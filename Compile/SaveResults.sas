/* MACRO %SaveResults
Version: 1.00
Author: Daniel Mastropietro
Created: 10-Oct-05
Modified: 25-Oct-05

DESCRIPTION:

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CreateVarFromList
- %ExistVar
- %Export
- %FindMatch
- %FixNames
- %GetNroElements
- %GetRegVarList
- %InsertInList
- %KeepInList
- %Means
- %Merge

AGREGAR:
- Calcular el nro. de observaciones eliminadas del desarrollo por outliers e influyentes.
Usar para esto la segunda variable listada en la macro variable TARGETS, que es la que se
supone se uso en el modelo.

- Calcular el residuo estandarizado para las cuentas NO usadas en TRAINING. Habria que ver
La formula es (y - p)/sqrt(p*(1-p)) (ya fue verificada contra la que calcula sas en el proc logistic).

SUPUESTOS:
- Para generar todas las salidas es necesario haber generado las siguientes salidas
en el PROC LOGISTIC:
	- PROC LOGISTIC outest=
	- OUTPUT out=
	- ODS OUTPUT ParameterEstimates=
	- ODS OUTPUT TypeIII=
*/
&rsubmit;
%MACRO SaveResults(
		/* Target information */
		targets,			/* Target variables: Original and optionally, the variable used in
							the model fit.														*/
		event,				/* Event predicted by the model. 									*/

		/* General information and variables to output */
		pop=,				/* Name of the sub-population to wich the model corresponds to. 	*/ 
		sample=,			/* Name of THE variable defining the sample partition in Training,
							Validation, Test. 													*/
		id=,				/* ID variables to keep in the PRED dataset. 						*/
		keep=ALL,			/* Variables to keep in PRED dataset */
		keepother=,			/* OTHER variables to keep besides ID P LOGIT RES COOK H and model
							variables */
		format=,			/* Format of the variables kept in the PRED dataset. 				*/
		fixnames=1,			/* Whether to fix the parameter and variable names in the parameter
							estimates table and in the TypeIII table.*/

		/* Input and output information */
		inlib=WORK,			/* Input library 													*/
		outlib=WORK,		/* Output library 													*/
		inprefix=,			/* Prefix of input datasets and tables 								*/
		insuffix=,			/* Suffix of input datasets and tables 								*/
		outprefix=model_,	/* Prefix of output datasets and tables 							*/
		outsuffix=,			/* Suffix of output datasets and tables used after the version name.*/
		ver=,				/* Model version used to name the output datasets. 					*/
		code=,				/* Name of the code used to generate the model. 					*/
		date=1,				/* Whether to use today's date in the output datasets names 
							when the version name is empty. 									*/

		/* Names to identify the different datasets */
		var=var,			/* Dataset with the model variables (to be used in a KEEP statement)*/
		regvar=regvar,		/* Dataset with the regression variables (to be used in the MODEL
							statement. 															*/
		pred=pred,			/* Dataset with the predicted probabilities.						*/
		params=params,		/* Dataset with the parameter estimates (one row - OUTEST dataset)	*/
		table=table,		/* Table with parameter estimates (ODS OUTPUT ParameterEstimates) 	*/
		typeIII=typeIII,	/* Table with Type III Analysis of Effects (ODS OUTPUT TypeIII)		*/
		summary=summary,	/* Summary Statistics Table of regression variables and CookD.		*/
		perf=perf,			/* Table with Model Performance Statistics. 						*/
		perfdata=perfdata,	/* Dataset with data to compute Model Performance Statistics.		*/
		gc=gc,				/* Gains Chart Summary Information.									*/
		gcdata=gcdata,		/* Data to construct Gains Chart.									*/

		/* Other information */
		where=,				/* WHERE statement applied to the PRED dataset when computing 
							performance measures. */
		df=2,				/* Degrees of freedom for Hosmer-Lemeshow test. */

		/* Prediction information */
		p=p,				/* Variable name with predicted probability in PRED dataset.		*/
		logit=logit,		/* Variable name with LOG(odds) in PRED dataset.					*/
		res=res,			/* Variable name with the the residuals of the fit in PRED dataset.	*/
		cook=cook,			/* Variable name with Cook distance.								*/
		h=h,				/* Variable name with Leverage.										*/

		/* Export information */
		export=FEW,			/* Datasets to export: FEW, ALL, explicit list.						*/ 
		dir=)				/* Directory where the datasets are exported to (no quotes)			*/
	/ store des="Save the Results of a Logistic Regression Model";
%local i _var_ var_int nro_var_int _ints;
%local label head tail;
%local bysample;			%* Boolean: states whether KS, Gini and Gains Chart computation by sample should be done;
%local target_orig target;
%local varkeep varnames varorder;
%local exporti;
%local export_summary;
%local export_table;
%local export_typeIII;
%local export_perf;
%local export_perfdata;
%local export_gc;
%local export_gcdata;
%local error;
%local rc dsid samplenum samplelen sampletype;

%SetSASOptions;

%put;
%put SAVERESULTS: Macro starts;
%put;

/*----- Parse Input Parameters -----*/
%let error = 0;

