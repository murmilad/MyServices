package MyService::Jep_Generator::Jep_RIA::Form_Detail;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/client/ui/form/detail/\w+DetailFormView(Impl)?\.java$'
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



	$this->{result}->{$this->{current_form}} = {}                                    unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{forms} = {}                           unless $this->{result}->{$this->{current_form}}->{forms}; 
	$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'} = {}            unless $this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}; 
	$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field} = []   unless $this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}; 

	$this->{result}->{$this->{current_form}}->{temporary} = {}                          unless $this->{result}->{$this->{current_form}}->{temporary}; 
	$this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id} = {} unless $this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}; 

	if (
		$line =~ /addField\s*\(\s*(\w+)\s*,\s*new\s*(\w+)\s*\(\s*\w+\.(\w+)\s*\(\s*\)\s*\)\s*\)/i
		|| $line =~ /addField\s*\(\s*\w+\s*,\s*(\w+)\s*,\s*new\s*(\w+)\s*\(\s*\w+\.(\w+)\s*\(\s*\)\s*\)\s*\)/i # Free layout
	) {
		push(@{$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}}, {id => $1, widget => $2});
		$this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}->{$1} = $3; 
	}

	if (
		$line =~ /Jep\w+Field\s*(\w+)\s*=\s*new\s+(\w+)\s*\(\s*\w+\.(\w+)\(/i
	) {
		push(@{$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}}, {id => $1, widget => $2});
		$this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}->{$1} = $3; 
	}

	if (
		$line =~ /fields.put\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)/i
	) {
		my $id   = $1;
		my $name = $2;
		my $field_item;
		if (($field_item) = grep {$_->{id} eq $name} @{$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}}){
			$field_item->{id} = $id;
			$this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}->{$id} = $this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}->{$name}; 
		}
	}

}


1;