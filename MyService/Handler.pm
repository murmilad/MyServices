package MyService::Handler;

use strict;

use POSIX qw(strftime);


use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Upload;
  
use Apache2::Const -compile => qw(OK);

use MyService::WEB_Plugin::Factory;
use MyService::WEB_Plugin::Constants;


sub handler {
        my $r = shift;

        my $param_hash = {};
		my $req = Apache2::Request->new($r);

		my @params = $req->param();
		map {
			$param_hash->{$_} = $req->param($_);
		} @params;

        $r->content_type('text/html');


		foreach my $upload ($req->upload) {
			if ($param_hash->{$upload}) {
				my $file = $req->upload($upload);
	
				$param_hash->{$upload} = {
					file_handler => $file->upload_fh,
					file_size    => $file->upload_size,
					file_type    => $file->upload_type,
					file_name    => $file->upload_filename,
				};
			}
		}

		my $temporary_html_path = &TEMPORARY_HTML_PATH;
		if ($param_hash->{'rid'}) {
			print `cat $temporary_html_path/$param_hash->{'rid'}.html`;	
		} else {
			print qq{
				<html>
					<head>
						<script type="text/javascript" src="/js/jquery-1.8.3.min.js">
							$.ajaxSetup({scriptCharset: "windows-1251" , contentType: "application/json; charset=windows-1251"});
						</script>
					</head>
				<body>
			};

			my $rid     = $param_hash->{handler} . '_' . `perl -e 'print \$\$;'` . time();
	        my $handler = MyService::WEB_Plugin::Factory->require_web_plugin(
	        	handler    => $param_hash->{handler},
	        	rid        => $rid,
	        	param_hash => $param_hash,
	        );

			if ($param_hash->{'wait'}) {
				my $wait = `cat $temporary_html_path/wait.html`;
				my $clean_wait = $wait;
				$clean_wait =~ s/"/'/g;
				$clean_wait =~ s/\n/ /g;

				my $wait_seconds = $param_hash->{'wait'} * 1000; 
				print qq{
					<script>
						var refresh = function() {
							\$.ajax({
	 							url: "/Service?rid=$rid",
								cache: false,
								success: function(html) {
									\$('#result-placeholder').html(html);
								}
							});
						};
						
					</script>
					<div id="result-placeholder">
				};

				my $wait_html = qq{
					<script>
						setTimeout(function() {
							refresh();
						}, $wait_seconds);
					</script>
					$wait
				}; 
				
				open WAIT_HTML, ">$temporary_html_path/$rid.html";
				print WAIT_HTML $wait_html;
				close WAIT_HTML;

				async_handler($handler, $r, $rid);
			} else {
				$handler->handle_and_print($r, $rid);
			}
			print `cat $temporary_html_path/$rid.html`;

			print '</div>'
				if $param_hash->{'wait'};	

			print '</body></html>';

		}

		return Apache2::Const::OK;
		
}

sub async_handler {
	my $handler = shift;
	my $r       = shift;
	my $rid     = shift;
	my $param_hash = shift;

	my $pid = fork();
	die "fork() failed: $!" unless defined $pid;
		
	unless ($pid) {
		$handler->handle_and_print($r, $rid);
	}
}

1;