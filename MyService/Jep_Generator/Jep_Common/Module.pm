package MyService::Jep_Generator::Jep_Common::Module;

use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/action/(\w+)(?<!Edit)InputAction\.java',
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


	if ($this->{current_form}) {
		$this->{result}->{$this->{current_form}} = {} unless $this->{result}->{$this->{current_form}};

		if ($line =~ /public\s+class\s+(\w+)InputAction\s+extends\s+JepInputAction/i) {
			$this->{result}->{$this->{current_form}}->{id} = $1;
		}
	}
}

sub handle_result {
	my $this = shift;
	my %h    = @_;

	foreach my $module_name (keys %{$this->{result}}) {
		delete $this->{result}->{$module_name} if !$this->{result}->{$module_name}->{id} && !$this->{result}->{$module_name}->{name};
	}

}

1;