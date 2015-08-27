Creado: 20/10/05
Modificado: 30/11/05

Para generar el score
---------------------
Ejecutar los comandos de startup.sas, que mapean el directorio que contiene las macros compiladas necesarias para generar el score.
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
