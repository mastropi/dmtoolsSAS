/* MACRO %PartialPlots
Version: 1.00
Author: Daniel Mastropietro
Created: 1-Oct-2003
Modified: 12-Jan-05

DESCRIPTION:
This macro generates partial plots (in principle for a linear regression model).

USAGE:
%PartialPlots(data , target=, var= , obs= , weight= , out=);

REQUIRED PARAMETERS:
- data:			Input dataset used in the regression.

- obs:			Name of the variable containing the observation number.
				(This is required but the idea is to change it to optional in the future.)

OPTIONAL PARAMETERS:
- target:		Target variable used in the regression.

- var:			List of regression variables.

- weight:		Weight variable used in the regression.

- out:			Name to use as the root of the output datasets that contain  the data needed
				to do the partial plots for each variable. The names of the output datasets
				are of the form: <out>_Intercept (partial plot for the intercept) and 
				<out>_<var>, where <var> is the name of each regression variable analyzed.

NOTES:
The observation number is used to label the points.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %DefineSymbols
- %GetDataOptions
- %GetNroElements
- %GetVarList
- %Merge
- %RemoveFromList
- %ResetSASOptions
- %SetSASOptions
*/
%MACRO PartialPlots(data , target=, var= , obs= , weight= , out=, outplot=, plot=0, log=1)
		/ des="Use %PartialCorrelation instead";
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

