package DBICx::Modeler::Model::Meta::Relationship;

use Moose;

use DBICx::Modeler;
use constant TRACE => DBICx::Modeler->TRACE;

has model_meta => qw/is ro required 1/;
has model_class => qw/is rw/;

sub belongs_to {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}

sub might_have {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}

sub has_one {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}

sub has_many {
    my $self = shift;
    my $model_class = shift;
    $self->model_class( $model_class );
}


1;
