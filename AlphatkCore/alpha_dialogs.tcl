## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_dialogs.tcl"
 #                                    created: 04/11/98 {17:32:52 PM} 
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 1998-2005  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##

# ×××× Dialogs ×××× #

# Make sure we get the version of BWidgets we have with us
# at the least
catch {package require alphatk_foo}
proc alpha::ensureBWidgetLoaded {{cmd ""}} {
    namespace eval :: {
	if {[catch {::package require BWidget ; ::Widget::theme 1}]} {
	    catch {eval [::package ifneeded BWidget [::package present BWidget]]}
	    catch {::package require BWidget}
	    catch {::Widget::theme 1}
	}
    }
    catch {::auto_load ::$cmd}
    if {($cmd ne "") && ([info commands ::$cmd] eq "")} {
	namespace eval :: {
	    catch {eval [::package ifneeded BWidget [::package present BWidget]]}
	    catch {::package require BWidget}
	    catch {::Widget::theme 1}
	}
	catch {::auto_load ::$cmd}
    }
}
alpha::ensureBWidgetLoaded

#¥ alertnote message_string
#  This command will display message_string in a standard Macintosh alert box.
proc alertnote {args} {
    set msg [lindex $args 0]
    if {[llength $args] > 1} {
	append msg "\r\r[join [lrange $args 1 end] { }]"
    }
    alpha::externalDialog tk_messageBox -message $msg -icon info
    update
}
#¥ colorTriple [<prompt>] [<red> <green> <blue>] - Prompts user to choose 
#  color. If specified, the input RGB value is used as the initial color on 
#  the colorpicker.
proc colorTriple {{prompt ""} args} {
    if {[llength $args] == 0} {
	set init 000
    } elseif {[llength $args] == 3} {
	foreach c $args {
	    set c1 [format %1X [expr {$c / 256}]]
	    if {[string length $c1] == 1} {set c1 "0$c1"}
	    append init $c1
	}
    } else {
	error "Bad args to colorTriple"
    }
    if {$prompt != ""} {
	set res [alpha::externalDialog \
	  tk_chooseColor -title $prompt -initialcolor "#${init}"]
    } else {
	set res [alpha::externalDialog \
	  tk_chooseColor -initialcolor "#${init}"]
    }
    if {$res == ""} { error "Cancelled" }
    foreach c [split [string range $res 1 end] ""] {
	lappend numbers [format %1d 0x$c]
    }
    set red [expr {[lindex $numbers 0] * 4096 + [lindex $numbers 1] * 256}]
    set green [expr {[lindex $numbers 2] * 4096 + [lindex $numbers 3] * 256}]
    set blue [expr {[lindex $numbers 4] * 4096 + [lindex $numbers 5] * 256}]
    return [list $red $green $blue]
}

#¥ findFile [<path>] - open a file in a new window. An optional path 
#  parameter specifies a default directory or file.
proc findFile {{default ""}} {
    if {$default == ""} { set default [file dirname [win::Current]]}
    if {[file isdirectory $default]} {
	edit [alpha::externalDialog \
	  tk_getOpenFile -initialdir $default -filetypes [findFileTypes]]
    } else {
	edit [alpha::externalDialog \
	  tk_getOpenFile -initialfile $default -filetypes [findFileTypes]]
    }
}
#¥ getfile [<prompt>] [<path>]
#  This command will display an SFGetFile() and return the full path name
#  of the selected file, or an error if CANCEL button was selected.  An
#  optional path parameter specifies a default directory or file.
proc getfile {args} {
    set opts(-types) ""
    getOpts [list -types]
    set title "Find file"
    set default ""
    if {[llength $args]} {
	set title [lindex $args 0]
	if {[llength $args] > 1} {
	    set default [lindex $args 1]
	    if {[llength $args] > 2} {
		return -code error "Too many arguments"
	    }
	}
    }
    if {$default == ""} { set default [file dirname [win::Current]]}
    if {[file isdirectory $default]} {
	set res [alpha::externalDialog \
	  tk_getOpenFile -title $title -initialdir $default \
	  -filetypes [findFileTypes $opts(-types)]]
    } elseif {[file isfile $default]} {
	set res [alpha::externalDialog \
	  tk_getOpenFile -title $title -initialfile $default \
	  -filetypes [findFileTypes $opts(-types)]]
    } else {
	set res [alpha::externalDialog \
	  tk_getOpenFile -title $title \
	  -filetypes [findFileTypes $opts(-types)]]
    }
    if {$res == ""} {
	error "Cancelled"
    } else {
	return $res
    }
}

proc findFileTypes {{useThesePatterns ""}} {
    global tcl_platform
    if {[llength $useThesePatterns]} {
	set notExt 0
	foreach pat $useThesePatterns {
	    if {[string length $pat] == 4 && [string first . $pat] == -1} {
		# it's not an extension
		set notExt 1
		break
	    }
	}
	if {$notExt} {
	    if {[tk windowingsystem] == "classic" \
	      || [tk windowingsystem] == "aqua"} {
		set pats {}
		foreach pat $useThesePatterns {
		    # Workaround for Tk bug at present.
		    if {[string index $pat 0] ne "\0"} {
			lappend pats $pat
		    }
		}
		lappend filetypes [list "Allowed files" "" $pats]
	    } else {
		set filetypes ""
	    }
	} else {
	    lappend filetypes [list "Allowed files" $useThesePatterns]
	}
	return $filetypes
    } else {
	if {[tk windowingsystem] == "classic" \
	  || [tk windowingsystem] == "aqua"} {
	    return [list [list "All files" "*"] \
	      [list "Text files" "" "TEXT"] \
	      [list "Applications" "*.app" "APPL"]]
	} else {
	    if {$tcl_platform(platform) == "windows"} {
		lappend filetypes [list "All Files" "*.*"]
	    } else {
		lappend filetypes [list "All Files" "*"] \
		  [list "Invisible Files" ".*"]
	    }
	    global filepats
	    foreach m [lsort -dictionary [array names filepats]] {
		if {$filepats($m) != ""} {
		    lappend filetypes [list "$m files" $filepats($m)]
		}
	    }
	    return $filetypes
	}
    }
}

# ¥ getTextDimensions [options] <text> - returns the rectangular 
#     bounds of <text> in pixels. Bounds are returned as 
#     {left ascent right descent} around the (0,0) origin 
#     of the line of text. The font, size and display width can be
# 	specified with the following options (later options override 
# 	earlier ones). If not otherwise specified, the default font 
#     and size are used.
# 
# 	  -w <win>        Use the font and size of the specified window
# 	  -font <font>    Use the specified font (integer or name). 
# 			  Special Appearance Manager meta fonts (which
# 			  affect the font, size, and style) can be 
# 			  specified as one of
# 
# 				     0 or kThemeSystemFont
# 				    -1 or kThemeSmallSystemFont
# 				    -2 or kThemeSmallEmphasizedSystemFont
# 				    -3 or kThemeViewsFont
# 			The remaining ID's are only available in AlphaX
# 				    -4 or kThemeEmphasizedSystemFont
# 				    -5 or kThemeApplicationFont
# 				    -6 or kThemeLabelFont
# 					-7 or kThemeSystemFontDetail
# 					-8 or kThemeSystemFontDetailEmphasized
# 				  -100 or kThemeMenuTitleFont
# 				  -101 or kThemeMenuItemFont
# 				  -102 or kThemeMenuItemMarkFont
# 				  -103 or kThemeMenuItemCmdKeyFont
# 				  -104 or kThemeWindowTitleFont
# 				  -105 or kThemePushButtonFont
# 				  -106 or kThemeUtilityWindowTitleFont
# 				  -107 or kThemeAlertHeaderFont
# 			The remaining ID's are available in OS 10.2 or greater
# 				  -108 or kThemeToolbarFont
# 
#   -size <size>	  Point size (positive integer). Whether 
# 				  given earlier or later, if an Appearance 
# 				  Manager meta font is specified, this size
# 				  setting is ignored.
#   -width <width>  Measure the text in a box of specified width,
# 		    wrapped to as many lines as necessary.
# 		    If this option is missing or set to zero, the
# 		    bounds of the text as a single line is returned.
#   --			  End of tags
# 
#     This command introduced in 8.0b9. Not available on 68k. 
if {![winfo exists .getTextDimensions]} {
    label .getTextDimensions -padx 0 -pady 0 -bd 0 -highlightthickness 0 -anchor w
    rename .getTextDimensions alpha::__getTextDimensions
}
proc getTextDimensions {args} {
    getOpts {-w -font -size -width}
    if {[llength $args] != 1} {
	return -code error "Bad arguments 'getTextDimensions $args'"
    }
    set text [lindex $args 0]
    if {[info exists opts(-w)]} {
	#tile
	catch {set font [text_wcmd $opts(-w) cget -font]}
    }
    if {[info exists opts(-font)]} {
	set font $opts(-font)
	if {$font == -1 || $font == -2} {
	    switch -- [tk windowingsystem] {
		"win32" {
		    if {$::alpha::theming} {
			set font {Helvetica -12 bold}
		    } else {
			set font {{MS Sans Serif} 8}
		    }
		}
		"aqua" - default {
		    set font {system 11}
		}
	    }
	}
    }
    if {![info exists font]} {
	set font [text_cmd cget -font]
    }
    if {[info exists opts(-width)]} {
	set opts(-width) [distanceToScreen $opts(-width)]
	# multi-line case
	if {1} {
	    regsub -all "\r" $text "\n" text
	    alpha::__getTextDimensions configure -font $font \
	      -text $text -wraplength $opts(-width)
	    set x1 0
	    set x2 [winfo reqwidth .getTextDimensions]
	    set y1 [expr {-[font metrics $font -ascent]}]
	    set y2 [expr {$y1 + [winfo reqheight .getTextDimensions]}]
	} else {
	    set width 0
	    set lines 0
	    foreach t [split $text "\r\n"] {
		set ww [font measure $font $t]
		if {$ww > $opts(-width)} {
		    set width $opts(-width)
		    set fulllines [expr {$ww / $width}]
		    set rest [expr {$ww % $width}]
		    if {$rest > 0} {
			incr fulllines
		    }
		    incr lines $fulllines
		} else {
		    incr lines
		    if {$ww > $width} { 
			set width $ww 
		    }
		}
	    }
	    if {$lines == 0} { set lines 1 }
	}
    } else {
	# single line case
	set width [font measure $font $text]
	set lines 1
    }
    if {[info exists lines]} {
	set x1 0
	set x2 $width
	set y1 [expr {-[font metrics $font -ascent]}]
	set y2 [expr {$y1 + $lines * [font metrics $font -linespace]}]
    }
    return [screenToDistance $x1 $y1 $x2 $y2]
}
# ¥ getThemeMetrics <arr> - Fills <arr> with the sizes of the 
#     interface elements in the current environment. This command 
#     introduced in 8.0b9. 
proc getThemeMetrics {arr} {
    upvar 1 $arr Metrics
    
    switch -- [tk windowingsystem] {
	"win32" {
	    foreach {m val} {CheckBoxHeight 17 CheckBoxWidth 22 \
	      CheckBoxSpacingX 8  CheckBoxSpacingY 5 \
	      CheckBoxSeparationX 3  TightCheckBoxSpacingY 3 \
	      StaticTextSpacingX 8  StaticTextSpacingY 8 \
              PopupButtonHeight 16} {
		set Metrics($m) [screenToDistance $val]
	    }
	    if {$::alpha::theming} {
		foreach {m val} {CheckBoxHeight 19} {
		    set Metrics($m) [screenToDistance $val]
		}
	    }
	}
	"x11" {
	    array set Metrics {CheckBoxHeight 18  CheckBoxWidth 18 \
	      CheckBoxSpacingX 8  CheckBoxSpacingY 6 \
	      CheckBoxSeparationX 3  TightCheckBoxSpacingY 3 \
	      StaticTextSpacingX 8  StaticTextSpacingY 8 \
              PopupButtonHeight 16}
	}
	"aqua" - "classic" - default {
	    array set Metrics {CheckBoxHeight 18  CheckBoxWidth 18 \
	      CheckBoxSpacingX 8  CheckBoxSpacingY 6 \
	      CheckBoxSeparationX 3  TightCheckBoxSpacingY 3 \
	      StaticTextSpacingX 8  StaticTextSpacingY 8 \
              PopupButtonHeight 20}
	}
    }
}

#¥ getChar - waits for a keystroke, returns ascii.
proc getChar {{representation "key"}} {
    global alphaPriv
    global alpha::modifiers
    set oldFocus [dialog::getFocus $w]
    set oldGrab [dialog::getGrab .status 1]
    bind .status <KeyPress> {set alphaPriv(done) [list %A %K %N]}
    alpha::forceFocus .status

    while 1 {
	vwait alphaPriv(done)
	#echo $alphaPriv(done)
	regsub -all -- {_[LR]} \
	  [set keycode [lindex $alphaPriv(done) 1]] "" keycode
	append key "-" $keycode
	if {[lsearch -exact $alpha::modifiers $keycode] == -1} {
	    break
	}
    }
    set ascii [lindex $alphaPriv(done) 0]
    
    unset alphaPriv(done)
    bind .status <KeyPress> ""

    catch {grab release .status}
    dialog::restoreFocus $w $oldFocus
    dialog::releaseGrab $oldGrab
    regsub -all {_[LR]} $key "" key
    if {[string first "Shift" $key] == -1} {
	if {[regexp -- {[A-Z]$} $key last]} {
	    regsub -- {[A-Z]$} $key [string tolower $last] key
	}
    }
    set key [string range $key 1 end]
    foreach mod $alpha::modifiers {
	regsub -all -- "(-$mod)+" $key "-$mod" key
    }
    switch -- $representation {
	"key" {
	    return $ascii
	}
	default {
	    error "No other representations supported"
	}
    }	

}

namespace eval status {}

proc status::makePrompt {w {oldtags ""}} {
    #catch {destroy $w}
    #label $w -text "" -background [default::color lightbackground] \
    #  -borderwidth 0 -padx 0
    #pack $w -side left
    if {![string length $oldtags]} {
	_forceTop
	grab $w
    } else {
	catch {grab release $w}
    }

    set prevtags [bindtags $w]
    
    if {![string length $oldtags]} {
	bind all <Button-1> [list alpha::forceFocus $w]
    } else {
	bind all <Button-1> ""
    }
    
    # The status bar nearly works without any of this stuff, just with
    # the two simple 'press/release' bindings below.  However, it doesn't
    # quite work, because if a modifier-key is already held down when the
    # status::prompt is first called, then we never notice that with the
    # simpler code.  For example if 'ctrl-s' is used for an interactive
    # search, a sequence of 'ctrl-s ctrl-w' in which the 'ctrl' is never
    # released is seen as ctrl-s w.  The more complex code handles this
    # case by explicitly binding to each possible modifier.
    global alpha::modifier_keys alpha::mods
    for {set i 0} {$i < 16} {incr i} {
	set key ""
	set themods 0
	set count 1
	foreach mod [list Shift Control \
	  [lindex $alpha::modifier_keys 0] \
	  [lindex $alpha::modifier_keys 2]] {
	    if {$i & $count} {
		append key "$mod-"
		set themods [expr {$themods | $alpha::mods($mod)}]
	    }
	    set count [expr {2*$count}]
	}
	if {![string length $oldtags]} {
	    bind $w <${key}KeyPress> \
	      "status::pressed 1 %A %K %N $themods ; break"
	    bind $w <${key}KeyRelease> \
	      "status::pressed 0 %A %K %N $themods ; break"
	} else {
	    bind $w <${key}KeyPress> ""
	    bind $w <${key}KeyRelease> ""
	}
    }
    
    #bind $w <KeyPress> "status::pressed 1 %A %K %N"
    #bind $w <KeyRelease> "status::pressed 0 %A %K %N"
    #bind $w <Return> "status::pressed 1 %A %K %N 0 ; break;\
    # set alphaPriv(done) 1 ; set alphaPriv(key) {}; break"
    bindtags $w [list $w all]
    return $prevtags
}

