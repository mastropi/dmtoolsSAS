/* COM_MAC_CREATEDUMMIES.SAS
Version: 		V5
Creado: 		16/08/06
Modificado:		17/09/06
Autor: 			Daniel Mastropietro
Descripcion:	Macros para generar indicadoras de meses, dias festivos, etc.

MODIFICACIONES A LA VERSION V1
DM = Daniel Mastropietro

Version		Fecha		Autor	Descripcion
===================================================================================================
V2			20/08/06	DM		- Se agregaron las siguientes macros:
									- %CreateDummyFestivos
									- %CreateDummyAroundFestivos
									Estas macros crean las variables indicadoras de los festivos
									y de los dias pegados a los festivos (pre y post-festivos).
								- Se modifico' la macro %CreateFestivos de manera de invocar a las
								macros %CreateDummyFestivos y %CreateDummyAroundFestivos. Ademas
								esta macro ahora tambien crea la indicadora de los festivos semanales
								(es decir dias especiales por pertenecer a semanas especiales,
								como la primera quincena de enero) y la indicadora de los dias
								post-festivos.
V3			31/08/06	DM		- Se agrego' la macro %CreateInicioFinTemporadas que genera dummies
								para los inicios y fin de temporadas.
								- (12/09/06) Se corrigio' un error en la macro %CreateInicioFinTemporadas
								donde antes de hacer drop de variables temporales se hacia referencia a 
								la macro variable &TemporadaFinDesc en lugar de a &TemporadaFinGenero.
V4			12/09/06	DM		- Se corrigio' la ecuacion que decia:
									&TemporadaFinGenero = "";
								por la ecuacion correcta que es:
									&FechaFin = .;
								Esto ocurria despues del:
									if &DummyTemporadaFin = 0 then do;
								- Se agrego' la macro %CreateInicioFinTemporadasByProg
								- Se agrego' el drop de &key en %CreateDummyAroundFestivos
V5			15/09/06	DM		- Se corrigio' un error en la generacion de las dummies indicadoras
								de festivos que NO estaban marcando el ultimo dia de un periodo
								de festivos (ej. el domingo de Semana Santa) como festivo.
								- (17/09/06) Se elimino' el valor default del parametro weekformat de
								las macros.
===================================================================================================
*/

/* PENDIENTES
- (25/08/06) En %CreateDummyFestivos relajar el supuesto 3 de que las fechas del input dataset deben
ser consecutivas, usando un PROC SQL y preguntando si la fecha &date esta entre FechaIni y FechaFin.
*/

/*
===================================================================================================
INDICE
%MACRO CreateWeek
	Crea una variable caracter con el numero de la semana del anho.

%MACRO CreateWeekday
	Crea una variable numerica con el numero de dia de la semana.

%MACRO CreateDummyWeek
	Crea 52 variables dummy indicadoras de las semanas del anho, a partir de la variable creada en
	%CreateWeek.

%MACRO CreateDummyMes
	Crea 12 variables dummy indicadoras de los meses del anho.

%MACRO CreateWeekInMes
	Crea 4 variables dummy indicadoras del numero de semana dentro del mes.

%MACRO CreateDummyFestivos
	Crea una dummy indicadora de los dias festivos.

%MACRO CreateDummyAroundFestivos
	Crea una dummy indicadora de dias que estan pegados a los festivos ya sea antes (Visperas)
	o despues (Post-Festivos).

%MACRO CreateFestivos
	Crea dummies indicadoras de los dias:	
	- festivos diarios
	- festivos semanales (que pertenecen a semanas especiales)
	- visperas de festivos diarios
	- dias post-festivos diarios

%MACRO CreateInicioFinTemporadas
	Crea dummies indicadoras de las semanas que son inicio y fin de temporada de programas que
	estan en el catalogo de inicio y fin de temporadas.

%MACRO CreateInicioFinTemporadasByProg
	Crea dummies indicadoras de las fechas y transmisiones de programas que tienen inicio o fin de
	temporada segun el catalogo de inicio y fin de temporadas.
===================================================================================================
*/

/*
Macro que crea una variable caracter (especificada en WEEK=) con el numero de semana del anho
a partir de la fecha almacenada en la variable DATE=.
SUPUESTOS:
- Debe existir el formato definido en el parametro WEEKFORMAT=, que permite calcular el numero de semana del anho.
*/
%MACRO CreateWeek(date=fecha, week=semana, weekformat=);
	%* Week;
	_week_ = put(&date, &weekformat);
	%* Semana del anho;
	&week = substr(_week_, 7, 2);
	drop _week_;
%MEND CreateWeek;

/*
Macro que crea una variable numerica (especificada en WEEKDAY=) con el numero de dia de la semana
a partir de la fecha almacenada en la variable DATE=;
La variable se genera usando la funcion WEEKDAY de SAS con lo que sus valores significan:
1 = Domingo, 2 = Lunes, ..., 7 = Sabado.
*/
%MACRO CreateWeekday(date=fecha, weekday=weekday);
	%* Dia de la semana;
	length &weekday 3;
	&weekday = weekday(&date);
