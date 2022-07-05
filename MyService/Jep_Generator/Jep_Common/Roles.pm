package MyService::Jep_Generator::Jep_Common::Roles;

use strict;

use Data::Dumper;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/action/(\w+)EditOutputAction\.java',
];

sub is_data_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	my $is_data_scope = $this->{scope};

	if ($line =~ /getHaveAccessOR/) {
		$is_data_scope = 1;
	} 

	if ($is_data_scope && $line =~ /}/) {
		$this->{next_will_last} = 1;
	} elsif ($is_data_scope && $this->{next_will_last}) {
		$is_data_scope = 0;
		$this->{next_will_last} = 0;
	}

	return $is_data_scope;
}

sub handle_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	if ($line =~ /"(\w+)"/i) {

		$this->{result}->{$this->{current_form}}                  = {} unless $this->{result}->{$this->{current_form}};
		$this->{result}->{$this->{current_form}}->{roles}         = {} unless $this->{result}->{$this->{current_form}}->{roles};
		$this->{result}->{$this->{current_form}}->{roles}->{role} = [] unless $this->{result}->{$this->{current_form}}->{roles}->{role};
				
		push(@{$this->{result}->{$this->{current_form}}->{roles}->{role}}, $1);
	}
}

1;