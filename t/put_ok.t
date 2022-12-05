#!perl -T

use strict;
use warnings;

use Test::More tests => 8;
use Test::Builder::Tester;

use Test::WWW::Mechanize ();

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

my $text = 'This is what we are putting';
GOOD_PUT: {
    local @ENV{qw( http_proxy HTTP_PROXY )};

    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok($mech,'Test::WWW::Mechanize');

    my $scratch = "$server_root/scratch.html";

    $mech->put_ok($scratch, {content => $text});
    ok($mech->success, 'sanity check: we can load scratch.html');

    test_out('ok 1 - Try to PUT scratch.html');
    my $ok = $mech->put_ok($scratch, 'Try to PUT scratch.html');
    test_test('PUTs existing URI and reports success');
    is( ref($ok), '', 'put_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # default desc
    test_out("ok 1 - PUT $scratch");
    $mech->put_ok($scratch);
    test_test('PUTs existing URI and reports success - default desc');
}


UNDEF_URL: {
    my $mech = Test::WWW::Mechanize->new();
    test_out( 'not ok 1 - Passing undef for a URL' );
    test_fail( +2 );
    test_diag( 'URL cannot be undef.' );
    my $ok = $mech->put_ok( undef, 'Passing undef for a URL' );
    test_test( 'Undef URLs' );
}


$server->stop;

done_testing();


exit 0;
