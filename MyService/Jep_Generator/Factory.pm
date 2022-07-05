package MyService::Jep_Generator::Factory;


use strict;

use constant GENERATOR_HANDLER_MAP => {
	db          => 'MyService::Jep_Generator::Jep_RIA::DB',
	data_source => 'MyService::Jep_Generator::Jep_RIA::Data_Source',
	form_detail => 'MyService::Jep_Generator::Jep_RIA::Form_Detail',
	form_list   => 'MyService::Jep_Generator::Jep_RIA::Form_List',
	string_id   => 'MyService::Jep_Generator::Jep_RIA::String_Id',
	record      => 'MyService::Jep_Generator::Jep_RIA::Record',
	module      => 'MyService::Jep_Generator::Jep_RIA::Module',
	roles       => 'MyService::Jep_Generator::Jep_RIA::Roles',
	toolbar     => 'MyService::Jep_Generator::Jep_RIA::Toolbar',
	header      => 'MyService::Jep_Generator::Jep_RIA::Header',

	db_common          => 'MyService::Jep_Generator::Jep_Common::DB',
	header_common      => 'MyService::Jep_Generator::Jep_Common::Header',
	module_common      => 'MyService::Jep_Generator::Jep_Common::Module',
	data_source_common => 'MyService::Jep_Generator::Jep_Common::Data_Source',
	string_id_common   => 'MyService::Jep_Generator::Jep_Common::String_Id',
	form_detail_common => 'MyService::Jep_Generator::Jep_Common::Form_Detail',
	form_list_common   => 'MyService::Jep_Generator::Jep_Common::Form_List',
	record_common      => 'MyService::Jep_Generator::Jep_Common::Record',
	roles_common       => 'MyService::Jep_Generator::Jep_Common::Roles',
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

sub get_jep_generator {
	my $class = shift;

	my %h = @_;
	my $handler = $h{handler};
	my $result  = $h{result}; 

	my $jep_generator;

	if (&GENERATOR_HANDLER_MAP->{$handler}) {
		$class->require_handler(&GENERATOR_HANDLER_MAP->{$handler});
		$jep_generator = &GENERATOR_HANDLER_MAP->{$handler}->new(result => $result);
	}

	return $jep_generator;
}


1;