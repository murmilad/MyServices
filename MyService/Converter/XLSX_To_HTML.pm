package MyService::Converter::XLSX_To_HTML;

use strict;

use SimpleXlsx;

use Data::Dumper;
use Encode;

use constant BORDER_PARAMETERS_ORDER => [
	'Top',
	'Right',
	'Bottom',
	'Left',
];

use constant FONT_MAP => {
	Arial          => 'font-family:Arial,Helvetica,sans-serif;',
	'Arial Narrow' => 'font-family:Arial Narrow;',
	Times          => 'font-family:"Times New Roman",Times,serif;',
	Calibri        => 'font-family:Calibri, sans-serif;',
	
};

use constant ALIGNMENT_MAP => {
	center => 'text-align:center;',
	left   => 'text-align:left;',
	right  => 'text-align:right;',
};

use constant BORDER_WIDTH_MAP => {
	thin   => '1px',
	medium => '2.5px',
};
 
use constant DEFAULT_FONT      => 'font-family:Arial,Helvetica,sans-serif;'; 
use constant DEFAULT_ALIGNMENT => 'text-align:left;';

use constant PX_COEF => 7.591; 
use constant FONT_COEF => 1.4; 

sub join_styles {
	my $source_style = shift;
	my $dest_style   = shift;

	foreach my $param_name (@{&BORDER_PARAMETERS_ORDER}) {
		$dest_style->{$param_name}->{Style} = $source_style->{$param_name}->{Style} 
			unless $dest_style->{$param_name}->{Style};

		$dest_style->{$param_name}->{Color} = $source_style->{$param_name}->{Color} 
			unless $dest_style->{$param_name}->{Color};
	}
}

