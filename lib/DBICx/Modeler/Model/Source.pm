package DBICx::Modeler::Model::Source;

use strict;
use warnings;

use Moose;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

use DBICx::Modeler::Model::Relationship;

has modeler => qw/is ro required 1 weak_ref 1/;
has schema => qw/is ro lazy_build 1 weak_ref 1/;
sub _build_schema {
    return shift->modeler->schema;
}
has moniker => qw/is ro required 1/;
has model_class => qw/is ro required 1/;
has result_source => qw/is ro lazy_build 1 weak_ref 1/;
sub _build_result_source {
    my $self = shift;
    return $self->schema->source( $self->moniker );
};
has create_select => qw/is rw lazy_build 1/;
sub _build_create_select {
    my $self = shift;
    return $self->modeler->create_select;
};
has _relationship_map => qw/is ro isa HashRef/, default => sub { {} };
sub relationship {
    my $self = shift;
    my $relationship_name = shift;
    return $self->_relationship_map->{$relationship_name} ||= $self->_build_relationship( $relationship_name );
}
sub relationships {
    my $self = shift;
    return values %{ $self->_relationship_map };
}

sub _build_relationship {
    my $self = shift;
    my $relationship_name = shift;

    my $result_source = $self->result_source;
    my $moniker = $self->moniker;

    TRACE->("[$self] Processing relationship $relationship_name for $moniker");
    my $schema_relationship = $result_source->relationship_info( $relationship_name );
    croak "No such relationship $relationship_name for ", $self->moniker unless $schema_relationship;
    my $model_relationship = DBICx::Modeler::Model::Relationship->new(
        modeler => $self->modeler,
        name => $relationship_name,
        model_source => $self,
        schema_relationship => $schema_relationship
    );
}

sub clone {
    my $self = shift;
    my %override = @_;
    my $clone = $self->new(
        clone => 1,
        _relationship_map => { map { $_ => $self->_relationship_map->{$_}->clone } keys %{ $self->_relationship_map } },
        ( map { $_ => $self->$_ } qw/ modeler schema moniker model_class create_select / ),
        %override,
    );
    return $clone;
}

#sub christen {
#    my $self = shift;
#    my %override = @_;
#    croak "Don't have schema override" unless $override{schema};
#    croak "Override for schema ", $override{schema}, " isn't blessed" unless blessed $override{schema};
#    croak "Don't have modeler override" unless $override{modeler};
#    croak "Override for modeler ", $override{modeler}, " isn't blessed" unless blessed $override{modeler};
#    # Don't want a class-based result_source, need to make sure we grab a fresh one via default =>
#    return $self->clone(%override);
#}

sub BUILD {
    my $self = shift;
    my $given = shift;

    unless ($given->{clone}) {
        my $schema = $self->schema;
        my $moniker = $self->moniker;
        my $result_source = $self->result_source;

        for my $relationship_name ($result_source->relationships) {
            TRACE->("[$self] Processing relationship $relationship_name for $moniker");
            my $relationship = $result_source->relationship_info($relationship_name);
            my $model_relationship = DBICx::Modeler::Model::Relationship->new(parent_model_source => $self,
                modeler => $self->modeler, name => $relationship_name, schema_relationship => $relationship);
            $self->_relationship_map->{$relationship_name} = $model_relationship;
        }

        $self->model_class->model_meta->specialize_model_source( $self );
    }
}

sub create {
    my $self = shift;
    my $create = shift;

    my $rs = $self->schema->resultset( $self->moniker );
    my $storage = $rs->create( $create );
    # TODO This should fetch based on the primary key information
    ($storage) = $storage->result_source->resultset->search({ id => $storage->id })->slice( 0, 0 ) if $self->create_select;
    return $self->inflate( model_storage => $storage, @_ );
}

sub inflate {
    my $self = shift;
    return $self->_inflate( $self->model_class, @_ );
}

sub _inflate {
    my $self = shift;
    my $model_class = shift;
    my $inflate = @_ > 1 ? { @_ } : $_[0];
    return $model_class->new( %$inflate );
}

sub search {
    my $self = shift;
    my $cond = shift || undef;
    my $attr = shift || {};

#    return $self->schema->resultset($self->moniker)->search($cond, { result_class => $self->model_class, %$attr });
# FIXME Doesn't work cuz result_source ain't connected!
    return $self->result_source->resultset->search( $cond, { result_class => $self->model_class, %$attr } );
}

sub inflate_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $inflate = @_ > 1 ? { @_ } : $_[0];

    my $relationship = $self->relationship( $relationship_name );

    # Don't create if entity doesn't have a relationship
    return undef unless my $storage = $entity->model_storage->$relationship_name;

    return $self->_inflate( $relationship->model_class, model_storage => $storage );
}

sub create_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $values = shift;

    my $relationship = $self->relationship( $relationship_name );

    my $storage = $entity->model_storage->create_related( $relationship_name => $values );
    # TODO This should fetch based on the primary key information
    ($storage) = $storage->result_source->resultset->search({ id => $storage->id })->slice( 0, 0 ) if $self->create_select;

    return $self->_inflate( $relationship->model_class, model_storage => $storage );
}