%MEND CreateWeekday;

/*
Macro que crea 52 variables dummy (con el prefijo indicado en PREFIX=) indicadoras de las semanas del anho
a partir de la semana del anho almacenada en la variable WEEK=.
SUPESTOS:
- La variable &week es caracter, NO numerica. Esta variable es creada por la macro %CreateWeek.
*/
%MACRO CreateDummyWeek(week=semana, prefix=I_S);
	%* Dummy variables indicadoras de las semanas del anho;
	%* Nota: La semana 53 es considerada la semana 52. Notar que la unica semana que puede compartir dias
	%* entre 2 anhos es la ultima semana del anho. La primera semana siempre tiene todos sus dias en un mismo anho;
	array dum_sem(*) &prefix.1-&prefix.52 (52*0);
	length &prefix.1-&prefix.52 3;
	_week_ = min(52, &week*1);
	_week_lag_ = max(1, lag(_week_));	%* Uso MAX(1, ...) para que _week_lag_ no valga missing para la primera observacion y pueda
										%* usar el statement dum_sem(_week_lag_) = 0 abajo;
	%* Seteo en 0 la dummy seteada en 1 en la iteracion anterior, porque si no sigue valiendo 1 indefinidamente;
	dum_sem(_week_lag_) = 0;
	%* Seteo en 1 la dummy correspondiente al mes actual;
	dum_sem(_week_) = 1;

	drop _week_ _week_lag_;
%MEND CreateDummyWeek;

/*
Macro que crea 12 variables dummy (con el prefijo indicado en PREFIX=) indicadoras de los meses del anho
a partir de la fecha almacenada en la variable DATE=.
*/
%MACRO CreateDummyMes(date=fecha, prefix=I_M);
	%* Dummy variables indicadoras de los meses;
	array dum_mes(*) &prefix.1-&prefix.12 (12*0);
	length &prefix.1-&prefix.12 3;
	_month_ = month(&date);
	_month_lag_ = max(1, lag(_month_));	%* Uso MAX(1, ...) para que _month_lag_ no valga missing para la primera observacion y pueda
										%* usar el statement dum_mes(_month_lag_) = 0 abajo;
	%* Seteo en 0 la dummy seteada en 1 en la iteracion anterior, porque si no sigue valiendo 1 indefinidamente;
	dum_mes(_month_lag_) = 0;
	%* Seteo en 1 la dummy correspondiente al mes actual;
	dum_mes(_month_) = 1;

	drop _month_ _month_lag_;
%MEND CreateDummyMes;

/* 
Macro que crea 4 variables dummy (con el prefijo indicado en PREFIX=) indicadoras del numero de semana dentro del mes
a partir de la fecha almacenada en la variable DATE=.
SUPUESTOS:
- Debe existir el formato definido en el parametro WEEKFORMAT= que permite calcular el numero de semana dentro del mes.
*/
%MACRO CreateWeekInMes(date=fecha, prefix=I_W, weekformat=);
	%* Dummies del numero de semana en el mes (considero las semanas 4 y 5 como semana 4);
	array dum_week(*) &prefix.1-&prefix.4 (4*0);
	length &prefix.1-&prefix.4 3;
	_weeknum_ = min(4, input(put(&date, &weekformat), 1.));	%* MIN(4, ...) para que la semana 5 sea considerada como semana 4;
	_weeknum_lag_ = max(1, lag(_weeknum_));
		%** Uso MAX(1, ...) para que _weeknum_lag_ no valga missing para la primera observacion y pueda
		%** usar el statement dum_week(_weeknum_lag_) = 0 abajo;
	%* Seteo en 0 la dummy seteada en 1 en la iteracion anterior, porque si no sigue valiendo 1 indefinidamente;
	dum_week(_weeknum_lag_) = 0;
	%* Seteo en 1 la dummy correspondiente al mes actual;
	dum_week(_weeknum_) = 1;

	drop _weeknum_ _weeknum_lag_;
%MEND CreateWeekInMes;

/*
Macro que crea una indicadora de los dias festivos con el nombre indicado en DUMMYFESTIVO=
y una indicadora de las visperas de festivo con el nombre indicado en DUMMYFESTIVOVISP=
a partir de la fecha almacenada en DATE=.
SUPUESTOS:
1.- Debe existir un indice por FechaIni en DataFestivos.
2.- Las variables existentes en el dataset indexado con los dias festivos son:
NombreTipo NombreFestivo FechaIni FechaFin
3.- El input dataset esta ordenado por la variable &date y NO HAY HUECOS EN LAS FECHAS, es decir
todos los dias del dataset son dias consecutivos. (Esto es necesario para evitar problemas en
la identificacion de los dias festivos en la variable indicadora DummyFestivo ya que se busca
si la fecha en &date esta en el catalogo de festivos.) (ver PENDIENTES arriba)
*/
%MACRO CreateDummyFestivos(date=fecha, 
						   DataFestivos=DataFestivos,
						   DummyFestivo=DummyFestivo,
						   FechaIni=FechaIni,
						   FechaFin=FechaFin, 
						   FestivoTipo=FestivoTipo,
						   FestivoDesc=FestivoDesc,
						   LastFestivo=LastFestivo);
