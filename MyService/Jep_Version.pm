package MyService::Jep_Version;

use strict;

use XML::Simple;
use Data::Dumper;
use File::Find;

use MyService::XML_Tools;

use constant CHANGES_XML_SVN_PATH => 'svn://srvbl08/Management/Module/DevToolkit/resources/JepVersion';

use constant FILES_TO_COPY =>[
	'\.java$',
];


sub new {
	my $this = shift;

	my %h      = @_;
	my $result = $h{result}; 

	my $self = {
		jep_versions => {},
	};

	my $class = ref($this) || $this;
	bless $self, $class;


	return $self;
}

sub get_supported_versions {
	my $self = shift;

	my $local_path = MyService::SVN::checkout_by_path(&CHANGES_XML_SVN_PATH) . '/JepVersion/';

	opendir(my $dh, $local_path);

	my @version_files = grep {/[\w_\.]+\.xml/i} readdir($dh);

	my $versions_xml = '<jep_replacer>';

	foreach my $version_file_path (@version_files) {
		if (open VERSION_XML, "<$local_path$version_file_path"){
			while (my $str = <VERSION_XML>) {
				$versions_xml .= $str;
			}
			close VERSION_XML;
		}
	}
	$versions_xml .= '</jep_replacer>';
		
	$self->{jep_versions} = XMLin($versions_xml, ForceArray => 1);
	
	
	return $self->{jep_versions};
}

sub update_version {
	my $self = shift;
	my %h    = @_;

	my $version = $h{version};
	my $source_path = $h{source_path};
	my $dest_path   = $h{dest_path};

	unless (keys %{$self->{jep_versions}}) {
		$self->get_supported_versions();
	}

	my $result = {message => [], count => 0};
	if (keys %{$self->{jep_versions}}){

		foreach my $jep_version (sort {compare_version($a, $b)} @{$self->{jep_versions}->{jep_version}}) {
			if (compare_version({version => $version}, $jep_version) > 0){
				last;
			} else {
				my $count = copy_project_files(
					source_path => $source_path,
					dest_path   => $dest_path,
					jep_version => $jep_version,
				);
				
				$result->{count} += $count;

				push(@{$result->{message}}, (@{$jep_version->{message}}));
			}
		}
	}
	return $result;
}

sub compare_version {
	my $a = shift;
	my $b = shift;

	return [split("\\.", $a->{version})]->[0] <=> [split("\\.", $b->{version})]->[0]
	|| [split("\\.", $a->{version})]->[1] <=> [split("\\.", $b->{version})]->[1]
	|| [split("\\.", $a->{version})]->[2] <=> [split("\\.", $b->{version})]->[2]
}

sub copy_project_files {
	my %h    = @_;

	my $source_path = $h{source_path};
	my $dest_path   = $h{dest_path};
	my $jep_version = $h{jep_version};

	my $result = 0;

	find({
			wanted => sub {
			if (-f){
				my $found = 0;
				my $file_path = $File::Find::name;
				my $file_name = $_;

				if (grep {$file_name =~ /$_/i}@{&FILES_TO_COPY}){
					if (open FILE, "<$file_path"){
						my $new_file = '';
						while (my $str = <FILE>) {
							foreach my $replace (@{$jep_version->{replace}}){
								if (
									$replace->{from}->[0]
									&& $replace->{to}->[0]
									&& $str =~ s/\Q$replace->{from}->[0]\E/$replace->{to}->[0]/
								){
									$found = 1;
								};
							}
							$new_file .= $str;
						}

						if ($found) {
							$result++;

							my $path_chunk = $file_path;
							$path_chunk =~ s/$source_path//;
							$path_chunk =~ s/[^\/]+$//;
							unless(-d "$dest_path/$path_chunk") {
								`mkdir -p $dest_path/$path_chunk`;
							}

							if (open NEW_FILE, ">$dest_path/$path_chunk/$file_name") {
								print NEW_FILE $new_file;
								close NEW_FILE;
							}
						}
						close FILE;
					}
				}
			}
		}
	}, $source_path);

	return $result;
}
1;