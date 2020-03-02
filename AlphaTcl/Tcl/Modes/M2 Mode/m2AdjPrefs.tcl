# to autoload this file
proc m2AdjPrefs.tcl {} {}

namespace eval M2 {}


#===========================================================================
# ×××× Adjusting preferences after F12-Configuration ×××× #
#===========================================================================
# The following proc serve to adjust the M2 preferences variables once 
# the user has edited them via the menu "Config > Current Mode > Preferences..."
# This ensures that the latest settings are preserved from one session to the 
# next and need not to be reconfigured each time you relaunch Alpha

proc M2::adjustAuthor {varName} {
	global M2modeVars
	global M2Author
	# alertnote "in M2::adjustAuthor"
	set M2Author "$M2modeVars($varName)"
	prefs::modified M2Author
}

proc M2::adjustShellLaunching {varName} {
	global M2modeVars
	global M2TokenFile
	global M2ShellName
	global M2ShellHome
	global M2ErrFile
	# alertnote "in M2::adjustShellLaunching"
	set M2ShellName "$M2modeVars($varName)"
	set M2ShellHome [file dirname $M2ShellName]
	set M2TokenFile [file join $M2ShellHome token.ALPHA]
	set M2ErrFile [file join $M2ShellHome err.ALPHA]
	prefs::modified M2ShellName M2ShellHome M2TokenFile M2ErrFile
}

proc M2::adjustErrDOKFile {varName} {
	global M2modeVars
	global M2errDOKFile
	# alertnote "in M2::adjustErrDOKFile"
	set M2errDOKFile "$M2modeVars($varName)"
	prefs::modified M2errDOKFile
}

proc M2::adjustRShiftAmount {varName} {	
	global M2modeVars
	global M2RightShift
	global duringAutoConfiguration
	# alertnote "in M2::adjustRShiftAmount"
	if {[info exists M2RightShift]} then {
		set oldM2RightShift $M2RightShift
	} else {
		set oldM2RightShift "$M2modeVars($varName)"
	}
	set M2RightShift "$M2modeVars($varName)"
	prefs::modified M2RightShift
	if {[info exists duringAutoConfiguration] && ($duringAutoConfiguration)} then { return }
	if {$oldM2RightShift != $M2RightShift} then {
		M2::setElectricCompletions
	}
}

proc M2::adjustLShiftAmount {varName} {
	global M2modeVars
	global M2LeftShift
	# alertnote "in M2::adjustLShiftAmount"
	set M2LeftShift "$M2modeVars($varName)"
	prefs::modified M2LeftShift
}

proc M2::adjustRightMargin {varName} {
	global M2modeVars
	global M2WrapRightMargin
	# alertnote "in M2::adjustRightMargin: M2WrapRightMargin = $M2WrapRightMargin; M2modeVars($varName) = $M2modeVars($varName)"
	set M2WrapRightMargin "$M2modeVars($varName)"
	prefs::modified M2WrapRightMargin
}

proc M2::adjustMaxLnLength {varName} {
	global M2modeVars
	global M2MaxLineLength
	# alertnote "in M2::adjustMaxLnLength"
	set M2MaxLineLength "$M2modeVars($varName)"
	prefs::modified M2MaxLineLength
	M2::setLnBreakBehavior $M2MaxLineLength
}

proc M2::adjustMaxLnLeTolerance {varName} {
	global M2modeVars
	global M2MaxLineLength
	# alertnote "in M2::adjustMaxLnLeTolerance"
	# is a simple newPref variable and its value is not remembered
	M2::setLnBreakBehavior $M2MaxLineLength
}

proc M2::adjustSavedState {varName} {
	global M2modeVars
	global M2SaveState
	# alertnote "in M2::adjustSavedState"
	set M2SaveState "$M2modeVars($varName)"
	prefs::modified M2SaveState
}

proc M2::adjustSpaceBarExpansion {varName} {
    global M2modeVars
    # alertnote "in M2::adjustSpaceBarExpansion"
    if $M2modeVars($varName) {
	M2::activateSpaceBarExpansion
    } else {
	M2::deactivateSpaceBarExpansion
    }
}
    
proc M2::adjustCommentChars {varName} {
    global M2::commentCharacters M2modeVars
    set M2::commentCharacters(General) "$M2modeVars(prefixString)"
    set M2::commentCharacters(Paragraph) [list "$M2modeVars(prefixString)" "$M2modeVars(suffixString)" ""]
    
    set boxBeg [string trim $M2modeVars(prefixString)]
    set boxBegLe [string length $boxBeg]
    set boxEnd [string trim $M2modeVars(suffixString)]
    set boxEndLe [string length $boxEnd]
    set M2::commentCharacters(Box) [list "$boxBeg" $boxBegLe "$boxEnd" $boxEndLe "\*" 3]
}

