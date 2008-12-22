#!perl

use strict;
use warnings;
use Test::More;
use Test::Builder::Tester;

use constant NONEXISTENT => 'http://blahblablah.xx-nonexistent.';
BEGIN {
    if ( gethostbyname( NONEXISTENT ) ) {
        plan skip_all => 'Found an A record for the non-existent domain';
    }
}

BEGIN {
    plan tests => 11;
    use_ok( 'Test::WWW::Mechanize' );
}


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
    my $badurl = 'http://wango.nonexistent.xx-only-testing/';
    $mech->head($badurl);
    ok(!$mech->success, q{sanity check: we can't load NONEXISTENT.html} );

    test_out( 'not ok 1 - Try to HEAD bad URL' );
    test_fail( +3 );
    test_diag( '500' );
    test_diag( q{Can't connect to wango.nonexistent.xx-only-testing:80 (Bad hostname 'wango.nonexistent.xx-only-testing')} );
    my $ok = $mech->head_ok( $badurl, 'Try to HEAD bad URL' );
    test_test( 'Fails to HEAD nonexistent URI and reports failure' );

    is( ref($ok), '', 'head_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}

$server->stop;
