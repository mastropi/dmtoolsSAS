/* MACRO %RemovePrefix
Version: 1.01
Author: Daniel Mastropietro
Created: 4-Jul-05
Modified: 19-Aug-06

DESCRIPTION:
A set of prefixes is removed from each name present in a list.

USAGE:
%RemovePrefix(names, prefix, sep=%quote( ), list=1, log=0);

REQUIRED PARAMETERS:
- names:			List of names where the prefixes are searched.

- prefix:			Blank-separated list of prefixes to be removed from each name in the list.
					The search for the presence of the prefixes is NOT case sensitive.

OPTIONAL PARAMETERS:
- sep:				Separator used between the names of the list.
					See NOTES below for comments on particular cases.
					default: %quote( ), i.e. a blank space

- list:				States whether the list of names passed in NAMES is really a list of names
					or is actually a string.
					This affects how the new list is displayed in the log after the suffixes
					were removed.
					Possible values are: 0 => The value of NAME should be treated as a string
										 1 => The value of NAME snould be treated as a list
					default: 1

- log:				Show messages in the log?
					Possible values are: 0 => Do not show messages
										 1 => Show messages
					default: 0

RETURNED VALUES:
The list passed in LIST where, if present, the prefix passed in PREFIX is removed
from each name.

NOTES:
1.- Some symbols need to be enclosed with the function %quote when passed
as parameters. This is the case for the blank space, the comma, the quotation
mark. In addition, the quotation mark is a special case, which needs to be treated
differently. Namely, the percentage sign should be used before the quotation
mark symbol, as in: %quote(%"). If '%' is not used, SAS will interpret '"' as the
beginning of a string, not as a symbol.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %Puts

SEE ALSO:
- %MakeList
- %MakeListFromName
- %RemoveSuffix

EXAMPLES:
1.- %let list = %RemovePrefix(I_x1 i_x2 xI_ xi_y, I_);
generates the macro variable 'list' with the value:
'x1 x2 xI_ xi_y'

2.- %let list = %RemovePrefix(%quote(I_x1,i_x2,xI_,xi_y), I_, sep=%quote(,));
generates the macro variable 'list' with the value:
'x1 , x2 , xI_ , xi_y'

3.- %let sentence = %RemovePrefix(;This is a text ;this is a second text ;etc., ;, list=0);
generates the macro variable 'sentence' with the value:
'This is a text this is a second text etc.'
Note the use of option LIST=0. This is just to have the macro display the result as a sentence
and not as a list of names.
*/
&rsubmit;
%MACRO RemovePrefix(names, prefix, sep=%quote( ), list=1, log=1)
	/ store des="Removes a given prefix from each name in a list";
%local i j name newname newlist nro_names nro_prefixes prefixj;

%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );

%let nro_names = %GetNroElements(&names, sep=%quote(&sep));
%let nro_prefixes = %GetNroElements(&prefix);
%let newlist = ;
%do j = 1 %to &nro_prefixes;
	%let prefixj = %scan(%quote(&prefix), &j, ' '); 
	%do i = 1 %to &nro_names;
		%let name = %scan(%quote(&names), &i , %quote(&sep));
		%let pos = %index(%upcase(&name), %upcase(&prefixj));
		%if &pos = 1 %then %do;
			%if %length(&prefixj) = %length(&name) %then %do;
				%* This means that the prefix found is the whole name.
				%* Therefore the new name without the prefix is empty;
				%* This is necessary to avoid an error in the %substr function used within
				%* the %else where the second parameter would larger than the length of &name;
				%let newname = ;
			%end;
			%else %do;
				%* This means that the prefix found is only part of the name;
				%let newname = %substr(%quote(&name), %eval(%length(&prefixj)+1));
			%end;
		%end;
		%else
			%let newname = &name;

		%* Create the new list of names (after the removal of suffixj);
		%if &i = 1 %then
			%let newlist = &newname;
		%else
			%let newlist = &newlist &sep &newname;
	%end;
	%let names = &newlist;
%end;

/* Commented out on 18/08/06 because I do not see the case of removing blanks when &name is a phrase.
%* Remove unnecessary blanks from the output list;
%if %quote(&newlist) ~= %then
	%let newlist = %sysfunc(compbl(&newlist));
*/
%if &log %then %do;
	%if &list %then %do;
		%put REMOVESUFFIX: The following list is returned:;
		%* Do not use a semicolon after the PUTS because that will generate an error when
		%* returning the value at the end of the macro. This was suggested by SAS support on 9/8/05;
		%puts(%quote(&newlist))
	%end;
	%else %do;
		%put REMOVESUFFIX: The following string is returned:;
		%put &newlist;
	%end;
%end;
&newlist
%MEND RemovePrefix;
