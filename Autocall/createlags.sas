/* MACRO %CreateLags
Version: 1.00
Author: Daniel Mastropietro
Created: 20-Aug-04
Modified: 20-Aug-04

DESCRIPTION:
This macro creates, in the input dataset, a set of lagged variables
(lags 1 to n) of a given set of variables.
The process can be done by BY variables.

USAGE:
%CreateLags(
	data,			*** Input dataset
	n=1,			*** Number of lags to compute
	var=_ALL_,		*** Variables to process
	by=, 			*** By variables by which the process is performed
	sortby=,		*** Variables defining the order of the obs. by the by variables
	suffix=_,		*** String to separate the name of the variable with the lag number
	log=1);			*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. NO data options can be specified.

OPTIONAL PARAMETERS:
- var:			List of variables to lag.
				default: _ALL_

- by:			List of variables by which the computation of the lagged variables
				is done.

- sortby:		List of variables by which the observations are sorted for each
				combination of the BY variables. These variables define what comes
				first and what comes next, and thus define the values of the lagged
				variables.

- suffix:		String to use for the name of the lagged variable to separate the
				name of the variable being lagged and the lag number.
				default: '_'
				(ex: x_1, x_2 will be the lags of variable x)

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes.
				default: 1

NOTES:
1.- The variables containing the lagged values are created in the input dataset and are
placed right after the original variable being lagged.
Their names are formed by adding the numbers 1 through n after the name of the variable
being lagged, and using SUFFIX to separate the name from the number.
(ex., with the default value of SUFFIX, lagged variables of x are named x_1, x_2, ..., x_n.) 

2.- If the variables containing the lagged values of a variable already exist in the
input dataset, they are overwritten.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CreateInteractions
- %CreatePrevPostVar

EXAMPLES:
1.- %CreateLags(A, n=3, var=x y, by=groupID, sortby=mth, suffix=);
This creates the variables X1, X2, X3, Y1, Y2, Y3 in dataset A containing the
1- to 3-lagged values of variables X and Y respectively, by variable GROUPID.
The order defining the lagged values is given by the variable MTH, which
establishes the order of the observations for each value of the by variable GROUPID.
*/
%MACRO CreateLags(data, n=1, var=_ALL_, by=, sortby=, suffix=_, log=1)
		/ des="Creates a set of lagged variables";
%CreatePrevPostVar(	&data, 
					by=&by, sortby=&sortby,
					var=&var,
					which=prev, suffixprev=&suffix.1, log=&log);
%do i = 2 %to &n;
	%CreateInteractions(%MakeList(&var, suffix=&suffix%eval(&i-1)&suffix&i),
					  with=%MakeList(&var, suffix=&suffix&i),
					  allInteractions=0,
					  join=%quote(=),
					  macrovar=_rename_, log=0);
	%CreatePrevPostVar(	&data, 
						by=&by, sortby=&sortby,
						var=%MakeList(&var, suffix=&suffix%eval(&i-1)),
						which=prev, suffixprev=&suffix&i,
						out=&data(rename=(&_rename_)), log=&log);
%end;

%if &n > 1 %then %do;
	%symdel _rename_;	%* since _rename_ is defined as global in %CreateInteractions;
	quit;
%end;

%MEND CreateLags;
