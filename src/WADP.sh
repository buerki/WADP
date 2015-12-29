#!/bin/bash -
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:"$HOME/bin"" # needed for Cygwin
##############################################################################
# WADP.sh (c) 2015 Cardiff University
# written by Andreas Buerki
####
version="0.6"
# DESCRRIPTION: processes word-association data
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
echo "WADP (c) 2015 Cardiff University - Licensed under the EUPL v. 1.1"
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
read -p '           ' module  < /dev/tty
case $module in
C|c)	echo "loading categoriser module ..."
	run_categoriser
	;;
R|r)	echo "loading reporter module ..."
	run_reporter
	;;
A|a)	echo "loading administrator module ..."
	run_administrator
	;;
X|x)	echo "This window can now be closed"; exit 0
	;;
*)	echo "$module is not a valid choice."
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
read -p '           ' infile  < /dev/tty
# get rid of any single quotation marks that might have attached
export infile="$(sed "s/'//g" <<<"$infile")"
if [ -z "$infile" ]; then
	echo "A data file to be categorised must be provided. Please drop the file into this window."
	read -p '           ' infile  < /dev/tty
	if [ -z "$infile" ]; then
		echo "No data file provided. Exiting." >&2
		return
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
read -p '           ' database  < /dev/tty
# get rid of single quotation marks
export database="$(sed "s/'//g" <<<"$database")"
printf "\033c"
echo
echo
echo
echo
echo
read -p '           Would you like rater IDs to appear in the rated output file? (Y/n)' ratID  < /dev/tty
if [ "$ratID" == "Y" ] || [ "$ratID" == "y" ] || [ -z "$ratID" ]; then
	ratID="-r"
else
	ratID=
fi
# sort out potential cygwin problems
if [ "$CYGWIN" ]; then
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
			echo "categoriser.sh -a $ratID $database $infile"
			read -p 'press ENTER to continue ' xxx < /dev/tt
		fi
		"$HOME/bin/categoriser.sh" -a $ratID "$database" "$infile"
	else
		if [ "$diagnostic" ]; then
			echo "categoriser.sh -a $ratID $infile"
			read -p 'press ENTER to continue ' xxx < /dev/tt
		fi
		"$HOME/bin/categoriser.sh" -a $ratID "$infile"
	fi
else
	if [ "$database" ]; then
		"$HOME/bin/categoriser.sh" -a $ratID "$database" "$infile"
	else
		"$HOME/bin/categoriser.sh" -a $ratID "$infile"
	fi
fi
}
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
echo "          Drag the data file to report on into this window and press ENTER."
echo 
read -p '           ' infile  < /dev/tty
# get rid of any single quotation marks that might have attached
export infile="$(sed "s/'//g" <<<"$infile")"
if [ -z "$infile" ]; then
	echo "A data file must be provided. Please drop the file into this window."
	read -p '           ' infile  < /dev/tty
	if [ -z "$infile" ]; then
		echo "No data file provided. Exiting." >&2
		return
	fi
fi
# change dir to that of the in-file
export working_dirname="$(dirname "$infile" | sed "s/'//g")"
cd "$working_dirname" 2>/dev/null || dirfail=true
if [ "$diagnostic" ]; then 
	echo "now in $(pwd). dirname is $working_dirname"
	read -p 'press ENTER to continue ' xxx < /dev/tt
fi
"$HOME/bin/reporter.sh" -a "$infile"
}
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
echo "          (T)    turn rated csv file into a database"
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
	read -p '           ' database1  < /dev/tty
	if [ -z "$database1" ]; then
		echo "A csv file must be provided. Please drop the file into this window."
		read -p '           ' database1  < /dev/tty
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
	read -p '           ' database1  < /dev/tty
	if [ -z "$database1" ]; then
		echo "A database file must be provided. Please drop the file into this window."
		read -p '           ' database1  < /dev/tty
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
	read -p '           ' database2  < /dev/tty
	if [ -z "$database2" ]; then
		echo "A database file must be provided. Please drop the file into this window."
		read -p '           ' database2  < /dev/tty
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
	"$HOME/bin/administrator.sh" -a "$database1"
else
	# check if there are differences in the databases
	if [ "$(diff -q "$database1" "$database2")" ]; then
		# call administrator.sh -a with 2 database files are arguments
		if [ "$c_task" ]; then
			"$HOME/bin/administrator.sh" -ac "$database1" "$database2"
		elif [ "$r_task" ]; then
			"$HOME/bin/administrator.sh" -ar "$database1" "$database2"
		else
			"$HOME/bin/administrator.sh" -ap "$database1" "$database2"
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
############### end defining functions #####################

# initialise some variables
extended="-r"
# check what platform we're under
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	alias clear='printf "\033c"'
	echo "running under Cygwin"
	CYGWIN=true
elif [ "$(grep 'Darwin' <<< $platform)" ]; then
	extended="-E"
	DARWIN=true
else
	LINUX=true
fi
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
		echo "(c) 2015 Cardiff University - Licensed under the EUPL v. 1.1"
		exit 0
		;;
	esac
done
shift $((OPTIND -1))
# splash screen
printf "\033c"
echo "Word Association Data Processor - (c) 2015 Cardiff University - licensed under the EUPL v.1.1."
printf "\033c"
splash
sleep 5
until [ "$module" == "X" ]; do
	printf "\033c"
	splash
	sleep 5
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
#	open $SCRATCHDIR1
#fi
# second one to keep other auxiliary and temporary files in
#SCRATCHDIR2=$(mktemp -dt WADPXXX) 
# if mktemp fails, use a different method to create the SCRATCHDIR
#if [ "$SCRATCHDIR2" == "" ] ; then
#	mkdir ${TMPDIR-/tmp/}WADPXXX.1$$
#	SCRATCHDIR2=${TMPDIR-/tmp/}WADPXXX.1$$
#fi
#if [ "$diagnostic" == true ]; then
#	open $SCRATCHDIR2
#fi
#if [ "$diagnostic" == true ]; then
#	:
#else
#	rm -r $SCRATCHDIR1
#	rm -r $SCRATCHDIR2
#fi
exit 0