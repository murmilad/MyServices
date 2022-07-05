package MyService::WEB_Plugin::Convert_Project_Report;

use strict;

use base "MyService::WEB_Plugin::Abstract";

use utf8;
use Encode qw/ decode /;

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Data::Dumper;
use POSIX;
  
use Apache2::Const -compile => qw(OK);



sub Node::new {
    my $class = shift;
    my %h = @_;

	my $self = \%h;
	
	$self->{children} =[]
		unless $self->{children};
	$self->{parrent} ={}
		unless $self->{parrent};

	
    bless $self, $class;
	
	return $self;
}

sub Node::add {
    my $self = shift;
    my %h = @_;

	my $new_tag;
	if (ref($_[0]) eq 'Node') {
		$new_tag = $_[0];
	} else {
		$new_tag = Node->new(%h);
	}
	
	$new_tag->{parrent} = $self;
	push (@{$self->{children}}, $new_tag);
	
	return $new_tag;
}

sub Node::unshift {
    my $self = shift;
    my %h = @_;

	my $new_tag;
	if (ref($_[0]) eq 'Node') {
		$new_tag = $_[0];
	} else {
		$new_tag = Node->new(%h);
	}
	
	$new_tag->{parrent} = $self;
	unshift(@{$self->{children}}, $new_tag);
	
	return $new_tag;
}

sub Node::copy {
    my $class = shift;
    my %h = @_;

	my $new_tag;

	if (ref($_[0]) eq 'Node') {
		foreach my $tag (grep {$_ ne 'parrent' && $_ ne 'children'} keys (%{$_[0]})) {
			$new_tag->{$tag} = $_[0]->{$tag};
		}

		$new_tag = Node->new(%{$new_tag});
	} else {
		$h{children} =[];
		$h{parrent} ={};
		$new_tag = Node->new(%h);
	}

	return $new_tag;
}

use constant SINGLE => {
	JRXML => [
		'parameter',
		'font',
	],
};


use constant EXTENSION => {
	JRXML => '.jrxml',
};


use constant TEMPLATES => {
	JRXML => {
			file => q{<?xml version="1.0" encoding="UTF-8"?>
<!-- Created with Jaspersoft Studio version 6.9.0.final using JasperReports Library version 6.9.0-cb8f9004be492ccc537180b49c026951f4220bf3  -->
<jasperReport xmlns="http://jasperreports.sourceforge.net/jasperreports" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://jasperreports.sourceforge.net/jasperreports http://jasperreports.sourceforge.net/xsd/jasperreport.xsd" name="act-detail" pageWidth="%WIDTH%" pageHeight="%HEIGHT%" whenNoDataType="AllSectionsNoDetail" columnWidth="%WIDTH%" leftMargin="0" rightMargin="0" topMargin="0" bottomMargin="0">
	<style name="Verdana_Normal" isDefault="true" fontName="Verdana"/>
	%FILE%
</jasperReport>
			}
	},
};

# convert
#	result(Node) - текущая нода результирующей модели
#	model  - текгщая нода исходной модели
#	type   - тип преобразования (JRXML)
#	config - контекст обработки

sub tag_body {
	my $result          = shift;
	my $model           = shift;
	my $type            = shift;
	my $config          = shift;
	my $converted_model = shift;

	if ($model->{body_after} ) {

		# Добавляем поле
		my $field = $converted_model->add(
			tag => 'textField',
			props => {
				'isBlankWhenNull' => "true",
			},
		);
		
		$field->add(
			tag   => 'reportElement',
			props => {
				'positionType' => "Float",
				'isPrintWhenDetailOverflows' => "true",
				'x'            => $config->{tables}->{$model->{table_name}}->{margin_left} + $config->{pos_x} + 10,
				'y'            => $config->{pos_y},
				'width'        => $config->{width} - $config->{margin_right} - $config->{margin_left},
				'height'       => 35,
			}
		);
		
		$field->add(
			tag   => 'textElement',
			props => {
				'textAlignment'     => "Left",
				'verticalAlignment' => "Middle",
				'markup'            => "html",
			}
		)->add(
			tag   => 'font',
			props => {
				'size' => "9",
			},
		);

		my $momo = $field->add(
			tag   => 'textFieldExpression',
			body  => $model->{body_after},
		);

		$model->{body_after} = '';

		# добавляем позицию y
		$config->{pos_y} += 35;

	}
}

