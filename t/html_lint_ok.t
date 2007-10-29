#!perl

use strict;
use warnings;
use Test::Builder::Tester tests => 4;
use Test::More;

use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

GOOD_GET: {
    my $mech = Test::WWW::Mechanize->new;
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/html/bad.html' )->as_string;
    $mech->get_ok( $uri, 'Fetching the file from disk' );

    test_out( "not ok 1 - checking HTML ($uri)" );
    test_fail( +5 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (7:9) Unknown attribute "hrex" for tag <a>' );
    test_err( '#  (8:33) </b> with no opening <b>' );
    test_err( '#  (9:5) <a> at (8:9) is never closed' );
    $mech->html_lint_ok( 'checking HTML' );
    test_test( 'Proper html_lint_ok results' );
}
