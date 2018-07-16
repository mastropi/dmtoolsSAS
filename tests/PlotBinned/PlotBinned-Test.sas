/* Test of %PlotBinned with BY variables.
Created: 12-Nov-2015
Dataset: ScoGMas-2015 at Pronto
		data toplot;
			set scomast.master_pvp01_s2;
			where A_MES in (1, 2, 3);
			if _N_ <= 1000;
		run;
*/

libname test "E:\Daniel\SAS\Macros\tests\PlotBinned";

data toplot;
	set test.toplot;
	keep
	A_ID
	A_MES
	B_TARGET_DQ90_12M
	B_FUT_MESES_HASTA_CANCELADO
	C_CR_CRITERIO_INCL_GENERAL
	C_CR_CRITERIO_INCL_GENERAL
	E_CR_NR_OTORG
	V_CR_PROB_MORA_REF
	V_CR_CUOTA
	;
run;


/* BY variable test */
options mprint;
%PlotBinned (toplot(WHERE= (V_CR_PROB_MORA_REF NE 0)) ,
		by = A_MES,
		target = B_TARGET_DQ90_12M,
		class = C_CR_CRITERIO_INCL_GENERAL,
		var = E_CR_NR_OTORG B_FUT_MESES_HASTA_CANCELADO,
		stat = mean min max kurtosis,
		value = mean,
		OUT = CORREL_PROBMORA_DQ90_M,
		outcorr= correl_probmora_DQ90_M_corr,
		valuesLetAlone = 12,
		bubble=0,
		smooth=1,
		plot=1,
		groupsize = 70,
		GROUPS = 10);
options nomprint;

/* Check by running each BY combination separately */
options mprint;
%PlotBinned (toplot(WHERE= (V_CR_PROB_MORA_REF NE 0 and A_MES = 1)),
		target = B_TARGET_DQ90_12M,
		class = C_CR_CRITERIO_INCL_GENERAL,
		var = E_CR_NR_OTORG B_FUT_MESES_HASTA_CANCELADO,
		stat = mean min max,
		OUT = CORREL_PROBMORA_DQ90_M1,
		outcorr= correl_probmora_DQ90_M1_corr,
		valuesLetAlone = 12,
		groupsize = 70,
		GROUPS = 10);
options nomprint;
%PlotBinned (toplot(WHERE= (V_CR_PROB_MORA_REF NE 0 and A_MES = 2)) ,
		target = B_TARGET_DQ90_12M,
		class = C_CR_CRITERIO_INCL_GENERAL,
		var = C_CR_CRITERIO_INCL_GENERAL E_CR_NR_OTORG V_CR_PROB_MORA_REF,
		OUT = CORREL_PROBMORA_DQ90_M2,
		outcorr= correl_probmora_DQ90_M2_corr,
		valuesLetAlone = 1,
		groupsize = 70,
		GROUPS = 10);
%PlotBinned (toplot(WHERE= (V_CR_PROB_MORA_REF NE 0 and A_MES = 3)) ,
		target = B_TARGET_DQ90_12M,
		class = C_CR_CRITERIO_INCL_GENERAL,
		var = C_CR_CRITERIO_INCL_GENERAL E_CR_NR_OTORG V_CR_PROB_MORA_REF,
		OUT = CORREL_PROBMORA_DQ90_M3,
		outcorr= correl_probmora_DQ90_M3_corr,
		valuesLetAlone = 1,
		groupsize=70,
		GROUPS = 10);
