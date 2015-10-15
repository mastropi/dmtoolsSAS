# 11-Oct-2015
# Extract the documentation included in a file that defines a SAS macro.
# The documentation is extracted from the C-like block comment included at the top of the file.
# The output of this program is in HTML format.
#
# SEE ALSO: DocRun.sh which parses all the files in a given directory generating an HTML file for each of them.
#
# EXAMPLE:
# awk -f DocExtract.awk ../Compile/PlotBinned > PlotBinned.html

# References for HTML tagging:
# http://stackoverflow.com/questions/9660987/how-to-get-a-tab-character
# https://developer.mozilla.org/en-US/docs/Web/HTML/Element/pre

# Reference for the styles in the PRE tag in order to avoid additional line break
# http://stackoverflow.com/questions/4233869/html-pre-tag-causes-linebreaks

BEGIN {
	FS = "\t*|[ ]{2,}"				# Field separator is: tab or at least 2 blank spaces
#	FS = "[[ ]{2,}\t*]"				# Field separator is: tab or at least 2 blank spaces
	print "<!DOCTYPE html>\n"
	print "<html>"
	USAGE = 0						# Whether we are inside the USAGE block
	COMMENT = "*{3}"				# Pattern for comment in USAGE section describing an input parameter
}

# Replace two or more consecutive blanks with a tab so that nothing is lost from the line
# Note that apparently the fields $1, $2, etc. are redefined after $0 is updated!
gsub(/[ ]{2,}/,"\t",$0);

# Stop processing when the end of the comment is found
{ if ($0 == "*/") exit 0; }

### Check content of each line
# Start the USAGE block
/^USAGE/ 	{ USAGE = 1 }
# Stop the USAGE block when the keyword REQUIRED is found (since a new section called REQUIRED PARAMETERS starts)
/^REQUIRED/ { USAGE = 0 }

# Check for the start of the documentation by the begin comment keyword: '/*'
{
if ($0 ~ /^\/\*/) {
	# Macro name (just keep the macro name (without the MACRO keyword before it)
	MACRONAME = substr($0, length("/* MACRO ")+1)
	
	# Set page title and the HTML style (note that I do not use CSS styles because this is a very simple HTML!
	print "<head>"
	print "<title>" MACRONAME "</title>"	# Just display the macro name in the title (e.g. %PlotBinned) so that the user can see rightaway the documentation of which macro they are browsing.
	print "<style>"
	print "pre {display: block}"			# Note: the other option for the PRE tag is 'display: inline' in order to avoid additional line breaks after each line. However, when opening the output in Internet Explorer all lines are seen alltogether with no line breaks!!! --> ?
	print "</style>"
	# Start the HTML body section
	print "<body>"

	# Show the macro name
	print "<h1>MACRO " MACRONAME "</h1>"	# The title is e.g. "MACRO %PlotBinned"
}

# Check empty line
else if ($NF == 0) {
	# Insert an empty line when there is nothing in the line to display
	print "<p></p>"
}

# Check title (e.g. DESCRIPTION:, NOTES:, etc.): line has all capital letters and ends with a colon. It may also contain blank spaces.
else if ($0 ~ /^[A-Z ]+:$/) {
	# Make the line a header
	print "<h3>"$0"</h3>"
}

# Normal line whose content should shown as is.
else {
	# Line inside the USAGE block where we should replace '***' comments with /* */ comments
	if (USAGE && $0 ~ COMMENT) {
		sub(COMMENT, "/*", $0)
		$0 = $0 " */"
	}

	# Show the line in verbtaim and add line break at the end
	if (USAGE) FORMAT = "%-10s%-30s%-30s%-30s"
	else FORMAT = "%-30s%-30s%-30s%-30s"
	printf "<pre>" FORMAT "</pre>\n", $1, $2, $3, $4			# <pre></pre> blocks means pre-formatted text. Ref: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/pre
#	printf "<pre>%s</pre>\n", $0								# This is similar to the above but does not align the lines properly.
}
}

END {
	print "<body>"
	print "</html>"
}
