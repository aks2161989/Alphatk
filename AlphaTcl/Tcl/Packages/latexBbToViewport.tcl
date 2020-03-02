## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "latexBbToViewport.tcl"
 #                                          created: 05/26/1999 {14:02:44 PM} 
 #                                      last update: 05/08/2004 {05:13:46 PM} 
 # Description:
 # 
 # Converts \\includegraphics bb= to viewport= 
 # 
 # Author: Vince Darley
 # E-mail: vince@biosgroup.com
 #   mail: Bios Group
 #         317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: http://www.biosgroup.com/
 #  
 # Copyright (c) 1999-2003 Vince Darley
 # 
 # Distributable under Tcl-style (free) license.
 #  
 # ==========================================================================
 ##

alpha::feature latexBbToViewport 0.1.1 {TeX} {
    # Initialization script.
    alpha::package require -loose TeX 5.0
} {
    # Activation script.
    menu::insert   {LaTeX Utilities} items 5 {Convert Bb To Viewport}
} {
    # Deactivation script.
    menu::uninsert {LaTeX Utilities} items 5 {Convert Bb To Viewport}
} maintainer {
    {Vince Darley} <vince@santafe.edu>
} uninstall {
    this-file
} description {
    Converts \\includegraphics bb= to viewport= so your file will work ok
    with both latex and pdflatex
} help {
    This package converts \\includegraphics bb= to viewport= so your file will
    work ok with both latex and pdflatex (provided you have both .eps and .pdf
    versions of all your figures).  It is a feature for TeX mode, and creates
    a new "LaTeX Utilities > Convert Bb To Viewport" menu item.
    
    Preferences: Mode-Features-TeX
    
    The cursor must be on the line of the 'includegraphics' for this to work.
}

proc latexBbToViewport.tcl {} {}

namespace eval TeX {}

proc TeX::ConvertBbToViewport {} {

    set pos0 [lineStart [getPos]]
    set pos1 [nextLineStart [getPos]]
    set line [getText $pos0 $pos1]

    if {![regexp {\\includegraphics(\[[^]]*\])?\{([\w-]+)\}} $line "" arg name]} {
	status::msg "Sorry, I can't find a valid \\includegraphics statement!"
	return
    }
    if {![regexp {bb=([0-9\. ]+)} $arg all bbox]} {
	status::msg "Sorry, I can't find a valid bounding box statement in: $arg"
	return
    }
    if {[set file [TeX::findGraphicsFile $name]] == ""} {
	status::msg "Sorry, I can't find the file $name"
	return
    }
    if {[set actualBbox [texfs_getEpsBoxFromFile $file]] == ""} {
	status::msg "Sorry, file $file contains no %%BoundingBox."
	return
    }
    scan $actualBbox "%d %d %d %d" b1 b2 b3 b4
    scan $bbox "%d %d %d %d" a1 a2 a3 a4
    set viewPort "viewport=[expr {$a1 - $b1}] [expr {$a2 - $b2}]\
      [expr {$a3-$a1}] [expr {$a4-$a2}]"
    regsub -- [quote::Regfind $all] $line [quote::Regsub $viewPort] newline
    replaceText $pos0 $pos1 $newline
    status::msg "Replaced 'bb=$bbox' with '$viewPort'"
}

proc TeX::findGraphicsFile {text} {

    if {[file extension $text] == ""} {
	foreach ext {.eps .ps .epsf} {
	    if {[set f [TeX::findTeXFile $text$ext]] != ""} {return $f}
	}
    } else {
	return [TeX::findTeXFile $text]
    }
    return ""
}
