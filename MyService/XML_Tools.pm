package MyService::XML_Tools;
@ISA = qw(Exporter);

@EXPORT = qw( make_array_hash );

use strict;

sub make_array_hash {
	my %h    = @_;

	my $hash = $h{hash};

	foreach my $item_name (keys %{$hash}) {
		
		my $config = $hash->{$item_name};

		$hash->{$item_name} = [] unless ref($hash) eq 'ARRAY';

		push(@{$hash->{$item_name}}, $config);
	}
}

1;