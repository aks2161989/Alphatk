################################################################################
#
# matlabHTML.tcl, part of the matlab mode package
# 
# This is a set of TCL proc's that can be used to make html documentation 
# for "properly" documented matlab files.  "Properly" is defined to mean they 
# are written so that the matlab command "helpwin" works well for them.
# 
################################################################################

proc matlabHTML.tcl {} {}

#############################################################################
# Make html files for a directory of .m files
#############################################################################

proc makeMatlabHTML {} {
	global matlabBusy
	
	if {$matlabBusy} {
		alertnote "Matlab is busy, try again later."
		return
	}
	
	set codeDir [get_directory -p "Select folder:"]
	if {![catch {glob -types TEXT -dir $codeDir -- "*.m"} filelist]} {
		set filelist [makeMatlabEmptyHTML $filelist]
		foreach mFile $filelist {
			makeMatlabHtmlFile $mFile
		}
		
	} else {
		alertnote "No .m files found in $codeDir"
	}
}

############################################################################# 
# Make empty html files for a directory of .m files.
# 
# We do this to check if old ones should be overwritten and to make sure 
# "see also" links work properly .
# 
# Returns a subset of filelist to be further processed
#############################################################################

proc makeMatlabEmptyHTML {filelist} {
    set overwrite "ask"
    set newFileList [list]
    foreach mFile $filelist {
	
	set codeDir [file dirname $mFile]
	set root [file rootname [file tail $mFile]]
	
	set htmlDir [file join $codeDir html]
	if {![file isdirectory $htmlDir]} {file mkdir $htmlDir}
	set htmlFile [file join $htmlDir $root.html]
	
	if {[file exists $htmlFile]} {
	    if {$overwrite == "ask"} {
		set overwrite [askyesno -c "Some html files already exist.  Should I replace them?  Old files will be put in trash."]
	    }
	    switch -- $overwrite {
		"yes" {
		    regexp -- {^[^:]*} $htmlFile theDisk
		    if {[catch {file rename "$htmlFile" [file join $theDisk Trash]}]} {
			alertnote "Problem moving old files to trash.  Try emptying the trash."
			return
		    }
		    close [open $htmlFile w]
		    lappend newFileList $mFile
		}
		"no" {}
		"cancel" {return ""}
	    }
	} else {
	    close [open $htmlFile w]
	    lappend newFileList $mFile
	}
    }
    return $newFileList
}


#############################################################################
# Parse the comment header of an .m file and make a .html file
#############################################################################

proc makeMatlabHtmlFile {mFile} {
	
	status::msg "Processing $mFile"
	
	#
	# Figure out where the files are and open them
	#
	
	set codeDir [file dirname $mFile]
	set root [file rootname [file tail $mFile]]
	
	set htmlDir [file join $codeDir html]
	if {![file isdirectory $htmlDir]} {file mkdir $htmlDir}
	set htmlFile [file join $htmlDir $root.html]
	
	set mFileID [open $mFile r]
	set htmlFileID [open $htmlFile w]
	
	#
	# Get the function declaration or script name
	#
	
	gets $mFileID firstLine
	if {![regexp -- {([ \t]*)(function)(.*)} $firstLine allText cc function call]} {
		set call $root
		seek $mFileID 0 start
	}
	
	#
	# Scan the header
	#
	
	set text ""
	set seeAlso ""
	while {[gets $mFileID oneLine] != -1} {
		if {![regexp -- {(%)(.*)} $oneLine allText cc comment]} {break}
		if {[regexp -- {(%)([\t ]*See also:)(.*)} $oneLine allText cc sa allSee]} {
			set comment "$sa [parceMatlabSeeAlso $allSee]"
		}
		append text "$comment\r"
	}
	
	#
	# Write the .html file
	#
	
	puts $htmlFileID "<HTML>\r<HEAD>"
	puts $htmlFileID "<TITLE>$root</TITLE>"
	puts $htmlFileID "</HEAD>"
	puts $htmlFileID "<BODY BGCOLOR=#F0F0F0>\r"
	puts $htmlFileID "<H1>$root</H1>\r"
	puts $htmlFileID "<HR>\r"
	puts $htmlFileID "<H2>$call</H2>\r"
	puts $htmlFileID "<PRE>$text\r</PRE>\r"
	puts $htmlFileID "<HR><BR>\r"
	
	#
	# Add helpdesk and contents to footer
	#
	
	regsub  -all ":" [matlabHelpDir] "/" helpDesk
	set helpDesk "file:///$helpDesk/helpdesk.html"
		
	set contents [file tail [file dirname $mFile]]
	set footer "<P ALIGN=\"CENTER\">\["
	append footer "<A HREF=\"contents.html\">$contents</A> | "
	append footer "<A HREF=\"$helpDesk\">Help Desk</A>\]</P>\r"
	
	puts $htmlFileID "$footer\r</BODY>\r</HTML>"

	#
	# All done, so close files
	#
	
	close $mFileID
	close $htmlFileID
	status::msg "Finished writing $htmlFile"
	
}


#############################################################################
# Parse a see also line
#############################################################################

proc parceMatlabSeeAlso {allSee} {
	set seeAlso ""
	set pre " "
	while {[regexp -- {(\b[_\w]+\b)(.*)} $allSee aText oneSee allSee]} {
		set docURL [findMatlabHelpFile $oneSee]
		if {$docURL != ""} {
			set oneLink "<A HREF=\"$docURL\">$oneSee</A>"
		} else {
			set oneLink "$oneSee"
		}
		append seeAlso "$pre$oneLink"
		set pre ", "
	}
	return $seeAlso
}