sub text_tag {
	my $result          = shift;
	my $model           = shift;
	my $type            = shift;
	my $config          = shift;

	if ($result->{tag} eq 'textFieldExpression' || @{$model->{children}}) {
		append_str(\$result->{body}, "<$model->{tag}>" . $model->{body} . "</$model->{tag}>" , ' ');
		$model->{body} = ''; # чтобы тело не дублировалось после текущего тега
		return undef;
	}
	my $width = 0;
	my $margin_right = 0;
	my $margin_left  = 0;
	if ($result->{width})  {
		$width = $result->{width}; # размер элемента в который таблица вложена
	} else  {
		$width = $config->{width} - $config->{margin_right} - $config->{margin_left}; # размер печатной формы
		$margin_right = $config->{margin_right};
		$margin_left  = $config->{margin_left};
	}
	
	my $field = $result->add(
		tag => 'textField',
		props => {
			'isBlankWhenNull' => "true",
		},
	);
	
	$field->add(
		tag   => 'reportElement',
		props => {
			'positionType' => "Float",
			'isPrintWhenDetailOverflows' => "true",
			'x'            => $margin_left + $config->{pos_x},
			'y'            => $config->{pos_y},
			'width'        => $width,
			'height'       => 35,
		}
	);
	
	$field->add(
		tag   => 'textElement',
		props => {
			'textAlignment'     => "Left",
			'verticalAlignment' => "Middle",
			'markup'            => "html",
		}
	)->add(
		tag   => 'font',
		props => {
			'size' => "9",
		},
	);

	my $body = $field->add(
		tag   => 'textFieldExpression',
		body  => $model->{body},
	);
	

	# добавляем позицию y
	$config->{pos_y} += 35;

	return $body;
}


use constant JAVA_TEMPLATE => q{
package com.technology.project.printforms.printform;

import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.Locale;

import org.json.JSONArray;
import org.json.JSONObject;

import com.technology.project.printforms.dao.PrintFormsDao;
import com.technology.project.printforms.dto.ApplicationHistoryDto;
import com.technology.project.printforms.dto.ApplicationHistoryTitleDto;

public class %CLASS_NAME% extends PrintForm{
	  
	@Override
	public String getPrintFormParametersJson(Integer applicationId, Integer cityId, Integer operatorId, PrintFormsDao service) {

/**	
		%REPORT_SCRIPT%
*/


		return new JSONObject() {{
			%PARAMETER_LIST%
		}}.toString();
		
	}

	@Override
	public String getPrintFormPath() {
		return "%FILE_NAME%";
	}
}
};

use constant PARAMETER => q{

	%TYPE% %PARAMETER% = %DEFAULT%;

/**	
*	%PARAMETER_SCRIPT%
*/

	put("%PARAMETER_NAME%", %PARAMETER%);
};

# В методах convert получаем ноду ($result) для привязки чилдов текущего уровня
# и возвращаем ноду куда пойдут чилды следующего уровня
# Если метод convert возвращает undef, то нода текущего уровня в модель не добавляется
use constant CONVERTER => {
	JRXML => { 
		'separate_function' => \&separate_block_to_root,
		'root'  => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;

				my $title = Node->new(
					'tag' => 'detail',
				);
				
				$result->add($title);
				return $title;
			}
		},
		'block'  => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;

				#Игнорировать блоки без скрипта появления 
				if ($config->{section_count} >= 1 && !$model->{perl}){
					return $result;
				}

				my $section_count = ++$config->{section_count};
				
				push(@{$config->{parameters}}, {
					type => "String",
					default => '"true"',
					name => "showSection$section_count",
					value => $model->{perl},
				});
				
				$config->{root}->unshift(
					tag   => 'parameter',
					props => {
						name  => "showSection$section_count",
						class => 'java.lang.String',
					},
				);

				my $band = Node->new(
					'tag' => 'band',
					perl => $model->{perl},
					props => {
						splitType => "Stretch",
					},
				);
				$band->add(
					'tag' => 'printWhenExpression',
					body => "\$P{showSection$section_count}.equals(\"true\") ? Boolean.TRUE : Boolean.FALSE",
				);

				$config->{pos_x} = 0;
				$config->{pos_y} = 0;
				foreach my $table_name (keys %{$config->{tables}}){
					$config->{tables}->{$table_name}->{row_index} = 0;
					$config->{tables}->{$table_name}->{pos_y} = 0;
				}

				if ($result->{tag} eq 'band') {

				#	$result->{parrent}->{children}->[@{$result->{parrent}->{children}}-1]->{props}->{height} = $config->{pos_y};
				
					$result->{parrent}->add($band);
				} else {

					$result->add($band);					
				}
				
				
				return $band;
			},
			close => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				my $converted_model = shift;

				$converted_model->{props}->{height} = $config->{pos_y} + 35;
				return undef;
			},
		},
		'table' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;

				$config->{table_index}++;
				my $table_name = "table_$config->{table_index}";

				my $table_width = 0;
				my $margin_right = 0;
				my $margin_left  = 0;
my $html = {};
compile_model($html, $model, '', {});

