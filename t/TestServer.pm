package TestServer;

use base 'HTTP::Server::Simple::CGI';

use Carp ();

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $file = (split('/',$cgi->path_info))[-1]||'index.html';
    $file    =~ s/\s+//g;

    my $filename = "t/html/$file";
    if ( -r $filename ) {
        if (my $response=do { local (@ARGV, $/) = $filename; <> }) {
            print "HTTP/1.0 200 OK\r\n";
            print "Content-Type: text/html\r\nContent-Length: ", length($response), "\r\n\r\n", $response;
            return;
        }
    }

    print "HTTP/1.0 404 Not Found\r\n\r\n";
}

sub background {
    my $self = shift;

    my $pid = $self->SUPER::background()
        or Carp::confess( q{Can't start the test server} );

    return $pid;
}

sub root {
    my $self = shift;
    my $port = $self->port;

    return "http://localhost:$port";
}

1;
