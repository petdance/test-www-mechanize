# Test-WWW-Mechanize

[![Build Status](https://travis-ci.org/petdance/test-www-mechanize.svg?branch=dev)](https://travis-ci.org/petdance/test-www-mechanize)

Test::WWW::Mechanize is a subclass of the Perl module WWW::Mechanize
that incorporates features for web application testing.  For example:

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
