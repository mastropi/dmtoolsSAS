/* MACRO %ExistMacroVar
Version: 1.00
Author: Daniel Mastropietro
Created: 12-Feb-03
Modified: 12-Jan-05

DESCRIPTION:
Checks if a macro variable with a given scope (default = global) exists.

USAGE:
%ExistMacroVar(macrovar , scope=global);

REQUIRED PARAMETERS:
- macrovar:			Macro variable whose existence wants to be checked.

OPTIONAL PARAMETERS:
- scope:			Scope where the macro variable is searched (global, local, etc.).

RETURNED VALUES:
Returns 1 if the macro variable 'macrovar' exists in scope 'scope', 0 otherwise.

SEE ALSO:
- %Exist
- %ExistData
- %ExistOption
- %ExistVar
*/
%MACRO ExistMacroVar(macrovar , scope=global)
		/ des="Returns 1 if a macro variable exists, 0 otherwise";
%local i dsid num_name num_scope rc;
%local exist obs val_name val_scope;

%let dsid = %sysfunc( open(sashelp.vmacro) );
%let num_name = %sysfunc( varnum(&dsid,name) );
%let num_scope = %sysfunc( varnum(&dsid,scope) );
%let exist = 0;
%let i = 0;
%do %until (&obs = -1);
	%let i = %eval(&i + 1);
	%let obs = %sysfunc( fetchobs(&dsid,&i) );	%* Note: when EOF is reached, fetchobs returns -1;
	%let val_name = %sysfunc( getvarc(&dsid,&num_name) );
	%let val_scope = %sysfunc( getvarc(&dsid,&num_scope) );
	%if %quote(&val_name) = %upcase(&macrovar) and %upcase(&val_scope) = %upcase(&scope) %then %do;
		%** The %quote above is used to prevent problems when the name of &val_name is 
		%** a keyword such as NOT, AND, etc.;
		%let obs = -1;
		%let exist = 1;
	%end;
%end;
%let rc = %sysfunc(close(&dsid));
&exist
%MEND ExistMacroVar;
