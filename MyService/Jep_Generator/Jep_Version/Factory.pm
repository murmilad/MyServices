package MyService::Jep_Generator::Jep_Version::Factory;


use strict;

use constant GENERATOR_HANDLER_MAP => {
	jep_common  => 'MyService::Jep_Generator::Jep_Version::Jep_Common',
	jep_ria     => 'MyService::Jep_Generator::Jep_Version::Jep_RIA',
};

sub require_handler {
	my $class   = shift;
	my $handler = shift;

	if ($handler) {
		my $location = $handler . '.pm';
		$location =~ s/::/\//g;
		require $location;
	}
}

sub get_jep_version {
	my $class = shift;

	my %h = @_;
	my $handler = $h{handler};

	my $jep_version;

	if (&GENERATOR_HANDLER_MAP->{$handler}) {
		$class->require_handler(&GENERATOR_HANDLER_MAP->{$handler});
		$jep_version = &GENERATOR_HANDLER_MAP->{$handler};
	}

	return $jep_version;
}


1;