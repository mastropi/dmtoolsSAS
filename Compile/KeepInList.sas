/* MACRO %KeepInList
Version: 1.00
Author: Daniel Mastropietro
Created: 26-Apr-05
Modified: 25-Oct-05

DESCRIPTION:
This macro keeps a list of specified names in a given source list.
By default, all occurrences of the names in the source list are kept,
but an option (allOccurrences=0) can be set to keep only the first occurrence.
The search for names in the source list is NOT case sensitive.

USAGE:
%KeepInList(namesList, names, sep=%quote( ), allOccurrences=1, log=1);

REQUESTED PARAMETERS:
- namesList:		List of names where the names to keep are searched.

- names:			List of names to be kept in 'namesList'.
					NO repeated names are allowed in this list.
	
OPTIONAL PARAMETERS:
- sep:				Separator used to separate the names in 'namesList'.
					The search for 'sep' in 'namesList' and in 'list' in order to determine
					the names present in each list is CASE SENSITIVE.
					See NOTES below for comments on particular cases.
					default: %quote( ) (i.e. the blank space)

- allOccurrences:	Specifies whether all occurrences of 'names' in 'namesList'
					should be kept, or only the first occurrence.
					Possible values: 0 => Keep only first occurence
									 1 => Keep all occurrences
					default: 1

- norepeated:		Specifies whether no repeated names are found in the list passed in NAMES.
					The only reason to pass the value NOREPEATED=0 is to avoid warning messages
					in the log stating that one of the repeated names listed in NAMES was not
					found in the list passed in NAMESLIST, when it was actually found for a
					previous occurrence of that name in NAMES.
					That is, as far as functionallity, the macro takes proper care of repeated names
					in NAMES.
					default: 1

- log:				Whether to show in the log the names kept in the list.
					Possible values: 0 => No, 1 => Yes.
					default: 1

RETURNED VALUES:
The list in 'namesList' without the names specified in 'names'.

NOTES:
1.- In the 'sep' parameter, some symbols need to be enclosed using the function
%quote when passed as parameters. This is the case for the comma, for instance.

2.- If some of the names listed in 'names' are not found in 'namesList', they
are not kept and a warning is issued. The names that are found are kept.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %FindInList
- %GetNroElements
- %Puts

SEE ALSO:
- %InsertInList
- %RemoveFromList
- %RemoveRepeated

EXAMPLES:
1.- %KeepInList(x1 x2 x3 x4 , x2 x4);
Returns the list 'x2 x4'.

2.- %KeepInList(%quote(xx,yy,zz,ww) , %quote(yy , zz) , sep=%quote(,));
Returns the list 'yy,zz'. Note that the separator ',' is also the separator used for the
list of names to be kept passed as second parameter.

3.- %KeepInList(%quote(a=0 or b=0 or c=0 OR d=0) , %quote(b=0 OR d=0) , sep=OR);
Returns the list 'b=0 or d=0'. Note that the separator 'OR' is also the separator used for
the list of names to be kept passed as second parameter.
Note the not case-sensitive feature.

4.- %KeepInList(This is A OR This is B , This is B , sep=OR);
Keeps the expression 'This is B' in the list.

5.- %KeepInList(%quote(a=0 OR b=0 OR c=0 OR b=0) , %quote(b=0) , sep=OR);
Returns the list 'b=0 or b=0'. I.e. all occurrences of 'b=0' are kept.

6.- %KeepInList(%quote(a=0 OR b=0 OR c=0 OR b=0) , %quote(b=0) , sep=OR, allOccurrences=0);
Returns the list 'b=0'. I.e. only the first occurrence of 'b=0' is kept.

APPLICATIONS:
1.- Use this macro to keep relevant variables in a list of regressor variables
used in a regression model, and fit the model again only with those relevant variables.
*/
&rsubmit;
%MACRO KeepInList(namesList, names, sep=%quote( ), allOccurrences=1, norepeated=1, log=1)
	/ store des="Returns a list of specified names kept from a list of names";
	%*** NOTE: In this macro, I use the expression %quote(%upcase(...)) when parsing
	%*** some input parameter such as &namesList. The order of these functions is important.
	%*** That is, first comes %quote and then comes %upcase.
	%*** This is because %upcase still works when there are special characters such as
	%*** comma, whereas the function where the result of the above expression is used
	%*** may not work;
%local i j k found;
%local match match_orig;
%local list name namei names_new nro_names nro_names_orig nro_namesInList;

/*----- Parse input parameters -----*/
%*** SEP=;
%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );

%*** NOREPEATED=;
%if ~&norepeated %then %do;
	%* Remove repeated names from NAMES;
	%let names = %RemoveRepeated(&names, sep=%quote(&sep), log=0);
%end;
/*----- Parse input parameters -----*/

