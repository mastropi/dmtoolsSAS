/* Macro that returns the number of observations (nobs) and variables (nvar) in a data set.
It uses the function ATTRN. Taken from Ex. 5 in %SYSFUNC help documentation.
If the input parameter return is equal to 0, no variables are returned as a result of calling
the function. Otherwise, 2 variables, nobs and nvar, defined as local to this macro, are returned.
Note: Parameters 'print' and 'log' indicate the same. The one prefered is 'log', but 'print' was left
for compatibility issues with previous versions.
If return=1, then print and log are set to 0, regardless of their values.
*/
%MACRO getnobs(data,return=0,print=1,log=1) 
	/ des="Computes the number of observations and variables in a dataset";

%local nobs nvar;
%let nobs = 0;	%*** These initializations are for the default in case the dataset does not exist;
%let nvar = 0;

%let data_id = %sysfunc(open(&data));
%if &data_id %then
   	%do;
       	%let nobs = %sysfunc(attrn(&data_id,NOBS));
       	%let nvar = %sysfunc(attrn(&data_id,NVARS));
       	%let rc   = %sysfunc(close(&data_id));%*** rc is just the return code of function close;
		%if (&print or &log) and ~&return %then
	 		%put &data has &nobs observation(s) and &nvar variable(s).;
   	%end;
%else
   	%put GETNOBS: %sysfunc(sysmsg());

%if &return %then
	&nobs &nvar;		%*** This statement returns the values to the outside world;

%MEND getnobs;
