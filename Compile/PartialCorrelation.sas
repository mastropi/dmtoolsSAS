/* MACRO %PartialCorrelation
Version: 1.00
Author: Daniel Mastropietro
Created: 9-Feb-05
Modified: 9-Feb-05

DESCRIPTION:
This macro computes the partial correlation between regression variables and a target
variable in a linear regression model.

Ref: Hocking, "Methods and Applications of Linear Models" (1996), pag. 226.

USAGE:
%PartialCorrelation(data , target=, var= , weight= , obs= , out=, outplot=, plot=0, log=1);

REQUIRED PARAMETERS:
- data:			Input dataset used in the regression.

OPTIONAL PARAMETERS:
- target:		Target variable used in the regression.

- var:			List of regression variables.

- weight:		Weight variable used in the regression.

- obs:			Name of the variable containing the observation number. The values of this
				variable are used to label the points in the partial plots.
				default: <empty>, i.e. the observation number is given by the order of
				the observations in the dataset.

- out:			Output dataset containing the partial correlations for each variable.

- outplot:		Name to use as the root of the output datasets that contain the data needed
				to do the partial plots for each variable. The names of the output datasets
				are of the form: <out>_Intercept (partial plot for the intercept) and 
				<out>_<var> for the regressor variables, where <var> is the name of each
				regression variable analyzed.

- plot:			Whether the partial plots for each variable should be done.
				Possible values: 0 => No, 1 => Yes
				default: 0

- log:			Whether to show messages in the log.
				Possible values: 0 => No, 1 => Yes
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %DefineSymbols
- %GetDataOptions
- %GetNroElements
- %GetVarList
- %MakeListFromVar
- %Merge
- %RemoveFromList
- %ResetSASOptions
- %SetSASOptions
*/
&rsubmit;
%MACRO PartialCorrelation(data , target=, var= , weight= , obs= , out=, outplot=, plot=0, log=1)
	/ store des="Makes partial plots of a linear regression fit";
%local i nro_vars;
%local annost idst regvar _var_ var_sortedRR2 weightst;
%local out_name;
%local outplot_name outplot_options;
%local RSS_all RSS0 RSQ_all;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put PARTIALCORRELATION: Macro starts;
	%put;
%end;

%DefineSymbols(height=0.7);

/*----- Parsing input parameters -----*/
%*** WEIGHT=;
%let weightst = ;
%if %quote(&weight) ~= %then
	%let weightst = weight &weight;
/*------------------------------------*/

%* Partial plot for the intercept (see example in "Influence Diagnostics" in SAS Manuals);
data _PartialCorr_data_;
	set &data;
	_int_ = 1;
/*	%if &obs = %then %do;
		_obs_ = _N_;
		%let obs = _obs_; 

		if vtype(&obs) = "N" then
			_obsc_ = put(&obs , 8.);
		else
			_obsc_ = &obs;
	%end;
*/
run;

