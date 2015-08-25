#!/bin/bash -
##############################################################################
# reporter.sh (c) 2015 Cardiff Universtiy
# written by Andreas Buerki
####
version="0.5"
# DESCRRIPTION: creates reports for word-association data
################# defining functions ###############################

#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename "$0") creates reports out of word-association data
SYNOPSIS:     $(basename "$0") WA-FILE.csv

NOTE:         - WA-FILE.csv is a csv file containing word-association data
              - required format: as output by categoriser.sh
"
}
#######################
# define add_to_name function
#######################
# this function checks if a file name (given as argument) exists and
# if so appends a number to the end so as to avoid overwriting existing
# files of the name as in the argument or any with the name of the argument
# plus an incremented count appended.
####
add_to_name ( ) {
count=
if [ "$(grep '.csv' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.csv//' <<< "$1")"
		while [ -e "$new$add$count.csv" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.csv//' <<< "$1")$add$count.csv"
elif [ "$(grep '.dat' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.dat//' <<< "$1")"
		while [ -e "$new$add$count.dat" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.dat//' <<< "$1")$add$count.dat"
elif [ "$(grep '.txt' <<< "$1")" ]; then
	if [ -e "$1" ]; then
		add=-
		count=1
		new="$(sed 's/\.txt//' <<< "$1")"
		while [ -e "$new$add$count.txt" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.txt//' <<< "$1")$add$count.txt"
else
	if [ -e "$1" ]; then
		add=-
		count=1
		while [ -e "$1-$count" ]
			do
			(( count += 1 ))
			done
	else
		count=
		add=
	fi
	output_filename=$(echo "$1$add$count")
fi
}
################## end defining functions ########################
# initialise some variables
extended="-r"
# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	CYGWIN=true
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
	DARWIN=true
else
	LINUX=true
fi
# analyse options
while getopts adhvV opt
do
	case $opt	in
	a)	auxiliary=true
		;;
	d)	diagnostic=true
		;;
	h)	help
		exit 0
		;;
	v)	verbose=true
		;;
	V)	echo "$(basename "$0")	-	version $version"
		echo "(c) 2015 Cardiff University - Licensed under the EUPL v. 1.1"
		exit 0
		;;
	esac
done
shift $((OPTIND -1))
################ checks on input files
# initialise some variables
in_filename=

if [ $# -gt 1 ]; then
	echo "Only one file is processed at a time. Processing $1 only." >&2
fi

# check that input file exists
if [ -s "$1" ]; then
		:
else
	echo "ERROR: could not open $file"
	exit 1
fi

# check what sorts of input files we've got
case $# in
	0)	echo "ERROR: no input files provided. Minimally, one input file needs to be provided to create a report. See the manual for details." >&2
		exit 1
		;;
	1)	if [ "$(echo "$1" | egrep '\.csv')" ]; then
			# testing format by checking whether there is a 'category' field in
			# the header
			if [ -z "$(head -1 "$1" | egrep ',\"*category\"*')" ]; then
				echo "ERROR: \"$1\" does not appear to be of the correct format. A .csv file with wa-responses and categories needs to be provided."
				exit 1
			fi
			in_filename="$1"
		fi
		;;
	*)	echo "ERROR: $(basename "$0") only deals with one input list at a time."
		exit 1
		;;
esac
if [ "$auxiliary" ]; then
	printf "\033c"
	echo
	echo
	echo
	echo
	echo
else
############## splash screen
printf "\033c"
echo "Word Association Data Processor - (c) 2015 Cardiff University - licensed under the EUPL v.1.1."
echo
echo
echo
echo
echo
echo "          WORD ASSOCIATION DATA REPORTER"
echo "          version $version"
fi

echo 
echo 
echo 
echo 
echo 
echo 
echo 
echo "          Please enter required report type(s) and press ENTER"
echo "          (I)   individual respose profiles"
echo "          (C)   cue profiles"
# echo "          (S)   stereotypy rating"
read -p '			' report_types < /dev/tty
case $report_types in
	I|i)	by_respondent=true
		;;
	C|c)	by_cue=true
		;;
	IC|CI|ic|ci)	by_respondent=true
			by_cue=true
		;;
	*)		echo "$report_types is not a valid option."
			read -p 'Please try again ' report_types < /dev/tty
			case $report_types in
				R|r)	by_respondent=true
					;;
				C|r)	by_cue=true
					;;
				RC|CR|rc|cr)	by_respondent=true
						by_cue=true
					;;
				*)	echo "$report_types is not a valid option. Exiting."
					exit 1		
			esac
