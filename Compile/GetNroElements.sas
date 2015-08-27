/* MACRO %GetNroElements
Version: 2.02
Author: Daniel Mastropietro
Created: 3-Mar-01
Modified: 19-Sep-03

DESCRIPTION:
Returns the number of blank-separated elements in a list.

USAGE:
%GetNroElements(list , sep=%quote( ));

REQUESTED PARAMETERS:
- list:			A list of unquoted names separated by blanks.
				(See example below.)

OPTIONAL PARAMETERS:
- sep:			Separator symbol that defines the different elements 
				in &list. Some symbols need to be enclosed with the
				function %quote. See NOTES below.
				default: %quote( ), i.e. a blank space

RETURNED VALUES:
The number of elements in 'list'.

NOTES:
1.- Some symbols need to be enclosed within the function %quote when passed
as parameters. This is the case for the blank space, the comma, the
quotation mark. In addition, the quotation mark is a special case, which
needs to be treated differently. Namely, the percentage sign should be used
before the quotation mark symbol, as in: %quote(%"). If '%' is not used, SAS
will interpret '"' as the beginning of a string, not as a symbol.

2.- It is assumed that there is always at least a character between the
separators. For example, valid entries for 'list' are:
A , B , C	(sep=,)	(Returned nro of elements = 3)
A.B.C		(sep=.)	(Returned nro of elements = 3)
A ,, B , C	(sep=,)	(Returned nro of elements = 3)
but the following entry is NOT valid:
A , , B , C (sep=,)
because this will return the value 1, instead of 4.

3.- The search for SEP in the list in order to determine the number of elements in the list
is CASE SENSITIVE. This was done like this because in function %SCAN (which is used in this macro)
the search for the separator passed as third parameter is CASE SENSITIVE.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

EXAMPLES:
1.- %let nro = %GetNroElements(A B Home x y z 54);
assigns the value 7 to the macro variable &nro.

2.- %let nro = %GetNroElements(%quote(A , B , Home) , sep=%quote(,));
assigns the value 3 to the macro variable &nro.

3.- %let nro = %GetNroElements(%quote(A"B"C) , sep=%quote(%"));
assigns the value 3 to the macro variable &nro.
*/
&rsubmit;
%MACRO GetNroElements(list , sep=%quote( )) / store des="Returns the number of names in a list";
%local i element nro_elements;

%let i = 0;
/*%do %until((&element =) and %eval( %length(%sysfunc(compress(%quote(&element)))) - %length(%sysfunc(compbl(%quote(&element)))) ) = 0); */
%** The above was an intent of solving the problem when there are blanks between the separators
in &sep, but it did not work;
%do %until(%length(%quote(&element)) = 0);
	%** (31/1/05) I changed %quote(&element) = to %length(%quote(&element)) = 0 because
	%** in the previous version, when &element is a very large number (say 838289384929)
	%** SAS gives an OVERFLOW error!!!!;
	%let i = %eval(&i + 1);
	%let element = %scan(%quote(&list) , &i , %quote(&sep));
%end;
%let nro_elements = %eval(&i - 1);
&nro_elements
%MEND GetNroElements;

