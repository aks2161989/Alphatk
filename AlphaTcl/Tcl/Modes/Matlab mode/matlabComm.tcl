################################################################################
#
# matlabComm.tcl, part of the matlab mode package
# 
# Communicate with MATLAB
# 
################################################################################

proc matlabComm.tcl {} {}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
#
# ×××× Core interaction with MATLAB ×××× #
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-

#################################################################################
# Launch MATLAB in background if not already running
################################################################################

proc matlabLaunch {} {
	set name [app::launchBack MATL]

# 	global matlabPath
# 	catch {checkRunning MATLAB MATL matlabPath} name

	return $name
}


#################################################################################
# Tell MATLAB to do a script.  
# Echo script and script results in command window if desired.
#   showResults = 0 show nothing
#                 1 echo command in command window and show results when done
#                 2 do not echo command but do show results when done
#   forceWait = 0 que command 
#               1 wait for result and return it
#               
#  If sending a list of scripts all argins must be present and of same length 
#  except forceWait which can only be a single 0
################################################################################

proc matlabDoScript {scriptName {showResults 1} {forceWait 0} {replyHandler MATL::ReplyHandler}} {
	global MATLmodeVars MATLeventQue matlabBusy
	
	matlabLaunch
	
	if {$forceWait} {
		status::msg "Waiting for result from MATLAB"
		set res [tclAE::build::resultData 'MATL' misc dosc \
		  ---- [tclAE::build::TEXT $scriptName]]
		status::msg "Got result from MATLAB"
		if {$showResults} {
			matlabCmdWindow
			insertText "${scriptName}\n"
			matlabResults $res
		}
		return $res
	}
	
	if {$matlabBusy && ! $MATLmodeVars(queEventsQuietly)} {
		if {[askyesno "Matlab is busy, should I queue your request:\r\"$scriptName\""] == "no"} {
			return
		}
	}
	
	if {[llength $showResults] > 1} {
		for {set i 0} {$i < [llength $scriptName]} {incr i} {
			lappend MATLeventQue "{[lindex $scriptName $i]} [lindex $showResults $i] [lindex $replyHandler $i]"
		}
	} else {
		lappend MATLeventQue "{$scriptName} $showResults $replyHandler"
	}
	
	if {! $matlabBusy} {
		MATL::queNextEvent
	}
}

################################################################################
# Switch to Matlab
################################################################################

proc matlab {} {
	app::launchFore MATL
}

################################################################################
# Check if Matlab is running
################################################################################

proc isMatlabRunning {} {
	return [app::isRunning MATL]

}

################################################################################ 
# Matlab Save Hook to clear the current function from MATLAB's memory.  
# This is useful for editing callback functions that don't get checked 
# for modifiction.
################################################################################

proc MATL::saveHook {name} {
	global MATLmodeVars

	#
	# Check if the user wants functions cleared on save and sure MATLAB 
	# is running.  We don't need to clear if it is not!
	#
	if {[isMatlabRunning] && $MATLmodeVars(clearOnSave)} then {
		#
		# Now clear the function
		#
		set procName [file rootname [file tail $name]]
# 		set scriptName "clear $procName"
		set scriptName "clear functions"
		matlabDoScript $scriptName 0
		status::msg $scriptName
		return
	}
}


################################################################################
#  Ask MATLAB for the location of a file.
################################################################################

