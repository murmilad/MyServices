package MyService::WEB_Plugin::Find_File;

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

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use constant SVN_MODULES_PATH     => '/var/Project/Modules/';
use constant FIND_FILE_DIR_PATH   => '/var/Project/FindFile/';
use constant FIND_FILE_CACHE_PATH => &FIND_FILE_DIR_PATH . 'list.obj';
use constant SVN_MODULES_URL      => 'svn://srvbl08/Project/Module/';
use constant TIME_FORMAT          => "%YT%mT%d TTTT%H:%M:%S";

use constant RUSSIFY_COMMAND  => 'unset LC_ALL; export LC_CTYPE="ru_RU.CP1251";';


sub load_list_form_txt {

	my $list;

	mkpath(&FIND_FILE_DIR_PATH);

	open LOG, "<" . &FIND_FILE_CACHE_PATH;
	while (my $list_str = <LOG>){
		$list .= $list_str;
	};
	close LOG;

	return $list;
}

sub grep_list_form_txt {
	my $regexp = shift;

	my $list;

	my $cache_path = &FIND_FILE_CACHE_PATH;

	my $list = `grep -E '\/$regexp\$' $cache_path`;

	return $list;
}

sub get_list_to_txt {

	my $current_path = &SVN_MODULES_PATH;
	my $svn_uri      = &SVN_MODULES_URL;

	my $list = `cd ${current_path}Module; svn list -R -r HEAD $svn_uri --username KosarevA --password kova148 --no-auth-cache`;
	
	mkpath(&FIND_FILE_DIR_PATH);

	if ($list) {
		open LOG, ">" . &FIND_FILE_CACHE_PATH;
		print LOG $list;
		close LOG;
	}

	return $list;
}

sub need_reload_cache {

	my $need_reload;
	
	if (-f &FIND_FILE_CACHE_PATH) {

		my $changes_date = strftime( 
    	    &TIME_FORMAT,
			localtime(( stat &FIND_FILE_CACHE_PATH )[9])
		);

		$need_reload = (DateTime::Format::Strptime->new(
    		pattern   => &TIME_FORMAT,
    		locale    => 'ru_RU',
    		time_zone => 'Europe/Moscow',
   		)->parse_datetime($changes_date)->epoch() + 60*60*24) < DateTime->now()->epoch();

	} else {
		$need_reload = 1;
	}
	
	return $need_reload;
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

		if ($param_hash->{file_regexp}) {


			if ($param_hash->{reload_list} || need_reload_cache()) {
				get_list_to_txt();
			}
			my $all_files_txt = grep_list_form_txt($param_hash->{file_regexp});
			my @all_files = split("\n", $all_files_txt);

			$self->print_html(qq{
				<h2>Found </h2>
				<table>
			});

			foreach my $file (grep {$_ =~ /\/$param_hash->{file_regexp}$/} @all_files) {
				
				$self->print_html(qq{
						<tr><td>$file</td></tr>
				});
			}

			$self->print_html(q{</table>});
		} else {
				my $last_update = strftime( 
    	 		   "%d.%m.%Y %H:%M:%S",
					localtime(( stat &FIND_FILE_CACHE_PATH )[9])
				);

                $self->print_html("<h1>Cached ($last_update) find file via Project repo</h1>");
                $self->print_html(qq|
                	<form name="input" action="/Service" method="post">
                	Please input any regexp <input type="text" id="file_regexp" name="file_regexp"/>
					<br>
					Forse update svn (too slow) 
					<input type="checkbox" name="reload_list" value="1"/>
					<br>
					<input type="submit" value="Find file"/>
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