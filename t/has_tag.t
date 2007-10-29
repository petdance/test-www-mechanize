#!perl -w

use strict;
use warnings;
use Test::More tests => 7;
use Test::Builder::Tester;
use URI::file;

use constant PORT => 13432;

$ENV{http_proxy} = ''; # All our tests are running on localhost

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $server=TWMServer->new(PORT);
my $pid=$server->background;
ok($pid,'HTTP Server started') or die "Can't start the server";
# $server->background() may come back prematurely, so give it a second to fire up
sleep 1;

sub cleanup { kill(9,$pid) if !$^S };
$SIG{__DIE__}=\&cleanup;

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get('http://localhost:'.PORT.'/goodlinks.html');

test_out( 'ok 1 - looking for "Test" link' );
$mech->has_tag( h1 => 'Test Page', 'looking for "Test" link' );
test_test( 'Handles finding tag by content' );

test_out( 'not ok 1 - looking for "Quiz" link' );
test_fail( +1 );
$mech->has_tag( h1 => 'Quiz', 'looking for "Quiz" link' );
test_test( 'Handles unfindable tag by content' );

test_out( 'ok 1 - Should have qr/Test 3/i link' );
$mech->has_tag_like( a => qr/Test 3/, 'Should have qr/Test 3/i link' );
test_test( 'Handles finding tag by content regexp' );

test_out( 'not ok 1 - Should be missing qr/goof/i link' );
test_fail( +1 );
$mech->has_tag_like( a => qr/goof/i, 'Should be missing qr/goof/i link' );
test_test( 'Handles unfindable tag by content regexp' );


cleanup();

{
  package TWMServer;
  use base 'HTTP::Server::Simple::CGI';

  sub handle_request {
    my $self=shift;
    my $cgi=shift;

    my $file=(split('/',$cgi->path_info))[-1]||'index.html';
    $file=~s/\s+//g;

    if(-r "t/html/$file") {
      if(my $response=do { local (@ARGV, $/) = "t/html/$file"; <> }) {
        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: text/html\r\nContent-Length: ",
          length($response), "\r\n\r\n", $response;
        return;
      }
    }

    print "HTTP/1.0 404 Not Found\r\n\r\n";
  }
}
