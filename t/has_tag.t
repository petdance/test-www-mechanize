#!perl -w

use strict;
use warnings;
use Test::More tests => 7;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

my $mech = Test::WWW::Mechanize->new;
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get( "$server_root/goodlinks.html" );

test_out( 'ok 1 - looking for "Test" link' );
$mech->has_tag( h1 => 'Test Page', 'looking for "Test" link' );
test_test( 'Handles finding tag by content' );

# default desc
test_out( 'ok 1 - Page has h1 tag with "Test Page"' );
$mech->has_tag( h1 => 'Test Page' );
test_test( 'Handles finding tag by content - default desc' );

test_out( 'not ok 1 - looking for "Quiz" link' );
test_fail( +1 );
$mech->has_tag( h1 => 'Quiz', 'looking for "Quiz" link' );
test_test( 'Handles unfindable tag by content' );

test_out( 'ok 1 - Should have qr/Test 3/i link' );
$mech->has_tag_like( a => qr/Test 3/, 'Should have qr/Test 3/i link' );
test_test( 'Handles finding tag by content regexp' );

test_out( 'not ok 1 - Should be missing qr/goof/i link' );
test_fail( +1 );
$mech->has_tag_like( a => qr/goof/i, 'Should be missing qr/goof/i link' );
test_test( 'Handles unfindable tag by content regexp' );

$server->stop;
