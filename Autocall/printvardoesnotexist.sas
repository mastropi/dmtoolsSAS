/* MACRO %PrintVarDoesNotExist
Version: 1.00
Author: Daniel Mastropietro
Created: 19-Sep-03
Modified: 22-Sep-03

DESCRIPTION:
Prints in the log that not all the variables in a list exist in a dataset.
If desired, the name of the macro where the messsage is generated is also shown.

USAGE:
%PrintVarDoesNotExist(data , var , macro=);

REQUESTED PARAMETERS:
- data:			Name of the dataset where the variables are not present.

- var:			List of variables not found.

OPTIONAL PARAMETERS:
- macro:		Name of the macro from where the message is generated.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %MakeList

SEE ALSO:
- %PrintDataDoesNotExist
- %PrintRequestedParameterMissing
*/
%MACRO PrintVarDoesNotExist(data , var , macro=) / des="Shows a message in the log regarding existence of variables in a dataset";
%if %quote(&macro) ~= %then
	%let macro = %quote(%upcase(&macro:) );
%if %quote(&data) ~= and %quote(&var) ~= %then %do;
	%if %GetNroElements(%quote(&var)) > 1 %then %do;
		%put &macro.ERROR - Not all variables in;
		%put &macro.(%MakeList(%upcase(&var) , sep=%quote(,)));
		%put &macro.were found in dataset %upcase(&data).;
	%end;
	%else
		%put &macro.ERROR - Variable %upcase(&var) was not found in dataset %upcase(&data).;
%end;
%else
	%put &macro.ERROR - No dataset or variables were passed.;
%MEND PrintVarDoesNotExist;
