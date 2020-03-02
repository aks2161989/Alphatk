## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "compare.tcl"
 #                                          created: 02/23/1993 {06:29:14 PM}
 #                                      last update: 03/21/2006 {02:05:30 PM}
 # Description:
 # 
 # Simplified (and improved) version of David C. Black's 'compare-windows', 
 # allowing one to compare two windows without any external helper.
 # 
 # Modified by Mark Nagata, 2/23/93, corrected, 2/24/93.
 # Sped-up version, 2/25/93.
 #
 # The return position bug in David's routine (when $patt != "") is fixed in
 # this version.
 # 
 # Vince renamed a couple of things and added the 'package' stuff so this
 # works smoothly with the new Alpha Tcl scheme.  The bindings can now be
 # adjusted via a preferences dialog.  Also rewrote a few bits to try to
 # avoid window-toggling.
 # 
 # Copyright (c) 1993-2006  David C. Black, Mark Nagata, Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::extension compareWindows 1.0 {
    namespace eval compare {}
    menu::insert Utils submenu 0 compare
    menu::insert "compare" items end (-) windowsInPlace
    hook::register requireOpenWindowsHook [list compare windowsInPlace] 2
    # Start a forwards search of the frontmost two windows, from the
    # current cursor position, for the first difference between their
    # contents
    newPref binding findDifference "/`ÇXÈ" \
      compareWindows "" compare::windowsInPlace
    # Start a forwards search of the frontmost two windows, from the
    # current cursor position, for the first difference between their
    # contents, ignoring any difference in whitespace
    newPref binding findDifferenceIgnoringSpace "/1ÇXÈ" \
      compareWindows "" compareOpt
    # Find the next text difference
    newPref binding findNextDifference "<U/`ÇXÈ" \
      compareWindows "" compareNext
    # Find the next text difference, ignoring any difference in
    # whitespace
    newPref binding findNextDifferenceIgnoringSpace "<U/1ÇXÈ" \
      compareWindows "" compareOptNext
    package::addPrefsDialog compareWindows
} description {
    This package allows for a quick comparison of two windows
} help {
    This package allows for a quick comparison of two windows, without all
    the complexity of a full-blown 'diff'.  You can activate it using the
    "Config > Global Setup > Features" menu command, and then checking the
    box for "Compare Windows" that appears in the dialog.
    
    Preferences: Features
    
    Turning on this package creates a "Utils > Compare > Windows In Place"
    menu command.  This item will perform a quick comparison of the two
    frontmost windows (i.e. the active window and the one just behind it.)
    
    After finding the first difference in the file, use the keyboard
    shortcuts for
    
	Find Difference
	Find Difference Ignoring Space
	Find Next Difference
	Find Next Difference Ignoring Space

    that are created by this package.  To change the default values of these
    shortcuts, use "Config > Preferences > Package Preferences" and go to
    the dialog pane labelled "Compare Windows".
    
    Preferences: compareWindows
    
    For more information about the "full-blown diff" options that are
    available, see the "Diff Help" file.
}

proc compare.tcl {} {}

####
# On my Extended Keyboard (where the backquote key is to the left of the 
# "1" key), I Bind prefix-(shift)-backquote to 'compare(Next)' and
# prefix-(shift)-1 to 'compareOpt(Next)', as in the above.
# 
# On my Powerbook keyboard (where nothing is to the left of the "1" key),
# I Bind prefix-(shift)-1 to 'compare(Next)' and
# prefix-(shift)-2 to 'compareOpt(Next)', respectively.
####

proc compareOpt {} {
    compare::windowsInPlace -w
}

proc compare::windowsInPlace {args} {
    if {[lindex $args 0] == "-w"} {
	set patt "\[ \t\n\r\]+"
    } else {
	set patt {}
    }
    
    set files [winNames -f]
    if {[llength $files] < 2} {
	alertnote "If you want to Compare texts, you need two windows."
	return
    }
    
    watchCursor
    for {set i 1} {$i < 3} {incr i} {
	set wn($i) [lindex $files [expr {$i -1}]]
	set wp($i) [getPos -w $wn($i)]
	selectText -w $wn($i) $wp($i) $wp($i)
	set wrt($i) [getText -w $wn($i) $wp($i) [maxPos -w $wn($i)]]
	set wt($i) $wrt($i)
	if {$patt != ""} {
	    regsub -all $patt $wt($i) " " wt($i)
	}
    }
    
    # Exactly equal
    if {$wt(1) == $wt(2)} {
	alertnote "The windows match from cursors to ends."
	return
    }
    
    # Only consider smaller of two strings
    set siz [string length $wt(1)]
    if {$siz > [string length $wt(2)]} {
	set siz [string length $wt(2)]
    }
    
    # Equal except for added stuff
    set l [expr {$siz-1}]
    if {[string range $wt(1) 0 $l] eq [string range $wt(2) 0 $l]} {
	set beg $siz
	set offset(1) $beg
	set offset(2) $beg
    } else {
	set beg 0
	
	while {$siz} {
	    set siz [expr {$siz/ 2}]
	    set end [expr {$beg+$siz}]
	    if {[string range $wt(1) $beg $end] \
	      eq [string range $wt(2) $beg $end]} {
		incr beg $siz
		incr beg
	    }
	}
	set offset(1) $beg
	set offset(2) $beg
    }
    for {set i 2} {$i > 0} {incr i -1} {
	set count $offset($i)
	set pos [pos::math -w $wn($i) $wp($i) + $count]
	if {$patt != ""} {
	    set ans [string range $wt($i) 0 [expr {$offset($i)-1}]]
	    set lans [string length $ans]
	    set tt [string range $wrt($i) 0 [expr {$count-1}]]
	    regsub -all $patt $tt " " tt
	    set ltt [string length $tt]
	    while {$ltt < $lans} {
		incr count [expr {$lans-$ltt}]
		set pos [pos::math -w $wn($i) $pos + [expr {$lans-$ltt}]]
		status::msg $pos
		set tt [string range $wrt($i) 0 [expr {$count-1}]]
		regsub -all $patt $tt " " tt
		set ltt [string length $tt]
	    }
	}
	
	set pos [expr {[pos::compare -w $wn($i) $pos > [maxPos -w $wn($i)]] \
	  ? [maxPos -w $wn($i)] : $pos}]
	display -w $wn($i) [pos::math -w $wn($i) $pos - 1]
	selectText -w $wn($i) $pos [pos::math -w $wn($i) $pos + 1]
	refresh -w $wn($i)
    }
    status::msg "difference found"
    return
}

proc compareNext {} {
    endOfLine
    catch {bringToFront [lindex [winNames -f] 1]}
    endOfLine
    compare::windowsInPlace
}

proc compareOptNext {} {
    endOfLine
    catch {bringToFront [lindex [winNames -f] 1]}
    endOfLine
    compare::windowsInPlace -w
}

# ===========================================================================
# 
# .