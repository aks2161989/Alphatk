################################################################################
#
# matlabWindows.tcl, part of the matlab mode package
# 
# Command and history windows
# 
################################################################################

dummyMATL
proc matlabWindows.tcl {} {}

################################################################################
#  Create and/or go to command window
################################################################################

proc matlabCmdWindow {} {
	global winModes MATLmodeVars

	set wins [winNames]
	if {[set winThere [lsearch $wins $MATLmodeVars(CmdWinName)]] >= 0} {
		set name [lindex $wins $winThere]
		bringToFront $name
		goto [maxPos]
	} else {
		new -n $MATLmodeVars(CmdWinName) -m MATL
		setWinInfo {shell} {1}
		insertText "Welcome to Alpha's Matlab shell."
		insertText -w [lindex [winNames] 0] [matlabPrompt]
	}
}


################################################################################
#  Write results to command window
################################################################################

proc matlabResults {res} {
	global lastMatlabResult
	
	matlabCmdWindow
	insertText "${res}[matlabPrompt 0]"
	set lastMatlabResult $res
}


################################################################################
#  Check if front window is the command window
################################################################################

proc matlabIsShell {} {	
	global MATLmodeVars
	return [expr [string compare [lindex [winNames] 0] $MATLmodeVars(CmdWinName)] == 0]
}


################################################################################
#  Check if front window is the command history window
################################################################################

proc matlabIsHist {} {	
	global MATLmodeVars
	return [expr [string compare [lindex [winNames] 0] $MATLmodeVars(CmdHistWinName)] == 0]
}


################################################################################
#  Send shell line to MATLAB
################################################################################

proc matlabDoShellLine {} {
    
    set pos [getPos]
    
    set ind [string first "È" [getText [lineStart $pos] [nextLineStart [getPos]]]]
    if {$ind >= 0} {
	set lStart [pos::math [lineStart $pos] +$ind+2]
	endOfLine
	set scriptName [getText $lStart [getPos]]
	if {[pos::compare [getPos] != [maxPos]]} {
	    goto [maxPos]
	    insertText $scriptName
	}
	
	insertText "\n"
	matlabDoScript $scriptName 2
	matlabAddCommandHistory $scriptName
	
    } else {
	
	# If we're not on a command line, either 
	# 1) insert a command prompt (if at the bottom of the window), or
	# 2) insert an ordinary return
		
	if {[pos::compare [getPos] == [maxPos]]} {
	    insertText [matlabPrompt]
	} else {
	    insertText "\r"
	}
    }
    return
}


################################################################################
#  Command History recall
################################################################################

proc matlabPrevCommand {} {
    global Matl_commandHistory Matl_commandNum
    
    set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
    if {[set ind [string first "È " $text]] == 0} {
	goto [pos::math [lineStart [getPos]] + $ind + 2]
    } else return
    
    incr Matl_commandNum -1
    if {$Matl_commandNum < 0} {
	incr Matl_commandNum
	endOfLine
	return
    }
    set text [lindex $Matl_commandHistory $Matl_commandNum]
    set to [nextLineStart [getPos]]
    if {[is::Eol [lookAt [pos::math $to -1]]]} {set to [pos::math $to -1]}
    replaceText [getPos] $to $text
}


proc matlabNextCommand {} {
    global Matl_commandHistory Matl_commandNum
    
    set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
    if {[set ind [string first "È " $text]] == 0} {
	goto [pos::math [lineStart [getPos]] + $ind + 2]
    } else return
    
    incr Matl_commandNum
    if {$Matl_commandNum >= [llength $Matl_commandHistory]} {
	incr Matl_commandNum -1
	matlabCancelLine
	return
    }
    set text [lindex $Matl_commandHistory $Matl_commandNum]
    set to [nextLineStart [getPos]]
    if {[is::Eol [lookAt [pos::math $to -1]]]} {set to [pos::math $to -1]}
    replaceText [getPos] $to $text
}


################################################################################
#  Clear current line
################################################################################

proc matlabCancelLine {} {
    global Matl_commandHistory Matl_commandNum
    
    if {![matlabIsShell]} {return}
    
    set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
    if {[set ind [string first "È " $text]] == 0} {
	goto [pos::math [lineStart [getPos]] + $ind + 2]
    } else return
    
    set to [nextLineStart [getPos]]
    deleteText [getPos] $to
    
    set Matl_commandNum [llength $Matl_commandHistory]
}


################################################################################
#  Prompt, for command window
################################################################################

proc matlabPrompt {{cr 1}} {
    if {$cr} {
	return "\rÈ "
    } else {
	return "È "
    }
}

################################################################################
#  Create and/or go to the command history window
################################################################################

proc matlabCmdHistWindow {} {
	global winModes MATLmodeVars Matl_commandHistory

	set wins [winNames]
	if {[set winThere [lsearch $wins $MATLmodeVars(CmdHistWinName)]] >= 0} {
		set name [lindex $wins $winThere]
		bringToFront $name
	} else {
		new -n $MATLmodeVars(CmdHistWinName) -m MATL
		set text "(<cr> to rexecute the command)\r"
		set theTime [join [mtime [now] long]]
		append text "---- Command session history beginning $theTime ----\r"
		set numLines [llength $Matl_commandHistory]
		for {set Matl_commandNum 0} {$Matl_commandNum < $numLines} {incr Matl_commandNum 1} {
			append text "[lindex $Matl_commandHistory $Matl_commandNum]\r"
		}
		insertText $text
		setWinInfo {dirty} {0}
		setWinInfo {read-only} {1}
		prevLineSelect
	}
}


################################################################################
#  Add a command to the history list and the command history window if open
################################################################################

proc matlabAddCommandHistory {scriptName} {
	global Matl_commandHistory Matl_commandNum MATLmodeVars

	if {[string compare [lindex $Matl_commandHistory [expr [llength $Matl_commandHistory]-1]] $scriptName] != 0} {
		lappend Matl_commandHistory $scriptName
		
		if {[set winThere [lsearch [winNames] $MATLmodeVars(CmdHistWinName)]] >= 0} {
			set currentWindow [lindex [winNames] 0]
			bringToFront $MATLmodeVars(CmdHistWinName)
			goto [maxPos -w $MATLmodeVars(CmdHistWinName)]
			setWinInfo -w $MATLmodeVars(CmdHistWinName) {read-only} {0}
			insertText -w $MATLmodeVars(CmdHistWinName) "$scriptName\r"
			setWinInfo -w $MATLmodeVars(CmdHistWinName) {dirty} {0}
			setWinInfo -w $MATLmodeVars(CmdHistWinName) {read-only} {1}
			prevLineSelect 
			bringToFront $currentWindow
		}
	}
	
	set Matl_commandNum [llength $Matl_commandHistory]
}


