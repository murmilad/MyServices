package MyService::WEB_Plugin::DAO_to_REST;
  
use strict;
use warnings;

use base "MyService::WEB_Plugin::Abstract";

use Encode qw(encode);
use Data::Dumper;
use URI::Escape;
  
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use constant TEMPORARY_PATH => '/var/Project/tmp/';

use constant TEMPLATE_REST => q{
package com.technology.project.%SERVICE_CLASS_PATH%;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.apache.log4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import org.jepria.ssoutils.JepPrincipal;
import javax.servlet.http.HttpServletRequest;


import com.technology.project.%SERVICE_CLASS_PATH%.dao.%SERVICE_CLASS%Dao;
import com.technology.project.%SERVICE_CLASS_PATH%.dao.%SERVICE_CLASS%DaoImpl;


import java.io.*;
import java.net.InetAddress;
import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;

@RestController
public class %SERVICE_CLASS%Controller {

	@Autowired
	protected Environment environment;

	private final %SERVICE_CLASS%Dao service = new %SERVICE_CLASS%ServerFactory(new %SERVICE_CLASS%DaoImpl()).getDao();

	%REST_METHOD%

	// Total control - setup a model and return the view name yourself. Or
	// consider subclassing ExceptionHandlerExceptionResolver (see below).
	@ExceptionHandler(Exception.class)
	public String handleError(HttpServletRequest req, Exception ex) {

		return ExceptionUtils.getStackTrace(ex).replaceAll("(\\\\W)at(\\\\W)", "$1at$2<br>");
	}

}	
};

use constant TEMPLATE_REST_GET => q{
	@GetMapping("%METHOD_PATH%")
	%METHOD_TYPE% %METHOD_NAME%(
		HttpServletRequest request,
		%METHOD_PARAMS%) {

		if (request.getUserPrincipal() == null) {
			throw new ResponseStatusException(HttpStatus.NETWORK_AUTHENTICATION_REQUIRED, "Not authorized");
		}
		Integer operatorId = ((JepPrincipal) request.getUserPrincipal()).getOperatorId();


	    %METHOD_CONSTRUCTOR%

		%METHOD_RESULT%
	}		 
};

use constant TEMPLATE_REST_DELETE => q{
	@DeleteMapping("%METHOD_PATH%")
	%METHOD_TYPE% %METHOD_NAME%(
		HttpServletRequest request,
		%METHOD_PARAMS%) {

		if (request.getUserPrincipal() == null) {
			throw new ResponseStatusException(HttpStatus.NETWORK_AUTHENTICATION_REQUIRED, "Not authorized");
		}
		Integer operatorId = ((JepPrincipal) request.getUserPrincipal()).getOperatorId();

	    %METHOD_CONSTRUCTOR%

		%METHOD_RESULT%;
	}		 
};

use constant TEMPLATE_REST_PARAMETER_GET => q{
		@PathVariable %TYPE% %NAME%};

use constant TEMPLATE_REST_PARAMETER_PUT => q{
		@RequestBody %TYPE% %NAME%};
	
use constant TEMPLATE_EXEMPLAR_PARAMETER => q{
			%CLASS%.get%PARAMETER%()};

use constant TEMPLATE_REST_PUT => q{
	@PutMapping("%METHOD_PATH%")
	%METHOD_TYPE% %METHOD_NAME%(
		HttpServletRequest request,
		@RequestBody %CLASS% %PARAMETER%,
		%METHOD_PARAMS%) {

		if (request.getUserPrincipal() == null) {
			throw new ResponseStatusException(HttpStatus.NETWORK_AUTHENTICATION_REQUIRED, "Not authorized");
		}
		Integer operatorId = ((JepPrincipal) request.getUserPrincipal()).getOperatorId();
	    
		%METHOD_CONSTRUCTOR%

		%METHOD_RESULT%;
	}		 
};


use constant TEMPLATE_DTO => q{
package com.technology.project.%SERVICE_CLASS_PATH%.dto;

import java.math.BigDecimal;

public class %CLASS%Dto {
	%DTO_PARAMETERS%
}
};

use constant TEMPLATE_DTO_PARAMETER => q{

	private %TYPE% %NAME%; %COMMENT%

	public %TYPE% get%UCNAME%() {
		return %NAME%;
	}

	public void set%UCNAME%(%TYPE% %NAME%) {
		this.%NAME% = %NAME%;
	}

};

use constant TEMPLATE_SERVICE_DAO_INTERFACE => q{
package com.technology.project.%SERVICE_CLASS_PATH%.dao;


public interface %SERVICE_CLASS%Dao {
	%SERVICE_DAO_INTERFACE_METHODS%
}

};

use constant TEMPLATE_SERVICE_DAO_INTERFACE_METHOD => q{
	public %METHOD_TYPE% %METHOD_NAME%(%METHOD_PARAMS%);};

use constant TEMPLATE_SERVICE_DAO => q{
package com.technology.project.%SERVICE_CLASS_PATH%.dao;


import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.jepria.compat.server.dao.ResultSetMapper;
import org.jepria.server.data.DaoSupport;


public class %SERVICE_CLASS%DaoImpl implements %SERVICE_CLASS%Dao {

	%SERVICE_DAO_METHODS%
  
}
};


