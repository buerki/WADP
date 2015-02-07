#!/bin/bash -

##############################################################################
# categoriser.sh (c) ABuerki 2014
####
version="0.3.1"
# DESCRRIPTION: assigns categories to word-association data

################ the following section can be adjusted

# the key used for category assignments
key='
  (A)     Affix manipulation                      (e.g. irony -> ironic)
  (CR)    Cue-Response collocation                (e.g. fence -> post)
  (CRRC)  Cue-Response & Response Cue collocation (e.g. rock -> hard)
  (E)     Erratic                                 (e.g. wolf -> and)
  (F)     similar in Form only                    (e.g. fence -> hence)
  (I)     two-step association                    (e.g. weak -> Monday, via 'week')
  (L)     Lexical set                             (e.g. bean -> vegetable, bean -> pea)
  (LCR)   Lexical set & Cue-Response collocation  (e.g. gold -> silver)
  (LRC)   Lexical set & Response-Cue collocation  (e.g. cheese -> bread)
  (OC)    Other Conceptual                        (e.g. fence -> field)
  (OCCR)  Other Conceptual & Cue-Response colloc. (e.g. long -> corridor)
  (OCRC)  Other Conceptual & Response-Cue colloc. (e.g. attack -> knife)
  (RC)    Response-Cue collocation                (e.g. fence -> electric)
  (S)     Synonym                                 (e.g. delay -> impede)
  (SCR)   Synonym & Cue-Response collocation      (e.g. torch -> light)
  (SRC)   Synonym & Response-Cue collocation      (e.g. shove -> push)
  (SS)    Synonym plural                          (e.g. variety -> choices)
'

# list of allowed categories
allowed_categories='A,CR,CRRC,E,F,I,L,LCR,LRC,OC,OCCR,OCRC,RC,S,SCR,SRC,SS'

################# end of user-adjustable section
################# defining functions ###############################

#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename $0) assigns categories to word-association data
SYNOPSIS:     $(basename $0) [-r] [(DATABASE.dat|DATABASE.csv)] WA-FILE.csv
              Items in square brackets are optional. Order is significant.
