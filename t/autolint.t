#!/usr/bin/env perl -T

use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;
use URI::file;
use HTML::Lint;

BEGIN {
    eval 'use HTML::Lint';
    plan skip_all => 'HTML::Lint is not installed, cannot test autolint' if $@;
    plan tests => 8;
}

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

CUSTOM_LINTER: {
    my $lint = HTML::Lint->new( only_types => HTML::Lint::Error::STRUCTURE );

    my $mech = Test::WWW::Mechanize->new( autolint => $lint );
    isa_ok( $mech, 'Test::WWW::Mechanize' );
}

GOOD_GET_GOOD_HTML: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/good.html' )->as_string;
    $mech->get_ok( $uri );

    test_out( "ok 1 - GET $uri" );
    $mech->get_ok( $uri, "GET $uri" );
    test_test( 'Good GET, good HTML' );
}

GOOD_GET_BAD_HTML: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/bad.html' )->as_string;

    # Test via get_ok
    test_out( "not ok 1 - GET $uri" );
    test_fail( +6 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (7:9) Unknown attribute "hrex" for tag <a>' );
    test_err( '#  (8:33) </b> with no opening <b>' );
    test_err( '#  (9:5) <a> at (8:9) is never closed' );
    test_err( '# 3 errors on the page' );
    $mech->get_ok( $uri, "GET $uri" );
    test_test( 'get_ok complains about bad HTML' );

    # Test via follow_link_ok
    test_out( 'not ok 1 - Following link back to bad.html' );
    test_fail( +6 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (7:9) Unknown attribute "hrex" for tag <a>' );
    test_err( '#  (8:33) </b> with no opening <b>' );
    test_err( '#  (9:5) <a> at (8:9) is never closed' );
    test_err( '# 3 errors on the page' );
    $mech->follow_link_ok( { text => 'Back to bad' }, 'Following link back to bad.html' );
    test_test( 'follow_link_ok complains about bad HTML' );
}
