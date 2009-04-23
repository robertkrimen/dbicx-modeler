package DBICx::Modeler::Does::Model;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

#########
# Class #
#########

# This is a class method!
# This method is for DBix::Class::ResultSet, so it can inflate into our model classes
sub inflate_result {
    my $class = shift;
    my $source = shift;
    my $storage = $source->result_class->inflate_result( $source, @_ ); # Inflate into the "original" DBIx::Class::Row-kind
    return $class->new( model_storage => $storage ); # Only need to pass in the storage, model_modeler is gotten from the schema
}

##########
# Object #
##########

use Moose::Role;

requires qw/model_meta/;
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

1;
