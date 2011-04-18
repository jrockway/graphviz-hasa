package GraphViz::HasA::Introspect::IsA;
# ABSTRACT: show Isa (and Does) relationships along with the HasA relationships
use Moose;
use true;
use namespace::autoclean;

use List::MoreUtils qw(uniq);

extends 'GraphViz::HasA::Introspect::Shallow';

sub resolve_roles {
    my @result;
    for my $role (@_) {
        $role = $role->meta unless blessed $role;
        if($role->isa('Moose::Meta::Role::Composite')){
            # really?  there's no attribute for this?
            push @result, resolve_roles(split /\|/, $role->name);
        }
        else {
            push @result, $role;
        }
    }
    return uniq @result;
}

around find_links_from_class => sub {
    my ($orig, $self, $class) = @_;
    my @links = $self->$orig($class);

    my $name = $class->name;

    return (
        @links,
        ( map { [ $name => { to => $_->name, via => 'DOES' } ] }
              resolve_roles(@{$class->roles}) ),

        ( map { [ $name => { to => $_, via => 'ISA' } ] }
              # skip Moose::Object though, because everything is one
              grep { $_ ne 'Moose::Object' } uniq $class->superclasses ),
    );
};

around find_links_from_role => sub {
    my ($orig, $self, $role) = @_;
    my @links = $self->$orig($role);

    my $name = $role->name;

    return (
        @links,
        ( map { [ $name => { to => $_->name, via => 'DOES' } ] }
              grep { $_->name ne $name }
                  resolve_roles(@{$role->get_roles}) ),
    );
};

__PACKAGE__->meta->make_immutable;
