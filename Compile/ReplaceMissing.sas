/* MACRO %ReplaceMissing
(Tomado de model-conburo2.sas, hacia el principio del codigo.)
19/8/05: La idea es que esta macro reemplace los missing por 0 (o por otro valor).
Ahora esta' la macro %Set2Zero definida en el codigo macros.sas del modelo UW2.0.
*/
&rsubmit;
%MACRO dummy;
%let var_set2zero = %SelectVar(dat, key=KNT, log=0);
%let nro_set2zero = %GetNroElements(&var_set2zero);
%PrintNameList(&var_set2zero, title=var_set2zero);
data dat(keep=&datvar) set2zero(keep=i var set2zero);
	set dat end=lastobs;
	array var_set2zero{*} &var_set2zero;
	array count{*} _count1-_count&nro_set2zero;
	retain _count1-_count&nro_set2zero 0;
	do i = 1 to dim(var_set2zero);
		if var_set2zero(i) = . then do;
			var_set2zero(i) = 0;
			count(i) = count(i) + 1;
		end;
	end;
	output dat;
	if lastobs then
		do i = 1 to &nro_set2zero;
			var = vname(var_set2zero(i));
			set2zero = count(i);
			output set2zero;
			put i= var= set2zero=;
		end;
	drop i;
run;
%MEND dummy;