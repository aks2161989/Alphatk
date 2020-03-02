## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "browserMode.tcl"
 #                                          created: 04/05/1998 {09:30:54 PM}
 #                                      last update: 03/21/2006 {04:07:41 PM}
 # Description:
 # 
 # Provides supports for 'browser' windows.
 # Alpha cannot do batch searches without this file.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::mode [list Brws Browser] 14.1.4 dummyBrws {} {
} {
    # Initialization script.
    alpha::internalModes "Brws" "Browser"
    # Define these variables here so they can be used elsewhere before
    # the mode is loaded
    namespace eval browse {
	variable separator [string repeat "-" 200]
	if {$::alpha::macos} {
	    variable char \u221e
	} else {
	    variable char \u00a9
	}
	variable jumpTo "[string repeat \t 30]$char"
    }
} maintainer {
} description {
    Provides support for displaying batch search result windows
} help {
    During a batch search, a list of all matching lines are displayed in a
    Brws window.  By using the arrow keys and the return key, you can easily
    jump to the correct file and line of the match you desire.  See the
    "Browser-Example" for a demonstration -- click on any fileset which
    appears in the dialog to see a Browser window.

    The browser windows are displayed this special 'Brws' mode, which has
    keyboard shortcuts for three primary operations:
    
    (1) Move up one line in the window and select the line
    
	Up-Arrow
	Control-P
	Delete

    (2) Move down one line in the window and select the line
    
	Down-Arrow
	Control-N
	Space
    
    (3) Go to match
    
	Return
	Enter
	Control-C Control-C

    There is also a very useful "Search > Next Match" menu command available.
    Regardless which window is frontmost, it brings the browser window to the
    front, navigates down one line, and goes to the match of that line.  Thus,
    this gives you a quick way to jump to all matches without having to
    manually bring the browser window to the front.
    
    There are some other preferences: Mode-Brws that can be set.
    
    This mode is not intended for text editing.  However Brws mode batch
    find windows can be saved to disk and then re-opened at a later time
    and all the above functionality will still work.
}

proc browserMode.tcl {} {}

namespace eval browse {}

newPref variable whenJumpingToWindow "Resize width and height" Brws "" \
  [list "Resize width and height" "Resize height only" "Bring to front only"]

hook::register activateHook browse::activateHook Brws

Bind '\r'	{browse::Select [getPos];browse::Goto}  Brws
Bind Enter	{browse::Select [getPos];browse::Goto}  Brws
# Enter:
ascii 0x3  	{browse::Select [getPos];browse::Goto}  Brws
Bind Down 	browse::Down Brws
Bind Up 	browse::Up   Brws
Bind 'n' <z>	browse::Down Brws
Bind 'p' <z>	browse::Up   Brws
# Space bar:
ascii 0x20	browse::Down Brws
# Backspace:
ascii 0x8	browse::Up   Brws
# this was below.  do we need it?
Bind 'c' <Cz>	{browse::Select [getPos];browse::Goto}


proc dummyBrws {} {}

# Set this to 1 to test dynamic code
if {${alpha::platform} == "alpha"} {
    set browse::enableDynamic 0
} else {
    set browse::enableDynamic 1
}

proc browse::activateHook {name} {
    variable current
    set current $name
}

proc browse::firstPos {{win ""}} {
    global browse::separator

    if {$win == ""} {
	set win [win::Current]
    }
    set loc [search -w $win -n -f 1 -r 1 -s \
      "(\r|\n)${browse::separator}(\r|\n)" [minPos]]

    if {[llength $loc]} {
	return [lindex $loc 1]
    } else {
	return [pos::nextLineStart -w $win \
	  [pos::nextLineStart -w $win [minPos]]]
    }
}

proc browse::linePos {line {win ""}} {
    if {$win == ""} {
	set win [win::Current]
    } 
    set first [browse::firstPos $win]
    set rowCol [pos::toRowChar -w $win $first]
    return [pos::fromRowChar -w $win \
      [expr {[lindex $rowCol 0]+$line}] [lindex $rowCol 1]]
}

proc browse::replaceLine {line text {win ""}} {
    if {$win == ""} {
	set win [win::Current]
    } 
    set pos [browse::linePos $line $win]
    if {![is::Eol [string index $text end]]} {
        set text "${text}\r"
    } 
    setWinInfo -w $win read-only 0
    replaceText -w $win $pos [pos::nextLineStart -w $win $pos] $text
    # update doesn't work on AlphaX  8^(
    update 
    setWinInfo -w $win read-only 1
}