OPTIONS:      -r   if used, this will result in rater IDs listed in output file
              -V   to display version, copyright and licensing information
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
if [ "$(grep '.csv' <<< $1)" ]; then
	if [ -e $1 ]; then
		add=-
		count=1
		new="$(sed 's/\.csv//' <<< $1)"
		while [ -e "$new$add$count.csv" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.csv//' <<< $1)$add$count.csv"
elif [ "$(grep '.dat' <<< $1)" ]; then
	if [ -e $1 ]; then
		add=-
		count=1
		new="$(sed 's/\.dat//' <<< $1)"
		while [ -e "$new$add$count.dat" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.dat//' <<< $1)$add$count.dat"
elif [ "$(grep '.txt' <<< $1)" ]; then
	if [ -e $1 ]; then
		add=-
		count=1
		new="$(sed 's/\.txt//' <<< $1)"
		while [ -e "$new$add$count.txt" ];do
			(( count += 1 ))
		done
	else
		count=
		add=
	fi
	output_filename="$(sed 's/\.txt//' <<< $1)$add$count.txt"
else
	if [ -e $1 ]; then
		add=-
		count=1
		while [ -e $1-$count ]
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

###################
# standard menu function (displays standard menu)
###################
standard_menu ( ) {
		clear
		echo "Please rate the following pair:"
		echo " "
		echo " "
		echo "		$cue   ->   $(sed 's/_/ /g' <<< $response)"
		echo " "
		echo " "
		echo "enter a choice and press ENTER:"
		echo "$key"
		echo "  (X)     exit (work will be saved)"
		if [ -n "$previous_pair" ]; then
		 echo "  (B)     back to previous pair"
		fi
		echo " "
		read -p '>>> ' category  < /dev/tty
		category=$(tr '[[:lower:]]' '[[:upper:]]' <<< $category)
		echo "You entered: $category"
		sleep 0.4
}

###################
# back menu function (displays standard menu)
###################
back_menu ( ) {
		clear
		echo "Previously you rated this pair as follows:"
		echo " "
		echo " "
		echo "	$(echo "$previous_pair" | cut -d ':' -f 2 | sed $extended -e 's/\|/   ->   /' -e 's/\|/   /' -e 's/_/ /g')"
		echo " "
		echo " "
		echo "enter a fresh choice and press ENTER:"
		echo "$key"
		read -p '>>> ' old_category  < /dev/tty
		old_category=$(tr '[[:lower:]]' '[[:upper:]]' <<< $old_category)
		echo "You entered: $old_category"
		sleep 0.4
}

###################
# exit_routine function (saves output files)
###################
exit_routine ( ) {
echo "saving files ..."
# if there is a previous pair,
if [ "$previous_pair" ]; then
	# write current_assignment to output list
	echo "$previous_pair$rater_id" >> $SCRATCHDIR/$categorised_out
	# update db with current_assignment's response and cat
	if [ -z "$(egrep '\|$' <<< $previous_pair)" ]; then
		# if the category assigned is not empty
		echo "$(cut -d '|' -f 2-3 <<< $previous_pair)$rater_id" >> $DBSCRATCHDIR/$previous_cue 2> /dev/null
	fi
fi
### write db file (this is tab delimited with one cue per line)
add_to_name db-$(date "+%d-%m-%Y%n").dat
for part in $(ls $DBSCRATCHDIR); do 
	echo "$part	$(tr '\n' '	' < $DBSCRATCHDIR/$part)" >> $output_filename
	dboutfilename=$output_filename
done
if [ "$ouput_filename" ]; then
	echo "updated database file saved as \"$ouput_filename\"."
fi
### check if out-file is required
if [ -z "$final_writeout" ]; then
	echo "The rating is not complete, yet."
	read -t 10 -p 'Output list for the part that is complete? [Y/n]' req_out < /dev/tty
	if [ "$req_out" == "n" ] || [ "$req_out" == "N" ]; then
		echo "updated database file only..."
	else
		write_inout
		echo "Output written to \"$categorised_out\""
	fi
else
	write_inout
	echo "Output written to \"$categorised_out\""
fi
echo "New database written to \"$dboutfilename\""
### tidy up
rm db.dat.tmp 2> /dev/null &
rm -r $SCRATCHDIR $DBSCRATCHDIR 2> /dev/null &
# exit
exit 0
}

###################
# write inout function (writes the wa input file out with assigned categories)
###################
write_inout ( ) {
# sort the in_cues
in_cues=$(tr '|' '\n' <<< $in_cues | sort | tr '\n' '|') 
# write header
if [ "$in_with_ID" ]; then
	# assemble in variable in_header_out
	# first get whatever was used for the heading of respondent IDs
	in_header_out="$(head -1 <<< "$in_respondentIDs")|"
	# get cues in original order and insert 'category' after each
	for cue in $(sed $extended 's/\|/ /g' <<< $in_cues); do
		if [ "$output_raterIDs" ]; then
			in_header_out+="$cue|category|rated by|"
		else
			in_header_out+="$cue|category|"
		fi
	done
	# new write to outfile
	sed $extended -e 's/^/\"/' -e 's/\|$/\"/g' -e 's/\|/\",\"/g' <<< "$in_header_out" > $categorised_out
	#echo "header is: $in_header_out"
else
	# assemble in variable in_header_out
	# get cues in original order and insert 'category' after each
	for cue in $(sed $extended 's/\|/ /g' <<< $in_cues); do
		if [ "$output_raterIDs" ]; then
			in_header_out+="$cue|category|rated by|"
		else
			in_header_out+="$cue|category|"
		fi
	done
	# new write to outfile
	sed $extended -e 's/^/\"/' -e 's/\|$/\"/g' -e 's/\|/\",\"/g' <<< "$in_header_out" > $categorised_out
	#echo "header is: $in_header_out"
fi
# write rows
if [ -e $SCRATCHDIR/$categorised_out ]; then
if [ "$in_with_ID" ]; then
	for ID in $(tail -n +2 <<< "$in_respondentIDs"); do
		(( row += 1 ))
		# assemble row in variable out_row
		# first get ID
		out_row="$ID|"
		# now get pairs for that row (it needs to check if row is complete and only prints complete rows, otherwise things would be a mess)
		responses_in_this_row="$(egrep "^$row:" $SCRATCHDIR/$categorised_out | sort | cut -d '|' -f 2-3)"
		if [ "$output_raterIDs" ]; then
			responses_in_this_row="$(sed 's/;/\",\"/' <<< "$responses_in_this_row")"
		else
			responses_in_this_row="$(cut -d ';' -f 1 <<< "$responses_in_this_row")"
		fi
		if [ "$(wc -l <<< "$responses_in_this_row")" -eq "$in_columns" ]; then
		# if we have a complete row, write it out
			out_row+="$(tr '\n' '|' <<< "$responses_in_this_row")"
			write_neatly >> $categorised_out
		fi
		# clear variable for next row
		out_row=
	done
else
	for n in $(eval echo {1..$(( $in_rows - 1 ))}); do
		(( row += 1 ))
		# assemble row in variable out_row (it needs to check if row is complete and only prints complete rows, otherwise things would be a mess)
		responses_in_this_row="$(egrep "^$row:" $SCRATCHDIR/$categorised_out | sort | cut -d '|' -f 2-3)"
		if [ "$output_raterIDs" ]; then
			responses_in_this_row="$(sed 's/;/\",\"/' <<< "$responses_in_this_row")"
		else
			responses_in_this_row="$(cut -d ';' -f 1 <<< "$responses_in_this_row")"
		fi
		#echo "responses_in_this_row: $(wc -l <<< "$responses_in_this_row") of $in_columns"
		if [ "$(wc -l <<< "$responses_in_this_row")" -eq "$in_columns" ]; then
		# if we have a complete row, write it out
			out_row+="$(tr '\n' '|' <<< "$responses_in_this_row")"
			write_neatly >> $categorised_out
		fi
		# clear variable for next row
		out_row=
	done
fi
else # this is the else for checking if SCRATCHDIR/categorised_out exists
	echo "$categorised_out will only contain a header because of the small number of ratings performed."
fi 
}

###################
# write neatly function (write categorised_out file; func used by write_inout)
###################
write_neatly ( ) {
sed $extended -e 's/^/\"/' -e 's/\|$/\"/g' -e 's/\|/\",\"/g' -e 's/_/ /g' -e 's/\–/-/g' -e 's/_DOT_/\./g' -e 's=_SLASH_=/=g' -e "s/_APOSTROPHE_/\'/g" -e 's/_LBRACKET_/(/g' -e 's/_RBRACKET_/)/g' -e 's/_ASTERISK_/\*/g' -e 's/_PLUS_/\+/g' <<< $out_row
}

################## end defining functions ########################

# initialise some variables
extended="-r"

# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	alias clear='printf "\033c"'
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
fi

# analyse options
while getopts dhrvV opt
do
	case $opt	in
	d)	diagnostic=true
		;;
	h)	help
		exit 0
		;;
	r)	output_raterIDs=true
		;;
	v)	verbose=true
		;;
	V)	echo "$(basename $0)	-	version $version"
		echo "(c) 2014 Andreas Buerki - Licensed under the EUPL v. 1.1"
		exit 0
		;;
	esac
