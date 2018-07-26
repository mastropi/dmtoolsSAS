/* MACRO %Chisq
Version: 1.00
Author: Daniel Mastropietro
Created: 7-Oct-05
Modified: 7-Oct-05

*/
%MACRO Chisq(data, by=, target=, var=, out=, format=, condition=, append=0) 
	/ des="Computes Chi-Square statistic for a dichotomous vs. categorical variable";
%LOCAL i library out_name vari nro_vars;

options nonotes;

/*----- Parsing input parameters -----*/
%let library = %GetLibraryName(&out);
%if %index(%quote(&out), .) %then %do;
	%let out_name = %scan(&out, 2, '.');
	%let out_name = %scan(&out_name, 1, '(');
%end;
%else
	%let out_name = %scan(&out, 1, '(');
/*------------------------------------*/

%let nro_vars = %GetNroElements(&var);

%IF ~&APPEND %THEN %DO;
	proc datasets library=&library nolist;
		delete &out_name;
	quit;
%END;

%DO I = 1 %TO &NRO_VARS;
	%LET VARI = %SCAN(&VAR, &I);
	%put Variable &i: %upcase(&vari);
	PROC FREQ DATA=&DATA NOPRINT;
		format &vari &format;
		%if %quote(&condition) ~= %then %do;
		where &vari &condition;
		%end;
		%if %quote(&by) ~= %then %do;
		by &by;
		%end;
		TABLES &VARI*&target / CHISQ;
		OUTPUT OUT=_CHISQ_&I CHISQ;
	RUN;

	DATA _CHISQ_&I(keep=&by var N Chisq df p LP);
		FORMAT var &by;
		LENGTH var $40 ;  
		SET _CHISQ_&I;
		format pvalue pvalue.;
		var = "&VARI";
		LP = -log10(P_PCHI);
		rename 	_PCHI_ = Chisq
				DF_PCHI = df
				P_PCHI = p;
	RUN;
	PROC APPEND BASE=&OUT DATA=_CHISQ_&I;
	RUN;
	PROC DATASETS NOLIST;
		DELETE _CHISQ_&I;
	QUIT;
%END;

options notes;
%MEND Chisq;
