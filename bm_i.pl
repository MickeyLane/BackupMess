#!C:/Strawberry/perl/bin/perl.exe
#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;

#
# This software is provided as is, where is, etc with no guarantee that it is
# fit for any purpose whatsoever. Use at your own risk. Mileage may vary.
#
use File::Find;           
use File::chdir;
use File::Basename;
use Cwd qw(cwd);
use List::Util qw (shuffle);
use POSIX;
use File::Copy;
use DateTime;
use List::Util qw (max);

use lib '.';

package main;

#
# SET PROGRAM PARAMETERS
# ======================
#
# Any variable that begins with 'fq_' is supposed to contain a fully qualified file name
# Any variable that begins with 'pp_' is a program parameter and is usually a flag to enable
#   or disable some feature
# Any variable that begins with 'fp_' is a floating point value. Not used very often
#

#
#
#
my $pp_software_root_dir = 'C:/BackupMess';
my $pp_database_root_dir = 'C:/BackupMess/db';
# my $pp_output_file_name = 'byzip-output.csv';

#
# COMMAND LINE ARGUMENTS
# ======================
#
# Set defaults
#
my $drive = '';

#
# Get input arguments
#
# my $untested_positive_switch = 'untested_positive=';
# my $untested_positive_switch_string_len = length ($untested_positive_switch);

# my $max_display_switch = 'cured_max_display=';
# my $max_display_switch_string_len = length ($max_display_switch);

# my $report_collection_switch = 'report_collection=';
# my $report_collection_switch_string_len = length ($report_collection_switch);

foreach my $switch (@ARGV) {
    # print ("Switch is \"$switch\"\n");
    if (index ($switch, 'drive=') != -1) {
        my $temp = substr ($switch, 6);

        if ($temp ne "") {
            $temp =~ s/\:\z//;
            if (length ($temp) == 1) {
                $drive = uc $temp;
                next;
            }
        }
    }

    print ("Don't know what to do with $switch\n");
    exit (1);
}

if (length ($drive) != 1) {
    print ("No drive specified\n");
    exit (1);
}

print ("Checking drive $drive\n");
