package MyService::Jep_Generator::Jep_RIA::Data_Source;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/server/\w+ServerConstant\.java$'
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

	$this->{result}->{$this->{current_form}} = {}                           unless $this->{result}->{$this->{current_form}}; 
	$this->{result}->{$this->{current_form}}->{db} = {}                     unless $this->{result}->{$this->{current_form}}->{db}; 


	$this->{result}->{temporary} = {}                           unless $this->{result}->{temporary}; 
	$this->{result}->{temporary}->{project} = {}                unless $this->{result}->{temporary}->{project}; 

	if ($line =~ /public\s+static\s+final\s+String\s+DATA_SOURCE_JNDI_NAME\s+=\s+"jdbc\/(\w+)"/){

		if (!$this->{result}->{$this->{current_form}}->{db}->{'datasource'}){
			$this->{result}->{$this->{current_form}}->{db}->{'datasource'} = $1;
		}

		if (!$this->{result}->{temporary}->{project}->{defaultDatasource}){
			$this->{result}->{temporary}->{project}->{defaultDatasource} = $1;
		}
	}
}

1;