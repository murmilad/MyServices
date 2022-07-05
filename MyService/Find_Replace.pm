package MyService::Find_Replace;

use strict;

use POSIX qw(strftime);

use File::Path qw(mkpath);
use File::Find;
use File::Copy;

use Data::Dumper;
use Storable qw{thaw freeze};

use MyService::Get_Project_Sync_Order;

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use constant SVN_MODULES_PATH => '/var/Project/Modules/';
use constant SVN_MODULES_URL => 'svn://srvbl08/Project/Module';

use constant RUSSIFY_COMMAND  => 'unset LC_ALL; export LC_CTYPE="ru_RU.CP1251";';



use constant TASK_MAP => {
	'example' => {
		branch     => 'br',
		message    => 'brmess',
		parameters => {
			tables => {
				TABLRE              => {all_fields => 1, pkg_name => 'ttt'},
			}
		},
		check_str => sub {
			my %h = @_;	

			my $string = $h{string};
			my $task   = $h{task};


			my @tables = keys %{$task->{parameters}->{tables}};

			my $table = '';

			unless ( grep {$string =~ /__PACKAGE__->table\('$_'\);/i} @tables){
				($table) = grep {$string =~ /insert\s+into(.+)?\W$_\W/i}  @tables;
			}

			return $table;
			 
		},
		find_cause => '.pm',
		update_str => sub {
			my %h = @_;	
		
			my $string       = $h{string};
			my $task         = $h{task};
			my $check_result = $h{check_result};

			my $result_str = $string;

			if ($result_str !~ /insert\s+into.+\w+ #REPLACE/i) {

				my @tables = keys %{$task->{parameters}->{tables}};
				my $table;
				if (($table) = grep {$string =~ /insert\s+into(.+)?\W$_\W/i}  @tables) {
					if ($result_str !~ /insert\s+into.+$table #REPLACE/i) {
						if ($result_str =~ s/(insert\s+into.+)$table\W/$1$table #REPLACE/i){
							print "\tOK replaced $table\n";
						}
					} else {
						print "\tAlready replaced\n";
					}
				}
			}

			return $result_str;
		}
	},

}; 


sub print_log {
	my $str = shift;

	my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;

	print "[$now_string] $str<br>";

	open LOG,">>/var/Project/log/find_replace.log";
	print LOG  "[$now_string] $str\n";
	close LOG;
}


sub update_file {

	my %h = @_;	

	my $check_result = $h{check_result};
	my $file_path    = $h{file_path};
	my $task         = $h{task};
	my $branch_name  = $task->{branch} || $h{task};

	my $result = 0;

	if (open INPUT_FILE, "<$file_path"){
		if (open OUTPUT_FILE, ">$file_path.tmp"){
			while (my $file_str = <INPUT_FILE>){
				my $new_str = $task->{update_str}(string => $file_str, task => $task, check_result => $check_result);
				if ($file_str ne $new_str){
					$result = $file_path;
				};
				print OUTPUT_FILE $new_str;
			}
			close OUTPUT_FILE;
			move("$file_path.tmp", $file_path);
		} else {
			print_log("Error: Can't open $file_path");
		}
		close INPUT_FILE;
	} else {
		print_log("Error: Can't open $file_path");
	}

	return $result;

}

sub check_file {
	my %h = @_;	

	my $file_path   = $h{file_path};
	my $task        = $h{task};
	my $branch_name = $task->{branch} || $h{task};

	my $result = 0;

	open FILE, "<$file_path";
	while (my $file_str = <FILE>){
		$result = $task->{check_str}(string => $file_str, task => $task);
		last if $result;
	}
	close FILE;

	return $result;
}

