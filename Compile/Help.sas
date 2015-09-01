/* MACRO %Help
Version: 	1.02
Author: 	Daniel Mastropietro
Created: 	09-Dec-2003
Modified: 	01-Sep-2015

DESCRIPTION:
Shows help on how to invoke a macro.

USAGE:
%Help(macro, by=topic);

REQUIRED PARAMETERS:
- macro:			Name of the macro of which help is requested. Not case sensitive.

OPTIONAL PARAMETERS:
- by:				What grouping to use in the macros list.
					Possible values: TOPIC (shows the macros by topic), ALPHABETICALLY
					(shows the macros in alphabetical order)
					default: topic
*/
&rsubmit;
%MACRO Help(macro, by=topic) / store des="Shows Macros help";
/*
NOTE: The list &macrolist must be updated as new macros include help support.
*/
%local macrolist;
%let macrolist = 
BOXCOX
CATEGORIZE
CENTER
CREATEGROUPVAR
CREATEINTERACTIONS
DETECTCOLLINEARITIES
DETECTOUTLIERSMAD
DFBETAS
EVALUATIONCHART
FREQMULT
GAINSCHART
HADI
INFORMATIONVALUE
KS
LIFTCHART
LORENZCURVE
MEANS
MERGE
PHTESTPLOT
PLOTBINNED
SORT
STANDARDIZE
TESTLOGISTICFIT
TRANSPOSE
VARIABLEIMPACT;

/* List of available macros (Taken from a dir > dir.txt in DOS prompt. Macros of internal
used are commented out). The asteriscs (*) next to the macro name indicate that additional
help is available when calling %Help(<macro-name>).
REMEMBER TO CHANGE THE DATE BELOW WHEN THE LIST IS UPDATED. */
%if %quote(&macro) = %then %do;
	%put;
	%put %quote(                        AVAILABLE MACROS AS OF 27-Aug-2015);
