# File: "mpCommands.tcl"
#                        Created: 2001-02-20 23:28:24
#              Last modification: 2005-08-31 12:00:00
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metapost Mode package for Alpha. 
# See comments at the beginning of 'mpMode.tcl'.

proc mpCommands.tcl {} {}

namespace eval Mp {}


# -------------------------------------------------------------------------
# Menus and submenus items procs
# -------------------------------------------------------------------------

proc Mp::menuProc {menu item} {
	global mp_params 
	switch $item {
		"switchToMetapost" {
			set sig [Mp::getSignature]
			if {$sig ne ""} {
				app::launchFore $sig
			} 
		}
		"runTheBuffer" {
			Mp::setNames [win::Current]
			if ![Mp::checkDirty] return
			Mp::runBuffer
		}
		"saveAndRun" {
			save
			Mp::setNames [win::Current]
			Mp::runBuffer
		}
		"runAFile" {
			if {[catch {getfile "Select a \".mp\" file to process"} name]} {return} 
			Mp::setNames $name
			edit -c $mp_params(fullname)
			if {[file exists $mp_params(fullname)]} {
				Mp::runBuffer
			}
		}
		"makeLongMenu" {Mp::makeLongMenu 1}
		"makeShortMenu" {Mp::makeLongMenu 0}
	}
}


proc Mp::metapostUtilsProc {submenu item} {
	global mp_params  
	switch -regexp $item {
		"open.*\.log$" {Mp::editAuxiliary log}
		"open.*\.mpx$" {Mp::editAuxiliary mpx}
		"openmodes.mf" -
		"openplain.mp" -
		"openmfplain.mp" -
		"openplain.mf" {
			regexp {open(\w+)\.(\w+)} $item -> name ext
			Mp::openMacroFile $name $ext
		}
		"deleteAuxiliaryFiles" {
			if ![Mp::deleteAuxDialog] return
			foreach e $mp_params(extensions) {
				if {[set mp_params(delete-$e)]} {
					Mp::deleteAuxFile $e
				} 
			}
			Mp::rebuildMetapostUtils ""
		}
		"figsFileTemplate" {Mp::newtemplateProc}
		"metapostBindings" {
			global tileLeft tileTop tileWidth errorHeight
			new -g $tileLeft $tileTop [expr $tileWidth*.5] [expr $errorHeight + 60] \
			  -n "* Metapost Bindings *" -info [Mp::bindingsInfoString]
			set start [minPos]
			while {![catch {search -f 1 -s -r 1 {('|<)[a-z-]+('|>)} $start} res]} {
				eval text::color $res 1
				set start [lindex $res 1]
			}
			text::color [minPos] [nextLineStart [minPos]] 5
			refresh
		}       
	}
}


proc Mp::bindingsInfoString {} {
	set mess "KEY BINDINGS AVAILABLE IN METAPOST MODE\n\n"
	append mess "Press 'ctrl-p', release, then hit one of the following letters:\n"
	append mess "  'b'    to process the <b>uffer\n"
	append mess "  'f'    to process a <f>ile\n"
	append mess "  'g'    to edit the lo<g> file\n"
	append mess "  'n'    to create a <n>ew figs template\n"
	append mess "  'x'    to edit the mp<x> file\n"
	return $mess
}


proc Mp::deleteAuxDialog {} {
	global mp_params
	set args ""
	lappend args [list -t "Select the extensions of files to delete:" 20 20 300 40 ]
	set y 20
	set x 30
	set i 0
	foreach e $mp_params(extensions) {
		if {[expr $i % 4] == 0} {
			set left $x
			incr y 20
		} else {
			incr left 60
		}
		eval lappend args [list -c $e $mp_params(delete-$e) $left $y [expr $left + 50] [expr $y + 20]]
		incr i
	}
	incr y 35
	set args [linsert $args 0 [list -b Delete 230 $y 310 [expr $y + 20] \
	  -b Cancel 130 $y 210 [expr $y + 20] ]]
	incr y 30
	set values [eval dialog -w 320 -h $y [join $args]]
	if {[lindex $values 1]} {return 0} 
	set i 2
	foreach e $mp_params(extensions) {
		set mp_params(delete-$e) [lindex $values $i]
		incr i
	}
	return 1
}


# No commands in this menu, only submenus
proc Mp::mfplainMacrosProc {submenu item} {}


# A proc to dimm/undimm the items of the "Related Files" submenu
# depending on the existence of auxiliary files
proc Mp::rebuildMetapostUtils {name} {
	global mp_params 
	Mp::setNames [win::Current]
	if {$mp_params(extname) ne ".mp" && $mp_params(extname) ne ".mpx"} {
		set mp_params(tailname) ""
		set mp_params(prefix-log) "("
		set mp_params(prefix-mpx) "("
	} else {
		if {[file exists [file join $mp_params(dirname) $mp_params(basename).log]]} {
			set mp_params(prefix-log) ""
		} else {
			set	mp_params(prefix-log) "("
		}
		if {[file exists [file join $mp_params(dirname) $mp_params(basename).mpx]]} {
			set mp_params(prefix-mpx) ""
		} else {
			set	mp_params(prefix-mpx) "("
		}
	}
	menu::buildSome metapostUtils
}



