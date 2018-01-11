/* MACRO %DetectCollinearities
Version: 		1.05
Author: 		Daniel Mastropietro
Created: 		11-Oct-2004
Modified: 		10-Sep-2015 (previous: 10-Aug-2015)
SAS Version:	9.4

DESCRIPTION:
This macro detects collinearities among continuous variables.
Currently the only implemented method is the one that is based on the
Variance Inflation Factor (VIF) of each variable.
A variable is considered collinear with the other variables when its VIF is larger
than a given threshold (parameter THR, equal to 10 by default)
(a VIF > 10 is equivalent to having an R-Square > 0.9 for the linear regression of
that variable in terms of the others).
Optionally an additional piece of information containing the correlation of the
analyzed variables with a target variable can be provided in the form of a dataset
which can be used to start eliminating variables that are less strongly correlated
with the target based on that correlation measure.
(For more detailed information see description of the METHOD parameter below, under
OPTIONAL PARAMETERS.)

Variables with a large VIF are removed from the list of variables analyzed under
one of the following two systems:
- All variables having a VIF larger than a given threshold (parameter THRLARGE)
are removed from the regression simultaneously.
- If the largest VIF is smaller than THRLARGE, but larger than the threshold THR
the variables are removed one by one. The variable with the largest 'criterion' value
is removed first and a new analysis of collinearity is performed on the remaining
variables. The criterion of removal depends on the DATACORR parameter: if this parameter
is empty, the criterion is simply given by the variable's VIF; if DATACORR is not empty,
the criterion is given by a combination of the variable's VIF and the variable's
correlation with the target. The details of the calculation of this criterion are
included below in the description of the METHOD parameter.
This process is repeated iteratively until no variable is detected as a candidate for
removal (because all the VIFs are smaller than the specified threshold THR).

USAGE:
%DetectCollinearities(
	data ,				*** Input dataset.
	var=_NUMERIC_ ,		*** List of variables whose collinearity is analyzed.
	method=VIF ,		*** Method used for detection of collinearity (only VIF is available).
	thr=10 ,			*** Threshold to define if a variable is collinear with others
						*** (based on 'method').
	thrLarge=50 ,		*** Threshold used to remove all variables having a VIF larger than
						*** the threshold at the same iteration.
	weight= ,			*** Weight variable used in the regression.		
	datacorr= ,			*** Dataset containing the correlation of the input variables with a target variable.
	out= ,				*** List of output datasets to contain the removed and kept variables.
						*** (Data options are NOT allowed)
	outvif= ,			*** Output dataset with the VIF of variables at each iteration.
	macrovar=varlist ,	*** Name of the macro variable where the list of variables
						*** NOT removed is stored.
	printList=0 ,		*** Show the list of variables that remain after each iteration?
	log=1);				*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option.

OPTIONAL PARAMETERS:
- var:			Blank-separated list of variables whose collinearity is analyzed.
				default: _NUMERIC_ (i.e. all numeric variables are analyzed)

- method:		Method to use for the detection of collinearities among the variables
				listed in 'var'.
				Possible values: VIF (Variance Inflation Factor)
				(this is currently the only available method)
				Description of the available methods:
				- VIF: A linear regression is performed for each variable, in which the
				variable of interest is regressed on the other variables. The R-Square (R2)
				of the regression is computed and the VIF is given by VIF = 1 / (1 - R2).
				A VIF = 5 => R2 = 0.8 and VIF = 10 => R2 = 0.9.

				The selected method is used to decide on the removal of highly collinear
				variables. First a set of variables having their collinearity measure
				larger than the THRLARGE value are removed simultaneously. Secondly,
				variables are removed one-by-one after each iteration of the collinearity
				analysis process by choosing to remove the variable with the largest value
				of a criterion that is based on the collinearity measure.
				The definition of the criterion depends on the DATACORR parameter:
				- if no correlation information is given for the analyzed variables
				through the DATACORR parameter, the criterion is simply the chosen collinearity
				measure.
				- if instead correlation information is given through the DATACORR parameter
				the critersion is defined as:
					"standardized-collinearity-measure" + "standardized-correlation"
				where each standardized measure is computed by standardizing the respective
				measures using the RANGE method of PROC STDIZE which generates standardized
				variables with values in the [0, 1] range. The values of all the variables
				taking part in the collinearity analysis for that iteration are used in the
				standardization process.
				default: VIF

- thr: 			Threshold used to decide whether a variable has a high collinearity with
				the other variables, based on 'method'.
				default: 10

- thrLarge:		Threshold defining the condition above which all the variables having
				a VIF larger than this value are removed, simultaneously, i.e. at the same
				iteration, or under the same regression being performed.
				default: 50

- datacorr:		Dataset containing the correlation of the input variables with a target variable.
				This information is used in the process of removing varaiables one by one as
				described under the METHOD parameter.
				The dataset should at least contain two columns:
				- VAR: contains the variable names.
				- CORR: contains the correlation measure with the hypothetical target.
				Data options are allowed after the dataset name, for instance one can rename
				variables to comply with the aforementioned requirements.
				default: empty

- out:			List of at most two output datasets used to store:
				- Dataset 1: the list of removed variables and the measure used to calculate their
				degree of collinearity with the other variables.
				- Dataset 2: the list of variables NOT removed because of a small collinearity value.
				Data options are NOT allowed.
				The following columns are created in the output datasets:
				- var: variable name
				- label: variable label (if any)
				- iter: (for Dataset 1 only) iteration at which the variable was removed.
				- <name of the measure used> (as specified by the METHOD parameter) (e.g. VIF)
				When the DATACORR parameter is not empty, two additional columns:
				- corr: correlation with the target coming from the CORR variable in the DATACORR dataset.
				- criterion: (for Dataset 1 only) criterion used to select the variable to remove
				during the one-by-one removal process. The variable with the largest criterion value
				is removed first.

- outvif:		Output dataset containing the variable collinearity values at each iteration
				of the detection process.
				Data options are allowed.
				The following columns are created in the output dataset:
				- var: name of the variable
				- iter: iteration at which the variable was removed.
				- <name of the measure used> (as specified by the METHOD parameter) (e.g. VIF)

- macrovar:		Name of the global macro variable where the list of variables NOT removed
				is stored.

- printList:	Whether to show the list of variables that remain in the analysis after
				each iteration.
				Possible values: 0 => No, 1 => Yes.
				default: 0

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes.
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %AddLabels
- %Callmacro
- %CheckInputParameters
- %GetNroElements
- %GetNobs
- %GetVarList
- %MakeListFromVar
- %RemoveFromList
- %ResetSASOptions
- %SetSASOptions

NOTES:
The name for the global macro variable where the list of non-collinear macro variables
is returned cannot be any of the parameter names and cannot contain underscores both
at the beginning and at the end.

EXAMPLES:
1.- %DetectCollinearities(test, var=x1-x5 z w, macrovar=noncollinear);
This analyzes collinearity among variables X1-X5, Z and W in dataset TEST and returns the
list of variables NOT detected as collinear with others in macro variable 'noncollinear'.
Two thresholds are used in the detection process: THR=10 and THRLARGE=50 which are their
default values.
The list of variables removed and kept, and the history of the removal process are NOT
stored in any output dataset, but they are printed in the output destination. 

2.- %DetectCollinearities(test, var=x1-x5 z w, thr=7, out=removed kept, outvif=vifhist);
Same as Ex. 1 with the difference that the threshold used to define a variable as collinear
to others is 7. That is, the removal algorithm stops when no variables being analyzed has
VIF larger than 7.
In addition:
- The output dataset REMOVED is created with the list of variables removed and their
respective VIF values.
- The output dataset KEPT is created with the list of variables NOT removed and their
respective VIF values.
- The output dataset VIFHIST is created with the history of VIF values at each iteration
of the collinearity detection process.
- The list of variables that are NOT detected as collinear is returned in global macro
variable 'varlist' (the default for option macrovar).

3.- %DetectCollinearities(test, var=x1-x5 z w, thrLarge=5000, datacorr=corrwithtarget,
out=removed kept, outvif=vifhist);
Dataset CORRWITHTARGET containing variables VAR and CORR is passed in the DATACORR= parameter
in order to use this information as part of the variable removal process.
See the METHOD parameter above for more information on this process.
Output datasets REMOVED, KEPT, and VIFHIST are created as explained in example 2.

APPLICATIONS:
The macro is useful to detect and remove variables with redundant information prior to
performing a regression model (linear, logistic, etc.). The use of highly collinear
variables may generate difficulties in the detection of those regressor variables that
are important for the prediction of the target variable in a regression model.
However, they do NOT affect the value predicted by the model.
*/

