use Test::Simple 'no_plan';
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;
use CGI;
use Smart::Comments '###';

$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";


my $r = new CGI::PathRequest({ rel_path => '/house.txt' });
ok( my $hash = $r->get_datahash );
## $hash

ok( my $hashprepped = $r->get_datahash_prepped );

## $hashprepped

ok( my $content_encoded = $r->get_content_encoded );
## $content_encoded


ok(my $nav_prepped = $r->nav_prepped, 'nav_prepped');

## $nav_prepped;


## QUERY STRING

for ( 'rel_path=/', 'rel_path=/house.txt', 'rel_path=house.txt', 'rel_path=demo/../oake.jpg', 'rel_path=demo/subdee/../hellokitty.gif' ) {
   $ENV{QUERY_STRING} = $_;
   ### $ENV{QUERY_STRING}
   my $r = undef;
   $r = new CGI::PathRequest({ cgi=> new CGI($ENV{QUERY_STRING}) });
   
   ### testings for doc root 
   if ( $r->is_DOCUMENT_ROOT ){
      my $rel_path = $r->rel_path;
      $rel_path ||= 0;
      ok(!$rel_path,'was document root');
   }

   else {

  
      ok( my $rel_path = $r->rel_path, 'get rel_path() ' );
      ### $rel_path
      my $datahash_prepped = $r->get_datahash_prepped;
      ## $datahash_prepped
      ## done    
   } 

   ### done
   ### ------
} 


