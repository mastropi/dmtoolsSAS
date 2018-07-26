/* MACRO %RemoveRepeated
Version: 1.00
Author: Daniel Mastropietro
Created: 16-Sep-03
Modified: 16-Jan-05

DESCRIPTION:
This macro removes repeated names from a list of names.
It is intended to be used in a SAS macro language context.

USAGE:
%RemoveRepeated(namesList , sep=%quote( ), log=1);

REQUIRED PARAMETERS:
- namesList:	List of names separated by any character.
				For some characters used as separators, the list
				should be enclosed in the %str or %quote function.
				IMPORTANT: If the separator is not a blank space, there
				should be at least a blank space between the separator
				and the names. Also, in such cases any blank space
				within a name plays the role of separator as well.
				See examples 2 and 3 below.
	
OPTIONAL PARAMETERS:
- sep:			Separator used to separate the names in 'namesList'.
				The search for 'sep' in 'namesList' in order to determine
				the names present in each list is CASE SENSITIVE.
				default: blank space

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

RETURNED VALUES:
The list in 'namesList' without the repeated names.

NOTES:
1.- The search for 'names' in 'namesList' and the separator indicated in 'sep' is
NOT case sensitive.

2.- In the 'sep' parameter, some symbols need to be enclosed using the function
%quote when passed as parameters. This is the case for the comma, for instance.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %RemoveFromList

SEE ALSO:
- %InserInList
- %RemoveFromList

EXAMPLES:
1.- %RemoveRepeated(x1 x2 X2 x4);
Returns 'x1 x2 x4'. Note the non-case sensitive feature.

2.- %RemoveRepeated(%quote(XX,yy,xx,ww) , sep=%quote(,));
Returns 'XX , yy , ww'.
Note the not case-sensitive feature.

3.- %RemoveRepeated(This is B OR This is B , sep=OR);
Returns the list 'This is B'.

APPLICATIONS:
1.- Apply it to a list of variables to be used as regressors in a regression procedure
such as PROC REG. If repeated names are not removed from the list, the regression procedure
aborts.
*/
%MACRO RemoveRepeated(namesList , sep=%quote( ), log=1)
	/ des="Removes repeated names from a list";
%local j list name newlist nro_names nro_names_orig;

/*-------------------------------- Parsing input parameters ---------------------------------*/
%* If SEP= is blank, redefine it as the blank space using function %quote;
%if %quote(&sep) = %then
	%let sep = %quote( );

%* Number of names in &namesList;
%let nro_names_orig = %GetNroElements(%quote(&namesList) , sep=%quote(&sep));
%* Assign the list passed to a local variable named list;
%let list = &namesList;
%* New list to be returned without the repeated names;
%let newlist = ;
/*-------------------------------------------------------------------------------------------*/

%* Check if the separator is in &list. If not, the original list is returned;
%let j = 0;		%* Counter for the number of names left in the output list;
%if %sysfunc(index(%quote(&list), %quote(&sep))) %then %do;
	%let nro_names = &nro_names_orig;
	%do %while (&nro_names > 0);
		%let j = %eval(&j + 1);
		%let name = %scan(%quote(&list), 1, %quote(&sep));
			%** Note that the element scanned is always number 1 (not number &j). This is because
			%** &list is updated in this loop, so that the next element to scan is always the
			%** first element;
		%* Removes all occurrences of &name in &list;
		%let list = %RemoveFromList(%quote(&list), %quote(&name), sep=%quote(&sep), allOccurrences=1, log=0);
		%* Add name to the new list with no repeated names (&newlist);
		%if &j = 1 %then
			%let newlist = &name;
		%else
			%let newlist = &newlist &sep &name;
			%** Function %quote is necessary when sep is the blank space;
		%* Updating the number of names remaining in &list;
		%let nro_names = %GetNroElements(%quote(&list), sep=%quote(&sep));
	%end;
%end;
%else
	%let newlist = &namesList; %* If the separator was not found, the macro returns the input list;

%* Remove unnecessary blanks from the output list;
%let newlist = %sysfunc(compbl(%quote(&newlist)));

%* Give information to the user;
%if &log %then %do;
	%put REMOVEREPEATED: Number of names originally present in the list: &nro_names_orig;
	%put REMOVEREPEATED: Number of names removed: %eval(&nro_names_orig - &j);
	%put REMOVEREPEATED: Number of names left: &j;
%end;
&newlist
%MEND RemoveRepeated;
