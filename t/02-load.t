use strict;
use warnings;

use Test::More qw/no_plan/;
use Test::Deep grep { !m/blessed/ } @Test::Deep::EXPORT;
use Test::Memory::Cycle;

use t::Test::Project;

sub ok_model {
    my $model_class = shift;
#    ok( $model_class->can( 'model_source' ), "$model_class can't model_source" );
#    ok( my $model_source = $model_class->model_source, "Couldn't get model_source for $model_class" );
#    is( $model_class, $model_source->model_class, "$model_class doesn't match up" );
#    memory_cycle_ok($model_source);
}

package t::Model::Track;

use DBICx::Modeler::Model;

package t::Model::Artist;

use DBICx::Modeler::Model;

package t::Model::Artist::Rock;

use DBICx::Modeler::Model;

extends qw/t::Model::Artist/;

package t::Model::Cd;

use DBICx::Modeler::Model;

belongs_to(artist => qw/t::Model::Artist::Rock/);

package t::Modeler;

use Test::More;
use Test::Deep grep { !m/blessed/ } @Test::Deep::EXPORT;

use Moose;
use t::Test::Project::Schema; # Probably don't need to do this step?

extends qw/DBICx::Modeler/;

#ok( __PACKAGE__->setup(qw/ t::Test::Project::Schema /) );

__PACKAGE__->meta->make_immutable;

package main;

my $schema = t::Test::Project->schema;
my $modeler = t::Modeler->new( schema => $schema );

for (qw/ Artist Artist::Rock Cd Track/ ) {
    ok_model( "t::Model::$_" );
}


ok( $modeler->model_source_by_model_class( 't::Model::Cd' )->relationship( 'artist' ) );
is( $modeler->model_source_by_model_class( 't::Model::Cd' )->relationship( 'artist' )->model_class, 't::Model::Artist::Rock' );

memory_cycle_ok($schema);
memory_cycle_ok($modeler);

ok( my $artist = $modeler->create( Artist => { name => 'apple' } ) );
is( $artist->name, 'apple' );
memory_cycle_ok( $artist );
is( $artist->model_source->relationship( "cds" )->model_class, 't::Model::Cd' );
ok( my $cd = $artist->create_related( cds => { title => 'banana' } ) );
memory_cycle_ok( $cd );
is( $cd->title, 'banana' );
ok( $artist->model_storage->id );
ok( $artist->id );
is( $artist->id, $artist->model_storage->id );
ok( $cd->artist );
ok( $cd->artist->model_storage->id );
is( $artist->id, $cd->artist->model_storage->id );
ok( $cd->id );

1;
