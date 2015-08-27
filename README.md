# dmtoolsSAS
Data Mining Tools in SAS (SAS macros)

A set of SAS macros that support predictive modeling in terms of exploratory data analysis and model fit visualizations.
A set of macros that help in the manipulation of strings (such as variable names) is also included such as:
- Add suffix to a list of variable names to be used to name new transformed variables.
- Remove certain variables from a list of variable names (e.g. remove variables from a model).
- Create strings representing variable interactions.

The full list of macros grouped by topic or area of application is shown below:

## Macros categorized by application
(An asterisk (\*) next to the macro name indicates that help is available for the macro).

Use %Help(<macro-name>) for a quick help on any of the macros marked with '\*'.

Ex: %Help(PlotBinned)

#### DATA MANIPULATION
Categorize*          Categorize a set of variables in a given number of groups.
Center*              Center and optionally standardize a set of variables.
CheckRepeated        Check the existence of observations with repeated key values in a dataset
                     and creates an output dataset containing those observations.
CreateGroupVar*      Create a variable identifying groups.
CreateInteractions*  Create interactions between variables or interaction strings.
CreateLags           Create a set of lagged variables with lag 1 to n.
CreatePrevPostVar    Create a variable containing previous and posterior values of variables,
                     where the 'previous' and 'posterior' conditions are defined by a certain
                     matching criterion.
DataComputeWithMissing Generate data statements to handle missing values in a computed variable.
Drop                 Drop a set of variables in a dataset, regardless if they exist or not.
GetVarList           Get the list of variables in a dataset associated with more complex listing
                     (like x1-x9, _NUMERIC_, etc.).
GetVarNames          Get the names of the variables present in a dataset.
GetVarOrder          Get the order in which variables are stored in a dataset.
GetVarType           Get the type of a variable (C(haracter) or N(umeric)) in a dataset.
Merge*               Merge 2 datasets without having them sorted by the by variables.
SetVarOrder          Set the order in which variables are stored in a dataset.
Standardize*         Center and standardize variables.
Sort*                User friendly PROC SORT. Several datasets can be sorted simultaneously.
Subset               Subset a dataset with a WHERE condition by by variables.
Transpose*           Transpose a dataset.

#### EXPLORATORY DATA ANALYSIS
Boxcox*              Box-Cox transformation (for distribution normalization).
Cov                  Compute covariance matrix of a set of variables.
CutMahalanobisChi    Detect multivariate outliers using Mahalanobis distance.
Det                  Compute determinant of a matrix.
DetectOutliersHadi   Detect univariate outliers using the Box-Cox transformation and the Hadi algorithm.
DetectOutliersMAD*   Detect univariate outliers based on the MAD.
Hadi*                Robustly detect multivariate oultiers using Hadi method.
Mahalanobis          Compute Mahalanobis distance of a set of variables.
PHTestPlot*          Make plots of survival curves to visually check proportional hazards assumption.
Qqplot               Make Q-Q plots for a set of variables.

#### GENERAL STATISTICS
FreqMult*            Compute and store the frequencies of a list of variables in an output
                     dataset.
GetStat              Get the value of ONE specified statistic for a set of variables
                     in a dataset.
Means*               Execute a user friendly PROC MEANS.

#### GRAPHS
Colors               Create list of 10 color names to be used for graph symbols and lines.
DefineSymbols        Define plotting symbols.
GraphXY              Make a 2D plot of Y vs. X
MPlot                Make multiple plots in the same window.
PlotBinned*          Make 2D scatter or bubble plots of a target variable vs. binned continuous variables.
Scatter              Make 2D scatter plots among pairwise variables.
SetAxis              Create the string for an AXIS statement so that pretty values are shown.
SymmetricAxis        Create the string for an AXIS statement so that the axis
                     is symmetric around 0.

## MODELLING
DetectCollinearities*Detect collinearities among variables.
Dfbetas*             Detect influential observations with the DFBETA criterion.
EvaluationChart*     Plot an evaluation chart for a model with a categorical target.
GainsChart*          Plot the Gains Chart for a model with a binary target.
InformationValue*    Compute the Information Value of a set of variables for a binary target.
KS*                  Compute the KS statistic of a set of variables w.r.t. a binary target.
LiftChart*           Plot the Lift Chart for a model with a discrete target.
LogisticRegression   Perform a Logistic Regression iteratively by eliminating influential
                     observations.
LorenzCurve          Plot the Lorenz Curve for a set of variables w.r.t. a non-negative target.
PartialPlots         Make partial plots to graphically assess the linearity of variables in a
                     linear regression.
PiecewiseTransf      Perform a linear piecewise transformation on continuous variables.
QualifyVars          Automatically qualify variables into categorical or continuous.
TestLogisticFit*     Test the fit of a logistic regression model.
VariableImpact*      Make plots to evaluate the univariate impact of a set of continuous variable
                     on a binary target.

#### OTHER
Compute              Evaluate a given function by forcing the evaluation of its argument.
EvalExp              Force the evaluation of an expression.
ExistData            Check if a dataset exists.
ExistMacroVar        Check if a macro variable exists.
ExistVar             Check if all variables in a given list exist in a dataset.
Getnobs              Get the nro. of observations and variables in a dataset.
Help                 Show this help information.

#### STRING MANIPULATION
All                  Establish a condition that ALL variables in a list must satisfy.
Any                  Establish a condition that AT LEAST ONE variable in a list must satisfy.
CompareLists         Compare two lists of names, and creates 3 datasets containing the list
                     of the names found in both lists, of the names found in one list and not
                     in the other, and viceversa.
CreateVarFromList    Create a dataset with a column containing the names in a list.
CreateVarList        Create a dataset with a column containing the variable names passed in a
                     list that are present in a dataset.
FindInList           Find a set of names in a list and returns their word position.
FindMatch            Find the names in a list that contain a given keyword.
GetNroElements       Get the nro. of elements in a list.
InsertInList         Insert a name in a list at a given position.
MakeList             Make a list by adding a prefix and suffix to each name in a given list.
MakeListFromName     Make a list from a name used as root.
MakeListFromVar      Make a list containing the values of a variable in a dataset.
MakeVar              Define global macro variables whose values are the elements of a given list.
PrintNameList        Print a list of names in one column in the output window.
RemoveFromList       Remove a set of names from a given list.
RemoveRepeated       Remove repeated names from a given list.
Rep                  Generate a list of one value repeated a number of times.
SelectName(s)        Return a subset of names from a list.
SelectVar            Return a list of variable names in a dataset matching a keyword.