##
 # --------------------------------------------------------------------------
 # 
 # "browse::lookUpToInfinity" --
 # 
 # Searching backward, look for first line containing the infinity symbol
 # (which therefore also contains a full file path), and return the start of
 # the line containing that symbol.
 # 
 # --------------------------------------------------------------------------
 ##

proc browse::lookUpToInfinity {pos {w ""}} {

     if {![string length $w]} {
	 set w [win::Current]
     }
     set pp [search -w $w -n -s -f 0 -r 0 -- "$::browse::char" [pos::lineStart -w $w $pos]]
     if {[llength $pp]} {
	 return [pos::lineStart -w $w [lindex $pp 1]]
     } else {
	 error "Cancelled -- can't find the 'infinity' character (up)."
     }
}

##
 # --------------------------------------------------------------------------
 # 
 # "browse::lookDownToInfinity" --
 # 
 # Searching forward, look for first line containing the infinity symbol
 # (which therefore also contains a full file path), and return the start of
 # the line containing that symbol.
 # 
 # --------------------------------------------------------------------------
 ##

proc browse::lookDownToInfinity {pos {w ""}} {

     if {![string length $w]} {
	 set w [win::Current]
     }
     set pp [search -w $w -n -s -f 1 -r 0 -- "$::browse::char" [pos::lineStart -w $w $pos]]
     if {[llength $pp]} {
	 return [pos::lineStart -w $w [lindex $pp 1]]
     } else {
	 error "Cancelled -- can't find the 'infinity' character (down)."
     }
}

proc browse::Up {{win ""}} {
    if {$win == ""} { set win [win::Current] }
    set pos [getPos -w $win]
    set pos [pos::lineStart -w $win $pos]
    if {![catch {browse::lookUpToInfinity $pos $win} pos]} {
	browse::Select $pos $win
    } else {
	status::msg "No further items in this window."
    }
}

