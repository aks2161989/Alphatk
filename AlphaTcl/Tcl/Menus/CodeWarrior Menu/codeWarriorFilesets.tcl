# -*-Tcl-*- (nowrap)
# 
# File: codeWarriorFilesets.tcl
# 							Last modification: 2005-03-29 19:14:28
# 
# Description : this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to the definition of a codewarrior 
# type of filesets.

proc codeWarriorFilesets.tcl {} {}

namespace eval cw {}
namespace eval fileset::codewarrior {}

# Make sure the CW menu is loaded
cw::checkRunning 0

# -----------------------------------------------------------------
# Fileset procs
# -----------------------------------------------------------------

proc cw::createCWFileset {} {
	if {![cw::isProjectOpen 0]} {return}
	cw::currentTarget
    newFileset codewarrior
}


proc cw::getProjectFiles {extras} {
	global cw_params 
	if {![cw::checkRunning]} {return} 

	set AcceptPatterns [lindex $extras 2]
	set IgnorePatterns [lindex $extras 3]
	set idx [cw::findProjectIndex [lindex $extras 0]]
	if {$idx == 0} {
		alertnote "Project '[lindex $extras 0]' is not opened."
		return
	} 
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT [lindex $extras 1]] \
	  [tclAE::build::indexObject PRJD $idx]]
	
	# List of all source files
	set scrfList [cw::propertyList Path $targetobj "source files"]
	
	if {[llength $scrfList]} {
		set result ""
		foreach f $scrfList {
			foreach accPat $AcceptPatterns {
				if {[string match $accPat $f]} {
					set matchOK 1
					foreach ignPat $IgnorePatterns {
						if {[string match $ignPat $f]} {
							set matchOK 0
							break
						} 
					} 
					if {$matchOK} {
						# CW returns paths mixing "/" and ":" (like "hd/usr:lib:crt1.o")
						lappend result [file tail [file::FinderPathToUnix $f]]
					} 
					break
				} 
			} 
		} 
		return [lsort -dictionary $result]
	} else {
		alertnote "Couldn't get source files." "Make sure the target '[lindex $extras 1]'\
		  of project '[lindex $extras 0]' has been built: CodeWarrior returns an empty\
		  list if the project has not been built at least once."
		return ""
	}
}


proc fileset::codewarrior::createTagFile {} { return [alphaCreateTagFile] }


proc fileset::codewarrior::create {{name ""}} {
    global gfileSets gfileSetsType fileSetsExtra cw_params

	if {![string length $name]} {
	    set name [prompt "New fileset name:" ""]
	}
	if {![string length $name]} {
	    status::msg "Cancelled -- no text was entered."
	    return
	}
	set filePat [prompt "File pattern:" "*"]
	
	set fileSetsExtra($name) [list $cw_params(currProjectName) $cw_params(currTarget)]
	lappend fileSetsExtra($name) $filePat
	set filePatIgnore [prompt "List of file patterns to ignore:" ""]
	if {$filePatIgnore != ""} {
	    lappend fileSetsExtra($name) $filePatIgnore
	}
	
    set gfileSets($name) [cw::getProjectFiles $fileSetsExtra($name)]
    set gfileSetsType($name) codewarrior
    return $name
}


proc fileset::codewarrior::updateContents {name {andMenu 0}} {
	global gfileSets fileSetsExtra cw_params

	if {$andMenu} {
		set menu [list]
		set gfileSets($name) [cw::getProjectFiles $fileSetsExtra($name)]
		set flist [getFilesInSet $name]
		foreach m $flist {
			lappend menu "[file tail $m]&"
		}
		return [filesetMenu::makeSub $name $name fileset::openItemProc $menu]
	} else {
		return [list]
	}
}


proc fileset::codewarrior::selected {fset menu item} {
	if {[catch {fileset::codewarrior::pathFromName $fset $item} res]} {
		alertnote $res
	} elseif {$res ne ""} {
		edit -c $res
	}
}


proc fileset::codewarrior::getDialogItems {name} {
	global fileSetsExtra cw_params
	if {[info exists fileSetsExtra($name)] && $fileSetsExtra($name) != ""} {
		set cur $fileSetsExtra($name)
	} else {
		# Reasonable defaults
		set cur [list $cw_params(currProjectName) $cw_params(currTarget) *.* \
		  [list *.o *.lib *.icns *.rsrc]]
		set fileSetsExtra($name) $cur
	}
	lappend res [list variable "Project:" [lindex $cur 0]]
	lappend res [list variable "Target:" [lindex $cur 1]]
	lappend res [list variable "File pattern:" [lindex $cur 2] \
	  "Only include files which match this pattern"]
	lappend res [list variable "List of file patterns to ignore:" [lindex $cur 3]]
	set res
}


proc fileset::codewarrior::setDetails {name proj targ pat ignore} {
    global gfileSets fileSetsExtra
    set fileSetsExtra($name) [list $proj $targ $pat $ignore]
    set gfileSets($name) [cw::getProjectFiles $fileSetsExtra($name)]
    modifyFileset $name
}


proc fileset::codewarrior::pathFromName {fset name} {
	global fileSetsExtra cw_params
	set data [set fileSetsExtra($fset)]
	
	if {![cw::checkRunning]} {return ""} 
	set idx [cw::findProjectIndex [lindex $data 0]]
	if {$idx == 0} {
		error "Project '[lindex $data 0]' is not opened"
	} 
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT [lindex $data 1]] \
	  [tclAE::build::indexObject PRJD $idx]]
	
	set scrfList [cw::propertyList Path $targetobj "source files"]
	if {![string length $scrfList]} {
		error "No files for target [lindex $data 1]"
	} 
	set fileidx [cw::findFileIndex $scrfList $name]
	
	if {$fileidx} {
		set path [lindex $scrfList [expr $fileidx - 1]]
		regsub -all / $path : path
		set path [file::FinderPathToUnix $path]
	} else {
		set path ""
	}
	return $path
}