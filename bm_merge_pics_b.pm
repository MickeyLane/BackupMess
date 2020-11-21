#!/usr/bin/perl
package bm_merge_pics_b;
use warnings;
use strict;

use File::Compare;

my $enable_renames_flag = 1;

sub compare_hash_dirs {
    my $prune_hash_ptr = shift;
    my $other_hash_ptr = shift;
    my $limit = shift;
    my $debug = shift // 0;
    
    my %other_hash = %$other_hash_ptr;
    my %prune_hash = %$prune_hash_ptr;
    my $debug_value = 1;

    my $enable_rename_top_dir_flag = 1;

    my @prune_keys_list = keys %prune_hash;
    my @other_keys_list = keys %other_hash;
    if ($debug) {
        foreach my $key (@prune_keys_list) {
            my $val = $prune_hash{$key};
            my $string = sprintf ("%03d   {%s} = %s", $debug_value++, $key, $val);
            print ("  $string\n");
        }
    }
    my $prune_key_count = @prune_keys_list;
    my $other_key_count = @other_keys_list;
    print ("  Found $prune_key_count and $other_key_count files\n");
    
    if ($prune_key_count != $other_key_count) {
        #
        # Dirs have different number of files. Don't rename the top dir
        #
        $enable_rename_top_dir_flag = 0;
    }

    my @rename_list;
    foreach my $key (@other_keys_list) {
        if (exists ($prune_hash{$key}) && exists ($other_hash{$key})) {
            my $prune_file = $prune_hash{$key};        
            my $other_file = $other_hash{$key};
            if (compare ($prune_file, $other_file) == 0) {
                #
                # Files are the same
                #
                push (@rename_list, $prune_file);
            }
            else {
                #
                # Files are different
                #
                $enable_rename_top_dir_flag = 0;
            }
        }
    }

    if ($enable_rename_top_dir_flag) {
        #
        # Rename top dir
        # Should begin E:/Picture Backups/2016 12 15 +/YYYY/
        #
        my $first_file = $rename_list[0];
        my $len = 32;
        my $left = substr ($first_file, 0, $len);
        my $right = substr ($first_file, $len, 4);
        # print ("\$left = \"$left\", \$right = \"$right\"\n");

        my $old_dir_name = $left . $right;
        my $new_dir_name = $left . 'bm_x-' . $right;
        print ("  Entire dir is same\n");
        print ("  Renaming:\n");
        print ("    Old: $old_dir_name\n");
        print ("    New: $new_dir_name\n");

        if ($enable_renames_flag) {
            rename ($old_dir_name, $new_dir_name) or die "Can't rename $old_dir_name: $!";
            $limit--;
            if ($limit == 0) {
                return ($limit);
            }
        }
    }
    else {
        #
        # Rename individual files
        #
        foreach my $old (@rename_list) {
            my $new = $old;
            my $i = rindex ($new, '/');
            substr ($new, $i, 1, '/bm_x-');
            
            print ("  Renaming:\n");
            print ("    Old: $old\n");
            print ("    New: $new\n");

            if ($enable_renames_flag) {
                rename ($old, $new) or die "Can't rename $old: $!";
                $limit--;
                if ($limit == 0) {
                    return ($limit);
                }
            }
        }
    }
    
    return ($limit);
}

1;
