use Test::Simple tests=>19;
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;
#use Smart::Comments '###';
$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";


my $r = new CGI::PathRequest({ rel_path => '/' });
ok($r);

my $abs_path = $r->abs_path;

ok($abs_path);
### $abs_path



ok(my $ls = $r->ls);
### $ls

ok(my $lsd = $r->lsd);
### $lsd

ok(my $lsf = $r->lsf);
### $lsd

ok($r->lsf_count == 3, 'lsf_count()');
ok($r->lsd_count, 'lsd_count()');
ok($r->ls_count, 'ls_count()');

ok(!$r->is_empty_dir);



### test empty dir -----------

mkdir './t/public_html/tmp';

ok( -d './t/public_html/tmp');

my $e = new CGI::PathRequest({ rel_path => '/tmp' });

ok($e->ls);
ok(ref $e->ls eq 'ARRAY');

ok(scalar @{$e->ls} == 0 );

ok($e->lsd);
ok($e->lsf);
ok($e->ls_count == 0, 'ls_count()');
ok($e->lsf_count == 0, 'lsf_count()');
ok($e->lsd_count == 0, 'lsd_count()');
ok($e->is_empty_dir);

