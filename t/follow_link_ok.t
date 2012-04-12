#!perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Test::Builder::Tester;
use URI::file;

use Test::WWW::Mechanize ();

FOLLOW_GOOD_LINK: {
    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok( $mech,'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
    $mech->get_ok( $uri );
    $mech->follow_link_ok( {n=>1}, 'Go after first link' );
}

FOLLOW_BAD_LINK: {
    local $TODO = q{I don't know how to get Test::Builder::Tester to handle regexes for the timestamp.};

    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/badlinks.html' )->as_string;
    $mech->get_ok( $uri );
    test_out('not ok 1 - Go after bad link');
    test_fail(+1);
    $mech->follow_link_ok( {n=>2}, 'Go after bad link' );
    test_diag('');
    test_test('Handles bad links');
}

done_testing();
