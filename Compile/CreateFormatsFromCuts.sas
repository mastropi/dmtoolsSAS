/* MACRO %CreateFormatsFromCuts
Version:	1.03
Author:		Daniel Mastropietro
Created:	07-Apr-2016
Modified:	18-Sep-2018 (Previous: 16-Sep-2018, 07-Apr-2016)

DESCRIPTION:
Creates interval-based numeric formats based on a set of cut values separating the intervals.
The formats definition is saved in an output dataset and optionally stored in a catalog (i.e. created on the fly).

USAGE:
%CreateFormatsFromCuts(
	data, 				*** Input dataset containing the cut values. Dataset options are allowed.
	dataformat=wide,	*** Format in which cut values are given in input dataset: WIDE (one row per format) or LONG.
	cutname=,			*** Name of the variable in input dataset containing the cut values when DATAFORMAT=LONG.
	varname=,			*** Name of the variable in input dataset containing the variables for which formats are defined.
	varfmtname=,		*** Name of the variable in input dataset containing the names of the formats to create (max 8 characters!).
	includeright=1,		*** Whether the format intervals defined by the cut values should be closed on the right.
	adjustranges=0, 	*** Whether to adjust the format intervals on the INCLUDE side in order to avoid non-inclusion of values due to precision loss.
	adjustcoeff=1E-9,	*** Coefficient to use to adjust the format intervals if ADJUSTRANGES=1.
	prefix=F,			*** Prefix to use in the automatically generated format name when VARFMTNAME is empty.
	out=,				*** Output dataset containing the format definitions.
	storeformats=0,		*** Whether to run the formats and store them in a catalog.
	showformats=1,		*** Whether to show the formats definition in the output window when STOREFORMATS=1.
	library=WORK,		*** Library where the catalog containing the formats should be stored when STOREFORMATS=1.
	log=1);				*** Show messages in the log?

REQUIRED PARAMETERS:
- data:				Input dataset containing the cut values. Dataset options are allowed.

OPTIONAL PARAMETERS:
- dataformat:		Format of the input dataset: either WIDE, meaning that there is a format
					definition per row, or LONG, meaning that the cut values to use for the
					different formats are given in a single column, so that each format
					definition spans several rows.

					In the WIDE format, the cut values span several columns and the number
					of cut values may be different for each format to create. The variables
					defining the cut values can have any name, they are identified by looking
					at the first numeric variable encountered starting from the left up to the
					last consecutive numeric variable.
					For example, the following dataset:
					VAR FMTNAME	 V1    V2   V3 LABEL
					"x"	"fx"	0.5	  0.8	 . "variable x"
					"y"	"fy"	  3	    .    . "variable y"
					"z"	"fz"	 -2	    6	12 "variable z"
					considers variables V1, V2 and V3 as the cut values to use to define the
					formats.

					Possible values: wide, long
					default: wide

- cutname:			Name of the variable in the input dataset containing the cut values when
					DATAFORMAT=LONG.
					default: (empty)

- varname:			Name of the variable in the input dataset containing the variable names
					associated with each format to crete.
					Note that VARNAME cannot be empty if DATAFORMAT=LONG and FMTNAME is empty.
					default: (empty)

- fmtname:			Name of the variable in the input dataset containing the names of the
					formats to create.
					Format names given in this variable must satisfy the restrictions imposed
					by SAS, such as:
					- maximum name length: 8 characters when option VALIDFMTNAME=V7 or
					32 characters when option VALIDFMTNAME=LONG.
					- cannot start with a number
					- cannot end with a number

					When no value is given, the format name is generated automatically and has
					the form <prefix><nnnn><S> where:
					- <prefix> is the first 3 characters of parameter PREFIX.
					- <nnnn> is a 4-digit number that can range from 0001 to 9999 used as format
					identifier.
					- <S> is either R or L defining whether each interval defined by the
					numeric format is closed to the Right or closed to the Left.
					This directly depends on the value of parameter INCLUDERIGHT: when this is
					equal to 1 then <suffix>=R, o.w. <suffix>=L.
					
					The identifiers given by the <nnnn> midfix are consecutive numbers which
					identify each format based on the order defined by the alphabetical order of
					the VARNAME column when this is given or by the order of the input dataset
					records when VARNAME is empty.

					Note that FMTNAME cannot be empty if DATAFORMAT=LONG and VARNAME is empty.
					default: (empty)

- includeright:		Flag indicating whether the intervals defined by the cut values should be
					closed on the right.
					Possible values: 0 => No, 1 => Yes
					default: 1

- adjustranges:		Flag indicating whether the intervals on the INCLUDE side should be adjusted
					in order to avoid non incorrect boundary value due to precision loss when
					converting those values to character (since the values are stored as characters
					when defining the formats).
					This is adjustment is particularly useful when dealing with floating point
					variables having many repeated observations with the same floating point value
					which will likely make up a boundary value with potential precision loss.
					The value is adjusted by an absolute amount of -ADJUSTCOEFF for left boundaries
					and by an absolut amount of +ADJUSTCOEFF for right boundaries.
					Possible values: 0 => No, 1 => Yes
					default: 0

- adjustcoeff:		Coefficient to use to adjust the format intervals if ADJUSTRANGES=1.
					See ADJUSTRANGES above for more details.
					default: 1E-9

- prefix:			Prefix to use in the automatically generated format name when VARFMTNAME is
					empty.
					The prefix is truncated to its first 3 characters in order to abide by the
					SAS rule that format names should be at most 8 characters long.
					The prefix cannot be empty and cannot be a number.
					default: F

- out:				Output dataset where the format definitions are saved.
					This dataset has the structure required by the CNTLIN dataset in PROC FORMAT
					and thus can be used like that to store the formats in a catalog.

					The following variables are included in the OUTFORMAT dataset:
					- var: analyzed variable name (if VARNAME is not empty).
					- fmtname: format name. This can be 8-character long or 32-character long
					depending on the value of the VALIDFMTNAME option (V7 => 8-character; LONG => 32-character).
					- type: type of format (equal to "N" which means "numeric").
					- start: left end value of each category (length 20).
					- end: right end value of each category (length 20).
					- sexcl: flag Y/N indicating whether the start value is included/excluded
					in each category.
					- eexcl: flag Y/N indicating whether the end value is included/excluded
					in each category.
					- label: label to use for each category (length 200).

					IMPORTANT: It is assumed that the number of digits including decimal point
					in the start and end values of each category is not larger than 20 when those
					numbers are expressed in BEST32. format.

					default: _FORMATS_

- storeformats:		Flag indicating whether to run the formats and store them in a catalog
					in the library specified by parameter LIBRARY.
					Possible values: 0 => No, 1 => Yes
					default: 0

- showformats:		Flag indicating whether to show the formats definition when STOREFORMAT=1.
					Only the formats defined now are shown.
					Possible values: 0 => No, 1 => Yes
					default: 1

- library:			Library where the catalog containing the formats should be stored when
					STOREFORMATS=1.
					default: WORK

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckInputParameters
- %ExecTimeStart
- %ExecTimeStop
- %MakeList
- %ResetSASOptions
- %SetSASOptions

APPLICATIONS:
1.- Create a set of numeric formats from the output dataset generated by the macros %InformationValue
or %PiecewiseTransf so that variables can be analyzed based on the groups, bins or pieces defined by
those macros.
In fact, these macros already have embedded the capability of generating such formats.

SEE ALSO:
- %CreateColorFormat
- %InformationValue
- %PiecewiseTransf
*/
&rsubmit;
%MACRO CreateFormatsFromCuts(
		data,
		dataformat=wide,
		cutname=,
		varname=,
		varfmtname=,
		prefix=F,
		includeright=1,
		adjustranges=0,
		adjustcoeff=1E-9,
		out=_FORMATS_,
		storeformats=0,
		showformats=1,
		library=WORK,
		log=1,
		help=0) / store des="Creates numeric formats from a dataset containing cut values";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put CREATEFORMATSFROMCUTS: The macro call is as follows:;
	%put %nrstr(%CreateFormatsFromCuts%();
	%put data , (REQUIRED) %quote( *** Input dataset containing the cut values. Data options are allowed.);
	%put dataformat=wide , %quote( *** Format in which cut values are given in input dataset: WIDE or LONG.);
	%put cutname= , %quote(        *** Name of the variable in input dataset containing the cut values when DATAFORMAT=LONG.);
	%put varname= , %quote(        *** Name of the variable in input dataset containing the variables for which formats are defined.);
	%put varfmtname= , %quote(     *** Name of the variable in input dataset containing the names of the formats to create (max 8 characters!).);
	%put prefix=F , %quote(        *** Prefix to use in the automatically generated format name when VARFMTNAME is empty.);
	%put includeright=1 , %quote(  *** Whether the format intervals defined by the cut values should be closed on the right.);
	%put adjustranges=0 , %quote(  *** Whether to adjust the format intervals on the INCLUDE side in order to avoid non-inclusion of values due to precision loss.);
	%put adjustcoeff=1E-9 , %quote(*** Coefficient to use to adjust the format intervals if ADJUSTRANGES=1.);
	%put out=_FORMATS_ , %quote(   *** Output dataset containing the format definitions.);
	%put storeformats=0 , %quote(  *** Whether to run the formats and store them in a catalog.);
	%put library=WORK , %quote(    *** Library where the catalog containing the formats should be stored when STOREFORMATS=1.);
	%put log=1) %quote(            *** Show messages in the log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(	data=&data, varRequired=0,
									requiredParamNames=data, check=cutname varname varfmtname, macro=CREATEFORMATSFROMCUTS) %then %do;
	%ShowMacroCall;
%end;
%else %do;

%SetSASOptions;
%ExecTimeStart;

%local cuts_long;		%* Name of the dataset containing the cut values in long format (i.e. all cut values in one column);
%local fmtnamelen;		%* Length to use for the FMTNAME variable in the output dataset;
%local formatnames;		%* Names of defined formats;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put CREATEFORMATSFROMCUTS: Macro starts;
	%put;
	%put CREATEFORMATSFROMCUTS: Input parameters:;
	%put CREATEFORMATSFROMCUTS: - Input dataset = %quote(&data);
	%put CREATEFORMATSFROMCUTS: - dataformat = %quote(   &dataformat);
	%put CREATEFORMATSFROMCUTS: - cutname = %quote(      &cutname);
	%put CREATEFORMATSFROMCUTS: - varname = %quote(      &varname);
	%put CREATEFORMATSFROMCUTS: - varfmtname = %quote(   &varfmtname);
	%put CREATEFORMATSFROMCUTS: - prefix = %quote(       &prefix);
	%put CREATEFORMATSFROMCUTS: - includeright = %quote( &includeright);
	%put CREATEFORMATSFROMCUTS: - adjustranges = %quote( &adjustranges);
	%put CREATEFORMATSFROMCUTS: - adjustcoeff = %quote(  &adjustcoeff);
	%put CREATEFORMATSFROMCUTS: - out = %quote(          &out);
	%put CREATEFORMATSFROMCUTS: - storeformats = %quote( &storeformats);
	%put CREATEFORMATSFROMCUTS: - library = %quote(      &library);
	%put CREATEFORMATSFROMCUTS: - log = %quote(          &log);
	%put;
%end;

/*--------------------------------- Parse input parameters ----------------------------------*/
%*** VARNAME= and VARFMTNAME=;
%* Read input dataset and rename variable containing format names (if any) to FMTNAME;
data _CF_cuts_;
	%if %quote(&varname) ~= or %quote(&varfmtname) ~= %then %do;
	%* Order the variables so that first comes the column containing the variable names and then the column containing the format names;
	%* This is done for easier processing of the input dataset below;
	format &varname &varfmtname;
	%end;
	set &data;
	%if %quote(&varfmtname) ~= %then %do;
	rename &varfmtname = fmtname;
	%end;
run;

%*** PREFIX=;
%* Keep just the first 3 characters of the PREFIX (to avoid automatic format names longer than 8 characters);
%let prefix = %substr(&prefix, 1, %sysfunc( min(%sysfunc(length(&prefix)), 3) ));

%*** Check the value of the VALIDFMTNAME option to decide on the length of the FMTNAME variable in the output dataset;
%if %upcase(%sysfunc(getoption(validfmtname))) = V7 %then
	%let fmtnamelen = 8;
%else
	%let fmtnamelen = 32;

%*** DATAFORMAT=;
%if %upcase(%quote(&dataformat)) = WIDE %then
	%goto WIDE;
%else %do;
	%let cuts_long = _CF_cuts_;
	%goto LONG;
%end;

/*-------------------------------- CUT VALUES GIVEN IN WIDE FORMAT --------------------------*/
%WIDE:
%local dsid;
%local error;
%local j jstart jstop;
%local found;
%local ncol;
%local rc;
%local stop;
%local vartype;

%let error = 0;

%* Sort input dataset by VARNAME when no VARFMTNAME exists in the dataset so that the automacit names generated for the format names
%* correspond to the alphabetical order of the variables;
%if %quote(&varname) ~= and %quote(&varfmtname) = %then %do;
	proc sort data=_CF_cuts_;
		by &varname;
	run;
%end;

%* Read the variable names containing the cut values;
%* These are given by the consecutive numeric variables found in the input dataset from the first found up to the last one found;
%let dsid = %sysfunc(open(_CF_cuts_));
%* Compute the number of columns in the dataset;
%let ncol = %sysfunc(attrn(&dsid, NVARS));
%if &ncol < 1 %then %do;
	%put CREATEFORMATSFROMCUTS: ERROR - Dataset %upcase(&data) must have at least 1 column.;
	%let error = 1;
%end;
%else %do;
	%* Look for the first numeric column where it is assumed that the cut values start;
	%let j = 1;
	%let found = 0;
	%let stop = 0;
	%let jstop = ;	%* column number at which to stop reading the cut values (should be set to empty at the beginning);
	%do %while(&j <= &ncol and ~&stop);
		%let vartype = %sysfunc(vartype(&dsid, &j));
		%if %upcase(&vartype) = N and ~&found %then %do;
			%let jstart = &j;	%* column number at which to start reading the cut values;
			%let found = 1;
		%end;
		%else %if %upcase(&vartype) = C and &found %then %do;
			%let jstop = %eval(&j - 1);	%* the column number at which to stop reading the cut values should be the previous column since the current column is of character type);
			%let stop = 1;
		%end;
		%let j = %eval(&j + 1);
	%end;
	%if ~&found %then %do;
		%put CREATEFORMATSFROMCUTS: ERROR - No numeric variables were found in dataset %upcase(&data) containing the cut values.;
		%let error = 1;
	%end;
	%else %do;
		%* Check whether &jstop is empty. In that case, set it to &ncol because it means that no character variable was
		%* found after the set of numeric columns and therefore we should read all the cut values from &jstart to &ncol;
		%if &jstop = %then
			%let jstop = &ncol;

		%* Read the variable names containing the cutvalues (this is used when creating the OUTFORMAT= dataset);
		%let varcuts = ;
		%do j = &jstart %to &jstop;
			%let varcuts = &varcuts %sysfunc(varname(&dsid, &j));
		%end;
	%end;
