# This file (unlike most of the rest of Alphatk core)
# is distributed under a BSD style license.

package provide balloonHelp 0.1

## 
 # -------------------------------------------------------------------------
 # 
 # "Balloon Help" --
 # 
 #  Simple way of attaching balloon help to any tk window or class
 #  (anything we can use bind or bindtags on).
 #  
 #  The balloon is coloured appropriately, follows the mouse, appears
 #  and disappears and transitions reasonably, and tries hard to ensure
 #  it isn't placed half off the screen.
 #  
 #  It also handles appropriate transitions when moving from one
 #  help field to another, whether the underlying widgets/bindings are
 #  side by side, nested, or whatever.
 #  
 #  See 'help' comments below for usage.
 # -------------------------------------------------------------------------
 ##
namespace eval balloon {
    variable info
    # The delay until a balloon appears
    variable delay 650
    # The delay until a balloon is removed, once the pointer leaves
    # the area.
    variable delayTillRemoval 100
    # Use balloon help at all
    variable useBalloonHelp 1
    
    # If balloon help is set for windows which contain as children
    # other windows which also have balloon help, Tk doesn't give us
    # the kind of leave-enter events we want.  We keep a stack of
    # current nested balloon help requests to deal with this situation
    # properly.
    set info(stack) ""
    
    ## 
     # ---------------------------------------------------------------------
     # 
     # "help" --
     # 
     # Register some information with a particular tk window or tk class
     # (anything to which 'bind' and 'bindtags' may be applied).
     # 
     # For simplest possible balloon help, 'args' is just a single argument
     # containing the text to show when the user's mouse dwells on the item.
     # 
     # For most items, args will contain 2 arguments, in order:
     # 
     # 1) Text for item when enabled
     # 2) Text for item when disabled
     # 
     # However, for checkboxes, the above two pieces of text are used when
     # the item is 'off/unchecked', and an additional two arguments may
     # be given:
     # 
     # 3) Text for item when enabled and on
     # 4) Text for item when disabled and on.
     # 
     # If either of items 2/4 is empty, the default is to use items 1/3
     # respectively, and if item 3 is item, the default is to use item 1.
     # If the item finally chosen to be shown is empty, no balloon is shown.
     # ----------------------------------------------------------------------
     ##
    proc help {item args} {
	variable info
	
	if {![llength $args]} {
	    if {[info exists info($item,text)]} {
		return $info($item,text)
	    }
	    return
	}
	
	if {[winfo exists $item]} {
	    set hitem "Help-$item"
	    bindtags $item [concat [list $hitem] [bindtags $item]]
	    bind $item <Destroy> "balloon::end $item %W"
	} else {
	    set hitem $item
	}
	# Add bindings for the various events we need.
	# Make sure we don't add them twice in case they
	# are registered again.
	foreach {event script} [list \
	  <Any-Enter> "balloon::_start $item %W" \
	  <Motion> "balloon::_follow %W" \
	  <Any-Leave> "balloon::_hide \"$item\" %W" \
	  <Unmap> "balloon::_hide $item %W" \
	  <Button-1> "balloon::_button $item %W"] {
	    set old [bind $hitem $event]
	    if {[string first $script $old] == -1} {
		bind $hitem $event "${script}; [bind $item $event]"
	    }
	}
      
	set info($item,text) $args
    }

    proc forgetClass {item} {
	variable info
	foreach b {Any-Enter Any-Leave Button-1 Motion Unmap} {
	    regsub {^[^;]+ ; } [bind $item <$b>] {} old
	    bind $item <$b> $old
	}
	unset info($item,text)
    }
    
    proc forget {} {
	variable info
	if {[info exists info]} {
	    unset info
	}
    }
    
    proc end {item w} {
	variable info
	if {$item eq $w} {
	    if {[info exists info($item,text)]} {
		unset info($item,text)
	    }
	    _remove
	    
	    catch {
		bind $item <Any-Enter> ""
		bind $item <Any-Leave> ""
		bind $item <Unmap> ""
		bind $item <Button-1> ""
		bind $item <Destroy> ""
	    }
	} else {
	    _remove
	}
    }

