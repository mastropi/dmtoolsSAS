/* MACRO %DetectCollinearities
Version: 		1.04
Author: 		Daniel Mastropietro
Created: 		11-Oct-2004
Modified: 		10-aug-2015 (previous: 31-Aug-2006)
SAS Version:	9.4

DESCRIPTION:
This macro detects collinearities among continuous variables.
Currently the only implemented method is the one that is based on the
Variance Inflation Factor (VIF) of each variable.
A variable is considered collinear with the other variables when its VIF is larger
than a given threshold (parameter THR, equal to 10 by default)
(a VIF > 10 is equivalent to having an R-Square > 0.9 for the linear regression of
that variable in terms of the others).
(For more detailed information see description of parameter 'method' below, under
'OPTIONAL PARAMETERS'.)

Variables with a large VIF are removed from the list of variables analyzed under
one of the following two systems:
- All variables having a VIF larger than a given threshold (parameter THRLARGE, 
equal to 50 by default) are removed from the regression simultaneously.
- If the largest VIF is smaller than THRLARGE, but larger than the threshold THR
the variables are removed one by one: that is, the variable with the largest VIF
is removed first and a new analysis of collinearity is performed on the remaining variables.
This process is repeated iteratively until no variable is detected as a candidate for
removal (because all the VIFs are smaller than the specified threshold THR).

USAGE:
%DetectCollinearities(
	data ,				*** Input dataset.
	var=_NUMERIC_ ,		*** List of variables whose collinearity is analyzed.
	method=VIF ,		*** Method used for detection of collinearity (only VIF is available).
	thr=10 ,			*** Threshold to define if a variable is collinear with others
						*** (based on 'method').
	thrLarge=50,		*** Threshold used to remove all variables having a VIF larger than
						*** the threshold at the same iteration.
	weight= ,			*** Weight variable used in the regression.		
	out= ,				*** List of output datasets to contain the removed and kept variables.
						*** (Data options are NOT allowed)
	outvif= ,			*** Output dataset with the VIF of variables at each iteration.
	macrovar=varlist ,	*** Name of the macro variable where the list of variables
						*** NOT removed is stored.
	printList=0,		*** Show the list of variables that remain after each iteration?
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
				default: VIF

- thr: 			Threshold used to decide whether a variable has a high collinearity with
				the other variables, based on 'method'.
				default: 10

- thrLarge:		Threshold defining the condition above which all the variables having
				a VIF larger than this value are removed, simultaneously, i.e. at the same
				iteration, or under the same regression being performed.
				default: 50

- out:			List of output datasets to contain:
				- the list of removed variables and the measure used to calculate their
				degree of collinearity with the other variables.
				- the list of variables NOT removed due to a small collinearity value.
				Data options are NOT allowed.
				The following columns are created in the output dataset:
				- var: name of the variable
				- iter: iteration at which the variable was removed (for the removed dataset only).
				- <name of the measure used> (as specified by 'method') (e.g. VIF)

- outvif:		Output dataset containing the variable VIF values at each iteration
				of the detection process.
				Data options are NOT allowed.
				The following columns are created in the output dataset:
				- var: name of the variable
				- iter: iteration at which the variable was removed.
				- <name of the measure used> (as specified by 'method') (e.g. VIF)

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

APPLICATIONS:
The macro is useful to detect and remove variables with redundant information prior to
performing a regression model (linear, logistic, etc.). The use of highly collinear
variables may generate difficulties in the detection of those regressor variables that
are important for the prediction of the target variable in a regression model.
*/

