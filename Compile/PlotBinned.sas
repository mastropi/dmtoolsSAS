/* MACRO %PlotBinned
Version: 		1.06
Author: 		Daniel Mastropietro
Created: 		13-Aug-2015
Modified: 		28-Oct-2015 (previous: 01-Oct-2015)
SAS Version:	9.4

DESCRIPTION:
Makes scatter or bubble plots of a target variable in terms of a set of binned input variables
and fits a loess curve to the plot (weighted by the number of cases in each bin).

USAGE:
%PlotBinned(
	data , 						*** Input dataset.
	target=, (REQUIRED) 		*** Target variable to plot in the Y axis.
	var=_NUMERIC_,				*** List of input variables to analyze.
	varclass=, 					*** List of categorical input variables among those listed in VAR.
	by=,						*** BY variables.
	datavartype=,				*** Dataset containing the type or level of the variables listed in VAR.
	valuesLetAlone=,			*** List of values taken by the analyzed variable to treat as separate bins.
	alltogether=0,				*** Whether the let-alone values should be put into the same bin.
	groupsize=,					*** Nro. of cases each group should contain when categorizing continuous variables.
	groups=20,					*** Nro. of groups to use in the categorization of continuous variables.
	value=mean,					*** Name of the statistic for both the input and target variable in each bin.
	plot=1,						*** Whether to generate the binned plots.
	out=,						*** Output dataset with the data needed to reproduce the plots.
	outcorr=,					*** Output dataset containing the correlation between the binned vs. predicted LOESS values.
	bubble=1,					*** Whether to generate a bubble plot instead of a scatter plot.
	xaxisorig=0,				*** Whether to use the original input variable range on the X axis.
	yaxisorig=1,				*** Whether to use the original target variable range on the Y axis.
	odspath=, 					*** Quoted name of the path where all generated files should be saved.
	odsfile=,					*** Quoted name of the file where the plots are saved.
	odsfiletype=pdf,			*** Type of the file specified in ODSFILE or output format.
	imagerootname=PlotBinned,	*** Root name to be used for the image file name generated by ODS graphics.
	log=1);						*** Show messages in log?

REQUIRED PARAMETERS:
- data:				Input dataset. Data options can be specified as in a data= SAS option.

- target:			Target variable containing the time to the event of interest.

OPTIONAL PARAMETERS:
- var:				List of input variables to analyze.
					default: _NUMERIC_

- varclass:			List of categorical variables to analyze among those listed in VAR.
					default: empty

- by:				BY variables.
					default: empty

- datavartype:		Dataset containing the type or level of the variables listed in VAR.
					The dataset should at least contain the following columns:
					- VAR: name of the variable whose type is given
					- LEVEL: type or level of the variable. All variables are considered
							 continuous except those with LEVEL = "categorical" (not case sensitive).
					Typically this dataset is created by the %QualifyVars macro.
					default: empty

- valuesLetAlone:	List of values taken by the analyzed variable to treat as separate bins.
					The values should be separated by commas.
					Ex: valuesLetAlone=%quote(0, 1)
					default: empty

- alltogether		Whether the let-alone values listed in VALUESLETALONE= should be put into the same bin.
					Possible values: 0 => No (put each value into a separate bin)
								 	 1 => Yes (put all let-alone values into the same bin. In this case
											the representative value of the bin will be based on the
											statistic specified in VALUE= weighted by the number of
											cases in each value to let alone)
					default: 0

- groupsize:		Number of cases each group or bin should contain.
					This option overrides the GROUPS parameter.
					default: empty

- groups:			Number of groups in which to categorize continuous variables for the plot.
					default: 20

- value:			Name of the statistic for both the input and target variable to use as 
					representation of each bin.
					default: mean

- plot:				Whether to generate the binned plots or just the output dataset
					needed to generate the plots (if parameter OUT is non empty of course).
					Possible values: 0 => No, 1 => Yes.
					default: 1

- out:				Output dataset with the data needed to reproduce the plots.
					Data options can be specified as in a data= SAS option.
					The dataset contains the following columns:
					- VAR: Input variable name
					- VALUE: Value representing each bin
					- NOBS: Number of cases in each bin
					- <TARGET>: Value of the target variable in each bin
					- FIT_LOESS_LOW: Lower limit of the 95% confidence interval for the predicted value
					- FIT_LOESS: LOESS fit in each bin
					- FIT_LOESS_UPP: Upper limit of the 95% confidence interval for the predicted value
					default: no output dataset is created

- outcorr:			Output dataset containing the correlation between binned values and
					predicted LOESS values by analyzed variable.
					Data options can be specified as in a data= SAS option.
					The dataset contains the following columns:
					- VAR: Input variable name
					- N: Number of bins on which the correlation is computed
					- CORR: Weighted (by N) correlation between binned values and predicted LOESS values
					- CORR_ADJ: Normalized weighted correlation by the target variable range
					- TARGET_RANGE: Target variable range in the original data
					default: no output dataset is created

- bubble			Whether to generate a bubble plot instead of a scatter plot.
					default: 1

- xaxisorig			Whether to use the original input variable range on the X axis.
					default: 0

- yaxisorig			Whether to use the original target variable range on the Y axis.
					default: 1

- odspath:			Quoted name of the path containing the files where plots should be saved.
					This is only valid for HTML output.
					default: none

- odsfile:			Quoted name of the file where plots should be saved.
					default: none

- odsfiletype:		Type of the file specified in the ODSFILE= option.
					default: pdf

- imagerootname:	Root name to be used for the image file name generated by ODS graphics.
					Each plot is stored in a file named as <imagerootname>-<TARGET>-<K>-<VAR> where
					<K> and <VAR> are respectively the number and name of the currently analyzed variable
					in the order they are passed to the VAR= parameter.
					default: PlotBinned

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes.
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Categorize
- %ExecTimeStart
- %ExecTimeStop
- %GetNroElements
- %GetVarLabel
- %MakeListFromName
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
		by=,
		datavartype=,
		valuesLetAlone=,
		alltogether=0, 
		groupsize=,
		groups=20,
		value=mean,
		out=,
		outcorr=,
		plot=1,
		bubble=1,
		xaxisorig=0,
		yaxisorig=1,
		odspath=,
		odsfile=,
		odsfiletype=pdf,
		imagerootname=PlotBinned,
		log=1,
		help=0) / store des="Makes scatter or bubble plots of a target variable vs. binned continuous variables";
/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PLOTBINNED: The macro call is as follows:;
	%put %nrstr(%PlotBinned%();
	%put data , (REQUIRED) %quote(         *** Input dataset.);
	%put target= , (REQUIRED) %quote(      *** Target variable to plot in the Y axis.);
	%put var=_NUMERIC_, %quote(            *** List of input variables to analyze.);
	%put varclass= , %quote(               *** List of categorical input variables among those listed in VAR.);
	%put by= , %quote(                     *** BY variables.);
	%put datavartype= , %quote(            *** Dataset containing the type or level of the variables listed in VAR.);
	%put valuesLetAlone= ,	%quote(        *** List of values taken by the analyzed variable to treat as separate bins.);
	%put alltogether=0 , %quote(           *** Whether the let-alone values should be put into the same bin.);
	%put groupsize= , %quote(              *** Nro. of cases each group should contain when categorizing continuous variables.);
	%put groups=3 , %quote(                *** Nro. of groups to use in the categorization of continuous variables.);
	%put value=mean , %quote(              *** Name of the statistic for both the input and target variable in each bin.);
	%put plot=1 , %quote(                  *** Whether to generate the binned plots.);
	%put out= , %quote(                    *** Output dataset with the data needed to reproduce the plots.);
	%put outcorr= , %quote(                *** Output dataset containing the correlation between binned and predicted LOESS values.);
	%put bubble=1 , %quote(                *** Whether to generate a bubble plot instead of a scatter plot.);
	%put xaxisorig=1 , %quote(             *** Whether to use the original input variable range on the X axis.);
	%put yaxisorig=1 , %quote(             *** Whether to use the original target variable range on the Y axis.);
	%put odspath= ,	%quote(		           *** Quoted name of the path where all generated files should be saved.);
	%put odsfile= ,	%quote(		           *** Quoted name of the file where the plots are saved.);
	%put odsfiletype=pdf, %quote(	       *** Type of the file specified in ODSFILE or output format.);
	%put imagerootname=PlotBinned , %quote(*** Root name to be used for the image file name generated by ODS graphics.);
	%put log=1) %quote(                    *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
/* THE FOLLOWING CHECK DOES NOT WORK WHEN THE INPUT DATASET HAS DATA OPTIONS! as it says that parameter DATA was not passed... WHY?? */
/*%else %if ~%CheckInputParameters(data=&data , var=&var, otherRequired=%quote(&target), requiredParamNames=data target=, check=target varclass, macro=PLOTBINNED) %then %do;*/
/*	%ShowMacroCall;*/
/*%end;*/
/*%else %do;*/
/************************************* MACRO STARTS ******************************************/
%local bystr;
%local i;
%local nro_vars;
%local varlist;
%local vartype;
%local condition;
%local maxlengthlabel;
%local _label_;
%local _var_;
%local _vartype_;
%local nobs nvars;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put PLOTBINNED: Macro starts;
	%put;
	%put PLOTBINNED: Input parameters:;
	%put PLOTBINNED: - Input dataset = %quote( &data);
	%put PLOTBINNED: - target = %quote(        &target);
	%put PLOTBINNED: - var = %quote(           &var);
	%put PLOTBINNED: - varclass = %quote(      &varclass);
	%put PLOTBINNED: - by = %quote(            &by);
	%put PLOTBINNED: - datavartype = %quote(   &datavartype);
	%put PLOTBINNED: - valuesLetAlone = %quote(&valuesLetAlone);
	%put PLOTBINNED: - alltogether = %quote(   &alltogether);
	%put PLOTBINNED: - groupsize = %quote(     &groupsize);
	%put PLOTBINNED: - groups = %quote(        &groups);
	%put PLOTBINNED: - value = %quote(         &value);
	%put PLOTBINNED: - plot = %quote(          &plot);
	%put PLOTBINNED: - out = %quote(           &out);
	%put PLOTBINNED: - outcorr = %quote(       &outcorr);
	%put PLOTBINNED: - bubble = %quote(        &bubble);
	%put PLOTBINNED: - xaxisorig = %quote(     &xaxisorig);
	%put PLOTBINNED: - yaxisorig = %quote(     &yaxisorig);
	%put PLOTBINNED: - odspath = %quote(       &odspath);
	%put PLOTBINNED: - odsfile = %quote(       &odsfile);
	%put PLOTBINNED: - odsfiletype = %quote(   &odsfiletype);
	%put PLOTBINNED: - imagerootname = %quote( &imagerootname);
	%put PLOTBINNED: - log = %quote(           &log);
	%put;
