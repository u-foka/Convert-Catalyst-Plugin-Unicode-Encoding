package Catalyst::Plugin::Unicode::Encoding;

use strict;
use base 'Class::Data::Inheritable';

use utf8;
use Carp ();
use Encode 2.21 ();
use Encode::Guess;

use MRO::Compat;
our $VERSION = '0.3';
our $CHECK   = Encode::FB_DEFAULT;

__PACKAGE__->mk_classdata('_encoding');

sub encoding {
    my $c = shift;
    my $encoding;

    if ( scalar @_ ) {
        # Let it be set to undef
        if (my $wanted = shift)  {
            $encoding = Encode::find_encoding($wanted)
              or Carp::croak( qq/Unknown encoding '$wanted'/ );
        }

        $encoding = ref $c 
                  ? $c->{encoding} = $encoding
                  : $c->_encoding($encoding);
    } else {
      $encoding = ref $c && exists $c->{encoding} 
                ? $c->{encoding} 
                : $c->_encoding;
    }

    return $encoding;
}

sub finalize {
    my $c = shift;

    my $body = $c->response->body;

    return $c->next::method(@_)
      unless defined($body);

    my $enc = $c->encoding;

    return $c->next::method(@_) 
      unless $enc;

    my ($ct, $ct_enc) = $c->response->content_type;

    # Only touch 'text-like' contents
    return $c->next::method(@_)
      unless $c->response->content_type =~ /^text|xml$|javascript$/;

    if ($ct_enc && $ct_enc =~ /charset=(.*?)$/) {
        if (uc($1) ne $enc->mime_name) {
            $c->log->debug("Unicode::Encoding is set to encode in '" .
                           $enc->mime_name .
                           "', content type is '$1', not encoding ");
            return $c->next::method(@_);
        }
    } else {
        $c->res->content_type($c->res->content_type . "; charset=" . $enc->mime_name);
    }

    # Encode expects plain scalars (IV, NV or PV) and segfaults on ref's
    $c->response->body( $c->encoding->encode( $body, $CHECK ) )
        if ref(\$body) eq 'SCALAR';

    $c->next::method(@_);
}

sub prepare_parameters {
    my $c = shift;

    $c->next::method(@_);

    my $enc = $c->encoding;

    my @possible_incoming_charsets;

    if (my $charsets = $c->config->{ incoming_charset }) {
        @possible_incoming_charsets
             = map { split /\s+/, $_ }
               ref $charsets ? @{ $charsets } : ( $charsets );
    }

    # If we have a list of possible charsets to search through, use them.  If
    # not, assume all input has to be valid based on $c->encoding.  Bad chars
    # will be replaced with empty chars. (see our $CHECK above.)
    my $found_encoding = @possible_incoming_charsets ? undef : $enc;

    PASSED_PARAMETER:
    foreach my $parameter ( keys %{ $c->request->{ parameters } } ) {
        my $value = $c->request->param( $parameter );

        # TODO: Hash support from the Params::Nested
        if ( ref $value && ref $value ne 'ARRAY' ) {
            next PASSED_PARAMETER;
        }

        PARAMETER_VALUE:
        for $value ( ref($value) ? @{ $value } : $value ) {
            # If it doesn't have a high byte character, decoding is going to
            # work regardless of what encoding we think it might be.
            my $has_highbyte_char = grep { $_ > 127  }
                                     map { ord( $_ ) }
                                   split //, $value;

            if (!$has_highbyte_char) {
                next PARAMETER_VALUE;
            }

            if ( !defined $found_encoding ) {
                eval { $enc->decode( $value, Encode::FB_CROAK ) };

                if ($@) {
                    $c->log->info(
                        'Params were not sent in '
                      . $c->encoding->name . '. '
                      . 'Attempting to guess.'
                    );

                    $found_encoding = guess_encoding(
                        $value, @possible_incoming_charsets
                    );

                    if (!ref $found_encoding) {
                        $found_encoding = $enc;

                        $c->log->warn(
                            'Failed finding encoding on input -- will put a '
                          . 'substitution character on failed conversions'
                        );
                    }
                }
                else {
                    $found_encoding = $enc;
                }
            }

            $value = $found_encoding->decode( $value, $CHECK );
        }
    }
}

sub setup {
    my $self = shift;

    my $conf = $self->config;

    # Allow an explict undef encoding to disable default of utf-8
    my $enc = exists $conf->{encoding} ? delete $conf->{encoding} : 'UTF-8';
    $self->encoding( $enc );

    return $self->next::method(@_);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Unicode::Encoding - Unicode aware Catalyst

=head1 SYNOPSIS

    use Catalyst qw[Unicode::Encoding];

    MyApp->config( encoding => 'UTF-8' ); # A valid Encode encoding
    MyApp->config( incoming_charset => [qw( big5 iso8859-1 )]);


=head1 DESCRIPTION

On request, decodes all params from encoding into a sequence of
logical characters. On response, encodes body into encoding.

=head1 CONFIGURATION

=over 2

=item incoming_charset

You may set your Catalyst application with one or more incoming_charset values
in your configuration. This module will attempt to decode incoming request
parameters to these type(s).

    MyApp->config( incoming_charset => [qw( big5 )] );

This is especially prudent when your website has a form submitted to from
another website that may have different encoding than yours.  Because browsers
don't generally send their charset type with their request, it's up to you to
have some idea what charsets they might be in.

Be careful using any iso8859 charset, as it's likely to match just about
everything as a series of 8 bit characters.

If a match isn't successfully found, this module will silently replace invalid
characters in accordance with C<Encode>'s FB_DEFAULT method.

If this isn't what you want or expect, set C<$Catalyst::Plugin::Unicode::Encoding::CHECK>
to the relevant FB_ or other relevant constant from the C<Encode> module.

=item encoding

Set your Catalyst application's default encoding.

=back

=head1 METHODS

=over 4

=item encoding

Returns an instance of an C<Encode> encoding

    print $c->encoding->name

=back

=head1 OVERLOADED METHODS

=over 4

=item finalize

Encodes body into encoding.

=item prepare_parameters

Decodes parameters into a sequence of logical characters.

=item setup

Setups C<< $c->encoding >> with encoding specified in C<< $c->config->{encoding} >>.

=back

=head1 SEE ALSO

L<Encode>, L<Encode::Encoding>, L<Catalyst::Plugin::Unicode>, L<Catalyst>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut
