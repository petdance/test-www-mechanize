#!perl

use strict;
use warnings;
use Test::More tests => 11;
use Test::Builder::Tester;
use URI::file;

my $NONEXISTENT = 'blahblablah.xx-nonexistent.foo';

require_ok( 'Test::WWW::Mechanize' );

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

# Bad HEAD test. Relies on getting an error finding a non-existent domain.
# Some ISPs "helpfully" provide resolution for non-existent domains,
# and thus this test fails by succeeding.  We check for this annoying
# behavior and skip this subtest if we get it.
SKIP: {
    skip "Found an A record for the non-existent domain $NONEXISTENT", 4
        if gethostbyname $NONEXISTENT;

    my $badurl = "http://$NONEXISTENT/";
    $mech->head($badurl);
    ok(!$mech->success, q{sanity check: we can't load $badurl} );

    test_out( 'not ok 1 - Try to HEAD bad URL' );
    test_fail( +3 );
    test_diag( '500' );
    test_diag( qq{Can't connect to $NONEXISTENT:80 (Bad hostname)} );
    my $ok = $mech->head_ok( $badurl, 'Try to HEAD bad URL' );
    test_test( 'Fails to HEAD nonexistent URI and reports failure' );

    is( ref($ok), '', 'head_ok() should only return a scalar' );
    ok( !$ok, 'And the result should be false' );
}