%*	%put MACROS DISPONIBLES AL 10/6/04:;
	%if %upcase(%quote(&by)) = TOPIC %then %do;
		%put %quote(                                  -- BY TOPIC --);
		%put %quote(%(An asterisk %(*%) next to the macro name indicates that help is available for the macro%));
		%put;
		%put DATA MANIPULATION;
		%put -----------------;
		%put 	Categorize*	%quote(         Categorize a set of variables in a given number of groups.);
		%put	Center*	%quote(             Center and optionally standardize a set of variables.);
		%put	CheckRepeated %quote(       Check the existence of observations with repeated key values in a dataset);
		%put 	%quote(                     and creates an output dataset containing those observations.);
		%put	CreateGroupVar*	%quote(     Create a variable identifying groups.);
		%put	CreateInteractions*	%quote( Create interactions between variables or interaction strings.);
		%put	CreateLags %quote(          Create a set of lagged variables with lag 1 to n.);
		%put	CreatePrevPostVar %quote(   Create a variable containing previous and posterior values of variables,);
		%put 	%quote(                     where the 'previous' and 'posterior' conditions are defined by a certain);
		%put 	%quote(                     matching criterion.);
		%put	DataComputeWithMissing %quote(Generate data statements to handle missing values in a computed variable.);
		%put	Drop %quote(                Drop a set of variables in a dataset, regardless if they exist or not.);
		%put	GetVarList %quote(          Get the list of variables in a dataset associated with more complex listing);
		%put	%quote(                     %(like x1-x9, _NUMERIC_, etc.%).);
  		%put	GetVarNames	%quote(         Get the names of the variables present in a dataset.);
		%put	GetVarOrder	%quote(         Get the order in which variables are stored in a dataset.);
		%put 	GetVarType %quote(          Get the type of a variable (C(haracter) or N(umeric)) in a dataset.);
		%put	Merge* %quote(              Merge 2 datasets without having them sorted by the by variables.);
		%put	SetVarOrder	%quote(         Set the order in which variables are stored in a dataset.);
		%put	Standardize* %quote(        Center and standardize variables.);
		%put	Sort* %quote(               User friendly PROC SORT. Several datasets can be sorted simultaneously.);
		%put 	Subset %quote(              Subset a dataset with a WHERE condition by by variables.);
		%put	Transpose* %quote(          Transpose a dataset.);
		%put;
		%put EXPLORATORY DATA ANALYSIS;
		%put -------------------------;
		%put 	Boxcox* %quote(             Box-Cox transformation (for distribution normalization).);
		%put	Cov	%quote(                 Compute covariance matrix of a set of variables.);
		%put	CutMahalanobisChi %quote(   Detect multivariate outliers using Mahalanobis distance.);
		%put	Det	%quote(                 Compute determinant of a matrix.);
		%put	DetectOutliersHadi %quote(  Detect univariate outliers using the Box-Cox transformation and the Hadi algorithm.);
		%put	DetectOutliersMAD*%quote(   Detect univariate outliers based on the MAD.);
		%put 	Hadi* %quote(               Robustly detect multivariate oultiers using Hadi method.);
		%put	LorenzCurve* %quote(        Plot the Lorenz Curve for a set of variables w.r.t. a non-negative target.);
		%put	Mahalanobis	%quote(         Compute Mahalanobis distance of a set of variables.);
		%put 	PHTestPlot* %quote(         Make plots of survival curves to visually check proportional hazards assumption.);
		%put	Qqplot %quote(              Make Q-Q plots for a set of variables.);
		%put;
		%put GENERAL STATISTICS;
		%put ------------------;
		%put	FreqMult* %quote(           Compute and store the frequencies of a list of variables in an output);
		%put 	%quote(                     dataset.);
		%put	GetStat	%quote(             Get the value of ONE specified statistic for a set of variables);
		%put	%quote(                     in a dataset.);
		%put	Means* %quote(              Execute a user friendly PROC MEANS.);
		%put;
		%put GRAPHS;
		%put ------;
		%put 	Colors %quote(              Create list of 10 color names to be used for graph symbols and lines.);
		%put	DefineSymbols %quote(       Define plotting symbols.);
		%put	GraphXY	%quote(             Make a 2D plot of Y vs. X);
		%put	MPlot %quote(               Make multiple plots in the same window.);
		%put 	PlotBinned* %quote(         Make 2D scatter or bubble plots of a target variable vs. binned continuous variables.);
		%put	Scatter	%quote(             Make 2D scatter plots among pairwise variables.);
		%put	SetAxis %quote(             Create the string for an AXIS statement so that pretty values are shown.);
		%put	SymmetricAxis %quote(       Create the string for an AXIS statement so that the axis);
		%put	%quote(                     is symmetric around 0.);
		%put;
		%put MODELLING;
		%put ---------;
		%put 	DetectCollinearities*%quote(Detect collinearities among variables.);
		%put	Dfbetas* %quote(            Detect influential observations with the DFBETA criterion.);
		%put	EvaluationChart* %quote(    Plot an evaluation chart for a model with a categorical target.);
		%put	GainsChart* %quote(         Plot the Gains Chart for a model with a binary target.);
		%put    InformationValue* %quote(   Compute the Information Value of a set of variables for a binary target.);
		%put	KS* %quote(                 Compute the KS statistic of a set of variables w.r.t. a binary target.);
		%put	LiftChart* %quote(          Plot the Lift Chart for a model with a discrete target.);
		%put	LogisticRegression %quote(  Perform a Logistic Regression iteratively by eliminating influential);
		%put	%quote(                     observations.);
		%put	PartialPlots %quote(        Make partial plots to graphically assess the linearity of variables in a;
		%put 	%quote(                     linear regression.);
		%put	PiecewiseTransf %quote(     Perform a linear piecewise transformation on continuous variables.); 
		%put	QualifyVars %quote(         Automatically qualify variables into categorical or continuous.);
		%put	TestLogisticFit* %quote(    Test the fit of a logistic regression model.);
		%put	VariableImpact*	%quote(     Make plots to evaluate the univariate impact of a set of continuous variable);
		%put	%quote(                     on a binary target.);
		%put;
		%put OTHER;
		%put -----;
		%put	Compute	%quote(             Evaluate a given function by forcing the evaluation of its argument.);
		%put	EvalExp %quote(             Force the evaluation of an expression.);
		%put 	ExecTimeStart %quote(       Start the clock to measure execution time of a macro.);
		%put 	ExecTimeStop %quote(        Measure the time elapsed since macro ExecTimeStart was last called.);
		%put	ExistData %quote(           Check if a dataset exists.);
		%put	ExistMacroVar %quote(       Check if a macro variable exists.);
		%put	ExistVar %quote(            Check if all variables in a given list exist in a dataset.);
		%put	Getnobs	%quote(             Get the nro. of observations and variables in a dataset.);
		%put	Help %quote(                Show this help information.);
		%put 	ODSOutputClose %quote(      Close an open ODS output file.);
		%put 	ODSOutputOpen %quote(       Open an ODS output file for writing.);
		%put;
		%put STRING MANIPULATION;
		%put -------------------;
		%put 	All %quote(                 Establish a condition that ALL variables in a list must satisfy.);
		%put 	Any	%quote(                 Establish a condition that AT LEAST ONE variable in a list must satisfy.);
		%put	CompareLists %quote(        Compare two lists of names, and creates 3 datasets containing the list);
		%put	%quote(                     of the names found in both lists, of the names found in one list and not);
		%put	%quote(                     in the other, and viceversa.);
		%put	CreateVarFromList %quote(   Create a dataset with a column containing the names in a list.);
		%put	CreateVarList %quote(       Create a dataset with a column containing the variable names passed in a);
		%put	%quote(                     list that are present in a dataset.);
		%put	FindInList %quote(          Find a set of names in a list and returns their word position.);
		%put	FindMatch %quote(           Find the names in a list that contain a given keyword.);
		%put	GetNroElements %quote(      Get the nro. of elements in a list.);
		%put 	InsertInList %quote(        Insert a name in a list at a given position.);
		%put	MakeList %quote(            Make a list by adding a prefix and suffix to each name in a given list.);
		%put	MakeListFromName %quote(    Make a list from a name used as root.);
		%put	MakeListFromVar %quote(     Make a list containing the values of a variable in a dataset.);
		%put	MakeVar	%quote(             Define global macro variables whose values are the elements of a given list.);
		%put	PrintNameList %quote(       Print a list of names in one column in the output window.);
		%put	RemoveFromList %quote(      Remove a set of names from a given list.);
		%put	RemoveRepeated %quote(      Remove repeated names from a given list.);
		%put	Rep %quote(                 Generate a list of one value repeated a number of times.);
		%put	SelectName(s) %quote(       Return a subset of names from a list.);
		%put	SelectVar %quote(           Return a list of variable names in a dataset matching a keyword.);
	%end;
	%else %do;		%* Alphabetic Listing;
		%put %quote(                                -- ALPHABETICALLY --);
		%put %quote(%(An asterisk %(*%) next to the macro name indicates that help is available for the macro%));
		%put;
		%put A;
		%put 	All %quote(                 Establish a condition that ALL variables in a list must satisfy.);
		%put 	Any	%quote(                 Establish a condition that AT LEAST ONE variable in a list must satisfy.);
		%put;
		%put B;
		%put 	Boxcox*	%quote(             Box-Cox transformation (for distribution normalization).);
		%put;
		%put C;
		%put 	Categorize*	%quote(         Categorize a set of variables in a given number of groups.);
		%put	Center*	%quote(             Center and optionally standardize a set of variables.);
		%*%put	CheckInputParameters	;
		%*%put	CheckRequiredParameters	;
		%put	CheckRepeated %quote(       Check the existence of observations with repeated key values in a dataset);
		%put 	%quote(                     and creates an output dataset containing those observations.);
		%put 	Colors %quote(              Create list of 10 color names to be used for graph symbols and lines.);
		%put	CompareLists %quote(        Compare two lists of names, and creates 3 datasets containing the list);
		%put	%quote(                     of the names found in both lists, of the names found in one list and not);
		%put	%quote(                     in the other, and viceversa.);
		%put	Compute	%quote(             Evaluate a given function by forcing the evaluation of its argument.);
		%put	Cov	%quote(                 Compute covariance matrix of a set of variables.);
		%put	CreateGroupVar*	%quote(     Create a variable identifying groups.);
		%put	CreateInteractions*	%quote( Create interactions between variables or interaction strings.);
		%put	CreateLags %quote(          Create a set of lagged variables with lag 1 to n.);
		%put	CreatePrevPostVar %quote(	Create a variable containing previous and posterior values of variables,);
		%put 	%quote(                     where the 'previous' and 'posterior' conditions are defined by a certain);
		%put 	%quote(                     matching criterion.);
		%put	CreateVarFromList %quote(   Create a dataset with a column containing the names in a list.);
		%put	CreateVarList %quote(       Create a dataset with a column containing the variable names passed in a);
		%put	%quote(                     list that are present in a dataset.);
		%put	CutMahalanobisChi %quote(   Detect multivariate outliers using Mahalanobis distance.);
		%put;
		%put D;
		%put	DefineSymbols %quote(       Define plotting symbols.);
		%*%put	Delet	;
		%*%put	DeleteMacroVar ;
		%put	Det	%quote(                 Compute determinant of a matrix.);
		%put 	DetectCollinearities*%quote(Detect collinearities among variables.);
		%put	DetectOutliersHadi %quote(  Detect univariate outliers using the Box-Cox transformation and the Hadi algorithm.);
		%put	DetectOutliersMAD*%quote(   Detect univariate outliers based on the MAD.);
		%put	Dfbetas* %quote(            Detect influential observations with the DFBETA criterion.);
		%put	Drop %quote(                Drop a set of variables in a dataset, regardless if they exist or not.);
		%put;
		%put E;
		%put	EvalExp %quote(             Force the evaluation of an expression.);
		%put	EvaluationChart* %quote(    Plot an evaluation chart for a model with a binary target.);
		%put 	ExecTimeStart %quote(       Start the clock to measure execution time of a macro.);
		%put 	ExecTimeStop %quote(        Measure the time elapsed since macro ExecTimeStart was last called.);
		%*%put	Exist	;
		%put	ExistData %quote(           Check if a dataset exists.);
		%put	ExistMacroVar %quote(       Check if a macro variable exists.);
		%*%put	ExistOption	;
		%put	ExistVar %quote(            Check if all variables in a given list exist in a dataset.);
		%put;
		%put F;
		%put	FindInList %quote(          Find a set of names in a list and returns their word position.);
		%put	FindMatch %quote(           Find the names in a list that contain a given keyword.);
		%put	FreqMult* %quote(           Compute and store the frequencies of a list of variables in an output);
		%put 	%quote(                     dataset.);
		%put;
		%put G;
		%put	GainsChart* %quote(         Plot the Gains Chart for a model with a binary target.);
		%*%put	GetDataName	;
		%*%put	GetDataOptions	;
		%*%put	GetLibraryName	;
		%put	Getnobs	%quote(             Get the nro. of observations and variables in a dataset.);
		%put	GetNroElements %quote(      Get the nro. of elements in a list.);
		%put	GetStat	%quote(             Get the value of ONE specified statistic for a set of variables);
		%put	%quote(                     in a dataset.);
		%put	GetVarList %quote(          Get the list of variables associated with more complex listing);
		%put	%quote(                     %(like hyphen, _NUMERIC_, etc.%).);
		%put	GetVarNames	%quote(         Get the names of the variables present in a dataset.);
		%put	GetVarOrder	%quote(         Get the order in which variables are stored in a dataset.);
		%put 	GetVarType %quote(          Get the type of a variable (C(haracter) or N(umeric)) in a dataset.);
		%*%put	GraphStrata	;
		%put	GraphXY	%quote(             Make a 2D plot of Y vs. X);
		%put;
		%put H;
		%put	Hadi* %quote(               Robustly detect multivariate oultiers using Hadi method.);
		%put	Help %quote(                Show this help information.);
		%put;
		%put I;
		%put    InformationValue* %quote(   Compute the Information Value of a set of variables for a binary target.);
		%put 	InsertInList %quote(        Insert a name in a list at a given position.);
		%put;
		%put K;
		%put	KS* %quote(                 Compute KS for a scoring model of a binary target.);
		%put;
		%put L;
		%put	LiftChart* %quote(          Plot the lift chart for a model with a discrete target.);
		%put	LogisticRegression %quote(  Perform a Logistic Regression iteratively by eliminating influential);
		%put	%quote(                     observations.);
		%put	LorenzCurve* %quote(        Plot the Lorenz Curve for a set of variables w.r.t. a non-negative target.);
		%put;
		%put M;
		%put	Mahalanobis	%quote(         Compute Mahalanobis distance of a set of variables.);
		%put	MakeList %quote(            Make a list by adding a prefix and suffix to each name in a given list.);
		%put	MakeListFromName %quote(    Make a list from a name used as root.);
		%put	MakeListFromVar %quote(     Make a list containing the values of a variable in a dataset.);
		%put	MakeVar	%quote(             Define global macro variables whose values are the elements of a given list.);
		%put	Means* %quote(              Execute a user friendly PROC MEANS.);
		%put	Merge* %quote(              Merge 2 datasets without having them sorted by the by variables.);
		%put	MPlot %quote(               Make multiple plots in the same window.);
		%put;
		%put O;
		%put 	ODSOutputClose %quote(      Close an open ODS output file.);
		%put 	ODSOutputOpen %quote(       Open an ODS output file for writing.);
		%put;
		%put P;
		%put	PartialPlots %quote(        Make partial plots to graphically assess the linearity of variables in a;
		%put 	%quote(                     linear regression.);
		%put 	PHTestPlot* %quote(         Make plots of survival curves to visually check proportional hazards assumption.);
		%put	PiecewiseTransf %quote(     Perform a linear piecewise transformation on continuous variables.); 
		%put 	PlotBinned* %quote(         Make 2D scatter or bubble plots of a target variable vs. binned continuous variables.);
		%put	PrintNameList %quote(       Print a list of names in one column in the output window.);
		%*%put	Pretty	;
		%*%put	PrintDataDoesNotExist	;
		%*%put	PrintRequiredParameterMissing	;
		%*%put	PrintVarDoesNotExist	;
		%put;
		%put Q;
		%put	QualifyVars %quote(         Automatically qualify variables into categorical or continuous.);
		%put	Qqplot %quote(              Make Q-Q plots for a set of variables.);
		%put;
		%put R;
		%put	RemoveFromList %quote(      Remove a set of names from a given list.);
		%put	RemoveRepeated %quote(      Remove repeated names from a given list.);
		%put	Rep %quote(                 Generate a list of one value repeated a number of times.);
		%*%put	ResetSASOptions	;
		%put;
		%put S;
		%put	Scatter	%quote(             Make 2D scatter plots among pairwise variables.);
		%put	SelectName(s) %quote(       Return a subset of names from a list.);
		%put	SelectVar %quote(           Return a list of variable names in a dataset matching a keyword.);
		%*%put	SetSASOptions	;
		%put	SetAxis %quote(             Create the string for an AXIS statement so that pretty values are shown.);
		%put	SetVarOrder	%quote(         Set the order in which variables are stored in a dataset.);
		%put	Sort* %quote(               User friendly PROC SORT. Several datasets can be sorted simultaneously.);
		%put	Standardize* %quote(        Center and standardize variables.);
		%put 	Subset %quote(              Subset a dataset with a WHERE condition by by variables.);
		%put	SymmetricAxis %quote(       Create the string for an AXIS statement so that the axis);
		%put	%quote(                     is symmetric around 0.);
		%put;
		%put T;
		%put	TestLogisticFit* %quote(    Test the fit of a logistic regression model.);
		%put	Transpose* %quote(          Transpose a dataset.);
		%put;
		%put V;
		%put	VariableImpact*	%quote(     Make plots to evaluate the univariate impact of a set of continuous variable);
		%put	%quote(                     on a binary target.);
	%end;
	%put;
	%put Use %nrstr(%Help%(<macro-name>%)) for a quick help on any of the macros marked with '*'.;
	%put Ex: %nrstr(%Help%(Boxcox%));
%*	%put Usar %nrstr(%Help%(<macro>%)) para una breve ayuda de cualquiera de las macros marcadas con '*'.;
%*	%put Ej: %nrstr(%Help%(Boxcox%));
	%put;
%end;
%else %if %sysfunc(indexw(&macrolist, %upcase(&macro))) %then
	%&macro(help=1);		%* This calls the macro with no parameters so that a help on how
							%* to call it is displayed;
%else %do;
	%put HELP: No help available for macro %upcase(&macro);
	%put HELP: Open the .SAS file with its name for help.;
%end;
%MEND Help;
