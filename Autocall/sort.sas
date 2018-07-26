/* %MACRO Sort
Version: 1.01
Author: Daniel Mastropietro
Created: 1-Dec-00
Modified: 24-May-03

DESCRIPTION:
Sorts a one or more datasets by a set of by variables.
(NOTE: No variable in the by variable list should be named 'DESCENDING',
because they are removed from the list.)

USAGE:
%Sort(
	data,		*** Input datasets to be sorted
	by=,		*** By variables by which the sort is done
	out=,		*** Output datasets where the sorted datasets are stored
	options=);	*** Options for the PROC SORT statement.

REQUIRED PARAMETERS:
- data:			Blank separated list of input datasets to be sorted.
				They CANNOT have data options as in a data= SAS option.

- by=:			Blank separated list of by variables by which each dataset
				listed in 'data' is sorted.
				NOTE: It is assumed that no variable in the by variable list
				is called DESCENDING, because any variable called DESCENDING
				is removed from the list.

OPTIONAL PARAMETERS:
- out:			Blank separated list of output datasets. The number of
				output datasets must be equal to the number of input
				datasets. The first dataset in 'out' corresponds to the
				first dataset in 'data', the second to the second and so on.

- options:		Options to be used in the PROC SORT statement.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckInputParameters
- %GetNroElements
- %RemoveFromList

EXAMPLES:
- %sort(data1 data2 , a b , out=sorted1 sorted2 , options=nodupkey);
Sorts datasets data1 and data2 by variables 'a' and 'b' and eliminates
observations with repeated values of 'a' and 'b'. The sorted datasets
are stored in sorted1 and sorted2, respectively.
*/
%MACRO Sort(data , by= , out= , options= , help=0) / des="Sorts multiple datasets";

/* Macro that displays usage */
%MACRO ShowMacroCall;
	%put SORT: The macro call is as follows:;
	%put %nrstr(%Sort%();
	%put data , (REQUIRED) %quote(      *** Input datasets to be sorted);
	%put by= ,  (REQUIRED) %quote(      *** By variables by which the sort is done);
	%put out= , %quote(                 *** Output datasets where the sorted datasets are stored);
	%put options=)%quote(               *** Options for the PROC SORT statement);
%MEND ShowMacroCall;

%local bytmp j dataj error nro_data nro_out outj outst;

%if &help %then %do;
	%ShowMacroCall;
%end;
%* Removing keyword DESCENDING from the by variable list in case it exists.
%* Otherwise, the keyword will be treated as a variable;
%else %do;
	%let bytmp = %RemoveFromList(&by , descending , log=0);
	%if ~%CheckInputParameters(	data=&data , var=&bytmp , requiredParamNames=data by= ,
								varRequired=1 , singleData=0, macro=SORT) %then %do;
		%ShowMacroCall;
	%end;	
	%else %do;
		%let nro_data = %GetNroElements(&data);
		%let error = 0;
		%if %quote(&out) ~= %then %do;
			%let nro_out = %GetNroElements(&out);
			%if &nro_out ~= &nro_data %then %do;
				%let error = 1;
				%put SORT: ERROR - The number of output datasets is not the same as the input datasets;
				%put SORT: The macro will stop executing;
			%end;
		%end;
		%if ~&error %then
			%do j = 1 %to &nro_data;
				%let dataj = %sysfunc( scan(&data,&j,' ') );
				%let outj = %sysfunc( scan(&out,&j,' ') );
				%let outst = ;
				%if &outj ~= %then
					%let outst = %str( out=&outj );
				proc sort data=&dataj &outst &options;
					by &by;
				run;
			%end;
	%end;	%* %if ~%CheckInputParameters;
%end;	%* %if &help;
%MEND Sort;
