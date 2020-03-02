# to autoload this file
proc m2CompErr.tcl {} {}

#================================================================================
# ×××× Compiler error display in M2 working files ×××× #
#================================================================================

namespace eval M2 {}

# force loading of mode or variables won't be defined
M2::loadMode

#================================================================================
proc M2::getCurWord {} {
    set pos [getPos]
    backwardWord
    set bPos [getPos]
    if {[pos::compare $bPos == [pos::math [minPos] + 1]]} {
	set text " "
	regexp "\[A-Za-z\]" [lookAt [minPos]] text
	if {$text != " "} {
	    set bPos [minPos]
	}
    }
    
    forwardWord
    set fPos [getPos]
    goto $pos
    return [getText $bPos $fPos]
}

#================================================================================
proc M2::selectCurWord {} {
    set pos [getPos]
    set char [lookAt [pos::math $pos - 1]]
    if {[regexp "\[A-Za-z\]" $char] == 0} {
	set bPos [pos::math $pos + 1]
    } else {
	backwardWord
	set bPos [getPos]
	if {[pos::compare $bPos == [pos::math [minPos] + 1]]} {
	    set text " "
	    regexp "\[A-Za-z\]" [lookAt [minPos]] text
	    if {$text != " "} {
		set bPos [minPos]
	    }
	}
	
	forwardWord
    }
    selectText $bPos [getPos]
}

#================================================================================
proc M2::fileExt {} {
	set fileName [lindex [winNames -f] 0]
	if {[string last "." $fileName] == -1} {
		return " "
	}
	set fileName [split $fileName .]
	return [lindex $fileName [expr "[llength $fileName]-1"]]
}

	
#================================================================================
proc M2::removeM2ErrMarks {fileName} {
	global m2ErrRing
	while 1 {
		set ind [lsearch $m2ErrRing "*$fileName*"]
		if {$ind == "-1"} {
			return
		}
		set m2ErrRing [lreplace $m2ErrRing $ind $ind]
	}
}

#================================================================================
proc M2::removeAllM2ErrMarks {} {
	global m2ErrRing
	while {[llength $m2ErrRing] != 0} {
		set fileName [lindex [lindex $m2ErrRing 0] 0]
		set ind [lsearch [winNames -f] "${fileName}"]
		if {$ind != -1} {
		    # alertnote "Removing in $fileName error '[lindex [lindex $m2ErrRing 0] 1]'"
		    removeTMark -w "${fileName}" [lindex [lindex $m2ErrRing 0] 1]
		    # alertnote [getTMarks -w "${fileName}"]
		}
		set m2ErrRing [lreplace $m2ErrRing 0 0]
	}
}

#================================================================================
proc M2::getM2ErrMsg {} {
	global m2ErrRing
	global errList
	if {[llength $m2ErrRing] == "0"} {
	    set errMsg "No M2 compiler errors"
	} else {
	    set num [lindex [lindex $m2ErrRing 0] 2]
	    set errMsg ""
	    regexp "$num\[ \]+(\[^\n\]*)" $errList dummyStr errMsg
	    set errMsg [string range $errMsg 0 100]
	}
	return $errMsg
}

#================================================================================
proc M2::actM2ErrMsg {} {
	global m2ErrRing
	global errList
	beep
	status::msg [M2::getM2ErrMsg]
	if {[llength $m2ErrRing] == "0"} {
		beep
	}
}


#================================================================================
proc M2::findNextError {} {
	global m2ErrRing
	global errList
	global M2::posBeforeJumpOutOfLn
	global M2::selEndBeforeJumpOutOfLn
	# Initialize M2::posBeforeJumpOutOfLn and M2::selEndBeforeJumpOutOfLn in a file specific way
	set M2::posBeforeJumpOutOfLn [getPos]
	set M2::selEndBeforeJumpOutOfLn [selEnd]
	set pfnOfCurWindow [lindex [winNames -f] 0]
	if {[llength $m2ErrRing] == "0"} {
		beep
		status::msg "No more M2 compiler errors"
		return
	}
	set first [lindex $m2ErrRing 0]
	set m2ErrRing [lreplace $m2ErrRing 0 0]
	set m2ErrRing [lappend m2ErrRing $first]
	set fileName [lindex [lindex $m2ErrRing 0] 0]
	if { "${fileName}" != "${pfnOfCurWindow}" } {
	    set ind [lsearch [winNames -f] "${fileName}"]
	    if {$ind == -1} {
		set windowName [file tail ${fileName}]
		set errMsg [M2::getM2ErrMsg]
		if {[file exists "$fileName"]} {
		    if {[llength $m2ErrRing] != "0"} {
			status::msg "Skipping error '$errMsg' in Ç${windowName}È (closed by user)"
			beep
		    } else {
			status::msg "Skipping Ç${windowName}È (closed by user)"
			beep
		    }
		} else {
		    status::msg "Can't find file Ç${windowName}È with error '$errMsg'" 
		    beep
		}
		return
	    } else {
		bringToFront [lindex [winNames] $ind]
	    }
	}
	gotoTMark [lindex [lindex $m2ErrRing 0] 1]
	M2::selectCurWord
	M2::actM2ErrMsg
}