%end;
%let rc = %sysfunc(close(&dsid));

%if ~&error %then %do;
	%* Transpose dataset to create the CNTLIN dataset to use as input to PROC FORMAT;
	%* NOTE: This assumes that the cut values for each variable are sorted in ascending order!;
	data _CF_cuts_t;
		keep &varname fmtname cut;
		length fmtname $&fmtnamelen;
		%* Rename the variable name containing the format names to FMTNAME if the column with the format names are given in the CUTS dataset;
		set _CF_cuts_;
		%if %quote(&varfmtname) = %then %do;
		retain count 1;
			%if &includeright %then %do;
		retain suffix "R";
			%end;
			%else %do;
		retain suffix "L";
			%end;
		%* Create the variable FMTNAME since it was not provided by the user in the CUTS dataset;
		%* NOTE: The length of the format names must be 8 (unless option VALIDFMTNAME=LONG,
		%* which is actually the default starting SAS 9.2(?), but I am still assuming that the
		%* maximum format name length is 8 characters) and cannot end in a number;
		fmtname = cats("&prefix", put(count, z4.), suffix);
		count + 1;
		%end;
		array acuts(*) &varcuts;
		do i = 1 to dim(acuts);
			cut = acuts(i);
			output;
		end;
	run;

	%* Set a couple of macro variables so that the FINAL step works fine;
	%let cuts_long = _CF_cuts_t;	%* Name of the dataset containing the cut values in one column;
	%let cutname = cut;				%* Name of the variable containing the cut values;

	%goto FINAL;
