#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { $ENV{TESTAPP_ENCODING} = 'UTF-8' };

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
use_ok('TestApp') };

use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

{
    TestApp->encoding('UTF-8');
    $mech->get_ok('http://localhost/unicode', 'encoding configured ok');
}

