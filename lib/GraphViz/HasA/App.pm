package GraphViz::HasA::App;
# ABSTRACT: display or output an object graph
use Moose;
use namespace::autoclean;
use GraphViz::HasA;

with 'MooseX::Runnable', 'MooseX::Getopt::Dashes';

has 'has_a' => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    isa        => 'GraphViz::HasA',
    lazy_build => 1,
    handles    => [qw/add_class graph/],
);

sub _build_has_a {
    return GraphViz::HasA->new;
}

sub run {
    my ($self, @classes) = @_;
    die 'need some classes on the command line!' unless @classes;

    $self->add_class($_) for @classes;
    print $self->graph->as_debug;
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
