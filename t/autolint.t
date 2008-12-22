#!perl

use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;

BEGIN {
    eval 'use HTML::Lint';
    plan skip_all => 'HTML::Lint is not installed, cannot test autolint' if $@;
    plan tests => 4;
}

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

GOOD_GET_GOOD_HTML: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = "$server_root/good.html";

    test_out( 'ok 1 - GET good.html' );
    $mech->get_ok( $uri, 'GET good.html' );
    test_test( 'Good GET, good HTML' );
}

GOOD_GET_BAD_HTML: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = "$server_root/bad.html";

    test_out( 'not ok 1 - GET bad.html' );
    test_fail( +5 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (7:9) Unknown attribute "hrex" for tag <a>' );
    test_err( '#  (8:33) </b> with no opening <b>' );
    test_err( '#  (9:5) <a> at (8:9) is never closed' );
    test_err( '# 3 errors on the page' );
    $mech->get_ok( $uri, 'GET bad.html' );
    test_test( 'Good GET, bad HTML' );
}

BAD_GET: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = "$server_root/nonexistent.html";

    test_out( 'not ok 1 - GET nonexistent.html' );
    test_fail( +3 );
    test_diag( '404' );
    test_diag( qq{File `$uri' does not exist} );
    $mech->get_ok( $uri, 'GET nonexistent.html' );
    test_test( 'Bad GET' );
}

$server->stop;
