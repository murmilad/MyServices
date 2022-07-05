package MyService::Jep_Generator::Jep_Version::Jep_RIA;

use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Jep_Version::Abstract';

use constant JEP_VERSION      => 'jep_ria';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/server/\w+ServerConstant\.java$'
];

sub is_version {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	my $result = 0;
	if ($line =~ /public\s+static\s+final\s+String\s+DATA_SOURCE_JNDI_NAME\s+=\s+"jdbc\/(\w+)"/){

		$result = 1;		
	}

	return $result;
}

1;