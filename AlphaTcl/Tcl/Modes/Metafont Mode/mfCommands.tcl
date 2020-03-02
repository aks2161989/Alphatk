# File: "mfCommands.tcl"
#                        Created: 2001-02-06 22:07:36
#              Last modification: 2005-07-15 12:47:48
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metafont Mode package for Alpha.
# See comments at the beginning of 'mfMode.tcl'.

proc mfCommands.tcl {} {}

namespace eval Mf {}


# -------------------------------------------------------------------------
# Menus and submenus items procs
# -------------------------------------------------------------------------

proc Mf::menuProc {menu item} {
	global mf_params MfmodeVars 
	switch $item {
		"switchToMetafont" {
			set sig [Mf::getSignature]
			if {$sig ne ""} {
				app::launchFore $sig
			} 
		}
		"processTheBuffer" {
			if ![Mf::checkDirty] return
			Mf::runBuffer
		}
		"saveAndRun" {
			save
			Mf::runBuffer
		}
		"processAFile" {
			if {[catch {getfile "Select a \".mf\" file to process"} name]} {
				return
			} 
			edit -c $name
			Mf::runBuffer
		}
		"makeLongMenu" {Mf::makeLongMenu 1}
		"makeShortMenu" {Mf::makeLongMenu 0}
		default {eval Mf::$item}
	}
}


proc Mf::metafontPostprocessProc {submenu item} {
	global mf_params
	Mf::setNames [win::Current]
	switch -regexp $item {
		"convertGfToPk" -
		"convertGfToDvi" {
			if {[catch {Mf::findGfFile} res]} {return} 
			regsub "convert" $item "" serv
			set gffile [file join $mf_params(dirname) $res]
			Mf::invokeService $serv $gffile gf
			if {$serv eq "GfToDvi"} {
				set mf_params(prefix-dvi) ""
				menu::buildSome metafontPostprocess
			} 
		}
		"open.*\.log$" {
			Mf::editLogFile
		}
		"open.*\.pl$" {
			Mf::editPlFile
		}
		"view.*\.dvi"  {
			set dvifile [file join $mf_params(dirname) $mf_params(basename).dvi]
			Mf::invokeService viewDVI $dvifile
		}
		"convert.*\.dvitops" {
			set dvifile [file join $mf_params(dirname) $mf_params(basename).dvi]
			Mf::invokeService dvips $dvifile
		}
		"convert.*\.tfmtopl"  {
			set tfmfile [file join $mf_params(dirname) $mf_params(basename).tfm]
			Mf::invokeService TfmToPl $tfmfile tfm
			set mf_params(prefix-pl) ""
			menu::buildSome metafontPostprocess
		}
		"tfmToPl" -
		"vfToVpl" -
		"plToTfm" -
		"vplToVf" {
			set serv "[string toupper [string range $item 0 0]][string range $item 1 end]"
			Mf::postProcessing $serv
		}
	}
}