use constant TEMPLATE_NEW_DAO => q|
package com.technology.project.%SERVICE_CLASS_PATH%.dao;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.List;

import org.apache.log4j.Logger;
import org.jepria.compat.server.dao.ResultSetMapper;
import org.jepria.server.data.DaoSupport;

import com.technology.project.%SERVICE_CLASS_PATH%.dto.%CLASS%Dto;

public class %CLASS%Dao {
	
	%NEW_DAO_METHODS%
  
|;


use constant TEMPLATE_REST_CLIENT => q{
package com.technology.project.%CLIENT_PATH%.rest;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.springframework.web.bind.annotation.*;
import com.technology.project.%CLIENT_PATH%.dto.CustomerDto;
import com.technology.project.%CLIENT_PATH%.restclient.DatabaseRestClient;

import java.util.HashMap;

@RestController
public class %SERVICE_CLASS%Rest {

		
	DatabaseRestClient %SERVICE_CLASS_LCFIRST%Client;
	
	public %SERVICE_CLASS%Rest() {
		this.%SERVICE_CLASS_LCFIRST%Client = DatabaseRestClient.getInstance();
	}


	%REST_CLIENT_METHODS%
  
}
};


use constant TEMPLATE_REST_CLIENT_METHOD => q{
	public %TYPE% %METHOD% (%PARAMETERS%) {
		%BODY%
	}
};


use constant TEMPLATE_SERVICE_DAO_GETTER_PUT => q{
		return true;
};

use constant TEMPLATE_SERVICE_DAO_GETTER_GET => q{
		return new %DTO_CLASS%(){{
%DTO_CLASS_PARAMS%
		}};
};

use constant TEMPLATE_SERVICE_DAO_METHOD => q{
	@Override
	public %METHOD_TYPE% %METHOD_NAME%(%METHOD_PARAMS%) {
	    
		%METHOD_CONSTRUCTOR%
		%METHOD_GETTER%
	}
};
	

use constant TEMPLATE_TOMCAT_REDIRECT => q{
    ProxyPass  /%SERVICE_CLASS% http://vsmldbscd2.rusfinance.ru:81/%SERVICE_CLASS%
    ProxyPassReverse  /%SERVICE_CLASS% http://vsmldbscd2.rusfinance.ru:81/%SERVICE_CLASS%
    <Location /%SERVICE_CLASS%/ >
        Order allow,deny
        Allow from all
    </Location>
};
	

sub put_getter {
	my %h      = @_;

	return 'service.' . $h{name}->{old_name} . '(' . join(',', map {
		my $rest_id = $_->{rest_id};

		my $is_dto = grep {lc($_->{camel_name}) eq lc($rest_id)} @{$h{dto_parameters}};
		$rest_id =~ /operatorId/i 
			? "\n\t\t\toperatorId" 
			: !$is_dto
				? "\n\t\t\t$rest_id"
				:set_values(&TEMPLATE_EXEMPLAR_PARAMETER, {
					'%CLASS%'      => lcfirst($h{class}),
					'%PARAMETER%'  => ucfirst($rest_id),
				})
	} @{$h{parameters}}) .  ')';
}

sub main_parameter {
	my %h      = @_;
	
	my $result = '';

	my @first_parameter = grep {lc($_->{rest_name}) eq lc($h{name}->{name} || $h{class})} @{$h{parameters}};
	if (@first_parameter) {
		$result .= set_values(&TEMPLATE_REST_PARAMETER_GET, {
			'%NAME%' => $first_parameter[0]->{rest_id},
			'%TYPE%' => $first_parameter[0]->{type}});
	}
	$result .= join(',', map {set_values(&TEMPLATE_REST_PARAMETER_GET, {'%NAME%' => $_->{rest_id}, '%TYPE%' => $_->{type}})} grep {
		my $rest_id = $_->{rest_id};
		$rest_id !~ /operatorId/i
		&& lc($_->{rest_name}) ne lc($h{name}->{name} || $h{class})
		&& !grep {lc($_->{camel_name}) eq lc($rest_id)} @{$h{dto_parameters}}
	} @{$h{parameters}});
	
	return $result;
}

sub main_parameter_path {
	my %h      = @_;
	my @first_parameter = grep {$_->{rest_name} eq lc($h{name}->{name} || $h{class})} @{$h{parameters}};
	
	my $parameters = join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {
		my $rest_id = $_->{rest_id};
		$rest_id !~ /operatorId/i
		&& lc($_->{rest_name}) ne lc($h{name}->{name} || $h{class})
		&& !grep {lc($_->{camel_name}) eq lc($rest_id)} @{$h{dto_parameters}}
	} @{$h{parameters}});

	if (@first_parameter) {
		return '/' . lcfirst($first_parameter[0]->{rest_name}) . '/{' . $first_parameter[0]->{rest_id} . '}/' . $parameters;
	} else {
		return '/' . (lcfirst($h{name}->{name} || $h{class})) . '/' . $parameters;
	}
}

