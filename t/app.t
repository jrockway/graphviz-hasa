use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok 'GraphViz::HasA::App';

my $app = GraphViz::HasA::App->new;

isa_ok $app, 'GraphViz::HasA::App';

lives_ok {
    select *STDERR;
    close *STDERR;
    $app->run('GraphViz::HasA::App');
    select *STDOUT;
} 'run works ok';

done_testing;
