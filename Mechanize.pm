package Test::WWW::Mechanize;

use strict;
use warnings;
use 5.010;

=head1 NAME

Test::WWW::Mechanize - Testing-specific WWW::Mechanize subclass

=head1 VERSION

Version 1.60

=cut

our $VERSION = '1.60';

=head1 SYNOPSIS

Test::WWW::Mechanize is a subclass of L<WWW::Mechanize> that incorporates
features for web application testing.  For example:

    use Test::More tests => 5;
    use Test::WWW::Mechanize;

    my $mech = Test::WWW::Mechanize->new;
    $mech->get_ok( $page );
    $mech->base_is( 'http://petdance.com/', 'Proper <BASE HREF>' );
    $mech->title_is( 'Invoice Status', "Make sure we're on the invoice page" );
    $mech->text_contains( 'Andy Lester', 'My name somewhere' );
    $mech->content_like( qr/(cpan|perl)\.org/, 'Link to perl.org or CPAN' );

This is equivalent to:

    use Test::More tests => 5;
    use WWW::Mechanize;

    my $mech = WWW::Mechanize->new;
    $mech->get( $page );
    ok( $mech->success );
    is( $mech->base, 'http://petdance.com', 'Proper <BASE HREF>' );
    is( $mech->title, 'Invoice Status', "Make sure we're on the invoice page" );
    ok( index( $mech->content( format => 'text' ), 'Andy Lester' ) >= 0, 'My name somewhere' );
    like( $mech->content, qr/(cpan|perl)\.org/, 'Link to perl.org or CPAN' );

but has nicer diagnostics if they fail.

Default descriptions will be supplied for most methods if you omit them. e.g.

    my $mech = Test::WWW::Mechanize->new;
    $mech->get_ok( 'http://petdance.com/' );
    $mech->base_is( 'http://petdance.com/' );
    $mech->title_is( 'Invoice Status' );
    $mech->content_contains( 'Andy Lester' );
    $mech->content_like( qr/(cpan|perl)\.org/ );

results in

    ok - Got 'http://petdance.com/' ok
    ok - Base is 'http://petdance.com/'
    ok - Title is 'Invoice Status'
    ok - Text contains 'Andy Lester'
    ok - Content is like '(?-xism:(cpan|perl)\.org)'

=cut

use HTML::TokeParser ();
use WWW::Mechanize ();
use Test::LongString;
use Test::Builder ();
use Carp ();
use Carp::Assert::More qw(
    assert_arrayref
    assert_in
    assert_is
    assert_isa
    assert_nonblank
);

use parent 'WWW::Mechanize';

my $TB = Test::Builder->new();


=head1 CONSTRUCTOR

=head2 new( %args )

Behaves like, and calls, L<WWW::Mechanize>'s C<new> method.  Any parms
passed in get passed to WWW::Mechanize's constructor.

You can pass in C<< autolint => 1 >> to make Test::WWW::Mechanize
automatically run HTML::Lint after any of the following methods are
called. You can also pass in an HTML::Lint object like this:

    my $lint = HTML::Lint->new( only_types => HTML::Lint::Error::STRUCTURE );
    my $mech = Test::WWW::Mechanize->new( autolint => $lint );

The same is also possible with C<< autotidy => 1 >> to use HTML::Tidy5.

=over

=item * get_ok()

=item * post_ok()

=item * submit_form_ok()

=item * follow_link_ok()

=item * click_ok()

=back

This means you no longer have to do the following:

    my $mech = Test::WWW::Mechanize->new();
    $mech->get_ok( $url, 'Fetch the intro page' );
    $mech->html_lint_ok( 'Intro page looks OK' );

and can simply do

    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    $mech->get_ok( $url, 'Fetch the intro page' );

The C<< $mech->get_ok() >> only counts as one test in the test count.  Both the
main IO operation and the linting must pass for the entire test to pass.

You can control autolint and autotidy on the fly with the C<autolint>
and C<autotidy> methods.

=cut

sub new {
    my $class = shift;

    my %args = (
        agent => "Test-WWW-Mechanize/$VERSION",
        @_
    );

    my $autolint = delete $args{autolint};
    my $autotidy = delete $args{autotidy};

    my $self = $class->SUPER::new( %args );

    $self->autolint( $autolint );
    $self->autotidy( $autotidy );

    return $self;
}


# Override WWW::Mechanize->_reset_page() to handle Test::WWW::Mechanize-specific data.
sub _reset_page {
    my $self = shift;

    # Parent object stuff
    $self->SUPER::_reset_page( @_ );

    $self->{ids} = undef;

    return;
}


=head1 METHODS: HTTP VERBS

=head2 $mech->get_ok($url, [ \%LWP_options ,] $desc)

A wrapper around WWW::Mechanize's get(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "GET $url" is used if none if provided.

=cut

sub get_ok {
    my $self = shift;

    my ($url,$desc,%opts) = $self->_unpack_args( 'GET', @_ );

    if ( !defined($url) ) {
        my $ok = $TB->ok( 0, $desc );
        $TB->diag( 'URL cannot be undef.' );
        return $ok;
    }

    $self->get( $url, %opts );
    my $ok = $self->success;

    $ok = $self->_post_load_validation( $ok, $desc );

    return $ok;
}

sub _post_load_validation {
    my $self = shift;
    my $ok   = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if ( $ok ) {
        my $emitted_ok = 0;
        if ( $self->is_html ) {
            if ( $self->autolint && $self->autotidy ) {
                my $msg = 'autolint & autotidy';
                $msg .= ": $desc" if defined $desc;
                $TB->subtest(
                    $desc,
                    sub {
                        $self->_lint_content_ok();
                        $self->_tidy_content_ok();
                    }
                );
                ++$emitted_ok;
            }
            else {
                if ( $self->autolint ) {
                    $ok = $self->_lint_content_ok( $desc );
                    ++$emitted_ok;
                }
                elsif ( $self->autotidy ) {
                    $ok = $self->_tidy_content_ok( $desc );
                    ++$emitted_ok;
                }
            }
        }

        if ( !$emitted_ok ) {
            $TB->ok( $ok, $desc );
            if ( !$ok ) {
                # Only show the URL and not the response message, because the
                # problem is with the lint/tidy, not the fetching of the URL.
                my $url = $self->_diag_url();
                $TB->diag( $url ) if $url;
            }
        }
    }
    else {
        $TB->ok( $ok, $desc );
        my $url = $self->_diag_url();
        $TB->diag( $url ) if $url;
        $TB->diag( $self->status );
        $TB->diag( $self->response->message ) if $self->response;
    }

    return $ok;
}


=head2 $mech->head_ok($url, [ \%LWP_options ,] $desc)

A wrapper around WWW::Mechanize's head(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "HEAD $url" is used if none if provided.

=cut

sub head_ok {
    my $self = shift;

    my ($url,$desc,%opts) = $self->_unpack_args( 'HEAD', @_ );

    if ( !defined($url) ) {
        my $ok = $TB->ok( 0, $desc );
        $TB->diag( 'URL cannot be undef.' );
        return $ok;
    }

    $self->head( $url, %opts );
    my $ok = $self->success;

    $TB->ok( $ok, $desc );
    if ( !$ok ) {
        my $url = $self->_diag_url();
        $TB->diag( $url ) if $url;
        $TB->diag( $self->status );
        $TB->diag( $self->response->message ) if $self->response;
    }

    return $ok;
}


