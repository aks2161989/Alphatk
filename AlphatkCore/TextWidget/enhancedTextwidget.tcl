## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "enhancedTextwidget.tcl"
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
 # of the license agreement (i.e. as part of an Alphatk distribution).
 # 
 # ###################################################################
 ##

package provide enhancedTextWidget 3.3

package require defaults 0.1
package require Tk 8.5

# Load our colouring code.
source [file join [file dirname [info script]] syntaxColouring.tcl]

if {0} {
    toplevel .tt
    set font "monaco 9"
    # font metrics $font claims it is "fixed" i.e. monospace
    pack [text .tt.t -font $font] -fill both -expand 1
    set w .tt.t
    $w configure -tabstyle wordprocessor
    
    # tab size 8 fails
    $w insert 1.0 "11111111222222223333333344444444\n"
    $w insert 1.0 "\ta\tb\tc\td\n"
    
    # tab size 4 fails
    $w tag configure tab4 -tabs "[expr {[font measure $font 0000]}] left"
    $w insert 1.0 "11111111222222223333333344444444\n"
    $w insert 1.0 "\ta\tb\tc\td\n"
    $w tag add tab4 1.0 3.0
}

# ×××× Public API ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 #
 # tw::Hook name ?val? --
 # 
 # Used to specify one of a number of hook Tcl scripts
 # which will be called under a number of circumstances by the enhanced
 # text widget.
 # 
 # Since it behaves like 'set', it can also be used with no extra 
 # argument to query the script associated with a given event.
 #
 # It is used for a variety of predefined hooks.  These are:
 # 
 # activate w -- this is now the foremost editing window
 # 
 # deactivate w -- this window was the foremost and is about to lose
 # the focus
 # 
 # lock w l -- the user has clicked in the 'lock' region of the status
 # control and the window has changed to status $l (0 or 1 as to whether
 # unlocked or locked)
 # 
 # save w -- the user has asked that the window be saved.
 # 
 # dirty w d -- the window has become dirty ($d == 1) or clean ($d == 0).
 # 
 # position {row col} -- the current cursor position is given by the
 # text string {row col}.
 # 
 # hyper cmd -- the user has clicked on a hypertext link in the window
 # and the $cmd should be evaluated in Tcl.
 # 
 # charInsertDelete w pos char -- a single character has just been inserted
 # 
 # created w -- the text widget is ready to have text inserted, but
 # it may be a good time to adjust tags, tabsize etc.
 # 
 # These hooks provide the developer with an API to deal with 
 # these standard events which may occur with the enhanced text
 # widget.
 # 
 # -------------------------------------------------------------------------
 ##
