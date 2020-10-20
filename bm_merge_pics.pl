#!C:/Strawberry/perl/bin/perl.exe
#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;

#
# Given a starting directory, check the last modify date of every non-directory
# file in the tree and modify the name of the starting directory (if authorized)
#
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

#
# Get input arguments
#
foreach my $switch (@ARGV) {
    print ("\$switch = \"$switch\"\n");
    if (index ($switch, 'dir=') != -1) {
        $dir_to_test = lc substr ($switch, 4);
        print ("\$dir_to_test = $dir_to_test\n");
        next;
    }

    print ("Don't know what to do with $switch\n");
    die;
}

if (length ($dir_to_test) == 0) {
    print ("No directory specified\n");
    exit (1);
}

print ("Checking $dir_to_test\n");

if (index ($dir_to_test, '/') != -1) {
    print ("Input has forward slashes. Use backslashes\n");
    exit (1);
}

if ($dir_to_test =~ /\d{4} \d{2} \d{2}/) {
    $dir_to_test_is_just_a_date_string = 1;
}

my $youngest_dt = DateTime->from_epoch (epoch => 10);  # init with *really* old time
my $youngest_filename;

my @dirs_to_test_list = $dir_to_test;
my $count = @dirs_to_test_list;
while ($count > 0) {

    my $dir = shift @dirs_to_test_list;

    opendir (DIR, $dir) or die "Can't open $dir: $!";
    while (my $file = readdir (DIR)) {
        if ($file =~ /^x-/ || $file =~ /^bm_x-/) {
            next;
        }
        elsif ($file eq 'System Volume Information') {
            next;
        }
        elsif ($file eq '.' || $file eq '..') {
            next;
        }
        elsif ($file eq '$RECYCLE.BIN') {
            next;
        }
        elsif ($file eq 'desktop.ini') {
            next;
        }
        
        if (-d "$dir/$file") {
            push (@dirs_to_test_list, "$dir/$file");
        }
        else {
            my $this_dt = get_file_date_info ("$dir/$file");
            if ($this_dt > $youngest_dt) {
                $youngest_dt = $this_dt;
                $youngest_filename = "$dir/$file";
            }
        }


    }
    close (DIR);
    $count = @dirs_to_test_list;
}

my $string = sprintf ("%04d %02d %02d", $youngest_dt->year(), $youngest_dt->month(), $youngest_dt->day());
print ("Youngest file found = $string\n");
print ("Name = $youngest_filename\n");

my $existing_paren_string = '';
my $existing_paren_date = '';
my $bare_dir_name;
my $possible_new_dir_name;

if ($dir_to_test_is_just_a_date_string) {
    #
    # Dir is <drive>:\<path>\YYYY MM DD
    #
    my $i = rindex ($dir_to_test, '\\');
    my $left = substr ($dir_to_test, 0, $i);
    $possible_new_dir_name = "$left/$string $checked_mark";
}
else {
    #
    # Does dir already have a date paren?
    #
    my $left_paren = index ($dir_to_test, '(');
    if ($left_paren != -1) {
        #
        # Dir name already has "(...)"
        #
        my $right_paren = rindex ($dir_to_test, ')');
        my $len = $right_paren - $left_paren + 1;
        $existing_paren_string = substr ($dir_to_test, $left_paren, $len);
        $existing_paren_date = substr ($existing_paren_string, 1, length ($existing_paren_string) - 2);
        print ("\$existing_paren_string = \"$existing_paren_string\"\n");
        print ("\$existing_paren_date = \"$existing_paren_date\"\n");
        $bare_dir_name = substr ($dir_to_test , 0, $left_paren - 1);
        print ("\$bare_dir_name = \"$bare_dir_name\"\n");

        $possible_new_dir_name = "$bare_dir_name ($string $checked_mark)";
    }
    else {
        $possible_new_dir_name = "$dir_to_test ($string $checked_mark)";
    }
}

if (-e $possible_new_dir_name) {
    print ("Possible new dir name \"$possible_new_dir_name\" already exists!\n");
    exit (1);
}

my $new_dir_name;
my $rename_flag = 0;
if ($dir_to_test ne $possible_new_dir_name) {
    print ("Rename \"$dir_to_test\" to \"$possible_new_dir_name\" [y/n] ");

    my $choice_string = uc <STDIN>;  # force uppercase
    $choice_string =~ s/[\r\n]+//;

    if ($choice_string eq 'Y') {
        $new_dir_name = $possible_new_dir_name;
        $rename_flag = 1;
    }
}

if ($rename_flag) {
    print ("Renaming $dir_to_test to $new_dir_name...\n");
    
    rename ($dir_to_test, $new_dir_name) or die "Can't rename $dir_to_test to $new_dir_name: $!";
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
