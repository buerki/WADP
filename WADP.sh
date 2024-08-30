#!/bin/bash -
##############################################################################
# WADP.sh 
copyright="(c) 2015-2024 Cardiff University; Licensed under the EUPL v. 1.2 or later"
####
version="1.1"
# DESCRRIPTION: processes word-association data
################# defining timeout variables
TMOUTSPLASH=3600 # timeout for splash screen of module selection
TMOUT1=10800     # timeout for categorisations in seconds
TMOUT2=60        # timeout for exit questions at the end of categoriser
TMOUT3=600       # timeout for return to main menu after categoriser
# TMOUT=20       # general timeout for read, not active
################# defining functions ###############################
#
#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename $0) processes word-association data
SYNOPSIS:     $(basename $0) [OPTIONS]

OPTIONS:      -d    run in debugging mode
              -h    display this help message
              -V    display version number
              
NOTE:         all other functions are accessed interactively.
"
}
#######################
# define splash function
#######################
splash ( ) {
echo "WADP $copyright"
echo
echo
echo
echo
echo "          WORD ASSOCIATION DATA PROCESSOR"
echo "          version $version"
echo 
echo 
echo
echo
echo "          Please choose a module and press ENTER:"
echo 
echo "          (c)  categoriser"
echo "          (r)  reporter"
echo "          (a)  administrator"
echo "          (x)  exit"
echo
read -t $TMOUTSPLASH -p '           ' module  < /dev/tty
# handle possible timeout
if [ $? == 0 ]; then
	:
else
	echo ""
	echo "the session TIMED OUT, please start a new WADP session."
	module='X'
fi
case $module in
C|c)	echo "loading categoriser module ..."
	run_categoriser
	#read -t $TMOUTSPLASH -p 'Press ENTER to return to the main menu.' resp
	;;
R|r)	echo "loading reporter module ..."
	run_reporter
	read -t $TMOUTSPLASH -p 'Press ENTER to return to the main menu.' resp
	;;
A|a)	echo "loading administrator module ..."
	run_administrator
	read -t $TMOUTSPLASH -p 'Press ENTER to return to the main menu.' resp
	;;
X|x)	echo "This window can now be closed"; exit 0
	;;
*)	echo "$module is not a valid choice."
	sleep 1
	return
	;;
esac
}
#######################
# define run_categoriser function
#######################
run_categoriser ( ) {
printf "\033c"
echo
echo
echo
echo
echo
echo "          Drag the data to be categorised into this window and press ENTER."
echo 
read -rp '           ' infile  < /dev/tty
# get rid of any single quotation marks that might have attached
export infile="$(sed "s/'//g" <<<"$infile")"
# get WSL path if required
if [ "$WSL" ]; then
	infile=$(wslpath -u "$infile")
	if [ "$diagnostic" ]; then
		echo "infile is $infile"
		sleep 3
	fi
fi
if [ -z "$infile" ]; then
	echo "A data file to be categorised must be provided. Please drop the file into this window."
	read -rp '           ' infile  < /dev/tty
	if [ -z "$infile" ]; then
		echo "No data file provided. Exiting." >&2
		return
	fi
	# get WSL path if required
	if [ "$WSL" ]; then
		infile=$(wslpath -u "$infile")
		if [ "$diagnostic" ]; then
		echo "infile is $infile"
		sleep 3
		fi
	fi
fi
# change dir to that of the in-file
export working_dirname="$(dirname "$infile" | sed "s/'//g")"
cd "$working_dirname" 2>/dev/null || dirfail=true
if [ "$diagnostic" ]; then 
	echo "now in $(pwd). dirname is $working_dirname"
	read -p 'press ENTER to continue ' xxx < /dev/tt
fi
printf "\033c"
echo
echo
echo
echo
echo
echo "          If an existing database is to be used, drag it into"
echo "          this window and press ENTER. Otherwise just press ENTER."
echo 
read -rp '           ' database  < /dev/tty
# get rid of single quotation marks
export database="$(sed "s/'//g" <<<"$database")"
# get WSL path if required
if [ "$WSL" ]; then
	# only execute next command if db was provided
	if [ -n "$database" ]; then
		database=$(wslpath "$database")
	fi
	if [ "$diagnostic" ]; then
		echo "database is $database"
		sleep 3
	fi
fi
printf "\033c"
# sort out potential WSL problems
if [ "$WSL" ]; then
	# if it wasn't possible to cd earlier, warn if in -d mode
	if [ "$dirfail" ]; then
		if [ "$diagnostic" ]; then
			echo "cd failed, still in $(pwd)"
			read -p 'press ENTER to continue ' xxx < /dev/tt
		fi
	fi
	# now run categoriser.sh for cygwin
	cd "$working_dirname" || echo "ERROR: could not change dir to $working_dirname"
	if [ "$database" ]; then
		if [ "$diagnostic" ]; then
			echo "categoriser.sh $ratID $database $infile"
			read -p 'press ENTER to continue ' xxx < /dev/tt
		fi
		categoriser -a $ratID "$database" "$infile"
		read -t $TMOUT3 -p 'Press ENTER to return to the main menu.' resp
		# handle possible timeout
		if [ $? == 0 ]; then
			printf "\033c"
			splash
		else
			echo "TIMEOUT"
			echo "any unsaved categorisations were saved in the database (see above for the name of the database)"
			exit 0
		fi
	else
		if [ "$diagnostic" ]; then
			echo "categoriser.sh -a $ratID $infile"
			read -p 'press ENTER to continue ' xxx < /dev/tt
		fi
		categoriser -a $ratID "$infile"
		read -t $TMOUT3 -p 'Press ENTER to return to the main menu.' resp
		# handle possible timeout
		if [ $? == 0 ]; then
			printf "\033c"
			splash
		else
			echo " TIMEOUT"
			echo "any unsaved categorisations were saved in the database (see above for the name of the database)"
			exit 0
		fi
	fi
else # if not running under WSL
	if [ "$database" ]; then
		categoriser -a $ratID "$database" "$infile"
		read -t $TMOUT3 -p 'Press ENTER to return to the main menu.' resp
		# handle possible timeout
		if [ $? == 0 ]; then
			printf "\033c"
			splash
		else
			echo "TIMEOUT"
			echo "any unsaved categorisations were saved in the database (see above for the name of the database)"
			exit 0
		fi
	else
		categoriser -a $ratID "$infile"
		read -t $TMOUT3 -p 'Press ENTER to return to the main menu.' resp
		# handle possible timeout
		if [ $? == 0 ]; then
			printf "\033c"
			splash
		else
			echo "TIMEOUT"
			echo "any unsaved categorisations were saved in the database (see above for the name of the database)"
			exit 0
		fi
	fi
fi
}
#############################################################################
# define categoriser function
#############################################################################
categoriser ( ) (
####
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
   (L)     Lexical set                             (e.g. bean -> vegetable / pea)
   (LCR)   Lexical set & Cue-Response collocation  (e.g. gold -> silver)
   (LRC)   Lexical set & Response-Cue collocation  (e.g. cheese -> bread)
   (OC)    Other Conceptual                        (e.g. fence -> field)
   (OCCR)  Other Conceptual & Cue-Response colloc. (e.g. long -> corridor)
   (OCRC)  Other Conceptual & Response-Cue colloc. (e.g. attack -> knife)
   (RC)    Response-Cue collocation                (e.g. fence -> electric)
   (S)     Synonym                                 (e.g. delay -> impede)
   (SCR)   Synonym & Cue-Response collocation      (e.g. torch -> light)
   (SRC)   Synonym & Response-Cue collocation      (e.g. shove -> push)
   (SS)    Synonym in wider sense (not necessarily (e.g. joint -> unification)
           same part of speech or number)
'
# list of allowed categories
allowed_categories='A,CR,CRRC,E,F,I,L,LCR,LRC,OC,OCCR,OCRC,RC,S,SCR,SRC,SS'
# database matching mode (write "TRUE" after the equal sign to turn one of them on)
approximate_match=
plural_match=
################# end of user-adjustable section
################# defining functions ###############################
# define csv_parser function
############################
csv_parser ( ) {
sed $extended -e 's/\|/PIPE/g' \
-e 's/,\"\"\"/,\" DOUBLEQUOTES /g' -e 's/\"\"\",/ DOUBLEQUOTES \",/g' -e 's/\"\"/ DOUBLEQUOTES /g' \
-e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' \
-e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' -e 's/  / /g' "$1"
}
#######################
# define add_windows_returns function
#######################
add_windows_returns ( ) {
sed "s/$/$(printf '\r')/g" "$1"
}
#######################
# define remove_windows_returns function
#######################
remove_windows_returns ( ) {
sed "s/$(printf '\r')//g" "$1"
}

#######################
# define remove_boms_macOS function
#######################
remove_boms_macOS ( ) {
sed $'s/\xEF\xBB\xBF//' "$1"
}

#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename $0) assigns categories to word-association data
SYNOPSIS:     $(basename $0) [-r] [(DATABASE.dat|DATABASE.csv)] WA-FILE.csv
              Items in square brackets are optional. Order is significant.
OPTIONS:      -a   run as auxiliary script to WADP
              -r   if used, this will result in rater IDs listed in output file
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
if [ "$(grep -E '.csv$' <<<"$1")" ]; then
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
elif [ "$(grep -E '.dat$' <<< "$1")" ]; then
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
		while [ -e "$1"-$count ]
			do
			(( count += 1 ))
			done
	else
		count=
		add=
	fi
	output_filename=$(echo ""$1"$add$count")
fi
}
###################
# standard menu function (displays standard menu)
###################
standard_menu ( ) {
		printf "\033c"
		echo "Please categorise the following pair:"
		echo " "
		echo "		$cue   ->   $(sed -e 's/_DOT_/\./g' -e 's=_SLASH_=/=g' -e "s/_APOSTROPHE_/\'/g" -e 's/_LBRACKET_/(/g' -e 's/_RBRACKET_/)/g' -e 's/_ASTERISK_/\*/g' -e 's/_PLUS_/\+/g' -e 's/DOUBLEQUOTES/\"/g' -e 's/_/ /g'<<< $response)"
		echo " "
		echo "type a choice and press ENTER:"
		echo "$key"
		echo "  (X)     exit (work will be saved)"
		if [ -n "$previous_pair" ]; then
		 echo "  (B)     back to previous pair"
		fi
		echo " "
		read -t $TMOUT1 -p '>>> ' category  < /dev/tty
		# timeout handling
		if [ $? == 0 ]; then
			category=$(tr '[[:lower:]]' '[[:upper:]]' <<< $category)
			echo "You entered: $category"
			sleep 0.4
		else
			echo "TIMEOUT"
			category='X'
		fi
}
###################
# back menu function (displays standard menu)
###################
back_menu ( ) {
		printf "\033c"
		echo "Previously you rated this pair as follows:"
		echo " "
		echo "	$(echo "$previous_pair" | cut -d ':' -f 2 | sed $extended -e 's/\|/   ->   /' -e 's/\|/   /' -e 's/_/ /g')"
		echo " "
		echo "type a fresh choice and press ENTER:"
		echo "$key"
		read -t $TMOUT1 -p '>>> ' old_category  < /dev/tty
		# timeout handling
		if [ $? == 0 ]; then
			old_category=$(tr '[[:lower:]]' '[[:upper:]]' <<< $old_category)
			echo "You entered: $old_category"
			sleep 0.4
		else
			echo "TIMEOUT"
			category='' # no category assigned
		fi

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
	if [ -z "$(grep -E '\|$' <<< $previous_pair)" ]; then
		# if the category assigned is not empty
		echo "$(cut -d '|' -f 2-3 <<< $previous_pair)$rater_id" >> $DBSCRATCHDIR/$previous_cue 2> /dev/null
	fi
fi
### write db file (this is tab delimited with one cue per line)
for part in $(ls $DBSCRATCHDIR); do 
	echo "$part	$(tr '\n' '	' < $DBSCRATCHDIR/$part)" >> $SCRATCHDIR/finished_db.dat
done
# undo any Windows damage
#if [ "$WSL" ]; then
#	conv -U "$SCRATCHDIR/finished_db.dat" 2>/dev/null
#fi
# check if db file is different from previous db file and if NOT, delete new db
if [ "$db_filename" ] && [ -z "$(diff -q $SCRATCHDIR/finished_db.dat "$db_filename")" ]; then
	echo "Database remains unchanged."
	db_nochange=true
else
	# ask if previous db should be updated or not
	if [ "$db_filename" ]; then
		if [ "$db_is_dat" ]; then
			db_filename_only="$(basename "$db_filename")"
			read -t $TMOUT2 -p '     Update database (U) or create new database? (n) ' retain  < /dev/tty
			# handle possible timeout
			if [ $? == 0 ]; then
				:
			else
				echo "timeout"
			fi
			if [ "$retain" == "n" ] || [ "$retain" == "N" ]; then
				if [ $DARWIN ]; then
					add_to_name db-$(date "+%d-%m-%Y_%H.%M.%S").dat
				else
					add_to_name db-$(date "+%d-%m-%Y_%H:%M:%S").dat
				fi
				dboutfilename=$output_filename
				echo "     $db_filename_only left unchanged, new database named $dboutfilename."
			else
				# archive previous state of database in invisible directory
				mkdir .previous_databases 2>/dev/null
				add_to_name .previous_databases/$db_filename_only
				old_db_name="$output_filename"
				mv "$db_filename" "$old_db_name"
				# prepare name for updated db
				dboutfilename="$db_filename_only"
				echo "     Database file \"$dboutfilename\" updated."
			fi
		else
			# if the input db was a csv file
			if [ $DARWIN ]; then
				add_to_name db-$(date "+%d-%m-%Y_%H.%M.%S").dat
			else
				add_to_name db-$(date "+%d-%m-%Y_%H:%M:%S").dat
			fi
			dboutfilename=$output_filename
			echo "     New database file saved as \"$dboutfilename\"."
		fi
	else
		# if we have no input db
		if [ $DARWIN ]; then
			add_to_name db-$(date "+%d-%m-%Y_%H.%M.%S").dat
		else
			add_to_name db-$(date "+%d-%m-%Y_%H:%M:%S").dat
		fi
		dboutfilename=$output_filename
		echo "     New database file saved as \"$dboutfilename\"."
	fi
	# make doubly sure nothing is overwritten
	add_to_name $dboutfilename
	dboutfilename=$output_filename
	cp $SCRATCHDIR/finished_db.dat $dboutfilename
	echo $dboutfilename > $SCRATCHDIR/autosavedbname
fi
### check if out-file is required
if [ -z "$final_writeout" ]; then
	echo "The rating is not complete, yet."
	read -t $TMOUT2 -p 'Output list for the part that is complete? (Y/n)' req_out < /dev/tty
	# handle possible timeout
	if [ $? == 0 ]; then
		:
	else
		echo "timeout"
	fi
	if [ "$req_out" == "n" ] || [ "$req_out" == "N" ]; then
		if [ "$db_nochange" ]; then
			:
		else
			echo "updated database file only..."
			sleep 0.5
		fi
	else
		write_inout
		echo "Output written to \"$categorised_out\""
	fi
else
	write_inout
	echo "Output written to \"$categorised_out\""
fi
### tidy up
rm db.dat.tmp 2> /dev/null &
rm -r $SCRATCHDIR $DBSCRATCHDIR 2> /dev/null &
### ask if dir should be opened
read -t $TMOUT2 -p 'Would you like to open the output directory? (Y/n)' a  < /dev/tty
# handle possible timeout
if [ $? == 0 ]; then
	:
else
	echo "timeout"
fi
if [ "$a" == "y" ] || [ "$a" == "Y" ] || [ -z "$a" ]; then
	if [ "$(grep 'Microsoft' <<< $platform)" ]; then
		explorer.exe `wslpath -w "$PWD"`
	elif [ "$(grep 'Darwin' <<< $platform)" ]; then
		open .
	else
		xdg-open .
	fi
fi
}
###################
# write inout function; writes the wa input file out with assigned categories
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
	sed $extended -e 's/^/\"/' -e 's/\|$/\"/g' -e 's/\|/\",\"/g' <<< "$in_header_out" > "$categorised_out"
	# correct erroneous newline characters in Windows
	if [ "$WSL" ]; then
		#conv -U "$categorised_out" 2>/dev/null
		tr '\n' '*' < "$categorised_out" | sed 's/*//g' > "$categorised_out."
		echo "" >> "$categorised_out."
		mv "$categorised_out." "$categorised_out"
		#conv -U "$categorised_out" 2>/dev/null
	fi
	if [ "$diagnostic" ]; then
		echo "header is: "$in_header_out""
	fi
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
	sed $extended -e 's/^/\"/' -e 's/\|$/\"/g' -e 's/\|/\",\"/g' <<< "$in_header_out" > "$categorised_out"
	if [ "$WSL" ]; then
		#conv -U "$categorised_out" 2>/dev/null
		tr '\n' '*' < "$categorised_out" | sed 's/*//g' > "$categorised_out."
		echo "" >> "$categorised_out."
		mv "$categorised_out." "$categorised_out"
		#conv -U "$categorised_out" 2>/dev/null
	fi
	if [ "$diagnostic" ]; then
		echo "header is: "$in_header_out""
	fi
