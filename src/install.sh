#!/bin/bash -
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin" # needed for Cygwin
##############################################################################
# installer 
copyright='(c) 2015-2018 Cardiff University' # licensed under the EUPL V.1.1.
# written by Andreas Buerki
version="0.7.2"
####
## set installation variables
export title="WADP"
export components="WADP.sh categoriser.sh reporter.sh administrator.sh"
export DESTINATION="${HOME}/bin"
export DESTINATION2="/" # for cygwin-only files
export cygwin_only="wicon.ico"
export linux_only="wicon.png"
export osx_only="WADP.command"
export licence="European Union Public Licence (EUPL) v. 1.1."
export URL="https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11"
# define functions
help ( ) {
	echo "
Usage: $(basename $(sed 's/ //g' <<<$0))  [OPTIONS]
Example: $(basename $(sed 's/ //g' <<<$0))  -u
IMPORTANT: this script should not be moved outside of its original directory.
           (it will stop working if it is moved)
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
		echo "licensed under the EUPL V.1.1"
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
platform=$(uname -s)
# and make adjustments accordingly
if [ "$(grep 'CYGWIN' <<< $platform)" ]; then
	CYGWIN=TRUE
	bash -lc 'export USERNAME="$USERNAME"'
	# check if $HOME contains spaces
	if [ "$(grep ' ' <<<"$HOME")" ]; then
		echo "WARNING: Your Cygwin installation user name contains one or more spaces." >&2
	fi
elif [ "$(grep 'Darwin' <<< $platform)" ];then
	DARWIN=TRUE
elif [ "$(grep 'Linux' <<< $platform)" ]; then
	LINUX=TRUE
else
	# probably some flavour of Linux
	LINUX=TRUE
fi
# ascertain source directory
export sourcedir="$(dirname "$0")"
if [ "$(grep '^\.' <<<"$sourcedir")" ] || [ "$LINUX" ]; then
	sourcedir="$(pwd)/src"
fi
if [ "$diagnostic" ]; then 
	echo "platform is $platform"
	echo "sourcedir is $sourcedir"
	echo "0 is $0"
	echo "dirname is $(dirname "$0")"
fi
# check it's in its proper directory
if [ "$(grep "$title" <<<"$sourcedir")" ]; then
	:
else
	echo "This installer script appears to have been moved out of its original directory. Please move it back into the $title directory and run it again." >&2
	sleep 2
	exit 1
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
	# set path
	# from now on, commands are executed from a subshell with -l (login) 
	# option (needed for Cygwin)
	bash -lc 'if [ "$(egrep -o "$HOME/bin" <<<$PATH)" ]; then
		echo "Path already set."
	elif [ -e ~/.bash_profile ]; then
		cp "${HOME}/.bash_profile" "${HOME}/.bash_profile.bkup"
		echo "">> "${HOME}/.bash_profile"
		echo "export PATH="\${PATH}:\"${HOME}/bin\""">> "${HOME}/.bash_profile"
		echo "Setting path in ~/.bash_profile"
		echo "Logout and login may be required before new path takes effect."
	else
		cp "${HOME}/.profile" "${HOME}/.profile.bkup"
		echo "">> "${HOME}/.profile"
		echo "export PATH="$\{PATH}:${HOME}/bin"">> "${HOME}/.profile"
		echo "Setting path in ~/.profile"
		echo "Logout and login may be required before new path takes effect."
	fi'
	if [ "$pathonly" ]; then
		exit 0
	fi
fi
###########
# removing old installations
###########
bash -lc 'echo "Checking for existing installations..."
for file in $components; do
	existing="$(which $file 2>/dev/null)"
	if [ "$existing" ]; then
		echo "removing $existing"
		rm -f "$existing" 2>/dev/null || sudo rm "$existing"
		if [ "$CYGWIN" ]; then
			echo "removing $DESTINATION2$cygwin_only"
		elif [ "$LINUX" ]; then
			echo "removing $HOME/.icons/$linux_only"
		fi
	fi
	# remove programme file in $HOME/bin
	rm -f "$HOME/bin/$file" 2>/dev/null
	existing=""
done'
if [ "$CYGWIN" ]; then
	rm "$DESTINATION2$cygwin_only" 2>/dev/null
	rm /cygdrive/c/Users/"$USERNAME"/Desktop/WADP.lnk 2>/dev/null
elif [ "$DARWIN" ]; then
	rm -r /Applications/$osx_only 2>/dev/null
	rm -r $HOME/Desktop/$osx_only 2>/dev/null
	rm -r /Applications/WADP.app 2>/dev/null
	rm -r $HOME/Desktop/WADP.app 2>/dev/null
else
	rm "$HOME/.icons/$linux_only" 2>/dev/null
	rm $HOME/Desktop/WADP.desktop 2>/dev/null
fi
echo "removing icons"
if [ "$uninstall" ]; then
	echo "Uninstall completed. This window can now be closed."
	sleep 5
	exit 0
fi
# install files
echo ""
echo "Installing files to $HOME/bin"
mkdir -p "$DESTINATION"
for file in $components; do
	cp "$sourcedir/$file" "$DESTINATION/" || problem=TRUE
	if [ "$problem" ]; then
		echo "Installation encountered problems. Manual installation may be required." >&2
		exit 1
	fi
done
if [ "$CYGWIN" ]; then
	cp "$sourcedir/$cygwin_only" "$DESTINATION2"
elif [ "$DARWIN" ]; then
	:
else
	mkdir $HOME/.icons 2>/dev/null
	cp "$sourcedir/$linux_only" $HOME/.icons
fi

echo "The following files were placed in $HOME/bin:"
echo "$components $(if [ "$CYGWIN" ]; then echo "$cygwin_only"; elif [ "$DARWIN" ]; then :;else echo "$linux_only placed in $HOME/.icons";fi)" | tr ' ' '\n'
echo ""
# create Windows shortcuts if under cygwin
if [ "$CYGWIN" ]; then
	cd "$sourcedir" 2>/dev/null
	mkshortcut -n WADP -i /wicon.ico -w "$HOME" -a "-i /wicon.ico /bin/bash -l \"$HOME\"/bin/WADP.sh" /bin/mintty
	read -t 10 -p 'Create shortcut on the desktop? (Y/n) ' d < /dev/tty
	if [ "$d" == "y" ] || [ "$d" == "Y" ] || [ -z "$d" ]; then
		cp ./WADP.lnk /cygdrive/c/Users/"$USERNAME"/Desktop/ || echo "Could not find desktop, shortcut created in $(pwd)."
	else
		echo "Created Windows shortcut in $(pwd)."
	fi
	cd - 2>/dev/null
	echo ""
	echo "Installation complete."
	echo "To start WADP, double-click on the WADP shortcut."
	echo "Feel free to move it anywhere convenient."
# create launcher if under Linux
elif [ "$LINUX" ]; then
	echo "[Desktop Entry]
Version=0.4
Encoding=UTF-8
Type=Application
Name=WADP
Comment=
Categories=Application;
Exec=$HOME/bin/WADP.sh
Icon=wicon
Terminal=true
StartupNotify=false" > $sourcedir/WADP.desktop
	chmod a+x $sourcedir/WADP.desktop
	read -t 10 -p 'Create launcher on the desktop? (Y/n) ' d < /dev/tty
	if [ "$d" == "y" ] || [ "$d" == "Y" ] || [ -z "$d" ]; then
		cp $sourcedir/WADP.desktop $HOME/Desktop/
	else
		echo "Launcher placed in $sourcedir."
	fi
	echo ""
	echo "Installation complete."
	echo "To start WADP, double-click on the WADP launcher."
	echo "Feel free to move it anywhere convenient."
elif [ "$DARWIN" ]; then
	cp -r "$sourcedir/$osx_only" /Applications || sudo cp -r "$sourcedir/$osx_only" /Applications 
	cp -r "$sourcedir/$osx_only" "$(dirname "$sourcedir")"
	echo "The application WADP was placed in your Applications folder."
	read -t 10 -p 'Create icon on the desktop? (Y/n) ' d < /dev/tty
	if [ "$d" == "y" ] || [ "$d" == "Y" ] || [ -z "$d" ]; then
		cp -r "$sourcedir/$osx_only" $HOME/Desktop
	fi
	echo "Installation complete."
	echo
	echo "To start WADP, double-click on the WADP icon in your Applications folder $(if [ -e "$HOME/Desktop/$osx_only" ]; then echo "or on your desktop";fi)."
	echo "Feel free to move it anywhere convenient."
	echo "This window can now be closed."
fi
sleep 10
echo "This window can now be closed."