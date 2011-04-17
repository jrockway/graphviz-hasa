use strict;
use warnings;
use Test::More;

{ package Book;
  use Moose;

  has 'author' => (
      is       => 'ro',
      isa      => 'User',
      required => 1,
      weak_ref => 1,
  );

  has 'owned_by' => (
      is       => 'ro',
      isa      => 'ArrayRef[User|Library]',
      weak_ref => 1,
  );

  package Library;
  use Moose;

  has 'collection' => (
      is       => 'ro',
      isa      => 'ArrayRef[Book]',
      required => 1,
  );

  has 'administrator' => (
      is       => 'ro',
      does     => 'LibraryAdministrator',
      required => 1,
  );

  has 'members' => (
      is  => 'ro',
      isa => 'ArrayRef[User]',
  );

  package User;
  use Moose;

  eval q{with 'LibraryAdministrator'}; # to confuse Dist::Zilla

  has 'username' => (
      is  => 'ro',
      isa => 'Str',
  );

  has 'books' => (
      is  => 'ro',
      isa => 'ArrayRef[Book]',
  );

  package LibraryAdministrator;
  use Moose::Role;

  has 'runs_library' => (
      is       => 'ro',
      isa      => 'Library',
      weak_ref => 1,
      required => 1,
  );


}

use GraphViz::HasA;
use GraphViz::HasA::Introspect;
my $i = GraphViz::HasA::Introspect->new;

is_deeply [ $i->find_links_from( Book->meta ) ], [
    [ author   => { to => 'User', weak_ref => 1,  } ],
    [ owned_by => { to => 'User', weak_ref => 1, optional => 1 } ],
    [ owned_by => { to => 'Library', weak_ref => 1, optional => 1 } ],
], 'got three links from Book';

is_deeply [ $i->find_links_from( Library->meta ) ], [
    [ administrator => { to => 'LibraryAdministrator' } ],
    [ collection => { to => 'Book' } ],
    [ members    => { to => 'User', optional => 1 } ],
], 'got two links from Library';

is_deeply [ $i->find_links_from( User->meta ) ], [
    [ books => { to => 'Book', optional => 1 } ],
], 'got one link from User';

is_deeply [ $i->find_links_from( LibraryAdministrator->meta ) ], [
    [ runs_library => { to => 'Library', weak_ref => 1 } ],
], 'got one link from LibraryAdmin';

my $g = GraphViz::HasA->new;
$g->add_class('User');

is_deeply [sort map { $_->name } $g->seen_classes ],
    [sort qw/Book Library LibraryAdministrator User/],
    'saw all four classes';

is_deeply [map { [ $_->{from}, $_->{to}, $_->{via} ] } $g->edges], [
    [ 'User' => 'Book', 'books' ],
    [ 'Book' => 'User', 'author' ],
    [ 'Book' => 'User', 'owned_by' ],
    [ 'Book' => 'Library', 'owned_by' ],
    [ 'Library' => 'LibraryAdministrator', 'administrator' ],
    [ 'LibraryAdministrator' => 'Library', 'runs_library' ],
    [ 'Library' => 'Book', 'collection' ],
    [ 'Library' => 'User', 'members' ],
], 'got all expected edges';

done_testing;
