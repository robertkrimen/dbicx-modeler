package t::Test::Project::Model::Cd;

use DBICx::Modeler::Model;

belongs_to( artist => 't::Test::Project::Model::Artist::Rock' );

1;
