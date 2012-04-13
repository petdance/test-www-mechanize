#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use Test::Builder::Tester;
use URI::file;

use Test::WWW::Mechanize ();

my $mech=Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

# Good links.
my $uri = URI::file->new_abs( 't/good.html' )->as_string;
$mech->get_ok( $uri );

test_out( 'ok 1 - Is this the test page?' );
test_out( 'ok 2 - Title is "Test Page"' );
$mech->title_is( 'Test Page', 'Is this the test page?' );
$mech->title_is( 'Test Page' );
test_test( 'Finds the title OK' );

test_out( 'ok 1 - Is this like the test page?' );
$mech->title_like( qr/[tf]est (p)age/i, 'Is this like the test page?' );
test_test( 'Finds the title OK' );

done_testing();
