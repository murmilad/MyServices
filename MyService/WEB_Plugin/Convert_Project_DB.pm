package MyService::WEB_Plugin::Convert_Project_DB;

use strict;

use utf8;
use Encode qw/ decode /;

use base "MyService::WEB_Plugin::Abstract";

use POSIX qw(strftime);

use File::Path qw(mkpath);
use File::Find;
use File::Copy;

use List::MoreUtils qw(uniq);

use Data::Dumper;
use Storable qw{thaw freeze};

use DateTime::Format::Strptime;
use DateTime;

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK);

use lib "/www/scn.lo/lib/";
use Project::DB_Deletable;


use constant HANDLER_MAP => {
	get_list => q{
				getListListener((String parameterName, Parameters parameters) -> {
					List<OptionDto> list = new LinkedList<OptionDto>();
/*
					%PERL_CODE%
*/
					return list;
				});
	},
	get_list_for_parrent => q{
				getListInteractiveListener((String parameterName, Parameters parameters) -> {
					List<OptionDto> list = new LinkedList<OptionDto>();
/*
					%PERL_CODE%
*/
					return list;
				});
	},
	check_param => q{
				checkListener((String parameterName, Parameters parameters) -> {
					List<String> errors = new LinkedList<String>();
/*
					%PERL_CODE%
*/
					return errors;
				});
	}
	
};

use constant DAO_NO_OUTPUT => q{
		WrapperDao.exec(
				sqlQuery
%INPUT_PARAMETERS%
		);
};


use constant DAO_LIST_RESULT => q{
		return super.getOptions(
              sqlQuery,
              new ResultSetMapper<OptionDto>() {
                  public void map(ResultSet rs, OptionDto dto) throws SQLException {
                      dto.setName(rs.getString(%UC_NAME%_NAME));
                      dto.setValue(rs.getString( %UC_NAME%_ID));
                  }
              }
%INPUT_PARAMETERS%
      	);
};

use constant DAO_LIST_PARAMETERS_RESULT => q{
		return super.getOptions(
              sqlQuery,
              new ResultSetMapper<OptionDto>() {
                  public void map(ResultSet rs, OptionDto dto) throws SQLException {
                      %OUTPUT_PARAMETERS%
                  }
              }
%INPUT_PARAMETERS%
      	);
};

use constant DAO_OUTPUT_PARAMETER_RESULT => q{
		Object[] outputObject = WrapperDao.<Object[]>execAndReturn(
			sqlQuery,
			Object[].class,
			new Object[] {
%OUTPUT_PARAMETER_TYPES%
			}
%INPUT_PARAMETERS%
		);
		RecordDto result = new RecordDto();
	
		%OUTPUT_PARAMETERS%

		return result;
};

use constant DAO_SINGLE_OUTPUT_PARAMETER_RESULT => q{
		Object[] outputObject = WrapperDao.<Object[]>execAndReturn(
			sqlQuery,
			Object[].class,
			new Object[] {
				String.class
			}
%INPUT_PARAMETERS%
		);

		return (String) outputObject[0];
};


use constant DAO_OUTPUT_SINGLE_PARAMETER_RESULT => q{
		return WrapperDao.<String>execAndReturn(
			sqlQuery
			, String.class
%INPUT_PARAMETERS%
		);
};

use constant TEMPLATES => {
	menue => {
		class  => q{
package com.technology.project.jfrontoffice.server.menu.item.action;


import static com.technology.project.jfrontoffice.server.menu.MenuConstant.*;
import static com.technology.project.jfrontoffice.server.dao.ApplicationSummaryDao.Condition.*;
import static com.technology.project.jfrontoffice.server.dao.ApplicationSummaryDao.Flag.*;
import static com.technology.project.jfrontoffice.server.dao.EmployeeProjectDao.AccessType.*;



import java.util.List;
import com.technology.jef.server.dto.RecordDto;
import com.technology.jef.server.exceptions.ServiceException;
import com.technology.project.jfrontoffice.server.dao.EmployeeProjectDao;
import com.technology.project.jfrontoffice.server.dao.ApplicationSummaryDao;
import com.technology.project.jfrontoffice.server.ProjectEnvironment;
import com.technology.project.jfrontoffice.server.menu.MenuParameters;
import com.technology.project.jfrontoffice.server.menu.ParameterHandler;
import com.technology.project.jfrontoffice.server.menu.item.ActionMenuItem;


/**
 * %HEADER%
 */

public class %CLASS_NAME% extends ActionMenuItem {


	@Override
	public void initMenuItem(MenuParameters menuParameters) {
/*
		menuParameters.addParameterHandler(MENU_PARAMETER_CAN_ACTIVATE_ONLINE_APPS, new ParameterHandler() {

			@Override
			public Object handle(MenuParameters menuParameters) throws ServiceException{
				return (((Integer) ((RecordDto) menuParameters.getParameter(MENU_PARAMETER_CURRENT_USER)).get(EmployeeProjectFieldNames.U_ACCESS_)) & EmployeeProjectDao.getAccessType(ONLINE_ACTIVATION)) > 0;
			}
			
		});
*/
	
	}


	@Override
	public Boolean isActive(MenuParameters menuParameters) throws ServiceException {

		%IS_ACTIVE%
	}

	@Override
	public String getHtml(MenuParameters menuParameters) throws ServiceException {

		%GET_HTML%

		return "<a href=\"/activation_app.html?id=" 
				+ menuParameters.getParameter(MENU_PARAMETER_APPLICATION_ID)
				+ "\" onclick=\"return confirm(\\'Активировать?\\');\">активировать&nbsp;анкету</a>";
	}

	@Override
	public String getHeader(MenuParameters menuParameters) {
		return "%HEADER%";
	}


}
			
		}
	},
	dao => {
		class  => q{
package com.technology.project.jfrontoffice.server.dao;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import com.technology.jep.jepria.server.dao.ResultSetMapper;
import com.technology.jef.server.exceptions.ServiceException;
import com.technology.jef.server.dto.OptionDto;
import com.technology.jef.server.dto.RecordDto;
import com.technology.project.jfrontoffice.server.field.AddressFieldNames;

import static com.technology.jef.server.serialize.SerializeConstant.*;

%PARAMETERS_CLASSES%

public class %CLASS_NAME%Dao extends WrapperDao {
	%METHODS%
}
		
		},
		method => q{
public %TYPE% %NAME%(%PARAMETERS%) throws ServiceException {
	String sqlQuery = %SQL%;

	%RESULT%
};
		},
		class_name => '%CLASS_NAME%Dao',
	},
	abstract => {
		class  => q{
package com.technology.project.jfrontoffice.server.da;

import java.util.List;

import com.technology.jep.jepria.server.dao.ResultSetMapper;
import com.technology.jef.server.exceptions.ServiceException;
import com.technology.jef.server.dto.OptionDto;
import com.technology.jef.server.dto.RecordDto;

public interface %CLASS_NAME% extends JepDataStandard {
	%METHODS%
}
		
		},
		method => q{
	public %TYPE% %NAME%(%PARAMETERS%) throws ApplicationException;
		},
		class_name => '%CLASS_NAME%',
	},
	field => {
		class  => q{
package com.technology.project.jfrontoffice.server.field;

public class %CLASS_NAME%FieldNames {
	%OUTPUT_PARAMETERS%
}
		},
		class_name => '%CLASS_NAME%FieldNames',
	},
	form => {
		class  => q{
package com.technology.project.jfrontoffice.server.form%INTERFACE_PARRENT_PATH%;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import com.technology.jef.server.exceptions.ServiceException;
import com.technology.jef.server.dto.OptionDto;
import com.technology.jef.server.dto.RecordDto;
import com.technology.jef.server.form.Field;
import com.technology.jef.server.form.Form;
import com.technology.jef.server.form.parameters.Parameters;

import com.technology.project.jfrontoffice.server.dao.%CLASS_NAME%Dao;
import com.technology.project.jfrontoffice.server.field.%CLASS_NAME%FieldNames;

/**
* Interface "%INTERFACE_CLASS_NAME%" controller
*/

public class %INTERFACE_CLASS_NAME%Form extends %PARRENT_CLASS_NAME%Form {

	@Override
	public Map<String, Field> getFieldsMap() {

		return new HashMap<String, Field>(){{
%PARAMETERS_MAP%
		}};
	}

	@Override
	public void load(Integer primaryId, Integer groupId, Parameters parameters) throws ServiceException {

		%CLASS_NAME%Dao %LC_CLASS_NAME%Dao = new %CLASS_NAME%Dao();
		
		setFormData(%LC_CLASS_NAME%Dao.retrieve(Integer.parseInt(parameters.get("operator_id")), primaryId));
	}


	@Override
	public Integer saveForm(Integer primaryId, Integer secondaryId, Parameters parameters)
			throws ServiceException {

		%CLASS_NAME%Dao %LC_CLASS_NAME%Dao = new %CLASS_NAME%Dao();
		
		RecordDto daoParameters = mapDaoParameters(parameters);

		daoParameters.put(%CLASS_NAME%FieldNames.OPERATOR_ID, Integer.parseInt(parameters.get("operator_id")));
		daoParameters.put(%CLASS_NAME%FieldNames.APPLICATION_ID, primaryId);

		%LC_CLASS_NAME%Dao.createOrUpdate(daoParameters);
		
		return primaryId;
	}	

}
		},
		class_name => '%CLASS_NAME%Form',
	},
};

