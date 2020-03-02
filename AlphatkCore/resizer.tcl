# From Tcl'ers Wiki -- many thanks
# We begin by creating a namespace that will hold the resize control stuff. 

namespace eval Resizer {
    
    namespace export resizer
    
    # Catch in case we're exiting.
    bind Resizer <1> [namespace code [list begin_resize %W %X %Y]]
    bind Resizer <B1-Motion> [namespace code [list continue_resize %W %X %Y]]
    bind Resizer <ButtonRelease-1> [namespace code [list end_resize %W %X %Y]]
}

# The following proc creates the control: 
# Resizer::resizer
#
#       Decorates a top-level window with a resize control
#
# Parameters:
#       w - Path name of the resize control
#
# Results:
#       Returns the path name of the resize control
#
# Side effects:
#       Creates the resize control and places it within its toplevel.

proc Resizer::resizer { w size } {
    
    if { [string compare windows $::tcl_platform(platform)] } {
	return
    }
    
    canvas $w -width $size -height $size -highlightthickness 0 -borderwidth 0 \
      -cursor size_nw_se
    
    set t [winfo toplevel $w]
    
    $w create text 16 16 -text \u006f \
      -font {Marlett -16} -fill white -anchor se
    $w create text 16 16 -text \u0070 \
      -font {Marlett -16} -fill gray50 -anchor se
    place $w -relx 1 -rely 1 -anchor se
    
    bindtags $w [list all $t Resizer $w]
    
    return $w
    
}

# The following proc handles the mouse click on the resize control.  It
# stores the original size of the window and the initial coords of the
# mouse relative to the root.
proc Resizer::begin_resize { w rootx rooty } {
    variable info
    set t [winfo toplevel $w]
    set relx [expr { $rootx - [winfo rootx $t] }]
    set rely [expr { $rooty - [winfo rooty $t] }]
    set info(startx,$w) $relx
    set info(starty,$w) $rely
    set info(startw,$w) [winfo width $t]
    set info(starth,$w) [winfo height $t]
    return
}

# The following proc handles mouse motion on the resize control by asking
# the wm to adjust the size of the window.
proc Resizer::continue_resize { w rootx rooty } {
    variable info
    set t [winfo toplevel $w]
    set relx [expr { $rootx - [winfo rootx $t] }]
    set rely [expr { $rooty - [winfo rooty $t] }]
    set width [expr { $relx - $info(startx,$w) + $info(startw,$w) }]
    set height [expr { $rely - $info(starty,$w) + $info(starth,$w) }]
    if { $width < 0 } {
	set width 0
    }
    if { $height < 0 } {
	set height 0
    }
    wm geometry $t ${width}x${height}
    return
}

# The following proc cleans up when the user releases the mouse button. 
proc Resizer::end_resize { w rootx rooty } {
    variable info
    continue_resize $w $rootx $rooty
    unset info(startx,$w)
    unset info(starty,$w)
    unset info(startw,$w)
    unset info(starth,$w)
}

