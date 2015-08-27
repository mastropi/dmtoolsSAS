/* MACRO %PlotBinned
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		13-Aug-2015
Modified: 		13-Aug-2015
SAS Version:	9.4

DESCRIPTION:
Makes scatter or bubble plots of a target variable in terms of a set of binned input variables
and fits a loess curve to the plot (weighted by the number of cases in each bin).

USAGE:
%PlotBinned(
	data , 					*** Input dataset.
	target=, (REQUIRED) 	*** Target variable to plot in the Y axis.
	var=_NUMERIC_, 		    *** List of input variables to analyze.
	varclass=, 				*** List of categorical input variables among those listed in VAR.
	datavartype=,			*** Dataset containing the type or level of the variables listed in VAR.
	groupsize=,				*** Nro. of cases each group should contain when categorizing continuous variables.
	groups=20,				*** Nro. of groups to use in the categorization of continuous variables.
	value=mean,				*** Name of the statistic for both the input and target variable in each bin.
	bubble=1,				*** Whether to generate a bubble plot instead of a scatter plot.
	xaxisorig=0,			*** Whether to use the original input variable range on the X axis.
	yaxisorig=1,			*** Whether to use the original target variable range on the Y axis.
	odspath=, 				*** Quoted name of the path where all generated files should be saved.
	odsfile=,				*** Quoted name of the file where the plots are saved.
	odsfiletype=pdf,		*** Type of the file specified in ODSFILE or output format.
	log=1);					*** Show messages in log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option..

- target:		Target variable containing the time to the event of interest.

OPTIONAL PARAMETERS:
- var:			List of input variables to analyze.
				default: _NUMERIC_

- varclass:		List of categorical variables to analyze among those listed in VAR.
				default: empty

- datavartype:	Dataset containing the type or level of the variables listed in VAR.
				The dataset should at least contain the following columns:
				- VAR: name of the variable whose type is given
				- LEVEL: type or level of the variable. All variables are considered
						 continuous except those with LEVEL = "categorical" (not case sensitive).
				Typically this dataset is created by the %QualifyVars macro.
				default: empty

- groupsize:	Number of cases each group or bin should contain.
				This option overrides the GROUPS parameter.
				default: empty

- groups:		Number of groups in which to categorize continuous variables for the plot.
				default: 20

- value:		Name of the statistic for both the input and target variable to use as 
				representation of each bin.
				default: mean

- bubble		Whether to generate a bubble plot instead of a scatter plot.
				default: 1

- xaxisorig		Whether to use the original input variable range on the X axis.
				default: 0

- yaxisorig		Whether to use the original target variable range on the Y axis.
				default: 1

- odspath:		Quoted name of the path containing the files where plots should be saved.
				This is only valid for HTML output.
				default: none

- odsfile:		Quoted name of the file where plots should be saved.
				default: none

- odsfiletype:	Type of the file specified in the ODSFILE= option.
				default: pdf

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes.
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Categorize
- %GetNroElements
- %MakeListFromVar
- %RemoveFromList
- %Rep
- %ResetSASOptions
- %SetSASOptions
*/

&rsubmit;
%MACRO PlotBinned(
		data,
		target=,
		var=_NUMERIC_,
		varclass=,
		datavartype=,
		exclude=,
		alltogether=0, 
		groupsize=,
		groups=20,
		value=mean,
		bubble=1,
		xaxisorig=0,
		yaxisorig=1,
		odspath=,
		odsfile=,
		odsfiletype=pdf,
		log=1,
		help=0) / store des="Makes scatter or bubble plots of a target variable vs. binned continuous variables";
/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PLOTBINNED: The macro call is as follows:;
	%put %nrstr(%PlotBinned%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put target= , (REQUIRED) %quote(   *** Target variable to plot in the Y axis.);
	%put var=_NUMERIC_, %quote(         *** List of input variables to analyze.);
	%put varclass= , %quote(            *** List of categorical input variables among those listed in VAR.);
	%put datavartype= , %quote(         *** Dataset containing the type or level of the variables listed in VAR.);
	%put groupsize= , %quote(           *** Nro. of cases each group should contain when categorizing continuous variables.);
	%put groups=3 , %quote(             *** Nro. of groups to use in the categorization of continuous variables.);
	%put value=mean , %quote(           *** Name of the statistic for both the input and target variable in each bin.);
	%put bubble=1 , %quote(             *** Whether to generate a bubble plot instead of a scatter plot.);
	%put xaxisorig=1 , %quote(          *** Whether to use the original input variable range on the X axis.);
	%put yaxisorig=1 , %quote(          *** Whether to use the original target variable range on the Y axis.);
	%put odspath= ,	%quote(		        *** Quoted name of the path where all generated files should be saved.);
	%put odsfile= ,	%quote(		        *** Quoted name of the file where the plots are saved.);
	%put odsfiletype=html, %quote(	    *** Type of the file specified in ODSFILE or output format.);
	%put log=1) %quote(                 *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var, otherRequired=%quote(&target), requiredParamNames=data target=, check=target varclass, macro=PLOTBINNED) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%local i;