=head2 $mech->post_ok( $url, [ \%LWP_options ,] $desc )

A wrapper around WWW::Mechanize's post(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

B<NOTE> Due to compatibility reasons it is not possible to pass
additional LWP_options beyond form data via this method (such as
Content or Content-Type).  It is recommend that you use WWW::Mechanize's
post() directly for instances where more granular control of the post
is needed.

A default description of "POST to $url" is used if none if provided.

=cut

sub post_ok {
    my $self = shift;

    my ($url,$desc,%opts) = $self->_unpack_args( 'POST', @_ );

    if ( !defined($url) ) {
        my $ok = $TB->ok( 0, $desc );
        $TB->diag( 'URL cannot be undef.' );
        return $ok;
    }

    $self->post( $url, \%opts );
    my $ok = $self->success;
    $ok = $self->_post_load_validation( $ok, $desc );

    return $ok;
}

=head2 $mech->put_ok( $url, [ \%LWP_options ,] $desc )

A wrapper around WWW::Mechanize's put(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "PUT to $url" is used if none if provided.

=cut

sub put_ok {
    my $self = shift;

    my ($url,$desc,%opts) = $self->_unpack_args( 'PUT', @_ );

    if ( !defined($url) ) {
        my $ok = $TB->ok( 0, $desc );
        $TB->diag( 'URL cannot be undef.' );
        return $ok;
    }

    $opts{content} = '' if !exists $opts{content};
    $self->put( $url, %opts );

    my $ok = $self->success;
    $TB->ok( $ok, $desc );
    if ( !$ok ) {
        my $url = $self->_diag_url();
        $TB->diag( $url ) if $url;
        $TB->diag( $self->status );
        $TB->diag( $self->response->message ) if $self->response;
    }

    return $ok;
}

=head2 $mech->delete_ok( $url, [ \%LWP_options ,] $desc )

A wrapper around WWW::Mechanize's delete(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

A default description of "DELETE to $url" is used if none if provided.

=cut

sub delete_ok {
    my $self = shift;

    my ($url,$desc,%opts) = $self->_unpack_args( 'DELETE', @_ );

    if ( !defined($url) ) {
        my $ok = $TB->ok( 0, $desc );
        $TB->diag( 'URL cannot be undef.' );
        return $ok;
    }

    if ($self->can('delete')) {
        $self->delete( $url, %opts );
    }
    else {
        # When version of LWP::UserAgent is older than 6.04.
        $self->_delete( $url, %opts );
    }
    my $ok = $self->success;

    $ok = $self->_post_load_validation( $ok, $desc );

    return $ok;
}

sub _delete {
    require URI;
    require HTTP::Request::Common;
    my $self = shift;
    my $uri  = shift;

    $uri = $uri->url if ref($uri) eq 'WWW::Mechanize::Link';
    $uri = $self->base
      ? URI->new_abs( $uri, $self->base )
      : URI->new($uri);

    my @parameters = ( $uri->as_string, @_ );
    my @suff = $self->_process_colonic_headers( \@parameters, 1 );
    return $self->request( HTTP::Request::Common::DELETE(@parameters), @suff );
}

=head2 $mech->submit_form_ok( \%parms [, $desc] )

Makes a C<submit_form()> call and executes tests on the results.
The form must be found, and then submitted successfully.  Otherwise,
this test fails.

I<%parms> is a hashref containing the parms to pass to C<submit_form()>.
Note that the parms to C<submit_form()> are a hash whereas the parms to
this function are a hashref.  You have to call this function like:

    $mech->submit_form_ok( {
            form_number => 3,
            fields      => {
                answer => 42
            },
        }, 'now we just need the question'
    );

As with other test functions, C<$desc> is optional.  If it is supplied
then it will display when running the test harness in verbose mode.

Returns true value if the specified link was found and followed
successfully.  The L<HTTP::Response> object returned by submit_form()
is not available.

=cut

sub submit_form_ok {
    my $self = shift;
    my $parms = shift || {};
    my $desc = shift;

    if ( ref $parms ne 'HASH' ) {
        Carp::croak 'FATAL: parameters must be given as a hashref';
    }

    # return from submit_form() is an HTTP::Response or undef
    my $response = $self->submit_form( %{$parms} );

    my $ok = $response && $response->is_success;
    $ok = $self->_post_load_validation( $ok, $desc );

    return $ok;
}


=head2 $mech->follow_link_ok( \%parms [, $desc] )

Makes a C<follow_link()> call and executes tests on the results.
The link must be found, and then followed successfully.  Otherwise,
this test fails.

I<%parms> is a hashref containing the parms to pass to C<follow_link()>.
Note that the parms to C<follow_link()> are a hash whereas the parms to
this function are a hashref.  You have to call this function like:

    $mech->follow_link_ok( {n=>3}, 'looking for 3rd link' );

As with other test functions, C<$desc> is optional.  If it is supplied
then it will display when running the test harness in verbose mode.

Returns a true value if the specified link was found and followed
successfully.  The L<HTTP::Response> object returned by follow_link()
is not available.

=cut

sub follow_link_ok {
    my $self = shift;
    my $parms = shift || {};
    my $desc = shift;

    if (!defined($desc)) {
        my $parms_str = join(', ', map { join('=', $_, $parms->{$_}) } keys(%{$parms}));
        $desc = qq{Followed link with "$parms_str"} if !defined($desc);
    }

    if ( ref $parms ne 'HASH' ) {
       Carp::croak 'FATAL: parameters must be given as a hashref';
    }

    # The return from follow_link() is an HTTP::Response or undef.
    my $response = $self->follow_link( %{$parms} );

    my $ok = $response && $response->is_success;
    $ok = $self->_post_load_validation( $ok, $desc );

    return $ok;
}


=head2 $mech->click_ok( $button[, $desc] )

=head2 $mech->click_ok( \@button-and-coordinates [, $desc ] )

Clicks the button named by C<$button>.  An optional C<$desc> can be
given for the test.

    $mech->click_ok( 'continue', 'Clicking the "Continue" button' );

Alternatively the first argument can be an arrayref with three elements:
The name of the button and the X and Y coordinates of the button.

    $mech->click_ok( [ 'continue', 12, 47 ], 'Clicking the "Continue" button' );

=cut

sub click_ok {
    my $self   = shift;
    my $button = shift;
    my $desc   = shift;

    my $response;
    if ( ref($button) eq 'ARRAY' ) {
        $response = $self->click( $button->[0], $button->[1], $button->[2] );
    }
    else {
        $response = $self->click( $button );
    }

    if ( !$response ) {
        return $TB->ok( 0, $desc );
    }

    my $ok = $response->is_success;

    $ok = $self->_post_load_validation( $ok, $desc );

    return $ok;
}