esac
printf "\033c"

################ create two scratch directories
# first one to keep db sections in
RSCRATCHDIR=$(mktemp -dt reporterXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$RSCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}reporterXXX.1$$
	RSCRATCHDIR=${TMPDIR-/tmp/}reporterXXX.1$$
fi
if [ "$diagnostic" == true ]; then
	if [ "$CYGWIN" ]; then
		cygstart $RSCRATCHDIR
	elif [ "$DARWIN" ]; then
		open $RSCRATCHDIR
	else
		xdg-open $RSCRATCHDIR
	fi
fi
# second one to keep other auxiliary and temporary files in
SCRATCHDIR=$(mktemp -dt reporterXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}reporterXXX.1$$
	SCRATCHDIR=${TMPDIR-/tmp/}reporterXXX.1$$
fi
if [ "$diagnostic" == true ]; then
	if [ "$CYGWIN" ]; then
		cygstart $SCRATCHDIR
	elif [ "$DARWIN" ]; then
		open $SCRATCHDIR
	else
		xdg-open $SCRATCHDIR
	fi
fi

################ processing in-file #########
# initialise some variables
in_rows= # total rows in file
in_cues= # n/a
in_header= # header w/o respondent ID heading
ID_header= # header for respondent ID column (if present)
cue= # n/a
category= # n/a
in_with_ID= # true if in-file has respondent IDs
in_respondentIDs= # holds respondent IDs w/o heading
in_wa= # holds in-file
in_columns= # holds NUMBER of columns in in-file
rowcount=-1 # set rowcount to -1 so the first line will be first row
cat_columns= # holds numbers indicating the columns that contain cats
in_categories= # holds the category columns of in-file

# read input file
echo -n "analysing $in_filename ..."
# create filename only
in_filename_only="$(basename "$in_filename")"
# make sure it's the right format if in cygwin
if [ "$CYGWIN" ]; then
	conv -U "$in_filename" 2>/dev/null
fi

# parse data into variables
# we need to insert underscores in place of any spaces in responses
# and we need to cater for potential empty responses which would
# show as 2 (or more) consecutive commas
# it's also better to replace any potentially confusing special characters
# these things are taken care of as the file is read in
in_wa="$(sed $extended -e 's/\|/PIPE/g' -e 's/\"\"//g' -e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' -e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' -e 's/ /_/g' -e 's/\|\|/\|_\|/g' -e 's/\|\|/\|_\|/g' -e 's/\;//g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/\(/_LBRACKET_/g' -e 's/\)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/\+/_PLUS_/g' "$in_filename" | tr '\r' '\n')"
echo -n '.'
# diagnostics
if [ "$diagnostic" ]; then
	echo
	echo "file read as:"
	echo "$in_wa"
	read -p 'Press ENTER to continue' a  < /dev/tty
fi
# check how many rows in file
in_rows=$(wc -l <<< "$in_wa")
# count in_columns
in_columns=$(( 1 + $(head -1 <<< "$in_wa" | tr -dc '|' | wc -c) ))
# check fields were properly separated: each line should contain the same number of field separators. If that is not the case, throw error and exit
while read line; do
	if [ "$(tr -dc '|' <<< $line | wc -c)" -ne "$(( $in_columns - 1 ))" ]; then
		echo "ERROR: field separation inconsistency. There should be exactly $(( $in_columns - 1)) fields per line. $(tr -dc '|' <<< $line | wc -c) were detected here:
$line" >&2
		rm -r $SCRATCHDIR $RSCRATCHDIR &
		exit 1
	fi