fi
# write rows
if [ -e $SCRATCHDIR/$categorised_out ]; then
if [ "$in_with_ID" ]; then
	for ID in $(tail -n +2 <<< "$in_respondentIDs"); do
		(( row += 1 ))
		# assemble row in variable out_row
		# first get ID
		out_row="$ID|"
		# now get pairs for that row (it needs to check if row is complete and only prints complete rows)
		# This is because header and rows could possibly be out of alignment in the case of incomplete rows, though because
		# headers and rows have responses in alphabetical order, and ratings are also gone through in alphabetical order
		# by response, it seems to hold up. Nevertheless, for the moment, partial rows are not printed unless -d option active, see below
		responses_in_this_row="$(grep -E "^$row:" $SCRATCHDIR/$categorised_out | sort | cut -d '|' -f 2-3)"
		if [ "$output_raterIDs" ]; then
			responses_in_this_row="$(sed 's/;/\",\"/' <<< "$responses_in_this_row")"
		else
			responses_in_this_row="$(cut -d ';' -f 1 <<< "$responses_in_this_row")"
		fi
		if [ "$(wc -l <<< "$responses_in_this_row")" -eq "$in_columns" ]; then
		# if we have a complete row, write it out
			out_row+="$(tr '\n' '|' <<< "$responses_in_this_row")"
			write_neatly >> "$categorised_out"
		else
			if [ $diagnostic ]; then
			# this is for outputting partial rows of categorised responses. This feature is experimental
				if [ "$(wc -l <<< "$responses_in_this_row")" -gt 1 ]; then
					echo "incomplete row added to output"
					out_row+="$(tr '\n' '|' <<< "$responses_in_this_row")"
					write_neatly | sed 's/$/,NB: this row is not yet complete; the remainder will be output once categorisation for this row is complete. Output of incomplete rows is an experimental feature. Only the output of completed rows has been fully tested./' >> "$categorised_out"
				else
					echo "\"$(sed 's/_/ /g' <<< $ID)\",\"NB: this row is not yet complete; once the categories for the complete row have been assigned, they will be output. The categorisations were saved in the database.\"" >> "$categorised_out"
				fi
			else
				echo "\"$(sed 's/_/ /g' <<< $ID)\",\"NB: this row is not yet complete; once the categories for the complete row have been assigned, they will be output. The categorisations were saved in the database.\"" >> "$categorised_out"
			fi
		fi
		# clear variable for next row
		out_row=
		# undo any damage by cygwin
		#if [ "$WSL" ]; then
		#	conv -U "$categorised_out" 2>/dev/null
		#fi
	done
else
	for n in $(eval echo {1..$(( $in_rows - 1 ))}); do
		(( row += 1 ))
		# assemble row in variable out_row (it needs to check if row is complete and only prints complete rows)
		# This is because header and rows could possibly be out of alignment in the case of incomplete rows, though because
		# headers and rows have responses in alphabetical order, and ratings are also gone through in alphabetical order
		# by response, it seems to hold up. Nevertheless, for the moment, partial rows are not printed unless -d option active, see below
		responses_in_this_row="$(grep -E "^$row:" $SCRATCHDIR/$categorised_out | sort | cut -d '|' -f 2-3)"
		if [ "$output_raterIDs" ]; then
			responses_in_this_row="$(sed 's/;/\",\"/' <<< "$responses_in_this_row")"
		else
			responses_in_this_row="$(cut -d ';' -f 1 <<< "$responses_in_this_row")"
		fi
		#echo "responses_in_this_row: $(wc -l <<< "$responses_in_this_row") of $in_columns"
		if [ "$(wc -l <<< "$responses_in_this_row")" -eq "$in_columns" ]; then
		# if we have a complete row, write it out
			out_row+="$(tr '\n' '|' <<< "$responses_in_this_row")"
			write_neatly >> "$categorised_out"
		else
			if [ $diagnostic ]; then
			# this is for outputting partial rows of categorised responses. This feature is experimental
				if [ "$(wc -l <<< "$responses_in_this_row")" -gt 1 ]; then
					echo "incomplete row added to output"
					out_row+="$(tr '\n' '|' <<< "$responses_in_this_row")"
					write_neatly | sed 's/$/,NB: this row is not yet complete; the remainder will be output once categorisation for this row is complete. Output of incomplete rows is an experimental feature. Only the output of completed rows has been fully tested./' >> "$categorised_out"
				else
					echo "\"NB: this row is not yet complete; once the categories for the complete row have been assigned, they will be output. The categorisations were saved in the database.\"" >> "$categorised_out"
				fi
			else
				echo "\"NB: this row is not yet complete; once the categories for the complete row have been assigned, they will be output. The categorisations were saved in the database.\"" >> "$categorised_out"
			fi
		fi
		# clear variable for next row
		out_row=
	done
fi
else # this is the else for checking if SCRATCHDIR/categorised_out exists
	echo "$categorised_out will only contain a header because of the small number of ratings performed."
	echo "This output file only contains a header because no categorisations have been recorded. Once categorisations have been recorded, they will be printed in future output files." >> "$categorised_out"
	sleep 1
	if [ $diagostic ]; then
				echo "looking at $row in $SCRATCHDIR/$categorised_out..."
				grep -E "^$row:" $SCRATCHDIR/$categorised_out
				read -p '           press ENTER to continue ' a  < /dev/tty
	fi
fi
}
###################
# write neatly function (write categorised_out file; func used by write_inout)
###################
write_neatly ( ) {
sed $extended -e 's/^/\"/' -e 's/\|$/\"/g' -e 's/\|/\",\"/g' -e 's/\–/-/g' -e 's/_DOT_/\./g' -e 's=_SLASH_=/=g' -e "s/_APOSTROPHE_/\'/g" -e 's/_LBRACKET_/(/g' -e 's/_RBRACKET_/)/g' -e 's/_ASTERISK_/\*/g' -e 's/_PLUS_/\+/g' -e 's/_/ /g' -e 's/DOUBLEQUOTES/\"\"/g' <<< $out_row
}
################## end defining functions ########################
# initialise some variables
extended="-r"
# check what platform we're under
platform=$(uname -v)
# and make adjustments accordingly
if [ "$(grep 'Microsoft' <<< $platform)" ]; then
	WSL=true
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
	DARWIN=true
else
	LINUX=true
fi
# analyse options
local OPTIND ahrvV opt # making sure the options are only for this script, leaving out -d as that can be global
while getopts adhrvV opt
do
	case $opt	in
	a)	auxiliary=true
		;;
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
		echo "$copyright"
		exit 0
		;;
	esac
done
shift $((OPTIND -1))
# set terminal window
printf '\e[8;33;83t'
if [ "$auxiliary" ]; then
	printf "\033c"
	echo "          CATEGORISER MODULE"
	echo
	echo
	echo
	echo
else
# splash screen
printf "\033c"
echo "Word Association Data Processor - $copyright"
echo
echo
echo
echo
echo
echo "          WORD ASSOCIATION DATA CATEGORISER"
echo "          version $version"
echo 
echo 
echo 
echo 
echo 
echo 
echo 
fi
################ checks on input files
# initialise some variables
grand_db=
db_filename=
wa_in_filename=
db_is_dat=
# check what sorts of input files we have got and check if they exist
case $# in
	0)	echo "ERROR: no input files provided. Minimally, one input file needs to be provided for rating. See $(basename "$0") -h or the manual for details." >&2
		exit 1
		;;
	1)	if [ -s "$1" ]; then
			# remove any Windows returns
			remove_windows_returns "$1" > "$1.corr"
			remove_boms_macOS "$1.corr" > "$1"
			rm "$1.corr"
		else
			echo "ERROR: could not open $1" >&2
			exit 1
		fi
		if [ "$(grep -E '\.csv$' <<<"$1" 2>/dev/null)" ]; then
			# testing if $1 is a db file by looking for fields with first,
			# second, tenth and fourteenth category of the variable allowed_categories
			if [ "$(grep -E "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" "$1")" ]; then
				echo "ERROR: \"$1\" appears to be a database file. A .csv file for rating also needs to be provided."
				exit 1
			fi
			read -p '          No database for category lookup was provided. Continue? (Y/n)' d \
			< /dev/tty
			if [ "$(grep -E 'N|n' <<< $d)" ]; then
				echo "exiting"
				exit 0
			fi
			echo; echo
			wa_in_filename="$1"
			no_db=db
		else
			echo "ERROR: minimally, one input .csv file needs to be provided for rating. See the manual for details." >&2
			exit 1
		fi
		;;
	2)	if [ -s "$1" ] && [ -s "$2" ]; then
			# remove any Windows returns
			remove_windows_returns "$1" > "$1.corr"
			remove_boms_macOS "$1.corr" > "$1"
			rm "$1.corr"
			remove_windows_returns "$2" > "$2.corr"
			remove_boms_macOS "$2.corr" > "$2"
			rm "$2.corr"
		else
			echo "ERROR: could not access file(s) $1 and/or $2" >&2
			exit 1
		fi
		# if a .dat and a .csv file are provided
		if [ "$(grep -E '\.csv' <<<"$2")" ] && [ "$(grep -E '\.dat' <<<"$1")" ]; then
				# test if $2 is NOT a db file
				if [ -z "$(grep -E "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" "$2")" ]; then
					wa_in_filename="$2"
				else
					echo "ERROR: \"$2\" appears to be a database file." >&2
					exit 1
				fi
				# test if $1 is a db file
				if [ "$(grep -E "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories | sed $extended -e 's/,/  .+|/g' -e 's/^/\.+|/' -e 's/$/  /g')" "$1")" ]; then
					db_filename="$1"
					db_is_dat=true
				else
					echo "ERROR: \"$1\" does not appear to be a properly formatted .dat file" >&2
					exit 1
				fi
		# if two .csv files are provided
		elif [ "$(grep -E '\.csv'<<<"$1")" ] &&  [ "$(grep -E '\.csv'<<<"$2")" ]; then
			# test if $1 is db file
			if [ "$(grep -E "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" "$1")" ]; then
				grand_db="$1"
				db_filename="$1"
			else
				echo "ERROR: \"$1\" does not appear to be a database file." >&2
				exit 1
			fi
			# test if $2 is not a db file
			if [ -z "$(grep -E "$(cut -d ',' -f 1,2,10,14 <<< $allowed_categories| sed $extended -e 's/,/,|,/g' -e 's/^/,/' -e 's/$/,/g' )" "$2")" ]; then
				wa_in_filename="$2"
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
# check if infile might already be categorised
if [ $(head -1 "$wa_in_filename" | grep -o 'category' | wc -l) -gt 1 ]; then
	echo "$wa_in_filename appears to be rated already. Please choose a data file which has not yet been rated." >&2
	exit 1
