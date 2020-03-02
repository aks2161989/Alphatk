## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_windows.tcl"
 #                                    created: 04/12/98 {22:45:38 PM} 
 #                                
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 1998-2005  Vince Darley
 # 
 # See the file "license.terms" for information on use and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##

namespace eval win {}
namespace eval tw {}

package require enhancedTextWidget

tw::Hook position    [list ::alphatk_position]
tw::Hook activate    [list ::alpha::divertTkCallToWindow ::activateHook]
tw::Hook deactivate  [list ::alpha::divertTkCallToWindow ::deactivateHook]
tw::Hook lock        [list ::alpha::divertTkCallToWindow ::alphatk_lockClick]
tw::Hook save        [list ::alpha::divertTkCallToWindow ::saveAllowingCancel]
tw::Hook textChanged [list ::alpha::divertTkCallToWindow ::changeTextHook]
tw::Hook dirty       [list ::alphatk_dirty]
tw::Hook charInsertDelete \
  [list ::alpha::divertTkCallToWindow ::characterInsertedHook]
tw::Hook hyper       [list ::alphatk_hyper]
tw::Hook created     [list ::alphatk_created]
tw::Hook message     [list ::status::msg]
tw::Hook dragndrop   [list ::alpha::divertTkCallToWindow ::dndWinHook]

