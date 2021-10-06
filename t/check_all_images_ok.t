#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Builder::Tester;
use URI::file ();

use Test::WWW::Mechanize ();

my $mech = Test::WWW::Mechanize->new( autocheck => 0 );
isa_ok( $mech, 'Test::WWW::Mechanize' );

GOOD_CHECK: {
    $mech->get_ok( URI::file->new_abs('t/img-good.html') );
    my $history_count = $mech->history_count;

    # we're going to count how often each image was checked
    my %head_request_counter;
    $mech->add_handler(
        request_prepare => sub {
            my ( $request, undef, undef ) = @_;
            ( my $img ) = $request->uri->as_string =~ m{/([^/]+)$};
            $head_request_counter{$img}++;
        },
        m_path_match => qr/200/
    );

    test_out('ok 1 - foo');
    my $ok = $mech->check_all_images_ok('foo');
    test_test('Finds all Images');
    is( $mech->history_count, $history_count,
        '... and the browser history is the same' );

    is( $head_request_counter{'200.gif'},
        1, 'Duplicate image was only checked once' );
    is( $head_request_counter{'200.gif?cachebuster=1'},
        1, '... and second image was checked' );
    is( keys %head_request_counter, 2, '... and no other images were checked' );

    # test optional arguments with comment
    $mech->get_ok( URI::file->new_abs('t/img-good-args.html') );

    test_out('ok 1 - two args and a comment');
    $ok = $mech->check_all_images_ok(
        url_regex => qr/cb=1/,
        class     => 'with-class',
        'two args and a comment'
    );
    test_test('Finds specific images with multiple arguments and comment');

    is( $head_request_counter{'200.gif?cb=1'}, 1,
        'Specific image was checked' );
    is( $head_request_counter{'200.gif'},
        1, '... and non-matching image was not checked' );
    is( keys %head_request_counter, 3, '... and no other images were checked' );

    # test optional arguments without comments
    # (this is the doubleclick example from the docs)
    test_out('ok 1 - All images in the page should exist');
    $ok = $mech->check_all_images_ok( url_regex => qr{^((?!cb=1).)*$}, );
    test_test('Finds specific images with one argument and no comment');

    is( $head_request_counter{'200.gif?cb=2'}, 1,
        'Specific image was checked' );
    is( $head_request_counter{'200.gif'},
        1, '... and already seen image was not checked' );
    is( $head_request_counter{'200.gif?cb=1'},
        1, '... and non-matching image was not checked' );
    is( keys %head_request_counter, 4, '... and no other images were checked' );
}

BAD_CHECK: {
    my $badimgs = URI::file->new_abs('t/img-bad.html')->as_string;

    $mech->get_ok($badimgs);

    test_out('not ok 1 - All images in the page should exist');
    test_fail(+2);
    test_diag('404.png returned code 404');
    my $ok = $mech->check_all_images_ok;
    test_test('Cannot find all Images');
}

done_testing();
