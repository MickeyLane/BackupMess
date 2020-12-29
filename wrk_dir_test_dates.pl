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
use Image::MetaData::JPEG;
use Win32API::File::Time qw{:win};

use lib '.';

package main;

#
# Set defaults
#
my $pp_software_root_dir = 'C:/BackupMess';
my $pp_database_root_dir = 'C:/BackupMess/db';
my $pp_root = 'D:/Pictures';
my $pp_debug_limit = 2;

my @suffixlist = qw (.jpg .tif .gif .jpeg);

my @fq_pictures;
my @fq_dirs_tested;
my @fq_dirs_to_test_list = $pp_root;
my $count = @fq_dirs_to_test_list;
while ($count > 0 && $pp_debug_limit > 0) {
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
        elsif ($ff eq '.tmp.drivedownload') {
            next;
        }
        
        if (-d "$fq_dir/$ff") {
            push (@fq_dirs_to_test_list, "$fq_dir/$ff");
        }
        else {
            my $fq_file = "$fq_dir/$ff";

            my ($name, $path, $suffix) = fileparse ($fq_file, @suffixlist);
            $path =~ s/\/\z//;

            if (length ($suffix) != 0) {
                push (@fq_pictures, "$fq_file");

                $pp_debug_limit--;
            }

            next;
        }
    }
    closedir (DIR);
    $count = @fq_dirs_to_test_list;
}

$count = @fq_dirs_tested;
print ("\nThere are $count directories under $pp_root\n");

my $pics_with_good_dates = 0;

#
# Loop through all the pictures
#
foreach my $fq_picture (@fq_pictures) {
    my ($name, $path, $suffix) = fileparse ($fq_picture, @suffixlist);
    $path =~ s/\/\z//;

    #
    # Status values:
    #
    #   1 = file is OK, no changes needed
    #   2 = can't process image data
    #   3 = bad file path
    #   99 = unsupported image type
    #
    my $status;
    if ($suffix eq '.jpg' || $suffix eq '.jpeg') {
        $status = wrk_dir_jpg::process_dates_in_jpg_file ($pp_root, $path, $fq_picture);
    }
    else {
        $status = 99;  # unsupported image type
    }

    if ($status == 1) {
        $pics_with_good_dates++;
    }
}

print ("\$pics_with_good_dates = $pics_with_good_dates\n");
#
# END
#




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

#
# A Windows file time is a 64-bit value that represents the number of
# 100-nanosecond intervals that have elapsed since
# 12:00 A.M. January 1, 1601 Coordinated Universal Time (UTC)
#
# A DateTime epoch is the number of seconds that have elapsed since the Unix epoch, minus leap
# seconds; the Unix epoch is 00:00:00 UTC on 1 January 1970
#
sub epoch_to_win_file_time {
    my $dt = shift;

    my $epoch = $dt->epoch();

    my $years_diff = 1970 - 1601;
    my $days_diff = $years_diff * 365;
    my $seconds_diff = $days_diff * 24 * 60 * 60;

    my $ftime;

    return $ftime;
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
