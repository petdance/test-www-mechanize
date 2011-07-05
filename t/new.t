#!perl -Tw

use warnings;
use strict;
use Test::More tests => 7;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

NEW: {
    my $m = Test::WWW::Mechanize->new;
    isa_ok( $m, 'Test::WWW::Mechanize' );
}

# Stolen from WWW::Mechanize's t/new.t.
# If this works, then subclassing works OK.
CONSTRUCTOR_PARMS: {
    my $alias = 'Windows IE 6';
    my $m = Test::WWW::Mechanize->new( agent => $alias );
    isa_ok( $m, 'Test::WWW::Mechanize' );
    can_ok( $m, 'request' );
    is( $m->agent, $alias, q{Aliases don't get translated in the constructor} );

    $m->agent_alias( $alias );
    like( $m->agent, qr/^Mozilla.+compatible.+Windows/, 'Alias sets the agent' );

    $m->agent( 'ratso/bongo v.43' );
    is( $m->agent, 'ratso/bongo v.43', 'Can still set the agent' );
}
