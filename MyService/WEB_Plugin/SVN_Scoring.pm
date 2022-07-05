package MyService::WEB_Plugin::SVN_Project;
  
use strict;
use warnings;

use base "MyService::WEB_Plugin::Abstract";

use MyService::Get_Project_Sync_Order;
use Encode qw(encode);
use Data::Dumper;
use URI::Escape;
  
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use constant COLORS => {
	Branch => '#66CC66',
	Trunk  => '#FF3300',
	Tag    => '#9999FF'
};

sub svn_to_wiki_link {
	my $svn_link = shift;
	my $type     = shift;

	my $wiki_link = $svn_link;
	$wiki_link =~ s/^svn:\/\/srvbl08\/Project\/\///;

#	$wiki_link =~ s/\//%252F/g;
#	Encode::from_to($wiki_link, 'windows-1251', 'utf-8');
#	$wiki_link = uri_escape($wiki_link);

#	$wiki_link = 'http://dwebsrv4.rusfinance.ru:8080/svnwebclient_fix/' . ($type eq 'd' ? 'directoryContent' : 'fileContent') . '.jsp?url=' . $wiki_link;

	$wiki_link = '<a href="http://srvsvn.rusfinance.ru/repo/Project/' . $wiki_link . '" >link</a>';
}

sub handler {
	my $self = shift;
	my $r    = shift;

	$r->content_type('text/html');

	my $args = $r->args();

	my $param_hash = {};
	my @params = split('&', $args);
	map {
		my @param_item = split('=', $_);
		$param_hash->{$param_item[0]} = $param_item[1];
	} @params;

	my $service = $param_hash->{service};
	my $task    = $param_hash->{task}; 

	if ($service eq 'order' && $task){

		my $result = MyService::Get_Project_Sync_Order::get_order($task);


		$self->print_html("\n<h1>$task task analize result</h1>");

		$self->print_html("<table width=\"100%\" border=\"1\" cellpadding=\"2\" cellspacing=\"0\">\n");

		$self->print_html("\t<tr>\n");

		$self->print_html("\t\t<th>\n");
		$self->print_html("\t\t\tPath\n");
		$self->print_html("\t\t</th>\n");

		$self->print_html("\t\t<th>\n");
		$self->print_html("\t\t\tLink to SVN\n");
		$self->print_html("\t\t</th>\n");

		$self->print_html("\t\t<th>\n");
		$self->print_html("\t\t\tLast revision for $task\n");
		$self->print_html("\t\t</th>\n");

#		$self->print_html("\t\t<th>\n");
#		$self->print_html("\t\t\tType\n");
#		$self->print_html("\t\t</th>\n");

		$self->print_html("\t</tr>\n");
		$self->print_html("</table>\n");

		

		foreach my $type_1 ( sort {$a cmp $b} keys %{$result->{splitted_files}}) {

			foreach my $type_2 ( sort {$a cmp $b} keys %{$result->{splitted_files}->{$type_1}}) {


				$self->print_html("<table width=\"100%\" style=\"background:" . &COLORS->{$type_1} . "\">\n");
				$self->print_html("\t<tr>\n");

				$self->print_html("\t\t<th>\n");
				$self->print_html("\t\t\t$type_1 " . ($type_2 ne 'none' ? $type_2 : '') . "\n");
				$self->print_html("\t\t</th>\n");

				foreach my $type_3 ( sort {$a cmp $b} keys %{$result->{splitted_files}->{$type_1}->{$type_2}}) {

					my @files = sort {$result->{splitted_files}->{$type_1}->{$type_2}->{$type_3}->{$a}->{type_2} cmp $result->{splitted_files}->{$type_1}->{$type_2}->{$type_3}->{$b}->{type_2}} 
						sort {$a cmp $b} keys %{$result->{splitted_files}->{$type_1}->{$type_2}->{$type_3}};

					$self->print_html("\t</tr>\n");

					$self->print_html("\t<tr>\n");

        	                
					$self->print_html("\t\t<td>\n");

					$self->print_files_table($result->{files}, \@files);

					$self->print_html("\t\t</td>\n");


					$self->print_html("\t</tr>\n");
				}

				$self->print_html("</table>\n");

				$self->print_html("<br>\n");
			}

		}

		$self->print_html("<br>\n");

		$self->print_html("<table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">\n");
		foreach my $module ( sort {$a cmp $b} keys %{$result->{modules}} ) {

			$self->print_html("\t<tr>\n");

			$self->print_html("\t\t<td>\n");
			$self->print_html("\t\t\t$module\n");
			$self->print_html("\t\t</td>\n");

			$self->print_html("\t\t<td>\n");
			$self->print_html("\t\t\t" . join(',', keys %{$result->{modules}->{$module}}) . "\n");
			$self->print_html("\t\t</td>\n");

			$self->print_html("\t</tr>\n");
		}

		$self->print_html("</table>\n");

	} else {
		$self->print_html(q{
			
			<h1>Task analize</h1>
			
			<form name="input" action="/Service" method="get">
			Task filter:
			<input type="text" name="task" />
			<input type="hidden" name="service" value="order"/>
			<input type="hidden" name="handler" value="find_by_task"/>
			<input type="hidden" name="wait" value="1"/>
			<input type="submit" value="Analize" />
			</form>
			
		});
	}

	$self->print_html("mod_perl 2.0 rocks!\n");

  
	return Apache2::Const::OK;
}

sub print_files_table {
	my $self = shift;
	my $files_hash = shift;
	my $files_list = shift;

		$self->print_html("<table width=\"100%\" border=\"1\" cellpadding=\"2\" cellspacing=\"0\">\n");

		my $type_2 = '';
		my $module = '';
		foreach my $file (@{$files_list}) {
			if ($files_hash->{$file}->{type_2} ne $type_2) {
				$self->print_html("\t<tr style=\"background:" . ($files_hash->{$file}->{type_2} eq 'Doc' ? '#FFFFCC' : '#CCCCFF') .  "; color:black\" >\n");

				$self->print_html("\t\t<th colspan=\"3\">\n");
				$self->print_html("\t\t\t" . $files_hash->{$file}->{type_2} . "\n");
				$self->print_html("\t\t</th>\n");

				$self->print_html("\t</tr>\n");

				$module = '';
			}
			$type_2 = $files_hash->{$file}->{type_2};

			if ($module ne $files_hash->{$file}->{module} && $module ne ''){

				$self->print_html("\t<tr style=\"background:" . ($type_2 eq 'Doc' ? '#FFFFCC' : '#CCCCFF') .  "; color:black\">\n");
				$self->print_html("\t\t<td colspan=\"3\">\n");
				$self->print_html("\t\t\t&nbsp\n");
				$self->print_html("\t\t</td>\n");
				$self->print_html("\t</tr>\n");
                        }
			$module = $files_hash->{$file}->{module};

			if (1 || $files_hash->{$file}->{type} eq 'f') {
				$self->print_html("\t<tr style=\"background:" . ($type_2 eq 'Doc' ? '#FFFFCC' : '#CCCCFF') .  "; color:black\">\n");

				$self->print_html("\t\t<td>\n");
				$self->print_html("\t\t\t$file\n");
				$self->print_html("\t\t</td>\n");
			
				$self->print_html("\t\t<td>\n");
				$self->print_html("\t\t\t" . svn_to_wiki_link($file, $files_hash->{$file}->{type}) . "\n");
				$self->print_html("\t\t</td>\n");
			
				$self->print_html("\t\t<td>\n");
				$self->print_html("\t\t\t" . $files_hash->{$file}->{revision} . "\n");
				$self->print_html("\t\t</td>\n");
			
#				$self->print_html("\t\t<td>\n");
#				$self->print_html("\t\t\t" . $files_hash->{$file}->{type_3} . ' ' . $files_hash->{$file}->{type_4} . $files_hash->{$file}->{type_1} . $files_hash->{$file}->{type_2} . "\n");
#				$self->print_html("\t\t</td>\n");
			
				$self->print_html("\t</tr>\n");
			}

		}
		$self->print_html("</table>\n");

		$self->print_html("<br>\n");
}

1;

