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
        'Carp::Assert::More'        => 0,
        'HTTP::Server::Simple'      => '0.42',
        'HTTP::Server::Simple::CGI' => 0,
        'Test::Builder::Tester'     => '1.09',
        'Test::LongString'          => '0.12',
        'Test::More'                => 0,
        'URI::file'                 => 0,
        'WWW::Mechanize'            => '1.24',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-WWW-Mechanize-*' },
};

if ( $ExtUtils::MakeMaker::VERSION ge '6.45_01' ) {
    $parms->{META_MERGE} = {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://code.google.com/p/www-mechanize/',
            bugtracker  => 'http://code.google.com/p/www-mechanize/issues/list',
            Repository  => 'http://code.google.com/p/www-mechanize/source',
            MailingList => 'http://groups.google.com/group/www-mechanize-users',
        }
    };
    $parms->{LICENSE} = 'perl';
}
if ( $ExtUtils::MakeMaker::VERSION ge '6.47_02' ) {
    $parms->{MIN_PERL_VERSION} = 5.008;
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
