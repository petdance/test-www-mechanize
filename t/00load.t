#!perl

use warnings;
use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

diag( "Testing Test::WWW::Mechanize $Test::WWW::Mechanize::VERSION, Perl $], $^X" );
