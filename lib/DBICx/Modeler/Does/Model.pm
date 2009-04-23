package DBICx::Modeler::Does::Model;

use Moose::Role;

use DBICx::Modeler;
*TRACE = \&DBICx::Modeler::TRACE;

# requires model_meta 

has model_modeler => qw/is ro lazy_build 1 weak_ref 1/;
sub _build_model_modeler {
    return shift->model_schema->modeler;
};

has model_schema => qw/is ro lazy_build 1 weak_ref 1/;
sub _build_model_schema {
    return shift->model_storage->result_source->schema;
};

has model_storage => qw/is ro required 1/;

sub model_source {
    my $self = shift;
    return $self->model_modeler->model_source_by_model_class( ref $self );
}

sub search_related {
    my $self = shift;
    my $relationship_name = shift;
    return $self->model_source->search_related( $self => $relationship_name => @_ );
}

sub create_related {
    my $self = shift;
    my $relationship_name = shift;
    return $self->model_source->create_related( $self => $relationship_name => @_ );
}

# This is a class method
sub inflate_result {
    # This method is for DBix::Class::ResultSet, so it can inflate into our Model classes
    my $class = shift;
    my $source = shift;
    my $storage = $source->result_class->inflate_result( $source, @_ );
    return $class->new( model_storage => $storage );
}

1;
