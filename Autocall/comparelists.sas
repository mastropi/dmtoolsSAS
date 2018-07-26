/* MACRO %CompareLists
Version: 1.00
Author: Daniel Mastropietro
Created: 9-Nov-04
Modified: 21-Jan-05

DESCRIPTION:
This macro compares 2 list of names (LIST1 and LIST2), and gives as result:
- The names present in both lists.
- The names in list1 NOT present in list2.
- The names in list2 NOT present in list1.

By default, these names are stored in three different global macro variables and in three
different datasets called (both macro variables and datasets):
_INTERSECTION_, _LIST1NOTLIST2_, _LIST2NOTLIST1_.

Before the comparison is performed, any repeated names are removed from the lists.
The comparison is NOT case sensitive.

USAGE:
%CompareLists(
	list1,			*** First list of names.
	list2,			*** Second list of names.
	sep=%quote( )	*** Separator used to separate the names in the lists.
	norepeated=0	*** All the names in each list are unique (i.e. not repeated)?
	sort=0,			*** Show matching and non-matching names in alphabetical order?
	output=1,		*** Create output datasets with matching and non-matching names?
	print=1,		*** Show the list of matching and non-matching names in the output?
	log=0);			*** Show messages in the log?

REQUIRED PARAMETERS:
- list1:		First blank-separated list of names to compare.

- list2: 		Second blank-separated list of names to compare.

OPTIONAL PARAMETERS:
- sep:			Separator used to separate the names in the lists.
				The search for 'sep' in the lists in order to determine the names
				present in the list is NOT case sensitive.
				default: %quote( ) (i.e. the blank space)

- norepeated:	Whether the lists may have repeated names so that they are repeated
				occurrences are eliminated prior to the comparison between the lists.
				Possible values: 0 => There may be repeated names
								 1 => There are no repeated names
				default: 0

- sort:			Whether to sort alphabetically the lists containing the matching and
				non-matching names.
				Possible values: 0 => Do not sort, 1 => Sort alphabetically.
				default: 0

- output:		Whether to create output datasets containing the lists of matching and
				non-matching names.
				If output=1, the following datasets are created, with one variable named NAME:
				- _INTERSECTION_:	List of names present in both lists.
				- _LIST1NOTLIST2_:	List of names present in the first list and not in the second list.
				- _LIST2NOTLIST1_: 	List of names present in the second list and not in the first list.
				Possible values: 0 => Do not create output datasets, 1 => Create output datasets.
				default: 1

- print:		Whether to show the list of matching and non-matching names in the output.
				Possible values: 0 => Do not show, 1 => Show.
				default: 1

- log:			Whether to show messages in the log.
				Possible values: 0 => Do not show messages, 1 => Show messages.
				default: 1

RETURNED VALUES:
None

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %FindInList
- %GetNroElements
- %PrintNameList
- %RemoveFromList
- %RemoveRepeated
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %CompareLists(x y z T u V, yy t u aa bb, norepeated=1);
Creates the following datasets:
- _INTERSECTION_: with 3 observations and variable NAME containing the values 'T', 'u'.
- _LIST1NOTLIST2_: with 4 observations and variable NAME containing the values 'x', 'y' 'z', 'v'.
- _LIST2NOTLIST1_: witht 2 observations and variable NAME containing the values 'aa', 'bb'.

The above lists of names is also shown in the output window.
Since there are no repeated names in each list the option NOREPEATED=1 is used so that the
process is faster.

2.- %CompareLists(x y z T u V, yy t u aa bb aa, sort=0, output=0);
The same as above with the difference that the names are sorted alphabetically. In addition,
parameter NOREPEATED is set to its default (= 0) because there are repeated names in the
second list.
*/
%MACRO CompareLists(list1, list2, sep=%quote( ), norepeated=0, sort=0, output=1, print=1, log=1)
		/ des="Compares two lists of names";
%local i j;
%local match nro_names1 nro_names2;
%local name1 name2 name1IsInList2;
%global _Intersection_ _List1NotList2_ _List2NotList1_;
%local nIntersection nList1NotList2 nList2NotList1;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put COMPARELISTS: Macro starts;
	%put;
%end;

%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );
%* Uppercase &list1, &list2 and &sep (because it can be keywords like OR, etc.),
%* so that the search for the names and the separator are NOT case sensitive;
%let list1 = %quote(%upcase(&list1));
%let list2 = %quote(%upcase(&list2));
%let sep = %quote(%upcase(&sep));

