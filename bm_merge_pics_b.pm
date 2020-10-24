#!/usr/bin/perl
package bm_merge_pics_b;
use warnings;
use strict;

sub compare_same_len_dirs {
    my ($prune_files_ptr, $other_files_ptr) = @_;
    
    my $test_string = 'E:/Picture Backups/';
    my $test_string_len = length ($test_string);
    
    my @prune_files = @$prune_files_ptr;
    my @other_files = @$other_files_ptr;
    
    #
    # Verify that the two lists are under the same E:\Picture Backups dir
    #
    if (!($prune_files[0] =~ /E:\/Picture Backups/) || !($other_files[0] =~ /E:\/Picture Backups/)) {
        print ("Lists start with:\n");
        print ("  $prune_files[0]\n");
        print ("  $other_files[0]\n");
        exit (1);
    }

    foreach my $of (@other_files) {
        print ("$of\n");
    }

    exit (1);
}


1;
