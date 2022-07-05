package MyService::Jep_Generator::Jep_Common::DB;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/action/(\w+)(?<!Edit)InputAction\.java',
	'java/com/technology/\w+/\w+/ejb/(\w+)Bean\.java',
	'java/com/technology/\w+/\w+/action/(\w+)EditOutputAction\.java',
];

sub is_data_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	my $is_data_scope = $this->{scope};

	if ($line =~ /^\s*(([\w<>]+\s*)?\w+\s*=\s*)?\w+.(find|create|update)\w+/) {
		$is_data_scope = $3;
	} elsif ($this->{scope} && $line =~ /\);/) {
		$this->{next_will_last} = 1;
	} elsif ($this->{scope} && $this->{next_will_last}) {
		$is_data_scope = 0;
		$this->{next_will_last} = 0;
	}
	
	return $is_data_scope;
}

sub handle_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	$this->{result}->{$this->{current_form}} = {}                           unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{db} = {}                     unless $this->{result}->{$this->{current_form}}->{db}; 
	$this->{result}->{$this->{current_form}}->{db}->{$this->{scope}} = [] unless $this->{result}->{$this->{current_form}}->{db}->{$this->{scope}}; 

	if ($line =~ /\w+Form.get(\w+)\(\)/i) {
		my $param_name = $1;
		$param_name =~ s/(\w)([A-Z])/${1}_${2}/g;
		$param_name = uc($param_name);

		push (@{$this->{result}->{$this->{current_form}}->{db}->{$this->{scope}}}, $param_name)
			unless ($param_name eq 'ROW_COUNT');
	}

	if (!$this->{result}->{$this->{current_form}}->{db}->{'package'} && $line =~ /\+\s*"\?\s*:=\s*(\w+).\w+\(|\+\s*"(\w+)\.\w+\("/) {
		$this->{result}->{$this->{current_form}}->{db}->{'package'} = $1 || $2;
	}

	$this->{result}->{$this->{current_form}} = {}                      unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{record} = {}            unless $this->{result}->{$this->{current_form}}->{record}; 
	
	if ($this->{scope} eq 'create' && $line =~ /^\s*(\w+)\s*=\s*\w+.create\w+/){
		my $param_name = $1;
		$param_name =~ s/(\w)([A-Z])/${1}_${2}/g;
		$param_name = uc($param_name);

		$this->{result}->{$this->{current_form}}->{record}->{primaryKey} = $param_name;
	}
}

sub handle_result {
	my $this = shift;
	my %h    = @_;

	foreach my $form_name (keys %{$this->{result}}) {
		foreach my $op_name (keys %{$this->{result}->{$form_name}->{db}}){
			if (ref($this->{result}->{$form_name}->{db}->{$op_name}) eq 'ARRAY') {
				my $op_list = $this->{result}->{$form_name}->{db}->{$op_name};
				if (scalar(@{$op_list}) > 0) {
					$this->{result}->{$form_name}->{db}->{$op_name} = {};
					$this->{result}->{$form_name}->{db}->{$op_name}->{parameters} = join (',', @{$op_list});
				} else {
					delete($this->{result}->{$form_name}->{db}->{$op_name});
				}
			}
		}
	} 
}
1;