proc status::pressed {press ascii mods other {modval 0}} {
    global alphaPriv
    if {$modval != 0} {
	if {$press} {
	    set alphaPriv(mods) [expr {$alphaPriv(mods) | $modval}]
	} else {
	    set alphaPriv(mods) [expr {($alphaPriv(mods) | $modval) ^ $modval}]
	}
    }
    if {![string length $ascii]} {
	global alpha::asciiMap
	if {[info exists alpha::asciiMap($mods)]} {
	    set ascii $alpha::asciiMap($mods)
	}
    }
    set alphaPriv(key) [list $press $ascii $mods $other $modval]
    #puts stdout "pressed: $press $ascii $mods $other $modval"
}

array set alpha::asciiMap [list BackSpace \x08 Return \x0d]

proc status::_forceTop {} {
    set w .status
    if {![winfo ismapped $w]} {
	wm deiconify [winfo toplevel $w]
	raise [winfo toplevel $w]
	update
    }
    if {![winfo ismapped $w]} {
	return -code error "Bug: Can't map $w"
    }
}

proc status::flash {color {wait 100}} {
    _forceTop
    set oldbg [.status cget -bg]
    .status configure -background $color
    .status.text configure -background $color
    update
    after $wait "set waiting 1"
    vwait waiting
    .status configure -background $oldbg
    .status.text configure -background $oldbg
}

array set alpha::keyToAsciiSpecials \
  [list Left \x1c Right \x1d Up \x1e Down \x1f Home \x01 End \x04 \
  Prior \x0b Next \x0c]

proc coreKeyPrompt {prompt} {
    global alphaPriv alpha::modifiers alpha::mods alpha::keyToAsciiSpecials
    set oldFocus [dialog::getFocus .status]
    set oldGrab [dialog::getGrab .status ""]
    #status::msg $prompt
    set oldTags [status::makePrompt .status.text]
    set err 0
    set res ""
    
    # Use a catch in case something really bad happens.
    
    if {[catch {
	# have problem in that the bindings below trigger and screw us
	# Not sure why the keycapture binding prevents alphaPriv(done)
	# from being set to 1
	alpha::forceFocus .status.text
	set alphaPriv(mods) 0
	if {[info exists alphaPriv(done)]} {unset alphaPriv(done)}
	set statuscontents ""
	while {1} {
	    vwait alphaPriv(key)
	    if {[info exists alphaPriv(done)]} {
		break
	    } else {
		if {![info exists alphaPriv(key)]} {
		    # Weird MacOSX problem
		    break
		}
		regsub -all -- {_[LR]} \
		  [set keycode [lindex $alphaPriv(key) 2]] "" keycode
		if {[info exists alpha::mods($keycode)]} {
		    if {[lindex $alphaPriv(key) 0]} {
			# pressed so add to list of mods
			set alphaPriv(mods) \
			  [expr {$alphaPriv(mods) | $alpha::mods($keycode)}]
		    } else {
			# released so remove
			set alphaPriv(mods) \
			  [expr {($alphaPriv(mods) | \
			  $alpha::mods($keycode)) ^ $alpha::mods($keycode)}]
		    }
		    unset alphaPriv(key)
		    continue
		} else {
		    # it was a real key
		    #puts "$keycode , $alphaPriv(key)"
		    if {[lindex $alphaPriv(key) 0]} {
			if {[string length $keycode] > 1} {
			    # So we don't append 'question', but rather ?
			    set ascii [lindex $alphaPriv(key) 1]
			    if {[string length $ascii]} {
				append statuscontents $ascii
			    } elseif {[info exists \
			      keyToAsciiSpecials($keycode)]} {
				append statuscontents \
				  $keyToAsciiSpecials($keycode)
			    } else {
				append statuscontents ""
			    }
			} else {
			    append statuscontents $keycode
			}
		    } else {
			unset alphaPriv(key)
			continue
		    }
		    
		}
		set first ""
		set last ""
		regexp -- {^(.*)(.)$} $statuscontents "" first last
		set res [list $last $alphaPriv(mods)]
		#puts $res
		break
	    }
	}
    } cerr]} { 
	alertnote "Please report a 'coreKeyPrompt' bug in Alphatk: $err"
    }
    
    if {[info exists alphaPriv(done)]} {unset alphaPriv(done)}
    unset -nocomplain alphaPriv(key)
    catch {grab release .status.text}
    status::makePrompt .status.text $oldTags
    dialog::restoreFocus .status $oldFocus
    dialog::releaseGrab $oldGrab
    return -code $err $res
}

#¥ statusPrompt <prompt> [<func>] - Prompt in the status window. If 'func' 
#  is present, call this routine at each key-press with the current 
#  contents of the status line and the key, insert into statusline 
#  whatever is returned by the func. Command-v pastes the current (<80 
#  char) clipboard contents on the status line.
proc statusPrompt {prompt {func ""} args} {
    global alphaPriv
    set alphaPriv(status) ""
    set oldFocus [dialog::getFocus .status]
    set oldGrab [dialog::getGrab .status ""]
    set flag ""
    if {$prompt == "-f" || $prompt == "--"} {
	set flag $prompt
	set prompt $func
	set func [lindex $args 0]
    }
    if {$flag == "-f"} {
	status::flash black
    }
    status::msg $prompt
    catch {destroy .status.e}
    entry .status.e -textvariable alphaPriv(status)
    grid .status.e -column 1 -row 0 -sticky w
    grid columnconfigure .status 1 -weight 1000
    grab .status.e
    trace add variable alphaPriv(status) write status::_helper
    bind .status.e <Return> "set alphaPriv(done) 1"
    bind .status.e <Escape> "set alphaPriv(done) 2"

    alpha::forceFocus .status.e
    bind all <Button-1> [list alpha::forceFocus .status.e]

    while 1 {
	vwait alphaPriv(done)
	if {$alphaPriv(done) == 1} {
	    trace remove variable alphaPriv(status) write status::_helper
	    break
	} elseif {$alphaPriv(done) == 2} {
	    trace remove variable alphaPriv(status) write status::_helper
	    set cancel 1
	    break
	}
	set first ""
	set last ""
	regexp -- {^(.*)(.)$} $alphaPriv(status) "" first last
	if {$func != ""} {
	    if {[catch [list uplevel 1 $func [list $first $last]] res]} {
		trace remove variable alphaPriv(status) write status::_helper
		break;
	    }
	}
	unset alphaPriv(done)
    }
    if {[info exists alphaPriv(done)]} {unset alphaPriv(done)}
    catch {destroy .status.e}
    grid columnconfigure .status 1 -weight 0
    catch {grab release .status.e}
    dialog::restoreFocus .status $oldFocus
    dialog::releaseGrab $oldGrab
    bind all <Button-1> ""
    if {[info exists cancel]} {
	error "Cancelled."
    }
    return $alphaPriv(status)
}

proc status::_helper {args} {
    global alphaPriv
    if {![info exists alphaPriv(done)]} {
	set alphaPriv(done) 0
    }
    
}

#¥ askyesno [-c] prompt
#  This command will display a Macintosh alert box with 'prompt' displayed
#  with the push buttons Yes and No. The command will return the 
#  string "yes" or "no". The '-c' flag specifies that a cancel button be 
#  used as well.  Also '-y name -n name' can optionally be used to
#  specify the names of the yes/no buttons (but 'yes' and 'no' are
#  always the return strings).
proc askyesno {args} {
    set yes "Yes"
    set no "No"
    for {set i 0} {$i < ([llength $args] -1)} {incr i} {
	switch -- [lindex $args $i] {
	    "-c" {
		set cancel "Cancel"
	    }
	    "-y" {
		incr i
		set yes [lindex $args $i]
	    }
	    "-n" {
		incr i
		set no [lindex $args $i]
	    }
	    "--" {
		incr i
		break
	    }
	    default {
		error "Bad option [lindex $args $i]"
	    }
	}
    }
    lappend buttons $yes $no
    if {[info exists cancel]} {
	lappend buttons $cancel
	lappend options "cancel"
    }
    # Reverse buttons so that the first is presented to the far right.
    set rbuttons {}
    foreach b $buttons { set rbuttons [linsert $rbuttons 0 $b] }
    set buttons $rbuttons

    lappend options "no" "yes"
    set text [lindex $args $i]
    incr i
    if {$i != [llength $args]} {
	error "Bad arguments: askyesno $args"
    }
    set defaultButtonIdx [expr {[llength $buttons] - 1}]
    if {[tk windowingsystem] == "classic"  || [tk windowingsystem] == "aqua"} {
	set bitmap "stop"
    } else {
	set bitmap ""
    }
    set i [eval [list dialog::buildTkDialog [dialog::findRoot] \
      "" $text $bitmap $defaultButtonIdx] $buttons]
    return [lindex $options $i]
}
#¥ buttonAlert <prompt> [<button>...] - Create a dialog w/ the specified 
#  buttons, returning the one selected.
proc buttonAlert {prompt args} {
    set buttons [list]
    foreach b $args {
	if {$b ne ""} {
	    lappend buttons $b
	}
    }
    if {![llength buttons]} {
	# Ensure that we have at least one button.
	set buttons [list "OK"]
    } else {
	# Reverse buttons so that the first is presented to the far right.
	set rbuttons {}
	foreach b $buttons { set rbuttons [linsert $rbuttons 0 $b] }
	set buttons $rbuttons
    }
    set defaultButtonIdx [expr {[llength $buttons] - 1}]
    if {[tk windowingsystem] == "classic"  || [tk windowingsystem] == "aqua"} {
	set bitmap "stop"
    } else {
	set bitmap ""
    }
    set i [eval [list dialog::buildTkDialog [dialog::findRoot] \
      "" $prompt $bitmap $defaultButtonIdx] $buttons]
    return [lindex $buttons $i]
}

namespace eval dialog {}

proc dialog::releaseGrab {of} {
    foreach {oldGrab grabStatus} $of {break}
    if {$oldGrab != "" && [winfo exists $oldGrab]} {
	if {$grabStatus == "global"} {
	    grab -global $oldGrab
	} else {
	    grab $oldGrab
	}
    }
}

proc dialog::getGrab {w {global 0}} {
    set oldGrab [grab current $w]
    set grabStatus {}
    if {$oldGrab != "" && [winfo exists $oldGrab]} {
	set grabStatus [grab status $oldGrab]
    }
    if {$global != ""} {
	# If this catches, we have a grab somewhere else,
	# possibly in a subinterp which we aren't handling.
	catch {
	    if {$global} {
		grab -global $w
	    } else {
		grab $w
	    }
	}
    }
    return [list $oldGrab $grabStatus]
}

proc dialog::buildTkDialog {w args} {
    global alpha::modifier_keys
    
    # Make sure our name doesn't clash with anything
    set i 0
    while {[winfo exists $w.dial$i]} {
	incr i
    }
    set w $w.dial$i
    
    # Add Alphatk bindings to toplevel
    after idle [list alpha::makeToplevel $w]
    # Make the dialog respond to keypresses.
    after idle [list bind $w <[lindex $alpha::modifier_keys 0]-KeyPress> \
      "dialog::cmd_key $w %K"]
    after idle [list bind $w <KeyPress-Escape> "dialog::cmd_key $w cancel"]
    
    eval [list ::alpha_tk_dialog $w] $args
}

