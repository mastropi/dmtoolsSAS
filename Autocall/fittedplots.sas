/* MACRO %FittedPlots
Version: 	1.00
Author: 	Daniel Mastropietro
Created: 	Aug-2003
Modified: 	20-Jan-2018 (previous: 15-Feb-2016, previous: Aug-2003)

DESCRIPTION:
Plots fitted values and residuals vs. each predictor variable.
The target variable can be continuous or binary.
For the binary target case use the GROUPS= parameter to create bins of the analyzed numeric variables.

USAGE:
%FittedPlots(
	data, 			*** Input dataset with predictions created by PROC REG
	var,			*** Target + model variables
	pred=,			*** Variable containing the values predicted or fitted by the model
	res=,			*** Variable containing the residual of the model fit
	groups=)		*** If wished, number of groups in which model variables are categorized

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Categorize
- %GetNroElements
- %Means
- %RemoveFromList
- %SetSASOptions
- %SymmetricAxis
- %ResetSASOptions

NOTES:
The macro requires SAS/GRAPH.
*/
%MACRO FittedPlots(data , var , pred=pred , res=res, groups=) 
	/ des="Plots fitted values and residuals vs. predictor variables";
%local i nro_vars _var_;

%SetSASOptions;
%ExecTimeStart;

%* Variable respuesta (dicotomica);
%let resp = %scan(&var , 1 , ' ');

%* Elimino la variable respuesta de la lista;
%let var = %RemoveFromList(&var , &resp, log=0);

%let nro_vars = %GetNroElements(&var);

%* Check if the user wants a grouped plot;
%if %quote(&groups) ~= %then %do;
%*	%Categorize(&data, var=&var, groups=&groups, both=0, value=mean, varvalue=&var, out=_FittedPlots_cat_(keep=&resp &pred &res &var));
	%* DM-2016/02/15: Refactored version of %Categorize (much simpler);
	%Categorize(&data, var=&var, groups=&groups, value=mean, varstat=&var, out=_FittedPlots_cat_(keep=&resp &pred &res &var));
%end;

%* Change the format of the target/response variable in case the target is binary 0/1
%* in which case the average will also have a e.g. 1.0 format which prevents us from seeing its actual value in the graph;
proc datasets nolist;
	modify _FittedPlots_cat_;
	format &resp 10.2;
quit;

%do i = 1 %to &nro_vars;
	%let _var_ = %scan(&var , &i , ' ');

	%* Check if the user wants a grouped plot;
	%if %quote(&groups) ~= %then %do;
		%Means(_FittedPlots_cat_, by=&_var_, var=&resp &pred &res, stat=mean n, name=&resp &pred &res n_resp n_pred n_res, out=_FittedPlots_toplot_);
	%end;
	%else %do;
		%* Sorting by &_var_ (because I do a line plot below);
		proc sort data=&data out=_FittedPlots_toplot_;
			by &_var_;
		run;
	%end;

	%* Plotting;
	symbol2 interpol=join value=star;
	title "Observed and Fitted vs. %upcase(&_var_)";
	legend value=("Observed" "Predicted");
	%SymmetricAxis(_FittedPlots_toplot_ , var=&res , axis=vaxis);
	proc gplot data=_FittedPlots_toplot_;
		%* Elimino los missing en la variable respuesta porque dichas observaciones no tienen missing en
		%* la prediccion, y no quiero que en el grafico aparezcan valores predichos de observaciones
		%* que no tienen variable respuesta;
		where &resp ~= .;
		plot &resp*&_var_=1 &pred*&_var_=2 / overlay legend=legend vaxis=axis2;
		plot &res*&_var_=1 / vref=(-3.3 0 3.3) cvref="red" vaxis=&vaxis;
	run;
	quit;
	legend;
	axis2;
	title;
%end;

%* Deleting global macro variables generated;
%symdel vaxis;

proc datasets nolist;
	delete 	%if %quote(&groups) ~= %then %do; _FittedPlots_cat_ %end;
			_FittedPlots_toplot_;
quit;

%ExecTimeStop;
%ResetSASOptions;
%MEND FittedPlots;
