use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> "CGI::PathRequest",
	VERSION_FROM	=> 'lib/CGI/PathRequest.pm',
	PREREQ_PM 		=> {
		'CGI'	=> '3',
		'File::Type' => '0.22',
		'Time::Format' => '1',
		'Want'	=> '0.12',
		'Cwd'	=> '3',
	},
	'dist'			=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
