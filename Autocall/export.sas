/* Export.sas
Created: ~ 2003
Modified: 07-Aug-2015
Macro to export to a file (default CSV file; for TAB delimited file, use type=TAB).
Leave the FILE parameter empty to quickly save the dataset to a CSV file with the same name as the dataset
in the WORK library. */
%MACRO export(dat, file=, type=csv) / des="Easily exports a dataset";
%local workdir;
%if %quote(&file) = %then %do;
	%let workdir = %sysfunc(getoption(WORK));
	%let file = "&workdir\&dat..csv";
%end;
proc export data=&dat
			outfile=&file
			dbms=&type replace;
run;
%MEND export;

