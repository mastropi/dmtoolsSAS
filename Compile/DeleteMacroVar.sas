/* MACRO %DeleteMacroVar
Version: 1.00
Author: Daniel Mastropietro
Created: 10-Jan-03
Modified: 17-Jul-03

DESCRIPTION:
Deletes GLOBAL macro variables.

USAGE:
%DeleteMacroVar(vars);

REQUESTED PARAMETERS:
- vars:			Unquoted blank-separated list of macro variables to delete.
				Use the keyword _ALL_ to delete all global macro variables.

NOTES:
- This macro is intended to be used in regular SAS language, i.e. not called
from within other modules. This is because the macro runs a data step. So
for example, if it is called from within IML, IML will terminate, since SAS
needs to run a data step;

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %GetNroElements

EXAMPLES:
- %DeleteMacroVar(var1 var2 x y);
*/
&rsubmit;
%MACRO DeleteMacroVar(vars) / store des="Deletes global macro variables";
/* NOTES:
1.- As for the note above, stating that this macro can only be used in regular
SAS language, the macro could be changed so that to avoid running a data step, using
%open and other stuff.
See code in SAS Help.doc under "CHECKING IF A MACRO VARIABLE EXITS".

2.- Only global macro variables can be deleted because %symdel only works with
global macro variables. I tried deleting a macro variable by deleting its entry
in the sashelp.vmacro dataset, but this does not delete the macro variable, it
only deletes the entry (which could also be dangerous...).
*/

/* %symdel &vars; */
/* The above is commented out because things like '%symdel var&i' do not work. It is interpreted by
   SAS as '%symdel var & i'.
   Also %symdel only applies to global variables. */

%local i nobs nro_vars var;
%local lastds notes_option;

/* NOTE: Do not call %SetSASOptions and %ResetSASOptions, because these macros refer to global
macro variables, which may be deleted if the parameter vars of this macro is equal to _ALL_.
Instead, I do what is done in SetSASOptions here. */
%let notes_option = %sysfunc(getoption(notes));
%let lastds = &syslast;		%*** Last dataset name;
options nonotes;			%*** Removing SAS notes;

%if %quote(%upcase(&vars)) = _ALL_ %then %do;
	data _DeleteMacroVar_vars_;
	    set sashelp.vmacro;
	run;
	data _null_;
	    set _DeleteMacroVar_vars_;
	    if upcase(scope) = "GLOBAL" then
      		call execute('%symdel '||trim(left(name))||';');
  	run;
%end;

%else %do;
	%*** Note that I do not call %MakeList to generate a list of the variables to be deleted
	%*** enclosed in quotation marks, because %MakeList calls %DeleteMacroVar, and doing that
	%*** would produce an endless loop;
	%*** NOTE: (26/5/03) The above about %MakeList is no longer true, but I keep not calling
	%*** %MakeList to avoid generating potential unnecessary errors;
	%let nro_vars = %GetNroElements(&vars);
	%*** This data step is necessary to avoid a violation task error when using call execute
	%*** in the next data step;
	data _DeleteMacroVar_vars_;
		set sashelp.vmacro;
		%do i = 1 %to &nro_vars;
			%let var = %scan(&vars , &i , ' ');
			if upcase(name) = upcase("&var") then output;
		%end;
	run;

	%callmacro(getnobs , _DeleteMacroVar_vars_ return=1 , nobs);
	%if &nobs = 0 %then
		%put DELETEMACROVAR: &vars do(es) not exist as global macro variables;
	%else %do; 
		data _null_;
			set _DeleteMacroVar_vars_;
	   		call execute('%symdel '||trim(left(name))||';');
		run;
	%end;
%end;

proc datasets nolist;
	delete _DeleteMacroVar_vars_;
quit;

%* Resetting SAS options;
options &notes_option _last_ = &lastds;
%MEND DeleteMacroVar;

