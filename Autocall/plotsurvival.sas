/* MACRO %PlotSurvival
Version: 		1.03
Author: 		Daniel Mastropietro
Created: 		29-Jul-2015
Modified: 		29-Nov-2018 (previous: 15-Feb-2016, 05-Oct-2015)
SAS Version:	9.4

DESCRIPTION:
Generates plots to visually test the Proportional Hazards assumption for Cox Survival regression models
on a set of analysis variables.
The analysis variables are categorized in a few groups (e.g. 3 groups) and the Survival curve
is plotted on the same graph for each of these groups.

USAGE:
%PlotSurvival(
	data , 						*** Input dataset.
	target=, (REQUIRED) 		*** Target variable containing the time to the event of interest.
	censor=, (REQUIRED)			*** Censor variable containing the indicator of whether the observation is censored.
	varclass=, 					*** List of categorical input variables to analyze.
	varnum=,					*** List of continuous input variables to analyze.
	censorValue=1,				*** Value that indicates censored cases.
	groups=3,					*** Nro. of groups to use in the categorization of continuous variables.
	method=KM,					*** Method to use for the Survival function estimation.
	alpha=0.05, 		 		*** Alpha level for confidence limits of the survival function.
	out=,						*** Output dataset containing the estimated Survival function.
	odspath=, 					*** Unquoted name of the path where all generated files should be saved.
	odsfile=,					*** Unquoted name of the file where the plots are saved.
	odsfiletype=html,			*** Type of the file specified in ODSFILE or output format.
	imagerootname=PlotSurvival,	*** Root name to be used for the image file name generated by ODS graphics.
	log=1);						*** Show messages in log?

REQUIRED PARAMETERS:
- data:				Input dataset. Data options can be specified as in a data= SAS option.

- target:			Target variable containing the time to the event of interest.

- censor:			Censor variable indicating whether the observation is censored.

OPTIONAL PARAMETERS:
- varclass:			List of categorical variables to analyze.
					At least one of the VARCLASS= option or the VARNUM= option should be non-empty
					to produce some graphs.
					default: empty

- varnum:			List of continuous variables to analyze.
					At least one of the VARCLASS= option or the VARNUM= option should be non-empty
					to produce some graphs.
					default: empty

- censorValue:		Value indicating censored cases.
					default: 1

- groups:			Number of groups in which to categorize continuous variables for the plot.
					default: 3

- method:			Value of the METHOD= option of the PROC LIFETEST statements.
					default: KM (Kaplan-Meier estimator)

- alpha:			Significance level defining the width of the confidence intervals.
					The confidence level is equal to 1-alpha.
					default: 0.05

- out:				Output dataset containing the estimated Survival function.
					Data options can be specified as in a data= SAS option.

- odspath:			Unquoted name of the path containing the files where plots should be saved.
					default: current working directory

- odsfile:			Unquoted name of the file where plots should be saved.
					If the odsfiletype is HTML, each file is saved in separate files
					with names indicated below for the IMAGEROOTNAME parameter.
					default: (empty)

- odsfiletype:		Type of the file specified in the ODSFILE= option.
					Valid values are those given in the documentation of ODS GRAPHICS,
					in section "Supported File Types for Output Destinations",
					under the table column "Output Destination".
					default: html
					NOTE: The default should be changed to PDF if the PDF output works with the LIFETEST procedure.
					which currently (Aug-2015) does not for medium size datasets (e.g. 300,000 cases).

- imagerootname:	Root name to be used for the image file name generated by ODS graphics
					using the following name:
						<yymmdddThhmmss>-<imagerootname>-<TARGET>-<K>-<VAR>.PNG
					where <yyyymmddThhmmss> is the current execution date and time, and
					<K> and <VAR> are respectively the number (zero padded to achieve
					alphabetical order) and name of the currently analyzed
					variable in the order they are passed to the VAR= parameter.
					Ex: 20181129-PlotBinned-Bad-001-balance.png
					which defaults to PNG format.
					default: PlotSurvival

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes.
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %AddLabels
- %Categorize
- %ExecTimeStart
- %ExecTimeStop
- %GetNroElements
- %ODSOutputClose
- %ODSOutputOpen
- %ResetSASOptions
- %SetSASOptions
*/
%MACRO PlotSurvival(
		data,
		target=,
		censor=,
		varclass=,
		varnum=,
		censorValue=1,
		groups=3,
		method=KM,
		alpha=0.05,
		out=,
		odspath=,
		odsfile=,
		odsfiletype=html,
		imagerootname=PlotSurvival,
		log=1,
		help=0) 
	/ des="Makes plots of survival curves to visually check proportional hazards assumption for a set of input variables";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PLOTSURVIVAL: The macro call is as follows:;
	%put %nrstr(%PlotSurvival%();
	%put data , (REQUIRED) %quote(         *** Input dataset.);
	%put target= , (REQUIRED) %quote(      *** Target variable containing the time to the event of interest.);
	%put censor= , (REQUIRED) %quote(      *** Censor variable containing the indicator of whether the observation is censored.);
	%put varclass= , %quote(               *** List of categorical input variables to analyze.);
	%put varnum= , %quote(                 *** List of continuous input variables to analyze.);
	%put censorValue=1 , %quote(           *** Value that indicates censored cases.);
	%put groups=3 , %quote(                *** Nro. of groups to use in the categorization of continuous variables.);
	%put method=KM , %quote(               *** Method to use for the Survival function estimation.);
	%put alpha=0.05 , %quote(              *** Alpha level for confidence limits of the survival function.);
	%put out= ,	%quote(		               *** Output dataset containing the estimated Survival function.);
	%put odspath= ,	%quote(		           *** Unquoted name of the path where all generated files should be saved.);
	%put odsfile= ,	%quote(		           *** Unquoted name of the file where the plots are saved.);
	%put odsfiletype=html, %quote(	       *** Type of the file specified in ODSFILE or output format.);
	%put imagerootname=PlotSurvival,%quote(*** Root name to be used for the image file name generated by ODS graphics.);
	%put log=1) %quote(                    *** Show messages in log?);
