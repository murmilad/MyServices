package MyService::WEB_Plugin::Get_Integration_Versions;

use strict;

use base "MyService::WEB_Plugin::Abstract";

use Data::Dumper;

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use MyService::WEB_Plugin::Constants;

use constant SSH_USER => 'IntegrationManager';
use constant SSH_HOST => 'srvt14.d.t';

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

		if ($param_hash->{package_name}) {

			my $ssh_user = &SSH_USER;
			my $ssh_host = &SSH_HOST;

			my $list = $self->execute_shell_command("ssh -i /home/nobody/.ssh/nobody $ssh_user\@$ssh_host 'source ~/.bash_profile; cd ~/iman; ./find-module.sh -m $param_hash->{package_name}' 2>&1");
#2014-03-Fix20 1.90.10 Project/Module/Anketa/Tag/1.90.10 PERL 

			if ($list =~ /\d/) {
				$self->print_html(qq{<table>});
				$self->print_html(qq{<tr><th>Module</th><th>Version</th><th>Path</th><th>Package</th></tr>});
	
				foreach my $line (split ("\n", $list)) {
					if($line =~ /^([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/){
						$self->print_html(qq{
								<tr><td>$4</td><td>$2</td><td>$3</td><td>$1</td></tr>
						});
					}
				}
				$self->print_html(q{</table>});
			} else {
				$self->print_html(q{</table>});
				$self->print_html(q{<h2>Can't find any modules</h2>});
			}
		} else {
                $self->print_html(qq|
                	<form name="input" action="/Service" method="post">
                	Please input module name <input type="text" id="package_name" name="package_name"/>
					<br>
					<input type="submit" value="Get versions"/>
					<input type="hidden" name="handler" value="get_integration_versions"/>
					<input type="hidden" name="wait" value="1">
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