sub all_parameter {
	my %h      = @_;

	return join(',', map {set_values(&TEMPLATE_REST_PARAMETER_GET, {'%NAME%' => $_->{rest_id}, '%TYPE%' => $_->{type}})} grep {$_->{rest_id} !~ /operatorId/i} @{$h{parameters}});
}

sub dao_getter_get {
	my %h      = @_;
	if (isDto($h{type})) {
		return 'JepOption ' . lcfirst($h{dto}) . ' = '.lcfirst($h{dto}).'Dao.' .$h{name}->{old_name}  . '(' . join (',', map {$_->{rest_id}} @{$h{parameters}}) . ");\n"
			. set_values(&TEMPLATE_SERVICE_DAO_GETTER_GET, {
				'%DTO_CLASS%' => "$h{dto}Dto",
				'%DTO_CLASS_PARAMS%' => join("\n", map {'			set' . ucfirst($_->{camel_name}) . '(' . lcfirst($h{dto}) . ".get($_->{name}));"} @{$h{dto_parameters}}),
			});
	} else { 
		return 'return ' . lcfirst($h{dto}).'Dao.' .$h{name}->{old_name}  . '(' . join (',', map {$_->{rest_id}} @{$h{parameters}}) . ");";
	}
}

sub dao_getter_put {
	my %h      = @_;
	
	if (isDto($h{type})) {
		return 'JepOption ' . lcfirst($h{dto}) . ' = '.lcfirst($h{dto}).'Dao.' .$h{name}->{old_name}  . '(' . join (',', map {$_->{rest_id}} @{$h{parameters}}) . ");\n"
			. set_values(&TEMPLATE_SERVICE_DAO_GETTER_GET, {
				'%DTO_CLASS%' => "$h{dto}Dto",
				'%DTO_CLASS_PARAMS%' => join("\n", map {'			set' . ucfirst($_->{camel_name}) . '(' . lcfirst($h{dto}) . ".get($_->{name}));"} @{$h{dto_parameters}}),
			});
	} else { 
		return 'return ' . lcfirst($h{dto}).'Dao.' .$h{name}->{old_name}  . '(' . join (',', map {$_->{rest_id}} @{$h{parameters}}) . ");";
	}
}

sub isDto {
	my $type = shift;
	
	return $type =~ /(?:(List)<\s*)?\s*(?:JepOption|OptionDto|JepRecord|RecordDto)/;
}

sub type_name_or_class {
	my %h      = @_;
	my $list_prefix = '';
	my $list_postfix = $h{is_list} ? '[]' : '';

	return $list_prefix . (isDto($h{type}) ? ucfirst($h{name}->{name} || $h{class}) . 'Dto' : $h{type}) . $list_postfix;
}

sub type_class {
	my %h      = @_;

	my $list_prefix = '';
	my $list_postfix = $h{is_list} ? '[]' : '';

	return $list_prefix . (isDto($h{type}) ? ucfirst($h{class}) . 'Dto' : $h{type}) . $list_postfix;
}

sub type_name {
	my %h      = @_;
	
	my $list_prefix = '';
	my $list_postfix = $h{is_list} ? '[]' : '';

	return $list_prefix . (isDto($h{type}) ? ucfirst($h{name}->{name}) . 'Dto' : $h{type}) . $list_postfix;
}

sub type_name_or_class_dao {
	my %h      = @_;
	my $list_prefix = $h{is_list} ? 'List<' : '';
	my $list_postfix = $h{is_list} ? '>' : '';

	return $list_prefix . (isDto($h{type}) ? ucfirst($h{name}->{name} || $h{class}) . 'Dto' : $h{type}) . $list_postfix;
}

sub type_class_dao {
	my %h      = @_;

	my $list_prefix = $h{is_list} ? 'List<' : '';
	my $list_postfix = $h{is_list} ? '>' : '';

	return $list_prefix . (isDto($h{type}) ? ucfirst($h{class}) . 'Dto' : $h{type}) . $list_postfix;
}

sub type_name_dao {
	my %h      = @_;
	
	my $list_prefix = $h{is_list} ? 'List<' : '';
	my $list_postfix = $h{is_list} ? '>' : '';

	return $list_prefix . (isDto($h{type}) ? ucfirst($h{name}->{name}) . 'Dto' : $h{type}) . $list_postfix;
}

