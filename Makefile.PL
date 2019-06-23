use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME         => 'Bookmarker',
    AUTHOR       => q{Gene Boggs <gene@ology.net>},
    VERSION_FROM => 'lib/Bookmarker.pm',
    ABSTRACT     => 'YOUR APPLICATION ABSTRACT',
    ($eumm_version >= 6.3001 ? (LICENSE => 'perl') : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'DBD::SQLite' => 0,
        'DBI' => 0,
        'Dancer2' => 0.207000,
        'Dancer2::Plugin::Auth::Extensible' => 0,
        'Dancer2::Plugin::Auth::Extensible::Provider::Database' => 0,
        'Dancer2::Plugin::Database' => 0,
        'HTML::HeadParser' => 0;
        'HTTP::Simple' => 0,
        'LWP::UserAgent' => 0,
        'List::Util' => 0,
        'Test::More' => 0,
        'Try::Tiny' => 0,
        'YAML' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Bookmarker-*' },
);