done

shift $((OPTIND -1))

# splash screen
clear
echo "Word Association Data Processor - (c) 2014 Andreas Buerki - licensed under the EUPL v.1.1."
echo
echo
echo
echo
echo
echo "			WORD ASSOCIATION DATA CATEGORISER"
echo "			version $version"
echo 
echo 
echo 
echo 
echo 
echo 
echo 


################ checks on input files

# initialise some variables
grand_db=
db_filename=
wa_in_filename=
db_is_dat=


# check that input files exist
for file in $@; do
	if [ -s $file ]; then
		:
	else
		echo "ERROR: could not open $file"
		exit 1
	fi
done

# check what sorts of input files we've got
case $# in
	0)	echo "ERROR: no input files provided. Minimally, one input file needs to be provided for rating. See $(basename $0) -h or the manual for details." >&2
		exit 1
		;;
	1)	if [ "$(echo "$1" | egrep '\.csv')" ]; then
			# testing if $1 is a db file by looking for fields with first,
			# second, tenth and fourteenth category of the variable allowed_categories
			if [ "$(egrep "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" $1)" ]; then
				echo "ERROR: \"$1\" appears to be a database file. A .csv file for rating also needs to be provided. See $(basename $0) -h"
				exit 1
			fi
			read -t 10 -p '			No database for category lookup was provided. Continue? [Y/n]' d \
			< /dev/tty
			if [ "$(egrep 'N|n' <<< $d)" ]; then
				echo "exiting"
				exit 0
			fi
			echo; echo
			wa_in_filename=$1
			no_db=db
		else
			echo "ERROR: minimally, one input .csv file needs to be provided for rating. See $(basename $0) -h or the manual for details." >&2
			exit 1
		fi
		;;
	2)	# if a .dat and a .csv file are provided
		if [ "$(echo "$@" | egrep '\.csv')" ] && [ "$(echo "$@" | egrep '\.dat')" ]; then
			# if the .csv file is the second one provided
			if [ "$(echo "$2" | egrep '\.csv')" ]; then
				# test if $2 is NOT a db file
				if [ -z "$(egrep "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" $2)" ]; then
					wa_in_filename=$2
				else
					echo "ERROR: \"$2\" appears to be a database file." >&2
					exit 1
				fi
				# test if $1 is a db file
				if [ "$(egrep "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories | sed $extended -e 's/,/  .+|/g' -e 's/^/\.+|/' -e 's/$/  /g')" $1)" ]; then
					db_filename=$1
					db_is_dat=true
				else
					echo "ERROR: \"$1\" does not appear to be a properly formatted .dat file" >&2
					exit 1
				fi
			else
				echo "ERROR: database files need to be provided as the first argument, files to be rated as the second." >&2
				exit 1 	
			fi
		# if two .csv files are provided
		elif [ "$(echo "$@" | egrep -o '\.csv' | wc -l)" -eq 2 ]; then
			# test if $1 is db file
			if [ "$(egrep "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" $1)" ]; then
				grand_db=$1
				db_filename=$1
			else
				echo "ERROR: \"$1\" does not appear to be a database file." >&2
				exit 1
			fi
			# test if $2 is not a db file
			if [ -z "$(egrep "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" $2)" ]; then
				wa_in_filename=$2
			else
				echo "ERROR: \"$2\" appears to be a database file, but should be a file with data to be rated." >&2
				exit 1
			fi
		else
			echo "ERROR: $1 and $2 do not appear to be of the correct format combination or order." >&2
			echo "They should either be two .csv files or a .dat file and a .csv file." >&2
			exit 1
		fi
		;;
	*)	echo "ERROR: more than three input files provided: $@" >&2
		exit 1
		;;
