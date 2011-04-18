package GraphViz::HasA::Introspect::IsA;
# ABSTRACT: show Isa (and Does) relationships along with the HasA relationships
use Moose;
use true;
use namespace::autoclean;

extends 'GraphViz::HasA::Introspect::Shallow';

around find_links_from_class => sub {
    my ($orig, $self, $class) = @_;
    my @links = $self->$orig($class);

    my $name = $class->name;

    return (
        @links,
        ( map { [ $name => { to => $_->name, via => 'DOES' } ] }
              $class->calculate_all_roles ),
        ( map { [ $name => { to => $_, via => 'ISA' } ] }
              # skip Moose::Object though, because everything is one
              grep { $_ ne 'Moose::Object' } $class->superclasses ),
    );
};

around find_links_from_role => sub {
    my ($orig, $self, $role) = @_;
    my @links = $self->$orig($role);

    my $name = $role->name;

    return (
        @links,
        ( map { [ $name => { to => $_->name, via => 'DOES' } ] }
              grep { $_->name ne $name } $role->calculate_all_roles ),
    );
};

__PACKAGE__->meta->make_immutable;
