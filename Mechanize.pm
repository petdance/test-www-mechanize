package Test::WWW::Mechanize;

=head1 NAME

Test::WWW::Mechanize - Testing-specific WWW::Mechanize subclass

=head1 VERSION

Version 1.14

=cut

our $VERSION = '1.14';

=head1 SYNOPSIS

Test::WWW::Mechanize is a subclass of L<WWW::Mechanize> that incorporates
features for web application testing.  For example:

    use Test::More tests => 5;
    use Test::WWW::Mechanize;

    my $mech = Test::WWW::Mechanize->new;
    $mech->get_ok( $page );
    $mech->base_is( 'http://petdance.com/', 'Proper <BASE HREF>' );
    $mech->title_is( "Invoice Status", "Make sure we're on the invoice page" );
    $mech->content_contains( "Andy Lester", "My name somewhere" );
    $mech->content_like( qr/(cpan|perl)\.org/, "Link to perl.org or CPAN" );

This is equivalent to:

    use Test::More tests => 5;
    use WWW::Mechanize;

    my $mech = WWW::Mechanize->new;
    $mech->get( $page );
    ok( $mech->success );
    is( $mech->base, 'http://petdance.com', 'Proper <BASE HREF>' );
    is( $mech->title, "Invoice Status", "Make sure we're on the invoice page" );
    ok( index( $mech->content, "Andy Lester" ) >= 0, "My name somewhere" );
    like( $mech->content, qr/(cpan|perl)\.org/, "Link to perl.org or CPAN" );

but has nicer diagnostics if they fail.

=cut

use warnings;
use strict;

use WWW::Mechanize ();
use Test::LongString;
use Test::Builder ();
use Carp::Assert::More;

use base 'WWW::Mechanize';

my $Test = Test::Builder->new();


=head1 CONSTRUCTOR

=head2 new

Behaves like, and calls, L<WWW::Mechanize>'s C<new> method.  Any parms
passed in get passed to WWW::Mechanize's constructor.

=cut

sub new {
    my $class = shift;
    my %mech_args = @_;

    my $self = $class->SUPER::new( %mech_args );

    return $self;
}

=head1 METHODS

=head2 $mech->get_ok($url, [ \%LWP_options ,] $desc)

A wrapper around WWW::Mechanize's get(), with similar options, except
the second argument needs to be a hash reference, not a hash. Like
well-behaved C<*_ok()> functions, it returns true if the test passed,
or false if not.

=cut

sub get_ok {
    my $self = shift;
    my $url = shift;

    my $desc;
    my %opts;

    if ( @_ ) {
        my $flex = shift; # The flexible argument

        if ( !defined( $flex ) ) {
            $desc = shift;
        }
        elsif ( ref $flex eq 'HASH' ) {
            %opts = %$flex;
            $desc = shift;
        }
        elsif ( ref $flex eq 'ARRAY' ) {
            %opts = @$flex;
            $desc = shift;
        }
        else {
            $desc = $flex;
        }
    } # parms left

    $self->get( $url, %opts );
    my $ok = $self->success;

    $Test->ok( $ok, $desc );
    if ( !$ok ) {
        $Test->diag( $self->status );
        $Test->diag( $self->response->message ) if $self->response;
    }

    return $ok;
}

=head2 html_ok( [$msg] )

Checks the validity of the HTML on the current page.  If the page is not
HTML, then it fails.

The URI is automatically appended to the I<$msg>.

=cut

sub html_ok {
    my $self = shift;
    my $msg = shift;

    my $ok;

    if ( $self->is_html ) {
        require HTML::Lint;

        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $lint = HTML::Lint->new;
        $lint->parse_file( $self->uri );
        $lint->parse( $self->content );

        my @errors = $lint->errors;
        if ( @errors ) {
            $ok = $Test->ok( 0, $msg );
            $Test->diag( $_ ) for @errors;
        }
        else {
            $ok = $Test->ok( 1, $msg );
        }
    }
    else {
        $ok = $Test->ok( 0, $msg );
        diag( q{This page doesn't appear to be HTML, or didn't get the proper text/html content type returned.} );
    }

    return $ok;
}