elif [ "$(grep 'categorised_' <<<"$wa_in_filename")" ]; then
	read -p "$wa_in_filename looks as though it has already been rated. Are you sure you wish to continue? (y/N)" sure < /dev/tt
	if [ "$sure" == "y" ] || [ "$sure" == "Y" ]; then
		:
	else
		exit 1
	fi
fi
################ create two scratch directories
# first one to keep db sections in
DBSCRATCHDIR=$(mktemp -dt categoriserXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$DBSCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}categoriserXXX.1$$
	DBSCRATCHDIR=${TMPDIR-/tmp/}categoriserXXX.1$$
fi
if [ "$diagnostic" == true ]; then
	open $DBSCRATCHDIR 2> /dev/null || xdg-open $DBSCRATCHDIR 2> /dev/null || explorer.exe `wslpath -w "$DBSCRATCHDIR"`
fi
# second one to keep other auxiliary and temporary files in
SCRATCHDIR=$(mktemp -dt categoriserXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}categoriserXXX.1$$
	SCRATCHDIR=${TMPDIR-/tmp/}categoriserXXX.1$$
fi
if [ "$diagnostic" == true ]; then
	open $SCRATCHDIR 2> /dev/null || xdg-open $SCRATCHDIR 2> /dev/null || explorer.exe `wslpath -w "$SCRATCHDIR"`
fi
# create name of rated WA output file
wa_in_filename_only="$(basename "$wa_in_filename")"
add_to_name "categorised_$wa_in_filename_only"
categorised_out="$output_filename"
################ collecting analyst's ID in the background
(read -p 'Please type your rater ID (or leave blank) and press ENTER: ' analyst_id  < /dev/tty
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
	db_total_cues=$(cat "$db_filename" | wc -l)
	# db_columns are variable for .dat files, so this is not meaningful
	# db_rows is same as db_total_cues
	# write info to file to be retrieved by other processes
	echo $db_total_cues > $SCRATCHDIR/db_total_cues
	# split db into response - category pairs per line in files named after cues
	while read line; do
		file=$(cut -f 1 <<< "$line")
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n')" \
		> $DBSCRATCHDIR/$file
	done < "$db_filename"
elif [ -z "$no_db" ]; then
##### if db is a .csv file #####
# parse csv db file and 
# - eliminate potential trouble characters
# - replace spaces w/ underscore and ^M with \n and ',' with '|'
# - copy file to SCRATCHDIR
csv_parser "$db_filename" |\
sed $extended -e 's/ /_/g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/(/_LBRACKET_/g' -e 's/)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/+/_PLUS_/g' | tr '\r' '\n' > $SCRATCHDIR/db.csv
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
if [ "$(head -1 <<< "$db" | grep -E -o "WA[[:digit:]]+\|[[:upper:]]*[[:lower:]]+\|*" | wc -l)" -ne "$db_total_cues" ]; then
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
# first remove any spaces at beginnings or ends of responses
# we need to insert underscores for any spaces in responses
# and we need to cater for potential empty responses which would
# show as 2 (or more) consecutive commas
# it is also better to replace any potentially confusing special characters
# these things are taken care of as the file is read in
# -e 's/, /,/g' was removed from the below to allow spaces after a literal comma
in_wa="$(csv_parser "$wa_in_filename" | sed $extended -e 's/ ,/,/g' -e 's/ /_/g' -e 's/\|_/\|/g' -e 's/_\|/\|/g' -e 's/\|\|/\|_\|/g' -e 's/\|\|/\|_\|/g' -e 's/\;//g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/\(/_LBRACKET_/g' -e 's/\)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/\+/_PLUS_/g' | tr '\r' '\n')"
# check how many rows in file
in_rows=$(wc -l <<< "$in_wa") 
# count in_columns
in_columns=$(( 1 + $(head -1 <<< "$in_wa" | tr -dc '|' | wc -c) ))
# check fields were properly separated: each line should contain the same number of field separators. If that is not the case, throw error and exit
while read line; do
	if [ "$(tr -dc '|' <<< $line | wc -c)" -ne "$(( $in_columns - 1 ))" ]; then
		echo "ERROR: field separation inconsistency. There should be exactly $in_columns fields per line. $(tr -dc '|' <<< $line | wc -c) were detected here:
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
# estimate number of responses to be rated
est_n_responses=$(( ($in_rows -1 ) * $in_columns ))
echo "An estimated $est_n_responses to be rated."
if [ "$db_is_dat" ]; then 
	echo "A portion of these ratings is likely to be read directly from the database provided."
fi
sleep 3
# process line-by-line
for line in $in_wa; do
	#echo "this is line: $line"
	(( rowcount += 1 ))
	# from zero line, pick out cues and put them into $in_cues
	if [ $rowcount -eq 0 ]; then
		in_cues=$( sed $extended -e 's/[[:digit:]][[:digit:]]*_DOT_._DOT__([[:alpha:]]*)_–+_Your_responses*/\1/g' -e 's/[[:digit:]][[:digit:]]*_DOT_([[:alpha:]]*)/\1/g' -e 's/\|[^:]+:_/|/g' -e 's/^[^:]+:_//' <<< "$line")
		in_cues=$(sed -e 's/^_//g' -e 's/|_/|/g' <<< $in_cues)
	else
	# for all other lines
		line="$(sed $extended -e 's/^\|/_|/g' -e 's/\|$/|_/g' <<< "$line")"
		for response in $(sed $extended 's/\|/ /g' <<< $line); do
			(( response_number += 1 ))
			cue=$(cut -d '|' -f "$response_number" <<< $in_cues)
			# convert response to upper case (all capitals)
			response=$(tr '[[:lower:]]' '[[:upper:]]' <<< $response | sed 's/ //g')
			# check if in database
			if [ -s $DBSCRATCHDIR/$cue ]; then
				# if cue is in db, check if response in db
				# and save category in variable
				if [ "$approximate_match" ]; then
					category=$(grep -E "^$response.?\|" $DBSCRATCHDIR/$cue | cut -d '|' -f 2)
				elif [ "$plural_match" ]; then
					category=$(grep -E "^($response)S?\|" $DBSCRATCHDIR/$cue | cut -d '|' -f 2)
				else
					category=$(grep -E "^$response\|" $DBSCRATCHDIR/$cue | cut -d '|' -f 2)
				fi
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
				if [ "$category" == "X" ] || [ "$category" == "x" ]; then
				# if exiting
					exit_routine
					exit 0
				elif [ "$category" == "B" ] || [ "$category" == "b" ]; then
				# if going back
					back_menu
					if [ "$old_category" ]; then
					# if old_category is not empty,
						# check it's not 'b'
						if [ "$old_category" == "B" ]; then
							echo "You have entered '$old_category', but going further back is not an available option."
							read -p 'Please enter a different value >>> ' old_category  < /dev/tty
							old_category=$(tr '[[:lower:]]' '[[:upper:]]' <<< $old_category)
							echo "You entered: $old_category"
						fi
						# modify $previous_pair accordingly
						previous_pair=$(echo "$(cut -d '|' -f 1-2 <<< $previous_pair)|$old_category")
					# if category is empty, leave it empty
					else
						previous_pair=$(echo "$(cut -d '|' -f 1-2 <<< $previous_pair)|")
					fi
					# now do current pair
					standard_menu
					if [ "$category" == "X" ] || [ "$category" == "x" ]; then
						exit_routine
					elif [ "$category" == "B" ] || [ "$category" == "b" ]; then
						echo "You have entered '$category', but the back option is not available."
						read -p 'Please try again here >>> ' category  < /dev/tty
						category=$(tr '[[:lower:]]' '[[:upper:]]' <<< $category)
						echo "You entered: $category"
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
					if [ -z "$(grep -E '\|$' <<< $previous_pair)" ]; then
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
					printf "\033c"
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
					echo "           out of an estimated $est_n_responses."
					echo
					echo
					echo 
					# reset counter
					counter=0
					# save db to pwd
					echo -n > db.dat.tmp
					for part in $(ls $DBSCRATCHDIR); do 
						#echo "$part      $(tr '\n' '     ' < $DBSCRATCHDIR/$part)" >> db.dat.tmp
						echo "$part	$(tr '\n' '	' < $DBSCRATCHDIR/$part)" >> db.dat.tmp
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
done < "$wa_in_filename"
# indicate that this is the final writout
final_writeout=true
echo "Rating of $wa_in_filename_only is now COMPLETE!"
# writing output file to pwd
exit_routine
# tidy up in the background
rm -r $SCRATCHDIR $DBSCRATCHDIR db.dat.tmp 2> /dev/null &
)
#######################
# define run_reporter function
#######################
run_reporter ( ) {
printf "\033c"
echo 
echo 
echo 
echo 
echo 
echo 
echo 
echo "          Please enter required report type(s) and press ENTER"
echo "          (I)   individual response profiles"
echo "          (C)   cue profiles"
echo "          (P)   primary responses"
echo "          (R)   inter-rater agreement"
echo "          (A)   all of the above"
# echo "          (S)   stereotypy rating"
read -p '          ' report_types < /dev/tty
case $report_types in
	I|i)	export by_respondent=true
		;;
	C|c)	export by_cue=true
		;;
	IC|ic)	export by_respondent=true
			export by_cue=true
		;;
	P|p)	export primary_resp=true
		;;
	ICP|icp)	export by_respondent=true
			export by_cue=true
			export primary_resp=true
		;;
	IP|ip)	export by_respondent=true
			export primary_resp=true
		;;
	CP|cp)	export by_cue=true
			export primary_resp=true
		;;
	R|r)	export inter_rater=true
		;;
	ICR|icr)	export by_respondent=true
				export by_cue=true
				export inter_rater=true
		;;
	A|a)	export by_respondent=true
			export by_cue=true
			export primary_resp=true
			export inter_rater=true
		;;
	*)		echo "$report_types is not a valid option."
			read -p 'Please try again, typing only one letter this time' report_types < /dev/tty
			case $report_types in
				I|i)	export by_respondent=true
					;;
				C|c)	export by_cue=true
					;;
				P|p)	export primary_resp=true
					;;
				R|r)	export inter_rater=true
					;;
				A|a)	export by_respondent=true
						export by_cue=true
						export primary_resp=true
						export inter_rater=true
					;;
				*)	echo "$report_types is not a valid option. Exiting."
					exit 1		
			esac
esac
printf "\033c"
echo
echo
echo
echo
echo
echo "          Drag the data file to report on into this window and press ENTER."
echo 
read -rp '           ' infile  < /dev/tty
# get rid of any single quotation marks that might have attached
export infile="$(sed "s/'//g" <<<"$infile")"
# get WSL path if required
if [ "$WSL" ]; then
	# only execute next command if file was provided
	if [ -n "$infile" ]; then
		infile=$(wslpath "$infile")
	fi
fi
if [ -z "$infile" ]; then
	echo "A data file must be provided. Please drop the file into this window."
	read -rp '           ' infile  < /dev/tty
	# get WSL path if required
	if [ "$WSL" ]; then
		# only execute next command if file was provided
		if [ -n "$infile" ]; then
			infile=$(wslpath "$infile")
		fi
	fi
	if [ -z "$infile" ]; then
		echo "No data file provided. Exiting." >&2
		return
	fi
