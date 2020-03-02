## -*-sh-*-
 # ==========================================================================
 # sh-Example.tcsh
 # 
 # Distributed as an example of Alpha's X Scripts mode.
 #
 # This file demonstrates a 'block' style syntax -- toggle the sh mode
 # preference 'Navigate Blocks' to explore file marking and navigation.
 # 
 # ==========================================================================
 ##

#!/usr/princeton/bin/tcsh
 # ==========================================================================
 # Corporate Policies Analysis - Exploring 30 years of family benefits
 #
 # FILE: "cps-master.csh"
 #                                          created: 09/25/1999 {10:46:22 pm}
 #                                      last update: 09/11/2001 {01:33:46 pm}
 # Description: 
 #
 # The master source file for beginning analysis of data extracted from the
 # Current Population Surveys CD-ROMs.  This source file should be run from
 # the Unix folder benefits/cps/analysis, which assumes that the data files
 # to be analyzed are contained in the folder benefits/cps/data.  To use
 # this file, type
 #
 # % source cps-master.csh
 #
 # where % indicates the Unix prompt.  
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 1999-2000  Craig Barton Upright
 # All rights reserved.
 # 
 # ==========================================================================
 ##


### Preliminaries

# This analysis requires some sharp spikes in memory requirements.
# For this reason I monitor the directory size, and keep
# intermediate data files in a scratch directory.


	unalias rm


# Making Stata "nice", which lowers its priority for CPU time.
# This keeps our friends at CIT happier.

	alias stata nice stata -q


# Creating symbolic links to scratch files.  Each data file is much too
# large to keep in a personal Unix account.  (In fact, they're so large
# that I have to compress them even in the scratch folder as soon as I can
# throughout the analysis.)  This source file assumes that the extracted
# data files are already in a scratch directory named "benefits-cps"

	mkdir   /var/scratch/benefits-cps

	rm -f    ../data-temp
	ln -s    /var/scratch/benefits-cps/  ../data-temp/

	mkdir    ../data

# Creating additional directory "output"

	mkdir ../output

	
# Removing intermediate data files.
#
# "rm" is necessary because Stata will not overwrite unless specifically
# told to do so, and (except for figures), I generally don't.

	rm -f       ../data-temp/*-1.1.dta*
	rm -f       ../data-temp/*-1.2.dta*
	rm -f       ../data-temp/*-1.3.dta*
	rm -f       ../data-temp/*-1.4.dta*
	rm -f       ../data-temp/*-1.5.dta*
	

### Analysis, part I: reading in data, transforming variables
#
# (1-0.do) "Stata-compressing" the marXX.dta data files.
# (1-1.do) Selects variables to be used in the analysis.
#	   Recodes variable responses from "_state" to create "region".
#	   Adjusts weights according to instructions in appendix Q.
#	   (This involves eliminating some observations from the 1963
#	   through 1975 data sets which were assigned negative weights.  
#	   The output file will indicate how many observations were
#	   dropped.)  The march files are then removed to save disk
#	   space.  (This is done at the very end, at which point we can 
#	   assume that the procedure worked.  This same logic continues
#	   in the procedures which follow.)
# (1-2.do) Transforms variables to determine parental status.
# (1-3.do) Transforms variables to determine occupation status.
# (1-4.do) Transforms variables to determine industry.
# (1-5.do) Creating dummy variables

	echo "Analysis, part I: reading in data, transforming variables"

	stata do cps-1-0.do > cps-1-0.out
	stata do cps-1-1.do > cps-1-1.out
	stata do cps-1-2.do > cps-1-2.out
	stata do cps-1-3.do > cps-1-3.out
	stata do cps-1-4.do > cps-1-4.out
	stata do cps-1-5.do > cps-1-5.out


# cleaning up after part I:  removing intermediate data files

	rm -f  ../data-temp/cps*-1.1*
	rm -f  ../data-temp/cps*-1.2*
	rm -f  ../data-temp/cps*-1.3*
	rm -f  ../data-temp/cps*-1.4*


### Analysis, part II: creating crosstab data files
#
# (2-1.do) Extracting, merging crosstab information, national data
# (2-2.do) Extracting, merging crosstab information, regional data
# (2-3.do) Creating new variables as specified by Erin, national data
# (2-4.do) Creating new variables as specified by Erin, regional data
# (2-5.do) Creating figures with new variables, national data
# (2-6.do) Creating figures with new variables, regional data


	echo "Analysis, part II: creating crosstab data files"

	stata do cps-2-1.do > cps-2-1.out
	stata do cps-2-2.do > cps-2-2.out
	stata do cps-2-3.do > cps-2-3.out
	stata do cps-2-4.do > cps-2-4.out
	stata do cps-2-5.do > cps-2-5.out
	stata do cps-2-6.do > cps-2-6.out

	
### Analysis, part III:  merging the new variables with Erin's data set
#
# The "hrs0100.dta.gz" file is from Erin -- it is the one in which all of 
# the new variables will be merged.  It is also rather large, so it has to 
# live in data-temp, the scratch directory.
# 
# (3-1.do) Obtaining the codebook for Erin's data set
# (3-2.do) Merging the new nariables into Erin's stripped data set
# (3-3.do) Merging the new nariables back into Erin's original data set
# (3-4.do) Adding new data, recoding count variables in original data set
# (3-5.do) Creating figures with new variables

	echo "Analysis, part III: merging the new variables"

	stata do cps-3-1.do > cps-3-1.out
	stata do cps-3-2.do > cps-3-2.out
	stata do cps-3-3.do > cps-3-3.out
	stata do cps-3-4.do > cps-3-4.out
	stata do cps-3-5.do > cps-3-5.out


# making all cps files world-readable on password protected web site
#
# Edit the .password/.ht* files to change access users and passwords.
# The Unix command "ypmatch username passwd" will give 
# encrypted passwords on this system.

	echo "making files world-readable on password protected web site"
	chmod -R 755 ../*


### Cleaning up

	mv *.out  ../output

	rm -f       ../figures/NMomAll*
	rm -f       ../figures/NWomAll*
	rm -f       ../figures/NMomWom*
	rm -f       ../figures/NParAll*

	gzip ../data/hrs0100.dta
	
	echo "current inst-logics directory size:" `du -ksd ../`


# Locating errors:  Useful if run in background

	echo "locating errors ..."
	grep 'r(' ../output/* | cat
	echo "finished looking for errors"

	
# never comment out this last line!!


	alias rm rm -i

# .