=head2 $mech->title_is( $str [, $desc ] )

Tells if the title of the page is the given string.

    $mech->title_is( "Invoice Summary" );

=cut

sub title_is {
    my $self = shift;
    my $str = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_string( $self->title, $str, $desc );
}

=head2 $mech->title_like( $regex [, $desc ] )

Tells if the title of the page matches the given regex.

    $mech->title_like( qr/Invoices for (.+)/

=cut

sub title_like {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return like_string( $self->title, $regex, $desc );
}

=head2 $mech->title_unlike( $regex [, $desc ] )

Tells if the title of the page matches the given regex.

    $mech->title_unlike( qr/Invoices for (.+)/

=cut

sub title_unlike {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unlike_string( $self->title, $regex, $desc );
}

=head2 $mech->base_is( $str [, $desc ] )

Tells if the base of the page is the given string.

    $mech->base_is( "http://example.com/" );

=cut

sub base_is {
    my $self = shift;
    my $str = shift;
    my $desc = shift;

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
    return lacks_string( $self->content, $str, $desc );
}

=head2 $mech->content_like( $regex [, $desc ] )

Tells if the content of the page matches I<$regex>.

=cut

sub content_like {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return like_string( $self->content, $regex, $desc );
}

=head2 $mech->content_unlike( $regex [, $desc ] )

Tells if the content of the page does NOT match I<$regex>.

=cut

sub content_unlike {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return unlike_string( $self->content, $regex, $desc );
}

=head2 $mech->has_tag( $tag, $text [, $desc ] )

Tells if the page has a C<$tag> tag with the given content in its text.

=cut

sub has_tag {
    my $self = shift;
    my $tag  = shift;
    my $text = shift;
    my $desc = shift;

    my $found = $self->_tag_walk( $tag, sub { $text eq $_[0] } );

    return $Test->ok( $found, $desc );
}


=head2 $mech->has_tag_like( $tag, $regex [, $desc ] )

Tells if the page has a C<$tag> tag with the given content in its text.

=cut

sub has_tag_like {
    my $self = shift;
    my $tag  = shift;
    my $regex = shift;
    my $desc = shift;

    my $found = $self->_tag_walk( $tag, sub { $_[0] =~ $regex } );

    return $Test->ok( $found, $desc );
}


sub _tag_walk {
    my $self = shift;
    my $tag  = shift;
    my $match = shift;

    my $p = HTML::TokeParser->new( \($self->content) );

    while ( my $token = $p->get_tag( $tag ) ) {
        my $tagtext = $p->get_trimmed_text( "/$tag" );
        return 1 if $match->( $tagtext );
    }
    return;
}

=head2 $mech->followable_links()

Returns a list of links that Mech can follow.  This is only http and
https links.

=cut

sub followable_links {
    my $self = shift;

    return $self->find_all_links( url_abs_regex => qr[^https?://] );
}

=head2 $mech->page_links_ok( [ $desc ] )

Follow all links on the current page and test for HTTP status 200

    $mech->page_links_ok('Check all links');

=cut

sub page_links_ok {
    my $self = shift;
    my $desc = shift;

    my @links = $self->followable_links();
    my @urls = _format_links(\@links);

    my @failures = $self->_check_links_status( \@urls );
    my $ok = (@failures==0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->page_links_content_like( $regex,[ $desc ] )

Follow all links on the current page and test their contents for I<$regex>.

    $mech->page_links_content_like( qr/foo/,
      'Check all links contain "foo"' );

=cut

sub page_links_content_like {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;

    my $usable_regex=$Test->maybe_regex( $regex );
    unless(defined( $usable_regex )) {
        my $ok = $Test->ok( 0, 'page_links_content_like' );
        $Test->diag("     '$regex' doesn't look much like a regex to me.");
        return $ok;
    }

    my @links = $self->followable_links();
    my @urls = _format_links(\@links);

    my @failures = $self->_check_links_content( \@urls, $regex );
    my $ok = (@failures==0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

    return $ok;
}

=head2 $mech->page_links_content_unlike( $regex,[ $desc ] )

Follow all links on the current page and test their contents do not
contain the specified regex.

    $mech->page_links_content_unlike(qr/Restricted/,
      'Check all links do not contain Restricted');

=cut

sub page_links_content_unlike {
    my $self = shift;
    my $regex = shift;
    my $desc = shift;

    my $usable_regex=$Test->maybe_regex( $regex );
    unless(defined( $usable_regex )) {
        my $ok = $Test->ok( 0, 'page_links_content_unlike' );
        $Test->diag("     '$regex' doesn't look much like a regex to me.");
        return $ok;
    }

    my @links = $self->followable_links();
    my @urls = _format_links(\@links);

    my @failures = $self->_check_links_content( \@urls, $regex, 'unlike' );
    my $ok = (@failures==0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

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
    my @failures = $self->_check_links_status( \@urls );
    my $ok = (@failures == 0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

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
    my @failures = $self->_check_links_status( \@urls, $status );
    my $ok = (@failures == 0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

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
    my @failures = $self->_check_links_status( \@urls, $status, 'isnt' );
    my $ok = (@failures == 0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

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

    my $usable_regex=$Test->maybe_regex( $regex );
    unless(defined( $usable_regex )) {
        my $ok = $Test->ok( 0, 'link_content_like' );
        $Test->diag("     '$regex' doesn't look much like a regex to me.");
        return $ok;
    }

    my @urls = _format_links( $links );
    my @failures = $self->_check_links_content( \@urls, $regex );
    my $ok = (@failures == 0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

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

    my $usable_regex=$Test->maybe_regex( $regex );
    unless(defined( $usable_regex )) {
        my $ok = $Test->ok( 0, 'link_content_unlike' );
        $Test->diag("     '$regex' doesn't look much like a regex to me.");
        return $ok;
    }

    my @urls = _format_links( $links );
    my @failures = $self->_check_links_content( \@urls, $regex, 'unlike' );
    my $ok = (@failures == 0);

    $Test->ok( $ok, $desc );
    $Test->diag( $_ ) for @failures;

    return $ok;
}

# This actually performs the status check of each url.
sub _check_links_status {
    my $self = shift;
    my $urls = shift;
    my $status = shift || 200;
    my $test = shift || 'is';

    # Create a clone of the $mech used during the test as to not disrupt
    # the original.
    my $mech = $self->clone();

    my @failures;

    for my $url ( @$urls ) {
        if ( $mech->follow_link( url => $url ) ) {
            if ( $test eq 'is' ) {
                push( @failures, $url ) unless $mech->status() == $status;
            }
            else {
                push( @failures, $url ) unless $mech->status() != $status;
            }
            $mech->back();
        }
        else {
            push( @failures, $url );
        }
    } # for

    return @failures;
}

# This actually performs the content check of each url. 
sub _check_links_content {
    my $self = shift;
    my $urls = shift;
    my $regex = shift || qr/<html>/;
    my $test = shift || 'like';

    # Create a clone of the $mech used during the test as to not disrupt
    # the original.
    my $mech = $self->clone();

    my @failures;
    for my $url ( @$urls ) {
        if ( $mech->follow_link( url => $url ) ) {
            my $content=$mech->content();
            if ( $test eq 'like' ) {
                push( @failures, $url ) unless $content=~/$regex/;
            }
            else {
                push( @failures, $url ) unless $content!~/$regex/;
            }
            $mech->back();
        }
        else {
            push( @failures, $url );
        }
    } # for

    return @failures;
}

# Create an array of urls to match for mech to follow.
sub _format_links {
    my $links = shift;

    my @urls;
    if(ref($links) eq 'ARRAY') {
        if(defined($$links[0])) {
            if(ref($$links[0]) eq 'WWW::Mechanize::Link') {
                @urls=map { $_->url() } @$links;
            }
            else {
                @urls=@$links;
            }
        }
    }
    else {
        push(@urls,$links);
    }
    return @urls;
}

=head2 $mech->follow_link_ok( \%parms [, $comment] )

Makes a C<follow_link()> call and executes tests on the results.
The link must be found, and then followed successfully.  Otherwise,
this test fails.

I<%parms> is a hashref containing the parms to pass to C<follow_link()>.
Note that the parms to C<follow_link()> are a hash whereas the parms to
this function are a hashref.  You have to call this function like:

    $mech->follow_link_ok( {n=>3}, "looking for 3rd link" );

As with other test functions, C<$comment> is optional.  If it is supplied
then it will display when running the test harness in verbose mode.

Returns true value if the specified link was found and followed
successfully.  The HTTP::Response object returned by follow_link()
is not available.

=cut

sub follow_link_ok {
    my $self = shift;
    my $parms = shift || {};
    my $comment = shift;

    # return from follow_link() is an HTTP::Response or undef
    my $response = $self->follow_link( %$parms );

    my $ok;
    my $error;
    if ( !$response ) {
        $error = "No matching link found";
    }
    else {
        if ( !$response->is_success ) {
            $error = $response->as_string;
        }
        else {
            $ok = 1;
        }
    }

    $Test->ok( $ok, $comment );
    $Test->diag( $error ) if $error;

    return $ok;
}

=head2 $mech->stuff_inputs( [\%options] )

Finds all free-text input fields (text, textarea, and password) in the
current form and fills them to their maximum length in hopes of finding
application code that can't handle it.  Fields with no maximum length
and all textarea fields are set to 66000 bytes, which will often be
enough to overflow the data's eventual recepticle.

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
    assert_in( $_, ['ignore', 'fill', 'specs'] ) foreach ( keys %$options );

    # set up the fill we'll use unless a field overrides it
    my $default_fill = '@';
    if ( exists $options->{fill} && defined $options->{fill} && length($options->{fill}) > 0 ) {
        $default_fill = $options->{fill};
    }

    # fields in the form to not stuff
    my $ignore = {};
    if ( exists $options->{ignore} ) {
        assert_isa( $options->{ignore}, 'ARRAY' );
        $ignore = { map {($_, 1)} @{$options->{ignore}} };
    }

    my $specs = {};
    if ( exists $options->{specs} ) {
        assert_isa( $options->{specs}, 'HASH' );
        $specs = $options->{specs};
        foreach my $field_name ( keys %$specs ) {
            assert_isa( $specs->{$field_name}, 'HASH' );
            assert_in( $_, ['fill', 'maxlength'] ) foreach ( keys %{$specs->{$field_name}} );
        }
    }

    my @inputs = $self->find_all_inputs( type => qr/^(text|textarea|password)$/ );

    foreach my $field ( @inputs ) {
        next if $field->readonly();
        next if $field->disabled();  # TODO: HTML::Form::TextInput allows setting disabled--allow it here?

        my $name = $field->name();

        # skip if it's one of the fields to ignore
        next if exists $ignore->{ $name };

        # fields with no maxlength will get this many characters
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
            # process the per-field info

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
            # the simple case
            $field->value( $fill x ($maxlength/length($fill)) );
        }
        else {
            # can be improved later
            $field->value( substr( $fill x int(($maxlength + length($fill) - 1)/length($fill)), 0, $maxlength ) );
        }
    } # for @inputs

    return;
}

=head1 TODO

Add HTML::Lint and HTML::Tidy capabilities.

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-www-mechanize at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WWW-Mechanize>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::WWW::Mechanize

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-WWW-Mechanize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-WWW-Mechanize>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-WWW-Mechanize>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-WWW-Mechanize>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to
Michael Schwern,
Mark Blackman,
Mike O'Regan,
Shawn Sorichetti,
Chris Dolan,
Matt Trout,
MATSUNO Tokuhiro,
and Pete Krawczyk for patches.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2007 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::WWW::Mechanize
