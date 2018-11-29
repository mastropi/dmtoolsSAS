#! /bin/bash

# 16-Oct-2018
# Script that bundles the macros in the specified directory into a single file
# Input parameters (1):
# - directory where the .sas files are read from (e.g. Autocall, Compile)

# Default parameter values
SOURCEDIR="Autocall"					# Input directory with source code

if [ $# -gt 0 ]; then
	SOURCEDIR=$1
fi

echo "Bundling .sas files in $SOURCEDIR directory to file MacrosBundle-$SOURCEDIR.sas"

find $SOURCEDIR -name "*.sas" -exec "cat" {} \; > MacrosBundle-$SOURCEDIR.sas

echo "done"
