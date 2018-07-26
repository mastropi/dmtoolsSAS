/* MACRO %LogisticRegression
Version: 1.03
Author: Daniel Mastropietro
Created: 14-Oct-04
Modified: 03-Nov-05

DESCRIPTION:
This macro performs a logistic regression iteratively and removes influential observations
by the Cook's distance criterion at each iteration. A flag is created indicating the
observations that were detected as influential.

REQUIRED PARAMETERS:
- data

- target

- var

OPTIONAL PARAMETERS:
- class=,
- format=,			(no hace falta pasar la palabra FORMAT, simplemente los formatos)
- event=1,

- selection=backward,
- options
- nameInfluent=influent,
- ThrPValue=0.05,
- ThrPValueLarge=0.5,
- cook=1,
- ThrCook=1,
- dfbetas=0,
- ThrDFBetas=1,
- iterDFBetas=1,

- out
					default: _LR_predicted_

- outparams
					default: _LR_params_

- outest:			OUTEST dataset.
					default: _LR_test_

- macrovar=_varfinal_
- print=1
- printhist=0
- plot=0
- log=1


OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CallMacro
- %CreateVarFromList
- %Dfbetas
- %Getnobs
- %GetNroElements
- %GetVarNames
- %InsertInList
- %MakeListFromVar
- %RemoveFromList
- %ReplaceChar
- %ResetSASOptions
- %SetSASOptions
*/
%MACRO LogisticRegression(	data, 
							target=,
							var=,
							class=,
							format=,
							event=1,

							selection=backward,
							options=,
							nameInfluent=influent,
							ThrPValue=0.05,
							ThrPValueLarge=0.5,
							cook=1,
							ThrCook=1,
							dfbetas=0,
							ThrDFBetas=1,
							iterDFBetas=1,

							out=,
							outparams=,
							outest=,
							macrovar=_varfinal_,
							print=1,
							printhist=0,
							plot=0,
							log=1) / des="Logistic Regression with iterative removal of influential observations";

/* Macro that returns in macro variable _regvar_ the list of the variable names used in the
logistic regression */
%MACRO GetRegVarList0(data, target=A_Y90);
proc transpose data=&data out=_LR_temp_(rename=(&target=param));
run;
data _LR_temp_;
	set _LR_temp_;
	where _NAME_ not in ("Intercept" "_LNLIKE_") and param ~= .;
	%* Elimino espacios en el label de la variable porque esto me da el nombre de las
	%* variables categoricas. Al mismo tiempo, chequeo si el label tiene un asterisco
	%* que indica si el parametro corresponde a una interaccion entre variables.
	%* De ser asi, elimino los espacios entre los nombres y el asterisco para
	%* despues poder listar las variables con un %PrintNameList sin problema de que
	%* me separe la interaccion en dos variables y me considere el asterisco como una
	%* tercera variable por el hecho de que hay espacios entre los nombres y el asterisco;
	if ~index(_LABEL_, '*') then
		var_label = substr(_LABEL_, 1, index(_LABEL_, ' '));
	else
		var_label = compress(_LABEL_);		%* Elimino espacios cuando hay asterisco;
	%* Leo los nombres de las variables;
	if var_label ~= "" then
		var = var_label;	%* Nombre de las variables categoricas;
	else
		var = _NAME_;		%* Nombre de las variables continuas;
	obs = _N_;
run;
%* Elimino repetidos que vienen de las variables categoricas;
proc sort data=_LR_temp_ out=_LR_temp_(keep=obs var) nodupkey;
	by var;
run;
%* Vuelvo a ordenar por el orden en que las variables habian sido listadas en la regresion;
proc sort data=_LR_temp_;
	by obs;
run;
%* Genero la macro variable con la lista de variables presentes en la regresion;
%let _regvar_ = %MakeListFromVar(_LR_temp_, log=0);
%MEND GetRegVarList0;

%local _options_label_;
%local _data_name_ _out_name_ _outparams_name_ _outest_name;
%local _backward_;
%local _influentCook_ _influentDFB_;
%local _i_ _iter_ _iterInfluent_;
%local _nobs_ _nro_class_ _nro_vars_;
%local _nro_influentCook_ _nro_influentCook_iter_ _nro_influentDFB_ _nro_influentDFB_iter_; 
%local _ds_pvalues_ _pvalue_ _var_remove_;
%local _var_order_ _var_order_orig_ _var_orig_;
%local _dsid_ _rc_;
%local _ClassVal0_ _varnum_ClassVal0_ _var_class_ _varnum_Variable_ _var4dfbetas_;
/*%local _regvar_;		%* List of variable names used in the logistic regression;*/
/*						%* Its value is assigned in the macro %GetRegVarList0, defined above;*/
%local _starpos_;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put LOGISTICREGRESSION: Macro starts;
	%put;
