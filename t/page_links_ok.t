#!perl -Tw

use strict;
use warnings;
use Test::More tests => 7;
use Test::Builder::Tester;
use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
$mech->get_ok( $uri );

# Good links.
test_out('ok 1 - Checking all page links successful');
$mech->page_links_ok('Checking all page links successful');
test_test('Handles All page links successful');

# Good links - default desc
test_out('ok 1 - All links ok');
$mech->page_links_ok();
test_test('Handles All page links successful - default desc');

# Bad links
$uri = URI::file->new_abs( 't/badlinks.html' )->as_string;
$mech->get_ok( $uri );

test_out('not ok 1 - Checking some page link failures');
test_fail(+4);
test_diag('bad1.html');
test_diag('bad2.html');
test_diag('bad3.html');
$mech->page_links_ok('Checking some page link failures');
test_test('Handles link not found');
