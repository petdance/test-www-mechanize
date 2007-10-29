#!perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Builder::Tester;
use URI::file;

use constant PORT => 13432;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}


my $server=TWMServer->new(PORT);
my $pid=$server->background;
ok($pid,'HTTP Server started') or die "Can't start the server";
sleep 1; # $server->background() may come back prematurely, so give it a second to fire up

sub cleanup { kill(9,$pid) };
$SIG{__DIE__}=\&cleanup;

SUBMIT_GOOD_FORM: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get('http://localhost:'.PORT.'/form.html');
    $mech->submit_form_ok( {form_number =>1}, "Submit First Form" );
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
