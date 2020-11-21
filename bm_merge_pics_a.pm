#!/usr/bin/perl
package bm_merge_pics_a;
use warnings;
use strict;

sub search_sub {
    my $root = shift;
    my $debug = shift // 0;

    my %pic_hash;
    my $tif_bytecount = 0;
    my $debug_value = 1;

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
                my $key = $file;
                my $val = "$dir/$file";

                $pic_hash{$key} = $val;

                if ($debug) {
                    my $string = sprintf ("%03d   {%s} = %s", $debug_value++, $key, $val);
                    print ("  $string\n");
                }
            }
        }
        closedir (DIR);

        $count = @dirs_to_test_list;
    }

    if ($tif_bytecount > 0) {
        print ("  In $root, ignoring $tif_bytecount bytes of .tif files\n");
    }

    my $key_count = keys %pic_hash;
    my $hash_count = %pic_hash;

    if ($key_count != $hash_count) {
        print ("WTF?\n");
        exit (1);
    }

    print ("  In $root, found $key_count files\n");

    return (\%pic_hash);
}

1;