proc matlabWhichFile {name} {
	global matlabBusy
	
	if {$matlabBusy} {
		alertnote "Matlab is busy, try again later."
		return ""
	}
	
	set mFile [string trim [matlabDoScript "which $name" 0 1]]
	
	# if it is a mex-file get the associated m-file
	if {[string compare [file extension $mFile] ".mex"] == 0} {
		set fRoot [file rootname $mFile]
		set mExt {.m}
		set mFile $fRoot$mExt
	}
	
	return $mFile
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
#
# ×××× Send stuff to MATLAB ×××× #
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-

################################################################################
#  Edit current window in MATLAB
################################################################################

proc editInMatlab {} {
	
	if {[winDirty]} {
		if {[askyesno "Save '[lindex [winNames] 0]'?"] == "yes"} {
			save
		} else {
			return
		}
	}
	
	set matName [matlabLaunch]
	
	if {[catch {sendOpenEvent -n $matName [lindex [winNames -f] 0]}] } {
		beep 
	} else {
		switchTo $matName
		killWindow
	}
}


################################################################################
#  Debug current window in MATLAB
################################################################################

proc debugInMatlab {} {
	
	if {[winDirty]} {
		if {[askyesno "Save '[lindex [winNames] 0]'?"] == "yes"} {
			save
		} else {
			return
		}
	}
	
	set mFile [lindex [winNames -f] 0]
	set procName [file rootname [file tail $mFile]]
	
	set scriptName "mactools mdebug $procName"
	matlabDoScript $scriptName 0
	switchTo [matlabLaunch]
}


################################################################################
#  Save current window and execute it in MATLAB
################################################################################

proc matlabSaveAndExecute {} {
	global MATLmodeVars
	
	# Temporarily turn off clearOnSave so we can send all events at once
	if {[winDirty]} {
		set oldClearOnSave $MATLmodeVars(clearOnSave)
		set MATLmodeVars(clearOnSave) 0
		save
		set MATLmodeVars(clearOnSave) $oldClearOnSave
	}
	
	# Get the path of the current window and it's name
	set mFile [lindex [winNames -f] 0]
	regsub -all -- {'} [file dirname $mFile] {''} mFilePath
	set procName [file rootname [file tail $mFile]]
	
	# Begin building event list
	# Change current working directory to window's and do the script
	set theScripts [list "cd '$mFilePath'" "$procName"]
	set handlers [list MATL::NullReplyHandler MATL::ReplyHandler]
	set showResults [list 0 1]
	
	# Now add the clearOnSave if necessary to event list
	if {$MATLmodeVars(clearOnSave) && [isMatlabRunning]} then {
# 		set scriptName "clear $procName"
		set scriptName "clear functions"
		set theScripts [concat [list $scriptName] $theScripts]
		set handlers [concat [list MATL::NullReplyHandler] $handlers]
		set showResults [concat [list 0] $showResults]
	}
	
	# Do the script
	matlabDoScript  $theScripts $showResults 0 $handlers
}


################################################################################
#  Send line to MATLAB
################################################################################

proc matlabDoLine {} {
    beginningOfLine
    set bol [getPos]
    endOfLine
    set eol [getPos]
    set scriptName [getText $bol $eol]
    matlabDoScript $scriptName
}


################################################################################
#  Send line or selection to MATLAB
################################################################################

proc matlabDoSelectionOrLine {} {
    if {[pos::compare [getPos] == [selEnd]]} {
	set bol [lineStart [getPos]]
	set eol [pos::math [nextLineStart [getPos]] - 1]
	set scriptName [string trim [getText $bol $eol]]
    } else {
	set scriptName [string trim [getSelect]]
    }
    
    matlabDoScript $scriptName
    return $scriptName
}


################################################################################
#  Open selected .m file
################################################################################

proc matlabOpenSelection {} {
	MATL::editMfile [getSelect]
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
#
# ×××× Reply handlers ×××× #
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-


################################################################################
#  Handle the reply from MATLAB
################################################################################

proc MATL::ReplyHandler {res} {
	
	if {[regexp -- {(Ò)([^Ó]*)} $res dum1 dum2 res1]} {
		matlabResults $res1
	} else {
		alertnote $res1
	}
	
	MATL::queNextEvent
	
	return 1
}


################################################################################
#  Handle the reply from MATLAB by doing nothing special
################################################################################

proc MATL::NullReplyHandler {res} {
	MATL::queNextEvent
	return 1
}



################################################################################
#  Handle the reply from MATLAB for a definition
################################################################################

proc MATL::DocReplyHandler {res} {
	global MATLcurrentScript
	
	if {[regexp -- {(Ò)([^Ó]*)} $res dum1 dum2 res1]} {
		if {[regexp -- {not found.} [string range $res 0 100]]} {
			alertnote $res1
		} else {
			matlabShowDefinition $MATLcurrentScript $res1
		}
	} else {
		alertnote $res
	}
	
	MATL::queNextEvent
	
	return 1
}
		
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
#
# ×××× Event que ×××× #
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-

################################################################################
#  Move the next event up in the que
################################################################################

proc MATL::queNextEvent {} {
	global MATLeventQue matlabBusy
	
	set matlabBusy 0
	
	if {[llength $MATLeventQue] > 0} {
		set nextEvent [lindex $MATLeventQue 0]
		set MATLeventQue [lrange $MATLeventQue 1 end]
		eval "MATL::DoEvent $nextEvent"
	}
}


################################################################################
#  Do the current event
################################################################################

proc MATL::DoEvent {scriptName showResults replyHandler} {
	global matlabBusy MATLcurrentScript
	
	switch -- $showResults {
		0 {
			currentReplyHandler MATL::NullReplyHandler
			tclAE::send -q 'MATL' misc dosc ---- \
			  [tclAE::build::TEXT $scriptName]
		}
		1 {
			matlabCmdWindow
			insertText "${scriptName}\n"
			set MATLcurrentScript $scriptName
			currentReplyHandler $replyHandler
			tclAE::send -q 'MATL' misc dosc ---- \
			  [tclAE::build::TEXT $scriptName]
		}
		2 {
			set MATLcurrentScript $scriptName
			currentReplyHandler $replyHandler
			tclAE::send -q 'MATL' misc dosc ---- \
			  [tclAE::build::TEXT $scriptName]
		}
	}
	set matlabBusy 1
}

################################################################################
#  Manually clear the event que
################################################################################

proc MATL::clearEventQue {} {
	global MATLeventQue matlabBusy
	
	set matlabBusy 0
	set MATLeventQue ""
	
}