done <<< "$in_wa"
echo '.'
# transfer header into in_header variable and remove from $in_wa
original_header="$(head -1 <<< "$in_wa")"
in_header="$(sed $extended -e 's/[[:digit:]][[:digit:]]*_DOT_._DOT__([[:alpha:]]*)_––_Your_responses*/\1/g' -e 's/[[:digit:]][[:digit:]]*_DOT_.([[:alpha:]]*)/\1/g' -e 's/\|[^\|:]+:_/|/g' <<< $original_header)"
in_wa="$(tail -n +2 <<< "$in_wa")"
# check if in-file contains respondent IDs
if [ -n "$(cut -d '|' -f 1 <<< "$in_header" | grep 'ID')" ]; then
	in_with_ID=true
	# put IDs in variable
	in_respondentIDs=$(cut -d '|' -f 1 <<< "$in_wa")
	# check if there are non-unique respondent IDs
	if [ "$(sort <<< "$in_respondentIDs" |uniq| wc -l)" -ne "$(wc -l <<< "$in_respondentIDs")" ]; then
		echo "ERROR: non-unique respondent IDs in $in_filename_only. Please verify and try again, or use file without respondent IDs."
		rm -r $SCRATCHDIR $RSCRATCHDIR &
		exit 1
	fi
	# take IDs out of $in_wa and reduce in_columns
	in_wa="$(cut -d '|' -f 2-$in_columns <<< "$in_wa")"
	((in_columns-=1))
	# take ID heading out of in_header put it in ID_header
	ID_header=$(cut -d '|' -f 1 <<< "$in_header")
	in_header=$(cut -d '|' -f 2- <<< "$in_header")
	echo "respondent IDs detected ..."
else
	if [ "$diagnostic" ]; then echo "No respondent IDs detected.";sleep 1; fi
fi

# identify 'category' columns
for field in $(sed $extended 's/\|/ /g' <<< "$in_header"); do
	(( field_no += 1 ))
	if [ "$(egrep '^category$' <<< "$field")" ]; then
		cat_columns+=" $field_no"
		if [ "$sw" ]; then
			echo "ERROR: two consecutive category columns in $in_filename. Please verify and try again"
			exit 1
		fi
		sw=ON
	else
		sw=
	fi
done
field_no=
field=
# verify identified columns are plausible
last_cat_column="$(egrep -o '[[:digit:]]+$' <<< "$cat_columns")"
if [ "$last_cat_column" -lt $(( $in_columns - 1 )) ]; then
	# if last category column is not the last or penultimate column of the file	
	echo "ERROR: the last or penultimate column of $in_filename_only should be a category column."
	echo "However, the two final colums are: $(egrep -o '\|[^\|]+\|[^\|]+$' <<< "$in_header" | sed $extended -e 's/\|/ /g' -e 's/ /, /2')"
	echo "Please verify and try again."
	exit 1
fi
last_cat_column=
# pick out category columns
in_categories="$(cut -d '|' -f $(sed $extended -e 's/^ //' -e 's/ /,/g' <<< $cat_columns) <<< "$in_wa")"
# report
if [ "$diagnostic" ]; then 
	echo "categories are:"
	echo "$in_categories"
	read -p 'Press ENTER to continue' a  < /dev/tty
