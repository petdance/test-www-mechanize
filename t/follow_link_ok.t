#!perl

use strict;
use warnings;
use Test::More tests => 6;
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

sub cleanup { kill(9,$pid) if !$^S };
$SIG{__DIE__}=\&cleanup;

FOLLOW_GOOD_LINK: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get('http://localhost:'.PORT.'/goodlinks.html');
    $mech->follow_link_ok( {n=>1}, "Go after first link" );
}

#FOLLOW_BAD_LINK: {
my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech,'Test::WWW::Mechanize' );
TODO: {
    local $TODO = "I don't know how to get Test::Builder::Tester to handle regexes for the timestamp.";

    $mech->get('http://localhost:'.PORT.'/badlinks.html');
    test_out('not ok 1 - Go after bad link');
    test_fail(+1);
    $mech->follow_link_ok( {n=>2}, "Go after bad link" );
    test_diag('');
    test_test('Handles bad links');
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