fi
# change dir to that of the in-file
export working_dirname="$(dirname "$infile" | sed "s/'//g")"
cd "$working_dirname" 2>/dev/null || dirfail=true
# call reporter function
reporter -a "$infile"
# reset option variables
export by_respondent=
export by_cue=
export primary_resp=
export inter_rater=
}
###############################################################################
# define reporter function
###############################################################################
reporter ( ) (
###############################################################################
# reporter.sh
# DESCRRIPTION: creates reports for word-association data
################# defining functions ###############################
# define csv_parser function
############################
csv_parser ( ) {
sed $extended -e 's/\|/PIPE/g' \
-e 's/,\"\"\"/,\" DOUBLEQUOTES /g' -e 's/\"\"\",/ DOUBLEQUOTES \",/g' -e 's/\"\"/ DOUBLEQUOTES /g' \
-e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' \
-e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' -e 's/  / /g' "$1"
}
#csv_parser ( ) {
#sed $extended -e 's/\|/PIPE/g' -e 's/\"\"//g' -e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' -e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' "$1"
#}
#######################
# define add_windows_returns function
#######################
add_windows_returns ( ) {
sed "s/$/$(printf '\r')/g" "$1"
}
#######################
# define remove_windows_returns function
#######################
remove_windows_returns ( ) {
sed "s/$(printf '\r')//g" "$1"
}
#######################
# define remove_boms_macOS function
#######################
remove_boms_macOS ( ) {
sed $'s/\xEF\xBB\xBF//' "$1"
}
 
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
if [ "$diagnostic" ]; then
	echo "arrived in reporter function."
fi
# initialise some variables
extended="-r"
# check what platform we're under
platform=$(uname -v)
# and make adjustments accordingly
if [ "$(grep 'Microsoft' <<< $platform)" ]; then
	WSL=true
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
	DARWIN=true
else
	LINUX=true
fi
# analyse options
if [ "$diagnostic" ]; then
	echo "$@"
fi
local OPTIND ahvV opt # to make sure options are only for this function; leaving out -d which is global
while getopts adhvV opt
do
	case $opt	in
	a)	auxiliary=true
		if [ "$diagnostic" ]; then echo "auxiliary mode"; fi
		;;
	d)	diagnostic=true
		;;
	h)	help
		exit 0
		;;
	v)	verbose=true
		;;
	V)	echo "$(basename "$0")	-	version $version"
		echo "$copyright"
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
# check that input file exists and remove Windows returns
if [ -s "$1" ]; then
		remove_windows_returns "$1" > "$1.corr"
		remove_boms_macOS "$1.corr" > "$1"
		rm "$1.corr"
else
	echo "ERROR: could not open $file"
	exit 1
fi

# check what sorts of input files we've got
case $# in
	0)	echo "ERROR: no input files provided. Minimally, one input file needs to be provided to create a report. See the manual for details." >&2
		exit 1
		;;
	1)	if [ "$(echo "$1" | grep -E '\.csv')" ]; then
			# testing format by checking whether there is a 'category' field in
			# the header
			if [ -z "$(head -1 "$1" | grep -E ',\"*category\"*')" ]; then
				noncategorised=true
				echo "noncategorised data detected in $file."
				echo "producing primary response report..."
				primary_resp=true
			fi
			in_filename="$1"
		fi
		;;
	*)	echo "ERROR: $(basename "$0") only deals with one input list at a time."
		exit 1
		;;
esac
if [ "$auxiliary" ] || [ $noncategorised ]; then
	printf "\033c"
	echo
	echo
	echo
	echo
	echo
else
############## splash screen
printf "\033c"
echo "Word Association Data Processor - $copyright"
echo
echo
echo
echo
echo
echo "          WORD ASSOCIATION DATA REPORTER"
echo "          version $version"
fi
if [ $noncategorised ] || [ "$auxiliary" ]; then
	:
else
echo 
echo 
echo 
echo 
echo 
echo 
echo 
echo "          Please enter required report type(s) and press ENTER"
echo "          (I)   individual response profiles"
echo "          (C)   cue profiles"
echo "          (P)   primary responses"
echo "          (R)   inter-rater agreement"
echo "          (A)   all of the above"
# echo "          (S)   stereotypy rating"
read -p '          ' report_types < /dev/tty
case $report_types in
	I|i)	by_respondent=true
		;;
	C|c)	by_cue=true
		;;
	IC|ic)	by_respondent=true
			by_cue=true
		;;
	P|p)	primary_resp=true
		;;
	ICP|icp)	by_respondent=true
			by_cue=true
			primary_resp=true
		;;
	IP|ip)	by_respondent=true
			primary_resp=true
		;;
	CP|cp)	by_cue=true
			primary_resp=true
		;;
	R|r)	inter_rater=true
		;;
	ICR|icr)	by_respondent=true
				by_cue=true
				inter_rater=true
		;;
	A|a)	by_respondent=true
			by_cue=true
			primary_resp=true
			inter_rater=true
		;;
	*)		echo "$report_types is not a valid option."
			read -p 'Please try again, typing only one letter this time' report_types < /dev/tty
			case $report_types in
				I|i)	by_respondent=true
					;;
				C|c)	by_cue=true
					;;
				P|p)	primary_resp=true
					;;
				R|r)	inter_rater=true
					;;
				A|a)	by_respondent=true
						by_cue=true
						primary_resp=true
						inter_rater=true
					;;
				*)	echo "$report_types is not a valid option. Exiting."
					exit 1		
			esac
esac
printf "\033c"
fi
################ create three scratch directories
# first one to keep db sections in
RSCRATCHDIR=$(mktemp -dt reporterXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$RSCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}reporterXXX.1$$
	RSCRATCHDIR=${TMPDIR-/tmp/}reporterXXX.1$$
fi
if [ "$diagnostic" ]; then
	echo "opening scratchdirs"
	if [ "$WSL" ]; then
		explorer.exe `wslpath -w "$RSCRATCHDIR"`
	elif [ "$DARWIN" ]; then
		open "$RSCRATCHDIR"
	else
		xdg-open "$RSCRATCHDIR"
	fi
fi
# second one to keep other auxiliary and temporary files in
SCRATCHDIR=$(mktemp -dt reporterXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}reporterXXX.1$$
	SCRATCHDIR=${TMPDIR-/tmp/}reporterXXX.1$$
fi
if [ "$diagnostic" ]; then
	if [ "$WSL" ]; then
		explorer.exe `wslpath -w "$SCRATCHDIR"`
	elif [ "$DARWIN" ]; then
		open "$SCRATCHDIR"
	else
		xdg-open "$SCRATCHDIR"
	fi