#ERACE/
use Data::Dumper;
open LOG, ">>/var/log/scn.log";
print LOG "data (Convert_Project_Report.pm) = " . Dumper($html) . "\n";
print LOG "data (Convert_Project_Report.pm) table name = " . Dumper($table_name) . "\n";
print LOG "data (Convert_Project_Report.pm) table width = " . Dumper	($config->{tables}->{$table_name}->{width}) . "\n";
close LOG;
#ERACE\
				if ($config->{tables}->{$table_name}->{width})  {
					$table_width = $config->{tables}->{$table_name}->{width}; # размер элемента в который таблица вложена
				} else  {
					$table_width = $config->{width} - $config->{margin_right} - $config->{margin_left}; # размер печатной формы
				}
				$margin_right = $config->{margin_right};
				$margin_left  = $config->{margin_left};

				my $cols_count = 0;
				my $cols_width = 0;

				my $tr_index = 0;
				my $col_width = [];
				#Считаем размеры и количество колонок, проставляем имя таблицы для получения размеров;
				foreach my $tr (find_inside({tag=>'tr'}, $model, {tag=>'table'})) {


					# Расчитываем размеры колонок по первой строке
					if ($tr_index == 0) {
						my $td_index  = 0;
						foreach my $td (find_inside({tag=>'td'}, $tr, {tag=>'table'})){

							$cols_count += $td->{props}->{colspan} || 1;
							$col_width->[$td_index] = $td->{props}->{width} =~ /^(\d++).*$/ 
								? $1 
								: $tr->{props}->{style} && $td->{props}->{style}->{width} =~ /^(\d++).*$/
									? $1
									: 0;

							$cols_width += $col_width;
							$td_index++
						}
						
						if ((grep {!$_} @{$col_width}) || scalar(@{$col_width}) < $cols_count) {
							for (my $i = 0; $i < $cols_count; $i++) {
								$col_width->[$i] = sprintf("%d", 1000 / $cols_count);
							}

							$cols_width = 1000;
						}
					}
						
					my $td_index  = 0;
					foreach my $td (find_inside({tag=>'td'}, $tr, {tag=>'table'})){
						$td->{col_width}  = $col_width->[$td_index];
						$td->{props}->{col_width}  = $col_width->[$td_index];
						$td->{table_name} = $table_name;
						$td_index++
					}
					
					$tr->{table_name} = $table_name;
					$tr_index++;
				}

				$config->{tables}->{$table_name} = {
					cols_width  => $cols_width,
					size_factor => $cols_width ? $table_width / $cols_width : 0,
					pos_x => $config->{pos_x},
					pos_y => $config->{pos_y},
					row_index => 0,
					margin_right => $margin_right,
					margin_left  => $margin_left,
				};
				
				#
				return undef;
			},
		},
		'tr' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;

				# если первая строка то выставляем начало координат строки
				if ($config->{tables}->{$model->{table_name}}->{row_index} == 0) {
					$config->{pos_y} = $config->{tables}->{$model->{table_name}}->{pos_y};
				} else {
					$config->{pos_y} += 35;
				}

				$config->{tables}->{$model->{table_name}}->{row_index}++;
				return undef;
			},
			
			close => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				my $converted_model = shift;

				# меняем позицию на следующую строку
				$config->{pos_x} = $config->{tables}->{$model->{table_name}}->{pos_x};

				return undef;
			},
			body => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				my $converted_model = shift;

				tag_body($result, $model, $type, $config, $converted_model);


			},

		}, 

		'td' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;

				# формируем прямоугольный элемент в позиции x,y и текстовую часть к нему
				my $width = floor($model->{col_width} * $config->{tables}->{$model->{table_name}}->{size_factor} * ($model->{props}->{colspan} ? $model->{props}->{colspan} : 1));

				
				if (grep {$_->{tag} eq 'table'} @{$model->{children}}){

					$config->{tables}->{'table_' . ($config->{table_index}+1)} = {
						width  => $width,
						pos_x  => $config->{pos_x},
						pos_y  => $config->{pos_y},
					};
					
					return undef;
				}
				
				# Рисуем квадрат
				$result->add(
					tag => 'rectangle',
				)->add(
					tag => 'reportElement',
					props => {
						'positionType' => "Float",
						'x'            => $config->{tables}->{$model->{table_name}}->{margin_left} + $config->{pos_x},
						'y'            => $config->{pos_y},
						'width'        => $width,
						'height'       => 35,
					},
					
				);
				
				# Добавляем поле
				my $field = $result->add(
					tag => 'textField',
					props => {
						'isBlankWhenNull' => "true",
					},
				);
				
				$field->add(
					tag   => 'reportElement',
					props => {
						'positionType' => "Float",
						'isPrintWhenDetailOverflows' => "true",
						'x'            => $config->{tables}->{$model->{table_name}}->{margin_left} + $config->{pos_x} + 10,
						'y'            => $config->{pos_y},
						'width'        => $width - 10,
						'height'       => 35,
					}
				);
				
				$field->add(
					tag   => 'textElement',
					props => {
						'textAlignment'     => "Left",
						'verticalAlignment' => "Middle",
						'markup'            => "html",
					}
				)->add(
					tag   => 'font',
					props => {
						'size' => "9",
					},
				);

				my $body = $field->add(
					tag   => 'textFieldExpression',
					body  => $model->{body},
				);
				
			
				# добавляем позицию x
				$config->{pos_x} += $width;

				return $body;
			},
		},
		'div' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				
				return text_tag($result, $model, $type, $config);
			},

		},
		'p' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				
				return text_tag($result, $model, $type, $config);
			},
		},
		'h1' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				
				return text_tag($result, $model, $type, $config);
			},
		},
		'h2' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				
				return text_tag($result, $model, $type, $config);
			},
		},
		'h3' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				
				return text_tag($result, $model, $type, $config);
			},
		},
		'h4' => {
			convert => sub {
				my $result          = shift;
				my $model           = shift;
				my $type            = shift;
				my $config          = shift;
				
				return text_tag($result, $model, $type, $config);
			},
		},
	}
};




