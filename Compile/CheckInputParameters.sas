/* MACRO %CheckInputParameters
Version: 	1.05
Author: 	Daniel Mastropietro
Created: 	22-Sep-03
Modified: 	24-Jul-2018 (previous: 17-Aug-2006)

DESCRIPTION:
Checks if a set of parameters passed to a macro is correct.
The following verifications are performed:
- whether all required parameters were passed to the macro.
- whether the datasets passed to the macro exist.
- whether the variables passed to the macro exist in the datasets.

USAGE:
%CheckInputParameters(
	data= ,
	var= ,
	otherRequired= ,
	requiredParamNames= ,
	dataRequired=1 ,
	varRequired=0 ,
	check= ,
	singleData=1 ,
	macro=);

REQUIRED PARAMETERS:
None.
If no parameters are passed, the macro returns 0 (FALSE), and displays the error
message that no datasets were passed.

OPTIONAL PARAMETERS:
- data:					Blank-separated list of dataset names passed to the macro call.
						************************* NOTE ********************************
						If only one dataset is in the list, there may be data options,
						but if more than one dataset is passed, there may NOT be any
						data options in any of the listed dataset.
						When there is more than one dataset passed, set parameter
						singleData=0 (see below).
						In any case, any data options passed when a single dataset is
						listed in DATA= are IGNORED.
						***************************************************************
						ALSO: If there are data options they should NOT contain the PIPE (|)
						operator, because this parameter is almost always required when
						running a macro, and the macro %CheckRequiredParameters that is
						called to check the required parameters receives the parameter
						values to check separated by a pipe (NOT by a comma, to avoid
						problems with expressions such as 'WHERE A IN (1, 2)'.

- var:					Content of the var= parameter as appears in the macro call.
						The following valid SAS specification of variables is allowed:
						- blank separated list
						- hyphen strings (as in x1-x3)
						- double hyphen strings (as in id--name)
						- colon expressions (as in id:)
						- reserved keyword: _ALL_, _CHAR_, _NUMERIC_ (in this case, no check is performed)
						Note that in the case of double hyphen strings and colon expressions
						their definition also defines the existence or non-existence of
						the variables in the dataset since the parsing of this strings
						requires the search of the variables in the dataset.

- otherRequired:		Content of other required parameters. The content
						of different required parameters should be separated by a PIPE (|)
						with NO SPACE between the pipe and the parameter values.
						The pipe is used to distinguish what values correspond to which
						parameter. See examples below.

- requiredParamNames:	Blank-separated list of the required parameter names.
						The number of elements in this list is counted to determine the
						number of required parameters by the macro call.
						Their names need not match the names of the original parameters
						received by the macro call, even though it is advisable to do
						so because their names are shown in the log when a parameter
						was not passed to the macro call.

- dataRequired:			Indicates whether parameter data= is a required or optional
						parameter.
						Possible values: 0 => Optional parameter
										 1 => Required parameter
						default: 1

- varRequired:			Indicates whether parameter var= is a required or optional
						parameter.
						Possible values: 0 => Optional parameter
										 1 => Required parameter
						default: 0

- check:				List of parameter names whose values passed are considered as
						variable names whose existence needs to be checked in all datasets
						in addition to the variables listed in parameter 'var'.
						The variables contained in the parameter names can be specified
						the same way as parameter VAR= can be specified (see above).
						(This means that hyphen strings, colons, etc. are allowed
						in BY=, CLASS=, and other macro parameters.)

- singleData:			Indicates whether in parameter 'data' only one dataset is
						passed, or multiple datasets are passed.
						This is to avoid problems when options are passed together with
						the dataset names and spaces are left between the dataset names
						and data options (if this is the case, the options would
						be regarded as dataset names, and in addition if there are spaces
						within the expressions in the options, an error is reported when
						equal signs or similar characters are encountered).
						So, use singleData=0 ONLY when the list of datasets passed in
						'data' is a list of dataset names with NO data options included.
						Possible values: 0 => multiple datasets; 1 => single dataset.
						default: 1

- macro:				Name of the macro whose call is analyzed. This is to show its
						name in the log when error messages are displayed.

NOTES:
1.- The required parameters MUST be specified in the parameter 'requiredParamNames'. This
is a blank-separated list of parameter names, whose number is counted in order to determine
the number of required parameters. This number is compared to the number of parameters
passed to the macro call, which are specified in parameters data=, var= and otherRequired=.
If this check is passed, the existence of the datasets listed in data= is checked.
If the datasets in data= exist, the variables listed in var= are checked for their existence
in the datasets listed in data=.
See examples below.

2.- Before checking for the existence of the variables listed in var= in the datasets listed
in data=, any keywords such as _ALL_, _NUMERIC_ and _CHAR_ are removed from the list.

3.- The parameter 'varRequired' is needed because sometimes it is necessary to check both
whether the parameter var= was passed to the macro call and whether the variables listed
in var= exist in the datasets passed, and sometimes it is only necessary to perform the
latter check.
In order to distinguish between these two cases, it is necessary to include the parameter
varRequired.
Note that whenever the parameter data= is not empty, the variables listed in var=
are checked for their existence in all datasets listed in data=.

4.- If the variables listed in the parameter var= passed to the macro call need NOT be
verified for their existence in the datasets in data=, simply leave the parameter
var= empty in the call to %CheckInputParameters, and set varRequired=0.
Note however that it is NOT possible to avoid checking the existence of the variables
listed in var= if at the same time a check of whether the parameter var= was passed to the
macro call is carried out (i.e. if varRequired=1).

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckRequiredParameters
- %ExistData
- %ExistVar
- %GetNroElements
- %GetVarList
- %PrintDataDoesNotExist
- %PrintRequiredParameterMissing
- %PrintVarDoesNotExist

EXAMPLES:
1.- Suppose that in the macro %Test(data , var= , stat= , name=) parameters data and var=
are required parameters. Then, at the beginning of %Test, use the following call to
%CheckInputParameters:
%if %CheckInputParameters(	data=&data , var=&var , varRequired=1 , 
							requiredParamNames=data var= , macro=TEST)
%then %do;
<Macro-code>
%end;

If an error is found in the macro call, a message of the following type is shown in the log:
'TEST: ERROR - Not all required parameters (DATA , VAR=) were passed.'
where the macro name (TEST) is displayed at the beginning of the message.

2.- Suppose that in the above macro %Test, both stat= and name= are required parameters, but
var= is not a required parameter.
At the beginning of %Test, use the following call to %CheckInputParameters:
%if %CheckInputParameters(data=&data , otherRequired=%quote(&stat|&name) ,
						  requiredParamNames=data stat= name= , macro=test)
%then %do;
<Macro-code>
%end;

Note that in this case, the variables passed to the macro call in the var= parameter are
not checked for their existence in the datasets listed in data=, because they are not
passed in the var= parameter of %CheckInputParameters.

3.- Suppose that in the above macro %Test, only the dataset is required.
At the beginning of %Test, use the following call to %CheckInputParameters:
%if %CheckInputParameters(data=&data , var=&var , macro=test)
%then %do;
<Macro-code>
%end;

4.- Suppose the macro %Test receives the additional parameter BY=, containing a list of by
variables. Therefore, the existence of the by variables needs to be checked for existence
in the input dataset. To check this, use parameter CHECK= when calling %CheckInputParameters
as follows:
%if %CheckInputParameters(data=&data , var=&var, otherRequired=%quote(&stat|&name) ,
						  requiredParamNames=data stat= name= , check=by, macro=test)
%then %do;
<Macro-code>
%end;
*/
&rsubmit;
%MACRO CheckInputParameters(data= , var= , otherRequired= , requiredParamNames= , 
							dataRequired=1 , varRequired=0 , check=, singleData=1 , macro=)
	/ store des="Checks if a set of input parameters passed to a macro is correct";
