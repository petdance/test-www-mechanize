#!perl

use warnings;
use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use WWW::Mechanize;
use LWP;

diag( "Testing Test::WWW::Mechanize $Test::WWW::Mechanize::VERSION, with WWW::Mechanize $WWW::Mechanize::VERSION, LWP $LWP::VERSION, Perl $], $^X" );
