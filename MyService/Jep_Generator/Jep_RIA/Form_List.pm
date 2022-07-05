package MyService::Jep_Generator::Jep_RIA::Form_List;


use strict;

use Data::Dumper;
use MyService::XML_Tools;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/client/ui/form/list/\w+ListFormView(Impl)?\.java$'
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



	$this->{result}->{$this->{current_form}} = {}                                  unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{forms} = {}                         unless $this->{result}->{$this->{current_form}}->{forms}; 
	$this->{result}->{$this->{current_form}}->{forms}->{'form-list'} = {}            unless $this->{result}->{$this->{current_form}}->{forms}->{'form-list'};
	$this->{result}->{$this->{current_form}}->{forms}->{'form-list'}->{field} = []   unless $this->{result}->{$this->{current_form}}->{forms}->{'form-list'}->{field}; 

	$this->{result}->{$this->{current_form}}->{temporary} = {}                         unless $this->{result}->{$this->{current_form}}->{temporary}; 
	$this->{result}->{$this->{current_form}}->{temporary}->{form_list_string_id} = {}  unless $this->{result}->{$this->{current_form}}->{temporary}->{form_list_string_id}; 

	if ($line =~ /column(?:Configuration)?s\.add\s*\(\s*new\s+\w+\(\s*(\w+)\s*,\s*\w+\.(\w+)\(\)\s*,/i) {
		push(@{$this->{result}->{$this->{current_form}}->{forms}->{'form-list'}->{field}}, {id => $1});
		$this->{result}->{$this->{current_form}}->{temporary}->{form_list_string_id}->{$1} = $2;
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