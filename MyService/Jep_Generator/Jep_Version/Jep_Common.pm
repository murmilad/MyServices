package MyService::Jep_Generator::Jep_Version::Jep_Common;

use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Jep_Version::Abstract';

use constant JEP_VERSION      => 'jep_common';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/action/\w+InputAction.java$'
];

sub is_version {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	my $result = 0;
	if ($line =~ /List<\w+Dto>\s*\w+\s*=\s*\w+.\w+/){
		$result = 1;		
	}

	return $result;
}

1;