sub _unpack_args {
    my $self   = shift;
    my $method = shift;
    my $url    = shift;

    my $desc;
    my %opts;

    if ( @_ ) {
        my $flex = shift; # The flexible argument

        if ( !defined( $flex ) ) {
            $desc = shift;
        }
        elsif ( ref $flex eq 'HASH' ) {
            %opts = %{$flex};
            $desc = shift;
        }
        elsif ( ref $flex eq 'ARRAY' ) {
            %opts = @{$flex};
            $desc = shift;
        }
        else {
            $desc = $flex;
        }
    } # parms left

    if ( not defined $desc ) {
        $url = $url->url if ref($url) eq 'WWW::Mechanize::Link';
        $desc = "$method $url";
    }

    return ($url, $desc, %opts);
}


=head1 METHODS: HEADER CHECKING

=head2 $mech->header_exists_ok( $header [, $desc ] )

Assures that a given response header exists. The actual value of the
response header is not checked, only that the header exists.

=cut

sub header_exists_ok {
    my $self = shift;
    my $header = shift;
    my $desc = shift || qq{Response has $header header};

    return $TB->ok( defined($self->response->header($header)), $desc );
}


=head2 $mech->lacks_header_ok( $header [, $desc ] )

Assures that a given response header does NOT exist.

=cut

sub lacks_header_ok {
    my $self   = shift;
    my $header = shift;
    my $desc   = shift || qq{Response lacks $header header};

    return $TB->ok( !defined($self->response->header($header)), $desc );
}


=head2 $mech->header_is( $header, $value [, $desc ] )

Assures that a given response header exists and has the given value.

=cut

sub header_is {
    my $self   = shift;
    my $header = shift;
    my $value  = shift;
    my $desc   = shift || qq{Response has $header header with value "$value"};

    # Force scalar context.
    my $actual_value = $self->response->header($header);

    my $ok;
    if ( defined( $actual_value ) ) {
        $ok = $TB->is_eq( $actual_value, $value, $desc );
    }
    else {
        $ok = $TB->ok( 0, $desc );
        $TB->diag( "Header $header does not exist" );
    }

    return $ok;
}


=head2 $mech->header_like( $header, $value [, $desc ] )

Assures that a given response header exists and has the given value.

=cut

sub header_like {
    my $self   = shift;
    my $header = shift;
    my $regex  = shift;
    my $desc   = shift || qq{Response has $header header that matches regex $regex};

    # Force scalar context.
    my $actual_value = $self->response->header($header);
    return $TB->like( $self->response->header($header), $regex, $desc );
}


=head1 METHODS: CONTENT CHECKING

=head2 $mech->html_lint_ok( [$desc] )

Checks the validity of the HTML on the current page using the HTML::Lint
module.  If the page is not HTML, then it fails.  The URI is automatically
appended to the I<$desc>.

Note that HTML::Lint must be installed for this to work.  Otherwise,
it will blow up.

=cut

sub html_lint_ok {
    my $self = shift;
    my $desc = shift;

    my $uri = $self->uri;
    $desc = $desc ? "$desc ($uri)" : $uri;

    my $ok;

    if ( $self->is_html ) {
        $ok = $self->_lint_content_ok( $desc );
    }
    else {
        $ok = $TB->ok( 0, $desc );
        $TB->diag( q{This page doesn't appear to be HTML, or didn't get the proper text/html content type returned.} );
    }

    return $ok;
}


sub _lint_content_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my $desc = shift;

    my $module = "HTML::Lint 2.20";
    if ( not ( eval "use $module; 1;" ) ) {
        die "Test::WWW::Mechanize can't do linting without $module: $@";
    }

    my $lint = $self->{autolint};
    if ( ref $lint && $lint->isa('HTML::Lint') ) {
        $lint->newfile;
        $lint->clear_errors;
    }
    else {
        $lint = HTML::Lint->new();
    }

    $lint->parse( $self->content );
    $lint->eof();

    my @errors = $lint->errors;
    my $nerrors = @errors;
    my $ok;
    if ( $nerrors ) {
        $ok = $TB->ok( 0, $desc );
        $TB->diag( 'HTML::Lint errors for ' . $self->uri );
        $TB->diag( $_->as_string ) for @errors;
        my $s = $nerrors == 1 ? '' : 's';
        $TB->diag( "$nerrors error$s on the page" );
    }
    else {
        $ok = $TB->ok( 1, $desc );
    }

    return $ok;
}


=head2 $mech->html_tidy_ok( [$desc] )

Checks the validity of the HTML on the current page using the HTML::Tidy
module.  If the page is not HTML, then it fails.  The URI is automatically
appended to the I<$desc>.

Note that HTML::tidy must be installed for this to work.  Otherwise,
it will blow up.

=cut

sub html_tidy_ok {
    my $self = shift;
    my $desc = shift;

    my $uri = $self->uri;
    $desc = $desc ? "$desc ($uri)" : $uri;

    my $ok;

    if ( $self->is_html ) {
        $ok = $self->_tidy_content_ok( $desc );
    }
    else {
        $ok = $TB->ok( 0, $desc );
        $TB->diag( q{This page doesn't appear to be HTML, or didn't get the proper text/html content type returned.} );
    }

    return $ok;
}


sub _tidy_content_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my $desc = shift;

    my $module = 'HTML::Tidy5 1.00';

    if ( not ( eval "use $module; 1;" ) ) {
        die "Test::WWW::Mechanize can't do tidying without $module: $@";
    }

    my $tidy = $self->{autotidy};
    if ( ref $tidy && $tidy->isa('HTML::Tidy5') ) {
        $tidy->clear_messages();
    }
    else {
        $tidy = HTML::Tidy5->new();
    }

    $tidy->parse( '', $self->content_for_tidy );

    my @messages = $tidy->messages;
    my $nmessages = @messages;
    my $ok;
    if ( $nmessages ) {
        $ok = $TB->ok( 0, $desc );
        $TB->diag( 'HTML::Tidy5 messages for ' . $self->uri );
        $TB->diag( $_->as_string ) for @messages;
        my $s = $nmessages == 1 ? '' : 's';
        $TB->diag( "$nmessages message$s on the page" );
    }
    else {
        $ok = $TB->ok( 1, $desc );
    }

    return $ok;
}


=head2 $mech->content_for_tidy()

This method is called by C<html_tidy_ok()> to get the content that should
be validated by HTML::Tidy5. By default, this is just C<content()>,
but subclasses can override it to modify the content before validation.

This method should not change any state in the Mech object.  Specifically,
it should not actually modify any of the actual content.

=cut

sub content_for_tidy {
    my $self = shift;

    return $self->content;
}


=head2 $mech->title_is( $str [, $desc ] )

Tells if the title of the page is the given string.

    $mech->title_is( 'Invoice Summary' );

=cut

sub title_is {
    my $self = shift;
    my $str = shift;
    my $desc = shift;
    $desc = qq{Title is "$str"} if !defined($desc);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_string( $self->title, $str, $desc );
}

=head2 $mech->title_like( $regex [, $desc ] )

Tells if the title of the page matches the given regex.

    $mech->title_like( qr/Invoices for (.+)/ );

=cut

sub title_like {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;
    $desc = qq{Title is like "$regex"} if !defined($desc);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return like_string( $self->title, $regex, $desc );
}

=head2 $mech->title_unlike( $regex [, $desc ] )