use constant TYPES_MAP => {
	operatorId => 'Integer',
	applicationId => 'Integer', 
	cityId => 'Integer',
};

my $handler = sub {};
my $inout_handler = sub {};


sub Cursor::new {
    my $class = shift;

    bless {}, $class;
}

sub Cursor::fetchall_arrayref {
    my $class = shift;

    return [];
}

sub Sth::new {
    my $class = shift;

    bless {}, $class;
}

sub Sth::bind_param_inout {
	my $class = shift;
	my $name = shift;
	my $inout = shift;
	
	&$inout_handler($name);
	$$inout = Cursor->new();
}

sub Sth::bind_param {
	my $class = shift;
	my $name = shift;
	my $in = shift;
	
}

sub Sth::execute {
}

sub Sth::finish {
}

sub db_Main::new {
    my $class = shift;

    bless {}, $class;
}

sub db_Main::prepare{
	my $class = shift;
	my $query = shift;

	&$handler($query);

	return Sth->new();
}

sub Project::DB_Deletable::db_Main {
	return db_Main->new();
}

sub get_menue_class {
    my $module = shift;

	my $class_name = $module;
	$class_name =~ s/^.+:([^:]+)$/$1/;
	$class_name =~ s/_//g;


	my $location = $module . '.pm';
	$location =~ s/::/\//g;
	
	my $file_name = ucfirst($class_name).'.java';

	if (open MENUE_FILE, '<' . "/var/www/scn.lo/lib/" . $location){
		my $menue_pm = "";
		while (my $line = <MENUE_FILE>){
			$menue_pm .= $line;
		}
		close MENUE_FILE;
		$menue_pm = decode('Windows-1251', $menue_pm);
		
		if (open JAVA_FILE, '>' . "/var/www/html/$file_name"){
	
			print JAVA_FILE  set_values(&TEMPLATES->{menue}->{class}, {
				'%CLASS_NAME%' => $class_name,
				'%IS_ACTIVE%'    => get_menue_is_active($menue_pm),
				'%GET_HTML%'    => get_menue_html($menue_pm),
				'%HEADER%'    => get_header($menue_pm),
			});
			close JAVA_FILE;
	
			return $file_name;
		}

	}	
}
sub get_menue_is_active {
	my $menue_pm = shift;
	
	my $result = "";
	
	if ($menue_pm =~ /sub\s*is_active\s*\{(.+)\}\s+=head2/s){
		$result .= "/*\n$1\n*/";
		my $is_active = $1;
		$is_active =~ s/#/\/\//g;
		$is_active =~ s/defined\(\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_GOOD\)\)/menuParameters.getParameter(MENU_PARAMETER_AUTO_GOOD) != null/g;
		$is_active =~ s/(?:scalar\()?\@\{\$menue_operator->get_parameter\(&MENUE_PARAM_SERVICES_ERRORS\)\}\s*\)?\s*([><=]+)\s*(\d+)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_INTERFACE_ERRORS_SERVICE)).size() $1 $2/g;
		$is_active =~ s/(?:scalar\()?\@\{\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_GOOD_ERRORS\)\}\s*\)?\s*([><=]+)\s*(\d+)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_GOODS)).size() $1 $2/g;
		$is_active =~ s/\!\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() == 0/g;
		$is_active =~ s/\!\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_CONTRACT_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() == 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() != 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_CONTRACT_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() != 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_CURRENT_USER_ACCESS\)\s*&\s*\$Project::Constants::ACCESS_TYPE\{(\w+)\}->\[0\]/0 != (EmployeeProjectDao.getAccessType($1) & ((Integer)menuParameters.getParameter(MENU_PARAMETER_CURRENT_USER_ACCESS)))/g;
		$is_active =~ s/\!\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_INTERFACE_WARNINGS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_INTERFACE_WARNINGS)).size() == 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_INTERFACE_WARNINGS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_INTERFACE_WARNINGS)).size() > 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_ACOOUNT_NUMBER\)/!JepRiaUtil.isEmpty(menuParameters.getParameter(MENU_PARAMETER_ACOOUNT_NUMBER))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_(NEW_|OLD_)?APPLICATION_ID\)/(Integer)menuParameters.getParameter(MENU_PARAMETER_$1APPLICATION_ID)/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_PRODUCT\)/menuParameters.getParameter(MENU_PARAMETER_PRODUCT) != null/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_CURRENT_USER_ACCESS\)\s*&\s*\$Project::Constants::ACCESS_TYPE\{BO\}->\[0\]/(Boolean)menuParameters.getParameter(MENU_PARAMETER_USER_HAVE_BO_ROLE)/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_IS_INSURANCE_CONDITION\)\s*&\s*(\w+)\s*\)/0 == ($1 & (Integer)menuParameters.getParameter(MENU_PARAMETER_IS_INSURANCE_CONDITION))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_IS_INSURANCE_CONDITION\)\s*&\s*(\w+)/0 != ($1 & (Integer)menuParameters.getParameter(MENU_PARAMETER_IS_INSURANCE_CONDITION))/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_CONDITION\)\s*&\s*\$STATUS\{(\w+)\}\s*\)/0 == (ProjectEnvironment.getAppCondition($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_CONDITION))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_CONDITION\)\s*&\s*\$STATUS\{(\w+)\}/0 != (ProjectEnvironment.getAppCondition($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_CONDITION))/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_CONDITION\)\s*&\s*\$STATUS\{(\w+)\}\s*\)/0 == (ProjectEnvironment.getAppCondition($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_CONDITION))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_FLAGS\)\s*&\s*\$ANKETA_FLAG{(\w+)}/0 != (ApplicationSummaryDao.getFlag($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_FLAGS))/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_FLAGS\)\s*&\s*\$ANKETA_FLAG{(\w+)}\s*\)/0 == (ApplicationSummaryDao.getFlag($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_FLAGS))/g;
		$is_active =~ s/scalar\(\s*\@\{\s*\$menue_operator->get_parameter\(&MENUE_PARAM_(\w+)\)\s*\}\s*\)\s*([=>]+)\s*(\d+)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_$1)).size() $2 $3/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_(\w+)\)\s*eq\s*['"](.+?)['"]/((String)menuParameters.getParameter(MENU_PARAMETER_$1)).equals("$2")/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_(\w+)\)\s*ne\s*['"](.+?)['"]/!((String)menuParameters.getParameter(MENU_PARAMETER_$1)).equals("$2")/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_/(Boolean)menuParameters.getParameter(MENU_PARAMETER_/g;
		$is_active =~ s/MENU_PARAMETER_APPLICATION_PR_APPLICATION_ID/MENU_PARAMETER_PRECHECK_FILLED/g;
		$is_active =~ s/(\s+)\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_NEW_APPLICATION_ID\)\s*==\s*\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_APPLICATION_ID\)\s*[\r\n]+(\s+)\|\|\s*\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_OLD_APPLICATION_ID\)\s*==\s*\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_APPLICATION_ID\)\s*[\r\n]+/$1((Integer)menuParameters.getParameter(MENU_PARAMETER_NEW_APPLICATION_ID)).equals((Integer)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_ID)) \n$2|| ((Integer)menuParameters.getParameter(MENU_PARAMETER_OLD_APPLICATION_ID)).equals((Integer)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_ID))\n/g;
		$is_active =~ s/(\s+)\(\s*\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_NEW_APPLICATION_ID\)\s*==\s*\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_APPLICATION_ID\)\s*\)\s*[\r\n]+(\s+)\|\|\s*\(\s*\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_OLD_APPLICATION_ID\)\s*==\s*\(Integer\)menuParameters\.getParameter\(MENU_PARAMETER_APPLICATION_ID\)\s*\)\s*[\r\n]+/$1((Integer)menuParameters.getParameter(MENU_PARAMETER_NEW_APPLICATION_ID)).equals((Integer)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_ID)) \n$2|| ((Integer)menuParameters.getParameter(MENU_PARAMETER_OLD_APPLICATION_ID)).equals((Integer)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_ID))\n/g;
		$result .= $is_active;
	}
	
	return $result;
}