fi
# third one to keep more auxiliary and temporary files in
SCRATCHDIR3=$(mktemp -dt reporterXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR3" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}reporterXXX.1$$
	SCRATCHDIR3=${TMPDIR-/tmp/}reporterXXX.1$$
fi
if [ "$diagnostic" ]; then
	if [ "$WSL" ]; then
		explorer.exe `wslpath -w "$SCRATCHDIR3"`
	elif [ "$DARWIN" ]; then
		open "$SCRATCHDIR3"
	else
		xdg-open "$SCRATCHDIR3"
	fi
fi
################ processing in-file #########
# initialise some variables
in_rows= # total rows in file
cues= # list of all cues in the file
no_of_cues= # number of cues
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
cue_columns= # holds numbers indicating the columns that contain cues (if header) or responses
in_categories= # holds the category columns of in-file

# read input file
echo -n "analysing $in_filename ..."
# create filename only
in_filename_only="$(basename "$in_filename")"
# make sure it's the right format if in cygwin
#if [ "$WSL" ]; then
#	conv -U "$in_filename" 2>/dev/null
#fi

# parse data into variables
# we need to insert underscores in place of any spaces in responses
# and we need to cater for potential empty responses which would
# show as 2 (or more) consecutive commas
# it's also better to replace any potentially confusing special characters
# these things are taken care of as the file is read in
in_wa="$(csv_parser "$in_filename" | sed $extended -e 's/ /_/g' -e 's/\|\|/\|_\|/g' -e 's/\|\|/\|_\|/g' -e 's/\;//g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/\(/_LBRACKET_/g' -e 's/\)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/\+/_PLUS_/g' | tr '\r' '\n')"
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
	if [ "$WSL" ]; then
		in_respondentIDs="$(echo $in_respondentIDs | tr '\n' ' ')"
	fi
	# check if there are non-unique respondent IDs
	if [ "$(sort -d <<< "$in_respondentIDs" |uniq| wc -l)" -ne "$(wc -l <<< "$in_respondentIDs")" ]; then
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

# unless non-categorised, identify 'category' columns
if [ -z "$noncategorised" ]; then
	for field in $(sed $extended 's/\|/ /g' <<< "$in_header"); do
		(( field_no += 1 ))
		if [ "$(grep -E '^category$' <<< "$field")" ]; then
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
	last_cat_column="$(grep -E -o '[[:digit:]]+$' <<< "$cat_columns")"
	if [ "$last_cat_column" -lt $(( $in_columns - 1 )) ]; then
		# if last category column is not the last or penultimate column of the file	
		echo "ERROR: the last or penultimate column of $in_filename_only should be a category column."
		echo "However, the two final colums are: $(grep -E -o '\|[^\|]+\|[^\|]+$' <<< "$in_header" | sed $extended -e 's/\|/ /g' -e 's/ /, /2')"
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
		echo ""
		echo "cat_columns are: $cat_columns"
		read -p 'Press ENTER to continue' a  < /dev/tty
	fi
	# derive cue column numbers
	for num in $cat_columns; do
		cue_columns+=" $(( $num - 1 ))"
	done
else
	cue_columns=$(eval echo {1..$in_columns})
fi
# pick out cues from header
cues="$(cut -d '|' -f $(sed -e 's/^ //' -e 's/ /,/g' <<< $cue_columns) <<< "$in_header")"
no_of_cues=$(( $( tr -dc ' ' <<< $cue_columns | wc -c) + 1 ))
# adjust cue count for Linux
if [ "$WSL" ] || [ "$LINUX" ]; then
	(( no_of_cues -= 1 ))
fi
if [ "$diagnostic" ]; then
	echo "cues are: $cues."
	echo "cue columns: $cue_columns"
	echo "no of cues: $no_of_cues"
	sleep 1
fi
########################### assembling individual response profiles ####################
if [ "$by_respondent" ]; then
	echo -n "Gathering figures for report of categories by respondent..."
	rowcount=
	# process line-by-line
	for line in $in_categories; do
	if [ "$diagnostic" ]; then echo;echo "this is line: $line
respondent IDs are $in_respondentIDs";fi
	(( rowcount += 1 ))
	# write every respondent's category frequencies to a tmp file with their ID
	if [ "$in_respondentIDs" ]; then
		# in the following, empty lines need to have an underscore inserted
		tr '|' '\n' <<< "$line" | sed 's/^$/_/g' | sort -d | uniq -c | sed $extended -e 's/^ +//' -e 's/([[:digit:]]+) (.+)/\2	\1/g' > $RSCRATCHDIR/$(echo $in_respondentIDs | cut -d ' ' -f $rowcount)
	else
		tr '|' '\n' <<< "$line" | sed 's/^$/_/g' | sort -d | uniq -c | sed $extended -e 's/^ +//' -e 's/([[:digit:]]+) (.+)/\2	\1/g' > $RSCRATCHDIR/respondent$rowcount
	fi
	done
	# assemble overall list of categories
	extant_cats=$(cut -f 1 $RSCRATCHDIR/* | sort -d | uniq | tr '\n' ' ')
	if [ "$diagnostic" ]; then echo "categories are $extant_cats";fi
	echo "."
	##### assemble report
	# write header and then row by row
	if [ "$in_respondentIDs" ]; then
		report_out="$ID_header|$(echo $extant_cats | sed $extended 's/ /|/g' | sed 's/_/no response/g')"
		for row in $in_respondentIDs; do
			out_row="$row"
			for out_cat in $extant_cats; do
				out_row+="|$(grep "^$out_cat	" $RSCRATCHDIR/$row |cut -f 2)"
			done
			report_out+="
$out_row"
		done
	else
		report_out="$(echo $extant_cats | sed 's/ /|/g' | sed 's/_/no response/g')"
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
	if [ "$diagnostic" ]; then
		echo "--------"
		echo "$report_out"
		echo "--------"
	fi
	sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' -e 's/\–/-/g' -e 's/_DOT_/\./g' -e 's=_SLASH_=/=g' -e "s/_APOSTROPHE_/\'/g" -e 's/_LBRACKET_/(/g' -e 's/_RBRACKET_/)/g' -e 's/_ASTERISK_/\*/g' -e 's/_PLUS_/\+/g' -e 's/_/ /g' -e 's/DOUBLEQUOTES/\"\"/g' <<< "$report_out" > "$output_filename"
	#sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' <<< "$report_out" > "$output_filename"
	# undo any cygwin damage
	#if [ "$WSL" ]; then
	#	conv -U "$output_filename" 2>/dev/null
	#fi
	echo "Report saved as \"$output_filename\"."
	# tidy up
	extant_cats=
	report_out=
	out_row=
	out_cat=
fi
########################### assembling by-cue report ####################
if [ "$by_cue" ]; then
	echo "Gathering figures for report of categories by cue..."
	# process column-by-column to write cat frequencies of every cue to tmp
	for colu in $(eval echo {1..$no_of_cues}); do
		cut -d '|' -f $colu <<< "$in_categories" | sed 's/^$/_/g' | sort -d | uniq -c | sed $extended -e 's/^ +//' -e 's/([[:digit:]]+) (.+)/\2	\1/g' > $SCRATCHDIR/$(cut -d '|' -f $colu <<< $cues)
	done
	# assemble overall list of categories
	extant_cats=$(cut -f 1 $SCRATCHDIR/* | sort -d | uniq |tr '\n' ' ')
	#echo "categories are $extant_cats"
	##### assemble report
	# assemble header
	report_out="cues|$(echo $extant_cats | sed 's/ /|/g' | sed 's/_/no response/g')"
	# assemble rows
#	cues="$(tr '\n' ' ' <<<$cues)"
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
	if [ "$diagnostic" ]; then
		echo "--------"
		echo "$report_out"
		echo "--------"
	fi
	sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' -e 's/\–/-/g' -e 's/_DOT_/\./g' -e 's=_SLASH_=/=g' -e "s/_APOSTROPHE_/\'/g" -e 's/_LBRACKET_/(/g' -e 's/_RBRACKET_/)/g' -e 's/_ASTERISK_/\*/g' -e 's/_PLUS_/\+/g' -e 's/_/ /g' -e 's/DOUBLEQUOTES/\"\"/g' <<< "$report_out" > "$output_filename"
	#sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' <<< "$report_out" > "$output_filename"
	# undo any cygwin damage
	#if [ "$WSL" ]; then
	#	conv -U "$output_filename" 2>/dev/null
	#fi
	echo "Report saved as \"$output_filename\"."
	# tidy up
	extant_cats=
	report_out=
	out_row=
	out_cat=
fi
########################### assembling primary response report ####################
if [ "$primary_resp" ]; then
	echo "Gathering figures for primary response report..."
	if [ "$diagnostic" ]; then
		echo "category columns are $cat_columns"
		echo "response columns are $cue_columns"
	fi
	# pick out response columns
	in_responses="$(cut -d '|' -f $(sed $extended -e 's/^ //' -e 's/ /,/g' <<< $cue_columns) <<< "$in_wa")"
	# process column-by-column to write response frequencies of every cue to tmp
	for colu in $(eval echo {1..$no_of_cues}); do
		cut -d '|' -f $colu <<< "$in_responses" | sed 's/^$/_/g' | sort -d | uniq -c | sed $extended -e 's/^ +//' -e 's/([[:digit:]]+) (.+)/\2	\1/g' | sort -rnk2 | sed 's/	/|/g'> $SCRATCHDIR3/$(cut -d '|' -f $colu <<< $cues)
	done
	##### assemble report
	# assemble header
	report_out="$(echo $cues | sed -e 's/|/|frequency|/g' -e 's/$/|frequency/g')"
	# add the rest
	report_out+="
$(paste $(sed -e 's/|/ /g' -e "s?^?$SCRATCHDIR3/?g" -e "s? ? $SCRATCHDIR3/?g" <<<$cues) | sed -e 's/^	/|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/	/|/g' -e 's/_/ /g' -e 's/| |/|no response|/g' -e 's/^ |/no response|/g')"
#	report_out+="
#$(paste $SCRATCHDIR3/* | sed -e 's/^	/|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/		/	|	/g' -e 's/	/|/g' -e 's/_/ /g')"
# write report file
# create name of report output file
add_to_name p-report_$in_filename_only
if [ "$diagnostic" ]; then
	echo "---------------"
	echo "$report_out"
	echo "---------------"
	sleep 5
fi
sed $extended -e 's/ /_/g' -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' -e 's/\–/-/g' -e 's/_DOT_/\./g' -e 's=_SLASH_=/=g' -e "s/_APOSTROPHE_/\'/g" -e 's/_LBRACKET_/(/g' -e 's/_RBRACKET_/)/g' -e 's/_ASTERISK_/\*/g' -e 's/_PLUS_/\+/g' -e 's/_/ /g' -e 's/DOUBLEQUOTES/\"\"/g' <<< "$report_out" > "$output_filename"
#sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' -e 's/\–/-/g' -e 's/ DOT /\./g' -e 's= SLASH =/=g' -e "s/ APOSTROPHE /\'/g" -e 's/ LBRACKET /(/g' -e 's/ RBRACKET /)/g' -e 's/ ASTERISK /\*/g' -e 's/ PLUS /\+/g' -e 's/DOUBLEQUOTES/\"\"/g' <<< "$report_out" > "$output_filename"
#sed $extended -e 's/^/\"/' -e 's/$/\"/g' -e 's/\|/\",\"/g' <<< "$report_out" > "$output_filename"
# undo any cygwin damage
#if [ "$WSL" ]; then
#	conv -U "$output_filename" 2>/dev/null
#fi
echo "Report saved as \"$output_filename\"."
fi
########################### assembling inter-rater agreement report ####################
if [ "$inter_rater" ]; then
	# check if rater IDs are supplied
	if [ "$(grep '|rated_by' <<< $in_header)" ] ; then
		:
	else
		echo "" >&2
		echo "ERROR: $in_filename does not contain rater IDs. Only data files with rater IDs can be used to derive inter-rater agreement ratios." >&2
		exit 1
	fi
	echo "Gathering figures for inter-rater agreement report..."
	# count the number of times the RESOLVED label is added to rater IDs
	disagreements=$(grep -o ';RESOLVED",*' "$in_filename" | wc -l | sed 's/ //g')
	# work out how many categories were assigned (= total category slots minus empty slots)
	total_cats=$(echo $in_categories | sed 's/ /|/g' | grep -o '|' | wc -l); (( total_cats += 1 ))
	empty=$(echo $in_categories | grep -o '_' | wc -l)
	(( total_cats -= $empty ))
	# work out the ratio
	int_rater_ratio=$(echo "scale=4; 1 - ($disagreements / $total_cats)" | bc)
	# display report
	if [ "$by_cue" ] || [ "$by_respondent" ] || [ "$primary_resp" ]; then
		:
	else
		printf "\033c"
	fi
	echo "=============================================================="
	echo "Inter-rater agreement report for $in_filename_only"
	echo "=============================================================="
	echo "total ratings in file: $total_cats"
	echo "ratings marked as having needed resolution: $disagreements"
	echo "inter-rater agreement ratio: $int_rater_ratio"
	echo "=============================================================="
	echo "The accuracy of the report depends on an agreement-marked"
	echo "database having been used to produce the data file. This will be"
	echo "the case if the database was created using WADP v. 0.6 or later."
	echo "See the manual for further details."
fi
# tidy up
if [ -z "$diagnostic" ]; then
	rm -r $RSCRATCHDIR $SCRATCHDIR $SCRATCHDIR3 &
fi

if [ "$by_cue" ] || [ "$by_respondent" ] || [ "$primary_resp" ]; then
# ask if directory should be opened
echo ""
read -p 'Would you like to open the output directory? (Y/n)' a  < /dev/tty
if [ "$a" == "y" ] || [ "$a" == "Y" ] || [ -z "$a" ]; then
	if [ "$WSL" ]; then
		explorer.exe `wslpath -w "$PWD"`
	elif [ "$DARWIN" ]; then
		open .
	else
		xdg-open .
	fi
fi
fi
)
#######################
# define run_administrator function
#######################
run_administrator ( ) {
printf "\033c"
echo
echo
echo
echo
echo
echo "          What would you like to do?"
echo "          (R)    resolve differences between 2 database files now"
echo "          (P)    produce a list of differences only"
echo "          (C)    combine two database files into one"
echo "          (T)    turn categorised csv file into a database"
read -p '          ' task
case $task in
		P|p)	list_only=true
			;;
		R|r)	r_task=true
				echo
				read -p 'Please enter your rater ID (or leave blank) and press ENTER: ' rater_id
				export rater_id
				if [ -z "$rater_id" ]; then
						rater_id="anonymous"
				fi
			;;
		C|c)	c_task=true
			;;
		T|t)	t_task=true
			;;
		*)		echo "ERROR: $task is not a valid choice" >&2
				exit 1
esac
# if r-task, ask for rater ID
if [ "$r_task" ]; then
	echo "r_task is $r_task"
fi
# if t-task, ask for csv file
if [ "$t_task" ]; then
	printf "\033c"
	echo
	echo
	echo
	echo
	echo
	echo "          Drag the csv file into this window and press ENTER."
	echo 
	read -rp '           ' database1  < /dev/tty
	# get WSL path if required
	if [ "$WSL" ]; then
		# only execute next command if db was provided
		if [ -n "$database1" ]; then
			database1=$(wslpath "$database1")
		fi
	fi
	if [ -z "$database1" ]; then
		echo "A csv file must be provided. Please drop the file into this window."
		read -rp '           ' database1  < /dev/tty
		# get WSL path if required
		if [ "$WSL" ]; then
			# only execute next command if db was provided
			if [ -n "$database1" ]; then
				database1=$(wslpath "$database1")
			fi
		fi
		if [ -z "$database1" ]; then
			echo "No file was provided. Exiting." >&2
			return
		fi
	fi
# otherwise, ask for 2 database files
else
	printf "\033c"
	echo
	echo
	echo
	echo
	echo
	echo "          Drag the first database file into this window and press ENTER."
	echo 
	read -rp '           ' database1  < /dev/tty
	# get WSL path if required
	if [ "$WSL" ]; then
		# only execute next command if db was provided
		if [ -n "$database1" ]; then
			database1=$(wslpath "$database1")
		fi
	fi
	if [ -z "$database1" ]; then
		echo "A database file must be provided. Please drop the file into this window."
		read -rp '           ' database1  < /dev/tty
		# get WSL path if required
		if [ "$WSL" ]; then
			# only execute next command if db was provided
			if [ -n "$database1" ]; then
				database1=$(wslpath "$database1")
			fi
		fi
		if [ -z "$database1" ]; then
			echo "No database file provided. Exiting." >&2
			return
		fi
	fi
	printf "\033c"
	echo
	echo
	echo
	echo
	echo
	echo "          Drag the second database file into this window and press ENTER."
	echo 
	read -rp '           ' database2  < /dev/tty
	# get WSL path if required
	if [ "$WSL" ]; then
		# only execute next command if db was provided
		if [ -n "$database2" ]; then
			database2=$(wslpath "$database2")
		fi
	fi
	if [ -z "$database2" ]; then
		echo "A database file must be provided. Please drop the file into this window."
		read -rp '           ' database2  < /dev/tty
		# get WSL path if required
		if [ "$WSL" ]; then
			# only execute next command if db was provided
			if [ -n "$database2" ]; then
				database2=$(wslpath "$database2")
			fi
		fi
		if [ -z "$database2" ]; then
			echo "No database file provided. Exiting." >&2
			return
		fi
	fi
fi
# get rid of any single quotation marks that might have attached
export database1="$(sed "s/'//g" <<<"$database1")"
if [ "$database2" ]; then
	export database2="$(sed "s/'//g" <<<"$database2")"
fi
# change dir to that of the first database/csv-file
export working_dirname="$(dirname "$database1" | sed "s/'//g")"
cd "$working_dirname" 2>/dev/null || dirfail=true
if [ "$diagnostic" ]; then 
	echo "now in $(pwd). dirname is $working_dirname"
	read -p 'press ENTER to continue ' xxx < /dev/tt
fi
# if t-task, call administrator.sh -a with csv file as argument
if [ "$t_task" ]; then
	administrator -a "$database1"
else
	# check if there are differences in the databases
	if [ "$(diff -q "$database1" "$database2")" ]; then
		# call administrator.sh -a with 2 database files are arguments
		if [ "$c_task" ]; then
			administrator -ac "$database1" "$database2"
		elif [ "$r_task" ]; then
			administrator -ar "$database1" "$database2"
		else
			administrator -ap "$database1" "$database2"
		fi
	else # if no differences
		echo "$(basename "$database1") and $(basename "$database2") are identical."
		sleep 2
	fi
