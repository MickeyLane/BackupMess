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
use wrk_dir_jpg;
use wrk_dir_tif;
use wrk_dir_lib;

package main;

my $pp_software_root_dir = 'C:/BackupMess';
my $pp_database_root_dir = 'C:/BackupMess/db';
my $pp_root = 'D:/Pictures';
my $test_pic_file;
my $test_pic_dir;
my @fq_dirs_to_test_list;

#
# For debug...
#
# my $pp_debug_limit = 300;
my $pp_enable_file_writes = 1;
my $pp_use_test_pic = 0;
my $pp_use_test_dir = 0;
my $pp_use_cell_phone_pics = 1;

if ($pp_use_cell_phone_pics) {
    $pp_root = 'D:/Picture Directories on Cell Phone';
}

if ($pp_use_test_dir) {
    $pp_use_test_pic = 0;
    if ($pp_use_cell_phone_pics) {
        $test_pic_dir = 'D:/Picture Directories on Cell Phone/2016 Grand Cayman';
    }
    else {
        $test_pic_dir = 'D:/Pictures/1910';
    }
    @fq_dirs_to_test_list = $test_pic_dir;
}
elsif ($pp_use_test_pic) {
    if ($pp_use_cell_phone_pics) {
        $test_pic_dir = 'D:/Picture Directories on Cell Phone/1975 USNS Vanguard';
        $test_pic_file = $test_pic_dir . '/09531906.jpg';
    }
    else {
        $test_pic_dir = 'D:/Pictures/1910';
        $test_pic_file = $test_pic_dir . '/Eulee Tisdale,1910.jpg';
    }
    @fq_dirs_to_test_list = $test_pic_dir;
}
else {
    @fq_dirs_to_test_list = $pp_root;
}

my @suffixlist = qw (.jpg .tif .gif .jpeg);

my @fq_pictures;
my @fq_dirs_tested;

#
# Loop through the directories and make a list of pictures
#
if ($pp_use_test_pic == 0 && $pp_use_test_dir == 0) {
    my $co = @fq_dirs_to_test_list;
    while ($co > 0) {
        get_pics_from_dir (\@fq_dirs_tested, \@fq_dirs_to_test_list, \@fq_pictures);
        $co = @fq_dirs_to_test_list;
    }
}
elsif ($pp_use_test_dir == 1) {
    get_pics_from_dir (\@fq_dirs_tested, \@fq_dirs_to_test_list, \@fq_pictures);
}
else {
    print ("Using test pic $test_pic_file\n");
    push (@fq_dirs_tested, $test_pic_dir);
    push (@fq_pictures, $test_pic_file);
}

my $count = @fq_dirs_tested;
print ("\nThere are $count directories under $pp_root\n");
$count = @fq_pictures;
print ("Found $count pictures\n");

my $pics_with_good_file_dates = 0;
my $pics_with_good_tag_dates = 0;
my $pics_that_dont_have_tags = 0;
my $pic_number = 1;

#
# Loop through all the pictures
#
foreach my $fq_picture (@fq_pictures) {
    if (0 && $pp_use_test_pic == 0 && $pp_use_test_dir == 0) {
        print ("Do $fq_picture? [ynx] ");
        my $choice_string = uc <STDIN>;  # force uppercase
        $choice_string =~ s/[\r\n]+//;
        if ($choice_string =~ /^X/) {
            exit (1);
        }
        elsif ($choice_string =~ /^N/) {
            next;
        }
    }

    my ($name, $path, $suffix) = fileparse ($fq_picture, @suffixlist);
    $path =~ s/\/\z//;

    my $pic_number = sprintf ("%04d", $pic_number++);
    print ("$pic_number: $fq_picture\n");

    #
    # Get current creation date (year only)
    #
    # wrk_dir_lib::get_file_creation_time ($fq_picture);
    # die;

    my ($atime, $mtime, $ctime) = GetFileTime ($fq_picture);
    if (!(defined ($ctime))) {
        print ("GetFileTime() returns an undef value for \$ctime\n");
        die;
    }
    my $file_create_time_dt = DateTime->from_epoch (epoch => $ctime);
    my $file_create_date_year = sprintf ("%04d", $file_create_time_dt->year());

    #
    # Get 'should be' year based on directory name
    #
    my $should_be_year = wrk_dir_lib::get_should_be_year ($pp_root, $fq_picture);

    if ($pp_use_test_pic) {
        #
        # Debug...
        #
        print ("\$file_create_date_year = $file_create_date_year\n");
        print ("\$should_be_year = $should_be_year\n");
    }

    #
    # If file creation year does not match directory year, fix
    #
    if ($file_create_date_year ne $should_be_year) {
        #
        # Update file creation date
        #
        my ($new_image_dt, $new_image_date_string) = wrk_dir_lib::make_image_should_be_date ($should_be_year);

        write_windows_file_times ($new_image_dt, $fq_picture, $pp_enable_file_writes);
    }
    else {
        $pics_with_good_file_dates++;
    }

    # print ("$fq_picture created $file_create_date_string\n");
    # exit (1);

    #
    # Status values from 'process_dates_in_xxx_file()':
    #
    #   1 = file is OK, no changes needed
    #   2 = can't process image data
    #   4 = file was modified without error
    #   5 = error trying to add new or modified tag
    #   99 = unsupported image type
    #
    my $status;
    my $err_message;
    if ($suffix eq '.jpg' || $suffix eq '.jpeg') {
        ($status, $err_message) = wrk_dir_jpg::process_dates_in_jpg_file (
            $pp_root, $fq_picture, $pp_enable_file_writes, $pp_use_test_pic);
        if ($status == 1) {
            $pics_with_good_tag_dates++;
        }
        elsif ($status == 4) {
            $pics_with_good_tag_dates++;
        }
        else {
            print ("\$status = $status\n");
            die;
        }
    }
    elsif ($suffix eq '.tif') {
        ($status, $err_message) = wrk_dir_tif::process_dates_in_tif_file (
            $pp_root, $fq_picture, $pp_enable_file_writes, $pp_use_test_pic);
        $pics_that_dont_have_tags++;
        $status = 1;
    }
    else {
        $status = 99;  # unsupported image type
    }

}

