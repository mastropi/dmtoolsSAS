/* %MACRO ExistData
Version: 1.00
Author: Daniel Mastropietro
Created: 19-Sep-03
Modified: 19-Sep-03

DESCRIPTION:
Determines if a dataset exists.

USAGE:
%ExistData(data);

REQUESTED PARAMETERS:
- data:			Name of the dataset whose existence is checked.
				It can have any data option as in any data= SAS option.

RETURNED VALUES:
The macro returns 1 if the dataset 'data' exists, 0 otherwise.

SEE ALSO:
- %Exist
- %ExistMacroVar
- %ExistOption
- %ExistVar
*/
%MACRO ExistData(data) / des="Returns 1 if a dataset exists, 0 otherwise";
%local exist;
%if %quote(&data) ~= %then
	%let exist = %sysfunc(exist(%scan(%quote(&data) , 1 , '(')));
		%** The scan function is to remove any data option that comes in &data;
%else
	%let exist = 0;
&exist
%MEND ExistData;
