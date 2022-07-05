package MyService::WEB_Plugin::Get_Module_Versions;

use strict;

use base "MyService::WEB_Plugin::Abstract";

use POSIX qw(strftime);

use File::Path qw(mkpath);
use File::Find;
use File::Copy;

use Data::Dumper;
use Storable qw{thaw freeze};

use DateTime::Format::Strptime;
use DateTime;

use MyService::Get_Project_Sync_Order;


use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);


use constant SVN_LOGIN      => 'KosarevA';
use constant SVN_PASSWORD   => 'kova148';
use constant BUILD_XML_DEST => '/var/Project/';


sub handler {
		my $self = shift;
        my $r    = shift;

        $r->content_type('text/html');

		my $c          = $r->connection;
  
        my $args = $r->args();

        my $param_hash = {};
		my $req = Apache2::Request->new($r);

		my @params = $req->param();
		map {
			$param_hash->{$_} = $req->param($_);
		} @params;

		if ($param_hash->{get_versions}) {

			my $svn_trunk_tag_list = MyService::Get_Project_Sync_Order::svn_list(
				svn_path => $param_hash->{modules_path},
				flat => 3,
			);



			$self->print_html(qq{
				<h2>Found </h2>
				<table  border="1" style="border-collapse: collapse;" >
				<tr><th>Имя в репозитории</th><th>SVN</th><th>WEB</th><th>Список интерфейсов</th><th>Версия JepRia</th></tr>
			});

			my $modules = [];
			foreach my $svn_java_path (grep {$_ =~ /\/Trunk\/+App$/} sort keys %{$svn_trunk_tag_list}) {
				my $build_properties_name = 'build.properties_' . `perl -e 'print \$\$;'` . time();
				MyService::Get_Project_Sync_Order::exec_cvn_command("svn export $svn_java_path/build.properties " . &BUILD_XML_DEST . "/$build_properties_name --force");
				my $build_properties_exec = 'cat ' . &BUILD_XML_DEST . "/$build_properties_name";
				my $build_properties = `$build_properties_exec`;
				my $build_properties_rm = 'rm ' . &BUILD_XML_DEST . "/$build_properties_name";
				`$build_properties_rm`;
				

				my $dependency_properties_name = 'dependency.properties_' . `perl -e 'print \$\$;'` . time();
				MyService::Get_Project_Sync_Order::exec_cvn_command("svn export $svn_java_path/dependency.properties " . &BUILD_XML_DEST . "/$dependency_properties_name --force");
				my $dependency_properties_exec = 'cat ' . &BUILD_XML_DEST . "/$dependency_properties_name";
				my $dependency_properties = `$dependency_properties_exec`; 
				my $dependency_properties_rm = 'rm ' . &BUILD_XML_DEST . "/$dependency_properties_name";
				`$dependency_properties_rm`;

				my $module = {};

				if ($svn_java_path =~/(^.+\/([^\/]+))\/+Trunk\//) {
					my $svn_path = "$1/Trunk/App";
					my $web_path = "$1/Trunk/App";
					my $name = $2;
					
					$svn_path =~ s/(?<!svn:)\/{2,}/\//g;
					$web_path =~ s/svn:\/\/srvbl08\//http:\/\/srvsvn.rusfinance.ru\/repo\//;

					$module->{name} = $name;
					$module->{svn_path} = "<a href='$svn_path'>svn</a>";
					$module->{web_path} = "<a target='_blank' href='$web_path'>web</a>";
					
				}

				if (
					($build_properties =~ /^\s*JEP_RIA_VERSION\s*=\s*\S*?(\d+\.[^\r\n\s]+)/m || $dependency_properties =~ /^\s*JEPRIA_VERSION\s*=\s*([^\r\n\s]+)/m) 
					&& defined($1)
				) {
					$module->{version} = $1;

					my $app_list = MyService::Get_Project_Sync_Order::svn_list(
						svn_path => "$svn_java_path/src/java/com/technology/",
						flat => 6,
					);

					foreach my $svn_text_path (grep {$_ =~ /\/main\/shared\/text\/.+_Source\.properties/} sort keys %{$app_list}) {
						$svn_text_path =~ /text\/(.+_Source\.properties)/;
						my $text_name = $1;

						my $svn_text_name = "${text_name}_" . `perl -e 'print \$\$;'` . time();
						MyService::Get_Project_Sync_Order::exec_cvn_command("svn export $svn_text_path " . &BUILD_XML_DEST . "/$svn_text_name --force");

						
						my $text_properties_exec = 'cd ' .  &BUILD_XML_DEST . "; iconv -f UTF-8 -t WINDOWS-1251 $svn_text_name > ${svn_text_name}_cp1251; cat ${svn_text_name}_cp1251";
						my $text_properties = `$text_properties_exec`;
						
						my @module_names = ($text_properties =~ /(?<!^module)\.title\s*=\s*([^\r\n]+)/g);
						$module->{names} = join('</td></tr><tr><td>', @module_names);

						$text_properties_exec = 'cd ' .  &BUILD_XML_DEST . "; rm $svn_text_name; rm ${svn_text_name}_cp1251;";
						`$text_properties_exec`;
					}
				}
				push(@{$modules}, $module);
				
			}

			foreach my $module (sort {
				if ($a->{version} =~ /(\d+)\.(\d+)\.(\d+)/) {
					my ($a1,$a2,$a3) = ($1,$2,$3); 
					if ($b->{version} =~ /(\d+)\.(\d+)\.(\d+)/) {
						my ($b1,$b2,$b3) = ($1,$2,$3);
						return $a1 <=> $b1
							|| $a2 <=> $b2
							|| $a3 <=> $b3;
					} else {
						return 1;
					}
				} else {
					if ($b->{version} =~ /(\d+)\.(\d+)\.(\d+)/) {
						return -1;
					} else {
						return 0;
					}
				}
				

			} @{$modules}) {
				if ($module->{version}) {
					$self->print_html(qq{
							<tr><td>$module->{name}</td><td>$module->{svn_path}</td><td>$module->{web_path}</td><td><table><tr><td>$module->{names}</td></tr></table></td><td>$module->{version}</td></tr>
					});
				}
			}
				

			$self->print_html(q{</table>});
		} else {
                $self->print_html("<h1>Get JepRia module versions</h1>");
                $self->print_html(qq|
                	<form name="input" action="/Service" method="post">

					<input type="text" name="modules_path" value="svn://srvbl08/Project/Module/"/>
					<input type="submit" value="Get module versions"/>
					<input type="hidden" name="handler" value="get_module_versions"/>
					<input type="hidden" name="get_versions" value="1"/>
					<input type="hidden" name="wait" value="1"/>
					
                	</form>
                |);
			
		}

	return Apache2::Const::OK;

}
#update_file(
#	task => 'P067.T0668',
#	file_path=> '/var/Project/Modules/Module/ExternalBLCheck/Branch/P067.T0668/App/lib/Project/Check_Queue.pm',
#);

1;