#¥ dialog [<-w width>|<-h height>|<-b title l t r b>|<-c title val l t r b>|
#		<-t text l t r b>|<-e text l t r b>|<-r text val l t r b>|
#		<-p l t r b>]+ 
#  Create and display a dialog.  '-w' and '-h' allow width and height of 
#  dialog window to be set.  '-b', '-c', '-r', '-t', '-e' and '-p' allow 
#  buttons, checkboxes, radio buttons, static text, editable text and gray 
#  outlines to be created, respectively.  All control types (except gray 
#  outlines) require specification of a title or text, together with left, 
#  top, right, and bottom coordinates.  Checkboxes and radioboxes have an 
#  additional parameter, the default value.  At least one button must be 
#  specified.  The return value is a list containing resulting values for 
#  all buttons, radioboxes, checkboxes, and editable textboxes (static text 
#  is ignored).  Buttons have value '1' if chosen, '0' otherwise.  The 
#  dialog box exits at the first button press.
#
proc dialog {args} {
    #puts stderr "dialog $args"
    if {[info exists ::alpha::debug_dialog]} {
	set time [clock clicks -micro]
	if {$::alpha::debug_dialog == 2} {
	    return -code error "cancel"
	}
    }
    global tcl_platform alphaPriv dialog::scripts
    
    # Set up a unique dialog window, and dialog storage array.
    # This allows this procedure to be re-entrant.
    set dialogNumber 1
    while {[info exists alphaPriv(atkdialog$dialogNumber)]} {
	incr dialogNumber
    }
    set dial atkdialog$dialogNumber
    global $dial
    set root [dialog::findRoot]
    set w [set alphaPriv($dial) ${root}.dl$dialogNumber]
    catch {destroy $w}
    # Remember old focus
    set ${dial}(oldFocus) [dialog::getFocus $w]

    alpha::makeToplevel $w -class Dialog
    wm title $w ""
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW { }

    # Dialog boxes should be transient with respect to their parent,
    # so that they will always stay on top of their parent window.  However,
    # some window managers will create the window as withdrawn if the parent
    # window is withdrawn or iconified.  Combined with the grab we put on the
    # window, this can hang the entire application.  Therefore we only make
    # the dialog transient if the parent is viewable.
    if {[winfo viewable [winfo toplevel [winfo parent $w]]]} {
	wm transient $w [winfo toplevel [winfo parent $w]]
    }
    if {[tk windowingsystem] == "classic" \
      || [tk windowingsystem] == "aqua"} {
	::tk::unsupported::MacWindowStyle style $w movableDBoxProc
    }

    pack [::ttk::frame $w.f] -fill both -expand 1

    set val 0
    set havebutton ""
    set haveentry ""
    set in $w.f
    set ${dial}(window) $w.f
    set ${dial}(pagevars) [list]
    
    set len [llength $args]
    if {[lindex $args [expr {$len -2}]] == "-help"} {
	set help [lindex $args end]
    }

    if {[catch {
	dialog_buildItems $dial $args
	if {$havebutton == ""} {
	    destroy $w
	    error "Must have a button in the dialog!"
	}
	if {![info exists arg(-w)] || ![info exists arg(-h)]} {
	    destroy $w
	    error "Must have both -w and -h in the dialog!"
	}
	if {[info exists help] && [llength $help]} {
	    destroy $w
	    error "Too many help entries specified: '$help' are left over"
	}
	if {[info exists nothingYet] && ($haveentry eq "")} {
	    eval $nothingYet
	}
	# Verify that all tags which were referenced actually exist
	if {[info exists check_tags]} {
	    foreach item $check_tags {
		if {![info exists ${dial}(tag,$item)]} {
		    error "No such tag '$item' registered"
		}
	    }
	}

	set _w [expr {([winfo screenwidth $w] - [distanceToScreen $arg(-w)])/2}]
	if {$_w < 0} { set _w 0}
	set _h [expr {([winfo screenheight $w] - [distanceToScreen $arg(-h)])/2}]
	if {$_h < 0} { set _h 0}
	wm geometry $w \
	  [distanceToScreen $arg(-w)]x[distanceToScreen $arg(-h)]+${_w}+${_h}
	$w.f configure -width [distanceToScreen $arg(-w)] \
	  -height [distanceToScreen $arg(-h)]
	# end of big 'catch'
    } err]} {
	#puts $::errorInfo
	unset -nocomplain $dial
	destroy $w
	if {[info exists ${dial}(deleteCommands)]} {
	    foreach cmd [set ${dial}(deleteCommands)] {
		rename $cmd ""
	    }
	}
	return -code error "$err around (previous\
	  [lrange $args [expr {$i -4}] [expr {$i -1}]]),\
	  (next [lrange $args $i [expr {$i+6}]]),\
	  $::errorInfo"
    }

    # 5. Create a <Destroy> binding for the window that sets the
    # button variable to -1;  this is needed in case something happens
    # that destroys the window, such as its parent window being destroyed.

    bind $w <Destroy> [list set ${dial}(button) -1]
    
    # 6. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw $w

    update idletasks
    # If the window has an icon, now is the time to set it
    alpha::setIcon $w
    if {[info exists arg(-x)]} {
	set x [distanceToScreen $arg(-x)]
    } else {
	set x [expr {[winfo screenwidth $w]/2 - [distanceToScreen $arg(-w)]/2 \
		- [winfo vrootx [winfo parent $w]]}]
    }
    if {[info exists arg(-y)]} {
	set y [distanceToScreen $arg(-y)]
    } else {
	set y [expr {[winfo screenheight $w]/2 - [distanceToScreen $arg(-h)]/2 \
		- [winfo vrooty [winfo parent $w]]}]
    }
    wm geom $w +$x+$y
    if {[info exists title]} {
	if {$tcl_platform(platform) == "windows"} {
	    # The standard Windows titlebar font doesn't seem to have
	    # an ellipsis... except for Windows 2000 (= NT 5.0)
	    # I need to know whether this is required on Win95/98...
	    if {($tcl_platform(os) != "Windows NT") \
	      || ($tcl_platform(osVersion) != 5.0)} {
		regsub -all "É" $title "..." title
	    }
	}
	if {[tk windowingsystem] eq "aqua" && $title == ""} {
	    # Workaround TkAqua bug
	    set title " "
	}
	wm title $w $title
    }
    wm deiconify $w
    
    foreach pv [set ${dial}(pagevars)] {
	# Have to place the correct item in each page, but also
	# we do this with an idle callback because of WinTk dnd
	# problems.
	after idle [list dialog_pane_change $dial [set ${dial}(window)] "" $pv ""]
    }

    if {![info exists ${dial}(modeless)]} {
	# 7. Set a grab and
	set ${dial}(oldGrab) [dialog::getGrab $w]
    }

    # 8. Claim the focus
    if {$haveentry != ""} {
	set e [set ${dial}(window)].d$haveentry
	focus $e
	if {[dialog::classIs $e "Entry"]} {
	    $e selection range 0 end
	} else {
	    # must be text widget
	    if {[string length [$e get 1.0 "end -1c"]]} {
		$e tag add sel 1.0 "end -1c"
	    }
	}
    } else {
	focus [set ${dial}(window)].d$havebutton
    }
    
    global alpha::modifier_keys
    bind OverallDialog <[lindex $alpha::modifier_keys 0]-KeyPress> \
      "dialog::cmd_key $w %K"
    # 8. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    bindtags $w [concat [list "OverallDialog"] [bindtags $w]]
    bind OverallDialog <Control-Return> \
      "dialog::redirectToFocus <Return> ; break"
    bind OverallDialog <Control-Tab> \
      "dialog::redirectToFocus <Tab> ; break"
    bind OverallDialog <Control-Shift-Tab> \
      "dialog::redirectToFocus <Shift-Tab> ; break"
    bind OverallDialog <Tab> \
      {dialog::tabToWindow [tk_focusNext %W] ; break}
    bind OverallDialog <Shift-Tab> \
      {dialog::tabToWindow [tk_focusPrev %W] ; break}

    #puts "$w, [focus]"
    #puts "[bindtags $w], [bindtags [focus]]"
    #bind $w <F1> {puts [focus] ; puts "tags: [bindtags [focus]]"}
    if {[info exists ::alpha::debug_dialog]} {
	puts [expr {([clock clicks -micro] - $time)/1000000.0}]

	after idle [list event generate $w <Escape>]
    }
    set ${dial}(w) $w
    set ${dial}(val) $val
    
    if {[info exists ${dial}(modeless)]} {
	trace add variable ${dial}(button) write \
	  [list dialog_modeless $dial]
	return $dial
    } else {
	tkwait variable ${dial}(button)
	return [dialog_finish $dial]
    }
}

proc dialog_modeless {dial args} {
    dialog_finish $dial
}

proc dialog_finish {dial} {
    global $dial alphaPriv
    
    #parray ${dial}
    set w [set ${dial}(window)]
    if {[info exists ${dial}(geometryvariable)]} {
	upvar 2 [set ${dial}(geometryvariable)] geometry
	set geometry [eval screenToDistance \
	  [split [wm geometry [winfo toplevel $w]] "x+"]]
    }
    set val [set ${dial}(val)]
    
    foreach pagevar [set ${dial}(pagevars)] {
	catch {trace remove variable ${dial}($pagevar) \
	  write [list ::dialog_pane_change $dial $w]}
	foreach v [array names ${dial} pager,*] {
	    unset -nocomplain ${dial}($v)
	}
    }
    if {[info exists ${dial}(deleteCommands)]} {
	# We overrode some commands, so we must make sure to
	# delete the procs we created.
	foreach cmd [set ${dial}(deleteCommands)] {
	    rename $cmd ""
	    rename __$cmd $cmd
	}
    }
    if {![info exists ${dial}(callback)]} {
	dialog::restoreFocus [winfo toplevel $w] [set ${dial}(oldFocus)]
    }
    set res {}
    for {set k 0} {$k < $val} {incr k} {
	if {[info exists ${dial}(isType($k))]} {
	    foreach {type ww} [set ${dial}(isType($k))] {break}
	    if {![winfo exists $ww]} {
		error "Window $ww destroyed!"
	    }
	    switch -- $type {
		"Text" {
		    lappend res [$ww get 1.0 "end -1c"]
		}
		"List" {
		    lappend res [$ww get 0 end]
		}
		"NoteBook" - "PagesManager" {
		    lappend res [$ww raise]
		}
		"Listitem" {
		    if {[$ww cget -selectmode] eq "extended"} {
			# Multi-item selection - result is a list
			# of items.
			set lres [list]
			foreach v [$ww curselection] {
			    lappend lres [$ww get $v]
			}
			lappend res $lres
		    } else {
			# Single item selection - result is the item
			if {[$ww curselection] ne ""} {
			    lappend res [$ww get [$ww curselection]]
			} else {
			    lappend res {}
			}
		    }
		}
		default {
		    error "Bad type '[set ${dial}(isType($k))]'"
		}
	    }
	} else {
	    if {[info exists ${dial}(var$k)]} {
		if {[string range [set ${dial}(var$k)] 0 10] == "radiobutton"} {
		    if {[info exists ${dial}(dialog::selectedButton)] \
		      && ([set ${dial}(dialog::selectedButton)] eq \
		      [string range [set ${dial}(var$k)] 12 end])} {
			lappend res 1
		    } else {
			lappend res 0
		    }
		} else {
		    #echo "alphaPriv(var$k) = [set alphaPriv(var$k)]"
		    set tmpres [set ${dial}(var$k)]
		    if {[info exists ${dial}(mapalphaPriv(var$k):$tmpres)]} {
			set actual [set ${dial}(mapalphaPriv(var$k):$tmpres)]
			unset ${dial}(mapalphaPriv(var$k):$tmpres)
			set tmpres $actual
		    }
		    lappend res $tmpres
		}
		unset ${dial}(var$k)
	    } else {
		if {[set ${dial}(button)] == $k} {
		    lappend res 1
		} else {
		    lappend res 0
		}
	    }
	} 
    }
    
    set w [winfo toplevel $w]
    
    catch {
	# It's possible that the window has already been destroyed,
	# hence this "catch".  Delete the Destroy handler so that
	# ${dial}(button) doesn't get reset by it.
	wm withdraw $w
	bind $w <Destroy> {}
	destroy $w
    }
    # This is a hack to make sure our variables are unset.
    # Unfortunately, despite the fact that we unset them correctly
    # above, when we destroy the window, the tk_optionMenu items
    # may be set again....
    foreach v [array names ${dial}] {
	if {[string match "var*" $v]} { unset ${dial}($v) }
	if {[string match "map*" $v]} { unset ${dial}($v) }
    }
    if {![info exists ${dial}(modeless)]} {
	dialog::releaseGrab [set ${dial}(oldGrab)]
    }
    update idletasks
    unset alphaPriv($dial)
    unset $dial

    if {![info exists ${dial}(callback)]} {
	return $res
    } else {
	uplevel 1 [set ${dial}(callback)] $res
    }
}

namespace eval dialog {}

proc dialog_controlTags {currentIdx tags} {
    upvar 1 check_tags check_tags
    
    set items {}
    foreach item $tags {
	if {[string is integer $item]} {
	    if {[regexp -- {^(\+|-)} $item]} {
		set item [expr {$item + $currentIdx}]
	    }
	} else {
	    lappend check_tags $item
	}
	lappend items $item
    }
    return $items
}

proc dialog::pushButton {w} {
    $w configure -state active
    catch {$w configure -relief sunken}
    update idletasks
    after 100
}

#ttk::button .b -text "Set" -padding {0 0 0 0} 
#place .b -x 20 -y 20 -height 16 -width 50

#toplevel .tt -bg red
#button .tt.b -text "Cancel" -padx 0 -pady 0 -bd 0 -highlightthickness 0
#ttk::button .tt.b2 -text "Cancel" -padding {0 1 0 1}
#place .tt.b -x 50 -y 20 -width 63 -height 21
#place .tt.b2 -x 50 -y 50 -width 63 -height 21

if {0} {
set w .tt
toplevel $w ; ::tk::unsupported::MacWindowStyle style $w movableDBoxProc
ttk::frame $w.f -width 300 -height 300 ; pack $w.f -fill both -expand 1
ttk::label $w.f.l -text "Here's some text for testing"
ttk::button $w.f.b -text "Press me" -command "destroy .tt"
pack $w.f.l -side top
pack $w.f.b -side top
}

set alphatk_dialog(-button) {
    set label [lindex $args [expr {$i +1}]]
    set default 0
    if {[lindex $args [expr {$i+2}]] eq "-default"} {
	set default 1
	incr i
    }
    if {$label eq "Set\u2026"} {
	if {$::alpha::theming} {
	    ::ttk::button $w.d$j -text $label \
	      -command "set ${dial}(var$val) 1 ; set ${dial}(button) $val" \
	      -width 0 -style Small.TButton -padding {0 1 0 1}
	    if {$::alpha::macos == 0} {
		$w.d$j configure -padding {0 -2 0 0}
	    }
	} else {
	    ::tk::button $w.d$j -text $label \
	      -command "set ${dial}(var$val) 1 ; set ${dial}(button) $val"
	}
    } else {
	::ttk::button $w.d$j -text $label \
	  -command "set ${dial}(var$val) 1 ; set ${dial}(button) $val"
	if {[tk windowingsystem] eq "aqua"} {
	    $w.d$j configure -padding {-6 1 0 0} 
	}
    }
    # first button is the default
    if {$havebutton == ""} {
	set default 1
    }
    if {$default} {
	if {[info exists ${dial}(defaultButton)]} {
	    [set ${dial}(defaultButton)] configure -default normal
	}
	set ${dial}(defaultButton) $w.d$j
	bind OverallDialog <Return> "
	    if {\[winfo class %W\] == \"Text\" \
	      && (\[winfo height %W\] >= 50)} {
		# It's a text widget which is fairly large,
		# so don't let return hit the default button.
		continue
	    }
	    dialog::pushButton $w.d$j
	    set ${dial}(button) $val
	    break
	"
	foreach b {Extended-Return KP_Enter} {
	    # Catch in case 'Extended' doesn't exist.
	    catch {
		bind OverallDialog <$b> "
		    dialog::pushButton $w.d$j
		    set ${dial}(button) $val
		    break
		"
	    }
	}
	$w.d$j configure -default active
	set havebutton $j
    }
    if {$label == "Cancel"} {
	bind [winfo toplevel $w] <Escape> "
	dialog::pushButton $w.d$j
	set ${dial}(button) $val
	break
	"
	wm protocol [winfo toplevel $w] WM_DELETE_WINDOW \
	  [list event generate [winfo toplevel $w] <Escape>]
    }
    incr val
    incr i 2
}
set alphatk_dialog(-listbox) {
    set listitems [lindex $args [expr {$i +1}]]
    set rows [lindex $args [expr {$i +2}]]
    listbox $w.d$j -height $rows 
    eval [list $w.d$j insert end] $listitems
    set ${dial}(isType($val)) [list List $w.d$j]
    set ${dial}(isType($w.d$j)) [list List]
    incr val
    incr i 3
}
set alphatk_dialog(-listitem) {
    set listitems [lindex $args [expr {$i +1}]]
    set rows {}
    set scrolled 0
    set active 0
    set multiple 0
    foreach param [lindex $args [expr {$i +2}]] {
	if {$param eq "active"} {
	    set active 1
	} elseif {$param eq "scrolled"} {
	    set scrolled 1
	} elseif {$param eq "multiple"} {
	    set multiple 1
	} else {
	    error "Bad parameter $param to -listitem"
	}
    }
    set rows [lindex $args [expr {$i +3}]]
    set curr [lindex $listitems 0]
    set listitems [lrange $listitems 1 end]
    if {$rows ne ""} {
	listbox $w.d$j -exportselection 0 -height $rows
    } else {
	listbox $w.d$j -exportselection 0
    }
    eval [list $w.d$j insert end] $listitems
    
    if {$scrolled} {
	scrollbar $w.dscroll$j -command "$w.d$j yview"
	$w.d$j configure -yscroll "$w.dscroll$j set"
    }
    if {$active} {
	alpha::bindDialogListbox $w $w.d$j
    }
    if {$multiple} {
	$w.d$j configure -selectmode extended
	set sel [list]
	foreach itm $curr {
	    set idx [lsearch -exact $listitems $itm]
	    if {$idx != -1} {
		lappend sel $idx
	    }
	}
	if {[llength $sel]} {
	    eval [list $w.d$j selection set] $sel
	    $w.d$j see [lindex $sel 0]
	}
    } else {
	if {[lsearch -exact $listitems $curr] == -1} {
	    set curr [lindex $listitems 0]
	}
	set idx [lsearch -exact $listitems $curr]
	$w.d$j selection set $idx
	$w.d$j see $idx
    }
    set ${dial}(isType($val)) [list Listitem $w.d$j]
    set ${dial}(isType($w.d$j)) [list Listitem]
    # Set up synchronized variable, and over-ride listbox
    # so that changes to its selection update this variable
    # (so that -action scripts can trigger).
    set ${dial}(var$val) $curr
    dialog_overrideListbox $dial $w.d$j [list $dial $w.d$j $w var$val]
    incr val
    incr i 4
}
set alphatk_dialog(-checkbox) {
    if {[lindex $args [expr {$i+2}]] == ""} {
	set defval 0
    } else {
	set defval [lindex $args [expr {$i+2}]]
	if {![string is boolean $defval]} {
	    error "Bad value '$defval' for checkbox"
	    set defval 0
	}
    }
    # Accept any boolean 'true' value, but convert
    # into 1 or 0.
    if {$defval} {
	set ${dial}(var$val) 1
    } else {
	set ${dial}(var$val) 0
    }
    if {$type == "-checkGroupBox"} {
	::ttk::labelframe $w.d$j
	::ttk::checkbutton $w.d$j.check -text \
	  [lindex $args [expr {$i +1}]] \
	  -variable ${dial}(var$val) 
	catch {$w.d$j.check configure -anchor w -justify left}
	$w.d$j configure -labelwidget $w.d$j.check -labelanchor nw
    } else {
	::ttk::checkbutton $w.d$j -text \
	  [lindex $args [expr {$i +1}]] \
	  -variable ${dial}(var$val) 
	catch {$w.d$j configure -anchor w -justify left}
	set auto_size 1
	set doWrap $Metrics(CheckBoxWidth)
    }
    incr val
    incr i 3
}

