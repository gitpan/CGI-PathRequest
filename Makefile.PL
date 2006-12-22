use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> "CGI::PathRequest",
	VERSION_FROM	=> 'lib/CGI/PathRequest.pm',
	PREREQ_PM 		=> {
		'CGI'	=> '3',
		'File::MMagic' => '1',
		'Time::Format' => '1',
		'Want'	=> '0.12',
		'File::PathInfo' => '1.06',
		'Cwd'	=> '3',
	},
	'dist'			=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
