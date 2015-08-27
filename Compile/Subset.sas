/* MACRO %Subset
Version: 1.00
Author: Daniel Mastropietro
Created: 4-Aug-04
Modified: 4-Aug-04

DESCRIPTION:
This macro subsets a dataset keeping all the observations of by variables for which a given
WHERE condition is satisfied at least once.

USAGE:
%Subset(data, where=, by=, out=);

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option.

OPTIONAL PARAMETERS:
- where:		Where statement with which the input dataset is subset.

- by:			List of by variables for which all the observations passing the
				WHERE statement are kept in the output dataset. 

- out:			Output dataset. It can receive data options as those specified in a 
				data= SAS statement.

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes.
				default: 1

NOTES:
- The order in which the input dataset is sorted is transfered to the output dataset.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Drop
- %GetDataOptions
- %Getnobs
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %Subset(A, where=x>5, by=id, out=A_subset);
Generates the output dataset A_SUBSET containing all the observations in the input
dataset A where x > 5, plus the other observations in A not satisfying the WHERE
condition, but having the same value of ID as those satisfying the condition.
Ex: If the input dataset A contains the following data:
ID	x
1	2.1
1	6.2
1	3.3
1	0.1
2	0.3
2	2.2
2	3.2
3	5.4
3	3.3
3	7.3
3	2.1

the output dataset A_SUBSET will be:
ID	x
1	2.1
1	6.2
1	3.3
1	0.1
3	5.4
3	3.3
3	7.3
3	2.1

i.e. all the observations for ID = 1 and 3 are kept because at least one observation
with those values of ID satisfies the WHERE condition x > 5.

2.- %Subset(A(obs=100), where=x>5, by=id, out=A_subset(keep=id x));
Same as Example 1 with the addition of data options for the input and output datasets.

APPLICATIONS:
1.- Useful in historical customer data to keep all the history of customers satisfying
a given condition in at least one point in time of the historical data.
*/
&rsubmit;
%MACRO Subset(data, where=, by=, out=, log=1)
	/ store des="Subsets a dataset keeping all the observations of by variables for which a given condition is satisfied at least once";
%local byst nobs nvar _out_ _out_name_;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put SUBSET: Macro starts;
	%put;
%end;

/*--------------------------------- Parsing input parameters --------------------------------*/
%* BY=;
%let byst = ;
%if %quote(&by) ~= %then
	%let byst = by &by;

%* OUT=;
%if %quote(&out) ~= %then %do;
	%let _out_ = &out;
	%let _out_name_ = %scan(&_out_, 1, '(');
%end;
%else %do;
	%let _out_ = _Subset_out_;
	%let _out_name_ = &_out_;
%end;
/*-------------------------------------------------------------------------------------------*/

%* Execute data options coming in DATA= and store the observation number to restore
%* the original order into the output dataset;
data _Subset_data_;
	set &data;
	_obs_ = _N_;
run;

%* Sort input dataset;
%if %quote(&byst) ~= %then %do;
	proc sort data=_Subset_data_;
		&byst;
	run;
%end;

%* Subset input dataset;
data _Subset_subset_;
	set _Subset_data_;
	where &where;
run;

%if &log %then %do;
	%callmacro(getnobs, _Subset_subset_ return=1, nobs);
	%put SUBSET: There are &nobs observations in %upcase(%scan(&data,1,'(')) where;
	%put SUBSET: &where;
%end;

%* Generate output dataset;
data &_out_name_;
	%** Note the use of &_out_name_ instead of &_out_. This is to avoid execution of
	%** data options at this point. See below for further explanation;
	merge _Subset_data_(in=_in1_) _Subset_subset_(in=_in2_ keep=&by);
	&byst;
	if _in1_ and _in2_;
run;
%if &log and %quote(&out) ~= %then %do;
	%callmacro(getnobs, &_out_name_ return=1, nobs nvar);
	%put SUBSET: Dataset %upcase(&_out_name_) created with &nobs observations and %eval(&nvar-1) variables.;
		%** There are (&nvar - 1) variables because variable _OBS_ will be removed below;
		%** On the other hand, I show this message here because I want to show it before
		%** the message on the number of different by variable combinations showed below,
		%** and for this message I need the variable _OBS_;
%end;

%if %quote(&byst) ~= %then %do;
	%if &log %then %do;
		%* Count and print the number of different BY variable combinations that satisfy the WHERE condition;
		proc sort data=&_out_name_ out=_Subset_nodup_ nodupkey;
			&byst;
		run;
		%callmacro(getnobs, _Subset_nodup_ return=1, nobs);
		%put SUBSET: Number of different BY variable combinations satisfying the condition: &nobs;
	%end;
	%* Sort the output dataset with the order of observations present in the input dataset;
	proc sort data=&_out_name_;
		by _obs_;
	run;
%end;

%* Drop the internal observation number if existing;
%drop(&_out_name_, _obs_);

%* Execute the data options coming in OUT= if any.
%* This is done here and not above, when the output dataset is created, because if there is
%* a KEEP= option among the data options, the variable _OBS_ will not exist any more after
%* the dataset is created and it is needed to resort it, as done above;
%if %GetDataOptions(&out) ~= %then %do;
	data &_out_;
		set &_out_;
	run;
%end;

%* Print the output dataset if OUT= is empty;
%if %quote(&out) = %then %do;
	title2 "Subset data";
	proc print data=&_out_;
	run;
	title2;
%end;

proc datasets nolist;
	delete 	_Subset_data_
			_Subset_nodup_
			_Subset_out_
			_Subset_subset_;
quit;

%if &log %then %do;
	%put;
	%put SUBSET: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND Subset;

