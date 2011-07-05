#!perl -Tw

use strict;
use warnings;
use Test::More tests => 4;
use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $mech = Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

my $uri = URI::file->new_abs( 't/manylinks.html' )->as_string;
$mech->get_ok( $uri );

# Good links.
my @links = $mech->followable_links();
@links = map { $_->url_abs } @links;
my @expected = (
    URI::file->new_abs( 't/goodlinks.html' )->as_string,
    'http://bongo.com/wang.html',
    'https://secure.bongo.com/',
    URI::file->new_abs( 't/badlinks.html' )->as_string,
    URI::file->new_abs( 't/goodlinks.html' )->as_string,
);
is_deeply( \@links, \@expected, 'Got the right links' );

done_testing();
