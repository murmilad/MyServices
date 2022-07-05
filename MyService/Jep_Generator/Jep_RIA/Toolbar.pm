package MyService::Jep_Generator::Jep_RIA::Toolbar;


use strict;

use Data::Dumper;
use XML::Simple;

use base 'MyService::Jep_Generator::Abstract';

use constant DATA_FILES_MASKS => [
	'java/com/technology/\w+/\w+/(\w+)/client/ui/toolbar/\w+ToolBarPresenter\.java$',
	'java/com/technology/\w+/\w+/(\w+)/client/ui/toolbar/\w+ToolBarView(Impl)?\.java$'
];

sub is_data_line {
	my $this = shift;
	my %h    = @_;

	my $line = $h{line};

	
	return 1;
}

sub handle_text {
	my $this = shift;
	my %h    = @_;
	
	my $text = $h{text};


	foreach my $form_name (keys %{$this->{result}}) {

		$this->{result}->{$form_name}->{temporary} = {}                         unless $this->{result}->{$form_name}->{temporary}; 
		$this->{result}->{$form_name}->{temporary}->{toolbar_string_id} = {}  unless $this->{result}->{$form_name}->{temporary}->{toolbar_string_id}; 
		
		$this->{result}->{$form_name}->{toolbar} = {button => []}
			unless $this->{result}->{$form_name}->{toolbar};
	
	
		while ($text->{$form_name} =~ /add(?:Button|Separator)\(\s*(\w+)\s*(?:,.*?\.(\w+)\(\s*\)\s*,\s*.*?\.(\w+)\(\s*\)\s*(?:,\s*.*?\.(\w+)\(\s*\)\s*)?)?\)/igs) {
			my $id     = $1;
			if ($2) {
				my $image  = $2;
				my $disable_image  = $4 ? $3 : undef;
				my $string = $4 || $3;
				
				my $event = $id;
				$event =~ s/_BUTTON_ID//;
				$event = lc($event);
				$event =~ s/(\w)_(\w)/$1 . uc($2)/eg;
				$event .= '()';
				
				if ($text->{$form_name} =~ /bindButton\(\s*$id\s*,\s*new\s*WorkstateEnum\[\]\s*\{([^\}]+)\}\s*,/i) {
					push(@{$this->{result}->{$form_name}->{toolbar}->{button}}, {
						id => $id,
						image => $image,
						imageDisabled => $disable_image, 
						enableStates => $1,
						event => $event,
						text => $string,
					});
				}
				$this->{result}->{$form_name}->{temporary}->{toolbar_string_id}->{$id} = $string;
			} else {
				push(@{$this->{result}->{$form_name}->{toolbar}->{button}}, {
					id => $id,
					tag => 'separator',
				});
			}
		}
	}

}
1;