* Created: 02-Mar-2016;
* Test the %PiecewiseTransf macro that generates piecewise linear variables on simulated data;

%let sigma = 0.05;
%let beta0 = 10;
%let betax1_1 = 2;
%let betax1_2 = 3.5;
data test;
	do i = 1 to 100;
		x1 = ranuni(1313);
		x2 = 5 + 7*rannor(1717);
		z = ranuni(13);
		* Modeling a piecewise linear response;
		ymodel =  &beta0 + &betax1_1 * 1 * ( (x1 - 0)*(x1 <= 0.3) + (0.3 - 0)*(x1>0.3) )
			+ &betax1_2 * (x1 > 0.3) * ( (x1 - 0.3)*(x1 <= 0.7)+ (0.7 - 0.3)*(x1 > 0.7) );
		y = ymodel + rannor(1917)*&sigma;
		output;
	end;
	* Add a couple of missing values;
	x1 = .; x2 = 3; z = .; output;
	drop i;
run;

proc sort data=test;
	by x1;
run;

proc sgplot data=test;
	scatter x=x1 y=y;
	series x=x1 y=ymodel;
run;
** OK!;

* Piecewise variables;
data test;
	set test;
	I1_x1 = 1;
	I2_x1 = (x1 > 0.3);
	I3_x1 = (x1 > 0.7);
	pw1_x1 = I1_x1 * ( (x1 - 0)   * (x1 <= 0.3) + (0.3 - 0)   * (not(x1 <= 0.3)) );
	pw2_x1 = I2_x1 * ( (x1 - 0.3) * (x1 <= 0.7) + (0.7 - 0.3) * (not(x1 <= 0.7)) );
	pw3_x1 = I3_x1 * ( (x1 - 0.7) * 1 );
run;
/*
proc print data= test;
	var x1 I1_x1 I2_x1 I3_x1 pw1_x1 pw2_x1 pw3_x1;
run;
*/
* Regression;
proc reg data=test;
	model y = I: pw:;
run;
quit;

%import(pwcuts, "O:\B-Datos\B1-DM\testpw.csv");

proc print data=pwcuts;
run;

options mprint;
%PiecewiseTransf(
	data=test,
	cuts=pwcuts,
	includeright=1,
	fill=mean,
	out=test_pw5
);
options nomprint;
%puts(&_dummylist_);
%puts(&_pwlist_);
%puts(&pw_x2);

proc compare base=test_pw4 compare=test_pw5;
run;

* Check;
%let var = x1;
%let nro_cuts = 3;
proc sql;
	select
		&var,
		I_x1,
		%MakeListFromName(I_&var._, start=1, step=1, stop=&nro_cuts, sep=%quote(, )),
		%MakeListFromName(pw_&var._, start=1, step=1, stop=&nro_cuts+1, sep=%quote(, ))
	from test_pw5
	order by &var;
quit;
** OK: the missing value has been replaced with the mean (0.4597...) and the indicator for missing I_x1 is 1 there;


* Regression;
proc reg data=test_pw2;
	model y = &I_x1 &I_X_x1;
	output out=test_pw2_pred pred=yhat student=res;
run;
quit;
** OK! The indicator variables have all estimated parameters equal to 0 as expected!;

proc sgplot data=test_pw2_pred;
	scatter x=x1 y=y;
	series x=x1 y=yhat;
run;



%*** TEST WITH REAL DATA;
%let data = scomast.master_pvp31_s1_110(obs=1000);
%let var =  N_CR_PLAZO
N_CR_PER_CUOPAGATR_PerALDIA_EVER
N_CR_PER_CUOPAGATR_PerATR_ULT03M
N_CR_PER_CUOPAGATR_PerATR_ULT04a;
%PiecewiseTransf(
	data=&data,
	var =&var,
	cuts=0.5 0.9 2 8,
	includeright=1,
	varfix=1,
	varfixremove=_,
	fill=mean,
	out=master_pvp31_pw
);


%let var = N_CR_PER_CUOPAGATR_PerATR_ULT04a;
%let varfix = %fixVarNames(&var, space=5, replace=_);
%let nro_cuts = 4;
proc sql outobs=100;
	select
		&var,
		%MakeListFromName(I_&varfix._, start=1, step=1, stop=&nro_cuts, sep=%quote(, )),
		%MakeListFromName(pw_&varfix._, start=1, step=1, stop=&nro_cuts+1, sep=%quote(, ))
	from master_pvp31_pw
	order by &var desc;
quit;
