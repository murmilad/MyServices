package MyService::Jep_Generator::Jep_Common::Data_Source;


use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/ejb/\w+Constant\.java',
	'java/com/technology/\w+/\w+/\w+Constant\.java',
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

	$this->{result}->{temporary} = {}                           unless $this->{result}->{temporary}; 
	$this->{result}->{temporary}->{project} = {}                unless $this->{result}->{temporary}->{project}; 

	if ($line =~ /(public\s+)?static\s+final\s+String\s+DATA_SOURCE_JNDI_NAME\s+=\s+"jdbc\/(\w+)"/){
		if (!$this->{result}->{temporary}->{project}->{defaultDatasource}){
			$this->{result}->{temporary}->{project}->{defaultDatasource} = $2 || $1;
		}
	}
}

sub handle_result {
	my $this = shift;
	my %h    = @_;

	foreach my $module_name (keys %{$this->{result}}) {
		if (!$this->{result}->{$module_name}->{db}->{'datasource'}){
			$this->{result}->{$module_name}->{db}->{'datasource'} = $this->{result}->{temporary}->{project}->{defaultDatasource};
		}
	}
}
1;