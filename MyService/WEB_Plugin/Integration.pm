package MyService::WEB_Plugin::Integration;

use strict;

use base "MyService::WEB_Plugin::Abstract";

use Data::Dumper;

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use MyService::WEB_Plugin::Constants;

use constant SSH_USER => 'IntegrationManager';
use constant SSH_HOST => 'vsmldbscd1.rusfinance.ru';

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

		my $ssh_user = &SSH_USER;
		my $ssh_host = &SSH_HOST;

		if ($param_hash->{server_name} && $param_hash->{package_name}) {

			my $server_hash = $self->print_server_list(0);

			my $package_list = $self->execute_shell_command("ssh $ssh_user\@$ssh_host 'source ~/.bash_profile; cd ~/iman; ./get-env-package-list.sh $param_hash->{server_name}' 2>&1");
			if (
				(grep {$_ eq $param_hash->{package_name}} split ("\n", $package_list)) 
				&& !$server_hash->{$param_hash->{server_name}}->{disabled}
			){
			
				use constant FLAGS => { 
					no_db         => 'no-db',
					no_perl       => 'no-perl',
					no_java       => 'no-app',
					gen_make_bat  => 'gen-make-bat',
					doc_only      => 'doc-only',
				};
			
				my $flags = join (' ', map {'--' . &FLAGS->{$_} if $param_hash->{$_} } keys %{&FLAGS}); 

				my $list = $self->execute_shell_command("ssh $ssh_user\@$ssh_host 'source ~/.bash_profile; cd ~/iman; ./integrate-package.sh -e $param_hash->{server_name} -v $param_hash->{package_name} $flags' 2>&1");

				$self->print_html(qq{<a href="/Service?handler=integration">�����</a>});

				$self->print_server_list(1);

				$self->print_html(qq{<table>});



	
				foreach my $line (split ("\n", $list)) {
					$self->print_html(qq{
							<tr><td>$line</td></tr>
					});
				}
				$self->print_html(qq{<tr><td><a href="/Service?handler=integration">�����</a></td></tr>});
				$self->print_html(q{</table>});
			} else {
				$self->print_server_list(1);
				$self->print_html(qq{<br><h1>��������� ����� "$param_hash->{package_name}" �� �������� ���������� �� ��������� "$param_hash->{server_name}"</h1>});
			}
		} else {
				my $server_hash = $self->print_server_list(1);

				my $select_server_html  = "<option value=''></option>\n";
				my $server_package_html = "<script>\n var serverPackage = {";


				foreach my $server_name (sort {$a cmp $b} keys %{$server_hash}) {

					my $disabled = $server_hash->{$server_name}->{disabled} ? 'disabled' : '';
					$select_server_html .= qq{<option value="$server_name" $disabled> $server_name </option>\n};

					my $package_list = $self->execute_shell_command("ssh $ssh_user\@$ssh_host 'source ~/.bash_profile; cd ~/iman; ./get-env-package-list.sh $server_name' 2>&1");
					my $package_list_js = join(',', map {"'$_'"} split("\n", $package_list));
					
					$server_package_html .= qq{'$server_name':[$package_list_js],};
				}
				
				$server_package_html = substr($server_package_html, 0, length($server_package_html)-1) . "};\n</script>\n"; 

                $self->print_html(qq|
                	<h3>������ �������� ����������</h3>
                	<form name="input" action="/Service" method="post">
                		$server_package_html
                		���������� �������� ��������� ��� ��������� 
                		<select id="server_name" name="server_name" onChange="var packages = document.getElementById('package_name'); while (packages.options.length > 1) { packages.remove(1);} for (currentElement in serverPackage[this.value]) {var packagesElement = document.createElement('option'); packagesElement.value = serverPackage[this.value][currentElement]; packagesElement.text = serverPackage[this.value][currentElement]; try {packages.add(packagesElement, null);} catch(ex) {packages.add(packagesElement);}}">
                			$select_server_html
                		</select><br>
                		���������� �������� ������ ������ ��� ��������� 
                		<select id="package_name" name="package_name">
                			<option value=""></option>
                		</select><br>
	                	<h3>��������� �������� ����������</h3>
                		��������� ��� ���� ������
                		<input type="checkbox" id="no_db" name="no_db" onchange="if (document.getElementById('doc_only').checked && !this.checked) {alert('������� �������� ������������� ������ ������������. ���������� ������� ������� ������������� ������ ������������ � ���������� ����� ����� �������� ��������� ��� ���� ������.'); this.checked = !this.checked;}"/><br>
                		��������� ��� Java
                		<input type="checkbox" id="no_java" name="no_java" onchange="if (document.getElementById('doc_only').checked && !this.checked) {alert('������� �������� ������������� ������ ������������. ���������� ������� ������� ������������� ������ ������������ � ���������� ����� ����� �������� ��������� ��� Java.'); this.checked = !this.checked;}"/><br>
                		��������� ��� Perl
                		<input type="checkbox" id="no_perl" name="no_perl" onchange="if (document.getElementById('doc_only').checked && !this.checked) {alert('������� �������� ������������� ������ ������������. ���������� ������� ������� ������������� ������ ������������ � ���������� ����� ����� �������� ��������� ��� Perl.'); this.checked = !this.checked;} if (document.getElementById('gen_make_bat').checked && this.checked){alert('������� �������� ������������� make.bat. ���������� ������� �������� ������������� make.bat � ���������� ����� ��������� �������� ��������� ��� Perl');  this.checked = !this.checked;}"/><br>
                		������������� make.bat ��� Perl (����������� ������ ��� ��������� � Perl)
                		<input type="checkbox" id="gen_make_bat" name="gen_make_bat" checked onchange="if (this.checked && document.getElementById('no_perl').checked){alert('��������� ������ make.bat �������� ������ � ���������� ������� Perl. ���������� ������� ������� ��� Perl � ���������� ����� ������� ��������� make.bat.'); this.checked=!this.checked;}"/><br>
                		������������� ������ ������������
                		<input type="checkbox" id="doc_only" name="doc_only" onchange="if (this.checked && !document.getElementById('no_db').checked && !document.getElementById('no_java').checked && !document.getElementById('no_perl').checked) {alert('��������� ������������ ����������� �������� �� ��������� ������. ���������� ������� �������� ��� ���� ������, ��� Java, ��� Perl  � ���������� ����� ������� ��������� ������������.'); this.checked = !this.checked;}"/><br>
                		
                		
					<br>
					<input type="submit" value="���������� ��������� �����"/>
					<input type="hidden" name="handler" value="integration"/>
					<input type="hidden" name="wait" value="1">
                	</form>
                |);
			
		}

	return Apache2::Const::OK;

}