Tells if the title of the page matches the given regex.

    $mech->title_unlike( qr/Invoices for (.+)/ );

=cut

sub title_unlike {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;
    $desc = qq{Title is unlike "$regex"} if !defined($desc);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unlike_string( $self->title, $regex, $desc );
}

=head2 $mech->base_is( $str [, $desc ] )

Tells if the base of the page is the given string.

    $mech->base_is( 'http://example.com/' );

=cut

sub base_is {
    my $self = shift;
    my $str = shift;
    my $desc = shift;
    $desc = qq{Base is "$str"} if !defined($desc);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_string( $self->base, $str, $desc );
}

=head2 $mech->base_like( $regex [, $desc ] )

Tells if the base of the page matches the given regex.

    $mech->base_like( qr{http://example.com/index.php?PHPSESSID=(.+)});

=cut

sub base_like {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;
    $desc = qq{Base is like "$regex"} if !defined($desc);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return like_string( $self->base, $regex, $desc );
}

=head2 $mech->base_unlike( $regex [, $desc ] )

Tells if the base of the page matches the given regex.

    $mech->base_unlike( qr{http://example.com/index.php?PHPSESSID=(.+)});

=cut

sub base_unlike {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;
    $desc = qq{Base is unlike "$regex"} if !defined($desc);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unlike_string( $self->base, $regex, $desc );
}

=head2 $mech->content_is( $str [, $desc ] )

Tells if the content of the page matches the given string

=cut

sub content_is {
    my $self = shift;
    my $str = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $desc = qq{Content is "$str"} if !defined($desc);

    return is_string( $self->content, $str, $desc );
}

=head2 $mech->content_contains( $str [, $desc ] )

Tells if the content of the page contains I<$str>.

=cut

sub content_contains {
    my $self = shift;
    my $str = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if ( ref($str) ) {
        return $TB->ok( 0, 'Test::WWW::Mechanize->content_contains called incorrectly.  It requires a scalar, not a reference.' );
    }
    $desc = qq{Content contains "$str"} if !defined($desc);

    return contains_string( $self->content, $str, $desc );
}

=head2 $mech->content_lacks( $str [, $desc ] )

Tells if the content of the page lacks I<$str>.

=cut

sub content_lacks {
    my $self = shift;
    my $str = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( ref($str) ) {
        return $TB->ok( 0, 'Test::WWW::Mechanize->content_lacks called incorrectly.  It requires a scalar, not a reference.' );
    }
    $desc = qq{Content lacks "$str"} if !defined($desc);

    return lacks_string( $self->content, $str, $desc );
}

=head2 $mech->content_like( $regex [, $desc ] )

Tells if the content of the page matches I<$regex>.

=cut

sub content_like {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;
    $desc = qq{Content is like "$regex"} if !defined($desc);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return like_string( $self->content, $regex, $desc );
}

=head2 $mech->content_unlike( $regex [, $desc ] )

Tells if the content of the page does NOT match I<$regex>.

=cut

sub content_unlike {
    my $self  = shift;
    my $regex = shift;
    my $desc  = shift || qq{Content is unlike "$regex"};

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unlike_string( $self->content, $regex, $desc );
}

=head2 $mech->text_contains( $str [, $desc ] )

Tells if the text form of the page's content contains I<$str>.

When your page contains HTML which is difficult, unimportant, or
unlikely to match over time as designers alter markup, use
C<text_contains> instead of C<content_contains>.

 # <b>Hi, <i><a href="some/path">User</a></i>!</b>
 $mech->content_contains('Hi, User'); # Fails.
 $mech->text_contains('Hi, User'); # Passes.

Text is determined by calling C<< $mech->text() >>.
See L<WWW::Mechanize/content>.

=cut

sub text_contains {
    my $self = shift;
    my $str  = shift;
    my $desc = shift || qq{Text contains "$str"};

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( ref($str) ) {
        return $TB->ok( 0, 'Test::WWW::Mechanize->text_contains called incorrectly.  It requires a scalar, not a reference.' );
    }

    return contains_string( $self->text, $str, $desc );
}

=head2 $mech->text_lacks( $str [, $desc ] )

Tells if the text of the page lacks I<$str>.

=cut

sub text_lacks {
    my $self = shift;
    my $str = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( ref($str) ) {
        return $TB->ok( 0, 'Test::WWW::Mechanize->text_lacks called incorrectly.  It requires a scalar, not a reference.' );
    }
    $desc = qq{Text lacks "$str"} if !defined($desc);

    return lacks_string( $self->text, $str, $desc );
}

=head2 $mech->text_like( $regex [, $desc ] )

Tells if the text form of the page's content matches I<$regex>.

=cut

sub text_like {
    my $self  = shift;
    my $regex = shift;
    my $desc  = shift || qq{Text is like "$regex"};

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return like_string( $self->text, $regex, $desc );
}

=head2 $mech->text_unlike( $regex [, $desc ] )

Tells if the text format of the page's content does NOT match I<$regex>.

=cut

sub text_unlike {
    my $self  = shift;
    my $regex = shift;
    my $desc  = shift || qq{Text is unlike "$regex"};

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unlike_string( $self->text, $regex, $desc );
}

=head2 $mech->has_tag( $tag, $text [, $desc ] )

Tells if the page has a C<$tag> tag with the given content in its text.

=cut

sub has_tag {
    my $self = shift;
    my $tag  = shift;
    my $text = shift;
    my $desc = shift || qq{Page has $tag tag with "$text"};

    my $found = $self->_tag_walk( $tag, sub { $text eq $_[0] } );

    return $TB->ok( $found, $desc );
}


=head2 $mech->has_tag_like( $tag, $regex [, $desc ] )

Tells if the page has a C<$tag> tag with the given content in its text.

=cut

sub has_tag_like {
    my $self = shift;
    my $tag  = shift;
    my $regex = shift;
    my $desc = shift;
    $desc = qq{Page has $tag tag like "$regex"} if !defined($desc);

    my $found = $self->_tag_walk( $tag, sub { $_[0] =~ $regex } );

    return $TB->ok( $found, $desc );
}


sub _tag_walk {
    my $self = shift;
    my $tag  = shift;
    my $match = shift;

    my $p = HTML::TokeParser->new( \($self->content) );

    while ( my $token = $p->get_tag( $tag ) ) {
        my $tagtext = $p->get_trimmed_text();
        return 1 if $match->( $tagtext );
    }
    return;
}

=head2 $mech->page_links_ok( [ $desc ] )

Follow all links on the current page and test for HTTP status 200

    $mech->page_links_ok('Check all links');

=cut

sub page_links_ok {
    my $self = shift;
    my $desc = shift;

    $desc = 'All links ok' unless defined $desc;

    my @links = $self->followable_links();
    my @urls = _format_links(\@links);

    my @failures = $self->_check_links_status( \@urls );
    my $ok = (@failures==0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->page_links_content_like( $regex [, $desc ] )

Follow all links on the current page and test their contents for I<$regex>.

    $mech->page_links_content_like( qr/foo/,
      'Check all links contain "foo"' );

=cut

sub page_links_content_like {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;

    $desc = qq{All links are like "$regex"} unless defined $desc;

    my $usable_regex=$TB->maybe_regex( $regex );

    if ( !defined( $usable_regex ) ) {
        my $ok = $TB->ok( 0, 'page_links_content_like' );
        $TB->diag(qq{     "$regex" doesn't look much like a regex to me.});
        return $ok;
    }

    my @links = $self->followable_links();
    my @urls = _format_links(\@links);

    my @failures = $self->_check_links_content( \@urls, $regex );
    my $ok = (@failures==0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->page_links_content_unlike( $regex [, $desc ] )

Follow all links on the current page and test their contents do not
contain the specified regex.

    $mech->page_links_content_unlike(qr/Restricted/,
      'Check all links do not contain Restricted');

=cut

sub page_links_content_unlike {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;
    $desc = qq{All links are unlike "$regex"} unless defined($desc);

    my $usable_regex=$TB->maybe_regex( $regex );

    if ( !defined( $usable_regex ) ) {
        my $ok = $TB->ok( 0, 'page_links_content_unlike' );
        $TB->diag(qq{     "$regex" doesn't look much like a regex to me.});
        return $ok;
    }

    my @links = $self->followable_links();
    my @urls = _format_links(\@links);

    my @failures = $self->_check_links_content( \@urls, $regex, 'unlike' );
    my $ok = (@failures==0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->links_ok( $links [, $desc ] )

Follow specified links on the current page and test for HTTP status
200.  The links may be specified as a reference to an array containing
L<WWW::Mechanize::Link> objects, an array of URLs, or a scalar URL
name.

    my @links = $mech->find_all_links( url_regex => qr/cnn\.com$/ );
    $mech->links_ok( \@links, 'Check all links for cnn.com' );

    my @links = qw( index.html search.html about.html );
    $mech->links_ok( \@links, 'Check main links' );

    $mech->links_ok( 'index.html', 'Check link to index' );

=cut

sub links_ok {
    my $self = shift;
    my $links = shift;
    my $desc = shift;

    my @urls = _format_links( $links );
    $desc = _default_links_desc(\@urls, 'are ok') unless defined $desc;
    my @failures = $self->_check_links_status( \@urls );
    my $ok = (@failures == 0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->link_status_is( $links, $status [, $desc ] )

Follow specified links on the current page and test for HTTP status
passed.  The links may be specified as a reference to an array
containing L<WWW::Mechanize::Link> objects, an array of URLs, or a
scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_status_is( \@links, 403,
      'Check all links are restricted' );

=cut

sub link_status_is {
    my $self = shift;
    my $links = shift;
    my $status = shift;
    my $desc = shift;

    my @urls = _format_links( $links );
    $desc = _default_links_desc(\@urls, "have status $status") if !defined($desc);
    my @failures = $self->_check_links_status( \@urls, $status );
    my $ok = (@failures == 0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->link_status_isnt( $links, $status [, $desc ] )

Follow specified links on the current page and test for HTTP status
passed.  The links may be specified as a reference to an array
containing L<WWW::Mechanize::Link> objects, an array of URLs, or a
scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_status_isnt( \@links, 404,
      'Check all links are not 404' );

=cut

sub link_status_isnt {
    my $self = shift;
    my $links = shift;
    my $status = shift;
    my $desc = shift;

    my @urls = _format_links( $links );
    $desc = _default_links_desc(\@urls, "do not have status $status") if !defined($desc);
    my @failures = $self->_check_links_status( \@urls, $status, 'isnt' );
    my $ok = (@failures == 0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}


=head2 $mech->link_content_like( $links, $regex [, $desc ] )

Follow specified links on the current page and test the resulting
content of each against I<$regex>.  The links may be specified as a
reference to an array containing L<WWW::Mechanize::Link> objects, an
array of URLs, or a scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_content_like( \@links, qr/Restricted/,
        'Check all links are restricted' );

=cut

sub link_content_like {
    my $self = shift;
    my $links = shift;
    my $regex = shift;
    my $desc = shift;

    my $usable_regex=$TB->maybe_regex( $regex );

    if ( !defined( $usable_regex ) ) {
        my $ok = $TB->ok( 0, 'link_content_like' );
        $TB->diag(qq{     "$regex" doesn't look much like a regex to me.});
        return $ok;
    }

    my @urls = _format_links( $links );
    $desc = _default_links_desc( \@urls, qq{are like "$regex"} ) if !defined($desc);
    my @failures = $self->_check_links_content( \@urls, $regex );
    my $ok = (@failures == 0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->link_content_unlike( $links, $regex [, $desc ] )

Follow specified links on the current page and test that the resulting
content of each does not match I<$regex>.  The links may be specified as a
reference to an array containing L<WWW::Mechanize::Link> objects, an array
of URLs, or a scalar URL name.

    my @links = $mech->followable_links();
    $mech->link_content_unlike( \@links, qr/Restricted/,
      'No restricted links' );

=cut

sub link_content_unlike {
    my $self = shift;
    my $links = shift;
    my $regex = shift;
    my $desc = shift;

    my $usable_regex=$TB->maybe_regex( $regex );

    if ( !defined( $usable_regex ) ) {
        my $ok = $TB->ok( 0, 'link_content_unlike' );
        $TB->diag(qq{     "$regex" doesn't look much like a regex to me.});
        return $ok;
    }

    my @urls = _format_links( $links );
    $desc = _default_links_desc( \@urls, qq{are not like "$regex"} ) if !defined($desc);
    my @failures = $self->_check_links_content( \@urls, $regex, 'unlike' );
    my $ok = (@failures == 0);

    $TB->ok( $ok, $desc );
    $TB->diag( $_ ) for @failures;

    return $ok;
}

# Create a default description for the link_* methods, including the link count.
sub _default_links_desc {
    my ($urls, $desc_suffix) = @_;
    my $url_count = scalar(@{$urls});
    return sprintf( '%d link%s %s', $url_count, $url_count == 1 ? '' : 's', $desc_suffix );
}

# This actually performs the status check of each URL.
sub _check_links_status {
    my $self = shift;
    my $urls = shift;
    my $status = shift || 200;
    my $test = shift || 'is';

    # Create a clone of the $mech used during the test as to not disrupt
    # the original.
    my $mech = $self->clone();

    my @failures;

    for my $url ( @{$urls} ) {
        if ( $mech->follow_link( url => $url ) ) {
            if ( $test eq 'is' ) {
                push( @failures, $url ) unless $mech->status() == $status;
            }
            else {
                push( @failures, $url ) if $mech->status() == $status;
            }
            $mech->back();
        }
        else {
            push( @failures, $url );
        }
    } # for

    return @failures;
}

# This actually performs the content check of each URL.
sub _check_links_content {
    my $self = shift;
    my $urls = shift;
    my $regex = shift || qr/<html>/;
    my $test = shift || 'like';

    # Create a clone of the $mech used during the test as to not disrupt
    # the original.
    my $mech = $self->clone();

    my @failures;
    for my $url ( @{$urls} ) {
        if ( $mech->follow_link( url => $url ) ) {
            my $content=$mech->content();
            if ( $test eq 'like' ) {
                push( @failures, $url ) unless $content =~ /$regex/;
            }
            else {
                push( @failures, $url ) if $content =~ /$regex/;
            }
            $mech->back();
        }
        else {
            push( @failures, $url );
        }
    } # for

    return @failures;
}

# Return a list of URLs to match for Mech to follow.
sub _format_links {
    my $links = shift;

    my @urls;
    if (ref($links) eq 'ARRAY') {
        my $link = $links->[0];
        if ( defined($link) ) {
            if ( ref($link) eq 'WWW::Mechanize::Link' ) {
                @urls = map { $_->url() } @{$links};
            }
            else {
                @urls = @{$links};
            }
        }
    }
    else {
        push(@urls,$links);
    }
    return @urls;
}

=head1 METHODS: SCRAPING

=head2 $mech->scrape_text_by_attr( $attr, $attr_value [, $html ] )

=head2 $mech->scrape_text_by_attr( $attr, $attr_regex [, $html ] )

Returns a list of strings, each string the text surrounded by an
element with attribute I<$attr> of value I<$value>.  You can also pass in
a regular expression.  If nothing is found the return is an empty list.
In scalar context the return is the first string found.

If passed, I<$html> is scraped instead of the current page's content.

=cut

sub scrape_text_by_attr {
    my $self = shift;
    my $attr = shift;
    my $value = shift;

    my $html = $self->_get_optional_html( @_ );

    my @results;

    if ( defined $html ) {
        my $parser = HTML::TokeParser->new(\$html);

        while ( my $token = $parser->get_tag() ) {
            if ( ref $token->[1] eq 'HASH' ) {
                if ( exists $token->[1]->{$attr} ) {
                    my $matched =
                        (ref $value eq 'Regexp')
                            ? $token->[1]->{$attr} =~ $value
                            : $token->[1]->{$attr} eq $value;
                    if ( $matched ) {
                        my $tag = $token->[ 0 ];
                        push @results, $parser->get_trimmed_text( "/$tag" );
                        if ( !wantarray ) {
                            last;
                        }
                    }
                }
            }
        }
    }

    return $results[0] if !wantarray;
    return @results;
}


=head2 $mech->scrape_text_by_id( $id [, $html ] )

Finds all elements with the given ID attribute and pulls out the text that that element encloses.

In list context, returns a list of all strings found. In scalar context, returns the first one found.

If C<$html> is not provided then the current content is used.

=cut

sub scrape_text_by_id {
    my $self = shift;
    my $id   = shift;

    my $html = $self->_get_optional_html( @_ );

    my @results;

    if ( defined $html ) {
        # If the ID doesn't appear anywhere in the text, then there's no point in parsing.
        my $found = index( $html, $id );
        if ( $found >= 0 ) {
            my $parser = HTML::TokeParser->new( \$html );

            while ( my $token = $parser->get_tag() ) {
                if ( ref $token->[1] eq 'HASH' ) {
                    my $actual_id = $token->[1]->{id};
                    $actual_id = '' unless defined $actual_id;
                    if ( $actual_id eq $id ) {
                        my $tag = $token->[ 0 ];
                        push @results, $parser->get_trimmed_text( "/$tag" );
                        if ( !wantarray ) {
                            last;
                        }
                    }
                }
            }
        }
    }

    return $results[0] if !wantarray;
    return @results;
}


sub _get_optional_html {
    my $self = shift;

    my $html;
    if ( @_ ) {
        $html = shift;
        assert_nonblank( $html, '$html passed in is a populated scalar' );
    }
    else {
        if ( $self->is_html ) {
            $html = $self->content();
        }
    }

    return $html;
}


=head2 $mech->scraped_id_is( $id, $expected [, $msg] )

Scrapes the current page for given ID and tests that it matches the expected value.

=cut

sub scraped_id_is {
    my $self     = shift;
    my $id       = shift;
    my $expected = shift;
    my $msg      = shift;

    my $ok;
    my $got = $self->scrape_text_by_id( $id );
    if ( defined( $got ) ) {
        $ok = $TB->is_eq( $got, $expected, $msg );
    }
    else {
        $ok = $TB->ok( 0, $msg );
        $TB->diag( qq{Can't find ID "$id" to compare to "$expected"} );
    }

    return $ok;
}


=head2 $mech->scraped_id_like( $id, $expected_regex [, $msg] )

Scrapes the current page for given id and tests that it matches the expected regex.

=cut

sub scraped_id_like {
    my $self     = shift;
    my $id       = shift;
    my $expected = shift;
    my $msg      = shift;

    my $ok;
    my $got = $self->scrape_text_by_id( $id );
    if ( defined($got) ) {
        $ok = $TB->like( $got, $expected, $msg );
    }
    else {
        $ok = $TB->ok( 0, $msg );
        $TB->diag( qq{Can't find ID "$id" to match against $expected} );
    }

    return $ok;
}


=head2 $mech->id_exists( $id )

Returns TRUE/FALSE if the given ID exists in the given HTML, or if none
is provided, then the current page.

The Mech object caches the IDs so that it doesn't bother reparsing every
time it's asked about an ID.

=cut

sub id_exists {
    my $self = shift;
    my $id   = shift;

    assert_is( $self->ct, 'text/html', 'Can only call id_exists on HTML pages' );

    if ( !$self->{ids} ) {
        my $ids = $self->{ids} = {};
        my $p = HTML::Parser->new(
            handlers => {
                start => [
                    sub {
                        my $attr = shift;

                        if ( my $id = $attr->{id} ) {
                            $ids->{$id} = 1;
                        }
                    },
                    'attr'
                ],
            },
        );
        $p->parse( $self->content );
        $p->eof;
    }

    return $self->{ids}->{$id};
}


=head2 $agent->id_exists_ok( $id [, $msg] )

Verifies there is an HTML element with ID C<$id> in the page.

=cut

sub id_exists_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my $id   = shift;
    my $msg  = shift || ('ID "' . ($id || '') . '" should exist');

    my $exists = $self->id_exists( $id );

    return $TB->ok( $exists, $msg );
}


=head2 $agent->ids_exist_ok( \@ids [, $msg] )

Verifies an HTML element exists with each ID in C<\@ids>.

=cut

sub ids_exist_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my $ids  = shift;
    my $msg  = shift;

    assert_arrayref( $ids );

    my $subtest_name = 'ids_exist_ok( [' . join( ', ', @{$ids} ) . ']';
    $subtest_name .= ", $msg" if defined $msg;
    $subtest_name .= ' )';

    return $TB->subtest(
        $subtest_name,
        sub {
            $TB->plan( tests => scalar @{$ids} );

            foreach my $id ( @$ids ) {
                $self->id_exists_ok( $id );
            }
        }
    );
}

=head2 $agent->lacks_id_ok( $id [, $msg] )

Verifies there is NOT an HTML element with ID C<$id> in the page.

=cut

sub lacks_id_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my $id   = shift;
    my $msg  = shift || ('ID "' . ($id || '') . '" should not exist');

    assert_nonblank( $id );

    my $exists = $self->id_exists( $id );

    return $TB->ok( !$exists, $msg );
}


=head2 $agent->lacks_ids_ok( \@ids [, $msg] )

Verifies there are no HTML elements with any of the ids given in C<\@ids>.

=cut

sub lacks_ids_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my $ids = shift;
    my $msg = shift;

    assert_arrayref( $ids );

    my $subtest_name = 'lacks_ids_ok( [' . join( ', ', @{$ids} ) . ']';
    $subtest_name .= ", $msg" if defined $msg;
    $subtest_name .= ' )';

    return $TB->subtest(
        $subtest_name,
        sub {
            $TB->plan( tests => scalar @{$ids} );

            foreach my $id ( @$ids ) {
                my $id_disp = defined($id) ? $id : '<undef>';
                $self->lacks_id_ok( $id, "ID '$id_disp' should not exist" );
            }
        }
    );
}


=head2 $mech->button_exists( $button )

Returns a boolean saying whether a submit button with the name C<$button> exists. Does not
do a test. For that you want C<button_exists_ok> or C<lacks_button_ok>.

=cut

sub button_exists {
    my $self   = shift;
    my $button = shift;

    my $input = $self->grep_inputs( {
        type => qr/^submit$/,
        name => qr/^$button$/
    } );

    return !!$input;
}


=head2 $mech->button_exists_ok( $button [, $msg] )

Asserts that the button exists on the page.

=cut

sub button_exists_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self   = shift;
    my $button = shift;
    my $msg    = shift || qq{Button named "$button" exists};

    return $TB->ok( $self->button_exists( $button ), $msg );
}


=head2 $mech->lacks_button_ok( $button [, $msg] )

Asserts that no button named C<$button> exists on the page.

=cut

sub lacks_button_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self   = shift;
    my $button = shift;
    my $msg    = shift || qq{No button named "$button" exists};

    return $TB->ok( !$self->button_exists( $button ), $msg );
}


=head1 METHODS: MISCELLANEOUS

=head2 $mech->autolint( [$status] )

Without an argument, this method returns a true or false value indicating
whether autolint is active.

When passed an argument, autolint is turned on or off depending on whether
the argument is true or false, and the previous autolint status is returned.
As with the autolint option of C<< new >>, C<< $status >> can be an
L<< HTML::Lint >> object.

If autolint is currently using an L<< HTML::Lint >> object you provided,
the return is that object, so you can change and exactly restore
autolint status:

    my $old_status = $mech->autolint( 0 );
    ... operations that should not be linted ...
    $mech->autolint( $old_status );

=cut

sub autolint {
    my $self = shift;

    my $ret = $self->{autolint};
    if ( @_ ) {
        $self->{autolint} = shift;
    }

    return $ret;
}


=head2 $mech->autotidy( [$status] )

Without an argument, this method returns a true or false value indicating
whether autotidy is active.

When passed an argument, autotidy is turned on or off depending on whether
the argument is true or false, and the previous autotidy status is returned.
As with the autotidy option of C<< new >>, C<< $status >> can be an
L<< HTML::Tidy5 >> object.

If autotidy is currently using an L<< HTML::Tidy5 >> object you provided,
the return is that object, so you can change and exactly restore
autotidy status:

    my $old_status = $mech->autotidy( 0 );
    ... operations that should not be tidied ...
    $mech->autotidy( $old_status );

=cut

sub autotidy {
    my $self = shift;

    my $ret = $self->{autotidy};
    if ( @_ ) {
        $self->{autotidy} = shift;
    }

    return $ret;
}


=head2 $mech->grep_inputs( \%properties )

Returns a list of all the input controls in the
current form whose properties match all of the regexes in C<$properties>.
The controls returned are all descended from HTML::Form::Input.

If C<$properties> is undef or empty then all inputs will be
returned.

If there is no current page, there is no form on the current
page, or there are no submit controls in the current form
then the return will be an empty list.

    # Get all text controls whose names begin with "customer".
    my @customer_text_inputs =
        $mech->grep_inputs( {
            type => qr/^(text|textarea)$/,
            name => qr/^customer/
        }
    );

=cut

sub grep_inputs {
    my $self = shift;
    my $properties = shift;

    my @found;

    my $form = $self->current_form();
    if ( $form ) {
        my @inputs = $form->inputs();
        @found = _grep_hashes( \@inputs, $properties );
    }

    return @found;
}


=head2 $mech->grep_submits( \%properties )

grep_submits() does the same thing as grep_inputs() except that
it only returns controls that are submit controls, ignoring
other types of input controls like text and checkboxes.

=cut

sub grep_submits {
    my $self = shift;
    my $properties = shift || {};

    $properties->{type} = qr/^(?:submit|image)$/;  # submits only
    my @found = $self->grep_inputs( $properties );

    return @found;
}

# Search an array of hashrefs, returning a list of the incoming
# hashrefs that match *all* the pattern in $patterns.
sub _grep_hashes {
    my $hashes = shift;
    my $patterns = shift || {};

    my @found;

    if ( ! %{$patterns} ) {
        # Nothing to match on, so return them all.
        @found = @{$hashes};
    }
    else {
        foreach my $hash ( @{$hashes} ) {

            # Check every pattern for a match on the current hash.
            my $matches_everything = 1;
            foreach my $pattern_key ( keys %{$patterns} ) {
                $matches_everything = 0 unless exists $hash->{$pattern_key} && $hash->{$pattern_key} =~ $patterns->{$pattern_key};
                last if !$matches_everything;
            }

            push @found, $hash if $matches_everything;
        }
    }

    return @found;
}


=head2 $mech->stuff_inputs( [\%options] )

Finds all free-text input fields (text, textarea, and password) in the
current form and fills them to their maximum length in hopes of finding
application code that can't handle it.  Fields with no maximum length
and all textarea fields are set to 66000 bytes, which will often be
enough to overflow the data's eventual receptacle.

There is no return value.

If there is no current form then nothing is done.

The hashref $options can contain the following keys:

=over

=item * ignore

hash value is arrayref of field names to not touch, e.g.:

    $mech->stuff_inputs( {
        ignore => [qw( specialfield1 specialfield2 )],
    } );

=item * fill

hash value is default string to use when stuffing fields.  Copies
of the string are repeated up to the max length of each field.  E.g.:

    $mech->stuff_inputs( {
        fill => '@'  # stuff all fields with something easy to recognize
    } );

=item * specs

hash value is arrayref of hashrefs with which you can pass detailed
instructions about how to stuff a given field.  E.g.:

    $mech->stuff_inputs( {
        specs=>{
            # Some fields are datatype-constrained.  It's most common to
            # want the field stuffed with valid data.
            widget_quantity => { fill=>'9' },
            notes => { maxlength=>2000 },
        }
    } );

The specs allowed are I<fill> (use this fill for the field rather than
the default) and I<maxlength> (use this as the field's maxlength instead
of any maxlength specified in the HTML).

=back

=cut

sub stuff_inputs {
    my $self = shift;

    my $options = shift || {};
    assert_isa( $options, 'HASH' );
    assert_in( $_, ['ignore', 'fill', 'specs'] ) foreach ( keys %{$options} );

    # Set up the fill we'll use unless a field overrides it.
    my $default_fill = '@';
    if ( defined $options->{fill} && length($options->{fill}) > 0 ) {
        $default_fill = $options->{fill};
    }

    # Fields in the form to not stuff
    my $ignore = {};
    if ( exists $options->{ignore} ) {
        assert_isa( $options->{ignore}, 'ARRAY' );
        $ignore = { map {($_, 1)} @{$options->{ignore}} };
    }

    my $specs = {};
    if ( exists $options->{specs} ) {
        assert_isa( $options->{specs}, 'HASH' );
        $specs = $options->{specs};
        foreach my $field_name ( keys %{$specs} ) {
            assert_isa( $specs->{$field_name}, 'HASH' );
            assert_in( $_, ['fill', 'maxlength'] ) foreach ( keys %{$specs->{$field_name}} );
        }
    }

    my @inputs = $self->find_all_inputs( type_regex => qr/^(text|textarea|password)$/ );

    foreach my $field ( @inputs ) {
        next if $field->readonly();
        next if $field->disabled();  # TODO: HTML::Form::TextInput allows setting disabled--allow it here?

        my $name = $field->name();

        # Skip if it's one of the fields to ignore.
        next if exists $ignore->{ $name };

        # Fields with no maxlength will get this many characters.
        my $maxlength = 66000;

        # maxlength from the HTML
        if ( $field->type ne 'textarea' ) {
            if ( exists $field->{maxlength} ) {
                $maxlength = $field->{maxlength};
                # TODO: what to do about maxlength==0 ?  non-numeric? less than 0 ?
            }
        }

        my $fill = $default_fill;

        if ( exists $specs->{$name} ) {
            # Process the per-field info.

            if ( exists $specs->{$name}->{fill} && defined $specs->{$name}->{fill} && length($specs->{$name}->{fill}) > 0 ) {
                $fill = $specs->{$name}->{fill};
            }

            # maxlength override from specs
            if ( exists $specs->{$name}->{maxlength} && defined $specs->{$name}->{maxlength} ) {
                $maxlength = $specs->{$name}->{maxlength};
                # TODO: what to do about maxlength==0 ?  non-numeric? less than 0?
            }
        }

        # stuff it
        if ( ($maxlength % length($fill)) == 0 ) {
            $field->value( $fill x ($maxlength/length($fill)) );
        }
        else {
            $field->value( substr( $fill x int(($maxlength + length($fill) - 1)/length($fill)), 0, $maxlength ) );
        }
    } # for @inputs

    return;
}


=head2 $mech->followable_links()

Returns a list of links that Mech can follow.  This is only http and
https links.

=cut

sub followable_links {
    my $self = shift;

    return $self->find_all_links( url_abs_regex => qr{^(?:https?|file)://} );
}


=head2 $mech->lacks_uncapped_inputs( [$comment] )

Executes a test to make sure that the current form content has no
text input fields that lack the C<maxlength> attribute, and that each
C<maxlength> value is a positive integer.  The test fails if the current
form has such a field, and succeeds otherwise.

Checks that all text input fields in the current form specify a maximum
input length.  Fields for which the concept of input length is irrelevant,
and controls that HTML does not allow to be capped (e.g. textarea)
are ignored.

The return is true if the test succeeded, false otherwise.

=cut

sub lacks_uncapped_inputs {
    my $self    = shift;
    my $comment = shift;

    $comment = 'All text inputs should have maxlength attributes' unless defined($comment);

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @uncapped;

    my @inputs = $self->grep_inputs( { type => qr/^(?:text|password)$/ } );
    foreach my $field ( @inputs ) {
        next if $field->readonly();
        next if $field->disabled();

        if ( not defined($field->{maxlength}) ) {
            push( @uncapped, $field->name . ' has no maxlength attribute' );
            next;
        }

        my $val = $field->{maxlength};
        if ( ($val !~ /^\s*\d+\s*$/) || ($val+0 <= 0) ) {
            push( @uncapped, $field->name . qq{ has an invalid maxlength attribute of "$val"} );
        }
    }

    my $ok = $TB->ok( @uncapped == 0, $comment );
    $TB->diag( $_ ) for @uncapped;

    return $ok;
}

=head2 $mech->check_all_images_ok( [%criterium ], [$comment] )

Executes a test to make sure all images in the page can be downloaded. It
does this by running C<HEAD> requests on them. The current page content stays the same.

The test fails if any image cannot be found, but reports all of the ones that were not found.

For a definition of I<all images>, see L<< C<images>in WWW::Mechanize|WWW::Mechanize/$mech->images >>.

The optional C<%criterium> argument can be passed in before the C<$comment> and will be used to define
which images should be considered. This is useful to filter out specific paths.

    $mech->check_all_images_ok( url_regex => qr{^/}, 'All absolute images should exist');
    $mech->check_all_images_ok( url_regex => qr{\.(?:gif|jpg)$}, 'All gif and jpg images should exist');
    $mech->check_all_images_ok(
        url_regex => qr{^((?!\Qhttps://googleads.g.doubleclick.net/\E).)*$},
        'All images should exist, but Ignore the ones from Doubleclick'
    );

For a full list of possible arguments see L<< C<find_all_images>in WWW::Mechanize|WWW::Mechanize/$mech->find_all_images >>.

The return is true if the test succeeded, false otherwise.

=cut

sub check_all_images_ok {
    my $self = shift;
    my @args = @_;

    my $comment;
    if ( @args % 2 ) {
        $comment = pop @args;
    }

    $comment = 'All images in the page should exist' unless defined($comment);

    require HTTP::Request::Common;

    my @not_ok;
    foreach my $img ( map { $_->URI } $self->find_all_images(@args) ) {
        my $abs = $img->abs;

        state $head_cache; # Cache images we've already checked between calls.
        if ( !$head_cache->{$abs}++ ) {
            # WWW::Mechanize->_make_request makes a raw LWP::UserAgent request that does
            # not show up in our history and does not mess with our current content.
            my $res = $self->_make_request( HTTP::Request::Common::HEAD($abs) );
            if ( not $res->is_success ) {
                push( @not_ok, $img . ' returned code ' . $res->code );
            }
        }
    }

    my $ok = $TB->ok( @not_ok == 0, $comment );
    $TB->diag($_) for @not_ok;

    return $ok;
}


sub _diag_url {
    my $self = shift;

    my $uri = $self->uri;

    return $uri ? $uri->as_string : 'Unable to determine URL';
}


=head1 TODO

Other ideas for features are at https://github.com/petdance/test-www-mechanize

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
<https://github.com/petdance/test-www-mechanize>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::WWW::Mechanize

You can also look for information at:

=over 4

=item * Bug tracker

L<https://github.com/petdance/test-www-mechanize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-WWW-Mechanize>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-WWW-Mechanize>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to
Julien Fiegehenn,
@marderh,
Eric A. Zarko,
@moznion,
Robert Stone,
@tynovsky,
Jerry Gay,
Jonathan "Duke" Leto,
Philip G. Potter,
Niko Tyni,
Greg Sheard,
Michael Schwern,
Mark Blackman,
Mike O'Regan,
Shawn Sorichetti,
Chris Dolan,
Matt Trout,
MATSUNO Tokuhiro,
and Pete Krawczyk for patches.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2022 Andy Lester.

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=cut

1; # End of Test::WWW::Mechanize
