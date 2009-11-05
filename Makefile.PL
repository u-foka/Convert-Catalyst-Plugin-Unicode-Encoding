use inc::Module::Install 0.91;

all_from 'lib/Catalyst/Plugin/Unicode/Encoding.pm';

requires 'Encode' => '2.21';
requires 'Catalyst' => '5.80';

test_requires 'Test::WWW::Mechanize::Catalyst' => 0.51;

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Unicode-Encoding/';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Unicode/Encoding.pm > README") and die;
}

auto_install;
WriteAll;

