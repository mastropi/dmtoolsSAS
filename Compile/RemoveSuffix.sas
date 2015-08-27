/* MACRO %RemoveSuffix
Version: 1.01
Author: Daniel Mastropietro
Created: 13-Jul-05
Modified: 19-Aug-06

DESCRIPTION:
A set of suffixes is removed from each name present in a list.

USAGE:
%RemovePrefis(names, suffix, sep=%quote( ), list=1, log=0);

REQUIRED PARAMETERS:
- names:			List of names where the suffixes are searched.

- suffix:			Blank-separated list of suffixes to be removed from each name in the list.
					The search for the presence of the suffixes is NOT case sensitive.

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
The list passed in LIST where, if present, the suffix passed in SUFFIX is removed
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
- %ReplaceChar

SEE ALSO:
- %MakeList
- %MakeListFromName
- %RemovePrefix

EXAMPLES:
1.- %let list = %RemoveSuffix(x1_L x2_l x_L1 y_l2, _L);
generates the macro variable 'list' with the value:
'x1 x2 x_L1 y_l2'

2.- %let list = %RemoveSuffix(%quote(x1_L,x2_l,x_L1,y_l2), _L, sep=%quote(,));
generates the macro variable 'list' with the value:
'x1 , x2 , x_L1 , y_l2'

3.- %let sentence = %RemoveSuffix(This is a text; this is a second text; etc., ;, list=0);
generates the macro variable 'sentence' with the value:
'This is a text this is a second text etc.'
Note the use of option LIST=0. This is just to have the macro display the result as a sentence
and not as a list of names.
*/
&rsubmit;
%MACRO RemoveSuffix(names, suffix, sep=%quote( ), list=1, log=1)
	/ store des="Removes a given suffix from each name in a list";
%local i j name newname newlist nro_names nro_suffixes searchname suffixj;
%local replacement;

%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );

%let nro_names = %GetNroElements(&names, sep=%quote(&sep));
%let nro_suffixes = %GetNroElements(&suffix);
%let newlist = ;
%do j = 1 %to &nro_suffixes;
	%let suffixj = %scan(%quote(&suffix), &j, ' '); 
	%* Definition of the replacement character used in the call to %ReplaceChar to keep searching 
	%* for SUFFIX all over the names passed in names;
	%if %upcase(&suffixj) ~= ? %then
		%let replacement = ?;
	%else
		%let replacement = !;
	%do i = 1 %to &nro_names;
		%let name = %scan(%quote(&names), &i , %quote(&sep));
		%* Search for a match with &suffixj at the end of &name;
		%let searchname = &name;	%* Create the name to search on, which is updated at each iteration;
		%* The following DO LOOP iterates until the string &suffixj is not found or until it is
		%* found at the end of &searchname (which is what we want since we want to remove the string
		%* &suffixj only when it is a suffix, not when it is found in the middle of the name!);
		%do %until (&pos = 0 or &pos = %eval(%length(&searchname) - %length(&suffixj) + 1));
			%let pos = %index(%upcase(&searchname), %upcase(&suffixj));
			%* Update searchname substituting the replacement character at the position where
			%* suffixj was found;
			%if &pos > 0 %then
				%let searchname = %ReplaceChar(%quote(&searchname), &pos, %quote(&replacement));
				%** NOTE: (19/08/06) A %QUOTE was added to enclose parameters &searchname and &replacement
				%** in case their values have a comma;
		%end;
		%** NOTE: (19/08/06) The line %let newname = &name was added and the following %if was changed from
		%** &if &pos > 0 to %if &pos > 1, because when &pos = 1, the 3rd argument of %substr will be 0
		%** which is not valid;
		%if &pos = 0 %then %do;
			%* This means that &suffixj was not found in &name;
			%let newname = &name;
		%end;
		%else %if &pos = 1 %then %do;
			%* This means that the string &suffixj was found in &name at position 1 and since it is a suffix
			%* it means that the &newname must be empty;
			%* This happens for example when we are removing suffix AA from name AA;
			%let newname = ;
		%end;
		%else %do;
			%* This means that the string &suffixj was found at the end of &name at a position greater than 1;
			%let newname = %substr(%quote(&name), 1, %eval(&pos-1));
		%end;

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
%MEND RemoveSuffix;
