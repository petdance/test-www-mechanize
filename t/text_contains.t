#!perl -Tw

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
$mech->text_contains( 'Test Page', 'Does it say test page?' );
test_test( 'Finds the contains' );

# default desc
test_out( 'ok 1 - Text contains "Test Page"' );
$mech->text_contains( 'Test Page');
test_test( 'Finds the contains - default desc' );

# Handles not finding something. Also, what we are searching for IS
# found in content_contains() but NOT in text_contains().
test_out( 'not ok 1 - Trying to find goodlinks' );
test_fail(+5);
test_diag( q{    searched: "Test PageTest PageTest 1 Test 2 Test 3"} );
test_diag( q{  can't find: "goodlinks.html"} );
test_diag( q{        LCSS: "s"} );
test_diag( q{LCSS context: "Test PageTest PageTest 1 Test 2 Test 3"} );
$mech->text_contains( 'goodlinks.html', 'Trying to find goodlinks' );
test_test( 'Handles not finding it' );
