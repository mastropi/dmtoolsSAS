/*MACRO QUE CALCULA EL R2 Y EL R2 AJUSTADO DE UNA REGRESION LOGISTICA. ES UTIL PARA CALCULAR
EL R2 DE UN CONJUNTO DE VALIDACION PARA EL QUE SE GENERARON PROBABILIDADES PREDICHAS. */
&rsubmit;
%MACRO rsquare(data,resp=oy,pred=p,event=1)
		/ store des="Computes the R-Square and the Adjusted R-Square of a logistic regression model";
data rsquare;
	set &data end=eof;
	retain lab n1 nT;
	if _n_ = 1 then do;
	  lab=1; n1=0; nt=0;
	  end;
	if &resp=&event then n1 = n1+1;
	if &resp ~= . then do;
	   nt=nt+1;
		if &resp=&event then
	   		lab = lab * &pred;
		else
	   	    lab = lab * (1-&pred);
	end;
	if eof then do;
	  alpha = log( (n1/nt)/(1 - (n1/nt)) );
	  pa = exp(alpha) / (1 + exp(alpha));
	  la = (pa**n1) * ( ((1-pa)**(nt-n1)) );
	  nullchi = -2*log(la);
	  abchi = -2*log(lab);
	  modchi =  nullchi - abchi;
	  r2ent = modchi/nullchi;
	  r2chi = 1 - exp(-modchi/nt);
	  RSquare=1-((la/lab)**(2/nt));*agregado;
	  RSquare_max=1-((la)**(2/nt));*Rmax2 = 1 - {L(0))**(2/n);
	  Rsquare_adj=RSquare/RSquare_max;
	  output;
	end;
	keep n1 nt pa la lab nullchi abchi modchi r2ent r2chi alpha RSquare RSquare_max RSquare_adj;
run;
title3 'cross validation r-square measures';
proc print data=rsquare; var n1 nt pa la lab nullchi abchi modchi r2ent r2chi 
alpha RSquare RSquare_max RSquare_adj;
run;
%MEND;

