/* MACRO %Puts
Version: 1.00
Author: Daniel Mastropietro
Created: 30-Mar-05
Modified: 7-Oct-05

DESCRIPTION:
Shows a blank-separated list of names in the log window, one name per line.
The names are indexed and are shown aligned on the same column.

USAGE:
%Puts(list)

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %Rep
*/
&rsubmit;
%MACRO Puts(list, sep=%quote( )) / store des="PUTs one name per line";
%local i nro_vars maxlength;
%let nro_vars = %GetNroElements(%quote(&list), sep=%quote(&sep));
%if &nro_vars > 0 %then %do;
	%* Maximum length of the numbers to be shown on the left hand side of the list indexing the names
	%* so that the names can be shown aligned on the same column;
	%let maxlength = %length(&nro_vars);
	%do i = 1 %to &nro_vars;
		%put &i: %rep(,%eval(&maxlength - %length(&i)))%sysfunc(trim(%sysfunc(left(%scan(%quote(&list), &i, %quote(&sep))))));
		%** The TRIM(LEFT()) is necessary when the separator is not blank, because there is usually
		%** a space before the name as returned by the SCAN function because of the QUOTE(&list) and
		%** because usually the lists with separators have spaces between the separator and the names;
	%end;
%end;
%else
	%put (Empty);
%MEND Puts;
