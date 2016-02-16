/* MACRO %GetNroElements
Version: 	2.03
Author: 	Daniel Mastropietro
Created: 	03-Mar-201
Modified: 	05-Feb-2016 (previous: 19-Sep-2003)

DESCRIPTION:
Returns the number of elements in a list separated by a given separator.

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

2.- The search for SEP in the list in order to determine the number of elements in the list
is CASE SENSITIVE. This was done like this because in function %SCAN (which is used in this macro)
the search for the separator passed as third parameter is CASE SENSITIVE.

3.- If the list starts or ends with a separator, no count is done before or
after the first and last separator, respectively.

4.- If the separator is non-blank, blank values are counted, even if they occur
at the beginning or at the end.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

EXAMPLES:
1.- %let nro = %GetNroElements(A B Home x y z 54);
assigns the value 7 to the macro variable &nro.

2.- %let nro = %GetNroElements(%quote(A , B , Home) , sep=%quote(,));
assigns the value 3 to the macro variable &nro.

3.- %let nro = %GetNroElements(%quote(A"B"C) , sep=%quote(%"));
assigns the value 3 to the macro variable &nro.

Examples for the notes (3) and (4):
If the list is:		Nro. of elements returns:
A , B , C	(sep=,)	3
A.B.C		(sep=.)	3
A ,, B , C	(sep=,)	3
A , , B , C	(sep=,)	4 --> because a blank space between separators is counted.
,A , B , C	(sep=,)	3 since the list begins with a separator
,A , B ,	(sep=,)	2 if the last character is ','
,A , B , 	(sep=,)	3 if the last character is ' '
  A B C		(sep= ) 3 as the first character is a separator (' ')
*/
&rsubmit;
%MACRO GetNroElements(list , sep=%quote( )) / store des="Returns the number of names in a list";
%local i element nro_elements;
%local indsep indrest;
%local isblanksep;

%let isblanksep = %length(%sysfunc(compress(%quote(&sep)))) = 0;

%let i = 0;
/*%do %until((&element =) and %eval( %length(%sysfunc(compress(%quote(&element)))) - %length(%sysfunc(compbl(%quote(&element)))) ) = 0); */
%** The above was an intent of solving the problem when there are blanks between the separators
in &sep, but it did not work;
%*%do %until(%length(%quote(&element)) = 0);
%do %until(&indsep = 0 or &indsep = &indrest);	%* indsep = indrest happens when the last character in the list is the separator;
	%** (31/1/05) I changed %quote(&element) = to %length(%quote(&element)) = 0 because
	%** in the previous version, when &element is a very large number (say 838289384929)
	%** SAS gives an OVERFLOW error!!!!;
	%let element = %scan(%quote(&list) , 1 , %quote(&sep));
	%let indsep = %index(%quote(&list), %quote(&sep));
	%if &indsep > 1 %then
		%* Only increase the count of elements if the separator is NOT the first element in the list of names!;
		%let i = %eval(&i + 1);
	%if &indsep > 0 %then %do;	%* indsep = 0 when SEP was not found in LIST;
		%* Subset the list for the next iteration by eliminating all that is to the left of the separator found up to and including the separator;
		%let indrest = %sysfunc( min(&indsep+1, %length(&list)) );	%* With the MIN function make sure that the first index of the rest of the list does not go beyond the current list length;
		%let list = %quote(%substr(%quote(&list), &indrest));	%* Note the use of %QUOTE in order to keep any white spaces if they exist.
																%* This is important when the separator is non-blank in which case white spaces
																%* should be considered as valid element values.
																%* Ex: %quote( | b | c | ) --> the first and last blanks are valid element values!;
	%end;
%end;
%*%let nro_elements = %eval(&i - 1);

%* Check the last value of LIST to see if there is one more element to count. This is the case when either:
%* - the separator is NON-BLANK and the list has length larger than 0 and is not equal to the separator.
%* - the separator is BLANK and the list has length larger than 0 ***after eliminating all white spaces*** (with COMPRESS());
%if ~&isblanksep and %length(%quote(&list)) > 0 and %quote(&list) ~= %quote(&sep) or
	 &isblanksep and %length(%sysfunc(compress(%quote(&list)))) > 0 %then
	%let nro_elements = %eval(&i + 1);
%else
	%let nro_elements = &i;

&nro_elements
%MEND GetNroElements;

