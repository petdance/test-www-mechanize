#!perl -T

use strict;
use warnings;
use Test::More tests => 2;
use Test::Builder::Tester;

use Test::WWW::Mechanize ();

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok($mech,'Test::WWW::Mechanize');


UNDEF_URL: {
    test_out( 'not ok 1 - Passing undef for a URL' );
    test_fail( +2 );
    test_diag( 'URL cannot be undef.' );
    my $ok = $mech->post_ok( undef, 'Passing undef for a URL' );
    test_test( 'Undef URLs' );
}


done_testing();

exit 0;