proc browse::Down {{win ""}} {
    if {$win == ""} { set win [win::Current] }
    set pos [selEnd -w $win]
    set pos [pos::lineStart -w $win $pos]
    if {![catch {browse::lookDownToInfinity $pos $win} pos]} {
	browse::Select $pos $win
    } else {
	status::msg "No further items in this window."
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "browse::Select" --
 # 
 # Given a position within a "Brws" window, select the lines which contain the
 # data of the browser listing.  If "pos" is not within such a data point, the
 # preceding data point (if any) will be selected -- if no preceding point was
 # found, the following data point will be selected.  If no data points were
 # found within the window, its entire contents will be selected.
 # 
 # Following the highlighting of the relevant text, a status message will
 # display the relative position of the selected data point.  When the number
 # of data points is high (i.e. > 1000) the dual [regexp] calls are a little
 # time-consuming -- if there is a more efficient method for counting "$::browse::char"
 # before/after a given position, we should optimize the block of code that
 # creates the "marks1/2" variables.
 # 
 # --------------------------------------------------------------------------
 ##

proc browse::Select {pos {w ""}} {
    global browse::current
    
    if {![string length $w]} {
	set w [win::Current]
    }
    if {[pos::compare -w $w $pos >= [pos::max -w $w]]} {
	set pos [pos::prevLineStart -w $w $pos]
    }
    set pos1 [browse::firstPos $w]
    set pos2 [pos::max -w $w]
    catch {
	set posU [browse::lookUpToInfinity $pos $w]
	set pos1 [pos::nextLineStart -w $w $posU]
    }
    catch {
	set posD [browse::lookDownToInfinity $pos $w]
	set pos2 [pos::nextLineStart -w $w $posD]
    }
    set marks1 [regexp -all -- "$::browse::char" [getText -w $w [pos::min -w $w] $pos1]]
    set marks2 [regexp -all -- "$::browse::char" [getText -w $w $pos2 [pos::max -w $w]]]
    goto -w $w [pos::prevLineStart -w $w $pos2]
    selectText -w $w $pos1 $pos2
    refresh -w $w
    set n1 [expr {$marks1 + 1}]
    set n2 [expr {$marks1 + $marks2 + 1}]
    status::msg "Item (${n1}) of (${n2})"
    set browse::current $w
    return
}

proc nextMatch {{wname "*Batch Find*"}} {
    browse::nextPrevMatch 1 $wname
}

proc prevMatch {{wname "*Batch Find*"}} {
    browse::nextPrevMatch 0 $wname
}

proc dispErr {{win "* Compiler Errors *"}} {
    if {[string length $win]} {
	set text [getText -w $win [getPos -w $win] [selEnd -w $win]]
	if {[regexp "(Line.*)$::browse::char" $text dummy sub]} {
	    status::msg "$sub"
	}
    }
}
		
proc browse::nextPrevMatch {{dir 1} {wname "*Batch Find*"}} {
    variable current
    if {[info exists current] && [win::Exists $current]} {
	set win $current
    } else {
	set wins [winNames]
	set res [lsearch $wins $wname]
	if {$res < 0} {
	    set res [lsearch -regexp $wins {\*.*\*}]
	    if {$res < 0} {
		status::msg "No browsable window is open"
		return
	    }
	}
	set win [lindex $wins $res]
    }
    
    if {$dir} {
	browse::Down $win
    } else {
	browse::Up $win
    }
    browse::Goto $win
    dispErr $win
}


##############################################################################
#  To be used in the windows created by "matchingLines" or by batch searches.
#
#  With the cursor positioned in a line corrsponding to a match, 
#  go back and select the line in the original file that 
#  generated this match.  (Like emacs 'Occur' functionality)
#  
#  Any code can register a "browse::GotoProc" entry for a window name to call
#  a specific procedure.  This registered proc must accept a "-w $w" argument
#  and decide if that window should be brought to the front before performing
#  any action.
#
proc browse::Goto {{win ""}} {
    if {$win == ""} { set win [win::Current] }
    global browse::GotoProc BrwsmodeVars
    foreach pat [array names browse::GotoProc] {
	if {[string match $pat [win::Tail $win]]} {
	    if {($win eq [win::Current])} {
		[set browse::GotoProc($pat)]
	    } else {
		eval [list [set browse::GotoProc($pat)] -w $win]
	    }
	    return
	}
    }
    global tileHeight tileWidth tileTop tileLeft tileHeight \
      errorHeight errorDisp tileMargin browse::current
    set browse::current $win
    set loc [getPos -w $win]
    set ind1 -1
    while {$ind1 < 0} {
	set text [getText -w $win [pos::lineStart -w $win $loc] \
	  [pos::nextLineStart -w $win $loc]]
	set ind1 [string first "$::browse::char" $text]
	set loc [pos::nextLineStart -w $win $loc]
	if {[pos::compare -w $win $loc == [pos::max -w $win]]} {break}
    }
    set ind2 [string last "$::browse::char" $text]
    if {$ind1 == $ind2} {
	set fname [string trim [string range $text $ind1 end] "$::browse::char\r\n"]
	set msg ""
    } else {
	set tmp [string trim [string range $text 0 $ind2] "$::browse::char\r\n"]
	if {[string last "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t$::browse::char" $tmp] < 0} {
	    set fname [string trim [string range $text $ind2 end] "$::browse::char\r\n"]
	    set msg ""
	} else {
	    set ind1 [string last "$::browse::char" $tmp]
	    set fname [string trim [string range $text $ind1 $ind2] "$::browse::char\r\n"]
	    set msg [string trim [string range $text $ind2 end] "$::browse::char\r\n"]
	}
    }
    set loc [getPos -w $win]
    set line -1
    while {1} {
	if {[regexp {Line ([0-9]+):} $text "" line]} {break}
	set text [getText -w $win [pos::lineStart -w $win $loc]\
	  [pos::nextLineStart -w $win $loc]]
	set loc [pos::math -w $win [pos::lineStart -w $win $loc] - 1]
	if {[pos::compare -w $win $loc <= [minPos]]} {
	    # It's a browse window without line numbers, since we've
	    # backed up to the top of the window.
	    set line -1
	    break
	}
    }
    
    if {![win::infoExists $win overrideGeometry]} {
	set top $tileTop
	set geo [getGeometry $win]
	if {([lindex $geo 0] != $tileLeft) || ([lindex $geo 1] != $top) \
	  || ([lindex $geo 3] != $errorHeight) } {
	    switch -- $BrwsmodeVars(whenJumpingToWindow) {
		"Resize width and height" {
		    moveWin $win $tileLeft $top
		    sizeWin $win $tileWidth $errorHeight
		}
		"Resize height only" {
		    moveWin $win [lindex $geo 0] $top
		    sizeWin $win [lindex $geo 2] $errorHeight
		}
	    }
	}
	set mar $tileMargin
	incr top [expr {$errorHeight + $mar}]
	if {[browse::OpenWindow $fname]} {
	    # Nothing needed here -- the window is already set up for us.
	} else {
	    if {![string match "*Link*" \
	      [getText -w $win [minPos] [pos::nextLineStart -w $win [minPos]]]]} {
		alertnote "File \"$fname\" not found." 
	    }
	    return
	}
	# Now the new window is in front
	if {$line >= 0} {
	    set pos [pos::fromRowChar $line 0]
	    selectText $pos [pos::nextLineStart $pos]
	}
    } else {
	file::gotoLine $fname $line
    }
    status::msg $msg
}

# JK (August 2005): modified to use [openWithTemporaryGeometry], to avoid 
# saving the peculiar browser geometries to the resource fork of each file.
proc browse::OpenWindow {fname} {
    global tileHeight tileWidth tileTop tileLeft tileHeight \
      errorHeight errorDisp tileMargin defWidth BrwsmodeVars
    if {[file exists $fname]} {
	set top $tileTop
	set mar $tileMargin
	incr top [expr {$errorHeight + $mar}]
	switch -- $BrwsmodeVars(whenJumpingToWindow) {
	    "Resize width and height" {
		openWithTemporaryGeometry $fname $tileLeft $top $tileWidth $errorDisp
		# What is the following good for?
		set geo [getGeometry]
		if {([lindex $geo 0] != $tileLeft) || ([lindex $geo 1] != $top) \
		  || ([lindex $geo 2] != $tileWidth) || ([lindex $geo 3] != $errorDisp) } {
		    sizeWin $tileWidth $errorDisp
		    moveWin $tileLeft $top
		}
	    }
	    "Resize height only" {
		openWithTemporaryGeometry $fname
		set geo [getGeometry]
		if {([lindex $geo 0] != $tileLeft) || ([lindex $geo 1] != $top) \
		  || ([lindex $geo 3] != $errorDisp) } {
		    sizeWin [lindex $geo 2] $errorDisp
		    moveWin $tileLeft $top
		}
	    }
	    "Bring to front only" {
		edit -c -w $fname
	    }
	}
	return 1
    } else {
	return 0
    }
}

set browse::lastMatchingLines ""

proc matchingLines {{reg ""} {for 1} {ign 1} {word 0} {regexp 1}} {
    global browse::lastMatchingLines browse::separator
	
    if {![string length $reg] && \
      [catch {prompt "Regular expression:" [set browse::lastMatchingLines]} reg]} return
    set browse::lastMatchingLines $reg
    if {![string length $reg]} return
    if {!$regexp} {
	set reg [quote::Regfind $reg]
    }
    if {$word} {
	set reg "^.*\\b$reg\\b.*$"
    } else {
	set reg "^.*$reg.*$"
    }
    set pos [expr {$for ? [minPos] : [getPos]}]
    set fileName [win::StripCount [win::Current]]
    set matches 0
    browse::Start {* Matching Lines *} \
      "%d matching lines (<cr> to go to match)\r${browse::separator}" 
    while {![catch {search -s -f 1 -r 1 -i $ign -- $reg $pos} mtch]} {
	browse::Add $fileName [eval getText $mtch] \
	  [lindex [pos::toRowChar [lindex $mtch 0]] 0] 0
	set pos [lindex $mtch 1]
	incr matches
    }
    browse::Complete
}

## 
 # -------------------------------------------------------------------------
 # 
 # "grepsToWindow" --
 # 
 #  'args' is a list of items
 # -------------------------------------------------------------------------
 ##
proc grepsToWindow {title args} {
    global tileLeft tileTop tileWidth tileHeight errorHeight
    win::SetProportions
    set win [new -n $title -g $tileLeft $tileTop $tileWidth $errorHeight \
      -m Brws -tabsize 8 -info [join $args ""]]
    browse::Select [minPos] $win
    status::msg ""
    return $win
}

## 
 # -------------------------------------------------------------------------
 # 
 # "browse::Format" --
 # 
 #  Can be used by external code to ensure browse information is in an
 #  acceptable format, and to simplify external code.
 # -------------------------------------------------------------------------
 ##
proc browse::Format {file match line {withname 1} {prefix ""}} {
    append res $prefix
    if {$withname} {
	set l [expr {40 - [string length [file tail $file]]}]
	append res "\"[file tail $file]\"; " [format "%$l\s" ""] " "
    } else {
	regsub -all "\t" $match "  " match
    }
    append res [format "Line %d:\r" $line] $match \
      "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t$::browse::char$file"
    return $res
}

proc browse::RedoCount {} {
    global browse::count
    set oldcount [search -w [set browse::haveWindow]\
      -f 1 -m 0 -s -r 1 "\[0-9\]+" [minPos]]
    eval [list replaceText -w [set browse::haveWindow]]\
      $oldcount [list [set browse::count]]
}

proc browse::Complete {} {
    global browse::lines browse::none browse::haveWindow browse::count
    if {[string length [set browse::haveWindow]]} {
	bringToFront [set browse::haveWindow]
	browse::RedoCount
	goto -w [set browse::haveWindow] [minPos]
	browse::Select [minPos] [set browse::haveWindow]
	setWinInfo -w [set browse::haveWindow] read-only 1
	set ret 0
    } else {
	if {[set browse::count]} {
	    browse::createWindow
	    setWinInfo -w [set browse::haveWindow] read-only 1
	    browse::Select [minPos] [set browse::haveWindow]
	    set ret 0
	} else {
	    beep
	    status::msg [set browse::none]
	    set ret 1
	}
    }
    return $ret
}

proc browse::createWindow {} {
    global tileLeft tileTop tileWidth tileHeight errorHeight \
      browse::lines browse::title browse::prefix browse::haveWindow \
      browse::backGround browse::count
    if {[set browse::backGround]} {set w [win::Current]}
    win::SetProportions
    set browse::haveWindow [new -n [set browse::title] \
      -g $tileLeft $tileTop $tileWidth $errorHeight -m Brws \
      -tabsize 8 -shell 1 \
      -text "[format [set browse::prefix] [set browse::count]]\r[join [set browse::lines] \r]\r"]
    set browse::lines {}
    if {[set browse::backGround]} {bringToFront $w}
    status::msg ""
}

proc browse::updateWindow {} {
    global browse::haveWindow browse::lines
    placeText -w [set browse::haveWindow] [pos::max -w [set browse::haveWindow]] "[join [set browse::lines] \r]\r"
    browse::RedoCount
    set browse::lines {}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "browse::Add" --
 # 
 #  Add the information to our list of browse items.  We can actually 
 #  add these dynamically to the window if we like.
 # -------------------------------------------------------------------------
 ##
proc browse::Add {file match line {withname 1} {prefix ""}} {
    global browse::lines browse::dynamic browse::haveWindow browse::count
    lappend browse::lines [browse::Format $file $match $line $withname $prefix]
    incr browse::count
    if {[set browse::dynamic]} {
	if {[string length [set browse::haveWindow]]} {
	    browse::updateWindow
	} else {
	    browse::createWindow
	}
	global alpha::platform
	if {${alpha::platform} != "alpha"} {update}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "browse::Dynamic" --
 # 
 #  Somewhat experimental.
 # -------------------------------------------------------------------------
 ##
proc browse::Dynamic {{backgd 0} {dyn 1}} {
    global browse::dynamic browse::haveWindow browse::backGround \
      browse::enableDynamic
    if {![set browse::enableDynamic]} {return}
    set browse::dynamic $dyn
    set browse::haveWindow ""
    set browse::backGround $backgd
}

proc browse::Start {{theTitle {* Matching Lines *}} \
  {thePrefix "%d matching lines (<cr> to go to match)"} \
  {ifNone "No matches found."}} {
    global browse::lines browse::title browse::prefix browse::none \
      browse::dynamic browse::haveWindow browse::backGround browse::count \
      browse::separator
    set browse::lines {}
    set browse::title $theTitle
    set browse::prefix "${thePrefix}[string repeat \t 30](mode:Brws)\r${browse::separator}"
    set browse::none $ifNone
    set browse::dynamic 0
    set browse::haveWindow ""
    set browse::backGround 0
    set browse::count 0
}

# ===========================================================================
# 
# .