esac




################ create two scratch directories
# first one to keep db sections in
DBSCRATCHDIR=$(mktemp -dt categoriserXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$DBSCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}categoriserXXX.1$$
	DBSCRATCHDIR=${TMPDIR-/tmp/}categoriserXXX.1$$
fi
if [ "$diagnostic" == true ]; then
	open $DBSCRATCHDIR
fi
# second one to keep other auxiliary and temporary files in
SCRATCHDIR=$(mktemp -dt categoriserXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}categoriserXXX.1$$
	SCRATCHDIR=${TMPDIR-/tmp/}categoriserXXX.1$$
fi
if [ "$diagnostic" == true ]; then
	open $SCRATCHDIR
fi

# create name of rated WA output file
add_to_name categorised_$wa_in_filename
categorised_out=$output_filename


################ collecting analyst's ID in the background
(read -p '			Please enter your rater ID (or leave blank) and press ENTER: ' analyst_id  < /dev/tty
if [ "$analyst_id" ]; then
	echo $analyst_id > $SCRATCHDIR/analyst_id
else
	echo "anonymous" > $SCRATCHDIR/analyst_id
fi
# inform user
echo ""
echo ""
echo ""
echo ""
if [ -z "$no_db" ]; then echo "Loading database $db_filename ..."; fi
sleep 1
if [ "$db_is_dat" ]; then
	echo "Detected $(cat $SCRATCHDIR/db_total_cues) cue words ..."
elif [ -z "$no_db" ]; then
	echo "Detected $(cat $SCRATCHDIR/db_total_cues) cue words and $(cat $SCRATCHDIR/db_rows) rows of responses ..."
fi
) &


