/* MACRO %Psi
Version:	1.01
Author:		Daniel Mastropietro
Created:	16-Sep-2018
Modified:	18-Sep-2018

DESCRIPTION:
Computes the PSI or Population inStability Index for a set of continuous and categorical variables,
which can be either character or numeric.

The following guidelines are used for the output PSI value, based on a 10-bin comparison:
- PSI <= 0.1:			The population distribution is stable
- 0.1 < PSI <= 0.25:	The population distribution is somewhat unstable
- PSI > 0.25:			The population distribution is unstable

Ref: Scoring_Validation_Guidelines_RRM_Int.doc (document prepared by Experian for Scotia Bank)
received by e-mail on 15-Jul-2013 at Nat Consultores.

USAGE:
%Psi(
	database,				*** Input dataset containing the analysis variables for the BASE distribution.
	datacomp,				*** Input dataset containing the analysis variables for the COMPARE distribution.
	varnum=,				*** List of continuous variables to analyze.
	varclass=, 				*** List of categorical variables to analyze, either character or numeric.
	groups=10,				*** Number of groups or bins to use in the PSI calculation for continuous variables.
	adjustbins=1,			*** Whether to slightly adjust the bin ends in order to avoid allocation problems due to precision loss.
	adjustcoeff=1E-9,		*** Coefficient to use to adjust the bin ends if ADJUSTBINS=1.
	out=_psi_,				*** Output dataset containing the PSI for each analyzed variable.
	outpsi=_psi_bygroup_,	*** Output dataset containing the contribution by each bin to the PSI.
	outformat=_psi_formats_	*** Output dataset containing the format definition used to compute the PSI on continuous variables.
	checkparams=1 			*** Whether to check input parameters (datasets and variable existence)
	log=1);					*** Show messages in the log?

REQUIRED PARAMETERS:
- database:			Input dataset containing the analysis variables to be used as BASE distribution.
					This is the distribution used as reference for the PSI calculation, i.e. the distribution
					defining the bins for the analysis.
					Dataset options are allowed.

- datacomp:			Input dataset containing the analysis variables to be used as COMPARE distribution.
					This is the distribution that is compared against the BASE distribution in the PSI calculation.
					Dataset options are allowed.

OPTIONAL PARAMETERS:
- varnum:			List of continuous variables to analyze.
					Continuous variables are first binned into the specified number of GROUPS using the BASE dataset
					and the PSI is computed on those groups.
					At least one of the VARCLASS= option or the VARNUM= option should be non-empty.
					default: empty

- varclass:			List of categorical variables to analyze, which can be either character or numeric.
					Categorical variables are analyzed as is, i.e. no grouping is performed and the variables
					in the COMPARE dataset are mapped into the groups or values of the corresponding variables
					in the BASE dataset.
					At least one of the VARCLASS= option or the VARNUM= option should be non-empty.
					default: empty

- groups:			Number of groups or bins to use in the PSI calculation of continuous variables.
					default: 10

- adjustbins:		Flag indicating whether to slightly adjust the bin ends in order to avoid
					allocation problems due to precision loss.
					This adjustment is particularly useful when dealing with floating point
					variables having many repeated observations with the same floating point value
					which will likely make up a boundary value with potential precision loss,
					probably making that repeated value be assigned to the wrong bin, thus messing
					up the approximately equal-size property of the constructed bins on the BASE dataset.

					The value is adjusted by an absolute amount of -ADJUSTCOEFF for left boundaries
					and by an absolute amount of +ADJUSTCOEFF for right boundaries.
					Possible values: 0 => No, 1 => Yes
					default: 1

- adjustcoeff:		Coefficient to use to adjust the bin ends if ADJUSTBINS=1.
					See the description of parameter ADJUSTBINS above for more details.
					default: 1E-9

- out:				Output dataset containing the PSI for each analyzed variable.
					Variables are grouped by variable type ("categorical" or "continuous")
					and sorted by variable name within each group.
					default: _PSI_

- outpsi:			Output dataset containing the contribution by each bin to the PSI.
					Variables are grouped by variable type ("categorical" or "continuous")
					and sorted by variable name and bin value within each group.
					default: _PSI_BYGROUP_

- outformat:		Output dataset containing the format definition used to compute the PSI
					on continuous variables.
					These formats are computed on the BASE dataset and define the bins against
					which the variable values in the COMPARE dataset are matched.

					Note that for floating point variables, the format intervals may not
					always coincide with the actual bins constructed from the BASE dataset
					values due to issues generated by precision loss.
					See description of parameter ADJUSTBINS above for more information about
					how to tackle the problem when such thing manifests.
					default: _PSI_FORMATS_

- checkparams:		Flag indicating whether input parameters should be checked for existence
					(datasets and variables).
					Set this parameter to 0 when e.g. you do some RENAME in any input dataset
					and you know that the analysis variables and datasets exist.
					The reason for this is that renames are NOT run before checking for variable
					existence in input datasets.
					Possible values: 0 => No, 1 => Yes
					default: 1

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Categorize
- %CheckInputParameters
- %CreateFormatsFromCuts
- %CreateInteractions
- %ExecTimeStart
- %ExecTimeStop
- %FreqMult
- %MakeList
- %MakeListFromName
- %ResetSASOptions
- %SetSASOptions

APPLICATIONS:
1.- Compare two populations in order to determine whether there has been a significant shift
in the distribution of some variables.
This is particularly useful or important when using a new population to test a model fitted
on another population.
*/
&rsubmit;
%MACRO psi(
		database,
		datacomp,
		varnum=_NUMERIC_,
		varclass=,
		groups=10,
		adjustbins=1,
		adjustcoeff=1E-9,
		out=_psi_,
		outpsi=_psi_bygroup_,
		outformat=_psi_formats_,
		checkparams=1,
		log=1,
		help=0)
	/ store des="Computes the Population inStability Index for a set of continuous and categorical variables between two populations";
