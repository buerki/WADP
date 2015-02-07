![WADP](icon.png)

The Word Association Data Processor (WADP)
======================

*see the included manual_0.3.pdf for detailed information, including a tutorial*

*******
DESCRIPTION

The Word Association Data Processor (WADP) is an open-source, free software package which automates key aspects of the processing of word association data gathered from respondents in word association tests. Its user base is expected to be linguists and others working with word association data and employing a methodology similar to that presented in [Fitzpatrick et. al. (2013)](http://applij.oxfordjournals.org/content/36/1/23.full.pdf+html).



The WADP offers:

- a tidy and efficient interface for the manual categorisation of word association responses
- automatic categorisation of responses in cases where categorisations for the relevant cue-response pairs are found in a database of past category ratings
- automatic storage of all new ratings in the database
- tracking of respondent IDs and rater IDs (if provided) in all in- and output files
- automatic creation of individual response profiles
- automatic creation of cue profiles
and more. For full documentation, a tutorial as well as installation instructions, see the manual.


The WADP is cross-platform and currently available as beta software. It was
tested under OS X, Xubuntu Linux, and via Cygwin on Windows 7 and 8 and should work well on any plat-
form that can run the bash shell.

*******
INSTALLATION


The WADP was tested on MacOS X (v. 10.8 and 10.9), Ubuntu Linux (version Xubuntu 14.04) and Cygwin (version 1.7.30), but should run on all platforms on which a bash shell is installed. This includes Windows with the [Cygwin](cygwin.com) package installed.
Generally, all scripts (i.e. the files ending in .sh) should be placed in a location that is in the user's $PATH variable (or the location should be added to the $PATH variable) so they can be called from the command line. A good place to put the scripts might be /usr/local/bin or $HOME/bin.

Detailed instructions of how to do this are given here:

1. open the Terminal application 

      MacOS X: in Applications/Utilities
      
      Ubuntu Linux: via menu Applications>Accessories>Terminal
      
      Cygwin: via the link on the desktop to Cygwin Terminal
2. type: `mkdir /usr/local/bin`	(it may say 'File exists', that's fine)
3. type: `echo $PATH` (if you can see /usr/local/bin somewhere in the
      output, move to step 8, if not carry on with the next step)
4. type: `cd $HOME`
      type: `cp .profile .profile.bkup` (if it says there no such file,
      that's fine)
5. type: `vi .profile`
6. move to an empty line and press the `i` key, then enter the
      following: `PATH=/usr/local/bin:$PATH`
7. press ESC, then type `:wq!`
8. move into the `WADP` directory. This can be done by typing `cd ` (make sure there is a space after `cd ` but don't press return yet) and then dragging the WADP folder onto the Terminal window and pressing return.
9. type: `sudo cp *.sh /usr/local/bin` (you will need to enter an admin password)

      Done!

The installation can be verified by calling each script's help function for the command line of a Terminal window:

1. open a new terminal window

2. Type `categoriser.sh -h` and hit enter. Try the same with `administrator.sh -h`, `reporter.sh -h`, etc.

3. If the help texts appear, all is in order.

For further tests, you may wish to run SubString on the test data (see next section)

*******
MANUAL

A manual detailing the operation of the WADP and a tutorial is supplied as a PDF document in the WADP directory.


*******
AUTHOR

Andreas Buerki, <buerkiA@cardiff.ac.uk>  

******
SEE ALSO

http://buerki.github.io/ngramprocessor/

http://buerki.github.io/SubString/

http://applij.oxfordjournals.org/content/36/1/23.full.pdf+html

*********
COPYRIGHT

Copyright 2015, Andreas Buerki
Licensed under the EUPL V.1.1. (the European Union Public Licence) which is an open-source licence (see the EUPL.pdf file for the full licence).

The project resides at [http://buerki.github.com/WADP/](http://buerki.github.com/WADP/) and new versions will be posted there. Suggestions and feedback are welcome. To be notified of new releases, go to https://github.com/buerki/WADP, click on the 'Watch' button and sign in.

*******
WARNING

As article 7 of the EUPL states, the WADP is a work in progress, which is continuously improved. It is not a finished work and may therefore contain defects or “bugs” inherent to this type of software development.
For the above reason, the software is provided under the Licence on an “as is” basis and without warranties of any kind concerning it, including without limitation merchantability, fitness for a particular purpose, absence of defects or errors, accuracy, non-infringement of intellectual property rights other than copyright as stated in Article 6 of this Licence.
This disclaimer of warranty is an essential part of the Licence and a condition for the grant of any rights to the WADP.
