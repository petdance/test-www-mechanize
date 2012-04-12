#!perl -T

use strict;
use warnings;
use Test::More tests => 9;
use Test::Builder::Tester;
use URI::file;

use Test::WWW::Mechanize ();

use lib 't';

my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech,'Test::WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
$mech->get_ok( $uri );

# test regex
test_out('not ok 1 - page_links_content_like');
test_fail(+2);
test_diag(q{     "blah" doesn't look much like a regex to me.});
$mech->page_links_content_like('blah','Testing the regex');
test_test('Handles bad regexs');

# like
test_out('ok 1 - Checking all page links contain: Test');
$mech->page_links_content_like(qr/Test/,'Checking all page links contain: Test');
test_test('Handles All page links contents successful');

# like - default desc
my $re_string = ($] < 5.014) ? '(?-xism:Test)' : '(?^:Test)';
test_out(qq{ok 1 - All links are like "$re_string"});
$mech->page_links_content_like(qr/Test/);
test_test('Handles All page links contents successful');

test_out('not ok 1 - Checking all page link content failures');
test_fail(+4);
test_diag('goodlinks.html');
test_diag('badlinks.html');
test_diag('goodlinks.html');
$mech->page_links_content_like(qr/BadTest/,'Checking all page link content failures');
test_test('Handles link content not found');

# unlike
# test regex
test_out('not ok 1 - page_links_content_unlike');
test_fail(+2);
test_diag(q{     "blah" doesn't look much like a regex to me.});
$mech->page_links_content_unlike('blah','Testing the regex');
test_test('Handles bad regexs');

test_out('ok 1 - Checking all page links do not contain: BadTest');
$mech->page_links_content_unlike(qr/BadTest/,'Checking all page links do not contain: BadTest');
test_test('Handles All page links unlike contents successful');

test_out('not ok 1 - Checking all page link unlike content failures');
test_fail(+4);
test_diag('goodlinks.html');
test_diag('badlinks.html');
test_diag('goodlinks.html');
$mech->page_links_content_unlike(qr/Test/,'Checking all page link unlike content failures');
test_test('Handles link unlike content found');

done_testing();
