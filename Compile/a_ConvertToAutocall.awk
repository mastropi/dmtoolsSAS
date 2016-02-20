# 15-Feb-2016
# Convert a SAS macro definition from a Compile version to an Autocall version by:
# - removing the STORE keyword from the %MACRO statement
# - removing the &rsubmit; line above the %MACRO statement
# NOTES:
# - the STORE keyword in the %MACRO statement CANNOT come from a macro variable &STOR
# that would be empty when we want the macro to be run as a SAS Autocall macro!
# - the &RSUBMIT macro CANNOT be defined as empty either as it generates very bad errors
# related to "open code recursion detected" which makes SAS unusable afterwards.
#
# SEE ALSO: a_ConvertToAutocall.sh which calls this program for each file in a given directory.
#
# EXAMPLE:
# awk -f a_ConvertToAutocall.awk PlotBinned.sas > ../Autocall/PlotBinned.sas
#

BEGIN{IGNORECASE=1}

# Remove the STORE keyword
/\/[ ]*store[ ]+des/ { count++; gsub("store", ""); }
# Do not output the line with the &rsubmit because it generates large problems with "open code recursion detected"... very messy!
# Only lines having just that word '&rsubmit;' are excluded.
{ if (! ($0 ~ /^[ ]*&rsubmit;[ ]*$/)) print }

END{
	print "...Number of lines replaced: " count > "/dev/stderr";	# This output is redirected to the STANDARD ERROR (so that it does not get output to the redirected output file!)
	if (count == 0) {
		print "\tWARNING: No lines were replaced!" > "/dev/stderr";
	}
}
