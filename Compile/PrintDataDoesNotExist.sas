/* MACRO %PrintDataDoesNotExist
Version: 1.00
Author: Daniel Mastropietro
Created: 19-Sep-03
Modified: 19-Sep-03

DESCRIPTION:
Prints in the log that a dataset does not exist, together with the
name of the macro where the messsage is generated (if desired).

USAGE:
%PrintDataDoesNotExist(data , macro=);

REQUESTED PARAMETERS:
- data:			Name of the dataset that was not found.

OPTIONAL PARAMETERS:
- macro:		Name of the macro from where the message is generated.

SEE ALSO:
- %PrintVarDoesNotExist
- %PrintRequestedParameterMissing
*/
&rsubmit;
%MACRO PrintDataDoesNotExist(data , macro=) 
	/ store des="Shows a message in the log regarding the existence of a dataset";
%if %quote(&macro) ~= %then
	%let macro = %quote(%upcase(&macro:) );
%if %quote(&data) ~= %then
	%put &macro.ERROR - Dataset %upcase(&data) does not exist.;
%else
	%put &macro.ERROR - No dataset was passed.;
%MEND PrintDataDoesNotExist;
