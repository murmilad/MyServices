package MyService::Jep_Generator;

use strict;

use XML::Simple;
use Data::Dumper;

use MyService::XML_Tools;

use MyService::Jep_Generator::Factory;
use MyService::Jep_Generator::Jep_Version::Factory;

use constant GENERATOR_ORDER => {
	jep_ria => [
		'db',
		'data_source',
		'form_detail',
		'form_list',
		'record',
		'roles',
		'toolbar',
		'module',    # Must be after roles 
		'string_id', # Must be after module, form_list, form_detail, toolbar
		'header',    # Must be last
	],
	jep_common => [
		'db_common',
		'data_source_common',
		'module_common',
		'form_detail_common',
		'form_list_common',
		'toolbar',
		'record_common',      # Must be after form_detail_common
		'string_id_common',   # Must be after module_common, form_list_common, form_detail_common, toolbar
		'roles_common',
		'header_common',      # Must be last
	]
};

use constant JEP_VERSION => [
	'jep_common',
	'jep_ria',
];

sub get_files_list {
	my $class = shift;
	my %h     = @_;

	my $path  = $h{path};
	my $files = $h{files} || [];

	if (-d $path) {
		if (opendir(my $dh, $path)) {
			my @readdir       = grep {$_ ne '.' && $_ ne '..'} readdir($dh);
			my @dirs          = grep {-d $_} map {"$path/$_"} @readdir;
			my @current_files = grep {-f $_} map {"$path/$_"} @readdir;

			foreach my $file (@current_files) {
				push(@{$files}, $file);
			}

			foreach my $dir (@dirs) {
				$class->get_files_list(
					path  => $dir,
					files => $files,
				);
			}
		}
	}
}

sub get_jep_xml {
	my $class = shift;
	my %h     = @_;

	my $path  = $h{path};

	if (-d $path) {
		my @files;

		$class->get_files_list(
			path  => $path,
			files => \@files,
		);


		my $jep_version = $class->get_jep_version(files => \@files);

		if (&GENERATOR_ORDER->{$jep_version}) {

			my $jep_generators_result = {};
	
			my $jep_generators = [];
			foreach my $generator_handler (@{&GENERATOR_ORDER->{$jep_version}}) {
				if (my $jep_generator = MyService::Jep_Generator::Factory->get_jep_generator(
					handler => $generator_handler,
					result  => $jep_generators_result,
				)) {
					push (@{$jep_generators}, $jep_generator);
				}
			} 

			foreach my $generator (@{$jep_generators}) {
				my $text = {};
				foreach my $file (@files) {
					if ($generator->is_data_file(file => $file)) {
						if (open JAVA_SOURCE, "<$file") {
							while (my $line = <JAVA_SOURCE>) {
								unless ($line =~ /^\s*\/\//) {
									$generator->exec_is_data_line(line=>$line);
									$generator->exec_handle_line(line=>$line);
									$text->{$generator->{current_form}} .= $line;
								}
							}
							close JAVA_SOURCE;
						}
					}
				}
				$generator->exec_handle_text(text=>$text);
			} 
	
			foreach my $jep_generator (@{$jep_generators}) {
				$jep_generator->handle_result();
			} 

			my $jep_xml = $class->get_result_xml(result => $jep_generators_result);
			
			$jep_xml =~ s/(name="[^"]+")\s+(id="\w+")/$2 $1/g;
			$jep_xml =~ s/(name="[^"]+".*)(type="\w+")/$2 $1/g;

			return $jep_xml;
		}
	}
}

sub get_result_xml {
	my $class = shift;

	my %h     = @_;

	my $result = $h{result};

	my $result_xml = XMLout($result, XMLDecl => '<?xml version="1.0" encoding="utf-8"?>', KeepRoot => 1);
	
	$result_xml =~ s/(<)\w+(.*)tag="(\w+)"(\s+\/>)/$1$3$2$4/g;
	$result_xml =~ s/\r"/"/g;

	return $result_xml;
}

sub get_jep_version {
	my $class = shift;

	my %h     = @_;

	my $files = $h{files};

	my $jep_versions = [];

	foreach my $jep_version_handler (@{&JEP_VERSION}) {
		if (my $jep_version = MyService::Jep_Generator::Jep_Version::Factory->get_jep_version(
			handler => $jep_version_handler
		)) {
			push (@{$jep_versions}, $jep_version);
		}
	} 

	foreach my $jep_version (@{$jep_versions}) {
		foreach my $file (@{$files}) {
			if ($jep_version->is_data_file(file => $file)) {
				if (open JAVA_SOURCE, "<$file") {
					while (my $line = <JAVA_SOURCE>) {
						my $is_version = $jep_version->is_version(line=>$line);
						if ($is_version) {
							return $jep_version->JEP_VERSION;
						}
					}
					close JAVA_SOURCE;
				}
			}
		}
	}

	return undef;
}

1;