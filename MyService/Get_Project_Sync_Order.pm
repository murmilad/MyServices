package MyService::Get_Project_Sync_Order;
use Exporter 'import';
@EXPORT_OK = qw(get_svn_tags checkout_tags deploy_tags install_deploy);

use strict;
use LWP::UserAgent;
use XML::Simple;

use File::Path;
use File::Find;
use File::Copy;

use POSIX qw(strftime);
use Storable qw(freeze thaw);

use DateTime::Format::Strptime;
use DateTime;

use Encode;

use Data::Dumper;

use constant RUSSIFY_COMMAND     => 'unset LC_ALL; export LC_CTYPE="ru_RU.CP1251";';

use constant LOG_PATH            => '/var/Project/ums_to_wiki.log';

use constant SOURCE_PATH         => '/var/www/html/project_doc/';

use constant SVN_URL_ROOT        => 'svn://srvbl08/Project/';
use constant SVN_URL             => &SVN_URL_ROOT . 'Module/';

use constant FIND_FILE_DIR_PATH   => '/var/Project/SVN_Project/';
use constant TIME_FORMAT          => "%YT%mT%d TTTT%H:%M:%S";

use constant WIKI_URL            => 'http://dwebsrv4.rusfinance.ru/wiki/index.php'; 
use constant WIKI_LOGIN_URL      => &WIKI_URL . '?title=Special:UserLogin&amp;action=submitlogin&amp;type=login&amp;returnto=Main_Page';

use constant WIKI_LOGIN      => 'robot';
use constant WIKI_PASSWORD   => 'robot1q2w3e4r';

use constant UPDATE_PATH         => '/var/www/html/project_doc/Module/';

use constant UPGRADE_LOG_PATH    => '/var/Project/scn_upgrade_tag.log';
use constant UPGRADE_PATH        => '/var/Project/Upgrade/Source/';
use constant BACKUP_PATH         => '/var/Project/Upgrade/Backup';
use constant CLEAN_PATH          => '/var/Project/Upgrade/Clean';
use constant DELAY_PATH          => '/var/Project/Upgrade/Delay';

use constant PROJECT_PATH => '/www/scn.lo';

use constant JAVA_MODULES => [
	'ScCommon',
	'ScNavigation',
	'ScReports'	
];

use constant ESCAPE_DIR_LIST => [
	'cvs',
	'.svn'
];

use constant CLEAN          => 0;
use constant LOCAL_MODIFIED => 1;
use constant DEPRICATED     => 2;
use constant CLEAN_MODIFIED => 3;
use constant NEW            => 4;

use constant ACTION_MAP => {
	&CLEAN          => 'Clean',
	&LOCAL_MODIFIED => 'Local Modify',
	&DEPRICATED     => 'Depricated',
	&CLEAN_MODIFIED => 'Clean Modify',
	&NEW            => 'New'
};

sub exec_command {
	my $command = shift;
	my $russify = &RUSSIFY_COMMAND;

	my $result = `$russify $command 2>&1;`;

	return $result;
}

sub time_to_str {
	my $time = shift;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	$year += 1900;
	$mon  = sprintf("%02d", $mon + 1);
	$mday = sprintf("%02d", $mday);
	$hour = sprintf("%02d", $hour);
	$min  = sprintf("%02d", $min);
	$sec  = sprintf("%02d", $sec);

	return qq{$year-$mon-$mday $hour:$min:$sec}; 
}

sub date_to_str {
	my $time = shift;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	$year += 1900;
	$mon  = sprintf("%02d", $mon + 1);
	$mday = sprintf("%02d", $mday);

	return qq{$year-$mon-$mday}; 
}

sub upgrade_log {
	my $log_message = shift;

	my $date_time = time_to_str(time());

	my $open_type = -f &UPGRADE_LOG_PATH ? '>>' :'>';

	open LOG, $open_type . &UPGRADE_LOG_PATH;
	print LOG "[$date_time] $log_message\n";
	close LOG;
}

sub exec_cvn_command {
	my $command      = shift;
	my $check_regexp = shift;

	my $source_path = &SOURCE_PATH;
	my $russify     = &RUSSIFY_COMMAND;

	upgrade_log("SVN: $russify cd $source_path; $command --no-auth-cache --username KosarevA --password kova148 2>&1;");
	my $result = `$russify cd $source_path; $command --no-auth-cache --username KosarevA --password kova148 2>&1;`;

	if ($result =~ /$check_regexp/m) {
		return {
			result => $result
		};
	} else {
		return {
			error  => "SVN command '$command' execute error: $result\n"
		};
	}
}

