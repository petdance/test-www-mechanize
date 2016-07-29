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
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get_ok( "$server_root/form.html" );
    $mech->click_ok( 'big_button', 'Submit First Form' );
}

SUBMIT_GOOD_FORM_WITH_COORDINATES: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get_ok( "$server_root/form.html" );
    $mech->click_ok( ['big_button',360,80], 'Submit First Form with coordinates' );
}

$server->stop;

done_testing();