%*** TARGETS;
%let target_orig = %scan(&targets, 1, ' ');
%let target = %scan(&targets, 2, ' ');

%*** EVENT;
%* Replace double quotes with simple quotes so that there is no error when enclosing &EVENT
%* within double quotes;
%let event = %sysfunc(tranwrd(%nrbquote(&event), %str(%"), %str(%')));

%*** INLIB= and OUTLIB=;
%if %sysfunc(libref(&inlib)) ~= 0 %then %do;
	%let error = 1;
	%put SAVERESULTS: ERROR - The input library reference %upcase(&inlib) does not exist.;
%end;
%if %sysfunc(libref(&outlib)) ~= 0 %then %do;
	%let error = 1;
	%put SAVERESULTS: ERROR - The output library reference %upcase(&outlib) does not exist.;
%end;

%*** DATE=;
%if &date and %quote(&ver) = %then %do;
	%* Read todays date in case there is no VERSION information and DATE=1;
	data _NULL_;
		today = compress(tranwrd(put(today(), YYMMDD10.), "-", ""));
		%if %quote(&outprefix) = %then %do;
			%* In case there is no prefix in the output datasets add a letter before the date
			%* to avoid the error that the dataset names start with a number;
			call symput ('ver', 'd'||trim(left(today)));	%* D as of Date;
		%end;
		%else %do;
			call symput ('ver', trim(left(today)));
		%end;
	run;
%end;
/*----- Parse Input Parameters -----*/

%if ~&error %then %do;

%*** SAMPLE=;
%* Create boolean variable BYSAMPLE stating whether KS, Gini and Gains Chart computations
%* by sample should be performed;
%if %quote(&sample) ~= and %sysfunc(exist(&inlib..&inprefix&pred&insuffix)) %then %do;
	%* Read length and type of SAMPLE variable in dataset _SR_pred_;
	%let dsid = %sysfunc(open(&inlib..&inprefix&pred&insuffix));
	%let samplenum = %sysfunc(varnum(&dsid, &sample));
	%let samplelen = %sysfunc(varlen(&dsid, &samplenum));
	%let sampletype = %sysfunc(vartype(&dsid, &samplenum));
	%let rc = %sysfunc(close(&dsid));
	%let bysample = %ExistVar(&inlib..&inprefix&pred&insuffix, &sample, log=0);
%end;
%else
	%let sample = ;	%* Remove variable name passed in parameter SAMPLE;

/*------------------ Parameter Estimates, Variables and Summary Statistics ------------------*/
%put;
%put SAVERESULTS: Saving Parameter Estimates and Model Variables...;
%if ~%sysfunc(exist(&inlib..&inprefix&params&insuffix)) %then %do;
	%put SAVERESULTS: WARNING - The OUTEST= dataset %upcase(&inlib..&inprefix&params&insuffix) does not exist.;
	%put SAVERESULTS: The following datasets will NOT be created:;
	%put SAVERESULTS: - Parameter Estimates (one row);
	%put SAVERESULTS: - Summary Statistics;
	%put SAVERESULTS: - List of model variables;
	%put SAVERESULTS: - List of regression variables;
%end;
%else %do;
	data &outlib..&outprefix&ver&outsuffix._&params;
		set &inlib..&inprefix&params&insuffix;
	run;
	%* Read the regression variables from the PARAMS dataset (with full names);
	%GetRegVarList(&outlib..&outprefix&ver&outsuffix._&params, out=, macrovar=_regvar_, log=0);
	%CreateVarFromList(&_regvar_, out=&outlib..&outprefix&ver&outsuffix._&regvar, log=0);
	%* Interaction variables to be created from the PRED dataset so that their impact in the odds
	%* can be computed;
	%let var_int = %FindMatch(&_regvar_, key=*, log=0);
	%* Create the list of variables participating in the regression (so that they can be used
	%* in a keep statement by the user and when creating the PRED dataset). Essentially ;
	data &outlib..&outprefix&ver&outsuffix._&var;
		length var $32;
		set &outlib..&outprefix&ver&outsuffix._&regvar;
		var = name;
		if index(var, "*") then do;
			i = 1;
			var = scan(name, i, "*");
			do until (var = "");
				output;
				i = i + 1;
				var = scan(name, i, "*");
			end;
		end;
		else
			output;
		drop i;
	run;
	proc sort data=&outlib..&outprefix&ver&outsuffix._&var(keep=var) nodupkey;
		by var;
	run;
	proc datasets library=&outlib nolist;
		modify &outprefix&ver&outsuffix._&regvar;
		rename name = var;
	quit;
	%let _var_ = %MakeListFromVar(&outlib..&outprefix&ver&outsuffix._&var, log=0);

	/*----- Summary Statistics -----*/
	%put;
	%put SAVERESULTS: Computing Summary Statistics for regression variables and Cook Distance...;
	%if ~%sysfunc(exist(&inlib..&inprefix&pred&insuffix)) %then %do;
		%put SAVERESULTS: WARNING - The OUTPUT= dataset with the regression variables %upcase(&inlib..&inprefix&pred&insuffix) does not exist.;
		%put SAVERESULTS: No dataset will be created with the summary statistics.;
	%end;
	%else %do;
		%let nro_var_int = %GetNroElements(&var_int);
		data _SR_pred_;
			set &inlib..&inprefix&pred&insuffix(keep=&_var_ &cook);
			%do i = 1 %to &nro_var_int;
				_int&i = %scan(&var_int, &i, ' ');	%* VAR_INT contains the PRODUCT(s) of the interaction variables;
			%end;
		run;
		%let _ints = ;
		%do i = 1 %to &nro_var_int;
			%let _ints = &_ints _int&i;
		%end;
		%** Note that above I could create the list of interaction variables using the hyphen
		%** notation, but I do not do that because that will disrupt the alphabetical order of
		%** the variables listed in &_var_ and I want the summary dataset to be sorted by
		%** the variable names and THEN FOLLOWED by the interaction variables. I accomplish this
		%** by listing the variables in that order in the MEANS macro, but it does not happen
		%** any more then some of the variables use the hyphen notation;
		%Means(
			_SR_pred_,
			var=&_var_ &_ints &cook,
			stat=n mean stddev cv min P1 P5 P10 P25 P50 P75 P90 P95 P99 max,
			transpose=1,
			out=&outlib..&outprefix&ver&outsuffix._&summary,
			log=0
		);
		%* Re-establish the variable names of the interaction variables as they appear
		%* in the TABLE dataset, if any interaction variables are present;
		%if &nro_var_int > 0 %then %do;
			data &outlib..&outprefix&ver&outsuffix._&summary;
				set &outlib..&outprefix&ver&outsuffix._&summary;
				%do i = 1 %to &nro_var_int;
					if upcase(var) = "_INT&i" then
						var = trim(left("%scan(&var_int, &i, ' ')"));
				%end;
			run;
		%end;
	%end;
	/*----- Summary Statistics -----*/
%end;
/*------------------ Parameter Estimates, Variables and Summary Statistics ------------------*/

/*----------------------------- Parameter Estimates Table -----------------------------------*/
%put;
%put SAVERESULTS: Constructing Parameter Estimates Table...;
%if ~%sysfunc(exist(&inlib..&inprefix&table&insuffix)) %then %do;
	%put SAVERESULTS: WARNING - The ODS PARAMETERESTIMATES dataset %upcase(&inlib..&inprefix&table&insuffix) does not exist.;
	%put SAVERESULTS: The Parameter Estimates Table will not be created.;
%end;
%else %do;
	%if &fixnames %then %do;
		%if ~%sysfunc(exist(&inlib..&inprefix&params&insuffix)) %then %do;
			%put SAVERESULTS: WARNING - The OUTEST= dataset %upcase(&inlib..&inprefix&params&insuffix) does not exist.;
			%put SAVERESULTS: The parameter names cannot be fixed.;
		%end;
		%else %do;
			%* Fix the names in the table with the parameter estimates;
			%put SAVERESULTS: Fixing parameter names...;
			%if %ExistVar(&inlib..&inprefix&table&insuffix, Variable, log=0) %then %do;
				%FixNames(&inlib..&inprefix&table&insuffix, params=&inlib..&inprefix&params&insuffix, out=&outlib..&outprefix&ver&outsuffix._&table, log=0);
			%end;
			%else %do;
				%put SAVERESULTS: The variable VARIABLE was not found in dataset %upcase(&inlib..&inprefix&table&insuffix).;
				%put SAVERESULTS: It is assumed that the variable names are already fixed.;
				%put SAVERESULTS: If this is not the case, rename the variable containing the variable names in;
				%put SAVERESULTS: %upcase(&inlib..&inprefix&table&insuffix) to VARIABLE, and run the code again.;
				%* Copy input dataset to output dataset;
				data &outlib..&outprefix&ver&outsuffix._&table;
					set &inlib..&inprefix&table&insuffix;
				run;
			%end;
		%end;
	%end;
	%else %do;
		data &outlib..&outprefix&ver&outsuffix._&table;
			set &inlib..&inprefix&table&insuffix;
			%if %ExistVar(&inlib..&inprefix&table&insuffix, variable, log=0) and
				~%ExistVar(&inlib..&inprefix&table&insuffix, var, log=0) %then %do;
			rename variable = var;
			%end;
		run;
	%end;

	%* Add observation number to recover original order;
	data &outlib..&outprefix&ver&outsuffix._&table;
		%if ~%ExistVar(&inlib..&inprefix&table&insuffix, type, log=0) and
			~%ExistVar(&inlib..&inprefix&table&insuffix, ClassVal0, log=0) %then %do;
			format var type;
			retain type "C";	%* C = Continuous Variable;
		%end;
		set &outlib..&outprefix&ver&outsuffix._&table;
		_OBS_ = _N_;
	run;
	%* Add the summary information to compute the odds ratios;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&summary)) %then %do;
		%Merge(
			&outlib..&outprefix&ver&outsuffix._&table,
			&outlib..&outprefix&ver&outsuffix._&summary(keep=var stddev),
			by=var,
			sort=0,
			condition=if in1,
			log=0
		);
	%end;
	%* Recover original order in the table;
	proc sort 	data=&outlib..&outprefix&ver&outsuffix._&table
				out=&outlib..&outprefix&ver&outsuffix._&table(drop=_OBS_);
		by _OBS_;
	run;
	%* Compute -log(p) and impact in the odds;
	data &outlib..&outprefix&ver&outsuffix._&table;
		set &outlib..&outprefix&ver&outsuffix._&table(rename=(stddev=delta));
		format logp odds 7.3;
		logp = -log10(ProbChiSq);
		if 	delta  ~= . then do;
			%if %ExistVar(&outlib..&outprefix&ver&outsuffix._&table, type, log=0) %then %do;
			if upcase(type) = "D" then
			%end;
			%else %do;
			%* When TYPE does not exist, it means that the variable ClassVal0 exists, because
			%* above I create the variable TYPE when neither TYPE nor CLASSVAL0 exist;
			if ClassVal0 ~= "" then
			%end;
				delta = 1;
			odds = sign(Estimate) * exp(abs(Estimate)*delta);
		end;
		else
			odds = .;
		label 	delta 	= "Delta: Continuous Variable = StdDev; Discrete Variable = 1"
				logp 	= "-Log10(ProbChiSq)"
				odds 	= "Odds Ratio when variable changes by Delta: >0 => ^Odds(&event); <0 => ^Odds(Not &event)";
	run;
%end;
/*----------------------------- Parameter Estimates Table -----------------------------------*/

/*-------------------------- Type III Analysis of Effects Table -----------------------------*/
%put;
%put SAVERESULTS: Constructing TypeIII Analysis of Effects Table...;
%if ~%sysfunc(exist(&inlib..&inprefix&typeIII&insuffix)) %then %do;
	%put SAVERESULTS: WARNING - The ODS TYPEIII dataset %upcase(&inlib..&inprefix&typeIII&insuffix) does not exist.;
	%put SAVERESULTS: The Type III Analysis of Effects Table will not be created.;
%end;
%else %do;
	%if &fixnames %then %do;
		%*** Fix the names in the Type III Analysis of Effects Table;
		%put SAVERESULTS: Fixing parameter names...;
		%FixNames(&inlib..&inprefix&typeIII&insuffix, params=&inlib..&inprefix&params&insuffix, out=&outlib..&outprefix&ver&outsuffix._&typeIII, type=typeIII, log=0);
	%end;
	%else %do;
		data &outlib..&outprefix&ver&outsuffix._&typeIII;
			set &inlib..&inprefix&typeII&insuffix;
			%if %ExistVar(&inlib..&inprefix&typeIII&insuffix, variable, log=0) and
				~%ExistVar(&inlib..&inprefix&typeIII&insuffix, var, log=0) %then %do;
			rename variable = var;
			%end;
		run;
	%end;
	data &outlib..&outprefix&ver&outsuffix._&typeIII;
		set &outlib..&outprefix&ver&outsuffix._&typeIII;
		logp = -log10(ProbChiSq);
		label logp 	= "-Log10(ProbChiSq)";
	run;
%end;
/*-------------------------- Type III Analysis of Effects Table -----------------------------*/

/*----------------- Predicted Probabilities, KS, Gini, Gains and Fit ------------------------*/
%put;
%put SAVERESULTS: Saving Predicted Probabilities Dataset...;
%if ~%sysfunc(exist(&inlib..&inprefix&pred&insuffix)) %then %do;
	%put SAVERESULTS: WARNING - The OUTPUT= dataset with the predicted probabilities %upcase(&inlib..&inprefix&pred&insuffix) does not exist.;
	%put SAVERESULTS: The following datasets will NOT be created:;
	%put SAVERESULTS: - Predicted Probabilities and model variables;
	%put SAVERESULTS: - Performance Statistics;
	%put SAVERESULTS: - CDFs for Performance Statistics;
	%put SAVERESULTS: - Gains Chart;
	%put SAVERESULTS: - Data for Gains Chart;
%end;
%else %do;
	%* Variables in the PRED dataset;
	%let varnames = %GetVarNames(&inlib..&inprefix&pred&insuffix);
	%if %quote(%upcase(&keep)) = FEW %then %do;
		%* List of variables to keep;
		%let varkeep = %KeepInList(&varnames, &id &sample &targets &p &logit &res &cook &h &_var_ &keepother, log=0);
		%* Variables for the FORMAT statement to set the order of the variables in the dataset.
		%* List only those that exist in the PRED dataset;
		%if %quote(&format) ~= %then
			%let varorder = &format;
		%else
			%let varorder = %KeepInList(&id &sample &targets &p &logit &res &cook &h &_var_ &keepother, &varnames, log=0);
	%end;
	%else %if %quote(%upcase(&keep)) = ALL %then %do;
		%let varkeep = &varnames;
		%if %quote(&format) ~= %then
			%let varorder = &format;
		%else
			%let varorder = &varnames;
	%end;
	%else %do;
		%let varkeep = &keep;
		%let varorder = &format;
	%end;
	data &outlib..&outprefix&ver&outsuffix._&pred;
		format %InsertInList(&varorder, &logit, after, &p);
		set &inlib..&inprefix&pred&insuffix(keep=&varkeep);
		if &p not in (0 1) then
			&logit = log(&p / (1-&p));
		else
			&logit = .;
		label &logit = "log(odds(&event))";
	run;

	/*----- Event distribution, KS, Gini, Gains Chart and Fit -----*/
	%if %quote(&perf) ~= %then %do;
		%put;
		%put SAVERESULTS: Computing Model Performance Statistics and Charts...;
		%if &bysample %then %do;
			%* Sort by SAMPLE;
			proc sort 	data=&outlib..&outprefix&ver&outsuffix._&pred(keep=&target_orig &target &p &logit &sample)
						out=_SR_pred_;
				by &sample;
			run;
		%end;
		%* Add a sample id;
		data _SR_pred_;
			%if &bysample %then %do;
			set _SR_pred_;
			by &sample;
			if first.&sample then
				_sampleid_ + 1;
			%* Convert SAMPLE to character if it is numeric;
			%if %upcase(&sampletype) = N %then %do;
			_sample_ = trim(left(put(&sample, 8.)));
			drop &sample;
			rename _sample_ = &sample;
			%let samplelen = 8;
			%end;
			%end;
			%else %do;
			set &outlib..&outprefix&ver&outsuffix._&pred(keep=&target_orig &target &p &logit &sample);
			%end;
		run;

		%*** Event distribution;
		%put SAVERESULTS: Event distribution...;
		proc freq data=_SR_pred_ noprint;
			tables &target_orig / out=_SR_freq_all_;
		run;
		%if &bysample %then %do;
			proc freq data=_SR_pred_ noprint;
				by _sampleid_;
				tables &target_orig / out=_SR_freq_;
			run;
			data _SR_freq_all_;
				set _SR_freq_all_;
				_sampleid_ = 0;
			run;
			proc append base=_SR_freq_all_ 
						data=_SR_freq_ FORCE;
			run;
		%end;
		%* Compute the number of observations effectively used in the construction of the model,
		%* by computing the number of non-missing values of the second target variable passed
		%* in parameter TARGET;
		%* Note that I use PROC TABULATE and not PROC MEANS because I want to include the case
		%* when the target variable is character, and PROC MEANS gives error!;
		%if %quote(&target) ~= %then %do;
			%* I use ODS LISTING EXCLUDE instead of NOPRINT because the NOPRINT option does not
			%* exist in PROC TABULATE!!!!!;
			ods listing exclude all;
			proc tabulate data=_SR_pred_ out=_SR_tabulate_all_;
				class &target;
				tables &target all;
			run;
			ods listing;
			data _SR_tabulate_all_(drop=_TYPE_);
				set _SR_tabulate_all_(keep=_TYPE_ n);
				where _TYPE_ = "0";	%* This identifies the ALL statistics;
			run;
			%if &bysample %then %do;
				ods listing exclude all;
				proc tabulate data=_SR_pred_ out=_SR_tabulate_;
					class _sampleid_ &target;
					tables _sampleid_, &target all;
				run;
				ods listing;
				data _SR_tabulate_(drop=_TYPE_);
					set _SR_tabulate_(keep=_sampleid_ _TYPE_ n);
					where _TYPE_ = "10";	%* This identifies the ALL statistics for each SAMPLEID;
				run;
				data _SR_tabulate_all_;
					set _SR_tabulate_all_;
					_sampleid_ = 0;
				run;
				proc append base=_SR_tabulate_all_ 
							data=_SR_tabulate_ FORCE;
				run;
			%end;
		%end;

		%*** KS;
		%put SAVERESULTS: KS...;
		%KS(_SR_pred_,
			target=&target_orig,
			score=&p,
			%if %quote(&perfdata) ~= %then %do;
			out=&outlib..&outprefix&ver&outsuffix._&perfdata,
			%end;
			outks=_sr_ks_all_,
			plot=0,
			log=0);
		%if &bysample %then %do;
			%KS(_SR_pred_,
				by=_sampleid_ &sample,
				target=&target_orig,
				score=&p,
				%if %quote(&perfdata) ~= %then %do;
				out=_sr_ksdata_,
				%end;
				outks=_sr_ks_,
				plot=0,
				log=0);
			data _sr_ks_all_;
				length &sample $&samplelen;
				set _sr_ks_all_;
				_sampleid_ = 0;
				&sample = "ALL";
			run;
			proc append base=_sr_ks_all_
						data=_sr_ks_ FORCE;
			run;
			%if %quote(&perfdata) ~= %then %do;
				data &outlib..&outprefix&ver&outsuffix._&perfdata;
					length &sample $&samplelen;
					set &outlib..&outprefix&ver&outsuffix._&perfdata;
					&sample = "ALL";
				run;
				proc append base=&outlib..&outprefix&ver&outsuffix._&perfdata
							data=_sr_ksdata_(drop=_sampleid_) FORCE;
				run;
			%end;
		%end;

		%put SAVERESULTS: Gini Index...;
		%Gini(
			_SR_pred_,
			target=&target_orig,
			var=&p,
			outgini=_sr_gini_all_,
			plot=0,
			log=0);
		%if &bysample %then %do;
			%Gini(
				_SR_pred_,
				by=_sampleid_,
				target=&target_orig,
				var=&p,
				outgini=_sr_gini_,
				plot=0,
				log=0);
			data _sr_gini_all_;
				set _sr_gini_all_;
				_sampleid_ = 0;
			run;
			proc append base=_sr_gini_all_
						data=_sr_gini_ FORCE;
			run;
		%end;

		%******* FALTA EL FIT PLOT *********;
		%* Hosmer-Lemeshow statistic;
		%put SAVERESULTS: Hosmer-Lemeshow goodness of fit statistic (D.F. for p-value: &df)...;
		ods listing exclude all;
		proc logistic data=_SR_pred_(keep=&target_orig logit);
			%* Below I replace single quotes with nothing because if EVENT is character, there will
			%* be an error. SAS IS THE KING OF INCONSISTENCIES!!!!!;
			model &target_orig (event="%sysfunc(tranwrd(%nrbquote(&event), %str(%'), %quote()))") = &logit / lackfit(&df);
		ods output LackFitChiSq=_SR_HL_all_;
		run;
		ods listing;
		%if &bysample %then %do;
			ods listing exclude all;
			proc logistic data=_SR_pred_(keep=_sampleid_ &target_orig logit);
				by _sampleid_;
				%* Below I replace single quotes with nothing because if EVENT is character, there will
				%* be an error. SAS IS THE KING OF INCONSISTENCIES!!!!!;
				model &target_orig (event="%sysfunc(tranwrd(%nrbquote(&event), %str(%'), %quote()))") = &logit / lackfit(&df);
				%** Note that the Hosmer-Lemeshow Statistic may vary if the event model is different!;
			ods output LackFitChiSq=_SR_HL_;
			run;
			ods listing;
			data _sr_hl_all_;
				set _sr_hl_all_;
				_sampleid_ = 0;
			run;
			proc append base=_sr_hl_all_
						data=_sr_hl_ FORCE;
			run;
		%end;

		%* Add the Gini Index and the Hosmer-Lemeshow statistic to the KS table and keep only the 
		%* Score based KS (since this has the information of the P at which the KS occurs and its 
		%* value is the same as the Score rank based KS);
		%if %quote(&perf) ~= %then %do;
			data &outlib..&outprefix&ver&outsuffix._&perf(drop=type KSSgn %if &bysample %then %do; _sampleid_ %end;);
				format &sample n nUsed event nEvent;
				format pcntEvent percent7.1;
				merge	_sr_ks_all_(where=(lowcase(type)="score based"))
						_sr_freq_all_(where=(&target_orig=&event) 
									   keep=&target_orig count percent %if &bysample %then %do; _sampleid_ %end;
									   rename=(count=nEvent percent=pcntEvent))
						_sr_tabulate_all_(rename=(n=nUsed))
						_sr_gini_all_(keep=Gini %if &bysample %then %do; _sampleid_ %end;)
						_sr_hl_all_(rename=(Chisq=HL ProbChisq=ProbHL));
				%if &bysample %then %do;
				by _sampleid_;
				%end;
				event = &event;
				pcntEvent = pcntEvent / 100;
				if nUsed = . then nUsed = 0;	%* nUsed is missing when all observations of the TARGET variable are missing for a given SAMPLE (e.g. Validation);
				label 	nUsed		= "Nro. obs used for modelling"
						nEvent 		= "Nro. obs with %upcase(&target_orig)=&event"
						pcntEvent 	= "% obs with %upcase(&target_orig)=&event"
						&p 			= "Probability of %upcase(&target_orig)=&event at which KS occurs"
						HL 			= "Hosmer-Lemeshow goodness of fit Statistic"
						df 			= "Degrees of Freedom for Hosmer-Lemeshow goodness of fit Test"
						ProbHL 		= "P-value for Hosmer-Lemeshow goodness of fit Test";
			run;
		%end;

		%put SAVERESULTS: Gains Chart Table...;
		%GainsChart(
			_SR_pred_,
			target=&target_orig,
			score=&p,
			%if %quote(&gcdata) ~= %then %do;
			out=&outlib..&outprefix&ver&outsuffix._&gcdata,
			%end;
			%if %quote(&gc) ~= %then %do;
			outstat=&outlib..&outprefix&ver&outsuffix._&gc,
			%end;
			print=0,
			plot=0,
			log=0);
		%if &bysample %then %do;
			%GainsChart(
				_SR_pred_,
				by=&sample,
				target=&target_orig,
				score=&p,
				%if %quote(&gcdata) ~= %then %do;
				out=_sr_gcdata_,
				%end;
				%if %quote(&gc) ~= %then %do;
				outstat=_sr_gc_,
				%end;
				print=0,
				plot=0,
				log=0);
			%if %quote(&gcdata) ~= %then %do;
				data &outlib..&outprefix&ver&outsuffix._&gcdata;
					length &sample $&samplelen;
					set &outlib..&outprefix&ver&outsuffix._&gcdata;
					&sample = "ALL";
					drop model;				%* Variable MODEL is generated by the macro %GainsChart;
					%* Drop variables corresponding to the BEST curves, because they are in
					%* the output dataset generated by the BY SAMPLE processing as MODEL = BEST
					%* and these variables are not present in the output datasets coming from the
					%* BY SAMPLE processing;
					drop BestLift BestGainsEvent BestGainsNonEvent;
				run;
				data _sr_gcdata_;
					length &sample $&samplelen;
					set _sr_gcdata_;
					%* Extract the SAMPLE name from variable MODEL;
					&sample = trim(left(scan(model, 2, "=)")));
					%* This is the BEST curves identified by MODEL=BEST;
					if &sample = "" then
						&sample = model;
					drop model;
				run;
				proc append base=&outlib..&outprefix&ver&outsuffix._&gcdata
							data=_sr_gcdata_ FORCE;
				run;
			%end;
			%if %quote(&gc) ~= %then %do;
				data &outlib..&outprefix&ver&outsuffix._&gc;
					length &sample $&samplelen;
					set &outlib..&outprefix&ver&outsuffix._&gc;
					&sample = "ALL";
					drop model;			%* Variable MODEL is generated by the macro %GainsChart;
				run;
				data _sr_gc_;
					length &sample $&samplelen;
					set _sr_gc_;
					%* Extract the SAMPLE name from variable MODEL;
					&sample = trim(left(scan(model, 2, "=)")));
					drop model;
				run;
				proc append base=&outlib..&outprefix&ver&outsuffix._&gc
							data=_sr_gc_ FORCE;
				run;
			%end;
		%end;
	%end;
	/*----- KS, Gini, Gains Chart and Fit -----*/
%end;
/*----------------- Predicted Probabilities, KS, Gini, Gains and Fit ------------------------*/

/*---------------------------------- Dataset labels -----------------------------------------*/
%* Define parts of the labels present in all datasets;
%let head = Model;
%let tail = ;
%if %upcase(&pop) ~= %then
	%let head = %upcase(&pop) - &head;
%if %quote(&ver) ~= %then
	%let head = &head-&ver;
%let head = &head:;
%if %quote(&code) ~= %then
	%let &tail= -- &code;

proc datasets library=&outlib nolist;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&params)) %then %do;
	modify &outprefix&ver&outsuffix._&params
			(label="%sysfunc(compbl(&head Parameters (TARGET=&target_orig) &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&var)) %then %do;
	modify &outprefix&ver&outsuffix._&var
			(label="%sysfunc(compbl(&head Independent Variables used in the Model &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&regvar)) %then %do;
	modify &outprefix&ver&outsuffix._&regvar
			(label="%sysfunc(compbl(&head Regression Variables &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&summary)) %then %do;
	modify &outprefix&ver&outsuffix._&summary
			(label="%sysfunc(compbl(&head Summary Statistics &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&table)) %then %do;
	modify &outprefix&ver&outsuffix._&table
			(label="%sysfunc(compbl(&head Table of Parameter Estimates (TARGET=&target_orig) &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&typeIII)) %then %do;
	modify &outprefix&ver&outsuffix._&typeIII
			(label="%sysfunc(compbl(&head Type III Analysis of Effects &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&pred)) %then %do;
	modify &outprefix&ver&outsuffix._&pred
			(label="%sysfunc(compbl(&head Predicted Prob(&target_orig=&event) &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&perf)) %then %do;
	modify &outprefix&ver&outsuffix._&perf
			(label="%sysfunc(compbl(&head Model Performance Summary &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&perfdata)) %then %do;
	modify &outprefix&ver&outsuffix._&perfdata
			(label="%sysfunc(compbl(&head Data for Model Performance &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&gc)) %then %do;
	modify &outprefix&ver&outsuffix._&gc
			(label="%sysfunc(compbl(&head Gains Charts Summary &tail))");
	%end;
	%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&gcdata)) %then %do;
	modify &outprefix&ver&outsuffix._&gcdata
			(label="%sysfunc(compbl(&head Data for Gains Charts &tail))");
	%end;
quit;
/*---------------------------------- Dataset labels -----------------------------------------*/

/*--------------------------------------- EXPORTS -------------------------------------------*/
%* Initialize boolean variables stating which datasets are exported, since they are only
%* changes when EXPORT is not empty;
%let export_summary = 0;
%let export_table = 0;
%let export_typeIII = 0;
%let export_perf = 0;
%let export_perfdata = 0;
%let export_gc = 0;
%let export_gcdata = 0;
%if %quote(&export) ~= %then %do;
	%* Add the backslash to the directory name;
	%if %quote(&dir) ~= %then
		%let dir = &dir\;
	%if %quote(%upcase(&export)) = FEW or %quote(%upcase(&export)) = ALL %then %do;
		%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&summary)) %then %do;
			%Export(&outlib..&outprefix&ver&outsuffix._&summary, "&dir.&outprefix&ver&outsuffix._&summary..csv", type=csv);
			%let export_summary = 1;
		%end;
		%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&table)) %then %do;
			%Export(&outlib..&outprefix&ver&outsuffix._&table, "&dir.&outprefix&ver&outsuffix._&table..csv", type=csv);
			%let export_table = 1;
		%end;
		%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&typeIII)) %then %do;
			%Export(&outlib..&outprefix&ver&outsuffix._&typeIII, "&dir.&outprefix&ver&outsuffix._&typeIII..csv", type=CSV);
			%let export_typeIII = 1;
		%end;
		%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&perf)) %then %do;
			%Export(&outlib..&outprefix&ver&outsuffix._&perf, "&dir.&outprefix&ver&outsuffix._&perf..csv", type=CSV);
			%let export_perf = 1;
		%end;
		%if %quote(%upcase(&export)) = ALL %then %do;
			%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&perfdata)) %then %do;
				%Export(&outlib..&outprefix&ver&outsuffix._&perfdata, "&dir.&outprefix&ver&outsuffix._&perfdata..csv", type=CSV);
			%let export_perfdata = 1;
			%end;
		%end;
		%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&gc)) %then %do;
			%Export(&outlib..&outprefix&ver&outsuffix._&gc, "&dir.&outprefix&ver&outsuffix._&gc..csv", type=CSV);
			%let export_gc = 1;
		%end;
		%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&gcdata)) %then %do;
			%Export(&outlib..&outprefix&ver&outsuffix._&gcdata, "&dir.&outprefix&ver&outsuffix._&gcdata..csv", type=CSV);
			%let export_gcdata = 1;
		%end;
	%end;
	%else
		%do i = 1 %to %GetNroElements(&export);
			%let exporti = %scan(&export, &i, ' ');
			%let export_&&exporti = 0;
			%if %sysfunc(exist(&outlib..&outprefix&ver&outsuffix._&&exporti)) %then %do;
				%Export(&outlib..&outprefix&ver&outsuffix._&&exporti, "&dir.&outprefix&ver&outsuffix._&&exporti..csv", type=CSV);
				%let export_&&exporti = 1;
			%end;
			%else %do;
				%put;
				%put SAVERESULTS: WARNING - Dataset %upcase(&outlib..&outprefix&ver&outsuffix._&exporti) does not exist.;
				%put SAVERESULTS: No export file will be created.;
			%end;
		%end;
