#!/usr/bin/perl
package wrk_dir_lib;
use warnings FATAL => 'all';
use strict;

use File::Compare;
use File::Basename;

use lib '.';

my @suffixlist = qw (.jpg .jpeg);

sub get_should_be_year {
    my $root = shift;
    my $fq_file = shift;

    #
    # For comments, asssume root is 'D:/Pictures'
    #
    my $root_len = length ($root);

    if ($fq_file =~ /^\Q$root/) {
        #
        # Get everything following the root
        #
        my $temp = substr ($fq_file, $root_len + 1);

        #
        # Assume dir structure is 'D:/Pictures'
        #                              '1910'
        #                              '1911'  etc.
        #
        if ($temp =~ /^\d{4}/) {
            #
            # Get year
            #
            return (substr ($temp, 0, 4));
        }
        else {
            die "bad year in path";
        }
    }
    else {
        die "bad file path";
    }
}

sub make_image_should_be_date {
    my $should_be_year = shift;
    
    my $dt = DateTime->new (
        year => $should_be_year,
        month => 7,
        day => 1,
        hour => 12,
        minute => 0,
        second => 0);

    my $string = "$should_be_year:07:01 12:00:00";

    return ($dt, $string);
}

use Time::localtime;
use File::stat;

sub get_file_creation_time {
    my $fq_file = shift;

    print ("\$fq_file = $fq_file\n");

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks) = stat ($fq_file);

    print ("\$size = $size\n");
    print ("\$ctime = $ctime\n");
    print ("\$mtime = $mtime\n");
    print ("\$atime = $atime\n");
}

1;
