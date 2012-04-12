#!perl -T

use strict;
use warnings;
use Test::More;

if ( not eval 'use Test::Pod::Coverage 0.08;' ) {
    plan skip_all => 'Test::Pod::Coverage 0.08 required for testing POD coverage' if $@;
}

all_pod_coverage_ok();

done_testing();
