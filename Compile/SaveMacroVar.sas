&rsubmit;
%MACRO SaveMacroVar(data=_vmacro_, var=, type=GLOBAL)
	/ store des="Creates a dataset containing the values of macro variables";

data &data;
	set sashelp.vmacro;
	%if %quote(&var) ~= %then %do;
	where 	upcase(scope) = upcase("&type") and
			upcase(name) in (%EvalExp(%MakeList(%upcase(&var), prefix=%quote(%"), suffix=%quote(%"))));
	%end;
	%else %do;
	where 	upcase(scope) = upcase("&type");
	%end;
run;

%MEND SaveMacroVar;
