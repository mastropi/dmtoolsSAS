/* MACRO %SelectName
Version: 1.01
Author: Daniel Mastropietro
Created: 20-Oct-04
Modified: 16-Jan-05

DESCRIPTION:
Selects names from a list, by specifying the starting and ending position.

USAGE:
%SelectName(list, first, last, sep=%quote( ));

REQUIRED PARAMETERS:
- list:			Blank-separated list from where the names are selected.

- first:		Position of the first name to select in 'list'.

- last:			Position of the last name to select in 'list'.

- sep:			Separator used to separate the names in the list.
				default: %quote( ) (i.e. the blank space)

RETURNED VALUES:
The list of names present in 'list' from position 'first' to position 'last' (inclusive).

NOTES:
The search for the separator SEP in the list of names is CASE SENSITIVE.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

SEE ALSO:
- %FindInList
- %FindMatch
- %InsertInList
- %RemoveFromList
- %RemoveRepeated
- %SelectVar

EXAMPLES:
1.- %let subset = %SelectName(x1 x2 x3 x4 x5 z1 z2, 3, 6);
Stores the list
x3 x4 x5 z1
in macro variable 'subset'.

2.- %let subset = %SelectName(%quote(x1,x2,x3,x4,z1), 2, 4, sep=%quote(,));
Stores the list
x2,x3,x4
in macro variable 'subset'.
*/
&rsubmit;
%MACRO SelectName(list, first, last, sep=%quote( ))
	/ store des="Selects names from a list from position number M to number N";
%local i newlist nro_names matchlist;

%* If SEP= is blank, redefine it as the blank space using function %quote;
%if %quote(&sep) = %then
	%let sep = %quote( );

%let nro_names = %GetNroElements(%quote(&list), sep=%quote(&sep));

%if &first > &last or &first > &nro_names or &last > &nro_names %then
	%put SELECTNAME: ERROR - The parameters passed for the first and last elements are incorrect.;
%else %do;
	%let newlist = ;
	%do i = &first %to &last;
		%if &i = &first %then
			%let newlist = %scan(%quote(&list), &i, %quote(&sep));
		%else
			%let newlist = &newlist &sep %scan(%quote(&list), &i, %quote(&sep));
	%end;
%end;

%* Remove unnecessary blanks from the output list;
%let newlist = %sysfunc(compbl(%quote(&newlist)));

&newlist
%MEND SelectName;
