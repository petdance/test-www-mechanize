#!perl

use strict;
use warnings;
use Test::More tests => 11;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get( "$server_root/goodlinks.html" );
my @urls = $mech->links();
ok( scalar @urls, 'Got links from the HTTP server');

# test regex
test_out('not ok 1 - link_content_like');
test_fail(+2);
test_diag(q{     "blah" doesn't look much like a regex to me.});
$mech->link_content_like(\@urls,'blah','Testing the regex');
test_test('Handles bad regexs');

# like
test_out('ok 1 - Checking all page links contain: Test');
$mech->link_content_like(\@urls,qr/Test/,'Checking all page links contain: Test');
test_test('Handles All page links contents successful');

# like - default desc
my $re_string = ($] < 5.014) ? '(?-xism:Test)' : '(?^:Test)';
test_out('ok 1 - ' . scalar(@urls) . qq{ links are like "$re_string"} );
$mech->link_content_like(\@urls,qr/Test/);
test_test('Handles All page links contents successful - default desc');

test_out('not ok 1 - Checking all page link content failures');
test_fail(+4);
test_diag('goodlinks.html');
test_diag('badlinks.html');
test_diag('goodlinks.html');
$mech->link_content_like(\@urls,qr/BadTest/,'Checking all page link content failures');
test_test('Handles link content not found');

# unlike
# test regex
test_out('not ok 1 - link_content_unlike');
test_fail(+2);
test_diag(q{     "blah" doesn't look much like a regex to me.});
$mech->link_content_unlike(\@urls,'blah','Testing the regex');
test_test('Handles bad regexs');

test_out('ok 1 - Checking all page links do not contain: BadTest');
$mech->link_content_unlike(\@urls,qr/BadTest/,'Checking all page links do not contain: BadTest');
test_test('Handles All page links unlike contents successful');

# unlike - default desc
$re_string = ($] < 5.014) ? '(?-xism:BadTest)' : '(?^:BadTest)';
test_out('ok 1 - ' . scalar(@urls) . qq{ links are not like "$re_string"});
$mech->link_content_unlike(\@urls,qr/BadTest/);
test_test('Handles All page links unlike contents successful - default desc');

test_out('not ok 1 - Checking all page link unlike content failures');
test_fail(+4);
test_diag('goodlinks.html');
test_diag('badlinks.html');
test_diag('goodlinks.html');
$mech->link_content_unlike(\@urls,qr/Test/,'Checking all page link unlike content failures');
test_test('Handles link unlike content found');

$server->stop;
