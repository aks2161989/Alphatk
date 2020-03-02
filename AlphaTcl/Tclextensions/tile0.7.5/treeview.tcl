#
# $Id: treeview.tcl,v 1.16 2006/01/30 18:25:02 jenglish Exp $
#
# Tile widget set -- bindings for Treeview widget.
#

namespace eval ttk::treeview {
    variable State

    # Enter/Leave/Motion
    #
    set State(activeWidget) 	{}
    set State(activeHeading) 	{}

    # Press/drag/release:
    #
    set State(pressMode) 	none
    set State(pressX)		0

    # For pressMode == "resize"
    set State(minWidth)		24
    set State(resizeColumn)	#0
    set State(resizeWidth)	0

    # For pressmode == "heading"
    set State(heading)  	{}

    # Provide [lassign] if not already present
    # (@@@ TODO: check if this is still needed after horrible-identify purge)
    #
    if {![llength [info commands lassign]]} {
	proc lassign {vals args} {
	    uplevel 1 [list foreach $args $vals break]
	}
    }
}

### Widget bindings.
#

bind Treeview	<Motion> 		{ ttk::treeview::Motion %W %x %y }
bind Treeview	<B1-Leave>		{ #nothing }
bind Treeview	<Leave>			{ ttk::treeview::ActivateHeading {} {}}
bind Treeview	<ButtonPress-1> 	{ ttk::treeview::Press %W %x %y }
bind Treeview	<Double-ButtonPress-1> 	{ ttk::treeview::DoubleClick %W %x %y }
bind Treeview	<ButtonRelease-1> 	{ ttk::treeview::Release %W %x %y }
bind Treeview	<B1-Motion> 		{ ttk::treeview::Drag %W %x %y }
bind Treeview 	<KeyPress-Up>    	{ ttk::treeview::Keynav %W up }
bind Treeview 	<KeyPress-Down>  	{ ttk::treeview::Keynav %W down }
bind Treeview 	<KeyPress-Right> 	{ ttk::treeview::Keynav %W right }
bind Treeview 	<KeyPress-Left>  	{ ttk::treeview::Keynav %W left }
bind Treeview	<KeyPress-Prior>	{ %W yview scroll -1 pages }
bind Treeview	<KeyPress-Next> 	{ %W yview scroll  1 pages }
bind Treeview	<KeyPress-Return>	{ ttk::treeview::ToggleFocus %W }
bind Treeview	<KeyPress-space>	{ ttk::treeview::ToggleFocus %W }

bind Treeview	<Shift-ButtonPress-1> \
		{ ttk::treeview::Select %W %x %y add }
bind Treeview	<Control-ButtonPress-1> \
		{ ttk::treeview::Select %W %x %y toggle }

# Standard mousewheel bindings:
#
bind Treeview <MouseWheel> { %W yview scroll [expr {- (%D / 120) * 4}] units }
if {[string equal "x11" [tk windowingsystem]]} {
    bind Treeview <ButtonPress-4>	{ %W yview scroll -5 units }
    bind Treeview <ButtonPress-5>	{ %W yview scroll 5 units }
}

### Binding procedures.
#

## Keynav -- Keyboard navigation
#
# @@@ TODO: verify/rewrite up and down code.
#
proc ttk::treeview::Keynav {w dir} {
    set focus [$w focus]
    if {$focus eq ""} { return }

    switch -- $dir {
	up {
	    if {[set up [$w prev $focus]] eq ""} {
	        set focus [$w parent $focus]
	    } else {
		while {[$w item $up -open] && [llength [$w children $up]]} {
		    set up [lindex [$w children $up] end]
		}
		set focus $up
	    }
	}
	down {
	    if {[$w item $focus -open] && [llength [$w children $focus]]} {
	        set focus [lindex [$w children $focus] 0]
	    } else {
		set up $focus
		while {$up ne "" && [set down [$w next $up]] eq ""} {
		    set up [$w parent $up]
		}
		set focus $down
	    }
	}
	left {
	    if {[$w item $focus -open] && [llength [$w children $focus]]} {
	    	CloseItem $w $focus
	    } else {
	    	set focus [$w parent $focus]
	    }
	}
	right {
	    OpenItem $w $focus
	}
    }

    if {$focus != {}} {
	BrowseTo $w $focus
    }
}

## Motion -- pointer motion binding.
#	Sets cursor, active element ...
#
proc ttk::treeview::Motion {w x y} {
    variable ::tile::Cursors
    variable State

    set cursor {}
    set activeHeading {}

    lassign [$w identify $x $y] what where detail
    switch -- $what {
	separator { set cursor $Cursors(hresize) }
	heading { set activeHeading $where }
    }

    if {[$w cget -cursor] ne $cursor} {
	$w configure -cursor $cursor
    }
    ActivateHeading $w $activeHeading
}

## ActivateHeading -- track active heading element
#
proc ttk::treeview::ActivateHeading {w heading} {
    variable State

    if {$w != $State(activeWidget) || $heading != $State(activeHeading)} {
	if {$State(activeHeading) != {}} {
	    $State(activeWidget) heading $State(activeHeading) state !active
	}
	if {$heading != {}} {
	    $w heading $heading state active
	}
	set State(activeHeading) $heading
	set State(activeWidget) $w
    }
}

## Select -- adjust selection
#
proc ttk::treeview::Select {w x y op} {
    set row [$w identify row $x $y] 
    if {$row ne "" } {
	$w selection $op [list $row]
    }
}

## DoubleClick -- Double-ButtonPress-1 binding.  
#
proc ttk::treeview::DoubleClick {w x y} {
    if {[set row [$w identify row $x $y]] ne ""} {
	Toggle $w $row
    } else {
	Press $w $x $y ;# perform single-click action
    }
}

## Press -- ButtonPress binding.
#
proc ttk::treeview::Press {w x y} {

    lassign [$w identify $x $y] what where detail

    focus $w
    switch -- $what {
	nothing { }
	heading { heading.press $w $where }
	separator { resize.press $w $x $where }
	cell { BrowseTo $w $where }
	row  { BrowseTo $w $where }
	item { BrowseTo $w $where }
    }
    if {$what eq "item" && [string match *indicator $detail]} {
    	Toggle $w $where
    }
}

## Drag -- B1-Motion binding
#
proc ttk::treeview::Drag {w x y} {
    variable State
    switch $State(pressMode) {
	resize	{ resize.drag $w $x }
	heading	{ heading.drag $w $x $y }
    }
}

proc ttk::treeview::Release {w x y} {
    variable State
    switch $State(pressMode) {
	resize	{ resize.release $w $x }
	heading	{ heading.release $w }
    }
    set State(pressMode) none
    Motion $w $x $y
}

### Interactive column resizing.
#
# @@@ needs work.
#
proc ttk::treeview::resize.press {w x column} {
    variable State

    set State(pressMode) "resize"
    set State(pressX)	$x
    set State(resizeColumn) $column
    set State(resizeWidth) [$w column $column -width]
}

proc ttk::treeview::resize.drag {w x} {
    variable State
    set newWidth [expr {$State(resizeWidth) + $x - $State(pressX)}]
    if {$newWidth < $State(minWidth)} {
	set newWidth $State(minWidth)
    }
    $w column $State(resizeColumn) -width $newWidth
}

proc ttk::treeview::resize.release {w x} {
    # no-op
}

### Heading activation.
#

proc ttk::treeview::heading.press {w column} {
    variable State
    set State(pressMode) "heading"
    set State(heading) $column
    $w heading $column state pressed
}

proc ttk::treeview::heading.drag {w x y} {
    variable State
    lassign [$w identify $x $y] what where detail
    if {$what eq "heading" && $where eq $State(heading)} {
    	$w heading $State(heading) state pressed
    } else {
    	$w heading $State(heading) state !pressed
    }
}

proc ttk::treeview::heading.release {w} {
    variable State
    if {[lsearch -exact [$w heading $State(heading) state] pressed] >= 0} {
	after idle [$w heading $State(heading) -command]
    }
    $w heading $State(heading) state !pressed
}

### Utilities.
#

## OpenItem, CloseItem -- Set the open state of an item, generate event
#

proc ttk::treeview::OpenItem {w item} {
    $w focus $item
    event generate $w <<TreeviewOpen>>
    $w item $item -open true
}

proc ttk::treeview::CloseItem {w item} {
    $w item $item -open false
    $w focus $item
    event generate $w <<TreeviewClose>>
}

## Toggle -- toggle opened/closed state of item
#
proc ttk::treeview::Toggle {w item} {
    if {[$w item $item -open]} {
	CloseItem $w $item
    } else {
	OpenItem $w $item
    }
}

## ToggleFocus -- toggle opened/closed state of focus item
#
proc ttk::treeview::ToggleFocus {w} {
    set item [$w focus]
    if {$item ne ""} {
    	Toggle $w $item
    }
}

## BrowseTo -- navigate to specified item; set focus and selection
#
proc ttk::treeview::BrowseTo {w item} {
    $w see $item
    $w focus $item
    $w selection set $item
}

### Style settings for selected built-in themes:
#
#   Do this here instead of in the theme definitions since the details are
#   likely to change; it's better to keep this all in one place for now.
#
namespace eval ::ttk::treeview {
variable theme
foreach theme [style theme names] {
    style theme settings $theme {
	style map Item -foreground [list selected #FFFFFF]
	style configure Row -background "#EEEEEE"
	style configure Heading -relief raised -font TkHeadingFont
	style configure Item -justify left
	style map Heading -relief {
	    pressed sunken
	}
	style map Row -background {
	    selected	#4a6984
	    focus	#ccccff
	    alternate	#FFFFFF
	}
	style map Cell -foreground {
	    selected	#FFFFFF
	}
    }
} }

#*EOF*