%* Remove repeated names;
%if ~&norepeated %then %do;
	%if &log %then
		%put COMPARELISTS: Removing repeated names in the lists...;
	%let list1 = %RemoveRepeated(%quote(&list1), sep=%quote(&sep), log=0);
	%let list2 = %RemoveRepeated(%quote(&list2), sep=%quote(&sep), log=0);
%end;
%else %if &log %then %do;
	%put COMPARELISTS: It is assumed that the lists do not have any repeated names.;
	%put COMPARELISTS: If this is not the case, call the macro with parameter NOREPEATED=0;
%end;

%let nro_names1 = %GetNroElements(%quote(&list1), sep=%quote(&sep));
%* Sort the names in list2 so that the search of the names in list1 is faster;
%CreateVarFromList(%quote(&list2), out=_CompareLists_list1_, sep=%quote(&sep), sort=1, log=0);
%let list2 = %MakeListFromVar(_CompareLists_list1_, log=0);

%if &log %then
	%put COMPARELISTS: Comparing lists...;
%let _Intersection_ = ;
%let _List1NotList2_ = ;
%let _List2NotList1_ = ;
%* Search in list2 for the names in list1;
%do i = 1 %to &nro_names1;
	%let name1 = %scan(%quote(&list1), &i, %quote(&sep));
	%* Search for &name1 in the second list. Note the use of %quote to enclose &name1, because
	%* &name1 may contain commas and other problematic characters;
	%let match = %FindInList(%quote(&list2), %quote(&name1), sep=%quote(&sep), match=1, sorted=1, log=0);
	%if &match ~= 0 %then %do;
		%if %quote(&_Intersection_) = %then
			%let _Intersection_ = &name1;
		%else
			%let _Intersection_ = &_Intersection_ &sep &name1;
		%* Remove name found from &list2;
		%let list2 = %RemoveFromList(%quote(&list2), %quote(&name1), sep=%quote(&sep), log=0);
	%end;
	%else
		%let _List1NotList2_ = &_List1NotList2_ &sep &name1;
%end;
%* Names that remained in list2 because no names in list1 were found in there;
%* Note that the macro variable &list2 was updated as the names in list1 were found in list2;
%let _List2NotList1_ = &list2;

%* Create datasets with the list of names present in both lists, and the names present in
%* one list and not in the other;
%PrintNameList(%quote(&_Intersection_), sep=%quote(&sep), out=_CompareLists_Intersection_, sort=&sort, log=0);
%PrintNameList(%quote(&_List1NotList2_), sep=%quote(&sep), out=_CompareLists_List1NotList2_, sort=&sort, log=0);
%PrintNameList(%quote(&_List2NotList1_), sep=%quote(&sep), out=_CompareLists_List2NotList1_, sort=&sort, log=0);

%if &print %then %do;
	title2 "Names present in both lists";
	proc print data=_CompareLists_Intersection_; run;
	title2 "Names in list1 NOT in list2";
	proc print data=_CompareLists_List1NotList2_; run;
	title2 "Names in list2 NOT in list1";
	proc print data=_CompareLists_List2NotList1_; run;
	title2;
	%if &log %then
		%put COMPARELISTS: The list of matching and not matching names is shown in the output window.;
%end;

%if &output %then %do;
	proc datasets nolist;
		delete 	_Intersection_
				_List1NotList2_
				_List2NotList1_;
		change 	_CompareLists_Intersection_  = _Intersection_
				_CompareLists_List1NotList2_ = _List1NotList2_
				_CompareLists_List2NotList1_ = _List2NotList1_;
	quit;
	%if &log %then %do;
		%callmacro(getnobs, _Intersection_ return=1, nIntersection);
		%callmacro(getnobs, _List1NotList2_ return=1, nList1NotList2);
		%callmacro(getnobs, _List2NotList1_ return=1, nList2NotList1);
		%put COMPARELISTS: Dataset _INTERSECTION_ created with names present in both lists (Total=&nIntersection).;
		%put COMPARELISTS: Dataset _LIST1NOTLIST2_ created with names in list1 not present in list2 (Total=&nList1NotList2).;
		%put COMPARELISTS: Dataset _LIST2NOTLIST1_ created with names in list2 not present in list1 (Total=&nList2NotList1).;
	%end;
%end;
%else %do;
	proc datasets nolist;
		delete 	_CompareLists_Intersection_
				_CompareLists_List1NotList2_
				_CompareLists_List2NotList1_;
	quit;
%end;

%if &log %then %do;
	%put;
	%put COMPARELISTS: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND CompareLists;
