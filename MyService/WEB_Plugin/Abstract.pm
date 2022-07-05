package MyService::WEB_Plugin::Abstract;

use strict;
use File::Copy;
use POSIX qw(strftime);

use MyService::WEB_Plugin::Constants;

sub new {
	my $this = shift;

	my %h = @_;

	my $rid        = $h{rid};
	my $param_hash = $h{param_hash}; 

	my $self = {};

	my $class = ref($this) || $this;
	bless $self, $class;

	$self->{rid} = $rid;
	$self->{param_hash} = $param_hash;

	return $self;
}

sub print_html {
	my $self   = shift;
	my $string = shift;
	
	open HTML, '>>' . &TEMPORARY_HTML_PATH . '/' . $self->{rid} . '.tmp';
	print HTML "$string\n";
	close HTML;
}

sub print_html_log {
	my $self   = shift;
	my $string = shift;

	my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

	$self->print_html("[$now_string] $string<br>");
}

sub handle_and_print {
	my $self = shift;

#	$self->print_html("<html>\n<body>");

	eval {
		$self->handler(@_);
	};

	sleep(2);

	if ($@) {
		$self->print_html('Error: ' . $@);
		$self->print_html("</body>\n</html>");
		copy(&TEMPORARY_HTML_PATH . '/' . $self->{rid} . '.tmp', &TEMPORARY_HTML_PATH . '/' . $self->{rid} . '.html');
	} else {
#		$self->print_html("</body>\n</html>");
		copy(&TEMPORARY_HTML_PATH . '/' . $self->{rid} . '.tmp', &TEMPORARY_HTML_PATH . '/' . $self->{rid} . '.html');
	}
}

sub execute_shell_command {
	my $self    = shift;
	my $command = shift;
	my $after_exec_sub = shift || sub {};
	
	my $result;

	if ($self->{rid}) {
		my $temporary_html_path = &TEMPORARY_HTML_PATH . "/$self->{rid}.html";
	
		open COMMAND, "$command |";
		my $string;
		while ($string = <COMMAND>) {
			$result .= $string;
			open HTML, ">>$temporary_html_path";
			print HTML "$string<br>";
			close HTML;
		}
		close COMMAND;

		$after_exec_sub->();
	} else {
		$result = `$command`;
	}

	return $result;
}
1;