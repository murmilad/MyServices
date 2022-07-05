package MyService::WEB_Plugin::Factory;

use strict;

use MyService::WEB_Plugin::Constants;

use base "MyService::Factory";

sub require_web_plugin{
	my $class = shift;

	my %h = @_;
	my $handler        = $h{handler};
	my $rid            = $h{rid};
	my $param_hash     = $h{param_hash};
	my $interface;
	
	my $handler_class = &WEB_PLUGIN_HANDLER_MAP->{$handler} || &WEB_PLUGIN_HANDLER_MAP->{&DEFAULT_PLUGIN_HANDLER};	

	if ($handler_class) {
		$class->require_handler($handler_class);
		$interface = $handler_class->new(rid => $rid, param_hash => $param_hash);
	}

	return $interface;
}

1;