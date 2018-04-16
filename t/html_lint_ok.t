#!perl -T

use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;

use Test::WWW::Mechanize;
use URI::file;

BEGIN {
    # Load HTML::Lint here for the imports
    my $module = 'HTML::Lint 2.20';
    if ( not eval "use $module; 1;" ) {
        plan skip_all => "$module is not installed, cannot test html_lint_ok" if $@;
    }
    plan tests => 3;
}

GOOD_GET: {
    my $mech = Test::WWW::Mechanize->new;
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/bad.html' )->as_string;
    $mech->get_ok( $uri, 'Fetching the file from disk' );

    test_out( "not ok 1 - checking HTML ($uri)" );
    test_fail( +6 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (7:9) Unknown attribute "hrex" for tag <a>' );
    test_err( '#  (8:33) </b> with no opening <b>' );
    test_err( '#  (9:5) <a> at (8:9) is never closed' );
    test_err( '# 3 errors on the page' );
    $mech->html_lint_ok( 'checking HTML' );
    test_test( 'Proper html_lint_ok results' );
}

done_testing();
exit 0;
