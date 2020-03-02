## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "fileUtils.tcl"
 #                                          created: 03/26/1996 {02:10:38 pm}
 #                                      last update: 04/18/2006 {11:56:37 AM}
 # Description:
 # 
 # Additional "Utils > Win Utils" menu items.
 # 
 # Author: Vince Darley and others
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # --------------------------------------------------------------------------
 # 
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted conditions following provided that the are met:
 # 
 #  ¥ Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 # 
 #  ¥ Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 # 
 #  ¥ Neither the name of Alpha/Alphatk nor the names of its contributors may
 #    be used to endorse or promote products derived from this software
 #    without specific prior written permission.
 # 
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 # IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 # THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 # PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE
 # LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 # CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 # POSSIBILITY OF SUCH DAMAGE.
 # 
 # ==========================================================================
 ##

# ×××× Feature Declaration ×××× #
alpha::feature windowUtilities 1.3.2 "global-only" {
    # Initialization script.
    # This just makes it easier to change this list without having to
    # duplicate it in both the activation/deactivation scripts.
    namespace eval win {
	variable winUtilsMenuItems [list \
	  "insertModeLineÉ" \
	  "(-)" \
	  {Menu -n windowLines -p win::windowLinesMenuProc {
	    "numberLines"
	    "countDuplicateLines" \
	      "findUniqueLines" \
	      "findDuplicateLines" \
	      "findFirstDuplicateLines" \
	      "removeDuplicateLines" \
	      "(-)" \
	      "windowLinesHelp" \
	    }} \
	  "<E<SwindowTabsTo4" \
	  "<S<IwindowTabsTo8" \
	  "<E<SsortWords" \
	  "<S<IreverseSortWords" \
	  ]
    }
} {
    # Activation script.
    eval [list menu::insert   winUtils items end] $::win::winUtilsMenuItems
} {
    # Deactivation script.
    eval [list menu::uninsert winUtils items end] $::win::winUtilsMenuItems
} uninstall {
    this-file
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Adds more "Utils > Win Utils" menu items, including commands to sort
    words, and to find matching/duplicate/unique lines in the active window
} help {
    This package adds more "Utils > Win Utils" menu items as described below.
    In general, the actions described below will be performed for the active
    window -- in some cases, the file must exist on a local disk in order for
    the operation to take place.  To turn this package on, open the menu item
    "Config > Global Setup > Features" and click on the checkbox that is next
    to "Window Utilities".
    
    Preferences: Features.
    
    You can click on this hyperlink <<win::testWindowUtils>> to test most of
    these items in this window.  Note that this will still be a 'shell'
    window, and 'undo' will be turned off.
    
    Preferences: Features
    
	        Table Of Contents

    "# Insert Mode Line ..."
    "# Window Lines"
    "#   Number Lines"
    "#   Count Duplicate Lines"
    "#   Find Unique Lines"
    "#   Find Duplicate Lines"
    "#   Find First Duplicate Lines"
    "#   Remove Duplicate Lines"
    "# Tabs 4 to 8"
    "# Tabs 8 to 4"
    "# Sort Words"

    <<floatNamedMarks>>

	----------------------------------------------------------------
    
	        Insert Mode Line ...

    <<win::insertModeLine>>

    This item inserts a line looking like
    
	# -*-Tcl-*-

    at the top of the window.  This will indicate that the file should be
    opened in "Tcl" mode (e.g.) by Alpha, no matter what its file suffix is.
    If the current mode is 'Text' you will be given the option to first
    change the mode of this window to something else.

	----------------------------------------------------------------

	        Window Lines

    This is a submenu that will analyze either the entire window or any
    currently highlighted selection, looking for unique or duplicated lines.
    In each case, if there any results they will be displayed in a new
    window, complete with line number and duplicate count information.
    
    For example, you might have this text in your window:
    
	{
	    # Activation script.
	    menu::insert winUtils items end
	      "insertModeLineÉ"
	      "(-)"
	      {Menu -n windowLines -p {menu::fileProc} {
	        "countDuplicateLines"
	        "findUniqueLines"
	        "findDuplicateLines"
	        "findFirstDuplicateLines"
	        "removeDuplicateLines"
	      }}
	      "<E<Stabs8To4"
	      "<Stabs4To8"
	} {
	    # Deactivation script.
	    menu::uninsert winUtils items end
	      "insertModeLineÉ"
	      "(-)"
	      {Menu -n windowLines -p {menu::fileProc} {
	        "countDuplicateLines"
	        "findUniqueLines"
	        "findDuplicateLines"
	        "findFirstDuplicateLines"
	        "removeDuplicateLines"
	      }}
	      "<E<Stabs8To4"
	      "<Stabs4To8"
	} uninstall {
	    this-file
	} maintainer {
	    "Vince Darley" vince@santafe.edu http://www.santafe.edu/~vince/
	} help {
	    This package adds more Utils --> Win Utils menu items ...
	}
	

    and then you want to locate which lines are duplicates, unique, etc.  The
    hyperlinks for each item will allow you to perform these actions on this
    window, even if this package is not yet turned on!
    
	                Number Lines

    <<win::uniq n>>

    This is a simply utility to add row numbers to the left of each line.
    
	                Count Duplicate Lines

    <<win::uniq c>>

    This item will scan the region, and report the number of times that each
    line appears.  The 'count' column is incremental, indicating how many
    times this line has appeared so far.
    
	                Find Unique Lines

    <<win::uniq u>>
    
    This item will only report occurences of unique lines, i.e. those that
    only appear once in the region.
    
	                Find Duplicate Lines

    <<win::uniq a>>
    
    This item reports only those lines that appear more than once in the
    region, with line numbers for each occurence and the number of times each
    item appears.
    
	                Find First Duplicate Lines

    <<win::uniq d>>
    
    Similar to "Find Duplicate Lines", but only the first occurence of each
    duplicate line is reported, along with the total number of times that it
    appears in the region.
    
	                Remove Duplicate Lines

    <<win::uniq r>>
    
    This item will include all unique lines and the first appearance of a
    duplicate line, but remove any subsequent appearance of duplicates found
    in the region.
    

	----------------------------------------------------------------

	        Tabs 4 to 8

    Turns all tabs in the active window from 4 to 8 columns.

	        Tabs 8 to 4

    Turns all tabs in the active window from 8 to 4 columns.

	        Sort Words

    This item requires a selection.  Each 'word' in the region, separated by
    a space or carriage return, is turned into a list which is sorted in
    alphabetical order, and the region is then replaced and the region is
    selected once again.  By default this sort is an 'ascii' sort, i.e.
    
	ABCD...abcd

    If you want a 'dictionary' style, i.e.
    
	AaBbCcDd...

    then simply use this "Utils > Win Utils > Sort Words" item once again --
    it will recognize the boundaries of the previous sort and decide that you
    want to try something different.  A third "Sort Words" action will revert
    the sort back to 'ascii'.
    
    Note that after performing the sort and replace, the lines containing the
    region are also 'wrapped' by necessity, so this will require two 'undo'
    actions to revert back to the original text.  Also, 'words' that are
    surrounded by curly braces {} or "double quotes" are considered to be a
    single item in the list.
    
    You can click here <<win::testWindowUtils>> to unlock this window, and
    then experiment with these strings of text:
    
	This is a test of sorting with both Dictionary and Ascii styles
	This is another Test of "Win Utils" sorting.
	And This is another Test {but with curly braces.}

    Here's the originals again so that you can compare the results:

	This is a test of sorting with both Dictionary and Ascii styles
	This is another Test of "Win Utils" sorting.
	And This is another Test {but with curly braces.}

    You'll notice that "Win Utils" gets converted to {Win Utils} during the
    sorting.  This is a known bug, with no immediate fix available.
    
    A dynamic "Win Utils > Reverse Sort Words" item is also available, press
    the Option key to display it in the menu.  The same rules regarding
    "dictionary" sorts also applies here.

	----------------------------------------------------------------

    If you have additional window/file utilities that you would like to see
    added to this package, contact its maintainer and describe what you would
    like to see.  Source code is always welcome!  See the "fileUtils.tcl"
    file for the current implementation.
}