%MEND ShowMacroCall;

/*----- Macro to create output table with Survival function estimate using ODS -----*/
%MACRO CreateODSTableWithSurvEstimate(method);
	%if %quote(%upcase(&method)) = BRESLOW or %quote(%upcase(&method)) = B %then %do;
	ods output BreslowEstimates=_PH_out_i;
	%end;
	%else %if %quote(%upcase(&method)) = FH  %then %do;
	ods output FlemingEstimates=_PH_out_i;
	%end;
	%else %if %quote(%upcase(&method)) = KM or %quote(%upcase(&method)) = PL %then %do;
	ods output ProductLimitEstimates=_PH_out_i;
	%end;
	%else %if %quote(%upcase(&method)) = ACT or %quote(%upcase(&method)) = LIFE or %quote(%upcase(&method)) = LT %then %do;
	ods output LifeTableEstimates=_PH_out_i;
	%end;
%MEND CreateODSTableWithSurvEstimate;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , otherRequired=%quote(&target,&censor), requiredParamNames=data target= censor=, check=target censor varclass varnum, macro=PLOTSURVIVAL) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%local i k;
%local nro_varclass;
%local nro_varnum;
%local _var_;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put PLOTSURVIVAL: Macro starts;
	%put;
	%put PLOTSURVIVAL: Input parameters:;
	%put PLOTSURVIVAL: - Input dataset = %quote(&data);
	%put PLOTSURVIVAL: - target = %quote(       &target);
	%put PLOTSURVIVAL: - censor = %quote(       &censor);
	%put PLOTSURVIVAL: - varclass = %quote(     &varclass);
	%put PLOTSURVIVAL: - varnum = %quote(       &varnum);
	%put PLOTSURVIVAL: - censorValue = %quote(  &censorValue);
	%put PLOTSURVIVAL: - groups = %quote(       &groups);
	%put PLOTSURVIVAL: - method = %quote(       &method);
	%put PLOTSURVIVAL: - alpha = %quote(        &alpha);
	%put PLOTSURVIVAL: - out = %quote(          &out);
	%put PLOTSURVIVAL: - odspath = %quote(      &odspath);
	%put PLOTSURVIVAL: - odsfile = %quote(      &odsfile);
	%put PLOTSURVIVAL: - odsfiletype = %quote(  &odsfiletype);
	%put PLOTSURVIVAL: - imagerootname = %quote(&imagerootname);
	%put PLOTSURVIVAL: - log = %quote(          &log);
	%put;
%end;

%SetSASoptions;
%ExecTimeStart;
%ODSOutputOpen(&odsfile, odspath=&odspath, odsfiletype=&odsfiletype, macro=PLOTSURVIVAL, log=&log);

%* Delete datasets that go through an APPEND during this process;
%if %quote(&out) ~= %then %do;
	proc datasets nolist;
		delete _PH_out_;
	quit;
%end;

%let nro_varclass = %GetNroElements(&varclass);
%let nro_varnum = %GetNroElements(&varnum);