sub get_files_list {
	my %h = @_;	

	my $task         = $h{task}  || return {error => 'task undefined'};
	my $branch_name  = $task->{branch} || return {error => 'branch undefined'};
	my $svn_replase = $h{svn_replase};
	my $svn_update  = $h{svn_update};

	my $all_files_list    = {};	
	my $module_files_list = {};	
	my $absent_files_list = {};	

	if ($svn_replase) {

		my $rm_cmd = 'rm -rf ' . &SVN_MODULES_PATH . '/Module/*';
		
		my $rm_result = `$rm_cmd`;
		print_log($rm_result);
		

		print_log("get_svn_trunks");

		my $trunk_paths = MyService::Get_Project_Sync_Order::get_svn_trunks();
		$trunk_paths = [(@{$trunk_paths}, map {my $branch = $_; $branch =~ s/\/Trunk\/AppPerl/\/Branch/; $branch} @{$trunk_paths})];

		map {$_ =~ s/\/Module//} @{$trunk_paths};

		print_log(Dumper($trunk_paths));

		foreach my $trunk_path (@{$trunk_paths}) {
			my $module_path = $trunk_path;
			my $svn_modules_url  = &SVN_MODULES_URL;
			my $svn_modules_path = &SVN_MODULES_PATH;
			$module_path =~ s /$svn_modules_url//;
			$module_path =~ s /\/[^\/]+(\/+)?$/$1/;
			unless (-d "$svn_modules_path/Module/$module_path"){
				mkpath("$svn_modules_path/Module/$module_path");
				sleep 2;
			}

			my $recursive = '';
			if ($trunk_path =~ /Branch/){
				
				$recursive = '-N';
			}

			print_log("cd $svn_modules_path/Module/$module_path; svn checkout $recursive $svn_modules_url/$trunk_path");
			exec_cvn_command("cd $svn_modules_path/Module/$module_path; svn checkout $recursive $svn_modules_url/$trunk_path <login> ");

			if ($trunk_path =~ /Branch/){
				print_log("cd $svn_modules_path/Module/$module_path/Branch; svn checkout $svn_modules_url/$trunk_path/$branch_name");
				exec_cvn_command("cd $svn_modules_path/Module/$module_path/Branch; svn checkout $svn_modules_url/$trunk_path/$branch_name <login> ");
			}

		}

	} elsif ($svn_update) {

		exec_cvn_command('svn update ' . &SVN_MODULES_PATH . '/Module/ <login>');
	}

	my $find_cause = $task->{find_cause};

	find({wanted => sub {
			if (-f){
				my $file_path = $File::Find::name;
				my $file_name = $_;

				if (
					$file_path =~ /$find_cause$/i 
					&& $file_path =~ /(.*\/DBOptimization)\/Trunk\/(.*)$file_name/
					&& $file_path !~ /\/\.svn\//
				){
					if (
						!$module_files_list->{$2 . $file_name}
						&& (my $result = check_file(file_path => $file_path, task => $task))
					){
						$all_files_list->{$2 . $file_name}->{module_path} = $1;
						$all_files_list->{$2 . $file_name}->{path}   = $file_path;
						$all_files_list->{$2 . $file_name}->{name}   = $file_name;
						$all_files_list->{$2 . $file_name}->{result} = $result;	
					}
				} elsif (
					$file_path =~ /$find_cause$/i
					&& $file_path =~ /^(.*)\/Trunk\/(.*)$file_name/
					&& (my $result = check_file(file_path => $file_path, task => $task))
					&& $file_path !~ /\/\.svn\//
				){
					$module_files_list->{$2 . $file_name}->{module_path} = $1;
					$module_files_list->{$2 . $file_name}->{path} = $file_path;
					$module_files_list->{$2 . $file_name}->{name} = $file_name;	
					$module_files_list->{$2 . $file_name}->{result} = $result;	

					$all_files_list->{$2 . $file_name}->{module_path} = $1;
					$all_files_list->{$2 . $file_name}->{path}   = $file_path;
					$all_files_list->{$2 . $file_name}->{name}   = $file_name;
					$all_files_list->{$2 . $file_name}->{result} = $result;	
				}
			}
		}
	}, &SVN_MODULES_PATH);

	foreach my $file_name (keys %{$all_files_list}){
		unless ($module_files_list->{$file_name}){
			$absent_files_list->{$file_name}->{module_path} = $all_files_list->{$file_name}->{module_path}; 
			$absent_files_list->{$file_name}->{path} = $all_files_list->{$file_name}->{path}; 
			$absent_files_list->{$file_name}->{name} = $all_files_list->{$file_name}->{name}; 
			$absent_files_list->{$file_name}->{result} = $all_files_list->{$file_name}->{result}; 
		}
	}

	print_log("Found: all_files_list = " . Dumper($all_files_list));
	print_log("Found: module_files_list = " . Dumper($module_files_list));
	print_log("Found: absent_files_list = " . Dumper($absent_files_list));
	return {
		all_files_list    => $all_files_list,
		module_files_list => $module_files_list,
		absent_files_list => $absent_files_list,
	};		
}

sub create_branches {
	my %h = @_;	

	my $task              = $h{task}        || return {error => 'task undefined'};
	my $branch_name       = $task->{branch} || return {error => 'branch undefined'};
	my $all_files_list    = $h{all_files_list};
	my $module_files_list = $h{module_files_list};
	my $absent_files_list = $h{absent_files_list};

	my $message = $task->{message};

	foreach my $file_name (keys %{$all_files_list}) {
		my $module_path  = $all_files_list->{$file_name}->{module_path};
		my $source_path  = $all_files_list->{$file_name}->{path};
		my $name         = $all_files_list->{$file_name}->{name};
		my $check_result = $all_files_list->{$file_name}->{result};
		my $file_path    = $file_name;
		$file_path =~ s/$name$//;
	
	 
		my $dest_path = $module_path . '/Branch/' . $branch_name . '/' . $file_path;
		$all_files_list->{$file_name}->{dest_path} = $dest_path;

		print_log("Change $source_path:\n\t$dest_path$name");
		unless (-f "$dest_path$name"){

			unless (-d "$dest_path"){
				mkpath($dest_path);
				sleep 2;
			}

			unless (-d "$module_path/Branch/$branch_name/.svn"){
				exec_cvn_command("cd $module_path/Branch; svn add $module_path/Branch/$branch_name");
			}

			my $dir_path = '';
			foreach my $dir (split('/', $file_path)){
				my $current_path = $dir_path;
				$dir_path .= '/' . $dir;

				unless (-d "$module_path/Branch/$branch_name$dir_path/.svn"){
					exec_cvn_command("cd $module_path/Branch/$branch_name$current_path; svn add $module_path/Branch/$branch_name$dir_path");
				}
			}

			exec_cvn_command("svn copy $source_path $dest_path$name <login> ");
			

			exec_cvn_command("svn commit $module_path/Branch/$branch_name -m '$message (start version)' <login> ");
			
		}
	}

	my $updated_files = [];
	foreach my $file_name (keys %{$all_files_list}) {
		my $module_path  = $all_files_list->{$file_name}->{module_path};
		my $dest_path    = $all_files_list->{$file_name}->{dest_path};
		my $name         = $all_files_list->{$file_name}->{name};
		my $check_result = $all_files_list->{$file_name}->{result};

		my $result = update_file(file_path => "$dest_path$name", task => $task, check_result => $check_result);		
		
		if ($result) {
			exec_cvn_command("svn commit $module_path/Branch/$branch_name -m '$message' <login> ");
			push(@{$updated_files}, "$module_path/Branch/$branch_name/$file_name");
		}

	}

	foreach my $file_name (keys %{$all_files_list}) {
		my $source_path = $all_files_list->{$file_name}->{path};

		print_log(qq{Finded: $source_path});
	}	

	my $new_files = [];

	foreach my $file_name (keys %{$absent_files_list}) {
		my $source_path = $absent_files_list->{$file_name}->{path};

		push(@{$new_files}, "$source_path");
		
		print_log(qq{Look: $source_path});
	}

	return {
		new_files     => $new_files,
		updated_files => $updated_files,
	};
}


sub exec_cvn_command {
	my $command     = shift;

	$command =~ s/<login>/--username KosarevA --password kova148/;
	my $russify     = &RUSSIFY_COMMAND;

	print_log("$russify $command");
	sleep 2;
	system ("$russify $command;");

	if ($? == -1) {
        print_log("failed to execute: $!");
    }
    elsif ($? & 127) {
        print_log(sprintf "child died with signal %d, %s coredump",
            ($? & 127),  ($? & 128) ? 'with' : 'without');
    }
    else {
        print_log(sprintf "child exited with value %d", $? >> 8);
    }

#	MyService::Get_Project_Sync_Order::exec_cvn_command($command);

#	my $russify = &RUSSIFY_COMMAND;


#	print "\t\t$russify svn $command 2>&1;\n";
#	my $result = `$russify svn $command 2>&1;`;
#	print "\t\t Result: $result\n";
}

sub find_replase {
	my %h = @_;
	
	my $task_command    = $h{task_command};
	my $old_find_params = $h{old_find_params};

	my $task = {};


	eval "\$task = {$task_command};";

	if ($@) {
		return {
			error => $@
		};
	} else {

		print q{
			<input type="hidden" name="helper_enubled" value="false" id="helper_enubled">
			<span onclick="
							if (document.getElementById('helper_enubled').value == 'false') {
								document.getElementById('helper').style.display = 'inline';
								document.getElementById('helper_enubled').value = 'true';
							} else {
								document.getElementById('helper').style.display = 'none';
								document.getElementById('helper_enubled').value = 'false';
							}
						">
			Click for log
			</span>			
			<div style="display: none; " id="helper">
		};
		my $files_list = get_files_list(
			task        => $task,
#			svn_replase => 1,
			svn_update  => 1,
		);

		if ($files_list->{error}) {		
			print q{</div>};
			return {
				error => $files_list->{error}
			};
		}

		my $result = create_branches(
			task => $task,
			all_files_list    => $files_list->{all_files_list},
			module_files_list => $files_list->{module_files_list},
			absent_files_list => $files_list->{absent_files_list},
		);

		print q{</div>};
		return {
			error => $result->{error}
		} if $result->{error};
		
		return {
			new_files     => $result->{new_files},
			updated_files => $result->{updated_files},
		}		
	}
};

sub handler {
        my $r = shift;

        $r->content_type('text/html');

		my $c          = $r->connection;
  
        my $args = $r->args();

        my $param_hash = {};
		my $req = Apache2::Request->new($r);

		my @params = $req->param();
		map {
			$param_hash->{$_} = $req->param($_);
		} @params;

		my $old_find_params = [];

		opendir(my $dh, '/var/Project/log/find_replace');
    	my @find_reqs = sort grep { /find_requst_\d+/ } readdir($dh);
	    closedir $dh;		

		foreach my $find_req_path (@find_reqs) {
			if (open FIND_PARAMS_OBJ, "</var/Project/log/find_replace/$find_req_path") {
				my $old_find_params_obj = '';
				while (my $string = <FIND_PARAMS_OBJ>){
					$old_find_params_obj .= $string;
				}
			 
				close FIND_PARAMS_OBJ;
				push(@{$old_find_params}, $old_find_params_obj)
					if $old_find_params_obj;
			} else {
				print_log("$! /var/Project/log/find_replace/$find_req_path");
			}
		}
		if ($param_hash->{task}) {

			open FIND_REQUEST, '>/var/Project/log/find_replace/find_requst_' . time();
			print FIND_REQUEST $param_hash->{task};
			close FIND_REQUEST;

			my $result = find_replase(
				task_command => $param_hash->{task},
				old_find_params => $old_find_params,
			);

            print "<html>\n<body>\n<h1>Find/Replace result</h1>";
			if ($result->{error}) {
	            print "Error: $result->{error}";
			} else {

				print q{
					<h2>Updated</h2>
					<table>
				};
				foreach my $file_path (@{$result->{updated_files}}){
					print qq{
							<tr><td>$file_path</td></tr>
					};
				}
				print q{
					</table>
					<h2>Look</h2>
					<table>
				};
				foreach my $file_path (@{$result->{new_files}}){
					print qq{
							<tr><td>$file_path</td></tr>
					};
				}
				print q{</table>};
			}
            print "</body>\n</html>";
		} else {
				my $select_old;
				if (scalar(@{$old_find_params}) > 0) {

					my $param_map = join(',', map {
						my $params_str = $_;
						$params_str=~s/\\/\\\\/g;
						$params_str=~s/"/\\"/g;
						$params_str=~s/\$/\\\$/g;
						$params_str=~s/(.)(\n)/\\n\\$1$2/g;
						qq{"$params_str"}
					} @{$old_find_params});

					$select_old = qq{
						<select id="old_criteries" name="old_criteries" onchange="onChangeOldCriteries(this)">
						<script>
							var parameterMap = ['', $param_map];
							function onChangeOldCriteries(current){
								document.getElementById('task').value = parameterMap[current.value];
							}
						</script>
						<option value="0">&nbsp;</option> 
					};
					for (my $i=1; $i <= @{$old_find_params}; $i++) {
						my $old_criterie = $old_find_params->[$i-1];
						eval "\$old_criterie={$old_criterie};";

						$select_old .= qq{
							<option value="$i">$old_criterie->{branch} ($i)</option>
						};
					}
					$select_old .=q{
						</select>
						<br>
					};
				}
                print "<html>\n<body>\n<h1>Enter Find/Replace data</h1>";
                print qq|
                	<form name="input" action="/Find_Replace" method="post">
                	$select_old 
                	<textarea id="task" name="task" style="height:980; width:100%;" WRAP=OFF>
                	</textarea>
					<br>
					<input type="submit" value="Find/Replace"/>
                	</form>
                |;
                print "</body>\n</html>";
			
		}

	return Apache2::Const::OK;

}
#update_file(
#	task => 'P067.T0668',
#	file_path=> '/var/Project/Modules/Module/ExternalBLCheck/Branch/P067.T0668/App/lib/Project/Check_Queue.pm',
#);

1;