/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PSI: The macro call is as follows:;
	%put %nrstr(%Psi%();
	%put database , (REQUIRED) %quote(     *** Input dataset used as BASE distribution.);
	%put datacomp , (REQUIRED) %quote(     *** Input dataset used as COMPARE distribution.);
	%put varnum= , %quote(                 *** List of continuous input variables to analyze.);
	%put varclass= , %quote(               *** List of categorical input variables to analyze.);
	%put groups, %quote(                   *** Number of groups to use for the PSI calculation on continuous variables.);
	%put adjustbins=1 ,%quote(             *** Whether to slightly adjust the bin ends in order to avoid allocation problems due to precision loss.);
	%put adjustcoeff=1E-9 , %quote(        *** Coefficient to use to adjust the bin ends if ADJUSTBINS=1.);
	%put out= ,	%quote(		               *** Output dataset containing the PSI of each analyzed variable.);
	%put outpsi= , %quote(		           *** Output dataset containing the contribution by each bin to the PSI.);
	%put outformat= , %quote(              *** Output dataset containing the format definition used to compute the PSI on continuous variables.);
	%put checkparams=1 %quote(             *** Whether to check the input parameters for something wrong.);
	%put log=1) %quote(                    *** Show messages in log?);
%MEND ShowMacroCall;

%* Extract the dataset names for the call to %CheckInputParameters because it fails otherwise;
%local database_name;
%local datacomp_name;
%let database_name = %scan(&database, 1, '(');
%let datacomp_name = %scan(&datacomp, 1, '(');
%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if &checkparams and ~%CheckInputParameters(data=&database_name &datacomp_name, singleData=0,
													check=varnum varclass, macro=PSI) %then %do;
		%ShowMacroCall;
%end;
%else %if %quote(&varnum) = and %quote(&varclass) = %then %do;
	%put PSI: At least one of VARNUM= or VARCLASS= must NOT be empty.;
	%put PSI: Macro stops.;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%local varlist_with_formats;	%* Set of variables and formats to use: Ex: z v1_base. xx v2_base. y v3_base.;
%local validfmtname_opt;		%* Value of the VALIDFMTNAME option to restore at the end;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put PSI: Macro starts;
	%put;
	%put PSI: Input parameters:;
	%put PSI: - BASE dataset    = %quote(&database);
	%put PSI: - COMPARE dataset = %quote(&datacomp);
	%put PSI: - varnum = %quote(         &varnum);
	%put PSI: - varclass = %quote(       &varclass);
	%put PSI: - groups = %quote(         &groups);
	%put PSI: - adjustbins = %quote(     &adjustbins);
	%put PSI: - adjustcoeff = %quote(    &adjustcoeff);
	%put PSI: - out = %quote(            &out);
	%put PSI: - outpsi = %quote(         &outpsi);
	%put PSI: - outformat = %quote(      &outformat);
	%put PSI: - checkparams= %quote(     &checkparams);
	%put PSI: - log = %quote(            &log);
	%put;
%end;

%SetSASOptions;
%ExecTimeStart;

%let validfmtname_opt = %sysfunc(getoption(validfmtname));
options validfmtname=LONG;	%* This accepts long format names;

%* Initialize the set of continuous variables with their formats, so that everything works fine
%* when VARNUM= is empty;
%let varlist_with_formats = ;

