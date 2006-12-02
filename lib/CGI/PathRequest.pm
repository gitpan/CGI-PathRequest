package CGI::PathRequest;
use CGI;
use Cwd;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)/g;
use File::Type;

use Time::Format qw(%time);
#use Smart::Comments '####';
use Carp;




sub new {
	my ($class, $self) = (shift, shift);
		
	$self								||= {};	

	$self->{ DOCUMENT_ROOT }	||= $ENV{DOCUMENT_ROOT};	
	defined $self->{DOCUMENT_ROOT} or croak('ENV DOCUMENT_ROOT not defined');	
	$self->{DOCUMENT_ROOT}=~s/\/+$//;

	$self->{ param_name }		||= 'rel_path';
	
	$self->{default}			||= undef; # what is the default	
	#print STDERR "default: [".$self->{default}."]\n";
#	$self->{default_on_fail}||= 0; # switch to the default on fail?
	
	if ($self->{tainted_request}){ $self->{rel_path} = $self->{tainted_request}; warn 'warning: argument tainted_path to CGI::PathRequest is deprecated.'; }
	$self->{ rel_path }			||= undef;	
	$self->{ excerpt_size }		||= 255; # chars if excerpt is called for	
	$self->{ time_format }		||= 'yyyy/mm/dd';
	bless $self, $class;


	# internals

	$self->{ status }						= [];
	$self->{ data }						= undef;
	$self->{ request_method }  = undef; # what kind of request was made? via argument or from cgi
	$self->{ request_made }				= 0; # was a request received
	$self->{ defaulted }					= 0;
	$self->{ errors }						= undef;

	# start
	$self->_establish_rel_path  # croaks on fail - should just return undef.. ?
		or  croak ('request method:'.$self->{request_method}.' cant extablish rel path ');

	
	$self->exists or return;
	#or return $self;

	$self->_feed_data or croak('cant _feed_data');
	
	$self->_feed_url_data;	
 
		
	return $self;
}

sub server_name {
	my $self = shift;
	if (defined $self->{SERVER_NAME}){
		return $self->{SERVER_NAME};		
	}

	if (defined $ENV{SERVER_NAME}){
		$self->{SERVER_NAME} = $ENV{SERVER_NAME};		
	}

	else {
		my $cgi = $self->get_cgi;
		$self->{SERVER_NAME} = $cgi->server_name;
		$self->{SERVER_NAME} or $self->{SERVER_NAME} = undef;
	}
	
	return $self->{SERVER_NAME};		
}



sub get_cgi {
	my $self = shift;
	$self->{ cgi }	||= new CGI;	
	return $self->{cgi};	
}

# run once!
sub _establish_rel_path {
	my $self = shift;
	
	if (defined $self->{rel_path}){
		$self->{request_method} = 'constructor argument';	
		return 1;
	}	
	
	elsif ( my $fromcgi = $self->_get_rel_path_from_cgi ){
		$self->{rel_path} = $fromcgi;
		$self->{request_method} = 'from cgi';
		return 1;
	}
	


	
	if (defined $self->{default}){
		$self->{rel_path} = $self->{default};
		$self->{request_method} = 'default';	
		return 1;
	}

	$self->{request_method} = 'none';
	#print STDERR $self->{default}."\n";
	#print STDERR $self->{rel_path}."\n";
	return ;
#	croak( ' - cant establish_rel_path method:'.$self->{request_method}.'- ');
	
}







sub exists {
	my $self = shift;
	if (defined $self->{data}->{exists}){
		return $self->{data}->{exists};
	}	
	( -e $self->{DOCUMENT_ROOT}.'/'.$self->{rel_path} ) ? 
		($self->{data}->{exists} = 1) :
			($self->{data}->{exists} = 0);		
	return $self->{data}->{exists};
}




sub error {
	my $self = shift;
	my $error = shift;
	push @{$self->{errors}}, $error;
	return 1;
}



