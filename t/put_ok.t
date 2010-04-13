#!perl

use strict;
use warnings;
use Test::More;
use Test::Builder::Tester;

BEGIN {
    plan tests => 8;
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

my $text = 'This is what we are putting';
GOOD_PUT: {
    my $goodlinks = "$server_root/goodlinks.html";

    $mech->put_ok($goodlinks, {content => $text});
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

$server->stop;