%end;	%* %if ~&error;
%else
	%goto FINALIZE;
/*-------------------------------- CUT VALUES GIVEN IN WIDE FORMAT --------------------------*/


/*-------------------------------- CUT VALUES GIVEN IN LONG FORMAT --------------------------*/
%LONG:
%local byvars;		%* Variables to use as BY variables when updating the _CF_cuts_ dataset;
%local byst;		%* BY statement to use when updating the _CF_cuts_ dataset;
%local lastst;		%* LAST. statement to use when updating the _CF_cuts_ dataset;

%* Sort input dataset by VARNAME CUTNAME or by VARFMTNAME CUTNAME or by CUTNAME depending on what variables are given
%* in the input parameters;
proc sort data=_CF_cuts_;
	by &varname &varfmtname &cutname;
run;

%let byvars = ;
%let byst = ;
%if %quote(&varname) ~= or %quote(&varfmtname) ~= %then %do;
	%if %quote(&varname) ~= %then
		%let byvars = &varname;
	%if %quote(&varfmtname) ~= %then
		%let byvars = &byvars fmtname;		%* Recall that &VARFMTNAME as been renamed to FMTNAME at the beginning;
	%let byst = by &byvars;
%end;
%let lastst = %MakeList(&byvars, prefix=LAST., sep=or, log=0);

