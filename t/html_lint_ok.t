#!perl

use strict;
use warnings;
use Test::More tests => 3;

use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

GOOD_GET: {
    my $mech = Test::WWW::Mechanize->new;
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/html_ok.t' );
    $mech->get_ok( $url );
}
