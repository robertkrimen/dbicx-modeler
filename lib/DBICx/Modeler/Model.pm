package DBICx::Modeler::Model;

use strict;
use warnings;

use DBICx::Modeler::Carp;
use constant TRACE => DBICx::Modeler::Carp::TRACE;

use Moose();
use Moose::Exporter;

use DBICx::Modeler::Model::Meta;

{

    my ($import, $unimport) = Moose::Exporter->build_import_methods(
        with_caller => [ qw/belongs_to has_one has_many might_have/ ],
        also => [ qw/Moose/ ],
    );

    sub import {
        my $class = caller();

        return if $class eq 'main';

        my $meta = Moose::Meta::Class->initialize( $class );
        my $model_meta = DBICx::Modeler::Model::Meta->new( model_class => $class );
        $meta->add_method( model_meta => sub {
            return $model_meta;
        } );
        Moose::Util::apply_all_roles( $meta => qw/DBICx::Modeler::Does::Model/ );

        goto &$import;
    }

    *unimport = \&$unimport;
    *unimport = $unimport; # Derp, derp, derp, warning
}

sub belongs_to {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->belongs_to( $relationship_name => $model_class );
}

sub has_one {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->has_one( $relationship_name => $model_class );
}

sub has_many {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->has_many( $relationship_name => $model_class );
}

sub might_have {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->might_have( $relationship_name => $model_class );
}

1;
