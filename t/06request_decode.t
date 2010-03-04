#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6 * 3;
use utf8;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
use Encode;
use HTTP::Request::Common;
use URI::Escape qw/uri_escape_utf8/;

my $encode_str = "\x{e3}\x{81}\x{82}"; # e38182 is japanese 'あ'
my $decode_str = Encode::decode('utf-8' => $encode_str);
my $escape_str = uri_escape_utf8($decode_str);

check_parameter(GET "/?foo=$escape_str");
check_parameter(POST '/', ['foo' => $encode_str]);
check_parameter(POST '/',
    Content_Type => 'form-data',
    Content => [
        'foo' => [
            "$Bin/06request_decode.t",
            $encode_str,
        ]
    ],
);

check_argument(GET "/$escape_str");


sub check_parameter {
    my ( undef, $c ) = ctx_request(shift);
    is $c->res->output => '<h1>It works</h1>';

    my $foo = $c->req->param('foo');
    ok utf8::is_utf8($foo);
    is $foo => $decode_str;

    my $other_foo = $c->req->method eq 'POST'
        ? $c->req->upload('foo')
            ? $c->req->upload('foo')->filename
            : $c->req->body_parameters->{foo}
        : $c->req->query_parameters->{foo};
    ok utf8::is_utf8($other_foo);
    is $other_foo => $decode_str;
}

sub check_argument {
    my ( undef, $c ) = ctx_request(shift);
    is $c->res->output => '<h1>It works</h1>';

    my $foo = $c->req->args->[0];
    ok utf8::is_utf8($foo);
    is $foo => $decode_str;
}