%* Number of names present in the list of names 'namesList';
%let nro_namesInList = %GetNroElements(%quote(&namesList), sep=%quote(&sep));
%* Names and Nro. of names present in the list of names to keep (NAMES=);
%let names_orig = &names;	%* names_orig is used because &names may be updated during the 
							%* removal process in case ALLOCCURRENCES=0.
							%* The information about the original list in &names is used only
							%* for informational purposes (at the end of the macro the names
							%* listed in &names that were not found in &namesList is informed);
%let nro_names_orig = %GetNroElements(%quote(&names_orig), sep=%quote(&sep));

%* Array containing a list of 0s and 1s which indicate if each of the names listed in &names
%* was found or not found in the list (0 => Not Found, 1 => Found);
%let found = ;
%do i = 1 %to &nro_names_orig;
	%let found = &found.0;
%end;

%let nro_names = &nro_names_orig;
%** The use of nro_names and nro_names_orig is necessary because the number of names in &names
%** may change in the following loop when ALLOCCURRENCES=0. This is information is only used
%** for informational purposes at the end of the macro;
%do i = 1 %to &nro_namesInList;
	%let name = %scan(%quote(&namesList), &i, %quote(&sep));
	%*** Search for &name in &names and keep it in &list if it is found; 
	%let match = %FindInList(%quote(&names), %quote(&name), sep=%quote(&sep), log=0);
	%* Keep the first occurrence of NAME found in NAMES, because there may be repeated values
	%* in NAMES;
	%let match = %scan(&match, 1);
	%if &match > 0 %then %do;
		%* If the name was found in the list of names to keep, add it to the output list (&list);
		%if %quote(&list) = %then
			%let list = &name;
		%else
			%let list = &list &sep &name;
		%* Update array &FOUND by replacing the 0 with 1 at the position indicated by &match
		%* so that we can show at the end which names listed in &names were found in the list
		%* and which were not found;
		%* When ALLOCCURRENCES=0, first I need to search for &name in the original list of
		%* &names (&names_orig) so that the proper index in the array &found is identified.
		%* This is because the list in &names may change when ALLOCCURRENCES=0, since the
		%* name already found is kept in &names;
		%if ~&allOccurrences %then %do;
			%let match_orig = %FindInList(%quote(&names_orig), %quote(&name), sep=%quote(&sep), log=0);
			%* Keep the first occurrence of NAME found in NAMES_ORIG, because there may be repeated values
			%* in NAMES_ORIG;
			%let match_orig = %scan(&match_orig, 1);
		%end;
		%else
			%let match_orig = &match;
		%if &match_orig > 1 and &match_orig < &nro_names_orig %then
			%let found = %substr(&found, 1, %eval(&match_orig-1))1%substr(&found, %eval(&match_orig+1));
		%else %if &match_orig = 1 and &match_orig < &nro_names_orig %then
			%let found = 1%substr(&found, %eval(&match_orig+1));		%* The name found is the first one in &names_orig;
		%else %if &match_orig > 1 and &match_orig = &nro_names_orig %then
			%let found = %substr(&found, 1, %eval(&match_orig-1))1;	%* The name found is the last one in &names_orig;
		%else
			%let found = 1;	%* There is only one name in &names_orig;

		%* In case only the first occurrence found is to be removed, keep the name found
		%* in &names so that future occurences of &name in &namesList are not kept;
		%if ~&allOccurrences %then %do;
			%let names_new = ;
			%do k = 1 %to &nro_names;
				%if &k ~= &match %then %do;
					%if %quote(&names_new) = %then
						%let names_new = %scan(%quote(&names), &k, %quote(&sep));
					%else
						%let names_new = &names_new &sep %scan(%quote(&names), &k, %quote(&sep));
				%end;
			%end;
			%* Update list of names to be removed (&names) and &nro_names;
			%let names = &names_new;
			%let nro_names = %GetNroElements(%quote(&names), sep=%quote(&sep));
		%end;
	%end;
%end;

%* Remove unnecessary blanks from the output list;
%let list = %sysfunc(compbl(%quote(&list)));

%* Give information to the user;
%if &log %then %do;
	%* List of names given in &names that were not found in the list;
	%do i = 1 %to &nro_names_orig;
		%if %substr(&found, &i, 1) = 0 %then
			%put KEEPINLIST: WARNING - The name %upcase(%scan(%quote(&names_orig), &i, %quote(&sep))) was not found in the list.;
	%end;

	%* List of names kept in the list;
	%put KEEPINLIST: List of names kept in the list:;
	%* Do not use a semicolon after the PUTS because that will generate an error when
	%* returning the value at the end of the macro. This was suggested by SAS support on 9/8/05;
	%puts(%quote(&list), sep=%quote(&sep))
%end;
&list
%MEND KeepInList;
