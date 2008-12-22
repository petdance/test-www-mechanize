#!perl -w

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

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get( "$server_root/goodlinks.html" );

# test regex
test_out( 'ok 1 - Does it say test page?' );
$mech->content_contains( 'Test Page', "Does it say test page?" );
test_test( "Finds the contains" );

# default desc
test_out( 'ok 1 - Content contains "Test Page"' );
$mech->content_contains( 'Test Page');
test_test( "Finds the contains - default desc" );

test_out( 'not ok 1 - Where is Mungo?' );
test_fail(+3);
test_diag(q(    searched: "<html>\x{0a}  <head>\x{0a}    <title>Test Page</title>\x{0a}  </h"...) );
test_diag(q(  can't find: "Mungo") );
$mech->content_contains( 'Mungo', "Where is Mungo?" );
test_test( "Handles not finding it" );
