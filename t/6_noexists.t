use Test::Simple 'no_plan';
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;
use CGI;
#use Smart::Comments '###';

$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";





## WHAT IF THESE dont exist

for ( 'rel_path=/34fq44q', 'rel_path=/house.txt/', 'rel_path=he/ouse.txt', 'rel_path=demo/.../oake.jpg', 'rel_path=demo/seubdee/../hellokittygif' ) {
   my $rel_path =  $_;
   my $r = new CGI::PathRequest({ rel_path => $rel_path });
   $r ||= 0;
   ok(!$r);
     
}

