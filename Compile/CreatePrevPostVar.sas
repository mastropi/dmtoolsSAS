/* MACRO %CreatePrevPostVar
Version: 1.01
Author: Daniel Mastropietro
Created: 4-Aug-04
Modified: 19-Aug-04

DESCRIPTION:
This macro creates variables containing the previous and posterior values of
a given set of variables, where 'previous' and 'posterior' is defined by an order
established by another set of variables, and optionally by a condition that must satisfy
each of the variables (e.g. previous and posterior values are updated only when the value
of the variable is not missing).
This process can be done by BY variables.

USAGE:
%CreatePrevPostVar(
	data,			*** Input dataset.
	var=_ALL_,		*** Variables to process.
	by=, 			*** By variables by which the process is performed.
	sortby=,		*** Variables defining the order of the obs. by the by variables.
	out=,			*** Output dataset.
	match=,			*** Matching criterion to update previous and posterior values.
	comparison=~=,	*** Comparison used in the matching criterion.
	which=prevpost,	*** Which values to compute? Prev, Post or both.
	suffixprev=,	*** Suffix to use for the variables containing the previous values.
	suffixpost=,	*** Suffix to use for the variables containing the posterior values.
	log=1);			*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option.

OPTIONAL PARAMETERS:
- var:			List of variables for which the previous and posterior values want
				to be stored in new variables.
				It can be specified with the format used in any VAR statement in SAS.
				(e.g. _ALL_, _NUMERIC_, x1-x3, etc.)

- by:			List of variables by which the computation of the previous and
				posterior values are computed.

- sortby:		List of variables by which the observations are sorted for each
				combination of the BY variables. These variables define what comes
				first and what comes next, based on which the previous and posterior
				values are computed.

- out:			Output dataset.	Data options can be specified as in a data= SAS option.

- match:		This value together with COMPARISON are used to specify the condition
				that each variable listed in VAR needs to satisfy in order to have
				its previous and posterior values updated.
				Exs:
				- if var=x, match=., the previous and posterior values of variable x
				are updated only 'if x ~= .' (since the default value of
				COMPARISON is '~=').
				- if var=x, match=4, comparison=<, the previous and posterior values of
				variable x are updated only 'if x < 4'.

- comparison:	See description of MATCH.
				default: ~=

- which:		Specify which values to compute for each variable listed in VAR, whether
				the previous values, posterior values, or both. Default is both.
				Possible values: prevpost, prev, post.
				default: prevpost

- suffixprev:	Suffix to use for the variable with the PREVIOUS value of the variable
				of interest.
				default: _prev

- suffixpost:	Suffix to use for the variable with the POSTERIOR value of the variable
				of interest.
				default: _post

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes.
				default: 1

NOTES:
1.- The variables containing the previous and posterior values of each requested variable
are placed right after the variable itself in the output dataset.

2.- If the variables that contain the previous and posterior values of a variable already
exist in the dataset, they are overwritten.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Drop
- %GetNroElements
- %GetVarNames
- %InsertInList
- %MakeList

EXAMPLES:
1.- %CreatePrevPostVar(A, var=x, by=groupID, sortby=mth);
This creates the variables X_PREV and X_POST in dataset A with the previous and posterior
values of variable X by variable GROUPID.
The conditions of 'previous' and 'posterior' are defined by the variable MTH, which
establishes the order of the observations for each value of the by variable GROUPID.

2.- %CreatePrevPostVar(A, var=x, by=groupID, sortby=mth, match=.);
Idem example 1, but previous and posterior values of variable x are updated only
if X is not missing.
This creates variables containing the previous and posterior values of variable X
that either occur BEFORE and AFTER blocks of observations for which X is missing,
or the usual previous and posterior values when X is not missing.
Ex: This would be the effect on the following data:
groupID		mth		X		X_prev 		X_post
10			1		5		.			2
10			2		2		5			4
10			3		4		2			3
10			4		.		4			3
10			5		.		4			3
10			6		.		4			3
10			7		3		4			6
10			1		6		3			.
234			2		7		.			2
234			3		2		7			5
234			4		5		2			.
*/

/* PENDIENTE:
- 17/8/04: Agregar el calculo del numero de valores contiguos que son iguales a match.

*/
&rsubmit;
%MACRO CreatePrevPostVar(
						data,
						out=,

						var=,
						by=,
						sortby=,

						condition=,
						match=,
						comparison=~=,

						which=prevpost,
						suffixprev=_prev,
						suffixpost=_post,
						log=1) / store des="Creates two variables with the previous and posterior values of a third variable";
%local data_name order out_name vars;
%local i byst_ascending byst_descending var_prev var_post;
%local _var_ _var_prev_ _var_post_;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put CREATEPREVPOSTVAR: Macro starts;
	%put;
%end;

