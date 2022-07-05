package MyService::Jep_Generator::Jep_RIA::Record;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/shared/record/\w+RecordDefinition\.java$'
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



	$this->{result}->{$this->{current_form}} = {}                      unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{record} = {}            unless $this->{result}->{$this->{current_form}}->{record}; 
	$this->{result}->{$this->{current_form}}->{record}->{field} = []   unless $this->{result}->{$this->{current_form}}->{record}->{field}; 

	if ($line =~ /new\s+String\s*\[\]\s*\{(\w+)\}/i) {
		$this->{result}->{$this->{current_form}}->{record}->{primaryKey} = $1;
	}

	if ($line =~ /typeMap.put\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)/i){
		push(@{$this->{result}->{$this->{current_form}}->{record}->{field}}, {id => $1, type => ucfirst(lc($2))});
	}
}

1;