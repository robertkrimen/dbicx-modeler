package DBICx::Modeler::Model;

use strict;
use warnings;

use DBICx::Modeler;
*TRACE = \&DBICx::Modeler::TRACE;
*TRACE = *TRACE;

use Moose();
use Moose::Exporter;
use Carp;
use DBICx::Modeler::Model::Meta;

{

    my ($import, $unimport) = Moose::Exporter->build_import_methods(
        with_caller => [ qw/belongs_to has_one has_many might_have/ ],
        also => [ qw/Moose/ ],
    );

    sub import {
        my $class = caller();

        return if $class eq 'main';

#        ($class->can('meta')) || confess "This package can only be used in Moose based classes";
#        my $meta = $class->meta;

        my $meta = Moose::Meta::Class->initialize( $class );
        my $model_meta = DBICx::Modeler::Model::Meta->new( model_class => $class );
        $meta->add_method( model_meta => sub {
            return $model_meta;
        } );
        Moose::Util::apply_all_roles( $meta => qw/DBICx::Modeler::Does::Model/ );

        goto &$import;
    }

    *unimport = $unimport;
    *unimport = $unimport; # Silly warning
}

sub belongs_to {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->relationship( $relationship_name )->belongs_to( $model_class );
}

sub has_one {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->relationship( $relationship_name )->has_one( $model_class );
}

sub has_many {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->relationship( $relationship_name )->has_many( $model_class );
}

sub might_have {
    my ($caller, $relationship_name, $model_class) = @_;
    $caller->model_meta->relationship( $relationship_name )->might_have( $model_class );
}

1;
