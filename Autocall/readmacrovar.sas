/* MACRO %ReadMacroVar
Version: 1.00
Author: Daniel Mastropietro
Created: 1-Oct-04
Modified: 6-Mar-05

DESCRIPTION:
This macro creates global macro variables from a dataset generated from the
sashelp.vmacro table where the macro variables created in the SAS session are stored.
The dataset contains the scope, the name and the content of each macro variable.
The macro does not work properly when there are macro variables to be read that have
too many elements, because the value of the macro variable is stored in different rows
in the sashelp.vmacro table, and SAS gets confused with this.

INPUT PARAMETERS:
data: input dataset containing the macro variable names and values to be read (default=_vmacro_).
var: list of macro variables to be read from &data. If empty, all macro variables found
in &data are read.
*/

/*
Example of %bquote vs. %nrquote:
%put %index(%nrquote(%()%nrbquote(&test),%nrquote(%)));
%put %index(%bquote(&test),%quote(%)));
%** ES FUNDAMENTAL PONER %BQUOTE(&test) en lugar de %QUOTE(&test);
%** BQUOTE masks ' " and parenthesis;
*/
%MACRO ReadMacroVar(data=, var=, log=1) / des="Reads macro variables from a VMACRO dataset";
%* The underscores are used in the local macro variables to diminish the probability of the 
%* following error occurring: AN ATTEMPT TO GLOBALIZE A MACRO VARIABLE DEFINED IN A LOCAL
%* ENVIRONMENT. This error occurs when one of the global macro variables being restored has the
%* same name as a locally defined macro variable; 
%local _data_;
%local _dsid_ _rc_;
%local _i_ _nobs_;
%local _name_num_ _offset_num_ _scope_num_ _value_num_;
%local _name_ _nameprev_ _offset_ _value_;
%local _nvars_;
%local _posParenthesis_;
%local _firstChar_ _lastChar_;

%if &log %then %do;
	%put;
	%put READMACROVAR: Macro starts;
	%put;
%end;

/*----- Parsing input parameters -----*/
%if %quote(&data) = %then
	%let _data_ = _vmacro_;
%else
	%let _data_ = &data;
/*------------------------------------*/

%let _dsid_ = %sysfunc(open(&_data_));
%if ~&_dsid_ %then
	%put CREATELISTFROMVAR: ERROR - Input dataset %upcase(&data) does not exist.;
%else %do;
	%let _nobs_ = %sysfunc(attrn(&_dsid_, nobs));
	%* Count for the number of global macro variables restored;
	%let _nvars_ = 0;
	%* Getting the variable positions;
	%let _scope_num_ = %sysfunc(varnum(&_dsid_, scope));
	%let _name_num_ = %sysfunc(varnum(&_dsid_, name));
	%let _offset_num_ = %sysfunc(varnum(&_dsid_, offset));
	%let _value_num_ = %sysfunc(varnum(&_dsid_, value));

	%* Read the values of variables &var;
	%do _i_ = 1 %to &_nobs_;
		%let _rc_ = %sysfunc(fetchobs(&_dsid_, &_i_));
		%if %upcase(%sysfunc(getvarc(&_dsid_, &_scope_num_))) = GLOBAL %then %do;
			%let _name_ = %sysfunc(getvarc(&_dsid_, &_name_num_));
			%* If VAR is not empty, check if the name of the macro variable is in the list
			%* of macro variables to be read specified in VAR=;
			%if %quote(&var) = or 
				(%quote(&var) ~= and %sysfunc(indexw(%upcase(&var), %upcase(&_name_)))) %then %do;
				%let _offset_ = %sysfunc(getvarn(&_dsid_, &_offset_num_));
				%let _value_ = %nrbquote(%sysfunc(getvarc(&_dsid_, &_value_num_)));
				%** NOTE: The use of %NRBQUOTE above is VERY IMPORTANT in order to preserve any spaces
				%** present in the current value and to mask all special characters, such as
				%** & or %. Note that I use %NRBQUOTE and NOT %NRSTR, because %NRSTR takes
				%** the string %sysfunc(getvarc(&_dsid_, &_value_num_)) as is, without
				%** resolving it.
				%** As far as preserving the spaces is concerned, the main issue coming about is when
				%** the value of a macro variable is too long (longer than 200 characters).
				%** In such case, the macro variable is cut into different observations in the
				%** dataset sashelp.vmacro, namely into groups of 200 characters each, and the
				*** position of the cut may occur either in the middle of a name or between names.
				%** Thus, a leading space or a space at the end of the current value, will be telling
				%** that the position of the cut is between names and this is an important information
				%** for the correct concatenation of the two parts of the macro variable value;
				%if &_offset_ = 0 %then %do;
					%* Remove spaces (using function %QTRIM) at the end of the value of the macro
					%* variable created at the previous step, because otherwise, spaces are added
					%* at the end of the macro variable to fill the 200 characters block.
					%* Note that I use the fuction %QTRIM and not COMPBL because I do not want
					%* multiple spaces appearing in the middle of the value to be removed.
					%* Also, I use %QTRIM instead of %sysfunc(trim) because the latter generates
					%* warnings when the value of the macro variable contains special characters
					%* such as & or %;
					%* The use of %QTRIM was indicated by SAS technical support (see e-mail by
					%* Antonio.Gomez@sas.com on 26/1/05);
					%if %quote(&_nameprev_) ~= %then
