#!/bin/bash -
##############################################################################
# administrator.sh (c) 2015 Cardiff University
# written by Andreas Buerki
####
version="0.5"
# DESCRRIPTION: performs administrative functions on wa dbs and data files
################# defining functions ###############################

#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename "$0") performs administrative functions on .dat files
              and .csv files containing word-association data
SYNOPSIS:     $(basename "$0") DB.dat DB.dat

NOTE:         $(basename "$0") -V for copyright and licensing information
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
echo
echo 	
echo
echo "	cue: $cue"
echo
sed $extended -e 's/</*response missing*/' -e 's/>/*response missing*/' -e 's/		//g' -e 's/\|/ -> /' -e 's/\|/ vs. /' -e 's/\|/ -> /' -e 's/^/	/' <<< "$difference"
# following menu items are conditional so no empty side can be chosen
if [ -z "$(egrep '>' <<< "$difference")" ]; then echo "	(L)	choose left";fi
if [ -z "$(egrep '<' <<< "$difference")" ]; then echo "	(R)	choose right";fi
echo "	(N)	input new category assignment"
echo "	(D)	discard both ratings"
read -p '	' r
case $r in
	l|L)	echo "$(cut -f 1 <<< $difference);$rater_id" >> $R_SCRATCHDIR/$cue
			echo "------> resolved as: $(cut -f 1 <<< $difference)" >> $SCRATCHDIR/$log_name
		;;
	r|R)	echo "$(cut -d '|' -f 3-4 <<< $difference|sed 's/	//g');$rater_id" >> $R_SCRATCHDIR/$cue
			echo "------> resolved as: $(cut -d '|' -f 3-4 <<< $difference|sed 's/	//g')" >> $SCRATCHDIR/$log_name
		;;
	d|D)	echo "	discarding those ratings..."
			echo "------> deleted" >> $SCRATCHDIR/$log_name
		;;
	*)	read -p '	Enter new category here: ' new_cat
		new_cat="$(tr '[[:lower:]]' '[[:upper:]]' <<<"$new_cat")"
		echo "$(cut -d '|' -f 1 <<< $difference|sed 's/							//g')|$new_cat;$rater_id" >> $R_SCRATCHDIR/$cue
		echo "------> resolved as: $(cut -d '|' -f 1 <<< $difference|sed 's/							//g')|$new_cat" >> $SCRATCHDIR/$log_name
		;;
esac
printf "\033c"
}
################## end defining functions ########################
# initialise some variables
extended="-r"
# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	:
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
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
	echo "Word Association Data Processor - (c) 2015 Cardiff Universitiy - licensed under the EUPL v.1.1."
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
		else
			echo "ERROR: could not access file $1" >&2
			exit 1
		fi
		if [ "$(egrep -o '\.csv' <<<"$1")" ]; then
			csv_infile="$1"
			csv_infile_name="$(basename "$csv_infile")"
		else
			echo "ERROR: if one file is provided, it must be a .csv file." >&2
			exit 1
		fi
		;;
	2)	if [ -s "$1" ] && [ -s "$2" ]; then
			:
		else
			echo "ERROR: could not access file(s) $1 and/or $2" >&2
			exit 1
		fi
		if [ "$(egrep -o '\.dat' <<<"$1")" ] && [ "$(egrep -o '\.dat'<<<"$2")" ]; then
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
	open $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR
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
				P|p)	r_task=true
						list_only=true
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
	fi
	if [ "$r_task" ] && [ -z "$list_only" ]; then
		echo
		read -p 'Please enter your rater ID (or leave blank) and press ENTER: ' rater_id
		if [ -z "$rater_id" ]; then
			rater_id="anonymous"
		fi
	fi