%** LastFestivo: Nombre de la variable donde se almacena si ya se encontrO la fecha correspondiente a la ultima
%** 			 fecha festiva del periodo festivo;
	if &DummyFestivo = 0 then do;
		%* Busco &date en &DataFestivos entrando por la key variable FechaIni;
		FechaIni = &date;
		set &DataFestivos(keep=NombreTipo NombreFestivo FechaIni FechaFin) key=FechaIni / unique;	
			%** Notar que todas las variables que vienen de este dataset son RETENIDAS debido a la logica del SET;
		if _IORC_ then do;
			_ERROR_ = 0;
			%* Se setean en missing las variables que se crean en el dataset, en caso de que el nombre de alguna
			%* de ellas coincida con el nombre que viene del dataset indexado con la informacion de los festivos.
			%* De hecho, si este es el caso y no se setea la variable en missing cuando la key no fue encontrada
			%* en el dataset indexado, el ultimo valor leido de dicho dataset se acarrea indefinidamente porque
			%* asi funciona el SET: todas las variables que vienen en el set son RETENIDAS;
			&FechaIni = .;
			&FechaFin = .;
			&FestivoTipo = "";
			&FestivoDesc = "";
		end;
		else do;
			&DummyFestivo = 1;
			%* Guardo la fecha inicial, la fecha final, el tipo y la descripcion del festivo;
			%* Estas asignaciones se hacen en caso de que el nombre de alguna de las variables que se estan creando
			%* en el dataset con esta informacion, sea distinto al nombre que viene del dataset indexado con la
			%* informacion de los festivos;
			&FechaIni = FechaIni;
			&FechaFin = FechaFin;
			&FestivoTipo = NombreTipo;
			&FestivoDesc = NombreFestivo;
		end;
	end;
	%* Pregunto si el dia anterior fue el ultimo dia de festivo para que este dia sea seteado como no festivo;
	if &date - 1 = &FechaFin then
		&LastFestivo = 1;		%* El &FechaFin que aparece en el IF es la variable que se esta creando en el dataset
								%* a partir de la informacion que viene en la variable FechaFin;
%MEND CreateDummyFestivos;

/*
Macro que crea una indicadora de los dias que estan entorno a los dias festivos.
El nombre de la indicadora es el indicado en el parametro DUMMYAROUNDFESTIVO=
Se crea tambien una variable con la fecha correspondiente a dicha dia cercano al festivo
en la variable indicada en el parametro DUMMYFESTIVOVISP=
Estas variables son creadas a partir de la informacion almacenada en la variable indicada
en DATAE=.
SUPUESTOS:
1.- Debe existir un indice por &date en DataAroundFestivos.
*/
%MACRO CreateDummyAroundFestivos(date=fecha, 
						   		 DataAroundFestivos=DataAroundFestivos,
								 DummyAroundFestivo=DummyAroundFestivo,
						   		 FechaAroundFestivo=FechaAroundFestivo,
								 key=FechaAroundFestivo);
%** KEY: Index key con que se entra al dataset indexado DataAroundFestivos;
	&key = &date;
	set &DataAroundFestivos(keep=&key) key=&key / unique;
	if _IORC_ then do;
		_ERROR_ = 0;
		&DummyAroundFestivo = 0;
		&FechaAroundFestivo = .;
	end;
	else do;
		&DummyAroundFestivo = 1;
		%* Guardo la fecha around el festivo;
		&FechaAroundFestivo = &key;
	end;

	%if %quote(%upcase(&FechaAroundFestivo)) ~= %upcase(&key) %then %do;
	drop &key;
	%end;
%MEND CreateDummyAroundFestivos;


/*
Macro que invoca a %CreateDummyFestivos y %CreateDummyAroundFestivos para crea indicadoras
de los dias festivos y de los dias que estan entorno a los dias festivos.
SUPUESTOS:
Ver los supuestos de %CreateDummyFestivos y %CreateDummyAroundFestivos.
*/
%MACRO CreateFestivos(date=fecha,
					  formatdate=date9.,
					  DataFestivosDiarios=indata.prd_cat_FEspDiarias,
					  DataFestivosSemanales=indata.prd_cat_FEspSemanales,
					  DataFestivosVisp=indata.PRD_cat_FestivosVisp,
					  DataFestivosPost=indata.PRD_cat_FestivosPost,
					  DummyFestivoDiario=I_Festivo,
					  DummyFestivoSemanal=I_Especial,
					  DummyFestivoVisp=I_FestivoVisp,
					  DummyFestivoPost=I_FestivoPost,
					  FechaIniFestivoDiario=FechaIniFestivo,
					  FechaFinFestivoDiario=FechaFinFestivo,
					  FechaIniFestivoSemanal=FechaIniEspecial,
					  FechaFinFestivoSemanal=FechaFinEspecial,
					  FechaFestivoVisp=FechaFestivoVisp,
					  FechaFestivoPost=FechaFestivoPost,
					  FestivoDiarioTipo=FestivoTipo,
					  FestivoDiarioDesc=FestivoDesc,
					  FestivoSemanalTipo=EspecialTipo,
					  FestivoSemanalDesc=EspecialDesc);
