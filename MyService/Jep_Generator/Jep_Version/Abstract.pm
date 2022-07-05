package MyService::Jep_Generator::Jep_Version::Abstract;


use strict;

use constant DATA_FILES_MASKS => [];
use constant JEP_VERSION      => '';

sub is_data_file {
	my $this = shift;
	my %h    = @_;

	my $file = $h{file};

	my $is_data_file = 0;
	
	foreach my $mask (@{$this->DATA_FILES_MASKS}) {
		
		if ($file =~ /$mask/){
			$is_data_file = 1;
		};
	}

	return $is_data_file;
}

sub is_version {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	return 0;
}

1;