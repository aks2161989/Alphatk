# We do not want to load all of M2 mode at startup!
# This file will be sourced when we actually want to load everything
# --- i.e. the first time we use M2 mode.

if {(![info exists M2::whileAdjusting]) | ([info exists M2::whileAdjusting] && ![set M2::whileAdjusting])} {
    proc M2::loadMode {} {}
}
    

namespace eval M2 {}

#===========================================================================
# ×××× Load other M2 mode files ×××× #
#===========================================================================
# Note, the following should take place on this level, not within a
# procedure, because of all global variables involved in the mode
# initialization.  Moreover, many scripts need to be loaded right away, since
# the mode is likely not to work fully otherwise.  An exception to this are
# m2AdjPrefs (may depend on Alpha version), m2Templates, m2CompErr, m2Utils,
# m2Marking, and m2HelpLookup, which could be loaded only if really needed,
# i.e. e.g. only when an identifier is command^double-clicked.  
#

# proc M2::enterM2Mode is for sure in m2Mode.tcl
set m2ModeDir "[file dirname [procs::find M2::enterM2Mode]]"
if {$m2ModeDir == ""} {
    set m2ModeDir [file join $HOME Tcl Modes "M2 Mode"]
}

if {[info exists M2modeVars(useLatestDevM2Mode)] && [info exists M2modeVars(m2ModeDevFolder)]} then {
    if $M2modeVars(useLatestDevM2Mode) {
	# e.g. /Volumes/HD/Documents/Origs!!/M2 Mode/M2 Mode/Modes/M2 Mode
	# set m2ModeDevFolder "/Volumes/HD/Documents/Origs!!/M2 Mode/M2 Mode/Modes/M2 Mode"
	if {[file exists [file join "${M2modeVars(m2ModeDevFolder)}" m2Mode.tcl]]} then {
	    # alertnote "Folder ${M2modeVars(m2ModeDevFolder)} exists"
	    set m2ModeDir "${M2modeVars(m2ModeDevFolder)}"
	} else {
	    # alertnote "${M2modeVars(m2ModeDevFolder)} does not exist"
	    set prompt "Select dir where you store the M2 mode's tcl files"
	    if {[catch {prompt $prompt "${M2modeVars(m2ModeDevFolder)}" } M2modeVars(m2ModeDevFolder)]} then {return 0} 
	    if {"${M2modeVars(m2ModeDevFolder)}" == ""} then {return 0}
	    prefs::modified m2ModeDevFolder
	    set m2ModeDir "${M2modeVars(m2ModeDevFolder)}"
	}
    }
}



if {![info exists M2::curAlphaV]} then {
    if {[catch {source [file join ${m2ModeDir} m2Mode.tcl]} err]} then {
	alertnote "Encountered error '$err' while sourcing 'm2Mode.tcl'!"
    }
}

# IT IS VITAL WE LOAD THE m2Prefs.tcl FILE NOW.  THE PRIMARY THING
# A MODE MUST ACCOMPLISH IN INITIALISATION IS TO CREATE ALL OF ITS
# PREFERENCES.
foreach tmp {
    m2Prefs m2GlobAux m2Menu m2Bindings m2Config
    m2CompErr m2ShellUse m2BackCompatibilty
    m2Syntax m2HelpLookup m2Templates
} {
    if {[file exists [file join ${m2ModeDir} ${tmp}.tcl]]} then {
	# alertnote "sourcing ${tmp}.tcl"
	if {[catch {source [file join ${m2ModeDir} ${tmp}.tcl]} err]} then {
	    alertnote "Encountered error '$err' while sourcing '${tmp}.tcl'!"
	}
    } else {
	alertnote "M2 mode's file '[file join ${m2ModeDir} ${tmp}.tcl]' seems\
	  to be missing. Could not load it!"
    }
}
unset tmp
unset -nocomplain err

# Reporting that end of this script has been reached
status::msg "m2Mode.tcl for Programing in Modula-2 loaded"
