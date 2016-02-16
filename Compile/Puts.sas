/* MACRO %Puts
Version: 	1.01
Author: 	Daniel Mastropietro
Created: 	30-Mar-2005
Modified: 	05-Feb-2016 (previous: 07-Oct-2005)

DESCRIPTION:
Shows a list of names separated by a given separator in the log window, one name per line.
The names are indexed and are shown aligned on the same column.

USAGE:
%Puts(list, sep=%quote( ))

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %Rep
*/
&rsubmit;
%MACRO Puts(list, sep=%quote( )) / store des="Reads a list o names and shows each name on a different line given a separator";
%local i nro_elems maxlength;
%local elem;

%let nro_elems = %GetNroElements(%quote(&list), sep=%quote(&sep));
%if &nro_elems > 0 %then %do;
	%* Maximum length of the numbers to be shown on the left hand side of the list indexing the names
	%* so that the names can be shown aligned on the same column;
	%let maxlength = %length(&nro_elems);
	%do i = 1 %to &nro_elems;
		%let elem = %scan(%quote(&list), &i, %quote(&sep));
		%put &i: %rep(,%eval(&maxlength - %length(&i)))%sysfunc(trim( %quote(%sysfunc(left( %quote(&elem) ))) ));
		%** The TRIM(LEFT()) is necessary when the separator is not blank, because there is usually
		%** a space before the name as returned by the SCAN function because of the QUOTE(&list) and
		%** because usually the lists with separators have spaces between the separator and the names;
	%end;
%end;
%else
	%put (Empty);
%MEND Puts;
