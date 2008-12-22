#!perl

use strict;
use warnings;
use Test::More tests => 5;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

FOLLOW_GOOD_LINK: {
    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get( "$server_root/goodlinks.html" );
    $mech->follow_link_ok( {n=>1}, 'Go after first link' );
}

FOLLOW_BAD_LINK: {
    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );
    local $TODO = q{I don't know how to get Test::Builder::Tester to handle regexes for the timestamp.};

    $mech->get( "$server_root/badlinks.html" );
    test_out('not ok 1 - Go after bad link');
    test_fail(+1);
    $mech->follow_link_ok( {n=>2}, 'Go after bad link' );
    test_diag('');
    test_test('Handles bad links');
}

$server->stop;
