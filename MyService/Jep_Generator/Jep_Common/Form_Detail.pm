package MyService::Jep_Generator::Jep_Common::Form_Detail;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'jsp/com/technology/\w+/\w+/(\w+)Edit\.jsp$'
];

use constant FIELD_TYPE_MAP => {
	field  => '',
	select => 'JepComboBoxField',
};

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

	my $is_data_scope = $this->{scope};

	if ($line =~ /bean:message\s+key=['"]([\w\.]+)(?<!title)['"]/) {
		$is_data_scope = $1;
	} elsif ($this->{scope} && $line =~ /jep:(field|select)\s+.*property=['"]\w+['"]/) {
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



	$this->{result}->{$this->{current_form}} = {}                                    unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{forms} = {}                           unless $this->{result}->{$this->{current_form}}->{forms}; 
	$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'} = {}            unless $this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}; 
	$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field} = []   unless $this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}; 

	$this->{result}->{$this->{current_form}}->{temporary} = {}                          unless $this->{result}->{$this->{current_form}}->{temporary}; 
	$this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id} = {} unless $this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}; 


	if ($line =~ /jep:(field|select)\s+.*property=['"](\w+)['"]/) {
		my $field_type = $1;
		my $param_name = $2;
		
		$param_name =~ s/(\w)([A-Z])/${1}_${2}/g;
		$param_name = uc($param_name);
		unless ($param_name eq 'ROW_COUNT') {
			push(@{$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}}, {id => $param_name, widget => &FIELD_TYPE_MAP->{$field_type}});
			$this->{result}->{$this->{current_form}}->{temporary}->{form_detail_string_id}->{$param_name} = $this->{scope};
		} 
	}
}


1;