%************************* COMMENT FOR SAS SUPPORT (4-Feb-05) ***********************************;
%* In the line below, where the value of the macro variable &_nameprev_ is assigned, I have tried
%* the following two options:
%* 1.- Using the %QTRIM function, as suggested by SAS support on 26-Jan-05, as follows:
%* 		%let &_nameprev_ = %qtrim(%nrbquote(&&&_nameprev_));
%* This saves and retrieves correctly all the macro variables (even if they contain special
%* characters such as & and %), but generates the problem mentioned in my e-mail on 26-Jan-05 
%* and shown in the code test-readmacrovar.sas, where the macro %SaveMacroVar starts giving errors
%* when it is executed for the third time (even when the variables saved do not include special
%* characters such as & and %).
%* 
%* 2.- Adding the %UNQUOTE function to the above case:
%* 		%let &_nameprev_ = %unquote(%qtrim(%nrbquote(&&&_nameprev_)));
%* This solves the errors appearing at the third execution of the macro %SaveMacroVar, but generates
%* the problem that if the macro variable contains special characters such as & or %
%* the macro variable is not retrieved correctly. The following warnings are shown when the 
%* macro variable being retrieved contains the & symbol and the % symbol, respectively:
%* WARNING: Apparent symbolic reference ... not resolved,
%* WARNING: Apparent invocation of macro ... not resolved.
%* These warnings can be seen by executing the code in test-readmacrovar.sas
%*
%* ANSWER from SAS on 9/2/05: Using %QTRIM (without the %unquote) would work fine if there were
%* not a bug in the SAS 8.2 version which causes problems when the SASHELP.VMACRO dataset is
%* used inside a macro. In this case, the macro that refers to this dataset is %SaveMacroVar,
%* which sets the dataset SASHELP.VMACRO when saving the global macro variables in a dataset.
%* This bug is solved in SAS 9.3.1, so for now the solution is to make a copy of SASHELP.VMACRO
%* into a temporary dataset PRIOR to calling the macro %SaveMacroVar. In any case, since the
%* occurrence of an & and % character in the value of a macro variable is very rare, for now
%* I use the %sysfunc(trim()) function below, instead of the %qtrim function, which avoids the
%* problem described above in item 1.
%************************************************************************************************;
%*						%let &_nameprev_ = %qtrim(%nrbquote(&&&_nameprev_));
						%** The %QTRIM above was suggested by SAS support, but generates problems
						%** with the functioning of SAS (see test-readmacrovar.sas for more info).
						%** The following statement using %sysfunc(trim) does not generate these
						%** problems but if the value of the macro variable contains special
						%** characters as & or % they are not retrieved;
						%let &_nameprev_ = %sysfunc(trim(%nrbquote(&&&_nameprev_)));
					%let _nvars_ = %eval(&_nvars_ + 1);
					%global &_name_;
					%let &_name_= %nrbquote(&_value_);
					%if &log %then
						%put READMACROVAR: Restoring macro variable %upcase(&_name_);
					%* Store previous variable name so that trailing blanks are removed in the
					%* next step, after its complete value was read;
					%let _nameprev_ = &_name_;
				%end;
				%else
					%let &_name_ = %nrbquote(%unquote(&&&_name_)&_value_);
					%** The UNQUOTE above is to avoid the following error:
					%** Maximum level of nesting of macro functions exceeded; 
%*%put NAME=&_name_;
%*%put OFFSET=&_offset_;
%*%put VALUE=S&_value_.T;
%*%put;
			%end;
		%end;
	%end;

	%* Remove spaces (using function %QTRIM) at the end of the value of the macro variable just
	%* created, because otherwise, spaces are added at the end of the macro variable to fill the 200
	%* characters block. Note that I use the fuction %QTRIM and not COMPBL because I do not want
	%* multiple spaces appearing in the middle of the value to be removed.
	%* Also, I use %QTRIM instead of %sysfunc(trim) because the latter generates warnings when the
	%* value of the macro variable contains special characters such as & or %.
	%* The use of %QTRIM was indicated by SAS technical support (see e-mail by Antonio.Gomez@sas.com
	%* on 26/1/05);
	%if %quote(&_name_) ~= %then
%************************* COMMENT FOR SAS SUPPORT (4-Feb-05) ***********************************;
%* SEE COMMENT ABOVE AT THE LINE DEFINING THE VALUE OF &_nameprev_;
%************************************************************************************************;
%*		%let &_name_ = %qtrim(%nrbquote(&&&_name_));
		%** The %QTRIM above was suggested by SAS support, but generates problems
		%** with the functioning of SAS (see test-readmacrovar.sas for more info).
		%** The following statement using %sysfunc(trim) does not generate these
		%** problems but if the value of the macro variable contains special
		%** characters as & or % they are not retrieved;
		%let &_name_ = %sysfunc(trim(%nrbquote(&&&_name_)));
	
	%* Close dataset;
	%let _rc_ = %sysfunc(close(&_dsid_));
%end;

%if &log %then %do;
	%put;
	%put READMACROVAR: Number of global macro variables restored: &_nvars_;
	%put;
	%put READMACROVAR: Macro ends;
	%put;
%end;
%MEND ReadMacroVar;

