# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile
# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'parent'             => 0;
requires 'Carp'               => 0;
requires 'Carp::Assert::More' => '1.16';
requires 'HTML::TokeParser'   => 0;
requires 'LWP'                => '6.02';
requires 'WWW::Mechanize'     => '1.68';

on 'test' => sub {
    requires 'HTML::Form'                => 0;
    requires 'HTTP::Server::Simple'      => '0.42';
    requires 'HTTP::Server::Simple::CGI' => 0;
    requires 'Test::Builder::Tester'     => '1.09';
    requires 'Test::LongString'          => '0.15';
    requires 'Test::More'                => '0.96'; # subtest() and done_testing()
    requires 'URI::file'                 => 0;
};

# vi:et:sw=4 ts=4 ft=perl
