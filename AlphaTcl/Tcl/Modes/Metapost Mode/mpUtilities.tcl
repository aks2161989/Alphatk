# File: "mpUtilities.tcl"
#                        Created: 2001-02-20 23:45:29
#              Last modification: 2005-07-15 12:27:45
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metapost Mode package for Alpha. 
# See comments at the beginning of 'mpMode.tcl'.

proc mpUtilities.tcl {} {}

namespace eval Mp {}


# Utility procs
# =============

proc Mp::setNames {name} {
    global mp_params 
    set mp_params(fullname) $name
    set mp_params(dirname) [file dirname $name]
    set mp_params(tailname) [file tail $name]
    set mp_params(basename) [file rootname [file tail $name]]
    set mp_params(extname) [file extension [file tail $name]]
}


proc Mp::getSignature {} {
	set serv [xserv::getCurrentImplementationNameFor Mp ""]
	if {$serv eq ""} {
		array set impl [xserv::selectImplementationFor Mp]
		if {[info exists impl(-name)]} {
			set serv $impl(-name)
		} 
	} 
	set sig ""
	switch -- $serv {
		"CMacTex" {set sig "CMTw"}
		"OzMetapost" {set sig "OzMP"}
	}
	return $sig
}


proc Mp::checkDirty {} {
	if {[winDirty]} {
		switch [askyesno -c "Dirty window '[lindex [winNames] 0]'. Do you want to save it ?"] {
			"yes" {save}
			"no" {}
			"cancel" {return 0}
		}
	}
	return 1
}


proc Mp::openMacroFile {name ext} {
	global MpmodeVars
	set pref "pathTo[string totitle $name][string totitle $ext]File"
	if {![info exists MpmodeVars($pref)] || ![file exists [set MpmodeVars($pref)]]} {
		alertnote "Can't find file $name.$ext: please locate it…"
		if {[catch {getfile "Locate file $name.$ext"} thepath]} {
			return
		} 
		set MpmodeVars($pref) $thepath
		prefs::modified MpmodeVars($pref)
	}
	edit -c -r $MpmodeVars($pref)
}

 
proc Mp::deleteAuxFile {ext} { 
	global mp_params
	set dir [file dirname [win::Current]]
	set filesindir [glob -nocomplain -dir $dir *.$ext]
	if {[llength $filesindir] == 0} {
		status::msg "No \"$ext\" file in current folder."
		return
	}
	foreach file $filesindir {
		catch {file delete $file}
	}
}


proc Mp::editAuxiliary {ext} {
	global mp_params 
	Mp::setNames [win::Current]
	set file [file join $mp_params(dirname) $mp_params(basename).$ext]
	if {![file exists $file]} {
		alertnote "Can't find file '$file'."
		return
	} 
	edit -c -w -r $file
}


# Choose the number of labels for a dotlabels command
proc Mp::mkdotlabelsProc {ext} {
	if {[catch {prompt "How many labels?" 3} numdlb]} {return} 
	if {![is::PositiveInteger $numdlb]} {
		status::msg "invalid input: please enter a positive integer"
		return
	}
	if {$numdlb} {
		set i 1
		if {$ext == "nil"} {
			set body "dotlabels(•"
		} else {
			set body "dotlabels.${ext}(•"
		}
		append body [string repeat ",•" $numdlb]
		append body ");\n•"
	} else {
		set body "•\n"
	}
	insertText $body
}


