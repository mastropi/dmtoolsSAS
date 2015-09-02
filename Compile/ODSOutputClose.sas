%* MACRO %ODSOutputClose;
%* Created: 01-Sep-2015;
%* Author: Daniel Mastropietro;
%* Close an open ODS output file;
%* SEE ALSO: %ODSOutputOpen;
&rsubmit;
%MACRO ODSOutputClose(odsfile, odsfiletype=pdf, macro=, log=0) / store des="Closes an open ODS output file";
%if %quote(&odsfile) ~= %then %do; 
	ods &odsfiletype close;
	%if &log %then %do;
		%put;
		%if %quote(&macro) ~= %then
			%put %upcase(&macro): %upcase(&odsfiletype) file %quote(&odsfile) created by ODS.;
		%else
			%put %upcase(&odsfiletype) file %quote(&odsfile) created by ODS.;
	%end;
%end;
%MEND ODSOutputClose;