sub convert_html {
	my $converted_model = shift;
	my $form_html       = shift;
	my $type            = shift;
	my $config          = shift;

	$form_html =~ s/%#----.+[\r\n]+//g;
	$form_html =~ s/#----.+[\r\n]+//g;


	# Отрезаем тела скриптов от тела самого отчета
	my $perl_body = []; # Тела скриптов перл
	while ($form_html =~ /<\s*%\s*(perl|once)\s*>(.+?)<\s*\/\s*%\s*(perl|once)\s*>/smg) { 
		push(@$perl_body, {
			body => decode('Windows-1251', $2),
			type => $1,
		});
	}
	$form_html =~ s/<\s*%\s*(perl|once)\s*>(.+?)<\s*\/\s*%\s*(perl|once)\s*>//smg;
	$config->{perl_body} = $perl_body;


	# Находим параметры отчета и экранируем теги внутри параметров
	my $form_html_perl_script = $form_html;
	my $parameters = {};
	while ($form_html_perl_script =~ /(<\s*%.+?%\s*>)/smg) {
		my $perl_script = $1;
		
		# Экранируем теги
		#my $replaced = $perl_script;
		#$replaced =~ s/(<)(\s*(:?\/\s*)?\w+)/$1-$2/g;
		#$form_html =~ s/\Q$perl_script/$replaced/;
		
		# Добавляем параметры
		my $simplefied = $perl_script;
		$simplefied =~ s/\s//g;
		
		my $parameter_name = '';
		if ($parameters->{$simplefied}) {
			$parameter_name = $parameters->{$simplefied}->{name};
		} else {
			$parameter_name = 'p';
			while ($perl_script =~ /(\w+)/g) {
				$parameter_name .= ucfirst(lc($1));
			}
			$parameters->{$simplefied} = {
				name     => $parameter_name,
				perlcode => decode('Windows-1251', $perl_script),
			};
		}
		push(@{$config->{parameters}}, {
			name => $parameter_name,
			value => decode('Windows-1251', $perl_script),
		});
		$form_html =~ s/\Q$perl_script/\$P{$parameter_name}/;
	};
	foreach my $parameter_key (keys(%{$parameters})) {
		$converted_model->add(
			tag   => 'parameter',
			props => {
				name  => $parameters->{$parameter_key}->{name},
				class => 'java.lang.String',
			},
		);
	}

	$form_html = decode('Windows-1251', $form_html);

	return $form_html;
}
sub convert_model {
	my $result = shift;
	my $model  = shift;
	my $type   = shift;
	my $config = shift;

	my $converted_model;
	if (&CONVERTER->{$type} && &CONVERTER->{$type}->{$model->{tag}}->{convert}) {
		my $start_added = @{$result->{children}} - 1;

		$converted_model = &CONVERTER->{$type}->{$model->{tag}}->{convert}($result, $model, $type, $config);



		if (!defined($converted_model)) {
			$converted_model = $result;

			# Добавляем либо обрабатываем тело тега
			if (&CONVERTER->{$type}->{$model->{tag}}->{body}) {
				&CONVERTER->{$type}->{$model->{tag}}->{body}($result, $model, $type, $config, $converted_model);
			} elsif (&CONVERTER->{$type}->{convert_body}) {
				&CONVERTER->{$type}->{convert_body}($result, $model, $type, $config, $converted_model);
			}			
			
			append_str(\$config->{body}, $model->{body}, ' ');
			append_str(\$config->{body_after}, $model->{body_after}, ' ');
		} else {

			# Добавляем либо обрабатываем тело тега
			if (&CONVERTER->{$type}->{$model->{tag}}->{body}) {
				&CONVERTER->{$type}->{$model->{tag}}->{body}($result, $model, $type, $config, $converted_model);
			} elsif (&CONVERTER->{$type}->{convert_body}) {
				&CONVERTER->{$type}->{convert_body}($result, $model, $type, $config, $converted_model);
			}		
			append_str(\$converted_model->{body}, $config->{body}, ' ');
			
			if (@{$result->{children}}) {
				append_str(\$result->{children}->[@{$result->{children}}-1]->{body_after}, $config->{body_after}, ' ');
				append_str(\$result->{children}->[@{$result->{children}}-1]->{body_after}, $model->{body_after}, ' ');
			}

			$config->{body} = '';
			$config->{body_after} = '';
		}

	} else {
		
		$converted_model = Node->copy(%{$model});

		append_str(\$converted_model->{body},       $config->{body}, "\n");
		append_str(\$converted_model->{body_after}, $config->{body_after}, "\n");


		$config->{body} = '';
		$config->{body_after} = '';


		$result->add($converted_model);
	}

	for my $child (@{$model->{children}}){
		convert_model($converted_model, $child, $type, $config);
	}

	if (&CONVERTER->{$type}->{$model->{tag}}->{close}) {
		&CONVERTER->{$type}->{$model->{tag}}->{close}($result, $model, $type, $config, $converted_model);
	}
	
}
sub compile_model {
	my $html   = shift;
	my $model  = shift;
	my $type   = shift;
	my $config = shift;
	
	my $tabs = (" " x ($html->{level}));
	if ($model->{tag}) {
		my $props = "";
		foreach my $prop (keys %{$model->{props}}) {
			my $value = $model->{props}->{$prop};
			$props .= " $prop='" . $value . "' ";
		}

		my $gt = (grep {$model->{tag} eq $_} @{&SINGLE->{$type}})  ? '/>' : '>';
		if ($model->{perl}) {
			$html->{result} .= format_perl_condition($model->{perl}, "$tabs ", $type);
		}

		$html->{result} .= "$tabs<$model->{tag} $props$gt\n";

		$html->{result} .= format_body($model->{body}, "$tabs ", $type, $config);
	}
	
	$html->{level}++
		if $model->{children} && scalar(@{$model->{children}});

	for my $child (@{$model->{children}}){
		
		compile_model($html, $child, $type, $config);
	}
	
	$html->{level}--
		if $model->{children} && scalar(@{$model->{children}});

	if ($model->{tag}) {
		if (!grep{$model->{tag} eq $_} @{&SINGLE->{$type}}) {
			
			$html->{result} .= "$tabs</$model->{tag}>\n";
			if (
				$model->{parrent}->{tag} eq 'band'
			) {
				$html->{result} .= "<!--\n" . format_body($model->{body_after}, $tabs, $type, $config) . "\n-->\n"
					if $model->{body_after};
			} else {
				$html->{result} .= format_body($model->{body_after}, $tabs, $type, $config);
			}
		}
	}
}

