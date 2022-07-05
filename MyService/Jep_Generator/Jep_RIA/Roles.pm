package MyService::Jep_Generator::Jep_RIA::Roles;

use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/main/client/ui/(?:main|module)/\w+Presenter\.java$'
];

sub is_data_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};


	return 1;
}

sub handle_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	if ($line =~ /addModuleProtection\s*\(\s*(\w+)\s*,\s*"([\w\s,]+)"\s*,/i) {

		$this->{result}->{temporary} = {}              unless $this->{result}->{temporary}; 
		$this->{result}->{temporary}->{module_id} = {} unless $this->{result}->{temporary}->{module_id}; 

		$this->{result}->{temporary}->{module_id}->{$1} = $2;
	}
}

1;