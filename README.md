![WADP](wicon.png)

The Word Association Data Processor (WADP)
======================
[![DOI](https://zenodo.org/badge/30462151.svg)](https://zenodo.org/badge/latestdoi/30462151)

*see the included manual_1.0.pdf for detailed information, including a tutorial*

*******
DESCRIPTION

The Word Association Data Processor (WADP) is an open-source, free software package which automates key aspects of the processing of word association data gathered from respondents in word association tests. Its user base is expected to be linguists and others working with word association data and employing a methodology similar to that presented in [Fitzpatrick et. al. (2015)](http://applij.oxfordjournals.org/content/36/1/23.full.pdf+html).



The WADP offers:

- a tidy and efficient interface for the manual categorisation of word association responses
- automatic categorisation of responses in cases where categorisations for the relevant cue-response pairs are found in a database of past category ratings
- automatic storage of all new ratings in the database
- tracking of respondent IDs and rater IDs (if provided) in all in- and output files
- automatic creation of individual response profiles
- automatic creation of cue profiles
and more.

For full documentation of all features, a tutorial as well as installation instructions, see the manual included in the distribution.




*******
COMPATIBLE SYSTEMS

The WADP is cross-platform and tested under macOS (v. 11), Ubuntu Linux (v. 20.04), and via Windows Subsystem for Linux on Windows 10. It should work well on any platform that can run the bash shell.

*******
INSTALLATION

**macOS:** use the double-clickable `macOS_installer` provided (give macOS the necessary permissions if prompted), or drop the `install.sh` script into a Terminal window to run it. An installation tutorial for macOS is available [on vimeo](https://vimeo.com/603176910).


**Windows:** The Windows Subsystem for Linux must be installed first (instructions [here](https://ubuntu.com/wsl)). Then use the double-clickable installer `Windows installer (WSL required)` provided. An WADP installation video tutorial for Windows is available [on vimeo](https://vimeo.com/603102292).

**Linux:** Open a terminal window and drop the `install.sh` into the terminal window, then press ENTER. It may be necessary to make `install.sh` executable first by right-clicking on it, then > properties > permissions > tick the box 'Allow executing file as program'. An installation tutorial video is available [on vimeo](https://vimeo.com/603098792).

**Manual installation:** Place the `WADP.sh` file into a directory in the user's `$PATH` to be able to launch it from the command line (it may be necessary to first grant the script permission to be executed).

**Use without installation:** Run the `WADP.sh` script from a terminal application.


*******
HOW TO USE

A detailed manual, including a tutorial, is supplied as a PDF document in the WADP directory. A video tutorial is available [on vimeo](https://vimeo.com/603190447).


*******
TEST

To test whether the WADP installation works as it should, the following tests can be performed:

- select (c) for categoriser and supply the file `five-extra.csv` from the `test_data` directory (supply no database), then rate all pairs as 'I'. The resulting output file should correspond to the contents of `categorised_five-extra.csv` (depending on the operating system, results may be listed in a different order).
- select (r) for reporter, then select (a) for all reports and supply the file `categorised_five-extra.csv` from the `test_data` directory. The content of reports produced should agree with the files `c-report-test.csv`, `i-report-test.csv` and `p-report-test.csv`. The order in which entires are listed can differ between platforms, but substantive results should be identical.
- select (a) for administrator and then (P) for 'produce a list of differences only'. Then supply the files `example_database.dat` and `example_database2.dat` when requested. The output should agree with `test-difference_report.txt` in the `test_data` directory.




*******
WRITTEN BY

Andreas Buerki, <buerkiA@cardiff.ac.uk>  



*********
COPYRIGHT

Copyright 2015-21, Cardiff University
Licensed under the EUPL v1.2 or later. (the European Union Public Licence) which is an open-source licence (see the EUPL-1.2EN.txt file for the full licence).

The project resides at [http://buerki.github.com/WADP/](http://buerki.github.com/WADP/) and new versions will be posted there. Suggestions and feedback are welcome. To be notified of new releases, go to https://github.com/buerki/WADP, click on the 'Watch' button and sign in.

*******
WARNING

As per article 7 of the EUPL, the WADP is a work in progress, which is continuously improved. It is not a finished work and may therefore contain defects or “bugs” inherent to this type of software development.
For the above reason, the software is provided under the Licence on an “as is” basis and without warranties of any kind concerning it, including without limitation merchantability, fitness for a particular purpose, absence of defects or errors, accuracy, non-infringement of intellectual property rights other than copyright as stated in Article 6 of the Licence.
This disclaimer of warranty is an essential part of the Licence and a condition for the grant of any rights to the WADP.