    proc _button {item w} {
	variable info
	if {[info exists info($w,after)]} {
	    after cancel $info($w,after)
	    if {[winfo exists .balloon.l]} {
		_check $item $w
	    }
	}
	# On Aqua the balloons float above menus, so
	# we make sure we remove the balloons if we have
	# anything that looks like a menubutton.  We don't
	# use 'winfo class' because what we really care about
	# are the bindings.
	if {[tk windowingsystem] == "aqua"} {
	    if {[lsearch -exact [bindtags $w] "Menubutton"] != -1} {
		_remove
	    }
	}
    }
    
    proc _start {item w} {
	variable info 
	variable delay
	
	variable useBalloonHelp
	if {!$useBalloonHelp} { return }
	
	set top [lindex $info(stack) end]
	if {($top ne $w)} {
	    lappend info(stack) $w
	}
	
	if {[info exists info(after)]} {
	    # If a previous balloon is still showing, but we have
	    # already left it's window, and entered a new window, we
	    # should show the new balloon immediately.
	    
	    # Cancel destruction of previous balloon
	    after cancel $info(after)
	    unset info(after)
	    # Show new balloon
	    _show $item $w
	} elseif {[llength $info(stack)] > 1} {
	    # Show new balloon immediately
	    _show $item $w
	} else {
	    # No balloon is currently showing, so wait before presenting
	    # the user with their first balloon
	    set info($w,after) [after $delay "balloon::_show $item $w"]
	}
    }

    proc _remove {} {
	# This procedure may be called twice if we 'end' balloons,
	# while an 'after' call is still outstanding.  So we just
	# need to make sure that it doesn't mind a second call.
	::destroy .balloon
	variable info
	if {[info exists info(after)]} {
	    after cancel $info(after)
	    unset info(after)
	}
    }
    
    proc _follow {w} {
	if {[winfo exists .balloon]} {
	    set y [winfo pointery $w]
	    if {[tk windowingsystem] eq "aqua"} {
		if {$y < 33} {
		    _remove
		    return
		}
	    }
	    _checkPosition [expr {[winfo pointerx $w] + 20}] \
	      [expr {$y + 20}]
	}
    }
    
    proc _checkPosition {posx posy} {
	if {[winfo exists .balloon]} {
	    set width [winfo reqwidth .balloon]
	    set height [winfo reqheight .balloon]
	    
	    #puts "$posx $posy $width $height"
	    # If right side is offscreen, move to the left...
	    if {$posx + $width > [winfo screenwidth .balloon]} {
		set posx [expr {$posx - 40 - $width}]
	    }
	    # ... but not too far.
	    if {$posx < 0} { set posx 0 }
	    
	    # If bottom is offscreen, move up...
	    if {$posy + $height > [winfo screenheight .balloon]} {
		set posy [expr {$posy - 40 - $height}]
	    }
	    # ... but not too far.
	    if {$posy < 0} { set posy 0 }
	    wm geometry .balloon "+${posx}+${posy}"
	    update idletasks
	}
    }
    