/* Parse the VAR= parameter (once all the options coming in the input dataset were parsed) */
%* It is necessary to do this AFTER the input dataset was read into a local dataset
%* (_PartialCorr_data_) to avoid problems when there are KEEP or DROP options coming with the
%* input dataset are contradictory with the list of variables to be analyzed (for ex.
%* %PartialPlots(data(keep=obs x z), target=y, var=x z w). Clearly variable W will not be
%* found in the local input dataset _PartialCorr_data_ because it is not kept! In order to
%* detect this, the parsing of the VAR= parameter needs to be done AFTER the input dataset
%* was read into a local dataset;
%*** VAR=;
%let nro_vars = %GetNroElements(&var);

%let regvar = &var;
%* Linear regression with ALL the variables to compute RSS for the full model;
proc reg data=_PartialCorr_data_ outest=_PartialCorr_RSQ_(keep=_RSQ_ rename=(_RSQ_=RSQ)) rsquare;
	&weightst;
	model &target = &regvar;
%let var = %GetVarList(_PartialCorr_data_, var=&var, log=0);
	output out=_PartialCorr_pred_(keep=&target residual) residual=residual;
run;
quit;
data _NULL_;
	if _N_ = 1 then set _PartialCorr_RSQ_;
	set _PartialCorr_pred_ end=lastobs;
	RSS + residual**2;
	if residual ~= . then do;
		target_sum + &target;
		target2_sum + &target**2;
		n + 1;
	end;
	if lastobs then do;
		call symput ('RSS_all', RSS);
		call symput ('RSS0', target2_sum - target_sum**2/n);
		call symput ('RSQ_all', RSQ);
	end;
run;

title "Partial Regression Residual Plot of %upcase(&target) and the Intercept";
title2 "Regression of %upcase(&target) and Intercept";
proc reg data=_PartialCorr_data_ noprint;
	&weightst;		%*** Notar que aqui tambien va el weight statement, como en la regresion original;
	model &target _int_ = &regvar / noint;
	output out=_PartialCorr_pred_ r=_resy_ _resx_;
		%*** Notar la opcion r= en lugar de rstudent=. De hecho  aqui hay que calcular los residuos a secas,
		%*** no los studentizados, para que el estimador de la pendiente sea el mismo que en el de la 
		%*** regresion original;
run;
quit;

%* Partial regression fit (resy vs. resx);
title2 "Regressing the partial residuals";
proc reg data=_PartialCorr_pred_;
	&weightst;							%*** VA EL WEIGHT PARA ESTA REGRESION??? (SI: Verificado con los partial plots del PROC REG);
	model _resy_ = _resx_ / noint;		%*** VA EL NOINT? SI: no hace falta estimar el intercept por que da 0 (del orden de 1e-14 por ejemplo), ya que el promedio de los residuos _resy_ es 0, por ser residuos de una regresion lineal con intercept;
	output out=_PartialCorr_resfit_ pred=_resy_pred_;
run;
quit;
%Merge(_PartialCorr_pred_ , _PartialCorr_resfit_ , out=_PartialCorr_toplot_ , by=&obs, log=0);
proc sort data=_PartialCorr_toplot_;
	by _resx_;
run;
/*---------------------------------------- PLOT ---------------------------------------------*/
%if &plot %then %do;
	%* Annotate dataset;
	%if %quote(&obs) ~= %then %do;
		%* Notar el trim(left()) aplicado a la variable con la observacion, para que el label quede centrado sobre el punto;
		data _PartialCorr_anno_(keep=xsys ysys x y function text position);
			set _PartialCorr_toplot_;
			retain xsys "2" ysys "2";
			x=_resx_; y=_resy_; function="label"; text=trim(left(put(&obs,8.))); position="2";
		run;
		data _PartialCorr_anno_;
			set _PartialCorr_anno_;
			where x ~= . and y ~=.;
		run;
		%let annost = annotate=_PartialCorr_anno_;
	%end;
	/*
	%if %quote(&obs) ~= %then
		symbol1 pointlabel=("#&obs");;
	*/
	symbol2 interpol=join value=star pointlabel=none;	%* Pongo pointlabel=none para evitar problemas con el pointlabel de symbol1, segun estaba sugerido en el web tech support de sas;
	axis1 label=("Intercept");
	axis2 label=("&target");
	proc gplot data=_PartialCorr_toplot_ &annost;
		%* Elimino los missing de la variable respuesta, porque los valores predichos para esas observaciones
		%* no es missing y aparecerian en el grafico, si no elimino esos missing;
		where _resy_ ~= .;
		plot _resy_*_resx_=1 _resy_pred_*_resx_=2 / overlay haxis=axis1 vaxis=axis2;
	run;
	quit;
	/*
	%if %quote(&obs) ~= %then
		symbol1 pointlabel=none;;
	*/
%end;
title;

%* Generate the output dataset if requested;
%if %quote(&outplot) ~= %then %do;
	%let outplot_name = %scan(&outplot , 1 , ' ');
	%let outplot_options = %GetDataOptions(&outplot);
	data &outplot_name._Intercept(&outplot_options);
		set _PartialCorr_toplot_;
	run;
%end;

%* Partial plots for the other variables in the regression model;
proc datasets nolist;
	delete _PartialCorr_RSS_;
quit;
%do i = 1 %to &nro_vars;
	%let _var_ = %scan(&var , &i , ' ');
	%let regvar = %RemoveFromList(&var , &_var_, log=0);
	title "Partial Regression Residual Plot of %upcase(&target) and %upcase(&_var_)";
	title2 "Regression for %upcase(&target) and Intercept";
	proc reg 	data=_PartialCorr_data_
				outest=_PartialCorr_RSQ_wo_(obs=1 keep=_RSQ_ rename=(_RSQ_=RSQ_wo)) rsquare noprint;
				%** In the OUTEST dataset I use OBS=1 because there are two observations in the
				%** OUTEST dataset, since there is one for each regression performed in this
				%** PROC REG. One regression is for the target variable and the other regression
				%** is for the &_var_ variable;
		&weightst;
		where &_var_ ~= .;	%* This needs to be added so that the same observations used
							%* for the full regression are used in the regression of 
							%* &target vs &regvar. In fact, this would not be the case
							%* if &_var_ has a missing values and no other variable
							%* among those listed in &regvar has a missing.
							%* Note that this filter does not affect the regression on &_var_
							%* as response variable because they are automatically removed from
							%* the regression anyway;
		model &target &_var_ = &regvar;
		output out=_PartialCorr_pred_ r=_resy_ _resx_;
	run;
	quit;

	%* Partial regression fit (resy vs. resx);
	title2 "Regressing the partial residuals";
	proc reg 	data=_PartialCorr_pred_ 
				outest=_PartialCorr_RSQ_Partial_(keep=_RSQ_ rename=(_RSQ_=RSQ_Partial)) rsquare;
		&weightst;
		model _resy_ = _resx_ / noint;
		output out=_PartialCorr_resfit_ pred=_resy_pred_;
	run;
	quit;
	title2;

	%* RSS for the model without variable &_var_;
	%* The RSS is NOT really used but I use this step to put the values of RSQ_Partial and 
	%* RSQ_wo together;
	data _PartialCorr_RSS_i_(keep=number var RSS RSQ_Partial RSQ_wo);
		format number var;
		set _PartialCorr_pred_ end=lastobs;
		if _N_ = 1 then do;
			set _PartialCorr_RSQ_Partial_;
			set _PartialCorr_RSQ_wo_;
		end;
		length var $32;
		retain number &i;
		retain var "&_var_";
		RSS + _resy_**2;
		if lastobs;
	run;
	proc append base=_PartialCorr_RSS_ data=_PartialCorr_RSS_i_ FORCE;
	run;

	%Merge(_PartialCorr_pred_ , _PartialCorr_resfit_ , out=_PartialCorr_toplot_ , by=&obs, log=0);
	proc sort data=_PartialCorr_toplot_;
		by _resx_;
	run;

	/*------------------------------------- PLOTS -------------------------------------------*/
	%if &plot %then %do;
		%* Annotate dataset;
		%if %quote(&obs) ~= %then %do;
			data _PartialCorr_anno_(keep=xsys ysys x y function text position);
				set _PartialCorr_toplot_;
				retain xsys "2" ysys "2";
				x=_resx_; y=_resy_; function="label"; text=trim(left(put(&obs,8.))); position="2";
			run;
			data _PartialCorr_anno_;
				set _PartialCorr_anno_;
				where x ~= . and y ~=.;
			run;
			%let annost = annotate=_PartialCorr_anno_;
		%end;
	/*
		%if %quote(&obs) ~= %then
			symbol1 pointlabel=("#&obs");;
	*/
		symbol2 interpol=join value=star pointlabel=none;
		axis1 label=("&_var_");
		axis2 label=("&target");
		proc gplot data=_PartialCorr_toplot_ &annost;
			%* Elimino los missing de la variable respuesta, porque los valores predichos para esas observaciones
			%* no es missing y aparecerian en el grafico, si no elimino esos missing;
			where _resy_ ~= .;
			plot _resy_*_resx_=1 _resy_pred_*_resx_=2 / overlay haxis=axis1 vaxis=axis2;
		run;
		quit;
	/*
		%if %quote(&obs) ~= %then
			symbol1 pointlabel=none;;
	*/
	%end;
	title;

	%* Generate output dataset, if requested;
	%if %quote(&outplot) ~= %then %do;
		%let outplot_name = %scan(&outplot , 1 , ' ');
		%let outplot_options = %GetDataOptions(&outplot);
		data &outplot_name._&_var_.(&outplot_options);
			set _PartialCorr_toplot_;
		run;
		%if &log %then %do;
			%put PARTIALCORRELATION: Output dataset %upcase(&outplot_name._&_var_) created containing the necessary data;
			%put PARTIALCORRELATION: to do the partial plot for variable %upcase(&_var_).;
			%put;
		%end;
	%end;
%end;

%* Sort by descending order of the contribution to the R-Square by each variable
%* (when the others are present) so that by adding the variables in this order
%* I can compute the PERCENTAGE of the R-Square contributed by each variable in the
%* full model;
proc sort data=_PartialCorr_RSS_;
	by descending RSQ_Partial;
run;

%let regvar = ;
proc datasets nolist;
	delete _PartialCorr_RSQ_Accum_;
quit;
%do i = 1 %to &nro_vars;
	%let var_sortedR2  = %MakeListFromVar(_PartialCorr_RSS_, var=var, log=0);
	%let _var_ = %scan(&var_sortedR2, &i, ' ');
	%let regvar = &regvar &_var_;
	proc reg 	data=_PartialCorr_data_ 
				outest=_PartialCorr_RSQ_(keep=_RSQ_ rename=(_RSQ_=RSQ_Accum)) rsquare noprint;
		&weightst;
		model &target = &regvar;
	run;
	quit;
	data _PartialCorr_RSQ_;
		format number Importance;
		set _PartialCorr_RSQ_;
		Importance = &i;
	run;
	proc append base=_PartialCorr_RSQ_Accum_ data=_PartialCorr_RSQ_ FORCE;
	run;
%end;

%* Compute the relative R2 contribution by each variable. Note that the sum of the contributions
%* DO NOT sum the total R2 of the full regression, unfortunately! This is why the relative R2
%* contribution is computed w.r.t. the total R2 (&RSQ_all). However, this does not always
%* give the same order of importance of the variables as the one given by the partial R2, stored
%* in RSQ_Partial;
data _PartialCorr_RSS_;
	format number importance var RSQ_Accum RSQ_Partial RSQ_wo;
	merge _PartialCorr_RSS_ _PartialCorr_RSQ_Accum_;
	%** Note that there is no BY statement because the observations in _PartialCorr_RSQ_Accum_
	%** are in the same order as in _PartialCorr_RSS_ (sorted by ascending value of R2);
	format RSQ_pcnt percent7.1;
*	format RSS_pcnt percent7.1;
	retain RSQ_Accum_prev 0;
	%* Percent of RSQ;
	RSQ_pcnt = (RSQ_Accum - RSQ_Accum_prev) / &RSQ_all;
*	RSQ_pcnt = 1 - RSQ_wo / &RSQ_all;
	%* Percent of RSS (not really necessary);
*	RSS_pcnt = (RSS - &RSS_all) / (&RSS0 - &RSS_all);
		%** The numerator is the reduction in the Residual Sum of Squares due to the presence
		%** of the corresponding variable w.r.t. its absence.
		%** The denominator is the reduction in the Residual Sum of Squares due to the presence of
		%** all regressor variables w.r.t. the absence of all regressor variables;
%*	RSS_pcnt = 1 - (1 - (RSS - &RSS_all)/&RSS0)/R2_full;		%* Old;

	RSQ_Accum_prev = RSQ_Accum;
	label	RSQ_Partial = "Partial R-Square"
			RSQ_Accum	= "Accumulated R-Square"
			RSQ_wo 		= "R-Square w.o. the variable"
			RSQ_pcnt	= "Percentage of Total R-Square explained";
	drop RSS RSQ_Accum_prev;
run;

%if %quote(&out) ~= %then %do;
	data &out;
		set _PartialCorr_RSS_;
	run;
	%if &log %then %do;
		%let out_name = %scan(&out, 1, '(');
		%put PARTIALCORRELATION: Output dataset %upcase(&out_name) created containing the information;
		%put PARTIALCORRELATION: on the partial R-Square for each regressor variable.;
	%end;
%end;

%* Deleting temporary datasets;
proc datasets nolist;
	delete 	_PartialCorr_anno_
			_PartialCorr_data_
			_PartialCorr_pred_
			_PartialCorr_RSQ_
			_PartialCorr_RSQ_Accum_
			_PartialCorr_RSQ_Partial_
			_PartialCorr_RSS_ 
			_PartialCorr_RSS_i_
			_PartialCorr_resfit_
			_PartialCorr_toplot_;
quit;

%* Resetting the symbols;
%DefineSymbols;

%if &log %then %do;
	%put;
	%put PARTIALCORRELATION: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND PartialCorrelation;
