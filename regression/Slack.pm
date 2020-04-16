#!/usr/bin/env perl

###############################################################################
 #
 #  This file is part of canu, a software program that assembles whole-genome
 #  sequencing reads into contigs.
 #
 #  This software is based on:
 #    'Celera Assembler' r4587 (http://wgs-assembler.sourceforge.net)
 #    the 'kmer package' r1994 (http://kmer.sourceforge.net)
 #
 #  Except as indicated otherwise, this is a 'United States Government Work',
 #  and is released in the public domain.
 #
 #  File 'README.licenses' in the root directory of this distribution
 #  contains full conditions and disclaimers.
 ##

package Slack;

require Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw(checkSlack postHeading postFile postText);

use strict;
use warnings;

use JSON::PP;
use FindBin;

#  Fail if we don't have a slack token defined.
sub checkSlack () {
    if (! -e "$FindBin::RealBin/regression/slack-token") {
        die "Failed to find regression/slack-token.\n";
    }
}

#  Post the input hash reference to slack.
sub postToSlack ($) {
    my $json          = shift @_;
    my $jsonformatter = JSON::PP->new();
    my $encoded       = $jsonformatter->pretty->encode($json);
    my $authtoken     = $ENV{'CANU_REGRESSION_TOKEN'};

    open(F, "< $FindBin::RealBin/regression/slack-token");
    $authtoken = <F>;   chomp $authtoken;
    close(F);

    open(LOG, "> mesg.json");
    print LOG $encoded;
    close(LOG);

    #print  "curl -H 'Content-Type: application/json' -X POST -d \@mesg.json $authtoken\n";
    system("curl -H 'Content-Type: application/json' -X POST -d \@mesg.json $authtoken > /dev/null 2>&1");

    unlink("mesg.json");
}


#  Post a short message.
#
#  This uses BlockKit.  That seems to (nicely) start any new message on a line after the bot name.
#
#  WARNING: they're fixed-width blocks though.
#
sub postHeading ($) {
    my $mesg = shift @_;
    my $json = {};
    my $text = {};
    my $jsonformatter = JSON::PP->new();

    return   if (!defined($mesg));

    $json->{'blocks'} = [ ];

    $text->{'type'} = "section";
    $text->{'text'} = { 'type' => 'mrkdwn',
                        'text' => $mesg };

    push @{ $json->{'blocks'} }, $text;

    postToSlack($json);
}


#  Posts a file as a code block.
#
#  This does not, and can not, use the fancy BlockKit messages.  Those
#  seem to have an annoying fixed width setting, and our long-line
#  messages always wrap (regardless of how wide you make the window).
#
#  Sending a plain old text message seems to let it be full width.
#
sub postFile ($$) {
    my $mesg = shift @_;
    my $file = shift @_;
    my $text;
    my $json = {};
    my $jsonformatter = JSON::PP->new();

    postHeading($mesg);

    if (! open(FIL, "< $file")) {
        postHeading("`$file`\n$!");
        return;
    }

    while (<FIL>) {
        $text .= $_;
    }

    close(FIL);

    if (defined($text)) {
        chomp $text;
        $text = "```\n$text\n```\n";

        $json->{'type'} = "mrkdwn";
        $json->{'text'} = $text;

        postToSlack($json);
    }
}


#  Posts a (multi-line) string as a code block.
#  DO NOT pre-format the text as a code block.
#
sub postText ($$) {
    my $mesg = shift @_;
    my $text = shift @_;
    my $json = {};
    my $jsonformatter = JSON::PP->new();

    postHeading($mesg);

    if ($text ne "") {
        chomp $text;
        $text = "```\n$text\n```\n";

        $json->{'type'} = "mrkdwn";
        $json->{'text'} = $text;

        postToSlack($json);
    }
}



1;