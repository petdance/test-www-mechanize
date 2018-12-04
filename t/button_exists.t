#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Test::WWW::Mechanize ();
use URI::file ();

my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech,'Test::WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/html/form.html' )->as_string;
$mech->get_ok( $uri );

ok( $mech->button_exists( 'big_button' ), 'Found a button that is there' );
ok( !$mech->button_exists( 'little_button' ), 'Not found button that is not there' );

$mech->button_exists_ok( 'big_button', 'Found a button that is there' );
$mech->lacks_button_ok( 'little_button', 'Not found button that is not there' );

done_testing();

exit 0
