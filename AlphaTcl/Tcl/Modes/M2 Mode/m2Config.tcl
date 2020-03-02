# to autoload this file (tabsize:8)
proc m2Config.tcl {} {}


#===========================================================================
# ◊◊◊◊ Configure Launching and Configure M2 mode ◊◊◊◊ #
#===========================================================================
# Customizable configuration of M2 mode (mandatory at first use of this mode).
# Supporting two menu commands "M2 > Configure M2 Mode" and 
# "M2 > Configure Launching".
# 
# Note this configuration method stems from pre 7 Alpha, where no mode
# specific preferences dialog was possible. It is implemented such that
# configuration is possible in pre 7 Alphas and that it remains fully
# consistent with the settings made via 
# "Config > Current Mode > Preferences..." dialog.
# 
# Some of this code could move into "m2BackCompatibility.tcl" ...


# The following global configuration (can be easily customized here)
# ------------------------------------------------------------------
 
namespace eval M2 {}

# The following trace and read triggered M2::triggerOnRead serve only
# to force Alpha to recognise changes which have been made to M2modeVars
# Their newPref declaration does unfortunately not invoke a trace, which
# leads to inconsistent values, depending on mechanism by which the
# configuration has been edited ("Config > Current Mode > Preferences..." 
# vs "M2 > Configure M2 Mode".  Note, M2::triggerOnRead is only actually invoked
# if a mode switch takes place, i.e. all proc configureXYZ must also force
# such a mode switch and if an Alpha < 7.x is used, which does not support
# the convenient mode configuration dialog via "Config > Current Mode > 
# Preferences..." or F12
trace variable M2modeVars r M2::triggerOnRead