%end;

%SetSASOptions(varlenchk=nowarn);	%* Set the VARLENCHECK= option to NOWARN in order to avoid a warning message when the length of the LABEL variable is shortened in this macro;
%ExecTimeStart;
%if &plot %then %do;
	%ODSOutputOpen(&odspath, &odsfile, odsfiletype=&odsfiletype, macro=PLOTBINNED, log=&log);
%end;

/*--------------------------------- Parse input parameters -----------------------------------*/
%*** BY=;
%let bystr = ;
%if %quote(&by) ~= %then
	%let bystr = by &by;

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
	%* NOTE that I cannot subset the dataset above to the variables appearing in VAR because
	%* when using the %MakeListFromVar macro to generate the list of variable names to search for
	%* SAS gives an error in the WHERE statement stating that it is flawed, that is completely NONSENSE!!
	%* as the WHERE statement is perfectly well constructed!!;
	%let varclass = %KeepInList(&varclass, &var, log=0);
%end;

%*** VARCLASS=;
%* Remove categorical variables from VAR;
%if %quote(&varclass) ~= %then
	%let var = %RemoveFromList(&var, &varclass, log=0);

%*** VALUESLETALONE=;
%let condition = ;
%if %quote(&valuesLetAlone) ~= %then
	%let condition = not in (&valuesLetAlone);

