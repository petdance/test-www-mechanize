#!perl -T

use strict;
use warnings;

use Test::More tests => 43;
use URI::file;

use Test::WWW::Mechanize ();

MAIN: {
    my $mech = Test::WWW::Mechanize->new();
    my $uri = URI::file->new_abs( 't/stuff_inputs.html' )->as_string;

    EMPTY_FIELDS: {
        $mech->get_ok( $uri ) or die;

        add_test_fields( $mech );
        $mech->stuff_inputs();
        field_checks(
            $mech, {
                text0         => '',
                text1         => '@',
                text10        => '@' x 10,
                text70k       => '@' x 70_000,
                textunlimited => '@' x 66_000,
                textarea      => '@' x 66_000,
            },
            'filling empty fields'
        );
    }


    MULTICHAR_FILL: {
        $mech->get_ok( $uri ) or die;

        add_test_fields( $mech );
        $mech->stuff_inputs( { fill => '123' } );
        field_checks(
            $mech, {
                text0         => '',
                text1         => '1',
                text10        => '1231231231',
                text70k       => ('123' x 23_333) . '1',
                textunlimited => '123' x 22_000,
                textarea      => '123' x 22_000,
            },
            'multichar_fill'
        );
    }


    OVERWRITE: {
        $mech->get_ok( $uri ) or die;

        add_test_fields( $mech );
        $mech->stuff_inputs();
        is( $mech->value('text10'), '@' x 10, 'overwriting fields: initial fill as expected' );
        $mech->stuff_inputs( { fill => 'X' } );
        field_checks(
            $mech, {
                text0         => '',
                text1         => 'X',
                text10        => 'X' x 10,
                text70k       => 'X' x 70_000,
                textunlimited => 'X' x 66_000,
                textarea      => 'X' x 66_000,
            },
            'overwriting fields'
        );
    }


    CUSTOM_FILL: {
        $mech->get_ok( $uri ) or die;

        add_test_fields( $mech );
        $mech->stuff_inputs( {
                fill => 'z',
                specs => {
                    text10 => { fill=>'#' },
                    textarea => { fill=>'*' },
                }
            } );
        field_checks(
            $mech, {
                text0         => '',
                text1         => 'z',
                text10        => '#' x 10,
                text70k       => 'z' x 70_000,
                textunlimited => 'z' x 66_000,
                textarea      => '*' x 66_000,
            },
            'custom fill'
        );
    }


    MAXLENGTH: {
        $mech->get_ok( $uri ) or die;

        add_test_fields( $mech );
        $mech->stuff_inputs( {
                specs => {
                    text10 => { maxlength=>7 },
                    textarea => { fill=>'*', maxlength=>9 },
                }
            }
        );
        field_checks(
            $mech, {
                text0         => '',
                text1         => '@',
                text10        => '@' x 7,
                text70k       => '@' x 70_000,
                textunlimited => '@' x 66_000,
                textarea      => '*' x 9,
            },
            'maxlength'
        );
    }


    IGNORE: {
        $mech->get_ok( $uri ) or die;

        add_test_fields( $mech );
        $mech->stuff_inputs( { ignore => [ 'text10' ] } );
        field_checks(
            $mech, {
                text0         => '',
                text1         => '@',
                text10        => undef,
                text70k       => '@' x 70_000,
                textunlimited => '@' x 66_000,
                textarea      => '@' x 66_000,
            },
            'ignore'
        );
    }
}

done_testing();


sub add_test_fields {
    my $mech = shift;

    HTML::Form::Input->new( type=>'text', name=>'text0', maxlength=>0 )->add_to_form( $mech->current_form() );
    HTML::Form::Input->new( type=>'text', name=>'text1', maxlength=>1 )->add_to_form( $mech->current_form() );
    HTML::Form::Input->new( type=>'text', name=>'text10', maxlength=>10 )->add_to_form( $mech->current_form() );
    HTML::Form::Input->new( type=>'text', name=>'text70k', maxlength=>70_000 )->add_to_form( $mech->current_form() );
    HTML::Form::Input->new( type=>'text', name=>'textunlimited' )->add_to_form( $mech->current_form() );
    HTML::Form::Input->new( type=>'textarea', name=>'textarea' )->add_to_form( $mech->current_form() );

    return;
}


sub field_checks {
    my $mech = shift;
    my $expected = shift;
    my $desc = shift;

    foreach my $key ( qw( text0 text1 text10 text70k textunlimited textarea ) ) {
        is( $mech->value($key), $expected->{$key}, "$desc: field $key" );
    }

    return;
}