/*********************************************************************************************
=====================
VERY IMPORTANT NOTE!!
=====================
WHEN CALLING ANOTHER MACRO FROM WITHIN THIS MACRO, AND THAT MACRO ENDS WITH A SEMICOLON (;)
(for example %PrintRequiredParameterMissing), DO NOT END THE CALL TO THE MACRO WITH A
SEMICOLON!!!! 
(i.e. call the macro by using the statement '%PrintRequiredParameterMissing' instead of
'%PrintRequiredParameterMissing;'
(the difference is that in the second call there is a semicolon at the end).
For some reason, the semicolon is carried over to the end of this macro and then
returned to the outside world, together with the returned macro variable (&ok),
and it creates problems in an %if, %put, etc statement from where this macro was called.
/*********************************************************************************************/
%local _data_ i j _check_ nro_check nro_datas nro_paramNames nro_vars requiredParamValues tocheck _var_;
%local ok;

%let ok = 1;

%*** Checks required parameters;
%* Pipe (|) separated list of required parameter values that must be checked as for
%* whether they were passed or not to the macro.
%* Note that we use the pipe and not comma for instance, because
%* the &data value may contain commas as in WHERE A IN (1, 3), and this generates
%* problems with the %GetNroElements macro;
%* On the contrary, the pipe should not occur, as long as the OR operator is used as OR
%* and NOT as |... so the user should NOT use the | operator in options of the input dataset;
%let requiredParamValues = &otherRequired;
%* if data= is a required parameter by the macro;
%if &dataRequired %then
	%let requiredParamValues = &requiredParamValues.|&data;
