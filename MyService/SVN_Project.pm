package MyService::SVN_Project;
  
use strict;
use warnings;

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
	$wiki_link =~ s/^\///;

#	$wiki_link =~ s/\//%252F/g;
	Encode::from_to($wiki_link, 'windows-1251', 'utf-8');
	$wiki_link = uri_escape(uri_escape($wiki_link));

	$wiki_link = 'http://dwebsrv4.rusfinance.ru:8080/svnwebclient_fix/' . ($type eq 'd' ? 'directoryContent' : 'fileContent') . '.jsp?url=' . $wiki_link;

	$wiki_link = '<a href="' . $wiki_link . '" >link</a>';
}

sub handler {
	my $r = shift;

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

		print "<!--\n";
		print "Deleted files:\n";

		my $result = MyService::Get_Project_Sync_Order::get_order($task);

		print "-->\n";

		print "<html>\n<body>\n<h1>$task task analize result</h1>";

		print "<table width=\"100%\" border=\"1\" cellpadding=\"2\" cellspacing=\"0\">\n";

		print "\t<tr>\n";

		print "\t\t<th>\n";
		print "\t\t\tPath\n";
		print "\t\t</th>\n";

		print "\t\t<th>\n";
		print "\t\t\tLink to SVN\n";
		print "\t\t</th>\n";

		print "\t\t<th>\n";
		print "\t\t\tLast revision for $task\n";
		print "\t\t</th>\n";

#		print "\t\t<th>\n";
#		print "\t\t\tType\n";
#		print "\t\t</th>\n";

		print "\t</tr>\n";
		print "</table>\n";

		

		foreach my $type_1 ( sort {$a cmp $b} keys %{$result->{splitted_files}}) {

			foreach my $type_2 ( sort {$a cmp $b} keys %{$result->{splitted_files}->{$type_1}}) {


				print "<table width=\"100%\" style=\"background:" . &COLORS->{$type_1} . "\">\n";
				print "\t<tr>\n";

				print "\t\t<th>\n";
				print "\t\t\t$type_1 " . ($type_2 ne 'none' ? $type_2 : '') . "\n";
				print "\t\t</th>\n";

				foreach my $type_3 ( sort {$a cmp $b} keys %{$result->{splitted_files}->{$type_1}->{$type_2}}) {

					my @files = sort {$result->{splitted_files}->{$type_1}->{$type_2}->{$type_3}->{$a}->{type_2} cmp $result->{splitted_files}->{$type_1}->{$type_2}->{$type_3}->{$b}->{type_2}} 
						sort {$a cmp $b} keys %{$result->{splitted_files}->{$type_1}->{$type_2}->{$type_3}};

					print "\t</tr>\n";

					print "\t<tr>\n";

        	                
					print "\t\t<td>\n";

					print_files_table($result->{files}, \@files);

					print "\t\t</td>\n";


					print "\t</tr>\n";
				}

				print "</table>\n";

				print "<br>\n";
			}

		}

		print "<br>\n";

		print "<table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">\n";
		foreach my $module ( sort {$a cmp $b} keys %{$result->{modules}} ) {

			print "\t<tr>\n";

			print "\t\t<td>\n";
			print "\t\t\t$module\n";
			print "\t\t</td>\n";

			print "\t\t<td>\n";
			print "\t\t\t" . join(',', keys %{$result->{modules}->{$module}}) . "\n";
			print "\t\t</td>\n";

			print "\t</tr>\n";
		}

		print "</table>\n";

	}
  

	print "mod_perl 2.0 rocks!\n";

	print "</body>\n</html>\n";
  
	return Apache2::Const::OK;
}

sub print_files_table {
	my $files_hash = shift;
	my $files_list = shift;

		print "<table width=\"100%\" border=\"1\" cellpadding=\"2\" cellspacing=\"0\">\n";

		my $type_2 = '';
		my $module = '';
		foreach my $file (@{$files_list}) {
			if ($files_hash->{$file}->{type_2} ne $type_2) {
				print "\t<tr style=\"background:" . ($files_hash->{$file}->{type_2} eq 'Doc' ? '#FFFFCC' : '#CCCCFF') .  "; color:black\" >\n";

				print "\t\t<th colspan=\"3\">\n";
				print "\t\t\t" . $files_hash->{$file}->{type_2} . "\n";
				print "\t\t</th>\n";

				print "\t</tr>\n";

				$module = '';
			}
			$type_2 = $files_hash->{$file}->{type_2};

			if ($module ne $files_hash->{$file}->{module} && $module ne ''){

				print "\t<tr style=\"background:" . ($type_2 eq 'Doc' ? '#FFFFCC' : '#CCCCFF') .  "; color:black\">\n";
				print "\t\t<td colspan=\"3\">\n";
				print "\t\t\t&nbsp\n";
				print "\t\t</td>\n";
				print "\t</tr>\n";
                        }
			$module = $files_hash->{$file}->{module};

			if (1 || $files_hash->{$file}->{type} eq 'f') {
				print "\t<tr style=\"background:" . ($type_2 eq 'Doc' ? '#FFFFCC' : '#CCCCFF') .  "; color:black\">\n";

				print "\t\t<td>\n";
				print "\t\t\t$file\n";
				print "\t\t</td>\n";
			
				print "\t\t<td>\n";
				print "\t\t\t" . svn_to_wiki_link($file, $files_hash->{$file}->{type}) . "\n";
				print "\t\t</td>\n";
			
				print "\t\t<td>\n";
				print "\t\t\t" . $files_hash->{$file}->{revision} . "\n";
				print "\t\t</td>\n";
			
#				print "\t\t<td>\n";
#				print "\t\t\t" . $files_hash->{$file}->{type_3} . ' ' . $files_hash->{$file}->{type_4} . $files_hash->{$file}->{type_1} . $files_hash->{$file}->{type_2} . "\n";
#				print "\t\t</td>\n";
			
				print "\t</tr>\n";
			}

		}
		print "</table>\n";

		print "<br>\n";
}

1;