sub client_body_set {
	my %h      = @_;

	return $h{dto_parameters} && scalar(@{$h{dto_parameters}}) > 0
		? $h{dto} . "Dto " . lcfirst($h{dto}) . " = new " . $h{dto} . "Dto(){{\n\t\t\t" . join("\t\t\t", map {"set" . ucfirst($_->{camel_name}). "($_->{camel_name});\n"} @{$h{dto_parameters}}) . "\t\t\t}};\n"
			. "\n\t\t" . ($h{dao_type} ne 'void' ? ' return ': '') . lcfirst($h{service_class}) . "Client.put(%REST_CLIENT_PATH%, %TYPE%.class, new HashMap(), " . lcfirst($h{dto}) . ");"
		: "\t\t" . ($h{dao_type} ne 'void' ? ' return ': '') . lcfirst($h{service_class}) . "Client.put(%REST_CLIENT_PATH%, %TYPE%.class, new HashMap());";
}
use constant CONVERT => {
	createOrUpdate => {
		path => sub {
			my %h      = @_;
			my @first_parameter = grep {$_->{rest_name} eq lc($h{class})} @{$h{parameters}};
			if (@first_parameter) {
				return '/' . lcfirst($first_parameter[0]->{rest_name}) . '/{' . $first_parameter[0]->{rest_id} . '}';
			}
			return '/' . lcfirst($h{class});
		},
		type => \&type_class,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{class});
		},
		getter => \&put_getter,
		parameters => \&main_parameter,
		method_pattern => &TEMPLATE_REST_PUT,
		dao_getter => \&dao_getter_put,
		dao_type => \&type_class_dao,
		client_body => \&client_body_set,
	},
	create => {
		path => \&main_parameter_path,
		type => \&type_name_or_class,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{name}->{name} || $h{class});
		},
		getter => \&put_getter,
		parameters => \&main_parameter,
		method_pattern => &TEMPLATE_REST_PUT,
		dao_getter => \&dao_getter_put,
		dao_type => \&type_name_or_class_dao,
		client_body => \&client_body_set,
	},
	update => {
		path => \&main_parameter_path,
		type => \&type_name_or_class,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{name}->{name} || $h{class});
		},
		getter => \&put_getter,
		parameters => \&main_parameter,
		method_pattern => &TEMPLATE_REST_PUT,
		dao_getter => \&dao_getter_put,
		dao_type => \&type_name_or_class_dao,
		client_body => \&client_body_set,
	},
	set => {
		path => \&main_parameter_path,
		type => \&type_name_or_class,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{name}->{name} || $h{class});
		},
		getter => \&put_getter,
		parameters => \&main_parameter,
		method_pattern => &TEMPLATE_REST_PUT,
		dao_getter => \&dao_getter_put,
		dao_type => \&type_name_or_class_dao,
		client_body => \&client_body_set,
	},
	delete => {
		path => sub {
			my %h      = @_;
			my @first_parameter = grep {$_->{rest_name} eq lc($h{name}->{name} || $h{class})} @{$h{parameters}};
			if (@first_parameter) {
				return '/' . $first_parameter[0]->{rest_name} . '/{' . $first_parameter[0]->{rest_id} . '}/' . join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {$_->{rest_name} ne lc($h{name}->{name} || $h{class})}  grep {$_->{rest_id} !~ /operatorId/i} @{$h{parameters}});
			} else {
				return '/' . lcfirst($h{name}->{name} || $h{class}) . '/' . join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {$_->{rest_id} !~ /operatorId/i} @{$h{parameters}});
			}
		},
		type => \&type_name_or_class,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{name}->{name} || $h{class});
		},
		method_pattern => &TEMPLATE_REST_DELETE,
		dao_getter => \&dao_getter_put,
		dao_type => \&type_name_or_class_dao,
		client_body => sub {
			my %h      = @_;
			return "\t\t" . ($h{dao_type} ne 'void' ? ' return ': '') . lcfirst($h{service_class}) . "Client.delete(%REST_CLIENT_PATH%, %TYPE%.class, new HashMap());";
		},
		getter => sub {
			my %h      = @_;

			return ' service.' . $h{name}->{old_name} . '(' . join(',', map {$_->{rest_id}} @{$h{parameters}}) . ');';
			
		},
	},
	retrieve => {
		
		path => sub {
			my %h      = @_;
			my @first_parameter = grep {$_->{rest_name} eq lc($h{class})} @{$h{parameters}};
			if (@first_parameter) {
				return '/' . $first_parameter[0]->{rest_name} . '/{' . $first_parameter[0]->{rest_id} . '}/' . join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {$_->{rest_name} ne lc($h{class})} grep {$_->{rest_id} !~ /operatorId/i}  @{$h{parameters}});
			} else {
				return '/' . lcfirst($h{class}) . '/' . join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {$_->{rest_id} !~ /operatorId/i} @{$h{parameters}});
			}
		},
		type => \&type_class,
		dao_type => \&type_class_dao,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{class});
		},
	},
	get => {
		path => sub {
			my %h      = @_;
			return '/' . lcfirst($h{name}->{name} || $h{class}) . '/' . join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {$_->{rest_id} !~ /operatorId/i} @{$h{parameters}});
		},
		type => \&type_name_or_class,
		dao_type => \&type_name_or_class_dao,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{name}->{name} || $h{class});
		},
	},
	find => {
		path => sub {
			my %h      = @_;
			return '/' . lcfirst($h{name}->{name} || $h{class}) . '/' . join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {$_->{rest_id} !~ /operatorId/i}  @{$h{parameters}});
		},
		type => \&type_name_or_class,
		dao_type => \&type_name_or_class_dao,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{name}->{name} || $h{class});
		},
	},
	'default' => {
		path => sub {
			my %h      = @_;
			return '/' . lcfirst($h{name}->{name}) . '/' . join('/', map {$_->{rest_name} . '/{' . $_->{rest_id} . '}'} grep {$_->{rest_id} !~ /operatorId/i}  @{$h{parameters}});
		},
		type => \&type_name,
		dto => sub {
			my %h      = @_;
			return ucfirst($h{name}->{name});
		},
		getter => sub {
			my %h      = @_;

			my $result = '';
			my $type = $h{dao_type};
			$type =~ s/^\s*List<//;
			$type =~ s/>\s*$//;
			
			if ($h{is_list}) {
				$result = "List<" . ucfirst($type) . '> ' . lcfirst($type) . ' = service.' . $h{name}->{old_name} . '(' . join(',', map {$_->{rest_id}} @{$h{parameters}}) . ");\n"
				. "\t\treturn ".lcfirst($type).".toArray(new " . ucfirst($type) . "[" . lcfirst($type) . ".size()]);";
			} else {
				$result = 'return service.' . $h{name}->{old_name} . '(' . join(',', map {$_->{rest_id}} @{$h{parameters}}) . ');';
			}
			return $result;
		},
		parameters => \&all_parameter,
		method_pattern => &TEMPLATE_REST_GET,
		dao_getter => \&dao_getter_get,
		dao_type => \&type_name_dao,
		client_body => sub {
			my %h      = @_;
			return "\t\treturn " . lcfirst($h{service_class}) . "Client.get(%REST_CLIENT_PATH%, %TYPE%.class, new HashMap());";
		},
	},
};

