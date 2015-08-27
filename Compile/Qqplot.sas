/* MACRO %qqplot
Version: 1.01
Author: Daniel Mastropietro
Created: 25-Feb-03
Modified: 12-Jan-05

DESCRIPTION:
Efectua un Q-Q plot de una variable para una distribucion especificada.

USAGE:
%qqplot(
	data ,			*** Input dataset
	var=_NUMERIC_ ,	*** Variables a analizar
	dist=normal , 	*** Distribucion de referencia para el Q-Q plot
	mu=mean , 		*** Establece como se calcula la media
	sigma=std ,		*** Establece como se calcula el desvio estandar
	probplot=0 , 	*** (No usado aun)
	pointlabel= , 	*** Variable para los point labels del gráfico
	sizelabel=10 ,	*** Tamaño de los point labels en puntos (PT)
	gout= ,			*** Nombre del graph catalog donde guardar el Q-Q plot
	name="qqplot" ,	*** Nombre del grafico con el Q-Q plot generado
	description="Normal Quantile plot");	*** Descripcion del grafico generado

REQUESTED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir cualquier 
				opción adicional como en cualquier opción data= de SAS.

OPTIONAL PARAMETERS:
Valores posibles para mu son median, mean.
Valores posibles para sigma son hspr (= qrange/1.349), std.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Exist
- %GetNroElements
- %GetVarList
- %ResetSASOptions
- %SetSASOptions
*/
&rsubmit;
%MACRO qqplot(	data , var=_NUMERIC_ , dist=normal , mu=mean , sigma=std , probplot=0 /*Not used yet*/,
				pointlabel= , sizelabel=10 , gout= , name="qqplot" , description=)
		/ store des="Q-Q plots of variables";
%local i _var_;

%SetSASOptions;

/*----------------------------------- Parse input parameters --------------------------------*/
%* Read input dataset into a local dataset so that any options coming with &data are parsed
%* BEFORE calling %GetVarList (to avoid problems such as keeping variables in &data but
%* not including the variables to be analyzed).
%* Note the use of KEEP=&VAR, which is to keep only the variables that are used in the analysis
%* and thus reduce the execution time as much as possible;
data _QQPLOT_data_(keep=&var);
	set &data;
run;
%let var = %GetVarList(_QQPLOT_data_, var=&var, log=0);
/*-------------------------------------------------------------------------------------------*/

/* Macro escrita por Michael Friendly de York University */
%MACRO nqplot_york (
        data=_LAST_,    /* input data set                      		*/
        var=x,          /* variable to be plotted              		*/
        out=nqplot,     /* output data set                     		*/
        mu=MEDIAN,      /* est of mean of normal distribution: 		*/
                        /* MEAN, MEDIAN or literal value      		*/
        sigma=HSPR,     /* est of std deviation of normal:     		*/
                        /* STD, HSPR, or literal value        		*/
        stderr=YES,     /* plot std errors around curves?      		*/
        detrend=YES,    /* plot detrended version?             		*/
        lh=1.5,         /* height for axis labels              		*/
        anno=,          /* name(s) of input annotate data set  		*/
	    colors=black blue red, /* colors for pts, ref line, CI 		*/
		symbol=dot,
        name="qqplot",  /* name of graphic catalog entries     		*/
		description=,	/* description of graphic catalog entries   */
        gout=);         /* name of graphic catalog             		*/
 
%if %quote(%upcase(&sigma)) = HSPR %then
	%let sigma = hspr/1.349;	%* El coeficiente 1.349 sale de que qrange = 1.349*sigma (ver libro sobre EDA);
%if %length(&anno)>0 %then %do;
	%local a1 a2 anno1 anno2;
	%let anno1= %scan(&anno,1);                                                      
	%let anno2= %scan(&anno,2);
	%if %length(&anno2)=0 %then %let anno2=&anno1;
	%let anno1=annotate=&anno1;
	%let anno2=annotate=&anno2;
%end;
%else %do;
	%let anno1=;
	%let anno2=;
%end;

%* Creating the character variable to put labels in the points;
%if %quote(&pointlabel) ~= %then %do;
/*	* ESTO ERA POR SI NO ANDABA BIEN CUANDO LA VARIABLE ESPECIFICADA EN &pointlabel ES NUMERICA Y NO CARACTER;
	* Pero resulta que si la paso a caracter, los labels no siempre aparecen!!!;
	data &data;
		set &data;
		retain _typenum_ 0;
		if _N_ = 1 then
			if (vtype(&pointlabel) = "N") then
				_typenum_ = 1;
			else
				_typenum_ = 0;
		put _typenum_=;
		if _typenum_ then
			_pointlabel_ = put(&pointlabel , 8.);
		else
			_pointlabel_ = &pointlabel;
		drop _typenum_;
	run;
*/
%end;
%if %length(&gout)>0  %then %let gout = gout=&gout;

%* Description of plot;
%if %quote(&description) = %then
	%let description = "Normal Quantile plot of %upcase(&var)";

data _Nqplot_Pass_;
  set &data;
  _match_=1;
  if &var ne . ;                %* get rid of missing data;
 
proc univariate noprint;        %* find n, median and hinge-spread;
   var &var;
   output out=_Nqplot_n1_ n=nobs median=median qrange=hspr mean=mean std=std;
