#!perl -Tw

use strict;
use warnings;
use Test::More tests => 15;
use Test::Builder::Tester;
use URI::file;

use Test::WWW::Mechanize ();

my $mech = Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
$mech->get_ok( $uri );

test_out( 'ok 1 - looking for "Test" link' );
$mech->has_tag( h1 => 'Test Page', 'looking for "Test" link' );
test_test( 'Handles finding tag by content' );

# default desc
test_out( 'ok 1 - Page has h1 tag with "Test Page"' );
$mech->has_tag( h1 => 'Test Page' );
test_test( 'Handles finding tag by content - default desc' );

test_out( 'not ok 1 - looking for "Quiz" link' );
test_fail( +1 );
$mech->has_tag( h1 => 'Quiz', 'looking for "Quiz" link' );
test_test( 'Handles unfindable tag by content' );

test_out( 'ok 1 - Should have qr/Test 3/i link' );
$mech->has_tag_like( a => qr/Test 3/, 'Should have qr/Test 3/i link' );
test_test( 'Handles finding tag by content regexp' );

test_out( 'not ok 1 - Should be missing qr/goof/i link' );
test_fail( +1 );
$mech->has_tag_like( a => qr/goof/i, 'Should be missing qr/goof/i link' );
test_test( 'Handles unfindable tag by content regexp' );

## nested table tag
my $table_uri = URI::file->new_abs( 't/table.html' )->as_string;
$mech->get_ok( $table_uri );

test_out( 'ok 1 - Page has td tag with "Foobar"' );
$mech->has_tag('td' =>  'Foobar' );
test_test( 'Handles finding text in table data tag' );

test_out( 'ok 1 - User company' );
$mech->has_tag('td', 'company', 'User company');
test_test( 'Handles finding text in nested table data tag' );

test_out( 'ok 1 - Page has td tag with "company,email,employee,website"' );
$mech->has_tag('td', 'company,email,employee,website');
test_test( 'Handles finding text in nested table data second tag' );

test_out( 'ok 1 - Page has th tag with "Groups"' );
$mech->has_tag('th', 'Groups');
test_test( "Handles finding text in nested table header" );

test_out( 'ok 1 - Page has h3 tag with "Show all users and groups"' );
$mech->has_tag('h3', 'Show all users and groups');
test_test( "Handles finding text in h3 in table" );

test_out( 'ok 1 - Page has p tag with "Its been said:"' );
$mech->has_tag('p', 'Its been said:');
test_test( "Checks finding text in sub inline element in p" );

test_out( 'ok 1 - Page has p tag with "Hi"');
$mech->has_tag( 'p', 'Hi' );
test_test( "Finding text in sub inline element in p" );

done_testing();
