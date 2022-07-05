package MyService::Jep_Generator::Jep_Common::Record;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/dto/(\w+)Dto\.java$'
];

use constant FIELD_WIDGET_MAP => {
	Integer    => 'JepNumberField',
	String     => 'JepTextField',
	Date       => 'JepDateField',
	BigDecimal => 'JepNumberField',
	Time       => 'JepTimeField',
};

use constant FIELD_TYPE_MAP => {
	Integer    => 'Integer',
	String     => 'String',
	Date       => 'Date',
	BigDecimal => 'BigDecimal',
	Time       => 'Time',
};

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

	# public void setBlackListId(Integer blackListId)
	if ($line =~ /public\s+void\s+set(\w+)\s*\((\w+)\s+\w+\)/i) {
		my $param_name = $1;
		my $param_type = $2;
		$param_name =~ s/(\w)([A-Z])/${1}_${2}/g;
		$param_name = uc($param_name);

		push(@{$this->{result}->{$this->{current_form}}->{record}->{field}}, {id => $param_name, type => &FIELD_TYPE_MAP->{$param_type}});
		foreach my $field (@{$this->{result}->{$this->{current_form}}->{forms}->{'form-detail'}->{field}}){
			if ($field->{id} eq $param_name && !$field->{widget}) {
				$field->{widget} = &FIELD_WIDGET_MAP->{$param_type};
			}
		}
	}

}

1;