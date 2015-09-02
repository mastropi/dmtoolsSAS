/* MACRO %PHTestPlots
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		29-Jul-2015
Modified: 		29-Jul-2015
SAS Version:	9.4

DESCRIPTION:
Generates plots to visually test the Proportional Hazards assumption for Cox Survival regression models
on a set of analysis variables.
The analysis variables are categorized in a few groups (e.g. 3 groups) and the Survival curve
is plotted on the same graph for each of these groups.

USAGE:
%PHTestPlots(
	data , 					*** Input dataset.
	target=, (REQUIRED) 	*** Target variable containing the time to the event of interest.
	censor=, (REQUIRED)		*** Censor variable containing the indicator of whether the observation is censored.
	varclass=, 				*** List of categorical input variables to analyze.
	varnum=, 		       	*** List of continuous input variables to analyze.
	censorValue=1,			*** Value that indicates censored cases.
	groups=3,				*** Nro. of groups to use in the categorization of continuous variables.
	method=KM,				*** Method to use for the Survival function estimation.
	alpha=0.05, 		 	*** Alpha level for confidence limits of the survival function.
	odspath=, 				*** Quoted name of the path where all generated files should be saved.
	odsfile=,				*** Quoted name of the file where the plots are saved.
	odsfiletype=html,		*** Type of the file specified in ODSFILE or output format.
	log=1);					*** Show messages in log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option..

- target:		Target variable containing the time to the event of interest.

- censor:		Censor variable indicating whether the observation is censored.

OPTIONAL PARAMETERS:
- varclass:		List of categorical variables to analyze.
				At least one of the VARCLASS= option or the VARNUM= option should be non-empty
				to produce some graphs.
				default: empty

- varnum:		List of continuous variables to analyze.
				At least one of the VARCLASS= option or the VARNUM= option should be non-empty
				to produce some graphs.
				default: empty

- censorValue:	Value indicating censored cases.
				default: 1

- groups:		Number of groups in which to categorize continuous variables for the plot.
				default: 3

- method:		Value of the METHOD= option of the PROC LIFETEST statements.
				default: KM (Kaplan-Meier estimator)

- alpha:		Significance level defining the width of the confidence intervals.
				The confidence level is equal to 1-alpha.
				default: 0.05

- odspath:		Quoted name of the path containing the files where plots should be saved.
				This is only valid for HTML output.
				default: none

- odsfile:		Quoted name of the file where plots should be saved.
				default: none

- odsfiletype:	Type of the file specified in the ODSFILE= option.
				default: html
				NOTE: The default should be changed to PDF if the PDF output works with the LIFETEST procedure.
				which currently (Aug-2015) does not for medium size datasets (e.g. 300,000 cases).

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes.
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Categorize
- %GetNroElements
- %ResetSASOptions
- %SetSASOptions
*/
&rsubmit;
%MACRO PHTestPlots(
		data,
		target=,
		censor=,
		varclass=,
		varnum=,
		censorValue=1,
		groups=3,
		method=KM,
		alpha=0.05,
		odspath=,
		odsfile=,
		odsfiletype=html,
		log=1,
		help=0) 
	/ store des="Makes plots of survival curves to visually check proportional hazards assumption for a set of input variables";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PHTESTPLOTS: The macro call is as follows:;
	%put %nrstr(%PHTestPlots%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put target= , (REQUIRED) %quote(   *** Target variable containing the time to the event of interest.);
	%put censor= , (REQUIRED) %quote(   *** Censor variable containing the indicator of whether the observation is censored.);
	%put varclass= , %quote(            *** List of categorical input variables to analyze.);
	%put varnum= , %quote(              *** List of continuous input variables to analyze.);
	%put censorValue=1 , %quote(        *** Value that indicates censored cases.);
	%put groups=3 , %quote(             *** Nro. of groups to use in the categorization of continuous variables.);
	%put method=KM , %quote(            *** Method to use for the Survival function estimation.);
	%put alpha=0.05 , %quote(           *** Alpha level for confidence limits of the survival function.);
	%put odspath= ,	%quote(		        *** Quoted name of the path where all generated files should be saved.);
	%put odsfile= ,	%quote(		        *** Quoted name of the file where the plots are saved.);
	%put odsfiletype=html, %quote(	    *** Type of the file specified in ODSFILE or output format.);
	%put log=1) %quote(                 *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , otherRequired=%quote(&target,&censor), requiredParamNames=data target= censor=, check=target censor varclass varnum, macro=PHTESTPLOTS) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%local datetime_start datetime_end;