%end;

/*------------------------------- Parsing input parameters ----------------------------------*/
%*** DATA;
%let _data_name_ = %scan(&data, 1, '(');

%*** CLASS;
%* If there are class variables passed, set the label option to LABEL, so that I can retrieve
%* the full name of the regressor variables (i.e. without the F**** truncation done by sas to 20
%* characters long!!!); 
%if %quote(&class) ~= %then %do;
	%let _options_label_ = %sysfunc(getoption(label));
	options label;
%end;

%*** SELECTION;
%let _backward_ = 0;
%if %quote(%upcase(&selection)) = BACKWARD %then %do;
	%let _backward_ = 1;
	%* Check if the largest p-value is larger than the regular p-value;
	%if %quote(&ThrPvalueLarge) ~= %then %do;
		%if %sysevalf(&ThrPvalue > &ThrPValueLarge) %then %do;
			%put LOGISTICREGRESSION: WARNING - The value of THRPVALUELARGE is smaller than THRPVALUE.;
			%put LOGISTICREGRESSION: The smallest threshold (THRPVALUE) will be set to the largest threshold (THRPVALUELARGE).;
		%end;
	%end;
%end;

%*** PLOT=;
%if &plot %then %do;
	%DefineSymbols;
%end;
/*-------------------------------------------------------------------------------------------*/

%* Model to fit;
%let model = &target = &var;
%if &log %then %do;
	%let _nro_vars_ = %GetNroElements(&var);
	%put LOGISTICREGRESSION: Model to be fitted:;
	%put TARGET:;
	%put &target;
	%put REGRESSOR VARIABLES (&_nro_vars_):;
	%do _i_ = 1 %to &_nro_vars_;
		%put %scan(&var, &_i_, ' ');
	%end;
	%if %quote(&class) ~= %then %do;
		%let _nro_class_ = %GetNroElements(&class);
		%put CATEGORICAL VARIABLES (&_nro_class_):;
		%do _i_ = 1 %to &_nro_class_;
			%put %scan(&class, &_i_, ' ');
		%end;
	%end;
	%else %do;
		%put CATEGORICAL VARIABLES:;
		%put (None);
	%end;
%end;

%* Reading in input dataset and
%* add auxiliary target variable and indicator variable for influential observation;
%* Get the order of the variables in the input dataset so that it can be restored at the end;
%let _var_order_orig_ = %GetVarNames(&data);
%* Remove any * indicating interaction from VAR so that there is no error in the KEEP= below;
%let _star_pos_ = %index(%quote(&var), *);
%let _var_orig_ = &var;
%do %while (&_star_pos_);
	%let _var_orig_ = %ReplaceChar(&_var_orig_, &_star_pos_, %quote( ));
	%let _star_pos_ = %index(&_var_orig_, *);
%end;

data _LR_data_(keep=_lr_obs_ _lr_y_ &class &_var_orig_ &nameInfluent)
	 _LR_rest_(drop=_lr_y_ &class &_var_orig_ &nameInfluent);
	set &data;
	_lr_obs_ = _N_;
	_lr_y_ = &target;
	&nameInfluent = 0;
	%* Remove the labels from the variables so that the %GetRegVarList0 macro works fine, when
	%* the full name of the regressor variables is retrieved;
	%if %quote(&class) ~= %then
		%do i = 1 %to &_nro_class_;
			label %scan(&class, &i, ' ') = " ";
		%end;
run;

%* Delete APPEND dataset with list of removed variables;
proc datasets nolist;
	delete _LR_RemovedVars_;
quit;

