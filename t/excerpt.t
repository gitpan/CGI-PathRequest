use Test::Simple tests=>3;
use strict;
use Cwd;
use lib './lib';
require CGI::PathRequest;
#use Smart::Comments '####';
$ENV{DOCUMENT_ROOT} = cwd()."/public_html";

ok( my $r = new CGI::PathRequest({ rel_path=> 'demo/civil.txt' }),'construct instance');
ok( my $content =  $r->get_content,'get content');
ok( my $excerpt = $r->get_excerpt,'get excerpt' );