%if %quote(&by) ~= %then %do;
	proc sort data=&data out=_CreatePrevPostVar_data_;
		%** Options coming with DATA= are executed here;
		by &by &sortby;
	run;
%end;

data _CreatePrevPostVar_data_;
	%if %quote(&by) ~= %then %do;	%* Temporary input dataset already created above;
	set _CreatePrevPostVar_data_;
	%end;
	%else %do;
	set &data;						%* Temporary input dataset not created yet;
	%end;
	retain _OBS_ 0;
	%if %quote(&by) ~= %then %do;
	by &by;
	if %MakeList(&by, prefix=first., sep=and) then
		_OBS_ = 0;
	%end;
	_OBS_ = _OBS_ + 1;
run;

/*---------------------------------- Parsing input parameters -------------------------------*/
%* VAR=;
%* Parse variable list passed as _ALL_, _NUMERIC_, x1-x3, etc.;
%let var = %GetVarList(_CreatePrevPostVar_data_, var=&var, log=0);
%let nro_vars = %GetNroElements(&var);

%* BY=, SORTBY=;
%if %quote(&sortby) ~= %then %do;
	%let byst_descending = by &by %MakeList(&sortby, prefix=%str(descending ));
	%let byst_ascending  = by &by &sortby;
%end;
%else %do;	%* Use observation number to sort;
	%let byst_descending = by &by descending _OBS_;
	%let byst_ascending  = by &by _OBS_;
%end;
/*-------------------------------------------------------------------------------------------*/

/*----------------------------------------- START -------------------------------------------*/
%* POST variables;
%if %upcase(&which) = PREVPOST or %upcase(&which) = POST %then %do;
	%* Sort in descending order of sortby variables;
	proc sort data=_CreatePrevPostVar_data_;
		&byst_descending;
	run;
	%* Drop variables &var_post from the input dataset should they exist, to avoid problems
	%* of updating their value;
	%let var_post = %MakeList(&var, suffix=&suffixpost);
	%Drop(_CreatePrevPostVar_data_, &var_post);

	%* Variables present in dataset before adding the posterior variables;
	%let vars = %GetVarNames(_CreatePrevPostVar_data_);
	%* Place the POST variables after each original variable;
	%let order = &vars;
	%do i = 1 %to &nro_vars;
		%let _var_ = %scan(&var, &i, ' ');
		%let _var_post_ = %scan(&var_post, &i, ' ');
		%let order = %InsertInList(&order, &_var_post_, after, &_var_);
	%end;

	%* Add the POST variables in the temporary input dataset;
	data _CreatePrevPostVar_data_;
		format &order;
		set _CreatePrevPostVar_data_ end=lastobs;
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var, &i, ' ');
			%let _var_post_ = %scan(&var_post, &i, ' ');
			retain &_var_post_._temp_;	%* Temporary POST value;
			retain &_var_post_;			%* Real POST value;
		%end;
		%if %quote(&by) ~= %then %do;
		by &by;
		if %MakeList(&by, prefix=first., sep=and) then do;
		%end;
		%else %do;
		if _N_ = 1 then do;
		%end;
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var, &i, ' ');
			%let _var_post_ = %scan(&var_post, &i, ' ');
			&_var_post_._temp_ = .;
			&_var_post_ = .;
		%end;
		end;
		else do;
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var, &i, ' ');
			%let _var_post_ = %scan(&var_post, &i, ' ');
			&_var_post_ = &_var_post_._temp_;
		%end;
		end;

		%* Update temporary variables with current values?;
		%if %quote(&condition) ~= %then %do;
		if ~(&condition) then do;
		%end;
		%else %do;
		do;
		%end;
		%if %quote(&match) ~= %then
			%do i = 1 %to &nro_vars;
				%let _var_ = %scan(&var, &i, ' ');
				%let _var_post_ = %scan(&var_post, &i, ' ');
			if &_var_ &comparison &match then
				&_var_post_._temp_ = &_var_;
			%end;
		%else
			%do i = 1 %to &nro_vars;
				%let _var_ = %scan(&var, &i, ' ');
				%let _var_post_ = %scan(&var_post, &i, ' ');
			&_var_post_._temp_ = &_var_;
			%end;
		end;
		drop %MakeList(&var_post, suffix=_temp_);
	run;
%end;
%* Sort in ascending order of the sortby variables;
proc sort data=_CreatePrevPostVar_data_;
	&byst_ascending;
