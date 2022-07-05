package MyService::WEB_Plugin::XLSX_to_HTML;
  
use strict;
use warnings;

use base "MyService::WEB_Plugin::Abstract";

use Encode qw(encode);
use Data::Dumper;
use URI::Escape;
  
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use MyService::Converter::XLSX_To_HTML;

use constant TEMPORARY_PATH => '/var/Project/tmp/';

sub handler {
	my $self = shift;
	my $r    = shift;

	my $req = Apache2::Request->new($r);

	my $param_hash = $self->{param_hash};

	if ($param_hash->{xlsx_file}){
		$r->content_type('text/html;charset=utf-8');

		if (open XLSX_FILE, '>' . &TEMPORARY_PATH . "/$self->{rid}.xlsx") {
			binmode(XLSX_FILE);

			my $xlsx_file;
			read $param_hash->{xlsx_file}->{file_handler}, $xlsx_file, $param_hash->{xlsx_file}->{file_size};

    		print XLSX_FILE $xlsx_file;
			close XLSX_FILE;

			if (my $result_html = get_html(&TEMPORARY_PATH . "/$self->{rid}.xlsx")) {
				if (open HTML_FILE, '>' . "/var/www/html/xlsx_to_html/$self->{rid}.html"){
					Encode::from_to($result_html, 'utf-8', 'windows-1251');
					print HTML_FILE $result_html;
					close HTML_FILE;
					$self->print_html(qq{
						
						<h1>Convert XLSX to HTML</h1>
						
						<form enctype="multipart/form-data" name="input" action="/Service" method="post">
							<a href="/xlsx_to_html/$self->{rid}.html" download>download HTML</a>
						</form>
						
					});
				} else {
					$self->print_html(qq{
						
						<h1>Convert XLSX to HTML</h1>
						
						<form enctype="multipart/form-data" name="input" action="/Service" method="post">
							<h2>Can't generate HTML</a>
						</form>
						
					});					
				}
				
			}		
		} else {
			print "error $@";
		}

	} else {
		$r->content_type('text/html');
		$self->print_html(q{
			
			<h1>Convert XLSX to HTML</h1>
			
			<form enctype="multipart/form-data" name="input" action="/Service" method="post">
			<input type="file"   name="xlsx_file" />
			<input type="hidden" name="handler" value="xlsx_to_html"/>
			<input type="hidden" name="wait" value="0"/>
			<input type="submit" value="Get HTML" />
			</form>
			
		});
	}
  
	return Apache2::Const::OK;
}

sub get_html {
	my $file_path = shift;

	my $html = MyService::Converter::XLSX_To_HTML->convert(
		file_path => $file_path
	);

	return $html;
}
1;

