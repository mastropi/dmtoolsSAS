/* MACRO %PrintRequiredParameterMissing
Version: 1.00
Author: Daniel Mastropietro
Created: 19-Sep-03
Modified: 19-Sep-03

DESCRIPTION:
Prints in the log that not all the required parameters by a macro call
were passed.
The macro name where the messsage is generated is also shown if required.

USAGE:
%PrintRequiredParameterMissing(paramNames , macro=);

REQUIRED PARAMETERS:
- paramNames:	List of the required parameter names by the macro where the error
				occurred.

OPTIONAL PARAMETERS:
- macro:		Name of the macro from where the message is generated.

SEE ALSO:
- %PrintDataDoesNotExist
- %PrintVarDoesNotExist
*/
&rsubmit;
%MACRO PrintRequiredParameterMissing(paramNames , macro=) 
		/ store des="Shows a message in the log regarding the parameters required in a macro call";
%local paramList;

%if %quote(&macro) ~= %then
	%let macro = %quote(%upcase(&macro:) );

%if %index(%quote(&paramNames) , %quote(,)) > 0 %then
	%* if the names in &paramNames are separated by comma;
	%let paramList = &paramNames;
%else
	%* if the names in &paramNames are separated by blanks;
	%let paramList = %MakeList(%quote(%upcase(&paramNames)) , sep=%quote(,));
%put &macro.ERROR - Not all required parameters (&paramList) were passed.;
%MEND PrintRequiredParameterMissing;