%*** OUT=;
%* Delete local output dataset because data is appended to it;
proc datasets nolist;
	delete _PB_out_;
quit;
/*--------------------------------- Parse input parameters -----------------------------------*/

%*** Prepare data;
%if %quote(&var) ~= %then %do;
	%if &log %then
		%put PLOTBINNED: Categorizing continuous variables...;
	%Categorize(&data, by=&by, var=&var, condition=&condition, alltogether=&alltogether, groupsize=&groupsize, groups=&groups, both=0, value=&value, varvalue=&var, out=_PB_data_(keep=&by &target &var &varclass), log=0);
	%if &log %then
		%put;
%end;
%else %do;
	data _PB_data_(keep=&by &target &varclass);
		set &data;
	run;
%end;

%* Restate the list of variables to analyze to the original list of variables (i.e. including the categorical variables);
%let vartype = %Rep(N, %GetNroElements(&var)) %Rep(C, %GetNroElements(&varclass));
%let var = &var &varclass;
%let nro_vars = %GetNroElements(&var);

%if &xaxisorig or &yaxisorig %then %do;
	%* Read the MIN and MAX values of the input and target variables from the original data;
	%* Note that I store the MIN and MAX of the input variables into macro variables named _VAR1_MIN, _VAR2_MIN, etc.
	%* in order to avoid problems with too long names (the limit of 32 characters also applies to the macro variable names!!);
	%GetStat(_PB_data_, var=&var &target, stat=min, name=%MakeListFromName(_VAR, start=1, stop=&nro_vars, step=1, suffix=_MIN) _TARGET_MIN_, log=0);
	%GetStat(_PB_data_, var=&var &target, stat=max, name=%MakeListFromName(_VAR, start=1, stop=&nro_vars, step=1, suffix=_MAX) _TARGET_MAX_, log=0);