%** date: Variable que contiene la fecha usada para crear las variables indicadoras;
%** formatdate: Format a usar para las variables de fecha que se crean;
%** DataFestivosDiarios: Dataset indexado por FechaIni con los festivos diarios;
%** DataFestivosSemanales: Dataset indexado por FechaIni con los festivos semanales;
%** DataFestivosVisp: Dataset indexado por FechaVisp con las visperas de festivos;
%** DataFestivosPost: Dataset indexado por FechaPost con los dias post-festivos;
%** DummyFestivoDiario: Variable a crear indicadora de los dias festivos;
%** DummyFestivoSemanal: Variable a crear indicadora de los dias especiales por festivos semanales;
%** DummyFestivoVisp: Variable a crear indicadora de los dias visperas de festivos;
%** DummyFestivoPost: Variable a crear indicadora de los dias post-festivos;
%** FechaIniFestivoDiario: Variable a crear con la fecha de inicio del periodo de festivos diarios;
%** FechaFinFestivoDiario: Variable a crear con la fecha de fin del periodo de festivos diarios;
%** FechaIniFestivoSemanal: Variable a crear con la fecha de inicio del periodo de festivos semanales;
%** FechaFinFestivoSemanal: Variable a crear con la fecha de fin del periodo de festivos semanales;
%** FechaFestivoVisp: Variable a crear con la fecha de visperas de festivos;
%** FechaFestivoPost: Variable a crear con la fecha de dias post-festivos;
%** FestivoDiarioTipo: Variable a crear con el tipo de festivo diario (DIA, PUENTES, VACACIONES, ESPECIALES);
%** FestivoDiarioDesc: Variable a crear con la descripcion del festivo diario (dia del ninho, dia de la madre, etc.);
%** FestivoSemanalTipo: Variable a crear con el tipo de festivo semanal (VACACIONES, ESPECIALES);
%** FestivoSemanalDesc: Variable a crear con la descripcion del festivo semanal (primera quincena de enero, vacaciones de verano, etc.);

	%* Variables nuevas que se crean en el dataset;
	length &DummyFestivoDiario &DummyFestivoSemanal &DummyFestivoVisp &DummyFestivoPost _lastFestivoDiario_ _lastFestivoSemanal_ 3;
	length &FestivoDiarioTipo &FestivoSemanalTipo $10 &FestivoDiarioDesc &FestivoSemanalDesc $80;
	length &FechaIniFestivoDiario &FechaFinFestivoDiario &FechaIniFestivoSemanal &FechaFinFestivoSemanal &FechaFestivoVisp &FechaFestivoPost 4;
	format &FechaIniFestivoDiario &FechaFinFestivoDiario &FechaIniFestivoSemanal &FechaFinFestivoSemanal &FechaFestivoVisp &FechaFestivoPost &formatdate;

	%* Variables a retener;
	retain &DummyFestivoDiario 0;
	retain &DummyFestivoSemanal 0;
	retain &DummyFestivoVisp 0;
	retain &DummyFestivoPost 0;
	retain _lastFestivoDiario_ 0;		%* Indicador del ultimo dia del ciclo de festivos diarios;
	retain _lastFestivoSemanal_ 0;		%* Indicador del ultimo dia del ciclo de festivos semanales;
	retain &FechaIniFestivoDiario .;
	retain &FechaFinFestivoDiario .;
	retain &FechaIniFestivoSemanal .;
	retain &FechaFinFestivoSemanal .;
	retain &FestivoDiarioTipo "";
	retain &FestivoDiarioDesc "";
	retain &FestivoSemanalTipo "";
	retain &FestivoSemanalDesc "";

	%* Festivos diarios;
	%CreateDummyFestivos(
		date=&date, 
		DataFestivos=&DataFestivosDiarios,
		DummyFestivo=&DummyFestivoDiario,
		FechaIni=&FechaIniFestivoDiario,
		FechaFin=&FechaFinFestivoDiario,
		FestivoTipo=&FestivoDiarioTipo,
		FestivoDesc=&FestivoDiarioDesc,
		LastFestivo=_lastFestivoDiario_
	);
	%* Dias especiales debido a semanas especiales;
	%* Notar que esto no se usa para marcar semanas especiales sino DIAS especiales. La identificacion
	%* de semanas especiales se hace aparte, ya que la logica de la generacion es distinta;
	%CreateDummyFestivos(
		date=&date, 
		DataFestivos=&DataFestivosSemanales,
		DummyFestivo=&DummyFestivoSemanal,
		FechaIni=&FechaIniFestivoSemanal,
		FechaFin=&FechaFinFestivoSemanal,
		FestivoTipo=&FestivoSemanalTipo,
		FestivoDesc=&FestivoSemanalDesc,
		LastFestivo=_lastFestivoSemanal_
	);

	%* Me fijo si el anterior fue el ultimo dia de festivo;
	if _lastFestivoDiario_ then do;
		&DummyFestivoDiario = 0;
		&DummyFestivoVisp = 0;
		&DummyFestivoPost = 0;
		_lastFestivoDiario_ = 0;
		%* Reseteo en missing las variables cuya informacion viene del dataset &DataFestivos porque ya no es festivo el dia actual
		%* (ya que _lastFestivoDiario_ = 1 o bien es el primer registro del input dataset);
		&FechaIniFestivoDiario = .;
		&FechaFinFestivoDiario = .;
		&FestivoDiarioTipo = "";
		&FestivoDiarioDesc = "";
	end;
	if _lastFestivoSemanal_ then do;
		&DummyFestivoSemanal = 0;
		_lastFestivoSemanal_ = 0;
		%* Reseteo en missing las variables cuya informacion viene del dataset &DataFestivos porque ya no es festivo el dia actual
		%* (ya que _lastFestivoSemanal_ = 1 o bien es el primer registro del input dataset);
		&FechaIniFestivoSemanal = .;
		&FechaFinFestivoSemanal = .;
		&FestivoSemanalTipo = "";
		&FestivoSemanalDesc = "";
	end;

	%* Visperas de festivos;
	%CreateDummyAroundFestivos(
		date=&date,
		DataAroundFestivos=&DataFestivosVisp,
		DummyAroundFestivo=&DummyFestivoVisp,
		FechaAroundFestivo=&FechaFestivoVisp,
		key=FechaVisp
	);
	%* Dias Post-Festivos;
	%CreateDummyAroundFestivos(
		date=&date,
		DataAroundFestivos=&DataFestivosPost,
		DummyAroundFestivo=&DummyFestivoPost,
		FechaAroundFestivo=&FechaFestivoPost,
		key=FechaPost
	);

	drop _lastFestivoDiario_ _lastFestivoSemanal_;
	%if %quote(%upcase(&FechaIniFestivoDiario)) ~= FECHAINI and %quote(%upcase(&FechaIniFestivoSemanal)) ~= FECHAINI %then %do;
	drop FechaIni;
	%end;
	%if %quote(%upcase(&FechaFinFestivoDiario)) ~= FECHAFIN and %quote(%upcase(&FechaFinFestivoSemanal)) ~= FECHAFIN %then %do;
	drop FechaFin;
	%end;
	%if %quote(%upcase(&FestivoDiarioTipo)) ~= NOMBRETIPO and %quote(%upcase(&FestivoSemanalTipo)) ~= NOMBRETIPO %then %do;
	drop NombreTipo;
	%end;
	%if %quote(%upcase(&FestivoDiarioDesc)) ~= NOMBREFESTIVO and %quote(%upcase(&FestivoSemanalDesc)) ~= NOMBREFESTIVO %then %do;
	drop NombreFestivo;
	%end;
