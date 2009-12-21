use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;

all_from 'lib/Catalyst/Plugin/Unicode/Encoding.pm';

requires 'Encode' => '2.21';
requires 'Catalyst' => '5.80';
requires 'LWP' => '5.828'; # LWP had unicode fail in 5.8.26

author_requires 'Test::WWW::Mechanize::Catalyst' => 0.51;
test_requires 'Test::More' => '0.88';
test_requires 'IO::Scalar';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Unicode-Encoding/';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Unicode/Encoding.pm > README") and die;
}

auto_install;
WriteAll;

