/* %MACRO Drop
Version: 1.01
Author: Daniel Mastropietro
Created: 9-Feb-01
Modified: 19-Jun-03

DESCRIPTION:
This macro drops variables from a data set without showing a warning or
error message in case any of the variables do not exist in the data set.

OTHER MACROS USED IN THIS MACRO:
- %ExistVar
- %GetNroElements
*/
%MACRO Drop(data , var) / des="Drops variables from a dataset";
%local i;
%local default data_name exist nro_vars _var_;

%let default = %sysfunc( getoption(dkrocond) );
%* Setting option dkrocond so that no warning message is shown in the log if the variables being
%* dropped do not exist. Note that the name of the option stands for DropKeepRenameOutputCONdition,
%* and its default value if dkrocond=warning;
options dkrocond=nowarning;

%let data_name = %scan(&data , 1 , '(');
%let nro_vars = %GetNroElements(&var);
%let exist = 0;
%do i = 1 %to &nro_vars;
	%let _var_ = %scan(&var , &i , ' ');
	%let exist = &exist or %ExistVar(&data , &_var_ , log=0);
		%** Note that I use log=0 in the call to ExistVar since the purpose of 
		%** this macro is not to show any warning or error messages when a variable
		%** being dropped actually does not exist;
%end;
%* If ANY of the vars in &var exist in &data the following data step is performed.
%* Notice that dropping an unexistent variable does not generate any warning messages because option
%* dkrocond is set to nowarning;
%if &exist %then %do;
	data &data_name;
		set &data_name;
		drop &var;
	run;
%end;
options dkrocond=&default;
%MEND Drop;

