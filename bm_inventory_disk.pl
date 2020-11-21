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
    die;
}

if (length ($drive) != 1) {
    print ("No drive specified\n");
    die;
}

print ("Checking drive $drive\n");

my $cwd = Cwd::cwd();
print ("\$cwd = $cwd\n");

chdir ("$drive:");

$cwd = Cwd::cwd();
print ("\$cwd = $cwd\n");

my $test_drive_root = "$drive:";
my $test_drive_id_file = "$test_drive_root\.backup_mess_id";

my @id_file_records;

open (FILE, "<", $test_drive_id_file) or die "Can't open $test_drive_id_file: $!";

while (my $r = <FILE>) {
    $r =~ s/[\r\n]+//;
    push (@id_file_records, $r);
}

close (FILE);

# foreach my $r (@id_file_records) {
#     print ("$r\n");
# }

my @manual_backup_dirs;
my @website_backup_dirs;
my @fq_dirs_tested;
my @fq_dirs_to_test_list = $test_drive_root;
my $count = @fq_dirs_to_test_list;
while ($count > 0) {
    # print ("$count\n");
    my $fq_dir = shift @fq_dirs_to_test_list;
    push (@fq_dirs_tested, $fq_dir);
    opendir (DIR, $fq_dir) or die "Can't open $fq_dir: $!";
    while (my $ff = readdir (DIR)) {
        if ($ff eq 'System Volume Information') {
            next;
        }
        elsif ($ff eq '.' || $ff eq '..') {
            next;
        }
        elsif ($ff eq '$RECYCLE.BIN') {
            next;
        }
        
        if (-d "$fq_dir/$ff") {
            push (@fq_dirs_to_test_list, "$fq_dir/$ff");
        }
        else {
            next;
        }


    }
    closedir (DIR);
    $count = @fq_dirs_to_test_list;
}

$count = @fq_dirs_tested;
print ("\nThere are $count directories on $drive:\n");

# foreach my $d (@fq_dir_list) {
#     print ("$d\n");
# }



# sub read_dir {
#     my $fq_dir = shift;

#     my @fq_dir_list;
    
#     opendir (DIR, $fq_dir) or die "Can't open $fq_dir: $!";
#     while (my $ff = readdir (DIR)) {
#         my $possible_fq_dir = "$fq_dir/$ff";
#         if (-d $possible_fq_dir) {
#             push (@fq_dir_list, $possible_fq_dir);
#         }
#     }
#     closedir (DIR);

#     return (\@fq_dir_list);
# }
