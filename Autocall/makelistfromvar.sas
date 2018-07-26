/* MACRO %MakeListFromVar
Version: 	1.04
Author: 	Daniel Mastropietro
Created: 	20-Oct-2004
Modified: 	04-Feb-2016 (previous: 08-Oct-2012)

DESCRIPTION:
This macro returns a macro variable containing the values of a variable in a dataset.
If no variable is specified, the list is generated from the first column in the dataset.

USAGE:
%MakeListFomVar(
	data,			*** Dataset containing the variable values to store in the macro variable.
	var=,			*** Name of the variable whose values are stored in the macro variable.
	sep=%quote( ),	*** Separator to use in the list of values stored in the macro variable.
	strip=1,		*** Use the strip function to eliminate leading and trailing blanks from values?
	log=1);			*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. NO data options are allowed.

OPTIONAL PARAMETERS:
- var:			The variable of interest (ONLY ONE VARIABLE is allowed).
				If no variable is passed, the values are read from the first column in the
				dataset.

- sep:			Separator used to create the list returned by the macro.
				default: blank space

- strip:		Use the strip function to eliminate leading and trailing blanks from variable values?
				Possible values: 0 => No, 1 => Yes
				default: 1

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

RETURNED VALUES:
A list with the values of a variable in a dataset.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Puts

EXAMPLES:
1.- %let values = %MakeListFromVar(test, var=x);
Stores in macro variable 'values' the values of variable X in dataset TEST.

2.- %let valuesBlanksAllowed = %quote(%MakeListFromVar(test, var=x, sep=|));
Stores in macro variable 'valuesBlanksAllowed' the values of variable X in dataset TEST
where values for different records are separated with '|'.
Note the use of macro %quote() enclosing the %MakeListFromVar call so that a blank
value at the first or last record will be preserved as a blank value.
*/
%MACRO MakeListFromVar(data, var=, sep=%quote( ), strip=1, log=1)
		/ des="Returns a list of names with the values of a variable in a dataset";
/*
NOTA: (23/11/04) Even though data options generally do not cause an error in the OPEN function,
no data options are accepted in the DATA parameter because one possible or common data option
would be a WHERE= option (to limit which values of the variable of interest to be read). However,
this option makes the returned value of the OPEN function be 0 (i.e. the dataset cannot be
opened).
*/
%local dsid rc;
%local i nobs;
%local fun varnum vartype;
%local cols concatenate firstobs lastobs;
%local value;	%* DM-2012/09/24: Macro variable VALUE added to store the current value read from the dataset variable (to avoid repeating the same calling function in several places);
%local firstvalue lastvalue;	%* DM-2016/02/05: First and last values in the list to check if they are blanks (which should be considered a valid value, especially when the separator is non-blank; 
%local list;

%* If SEP= is blank, redefine it as the blank space using function %quote;
%if %quote(&sep) = %then
	%let sep = %quote( );

%* Initialize the list to return (I do it here, before opening the input dataset, so that an
%* empty list is returned if an error occurs);
%let list = ;

%let dsid = %sysfunc(open(&data));
%if ~&dsid %then
	%put MAKELISTFROMVAR: ERROR - Input dataset %upcase(&data) does not exist.;
%else %do;
	%let nobs = %sysfunc(attrn(&dsid, nobs));
	%if %quote(&var) ~= %then %do;
		%let varnum = %sysfunc(varnum(&dsid, &var));
		%if &varnum = 0 %then
			%put MAKELISTFROMVAR: ERROR - Variable %upcase(&var) does not exist in dataset %upcase(&data).;
	%end;
	%else
		%let varnum = 1;
	%if &varnum > 0 %then %do;
		%let vartype = %sysfunc(vartype(&dsid, &varnum));
		%if %upcase(&vartype) = N %then
			%let fun = getvarn;
		%else
			%let fun = getvarc;

		%* Read the values of variable &var;
		%do i = 1 %to &nobs;
			%let rc = %sysfunc(fetchobs(&dsid, &i));
			%let value = %sysfunc(&fun(&dsid, &varnum));
			%if &i = 1 %then %do;
				%let firstvalue = &value;
				%if &strip and %quote(&value) ~= %then
					%* Note that the strip() function does not accept a blank as input parameter;
					%let list = %sysfunc(strip( &value ));
				%else
					%let list = &value;
			%end;
			%else %do;
				%*** DM-2012/06/06: Removed the COMPBL function because it may alter the original values of character variables (e.g. when the values contain inner blank spaces);
				/*   DM-2012/09/24: RE-ESTABLISHED the use of the COMPBL function to remove repetitive blanks because its absence caused problems when the list is very long (~ more than 20 or 30 names!);
									In fact, by using the MLOGIC option I saw that, regardless of the use of COMPBL, the names in the list are sometimes preceded or followed
									by very strange characters (e.g. A_CUSTOMER V_FIELD_SURFACE) and this seems to cause a closing parentehesis appear at the end
									of the names which make the error "Maximum level of nesting of macro functions exceeded." appear
				*/
				%let list = %sysfunc(compbl( %quote(&list &sep &value) ));
					%** NOTE: Function COMPBL is used to avoid leaving more spaces than necessary
					%** between the names and/or between the separator and the names;
				%if &strip and %quote(&value) ~= %then
			   		%* Note that the strip() function does not accept a blank as input parameter;
					%let list = %sysfunc(strip( &list ));
				/* DM-2012/09/24: The statements below are replaced with the above IF &STRIP statement because
					it generated errors when the list of variables is too long as explained above.
					Note that this was only fixed on 10-Oct-2012.
				%if &strip %then
			   		%let list = %quote(&list&sep%sysfunc(strip( &value )));
				%else
			   		%let list = %quote(&list&sep&value);
				*/
			%end;
		%end;
	%end;
	%* Close dataset;
	%let rc = %sysfunc(close(&dsid));
%end;

%* (DM-2016/02/05) Check if the first and last values are empty, in which case we add a blank space at the beginning or end 
%* of the returned list. This happens only for character variables when there is no value in the record, as missing numeric
%* values would return dot (.);
%* Reason: We still want empty records to contribute to the output list. In fact, if we are using %MakeListFromVar to read
%* records from different variables in a dataset, we would like to have the same number of values read for each variable;
%let lastvalue = &value;
%if %quote(&firstvalue) = %then
	%* Add a blank space at the end to indicate that the last value was blank;
	%let list = %quote( &list);
%if %quote(&lastvalue) = %then
	%* Add a blank space at the end to indicate that the last value was blank;
	%let list = %quote(&list );

%if &log %then %do;
	%put List of names returned:;
	%puts(%quote(&list), sep=%quote(&sep))
%end;

&list
%MEND MakeListFromVar;