sub check_dir_path {
	my $path = shift;

	$path =~ s/^\///;
	$path =~ s/\/\//\//g;

	my @dir_array = split('/', $path);

	my $mkdir_path = ''; 
	foreach my $dir (@dir_array) {
		$mkdir_path .= "/$dir";
		unless (-d $mkdir_path) {
			mkdir $mkdir_path;
		}
	}
}


sub svn_checkout {
	my $svn_path  = shift;
	my $dest_path = shift;

	check_dir_path($dest_path);              

	my $result = exec_cvn_command('cd ' . $dest_path . '; cd ..; svn checkout ' . &SVN_URL . $svn_path, '^Checked out revision \d+|At revision \d+');	

	if ($result->{error}) {
		upgrade_log("Error: $svn_path \n" . $result->{error});
	} else {
		upgrade_log("$svn_path \n" . $result->{result})
			if $result->{result} =~ /^A|^U|^D/;
	}

	return $result;
};

sub load_log_form_xml {
	my $dest_path = shift;
	$dest_path =~ s/\//_/g;

	my $list_xml;

	mkpath(&FIND_FILE_DIR_PATH);

	open LOG, "<" . &FIND_FILE_DIR_PATH . "/log_$dest_path.xml";
	while (my $list_xml_str = <LOG>){
		$list_xml .= $list_xml_str;
	};
	close LOG;

	return $list_xml;
}

sub get_log_to_xml {
	my $dest_path = shift;

	my $start_revision;
	my $list_xml = load_log_form_xml($dest_path);
	
	my $log = {logentry => []};

	if ($list_xml) {
		($log) = thaw($list_xml);

		$start_revision = (@{$log->{logentry}})[0]->{revision};
	}

	upgrade_log("start_revision = $start_revision");

	my $result = $start_revision 
		? exec_cvn_command('cd ' . &SOURCE_PATH . "/Module; svn log -r HEAD:$start_revision -v --xml $dest_path", '^</log>')
		: exec_cvn_command('cd ' . &SOURCE_PATH . "/Module; svn log -v --xml $dest_path", '^</log>');

	if ($result->{error}) {
		return '';
	} else {
		
		my $new_log = XMLin($result->{result});

		if (ref($new_log->{logentry}) eq 'ARRAY') {
			unshift (@{$log->{logentry}}, @{$new_log->{logentry}});

			$dest_path =~ s/\//_/g;
			mkpath(&FIND_FILE_DIR_PATH);
	
			open LOG, ">" . &FIND_FILE_DIR_PATH . "/log_$dest_path.xml";
			print LOG freeze($log);
			close LOG;


		}

		return $log;
	}
}

sub need_reload_log_cache {
	my $dest_path = shift;

	my $need_reload;

	$dest_path =~ s/\//_/g;
	
	my $file_path = &FIND_FILE_DIR_PATH . "/log_$dest_path.xml";

	if (-f $file_path) {

		my $changes_date = strftime( 
    	    &TIME_FORMAT,
			localtime(( stat $file_path )[9])
		);

		$need_reload = (DateTime::Format::Strptime->new(
    		pattern   => &TIME_FORMAT,
    		locale    => 'ru_RU',
    		time_zone => 'Europe/Moscow',
   		)->parse_datetime($changes_date)->epoch() + 60*60*24) < DateTime->now()->epoch();

	} else {
		$need_reload = 1;
	}
	
#	return $need_reload;
	return 1; # Always need to reload
}

sub svn_log {

	my $dest_path = shift;

	my $log = get_log_to_xml($dest_path);

	if ($log) {
		return $log->{logentry};
	}
};

sub load_list_form_obj {
	my $svn_path = shift || &SVN_URL_ROOT;
	my $flat     = shift;

	my $list_xml;

	mkpath(&FIND_FILE_DIR_PATH);

	$svn_path =~ s/[\/:]/_/g;

	open LOG, "<" . &FIND_FILE_DIR_PATH . "/${flat}_$svn_path.obj";
	while (my $list_xml_str = <LOG>){
		$list_xml .= $list_xml_str;
	};
	close LOG;

	my ($list_array) = thaw($list_xml);
	return $list_array;
}

