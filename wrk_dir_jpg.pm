#!/usr/bin/perl
package wrk_dir_jpg;
use warnings FATAL => 'all';
use strict;

use File::Compare;
use File::Basename;

use lib '.';
use wrk_dir_lib;

my @suffixlist = qw (.jpg .jpeg);
my $pp_report_anyway = 0;

sub process_dates_in_jpg_file {
    my ($pp_root, $fq_picture, $enable_file_writes, $using_test_pic) = @_;

    my $return_status;
    my $image_date_year;
    my $image_date_string;
    my $image_does_not_have_a_date_flag;
    my @report;

    my ($name, $path, $suffix) = fileparse ($fq_picture, @suffixlist);
    $path =~ s/\/\z//;

    my $should_be_year = wrk_dir_lib::get_should_be_year ($pp_root, $fq_picture);

    # if ($name =~ /(\d{4})/) {
    #     my $year_in_file_name = $1;
    #     if ($year_in_file_name ne $should_be_year) {
    #         push (@report, "The file name contains a date that is different from it's filed-under date: $year_in_file_name");
    #         die;
    #     }
    # }

    my ($new_image_dt, $new_image_date_string) = wrk_dir_lib::make_image_should_be_date ($should_be_year);

    #
    # Read image from file into memory
    #
    my $image = new Image::MetaData::JPEG ($fq_picture);
    if (!(defined ($image))) {
        my $msg = Image::MetaData::JPEG::Error();
        my $err_message = "fail to make image object: $msg";
        return (2, $err_message);
    }

    #
    # For debug...
    #
    # print $image->get_description();
    # push (@report, "Process_dates_in_jpg_file()...");
    # push (@report, "  $fq_picture");
    push (@report, "  Should be: $should_be_year");

    #
    # Get all of the tag data from the image
    #
    my $image_data = $image->get_Exif_data('ALL');

    #
    # Extract dates. They may not exist
    #
    my ($ifd0_image_dt, $subifd_image_dt) = get_image_date ($image_data);

    #
    # Deal with creation date under IFD0_DATA
    # ---------------------------------------
    #
    if (defined ($ifd0_image_dt)) {
        $image_date_string = sprintf ("%04d %02d %02d",
            $ifd0_image_dt->year(), $ifd0_image_dt->month(), $ifd0_image_dt->day());
        $image_date_year = $ifd0_image_dt->year();
        $image_does_not_have_a_date_flag = 0;
    }
    else {
        $image_date_string = "No date in image";
        $image_date_year = "YYYY";
        $image_does_not_have_a_date_flag = 1;
    }
    
    push (@report, "  IFD0 image date: $image_date_year");

    # if ($should_be_year ne $image_date_year || $using_test_pic || $pp_report_anyway) {
    #     foreach my $r (@report) {
    #         print ("$r\n");
    #     }
    # }

    if ($should_be_year ne $image_date_year) {
        my $new_image_action;
        if ($image_does_not_have_a_date_flag) {
            $new_image_action = 'ADD';
            push (@report, "  Adding \"$new_image_date_string\"");
        }
        else {
            $new_image_action = 'REPLACE';
            push (@report, "  Replacing with \"$new_image_date_string\"");
        }

        #
        # JPEG::set_Exif_data
        #    [arguments: ($data, $what, $action)]
        #
        # https://metacpan.org/pod/distribution/Image-MetaData-JPEG/lib/Image/MetaData/JPEG.pod
        #

        my $hash_ptr = $image->set_Exif_data ({'DateTime' => $new_image_date_string}, 'IMAGE_DATA', $new_image_action);
        my $result = check_set_exif_data_results ($hash_ptr, $image, $fq_picture, $enable_file_writes);

        if ($result == 0) {
            foreach my $r (@report) {
                print ("$r\n");
            }
            return (5, undef);  # error trying to add new or modified tag
        }
    }
    else {
        push (@report, "  Not attempting to modify IFD0 tags");
    }

    #
    # Deal with creation date under SUBIFD_DATA
    # -----------------------------------------
    #
    if (defined ($subifd_image_dt)) {
        $image_date_string = sprintf ("%04d %02d %02d",
            $subifd_image_dt->year(), $subifd_image_dt->month(), $subifd_image_dt->day());
        $image_date_year = $subifd_image_dt->year();
        $image_does_not_have_a_date_flag = 0;
    }
    else {
        $image_date_string = "No date in image";
        $image_date_year = "YYYY";
        $image_does_not_have_a_date_flag = 1;
    }

    push (@report, "  SUBIFD image date: $image_date_year");

    if ($should_be_year ne $image_date_year) {
        my $new_image_action;
        if ($image_does_not_have_a_date_flag) {
            $new_image_action = 'ADD';
            push (@report, "  Adding \"$new_image_date_string\"\n");
        }
        else {
            $new_image_action = 'REPLACE';
            push (@report, "  Replacing with \"$new_image_date_string\"\n");
        }
        my $hash_ptr = $image->set_Exif_data ({'DateTimeOriginal' => $new_image_date_string}, 'IMAGE_DATA', $new_image_action);
        my $result = check_set_exif_data_results ($hash_ptr, $image, $fq_picture, $enable_file_writes);

        if ($result == 0) {
            foreach my $r (@report) {
                print ("$r\n");
            }
            return (5, undef);  # error trying to add new or modified tag
        }

        return (4, undef); # good
    }
    else {
        #
        # Image date matches should be date
        #
        if ($using_test_pic || $pp_report_anyway) {
            foreach my $r (@report) {
                print ("$r\n");
            }
        }

        return (1, undef);
    }
}

