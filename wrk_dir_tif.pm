#!/usr/bin/perl
package wrk_dir_tif;
use warnings;
use strict;

use File::Compare;
use File::Basename;

use lib '.';
use wrk_dir_lib;

my @suffixlist = qw (.tif .tiff);
my $pp_report_anyway = 1;

sub process_dates_in_tif_file {
    my ($pp_root, $fq_picture, $enable_file_writes, $using_test_pic) = @_;

    my $return_status = 1;
}

1;
