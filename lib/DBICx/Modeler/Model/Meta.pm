package DBICx::Modeler::Model::Meta;

use strict;
use warnings;

use Moose;

use DBICx::Modeler;
*TRACE = \&DBICx::Modeler::TRACE;
*TRACE = *TRACE;

use DBICx::Modeler::Model::Meta::Relationship;
use Carp;

has parent => qw/is ro isa Maybe[DBICx::Modeler::Model::Meta] lazy_build 1/;
sub _build_parent {
    my $self = shift;
    if (my $method = $self->model_class->meta->find_next_method_by_name( 'model_meta' )) {
        return $method->();
    }
    return undef;
}
has model_class => qw/is ro required 1/;
has base_model_class => qw/is ro lazy_build 1/;
sub _build_base_model_class {
    my $self = shift;
    if ($self->parent) {
        return $self->parent->model_class; # If we are ::Model::Artist::Rock
    }
    return $self->model_class; # If we are ::Model::Artist
}
has _relationship_map => qw/is ro isa HashRef/, default => sub { {} };
sub relationship {
    my $self = shift;
    my $relationship_name = shift;
    return $self->_relationship_map->{$relationship_name} ||= DBICx::Modeler::Model::Meta::Relationship->new( model_meta => $self );
}

sub specialize_model_source {
    my $self = shift;
    my $model_source = shift;
    for my $relationship ($model_source->relationships) {
        next unless $self->_relationship_map->{ $relationship->name };
        my $special = $self->relationship( $relationship->name );
        DBICx::Modeler->ensure_class_loaded( $special->model_class );
        $relationship->model_class( $special->model_class );
    }
    return $model_source;
}

sub initialize_base_model_class {
    my $self = shift;
    my $model_source = shift;

    # $model_source should have been specialized already
    #
    croak "I should only be called on base model classes" if $self->parent;

    my $meta = $self->model_class->meta;
    my $result_source = $model_source->result_source;

    for my $relationship ( $model_source->relationships ) {
        my $name = $relationship->name;

        next if $meta->has_method($name);

        if (! $relationship->is_many) {
            $meta->add_attribute( $name => qw/is ro lazy 1/, default => sub {
                my $self = shift;
                return $self->model_source->inflate_related( $self, $name );
            } );
        }
        else {
            $meta->add_method( $name => sub {
                my $self = shift;
                return $self->model_source->search_related( $self, $name, @_ );
            } );
        }
    }

    my $attribute;
    if ($attribute = $meta->get_attribute( 'model_storage' )) {

        if ($attribute->has_handles) { 
            # Assume the user know's what they're doing
            # TODO Add a TRACE here
        }
        else {
            my @handles = grep { ! $meta->has_method( $_ ) } $result_source->columns;
            my $new_attribute = $meta->_process_inherited_attribute( $attribute->name, handles => \@handles );
            $meta->add_attribute( $new_attribute );
        }
    }
    else {
        croak $self->model_class, ' WTF?';
        # TODO Warn we don't know what's going on
    }
}

1;