%end;

%*** Iterate on each input variable;
%let maxlengthlabel = 0;
%do i = 1 %to &nro_vars;
	%let _var_ = %scan(&var, &i , ' ');
	%let _vartype_ = %scan(&vartype, &i, ' ');
	%if &log %then %do;
		%if &_vartype_ = C %then
			%put PLOTBINNED: Computing plot of %upcase(&target) vs. (categorical) variable &i of &nro_vars: %upcase(&_var_);
		%else
			%put PLOTBINNED: Computing plot of %upcase(&target) vs. binned (continuous) variable &i of &nro_vars: %upcase(&_var_);
	%end;
	%Means(_PB_data_, by=&by &_var_, var=&target, stat=&value n, name=&target nobs, out=_PB_means_, log=0);

	%* Read the variable label;
	%let _label_ = %GetVarLabel(_PB_data_, &_var_);
	%let maxlengthlabel = %sysfunc(max(&maxlengthlabel, %length(%quote(&_label_))));

	%* Add the variable information;
	data _PB_means_;
		%if %quote(&by) ~= %then %do;
		format &by;
		%end;
		length var $32 label $500;	%* Use 500 as label length to be kind of safe that we do not truncate any labels;
		set _PB_means_;
		var = "&_var_";
		label = "%quote(&_label_)";
	run;

	%* Compute the fitted loess;
	ods exclude all;	%* Avoid showing any output in any of the active outputs;
	proc loess data=_PB_means_ plots=none;
		%* NOTE: The options of the MODEL statement request to do a global search for the best smoothing parameter
		%* on the default range (interval (0,1]). The AICC criterion is used instead of GCV because it is 
		%* more modern and more robust. We could also use a variation of it AICC1, in order ot improve the
		%* undersmoothing sometimes observed with AICC. For more info, see the SAS documentation.
		%* Note that the default range is (0, 1] because the smoothing parameter in the LOESS context represents
		%* the proportion of data that is used at each local regression around an X point where X is the input vector.
		%* For more info see: http://www.ats.ucla.edu/stat/sas/library/loesssugi.pdf;
		%* THIS IS IMPORTANT BECAUSE OTHERWISE THE LOESS FIT OF THE PLOT MAY BE VERY DIFFERENT FROM THE LOESS FIT HERE;
		&bystr;
		model &target = &_var_ / select=aicc(global);
		weight nobs;
		output 	out=_PB_means_(keep=&by var label &_var_ nobs &target fit_loess fit_loess_low fit_loess_upp)
				predicted=fit_loess LCLM=fit_loess_low UCLM=fit_loess_upp;
	run;
	ods exclude none;
	%* Append the plotted data to the output dataset;
	proc append base=_PB_out_ data=_PB_means_(rename=(&_var_=value));
	run;
	
	%if &plot %then %do;
		%if ~&yaxisorig %then %do;
			%* Read the min and max of the target variable from the aggregated data;
			%GetStat(_PB_means_, var=&target, stat=min, name=_TARGET_MIN_, log=0);
			%GetStat(_PB_means_, var=&target, stat=max, name=_TARGET_MAX_, log=0);
		%end;
		ods proclabel="%upcase(&_VAR_)";	%* This adds a title to each entry in an e.g. PDF file that helps in browsing;
		ods graphics / imagename="&imagerootname-&target-&i-&_var_" reset=index;	%* This generates the image file with the name specified in the IMAGENAME= option;
		title "Bin plot of %upcase(&TARGET) vs. %upcase(&_VAR_)";
		proc sgplot data=_PB_means_;
			%*** BUBBLE or SCATTER;
			%if &bubble %then %do;
			bubble x=&_var_ y=&target size=nobs / %if %quote(&by) ~= %then %do; group=&by %end;
												  datalabel=nobs;
			%end;
			%else %do;
			scatter x=&_var_ y=&target / %if %quote(&by) ~= %then %do; group=&by %end;
										 datalabel=nobs markerattrs=(symbol=CircleFilled);
			%end;

			%*** CATEGORICAL or CONTINUOUS;
			%if &_vartype_ = C %then %do;
			%* Linear interpolation for categorical variables;
			series x=&_var_ y=&target / %if %quote(&by) ~= %then %do; group=&by %end;
										%else %do; lineattrs=(color="red") %end;		;
			%end;
			%else %do;
			%* LOESS curve for continuous variables;
			loess x=&_var_ y=&target  / %if %quote(&by) ~= %then %do; group=&by %end;
										%else %do;
											lineattrs=(color="red")
											CLM clmattrs=(clmfillattrs=(color="light grayish red")) clmtransparency=0.7
										%end;
										weight=nobs 
										interpolation=cubic
										;
			%end;

			%*** AXIS LIMITS;
			%* Set horizontal axis to reflect the original input variable scale;
			%if &xaxisorig %then %do;
			xaxis min=&&&_var&i._MIN max=&&&_var&i._MAX;
			%end;
			%* Set common vertical axis limits;
			yaxis min=&_TARGET_MIN_ max=&_TARGET_MAX_;
		run;
		title;
	%end;
