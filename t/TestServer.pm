package TestServer;

use warnings;
use strict;

use Test::More;
use HTTP::Server::Simple::CGI;
use Cwd qw( realpath );
use parent qw( HTTP::Server::Simple::CGI );

my $dispatch_table = {};

=head1 OVERLOADED METHODS

=cut

our $pid;

sub new {
    die 'An instance of TestServer has already been started.' if $pid;

    my $class = shift;
    my $port  = shift;

    if ( !$port ) {
        $port = int(rand(20000)) + 20000;
    }
    my $self = $class->SUPER::new( $port );

    my $root = $self->root;

    return $self;
}

sub run {
    my $self = shift;

    $pid = $self->SUPER::run(@_);

    $SIG{__DIE__} = \&stop;

    return $pid;
}

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path = $cgi->path_info();
    my $handler = $dispatch_table->{$path};

    if (ref($handler) eq 'CODE') {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);
    }
    else {
        my $file = $path;
        if ( $file =~ m{/$} ) {
            $file .= 'index.html';
        }
        $file =~ s/\s+//g;
        my $filename = "t/html/$file";

        my ($code, $msg) = (200, 'OK');
        if ( ! -r $filename ) {
            ($code, $msg) = (404, 'Not Found');
        }
        if (index(realpath($filename), realpath("t/html")) != 0) {
            # don't expose a file outside server root
            ($code, $msg) = (403, 'Forbidden');
        }

        print "HTTP/1.0 $code $msg\r\n";

        if ($code == 200) {
            if (my $response=do { local (@ARGV, $/) = $filename; <> }) {
                print
                    "Content-Type: text/html\r\n",
                    "Content-Length: ", length($response), "\r\n\r\n",
                    $response;
            }
        }
        else {
            print
                $cgi->header,
                $cgi->start_html($msg),
                $cgi->h1($msg),
                $cgi->end_html;
        }
    }

    return;
}

=head1 METHODS UNIQUE TO TestServer

=cut

sub set_dispatch {
    my $self = shift;
    $dispatch_table = shift;

    return;
}

sub background {
    my $self = shift;

    $pid = $self->SUPER::background()
        or Carp::confess( q{Can't start the test server} );

    sleep 1; # background() may come back prematurely, so give it a second to fire up

    my $root = $self->root;

    diag( "Test server $root as PID $pid" );

    return $pid;
}


sub hostname {
    my $self = shift;

    return '127.0.0.1';
}

sub root {
    my $self = shift;
    my $port = $self->port;
    my $hostname = $self->hostname;

    return "http://$hostname:$port";
}

sub stop {
    if ( $pid ) {
        kill( 9, $pid ) unless $^S;
        undef $pid;
    }

    return;
}

1;