    proc _show {item w} {
	#puts "show $item $w"
	if {![winfo exists $w]} {
	    _hide $item $w
	    end $item $w
	    return
	}
	
	variable info
	variable delay
	
	set top [lindex $info(stack) end]
	if {($top ne $w)} {
	    # If we're not top of the stack, reschedule
	    set info($w,after) [after $delay "balloon::_show $item $w"]
	    return
	}
	
	# the position of the balloon window
	set posx [expr {[winfo pointerx $w] + 20}]
	set posy [expr {[winfo pointery $w] + 20}]

	# The .balloon often exists from the previous balloon
	::destroy .balloon
	switch -- [tk windowingsystem] {
	    "classic" {
		toplevel .balloon -relief ridge -borderwidth 2 \
		  -class Balloonhelp ; ::tk::unsupported::MacWindowStyle\
		  style .balloon floating none
	    }
	    "aqua" {
		toplevel .balloon -relief flat -borderwidth 2 \
		  -class Balloonhelp ; ::tk::unsupported::MacWindowStyle\
		  style .balloon help none
	    }
	    "win32" {
		toplevel .balloon -relief ridge -borderwidth 1 \
		  -class Balloonhelp 
	    }
	    default {
		toplevel .balloon -relief ridge -borderwidth 2 \
		  -class Balloonhelp 
	    }
	}
	.balloon configure -background [default::color balloonborder]
	
	if {[tk windowingsystem] == "classic"} {
	    ::tk::unsupported::MacWindowStyle style .balloon\
	      floating none
	} elseif {[tk windowingsystem] == "aqua"} {
	    ::tk::unsupported::MacWindowStyle style .balloon\
	      help none
	    # Workaround TkAqua bug.
	    bindtags .balloon [concat AlphaToplevel Alpha [bindtags .balloon]]
	} else {
	    wm overrideredirect .balloon 1
	}
	wm withdraw .balloon 
	#wm geometry .balloon "+${posx}+${posy}"

	set text [_text $item $w]
	if {[string length $text] > 500} {
	    set wraplength 3i
	} else {
	    set wraplength 2i
	}
	
	::tk::label .balloon.l -text $text \
	  -bg [default::color balloonhelp] -foreground black \
	  -bd 0 -font [default::font balloonhelp] \
	  -justify left -wraplength $wraplength -padx 6 -relief solid \
	  -highlightthickness 0
	
	pack .balloon.l

	# make it visible
	if {$text != ""} {
	    update idletasks
	    _checkPosition $posx $posy
	    # Unfortunately the above line can also destroy the balloon!
	    if {[winfo exists .balloon]} {
		wm deiconify .balloon
	    }
	}
	set info($w,after) [after $delay "balloon::_check $item $w"]
    }
    
    proc _text {item w} {
	variable info
	# In principle we allow four different pieces of text to be
	# associated with each item.  In practice we only use 1 or 2.
	# This flexibility is nicely compatible with MacOS balloons.
	
	set offset 0
	if {![catch {$w cget -state} state]} {
	    if {$state == "disabled"} {
		incr offset 1
	    }
	}
	
	switch -- [winfo class $w] {
	    "Checkbutton" {
		# Checkbuttons display a different help text if the
		# box is checked or not.
		set value [uplevel \#0 set [$w cget -variable]]
		if {$value == [$w cget -onvalue]} {
		    incr offset 2
		}
	    }
	}
	
	set text [lindex $info($item,text) $offset]
	if {$text == "" && ($offset & 1)} {
	    incr offset -1
	    set text [lindex $info($item,text) $offset]
	    if {$text == "" && ($offset & 2)} {
		incr offset -2
	    }
	    set text [lindex $info($item,text) $offset]
	}
	return $text
    }
    
    proc _check {item w} {
	variable info
	variable delay
	if {![winfo exists $w]} {
	    catch {_hide $item $w}
	    end $item $w
	} else {
	    if {[winfo exists .balloon.l]} {
		set top [lindex $info(stack) end]
		if {$top eq $w} {
		    set text [_text $item $w]
		    if {$text == ""} {
			wm withdraw .balloon
		    } else {
			.balloon.l configure -text $text
			wm deiconify .balloon
		    }
		}
		set info($w,after) [after $delay "balloon::_check $item $w"]
	    }
	}
    }
    
    proc _hide {item w} {
	#puts "hide $item $w"
	variable info 
	variable delayTillRemoval
	if {[info exists info($w,after)]} {
	    after cancel $info($w,after)
	    unset info($w,after)
	}
	set top [lindex $info(stack) end]
	if {$top eq $w} {
	    set info(stack) [lreplace $info(stack) end end]
	}
	if {![llength $info(stack)]} {
	    set info(after) [after $delayTillRemoval "balloon::_remove"]
	} else {
	    # workaround for bug on macosx
	    while {[llength $info(stack)] \
	      && ![winfo exists [lindex $info(stack) end]]} {
		set info(stack) [lreplace $info(stack) end end]
	    }
	    if {![llength $info(stack)]} {
		set info(after) [after $delayTillRemoval "balloon::_remove"]
	    }
	}
    }
    
}
