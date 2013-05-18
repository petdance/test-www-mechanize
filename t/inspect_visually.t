#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Test::Builder::Tester;
use URI::file ();
use File::Temp;

use Test::WWW::Mechanize ();

## Set PATH so it'not tainted.
$ENV{PATH} = '/usr/bin/';


my $fake_output = File::Temp->new( SUFFIX => '.out' );
my $fake_output_fname = $fake_output->filename();
my $fake_browser = q|#!|.$^X.q| -T
## Good old Perl.
use strict;
use warnings;
my $fname = shift;
$fname =~ s/^file:\/\///;
open FILE , '<' , $fname;
binmode FILE;
$/ = undef;
my $content = <FILE>;
close FILE;
open OUT , '>' ,'|.$fake_output_fname.q|';
binmode OUT;
print OUT $content;
close OUT;
exit(0);
|;

my $fake_browser_ft = File::Temp->new(SUFFIX => '.pl');
my $fake_browser_filename = $fake_browser_ft->filename();
chmod 0700, $fake_browser_filename;
print $fake_browser_ft  $fake_browser;
close $fake_browser_ft;


my $mech = Test::WWW::Mechanize->new( autocheck => 0 , browser_command => $fake_browser_filename.' !!URL!!');
isa_ok($mech,'Test::WWW::Mechanize');

my $page = URI::file->new_abs( 't/goodlinks.html' )->as_string;

$mech->get_ok($page);

$mech->inspect_visually();

## Check our fake browser has output the right thing
my $content = do{ local $/ = undef; open FILE , '<' , $fake_output; my $content = <FILE>; close FILE; $content; };
is($content , $mech->content() , "Our fake browser did read and output the right file");

done_testing();
