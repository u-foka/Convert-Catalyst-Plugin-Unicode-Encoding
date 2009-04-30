#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 21;
use utf8;
use IO::Scalar;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN { use_ok('TestApp') or BAIL_OUT($@) };

our $TEST_FILE = IO::Scalar->new(\"this is a test");
sub IO::Scalar::FILENO { -1 }; # needed?

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is ($mech->response->header('Content-Type'), 'text/html; charset=UTF-8',
    'Content-Type with charset'
);

my $hoge_utf8 = "ほげ";
{
    $mech->get_ok('http://localhost/unicode_no_enc', 'get unicode_no_enc');
    
    my $octets = Encode::encode_utf8($hoge_utf8); 
    my $content = $mech->content;

    is ($mech->response->header('Content-Type'), 'text/plain',
        'Content-Type with no charset');

    # This was an is_utf8 check before, but WWW::Mech does a few silly things.
    is($content, $octets, "not utf8");
    # Just to double check that no autopromotion is going on
    isnt($content, $hoge_utf8, "Bytes != string");
    utf8::decode($content);

    is( $content, $hoge_utf8, 'content contains hoge');
}

{
    $mech->get_ok('http://localhost/unicode', 'get unicode');
    
    is ($mech->response->header('Content-Type'), 'text/plain; charset=UTF-8',
        'Content-Type with charset');

    is( $mech->content, $hoge_utf8, 'content contains hoge');
}

{
    $mech->get_ok('http://localhost/not_unicode', 'get bytes');
    my $content = $mech->content; 
    my $chars = "\x{1234}\x{5678}";
    isnt($content, $chars);
    utf8::encode($chars);
    like $content, qr/$chars/, 'got 1234 5678';
}

{
    $mech->get_ok('http://localhost/file', 'get file');
    $mech->content_like(qr/this is a test/, 'got filehandle contents');
}

{
    # The latin 1 case is the one everyone forgets. I want to really make sure
    # its right, so lets check the damn bytes.
    $mech->get_ok('http://localhost/latin1', 'get latin1');
    is ($mech->response->header('Content-Type'), 'text/plain; charset=UTF-8',
        'Content-Type with charset');

    # Encode the utf8 string into bytes
    my $bytes = Encode::encode_utf8($mech->content);

    is ($bytes, "LATIN SMALL LETTER E WITH ACUTE: \x{C3}\x{A9}", 
        'content bytes are utf8'
    );
    is ($mech->content, "LATIN SMALL LETTER E WITH ACUTE: \x{E9}", 
        'content string matches from latin1'
    );
}

