#!perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

sub cleanup { kill(9,$pid) if !$^S };
$SIG{__DIE__}=\&cleanup;

SUBMIT_GOOD_FORM: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get( "$server_root/form.html" );
    $mech->submit_form_ok( {form_number =>1}, 'Submit First Form' );
}

cleanup();

