#!C:/Strawberry/perl/bin/perl.exe
#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;

#
# Given "Picture Backups/YYYY MM DD" and an earlier directory in the same style
# remove as many identical subdirectories from the earlier directory as possible

#
# This software is provided as is, where is, etc with no guarantee that it is
# fit for any purpose whatsoever. Use at your own risk. Mileage may vary.
#

use File::Find;           
use File::chdir;
use File::Basename;
# use File::DirCompare;
use File::Copy;
use Cwd qw(cwd);
use List::Util qw (shuffle);
use POSIX;
use DateTime;
use List::Util qw (max);

use lib '.';
use bm_merge_pics_a;
use bm_merge_pics_b;

package main;

open (FILE, "<", 'E:\Picture Backups\bm_x_list.txt') or die "Can't open list";
while (my $r = <FILE>) {
    chomp ($r);

    my $old = $r;

    my $new = $r;
    $new =~ s/\\bm_x-/\\/;

    print ("\$old = $old, \$new = $new\n");

    rename ($old, $new) or die "Can't rename";
}
close (FILE);

