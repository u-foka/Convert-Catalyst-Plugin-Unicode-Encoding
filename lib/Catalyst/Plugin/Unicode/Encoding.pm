package Catalyst::Plugin::Unicode::Encoding;

use strict;
use base 'Class::Data::Inheritable';

use Carp ();
use Encode 2.10 ();

our $VERSION = '0.1';
our $CHECK   = Encode::FB_CROAK | Encode::LEAVE_SRC;

__PACKAGE__->mk_classdata('_encoding');

sub encoding {
    my $c = shift;

    if ( ref($c) ) { # instance

        if ( my $wanted = shift(@_) ) {

            $c->{encoding} = Encode::find_encoding($wanted)
              or Carp::croak( qq/Unknown encoding '$wanted'/ );
        }

        if ( $c->{encoding} ) {
            return $c->{encoding};
        }
    }

    if ( my $wanted = shift(@_) ) {

        my $encoding = Encode::find_encoding($wanted)
          or Carp::croak( qq/Unknown encoding '$wanted'/ );

        $c->_encoding($encoding);
    }

    return $c->_encoding;
}

sub finalize {
    my $c = shift;

    unless ( $c->response->body ) {
        return $c->NEXT::finalize;
    }

    unless ( $c->response->content_type =~ /^text|xml$|javascript$/ ) {
        return $c->NEXT::finalize;
    }

    unless ( Encode::is_utf8( $c->response->body ) ) {
        return $c->NEXT::finalize;
    }

    $c->response->body( $c->encoding->encode( $c->response->body, $CHECK ) );

    $c->NEXT::finalize;
}

sub prepare_parameters {
    my $c = shift;

    $c->NEXT::prepare_parameters;

    for my $value ( values %{ $c->request->{parameters} } ) {

        if ( ref $value && ref $value ne 'ARRAY' ) {
            next;
        }

        $_ = $c->encoding->decode( $_, $CHECK ) for ( ref($value) ? @{$value} : $value );
    }
}

sub setup {
    my $self = shift;

    $self->encoding( $self->config->{encoding} || 'UTF-8' );

    return $self->NEXT::setup(@_);
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
