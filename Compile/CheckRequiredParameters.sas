/* MACRO %CheckRequiredParameters
Version: 1.00
Author: Daniel Mastropietro
Created: 19-Sep-03
Modified: 19-Sep-03

DESCRIPTION:
This macro is used to check if all the parameters required by a macro
are not empty.

USAGE:
%CheckRequiredParameters(params , nroRequired , sep=%quote(,));

REQUIRED PARAMETERS:
- params:			List of the values taken by the parameters passed to the
					macro call being analyzed. They should NOT be separated 
					by blank spaces, because it is assumed that the parameter
					values are the ones separated by blank spaces.
					If this is not the case, change the value of 'sep' passed
					if necessary (e.g. if the set of values of a single parameter
					is separated by commas, do not use sep=%quote(,) when
					calling this macro.

- nroRequired:		Number of required parameters by the macro call being analyzed.

OPTIONAL PARAMETERS:
- sep:				Separator between the parameter values passed in 'params'.
					This can be anything EXCEPT the blank space.
					default: , (comma)

RETURNED VALUES:
The macro returns 1 if the number of parameter values passed in 'params' is the
same as the number specified in 'nroRequired'.

NOTES:
- Though apparently not necessary, it is advisable that there be no space between
the separator and the parameter values. This is to avoid potential problems
with number returned by the macro %GetNroElements that is called by this macro.
(See examples below).

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

EXAMPLES:
1.- %CheckRequiredParameters(%quote(test,y x1 x2) , 2);
returns 1 (TRUE).

2.- %CheckRequiredParameters(%quote(test,,y x1 x2) , 3);
returns 0 (FALSE).

APPLICATIONS:
1.- Call this macro to check if all required parameters by a macro call were passed,
and thus abort the execution of that macro if that is not the case.
*/
&rsubmit;
%MACRO CheckRequiredParameters(params , nroRequired , sep=%quote(,))
		/ store des="Checks if the required parameters were passed to a macro call";
%local nro_params ok;

%let nro_params = %GetNroElements(%quote(&params) , sep=%quote(&sep));
%if &nro_params ~= &nroRequired %then
	%let ok = 0;
%else
	%let ok = 1;
&ok
%MEND CheckRequiredParameters;