data _CF_cuts_;
	keep &varname fmtname &cutname;
	length fmtname $&fmtnamelen;
	set _CF_cuts_;
	%* BY variable for the FIRST and LAST variables in case VARNAME or FMTNAME is given;
	%* Note that both variables can be given and the same variable name may have more than one format names;
	&byst;

	%* Create the format name if this information is not provided in the input dataset;
	%if %quote(&varfmtname) = %then %do;
	retain count 1;
		%if &includeright %then %do;
	retain suffix "R";
		%end;
		%else %do;
	retain suffix "L";
		%end;
	%* Create the variable FMTNAME since it was not provided by the user in the CUTS dataset;
	%* NOTE: The length of the format names must be 8 (unless option VALIDFMTNAME=LONG,
	%* which is actually the default starting SAS 9.2(?), but I am still assuming that the
	%* maximum format name length is 8 characters) and cannot end in a number;
	fmtname = cats("&prefix", put(count, z4.), suffix);
		%if %quote(&byst) ~= %then %do;
	if &lastst then
		count + 1;
		%end;
	%end;
run;
%* Set macro variable CUTS_LONG with the name of the dataset to use in the FINAL block when creating the output dataset;
%let cuts_long = _CF_cuts_;

%goto FINAL;
/*-------------------------------- CUT VALUES GIVEN IN LONG FORMAT --------------------------*/


