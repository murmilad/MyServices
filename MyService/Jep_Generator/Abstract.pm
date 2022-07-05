package MyService::Jep_Generator::Abstract;


use strict;

use constant DATA_FILES_MASKS => [];

sub new {
	my $this = shift;

	my %h      = @_;
	my $result = $h{result}; 

	my $self = {
		source            => {},
		result            => $result,
		current_form      => '',
		current_file_path => '',
		is_data           => 0,
	};

	my $class = ref($this) || $this;
	bless $self, $class;


	return $self;
}


sub is_data_file {
	my $this = shift;
	my %h    = @_;

	my $file = $h{file};

	my $is_data_file = 0;
	
	foreach my $mask (@{$this->DATA_FILES_MASKS}) {
		
		if ($file =~ /$mask/){
			$this->{current_form} = $1;
			$is_data_file = 1;
		};
	}

	if ($is_data_file) {
		$this->{current_file_path} = $file;
	}

	return $is_data_file;
}

sub exec_is_data_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	$this->{scope} = $this->is_data_line(line => $line);

}

sub exec_handle_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	if ($this->{scope}) {
		$this->handle_line(line => $line);
	}

}

sub exec_handle_text {
	my $this = shift;
	my %h    = @_;

	my $text = $h{text};

	if ($this->{scope}) {
		$this->handle_text(text => $text);
	}

}

sub is_data_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};
	
	return 0;
}

sub handle_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

}

sub handle_text {
	my $this = shift;
	my %h    = @_;

	my $text = $h{text};

}
sub handle_result {
	my $this = shift;
	my %h    = @_;

}


1;