fi
########################### assembling by-respondent report ####################
if [ "$by_respondent" ]; then
	echo -n "Gathering figures for report of categories by respondent..."
	rowcount=
	# process line-by-line
	for line in $in_categories; do
	if [ "$diagnostic" ]; then echo;echo "this is line: $line";fi
	(( rowcount += 1 ))
	# write every respondent's category frequencies to a tmp file with their ID
	if [ "$in_respondentIDs" ]; then
		# in the following, empty lines need to have an underscore inserted
		tr '|' '\n' <<< "$line" | sed 's/^$/_/g' | sort | uniq -c | sed $extended -e 's/^ +//' -e 's/([[:digit:]]+) (.+)/\2	\1/g' > $RSCRATCHDIR/$(cut -d ' ' -f $rowcount <<< $in_respondentIDs)
	else
		tr '|' '\n' <<< "$line" | sed 's/^$/_/g' | sort | uniq -c | sed $extended -e 's/^ +//' -e 's/([[:digit:]]+) (.+)/\2	\1/g' > $RSCRATCHDIR/respondent$rowcount
	fi
	done
	# assemble overall list of categories
	extant_cats=$(cut -f 1 $RSCRATCHDIR/* | sort | uniq)
	if [ "$diagnostic" ]; then echo "categories are $extant_cats";fi
	echo "."
	##### assemble report
	# write header and then row by row
	if [ "$in_respondentIDs" ]; then
		report_out="$ID_header|$(sed $extended 's/ /|/g' <<< $extant_cats | sed 's/_/no response/g')"
		for row in $in_respondentIDs; do
			out_row="$row"
			for out_cat in $extant_cats; do
				out_row+="|$(grep "^$out_cat	" $RSCRATCHDIR/$row |cut -f 2)"
			done
			report_out+="
$out_row"
		done
	else
		report_out="$(sed 's/ /|/g' <<< $extant_cats| sed 's/_/no response/g')"
		for row in $(eval echo {1..$(( $in_rows - 1 ))}); do
			# it's in_rows minus 1 because of the header
			out_row=
			for out_cat in $extant_cats; do
				out_row+="|$(grep "^$out_cat	" $RSCRATCHDIR/respondent$row |cut -f 2)"
			done
			report_out+="
$(sed $extended 's/^\|//g' <<< "$out_row")"
		done
	fi
	# write report file
	# create name of report output file
	add_to_name i-report_$in_filename_only
	sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' <<< "$report_out" > "$output_filename"
	# undo any cygwin damage
	if [ "$CYGWIN" ]; then
		conv -U "$output_filename" 2>/dev/null
	fi
	echo "Report saved as \"$output_filename\"."
	# tidy up
	extant_cats=
	report_out=
	out_row=
	out_cat=
fi

########################### assembling by-cue report ####################
if [ "$by_cue" ]; then
	echo -n "Gathering figures for report of categories by cue..."
	# derive cue column indices
	for num in $cat_columns; do
		cue_columns+=" $(( $num - 1 ))"
	done
	# pick out cues from header
	cues="$(cut -d '|' -f $(sed -e 's/^ //' -e 's/ /,/g' <<< $cue_columns) <<< "$in_header")"
	no_of_cues=$(( $( tr -dc ' ' <<< $cue_columns | wc -c) + 1 ))
	if [ "$diagnostic" ]; then
		echo "cue columns: $cue_columns"
		echo "no of cues: $no_of_cues"
	fi
	echo "."
	# process by column-by-column to write cat frequencies of every cue to tmp
	for colu in $(eval echo {1..$no_of_cues}); do
		cut -d '|' -f $colu <<< "$in_categories" | sed 's/^$/_/g' | sort | uniq -c | sed $extended -e 's/^ +//' -e 's/([[:digit:]]+) (.+)/\2	\1/g' > $SCRATCHDIR/$(cut -d '|' -f $colu <<< $cues)
	done
	# assemble overall list of categories
	extant_cats=$(cut -f 1 $SCRATCHDIR/* | sort | uniq)
	#echo "categories are $extant_cats"
	##### assemble report
	# assemble header
	report_out="cues|$(sed 's/ /|/g' <<< $extant_cats| sed 's/_/no response/g')"
	# assemble rows
	for row in $(eval echo {1..$no_of_cues}); do
		current_cue=$(cut -d '|' -f $row <<< $cues)
		out_row=$current_cue
		for out_cat in $extant_cats; do
			out_row+="|$(grep "^$out_cat	" $SCRATCHDIR/$current_cue |cut -f 2)"
		done
		report_out+="
$(sed $extended 's/^\|//g' <<< "$out_row")"
	done
	# write report file
	# create name of report output file
	add_to_name c-report_$in_filename_only
	sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' <<< "$report_out" > "$output_filename"
	# undo any cygwin damage
	if [ "$CYGWIN" ]; then
		conv -U "$output_filename" 2>/dev/null
	fi
	echo "Report saved as \"$output_filename\"."
	# tidy up
	extant_cats=
	report_out=
	out_row=
	out_cat=
fi

# tidy up
if [ -z "$diagnostic" ]; then
	rm -r $RSCRATCHDIR $SCRATCHDIR &
fi

# ask if directory should be opened
echo ""
read -p 'Would you like to open the output directory? (Y/n)' a  < /dev/tty
if [ "$a" == "y" ] || [ "$a" == "Y" ] || [ -z "$a" ]; then
	if [ "$CYGWIN" ]; then
		cygstart .
	elif [ "$DARWIN" ]; then
		open .
	else
		xdg-open .
	fi
fi