%end;

%if &plot %then %do;
	%ODSOutputClose(&odsfile, odsfiletype=&odsfiletype, macro=PLOTBINNED, log=&log);
	ods graphics / reset=all;
%end;

%if %quote(&out) ~= %then %do;
	data &out;
		%if %quote(&by) ~= %then %do;
		format &by;
		%end;
		format var $32. label $&maxlengthlabel..;
		format value BEST8.;	%* This format is to make sure that values are not shown as integer values when there are integer-valued analysis variables;
		format nobs &target;
		format fit_loess_low fit_loess fit_loess_upp;
		%* Set the final length of the label variable;
		length label $&maxlengthlabel;
		set _PB_out_;
		label 	value = " "
				nobs = " "
				fit_loess_low = "Lower Limit of 95% Confidence Band for Loess Fit"
				fit_loess = "Weighted Loess Fit"
				fit_loess_upp = "Upper Limit of 95% Confidence Band for Loess Fit";
	run;
	%if &log %then %do;
		%callmacro(getnobs, _PB_out_ return=1, nobs nvars);
		%put;
		%put PLOTBINNED: Dataset %upcase(&out) created with &nobs observations and &nvars variables;
		%put PLOTBINNED: with the data that can be used to reproduce the plots.;
	%end;
%end;