%end;
/*--------------------------------------- EXPORTS -------------------------------------------*/

%put SAVERESULTS: OUTPUT DATASETS;
%if %quote(&export) = %then
	%put SAVERESULTS: The following datasets where created:;
%else %do;
	%put SAVERESULTS: The following datasets where created and exported to;
	%put SAVERESULTS: &dir;
	%put SAVERESULTS: Export mode: %upcase(&export);
%end;
data _NULL_;
	%* Datasets with no exports;
	if exist("&outlib..&outprefix&ver&outsuffix._&params") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&params):" @40 "Parameter Estimates (OUTEST dataset)";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&var") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&var):" @40 "Alphabetical list of Model Variables";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&regvar") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&regvar):" @40 "List of Regression Variables";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&pred") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&pred):" @40 "Predicted Probabilities Dataset";
		put @5 "Variables kept (mode): %upcase(&keep)";
	end;

	%* Datasets with exports;
	if exist("&outlib..&outprefix&ver&outsuffix._&summary") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&summary):" @40 "Summary Statistics of Regression Variables and Cook";
		if &export_summary then
			put @5 "&dir.&outprefix&ver&outsuffix._&summary..csv";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&table") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&table):" @40 "Parameter Estimates Table";
		if &export_table then
			put @5 "&dir.&outprefix&ver&outsuffix._&table..csv";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&typeIII") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&typeIII):" @40 "Type III Analysis of Effects Table";
		if &export_typeIII then
			put @5 "&dir.&outprefix&ver&outsuffix._&typeIII..csv";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&perf") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&perf):" @40 "Performance Statistics (KS, Gini, Hosmer-Lemeshow)";
		if &export_perf then
			put @5 "&dir.&outprefix&ver&outsuffix._&perf..csv";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&perfdata") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&perfdata):" @40 "CDFs for Performance Statistics";
		if &export_perfdata then
			put @5 "&dir.&outprefix&ver&outsuffix._&perfdata..csv";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&gc") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&gc):" @40 "Gains Chart Table";
		if &export_gc then
			put @5 "&dir.&outprefix&ver&outsuffix._&gc..csv";
	end;
	if exist("&outlib..&outprefix&ver&outsuffix._&gcdata") then do;
		i + 1;
		put;
		put i +(-1) "." @5 "%upcase(&outlib..&outprefix&ver&outsuffix._&gcdata):" @40 "Gains Chart Summary Information";
		if &export_gcdata then
			put @5 "&dir.&outprefix&ver&outsuffix._&gcdata..csv";
	end;
run;

proc datasets nolist;
	delete 	_sr_freq_
			_sr_freq_all_
			_sr_gc_
			_sr_gcdata_
			_sr_gini_
			_sr_gini_all_
			_sr_hl_
			_sr_hl_all_
			_sr_ks_
			_sr_ks_all_
			_sr_ksdata_
			_sr_pred_
			_sr_tabulate_
			_sr_tabulate_all_;
quit;

%end;	%* %if ~&error;

%put;
%put SAVERESULTS: Macro ends;
%put;

%ResetSASOptions;
%MEND SaveResults;
