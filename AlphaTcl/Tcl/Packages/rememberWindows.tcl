## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "rememberWindows.tcl"
 #                                    created: 09/11/2000 {11:13:30 AM} 
 #                                last update: 03/21/2006 {02:18:39 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley, all rights reserved
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Only really useful for Alphatk, since Alpha has this functionality
 # built in through resource forks provided by MacOS.  Therefore this
 # file requires Tcl 8.x.  It may eventually be useful for Alpha as well,
 # when editing files on volumes that don't support resource forks.
 # 
 # The following window information is saved and re-introduced when the
 # same window is subsequently opened:
 #   - cursor position
 #   - selection 
 #   - first line displayed
 #   - mode (if it was manually changed)
 #   - tabsize (again, if manually changed)
 #   - manually applied colours/styles and hypertext links
 #   - window size (width, height), position
 #   
 # Future: the marks, or encoding could be saved.  i.e. we could
 # implement a general sort of 'resource fork' mechanism for files
 # without any.
 # 
 # ###################################################################
 ##

alpha::feature rememberWindows 0.4.0 global {
    namespace eval rememberWindows {}
    prefs::updateHome rememberWindows::memory name
    newPref flag rememberMode 1 rememberWindows
    newPref flag rememberTabSize 1 rememberWindows
    newPref flag rememberWindowPosition 0 rememberWindows
    newPref flag rememberColorsAndHypers 0 rememberWindows
    newPref flag rememberFoldedSections 1 rememberWindows
    newPref flag rememberUseOfMarginLineNumbers 1 rememberWindows
    package::addPrefsDialog rememberWindows
} {
    hook::register preCloseHook rememberWindows::Close
    hook::register openHook rememberWindows::Open
    hook::register winChangedNameHook rememberWindows::NameChanged
} {
    hook::deregister preCloseHook rememberWindows::Close
    hook::deregister openHook rememberWindows::Open
    hook::deregister winChangedNameHook rememberWindows::NameChanged
} description {
    This feature will record and restore information on tabsize, cursor
    position, etc about windows when they are opened/closed.
} help {
    This feature will record information about windows when they are closed, so
    the cursor position, selection, etc.  can be restored the next time that
    window is opened.
    
    Preferences: Features
    
    The following window information is saved and re-introduced when the
    same window is subsequently opened:
      - cursor position
      - selection 
      - first line displayed
      - mode (if it was manually changed)
      - tabsize (again, if manually changed)
      - manually applied colours/styles and hypertext links
      - window size (width, height), position
      - which sections of text in the window have been folded (hidden)
      - whether the window had a vertical margin with line numbers showing
    
    This feature is only useful for Alphatk since Alpha already does
    most of this by storing the information in the MacOS resource fork
    of each file.  (See the "Alpha Manual # File formats" Help file
    section for more information.)
} uninstall this-file maintainer {
    "Vince Darley" vince@santafe.edu <http://www.santafe.edu/~vince/>
} requirements {
    if {$alpha::platform ne "tk"} {
	error "Only useful for Alphatk"
    }
}

proc rememberWindows.tcl {} {}

namespace eval rememberWindows {}

proc rememberWindows::Close {name} {
    if {![win::IsFile $name stripped]} { return }
    variable memory
    getWinInfo -w $name arr
    set memory($stripped) [list [getPos -w $name] [selEnd -w $name] \
      $arr(currline)]
    
    global rememberWindowsmodeVars
    global lineNumbers
    variable origMode
    variable origTabSize
    variable origWindowPos
    
    if {$rememberWindowsmodeVars(rememberMode) \
      && [info exists origMode($name)] \
      && ([win::getMode $name] ne $origMode($name))} {
	unset origMode($name)
	lappend memory($stripped) [win::getMode $name]
    } else {
	lappend memory($stripped) ""
    }
    
    if {$rememberWindowsmodeVars(rememberTabSize) \
      && [info exists origTabSize($name)] \
      && ($arr(tabsize) != $origTabSize($name))} {
	unset origTabSize($name)
	lappend memory($stripped) $arr(tabsize)
    } else {
	lappend memory($stripped) ""
    }

    if {$rememberWindowsmodeVars(rememberWindowPosition) \
      && [info exists origWindowPos($name)] \
      && ([getGeometry $name] != $origWindowPos($name))} {
	unset origWindowPos($name)
	lappend memory($stripped) [getGeometry $name]
    } else {
	lappend memory($stripped) ""
    }

    if {$rememberWindowsmodeVars(rememberColorsAndHypers)} {
	lappend memory($stripped) [getColors -w $name]
    } else {
	lappend memory($stripped) ""
    }
    
    if {$rememberWindowsmodeVars(rememberFoldedSections)} {
	lappend memory($stripped) [fold -w $name info]
    } else {
	lappend memory($stripped) ""
    }
    
    if {$rememberWindowsmodeVars(rememberUseOfMarginLineNumbers) \
      && ($lineNumbers != $arr(linenumbers))} {
	lappend memory($stripped) $arr(linenumbers)
    } else {
	lappend memory($stripped) ""
    }
    
    prefs::modified rememberWindows::memory($stripped)
}

