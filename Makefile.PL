use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> "CGI::PathRequest",
	VERSION_FROM	=> 'lib/CGI/PathRequest.pm',
	PREREQ_PM 		=> {
		'CGI'	=> '3.00',
		'File::Type' => '0.22',
		'Time::Format' => '2.22',
		'Want'	=> '0.11',
		'Cwd'	=> '3.01',
	},
	'dist'			=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
