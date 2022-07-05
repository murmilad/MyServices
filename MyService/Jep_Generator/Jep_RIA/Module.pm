package MyService::Jep_Generator::Jep_RIA::Module;

use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/shared/service/\w+ServiceAsync\.java$',
	'java/com/technology/\w+/\w+/main/client/\w+ClientConstant\.java$'
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

		if ($line =~ /public\s+interface\s+(\w+)ServiceAsync\s+extends/i) {
			$this->{result}->{$this->{current_form}}->{id} = $1;
		}
	} else {
		if ($line =~ /public\s+static\s+final\s+String\s+(\w+)\s*=\s*"(\w+)"/i) {

			my $module = lc($2);

			if (my $role = $this->{result}->{temporary}->{module_id}->{$1}) {
				$this->{result}->{$module}                  = {} unless $this->{result}->{$module};
				$this->{result}->{$module}->{roles}         = {} unless $this->{result}->{$module}->{roles};
				$this->{result}->{$module}->{roles}->{role} = [] unless $this->{result}->{$module}->{roles}->{role};
				
				$this->{result}->{lc($module)}->{roles}->{role} = [split(/\s*,\s*/, $role)];
			}
		}
	}
}


1;