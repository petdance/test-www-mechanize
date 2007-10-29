#!perl

use strict;
use warnings;
use Test::More tests => 8;
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

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get('http://localhost:'.PORT.'/goodlinks.html');

# Good links.
my $links=$mech->links();
test_out('ok 1 - Checking all links status are 200');
$mech->link_status_is($links,200,'Checking all links status are 200');
test_test('Handles All Links successful');

$mech->link_status_isnt($links,404,'Checking all links isnt');

# Bad links
#$mech->get(URI::file->cwd().'t/badlinks.html');
$mech->get('http://localhost:'.PORT.'/badlinks.html');

$links=$mech->links();
test_out('not ok 1 - Checking all links some bad');
test_fail(+2);
test_diag('goodlinks.html');
$mech->link_status_is($links,404,'Checking all links some bad');
test_test('Handles bad links');


test_out('not ok 1 - Checking specified link not found');
test_fail(+2);
test_diag('test2.html');
$mech->links_ok('test2.html','Checking specified link not found');
test_test('Handles link not found');

test_out('not ok 1 - Checking all links not 200');
test_fail(+2);
test_diag('goodlinks.html');
$mech->link_status_isnt($links,200,'Checking all links not 200');
test_test('Handles all links mismatch');

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
