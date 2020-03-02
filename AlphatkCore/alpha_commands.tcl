## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_commands.tcl"
 #                                    created: 04/12/98 {23:17:46 PM} 
 #                                last update: 04/07/2006 {12:01:16 AM} 
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
#==============================================================================
#= Alpha Commands
#==============================================================================
#
#In this list of routines, text between '<' and '>' is a placeholder for a 
#required parameter, text between '[' and ']' is a placeholder for an 
#optional parameter, and the '|' signifies a choice of two or more 
#alternatives.  A '+' signifies that the previous symbol can be present one 
#or more times, while a '*" means zero or more times.  Some commands have no 
#parameters, and are only expected to be called interactively.
#

namespace eval win {}

# Helper command for anything which takes an optional '-w win' argument.
# Takes as arguments the name of the variable in which to put the window
# name (or win::current if none is given) followed by any number of
# arguments representing variable names to be populated with values
# given by the caller.  If not enough arguments are given (or too many)
# a nice error message will be thrown.  It is also possible to end
# the list of variable names with 'args' which will collect all 
# remaining values given, or to supply default arguments as with 
# standard Tcl procedure argument lists.
proc win::parseArgs {ww args} {
    upvar 1 args valuesArgs
    upvar 1 $ww w
    if {[lindex $valuesArgs 0] eq "-w"} {
	set w [lindex $valuesArgs 1]
	set valuesArgs [lrange $valuesArgs 2 end]
    } else {
	set w [win::Current]
    }

    set len [llength $args]
    incr len -1
    for {set i 0} {$i <= $len} {incr i} {
	set var [lindex $args $i]
	if {($i == $len) && ($var eq "args")} {
	    uplevel 1 [list set args [lrange $valuesArgs $i end]]
	    set i [llength $valuesArgs]
	    break
	} else {
	    switch -- [llength $var] {
		0 - 1 {
		    if {$i < [llength $valuesArgs]} {
			uplevel 1 [list set $var [lindex $valuesArgs $i]]
		    } else {
			return -code error "Wrong number arguments, should be:\
			  [lindex [info level -1] 0] ?-w window? $args"
		    }
		}
		2 {
		    set default [lindex $var 1]
		    set var [lindex $var 0]
		    if {$i < [llength $valuesArgs]} {
			uplevel 1 [list set $var [lindex $valuesArgs $i]]
		    } else {
			uplevel 1 [list set $var $default]
		    }
		}
		default {
		    return -code error "Bad argument list \"$var\""
		}
	    }
	}
    }
    if {$i < [llength $valuesArgs]} {
	# Too many arguments
	return -code error "Too many arguments, should be:\
	  [lindex [info level -1] 0] ?-w window? $args"
    }
}

namespace eval alphatk {
    variable coloring 1
    variable hyperText
    variable blockCursor 0
    
    variable horScrollBar 1
    variable locationOfStatusBar
    variable moveInsertion
    variable openAllFiles
    variable changeTypeAndCreatorOnSave
    variable smallMenuFont
    variable tearoffMenus
    variable undoOn
    variable printerFont
    variable printerFontSize
    variable tabSize
    variable wordBreak
    variable defaultFont
    variable fontSize
    variable linkableVariables {
	 coloring horScrollBar blockCursor locationOfStatusBar hyperText
	 moveInsertion openAllFiles changeTypeAndCreatorOnSave
	 smallMenuFont tearoffMenus undoOn printerFont printerFontSize
	 tabSize wordBreak defaultFont fontSize
    }
}

proc linkVar {varName} { 
    global alphatk::linkableVariables
    if {[lsearch -exact $alphatk::linkableVariables $varName] == -1} {
	puts stderr "Trying to link with unknown variable $varName"
	#error "Trying to link with unknown variable $varName"
	return
    }
    if {[info exists ::$varName]} {
	puts stderr "$varName already exists, that is bad"
	unset ::$varName
    }
    #puts stdout "linking with $varName"
    upvar \#0 ::alphatk::$varName ::$varName
}

# ×××× other ×××× #

