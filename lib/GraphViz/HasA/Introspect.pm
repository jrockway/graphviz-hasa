package GraphViz::HasA::Introspect;
# ABSTRACT: introspector that knows how to introspect Moose classes
use Moose;
use true;
use namespace::autoclean;
use feature qw(switch);
use Data::Visitor::Callback;

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
    );
    $v->visit($type);
    return @result;
}

sub find_links_from {
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

__PACKAGE__->meta->make_immutable;
