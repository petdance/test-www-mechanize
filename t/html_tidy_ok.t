#!perl -T

use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;

use Test::WWW::Mechanize;
use URI::file;

BEGIN {
    my $module = 'HTML::Tidy5 1.00';
    if ( not eval "use $module; 1;" ) {
        plan skip_all => "Optional $module is not installed, cannot test html_tidy_ok" if $@;
    }
    plan tests => 7;
}

GOOD_GET: {
    my $mech = Test::WWW::Mechanize->new;
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/bad.html' )->as_string;
    $mech->get_ok( $uri, 'Fetching the file from disk' );

    test_out( "not ok 1 - checking HTML ($uri)" );
    test_fail( +6 );
    test_err( "# HTML::Tidy5 messages for $uri" );
    test_err( '# (1:1) Warning: missing <!DOCTYPE> declaration' );
    test_err( '# (8:33) Warning: discarding unexpected </b>' );
    test_err( '# (8:9) Warning: missing </a>' );
    test_err( '# 3 messages on the page' );
    $mech->html_tidy_ok( 'checking HTML' );
    test_test( 'Proper html_tidy_ok results' );
}

CONTENT_FOR_VALIDATION: {
    my $mech = My::Subclass->new;
    isa_ok( $mech, 'My::Subclass' );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/bad.html' )->as_string;
    $mech->get_ok( $uri, 'Fetching the file from disk' );

    test_out( "not ok 1 - checking HTML ($uri)" );
    test_fail( +4 );
    test_err( "# HTML::Tidy5 messages for $uri" );
    test_err( '# (9:9) Warning: missing </a>' );
    test_err( '# 1 message on the page' );
    $mech->html_tidy_ok( 'checking HTML' );
    test_test( 'Proper html_tidy_ok results after modifying the contents before tidying' );
}

done_testing();
exit 0;

package My::Subclass;

use parent 'Test::WWW::Mechanize';

sub content_for_tidy {
    my $self = shift;

    my $content = $self->content;

    # Fix the missing DOCTYPE.
    $content = "<!DOCTYPE html>\n$content";

    # Change the </b> to something innocuous.
    $content =~ s{</b>}{<br/>};

    # We're still leaving the unclosed </a>.

    return $content;
}
