data table;
	input var :$32. var_transf :$32. values :$100. transf :$2.;
	datalines;
x I1_x =2,=3,=5.5 CP
x I2_x <2,>=6-<8,>10 CP
x I3_x >=9 CP
w w_L . LG
t I0_t . I0
zz I1_zz =1 CP
zz I2_zz >1 CP
cc I1_cc ="pp",="qq" CP
cc I2_cc ="tt" CP
;
%pp(table);

data test;
	input x zz cc $ w t;
	datalines;
2 0 pp 3 0
2 1 pp 0 0
3 0 pp -2 0
1 1 qq 0.2 0
6 4 qq 10 1
7.5 0 qq 100 1
8.5 2 tt 1000 2
10 0 tt 24 3.5
11 2 aaa 30 1
;
%pp(test);

%MACRO test;
%local i;
%local valuesi vari var_transfi;
%local pos_var pos_var_transf pos_transf;
%local nro_vars;

data table;
	set table;
	if values = "" then values = "-";
run;

%MACRO TCP(var, var_transf, values);
%local condition;

%let condition = %sysfunc(tranwrd(%quote(&values), %quote(,), %quote( OR &var)));
%let condition = &var%sysfunc(tranwrd(%quote(&condition), %quote(-), %quote( AND &var)));
if &condition then
	&var_transf = 1;
else
	&var_transf = 0;
%MEND TCP;

%* Indicadora de ceros;
%* TI0 = Transformacion Indicadora de Ceros;
%MACRO TI0(var, var_transf);
if &var = 0 then
	&var_transf = 1;
else
	&var_transf = 0;
%MEND TI0;

%* Transformacion logaritmica;
%* TLG = Transformacion LoGaritmica;
%MACRO TLG(var, var_transf);
if &var >= 0 then
	&var_transf = log10(1 + &var);
else
	&var_transf = -log10(1 - &var);
%MEND TLG;

%let nro_vars = %GetNroElements(&var);

%let var = %MakeListFromVar(table, var=var); %puts(&var);
%let var_transf = %MakeListFromVar(table, var=var_transf); %puts(&var_transf);
%let values = %MakeListFromVar(table, var=values); %puts(%quote(&values));

%let pos_var = %eval(1+3+1);
%let pos_var_transf = %eval(&pos_var + (32+1));
%let pos_transf = %eval(&pos_var_transf + (32+1));
data out;
	set test;
	if _N_ = 1 then
		put "#" @&pos_var "Variable" @&pos_var_transf "Variable Transformada" @&pos_transf "Transformacion";
	%do i = 1 %to &nro_vars;
		i = &i;
		%let vari = %scan(&var, &i, ' ');
		%let var_transfi = %scan(&var_transf, &i, ' ');
		%let valuesi = %scan(%quote(&values), &i, ' ');
		set table(keep=transf) point=i;
		if _N_ = 1 then
			put "&i" @&pos_var "&vari" @&pos_var_transf "&var_transfi" @&pos_transf transf;
		select (upcase(transf));
			when("CP") do; %TCP(&vari, &var_transfi, %quote(&valuesi)); end;
			when("I0") do; %TI0(&vari, &var_transfi); end;
			when("LG") do; %TLG(&vari, &var_transfi); end;
			otherwise;
		end;
	%end;
	drop transf;
run;
%MEND test;
%test;
%pp(out);

