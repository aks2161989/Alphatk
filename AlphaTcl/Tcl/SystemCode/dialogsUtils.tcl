## -*-Tcl-*- (nowrap)
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "dialogsUtils.tcl"
 #                                    created: 01-08-13 17.38.38 
 #                                last update: 04/18/2006 {05:21:22 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Much copyright (c) 1997-2006  Vince Darley, all rights reserved, 
 # rest Pete Keleher, Johan Linde.
 # 
 # Reorganisation carried out by Vince Darley with much help from Tom 
 # Fetherston, Johan Linde and suggestions from the alphatcl-developers mailing list.  
 # Alpha is shareware; please register with the author using the register 
 # button in the about box.
 # 
 # This file contains helper procedures used by the other dialogs
 # code.  Most likely you will not need to call these procedures
 # directly in your code, unless you are really building your own
 # dialogs piece by piece.
 # ###################################################################
 ##

namespace eval dialog {}
namespace eval global {}

# ×××× Dialog utilities ×××× #

# We need to clarify some of these items.  In particular the 'Spacing'
# and 'Separation' items are somehow not given by getThemeMetrics.  The
# spacing values are (with the exception of TightCheckBoxSpacingY and
# CheckBoxSeparationX that haven't got official counterparts) taken from
# AquaMetrics.plist, where they don't have individual names.
proc dialog::metrics {arr} {
    upvar 1 $arr Metrics

    array set Metrics {CheckBoxHeight 18  CheckBoxWidth 18 \
      CheckBoxSpacingX 8  CheckBoxSpacingY 6 \
      CheckBoxSeparationX 3  TightCheckBoxSpacingY 3 \
      StaticTextSpacingX 8  StaticTextSpacingY 8 \
      PopupButtonHeight 16}

    catch {getThemeMetrics Metrics}
}

proc dialog::helpdescription {hlp} {
    set hlp [split $hlp |]
    if {[llength $hlp] <= 1} {
	return [lindex $hlp 0]
    }
    set res ""
    set len [llength $hlp]
    # Only examine the first 4 elements for help descriptions, since
    # the fifth element may be a v. large amount of text.
    if {$len > 4} { set len 4 }
    for {set hi 0} {$hi < $len} {incr hi} {
        # Remove extraneous spaces
	set hitem [string trimleft [lindex $hlp $hi]]
        set hitem [string trimright $hitem " \\"]
	if {$hitem ne ""} {
	    if {$hi == 0} {
		regsub "click this box\\.?" $hitem "turn this item on" hitem
	    } elseif {$hi == 2} {
		regsub "click this box\\.?" $hitem "turn this item off" hitem
	    }
            append hitem ". "
            # Don't include duplicates.
            if {$res ne $hitem} {
                append res $hitem
            }
	}
    }
    return $res
}

if {${alpha::platform} == "alpha"} {
    set dialog::strlength 253
} else {
    set dialog::strlength 2000
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::packagehelp" --
 # 
 #  Return help string useful for balloon help for a given package,
 #  in the format required by the 'dialog' command.
 # -------------------------------------------------------------------------
 ##
proc dialog::packagehelp {pkg} {
    global dialog::strlength
    set hlp [package::description $pkg]
    return "${hlp}||${hlp}"
}

proc dialog::getFlag {itemInfo} {
    return [dialog::valGet [lindex $itemInfo 0] [lindex $itemInfo 1]]
}

# Used on modified mode flags, for modes where the author hasn't
# specified a particular proc of its own.
set prefs::script(*,stringColor) "stringColorProc"
set prefs::script(*,commentColor) "stringColorProc"
set prefs::script(*,keywordColor) "stringColorProc"
set prefs::script(*,funcColor) "stringColorProc"
set prefs::script(*,sectionColor) "stringColorProc"
set prefs::script(*,bracesColor) "stringColorProc"

proc global::updateHelperFlags {} {
    uplevel #0 {
	set "flagPrefs(Helper Applications)" {}
	set "varPrefs(Helper Applications)" [lsort -dictionary [info globals *Sig]]
	global execSearchPath
	if {[info exists execSearchPath]} {
	    lappend "varPrefs(Helper Applications)" execSearchPath
	}
    }
}

proc global::updatePackageFlags {} {
    global flagPrefs varPrefs allFlags knownVars allVars
    # flags can be in either flagPrefs or varPrefs if we're grouping
    # preferences according to function
    set all {}
    set flagPrefs(Packages) {}
    set varPrefs(Packages) {}
    foreach v [array names flagPrefs] {
	eval lappend all $flagPrefs($v)
	if {[info exists varPrefs($v)]} {
	    if {[regexp {[{}]} $varPrefs($v)]} {
		# we're grouping
		foreach i $varPrefs($v) {
		    if {[llength $i] > 1} {
			eval lappend all [lrange $i 1 end]
		    } else {
			lappend all $i
		    }
		}
	    } else {
		eval lappend all $varPrefs($v)
	    }
	}
    }
    foreach f $allFlags {
	if {([lsearch -exact $knownVars $f] < 0)} {
	    if {[lsearch -exact $all $f] == -1} {
		lappend flagPrefs(Packages) $f
	    }
	}
    }
    
    foreach f $allVars {
	if {([lsearch -exact $knownVars $f] < 0)} {
	    if {[lsearch -exact $all $f] == -1} {
		if {[regexp {Sig$} $f]} {
		    lappend "varPrefs(Helper Applications)" $f
		} else {
		    lappend varPrefs(Packages) $f
		}
		lappend all $f
	    }
	}
    }
}