sub print_server_list {
	my $self  = shift;
	my $print = shift;


	my $ssh_user = &SSH_USER;
	my $ssh_host = &SSH_HOST;
	
	my $server_hash = {};

	my $server_list = $self->execute_shell_command("ssh $ssh_user\@$ssh_host 'source ~/.bash_profile; cd ~/iman; ./get-environment-status.sh' 2>&1");

	if ($server_list =~ /\d/) {
		$self->print_html(qq{<h2>������� ����������</h2>}) if $print;
		$self->print_html(qq{<h3>������ �������� ����������</h3>}) if $print;
		$self->print_html(qq{<table style="border: 1px solid black; border-collapse: collapse;">}) if $print;
		$self->print_html(qq{<tr><th style="border: 1px solid black;">���</th><th style="border: 1px solid black;">Perl</th><th style="border: 1px solid black;">Java</th><th style="border: 1px solid black;">Oracle</th><th style="border: 1px solid black;">�����</th><th style="border: 1px solid black;">������</th></tr>}) if $print;

		foreach my $line (sort {$a cmp $b} split ("\n", $server_list)) {
			if($line =~ /^([^\s]+)\s+([^\s]*)\s+([^\s]+)/){
				my $name    = $1;
				my $package = $2;
				my $status  = $3;

				my $server_data = `ssh -i /home/nobody/.ssh/nobody $ssh_user\@$ssh_host 'source ~/.bash_profile; cat ~/iman-config/Environment/$name/settings.sh ' 2>&1`;

				$server_data =~ /\s*perlHost\s*=\s*["']([^"']*)["']/;
				my $perl_server = "<a href='http://$1' target='_blank'>$1</a>"; 

				$server_data =~ /\s*envJavaUrl\s*=\s*["']([^"']*)["']/;
				my $java_server = "<a href='$1' target='_blank'>$1</a>"; 
				
				$server_data =~ /\s*projectDbName\s*=\s*["']([^"']*)["']/;
				my $db_server = $1; 

				$self->print_html(qq{
						<tr><td style="border: 1px solid black; padding: 3px;">$name</td><td style="border: 1px solid black; padding: 3px;">$perl_server</td><td style="border: 1px solid black; padding: 3px;">$java_server</td><td style="border: 1px solid black; padding: 3px;">$db_server</td><td style="border: 1px solid black; padding: 3px;">$package</td><td style="border: 1px solid black; padding: 3px;">$status</td></tr>
				}) if $print;
				
				$server_hash->{$name} = {};
				if ($status eq 'IN_PROGRESS') {
					$server_hash->{$name}->{disabled} = 1;
				}
			}
		}
		$self->print_html(q{</table>}) if $print;

	} else {
		$self->print_html(q{<h2>������ ��������� ������ �������� ����������</h2>});
	}

	return $server_hash;
}
#update_file(
#	task => 'P067.T0668',
#	file_path=> '/var/Project/Modules/Module/ExternalBLCheck/Branch/P067.T0668/App/lib/Project/Check_Queue.pm',
#);

1;