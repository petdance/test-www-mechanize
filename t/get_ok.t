#!perl

use strict;
use warnings;
use Test::More;
use Test::Builder::Tester;
use URI::file;

use constant PORT => 13432;

use constant NONEXISTENT => 'http://blahblablah.xx-nonexistent.';
BEGIN {
    if ( gethostbyname( 'blahblahblah.xx-nonexistent.' ) ) {
        plan skip_all => 'Found an A record for the non-existent domain';
    }
}

BEGIN {
    $ENV{http_proxy} = ''; # All our tests are running on localhost
    plan tests => 11;
    use_ok( 'Test::WWW::Mechanize' );
}


my $server=TWMServer->new(PORT);
my $pid=$server->background;
ok( $pid,'HTTP Server started' ) or die "Can't start the server";
sleep 1; # $server->background() may come back prematurely, so give it a second to fire up

sub cleanup { kill(9,$pid) if !$^S };
$SIG{__DIE__}=\&cleanup;

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

GOOD_GET: {
    my $goodlinks='http://localhost:'.PORT.'/goodlinks.html';

    $mech->get($goodlinks);
    ok($mech->success, 'sanity check: we can load goodlinks.html');

    test_out('ok 1 - Try to get goodlinks.html');
    my $ok = $mech->get_ok($goodlinks, 'Try to get goodlinks.html');
    test_test('Gets existing URI and reports success');
    is( ref($ok), '', "get_ok() should only return a scalar" );
    ok( $ok, "And the result should be true" );
}

BAD_GET: {
    my $badurl = "http://wango.nonexistent.xx-only-testing/";
    $mech->get($badurl);
    ok(!$mech->success, "sanity check: we can't load NONEXISTENT.html");

    test_out( 'not ok 1 - Try to get bad URL' );
    test_fail( +3 );
    test_diag( "500" );
    test_diag( "Can't connect to wango.nonexistent.xx-only-testing:80 (Bad hostname 'wango.nonexistent.xx-only-testing')" );
    my $ok = $mech->get_ok( $badurl, 'Try to get bad URL' );
    test_test( 'Fails to get nonexistent URI and reports failure' );

    is( ref($ok), '', "get_ok() should only return a scalar" );
    ok( !$ok, "And the result should be false" );
}


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
