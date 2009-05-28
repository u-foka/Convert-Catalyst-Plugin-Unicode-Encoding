use inc::Module::Install 0.87;

all_from 'lib/Catalyst/Plugin/Unicode/Encoding.pm';

requires 'Encode' => 2.21;
requires 'Catalyst' => 5.80;

test_requires 'Test::WWW::Mechanize::Catalyst' => 0.51;

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Plugin-Unicode-Encoding/';

auto_install;
WriteAll;

