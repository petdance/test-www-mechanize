# Test-WWW-Mechanize

* Travis: [![Build Status](https://travis-ci.org/petdance/test-www-mechanize.svg?branch=dev)](https://travis-ci.org/petdance/test-www-mechanize)
* cpantesters.org:
[summary](http://www.cpantesters.org/distro/T/Test-WWW-Mechanize.html) and
[dev FAILs](http://www.cpantesters.org/distro/T/Test-WWW-Mechanize.html?grade=3&perlmat=2&patches=2&oncpan=2&distmat=3&perlver=ALL&osname=ALL&version=1.44)

----

Test::WWW::Mechanize is a subclass of the Perl module WWW::Mechanize
that incorporates features for web application testing.  For example:

    use Test::WWW::Mechanize;

    my $mech = Test::WWW::Mechanize->new;
    $mech->get_ok( $page );
    $mech->base_is( 'http://petdance.com/', 'Proper <BASE HREF>' );
    $mech->title_is( 'Invoice Status', "Make sure we're on the invoice page" );
    $mech->text_contains( 'Andy Lester', 'My name somewhere' );
    $mech->content_like( qr/(cpan|perl)\.org/, 'Link to perl.org or CPAN' );
    $mech->header_is( 'Cache-Control', 'private', 'Caching is turned off' );
    $mech->lacks_header_ok( 'X-Foo', 'Does not have the X-Foo header' );

This is equivalent to:

    use WWW::Mechanize;

    my $mech = WWW::Mechanize->new;
    $mech->get( $page );
    ok( $mech->success );
    is( $mech->base, 'http://petdance.com', 'Proper <BASE HREF>' );
    is( $mech->title, 'Invoice Status', "Make sure we're on the invoice page" );
    ok( index( $mech->content( format => 'text' ), 'Andy Lester' ) >= 0, 'My name somewhere' );
    like( $mech->content, qr/(cpan|perl)\.org/, 'Link to perl.org or CPAN' );
    is( $mech->response->header( 'Cache-Control' ), 'private', 'Caching is turned off' );
    ok( !defined $mech->response->header( 'X-Foo' ), 'Does not have the X-Foo header' );

but has nicer diagnostics if they fail.

# INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

# COPYRIGHT AND LICENSE

Copyright (C) 2004-2016 Andy Lester

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.