################# processing database file ###################
# initialise some variables
db_with_ID=
db_with_rater_ID=
db=
respondentIDs=
db_raterIDs=
db_columns=
db_total_cues=
db_rows=
db=

if [ "$db_is_dat" ]; then
##### if db is a .dat file #####	
	# count cues in db
	db_total_cues=$(cat $db_filename | wc -l)
	# db_columns are variable for .dat files, so this is not meaningful
	# db_rows is same as db_total_cues
	
	# write info to file to be retrieved by other processes
	echo $db_total_cues > $SCRATCHDIR/db_total_cues

	# split db into response - category pairs per line in files named after cues
	while read line; do
		file=$(cut -f 1 <<< "$line")
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n')" \
		> $DBSCRATCHDIR/$file
	done < $db_filename

elif [ -z "$no_db" ]; then
##### if db is a .csv file #####
# parse csv db file and 
# - eliminate potential trouble characters
# - replace spaces w/ underscore and ^M with \n and ',' with '|'
# - copy file to SCRATCHDIR
sed $extended -e 's/\|/PIPE/g' -e 's/\"\"//g' -e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' -e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' $db_filename |\
sed -e 's/ /_/g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/(/_LBRACKET_/g' -e 's/)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/+/_PLUS_/g' | tr '\r' '\n' > $SCRATCHDIR/db.csv

# checking if respondent ID is included 
if [ -n "$(head -1 $SCRATCHDIR/db.csv | cut -d '|' -f 1 | grep 'ID')" ]; then
	db_with_ID=true
fi

# count db_columns
db_columns=$(( 1 + $(head -1 $SCRATCHDIR/db.csv | tr -dc '|' | wc -c) ))

# put database in memory and detect and isolate any respondent IDs
if [ "$db_with_ID" ]; then
	# put IDs in variable
	respondentIDs=$(cut -d '|' -f 1 $SCRATCHDIR/db.csv)
	db="$(cut -d '|' -f 2-$db_columns $SCRATCHDIR/db.csv)"
	# count db_rows
	db_rows=$(( $(wc -l <<< "$db") - 1 ))
	# count cues in db
	db_total_cues=$(( ($db_columns / 2) - 1 ))
	# inform user
	echo "respondent IDs detected ..."
else
	db="$(cat $SCRATCHDIR/db.csv)"
	# count db_rows
	db_rows=$(( $(wc -l <<< "$db") - 1 ))
	# count cues in db
	db_total_cues=$(( $db_columns / 2 ))
fi

# write info to files to be retrieved by other processes
echo $db_total_cues > $SCRATCHDIR/db_total_cues
echo $db_rows > $SCRATCHDIR/db_rows

# check if format is consistent
if [ "$(head -1 <<< $db | egrep -o "WA[[:digit:]]+\|[[:upper:]]*[[:lower:]]+\|*" | wc -l)" -ne "$db_total_cues" ]; then
	# let ID entering process finish first
	wait
	echo "WARNING: there appears to be an inconsistency in the first row of \"$db_filename\". It should contain sequences of \"WA000\" (where 000 is any number of digits), followed, in the next field, by a single word indicating the cue (either all lower case or mixed case). Optionally the first field of the first row can contain text that includes the words \"ID\", and the last field of the first row can contain text that includes either the words \"rater ID\". Please check \"$db_filename\" to make certain that it conforms to these specifications and then retry."
	rm -r $SCRATCHDIR $DBSCRATCHDIR &
	exit 1
fi

# check fields were properly separated: each line should contain the same number of field separators. If that is not the case, throw error and exit
while read line; do
	if [ "$(tr -dc '|' <<< $line | wc -c)" -eq "$(( $db_columns - 1 ))" ]; then
		:
	else
		echo "ERROR: field separation inconsistency. There should be exactly $db_columns fields per line. $(tr -dc '|' <<< $line | wc -c) were detected here:
$line" >&2
		rm -r $SCRATCHDIR $DBSCRATCHDIR &
		exit 1
	fi
done <<< "$db"

# make sure the analyst ID has been obtained before proceeding

# split db into response - category pairs
i=1
ii=2
while [ $ii -le $db_columns ]; do
	for line in $(cut -d '|' -f $i-$ii <<< "$db"); do
		tmplist="$tmplist
