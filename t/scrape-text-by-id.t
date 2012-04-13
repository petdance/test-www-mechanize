#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 1;

use Test::Builder;

use URI::file ();

use Test::WWW::Mechanize ();

subtest scrape_text_by_id => sub {
    plan tests => 8;

    my $mech = Test::WWW::Mechanize->new( autolint => 0 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
    $mech->get_ok( $uri, 'Get a dummy page just to have one' );

    subtest 'nothing to find' => sub {
        plan tests => 2;
        $mech->update_html( '<html><head><title></title></head><body></body></html>' );

        is_deeply( [$mech->scrape_text_by_id( 'asdf' )], [], 'empty list returned in list context' );
        is( $mech->scrape_text_by_id( 'asdf' ), undef, 'undef returned in scalar context' );
    };

    subtest 'find one' => sub {
        plan tests => 2;
        $mech->update_html( '<html><head><title></title></head><body><p id="asdf">contents</p></body></html>' );
        is_deeply( [$mech->scrape_text_by_id( 'asdf' )], ['contents'], 'list context' );
        is( $mech->scrape_text_by_id( 'asdf' ), 'contents', 'scalar context' );
    };

    subtest 'find multiple' => sub {
        plan tests => 2;

        $mech->update_html( '<html><head><title></title></head><body><p id="asdf">contents</p><p id="asdf">further</p></body></html>' );
        is_deeply( [$mech->scrape_text_by_id( 'asdf' )], ['contents', 'further'], 'empty list returned in list context' );
        is( $mech->scrape_text_by_id( 'asdf' ), 'contents', 'first string returned in scalar context' );
    };

    subtest 'present but empty' => sub {
        plan tests => 2;

        $mech->update_html( '<html><head><title></title></head><body><p id="asdf"></p></body></html>' );
        is_deeply( [$mech->scrape_text_by_id( 'asdf' )], [''], 'list context' );
        is( $mech->scrape_text_by_id( 'asdf' ), '', 'scalar context' );
    };

    subtest 'present but emptier' => sub {
        plan tests => 2;

        $mech->update_html( '<html><head><title></title></head><body><p id="asdf" /></body></html>' );
        is_deeply( [$mech->scrape_text_by_id( 'asdf' )], [''], 'list context' );
        is( $mech->scrape_text_by_id( 'asdf' ), '', 'scalar context' );
    };

    subtest 'nested tag' => sub {
        plan tests => 2;

        $mech->update_html( '<html><head><title></title></head><body><p id="asdf">Bob and <b>Bongo!</b></p></body></html>' );
        is_deeply( [$mech->scrape_text_by_id( 'asdf' )], ['Bob and Bongo!'], 'list context' );
        is( $mech->scrape_text_by_id( 'asdf' ), 'Bob and Bongo!', 'scalar context' );
    };
};

done_testing();

exit 0;