sub get_image_date {
    my ($image_data) = @_;

    my $ifd0_image_dt;
    my $subifd_image_dt;

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

        if ($top_level_key eq 'IFD0_DATA') {
            my $ifd0_data = $h;
            while (my ($ifd_key, $ifd_val) = each %$ifd0_data) {
                if ($ifd_key eq 'DateTime') {
                    my @date_time_records = @$ifd_val;

                    my $count = @date_time_records;

                    if ($count == 1) {
                        my $record = $date_time_records[0];
                        # print ("  From $top_level_key, setting \$image_dt to $record\n");
                        if ($record =~ /(\d{4}):(\d{2}):(\d{2})/) {
                            $ifd0_image_dt = DateTime->new(
                                    year       => $1,
                                    month      => $2,
                                    day        => $3);
                        }
                    }

                    next;
                }
                elsif ($ifd_key eq 'Orientation') {
                    next;
                }
                elsif ($ifd_key eq 'Software') {
                    next;
                }
                elsif ($ifd_key eq 'Make') {
                    next;
                }
                elsif ($ifd_key =~ /^Unknown_tag/) {
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
                elsif ($ifd_key eq 'ReferenceBlackWhite') {
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
                elsif ($ifd_key eq 'Model') {
                    next;
                }
                elsif ($ifd_key eq 'JPEGInterchangeFormat') {
                    next;
                }
                elsif ($ifd_key eq 'Model') {
                    next;
                }
                elsif ($ifd_key eq 'YCbCrPositioning' || $ifd_key eq 'YCbCrCoefficients') {
                    next;
                }
                elsif ($ifd_key eq 'Artist') {
                    print ("  $top_level_key\n");
                    print ("    $ifd_key\n");
                    my @array = $top_level_key;
                    foreach my $a (@array) {
                        print ("      $a\n");
                    }
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
                # die;
            }
        }
        elsif ($top_level_key eq 'IFD1_DATA') {
            my $ifd1_data = $h;
            while (my ($ifd1_key, $ifd1_val) = each %$ifd1_data) {
                if ($ifd1_key eq 'Compression') {
                    next;
                }
                elsif ($ifd1_key eq 'XResolution' || $ifd1_key eq 'YResolution') {
                    next;
                }
                elsif ($ifd1_key eq 'ResolutionUnit') {
                    next;
                }
                elsif ($ifd1_key eq 'JPEGInterchangeFormatLength') {
                    next;
                }
                elsif ($ifd1_key eq 'JPEGInterchangeFormat') {
                    next;
                }
                elsif ($ifd1_key eq 'ImageLength' || $ifd1_key eq 'ImageWidth') {
                    next;
                }
                elsif ($ifd1_key =~ /^Unknown_tag/) {
                    # print ("Ignoring IFD1_DATA tag $ifd1_key\n");
                    next;
                }

                print ("$top_level_key\n");
                print ("  $ifd1_key  $ifd1_val\n");
                # die;
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
            my $gps_data = $h;
            # my @keys = keys %gps_data;
            # my $count = @keys;
            # if ($count > 0) {
            #     print ("$top_level_key\n");
            #     while (my ($dd, $hh) = each %gps_data) {
            #         if ($dd eq 'Orientation') {
            #             my @orientation_records = @$hh;

            #             foreach my $or (@orientation_records) {
            #                 print ("    $or\n");
            #             }
            #         }
            #     }
            # }
            while (my ($gps_key, $gps_val) = each %$gps_data) {
                if ($gps_key eq 'Orientation') {
                    #
                    # This is an ARRAY
                    #
                    my @orientation_records = @$gps_val;
                    my $count = @orientation_records;
                    next;
                }
                elsif ($gps_key eq 'GPSMapDatum') {
                    next;
                }
                elsif ($gps_key eq 'GPSVersionID') {
                    next;
                }

                print ("$top_level_key\n");
                print ("  $gps_key  $gps_val\n");
                # die;
            }
        }
        elsif ($top_level_key eq 'INTEROP_DATA') {
            my $interop_data = $h;
            while (my ($id_key, $id_val) = each %$interop_data) {
                if ($id_key eq 'InteroperabilityVersion') {
                    #
                    # This is an ARRAY
                    #
                    next;
                }
                elsif ($id_key eq 'InteroperabilityIndex') {
                    next;
                }

                print ("$top_level_key\n");
                print ("  $id_key  $id_val\n");
                # die;
            }
        }
        elsif ($top_level_key eq 'SUBIFD_DATA') {
            my $subifd_data = $h;
            while (my ($ifd_key, $ifd_val) = each %$subifd_data) {
                if ($ifd_key eq 'PixelYDimension' || $ifd_key eq 'PixelXDimension') {
                    #
                    # This is an ARRAY
                    #
                    next;
                }
                elsif ($ifd_key eq 'SubSecTimeOriginal') {
                    #
                    # This is an ARRAY
                    #
                    my @original_time_records = @$ifd_val;
                    my $count = @original_time_records;
                    next;
                }
                elsif ($ifd_key eq 'FlashpixVersion') {
                    next;
                }
                elsif ($ifd_key eq 'CustomRendered') {
                    next;
                }
                elsif ($ifd_key eq 'SubSecTime') {
                    next;
                }
                elsif ($ifd_key eq 'UserComment') {
                    next;
                }
                elsif ($ifd_key eq 'Contrast') {
                    next;
                }
                elsif ($ifd_key eq 'Saturation') {
                    next;
                }
                elsif ($ifd_key eq 'WhiteBalance') {
                    next;
                }
                elsif ($ifd_key eq 'ExifVersion') {
                    next;
                }
                elsif ($ifd_key eq 'ColorSpace') {
                    next;
                }
                elsif ($ifd_key eq 'Sharpness') {
                    next;
                }
                elsif ($ifd_key eq 'DigitalZoomRatio') {
                    next;
                }
                elsif ($ifd_key eq 'ComponentsConfiguration') {
                    next;
                }
                elsif ($ifd_key eq 'SceneCaptureType') {
                    next;
                }
                elsif ($ifd_key eq 'ExposureMode') {
                    next;
                }
                elsif ($ifd_key eq 'DateTimeOriginal') {
                    my @date_time_records = @$ifd_val;
                    my $count = @date_time_records;

                    if ($count == 1) {
                        my $record = $date_time_records[0];
                        # print ("  From SUBIFD_DATA, setting \$image_dt to $record\n");
                        if ($record =~ /(\d{4}):(\d{2}):(\d{2})/) {
                            $subifd_image_dt = DateTime->new(
                                    year       => $1,
                                    month      => $2,
                                    day        => $3);
                        }
                    }

                    next;
                }
                elsif ($ifd_key eq 'FileSource') {
                    my @file_source_records = @$ifd_val;
                    my $count = @file_source_records;

                    foreach my $fsr (@file_source_records) {
                        print ("  $fsr\n");
                    }

                    next;
                }
                elsif ($ifd_key =~ /^Unknown_tag/) {
                    next;
                }
                elsif ($ifd_key eq 'MeteringMode') {
                    next;
                }
                elsif ($ifd_key eq 'ISOSpeedRatings') {
                    next;
                }
                elsif ($ifd_key eq 'ExposureIndex') {
                    next;
                }
                elsif ($ifd_key eq 'ExposureMode') {
                    next;
                }
                elsif ($ifd_key eq 'LightSource') {
                    next;
                }
                elsif ($ifd_key eq 'ResolutionUnit') {
                    next;
                }
                elsif ($ifd_key eq 'FocalPlaneXResolution' || $ifd_key eq 'FocalPlaneYResolution') {
                    next;
                }
                elsif ($ifd_key eq 'FocalPlaneResolutionUnit') {
                    next;
                }
                elsif ($ifd_key eq 'FocalPlaneResolution') {
                    next;
                }
                elsif ($ifd_key eq 'ExposureBiasValue') {
                    next;
                }
                elsif ($ifd_key eq 'ExposureProgram') {
                    next;
                }
                elsif ($ifd_key eq 'ExposureTime') {
                    next;
                }
                elsif ($ifd_key eq 'ShutterSpeedValue') {
                    next;
                }
                elsif ($ifd_key eq 'BrightnessValue') {
                    next;
                }
                elsif ($ifd_key eq 'MaxApertureValue') {
                    next;
                }
                elsif ($ifd_key eq 'SensingMethod') {
                    next;
                }
                elsif ($ifd_key eq 'ApertureValue') {
                    next;
                }
                elsif ($ifd_key eq 'FocalLength') {
                    next;
                }
                elsif ($ifd_key eq 'SceneType') {
                    next;
                }
                elsif ($ifd_key eq 'SubjectDistance') {
                    next;
                }
                elsif ($ifd_key eq 'Flash') {
                    next;
                }
                elsif ($ifd_key eq 'FNumber') {
                    next;
                }
                elsif ($ifd_key eq 'CompressedBitsPerPixel') {
                    next;
                }
                elsif ($ifd_key eq 'SubSecTimeDigitized') {
                    my @time_records = @$ifd_val;
                    my $count = @time_records;
                    
                    next;
                }
                elsif ($ifd_key eq 'DateTimeDigitized') {
                    
                    next;
                }
                
                print ("$top_level_key\n");
                print ("  $ifd_key  $ifd_val\n");
                # die;
            }
        }
        elsif ($top_level_key eq 'MAKERNOTE_DATA') {
            my $makernote_data = $h;
            while (my ($md_key, $md_val) = each %$makernote_data) {
                if ($md_key eq 'FirmwareVersion') {
                    next;
                }
                elsif ($md_key eq 'CameraSettings') {
                    next;
                }
                elsif ($md_key eq 'CameraSerialNumber') {
                    next;
                }
                elsif ($md_key eq 'ImageType') {
                    next;
                }
                elsif ($md_key eq 'ShotInfo') {
                    next;
                }
                elsif ($md_key eq 'OwnerName') {
                    next;
                }
                elsif ($md_key eq 'Canon-A0Tag') {
                    next;
                }
                elsif ($md_key =~ /^Unknown_tag/) {
                    # print ("Ignoring MAKERNOTE_DATA tag $md_key\n");
                    next;
                }

                print ("$top_level_key\n");
                print ("  $md_key  $md_val\n");
                # die;
            }
        }
        else {
            print ("Not processing $top_level_key!\n");
        }
    }

    return ($ifd0_image_dt, $subifd_image_dt);
}

sub check_set_exif_data_results {
    my $hash_ptr = shift;
    my $image = shift;
    my $fq_picture = shift;
    my $enable_file_writes = shift;
    
    my %hash = %$hash_ptr;
    if (%hash) {
        #
        #
        #
        print ("Error reported from set_Exif_data...\n");
        while (my ($err_key, $err_val) = each %hash) {
            print ("  $err_key   $err_val\n");
        }
        
        return (0); 
    }
    else {
        print ("     Success\n");
        if ($enable_file_writes) {
            $image->save ($fq_picture) or die "Save failed";
        }
        else {
            print ("  *** Save disabled ***\n");
        }

        return (1);
    }
}

1;