#================================================================================

proc maxListItemLength {l} {
    set m 0
    foreach item $l {
	if {[set mm [string length $item]] > $m} { set m $mm }
    }
    return $m
}

proc stringColorProc {flag} {
    global $flag mode
    
    if {[set $flag] == "none"} {
        set $flag "foreground"
    }
    if {$flag == "stringColor"} {
        regModeKeywords -a -s $stringColor $mode
    } elseif {$flag == "commentColor"} {
        regModeKeywords -a -c $commentColor $mode
    } elseif {$flag == "funcColor"} {
        regModeKeywords -a -f $funcColor $mode
    } elseif {$flag == "bracesColor"} {
        regModeKeywords -a -I $bracesColor $mode
    } elseif {($flag == "keywordColor") || ($flag == "sectionColor")} {
        alertnote "Change in keyword color will take effect after Alpha restarts."
        return
    } else {
        alertnote "Change in $flag color will take effect after Alpha restarts."
        return
    }
    refresh
}

# ×××× Dialog sub-items ×××× #

# Alphatk and Alpha8 can cope with setting dialog elements in place, via an extra
# '-set' flag.  This means we don't need to destroy and recreate the entire dialog
# when using a 'Set...' button.  This method produces the appropriate creation
# arguments for both the button and the optional set argument.  The set callback
# will be passed on to dialog::specialSet::<type> which will, in turn, arrange
# both for the change to be remembered and for the dialog to be updated in place
# (the last argument with which the callback is evaluated is the dialogItemId which
# can be used to modify the dialog in place)
proc dialog::buttonSet {mod x y args} {
    #alpha::log stdout [list $mod $x $y $args]
    set height 15
    if {[llength $args]} {
	set setCallback [dialog::makeSetCallback $mod -1 [lindex $args 0] [lindex $args 1]]
	return [list -b SetÉ -set $setCallback -font 2 \
	  $x $y [expr {$x + 45}] [expr {$y + $height}]]
    } else {
	return [list -b SetÉ -font 2 $x $y \
	  [expr {$x + 45}] [expr {$y + $height}]]
    }
}

# if (x < 0) then it specifies the leftmost edge.
# Place items in their /correct/ locations.
proc dialog::okcancel {x yy {vertical 0} {ok OK} {cancel Cancel}} {
    upvar 1 $yy y
    set yr $y
    if {$x < 0} {
	set i [dialog::button "$ok" "" y]
	if {$vertical} {
	    # want 10 pixel margin, but only get 6
	    incr y 4
	} else {
	    set y $yr
	}
	eval lappend i [dialog::button "$cancel" "" y]
    } else {
	set i [dialog::button "$ok" $x y]
	if {$vertical} {
	    # want 10 pixel margin, but only get 6
	    incr y 4
	} else {
	    set y $yr
	    incr x 80
	}
	eval lappend i [dialog::button "$cancel" $x y]
    }
    
    return $i
}

# Not supported yet.  Experimental and will change.
# Currently returns information on the height of the tabs
proc dialog::tab {x yy item {def "def"} {requestedWidth 0} {bodyHeight 30}} { 
    upvar 1 $yy y
    set m [concat [list $def] $item]
    if {$requestedWidth == 0} {
	set popUpWidth 340
    } else {
	set popUpWidth $requestedWidth 
    }
    
    metrics Metrics
    set res [list -tab $m $x $y [expr {$x + $popUpWidth}] \
      [expr {$y +$Metrics(PopupButtonHeight) + 7 + $bodyHeight}]]
    incr y $Metrics(PopupButtonHeight)
    incr y 10
    return $res
}

