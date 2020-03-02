## -*-Tcl-*- (install)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "tclproUtils.tcl"
 #                                          created: 09/10/1997 {11:22:17 am}
 #                                      last update: 03/21/2006 {02:21:26 PM} 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::feature tclproUtils 0.4.0 Tcl {
} {
    # Location of TclPro checker or ActiveState TclDevKit checker.
    newPref sig procheckSig ""
    menu::insert tclProUtils items end tclProCheck tclProCheckDir…
} {
} maintainer {
    "Vince Darley" vince@santafe.edu <http://www.santafe.edu/~vince/>
} description {
    Interact with Tcl Pro
} help {
    This features creates two new menu items in the "Tcl Menu", named
    
	Tcl Pro Check
	Tcl Pro Check Dir
    
    You can turn on this feature "globally"
    
    Preferences: Features
    
    or just for Tcl mode
    
    Preferences: Mode-Features-Tcl
    
    All results are presented in a new Alpha "browser" window, which includes
    some handy navigation items for jumping to the referenced windows.
} requirements {
    if {$tcl_platform(platform) == "macintosh"} {
	error "tclproUtils requires command-line functionality"
    }
} uninstall {
    this-file
}

proc tclproUtils.tcl {} {}

namespace eval Tcl {}

set Tcl::tclProCheckSuppress "warnVarRef winBeginDot warnUndefProc \
  warnExpr warnRedefine warnPattern undefinedVar warnReadonlyVar"

proc Tcl::tclProCheck {} {
    variable tclProCheckSuppress
    global procheckSig
    app::getSig "TclPro Checker" procheckSig
    catch {
	exec $procheckSig -suppress $tclProCheckSuppress \
	  [win::StripCount [win::Current]]
    } res
    grepsToWindow "* Tcl Pro Check output *" \
      [Tcl::tclProCheckCleanupResults $res]
}

proc Tcl::tclProCheckDir {} {
    variable tclProCheckSuppress
    global procheckSig
    app::getSig "TclPro Checker" procheckSig
    catch {
	exec $procheckSig -suppress $tclProCheckSuppress \
	  [file join [file dirname [win::Current]] *.tcl]\
	  [file join [file dirname [win::Current]] * *.tcl]
    } res
    grepsToWindow "* Tcl Pro Check output *" \
      [Tcl::tclProCheckCleanupResults $res]
}

proc Tcl::tclProCheckCleanupResults {res} {
    regsub -all "scanning\[^\r\n\]+\n" $res "" res
    regsub -all "warning: no files match\[^\r\n\]+\n" $res "" res
    regsub -all "checking\[^\r\n\]+\n" $res "" res
    global procheckSig
    if {[file root [file tail $procheckSig]] eq "procheck"} {
	# Squish the first two lines
	regsub "\n" $res " " res
	regsub "\n" $res " " res
    } else {
	set res "\n$res"
    }
    regsub -all "\n(\[^\r\n\]+):(\[0-9\]+)\
      (\\\(\[^\r\n\]+)(\n\[^\r\n\]+\n\[^\r\n\]+)" $res \
      "\nLine \\2: \\3\\4\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t∞\\1" res
    return $res
}

# Not used.
proc Tcl::tclProGotoMatch {} {
    set text [getSelect]
    if {[string first "checking:" $text] == 0} {
	set file [string trim [string range $text 10 end]]
	browse::OpenWindow $file
    } elseif {[regexp {^(.*):([1-9][0-9]*) (\(.*)$} $text "" file line problem]} {
	browse::OpenWindow $file
	set pos [pos::fromRowCol $line 0]
	selectText $pos [nextLineStart $pos]
	status::msg $problem
    } else {
	status::msg "Didn't understand the line!"
    }
}

# ===========================================================================
# 
# .