sub append_str {
	my $source  = shift;
	my $str     = shift;
	my $dividor = shift;
	
	$$source .= ($$source ? $dividor : '') . $str
				if $str;
}


sub format_perl_condition {
	my $condition  = shift;
	my $tabs   = shift;
	
	my $result = '';
	if ($condition =~ /\S/) {
		$result .= "$tabs<!--\n$tabs$condition\n$tabs-->\n"
	}
	return $result;
}

# my $props_model = find_inside_first({props=>{y=>1}}, $model); # Ищем узел, содержащий указанное свойство внутри родительского узла
# Рекурсивный поиск внутрь
sub find_inside {
	my $criteria = shift;
	my $model    = shift;
	my $exclude  = shift;
	my $result = shift || [];

	
	push(@{$result}, $model)
		if match_param($criteria, $model);
	
	foreach my $child (@{$model->{children}}) {
		find_inside($criteria, $child, $exclude, $result)
			if !$exclude || !match_param($exclude, $child);
	}
	
	return @{$result};
	
	
}

# Рекурсивная проверка параметров
sub match_param {
	my $criteria  = shift;
	my $model   = shift;

	foreach my $key (keys %$criteria) {
		return 0
			if !defined($model->{$key});
		
		return 0
			if ref($criteria->{$key}) eq 'HASH' && ref($model->{$key}) ne 'HASH';

		my $current_criteria = $criteria->{$key};


		return 0
			if $model->{$key} !~ /^${current_criteria}$/;

		return match_param($criteria->{$key}, $model->{$key})
			if ref($criteria->{$key}) eq 'HASH' && ref($model->{$key}) eq 'HASH';
		
	}
	
	return 1;
}

