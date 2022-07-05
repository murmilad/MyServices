package MyService::WEB_Plugin::Constants;
require Exporter;

@ISA = qw(Exporter);


use constant WEB_PLUGIN_HANDLER_MAP => {
	find_replace             => 'MyService::WEB_Plugin::Find_Replace',
	find_by_task             => 'MyService::WEB_Plugin::SVN_Project',
	get_jep_xml              => 'MyService::WEB_Plugin::Get_Jep_XML',
	get_updated_jep_project  => 'MyService::WEB_Plugin::Get_Updated_Jep_Project',
	xlsx_to_html             => 'MyService::WEB_Plugin::XLSX_to_HTML',
	find_file                => 'MyService::WEB_Plugin::Find_File',
	get_integration_versions => 'MyService::WEB_Plugin::Get_Integration_Versions',
	integration              => 'MyService::WEB_Plugin::Integration',
	get_module_versions      => 'MyService::WEB_Plugin::Get_Module_Versions',
	convert_project_db       => 'MyService::WEB_Plugin::Convert_Project_DB',
	convert_project_xml     => 'MyService::WEB_Plugin::Convert_Project_XML',
	move_documentation      => 'MyService::WEB_Plugin::Move_Documentation',
	reboot_apache       	=> 'MyService::WEB_Plugin::Reboot_Apache',
	convert_project_report  => 'MyService::WEB_Plugin::Convert_Project_Report',
	dao_to_rest             => 'MyService::WEB_Plugin::DAO_to_REST',
};

use constant DEFAULT_PLUGIN_HANDLER => 'find_by_task';
use constant TEMPORARY_HTML_PATH    => '/var/www/html/perl/';


@EXPORT = qw(
	&DEFAULT_PLUGIN_HANDLER
	&WEB_PLUGIN_HANDLER_MAP
	&TEMPORARY_HTML_PATH
);

1;