%let _iter_ = 0;
%let _nro_influentCook_ = 0;
%let _nro_influentDFB_ = 0;
%* When SELECTION=BACKWARD iterate eliminating non significant variables;
%do %until(~&_backward_ or %quote(&_var_remove_) =);
	%* Show the list of removed variables in last iteration, so that the user can see it
	%* while the new iteration runs;
	%if &_iter_ > 0 and &log %then %do;	
		%if %GetNroElements(&_var_remove_) > 1 %then %do;
			%put LOGISTICREGRESSION: Variables removed satisfying the large p-value threshold (&ThrPvalueLarge):;
			%do _i_ = 1 %to %GetNroElements(&_var_remove_);
				%put LOGISTICREGRESSION: %upcase(%scan(&_var_remove_, &_i_, ' ')) (p-value = %sysfunc(round(%scan(&_pvalue_, &_i_, ' '), 0.0001)));
			%end;
		%end;
		%else
			%put LOGISTICREGRESSION: Variable removed: %upcase(&_var_remove_) (p-value = %sysfunc(round(&_pvalue_, 0.0001)));
	%end;

	%* Reset variables;
	%let _iter_ = %eval(&_iter_ + 1);
	%* Variable removed because of large p-value;
	%let _var_remove_ = ;
	%* Update of the model to fit;
	%let model = &target = &var;
	%if &log %then %do;
		%put;
		%put LOGISTICREGRESSION: Iteration &_iter_;
		%put LOGISTICREGRESSION: Nro. of variables left in the model: %GetNroElements(&var);
	%end;

	%* Create an (empty) dataset where the influential observations are stored;
	data _LR_influent_;
		length _LARGEST_DFBETA_ $32;
		_lr_obs_ = .;
		%* I create the following variables in order to drop them with no error after merging
		%* the input dataset with the dataset containing the flag with the influential observations;
		_lr_cookd_ = .;
		_MAX_DFBETA_ = .;
		_LARGEST_DFBETA_ = "";
		if 0 then output;
	run;

	/* ------------------- COOK criterion for Influential Obs -------------------------------*/
	%let _iterInfluent_ = 0;
	%let _nro_influentCook_iter_ = 0;
	%let _influentCook_ = 1;
	%do %while(&_influentCook_);
		%let _iterInfluent_ = %eval(&_iterInfluent_ + 1);
		data _LR_data_;
			merge _LR_data_ _LR_influent_(in=_lr_in2_);
			by _lr_obs_;
			if _lr_in2_ then do;
				_lr_y_ = .;
				&nameInfluent = 1;
				&nameInfluent._Cook = 1;
				_lr_iter_Cook_ = &_iter_;
				_lr_Cook_ = _lr_cookd_;
			end;
			%* Drop auxiliary variables created initially in _LR_influent_;
			drop _lr_cookd_ _MAX_DFBETA_ _LARGEST_DFBETA_;
		run;

		%* Logistic regression;
		%if ~&printhist %then %do;
			ods listing exclude ALL;
		%end;
		%* I use TITLE3 and not TITLE1 because TITLE1 and TITLE2 are used below when doing
		%* the plot of the influential observations;
