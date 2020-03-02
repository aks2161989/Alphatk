################################################################################
#
# matlabDoc.tcl, part of the matlab mode package
# 
# Documentation system using matlab and web browser
# 
################################################################################

proc matlabDoc.tcl {} {}

################################################################################
# Main proc for getting help.
# Does both web and matlab help depending on modeVar webHelp.
################################################################################

proc getMatlabHelp {command} {
	global MATLmodeVars
	
	if {$MATLmodeVars(webHelp)} {
		set docURL [findMatlabHelpFile $command]
		if {$docURL != ""} {
			sendUrl "$docURL"
			return
		}
	}
	
	set scriptName "help $command"
	matlabDoScript $scriptName 2 0 {MATL::DocReplyHandler}
}

################################################################################ 
# Return the path of help directory.
# It can be set by the user in the preferences, but we will 
# ask Matlab if we do not already know it.  
################################################################################

proc matlabHelpDir {} {
	global MATLmodeVars
	
	if {![info exists MATLmodeVars(MatlabHelpFolder)] || [expr {$MATLmodeVars(MatlabHelpFolder) == ""}]} {
		set MATLmodeVars(MatlabHelpFolder) [string trim [matlabDoScript disp(docroot) 0 1]]
# 		set MatlabHelpFolder [get_directory -p "Select Matlab help folder:"]
		prefs::modified MATLmodeVars(MatlabHelpFolder)
	}
	
	return $MATLmodeVars(MatlabHelpFolder)
}


################################################################################
#  Get the URL of a help file
################################################################################

proc findMatlabHelpFile {command} {
	
	set helpDir [matlabHelpDir]
	if {$helpDir != ""} {
		set docPath "$helpDir:techdoc:ref:$command.html"
		if {[file exists $docPath]} {
			regsub  -all ":" $docPath "/" docPath
			return "file:///$docPath"
		}
	}
	
	set mFile [matlabWhichFile $command]
	if {$mFile == ""} {return -code return}
	
	set docPath "[file dirname $mFile]:html:$command.html"
	if {[file exists $docPath]} {
		regsub  -all ":" $docPath "/" docPath
		return "file:///$docPath"
	}
	
	return ""
}


################################################################################
#  Search MATLAB documentation
################################################################################

proc matlabSearchHelp {command} {
	global MATLmodeVars

	if {$MATLmodeVars(webHelp)} {
		set helpDir [matlabHelpDir]
		if {$helpDir == ""} {return}
		
		regsub -all -- ":" $helpDir "/" docPath
		regsub -all -- " " $command "+" command
		set docURL "file:///$docPath/searchindex.html?searchnv=$command"
		sendUrl "$docURL"
	} else {
		set scriptName "lookfor $command"
		matlabDoScript $scriptName 2 0 MATL::DocReplyHandler
	}
}
	

################################################################################
#  Create a new window with function definition
################################################################################

proc matlabShowDefinition {name def} {
	new -n "* $name *" -m MATL
	insertText $def
	goto [minPos]

	# Set window mode to MATLAB, so that we can follow 
	# cross-references by Cmd-dbl-clicking (and colors
	# are active, etc...)
	
	catch {shrinkWindow 1}
	set win [lindex [winNames -f] 0]
	setWinInfo -w $win dirty 0
	setWinInfo -w $win read-only 1
} 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
#
# ×××× UI procs for getting help ×××× #
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-

################################################################################
# Get help on selected command
################################################################################

proc matlabHelpSelection {} {
	getMatlabHelp [getSelect]
}


################################################################################
#  Present a dialog to get help on a command
################################################################################

proc matlabHelp {} {
	if {[set text [prompt "Enter command" ""]] == ""} {
	    status::msg "Cancelled -- no text was entered."
	    return
	}
	getMatlabHelp $text
}


################################################################################
#  Present a dialog to search help on a command
################################################################################

proc matlabSearchHelpDialog {} {
	if {[set command [prompt "Enter search string" ""]] == ""} {
	    status::msg "Cancelled -- no text was entered."
	    return
	}
	matlabSearchHelp $command
}
