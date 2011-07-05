#!perl -w

use strict;
use warnings;
use Test::More tests => 6;
use Test::Builder::Tester;
use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech,'Test::WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
$mech->get_ok( $uri );

# test regex
test_out( 'ok 1 - Does it say test page?' );
$mech->content_contains( 'Test Page', 'Does it say test page?' );
test_test( 'Finds the contains' );

# default desc
test_out( 'ok 1 - Content contains "Test Page"' );
$mech->content_contains( 'Test Page');
test_test( 'Finds the contains - default desc' );

test_out( 'not ok 1 - Where is Mungo?' );
test_fail(+5);
test_diag(q(    searched: "<html>\x{0a}    <head>\x{0a}        <title>Test Page</title>"...) );
test_diag(q(  can't find: "Mungo") );
test_diag(q(        LCSS: "go"));
test_diag(q(LCSS context: "dy>\x{0a}        <h1>Test Page</h1>\x{0a}        <a href="go"));
$mech->content_contains( 'Mungo', 'Where is Mungo?' );
test_test( 'Handles not finding it' );
