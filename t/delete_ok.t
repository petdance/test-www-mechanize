#!perl -T

use strict;
use warnings;

use Test::More tests => 9;
use Test::Builder::Tester;

use Test::WWW::Mechanize ();

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

GOOD_DELETE: {
    local @ENV{qw( http_proxy HTTP_PROXY )};

    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok($mech,'Test::WWW::Mechanize');

    my $scratch = "$server_root/scratch.html";

    $mech->delete_ok($scratch);
    ok($mech->success, 'sanity check: we can load scratch.html');

    test_out('ok 1 - Try to DELETE scratch.html');
    my $ok = $mech->delete_ok($scratch, 'Try to DELETE scratch.html');
    test_test('DELETEs existing URI and reports success');
    is( ref($ok), '', 'delete_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # default desc
    test_out("ok 1 - DELETE $scratch");
    $mech->delete_ok($scratch);
    test_test('DELETEs existing URI and reports success - default desc');

    # For old LWP::UA
    undef *Test::WWW::Mechanize::can;
    *Test::WWW::Mechanize::can = sub {
        return undef;
    };
    $mech->delete_ok($scratch);
    ok($mech->success, 'sanity check: we can load scratch.html by old LWP::UA');
    undef *Test::WWW::Mechanize::can;
    *Test::WWW::Mechanize::can = *UNIVERSAL::can{CODE};
}

$server->stop;

done_testing();
