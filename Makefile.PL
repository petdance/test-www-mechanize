use strict;
use warnings;
use ExtUtils::MakeMaker;

my $parms = {
    NAME                => 'Test::WWW::Mechanize',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'Mechanize.pm',
    ABSTRACT_FROM       => 'Mechanize.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'parent'                    => 0,
        'Carp'                      => 0,
        'Carp::Assert::More'        => '1.16',
        'HTML::Form'                => 0,
        'HTTP::Server::Simple'      => '0.42',
        'HTTP::Server::Simple::CGI' => 0,
        'HTML::TokeParser'          => 0,
        'LWP'                       => 6.02,
        'Test::Builder::Tester'     => '1.09',
        'Test::LongString'          => '0.15',
        'Test::More'                => '0.96', # subtest() and done_testing()
        'URI::file'                 => 0,
        'WWW::Mechanize'            => '1.68',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-WWW-Mechanize-*' },
};

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
    $parms->{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms->{META_MERGE} = {
        resources => {
            license     => 'https://opensource.org/licenses/artistic-license-2.0',
            homepage    => 'https://github.com/petdance/test-www-mechanize',
            bugtracker  => 'https://github.com/petdance/test-www-mechanize/issues',
            repository  => 'git@github.com:petdance/test-www-mechanize.git',
        }
    };
}
if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
    $parms->{MIN_PERL_VERSION} = 5.008;
}

my $module = 'HTML::Lint 2.20';
if ( not eval "use $module; 1;" ) {
    print "You don't have $module installed, so cannot use autolinting.\n";
}

WriteMakefile( %{$parms} );


sub MY::postamble {
    return <<'MAKE_FRAG';
.PHONY: critic tags

critic:
	perlcritic -1 -q -profile perlcriticrc Mechanize.pm t/

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.svn \
		--exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

MAKE_FRAG
}
