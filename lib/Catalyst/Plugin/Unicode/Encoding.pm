package Catalyst::Plugin::Unicode::Encoding;

use strict;
use base 'Class::Data::Inheritable';

use Carp ();
use Encode 2.21 ();

use MRO::Compat;
our $VERSION = '0.3';
our $CHECK   = Encode::FB_CROAK | Encode::LEAVE_SRC;

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

    return $c->next::method(@_)
      unless $c->response->body;

    my $enc = $c->encoding;

    return $c->next::method(@_) 
      unless $enc;

    my ($ct,$ct_enc) = $c->response->content_type;

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

    $c->response->body( $c->encoding->encode( $c->response->body, $CHECK ) );

    $c->next::method(@_);
}

sub prepare_parameters {
    my $c = shift;

    $c->next::method(@_);

    my $enc = $c->encoding;

    for my $value ( values %{ $c->request->{parameters} } ) {

        # TODO: Hash support from the Params::Nested
        if ( ref $value && ref $value ne 'ARRAY' ) {
            next;
        }

        $_ = $enc->decode( $_, $CHECK ) for ( ref($value) ? @{$value} : $value );
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


=head1 DESCRIPTION

On request, decodes all params from encoding into a sequence of
logical characters. On response, encodes body into encoding.

=head1 METHODS

=over 4

=item encoding

Returns a instance of a C<Encode> encoding

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
