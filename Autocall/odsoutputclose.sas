%* MACRO %ODSOutputClose;
%* Created: 01-Sep-2015;
%* Modified: 29-Nov-2018;
%* Author: Daniel Mastropietro;
%* Close an open ODS output file;
%* SEE ALSO: %ODSOutputOpen;
%MACRO ODSOutputClose(odsfile, odsfiletype=pdf, macro=, log=0) / des="Closes an open ODS output file";
%if %quote(&odsfile) ~= and %quote(&odsfiletype) ~= %then %do; 
	ods &odsfiletype close;
	%if &log %then %do;
		%put;
		%if %quote(&macro) ~= %then
			%put %upcase(&macro): %upcase(&odsfiletype) file "&odsfile" created by ODS.;
		%else
			%put %upcase(&odsfiletype) file "&odsfile" created by ODS.;
	%end;
%end;
%MEND ODSOutputClose;