%* Partial plot for the intercept (see example in "Influence Diagnostics" under the "Details" section of 
%* the REG procedure in the SAS Manuals);
data _PartialPlots_data_;
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
%* (_PartialPlots_data_) to avoid problems when there are KEEP or DROP options coming with the
%* input dataset are contradictory with the list of variables to be analyzed (for ex.
%* %PartialPlots(data(keep=obs x z), target=y, var=x z w). Clearly variable W will not be
%* found in the local input dataset _PartialPlots_data_ because it is not kept! In order to
%* detect this, the parsing of the VAR= parameter needs to be done AFTER the input dataset
%* was read into a local dataset;
%*** VAR=;
%let nro_vars = %GetNroElements(&var);

%let regvar = &var;
%* Linear regression with ALL the variables to compute RSS for the full model;
proc reg data=_PartialPlots_data_ outest=_PartialPlots_RSQ_(keep=_RSQ_ rename=(_RSQ_=RSQ)) rsquare;
	&weightst;
	model &target = &regvar;
%let var = %GetVarList(_PartialPlots_data_, var=&var, log=0);
	output out=_PartialPlots_pred_(keep=&target residual) residual=residual;
run;
quit;
data _NULL_;
	if _N_ = 1 then set _PartialPlots_RSQ_;
	set _PartialPlots_pred_ end=lastobs;
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
proc reg data=_PartialPlots_data_ noprint;
	&weightst;		%*** Notar que aqui tambien va el weight statement, como en la regresion original;
	model &target _int_ = &regvar / noint;
	output out=_PartialPlots_pred_ r=_resy_ _resx_;
		%*** Notar la opcion r= en lugar de rstudent=. De hecho  aqui hay que calcular los residuos a secas,
		%*** no los studentizados, para que el estimador de la pendiente sea el mismo que en el de la 
		%*** regresion original;
run;
quit;

%* Partial regression fit (resy vs. resx);
title2 "Regressing the partial residuals";
proc reg data=_PartialPlots_pred_;
	&weightst;							%*** VA EL WEIGHT PARA ESTA REGRESION??? (SI: Verificado con los partial plots del PROC REG);
	model _resy_ = _resx_ / noint;		%*** VA EL NOINT? SI: no hace falta estimar el intercept por que da 0 (del orden de 1e-14 por ejemplo), ya que el promedio de los residuos _resy_ es 0, por ser residuos de una regresion lineal con intercept;
	output out=_PartialPlots_resfit_ pred=_resy_pred_;
run;
quit;
%Merge(_PartialPlots_pred_ , _PartialPlots_resfit_ , out=_PartialPlots_toplot_ , by=&obs, log=0);
proc sort data=_PartialPlots_toplot_;
	by _resx_;
run;
/*---------------------------------------- PLOT ---------------------------------------------*/
%if &plot %then %do;
	%* Annotate dataset;
	%if %quote(&obs) ~= %then %do;
		%* Notar el trim(left()) aplicado a la variable con la observacion, para que el label quede centrado sobre el punto;
		data _PartialPlots_anno_(keep=xsys ysys x y function text position);
			set _PartialPlots_toplot_;
			retain xsys "2" ysys "2";
			x=_resx_; y=_resy_; function="label"; text=trim(left(put(&obs,8.))); position="2";
		run;
		data _PartialPlots_anno_;
			set _PartialPlots_anno_;
			where x ~= . and y ~=.;
		run;
		%let annost = annotate=_PartialPlots_anno_;
	%end;
	/*
	%if %quote(&obs) ~= %then
		symbol1 pointlabel=("#&obs");;
	*/
	symbol2 interpol=join value=star pointlabel=none;	%* Pongo pointlabel=none para evitar problemas con el pointlabel de symbol1, segun estaba sugerido en el web tech support de sas;
	axis1 label=("Intercept");
	axis2 label=("&target");
	proc gplot data=_PartialPlots_toplot_ &annost;
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
	title;
%end;

%* Generate the output dataset if requested;
%if %quote(&outplot) ~= %then %do;
	%let outplot_name = %scan(&outplot , 1 , ' ');
	%let outplot_options = %GetDataOptions(&outplot);
	data &outplot_name._Intercept(&outplot_options);
		set _PartialPlots_toplot_;
	run;
%end;

%* Partial plots for the other variables in the regression model;
proc datasets nolist;
	delete _PartialPlots_RSS_;
quit;
%do i = 1 %to &nro_vars;
	%let _var_ = %scan(&var , &i , ' ');
	%let regvar = %RemoveFromList(&var , &_var_, log=0);
	title "Partial Regression Residual Plot of %upcase(&target) and %upcase(&_var_)";
	title2 "Regression for %upcase(&target) and Intercept";
	proc reg 	data=_PartialPlots_data_
				outest=_PartialPlots_RSQ_wo_(obs=1 keep=_RSQ_ rename=(_RSQ_=RSQ_wo)) rsquare noprint;
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
		output out=_PartialPlots_pred_ r=_resy_ _resx_;
	run;
	quit;

	%* Partial regression fit (resy vs. resx);
	title2 "Regressing the partial residuals";
	proc reg 	data=_PartialPlots_pred_ 
				outest=_PartialPlots_RSQ_Partial_(keep=_RSQ_ rename=(_RSQ_=RSQ_Partial)) rsquare;
		&weightst;
		model _resy_ = _resx_ / noint;
		output out=_PartialPlots_resfit_ pred=_resy_pred_;
	run;
	quit;
	title2;

	%* RSS for the model without variable &_var_;
	%* The RSS is NOT really used but I use this step to put the values of RSQ_Partial and 
	%* RSQ_wo together;
	data _PartialPlots_RSS_i_(keep=number var RSS RSQ_Partial RSQ_wo);
		format number var;
		set _PartialPlots_pred_ end=lastobs;
		if _N_ = 1 then do;
			set _PartialPlots_RSQ_Partial_;
			set _PartialPlots_RSQ_wo_;
		end;
		length var $32;
		retain number &i;
		retain var "&_var_";
		RSS + _resy_**2;
		if lastobs;
	run;
	proc append base=_PartialPlots_RSS_ data=_PartialPlots_RSS_i_ FORCE;
	run;

	%Merge(_PartialPlots_pred_ , _PartialPlots_resfit_ , out=_PartialPlots_toplot_ , by=&obs, log=0);
	proc sort data=_PartialPlots_toplot_;
		by _resx_;
	run;

	/*------------------------------------- PLOTS -------------------------------------------*/
	%if &plot %then %do;
		%* Annotate dataset;
		%if %quote(&obs) ~= %then %do;
			data _PartialPlots_anno_(keep=xsys ysys x y function text position);
				set _PartialPlots_toplot_;
				retain xsys "2" ysys "2";
				x=_resx_; y=_resy_; function="label"; text=trim(left(put(&obs,8.))); position="2";
			run;
			data _PartialPlots_anno_;
				set _PartialPlots_anno_;
				where x ~= . and y ~=.;
			run;
			%let annost = annotate=_PartialPlots_anno_;
		%end;
	/*
		%if %quote(&obs) ~= %then
			symbol1 pointlabel=("#&obs");;
	*/
		symbol2 interpol=join value=star pointlabel=none;
		axis1 label=("&_var_");
		axis2 label=("&target");
		proc gplot data=_PartialPlots_toplot_ &annost;
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
		title;
	%end;

	%* Generating output dataset, if requested;
	%if %quote(&outplot) ~= %then %do;
		%let outplot_name = %scan(&outplot , 1 , ' ');
		%let outplot_options = %GetDataOptions(&outplot);
		data &outplot_name._&_var_.(&outplot_options);
			set _PartialPlots_toplot_;
		run;
	%end;
%end;

%* Sort by descending order of the contribution to the R-Square by each variable
%* (when the others are present) so that by adding the variables in this order
%* I can compute the PERCENTAGE of the R-Square contributed by each variable in the
%* full model;
proc sort data=_PartialPlots_RSS_;
	by descending RSQ_Partial;
run;

%let regvar = ;
proc datasets nolist;
	delete _PartialPlots_RSQ_Accum_;
quit;
%do i = 1 %to &nro_vars;
	%let var_sortedR2  = %MakeListFromVar(_PartialPlots_RSS_, var=var, log=0);
	%let _var_ = %scan(&var_sortedR2, &i, ' ');
	%let regvar = &regvar &_var_;
	proc reg 	data=_PartialPlots_data_ 
				outest=_PartialPlots_RSQ_(keep=_RSQ_ rename=(_RSQ_=RSQ_Accum)) rsquare noprint;
		&weightst;
		model &target = &regvar;
	run;
	quit;
	data _PartialPlots_RSQ_;
		format number Importance;
		set _PartialPlots_RSQ_;
		Importance = &i;
	run;
	proc append base=_PartialPlots_RSQ_Accum_ data=_PartialPlots_RSQ_ FORCE;
	run;
%end;

%* Compute R2 contribution by each variable. Note that the sum of the contributions DO NOT
%* sum the total R2 of the full regression, unfortunately!;
data _PartialPlots_RSS_;
	merge _PartialPlots_RSS_ _PartialPlots_RSQ_Accum_;
	%** Note that there is no BY statement because the observations in _PartialPlots_RSQ_Accum_
	%** are in the same order as in _PartialPlots_RSS_ (sorted by ascending value of R2);
	format RSQ_pcnt RSS_pcnt percent7.1;
	retain RSQ_prev 0;
	%* Percent of RSQ;
	RSQ_pcnt = (RSQ_Accum - RSQ_prev) / &RSQ_all;
*	RSQ_pcnt = 1 - RSQ_wo / &RSQ_all;
	%* Percent of RSS;
	RSS_pcnt = (RSS - &RSS_all) / (&RSS0 - &RSS_all);
		%** The numerator is the reduction in the Residual Sum of Squares due to the presence
		%** of the corresponding variable w.r.t. its absence.
		%** The denominator is the reduction in the Residual Sum of Squares due to the presence of
		%** all regressor variables w.r.t. the absence of all regressor variables;
%*	RSS_pcnt = 1 - (1 - (RSS - &RSS_all)/&RSS0)/R2_full;		%* Old;

	RSQ_prev = RSQ_Accum;
	label	RSQ_Partial = "Partial R-Square"
			RSQ_Accum	= "Accumulated R-Square"
			RSQ_wo 		= "R-Square w.o. the variable";
	drop RSQ_prev;
run;

%if %quote(&out) ~= %then %do;
	data &out;
		set _PartialPlots_RSS_;
	run;
%end;

%* Deleting temporary datasets;
proc datasets nolist;
	delete 	_PartialPlots_anno_
			_PartialPlots_data_
			_PartialPlots_pred_
			_PartialPlots_RSQ_
			_PartialPlots_RSQ_Accum_
			_PartialPlots_RSQ_Partial_
			_PartialPlots_RSS_ 
			_PartialPlots_RSS_i_
			_PartialPlots_resfit_
			_PartialPlots_toplot_;
quit;

%* Resetting the symbols;
%DefineSymbols;

%if &log %then %do;
	%put;
	%put PARTIALCORRELATION: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND PartialPlots;
