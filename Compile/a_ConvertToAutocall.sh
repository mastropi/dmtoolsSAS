#! /bin/bash

# 15-Feb-2016
# Script that calls the a_ConvertToAutocall.awk AWK program to each .sas file located in the -s or --sourcedir directory
# and generates the corresponding .sas output file in the -o or --outdir directory.
#
# EXAMPLE:
# bash a_ConvertToAutocall.sh

# NOTE: The new line for this file should be UNIX new lines! Otherwise I get an error that \r command is not found.
# Ref: http://stackoverflow.com/questions/11616835/r-command-not-found-bashrc-bash-profile

# Default parameter values
SOURCEDIR="."							# Input directory with source code
OUTDIR="../Autocall"					# Output directory with the processed file
TEST=0									# Non-test mode

OPTIONS=$(getopt -o s:o: -l sourcedir:,outdir:,test -- "$@")
	## The ':' keyword means that after the parameter name we expect a value (e.g. -s src or --sourcedir=src)
	## The '--' keyword is used to signal the end of the input parameters passed
	## The $@ is used to store all input parameters as an array

if [ $? -ne 0 ]; then
  echo "getopt error"
  exit 1
fi

eval set -- $OPTIONS	# Unsets the existing positional parameters and sets them to the result of getopt.

# Parse input parameters
while [ $# -gt 0 ]; do
  case "$1" in
    -s|--sourcedir) 	SOURCEDIR="$2" ; shift ;;	# $2 contains the second value after the = 
    -o|--outdir) 		OUTDIR="$2" ; shift ;;
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
echo "Output directory with processed SAS macros:" \"$OUTDIR\"

# Create output directory if it does not exist
mkdir -p "$OUTDIR"					# The -p option says that the directory should not be created if it already exists (Ref: http://stackoverflow.com/questions/4906579/how-to-use-bash-to-create-a-folder-if-it-doesnt-already-exist)

# Count the number of macros
let NMACROS=0
for FILE in "$SOURCEDIR"/*.sas		# Select all .sas files in the SOURCEDIR directory
do
	let NMACROS+=1	
done
echo Number of files to process: $NMACROS
let LEN=${#NMACROS}

# Process each of the SAS macro with a_ConvertToAutocall.awk
let i=0
for FILE in "$SOURCEDIR"/*.sas
do
	let i+=1

	FILENAME=${FILE#$SOURCEDIR/}	# Remove the SOURCEDIR from the file name
	OUTFILENAME=${FILENAME,,}		# Output file name is the input file name converted to lower case (so that the macros work in Linux!) Ref: https://askubuntu.com/questions/383352/command-to-convert-an-upper-case-string-to-lower-case)
	echo -n Processing SAS macro $FILENAME "-->" $OUTDIR/$OUTFILENAME
	
	# Run AWK!
	if [ $TEST == 0 ]; then
		LC_ALL=C gawk -f a_ConvertToAutocall.awk "$FILE" > "$OUTDIR/$OUTFILENAME"			# Note the use of LC_ALL=C, o.w. lines are truncated when an accented character is encountered (Ref: http://www.catonmat.net/blog/ten-awk-tips-tricks-and-pitfalls)
		
		echo -n ".......Checking that the number of lines in the output file is equal to the number of lines in the input file plus 1..."
		# Check number of lines in the output file
		# NOTE the use of gawk instead of wc because wc may not count the last line if it does not end with an EOL character
		# Ref: http://stackoverflow.com/questions/28038633/wc-l-is-not-counting-last-of-the-file-if-it-does-not-have-end-of-line-character
		#read lines words chars filename <<< $(wc "$FILE")							# Ref for the '<<<' operator: http://stackoverflow.com/questions/7119936/results-of-wc-as-variables
		#NLINES_IN=$lines
		#read lines filename <<< $(wc -l "$OUTDIR/$OUTFILENAME")						# Note the use of the -l option to output just the number of lines
		#NLINES_OUT=$lines
		NLINES_IN=`gawk 'END{print NR}' "$FILE"`
		NLINES_OUT=`gawk 'END{print NR}' "$OUTDIR/$OUTFILENAME"`
		if [ $NLINES_IN -ne $(($NLINES_OUT+1)) ]; then
			echo
			echo "    WARNING: It is expected that the number of lines in the output file name ("$NLINES_OUT") be equal to the number of lines in the input file name ("$NLINES_IN") plus 1"
		else
			echo OK
		fi
	else
		echo
	fi
done

echo
echo "Source directory with SAS macros:" \"$SOURCEDIR\"
echo "Output directory with processed SAS macros:" \"$OUTDIR\"

### Verification step
if [ $TEST == 0 ]; then
	# That all &RSUBMIT and STORE keywords have been removed
	# Note the use of the -e option of grep to pass different search patterns since grep does not support the | operator for OR (although egrep does)
	# Ref: http://unix.stackexchange.com/questions/37313/how-do-i-grep-for-multiple-patterns
	# Note also that I do not check for lines that start and end with '&rsubmit;' on purpose because I want to see if there are other places
	# where this keyword appears...
	echo "Checking that all &RSUBMIT and STORE keywords have been removed from the output files (nothing should appear now)..."
	find $OUTDIR -name "*.sas" -exec grep -i -e "/[ ]*store" -e "[ ]*&rsubmit;[ ]*" {} \;

	# That the number of lines in the output files is the same as in the input files
#	find $OUTDIR -name "*.sas" -exec wc {} \;
fi

echo "DONE!"

read -p "Press ENTER to close..."