################# processing dat files ###################
	# count cues in dat files
	total_cues1=$(wc -l < "$dat_infile1" | tr '\r' '\n')
	total_cues2=$(wc -l < "$dat_infile2" | tr '\r' '\n')
	# split db into response - category pairs per line in files named after cues
	while read line; do
		file=$(cut -f 1 <<< "$line" | sed 's/﻿//g')
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n' | sort)" \
		> $SCRATCHDIR1/$file
	done < "$dat_infile1"
	while read line; do
		file=$(cut -f 1 <<< "$line" | sed 's/﻿//g')
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n' | sort)" \
		> $SCRATCHDIR2/$file
	done < "$dat_infile2"
	##### begin log file (the is relative to task, so 3 different ways)
	if [ "$list_only" ]; then
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
	if [ -z "$list_only" ] && [ "$r_task" ]; then
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
		diff -y --suppress-common-lines $SCRATCHDIR/cues[12] |sed $extended -e 's/</*cue missing*		/g' -e 's/	+ *>/*cue missing*						/g'| tee -a $SCRATCHDIR/$log_name
		echo
		# move cues only found in dat_infile1 to results
		for single_cue in $(comm -23 $SCRATCHDIR/cues[12]); do
			mv $SCRATCHDIR1/$single_cue $R_SCRATCHDIR
			if [ -z "$list_only" ]; then echo "Responses and ratings for cue \"$single_cue\" will be copied to resolved list."
			fi
		done
		# move cues only found in dat_infile2 to results
		for single_cue in $(comm -13 $SCRATCHDIR/cues[12]); do
			mv $SCRATCHDIR2/$single_cue $R_SCRATCHDIR
			if [ -z "$list_only" ]; then echo "Responses and ratings for cue \"$single_cue\" will be copied to resolved list."
			fi
		done
		if [ -z "$list_only" ] && [ "$r_task" ]; then 
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
		diff -y --suppress-common-lines $SCRATCHDIR/cues[12] | tee -a $SCRATCHDIR/$log_name
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
			echo
			echo "$WARN The following responses to cue \"$cue\" differ:"|sed 's/^ //g' | tee -a $SCRATCHDIR/$log_name
			echo
			echo "$dat_infile1_name			vs.		  $dat_infile2_name" | tee -a $SCRATCHDIR/$log_name
			sort <<< "$resp1" | sed '/^$/d' > $SCRATCHDIR/resp1
			sort <<< "$resp2" | sed '/^$/d' > $SCRATCHDIR/resp2
			diff -y --suppress-common-lines $SCRATCHDIR/resp[12] | sed $extended -e 's/</*reponse missing*/g' -e 's/	+ *>/*response missing*					/'| tee -a $SCRATCHDIR/$log_name
			# copy over responses only found in dat_infile1
			for single_resp in $(comm -23 $SCRATCHDIR/resp[12]); do
				# copy it over and remove it
				egrep "^$single_resp\|" $SCRATCHDIR1/$cue >> $R_SCRATCHDIR/$cue
				egrep -v "^$single_resp\|" $SCRATCHDIR1/$cue >$SCRATCHDIR1/$cue.
				mv $SCRATCHDIR1/$cue. $SCRATCHDIR1/$cue
				if [ -z "$list_only" ] && [ "$r_task" ]; then echo "Ratings for response \"$single_resp\" will be copied to resolved list."
				fi
			done
			# move over responses only found in dat_infile2
			for single_resp in $(comm -13 $SCRATCHDIR/resp[12]); do
				# copy it over and remove it
				egrep "^$single_resp\|" $SCRATCHDIR2/$cue >> $R_SCRATCHDIR/$cue
				egrep -v "^$single_resp\|" $SCRATCHDIR2/$cue >$SCRATCHDIR2/$cue.
				mv $SCRATCHDIR2/$cue. $SCRATCHDIR2/$cue
				if [ -z "$list_only" ] && [ "$r_task" ]; then echo "Ratings for response \"$single_resp\" will be copied to resolved list."
				fi
			done
			if [ -z "$list_only" ] && [ "$r_task" ]; then
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
			diff -y --suppress-common-lines $SCRATCHDIR/resp[12] | tee -a $SCRATCHDIR/$log_name
			echo "cannot continue."
			if [ -z "$diagnostic" ]; then
				rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 $R_SCRATCHDIR &
			fi
			exit 1
		fi
	done
	##################### comparing ratings
	# up to now we've sorted out cues and responses that do not have equivalents
	# in both files (i.e. are not shared), now we look at ratings (ie.categories
	# that may be identical or differ between the shared cues&responses
	printf "\033c"
	if [ -z "$list_only" ] && [ "$r_task" ]; then
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
			if [ -z "$list_only" ]; then
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
				sed $extended -e 's/		//g' -e 's/\|/vs./2' -e 's/	[[:upper:]]+_*[[:upper:]]*\|/	/g' -e 's/\|/	/g' -e 's/ +/	/g' -e 's/		/	/g' <<< "$diffs" >> $SCRATCHDIR/$log_name
				# now write resolved/combined ratings to results
				if [ -z "$list_only" ] && [ "$r_task" ]; then
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
	#### write new db file (this is tab delimited with one cue per line)
	if [ -z "$list_only" ] && [ "$r_task" ]; then
		add_to_name resolved-db-$(date "+%d-%m-%Y%n").dat
		for part in $(ls $R_SCRATCHDIR); do 
			echo "$part	$(tr '\n' '	' < $R_SCRATCHDIR/$part)" | sed '/^$/d'>> $output_filename
		done
		echo "Resolved database saved as \"$output_filename\"." | tee -a $SCRATCHDIR/$log_name
		# undo any cygwin damage
		if [ "$CYGWIN" ]; then
			conv -U "$output_filename" 2>/dev/null
		fi
		# ending routine
		read -t 60 -p 'Would you like to output the log file? (y/N)' r
		if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
			mv $SCRATCHDIR/$log_name $log_name || echo "ERROR: could not find log."
			echo "Log file \"$log_name\" placed in $(pwd)."
		fi
	elif [ "$list_only" ]; then
		printf "\033c"
		cat $SCRATCHDIR/$log_name
		echo 
		echo
		read -t 60 -p 'Save this report to file? (y/N)' r
		if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
			add_to_name difference_report.txt
			mv $SCRATCHDIR/$log_name $output_filename
			echo "Report named \"$output_filename\" saved in $(pwd)."
		else
			do_not_ask=true
		fi
	else # i.e. if c_task
		add_to_name combined-db-$(date "+%d-%m-%Y%n").dat
		for part in $(ls $R_SCRATCHDIR); do 
			echo "$part	$(tr '\n' '	' < $R_SCRATCHDIR/$part)" >> "$output_filename"
		done
		echo "combined database saved as \"$output_filename\"."
		# ending routine
		if [ "$warnings" ]; then
			mv $SCRATCHDIR/$log_name $log_name || echo "ERROR: could not find log."
			echo "Log file \"$log_name\" placed in $(pwd)."
		else
			read -t 60 -p 'Would you like to output the log file? (y/N)' r
			if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
				mv $SCRATCHDIR/$log_name $log_name || echo "ERROR: could not find log."
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
	sed $extended -e 's/\|/PIPE/g' -e 's/\"\"//g' -e 's/(([^\",]+)|(\"[^\"]+\")|(\"\")|(\"[^\"]+\"\"[^"]+\"\"[^\"]+\")+)/\1\|/g' -e 's/\|$//g' -e 's/\|,/\|/g' -e 's/,,/\|\|/g' -e 's/\|,/\|\|/g' -e 's/^,/\|/g' -e 's/\"//g' "$csv_infile_name" |\
	sed -e 's/ /_/g' -e 's/\-/–/g' -e 's/\./_DOT_/g' -e 's=/=_SLASH_=g' -e "s/'/_APOSTROPHE_/g" -e 's/\`//g' -e 's/\[/_LBRACKET_/g' -e 's/(/_LBRACKET_/g' -e 's/)/_RBRACKET_/g' -e 's/\]/_RBRACKET_/g' -e 's/\*/_ASTERISK_/g' -e 's/+/_PLUS_/g' | tr '\r' '\n' > $SCRATCHDIR/db.csv
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
	if [ "$(head -1 <<< "$db" | egrep -o "[[:upper:]]*[[:lower:]]+\|category" | wc -l)" -ne "$db_total_cues" ]; then
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
	add_to_name converted-db-$(date "+%d-%m-%Y%n").dat
	for part in $(ls $R_SCRATCHDIR); do 
		echo "$part	$(tr '\n' '	' < $R_SCRATCHDIR/$part)" >> "$output_filename"
	done
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
	read -p 'Would you like to open the output directory? (Y/n)' a  < /dev/tty
	if [ "$a" == "y" ] || [ "$a" == "Y" ] || [ -z "$a" ]; then
		if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
			cygstart .
		elif [ "$(grep 'Darwin' <<< $platform)" ]; then
			open .
		else
			xdg-open .
		fi
	fi
fi