sub convert {
	my $self = shift;
	my %h    = @_;

	my $file_path = $h{file_path};

	my($xlsx)       = SimpleXlsx->new();
	my($worksheets) = $xlsx->parse($file_path);


#	print Dumper($worksheets);

	my $html;

	if ($worksheets && $worksheets->{sheet1}){

		# Colspan processing

		my $colspans = {};
		foreach my $row_number (keys %{$worksheets->{sheet1}->{Merge}}) {
			foreach my $connection (@{$worksheets->{sheet1}->{Merge}->{$row_number}}) {

				my $from_col;
				map {$from_col = $from_col * 26 + ord($_)-64} split("|", $connection->{From}->{Column});
				
				my $to_col;
				map {$to_col = $to_col * 26 + ord($_)-64} split("|", $connection->{To}->{Column});

				$colspans->{$row_number}->{$from_col-1}->{colspan} = $to_col - $from_col + 1;
				$colspans->{$row_number}->{$from_col-1}->{size}    = $worksheets->{sheet1}->{Columns_Size}->[$from_col-1];

				# Joined cells style merging
				my $cell_style = {}; 
				join_styles($worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$from_col-1]->{Border}, $cell_style);

				for (my $i = 0; $i < $to_col - $from_col; $i++) {
					$colspans->{$row_number}->{$from_col + $i}->{in_colspan} = 1;
					$colspans->{$row_number}->{$from_col-1}->{size} += $worksheets->{sheet1}->{Columns_Size}->[$from_col + $i] + 0.3;
					# Joined cells style merging
					join_styles($worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$from_col + $i]->{Border}, $cell_style);
				}

				# Joined cells style merging
				$worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$from_col-1]->{Border} = $cell_style; # Joined cells style merging
			}
		}

		my $columns_count = scalar(@{$worksheets->{sheet1}->{Columns}});
		my $table_width = 0;
		my $base_row_html = '';

		# Col width processing 
		for (my $col_number = 0; $col_number < $columns_count; $col_number++){
			my $col_width = $worksheets->{sheet1}->{Columns_Size}->[$col_number];
			$table_width += $col_width; 
			$base_row_html .= '<td style="width:' . sprintf("%.2f", $col_width * &PX_COEF) . 'px" ></td>';
		}
		$table_width = sprintf("%.2f", $table_width * &PX_COEF);

		$html = qq{
			<style>
	
				table.project {
					padding:0px;
					margin:0px;
					font-size:12px;

					border-collapse:collapse;
					border-color:black;
					width:${table_width}px
				}
				td.project {
					padding:1px;
					margin:0px;
					border-width:1px;
					vertical-align:top;
				}
				p.project, div.project {
					margin-top:1.0pt;
					margin-right:0cm;
					margin-bottom:1.0pt;
					margin-left:0cm;
					text-indent:0cm;
				}
			</style>
			
			<table class="project">
		};

		if ($columns_count) {
	
			$html .= qq{
				<tr> $base_row_html </tr>
			};

			foreach my $row_number (@{$worksheets->{sheet1}->{Rows}}) {
				
#####################################################################################################
## Row styles

				my $row_style_html = '';
				my $row_height;
				if ($row_height = $worksheets->{sheet1}->{Data}->{$row_number}->{Height} || 16) {
					$row_style_html .= qq{height:${row_height}px;};
				}
				$row_style_html = $row_style_html ? qq{style="$row_style_html"} : '';

				$html .= qq{
					<tr $row_style_html>
				};

## Row styles 
#####################################################################################################

				for (my $col_number = 0; $col_number < $columns_count; $col_number++){
	
					my $column_data = $worksheets->{sheet1}->{Data}->{$row_number}->{Data}->[$col_number];

#####################################################################################################
## Text styles
					if (ref($column_data) eq 'HASH') {
						$column_data = $column_data->{content};
					} elsif (ref($column_data) eq 'ARRAY'){
						my $chunks_html = '';

						foreach my $chunk (@{$column_data}) {
							my $text_style_html .= &FONT_MAP->{$chunk->{style}->{Name}} || &DEFAULT_FONT; 
							$text_style_html .= $chunk->{style}->{Bold} 
													? 'font-weight:bold;' 
													: $chunk->{style}->{Italic} 
														? 'font-style:italic;'
														: 'font-weight:normal;'; 
							$text_style_html .= 'font-size:' . sprintf("%.2f", $chunk->{style}->{Size} * &FONT_COEF) . 'px;'
								if $chunk->{style}->{Size};

							my $content ='';
							if (ref($chunk->{text}) eq 'HASH') {
								$content = $chunk->{text}->{content};
							} else {
								$content = $chunk->{text};
							}
							
							if ($text_style_html){
								$chunks_html .= qq{<span style="$text_style_html">$content</span>};
							} else {
								$chunks_html .= $content;
							}
						}
						$column_data = $chunks_html;
					}

					my @paragraphs = split("\n", $column_data);

					my $html_margin = "\t\t\t\t\t\t\t\t"; 
					if (scalar(@paragraphs) > 1) {
						$column_data = qq{$html_margin<p class="project"} . join(qq{</p>\n$html_margin<p class="project">}, @paragraphs) . qq{</p>};
					}
## Text styles
#####################################################################################################

					Encode::_utf8_off($column_data);

#####################################################################################################
## Cell styles

					my $style_html = '';
					
					my $col_width = sprintf("%.2f", ($colspans->{$row_number}->{$col_number}->{size} || $worksheets->{sheet1}->{Columns_Size}->[$col_number]) * &PX_COEF);
					
					my $div_style_html = qq{overflow:hidden;width:${col_width}px;};
					if ($column_data) {
						if ($worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Font}) {
							$style_html .= &FONT_MAP->{$worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Font}->{Name}} || &DEFAULT_FONT; 
							$style_html .= $worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Font}->{Bold} ? 'font-weight:bold;' : ''; 
							$style_html .= $worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Font}->{Italic} ? 'font-style:italic;' : ''; 
							$style_html .= &ALIGNMENT_MAP->{$worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Alignment}->{horizontal}} || &DEFAULT_ALIGNMENT;
							$style_html .= 'font-size:' . sprintf("%.2f", $worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Font}->{Size} * &FONT_COEF) . 'px;'; 
						}
					} else {
						$div_style_html .= qq{height:${row_height}px;};
					}

					my $border_style = [];
					my $border_width = [];
					my $is_borders_exist = 0;
					foreach my $param_name (@{&BORDER_PARAMETERS_ORDER}) {
						if (
							$worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Border}->{$param_name}->{Style}
							|| $worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Border}->{$param_name}->{Color}
						) {
							$is_borders_exist = 1;
							push(@{$border_style}, 'solid');
							push(@{$border_width}, &BORDER_WIDTH_MAP->{($worksheets->{sheet1}->{Data}->{$row_number}->{Style}->[$col_number]->{Border}->{$param_name}->{Style} || 'thin')});
						} else {
							push(@{$border_style}, 'none');
							push(@{$border_width}, '0px');
						}
					}

					if ($is_borders_exist){
						$style_html .= 'border-style:' . join(' ', @{$border_style}) . ';';
						$style_html .= 'border-width:' . join(' ', @{$border_width}) . ';';
					}

					$style_html = $style_html ? qq{style="$style_html"} : '';
					$div_style_html = $div_style_html ? qq{style="$div_style_html"} : '';

## Cell styles
#####################################################################################################

					my $colspan_html = '';
					if ($colspans->{$row_number}->{$col_number}->{colspan}) {
						$colspan_html = 'colspan=' . $colspans->{$row_number}->{$col_number}->{colspan};
					}

					if (!$colspans->{$row_number}->{$col_number}->{in_colspan}) {
						$html .= qq{
							<td class="project" $colspan_html $style_html><div class="project" $div_style_html>$column_data</div></td>};

					}
				}

				$html .= qq{
					</tr>
				};
				
			}
		}
		
	}
	
	$html .= qq{</table>\n};

	return $html;
}

1;