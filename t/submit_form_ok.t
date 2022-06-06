#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
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
    $mech->submit_form_ok( {form_number =>1}, 'Submit First Form' );
}

$server->stop;

done_testing();
