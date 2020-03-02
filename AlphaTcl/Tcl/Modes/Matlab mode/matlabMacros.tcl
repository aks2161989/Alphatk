################################################################################
#
# matlabMacros.tcl, part of the matlab mode package
# 
# Send various commands to MATLAB
# 
################################################################################

proc matlabMacros.tcl {} {}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
#
# ×××× MATLAB Workspace ×××× #
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-

################################################################################
#  Reset MATLAB path
################################################################################

proc matlabRebuildPath {} {
	set scriptName "path(path)"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}


################################################################################
#  Clears the current window's script/function from the workspace
################################################################################

proc matlabClearProcedure {} {
	set mFile [lindex [winNames -f] 0]
	set procName [file rootname [file tail $mFile]]
	set scriptName "clear $procName"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}
	

################################################################################
#  Clears the workspace
################################################################################

proc matlabClear {} {
	set scriptName "clear"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}

################################################################################
#  Closes all figure windows
################################################################################

proc matlabCloseAll {} {
	set scriptName "close all"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}

################################################################################
# Get the path of the current window and add it to MATLAB's path
################################################################################

proc matlabAddToPath {} {

	set mFile [lindex [winNames -f] 0]
	regsub -all {'} [file dirname $mFile] {''} mFilePath
	matlabDoScript "path(path,'$mFilePath');" 0
	status::msg "Added '$mFilePath' to path."
	
}

################################################################################
# CD to the path of the current window
################################################################################

proc matlabCdToWin {} {

	set mFile [lindex [winNames -f] 0]
	regsub -all {'} [file dirname $mFile] {''} mFilePath
	matlabDoScript "cd('$mFilePath');" 0
	status::msg "cd('$mFilePath')"
	
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
#
# ×××× MATLAB debugging ×××× #
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-

################################################################################
#  Turn on debugging
################################################################################

proc matlabStopIfError {} {
	set scriptName "dbstop if error"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}


################################################################################
#  Turn off debugging
################################################################################

proc matlabDbClear {} {
	set scriptName "dbclear all"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}


################################################################################
#  Turn on debugging for current window's script/function
################################################################################

proc matlabStopInFile {} {
	set mFile [lindex [winNames -f] 0]
	set procName [file rootname [file tail $mFile]]
	set scriptName "dbstop in $procName"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}


################################################################################
#  Turn on debugging for current window's script/function
################################################################################

proc matlabStopAtCurrentLine {} {
	set mFile [lindex [winNames -f] 0]
	set procName [file rootname [file tail $mFile]]

	set lineno [lindex [pos::toRowChar [getPos]] 0]
	
	set scriptName "dbstop at $lineno in $procName"
	matlabDoScript $scriptName 0
	status::msg $scriptName
}


################################################################################
#  Debug step
################################################################################

proc matlabDebugStep {{nlines 1}} {
	set scriptName "dbstep $nlines"
	matlabDoScript $scriptName
	status::msg $scriptName
}


################################################################################
#  List breakpoints for a file
################################################################################

proc matlabDebugStatus {} {
	set mFile [lindex [winNames -f] 0]
	set procName [file rootname [file tail $mFile]]
	set scriptName "dbstatus $procName"
	set res [matlabDoScript $scriptName 0]
	set text "Breakpoints in $procName"
	matlabShowDefinition $text $res
}


################################################################################
#  Open the file that caused the MATLAB error
################################################################################

proc matlabOpenErrorFile {} {
	global lastMatlabResult
	
	if {[regexp -- {(Error in ==> )([^\r]*)([\r]On line )+([^=]*)(==>)} $lastMatlabResult d1 d2 mFile d3 line]} {
		set fname [string trim $mFile]
		set line [string trim $line]
	
		if {[catch {edit -c $mFile}]} {
			beep
			alertnote "Could not open file, $mFile"
		} else {
			set pos [pos::fromRowChar $line 0]
			selectText $pos [nextLineStart $pos]
		}
	} else {
			beep
			alertnote "No error or no file to open from last command."
	}
}

