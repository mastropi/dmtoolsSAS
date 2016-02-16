#! /bin/bash

# 11-Oct-2015
# Script that calls the DocExtract.awk AWK program that extracts the documentation from a SAS macro code
# located in the -s or --sourcedir directory and generates an HTML help file in the -o or --outdir directory.
# The script also generates an index HTML file in the execution directory whose name is given by the --index option.
# Can run the script in test mode by specifying --test.
#
# SEE ALSO: DocExtract.awk which is called by this program to extract the documentation from each file in the source directory.
#
# EXAMPLE:
# bash DocRun.sh -s ../Compile -o "DMMacros Documentation" --index="DMMacros Documentation.html" --test

# Reference for the getopt command to read options passed to bash:
# http://stackoverflow.com/questions/3534280/how-can-i-pass-a-file-argument-to-my-bash-script-using-a-terminal-command-in-lin
# http://journal.missiondata.com/post/63404248482/long-arguments-and-getops

# NOTE: The new line for this file should be UNIX new lines! Otherwise I get an error that \r command is not found.
# Ref: http://stackoverflow.com/questions/11616835/r-command-not-found-bashrc-bash-profile

# Default parameter values
SOURCEDIR="../Compile"					# Input directory with source code
OUTDIR="DMMacros Documentation"			# Output directory with HTML files
INDEX="DMMacros Documentation.html"		# Index HTML file
TEST=0									# Non-test mode

OPTIONS=$(getopt -o s:o: -l sourcedir:,outdir:,index:,test -- "$@")
	## The ':' keyword means that after the parameter name we expect a value (e.g. -s src or --sourcedir=src)
	## The '--' keyword is used to signal the end of the input parameters passed
	## The $@ is used to store all input parameters as an array

if [ $? -ne 0 ]; then
  echo "getopt error"
  exit 1
fi

eval set -- $OPTIONS	# Unsets the existing postional parameters and sets them to the result of getopt.

# Parse input parameters
while [ $# -gt 0 ]; do
  case "$1" in
    -s|--sourcedir) 	SOURCEDIR="$2" ; shift ;;	# $2 contains the second value after the = 
    -o|--outdir) 		OUTDIR="$2" ; shift ;;
    --index)			INDEX="$2" ; shift ;;
    --test)				TEST=1 ;;
    --)        			shift ; break ;;			# This keyword is used to signal the end of input parameters
    *)        			echo "unknown option: $1" ; exit 1 ;;
  esac
  shift												# shift removes the first element ($1) from the list of arguments, so that in the next loop $1 is updated with the new argument. Nice!
done

if [ $# -ne 0 ]; then
  echo "unknown option(s): $@"
  exit 1
fi

echo "Source directory with SAS macros:" \"$SOURCEDIR\"
echo "Output directory with help files:" \"$OUTDIR\"

# Create output directory if it does not exist
mkdir -p "$OUTDIR"					# The -p option says that the directory should not be created if it already exists (Ref: http://stackoverflow.com/questions/4906579/how-to-use-bash-to-create-a-folder-if-it-doesnt-already-exist)

# Count the number of macros
let NMACROS=0
for FILE in "$SOURCEDIR"/*
do
	let NMACROS+=1	
done
echo Number of files to process: $NMACROS
let LEN=${#NMACROS}

# Create the index HTML file (this file is created in the directory where this bash program is run)
echo "<!DOCTYPE html>" > "$INDEX"	# Need to enclose $INDEX in quotes to avoid the "ambiguous redirect" error.
echo "<html>" >> "$INDEX"
echo "<head>" >> "$INDEX"
echo "<title>Index for SAS macros documentation in DMMacros</title>" >> "$INDEX"
echo "</head>" >> "$INDEX"
echo "<body>" >> "$INDEX"
echo "<h2>Index for SAS macros created by Daniel Mastropietro</h1>" >> "$INDEX"
DATE=`date +%Y-%m-%d`
echo "<p>Generated on $DATE</p>" >> "$INDEX"
echo "$NMACROS macros sorted alphabetically<br>" >> "$INDEX"
echo "(single click opens the documentation in a new tab)<br>" >> "$INDEX"
echo "<p></p>" >> "$INDEX"

# Process the SAS macros and create HTML help files
let i=0
for FILE in "$SOURCEDIR"/*
do
	let i+=1

	FILENAME=${FILE#$SOURCEDIR/}	# Remove the SOURCEDIR from the file name
	MACRONAME=${FILENAME%.sas}		# Remove extension .sas from file name in order to construct the help file name
	HELPFILE=$MACRONAME.html		# HTML file name
	echo Processing SAS macro $FILENAME "-->" $HELPFILE
	
	# Run AWK!
	if [ $TEST == 0 ]; then
		LC_ALL=C gawk -f DocExtract.awk "$FILE" > "$OUTDIR/$HELPFILE"					# Note the use of LC_ALL=C, o.w. lines are truncated when an accented character is encountered (Ref: http://www.catonmat.net/blog/ten-awk-tips-tricks-and-pitfalls)
	fi

	# Add an entry to the index HTML file
#	printf "%${LEN}s: %s" "$i" "<a href=\"$OUTDIR/$HELPFILE\" target="_blank">%$FILENAME</a><br>" >> "$INDEX"		# The ${LEN}s does NOT work... don't know why (Ref for printf: http://wiki.bash-hackers.org/commands/builtin/printf)
	echo "$i: <a href=\"$OUTDIR/$HELPFILE\" target="_blank">%$FILENAME</a><br>" >> "$INDEX"		# target="_blank" opens the link in a new tab (Ref: http://stackoverflow.com/questions/15551779/open-link-in-new-tab)
done

echo "</body>" >> "$INDEX"
echo "</html>" >> "$INDEX"

echo
echo "Source directory with SAS macros:" \"$SOURCEDIR\"
echo "Output directory with help files:" \"$OUTDIR\"