/* PENDIENTE:
- [DONE-2015/09/10] 21/10/04: Agregar una informacion en el log que diga el maximo VIF menor que el
threshold encontrado al final, cuando ya no se eliminan variables, asi uno sabe cuan
cerca del threshold esta' ese VIF.
- [DONE-2015/09/10: This was achieved naturally after refactoring of the removal
process following the inclusion of the DATACORR parameter.]
16/3/05: Cuando se muestra la informacion de las variables eliminadas en conjunto porque
su VIF supera el thrLarge, listarlas en orden de VIF decreciente.
*/
&rsubmit;
%MACRO DetectCollinearities(data,
							var=_NUMERIC_,
							method=VIF,
							thr=10,
							thrLarge=50,
							weight=,
							datacorr=,
							out=,
							outvif=,
							macrovar=varlist,
							printList=0,
							log=1,
							help=0) / store des="Detects variables with high collinearities";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put DETECTCOLLINEARITIES: The macro call is as follows:;
	%put %nrstr(%DetectCollinearities%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put var=_NUMERIC_ , %quote(        *** Variables to analyze.);
	%put method=VIF , %quote(           *** Method used for detection of collinearity %(only VIF is available%).);
	%put thr=10 ,	%quote(             *** Threshold to define if a variable is collinear with others);
	%put %quote(                        *** %(based on 'method'%).);
	%put thrLarge=50 ,	%quote(         *** Threshold defining the condition above which all the variables having);
	%put %quote(                        *** a larger VIF, are all removed at the same iteration.);
	%put datacorr= , %quote(            *** Dataset containing the correlation of the input variables with a target variable.);
	%put out= , %quote(                 *** Output dataset showing level of collinearity of variables removed.);
	%put macrovar= %quote(              *** Name of macro variable where the list of variables NOT removed);
	%put %quote(                            is stored.);
	%put log=1) , %quote(               *** Show messages in the log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var , macro=DETECTCOLLINEARITIES) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
