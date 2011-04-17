package GraphViz::HasA::App;
# ABSTRACT: display or output an object graph
use Moose;
use true;
use namespace::autoclean;

use File::Slurp qw(write_file);
use File::Which qw(which);

use feature 'switch';

use GraphViz::HasA;

with 'MooseX::Runnable', 'MooseX::Getopt::Dashes';

has 'has_a' => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    isa        => 'GraphViz::HasA',
    lazy_build => 1,
    handles    => [qw/add_class graph/],
);

has 'output_method' => (
    is            => 'ro',
    isa           => 'Str',
    lazy_build    => 1,
    documentation => 'print to print dot file, xdot to run xdot, file to write to a file',
);

sub _build_output_method {
    my $self = shift;
    return 'print' if !-t *STDOUT;
    return 'xdot' if which('xdot');
    return 'file';
}

sub _build_has_a {
    return GraphViz::HasA->new;
}

sub run {
    my ($self, @classes) = @_;
    die 'need some classes on the command line!' unless @classes;

    my $filename = $classes[0];
    $filename =~ s/::/_/g;
    $filename .= '.dot';

    $self->add_class($_) for @classes;

    my $viz = $self->graph;
    given($self->output_method) {
        when(/xdot/){
            # if you have xdot, my guess is that /tmp is your tmpfs :)
            write_file("/tmp/$filename", $viz->as_debug);
            print {*STDERR} "running xdot\n";
            exec(which('xdot'), "/tmp/$filename");
        }
        when(/file/){
            write_file($filename, $viz->as_debug);
            print {*STDERR} "wrote $filename\n";
        }
        default {
            print $viz->as_debug;
        }
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
