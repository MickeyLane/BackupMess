#!/usr/bin/perl
package bm_merge_pics_a;
use warnings;
use strict;

sub inventory_year_dirs {
    my ($prune, $other) = @_;
    
    print ("\nCompare $prune and $other\n");

    my ($prune_pic_list_ptr, $prune_tif_bytecount) = search_sub ($prune);
    my ($other_pic_list_ptr, $other_tif_bytecount) = search_sub ($other);

    if ($prune_tif_bytecount > 0 || $other_tif_bytecount > 0) {
        print ("Ignoring $prune_tif_bytecount and $other_tif_bytecount bytes of .tif files\n");
    }

    my $prune_file_count = @$prune_pic_list_ptr;
    my $other_file_count = @$other_pic_list_ptr;
    print ("Found $prune_file_count and $other_file_count files\n");

    return ($prune_pic_list_ptr, $prune_file_count, $other_pic_list_ptr, $other_file_count);
}

sub search_sub {
    my $root = shift;

    my @pic_list;
    my $tif_bytecount = 0;

    my @dirs_to_test_list = $root;
    my $count = @dirs_to_test_list;
    while ($count > 0) {

        my $dir = shift @dirs_to_test_list;

        opendir (DIR, $dir) or die "Can't open $dir: $!";
        while (my $file = readdir (DIR)) {
            if ($file =~ /^x-/ || $file =~ /^bm_x-/) {
                #
                # Works on files and directories
                #
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
                next;
            }

            my $this_dt = main::get_file_date_info ("$dir/$file");
            
            # my ($name, $path, $suffix) = fileparse ("$dir/$file", @suffixlist);
            # $path =~ s/\/\z//;

            my $i = rindex ($file, '.');
            my $suffix = substr ($file, $i);

            if ($suffix eq '.tif') {
                my @stat = stat ("$dir/$file");
                my $z = $stat[7];
                $tif_bytecount += $z;
            }
            elsif (length ($suffix) > 0) {
                push (@pic_list, "$dir/$file");
            }
        }
        close (DIR);

        $count = @dirs_to_test_list;
    }

    my $file_count = @pic_list;
    return (\@pic_list, $tif_bytecount);
}

1;
