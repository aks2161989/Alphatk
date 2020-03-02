#
# $Id: paned.tcl,v 1.2 2006/01/16 15:29:47 jenglish Exp $
#
# Tile widget set: bindings for TPaned widget.
#

namespace eval ttk::paned {
    variable State

    array set State {
	pressed 	0
    	pressX		-
	pressY		-
	sash 		-
	sashPos 	-
    }

    if {![llength [info commands lassign]]} {
	proc lassign {vals args} {uplevel 1 [list foreach $args $vals break] }
    }
}

## Bindings:
#
bind TPaned <ButtonPress-1> 	{ ttk::paned::Press %W %x %y }
bind TPaned <B1-Motion> 	{ ttk::paned::Drag %W %x %y }
bind TPaned <ButtonRelease-1> 	{ ttk::paned::Release %W %x %y }

bind TPaned <Motion> 		{ ttk::paned::SetCursor %W %x %y }
bind TPaned <Enter> 		{ ttk::paned::SetCursor %W %x %y }
bind TPaned <Leave> 		{ ttk::paned::ResetCursor %W } 
# See PanedEventProc in paned.c:
bind TPaned <<EnteredChild>>	{ ttk::paned::ResetCursor %W }


## Sash movement:
#
proc ttk::paned::Press {w x y} {
    variable State

    lassign [$w identify $x $y] sash element 
    if {![info exists sash]} { 
    	set State(pressed) 0
	return 
    }
    set State(pressed) 	1
    set State(pressX) 	$x
    set State(pressY) 	$y
    set State(sash) 	$sash
    set State(sashPos)	[$w sashpos $sash]
}

proc ttk::paned::Drag {w x y} {
    variable State
    if {!$State(pressed)} { return }
    switch -- [$w cget -orient] {
    	horizontal 	{ set delta [expr {$x - $State(pressX)}] }
    	vertical 	{ set delta [expr {$y - $State(pressY)}] }
    }
    $w sashpos $State(sash) [expr {$State(sashPos) + $delta}]
}

proc ttk::paned::Release {w x y} {
    variable State
    set State(pressed) 0
    SetCursor $w $x $y
}

## Cursor management:
#
proc ttk::paned::ResetCursor {w} {
    variable State
    if {!$State(pressed)} {
	$w configure -cursor {}
    }
}

proc ttk::paned::SetCursor {w x y} {
    variable ::tile::Cursors

    if {![llength [$w identify $x $y]]} {
    	ResetCursor $w
    } else {
    	# Assume we're over a sash.
	switch -- [$w cget -orient] {
	    horizontal 	{ $w configure -cursor $Cursors(hresize) }
	    vertical 	{ $w configure -cursor $Cursors(vresize) }
	}
    }
}

#*EOF*