sub get_list_to_obj {
	my $svn_path = shift || &SVN_URL_ROOT;
	my $flat     = shift;
	my $source_path  = shift || &SOURCE_PATH;

	my $result = exec_cvn_command ('cd ' . $source_path . "; svn list --xml -r HEAD " . ($flat ? '' : '-R ')  . "'" . $svn_path . "'", '.*');	

	$svn_path =~ s/[\/:]/_/g;
	mkpath(&FIND_FILE_DIR_PATH);

	#upgrade_log('result ' . $result->{result});
	if ($result->{result} =~ /non-existent in that revision|Authorization failed/) {
		return '';
	} else {
		my $hash = '';
		eval{
			$hash = XMLin($result->{result});
		};

		if ($@) {
			upgrade_log("XMLin error $@");
		} else {
			open LOG, ">" . &FIND_FILE_DIR_PATH . "/${flat}_$svn_path.obj";
			print LOG  freeze($hash);
			close LOG;
		}

		return $hash;
	}

}

sub need_reload_cache {
	my $svn_path = shift;
	my $flat     = shift;

	my $need_reload;

	$svn_path =~ s/\//_/g;
	
	my $file_path = &FIND_FILE_DIR_PATH . "/${flat}_$svn_path.xml"; 
	if (-f $file_path) {

		my $changes_date = strftime( 
    	    &TIME_FORMAT,
			localtime(( stat $file_path )[9])
		);

		$need_reload = (DateTime::Format::Strptime->new(
    		pattern   => &TIME_FORMAT,
    		locale    => 'ru_RU',
    		time_zone => 'Europe/Moscow',
   		)->parse_datetime($changes_date)->epoch() + 60*10) < DateTime->now()->epoch();

	} else {
		$need_reload = 1;
	}
	
#	return $need_reload;
	return 1; # Always need to reload
}


sub svn_list {
	my %h = @_;
 
	my $svn_path        = $h{svn_path} || '/Module';
	my $files_list_hash = $h{files_list_hash} || {};
	my $flat            = $h{flat};
	my $source          = $h{source};

	my $result_hash;

	if (need_reload_cache($svn_path, $flat)) {
		$result_hash = get_list_to_obj($svn_path, $flat, $source)
	} else {
		$result_hash = load_list_form_obj($svn_path, $flat)
	}
	if ($flat > 1) {
		if ($result_hash) {
			if ($result_hash->{list}->{entry}->{kind} eq 'file'){
			} elsif ($result_hash->{list}->{entry}->{kind} eq 'dir'){
				my $result_sub_hash = svn_list(
					svn_path        => "$svn_path/$result_hash->{list}->{entry}->{name}",
					files_list_hash => $files_list_hash,
					flat            => $flat - 1,
					source          => $source,
				);
	
				$result_hash->{list}->{entry}->{keys %{$result_sub_hash->{list}->{entry}}} = values %{$result_sub_hash->{list}->{entry}};
			} else {
				foreach my $file_path (keys %{$result_hash->{list}->{entry}}) {
					if ($result_hash->{list}->{entry}->{$file_path}->{kind} eq 'dir') {
						my $result_sub_hash = svn_list(
							svn_path        => "$svn_path/$file_path",
							files_list_hash => $files_list_hash,
							flat            => $flat - 1,
							source          => $source,
						);
						
						$result_hash->{list}->{entry}->{keys %{$result_sub_hash->{list}->{entry}}} = values %{$result_sub_hash->{list}->{entry}};
					}
				}
			}
		}
	}
	
	if ($result_hash) {
	
		
		if ($result_hash->{list}->{entry}->{kind} eq 'file'){
			$files_list_hash->{$svn_path}->{type} = 'f';
			$files_list_hash->{$svn_path . '/' . $result_hash->{list}->{entry}->{name}}->{type} = 'f';
		} elsif ($result_hash->{list}->{entry}->{kind} eq 'dir'){
			$files_list_hash->{$svn_path}->{type} = 'd';
			$files_list_hash->{$svn_path . '/' . $result_hash->{list}->{entry}->{name}}->{type} = 'd';
		} else {
			foreach my $file_path (sort keys %{$result_hash->{list}->{entry}}) {
				my $type;
				if ($result_hash->{list}->{entry}->{$file_path}) {
					if ($result_hash->{list}->{entry}->{$file_path}->{kind} eq 'file') {
						$type = 'f';
					} else {
						$type = 'd';
					}
					$files_list_hash->{"$svn_path/$file_path"}->{type} = $type;
				}
		
			}
		}
	}

	return $files_list_hash;
}

