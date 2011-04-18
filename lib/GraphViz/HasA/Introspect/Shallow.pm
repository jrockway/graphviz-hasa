package GraphViz::HasA::Introspect::Shallow;
# ABSTRACT: intospector that ignores inherited attributes
use Moose;
use namespace::autoclean;

extends 'GraphViz::HasA::Introspect';

override find_attributes_in_class => sub {
    my ($self, $class) = @_;

    my %attrs = map { $_ => 1 } $class->get_attribute_list;

    for my $role ($class->calculate_all_roles) {
        $attrs{$_} = 0 for $role->get_attribute_list;
    }

    return map { $class->get_attribute($_) } sort grep {
        $attrs{$_} == 1
    } keys %attrs;
};

override find_attributes_in_role => sub {
    my ($self, $role) = @_;
    my %attrs = map { $_ => 1 } $role->get_attribute_list;

    for my $role2 (grep { $_->name ne $role->name } $role->calculate_all_roles) {
        $attrs{$_} = 0 for $role2->get_attribute_list;
    }

    return sort grep { $attrs{$_} == 1 } keys %attrs;
};

__PACKAGE__->meta->make_immutable;

1;