sub set_values {
	my $template = shift;
	my $values   = shift;


	foreach my $value (keys %{$values}) {

		my $replace = $values->{$value};

		$template =~ s/$value/$replace/g;
	}

	return $template;
}

sub handler {
	my $self = shift;
	my $r    = shift;

	my $req = Apache2::Request->new($r);

	my $param_hash = $self->{param_hash};

	if ($param_hash->{dao_file}){
		$r->content_type('text/html;charset=utf-8');

		my $dao_file;
		my $service_class = $param_hash->{service_class};
		my $client_project = $param_hash->{client_project};
		read $param_hash->{dao_file}->{file_handler}, $dao_file, $param_hash->{dao_file}->{file_size};

		if (my $result_rest = get_rest($dao_file, $param_hash->{dao_file}->{file_name}, $service_class, $client_project)) {
			$self->print_html(qq{
				
				<h1>Convert DAO to REST</h1>
				
				<form enctype="multipart/form-data" name="input" action="/Service" method="post">
			});

			foreach my $path (sort keys %{$result_rest}){
				$self->print_html(qq{
							<br>$path
				});
				foreach my $file (@{$result_rest->{$path}}){
					my $rnd = int(rand(10000));
					if (open HTML_FILE, '>' . "/var/www/html/$rnd$file->{path}"){
						print HTML_FILE $file->{body};
						close HTML_FILE;
						$self->print_html(qq{
								<br>
								&emsp;<a href="/html/$rnd$file->{path}" download>$path$file->{path}</a>&emsp;-&nbsp;$file->{name}
						});
					} else {
						$self->print_html(qq{
								<br>
								<h2>Can't generate $file->{name}</a>
						});					
					}
				}
			}
			
			
			$self->print_html(qq{
				</form>
			});
		}		


	} else {
		$r->content_type('text/html');
		$self->print_html(q{
			
			<h1>Convert DAO to REST</h1>
			
			<form enctype="multipart/form-data" name="input" action="/Service" method="post">
			<input type="file"   name="dao_file" />
			Service class: <input type="input"  name="service_class" />
			Client project: <input type="input"  name="client_project" />
			<input type="hidden" name="handler" value="dao_to_rest"/>
			<input type="hidden" name="wait" value="0"/>
			<input type="submit" value="Get REST" />
			</form>
			
		});
	}
  
	return Apache2::Const::OK;
}
sub convert_name {
	my $name = shift;
	if ($name =~ /^(delete|find|update|get|set|createOrUpdate|create)?(\w*)$/i){
		return {
			old_name  => $name,
			name      => $2,
			type      => $1,
		};
	}
	return {
		old_name  => $name,
		name      => $name,
		type      => '',
	};
};

sub convert_parameters {
	my $parameters = shift;
	
	my $parameters_array = [];
	foreach my $parameter (split(',', $parameters)) {
		$parameter =~ s/\s*+(.+)\s*+/$1/;

		if ($parameter =~ /^(\w+)\s+(\w+?)(id|name)?$/i){
			push(@{$parameters_array}, {
				name      => $parameter,
				type      => $1,
				rest_name => lc($2),
				rest_id   => "$2$3",
			});
		}
	}
	return 	$parameters_array;
};

