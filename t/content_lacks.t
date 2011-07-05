#!perl -Tw

use strict;
use warnings;
use Test::More tests => 6;
use Test::Builder::Tester;
use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
$mech->get_ok( $uri );

# test regex
test_out( 'ok 1 - Does it say Mungo eats cheese?' );
$mech->content_lacks( 'Mungo eats cheese', 'Does it say Mungo eats cheese?' );
test_test( 'Finds the lacks' );

# default desc
test_out( 'ok 1 - Content lacks "Mungo eats cheese"' );
$mech->content_lacks( 'Mungo eats cheese');
test_test( 'Finds the lacks - default desc' );

test_out( q{not ok 1 - Shouldn't say it's a test page} );
test_fail(+4);
test_diag(q(    searched: "<html>\x{0a}    <head>\x{0a}        <title>Test Page</title>"...) );
test_diag(q(   and found: "Test Page") );
test_diag(q( at position: 33 (line 3 column 16)) );
$mech->content_lacks( 'Test Page', q{Shouldn't say it's a test page} );
test_test( 'Handles not finding it' );
