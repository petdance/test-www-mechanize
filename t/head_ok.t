#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use Test::WWW::Mechanize;

use Test::Builder::Tester;
use URI::file;

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');

GOOD_HEAD: { # Stop giggling, you!
    my $goodlinks = URI::file->new_abs( 't/goodlinks.html' )->as_string;

    $mech->head($goodlinks);
    ok($mech->success, 'sanity check: we can load goodlinks.html');

    test_out('ok 1 - Try to HEAD goodlinks.html');
    my $ok = $mech->head_ok($goodlinks, 'Try to HEAD goodlinks.html');
    test_test('HEAD existing URI and reports success');
    is( ref($ok), '', 'head_ok() should only return a scalar' );
    ok( $ok, 'And the result should be true' );

    # default desc
    test_out("ok 1 - HEAD $goodlinks");
    $mech->head_ok($goodlinks);
    test_test('HEAD existing URI and reports success - default desc');
}

BAD_HEAD: {
    my $badurl = URI::file->new_abs('t/no-such-file');
    my $abs_path = $badurl->file;
    $mech->head( $badurl->as_string );
    ok(!$mech->success, qq{sanity check: we can't load $badurl} );

    test_out( 'not ok 1 - Try to HEAD bad URL' );
    test_fail( +3 );
    test_diag( '404' );
    test_diag( qq{File `$abs_path' does not exist} );
    my $ok = $mech->head_ok( $badurl->as_string, 'Try to HEAD bad URL' );
    test_test( 'Fails to HEAD nonexistent URI and reports failure' );

    is( ref($ok), '', 'head_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}

done_testing();