%* Create a dataset stating the type of each variable (CONTINUOUS/CATEGORICAL)
%* so that it is informed in thte output dataset;
data _psi_vartypes;
	length var $32;
	length type $15;
	%if %quote(&varnum) ~= %then %do;
	array avarnum(*) &varnum;
	do i = 1 to dim(avarnum);
		var = vname(avarnum(i));
		type = "continuous";
		output;
	end;
	%end;
	%if %quote(&varclass) ~= %then %do;
	array avarclass(*) &varclass;
	do i = 1 to dim(avarclass);
		var = vname(avarclass(i));
		type = "categorical";
		output;
	end;
	%end;
	drop i;
run;

%*** CONTINUOUS VARIABLES;
%if %quote(&varnum) ~= %then %do;
	%local i;						%* Loop variable;
	%local nvars;					%* Number of continuous variables;
	%local vari;					%* Currently analyzed variable in the I loop;
	%local fmtnamei;				%* Name of the format used for variable &vari;
	%local varnumbers;				%* List of variables whose names are numbered, e.g. var1, var2, etc;
									%* These are used to avoid exceeding the maximum of 32 characters in the variable names
									%* when categorizing the continuous variables;
	%local vargroups;				%* List of variable names containing the groups or bins when categorizing continuous variables;
	%local zeros;					%* Bunch of zeros used to left pad the numbering of the formats (e.g. v001_base);

	%* Bin the continuous variables (all variables are binned at the same time);
	%* Note that the variable names used after binning are of the form VAR1, VAR2, ...
	%* so that there is no problem in exceeding the 32-character limit of SAS;
	%let nvars = %sysfunc(countw(&varnum));
	%let varnumbers = %MakeListFromName(var, start=1, step=1, stop=&nvars);
	%let vargroups = %MakeList(&varnumbers, suffix=_group);
	%global varstats;
	%CreateInteractions(&varnumbers, with=min max, join=_, allinteractions=1, macrovar=varstats, log=0);

	%* Create a copy of the BASE dataset because:
	%* - we are using twice in the code
	%* - we want to reduce it to its minimal expression in terms of variables kept
	%* - it may contain data options that may filter the analysis cases;
	data _psi_base(keep=&varnum &varclass);
		set &database;
	run;
	%* Update the macro variable containing the BASE dataset because it is used
	%* outside this loop when computing the variables distribution (and because
	%* this process here does not run when there are no continuous variables to analyze);
	%let database = _psi_base;

	%* Categorize ALL continuous variables;
	%if &log %then %do;
		%put;
		%put PSI: Categorizing &nvars continuous variables on the BASE dataset...;
	%end;
	%Categorize(
		_psi_base,
		var=&varnum,
		groups=&groups,
		stat=min max,
		varcat=&vargroups,
		varstat=&varstats,
		out=_psi_base_cat,
		log=0
	);

	%*** For each CONTINUOUS variable, find the min and max values for each bin;
	%* These min and max values define the range against which the distribution of the correspoding variables
	%* in the COMPARE dataset is compared;
	proc datasets nolist;
		delete _psi_base_dist;
	quit;

	%if &log %then
		%put PSI: Computing group ranges of continuous variables in BASE dataset...;
	%do i = 1 %to &nvars;
		%let vari = %scan(&varnum, &i, ' ');
		%let zeros = %rep(0, 3 - %length(&i));
		%if &log %then
			%put PSI: %upcase(&vari) (&i of &nvars)...;
		proc sql noprint;
			create table _psi_base_dist_i as
			select
				cats("v", put(&i, z4.), "_base") as fmtname
				,"&vari" as var length=32
				,var&i._group as _group
				,var&i._min as _min
				,var&i._max as _max
				,count(*) as _n
			from _psi_base_cat
			group by var&i._group, var&i._min, var&i._max
			order by fmtname, var&i._group
			;

			%* Store the name of the format in a macro variable so that we can refer to it below in macro language;
			select distinct fmtname into :fmtnamei
			from _psi_base_dist_i;
		quit;

		%* Update the list of formats for each analysis variable so that they can be applied
		%* when generating the distribution for the COMPARE dataset;
		%let varlist_with_formats = &varlist_with_formats
									&vari &fmtnamei..;

		%* Append the results into the single dataset that contains the information for ALL variables;
		proc append base=_psi_base_dist data=_psi_base_dist_i;
		run;
	%end;

	%* Create formats on ALL the analysis variables;
	%CreateFormatsFromCuts(
		_psi_base_dist,
		dataformat=long,
		cutname=_max,
		varfmtname=fmtname,
		includeright=1,
		adjustranges=&adjustbins,
		adjustcoeff=&adjustcoeff,
		out=_psi_base_format_def,
		storeformats=1,
		showformats=0,
		log=0
	);

	%* Create the output formats dataset if requested;
	%if %quote(&outformat) ~= %then %do;
		data &outformat;
			format fmtname var;
			merge	_psi_base_format_def
					_psi_base_dist(keep=fmtname var);
			by fmtname;
		run;
		%if &log %then %do;
			%put PSI: Dataset %upcase(&outformat) created with the format definition for continuous variables;
			%put PSI: that define the BASE groups used to compute the PSI.;
		%end;
	%end;
