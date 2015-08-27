/* %MACRO SetVarOrder
Version: 1.00
Author: Daniel Mastropietro
Created: 13-Aug-04
Modified: 13-Aug-04

DESCRIPTION:
Sets the order of some variables in a dataset, so that the whole list
of variables need not be specified.

USAGE:
%SetVarOrder(data, vars, pos, var);

REQUIRED PARAMETERS:
- data:			Dataset where the order of the variables wants to be set.

- vars:			Blank-separated list of variables to move to another position.

- pos:			The relative position (after/before) where the variables listed in
				'vars' are placed with respect to the var listed in 'var'.

- var:			Variable that defines the relative position of the variables listed
				in 'vars'.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetVarNames
- %InsertInList

EXAMPLES:
1.- %SetVarOrder(test, x y, after, z);
This places variables X and Y in dataset TEST after variable z.

2.- %SetVarOrder(test, x, before, z);
This places variable X in dataset TEST before variable Z.

APPLICATIONS:
This macro avoids one having to use a FORMAT statement and list ALL the variables that one
wants to appear before a given variable in a dataset.
It becomes particularly useful when the dataset has hundreds of variables.
*/
&rsubmit;
%MACRO SetVarOrder(data, vars, pos, var) / store des="Orders variables in a dataset relative to other variables";
%local order;
%let order = %GetVarNames(&data);
%let order = %InsertInList(&order, &vars, &pos, &var);
data &data;
	format &order;
	set &data;
run;
%MEND SetVarOrder;
