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
use Cwd qw(cwd);
use List::Util qw (shuffle);
use POSIX;
use File::Copy;
use DateTime;
use List::Util qw (max);

use lib '.';

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
        my $a1 = $list_to_prune[$l2p];
        my $b1 = $other_list[$ol];

        my $i = rindex ($a1, '/');
        my $a2 = substr ($a1, $i);

        $i = rindex ($b1, '/');
        my $b2 = substr ($b1, $i);

        if ($a2 eq $b2) {
            my $same = compare_year_dirs ($a1, $b1);
        }
    }
}

sub compare_year_dirs {
    my ($a, $b) = @_;
    
    print ("Compare $a and $b\n");

    return (0);
}

# my $string = sprintf ("%04d %02d %02d", $youngest_dt->year(), $youngest_dt->month(), $youngest_dt->day());
# print ("Youngest file found = $string\n");
# print ("Name = $youngest_filename\n");

# my $existing_paren_string = '';
# my $existing_paren_date = '';
# my $bare_dir_name;
# my $possible_new_dir_name;

# if ($dir_to_test_is_just_a_date_string) {
#     #
#     # Dir is <drive>:\<path>\YYYY MM DD
#     #
#     my $i = rindex ($dir_to_test, '\\');
#     my $left = substr ($dir_to_test, 0, $i);
#     $possible_new_dir_name = "$left/$string $checked_mark";
# }
# else {
#     #
#     # Does dir already have a date paren?
#     #
#     my $left_paren = index ($dir_to_test, '(');
#     if ($left_paren != -1) {
#         #
#         # Dir name already has "(...)"
#         #
#         my $right_paren = rindex ($dir_to_test, ')');
#         my $len = $right_paren - $left_paren + 1;
#         $existing_paren_string = substr ($dir_to_test, $left_paren, $len);
#         $existing_paren_date = substr ($existing_paren_string, 1, length ($existing_paren_string) - 2);
#         print ("\$existing_paren_string = \"$existing_paren_string\"\n");
#         print ("\$existing_paren_date = \"$existing_paren_date\"\n");
#         $bare_dir_name = substr ($dir_to_test , 0, $left_paren - 1);
#         print ("\$bare_dir_name = \"$bare_dir_name\"\n");

#         $possible_new_dir_name = "$bare_dir_name ($string $checked_mark)";
#     }
#     else {
#         $possible_new_dir_name = "$dir_to_test ($string $checked_mark)";
#     }
# }

# if (-e $possible_new_dir_name) {
#     print ("Possible new dir name \"$possible_new_dir_name\" already exists!\n");
#     exit (1);
# }

# my $new_dir_name;
# my $rename_flag = 0;
# if ($dir_to_test ne $possible_new_dir_name) {
#     print ("Rename \"$dir_to_test\" to \"$possible_new_dir_name\" [y/n] ");

#     my $choice_string = uc <STDIN>;  # force uppercase
#     $choice_string =~ s/[\r\n]+//;

#     if ($choice_string eq 'Y') {
#         $new_dir_name = $possible_new_dir_name;
#         $rename_flag = 1;
#     }
# }

# if ($rename_flag) {
#     print ("Renaming $dir_to_test to $new_dir_name...\n");
    
#     rename ($dir_to_test, $new_dir_name) or die "Can't rename $dir_to_test to $new_dir_name: $!";
# }

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
