/* MACRO %GainsChart --> Calls %EvaluationChart with specific parameter values
Version: 	2.01
Author: 	Daniel Mastropietro
Created: 	23-Nov-04
Modified:	22-Jun-2012 (added the ODSFILE, ODSFILETYPE and LIBFORMAT parameters)

DESCRIPTION:
This macro plots a Gains chart for a model with a dichotomous target variable.
For more information see the macro %EvaluationChart.

Keywords used below:
LR = Logistic Regression
DT = Decision Tree

USAGE:
%GainsChart(
	data,				*** Input dataset
	target=y,			*** Target variable
	score=p,			*** Score variable
	by=,				*** By variables
	event=1,			*** Event of interest
	model=LR,			*** Model used to generate the score (LR/Reg, DT/Tree)
	leaf=leaf,			*** Name of variable defining the leaves in a DT
	step=,				*** Step to use for the score variable when constructing the plot
	groups=,			*** Nro. of percentile groups for plot
	percentiles=,		*** Percentiles to use in plot
	plot=1,				*** Make plot of Evaluation Chart?
	overlay=0,			*** Overlay the Evaluation Charts on the same plot?
	best=1,				*** Show the Best Lift/Gains Curve?
	pointlabels=0,		*** Use pointlabels showing quantile size?
	points=1,			*** Show points indicating plotting points?
	legend=1,			*** Show legend?
	bands=0,			*** Show confidence bands for the Gains Chart?
	confidence=0.95		*** Confidence level for the Gains confidence bands.
	out=,				*** Output dataset with the data to make the evaluation charts?
	outstat=,			*** Output dataset with the KS Statistic and Gini Index
	odsfile=,			*** Name of the file where the Evaluation Chart is saved
	odsfiletype=pdf,	*** Type of the file specified in ODSFILE
	libformat=,			*** Library where the target formats created by the macro are stored
	print=,				*** Show KS and Gini Index in the output window?
	log=1);				*** Show messages in the log?

NOTES:
This macro calls %EvaluationChart with option chart=GAINS.
See that macro for more information.
*/
&rsubmit;
%MACRO GainsChart(	data,
					target=y,
					score=p, 
					by=,
					event=1,
					model=LR,
					leaf=leaf,

					step=,
					groups=, 
					percentiles=,

					plot=1,
					overlay=0,
					best=,
					pointlabels=0,
					points=1,
					legend=1,
					bands=0,
					confidence=0.95,

					out=,
					outstat=,

					odsfile=,
					odsfiletype=pdf,

					libformat=,
					print=1,
					log=1, 
					help=0) / store des="Plots Gains Charts for a scoring model";
%if &log %then
	%put GAINSCHART: Calling %nrstr(%EvaluationChart) with option chart=GAINS...;
%EvaluationChart(	&data,
					target=&target,
					score=&score,
					by=&by,
					event=&event,
					model=&model,
					leaf=&leaf,
					step=&step,
					groups=&groups, 
					percentiles=&percentiles, 
					chart=GAINS,					/* THIS PARAMETER IS FIXED */
					plot=&plot,
					overlay=&overlay,
					best=&best,
					pointlabels=&pointlabels,
					points=&points,
					legend=&legend,
					bands=&bands,
					confidence=&confidence,
					out=&out,
					outstat=&outstat,
					odsfile=&odsfile,
					odsfiletype=&odsfiletype,
					libformat=&libformat,
					print=&print,
					log=&log, 
					help=&help);
%MEND GainsChart;