#¥ getFileInfo <file> <arr> - Given a file name, creates an array called 
#  'arr' in the current context, containing fields 'created', 'creator', 
#  'modified', 'type', 'datalen', and 'resourcelen'. 'created' and 
#  'modified' are in a form suitable for the command 'mtime'.
proc getFileInfo {f a} {
    upvar 1 $a arr
    file stat $f arr
    # Convert 'type' to 'objecttype'
    set arr(objecttype) $arr(type)
    unset arr(type)
    foreach {opt val} [file attributes $f] {
	set arr([string range $opt 1 end]) $val
    }
    # We will get rid of these three in the future!
    if {![info exists arr(resourcelen)]} {
	set arr(resourcelen) 0
    }
    if {![info exists arr(creator)]} {
	set arr(creator) $f
	# For macosx ?
	#[mac::findItemProperty fcrt file $f]
    }
    if {![info exists arr(type)]} {
	set arr(type) TEXT
	# For macosx ?
	#[mac::findItemProperty asty file $f]
    }
    set arr(modified) [file mtime $f]
    set arr(datalen) [file size $f]
    set arr(created) $arr(ctime)
}

#¥ setFileInfo <file> <field> [arg] - Allows some information to be set 
#  for files. Settable fields are 'modified', 'created', 'creator', and 
#  'type' all take an argument. 'resourcelen' can be set, but doesn't take 
#  an argument and just removes the resource fork.
proc setFileInfo {file field {arg ""}} {
    if {![file exists $file]} {
	error "No such file: $file"
    }
    switch -- $field {
	"modified" {
	    file mtime $file $arg
	}
	"created" {
	    echo "Unimplemented: setFileInfo $file created"
	}
	"resourcelen" {
	    echo "Unimplemented: setFileInfo $file resourcelen"
	}
	default {
	    file attributes $file -$field $arg
	}
    }
}

proc getModifiers {args} {return 0}
#¥ insertColorEscape <pos> <color ind> [hypertext func] - Create a color 
#  or style "point" for documentation purposes. Look at the file 
#  "docColors.tcl" for examples. The hypertext func is only used when the 
#  "point" is underline. See 'getColors' for info about the current file.
proc insertColorEscape {args} {
    win::parseArgs w pos color {func ""}
    global alphaPriv
    if {$color == 0 || $color == 12} {
	if {![info exists alphaPriv(insertColorEscapeColor)]} {
	    return
	}
	if {[string is integer $alphaPriv(insertColorEscapeColor)]} {
	    set c color$alphaPriv(insertColorEscapeColor)
	} else {
	    set c $alphaPriv(insertColorEscapeColor)
	}
	text::color -w $w \
	  $alphaPriv(insertColorEscapePos) $pos \
	  $c $alphaPriv(insertColorEscapeFunc)
	unset alphaPriv(insertColorEscapePos) 
	unset alphaPriv(insertColorEscapeColor)
	unset alphaPriv(insertColorEscapeFunc) 
    } else {
	set alphaPriv(insertColorEscapePos) $pos
	set alphaPriv(insertColorEscapeColor) $color
	set alphaPriv(insertColorEscapeFunc) $func
    }
}

proc removeColorEscapes {args} {
    win::parseArgs ww
    global win::tk
    set w $win::tk($ww)
    foreach t [$w tag names] {
	if {[string range $t 0 4] ne "user:" && $t ne "hyper"} { continue }
	if {[string range $t 0 4] == "mark:"} { continue }
	if {[llength [set range [$w tag ranges $t]]]} {
	    eval [list $w tag remove $t] $range
	}
    }
}

namespace eval text {}

proc text::hyper {args} {
    win::parseArgs w from to hyper
    text::color -w $w $from $to 15 $hyper
}