%local nro_vars;
%local varlist;
%local vartype;
%local condition;
%local _var_;
%local _vartype_;
%local datetime_start;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put PLOTBINNED: Macro starts;
	%put;
	%put PLOTBINNED: Input parameters:;
	%put PLOTBINNED: - Input dataset = %quote(&data);
	%put PLOTBINNED: - target = %quote(       &target);
	%put PLOTBINNED: - var = %quote(          &var);
	%put PLOTBINNED: - varclass = %quote(     &varclass);
	%put PLOTBINNED: - datavartype = %quote(  &datavartype);
	%put PLOTBINNED: - groupsize = %quote(    &groupsize);
	%put PLOTBINNED: - groups = %quote(       &groups);
	%put PLOTBINNED: - value = %quote(        &value);
	%put PLOTBINNED: - bubble = %quote(       &bubble);
	%put PLOTBINNED: - xaxisorig = %quote(    &xaxisorig);
	%put PLOTBINNED: - yaxisorig = %quote(    &yaxisorig);
	%put PLOTBINNED: - odspath = %quote(      &odspath);
	%put PLOTBINNED: - odsfile = %quote(      &odsfile);
	%put PLOTBINNED: - odsfiletype = %quote(  &odsfiletype);
	%put PLOTBINNED: - log = %quote(          &log);
	%put;
%end;

%SetSASOptions;

%* Keep track of total exceution time;
%* Ref: http://www.sascommunity.org/wiki/Tips:Program_run_time;
%let datetime_start = %sysfunc(DATETIME()) ;

