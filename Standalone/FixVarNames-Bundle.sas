/* 06-Oct-2018: Standalone bundle of macros needed to run %FixVarNames.
The following macros are defined:
%FixVarNames: the main macro doing the job of fixing a set of names so that they do not exceed a given number of characters
	and there is no collision among truncated names.
%FindInList: finds a name in a list of names given as a string and returns their position.
%SelectNames: selects names based on position from a list of names given as a string.
%GetNroElements: returns the number of elements in a list of names given as a string.

EXAMPLE:
%let varnames2fix =
this_is_a_longname_should_be_truncated_1
this_is_a_longname_should_be_truncated_2
this_is_a_longname_should_be_truncated_3
v234567890test
;
* Fix the set of names to a maximum allowed of 32 characters by leaving space for possible prefix or suffix containing 2 characters;
* This implies that the variable names are truncated to 30 characters;
%let varnames_fixed = %FixVarNames(&varnames2fix, max=32, space=2);
%put &varnames_fixed;
** Should return:
this_is_a_longname_should_be_1 this_is_a_longname_should_be_2 this_is_a_longname_should_be_t v234567890test
;
*/

/************************************ MACRO DEFINITIONS **************************************/
/* MACRO %FixVarNames
Version: 	1.01
Author: 	Daniel Mastropietro
Created: 	03-Feb-2016
Modified: 	16-Jun-2016 (previous: 28-May-2016)

DESCRIPTION:
Fix variable names by shortening their number of characters to a specified
maximum minus a specified space.

Name conflicts are resolved by replacing the name of the shortened name with
an appropriate number.

Useful to make sure that all remain SAS valid variable names after adding
a prefix or suffix of fixed length.

USAGE:
%FixVarNames(var, max=32, space=0, replace=, replacement=, log=1);

REQUIRED PARAMETERS:
- var:				List of variables to fix.

OPTIONAL PARAMETERS:
- max:				Maximum number of characters allowed for each variable
					name including the margin space defined by parameter SPACE.
					default: 32 (i.e. the maximum allowed number of chars in SAS)

- space:			Number of characters to leave as margin space for a prefix or
					suffix to be added to the variable name before exceeding
					the number of characters given in MAX.
					default: 0

- replace:			One or more consecutive characters to replace in the original
					variable name prior to fixing their name (only applied when the
					variable actually needs to be shortened).
					default: (empty)

- replacement:		One ore more characters to replace the characteres indicated in
					REPLACE=.
					default: (empty)

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes
					default: 1

RETURNED VALUES:
The list in input parameter 'var' where names have been shortened to the number
of characters given by max - space.
All variable names are trimmed on the right.

NOTES:
1.- No check is done for repeated variable names after truncation.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %FindInList
- %GetNroElements
- %SelectNames

EXAMPLES:
1.- %FixVarNames(thisisalongname v234567890test, max=10, space=2);
Returns the list 'thisisal v2345678'.

2.- %FixVarNames(A_ID_PERIODO A_TEST V_CR_SAMPLE_SUM, max=20, space=10, replace=_);
Returns the list 'AIDPERIODO A_TEST VCRSAMPLES'

APPLICATIONS:
1.- Use this macro to shorten the variable names to make sure that when adding
a prefix or a suffix to them (with e.g. %MakeList) each generated variable name
is a valid SAS variable.
*/
%MACRO FixVarNames(var, max=32, space=0, replace=, replacement=, log=1) / des="Fixes variable names by shortening their names to an allowed maximum minus a space";
%local i j;
%local maxlen;			%* Maximum length allowed for the variable name based on parameters MAX= and SPACE=;
%local lastchar;		%* Position of the last character to keep in each variable name (this is used to avoid an out-of-range error in the %substr() macro when trimming variable names);
%local nro_vars;
%local changed;			%* List of 0s and 1s indicating which variable names were changed by the process;
%local changedi;
%local vari;
%local varfix;
%local varfixi;			%* Fixed variable name after the first step;
%local newname;			%* Proposed new variable name to resolve conflicts;
%local nro_matches;		%* Number of conflicts + 1 (so, if &nro_matches = 1 there is no conflict);
%local resolved;		%* Whether the conflict was resolved;
%local list1;
%local list2;
%local nreplace;
%local number;
%local foundPositions;