proc fileUtils.tcl {} {}
proc winUtils.tcl  {} {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Older 'file' procedures ×××× #
# 
# This package used to define all of these procedure in the "file" namespace,
# and in fact the "winUtils" menu proc calls [menu::fileUtils] which assumes
# that all procs will be in the "file" namespace.  This doesn't make so much
# sense for the "winUtils" menu, since they are supposed to all operate on
# the active window, and not actually on a file.
# 
# So we define all of the former procedures in the "file" namespace, but they
# really just redirect to the "win" procedures below.
# 

namespace eval file {}


proc file::insertModeLine {args} {
    return [eval win::insertModeLine $args]
}

proc file::sortWords {args} {
    return [eval win::sortWords $args]
}

proc file::reverseSortWords {args} {
    return [eval win::reverseSortWords $args]
}

proc file::uniq {args} {
    return [eval win::uniq $args]
}

proc file::tabs8To4 {args} {
    return [eval win::windowTabsTo4 $args]
}

proc file::tabs4To8 {args} {
    return [eval win::windowTabsTo8 $args]
}

proc file::windowTabsTo4 {} {
    win::changeTabSize 4
    return
}

proc file::windowTabsTo8 {} {
    win::changeTabSize 8
    return
}


# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Window Utilities ×××× #
# 

namespace eval win {
    variable lastSARStyle "-dictionary"
}

##
 # --------------------------------------------------------------------------
 #
 # "win::winUtilsMenuItems" --
 #
 # Ensures that this package has been activated.
 # Should only be called by the help file hyperlink.
 #
 # --------------------------------------------------------------------------
 ##

proc win::testWindowUtils {} {
    
    if {![package::active windowUtilities]} {
	package::activate windowUtilities
	set msg "The 'Window Utilities' package\
	  has been temporarily activated.  "
    }
    append msg "You can now experiment with items in this window."
    alertnote $msg
    catch {float -m "winUtils" -l [expr {$::defWidth + 20}] -t $::defTop}
    setWinInfo read-only 0
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "win::insertModeLine" --
 #
 # Inserts a 'smart' mode line in the active window.  If the mode of the
 # active window is 'Text', the user is offered a list of other modes (via
 # [file::notTextMode]) -- selecting one will change the mode of this window.
 #
 # --------------------------------------------------------------------------
 ##

proc win::insertModeLine {} {
    
    if {![win::checkIfWinToEdit]} {
	status::msg "Window is read-only"
	return
    }
    set m [win::getMode]
    if {($m eq "Text")} {
	# We probably don't want Text mode.
	set p "Choose a new mode instead of \"Text\"?"
	set L [list "Text"]
	if {![catch {listpick -p $p -L $L [mode::listAll]} newMode]} {
	    set m $newMode
	    win::ChangeMode $m
	}
    }
    set pos0 [minPos]
    set posL [pos::nextLineStart [pos::nextLineStart $pos0]]
    set txt1 "-*-${m}-*-"
    set pat1 {\-\*\-[-a-zA-Z0-9+]+\-\*\-}
    # Does a mode line already exist?
    if {[llength [set pp [search -n -s -f 1 -r 1 -l $posL -- $pat1 [minPos]]]]} {
	set pos0 [lindex $pp 0]
	set pos1 [lindex $pp 1]
	set txt2 $txt1
    } else {
	set cCh1 [lindex [comment::Characters "General"] 0]
	set cCh2 ""
	if {![string length $cCh1]} {
	    set cChs [comment::Characters "Paragraph"]
	    set cCh1 [lindex $cChs 0]
	    set cCh2 [lindex $cChs 1]
	}
	if {![string length $cCh1]} {
	    set cCh1 $::prefixString
	    set cCh2 $::suffixString
	}
	set pos1 $pos0
	set txt2 [string trim "${cCh1} ${txt1} ${cCh2}"]\r
    }
    if {([getText $pos0 $pos1] ne $txt2)} {
	replaceText $pos0 $pos1 $txt2
	status::msg "The mode line '[string trim $txt2]' has been inserted\
	  at the top of the window."
    } else {
	status::msg "Current mode line has not been changed."
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "win::sortWords" --
 # "win::reverseSortWords" --
 #
 # Take the current region, and pass it through [lsort].  The default style
 # is 'ascii', but a subsequent call will perform a 'dictionary' sort if the
 # boundaries of the previous sort have not changed.  Following the sort and
 # replacement, we make sure that the line is properly wrapped.  (Probably
 # should figure out some way to do this before calling [replaceText] so that
 # [undo] will be a single action.)
 #
 # --------------------------------------------------------------------------
 ##

proc win::sortWords {{pos0 ""} {pos1 ""} {reverseSort 0}} {
    
    if {![win::checkIfWinToEdit]} {
	status::msg "Window is read-only"
	return
    }
    # Preliminaries
    variable lastSARPositions
    if {![info exists lastSARPositions]} {
	set lastSARPositions [list [minPos] [minPos]]
    }
    variable lastSARStyle
    if {![string length $pos0] || ![string length $pos1]} {
	requireSelection
	set pos0 [getPos]
	set pos1 [selEnd]
    }
    if {$reverseSort} {
	set order -decreasing
    } else {
	set order -increasing
    }
    set chr0 [lookAt $pos0]
    set chr1 [lookAt $pos1]
    if {($chr0 == "\{" && $chr1 == "\}") || ($chr0 == "\[" && $chr1 == "\]")} {
	set pos0 [pos::nextChar $pos0]
	set pos1 [pos::prevChar $pos1]
    }
    set pos2 [pos::lineStart $pos0]
    set txt1 [getText $pos0 $pos1]
    # Determine what style we should use, and sort the text.
    set posTest0 [pos::compare [lindex $lastSARPositions 0] == $pos0]
    set posTest1 [pos::compare [lindex $lastSARPositions 1] == $pos1]
    set newSARPositions [list $pos0 $pos1]
    if {[pos::compare $pos1 == [pos::lineStart $pos1]]} {
	set pos1 [pos::prevLineEnd $pos1]
    }
    if {!$posTest0 || !$posTest1 || ($lastSARStyle == "-dictionary")} {
	# Either our positions have changed, or the last sort was a
	# dictionary, so do an '-ascii' sort.
	set style "-ascii"
    } else {
	set style "-dictionary"
    }
    set txt2 [lsort $style $order $txt1]
    # Did we do anything?
    if {($txt1 eq $txt2)} {
	status::msg "No changes made."
    } else {
	replaceText $pos0 $pos1 $txt2
	set pos3 [pos::lineEnd [pos::math $pos0 + [string length $txt2]]]
	wrapText $pos2 $pos3
	selectText $pos0 [set pos1 [selEnd]]
	status::msg "Selection sorted, '$style' style."
    }
    # Remember the last positions, style.
    set lastSARPositions [list $pos0 $pos1]
    set lastSARStyle $style
    return
}

proc win::reverseSortWords {{pos0 ""} {pos1 ""}} {
    win::sortWords $pos0 $pos1 1
    return
}

# ×××× Window Lines ×××× #

##
 # --------------------------------------------------------------------------
 #
 # "win::uniq" --
 # 
 # This differs from earlier versions of this proc in that rather than
 # changing the text in the active window, we always report the results in a
 # new one.  The user can then do whatever is desired with the results.
 # 
 # The meaning of the flags is unchanged :
 # 
 #   "a" all-duplicates : print all duplicate lines (i-e remove unique lines)
 #   "c" count          : prefix lines by the number of occurrences
 #   "d" duplicates     : only print (once) duplicate lines
 #   "n" number         : number all lines
 #   "r" remove         : remove duplicates, leaving one exemplary
 #   "u" unique         : only print unique lines
 # 
 # (This proc is in place in case older code still calls it, and it's a handy
 # thing to include in the help file.)
 # 
 # "win::windowLinesMenuProc" --
 # 
 # Uniquify either the current region or the active window, reporting the
 # results using the methods described below.  The item names in this menu
 # have all been renamed from earlier versions of this package, hopefully for
 # the better to make it clearer what each one does!
 # 
 # --------------------------------------------------------------------------
 ##

proc win::uniq {{flag r}} {
    win::windowLinesMenuProc "" $flag
    return
}

proc win::windowLinesMenuProc {menuName itemName} {
    
    watchCursor
    switch -- $itemName {
	"windowLinesHelp"               {return [win::${itemName}]}
	"findDuplicateLines"            {set flag a}
	"countDuplicateLines"           {set flag c}
	"findFirstDuplicateLines"       {set flag d}
	"numberLines"                   {set flag n}
	"removeDuplicateLines"          {set flag r}
	"findUniqueLines"               {set flag u}
	default                         {set flag $itemName}
    }
    # Preliminaries -- set some variables ...
    set count  0
    set lines  [list]
    set header ""
    set msg    ""
    set d      [string repeat _ 80]
    # Get and manipulate our text to analyze.
    if {![isSelection]} {
	set pos0 [minPos]
	set pos1 [maxPos]
	set row1 [set row 1]
    } else {
	set pos0 [pos::lineStart]
	# We want complete lines :
	if {[pos::compare [selEnd] != [pos::lineStart [selEnd]]]} {
	    set pos1 [pos::nextLineStart]
	} else {
	    set pos1 [selEnd]
	}
	set row1 [set row [lindex [pos::toRowCol $pos0] 0]]
    }
    set txt  [getText $pos0 $pos1]
    set txtL [split $txt "\n\r"]
    if {![string length [lindex $txtL end]]} {
	set txtL [lreplace $txtL end end]
    }
    set txtLen [llength $txtL]
    # Now analyze it according to the specified flag.
    switch -- $flag {
	"a" {
	    # all : print all duplicate lines (i-e remove unique lines)
	    set windowName "Find All Duplicates"
	    set header "  line | count | original text\r${d}\r"
	    # Do a first pass to determine how many of each line we have.
	    set oldLines() 0
	    foreach line $txtL {
	        if {![info exists oldLines($line)]} {
	            set oldLines($line) 1
	        } else {
	            incr oldLines($line)
	        }
	    }
	    # Now do a second pass, only keeping duplicates.
	    foreach line $txtL {
	        if {($oldLines($line) > 1)} {
	            set    result "[format %5d $row] |"
	            append result "[format %5d $oldLines($line)] | ${line}"
	            lappend lines $result
	        } else {
	            incr count
	        }
	        incr row
	    }
	    set msg "$count unique lines removed"
	}
	"c" {
	    # count : prefix lines by the number of occurrences
	    set windowName "Count All Duplicates"
	    set oldLines() 0
	    set header "  line | count | original text\r${d}\r"
	    foreach line $txtL {
	        if {![info exists oldLines($line)]} {
	            set oldLines($line) 1
	        } elseif {([incr oldLines($line)] > 1)} {
	            incr count
	        }
	        set    result "[format %5d $row] |"
	        append result "[format %5d $oldLines($line)] | ${line}"
	        lappend lines $result
	        incr row
	    }
	    set msg "$count duplicate lines"
	}
	"d" {
	    # duplicates : only print (once) duplicate lines
	    set windowName "First Occurence Of Duplicate Lines"
	    set header "  line | count | original text\r${d}\r"
	    # Do a first pass to determine how many of each line we have.
	    set oldLines() 0
	    foreach line $txtL {
	        if {![info exists oldLines($line)]} {
	            set oldLines($line) 1
	        } else {
	            incr oldLines($line)
	        }
	    }
	    # Now do a second pass, only keeping duplicates.
	    set count1 [set count2 0]
	    foreach line $txtL {
	        if {($oldLines($line) <= 1)} {
	            incr count1
	        } elseif {[info exists ignoreLines($line)]} {
	            incr count2
	        } else {
	            set    result "[format %5d $row] |"
	            append result "[format %5d $oldLines($line)] | ${line}"
	            lappend lines $result
	            set ignoreLines($line) 1
	        }
	        incr row
	    }
	    set count [expr {$count1 + $count2}]
	    set msg "$count1 unique, $count2 duplicated lines removed"
	}
	"n" {
	    # number lines:
	    while {1} {
	        status::msg "The first row in the selection is \"${row1}\""
	        set row  [prompt "Start numbering rows with" $row]
	        if {[regexp {^[-0-9]+$} $row]} {
	            status::msg ""
	            break
	        }
	        alertnote "The \"row\" must be a number!"
	    }
	    set windowName "Numbered Lines"
	    set intro ""
	    foreach line $txtL {
	        lappend lines "[format %5d $row] | $line"
	        set oldLines($line) 1
	        incr count
	        incr row
	    }
	    set msg "$count lines numbered"
	}
	"r" {
	    # remove : remove duplicates, leaving one exemplary
	    set windowName "Remove All Duplicates"
	    set header "  line | original text\r${d}\r"
	    foreach line $txtL {
	        if {![info exists oldLines($line)]} {
	            lappend lines "[format %5d $row] | $line"
	            set oldLines($line) 1
	        } else {
	            incr count
	        }
	        incr row
	    }
	    set msg "$count duplicate lines removed"
	}
	"u" {
	    # unique : only print unique lines
	    set windowName "Find Unique Lines"
	    set header "  line | original text\r${d}\r"
	    foreach line $txtL {
	        if {![info exists oldLines($line)]} {
	            set oldLines($line) 1
	        } else {
	            incr oldLines($line)
	        }
	    }
	    foreach line $txtL {
	        if {($oldLines($line) == 1)} {
	            lappend lines "[format %5d $row] | $line"
	        } else {
	            incr count
	        }
	        incr row
	    }
	    set msg "$count duplicate lines removed"
	}
	default {error "Unknown flag: $flag"}
    }
    # Adjust the message, and create a new window if we have results.
    if {($count == 1)} {
	regsub -- {lines} $msg line msg
    }
    if {($txtLen == 1)} {
	set msg "$txtLen line analyzed, ${msg}."
    } else {
	set msg "$txtLen lines analyzed, ${msg}."
    }
    if {![llength $lines] || !$count} {
	regsub -all -- " removed" $msg "" msg
	set msg "No results -- $msg"
    } else {
	if {![info exists intro]} {
	    set    intro "\r${windowName} Results\r\r\"[win::Current]\"\r"
	    append intro "Lines $row1 through [expr {$row1 + $txtLen - 1}], "
	    append intro "as of [mtime [now] short]\r\r${msg}\r\r"
	    append intro "Click here <<win::removeDuplicateFormatting>> "
	    append intro "to remove the leading line counts.\r"
	    append intro "${d}\r\r${header}"
	}
	foreach line $lines {append results ${line}\r}
	set results ${intro}[join $lines "\r"]\r
	new -n "* $windowName *" -mode $::mode -text $results
	win::searchAndHyperise {<<(win::removeDuplicateFormatting)>>} \
	  \\1 1 3 +2 -2
	goto [minPos] ; setWinInfo dirty 0
    }
    status::msg $msg
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "win::removeDuplicateFormatting" --
 #
 # Removes all of the leading formatting from 'results' windows created by
 # [win::uniq], so that the actual text could be cut/pasted/whatever.
 #
 # --------------------------------------------------------------------------
 ##

proc win::removeDuplicateFormatting {} {
    
    set isDirty [win::getInfo [win::Current] dirty]
    set d [string repeat _ 80]
    if {[llength [set pp [search -n -s -f 1 -r 0 -- $d [minPos]]]]} {
	set pos0 [lindex $pp 1]
	set pos1 [maxPos]
	set txt1 [getText $pos0 $pos1]
	regsub -all -- {([\r\n]+)( *[0-9]+ \|)+ } $txt1 \\1 txt2
	if {($txt1 ne $txt2)} {
	    replaceText $pos0 $pos1 $txt2
	    if {!$isDirty} {
	        setWinInfo dirty 0
	    }
	}
	goto [minPos]
    } else {
	status::msg "Could not find the formatting divider."
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "win::windowLinesHelp" --
 #
 # Open the help file, jump to the proper mark.
 #
 # --------------------------------------------------------------------------
 ##

proc win::windowLinesHelp {} {
    package::helpWindow "fileUtils"
    help::goToSectionMark "Window Lines"
    return
}

# ×××× Tabs, Spaces ×××× #

##
 # --------------------------------------------------------------------------
 #
 # "win::windowTabsTo4" --
 # "win::windowTabsTo8" --
 # "win::changeTabSize" --
 # 
 # Just what they say -- changes the tab size for the active window.
 #
 # --------------------------------------------------------------------------
 ##

proc win::windowTabsTo4 {} {
    win::changeTabSize 4
    return
}

proc win::windowTabsTo8 {} {
    win::changeTabSize 8
    return
}

proc win::changeTabSize {newTabSize} {
    
    if {![win::checkIfWinToEdit]} {
	return
    } elseif {([win::getInfo [win::Current] tabsize] == $newTabSize)} {
	status::msg "The current tabsize is already ${newTabSize}."
	return
    }
    allTabsToSpaces [minPos] [maxPos]
    setWinInfo tabsize $newTabSize
    leadingSpacesToTabs [minPos] [maxPos]
    status::msg "The current tabsize for \"[win::Tail]\" is ${newTabSize}."
    return
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 
# 03/26/96 VMD 0.1    Original.
# ??/??/?? VMD -1.2.5 Various fixes and updates
# 10/19/02 cbu 1.3    Major update for Tcl 8.4 (which is now required.)
#                     Improved 'help' argument.
#                     Now a 'global-only' feature instead of an extension,
#                       so that we can have a deactivation script.
#                     Reorganized menu, placing most of the items in the
#                       main "Win Utils" submenu, less mouse travel.
#                     But created a separate "Duplicate Lines" submenu.
#                     Major overhaul of [win::uniq], which is very speedy
#                       now, and reports results in a separate window.
#                     Added more file/folder compression utilities.
#                     Added support for 'DropTar' compression.
#                     Moved all compression functions out of this file and
#                       into "fileCompression.tcl"
#                     Renamed package "windowUtilities"
#                     Put all procedures in the "win" namespace
# 08/01/03 cbu 1.3.1  All procs defined in this source file can be called by
#                       other code -- this package provides the UI.
#                     Optional starting row number can be defined by user
#                       in "Window Lines > Number Lines".
# 08/01/03 cbu 1.3.2  Incorporated the body of [text::notTextMode] into
#                       [win::insertModeLine], the only proc which used it.
#

# ===========================================================================
# 
# .