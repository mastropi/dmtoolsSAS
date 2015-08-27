Creado: 26/09/05
Modificado: 30/11/05


Para acceder a las macros de Score
----------------------------------
1.- Copiar todo el directorio Score al disco local.

2.- Ejecutar el codigo startup.sas como se explica en dicho archivo. Por ej, suponiendo que el directorio Score fue copiado a C:\Macros, una ejecucion posible es:
%let scoredir = C:\Macros\Score;	* Directorio con las macros para SCORE compiladas;
%let score = score;					* Libname con las macros para SCORE compiladas;
%include "&scoredir\startup.sas";

Esto mapea la libreria SCORE al directorio con las macros compiladas.


Para generar el score
---------------------
Ejecutar la macro %Score segun el siguiente modelo:

%Score(
	data=, 				/* Input dataset con las cuentas a scorear y las variables transformadas */
						/* necesarias para aplicar el modelo */
	template=, 			/* Template que define las variables del modelo y sus transformaciones */
	table=, 			/* Tabla de parametros estimados del modelo */
	calibration=, 		/* Dataset con la informacion de calibracion */
	out=_score_, 		/* Output dataset con el score */
	summary=_summary_,	/* Output dataset con las variables del modelo sumarizadas */
	id=,				/* Variables ID para conservar en el output dataset */
	pop=ALL,			/* Nombre del sub-modelo al que pertenecen las cuentas a scorear */
	edad=P_EDAD_12, 	/* Nombre de la variable con el horizonte de prediccion */
	time=12,			/* Horizonte de prediccion (en meses) */
	keepvars=1			/* Si se desea conservar (=1) o no (=0) las variables del modelo en
						   el output dataset */
);