%if %quote(&odsfile) ~= %then %do;
	%if %upcase(%quote(&odsfiletype)) = HTML and %quote(&odspath) ~= %then %do;
		%* This distinction of HTML output is necessary because this is the only format that accepts the PATH= option...;
		%* (the reason being that the HTML output stores graphs in separate files (e.g. PNG files that are linked to the HTML output);
		ods &odsfiletype path=&odspath file=&odsfile style=statistical;
	%end;
	%else %do;
		ods &odsfiletype file=&odsfile style=statistical;
	%end;
%end;

/*--------------------------------- Parse input parameters -----------------------------------*/
%*** DATAVARTYPE=;
%if %quote(&datavartype) ~= %then %do;
	%* Read the variable type or level (continuous categorical) from the dataset given here.
	%* (typically generated by the %QualifyVars macro or also manually generated by the user);
	%* The variable type or level should be stored in a column called LEVEL and the variable name
	%* should be stored in a column called VAR;
	data _PB_vartypes_(keep=var level);
		set &datavartype;
		where upcase(level) = "CATEGORICAL";
	run;
	%let varclass = %MakeListFromVar(_PB_vartypes_, var=var, log=0);
	%* Keep just the categorical variables that also appear in VAR;
	%* NOTE that I cannot subset the dataset above to the variables appearing in VAR because the
	%* when using the %MakeList macro to generate the list of variable names to search for
	%* SAS gives an error in the WHERE statement that is completely NONSENSE!! as the WHERE statement
	%* is perfectly well constructed!!;
	%let varclass = %KeepInList(&varclass, &var, log=0);
%end;

%*** VARCLASS=;
%* Remove categorical variables from VAR;
%if %quote(&varclass) ~= %then
	%let var = %RemoveFromList(&var, &varclass, log=0);

%*** EXCLUDE=;
%let condition = not in (&exclude);
/*--------------------------------- Parse input parameters -----------------------------------*/

%*** Prepare data;
%if %quote(&var) ~= %then %do;
	%put PLOTBINNED: Categorizing continuous variables...;
	%Categorize(&data, var=&var, condition=&condition, alltogether=&alltogether, groupsize=&groupsize, groups=&groups, both=0, value=&value, varvalue=&var, out=_PB_data_(keep=&target &var &varclass), log=0);
%end;
%else %do;
	data _PB_data_(keep=&target &varclass);
		set &data;
	run;
%end;

%* Restate the list of variables to analyze to the original list of variables (i.e. including the categorical variables);
%let vartype = %Rep(N, %GetNroElements(&var)) %Rep(C, %GetNroElements(&varclass));
%let var = &var &varclass;

%* Compute min and max values of the target variable;
%if &xaxisorig or &yaxisorig %then %do;
	%* Read the min and max of the input and target variables from the original data;
	%GetStat(_PB_data_, var=&var &target, stat=min, name=%MakeList(&var, suffix=_MIN) _TARGET_MIN_, log=0);
	%GetStat(_PB_data_, var=&var &target, stat=max, name=%MakeList(&var, suffix=_MAX) _TARGET_MAX_, log=0);
%end;

%*** Iterate on each input variable;
%let nro_vars = %GetNroElements(&var);
%do i = 1 %to &nro_vars;
	%let _var_ = %scan(&var, &i , ' ');
	%let _vartype_ = %scan(&vartype, &i, ' ');
	%if &log %then %do;
		%if &_vartype_ = C %then
			%put PLOTBINNED: Plotting %upcase(&target) vs. (categorical) variable &i of &nro_vars: %upcase(&_var_)...;
		%else
			%put PLOTBINNED: Plotting %upcase(&target) vs. &groups bins of (continuous) variable &i of &nro_vars: %upcase(&_var_)...;
	%end;
	%Means(_PB_data_, by=&_var_, var=&target, stat=&value n, name=&target _n_, out=_PB_means_, log=0);

	%if ~&yaxisorig %then %do;
		%* Read the min and max of the target variable from the aggregated data;
		%GetStat(_PB_means_, var=&target, stat=min, name=_TARGET_MIN_, log=0);
		%GetStat(_PB_means_, var=&target, stat=max, name=_TARGET_MAX_, log=0);
	%end;
	ods proclabel="%upcase(&_VAR_)";
	title "Bin plot of %upcase(&TARGET) vs. %upcase(&_VAR_)";
	proc sgplot data=_PB_means_;
		%*** BUBBLE or SCATTER;
		%if &bubble %then %do;
		bubble x=&_var_ y=&target size=_n_ / datalabel=_n_;
		%end;
		%else %do;
		scatter x=&_var_ y=&target / datalabel=_n_ markerattrs=(symbol=CircleFilled);
		%end;

		%*** CATEGORICAL or CONTINUOUS;
		%if &_vartype_ = C %then %do;
		%* Linear interpolation for categorical variables;
		series x=&_var_ y=&target / lineattrs=(color="red");
		%end;
		%else %do;
		%* LOESS curve for continuous variables;
		loess x=&_var_ y=&target  / weight=_N_ 
									lineattrs=(color=red) interpolation=cubic
									CLM clmattrs=(clmfillattrs=(color="light grayish red")) clmtransparency=0.7;
		%end;

		%*** AXIS LIMITS;
		%* Set horizontal axis to reflect the original input variable scale;
		%if &xaxisorig %then %do;
		xaxis min=&&&_var_._MIN max=&&&_var_._MAX;
		%end;
		%* Set common vertical axis limits;
		yaxis min=&_TARGET_MIN_ max=&_TARGET_MAX_;
	run;
	title;
%end;
%* Close the ODS output;
%if %quote(&odsfile) ~= %then %do; 
ods &odsfiletype close;
%end;

proc datasets nolist;
	delete  _PB_data_
			_PB_means_
			%if %quote(&datavartype) ~= %then %do;
			_PB_vartypes_
			%end;
			;
quit;

%* Delete global macro variables created here;
%symdel _TARGET_MIN_ _TARGET_MAX_;
%if &xaxisorig or &yaxisorig %then
	%symdel %MakeList(&var, suffix=_MIN) %MakeList(&var, suffix=_MAX);

%if &log %then %do;
	%put;
	%put PLOTBINNED: Macro ends.;
	%put;
%end;

%let datetime_end = %sysfunc(DATETIME());
%put *** START TIME: %quote(   %sysfunc(putn(&datetime_start, datetime20.)));
%put *** END TIME: %quote(     %sysfunc(datetime(), datetime20.));
%put *** EXECUTION TIME: %sysfunc(putn(%sysevalf(&datetime_end - &datetime_start.), hhmm8.2)) (hh:mm);

%ResetSASOptions;

%end;
%MEND PlotBinned;
