## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "functionComments.tcl"
 #                                    created: 27/10/1999 {8:15:22 pm} 
 #                                last update: 03/21/2006 {02:16:21 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley.
 # 
 # Distributed under a Tcl style license.  This package is not
 # actively improved any more, so if you wish to make improvements,
 # feel free to take it over.
 # 
 # ###################################################################
 ##

alpha::extension functionComments 0.1.5 {
    if {[package::active electricMenu]} {
	menu::insert elec items end \
	  {Menu -n FunctionComments -p menu::generalProc {
	    "/eusual"	
	    "/e<Isimple" 
	    "/e<OwithAuthor" 
	    "/e<Uupdate" 
	}}
	hook::register requireOpenWindowsHook [list -m $electricMenu FunctionComments] 1
    } else {
	menu::insert winUtils items end \
	  {Menu -n FunctionComments -p menu::generalProc {
	    "/eusual"	
	    "/e<Isimple" 
	    "/e<OwithAuthor" 
	    "/e<Uupdate" 
	}}
	hook::register requireOpenWindowsHook [list winUtils FunctionComments] 1
    }
} maintainer {
    "Vince Darley" vince@santafe.edu <http://www.santafe.edu/~vince/>
} uninstall {this-file} description {
    This package provides capability to insert nice comments for any given
    function definition
} help {
    This package provides capability to insert nice comments for any given
    function definition.  Once this package has been turned on
    
    Preferences: Features
    
    a new "Function Comments" submenu is created.  If your list of global
    menus includes the package: electricMenu , that's where you will find it,
    otherwise it is in "Utils > Win Utils".  This new Function Comments menu
    includes the following items:
    
	Usual
	Simple
	With Author
    
    Selecting these items (or their associated shortcuts) will insert a new
    comment that looks something like this:
    
	## 
	 # ----------------------------------------------------------------------
	 #	 
	 #	"file::functionComment" --
	 #	
	 #  This procedure generates a nice little comment box like this one here.
	 #	
	 #   Results:
	 #  Well it doesn't return anything, but it allows you to enter each item
	 #  simply, moving from one to the next with Tab
	 #	
	 #   Side effects:
	 #  Not much
	 #	
	 # ----------------------------------------------------------------------
	 ##

    The last item in the submenu,
    
	Update
	
    handles updating of a version line like the one below:
    
	# --Version--Author------------------Changes-------------------------------  
	#    1.0     vince@santafe.edu   original
	#    1.1     vince@santafe.edu   quickly updated with shift-F1

    Sources can be found in "functionComments.tcl".
}

proc functionComments.tcl {} {}

namespace eval functioncomments {}

## 
 # ----------------------------------------------------------------------
 #	 
 #	"file::functionComment" --
 #	
 #  This procedure generates a nice little comment box like this one here.
 #	
 #   Results:
 #  Well it doesn't return anything, but it allows you to enter each item
 #  simply, moving from one to the next with Tab
 #	
 #   Side effects:
 #  Not much
 #	
 # ----------------------------------------------------------------------
 ##
proc functioncomments::usual { {simple ""} {author 0} } {
    
    if {![string length [getSelect]]} {
	selectText [lineStart [getPos]] [nextLineStart [getPos]]
    }
    
    # Changed 6/22/2000 by John Seal to include argument descriptions.
    
    # Selection should now include entire proc header, possibly even
    # including the word "proc" and the opening brace of the body.
    # That way you can usually just triple-click the definition line.
    
    # Strip trailing brace and leading "proc" if necessary.
    set defn [string trimright [getSelect] " \t\n\{"]
    if {$defn eq ""} {
	status::msg "No function name found since no characters in selection"
	return
    }
    if {[string match "proc *" $defn]} {
	set defn [string trimleft [string range $defn 5 end]]
    }
    # Extract function name and argument list.
    scan $defn "%s" fn
    set n [string length $fn]
    if {[catch {
	set defn [lindex [string range $defn $n end] 0]
    } err]} {
	status::msg "No function name found: $err"
	return
    }

    beginningOfLine
    set t "-------------------------------------------------------------------------\r"
    append t "\r"
    append t "\"$fn\" --\r"
    append t "\r ¥description¥\r"
    if { $simple != "simple" } {
	# Insert argument description header
	append t "\rArgument     Default In/Out Description"
	append t "\r------------ ------- ------ ---------------------------------------------\r"
	# Insert description of each argument.
	foreach arg $defn {
	    append t [format "%-12s " [lindex $arg 0]]
	    set default [lindex $arg 1]
	    # Default values of "" need special treatment.
	    if {([llength $arg] > 1) && ($default == "")} {set default "\"\""}
	    # Arguments are usually "In" only so assume that.
	    append t [format "%-7s In     ¥description¥\r" $default]
	}
	append t "\rResults:\r ¥results¥\r\rSide effects:\r ¥side effects¥\r"
    }
    if {$author} {
	append t "\r--Version--Author------------------Changes-------------------------------"
	append t "\r   1.0     [userInfo::getInfo email] original\r"
    }
    append t "-------------------------------------------------------------------------"
    set t [comment::TextBlock $t]
    elec::CenterInsertion $t
}

proc functioncomments::simple {} { return [functioncomments::usual simple 0]}
proc functioncomments::withAuthor {} { return [functioncomments::usual "" 1] }


## 
 # -------------------------------------------------------------------------
 #	 
 #	"file::functionCommentUpdate" --
 #	
 #  Handles updating of a version line like the one below
 #	
 # --Version--Author------------------Changes-------------------------------  
 #    1.0     <vince@santafe.edu> original
 #    1.1     <vince@santafe.edu> quickly updated with shift-F1
 # -------------------------------------------------------------------------
 ##
proc functioncomments::update {} {
    
    set begin [lindex [comment::Characters Paragraph] 2]
    goto [lindex [file::findClosestMatch "${begin}--Version--Author"] 0]
    goto [nextLineStart [nextLineStart [getPos] ]]
    goto [lindex [file::findClosestMatch "${begin}-------"] 0]
    elec::Insertion "${begin}   ¥Version¥     [userInfo::getInfo email] ¥Changes¥\r"
}

# ===========================================================================
# 
# .