#!perl

use strict;
use warnings;
use Test::More;
use Test::Builder::Tester;

use constant NONEXISTENT => 'http://blahblablah.xx-nonexistent.';
BEGIN {
    if ( gethostbyname( 'blahblahblah.xx-nonexistent.' ) ) {
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

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

GOOD_PUT: {
    my $goodlinks = "$server_root/goodlinks.html";

    $mech->put($goodlinks);
    ok($mech->success, 'sanity check: we can load goodlinks.html');

    test_out('ok 1 - Try to PUT goodlinks.html');
    my $ok = $mech->put_ok($goodlinks, 'Try to PUT goodlinks.html');
    test_test('PUTs existing URI and reports success');
    is( ref($ok), '', 'put_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # default desc
    test_out("ok 1 - PUT $goodlinks");
    $mech->put_ok($goodlinks);
    test_test('PUTs existing URI and reports success - default desc');
}

BAD_PUT: {
    my $badurl = 'http://wango.nonexistent.xx-only-testing/';
    $mech->put($badurl);
    ok(!$mech->success, q{sanity check: we can't load NONEXISTENT.html});

    test_out( 'not ok 1 - Try to PUT bad URL' );
    test_fail( +3 );
    test_diag( '500' );
    test_diag( q{Can't connect to wango.nonexistent.xx-only-testing:80 (Bad hostname 'wango.nonexistent.xx-only-testing')} );
    my $ok = $mech->put_ok( $badurl, 'Try to PUT bad URL' );
    test_test( 'Fails to PUT nonexistent URI and reports failure' );

    is( ref($ok), '', "put_ok() should only return a scalar" );
    ok( !$ok, 'And the result should be false' );
}

$server->stop;
