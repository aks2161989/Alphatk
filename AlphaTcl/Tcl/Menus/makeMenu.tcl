## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "makeMenu.tcl"
 #                                          created: 05/25/1998 {16:51:08 PM}
 #                                      last update: 04/28/2004 {07:01:24 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Redistributable under standard 'Tcl' license.
 #
 # ==========================================================================
 ##

alpha::menu makeMenu 0.2 "C C++ Java Pasc" Make {
} {
    makeMenu
} {
} uninstall {
    this-file
} maintainer {
    "No-one" 
} preinit { 
    fileset::attachNewInformation "" file "Makefile location" "" \
      "Use this file as the makefile for any 'make' operations\
      on files in this fileset."
} description {
    Supports attempts to 'make' the current window (provided a makefile can
    be found), including utilities to compile, check syntax, and more
} help {
    This package provides a 'Make Menu' that can be activated for any mode,
    but is probably only useful for "C C++ Java Pasc" modes.
    
    The menu items will try to 'make' the current window provided a makefile
    can be found.  It creates a new fileset option for 'Makefile location'
    which can be attached to any current fileset.
    
    This is really just a template for anyone who might want to implement
    some of this.  See the source file "makeMenu.tcl" for more information.
}

proc makeMenu.tcl {} {}

alpha::package require searchPaths 1.0

switch -- $tcl_platform(platform) {
    "unix" {
	newPref sig makeSig make
    }
    "windows" {
	newPref sig makeSig nmake
    }
    "macintosh" {
	newPref sig makeSig make
    }
}

namespace eval make {}

proc makeMenu {} {}

Menu -n Make -p make::menuProc {
    "addFile"
    "/K<Ucompile"
    "compileFiles"
    "checkSyntax"
    "precompileÉ"
    {Menu -m -n headers {}}
    "(-"
    "openHeader"
    "(-"
    "/U<Uupdate"
    "/M<Umake"
    "(-"
    "/N<UnextError"
    "/R<Urun"
}

mode::rebuildSearchPathMenu 

proc make::nextError {} {
    nextMatch "*Compiler Errors*"
}

proc make::menuProc {menu item} {
    make::$item
}

proc make::findMakefile {filename} {
    if {[file exists [set m [file join [file dirname $filename] Makefile]]]} {
	return $m
    } elseif {[file exists [set m [file join [file dirname $filename] makefile.vc]]]} {
	return $m
    } else {
	set fset [fileset::findForFile $filename]
	if {[string length $fset]} {
	    set m [fileset::getInformation $fset "Makefile location"]
	    if {[file exists $m]} {
		return $m
	    }
	}
    }
    return ""
}
	
proc make::action {filename option} {
    set m [make::findMakefile $filename]
    if {![string length $m]} {
	status::msg "No makefile found"
	return
    }
    
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"unix" {
	    set flags ""
	}
	"windows" {
	    set flags [list -f [file tail $m]]
	}
	"macintosh" {
	    set flags ""
	}
    }
    
    app::runScript make "Make" $option 0 1 $flags [file dirname $m]
}

proc make::compile {{filename ""}} {
    if {![string length $filename]} { set filename [win::Current] }
    make::action $filename "[file rootname $filename].obj"
}

proc make::make {} {
    make::action [win::TopFileWindow] ""
}