proc dialog_buildItems {dial theargs} {
    global $dial tcl_platform alphatk_dialog
    
    getThemeMetrics Metrics
    
    upvar 1 check_tags check_tags
    upvar 1 arg arg
    upvar 1 val val
    upvar 1 havebutton havebutton
    upvar 1 haveentry haveentry
    upvar 1 nothingYet nothingYet
    upvar 1 in in
    upvar 1 i i
    upvar 1 help help
    upvar 1 title title
    
    set args $theargs

    set i 0
    set j 0

    set w [set ${dial}(window)]
    set in $w

    while 1 {
	set type [lindex $args $i]
	switch -- $type {
	"-width" - "-height" -    
	"-w" - "-h" - "-x" - "-y" {
	    incr i
	    set arg([string range $type 0 1]) [lindex $args $i]
	    incr i
	    continue
	}
	"-geometryvariable" {
	    incr i
	    set varname [lindex $args $i]
	    set ${dial}(geometryvariable) $varname
	    upvar 2 $varname geo
	    if {[info exists geo] && ([llength $geo] != 0)} {
		if {[llength $geo] != 4} {
		    error "[lindex $args $i] must be a list of 4 elements.\
		      It has [llength $geo]"
		}
		foreach v {-w -h -x -y} g $geo {
		    set arg($v) $g
		}
	    }
	    incr i
	    continue
	}
	"-modeless" {
	    set ${dial}(modeless) 1
	    incr i
	    continue
	}
	"-callback" {
	    set ${dial}(callback) [lindex $args [expr {$i +1}]]
	    incr i 2
	    continue
	}
	"-button" - 
	"-b" {
	    eval $alphatk_dialog(-button)
	    #after 1000 "puts \[winfo width $w.d$j\]"
	    #puts [lrange $args [expr {$i - 1}] [expr {$i + 4}]]
	}
	"-listpick" -
	"-listbox" -
	"-l" {
	    eval $alphatk_dialog(-listbox)
	}
	"-listitem" {
	    eval $alphatk_dialog(-listitem)
	}
	"-checkBox" -
	"-checkbox" -
	"-checkGroupBox" -
	"-c" {
	    eval $alphatk_dialog(-checkbox)
	}
	"-popupGroupBox" {
	    set label [lindex $args [expr {$i +1}]]
	    set items [lindex $args [expr {$i +2}]]
	    set curr [lindex $items 0]
	    set items [lrange $items 1 end]
	    if {[lsearch -exact $items $curr] == -1} {
		set curr [lindex $items 0]
	    }
	    set ${dial}(var$val) $curr
	    ::ttk::labelframe $w.d$j
	    eval [list alpha_optionMenu $w.d$j.popup ${dial}(var$val)] $items
	    $w.d$j configure -labelwidget $w.d$j.popup -labelanchor nw
	    alpha::ensureBWidgetLoaded PagesManager
	    #package require BWidget
	    PagesManager $w.d$j.pages
	    foreach item $items {
		$w.d$j.pages add [dialog::_cleanName $item]
	    }
	    pack $w.d$j.pages -fill both
	    lappend ${dial}(pagevars) var$val
	    set ${dial}(pager,var$val) [list "popupgroupbox" \
	      [list $w.d$j $w.d$j.pages $w.d$j.popup] $items]
	    incr val
	    incr i 3
	}
	"-groupBox" -
	"-labelframe" {
	    set label [lindex $args [expr {$i +1}]]
	    ::ttk::labelframe $w.d$j -text $label \
	      -labelanchor nw
	    set pane $label
	    if {[lindex $args [expr {$i +2}]] eq "-pane"} {
		set pane [lindex $args [expr {$i +3}]]
		incr i 2
	    }
	    # declare this as a page
	    lappend ${dial}(pagevars) pane$pane
	    set ${dial}(pager,pane$pane) [list "labelframe" $w.d$j [list $pane]]
	    incr i 2
	}
	"-separator" {
	    if {$::alpha::theming} {
		ttk::separator $w.d$j -orient horizontal
	    } else {
	        frame $w.d$j -relief sunken -height 3 -bd 1
	    }
	    incr i
	}
	"-text" -
	"-staticText" -
	"-t" {
	    set label [lindex $args [expr {$i +1}]]
	    ::ttk::label $w.d$j -text $label \
	      -anchor w \
	      -wraplength [distanceToScreen [expr {$arg(-w) -20}]] \
	      -justify left -padding {0 0 0 0} -borderwidth 0
	    incr i 2
	}
	"-icon" -
	"-image" - 
	"-i" {
	    set label [lindex $args [expr {$i +1}]]
	    ::ttk::label $w.d$j -image $label \
	      -anchor w
	    incr i 2
	}
	"-edittext" -
	"-e" {
	    set show ""
	    set econtents [lindex $args [expr {$i +1}]]
	    incr i 2
	    while {1} {
		switch -- [lindex $args $i] {
		    "-password" {
			set show "\u2022"
			incr i
		    }
		    "--" {
			incr i
			break
		    }
		    default {break}
		}
	    }
	    set eheight [expr {[lindex $args [expr {$i +3}]] - \
	      [lindex $args [expr {$i + 1}]]}]
	    global defaultFont 
	    if {[globalVarIsShadowed fontSize]} {
		set fs [globalVarSet fontSize]
	    } else {
		set fs $::fontSize
	    }
	    if {$eheight > 20} {
		if {$show != ""} {
		    return -code error "Can't have multi-line\
		      password fields"
		}
		# multi-line; use text widget
		::text $w.d$j -wrap char -relief sunken \
		  -bd 2 -highlightthickness 0 \
		  -font [list $defaultFont $fs]
		$w.d$j insert end $econtents
		set ${dial}(isType($val)) [list Text $w.d$j]
	    } else {
		if {$eheight < 3} {
		    set show "\u2022"
		}
		set ${dial}(var$val) $econtents
		::ttk::entry $w.d$j -textvariable ${dial}(var$val) \
		  -show $show
		#-font [list $defaultFont $fs] 
	    }
	    if {$haveentry == ""} {
		set haveentry $j
	    }
	    incr val
	}
	"-multipane" -
	"-tab" -
	"-mt" -
	"-titlePopup" -
	"-popup" -
	"-m" {
	    if {$type eq "-mt" || $type eq "-titlePopup"} {
		set menutitle [lindex $args [expr {$i+1}]]
		incr i
	    }
	    set items [lindex $args [expr {$i +1}]]
	    set curr [lindex $items 0]
	    set items [lrange $items 1 end]
	    if {![llength $items]} { 
		if {$curr eq ""} {
		    label $w.d$j -text "(no options available)"
		} else {
		    label $w.d$j -text "$curr"
		}
		set ${dial}(var$val) $curr
		lappend items $curr
	    } else {
		if {[lsearch -exact $items $curr] == -1} {
		    set curr [lindex $items 0]
		}
		set ${dial}(var$val) $curr
		if {$type eq "-tab"} {
		    set style "tabbed"
		} elseif {$type eq "-multipane"} {
		    set style "multipane"
		} else {
		    set style "popup"
		}
		switch -- $style {
		    "multipane" {
			alpha::ensureBWidgetLoaded PagesManager
			#package require BWidget
			PagesManager $w.d$j
			foreach item $items {
			    $w.d$j add $item
			}
			set ${dial}(isType($val)) [list PagesManager $w.d$j]
			set ${dial}(isType($w.d$j)) "PagesManager"
		    }
		    "popup" {
			# Alpha's option-menus auto-shrink to the size of
			# the largest item they contain, so we cheat
			if {$type ne "-m"} { 
			    #set auto_size 1 
			}
			# Make the option menu.
			eval [list alpha_optionMenu $w.d$j ${dial}(var$val)] \
			  $items
		    }
		    "tabbed" {
			if {$::alpha::theming} {
			    ttk::notebook $w.d$j
			    set npage 0
			    foreach item $items {
				::ttk::frame $w.d$j.p$npage
				catch {$w.d$j.p$npage configure -style Toolbar}
				$w.d$j add $w.d$j.p$npage -text $item
				if {$npage == 0} {
				    $w.d$j select $w.d$j.p$npage
				}
				incr npage
			    }
			    bind $w.d$j <<NotebookTabChanged>> \
			      "set \"${dial}(var$val)\" \"\[$w.d$j tab current -text\]\""
			} else {
			    alpha::ensureBWidgetLoaded NoteBook
			    #package require BWidget
			    NoteBook $w.d$j -ibd 0 -side top
			    foreach item $items {
				$w.d$j insert end $item \
				  -text $item
			    }
			    $w.d$j bindtabs <Button-1> "set \"${dial}(var$val)\" "
			    set ${dial}(isType($val)) [list NoteBook $w.d$j]
			    set ${dial}(isType($w.d$j)) "NoteBook"
			}
		    }
		    default {
			error "Bad style $style"
		    }
		}
		if {$style eq "popup" && $type eq "-menu"} {
		    # This is not a pager by default
		} else {
		    if {![llength [set ${dial}(pagevars)]]} {
			if {$style ne "multipane"} {
			    bind [winfo toplevel $w] <Down> \
			      "dialog_pane_change $dial $w 1 var$val cursor"
			    bind [winfo toplevel $w] <Up> \
			      "dialog_pane_change $dial $w -1 var$val cursor"
			    bind [winfo toplevel $w] <MouseWheel> \
			      "dialog_pane_change $dial $w \[expr {%D > 0 ? -1 : 1}\] var$val cursor"
			}
		    }
		    lappend ${dial}(pagevars) var$val
		    set ${dial}(pager,var$val) [list $style $w.d$j $items]
		}
	    }
	    incr val
	    incr i 2
	}
	"-M" {
	    incr i
	    continue
	}
	"-v" {
	    incr i
	    continue
	}
	"-title" - 
	"-T" {
	    set title [lindex $args [expr {$i +1}]]
	    incr i 2
	    continue
	}
	"-radioGroup" {
	    puts stderr "dialog option -radioGroup ignored"
	    incr i 5
	    continue
	}
	"-p" {
	    #echo "dialog option -p ignored"
	    incr i 5
	    continue
	}
	"-in" -
	"-n" {
	    set pname [lindex $args [expr {$i +1}]]
	    set got_page 0
	    foreach pvar [set ${dial}(pagevars)] {
		set items [lindex [set ${dial}(pager,$pvar)] 2]
		if {[lsearch -exact $items $pname] != -1} {
		    set got_page 1
		    break
		}
	    }
	    if {!$got_page} {
		if {$pname eq ""} {
		    # Cancel the page-ness if the page name is empty and
		    # there is no empty page name.
		    set in $w
		} else {
		    #puts stderr "Unknown pane name \"$pname\" in dialog"
		    #error "Unknown pane name \"$pname\" in dialog"
		}
	    } else {
		set f [dialog_pageitem_to_frame $dial \
		  [dialog::_makeSubf $w $pvar] \
		  $pvar $pname]
		if {![winfo exists $f]} {
		    # Some multi-page widgets will have already created
		    # a window for us
		    ::ttk::frame $f
		}
		if {$in eq $w} {
		    trace add variable ${dial}($pvar) write \
		      [list ::dialog_pane_change $dial $w]
		}
		set in $f
	    }
	    incr i 2
	    continue
	}
	"-help" {
	    # We have usually extracted the help in advance.
	    if {![info exists help]} {
		set help [lindex $args [expr {$i +1}]]
	    }
	    incr i 2
	    continue
	}
	"-radiobutton" -
	"-r" {
	    set te [lindex $args [expr {$i +1}]]
	    set ${dial}(var$val) "radiobutton $te"
	    radiobutton $w.d$j -text $te \
	      -value $te -anchor w 
	    if {[lindex $args [expr {$i+2}]]} {
		set ${dial}(dialog::selectedButton) $te
	    }
	    incr val
	    incr i 3
	}
	"-tag" - "-action" - "-font" - "-set" - "-state" -
	"-delay" - "-drop" - "-drag" {
	    set actOnPrevious 1
	}
	"" {
	    # Usually only reached if we have a multi-page dialog
	    # which ends immediately after a new page, and isn't
	    # robustly constructed.
	    break
	}
	default {
	    #echo "dialog $args"
	    destroy [winfo toplevel $w]
	    error "dialog argument [lindex $args $i] not handled ($args)"
	}
    }
    if {![info exists nothingYet]} {
	if {[lsearch -exact [list -t -p] $type] == -1} {
	    # This is the first active item
	    set nothingYet [list bind [winfo toplevel $w] <KeyPress> \
	      "dialog::a_key $w.d$j %A"]
	}
    }

    while {1} {
	# Find index of current item -- this depends on whether
	# we have already seen the l r t b arguments and placed
	# the item or not (i.e. if the -drop, or -action is before
	# or after the position).
	if {[info exists actOnPrevious]} {
	    set jj [expr {$j -1}]
	} else {
	    set jj $j
	}
	set lval [expr {$val -1}]
	if {[lindex $args $i] == "-drag"} {
	    incr i
	    set dndArgs [lindex $args $i]
	    set mimetypes [lindex $dndArgs 0]
	    if {[llength $mimetypes]} {
		set cmdCheck [lindex $dndArgs 1]
		set cmdDone [lindex $dndArgs 2]
		set items [dialog_controlTags $jj [lindex $dndArgs 3]]
		# Only set up the drag-drop stuff when the widget
		# is mapped
		bind $w.d$jj <Map> [list ::dialog::bindDrag $dial $w.d$jj \
		  $items $cmdDone $cmdCheck $mimetypes]
	    }
	    # Not yet supported.
	    incr i
	    continue
	}
	if {[lindex $args $i] == "-drop"} {
	    # dialog::findApp foo
	    incr i
	    set dndArgs [lindex $args $i]
	    set mimetypes [lindex $dndArgs 0]
	    if {[llength $mimetypes]} {
		set cmdCheck [lindex $dndArgs 1]
		set cmdSet [lindex $dndArgs 2]
		set items [dialog_controlTags $jj [lindex $dndArgs 3]]
		# Only set up the drag-drop stuff when the widget
		# is mapped
		bind $w.d$jj <Map> [list ::dialog::bindDrop $dial $w.d$jj \
		  $items $cmdSet $cmdCheck $mimetypes]
	    }
	    incr i
	    continue
	}
	if {([lindex $args $i] == "-set") \
	  || ([lindex $args $i] == "-action")} {
	    # takes '{cmd {index ... index}}'
	    set setArgs [lindex $args [expr {$i +1}]]
	    set cmdScript [lindex $setArgs 0]
	    set items [dialog_controlTags $jj [lindex $setArgs 1]]
	    if {([lindex $args $i] == "-set")} {
		if {[llength $items] != 1} {
		    # Hopefully relax this in the future
		    return -code error \
		      "'-set' option must have exactly one index"
		}
		trace add variable ${dial}(var$lval) write \
		  [list ::dialog::triggerSet $dial $items $cmdScript]
		if {[dialog::classIs $w.d$jj "Button"]} {
		    $w.d$jj configure -command "set ${dial}(var$lval) 0"
		}
	    } else {
		trace add variable ${dial}(var$lval) write \
		  [list ::dialog::triggerAction $dial $items $cmdScript]
		if {[dialog::classIs $w.d$jj "Button"]} {
		    $w.d$jj configure -command "set ${dial}(var$lval) 0"
		}
	    }
	    if {$havebutton == $jj} {
		set havebutton ""
	    }
	    incr i 2
	    continue
	}
	if {[lindex $args $i] == "-delay"} {
	    # A delay flag makes a button disabled until a certain time
	    set time [lindex $args [incr i]]
	    incr i
	    $w.d$jj configure -state disabled
	    after $time \
	      [list catch [list $w.d$jj configure -state active]]
	    continue
	}
	if {[lindex $args $i] == "-state"} {
	    incr i
	    if {[lindex $args $i]} {
		catch {$w.d$jj configure -state normal}
	    } else {
		catch {$w.d$jj configure -state disabled}
	    }
	    incr i
	    continue
	}
	if {[lindex $args $i] == "-tag"} {
	    incr i
	    set tagname [lindex $args $i]
	    set ${dial}(tag,$tagname) $jj
	    incr i
	    continue
	}
	if {[lindex $args $i] == "-font"} {
	    # ignore font specifications for the moment.
	    incr i
	    set fnt [lindex $args $i]
	    if {[tk windowingsystem] eq "aqua" && $fnt == 2} {
		catch {$w.d$jj configure -font "system 11"}
		catch {$w.d$jj configure -style Small.[winfo class $w.d$jj]}
		#alpha::stderr "making $w.d$jj [winfo class $w.d$jj] small"
	    }
	    incr i
	    continue
	}
	break
    }
    if {[info exists actOnPrevious]} {
	unset actOnPrevious
	# Go back up to the top, looking for the next actual
	# dialog item
	continue
    }

    if {![catch {$w.d$j cget -takefocus} takefocus]} {
	$w.d$j configure -takefocus [list ::dialog::takesFocus $takefocus]
    }
    
    foreach {l t r b} [lrange $args $i [expr {$i+3}]] {}
    if {[info exists doWrap]} {
	set wrapLength [distanceToScreen [expr {$r - $l - $doWrap}]]
	catch {$w.d$j configure -wraplength $wrapLength -justify left}
	if {($wrapLength > 0) && ([winfo class $w.d$j] eq "TCheckbutton")} {
	    # Tile: Wraplength not properly supported
	    if {0} {
		$w.d$j configure -text \
	      [alpha::fakeWrap $wrapLength \
	      [$w.d$j cget -font] [$w.d$j cget -text]]
	    }
	}
	unset doWrap
    }
    #puts [list $l $t $r $b]
    # Special password handling
    if {[info exists eheight]} {
	if {$show != ""} {
	    if {($b - $t) < 10} {incr b 10}
	}
	if {$::alpha::macos == 2} {
	    incr t -2 ; incr b 2
	}
 	unset eheight
    }
    if {[info exists storeCoordinates]} {
	set ${dial}($storeCoordinates) [list \
	  [distanceToScreen $l] \
	  [distanceToScreen $t]]
	unset storeCoordinates
    }
    if {[info exists hide]} {
	unset hide
	# Do nothing
    } elseif {[info exists auto_size]} {
	if {[info exists menutitle]} {
	    label $w.dm$j -text $menutitle
	    set lwidth [winfo reqwidth $w.dm$j]
	    place $w.dm${j} -in $in \
	      -x [distanceToScreen $l] \
	      -y [distanceToScreen $t] -height \
	      [distanceToScreen [expr {$b - $t}]]
	    incr l [screenToDistance $lwidth]
	    unset menutitle
	}
	place $w.d$j -in $in \
	  -x [distanceToScreen $l] \
	  -y [distanceToScreen $t] \
	  -height [distanceToScreen [expr {$b -$t}]]
	unset auto_size
    } else {
	if {[info exists menutitle]} {
	    label $w.dm$j -text $menutitle
	    set lwidth [winfo reqwidth $w.dm$j]
	    place $w.dm${j} -in $in \
	      -x [distanceToScreen $l] \
	      -y [distanceToScreen $t] -height \
	      [distanceToScreen [expr {$b - $t}]]
	    incr l [screenToDistance $lwidth]
	    unset menutitle
	}
	if {($r == $l)} {
	    place $w.d$j -in $in \
	      -x [distanceToScreen $l] \
	      -y [distanceToScreen $t]
	    set r [expr {[distanceToScreen $l] + [winfo reqwidth $w.d$j]}]
	} else {
	    set r [distanceToScreen $r]
	}
	set hh [expr {$b - $t}]
	if {$j == $havebutton && $hh < 21 \
	  && ($tcl_platform(platform) != "windows") \
	  && ([tk windowingsystem] ne "aqua")} {
	    set hdiff [expr {26 - $hh}]
	    set t [expr {$t - $hdiff/2}]
	    set hh 26
	}
	set ww [expr {$r - [distanceToScreen $l]}]
	if {[info exists dialog::scripts($type)]} {
	    eval $dialog::scripts($type)
	}
	place $w.d$j -in $in \
	  -x [distanceToScreen $l] \
	  -y [distanceToScreen $t] \
	  -width $ww -height [distanceToScreen $hh]
	if {[winfo exists $w.dscroll$j]} {
	    set sub [default::size scrollbarwidth]
	    place $w.d$j -width [expr {$ww - $sub}]
	    place $w.dscroll$j -in $in \
	      -x [expr {[distanceToScreen $l] + $ww - $sub}] \
	      -y [distanceToScreen $t] \
	      -height [distanceToScreen $hh]
	}
    }
    if {![catch {$in cget -style} parentStyle] && ($parentStyle eq "Toolbar")} {
	#puts $parentStyle
    }
    
    bindtags $w.d$j [concat [list "OverallDialog"] [bindtags $w.d$j]]
    incr i 4
    set noHelpFor [list -t -p -l -text -staticText -separator]
    if {[info exists help]} {
	if {[lsearch -exact $noHelpFor $type] == -1} {
	    # add the first help index
	    set helpitem [lindex $help 0]
	    set help [lrange $help 1 end]
	    if {$helpitem ne ""} {
		eval balloon::help $w.d$j [split $helpitem "|"]
	    }
	}
    }
    incr j

    # reached end?
    if {[lindex $args $i] == ""} {break}
    
    # End while:
    }
}

