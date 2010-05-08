use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

all_from 'lib/Catalyst/Plugin/Unicode/Encoding.pm';

requires 'Encode' => '2.21';
requires 'Catalyst' => '5.80';
requires 'LWP' => '5.828'; # LWP had unicode fail in 5.8.26
requires 'URI' => '1.36';

author_requires 'Test::WWW::Mechanize::Catalyst' => 0.51;
test_requires 'Test::More' => '0.88';
test_requires 'IO::Scalar';

author_tests 't/author';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-Unicode-Encoding/';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/Plugin/Unicode/Encoding.pm > README") and die;
}

WriteAll;

