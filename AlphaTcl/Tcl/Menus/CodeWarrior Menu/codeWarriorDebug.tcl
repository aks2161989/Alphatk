# -*-Tcl-*- (nowrap)
# 
# File: codeWarriorDebug.tcl
# 							Last modification : 2003-10-28 11:14:22
# 
# Description : this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to 

proc codeWarriorDebug.tcl {} {}

namespace eval cw {}


# -----------------------------------------------------------------
# Debugging procs
# -----------------------------------------------------------------

proc cw::setBreakpoint {} {
    cw::doBreakpoint Sbrk
}


proc cw::clearBreakpoint {} {
    cw::doBreakpoint Cbrk
}


proc cw::showinIDE {} {
    cw::doBreakpoint Show
}


proc cw::doBreakpoint {what} {
    global cw_params 
    cw::checkDebuggerSig
	if {$what eq "Show"} {
		switchTo $cw_params(dbgsig)
	} 
    set fname [win::StripCount [win::Current]]
    set ln [lindex [pos::toRowCol [getPos]] 0]
    set res [tclAE::send -t 500000 -r $cw_params(dbgsig) $cw_params(dbgclass) $what \
      ---- [tclAE::build::alis $fname] Line long($ln)]
}


proc cw::editLinkMap {} {
	global cw_params
	if {![cw::isProjectOpen]} {return} 
	# Find the output folder set in the "Target Settings" panel
	set outputFold [cw::getOutputFolder]
	if {$outputFold!=""} {
		set filelist [glob -nocomplain -dir $outputFold *.xMAP]
		set debuglist ""
		foreach f $filelist {
			lappend debuglist [file tail $f]
		} 
		if {![llength $debuglist]} {
			alertnote "Weird. No '.xMAP' file in output folder \"$outputFold\".\rDid you set the\
			  'Generate Link Map' flag on?"
			return
		} 
		if {![catch {set outputName [listpick -p "File to open:" $debuglist]}]} {
			edit -c "[file join $outputFold $outputName]"
		} 
	} else {
		alertnote "Couldn't find output folder."
	}
}

# This proc finds the expanded output folder for the current target. The AppleEvent
# can return various kinds of path :
# 	'Abso': An absolute path name, including volume name.
# 	'PRel': A path relative to the current projectÕs folder.
# 	'SRel': A path relative to the CodeWarriorª folder.
# 	'YRel': A path relative to the system folder
# 	'RRel': A path root relative
proc cw::getOutputFolder {} {
	global cw_params
	set outputFold ""

	catch {
		set aedesc [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) Gref PNam [tclAE::build::TEXT "Target Settings"]]
		set theobj [tclAE::getKeyDesc $aedesc ----]
		set thesubobj [tclAE::getKeyDesc $theobj TA16]
		
		set outputFold [tclAE::getKeyData $thesubobj pnam]
		regsub -all : $outputFold / outputFold
		set kind [tclAE::getKeyData $thesubobj Orig]
	# 	set form [tclAE::getKeyData $thesubobj Frmt]

		switch $kind {
			"Abso" {
				# Nothing
			}
			"PRel" {
				cw::currentProject
				if {$cw_params(currProjectPath) == ""} {break} 
				set outputFold "[file dirname $cw_params(currProjectPath)]$outputFold"
			}
			"SRel" - "RRel" - "YRel" {}
		}
	}
	return $outputFold
}


