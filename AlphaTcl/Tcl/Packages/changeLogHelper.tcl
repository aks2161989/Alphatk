## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl
 # 
 #  FILE: "changeLogHelper.tcl"
 #                                    created: 05/28/2002 {02:51:16 PM} 
 #                                last update: 12/29/2005 {04:19:27 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta, Santa Fe
 #     www: http://www.santafe.edu/~vince/
 #  
 # ###################################################################
 ##

# extension declaration
alpha::extension changeLogHelper 0.1 {
    newPref binding putChangesInLog "<U<O/L" global "" 1
    alpha::addToPreferencePage Packages putChangesInLog
} maintainer {
    {Vince Darley} vince@santafe.edu http://www.santafe.edu/~vince/
} description {
    This package provides a keyboard shortcut which allows you to edit a
    standard ChangeLog window
} help {
    This package provides a keyboard shortcut which allows you to edit a
    standard ChangeLog window.  To activate this package, select the menu item
    "Config > Global Setup > Features" and then check the box that is next to
    "Change Log Helper" that appears in the dialog.
    
    Preferences: Features
    
    The default shortcut 'Shift-Command-L' will insert appropriate comments
    into the changelog nearest to the active window.  Once this package has
    been turned on, you can change the "Put Changes In Log" preference by
    selecting "Config > Preferences > Package Preferences > Miscellaneous".
} uninstall this-file

proc putChangesInLog {} {
    # Should really get name of current proc too
    set log [findChangeLog [file dirname [win::Current]]]
    if {![string length $log]} {
	status::msg "No ChangeLog found"
	return
    }
    set changelogDir [file dirname $log]
    if {![file::pathStartsWith [win::StripCount [win::Current]] \
      [file dirname $log] path]} {
	set path [file tail [win::StripCount [win::Current]]]
    }
    
    file::openQuietly $log
    goto [minPos]
    
    set text "[lindex [mtime [now] relaxed] 0]  [userInfo::getInfo author]  <[userInfo::getInfo email]>"
    append text "\r\r    * ${path}: \r\r"
    insertText $text
    goto [pos::math [getPos] -2]
}

proc findChangeLog {dir} {
    while {1} {
	foreach ext {"" ".txt"} {
	    set f [file join $dir "ChangeLog$ext"]
	    if {[file exists $f]} {
		return $f
	    }
	}
	set newdir [file dirname $dir]
	if {$dir eq $newdir} {
	    return ""
	}
	set dir $newdir
    }
}