fi
# reset task selectors
c_task=
t_task=
r_task=
list_only=
}
#######################
# define administrator function
#######################
administrator ( ) (
##############################################################################
# administrator.sh
# DESCRRIPTION: performs administrative functions on wa dbs and data files
################# defining functions ###############################
# define csv_parser function
############################
csv_parser ( ) {
sed $extended -e 's/\|/PIPE/g' \
-e 's/,\"\"\"/,\" DOUBLEQUOTES /g' -e 's/\"\"\",/ DOUBLEQUOTES \",/g' -e 's/\"\"/ DOUBLEQUOTES /g' \
-e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' \
-e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' -e 's/  / /g' "$1"
#sed $extended -e 's/\|/PIPE/g' -e 's/\"\"//g' -e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' -e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' "$1"
}
#######################
# define add_windows_returns function
#######################
add_windows_returns ( ) {
sed "s/$/$(printf '\r')/g" "$1"
}
#######################
# define remove_windows_returns function
#######################
remove_windows_returns ( ) {
sed "s/$(printf '\r')//g" "$1"
}

#######################
# define remove_boms_macOS function
#######################
remove_boms_macOS ( ) {
sed $'s/\xEF\xBB\xBF//' "$1"
}

#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename "$0") performs administrative functions on .dat files
              and .csv files containing word-association data
SYNOPSIS:     $(basename "$0") (DB.dat DB.dat | rated_list.csv)

OPTIONS:      -a run in auxiliary script mode
              -p produce list of differences between two database files
              -r resolve differences between two database files
              -c combine two database files into one database file
              -t turn rated csv file into a database
              -h show this help message
              -V show copyright and licensing information
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
		while [ -e "$1"-$count ]
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
#######################
# define resolution_menu function
#######################
resolution_menu () {
# read any changed keys assignments
if [ -e $SCRATCHDIR/new_left ]; then
	new_left="$(cat $SCRATCHDIR/new_left)"
	new_right="$(cat $SCRATCHDIR/new_right)"
fi
# shift variable names for the 'back' function
previous_cue="$new_cue"; new_cue=
previous_diff="$new_diff"; new_diff=
previous_rating="$new_rating"; new_rating=
previous_destination="$new_destination"; new_destination=
previous_difference="$new_difference"; new_difference=
echo "processing cue $cue_progress of $(wc -l <<<"$cues" | sed 's/ //g')."
echo
echo 	
echo
echo "	cue: $cue"
new_cue=$cue
echo
new_diff="$(sed $extended -e 's/</-/' -e 's/>/-/' -e 's/		//g' -e 's/\|/ -> /' -e 's/\|/ vs. /' -e 's/\|/ -> /' -e 's/^/	/' <<< "$difference" | sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g')"
echo "$new_diff"
echo
# following menu items are conditional so no empty side can be chosen
if [ -z "$(grep -E '>' <<< "$difference")" ]; then echo "	("$new_left")	choose left";fi
if [ -z "$(grep -E '<' <<< "$difference")" ]; then echo "	("$new_right")	choose right";fi
echo "	(N)	input new category assignment"
echo "	(D)	discard both ratings"
if [ "$previous_rating" ] || [ "$deleted" ]; then echo "	(B)	go back to previous";fi
echo "	(X)	exit rating process"
echo "	(*)	assign new keys to \"choose left\" and \"choose right\""
echo
read -p '	' r
# reset 'deleted' switch
deleted=
# check if B was requested and deal with this request first
if [ "$r" != "b" ] && [ "$r" != "B" ]; then
	# if 'B' was NOT requested, write any previous assignments to file
	if [ "$previous_rating" ]; then
		echo "$previous_rating" >> "$previous_destination"
		previous_rating=
		previous_destination=
	fi
else
	printf "\033c"
	previous_resolution_menu
	echo
	echo 	
	echo
	echo "	cue: $new_cue"
	echo
	echo "$new_diff"
	echo
	# following menu items are conditional so no empty side can be chosen
	if [ -z "$(grep -E '>' <<< "$difference")" ]; then echo "	("$new_left")	choose left";fi
	if [ -z "$(grep -E '<' <<< "$difference")" ]; then echo "	("$new_right")	choose right";fi
	echo "	(N)	input new category assignment"
	echo "	(D)	discard both ratings"
	echo "	(X)	exit rating process"
	echo "	(*)	assign new keys to \"choose left\" and \"choose right\""
	echo
	read -p '	' r
fi
# if * chosen
if [ "$r" == "*" ]; then
	echo "	-> New key assignments are only retained during the current session."
	read -p '	enter new key for "choose left" here: ' new_left
	read -p '	enter new key for "choose right" here: ' new_right
	echo "$new_left" > $SCRATCHDIR/new_left
	echo "$new_right" > $SCRATCHDIR/new_right
	if [ -z "$(grep -E '>' <<< "$difference")" ]; then echo "	($new_left)	choose left";fi
	if [ -z "$(grep -E '<' <<< "$difference")" ]; then echo "	($new_right)	choose right";fi
	echo "	(N)	input new category assignment"
	echo "	(D)	discard both ratings"
	read -p '	' r
fi
# if interruption
if [ "$r" == "x" ] || [ "$r" == "X" ]; then
	echo "	If you exit the rating process before it is complete,"
	echo "	you will get a log with all decisions listed, but you"
	echo "	will have to enter them again next time to get a"
	echo "	fully resolved database."
	echo "	Would you still like to exit? [Y/n]"
	read -p '	' r
	if [ "$r" == "n" ] || [ "$r" == "N" ]; then
		echo "	Enter a new choice:"
		read -p '	' r		
	else
		echo "++++++++++++++++++++++">> $SCRATCHDIR/$log_name
		echo "Resolution interrupted">> $SCRATCHDIR/$log_name
		echo "++++++++++++++++++++++">> $SCRATCHDIR/$log_name
		add_to_name ./$log_name
		sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$log_name > $output_filename || echo "ERROR: could not find log."
		echo "	Log file \"$output_filename\" placed in $(pwd)."
		rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 &
		exit 0
	fi
fi
# if other options
echo "	your choice: $r"
case $r in
	"$new_left")	new_rating="$(cut -f 1 <<< $difference);$rater_id;RESOLVED"
			new_destination="$R_SCRATCHDIR/$cue"
			echo "---> resolved as: $(cut -f 1 <<< $difference)" >> $SCRATCHDIR/$log_name
		;;
	"$new_right")	new_rating="$(cut -d '|' -f 3-4 <<< $difference|sed 's/	//g');$rater_id;RESOLVED"
			echo "---> resolved as: $(cut -d '|' -f 3-4 <<< $difference|sed 's/	//g')" >> $SCRATCHDIR/$log_name
			new_destination="$R_SCRATCHDIR/$cue"
		;;
	d|D)	echo "	discarding those ratings..."
			deleted=true
			new_rating=
			new_destination="$R_SCRATCHDIR/$cue"
			echo "---> $(cut -d '|' -f 1 <<< $difference|sed 's/							//g') deleted" >> $SCRATCHDIR/$log_name
		;;
	*)	read -p '	Enter new category here: ' new_cat
		new_cat="$(tr '[[:lower:]]' '[[:upper:]]' <<<"$new_cat")"
		new_rating="$(cut -d '|' -f 1 <<< $difference|sed 's/							//g')|$new_cat;$rater_id;RESOLVED"
		new_destination="$R_SCRATCHDIR/$cue"
		echo "---> resolved as: $(cut -d '|' -f 1 <<< $difference|sed 's/							//g')|$new_cat" | sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' >> $SCRATCHDIR/$log_name
		;;
esac
sleep 0.5
printf "\033c"
new_difference="$difference"
}
#######################
# define previous_resolution_menu function
#######################
previous_resolution_menu () {
	echo
	echo 	
	echo
	echo "	cue: $previous_cue"
	echo
	echo "$previous_diff"
	echo
	echo "	previously rated as: $(cut -d '|' -f 2 <<< $previous_rating | cut -d ';' -f 1)"
	echo
	# following menu items are conditional so no empty side can be chosen
	if [ -z "$(grep -E '>' <<< "$new_difference")" ]; then echo "	("$new_left")	choose left";fi
	if [ -z "$(grep -E '<' <<< "$new_difference")" ]; then echo "	("$new_right")	choose right";fi
	echo "	(N)	input new category assignment"
	echo "	(D)	discard both ratings"
	echo
	read -p '	' r
	echo "	your choice: $r"
	case $r in
		"$new_left")	echo "$(cut -f 1 <<< $previous_difference);$rater_id;RESOLVED" >> $previous_destination
				echo "-x-x-x-x-x-x-x-x-x-x-> A PREVIOUS RATING WAS CHANGED: $previous_cue - $(cut -f 1 <<< $previous_difference)" >> $SCRATCHDIR/$log_name
			;;
		"$new_right")	echo "$(cut -d '|' -f 3-4 <<< $previous_difference|sed 's/	//g');$rater_id;RESOLVED" >> $previous_destination
				echo "-x-x-x-x-x-x-x-x-x-x-> A PREVIOUS RATING WAS CHANGED: $previous_cue - $(cut -d '|' -f 3-4 <<< $previous_difference|sed 's/	//g')" >> $SCRATCHDIR/$log_name
			;;
		d|D)	echo "	discarding those ratings..."
				previous_rating=
				echo "-x-x-x-x-x-x-x-x-x-x-> A PREVIOUS RATING WAS CHANGED: $previous_cue - $(cut -d '|' -f 1 <<< $previous_difference|sed 's/							//g') deleted" >> $SCRATCHDIR/$log_name
			;;
		*)	read -p '	Enter new category here: ' new_cat
			new_cat="$(tr '[[:lower:]]' '[[:upper:]]' <<<"$new_cat")"
			echo "$(cut -d '|' -f 1 <<< $previous_difference|sed 's/							//g')|$new_cat;$rater_id;RESOLVED" >> $previous_destination
			echo "-x-x-x-x-x-x-x-x-x-x-> A PREVIOUS RATING WAS CHANGED: $previous_cue - $(cut -d '|' -f 1 <<< $previous_difference|sed 's/							//g')|$new_cat" | sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' >> $SCRATCHDIR/$log_name
			;;
	esac
	sleep 0.5
	printf "\033c"
}
################## end defining functions ########################
# initialise some variables
extended="-r"
new_left="<"
new_right=">"
# check what platform we're under
platform=$(uname -v)
# and make adjustments accordingly
if [ "$(grep 'Microsoft' <<< $platform)" ]; then
	WSL=TRUE
elif [ "$(grep 'Darwin' <<< $platform)" ];then
	DARWIN=TRUE
	extended="-E"
elif [ "$(grep 'Linux' <<< $platform)" ]; then
	LINUX=TRUE
else
	# probably some flavour of Linux
	LINUX=TRUE
fi
# analyse options
local OPTIND ahvVprct opt # making sure the options are only for this script, leaving out -d as that can be global
while getopts adhvVprct opt
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
		echo "$copyright"
		exit 0
		;;
	p)	p_task=true
		;;
	r)	r_task=true
		;;
	c)	c_task=true
		;;
	t)	t_task=true
		;;
	esac
done
shift $((OPTIND -1))
# splash screen
if [ "$auxiliary" ]; then
	printf "\033c"
	echo
	echo
	echo
	echo
	echo
else
	# splash screen
	printf "\033c"
	echo "Word Association Data Processor - $copyright"
	echo
	echo
	echo
	echo
	echo
	echo "			WORD ASSOCIATION DATA ADMINISTRATOR"
	echo "			version $version"
fi
echo 
echo 
echo 
echo 
echo 
echo 
echo 
################ checks on input files
# check what sorts of input files we've got
case $# in
	0)	echo "ERROR: insufficient number of input files provided." >&2
		exit 1
		;;
	1)	if [ -s "$1" ]; then
			t_task=true
			remove_windows_returns "$1" > "$1.corr"
			remove_boms_macOS "$1.corr" > "$1"
			rm "$1.corr"
		else
			echo "ERROR: could not access file $1" >&2
			exit 1
		fi
		if [ "$(grep -E -o '\.csv' <<<"$1")" ]; then
			csv_infile="$1"
			csv_infile_name="$(basename "$csv_infile")"
		else
			echo "ERROR: if one file is provided, it must be a .csv file." >&2
			exit 1
		fi
		;;
	2)	if [ -s "$1" ] && [ -s "$2" ]; then
			remove_windows_returns "$1" > "$1.corr"
			remove_boms_macOS "$1.corr" > "$1"
			rm "$1.corr"
			remove_windows_returns "$2" > "$2.corr"
			remove_boms_macOS "$2.corr" > "$2"
			rm "$2.corr"
		else
			echo "ERROR: could not access file(s) $1 and/or $2" >&2
			exit 1
		fi
		if [ "$(grep -E -o '\.dat' <<<"$1")" ] && [ "$(grep -E -o '\.dat'<<<"$2")" ]; then
			dat_infile1="$1"
			dat_infile1_name="$(basename "$dat_infile1")"
			dat_infile2="$2"
			dat_infile2_name="$(basename "$dat_infile2")"
		else
			echo "ERROR: Two .dat files must be provided as input." >&2
			exit 1
		fi
		;;
	*)	echo "ERROR: more than two input files provided: $@" >&2
		exit 1
		;;
esac
################ create scratch directories
# two to keep db sections in
SCRATCHDIR1=$(mktemp -dt administrator1XXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR1" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}administrator1XXX.1$$
	SCRATCHDIR1=${TMPDIR-/tmp/}administrator1XXX.1$$
fi
SCRATCHDIR2=$(mktemp -dt administrator2XXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR2" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}administrator2XXX.1$$
	SCRATCHDIR2=${TMPDIR-/tmp/}administrator2XXX.1$$
fi
# another one to put the resolved db in
R_SCRATCHDIR=$(mktemp -dt R_administratorXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$R_SCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}R_administratorXXX.1$$
	R_SCRATCHDIR=${TMPDIR-/tmp/}R_administratorXXX.1$$
fi
# another one to keep other auxiliary and temporary files in
SCRATCHDIR=$(mktemp -dt administratorXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
if [ "$SCRATCHDIR" == "" ] ; then
	mkdir ${TMPDIR-/tmp/}administratorXXX.1$$
	SCRATCHDIR=${TMPDIR-/tmp/}administratorXXX.1$$
fi
if [ "$diagnostic" == true ]; then
	if [ "$DARWIN" ]; then
		open $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR
	elif [ "$WSL" ]; then
		explorer.exe `wslpath -w "$SCRATCHDIR"`
		explorer.exe `wslpath -w "$SCRATCHDIR1"`
		explorer.exe `wslpath -w "$SCRATCHDIR2"`
		explorer.exe `wslpath -w "$R_SCRATCHDIR"`
	else
		xdg-open $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR
	fi	
fi
# initiating the log file
# create name for log file
add_to_name administrator-log.txt; log_name=$output_filename
################ menu for .dat .dat operations
if [ "$dat_infile1_name" ]; then
	if [ -z "$auxiliary" ]; then
		echo "          What would you like to do?"
		echo "          (P)    produce a list of differences only"
		echo "          (R)    resolve differences now"
		echo "          (C)    combine two databases into one"
		echo "          (T)    turn rated csv file into a database"
		read -p '          ' task
		case $task in
				P|p)	p_task=true
					;;
				R|r)	r_task=true
					;;
				C|c)	c_task=true
					;;
				T|t)	t_task=true
					;;
				*)		echo "ERROR: $task is not a valid choice" >&2
						exit 1
		esac
		if [ "$r_task" ] && [ -z "$p_task" ]; then
			echo
			read -p 'Please enter your rater ID (or leave blank) and press ENTER: ' rater_id
			if [ -z "$rater_id" ]; then
				rater_id="anonymous"
			fi
		fi
	fi
	# if p_task is active, also activate r-task
	if [ "$p_task" ]; then
		r_task=true
	fi
