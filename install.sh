#!/bin/bash -
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin" # needed for Cygwin
##############################################################################
# installer 
copyright='(c) 2015-2021 Cardiff University'
# licensed under the EUPL v1.2 or later.
# written by Andreas Buerki
version="1.0.1"
####
## set installation variables
export title="WADP"
export components="WADP.sh"
export DESTINATION="${HOME}/bin" # "/usr/local/bin"
#export DESTINATION2="${HOME}/bin" # for Windows Subsystem for Linux (WSL) files
export WSL_only="wicon.ico"
export linux_only="wicon.png"
export osx_only="WADP.sh"
export licence="European Union Public Licence (EUPL) v1.2 or later."
export URL="https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12"
setting_path_required=""
# define functions
help ( ) {
	echo "
Usage: $(basename $(sed 's/ //g' <<<$0))  [OPTIONS]
IMPORTANT: this script should not be moved to a different location or it will not find its payload
Example: $(basename $(sed 's/ //g' <<<$0))  -u
Options:   -u	uninstalls the software
           -V   displays version information
           -p   only attempts to set path
"
}
# analyse options
while getopts dhpuV opt
do
	case $opt	in
	d)	diagnostic=TRUE
		;;
	h)	help
		exit 0
		;;
	u)	uninstall=TRUE
		;;
	p)	pathonly=TRUE
		;;
	V)	echo "$(basename $(sed 's/ //g' <<<$0))	-	version $version"
		echo "Copyright $copyright"
		echo "$licence"
		echo "written by Andreas Buerki"
		exit 0
		;;
	esac
done
echo ""
echo "Installer"
echo "---------"
echo ""
if [ "$diagnostic" ]; then
	echo "pwd is $(pwd)"
	echo "current path is $PATH"
	echo "home: $HOME"
fi
# check what platform we're under
platform=$(uname -v)
# and make adjustments accordingly
if [ "$(grep 'Microsoft' <<< $platform)" ]; then
	WSL=TRUE
	# check if $HOME contains spaces
	#if [ "$(grep ' ' <<<"$HOME")" ]; then
	#	echo "WARNING: Your Cygwin installation user name contains one or more spaces." >&2
	#fi
elif [ "$(grep 'Darwin' <<< $platform)" ];then
	DARWIN=TRUE
else
	# assume a flavour of Linux
	LINUX=TRUE
fi
# ascertain source directory
# export sourcedir="$(dirname "$0")"
export sourcedir=$(dirname "${BASH_SOURCE[0]}")
if [ "$diagnostic" ]; then 
	echo "sourcedir is $sourcedir"
fi
#if [ "$(grep '^\.' <<<"$sourcedir")" ] || [ "$LINUX" ] && [ -z "$(grep 'src' <<<"$sourcedir")" ]; then
#	sourcedir="$(pwd)/src"
#else
#	echo "ERROR: it seems this script was moved outside its original folder." >&2
#	echo "       please move it back into that folder and try again." >&2
#fi
if [ "$diagnostic" ]; then 
	echo "platform is $platform"
	echo "sourcedir is $sourcedir"
	echo "0 is $0"
	echo "dirname is $(dirname "$0")"
fi
###########
# getting agreement on licence
###########
if [ "$uninstall" ]; then
	:
else
	echo "This software is licensed under the open-source"
	echo "$licence"
	echo "The full licence is found at"
	echo "$URL"
	echo "or in the accompanying licence file."
	echo "Before installing and using the software, we ask"
	echo "that you agree to the terms of this licence."
	echo "If you agree, please type 'agree' and press ENTER,"
	echo "otherwise just press ENTER."
	read -p '> ' d < /dev/tty
	if [ "$d" != "agree" ]; then
		echo
		echo "Since the installation and use of this software requires"
		echo "agreement to the licence, installation cannot continue."
		sleep 2
		exit 1
	else
		echo "Thank you."
	fi
fi
###########
# setting path
###########
if [ "$uninstall" ]; then
	echo "path needs to be uninstalled manually."
else
	if [ "$setting_path_required" ]; then
		# set path
		# from now on, commands are executed from a subshell with -l (login) 
		# option (needed for Cygwin)
		bash -lc 'if [ "$(egrep -o "$DESTINATION" <<<$PATH)" ]; then
			echo "Path already set."
		elif [ -e ~/.bash_profile ]; then
			cp "${HOME}/.bash_profile" "${HOME}/.bash_profile.bkup"
			echo "">> "${HOME}/.bash_profile"
			echo "export PATH="\${PATH}:\"$DESTINATION\""">> "${HOME}/.bash_profile"
			echo "Setting path in ~/.bash_profile"
			echo "Logout and login may be required before new path takes effect."
		else
			cp "${HOME}/.profile" "${HOME}/.profile.bkup"
			echo "">> "${HOME}/.profile"
			echo "export PATH="$\{PATH}:$DESTINATION"">> "${HOME}/.profile"
			echo "Setting path in ~/.profile"
			echo "Logout and login may be required before new path takes effect."
		fi'
	fi
	if [ "$pathonly" ]; then
		exit 0
	fi
