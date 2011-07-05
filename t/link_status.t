#!perl -Tw

use strict;
use warnings;
use Test::More tests => 10;
use Test::Builder::Tester;
use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech,'Test::WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
$mech->get_ok( $uri );

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
$uri = URI::file->new_abs( 't/badlinks.html' )->as_string;
$mech->get_ok( $uri );

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