%* if var= is a required parameter by the macro;
%if &varRequired %then
	%let requiredParamValues = &requiredParamValues.|&var;
%* Number of required parameters;
%let nro_paramNames = %GetNroElements(%quote(&requiredParamNames));
%* Checks if required parameters were passed;
%if &nro_paramNames > 0 %then %do;
	%if ~%CheckRequiredParameters(%quote(&requiredParamValues) , &nro_paramNames, sep=|) %then %do;
		%PrintRequiredParameterMissing(%quote(&requiredParamNames) , macro=&macro)
		%let ok = 0;
	%end;
%end;
%else %do;
	%if &dataRequired and %quote(&data) = %then %do;
		%PrintRequiredParameterMissing(%quote(DATA) , macro=&macro)
		%let ok = 0;
	%end;
	%if &varRequired and %quote(&var) = %then %do;
		%PrintRequiredParameterMissing(%quote(VAR=) , macro=&macro)
		%let ok = 0;
	%end;
%end;

%* Checks existence of datasets and existence of variables in those datasets;
%if &ok %then %do;
	%if &singleData %then %do;
		%* Remove any data options from the DATA parameter;
		%let _data_ = %scan(&data , 1 , '(');
		%let nro_datas = %GetNroElements(&_data_);
	%end;
	%else
		%let nro_datas = %GetNroElements(%quote(%sysfunc(compress("&data" , '()="'))));
		%** Above is important the use of %QUOTE() instead of %STR(), otherwise, the 
		%** something is not parsed before calling %GetNroElements, and this macro
		%** will think that more positional parameters are passed than defined;
		%** Also note the use of the double quotes in the second parameter of
		%** compress(), so that the quotes that are used to enclose &data are removed;
		%** Note that &data must be enclosed in double quotes instead of single quotes
		%** because the &data needs to be evaluated before the evaluation of compress();
	%do i = 1 %to &nro_datas;
		%if ~&singleData %then
			%** The above --%if ~&singleData-- in principle should not be necessary.
			%** However, if it is not present and there are data options in the dataset passed
			%** in &data, and there is only one dataset in &data (i.e. singleData = 1),
			%** and that dataset does not exist, SAS shows an error (in red) stating that the
			%** the dataset does not exist instead of showing the error message generated
			%** by this macro stating that the dataset does not exist;
			%let _data_ = %scan(&data , &i , ' ');
		%* Checks existence of each dataset;
		%if ~%index(%str("&_data_") , %str(%()) %then %do;
				%** Here I check whether in &_data_ there is a parenthesis, an
				%** equal sign, a >, and other strange symbol that may come with
				%** an option to the dataset and that is not a valid part of a dataset name.
				%** Note that this can only return FALSE when there is more than one dataset
				%** listed in parameter DATA, as when only one dataset is listed, the options
				%** were already removed above.
				%** Note the following:
				%** - The use of double quotes to enclose &_data_ in the first %STR() function.
				%**   This is to avoid the interpretation of an open parenthesis as such when
				%**   there is one in &_data_ (as in test(where=(x > y))).
				%** - The use of %STR() instead of %QUOTE() in the first argument of the 
				%**   %index function. This is to have the double quotes *really* enclose
				%**   the value of &_data_ and not be interpreted as any particular
				%**   character in &_data_;
			%** The above means that &_data_ is really a dataset name and not
			%** the set of options that come with a dataset name;
			%if ~%ExistData(&_data_) %then %do;
				%PrintDataDoesNotExist(&_data_ , macro=&macro)
				%let ok = 0;
			%end;
			%else %do;
				%* Checks existence of variables listed in VAR= in each dataset;
				%* Note that the check is done only if &var is not a reserved word
				%* as _ALL_, _NUMERIC_ or _CHAR_.
				%* Note that if &var is _ALL_, _NUMERIC_ or _CHAR_, there will be no problem using
				%* the variables by a data step or SAS procedure because they will always be found,
				%* (even though there could be no numeric or no character variables in a dataset,
				%* which will generate an error, but this is inevitable);
				%if %index(%quote(%upcase(&var)) , _ALL_) %then
					%let var = %RemoveFromList(&var , _ALL_, log=0);
				%if %index(%quote(%upcase(&var)) , _NUMERIC_) %then
					%let var = %RemoveFromList(&var , _NUMERIC_, log=0);
				%if %index(%quote(%upcase(&var)) , _CHAR_) %then
					%let var = %RemoveFromList(&var , _CHAR_, log=0);
				%if %quote(&var) ~= %then %do;
					%* Parse list of variables;
					%let var = %GetVarList(&_data_, var=&var, check=0, log=0);

					%* Check existence of each variable separately, so that the user knows which
					%* variables are missing;
					%let nro_vars = %GetNroElements(&var);
					%if &nro_vars = 0 %then %do;
						%put %upcase(&macro): No variables in %upcase(&_data_) were found in the list passed in VAR=.;
						%let ok = 0;
					%end;
					%else
						%do j = 1 %to &nro_vars;
							%let _var_ = %scan(&var , &j , ' ');
							%if ~%ExistVar(&_data_ , &_var_, log=0) %then %do;
								%PrintVarDoesNotExist(&_data_ , &_var_ , macro=&macro)
								%let ok = 0;
							%end;
						%end;
				%end;

				%* Checks existence of other variables passed, as requested by parameter CHECK=.
				%* It is assumed that parameter CHECK= does not have reserved words as _ALL_,
				%* _NUMERIC_ or _CHAR_, and no hyphens are used;
				%if %quote(&check) ~= %then %do;
					%* List of variables to be checked for existence in all datasets;
					%* First read the list of parameters (like BY=, ID=, etc.) whose values
					%* correspond to variables whose existence needs to be checked;
					%let tocheck = ;
					%do j = 1 %to %GetNroElements(%quote(&check));
						%let _check_ = %scan(&check, &j, ' ');
						%* Add the content of the current parameter to the list of variables
						%* to check;
						%let tocheck = &tocheck &&&_check_;
					%end;
					%if %length(&tocheck) > 0 %then %do;	%* If there are any variables to check;
						%* Parse list of variables in &tocheck;
						%let tocheck = %GetVarList(&_data_, var=&tocheck, check=0, log=0);
						%let nro_check = %GetNroElements(&tocheck);
						%if &nro_check = 0 %then %do;
							%put %upcase(&macro): No variables in %upcase(&_data_) were found in the variable lists passed in parameters %upcase(&check).;
							%let ok = 0;
						%end;
						%else
							%do j = 1 %to &nro_check;
								%let _var_ = %scan(&tocheck , &j , ' ');
								%if ~%ExistVar(&_data_ , &_var_, log=0) %then %do;
									%PrintVarDoesNotExist(&_data_ , &_var_ , macro=&macro)
									%let ok = 0;
								%end;
							%end;
					%end;
				%end;
			%end;
		%end;
	%end;
%end;
&ok
%MEND CheckInputParameters;