proc M2::adjustGlobalM2Bindings {varName} {
    global M2modeVars
    # alertnote "in M2::adjustGlobalM2Bindings - M2modeVars($varName) = $M2modeVars($varName)"
    if $M2modeVars($varName) {
	# Activate all global bindings introduced by M2 mode
	if {[alpha::package exists "globalM2Bindings"]} {
	    # alertnote "Package globalM2Bindings exists"
	    if {![package::active "globalM2Bindings"]} {
		package::makeOnOrOff "globalM2Bindings" "basic-on" "global"
	    }
	} else {
	    # alertnote "package does not exist, yet making global bindings active"
	    M2::setGlobalBindings
	}
    } else {
	# Deactivate all global bindings introduced by M2 mode
	if {[package::active "globalM2Bindings"]} {
	    package::makeOnOrOff "globalM2Bindings" "basic-off" "global"
	} else {
	    # Package not active, but make sure global bindings are unbound 
	    M2::unsetGlobalBindings 
	}
    }
}

proc M2::adjustElectricNumKeypad1 {varName} {
    global M2modeVars
    # alertnote "in M2::adjustElectricNumKeypad1 - M2modeVars($varName) = $M2modeVars($varName)"
    if $M2modeVars($varName) {
	M2::activateElectricNumKeypad1
    } else {
	M2::deactivateElectricNumKeypad1 
    }
}

proc M2::adjustLatestDevModeUse {varName} {
    global M2modeVars
    # alertnote "in M2::adjustLatestDevModeUse - M2modeVars($varName) = $M2modeVars($varName)"
    if {[info exists M2modeVars(m2ModeDevFolder)]} then {
        set m2ModeDir "${M2modeVars(m2ModeDevFolder)}"
    } else {
        set m2ModeDir "[file dirname [procs::find M2::enterM2Mode]]"
    }
    # Source the M2 mode
    source [file join ${m2ModeDir} m2Load.tcl]
    # Source global feature global M2 bindings
    source [file join ${m2ModeDir} globalM2bindings.tcl]
    # Inform user about what has been done
    if {[info exists M2modeVars(useLatestDevM2Mode)] && $M2modeVars(useLatestDevM2Mode)} then {
	alertnote "Have loaded latest development version of M2 mode"
    } else {
	alertnote "Activating the preinstalled version of M2 mode"
    }
}



set M2::whileAdjusting 0

proc M2::adjustM2Prefs {varName} {
    global M2::whileAdjusting M2modeVars
    set M2::whileAdjusting 1
    # alertnote "in M2::adjustM2Prefs at begin: varName = $varName"
    if {[catch {
	switch -- $varName {
	    "m2_author" { M2::adjustAuthor "$varName" }
	    "m2_shellName" { M2::adjustShellLaunching "$varName" }
	    "m2_errListDOK" { M2::adjustErrDOKFile "$varName" }
	    "m2_indentAmount" { M2::adjustRShiftAmount "$varName" }
	    "m2_leftShiftAmount" { M2::adjustLShiftAmount "$varName" }
	    "m2_fillRightMargin" { M2::adjustRightMargin "$varName" }
	    "m2_maxLineLength" { M2::adjustMaxLnLength "$varName" }
	    "m2_maxLnLeTol" { M2::adjustMaxLnLeTolerance "$varName" }
	    "m2_savedState" { M2::adjustSavedState "$varName" }
	    "spaceBarExpansion" { M2::adjustSpaceBarExpansion "$varName" }
	    "prefixString" { M2::adjustCommentChars "$varName" }
	    "suffixString" { M2::adjustCommentChars "$varName" }
	    "globalM2Bindings" { M2::adjustGlobalM2Bindings "$varName" }
	    "electricNumKeypad_1" { M2::adjustElectricNumKeypad1 "$varName" }
	    "useLatestDevM2Mode" { M2::adjustLatestDevModeUse "$varName" }
	}
    } err]} {
	alertnote "M2 mode error '$err' in M2::adjustM2Prefs"
    }
    set M2::whileAdjusting 0
    # alertnote "In M2::adjustM2Prefs at end: varName = '$varName'"
}



# Reporting that end of this script has been reached
status::msg "m2AdjPrefs.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote "m2AdjPrefs.tcl for Programing in Modula-2 loaded"
}

