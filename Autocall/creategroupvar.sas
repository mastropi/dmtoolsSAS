/* %MACRO %CreateGroupVar
Version: 		1.03
Author: 		Daniel Mastropietro
Created: 		01-Dec-2000
Modified: 		21-Jun-2012

DESCRIPTION:
This macro creates a single group id variable from a set of by variables, so that
the different by groups are identified with the values of that variable.

USAGE:
%CreateGroupVar(
	_data_ , 			*** Input dataset
	by= ,    			*** By variables from which the group id variable is created
	out= ,				*** Output dataset
	name=_GROUPID_ ,	*** Name to be used for the group id variable
	ngroups=,			*** Name of the global macro variable where the nro. of different
						*** groups is stored
	sort=0,				*** Sort the output dataset by the by variables or keep original order?
	log=1);				*** Show messages in the log?

REQUIRED PARAMETERS:
- _data_:			Input dataset.
					It can receive any additional option as in any SAS data= option.

- by=:				By variables from the group id variable is created.
					The keyword DESCENDING is accepted in order to define how the group
					variable maps the original order of the BY variables being identified.

OPTIONAL PARAMETERS:
- out:				Output dataset.
					If this parameter is empty, the group id variable is added to
					the intput dataset.
					The variables in the output dataset are placed so that the by
					variables and the group id variable appear first.

- name:				Name to be used for the group id variable created.
					default: _GROUPID_

- ngroups:			Name of the macro variable where the nro. of different
					groups found in the by variables is stored.
					This name cannot be 'ngroups', nor any other name used for the
					input parameters, and cannot have underscores at the beginning
					and at the end (such as in _nrogroups_).
					This number coincides with the number of different values of
					the group id varible.

- sort:				Whether the output dataset should be sorted by the by variables or
					whether the original order of the observations should be kept.
					Possible values: 0 => Keep original order, 1 => Sort by by variables.
					default: 0

- log:				Show messages in the log?
					Possible values: 0 => Do not show, 1 => Show.
					default: 1

NOTES:
The dataset should not have a variable named _CreateGroupVar_obs_. If it does, it will
be overwritten in the output dataset.
The name of the global macro variable passed in parameter NGROUPS= cannot be _DATA_ nor any
other parameter name, and it cannot contain underscores.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
- %MakeList
- %ResetSASOptions
- %SetSASOptions

SEE ALSO:
- %GraphXY
- %Scatter

EXAMPLES:
1.- %CreateGroupVar(test , by=strata substrata , name=group , ngroups=nrogroups);
Creates group id variable 'group' in dataset TEST, which has a different value for each
combination of the values of variables 'strata' and 'substrata'.
The number of different values taken by 'group' is stored in the global macro variable
&nrogroups.

2.- %CreateGroupVar(test , by=strata substrata , out=test_group , name=group, sort=1);
Creates dataset TEST_GROUP with group id variable 'group', identifying each different
combination of the values of variables 'strata' and 'substrata'.
Since SORT=1, the output dataset is sorted by the by variables STRATA and SUBSTRATA.

APPLICATIONS:
1.- Used to create the 'strata' variable used in the graphical macros %GraphXY and %Scatter
that identifies the different groups defining the colors used for the points in a scatter
plot.
Ex:
%CreateGroupVar(test , by=strata substrata , name=group);
%GraphXY(test , x , y , strata=group);

2.- To deal more simply with groups that are defined by the values of multiple variables,
since they can be referred to with a single variable.
*/
%MACRO CreateGroupVar(_data_ , by= , out= , name=_GROUPID_ , ngroups= , sort=0, log=1 , help=0)
	/ des="Creates a variable identifying each group of by variables";
%local _data_name_ _newgroup_ _ngroups_ _out_name_ _temp_;
	%*** All the variable names have underscores because this macro may return a macro variable and if
	%*** the selected name for this macro variable coincides with one of the locally defined macro variables,
	%*** only the local macro variable is changed, not the one that should be returned by the macro;

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put CREATEGROUPVAR: The macro call is as follows:;
	%put %nrstr(%CreateGroupVar%();
	%put _data_ , (REQUIRED) %quote(    *** Input dataset);
	%put by= ,    (REQUIRED) %quote(    *** By variables from which the group id variable is created);
	%put out= ,	%quote(                 *** Output dataset);
	%put name=_GROUPID_ , %quote(       *** Name to be used for the group id variable);
	%put ngroups=) %quote(              *** Name of the macro variable where the nro. of created groups is stored);
%MEND ShowMacroCall;

%* DM-2012/06/21: Remove any (potential) DESCENDING keyword from the BY variable list before checking the parameters;
%let byvars = %sysfunc(tranwrd(%upcase(&by), DESCENDING, ));
%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters( data=&_data_ , var=&byvars , requiredParamNames=data by= ,
								varRequired=1 , macro=CREATEGROUPVAR) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%SetSASOptions;

%let _data_name_ = %scan(&_data_ , 1 , '(');

%let _newgroup_ = %MakeList(&byvars , prefix=First. , sep=%quote( or ));
%let _newgroup_ = (&_newgroup_);	%*** Add parenthesis;

data _CreateGroupVar_data_;
	set &_data_;		%* All the options coming with &_data_ are executed here;
	%* When SORT=0, store the original order of the observations in the dataset, in order to
	%* restore the dataset to this order;
	%if ~&sort %then %do;
	_CreateGroupVar_obs_ = _N_;
	%end;
run;
%*** Sorting by the by variables;
proc sort data=_CreateGroupVar_data_ out=_CreateGroupVar_data_sorted_;
	by &by;
run;

data _CreateGroupVar_data_sorted_;
	set _CreateGroupVar_data_sorted_;
	by &by;
	retain &name 0;
	if &_newgroup_ then do;
		&name = &name + 1;
	end;
run;

%*** Getting the number of groups generated (if requested by an output macro variable);
%if %quote(&ngroups) ~= %then %do;
	proc sort data=_CreateGroupVar_data_sorted_ out=_CreateGroupVar_ngroups_(keep=&name) nodupkey;
		by &name;
	run;
	%callmacro(getnobs , _CreateGroupVar_ngroups_ return=1 , _ngroups_);
	%global &ngroups;
	%let &ngroups = &_ngroups_;
%end;

%if %quote(&out) = %then %do;
	%let out = &_data_name_;
	%let _out_name_ = &out;
%end;
%else
	%let _out_name_ = %scan(&out , 1 , '(');

%* When SORT=0, restore the original order in the output dataset;
%if ~&sort %then %do;
	proc sort data=_CreateGroupVar_data_sorted_ out=&_out_name_(drop=_CreateGroupVar_obs_);
		by _CreateGroupVar_obs_;
	run;
	data &_out_name_;
		set &out;		%* Here the options in out= are executed;
	run;
%end;
%else %do;
	data &out;
		set _CreateGroupVar_data_sorted_;
	run;
%end;
%if &log %then %do;
	%put;
	%if &_out_name_ ~= &_data_name_ %then
		%put CREATEGROUPVAR: Output dataset %upcase(&_out_name_) created.;
	%put CREATEGROUPVAR: Group id variable %upcase(&name) created in dataset %upcase(&_out_name_).;
%end;
	
proc datasets nolist;
	delete 	_CreateGroupVar_data_
			_CreateGroupVar_data_sorted_
 			_CreateGroupVar_ngroups_;
quit;

%ResetSASOptions;
%end; 	%* %if ~%CheckInputParameters;
%MEND CreateGroupVar;