proc Mf::metafontUtilsProc {submenu item} {
	global mf_params 
	switch -regexp $item {
		"openplain.mf" -
		"openmodes.mf" {
			regexp {open(\w+)\.mf} $item -> name
			Mf::openMacroFile $name
		}
		"deleteAuxiliaryFiles" {
			if ![Mf::deleteAuxDialog] return
			foreach e $mf_params(extensions) {
				if {[set mf_params(delete-$e)]} {
					Mf::deleteAuxFile $e
				} 
			}
			status::msg "Done"
			Mf::rebuildSubmenus ""
		}
		"newFontTemplate" {Mf::newFontTemplate}
		"metafontBindings" {
			global tileLeft tileTop tileWidth errorHeight 
			new -g $tileLeft $tileTop [expr int($tileWidth*.5)] \
			  [expr {$errorHeight + 70}] -n "* Metafont Bindings *" \
			  -info [Mf::bindingsInfoString]
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


proc Mf::bindingsInfoString {} {
	set mess "KEY BINDINGS AVAILABLE IN METAFONT MODE\r\r"
	append mess "Press 'ctrl-m', release, then hit one of the following letters:\r"
	append mess "  'b'    to process the <b>uffer\r"
	append mess "  'd'    to process a <d>irectory\r"
	append mess "  'f'    to process a <f>ile\r"
	append mess "  'g'    to edit the lo<g> file\r"
	append mess "  'i'    to convert the gf file to dv<i>\r"
	append mess "  'k'    to convert the gf file to p<k>\r"
	append mess "  'l'    to select <l>ocalfont mode\r"
	append mess "  'n'    to create a <n>ew font template\r"
	append mess "  'p'    to select <p>roof mode\r"
	append mess "  's'    to select <s>moke mode\r"
	append mess "  't'    to convert the <t>fm file to pl\r"
	append mess "  'u'    to select <u>ser defined mode\r"
	append mess "  'v'    to <v>iew the d<v>i\r"
	return $mess
}


proc Mf::deleteAuxDialog {} {
	global mf_params
	set args ""
	lappend args [list -t "Select the extensions of files to delete:" 20 20 300 40 ]
	set y 20
	set x 30
	set i 0
	foreach e $mf_params(extensions) {
		if {[expr $i % 4] == 0} {
			set left $x
			incr y 20
		} else {
			incr left 60
		}
		eval lappend args [list -c $e $mf_params(delete-$e) $left $y [expr $left + 50] [expr $y + 20]]
		incr i
	}
	incr y 35
	set args [linsert $args 0 [list -b Delete 230 $y 310 [expr $y + 20] \
	  -b Cancel 130 $y 210 [expr $y + 20] ]]
	incr y 30
	set values [eval dialog -w 320 -h $y [join $args]]
	if {[lindex $values 1]} {return 0} 
	set i 2
	foreach e $mf_params(extensions) {
		set mf_params(delete-$e) [lindex $values $i]
		incr i
	}
	return 1
}


# Proc to dimm/undimm the items of the metafontUtils submenu
# depending on the existence of auxiliary files
proc Mf::rebuildSubmenus {name} {
	global mfMenu mf_params
	Mf::setNames [win::Current]
	if {$mf_params(extname) ne ".mf" && $mf_params(extname) ne ".pl"} {
		set mf_params(prefix-gf) "("
		set mf_params(prefix-dvi) "("
		set mf_params(prefix-log) "("
		set mf_params(prefix-tfm) "("
		set mf_params(prefix-pl) "("
	} else {
		if {[file exists [file join $mf_params(dirname) $mf_params(basename).pl]]} {
			set mf_params(prefix-pl) ""
		} else {
			set mf_params(prefix-pl) "("
		}
		if {[file exists [file join $mf_params(dirname) $mf_params(basename).dvi]]} {
			set mf_params(prefix-dvi) ""
		} else {
			set mf_params(prefix-dvi) "("
		}
		if {$mf_params(done) || [file exists [file join $mf_params(dirname) $mf_params(basename).log]]} {
			set mf_params(prefix-gf) ""
			set mf_params(prefix-log) ""
		} else {
			set mf_params(prefix-gf) "("
			set mf_params(prefix-log) "("
		}
		if {$mf_params(tfmdone) || [file exists [file join $mf_params(dirname) $mf_params(basename).tfm]]} {
			set mf_params(prefix-tfm) ""
		} else {
			set mf_params(prefix-tfm) "("
		}
	}
	menu::buildSome metafontPostprocess
	menu::buildSome metafontUtils
	set mf_params(done) 0
    set mf_params(tfmdone) 0
}


# Choosing Metafont printer mode
proc Mf::chooseModeProc {menu item} {
	global MfmodeVars mf_params
	switch $item {
		"proof" - "smoke" {
			set mf_params(chosenMode) $item
			Mf::markPrinterMode $item
			status::msg "mode $item - no tfm produced"
		}
		"localfont" {
			set mf_params(chosenMode) localfont
			Mf::markPrinterMode localfont
			status::msg "mode localfont"
		}
		"userDefined" {
			set mf_params(chosenMode) $MfmodeVars(mfModeForPrinter)
			Mf::markPrinterMode userDefined
			status::msg "mode \"$MfmodeVars(mfModeForPrinter)\""
			alertnote "Current user-defined mode is \"$MfmodeVars(mfModeForPrinter)\".\
			  You can change this in the Metafont mode preferences."
		}
	}
}


proc Mf::markPrinterMode {item} {
    Mf::clearAllModes
    markMenuItem metafontModes $item 1
}


proc Mf::clearAllModes {} {
	global mf_params
	foreach i $mf_params(modes) {
		markMenuItem metafontModes $i 0
	} 
}


proc Mf::metafontOptionsProc {menu item} {
	global mf_params
	switch $item {	
		"mag" {
			if {[catch {prompt "Choose a magnification" $mf_params(mag)} res]} {
				set res 1
			} 
			if {$res != 1} {
				set mf_params(magstep) 0
			}
			set mf_params(mag) $res
		}
		"magstep" {
			if {[catch {prompt "Choose a magstep coefficient " $mf_params(magstep)} res]} {
				set res 0
			} 
			if {$res != 0} {
				set mf_params(mag) 1
			}
			set mf_params(magstep) $res
		}
		"baseFile" {
			if {[catch {getfile "Select a base file"} res]} {
				set mf_params(baseFile) "" 
			} else {
				set mf_params(baseFile) [file tail $res] 
			}
		}
		"clearAllOptions" {Mf::clearAllOptions}
		default {Mf::toggleOption $item}
	}
	Mf::markOptionsMenu
}


proc Mf::toggleOption {name} {
    global mf_params
    eval set mf_params($name) [expr ![set mf_params($name)]]
    Mf::shadowMode $name
}


proc Mf::shadowMode {name} {
    global mf_params
    markMenuItem metafontOptions $name [set mf_params($name)]
}


proc Mf::shadowPrefs {name} {
	global mf_params MfmodeVars
	set mf_params($name) [set MfmodeVars($name)]
	Mf::shadowMode $name
}


proc Mf::markOptionsMenu {} {
	global mf_params
	if {$mf_params(mag) eq 1} {
		markMenuItem metafontOptions "mag…" 0
	} else {
		markMenuItem metafontOptions "mag…" 1
	}
	if {$mf_params(magstep) eq 0} {
		markMenuItem metafontOptions "magstep…" 0
	} else {
		markMenuItem metafontOptions "magstep…" 1
	}
	if {$mf_params(baseFile) eq ""} {
		markMenuItem metafontOptions "baseFile…" 0
	} else {
		markMenuItem metafontOptions "baseFile…" 1
	}
	foreach opt $mf_params(options) {
		markMenuItem metafontOptions $opt [set mf_params($opt)]
	}
}


proc Mf::clearAllOptions {} {
	global mf_params
	foreach i $mf_params(options) {
		eval set mf_params($i) 0
	}
	set mf_params(mag) 1
	set mf_params(magstep) 0
	set mf_params(baseFile) ""
	Mf::markOptionsMenu
}



