#!/usr/bin/perl -w
use Test::Simple tests=>7;
use Cwd;
use strict;
use lib './lib';
require CGI::PathRequest;

$ENV{DOCUMENT_ROOT} = cwd()."/public_html";


ok( my $e = new CGI::PathRequest({ default=>'/', SERVER_NAME => 'mescaline'}), 'default to root');
ok( $e->rel_path eq '/' );
ok( $e->is_root );
ok( $e->is_dir );
ok( !$e->is_text );

print STDERR 
' www '.	$e->www ."\n".
' url '.	$e->url."\n".
' abs_loc '.	$e->abs_loc."\n";



ok( my $r = new CGI::PathRequest({ default=>'/demo', SERVER_NAME => 'mescaline'}), 'default to /demo');
ok($r->rel_path eq 'demo'); 