sub get_menue_html {
	my $menue_pm = shift;
	
	my $result = "";
	
	if ($menue_pm =~ /sub\s*get_menue_item\s*\{(.+)\}\s*1;/s){
		$result .= "/*\n$1\n*/";
		my $is_active = $1;
		$is_active =~ s/#/\/\//g;
		$is_active =~ s/defined\(\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_GOOD\)\)/menuParameters.getParameter(MENU_PARAMETER_AUTO_GOOD) != null/g;
		$is_active =~ s/(?:scalar\()?\@\{\$menue_operator->get_parameter\(&MENUE_PARAM_SERVICES_ERRORS\)\}\s*\)?\s*([><=]+)\s*(\d+)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_INTERFACE_ERRORS_SERVICE)).size() $1 $2/g;
		$is_active =~ s/(?:scalar\()?\@\{\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_GOOD_ERRORS\)\}\s*\)?\s*([><=]+)\s*(\d+)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_GOODS)).size() $1 $2/g;
		$is_active =~ s/\!\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() == 0/g;
		$is_active =~ s/\!\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_CONTRACT_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() == 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() != 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_AUTO_INSURANCE_CONTRACT_ERRORS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_CHECK_INTERFACE_ERRORS_INSURANCE)).size() != 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_CURRENT_USER_ACCESS\)\s*&\s*\$Project::Constants::ACCESS_TYPE\{(\w+)\}->\[0\]/0 != (EmployeeProjectDao.getAccessType($1) & ((Integer)menuParameters.getParameter(MENU_PARAMETER_CURRENT_USER_ACCESS)))/g;
		$is_active =~ s/\!\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_INTERFACE_WARNINGS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_INTERFACE_WARNINGS)).size() == 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_INTERFACE_WARNINGS\)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_APPLICATION_INTERFACE_WARNINGS)).size() > 0/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_ACOOUNT_NUMBER\)/!JepRiaUtil.isEmpty(menuParameters.getParameter(MENU_PARAMETER_ACOOUNT_NUMBER))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_(NEW_|OLD_)?APPLICATION_ID\)/(Integer)menuParameters.getParameter(MENU_PARAMETER_$1APPLICATION_ID)/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_PRODUCT\)/menuParameters.getParameter(MENU_PARAMETER_PRODUCT) != null/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_CURRENT_USER_ACCESS\)\s*&\s*\$Project::Constants::ACCESS_TYPE\{BO\}->\[0\]/(Boolean)menuParameters.getParameter(MENU_PARAMETER_USER_HAVE_BO_ROLE)/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_IS_INSURANCE_CONDITION\)\s*&\s*(\w+)\s*\)/0 == ($1 & (Integer)menuParameters.getParameter(MENU_PARAMETER_IS_INSURANCE_CONDITION))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_IS_INSURANCE_CONDITION\)\s*&\s*(\w+)/0 != ($1 & (Integer)menuParameters.getParameter(MENU_PARAMETER_IS_INSURANCE_CONDITION))/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_CONDITION\)\s*&\s*\$STATUS\{(\w+)\}\s*\)/0 == (ProjectEnvironment.getAppCondition($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_CONDITION))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_CONDITION\)\s*&\s*\$STATUS\{(\w+)\}/0 != (ProjectEnvironment.getAppCondition($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_CONDITION))/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_CONDITION\)\s*&\s*\$STATUS\{(\w+)\}\s*\)/0 == (ProjectEnvironment.getAppCondition($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_CONDITION))/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_FLAGS\)\s*&\s*\$ANKETA_FLAG{(\w+)}/0 != (ApplicationSummaryDao.getFlag($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_FLAGS))/g;
		$is_active =~ s/\!\(\s*\$menue_operator->get_parameter\(&MENUE_PARAM_APPLICATION_FLAGS\)\s*&\s*\$ANKETA_FLAG{(\w+)}\s*\)/0 == (ApplicationSummaryDao.getFlag($1) & (Integer) menuParameters.getParameter(MENU_PARAMETER_APPLICATION_FLAGS))/g;
		$is_active =~ s/scalar\(\s*\@\{\s*\$menue_operator->get_parameter\(&MENUE_PARAM_(\w+)\)\s*\}\s*\)\s*([=>]+)\s*(\d+)/((List<Object>)menuParameters.getParameter(MENU_PARAMETER_$1)).size() $2 $3/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_(\w+)\)\s*eq\s*['"](.+?)['"]/((String)menuParameters.getParameter(MENU_PARAMETER_$1)).equals("$2")/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_(\w+)\)\s*ne\s*['"](.+?)['"]/!((String)menuParameters.getParameter(MENU_PARAMETER_$1)).equals("$2")/g;
		$is_active =~ s/\$menue_operator->get_parameter\(&MENUE_PARAM_/(Boolean)menuParameters.getParameter(MENU_PARAMETER_/g;
		$is_active =~ s/MENU_PARAMETER_APPLICATION_PR_APPLICATION_ID/MENU_PARAMETER_PRECHECK_FILLED/g;
		$is_active =~ s/'/!q!/g;
		$is_active =~ s/"/'/g;
		$is_active =~ s/!q!/"/g;
		$is_active =~ s/\s+\.\s+/\n\t+ /g;
		$result .= "/*\n$is_active*/";

	}
	
	return $result;
}

sub get_header {
	my $menue_pm = shift;
	
	my $result = "";
	
	if ($menue_pm =~ /=head1 DESCRIPTION\s+(.+?)\s++=cut\s+use strict;/s){
		$result .= $1;
	}
	
	return $result;
}

sub list_module {
    my $module = shift;

    no strict 'refs';

	my $location = $module . '.pm';
	$location =~ s/::/\//g;
	require $location;

	my @subroutines = ( 'retrieve', 'delete', 'create_or_update', (grep {defined &{"$module\::$_"} && $module->can($_) &&  $_ =~/^[a-z]/ } keys %{"$module\::"}));
    return (uniq @subroutines); 
}


sub get_class_name {
	my $package = shift;

	if ($package =~ /Project::Interface_API/){
		$package =~ s/Project::Interface_API::(.+?)$/$1/g;
		$package =~ s/::/_/g;
	}

	$package =~ s/^.+::(.+?)$/$1/;
	$package =~ s/([a-zA-Z])_(\w)/$1\U$2\E/g;

	return $package;
}

sub get_method_structure {
	my $name = shift;
	my $query = shift;
	my $output_parameters = shift;

	my $metod_structure = {};

	$name =~ s/([a-z])_(\w)/$1\U$2\E/g;

	$metod_structure->{name}       = $name;
	$metod_structure->{output_parameters} = $output_parameters; 

	my $input_parameters = [];
	while($query =~ /=>\s*\s*:(\w+)/g) {
		my $input_parameter_name = $1;

		push(@{$input_parameters}, $input_parameter_name);
	}

	$metod_structure->{input_parameters}  = $input_parameters; 
	$metod_structure->{query}             = $query; 

	return $metod_structure;
}

sub set_values {
	my $template = shift;
	my $values   = shift;


	foreach my $value (keys %{$values}) {

		my $replace = $values->{$value};
#ERACE/
use Data::Dumper;
open LOG, ">>/tmp/scn.log";
print LOG "data (Constants.pm)  $value = $replace\n";
close LOG;
#ERACE\

		$template =~ s/$value/$replace/g;
	}

	return $template;
}

sub get_parameters_classes {
	my $self = shift;
	my $structure = shift;

	my $methods;
	
	my $output_parameters_array = [];
	my $interface_map = {};
	if ($structure->{interface}) {
		foreach my $method (@{$structure->{methods}}){
			if ($method->{output_parameters}->[0] eq 'ps') {
				my @exports;
				eval "\@exports = \@$structure->{package}::EXPORT;";
#ERACE/
use Data::Dumper;
open LOG, ">>/tmp/scn.log";
print LOG "data (Convert_Project_DB.pm) exports = " . Dumper(\@exports) . "\n";
close LOG;
#ERACE\
				push(@{$output_parameters_array}, (map {my $const; $_ =~ s/&//; eval "\$const = $structure->{package}::$_;";  'public static final String ' . uc($const) . ' = "' . lc($const) . '";';} @exports));
				foreach  my $db_perl_parameter (map {my $const; $_ =~ s/&//; eval "\$const = $structure->{package}::$_;"; $const} @exports) {
#ERACE/
use Data::Dumper;
open LOG, ">>/tmp/scn.log";
print LOG "data (Convert_Project_DB.pm) db_perl_parameter = " . Dumper($db_perl_parameter) . "\n";
close LOG;
#ERACE\
						my ($interface_perl_parameter) = grep {$structure->{interface}->PARAMETERS_MAP->{$_} eq $db_perl_parameter} keys %{$structure->{interface}->PARAMETERS_MAP};
						#ERACE/
						use Data::Dumper;
						open LOG, ">>/tmp/scn.log";
						print LOG "data (Convert_Project_DB.pm) $db_perl_parameter = $interface_perl_parameter\n";
						close LOG;
						#ERACE\		
						if ($db_perl_parameter && $interface_perl_parameter) {
							$interface_map->{uc($db_perl_parameter)} = $interface_perl_parameter;
						}
					
				}
				
			} else {
				push(@{$output_parameters_array}, (map {$_ =~ /^(out|get)(.+)/; my $param = $2; my $uc_param = $param; $uc_param =~ s/([a-z])([A-Z])/$1_$2/g; 'public static final String ' . uc($uc_param) . ' = "' . lc($uc_param) . '";';} @{$method->{output_parameters}}));
				foreach  my $db_parameter ((map {$_ =~ /^(out|get)(.+)/; $2} @{ $method->{output_parameters} })) {

					my $uc_param = $db_parameter;
					$uc_param =~ s/([a-z])([A-Z])/$1_$2/g;
					unless ($interface_map->{uc($uc_param)}) {
						$db_parameter = $structure->{'package'}->API_MAP->{$structure->{'package'}->API_VERSION}->{prefix} . lcfirst($db_parameter);
	
	#ERACE/
	use Data::Dumper;
	open LOG, ">>/tmp/scn.log";
	print LOG "data (Convert_Project_DB.pm) $db_parameter = " . Dumper($structure->{'package'}->FIELD_MAP) . "\n";
	close LOG;
	#ERACE\					
	
						my ($db_perl_parameter) = grep {$structure->{'package'}->FIELD_MAP->{$_}->{name} eq $db_parameter} keys %{$structure->{'package'}->FIELD_MAP};
						my ($interface_perl_parameter) = grep {$structure->{interface}->PARAMETERS_MAP->{$_} eq $db_perl_parameter} keys %{$structure->{interface}->PARAMETERS_MAP};
	#ERACE/
	use Data::Dumper;
	open LOG, ">>/tmp/scn.log";
	print LOG "data (Convert_Project_DB.pm) $db_perl_parameter = $interface_perl_parameter\n";
	close LOG;
	#ERACE\		
						if ($db_perl_parameter && $interface_perl_parameter) {
							$interface_map->{uc($uc_param)} = $interface_perl_parameter;
						}
					}
				}
			}
		}
	}

	my $output_parameters .= "\n\t\t" . join("\n\t\t", uniq @{$output_parameters_array});

	my $file_name = set_values(&TEMPLATES->{field}->{class_name}, {
		'%CLASS_NAME%' => "$structure->{class_name}",
	});

	my $files = [];

	if (open JAVA_FILE, '>' . "/var/www/html/$file_name.java"){
		print JAVA_FILE  set_values(&TEMPLATES->{field}->{class}, {
			'%CLASS_NAME%' => "$structure->{class_name}",
			'%OUTPUT_PARAMETERS%'    => $output_parameters,
		});
		close JAVA_FILE;

		push (@{$files},  "$file_name");
	}

	$output_parameters = '';
	foreach my $method (@{$structure->{methods}}){
		if ($method->{output_parameters}->[0] eq 'ps') {

			my $method_name = $method->{name};
			$method_name =~ s/^get//;
			$file_name = set_values(&TEMPLATES->{field}->{class_name}, {
				'%CLASS_NAME%' => $method_name,
			});
			
			$output_parameters .= "\n\t\t" . join("\n\t\t", map {$_ =~ /^(out|)(.+)/; my $param = $2; my $uc_param = $param; $uc_param =~ s/([a-z])([A-Z])/$1_$2/g; 'public static final String ' . uc($uc_param) . ' = "' . lc($uc_param) . '";';} ("${method_name}_id", "${method_name}_name"));
			
			if (open JAVA_FILE, '>' . "/var/www/html/$file_name.java"){
				print JAVA_FILE  set_values(&TEMPLATES->{field}->{class}, {
					'%CLASS_NAME%' => $method_name,
					'%OUTPUT_PARAMETERS%'    => $output_parameters,
				});
				close JAVA_FILE;
		
				push (@{$files},  "$file_name");
			}
			$output_parameters = '';
		}
	}
	
	if (keys %{$structure->{interface}->PARAMETERS_MAP}) {

		my $parameters_map = "";
		foreach my $interface_parameter_name (sort keys %{$structure->{interface}->PARAMETERS_MAP}) {
			my $db_parameter_name;
			foreach (keys %{$interface_map}) {
				if ($interface_parameter_name eq $interface_map->{$_}) {
					$db_parameter_name = $_;
				}
				
			}

			my $handlers_map = $self->get_handlers($interface_parameter_name, $structure->{'interface_file_path'}, {});
			
			my $handlers = "";
			foreach my $method (keys %{$handlers_map}) {
				$handlers .= qq{$handlers_map->{$method}
				} if $handlers_map->{$method};
			}

			if ($structure->{'interface_parrent_file_path'} && !$handlers) {
				$parameters_map.= qq{\t\t\tput("$interface_parameter_name", $structure->{interface_class_name}Form.super.getFieldsMap().get("$interface_parameter_name"));\n};
			} else {
				$handlers = qq{{{
					$handlers
				}}} if $handlers; 
				$parameters_map.= qq{\t\t\tput("$interface_parameter_name", new Field($db_parameter_name)$handlers);\n};
			}
		}		

		$file_name = set_values(&TEMPLATES->{form}->{class_name}, {
			'%CLASS_NAME%' => $structure->{interface_class_name},
		});

		if (open JAVA_FILE, '>' . "/var/www/html/$file_name.java"){
			print JAVA_FILE  set_values(&TEMPLATES->{form}->{class}, {
				'%CLASS_NAME%'     => $structure->{class_name},
				'%LC_CLASS_NAME%'  => lcfirst($structure->{class_name}),
				'%PARRENT_CLASS_NAME%'  => $structure->{parrent_class_name},
				'%INTERFACE_CLASS_NAME%'     => $structure->{interface_class_name},
				'%INTERFACE_PARRENT_PATH%'  => $structure->{interface_parrent_path},
				'%PARAMETERS_MAP%' => $parameters_map,
			});
			close JAVA_FILE;
		
			push (@{$files},  "$file_name");
		}
	}
	
	return {
		classes       => $files,
	};

}

sub get_interface_parrent_file_path {
	my $interface_path = shift;
	if (open INTERFACE_FILE, '<' . $interface_path){
		my $project_interface = "";
		while (my $line = <INTERFACE_FILE>){
			$project_interface .= $line;
		}
		close INTERFACE_FILE;
		$project_interface = decode('Windows-1251', $project_interface);
		
		if ($project_interface =~ /use\s+base\s+['"](Project::Interface_API::[\w:]+)['"]/) {
				my $location = $1 . '.pm';
				$location =~ s/::/\//g;
				return "/www/scn.lo/lib/$location";
		}
	}

}

sub get_handlers {
	my $self = shift;
	my $interface_parameter = shift;
	my $interface_path = shift;
	my $handlers = shift;
	my $parrent_method = shift;

#ERACE/
use Data::Dumper;
open LOG, ">>/tmp/scn.log";
print LOG "data (Convert_Project_DB.pm) = get_handlers\n";
close LOG;
#ERACE\

	if (open INTERFACE_FILE, '<' . $interface_path){

		my $project_interface = "";
		while (my $line = <INTERFACE_FILE>){
			$project_interface .= $line;
		}
		close INTERFACE_FILE;
		
		$project_interface = decode('Windows-1251', $project_interface);
		
		foreach my $method (keys %{&HANDLER_MAP}) {
			my $code = ""; 

			if ($project_interface =~ /sub\s+$method\s+\{(.+?)}\s*(sub\s+.+)?[\r\n]?\s*1;\s*/s) {
				my $method_code = $1;
				$method_code =~ s/\t/    /g;

				while ($method_code =~ /(\s*(\}\s*els)?if\s*\(\s*(\$(name|parameter).+?)\)\s*\{\s*)/sg) {
					my $compare = $3;
					my $equal = 0;
					my $name = $interface_parameter;
					my $parameter = $interface_parameter;
					my $current_code = "";

					my $name_condition = "";
					while ($compare =~ /((\$(name|parameter)\s*[=~eq]\s*.+?)(\|\||&&|$))/sg) {
						$name_condition .= $2 . " || ";
					}
					$name_condition .= "0";


					eval "\$equal = $name_condition;";
#ERACE/
use Data::Dumper;
open LOG, ">>/tmp/scn.log";
print LOG "data (Convert_Project_DB.pm) $name name_condition = " . Dumper($name_condition) . "\n";
close LOG;
#ERACE\
					if ($@){
						$self->print_html("Handlers equal (\$equal = $name_condition;) error: $@");
					}
					

					if ($equal) {

						my $chunk = substr($method_code, pos($method_code));

						my $bracket = 1;

						while ($bracket && $chunk =~ /([\{\}])/g) {
							if ($1 eq '{') {
								$bracket++;
							} else {
								$bracket--;
							}
						};
						
						$code = substr($chunk, 0, pos($chunk)-1);
						$code .= "\n#######\n condition $compare \n#######\n";

					}
				}
			}
			$handlers->{$method} .= "\n" . set_values(&HANDLER_MAP->{$method}, {
				'%PERL_CODE%' =>  $parrent_method || $code
			}) if $code;
		}
	}
	
	
	return $handlers;
}

sub join_lists{
	my $project_xml = shift;
	my $list_name = shift;
	
	my $items_hash = {};
	while($project_xml =~ s/(<\s*form_item.+?name="[^"]+"[^>]+?)${list_name}_\d+\s*=\s*"(\w+)"\s*/$1/){
		$items_hash->{$1} = [] unless $items_hash->{$1}; 
		push (@{$items_hash->{$1}}, $2);
	};
	foreach my $key (keys %{$items_hash}) {
		my $value = join("," , @{$items_hash->{$key}});
		$project_xml =~ s/\Q$key/$key $list_name="$value" /g;
	}
	
	return $project_xml;
}

sub get_xml_file {
	my $self = shift;
	my $structure = shift;
	my $filename  = shift;

	if (open XML_FILE, '<' . $structure->{xml}){
		my $project_xml = "";
		while (my $line = <XML_FILE>){
			$project_xml .= $line;
		}
		close XML_FILE;
		$project_xml = decode('Windows-1251', $project_xml);


		if (open XML_FILE, '>' . "/var/www/html/$filename.xml"){

			
			while($project_xml =~ s/(<\s*script\s+type\s*=\s*"on_.+?)current(.+?<\/script)/$1this$2/smg){}
	
			$project_xml =~ s/<\s*script.+?type\s*=\s*"on_(\w+)"\s*>/<script type="$1">/g;
	
#			$project_xml =~ s/(<form_item\s+[^>]+)\/>/$1><\/form_item>/g;
	
			$project_xml = join_lists($project_xml, "set_visible_list");
			$project_xml = join_lists($project_xml, "ajax_visible_list");
			$project_xml = join_lists($project_xml, "parrent_value");
			$project_xml = join_lists($project_xml, "ajax_parrent_list");
			$project_xml = join_lists($project_xml, "set_result");
			$project_xml = join_lists($project_xml, "set_active_list");
	
			$project_xml =~ s/set_visible_list/ajax_visible_parrent/g;
			$project_xml =~ s/ajax_visible_list/ajax_visible_parrent/g;
			$project_xml =~ s/parrent_value/ajax_value_parrent/g;
			$project_xml =~ s/set_active_list/ajax_active_parrent/g;
			$project_xml =~ s/ajax_parrent_list/ajax_value_parrent/g;
			$project_xml =~ s/set_result/ajax_value_child/g;
			$project_xml =~ s/parrent_group/parrent_api/g;
			$project_xml =~ s/name\s*=\s*(["'])/id=$1/g;
			$project_xml =~ s/header\s*=\s*(["'])/name=$1/g;
			$project_xml =~ s/windows-1251/utf-8/gi;
			$project_xml =~ s/auto_complete/auto_complete_address/g;
			$project_xml =~ s/short_editable_list/auto_complete_editable/g;
			$project_xml =~ s/short_list/auto_complete/g;
			$project_xml =~ s/short_webcamera_image/image_webcam/g;
			$project_xml =~ s/(\W)label(\W)/$1info$2/g;
			

			$project_xml =~ s/<interface /<interface service="rest\/form\/" header="header.html"/g;
	
	
	
			while($project_xml =~ s/(<\s*form_item.+?type\s*=\s*"\w+_list.+?)ajax_value_parrent(.+?<\/form_item)/$1ajax_list_parrent$2/g){}

			my $interfaces_list = {};
			while ($project_xml =~/api\s*=\s*["'](.+?)["']/g) {
				my $inteface_api = $1;
				my $short_inteface_api = $inteface_api;
				$short_inteface_api =~ s/Project::Interface_API:://;
				$short_inteface_api =~ s/::/_/g;
				
				$interfaces_list->{uc($short_inteface_api)} = $inteface_api;
			}

			foreach my $java_handler (sort {length($b) <=> length($a)} keys %{$interfaces_list}) {
				$project_xml =~ s/$interfaces_list->{$java_handler}/$java_handler/g;
			}

			#Encode::from_to($result_html, 'utf-8', 'windows-1251');
			print XML_FILE $project_xml;
			close XML_FILE;
			

			
			my $interfaces = join("<br>\n", sort keys %{$interfaces_list});
			$self->print_html($interfaces);
		}
	}

	return "$filename.xml";
}

sub get_java_class {
	my $structure = shift;
	my $template  = shift;
	my $parameters_classes = shift;

	my $methods;
	foreach my $method (@{$structure->{methods}}){
		$methods .= get_java_method($structure, $method, $template);
	}

	my $file_name = set_values(&TEMPLATES->{$template}->{class_name}, {
		'%CLASS_NAME%' => "$structure->{class_name}",
	});

	if (open JAVA_FILE, '>' . "/var/www/html/$file_name.java"){
		print JAVA_FILE  set_values(&TEMPLATES->{$template}->{class}, {
			'%PARAMETERS_CLASSES%' => ($parameters_classes ? ("import static com.technology.project.jfrontoffice.server.field." . join(".*;\nimport static com.technology.project.jfrontoffice.server.field.", @{$parameters_classes}) . ".*;\n") : ''),
			'%CLASS_NAME%' => "$structure->{class_name}",
			'%METHODS%'    => $methods,
		});
		close JAVA_FILE;

		return  "$file_name.java";
	}
}

sub get_java_method {
	my $structure = shift;
	my $method = shift;
	my $template = shift;


	my $name = $method->{name};
	my $type;
	my $result;
	my $sql = $method->{query};

	map {$sql =~ s/:$_(\W)/?$1/g;} @{$method->{input_parameters}};
	map {$sql =~ s/:$_(\W)/?$1/g;} @{$method->{output_parameters}};
	$sql =~ s/\n\s*\n/\n/g;
	$sql =~ s/(^|\n)\s*(\n|$)//g;
	$sql =~ s/(\n|$)/ "$1/g;
	$sql =~ s/^\s*+/" /;
	$sql =~ /\n(\s*+)/;
	my $tabs = $1;
	$sql =~ s/\n(\S)/\n$tabs\t$1/g;
	$sql =~ s/\n(\s*+)/\n$1 + " /g;

	my $input_parameters = join(', ',  map {$_ =~ /^(fin|upd|get|req|)(.+)/; (&TYPES_MAP->{lcfirst($2)} || 'String') . ' ' . lcfirst($2);} @{$method->{input_parameters}});

	if (scalar(@{$method->{output_parameters}}) == 1 && $method->{output_parameters}->[0] eq 'ps') {
		$type = 'List<OptionDto>';
		if ($method->{query} =~ /declare\s+form/) {
			my $index = 0;
			$result = set_values(&DAO_SINGLE_OUTPUT_PARAMETER_RESULT, {
				'%INPUT_PARAMETERS%' => join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; "\t\t\t, " . lcfirst($2);} @{$method->{input_parameters}}),
			});
		} else {
			my $method_name = $method->{name};
			$method_name =~ s/^get//;
			my $uc_param = $method_name;
			$uc_param =~ s/([a-z])([A-Z])/$1_$2/g;

			my $parameter_class_name = set_values(&TEMPLATES->{field}->{class_name}, {
				'%CLASS_NAME%' => $method_name,
			});
			if ($method_name eq 'retrieve') {
				my @exports;
				eval "\@exports = \@$structure->{package}::EXPORT;";

				$result = set_values(&DAO_LIST_PARAMETERS_RESULT, {
					'%NAME%'    => $method_name,
					'%UC_NAME%' => "$parameter_class_name." . uc($uc_param),
					'%INPUT_PARAMETERS%' => join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; "\t\t\t, " . lcfirst($2);} @{$method->{input_parameters}}),
					'%OUTPUT_PARAMETERS%' => "\n\t\t\t\t\t" . join("\n\t\t\t\t\t\t", map {"dto.put(" . uc($_) . ", rs.getString(" . uc($_) . '));';} map {my $const; $_ =~ s/&//; eval "\$const = $structure->{package}::$_;"; $const} @exports),
				});
			} else {
				$result = set_values(&DAO_LIST_RESULT, {
					'%NAME%'    => $method_name,
					'%UC_NAME%' => "$parameter_class_name." . uc($uc_param),
					'%INPUT_PARAMETERS%' => join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; "\t\t\t, " . lcfirst($2);} @{$method->{input_parameters}}),
				});
			}
		}
	} elsif (scalar(@{$method->{output_parameters}}) == 1 && $method->{output_parameters}->[0] eq 'result' ) {
		$type = 'String';
		if ($method->{query} =~ /declare\s+form/) {
			my $index = 0;
			$result = set_values(&DAO_SINGLE_OUTPUT_PARAMETER_RESULT, {
				'%INPUT_PARAMETERS%' => join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; "\t\t\t, " . lcfirst($2);} @{$method->{input_parameters}}),
			});
		} else {
			$result = set_values(&DAO_OUTPUT_SINGLE_PARAMETER_RESULT, {
				'%INPUT_PARAMETERS%' => join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; "\t\t\t, " . lcfirst($2);} @{$method->{input_parameters}}),
			});
		}

	} elsif (scalar(@{$method->{output_parameters}})) {
		my $index = 0;
		$type = 'RecordDto';
		my $parameter_class_name = set_values(&TEMPLATES->{field}->{class_name}, {
			'%CLASS_NAME%' => "$structure->{class_name}",
		});
		
		my $set_input_parameters = "";
		if ($method->{name} eq 'createOrUpdate') {
			$set_input_parameters = join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; my $param = $2; $param =~ s/([a-z])([A-Z])/$1_$2/g; "\t\t\t, daoParameters.get($parameter_class_name." . uc($param) . ")";} @{$method->{input_parameters}});
			$input_parameters = "RecordDto daoParameters";
		} else {
			$set_input_parameters = join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; "\t\t\t, " . lcfirst($2);} @{$method->{input_parameters}});
		}
		
		$result = set_values(&DAO_OUTPUT_PARAMETER_RESULT, {
			'%OUTPUT_PARAMETER_TYPES%' => "\t\t\t\t" . join(",\n\t\t\t\t", map {"String.class";} @{$method->{output_parameters}}),
			'%INPUT_PARAMETERS%' => $set_input_parameters,
			'%OUTPUT_PARAMETERS%' => "\n\t\t" . join("\n\t\t", map {$_ =~ /^(out|get)(.+)/; my $param = $2; my $uc_param = $param; $uc_param =~ s/([a-z])([A-Z])/$1_$2/g; "result.put($parameter_class_name." . uc($uc_param) . ', outputObject[' . $index++ . ']);';} @{$method->{output_parameters}}),
		});
	} elsif (scalar(@{$method->{output_parameters}}) == 0) {
		my $index = 0;
		$type = 'void';
		my $parameter_class_name = set_values(&TEMPLATES->{field}->{class_name}, {
			'%CLASS_NAME%' => "$structure->{class_name}",
		});

		my $set_input_parameters = "";
		if ($method->{name} eq 'createOrUpdate') {
			$set_input_parameters = join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; my $param = $2; $param =~ s/([a-z])([A-Z])/$1_$2/g; "\t\t\t, daoParameters.get($parameter_class_name." . uc($param) . ")";} @{$method->{input_parameters}});
			$input_parameters = "RecordDto daoParameters";
		} else {
			$set_input_parameters = join("\n", map {$_ =~ /^(fin|upd|get|req|)(.+)/; "\t\t\t, " . lcfirst($2);} @{$method->{input_parameters}});
		}

		$result = set_values(&DAO_NO_OUTPUT, {
			'%INPUT_PARAMETERS%' => $set_input_parameters,
		});
	}

	return set_values(&TEMPLATES->{$template}->{method}, {
		'%SQL%'  => $sql,
		'%TYPE%' => $type,
		'%NAME%' => $method->{name},
		'%PARAMETERS%' => $input_parameters,
		'%RESULT%' => $result,
	});
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

		if ($param_hash->{'package'}) {
			my $package = $param_hash->{'package'};
			my $queries;
			my @subroutines = list_module($package);
			my $structure = {};
			my $interface =  $param_hash->{'interface'};
			$structure->{interface_class_name} = get_class_name($interface);

			my $interface_parrent_path = $interface;
			if ($interface_parrent_path =~ s/Project::Interface_API::(.+)::(.+?)$/$1/) {
				$structure->{parrent_class_name} = $2;
				$interface_parrent_path =~ s/::/./g;
				$structure->{interface_parrent_path} = '.' . lc($interface_parrent_path);
			} else {
				$structure->{parrent_class_name} = 'Form';
			}

			my $xml       =  $param_hash->{'xml'};

			if ($xml) {
				$structure->{xml} = " /www/scn.lo/interface/$xml.xml";
			}

			$structure->{class_name} = get_class_name($package);
			$structure->{'package'} = $package;
			if ($interface) {
				my $location = $interface . '.pm';
				$location =~ s/::/\//g;
				if (require $location) { 
					$structure->{'interface'} = $interface;
					$structure->{'interface_file_path'} = "/www/scn.lo/lib/$location";
					$structure->{'interface_parrent_file_path'} = get_interface_parrent_file_path($structure->{'interface_file_path'});
					
				}
			}
			$structure->{methods} = [];

			my $query;
			$handler = sub {
				my $sql = shift;
				if ($sql !~ /CLOSE/) {
					$query = $sql;
          			$queries .= "$query\n<br>\n";
				}
  			};

			my $parameters = [];
			$inout_handler = sub {
				my $name = shift;
				$name =~ s/^://;
				push(@{$parameters}, $name);
          		$queries .= "<span style='color:red'>$name</span>\n<br>\n";
  			};

			foreach my $method (@subroutines){
				$queries .= "<b>$method</b>\n<br>\n";
				eval {
					$package->$method;
				};
				if ($@) {
					$queries .= "<b style='color:red'>$method ERROR!</b>$@\n<br>\n";
				}
				push (@{$structure->{methods}}, get_method_structure($method, $query, $parameters));

				$query = '';
				$parameters = [];

			}

			#ERACE/
			use Data::Dumper;
			open LOG, ">>/tmp/scn.log";
			print LOG "data (DB converter) structure = " . Dumper($structure) . "\n";
			close LOG;
			#ERACE\

			my $abstract_name = get_java_class($structure, 'abstract');
			my $parameters_classes_list = "";
			my $parameters_data = $self->get_parameters_classes($structure);
			
			
			foreach (@{$parameters_data->{classes}}) {
				$parameters_classes_list.= qq{
					<a href="/html/$_.java" download>$_.java</a>
					<br>
				};
			}


			my $dao_name = get_java_class($structure, 'dao', $parameters_data->{classes});

			my $menue_name = get_menue_class($param_hash->{'menue'});

			my $xml_name = $self->get_xml_file($structure, $param_hash->{'xml'});
			
			$self->print_html(qq{
						
						
				<form enctype="multipart/form-data" name="input" action="/Service" method="post">
					<a href="/html/$abstract_name" download>$abstract_name</a>
					<br>
					<a href="/html/$dao_name" download>$dao_name</a>
					<br>
					<a href="/html/$menue_name" download>$menue_name</a>
					<br>
					$parameters_classes_list
					<br>
					<a href="/html/$xml_name" download>$xml_name</a>
				</form>
			});

			$self->print_html($queries);

		} else {
                $self->print_html(qq|
                	<form name="input" action="/Service" method="post">
                	Please input Project DB_API module (ex. Project::DB_API::Application::Form::Address) <input type="text" id="package" name="package"/> 
                	<br>
                	Please input Project INTERFACE_API module (ex. Project::Interface_API::Address) <input type="text" id="interface" name="interface"/>
					<br>
                	Please input Project MENUE module (ex. Project::Application_Menue::Application_Calculate_With_Warantor) <input type="text" id="menue" name="menue"/>
					<br>
                	Please input Project interface xml filename (boost) <input type="text" id="xml" name="xml"/>
					<br>
					<input type="submit" value="Convert to Java"/>
					<input type="hidden" name="handler" value="convert_project_db"/>
					
                	</form>
                |);
			
		}

	return Apache2::Const::OK;

}
#update_file(
#	task => 'P067.T0668',
#	file_path=> '/var/Project/Modules/Module/ExternalBLCheck/Branch/P067.T0668/App/lib/Project/Check_Queue.pm',
#);

1;