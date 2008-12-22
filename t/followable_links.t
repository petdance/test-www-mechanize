#!perl

use strict;
use warnings;
use Test::More tests => 3;

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

my $mech = Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get("$server_root/manylinks.html");

# Good links.
my @links = $mech->followable_links();
@links = map { $_->url_abs } @links;
my @expected = (
    "$server_root/goodlinks.html",
    'http://bongo.com/wang.html',
    'https://secure.bongo.com/',
    "$server_root/badlinks.html",
    "$server_root/goodlinks.html",
);
is_deeply( \@links, \@expected, 'Got the right links' );

cleanup();
