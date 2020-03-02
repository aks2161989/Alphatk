# File: "mfUtilities.tcl"
#                        Created: 2001-02-06 22:07:36
#              Last modification: 2005-07-15 12:48:10
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metafont Mode package for Alpha.
# See comments at the beginning of 'mfMode.tcl'.

proc mfUtilities.tcl {} {}

namespace eval Mf {}


# Utility procs
# =============

proc Mf::setNames {name} {
	global mf_params MfmodeVars
	set mf_params(fullname) $name
	set mf_params(dirname) [file dirname $name]
	set mf_params(tailname) [file tail $name]
	set mf_params(basename) [file rootname [file tail $name]]
	set mf_params(extname) [file extension $name]
}


proc Mf::getSignature {} {
	set serv [xserv::getCurrentImplementationNameFor Mf ""]
	if {$serv eq ""} {
		array set impl [xserv::selectImplementationFor Mf]
		if {[info exists impl(-name)]} {
			set serv $impl(-name)
		} 
	} 
	set sig ""
	switch -- $serv {
		"CMacTex" {set sig "CMT3"}
		"OzMetafont" {set sig "OzMF"}
	}
	return $sig
}


# --------------------------------------------------------------------------
# This proc looks in the current log file for a line indicating the name of
# the gf file produced by Metafont: its extension depends on the printer
# mode and the magnification.
# --------------------------------------------------------------------------
proc Mf::findGfFile {} {
	global mf_params 
	set logfile [file join $mf_params(dirname) $mf_params(basename).log]
	if {![Mf::checkExists $logfile log]} {error}
	set fid [open $logfile]
	set txt [read $fid]
	close $fid
	if {[regexp "\.(\\d+gf)" $txt dum ext]} {
		return "$mf_params(basename).$ext"
	} else {
		error "According to $mf_params(basename).log, no gf output written."
	}
} 


proc Mf::checkDirty {} {
	if {[winDirty]} {
		switch [askyesno -c "Dirty window '[lindex [winNames] 0]'. Do you want to save it before?"] {
			"yes" {save}
			"no" {}
			"cancel" {return 0}
		}
	}
	return 1
}


proc Mf::checkExists {file {type ""}} {
	if {![file exists $file]} {
		set msg "Can't find file '$file'."
		if {[xserv::getCurrentImplementationNameFor Mf ""] eq "OzMetafont"} {
			if {$type ne ""} {
				append msg "Check that the \"delete_$type\" flag is set to false in OzMetafont configs."
			} 
		} 
		alertnote $msg
		return 0
	}
	return 1
}


proc Mf::findResolution {} {
	global MfmodeVars mf_params
	if {$mf_params(chosenMode) == "proof"} {
		return [list "proof" "2602"]
	}
	if {$mf_params(chosenMode) == "smoke"} {
		return [list "smoke" "2602"]
	}
	if {[file exists $MfmodeVars(pathToModesMfFile)]} {
		set fid [open "$MfmodeVars(pathToModesMfFile)"]
		set txt [read $fid]
		close $fid
		if {$mf_params(chosenMode) == "localfont"} {
			if {[regexp {localfont[ \t]*:=[ \t]*([^;]+);} $txt -> localMfmode]} {
				set localMfmode [string trim $localMfmode]
			} else {
				error "Can't find localfont in modes.mf"
			}			
		} else {
			set localMfmode $MfmodeVars(mfModeForPrinter)			
		}
		# Now find the resolution in dpi
		set start [string first "mode_def $localMfmode" $txt]
		if {$start == -1} {
			error "Unknown mode $localMfmode."
		}
		set txt [string range $txt $start end]
		regexp {pixels_per_inch[^0-9)]*([0-9]+)} $txt -> dpi
		return [list $localMfmode $dpi]
	} else {
		error "Can't find file modes.mf: set the path in the mode preferences."
	}
}


proc Mf::openMacroFile {name} {
	global MfmodeVars
	set pref "pathTo[string totitle $name]MfFile"
	if {![info exists MfmodeVars($pref)] || ![file exists [set MfmodeVars($pref)]]} {
		alertnote "Can't find file $name.mf: please locate it╔"
		if {[catch {getfile "Locate file $name.mf"} thepath]} {
		    return
		} 
		set MfmodeVars($pref) $thepath
		prefs::modified MfmodeVars($pref)
	}
	edit -c -r $MfmodeVars($pref)
}

 
proc Mf::deleteAuxFile {ext} { 
	global mf_params
	set dir [file dirname [win::Current]]
	if {![regexp "gf" $ext] && ![regexp "pk" $ext]} {
		set ext ".$ext"
	}
	set filesindir [glob -nocomplain -dir $dir *$ext]
	if {[llength $filesindir] == 0} {
		status::msg "No \"$ext\" file in current folder."
		return
	}
	foreach file $filesindir {
		catch {file delete $file}
	}
}


# --------------------------------------------------------------------------
# Choose the number of horizontal and vertical lines in a grid
# --------------------------------------------------------------------------
proc Mf::mkgridProc {} {
	if {[catch {prompt "How many x-coordinates?" 3} numbx]} {return} 
	if {![is::PositiveInteger $numbx]} {
		status::msg "invalid input: please enter a positive integer"
		return
	}
	if {[catch {prompt "How many y-coordinates?" 3} numby]} {return} 
	if {![is::PositiveInteger $numby]} {
		status::msg "invalid input: please enter a positive integer"
		return
	}
	if {$numbx && $numby} {
		set body "makegrid(е"
		append body [string repeat ",е" $numbx]
		append body ")(е"
		append body [string repeat ",е" $numby]
		append body ");\nе"
	} else {
		set body "е\r"
	}
	insertText $body
}


# --------------------------------------------------------------------------
# Choose the number of points on a flex path
# --------------------------------------------------------------------------
proc Mf::mkflexProc {} {
	if {[catch {prompt "How many points on the flex-path?" 3} numbp]} {return} 
	if {![is::PositiveInteger $numbp]} {
		beep
		status::msg "Invalid input: please enter a positive integer"
		return
	}
	if {$numbp} {
		set body "flex(е[string repeat ",е" $numbp]) е"
	} else {
		set body "е\r"
	}
	insertText $body
}


# --------------------------------------------------------------------------
# Choose the number of points on a penstroke
# --------------------------------------------------------------------------
proc Mf::penstrokeProc {} {
	if {[catch {prompt "How many points on the penstroke ?" 3} numbp]} {
		return
	} elseif {![is::PositiveInteger $numbp]} {
		status::msg "invalid input: please enter a positive integer"
		return
	}
	if {$numbp} {
		set body "penstroke z1e"
		for {set i 2} {$i < [expr {$numbp + 1}]} {incr i} {
			append body "..z${i}e"
		}
		append body " ;"
	} else {
		set body "ее\r"
	}
	insertText $body
}

