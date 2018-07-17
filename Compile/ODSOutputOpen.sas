%* MACRO %ODSOutputOpen;
%* Created: 01-Sep-2015;
%* Author: Daniel Mastropietro;
%* Open an ODS output file for writing;
%* SEE ALSO: %ODSOutputClose;
&rsubmit;
%MACRO ODSOutputOpen(odspath, odsfile, odsfiletype=pdf, macro=, log=0) / store des="Opens an ODS output file for writing";
%if %quote(&odsfile) ~= and %quote(&odsfiletype) ~= %then %do;
	%if %upcase(%quote(&odsfiletype)) = HTML and %quote(&odspath) ~= %then %do;
		%* This distinction of HTML output is necessary because this is the only format that accepts the PATH= option...;
		%* (the reason being that the HTML output stores graphs in separate files (e.g. PNG files that are linked to the HTML output);
		ods &odsfiletype path=&odspath file=&odsfile style=statistical;
	%end;
	%else %do;
		ods &odsfiletype file=&odsfile style=statistical;
	%end;

	%if &log %then %do;
		%if %quote(&macro) ~= %then
			%put %upcase(&macro): %upcase(&odsfiletype) file %quote(&odsfile) opened for output by ODS.;
		%else
			%put %upcase(&odsfiletype) file %quote(&odsfile) opened for output by ODS.;
		%put;
	%end;
%end;
%MEND ODSOutputOpen;
