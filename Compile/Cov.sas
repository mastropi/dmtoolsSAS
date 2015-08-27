/* MACRO %Cov
Version: 1.01
Author: Santiago Laplagne - Daniel Mastropietro
Created: 17-Dec-02
Modified: 28-Jul-04

DESCRIPTION:
Calcula la matriz de covarianza de los datos, usando proc corr.

USAGE:
%Cov (data, out=, var=_numeric_);

REQUESTED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir
				cualquier opción adicional como en cualquier opción data=
				de SAS.

OPTIONAL PARAMETERS:
- out:			Output dataset donde se guarda la matriz de covarianza de
				los datos. La matriz es de tamaño p x p, donde p es el
				el número de variables listadas en 'var'.

- var:			Lista de las variables a utilizar para calcular la matriz 
				de covarianza.
				default: _numeric_, es decir, todas las variables numéricas

NOTES:
- La matriz de covarianza se usa en el cálculo de la distancia Mahalanobis. 
Esta macro se usa en la macro %CutMahalanobisChi. La macro %Hadi tambien
calcula la matriz de covarianza pero por cuestiones de eficiencia usa su
propia rutina dentro de IML.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
*/
&rsubmit;
%MACRO Cov(data, out=, var=_numeric_) / store des="Computes a covariance matrix";
%local temp nvar;

proc corr data=&data nomiss
		cov 
		outp=&out(keep=&var)
		noprint;
		var &var;
run;

%* Remove additional computations (such as number of obs., etc.);
%callmacro(getnobs , &out return=1 , temp nvar);
data &out;
	set &out(obs=&nvar);
run;
%MEND Cov;
