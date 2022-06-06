#!perl -T

use strict;
use warnings;
use Test::More tests => 6;
use Test::Builder::Tester;

use Test::WWW::Mechanize ();

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

SUBMIT_GOOD_FORM: {
    local @ENV{qw( http_proxy HTTP_PROXY )};

    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get_ok( "$server_root/form.html" );
    $mech->click_ok( 'big_button', 'Submit First Form' );
    # XXX We need to check that the request is correct.
}


SUBMIT_GOOD_FORM_WITH_COORDINATES: {
    local @ENV{qw( http_proxy HTTP_PROXY )};

    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get_ok( "$server_root/form.html" );
    $mech->click_ok( ['big_button',360,80], 'Submit First Form with coordinates' );
    # XXX We need to check that the request is correct.
}

$server->stop;

done_testing();

exit 0;
