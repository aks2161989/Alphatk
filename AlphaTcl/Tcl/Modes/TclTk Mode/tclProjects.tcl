## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclProjects.tcl"
 #                                          created: 04/05/1997 {09:31:10 pm}
 #                                      last update: 2005-02-24 09:30:31
 # Description:
 # 
 # Supports the creation of different projects associated with given
 # windows/files, and the interpreters that they use.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2004 Vince Darley
 # All rights reserved.
 # 
 # ==========================================================================
 ##

# Make sure that the "tclMode.tcl" file has been sourced.
# This sets some initial Tcl mode 'project' preferences.
tclMode.tcl

proc tclProjects.tcl {} {}

namespace eval Tcl {}

# Called in "tclComm.tcl" procedures, esp [tcltk::getInterpCmd].

proc Tcl::synchroniseProjectHook {{name ""}} {
    
    if {![string length $name]} {
	set name [win::Current]
    }
    if {![string length $name]} {
	return
    }
    if {[string length [set proj [Tcl::findProjectFor $name]]]} {
	Tcl::setProject $proj
    }
    return $proj
}

proc Tcl::projectInfo {{proj ""}} {
    
    global TclmodeVars Tclprojects
    
    if {![string length $proj]} {
	set proj $TclmodeVars(project)
    }
    return $Tclprojects($proj)
}

proc Tcl::project {{proj ""}} {
    
    global TclmodeVars
    
    if {![string length $proj]} {
	return $TclmodeVars(project)
    } else {
	return $proj
    }
}

proc Tcl::setProject {proj} {
    
    global TclmodeVars
    
    if {($proj != $TclmodeVars(project))} {
	set TclmodeVars(project) $proj
	menu::buildSome tclMenu
    }
    return
}

proc Tcl::interpDied {interp} {
    
    global TclprojectEvalCmd
    
    # Remove array element.
    foreach arr [array names TclprojectEvalCmd] {
	if {($TclprojectEvalCmd($arr) eq $interp)} {
	    unset TclprojectEvalCmd($arr)
	    break
	}
    }
    set msg "The remote shell has died, sorry."
    if {[dialog::yesno -y "Use Internal Interp" -n "Cancel" $msg]} {
	Tcl::setProject AlphaTcl
	return [list tcltk::internalEvaluate]
    } else {
	error "cancel"
    }
}

proc Tcl::getInterp {{proj ""}} {
    
    global TclprojectEvalCmd

    set proj [Tcl::project $proj]
    if {[info exists TclprojectEvalCmd($proj)] \
      && [string length $TclprojectEvalCmd($proj)]} {
	set interp [set TclprojectEvalCmd($proj)]
    } else {
	set interp [list tcltk::internalEvaluate]
    }
    return $interp
}

proc Tcl::findProjectFor {winName} {
    
    global Tclprojects
    
    if {![win::IsFile $winName]} {
	return ""
    }
    foreach proj [array names Tclprojects] {
	set fileset [lindex $Tclprojects($proj) 5]
	if {[string length $fileset] && [fileset::exists $fileset]} {
	    if {[fileset::isIn $fileset $winName]} {
		return $proj
	    }
	}
    }
    return ""
}

proc Tcl::editProjects {} {
    
    global TclmodeVars Tclprojects
    
    set result [dialog::editGroup -array Tclprojects -delete ask \
      -new Tcl::newProjectDetails \
      -title "Edit Tcl project information" \
      -current $TclmodeVars(project) \
      [list "mainFile" file "Main project file"\
      "This is the main file which will be evaluated by a Tcl\
      interpreter to run the project"] \
      [list "shell" appspec "Tcl interpreter to use"\
      "Which Tcl interpreter (executable) to use for this project"] \
      [list "fileset" fileset "Fileset associated with this project"\
      "A fileset containing files associated with the project, if it\
      is a multi-file project"]]
    # This works whether projects have been modified or deleted.
    foreach proj $result {
	prefs::modified Tclprojects($proj)
    }
    if {[llength $result]} {
	# Should now rebuild the menu in case we've added or removed a
	# project.  This will also reset the internal Tcl var 'interpCmd'.
	menu::buildSome tclMenu
    }
    return
}

proc Tcl::newProjectDetails {} {
    
    set name [prompt "Descriptive name of new project" ""]
    if {[string length $name]} {
	return [list $name [list mainFile [win::StripCount [win::Current]] \
	  fileset "" shell ""]]
    } else {
	return ""
    }
}

proc Tcl::wrapProjectAsStarkit {{proj ""}} {
    Tcl::wrapProject starkit $proj
    return
}

proc Tcl::wrapProjectAsStarpack {{proj ""}} {
    Tcl::wrapProject starpack $proj
    return
}

proc Tcl::wrapProject {type {proj ""}} {
    global tcl_platform Tclprojects HOME
    
    if {$tcl_platform(platform) eq "macintosh"} {
	alertnote "Sorry, not yet implemented for MacOS < X"
	return
    }

    # evaluate 'tclsh sdx.kit wrap project.kit -writable'
    if {$proj eq ""} {
	set proj [Tcl::synchroniseProjectHook]
	if {$proj eq ""} {
	    set proj "Current Window"
	}
    }
    set fileset [lindex $Tclprojects($proj) 5]
    if {$proj eq "Current Window"} {
	set mainfile [win::Current]
    } else {
	set mainfile [lindex $Tclprojects($proj) 1]
    }
    if {$fileset eq ""} {
	if {$mainfile eq ""} {
	    alertnote "There is no fileset and no mainfile\
	      associated with the \"$proj\" project."
	    return
	}
	set res [dialog::yesno -y "Wrap Current Window Only" \
	  -n "Use the '[file tail [file dirname $mainfile]]' directory" \
	  -c  "The \"$proj\" project has no associated fileset"]
	if {$res} {
	    set dir "[file root $mainfile].vfs"
	    file mkdir $dir
	    file copy -force $mainfile [file join $dir [file tail $mainfile]]
	    set fout [open [file join $dir main.tcl] w]
	    puts $fout "source \[file join \[file dirname \[info script\]\] [file tail $mainfile]\]"
	    close $fout
	    set delete 1
	} else {
	    set dir [file dirname $mainfile]
	}
    } else {
	set dir [fileset::getBaseDirectory $fileset]
    }
    
    set old [pwd]
    cd [file dirname $dir]
    set root [file root [file tail $dir]]
    
    if {$type eq "starkit"} {
	set opts [list $root.kit -writable]
    } else {
	set app [xserv::invoke tclKitGetApplication]
	file copy -force $app [set runtime [temp::path starpack $app]]
        set opts [list $root.exe -runtime $runtime]
    }
    
    if {[file extension $dir] != ".vfs"} {
	file rename $dir $dir.vfs
	::xserv::invoke tclKitEvaluate [concat [list [file join $HOME Tools sdx.kit] \
	  wrap] $opts]
	file rename $dir.vfs $dir
    } else {
	::xserv::invoke tclKitEvaluate [concat [list [file join $HOME Tools sdx.kit] \
	  wrap] $opts]
    }
    cd $old
    if {[info exists delete]} {
	file delete -force $dir
    }
    if {[info exists runtime]} {
	file delete -force $runtime
    }
    return
}

# ===========================================================================
# 
# .