################# processing dat files ###################
	# count cues in dat files
	total_cues1=$(wc -l < "$dat_infile1" | tr '\r' '\n')
	total_cues2=$(wc -l < "$dat_infile2" | tr '\r' '\n')
	# split db into response - category pairs per line in files named after cues
	while read line; do
		file=$(cut -f 1 <<< "$line" | sed 's/﻿//g')
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n' | sort | sed -e 's/\?/QQUUEESSTTIIOONNMMAARRKK/g' -e 's/\^/CCIIRRCCUUMMFFLLEEXX/g' -e 's/#/HHAASSHHTTAAGG/g' -e 's/\!/EEXXCCLLAAMM/g')" > $SCRATCHDIR1/$file
	done < "$dat_infile1"
	while read line; do
		file=$(cut -f 1 <<< "$line" | sed 's/﻿//g')
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n' | sort | sed -e 's/\?/QQUUEESSTTIIOONNMMAARRKK/g' -e 's/\^/CCIIRRCCUUMMFFLLEEXX/g' -e 's/#/HHAASSHHTTAAGG/g' -e 's/\!/EEXXCCLLAAMM/g')" > $SCRATCHDIR2/$file
	done < "$dat_infile2"
	##### begin log file (this is relative to task, so 3 different ways)
	if [ "$p_task" ]; then
		date > $SCRATCHDIR/$log_name
		echo "Differences $dat_infile1_name vs. $dat_infile2_name" >> $SCRATCHDIR/$log_name
		echo "-------------------------------------------------------------------------">> $SCRATCHDIR/$log_name
	elif [ "$r_task" ]; then
		# write an identifier line to the log
		echo "# administrator.sh-log - $(date)" > $SCRATCHDIR/$log_name
		echo "# Difference resolution" >> $SCRATCHDIR/$log_name
		echo "# $dat_infile1_name vs. $dat_infile2_name" >> $SCRATCHDIR/$log_name
	else # that is, if c_task
		echo "# administrator.sh-log - $(date)" > $SCRATCHDIR/$log_name
		echo "# Combination of $dat_infile1_name & $dat_infile2_name" >> $SCRATCHDIR/$log_name
	fi
	# set WARNING relative to task
	if [ -z "$p_task" ] && [ "$r_task" ]; then
		WARN="WARNING:"
	fi
	##################### comparing cues
	ls $SCRATCHDIR1 | sed 's/﻿//g' | sort > $SCRATCHDIR/cues1
	# the sed here gets rid of an invisible control character that might appear
	ls $SCRATCHDIR2 | sed 's/﻿//g' | sort > $SCRATCHDIR/cues2
	if [ "$(diff $SCRATCHDIR/cues[12])" ]; then
	# if the cues differ
		printf "\033c"
		echo
		echo
		echo
		echo "$WARN The following cues differ:"|sed 's/^ //g' | tee -a $SCRATCHDIR/$log_name
		echo "$dat_infile1_name			vs.		  $dat_infile2_name" | tee -a $SCRATCHDIR/$log_name
		diff -y --suppress-common-lines $SCRATCHDIR/cues[12] |sed $extended -e 's/</*cue missing*		/g' -e 's/	+ *>/*cue missing*						/g'| sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' | tee -a $SCRATCHDIR/$log_name
		echo
		# move cues only found in dat_infile1 to results
		for single_cue in $(comm -23 $SCRATCHDIR/cues[12]); do
			mv $SCRATCHDIR1/$single_cue $R_SCRATCHDIR
			if [ -z "$p_task" ]; then echo "Responses and ratings for cue \"$single_cue\" will be copied to resolved list."
			fi
		done
		# move cues only found in dat_infile2 to results
		for single_cue in $(comm -13 $SCRATCHDIR/cues[12]); do
			mv $SCRATCHDIR2/$single_cue $R_SCRATCHDIR
			if [ -z "$p_task" ]; then echo "Responses and ratings for cue \"$single_cue\" will be copied to resolved list."
			fi
		done
		if [ -z "$p_task" ] && [ "$r_task" ]; then 
			read -p 'Continue? (Y/n)' r
			if [ "$r" == "n" ] || [ "$r" == "N" ]; then
				rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR &
				exit 0
			fi
		fi
	fi
	# get new list of cues (sed necessary to get rid of possible control chars)
	ls $SCRATCHDIR1 | sed 's/﻿//g' | sort > $SCRATCHDIR/cues1
	ls $SCRATCHDIR2 | sed 's/﻿//g' | sort > $SCRATCHDIR/cues2
	cues=$(cat $SCRATCHDIR/cues1)
	# remaining cues should now be identical, but check
	if [ "$(diff $SCRATCHDIR/cues[12])" ]; then
		echo "ERROR in processing encountered: the following cues should be common to both .dat files but are not" | tee -a $SCRATCHDIR/$log_name
		diff -y --suppress-common-lines $SCRATCHDIR/cues[12] | sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' | tee -a $SCRATCHDIR/$log_name
		echo "cannot continue."
		rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR &
		exit 1
	fi
	##################### comparing responses
	for cue in $cues; do
		resp1=$(cut -d '|' -f 1 $SCRATCHDIR1/$cue | sed -e 's/﻿//g' -e '/^$/d'| sort)
		resp2=$(cut -d '|' -f 1 $SCRATCHDIR2/$cue | sed -e 's/﻿//g' -e '/^$/d'| sort)
		if [ "$resp1" != "$resp2" ]; then
		# if responses for this cue are NOT identical (not counting cats/raters)
			printf "\033c"
			echo
			echo
			echo "" | tee -a $SCRATCHDIR/$log_name
			echo "$WARN The following responses to cue \"$cue\" differ:"|sed 's/^ //g' | tee -a $SCRATCHDIR/$log_name
			echo
			echo "$dat_infile1_name			 vs.		        $dat_infile2_name" | tee -a $SCRATCHDIR/$log_name
			sort <<< "$resp1" | sed '/^$/d' > $SCRATCHDIR/resp1
			sort <<< "$resp2" | sed '/^$/d' > $SCRATCHDIR/resp2
			diff -y --suppress-common-lines $SCRATCHDIR/resp[12] | sed $extended -e 's/</-/g' -e 's/	+ *>/-						/'|sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' -e 's/|//g'| tee -a $SCRATCHDIR/$log_name
			# copy over responses only found in dat_infile1
			for single_resp in $(comm -23 $SCRATCHDIR/resp[12]); do
				# copy it over and remove it
				grep -E "^$single_resp\|" $SCRATCHDIR1/$cue >> $R_SCRATCHDIR/$cue
				grep -E -v "^$single_resp\|" $SCRATCHDIR1/$cue >$SCRATCHDIR1/$cue.
				mv $SCRATCHDIR1/$cue. $SCRATCHDIR1/$cue
				if [ -z "$p_task" ] && [ "$r_task" ]; then echo "Ratings for response \"$single_resp\" will be copied to resolved list."
				fi
			done
			# move over responses only found in dat_infile2
			for single_resp in $(comm -13 $SCRATCHDIR/resp[12]); do
				# copy it over and remove it
				grep -E "^$single_resp\|" $SCRATCHDIR2/$cue >> $R_SCRATCHDIR/$cue
				grep -E -v "^$single_resp\|" $SCRATCHDIR2/$cue >$SCRATCHDIR2/$cue.
				mv $SCRATCHDIR2/$cue. $SCRATCHDIR2/$cue
				if [ -z "$p_task" ] && [ "$r_task" ]; then echo "Ratings for response \"$single_resp\" will be copied to resolved list."
				fi
			done
			if [ -z "$p_task" ] && [ "$r_task" ]; then
				echo
				read -p 'Continue? (Y/n)' r
				if [ "$r" == "n" ] || [ "$r" == "N" ]; then
					rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR &
					exit 0
				fi
			fi
		fi
		### at this stage, we should have only shared cues and responses
		# check if that is so
		resp1=$(cut -d '|' -f 1 $SCRATCHDIR1/$cue | sed -e 's/﻿//g' | sort)
		resp2=$(cut -d '|' -f 1 $SCRATCHDIR2/$cue | sed -e 's/﻿//g' | sort)
		sort <<< "$resp1" > $SCRATCHDIR/resp1
		sort <<< "$resp2" > $SCRATCHDIR/resp2
		if [ "$resp1" != "$resp2" ]; then
			echo "ERROR in processing encountered: the following responses should be common to both .dat files but are not" | tee -a $SCRATCHDIR/$log_name
			diff -y --suppress-common-lines $SCRATCHDIR/resp[12] |sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g'| tee -a $SCRATCHDIR/$log_name
			echo "You should not continue without investigating this inconsistency."
			echo "Press any key to exit the current task, or press 'c' to continue regardless."
			read -p '	' r
			if [ "$r" == "c" ]; then
				:
			elif [ "$r" == "C" ]; then
				:
			else
				if [ -z "$diagnostic" ]; then
					rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR &
				fi
				exit 1
			fi
		fi
	done
	##################### comparing ratings
	# up to now we've sorted out cues and responses that do not have equivalents
	# in both files (i.e. are not shared), now we look at ratings (ie.categories
	# that may be identical or differ between the shared cues&responses
	printf "\033c"
	if [ -z "$p_task" ] && [ "$r_task" ]; then
		echo
		echo
		echo
		echo "	Resolving differences in category ratings"
		echo "	$dat_infile1_name vs. $dat_infile2_name"
		sleep 1
	fi
	if [ "$diagnostic" ]; then
		echo "all differing cues and responses (but not ratings) should now be resolved"
		read -p 'Press ENTER to continue' a  < /dev/tty
	fi
	for cue in $cues; do
		if [ "$diagnostic" ]; then
			echo "now checking $cue"
			sleep 1
		fi
		(( cue_progress += 1 ))
		# first see if the whole cue (incl. responses & ratings) is entirely
		# identical (apart from the rater ID which is cut off)
		allcat1=$(cut -d ';' -f 1 $SCRATCHDIR1/$cue | sed 's/﻿//g' | sort)
		allcat2=$(cut -d ';' -f 1 $SCRATCHDIR2/$cue | sed 's/﻿//g' | sort)
		if [ "$diagnostic" ]; then
			echo "allcat1: $allcat1"
			echo "allcat2: $allcat2"
			read -p 'Press ENTER to continue' a  < /dev/tty
		fi
		if [ "$allcat1" == "$allcat2" ]; then
			if [ -z "$p_task" ]; then
				# write cue to R_SCRATCHDIR and delete
				cat $SCRATCHDIR1/$cue >> $R_SCRATCHDIR/$cue
				rm $SCRATCHDIR1/$cue $SCRATCHDIR2/$cue
			fi
		else
		# if not, look at each rating in detail
			# produce a set w/o rater IDs first
			cut -d ';' -f 1 $SCRATCHDIR1/$cue | sort > $SCRATCHDIR1/$cue.
			cut -d ';' -f 1 $SCRATCHDIR2/$cue | sort > $SCRATCHDIR2/$cue.
			# $cue = with rater IDs / $cue. = w/o rater IDs
		
			# dealing with sameness
			# write all cases of identical responses + ratings to R_SCRATCHDIR
			# this is irrespective of differing rater IDs
			for same_rating in $(comm -12 $SCRATCHDIR1/$cue. $SCRATCHDIR2/$cue.)
			do
				grep "^$same_rating;" $SCRATCHDIR1/$cue >> $R_SCRATCHDIR/$cue
				# note we are taking responses WITH rater IDs from first db
				if [ "$diagnostic" ]; then
					echo "same: $(grep "^$same_rating;" $SCRATCHDIR1/$cue)"
				fi
			done
			# dealing with difference
			# establish differences in current cue excluding diffs in rater
			diffs="$(diff -y --suppress-common-lines $SCRATCHDIR1/$cue. $SCRATCHDIR2/$cue.)"
			#diffs="$(comm -3 $SCRATCHDIR1/$cue. $SCRATCHDIR2/$cue.)"
			if [ "$diffs" ]; then
				# arrange for the right information to be displayed
				# and/or written to log
				warnings=true # flick switch to mark there were warnings
				echo >> $SCRATCHDIR/$log_name
				if [ "$r_task" ]; then
					echo "The following ratings for cue \"$cue\" differ:" >> $SCRATCHDIR/$log_name
				else # i.e. if c_task
					echo "WARNING: There are conflicts in ratings for cue \"$cue\"." | tee -a $SCRATCHDIR/$log_name
					echo "The left rating was transfered to the combined list." >> $SCRATCHDIR/$log_name
					echo "The ratings in \"$dat_infile1_name\" were transfered to the combined list. See log for details."
					echo | tee -a $SCRATCHDIR/$log_name
				fi
				# convert diffs for log output and write to log
				sed $extended -e 's/		//g' -e 's/\|/vs./2' -e 's/	[[:upper:]]+_*[[:upper:]]*\|/	/g' -e 's/\|/	/g' -e 's/ +/	/g' -e 's/		/	/g' <<< "$diffs" |sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' >> $SCRATCHDIR/$log_name
				# now write resolved/combined ratings to results
				if [ -z "$p_task" ] && [ "$r_task" ]; then
					printf "\033c"
					old_IFS=$IFS  # save the field separator           
					IFS=$'\n'     # new field separator, the end of line  
					for difference in $diffs; do
						resolution_menu
					done
					IFS=$old_IFS     # restore default field separator
				else # i.e. if c_task	
					grep "^$(cut -f 1 <<< "$diffs");" $SCRATCHDIR1/$cue >> $R_SCRATCHDIR/$cue
				fi
			fi # for the if diffs
		fi
		# tidy up
		resp_done=
	done
	#### write any remaining resolutions out
	if [ "$new_rating" ]; then
		echo "$new_rating" >> "$new_destination"
	fi
	#### write new db file (this is tab delimited with one cue per line)
	if [ -z "$p_task" ] && [ "$r_task" ]; then
		if [ $DARWIN ]; then
			add_to_name resolved-db-$(date "+%d-%m-%Y_%H.%M.%S").dat
		else
			add_to_name resolved-db-$(date "+%d-%m-%Y_%H:%M:%S").dat
		fi
		for part in $(ls $R_SCRATCHDIR); do 
			echo "$part	$(tr '\n' '	' < $R_SCRATCHDIR/$part)" | sed '/^$/d'>> $SCRATCHDIR/$output_filename
			sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$output_filename > $output_filename
		done
		echo "Resolved database saved as \"$output_filename\"." | tee -a $SCRATCHDIR/$log_name
		# undo any cygwin damage
		#if [ "$WSL" ]; then
		#	conv -U "$output_filename" 2>/dev/null
		#fi
		# ending routine
		read -p 'Would you like to output the log file? (y/N)' r
		if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
			sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$log_name > $log_name || echo "ERROR: could not find log."
			echo "Log file \"$log_name\" placed in $(pwd)."
		fi
	elif [ "$p_task" ]; then
		printf "\033c"
		sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$log_name
		echo 
		echo
		read -p 'Save this report to file? (y/N)' r
		if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
			add_to_name difference_report.txt
			sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$log_name > $output_filename
			echo "Report named \"$output_filename\" saved in $(pwd)."
		else
			do_not_ask=true
		fi
	else # i.e. if c_task
		if [ $DARWIN ]; then
			add_to_name combined-db-$(date "+%d-%m-%Y_%H.%M.%S").dat
		else
			add_to_name combined-db-$(date "+%d-%m-%Y_%H:%M:%S").dat
		fi
		for part in $(ls $R_SCRATCHDIR); do 
			echo "$part	$(tr '\n' '	' < $R_SCRATCHDIR/$part)" >> "$SCRATCHDIR/$output_filename"
			sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$output_filename > $output_filename
		done
		echo "combined database saved as \"$output_filename\"."
		# ending routine
		if [ "$warnings" ]; then
			sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$log_name > $log_name || echo "ERROR: could not find log."
			echo "Log file \"$log_name\" placed in $(pwd)."
		else
			read -p 'Would you like to output the log file? (y/N)' r
			if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
				sed -e 's/QQUUEESSTTIIOONNMMAARRKK/?/g' -e 's/CCIIRRCCUUMMFFLLEEXX/^/g' -e 's/HHAASSHHTTAAGG/#/g' -e 's/EEXXCCLLAAMM/!/g' $SCRATCHDIR/$log_name > $log_name || echo "ERROR: could not find log."
				echo "Log file \"$log_name\" placed in $(pwd)."
			fi
		fi
	fi