$line"
	done
	file=$(head -2 <<< "$tmplist" | tail -1 | cut -d '|' -f 2)
	tail -n +3 <<< "$tmplist" | sed $extended -e '/^\|$/d' -e '/^$/d' -e '/\|$/d' | tr '[[:lower:]]' '[[:upper:]]' | sort | uniq | sed "s/$/;legacylist/" > $DBSCRATCHDIR/$file
	tmplist=
	(( i += 2 ))
	(( ii += 2 ))
done
fi # this is the fi from check whether db is dat or csv

# make sure the analyst ID has been obtained before proceeding
wait

################ processing  word-association in-file #########
# initialise some variables
in_rows=
in_cues=
response=
cue=
response_number=
in_with_ID=
in_respondentIDs=
in_wa=
in_columns=
rowcount=-1 # set rowcount to -1 so the first line will be line zero of cues
if [ "$(cat $SCRATCHDIR/analyst_id)" ]; then
	rater_id=";$(cat $SCRATCHDIR/analyst_id)"
fi

# tidy up word-association data in input file
echo -n "analysing $wa_in_filename ... "

# parse word-association data into variables
# we need to insert underscores or any spaces in responses
# and we need to cater for potential empty responses which would
# show as 2 (or more) consecutive commas
# it's also better to replace any potentially confusing special characters
# these things are taken care of as the file is read in
in_wa="$(sed $extended -e 's/\|/PIPE/g' -e 's/\"\"//g' -e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' -e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' -e 's/ /_/g' -e 's/\|\|/\|_\|/g' -e 's/\|\|/\|_\|/g' -e 's/\;//g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/\(/_LBRACKET_/g' -e 's/\)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/\+/_PLUS_/g' $wa_in_filename | tr '\r' '\n')"

# check how many rows in file
in_rows=$(wc -l <<< "$in_wa") 
# count in_columns
in_columns=$(( 1 + $(head -1 <<< "$in_wa" | tr -dc '|' | wc -c) ))
# check fields were properly separated: each line should contain the same number of field separators. If that is not the case, throw error and exit
while read line; do
	if [ "$(tr -dc '|' <<< $line | wc -c)" -ne "$(( $in_columns - 1 ))" ]; then
		echo "ERROR: field separation inconsistency. There should be exactly $db_columns fields per line. $(tr -dc '|' <<< $line | wc -c) were detected here:
$line" >&2
		rm -r $SCRATCHDIR $DBSCRATCHDIR &
		exit 1
	fi
done <<< "$in_wa"

# check if in-file contains respondent IDs
if [ -n "$(head -1 <<< "$in_wa" | cut -d '|' -f 1 | grep 'ID')" ]; then
	in_with_ID=true
	# put IDs in variable
	in_respondentIDs=$(cut -d '|' -f 1 <<< "$in_wa")
	# check if there are non-unique respondent IDs
	if [ "$(sort <<< "$in_respondentIDs" |uniq| wc -l)" -ne "$(wc -l <<< "$in_respondentIDs")" ]; then
		echo "WARNING: non-unique respondent IDs in $wa_in_filename." >&2
	fi
	# take IDs out of $in_wa and reduce in_columns
	in_wa="$(cut -d '|' -f 2-$in_columns <<< "$in_wa")"
	((in_columns-=1))
	echo "respondent IDs detected ..."
fi

