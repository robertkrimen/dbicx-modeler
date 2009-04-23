package DBICx::Modeler::Carp;

use strict;
use warnings;

use Carp::Clan::Share;
use constant TRACE_DEFAULT => 0;
use constant TRACE => (exists $ENV{MODELER_TRACE} ? $ENV{MODELER_TRACE} : TRACE_DEFAULT) ? sub { print STDERR join "", @_, "\n" } : sub {};

1;