%*** 1.- First fixing step, where variable names are shortened but no conflicting names are checked;
%let nro_vars = %GetNroElements(&var);
%let maxlen = %eval(&max - &space);
%let changed = ;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');

	%* Check if there would be any changes in the variable name by comparing the variable name length
	%* with the maximum allowed name length (MAXLEN): if the former is smaller or equal, then the variable name should not be changed;
	%if %length(&vari) <= &maxlen %then %do;
		%* No changes in the variable name;
		%let varfixi = &vari;
		%let changed = &changed 0;
	%end;
	%else %do;
		%* First shorten the variable by replacing the characters specified in REPLACE= if any;
		%if %quote(&replace) ~= %then
			%let vari = %sysfunc(transtrn(&vari, &replace, &replacement));
		%* FIX the variable name;
		%let lastchar = %sysfunc(min(%length(&vari), &maxlen));
		%let varfixi = %substr(&vari, 1, &lastchar);
		%let changed = &changed 1;
	%end;
	
	%* Update the list of output variable names;
	%let varfix = &varfix &varfixi;
%end;


%*** 2.- Check for conflicting names and resolve them;
%do i = 1 %to &nro_vars;
	%let changedi = %scan(&changed, &i, ' ');
	%if &changedi %then %do;
		%*** Only check if there is a conflict when the name has changed, o.w. we always keep the original name;
		%* Read both the original and first version of fixed variable names;
		%let vari = %scan(&var, &i, ' ');
		%let varfixi = %scan(&varfix, &i, ' ');

		%* Look for possible appearances of the variable name in the list;
		%let foundPositions = %FindInList(&varfix, &varfixi, log=0);
		%let nro_matches = %GetNroElements(&foundPositions);
		%if &nro_matches > 1 %then %do;
			%* If there is more than one match resolve conflicts by shortening the variable name and adding a number at the end;
			%let resolved = 0;
			%let number = 1;

			%* Loop until the problem is solved;
			%do %until(&resolved);
				%* Number of characters to replace with the number;
				%let nreplace = %length(&number);
				%let lastchar = %length(&varfixi) - &nreplace;
				%if &lastchar < 1 %then %do;
					%put FIXVARNAMES: WARNING - Cannot resolve conflict without making an invalid variable name starting with a number.;
					%put FIXVARNAMES: The variable name will NOT be changed to resolve the conflict (%upcase(&varfixi)).;
					%put FIXVARNAMES: Try increasing the number of characters allowed in the variable name (MAX=&max);
					%put FIXVARNAMES: or decrease the space to be left after name shortening (SPACE=&space).;
					%let newname = &varfixi;
					%let resolved = 1;
				%end;
				%else %do;
					%let newname = %substr(&varfixi, 1, &lastchar)&number;

					%* Check if the new name no longer exists in the list of variables to fix;
					%* If that is that case, we are done, if not increase the number to use at the end of the name by 1;
					%if %quote(%FindInList(&varfix, &newname, log=0)) = 0 %then %do;
						%let resolved = 1;
						%if &log %then
							%put FIXVARNAMES: Variable name changed to resolve conflict: %upcase(&vari) = %upcase(&newname);
					%end;
					%else
						%let number = %eval(&number + 1);
				%end;
			%end;

			%* Update the name in the list of fixed variable names;
			%let list1 = ;
			%let list2 = ;
			%if &i > 1 %then
				%let list1 = %SelectNames(&varfix, 1, &i-1);
			%if &i < &nro_vars %then
				%let list2 = %SelectNames(&varfix, &i+1, &nro_vars);
			%let varfix = &list1 &newname &list2;
		%end;
		%else %if &log %then
			%put FIXVARNAMES: Variable name changed: %upcase(&vari) = %upcase(&varfixi);
	%end;
%end;

&varfix
%MEND FixVarNames;


