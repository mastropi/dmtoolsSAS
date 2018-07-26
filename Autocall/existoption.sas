/* Checks if an option of the type '<option>=' exists in the string 'str'. If exists, returns 1, o.w. 0.
Only one option can be passed. 

SEE ALSO:
- %Exist
- %ExistData
- %ExistMacroVar
- %ExistVar
*/
%MACRO ExistOption(str , option) / des="Returns 1 if a given option exists in a string, 0 otherwise";
%local existOption;
%let str = %sysfunc(lowcase(&str));
%let option = %sysfunc(lowcase(&option));
%let existOption = %eval( %index(%sysfunc(compress(%quote(&str))) , &option=) > 0 );
&existOption
%MEND ExistOption;