data _Nqplot_n2_; set _Nqplot_n1_;
   _match_=1;
 
data _Nqplot_;
   merge _Nqplot_Pass_ _Nqplot_n2_;
   drop _match_;
   by _match_;
 
proc sort data=_Nqplot_;
   by &var;
run;
 
data &out;
   set _Nqplot_;
   drop sigma hspr nobs median std mean ;
   sigma = &sigma;
   _p_=(_n_ - .5)/nobs;                 %* cumulative prob.;
   _z_=probit(_p_);                     %* unit-normal Quantile;
   _se_=(sigma/((1/sqrt(2*3.1415926))*exp(-(_z_**2)/2)))
      *sqrt(_p_*(1-_p_)/nobs);          %* std. error for normal quantile;
   _normal_= sigma * _z_ + &mu ;        %* corresponding normal quantile;
   _res_ = &var - _normal_;           	%* deviation from normal;
   _lower_ = _normal_ - 2*_se_;         %* +/- 2 SEs around fitted line;
   _upper_ = _normal_ + 2*_se_;
   _reslo_  = -2*_se_;                  %* +/- 2 SEs ;
   _reshi_   = 2*_se_;
  label _z_='Normal Quantile'
        _res_='Deviation From Normal';
  run;
 /*-
 proc plot;
   plot &var * _z_='*'
        _normal_ * _z_='-'
        _lower_ * _z_='+'
        _upper_ * _z_='+' / overlay;       %* observed and fitted values;
   plot _res_ * _z_='*'
        _reslo_ * _z_='+'
        _reshi_ * _z_='+' / overlay vref=0; %* deviation from fitted line;
   run;
 -*/
%let vh=1;           %*-- value height;
%if &lh >= 1.5 %then %let vh=1.5;
%if &lh >= 2.0 %then %let vh=1.8;
	%let c1= %scan(&colors &colors,1);                                                      
	%let c2= %scan(&colors &colors,2);
	%let c3= %scan(&colors &colors &c2,3);
  symbol1 v=&symbol height=0.7 i=none c=&c1 l=1 %if %quote(&pointlabel) ~= %then pointlabel=("#&pointlabel" height=&sizelabel pt);;
  symbol2 v=none   i=join  c=&c2  l=3 w=3 pointlabel=none;
  symbol3 v=none   i=join  c=&c3 l=20 pointlabel=none;
  axis1  label=(a=90 r=0 h=&lh) value=(h=&vh);
  axis2  label=("Normal quantiles" h=&lh) value=(h=&vh);
%if %quote(&pointlabel) ~= and ~%Exist(sashelp.Vtitle , type , F) %then %do;
	footnote "Point label is variable %upcase(&pointlabel)";
%end;
proc gplot data=&out &anno1 &gout ;
  plot &var     * _z_= 1
       _normal_ * _z_= 2
  %if %quote(%upcase(&stderr)) = YES %then %do;
       _lower_ * _z_= 3
       _upper_ * _z_= 3 %end;
       / overlay frame
         vaxis=axis1 haxis=axis2
         hminor=1 vminor=1
         name=&name 
		 des=&description;
	run; quit;

%if %quote(%upcase(&detrend)) = YES %then %do;
  %gskip_york;	%*** Si esto se usa, hay que definir esta macro!!!;
proc gplot data=&out &anno2 &gout ;
  plot _res_ * _z_= 1
  %if %quote(%upcase(&stderr)) = YES %then %do;
       _reslo_ * _z_= 3
       _reshi_ * _z_= 3 %end;
       / overlay
         vaxis=axis1 haxis=axis2
         vref=0 cvref=&c2 lvref=3 frame
         hminor=1 vminor=1
         name=&name
 		 des="Detrended Normal Quantile plot of %upcase(&var)";
run; quit;
%end;

%* Resetting symbol formats and footnote;
symbol1 pointlabel=none;
symbol2 pointlabel=none;
symbol3 pointlabel=none;
%if %quote(&pointlabel) ~= %then footnote;;

%* Deleting temporary datasets;
proc datasets nolist;
	delete 	_Nqplot_n1_
			_Nqplot_n2_
			_Nqplot_
			_Nqplot_Pass_;
quit;
%MEND nqplot_york;

%if %quote(%upcase(&dist)) = NORMAL	%then %do;
	%do i = 1 %to %GetNroElements(&var);
		%let _var_ = %scan(&var , &i , ' ');
%*		title2 "Variable: &_var_";
/*		
		%if %quote(%upcase(&mu)) = EST %then
			%let mu = MEDIAN;
		%if %quote(%upcase(&sigma)) = EST %then
			%let sigma = HSPR;	* Creo que HSPR stands for Half SPRead;
*/
		%nqplot_york(data=_QQPLOT_data_ , var=&_var_ , out=_qqplot_out_ , mu=&mu , sigma=&sigma , detrend=NO , gout=&gout , name=&name , description=&description);
%*		title2;
	%end;
%end;
%else %do;
	%put QQPLOT: ERROR - The specified distribution (%sysfunc(trim(%sysfunc(left(&dist))))) is not supported.;
	%put QQPLOT: Currently supported distributions are: normal.;
%end;

proc datasets nolist;
	delete 	_qqplot_data_
			_qqplot_out_;
quit;

%ResetSASOptions;
%MEND qqplot;