/* MACRO %FindInList
Version: 	1.03
Author: 	Daniel Mastropietro
Created: 	20-Oct-2004
Modified: 	31-Mar-2016 (previous: 16-Mar-2016)

DESCRIPTION:
Finds names in a list as whole words and returns their name position.
The search for the names is NOT case sensitive.

USAGE:
%FindInList(list, names, sep=%quote( ), match=ALL, sorted=0, out=, log=1);

REQUIRED PARAMETERS:
- list:			List where names are searched for. Different separators can be used.

- names:		List ot names to be searched for in 'list'. The same separator used in 'list'
				should be used here.
				The search is NOT case sensitive.

OPTIONAL PARAMETERS:
- sep:			Separator used to separate the names in 'list' and in 'names'.
				The search for 'sep' in 'list' and in 'names' in order to determine
				the names present in each list is CASE SENSITIVE.
				default: %quote( ) (i.e. the blank space)

- match:		Number of occurrences of each name in NAMES to be reported as found in LIST.
				Possible values: any integer >= 0, ALL.
				default: ALL

- sorted:		Whether the list of names in LIST is sorted in alphabetical order. This is used
				to accelerate the search process.
				Possible values: 0 => Not sorted, 1 => Sorted.
				default: 0

- out:			Output dataset where the list of 'names' found in 'list' and their name 
				positions in the list are stored.
				The output dataset has two columns:
				- NAME: Contains the name in 'names' found in 'list'.
				- POS: Contains the name position of NAME in 'list'.
				If this parameter is not empty, the value that is returned by the macro by
				default, containing the positions in list of the names found in 'list', is no
				longer returned (because of incompatibility issues regarding the creation of
				datasets and the return of values).

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

RETURNED VALUES:
If at least one name is found (and if no output dataset is requested), a list with the positions
of the first occurrence of each name in 'list' is returned.
The position is not the character position but the name position. If no name is found,
the value 0 is returned.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

SEE ALSO:
- %FindMatch
- %InsertInList
- %RemoveFromList
- %RemoveRepeated
- %SelectName
- %SelectVar

EXAMPLES:
1.- %let matches = %FindInList(name1 name2 a_xx_b c_XX_d name2, c_xx_d name2);
Stores in macro variable 'matches' the list 
4 2

2.- %let matches = %FindInList(%quote(name1,name2,a_xx_b,c_XX_d), %quote(_xx_,name), sep=%quote(,));
Stores in macro variable 'matches' the value 0.

3.- %FindInList(%quote(name1 OR name2 OR name3), %quote(name2 OR name), sep=OR, out=MATCHES);
The output dataset MATCHES is created with columns NAME and POS, with one observation with
the following value: NAME="name2", POS=2 (because NAME2 is the second name present in the list.
Note that the specification of the separator (OR) has to be in upper case because that is how
it appears in the list where the search is performed and in the list of names that are searched for.
*/
%MACRO FindInList(list, names, sep=%quote( ), match=ALL, sorted=0, out=, log=1)
		/ des="Retuns the positions of the names found in a list";
%local i;
%local count counti counts;	%* COUNT is the number of names listed in NAMES found in the list;
							%* COUNTI is the number of times each name is found in the list;
							%* COUNTS is the vector containing the number of times EACH
							%* name is found in the list;
%local pos posi;	%* POS is the vector of name positions of each name found in the list;
					%* POSI is the name position in the list of the name being analyzed;
%local name nro_names nro_namesInlist;
%local namesFound namesFoundPos;
%local length maxlength;
%local notes_option space;

%if &log %then %do;
	%put;
	%put FINDINLIST: Macro starts;
	%put;
%end;

/*----------------------------------- Parse input parameters --------------------------------*/
%*** SEP=;
%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );
%if %quote(&sep) = %quote( ) %then
	%let fast = 1;	%* Perform fast search using INDEXW;
%else
	%let fast = 0;	%* Perform slow search using the %SCAN function that sweeps over all elements in &list;

%*** MATCH=;
%if %quote(%upcase(&match)) = ALL %then
	%let match = 0;

%*** FAST=;
%if &fast %then 	%goto FAST;
%else				%goto SLOW;
/*-------------------------------------------------------------------------------------------*/

/*------------------------------------------- FAST ------------------------------------------*/
%FAST:
%local error;
%local FirstPartOfList posi_prev;