proc text::color {args} {
    win::parseArgs w from to colour {hyper ""}
    switch -- $colour {
	black       {set colour 0}
	blue        {set colour 1}
	cyan        {set colour 2}
	green       {set colour 3}
	magenta     {set colour 4}
	red         {set colour 5}
	white       {set colour 6}
	yellow      {set colour 7}
	bold        {set colour 8}
	roman       {set colour 10}
	italic      {set colour 11}
	normal      {set colour 12}
	overstrike  {set colour 13}
	underline   {set colour 15}
	extended - condensed - outline - shadow {
	    # Use normal, since these aren't supported
	    set colour 12
	}
    }
    if {$hyper ne ""} {
	text_wcmd $w addHyper $from $to $hyper
    }
    if {[string is integer $colour]} {
	text_wcmd $w tag add user:color$colour $from $to
    } else {
	text_wcmd $w tag add user:$colour $from $to
    }
}

#¥ execute - prompt user for a function or macro. The 
#  tab key acts as a "completion" command.
proc execute {} {
    if {[catch {uplevel \#0 [statusPrompt "execute: "]} res]} {
	status::msg "Error: $res"
    } else {
	status::msg "Result: $res"
    }
}

# Called in aeom.tcl
proc openFile {path} {
    edit $path
}

proc beep {args} {bell}

proc selectLimits {args} {
    win::parseArgs w
    if {![llength [set res [text_wcmd $w tag ranges sel]]]} {
	return ""
    }
    return [list [lindex $res 0] [lindex $res end]]
}

proc selectSegments {args} {
    win::parseArgs w
    return [text_wcmd $w tag ranges sel]
}

proc rgbToColor {triplet} {
    set rgb "#"
    foreach c $triplet {
	append rgb [format "%04x" $c]
    }
    return $rgb
}

proc setRGB {col args} {
    if {[llength $args] != 3} {
	# not sure what this command with no args is supposed to do
	error "Bad args to setRGB"
    }
    set rgb [rgbToColor $args]
    if {![regsub "color_" $col "color" col]} {
	set idx [lsearch -exact {blue cyan green magenta red white yellow} $col]
	if {$idx < 0} {
	    if {$col == "background" || $col == "foreground"} {
		foreach w [winNames -f] {
		    text_wcmd $w configure -$col $rgb
		}
		return
	    } else {
		puts stderr "Bad colour $col"
	    }
	}
	incr idx
	set col "color$idx"
    }
    
    foreach w [winNames -f] {
	text_wcmd $w tag configure $col -foreground $rgb
	alpha::synchroniseTagColours $w
    }
}

# #¥ largestPrefix <list> - Returns the longest prefix contained in all 
#  strings of 'list'.
proc largestPrefix {list} {
    # we only use this where the list is alphabetical
    set first [lindex $list 0]
    set last [lindex $list end]
    set len [string length $first]
    set i 0
    while {[string index $first $i] == [string index $last $i]} {
	if {$i == $len} {
	    break
	}
	incr i
    }
    return [string range $first 0 [expr {$i -1}]]
}

#¥ watchCursor - turns the cursor into a a watch cursor.
proc watchCursor {} {
    global hasWatch
    # not a very good implementation.  May choose wrong window
    # and should really use an idletask not an 'after'
    if {![info exists hasWatch]} {
	set hasWatch 1
	global alpha::guiNotReady
	if {[info exists alpha::guiNotReady] || ([win::Current] eq "")} {
	    . configure -cursor watch
	    after 1000 "catch {. configure -cursor xterm} ; unset hasWatch"
	} else {
	    global win::tk
	    set w $win::tk([win::Current])
	    $w configure -cursor watch
	    after 1000 "catch {$w configure -cursor xterm} ; unset hasWatch"
	}
	return 1
    } else {
	return 0
    }
}

# ×××× save quit undo ×××× #

#¥ quit - quits ALPHA
if {[info commands __quit] == ""} {
    rename quit __quit
}
proc quit {args} {
    # need to check files aren't dirty
    global win::NumDirty
    if {[info exists win::NumDirty] && ($win::NumDirty > 0)} {
	if {![dialog::yesno "There are windows with unsaved changes. Are you\
	  sure you wish to quit?"]} {
	    return
	}
    }
    if {![catch {winNames -f}]} {
	while {[llength [winNames -f]]} {
	    killWindow -w [lindex [winNames -f] 0] "Discard Changes"
	}
    }
    if {[info commands quitHook] != ""} {
	quitHook
    }
    __quit
}

proc saveAll {} {
    foreach w [winNames -f] {
	save $w
    }
}


#¥ redo - redo the next action that has been undone but 
#  not redone
proc redo {args} {
    ::win::parseArgs w
    text_wcmd $w redo
}
#¥ undo - undo the last action that has not been undone
proc undo {args} {
    ::win::parseArgs w
    text_wcmd $w undo
}

# ×××× Basic gui stuff ×××× #

#¥ getMainDevice - return a list containing the left, top, right, and 
#  bottom of the rectangle defining the main device.
proc getMainDevice {} {
    return [list 0 0 [screenToDistance [winfo screenwidth .]] \
      [screenToDistance [winfo screenheight .]]]
}
#¥ new [-g <l> <t> <w> <h>] [-n <name>] - opens an untitled window.
#Can optionally provide left and top coordinates, plus width and
#height.  All or none.
proc new {args} {
    set opts(-n) "untitled"
    set opts(-text) ""
    getOpts [list {-g 4} -n -text -tabbed]
    
    if {[info exists opts(-tabbed)]} {
	set type "tabbed"
	set options [list $opts(-n) $opts(-tabbed)]
    } else {
	set type "toplevel"
	if {![info exists opts(-g)]} {
	    global defWidth defHeight defTop defLeft
	    set opts(-g) [list $defLeft $defTop $defWidth $defHeight]
	}
	set options [concat [list $opts(-n)] $opts(-g)]
    }
    regsub -all "\r" $opts(-text) "\n" opts(-text)

    alpha::embedInto -text $opts(-text) -- $opts(-n) $type $options
}
#¥ setWinInfo [-w <win>] <field> <arg> - Sets a piece of data about either 
#  the current or a specified window. Settable fields 'platform', 'state', 
#  'read-only', 'tabsize', 'dirty', and 'shell'. 'shell' means that dirty 
#  flag ignored and undo off.
proc setWinInfo {args} {
    win::parseArgs win field arg
    global ::win::tk
    if {![info exists win::tk($win)]} {
	set win [winTailToFullName $win]
    }
    switch -- $field {
	"platform" {
	    tw::platform $win::tk($win) $arg
	}
	"state" {
	    echo "Ignored 'state' argument to setWinInfo"
	}
	"read-only" {
	    tw::read_only $win::tk($win) $arg
	}
	"tabsize" {
	    if {[llength [info commands $win::tk($win)]]} {
		tw::setTabs $win::tk($win) $arg
	    } else {
		tw::setvar $win::tk($win) tabsize $arg
	    }
	}
	"dirty" {
	    tw::dirty $win::tk($win) $arg
	}
	"shell" {
	    if {$arg} {
		tw::setvar [set win::tk($win)] shell 1
	    } else {
		global ::tw::[set win::tk($win)]
		unset -nocomplain ::tw::[set win::tk($win)](shell)
	    }
	    
	}
	"encoding" {
	    tw::encoding $win::tk($win) $arg
	}
	"font" {
	    if {[llength [info commands $win::tk($win)]]} {
		set s [font actual [$win::tk($win) cget -font] -size]
		tw::setFont $win::tk($win) [list $arg $s]
	    } else {
		tw::setvar $win::tk($win) font $arg
	    }
	}
	"fontsize" {
	    if {[llength [info commands $win::tk($win)]]} {
		set f [font actual [$win::tk($win) cget -font] -family]
		tw::setFont $win::tk($win) [list $f $arg]
	    } else {
		tw::setvar $win::tk($win) fontsize $arg
	    }
	}
	"linenumbers" {
	    if {[llength [info commands $win::tk($win)]]} {
		if {[tw::readvar $win::tk($win) linenumbers] != $arg} {
		    text_wcmd $win toggleLineNumbers
		}
	    } else {
		tw::setvar $win::tk($win) linenumbers $arg
	    }
	}
	"horscrollbar" {
	    if {[llength [info commands $win::tk($win)]]} {
		if {[tw::readvar $win::tk($win) horizScrollbar] != $arg} {
		    text_wcmd $win horizScrollbar
		}
	    } else {
		tw::setvar $win::tk($win) horizScrollbar $arg
	    }
	}
	"colortags" -
	"bindtags" -
	"wordbreak" {
	    tw::Set $win::tk($win) $field $arg
	}
        "wrap" {
            if {[llength [info commands $win::tk($win)]]} {
                $win::tk($win) configure -wrap $arg
            } else {
		tw::setvar $win::tk($win) wrap $arg
            }
        }
	default {
	    error "Bad arg '$field' to setWinInfo"
	}
    }
}
#¥ splitWindow [percent] - toggle having window split into two panes. 
#  Optional arg specifies percent of window to allocate to the first pane. 
proc toggleSplitWindow {args} {
    ::win::parseArgs w {percent ""}
    text_wcmd $w toggleSplit
}

#¥ toggleScrollbar - toggles horizontal scrollbar on frontmost window. 
#  Will not succeed if scrollbar scrolled.
proc toggleScrollbar {args} {
    ::win::parseArgs w
    text_wcmd $w horizScrollbar
}

proc winTailToFullName {n} {
    global win::tk
    if {[file exists $n] || \
      ([regsub { <[0-9]+>$} $n {} name] && [file exists $name])} {
	set n [file nativename $n]
    }
    if {![info exists win::tk($n)]} {
	# it was just the tail of the name
	foreach nm [array names win::tk] {
	    if {[file tail $nm] eq $n} {
		return $nm
	    }
	}
	if {![info exists win::tk($n)]} {
	    return -code error "Window \"$n\" not found!"
	}
    }
    return $n
}

#¥ otherPane - If window is split, select the other pane.
proc otherPane {args} {
    ::win::parseArgs w
    text_wcmd $w otherPane
}

#¥ getWinInfo [-w <win>] <arr> - Creates an array in current context 
#  containing info about either the current or a specified window. Array 
#  has fields 'state', 'platform', 'read-only', 'tabsize', 'split', 
#  'linesdisp' (num lines that can be seen in the window), 'currline' 
#  (first line displayed), and 'dirty'.
proc getWinInfo {args} {
    win::parseArgs w ar
    global win::tk
    if {![info exists win::tk($w)]} {
	set ww [winTailToFullName $w]
	if {![info exists win::tk($ww)]} {
	    error "Unknown window $ww"
	}
	set w $ww
    }
    uplevel 1 [list array set $ar [array get ::tw::[set win::tk($w)]]]
    set tkw $win::tk($w)
    if {$tkw eq "."} {
	error "Cancelled since no window is open (while executing 'getWinInfo')"
    }
    uplevel 1 [list set ${ar}(state)    "none"]
    if {[info commands $tkw] ne ""} {
	set lines [expr {int([$tkw index end])}]
	set currline [expr {int([$tkw index @0,0])}]
	set lastline [expr {int([$tkw index "@[winfo width $tkw],[winfo height $tkw]"])}]
	set linesdisp [expr {$lastline - $currline}]
	uplevel 1 [list set ${ar}(currline) $currline]
	uplevel 1 [list set ${ar}(linesdisp) $linesdisp]
	global tw::split
	uplevel 1 [list set ${ar}(split) [info exists tw::split([set win::tk($w)])]]
	set fnt [$tkw cget -font]
	uplevel 1 [list set ${ar}(font) [font actual $fnt -family]]
	uplevel 1 [list set ${ar}(fontsize) [font actual $fnt -size]]
	uplevel 1 [list set ${ar}(wrap) [$tkw cget -wrap]]
    }
    return ""
}

#¥ icon [-f <winName>] [-c|-o|-t|-q] [-g <h> <v>] - Having to do w/ 
#  iconifying windows. '-c' means close (iconify) window, '-o' open, '-t' 
#  toggle open/close, '-q' returns either a '1' for an iconified window or a 
#  '0' for an uniconified window, and '-g' moves the icon to horizontal 
#  position <h> and vertical position 'v'. Options are executed as they 
#  are parsed, so the '-f' option, if present, should always be first. 
proc icon {args} {
    getOpts {-f}
    if {[info exists opts(-f)]} {
	set w $opts(-f)
    } else {
	set w [win::Current]
    }
    global win::tk
    set w [winfo toplevel $win::tk($w)]
    set state [wm state $w]
    if {[info exists opts(-q)]} {
	return [expr {$state ne "normal"}]
    } elseif {[info exists opts(-c)]} {
	if {![string length [$w cget -use]]} {
	    wm iconify $w
	}
    } elseif {[info exists opts(-o)]} {
	if {![string length [$w cget -use]]} {
	    wm deiconify $w
	}
    } elseif {[info exists opts(-t)]} {
	if {$state == "normal"} { 
	    if {![string length [$w cget -use]]} {
		wm iconify $w
	    }
	} else {
	    if {![string length [$w cget -use]]} {
		wm deiconify $w
	    }
	}
    }
}

# ×××× Time and timing ×××× #

#¥ iterationCount - allows actions to be repeated many times. "control-u 44 
#  =" inserts 44 '='s into current window.  Also can be used to execute any 
#  function or macro (including the keyboard macro) many times.  Defaults to 
#  4.
proc iterationCount {args} {
    error "Cancelled - iterationCount not implemented."
}

# ×××× Not that important ×××× #

#¥ abortEm - aborts whatever is currently happening
proc abortEm {} {
    global alpha::abort
    set alpha::abort 1
}

# ×××× Even less important ×××× #

#¥ zapInvisibles - removes chars < ascii 32, except for
#  LF's and CR's and tabs.
proc zapNonPrintables {args} {
    win::parseArgs w
    for {set i 0} {$i < 32} {incr i} {
	if {$i == 10 || $i == 13 || $i == 9} { continue }
	lappend map [format "%c" $i] {}
    }
    set text [string map $map [getText -w $w [minPos -w $w] [maxPos -w $w]]]
    replaceText -w $w [minPos -w $w] [maxPos -w $w] $text
}
#¥ getColors - returns list of colors/hypertext for current document. 
#  Format is list of lists, each sublist consisting of file offset, color 
#  index, and possibly a hypertext command.
proc getColors {args} {
    win::parseArgs w {style ""}
    
    global win::tk
    set res {}
    set hyper {}
    set lastindex {}
    foreach {on tag index} [text_wcmd $w dump -tag [minPos -w $w] [maxPos -w $w]] {
	if {$tag eq "hyper"} {
	    if {$on eq "tagon"} {
		set hypername [text_wcmd $w _getHyper $index]
		if {[catch {text_wcmd $w readvar $hypername} hyper]} {
		    set hyper ""
		} else {
		    if {$lastindex eq $index} {
			# Hyper tag is after the color tag.
			set prev [lindex $res end]
			if {[llength $prev] == 2} {
			    lappend prev $hyper
			    lset res end $prev
			    set hyper {}
			}
		    }
		}
	    } else {
	        set hyper ""
	    }
	    continue
	}
	if {![regexp -- {^user:color(\d+)$} $tag -> color]} {
	    set hyper ""
	    continue
	}
	if {$on == "tagon"} {
	    if {$hyper ne ""} {
		lappend res [list $index $color $hyper]
	    } else {
		lappend res [list $index $color]
	    }
	    set lastindex $index
	} else {
	    if {$color == 15} {
		lappend res [list $index 12]
	    } else {
		lappend res [list $index 0]
	    }
	    set lastindex {}
	}
	set hyper {}
    }
    set res
}
#¥ insertAscii - prompts for an ASCII code and inserts
#  into text.
proc insertAscii {} {
    set ascii [getline "Ascii code:"]
    if {[catch {format {%c} $ascii} text]} {
	error "Cancelled - $text"
    }
    insertText $text
}
#¥ mousePos - Returns list <row,col> of mouse position, if the mouse is 
#  currently over the active window. Otherwise, return error (catch w/ 
#  'catch').
proc mousePos {} {
    screenToDistance [winfo pointerx .] [winfo pointery .]
}