%end;

%*** Distributions of ALL variables in BASE and COMPARE datasets;
%if &log %then %do;
	%put;
	%put PSI: Computing distribution of ALL variables in BASE dataset...;
%end;
%FreqMult(
	&database,
	format=&varlist_with_formats,
	var=&varnum &varclass,
	missing=1,
	out=_psi_base_freq,
	log=0
);
%if &log %then
	%put PSI: Computing distribution of ALL variables in COMPARE dataset...;
%FreqMult(
	&datacomp,
	format=&varlist_with_formats,
	var=&varnum &varclass,
	missing=1,
	out=_psi_compare_freq,
	log=0
);

%if &log %then %do;
	%put;
	%put PSI: Computing the Population inStability Index by group/bin...;
%end;
proc sql;
	create table &outpsi as
	select
		b.var,
		t.type,
		b.fmtvalue,
		b.count as count_base,
		b.percent as percent_base,
		/* NOTE: NONE of the BASE values CAN be 0 because o.w. the group value (FMTVALUE) would not show up in the BASE dataset */
		coalesce(c.count, 0) as count_comp,
		coalesce(c.percent, 0) as percent_comp,
		/* NOTE: In the computation of the PSI, it is important to use the PERCENT of cases (as opposed to the case COUNT)
		ALSO in the log() term, because of bins that may exist in one dataset and not in the other... making possibly the
		COUNT to be equal but actually the PERCENT values are NOT (because the base for computing the percentages is not
		the same in both datasets --because of a differing number of groups/bins.
		*/
		(coalesce(c.percent, 0) - b.percent)/100 * log( (coalesce(c.percent, 0) + 1E-9) / (b.percent + 1E-9) ) as psi
	from _psi_base_freq b
	LEFT JOIN _psi_compare_freq c
	on b.var = c.var
	and b.fmtvalue = c.fmtvalue
	LEFT JOIN _psi_vartypes t
	on b.var = t.var
	order by type, var, fmtvalue
	;
quit;
%if &log %then
	%put PSI: Dataset %upcase(&outpsi) created with the PSI values by group/bin (sorted by type, var, bin value);

%if &log %then %do;
	%put;
	%put PSI: Computing the Population inStability Index...;
%end;
proc sql;
	create table &out as
	select
		var
		,type
		,sum(count_base) as ncases_base
		,sum(count_comp) as ncases_comp
		,count(psi) as nbins
		,sum(psi) as psi
	from &outpsi
	group by var, type
	order by type, var
	;
quit;
%if &log %then
	%put PSI: Dataset %upcase(&out) created with the PSI values by variable (sorted by type, var);

%* Reset the VALIDFMTNAME option;
options validfmtname=&validfmtname_opt;

%* Delete temporary datasets;
proc datasets nolist;
	delete	_psi_base
			_psi_base_cat
			_psi_base_dist
			_psi_base_dist_i
			_psi_base_freq
			_psi_base_format_def
			_psi_compare_freq
			_psi_vartypes
	;
quit;

%* Delete global macro variables;
%if %quote(&varnum) ~= %then
	%symdel varstats;

%ExecTimeStop;
%ResetSASOptions;

%end;

%MEND Psi;


/*
***************
* Test data
***************;
proc freq data=test.totest;
	tables b_target_dq90_12m e_cr_pago_tipo;
run;

data base compare;
	set test.totest;
	if e_cr_pago_tipo = "Debito" then output base;
	else output compare;
run;


***************
* Input parameters
***************;
* This should be a list of variables and we should iterate on each of them;
%let varnum = V_CR_SALDO_ACTUAL B_TIME_DQ90;

* Class variables, some numeric some categorical;
%let varclass = B_TARGET_DQ90_12M E_CR_VINCULACION;

options mprint;
%psi(base, compare, varnum=&varnum, varclass=&varclass, out=psi_12, outpsi=psi_12_bins, outformat=psi_12_formats);
%psi(compare, base, varnum=&varnum, varclass=&varclass, out=psi_21, outpsi=psi_21_bins);
%psi(test.totest(where=(e_cr_pago_tipo = "Debito")), test.totest(where=(e_cr_pago_tipo ~= "Debito")), varnum=&varnum, varclass=&varclass, out=psi, outpsi=psi_bins);
options nomprint;
*/