print ("\$pics_with_good_file_dates = $pics_with_good_file_dates\n");
print ("\$pics_with_good_tag_dates = $pics_with_good_tag_dates\n");
print ("\$pics_that_dont_have_tags = $pics_that_dont_have_tags\n");
#
# END
#

sub write_windows_file_times {
    my $new_image_dt = shift;
    my $fq_picture = shift;
    my $pp_enable_file_writes = shift;

    #
    # Get epoch value for 'now'
    #
    my $today_dt = DateTime->now();
    my $today_epoch_1 = $today_dt->epoch();
    my $today_epoch_2 = time();
    if ($today_epoch_1 ne $today_epoch_2) {
        die;
    }

    #
    # Get epoch value for what the image file is supposed to have
    #
    my $should_be_epoch = $new_image_dt->epoch();

    #
    # Compute the number of seconds between what the image is supposed to have
    # and 'now'
    #
    my $diff_in_seconds = $today_epoch_2 - $should_be_epoch;

    # my $new_epoch = $today_epoch_2 - $diff_in_seconds;

    # my $st = stat ($fq_picture);
    # my $epoch_timestamp = $st[9];

    my $last_access_time = $today_epoch_2;
    my $modify_time = $today_epoch_2;
    my $create_time = $today_epoch_2 - $diff_in_seconds;
    if ($pp_enable_file_writes) {
        SetFileTime ($fq_picture, $last_access_time, $modify_time, $create_time);
    }
}


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
# sub epoch_to_win_file_time {
#     my $dt = shift;

#     my $epoch = $dt->epoch();

#     my $years_diff = 1970 - 1601;
#     my $days_diff = $years_diff * 365;
#     my $seconds_diff = $days_diff * 24 * 60 * 60;

#     my $ftime;

#     return $ftime;
# }

sub get_pics_from_dir {
    my $fq_dirs_tested_ptr = shift;
    my $fq_dirs_to_test_list_ptr = shift;
    my $fq_pictures_ptr = shift;

    my $fq_dir = shift @$fq_dirs_to_test_list_ptr;

    push (@$fq_dirs_tested_ptr, $fq_dir);
    opendir (DIR, $fq_dir) or die "Can't open $fq_dir: $!";
    while (my $fff = readdir (DIR)) {
        my $ff = lc $fff;

        if ($ff eq 'system volume information') {
            next;
        }
        elsif ($ff eq '.' || $ff eq '..') {
            next;
        }
        elsif ($ff eq '$recycle.bin') {
            next;
        }
        elsif ($ff eq '.tmp.drivedownload') {
            next;
        }
            
        if (-d "$fq_dir/$ff") {
            push (@$fq_dirs_to_test_list_ptr, "$fq_dir/$ff");
        }
        else {
            my $fq_file = "$fq_dir/$ff";

            my ($name, $path, $suffix) = fileparse ($fq_file, @suffixlist);
            $path =~ s/\/\z//;

            if (length ($suffix) != 0) {
                push (@$fq_pictures_ptr, "$fq_file");
            }

            next;
        }
    }
    
    closedir (DIR);
}
