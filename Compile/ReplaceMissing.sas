/* MACRO %ReplaceMissing
(Tomado de model-conburo2.sas, hacia el principio del codigo.)
19/8/05: La idea es que esta macro reemplace los missing por 0 (o por otro valor).
Ahora esta' la macro %Set2Zero definida en el codigo macros.sas del modelo UW2.0.

(2016/04/21) Revisiting this macro and completing it.

*/
&rsubmit;
%MACRO ReplaceMissing(data, var=, value=mean, out=);
%local nro_vars;

%let var = %GetvarList(&data, var=&var, log=0);
%let nro_vars = %GetNroElements(&var);

%if ~%isNumber(&value) %then %do;
	%* Compute the statistic specified in VALUE= for each analyzed variable;
	%Means(&data, var=&var, stat=&value, name=&var, transpose=1, namevar=var, out=_rm_means_, log=0);
	%let values = %MakeListFromVar(&data, var=&value);
%end;
%else
	%let values = %Rep(0, &nro_vars);

%* Show the list of variables in the output window;
%*%PrintNameList(&var, title=var);
data 	&data
		_rm_counts_(keep=i var nreplaced);
	set &data end=lastobs;
	array avar{*} &var;
	array acount(&nro_vars) _TEMPORARY_;
	array avalues{*} &values;
	retain _count1-_count&nro_vars 0;
	do i = 1 to dim(avar);
		if avar(i) = . then do;
			avar(i) = avalue(i);
			acount(i) = acount(i) + 1;
		end;
	end;
	output &data;
	if lastobs then
		do i = 1 to &nro_vars;
			var = vname(avar(i));
			nreplaced = acount(i);
			output _rm_counts_;
			put i= var= nreplaced=;
		end;
	drop i;
run;
%MEND ReplaceMissing;
