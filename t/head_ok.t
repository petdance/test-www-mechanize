#!perl

use strict;
use warnings;
use Test::More;
use Test::Builder::Tester;

my $NONEXISTENT = 'blahblablah.xx-nonexistent.foo';

plan skip_all => "Found an A record for the non-existent domain $NONEXISTENT"
    if gethostbyname $NONEXISTENT;

plan tests => 11;
require_ok( 'Test::WWW::Mechanize' );

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

my $mech=Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

GOOD_HEAD: { # Stop giggling, you!
    my $goodlinks = "$server_root/goodlinks.html";

    $mech->head($goodlinks);
    ok($mech->success, 'sanity check: we can load goodlinks.html');

    test_out('ok 1 - Try to HEAD goodlinks.html');
    my $ok = $mech->head_ok($goodlinks, 'Try to HEAD goodlinks.html');
    test_test('HEAD existing URI and reports success');
    is( ref($ok), '', 'head_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # default desc
    test_out("ok 1 - HEAD $goodlinks");
    $mech->head_ok($goodlinks);
    test_test('HEAD existing URI and reports success - default desc');
}

BAD_HEAD: {
    my $badurl = 'http://$NONEXISTENT/';
    $mech->head($badurl);
    ok(!$mech->success, q{sanity check: we can't load $badurl} );

    test_out( 'not ok 1 - Try to HEAD bad URL' );
    test_fail( +3 );
    test_diag( '500' );
    test_diag( q{Can't connect to $NONEXISTENT:80 (Bad hostname '$NONEXISTENT')} );
    my $ok = $mech->head_ok( $badurl, 'Try to HEAD bad URL' );
    test_test( 'Fails to HEAD nonexistent URI and reports failure' );

    is( ref($ok), '', 'head_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}

$server->stop;
