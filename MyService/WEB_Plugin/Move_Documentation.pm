package MyService::WEB_Plugin::Move_Documentation;

use strict;

use base "MyService::WEB_Plugin::Abstract";

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use constant SVN_MODULES_URL      => 'svn://srvbl08/Project/Module/';
use constant RUSSIFY_COMMAND  => 'unset LC_ALL; export LC_CTYPE="ru_RU.CP1251";';

sub get_list {

	my $svn_uri      = &SVN_MODULES_URL;

	my $list = `svn list -r HEAD $svn_uri  --no-auth-cache --username KosarevA --password kova148`;
	
	return $list;
}


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

		if ($param_hash->{'wait'}) {

			my $list = get_list();
			$list =~ s/\n/<br>/g; 


			$self->print_html(qq{
				<h2>Found </h2>
				$list
			});

		} else {

                $self->print_html(qq|
                	<form name="input" action="/Service" method="post">
                	Move documentation from branches
					<input type="submit" value="Move"/>
					<input type="hidden" name="handler" value="find_file"/>
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