package MyService::SVN;

use strict;

use constant RUSSIFY_COMMAND     => 'unset LC_ALL; export LC_CTYPE="ru_RU.CP1251";';
use constant SOURCE_PATH         => '/var/Project/svn';

sub exec_cvn_command {
	my $command      = shift;

	my $source_path = &SOURCE_PATH;
	my $russify     = &RUSSIFY_COMMAND;

	my $result = `$russify cd $source_path; $command --no-auth-cache --username KosarevA --password kova148 2>&1;`;
}

sub checkout_by_path {
	my $path      = shift;

	my $local_path = get_local_path($path);

	if (-d $path) {
		exec_cvn_command("svn update $local_path -r HEAD --force");
	} 
	
	$local_path =~ s/\/\w+$//;

	unless (-d $path){
		`mkdir -p $local_path`;
		exec_cvn_command("cd $local_path; svn checkout $path");
	}

	return $local_path;
}

sub get_local_path{
	my $svn_path = shift;
	
	my $local_path = $svn_path;

	$local_path =~ s/svn:\/\/\w+\///;
	$local_path = &SOURCE_PATH . '/' . $local_path;

	return $local_path;
}
1;