fi
###########
# removing old installations
###########
echo "Checking for existing installations..."
for file in $components; do
	existing="$(which $file 2>/dev/null)"
	if [ "$existing" ]; then
		echo "removing $existing"
		rm -f "$existing" 2>/dev/null || sudo rm "$existing"
		if [ "$WSL" ]; then
			echo "removing $DESTINATION$WSL_only"
		elif [ "$LINUX" ]; then
			echo "removing $HOME/.icons/$linux_only"
		fi
	else
		echo "no existing installation found."
		break
	fi
	# remove programme file in $HOME/bin
	# rm -f "$HOME/bin/$file" 2>/dev/null
done
if [ "$existing" ]; then
	echo "removing icons"
	if [ "$WSL" ]; then
		rm "$DESTINATION$WSL_only" 2>/dev/null
		rm /mnt/c/Users/"$USER"/Desktop/WADP.lnk 2>/dev/null
	elif [ "$DARWIN" ]; then
		rm -r /Applications/$osx_only 2>/dev/null
		rm -r $HOME/Desktop/$osx_only 2>/dev/null
	else
		rm "$HOME/.icons/$linux_only" 2>/dev/null
		rm $HOME/Desktop/WADP.desktop 2>/dev/null
	fi
fi
if [ "$uninstall" ]; then
	echo "Uninstall completed. This window can now be closed."
	sleep 5
	exit 0
fi
###############
# install files
###############
echo ""
echo "Installing files to $DESTINATION"
mkdir -p "$DESTINATION"
for file in $components; do
	chmod a+x "$sourcedir/$file"
	# making sure no unrelated files are accidentally overwritten
	#if [ -e "$DESTINATION/$file" ]; then
	#	echo "A file named $file already exists in the destination directory."
	#	echo "It was renamed $file-1"
	#	mv "$DESTINATION/$file" "$DESTINATION/$file-1"
	#fi
	cp "$sourcedir/$file" "$DESTINATION/" || problem=TRUE
	if [ "$problem" ]; then
		echo "Installation encountered problems. Manual installation may be required." >&2
		echo "failing command: cp "$sourcedir/$file" "$DESTINATION/"" >&2
		sleep 10	
		exit 1
	fi
done
if [ "$WSL" ]; then
	cp "$sourcedir/$WSL_only" "$DESTINATION"
elif [ "$DARWIN" ]; then
	:
else
	mkdir $HOME/.icons 2>/dev/null
	cp "$sourcedir/$linux_only" $HOME/.icons
fi
echo "The following files were placed in $DESTINATION:"
echo "$components" | tr ' ' '\n'
if [ "$WSL" ]; then echo "$WSL_only"; fi
echo ""
if [ "$LINUX" ]; then echo "$linux_only placed in $HOME/.icons";fi
#######################################
# create Windows shortcuts if under WSL
#######################################
if [ "$WSL" ]; then
	cd "$sourcedir" 2>/dev/null
	echo "installing shortcut... [please wait]"
	wslusc -n WADP -i "${HOME}/bin/wicon.ico" "$DESTINATION/WADP.sh"
	echo "Created Windows shortcut on the Desktop."
	cd - 2>/dev/null
	echo ""
	echo "Installation complete."
	echo "To start WADP, double-click on the WADP shortcut."
	echo "Feel free to move it anywhere convenient."
################################
# create launcher if under Linux
################################
elif [ "$LINUX" ]; then
	echo "[Desktop Entry]
Version=0.4
Encoding=UTF-8
Type=Application
Name=WADP
Comment=
Categories=Application;
Exec=$DESTINATION/WADP.sh
Icon=wicon
Terminal=true
StartupNotify=false" > "$HOME/Desktop/WADP.desktop"
	chmod a+x "$HOME/Desktop/WADP.desktop"
	gio set "$HOME/Desktop/WADP.desktop" metadata::trusted true
	echo ""
	echo "Installation complete."
	echo "To start WADP, double-click on the WADP launcher."
#####################
# create app on MacOS (this no longer works)
#####################
#elif [ "$DARWIN" ]; then
#	cp -r "$sourcedir/$osx_only" /Applications/WADP.command || sudo cp -r "$sourcedir/$osx_only" /Applications/WADP.command 
#	#cp -r "$sourcedir/$osx_only" "$(dirname "$sourcedir")/WADP.command"
#	echo "The application WADP was placed in your Applications folder."
#	read -t 10 -p 'Create icon on the desktop? (Y/n) ' d < /dev/tty
#	if [ "$d" == "y" ] || [ "$d" == "Y" ] || [ -z "$d" ]; then
#		cp -r "$sourcedir/$osx_only" $HOME/Desktop/WADP.command
#	fi
#	echo "Installation complete."
#	echo
#	echo "To start WADP, double-click on the WADP icon in your Applications folder $(if [ -e "$HOME/Desktop/$osx_only" ]; then echo "or on your desktop";fi)."
#	echo "Feel free to move it anywhere convenient."
#	echo "This window can now be closed."
fi
sleep 10
echo "This window can now be closed."