sub get_parameter_type_from_dto {
	my $parameter_getter = shift;
	my $body = shift;
	
	if ( $parameter_getter =~ /"\w+"\.equals/) {
		return 'Boolean';
		
	} elsif ($parameter_getter =~ /getInteger/) {
		return 'Integer';
		
	} elsif ($parameter_getter =~ /getString/) {
		return 'String';
	} elsif ($parameter_getter =~ /getBoolean/) {
		return 'Boolean';
	} elsif ($parameter_getter =~ /getTimestamp/) {
		return 'Timestamp';
		
	} elsif ($parameter_getter =~ /getBigDecimal/) {
		return 'BigDecimal';
		
	} elsif ($parameter_getter =~ /\s*\w+\[(\d+)\]\s*$/) {
		my $parameter_index = $1;
		my $found = 0;
		my $item = 0;
		while ($body =~ /(new\s+Object\[\]\s*{|(\w++)\.class)/g) {
			my $string = $1;
			if ($found) {
				if ($string =~ /(\w++)\.class/) {
					if ($item == $parameter_index) {
						return $1;
					}
					$item++;
				}
			}
			$found = ($string =~/new\s+Object\[\]\s*{/ )
				if !$found;
		}
	} 
	return 'NotFound';
}

sub exec_in_hash {
	my $item = shift;
	my $h    = shift;

	$h->{item} = $item;
	
	my %h    = %{$h};

	return 
		&CONVERT->{$h{name}->{old_name}}->{$h{item}} 
			? &CONVERT->{$h{name}->{old_name}}->{$h{item}}(%h) 
			: &CONVERT->{$h{name}->{type}}->{$h{item}}
				? &CONVERT->{$h{name}->{type}}->{$h{item}}(%h)	
				: &CONVERT->{'default'}->{$h{item}}(%h);
}

sub get_from_hash {
	my %h       = @_;

	return &CONVERT->{$h{name}->{old_name}}->{$h{item}} 
	|| &CONVERT->{$h{name}->{type}}->{$h{item}} 
	|| &CONVERT->{'default'}->{$h{item}};
}

sub get_rest {
	my $data = shift;
	my $class = shift;
	my $service_class = shift;
	my $client_project = shift;
	$class =~ s/Dao\.java//;

	my $files = {};
	$files->{lc($service_class) . '/dto/'} = [];

	my $rest = '';
	my $rest_methods = '';
	my $service_dao_interface_methods = '';
	my $service_dao_methods = '';
	my $service_dto_hash = {};
	my $new_dao_class = '';
	my $rest_client_methods = '';
	
	
	my $chunk_regexp = '\s*(public\s+([\w<>]+)\s+(\w+)\s*\(\s*([^\)]+)\s*\)\s*(?:throws\s+ServiceException\s*)?{)\s*';
	my @chunks = split(/$chunk_regexp/sm, $data);
	shift(@chunks);

	#find dtos
	for (my $i = 0; $i < scalar(@chunks)/5 ; $i++) {
		my $signature = $chunks[$i*5];
		my $type = $chunks[$i*5+1];
		my $name = convert_name($chunks[$i*5+2]);
		my $parameters = convert_parameters($chunks[$i*5+3]);
		my $body = $chunks[$i*5+4];

		my $current_dto = '';
		my $parameters_count = 0;
		my $dto_parameters = [];

		my $context = {
			class          => $class,
			type           => $type,
			name           => $name,
			parameters     => $parameters,
			body           => $body,
			service_class  => $service_class,
		};
		
		if ($type =~ /(?:(List)<\s*)?\s*(?:JepOption|OptionDto|JepRecord|RecordDto)/) {
                                  #result.put                      ( ApplicationSu.ATE,     rs.getTimestamp(ApplicationSummaryFieldNames.AS_APPLICATION_DATE, DaoSupport.getInstance().getCalendar()));
			while ($body =~ /((?:\w+)\.(?:put|setName|setValue)\s*\((?:\s*([\w\.]+)\s*,)?\s*(.+)\s*\);(.*))/g) {
				my $dto_parameter_body = $1;
				my $dto_parameter_type = get_parameter_type_from_dto($3, $body);
				my $dto_parameter_getter = $3;
				my $dto_parameter_name = $2 ? $2 : $3;
				my $dto_comment = $4;
				$dto_parameter_name =~ s/^.+\((.+)\)$/$1/;

				my $camel_name = lc($dto_parameter_name);
				$camel_name =~ s/^.*?([^\.]++)$/$1/;
				$camel_name =~ s/_(\w)/uc($1)/ge;
				
				$current_dto .= set_values(&TEMPLATE_DTO_PARAMETER, {
					'%TYPE%'   => $dto_parameter_type,
					'%NAME%'   => $camel_name,
					'%UCNAME%' => ucfirst($camel_name),
					'%COMMENT%' => $dto_comment,
				});
				push(@{$dto_parameters}, {
					body => $dto_parameter_body,
					getter => $dto_parameter_getter,
					name => $dto_parameter_name,
					type => $dto_parameter_type,
					comment => $dto_comment,
					camel_name => $camel_name,
				});
				$parameters_count++;
			}
			

			my $dto = exec_in_hash('dto', $context);

			$service_dto_hash->{$dto} = {
				parameters_count => $parameters_count,
				parameters       => $dto_parameters,
				code             => $current_dto,
			} if !$service_dto_hash->{$dto} || $parameters_count > $service_dto_hash->{$dto}->{parameters_count};
		}
	}

	# generate files
	for (my $i = 0; $i < scalar(@chunks)/5 ; $i++) {
		my $signature = $chunks[$i*5];
		my $type = $chunks[$i*5+1];
		my $name = convert_name($chunks[$i*5+2]);
		my $parameters = convert_parameters($chunks[$i*5+3]);
		my $body = $chunks[$i*5+4];
		
		my $new_body = $body;

		my $context = {
			class          => $class,
			type           => $type,
			name           => $name,
			parameters     => $parameters,
			body           => $body,
			service_class  => $service_class,
			is_list        => $type =~ /List\s*<\s*(?:JepOption|OptionDto|JepRecord|RecordDto)/,
		};

		my $dto = exec_in_hash('dto', $context);

		$context->{dto_parameters} = $service_dto_hash->{$dto}->{parameters};
		$context->{dto} = $dto;
		my $dao_type = exec_in_hash('dao_type', $context);
		$context->{dao_type} = $dao_type;
		
		$new_body = exec_in_hash('dao_type', $context) . ' ' . $name->{old_name} . '('. join(', ', map {$_->{name}} @{$parameters}) . ") {\n" . $new_body;
		
		
		while ($body =~ /((\w+)\.(put|setName|setValue|get)\s*\((?:\s*([\w\.]+)\s*,)?\s*(.+)\s*\)(;)?(.*))$/mg) {
				my $dto_object = $2;
				my $dto_action = $3;
				my $dto_parameter_body = $1;
				my $dto_parameter_type = get_parameter_type_from_dto($5, $body);
				my $dto_parameter_getter = $5;
				my $dto_parameter_name = $4 ? $4 : $5;
				my $comma = $6;
				my $dto_comment = $7;
				$dto_parameter_name =~ s/^.+\((.+)\)$/$1/;

				my $camel_name = lc($dto_parameter_name);
				$camel_name =~ s/^.*?([^\.]++)$/$1/;
				$camel_name =~ s/_(\w)/uc($1)/ge;

											
				if ($dto_action =~ /get/) {
					my $dto_parameter_setter = ($dto_object=~/dto/ ? lcfirst("${dto}.get") : "${dto_object}.get") . ucfirst($camel_name) . "()${comma}" . $dto_comment;
					$new_body =~ s/\Q$dto_parameter_body\E/$dto_parameter_setter/g;
				} else  {
					my $dto_parameter_setter = ($dto_object=~/dto/ ? lcfirst("${dto}.set") : "${dto_object}.set") . ucfirst($camel_name) . '(' . ($dto_parameter_getter =~ /\[\d+\]/ ? "($dto_parameter_type) " : '') . $dto_parameter_getter . ")${comma}" . $dto_comment;
					$new_body =~ s/\Q$dto_parameter_body\E/$dto_parameter_setter/g;
				}

		}
		$new_body =~ s/DaoSupport\.|WrapperDao\./DaoSupport.getInstance()./g;
		$new_body =~ s/(JepOption|OptionDto|JepRecord|RecordDto)\s+dto/$1 \l${dto}/g;
		$new_body =~ s/JepOption|OptionDto|JepRecord|RecordDto/${dto}Dto/g;
		$new_body =~ s/exec/execute/g;
		$new_body =~ s/super\.find/DaoSupport.getInstance().find/g;
		$new_body =~ s/ServiceException/SQLException/g;
		$new_body =~ s/super.getOptions/DaoSupport.getInstance().find/g;
		$new_body =~ s/super.executeAndReturn/DaoSupport.getInstance().executeAndReturn/g;
		$new_body =~ s/super.execute/DaoSupport.getInstance().execute/g;
		
		$new_dao_class .= $new_body . "\n\n";
		
		$rest_methods .= set_values(get_from_hash(name=>$name, item=>'method_pattern'), {
			'%METHOD_PATH%'        => exec_in_hash('path', $context),
			'%METHOD_TYPE%'        => exec_in_hash('type', $context),
			'%METHOD_NAME%'        => $name->{old_name},
			'%METHOD_PARAMS%'      => exec_in_hash('parameters', $context),
			'%METHOD_CONSTRUCTOR%' => '',
			'%METHOD_RESULT%'      => exec_in_hash('getter', $context),
			'%CLASS%'              => $dto . 'Dto',
			'%PARAMETER%'          => lcfirst($class),
		});

		$service_dao_interface_methods .= set_values(&TEMPLATE_SERVICE_DAO_INTERFACE_METHOD,{
			'%METHOD_TYPE%'   => exec_in_hash('dao_type', $context),
			'%METHOD_NAME%'   => $name->{old_name},
			'%METHOD_PARAMS%' => join(', ', map {$_->{name}} @{$parameters}),
		});


		my $has_dto_parameter = 0;
		if ($service_dto_hash->{$dto}->{parameters} && !$service_dto_hash->{$dto}->{printed}) {
			push(@{$files->{lc($service_class) . '/dto/'}}, {body => set_values(&TEMPLATE_DTO, {
				'%SERVICE_CLASS%'  => $service_class,
				'%SERVICE_CLASS_PATH%'  => lc($service_class),
				'%CLASS%'          => ucfirst($dto),
				'%DTO_PARAMETERS%' => $service_dto_hash->{$dto}->{code},
			}), path => "${dto}Dto.java" , name => "Найденный в DAO объект DTO (функция $name->{old_name})"});
			$service_dto_hash->{$dto}->{printed} = 1;
			$has_dto_parameter = 1;
		}

		my $dao_type = exec_in_hash('dao_type', $context);
		$service_dao_methods .= set_values(&TEMPLATE_SERVICE_DAO_METHOD,{
			'%METHOD_TYPE%'   => $dao_type,
			'%METHOD_NAME%'   => $name->{old_name},
			'%METHOD_PARAMS%' => join(', ', map {$_->{name}} @{$parameters}),
			'%METHOD_CONSTRUCTOR%' => $class . 'Dao ' . lcfirst($class) . 'Dao = new ' . $class . 'Dao();',
			'%METHOD_GETTER%' => ($dao_type ne 'void' ? 'return ': '') . lcfirst($class).'Dao.' .$name->{old_name}  . '(' . join (',', map {$_->{rest_id}} @{$parameters}) . ");",
		});
		
		$rest_client_methods .= set_values(&TEMPLATE_REST_CLIENT_METHOD, {
			'%TYPE%'				  => exec_in_hash('type', $context),
			'%METHOD%'                => $name->{old_name},
			'%PARAMETERS%'            => join(', ', map {$_->{name}} grep {$_->{rest_id} !~ /operatorId/i} @{$parameters}),
			'%BODY%'                  => set_values(exec_in_hash('client_body', $context),{
				'%REST_CLIENT_PATH%'      => replace_path_parameter_to_client("/$service_class" . exec_in_hash('path', $context)),
				'%TYPE%'				  => exec_in_hash('type', $context),
			}),
		});
#exec_in_hash('dao_getter', $context)
	}
	
	$rest .= set_values(&TEMPLATE_REST, {
		'%SERVICE_CLASS%'  => $service_class,
		'%SERVICE_CLASS_PATH%'  => lc($service_class),
		'%REST_METHOD%'  => $rest_methods,
		'%CLASS%'        => "${service_class}Controller",
	});
	
	$files->{lc($service_class) . '/'} = [];
	push(@{$files->{lc($service_class) . '/'}}, {body => $rest, path => "${service_class}Controller.java", name => "Входные точки REST сервиса"});

	$files->{lc($service_class) . '/dao/'} = [];
	push(@{$files->{lc($service_class) . '/dao/'}}, {body => set_values(&TEMPLATE_SERVICE_DAO_INTERFACE, {
		'%SERVICE_CLASS%'  => $service_class,
		'%SERVICE_CLASS_PATH%'  => lc($service_class),
		'%SERVICE_DAO_INTERFACE_METHODS%' => $service_dao_interface_methods,
	}), path => "${service_class}Dao.java", name => "DAO интерфейс с врапперами"});
	push(@{$files->{lc($service_class) . '/dao/'}}, {body => set_values(&TEMPLATE_SERVICE_DAO, {
		'%SERVICE_CLASS%'  => $service_class,
		'%SERVICE_CLASS_PATH%'  => lc($service_class),
		'%SERVICE_DAO_METHODS%' => $service_dao_methods,
	}), path => "${service_class}DaoImpl.java", name => "DAO класс с врапперами"});
	push(@{$files->{lc($service_class) . '/dao/'}}, {body => set_values(&TEMPLATE_NEW_DAO, {
		'%CLASS%'  => $class,
		'%SERVICE_CLASS_PATH%'  => lc($service_class),
		'%NEW_DAO_METHODS%'     => $new_dao_class,
	}), path => "${class}Dao.java", name => "Переписаный для использования в REST сервисе DAO класс с реализацией запросов"});
	
	$files->{'/etc/http/conf.d/'} = [];	
	push(@{$files->{'/etc/http/conf.d/'}}, {body => set_values(&TEMPLATE_TOMCAT_REDIRECT, {
		'%SERVICE_CLASS%'   => $service_class,
	}), path => "tomcat.redirect.conf", name => "Конфигурация прокси перлового апаче для REST сервиса"});

	$files->{lc($client_project) . '/rest/'} = [];	
	push(@{$files->{lc($client_project) . '/rest/'}}, {body => set_values(&TEMPLATE_REST_CLIENT, {
		'%CLIENT_PATH%'         => lc($client_project),
		'%SERVICE_CLASS%'       => $service_class,
		'%SERVICE_CLASS_LCFIRST%' => lcfirst($service_class),
		'%REST_CLIENT_METHODS%' => $rest_client_methods,
	}), path => "${service_class}Rest.java", name => "Все возможные запросы к REST сервису"});

	return $files;
}

sub replace_path_parameter_to_client{
	my $path = shift;
	$path =~ s/\{(\w+)\}/" + String.valueOf($1) + "/g;
	$path = "\"" . $path . "\"";
	$path =~ s/ \+ ""$//;

	return $path;
}
1;