/* Local variables declaration */
%local _largevif_ _largestvif_ _largestvifi_ _vif_ _vifi_ _vifs_;
%local _corr_ _criterion_;
%local _count_ _i_ _iter_ _iteri_ _nro_vars_ _removed_var_;
%local _nobs_ _nvar_ _nro_largestvif_;
%local _out_largevif_ _out_vifok_;
%local corrwithtarget;		%* Flag indicating whether the DATACORR parameter is not empty;
%local nro_vars_infvif nro_vars_largevif nro_vars_largevif_corrok;

%SetSASOptions(varlenchk=NOWARN);
%ExecTimeStart;

%if &log %then %do;
	%put;
	%put DETECTCOLLINEARITIES: Macro starts;
	%put;
%end;

%* Parse list of variables;
%*%let var = %GetVarList(&data , var=&var, log=0);

%* Reading in the input dataset and creating a variable with the observation number.
%* The observation number is used by some methods in order to compute the collinearity
%* measure (for example the VIF method uses the observation variable as a fake target
%* variable in PROC REG);
data _DC_data_;
	set &data;
	_dc_obs_ = _N_;
run;

%let corrwithtarget = 0;
%if %quote(&datacorr) ~= %then %do;
	%let corrwithtarget = 1;
	data _DC_corr_;
		keep var corr;
		set &datacorr;
	run;
%end;

