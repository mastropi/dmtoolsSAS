/*
Created:		17-May-2016
Author:			Daniel Mastropietro
Description:	Hand tests for the %FreqMult macro.
				They were originally present below the macro definition but they were now removed from there.
				They could be set up as a Test Harness but I haven't done so yet.
*/

*** Tests;
data _fm_test_;
	length c $10;
	c = "test"; x = 2; y = 3.5; output;
	c = "test"; x = 20; y = -3.5; output;
	c = "daniel"; x = 8; y = 3.5; output;
	c = "test"; x = -2; y = 35.8E-9; output;
	c = "mastro"; x = .; y = -9999; output;
	c = "daniel"; x = 8; y = .; output;
	c = ""; x = 8; y = 33; output;
run;

proc format;
	value $cc  	"test", " " = "te"
				"daniel", "mastro" = "dm";
	value xx 	-2 = 'B'
				 8 = 'A'
				20 = '.';	%* Assign a number to "missing" value to see that missing values cannot be formatted to a missing value in numeric variables;
run;

proc freq data=_fm_test_ order=formatted;
	format x xx. c $cc.;
	tables x c / out=temp missing;
run;

* NOTE: On purpose list variables in non-alphabetical order to check that the output is alphabetically sorted and that the macro does not break;
title "Test 1A: Three mixed variables";
%FreqMult(_fm_test_, var=x y c, out=_fm_test_freq); proc print data=_fm_test_freq; run;
title "Test 2A: Two numeric variables, by character variable";
%FreqMult(_fm_test_, var=y x, by=c, out=_fm_test_freq); proc print data=_fm_test_freq; run;
title "Test 3A: Two mixed variables, by numeric variable (missing=1)";
%FreqMult(_fm_test_, var=c y, by=x, out=_fm_test_freq, missing=1); proc print data=_fm_test_freq; run;
title "Test 4A: One numeric variable, by descending variable (missing=1)";
%FreqMult(_fm_test_, var=y, by=c descending x, out=_fm_test_freq, missing=1); proc print data=_fm_test_freq; run;
title "Test 5A: Target variable";
%FreqMult(_fm_test_, target=c, var=x y, out=_fm_test_freq); proc print data=_fm_test_freq; run;

* Transpose = 1;
title "Test 1B: Three mixed variables (transposed)";
%FreqMult(_fm_test_, var=x y c, out=_fm_test_freq, transpose=1); proc print data=_fm_test_freq; run;
title "Test 2B: Two numeric variables, by character variable (transposed)";
%FreqMult(_fm_test_, var=y x, by=c, out=_fm_test_freq, transpose=1); proc print data=_fm_test_freq; run;
title "Test 3B: Two mixed variables, by numeric variable (transposed, missing=1)";
%FreqMult(_fm_test_, var=c y, by=x, out=_fm_test_freq, missing=1, transpose=1); proc print data=_fm_test_freq; run;
title "Test 4B: One numeric variable, by descending variable (transposed, missing=1)";
%FreqMult(_fm_test_, var=y, by=c descending x, out=_fm_test_freq, missing=1, transpose=1); proc print data=_fm_test_freq; run;
title "Test 5B: Target variable";
%FreqMult(_fm_test_, target=c, var=x y, out=_fm_test_freq, transpose=1); proc print data=_fm_test_freq; run;

* Formats;
title "Test 1AF: Three mixed variables (format on two)";
%FreqMult(_fm_test_, var=x y c, format=x xx. c $cc., out=_fm_test_freq); proc print data=_fm_test_freq; run;
title "Test 3AF: Two mixed variables, by numeric variable (missing=1) with format in BY variable and analysis variable";
%FreqMult(_fm_test_, var=c y, by=x, format=x xx. c $cc., out=_fm_test_freq, missing=1); proc print data=_fm_test_freq; run;
title "Test 5AF: Target variable with format";
%FreqMult(_fm_test_, target=c, var=x y, format=c $cc., out=_fm_test_freq); proc print data=_fm_test_freq; run;
title "Test 5AFM: Target variable with format (missing=1)";
%FreqMult(_fm_test_, target=c, var=x y, format=c $cc., missing=1, out=_fm_test_freq); proc print data=_fm_test_freq; run;

title "Test 1BF: Three mixed variables (transposed, format on two)";
%FreqMult(_fm_test_, var=x y c, format=x xx. c $cc., transpose=1, out=_fm_test_freq); proc print data=_fm_test_freq; run;
title "Test 5BFM: Target variable with format (missing=1)";
%FreqMult(_fm_test_, target=c, var=x y, format=c $cc., transpose=1, missing=1, out=_fm_test_freq); proc print data=_fm_test_freq; run;
title;

proc datasets nolist;
	delete _fm_test_ _fm_test_freq;
quit;
