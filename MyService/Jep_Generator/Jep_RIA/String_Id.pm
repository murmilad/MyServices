package MyService::Jep_Generator::Jep_RIA::String_Id;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/shared/text/\w+Text_en\.properties$',
	'java/com/technology/\w+/\w+/(\w+)/shared/text/\w+Text_Source\.properties$'
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

	my $param_name = $this->{current_file_path} =~ /Text_Source\.properties$/ ? 'name' : 'nameEn';

	if ($this->{result}->{$this->{current_form}}) {
		if ($line =~ /(\w+)\.(\w+)\.(\w+)\s*=(.+)$/i) {
			my $string = $4;

			foreach my $field (@{$this->{result}->{$this->{current_form}}->{forms}->{'form-list'}->{field}}) {
				if (my $str_id = $this->{result}->{$this->{current_form}}->{temporary}->{form_list_string_id}->{$field->{id}}) {
					if ($str_id eq "${1}_${2}_${3}") {
						$field->{$param_name} = $string;
					}
				}
			}

			foreach my $field (@{$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}}) {
				if (my $str_id = $this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}->{$field->{id}}) {
					if ($str_id eq "${1}_${2}_${3}") {
						$field->{$param_name} = $string;
					}
				}
			}

			foreach my $field (@{$this->{result}->{$this->{current_form}}->{record}->{field}}) {
				if (my $str_id = $this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}->{$field->{id}}) {
					if ($str_id eq "${1}_${2}_${3}") {
						$field->{$param_name} = $string;
					}
				}
			}

		} elsif ($line =~ /^\s*\w+\.title\s*=(.+)$/i) {
			my $string = $1;
	
			unless ($this->{result}->{$this->{current_form}}->{$param_name}) {
				$this->{result}->{$this->{current_form}}->{$param_name} = $string;
			}			
		
		} elsif ($line =~ /^\s*(\w+)\s*=(.+)$/i) {
			my $string = $2;
			foreach my $field (@{$this->{result}->{$this->{current_form}}->{toolbar}->{button}}) {
				if (my $str_id = $this->{result}->{$this->{current_form}}->{temporary}->{toolbar_string_id}->{$field->{id}}) {
					if ($str_id eq $1) {
						$field->{$param_name} = $string;
					}
				}
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