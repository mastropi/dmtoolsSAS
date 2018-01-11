/* MACRO %OptimizeLength
Version: 	1.00
Author: 	Daniel Mastropietro
Created: 	20-Apr-2016
Modified: 	20-Apr-2016

DESCRIPTION:
Minimizes the length of integer variables based on their value range (absolute min-max values).
The length string is created and stored in a global macro variable specified by the user.

CAUTION: A variable is considered integer-valued only based on its INFORMAT with the following criteria:
- the informat length should be larger than 0,
- the number of decimals in the format should be 0.

Note that variables created during a data step with no explicit INFORMAT statement, the above
two pieces of information are set to 0, therefore they will not be considered integer-valued
variables even if their values are integer.

USAGE:
%OptimizeLength(data, var=_ALL_, apply=0, out=_OptimizeLength_, macrovar=lengthstr, log=1);

REQUIRED PARAMETERS:
- data:			Input dataset. Options are not accepted.

OPTIONAL PARAMETERS:
- var:			List of variables to analyze.
				default: _ALL_

- apply:		Whether to apply the LENGTH statement to the input dataset.
				Possible values: 0 => No, 1 => Yes
				default: 0

- out:			Output dataset containing the variables range and the minimum accepted length.
				default: _OptimizeLength_

- macrovar:		Name of the global macro variable where the LENGTH statement is stored.
				default: lengthstr

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 0

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CreateInteractions
- %ExecTimeStart
- %ExecTimeStop
- %GetVarOrder
- %MakeListFromVar
- %Means
- %ResetSASOptions
- %SetSASOptions
*/
&rsubmit;
%MACRO OptimizeLength(data, var=_ALL_, apply=0, out=_OptimizeLength_, macrovar=lengthstr, print=1, log=1) / store des="Optimizes the length of integer variables based on their value range";
%local var4len;
%local len4len;
%global _lengthstr_;	%* Global macro varibale generated by %CreateInteracions;

%SetSASOptions;
%ExecTimeStart;

%if &log %then %do;
	%put;
	%put OPTIMIZELENGTH: Macro starts;
	%put;
%end;

%* Extract the numeric integer variables;
proc contents data=&data(keep=&var) out=_ol_contents_ noprint;
run;
data _ol_contents_discrete_;
	set _ol_contents_;
	%* Condition for numeric and integer variables (although this is NOT always the case as some integer values may have INFORML = 0!;
	%* I think it depends on how the variable was read from the source (if the variable was created in SAS without any informat, it will
	%* have INFORML = 0.;
	where informl > 0 and informd = 0 and informat ~= "$";
run;
%let var4len = %MakeListFromVar(_ol_contents_discrete_, var=name, log=0);

%if %quote(&var4len) = %then %do;
	%if &log %then %do;
		%put OPTIMIZELENGTH: No integer variables were found among the input variables (based on their INFORMATS);
		%put OPTIMIZELENGTH: in input dataset %upcase(&data) to be optimized.;
		%put OPTIMIZELENGTH: The macro will stop executing.;
	%end;
%end;
%else %do;
	%if &log %then
		%put OPTIMIZELENGTH: Computing MIN and MAX values for each integer variable...;
	%Means(&data(keep=&var), var=&var4len, transpose=1, stat=min max, namevar=var, out=_ol_means_, log=0);

	%if &log %then
		%put OPTIMIZELENGTH: Computing minimum possible length...;
	data _ol_means_;
		format var min max len len_orig;
		merge 	_ol_means_
				_ol_contents_discrete_(keep=name length rename=(name=var length=len_orig));
		by var;
		array amax(6) max3-max8;
		do nbytes = 3 to 8;
			i = nbytes - 2;
			* Formula that computes the maximum value allowed based on the number of bytes (length);
			shift = nbytes - 4;
			amax(i) = 2**(7*(nbytes-1) + shift);
			if abs(min) <= amax(i) and abs(max) <= amax(i) then do;
				if missing(len) then
					len = nbytes;
			end;
		end;
		label 	len = "Minimum variable length"
				len_orig = "Original variable length";
		drop i nbytes shift;
	run;

	%* Create the macro variable with the LENGTH string for those variables whose minimum length is smaller than the original length;
	%if &log %then
		%put OPTIMIZELENGTH: Generating LENGTH statement...;
	data _ol_lengths_;
		set _ol_means_;
		where len < len_orig;
	run;
	%let var4len = %MakeListFromVar(_ol_lengths_, var=var, log=0);
	%let len4len = %MakeListFromVar(_ol_lengths_, var=len, log=0);
	%if %quote(&var4len) ~= %then %do;
		%CreateInteractions(&var4len, with=&len4len, allinteractions=0, join=%quote( ), macrovar=_lengthstr_, log=0);
		%if &print %then %do;
			title "Minimum length to apply to each variable";
			proc print data=_ol_means_;
				var var len len_orig;
			run;
			title;
		%end;
	%end;
	%else %if &log %then %do;
		%put;
		%put OPTIMIZELENGTH: All variables are at its minimum possible length, no LENGTH string will be generated.;
		%put;
	%end;

	%* Save the length string to the global macro variable name specified by the user;
	%if %quote(&macrovar) ~= and %quote(&_lengthstr_) ~= %then %do;
		%global &macrovar;
		%let &macrovar = &_lengthstr_;
		%if &log %then
			%put OPTIMIZELENGTH: Global macro variable (%upcase(&macrovar)) created with the LENGTH statement.;
	%end;

	%if %quote(&out) ~= %then %do;
		data &out;
			set _ol_means_;
		run;
		%if &log %then
			%put OPTIMIZELENGTH: Dataset %upcase(&out) created with the information about variables range and minimum length.;
	%end;

	%* If requested apply the minimum lengths;
	%if &apply and %quote(&_lengthstr_) ~= %then %do;
		%global _varorder_;
		%GetVarOrder(&data, _varorder_);
		%if &log %then %do;
			%put;
			%put OPTIMIZELENGTH: Applying the generated LENGTH statement to input dataset %upcase(&data)...;
			%put OPTIMIZELENGTH: A warning message will show up for each variable whose length is reduced.;
		%end;
		data &data;
			format &_varorder_;
			length &_lengthstr_;
			set &data;
		run;
		%symdel _varorder_;
	%end;
%end;

%* Cleanup;
proc datasets nolist;
	delete	_ol_contents_
			_ol_contents_discrete_
			_ol_means_;
quit;
%symdel _lengthstr_;

%if &log %then %do;
	%put;
	%put OPTIMIZELENGTH: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;
%MEND OptimizeLength;