sub search_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $condition = shift || undef;
    my $attributes = shift || {};

    my $relationship = $self->relationship( $relationship_name );

    return $entity->storage->search_related( $relationship_name => $condition,
        { result_class => $relationship->model_class, %$attributes } );
}

1;

__END__

package MooseX::DBIC::Modeler::ModelSource;

use MooseX::DBIC::Modeler;
use constant TRACE => MooseX::DBIC::Modeler->TRACE;

use Moose;
use Carp::Clan qw/^MooseX::DBIC::Modeler::/;
use Scalar::Util qw/blessed/;

use MooseX::DBIC::Modeler::Relationship;

has modeler => qw/is ro required 1 weak_ref 1/; # Can be class or blessed reference
has schema => qw/is ro required 1 weak_ref 1/; # Can be class or blessed reference
has moniker => qw/is ro required 1/;
has result_source => qw/is ro required 1 weak_ref 1 lazy 1/, default => sub {
    my $self = shift;
    return $self->schema->source($self->moniker);
};
has relationship_map => qw/is ro lazy 1 required 1/, default => sub { {} };
has model_class => qw/is rw lazy 1 required 1/, default => sub { # TODO Should this grab a default?
    my $self = shift;
    return $self->modeler->get_model_class($self->moniker);
};
has create_select => qw/is rw lazy 1/, default => sub {
    my $self = shift;
    return $self->modeler->create_select;
};

sub has_model_class {
    my $self = shift;
    return $self->modeler->has_model_class($self->moniker);
}

sub clone {
    my $self = shift;
    my %override = @_;
    my $clone = $self->new(
        clone => 1,
        relationship_map => { map { $_ => $self->relationship_map->{$_}->clone } keys %{ $self->relationship_map } },
        (map { $_ => $self->$_ } qw/modeler schema moniker model_class/), %override);
    # FIXME This is a hack!
    $clone->_setup_defer;
    return $clone;
}

sub christen {
    my $self = shift;
    my %override = @_;
    croak "Don't have schema override" unless $override{schema};
    croak "Override for schema ", $override{schema}, " isn't blessed" unless blessed $override{schema};
    croak "Don't have modeler override" unless $override{modeler};
    croak "Override for modeler ", $override{modeler}, " isn't blessed" unless blessed $override{modeler};
    # Don't want a class-based result_source, need to make sure we grab a fresh one via default =>
    return $self->clone(%override);
}

sub _setup_defer {
    my $self = shift;
    # FIXME This is a hack!
    $_->_setup_defer($self) for $self->relationships;
}

sub BUILD {
    my $self = shift;

    unless ($_[0]->{clone}) {
        my $schema = $self->schema;
        my $moniker = $self->moniker;
        my $result_source = $schema->source($moniker);

        for my $relationship_name ($result_source->relationships) {
            TRACE->("[$self] Processing relationship $relationship_name for $moniker");
            my $relationship = $result_source->relationship_info($relationship_name);
            my $model_relationship = MooseX::DBIC::Modeler::Relationship->new(parent_model_source => $self,
                modeler => $self->modeler, name => $relationship_name, schema_relationship => $relationship);
            $self->relationship_map->{$relationship_name} = $model_relationship;
        }
    }
}

sub relationship {
    my $self = shift;
    my $name = shift;
    confess unless $name;
    return $self->relationship_map->{$name};
}

sub relationships {
    my $self = shift;
    return values %{ $self->relationship_map };
}

sub create {
    my $self = shift;
    my $create = shift;

    my $rs = $self->schema->resultset($self->moniker);
    my $storage = $rs->create($create);
    ($storage) = $storage->result_source->resultset->search({ id => $storage->id })->slice(0, 0) if $self->create_select;
    return $self->inflate(storage => $storage, @_);
}

sub inflate {
    my $self = shift;
    my $inflate = @_ > 1 ? { @_ } : $_[0];

    return $self->model_class->new(%$inflate);
}

sub search {
    my $self = shift;
    my $cond = shift || undef;
    my $attr = shift || {};

#    return $self->schema->resultset($self->moniker)->search($cond, { result_class => $self->model_class, %$attr });
# FIXME Doesn't work cuz result_source ain't connected!
    return $self->result_source->resultset->search($cond, { result_class => $self->model_class, %$attr });
}

sub inflate_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $inflate = @_ > 1 ? { @_ } : $_[0];

    my $relationship = $self->relationship($relationship_name);

    # Don't create if entity doesn't have a relationship
    return undef unless my $storage = $entity->storage->$relationship_name;

    return $relationship->model_source->inflate(storage => $storage);
}

sub create_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $values = shift;

    my $relationship = $self->relationship($relationship_name);

    my $storage = $entity->storage->create_related($relationship_name => $values);
    ($storage) = $storage->result_source->resultset->search({ id => $storage->id })->slice(0, 0) if $self->create_select;

    return $relationship->model_source->inflate(storage => $storage);
}

sub search_related {
    my $self = shift;
    my $entity = shift;
    my $relationship_name = shift;
    my $condition = shift || undef;
    my $attributes = shift || {};

    my $relationship = $self->relationship($relationship_name);

    return $entity->storage->search_related($relationship_name => $condition,
        { result_class => $relationship->model_class, %$attributes });
}

1;

