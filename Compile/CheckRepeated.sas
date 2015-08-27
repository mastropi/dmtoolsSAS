/* MACRO %CheckRepeated
Version: 1.03
Author: Daniel Mastropietro
Created: 1-Nov-00
Modified: 20-Oct-05

DESCRIPTION:
This macro finds observations with repeated key values, and creates a dataset containing all
the observations with repeated key values.

USAGE:
%CheckRepeated(data, by=, out=, log=1);

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in any data= SAS option.

- by=:			List of key variables that define the condition of repeated observation.

OPTIONAL PARAMETERS:
- out:			Output dataset. Data options can be specified as in any DATA= SAS option.
				It contains the observations in the input dataset with repeated key values.
				The key variables are placed first in the dataset.
				Variable _COUNT_ is added to the output dataset containing the number of
				observations with the same key values.
				default: _CR_out_

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
- %MakeList
- %ResetSASOptions
- %SetSASOptions

NOTES:
1.- The variables analyzed cannot have the name of any reserved word used in the SELECT statement
(such as CASE).

EXAMPLES:
1.- %CheckRepeated(test, id month, out=repeated);
Finds and stores in dataset REPEATED the observations in TEST that have the same values of
variables ID and MONTH.

APPLICATIONS:
This macro is useful to check if there are observations with repeated key values and if so,
to take a look at those observations.
*/
&rsubmit;
%MACRO CheckRepeated(data, by=, out=_CR_out_, log=1)
		/ store des="Finds observations that have repeated values in a given set of by variables";
%local byvars_list byvars_crossed nobs;
%local data_name out_name;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put CHECKREPEATED: Macro starts;
	%put;
%end;

%let data_name = %scan(&data, 1, '(');
%let out_name = %scan(&out, 1, '(');

%let byvars_list = %MakeList(&by, sep=%quote(,));
proc sql;
	create table &out as
		select *, count(*) as _count_
		from &data
		group by &byvars_list
		having calculated _count_ > 1
		order by &byvars_list;
quit;

%* Count number of by variables combinations with repeated values;
proc sort data=&out_name(keep=&by) out=_CR_nodup_ nodupkey;
	by &by;
run;
%Callmacro(getnobs, _CR_nodup_ return=1, nobs);

%if &log %then %do;
	%put CHECKREPEATED: There are &nobs unique observations with repeated values of;
	%put CHECKREPEATED: %upcase(&by) in dataset %upcase(&data_name).;
	%put;
	%put CHECKREPEATED: Output dataset %upcase(&out_name) created containing the observations;
	%put CHECKREPEATED: with repeated key values and their counts (stored in variable _COUNT_).;
%end;

proc datasets nolist;
	delete 	_CR_nodup_
		 	_CR_freq_;
	%if %quote(&out_name) ~= _CR_out_ %then %do;
	delete _CR_out_;
	%end;
quit;

%if &log %then %do;
	%put;
	%put CHECKREPEATED: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND CheckRepeated;
