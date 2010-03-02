package DBICx::Modeler::X;

use strict;
use warnings;

use Any::Moose();
use base qw/ Exporter /;
use vars qw/ @EXPORT /;

push @EXPORT, qw/ am /;

*any_moose = \&Any::Moose::any_moose;

sub am {
    if ( ref $_[0] eq 'ARRAY' ) {
        my ( $fragment, $method ) = @{ shift() };

        {
            no strict 'refs';
            return &{ any_moose( $fragment ) . "::$method" }( @_ );
        }
    }
    else {
        return any_moose( @_ );
    }
}

1;
