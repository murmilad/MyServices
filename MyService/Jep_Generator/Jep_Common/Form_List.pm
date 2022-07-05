package MyService::Jep_Generator::Jep_Common::Form_List;


use strict;

use Data::Dumper;
use MyService::XML_Tools;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'jsp/com/technology/\w+/\w+/(\w+)(?<!Edit)\.jsp$'
];

sub is_data_file {
	my $this = shift;
	my %h    = @_;

	my $file = $h{file};

	my $is_data_file = 0;
	
	foreach my $mask (@{$this->DATA_FILES_MASKS}) {
		
		if ($file =~ /$mask/){
			$this->{current_form} = ucfirst($1);
			$is_data_file = 1;
		};
	}

	if ($is_data_file) {
		$this->{current_file_path} = $file;
	}

	return $is_data_file;
}

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



	$this->{result}->{$this->{current_form}} = {}                                  unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{forms} = {}                         unless $this->{result}->{$this->{current_form}}->{forms}; 
	$this->{result}->{$this->{current_form}}->{forms}->{'form-list'} = {}            unless $this->{result}->{$this->{current_form}}->{forms}->{'form-list'};
	$this->{result}->{$this->{current_form}}->{forms}->{'form-list'}->{field} = []   unless $this->{result}->{$this->{current_form}}->{forms}->{'form-list'}->{field}; 

	$this->{result}->{$this->{current_form}}->{temporary} = {}                         unless $this->{result}->{$this->{current_form}}->{temporary}; 
	$this->{result}->{$this->{current_form}}->{temporary}->{form_list_string_id} = {}  unless $this->{result}->{$this->{current_form}}->{temporary}->{form_list_string_id}; 

	# <jep:column width="100" property="taskStatusName" captionkey="reportSimple.taskStatusName" style="text-align: center;" />

	my $param_name = '';
	if ($line =~ /jep:column\s+.*property\s*=\s*["'](\w+)["']/) {
		$param_name = $1;
		$param_name =~ s/(\w)([A-Z])/${1}_${2}/g;
		$param_name = uc($param_name);

		push(@{$this->{result}->{$this->{current_form}}->{forms}->{'form-list'}->{field}}, {id => $param_name});
	}
	if ($line =~ /jep:column\s+.*captionkey\s*=\s*['"]([\w\.]+)['"]/) {
		$this->{result}->{$this->{current_form}}->{temporary}->{form_list_string_id}->{$param_name} = $1;
	}
}

sub handle_result {
	my $this = shift;
	my %h    = @_;

	foreach my $form_name (keys %{$this->{result}}) {
		make_array_hash(hash => $this->{result}->{$form_name}->{forms});
	} 
	
}
1;