if {[tk windowingsystem] eq "aqua"} {
    # The reqwidth of checkbuttons seems to ignore the need for the actual
    # box to click on.
    set dialog::scripts(-c) {
	set hhh [winfo reqheight $w.d$j]
	if {$hh < $hhh} { set hh $hhh } 
	set www [expr {10+[winfo reqwidth $w.d$j]}]
	if {$ww < $www} { set ww $www } 
    }
    set dialog::scripts(-b) {
	if {$::alpha::theming && ([$w.d$j cget -style] == "Small.TButton")} {
	    if {$hh < 21} { set hh 21 }
	} else {
	    if {$hh < 24} { set hh 24 }
	}
	#set www [winfo reqwidth $w.d$j] ; if {$ww < $www} { set ww $www } 
	set www [winfo reqwidth $w.d$j] ; if {$ww < $www} { incr ww 5 } 
    }
    #set hhh [winfo reqheight $w.d$j] ; if {$hh < $hhh} { set hh $hhh } 
}

# experimental
proc dialog::notebook {x yy item {def "def"} {requestedWidth 0}} { 
    upvar 1 $yy y
    set m [concat [list $def] $item]
    if {$requestedWidth == 0} {
	set popUpWidth 340
    } else {
	set popUpWidth $requestedWidth 
    }
    
    metrics Metrics
    set res [list -tab $m $x $y [expr {$x + $popUpWidth}] \
      [expr {$y +$Metrics(PopupButtonHeight) + 7}]]
    incr y $Metrics(PopupButtonHeight)
    incr y 10
    return $res
}

proc dialog::classIs {w class} {
    if {![winfo exists $w]} { return 0 }
    set cl [winfo class $w]
    if {$cl eq $class} { 
	return 1 
    } elseif {$cl eq "T$class"} {
        return 1
    } else {
        return 0
    }
}

proc dialog::_makeSubf {w id} {
    return $w.subf[_cleanName $id]
}

proc dialog::_cleanName {id} {
    string map {( X ) X . X * X " " _} $id
}

proc dialog::itemList {dial items} {
    global $dial
    
    set w [set ${dial}(window)]

    set res {}
    foreach item $items {
	if {![string is integer $item]} {
	    if {![info exists ${dial}(tag,$item)]} {
		return -code error "No such tag '$item' registered"
	    }
	    set item [set ${dial}(tag,$item)]
	}
	lappend res "$w.d$item"
    }
    return $res
}

proc dialog::bindDrop {dial widg items cmdSet cmdCheck mimetypes} {
    global $dial
    
    set cmds {}
    foreach item [itemList $dial $items] {
	lappend cmds [getDialogGetOrSetter $dial $item]
    }
    lappend cmdSet $cmds
    BindDropOnDialogItem $widg $cmdSet $cmdCheck $mimetypes 30
}

proc dialog::bindDrag {dial widg items cmdDone cmdCheck mimetypes} {
    global $dial
    
    set cmds {}
    foreach item [itemList $dial $items] {
	lappend cmds [getDialogGetOrSetter $dial $item]
    }
    lappend cmdDone $cmds
    BindDragFromDialogItem $widg $cmdDone $cmdCheck $mimetypes 30
}

# Copy of Tk's private 'tk::TabToWindow'.
proc dialog::tabToWindow  {w} {
    set focus [focus]
    if {$focus ne ""} {
	event generate $focus <<TraverseOut>>
    }
    if {[dialog::classIs $w Entry]} {
	$w selection range 0 end
	$w icursor end
    } elseif {[dialog::classIs $w Text]} {
	$w tag add sel 1.0 end-1c
	$w mark set insert end-1c
    }
    focus $w
    event generate $w <<TraverseIn>>
}

# Handles two things: first it ensures we don't think we've lost
# the focus just because a window has appeared, and second it
# sets the -parent for the dialog.  On MacOS X, if the status bar
# is the parent, it doesn't use it for the parent, and instead just
# ensures the dialog is placed in the default manner.
proc alpha::externalDialog {args} {
    variable Priv
    set Priv(lostFocusIgnore) 1

    set parent [dialog::findParent]
    set parentargs [list -parent $parent]
    if {([tk windowingsystem] eq "aqua") && ($parent eq ".")} {
	set parentargs {}
    }
    set code [catch [concat $args $parentargs] result]
    unset Priv(lostFocusIgnore)
    return -code $code $result
}

proc alpha::forceFocus {w} {
    if {[tk windowingsystem] == "aqua"} { 
	raise [winfo toplevel $w]
	focus -force $w
	update idletasks
    } else {
	focus -force $w
    }
}

