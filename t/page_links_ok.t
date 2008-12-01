#!perl

use strict;
use warnings;
use Test::More tests => 5;
use Test::Builder::Tester;
use URI::file;

use constant PORT => 13432;

delete $ENV{http_proxy}; # All our tests are running on localhost

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $server=TWMServer->new(PORT);
my $pid=$server->background or die q{Can't start the server};
# Pause a second in case $server->background() came back too fast
sleep 1;

sub cleanup { kill(9,$pid) if !$^S }
$SIG{__DIE__}=\&cleanup;

my $mech=Test::WWW::Mechanize->new( autocheck => 0 );

isa_ok($mech,'Test::WWW::Mechanize');

$mech->get('http://localhost:'.PORT.'/goodlinks.html');

# Good links.
test_out('ok 1 - Checking all page links successful');
$mech->page_links_ok('Checking all page links successful');
test_test('Handles All page links successful');

# Good links - default desc
test_out('ok 1 - All links ok');
$mech->page_links_ok();
test_test('Handles All page links successful - default desc');

# Bad links
$mech->get('http://localhost:'.PORT.'/badlinks.html');

test_out('not ok 1 - Checking some page link failures');
test_fail(+4);
test_diag('bad1.html');
test_diag('bad2.html');
test_diag('bad3.html');
$mech->page_links_ok('Checking some page link failures');
test_test('Handles link not found');


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
