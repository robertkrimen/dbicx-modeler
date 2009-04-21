use inc::Module::Install;

name     'DBICx-Modeler';
all_from 'lib/DBICx/Modeler.pm';
author   'Robert Krimen <rkrimen@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

