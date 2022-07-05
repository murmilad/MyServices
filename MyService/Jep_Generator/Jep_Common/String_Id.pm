package MyService::Jep_Generator::Jep_Common::String_Id;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'resources/com/technology/\w+/\w+/text/\w+_en\.properties$',
	'resources/com/technology/\w+/\w+/text/\w+_Source\.properties$',
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

	my $param_name = $this->{current_file_path} =~ /_Source\.properties$/ ? 'name' : 'nameEn';

	foreach my $module_name (keys %{$this->{result}}) {
		my $module_name_string = lcfirst($module_name) . '.title';

		if ($line =~ /^\s*([\w.]+)\s*=(.+)\n/si) {
			my $string_id = $1;
			my $string    = $2;
			$string =~ s/\s*:\s*$//;

			foreach my $field (@{$this->{result}->{$module_name}->{forms}->{'form-list'}->{field}}) {
				if (my $str_id = $this->{result}->{$module_name}->{temporary}->{form_list_string_id}->{$field->{id}}) {
					if ($str_id eq $string_id) {
						$field->{$param_name} = $string;
					}
				}
			}

			foreach my $field (@{$this->{result}->{$module_name}->{record}->{field}}) {
				if (my $str_id = $this->{result}->{$module_name}->{temporary}->{form_detail_string_id}->{$field->{id}}) {
					if ($str_id eq $string_id) {
						$field->{$param_name} = $string;
					}
				}
			}
		}

		if ($line =~ /^\s*$module_name_string\s*=(.+)\n/si) {
			my $string = $1;
	
			unless ($this->{result}->{$module_name}->{$param_name}) {
				$string =~ s/\s*:\s*$//;
				$this->{result}->{$module_name}->{$param_name} = $string;
			}			
		
		}
	}
}

sub handle_result {
	my $this = shift;
	my %h    = @_;

	foreach my $form_name (keys %{$this->{result}}) {
		delete($this->{result}->{$form_name}->{temporary});
	} 
}
1;