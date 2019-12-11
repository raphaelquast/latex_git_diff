#!/bin/bash

# set name of the master-file you want to use (without .tex extension!!)
MASTER="Master"

# set path to the perl-executable
# (this is necessary since git comes with it's own perl distribution and there might be some 
# version- and path problems etc.
perl_exec="C:\Strawberry\perl\bin\perl.exe"

# set path to the latexdiff perl-script
latexdiffpath="C:\Users\rquast\AppData\Local\Programs\MiKTeX 2.9\scripts\latexdiff\latexdiff"


# -----------------------------------------------------------------------
# get command line arguments
LOCAL=$2
REMOTE=$1

# get all names of files that have changed
diffoutput=$(git diff --name-only)
# convert to an array
diffoutputarray=($diffoutput)

# ensure that the file under consideration is a .tex file
if [ ${LOCAL: -4} != ".tex" ]
then 
	echo $LOCAL is NOT a TEX file ... skipping
	exit 0
fi

checkmaster="${LOCAL/$MASTER/xxxxxxx}"
if [ "$checkmaster" != "$LOCAL" ]; then
	# if it's the MASTER-file, generate a master-diff and nothing else
	"$perl_exec" "$latexdiffpath" $LOCAL $REMOTE > "${LOCAL/.tex/_diff.tex}"

else
	# if it's not the MASTER-file

	# if the MASTER_diff.tex already exists, use the existing one, else create it
	if [ -e "${MASTER}_diff.tex" ]
	then
		echo "using the existing ${MASTER}_diff.tex file"
	else
		# execute latexdiff on MASTER file to get latexdiff preamble into the master file
		"$perl_exec" "$latexdiffpath" "${MASTER}.tex" "${MASTER}.tex" > "${MASTER}_diff.tex"
	fi


	# define all possible include-statements used in the master document
	s1="\include{$2}"
	s2="\include{/$2}"
	s3="\include{./$2}"

	# replace input-statements in the master-document with similar statements for the generated diff-files
	replacements=($s1 $s2 $s3)
	for i in "${replacements[@]}"; do
		# replace all occurances of the string "xxx.tex" with "xxx_diff.tex"
		repl="${i/.tex/_diff.tex}"

		# sed s:first_string:second_string:g file
		# (s... string-replace,    g... global, e.g. replace all occurances of the string -i ... inplace, e.g. modify the file directly)
		# use : as delimiter instead of / since / is part of the string that should be replaced by sed
		sed -i s:"$i":"$repl":g "${MASTER}_diff.tex"

		# in case the input-statement does not include the .tex extension
		new_i="${i/.tex/}"
		new_repl="${repl/.tex/}"
		sed -i s:"$new_i":"$new_repl":g "${MASTER}_diff.tex"
	done
	
	
	# generate the diff for the file under consideration
	"$perl_exec" "$latexdiffpath" $LOCAL $REMOTE > "${LOCAL/.tex/_diff.tex}"
fi 




# only compile the pdf after generating the diff for the last file that has been changed
if [ "$LOCAL" = "${diffoutputarray[-1]}" ]
	then
	# in case the file is the last file in the list of changed files
		
	# include only chapters that have changed
	includeonlys=""
	for i in "${diffoutputarray[@]}"; do
		diffname="${i/.tex/_diff}"
		includeonlys="$includeonlys","${diffname},/${diffname},./${diffname}"
	done
	# add the includeonly command before \begin{document}
	sed -i '/^\\begin{document}.*/i \\\includeonly{'"$includeonlys}" "${MASTER}_diff.tex"

	
	# compile the diff
	pdflatex -interaction nonstopmode -output-directory diff "${MASTER}_diff.tex"

	# collect all files
	# move the MASTER_diff.tex file to the diff folder
	mv "${MASTER}_diff.tex" "diff/${MASTER}_diff.tex"
	# move all the CHAPTER_diff.tex files to the diff folder
	for i in "${diffoutputarray[@]}"; do
		if [ ${i: -4} = ".tex" ]
			then 
			mv "${i/.tex/_diff.tex}" "diff/${i/.tex/_diff.tex}"
		fi
	done

	# move the pdf out of the diff folder
	mv "diff/${MASTER}_diff.pdf" "${MASTER}_diff.pdf"

	# remove the diff-folder and all its contents
	rm -r diff

fi