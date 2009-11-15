#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3 * 10;
use utf8;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN{
    $ENV{TESTAPP_PARAMS_NESTED} = 1;
}
use Catalyst::Test 'TestApp';
use Encode;
use HTTP::Request::Common;
use URI::Escape;

my $encode_str = "\x{e3}\x{81}\x{82}"; # e38182 is japanese 'あ'
my $decode_str = Encode::decode('utf-8' => $encode_str);
my $escape_str = uri_escape_utf8($decode_str);


{
    my $foo_data = $decode_str;
    check_parameter(GET("/?foo=$escape_str") => $foo_data);
    check_parameter(POST('/', ['foo' => $encode_str]) => $foo_data);
    check_parameter(
        POST('/',
            Content_Type => 'form-data',
            Content => [
                'foo' => [
                    "$Bin/06request_decode.t",
                    $encode_str,
                ]
            ],
        ) => $foo_data
    );
}

{ # Array
    my $foo_data = [$decode_str, $decode_str];
    check_parameter(GET("/?foo=$escape_str&foo=$escape_str") => $foo_data);
    check_parameter(POST('/', ['foo' => $encode_str, 'foo' => $encode_str]) => $foo_data);
    check_parameter(
        POST('/',
            Content_Type => 'form-data',
            Content => [
                'foo' => [
                    "$Bin/06request_decode.t",
                    $encode_str,
                ],
                'foo' => [
                    "$Bin/06request_decode.t",
                    $encode_str,
                ]
            ],
        ) => $foo_data
    );
}
{ # Array[2]
    my $foo_data = [$decode_str, undef, $decode_str];
    check_parameter(GET("/?foo[0]=$escape_str&foo[2]=$escape_str") => $foo_data);
    check_parameter(POST('/', ['foo[0]' => $encode_str, 'foo[2]' => $encode_str]) => $foo_data);
    # no support filename nested param now(C::P::Params::Nested version 0.02)
    #check_parameter(
    #    POST('/',
    #        Content_Type => 'form-data',
    #        Content => [
    #            'foo[0]' => [
    #                "$Bin/06request_decode.t",
    #                $encode_str,
    #            ],
    #            'foo[2]' => [
    #                "$Bin/06request_decode.t",
    #                $encode_str,
    #            ]
    #        ],
    #    ) => $foo_data
    #);
}

{ # Hash
    my $foo_data = {bar => $decode_str, baz => $decode_str};
    check_parameter(GET("/?foo[bar]=$escape_str&foo[baz]=$escape_str") => $foo_data);
    check_parameter(POST('/', ['foo[bar]' => $encode_str, 'foo[baz]' => $encode_str]) => $foo_data);
    # no support filename nested param now(C::P::Params::Nested version 0.02)
    #check_parameter(
    #    POST('/',
    #        Content_Type => 'form-data',
    #        Content => [
    #            'foo[bar]' => [
    #                "$Bin/06request_decode.t",
    #                $encode_str,
    #            ],
    #            'foo[baz]' => [
    #                "$Bin/06request_decode.t",
    #                $encode_str,
    #            ]
    #        ],
    #    ) => $foo_data
    #);
}


sub check_parameter {
    my ( $request, $foo_data ) = @_;
    my ( undef, $c ) = ctx_request($request);
    is $c->res->output => '<h1>It works</h1>';

    my $foo = get_foo($c);
    ok is_utf8_deeply($foo);
    is_deeply $foo => $foo_data;
}

sub is_utf8_deeply {
    my $data = shift;

    my $is_utf8 = 1;
    my $check_depply; $check_depply =sub {
        my $var = shift;
        my $ref = ref($var);
        if ($ref eq 'ARRAY') {
            $check_depply->($_) for @$var;
        }
        elsif ($ref eq 'HASH') {
            $check_depply->($_) for values %$var;
        }
        elsif ($ref eq 'SCALAR') {
            $check_depply->($$var);
        }
        elsif ($ref eq '') {
            return unless defined($_);
            $is_utf8 = 0 unless utf8::is_utf8($var);
        }
    };
    $check_depply->($data);

    return $is_utf8;
}

sub get_foo {
    my $c = shift;
    my $foo = [$c->req->param('foo')];
    if ( @$foo > 1 ) {
        return $foo;
    }
    else {
        return $foo->[0];
    }
}