#================================================================================
proc M2::convertErrLstToErrALPHA {M2errLstFile errAlphaFileName} {
    global M2modeVars
    # existence of M2errLstFile is assumed to be given
    set errLstFile [open "$M2errLstFile"]
    set lineStr "START"
    set workDir ""
    set prevFileName ""
    set lineNo 0
    set colNo {}
    set errNos {}
    set errAlphaFile [open "${errAlphaFileName}" w]
    while {$lineStr != ""} {
	if  {[gets $errLstFile lineStr] < 1} {
	    break
	}
	# alertnote $lineStr
	if { [regexp {DIR} "${lineStr}"] } then {
	    regexp {(DIR )(.*)} $lineStr ignore dummy workDir 
	}
	regexp {(DIR )(.*)} $lineStr ignore dummy workDir
	regexp {(#   )([0-9]+)(.*)} $lineStr ignore dummy lineNo dummy
	set colLead ""
	set errNo ""
	regexp {(####)([ ]*)(\^  )([0-9]+)(:.*)} $lineStr ignore dummy colLead dummy errNo dummy
	if {$colLead != ""} then {
	    set colNo [lappend colNo [string length "${colLead}"]]
	    set errNos [lappend errNos $errNo]
	}
	set colLead ""
	set errNo ""
	regexp {(####)([ ]*)(\^ warning: )([0-9]+)(:.*)} $lineStr ignore dummy colLead dummy errNo dummy
	if {$colLead != ""} then {
	    set colNo [lappend colNo [string length "${colLead}"]]
	    set errNos [lappend errNos $errNo]
	}
	set fileName ""
	regexp {(^ File ")([^"]*)(".*)} $lineStr ignore dummy fileName dummy
	if {$fileName != ""} then {
	    set fileName [file join "${workDir}" "${fileName}"]
	    # alertnote "$fileName $lineNo '$colNo' '$errNos'"
	    if {$prevFileName != $fileName} then {
		puts $errAlphaFile "NEW"
		puts $errAlphaFile "$fileName"
	    }
	    set prevFileName "${fileName}"
	    for {set ix 0} {$ix<[llength $colNo]} {incr ix} {
		puts $errAlphaFile "$lineNo [lindex $colNo $ix] [lindex $errNos $ix]"
	    }
	    set lineNo 0
	    set colNo {}
	    set errNos {}
	}
    }
    close $errLstFile
    puts $errAlphaFile "END"
    close $errAlphaFile
}


#================================================================================
set loadM2ErrorMsg ""

proc M2::openM2WorkFiles {{p1InUse "FALSE"}} {
    global m2ErrRing
    global errList
    global M2ErrFile
    global M2errDOKFile
    global M2ShellHome
    global loadM2ErrorMsg
    global M2modeVars
    global tcl_platform
    global HOME
    set awindowOpen [winNames -f]
    if {$awindowOpen != ""} then {
	M2::removeAllM2ErrMarks
    }
    set m2ErrRing ""
    # alertnote "Before testing preconditions: p1InUse $p1InUse"
    # Test preconditions
    if { "$p1InUse" == "FALSE" } then {
	if {![info exists M2errDOKFile]} then {
	    set loadM2ErrorMsg "Can't open M2 work files! Check MacMETH or RAMSES installation and/or reconfigure launching from within M2 mode"
	} else {
	    if {![file exists ${M2errDOKFile}]} then {
		set loadM2ErrorMsg "Can't open M2 work files. Check MacMETH or RAMSES installation and/or reconfigure launching from within M2 mode"
	    } else {
		set loadM2ErrorMsg "Can't open/read $M2errDOKFile, please enter at least once M2 mode or reconfigure launching"
	    }
	}
    } elseif { "$p1InUse" == "TRUE" } then {
	# Use errLstFile (M2_err.LST) and adHocErrListDok (M2_ErrListP1.DOK) as
	# generated by RASS-OSX utilities 'mk' or 'mk1' IMPORTANT: Make sure to
	# set M2errFileHome to a value which is consistent with where 'mk' and
	# 'mk1' have written the needed aux files.
	if { [info exists M2modeVars(m2_P1AuxFileCacheFolder)] } then {
	    set M2errFileHome "$M2modeVars(m2_P1AuxFileCacheFolder)"
	} else {
	    # resort to default
	    set M2errFileHome "[file join $HOME Cache]"
	}
	set M2errP1DOKFile [file join "${M2errFileHome}" "M2_ErrListP1.DOK"]
	# The following file is removed from $M2ShellHome if MacMETH compiler is used under RAMSES
	# Has to be considered if M2modeVars(m2_P1AuxFileCacheFolder) should be the RAMSES folder.
	# Note, this is NOT the case for the MacMETH shell, since it is not M2Tool 'AlphaEdit' which deletes
	# this file, but the RAMSES shell
	set M2errLstFile [file join "${M2errFileHome}" "M2_err.LST"]
	if {! [file exists "$M2errLstFile"]} then {
	    set loadM2ErrorMsg "Can't open/read expected file '$M2errLstFile'! Try to use RASS-OSX utility 'mk' or 'mk1' once more."
	    alertnote "${loadM2ErrorMsg}"
	    set p1InUse FALSE
	    return
	}
	if {! [file exists "$M2errP1DOKFile"]} then {
	    set loadM2ErrorMsg "Can't open/read expected file '$M2errP1DOKFile'! Try to use RASS-OSX utility 'mk' or 'mk1' once more."
	    alertnote "${loadM2ErrorMsg}"
	    set p1InUse FALSE
	    return
	}
    }
    # alertnote "After testing preconditions: p1InUse $p1InUse"
    
    # Open now msgFile containing compiler generated/specific error messages
    if { "$p1InUse" == "TRUE" } then {
	# Try to create M2_err.ALPHA first
	set errAlphaFileName [file join ${M2errFileHome} M2_err.ALPHA]
	if {![catch {
	    M2::convertErrLstToErrALPHA "$M2errLstFile" "$errAlphaFileName"
	}]} then { 
	    set msgFile [open "$M2errP1DOKFile"]
	} else {
	    # fall back to non P1 (RAMSES/MacMETH) use
	    set p1InUse FALSE
	    set msgFile [open "$M2errDOKFile"]
	}
    } else {
	set msgFile [open "$M2errDOKFile"]
    }
    set errList [read $msgFile]
    # discard begin up to "Syntax errors" to avoid confounding of years with error numbers 
    regexp {(.+)(Syntax .+)} $errList all headers errList
    close $msgFile
    
    # Process now all work files according to content of aux file 'err.ALPHA' resp. 'M2_err.ALPHA'
    if { "$p1InUse" == "TRUE" } then {
	set theM2errAlphaFile "${errAlphaFileName}"
    } else {
	set theM2errAlphaFile "${M2ErrFile}"
    }
    set loadM2ErrorMsg "Can't open/read '$theM2errAlphaFile'. It may help to enter at least once M2 mode or reconfigure launching"
    set errFile [open "$theM2errAlphaFile"]
    if  {[gets $errFile lineStr] < 1} {
	beep
	status::msg "No M2 working files to open"
	close $errFile
	return
    }
    # Open all files as listed in err.ALPH (or M2_err.ALPHA) one by one, insert
    # temporary marks for each error listed, and build m2ErrRing list for use by
    # M2::findNextError
    set numErrs 0
    set i 1
    while {$lineStr == "NEW"} {
	if  {[gets $errFile lineStr] < 1} {
	    break
	}
	# set fileToEditName [file tail $lineStr]
	# file::startupDisk
	set shellPath "${M2ShellHome}"
	set fileToEditName "${lineStr}"
	# Test wether this script is executed within AlphaX:
	if {$tcl_platform(platform) == "unix"} {
	    set fileToEditName "[mac2unix "${lineStr}"]"
	    if {[regexp {[/]$} $M2ShellHome]} {
		regsub {(.*)[/]$} $M2ShellHome "\\1" shellPath
	    }
	} else {
	    if {[regexp {[:]$} $M2ShellHome]} {
		regsub {(.*)[:]$} $M2ShellHome "\\1" shellPath
	    }
	}
	set loadM2ErrorMsg "Can't open Ç${fileToEditName}È"
	set ind [lsearch [winNames -f] "${fileToEditName}"]
	if {$ind == -1} {
	    if {[file pathtype "${fileToEditName}"] == "absolute"} {
		# it is an absolute path or otherwise ok path/file name, e.g.
		# the case if p1InUse is TRUE
		set wfpfn "${fileToEditName}"
	    } elseif {[file pathtype "${fileToEditName}"] == "relative"} {
		# it is a relative path from MacOS Classic
		# construct absolute path relative to home of Modula-2 shell
		if {[regexp {^[/]} "${M2ShellHome}"]} {
		    # I am running in AlphaX (cheap technique)
		    if {[regexp {^[..]} "${fileToEditName}"]} {
			# fileToEditName contains e.g. "../Dev/ToolsDev/Make/Make.MOD"
			# could remove superfluous pieces from shellPath and or 
			# fileToEditName. But would be quite complicated and not really
			# necessary
		    } elseif {[regexp {^[./]} "${fileToEditName}"]} {
			# fileToEditName contains either e.g. "./Work/;LBM/LBM M8/Sources/ LBM.PRJ"
			# remove superfluous prefix "./" from fileToEditName
			regsub {(^[./])(.*)$} "${fileToEditName}" "\\2" fileToEditName
		    }	
		}
		set wfpfn "[file join "${shellPath}" "${fileToEditName}"]"
	    } else {
		# it is not a relative path, and not an absolute path, but just a file name
		# If you expect crash of this proc in subsequent edit command, close errFile
		set wfpfn "[file join "${shellPath}" "${fileToEditName}"]"
	    }
	    if {[file exists "$wfpfn"]} {
		edit -c -w "$wfpfn"
	    } else {
		close $errFile
		set loadM2ErrorMsg "Can't find file Ç${wfpfn}È" 		
	    }
	} else {
	    bringToFront [lindex [winNames] $ind]
	}
	if  {[gets $errFile lineStr] < 1} {
	    set loadM2ErrorMsg "Bad syntax while reading $M2ErrFile, please recompile"
	    break
	}
	# Window is ready, now insert temporary marks for errors and build m2ErrRing 
	set fileName [lindex [winNames -f] 0]
	# alertnote "p1InUse $p1InUse"
	while {($lineStr != "NEW") && ($lineStr != "END")} {
	    if {"$p1InUse" != "TRUE"} then {
		# This is the format generated from MacMETH compiler output
		# by utility 'AlphaEdit' (e.g. as contained in /Volumes/HD2/Sim/RMS/M2Tools/)
		scan $lineStr "%d %d" pos errNum
	    } else {
		# This is the format generated from P1 compiler output by proc
		# M2::convertErrLstToErrALPHA. The latter used aux file
		# errLstFile (M2_err.LST) as generated by RASS-OSX utilities 'mk'
		# and/or 'mk1'
		scan $lineStr "%d %d %d" errLine errCol errNum
		set pos [pos::fromRowCol $errLine $errCol]
		goto $pos
		# The following improves considerably the error display
 		backwardWord
		forwardWord
 		set pos [getPos]
		# alertnote "$errLine $errCol $errNum - pos: $pos"
	    }
	    if  {[gets $errFile lineStr] < 1} {
		break
	    }
	    goto $pos
	    createTMark "errMark$i" $pos
	    set m2ErrRing [lappend m2ErrRing [list $fileName errMark$i $errNum]]
	    set i [expr $i+1]
	    set numErrs [expr $numErrs+1]
	}
    }
    # Handle case where user launched editor, but there were actually no errors
    if {$numErrs < 1} {
	beep
	status::msg "No M2 compiler errors found"
	close $errFile
	return
    }
    close $errFile
    
    # Now show first error in first file
    set firstFileToEdit [lindex [lindex $m2ErrRing 0] 0]
    bringToFront "$firstFileToEdit"
    gotoTMark errMark1
    set pos [getPos]
    centerRedraw
    M2::selectCurWord
    M2::actM2ErrMsg
}



# This procedure is called via M2 menu "Open Work Files" or via the Apple Event
# handlers M2::EventHandlerAlpha8 (m2Mode.tcl), M2::m2EventHandlerSimple
# (m2ShellUse.tcl), or M2::m2EventHandler (m2ShellUse.tcl)
proc M2::openWorkFiles {} {
    global loadM2ErrorMsg
    global M2modeVars
    if { $M2modeVars(openP1WorkFiles) } then {
	set p1InUse TRUE
    } else {
	set p1InUse FALSE
    }
    if {[catch {
	M2::openM2WorkFiles $p1InUse
    }]} then { 
	beep
	if {[info exists loadM2ErrorMsg] && ("${loadM2ErrorMsg}" != "")} then {
	    alertnote "Error: $loadM2ErrorMsg.  Encountered while attempting to open the M2 work file(s)."
	} else {
	    alertnote "Error in M2 mode: Sorry, unexpected error encountered while attempting to open the M2 work file(s). Probably bad M2 mode installation."
	}
    }
}



# # for M2 menu only
# proc openWorkFiles {} {
#     M2::openWorkFiles
# }


# Reporting that end of this script has been reached
status::msg "m2CompErr.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2CompErr.tcl for Programing in Modula-2 loaded"
}
