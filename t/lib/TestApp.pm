package TestApp;
use strict;
use warnings;

use Catalyst qw/Unicode::Encoding/;

__PACKAGE__->config(
  encoding => $ENV{TESTAPP_ENCODING}
) if $ENV{TESTAPP_ENCODING};

__PACKAGE__->setup;

1;
