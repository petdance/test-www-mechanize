#!perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Test::Builder::Tester;
use URI::file ();

use Test::WWW::Mechanize ();

FOLLOW_GOOD_LINK: {
    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok( $mech,'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/goodlinks.html' )->as_string;
    $mech->get_ok( $uri );
    test_out( 'ok 1 - Go after first link' );
    $mech->follow_link_ok( {n=>1}, 'Go after first link' );
    test_test( 'Handles good links' );
}

FOLLOW_BAD_LINK: {
    my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/badlinks.html' )->as_string;

    my $path = $uri;
    $path =~ s{file://}{};
    $path =~ s{\Qbadlinks.html}{bad1.html};

    $mech->get_ok( $uri );
    test_out('not ok 1 - Go after bad link');
    test_fail(+3);
    test_diag( 404 ); # XXX Who is printing this 404, and should it be?
    test_diag( qq{File `$path' does not exist} );
    $mech->follow_link_ok( {n=>2}, 'Go after bad link' );
    test_test('Handles bad links');
}

done_testing();
