/* MACRO %Transpose
Version: 1.01
Author: Daniel Mastropietro
Created: 25-May-04
Modified: 12-Jan-05

DESCRIPTION:
Transposes a set of variables using the values of an ID variable to define 
the number and names of the transposed variables.
The resulting output dataset has only ONE observation for each combination
of BY variables.
This is what makes the difference between the macro %Transpose and PROC TRANSPOSE.
That is, PROC TRANSPOSE creates as many observations as combinations of the
BY variables exist, while %Transpose creates only one observation for each
combination of BY variables.

USAGE:
%Transpose(
	data ,					*** Input dataset (required)
	var=_ALL_ ,				*** List of variables to transpose
	out= ,					*** Output dataset
	by= ,					*** List of BY variables
	id= ,					*** ID variable (only one is allowed)
	copy= ,					*** List of variables to COPY
	name= ,					*** Name for the transposed variables
	prefix= ,				*** PREFIX= option of PROC TRANSPOSE
	log=1);					*** Show messages in log?
 
REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option.

OPTIONAL PARAMETERS:
- var:			Blank-separated list of variables to transpose.
				default: _numeric_, es decir todas las variables numéricas

- out:			Output dataset. Data options can be specified as in a data= SAS option.
				It consists of the following variables:
				- BY variables
				- COPY variables
				- Transpose of the variables listed in the VAR option for each
				value of the ID variable in each combination of BY variables.
				The names used for the transposed variables coming from the same
				input variable is made up of: the input variable name, the PREFIX,
				and the corresponding value of the ID variable.

				The output dataset is sorted by the BY variables.	

- by:			List of BY variables. Transposition is performed for each combination
				of BY variables.

- id:			ID variable. It is used in an ID statement of the PROC TRANSPOSE called
				to perform the transposition.
				Its values are used to distinguish the columns in the transposed dataset
				coming from a common variable.
				The following restrictions apply:
				- Only one variable can be listed.
				- Only one occurrence of each value of the id variable is allowed
				for each by variables combination.

- copy:			List of variables to COPY to the transposed dataset.
				It is assumed that the values of the COPY variables are the same
				for each combination of BY variables.

- name:			List of names to use for the transposed variables.
				If no value is passed the name of the transposing variable is used.
				It must have the same number of elements as the number of variables
				being transposed (as listed in the VAR option).

- prefix:		Prefix to use for each transposed variable name.
				It is used in the PREFIX= option of PROC TRANSPOSE, so that this
				prefix comes soon after the name used for the transposed variable
				(either given by the name of the transposing variable or by the name
				specified in the NAME option), and before the value of the transposing variable
				that uniquely identifies the different transposed variables.

- log:			Indicates whether to show messages in the log.
				Possible values: 0 => No, 1 => Yes.
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %CheckInputParameters
- %GetDataOptions
- %Getnobs
- %GetNroElements
- %GetVarList
- %MakeList
- %RemoveFromList

NOTES:
If there are missing values in the ID variable, the corresponding observation is
ommited from the transposed dataset.

EXAMPLES:
1.- %Transpose(test, var=x y z, by=group client, id=mth, prefix=5_, out=test_t);
This transposes variables X, Y and Z in dataset TEST by each combination of by variables
GROUP-CLIENT. The names of the transposed variables are constructed by putting
together (a) the variable name, (b) the string '5_', and (c) the value of variable MTH,
which is used as index.

For example, if MTH can take values 1, 2 and 3, the transposed variables corresponding to
variable X are named X5_1, X5_2, X5_3.

Dataset TEST_T is created with the transposed variables, and has one record per GROUP-CLIENT
combination.

2.- %Transpose(test, var=x y z, by=group client, id=mth, name=u v w, prefix=5_, out=test_t);
Same as Example 1 but now the names of the transposed variables are changed to U, V and W,
as if the names of the variables being transposed were U, V and W, instead of X, Y and Z.

APPLICATIONS:
1.- Useful to transpose monthly data of different individuals (one record per month)
into a dataset with the historical data in one row for each individual.
*/
%MACRO Transpose(data, var=_ALL_, out=, by=, id=, copy=, name=, prefix=, log=1, help=0) 
	/ des="Transposes a set of variables in a dataset";
%local byst _data_ j _name_ nro_vars _var_;
%local error;		%* Flag for an error in the input parameters;
%local nobs nvar;


