package GraphViz::HasA::Introspect;
# ABSTRACT: introspector that knows how to introspect Moose classes
use Moose;
use namespace::autoclean;
use feature qw(switch);

use Data::Visitor::Callback;
use List::MoreUtils qw(uniq);
use Moose::Util::TypeConstraints ();
use Try::Tiny;

sub extract_classnames_from_type {
    my ($self, $type) = @_;

    # convert string to type metaobject
    $type = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint(
        $type,
    ) unless blessed $type;

    return unless $type;

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

sub extract_classnames_from_docstring {
    my ($self, $docstring) = @_;
    my @types;
    while($docstring =~ /type:(\S+)/g) {
        push @types, $1;
    }
    return map { $self->extract_classnames_from_type($_) } @types;
}

sub find_links_from_class {
    my ($self, $class) = @_;

    my @links;

    for my $attr (sort { $a->name cmp $b->name } $class->get_all_attributes){
        my $name = $attr->name;
        my $longname = join '::', $class->name, $name;

        my (%result, @classnames);

        $result{weak_ref} = 1 if $attr->is_weak_ref;

        # optional means that this thing may never exist, and
        # that's okay
        $result{optional} = 1
            unless $attr->is_required ||
                   $attr->has_default ||
                   $attr->has_builder;

        try {
            if($attr->has_documentation) {
                push @classnames, $self->extract_classnames_from_docstring(
                    $attr->documentation,
                );
            }
        }
        catch {
            warn "warning: cannot load constraints from docstring of $longname: $_";
        };

        try {
            if($attr->has_type_constraint) {
                push @classnames, $self->extract_classnames_from_type(
                    $attr->type_constraint,
                );
            }
        }
        catch {
            warn "warning: cannot load type constraint for $longname: $_";
        };

        for my $cname (@classnames) {
            push @links, [ $name => { %result, to => $cname } ];
        }
    }

    return @links;
}

sub find_links_from_role {
    my ($self, $role) = @_;

    my @links;

    my @attrs = uniq map { $_->get_attribute_list } $role->calculate_all_roles;
  attr: for my $name (sort { $a cmp $b } @attrs) {
        my $longname = join '::', $role->name, $name;
        my $attr = $role->get_attribute($name);

        my $type = $attr->{isa};
        next attr unless $type;

        my (%result, @classnames);
        $result{weak_ref} = 1 if $attr->{weak_ref};
        $result{optional} = 1
            unless $attr->{required}   ||
                   $attr->{default}    ||
                   $attr->{builder}    ||
                   $attr->{lazy_build};

        try {
            @classnames = $self->extract_classnames_from_type($type);
        }
        catch {
            warn "cannot extract types from role attribute $longname: $_";
        };

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

1;
