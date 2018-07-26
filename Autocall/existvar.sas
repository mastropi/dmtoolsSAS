/* %MACRO ExistVar
Version: 1.05
Author: Daniel Mastropietro
Created: 12-May-01
Modified: 28-Dec-04

DESCRIPTION:
Determines if all variables in a list exist in a dataset and optionally stores the list of
variables not found in a global macro variable.

USAGE:
%ExistVar(
	data,		*** Input dataset where the variables are searched for.
	var,		*** List of variables to search in the input dataset.
	macrovar=,	*** Name of global macro variable with list of variables not found.
	log=1);		*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Name of the dataset where the variables are searched for.
				Data option can be specified as in any data= SAS option, but THEY ARE IGNORED.

- var:			Blank-separated list of variables to search in 'data'.

OPTIONAL PARAMETERS:
- macrovar:		Name of the global macro variable where the list of the variables not found
				in the dataset is stored.
				NOTE: The name passed CANNOT be the name of any other parameter in the macro
				and it should not contain two underscores in its name.
				Also, its value CANNOT be EXIST.

- log:			Show messages in the log?
				Possible values: 0 => Do not show, 1 => Show.
				default: 1

RETURNED VALUES:
The macro returns 1 if ALL variables in 'var' exist, 0 otherwise.
Also, if either the dataset does not exist, or the list of variables passed
is empty, the macro returns 0.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

SEE ALSO:
- %Exist
- %ExistMacroVar
- %ExistOption
*/
%MACRO ExistVar(data, var, macrovar=, log=1) 
		/ des="Returns 1 if all variables in a list exist in a dataset, 0 otherwise";
/* NOTE: (27/12/04) I use two underscores in the local names because it may be common to
use a name with single underscores as the value of parameter MACROVAR= when calling this macro
from within another macro.
Except for macro variable EXIST, because there is an auxiliary macro variable called __EXIST__.
*/
%local __i__;
%local __data_name__ __dsid__ __nro_vars__ exist rc __var__;
%* Local variable used to check the existence (in turn) of each variable passed;
%local __exist__;
%local __notfound__;

%* Setting default value for returned variable (EXIST);
%* Note that the value is set to a value such that the macro returns FALSE if
%* the parameters passed are not correct.;
%let exist = 0;

%let __data_name__ = %scan(&data , 1 , '(');

%let __dsid__ = %sysfunc(open(&__data_name__));
%if ~&__dsid__ %then %do;
	%if &log %then
		%put EXISTVAR: %sysfunc(sysmsg());
%end;
%else %do;
	%let __nro_vars__ = %GetNroElements(&var);
	%if &__nro_vars__ <= 0 %then
		%put EXISTVAR: ERROR - No variables were passed.;
	%else %do;
		%let __i__ = 1;
		%let exist = 1;
		%let __notfound__ = ;
		%do %while (&__i__ <= &__nro_vars__);
			%let __var__ = %scan(&var , &__i__ , ' ');
			%if %length(&__var__) > 32 %then %do;
				%* I ask for length > 32 because the maximum allowable length of a variable name
				%* is 32 and if the varnum function is used when the name is larger than 32
				%* an error occurs (saying that the second element of the function is out of range);
				%let __exist__ = 0;
			%end;
			%else
				%let __exist__ = %sysfunc(varnum(&__dsid__ , &__var__));
				%** Returns the position of the variable in the dataset;
				%** Returns 0 if the variable does not exist;
			%if ~&__exist__ %then %do;
				%let exist = 0;		%* Setting the value of the variable that is returned by the macro;
				%let __notfound__ = &__notfound__ &__var__;
				%if &log %then
					%put EXISTVAR: Variable %upcase(&__var__) does not exist in dataset %upcase(&data).;
			%end;
			%let __i__ = %eval(&__i__ + 1);
		%end;
	%end;
	%let rc = %sysfunc(close(&__dsid__));
	
	%* Storing in a global macro variable the list of variables not found;
	%if %quote(&macrovar) ~= %then %do;
		%global &macrovar;
		%let &macrovar = &__notfound__;
	%end;
	%if &log and ~&exist %then %do;
		%put EXISTVAR: The following variables were not found in dataset %upcase(&data):;
		%put EXISTVAR: &__notfound__;
		%put;
	%end;
%end;
&exist
%MEND ExistVar;
