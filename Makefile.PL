use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> "CGI::PathRequest",
	VERSION_FROM	=> 'lib/CGI/PathRequest.pm',
	PREREQ_PM 		=> {
		'CGI'	=> 0,
		'File::MMagic' => 0,
		'Time::Format' => 0,
		'Want'	=> 0,
		'File::PathInfo' => 0,
		'Cwd'	=> 0,
	},
	'dist'			=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
