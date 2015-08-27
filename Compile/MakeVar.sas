/* MACRO %MakeVar
Version: 1.01
Author: Daniel Mastropietro
Created: 1-Mar-01
Modified: 5-Jan-04

DESCRIPTION:
This macro creates several GLOBAL macro variables with the same root name
whose values are the elements of a blank-separated list.

USAGE:
%MakeVar(valuesList , rootName , log=0);

REQUIRED PARAMETERS:
- valuesList:		List of values separated by blank spaces to be assigned
					to the macro variables.

- rootName:			Root to be used for the names of the macro variables created.

- log:				Show messages in the log?
					Possible values are: 0 => Do not show messages
										 1 => Show messages
					default: 0

NOTES:
- This macro is useful to create a set of macro variables with names of the form
'x1' 'x2', etc.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

SEE ALSO:
- %MakeList
- %MakeListFromName

EXAMPLES:
- %MakeVar(a b c , x);
generates GLOBAL macro variables 'x1' 'x2' and 'x3' with the values:
&x1 = a, &x2 = b, &x3 = c.
*/
&rsubmit;
%MACRO MakeVar(valuesList , rootName , log=0) / store des="Creates global macro variables with a given root name";
%local j nro_vars;

%let nro_vars = %GetNroElements(&valuesList);
%do j = 1 %to &nro_vars;
		%*** Note that the following variables are declared global because they are several variables and
		%*** it would be cumbersome to initialize each of them prior to calling the macro;
		%*** On the other hand, if this macro is called from another macro, it is expected that 
		%*** the macro variables will be named using the standard way that avoids overwriting user-defined
		%*** variables (i.e. with underscores at the beginning and at the end);
	%global &rootName&j;
	%let &rootName&j = %scan(&valuesList , &j , ' ');
	%if &log %then
		%put MAKEVAR: Global macro variable %upcase(&rootName&j) = &&&rootName&j, created.;
%end;
%if &log %then
	%put;
%MEND MakeVar;
