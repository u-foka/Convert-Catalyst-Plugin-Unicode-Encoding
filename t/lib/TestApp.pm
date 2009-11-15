package TestApp;
use strict;
use warnings;
use base qw/Catalyst/;

use Catalyst;

__PACKAGE__->config(
  encoding => $ENV{TESTAPP_ENCODING}
) if $ENV{TESTAPP_ENCODING};

__PACKAGE__->config('name' => 'TestApp');

my @plugins = qw/Unicode::Encoding/;
push @plugins, 'Params::Nested' if $ENV{TESTAPP_PARAMS_NESTED};
__PACKAGE__->setup(@plugins);

1;
