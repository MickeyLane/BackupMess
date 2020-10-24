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

#
# COMMAND LINE ARGUMENTS
# ======================
#
# Set defaults
#
my $dir_to_test = '';
my $dir_to_test_is_just_a_date_string = 0;
my $checked_mark = '+';

# find (\&initial_find_function, 'E:/Picture Backups');


# exit (1);

my $root = 'E:/Picture Backups';
my @unsorted_list;
opendir (DIR, $root) or die "Can't open $root: $!";
while (my $file = readdir (DIR)) {
    if ($file =~ /\d{4} \d{2} \d{2}/) {
        push (@unsorted_list, $file);
    }
    else {
        print ("Ignoring $file\n");
    }
}
close (DIR);
my @list = sort (@unsorted_list);

# my $youngest_dt = DateTime->from_epoch (epoch => 10);  # init with *really* old time
# my $youngest_filename;

# my @dirs_to_test_list = $dir_to_test;
# my $count = @dirs_to_test_list;
# while ($count > 0) {

print ("Files:\n");
my $index = 0;
foreach my $file (@list) {
    my $c;
    if ($index > 0) {
        $c = sprintf ("%02d %s", $index, $file);
    }
    else {
        $c = sprintf ("   %s", $file);
    }
    $index++;

    print ("  $c\n");
    
    my $plus = index ($file, '+');
    if ($plus == -1) {
        print ("Check $file for youngest file\n");
        exit (1);
    }
}

print ("Choose: ");

my $choice_int = -1;
my $choice_string = uc <STDIN>;  # force uppercase
$choice_string =~ s/[\r\n]+//;
if ($choice_string =~ /\D/) {
    print ("Bad answer\n");
    exit (1);
}
$choice_int = int ($choice_string);
if ($choice_int < 1 || $choice_int >= $index) {
    print ("Bad answer\n");
    exit (1);
}

my $newer_selected_dir = "$root/$list[$choice_int]";
my $older_selected_dir = "$root/$list[$choice_int - 1]";

print ("Comparing \"$newer_selected_dir\" with \"$older_selected_dir\"\n");

undef (@unsorted_list);
opendir (DIR, $newer_selected_dir) or die "Can't open $newer_selected_dir: $!";
while (my $file = readdir (DIR)) {
    if ($file =~ /\d{4}/) {
        push (@unsorted_list, "$newer_selected_dir/$file");
    }
}
close (DIR);
my @newer_list = sort (@unsorted_list);

undef (@unsorted_list);
opendir (DIR, $older_selected_dir) or die "Can't open $older_selected_dir: $!";
while (my $file = readdir (DIR)) {
    if ($file =~ /\d{4}/) {
        push (@unsorted_list, "$older_selected_dir/$file");
    }
}
close (DIR);
my @older_list = sort (@unsorted_list);

my ($list_to_prune_ptr, $other_list_ptr) = select_shorter_list (\@newer_list, \@older_list);
my @list_to_prune = @$list_to_prune_ptr;
my $list_to_prune_count = @list_to_prune;
my @other_list = @$other_list_ptr;
my $other_list_count = @other_list;

print ("List lens are $list_to_prune_count and $other_list_count\n");

my $flag;
for (my $l2p = 0; $l2p < $list_to_prune_count; $l2p++) {
    for (my $ol = 0; $ol < $other_list_count; $ol++) {
        my $prune = $list_to_prune[$l2p];
        my $other = $other_list[$ol];

        my $i = rindex ($prune, '/');
        my $prune_name = substr ($prune, $i);

        $i = rindex ($other, '/');
        my $other_name = substr ($other, $i);

        if ($prune_name eq $other_name) {
            # my $same = compare_year_dirs ($prune, $other);
            my ($prune_files_ptr, $prune_files_count, $other_files_ptr, $other_files_count) =
                bm_merge_pics_a::inventory_year_dirs ($prune, $other);

            if ($prune_files_count > 0 && $prune_files_count == $other_files_count) {
                my $dirs_are_same = bm_merge_pics_b::compare_same_len_dirs ($prune_files_ptr, $other_files_ptr);
                # File::DirCompare->compare ($prune, $other, sub {$dirs_are_same = 0});

                if ($dirs_are_same) {
                    print ("SAME\n");
                }
            }
        }
    }
}



################################################################################################
#
#
#
sub get_file_date_info {
    my $filename = shift;

    my @stat = stat ($filename);
    # say $stat[9];
 
    my $modify_time = $stat[9]; # (stat($filename))[9];
    # say $modify_time;
    # say scalar localtime($modify_time);
 
    my $dt = DateTime->from_epoch (epoch => $modify_time);
    # say $dt;
 
    return ($dt);
}


sub select_shorter_list {
    my ($a, $b) = @_;

    my @a_list = @$a;
    my @b_list = @$b;

    my $a_count = @a_list;
    my $b_count = @b_list;

    print ("List lens are $a_count and $b_count\n");

    if ($a_count < $b_count) {
        return ($a, $b);
    }
    else {
        return ($b, $a);
    }
}


# sub find_function {
#     my @suffixlist = qw (.jpg .tif .gif);

#     my $f = $File::Find::name;

#     my ($name, $path, $suffix) = fileparse ($f, @suffixlist);
#     # $path =~ s/\/\z//;

#     if ($suffix eq '.tif') {
#         my @stat = stat ($f);
#         my $z = $stat[7];
#         $global_tif_bytecount += $z;
#     }
#     elsif (length ($suffix) > 0) {
#         push (@global_file_list, $f);
#     }
# }