sub errors {
	my $self = shift;
	defined $self->{errors} or return;
	scalar @{$self->{errors}} or return;
	return @{$self->{errors}};
}




sub _get_rel_path_from_cgi {
	my $self = shift;
	my $cgi = $self->get_cgi;

	defined $cgi->param($self->{param_name}) or return;

	my $req = $cgi->param($self->{param_name});	
	$req or return;
	
	my $wasfullurl = 0;

	if ($req=~s/^https\:\/\/|^http\:\/\///){
		$wasfullurl++;  
	}
	if ($req=~s/^www\.//){
		$wasfullurl++;
	}
	
	if (my $server = $self->server_name){
		$req=~s/^$server//;
	}
	
	if ($wasfullurl and !$req){
		return '/';	
	}
	
	$req or return;
	
	return $req;	
}






# test existancem, type, etc
# will attempt to default IF DOES NOT EXIST
sub _feed_data {
	my $self = shift;

	
	my $data = {
	
		abs_path		=> undef,
		rel_path		=> undef,
		
		abs_loc => undef,
		rel_loc	=> undef,
		
		filename				=> undef,
		filename_pretty	=> undef,
		filetype				=> undef, # f d
		is_root				=> undef,
		url					=> undef,
		www					=> undef,
		ext 					=> undef,

		excerpt 			=> undef,
		content 			=> undef,

		alt				=> undef,

	};


#	 -e $opt->{DOCUMENT_ROOT}.'/'.$opt->{rel_path} or return;
	
	$data->{abs_path} = Cwd::abs_path($self->{DOCUMENT_ROOT}.'/'.$self->{rel_path})
		or warn ("from CGI/PathRequest.pm get_data() -  Cwd not returning value for rel_path=[" 
		.$self->{rel_path}."] docroot=["
			.$self->{DOCUMENT_ROOT}."] - likely that file does not exist" ) and 
				croak('Cwd returns nothing');
	
	
	## $data
	
		
	defined $data->{abs_path} or croak('abs_path undef 228');


	# TODO: presently not doing anything for other file types, pipes, etc
	
	#-d $data->{abs_path} ? $data->{filetype}='d' :	
#		( -f $data->{abs_path} ? $data->{filetype}='f' : $data->{abs_path}=undef );


	if (-d $data->{abs_path}){
		$data->{filetype}='d';
		$data->{is_dir}=1;
		$data->{is_file}=0;
		
	}
	elsif (-f $data->{abs_path}){
		$data->{filetype}='f';	
		$data->{is_file}=1;
		$data->{is_dir}=0;		
	}
	else {
		warn "filetype for $$data{abs_path} is not d or f, unsupported.";
		return;
	}

	$data->{ rel_path } = $data->{abs_path};	
	unless ($data->{ rel_path } =~s/^$$self{DOCUMENT_ROOT}//){	
		croak("cant regex $$self{DOCUMENT_ROOT} inside $$data{rel_path}");
	} 
	$data->{ rel_path } =~s/^\/+//;
	$data->{ rel_path } ||= '/';

	if ($$self{DOCUMENT_ROOT}=~/^$$data{abs_path}\/*$/){
		### PathRequest.pm is root 
		$data->{ filename } = '/';	
		$data->{ rel_loc } = '/';
		$data->{ rel_path } = '/';
		$data->{ abs_path } = $$self{DOCUMENT_ROOT}.'/';		
		$data->{ abs_loc } = $$self{DOCUMENT_ROOT}.'/';
		$data->{ is_root }=1;
	} 

	else {
		### PathRequest.pm is not root

		$data->{ abs_loc } = $data->{abs_path};
		$data->{ abs_loc } =~s/([^\/]+)$// or return undef;
		$data->{ filename } = $1;		
		$data->{ abs_loc } =~s/\/+$//;
		
		$data->{ is_root }=0;
		
	
		$data->{ rel_loc } = $data->{ abs_loc };
		$data->{ rel_loc } =~s/^$$self{DOCUMENT_ROOT}// or return undef;
		$data->{ rel_loc }=~s/^\/+|\/+$//g;		
		$data->{ rel_loc } ||= '/';
	}


	if ($data->{ abs_loc } eq $$self{DOCUMENT_ROOT}){
		$data->{ abs_loc } = $data->{ abs_loc }.'/';
	}

	unless($data->{is_root}) {	
		if ($data->{filename}=~/.+\.(\w{3,5})$/){		
			$data->{ext}=$1;		
		}	
	
		$data->{filename_pretty}= $data->{filename};
		$data->{filename_pretty}=~s/\.(\w{3,5})$//i;	
		$data->{filename_pretty}=~s/_/ /sg;	

		$data->{filename_pretty} = join '', map {ucfirst lc} split (/(?=\s)/, $data->{filename_pretty}); # http://perlmonks.org/?node_id=471292

		$data->{alt} = $data->{filename_pretty};

	
	}	
	
	for (keys %{$data}){
		$self->{data}->{$_} = $data->{$_};
	}
	return 1;
}






sub _feed_url_data {
	my $self = shift;	

	$self->server_name or return;	
	
	my $cgi = $self->get_cgi;

	my $url_data = {};

	if ($cgi->https()){
		$url_data->{www} = 'https://'.$self->server_name;
	}
	else {
		$url_data->{www} = 'http://'.$self->server_name;		
	}
	
	$url_data->{url} = $self->rel_path;
	$url_data->{url}=~s/^\/+//;
	$url_data->{url}= $url_data->{www}.'/'.$url_data->{url};	
	$url_data->{url}=~s/\/{3,}/\/\//;	

	for (keys %{$url_data}){
		$self->{data}->{$_} = $url_data->{$_};
	}
	return 1;
}







# TODO: work this

sub _feed_extended_data {
	my $self = shift;
	
	
 	my $ft = File::Type->new;	
	my $mime_type = $ft->mime_type($self->abs_path);

	my $extended_data = {		
   	is_image			=> ( $self->is_file ? ($mime_type=~m/image/ or 0) : 0 ),	
		is_binary		=> ( -B $self->abs_path() or 0 ),
		is_text			=> ( -T $self->abs_path() or 0 ),
		mime_type		=> $mime_type,
	};

	for ( keys %{$extended_data}){
		$self->{data}->{$_} = $extended_data->{$_}; 
	}	
	return 1;
}


sub _feed_stat_data {
	my $self = shift;
	
	my $stat_data = {};

	my @stat =  stat $self->abs_path or croak("$! - cant stat ".$self->abs_path);
	my @keys = qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);
	for (@stat) {
	 	my $v= $_;
	 	my $key = shift @keys;		
		$stat_data->{$key} = $v;		
	}
	
### $st	

	# prettyfy!!!  :-) 

	$stat_data->{ filesize_pretty }	= ( sprintf "%d",($stat_data->{size} / 1024 )).'k';
	$stat_data->{ ctime_pretty }		= $time{$self->{time_format},$stat_data->{ctime}};
	$stat_data->{ atime_pretty }		= $time{$self->{time_format},$stat_data->{atime}};
	$stat_data->{ mtime_pretty }		= $time{$self->{time_format},$stat_data->{mtime}};
	$stat_data->{ filesize }		= $stat_data->{size};

	for ( keys %{$stat_data} ){
		$self->{data}->{$_} = $stat_data->{$_}; 
	}
	
	return 1;
}

















sub elements {
	my $self = shift;
	my @elements = sort keys %{$self->{data}};
	return @elements;
}

# extended data 


# stat, these have to be loaded

sub filesize {	
	my $self = shift;
	exists $self->{data}->{filesize} or $self->_feed_stat_data;
	defined $self->{data}->{filesize} or return;
	return $self->{data}->{filesize};
}

sub filesize_pretty  { my $self = shift;
 exists $self->{data}->{filesize_pretty} or $self->_feed_stat_data;
 defined $self->{data}->{filesize_pretty} or return; 
 return $self->{data}->{filesize_pretty};
}

sub ctime  { my $self = shift;
 defined $self->{data}->{ctime} or $self->_feed_stat_data;
 return $self->{data}->{ctime};
}

sub ctime_pretty  { my $self = shift;
 defined $self->{data}->{ctime_pretty} or $self->_feed_stat_data;
 return $self->{data}->{ctime_pretty};
}

sub atime  { my $self = shift;
 defined $self->{data}->{atime} or $self->_feed_stat_data;
 return $self->{data}->{atime};
}

sub atime_pretty  { my $self = shift;
 defined $self->{data}->{atime_pretty} or $self->_feed_stat_data;
 return $self->{data}->{atime_pretty};
}

sub mtime  { my $self = shift;
 defined $self->{data}->{mtime} or $self->_feed_stat_data;
 return $self->{data}->{mtime};
}

sub mtime_pretty  { my $self = shift;
 defined $self->{data}->{mtime_pretty} or $self->_feed_stat_data;
 return $self->{data}->{mtime_pretty};
}








# these have to be loaded
sub is_image  { 
 my $self = shift;
 defined $self->{data}->{is_image} or $self->_feed_extended_data;
 return $self->{data}->{is_image};
}

sub is_binary  {
 my $self = shift;
 defined $self->{data}->{is_binary} or $self->_feed_extended_data;
 return $self->{data}->{is_binary};
}

sub is_text  { 
 my $self = shift;
 defined $self->{data}->{is_text} or $self->_feed_extended_data;
 return $self->{data}->{is_text};
}

sub mime_type  { my $self = shift;
 exists $self->{data}->{mime_type} or $self->_feed_extended_data;
 return $self->{data}->{mime_type};
}








# has to be loaded 
sub get_content {
	my $self= shift;
	
	return $self->{data}->{content} if defined $self->{data}->{content};


	my $slurp;
	{
		local (*INPUT, $/);
		open (INPUT, $self->abs_path);
		$slurp = <INPUT>;
		close INPUT;
	}
	$self->{data}->{content} = $slurp;
	$self->{data}->{content} ||= undef;		
	return $self->{data}->{content};
}

# has to be loaded 
sub get_excerpt { 
	my $self = shift;
	my $opts = shift;
	$opts ||={};
	$opts->{excerpt_size} ||= $self->{excerpt_size};
	my $limit = $opts->{excerpt_size};
	$limit||=255;

	unless( defined $self->{data}->{excerpt} ){
	
		my $content = $self->get_content;
		defined $content or return;

		# take out possible html
		$content=~s/\<[^<>]+\>/ /sg;
		if ($content=~/^(.{1,$limit})/s){
			$self->{data}->{excerpt} = $1."... ";
		}
	}		
	return $self->{data}->{excerpt};
}


sub _debug { my $arg = shift; print STDERR "PathRequest. $arg \n";  }


# have to be loaded

sub url { my $self = shift; exists $self->{data}->{url} or $self->_feed_url_data; return $self->{data}->{url}; }
sub www { my $self = shift; exists $self->{data}->{www} or $self->_feed_url_data; return $self->{data}->{www}; }





# automatically loaded on instantiation

sub filename { my $self = shift;	return $self->{data}->{filename}; }
sub filename_pretty { my $self = shift; return $self->{data}->{filename_pretty}; }
sub filetype { my $self = shift;	return $self->{data}->{filetype}; }
sub abs_path { 
	my $self = shift;	
	return $self->{data}->{abs_path}; 
}
sub abs_loc { my $self = shift; return $self->{data}->{abs_loc}; }
sub rel_path { my $self = shift;	return $self->{data}->{rel_path}; }
sub rel_loc { my $self = shift;	return $self->{data}->{rel_loc}; }

sub ext { my $self = shift; return $self->{data}->{ext}; }
sub is_root {
	my $self = shift;
	return $self->{data}->{is_root};
}

sub is_dir  { 
	my $self = shift;		
	return $self->{data}->{is_dir};
}

sub is_file {
	my $self = shift;
	return $self->{data}->{is_file};	
	return 1;
}

sub alt  { 
 my $self = shift;
 return $self->{data}->{alt};	
}






sub get_defaulted {
	my $self= shift;	return $self->{defaulted};
}


# must be loaded
sub ls {
	my $self = shift;
	$self->is_dir or return;

	if ( defined $self->{data}->{ls}){
		return $self->{data}->{ls};
	}

	opendir(DIR, $self->abs_path) or croak("cant open dir ".$self->abs_path.", check permissions? - $!");
	my @ls = sort grep { !/^\.+$/g } readdir DIR;
	closedir DIR;
	$self->{data}->{ls} = \@ls;
	return $self->{data}->{ls};
}

# must be loaded
sub lsd {
	my $self = shift;
	$self->is_dir or return;
	if ( defined $self->{data}->{lsd} ){
		return $self->{data}->{lsd};
	}

	$self->{data}->{lsd} = [];
	for ( @{$self->ls} ){
		-d $self->abs_path . "/$_" or next;
		push @{$self->{data}->{lsd}}, "$_";
	}

	return $self->{data}->{lsd};
}



# must be loaded
sub is_empty_dir {
	my $self = shift;
	$self->is_dir or return;
	
	if (scalar @{$self->ls}){
		$self->{data}->{is_empty_dir} = 0;
	}
	else {
		$self->{data}->{is_empty_dir} = 1;	
	}	
	return $self->{data}->{is_empty_dir};
}

# must be loaded
sub lsf {
	my $self = shift;
	$self->is_dir or return;
	if ( defined $self->{data}->{lsf}){
		return $self->{data}->{lsf};
	}

	$self->{data}->{lsf} = [];
	for ( @{$self->ls} ){
		-f $self->abs_path . "/$_" or next;
		push @{$self->{data}->{lsf}}, $_;
	}

	return $self->{data}->{lsf};
}

sub lsd_prepped {
	my $self = shift;
	$self->is_dir or return;
	if (scalar @{$self->lsd}){
		my $prepped = [];

		for (@{$self->lsd}){
			push @{$prepped}, { 
					filename => $_,
					rel_path => $self->rel_path."/$_",
					rel_loc => $self->rel_path,
					abs_path =>$self->abs_path."/$_",
					abs_loc => $self->abs_path,
					filetype => 'd',
					is_dir => 1,
					is_file => 0,
					is_root => 0,
			};
		}
		return $prepped;
	}	
	return [];
}

sub lsf_prepped {
	my $self = shift;
	$self->is_dir or return;
	if (scalar @{$self->lsf}){
		my $prepped = [];

		for (@{$self->lsf}){
			push @{$prepped}, { 
				filename => $_,
				rel_path => $self->rel_path."/$_",
				rel_loc => $self->rel_path,
				abs_path =>$self->abs_path."/$_",
				abs_loc => $self->abs_path,
				filetype => 'f',
				is_dir => 0,
				is_file => 1,
				is_root => 0,
			};
		}
		return $prepped;
	}	
	return [];
}

sub ls_prepped {
	my $self = shift;
	$self->is_dir or return;

	if (scalar @{$self->ls}){
		my $prepped = [];
		push @{$prepped}, @{$self->lsd_prepped};
		push @{$prepped}, @{$self->lsf_prepped};
		return $prepped;
	}	

	return [];
}

sub get_datahash_prepped {
	my $self = shift;
	my $data = $self->get_datahash;
	my $prepped;
	for (keys %{$data}) {
		if(ref $data->{$_}){ next;}
		$prepped->{$_} = $data->{$_};
	}

	return $prepped;
}
	
sub get_datahash{
	my $self = shift;
	exists $self->{data}->{filesize} or $self->_feed_stat_data; #make sure it is fed
	exists $self->{data}->{is_binary} or $self->_feed_extended_data; #make sure it is fed
	$self->lsf;
	$self->lsd;
	$self->get_excerpt;
	return $self->{data}; 
}

	
1;

__END__

=pod

=head1 NAME

CGI::PathRequest - get file info in a cgi environment

=cut

=head1 SYNOPSIS

	use CGI::PathRequest;
	
	my $rq = new CGI::PathRequest;
	$rq || die('no request, no default');
	
=cut


=head1 DESCRIPTION

This is kind of my swiss army knife of dealing with files in a cgi environment.
It's mainly geared for taking requests from a client and setting default information about that resource.
The constructor is told the relative path to a file (or directory) and from that you can ask a lot of
really useful things like, relative path, absoltue path, filename, filesize, absolute location, relative
location, etc. Things you normally have to regex for, they are already done here.


=cut













=head1 new()

Constructor. Takes hash ref as argument. Each key is a parameter.
	
	my $rq = CGI::PathRequest->new({

		param_name => 'path', 		
		default => '/',
		DOCUMENT_ROOT => '/home/superduper/html', 
		SERVER_NAME => 'superduper.com',		
		rel_path => $url, 		
		cgi => $cgi, 		
	
	});	

=head2 Optional Parameters

=over 4

=item param_name

if you are taking data from a form imput via POST or GET , by default we are looking for a 
cgi param named 'path' - this can be overridden

=item rel_path

specify the relative path to the file or dir we want

=item default

if POST or GET do not yield a path and that path exists on disk, then default to what rel_path?
Defaults to / (which would be your DOCUMENT ROOT )

=item DOCUMENT_ROOT 

Will try to determine automatically from ENV DOCUMENT_ROOT unless provided.
Croaks if not determinded.

=item cgi

Pass it an already existing cgi object for re use.

=item SERVER_NAME

The name of your server or domain.

=back








=head1 abs_path()

Absolute path on disk. Watch it, all /../ and links are resolved!

=head1 rel_path()


=head1 abs_loc()

The directory upon which the requested resource sits, everything but the filename


=head1 rel_loc()

Like abs_loc() but relative to ENV DOCUMENT_ROOT

=head1 filename()

Returns the filename portion of the file

=head1 filename_pretty()

Returns the filename, but prettyfied.
Turns 'how_are_you.pdf' to 'How Are You'.

=head1 filetype()

Returns 'd' if directory, 'f' if file.



=head1 url()

Returns how this file would be accessed via a browser.

=head1 www()

Returns domain name of current site.

=head1 ext()

Returns filename's extension.

=head1 is_root()

Returns true if the request is the same as ENV DOCUMENT_ROOT
This sets rel_loc(), rel_path(), and filename() to return "/", and 
also sets filetype() to return "d".










=head1 EXTENDED METHODS

These are methods that populate on call, that is, the values are not 
fed before you ask for them. If you are creating many CGI::PathRequest objects
in one run and you use these, they should slow your process.

=head2 elements()

Returns an array of all data elements that are presently defined

	my @elements = $r->elements;

=head2 get_excerpt()

Get first x characters from file content if get_content() is or can be defined
returns undef on failure

	$r->get_excerpt;

=head2 get_content()

Get contents of resource if is_text() returns true, returns undef on failure or
zero size

	$r->get_content();


=head2 filesize()

Returns filesize in bites

	$r->filesize;


=head2 filesize_pretty()

Returns filesize in k, with the letter k in the end returns 0k if filesize is 0 

	$r->filesize_pretty;


=head2 ctime()

Returns ctime, unix time

	$r->ctime;


=head2 ctime_pretty()

Returns ctime formatted to yyyy/mm/dd hh:mm by default

	$r->ctime_pretty;


=head2 atime()

Returns atime, unix time 

	$r->atime;


=head2 atime_pretty()

Returns atime formatted to yyyy/mm/dd hh:mm by default

	$r->atime_pretty;


=head2 mtime()

Returns mtime, unix time 

	$r->mtime;


=head2 mtime_pretty()

Returns mtime formatted to yyyy/mm/dd hh:mm by default

	$r->mtime_pretty;




=head2 is_dir()

Returns true if it is a directory

=head2 is_empty_dir()

Returns true if it is an empty directory, slow, feeds ls, lsf, and lsd.

=head2 is_file()

returns true if it is a file 

=head2 is_image()

Returns true if mime type is an image type

	$r->is_image;

=head2 is_binary()

Returns true if resource was binary, directories return true

	$r->is_binary;

=head2 is_text()

Returns true if resource is text ( according to -T )

	$r->is_text;


	

=head2 mime_type()
	
Returns mime type returned by File::Type

	$r->mime_type;
	

=head2 alt()

Returns same as filename_pretty(), for use with an image alt tag, etc

	$r->alt;
	


=head1 DIRECTORY METHODS


=head2 ls()

returns array ref listing of dir 
returns undef if it is not a dir
returns all files, all dirs sorted
returns empty array ref [] if none found
excludes . and ..

=head2 lsd()

returns array ref listing of subdirs
returns undef if it is not a dir
returns only dirs sorted
returns empty array ref [] if none found
excludes . and ..

=head2 lsf()

returns array ref listing of files
returns undef if it is not a dir
returns only files sorted
returns empty array ref [] if none found
excludes . and ..


=cut


=head1 ERROR METHODS


=head2 error()

record an error

	$r->error('this went wrong');

=head2 errors()

returns array of errors, just strings.
returns undef if no errors
	
	my @errors = $r->errors;

examples of viewing for errors:

	# using Data::Dumper
	if ($r->errors){ 
		print STDERR Dumper($r->errors);
	}

	# using Smart::Comments	
	my $err = $r->errors; 
	### $err
	
=cut	



=head1 get_datahash()

Returns hash with data, abs_path, rel_path, etc etc


=head1 METHODS FOR USE WITH HTML::Template


=head2 ls_prepped(), lsd_prepped() and lsf_prepped()

Alike ls lsf and lsd, returns array ref with hashes representing
directory listing excluding . and ..
in hash form, suitable for html template.
for example, if your template has

	<TMPL_LOOP LS>
		<TMPL_VAR FILENAME>
		<TMPL_VAR REL_PATH>
				
	</TMPL_LOOP>

You would feed it as 

	$html_template_object->param( LS => $cms->ls_prepped ); 

Returns empty array ref on none present [], that way it wont error on nothing there when
you assign it to the tmpl loop

The same for lsd_prepped() and lsf_prepped()
The name of the TMPL_VAR will be the same as the name of the method, (LS, LSF, LSD).

The TMPL_VAR set are :

	rel_path, rel_loc, abs_path, abs_loc, filename, is_file, is_dir, filetype

=head2 get_datahash_prepped()

returns hash with data suitable for HTML::Template, none of the data that are arrays, etc are included
For example:

	my $prepped = $r->get_datahash_prepped;

	for (keys %{$prepped}){
		$html_template_object->param($_,$prepped->{$_}); 
	}

Your template could say:

	<TMPL_IF IS_DIR>
		This is a directory.
	</TMPL_IF> 

Your HTML::Template construction should include die_on_bad_params=>0 to make use of this.


=cut




=head1 PREREQUISITES

File::stat;
File::Type;
File::Slurp;
Time::Format;



=head1 TODO

option not to resolve symlinks

get rid of default.
if resource does not exist, just return undef.


=head1 AUTHOR

Leo Charre leo (at) leocharre (dot) com

=head1 SEE ALSO



=cut


