#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN { $ENV{TESTAPP_ENCODING} = 'UTF-8' };

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
if ( !eval { require Test::WWW::Mechanize::Catalyst } ) {
    plan skip_all => 'Need Test::WWW::Mechanize::Catalyst for this test';
}
}

# make sure testapp works
use_ok('TestApp');

use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

{
    TestApp->encoding('UTF-8');
    $mech->get_ok('http://localhost/unicode', 'encoding configured ok');
}

done_testing;