sub svn_log_find {
	my $dest_path  = shift;
	my $match_case = shift;

	my $svn_log_list = svn_log($dest_path);
	my $svn_log_list_result = [];

	foreach my $svn_log_item (@{$svn_log_list}) {
		if ($svn_log_item->{msg} =~ /$match_case/) {			
			push (@{$svn_log_list_result}, $svn_log_item);
		}		
	}

	return $svn_log_list_result;
}

sub clean_path {
	my $path = shift;

	$path =~ s/([ ()-+&'])/\\$1/g;

	return $path;
}
sub svn_exists_files_find {
	my $dest_path  = shift;
	my $match_case = shift;

	my $all_foles_hash = {};

	my $svn_log_list = svn_log_find($dest_path, $match_case);

	my $files_hash = {};

#	print Dumper($all_foles_hash);
	
	foreach my $svn_log_item (@{$svn_log_list}) {
		my $revision = $svn_log_item->{revision};
		if ($svn_log_item->{paths}){
			my $path_list = [];
			if (ref($svn_log_item->{paths}->{path}) eq 'ARRAY'){
				push (@{$path_list}, (@{$svn_log_item->{paths}->{path}}));
			} elsif ($svn_log_item->{paths}->{path}){
				push (@{$path_list}, $svn_log_item->{paths}->{path});
			}

			foreach my $path_item (@{$path_list}) {
				my $path = &SVN_URL_ROOT . $path_item->{content};

				Encode::_utf8_off($path);
				Encode::from_to($path, 'utf-8', 'windows-1251');

				my $path_regexp = $path;
				$path_regexp    =~ s/^\/Module\///;
				$path_regexp    = clean_path($path_regexp);
				$path_regexp    =~ s/\//\\\//g;
				upgrade_log("svn_list ($path)");
				

				svn_list(
					svn_path        => $path,
					files_list_hash => $all_foles_hash,
					flat            => 1,
				) unless $all_foles_hash->{$path};


				my $action = $path_item->{action};
				if (
					($action eq 'A' || $action eq 'M')
					&& $all_foles_hash->{$path}
				) {
					if ($files_hash->{$path} < $revision) {
						$files_hash->{$path}->{revision} = $revision;
						$files_hash->{$path}->{type} = $all_foles_hash->{$path}->{type};
					}
				} else {
					upgrade_log("svn_list ($path) is absent");
				}
			}

		}
	}

	upgrade_log("svn_list files_hash " . Dumper($files_hash));
	upgrade_log("svn_list all_foles_hash " . Dumper($all_foles_hash));
	

	return $files_hash;
}

sub get_file_data {
	my $file_path = shift;

	my $file_hash = {};

	upgrade_log("get file data ($file_path)");

	if ($file_path =~ /\/Module\/(\w+)\/(\w+)\/([\w\.]+)(\/[\w\.]+)?(\/[\w\.]+)?/) {

		my $module  = $1;
		my $version = $2;

		my $postfix_group = '';
		my $postfix_1 = '';
		my $postfix_2 = 'none';
		my $postfix_3 = 'none';
		my $postfix_4 = 'Other';
		my $match_1 = $1;
		my $match_2 = $2;
		my $match_3 = $3;
		my $match_4 = $4;
		my $match_5 = $5;
		if ($version =~ /^Tag$/i) {
			$postfix_group = "Tag $match_3";
			$postfix_1 = 'Tag';
			$postfix_2 = "$module $match_3";
			if ($match_4 =~ /^\/Doc$/i){
				$postfix_3 = "Doc";
				if ($match_5 =~ /^\/DB$/i){
					$postfix_4 = "DB";
				} else {
					$postfix_4 = "AppPerl";
				}
			} elsif ($match_4 =~ /^\/AppPerl$/i) {
				$postfix_4 = "AppPerl";
	
			} elsif ($match_4 =~ /^\/DB$/i){
				$postfix_4 = "DB";
			}
		} elsif ($version eq 'Trunk') {
			$postfix_1     = 'Trunk';
			$postfix_group = "Trunk $match_3";
			if ($match_3 =~ /^Doc$/i){
				$postfix_3 = "Doc";
				if ($match_4 =~ /^\/DB$/i){
					$postfix_4 = "DB";
				} else {
					$postfix_4 = "AppPerl";
				}
			} elsif ($match_3 =~ /^AppPerl$/i) {
				$postfix_4 = "AppPerl";
			} elsif ($match_3 =~ /^DB$/i){
				$postfix_4 = "DB";
			}				
		} elsif ($version eq 'Branch'){
			$postfix_group = 'Branch';
			$postfix_1 = 'Branch';
			$postfix_2 = $match_3;
			if ($match_4 =~ /^\/Doc$/i){
				$postfix_3 = "Doc";
				if ($match_5 =~ /^\/DB$/i){
					$postfix_4 = "DB";
				} else {
					$postfix_4 = "AppPerl";
				}
			} elsif ($match_4 =~ /^\/AppPerl$/i) {
				$postfix_4 = "AppPerl";
			} elsif ($match_4 =~ /^\/DB$/i){
				$postfix_4 = "DB";
			}
		} else {
			$postfix_2 = "Other";
		}

		$file_hash->{type_1} = $postfix_4;
		$file_hash->{type_2} = $postfix_3 eq 'none' ? $postfix_4 : $postfix_3;
		$file_hash->{type_3} = $postfix_1;
		$file_hash->{type_4} = $postfix_2;
		$file_hash->{module} = $module;
		$file_hash->{version} = $version;
	}

	return $file_hash;
}

sub get_modules_versions {
	my $dest_path  = shift;
	my $match_case = shift;

	my $files_hash   = svn_exists_files_find($dest_path, $match_case);
	my $modules_hash = {};

	my $splitted_files_hash = {};
	foreach my $file_path (keys %{$files_hash}) {
		my $file_data = get_file_data($file_path);

		if ($file_data) {

			$files_hash->{$file_path}->{type_1} = $file_data->{type_1};
			$files_hash->{$file_path}->{type_2} = $file_data->{type_2};
			$files_hash->{$file_path}->{type_3} = $file_data->{type_3};
			$files_hash->{$file_path}->{type_4} = $file_data->{type_4};
			$files_hash->{$file_path}->{module} = $file_data->{module};

			if ($files_hash->{$file_path}->{type} eq 'f' || $file_data->{version} eq 'Tag') {
				$splitted_files_hash->{$file_data->{type_3}}->{$file_data->{type_4}}->{$file_data->{type_1}}->{$file_path} = $files_hash->{$file_path};

				$modules_hash->{$file_data->{module} . ' ' . $file_data->{version} . ' ' . $file_data->{type_4} . ' ' . $file_data->{type_1} . ' ' . $file_data->{type_2}}->{$files_hash->{$file_path}->{revision}} = 1;
			}
		}
	}

	my @modules_str_array = map {
		$_ . ' ' . join(',', keys %{$modules_hash->{$_}})
	} keys %{$modules_hash};

	@modules_str_array = sort {$a cmp $b} @modules_str_array;

	return {
		files          => $files_hash,
		modules        => $modules_hash,
		splitted_files => $splitted_files_hash
	};
}

sub get_order{
	my $match_case = shift;

	return get_modules_versions(&SVN_URL, $match_case);
}

sub get_svn_tags {
	upgrade_log("SVN log BEGIN ====================================================== ");

	my $modules_hash = svn_list(
			svn_path => &SVN_URL_ROOT . '/Module',
			flat => 1,
	);

	my $last_tags_hash = {};

	foreach my $module_path (keys %{$modules_hash}) {
		if ($modules_hash->{$module_path}->{type} eq 'd') {
			my $tags_hash = svn_list(
				svn_path => "$module_path/Tag",
				flat     => 1,
			);
			upgrade_log("Tags = " . Dumper($tags_hash));

			my ($last_tag) = sort {number_to_str($b) cmp number_to_str($a)} keys %{$tags_hash};
			upgrade_log("LTag = $last_tag");

			if ($last_tag) {
				my $content_hash = svn_list(
					svn_path => $last_tag,
					flat     => 1,
				);
				upgrade_log("Content Tags = " . Dumper($content_hash));
	
				if (grep {$_ =~ /\/AppPerl$/} keys %{$content_hash}) {
					$last_tags_hash->{"$last_tag/AppPerl"} = $content_hash->{"$last_tag/AppPerl"};
					upgrade_log("Last Tag = $last_tag");
				}
			}

		}
	}

	my @last_tags = keys %{$last_tags_hash};

	upgrade_log("SVN log END ====================================================== ");

	return \@last_tags;
}

sub get_svn_trunks {
	upgrade_log("SVN log BEGIN ====================================================== ");

	my $modules_hash = svn_list(
		svn_path => &SVN_URL_ROOT . '/Module',
		flat => 1,
	);

	my $trunks_hash = {};

	foreach my $module_path (keys %{$modules_hash}) {
		if ($modules_hash->{$module_path}->{type} eq 'd') {
			my $content_hash = svn_list(
				svn_path => "$module_path/Trunk",
				flat     => 1,
			);

			if (grep {$_ =~ /\/AppPerl$/} keys %{$content_hash}) {
				$trunks_hash->{"$module_path/Trunk/AppPerl"} = $content_hash->{"$module_path/Trunk/AppPerl"};
				upgrade_log("Trunk = $module_path/Trunk");
			}

		}
	}

	my @trunks = keys %{$trunks_hash};

	upgrade_log("SVN log END ====================================================== ");

	return \@trunks;
}

sub format_number {
	my $number = shift;

	return sprintf("%03d", $number);
}

sub number_to_str {
	my $str_num = shift;	

	$str_num =~ s/(\d+)/format_number($1)/eg;

	return $str_num;
}

sub checkout_tags {
	my $tag_list = shift;

	upgrade_log("SVN checkout BEGIN ====================================================== ");

	my $date_str = date_to_str(time());

	my $target_tags = [];

	foreach my $tag_path (@{$tag_list}){
		unless ($tag_path =~ /DBOptimization/) {

			$tag_path = join ('/', grep {$_ ne 'Module'} split('/' , $tag_path));
	
			my $target = &UPGRADE_PATH . $date_str . '/' .  $tag_path;
	
			svn_checkout($tag_path, $target);
	
			push(@{$target_tags}, $target);
		}
	}

	upgrade_log("SVN checkout END ====================================================== ");

	return $target_tags;
}

sub deploy_tags {
	my $source_tags = shift;

	my $target = &UPGRADE_PATH . '/Deploy';

	rmtree($target);

	mkdir ($target)
		unless (-d $target);

	foreach my $tag_path (@{$source_tags}){
		unless ($tag_path =~ /DBOptimization/) {
			opendir(my $dh, $tag_path);
	    	if (scalar(grep  {!/^(\.svn|\.|\.\.)$/} readdir($dh)) > 0){
				`cp -rf $tag_path/* $target`
	    	}
		}
	}
}

sub get_file_path {
	my $source_path = shift;
	my $target_path = shift;

	$source_path =~ s/\/\//\//g;


	my $shrink_part  = &UPGRADE_PATH . '/Deploy';
	$shrink_part =~ s/\/\//\\\//g;

	$source_path  =~ s/$shrink_part//;

	$target_path = $target_path . $source_path;
	
	my @path_array = split('/', $target_path);
	my $file_name  = pop @path_array;

	$target_path  =~ s/\/$file_name//;
#print "\$target_path = $target_path\n";
	check_dir_path($target_path);

	return "$target_path/$file_name";	
}

sub clean_path {
	my $path = shift;

	$path =~ s/([ ()-+&'])/\\$1/g;

	return $path;
}

sub is_modified {
	my $file_path = shift;

	my $current_date = date_to_str(time());

	my $clean_file_path   = get_file_path($file_path, &CLEAN_PATH);
	my $project_file_path = get_file_path($file_path, &PROJECT_PATH);

	my $repo_file_path    = clean_path($file_path);
	my $result = {};
	upgrade_log("check -f $project_file_path");
	if (-f $project_file_path) {
		my $clean_difference = exec_command(qq{diff -buN $clean_file_path $project_file_path});
		my $repo_difference  = exec_command(qq{diff -buN $project_file_path $repo_file_path});

		if ($repo_difference) {
			if ($clean_difference) {	
				my $current_date = date_to_str(time());
				my $delay_path = get_file_path($file_path, &DELAY_PATH . '/' . $current_date);
	
				copy($file_path, $delay_path)
					or return {error => "Error while delay file copying from '$file_path' to '$delay_path' : $!"};
	
				open DIFF, ">$delay_path.diff";
				print DIFF $repo_difference;
				close DIFF;
	
				copy("$delay_path.diff", "$delay_path.cmp.diff");
	
				open DIFF, ">$delay_path.local.diff";
				print DIFF $clean_difference;
				close DIFF;
	
				upgrade_log("Difference: $file_path");
				upgrade_log("Changes escaped: $project_file_path; Differece: $delay_path.diff");
	
				$result->{result} = &LOCAL_MODIFIED;
			} else {
				$result->{result} = &DEPRICATED;
			}
		} else {
			if ($clean_difference) {
				$result->{result} = &CLEAN_MODIFIED;				
			} else {
				$result->{result} = &CLEAN;
			}
		}
	} else {
		$result->{result} = &NEW;
	}

	upgrade_log("\tAction (" . &ACTION_MAP->{$result->{result}} . "): $file_path");

	return $result;
}


sub upgrade_file {
	my $file_path = shift;


	my $modified;
	my $result = is_modified($file_path);

	if ($result->{error}) {
		return $result->{error};
	} elsif ($result->{result}) {
		$modified = $result->{result};
	}

	if (
		$modified == &DEPRICATED
		|| $modified == &NEW
	) {
		$result = copy_file($file_path);
		return $result->{error} if $result->{error};
	} elsif ($modified == &CLEAN_MODIFIED){
		$result = copy_clean_file($file_path);
		return $result->{error} if $result->{error};
	}

	return '';
}

sub copy_clean_file{
	my $file_path = shift;

	my $target_path  = '';

	if (-f ($file_path)) {
		$target_path = get_file_path($file_path, &CLEAN_PATH);

		copy($file_path, $target_path)
			or return {error => "Error while clean file copying from '$file_path' to '$target_path' : $!"};
	}

	return {};
}

sub copy_file {
	my $file_path = shift;

	my $result;

	my $current_date = date_to_str(time());
	my $project_path = &PROJECT_PATH;
	my $target_path  = '';
	my $result = {};

	if (-f ($file_path)) {
		my $target_proj_path = get_file_path($file_path, &PROJECT_PATH);

		if (-f $target_proj_path){
			my $target_back_path = get_file_path($file_path, &BACKUP_PATH . '/' . $current_date);
			copy($target_proj_path, $target_back_path)
				or return {error => "Error while backup file copying from '$target_proj_path' to '$target_back_path' : $!"};
		}

		$result = copy_clean_file($file_path);
		return $result if $result->{error};


		copy($file_path, $target_proj_path)
			or return {error => "Error while project file copying $file_path : $!"};

		upgrade_log("Upgraded: $file_path");
	}

	return {
		result => 1
	};
}


sub install_deploy {
	
	my $files_list = [];

	my $current_date = date_to_str(time());
	my $delay_path   = &DELAY_PATH . '/' . $current_date;
	my $backup_path  = &BACKUP_PATH . '/' . $current_date;

	upgrade_log("Upgrade BEGIN ====================================================== ");

	rmtree("$delay_path.tmp")
		if (-d "$delay_path.tmp");
	rmtree("$backup_path.tmp")
		if (-d "$backup_path.tmp");

	`mv $delay_path $delay_path.tmp`
		if (-d $delay_path);
	`mv $backup_path $backup_path.tmp`
		if (-d $backup_path);

	rmtree($delay_path)
		if (-d $delay_path);
	rmtree($backup_path)
		if (-d $backup_path);

	my $escape_list = '^' . join('$|^', @{&ESCAPE_DIR_LIST}) . '$';
	$escape_list =~ s/\./\./g;
	
	find({wanted => sub {
			if (-f){
				my $file_path = $File::Find::name;

				my $result = upgrade_file($file_path);
				push (@{$files_list}, $file_path);	
	
				if ($result) {
					upgrade_log("ERROR: $file_path " . $result);
				}	
			}
		},preprocess => sub {
			grep {! /$escape_list/i} @_;
		}
	}, &UPGRADE_PATH . '/Deploy');

	upgrade_log("Upgrade END ====================================================== ");
}

1;
