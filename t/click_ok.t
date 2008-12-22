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


my $server = TWMServer->new;
my $pid    = $server->background;
ok( $pid, 'HTTP Server started' ) or die "Can't start the server";
sleep 1; # $server->background() may come back prematurely, so give it a second to fire up

my $port = $server->port;

sub cleanup { kill(9,$pid) };
$SIG{__DIE__}=\&cleanup;

SUBMIT_GOOD_FORM: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get( "http://localhost:$port/form.html" );
    $mech->click_ok( 'big_button', 'Submit First Form' );
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

        my $filename = "t/html/$file";
        if ( -r $filename ) {
            if (my $response=do { local (@ARGV, $/) = $filename; <> }) {
                print "HTTP/1.0 200 OK\r\n";
                print "Content-Type: text/html\r\nContent-Length: ",
                length($response), "\r\n\r\n", $response;
                return;
            }
        }

        print "HTTP/1.0 404 Not Found\r\n\r\n";
    }
}