/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put TRANSPOSE: The macro call is as follows:;
	%put %nrstr(%Transpose%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put var=_ALL_ , %quote(            *** List of variables to transpose);
	%put out= , %quote(                 *** Output dataset);
	%put by= , %quote(                  *** List of BY variables);
	%put id= , %quote(                  *** ID variable -- only one is allowed);
	%put copy= , %quote(                *** List of variables to COPY);
	%put prefix= , %quote(              *** Prefix to use for transposed variable names);
	%put log=1) %quote(                 *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var , macro=TRANSPOSE) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%SetSASOptions;

/*----- Parsing input parameters -----*/
%let error = 0;

%* DATA=;
%* Execute data options passed in &data;
data _Transpose_data_;
	set &data;
run;
%let _data_ = _Transpose_data_;

%* VAR=;
%let var = %GetVarList(&_data_, var=&var, log=0);
%* Remove from &var the variables listed in &by and &id, because otherwise the
%* transposition would be inconsistent;
%let var = %RemoveFromList(&var, &by &id, log=0);
%let nro_vars = %GetNroElements(&var);

%* BY=;
%let byst =;
%if %quote(&by) ~= %then
	%let byst = by &by;

%* ID=;
%let idst =;
%if %GetNroElements(&id) > 1 %then %do;
	%put TRANSPOSE: ERROR - The number of ID variables must be at most 1.;
	%let error = 1;
%end;
%else %if %quote(&id) ~= %then
	%let idst = id &id;

%* NAME=;
%if %quote(&name) ~= %then %do;
	%if %GetNroElements(&name) ~= %GetNroElements(&var) %then %do;
		%put TRANSPOSE: ERROR - The number of names listed in NAME= must be equal to;
		%put TRANSPOSE: the number of variables listed in VAR=;
		%let error = 1;
	%end;
%end;

%* OUT=;
%if %quote(&out) = %then %do;
	%let out = _Transpose_out_;
	%let out_name = &out;
%end;
%else
	%let out_name = %scan(&out, 1, '(');
/*----- END Parsing input parameters -----*/

%if ~&error %then %do;
%* Sort by &by variables;
%if %quote(&byst) ~= %then %do;
	proc sort data=&_data_ out=_Transpose_dataSorted_;
		&byst;
	run;
	%let _data_ = _Transpose_dataSorted_;
%end;

%do j = 1 %to &nro_vars;
	%let _var_ = %scan(&var, &j, ' ');
	%if %quote(&name) ~= %then
		%let _name_ = %scan(&name, &j, ' ');
	%else
		%let _name_ = &_var_;
	proc transpose data=&_data_ out=_Transpose_out_&j(drop=_NAME_) prefix=&_name_&prefix;
		&byst;
		&idst;
		var &_var_;
	run;
	%if &j = 1 %then %do;
		data &out_name;
			set _Transpose_out_&j;
		run;
	%end;
	%else %do;
		data &out_name;
			merge &out_name _Transpose_out_&j;
			&byst;
		run;
	%end;
%end;

/* Adding variables to be copied. It is assumed that the variables to copy have all the
same value for each by variable combination. Thus the value of the first ocurrence of the
by variables is copied to the output dataset. */
%if %quote(&copy) ~= %then %do;
	data &out;
		merge &out_name &_data_(keep=&by &copy);
		&byst;
		%* Check for first occurrence of by variable combination;
		if %MakeList(&by, prefix=first., sep=%quote( and )) then
			output;
	run;
%end;
%* Execute the options coming with the output dataset;
%* (Note that I only do this when COPY= is empty, because otherwise the options were
%* already executed inside the above IF);
%else %if %GetDataOptions(&out) ~= %then %do;
	data &out;
		set &out_name;
	run;
%end;

%* Show message about creation of output dataset;
%if &log %then %do;
	%callmacro(getnobs, &out_name return=1, nobs nvar);
	%put;
	%put TRANSPOSE: Dataset with transposed variables (%upcase(&out_name)) created.;
	%put TRANSPOSE: The data set %upcase(&out_name) has &nobs observations and &nvar variables.;
	%put;
%end;

proc datasets nolist;
	delete 	_Transpose_data_
			_Transpose_dataSorted_;
	%do j = 1 %to &nro_vars;
		delete _Transpose_out_&j;
	%end;
	%if %quote(&out_name) ~= _Transpose_out_ %then %do;
		delete _Transpose_out_;
	%end;
quit;
%end;		%* %if ~&error;

%ResetSASOptions;
%end;	%* if ~%CheckInputParameters;
%MEND Transpose;