%*** Output dataset containing the correlation between the observed binned values and the predicted LOESS values;
%if %quote(&outcorr) ~= %then %do;
	%* Compute the range of the target variable in the original data to be used for the normalized correlation calculation
	%* which can be used as a measure of predictive power of the target by each input variable;
	%GetStat(_PB_data_, var=&target, stat=range, name=_TARGET_RANGE_, log=0);

	%*** Compute the correlation between the observed and predicted LOESS values;
	proc sort data=_PB_out_;
		by &by var value;
	run;
	proc corr data=_PB_out_ out=_PB_corr_ noprint;
		by &by var label;
		var &target;
		with fit_loess;
		%* Use the same weight as for the LOESS fit;
		weight nobs;
	run;
	%* Transpose;
	proc transpose data=_PB_corr_ out=_PB_corr_(keep=&by var label n corr);
		where _TYPE_ in ("N", "CORR");
		by &by var label;
		id _TYPE_;
		var &target;
	run;

	%* Compute the range of the target variable so that the input variable spanning a larger range of the target variable
	%* would be considered to be more predictive of the target variable;
	%* The span of the target variable range is then measured as a percentage of its original range;
	proc means data=_PB_out_ range noprint;
		by &by var;
		var &target;
		output out=_PB_range_ range=range;
	run;
	data _PB_corr_;
		%if %quote(&by) ~= %then %do;
		format &by;
		%end;
		format var $32. label $&maxlengthlabel..;
		format n corr corr_adj target_range;
		format target_range_rel percent7.1;
		%* Set the final length of the label variable;
		length label $&maxlengthlabel;
		merge 	_PB_corr_
				_PB_range_(keep=&by var range rename=(range=target_range));
		by &by var;
		target_range_rel = target_range / &_TARGET_RANGE_;
		corr_adj = corr * target_range_rel;
		label 	n = "Number of bins"
				target_range = "Range of target variable"
				target_range_rel = "Relative range of target variable (input data range = %sysfunc(putn(&_TARGET_RANGE_, best8.)))"
				corr = "Weighted correlation between observed binned values and predicted LOESS values"
				corr_adj = "Weighted correlation normalized by the spanned target range";
	run;
	proc sort data=_PB_corr_ out=&outcorr;
		by &by descending corr_adj;
	run;
	%if &log %then %do;
		%callmacro(getnobs, _PB_corr_ return=1, nobs nvars);
		%put;
		%put PLOTBINNED: Dataset %upcase(&outcorr) created with &nobs observations and &nvars variables;
		%put PLOTBINNED: containing two correlation measures of the binned observed vs. predicted LOESS values.;
	%end;
%end;

proc datasets nolist;
	delete  _PB_data_
			_PB_means_
			_PB_out_
			%if %quote(&outcorr) ~= %then %do;
			_PB_corr_
			_PB_range_
			%end;
			%if %quote(&datavartype) ~= %then %do;
			_PB_vartypes_
			%end;
			;
quit;

%* Delete global macro variables created here;
%symdel _TARGET_MIN_ _TARGET_MAX_;
%if &xaxisorig or &yaxisorig %then
	%symdel %MakeListFromName(_VAR, start=1, stop=&nro_vars, step=1, suffix=_MIN) %MakeListFromName(_VAR, start=1, stop=&nro_vars, step=1, suffix=_MAX);
%if %quote(&outcorr) ~= %then
	%symdel _TARGET_RANGE_;

%if &log %then %do;
	%put;
	%put PLOTBINNED: Macro ends.;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;

/*%end;*/
%MEND PlotBinned;