%let error = 0;
/* The following is not necessary any more, because the macro variable FAST was removed from
the parameter list. Its value is set from the value of SEP, above.
%* Check if the separator is a blank space, o.w. abort;
%if %quote(&sep) ~= %then %do;
	%let error = 1;
	%put FINDINLIST: ERROR - In FAST search mode (FAST=1), the separator must be a blank space.;
	%put FINDINLIST: Use SLOW search mode (FAST=0) instead.;
	%put FINDINLIST: WARNING - If the number of names in the list is large, the search may take;
	%put FINDINLIST: too long.;
%end;
*/

%if ~&error %then %do;
	%let nro_names = %GetNroElements(%quote(&names));
	%let pos = ;		%* List of name positions of the names found in &list;
	%let count = 0;		%* Counter for the number of &names found in list;
	%let counts = ;		%* Vector containing the number of times each name is found in the list;
	%let namesFound = ;	%* List of names found in the list;
	%let namesFoundPos =;	%* Vector of the position of the names found in NAMES;
	%do i = 1 %to &nro_names;
		%let counti = 0;
		%let posi_prev = 0;
		%let _list_ = %quote(&list);
		%let name = %scan(%quote(&names), &i, %quote( ));
		%do %until (&posi = 0 or &counti = &match);
			%let posi = %sysfunc(indexw(%quote(%upcase(&_list_)) , %quote(%upcase(&name))));
			%if &posi > 0 %then %do;
				%let counti = %eval(&counti + 1);
				%* If this is the first occurrence of NAME found in the list, increase the counter
				%* for the number of names present in NAMES found in LIST;
				%if &counti = 1 %then
					%let count = %eval(&count + 1);

				%* Store the first part of the list (coming before &name) so that the name position
				%* of &name in &list can be computed;
				%if &posi > 1 %then
					%** If it is not the first name in the list;
					%* Keep everything that is before the name to be removed from the list;
					%let FirstPartOfList = %substr(%quote(&_list_), 1, %eval(&posi-1));
				%else
					%** If it is the first name in the list;
					%let FirstPartOfList = ;

				%* Keep the list of names coming after the position where &name was found, so
				%* that the search for &name in the following loop is conducted only on the
				%* remaining part of &list;
				%if &posi < %length(&_list_) - %length(&name) %then
					%* If it is not the last element in the list;
					%let _list_ = %substr(%quote(&_list_), %eval(&posi + %length(&name) + 1));
				%else
					%** If it is the last element in the list;
					%let _list_ = ;

				%* Get the name position of &name in the list;
				%let posi = %eval(%GetNroElements(&FirstPartOfList) + &posi_prev + 1);
				%let pos = &pos &posi;
				%let posi_prev = &posi;
			%end;
		%end;
		%* Update vector with the name of times that each name is found in the list;
		%let counts = &counts &counti;
		%* Update list of names found in the list and their position in NAMES;
		%if &counti > 0 %then %do;
			%let namesFound = &namesFound &name;
			%let namesFoundPos = &namesFoundPos &i;
		%end;
		%* If more than one occurrence was requestd and the number of names in NAMES is
		%* more than one, add a semicolon to separate the list of positions for each occurrence
		%* of the names passed in NAMES in the list;
		%* Note that I use STR not QUOTE, because with QUOTE there is an error that screws everything up;
		%* Also, a space needs to be left after the semicolon, o.w. the %scan function used below
		%* to choose the elements in the list when creating the output dataset does not
		%* work properly, because the %scan function does not recognize an element as such
		%* if there are two separators stick together;
		%if &nro_names > 1 %then
			%let pos = %str(&pos; );
	%end;
	%goto FINAL;
%end;
%else
	%goto ABORTALL;
/*---------------------------------------- FAST ---------------------------------------------*/


/*---------------------------------------- SLOW ---------------------------------------------*/
%SLOW:
%local namej;
%local name_ch1 name_ch2 namej_ch1 namej_ch2;

