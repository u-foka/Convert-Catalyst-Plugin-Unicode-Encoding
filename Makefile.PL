use inc::Module::Install 0.81;

all_from 'lib/Catalyst/Plugin/Unicode/Encoding.pm';

requires 'Encode' => 2.21;
requires 'Catalyst' => 5.80;

test_requires 'Test::WWW::Mechanize::Catalyst' => 0.51;

WriteAll;
