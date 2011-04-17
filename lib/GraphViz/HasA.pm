package GraphViz::HasA;
# ABSTRACT: visualize object graphs with GraphViz
use Moose;
use true;
use namespace::autoclean;

use GraphViz;
use MooseX::Types::Set::Object;
use Set::Object qw(set);

has 'introspector' => (
    is      => 'ro',
    isa     => 'GraphViz::HasA::Introspect',
    default => sub { GraphViz::HasA::Introspect->new },
    handles => [qw/find_links_from/],
);

# edges is built incrementally, as a user may provide many "root" classes
has 'edges' => (
    init_arg => 'edges', # feel free to supply your own
    isa      => 'ArrayRef[HashRef]',
    traits   => ['Array'],
    default  => sub { [] },
    handles  => {
        edges     => 'elements',
        push_edge => 'push',
    },
);

has 'seen' => (
    is      => 'ro',
    isa     => 'Set::Object',
    default => sub { set },
    handles => {
        already_seen => 'member',
        mark_seen    => 'insert',
        seen_classes => 'members',
    },
);

sub add_class {
    my ($self, $class) = @_;
    $class = do { Class::MOP::load_class($class); Class::MOP::class_of($class) }
        if !ref $class;

    return if $self->already_seen($class);
    $self->mark_seen($class);

    my $name = $class->name;
    for my $link ($self->find_links_from($class)) {
        $self->push_edge({ from => $name, via => $link->[0], %{$link->[1]}});

        my $next = $link->[1]{to};
        $self->add_class($next) if $next;
    }

    return;
}

sub graph {
    my ($self, $viz, %params) = @_;
    $viz ||= GraphViz->new;

    for my $class ($self->seen_classes) {
        $viz->add_node($class->name);
    }

    for my $edge ($self->edges) {
        $viz->add_edge(
            $edge->{from} => $edge->{to},
            label => $edge->{via},
            style => $edge->{weak_ref} ? 'dashed' : 'normal',
        );
    }

    return $viz;
}

__PACKAGE__->meta->make_immutable;