package DBICx::Modeler::AnyMooseOverride;

use strict;
use warnings;

use DBICx::Modeler::X;

use Any::Moose 'Exporter';

am( 'Exporter' )->setup_import_methods(
    as_is => [qw/
        after before around
        belongs_to has_one has_many might_have
    /],
);

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
