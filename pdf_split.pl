#!/usr/bin/perl

use strict;
use warnings;

use CAM::PDF;

my $pdffile = shift;
my $pdfout  = shift;

my $pdf = CAM::PDF->new($pdffile) or die $CAM::PDF::errstr;

foreach my $pagenum (1..$pdf->numPages) {

    # get some values for cropping
    my $pagedict          = $pdf->getPage(1);
    my ($objnum, $gennum) = $pdf->getPageObjnum(1);
    my $oldbox            = $pdf->getValue($pagedict->{CropBox} || $pagedict->{MediaBox});
    my @box               = map {$pdf->getValue($_)} @{$oldbox};

    # add the page twice and crop it
    my $duplicate = CAM::PDF->new($pdffile) or die $CAM::PDF::errstr;
    $duplicate->extractPages($pagenum);
    $pdf->appendPDF($duplicate);
    $pdf->appendPDF($duplicate);

    $pagedict = $pdf->getPage($pdf->numPages);
    $pagedict->{CropBox} = CAM::PDF::Node->new('array', [
       map {CAM::PDF::Node->new('number', $_)} $box[0], $box[1], $box[2], ($box[3]+$box[1])/2
    ]);

    $pagedict = $pdf->getPage($pdf->numPages - 1);
    $pagedict->{CropBox} = CAM::PDF::Node->new('array', [
       map {CAM::PDF::Node->new('number', $_)} $box[0], ($box[3]+$box[1])/2, $box[2], $box[3]
    ]);

    if ($objnum) {
       $pdf->{changes}->{$objnum} = 1;
    }

    $pdf->deletePage(1);
}

$pdf->cleanoutput($pdfout);
