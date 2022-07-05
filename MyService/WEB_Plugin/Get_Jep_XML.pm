package MyService::WEB_Plugin::Get_Jep_XML;
  
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
use MyService::Jep_Generator;

use constant FOLDERS_TO_CHECKOUT =>[
	'src'
];

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

	if ($project_path){
		$r->content_type('text/xml');

		if (my $result_xml = get_xml($project_path)) {
			if (open HTML_FILE, '>' . "/var/www/html/get_jep_xml/$self->{rid}.xml"){
				#Encode::from_to($result_xml, 'utf-8', 'windows-1251');
				print HTML_FILE $result_xml;
				close HTML_FILE;
				$self->print_html(qq{
					
					<h1>Get JEP XML</h1>
					
					<a href="/get_jep_xml/$self->{rid}.xml" download>download XML</a>
					
				});
			} else {
				$self->print_html(qq{
					
					<h1>Get JEP XML</h1>
					
					<h2>Can't generate XML</a>
					
				});					
			}

		}		
	} else {
		$r->content_type('text/html');
		$self->print_html(q{
			
			<h1>Get JEP XML</h1>
			
			<form name="input" action="/Service" method="get">
			SVN path (ex. svn://srvbl08/Project/Module/RestrictionPhoto/Trunk/App):
			<input type="text"   name="project_path" />
			<input type="hidden" name="handler" value="get_jep_xml"/>
			<input type="hidden" name="wait" value="0"/>
			<input type="submit" value="Get XML" />
			</form>
			
		});
	}
  
	return Apache2::Const::OK;
}

sub get_xml {
	my $svn_path = shift;


	my $local_path;
	foreach my $sub_folder (@{&FOLDERS_TO_CHECKOUT}) {
		$local_path = MyService::SVN::checkout_by_path("$svn_path/$sub_folder");
	}


	my $result;

	if (-d $local_path) {
		$result = MyService::Jep_Generator->get_jep_xml(path => $local_path);
	}

	return $result;
}
1;

