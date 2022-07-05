package MyService::Jep_Generator::Jep_RIA::DB;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/server/ejb/\w+Bean\.java$',
];

sub is_data_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	my $is_data_scope = $this->{scope};

	if($line =~ /public\s+List<\w+>\s+find\s*\(/){
		$is_data_scope = 'find';
	} elsif($line =~ /public\s+Integer\s+create\s*\(/){
		$is_data_scope = 'create';
	} elsif($line =~ /public\s+void\s+update\s*\(/){
		$is_data_scope = 'update';
	} elsif ($this->{scope} && $line =~ /public\s+.+\s+\w+\s*\(/ && $line !~ /public\s+.+\s+map\s*\(/) {
		$is_data_scope = 0;
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

	if ($line =~ /templateRecord.get\((\w+)\)|record.get\((\w+)\)/i) {
		push (@{$this->{result}->{$this->{current_form}}->{db}->{$this->{scope}}}, $1 || $2);
	}
	
	if (!$this->{result}->{$this->{current_form}}->{db}->{'package'} && $line =~ /\s*"\s*begin\s*\?\s*:=\s*(\w+)\.\w+\(|\+\s*"\s*\?\s*:=\s*(\w+)\.\w+\(|\+\s*"(\w+)\.\w+\("/) {
		$this->{result}->{$this->{current_form}}->{db}->{'package'} = $1 || $2 || $3;
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