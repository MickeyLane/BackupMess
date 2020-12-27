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
use bm_merge_pics_select_input;

package main;

my $dir_to_test = '';
my $limit = 9999;

#
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
    elsif (index ($switch, 'limit=') != -1) {
        $limit = lc substr ($switch, 6);
        print ("\$limit = $limit\n");
        next;
    }
    print ("Don't know what to do with $switch\n");
    die;
}

#
# Set up dirs to compare
#
my ($newer_selected_dir, $older_selected_dir) = bm_merge_pics_select_input::select_input_dir_pair ($dir_to_test);
print ("Comparing \"$newer_selected_dir\" with \"$older_selected_dir\"\n");

#
# Get top level dirs in each
#
my $newer_list_ptr = find_top_level_dirs ($newer_selected_dir);
my $older_list_ptr = find_top_level_dirs ($older_selected_dir);
if (!(defined ($newer_list_ptr)) || !(defined ($older_list_ptr))) {
    print ("Nothing to do\n");
    exit (1);
}

#
# If different sizes, try to reduce the shorter one
#
my ($list_to_prune_ptr, $other_list_ptr) = select_shorter_list ($newer_list_ptr, $older_list_ptr);
my @list_to_prune = @$list_to_prune_ptr;
my $list_to_prune_count = @list_to_prune;
my @other_list = @$other_list_ptr;
my $other_list_count = @other_list;

print ("  List lens are $list_to_prune_count and $other_list_count\n");

my $flag;
for (my $l2p = 0; $l2p < $list_to_prune_count; $l2p++) {
    for (my $ol = 0; $ol < $other_list_count; $ol++) {
        my $prune = $list_to_prune[$l2p];
        my $other = $other_list[$ol];

        if ($prune eq $other) {
            print ("Broken\n");
            exit (1);
        }

        my $i = rindex ($prune, '/');
        my $prune_name = substr ($prune, $i);

        $i = rindex ($other, '/');
        my $other_name = substr ($other, $i);

        # print ("  \$prune_name = $prune_name, \$other_name = $other_name\n");
        
        if ($prune_name eq $other_name) {
            print ("\nCompare $prune and $other\n");
            my ($prune_hash_ptr) = bm_merge_pics_a::search_sub ($prune);
            my ($other_hash_ptr) = bm_merge_pics_a::search_sub ($other);

            # my ($prune_hash_ptr, $other_hash_ptr) = bm_merge_pics_a::inventory_year_dirs ($prune, $other);

            if (%$prune_hash_ptr && %$other_hash_ptr) {
               bm_merge_pics_b::compare_hash_dirs ($prune_hash_ptr, $other_hash_ptr, $limit);
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

sub find_top_level_dirs {
    my $dir = shift;

    my @unsorted_list;
    opendir (DIR, $dir) or die "Can't open $dir: $!";
    while (my $file = readdir (DIR)) {
        if ($file =~ /^\./) {
            next;
        }

        if ($file =~ /^\d{4}/) {
            #
            # File begines with YYYY
            #
            if (length ($file) != 4) {
                #
                # But it includes something else
                #
                next;
            }
        }

        my $fully_qualified_name = "$dir/$file";
        
        if (-d $fully_qualified_name) {
            push (@unsorted_list, $fully_qualified_name);
        }
    }
    closedir (DIR);

    my $count = @unsorted_list;
    if ($count == 0) {
        return (undef);
    }

    my @sorted_list = sort (@unsorted_list);

    return (\@sorted_list);
}