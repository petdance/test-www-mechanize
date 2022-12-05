#!perl -T

use strict;
use warnings;
use Test::More tests => 11;
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
    my $badurl = URI::file->new_abs('t/no-such-file');
    my $abs_path = $badurl->file;
    $mech->get( $badurl->as_string );
    ok(!$mech->success, qq{sanity check: we can't load $badurl});

    test_out( 'not ok 1 - Try to get bad URL' );
    test_fail( +4 );
    test_diag( $badurl );
    test_diag( '404' );
    test_diag( qq{File `$abs_path' does not exist} );
    my $ok = $mech->get_ok( $badurl->as_string, 'Try to get bad URL' );
    test_test( 'Fails to get nonexistent URI and reports failure' );

    is( ref($ok), '', 'get_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}


UNDEF_URL: {
    test_out( 'not ok 1 - Passing undef for a URL' );
    test_fail( +2 );
    test_diag( 'URL cannot be undef.' );
    my $ok = $mech->get_ok( undef, 'Passing undef for a URL' );
    test_test( 'Undef URLs' );
}


done_testing();

exit 0;