%local i;
%local nro_varclass;
%local nro_varnum;
%local _var_;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put PHTESTPLOTS: Macro starts;
	%put;
	%put PHTESTPLOTS: Input parameters:;
	%put PHTESTPLOTS: - Input dataset = %quote(&data);
	%put PHTESTPLOTS: - target = %quote(       &target);
	%put PHTESTPLOTS: - censor = %quote(       &censor);
	%put PHTESTPLOTS: - varclass = %quote(     &varclass);
	%put PHTESTPLOTS: - varnum = %quote(       &varnum);
	%put PHTESTPLOTS: - censorValue = %quote(  &censorValue);
	%put PHTESTPLOTS: - groups = %quote(       &groups);
	%put PHTESTPLOTS: - method = %quote(       &method);
	%put PHTESTPLOTS: - alpha = %quote(        &alpha);
	%put PHTESTPLOTS: - odspath = %quote(      &odspath);
	%put PHTESTPLOTS: - odsfile = %quote(      &odsfile);
	%put PHTESTPLOTS: - odsfiletype = %quote(  &odsfiletype);
	%put PHTESTPLOTS: - log = %quote(          &log);
	%put;
%end;

%SetSASoptions;
%ExecTimeStart;
%ODSOutputOpen(&odspath, &odsfile, odsfiletype=&odsfiletype, macro=PHTESTPLOTS, log=&log);

%* Keep track of total exceution time;
%* Ref: http://www.sascommunity.org/wiki/Tips:Program_run_time;
%let datetime_start = %sysfunc(DATETIME()) ;

%let nro_varclass = %GetNroElements(&varclass);
%let nro_varnum = %GetNroElements(&varnum);

%do i = 1 %to &nro_varclass;
	%let _var_ = %scan(&varclass , &i , ' ');
	%put PHTESTPLOTS: Analyzing categorical variable &i of &nro_varclass: %upcase(&_var_)...;

	%* Select just the plot for the ODS output (e.g. HTML or RTF file);
	%* Note that if I use the NOPRINT option in the PROC LIFETEST statement (to exclude the generated table from the output)
	%* ALL output is supressed, including the plot!;
	%* Ref: Documentation on the ODS EXCLUDE statement;
	%if %quote(&odsfile) ~= %then %do; 
	ods &odsfiletype select where=(_name_ ? 'SurvivalPlot');
	%end;
	title "Input variable: &_var_";
	proc lifetest data=&data plots=(survival(strata=overlay CL)) notable method=&method alpha=&alpha;
		strata &_var_;
		time &target*&censor(&censorValue);
	run;
	title;
%end;

%put;
%if &nro_varnum > 0 %then %do;
	%put PHTESTPLOTS: Categorizing continuous variables...;
	%put;
	%Categorize(&data, var=&varnum, groups=&groups, both=0, value=mean, varvalue=&varnum, out=_PH_data_(keep=&target &censor &varnum), log=0);
%end;

%do i = 1 %to &nro_varnum;
	%let _var_ = %scan(&varnum , &i , ' ');
	%put PHTESTPLOTS: Analyzing continuous variable &i of &nro_varnum: %upcase(&_var_)...;

	%* Remove tables from the HTML output and form the listing output;
	%* Note that if I use the NOPRINT option in the PROC LIFETEST statement, ALL output is supressed, including the plot!;
	%* Ref: Documentation on the ODS EXCLUDE statement;
	%if %quote(&odsfile) ~= %then %do; 
	ods &odsfiletype select where=(_name_ ? 'SurvivalPlot');
	%end;
	title "Input variable: &_var_";
	proc lifetest data=_PH_data_ plots=(survival(strata=overlay CL)) notable method=&method alpha=&alpha;
		strata &_var_;
		time &target*&censor(&censorValue);
	run;
	title;
%end;
%* Close the ODS output;
%ODSOutputClose(&odsfile, odsfiletype=&odsfiletype, macro=PHTESTPLOTS, log=&log);

%if &nro_varnum > 0 %then %do;
	proc datasets nolist;
		delete _PH_data_;
	quit;
%end;

%if &log %then %do;
	%put;
	%put PHTESTPLOTS: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASoptions;

%end;	%* %if ~%CheckInputParameters;
%MEND PHTestPlots;
