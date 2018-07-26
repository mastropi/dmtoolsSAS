/* MACRO %CreateColorFormat
Version:	1.0
Author:		Daniel Mastropietro
Created:	07-Apr-2016
Modified:	07-Apr-2016

DESCRIPTION:
Creates a color ramp format based on the range of values taken by the given statistic
(e.g. mean) computed on the analyzed variable for each combination of a set of BY variables.

For now, only one analysis variable is supported at a time.

USAGE:
%CreateColorFormat(
	data, 			*** Input dataset. Dataset options are allowed.
	var,			*** One single numeric variable whose values define the color format.
	by,				*** Blank-separated list of BY variables for which the statistic in STAT is computed.
	fmtname,		*** Name of the color format to create. Maximum 8 characters!
	stat=mean,		*** Statistic to use for the analysis variable.
	library=WORK,	*** Library where the format should be stored.
	out=,			*** Output dataset with the color format definition.
	log=1);			*** Show messages in the log?

REQUIRED PARAMETERS:
- data:				Input dataset. Dataset options are allowed.

- var:				One single numeric variable whose values define the color ramp format.

- by:				Blank-separated list of BY variables by which the statistic given
					in STAT is computed on the analyzed variable.

- fmtname:			Name of the color format to create.
					The name must satisfy the restrictions given by SAS, such as:
					- maximum name length: 8 characters
					- cannot start with a number
					- cannot end with a number

OPTIONAL PARAMETERS:
- stat:				Statistic to use when computing the range of values taken by the analysis
					variable for each combination of the BY variables.
					default: mean

- library:			Library where the format should be stored.
					default: WORK

- out:				Output dataset where the color format is stored.
					default: (Empty)

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %CheckInputParameters
- %CreateFormatsFromCuts
- %ExecTimeStart
- %ExecTimeStop
- %Getnobs
- %Means
- %ResetSASOptions
- %SetSASOptions

APPLICATIONS:
1.- Create a color ramp format to use in PROC REPORT and PROC TABULATE outputs
to color cells based on their values.

REFERENCES:
- Using color formats in PROC REPORT, PROC TABULATE, etc.:
http://support.sas.com/kb/23/353.html

- Defining colors using RGB numbers (0-255) which are converted to hexadecimal codes as in CXFFA395:
http://blogs.sas.com/content/iml/2012/10/22/whats-in-a-name.html
*/
%MACRO CreateColorFormat(data, var, by, fmtname, stat=mean, library=WORK, out=, log=1, help=0) / des="Creates a color ramp format based on a range of variable values";
/*
TODO:
- (2016/04/08) Allow for several analysis variables. This requires that the %CreateFormatsFromCuts macro
be extended to create formats from different columns defining cuts.
*/