%let nro_namesInList = %GetNroElements(%quote(&list), sep=%quote(&sep));
%let nro_names = %GetNroElements(%quote(&names), sep=%quote(&sep));
%let pos = ;		%* List of name positions of the names found in &list;
%let count = 0;		%* Counter for the number of &names found in list;
%let counts = ;		%* Vector containing the number of times each name is found in the list;
%let namesFound = ;	%* List of names found in the list;
%let namesFoundPos =;	%* Vector of the position of the names found in NAMES;
%do i = 1 %to &nro_names;
	%let counti = 0;
	%let name = %scan(%quote(&names), &i, %quote(&sep));
	%let name_ch1 = %substr(%quote(%upcase(&name)), 1, 1);
	%if %length(&name) > 1 %then
		%let name_ch2 = %substr(%quote(%upcase(&name)), 2, 1);
		%if %quote(&name_ch2) = %then
			%let name_ch2 = %quote( );	%* If the second character is a blank space explicitly set it to that, o.w. the RANK function below gives error;
	%else
		%let name_ch2 = %quote( );	%* It is neccessary to define the value of &name_ch2 as
									%* a blank space to avoid an error in the rank function below that it did not receive enough input arguments;
	%* Search for &name in &list;
	%let j = 0;
	%do %while (&j < &nro_namesInList);
		%let j = %eval(&j + 1);
		%let namej = %scan(%quote(&list), &j, %quote(&sep));
		%let namej_ch1 = %substr(%quote(%upcase(&namej)), 1, 1);
		%if %length(&namej) > 1 %then
			%let namej_ch2 = %substr(%quote(%upcase(&namej)), 2, 1);
			%if %quote(&namej_ch2) = %then
				%let namej_ch2 = %quote( );	%* If the second character is a blank space explicitly set it to that, o.w. the RANK function below gives error;
		%else
			%let namej_ch2 = %quote( );	%* It is neccessary to define the value of &name_ch2 as
										%* a blank space to avoid an error in the rank function below that it did not receive enough input arguments;

		%if &sorted and
			(%sysfunc(rank(&namej_ch1)) > %sysfunc(rank(&name_ch1)) or
			 %sysfunc(rank(&namej_ch1)) = %sysfunc(rank(&name_ch1)) and %sysfunc(rank(&namej_ch2)) > %sysfunc(rank(&name_ch2))) %then
			%let j = &nro_namesInList;
		%else %if %upcase(&namej) = %upcase(&name) %then %do;
			%let counti = %eval(&counti + 1);
			%* If this was the first occurrence of NAME found in the list, increase the counter
			%* for the number of names present in NAMES found in LIST;
			%if &counti = 1 %then
				%let count = %eval(&count + 1);
			%* Store the name position in list of i-th name in &names (&name);
			%let posi = &j;
			%* Update the list of name positions for each different name listed in &names;
			%let pos = &pos &posi;

			%* If the number of matches requested were found, set j to &nro_namesInList so
			%* that the loop stops. Note that if MATCH=ALL, then MATCH is set to 0 at the
			%* beginning of the macro, and in this case &counti is always larger than 0
			%* therefore, the loop will continue until all the occurrences of &name are found
			%* in &list;
			%if &counti = &match %then
				%let j = &nro_namesInList;
		%end;
	%end;
	%* Update vector with the number of times that each name is found in the list;
	%let counts = &counts &counti;
	%* Update list of names found in the list and their position in NAMES;
	%if &counti > 0 %then %do;
		%let namesFound = &namesFound &name;
		%let namesFoundPos = &namesFoundPos &i;
	%end;
	%* If more than one occurrence was requestd and the number of names in NAMES is
	%* more than one, add a semicolon to separate the list of positions for each occurrence
	%* of the names passed in NAMES in the list;
	%* Note that I use STR not QUOTE, because with QUOTE there is an error that screws everything up;
	%* Also, a space needs to be left after the semicolon, o.w. the %scan function used below
	%* to choose the elements in the list when creating the output dataset does not
	%* work properly, because the %scan function does not recognize an element as such
	%* if there are two separators stick together;
	%if &nro_names > 1 %then
		%let pos = %str(&pos; );
%end;
/*------------------------------------------- SLOW ------------------------------------------*/

%FINAL:
%if &log %then %do;
	%if &count = 0 %then
		%put FINDINLIST: No names were found in the list.;
	%else %do;
		%put FINDINLIST: &count out of &nro_names names were found in the list.;
		%put FINDINLIST: The list of names found, their index, and their positions in the list follows:;
		%let nro_namesFound = %GetNroElements(&namesFound);
		%do i = 1 %to &nro_namesFound;
			%if &i = 1 %then
				%let space = %quote( );
			%else
				%let space = ;
			%put %scan(&namesFoundPos, &i, ' '): %upcase(%scan(&namesFound, &i, ' ')) --at: &space%sysfunc(compbl(%quote(%scan(&pos, &i, ';'))));
		%end;
	%end;
