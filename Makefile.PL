use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::WWW::Mechanize',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'Mechanize.pm',
    ABSTRACT_FROM       => 'Mechanize.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp::Assert::More'    => 0,
        'HTTP::Server::Simple'  => '0.07',
        'Test::Builder::Tester' => '1.09',
        'Test::LongString'      => '0.07',
        'Test::More'            => 0,
        'URI::file'             => 0,
        'WWW::Mechanize'        => '1.24',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-WWW-Mechanize-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
.PHONY: critic tags

critic:
	perlcritic -1 -q -profile perlcriticrc bin/ lib/ t/

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.svn \
		--exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

MAKE_FRAG
}
