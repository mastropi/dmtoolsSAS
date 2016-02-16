# 15-Feb-2016
# Remove the STORE keyword from the %MACRO statement of a SAS macro definition program file
# in order to make the macro ready to be used as a SAS Autocall macro.
# Note that the STORE keyword in the %MACRO statement CANNOT come from a macro variable &STORE
# that would be empty when we want the macro to be run as a SAS Autocall macro!
#
# SEE ALSO: a_RemoveStore.sh which calls this program for each file in a given directory.
#
# EXAMPLE:
# awk -f a_RemoveStore.awk PlotBinned.sas > ../CompileNoStore/PlotBinned.sas
#

BEGIN{IGNORECASE=1}

/\/[ ]*store[ ]+des/ { count++; gsub("store", ""); }
{print}

END{
	print "...Number of lines replaced: " count > "/dev/stderr";	# This output is redirected to the STANDARD ERROR (so that it does not get output to the redirected output file!)
	if (count == 0) {
		print "\tWARNING: No lines were replaced!" > "/dev/stderr";
	}
}