proc dialog::menu {x yy item {def "def"} {requestedWidth 0}} { 
    upvar 1 $yy y
    if {([lsearch -exact $item $def] == -1)} {
        if {$def ne ""} {
	    alpha::stderr "Invalid default value specified\
	      for \[dialog::menu\] (pop-up menu)\
	      \rlist:  $item\
	      \rvalue: $def"
	}
        set def [lindex $item 0]
    }
    set m [concat [list $def] $item]
    if {$requestedWidth == 0} {
        set popUpWidth 340
    } else {
        set popUpWidth $requestedWidth 
    }
    
    metrics Metrics
    set res [list -m $m $x $y [expr {$x + $popUpWidth}] \
      [expr {$y +$Metrics(PopupButtonHeight) + 7}]]
    incr y $Metrics(PopupButtonHeight)
    incr y 10
    return $res
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dialog::titledmenu" --
 # 
 # Create a dialog string with a titled pop-up menu.  If the "-mt" dialog
 # control is available the second version of this procedure is used.  'name'
 # is the text preceding the pop-up menu, x is the x position, yy is the name
 # of a variable containing the y position of both the title and the menu,
 # which will be incremented by this procedure.
 # 
 # The "requestedWidth" variable is the suggested width of the pop-up menu,
 # not the entire title-menu width.
 # 
 # --------------------------------------------------------------------------
 ##

if {![alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {

    proc dialog::titledmenu {x yy name item {def "def"} {requestedWidth 0}} { 
	upvar 1 $yy y
	set yTemp $y
	metrics Metrics
	set nameX [expr {$x+2+[lindex [getTextDimensions -font 0 -- $name] 2]}]
	set res [list -t $name $x $y $nameX \
	  [expr {$y+$Metrics(PopupButtonHeight) + 7}]]
	incr nameX 2
	set y $yTemp
	eval lappend res [dialog::menu $nameX y $item $def $requestedWidth]
	return $res
    }

} else {
    
    proc dialog::titledmenu {x yy name item {def "def"} {requestedWidth 0}} { 
	upvar 1 $yy y
	if {([lsearch -exact $item $def] == -1)} {
	    if {$def ne ""} {
		alpha::stderr "Invalid default value specified\
		  for \[dialog::menu\] (pop-up menu)\
		  \r    list:  $item\
		  \r    value: $def"
	    }
	    set def [lindex $item 0]
	}
	set m [concat [list $def] $item]
	metrics Metrics
	set nameX [lindex [getTextDimensions -font 0 -- $name] 2]
	if {($requestedWidth == 0)} {
	    set width [expr {$nameX+340}]
	} else {
	    set width [expr {$nameX+$requestedWidth}]
	}
	set res [list -mt $name $m $x $y [expr {$x+$width+5}] \
	  [expr {$y+$Metrics(PopupButtonHeight)+7}]]
	incr y $Metrics(PopupButtonHeight)
	incr y 10
	return $res
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::button" --
 # 
 #  Create a dialog string encoding one or more buttons.  'name' is the
 #  name of the button ("OK" etc), x is the x position, or if x is null,
 #  then we use the variable called 'x' in the calling procedure.  yy is
 #  the name of a variable containing the y position of the button, which
 #  will be incremented by this procedure.  if args is non-null, it
 #  contains further name-x-yy values to be lined up next to this button.
 #  For sequences of default buttons, a spacing of '80' is usual, but
 #  it's probably best if you just set the 'x' param to "" and let this
 #  procedure calculate them for you.  See dialog::yesno for a good
 #  example of calling this procedure.
 # -------------------------------------------------------------------------
 ##
if {${alpha::platform} == "tk"} {
    proc dialog::button {name x yy args} { 
	upvar 1 $yy y
	if {$x == ""} {
	    unset x
	    upvar 1 x x
	}
	set add [default::buttonWidth $name]

	if {$x < 0} {
	    set res [list -b $name [expr {-($x +$add)}] $y [expr {-$x}] [expr {$y +20}]]
	} else {
	    set res [list -b $name $x $y [expr {$x +$add}] [expr {$y +20}]]
	}
	
	incr x $add
	incr x 12
	if {[llength $args]} {
	    eval lappend res [eval dialog::button $args]
	    return $res
	}
	incr y 26
	
	return $res
    }
} elseif {${alpha::macos} == 2} {
    proc dialog::button {name x yy args} { 
	upvar 1 $yy y
	if {$x == ""} {
	    unset x
	    upvar 1 x x
	}
	set add [expr {22 + [dialog::text_width $name]}]
	if {$x < 0} {
	    set res [list -b $name [expr {-($x +$add)}] $y [expr {-$x}] [expr {$y +20}]]
	} else {
	    set res [list -b $name $x $y [expr {$x +$add}] [expr {$y +20}]]
	}
	
	incr x $add
	incr x 12
	if {[llength $args]} {
	    eval lappend res [eval dialog::button $args]
	    return $res
	}
	incr y 26
	
	return $res
    }
} else {
    proc dialog::button {name x yy args} { 
	upvar 1 $yy y
	if {$x == ""} {
	    unset x
	    upvar 1 x x
	}
	set add 58
	if {[set i [expr {[string length $name] - 7}]] > 0} { 
	    incr add [expr {$i * 7}]
	}
	if {$x < 0} {
	    set res [list -b $name [expr {-($x +$add)}] $y [expr {-$x}] [expr {$y +20}]]
	} else {
	    set res [list -b $name $x $y [expr {$x +$add}] [expr {$y +20}]]
	}
	
	incr x $add
	incr x 12
	if {[llength $args]} {
	    eval lappend res [eval dialog::button $args]
	    return $res
	}
	incr y 26
	
	return $res
    }
}

proc dialog::radiobuttons {name default x yy} {
    upvar 1 $yy y
    set res [list -r $name $default -font 2 $x $y]
    lappend res [expr {$x + 20 + [dialog::_reqWidth $name]}] [expr {$y +15}]
    incr y 18
    return $res
}

proc dialog::title {name w} {
    set l [expr {${w}/2 - 4 * [string length $name]}]
    if {$l < 0} {set l 0}
    return [list -T $name]
}

# Can be used like 'dialog::text' but is capable of producing multiple
# pages if the text is really long.
proc dialog::multipagetext {text x yy width} {
    upvar 1 $yy height
    
    set ystart $height

    set height 17
    set args {}
    set t $ystart
    set page 1
    set pages {}
    set lst {}
    
    #incr width -1
    
    foreach line [dialog::splitText $text $width] {
	if {$t > 360} {
	    # make another page
	    eval lappend pages -n [list "Page $page"] $args
	    eval lappend lst [list $args]
	    set args {}
	    incr page
	    if {$t > $height} {set height $t}
	    set t $ystart
	}
	eval [list lappend args] [dialog::text $line $x t $width]
	incr t -10
    }
    if {$t > $height} {set height $t}
    if {$page > 1} {
	set t $height
	set height [expr {$t + 40}]
	for {set i 1} {$i <= $page} {incr i} {
	    lappend names "Page $i"
	}
	eval lappend pages [list -n "Page $page"] $args

	return [concat [list -m [concat [list [lindex $names 0]] $names] 400 10 475 30] $pages]
    } else {
	return $args
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::text" --
 # 
 #  Creates a text box wrapping etc the text to fit appropriately.
 #  In the input text 'name', "\r" is used as a paragraph delimiter,
 #  and "\n" is used to force a linebreak.  Paragraphs have a wider
 #  spread.
 # -------------------------------------------------------------------------
 ##
proc dialog::text {name x yy {split 0} args} {
    upvar 1 $yy y
    if {$split <= 0 || ![string length $name]} {
	if {$split < 0} {
	    set height [expr {15*[lindex $args 0]}]
	    set res [list -t $name $x $y [expr {$x - $split}] \
	      [incr y $height]]
	    incr y 3
	} else {
	    # 16 pixels high
	    set res [list -t $name $x $y [expr {$x + [dialog::text_width $name]}] \
	      [incr y 16]]
	    # 6 pixel gap from baseline to next element (-4 pixel descender)
	    incr y 2
	}
    } else {
	global dialog::strlength
	set name [string trim $name]
	set paragraphList [split $name "\r"]
	foreach para $paragraphList {
	    set lines ""
	    foreach line [split $para "\n"] {
		lappend lines [breakIntoLines $line $split 0]
	    }
	    set lines [join $lines "\r"]
	    set curline {}
	    set curlinecount 0
	    set curmax 0
	    foreach line [split $lines "\r"] {
		# Each '-t' dialog item can only be 255 characters long, and in Alpha 7
		# there are a limited number or total possible dialog items, so we try
		# to squash as much as possible into one -t item.
		if {([string length $curline] + [string length $line]) < [set dialog::strlength]} {
		    if {[string length $curline]} {append curline "\r"}
		    append curline $line
		    incr curlinecount
		    #set xx [dialog::_reqWidth $line]
		    set xx [expr {8 * [string length $line]}]
		    if {$xx > $curmax} { set curmax $xx }
		} else {
		    eval lappend res [list -t $curline $x $y \
		      [expr {$x + 4 + $curmax}] [expr {$y + 16 * $curlinecount -3}]]
		    incr y [expr {16 * $curlinecount}]
		    set curline $line
		    set curlinecount 1
		    #set curmax [dialog::_reqWidth $line]
		    set curmax [expr {8 * [string length $line]}]
		}
	    }
	    # handle the last item.
	    eval lappend res [list -t $curline $x $y \
	      [expr {$x + 4 + $curmax}] [expr {$y + 17 * $curlinecount -3}]]
	    incr y [expr {16 * $curlinecount}]
	    incr y 10
	}
	if {![info exists res]} {
	    set res [list -t $name $x $y [expr {$x + 7 * [string length $name]}] \
	      [expr {$y +15}]]
	    incr y 18
	}
    }
    return $res
}

proc dialog::splitText {name split} {
    set name [string trim $name]
    set paragraphList [split $name "\r"]
    
    set res [list]
    
    foreach para $paragraphList {
	set lines ""
	foreach line [split $para "\n"] {
	    lappend lines [breakIntoLines $line $split 0]
	}
	set lines [join $lines "\r"]
	eval [list lappend res] [split $lines "\r"]
    }
    return $res
}

proc dialog::edit {name x yy chars {rows 1}} {
    upvar 1 $yy y
    set res [list -e $name $x $y [expr {$x + 10 * $chars}] [expr {$y + 15 * $rows}]]
    incr y [expr {5 + 15*$rows}]
    return $res
}
proc dialog::textedit {name default x yy chars {height 1} {horiz 0}} {
    upvar 1 $yy y
    set xx [dialog::_reqWidth $name]
    set res [list -t $name $x $y [expr {$x + $xx}]\
      [expr {$y +16}] -e $default]
    if {$horiz} {
	incr x $horiz
    } else {
	incr y 22
    }
    lappend res $x $y [expr {$x + 10 * $chars}] \
      [expr {$y + 16*$height}]
    incr y [expr {9 + 16*$height}]
    return $res
}

if {${alpha::platform} == "alpha"} {
    proc dialog::checkbox {name default x yy} {
	upvar 1 $yy y
	set res [list -c $name $default -font 2 $x $y]
	lappend res [expr {$x + 20 + [dialog::_reqWidth $name]}] [expr {$y +15}]
	incr y 18
	return $res
    }
} else {
    proc dialog::checkbox {name default x yy} {
	upvar 1 $yy y
	metrics Metrics
	set res [list -c $name $default -font 2 $x $y]
	lappend res [expr {$x + [dialog::_reqWidth $name]}] \
	  [expr {$y + $Metrics(CheckBoxHeight)}]
	incr y $Metrics(CheckBoxHeight)
	incr y $Metrics(CheckBoxSpacingY)
	return $res
    }
}

if {${alpha::platform} == "alpha"} {
    proc dialog::_reqWidth {args} {
       set width 0
       foreach str $args {
	  set w [dialog::text_width $str]
	  if {$w>$width} then {set width $w}
       }
       set width
    }
} else {
    proc dialog::_reqWidth {args} {
	set width 0
	foreach str $args {
	   set w [default::buttonWidth $str]
	   if {$w>$width} {set width $w}
	}
	set width
    }
    proc dialog::_reqWidth {args} {return 0}
}

# ×××× Manipulation of special pref types ×××× #

# This function needs to be passed an appropriate width and then
# it needs to check whether the size of the 'view' it calculates
# is greater than that width, and only abbreviate in that case.

proc dialog::specialViewAndAbbreviate {type val args} {
    set view [dialog::specialView::$type $val]
    switch -- $type {
	"file" - "sig" - "folder" - "io-file" - "url" {
	    if {[set sl [string length $view]] > 33} {
		set view "[string range $view 0 8]...[string range $view [expr {$sl -21}] end]"
	    }
	}
	"File" {
	    if {([set maxLen [lindex $args 0]] eq "")} {
	        set maxLen "45"
	    }
	    set legs [lreverse [::file split $view]]
	    set name [lindex $legs 0]
	    set root [lindex $legs end]
	    set legs [lreplace $legs 0 0]
	    set legs [lreplace $legs end end] 
	    
	    incr maxLen [expr {-[string length $name]-1}]
	    incr maxLen [expr {-[string length $root]-1}]
	    
	    set path {}

	    foreach leg $legs {
		if {[string length $leg] <= $maxLen} {
		    lappend path $leg
		    incr maxLen [expr {-[string length $leg]}]
		} else {
		    lappend path "É"
		    break
		}
	    }
	    set view [eval ::file join $root [lreverse $path] $name]
	}
	default {
	    # nothing
	}
    }
    return $view
}

namespace eval dialog::specialView {}
namespace eval dialog::specialSet {}

proc dialog::specialView::binding {key} {
    append key1 [keys::modifiersTo $key "verbose"]
    append key1 [keys::verboseKey $key]
    if {$key1 == ""} { return "<no binding>" }
    return $key1
}

proc dialog::specialSet::binding {itemInfo {dialogItemId ""}} {
    # SetÉ pressed
    set oldB [dialog::getFlag $itemInfo]
    if {![catch {dialog::getAKey [quote::Prettify [::dialog::_getName $itemInfo]] $oldB 0} newKey] \
      && $newKey != $oldB} {
	dialog::modified $itemInfo $newKey $dialogItemId
    }
}

proc dialog::specialSet::menubinding {itemInfo {dialogItemId ""}} {
    # SetÉ pressed
    set oldB [dialog::getFlag $itemInfo]
    if {![catch {dialog::getAKey [quote::Prettify [::dialog::_getName $itemInfo]] $oldB 1} newKey] && $newKey != $oldB} {
	dialog::modified $itemInfo $newKey $dialogItemId
    }
}

proc dialog::specialSet::sig {itemInfo {dialogItemId ""}} {
    set old [dialog::getFlag $itemInfo]
    set newval [dialog::findApp [::dialog::_getName $itemInfo] "" $old]
    if {($newval != "") && ($newval != $old)} {
	dialog::modified $itemInfo $newval $dialogItemId
    }
}

proc dialog::specialSet::folder {itemInfo {dialogItemId ""}} {
    set old [dialog::getFlag $itemInfo]
    set title "New [quote::Prettify [::dialog::_getName $itemInfo]]"
    if {[catch {get_directory -p $title $old} newval]} {
	return
    }
    dialog::modified $itemInfo $newval $dialogItemId
}

proc dialog::specialSet::_asyncmakeGeomWindow {setter geom itemInfo} {
    set t "Click here to set the window geometry,\rclose this\
      window to leave it unchanged.\r\r"
    set opts [list]
    eval lappend opts $geom
    lappend opts -n "* Resize To Desired Geometry *" -info $t
    set w [eval ::new $opts]
    set t [search -w $w -f 1 -r 0 -s -- here [minPos]]
    eval [list text::color -w $w] $t green
    set hyper [list dialog::specialSet::_asyncSetFromWindow $setter]
    eval [list text::hyper -w $w] $t [list $hyper]
    refresh -w $w
    return
}

proc dialog::specialSet::_asyncSetFromWindow {setter} {
    eval $setter [list "-g [getGeometry]"]
    status::msg "Window geometry set."
    killWindow
}

# Used for setting any 'geometry' preference from a dialog, which
# may be the system-wide default geometry, or any package's 
# geometry preferences.
proc dialog::specialSet::asyncGeometry {setter itemInfo {dialogItemId ""}} {
    set dial [list dialog::make -title "Set Default Geometry"]
    set txt "Please choose how you would like to edit the window geometry"
    set options [list "Open a new window for re-sizing" \
      "Use default" "Enter pixel lengths 'manually'"]
    if {[llength [winNames]]} {
        lappend options "Use the active window's geometry"
    }
    if {([llength [winNames]] > 1)} {
        lappend options "Choose an open window's geometry"
    }
    # Add an unnamed page with the text and popup menu
    lappend dial [list "" \
      [list text $txt] [list [list menu $options] "Method:" ""]]
    
    switch -- [lindex [eval $dial] 0] {
        "Use default" {
            # Set the preference to the empty string, which
            # results in the code using whatever it considers
            # the default value.
            dialog::modified $itemInfo {} $dialogItemId
        }
        "Open a new window for re-sizing" {
            set old [dialog::getFlag $itemInfo]
            if {$dialogItemId != ""} {
                dialog::setValue $dialogItemId $itemInfo " $old"
            }
            status::msg "You'll get a chance to edit this preference *after*\
              you click OK."
            dialog::specialSet::_asyncmakeGeomWindow $setter $old $itemInfo
        }
        "Enter pixel lengths 'manually'" {
            # Create a dialog in which the new values can be set.  This
            # dialog could really be a lot nicer!
            set newG [list]
            while {1} {
                set okay 1
                set p "Enter values for Left, Top, Width, Height"
                set newG [prompt $p $newG]
                if {![is::List $newG] || ([llength $newG] != 4)} {
                    alertnote "You must enter four unique values"
                    continue
                }
                foreach v $newG {
                    if {![regexp -- {^[0-9]+$} $v]} {
                        alertnote "Each value must be a number!"
                        set okay 0
                        break
                    }
                }
                if {$okay} {
                    break
                }
            }
            dialog::modified $itemInfo [concat [list -g] $newG] $dialogItemId
        }
        "Use the active window's geometry" {
            if {[win::Current] eq ""} {
                status::msg "Cancelled: No open window"
                return
            }
            set newG [getGeometry]
            dialog::modified $itemInfo [concat [list -g] $newG] $dialogItemId
        }
        "Choose an open window's geometry" {
            # Choose the geometry from an open window.
            set p "Use which window's geometry?"
            set windowPaths [winNames -f]
            set windowTails [winNames]
            set w [listpick -p $p $windowTails]
            set w [lindex $windowPaths [lsearch $windowTails $w]]
            set newG [getGeometry $w]
            dialog::modified $itemInfo [concat [list -g] $newG] $dialogItemId
        }
    }
    return
}

proc dialog::specialView::geometry {v} {
    switch -regexp -- $v {
	^$ {return "Default"}
	{^ } {return "Edit after pressing OK"}
	default {
	    return "\[[lindex $v 1],[expr {[lindex $v 1]+[lindex $v 3]}]\]\
	      x \[[lindex $v 2],[expr {[lindex $v 2]+[lindex $v 4]}]\]"
	}
    }
}

proc dialog::specialView::menubinding {key} {
    dialog::specialView::binding $key
}

if {![alpha::package vsatisfies -loose [dialog::coreVersion] 2.1] 
|| $alpha::platform eq "tk"} {
proc dialog::specialView::searchpath {vv} {
    if {[llength $vv]} {
	foreach ppath $vv {
	    lappend view [dialog::specialView::file $ppath]
	}
	return [join $view "\r"]
    } else {
	return "No search paths currently set."
    }
}

proc dialog::specialView::filepaths {vv} {
    if {[llength $vv]} {
	foreach ppath $vv {
	    lappend view [dialog::specialView::file $ppath]
	}
	return [join $view "\r"]
    } else {
	return "No file paths currently set."
    }
}
}

proc dialog::specialView::sig {vv} {
    if {$vv != ""} {
	if {[catch {nameFromAppl $vv} path]} {
	    return "Unknown application with sig '$vv'"
	} else {
	    return [dialog::specialView::file $path]
	}
    }
    return ""
}

proc dialog::specialView::folder {vv} {
    return $vv
}

proc dialog::specialView::io-file {vv} {
    return $vv
}
proc dialog::specialView::File {vv {maxLen 33}} {
    return $vv
}
proc dialog::specialView::file {vv} {
    return $vv
}
proc dialog::specialView::url {vv} {
    # Hide any password in the url
    if {[regsub -- {^([^:]+)://(([^:]*)(:([^@]*))@)(([^/]*)/(.*/)?([^/]*))$} \
      $vv {\1://\3:[string repeat \u2022 [string length \5]]@\6} hide]} {
	return [subst $hide]
    } else {
        return $vv
    }
}
proc dialog::specialView::date {vv} {
    return [clock format $vv]
}

proc dialog::specialSet::file {itemInfo {dialogItemId ""}} {
    # SetÉ pressed
    set old [dialog::getFlag $itemInfo]
    if {![catch {getfile [quote::Prettify "New [::dialog::_getName $itemInfo]"] $old} ff] \
      && $ff ne $old} {
	dialog::modified $itemInfo $ff $dialogItemId
    }
}
proc dialog::specialSet::url {itemInfo {dialogItemId ""}} {
    # SetÉ pressed
    set old [dialog::getFlag $itemInfo]
    if {![catch {dialog::getUrl "New URL for [quote::Prettify [::dialog::_getName $itemInfo]]" $old} ff] \
      && $ff != $old} {
	dialog::modified $itemInfo $ff $dialogItemId
    }
}
proc dialog::specialSet::date {itemInfo {dialogItemId ""}} {
    # SetÉ pressed
    set old [dialog::getFlag $itemInfo]
    if {![catch {dialog::getDate "New Date for [quote::Prettify [::dialog::_getName $itemInfo]]" $old} ff] \
      && $ff != $old} {
	dialog::modified $itemInfo $ff $dialogItemId
    }
}

proc dialog::specialSet::io-file {itemInfo {dialogItemId ""}} {
    # SetÉ pressed
    set old [dialog::getFlag $itemInfo]
    if {![catch {putfile [quote::Prettify "New [::dialog::_getName $itemInfo]"] $old} ff] \
      && $ff ne $old} {
	dialog::modified $itemInfo $ff $dialogItemId
    }
}
proc dialog::specialSet::searchpath {itemInfo {dialogItemId ""}} {
    
    global prefs::extraOptions
    
    set v [::dialog::_getName $itemInfo]
    set V [string trimright [lindex [split $v ","] end] ":"]
    set V "\"[quote::Prettify $V]\""
    if {[info exists prefs::extraOptions($v)]} {
	# ??  Is this used anywhere?  The "filepaths" pref should be used
	# instead of "searchpath".
	alertnote "Obsolete preference option: if the $V preference wants\
	  to set file paths instead of directories, it should make use of\
	  the \"FilePaths\" preference type.\r\rPlease report this to the\
	  AlphaTcl mailing list."
    }
    if {![llength [dialog::getFlag $itemInfo]]} {
	set result "Add Path"
    } else {
	set buttons [list \
	  "Remove PathÉ"  "Click here to remove a directory from the path list." \
	  {set retCode 1 ; set retVal "Remove Path"} \
	  "Change PathÉ"  "Click here to change one of path list directories." \
	  {set retCode 1 ; set retVal "Change Path"} \
	  ]
	set dialogScript [list dialog::make -title "Edit List Of Search Paths" \
	  -width 500 -ok "Add PathÉ" \
	  -okhelptag "Click here to add a new file to the path list."\
	  -addbuttons $buttons \
	  [list "" \
	  [list "text" "How do you want to edit the $V search paths?"]]]
	if {![catch $dialogScript result]} {
	    set result "Add Path"
	}
    }
    switch -- $result {
	"Add Path" {
	    # Add a search path to the list.
	    set p "New ${V}:"
	    set newPath ""
	    while {1} {
		if {[catch {get_directory -p $p $newPath} newPath]} {
		    return
		}
		set newVal [dialog::getFlag $itemInfo]
		lappend newVal $newPath
		dialog::modified $itemInfo $newVal $dialogItemId
		status::msg "Added: $newPath"
		if {![askyesno "Would you like to add another path?"]} {
		    break
		}
	    }
	}
	"Remove Path" {
	    set p "Remove which item(s) from ${V}?"
	    foreach oldValItem [set oldVal [dialog::getFlag $itemInfo]] {
		lappend OldValItems \
		  [dialog::specialViewAndAbbreviate "folder" $oldValItem]
	    }
	    if {[catch {listpick -p $p -l -indices $OldValItems} removeIdxs]} {
		return
	    }
	    # Remove them.
	    foreach itemIdx $removeIdxs {
		lappend removeList [lindex $oldVal $itemIdx]
	    }
	    set newVal [lremove $oldVal $removeList]
	    dialog::modified $itemInfo $newVal $dialogItemId
	}
	"Change Path" {
	    set p "Change which item in ${V}?"
	    while {1} {
		# Choose an item to replace.
		set OldValItems [list]
		foreach oldValItem [set oldVal [dialog::getFlag $itemInfo]] {
		    lappend OldValItems \
		      [dialog::specialViewAndAbbreviate "folder" $oldValItem]
		}
		if {[catch {listpick -p $p -indices $OldValItems} valIdx]} {
		    return
		}
		set oldPath [lindex $oldVal $valIdx]
		# Choose a replacement.
		set p "Replacement ${V}:"
		if {[catch {get_directory -p $p $oldPath} newPath]} {
		    break
		}
		# Change it.
		set newVal [lreplace $oldVal $valIdx $valIdx $newPath]
		dialog::modified $itemInfo $newVal $dialogItemId
		status::msg "Changed to: $newPath"
		set q "Would you like to change another path?"
		if {([llength $newVal] > 1) && ![askyesno $q]} {
		    break
		}
	    }
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dialog::specialSet::filepaths" --
 # 
 # Similar to [dialog::specialSet::searchpath] but specific to files rather
 # than directories.
 # 
 # --------------------------------------------------------------------------
 ##

proc dialog::specialSet::filepaths {itemInfo {dialogItemId ""}} {
    
    global prefs::extraOptions
    
    set v [::dialog::_getName $itemInfo]
    set V [string trimleft [lindex [split $v ","] end] ":"]
    set V "\"[quote::Prettify $V]\""
    set options [list "Add" "Remove" "Change" "Cancel"]
    set buttons [list]
    if {![llength [dialog::getFlag $itemInfo]]} {
	set result "Add Path"
    } else {
	set buttons [list \
	  "Remove PathÉ"  "Click here to remove a file from the path list." \
	  {set retCode 1 ; set retVal "Remove Path"} \
	  "Change PathÉ"  "Click here to change one of path list files." \
	  {set retCode 1 ; set retVal "Change Path"} \
	  ]
	set dialogScript [list dialog::make -title "Edit List Of File Paths" \
	  -width 500 -ok "Add PathÉ" \
	  -okhelptag "Click here to add a new file to the path list."\
	  -addbuttons $buttons \
	  [list "" \
	  [list "text" "How do you want to edit the $V file paths?"]]]
	if {![catch $dialogScript result]} {
	    set result "Add Path"
	}
    }
    if {[info exists prefs::extraOptions($v)]} {
	set types $prefs::extraOptions($v)
    } else {
	set types [list]
    }
    switch -- $result {
	"Add Path" {
	    # Add a file path to the list.
	    set p "New ${V}:"
	    set newPath ""
	    while {1} {
		if {[catch {getfile -types $types $p $newPath} newPath]} {
		    return
		}
		set newVal [dialog::getFlag $itemInfo]
		lappend newVal $newPath
		dialog::modified $itemInfo $newVal $dialogItemId
		status::msg "Added: $newPath"
		if {![askyesno "Would you like to add another path?"]} {
		    break
		}
	    }
	}
	"Remove Path" {
	    set p "Remove which item(s) from ${V}?"
	    foreach oldValItem [set oldVal [dialog::getFlag $itemInfo]] {
		lappend OldValItems \
		  [dialog::specialViewAndAbbreviate "file" $oldValItem]
	    }
	    if {[catch {listpick -p $p -l -indices $OldValItems} removeIdxs]} {
		return
	    }
	    # Remove them.
	    foreach itemIdx $removeIdxs {
		lappend removeList [lindex $oldVal $itemIdx]
	    }
	    set newVal [lremove $oldVal $removeList]
	    dialog::modified $itemInfo $newVal $dialogItemId
	}
	"Change Path" {
	    set p "Change which item in ${V}?"
	    while {1} {
		# Choose an item to replace.
		set OldValItems [list]
		foreach oldValItem [set oldVal [dialog::getFlag $itemInfo]] {
		    lappend OldValItems \
		      [dialog::specialViewAndAbbreviate "file" $oldValItem]
		}
		if {[catch {listpick -p $p -indices $OldValItems} valIdx]} {
		    return
		}
		set oldPath [lindex $oldVal $valIdx]
		# Choose a replacement.
		set p "Replacement ${V}:"
		if {[catch {getfile -types $types $p $oldPath} newPath]} {
		    break
		}
		# Change it.
		set newVal [lsort -dictionary -unique \
		  [lreplace $oldVal $valIdx $valIdx $newPath]]
		dialog::modified $itemInfo $newVal $dialogItemId
		status::msg "Changed to: $newPath"
		set q "Would you like to change another path?"
		if {([llength $newVal] > 1) && ![askyesno $q]} {
		    break
		}
	    }
	}
    }
    return
}

# ===========================================================================
# 
# .