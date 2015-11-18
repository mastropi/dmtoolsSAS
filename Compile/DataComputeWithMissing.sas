/* MACRO %DataComputeWithMissing
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		12-Aug-2015
Modified: 		12-Aug-2015
SAS Version:	9.4

DESCRIPTION:
Generates DATA STEP statements to compute a variable in terms of other two variables, one of which
could generate missing values in the result.

Typically the formula is a division where a zero in the denominator generates missing values in the
computed ratio variable. This macro generates the required statements that avoid such a missing value
when the numerator variable is also 0.

USAGE:
%DataComputeWithMissing(
	varout,						*** Variable to create as the result of FORMULA.
	var,						*** Variable that does not generate missing values in VAROUT.
	varmiss,					*** Variable that may generate missing vaues in VAROUT.
	valueout=0,					*** Value to assign to VAROUT when VAR takes the value VALUEOK.
	valueok=0,					*** Value taken by VAR that can avoid a missing value in VAROUT.
	valuemiss=0,				*** Value taken by VARMISS that generates missing values in VAROUT.
	formula=&var / &varmiss,	*** Formula to use to compute VAROUT.
	macrovar=_nmiss_ _nmissok_,	*** Name of the macro variables to store the count of missing and missing OK.
	end=lastobs);				*** Variable created in the data step that signals the last observation.

REQUIRED PARAMETERS:
- varout:			Variable to create in the data set being modified as a result of the operation
					on VAR and VARMISS given by FORMULA.

- var:				Variable that does not generate missing values in VAROUT when applying FORMULA.
					Typically this is the numerator variable in a division.

- varmiss:			Variable that may generate missing values in VAROUT when applying FORMULA.
					Typically this is the denominator variable in a division.

OPTIONAL PARAMETERS:
- valueout:			Value to assign to VAROUT when VAR takes the value VAROK.
					Typically this is used to assign 0 when both numerator and denominator are 0
					in a division.
					default: 0

- valueok:			Value taken by VAR that can avoid a missing value in VAROUT.
					Typically this is the value 0 in the case we are performing a division, that is:
					when the numerator takes the value 0 then division can be assigned the value 0
					regardless of the value of the denominator.
					default: 0

- valuemiss:		Value taken by VARMISS that generates missing values in VAROUT.
					Typically this is the value 0 as VARMISS is typically the denominator variable
					in a division.
					default: 0

- formula:			Expression or formula to use to compute VAROUT.
					default: VAR / VARMISS

- macrovar:			Name of the macro variables to store the number of would-be missing values and
					the number of actual missing values in VAROUT.
					The number of would-be missing cases are those that would be generated in VAROUT
					should there be no special calculation in the case when VAR=&valueok.
					The number of actual missing cases in VAROUT are the number of cases that resulted
					in missing value that could not be avoided because VAR takes a value that is
					different from &valueok.
					IMPORTANT: These macro variables should have different names if we are calling the
					macro in the same DATA STEP for different calculations.
					default: _nmiss_ _nmissok_

- end:				Name of the variable temporarily defined to signal the last observation
					in the SET statement of the data step where this macro call is included.
					This parameter is defined as part of the macro in order to give flexibility
					to the user that needs to avoid a variable existing in the data set to be
					overridden.
					default: _lastobs_

NOTES:
1.- This macro should only be called from within a DATA STEP.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None
*/
&rsubmit;
%MACRO DataComputeWithMissing(
		varout,
		var,
		varmiss,
		valueout=0,
		valueok=0,
		valuemiss=0,
		formula=&var/&varmiss,
		macrovar=_nmiss_ _nmissok_,
		end=_lastobs_) / store des="Generates data statements to handle missing values in a computed variable";
%local counter1;
%local counter2;
%let counter1 = %scan(&macrovar, 1, ' ');	%* Add an underscore as prefix and suffix in order to not override a potentially existing variable in the dataset;	
%let counter2 = %scan(&macrovar, 2, ' ');	%* Add an underscore as prefix and suffix in order to not override a potentially existing variable in the dataset;

	%* DATA STEP CODE;
	retain _&counter1 _&counter2 0;
	drop _&counter1 _&counter2 &end;
	if &varmiss ~= &valuemiss then
		&varout = &formula;
	else do;
		_&counter1 = _&counter1 + 1;
		if &var = &valueok then do;
			&varout = &valueout;
			_&counter2 = _&counter2 + 1;
		end;
		else
			&varout = .;
	end;
	if &end then do;
		call symput("&counter1", _&counter1);
		call symput("&counter2", _&counter2);
	end;
%MEND DataComputeWithMissing;
