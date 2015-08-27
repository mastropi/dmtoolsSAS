/* PROC FREQ */
/* NOTE: PROC FREQ does not support ID statement nor CLASS statement! */
&rsubmit;
%MACRO freq(dat, vars, where=, by=, byvar=, list=1, noprint=, weight=, out=, options=)
		/ store des="Executes a PROC FREQ";
%local wherest byst listst noprintst weightst outst;
%local _dat_;

%let _dat_ = &dat;

%let wherest =;
%if %quote(&where) ~= %then
	%let wherest = where &where;

%if %quote(&by) ~= %then
	%let byvar = &by;
%let byst =;
%if &byvar ~= %then %do;
	%let byst = by &byvar;
	proc sort data=&_dat_ out=_dat_;
		&byst;
	run;
	%let _dat_ = _dat_;
%end;

%let listst =; 
%if &list %then
	%let listst = list;

%let noprintst =;
%if &noprint ~= %then
	%if &noprint %then
		%let noprintst = noprint;

%let weightst = ;
%if %quote(&weight) ~= %then
	%let weightst = weight &weight;

%let outst =;
%if %quote(&out) ~= %then %do;
	%let outst = %quote(out=&out);
	%if &noprint = %then
		%let noprintst = noprint;
%end;

proc freq data=&_dat_ &noprintst;
	&wherest;
	&byst;
	&weightst;
	tables &vars / &listst &outst &options;
run;

proc datasets nolist;
	delete _dat_;
quit;
%MEND freq;
