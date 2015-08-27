/* Checks if something exists in a dataset.
Looks for 'value' under column 'colname' in dataset 'data', and returns the value 1
if the value is found. Otherwise, it returns the value 0.

NOTE: I don't use any PROCedure to look for 'value' for two reasons:
- Have the macro return a number indicating whether 'value' was found or not.
- Be able to call the macro from anywhere, such as PROC IML.
*/
&rsubmit;
%MACRO Exist(data , colname , value) / store des="Returns 1 if a value exists in a given variable of a dataset, 0 otherwise";
%local dsid exist i obs rc val;

%let dsid = %sysfunc(open(&data));				%*** Open dataset &data;
%if ~&dsid %then
   	%put EXIST: %sysfunc(sysmsg());
%else %do;
	%let varnum = %sysfunc(varnum(&dsid , &colname));	%*** Finds out the column number of &colname;
	%if &varnum = 0 %then
		%put EXIST: ERROR - The column &colname does not exist in &data dataset. The macro will stop executing.; 
	%else %do;
		%let vartype = %sysfunc(vartype(&dsid , &varnum));	%*** Type of variable in column &varnum. Either C or N;
		%let i = 0;
		%let exist = 0;
		%do %until(&obs = -1);
			%let i = %eval(&i + 1);						%*** Observation number;
			%let obs = %sysfunc(fetchobs(&dsid , &i));	%*** Reads observation &i. Returns -1 if EOF;
			%if %upcase(&vartype) = C %then
				%let val = %sysfunc(getvarc(&dsid , &varnum));	%*** Get the character value of column &num;
			%else
				%let val = %sysfunc(getvarn(&dsid , &varnum));	%*** Get the numeric value of column &num;
		
			%if %upcase(&val) = %upcase(&value) %then %do;
				%let obs = -1;
				%let exist = 1;
			%end;
		%end;
		%let rc = %sysfunc(close(&dsid));
		&exist
	%end;
%end;
%MEND Exist;