/* PENDIENTE:
- 21/10/04: Agregar una informacion en el log que diga el maximo VIF menor que el
threshold encontrado al final, cuando ya no se eliminan variables, asi uno sabe cuan
cerca del threshold esta' ese VIF.
- 16/3/05: Cuando se muestra la informacion de las variables eliminadas en conjunto porque
su VIF supera el thrLarge, listarlas en orden de VIF decreciente.
*/
&rsubmit;
%MACRO DetectCollinearities(data,
							var=_NUMERIC_,
							method=VIF,
							thr=10,
							thrLarge=50,
							weight=,
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
	%put thrLarge=10 ,	%quote(         *** Threshold defining the condition above which all the variables having);
	%put %quote(                        *** a larger VIF, are all removed at the same iteration.);
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
%local _count_ _i_ _iter_ _iteri_ _nro_vars_ _removed_var_;
%local _nobs_ _nvar_ _nro_largestvif_;
%local _out_largevif_ _out_vif_ _out_vifok_;

%SetSASOptions;

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

%if %upcase(&method) = VIF %then %do;
	%* Delete output datasets that are created with PROC APPEND;
	proc datasets nolist;
		delete _DC_vifs_ _DC_largevifs_;
	quit;

	%* Create the dataset that is used to store the list of variables removed when
	%* an output dataset is requested;
	%if %quote(&out) ~= %then %do;
		data _DC_largevifs_;
			length var $32;
			iter = 0;
			var = "";
			VIF = .;
			if 0 then output;	%* This creates a dataset with the variables specified above
								%* but with no observations;
		run;
	%end;

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

		%* Find variable with the largest VIF qualifying for removal;
		data _DC_largevif_ _DC_vif_;
			keep var VIF iter;
			set _DC_outreg_;
			length var $32;
			where _TYPE_ = "RIDGEVIF" or _TYPE_ = "PARMS";
			array vars{*} &var;
			retain infVIF 0;

			%* Check for Infinite VIFs (VIF = .) which can be detected because the parameter
			%* estimate of the variable with infinite VIF is equal to 0;
			if _TYPE_ = "PARMS" then
				do i = 1 to &_nro_vars_;
					if vars(i) = 0 then do;
						infVIF = 1;
						call symput ('_largevif_', 1);
						iter = &_iter_;
						var = vname(vars(i));
						VIF = .;
						output;
					end;
				end;
			else if ~infVIF then do;
				%* Remove the variables with large VIF only after all the variables that
				%* are redundant (i.e. VIF = .) were removed, because when the redundant variables
				%* are present in the regression, the VIFs for the other variables may be incorrect;
				largeVIF = 0;
				do i = 1 to &_nro_vars_;
					iter = &_iter_;
					var = vname(vars(i));
					VIF = vars(i);
					output _DC_vif_;
					if vars(i) > &thrLarge then do;
						largeVIF = 1;
						call symput ('_largevif_', 1);
						output _DC_largevif_;
					end;
				end;
				%* Only check for individual variables with large VIF when no set of variables
				%* were detected with VIF larger than THRLARGE;
				if ~largeVIF then do;
					_dc_maxvalue_ = max(of &var);
					if _dc_maxvalue_ > &thr then
						do i = 1 to &_nro_vars_;
							if abs(_dc_maxvalue_ - vars(i)) < 1e-9 then do;
								call symput ('_largestvif_', vname(vars(i)));
								call symput ('_largevif_', 1);
								call symput ('_vif_' , _dc_maxvalue_);

								iter = &_iter_;
								var = vname(vars(i));
								VIF = _dc_maxvalue_;
								output;
								stop;
							end;
						end;
				end;
			end;
		run;
		%* Append the OUTVIF dataset;
		proc append base=_DC_vifs_ data=_DC_vif_; run;

		%* Append the LARGEVIF dataset;
		%if &_largevif_ %then %do;
			%* Sort by descending VIF;
			proc sort data=_DC_largevif_;
				by descending VIF;
			run;
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
			%if &log %then
				%do _i_ = 1 %to &_nro_largestvif_;
					%let _vifi_ = %scan(&_vif_, &_i_, ' ');
					%let _largestvifi_ = %scan(&_largestvif_, &_i_, ' ');
					%if &_vifi_ = . %then
						%put DETECTCOLLINEARITIES: Variable %upcase(&_largestvifi_) removed (VIF=Inf);
						%** The %if &_vif_ = . is done to avoid an error with the function ROUND;
					%else
						%put DETECTCOLLINEARITIES: Variable %upcase(&_largestvifi_) removed (VIF=%sysfunc(compbl(%sysfunc(round(&_vifi_, 0.1)))));
				%end;
			%* Appending the variable removed to the dataset containing all removed variables;
			proc append base=_DC_largevifs_ data=_DC_largevif_; run;
		%end;
		%else %do;
			%* Store variables left and their VIFs;
			data _DC_vifok_(keep=var vif);
				set _DC_outreg_;
				length var $32;
				where _TYPE_ = "RIDGEVIF";
				array vars{*} &var;
				do i = 1 to dim(vars);
					var = vname(vars(i));
					VIF = vars(i);
					output;
				end;
				drop i;
			run;
		%end;
	%end;

	%if &log %then %do;
		%let _nro_vars_ = %GetNroElements(&var);
		%put;
		%put DETECTCOLLINEARITIES: No more variables removed due to large VIF (> &thr).;
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
	%* Sort by iter and descending VIF; 
	proc sort data=_DC_vifs_; by iter descending VIF; run;
	%if %quote(&outvif) ~= %then %do;
		%let _out_vif_ = %scan(&outvif, 1, ' ');
		data &_out_vif_;
			set _DC_vifs_;
			format VIF 10.1;
		run;
		%* Add the variable labels column;
		%AddLabels(&_out_vif_, &data, log=0);
		%if &log %then %do;
			%callmacro(getnobs, &_out_vif_ return=1, _nobs_ _nvar_);
			%put;
			%put DETECTCOLLINEARITIES: Output dataset %upcase(%scan(&_out_vif_, 1, '(')) created with &_nobs_ observations and &_nvar_ variables;
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
	delete 	_DC_data_
			_DC_largevif_
			_DC_largevifs_
			_DC_vif_
			_DC_vifs_
			_DC_outreg_
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

%ResetSASOptions;
%end;
%MEND DetectCollinearities;