%FINAL:
%* Create output dataset with the formats definition;
%* Create output dataset with the formats definition;
%* Define adjust coefficients tha are optionally applied for the INCLUDED range border
%* (which depends on the INCLUDERIGHT= parameter) to avoid not inclusion of cases due to
%* precision loss...;
%local adjust_coeff_start;
%local adjust_coeff_end;
data &out;
	keep &varname fmtname type start end sexcl eexcl label;
	format &varname fmtname type start end sexcl eexcl label;
	length %if %quote(&varname) ~= %then %do; &varname $32 %end; fmtname $&fmtnamelen type $1 start $20 end $20 sexcl $1 eexcl $1 label $200;
	set &cuts_long;
	where &cutname ~= .;	%* Remove missing values of the CUT variable (when data format is WIDE, these values come from variables with number of cuts less than the maximum);
	by fmtname;
	retain type "N";		%* N = Numeric variables;
	retain start;
	retain count;

	%* Convert the START and END values to string (they should be string because of the LOW and HIGH values;
	%* Note that optionally (if ADJUSTRANGES=1) and the border value is NOT an integer (i.e. if contains a decimal point),
	%* the range border value to INCLUDE is adjusted by a VERY small quantity in order to try to avoid misplacement
	%* of values into the incorrect range due to precision loss
	%* (SAS is known to have these problems such as vale -0.1 being stored as -0.999999999).
	%* Note that this adjustment affects BOTH contiguous ranges, so NON-overlapping is GUARANTEED;

	%* First check if we need to adjust the current cut value (range end value);
	%if &adjustranges %then %do;
		_cutvalue_char = put(&cutname, best32.);
		%* Check if the value is NOT integer (i.e. it contains a decimal point);
		if index(_cutvalue_char, '.') > 0 then
		%if &includeright %then %do;
			&cutname = &cutname + &adjustcoeff;	%* Give a little more space to the right of the range;
		%end;
		%else %do;
			&cutname = &cutname - &adjustcoeff;	%* Give a little more space to the left of the range;
		%end;
	%end;
	start = compress( put(lag(&cutname), best32.) );
	end = compress( put(&cutname, best32.) );

	%* Define open and close parentheses depending on the INCLUDERIGHT= parameter;
	%if &includeright %then %do;
	openparen = "(";
	closeparen = "]";
	sexcl = "Y";
	eexcl = "N";
	%end;
	%else %do;
	openparen = "[";
	closeparen = ")";
	sexcl = "N";
	eexcl = "Y";
	%end;
	if first.fmtname then do;
		%* Update the values of the first case;
		count = 0;
		start = "LOW";
		openparen = "[";
		sexcl = "N";
	end;
	%* Number the labels so that they can be sorted correctly in alphabetical order;
	count + 1;
	label = cat(put(count, z3.), " - ", openparen, compress(start), ", ", compress(end), closeparen);
	output;
	if last.fmtname then do;
		count + 1;
		%* Define the open parenthesis depending on the INCLUDERIGHT= parameter;
		%* This is important here in case there is only one cut for the variable and if that is the case
		%* this last record will have the settings of the first record (defined in block FIRST.FMTNAME above)
		%* and we do not want that;
		%if &includeright %then %do;
		openparen = "(";
		sexcl = "Y";
		%end;
		%else %do;
		openparen = "[";
		sexcl = "N";
		%end;
		start = end;
		end = "HIGH";
		closeparen = "]";
		eexcl = "N";
		label = cat(put(count, z3.), " - ", openparen, compress(start), ", ", compress(end), closeparen);
		output;
	end;
	drop _cutvalue_char;
run;
%if &storeformats %then %do;
	%if &log %then
		%put CREATEFORMATSFROMCUTS: Storing formats defined in output dataset %upcase(&OUT) in library %upcase(&library)...;
	%* Read the names of the formats to create so that we show the format definition (with FMTLIB) just for them;
	proc sql noprint;
		select distinct fmtname into :formatnames separated by ' '
		from &out;
	quit;
	proc format cntlin=&out library=&library %if &showformats %then %do; fmtlib %end;;
		%if &showformats %then %do;
		select &formatnames;
		%end;
	run;
%end;

%goto FINALIZE;

%FINALIZE:
proc datasets nolist;
	delete 	_CF_cuts_
			_CF_cuts_t;
quit;

%if &log %then %do;
	%put;
	%put CREATEFORMATSFROMCUTS: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;

%end;	%* %if ~%CheckInputParameters;
%MEND CreateFormatsFromCuts;
