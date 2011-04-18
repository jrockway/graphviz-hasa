package GraphViz::HasA::App;
# ABSTRACT: display or output an object graph
use Moose;
use namespace::autoclean;
use GraphViz::HasA;

with 'MooseX::Runnable', 'MooseX::Getopt::Dashes';

has 'introspector' => (
    is            => 'ro',
    isa           => 'Str',
    default       => 'GraphViz::HasA::Introspect',
    documentation => 'class to use for building the edge list; default is quite sane',
);

has 'has_a' => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    isa        => 'GraphViz::HasA',
    lazy_build => 1,
    handles    => [qw/add_class graph/],
);

sub _build_has_a {
    my $self = shift;

    my $introspector = $self->introspector;
    Class::MOP::load_class($introspector);

    return GraphViz::HasA->new( introspector => $introspector->new );
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
