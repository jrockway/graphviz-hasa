package GraphViz::HasA::Introspect;
# ABSTRACT: introspector that knows how to introspect Moose classes
use Moose;
use true;
use namespace::autoclean;
use feature qw(switch);

use Data::Visitor::Callback;
use List::MoreUtils qw(uniq);
use Moose::Util::TypeConstraints ();

sub extract_classnames_from_type {
    my ($self, $type) = @_;

    my @result;
    my $v = Data::Visitor::Callback->new(
        'Moose::Meta::TypeConstraint::Class' => sub {
            push @result, $_->class;
            return $_;
        },
        'Moose::Meta::TypeConstraint::Role' => sub {
            push @result, $_->role;
            return $_;
        },
        'Moose::Meta::TypeConstraint::Parameterized' => sub {
            $_[0]->visit($_->type_parameter);
            return $_;
        },
        'Moose::Meta::TypeConstraint::Union' => sub {
            $_[0]->visit($_->type_constraints);
            return $_;
        },
        'Moose::Meta::TypeConstraint' => sub {
            if($_->has_parent) {
                $_[0]->visit($_->parent);
            }
        }
    );
    $v->visit($type);
    return @result;
}

sub find_links_from_class {
    my ($self, $class) = @_;

    my @links;

    for my $attr (sort { $a->name cmp $b->name } $class->get_all_attributes){
        my $name = $attr->name;

        if($attr->has_type_constraint) {
            my $type = $attr->type_constraint;
            my %result;

            $result{weak_ref} = 1 if $attr->is_weak_ref;

            # optional means that this thing may never exist, and
            # that's okay
            $result{optional} = 1
                unless $attr->is_required ||
                       $attr->has_default ||
                       $attr->has_builder;

            my @classnames = $self->extract_classnames_from_type($type);
            for my $cname (@classnames) {
                push @links, [ $name => { %result, to => $cname } ];
            }
        }
    }

    return @links;
}

sub find_links_from_role {
    my ($self, $role) = @_;

    my @links;

    my @attrs = uniq map { $_->get_attribute_list } $role->calculate_all_roles;
  attr: for my $name (sort { $a cmp $b } @attrs) {
        my $attr = $role->get_attribute($name);

        next attr unless exists $attr->{isa};

        my $type = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($attr->{isa});
        next attr unless $type;

        my %result;
        $result{weak_ref} = 1 if $attr->{weak_ref};
        $result{optional} = 1
            unless $attr->{required}   ||
                   $attr->{default}    ||
                   $attr->{builder}    ||
                   $attr->{lazy_build};

        my @classnames = $self->extract_classnames_from_type($type);
        for my $cname (@classnames) {
            push @links, [ $name => { %result, to => $cname } ];
        }
    }

    return @links;
}


sub find_links_from {
    my ($self, $it) = @_;
    return $self->find_links_from_class($it) if $it->isa('Moose::Meta::Class');
    return $self->find_links_from_role($it)  if $it->isa('Moose::Meta::Role');
    return;
}

__PACKAGE__->meta->make_immutable;