sub format_body {
	my $body = shift;
	my $tabs = shift;
	my $type = shift;
	my $config = shift;
	
	my $result = '';
	if ($body =~/\S/) {
		if ($body =~ /showSection/){
			$result = "$tabs<![CDATA[$body]]>\n";
		} else {
			$body =~ s/[\r\n]+/ /;
			$body =~ s/(\$P{\w+})/" + $1 + "/g;
			$body = '"' . $body . '"';
			$body =~ s/\s*\+\s*""$//;
			$body =~ s/^""\s*\+\s*//;
			$body =~ s/[\r\n]//g;
	
			$result = "$tabs<![CDATA[$body]]>\n";
		}
	}
	
	return $result;#$body =~/\S/ ? "$tabs<![CDATA[$body]]>\n" : "";
}


sub get_error_context {
	my $chunk = shift;
	my $html  = shift;
	my $regexp = shift;
	my $count = shift || 200;
	my $error = '';

	my $index=0;

	while ($html =~ /$regexp/smg){
		if ($chunk == $index) {
			my $error_r = substr($html, pos($html)-$count, $count);
			$error_r =~ s/</&lt;/g;
			$error_r =~ s/>/&gt;/g;
			$error_r =~ s/[\r\n]+/<br>/g;

			my $error_l = substr($html, pos($html), $count);
			$error_l =~ s/</&lt;/g;
			$error_l =~ s/>/&gt;/g;
			$error_l =~ s/[\r\n]+/<br>/g;
			
			$error = $error_r . '<b><span style="color:red"><--HERE--></span></b>' . $error_l;
		}
		$index++;
	}
	
	return $error;
}

sub incapsulate_inside_block {
	my $current_parrent = shift;


	my $old_parrent = $current_parrent->{parrent};
	my $block;
	if ($current_parrent->{parrent}->{tag} ne 'block') {
		$block = Node->new(
			tag      => 'block',
			children => [$current_parrent],
			parrent  => $current_parrent->{parrent},
			#perl     => "\n----------\n" . get_error_context($i, $form_html, $chunk_regexp, 100) . "\n----------\n" ,
		);
		foreach my $child (@{$current_parrent->{children}}) {
			$child->{parrent} = $block;
		}
		map {$_ = $block if $_ eq $current_parrent} @{$old_parrent->{children}};
	}

	
	return $block;
}

sub move_up {
	my $current_parrent = shift;
	my $path		    = shift;
	
	unshift(@{$path}, $current_parrent);
	
	if ($current_parrent->{parrent}) {
		$path = move_up($current_parrent->{parrent}, $path);
	}
	
	return $path;
}

sub create_down {
	my $current_parrent = shift;
	my $path 			= shift;

	my $item = shift(@{$path});

	if ($item) {	
		return create_down($current_parrent->add(Node->copy(%{$item})), $path);
	} else {
		return $current_parrent;
	}
}

sub separate_block_to_root {
	my $current_parrent = shift;
	my $perl_after = shift;

	my $path = move_up($current_parrent->{parrent}, []);

	shift($path);
	my $root = shift($path);
	my $block;

	if ($path->[0]->{tag} eq 'block') {
		$block = shift($path);
	} else {
		$block = incapsulate_inside_block($path->[0]);
	}

	my $new_parrent = $block ? $block : $current_parrent->{parrent};

	return create_down($new_parrent->{parrent}->add(
		tag      => 'block',
		perl     => $perl_after,
	), $path);

}

sub separate_block {
	my $current_parrent = shift;
	my $perl_after = shift;

	my $block = incapsulate_inside_block($current_parrent);

	my $new_parrent = $block ? $block : $current_parrent->{parrent};

	my $result = $new_parrent->{parrent}->add(
		tag      => 'block',
		children => [],
		perl     => $perl_after,
	);

	return $result;

}