%end;

%if %quote(&out) ~= %then %do;
	%* Determine the length to be used for variable POS in the output dataset;
	%if &nro_names > 1 %then %do;
		%let maxlength = 0;
		%do i = 1 %to &nro_names;
			%let length = %length(%scan(%quote(&names), &i, ';'));
			%if &length > &maxlength %then
				%let maxlength = &length;
		%end;
	%end;

	%* Remove the notes from the log. This is necessary to avoid messages in the log when
	%* log=0;
	%let notes_option = %sysfunc(getoption(notes));
		%** Two semicolons are used in the %let above to prevent the OPTIONS command below
		%** from not being executed when an output dataset is requested by the user and
		%** accidentally the user uses a %put statement that includes a call to %FindInList
		%** as in %put %FindInList(aa bb cc, aa, out=out). Such call will show the string
		%** OPTIONS NOTES in the log instead of executing it, because it is bounded to the
		%** %put statement used before calling %FindInList;
	options nonotes;
	data &out;
		length name $32;
		%if &nro_names > 1 %then %do;
		length pos $&maxlength;
		%end;
		%do i = 1 %to &nro_names;
			name = compbl("%scan(%quote(&names), &i, %quote(&sep))");
			%* Remove any space at the beginning;
			if substr(name,1, 1) = " " then
				name = substr(name, 2);
			%if &nro_names > 1 %then %do;
			%* Remove any space at the beginning;
			pos = compbl("%scan(&pos, &i, ';')");
			if substr(pos, 1, 1) = " " then
				pos = substr(pos, 2);
			%end;
			%else %do;
			pos = %scan(&pos, &i, ' ');
			%end;
			output;
		%end;
	run;
	options &notes_option;
	%if &log %then %do;
		%put;
		%put FINDINLIST: Output dataset %upcase(%scan(&out, 1, '(')) created with the positions of each name in the list.;
	%end;
%end;

%* If no name was found, return 0 (just one 0, even if there are many names in the list)
%* This is done so that the returned value can be used in an %if statement;
%if &count = 0 %then
	%let pos = 0;

%ABORTALL:
%if &log %then %do;
	%put;
	%put FINDINLIST: Macro ends;
	%put;
%end;

%* Only return the name positions of the names found if no output dataset has been created.
%* Note the use of the semicolon after &pos, which closes the %if;
%if %quote(&out) = %then
&pos;
%MEND FindInList;


/* MACRO %SelectNames
Version: 	1.02
Author: 	Daniel Mastropietro
Created: 	20-Oct-2004
Modified: 	12-Feb-2016 (previous: 16-Jan-2005)

DESCRIPTION:
Selects names from a list, by specifying the starting and ending position.
It can also be used to change the separator of the names in the list as the
input separator may be different form the output separator.

USAGE:
%SelectNames(list, first, last, sep=%quote( ), outsep=);

REQUIRED PARAMETERS:
- list:			Blank-separated list from where the names are selected.

- first:		Position of the first name to select in 'list'.

- last:			Position of the last name to select in 'list'.

- sep:			Separator used for the names in 'list'.
				default: %quote( ) (i.e. the blank space)

- outsep:		Separator to use for the names in the output list.
				default: same as 'sep'

RETURNED VALUES:
The list of names present in 'list' from position 'first' to position 'last'
(ends included) separated by separator 'outsep'.

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
1.- %let subset = %SelectNames(x1 x2 x3 x4 x5 z1 z2, 3, 6);
Stores the list
x3 x4 x5 z1
in macro variable 'subset'.

2.- %let subset = %SelectNames(%quote(x1,x2,x3,x4,z1), 2, 4, sep=%quote(,));
Stores the list
x2 , x3 , x4
in macro variable 'subset'.

3.- Change the separator of the list from comma to blank space
%let subset = %SelectNames(%quote(x1,x2,x3,x4,z1), 2, 4, sep=%quote(,), outsep=%quote( ));
Stores the list
x2 x3 x4
in macro variable 'subset'.
*/
%MACRO SelectNames(list, first, last, sep=%quote( ), outsep=)
	/ des="Selects names from a list from position number M to number N";