%* Variable used to number each plot (regardless of whether the analyzed variable is categorical or continuous);
%let k = 0;
%do i = 1 %to &nro_varclass;
	%let k = %eval(&k + 1);
	%let _var_ = %scan(&varclass , &i , ' ');
	%put PLOTSURVIVAL: Analyzing categorical variable &i of &nro_varclass: %upcase(&_var_)...;

	%* Select just the plot for the ODS output (e.g. HTML or RTF file);
	%* Note that if I use the NOPRINT option in the PROC LIFETEST statement (to exclude the generated table from the output)
	%* ALL output is supressed, including the plot!;
	%* Ref: Documentation on the ODS EXCLUDE statement;
	%if %quote(&odsfile) ~= %then %do; 
	ods &odsfiletype select where=(_name_ ? 'SurvivalPlot');
	%end;
	ods proclabel="%upcase(&_VAR_)";	%* This adds a title to each entry in an e.g. PDF file that helps in browsing;
	ods graphics / outputfmt=png imagename="&imagerootname-&target-%GetZeroPaddedNumber(&k, &nro_varclass)-&_var_" reset=index;	%* This generates the image file with the name specified in the IMAGENAME= option;
		%** NOTE: The OUTPUTFMT=PNG option is used to avoid too large files generated with the PDF or RTF formats;
		%** Ref: Martin Mancey from SAS Technical Support in Oct-2015 via the SAS license at Pronto;
	title "Input variable: &_var_";
	ods select where=(_name_ ? 'SurvivalPlot');
	proc lifetest data=&data plots=(survival(strata=overlay CL)) method=&method alpha=&alpha;
		strata &_var_;
		time &target*&censor(&censorValue);
		%if %quote(&out) ~= %then %do;
		%CreateODSTableWithSurvEstimate(&method);
		%end;
	run;
	ods select all;
	title;

	%* Append output dataset to output data;
	%if %quote(&out) ~= %then %do;
		%* Add the variable name information;
		data _PH_out_i;
			format var;
			length var $32;
			set _PH_out_i (rename=(&_var_=value));
			var = "&_var_";
		run;
		%* Append the data to the output dataset;
		proc append base=_PH_out_ data=_PH_out_i FORCE;
		run;
	%end;
%end;

%put;
%if &nro_varnum > 0 %then %do;
	%put PLOTSURVIVAL: Categorizing continuous variables...;
	%put;
%*	%Categorize(&data, var=&varnum, groups=&groups, both=0, value=mean, varvalue=&varnum, out=_PH_data_(keep=&target &censor &varnum), log=0);
	%* DM-2016/02/15: Refactored version of %Categorize (much simpler);
	%Categorize(&data, var=&varnum, groups=&groups, value=mean, varstat=&varnum, out=_PH_data_(keep=&target &censor &varnum), log=0);
%end;

%do i = 1 %to &nro_varnum;
	%let k = %eval(&k + 1);
	%let _var_ = %scan(&varnum , &i , ' ');
	%put PLOTSURVIVAL: Analyzing continuous variable &i of &nro_varnum: %upcase(&_var_)...;

	%* Remove tables from the HTML output and form the listing output;
	%* Note that if I use the NOPRINT option in the PROC LIFETEST statement, ALL output is supressed, including the plot!;
	%* Ref: Documentation on the ODS EXCLUDE statement;
	%if %quote(&odsfile) ~= %then %do; 
	ods &odsfiletype select where=(_name_ ? 'SurvivalPlot');
	%end;
	ods proclabel="%upcase(&_VAR_)";	%* This adds a title to each entry in an e.g. PDF file that helps in browsing;
	ods graphics / outputfmt=png imagename="&imagerootname-&target-%GetZeroPaddedNumber(&k, &nro_varnum)-&_var_" reset=index;	%* This generates the image file with the name specified in the IMAGENAME= option;
		%** NOTE: The OUTPUTFMT=PNG option is used to avoid too large files generated with the PDF or RTF formats;
		%** Ref: Martin Mancey from SAS Technical Support in Oct-2015 via the SAS license at Pronto;
	title "Input variable: &_var_";
	ods select where=(_name_ ? 'SurvivalPlot');
	proc lifetest data=_PH_data_ plots=(survival(strata=overlay CL)) method=&method alpha=&alpha;
		strata &_var_;
		time &target*&censor(&censorValue);
		%if %quote(&out) ~= %then %do;
		%CreateODSTableWithSurvEstimate(&method);
 		%end;
	run;
	ods select all;
	title;

	%* Append output dataset to output data;
	%if %quote(&out) ~= %then %do;
		%* Add the variable name information;
		data _PH_out_i;
			format var;
			length var $32;
			set _PH_out_i (rename=(&_var_=value));
			var = "&_var_";
		run;
		%* Append the data to the output dataset;
		proc append base=_PH_out_ data=_PH_out_i FORCE;
		run;
	%end;
%end;
%* Close the ODS output and reset options;
%ODSOutputClose(&odsfile, odsfiletype=&odsfiletype, macro=PLOTSURVIVAL, log=&log);
ods graphics / reset=all;

%* Delete temporary datasets;
%if &nro_varnum > 0 %then %do;
	proc datasets nolist;
		delete _PH_data_;
	quit;
%end;

%* Create output dataset and delete temporary output dataset;
%if %quote(&out) ~= %then %do;
	data &out;
		set _PH_out_;
		%* Keep only the rows that have a non-missing survival value. In fact, the original dataset created by
		%* PROC LIFETEST contains at least as many cases as the input dataset and here we are only interested
		%* in keeping the cases that inform about the survival function.
		%* Note that missing survival values are created when there are repeated times to event;
		if Survival ~= .;
	run;
	%AddLabels(&out, &data, label=label, var=var, log=0);
	proc datasets nolist;
		delete 	_PH_out_
				_PH_out_i;
	quit;
%end;

%if &log %then %do;
	%put;
	%put PLOTSURVIVAL: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASoptions;

%end;	%* %if ~%CheckInputParameters;
%MEND PlotSurvival;