# Used to help perform over-rides of events.  We want 'Return' and
# 'Tab' in a dialog to have a special effect, but then we want the
# user to be able to use 'Control-Return/Tab' for the original
# purpose of Tab/Return.
proc dialog::redirectToFocus {event} {
    set w [focus]
    if {$w == ""} {return}
    #puts "redirect $w $event"
    set tags [bindtags $w]
    set idx [lsearch -exact $tags "OverallDialog"]
    if {$idx < 0} {
	event generate $w $event
	return
    }
    bindtags $w [lreplace $tags $idx $idx]
    catch {event generate $w $event}
    catch {
	bindtags $w $tags
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::a_key" --
 # 
 #  When the user presses a straightforward key in a dialog, this procedure
 #  is called.  If the first item in the dialog is suitable for keyboard
 #  matching (e.g. it is a popup menu or a listbox), we try to match
 #  the item the user is spelling out.
 # -------------------------------------------------------------------------
 ##
proc dialog::a_key {w key} {
    variable string_so_far
    #puts stdout "$w $key [winfo class $w]"
    if {[lsearch -exact [list Menubutton Listbox] [winfo class $w]] == -1} {
	return
    }
    append string_so_far $key
    #puts stderr $string_so_far
    after cancel [list set dialog::string_so_far ""]
    after 1000 [list set dialog::string_so_far ""]
    switch -- [winfo class $w] {
	"TMenubutton" -
	"Menubutton" {
	    set m [$w cget -menu]
	    set last [$m index end]
	    for {set i 0} {$i < $last} {incr i} {
		if {![catch {$m entrycget $i -label} label]} {
		    regsub -all " " [string tolower $label] "" item
		    if {[string first $string_so_far $item] == 0} {
			$m invoke $i
			return
		    }
		}
	    }
	}
	"Listbox" {
	    set last [$w index end]
	    for {set i 0} {$i < $last} {incr i} {
		regsub -all " " [string tolower [$w get $i]] "" item
		if {[string first $string_so_far $item] == 0} {
		    set cur [$w curselection]
		    if {[llength $cur]} {
			eval $w selection clear $cur
		    }
		    $w selection set $i
		    $w see $i
		    return
		}
	    }
	}
    }
}

proc dialog::takesFocus {origOption w} {
    if {![isViewable $w]} {
	return 0
    }
    if {$origOption ne "" && ![string is integer $origOption]} {
	return [uplevel #0 $origOption [list $w]]
    }
    return ""
}

proc dialog::isViewable {w} {
    if {![winfo exists $w]} { return 0 }
    set W [winfo toplevel $w]
    set X [expr {[winfo x $W] + [winfo width $W]}]
    set Y [expr {[winfo y $W] + [winfo height $W]}]
    if {![winfo viewable $w] || ([winfo x $w] > $X) \
      || ([winfo y $w] > $Y)} {
	return 0
    } else {
        return 1
    }
}

proc dialog::cmd_key {w key} {
    set key [string tolower $key]
    foreach child [winfo children $w] {
	if {![isViewable $child]} {
	    continue
	}
	
	set class [winfo class $child]
	switch -- $class {
	    "TFrame" - 
	    "Frame" {
		if {[cmd_key $child $key]} {
		    return 1
		}
	    }
	    "TCheckbutton" -
	    "TButton" -
	    "Checkbutton" -
	    "Button" {
		set match 0
		set text [$child cget -text]
		if {[string length $key] > 1} {
		    set match [expr {[string tolower $text] eq $key}]
		} elseif {[string tolower [string index $text 0]] eq $key} {
		    set match 1
		}
		if {$match} {
		    # contents of tk::ButtonInvoke
		    if {[string compare [$child cget -state] "disabled"]} {
			#ttk
			catch {
			    set oldRelief [$child cget -relief]
			    set oldState [$child cget -state]
			    $child configure -state active -relief sunken
			    update idletasks
			    after 100
			    $child configure -state $oldState -relief $oldRelief
			}
			uplevel #0 [list $child invoke]
		    }
		    return 1
		}
	    }
	}
    }
    return 0
}

proc dialog::haveNewWindow {} {
    variable noNewWindow
    foreach arr [array names noNewWindow] {
	set noNewWindow($arr) 0
    }
}

proc dialog::getFocus {w} {
    set to [focus]
    if {[string first ".dl" $to] == -1} {
	variable noNewWindow
	if {[info exists noNewWindow($w,$to)]} {
	    puts stderr "again $noNewWindow($w,$to) $w $to"
	}
	set noNewWindow($w,$to) 1
    }
    return $to
}

proc dialog::restoreFocus {w to} {
    variable noNewWindow

    if {[string first ".dl" $to] != -1} {
	# We probably have nested dialogs, we need to be
	# careful to restore the focus to the dialog underneath.
	if {[winfo exists $to]} {
	    catch {focus $to}
	    return
	}
    }
    
    if {[info exists noNewWindow($w,$to)]} {
	if {!$noNewWindow($w,$to)} {
	    # We got a new window in the mean-time, so we mustn't
	    # restore the focus to the old one.
	    unset noNewWindow($w,$to)
	    return
	}
	unset noNewWindow($w,$to)
    }

    if {![catch {win::Current} cw]} {
	catch {text_wcmd $cw takeFocus}
    } else {
	catch {focus $to}
    }
}

# These two procs have to destroy .startup at least under
# Gnome on Linux, otherwise startup messages/errors are
# hidden underneath the splash screen.
proc dialog::findRoot {} {
    set root [focus]
    if {[string length $root] < 2 || [string first ".balloon" $root] == 0} {
	set root ""
    }
    if {[winfo exists .startup]} {
	global tcl_platform
	if {$tcl_platform(platform) == "unix" \
	  && [tk windowingsystem] ne "aqua"} {
	    destroy .startup
	    return ""
	}
	return .startup
    } else { 
	return $root
    }
}

proc dialog::findParent {} {
    set root [focus]
    if {![string length $root] || [string first ".balloon" $root] == 0} {
	set root .
    }
    if {[winfo exists .startup]} {
	global tcl_platform
	if {$tcl_platform(platform) == "unix" \
	  && [tk windowingsystem] ne "aqua"} {
	    destroy .startup
	    return .
	}
	return .startup
    } else {
	if {[string first .status $root] != -1} {
	    return .
	} else {
	    return $root
	}
    }
}

proc dialog::getDialogGetOrSetter {dial item} {
    global $dial

    set type [winfo class $item]
    if {[info exists ${dial}(isType($item))]} {
	set type [set ${dial}(isType($item))]
    }
    switch -- $type {
	"Listitem" {
	    return [list ::dialog::listitemGetOrSetContents $item]
	}
	"List" - "Listbox" {
	    return [list ::dialog::listboxGetOrSetContents $item]
	}
	"TLabel" - "TButton" - 
	"Label" - "Button" {
	    return [list ::dialog::labelGetOrSetContents $item]
	}
	"Entry" - "TEntry" {
	    return [list ::dialog::entryGetOrSetContents $item]
	}
	"Text" {
	    return [list ::dialog::textGetOrSetContents $item]
	}
	"TCheckbutton" - "TRadiobutton" {
	    return [list ::dialog::tcheckbuttonGetOrSetContents $item]
	}
	"Checkbutton" - "Radiobutton" {
	    return [list ::dialog::checkbuttonGetOrSetContents $item]
	}
	"Menubutton" - "TMenubutton" {
	    return [list ::dialog::menubuttonGetOrSetContents $item]
	}
	"TNotebook" {
	    return [list ::dialog::tnotebookGetOrSetContents $item]
	}
	"NoteBook" - "PagesManager" {
	    return [list ::dialog::notebookGetOrSetContents $item]
	}
	default {
	    # Could throw error I suppose
	    puts stderr "No known getter/setter for [winfo class $item]"
	    return
	}
    }
}

proc dialog::triggerSet {dial items cmdScript var elt op} {
    set item [lindex [itemList $dial $items] 0]
    set setCmd [getDialogGetOrSetter $dial $item]

    if {[catch {dialog::itemSet $setCmd $cmdScript} err]} {
	::error::occurred $err
    }
}

proc dialog::triggerAction {dial items cmdScript var elt op} {
    set getOrSetCmds {}

    foreach i [itemList $dial $items] {
	set cmd [list ::dialog::actionGetOrSet $dial $i $i]
	lappend getOrSetCmds $cmd
    }

    if {[catch {eval $cmdScript [list $getOrSetCmds]} err]} {
	::error::occurred $err
    }
}

proc setControlInfo {id attribute val} {
    set item [lindex $id 2]
    set dial [lindex $id 1]
    if {$item eq ""} { 
	set item [lindex $id 1] 
    }
    set setCmd [dialog::getDialogGetOrSetter $dial $item]
    set control [lindex $setCmd 1]

    switch -- $attribute {
	"state" {
	    if {$val} {
		$control configure -state normal
	    } else {
		$control configure -state disabled
	    }
	}
	"value" {
	    eval $id [list $val]
	}
	"font" {
	    $control configure -font $val
	}
	"contents" {
	    # Only works for listboxes so far.
	    $control delete 0 end
	    eval [linsert $val 0 $control insert 0]
	}
	"help" {
	    eval [list ::balloon::help $control] [split $val "|"]
	}
	default {
	    return -code error "Bad attribute \"$attribute\", should be\
	      state, value, contents, font or help."
	}
    }
}

proc getControlInfo {id attribute} {
    set item [lindex $id 2]
    set dial [lindex $id 1]
    if {$item eq ""} { 
	set item [lindex $id 1] 
    }
    set setCmd [dialog::getDialogGetOrSetter $dial $item]
    set control [lindex $setCmd 1]

    switch -- $attribute {
	"state" {
	    if {[$control cget -state] == "normal"} {
		return 1
	    } else {
		return 0
	    }
	}
	"value" {
	    return [eval $id]
	}
	"font" {
	    return [$control cget -font]
	}
	"contents" {
	    # Only works for listboxes so far.
	    return [$control get 0 end]
	}
	"help" {
	    return [join [balloon::help $control] "|"]
	}
	default {
	    return -code error "Bad attribute \"$attribute\", should be\
	      state, value, contents, font or help."
	}
    }
}

proc setControlValue {id val} {
    eval $id [list $val]
}

proc getControlValue {id} {
    eval $id
}

proc abbreviateText {font str width} {
    if {$font eq ""} { return $str }
    global dialog::ellipsis
    set ratio 0.33
    if {[screenToDistance [font measure $font $str]] <= $width} then {return $str}
    set tw [expr {$width - [screenToDistance [font measure $font ${dialog::ellipsis}]]}]
    set lower -1
    set upper [expr {[string length $str] - 1}]
    set t [expr {$ratio * $tw}]
    while {$upper - $lower > 1} {
       set middle [expr {($upper + $lower) / 2}]
       if {[screenToDistance [font measure $font [string range $str 0 $middle]]] > $t}\
       then {set upper $middle} else {set lower $middle}
    }
    set abbr [string range $str 0 $lower]
    append abbr ${dialog::ellipsis}
    set upper [string length $str]
    set t [expr {(1 - $ratio) * $tw}]
    while {$upper - $lower > 1} {
       set middle [expr {($upper + $lower) / 2}]
       if {[screenToDistance [font measure $font [string range $str $middle end]]] > $t}\
       then {set lower $middle} else {set upper $middle}
    }
    append abbr [string range $str $upper end]
}

proc getControlStyle {id arr} {
    set w [lindex $id 1]
    upvar 1 $arr local
    set local(type) [winfo class $w]
    set local(font) [$w cget -font]
}

# Handle -action callbacks.  May in the future be better
# to deal with 'index', 'dial', for example!
proc dialog::actionGetOrSet {dial index item args} {
    set setCmd [getDialogGetOrSetter $dial $item]
    if {[llength $setCmd]} {
	return [eval $setCmd $args]
    } else {
	alertnote "dialog::actionGetOrSet unsupported error,\
	  [winfo class $item], $dial $item $args"
    }
}

# Also used for radiobuttons
proc dialog::checkbuttonGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    return [set [$w cget -variable]]
	}
	1 {
	    if {[lindex $args 0]} {
		$w select
	    } else {
		$w deselect
	    }
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::tcheckbuttonGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    return [uplevel \#0 [list set [$w cget -variable]]]
	}
	1 {
	    if {[lindex $args 0]} {
		uplevel \#0 [list set [$w cget -variable] 1]
	    } else {
		uplevel \#0 [list set [$w cget -variable] 0]
	    }
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::textGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    return [$w get 1.0 end-1c]
	}
	1 {
	    set val [lindex $args 0]
	    $w delete 1.0 end
	    $w insert 1.0 $val
	    $w tag add sel 1.0 end-1c  
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::entryGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    return [$w get 0 end]
	}
	1 {
	    set val [lindex $args 0]
	    $w delete 0 end
	    $w insert 0 $val
	    $w selection range 0 end
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::menubuttonGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    return [uplevel \#0 [list set [$w cget -textvariable]]]
	}
	1 {
	    uplevel \#0 [list set [$w cget -textvariable] [lindex $args 0]]
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

# Also used for buttons
proc dialog::labelGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    return [$w cget -text]
	}
	1 {
	    set val [lindex $args 0]
	    set width [winfo width $w]
	    #tile
	    if {![catch {$w cget -font} font]} {
		if {$font ne ""} {
		    set valwidth [font measure $font $val]
		    #puts [list $w $var $width $valwidth]
		    if {$valwidth > $width} {
			return -code error [screenToDistance $width]
		    }
		}
	    }
	
	    set view $val
	    $w configure -text $view
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::listboxGetOrSetContents {w args} {
    #puts [list dialog::listboxGetOrSetContents $w $args]
    switch -- [llength $args] {
	0 {
	    return [$w get 0 end]
	}
	1 {
	    set val [lindex $args 0]
	    $w delete 0 end
	    eval [list $w insert end] [split $val \r]
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::tnotebookGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    return [$w tab current -text]
	}
	1 {
	    set val [lindex $args 0]
	    foreach tpage [$w tabs] {
		if {[$w tab $tpage -text] eq $val} {
		    $w select $tpage
		    return ""
		}
	    }
	    error "No known page $val"
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::notebookGetOrSetContents {w args} {
    switch -- [llength $args] {
	0 {
	    set val [$w raise]
	    # Now convert this to the previous name
	    
	    return [$w raise]
	}
	1 {
	    set val [lindex $args 0]
	    $w raise $val
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

proc dialog::listitemGetOrSetContents {w args} {
    #puts [list dialog::listitemGetOrSetContents $w $args]
    switch -- [llength $args] {
	0 {
	    if {[$w cget -selectmode] eq "extended"} {
		# Multi-item selection - result is a list
		# of items.
		set lres [list]
		foreach v [$w curselection] {
		    lappend lres [$w get $v]
		}
		return $lres
	    } else {
		# Single item selection - result is the item
		if {[$w curselection] ne ""} {
		    return [$w get [$w curselection]]
		} else {
		    return {}
		}
	    }
	}
	1 {
	    set val [lindex $args 0]
	    # Not quite implemented
	    if {[$w cget -selectmode] ne "extended"} {
		set val [list $val]
	    }
	    set vals [$w get 0 end]
	    set indices {}
	    foreach v $val {
		set idx [lsearch -exact $vals $v]
		if {$idx == -1} {
		    puts stderr "Bad val $v"
		} else {
		    lappend indices $idx
		}
	    }
	    $w selection clear 0 end
	    if {[llength $indices]} {
		eval [list $w selection set] $indices
	    }
	    return ""
	}
	default {
	    return -code error "Too many arguments"
	}
    }
}

# Following proc modified from:
# optMenu.tcl --
#
# This file defines the procedure tk_optionMenu, which creates
# an option button and its associated menu.
#
# RCS: @(#) $Id: alpha_dialogs.tcl,v 1.8 2006/04/19 22:43:03 vincentdarley Exp $
#
# Copyright (c) 1994 The Regents of the University of California.
# Copyright (c) 1994 Sun Microsystems, Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# tk_optionMenu --
# This procedure creates an option button named $w and an associated
# menu.  Together they provide the functionality of Motif option menus:
# they can be used to select one of many values, and the current value
# appears in the global variable varName, as well as in the text of
# the option menubutton.  The name of the menu is returned as the
# procedure's result, so that the caller can use it to change configuration
# options on the menu or otherwise manipulate it.
#
# Arguments:
# w -			The name to use for the menubutton.
# varName -		Global variable to hold the currently selected value.
# args -		Any number of values for the option, must be >= 1,
#                       and at least one must be non-dimmed.

proc alpha_optionMenu {w varName args} {
    global multiColumnMenusEveryNItems
    upvar #0 $varName var

    foreach firstVal $args {
	if {!([string index $firstVal 0] == "\(")} {
	    set firstValue $firstVal
	    break
	}
    }
    if {![info exists firstValue]} {
	error "No legal value for option menu given!"
    }
    if {![info exists var]} {
	set var $firstValue
    }
    if {$::alpha::theming} {
	::ttk::menubutton $w -textvariable $varName -menu $w.menu \
	  -direction flush
    } else {
	menubutton $w -textvariable $varName -indicatoron 1 -menu $w.menu \
	  -relief raised -borderwidth 2 -highlightthickness 2 -anchor c \
	  -direction flush
    }
    menu $w.menu -tearoff 0
    set count $multiColumnMenusEveryNItems
    foreach i $args {
	incr count -1
	if {$i eq "-"} {
	    $w.menu add separator
	} else {
	    $w.menu add radiobutton -label $i -variable $varName
	    if {$count < 0} {
		set count $multiColumnMenusEveryNItems
		$w.menu entryconfigure $i -columnbreak 1
	    }
	}
    }
    return $w.menu
}

proc dialog_pageitem_to_frame {dial prefix elt name} {
    global $dial
    set style [lindex [set ${dial}(pager,$elt)] 0]
    set controller [lindex [set ${dial}(pager,$elt)] 1]
    switch -- $style {
	"popup" {
	    # Have to get rid of extra '.' or ' ' which happen to be in the name
	    set fr [dialog::_cleanName $name]
	    set pane $prefix$fr
	    return $pane
	}
	"tabbed" {
	    if {$::alpha::theming} {
		foreach npage [$controller tabs] {
		    if {[$controller tab $npage -text] eq $name} {
			return $npage
		    }
		}
		error "No page known"
	    } else {
		return [$controller getframe $name]
	    }
	}
	"multipane" {
	    return [$controller getframe $name]
	}
	"labelframe" {
	    # Only one page, which is the frame itself
	    return $controller
	}
	"popupgroupbox" {
	    return  [[lindex $controller 1] getframe $name]
	}
	default {
	    error "Bad page style $style"
	}
    }
}

proc dialog_pane_change {dial w dmy elt op} {
    global $dial
    if {$op == "cursor"} {
	# we used a cursor key
	set items [lindex [set ${dial}(pager,$elt)] 2]
	set idx [lsearch -exact $items [set ${dial}($elt)]]
	set len [llength $items]
	while {1} {
	    # we don't wrap around (else could use: ($idx + $dmy +$len)%$len )
	    incr idx $dmy
	    if {$idx < 0 || $idx >= $len} {
		return
	    }
	    # Don't stop on separators
	    if {![regexp -- {^(\(|-$)} [lindex $items $idx]]} {
		break
	    }
	}
	set ${dial}($elt) [lindex $items $idx]
	return
    } elseif {$op == "cycle"} {
	# Used to work around bug in Windows dnd.
	set orig [set ${dial}($elt)]
	set items [lindex [set ${dial}(pager,$elt)] 2]
	set len [llength $items]
	for {set idx 0} {$idx < $len} {incr idx} {
	    if {![regexp -- {^(\(|-$)} [lindex $items $idx]]} {
		set ${dial}($elt) [lindex $items $idx]
		update idletasks
	    }
	}
	set ${dial}($elt) $orig
	return
    }
    set style [lindex [set ${dial}(pager,$elt)] 0]
    switch -- $style {
	"multipane" {
	    dialog_multipane_pane_change $dial $w $elt
	}
	"popup" {
	    dialog_popup_pane_change $dial $w $elt
	}
	"popupgroupbox" {
	    dialog_popupgroupbox_pane_change $dial $w $elt
	}
	"tabbed" {
	    dialog_tabbed_pane_change $dial $w $elt
	}
	"labelframe" {
	    # No change needed
	}
	default {
	    error "Bad page style '$style'"
	}
    }
}

proc dialog_overrideListbox {dial lb items} {
    global $dial
    lappend ${dial}(deleteCommands) $lb

    rename $lb __$lb
    eval [format {
	;proc %s {args} {
	    set res [uplevel 1 __%s $args]
	    set first [lindex $args 0]
	    if {[string equal -length [string len $first] $first "selection"]} {
		if {[lindex $args 1] eq "set"} {
		    dialog_listed_var_change %s
		}
	    }
	    return $res
	}
    } $lb $lb $items $items]
}

proc dialog_listed_var_change {dial widget w elt} {
    global $dial

    set cur [$widget curselection]
    set item [$widget get $cur]
    set ${dial}($elt) $item
}

proc dialog_popupgroupbox_pane_change {dial w elt} {
    global $dial
    set controllers [lindex [set ${dial}(pager,$elt)] 1]
    set widget [lindex $controllers 1]
    set item [set ${dial}($elt)]
    $widget raise $item
    dialog_pane_foremost $dial [$widget getframe $item]
}

proc dialog_multipane_pane_change {dial w elt} {
    global $dial
    set widget [lindex [set ${dial}(pager,$elt)] 1]
    set item [set ${dial}($elt)]
    $widget raise $item
    dialog_pane_foremost $dial [$widget getframe $item]
}

proc dialog_popup_pane_change {dial w elt} {
    global $dial
    foreach pane [info commands [dialog::_makeSubf $w $elt]*] {
	place forget $pane
    }
    set pane [dialog_pageitem_to_frame $dial \
      [dialog::_makeSubf $w $elt] $elt [set ${dial}($elt)]]
    if {[winfo exists $pane]} {
	place $pane -in $w -x 0 -y 0
	dialog_pane_foremost $dial $pane
    }
}

proc dialog_tabbed_pane_change {dial w elt} {
    global $dial
    set widget [lindex [set ${dial}(pager,$elt)] 1]
    set item [set ${dial}($elt)]
    if {$::alpha::theming} {
	foreach frame [$widget tabs] {
	    if {[$widget tab $frame -text] eq $item} {
		$widget select $frame
		break
	    }
	}
    } else {
	$widget raise $item
	set frame [$widget getframe $item]
    }
    dialog_pane_foremost $dial $frame
}

# This function is called when a particular pane is made the frontmost
# in a multi-page dialog.  It is used particularly to deal with a
# problem with drag-n-drop commands on WinTk, which cause cosmetic
# weirdnesses if they are initialized on a widget which isn't mapped.
# So, we only call them once a widget is mapped.  To be extra careful,
# we only schedule the scripts with after-idle events.
# 
# Currently not used, since we found a different way to deal with the
# wintk-dnd nonsense.
proc dialog_pane_foremost {dial in} {
    global $dial
    if {[info exists ${dial}(frontmost,$in)]} {
	foreach script [set ${dial}(frontmost,$in)] {
	    after idle $script
	}
	unset ${dial}(frontmost,$in)
    }
}

#¥ get_directory [-p <prompt>] [<default>]
#
#  This command will display a standard file dialog and
#  request the user select a folder.  The command will return the
#  selected folder's full path name, or an error if the Cancel button
#  was selected.
proc get_directory {args} {
    set opts(-p) "Pick a directory"
    set opts(-d) ""
    getOpts {-p -d}
    if {[llength $args]} {
	set opts(-d) [lindex $args 0]
    }
    if {[file exists $opts(-d)]} {
	set f [alpha::externalDialog \
	  tk_chooseDirectory -title $opts(-p) -initialdir $opts(-d)]
    } else {
	set f [alpha::externalDialog \
	  tk_chooseDirectory -title $opts(-p)]
    }
    if {$f != ""} {
	global tcl_platform
	if {$tcl_platform(platform) == "windows"} {
	    # Catch this in case we're in a vfs.
	    catch {set f [file attributes $f -longname]}
	    return $f
	} else {
	    return $f
	}
    } else {
	error "Cancelled"
    }
}

#¥ putfile <prompt> <original>
#
#  This command will display an SFPutFile() and return the full path
#  name of the selected file, or an empty string if CANCEL button was
#  selected.  Original is the default name displayed for the user.
proc putfile {{title "Enter save file"} {where ""}} {
    return [alpha::externalDialog \
      tk_getSaveFile -title $title -initialfile $where]
}

proc gotoLine {} {
    if {![llength [winNames -f]]} {return}
    while {1} {
	set y 80
	set res [eval dialog -w 250 -h 110 -t [list "Goto line:"] 10 10 245 30 \
	  -e [list ""] 20 50 190 70 [dialog::okcancel -230 y]]
	if {[lindex $res 1]} {
	    if {[catch {goto "[lindex $res 0].0"} err]} {
		alertnote "'[lindex $res 0]' is not a valid line number"
	    } else {
		bringToFront [win::Current]
		return
	    }
	} else {
	    return
	}
    }
}

#¥ prompt <prompt> <default> [<name> <menu item>*] - prompt dialog to 
#  the user with a prompt string and a default value. The prompt dialog can 
#  optionally include a popup menu specified by 'name' and the succeeding 
#  strings. Selection of the popup menu items inserts the item text into the 
#  editable dialog item. 'Prompt' returns the value of the editable item. 
#  If the 'Cancel' button is selected, the tcl returns an error and your 
#  script will be stopped unless you execute the command from 'catch'.
proc prompt {prompt default args} {
    if {![llength $args]} {
	set y 12
	eval lappend dialog [dialog::text $prompt 10 y 30] \
	  [dialog::edit $default 20 y 300]
	incr y 10
	eval lappend dialog [dialog::okcancel -230 y]
	set res [eval dialog -w 250 -h 110 $dialog]
	if {[lindex $res 1]} {
	    return [lindex $res 0]
	} else {
	    error "Cancelled"
	}
    } else {
	set name [lindex $args 0]
	set args [lrange $args 1 end]
	set y 12
	eval lappend dialog [dialog::text $prompt 10 y 30] \
	  [dialog::edit $default 20 y 300] -tag edit [dialog::text $name 10 y] \
	  [dialog::menu 50 y $args [lindex $args 0]] \
	  -action [list [list ::dialog::copyingTo {+0 edit}]] \
	  [dialog::okcancel -230 y]
	set res [eval dialog -w 250 -h $y $dialog]
	if {[lindex $res 2]} {
	    return [lindex $res 0]
	} else {
	    error "Cancelled"
	}
    }
}

proc dialog::copyingTo {idList} {
    setControlValue [lindex $idList 1] [getControlValue [lindex $idList 0]]
}

#¥ setFontsTabs - bring up font and tab dialog
proc setFontsTabs {args} {
    getOpts {-w -font -fontsize -tabsize}
    if {[llength $args]} { return -code error "Too many args" }
    if {![info exists opts(-w)]} {
	set opts(-w) [win::Current]
	if {$opts(-w) == ""} { error "Cancelled - no window" }
    }
    getWinInfo -w $opts(-w) arr
    if {[info exists opts(-font)] || [info exists opts(-fontsize)] \
      || [info exists opts(-tabsize)]} {
	foreach arg {font fontsize tabsize} {
	    set new($arg) $arr($arg)
	    if {[info exists opts(-$arg)]} {
		set new($arg) $opts(-$arg)
	    }
	}
    } else {
	# Use the dialog
	foreach {new(font) new(fontsize) new(tabsize)} \
	  [chooseFontTab $arr(font) $arr(fontsize) $arr(tabsize) \
	  "Choose font/tab for current window"] {}
    }
    if {($new(font) ne $arr(font)) || ($new(fontsize) ne $arr(fontsize))} {
	text_wcmd $opts(-w) setFont [list $new(font) $new(fontsize)]
    }
    if {$new(tabsize) ne $arr(tabsize)} {
	text_wcmd $opts(-w) setTabs $new(tabsize)
    }
}

proc alpha::getFontList {{fixed 1}} {
    if {$fixed} {
	set res {}
	foreach f [lsort -dictionary [font families]] {
	    if {[font metrics [list $f] -fixed]} {
		lappend res $f
	    }
	}
	return $res
    } else {
	return [font families]
    }
}

proc chooseFontTab {font size tabsize {title "Choose font and tabsize"}} {
    set y 12
    
    set fontList [prefs::options defaultFont]
    if {[lsearch -exact $fontList $font] == -1} {
	set idx [lsearch -exact [string tolower $fontList] \
	  [string tolower $font]]
	if {$idx != -1} {
	    set font [lindex $fontList $idx]
	}
    }
    
    eval lappend dialog \
      [dialog::text "Font:" 10 y] \
      [dialog::menu 50 y $fontList $font] \
      [dialog::text "Size:" 10 y] \
      [dialog::menu 50 y [prefs::options fontSize] $size] \
      [dialog::text "Tab Size:" 10 y] \
      [dialog::edit $tabsize 50 y 4] \
      [dialog::okcancel -230 y]
    set res [eval [list dialog -w 250 -h $y -T $title] $dialog]
    if {[lindex $res 3]} {
	return [lrange $res 0 2]
    } else {
	error "Cancelled"
    }
    
}


#¥ getline <prompt> <default>
#  This command will display a Macintosh alert box with prompt displayed, a 
#  text edit field with default initially in the field, and with the push 
#  buttons OK, Cancel.. The command will return the text entered into the 
#  text edit field by the user, or an empty string if the user selected the 
#  Cancel button. 
proc getline {{prompt Prompt} {default {}}} {
    set y 10
    set d [dialog::text $prompt 10 y 300]
    eval lappend d [dialog::edit $default 20 y 30 3]
    incr y 10
    eval lappend d [dialog::okcancel -230 y]
    set res [eval dialog -w 340 -h $y $d]
    if {[lindex $res 1]} {
	return [lindex $res 0]
    } else {
	return ""
    }
}

proc dialog::navigateList {w itemName args} {
    set selected [$w curselection]
    switch -- $itemName {
	up {
	    # Select the previous item, clearing any prior selections.
	    # The 'l' argument indicates multiple list items are ok.
	    set l [lindex $args 0]
	    if {![llength $selected]} {
		$w selection set end
	    } else {
		set last [lindex $selected 0]
		if {!$l} {$w selection clear 0 [$w size]}
		if {$last > 0} {incr last -1}
		$w selection set $last
	    }
	    $w see [lindex [$w curselection] 0]
	}
	down {
	    # Select the next item, clearing any prior selections.
	    # The 'l' argument indicates multiple list items are ok.
	    set l [lindex $args 0]
	    if {![llength $selected]} {
		$w selection set 0
	    } else {
		set last [lindex $selected end]
		if {!$l} {$w selection clear 0 [$w size]}
		if {$last < [expr {[$w size] -1}]} {incr last}
		$w selection set $last
	    }
	    $w see [lindex [$w curselection] 0]
	}
	pageDown {
	    # If current selection is already at the bottom of the page
	    # view, scroll down one page.  Select the bottom item.
	    set bottomitem [$w nearest [winfo height $w]]
	    $w selection clear 0 [$w size]
	    if {![lcontains selected $bottomitem]} {
		# bottom item not selected
		$w selection set $bottomitem
	    } else {
		$w yview scroll 1 pages
		$w selection set [$w nearest [winfo height $w]]
	    }
	}
	pageUp {
	    # If current selection is already at the top of the page view,
	    # scroll down one page.  Select the top item.
	    set topitem [$w nearest 0]
	    $w selection clear 0 [$w size]
	    if {![lcontains selected $topitem]} {
		# top item not selected
		$w selection set $topitem
	    } else {
		$w yview scroll -1 pages
		$w selection set [$w nearest 0]
	    }
	}
	home {
	    # Select the first item.
	    $w selection clear 0 [$w size]
	    $w selection set 0
	    $w see 0    
	}
	end {
	    # Select the last item.
	    $w selection clear 0 [$w size]
	    $w selection set end
	    $w see end
	}
	scrollDown {
	    # Scroll the list down one, leaving selection unchanged.
	    $w yview scroll  1 units
	}
	scrollUp {
	    # Scroll the list up one, leaving selection unchanged.
	    $w yview scroll -1 units
	}
	mouseWheel {
	    if {[$w yview] == "0 1"} {
		# Nothing to scroll, so move the selection
		if {[lindex $args 0] < 0} {
		    return [navigateList $w down 0]
		} else {
		    return [navigateList $w up 0]
		}
	    } else {
		# Scroll the list, leaving selection unchanged.
		set scrollAmount 1
		$w yview scroll [expr {-[lindex $args 0] * $scrollAmount}] units
	    }
	}
    }
}

proc dialog::image {name x yy} {
    upvar 1 $yy y
    if {$x == ""} {
	unset x
	upvar 1 x x
    }
    set res [list -i $name $x $y]
    incr x [::image width $name]
    incr y [::image height $name]
    lappend res $x $y
    return $res
}

#¥ listpick [-p <prompt>] [-l] [-L <def list>] <list>
#  This command will display a dialog with the list displayed in a List Manager 
#  list. If the user presses the Cancel button, an empty string is returned. If 
#  the user selects the Open button, or double clicks an item in the list, that 
#  item will be returned. If '-l' is specified, than the return is a list of 
#  items.
proc listpick {args} {
    set opts(-w) 350
    set opts(-h) 400
    set opts(-rows) {}
    set opts(-L) {}
    getOpts {-p -L -w -h -T -rows}
    
    if {[llength $args] != 1} {
	return -code error "Bad arguments"
    }
    
    if {![info exists opts(-p)]} {
	if {[info exists opts(-l)]} {
	    set opts(-p) "Please pick one or more:"
	} else {
	    set opts(-p) "Please pick one:"
	}
    }

    set dial [list dialog -w $opts(-w) -h $opts(-h)]
    if {[info exists opts(-T)]} {
	lappend dial -T $opts(-T)
    }
    # Add the prompt
    lappend dial -t $opts(-p) 10 10 $opts(-w) 30
    # Find the listbox parameters are current selection
    if {[info exists opts(-l)]} {
	set params [list "multiple"]
	set lval [linsert [lindex $args 0] 0 $opts(-L)]
    } else {
	set params [list]
	set lval [concat [list $opts(-L)] [lindex $args 0]]
    }
    # 'active' means keyboard controlled, 'scrolled' means add a
    # scrollbar and any number will specify the number of rows to use.
    # If the number of rows is not given (or if an empty string is
    # given), then the rows will be made to fit whatever space was
    # given.
    lappend params "active" "scrolled" 
    # Add the listbox
    lappend dial -listitem $lval $params $opts(-rows) \
      30 50 [expr {$opts(-w) - 30}] [expr {$opts(-h) - 60}]
    # Add the buttons
    lappend dial -b "Ok" [expr {$opts(-w) - 100}] [expr {$opts(-h) - 40}] \
      [expr {$opts(-w) - 10}] [expr {$opts(-h) - 12}] \
      -b "Cancel" [expr {$opts(-w) - 200}] [expr {$opts(-h) - 40}] \
      [expr {$opts(-w) - 110}] [expr {$opts(-h) - 12}]
    set res [eval $dial]
    if {[lindex $res 2]} {
	return -code error "Cancelled"
    } else {
	if {[info exists opts(-indices)]} {
	    if {[info exists opts(-l)]} {
		set indexresult {}
		foreach r [lindex $res 0] {
		    lappend indexresult [lsearch -exact [lindex $args 0] $r]
		}
		return $indexresult
	    } else {
	        return [lsearch -exact [lindex $args 0] [lindex $res 0]]
	    }
	} else {
	    return [lindex $res 0]
	}
    }
}

proc alpha::bindDialogListbox {w listbox} {
    set w [winfo toplevel $w]
    bind $listbox <Double-Button-1> "event generate $w <Return>"

    # This enables navigating the list by typing in a key, clearing any
    # previous selection.
    bind $w <KeyPress>       "dialog::a_key        $listbox %A"
    # These change the selected item, clearing any previous selections.
    bind $w <Down>           "dialog::navigateList $listbox down 0"
    bind $w <Up>             "dialog::navigateList $listbox up   0"
    # These enable using the shift key to extend the list of
    # multiple selections one item up/down.
    if {[info exists opts(-l)]} {
	bind $w <Shift-Down> "dialog::navigateList $listbox down 1"
	bind $w <Shift-Up>   "dialog::navigateList $listbox up   1"
    }
    # These enable using page up/down and home/end to navigate the
    # list, changing the selection as well.
    bind $w <Next>           "dialog::navigateList $listbox pageDown"
    bind $w <Prior>          "dialog::navigateList $listbox pageUp"
    bind $w <Home>           "dialog::navigateList $listbox home"
    bind $w <End>            "dialog::navigateList $listbox end"
    # These enable scrolling up/down in the list without actually changing
    # the selection.
    bind $w <Control-Down>   "dialog::navigateList $listbox scrollDown"
    bind $w <Control-Up>     "dialog::navigateList $listbox scrollUp"
    bind $w <MouseWheel>     "dialog::navigateList $listbox mouseWheel %D"
}

if {0} {
#¥ listpick [-p <prompt>] [-l] [-L <def list>] <list>
#  This command will display a dialog with the list displayed in a List Manager 
#  list. If the user presses the Cancel button, an empty string is returned. If 
#  the user selects the Open button, or double clicks an item in the list, that 
#  item will be returned. If '-l' is specified, than the return is a list of 
#  items.
proc listpick {args} {
    global tcl_platform alphaPriv
    set root [dialog::findRoot]
    set w ${root}.dl
    catch {destroy $w}
    # Remember old focus
    set oldFocus [dialog::getFocus $w]
    
    alpha::makeToplevel $w -class Dialog
    wm title $w ""
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW { }

    # Dialog boxes should be transient with respect to their parent,
    # so that they will always stay on top of their parent window.  However,
    # some window managers will create the window as withdrawn if the parent
    # window is withdrawn or iconified.  Combined with the grab we put on the
    # window, this can hang the entire application.  Therefore we only make
    # the dialog transient if the parent is viewable.
    if {[winfo viewable [winfo toplevel [winfo parent $w]]]} {
	wm transient $w [winfo toplevel [winfo parent $w]]
    }
    if {[tk windowingsystem] == "classic" \
      || [tk windowingsystem] == "aqua"} {
	::tk::unsupported::MacWindowStyle style $w movableDBoxProc
    }

    getOpts {-p -L -w -h -T}
    if {![info exists opts(-p)]} {
	if {[info exists opts(-l)]} {
	    set opts(-p) "Please pick one or more:"
	} else {
	    set opts(-p) "Please pick one:"
	}
    }
    
    if {[info exists opts(-T)]} {
	set title $opts(-T)
	if {$tcl_platform(platform) == "windows"} {
	    # The standard Windows titlebar font doesn't seem to have
	    # an ellipsis... except for Windows 2000 (= NT 5.0)
	    # I need to know whether this is required on Win95/98...
	    if {($tcl_platform(os) != "Windows NT") \
	      || ($tcl_platform(osVersion) != 5.0)} {
		regsub -all "É" $title "..." title
	    }
	}
	wm title $w $title
    }
    
    label $w.msg -wraplength 4i -justify left  -text $opts(-p)
    pack $w.msg -side top
    
    frame $w.buttons
    pack $w.buttons -side bottom -fill x -pady 2m
    button $w.buttons.ok -text Ok -command "set alphaPriv(button) 1" \
      -default active
    bind $w <Return> "
    dialog::pushButton $w.buttons.ok
    set alphaPriv(button) 1
    "
    
    button $w.buttons.cancel -text Cancel -command "set alphaPriv(button) 0"
    bind $w <Escape> "
    dialog::pushButton $w.buttons.cancel
    set alphaPriv(button) 0
    "
    wm protocol $w WM_DELETE_WINDOW [list event generate $w <Escape>]
    pack $w.buttons.cancel $w.buttons.ok -side left -expand 1
    
    frame $w.frame -borderwidth .5c
    pack $w.frame -side top -expand yes -fill both
    
    scrollbar $w.frame.scroll -command "$w.frame.list yview"
    if {[info exists opts(-l)]} {
	set selectmode "extended"
    } else {
	set selectmode "browse"
    }
    listbox $w.frame.list -yscroll "$w.frame.scroll set" \
      -setgrid 1 -height 12 -selectmode $selectmode -width 30
    
    pack $w.frame.scroll -side right -fill y
    pack $w.frame.list -side left -expand 1 -fill both

    alpha::bindDialogListbox $w $w.frame.list

    # args is a list of a list
    eval [linsert [lindex $args 0] 0 $w.frame.list insert 0]
    # Determine (a) which item(s) will be initially selected, and
    # (b) which item should appear at the top of the view page.
    set idx [list ]
    if {[info exists opts(-L)]} {
	if {[info exists opts(-l)]} {
	    # Multiple selections are possible.
	    foreach itm $opts(-L) {
		# Select all default items found ...
		set _idx [lsearch -exact [lindex $args 0] $itm]
		if {$_idx >= 0} {lappend idx $_idx}
	    }
	} else {
	    # Only one default is possible.
	    set _idx [lsearch -exact [lindex $args 0] [lindex $opts(-L) 0]]
	    if {$_idx >= 0} {lappend idx $_idx}
	}
    }
    if {![llength $idx]} {set idx [list "0"]}
    
    bind $w <Destroy> {set alphaPriv(button) -1}

    # 6. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw $w
    update idletasks
    # If the window has an icon, now is the time to set it
    alpha::setIcon $w
    set x [expr {[winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
      - [winfo vrootx [winfo parent $w]]}]
    set y [expr {[winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
      - [winfo vrooty [winfo parent $w]]}]
    wm geom $w +$x+$y
    
    # Show the first selected item
    $w.frame.list see [lindex $idx 0]

    update
    wm deiconify $w

    # 7. Set a grab and claim the focus too.

    set oldGrab [dialog::getGrab $w]
    focus $w.buttons.ok
    
    # Set the selection (if we do this earlier it can be reset by
    # the grab, I think).
    foreach _idx $idx {$w.frame.list selection set $_idx}

    # 8. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    tkwait variable alphaPriv(button)
    
    if {[info exists opts(-l)]} {
	set res [list]
	if {[info exists opts(-indices)]} {
	    eval lappend res [$w.frame.list curselection]
	} else {
	    foreach itm [$w.frame.list curselection] {
		lappend res [$w.frame.list get $itm]
	    }
	}
    } else {
	if {[info exists opts(-indices)]} {
	    set res [$w.frame.list curselection]
	} else {
	    if {[$w.frame.list curselection] != ""} {
		set res [$w.frame.list get [$w.frame.list curselection]]
	    } else {
		set res ""
	    }
	}
    }
    
    dialog::restoreFocus $w $oldFocus
    catch {
	# It's possible that the window has already been destroyed,
	# hence this "catch".  Delete the Destroy handler so that
	# alphaPriv(button) doesn't get reset by it.

	bind $w <Destroy> {}
	destroy $w
    }
    dialog::releaseGrab $oldGrab
    if {$alphaPriv(button) == 1} {
	return $res
    } else {
	error "Cancelled!"
    }
}
}

#¥ status::msg <string> - prints 'string' on the status line.
proc status::msg {t args} {
    set color "black"
    set widget .status.text

    if {![winfo exists .status.text]} {
	label .status.text
	grid .status.text -sticky ew -row 0 -column 0
	grid columnconfigure .status 1 -weight 2
    }

    switch -- [llength $args] {
	0 {
	    # do nothing
	}
	1 {
	    set flag $t
	    set t [lindex $args 0]
	    switch -- $flag {
		"-error" {
		    set color "red"
		}
		"-state" {
		    set widget .status.w.state
		}
		default {
		    error "bad arguments to status::msg"
		}
	    }
	}
	default {
	    error "too many arguments to status::msg"
	}
    }
    regsub -all "\[\r\n\]" $t " " t
    $widget configure -text [::msgcat::mc $t] -foreground $color
    if {[info exists ::alpha::guiNotReady]} {
	# While we're starting up, allow full events for more
	# responsive package index rebuild, etc.  We will use
	# a 'grab' to prevent user interaction.
	update
    } else {
	update idletasks
    }
}

proc alpha_tk_dialog {w title text bitmap default args} {
    global tcl_platform
    variable ::tk::Priv

    # Check that $default was properly given
    if {[string is int $default]} {
	if {$default >= [llength $args]} {
	    return -code error "default button index greater than number of\
		    buttons specified for tk_dialog"
	}
    } elseif {[string equal {} $default]} {
	set default -1
    } else {
	set default [lsearch -exact $args $default]
    }

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    catch {destroy $w}
    toplevel $w -class Dialog
    # At least on some X11 an empty title is converted into
    # some window-manager specific text we don't want
    if {$title eq ""} { set title "Alphatk" }
    wm title $w $title
    wm iconname $w Dialog
    wm protocol $w WM_DELETE_WINDOW { }

    # Dialog boxes should be transient with respect to their parent,
    # so that they will always stay on top of their parent window.  However,
    # some window managers will create the window as withdrawn if the parent
    # window is withdrawn or iconified.  Combined with the grab we put on the
    # window, this can hang the entire application.  Therefore we only make
    # the dialog transient if the parent is viewable.
    #
    if {[winfo viewable [winfo toplevel [winfo parent $w]]] } {
	wm transient $w [winfo toplevel [winfo parent $w]]
    }    

    if {[string equal $tcl_platform(platform) "macintosh"]
	    || [string equal [tk windowingsystem] "aqua"]} {
	::tk::unsupported::MacWindowStyle style $w dBoxProc
    }

    ttk::frame $w.bot
    ttk::frame $w.top
    if {[string equal [tk windowingsystem] "x11"]} {
	$w.bot configure -relief raised -bd 1
	$w.top configure -relief raised -bd 1
    }
    pack $w.bot -side bottom -fill both
    pack $w.top -side top -fill both -expand 1

    # 2. Fill the top part with bitmap and message (use the option
    # database for -wraplength and -font so that they can be
    # overridden by the caller).

    option add *Dialog.msg.wrapLength 3i widgetDefault
    if {[string equal $tcl_platform(platform) "macintosh"]
	    || [string equal [tk windowingsystem] "aqua"]} {
	option add *Dialog.msg.font system widgetDefault
    } else {
	option add *Dialog.msg.font {Times 12} widgetDefault
    }

    ttk::label $w.msg -justify left -text $text
    pack $w.msg -in $w.top -side right -expand 1 -fill both -padx 3m -pady 3m
    if {[string compare $bitmap ""]} {
	if {([string equal $tcl_platform(platform) "macintosh"]
	     || [string equal [tk windowingsystem] "aqua"]) &&\
		[string equal $bitmap "error"]} {
	    set bitmap "stop"
	}
	ttk::label $w.bitmap 
	#-bitmap $bitmap
	pack $w.bitmap -in $w.top -side left -padx 3m -pady 3m
    }

    # 3. Create a row of buttons at the bottom of the dialog.

    # First add an expanding frame to push all buttons to the right.
    ttk::frame $w.bframe
    grid $w.bframe -in $w.bot -sticky ew -row 0
    grid columnconfigure $w.bot 0 -weight 1
    set i 0
    foreach but $args {
	ttk::button $w.button$i -text $but -command [list set ::tk::Priv(button) $i]
	catch {
	    if {$i == $default} {
		$w.button$i configure -default active
	    } else {
		$w.button$i configure -default normal
	    }
	}
	set col [expr {$i + 1}]
	grid $w.button$i -in $w.bot -column $col -row 0 -sticky ew \
		-padx 10 -pady 4
	grid columnconfigure $w.bot $col
	# We boost the size of some Mac buttons for l&f
	if {[string equal $tcl_platform(platform) "macintosh"]
	    || [string equal [tk windowingsystem] "aqua"]} {
	    set tmp [string tolower $but]
	    if {[string equal $tmp "ok"] || [string equal $tmp "cancel"]} {
		grid columnconfigure $w.bot $col -minsize [expr {59 + 20}]
	    }
	}
	incr i
    }

    # 4. Create a binding for <Return> on the dialog if there is a
    # default button.

    if {$default >= 0} {
	bind $w <Return> "
	dialog::pushButton $w.button$default
	set ::tk::Priv(button) $default
	"
    }

    # 5. Create a <Destroy> binding for the window that sets the
    # button variable to -1;  this is needed in case something happens
    # that destroys the window, such as its parent window being destroyed.

    bind $w <Destroy> {set ::tk::Priv(button) -1}

    # 6. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw $w
    update idletasks
    set x [expr {[winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
	    - [winfo vrootx [winfo parent $w]]}]
    set y [expr {[winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
	    - [winfo vrooty [winfo parent $w]]}]
    # Make sure that the window is on the screen and set the maximum
    # size of the window is the size of the screen.  That'll let things
    # fail fairly gracefully when very large messages are used. [Bug 827535]
    if {$x < 0} {
	set x 0
    }
    if {$y < 0} {
	set y 0
    }
    wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]
    wm geom $w +$x+$y
    wm deiconify $w

    # 7. Set a grab and claim the focus too.

    set oldFocus [dialog::getFocus $w]
    set oldGrab [grab current $w]
    if {[string compare $oldGrab ""]} {
	set grabStatus [grab status $oldGrab]
    }
    grab $w
    if {$default >= 0} {
	focus $w.button$default
    } else {
	focus $w
    }

    # 8. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    vwait ::tk::Priv(button)
    catch {dialog::restoreFocus $w $oldFocus}
    catch {
	# It's possible that the window has already been destroyed,
	# hence this "catch".  Delete the Destroy handler so that
	# Priv(button) doesn't get reset by it.

	bind $w <Destroy> {}
	destroy $w
    }
    if {[string compare $oldGrab ""]} {
	if {[string compare $grabStatus "global"]} {
	    grab $oldGrab
	} else {
	    grab -global $oldGrab
	}
    }
    return $Priv(button)
}

proc alpha::fakeWrap {len font label} {
    set first 0
    set line 0
    set haveSpace 0
    while {1} {
	set next [string first " " $label $first]
	if {$next == -1} {
	    set next end
	}
	set measure \
	  [font measure $font [string range $label $line $next]] 
	if {$measure > $len} {
	    # Insert new-line unless it's one big word
	    if {$haveSpace} {
		set label [string replace $label $prev $prev "\n"]
	    } else {
		# nothing
	    }
	    set line [expr {$prev + 1}]
	    set haveSpace 0
	} else {
	    set haveSpace 1
	    set prev $next
	}
	if {$next eq "end"} {
	    break
	}
	set first [expr {$next + 1}]
    }
    return $label
}
