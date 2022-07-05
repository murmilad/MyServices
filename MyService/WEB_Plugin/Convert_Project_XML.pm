package MyService::WEB_Plugin::Convert_Project_XML;
  
use strict;
use warnings;

use base "MyService::WEB_Plugin::Abstract";

use Encode qw(encode);
use Data::Dumper;
use URI::Escape;
  
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use constant TEMPORARY_PATH => '/var/homyaki/tmp/';

sub handler {
	my $self = shift;
	my $r    = shift;

	my $req = Apache2::Request->new($r);

	my $param_hash = $self->{param_hash};

	if ($param_hash->{xml_file}){
		$r->content_type('text/html;charset=utf-8');

#		if (open XML_FILE, '>' . &TEMPORARY_PATH . "/$self->{rid}.xml") {
#			binmode(XML_FILE);

			my $xml_file;
			read $param_hash->{xml_file}->{file_handler}, $xml_file, $param_hash->{xml_file}->{file_size};

 #   		print XML_FILE $xml_file;
#			close XML_FILE;

			if (my $result_html = get_xml($xml_file)) {
				if (open XML_FILE, '>' . "/var/www/html/$self->{rid}.xml"){
					#Encode::from_to($result_html, 'utf-8', 'windows-1251');
					print XML_FILE $result_html;
					close XML_FILE;
					
					my $interfaces_list = {};
					while ($xml_file =~/api\s*=\s*["'](.+?)["']/g) {
						my $inteface_api = $1;
						my $short_inteface_api = $inteface_api;
						$short_inteface_api =~ s/Project::Interface_API:://;
						$short_inteface_api =~ s/::/_/g;
						
						$interfaces_list->{uc($short_inteface_api)} = $inteface_api;
					}
					
					my $interfaces = join("<br>\n", sort keys %{$interfaces_list});
					$self->print_html(qq{
						
						<h1>Convert perl XML to java Webengine XML</h1>
						
						<form enctype="multipart/form-data" name="input" action="/Service" method="post">
							<a href="/html/$self->{rid}.xml" download>download Webengine XML</a>
						</form>

						Interfaces list:<br>
						$interfaces
					});
					
					
				} else {
					$self->print_html(qq{
						
						<h1>Convert perl XML to java Webengine XML</h1>
						
						<form enctype="multipart/form-data" name="input" action="/Service" method="post">
							<h2>Can't generate Webengine XML error $!</a>
						</form>
						
					});					
				}
				
			}		
#		} else {
#			print "error $@";
#		}

	} else {
		$r->content_type('text/html');
		$self->print_html(q{
			
			<h1>Convert perl XML to java Webengine XML</h1>
			
			<form enctype="multipart/form-data" name="input" action="/Service" method="post">
			<input type="file"   name="xml_file" />
			<input type="hidden" name="handler" value="convert_project_xml"/>
			<input type="hidden" name="wait" value="0"/>
			<input type="submit" value="Get Java XML" />
			</form>
			
		});
	}
  
	return Apache2::Const::OK;
}

sub get_xml {
	my $project_xml = shift;

#	if (open FILE_XML, "<$file_path") {
#		my $project_xml = "";
#		while  (my $line = <FILE_XML>) {
#			$project_xml .= $line;
#		}
#		close FILE_XML;
		
		$project_xml =~ s/<interface /<interface service="\/JFrontOffice\/interface\/" /g;
		
		while($project_xml =~ s/(<\s*script\s+type\s*=\s*"on_.+?)current(.+?<\/script)/$1this$2/smg){}

		$project_xml =~ s/<\s*script.+?type\s*=\s*"on_(\w+)"\s*>/<script type="$1">/g;

		$project_xml =~ s/(<form_item\s+[^>]+)\/>/$1><\/form_item>/g;

		$project_xml = join_lists($project_xml, "set_visible_list");
		$project_xml = join_lists($project_xml, "ajax_visible_list");
		$project_xml = join_lists($project_xml, "parrent_value");
		$project_xml = join_lists($project_xml, "ajax_parrent_list");
		$project_xml = join_lists($project_xml, "set_result");
		$project_xml = join_lists($project_xml, "set_active_list");

		$project_xml =~ s/set_visible_list/ajax_visible_parrent/g;
		$project_xml =~ s/ajax_visible_list/ajax_visible_parrent/g;
		$project_xml =~ s/parrent_value/ajax_value_parrent/g;
		$project_xml =~ s/set_active_list/ajax_active_parrent/g;
		$project_xml =~ s/ajax_parrent_list/ajax_value_parrent/g;
		$project_xml =~ s/set_result/ajax_value_child/g;
		$project_xml =~ s/parrent_group/parrent_api/g;



		while($project_xml =~ s/(<\s*form_item.+?type\s*=\s*"\w+_list.+?)ajax_value_parrent(.+?<\/form_item)/$1ajax_list_parrent$2/g){}

		$project_xml =~ s///g;
#	} 

	return $project_xml;
}

sub join_lists{
	my $project_xml = shift;
	my $list_name = shift;
	
	my $items_hash = {};
	while($project_xml =~ s/(<\s*form_item.+?name="[^"]+"[^>]+?)${list_name}_\d+\s*=\s*"(\w+)"\s*/$1/){
		$items_hash->{$1} = [] unless $items_hash->{$1}; 
		push (@{$items_hash->{$1}}, $2);
	};
	foreach my $key (keys %{$items_hash}) {
		my $value = join("," , @{$items_hash->{$key}});
		$project_xml =~ s/\Q$key/$key $list_name="$value" /g;
	}
	
	return $project_xml;
}
1;

