package MyService::Jep_Generator::Jep_RIA::Header;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/(\w+)/\w+/main/client/(\w+)ClientConstant\.java$'
];

sub is_data_file {
	my $this = shift;
	my %h    = @_;

	my $file = $h{file};

	my $is_data_file = 0;
	
	foreach my $mask (@{$this->DATA_FILES_MASKS}) {
		
		if ($file =~ /$mask/){
			$this->{current_project} = $1;
			$this->{current_module}  = $2;
			$is_data_file = 1;
		};
	}

	if ($is_data_file) {
		$this->{current_file_path} = $file;
	}

	return $is_data_file;
}

sub handle_result {
	my $this = shift;
	my %h    = @_;

	my $temporary = $this->{result}->{temporary};

	delete ($this->{result}->{temporary});

	foreach my $module_name (keys %{$this->{result}}) {
		$this->{result}->{application}                      = {} unless $this->{result}->{application};
		$this->{result}->{application}->{modules}           = {} unless $this->{result}->{application}->{modules};
		$this->{result}->{application}->{modules}->{module} = [] unless $this->{result}->{application}->{modules}->{module};

		push (@{$this->{result}->{application}->{modules}->{module}},  $this->{result}->{$module_name});
		delete ($this->{result}->{$module_name});
	}

	$this->{result}->{application}->{projectPackage}    = $this->{current_project};
	$this->{result}->{application}->{defaultDatasource} = $temporary->{project}->{defaultDatasource};
	$this->{result}->{application}->{name}              = $this->{current_module};

}

1;