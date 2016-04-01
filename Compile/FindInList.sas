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
&rsubmit;
%MACRO FindInList(list, names, sep=%quote( ), match=ALL, sorted=0, out=, log=1)
		/ store des="Retuns the positions of the names found in a list";
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
