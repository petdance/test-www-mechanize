#!perl -T

use warnings;
use strict;

use Test::More tests => 1;

use LWP;
use WWW::Mechanize;
use Test::WWW::Mechanize;

pass( 'Modules loaded' );

diag( "Testing Test::WWW::Mechanize $Test::WWW::Mechanize::VERSION, with WWW::Mechanize $WWW::Mechanize::VERSION, LWP $LWP::VERSION, Perl $], $^X" );

done_testing();
