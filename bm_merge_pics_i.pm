#!/usr/bin/perl
package bm_merge_pics_i;
use warnings;
use strict;

sub select_input_dir_pair {
    my $dir_to_test = shift;
    
    #
    # Get list of possibles
    #
    my $root = 'E:/Picture Backups';
    my @unsorted_list;
    opendir (DIR, $root) or die "Can't open $root: $!";
    while (my $file = readdir (DIR)) {
        if ($file =~ /^\d{4} \d{2} \d{2}/) {
            push (@unsorted_list, $file);
        }
        else {
            print ("Ignoring $file\n");
        }
    }
    closedir (DIR);
    my @list = sort (@unsorted_list);

    if (defined ($dir_to_test)) {
        my $len = @list;
        for (my $i = 1; $i < $len; $i++) {
            if ($dir_to_test eq $list[$i]) {
                my $newer_selected_dir = "$root/$list[$i]";
                my $older_selected_dir = "$root/$list[$i - 1]";

                return ($newer_selected_dir, $older_selected_dir);
            }
        }
    }

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

    print ("\nChoose: ");

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
    
    return ($newer_selected_dir, $older_selected_dir);
}


1;