%MEND CreateFestivos;

/*
Macro que crea dummies indicadoras de las semanas que son inicio y fin de temporada de series/novelas.
Las dummies indicadoras de las semanas valen 1 desde la fecha indicada en el catalogo de inicio y fin de temporadas
hasta el domingo de dicha semana.
SUPUESTOS:
1.- El catalogo de inicio y fin de temporadas (DATATEMPORADAS=):
	- Contiene las variables FechaIni y FechaFin, la primera correspondiente al lunes de la semana en que inicia
	la temporada, la segunda correspondiente al lunes de la semana en que termina la temporada.
	- Tiene dos indices, uno por FechaIni y otro por FechaFin.
	- Tiene las variables NombrePrograma y NombreGenero con la descripcion del programa asociada a las fechas de inicio
	y fin de temporada.
2.- El input dataset esta ordenado por la variable &date y NO HAY HUECOS EN LAS FECHAS, es decir
todos los dias del dataset son dias consecutivos. (Esto es necesario para evitar problemas en
la identificacion de los dias incluidos en las semanas de inicio y fin de temporada en las variables
indicadoras DummyTemporadaIni y DummyTemporadaFin ya que se busca si la fecha en &date esta en el catalogo
de inicio y fin de temporadas para definir en quE fecha empieza a valer 1 y en quE fecha deja de valer 1.)
(ver PENDIENTES arriba)
*/
%MACRO CreateInicioFinTemporadas(date=fecha,
								 formatdate=date9.,
								 DataTemporadas=DataTemporadas,
								 DummyTemporadaIni=I_TemporadaIni,
								 DummyTemporadaFin=I_TemporadaFin,
								 FechaIni=FechaTemporadaIni,
								 FechaFin=FechaTemporadaFin,
								 TemporadaIniDesc=TemporadaIniDesc,
								 TemporadaFinDesc=TemporadaFinDesc,
								 TemporadaIniGenero=TemporadaIniGenero,
								 TemporadaFinGenero=TemporadaFinGenero);
