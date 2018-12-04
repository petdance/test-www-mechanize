#!perl -T

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More tests => 21;

use Test::WWW::Mechanize ();

use URI::file ();

my @valid_ids = ( 'user-block', 'name', 'address' );
my @invalid_ids = ( 'bingo', 'bongo' );

my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech,'Test::WWW::Mechanize' );

my $uri = URI::file->new_abs( 't/id_exists.html' )->as_string;
$mech->get_ok( $uri );

for my $id ( @valid_ids ) {
    ok( $mech->id_exists( $id ), "$id found" );
    $mech->id_exists_ok( $id );
    $mech->ids_exist_ok( [$id] );
}
for my $id ( @invalid_ids ) {
    ok( !$mech->id_exists( $id ), "$id not found" );
    $mech->lacks_id_ok( $id );
    $mech->lacks_ids_ok( [$id] );
}

$mech->ids_exist_ok( [@valid_ids], 'Valid IDs found' );
$mech->lacks_ids_ok( [@invalid_ids], 'Valid IDs found' );


# Now test output specifics.
# id_exists_ok
test_out( 'not ok 1 - ID "bongo" should exist' );
test_fail( +1 );
$mech->id_exists_ok( 'bongo' );
test_test( 'Proper id_exists_ok results for nonexistent ID' );

# lacks_id_ok
test_out( 'not ok 1 - ID "name" should not exist' );
test_fail( +1 );
$mech->lacks_id_ok( 'name' );
test_test( 'Proper lacks_id_ok results for ID that is there' );

# XXX We shoudl test ids_exist_ok and lacks_ids_ok, too.

exit 0