%*			title3 "Iteration &_iter_ , Cook Iteration = &_iterInfluent_";
		%if &log %then %do;
			%* The only difference between the two PUTs below is the spaces at the beginning...
			%* to avoid confusion when reading the log.;
			%if &cook %then
				%put %quote(    LOGISTICREGRESSION: Performing Logistic Regression...);
			%else
				%put %quote(LOGISTICREGRESSION: Performing Logistic Regression...);
		%end;
		proc logistic data=_LR_data_ outest=_LR_outest_ namelen=32;
			%if %quote(&format) ~= %then %do;
			format &format;
			%end;
			class &class / param=ref;
			model _lr_y_(event="&event") = &var / &options;
			output out=_LR_predicted_ pred=_lr_p_ reschi=_lr_res_ cbar=_lr_cookd_ h=_lr_h_;
		ods output ParameterEstimates=_LR_params_;
		%let _ds_pvalues_ = _LR_params_;	%* Name of the dataset containing the p-values;
		%if %quote(&class) ~= %then %do;
		%* If there are class variables, I need to look at the p-values of the Type III
		%* analysis of effects, not at the parameter estimates, in order to eliminate variables;
		%* Note that the TypeIII table is not created by the PROC LOGISTIC unless there are
		%* variables listed in the CLASS statement;
		ods output TypeIII=_LR_TypeIII_;
		%end;
		run;
		%* Change the name of the dataset containing the p-values when the TYPEIII Analysis of
		%* Effect was created;
		%if %sysfunc(exist(_LR_TypeIII_)) %then
			%let _ds_pvalues_ = _LR_TypeIII_;		%* Name of the dataset containing the p-values;
		%if ~&printhist %then %do;
			ods listing;
		%end;

		%* Correct the name of the variables in case they are more than 20 characters
		%* long because the names are truncated to 20 characters in the ODS ParameterEstimates
		%* dataset!!!!!($&*@&*#^$&*#@#();
		%* But this only works when there are NO class variables, because the names in the
		%* OUTEST dataset will have the level information too, which are not presetn in the
		%* ODS TypeIII dataset;
		/* 13/3/05: Ya no hace falta este data step porque uso la macro %GetRegVarList0;
		data _LR_vars_(keep=param variable);
			format param;
			length variable $32;
			length vart $20;
			set _LR_outest_(keep=&var);
			array vars{*} &var;
			%* Output the name of the intercept;
			param = 0;
			variable = "Intercept";
			output;
			%* Output the name of the other parameters;
			do param = 1 to dim(vars);
				variable = vname(vars(param));
				output;
			end;
		run;
		*/
		%* Get the variable names from dataset OUTEST;
/*		%GetRegVarList0(_LR_outest_, target=_lr_y_);*/
		%GetRegVarList(_LR_outest_, log=0);
		%CreateVarFromList(&_regvar_, out=_LR_vars_, log=0);
		data _LR_vars_;
			format param;
			set _LR_vars_;
			param = _N_;
			rename name = var;
		run;
		%* Add an observation number to dataset &_ds_pvalues_ so that I can merge
		%* with dataset _LR_vars_ (already transposed above);
		data &_ds_pvalues_;
			format param;
			length var $32;
			set &_ds_pvalues_/*(rename=(variable=var))*/;
			%if %upcase(&_ds_pvalues_) = _LR_PARAMS_ %then %do;
			param = _N_ - 1;	%* In _LR_Params_ there is the Intercept too, which should be eliminated;
			%end;
			%else %do;
			param = _N_;
			%end;
			drop var;
		run;
		%* Merge with the dataset _LR_vars_ which contains the full variable names. Note that
		%* if the observation does not come from _LR_vars_ it means that the parameter
		%* corresponds to the intercept, and thus the value for VAR is set to INTERCEPT;
		%Merge(	&_ds_pvalues_, _LR_vars_, out=&_ds_pvalues_(drop=param), by=param, 
				condition=if in1 and ~in2 then var="Intercept", format=var, log=0);

		%if ~&cook %then
			%let _influentCook_ = 0;
		%else %do;
			%if &log %then
				%put %quote(    LOGISTICREGRESSION: Influential Observations by Cook - Iteration &_iterInfluent_);

			%* Plot Cook Distance if requested;
			%if &plot %then %do;
				data _LR_predicted_;
					set _LR_predicted_;
					_lr_influent_ = _lr_cookd_ > &ThrCook;
				run;
				data _LR_anno_(keep=xsys ysys x y function text color position);;
					format xsys ysys x y function text position;
					set _LR_predicted_(keep=_lr_obs_ _lr_h_ _lr_cookd_);
					length function $8 text $8 color $5;		%* length of text is 8 to allow for different length of its value;
					retain xsys "2" ysys "2" position "2";
					if _lr_cookd_ > &ThrCook then do;
						function = "label";
						text = trim(left(put(_lr_obs_, 8.)));
						color = "black";
						output;
					end;
					rename 	_lr_h_ = x
							_lr_cookd_ = y;
				run;
				title1 "Cook's distance vs. Leverage for %upcase(&_data_name_)";
				title2 "Model: &model";
				footnote "Label is observation number of influential observations";
				legend value=("Not Influent" "Influent");
				axis1 label=("Leverage");
				axis2 label=("Cook's Distance");
				proc gplot data=_LR_predicted_ annotate=_LR_anno_;
					plot _lr_cookd_*_lr_h_=_lr_influent_ / haxis=axis1 vaxis=axis2 legend=legend;
				run;
				quit;
				title2;
				title1;
				footnote;
			%end;
%*			title3;

			%* Cook Distance criterion to detect influential observations;
			data _LR_influent_;
				set _LR_predicted_(keep=_lr_obs_ _lr_cookd_);
				length _LARGEST_DFBETA_ $32;
				if _lr_cookd_ > &ThrCook;
				_MAX_DFBETA_ = .;
				_LARGEST_DFBETA_ = "";
			run;

			%* Get number of influential observations detected in this step;
			%Callmacro(getnobs, _LR_influent_ return=1, _nobs_);
			%if &_nobs_ > 0 %then
				%let _nro_influentCook_iter_ = %eval(&_nro_influentCook_iter_ + &_nobs_);
			%else
				%let _influentCook_ = 0;	%* No more influential observations detected;

			%if &log %then
				%put %quote(    LOGISTICREGRESSION: Nro. of influential obs. with CookD > &ThrCook: &_nobs_);
		%end;
	%end;
	%* Update total number of influential observartions detected in all iterations performed
	%* in the detection of influential observations so far;
	%let _nro_influentCook_ = %eval(&_nro_influentCook_ + &_nro_influentCook_iter_);
	/*---------------------------------------------------------------------------------------*/

	/* --------------------- DFBETAS criterion for Influential Obs --------------------------*/
	%if &dfbetas %then %do;
		%let _iterInfluent_ = 0;
		%let _nro_influentDFB_iter_ = 0;
		%let _influentDFB_ = 1;
		%if &log %then %do;
			%put;
			%put %quote(    LOGISTICREGRESSION: Detecting influent observations with DFBETAS...);
		%end;
		%do %while(&_influentDFB_);
			%let _iterInfluent_ = %eval(&_iterInfluent_ + 1);
			%if &log %then
				%put %quote(    LOGISTICREGRESSION: Influential Observations by DFBETAS - Iteration &_iterInfluent_);
			%* Update influential observations;
			%let _var_order_ = %GetVarNames(_LR_data_);
			data _LR_data_;
				%if &cook %then %do;
				format %InsertInList(&_var_order_ , &nameInfluent._dfb, after, _lr_Cook_);
				%end;
				merge _LR_data_ _LR_influent_(in=_lr_in2_);
				by _lr_obs_;
				if _lr_in2_ then do;
					_lr_y_ = .;
					&nameInfluent = 1;
					&nameInfluent._dfb = 1;
					_lr_iter_dfb_ = &_iter_;
					_lr_max_dfbeta_ = _MAX_DFBETA_;
					_lr_largest_dfbeta_ = _LARGEST_DFBETA_;
				end;
				%* Drop auxiliary variables created initially in _LR_influent_;
				drop _lr_cookd_ _MAX_DFBETA_ _LARGEST_DFBETA_;
			run;
			%* Logistic Regression;
			%if ~&printhist %then %do;
				ods listing exclude ALL;
			%end;
			proc logistic data=_LR_data_ outest=_LR_outest_ namelen=32;
				%if %quote(&format) ~= %then %do;
				format &format;
				%end;
				class &class / param=ref;
				model _lr_y_(event="&event") = &var / &options;
				output out=_LR_predicted_ pred=_lr_p_ reschi=_lr_res_ cbar=_lr_cookd_ h=_lr_h_ dfbetas=_ALL_;
			ods output ParameterEstimates=_LR_params_;
			%let _ds_pvalues_ = _LR_params_;	%* Name of the dataset containing the p-values;
			%if %quote(&class) ~= %then %do;
			%* If there are class variables, I need to look at the p-values of the Type III
			%* analysis of effects, not at the parameter estimates, in order to eliminate variables;
			%* Note that the TypeIII table is not created by the PROC LOGISTIC unless there are
			%* variables listed in the CLASS statement;
			ods output TypeIII=_LR_TypeIII_;
			%end;
			run;
			%* Change the name of the dataset containing the p-values when the TYPEIII Analysis of
			%* Effect was created;
			%if %sysfunc(exist(_LR_TypeIII_)) %then
				%let _ds_pvalues_ = _LR_TypeIII_;		%* Name of the dataset containing the p-values;
			%if ~&printhist %then %do;
				ods listing;
			%end;

			%* Prepare the list of variables for macro %Dfbetas when there are class variables,
			%* since in this case there is one DFBETA for each level of the class variable.
			%* If there are interactions between class variables, the Dfbetas on the interactions
			%* are not analyzed;
			%let _var4dfbetas_ = &var;
			%if %quote(&class) ~= %then %do;
				proc transpose 	data=_LR_outest_(drop=_LNLIKE_)
								out=_LR_outest_t_(rename=(_NAME_=var));
				run;
				%let _var4dfbetas_ = %MakeListFromVar(_LR_outest_t_, var=var, log=0);
			%end;
			%* Creo la lista de variables conteniendo los DFBETAS;
			%let _var4dfbetas_ = %MakeList(&_var4dfbetas_, prefix=dfbeta_);
/* 2005/03/13: Can delete, since the following was wrong.
			%let _var4dfbetas_ = &var;
			%if %quote(&class) ~= %then %do;
				%let _dsid_ = %sysfunc(open(_LR_params_));
				%let _nobs_ = %sysfunc(attrn(&_dsid_, nobs));
				%* Variable number of VARIABLE (containing the variable names) and CLASSVAL0 (containing the variable levels);
				%let _varnum_Variable_ = %sysfunc(varnum(&_dsid_, Variable));
				%let _varnum_ClassVal0_ = %sysfunc(varnum(&_dsid_, ClassVal0));
				%let _var_class_ = ;
				%do _i_ = 1 %to &_nobs_;
					%let _rc_ = %sysfunc(fetchobs(&_dsid_, &_i_));
					%let _ClassVal0_ = %left(%qtrim(%sysfunc(getvarc(&_dsid_, &_varnum_ClassVal0_))));
					%if %quote(&_ClassVal0_) ~= %then
	   					%let _var_class_ = &_var_class_ %qtrim(%sysfunc(getvarc(&_dsid_, &_varnum_Variable_)))&_ClassVal0_;
				%end;
				%let _rc_ = %sysfunc(close(&_dsid_));
				%* List of variables to use in macro %Dfbetas;
				%let _var4dfbetas_ = %RemoveFromList(&var, &class, log=0) &_var_class_;
			%end;
*/
			%* Correct the name of the variables in case they are more than 20 characters
			%* long because the names are truncated to 20 characters in the ODS ParameterEstimates
			%* dataset!!!!!($&*@&*#^$&*#@#();
			%* But this only works when there are NO class variables, because the names in the
			%* OUTEST dataset will have the level information too, which are not presetn in the
			%* ODS TypeIII dataset;
			/* 13/3/05: Ya no hace falta este data step porque uso la macro %GetRegVarList0;
			data _LR_vars_(keep=param variable);
				format param;
				length variable $32;
				length vart $20;
				set _LR_outest_(keep=&var);
				array vars{*} &var;
				%* Output the name of the intercept;
				param = 0;
				variable = "Intercept";
				output;
				%* Output the name of the other parameters;
				do param = 1 to dim(vars);
					variable = vname(vars(param));
					output;
				end;
			run;
			*/
			%* Get the variable names from dataset OUTEST;
/*			%GetRegVarList0(_LR_outest_, target=_lr_y_);*/
			%GetRegVarList(_LR_outest_, log=0);
			%CreateVarFromList(&_regvar_, out=_LR_vars_, log=0);
			data _LR_vars_;
				format param;
				set _LR_vars_;
				param = _N_;
				rename name = var;
			run;
			%* Add an observation number to dataset _LR_params_;
			data &_ds_pvalues_;
				format param;
				length var $32;
				set &_ds_pvalues_/*(rename=(variable=var))*/;
				%if %upcase(&_ds_pvalues_) = _LR_PARAMS_ %then %do;
				param = _N_ - 1;	%* In _LR_Params_ there is the Intercept too, which should be eliminated;
				%end;
				%else %do;
				param = _N_;
				%end;
				drop var;
			run;
			%* Merge with the dataset _LR_vars_ which contains the full variable names. Note that
			%* if the observation does not come from _LR_vars_ it means that the parameter
			%* corresponds to the intercept, and thus the value for VAR is set to INTERCEPT;
			%Merge(	&_ds_pvalues_, _LR_vars_, out=&_ds_pvalues_(drop=param), by=param,
					condition=if in1 and ~in2 then var="Intercept", format=var, log=0);

			%Dfbetas(_LR_predicted_, dfbetas=&_var4dfbetas_, obs=_lr_obs_, thr=&thrDFBetas, iter=&iterDFBetas, nameInfluent=_lr_influent_, plot=0, log=0);
			data _LR_influent_(drop=_lr_influent_);
				set _LR_predicted_(keep=_lr_influent_ _lr_obs_ _lr_cookd_ _MAX_DFBETA_ _LARGEST_DFBETA_);
				where _lr_influent_;
			run;

			%* Get number of influential observations detected in this step;
			%Callmacro(getnobs, _LR_influent_ return=1, _nobs_);
			%if &_nobs_ > 0 %then
				%let _nro_influentDFB_iter_ = %eval(&_nro_influentDFB_iter_ + &_nobs_);
			%else
				%let _influentDFB_ = 0;	%* No more influential observations detected;

			%if &log %then
				%put %quote(    LOGISTICREGRESSION: Nro. of influential obs. detected with DFBETA criterion: &_nobs_);
		%end;
		%* Update total number of influential observartions detected in all iterations performed
		%* in the detection of influential observations so far;
		%let _nro_influentDFB_ = %eval(&_nro_influentDFB_ + &_nro_influentDFB_iter_);
	%end;
	/*---------------------------------------------------------------------------------------*/

	%* Total nro. of influential observations detected in current iteration;
	%if &log and &cook or &dfbetas %then %do;
		%put;
		%put %quote(    LOGISTICREGRESSION: ITER &_iter_ - Total nro. of influential obs. detected with);
		%if &cook %then
			%put %quote(    LOGISTICREGRESSION: Cook Distance criterion: &_nro_influentCook_iter_);
		%if &dfbetas %then
			%put %quote(    LOGISTICREGRESSION: DFBETA criterion: &_nro_influentDFB_iter_);
	%end;

	%* If SELECTION=BACKWARD remove the least significant variable from the model, or the many
	%* non-significant variables whose p-values is larger than THRPVALUELARGE;
	%if &_backward_ %then %do;
		%if %sysevalf(&ThrPValueLarge > 0) and %sysevalf(&ThrPValueLarge < 1) %then %do;
			data _LR_RemovedVars_iter_;
				set &_ds_pvalues_;
				where upcase(var) ~= "INTERCEPT" and ProbChiSq > &ThrPvalueLarge;
					%* The filter for the intercept is to avoid having the Intercept removed for large p-value;
			run;
			%* Sort by descending p-value;
			proc sort data=_LR_RemovedVars_iter_;
				by descending ProbChiSq;
			run;
			%let _var_remove_ = %MakeListFromVar(_LR_RemovedVars_iter_, var=var, log=0);
		%end;
		%if %quote(&_var_remove_) = %then %do;
			%* If no variables were found satisfying the condition of the large p-value threshold
			%* remove from the model THE variable with the largest p-value;
			proc means data=&_ds_pvalues_ max noprint;
				where upcase(var) ~= "INTERCEPT";	%* So that the Intercept is not chosen for removal;
				var ProbChiSq;
				output out=_LR_max_pvalue_(drop=_TYPE_ _FREQ_) maxid(ProbChiSq(var))=var max=pvalue;
			run;
			data _LR_RemovedVars_iter_;
				format _lr_iter_ var pvalue;
				length var $32;
				set _LR_max_pvalue_;
				_lr_iter_ = &_iter_;
				call symput ('_var_remove_', var);
				call symput ('_pvalue_', pvalue);
				if pvalue > &ThrPValue then output;
				%** Output to the dataset so that the information of the variable with the largest
				%** p-value can be appended to _LR_RemovedVars_;
			run;
		%end;
		%else %do;
			%* Add the iteration and the p-value information to the dataset containing the
			%* list of removed variables with p-value larger than THRPVALUELARGE;
			data _LR_RemovedVars_iter_;
				format _lr_iter_ var ProbChiSq;
				length var $32;
				set _LR_RemovedVars_iter_(keep=var ProbChiSq);
				_lr_iter_ = &_iter_;
				rename ProbChiSq = pvalue;
			run;
			%* List of p-values of each variable to be removed;
			%let _pvalue_ = %MakeListFromVar(_LR_RemovedVars_iter_, var=pvalue, log=0);
		%end;			
		proc append base=_LR_RemovedVars_ data=_LR_RemovedVars_iter_ FORCE;
		run;

		%* Remove variable with large p-values from the list of regressor variables;
		%if %GetNroElements(&_var_remove_) > 1 or
			%sysevalf(%scan(&_pvalue_, 1, ' ') > &ThrPValue) %then %do;
			%let var = %RemoveFromList(&var, &_var_remove_, log=0);
		%end;
		%else %do;
			%if &log %then %do;
				%* The QTRIM function below is necessary because when the p-value is missing
				%* there are trailing blanks at the beginning;
				%if %quote(%qtrim(&_pvalue_)) ~= . %then
					%put LOGISTICREGRESSION: No variables are removed: Max p-value (%upcase(&_var_remove_)) = %sysfunc(round(&_pvalue_, 0.0001)) < &ThrPValue;
				%else
					%put LOGISTICREGRESSION: No variables are removed: Max p-value (%upcase(&_var_remove_)) = . < &ThrPValue;
			%end;
			%put;
			%let _var_remove_ = ;
		%end;
	%end;

	%if &log %then %do;
		%put LOGISTICREGRESSION: Variables kept in the model:;
		%if %GetNroElements(&var) > 0 %then
			%do _i_ = 1 %to %GetNroElements(&var);
				%put &_i_: %scan(&var, &_i_, ' ');
			%end;
		%else
			%put (None);
	%end;
%end;

%* Delete global macro variable _regvar_ created in %GetRegVarList;
%symdel _regvar_;

%if &log and &_backward_ %then %do;
	%put;
	%put LOGISTICREGRESSION: Total nro. of influential obs. detected with Cook Distance criterion: &_nro_influentCook_;
	%put LOGISTICREGRESSION: Total nro. of influential obs. detected with DFBETA criterion: &_nro_influentDFB_;
%end;

%*** Create output datasets;
%* Predicted values and residuals;
%if %quote(&out) = %then
	%let out = _LR_predicted_;
%* Read the order of the variables in _LR_predicted_ so that I can set the order of the new
%* variables created;
%let _var_order_ = %GetVarNames(_LR_predicted_);
%* Merge with the rest of the data that was left out at the beginning (_LR_rest_);
data &out;
	%if &dfbetas %then %do;
%* 1-DM-2005/03/13: Use this format to restore the order of the original variables present in
%* the input dataset. I sacrifice the position of _lr_cookd_ as I do below;
	format &_var_order_orig_;
	%* Put the CookD calculated at the last logistic regression before _lr_h_ and
	%* drop variables created by macro %Dfbetas that do not give any information because
	%* in the last iteration, no influential observations were detected;
%*	format %InsertInList(&_var_order_ , _lr_cookd_, before, _lr_h_);
%* 2-DM-2005/03/13;
	merge _LR_rest_
		  _LR_predicted_(drop=_lr_influent_ _THRESHOLD_ _MAX_DFBETA_ _NRO_LARGE_DFBETAS_ _LARGEST_DFBETA_);
	%end;
	%else %do;
	merge _LR_rest_
		  _LR_predicted_;
	%end;
	by _lr_obs_;
	drop _lr_obs_;
run;

%if &log %then %do;
	%let _out_name_ = %scan(&out, 1, '(');
	%put;
	%put LOGISTICREGRESSION: Output dataset %upcase(&_out_name_) created with the predicted values and residuals.;
%end;

%* Parameter estimates;
%if %quote(&outparams) = %then
	%let outparams = _LR_params_;
data &outparams;
	set _LR_params_;
	format logp 10.1;
	if ProbChiSq > 0 then
		logp = -log(ProbChiSq);
	else
		logp = .;
	label logp = "-Log(ProbChiSq)";
run;
%if &log %then %do;
	%let _outparams_name_ = %scan(&outparams, 1, '(');
	%put;
	%put LOGISTICREGRESSION: Output dataset %upcase(&_outparams_name_) created with the estimated parameters.;
%end;

%* Outest dataset;
%if %quote(&outest) = %then
	%let outest = _LR_outest_;
data &outest;
	set _LR_outest_;
run;
%if &log %then %do;
	%let _outest_name_ = %scan(&outest, 1, '(');
	%put;
	%put LOGISTICREGRESSION: Output dataset %upcase(&_outest_name_) created as the OUTEST dataset.;
%end;

%* Show results of the final logistic regression in the output window if requested;
%if %quote(&print) %then %do;
	%local _options_notes_;
	%let _options_notes_ = %sysfunc(getoption(notes));
	options notes;
	title "Final Regression";
	proc logistic data=_LR_data_ namelen=32;
		%if %quote(&format) ~= %then %do;
		format &format;
		%end;
		class &class / param=ref;
		model _lr_y_(event="&event") = &var / &options;
	run;
	title;
	options &_options_notes_;
%end;

%if %quote(&macrovar) ~= %then %do;
	%global &macrovar;
	%let &macrovar = &var;
	%if &log %then %do;
		%put;
		%put LOGISTICREGRESSION: Global macro variable %upcase(&macrovar) created with the variables kept in the model.;
	%end;
%end;

%* Restore the LABEL option;
%if %quote(&class) ~= %then %do;
	options &_options_label_;
%end;

proc datasets nolist;
	delete	_LR_anno_
			_LR_data_
			_LR_influent_
			_LR_max_pvalue_
			_LR_params_class_
			_LR_outest_t_
			_LR_RemovedVars_
			_LR_RemovedVars_iter_
			_LR_Rest_
			_LR_Temp_
			_LR_TypeIII_
			_LR_vars_;
	%if %quote(&out) ~= and %quote(%upcase(&out)) ~= _LR_PREDICTED_ %then %do;
	delete _LR_predicted_;
	%end;
	%if %quote(&outparams) ~= and %quote(%upcase(&outparams)) ~= _LR_PARAMS_ %then %do;
	delete _LR_params_;
	%end;
	%if %quote(&outest) ~= and %quote(%upcase(&outest)) ~= _LR_OUTEST_ %then %do;
	delete _LR_outest_;
	%end;
quit;

%if &log %then %do;
	%put;
	%put LOGISTICREGRESSION: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND LogisticRegression;
