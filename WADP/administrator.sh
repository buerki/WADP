#!/bin/bash -

##############################################################################
# administrator.sh (c) ABuerki 2014
####
version="0.3.1"
# DESCRRIPTION: performs administrative functions on wa dbs and data files

################# defining functions ###############################

#######################
# define help function
#######################
help ( ) {
	echo "
DESCRRIPTION: $(basename $0) performs administrative functions on .dat files
              and .csv files containing word-association data
SYNOPSIS:     $(basename $0) DB.dat DB.dat

NOTE:         $(basename $0) -V for copyright and licensing information
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
		echo "$(cut -d '|' -f 1 <<< $difference|sed 's/							//g')|$new_cat;$rater_id" >> $R_SCRATCHDIR/$cue
		echo "------> resolved as: $(cut -d '|' -f 1 <<< $difference|sed 's/							//g')|$new_cat" >> $SCRATCHDIR/$log_name
		;;
esac
clear
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
while getopts dhvV opt
do
	case $opt	in
	d)	diagnostic=true
		;;
	h)	help
		exit 0
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
echo "			WORD ASSOCIATION DATA ADMINISTRATOR"
echo "			version $version"
echo 
echo 
echo 
echo 
echo 
echo 
echo 


################ checks on input files
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
	0|1)	echo "ERROR: no input files provided. Two .dat files must be provided as input." >&2
		exit 1
		;;
#	1)	if [ "$(echo "$1" | egrep '\.csv')" ]; then
#			# testing if $1 is a db file by looking for fields with first,
#			# second, tenth and fourteenth category of the variable allowed_categories
#			if [ -z "$(head -1 $1 | egrep ",\"*category\"*,")" ]; then
#				echo "ERROR: \"$1\" appears not to be a word-association data file with categories assigned. If a .csv file is provided, it must contain category assignments."
#				exit 1
#			fi
#			csv_in_filename=$1
#		elif [ "$(echo "$1" | egrep '\.dat')" ]; then
#			echo "ERROR: if .dat files are provided, two are needed." >&2
#			exit 1
#		else
#			echo "ERROR: $1 not recognised as valid imput file. Either a single .csv file or two .dat files must be provided as input." >&2
#		fi
#		;;
	2)	if [ "$(echo "$@" | egrep -o '\.dat' | wc -l)" -eq 2 ]; then
			dat_infile1=$1
			dat_infile2=$2
		else
			echo "ERROR: Two .dat files must be provided as input." >&2
			exit 1
		fi
		;;
	*)	echo "ERROR: more than two input files provided: $@" >&2
		exit 1
		;;
esac


################ create two scratch directories
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

# create name of rated WA output file
add_to_name categorised_$wa_in_filename
categorised_out=$output_filename

# initiating the log file
# create name for log file
add_to_name administrator-log.txt; log_name=$output_filename


################ menu for .dat .dat operations
if [ "$dat_infile1" ]; then
	echo "			What would you like to do?"
	echo "			(P)    produce a list of differences"
	echo "			(R)    resolve differences now"
	echo "			(C)    combine two databases into one"
	read -p '			' task
	case $task in
		P|p)	r_task=true
				list_only=true
			;;
		R|r)	r_task=true
			;;
		C|c)	c_task=true
			;;
		*)		echo "ERROR: $task is not a valid choice" >&2
				exit 1
	esac
	if [ "$r_task" ] && [ -z "$list_only" ]; then
		echo
		read -p '			Please enter your rater ID (or leave blank) and press ENTER: ' rater_id
		if [ -z "$rater_id" ]; then
			rater_id="anonymous"
		fi
	fi