%** date: Variable que contiene la fecha usada para crear las variables indicadoras;
%** formatdate: Format a usar para las variables de fecha que se crean;
%** DataTemporadas: Dataset indexado por FechaIni y FechaFin con el inicio y el fin de temporadas;
%** DummyTemporadaIni: Variable a crear indicadora de las semanas correspondientes a los inicios de temporada;
%** DummyTemporadaFin: Variable a crear indicadora de las semanas correspondientes a los fines de temporada;
%** FechaIni: Variable a crear con la fecha del lunes correspondiente al inicio de temporada;
%** FechaFin: Variable a crear con la fecha del lunes correspondiente al fin de temporada;
%** TemporadaIniDesc: Variable a crear con la descripcion de la serie/novela asociada al inicio de temporada;
%** TemporadaFinDesc: Variable a crear con la descripcion de la serie/novela asociada al fin de temporada;
%** TemporadaIniGenero: Variable a crear con el genero de la serie/novela asociada al inicio de temporada;
%** TemporadaFinGenero: Variable a crear con el genero de la serie/novela asociada al fin de temporada;

	%* Variables nuevas que se crean en el dataset;
	length &DummyTemporadaIni &DummyTemporadaFin 3;
	length &FechaIni 4 &TemporadaIniDesc &TemporadaIniGenero $80;
	length &FechaFin 4 &TemporadaFinDesc &TemporadaFinGenero $80;
	length _monday_ 3;
	format &FechaIni &FechaFin &formatdate;

	%* Variables a retener;
	retain &DummyTemporadaIni;
	retain &DummyTemporadaFin;
	retain &FechaIni;
	retain &TemporadaIniDesc;
	retain &TemporadaIniGenero;
	retain &FechaFin;
	retain &TemporadaFinDesc;
	retain &TemporadaFinGenero;
	retain _monday_;

	if &date ~= lag(&date) and weekday(&date) = 2 then
		_monday_ = 1;	%* weekday = 2 es lunes y ahi quiero que termine la indicadora de inicio / fin de temporada;

	%* Reset de variables a retener;
	if _N_ = 1 or _monday_ then do;
		&DummyTemporadaIni=0;
		&DummyTemporadaFin=0;
		_monday_ = 0;
		%* Reseteo en missing las variables cuya informacion viene del dataset &DataTemporadas porque la fecha actual ya no 
		%* es parte del inicio o fin de temporada;
		&FechaIni = .;
		&TemporadaIniDesc = "";
		&TemporadaIniGenero = "";
		&FechaFin = .;
		&TemporadaFinDesc = "";
		&TemporadaFinGenero = "";
	end;

	%* Inicio de temporada;
	if &DummyTemporadaIni = 0 then do;
		%* Busco &date en &DataTemporadas entrando por la key variable FechaIni;
		FechaIni = &date;
		set &DataTemporadas(keep=FechaIni NombrePrograma NombreGenero) key=FechaIni;	
			%** Notar que NO USO LA OPCION / UNIQUE. Esto es porque hay repetidos en el catalogo de inicio y fin de
			%** temporadas y me quiero librar de los repetidos. Lo que se logra con no usar el UNIQUE es quedarse
			%** con la primera ocurrencia de FechaIni que hace match con &date;
		if _IORC_ then do;
			_ERROR_ = 0;
			%* Se setean en missing las variables que se crean en el dataset, en caso de que el nombre de alguna
			%* de ellas coincida con el nombre que viene del dataset indexado con la informacion de los festivos.
			%* De hecho, si este es el caso y no se setea la variable en missing cuando la key no fue encontrada
			%* en el dataset indexado, el ultimo valor leido de dicho dataset se acarrea indefinidamente porque
			%* asi funciona el SET: todas las variables que vienen en el set son RETENIDAS;
			&FechaIni = .;
			&TemporadaIniDesc = "";
			&TemporadaIniGenero = "";
			if &DummyTemporadaFin = 0 then do;
				%* Pongo en missing las variables de fin de temporada porque estamos creando la dummy de Ini;
				%* Uso el IF para setear en missing estas variables Fin SOLO cuando NO habian sido seteadas a un valor
				%* en la iteracion anterior;
				&FechaFin = .;
				&TemporadaFinDesc = "";
				&TemporadaFinGenero = "";
			end;
		end;
		else do;
			&DummyTemporadaIni = 1;
			%* Guardo la fecha de inicio de temporada y la descripcion del PRIMER programa asociado a dicha temporada.
			%* Digo PRIMER programa porque solamente entra del catalogo de temporadas la primera ocurrencia de &date;
			%* Estas asignaciones se hacen en caso de que el nombre de alguna de las variables que se estan creando
			%* en el dataset con esta informacion, sea distinto al nombre que viene del dataset indexado con la
			%* informacion de los festivos;
			&FechaIni = FechaIni;
			&TemporadaIniDesc = NombrePrograma;
			&TemporadaIniGenero = NombreGenero;
			if &DummyTemporadaFin = 0 then do;
				%* Pongo en missing las variables de fin de temporada porque estamos creando la dummy de Ini;
				%* Uso el IF para setear en missing estas variables Fin SOLO cuando NO habian sido seteadas a un valor
				%* en la iteracion anterior;
				&FechaFin = .;
				&TemporadaFinDesc = "";
				&TemporadaFinGenero = "";
			end;
		end;
	end;

	%* Fin de temporada;
	if &DummyTemporadaFin = 0 then do;
		%* Busco &date en &DataTemporadas entrando por la key variable FechaFin;
		FechaFin = &date;
		set &DataTemporadas(keep=FechaFin NombrePrograma NombreGenero) key=FechaFin;	
			%** Notar que NO USO LA OPCION / UNIQUE. Esto es porque hay repetidos en el catalogo de inicio y fin de
			%** temporadas y me quiero librar de los repetidos. Lo que se logra con no usar el UNIQUE es quedarse
			%** con la primera ocurrencia de FechaFin que hace match con &date;
		if _IORC_ then do;
			_ERROR_ = 0;
			%* Se setean en missing las variables que se crean en el dataset, en caso de que el nombre de alguna
			%* de ellas coincida con el nombre que viene del dataset indexado con la informacion de los festivos.
			%* De hecho, si este es el caso y no se setea la variable en missing cuando la key no fue encontrada
			%* en el dataset indexado, el ultimo valor leido de dicho dataset se acarrea indefinidamente porque
			%* asi funciona el SET: todas las variables que vienen en el set son RETENIDAS;
			if &DummyTemporadaIni = 0 then do;
				%* Pongo en missing las variables de inicio de temporada porque estamos creando la dummy de Fin;
				%* Uso el IF para setear en missing estas variables Ini SOLO cuando NO habian sido seteadas a un valor
				%* arriba;
				&FechaIni = .;
				&TemporadaIniDesc = "";
				&TemporadaIniGenero = "";
			end;
			&FechaFin = .;
			&TemporadaFinDesc = "";
			&TemporadaFinGenero = "";
		end;
		else do;
			&DummyTemporadaFin = 1;
			%* Guardo la fecha de inicio de temporada y la descripcion del PRIMER programa asociado a dicha temporada.
			%* Digo PRIMER programa porque solamente entra del catalogo de temporadas la primera ocurrencia de &date;
			%* Estas asignaciones se hacen en caso de que el nombre de alguna de las variables que se estan creando
			%* en el dataset con esta informacion, sea distinto al nombre que viene del dataset indexado con la
			%* informacion de los festivos;
			if &DummyTemporadaIni = 0 then do;
				%* Pongo en missing las variables de inicio de temporada porque estamos creando la dummy de Fin;
				%* Uso el IF para setear en missing estas variables Ini SOLO cuando NO habian sido seteadas a un valor
				%* arriba;
				&FechaIni = .;
				&TemporadaIniDesc = "";
				&TemporadaIniGenero = "";
			end;
			&FechaFin = FechaFin;
			&TemporadaFinDesc = NombrePrograma;
			&TemporadaFinGenero = NombreGenero;
		end;
	end;

	drop _monday_;
	%if %quote(%upcase(&FechaIni)) ~= FECHAINI %then %do;
	drop FechaIni;
	%end;
	%if %quote(%upcase(&FechaFin)) ~= FECHAFIN %then %do;
	drop FechaFin;
	%end;
	%if %quote(%upcase(&TemporadaIniDesc)) ~= NOMBREPROGRAMA and %quote(%upcase(&TemporadaFinDesc)) ~= NOMBREPROGRAMA %then %do;
	drop NombrePrograma;
	%end;
	%if %quote(%upcase(&TemporadaIniGenero)) ~= NOMBREGENERO and %quote(%upcase(&TemporadaFinGenero)) ~= NOMBREGENERO %then %do;
	drop NombreGenero;
	%end;