elif [ "$csv_infile_name" ]; then
	# test if $csv_infile is a db file
	if [ $(head -1 "$csv_infile" | grep -o 'category' | wc -l) -gt 1 ]; then
		:
	else
		echo "ERROR: \"$1\" does not appear to be of the required format." >&2
		echo "Input files must contain a header that lists: respondent ID (optional), cue, category, rated by (optional)." >&2
		exit 1
	fi
	################# processing csv database file ###################
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
	# parse csv db file and 
	# - eliminate potential trouble characters
	# - replace spaces w/ underscore and ^M with \n and ',' with '|'
	# - copy file to SCRATCHDIR
	csv_parser "$csv_infile" |\
	sed $extended -e 's/ /_/g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/\(/_LBRACKET_/g' -e 's/\)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/\+/_PLUS_/g' | tr '\r' '\n' > $SCRATCHDIR/db.csv
	# checking if respondent ID is included 
	if [ -n "$(head -1 $SCRATCHDIR/db.csv | cut -d '|' -f 1 | grep 'ID')" ]; then
		db_with_ID=true
	fi
	# checking if rater ID is included
	n_of_raterIDs="$(head -1 $SCRATCHDIR/db.csv | grep -o 'rated_by' | wc -l)"
	if [ "$n_of_raterIDs" -gt 1 ]; then
		db_with_raterID=true
		echo "rater IDs detected"
	fi
	# count db_columns
	db_columns=$(( 1 + $(head -1 $SCRATCHDIR/db.csv | tr -dc '|' | wc -c) ))
	# put database in memory and remove any respondent IDs
	if [ "$db_with_ID" ]; then
		db="$(cut -d '|' -f 2-$db_columns $SCRATCHDIR/db.csv)"
		# reduce db_columns count accordingly
		(( db_columns -= 1 ))
		# inform user
		echo "respondent IDs detected ..."
	else
		db="$(cat $SCRATCHDIR/db.csv)"
	fi
	# count cues in db
	db_total_cues=$(( ($db_columns - $n_of_raterIDs) / 2 ))
	# count db_rows
	db_rows=$(( $(wc -l <<< "$db") - 1 ))
	# write info to files to be retrieved by other processes
	echo $db_total_cues > $SCRATCHDIR/db_total_cues
	echo $db_rows > $SCRATCHDIR/db_rows
	# check if format is consistent
	if [ "$(head -1 <<< "$db" | grep -E -o "[[:upper:]]*[[:lower:]]+\|category" | wc -l)" -ne "$db_total_cues" ]; then
		echo "WARNING: there appears to be an inconsistency in the first row of \"$csv_infile_name\". It should contain sequences of a cue, followed, in the next field, by \"category\". Optionally the first field of the first row can contain text that includes the words \"ID\", and the words \"rated by\" can be included in a separate field after each category field. Please check to make certain that the format conforms to these specifications and then retry."
		rm -r $SCRATCHDIR $R_SCRATCHDIR &
		exit 1
	fi
	# check fields were properly separated: each line should contain the same number of field separators. If that is not the case, throw error and exit
	while read line; do
		if [ "$(tr -dc '|' <<< $line | wc -c)" -eq "$(( $db_columns - 1 ))" ]; then
			:
		else
			echo "ERROR: field separation inconsistency. There should be exactly $db_columns fields per line. $(tr -dc '|' <<< $line | wc -c) were detected here:" >&2
			echo "$line" >&2
			rm -r $SCRATCHDIR $R_SCRATCHDIR &
			exit 1
		fi
	done <<< "$db"
	# split db into response - category pairs
	i=1
	if [ "$db_with_raterID" ]; then
		ii=3
	else
		ii=2
	fi
	while [ $ii -le $db_columns ]; do
		# put column pairs or triples into tmplist (the first line will be empty because at first iteration $tmplist is empty)
		for line in $(cut -d '|' -f $i-$ii <<< "$db"); do
			tmplist="$tmplist
	$line"
		done
		# isolate cue and put it in $file
		file=$(head -2 <<< "$tmplist" | tail -1 | cut -d '|' -f 1 | sed 's/	//g')
		# from line 3 onwards, write lines to file named $file
		if [ "$db_with_raterID" ]; then
			tail -n +3 <<< "$tmplist" | sed $extended -e '/^\|$/d' -e '/^$/d' -e '/\|$/d' -e '/_\|_/d' | sort | uniq | sed $extended "s/\|/;/2" > $R_SCRATCHDIR/$file
		else
			tail -n +3 <<< "$tmplist" | sed $extended -e '/^\|$/d' -e '/^$/d' -e '/\|$/d' -e '/_\|_/d' | tr '[[:lower:]]' '[[:upper:]]' | sort | uniq | sed "s/$/;anonymous/" > $R_SCRATCHDIR/$file
		fi
		# empty tmplist
		tmplist=
		# advance counters
		if [ "$db_with_raterID" ]; then
			(( i += 3 ))
			(( ii += 3 ))
		else
			(( i += 2 ))
			(( ii += 2 ))
		fi
	done
	# now write the db to file
	if [ $DARWIN ]; then
		add_to_name converted-db-$(date "+%d-%m-%Y_%H.%M.%S").dat
	else
		add_to_name converted-db-$(date "+%d-%m-%Y_%H:%M:%S").dat
	fi
	for part in $(ls $R_SCRATCHDIR); do 
		echo "$part	$(tr '\n' '	' < $R_SCRATCHDIR/$part)" >> $SCRATCHDIR/newdb.csv
	done
	# tidy up the format, exclude responses with empty categorisation, and write to outfile
	sed -e 's/		/	/g' -e 's/_DOT_/./g' -e 's/	_/	/g' -e 's/_|/|/g' $SCRATCHDIR/newdb.csv | \
		sed $extended 's/	[[:upper:]]+\|;[[:lower:]]*//g'> "$output_filename"
	echo "converted database saved as \"$output_filename\"."
fi # this is the fi that ends the if dat_infile1 exists
# tidy up
if [ -z "$diagnostic" ]; then
	rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 &
fi
if [ "$do_not_ask" ]; then
	:
else
	# ask if directory should be opened
	echo ""
	read -p 'Would you like to open the output directory? (Y/n)' a
	if [ "$a" == "y" ] || [ "$a" == "Y" ] || [ -z "$a" ]; then
		if [ "$(grep 'Microsoft' <<< $platform)" ]; then
			explorer.exe `wslpath -w "$PWD"`
		elif [ "$(grep 'Darwin' <<< $platform)" ]; then
			open .
		else
			xdg-open .
		fi
	fi
fi
)
##################### end of administrator function ##################
#
############### end defining functions #####################
############################################################
# set terminal window to correct size
printf '\e[8;36;85t'
# initialise some variables
extended="-r"
ratID="-r" # rater ID to appear on output files
# check what platform we're under
platform=$(uname -v)
# and make adjustments accordingly
if [ "$(grep 'Microsoft' <<< $platform)" ]; then
	alias clear='printf "\033c"'
	echo "running under Windows Subsystem for Linux"
	WSL=true
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
	DARWIN=true
else
	LINUX=true
fi
# get directory of this script
startdir=$(dirname "${BASH_SOURCE[0]}")
# analyse options
while getopts dhV opt
do
	case $opt	in
	d)	diagnostic=true
		echo "Running in debug mode";sleep 1
		;;
	h)	help
		exit 0
		;;
	V)	echo "$(basename "$0")	-	version $version"
		echo "$copyright"
		exit 0
		;;
	esac
done
shift $((OPTIND -1))
# splash screen
printf "\033c"
echo "Word Association Data Processor - $copyright"
printf "\033c"
splash
until [ "$module" == "X" ]; do
	printf "\033c"
	splash
done
################ create two scratch directories
# first one to keep db sections in
#SCRATCHDIR1=$(mktemp -dt WADPXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
#if [ "$SCRATCHDIR1" == "" ] ; then
#	mkdir ${TMPDIR-/tmp/}WADPXXX.1$$
#	SCRATCHDIR1=${TMPDIR-/tmp/}WADPXXX.1$$
#fi
#if [ "$diagnostic" == true ]; then
#	open $SCRATCHDIR1 || xdg-open $SCRATCHDIR1 || explorer.exe `wslpath -w "$SCRATCHDIR1"`
#fi
# second one to keep other auxiliary and temporary files in
#SCRATCHDIR2=$(mktemp -dt WADPXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
#if [ "$SCRATCHDIR2" == "" ] ; then
#	mkdir ${TMPDIR-/tmp/}WADPXXX.1$$
#	SCRATCHDIR2=${TMPDIR-/tmp/}WADPXXX.1$$
#fi
#if [ "$diagnostic" == true ]; then
#	open $SCRATCHDIR2 || xdg-open $SCRATCHDIR2 || explorer.exe `wslpath -w "$SCRATCHDIR2"`
#fi
#if [ "$diagnostic" == true ]; then
#	:
#else
#	rm -r $SCRATCHDIR1
#	rm -r $SCRATCHDIR2
#fi
echo "This window can now be closed."
exit 0