run;
%* PREV value;
%if %upcase(&which) = PREVPOST or %upcase(&which) = PREV %then %do;
	%* Drop variables &var_prev from the input dataset should they exist, to avoid problems
	%* of updating their value;
	%let var_prev = %MakeList(&var, suffix=&suffixprev);
	%Drop(_CreatePrevPostVar_data_, &var_prev);

	%* Variables present in dataset before adding the previous variables;
	%let vars = %GetVarNames(_CreatePrevPostVar_data_);
	%* Place the PREV variables after each original variable;
	%let order = &vars;
	%do i = 1 %to &nro_vars;
		%let _var_ = %scan(&var, &i, ' ');
		%let _var_prev_ = %scan(&var_prev, &i, ' ');
		%let order = %InsertInList(&order, &_var_prev_, after, &_var_);
	%end;

	%* Add the PREV variables in the temporary input dataset;
	data _CreatePrevPostVar_data_;
		format &order;
		set _CreatePrevPostVar_data_ end=lastobs;
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var, &i, ' ');
			%let _var_prev_ = %scan(&var_prev, &i, ' ');
			retain &_var_prev_._temp_;	%* Temporary PREV value;
			retain &_var_prev_;			%* Real PREV value;
		%end;
		%if %quote(&by) ~= %then %do;
		by &by;
		if %MakeList(&by, prefix=first., sep=and) then do;
		%end;
		%else %do;
		if _N_ = 1 then do;
		%end;
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var, &i, ' ');
			%let _var_prev_ = %scan(&var_prev, &i, ' ');
			&_var_prev_._temp_ = .;
			&_var_prev_ = .;
		%end;
		end;
		else do;
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var, &i, ' ');
			%let _var_prev_ = %scan(&var_prev, &i, ' ');
			&_var_prev_ = &_var_prev_._temp_;
		%end;
		end;

		%* Update temporary variables with current values?;
		%if %quote(&condition) ~= %then %do;
		if ~(&condition) then do;
		%end;
		%else %do;
		do;
		%end;
		%if %quote(&match) ~= %then
			%do i = 1 %to &nro_vars;
				%let _var_ = %scan(&var, &i, ' ');
				%let _var_prev_ = %scan(&var_prev, &i, ' ');
			if &_var_ &comparison &match then
				&_var_prev_._temp_ = &_var_;
			%end;
		%else
			%do i = 1 %to &nro_vars;
				%let _var_ = %scan(&var, &i, ' ');
				%let _var_prev_ = %scan(&var_prev, &i, ' ');
			&_var_prev_._temp_ = &_var_;
			%end;
		end;
		drop %MakeList(&var_prev, suffix=_temp_);
	run;
%end;
%if &log %then %do;
	%if %upcase(&which) = PREVPOST or %upcase(&which) = PREV %then %do;
		%put CREATEPREVPOSTVAR: Variables;
		%put CREATEPREVPOSTVAR: %upcase(&var_prev);
		%put CREATEPREVPOSTVAR: created, with the previous values of;
		%put CREATEPREVPOSTVAR: %upcase(&var);
	%end;

	%put;
	%if %upcase(&which) = PREVPOST or %upcase(&which) = POST %then %do;
		%put CREATEPREVPOSTVAR: Variables;
		%put CREATEPREVPOSTVAR: %upcase(&var_post);
		%put CREATEPREVPOSTVAR: created, with the posterior values of;
		%put CREATEPREVPOSTVAR: %upcase(&var);
	%end;

	%put;
	%if %quote(&sortby) ~= %then %do;
		%put CREATEPREVPOSTVAR: The variables were created according to the order of variable(s);
		%put CREATEPREVPOSTVAR: %upcase(&sortby);
	%end;
	%else
		%put CREATEPREVPOSTVAR: The variables were created according to the order they appear in the input dataset;
	%if %quote(&by) ~= %then
		%put CREATEPREVPOSTVAR: by variable(s) %upcase(&by).;

	%put;
	%if %quote(&condition) ~= %then %do;
		%put CREATEPREVPOSTVAR: Previous and/or posterior values are updated only when;
		%put CREATEPREVPOSTVAR: the following condition occurs: %quote(%')&condition%quote(%') .;
	%end;
	%if %quote(&match) ~= %then %do;
		%put CREATEPREVPOSTVAR: Previous and/or posterior values are updated only when;
		%put CREATEPREVPOSTVAR: the variable is %quote(%')&comparison &match%quote(%') .;
	%end;
%end;

%if %quote(&out) ~= %then %do;
	%* Execute data options comming in OUT= and drop the variable with the internal observation number, _OBS_;
	%let out_name = %scan(&out, 1, '(');
	data &out;
		set _CreatePrevPostVar_data_;
		drop _OBS_;
	run;
	%if &log %then
		%put CREATEPREVPOSTVAR: Dataset %upcase(&out_name) created.;
%end;
%else %do;
	%* Update input dataset with the new variables and drop variable _OBS_;
	%let data_name = %scan(&data, 1, '(');
	data &data_name;			%* &data_name is used because the options coming in &data were
								%* already executed at the beginning;
		set _CreatePrevPostVar_data_;
		drop _OBS_;
	run;
%end;

proc datasets nolist;
	delete _CreatePrevPostVar_data_;
quit;

%if &log %then %do;
	%put;
	%put CREATEPREVPOSTVAR: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND CreatePrevPostVar;
