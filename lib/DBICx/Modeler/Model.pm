package DBICx::Modeler::Model;

use strict;
use warnings;

use DBICx::Modeler::X;
#use DBICx::Modeler::Carp;
#use constant TRACE => DBICx::Modeler::Carp::TRACE;

use Any::Moose '::Exporter';
use DBICx::Modeler::Model::Meta;

{

    my ($import, $unimport) = am( '::Exporter' )->build_import_methods(
# FIXME Mouse::Exporter does not implement this
        as_is => [qw/
            after before around
            belongs_to has_one has_many might_have
        /],
        also => [ am ],
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

sub after {
#    my $caller = shift;
    my $caller = scalar caller;
    push @{ $caller->_model__meta->_specialization->{method_modifier} }, [ after => @_ ];
}

sub before {
#    my $caller = shift;
    my $caller = scalar caller;
    push @{ $caller->_model__meta->_specialization->{method_modifier} }, [ before => @_ ];
}

sub around {
#    my $caller = shift;
    my $caller = scalar caller;
    push @{ $caller->_model__meta->_specialization->{method_modifier} }, [ around => @_ ];
}

sub belongs_to {
#    my ($caller, $relationship_name, $model_class) = @_;
    my ($relationship_name, $model_class) = @_;
    my $caller = scalar caller;
    $caller->_model__meta->belongs_to( $relationship_name => $model_class );
}

sub has_one {
#    my ($caller, $relationship_name, $model_class) = @_;
    my ($relationship_name, $model_class) = @_;
    my $caller = scalar caller;
    $caller->_model__meta->has_one( $relationship_name => $model_class );
}

sub has_many {
#    my ($caller, $relationship_name, $model_class) = @_;
    my ($relationship_name, $model_class) = @_;
    my $caller = scalar caller;
    $caller->_model__meta->has_many( $relationship_name => $model_class );
}

sub might_have {
#    my ($caller, $relationship_name, $model_class) = @_;
    my ($relationship_name, $model_class) = @_;
    my $caller = scalar caller;
    $caller->_model__meta->might_have( $relationship_name => $model_class );
}

1;