%MEND CreateInicioFinTemporadas;


/*
Macro que crea dummies indicadoras de las fechas y programas que se encuentran en el catalogo de inicio y fin
de temporadas.
Las dummies indicadoras de valen 1 al encontrarse en el dataset que se esta procesando un registro con el
ID programa y con la fecha igual a la fecha de inicio o de fin de la temporada, segun corresponda.
SUPUESTOS:
1.- El catalogo de inicio y fin de temporadas (DATATEMPORADAS=):
	- Contiene las variables FechaIni y FechaFin, la primera correspondiente al lunes de la semana en que inicia
	la temporada, la segunda correspondiente al lunes de la semana en que termina la temporada.
	- Contiene la variable IdPrograma con el ID del programa asociado a la fecha de inicio o de fin de temporada.
	- Tiene la variable NombreGenero con la descripcion del genero del programa IdPrograma.
*/
%MACRO CreateInicioFinTemporadasByProg(	date=fecha,
										formatdate=date9.,
										Programas=IdPrograma,
										DataTemporadas=DataTemporadas,
										DummyTemporadaIni=I_TemporadaIni,
										DummyTemporadaFin=I_TemporadaFin,
										FechaIni=FechaTemporadaIni,
										FechaFin=FechaTemporadaFin,
										TemporadaIniPrograma=TemporadaIniPrograma,
										TemporadaFinPrograma=TemporadaFinPrograma,
										TemporadaIniGenero=TemporadaIniGenero,
										TemporadaFinGenero=TemporadaFinGenero);
