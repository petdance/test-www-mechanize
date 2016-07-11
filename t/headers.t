#!perl -T

use strict;
use warnings;
use Test::More tests => 26;
use Test::Builder::Tester;

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

use Test::WWW::Mechanize ();

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');
$mech->get_ok( "$server_root/form.html" );

GOOD_EXISTS: {
    test_out( 'ok 1 - Has Content-Type' );
    my $ok = $mech->header_exists('Content-Type', 'Has Content-Type');
    test_test( 'Gets existing header and reports success' );
    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # default desc
    test_out( 'ok 1 - Response has Content-Type header' );
    $mech->header_exists('Content-Type');
    test_test( 'Gets existing header and reports success - default desc' );
}

BAD_EXISTS: {
    test_out( 'not ok 1 - Try to get a bad header' );
    test_fail( +1 );
    my $ok = $mech->header_exists('Server', 'Try to get a bad header');
    test_diag( 'Content-Length: ' );
    test_diag( 'Content-Type: ' );
    test_diag( 'client-date: ' );
    test_diag( 'client-peer: ' );
    test_diag( 'client-response-num: ' );
    test_diag( 'title: ' );
    test_test( 'Fails to get nonexistent header and reports failure' );

    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}

GOOD_LACKS: {
    test_out( 'ok 1 - Lacks Bongotronic-X' );
    my $ok = $mech->lacks_header( 'Bongotronic-X', 'Lacks Bongotronic-X' );
    test_test( 'Gets existing header and reports success' );
    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    test_out( 'ok 1 - Response lacks Bongotronic-X header' );
    $mech->lacks_header( 'Bongotronic-X' );
    test_test( 'Gives reasonable default to lacks_header' );
}

BAD_LACKS: {
    test_out( 'not ok 1 - Hoping Content-Type is missing' );
    test_fail( +1 );
    my $ok = $mech->lacks_header( 'Content-Type', 'Hoping Content-Type is missing' );
    test_test( 'The header we expected to lack is indeed there.' );

    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}

GOOD_MATCHES: {
    test_out( 'ok 1 - Content-Type is "text/html"' );
    my $ok = $mech->header_matches('Content-Type', 'text/html', 'Content-Type is "text/html"');
    test_test( 'Matches existing header and reports success' );
    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # regex
    test_out( 'ok 1 - Content-Type matches /^text\\/html$/' );
    $mech->header_matches('Content-Type', qr/^text\/html$/, 'Content-Type matches /^text\\/html$/');
    test_test( 'Matches existing header and reports success - regex' );

    # default desc
    test_out( 'ok 1 - Response has Content-Type header with value \'text/html\'' );
    $mech->header_matches('Content-Type', 'text/html');
    test_test( 'Matches existing header and reports success - default desc' );
}

BAD_MATCHES: {
    test_out( 'not ok 1 - Try to match a bad header' );
    test_fail( +1 );
    my $ok = $mech->header_matches('Server', 'GitHub.com', 'Try to match a bad header');
    test_test( 'Fails to match nonexistent header and reports failure' );

    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );

    test_out( 'not ok 1 - Content-Type is "text/plain"' );
    test_fail( +1 );
    $mech->header_matches('Content-Type', 'text/plain', 'Content-Type is "text/plain"');
    test_diag( 'text/html' );
    test_test( 'Fails to match header and reports failure' );

    test_out( 'not ok 1 - Content-Type matches /^text\\/plain$/' );
    test_fail( +1 );
    $mech->header_matches('Content-Type', qr/^text\/plain$/, 'Content-Type matches /^text\\/plain$/');
    test_diag( 'text/html' );
    test_test( 'Fails to match header and reports failure - regex' );
}

$server->stop;

done_testing();
