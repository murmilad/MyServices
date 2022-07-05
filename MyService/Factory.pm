package MyService::Factory;

use strict;

sub require_handler {
	my $class   = shift;
	my $handler = shift;
         
		if ($handler) {
			my $location = $handler . '.pm';
			$location =~ s/::/\//g;
			require $location;
		}
}

1;