%if %upcase(&method) = VIF %then %do;
	%* Delete output datasets that are created with PROC APPEND;
	proc datasets nolist;
		delete _DC_vifs_ _DC_largevifs_;
	quit;

	%* In order to avoid problems with character variable lengths in the appended datasets
	%* I create their structure here with no records yet;
	data _DC_vifs_ _DC_largevifs_;
		length var $32;
		var = "";
		iter = 0;
		VIF = .;
		%if &corrwithtarget %then %do;
		corr = .;
		criterion = .;
		%end;
		if 0 then output;	%* This creates a dataset with the variables specified above
							%* but with no observations;
	run;

	%* Initial settings;
	%let _largevif_ = 1;
	%let _iter_ = 0;
	%let _count_ = 0;
	%let _removed_var_ = ;
	%let _vifs_ = ;
	%let _iters_ = ;
	%* Start iteration of variable removal;
	%do %while(&_largevif_);
		%let _largevif_ = 0;
		%let _iter_ = %eval(&_iter_ + 1);
		%let _nro_vars_ = %GetNroElements(&var);

		%if &log %then %do;
			%put;
			%put DETECTCOLLINEARITIES: Iteration &_iter_;
			%if &printList %then %do;
				%put DETECTCOLLINEARITIES: Remaining variables:;
				%put DETECTCOLLINEARITIES: %upcase(&var);
			%end;
		%end;

		%* Compute VIF;
		%* Note that the option RIDGE= is necessary, otherwise the VIF is not output to
		%* the OUTEST dataset. Setting RIDGE=0 specifies that no smoothing parameter
		%* is used in the ridge regression run to compute the VIF;
		proc reg data=_DC_data_ outest=_DC_outreg_ ridge=0 outvif noprint;
			model _dc_obs_ = &var / vif;
			%if %quote(&weight) ~= %then %do;
			weight &weight;
			%end;
			run;
		quit;

		%* Get the list of variables whose VIF is larger than the threshold;
		proc transpose 	data=_DC_outreg_(where=(_TYPE_ = "RIDGEVIF" or _TYPE_ = "PARMS")) 
						out=_DC_outreg_(rename=(RIDGEVIF=VIF PARMS=beta))
						name=var;
			id _TYPE_;
			var &var;
		run;

		proc sql noprint;
			%* Sort by ;
			create table _DC_outreg_t as
			select r.var label=" ", r.VIF, r.beta
			%if &corrwithtarget %then %do;
				  ,c.corr
				  ,1/abs(c.corr) as invcorr		/* Consider the absolute value of CORR in case correlations are allowed to be negative */
				from _DC_outreg_ r
				LEFT OUTER JOIN _DC_corr_ c
				on r.var = c.var
				order by VIF desc;
			%end;
			%else %do;
				from _DC_outreg_ r
				order by VIF desc;
			%end;

			%* Count the number of variables with infinite VIF;
			select count(*) into :nro_vars_infvif
			from _DC_outreg_t
			where beta = 0;

			%* Count the number of variables with VIF larger than the threshold;
			select count(*) into :nro_vars_largevif
			from _DC_outreg_t
			where vif > min(&thr, &thrLarge);
				%** Note that I use the MIN() function to compare the VIF value because
				%** I cannot assure that the value of &thrLarge is actually larger than &thr
				%** since both are passed by the user;

			%let nro_vars_largevif_corrok = 0;
			%IF &corrwithtarget %THEN %DO;
				%* Count the number of variables with VIF larger than the threshold and non missing CORR value;
				select count(*) into :nro_vars_largevif_corrok
				from _DC_outreg_t
				where vif > &thr and ~missing(corr);
			%END;
		quit;
		%let _largevif_ = %eval(&nro_vars_infvif > 0 or &nro_vars_largevif > 0);

		%if &_largevif_ %then %do;
			%* If there are any variables with infinite VIF remove them and go to the next iteration without
			%* them, because when they are present in the regression, the VIFs for the other variables tend
			%* to be smaller than when they are not present (verified experimentally);
			%if &nro_vars_infvif > 0 %then %do;
				data _DC_largevif_ _DC_vif_;
					keep var iter VIF %if &corrwithtarget %then %do; corr criterion %end;;
					format var iter VIF;
					length var $32;
					set _DC_outreg_t;
					where beta = 0;
					iter = &_iter_;
					VIF = .;
					%IF &corrwithtarget %THEN %DO;
					criterion = .;
					%END;
				run;
			%end;
			%else %do;
				%* Find variable(s) with the largest VIF qualifying for removal;
				%* If a DATACORR dataset is given, qualifying variables are removed based on a criterion
				%* that combines VIF and the CORR variable present in the DATACORR dataset (unless the variables
				%* have a VIF larger than the THRLARGE option, in which case ALL variables are removed
				%* regarldess of their correlation with the target;
				%if &corrwithtarget %then %do;
					%* Standardize the variables VIF and CORR in order to create a more informative criterion by which to decide
					%* which variables to remove, as we want to remove the variable with smallest correlation among competing
					%* variables on VIF (but do NOT remove e.g. a variable with VIF 10.5 (just above the threshold) with low
					%* correlation and do not remove a variable with very large VIF and correlation just a little larger than
					%* the variable with VIF = 10.5!);
					%* Notes:
					%* - The METHOD=RANGE option specifies a standardization where the location is defined by the
					%* minimum value and the scale by the range of the data. This means that all standardized variables
					%* are between 0 and 1;
					%* - Missing values of stdINVCORR are replaced with its average value which is tantamount
					%* to assuming the variable has a medium correlation with the target. Note that no mising values
					%* should occur in the VIF value;
					proc stdize data=_DC_outreg_t out=_DC_outreg_t method=range oprefix sprefix=std;
						var VIF invcorr;
					run;
					%* Computing the mean value of stdINVCORR to be used for missing values replacement;
					%GetStat(_DC_outreg_t, var=stdINVCORR, stat=mean, name=_stdINVCORR_mean, log=0);
					%* Construct the criterion;
					data _DC_outreg_t;
						set _DC_outreg_t;
						if missing(stdINVCORR) then stdINVCORR = &_stdINVCORR_mean;
						criterion = stdVIF + stdINVCORR;
					run;
					%symdel _stdINVCORR_mean;
					%* Sort by descending criterion;
					proc sort data=_DC_outreg_t;
						by descending criterion;
					run;
				%end;
				data _DC_largevif_ _DC_vif_;
					keep var iter VIF %IF &corrwithtarget %THEN %DO; corr criterion %END;;
					format var iter VIF;
					length var $32;
					set _DC_outreg_t;
					iter = &_iter_;
					retain largeVIF 0;			%* Flag indicating whether at least one variable has a VIF larger than the THRLARGE threshold;
					retain largeVIFFound 0;		%* Flag indicating whether already a qualifying variable has been found to have a VIF larger than the THR threshold;
												%* (because we want to remove just one variable at each iteration);
												%* When the DATACORR parameter is not empty QUALIFYING variable implies having a non missing value for the CORR variable present in such dataset;
					if VIF > &thrLarge then do;
						largeVIF = 1;
						output _DC_largevif_;
					end;
					else if ~largeVIF and ~largeVIFFound then do;
						%** NOTE: The ~largeVIF condition above is important because we do not want to continue
						%** removing variables with VIF < &thrLarge until we go on to the next iteration
						%** where all the really large VIF variables have been removed;
						if VIF > &thr /*%IF &corrwithtarget AND &nro_vars_largevif_corrok > 0 %THEN %DO; and ~missing(corr) %END; */ then do;
							%* Output the SINGLE variable with the largest VIF to the _DC_largevif_ dataset;
							largeVIFFound = 1;
							output _DC_largevif_;
							call symput('_largestvif_', var);
							call symput('_vif_' , VIF);
							%IF &corrwithtarget %THEN %DO;
							call symput('_corr_', corr);
							call symput('_criterion_', criterion);
							%END;
						end;
					end;
					%* Always output the record to the _DC_vif_ dataset since this dataset contains ALL the variables
					%* analyzed at each interation (except when there are variables with infinite VIF);
					output _DC_vif_;
				run;
			%end;

			%*---------------------- UPDATE PROCESS FOR THE NEXT ITERATION -------------------;
			%* Variable names with large VIF;
			%let _largestvif_ = %MakeListFromVar(_DC_largevif_, var=var, log=0);
			%let _nro_largestvif_ = %GetNroElements(&_largestvif_);
			%* Values of the VIF for the above variable names;
			%let _vif_ = %MakeListFromVar(_DC_largevif_, var=VIF, log=0);
			%let _iterlist_ = %Rep(&_iter_, &_nro_largestvif_);
			%* List of variables left, after removal of variables with large VIF;
			%let var = %RemoveFromList(&var, &_largestvif_, log=0);
			%* Nro. of variables detected with large VIF;
			%* Update total nro. of variables detected with large VIF so far;
			%let _count_ = %eval(&_count_ + &_nro_largestvif_);
			%* Update list of variables detected with large VIF;
			%let _removed_var_ = &_removed_var_ &_largestvif_;
			%* Update list of VIF values of the variables with large VIF;
			%let _vifs_ = &_vifs_ &_vif_;
			%let _iters_ = &_iters_ &_iterlist_;
			%*---------------------- UPDATE PROCESS FOR THE NEXT ITERATION -------------------;

			%if &log %then %do;
				%do _i_ = 1 %to &_nro_largestvif_;
					%let _vifi_ = %scan(&_vif_, &_i_, ' ');
					%let _largestvifi_ = %scan(&_largestvif_, &_i_, ' ');
					%if &_vifi_ = . %then
						%put DETECTCOLLINEARITIES: Variable %upcase(&_largestvifi_) removed (VIF=Inf);
						%** The %if &_vif_ = . is done to avoid an error with the function ROUND;
					%else
						%put DETECTCOLLINEARITIES: Variable %upcase(&_largestvifi_) removed (VIF=%sysfunc(compbl(%sysfunc(round(&_vifi_, 0.1)))));
				%end;
				%put DETECTCOLLINEARITIES: Number of variables removed: &_nro_largestvif_;
				%put DETECTCOLLINEARITIES: Number of variables left: %GetNroElements(&var); 
			%end;
			%* Append the variable(s) removed to the dataset containing all removed variables;
			proc append base=_DC_largevifs_ data=_DC_largevif_; run;
		%end;
		%else %do;
			%* Copy the _DC_outreg_t dataset to the _DC_vif_ and _DC_vifok_ datasets.
			%* The latter dataset contains the list of variables with VIF values smaller than the threshold;
			data _DC_vif_ _DC_vifok_(drop=iter %IF &corrwithtarget %THEN %DO; criterion %END;);
				keep var iter VIF %IF &corrwithtarget %THEN %DO; corr criterion %END;;
				format var iter VIF;
				length var $32;
				set _DC_outreg_t;
				%* Compute the largest VIF of the remaining variables so that it is informed to the user;
				if _N_ = 1 then call symput('_largestvif_', VIF);
				iter = &_iter_;
				criterion = .;
			run;
		%end;

		%* Append the OUTVIF dataset;
		proc append base=_DC_vifs_ data=_DC_vif_; run;
	%end;

	%if &log %then %do;
		%let _nro_vars_ = %GetNroElements(&var);
		%put;
		%put DETECTCOLLINEARITIES: No more variables removed due to large VIF (> &thr).;
		%put DETECTCOLLINEARITIES: Largest VIF = %sysfunc(round(&_largestvif_, 0.1));
		%put DETECTCOLLINEARITIES: Variables removed:;
		%if %quote(&_removed_var_) ~= %then
			%do _i_ = 1 %to &_count_;
				%let _vifi_ = %scan(&_vifs_, &_i_, ' ');
				%let _iteri_ = %scan(&_iters_, &_i_, ' ');
				%if &_vifi_ = . %then
					%put DETECTCOLLINEARITIES: %upcase(%scan(&_removed_var_, &_i_)) (Iter=&_iteri_, VIF=Inf);
					%** The %if &_vifi_ = Inf is done to avoid an error with the function ROUND;
				%else
					%put DETECTCOLLINEARITIES: %upcase(%scan(&_removed_var_, &_i_)) (Iter=&_iteri_, VIF=%sysfunc(round(&_vifi_, 0.1)));
			%end;
		%else
			%put DETECTCOLLINEARITIES: (None);
		%put DETECTCOLLINEARITIES: Nro. of variables removed: &_count_;
		%put DETECTCOLLINEARITIES: Nro. of variables left: &_nro_vars_;
	%end;

	%*** Generate output datasets;
	%* OUT=;
	%if %quote(&out) ~= %then %do;
		%let _out_largevif_ = %scan(&out, 1, ' ');
		data &_out_largevif_;
			set _DC_largevifs_;
			format VIF 10.1;
			label criterion = "Removal criterion: range-standardized(VIF) + range-standardized(1/corr)";
		run;
		%* Add the variable labels column;
		%AddLabels(&_out_largevif_, &data, log=0);
		%if &log %then %do;
			%callmacro(getnobs, &_out_largevif_ return=1, _nobs_ _nvar_);
			%put;
			%put DETECTCOLLINEARITIES: Output dataset %upcase(%scan(&_out_largevif_, 1, '(')) created with &_nobs_ observations and &_nvar_ variables;
			%put DETECTCOLLINEARITIES: containing the variables with VIF > &thr and corresponding VIF values.;
		%end;
		%if %GetNroElements(&out) > 1 %then %do;
			%let _out_vifok_ = %scan(&out, 2, ' ');
			data &_out_vifok_;
				set _DC_vifok_;
				format VIF 10.1;
			run;
			%* Add the variable labels column;
			%AddLabels(&_out_vifok_, &data, log=0);
			%if &log %then %do;
				%callmacro(getnobs, &_out_vifok_ return=1, _nobs_ _nvar_);
				%put;
				%put DETECTCOLLINEARITIES: Output dataset %upcase(%scan(&_out_vifok_, 1, '(')) created with &_nobs_ observations and &_nvar_ variables;
				%put DETECTCOLLINEARITIES: containing the variables with VIF <= &thr and corresponding VIF values.;
			%end;
		%end;
	%end;
	%else %do; 	%* Show results in the output window;
		title3 "Dataset %upcase(&data)";
		title4 "List of variables removed with VIF > &thr";
		proc print data=_DC_largevifs_ noobs;
			format VIF 10.1;
		run;
		title3;
		title4;

		title3 "Dataset %upcase(&data)";
		title4 "List of variables left with VIF <= &thr";
		proc print data=_DC_vifok_ noobs;
			format VIF 10.1;
		run;
		title3;
		title4;
	%end;

	%* OUTVIF=;
	%* When the DATACORR parameter is not empty, sort the OUTVIF dataset by ITER and
	%* then descending criterion within each set of variables:
	%* - those with large VIF
	%* - those with small VIF;
	%* Still I always create the GROUP variable now so that I do not have to worry about not dropping it below
	%* when creating the output dataset;
	data _DC_vifs_;
		set _DC_vifs_;
		if VIF > &thr 	then group = 1;
						else group = 2;
	run;
	%if &corrwithtarget %then %do;
	proc sort data=_DC_vifs_;
		by iter group descending criterion;
	run;
	%end;
	%if %quote(&outvif) ~= %then %do;
		data &outvif;
			set _DC_vifs_(drop=group);
			format VIF 10.1;
			label criterion = "Removal criterion: range-standardized(VIF) + range-standardized(1/corr)";
		run;
		%* Add the variable labels column;
		%AddLabels(&outvif, &data, log=0);
		%if &log %then %do;
			%callmacro(getnobs, &outvif return=1, _nobs_ _nvar_);
			%put;
			%put DETECTCOLLINEARITIES: Output dataset %upcase(%scan(&outvif, 1, '(')) created with &_nobs_ observations and &_nvar_ variables;
			%put DETECTCOLLINEARITIES: containing the VIF of all the variables by the different iterations performed.;
		%end;
	%end;
	%else %do; 	%* Show results in the output window;
		title3 "Dataset %upcase(&data)";
		title4 "Variables VIF by iteration";
		proc print data=_DC_vifs_ noobs;
			format VIF 10.1;
		run;
		title3;
		title4;
	%end;

	%* Delete temporary datasets;
	proc datasets nolist;
	delete 	_DC_corr_
			_DC_data_
			_DC_largevif_
			_DC_largevifs_
			_DC_outreg_
			_DC_outreg_t
			_DC_vif_
			_DC_vifs_
			_DC_vifok_;
	quit;
%end;

%if %quote(&macrovar) ~= %then %do;
	%global &macrovar;
	%let &macrovar = &var;
%end;

%if &log %then %do;
	%put;
	%put DETECTCOLLINEARITIES: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;
%end;
%MEND DetectCollinearities;
