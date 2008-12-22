#!perl

use strict;
use warnings;
use Test::More tests => 8;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}


use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get( "$server_root/goodlinks.html" );

# Good links.
my $links=$mech->links();
test_out('ok 1 - Checking all links status are 200');
$mech->link_status_is($links,200,'Checking all links status are 200');
test_test('Handles All Links successful');

# Good links - Default desc
test_out('ok 1 - ' . scalar(@{$links}) . ' links have status 200');
$mech->link_status_is($links,200);
test_test('Handles All Links successful - default desc');

$mech->link_status_isnt($links,404,'Checking all links isnt');

# Bad links
$mech->get( "$server_root/badlinks.html" );

$links=$mech->links();
test_out('not ok 1 - Checking all links some bad');
test_fail(+2);
test_diag('goodlinks.html');
$mech->link_status_is($links,404,'Checking all links some bad');
test_test('Handles bad links');


test_out('not ok 1 - Checking specified link not found');
test_fail(+2);
test_diag('test2.html');
$mech->links_ok('test2.html','Checking specified link not found');
test_test('Handles link not found');

test_out('not ok 1 - Checking all links not 200');
test_fail(+2);
test_diag('goodlinks.html');
$mech->link_status_isnt($links,200,'Checking all links not 200');
test_test('Handles all links mismatch');
