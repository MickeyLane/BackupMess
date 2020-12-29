#!/usr/bin/perl
package wrk_dir_jpg;
use warnings;
use strict;

use File::Compare;

sub process_dates_in_jpg_file {
    my ($pp_root, $path, $fq_picture) = @_;

    my $return_status;

    my $should_be_year;
    if ($path =~ /\Q$pp_root/) {
        my $temp = substr ($path, 12);
        $should_be_year = substr ($temp, 0, 4);
    }
    else {
        return (3);  # bad file path
    }

    my $image = new Image::MetaData::JPEG ($fq_picture);
    if (!(defined ($image))) {
        my $msg = Image::MetaData::JPEG::Error();
        print ("Fail to make image object: $msg\n)";
        return (2);  # can't process image data
    }

    # print $image->get_description();

    my @report = "$fq_picture";

    my $image_data = $image->get_Exif_data('ALL');

    my $image_date_year;
    my $image_date_string;
    my $image_does_not_have_a_date_flag = 0;
    my $image_dt = get_image_date ($image_data);
    if (defined ($image_dt)) {
        $image_date_string = sprintf ("%04d %02d %02d", $image_dt->year(), $image_dt->month(), $image_dt->day());
        $image_date_year = $image_dt->year();
    }
    else {
        $image_date_string = "No date in image";
        $image_date_year = "YYYY";
        $image_does_not_have_a_date_flag = 1;
    }
    
    #
    # Get file creation date
    #



    my $stop_flag = 0;
    push (@report, "  Should be: $should_be_year");
    push (@report, "  Image date: $image_date_year");

    if ($name =~ /(\d{4})/) {
        my $year_in_file_name = $1;
        if ($year_in_file_name ne $should_be_year) {
            push (@report, "  Different date in file name: $year_in_file_name");
            $stop_flag = 1;
        }
    }

    if ($stop_flag || $should_be_year ne $image_date_year) {
        foreach my $r (@report) {
            print ("$r\n");
        }
    }

    if ($stop_flag == 1) {
        last;
    }

    if ($should_be_year ne $image_date_year) {
        my ($new_image_dt, $new_image_date_string) = make_image_should_be_date ($should_be_year);

        my $new_image_action = 'REPLACE';
        if ($image_does_not_have_a_date_flag) {
            $new_image_action = 'ADD';
            print ("  Adding \"$new_image_date_string\"\n");
        }
        else {
            print ("  Replacing with \"$new_image_date_string\"\n");
        }

        my $hash_ptr = $image->set_Exif_data ({'DateTime' => $new_image_date_string}, 'IMAGE_DATA', $new_image_action);
        my %hash = %$hash_ptr;
        if (%hash) {
            #
            #
            #
            print ("Error reported from set_Exif_data...\n");
            while (my ($err_key, $err_val) = each %hash) {
                print ("  $err_key   $err_val\n");
            }
            die; 
        }
        else {
            print ("     Success\n");
            if (0) {
                $image->save ($fq_picture) or die "Save failed";
            }
            else {
                print ("  *** Save disabled ***\n");
            }
        }

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
        SetFileTime ($fq_picture, $last_access_time, $modify_time, $create_time);
    }
    else {
        $pics_with_good_dates++;
    }
}

sub get_image_date {
    my ($image_data) = @_;

    my $image_dt;

    while (my ($top_level_key, $h) = each %$image_data) {
        #
        # SUBIFD_DATA
        # INTEROP_DATA
        # MAKERNOTE_DATA
        # IFD0_DATA
        # GPS_DATA
        # ROOT_DATA
        # IFD1_DATA
        #
        # print ("$top_level_key\n");

        if ($top_level_key eq 'IFD0_DATA' || $top_level_key eq 'IFD1_DATA') {
            my $ifd0_data = $h;
            while (my ($ifd_key, $ifd_val) = each %$ifd0_data) {
                if ($ifd_key eq 'DateTime') {
                    my @date_time_records = @$ifd_val;

                    my $count = @date_time_records;

                    if ($count == 1) {
                        my $record = $date_time_records[0];
                        # print ("  $record\n");
                        if ($record =~ /(\d{4}):(\d{2}):(\d{2})/) {
                            my $image_dt = DateTime->new(
                                    year       => $1,
                                    month      => $2,
                                    day        => $3);

                            return ($image_dt);
                        }
                    }
                }
                elsif ($ifd_key eq 'Orientation') {
                    next;
                }
                elsif ($ifd_key eq 'Software') {
                    next;
                }
                elsif ($ifd_key eq 'Unknown_tag_59932' || $ifd_key eq 'Unknown_tag_11') {
                    next;
                }
                elsif ($ifd_key eq 'YResolution') {
                    next;
                }
                elsif ($ifd_key eq 'XResolution') {
                    next;
                }
                elsif ($ifd_key eq 'ResolutionUnit') {
                    next;
                }
                elsif ($ifd_key eq 'SamplesPerPixel') {
                    next;
                }
                elsif ($ifd_key eq 'ImageLength' || $ifd_key eq 'ImageWidth') {
                    next;
                }
                elsif ($ifd_key eq 'StripOffsets') {
                    next;
                }
                elsif ($ifd_key eq 'PlanarConfiguration') {
                    next;
                }
                elsif ($ifd_key eq 'PhotometricInterpretation') {
                    next;
                }
                elsif ($ifd_key eq 'Compression') {
                    next;
                }
                elsif ($ifd_key eq 'RowsPerStrip') {
                    next;
                }
                elsif ($ifd_key eq 'StripByteCounts') {
                    next;
                }
                elsif ($ifd_key eq 'BitsPerSample') {
                    next;
                }
                elsif ($ifd_key eq 'NewSubfileType') {
                    next;
                }
                elsif ($ifd_key eq 'Predictor') {
                    next;
                }
                elsif ($ifd_key eq 'XML_Packet') {
                    next;
                }
                elsif ($ifd_key eq 'YCbCrPositioning') {
                    next;
                }
                elsif ($ifd_key eq 'PhotoshopImageResources') {
                    print ("  $top_level_key\n");
                    print ("    $ifd_key\n");
                    my @resources = @$ifd_val;
                    my $max_to_report = 10;
                    foreach my $r (@resources) {
                        print ("      $r\n");
                        $max_to_report--;
                        if ($max_to_report == 0) {
                            last;
                        }
                    }
                    next;
                }

                print ("$top_level_key\n");
                print ("  $ifd_key  $ifd_val\n");
                die;
            }
        }
        elsif ($top_level_key eq 'ROOT_DATA') {
            # print ("$d\n");
            # my $root_data = $h;
            # while (my ($dd, $hh) = each %$root_data) {
            #     print (" $dd  $hh\n");
            # }
        }
        elsif ($top_level_key eq 'GPS_DATA') {
            my %gps_data = %$h;
            my @keys = keys %gps_data;
            my $count = @keys;
            if ($count > 0) {
                print ("  $top_level_key\n");
                while (my ($dd, $hh) = each %gps_data) {
                    if ($dd eq 'Orientation') {
                        my @orientation_records = @$hh;

                        foreach my $or (@orientation_records) {
                            print ("    $or\n");
                        }
                    }
                }
            }
        }
    }

    return (undef);
}

1;
