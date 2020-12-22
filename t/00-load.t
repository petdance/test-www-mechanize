#!perl -T

use warnings;
use strict;

use Test::More tests => 1;

use LWP;
use WWW::Mechanize;
use Test::Builder::Tester;
use Test::WWW::Mechanize;

pass( 'Modules loaded' );

diag( "Testing Test::WWW::Mechanize $Test::WWW::Mechanize::VERSION undef Perl $], $^X" );
diag( "LWP $LWP::VERSION" );
diag( "WWW::Mechanize $WWW::Mechanize::VERSION" );
diag( "Test::More $Test::More::VERSION" );
diag( "Test::Builder::Tester $Test::Builder::Tester::VERSION" );

for my $module ( qw( HTML::Lint HTML::Tidy5 ) ) {
    my $rc = eval "use $module; 1;";
    if ( $rc ) {
        no strict 'refs';
        my $version = ${"${module}::VERSION"};
        diag( "Found optional $module $version" );
    }
    else {
        diag( "Optional $module not found. Install it to use additional features." );
    }
}

done_testing();
