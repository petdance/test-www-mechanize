#!perl -T

use warnings;
use strict;

use Test::More tests => 2;

use Test::WWW::Mechanize ();

subtest 'basic new' => sub {
    my $mech = Test::WWW::Mechanize->new;
    isa_ok( $mech, 'Test::WWW::Mechanize' );
};

# Stolen from WWW::Mechanize's t/new.t.
# If this works, then subclassing works OK.

subtest 'constructor parms' => sub {
    my $alias = 'Windows IE 6';
    my $mech  = Test::WWW::Mechanize->new( agent => $alias );

    isa_ok( $mech, 'Test::WWW::Mechanize' );
    can_ok( $mech, 'request' );
    is( $mech->agent, $alias, q{Aliases don't get translated in the constructor} );

    $mech->agent_alias( $alias );
    like( $mech->agent, qr/^Mozilla.+compatible.+Windows/, 'Alias sets the agent' );

    $mech->agent( 'ratso/bongo v.43' );
    is( $mech->agent, 'ratso/bongo v.43', 'Can still set the agent' );
};

done_testing();
