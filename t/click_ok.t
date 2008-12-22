#!perl -Tw

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Builder::Tester;

use lib 't';
use TestServer;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}


my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

sub cleanup { kill(9,$pid) if !$^S };
$SIG{__DIE__} = \&cleanup;


SUBMIT_GOOD_FORM: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get( "$server_root/form.html" );
    $mech->click_ok( 'big_button', 'Submit First Form' );
}

cleanup();
