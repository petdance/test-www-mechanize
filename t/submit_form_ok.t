#!perl -T

use strict;
use warnings;
use Test::More tests => 5;
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
    $mech->submit_form_ok( {form_number =>1}, 'Submit First Form' );
}

SUBMIT_BAD_FORM: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get_ok( "$server_root/form.html" );

    test_out( 'not ok 2 - Submit 14th form' );
    test_fail( +2 );
    my $ok = $mech->submit_form_ok( {form_number => 14}, 'Submit 14th (and thus non-existent) form' );
    test_test( 'Get the correct line reference back' );
    is( !$ok, 'And the results should be false' );
}

$server->stop;

done_testing();
