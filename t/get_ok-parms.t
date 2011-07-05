#!perl -Tw

use strict;
use warnings;
use Test::More tests => 16;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $ua_args;

sub Test::WWW::Mechanize::success { return 1; }
sub Test::WWW::Mechanize::get {
    my $self = shift;
    my $url = shift;
    $ua_args = {@_};
    return 1;
}

my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech, 'Test::WWW::Mechanize' );

my $url = 'dummy://url';
$mech->get_ok( $url );
ok( eq_hash( {}, $ua_args ), 'passing URL only' );

$mech->get_ok( $url, 'Description' );
ok( eq_hash( {}, $ua_args ), 'Passing description' );

$mech->get_ok( $url, undef, 'Description' );
ok( eq_hash( {}, $ua_args ), 'Passing undef for hash' );

my $wanted = { foo=>1, bar=>2, baz=>3 };

$mech->get_ok( $url, [ %{$wanted} ] );
ok( eq_hash( $wanted, $ua_args ), 'Passing anonymous list for hash' );

$mech->get_ok( $url, [ %{$wanted} ], 'Description' );
ok( eq_hash( $wanted, $ua_args ), 'Passing anonymous list for hash' );

$mech->get_ok( $url, { %{$wanted} } );
ok( eq_hash( $wanted, $ua_args ), 'Passing anonymous array for hash' );

$mech->get_ok( $url, { %{$wanted} }, 'Description' );
ok( eq_hash( $wanted, $ua_args ), 'Passing anonymous array for hash' );