proc M2::triggerOnRead {varid ele op} {
    #puts stderr "enter [info level -1] [list $varid $ele $op]"
    #alpha::log stdout "enter $varid $ele $op"
    global M2::whileAdjusting
    global M2Author M2ShellName M2errDOKFile M2RightShift M2LeftShift
    global M2WrapRightMargin M2MaxLineLength M2SaveState
    global M2modeVars
        
    if {[catch {
	if {[info exists M2::whileAdjusting] && ![set M2::whileAdjusting]} {
	    switch -- $ele {
		"m2_author" { set M2modeVars($ele) $M2Author }
		"m2_shellName" { set M2modeVars($ele) $M2ShellName }
		"m2_errListDOK" { set M2modeVars($ele) $M2errDOKFile }
		"m2_indentAmount" { set M2modeVars($ele) $M2RightShift }
		"m2_leftShiftAmount" { set M2modeVars($ele) $M2LeftShift }
		"m2_fillRightMargin" { set M2modeVars($ele) $M2WrapRightMargin }
		"m2_maxLineLength" { set M2modeVars($ele) $M2MaxLineLength }
		"m2_savedState" { set M2modeVars($ele) $M2SaveState }
		default {# there is nothing to do}
	    }
	}
    } err]} {
	alertnote "M2 mode bug $err in M2::triggerOnRead"
    }
    #alpha::log stdout "done $varid $ele $op"
}

proc M2::forceReadTrigger {} {
    global duringAutoConfiguration
    # no need to trigger reading during startup
    if {[info exists duringAutoConfiguration] && ($duringAutoConfiguration)} then { return }
    # The old code 'changeMode Text ; changeMode M2' is illegal if we're in the middle
    # of switching to M2 mode.

    # I have no idea why M2 mode can't store all its variables in one place, but
    # lets make sure we read them all.
    global M2modeVars
    foreach ele {
	m2_author m2_shellName m2_errListDOK m2_indentAmount m2_leftShiftAmount 
	m2_fillRightMargin m2_maxLineLength m2_savedState
    } {
	set foo $M2modeVars($ele)
    }
}


# The following code belongs to that part of the configuration which
# ought to be customized only interactively via the M2 menu
# ------------------------------------------------------------------

proc M2::configAuthor {} {
    global M2Author
    global M2modeVars
    if {[info exists M2Author]} then {
	set defltM2Author $M2Author
    } else {		
	set defltM2Author "First Last"
    }
    set prompt "Your first and last name please:"
    if {[catch {prompt $prompt $defltM2Author } author]} then {} 
    if {$author == ""} then {return 0}
    # Now create the variable to make it accessible immediately
    set M2Author $author	
    prefs::modified M2Author
    # The following does not help to force Alpha's "Config > Current Mode > Preferences..."
    # dialog to show the new values
    set M2modeVars(m2_author) "$M2Author"
    # force now Alpha to recognize the changes
    M2::forceReadTrigger
    return 1
}



proc M2::configIndentation {} { 
    global M2RightShift
    global M2LeftShift
    global M2modeVars
    
    set maxTabWidth 31
    if {[info exists M2RightShift]} then {
	set defltRIndent $M2RightShift
    } else {		
	set defltRIndent "  "
    }
    set Defltcount [string length $defltRIndent]
    set prompt "By how many spaces shall «Tab»/«Shift right» move text?"
    if {[catch {prompt $prompt $Defltcount } count]} then {} 
    if {$count == ""} then {return 0}
    set intCount ""
    catch { set intCount [expr int($count)]}
    if {$intCount == $count} then {
	if {[expr (0 <= $intCount) & ($intCount <= $maxTabWidth)]} then {
	    # Now create the variables to make them accessible immediately
	    set M2RightShift ""
	    for {set i 0} {$i < $count} {incr i} {
		set M2RightShift "$M2RightShift "
	    }
	    set M2LeftShift ""
	    for {set i 0} {$i < $count} {incr i; incr i} {
		set M2LeftShift "$M2LeftShift "
	    }
	    if {($M2LeftShift == "") & ($M2RightShift != "")} then {
		set M2LeftShift " "
	    }
	    prefs::modified M2RightShift 
	    prefs::modified M2LeftShift 
	    set M2modeVars(m2_indentAmount) "$M2RightShift"
	    set M2modeVars(m2_leftShiftAmount) "$M2LeftShift"
	    # force now Alpha to recognize the changes
	    M2::forceReadTrigger
	    # adjust the completions accordingly to current value
	    M2::setElectricCompletions
	    # explain effect/purpose a bit to user
	    set msg "Note, «Tab»/«Shift right» shifts a selection by [string length $M2RightShift] space(s),"
	    set msg "$msg «Shift left» shifts it by [string length $M2LeftShift] space(s)."
	    alertnote $msg
	} else {
	    alertnote "Please enter a number in range 0..$maxTabWidth"
	    catch { unset M2RightShift}
	    catch { unset M2LeftShift}
	}
    } else {
	set msg "'$count' is not an integer!"
	set msg "$msg Please enter a number in range 0..$maxTabWidth"
	alertnote $msg
	catch { unset M2RightShift}
	catch { unset M2LeftShift}
    }		
    return 1
}



proc M2::configWrapRightMargin {} { 
    global M2WrapRightMargin
    global M2modeVars
    set minWTRM 2
    set maxWTRM 256
    if {[info exists M2WrapRightMargin]} then {
	set defltWTRM $M2WrapRightMargin
    } else {		
	set defltWTRM 65
    }
    set prompt "At which right margin (column) shall text be wrapped?"
    if {[catch {prompt $prompt $defltWTRM } userWTRM]} then {} 
    if {$userWTRM == ""} then {return 0}
    set intWTRM ""
    catch { set intWTRM [expr int($userWTRM)]}
    if {$intWTRM == $userWTRM} then {
	if {[expr ($minWTRM <= $intWTRM) & ($intWTRM <= $maxWTRM)]} then {
	    # it's now ok
	    set M2WrapRightMargin "$userWTRM"
	    prefs::add M2WrapRightMargin $M2WrapRightMargin
	    set M2modeVars(m2_fillRightMargin) "$M2WrapRightMargin"
	    # force now Alpha to recognize the changes
	    M2::forceReadTrigger
	} else {
	    alertnote "Please enter a number in range $minWTRM..$maxWTRM"
	    catch { unset M2WrapRightMargin}
	}
    } else {
	set msg "'$M2WrapRightMargin' is not an integer!"
	set msg "$msg Please enter a number in range $minWTRM..$maxWTRM"
	alertnote $msg
	catch { unset M2WrapRightMargin}
    }	
    return 1
}



proc M2::configMaxLineLength {} { 
    global M2MaxLineLength
    global M2modeVars
    set minMLL 2
    set maxMLL 256
    if {[info exists M2MaxLineLength]} then {
	set defltMLL $M2MaxLineLength
    } else {		
	set defltMLL 120
    }
    set prompt "Maximum line length (beyond occurrs automatic break)?"
    if {[catch {prompt $prompt $defltMLL } userMLL]} then {} 
    if {$userMLL == ""} then {return 0}
    set intMLL ""
    catch { set intMLL [expr int($userMLL)]}
    if {$intMLL == $userMLL} then {
	if {[expr ($minMLL <= $intMLL) & ($intMLL <= $maxMLL)]} then {
	    # it's now ok
	    set M2MaxLineLength "$userMLL"
	    prefs::add M2MaxLineLength $M2MaxLineLength
	    # following proc sets involved M2modeVars
	    M2::setLnBreakBehavior $M2MaxLineLength
	    # force now Alpha to recognize the changes
	    M2::forceReadTrigger
	} else {
	    alertnote "Please enter a number in range $minMLL..$maxMLL"
	    catch { unset M2MaxLineLength}
	}
    } else {
	set msg "'$M2MaxLineLength' is not an integer!"
	set msg "$msg Please enter a number in range $minMLL..$maxMLL"
	alertnote $msg
	catch { unset M2MaxLineLength}
    }	
    return 1
}



proc M2::configFileSaveFormat {} {
    global M2SaveState
    global savedState
    global M2modeVars
    if {[info exists M2SaveState]} then {
	set defltM2SaveState $M2SaveState
    } else {		
	set defltM2SaveState mpw
	# Store mpw information, which should not confuse MEdit (it is option THINK,
	# which confuses it), but retains current edit position and other information 
	# used by Alfa
    }
    set quest "Save by default files in MPW format? (recommended, unless you mainly edit remote Unix files)"
    set answer [askyesno -c $quest]
    if {$answer == "yes"} then {
	set M2SaveState mpw
    } elseif {$answer == "no"} then {
	set M2SaveState none
    } else {
	return 0
    }
    prefs::modified M2SaveState
    set M2modeVars(m2_savedState) "$M2SaveState"
    # force now Alpha to recognize the changes
    M2::forceReadTrigger
    set savedState "$M2SaveState"	
    return 1
}




proc M2::configureLaunching {shell errlistdok} {
    global M2ShellHome
    global M2TokenFile
    global M2ShellName
    global M2ErrFile
    global M2errDOKFile
    global M2modeVars
    
    if $shell {
	if {[catch {getfile "Open a M2 shell (MacMETH or RAMSES)"} path]} then {
	    # immediately quit routine
	    return 0
	}
	# Now create the variables to make them accessible immediately
	set M2ShellName $path
	set M2ShellHome [file dirname $path]
	set M2TokenFile "[file join "$M2ShellHome" "token.ALPHA"]"
	set M2ErrFile   "[file join "$M2ShellHome" "err.ALPHA"]"
	prefs::modified M2ShellName
	prefs::modified M2ShellHome
	prefs::modified M2TokenFile
	prefs::modified M2ErrFile  
	set M2modeVars(m2_shellName) "$M2ShellName"
	# force now Alpha to recognize the changes
	M2::forceReadTrigger
    }
    
    if $errlistdok {
	# alertnote "Try guessing the M2errDOKFile"
	if {[info exists M2ShellName]} then {
	    set M2errDOKFile [file join [file dirname $M2ShellName] M2Tools ErrList.DOK]
	    set M2modeVars(m2_errListDOK) $M2errDOKFile
	    if {[file exists "$M2errDOKFile"]} then {
		# remember it
		prefs::modified M2errDOKFile
		# All ok, force now Alpha to recognize the changes
		M2::forceReadTrigger
	    } else {
		# Configure ErrList.DOK
		set quest "Couldn't find 'ErrList.DOK' (compiler support), you wish to set it?"
		set answer [askyesno $quest]
		if {$answer == "yes"} then {
		    # immediately quit
		    return 1
		}
		if {[catch {getfile "Please locate 'ErrList.DOK' (look in ƒ M2Tools)"} errpath]} {
		    # immediately quit routine
		    return 0
		}
		# Now create the variable to make it accessible immediately
		set M2errDOKFile $errpath
		prefs::modified M2errDOKFile
		set M2modeVars(m2_errListDOK) "$M2errDOKFile"
		# force now Alpha to recognize the changes
		M2::forceReadTrigger
	    }
	}			
    }
    
    return 1
}


proc M2::configureM2Mode {} {
    global M2Author
    global M2RightShift
    global M2WrapRightMargin
    global M2MaxLineLength
    global M2modeVars
    
    # Now config author
    if {![M2::configAuthor]} {return}
    
    # Now config indentation
    if {![M2::configIndentation]} {return}
    
    # Now config right text wrap margin
    if {![M2::configWrapRightMargin]} {return}
    
    # Now config maximum line length where automatic line breaks occurr
    if {![M2::configMaxLineLength]} {return}
    
    # Configure default file save format
    if {![M2::configFileSaveFormat]} {return}
    
}



# Make sure configuration is ok
# Several levels of "intrusiveness" in which M2::checkM2Configuration is run
# are available:  IF M2::quietUse THEN autosearch of RAMSES or MacMETH shell on entire computer
#                 IF NOT M2::quietUse AND M2::veryQuietUse THEN ask user about shell and name
#                 IF NOT M2::quietUse AND NOT M2::veryQuietUse THEN ask user about all the rest like in older M2 modes
set M2::quietUse 1
set M2::veryQuietUse 1
set M2::userAlreadyAsked 0
set M2::userAlreadyWarned 0

proc M2::userWantsToStop {} {
    global M2::userAlreadyAsked
    if {[set M2::userAlreadyAsked]} { return 0 }
    set msg "The configuration of the Modula-2 environment appears to be incomplete."
    set msg "$msg Please configure it."
    set doIt Now
    set answer [buttonAlert $msg $doIt "Later"]
    set M2::userAlreadyAsked 1
    if {$answer == $doIt} then { 
	return 0
    } else {
	return 1
    }
}

proc M2::warnUser {} {
    global M2::userAlreadyWarned
    global duringAutoConfiguration
    if {[set M2::userAlreadyWarned]} { return }
    set msg "Be warned, M2 mode may not work properly, since you have cancelled its configuration."
    set msg "$msg Don't forget to configure it fully before you start really using it."
    alertnote $msg
    set M2::userAlreadyWarned 1
    set duringAutoConfiguration 0
}

proc M2::checkM2Configuration {} {
    global M2Author 
    global M2ShellName
    global M2errDOKFile
    global M2RightShift M2LeftShift M2WrapRightMargin M2MaxLineLength M2SaveState
    global M2modeVars
    global duringAutoConfiguration
    global M2::quietUse M2::veryQuietUse
    global M2::userAlreadyAsked
    global M2::userAlreadyWarned
    
#     # Check if Alpha version is really a good one (same code as in OPEN-TO-INSTALL) to ensure user is 
#     # informed in case of other installation technique 
#     set cancelRecommendation ""
#     if {![catch {alpha::package versions Alpha} alphaVers]} {
# 	if {$alphaVers >= "7.1b"} then {
# 	    if {("7.1b10" != $alphaVers) && ("7.1b1" <= $alphaVers) && ($alphaVers <= "7.1b5")} then {
# 		set msg "Warning: You should upgrade to at least Alpha 7.1b6 or M2 mode's menu won't work properly!"
# 		append msg "$cancelRecommendation"
# 		alertnote "$msg"
# 	    } 
# 	} elseif {("7.0" <= $alphaVers) && ($alphaVers < "7.0p5")} then {
# 	    set msg "Warning: You should upgrade to at least Alpha 7.0p5 (7.1b6 recommended) for M2 mode to work fully!" 
# 	    append msg "$cancelRecommendation"
# 	    alertnote "$msg"
# 	} 
#     } elseif {![catch {[info commands alpha::extension] == ""}]} then {
# 	set msg "It is recommended to upgrade to Alpha 7.1 to make good use of the M2 mode!"
# 	alertnote "$msg"
#     }
#     unset cancelRecommendation
    
    # flag to M2::forceReadTrigger that config proc only called during initial load
    # to avoid recursive mode loading
    set duringAutoConfiguration 1
    
    set configureNow 1
    set M2::userAlreadyWarned 0
    set M2::userAlreadyAsked 0
    
    if {![set M2::quietUse]} {
	if {![info exists M2ShellName]} {
	    
	    set msg "Please configure the Modula-2 environment for the launching of a shell "
	    set msg "$msg and the compiler support."
	    set doIt Now
	    set answer [buttonAlert $msg $doIt "Later"]
	    set M2::userAlreadyAsked 1
	    if {$answer == $doIt} { 
		set configureNow [M2::configureLaunching 1 1]
	    } else {
		set configureNow 0
	    }
	    if {!$configureNow} then { M2::warnUser }
	} elseif {![file exists "$M2ShellName"]} then {
	    set shellName [file tail "$M2ShellName"]
	    set quest "Couldn't find the Modula-2 shell “$shellName“. "
	    append quest "Do you wish to reconfigure the Modula-2 environment?"
	    set M2::userAlreadyAsked 1
	    if {[askyesno $quest] == "yes"} then {
		set configureNow [M2::configureLaunching 1 1] 
	    } else {
		set configureNow 0
	    }
	    if {!$configureNow} then { M2::warnUser ; return }
	}
	
	if {$configureNow} then {
	    if {![info exists M2errDOKFile]} then {
		if {[M2::userWantsToStop]} then { M2::warnUser ; return }
		set configureNow [M2::configureLaunching 0 1]
	    } elseif {![file exists "$M2errDOKFile"]} then {
		set fileName [file tail "$M2errDOKFile"]
		set quest "Couldn't find the file “$fileName“. "
		append quest "Do you wish to reconfigure the ErrList.DOK file?"
		if {[askyesno $quest] == "yes"} then {
		    set configureNow [M2::configureLaunching 0 1]
		} else {
		    set configureNow 0
		}
	    }
	    if {!$configureNow} then { M2::warnUser ; return }
	}
    } else {
	set configureNow 1
	if {![info exists M2ShellName]} then {
	    # Try looking at the desktop data base, giving RAMSES higher priority
	    if { [catch {nameFromAppl 'RAMS'}] } then {
		# alertnote "look for RAMS"
		if { [catch {nameFromAppl 'ETHM'}] } then {
		    # alertnote "No Modula-2 shells found" 
		    set M2modeVars(m2_shellName) ""
		} else {
		    # alertnote "At least MacMETH found"
		    set M2modeVars(m2_shellName) "[file join [file dirname [nameFromAppl 'ETHM']] " MacMETH"]"
		}
	    } else {
		# alertnote "RAMS found", use it with higher priority than MacMETH shell
		set M2modeVars(m2_shellName) "[file join [file dirname [nameFromAppl 'RAMS']] " RAMSES Shell"]"
	    }
	}
	if {[info exists M2modeVars(m2_shellName)]} then { 
	    if {[file exists "$M2modeVars(m2_shellName)"]} then {
		M2::adjustShellLaunching m2_shellName
	    } else {
		if {$M2modeVars(m2_shellName) == ""} then {
		    alertnote "M2 autoconfigure: MacMETH or RAMSES missing, bad, or\
		      desktop corrupted. Try M2 menu “Configure Launching”,\
		      (re)install M2, and/or recreate desktop."
		} else {
		    alertnote "M2 autoconfigure: Shell “$M2modeVars(m2_shellName)” not found! MacMETH or RAMSES missing, bad, or desktop corrupted. Try M2 menu “Configure Launching”."
		}			
	    }
	    if {![info exists M2errDOKFile]} then {
		set M2modeVars(m2_errListDOK) "[file join [file dirname $M2modeVars(m2_shellName)] "M2Tools" "ErrList.DOK"]"
		if {[file exists $M2modeVars(m2_errListDOK)]} {
		    M2::adjustErrDOKFile m2_errListDOK
		}
	    }
	} else {
	    alertnote "M2 autoconfigure: MacMETH or RAMSES missing, bad, or\
	      desktop corrupted. Please (re)install to make good use of M2 mode."
	}
	if {[info exists M2modeVars(m2_shellName)]} { 
	    status::msg "Have quietly configured your Modula-2 environment - shell “$M2modeVars(m2_shellName)“"
	} else {
	    status::msg "Sorry, attempt to quietly configure your Modula-2 environment failed!"
	}
    } 
    
    if {$configureNow} then { 
	
	if {![set M2::quietUse]} {
	    
	    if {![info exists M2Author]} { 
		if {[M2::userWantsToStop]} { M2::warnUser ; return }
		if {![M2::configAuthor]} {M2::warnUser ; return}
	    } else {
		adjustAuthor m2_author
	    }
	    
	    if {![set M2::veryQuietUse]} {
		if {![info exists M2RightShift] | ![info exists M2LeftShift]} { 
		    if {[M2::userWantsToStop]} { return }
		    if {![M2::configIndentation]} {return}
		}
		
		if {![info exists M2WrapRightMargin]} { 
		    if {[M2::userWantsToStop]} { return }
		    if {![M2::configWrapRightMargin]} { return}
		}
		
		if {![info exists M2MaxLineLength]} { 
		    if {[M2::userWantsToStop]} { return }
		    if {![M2::configMaxLineLength]} { return}
		}
		
		if {![info exists M2SaveState]} { 
		    if {[M2::userWantsToStop]} { return }
		    if {![M2::configFileSaveFormat]} { return }
		}
	    } else {
		# Adjusting further preferences quietly
		M2::adjustRShiftAmount m2_indentAmount
		M2::adjustLShiftAmount m2_leftShiftAmount
		M2::adjustRightMargin m2_fillRightMargin
		M2::adjustMaxLnLength m2_maxLineLength
		M2::adjustMaxLnLeTolerance m2_maxLnLeTol
		M2::adjustSavedState m2_savedState
	    }
	}
	
	
    }
    
    unset duringAutoConfiguration
}


# Fix any possibly missing parts to ensure no M2 proc fail
proc M2::setDefltM2Configuration {} {
    global M2Author
    global M2ShellHome
    global M2TokenFile
    global M2ShellName
    global M2ErrFile
    global M2errDOKFile
    global M2RightShift
    global M2LeftShift
    global M2WrapRightMargin
    global M2MaxLineLength
    global M2SaveState
    global M2modeVars
    
    
    if {![info exists M2Author]} { set M2Author "$M2modeVars(m2_author)" }
    if {![info exists M2ShellName]} { set M2ShellName "$M2modeVars(m2_shellName)" }
    if {![info exists M2ShellHome]} { set M2ShellHome "[file dirname $M2ShellName]" }
    if {![info exists M2TokenFile]} { set M2TokenFile "[file join "$M2ShellHome" "token.ALPHA"]" }
    if {![info exists M2ErrFile]}   { set M2ErrFile   "[file join "$M2ShellHome" "err.ALPHA"]" }
    if {![info exists M2errDOKFile]} { set M2errDOKFile "$M2modeVars(m2_errListDOK)" }
    if {![info exists M2RightShift]} { set M2RightShift "$M2modeVars(m2_indentAmount)" }
    if {![info exists M2LeftShift]} { set M2LeftShift "$M2modeVars(m2_leftShiftAmount)" }
    if {![info exists M2WrapRightMargin]} { set M2WrapRightMargin $M2modeVars(m2_fillRightMargin) }
    if {![info exists M2MaxLineLength]} { set M2MaxLineLength $M2modeVars(m2_maxLineLength) }
    if {![info exists M2SaveState]} { set M2SaveState $M2modeVars(m2_savedState) }
    
    M2::adjustCommentChars prefixString
    
}



# Reporting that end of this script has been reached
status::msg "m2Config.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2Config.tcl for Programing in Modula-2 loaded"
}