################# processing dat files ###################

	# count cues in dat files
	total_cues1=$(wc -l < $dat_infile1 | tr '\r' '\n')
	total_cues2=$(wc -l < $dat_infile2 | tr '\r' '\n')
	# split db into response - category pairs per line in files named after cues
	while read line; do
		file=$(cut -f 1 <<< "$line" | sed 's/﻿//g')
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n' | sort)" \
		> $SCRATCHDIR1/$file
	done < $dat_infile1
	while read line; do
		file=$(cut -f 1 <<< "$line" | sed 's/﻿//g')
		echo "$(cut -f 2- <<< "$line" | tr '	' '\n' | sort)" \
		> $SCRATCHDIR2/$file
	done < $dat_infile2
	
	##### begin log file (the is relative to task, so 3 different ways)
	if [ "$list_only" ]; then
		date > $SCRATCHDIR/$log_name
		echo "Differences $dat_infile1 vs. $dat_infile2" >> $SCRATCHDIR/$log_name
		echo "-------------------------------------------------------------------------">> $SCRATCHDIR/$log_name
	elif [ "$r_task" ]; then
		# write an identifier line to the log
		echo "# administrator.sh-log - $(date)" > $SCRATCHDIR/$log_name
		echo "# Difference resolution" >> $SCRATCHDIR/$log_name
	else # that is, if c_task
		echo "# administrator.sh-log - $(date)" > $SCRATCHDIR/$log_name
		echo "# Combination of $dat_infile1 & $dat_infile2" >> $SCRATCHDIR/$log_name
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
		clear
		echo
		echo
		echo
		echo "$WARN The following cues differ:"|sed 's/^ //g' | tee -a $SCRATCHDIR/$log_name
		echo "$dat_infile1			vs.		  $dat_infile2" | tee -a $SCRATCHDIR/$log_name
		diff -y --suppress-common-lines $SCRATCHDIR/cues[12] |sed $extended -e 's/</*cue missing*		/g' -e 's/	+ *>/*cue missing*						/g'| tee -a $SCRATCHDIR/$log_name
		echo
		# move over cues only found in dat_infile1
		for single_cue in $(comm -23 $SCRATCHDIR/cues[12]); do
			mv $SCRATCHDIR1/$single_cue $R_SCRATCHDIR
			if [ -z "$list_only" ]; then echo "Responses and ratings for cue \"$single_cue\" will be copied to resolved list."
			fi
		done
		# move over cues only found in dat_infile2
		for single_cue in $(comm -13 $SCRATCHDIR/cues[12]); do
			mv $SCRATCHDIR2/$single_cue $R_SCRATCHDIR
			if [ -z "$list_only" ]; then echo "Responses and ratings for cue \"$single_cue\" will be copied to resolved list."
			fi
		done
		if [ -z "$list_only" ] && [ "$r_task" ]; then 
			read -p 'Continue? [Y/n]' r
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
			clear
			echo
			echo
			echo
			echo "$WARN The following responses to cue \"$cue\" differ:"|sed 's/^ //g' | tee -a $SCRATCHDIR/$log_name
			echo
			echo "$dat_infile1			vs.		  $dat_infile2" | tee -a $SCRATCHDIR/$log_name
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
				read -p 'Continue? [Y/n]' r
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
	##################### comparing categories
	# up to now we've sorted out cues and responses that do not have equivalents
	# in both files (i.e. are not shared), now we look at ratings (ie.categories
	# that may be identical or differ between the shared cues&responses
	clear
	if [ -z "$list_only" ] && [ "$r_task" ]; then
		echo
		echo
		echo
		echo "	Resolving differences in category ratings"
		echo "	$dat_infile1 vs. $dat_infile2"
		sleep 1
	fi
	for cue in $cues; do
		# first see if the whole cue (incl. responses & ratings) is entirely
		# identical (apart from the rater ID which is cut off)
		allcat1=$(cut -d ';' -f 1 $SCRATCHDIR1/$cue | sed 's/﻿//g' | sort)
		allcat2=$(cut -d ';' -f 1 $SCRATCHDIR2/$cue | sed 's/﻿//g' | sort)
		if [ "$allcat1" == "$allcat2" ]; then
			if [ -z "$list_only" ]; then
				# write cue to R_SCRATCHDIR and delete
				cat $SCRATCHDIR1/$cue >> $R_SCRATCHDIR/$cue
				rm $SCRATCHDIR1/$cue $SCRATCHDIR2/$cue
			fi
		else
		# if not, look at each rating in detail
			# take off rater IDs first
			cut -d ';' -f 1 $SCRATCHDIR1/$cue | sort > $SCRATCHDIR1/$cue.
			cut -d ';' -f 1 $SCRATCHDIR2/$cue | sort > $SCRATCHDIR2/$cue.
			# first write all identical responses&cats to R_SCRATCHDIR
			resp_done="$(comm -12 $SCRATCHDIR1/$cue. $SCRATCHDIR2/$cue. | tr '\n' '|' | sed $extended 's/\|$//g')"
			if [ "$resp_done" ]; then
				grep "^$resp_done;" $SCRATCHDIR1/$cue >> $R_SCRATCHDIR/$cue
				# note we are taking responses WITH rater IDs
				# now delete those done (different for r_task / c_task)
				if [ "$r_task" ]; then
				grep -v "^$resp_done$" $SCRATCHDIR1/$cue. > $SCRATCHDIR1/$cue
				rm $SCRATCHDIR1/$cue.
				grep -v "^$resp_done$" $SCRATCHDIR2/$cue. > $SCRATCHDIR2/$cue
				rm $SCRATCHDIR2/$cue.
				else # i.e. for c-task
				grep -v "^$resp_done;" $SCRATCHDIR1/$cue > $SCRATCHDIR1/$cue.
				mv $SCRATCHDIR1/$cue. $SCRATCHDIR1/$cue
				grep -v "^$resp_done;" $SCRATCHDIR2/$cue > $SCRATCHDIR2/$cue.
				mv $SCRATCHDIR2/$cue. $SCRATCHDIR2/$cue
				fi
			else
				if [ "$r_task" ]; then
					mv $SCRATCHDIR1/$cue. $SCRATCHDIR1/$cue # rm cues w/raterIDs
					mv $SCRATCHDIR2/$cue. $SCRATCHDIR2/$cue # rm cues w/raterIDs
				else
					rm $SCRATCHDIR1/$cue. # delete cues w/o rater IDs
					rm $SCRATCHDIR2/$cue. # delete cues w/o rater IDs
				fi
			fi
			# then display remaining differences, one by one
			diffs="$(diff -y --suppress-common-lines $SCRATCHDIR1/$cue $SCRATCHDIR2/$cue)"
			if [ "$diffs" ]; then
				warnings=true # flick switch to mark there were warnings
				echo >> $SCRATCHDIR/$log_name
				if [ "$r_task" ]; then
					echo "The following ratings for cue \"$cue\" differ:" >> $SCRATCHDIR/$log_name
				else # i.e. if c_task
					echo "WARNING: There are conflicts in ratings for cue \"$cue\"." | tee -a $SCRATCHDIR/$log_name
			echo "The left rating was transfered to the combined list." >> $SCRATCHDIR/$log_name
					echo "The ratings in \"$dat_infile1\" were transfered to the combined list. See log for details."
				fi
				sed $extended -e 's/		//g' -e 's/\|/vs./2' -e 's/	[[:upper:]]+_*[[:upper:]]*\|/	/g' -e 's/\|/	/g' -e 's/ +/	/g' -e 's/		/	/g' <<< "$diffs" >> $SCRATCHDIR/$log_name
				if [ -z "$list_only" ] && [ "$r_task" ]; then
					clear
					old_IFS=$IFS  # save the field separator           
					IFS=$'\n'     # new field separator, the end of line  
					for difference in $diffs; do
						resolution_menu
					done
					IFS=$old_IFS     # restore default field separator
				else # i.e. if c_task
					echo | tee -a $SCRATCHDIR/$log_name
					cut -f 1 <<< "$diffs" >> $R_SCRATCHDIR/$cue
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
		# ending routine
		read -t 60 -p 'Would you like to output the log file? [y/N]' r
		if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
			mv $SCRATCHDIR/$log_name $log_name || echo "ERROR: could not find log."
			echo "Log file \"$log_name\" placed in $(pwd)."
		fi
	elif [ "$list_only" ]; then
		add_to_name difference_report.txt
		mv $SCRATCHDIR/$log_name $output_filename
		clear
		cat $output_filename
		echo 
		echo
		echo "Report named \"$output_filename\" saved in $(pwd)."
	else # i.e. if c_task
		add_to_name combined-db-$(date "+%d-%m-%Y%n").dat
		for part in $(ls $R_SCRATCHDIR); do 
			echo "$part	$(tr '\n' '	' < $R_SCRATCHDIR/$part)" >> $output_filename
		done
		echo "combined database saved as \"$output_filename\"."
		# ending routine
		if [ "$warnings" ]; then
			mv $SCRATCHDIR/$log_name $log_name || echo "ERROR: could not find log."
			echo "Log file \"$log_name\" placed in $(pwd)."
		else
			read -t 60 -p 'Would you like to output the log file? [y/N]' r
			if [ "$r" == "Y" ] || [ "$r" == "y" ]; then
				mv $SCRATCHDIR/$log_name $log_name || echo "ERROR: could not find log."
				echo "Log file \"$log_name\" placed in $(pwd)."
			fi
		fi
	fi
fi # this is the fi that ends the if dat_infile1 exists

# tidy up
if [ -z "$diagnostic" ]; then
	rm -r $SCRATCHDIR $SCRATCHDIR1 $SCRATCHDIR2 &
fi