# process line-by-line
for line in $in_wa; do
	#echo "this is line: $line"
	(( rowcount += 1 ))
	# from zero line, pick out cues and put them into $in_cues
	if [ $rowcount -eq 0 ]; then
		in_cues=$( sed $extended -e 's/[[:digit:]][[:digit:]]*_DOT_._DOT__([[:alpha:]]*)_––_Your_responses*/\1/g' -e 's/[[:digit:]][[:digit:]]*_DOT_.([[:alpha:]]*)/\1/g' -e 's/\|[^:]+:_/|/g' -e 's/^[^:]+:_//' <<< "$line")
	else
	# for all other lines
		line="$(sed $extended -e 's/^\|/_|/g' -e 's/\|$/|_/g' <<< "$line")"
		for response in $(sed $extended 's/\|/ /g' <<< $line); do
			(( response_number += 1 ))
			cue=$(cut -d '|' -f "$response_number" <<< $in_cues)
			# convert response to upper case
			response=$(tr '[[:lower:]]' '[[:upper:]]' <<< $response)
			# check if in database
			if [ -s $DBSCRATCHDIR/$cue ]; then
				# if cue is in db, check if response in db
				# and save category in variable
				category=$(egrep "^$response\|" $DBSCRATCHDIR/$cue | cut -d '|' -f 2)
				# if category is not empty, write line to output list
				if [ -n "$category" ]; then
					echo "$rowcount:$cue|$response|$category" >> $SCRATCHDIR/$categorised_out
					#echo "$rowcount:$cue,$response,$category"
				else
					manual=true
				fi
			else
				manual=true
			fi
			# deal with empty responses
			if [ -z "$response" ] || [ "$response" == "_" ]; then
					echo "$rowcount:$cue|$response|_;_" >> $SCRATCHDIR/$categorised_out
					manual=
			fi
			# manual processing if necessary
			if [ "$manual" ]; then
				# present standard menu
				standard_menu
				if [ "$category" == "X" ]; then
				# if exiting
					exit_routine
				
				elif [ "$category" == "B" ]; then
				# if going back
					back_menu
					if [ "$old_category" ]; then
					# if old_category is not empty, 
						# modify $previous_pair accordingly
						previous_pair=$(echo "$(cut -d '|' -f 1-2 <<< $previous_pair)|$old_category")
					# if category is empty, leave it empty
					else
						previous_pair=$(echo "$(cut -d '|' -f 1-2 <<< $previous_pair)|")
					fi
					
					# now do current pair
					standard_menu
					if [ "$category" == "X" ]; then
						exit_routine
					fi
				fi
				# if category is not empty, 
				if [ "$category" ]; then
					# write line to current_assignment
					current_assignment=$(echo "$rowcount:$cue|$response|$category")
				# if category is empty, leave empty
				else
					current_assignment=$(echo "$rowcount:$cue|$response|")
				fi
				
				# if there is a previous pair,
				if [ "$previous_pair" ]; then
					# write out previous_pair
					echo "$previous_pair$rater_id" >> $SCRATCHDIR/$categorised_out
					# update db with previous pair's response and cat
					if [ -z "$(egrep '\|$' <<< $previous_pair)" ]; then
					# if the category assigned is not empty
						echo "$(cut -d '|' -f 2-3 <<< $previous_pair)$rater_id" >> $DBSCRATCHDIR/$previous_cue 2> /dev/null
					fi
				fi

				# move current_assignment to previous_pair
				previous_pair="$current_assignment"
				# move cue to previous_cue
				previous_cue="$cue"
				#previous_pair="$rowcount:$cue,$response,$category" 
			
				# routine for periodic saving and informing of progress
				(( ratings_done += 1 ))
				(( counter += 1 ))
				if [ "$counter" -eq 30 ]; then
					clear
					echo
					echo
					echo
					echo
					echo
					echo "           PROGRESS UPDATE"
					echo
					echo
					echo "           $ratings_done manual ratings done"
					echo "           $(cat $SCRATCHDIR/$categorised_out|wc -l|sed $extended -e 's/ //g' -e 's/ //g') responses rated in total (including database lookups)"
					echo
					echo
					echo 
					# reset counter
					counter=0
					# save db to pwd
					echo -n > db.dat.tmp
					for part in $(ls $DBSCRATCHDIR); do 
						echo "$part      $(tr '\n' '     ' < $DBSCRATCHDIR/$part)" >> db.dat.tmp
					done
					read -p '           press ENTER to continue ' a  < /dev/tty
				fi
			fi
			# turn off manual switch
			manual=
			# to put responses into variables named after cues:
			#eval $cue+="$(echo $response | tr '[[:lower:]]' '[[:upper:]]'),"
		done
	fi
	# reset response number
	response_number=0
done < $wa_in_filename

# indicate that this is the final writout
final_writeout=true
echo "Rating of $wa_in_filename is now COMPLETE!"
# writing output file to pwd
exit_routine
# tidy up in the background
rm -r $SCRATCHDIR $DBSCRATCHDIR db.dat.tmp 2> /dev/null &