#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use FindBin qw($Bin);
use lib "$Bin/../lib";

# these make the app much easier to use
use lib ".";
use lib "lib";

use MooseX::Runnable::Run 'GraphViz::HasA::App';

# PODNAME: visualize-objects.pl
# ABSTRACT: script to invoke L<GraphViz::HasA::App>

__END__

=head1 SYNOPSIS

   $ visualize-objects.pl Foo Bar
   <the object graph displays on your screen>

=head1 DESCRIPTION

Run this with C<--help> for more information.

This script adds C<.> and C<lib> to C<@INC> so that you can easily
visualize in-progress code.