%local i newlist nro_names matchlist;

%* If SEP= is empty, redefine it as the blank space using function %quote;
%if %quote(&sep) = %then
	%let sep = %quote( );
%* If OUTSEP= is empty, set it equal to SEP;
%* Note that I need to use %length(%quote()) instead of just %quote(&outsep) = because when OUTSEP=%quote( ) (blank space)
%* the condition %quote(&outsep) = is TRUE --and we want it to be FALSE in that case!;
%if %length(%quote(&outsep)) = 0 %then
	%let outsep = &sep;

%let nro_names = %GetNroElements(%quote(&list), sep=%quote(&sep));

%if &first > &last or &first > &nro_names or &last > &nro_names %then
	%put SELECTNAMES: ERROR - The parameters passed for the first and last elements are incorrect.;
%else %do;
	%let newlist = ;
	%do i = &first %to &last;
		%if &i = &first %then
			%let newlist = %scan(%quote(&list), &i, %quote(&sep));
		%else
			%let newlist = &newlist &outsep %scan(%quote(&list), &i, %quote(&sep));
	%end;
%end;

%* Remove unnecessary blanks from the output list;
%let newlist = %sysfunc(compbl(%quote(&newlist)));

&newlist
%MEND SelectNames;


/* MACRO %GetNroElements
Version: 	2.05
Author: 	Daniel Mastropietro
Created: 	03-Mar-201
Modified: 	27-Jul-2018 (previous: 17-Jul-2018, 05-Feb-2016, 19-Sep-2003)

DESCRIPTION:
Returns the number of elements in a list separated by a given separator.

The characters in the list are masked during processing using the %NRBQUOTE() function.
The list can be empty in which case the returned value is 0.

USAGE:
%GetNroElements(list , sep=%quote( ));

REQUESTED PARAMETERS:
- list:			A list of unquoted names separated by blanks.
				(See example below)

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
%MACRO GetNroElements(list , sep=%quote( )) / des="Returns the number of names in a list";
%local i element nro_elements;
%local indsep indrest;
%local isblanksep;

%if %nrbquote(&list) = %then
	%let nro_elements = 0;
%else %do;
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
		%let element = %scan(%nrbquote(&list) , 1 , %quote(&sep));
		%let indsep = %index(%nrbquote(&list), %quote(&sep));
		%if &indsep > 1 %then
			%* Only increase the count of elements if the separator is NOT the first element in the list of names!;
			%let i = %eval(&i + 1);
		%if &indsep > 0 %then %do;	%* indsep = 0 when SEP was not found in LIST;
			%* Subset the list for the next iteration by eliminating all that is to the left of the separator found up to and including the separator;
			%let indrest = %sysfunc( min(&indsep+1, %length(%nrbquote(&list))) );	%* With the MIN function make sure that the first index of the rest of the list does not go beyond the current list length;
			%let list = %quote(%substr(%nrbquote(&list), &indrest));	%* Note the use of %QUOTE in order to keep any white spaces if they exist.
																	%* This is important when the separator is non-blank in which case white spaces
																	%* should be considered as valid element values.
																	%* Ex: %quote( | b | c | ) --> the first and last blanks are valid element values!;
		%end;
	%end;
	%*%let nro_elements = %eval(&i - 1);

	%* Check the last value of LIST to see if there is one more element to count. This is the case when either:
	%* - the separator is NON-BLANK and the list has length larger than 0 and is not equal to the separator.
	%* - the separator is BLANK and the list has length larger than 0 ***after eliminating all white spaces*** (with COMPRESS());
	%if ~&isblanksep and %length(%nrbquote(&list)) > 0 and %nrbquote(&list) ~= %quote(&sep) or
		 &isblanksep and %length(%nrbquote(%sysfunc(compress(%nrbquote(&list))))) > 0 %then
		%let nro_elements = %eval(&i + 1);
	%else
		%let nro_elements = &i;
%end;

&nro_elements
%MEND GetNroElements;
/************************************ MACRO DEFINITIONS **************************************/
