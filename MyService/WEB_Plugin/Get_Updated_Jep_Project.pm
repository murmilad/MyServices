package MyService::WEB_Plugin::Get_Updated_Jep_Project;
  
use strict;
use warnings;

use base "MyService::WEB_Plugin::Abstract";

use Encode qw(encode);
use Data::Dumper;
use URI::Escape;
  
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use MyService::SVN;
use MyService::Jep_Version;


use constant FOLDERS_TO_CHECKOUT =>[
	'src'
];

use constant WWW_DOWNLOAD_PATH => '/var/www/html/download';

sub handler {
	my $self = shift;
	my $r    = shift;


	my $args = $r->args();

	my $param_hash = {};
	my @params = split('&', $args);
	map {
		my @param_item = split('=', $_);
		$param_hash->{$param_item[0]} = $param_item[1];
	} @params;

	my $project_path = uri_unescape($param_hash->{project_path}); 
	my $version      = $param_hash->{version};


	$r->content_type('text/html; charset=utf-8');

	if ($project_path){

		if (my $result_html = get_updated_data($project_path, $version)) {
			print qq{
				<h1>Updated JEP Version</h1>
				$result_html
			};
		}		
	} else {

		my $updater = MyService::Jep_Version->new();
		my $supported_versions = $updater->get_supported_versions();

		my $supported_versions_html;
		foreach my $supported_version (@{$supported_versions->{jep_version}}) {
			$supported_versions_html .= "<option value='$supported_version->{version}'>$supported_version->{version}</option>\n"
		}

		$self->print_html(qq{
			
			<h1>Get Updated JEP Version</h1>
			
			<form name="input" action="/Service" method="get">
			SVN path (ex. svn://srvbl08/Project/Module/RestrictionPhoto/Trunk/App):
			<input type="text"   name="project_path" />
			Please select version:
			<select name="version">
				$supported_versions_html
			</select>
			<input type="hidden" name="handler" value="get_updated_jep_project"/>
			<input type="hidden" name="wait" value="0"/>
			<input type="submit" value="Get Updated Project" />
			</form>
			
		});
	}
  
	return Apache2::Const::OK;
}

sub get_updated_data {
	my $svn_path = shift;
	my $version  = shift;

	my $updater = MyService::Jep_Version->new();

	my $local_path;
	$svn_path =~ /\/([^\/]+)(\/)?$/;
	
	my $file_name    = "app_" . `perl -e 'print \$\$;'` . time();
	my $www_path     = &WWW_DOWNLOAD_PATH;
	my $archive_path = "$www_path/$file_name";
	

	foreach my $sub_folder (@{&FOLDERS_TO_CHECKOUT}) {
		$local_path = MyService::SVN::checkout_by_path("$svn_path/$sub_folder");

		mkdir($archive_path) unless (-d $archive_path);

	}


	my $result_html;

	if (-d $archive_path) {
		my $result = $updater->update_version(
			version     => $version,
			source_path => $local_path,
			dest_path   => $archive_path,
		);
		$result_html = '<table>';

		if ($result->{count}) {
			`cd $www_path; zip -rm0 $file_name.zip $file_name 2>&1;`;
		
			$result_html .="<tr><td><a href='/download/$file_name.zip'>Updated project ($result->{count} files found)</a></td></tr>";
		} else {
			$result_html .="<tr><td>0 files was updated</td></tr>";
		}

		foreach my $message (@{$result->{message}}){
			$message =~ s/\n/<br>/g;
			$message =~ s/ /&nbsp;/g;
			$message =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;

			$result_html .="<tr><td>$message</td></tr>";
		}

		$result_html .= '</table>';
		 
	}

	
	return $result_html;
}


1;

