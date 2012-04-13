#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Test::Builder;

use URI::file ();

use Test::WWW::Mechanize ();

subtest scrape_text_by_id => sub {
    plan tests => 12;

    my $mech = Test::WWW::Mechanize->new( autolint => 0 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
    $mech->get_ok( $uri, 'Get a dummy page just to have one' );

    # nothing to find
    $mech->update_html( '<html><head><title></title></head><body></body></html>' );
    is_deeply( [$mech->scrape_text_by_id('asdf')], [], 'not found: empty list returned in list context' );
    is( $mech->scrape_text_by_id('asdf'), undef, 'not found: undef returned in scalar context' );

    # find one
    $mech->update_html( '<html><head><title></title></head><body><p id="asdf">contents</p></body></html>' );
    is_deeply( [$mech->scrape_text_by_id('asdf')], ['contents'], 'find one: list context' );
    is( $mech->scrape_text_by_id('asdf'), 'contents', 'find one: scalar context' );

    # find multiple
    $mech->update_html( '<html><head><title></title></head><body><p id="asdf">contents</p><p id="asdf">further</p></body></html>' );
    is_deeply( [$mech->scrape_text_by_id('asdf')], ['contents', 'further'], 'find multiple: empty list returned in list context' );
    is( $mech->scrape_text_by_id('asdf'), 'contents', 'find multiple: first string returned in scalar context' );

    # present but empty
    $mech->update_html( '<html><head><title></title></head><body><p id="asdf"></p></body></html>' );
    is_deeply( [$mech->scrape_text_by_id('asdf')], [''], 'present but empty: list context' );
    is( $mech->scrape_text_by_id('asdf'), '', 'present but empty: scalar context' );

    # present but emptier
    $mech->update_html( '<html><head><title></title></head><body><p id="asdf" /></body></html>' );
    is_deeply( [$mech->scrape_text_by_id('asdf')], [''], 'present but emptier: list context' );
    is( $mech->scrape_text_by_id('asdf'), '', 'present but emptier: scalar context' );
};

done_testing();

exit 0;
