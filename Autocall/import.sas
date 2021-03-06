/* Macro to import an external file (CSV, TXT, EXCEL, DLM (delimited file)).
Use DLM for delimited file and specify the delimiter in option DELIMITER.
For tab separated files use the hexadecimal value '09'x.
*/
%MACRO import(dat , file , type=CSV, firstobs=2, sheet=, delimiter=',', guessingrows=1000) / des="Imports an external file";
%local getnames;
%if &firstobs = 1 %then
	%let getnames = NO;
%else %if &firstobs > 1 %then
	%let getnames = YES;
%else
	%put ERROR: The value of firstobs must be positive: &firstobs;
PROC IMPORT OUT=&dat 
            DATAFILE=&file
            DBMS=&type REPLACE;
	%if %index(%upcase(%quote(&type)), EXCEL) = 0 %then %do;
	%* Add the delimiter if the data is NOT in Excel format;
	DELIMITER=&delimiter;
	%end;
	%if %quote(%upcase(&type)) = CSV %then %do;
	GUESSINGROWS=&guessingrows;
	%end;
	%if %index(%upcase(%quote(&type)), EXCEL) %then %do;
		%if %quote(&sheet) ~= %then %do;
		RANGE="&sheet$";
		%end;
	%end;
	%else %do;
	DATAROW=&firstobs;
	%end;
	GETNAMES=&getnames;
RUN;
%MEND;