proc tw::Hook {name args} {
    variable hooks
    variable knownHooks
    if {[lsearch -exact $knownHooks $name] == -1} {
	return -code error "Unknown hook \"$name\", should be one of\
	  [join $knownHooks ,]"
    }
    eval [list ::set hooks($name)] $args
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tw::Set" --
 # 
 #  var == colortags
 #  
 #  Sets the 'colortags' list associated with a particular enhanced text
 #  widget.  This is a list of arbitrary pieces of information which is
 #  used for colouring.
 #  
 #  var == bindtags
 #  
 #  Sets the bind mode list for this window - foreach element of this
 #  list, all panes associated with that element will have the
 #  ${element}AlphaStyle bindtag as one of the first elements of their
 #  bindtags list.
 #  
 #  var == wordbreak
 #  
 #  Sets the wordbreak regular expression for the window, for use in
 #  syntax colouring and forward/backward word.
 # -------------------------------------------------------------------------
 ##
proc tw::Set {w var value} {
    variable split
    if {[info exists split($w)]} {
	set w [set split($w)]
    }
    if {[lsearch -exact {bindtags colortags wordbreak} $var] == -1} {
	return -code error "Bad variable '$var' - should be bindtags, colortags\
	  or wordbreak"
    }
    if {![llength [info commands ::$w]]} {
	# Widget is only half-created.  No need to do anything fancy.
	return [setvar $w $var $value]
    }

    variable $w
    
    switch -- $var {
	"bindtags" {
	    set oldbinds [list]
	    set newbinds [list]
	    if {[info exists ${w}(bindtags)] && ([::set ${w}(bindtags)] ne "")} {
		foreach old [::set ${w}(bindtags)] {
		    lappend oldbinds ${old}AlphaStyle
		}
	    }
	    ::set ${w}(bindtags) $value
	    foreach newb $value {
		lappend newbinds ${newb}AlphaStyle
	    }
	    ReplaceBindTags $w $oldbinds $newbinds
	    return $value
	}
	"wordbreak" - "colortags" {
	    setvar $w $var $value
	    _recolour $w
	    return $value
	}
    }
}

proc tw::_recolour {w} {
    if {[winfo exists $w]} {
	if {[winfo ismapped $w] && [winfo viewable $w]} {
	    ::tw::arrangeToColour $w {} {}
	} else {
	    bind [winfo toplevel $w] <Map> \
	      "[list ::tw::arrangeToColour $w {} {}] ;\
	      [list bind [winfo toplevel $w] <Map> {}]"
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tw::GetColorTags" --
 # 
 #  Reads the 'mode' string associated with a particular enhanced text widget.
 #  See 'SetMode' for its meaning.
 # -------------------------------------------------------------------------
 ##
proc tw::GetColorTags {w} {
    variable split
    if {[info exists split($w)]} {
	set w [set split($w)]
    }
    variable $w
    ::set ${w}(colortags)
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tw::Toolbar" --
 # 
 #  Used to manipulate or query the 'toolbar' frame associated with this
 #  window.  This is a vertical bar located in the top right corner of
 #  the widget (above the vertical scrollbar, to the right of the widget's
 #  contents).  The toolbar frame already contains a number of other
 #  widgets provided by the enhanced text widget, but this command
 #  provides an API by which further developer defined widgets may be added.
 #  
 #  There are three main 'Toolbar' subcommands:
 #  
 #  "path" subwidgetname - returns the widget path of a subwidget which
 #  either will be or has been placed in the toolbar frame.
 #  
 #  "add" subwidgetname - uses 'grid' to add the specified widget to
 #  the bottom of the toolbar.
 #  
 #  "remove" subwidgetname - calls 'grid forget' to remove the 
 #  specified widget from the toolbar.
 # -------------------------------------------------------------------------
 ##
proc tw::Toolbar {w cmd path} {
    switch -- $cmd {
	"path" {
	    return $w.rt.$path
	}
	"add" {
	    set num [llength [grid slaves $w.rt]]
	    grid $w.rt.$path -row $num -sticky ew
	}
	"remove" {
	    grid forget $w.rt.$path
	}
    }
}

proc tw::PreMakeWindow {W args} {
    set w [_uniqueTextWidget $W]
    variable $w
    
    foreach {arg val} $args {
	switch -- $arg {
	    "-encoding" {
		if {$val != ""} {
		    set ${w}(encoding) $val
		}
	    }
	    default {
		return -code error "Bad argument $arg to PreMakeWindow"
	    }
	}
    }
    return $w
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tw::MakeWindow" W ?contents? ?opt val opt val ...? --
 # 
 #  Creates a new enhanced text widget inside the frame/toplevel '$W'.
 #  Unlike conventional Tk widgets, the enhanced text widget expects to
 #  take over the contents of a given empty frame or toplevel, into which
 #  it will place and control a number of other widgets.
 #  
 #  Optional arguments give the desired textual contents of the widget,
 #  followed by a large number of possible option-value pairs.  Allowed
 #  options are:
 #  
 #  -encoding : sets the encoding associated with the widget. This has
 #  no particular effect, except to be a piece of information which is
 #  made available.
 #  
 #  -font : sets the font/size to use for the widget, in the standard
 #  form for Tk's '-font' option
 #  
 #  -tabsize : sets the tabsize, typically '8', '4' or '2'.
 #  
 #  -horizontalScrollbar boolean : whether to have a horizontal scrollbar
 #  in the window or not (this can be controlled programmatically later as
 #  well).
 #  
 #  -linenumbers boolean : whether to provide an additional left margin
 #  in the widget to show line numbers and other information.
 #  
 #  -minimal boolean : minimal windows do not contain a horizontal scrollbar
 #  or a toolbar in the top right corner.  They are typically used for
 #  split windows, and rely on the existence of an 'original' window for
 #  some actions.
 # -------------------------------------------------------------------------
 ##
proc tw::MakeWindow {W {text ""} args} {
    set w [_uniqueTextWidget $W]
    uplevel 1 [list CompleteWindow $W $w $text] $args
}

proc tw::CompleteWindow {W w {text ""} args} {
    # The vertical scrollbar
    set ws [_textTo $w scroll]
    
    variable $w
    global tcl_platform
    variable window_activate ""

    set minimal 0

    if {![info exists ${w}(linenumbers)]} {
	set ${w}(linenumbers) 0
    }
    if {![info exists ${w}(horizScrollbar)]} {
	set ${w}(horizScrollbar) 0
    }
    if {[info exists ${w}(wrap)]} {
	set wrap [set ${w}(wrap)]
	unset ${w}(wrap)
    } else {
        set wrap "none"
    }

    if {[info exists ${w}(font)]} {
	set font [list [set ${w}(font)]]
	unset ${w}(font)
	
	if {[info exists ${w}(fontsize)]} {
	    lappend font [set ${w}(fontsize)]
	    unset ${w}(fontsize)
	}
    }
    
    foreach {arg val} $args {
	switch -- $arg {
	    "-encoding" {
		if {$val != ""} {
		    set ${w}(encoding) $val
		}
	    }
	    "-font" {
		set font $val
	    }
	    "-tabsize" {
		set ${w}(tabsize) $val
	    }
	    "-minimal" {
		set minimal $val
	    }
	    "-horizontalScrollbar" {
		set ${w}(horizScrollbar) $val
	    }
	    "-linenumbers" {
		set ${w}(linenumbers) $val
	    }
	    default {
		return -code error "Bad argument $arg to MakeWindow"
	    }
	}
    }
    
    if {!$minimal} {
	foreach {p v} [list encoding "" dirty 0 read-only 0 \
	  tabsize 8 platform $tcl_platform(platform)] {
	    if {![info exists ${w}($p)]} {
		set ${w}($p) $v
	    }
	}
    }
    
    variable split
    if {[info exists split($w)]} {
	set peer 1
    } else {
        set peer 0
    }
    
    if {$peer} {
	set origW $split($w)
	$origW peer create $w -relief flat -bd 2 -yscrollcommand "$ws set" \
	  -bg white -height 0 -wrap $wrap
    } else {
	text $w -relief flat -bd 2 -yscrollcommand "$ws set" \
	  -bg white -height 0 -wrap $wrap
    }
    $w configure -tabstyle wordprocessor
    
    set tags [bindtags $w]
    set idx [lsearch -exact $tags "Text"]
    bindtags $w [lreplace $tags $idx $idx AlphaStyle]
    
    if {[info exists font]} {
	$w configure -font $font
    }

    global tcl_platform
    if {[tk windowingsystem] eq "classic" \
      || [tk windowingsystem] == "aqua"} {
	$w configure -highlightthickness 0
    }
    scrollbar $ws -command [list ::tw::direct_yview $w]
    
    # Add a special corner element.
    if {[winfo exists $W.corner]} {
	set corner $W.corner
    } else {
	switch -- [tk windowingsystem] {
	    "win32" - "windows" {
		set corner [Resizer::resizer $W.corner [winfo reqwidth $ws]]
	    }
	    "classic" - "aqua" {
		set corner [frame $W.corner -width [winfo reqwidth $ws] \
		  -height [winfo reqwidth $ws]]
	    }
	    default {
		set corner ""
	    }
	}
    }
    
    # Find next free row
    set row [lindex [grid size $W] 1]
    
    # Both styles use exactly three columns.
    if {$minimal} {
	# A minimal window takes up one or two rows, and cannot
	# have a horizontal scrollbar.  It also doesn't have
	# the toolbar at the top right
	if {[string length $corner]} {
	    grid $w -sticky news -column 1 -row $row -rowspan 2
	} else {
	    grid $w -sticky news -column 1 -row $row
	}
	grid $ws -sticky nse -column 2 -row $row
	grid rowconfigure $W $row -weight 1
	if {[string length $corner]} {
	    incr row
	    grid $corner -sticky nse -column 2 -row $row
	    grid rowconfigure $W $row -weight 0
	}
    } else {
	# A more complex window takes up four or five rows, and the
	# vertical scrollbar is complicated by the small toolbar in the
	# top right.  Anyone can add things to that toolbar with
	# 'tw::Toolbar'.
	::ttk::frame $W.rt -height 48
	catch {$W.rt configure -style Toolbar}
	#-highlightcolor red 
	::tk::frame $W.splitter -height 8 -relief raised -borderwidth 3 \
	  -highlightthickness 1 -width [winfo reqwidth $ws]
	bindtags $W.splitter Splitter
	if {[string length $corner]} {
	    grid $w -sticky news -column 1 -row $row -rowspan 4
	} else {
	    grid $w -sticky news -column 1 -row $row -rowspan 3
	}
	grid $W.rt -sticky nsew -column 2 -row $row
	incr row
	grid $W.splitter -sticky we -column 2 -row $row
	incr row
	grid $ws -sticky nse -column 2 -row $row
	tw::horizScrollbar $w 0
    
	::ttk::label $W.rt.dirty -image clean
	bindtags $W.rt.dirty [concat "Lock" [bindtags $W.rt.dirty]]

	grid $W.rt.dirty -row 0 -sticky ew
	grid columnconfigure $W.rt 0 -weight 1

	grid rowconfigure $W $row -weight 1
	if {[string length $corner]} {
	    incr row
	    grid $corner -sticky nse -column 2 -row $row
	    grid rowconfigure $W $row -weight 0
	}
    }

    $w tag configure elidden -elide 1 \
      -background [default::color activebackground]
    # Set up hypertext handling
    $w tag configure hyper -underline 1
    $w tag bind hyper <ButtonPress> "%W hyperClick activate %x %y ; break"
    $w tag bind hyper <Enter> "%W hyper enter %x %y ; break"
    $w tag bind hyper <Motion> "%W hyper motion %x %y ; break"
    $w tag bind hyper <Leave> "%W hyper leave %x %y ; break"
    # Set up highlight handling
    $w tag configure highlight -underline 1;# -background gray80
    # Set up background selection
    if {[tk windowingsystem] eq "aqua"} {
	$w tag configure sel -borderwidth 0
	$w configure -inactiveselectbackground lightgray \
	  -exportselection 0
    } else {
	$w configure -inactiveselectbackground darkgray \
	  -exportselection 0
    }

    # Allow code to adjust the window (create tags etc).
    CallHook created $w

    update idletasks
    # These three need only be set once per window, since they
    # apply to all columns (i.e. all split windows) which are
    # added.  However, it doesn't harm to redo them each time.
    grid columnconfigure $W 2 -weight 0 -minsize [winfo reqwidth $ws]
    grid columnconfigure $W 1 -weight 1
    grid columnconfigure $W 0 -weight 0

    if {!$peer} {
	$w insert 1.0 $text
    }
    $w mark set insert 1.0
    
    _updateMargin $w
    
    rename $w ::tw::$w
    ;proc ::$w {cmd args} \
      "uplevel 1 \[list namespace eval ::tw \"\$cmd $w \$args\"\]"

    setTabs $w [set ${w}(tabsize)]

    # Register drag'n'drop handlers
    if {$::alpha::haveDnd} {
	after idle [list ::tw::BindDragDrop $w]
    }
    
    if {[info exists ${w}(bindtags)] && ([set ${w}(bindtags)] ne "")} {
	Set $w bindtags [set ${w}(bindtags)]
    }
    if {[info exists ${w}(colortags)] && ([set ${w}(colortags)] ne "")} {
	Set $w colortags [set ${w}(colortags)]
    }
    
    return $w
}

# ×××× Setup and initialization ×××× #

# Namespace used to over-ride the text widget, and to store
# a variety of enhanced-text-widget-specific information. This
# information is private to the widget.
namespace eval tw {    
    variable lmatch [list "(" "\{" "\[" "\"" "\<"]
    variable rmatch [list ")" "\}" "\]" "\"" "\>"]
    
    variable split
    variable split_focus
    variable splitter
    variable hooks
    variable window_activating 0
    variable window_activate ""

    variable knownHooks [list activate created deactivate dirty hyper\
      charInsertDelete position lock save textChanged message\
      dragndrop]
}


proc tw::CallHook {name args} {
    variable hooks
    if {[info exists hooks($name)]} {
	if {[catch {eval $hooks($name) $args} err]} {
	    #bgerror $err
	    return ""
	}
	return $err
    }
}

;proc _listAllTextSubcommands {} {
    text .alphatktextdummy
    catch {.alphatktextdummy alphatk} msg
    destroy .alphatktextdummy

    regsub ".*must be " $msg "" msg
    regsub ", or " $msg ", " msg
    regsub -all ", " $msg " " msg
    rename _listAllTextSubcommands {}
    return [::split $msg]
}

# For each text widget subcommand, create a dummy procedure 'tw::subcmd'
# for our purposes of wrapping the text widget.  Most of these subcommands
# are actually over-ridden below, but we do this exhaustively, so that
# even if the text widget gains new subcommands with new Tk releases
# (e.g. Tk 8.4 adds 'edit'), we make sure we cover them all.
if {[info commands ::tw::configure] == ""} {
    foreach subcmd [_listAllTextSubcommands] {
	;proc tw::$subcmd {w args} \
	  "uplevel 1 ::tw::\[getSplitFocus \$w\] $subcmd \$args"
    }
    unset -nocomplain subcmd
    
    # Also copy over all bindings from 'Text' to our widget.
    foreach bind [bind Text] {
	set to "Alpha"
	foreach bt {Focus Enter Leave Motion Button B1 B2 B3} {
	    if {[string first $bt $bind] != -1} {
		set to "AlphaStyle"
		break
	    }
	}
	if {[bind $to $bind] == ""} {
	    bind $to $bind [list if {"%W" ne "."} [bind Text $bind]]
	}
	unset bt to
    }
    unset bind
    
    proc ::tw::_built_in_replace {w begin end text} {
	$w replace $begin $end $text
    }
    
}

# These three procedures are the only ones which
# know that text widgets are called '$W.text$num'
proc tw::_uniqueTextWidget {W} {
    # Find an unused path name of a specific form inside the window (if
    # the frame is split, we'll use more and more of these).
    set i 1
    while {[winfo exists $W.text$i]} {
	incr i
    }
    return $W.text$i
}

# Given the widget path of a text window, return
# the widget path of the corresponding '$to' widget
# (a scrollbar, margin, toolbar, etc).
proc tw::_textTo {w to} {
    if {$w == "."} { error "Cancelled" }
    regsub "\\.text" $w ".$to" wres
    set wres
}

proc tw::_getFocusWidget {W args} { 
    set w [getSplitFocus $W.text1]
    if {[llength $args]} {
	eval [list ::$w] $args
    } else {
	return $w
    }
}

# ×××× Standard Text widget ×××× #

proc tw::bbox {w args} { uplevel 1 ::tw::[getSplitFocus $w] bbox $args } 
proc tw::cget {w args} { uplevel 1 ::tw::[getSplitFocus $w] cget $args } 
proc tw::compare {w args} { uplevel 1 ::tw::[getSplitFocus $w] compare $args } 
proc tw::configure {w args} {
    set cmd ::tw::[getSplitFocus $w]
    set oldwrap [expr {[$cmd cget -wrap] == "none"}]
    set code [catch [list uplevel 1 [list $cmd configure] $args] res]
    set newwrap [expr {[$cmd cget -wrap] == "none"}]
    if {($oldwrap ne $newwrap)} {
	_updateMargin $w 1
    }
    return -code $code $res
} 
proc tw::debug {w args} { uplevel 1 ::tw::[getSplitFocus $w] debug $args } 
proc tw::dump {w args} { uplevel 1 ::tw::[getSplitFocus $w] dump $args } 
proc tw::dlineinfo {w args} { 
    uplevel 1 ::tw::[getSplitFocus $w] dlineinfo $args 
} 
proc tw::get {w args} { uplevel 1 ::tw::[getSplitFocus $w] get $args } 

proc tw::image {w args} { uplevel 1 ::tw::[getSplitFocus $w] image $args } 
proc tw::index {w args} { uplevel 1 ::tw::[getSplitFocus $w] index $args } 
proc tw::mark {w args} {
    set res [uplevel 1 ::tw::[getSplitFocus $w] mark $args]
    if {([lindex $args 0] == "set") && ([lindex $args 1] == "insert")} {
	CallHook position [base_window $w] [::split [index $w insert] .]
    }
    return $res
}
proc tw::tag {w args} { uplevel 1 ::tw::[getSplitFocus $w] tag $args } 
proc tw::window {w args} { uplevel 1 ::tw::[getSplitFocus $w] window $args } 

# This is uplevel 2 because of the use of 'namespace eval' in
# the renamed window procedure.
proc tw::search {w args} {
    #puts stderr "$w $args"
    uplevel 2 tw::[getSplitFocus $w] search $args
}

proc tw::viewable {w args} {
    if {[llength $args]} {
	set first [$w index @0,0]
	set last [$w index "@[winfo width $w],[winfo height $w]"]
	foreach pos $args {
	    if {[$w compare $pos < $first]} {
		lappend res -1
	    } elseif {[$w compare $pos > $last]} {
		lappend res 1
	    } else {
		lappend res 0
	    }
	}
	return $res
    } else {
	_viewable $w
    }
}

proc tw::see {w args} {
    #puts "see $w $args"
    set ww [getSplitFocus $w]
    set old [_viewable $ww]
    set ret [uplevel 1 ::tw::$ww see $args]
    set new [$ww yview]
    _marginYscroll $ww $new
    eval [list arrangeToColourNewlyRevealed $ww] $old
    return $ret
}

proc tw::scan {w args} { 
    set ww [getSplitFocus $w]
    set old [_viewable $ww]
    set ret [uplevel 1 ::tw::$ww scan $args]
    set new [$ww yview]
    _marginYscroll $ww $new
    eval [list arrangeToColourNewlyRevealed $ww] $old
    return $ret
} 

# The direct version is called from scrollbars
proc tw::direct_xview {w args} { 
    uplevel 1 [list ::tw::$w xview] $args 
} 

proc tw::xview {w args} { 
    set ww [getSplitFocus $w]
    eval [list direct_xview $ww] $args
} 

# The direct version is called from scrollbars
proc tw::direct_yview {ww args} {
    if {[llength $args]} {
	set old [_viewable $ww]
	set ret [uplevel 1 [list ::tw::$ww yview] $args]
	set new [$ww yview]
	_marginYscroll $ww $new
	# now recolour as appropriate
	eval [list arrangeToColourNewlyRevealed $ww] $old
	return $ret
    } else {
	# '$w' is a command in the 'tw' namespace so this
	# is not an infinite loop!
	$ww yview
    }
}

proc tw::yview {w args} {
    #puts "yview $w $args"
    set ww [getSplitFocus $w]
    eval [list direct_yview $ww] $args
}

# ×××× Insertion and Deletion ×××× #

proc tw::silent_replace {w from to text} {
    # We must have normalized index positions
    variable split

    set colourArg [list replace $from $to [string length $text]]
    
    if {[info exists split($w)]} {
	variable splitter
	set wlist $splitter([set split($w)])
    } else {
        set wlist [list $w]
    }
    foreach ww $wlist {
	lappend oldview [_viewable $ww]
    }
    uplevel 1 [list ::tw::_built_in_replace $w $from $to $text]
    foreach ww $wlist view $oldview {
	eval [list arrangeToColourNewlyRevealed $ww] $view $colourArg
	_updateMargin $ww
    }
}

proc tw::silent_insert {w where args} { 
    variable split
    set where [$w index $where]

    if {[info exists split($w)]} {
	variable splitter
	set wlist $splitter([set split($w)])
    } else {
	set wlist [list $w]
    }
    foreach ww $wlist {
	lappend oldview [_viewable $ww]
    }
    uplevel 1 [list ::tw::$ww insert $where] $args
    foreach ww $wlist view $oldview {
	eval [list arrangeToColourNewlyRevealed $ww] $view [list insert] $where
	_updateMargin $ww
    }
}

proc tw::silent_delete {w args} { 
    variable split
    # We must have normalized index positions
    foreach p $args {
	lappend idx [index $w $p]
    }
    if {[info exists split($w)]} {
	variable splitter
	set wlist $splitter([set split($w)])
    } else {
	set wlist [list $w]
    }
    foreach ww $wlist {
	lappend oldview [_viewable $ww]
    }
    uplevel 1 [list ::tw::$w delete] $idx
    foreach ww $wlist view $oldview {
	eval [list arrangeToColourNewlyRevealed $ww] $view [list delete] $idx
	_updateMargin $ww
    }
}

proc tw::insert {w where args} {
    if {[$w cget -state] == "disabled"} {return}
    variable split
    set char [join $args ""]
    if {[string length $char] == 0} {
	# Insert empty string is a no-op
	return
    }
    # make sure we use the 'where' which corresponds to the correct pane if a
    # window has been split into pieces.  To do this we must turn it into a 
    # canonical line.col form
    set where [index $w $where]
    if {[info exists split($w)]} {
	set w $split($w)
    }
    variable $w
    
    if {![info exists ${w}(shell)]} {
	if {![info exists ${w}(undo)]} {
	    dirty $w
	}
	set where [index $w $where]
	lappend ${w}(undo) [concat [list insert $where] $args]
	if {[info exists ${w}(redo)]} {
	    unset ${w}(redo)
	}
	set numChanges [llength [set ${w}(undo)]]
    } else {
	set numChanges 0
    }
    
    eval [list silent_insert $w $where] $args

    CallHook position $w [::split [index $w insert] .]

    if {$numChanges > 0} {
	CallHook textChanged $w $numChanges
    }
}

proc tw::replace {w begin end text} {
    if {[$w cget -state] == "disabled"} {return}
    if {[info exists split($w)]} {
	set w $split($w)
    }
    variable $w

    set begin [index $w $begin]
    set end [index $w $end]

    if {![info exists ${w}(shell)]} {
	if {![info exists ${w}(undo)]} {
	    dirty $w
	}
	lappend ${w}(undo) [list replace $begin $end [::tw::$w get $begin $end] $text]
	if {[info exists ${w}(redo)]} {
	    unset ${w}(redo)
	}
	set numChanges [llength [set ${w}(undo)]]
    } else {
	set numChanges 0
    }

    silent_replace $w $begin $end $text

    CallHook position $w [::split [index $w insert] .]

    if {$numChanges > 0} {
	CallHook textChanged $w $numChanges
    }
}

proc tw::delete {w args} {
    if {![llength $args]} {
	return -code error \
	  "wrong # args: should be \"$w delete index1 ?index2 ...?\""
    }
    if {[$w cget -state] == "disabled"} {return}
    # make sure we use the 'where' which corresponds to the correct pane if a
    # window has been split into pieces.  To do this we must turn it into a 
    # canonical line.col form
    set where1 [lindex $args 0]
    set where2 [lindex $args 1]
    if {[llength $args] > 2} {
	# not supported yet
    }
    set where1 [index $w $where1]
    if {$where2 != ""} {
	set where2 [index $w $where2]
	if {[compare $w $where1 == $where2]} {
	    return
	}
	if {[compare $w $where2 == end]} {
	    set where2 [index $w "$where2 -1c"]
	}
    }
    variable split
    if {[info exists split($w)]} {
	set w $split($w)
    }
    variable $w
    if {![info exists ${w}(shell)]} {
	if {![info exists ${w}(undo)]} {
	    dirty $w
	}
	if {$where2 != ""} { 
	    lappend ${w}(undo) [list delete $where1 $where2 [::tw::$w get $where1 $where2]]
	} else {
	    lappend ${w}(undo) [list delete $where1 $where2 [::tw::$w get $where1]]
	}
	if {[info exists ${w}(redo)]} {
	    unset ${w}(redo)
	}
    }
    if {$where2 != ""} {
	silent_delete $w $where1 $where2
    } else {
	silent_delete $w $where1
    }

    CallHook position [base_window $w] [::split [index $w insert] .]
}

# ×××× Window deletion ×××× #

proc tw::windowCleanup {w} {
    variable split
    if {[info exists split($w)]} {
	variable splitter
	variable split_focus
	set original $split($w)
	foreach ww $splitter($original) {
	    unset split($ww)
	    if {($ww ne $original)} {
		rename ::$ww {}
	    }
	}
	unset splitter($original)
	unset split_focus($original)
    }
    variable colouring
    if {[info exists colouring($w)]} {
	unset colouring($w)
    }
    _destroyTextWidget $w
}

proc tw::_destroyTextWidget {ww} {
    # Remove the procedure which is overriding
    # the tk widget name.
    rename ::$ww {}
    # Remove any possible bindings which may trigger
    # side-effects (esp. for destroy)
    bindtags $ww $ww
    # Destroy the text widget
    destroy $ww
    # Cleanup all state information stored in this
    # variable
    variable $ww
    unset -nocomplain $ww
    # Destroy the associated vertical scrollbar
    destroy [_textTo $ww scroll]
}

# ×××× Split windows ×××× #

bind Splitter <Enter> \
  "%W configure -highlightbackground \[color activebackground\]"
bind Splitter <Leave> \
  "%W configure -highlightbackground \[color background\]"
bind Splitter <Button-1> {
  %W configure -relief sunken
  tw::_getFocusWidget [winfo parent %W] toggleSplit
}
bind Splitter <ButtonRelease-1> "%W configure -relief raised"

proc tw::split {w} {
    variable split
    if {[info exists split($w)]} {
	return
    }
    variable split_focus
    set split_focus($w) $w

    set W [winfo parent $w]
    
    set sash [frame $W.split -height 6 -bd 3 -relief raised]
    grid $W.split -sticky ew -column 0 -columnspan 3 -row 4

    variable $w

    set ww [_uniqueTextWidget $W]

    variable splitter
    if {[info exists split($w)]} {
	set original $split($w)
	lappend splitter($original) $ww
    } else {
	set original $w
	set split($w) $w
	lappend splitter($original) $w $ww
    }
    set split($ww) $original

    CompleteWindow $W $ww [$w get 1.0 "end -1c"] \
      -minimal 1 -font [$w cget -font] -tabsize [set ${w}(tabsize)]

    bind $sash <Button-1> "tw::_startGrip $sash %y $w $ww"
    bind $sash <B1-Motion> "tw::_handleGrip $sash %Y $w $ww"
    bind $sash <B1-ButtonRelease-1> "tw::_endGrip $sash %y $w $ww"

    # Set up correct bindings.  We have to translate the
    # original window path (e.g. .al0.text1) to the new
    # window path, otherwise we'll inherit specific bindings
    # we don't want!
    regsub -all "$w" [bindtags $w] $ww newtags
    bindtags $ww $newtags
    after idle [list ::tw::arrangeToColour $ww {} {}]
}

proc tw::otherPane {w} {
    variable split
    if {![info exists split($w)]} {
	return -code error "Cancelled: no other pane"
    }
    variable splitter
    variable split_focus
    set original $split($w)
    foreach ww $splitter($original) {
	if {$ww != $split_focus($original)} {
	    focus $ww
	    return
	}
    }
}

proc tw::_startGrip {sash y w ww} {
    $sash configure -relief sunken
    grab $sash
}

# not an ideal solution, but kind of works.
proc tw::_handleGrip {sash y w ww} {
    set tophalf [expr {[winfo height $w] + ($y-[winfo rooty $sash])}]
    set height [expr {[winfo height $w] + [winfo height $ww]}]
    if {[set ww [expr {100*$tophalf/$height}]] < 0} {
	set ww 0
    }
    grid rowconfigure [winfo parent $w] 2 -weight $ww
    if {[set ww [expr {100-100*$tophalf/$height}]] < 0} {
	set ww 0
    }
    grid rowconfigure [winfo parent $w] 5 -weight $ww
    update
}

proc tw::_endGrip {sash y w ww} {
    $sash configure -relief raised
    grab release $sash
}


proc tw::toggleSplit {w} {
    if {$w == "."} { error "Cancelled - no window open." }
    variable split
    if {[info exists split($w)]} {
	unsplit $w
    } else {
	split $w
    }
}

proc tw::unsplit {w} {
    variable split
    variable splitter
    variable split_focus
    set original $split($w)
    set W [winfo parent $original]
    foreach ww $splitter($original) {
	unset split($ww)
	if {($ww ne $original)} {
	    # Destroy the splitting widget
	    destroy [winfo parent $ww].split
	    # Destroy the text widget
	    _destroyTextWidget $ww
	}
    }
    grid rowconfigure $W 5 -weight 0
    grid rowconfigure $W 4 -weight 0
    grid rowconfigure $W 2 -weight 1
    grid rowconfigure $W 1 -weight 0
    if {[winfo exists $W.corner]} {
	grid configure $W.corner -row 3
    }
    unset splitter($original)
    unset split_focus($original)
}

proc tw::_firstSplitWindow {w} {
    variable split
    if {[info exists split($w)]} {
	return $split($w)
    } else {
	return $w
    }
}

proc tw::_commandOnAllSplits {w pre {post ""}} {
    variable split
    if {[info exists split($w)]} {
	variable splitter
	foreach ww $splitter([set split($w)]) {
	    eval $pre [list $ww] $post
	}
    } else {
	eval $pre [list $w] $post
    }
}

proc tw::getSplitFocus {w} {
    variable split
    if {[info exists split($w)]} {
	variable split_focus
	return $split_focus($split($w))
    } else {
	return $w
    }
}

proc tw::base_window {w} {
    variable split
    return [expr {[info exists split($w)] ? $split($w) : $w}]
}

# ×××× The left margin widget ×××× #

proc tw::marginClick {w wm x y args} {
    set cur [tk::TextClosestGap $wm $x $y]
    set line [lindex [::split [$wm index $cur] .] 0]
    set txt [string trim [$wm get "$cur linestart" "$cur lineend"]]
    CallHook message "Clicked in margin at line $line"
    if {$txt == ""} {
	set folded [fold $w info "$line.0" "$line.0 +1 display line"]
	if {[llength $folded]} {
	    eval [list fold $w show] $folded
	} else {
	    CallHook message "Click!"
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tw::setMarginItem" --
 # 
 #  Change the string for a line or set of lines to be shown in the
 #  margin (where the line-number is ordinarily shown).  The 'args'
 #  contains a line number and string at present.
 # -------------------------------------------------------------------------
 ##
proc tw::setMarginItem {w {keepPrevious 0} args} {
    variable $w
    if {!$keepPrevious} {
	if {[info exists ${w}(margin,previous)]} {
	    set i [set ${w}(margin,previous)]
	    unset ${w}(margin,$i)
	    unset ${w}(margin,previous)
	}
    }
    if {[llength $args]} {
	set line [lindex $args 0]
	set ${w}(margin,$line) [lrange $args 1 end]
	set ${w}(margin,previous) $line
    }
    _updateMargin $w 1
}

proc tw::_updateMargin {w {force 0}} {
    variable $w
    
    set wm [_textTo $w margin]
    
    set hide [$w tag ranges elidden]
    
    if {[set ${w}(linenumbers)]} {
	if {![winfo exists $wm]} {
	    # Implementation of a thin margin on the left for
	    # various control options.
	    text $wm -width 1 -borderwidth [$w cget -borderwidth] \
	      -bg [color background] \
	      -highlightthickness [$w cget -highlightthickness] \
	      -relief flat -state disabled -cursor arrow -wrap none
	    $wm configure -font [$w cget -font]
	    $wm tag configure right -justify right
	    
	    array set info [grid info $w]
	    grid $wm -sticky wns -row $info(-row) \
	      -column 0 -rowspan $info(-rowspan)
	    
	    set repeat -1
	    $wm tag configure elidden -elide 1
	    bindtags $wm [concat Margin [bindtags $wm]]
	} else {
	    set repeat [expr {int([$w index end]) -1}]
	}

	set isWrapped [expr {[$w cget -wrap] != "none"}]
	
	if {$isWrapped} {
	    $wm configure -wrap char
	    return [_updateVisibleMargin $w $wm [$w yview]]
	}
	
	if {$force || ![info exists ${w}(numlines)] \
	  || ([set ${w}(numlines)] != $repeat)} {
	    set repeat [expr {int([$w index end]) -1}]
	    if {[winfo exists $wm]} {
		$wm configure -width [string length $repeat]
		for {set i 1} {$i <= $repeat} {incr i} {
		    if {$i != 1} {
			append str "\n"
		    }
		    if {[info exists ${w}(margin,$i)]} {
			foreach {text image} [set ${w}(margin,$i)] {break}
			if {[string length $image]} {
			    lappend extras \
			      [list $wm image create ${i}.0 -image $image]
			    append str " "
			    #$text
			} else {
			    append str $text
			}
		    } else {
			append str $i
		    }
		}
		$wm configure -state normal
		$wm delete 0.0 end
		$wm insert end $str right
		if {[info exists extras]} {
		    eval [join $extras ";"]
		}
		if {[info exists hide] && [llength $hide]} {
		    eval [list $wm tag add elidden] $hide
		}
		# Buglet/issue in Tk 8.5 - initial view is all wrong.
		catch {$wm count -update -ypixels 1.0 end}
		$wm yview moveto [lindex [$w yview] 0]
		$wm configure -state disabled
	    }
	    set ${w}(numlines) $repeat
	}
    } else {
	destroy $wm
    }
}

proc tw::_updateVisibleMargin {w wm new} {
    #puts "_updateVisibleMargin $w $wm $new"
    set repeat [expr {int([$w index end]) -1}]
    $wm configure -width [string length $repeat]

    set line [$w index @0,0]
    
    set bbox [$w bbox $line]
    set bbox_y [lindex $bbox 1]
    set bbox_h [lindex $bbox 3]
    incr bbox_y -$bbox_h
    set bbox_space [string range "           " 1 [string length $repeat]]
    #puts [list $repeat $bbox_space]
    
    set i [lindex [::split $line .] 0]
    while {1} {
	set y [lindex [$w bbox $line] 1]
	if {$y == ""} { break }
	incr bbox_y $bbox_h
	while {$y > $bbox_y} {
	    append str $bbox_space
	    incr bbox_y $bbox_h
	}
	set bbox_y $y
	append str "\n"
	append str $i
	incr i
	set line ${i}.0
    }
    $wm configure -state normal
    $wm delete 0.0 end
    $wm insert end [string range $str 1 end] right
    $wm configure -state disabled
}

proc tw::_marginYscroll {w new} {
    #puts "_marginYscroll $w $new"
    set wm [_textTo $w margin]
    if {[winfo exists $wm]} {
	if {[expr {[$w cget -wrap] != "none"}]} {
	    _updateVisibleMargin $w $wm $new
	} else {
	    eval [list ::$wm yview] moveto [lindex $new 0]
	}
    }
}

proc tw::toggleLineNumbers {w {create 1}} {
    variable $w

    if {[info exists ${w}(linenumbers)]} {
	set ${w}(linenumbers) [expr {1- [set ${w}(linenumbers)]}]
    } else {
	set ${w}(linenumbers) $create
    }

    _updateMargin $w
}

# ×××× Hypertext links ×××× #

proc tw::addHyper {w from to hyper} {
    $w tag add hyper $from $to
    variable $w
    if {![info exists ${w}(hypers)]} {
	set ${w}(hypers) 0
    }
    incr ${w}(hypers)
    set mark "hyper[set ${w}(hypers)]"
    $w mark set $mark $to
    set ${w}($mark) $hyper
}

proc tw::hyperClick {w action x y} {
    variable $w
    switch -- $action {
	"activate" {
	    hyper $w activate $x $y
	    set ${w}(hyper) [list $x $y]
	    after idle [list unset ::tw::${w}(hyper)]
	}
	"alreadyClicked" {
	    if {![info exists ${w}(hyper)]} { return 0 }
	    
	    foreach {xx yy} [set ${w}(hyper)] {break}
	    if {$xx == $x && $yy == $y} {
		return 1
	    }
	    return 0
	}
	default {
	    return -code error "Bad action"
	}
    }
}

proc tw::_getHyper {w pos} {
    while {1} {
	set hypername [$w mark next $pos]
	if {$hypername eq $pos || $hypername eq ""} {
	    return ""
	}
	if {[::string equal -length 5 "hyper" $hypername]} {
	    return $hypername
	}
	set pos $hypername
    }
}

proc tw::hyper {w what x y} {
    switch -- $what {
	"leave" {
	    CallHook message ""
	    $w config -cursor xterm
	    return
	}
    }
    set pos [tk::TextClosestGap $w $x $y]
    set range [$w tag prevrange hyper $pos]
    if {![llength $range] || [compare $w [lindex $range 1] < $pos]} {
	# We're right on the very edge of the hyper,
	# so we simply ignore things.
	return
    }
    variable $w

    set hypername [_getHyper $w $pos]
    
    if {$hypername eq "" || ![info exists ${w}($hypername)]} {
	return
    }
    set cmd [set ${w}($hypername)]

    switch -- $what {
	"activate" {
	    eval ::selectText $range
	    update
	    $w tag delete sel
	    update
	    CallHook hyper $cmd
	}
	"enter" - 
	"motion" {
	    CallHook message "---> '$cmd'"
	    $w config -cursor arrow
	}
    }
}

# ×××× Matching braces/quotes ×××× #

proc tw::balance {w} {
    set pair [eval [list findBalancedPair $w] [selectLimits]]
    eval [list select $w] $pair
    CallHook message "Matching braces selected, from [join $pair { to }]."
}

proc tw::findBalancedPair {w {before insert} {after insert}} {
    variable lmatch
    variable rmatch
    while {1} {
	while {1} {
	    set f [singlesearch $w -forwards -regexp \
	      -- "\[\]\[\{\(\)\}\]" $after end]
	    if {$f == "" || ![text::isEscaped $f]} {
		break
	    }
	    set after "$f +1c"
	}
	while {1} {
	    set b [singlesearch $w -backwards -regexp \
	      -- "\[\]\[\{\(\)\}\]" $before 1.0]
	    if {$b == "" || ![text::isEscaped $b]} {
		break
	    }
	    set before "$b -1c"
	}
	
	# echo "$b $before $after $f"
	if {([string length $f] == 0) || ([string length $b] == 0)} {
	    error "No matching delimiters"
	}
	if {[set i [lsearch -exact $rmatch [$w get $f]]] != -1} {
	    # we found a backwards looking element while looking forwards
	    # We need to find its partner
	    return [list [match $w [get $w $f] "$f -1c"] [index $w "$f +1c"]]
	} elseif {[set i [lsearch -exact $lmatch [get $w $b]]] != -1} {
	    # we found the opposite, which is also ok
	    return [list $b [index $w "[match $w [get $w $b] "$b +1c"] +1c"]]
	} else {
	    # hmm, this is harder
	    set before [match $w [get $w $b] "$b -1c"]
	    set after "[match $w [get $w $f] "$f+1c"] +1c"
	}
    }
}

proc tw::matchError {w dir look pos} {
    if {$pos != ""} {
	set start [lindex [::split [set pos [index $w $pos]] .] 0]
	error "No match $dir for '$look' from $pos; possible unmatched\
	  delimiter at: [string trim [get $w ${start}.0 [expr {$start+1}].0]]"
    } else {
	error "No further braces found"
    }
}

# Return position before matching quotation mark
proc tw::matchQuoteBack {w pos limit} {
    set pos "$pos +1c"
    while {1} {
	#update ; if {$::alpha::abort} {set ::alpha::abort 0 ; error "Action aborted by user."}
	set pos1 [singlesearch $w -backwards -- \" $pos $limit]
	if {$pos1 == ""} { matchError $w back \" $pos }
	if {![text::isEscaped $pos1]} {
	    break
	} else {
	    set pos "$pos1 -1c"
	}
    }
    return $pos1
}

# Return position after matching quotation mark
proc tw::matchQuoteForward {w pos limit} {
    while {1} {
	#update ; if {$::alpha::abort} {set ::alpha::abort 0 ; error "Action aborted by user."}
	set pos1 [singlesearch $w -forwards -- \" $pos $limit]
	if {$pos1 == ""} { matchError $w forward \" $pos }
	if {![text::isEscaped $pos1]} {
	    break
	} else {
	    set pos "$pos1 +1c"
	}
    }
    return "$pos1 +1c"
}

proc tw::matchForward {w pos looking matchlook limit} {
    variable rmatch
    variable lmatch
    while 1 {
	while {1} {
	    #update ; if {$::alpha::abort} {set ::alpha::abort 0 ; error "Action aborted by user."}
	    set pos1 [singlesearch $w -forwards -regexp \
	      -- $matchlook $pos $limit]
	    if {$pos1 == ""} { matchError $w forward [lindex ${looking} end] $pos }
	    set pos $pos1
	    if {![text::isEscaped $pos]} {
		break
	    } else {
		set pos "$pos +1c"
	    }
	}
	set char [$w get $pos]
	if {$char == "\""} {
	    set pos [matchQuoteForward $w "$pos +1c" $limit]
	    continue
	}
	if {[lindex $looking end] eq $char} {
	    set looking [lreplace $looking end end]
	    if {$looking == ""} {
		return $pos
	    }
	} else {
	    if {[lsearch -exact $rmatch $char] == -1} {
		lappend looking [lindex $rmatch [lsearch -exact $lmatch $char]]
	    } else {
		matchError $w forward [lindex ${looking} end] $pos
	    }
	}
	set pos "$pos +1c"
    }
}

proc tw::matchBack {w pos looking matchlook limit} {
    variable rmatch
    variable lmatch
    set pos "$pos +1c"
    while 1 {
	while {1} {
	    #update ; if {$::alpha::abort} {set ::alpha::abort 0 ; error "Action aborted by user."}
	    set pos1 [singlesearch $w -backwards -regexp \
	      -- $matchlook $pos $limit]
	    if {$pos1 == ""} { matchError $w back [lindex ${looking} end] $pos }
	    set pos $pos1
	    if {![text::isEscaped $pos]} {
		break
	    }
	}
	set char [$w get $pos]
	if {$char == "\""} {
	    set pos [matchQuoteBack $w "$pos -1c" $limit]
	    continue
	}
	if {[lindex $looking end] eq $char} {
	    set looking [lreplace $looking end end]
	    if {$looking == ""} {
		return "$pos"
	    }
	} else {
	    if {[lsearch -exact $lmatch $char] == -1} {
		lappend looking [lindex $lmatch [lsearch -exact $rmatch $char]]
	    } else {
		matchError $w back [lindex ${looking} end] "$pos -1c"
	    }
	}
    }
}

set tw::matchlook "\[\]\"\)\}\[\(\{\]"

proc tw::match {w char pos {limit ""}} {
    # echo "tw::match $w $char $pos $limit"
    variable lmatch
    variable rmatch
    variable matchlook
    set pattern $matchlook
    if {[set i [lsearch -exact $lmatch $char]] != -1} {
	lappend looking [lindex $rmatch $i]
	if {$limit == ""} { 
	    set limit end 
	} else {
	    set limit "$pos + ${limit}c"
	}
	if {$char eq "<"} {
	    set pattern "\[<>\"\]"
	}
	return [matchForward $w $pos $looking $pattern $limit]
    } elseif {[set i [lsearch -exact $rmatch $char]] != -1} {
	lappend looking [lindex $lmatch $i]
	if {$limit == "0" || $limit == ""} { 
	    set limit 1.0 
	} else {
	    set limit "$pos - ${limit}c"
	}
	if {$char eq ">"} {
	    set pattern "\[<>\"\]"
	}
	return [matchBack $w "$pos" $looking $pattern $limit]
    } else {
	error "Char '$char' unrecognised by match"
    }
}

# ×××× Word manipulation ×××× #

if {[info tclversion] < 8.5} {
    proc tw::backward_word {w pos} {
	set bk [splitreadvar $w wordbreak]
	
	set to [singlesearch $w -backwards -regexp -- $bk "$pos -1c" 1.0]
	if {$to == ""} {
	    return 1.0
	} else {
	    # Make sure we have the longest match
	    while {1} {
		set back [$w index "$to -1c"]
		if {[compare $w [singlesearch $w -count c -regexp -- \
		  $bk $back $pos] == $back] && ($c > 1)} {
		    set to $back
		    if {$back == "1.0"} {break}
		} else {
		    break
		}
	    }
	    return $to
	}
    }
} else {
    proc tw::backward_word {w pos} {
	set bk [splitreadvar $w wordbreak]

	set to [singlesearch $w -backwards -regexp -- $bk "$pos -1c" 1.0]
	if {$to == ""} {
	    return 1.0
	} else {
	    return $to
	}
    }
}

proc tw::forward_word {w pos} {
    set bk [splitreadvar $w wordbreak]
    set to [singlesearch $w -forwards -regexp -count c -- $bk $pos]
    if {$to == ""} {
	return end
    } else {
	return "$to +${c}c"
    }
}

proc tw::current_word {w cur} {
    set end [forward_word $w "$cur -1c"]
    set start [backward_word $w "$cur +1c"]
    return [list $start $end]
}

proc tw::double_click {w x y} {
    set cur [tk::TextClosestGap $w $x $y]
    set char [$w get $cur]
    if {[regexp -- "\[\]\[\{\(\)\}\"\]" $char]} {
	if {$char == "\""} {
	    if {[catch {matchQuoteBack $w "$cur -1c" "$cur -10l"} back]} {
		set back ""
	    }
	    if {[catch {matchQuoteForward $w "$cur +1c" "$cur +10l"} forw]} {
		set forw ""
	    }
	    if {$back == "" && $forw == ""} {
		CallHook message "No matching quote"
		return
	    }
	    if {$back == ""} {
		set start $cur
		set end $forw
	    } elseif {$forw == ""} {
		set start $back
		set end $cur
	    } else {
		# Need to find the closest
		foreach {backl backc} [::split [$w index $back] .] {}
		foreach {forwl forwc} [::split [$w index $forw] .] {}
		foreach {curl curc} [::split [$w index $cur] .] {}
		set fcl [expr {$forwl - $curl}]
		set bcl [expr {$curl - $backl}]
		if {$fcl < $bcl} {
		    set start $cur
		    set end $forw
		} elseif {$fcl > $bcl} {
		    set start $back
		    set end "$cur +1c"
		} else {
		    set fcc [expr {$forwc - $curc}]
		    set bcc [expr {$curc - $backc}]
		    if {$fcc < $bcc} {
			set start $cur
			set end $forw
		    } else {
			set start $back
			set end "$cur +1c"
		    }
		}
	    }
	} elseif {[regexp -- "\[\[\{\(\]" $char]} {
	    # open bracket of some kind
	    set end [match $w $char "$cur +1c"]
	    set start "$cur + 1c"
	} else {
	    # close bracket of some kind
	    set start "[match $w $char "$cur -1c"] +1c"
	    set end $cur
	}
    } else {
	foreach {start end} [current_word $w $cur] {}
    }
    select $w $start $end
    mark $w set insert $start
}

# ×××× Binding captures ×××× #

proc tw::binding_capture {w bt} {
    set ww [_firstSplitWindow $w]
    variable $ww
    if {[info exists ${ww}(_storebindtags)]} {
	error "Already got binding capture!"
    } else {
	set ${ww}(_storebindtags) [::bindtags $ww]
	_commandOnAllSplits $ww ::bindtags [list "BindReset $bt BindNoMatch"]
	bind BindReset <Key> [list tw::binding_reset $ww]
    }
}

bind BindNoMatch <Key> \
  [list ::tw::CallHook message "No matching prefixed binding."]

proc tw::binding_reset {w} {
    set ww [_firstSplitWindow $w]
    variable $ww
    CallHook message ""
    if {[info exists ${ww}(_storebindtags)]} {
	_commandOnAllSplits $ww ::bindtags [list [set ${ww}(_storebindtags)]]
	unset ${ww}(_storebindtags)
    } else {
	error "No previous binding capture!"
    }
}

# ×××× Window manager related ×××× #

proc tw::takeFocus {w} {
    #puts "taking focus $w"
    set oldFocus [focus]
    set newFocus [getSplitFocus $w]
    if {$oldFocus eq $newFocus} {
	return
    }
    focus $newFocus
    variable window_activate
    if {[lsearch -exact $window_activate $w] == -1} {
	lappend window_activate $w
    }
}

proc tw::activateHook {ww} {
    #puts "activate $ww"
    if {1} {
	variable window_activating
	variable window_activate
	
	if {[llength $window_activate]} {
	    if {[set idx [lsearch -exact $window_activate $ww]] == -1} {
		return
	    }
	    set window_activate [lreplace $window_activate $idx $idx]
	}
	
	if {$window_activating} {
	    return 
	}
	
	set window_activating 1
    }

    variable split
    if {[info exists split($ww)]} {
	variable split_focus
	set original $split($ww)
	set split_focus($original) $ww
    }
    set base [base_window $ww]
    # This might destroy the window
    CallHook activate $base
    if {[winfo exists $ww]} {
	CallHook position $base [::split [index $ww insert] .]
    }
    set window_activating 0
}

proc tw::deactivateHook {ww} {
    variable $ww
    if {[info exists ${ww}(_storebindtags)]} {
	tw::binding_reset $ww
    }
    CallHook deactivate [base_window $ww]
}

# return list of first and last viewable positions
proc tw::_viewable {w} {
    variable $w
    set first [expr {int([$w index @0,0])}]
    set last [expr {int([$w index "@[winfo width $w],[winfo height $w]"])}]
    # Set this array element and return the result
    set ${w}(viewable) [list $first $last]
}

proc tw::windowConfigure {w width height} {
    #puts "config $w $width $height"
    variable $w
    if {![info exists ${w}(viewable)]} {
	_viewable $w
	return
    }
    set old [set ${w}(viewable)]
    if {[$w cget -wrap] != "none"} {
	_updateMargin $w
    }
    # now recolour as appropriate
    eval [list arrangeToColourNewlyRevealed $w] $old
}


proc tw::ReplaceBindTags {w fromlist tolist} {
    set oldtags [bindtags $w]

    set idx 0
    foreach old $fromlist {
	set idx [lsearch -exact $oldtags $old]
	set oldtags [lreplace $oldtags $idx $idx]
    }
    set newtags [eval [list linsert $oldtags $idx] $tolist]
    _commandOnAllSplits $w bindtags [list $newtags]
}

# ×××× Undo/Redo/Save ×××× #

proc tw::save {w} {
    variable undo
    variable redo
    variable $w
    if {[set ${w}(dirty)] != 0} {
	set ${w}(dirty) 0
	CallHook dirty $w 0
    }
    [winfo parent $w].rt.dirty configure -image clean \
      -background [default::color background]
    if {[info exists ${w}(undo)]} {
	unset ${w}(undo)
    }
    if {[info exists ${w}(redo)]} {
	unset ${w}(redo)
    }
}

proc tw::read_only {w {d 1}} {
    set w [base_window $w]
    variable $w
    # If there's no change
    if {[set ${w}(read-only)] == $d} {return}

    if {$d} {
	tw::dirty $w 0
	$w configure -state disabled
	[winfo parent $w].rt.dirty configure -image lock
    } else {
	$w configure -state normal
	[winfo parent $w].rt.dirty configure -image clean
    }
    set ${w}(read-only) $d
}

proc tw::dirty {w {d 1}} {
    set w [base_window $w]
    variable $w
    if {[info exists ${w}(shell)]} {
	return
    }
    if {[set ${w}(dirty)] != $d} {
	set ${w}(dirty) $d
	CallHook dirty $w $d
    }
    if {$d == 0} {
	if {[info exists ${w}(undo)]} {
	    unset ${w}(undo)
	}
	# This prevents a redo after an 'undo makes window unmodified'
	# so we remove it for the moment
	#if {[info exists ${w}(redo)]} {unset ${w}(redo)}
    }
    
    if {[$w cget -state] == "disabled"} {
	# it's a read-only window
	if {![dialog::yesno -y "Continue" -n "Throw error" \
	  "Modified a read-only window!"]} {
	    return -code error "Modified a read-only window!"
	}
    }
    
    [winfo parent $w].rt.dirty configure -image [expr {$d ? "dirty" : "clean"}]
}

proc tw::undo {w {allcontiguous 1}} {
    variable $w
    if {![info exists ${w}(undo)]} {
	return
    }
    set first 1
    while 1 {
	set action [lindex [set ${w}(undo)] end]
	if {$action == ""} {break}
	switch -- [lindex $action 0] {
	    "insert" {
		set len [string length [join [lrange $action 2 end] ""]]
		set where [lindex $action 1]
		if {!$first} {
		    if {[compare $w $where != $new_pos]} {
			break
		    }	    
		}
	    }
	    "delete" {
		set len [string length [join [lrange $action 3 end] ""]]
		set where [lindex $action 1]
		if {!$first} {
		    if {[compare $w $where != "$new_pos + ${len}c"]} {
			break
		    }	    
		}
	    }
	    "replace" {
		set len [string length [lindex $action 4]]
		set where [lindex $action 1]
		if {!$first} {
		    break
		}
	    }
	}
	# perform action
	# adjust the undo/redo lists
	lappend ${w}(redo) $action
	set ${w}(undo) [lrange [set ${w}(undo)] 0 [expr {[llength [set ${w}(undo)]] -2}]]
	
	switch -- [lindex $action 0] {
	    "insert" {
		if {$len > 1} {
		    uplevel 1 [list ::tw::silent_delete $w $where [list $where +${len}c]]
		} else {
		    uplevel 1 [list ::tw::silent_delete $w $where]
		}
		set new_pos [index $w "$where - 1c"]
		set goto_pos "$new_pos +1c"
	    }
	    "delete" {
		uplevel 1 [list ::tw::silent_insert $w $where [lindex $action 3]]
		set new_pos $where
		set goto_pos "$new_pos + [string length [lindex $action 3]]c"
	    }
	    "replace" {
		uplevel 1 [list ::tw::silent_replace $w $where \
		  [list $where +${len}c] [lindex $action 3]]
		set new_pos $where
		#set goto_pos "$new_pos + [string length [lindex $action 3]]c"
		break
	    }
	}
	if {!$allcontiguous} {
	    break
	}
	set first 0
    }
    
    # undirty if necessary
    if {[llength [set ${w}(undo)]] == 0} { 
	unset ${w}(undo)
	dirty $w 0
    }
    if {[info exists new_pos]} {
	if {[info exists goto_pos]} {
	    # Move insertion (and view) to the correct position.
	    goto $w $goto_pos
	} else {
	    # Move insertion (and view) to the correct position.
	    see $w $new_pos
	}
    }
}

proc tw::redo {w {allcontiguous 1}} {
    variable $w
    if {![info exists ${w}(redo)]} {
	return
    }
    if {![info exists ${w}(undo)]} {
	dirty $w 1
    }
    set first 1
    while 1 {
	set action [lindex [set ${w}(redo)] end]
	if {$action == ""} {break}
	switch -- [lindex $action 0] {
	    "insert" {
		set len [string length [join [lrange $action 2 end] ""]]
		set where [lindex $action 1]
		if {!$first} {
		    if {[compare $w $where != $new_pos]} {
			break
		    }	    
		}
	    }
	    "delete" {
		set len [string length [join [lrange $action 3 end] ""]]
		set where [lindex $action 1]
		if {!$first} {
		    if {[compare $w "$where +${len}c" != $new_pos]} {
			break
		    }	    
		}
	    }
	    "replace" {
		set len [string length [lindex $action 3]]
		set where [lindex $action 1]
		if {!$first} {
		    break
		}
	    }
	}
	# perform action
	# adjust the undo/redo lists
	lappend ${w}(undo) $action
	set ${w}(redo) [lrange [set ${w}(redo)] 0 [expr {[llength [set ${w}(redo)]] -2}]]
	
	switch -- [lindex $action 0] {
	    "delete" {
		if {$len > 1} {
		    uplevel 1 [list ::tw::silent_delete $w $where [list $where +${len}c]]
		} else {
		    uplevel 1 ::tw::silent_delete $w $where
		}
		set new_pos $where
		set goto_pos $new_pos
	    }
	    "insert" {
		uplevel 1 [list ::tw::silent_insert $w $where [lindex $action 2]]
		set new_pos [index $w "$where + ${len}c"]
		set goto_pos $new_pos
	    }
	    "replace" {
		uplevel 1 [list ::tw::silent_replace $w $where \
		  [lindex $action 2] [lindex $action 4]]
		set new_pos [index $w "$where + [string length [lindex $action 4]]c"]
		break
	    }
	}
	if {!$allcontiguous} {
	    break
	}
	set first 0
    }
    # undirty if necessary
    if {[llength [set ${w}(redo)]] == 0} { 
	unset ${w}(redo)
    }
    if {[info exists new_pos]} {
	if {[info exists goto_pos]} {
	    goto $w $goto_pos
	} else {
	    see $w $new_pos
	}
    }
}


# ×××× Miscellaneous ×××× #

# Central location for creating and destroying the horizontal scrollbar.
# We currently only allow one horizontal scrollbar for the main window,
# and split sub-windows are therefore not allowed one.
proc tw::horizScrollbar {w {toggle 1}} {
    set w [base_window $w]
    
    variable $w

    set wh [tw::_textTo $w hscroll]
    
    if {$toggle} {
	if {[info exists ${w}(horizScrollbar)]} {
	    set ${w}(horizScrollbar) [expr {1- [set ${w}(horizScrollbar)]}]
	} else {
	    set ${w}(horizScrollbar) 0
	}
    }
    
    if {[set ${w}(horizScrollbar)]} {
	scrollbar $wh -command [list ::tw::direct_xview $w] -orient horizontal
	grid $wh -sticky sew -column 0 -row 3 -columnspan 2
	$w configure -xscrollcommand "$wh set"
	grid configure $w -rowspan 3
    } else {
	if {[winfo exists $wh]} {
	    destroy $wh
	    $w configure -xscrollcommand ""
	}
	grid configure $w -rowspan 4
    }
}


# this needs work, perhaps
proc tw::select {w args} {
    set tag "sel"
    if {[llength $args]} {
	eval [list tag $w add $tag] $args
    } else {
	return [tag $w ranges $tag]
    }
}


proc tw::statusConfigure {w what args} {
    variable $w
    switch -- $what {
	"image" {
	    if {[llength $args]} {
		return [eval [list [winfo parent $w].rt.dirty configure -image] $args]
	    } else {
		return [eval [list [winfo parent $w].rt.dirty cget -image] $args]
	    }
	}
	"background" {
	    if {[llength $args]} {
		return [eval [list [winfo parent $w].rt.dirty configure -background] $args]
	    } else {
		return [eval [list [winfo parent $w].rt.dirty cget -background] $args]
	    }
	}
	default {
	    return -code error "bad option $what"
	}
    }
}

proc tw::lockClick {w {ctrl 0}} {
    set w [base_window $w]
    variable $w
    if {[info exists ${w}(shell)]} {
	CallHook message "Clicking doesn't affect shell windows."
	return
    }
    switch -- [[winfo parent $w].rt.dirty cget -image] {
	"lock" {
	    if {!$ctrl} {return}
	    if {[set ${w}(dirty)]} {
		CallHook message "Clicking only affects locked or clean windows."
		return
	    }
	    CallHook lock $w 1
	}
	"" - 
	"clean" {
	    if {!$ctrl} {return}
	    if {[set ${w}(dirty)]} {
		CallHook message \
		  "Clicking only affects locked or clean windows."
		return
	    }
	    CallHook lock $w 0
	}
	"dirty" {
	    CallHook save $w
	}
	default {
	    error "Clicked on unknown image"
	}
    }
}

proc tw::_slowReadVar {w var} {
    variable $w
    variable split

    if {[string range $w 0 5] eq "::tw::"} {
	set w [string range $w 6 end]
    }
    if {[info exists split($w)]} {
	set ww $split($w)
	variable $ww
	set ${ww}($var)
    } else {
	set ${w}($var)
    }
}

proc tw::setvar {w var val} {
    variable $w
    set ${w}($var) $val
}

proc tw::readvar {w var} {
    variable $w
    set ${w}($var)
}

proc tw::splitreadvar {w var} {
    variable split
    if {[info exists split($w)]} {
	set ww $split($w)
	variable $ww
	set ${ww}($var)
    } else {
	variable $w
	set ${w}($var)
    }
}

proc tw::goto {w where} {
    set range [$w tag ranges sel]
    if {$range != ""} {
	eval $w tag remove sel $range
    }
    mark $w set insert $where
    see $w insert
}

# This can be used internally where we know we only want to
# look at a single line.  For example the forward/backward
# word functionality (also used by syntax colouring) uses
# this.  It's obviously significantly faster, and is therefore
# useful when we need to call a proc hundreds or thousands of
# times very quickly (as with syntax colouring).
proc tw::singlesearch {w args} {
    #puts stderr "$w search $args"
    uplevel 1 tw::[getSplitFocus $w] search $args
}

proc tw::highlight {w pattern} {
    set ww [getSplitFocus $w]
    # Should return (almost) immediately, but schedule events to ensure
    # all strings matching 'pattern' are highlighted in the window.
    # 
    # If 'pattern' is the empty string, then remove all highlighting.
    set range [$ww tag ranges highlight]
    if {[llength $range]} {
	eval [list $ww tag remove highlight] $range
    }
    variable $w
    if {[info exists ${w}(highlightEvent)]} {
	after cancel [set ${w}(highlightEvent)]
    }
    if {$pattern != ""} {
	eval [list $ww tag add highlight] [select $ww]
	set ${w}(highlightEvent) \
	  [after idle [list ::tw::_highlightEvent $w $pattern]]
    }
}

proc tw::_highlightEvent {w pattern {limits ""}} {
    variable $w

    set ww [getSplitFocus $w]
    if {![llength $limits]} {
	set limits [list [index $ww @0,0] \
	  [index $ww "@[winfo width $ww],[winfo height $ww]"]]
    }
    set found [eval [list search $ww -nocase -count ::tw::c -- $pattern] $limits]
    if {[llength $found]} {
	set endFound "$found + ${::tw::c}c"
	$ww tag add highlight $found $endFound
	set ${w}(highlightEvent) \
	  [after idle [list ::tw::_highlightEvent $w $pattern \
	  [list $endFound [lindex $limits 1]]]]
    }
}



# Set to 0 to run pkg_mkIndex
if {1} {
    
# Over-ride some bindings.
bind AlphaStyle <Configure> {tw::windowConfigure "%W" %w %h} 
bind AlphaStyle <FocusIn> {::tw::activateHook %W} 
bind AlphaStyle <FocusOut> {::tw::deactivateHook %W} 
bind AlphaStyle <Double-Button-1> {
    set tk::Priv(selectMode) word
    ::tw::double_click %W %x %y
    break
}
bind Alpha <KeyPress> "::tw::keypressed %W %A ; break"
if {[tk windowingsystem] eq "classic" \
  || [tk windowingsystem] eq "aqua"} {
    bind AlphaStyle <Option-B1-Motion> \
      "tw::TextRectSelectTo %W %x %y ; break" 
} else {
    bind AlphaStyle <[lindex $alpha::modifier_keys 0]-B1-Motion> \
      "tw::TextRectSelectTo %W %x %y ; break" 
}
bind Alpha <Key-bracketright> "flash {\]} ; [bind Alpha <KeyPress>]"
bind Alpha <Key-parenright> "flash {\)} ; [bind Alpha <KeyPress>]"

bind Lock <[lindex $alpha::modifier_keys 0]-Button-1> \
  "tw::_getFocusWidget \[winfo parent \[winfo parent %W\]\] lockClick 1"
bind Lock <Button-1> \
  "tw::_getFocusWidget \[winfo parent \[winfo parent %W\]\] lockClick 0"
bind Margin <Double-Button-1> \
  "tw::_getFocusWidget \[winfo parent %W\] marginClick %W %x %y"
}

proc tw::setFont {w v} {
    variable $w
    
    _commandOnAllSplits $w "" [list configure -font $v]

    # May need to re-adjust the tabs
    setTabs $w
    
    return $v
}

proc tw::setTabs {w {v ""}} {
    variable $w
    if {$v == ""} {
	set v [set ${w}(tabsize)]
    } else {
	set ${w}(tabsize) $v
    }
    if {$v == 8} {
	_commandOnAllSplits $w "" [list configure -tabs ""]
    } else {
	set charWidth [font measure [$w cget -font] "a"]
	lappend tabOpts [expr {$v * $charWidth}] left
	_commandOnAllSplits $w "" \
	  [list configure -tabs $tabOpts]
    }
    return $v
}

proc tw::encoding {w args} {
    variable $w
    switch -- [llength $args] {
	0 {
	    set ${w}(encoding)
	}
	1 {
	    set val [lindex $args 0]
	    set ${w}(encoding) $val
	}
	default {
	    error "Wrong number of args"
	}
    }
}

proc tw::platform {w args} {
    variable $w
    switch -- [llength $args] {
	0 {
	    set ${w}(platform)
	}
	1 {
	    set val [lindex $args 0]
	    set ${w}(platform) $val
	}
	default {
	    error "Wrong number of args"
	}
    }
}

proc tw::fold {w action args} {
    if {$action eq "info"} {
	switch -- [llength $args] {
	    0 {
		return [$w tag ranges elidden]
	    }
	    1 {
		set pos [lindex $args 0]
		set range [$w tag prevrange elidden $pos]
		if {![llength $range]} { 
		    set range [$w tag nextrange elidden $pos "$pos +1c"]
		    if {![llength $range]} { 
			return
		    }
		}
		if {[compare $w [lindex $range 1] < $pos]} {
		    return ""
		}
		return $range
	    }
	    2 {
		foreach {from to} $args {}
		set res [list]
		foreach {l_from l_to} [$w tag ranges elidden] {
		    if {[$w compare $l_to < $from]} {
			continue
		    }
		    if {[$w compare $l_from > $to]} {
			break
		    }
		    lappend res $l_from $l_to
		}
		return $res
	    }
	    default {
		return -code error "Wrong num args"
	    }
	}
    } elseif {$action eq "hide"} {
	if {![llength $args] || ([llength $args] % 2)} {
	    return -code error "Wrong num args"
	}
	foreach {bs be} $args {
	    set bs [index $w $bs]
	    set be [index $w $be]
	    $w tag add elidden $bs $be
	    set wm [_textTo $w margin]
	    if {[winfo exists $wm]} {
		#puts "folding margin $bs $be"
		::$wm tag add elidden $bs $be
	    }
	    set line [lindex [::split $bs .] 0]
	    setMarginItem $w 1 $line "fold" collapser
	}
	return $line
    } elseif {$action eq "show"} {
	if {![llength $args] || ([llength $args] % 2)} {
	    return -code error "Wrong num args"
	}
	foreach {bs be} $args {
	    $w tag remove elidden $bs $be
	    set wm [_textTo $w margin]
	    if {[winfo exists $wm]} {
		::$wm tag remove elidden $bs $be
	    }
	    set line [lindex [::split $bs .] 0]
	    setMarginItem $w 1 $line $line
	}
	return $line
    } else {
	return -code error "Wrong action \"$action\" should be\
	  hide, info or show."
    }
}


proc tw::TextRectSelectTo {w x y} {
    # Find closest index position to 'x,y'
    set pos [$w index @$x,$y]
    set bbox [$w bbox $pos]
    #puts "$x, $y, $bbox"
    if {[string equal $bbox ""]} {
	set cur $pos
    } elseif {$x >= [lindex $bbox 0]} {
	if {($x - [lindex $bbox 0]) < ([lindex $bbox 2]/2)} {
	    set cur $pos
	    set x [lindex $bbox 0]
	} elseif {$x < ([lindex $bbox 0] + [lindex $bbox 2])} {
	    set cur $pos
	    set x [expr {[lindex $bbox 0] + [lindex $bbox 2]}]
	} else {
	    set cur $pos
	    set x [expr {[lindex $bbox 0] + [lindex $bbox 2]}]
	}
    } else {
	set cur [$w index "$pos + 1 char"]
    }
    #puts "at $x, $y, $pos, $cur, $bbox"
    # Now work out whether the position has changed.
    if {[catch {$w index anchor}]} {
	$w mark set anchor $cur
    }
    if {[$w compare $cur == anchor]} {
	return
    }

    # The bounds of the rect are '$cur' and 'anchor'
    set xx [lindex [$w bbox anchor] 0]
    set l0 [lindex [::split [$w index anchor] .] 0]
    set l1 [lindex [::split [$w index $cur] .] 0]
    
    # Remove the old selection, and create a new one
    $w tag remove sel 0.0 end
    $w mark set insert $cur
    if {$xx < $x} {
	set tmp $x
	set x $xx
	set xx $tmp
	unset tmp
    }
    if {$l1 < $l0} {
	set tmp $l0
	set l0 $l1
	set l1 $tmp
	unset tmp
    }
    
    if {$x ne ""} {
	for {set l $l0} {$l <= $l1} {incr l} {
	    set y [lindex [$w bbox "${l}.0"] 1]
	    if {$y != ""} {
		set from [$w index @$x,$y]
		set to [$w index @$xx,$y]
		if {$from ne $to} {
		    lappend sel $from $to
		}
	    }
	}
    }
    if {[info exists sel]} {
	eval [list $w tag add sel] $sel
	update idletasks
    }
}

proc tw::keypressed {w char} {
    if {[winfo class $w] == "Text"} {
	::tk::TextInsert $w $char
	if {$char != ""} {
	    CallHook charInsertDelete $w insert $char
	}
    }
}

proc tw::delete_key {w pos} {
    delete $w $pos
    CallHook charInsertDelete $w $pos
}

# ×××× Drag and drop ×××× #

# Takes values 0=no drag,1=drag initialize,2=drag in progress
# (it'll always be zero if we don't have drag and drop)
namespace eval tk {}
set ::tk::Priv(drag) 0

# This line is actually for both drag and drop and hypertext clicking
bind AlphaStyle <Button-1> \
  "if {\$::tk::Priv(drag) || \[%W hyperClick alreadyClicked %x %y\]}\
  break; [bind AlphaStyle <Button-1>]"

if {![info exists alpha::haveDnd] || !$alpha::haveDnd} { return }

bind AlphaStyle <B1-Motion> {
    if {!$::tk::Priv(drag)} {
	set tk::Priv(x) %x
	set tk::Priv(y) %y
	tk::TextSelectTo %W %x %y
    }
}

bind AlphaStyle <B1-Leave> {
    if {!$::tk::Priv(drag)} {
	set tk::Priv(x) %x
	set tk::Priv(y) %y
	tk::TextAutoScan %W
    }
}

bind AlphaStyle <ButtonRelease-1> {
    if {$::tk::Priv(drag)} {
	set ::tk::Priv(drag) 0
	set ::tk::Priv(dragWindow) ""
	tk::TextButton1 %W %x %y
	%W tag remove sel 0.0 end
    }
    #puts stderr "button-up"
    tk::CancelRepeat
}

proc tw::BindDragDrop {win} {
    # Bind text/plain as drag source and drop target
    foreach {type p} [list "text/plain" 50] {
	dnd bindsource $win $type \
	  [list tk::DragSource %A %a %T %W %X %Y %x %y %D] $p
    }
    # Instigate drag on selection, with change in cursor as well
    $win tag bind sel <Button-1> "tk::DragTextInit %W %x %y ; break"
    $win tag bind sel <B1-Motion> "tk::DragTextStart %W %x %y"
    $win tag bind sel <Enter> [list %W configure -cursor arrow]
    $win tag bind sel <Leave> [list %W configure -cursor xterm]
    
    # Also allow dropping of files onto windows
    foreach {type p} [list text/plain 20 FILENAME 30 text/uri-list 50] {
	dnd bindtarget $win $type <DragEnter> \
	  [list tw::DndItem %W "enter" %T %x %y %A %a %m %D] $p
	dnd bindtarget $win $type <Drag>      \
	  [list tw::DndItem %W "drag" %T %x %y %A %a %m %D] $p
	dnd bindtarget $win $type <DragLeave> \
	  [list tw::DndItem %W "leave" %T %x %y %A %a %m %D] $p
	dnd bindtarget $win $type <Drop>      \
	  [list tw::DndItem %W "drop" %T %x %y %A %a %m %D] $p
    }
}

proc tw::DndItem {w state type x y A actions modifiers {data {}} args} {
    #if {[llength $actions] > 1} { puts $actions }
    if {$type == "FILENAME"} {
	set data [list $data]
	set type "text/uri-list"
    }
    set idx [_ClosestGap $w $x $y]

    set attr(data) $data
    set attr(actions) $actions
    set attr(action) $A
    set attr(pos) $idx
    set attr(x) $x
    set attr(y) $y
    set attr(type) $type
    set attr(modifiers) $modifiers
    
    if {[$w cget -state] == "disabled"} {
	tw::CallHook message "Can't drop into this\
	  window - it is read-only"
	return "none"
    }

    if {$state eq "leave" || $state eq "drop"} {
	_DropTextDeleteWindow $w 
    }
    
    if {[info exists ::tk::Priv(dragWindow)]} {
	set sourcewin $::tk::Priv(dragWindow)
	if {$sourcewin != ""} {
	    # Any Alphatk window we use 'move' by default
	    set attr(action) "move"
	}
    }
    
    if {[lsearch -exact $attr(modifiers) "Control"] != -1} {
	set attr(action) "copy"
    }

    set do [tw::CallHook dragndrop $w $state [array get attr]]
    if {$state eq "leave"} {
	return "none"
    }
    if {[lsearch -exact $actions $do] == -1} {
	bgerror "Bad dragndrop action '$do' - should be one of [join $actions ,]"
	set do "none"
    }
    if {$do != "none"} {
	switch -- $state {
	    "enter" {
		_DropTextDeleteWindow $w 
	    }
	    "drag" {
		if {![string equal [lindex [$w dump -window @$x,$y] 1] "$w.dnd"] \
		  && ![string equal [lindex [$w dump -window $idx] 1] "$w.dnd"]} {
		    _DropTextMakeWindow $w $idx
		}
	    }
	}
    }
    return $do
}

# For dropping into windows

proc tw::_DropTextMakeWindow {w idx} {
    variable split
    
    catch {silent_delete $w $w.dnd}

    if {[info exists split($w)]} {
	variable splitter
	set wlist $splitter([set split($w)])
    } else {
        set wlist [list $w]
    }
    $w window create $idx -create \
      [list frame %W.dnd -width 3 -height 8 -bg black] \
      -align center -stretch 1
    foreach ww $wlist {
	_updateMargin $ww
    }
}

proc tw::_DropTextDeleteWindow {w} {
    variable split

    catch {silent_delete $w $w.dnd}

    if {[info exists split($w)]} {
	variable splitter
	set wlist $splitter([set split($w)])
    } else {
	set wlist [list $w]
    }
    foreach ww $wlist {
	destroy $ww.dnd
	_updateMargin $ww
    }
}

proc tw::_ClosestGap {w x y} {
    set pos [$w index @$x,$y]
    set bbox [$w bbox $pos]
    if {[string equal $bbox ""]} {
	return $pos
    }
    if {($x - [lindex $bbox 0]) < ([lindex $bbox 2]/2)} {
	return $pos
    }
    $w index "$pos + 1 char"
}


# For dragging from windows

proc tk::DragTextInit {w x y} {
    #puts stderr "drag init"
    set ::tk::Priv(drag) 1
}

proc tk::DragTextStart {w x y} {
    # Ensure window still exists.
    if {$::tk::Priv(drag) == 1} {
	set ::tk::Priv(drag) 2
	set ::tk::Priv(dragWindow) $w
	set idx @$x,$y
	#puts stderr "drag start $w $idx"
	
	# Apply 'drag' tag to the given range.  We need to do this
	# rather than just remember a character range in case the
	# drag is within the same window.
	$w tag delete drag
	eval [list $w tag add drag] [$w tag ranges sel]
	# Perform the drag and drop (this won't return until it's over)
	set dragres [dnd drag $w -actions [list copy move]]
	# If it was a 'move' then delete the text.
	if {$dragres == "move"} {
	    set range [$w tag ranges drag]
	    eval [list $w delete] $range
	}
	set ::tk::Priv(dragWindow) ""
    }
}

proc tk::DragSource {action actions type win X Y x y args} {
    #puts "drag succeeded $win $args"
    set cursorIn [winfo containing $X $Y]
    if {$cursorIn == $win} {
	# We don't allow a drop onto the actual source of
	# the drag itself
	set idx @$x,$y
	set range [$win tag prevrange sel $idx]
	if {[llength $range]} {
	    if {[$win compare [lindex $range 1] > $idx]} {
		#tw::CallHook message "No drop"
		return ""
	    }
	}
    }
    set range [$win tag ranges sel]
    if {[llength $range] > 2} {
	set txt [join [eval [list $win get] $range] \n]
    } else {
	set txt [eval [list $win get] $range]
    }
    return $txt
}