/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put CREATECOLORFORMAT: The macro call is as follows:;
	%put %nrstr(%CreateColorFormat%();
	%put data , (REQUIRED) %quote(      *** Input dataset. Dataset options are allowed.);
	%put var , (REQUIRED) %quote(       *** One single numeric variable whose values define the color format.);
	%put by , (REQUIRED) %quote(        *** Blank-separated list of BY variables for which the statistic in STAT is computed.);
	%put fmtname , (REQUIRED) %quote(   *** Name of the color format to create (maximum 8 characters!).);
	%put stat=mean , %quote(            *** Statistic to use for the analysis variable.);
	%put library=WORK , %quote(         *** Library where the color format should be stored.);
	%put out= , %quote(                 *** Output dataset where the format definition is stored.);
	%put log=1) %quote(                 *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(	data=&data, var=&var, varRequired=1,
									otherRequired=%quote(&by,&fmtname), requiredParamNames=data var by fmtname,
									check=by, macro=CREATECOLORFORMAT) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%local nobs;
%local var_min;
%local var_max;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put CREATECOLORFORMAT: Macro starts;
	%put;
	%put CREATECOLORFORMAT: Input parameters:;
	%put CREATECOLORFORMAT: - Input dataset = %quote(&data);
	%put CREATECOLORFORMAT: - var = %quote(          &var);
	%put CREATECOLORFORMAT: - by = %quote(           &by);
	%put CREATECOLORFORMAT: - fmtname = %quote(      &fmtname);
	%put CREATECOLORFORMAT: - stat = %quote(         &stat);
	%put CREATECOLORFORMAT: - library = %quote(      &library);
	%put CREATECOLORFORMAT: - out = %quote(          &out);
	%put CREATECOLORFORMAT: - log = %quote(          &log);
	%put;
%end;

%SetSASOptions;
%ExecTimeStart;

/*-------------------------------- Parse input parameters -----------------------------------*/
%*** OUT=;
%if %quote(&out) = %then
	%let out = _ccf_colorcuts_;
/*-------------------------------- Parse input parameters -----------------------------------*/

%Means(
	&data,
	by=&by,
	var=&var,
	stat=&stat,
	name=value,
	out=_ccf_means_,
	log=0
);

proc sql;
	select
		min(value),
		max(value)
	into :var_min, :var_max
	from _ccf_means_;
quit;

data _ccf_means_;
	format &by fmtname value;
	set _ccf_means_;
	fmtname = "&fmtname";
run;

%* Create an initial format dataset from the summarized values of the analysis variable taken by the BY variables;
%* This dataset is updated below so that the format labels define a color ramp based on the minimum and maximum
%* summarized values;
%CreateFormatsFromCuts(_ccf_means_, dataformat=long, cutname=value, varfmtname=fmtname, out=_ccf_colorcuts_, log=0);

%callmacro(getnobs, _ccf_colorcuts_ return=1, nobs);
data &out;
	set _ccf_colorcuts_;
	%* Update the START and END variables so that their values are equally spaced based on the range of the analysis variables;
	if _N_ > 1 and _N_ < &nobs - 1 then
		end = compress(put(&var_min + (&var_max - &var_min) / (&nobs - 2) * (_N_ - 1), best8.));
	end_lag = lag(end);
	if _N_ > 1 and _N_ < &nobs then
		start = end_lag;
	%* Color labels;
	array rgb(3) _TEMPORARY_;
	array starts(3) _TEMPORARY_;
	array stops(3) _TEMPORARY_;
	array slopes(3) _TEMPORARY_;
	array hex1(3) $ _TEMPORARY_;
	array hex2(3) $ _TEMPORARY_;
	array hex(3) $ _TEMPORARY_;
	%* Define the start and stop values for each color RGB;
	starts(1) = 0; 		stops(1) = 255;
	starts(2) = 255; 	stops(2) = 0;
	starts(3) = 0;		stops(3) = 0;
	do i = 1 to dim(rgb);
		slopes(i) = (stops(i) - starts(i)) / (&nobs - 1);
		rgb(i) = round(starts(i) + slopes(i) * (_N_ - 1));
		%* Convert to hexadecimal form (e.g. CXFF6060 for r = 255, g = 96, b = 96);
		hex1(i) = substr("0123456789ABCDEF", floor(rgb(i) / 16) + 1, 1);
		hex2(i) = substr("0123456789ABCDEF", rgb(i) - floor(rgb(i) / 16) * 16 + 1, 1);
		hex(i) = cats(hex1(i), hex2(i));
	end;
	length rgbcx $8;
	rgbcx = "CX";
	do i = 1 to dim(rgb);
		rgbcx = cats(rgbcx, hex(i));
	end;
	label = rgbcx;
	drop end_lag i rgbcx;
run;

proc format cntlin=&out fmtlib library=&library;
run;

%if &log and %upcase(%quote(&out)) ~= _CCF_COLORCUTS_ %then %do;
	%put CREATECOLORFORMAT: Output dataset %upcase(&out) created with;
	%put CREATECOLORFORMAT: the color format definition for variable %upcase(&var).;
	%put CREATECOLORFORMAT: Format %upcase(&fmtname) created defining a color ramp;
	%put CREATECOLORFORMAT: based on the range of values of variable %upcase(&var);
	%put CREATECOLORFORMAT: computed with %upcase(&stat) summary statistic;
	%put CREATECOLORFORMAT: on each combination of BY variables %upcase(&by).;
%end;

%*** Cleanup;
%* Delete temporary datasets;
proc datasets nolist;
	delete 	_ccf_means_
			_ccf_colorcuts_;
quit;

%if &log %then %do;
	%put;
	%put CREATECOLORFORMAT: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;

%end;	%* %if ~%CheckInputParameters;

%MEND CreateColorFormat;