sub remove_empty_bands {
	my $node = shift;
	

	for my $child (@{$node->{children}}) {
		remove_empty_bands($child);
	}

	my $new_children = [];
	for my $child (@{$node->{children}}) {
		push (@{$new_children}, $child)
			if ($child->{tag} ne 'block' || scalar(@{$child->{children}}) != 0);
	}

	$node->{children} = $new_children;
	
}
sub get_html_model {

	my $form_html = shift;
	my $width     = shift;
	my $height    = shift;
	my $type      = shift;

	my $model = Node->new(tag => '');
	
	# Собираем массив тегов кроме b|br
	my $chunk_regexp = '\s*<\s*(\/)?\s*(?!(?:b|br)\s*\/?\s*>)(\w+)(?:\s+(.+?))?(\/)?\s*>\s*';
	my @chunks = split(/$chunk_regexp/sm, $form_html);
	shift(@chunks);

	my $tag_level      = 0;
	my $prev_tag_level = {};
	my $is_tag_opened  = {};
	my $current_parrent = $model->add(tag => '');
	for (my $i = 0; $i < scalar(@chunks)/5 ; $i++) {
		my $closed = $chunks[$i*5];
		my $tag = $chunks[$i*5+1];
		my $props_string = $chunks[$i*5+2];
		my $single = $chunks[$i*5+3];
		my $body = $chunks[$i*5+4];

		my $body_after = '';
		my $perl_after = ''; # скрипт на перле который влияет на отображение следующего элемента
		if ($closed) { # если тег закрывается то после него идет не его тело, а
			while ($body =~ /^(\s*%.+)$/mg) { # либо скрипт с условием для следующего тега
				$perl_after .= $1;
			}
			while ($body =~ /^(?!\s*%)(.+)$/mg) { # либо тело родителя
				$body_after .= $1;
			}
			$body = '';
		}
		
		# получаем свойства тега
		my $props = {};
		while ($props_string =~ /([\w-]+)\s*=\s*['"](.+?)['"]/sgm) {
			my $prop_name  = $1;
			my $prop_value = $2;
			if ($prop_name eq 'style') {
				while ($prop_value =~ /([\w-]+)\s*:\s*(.+?);/g) {
					$props->{$prop_name}->{$1} = $2; 
				}
			} else {
				$props->{$prop_name} = $prop_value;
			}
		}
		 
		my $node = Node->new(
			tag => $tag,  					 				   	# Тип тега
			tag_level => $tag_level, 							# Уровень вложнноси - требуется для определения иерархии
			body => $body,					 					# Тело тега
			props_string => $props_string,					 	# Свойства тега в виде строки
			props => $props,									# Свойства тега
			single => $single,				 					# Тег сразу закрывается
			closed => $closed,				 					# Текущий тег является закрывающим
			children => [],
		);
	
		
		if (!$closed ) {
			$current_parrent->add($node);
		}
		if (!$closed && !$single) {
			$current_parrent = $node;
			$tag_level++;
		}
		
		if ($closed) {
			# Заворачиваем в блок все теги которые входят в перл условие
			my $new_block;
			if ($perl_after =~ /\W/) {
				$new_block = &CONVERTER->{$type}->{'separate_function'}->($current_parrent, $perl_after);
			}


			if (
				!$current_parrent->{tag} 
				|| $current_parrent->{tag} eq $tag 
				|| $current_parrent->{tag} eq 'block'
			) {
				# Тело, которое должно быть помещено в родительский тег как тело, идущее после текущего тега
				$current_parrent->{body_after} = $body_after;
				
				$current_parrent = $new_block 
					? $new_block 
					: $current_parrent->{tag} eq 'block' 
						? $current_parrent->{parrent}->{parrent}
						: $current_parrent->{parrent};
				
				$tag_level--;
			} else {

				die '-' . $current_parrent->{parrent}->{tag} . "- Incorrect tag chain. Perhaps <b><span style='color:red;'>&lt;$current_parrent->{tag}&gt;</span></b> is not closed. Expected <b><span style='color:red;'>&lt;$tag&gt;</span></b> :<br><br>" . get_error_context($i, $form_html, $chunk_regexp, 100);
			}
		}

	}

	#$model = incapsulate_inside_block($model);

	remove_empty_bands($model);
	
	return $model;
}

sub set_values {
	my $template = shift;
	my $values   = shift;


	foreach my $value (keys %{$values}) {

		my $replace = $values->{$value};

		$template =~ s/$value/$replace/g;
	}

	return $template;
}

sub convert_file {
	my $type   = shift;
	my $path   = shift;
	my $width  = shift;
	my $height = shift;


	my $files = [];
	# Текстовое представление результирующей модели
	my $html = {result=>'', level=>0};
	my $model;
	my $converted_model;
	my $config = {
		margin_right => 10,
		margin_left => 10,
		width => $width, 
		height => $height, 
		pos_x=>0, 
		pos_y=>0,
		parameters=>[],
	};

	if (open HTML_FILE, '<' . "/var/www/scn.lo/www/" . $path){
		# Читаем HTML скриптлет
		my $form_html = "";
		while (my $line = <HTML_FILE>){
			$form_html .= $line;
		}		
		close HTML_FILE;

		# Результирующая модель и конфигурация
		$converted_model = Node->new(tag => '');
		$config->{root} = $converted_model;

		# Обрабатываем голый текст
		$form_html = convert_html($converted_model, $form_html, $type, $config);


		my $methods;

		# Преобразовываем голый текст в исходную модель
		$model = get_html_model($form_html, $width, $height, $type);


		# Если в модели есть что то
		if (@{$model->{children}}) {
			

			# Конвертируем исходную модель в результирующую
			my $converted_model_body = &CONVERTER->{$type}->{'root'}->{convert}($converted_model, $model, $type, $config);
			convert_model($converted_model_body, $model, $type, $config);

			# Собираем из результирующей модели текстовое предстовление

			compile_model($html, $converted_model, $type, $config);
#			compile_model($html, $model, $type, $config);
			
			# задаем размер последнего блока
			$html->{result} =~ s/%SECTION_HEIGHT_\d+%/0/;
#ERACE/
use Data::Dumper;
open LOG, ">>/var/log/scn.log";
print LOG "data (Convert_Project_Report.pm) config = " . Dumper($config) . "\n";
close LOG;
#ERACE\


		}


		# Если есть результаты в текстовом представлении, печатаем их в файл
		if ($html->{result}) {
			my $filename = $path;
			$filename =~ s/^.+\/([^\/]+)\.[^\.\/]+$/$1/;

			my $jrxml_filename = $filename;
			$jrxml_filename .= &EXTENSION->{$type};

			my $java_classname = $filename;
			$java_classname =~ s/_+(\w)/\U$1\E/g;
			$java_classname = ucfirst($java_classname);

			my $java_filename .= $java_classname . '.java';
			
			my $script = join("\n\n", map {" - type - " . $_->{type} . " - \n" . $_->{body}} @{$config->{perl_body}});
			my $parameters_list = "";

			foreach my $parameter (@{$config->{parameters}}) {
				$parameters_list .= set_values(&PARAMETER, {
					'%TYPE%'             => $parameter->{type} ? $parameter->{type} : 'String',
					'%DEFAULT%'          => $parameter->{default} ? $parameter->{default} : '""',
					'%PARAMETER%'        => $parameter->{name},
					'%PARAMETER_NAME%'   => $parameter->{name},
					'%PARAMETER_SCRIPT%' => $parameter->{value},
				});
			}
			
			if (open RESULT_JAVA, '>' . "/var/www/html/$java_filename") {
				print RESULT_JAVA  set_values(&JAVA_TEMPLATE, {
					'%CLASS_NAME%'     => $java_classname,
					'%REPORT_SCRIPT%'  => $script,
					'%PARAMETER_LIST%' => $parameters_list,
					'%FILE_NAME%'      => $jrxml_filename,
				});
				close RESULT_JAVA;

				push(@{$files}, {header => 'JAVA', filename => $java_filename});
			}

			if (open RESULT_FILE, '>' . "/var/www/html/$jrxml_filename"){
				print RESULT_FILE  set_values(&TEMPLATES->{$type}->{file}, {
					'%FILE%'       => $html->{result},
					'%WIDTH%'      => $config->{width},
					'%HEIGHT%'     => $config->{height},
				});
				close RESULT_FILE;

				push(@{$files}, {header => $type, filename => $jrxml_filename});
			} else {
				die "$0: open /var/www/html/$jrxml_filename: $!";
			}
		} else {
				die "Empty body";
		}

	} else {
		die "$0: open /var/www/scn.lo/www/$path: $!";
	}

	return  {files => $files, body => $html->{result}};
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

		if ($param_hash->{'report'}) {
			my $report = $param_hash->{'report'};

			my $result = convert_file('JRXML', $report, $param_hash->{'width'} || 750, $param_hash->{'height'} || 900);

			my $files = join('<br>', map {"$_->{header} <a href='/html/$_->{filename}' download>$_->{filename}</a>"} @{$result->{files}});
			$self->print_html(qq{
						
				<form enctype="multipart/form-data" name="input" action="/Service" method="post">
					$files
				</form>
				
			});
			my $body = $result->{body};
			$body =~ s/</&lt;/g;
			$body =~ s/>/&gt;/g;
			$body =~ s/([\r\n]+)/$1<br>/g;
			$body =~ s/ /&nbsp;/g;
			
			$self->print_html($body);

		} else {

                $self->print_html(qq|
                	<form name="input" action="/Service" method="post">
                	Please input Project Report path (ex. /print/auto/goods.html) <input type="text" id="report" name="report"/> 
                	Please input Report width (def. 750) <input type="text" id="width" name="width"/> height (def. 900) <input type="text" id="height" name="height"/>
					<input type="submit" value="Convert to Jasper"/>
					<input type="hidden" name="handler" value="convert_project_report"/>
					
                	</form>
                |);
			
		}

	return Apache2::Const::OK;

}


1;