# This allows some global things to happen in a slightly simpler
# fashion even when there are no windows around.  I don't think
# it has any adverse side-effects.  It associates the Tk window '.'
# with the Alpha window "" (i.e. no window).
set win::tk() .
# This command is eventually called when you try to execute
# something (e.g. getPos) which requires an open window when
# there isn't an open window.  So, it's convenient to have
# it throw this error.
proc ::tw::. {args} {
    error "Cancelled since no window is open (while executing '$args')"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::divertTkCallToWindow" --
 # 
 #  Used to divert the Tk callbacks from the enhanced text widget to
 #  callbacks into the AlphaTcl library which use window names
 #  (win/file paths with optional <2>) as file identifiers.
 #  
 #  We basically convert from a Tk widget path (.al0.text1) to a window
 #  name, and leave the rest of the arguments intact, passing them to
 #  'cmd'.
 # -------------------------------------------------------------------------
 ##
proc alpha::divertTkCallToWindow {cmd w args} {
    eval $cmd [list $::win::tktitle([$w base_window])] $args
}

proc ::alphatk_lockClick {win isLocked} {
    if {$isLocked} {
	if {[win::IsFile $win filename]} {
	    if {[catch {file::setLockState $filename 0} err]} {
		if {![dialog::yesno "Can't unlock '$filename', do you want to\
		  make this window editable?"]} {
		    status::msg "Can't unlock '$filename': $err"
		    return
		}
	    }
	}
	setWinInfo -w $win read-only 0
	hook::callAll unlockHook "" $win
    } else {
	setWinInfo -w $win read-only 1
	hook::callAll lockHook "" $win
    }
}

proc ::alphatk_hyper {cmd} {
    if {!$::alphatk::hyperText} {return}
    placeBookmark
    if {[catch {uplevel \#0 $cmd} err]} {
	bgerror $err
    }
}

proc ::alphatk_position {w pos} {
    if {$::win::tktitle([$w base_window]) eq [win::Current]} {
	.status.w.position configure -text $pos
    }
    ::alpha::divertTkCallToWindow ::positionHook $w $pos
}

## 
 # -------------------------------------------------------------------------
 # 
 # "positionHook" --
 # 
 #  Called by Alphatk when the insertion position changes in any
 #  window.  We can use this to compare positions with known
 #  changes of guest modes, for example.
 # -------------------------------------------------------------------------
 ##
proc positionHook {w pos} {
}

proc splitter {w} {
    text_cmd toggleSplit 
}

proc toggleLineNumbers {} {
    text_cmd toggleLineNumbers
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::embedInto" --
 # 
 #  To embed Alphatk's functionality within any Tk window, one must
 #  pass the following arguments:
 #  
 #  alpha::embedInto ?-text contents? ?-encoding enc? \
 #    ?--? name type options
 #  
 #  so, optionally:
 #  
 #   -encoding enc
 #   -text contents
 #   --
 #  
 #  and three required arguments:
 #   
 #   name -- name/title Alphatk should use for the window.
 #   type -- any of "toplevel", "container", "windowid", "tabbed"
 #   options -- depends on type:
 #   
 #       "container" - a tk window path
 #           
 #       "windowid" - a window id (if it is the window id of a tk
 #       container in a separate process, it must have been created with
 #       '-container 1')
 #           
 #       "toplevel" - a toplevel description which is a list of five
 #       elements: {title l t w h}
 #           
 #       "tabbed" - a tab description list of 2 or 3 elements: {title
 #       book ?page?}
 #   
 #  Unfortunately embedded windows currently seem to have trouble
 #  with notification of their destruction (i.e. win::kill is never
 #  called).
 # -------------------------------------------------------------------------
 ##
proc alpha::embedInto {args} {
    set opts(-text) ""
    set opts(-encoding) ""
    getOpts [list -text -encoding]
    if {[llength $args] != 3} {
	error "Bad arguments: should be \"alpha::embedInto\
	  ?-text contents? ?-encoding enc? ?--? name type options\""
    }
    foreach {name type options} $args {break}
    # Over-ride if this variable is set -- bit of a hack at present
    global useTabbedWindow
    if {($type eq "toplevel") && [info exists useTabbedWindow] \
      && ($useTabbedWindow ne "")} {
	set type "tabbed"
	set options [list [lindex $options 0] $useTabbedWindow]
    }
    
    switch -- $type {
	"container" {
	    # It's a tk window.  Should be a frame or toplevel
	    set ww $options
	}
	"windowid" {
	    # It's a window id.  This should be either a Tk window
	    # which has '-container 1' set, or just some window in
	    # some other application.
	    set ww [_uniqueToplevel -use $options]
	    alpha::setIcon $ww $name
	    wm protocol $ww WM_DELETE_WINDOW [list killWindow -w $name]
	}
	"toplevel" {
	    if {[llength $options] != 5} {
		return -code error "Should be 'toplevel {title l t w h}'"
	    }
	    foreach {title x y w h} $options {}

	    # Create the toplevel
	    set ww [_uniqueToplevel]
	    wm withdraw $ww

	    # Calculate and set window geometry and title
	    set xy [moveSizeWin $x $y 1]
	    set wh [moveSizeWin $w $h 0]
	    wm geometry $ww [join $wh x]+[join $xy +]
	    wm title $ww $title
	    alpha::setIcon $ww $name
	    wm protocol $ww WM_DELETE_WINDOW [list killWindow -w $name]
	}
	"tabbed" {
	    if {[llength $options] < 2 || [llength $options] > 3} {
		return -code error "Should be 'tabbed {title book ?page?}'"
	    }
	    set title [lindex $options 0]
	    set book [lindex $options 1]
	    set page [lindex $options 2]
	    if {$page == ""} { set page "end" }
	    
	    variable tabbedWindows
	    if {![info exists tabbedWindows($book)]} {
		return -code error "No such notebook $book"
	    }
	    set book $tabbedWindows($book).pages
	    if {$::alpha::theming} {
		# Find a unique page number
		set item [llength [$book tabs]]
		while {[winfo exists $book.f$item]} {
		    incr item
		}
		# Declare that as this page value
		variable tabs
		set tabs($name) $title

		set ww [frame $book.f$item]
		$book add $ww -text $title
		#-image killWin -compound right
	    } else {
		# Find a unique page number
		set item 1
		while {[lsearch -exact [$book pages] $item] != -1} {
		    incr item
		}
		# Declare that as this page value
		variable tabs
		set tabs($name) $item

		$book insert $page $tabs($name) -text $title
		set ww [$book getframe $tabs($name)]
	    }
	}
	default {
	    return -code error "Should be 'container', 'toplevel', 'windowid'\
	      or 'tabbed'"
	}
    }
    coreWindow $name $ww $opts(-text) $opts(-encoding)
    registerWindowWithAlphaTcl $name
}

proc alpha::windowLower {name} {
    set parent [winfo parent $::win::tk($name)]
    if {[winfo toplevel $parent] eq $parent} {
	lower $parent
    } else {
	# Parent isn't a toplevel -- it must be embedded somewhere,
	# and we don't currently know how to lower it
    }
}

proc alpha::windowRaise {name} {
    global win::tk
    
    set w [winfo toplevel $win::tk($name)]
    if {![string length [$w cget -use]]} {
	wm deiconify $w
    }

    set tkwin $win::tk($name)
    $tkwin activateHook
    
    if {![winfo exists $tkwin]} {
	# Window destroyed inside activateHook
	return
    }
    
    foreach {w type} [_findWindowParent [winfo parent $tkwin]] {}
    
    switch -- $type {
	"Toplevel" {
	    raise $w
	}
	"NoteBook" {
	    # Now we just need to raise the page
	    variable tabs
	    $w raise $tabs($name)
	}
	"TNotebook" {
	    # Now we just need to raise the page
	    variable tabs
	    set num [llength [$w tabs]]
	    for {set i 0} {$i < $num} {incr i} {
		if {[$w tab $i -text] eq $tabs($name)} {
		    $w select $i
		    break
		}
	    }
	}
	default {
	    puts stderr "Unknown window type $type"
	}
    }
    text_wcmd $name takeFocus
}

proc alpha::windowChangeTitle {origName name title} {
    global win::tk win::tktitle
    
    set w $win::tk($name)

    foreach {parent type} [_findWindowParent [winfo parent $w]] {}
    switch -- $type {
	"Toplevel" {
	    wm title $parent $title
	    alpha::setIcon $parent $name
	    wm protocol $parent WM_DELETE_WINDOW [list killWindow -w $name]
	}
	"NoteBook" {
	    variable tabs
	    set tabs($name) $tabs($origName)
	    
	    if {$name ne $origName} {
		unset tabs($origName)
	    }
	    
	    $parent itemconfigure $tabs($name) -text $title
	}
	"TNotebook" {
	    variable tabs
	    set tabs($name) $tabs($origName)
	    
	    if {$name ne $origName} {
		unset tabs($origName)
	    }
	    $parent tab $tabs($name) -text $title
	}
    }
    # Store the new title
    set win::tktitle($w) $name
}

proc alpha::_findWindowParent {parent} {
    set okTypes [list "Toplevel" "NoteBook" "TNotebook"]
    while {1} {
	set class [winfo class $parent]
	if {[lsearch -exact $okTypes $class] != -1} {
	    return [list $parent $class]
	}
	set parent [winfo parent $parent]
    }
}

proc alpha::destroyWindow {wn {dirty_behaviour ""} {destroy_in_progress 0}} {
    # First cleanup the actual text widget.  All that remains
    # after this is to clean up any enclosure (if needed)
    # and the win::tktitle array entry.
    global win::tk win::tktitle
    if {![info exists win::tk($wn)]} {
	return
    }
    
    set twidget $win::tk($wn)
    
    if {![winfo exists $twidget]} {
	# Nested killWindow (e.g. through closeHook).  Just ignore
	return
    }
    
    set parent [winfo parent $win::tk($wn)]
    
    if {![catch {getWinInfo -w $wn winfo}]} {
	if {$winfo(dirty)} {
	    if {$dirty_behaviour == ""} {
		set dirty_behaviour [buttonAlert \
		  "That window '[win::Tail $wn]' has unsaved changes.\
		  What shall I do?" "Save first" "Cancel" "Discard Changes"]
	    }
	    switch -- $dirty_behaviour {
		"Discard Changes" {
		    # do nothing
		}
		"Save first" {
		    save
		}
		"Cancel" {
		    error "Cancelled"
		}
	    }
	}
	# Unfortunately, if 'save' above was activated, the window may
	# even have changed name, and 'win::tk($wn)' may no longer exist!
	# So, we get the name again
	set wn $win::tktitle($twidget)
    }

    if {[winfo exists $win::tk($wn)]} {
	# remove any possible bindings which may trigger
	# side-effects (esp. for destroy)
	if {[bindtags $win::tk($wn)] eq $win::tk($wn)} {
	    # Already in process of destroying
	    return
	}
	bindtags $win::tk($wn) $win::tk($wn)
    } else {
        return
    }
    
    if {[catch {preCloseHook $win::tktitle($twidget)} err]} {
	alertnote "Bad error in preClosehook; please report bug:\
	  $err, $::errorInfo"
    }
    if {[win::Current -normal] eq $wn} {
	if {[catch {::deactivateHook $win::tktitle($twidget)} err]} {
	    alertnote "Bad error in deactivateHook; please report bug:\
	      $err, $::errorInfo"
	}
    }
    tw::windowCleanup $win::tk($wn)
    unset win::tk($wn)

    foreach {w type} [_findWindowParent $parent] {}
    
    if {[winfo exists $w]} {
	switch -- $type {
	    "Toplevel" {
		# All sorts of nasty recursive loops can arise if we
		# don't remove these two bindings.  Such loops generally
		# result in wish crashing (obviously not ideal
		# behaviour, and it ought to catch the infinite loop,
		# but anyway, we should write nice code too ;-)
		::bind $w <Destroy> ""
		wm protocol $w WM_DELETE_WINDOW ""
		bindtags $w $w
		if {!$destroy_in_progress} {
		    destroy $w
		}
	    }
	    "TNotebook" {
		variable tabs
		set num [llength [$w tabs]]
		for {set i 0} {$i < $num} {incr i} {
		    if {[$w tab $i -text] eq $tabs($wn)} {
			set fr [lindex [$w tabs] $i]
			$w forget $i
			destroy $fr
			unset tabs($wn)
			break
		    }
		}
	    }
	    "NoteBook" {
		variable tabs
		$w delete $tabs($wn)
		unset tabs($wn)
	    }
	}
    }
    # If the 'close' action resulted in the user deciding to save
    # a dirty window with a different name, then 'wn' will be wrong.
    # Therefore we must use $win::tktitle($twidget) instead.
    if {[catch {closeHook $win::tktitle($twidget)} err]} {
	alertnote "Bad error in closehook; please report bug:\
	  $err, $::errorInfo"
    }
    unset win::tktitle($twidget)
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::coreWindow" --
 # 
 #  To embed Alphatk's functionality within any Tk window, one must
 #  take the following sequence of actions.  
 #  
 #  (i) call 'alpha::coreWindow $name $callback $w $text $encoding'
 #  
 #  (ii) call 'registerWindowWithAlphaTcl $n'
 #  
 #  That is sufficient!  Or you can call 'alpha::embedInto' which
 #  will do all of the above for you.
 #  
 #  Here '$w' is the arbitrary Tk window, '$name' is the name of the
 #  window, and $text, $encoding are the contents and encoding of the
 #  window (optional).
 #  
 # -------------------------------------------------------------------------
 ##
proc alpha::coreWindow {name w {text ""} {encoding ""}} {
    global tcl_platform win::tk win::tktitle
        
    set textwin [tw::PreMakeWindow $w -encoding $encoding]

    set win::tk($name) $textwin
    set win::tktitle($textwin) $name
    ::winCreatedHook $name
    
    set textwin [tw::CompleteWindow $w $textwin $text]

    # Note: 'width 1' is too narrow, but 'width 2' is a little larger
    # than is necessary.  Hence we use width 1 here, but then use
    # grid -sticky ew to let them expand to the available space.  This
    # allows the right margin to size itself to the width of the scrollbar,
    # which can vary depending on the current appearance/colour-scheme.
    smallMenuButton [tw::Toolbar $w path vcs] -text "V" -padx 0 -pady 0 \
      -width 1 -relief ridge -activebackground [color activebackground] \
      -activeforeground [color activeforeground]
    smallMenuButton [tw::Toolbar $w path marks] -text "M" -padx 0 -pady 0 \
      -width 1 -relief ridge -activebackground [color activebackground] \
      -activeforeground [color activeforeground]
    smallMenuButton [tw::Toolbar $w path func] -text "\{ \}" -padx 0 -pady 0 \
      -width 1 -relief ridge -activebackground [color activebackground] \
      -activeforeground [color activeforeground]
    smallMenuButton [tw::Toolbar $w path files] -text "f" -padx 0 -pady 0 \
      -width 1 -relief ridge -activebackground [color activebackground] \
      -activeforeground [color activeforeground]
    bindtags [tw::Toolbar $w path vcs] \
      [concat Vcspopup [bindtags [tw::Toolbar $w path vcs]]]
    bindtags [tw::Toolbar $w path marks] \
      [concat Markspopup [bindtags [tw::Toolbar $w path marks]]]
    bindtags [tw::Toolbar $w path func] \
      [concat Funcspopup [bindtags [tw::Toolbar $w path func]]]
    bindtags [tw::Toolbar $w path files] \
      [concat Filespopup [bindtags [tw::Toolbar $w path files]]]

    if {[tk windowingsystem] == "classic" \
      || [tk windowingsystem] == "aqua" } {
	# Makes things look a little better on MacOS, which has a
	# rather larger default font.
	catch {
	    [tw::Toolbar $w path func] configure -text "\{\}"
	    [tw::Toolbar $w path vcs] configure -font "Monaco 9"
	    [tw::Toolbar $w path marks] configure -font "Monaco 9"
	    [tw::Toolbar $w path func] configure -font "Times 9" -pady 2
	    [tw::Toolbar $w path files] configure -font "Monaco 9"
	}
    }
    
    tw::Toolbar $w add vcs
    tw::Toolbar $w add func
    tw::Toolbar $w add marks
    tw::Toolbar $w add files
    
    if {[winfo toplevel $w] == $w} {
	global useGlobalMenuBarOnly
	if {![info exists useGlobalMenuBarOnly] || !$useGlobalMenuBarOnly} {
	    if {[tk windowingsystem] != "classic" \
	      && [tk windowingsystem] != "aqua" } {
		$w configure -menu .menubar
	    }
	}
    }
    
    update idletasks
    focus $textwin
    return $w
}

bind Toplevel <Destroy> [list win::kill %w]

proc win::kill {w} {
    variable tktitle
    set tw ${w}.text1
    if {[info exists tktitle($tw)]} {
	::alpha::destroyWindow $tktitle($tw) "" 1
    }
}

proc ::alphatk_dirty {w d} {
    if {[tk windowingsystem] == "aqua"} {
	wm attributes [winfo toplevel $w] -modified $d
    }
    ::alpha::divertTkCallToWindow ::dirtyHook $w $d
}

proc ::alphatk_created {w} {
    #puts "created $w"
    ::dialog::haveNewWindow
    bindtags $w [concat Alpha [bindtags $w]]
    if {$::alphatk::blockCursor} { 
	$w configure -blockcursor 1
    }
    $w tag configure blink -background black -foreground white
    
    global colorInds
    set foreground [rgbToColor $colorInds(foreground)]
    $w configure -background [rgbToColor $colorInds(background)]
    $w configure -foreground $foreground
    $w tag configure color1 -foreground [rgbToColor $colorInds(blue)]
    $w tag configure color2 -foreground [rgbToColor $colorInds(cyan)]
    $w tag configure color3 -foreground [rgbToColor $colorInds(green)]
    $w tag configure color4 -foreground [rgbToColor $colorInds(magenta)]
    $w tag configure color5 -foreground [rgbToColor $colorInds(red)]
    $w tag configure color6 -foreground [rgbToColor $colorInds(white)]
    $w tag configure color7 -foreground [rgbToColor $colorInds(yellow)]
    if {[info exists colorInds(color_8)]} {
	$w tag configure color8 -foreground [rgbToColor $colorInds(color_8)]
    } else {
	$w tag configure color8 -foreground $foreground
    }
    if {[info exists colorInds(color_9)]} {
	$w tag configure color9 -foreground [rgbToColor $colorInds(color_9)]
    } else {
	$w tag configure color9 -foreground $foreground
    }
    if {[info exists colorInds(color_10)]} {
	$w tag configure color10 -foreground [rgbToColor $colorInds(color_10)]
    } else {
	$w tag configure color10 -foreground $foreground
    }
    if {[info exists colorInds(color_11)]} {
	$w tag configure color11 -foreground [rgbToColor $colorInds(color_11)]
    } else {
	$w tag configure color11 -foreground $foreground
    }
    if {[info exists colorInds(color_12)]} {
	$w tag configure color12 -foreground [rgbToColor $colorInds(color_12)]
    } else {
	$w tag configure color12 -foreground $foreground
    }
    if {[info exists colorInds(color_13)]} {
	$w tag configure color13 -foreground [rgbToColor $colorInds(color_13)]\
	  -underline 1
    } else {
	$w tag configure color13 -underline 1
    }
    if {[info exists colorInds(color_14)]} {
	$w tag configure color14 -foreground [rgbToColor $colorInds(color_14)]\
	  -underline 1
    } else {
	$w tag configure color14 -underline 1
    }
    if {[info exists colorInds(color_15)]} {
	$w tag configure color15 -foreground [rgbToColor $colorInds(color_15)]\
	  -underline 1
	$w tag configure hyper -foreground [rgbToColor $colorInds(color_15)]
    } else {
	$w tag configure color15 -underline 1
	$w tag configure hyper -underline 1
    }
    
    alpha::synchroniseTagColours $w
}

proc alpha::synchroniseTagColours {w} {
    for {set tag 1} {$tag < 7} {incr tag} {
	$w tag configure user:color$tag -foreground \
	  [$w tag cget color$tag -foreground]
    }
    $w tag configure user:color8 -font "[$w cget -font] bold"
    $w tag configure user:color9 -font [$w cget -font] ;#condense
    $w tag configure user:color10 -font "[$w cget -font] roman"
    $w tag configure user:color11 -font "[$w cget -font] italic"
    $w tag configure user:color12 -font [$w cget -font] ;#normal
    $w tag configure user:color13 -font "[$w cget -font] overstrike"
    $w tag configure user:color14 -font [$w cget -font] ;#shadow
    $w tag configure user:color15 -underline 1
}

# This is the ONLY piece of code that cares the given window
# is called '.alN'.  If any 'args' are given, they are passed
# to the toplevel's creation command (e.g. -use 0x... for embedding)
proc alpha::_uniqueToplevel {args} {
    set nn 0
    while {[winfo exists .al$nn]} {incr nn}
    eval [list ::alpha::makeToplevel [set w .al$nn]] $args
    return $w
}

# This second version is a workaround for a bug in Tk 8.5a0's text
# widget: when a widget path is re-used too quickly, Tk crashes.
set alpha::nn 0
proc alpha::_uniqueToplevel {args} {
    variable nn
    while {[winfo exists .al$nn]} {incr nn}
    eval [list ::alpha::makeToplevel [set w .al$nn]] $args
    if {[incr nn] > 10000} { set nn 0 }
    return $w
}

proc alpha::tabbedWindowNames {} {
    variable tabbedWindows
    array names tabbedWindows
}

proc useTabbedWindow {{n ""}} {
    global useTabbedWindow
    if {$n == ""} {
	set existing [alpha::tabbedWindowNames]
	if {![llength $existing]} {
	    set n [prompt "Make new tabbed window" ""]
	} else {
	    set n [eval [list prompt "Make new tabbed window" "" "Or use"] \
	      $existing]
	}
    }
    if {[lsearch -exact [alpha::tabbedWindowNames] $n] == -1} {
	alpha::makeTabbedWindow $n
    }
    set useTabbedWindow $n
}

set alpha::tt 0
proc alpha::makeTabbedWindow {args} {
    if {![llength $args]} {
	set title [getline "Tabbed window title"]
	if {$title == ""} { return }
    } else {
	set title [lindex $args 0]
	set args [lrange $args 1 end]
    }
    variable tt
    variable tabbedWindows
    while {[winfo exists .altab$tt]} {incr tt}
    eval [list ::alpha::makeToplevel [set tabw .altab$tt]] $args
    global defWidth defHeight defTop defLeft
    
    set x [distanceToScreen ${defLeft}]
    set y [expr {[distanceToScreen ${defTop}] - [default::size titlebarheight]}]
    wm geometry $tabw \
      [distanceToScreen ${defWidth}]x[distanceToScreen ${defHeight}]+$x+$y
    wm title $tabw $title
    #bindtags $tabw [concat Alpha [bindtags $tabw]]
    wm protocol $tabw WM_DELETE_WINDOW [list alpha::destroyTabbedWindow $title]
    set tabbedWindows($title) $tabw
    if {[incr tt] > 10000} { set tt 0 }
    if {$::alpha::theming} {
	ttk::notebook $tabw.pages -width 500 -height 500
	bind $tabw.pages <FocusIn> {
	    tw::takeFocus "[lindex [%W tabs] [%W index current]].text1"
	}
    } else {
	::package require BWidget
	NoteBook $tabw.pages -side top -width 500 -height 500 -ibd 0
	if {$::alpha::macos == 2} {
	    $tabw.pages configure -bd 2 -background gray80
	}
    }
    bindtags $tabw.pages [concat Alpha [bindtags $tabw.pages]]
    pack $tabw.pages -fill both -expand 1
    focus $tabw
    return $tabw
}

proc alpha::sequenceSubWindows {subs} {
    # Need to sequence multiple subwindows
    set parent [lindex $subs 0]
    while 1 {
	set bad 0
	set parent [winfo parent $parent]
	foreach ww $subs {
	    if {![string match $parent.* $ww]} {
		set bad 1
		break
	    }
	}
	if {!$bad} {
	    break
	}
	if {$parent eq "."} { error "bug in winNames" }
    }
    # Found the unique common parent
    if {$::alpha::theming} {
	# Find the frontmost tab.
	set cur [$parent index current]
	set widg "[lindex [$parent tabs] $cur].text1"
	set idx [lsearch -exact $subs $widg]
	# Return in correct order.
	return [concat [list $widg] [lreplace $subs $idx $idx]]
    } else {
	# Bug!!  Need to handle Bwidgets.
	return $subs
    }

}

proc alpha::destroyTabbedWindow {title} {
    variable tabbedWindows 
    global win::tktitle
    set book $tabbedWindows($title).pages
    global useTabbedWindow
    if {[info exists useTabbedWindow] && ($title eq $useTabbedWindow)} {
	# In case we try to open a new window during the window
	# closing (usually an error window) we don't want it inside
	# the tabbed window.
	set old_useTabbedWindow $useTabbedWindow
	unset useTabbedWindow
    }
    if {[catch {
	if {$::alpha::theming} {
	    set contents [$book tabs]
	    foreach frame $contents {
		foreach ww [array names win::tktitle] {
		    if {[winfo parent $ww] == $frame} {
			set name $win::tktitle($ww)
			# This can throw an error to cancel closing
			killWindow -w $name
		    }
		}
	    }
	} else {
	    set contents [$book pages]
	    foreach page $contents {
		set frame [$book getframe $page]
		foreach ww [array names win::tktitle] {
		    if {[winfo parent $ww] == $frame} {
			set name $win::tktitle($ww)
			# This can throw an error to cancel closing
			killWindow -w $name
		    }
		}
	    }
	}
    } err]} {
	if {[info exists old_useTabbedWindow]} {
	    set useTabbedWindow $old_useTabbedWindow
	}
	return -code error $err
    }
    # If we reached here, then we want to destroy the window
    destroy $tabbedWindows($title)
    unset tabbedWindows($title)
}

proc highlight {args} {
    ::win::parseArgs w pattern
    text_wcmd $w highlight $pattern
}

proc flash {char} {
    if {[text::isEscaped]} {
	# it's a literal character
	return
    }
    set pos [pos::math [getPos] - 1]
    if {[catch {matchIt $char $pos} matched]} {
	beep
	status::msg $matched
	return
    } else {
	blink $matched
    }
}

proc win::diskModified {name {mod 1} {diff 0}} {
    variable tk
    set w $tk($name)
    if {$mod} {
	$w statusConfigure background [default::color activebackground]
    } else {
	$w statusConfigure background [default::color background]
    }
}

# Go up/down a line preserving x-position.
proc text_updownline {ww from n} {
    set w $::win::tk($ww)
    
    variable ::tk::Priv

    # Use text_wcmd to throw an error if there are no windows.
    set i [text_wcmd $ww index $from]
    scan $i "%d.%d" line char
    if {$Priv(prevPos) ne $i} {
        set Priv(char) $char
    }
    set new [$w index [expr {$line + $n}].$Priv(char)]
    if {[$w compare $new == end] || [$w compare $new == "$from linestart"]} {
        set new $i
    }
    set Priv(prevPos) $new
    return $new
}

proc text_cmd {cmd args} {
    global tw::split win::tktitle
    set w [focus]
    if {![info exists win::tktitle($w)] && ![info exists tw::split($w)]} {
	global win::tk
	set w $win::tk([win::Current])
    }
    uplevel 1 [list tw::$cmd $w] $args
}

proc text_cmds {args} {
    global tw::split win::tktitle
    set w [focus]
    if {![info exists win::tktitle($w)] && ![info exists tw::split($w)]} {
	global win::tk
	set w $win::tk([win::Current])
    }
    foreach cmd $args {
	set rest [lrange $cmd 1 end]
	set cmd [lindex $cmd 0]
	uplevel 1 [list tw::$cmd $w] $rest
    }
}

proc text_wcmd {ww cmd args} {
    global win::tk
    # Try full window name
    if {[info exists win::tk($ww)]} {
	set w $win::tk($ww)
	uplevel 1 [list tw::$cmd $w] $args
    } else {
	# See if we can find a window whose tail is ok
	regsub -all {[][\\*?]} $ww {\\&} quoted_ww
	foreach full [array names win::tk "*$quoted_ww"] {
	    if {[file tail $full] eq $ww} {
		set w $win::tk($full)
		return [uplevel 1 [list tw::$cmd $w] $args]
	    }
	}
	return -code error "No such window \"$ww\""
    }
}

proc text_wcmds {ww args} {
    global win::tk
    if {[info exists win::tk($ww)]} {
	set w $win::tk($ww)
	foreach cmd $args {
	    set rest [lrange $cmd 1 end]
	    set cmd [lindex $cmd 0]
	    uplevel 1 [list tw::$cmd $w] $rest
	}
    } else {
	# See if we can find a window whose tail is ok
	regsub -all {[][\\*?]} $ww {\\&} quoted_ww
	foreach full [array names win::tk "*$quoted_ww"] {
	    if {[file tail $full] eq $ww} {
		set w $win::tk($full)
		foreach cmd $args {
		    set rest [lrange $cmd 1 end]
		    set cmd [lindex $cmd 0]
		    uplevel 1 [list tw::$cmd $w] $rest
		}
		return
	    }
	}
	return -code error "No such window \"$ww\""
    }
}

# We have to do some funny stuff here, to turn the commands
# in the menu which was created into the format that is needed
# by AlphaTcl.
proc win::titleBarPopup {w x y} {
    set name [::titlebarPathHook]
    set widget [lindex [menu_tags $name] 1]
    
    for {set entry [$widget index end]} {$entry >= 0} {incr entry -1} {
	if {![catch {$widget entrycget $entry -command} got]} {
	    if {[lindex $got 0] eq "::alpha::executeAndRecord"} {
		set got [lindex $got 1]
		lappend path [lindex $got 2]
		set got [lreplace $got 2 2 $path]
		set got [list "::alpha::executeAndRecord" $got]
	    } else {
		lappend path [lindex $got 2]
		set got [lreplace $got 2 2 $path]
	    }
	    $widget entryconfigure $entry -command $got
	}
    }
    tk_popup $widget $x $y 0
}

proc win::contextualMenuPopup {w X Y x y} {
    # This line is required to make sure contextual actions use
    # the click-pos/etc for the correct window pane (when split).
    focus $w ; $w activateHook
    alphatk::menuForPopup "" \
      [list ::contextualMenuHook [$w index @$X,$Y]] .contextual
    if {[winfo exists .contextual]} {
	tk_popup .contextual $x $y
    }
}

switch -- [tk windowingsystem] {
    "macintosh" - "aqua" - "classic" {
	bind AlphaStyle <Mod1-Double-Button-1> {cmdDoubleClick}
	bind AlphaStyle <Mod1-Control-Double-Button-1> \
	  {cmdDoubleClick -1 -1 0 0 1}
	bind AlphaStyle <Mod1-Shift-Double-Button-1> \
	  {cmdDoubleClick -1 -1 1 0 0}
	bind AlphaStyle <Mod1-Control-Shift-Double-Button-1> \
	  {cmdDoubleClick -1 -1 1 0 1}
	bind AlphaStyle <Mod1-Button-3> {win::titleBarPopup %W %X %Y}
	bind AlphaStyle <Control-Button-1> \
	  {win::contextualMenuPopup %W %x %y %X %Y}
    }
    default {
	bind AlphaStyle <Alt-Double-Button-1> {cmdDoubleClick}
	bind AlphaStyle <Alt-Control-Double-Button-1> \
	  {cmdDoubleClick -1 -1 0 0 1}
	bind AlphaStyle <Alt-Shift-Double-Button-1> \
	  {cmdDoubleClick -1 -1 1 0 0}
	bind AlphaStyle <Alt-Control-Shift-Double-Button-1> \
	  {cmdDoubleClick -1 -1 1 0 1}
	bind AlphaStyle <Alt-Button-3> {win::titleBarPopup %W %X %Y}
	bind AlphaStyle <Button-3> {win::contextualMenuPopup %W %x %y %X %Y}
	bind AlphaStyle <Shift-Button-3> {tk::TextScanMark %W %x %y}
	bind AlphaStyle <Shift-B3-Motion> {tk::TextScanDrag %W %x %y}
    }
}

bind Markspopup <Button-1> \
  "alphatk::menuForPopup %W ::marksMenuHook \"%W.menu\""
bind Funcspopup <Button-1> \
  "alphatk::menuForPopup %W ::parseMenuHook \"%W.menu\""
# This callback we allow to fail, but in that case we don't allow the event
# to continue through to the menubutton.
bind Vcspopup <Button-1> \
  "alphatk::menuForPopup %W ::vcsMenuHook \"%W.menu\" 1"
bind Filespopup <Button-1> \
  "alphatk::menuForPopup %W ::relatedFilesMenuHook \"%W.menu\""

if {($::tcl_platform(platform) == "windows")} {
    bind Alpha <Control-z> {undo ; break}
    bind Alpha <Control-Shift-z> {redo ; break}
    bind Alpha <Control-x> {cut ; break}
    bind Alpha <Control-c> {copy ; break}
    bind Alpha <Control-v> {paste ; break}
}
bind Alpha <<Paste>> {paste ; break}
bind Alpha <<Cut>> {cut ; break}
bind Alpha <<Copy>> {copy ; break}
bind Alpha <<Clear>> {clear ; break}
balloon::help Splitter "Click here to split/unsplit the window"
balloon::help Vcspopup "Click here to access version control functions"
balloon::help Markspopup "Click here to access file marks"
balloon::help Funcspopup "Click here to access functions in this window"
balloon::help Filespopup "Click here to access related files"
balloon::help Lock "Shows modified/dirty status of the window.\
  A red dot indicates unsaved changes (and you can click here to save),\
  a dark background indicates that the file has changed on disk,\
  and a lock indicates the window is not editable."

# ×××× Public window commands ×××× #

#¥ killWindow - kill current window 
#  'killWindow ?-w win? dirty_behaviour'
proc killWindow {args} {
    win::parseArgs wn {dirty_behaviour ""}

    if {$dirty_behaviour ne "" && \
      [lsearch -exact {"Discard Changes" "Save first" "Cancel"} \
      $dirty_behaviour] == -1} {
	return -code error "Bad argument \"$dirty_behaviour\" should be\
	  \"killWindow ?-w win? ?{Discard Changes} {Save first} {Cancel}?\""
    }

    if {$wn eq ""} {
	return -code error "Cancel: no open windows"
    }
    
    alpha::destroyWindow $wn $dirty_behaviour
    
    alpha::focusOnFrontmost
    # Return the empty string.
    return
}

proc win::List {type maxCount} {
    variable tk
    variable tktitle
    
    set winlist [list]
    if {$maxCount == 0} {
	return $winlist
    }
    
    # Get dictionary of current windows
    set wins [array get tktitle]
    # This is in the order from back to front -- we want from
    # front to back.
    set order [wm stackorder .]
    set i [expr {[llength $order] - 1}]
    while {$i >= 0} {
	set w [lindex $order $i]
	# Get all subwins.
	set subs [list]
	foreach s [array names tktitle $w.*] {
	    if {[winfo exists $s]} {
		lappend subs $s
	    }
	}
	if {[llength $subs] > 1} {
	    set subs [alpha::sequenceSubWindows $subs]
	}
	foreach ww $subs {
	    # Some of these might be inside tabbed windows
	    set f [dict get $wins $ww]
	    dict unset wins $ww
	    if {[info exists tk($f)]} {
		lappend winlist $f
		if {($maxCount > 0) && ([llength $winlist] >= $maxCount)} {
		    return $winlist
		}
	    }
	}
	incr i -1
    }
    if {$type eq "-normal"} {
	return $winlist
    }
    # Add any not in the stackorder.  We don't care
    # about the order of these.
    foreach f [dict values $wins] {
	if {[info exists tk($f)]} {
	    lappend winlist $f
	    if {($maxCount > 0) && ([llength $winlist] >= $maxCount)} {
		return $winlist
	    }
	}
    }
    
    return $winlist
}

proc win::Current {{type ""}} {
    return [lindex [List $type 1] 0]
}

#¥ winNames [-f] - return a TCL list of all open windows. If '-f' option 
#  specified, complete pathnames are returned.
proc winNames {{full ""}} {
    # First construct the list of current windows, we use 
    # [wm stackorder] so that we have the right sequence,
    # but must double-check each entry with win::tk() to 
    # ensure it still exists (it may be in the process of
    # being deleted, and [winNames] might be called from
    # inside a closeHook).  Finally we add any windows not
    # listed in the stackorder (e.g. iconified windows).
    global win::tk win::tktitle
    
    set winlist [win::List -all -1]
    
    if {$full == "-f"} { return $winlist }
    if {$full == "-fnocount"} { 
	set res {}
	foreach f $winlist {
	    lappend res [win::StripCount $f]
	}
	return $res
    } elseif {$full != ""} {
	return -code error "Bad argument '$full' to winNames"
    }
    set res {}
    foreach f $winlist {
	if {[win::IsFile $f]} {
	    lappend res [file tail $f]
	} else {
	    lappend res $f
	}
    }
    set res
}

#¥ windowVisibility ?-w <win>? ?state? - query or set window visibility
proc windowVisibility {args} {
    win::parseArgs w args
    global win::tk

    if {![info exists win::tk($w)]} {
	set ww [winTailToFullName $w]
	if {![info exists win::tk($ww)]} {
	    error "Unknown window $ww"
	}
	set w $ww
    }
    set tkw $win::tk($w)

    switch -- [llength $args] {
	0 {
	    switch -- [wm state [winfo toplevel $tkw]] {
		"iconic" {
		    return "minimized"
		}
		"withdrawn" {
		    return "minimized"
		}
		"normal" - default {
		    return "normal"
		}
	    }
	}
	1 {
	    set arg [lindex $args 0]
	    if {[lsearch -exact {normal minimized hidden} $arg] == -1} {
		error "Bad argument. Should be normal, minimized or hidden."
	    }
	    switch -- $arg {
		"normal" {
		    bringToFront $w
		}
		"minimized" {
		    wm iconify [winfo toplevel $tkw]
		}
		"hidden" {
		    wm withdraw [winfo toplevel $tkw]
		}
	    }
	}
	default {
	    return -code error "Too many arguments, should be\
	      'windowVisibility ?-w win? ?(hidden|normal|minimized)?'"
	}
    }
}

#¥ sendToBack <winName> - Send named window to back.
proc sendToBack {{n ""}} {
    if {$n == ""} { set n [win::Current] }
    
    alpha::windowLower [winTailToFullName $n]
}

#¥ bringToFront <winName> - Bring named window to front.
proc bringToFront {n {deactivate 1}} {
    global win::tk

    if {$n eq ""} {
	return -code error "Empty window name in bringToFront"
    }

    set n [winTailToFullName $n]
    set old [win::Current]
    set numWins [array size win::tktitle]
    
    if {($numWins > 1) && ($old eq $n)} {
	if {!$deactivate} {
	    # We just deleted the previous window, and have
	    # already adjusted our arrays so this
	    # one is already in front.
	    alpha::windowRaise $n
	} else {
	    set w [winfo toplevel $win::tk($n)]
	    if {![string length [$w cget -use]]} {
		wm deiconify $w
	    }
	    text_wcmd $n takeFocus
	}
	return 
    }
    
    if {$old ne $n && $old != ""} {
	# if this flag wasn't set, we just killed the last window
	if {$deactivate} {
	    deactivateHook $old
	}
    }
    #puts stderr "bringToFront $old -> $n"
    alpha::windowRaise $n
    return $n
}

proc moveSizeWin {x y move} {
    if {$move} {
	# Must check it's not too high.
	if {$y < $::defTop} {
	    set y $::defTop
	}
	# Need to position further up to account for the titlebar.
	set structureY [expr {[distanceToScreen $y] - $::titlebarHeight}]
	set structureX [distanceToScreen [expr {$x-2}]]
	if {$structureX < 0} {
	    set structureX 0
	}
	return [list $structureX $structureY]
    } else {
	return [list [distanceToScreen $x] [distanceToScreen $y]]
    }
}

#¥ moveWin [win name] <left> <top> - moves current or specified window. 
#  The window name can be "StatusWin".
proc moveWin {args} {
    for {set i 0} {$i < [llength $args]} {incr i} {
	set val [lindex $args $i]
	switch -- $val {
	    "--" {
		incr i
		break
	    }
	    "-s" {
		set structure 1
	    }
	    default {
		break
	    }
	}
    }
    set diff [expr {[llength $args] - $i}]
    if {$diff > 3} {
	error "Too many args: $args"
    } elseif {$diff < 2} {
	error "Too few args: $args"
    } elseif {$diff == 3} {
	set win [winTailToFullName [lindex $args $i]]
	incr i
    } else {
	set win [win::Current]
    }
    foreach {x y} [lrange $args $i end] {break}
    if {$win == ""} { error "Cancelled" }
    global win::tk
    # Must check it's not too high.
    if {$y < $::defTop} {
	set y $::defTop
    }
    # Need to position further up to account for the titlebar.
    if {$::alpha::windowingsystem eq "x11"} {
	if {[info exists structure]} {
	    set structureY [expr {[distanceToScreen $y] + $::titlebarHeight}]
	} else {
	    set structureY [expr {[distanceToScreen $y]}]
	}
    } else {
	if {[info exists structure]} {
	    set structureY [distanceToScreen $y]
	} else {
	    set structureY [expr {[distanceToScreen $y] - $::titlebarHeight}]
	}
    }
    set structureX [distanceToScreen [expr {$x-2}]]
    if {$structureX < 0} {
	set structureX 0
    }
    wm geometry [winfo toplevel $win::tk($win)] +$structureX+$structureY
    # For some reason, without this update, if we do a moveWin, but
    # then immediately throw up a dialog, the moveWin is ignored.
    # It would be good to track down exactly where the problem happens...
    update idletasks
}

#¥ sizeWin [win name] <width> <height> - sets size of current or
#  specified window.  The window name can be "StatusWin", although only the
#  width can be changed.
proc sizeWin {args} {
    for {set i 0} {$i < [llength $args]} {incr i} {
	set val [lindex $args $i]
	switch -- $val {
	    "--" {
		incr i
		break
	    }
	    "-s" {
		set structure 1
	    }
	    default {
		break
	    }
	}
    }
    set diff [expr {[llength $args] - $i}]
    if {$diff > 3} {
	error "Too many args: $args"
    } elseif {$diff < 2} {
	error "Too few args: $args"
    } elseif {$diff == 3} {
	set win [winTailToFullName [lindex $args $i]]
	incr i
    } else {
	set win [win::Current]
    }
    foreach {w h} [lrange $args $i end] {break}
    if {$win == ""} { error "Cancelled" }
    global win::tk
    # The OS will add the titlebarheight to this.
    if {[info exists structure]} {
	set totalH [expr {[distanceToScreen $h] - $::titlebarHeight}]
    } else {
	set totalH [distanceToScreen $h]
    }
    wm geometry [winfo toplevel $win::tk($win)] \
      [distanceToScreen $w]x$totalH
}
#¥ getGeometry ?-s? ?--? [win] - return a TCL list containing the left 
#  edge of the current window, the top, the width, and height.
proc getGeometry {args} {
    global win::tk
    
    switch -- [llength $args] {
	0 {
	    set w [win::Current]
	}
	1 {
	    if {[lindex $args 0] eq "-s"} {
		set with_s 1
		set w [win::Current]
	    } else {
		set w [winTailToFullName [lindex $args 0]]
	    }
	}
	2 {
	    if {[lindex $args 0] eq "-s"} {
		set with_s 1
	    } elseif {[lindex $args 0] eq "--"} {
		# nothing
	    } else {
		return -code error "Bad argument [lindex $args 0]"
	    }
	    set w [winTailToFullName [lindex $args 1]]
	}
	default {
	    error "Bad args"
	}
    }
    
    if {$w == ""} {
	error "No open window"
    }
    
    set g [eval [list screenToDistance] \
      [split [winfo geometry [winfo toplevel $win::tk($w)]] "x+."]]
    if {[info exists with_s]} {
	return [list [lindex $g 2] [lindex $g 3] [lindex $g 0] \
	 [expr {[lindex $g 1] + [screenToDistance $::titlebarHeight]}]]
    } else {
	return [list [expr {[lindex $g 2]+2}] \
	  [expr {[lindex $g 3] + [screenToDistance $::titlebarHeight]}] \
	  [lindex $g 0] \
	 [expr {[lindex $g 1] + 0}]]
    }
}