proc rememberWindows::Open {name} {
    variable memory
    global rememberWindowsmodeVars
    global lineNumbers
    
    if {![win::IsFile $name stripped]} { return }
    
    # Store the original mode and tab-size and position.
    variable origMode
    variable origTabSize
    variable origWindowPos

    set curMode [win::getMode $name]
    if {$rememberWindowsmodeVars(rememberMode)} {
	set origMode($name) $curMode
    } else {
	set origMode($name) ""
    }
    if {$rememberWindowsmodeVars(rememberWindowPosition)} {
	set origWindowPos($name) [getGeometry $name]
    }
    
    set origTab [win::getInfo $name tabsize]
    set origLineNums [win::getInfo $name linenumbers]
    
    if {[info exists memory($stripped)]} {
	set m [lindex $memory($stripped) 3]
	set t [lindex $memory($stripped) 4]
	set g [lindex $memory($stripped) 5]
	set c [lindex $memory($stripped) 6]
	set f [lindex $memory($stripped) 7]
	set l [lindex $memory($stripped) 8]
	
	if {$rememberWindowsmodeVars(rememberMode) \
	  && ($m != "") && ($m != $curMode)} {
	    winChangeMode $name $m
	    # This may have changed now
	    set origTab [win::getInfo $name tabsize]
	}
	
	if {$rememberWindowsmodeVars(rememberColorsAndHypers) \
	  && [llength $c]} {
	    foreach item $c {
		foreach {index color hyper} $item {
		    insertColorEscape -w $name $index $color $hyper
		}
	    }
	}
	
	if {$rememberWindowsmodeVars(rememberFoldedSections) \
	  && [llength $f]} {
	    eval [list fold -w $name hide] $f
	}

	if {$rememberWindowsmodeVars(rememberUseOfMarginLineNumbers) \
	  && ($l != "") && ($l != $origLineNums)} {
	    setWinInfo -w $name linenumbers $l
	}

	if {$rememberWindowsmodeVars(rememberWindowPosition) \
	  && ([llength $g] == 4)} {
	    eval [list moveWin $name] [lrange $g 0 1]
	    eval [list sizeWin $name] [lrange $g 2 3]
	}
	
	if {$rememberWindowsmodeVars(rememberTabSize) \
	  && ($t != "") && ($t != $origTab)} {
	    setWinInfo -w $name tabsize $t
	}
	
	goto -w $name [lindex $memory($stripped) 0]
	eval [list selectText -w $name] [lrange $memory($stripped) 0 1]
	set currline [lindex $memory($stripped) 2]
	if {$currline != ""} {
	    display -w $name [pos::fromRowCol -w $name $currline 0]
	}
	
    }
    
    set origTabSize($name) $origTab
}

proc rememberWindows::NameChanged {newName oldName} {
    variable memory
    variable origMode
    set old [win::StripCount $oldName]
    unset -nocomplain memory($newName)
    if {[info exists memory($old)]} {
	set path [win::StripCount $newName]
	set memory($path) $memory($old)
	# If this name change was accompanied by a resulting mode
	# change (because a file extension was changed), then we
	# must update the remembered 'original mode' to be the
	# new one.  This line isn't quite correct, because it
	# will do the wrong thing in the case where the window first 
	# has its mode manually changed and then it is renamed.
	set mode [win::getMode $newName]
	lset memory($path) 3 $mode
	set origMode($newName) $mode
    }
}