%** date: Variable que contiene la fecha usada para crear las variables indicadoras;
%** formatdate: Format a usar para las variables de fecha que se crean;
%** DataTemporadas: Dataset con las fechas de inicio y fin de temporadas;
%** DummyTemporadaIni: Variable a crear indicadora de las semanas correspondientes a los inicios de temporada;
%** DummyTemporadaFin: Variable a crear indicadora de las semanas correspondientes a los fines de temporada;
%** FechaIni: Variable a crear con la fecha del lunes correspondiente al inicio de temporada;
%** FechaFin: Variable a crear con la fecha del lunes correspondiente al fin de temporada;
%** TemporadaIniPrograma: Variable a crear con el ID del Programa asociado al inicio de temporada;
%** TemporadaFinPrograma: Variable a crear con el ID del Programa asociado al fin de temporada;
%** TemporadaIniGenero: Variable a crear con el genero de la serie/novela asociada al inicio de temporada;
%** TemporadaFinGenero: Variable a crear con el genero de la serie/novela asociada al fin de temporada;
	%local nobs;
	%callmacro(getnobs, &DataTemporadas return=1, nobs);

	%* Variables nuevas que se crean en el dataset;
	length &DummyTemporadaIni &DummyTemporadaFin 3;
	length &FechaIni 4 &TemporadaIniGenero $80;
	length &FechaFin 4 &TemporadaFinGenero $80;
	length _i_ 3;
	length _j_ 3;
	length _ProgFound_ 3;
	format &FechaIni &FechaFin &formatdate;

	array Programas(*) &Programas;

	%*** Initial settings;
	%* Inicio de temporada;
	&DummyTemporadaIni = 0;
	&FechaIni = .;
	&TemporadaIniPrograma = .;
	&TemporadaIniGenero = "";

	%* Fin de temporada;
	&DummyTemporadaFin = 0;
	&FechaFin = .;
	&TemporadaFinPrograma = .;
	&TemporadaFinGenero = "";

	%* Inicio de temporada;
	_i_ = 0;
	do while (_i_ < &nobs);
		_i_ = _i_ + 1;
		set &DataTemporadas(keep=FechaIni IdPrograma NombreGenero 
							rename=(FechaIni=_FechaIni_
									IdPrograma=_IdPrograma_
								    NombreGenero=_NombreGenero_)) point=_i_;
		if _FechaIni_ <= &date <= _FechaIni_ + 6 then do;
			_j_ = 0;
			_ProgFound_ = 0;
			do while (_j_ < dim(Programas) and not _ProgFound_ );
				_j_ + 1;
				if Programas(_j_) = _IdPrograma_ then do;
					_ProgFound_ = 1;
					&DummyTemporadaIni = 1;
					&FechaIni = _FechaIni_;
					&TemporadaIniPrograma = _IdPrograma_;
					&TemporadaIniGenero = _NombreGenero_;
				end;
			end;
		end;
	end;

	%* Fin de temporada;
	_i_ = 0;
	do while (_i_ < &nobs);
		_i_ = _i_ + 1;
		set &DataTemporadas(keep=FechaFin IdPrograma NombreGenero
							rename=(FechaFin=_FechaFin_
									IdPrograma=_IdPrograma_
								    NombreGenero=_NombreGenero_)) point=_i_;
		if _FechaFin_ <= &date <= _FechaFin_ + 6 then do;
			_j_ = 0;
			_ProgFound_ = 0;
			do while (_j_ < dim(Programas) and not _ProgFound_ );
				_j_ + 1;
				if Programas(_j_) = _IdPrograma_ then do;
					_ProgFound_ = 1;
					&DummyTemporadaFin = 1;
					&FechaFin = _FechaFin_;
					&TemporadaFinPrograma = _IdPrograma_;
					&TemporadaFinGenero = _NombreGenero_;
				end;
			end;
		end;
	end;

	drop _j_ _ProgFound_;
	drop _FechaIni_;
	drop _FechaFin_;
	drop _IdPrograma_;
	drop _NombreGenero_;
%MEND CreateInicioFinTemporadasByProg;
