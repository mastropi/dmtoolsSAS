/* %MACRO InsertInList
Version: 1.00
Author: Daniel Mastropietro
Created: 4-Aug-04
Modified: 4-Aug-04

DESCRIPTION:
Inserts a name in a blank-separated list of names, either before or after
a given keyword.
The keyword can be a list of names and it is always searched for its full
appearance (function INDEXW is used from SAS language).
The search for the keyword is NOT case sensitive.
If one of the names to be inserted is already present in the list, its
position is changed as requested.

USAGE:
%InsertInList(list, name, pos, key);

REQUIRED PARAMETERS:
- list:			Blank-separated list where a name wants to be inserted.

- name:			List of names to be inserted.

- pos:			The relative position (after/before) where 'name' should be
				inserted with respect to 'key'.

- key:			Keyword to be searched for in 'list' that determines the position
				where 'name' is inserted.
				It is usually a single name, but a list of names is also accepted.
				In this case, the list of keywords is searched for as a whole,
				as opposed to searching each name in the list.
				The search is NOT case sensitive.

RETURNED VALUES:
The original list with the name 'name' inserted before/after (according to 'pos')
the name 'key'.

NOTES:
If more than one occurrence of the keyword 'key' exist in 'list', the insertion point
is taken to be that of the first occurrence.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

SEE ALSO:
- %GetNroElements
- %GetVarNames
- %RemoveFromList
- %MakeListFromName

EXAMPLES:
1.- %InsertInList(pp qq rr, ss, after, qq);
Returns the list 'pp qq ss rr'.

2.- %InsertInList(pp qq rr, ss, before, pp);
Returns the list 'ss pp qq rr'.

3.- %InsertInList(pp qq rr, ss, before, NonExistentName);
Returns the list unchanged, since the name 'NonExistentName' is not in the list.

4.- %InsertInList(pp qq rr, ss, before, s);
Returns the list unchanged, since the name 's' is not in the list.

5.- Change the position of a name in the list:
%InsertInList(pp qq rr, rr, before, qq);
Returns the list 'pp rr qq'.

6.- Insert multiple names:
%InsertInList(pp qq rr, ss tt, after, qq);
Returns the list 'pp qq ss tt rr'.

7.- Keyword as a list of names:
%InsertInList(pp qq rr, ss tt, after, qq rr);
Returns the list 'pp qq rr ss tt'.

8.- Problematic insertions:
%InsertInList(pp qq rr, rr, before, RR);
Returns the list unchanged, since rr is both in the list of names to be inserted
and in the keyword.

%InsertInList(pp qq rr, ss, before, qq r);
Returns the list unchanged, since the key 'qq r' is not in the list.

APPLICATIONS:
This macro is useful to make it easier to specify the order of a new variable
created in a dataset with a FORMAT statement, without having to list all the
variables coming before the new variable.
Ex:
%let var = %GetVarNames(A); 			* Reads the variable names present in A;
%let format = %InsertInList(&var, newvar, after, somevar);
data A;
	format &format;
	set A;
run;
*/
&rsubmit;
%MACRO InsertInList(list, name, pos, key) / store des="Inserts a name in a list at a given position";
%local i _list_ _name_ nro_names;
%local head tail;

%* Remove any names listed in NAME that already exist in LIST;
%let _list_ = &list;		%* Create temporary variable so that the original list is not
							%* altered in case the macro does not add any name.
							%* This is important to avoid problems when a name listed in
							%* NAME is also present in KEY and exists in LIST as well,
							%* because in such case that name is removed from LIST
							%* but then is not added back because KEY is no longer found
							%* and the macro stops;

%let nro_names = %GetNroElements(&name);
%do i = 1 %to &nro_names;
	%let _name_ = %scan(&name, &i, ' ');
	%if %sysfunc(indexw(%quote(%upcase(&_list_)), %upcase(&_name_))) > 0 %then
		%let _list_ = %RemoveFromList(&_list_, &_name_, log=0);
%end;

%* Position of keyword &key in &_list_;
%let indexKey = %sysfunc(indexw(%quote(%upcase(&_list_)), %upcase(&key)));
	%** Note the use of INDEXW and not INDEX, because I only want matches of WORDS,
	%** not of parts of words. This avoids for example matching x in the list: y x_1 x_2;
	%** Note also that if KEY is a blank-separated list of names, the whole list
	%** is searched for in LIST, as opposed to each name separately;

%if &indexKey = 0 %then %do;
	%put INSERT: ERROR - Either the keyword %upcase(&key) is not present in the list;
	%put INSERT: or one of the names to be inserted is also in the keyword.;
	%put INSERT: Name(s) %upcase(&name) will not be inserted.;
%end;

%else %do;
	%* Define the head and tail of the modified list;
	%if %upcase(&pos) = BEFORE %then %do;
		%if &indexKey > 1 %then %do;
			%let head = %substr(%quote(&_list_), 1, &indexKey-1);
			%let tail =	%substr(%quote(&_list_), &indexKey-1);
		%end;
		%else %do;
			%let head = ;
			%let tail = &_list_;
		%end;
	%end;
	%else %do;
		%if %eval(&indexKey + %length(&key)) < %length(&_list_) %then %do;
			%let head = %substr(&_list_, 1, &indexKey + %length(&key));
			%let tail = %substr(&_list_, &indexKey + %length(&key));
		%end;
		%else %do;
			%let head = &_list_;
			%let tail = ;
		%end;
	%end;

	%* Create the new list;
	%let _list_ = %sysfunc(compbl(&head%quote( )&name%quote( )&tail));
	%* Update the list input to the macro with the new list;
	%let list = &_list_;
%end;
&list
%MEND InsertInList;
