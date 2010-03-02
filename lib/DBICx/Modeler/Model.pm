package DBICx::Modeler::Model;

use strict;
use warnings;

use DBICx::Modeler::X;
#use DBICx::Modeler::Carp;
#use constant TRACE => DBICx::Modeler::Carp::TRACE;

use Any::Moose '::Exporter';
use DBICx::Modeler::AnyMooseOverride;
use DBICx::Modeler::Model::Meta;

{

    my ($import, $unimport) = am( '::Exporter' )->build_import_methods(
# FIXME Mouse::Exporter does not implement this
#        as_is => [qw/
#            after before around
#            belongs_to has_one has_many might_have
#        /],
        also => [ am, 'DBICx::Modeler::AnyMooseOverride' ],
    );

    sub import {
        my $class = caller();

        return if $class eq 'main';

        my $meta = am( '::Meta::Class' )->initialize( $class );
        my $model_meta = DBICx::Modeler::Model::Meta->new( model_class => $class );
        $meta->add_method( _model__meta => sub {
            return $model_meta;
        } );

        am( [ '::Util' => 'apply_all_roles' ], $meta => qw/DBICx::Modeler::Does::Model/ );

        goto &$import;
    }

    *unimport = \&$unimport;
    *unimport = $unimport; # Derp, derp, derp, warning
}

1;
