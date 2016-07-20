#!/usr/bin/perl -T

use strict;
use warnings;

use Test::Builder::Tester;

use Test::More tests => 3;

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


subtest 'scraped_id_is and scraped_id_like' => sub {
    plan tests => 5;

    my $mech = Test::WWW::Mechanize->new( autolint => 0 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
    $mech->get_ok( $uri, 'Get a dummy page just to have one' );

    subtest 'find one' => sub {
        plan tests => 2;
        $mech->update_html( '<html><head><title></title></head><body><p id="asdf">contents</p></body></html>' );
        $mech->scraped_id_is( 'asdf', 'contents', 'Works in scalar context' );
        $mech->scraped_id_like( 'asdf', qr/con.+s/, 'Works on regexes' );
    };

    subtest 'nested tag' => sub {
        plan tests => 2;

        $mech->update_html( '<html><head><title></title></head><body><p id="asdf">Bob and <b>Bongo!</b></p></body></html>' );
        $mech->scraped_id_is( 'asdf', 'Bob and Bongo!' );
        $mech->scraped_id_like( 'asdf', qr/Bob.+Bongo/ );
    };

    subtest 'failures' => sub {
        plan tests => 6;

        $mech->update_html( '<html><head><title></title></head><body><p id="asdf">Bob and <b>Bongo!</b></p><p id="empty"></p></body></html>' );

        # Test standard successes.
        $mech->scraped_id_is( 'asdf', 'Bob and Bongo!' );
        $mech->scraped_id_like( 'asdf', qr/Bob.+Bongo/ );

        # Test failures.
        test_out( 'not ok 1 - Trying to match nonexistent ID to a string' );
        test_fail( +2 );
        test_diag( q{Can't find ID "nonexistent" to compare to "foo"} );
        $mech->scraped_id_is( 'nonexistent', 'foo', 'Trying to match nonexistent ID to a string' );
        test_test( 'Fails when trying to find nonexistent ID' );

        my $regex = qr/Dave/ism;
        test_out( 'not ok 1 - Trying to match nonexistent ID to a regex' );
        test_fail( +2 );
        test_diag( qq{Can't find ID "nonexistent" to match against $regex} );
        $mech->scraped_id_like( 'nonexistent', $regex, 'Trying to match nonexistent ID to a regex' );
        test_test( 'Fails when mismatched against existing ID' );

        # Make sure that empty tags don't get seen as non-existent.
        $mech->scraped_id_is( 'empty', '' );
        $mech->scraped_id_like( 'empty', qr/^$/ );

    };
};


# Previous versions would miss a search for id="foo" if it was not
# exactly id="foo".  Here we test for variants.
subtest 'scrape_text_by_id optimization' => sub {
    plan tests => 6;

    _find_the_chips( <<'HTML', 'Double-quoted ID' );
        <html>
            <head><title>Bongo</title></head>
            <body>not chips<p id="fish">chips</p>also not chips</body></html>
HTML

    _find_the_chips( <<'HTML', 'Single-quoted ID' );
        <html>
            <head><title>Bongo</title></head>
            <body>not chips<p id='fish'>chips</p>also not chips</body></html>
HTML

    _find_the_chips( <<'HTML', 'Unquoted ID' );
        <html>
            <head><title>Bongo</title></head>
            <body>not chips<p id=fish>chips</p>also not chips</body></html>
HTML

    _find_the_chips( <<'HTML', 'Abnormal spacing' );
        <html>
            <head><title>Bongo</title></head>
            <body>not chips<p id = fish >chips</p>also not chips</body></html>
HTML

    _find_the_chips( <<'HTML', 'Unquoted broken across lines' );
        <html>
            <head><title>Bongo</title></head>
            <body>not chips<p id
            =
            fish >chips</p>also not chips</body></html>
HTML

    _find_the_chips( <<'HTML', 'Quoted broken across lines' );
        <html>
            <head><title>Bongo</title></head>
            <body>not chips<p
            id
            =
            "fish"
            >
            chips
            </p>
            also not chips</body></html>
HTML
};

sub _find_the_chips {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $html = shift;
    my $msg  = shift or die;

    return subtest "_find_the_chips( $msg )" => sub {
        plan tests => 2;

        my $mech = Test::WWW::Mechanize->new( autolint => 0 );
        isa_ok( $mech, 'Test::WWW::Mechanize' );
        $mech->update_html( $html );
        $mech->scraped_id_is( 'fish', 'chips' );
    };
}


done_testing();

exit 0;
