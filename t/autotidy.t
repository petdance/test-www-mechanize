#!/usr/bin/env perl -T

use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;
use URI::file;

use Test::WWW::Mechanize;

BEGIN {
    my $module = 'HTML::Tidy5 1.00';

    # Load HTML::Lint here for the imports
    if ( not eval "use $module; 1;" ) {
        plan skip_all => "$module is not installed, cannot test autotidy.";
    }
    plan tests => 5;
}


subtest 'Accessor and mutator' => sub {
    plan tests => 17;

    my $tidy = HTML::Tidy5->new;
    isa_ok( $tidy, 'HTML::Tidy5' );

    ACCESSOR: {
        my $mech = Test::WWW::Mechanize->new();
        ok( !$mech->autotidy(), 'no autotidy to new yields autotidy off' );

        $mech = Test::WWW::Mechanize->new( autotidy => undef );
        ok( !$mech->autotidy(), 'undef to new yields autotidy off' );

        $mech = Test::WWW::Mechanize->new( autotidy => 0 );
        ok( !$mech->autotidy(), '0 to new yields autotidy off' );

        $mech = Test::WWW::Mechanize->new( autotidy => 1 );
        ok( $mech->autotidy(), '1 to new yields autotidy on' );

        $mech = Test::WWW::Mechanize->new( autotidy => [] );
        ok( $mech->autotidy(), 'non-false, non-object to new yields autotidy on' );

        $mech = Test::WWW::Mechanize->new( autotidy => $tidy );
        ok( $mech->autotidy(), 'HTML::Tidy5 object to new yields autotidy on' );
    }

    MUTATOR: {
        my $mech = Test::WWW::Mechanize->new();

        ok( !$mech->autotidy(0), '0 returns autotidy off' );
        ok( !$mech->autotidy(), '0 autotidy really off' );

        ok( !$mech->autotidy(''), '"" returns autotidy off' );
        ok( !$mech->autotidy(), '"" autotidy really off' );

        ok( !$mech->autotidy(1), '1 returns autotidy off (prior state)' );
        ok( $mech->autotidy(), '1 autotidy really on' );

        ok( $mech->autotidy($tidy), 'HTML::Tidy5 object returns autotidy on (prior state)' );
        ok( $mech->autotidy(), 'HTML::Tidy5 object autotidy really on' );
        my $ret = $mech->autotidy( 0 );
        isa_ok( $ret, 'HTML::Tidy5' );
        ok( !$mech->autotidy(), 'autotidy off after nuking HTML::Tidy5 object' );
    }
};


subtest 'Fluffy page has errors' => sub {
    plan tests => 2;

    my $mech = Test::WWW::Mechanize->new( autotidy => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/fluffy.html' )->as_string;

    test_out( "not ok 1 - GET $uri" );
    test_fail( +5 );
    test_err( "# HTML::Tidy5 messages for $uri" );
    test_err( '# (1:1) Warning: missing <!DOCTYPE> declaration' );
    test_err( '# (10:9) Warning: <img> lacks "alt" attribute' );
    test_err( '# 2 messages on the page' );
    $mech->get_ok( $uri );
    test_test( 'Fluffy page should have fluffy errors' );
};


subtest 'Custom tidy ignores fluffy errors' => sub {
    plan tests => 4;

    my $tidy = HTML::Tidy5->new( { show_warnings => 0 } );
    isa_ok( $tidy, 'HTML::Tidy5' );

    my $mech = Test::WWW::Mechanize->new( autotidy => $tidy );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/fluffy.html' )->as_string;
    $mech->get_ok( $uri, 'Fluffy page should not have errors' );

    # And if we go to another page, the autolint object has been reset.
    $mech->get_ok( $uri, 'Second pass at the fluffy page should not have errors, either' );
};


subtest 'Get good HTML' => sub {
    plan tests => 3;

    my $mech = Test::WWW::Mechanize->new( autotidy => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/good.html' )->as_string;
    $mech->get_ok( $uri );

    test_out( "ok 1 - GET $uri" );
    $mech->get_ok( $uri, "GET $uri" );
    test_test( 'Good GET, good HTML' );
};


subtest 'Get bad HTML' => sub {
    plan tests => 3;

    my $mech = Test::WWW::Mechanize->new( autotidy => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/bad.html' )->as_string;

    # Test via get_ok
    test_out( "not ok 1 - GET $uri" );
    test_fail( +7 );
    test_err( "# HTML::Tidy5 messages for $uri" );
    test_err( '# (1:1) Warning: missing <!DOCTYPE> declaration' );
    test_err( '# (8:33) Warning: discarding unexpected </b>' );
    test_err( '# (8:9) Warning: missing </a>' );
    #test_err( '# (7:9) Warning: <a> proprietary attribute "hrex"' );
    test_err( '# 3 messages on the page' );
    $mech->get_ok( $uri, "GET $uri" );
    test_test( 'get_ok complains about bad HTML' );

    # Test via follow_link_ok
    test_out( 'not ok 1 - Following link back to bad.html' );
    test_fail( +7 );
    test_err( "# HTML::Tidy5 messages for $uri" );
    test_err( '# (1:1) Warning: missing <!DOCTYPE> declaration' );
    test_err( '# (8:33) Warning: discarding unexpected </b>' );
    test_err( '# (8:9) Warning: missing </a>' );
    #test_err( '# (7:9) Warning: <a> proprietary attribute "hrex"' );
    test_err( '# 3 messages on the page' );
    $mech->follow_link_ok( { text => 'Back to bad' }, 'Following link back to bad.html' );
    test_test( 'follow_link_ok complains about bad HTML' );
};

done_testing();
exit 0;
