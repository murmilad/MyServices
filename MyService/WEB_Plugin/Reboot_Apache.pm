package MyService::WEB_Plugin::Reboot_Apache;

use strict;

use base "MyService::WEB_Plugin::Abstract";

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);


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
			my $pid = fork();
			die "fork() failed: $!" unless defined $pid;
		
			unless ($pid) {
				sleep(2);
				$self->print_html(`sudo systemctl restart httpd`);
			}
			
			$self->print_html("<h2>Done</h2>");

		} else {

                $self->print_html(qq|
                	<form name="input" action="/Service" method="post">
                	Restart apache
					<input type="submit" value="Restart apache"/>
					<input type="hidden" name="wait" value="1"/>
					<input type="hidden" name="handler" value="reboot_apache"/>
                	</form>
                |);
			
		}

	return Apache2::Const::OK;

}


1;