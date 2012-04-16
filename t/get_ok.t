#!perl -T

use strict;
use warnings;
use Test::More tests => 10;
use Test::Builder::Tester;
use URI::file ();

use Test::WWW::Mechanize ();

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

GOOD_GET: {
    my $goodlinks = URI::file->new_abs( 't/goodlinks.html' )->as_string;

    $mech->get_ok($goodlinks);

    test_out('ok 1 - Try to get goodlinks.html');
    my $ok = $mech->get_ok($goodlinks, 'Try to get goodlinks.html');
    test_test('Gets existing URI and reports success');
    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # default desc
    test_out("ok 1 - GET $goodlinks");
    $mech->get_ok($goodlinks);
    test_test('Gets existing URI and reports success - default desc');
}

BAD_GET: {
    my $badurl = URI::file->new_abs('t/no-such-file')->as_string;
    (my $abs_path = $badurl) =~ s{^file://}{};
    $mech->get($badurl);
    ok(!$mech->success, qq{sanity check: we can't load $badurl});

    test_out( 'not ok 1 - Try to get bad URL' );
    test_fail( +3 );
    test_diag( '404' );
    test_diag( qq{File `$abs_path' does not exist} );
    my $ok = $mech->get_ok( $badurl, 'Try to get bad URL' );
    test_test( 'Fails to get nonexistent URI and reports failure' );

    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}

done_testing();
