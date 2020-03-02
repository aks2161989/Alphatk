## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwShell.tcl"
 #                                   created: 10/13/2002 {02:47:10 PM} 
 #                               last update: 03/21/2006 {01:54:24 PM} 
 # Description:
 # 
 # Procedures that support a "Go To Url" shell window.  See the text in the
 # "WWWsh::help" procedure for more information.
 # 
 # Since this is not available in Alpha7 (mainly due to the limitations of
 # selecting/inserting text in windows other than the front one) we could
 # probably take better advantage of using Tcl 8.0 here.
 # 
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the wwwMode.tcl file has been loaded.
wwwMode.tcl

proc wwwShell.tcl {} {}

namespace eval WWW  {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Go To Url Shell ×××× #
# 

proc WWW::goToUrlWindow {} {
    WWWsh::shellWindow
    return
}

namespace eval WWWsh {}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWsh::initializeVars"  --
 # 
 # Preliminaries -- set up some vars we need below.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::initializeVars {} {
    
    global wwwShellVars wwwMenuVars Shel::startPrompt Shel::endPrompt \
      tcl_platform tileWidth defLeft defTop mode::features
    
    if {[info exists wwwShellVars(shellInitialized)]} {
	return
    }
    
    # Make sure that the wwwMenuVars(uniqueHistory) var has been created.
    WWW::initializeHistory
    
    set wwwShellVars(ShellTitle)            "*Go To Url ...*"
    set wwwShellVars(CycleCompletionsPos)   [list [minPos] [minPos]]
    set wwwShellVars(HistoryForCompletions) [lunique $wwwMenuVars(uniqueHistory)]
    set wwwShellVars(HistoryIndex)          [list 0 0]
    set wwwShellVars(StartPrompt)           [set Shel::startPrompt]
    set wwwShellVars(EndPrompt)             [set Shel::endPrompt]
    
    # Set the welcome message.
    set wwwShellVars(Welcome) [string trim {
Welcome To the WWW 'Go To Url' shell window.
¥ Type in a url, press the Return key to open a new WWW window...
¥ Press the Tab key to complete a url from the history cache...
¥ Press the Control-Up/Down Arrow keys to navigate history...
¥ Type 'help' for more information.
}]
    # Set the prompt.
    set wwwShellVars(Prompt) \
      "${Shel::startPrompt}WWW Go To ...${Shel::endPrompt} "
    
    # Set up some bindings.

    # Bind WWW Shell completions to 'tab' key.
    Bind 0x30       {WWWsh::completeUrlBody}    wwwShell
    Bind 0x30 <z>   {WWWsh::cycleCompletions 0} wwwShell
    # Bind "/" to quick completion.
    Bind '/'        {WWWsh::completeUrlSlash}   wwwShell
    # Bind <command> up/down arrow keys to cycle url history.
    Bind up   <z>   {WWWsh::cycleHistory 0}     wwwShell
    Bind down <z>   {WWWsh::cycleHistory 1}     wwwShell
    
    # Create a "minor mode" for the WWW Shell Window.
    set mode::features(wwwShell) [list "wwwMenu"]
    alpha::minormode "wwwshell" \
      bindtags          "Shel" \
      +bindtags         "wwwShell" \
      colortags         "" \
      +featuremodes     "wwwShell" \
      hookmodes         "wwwShell" \
      varmodes          "wwwShell"
    
    # Remember the shell window size when we quit.
    prefs::modified WWWmodeVars(wwwShellWindowSize)

    set wwwShellVars(shellInitialized) 1
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::shellWindow" "WWWsh::Prompt"  --
 # 
 # Open a shell window, in "Shel" mode, with a "Go To ..."  prompt.  Pressing
 # <return> will attempt to open a new WWW window with the requested url.  If
 # the command line looks like it might be a WWW AlphaTcl or Tcl shell
 # command then we evaluate that preferentially.  The <tab> key is bound to
 # attempt to complete the url if we really are in a WWW Shell window, based
 # upon the history of urls seen as contained in the wwwMenuVars(history)
 # var.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::shellWindow {} {

    global wwwMenuVars wwwShellVars WWWmodeVars

    WWWsh::initializeVars

    set title $wwwShellVars(ShellTitle)
    if {[win::Exists $title]} {
	# We already have a shell window open.
	bringToFront $title
	return
    }
    Shel::start "WWWsh" $title $wwwShellVars(Welcome) "Text" "wwwshell"
    # Adjust the size of the window.
    foreach {l t w h} $WWWmodeVars(wwwShellWindowSize) {}
    moveWin $title $l $t
    sizeWin $title $w $h
    # Insert the last history item.
    set pos0 [getPos -w $title]
    insertText -w $title [set initialUrl [lindex $wwwMenuVars(uniqueHistory) 0]]
    selectText -w $title $pos0 [pos::math $pos0 + [string length $initialUrl]]
    return
}

proc WWWsh::Prompt {} {
    global wwwShellVars
    return $wwwShellVars(Prompt)
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::openShellWindow"  --
 # 
 # Called after a web page has been rendered and if the user has set the
 # preference to open the shell window, see if we have one yet and if not
 # open it but bring the current window back to the front.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::openShellWindow {} {
    
    global wwwShellVars
    
    # Do we already have a shell window open?
    if {[win::Exists $wwwShellVars(ShellTitle)]} {
	return
    }
    set currentWindow [win::Current]
    WWWsh::shellWindow
    if {[win::Exists $currentWindow]} {
	bringToFront $currentWindow
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::evaluate"  --
 # 
 # Called by "Shel::CarriageReturn", if it looks like a WWW AlphaTcl or a Tcl
 # command then we evaluate the command line, otherwise attempt to open a new
 # WWW window with the requested url.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::evaluate {cmdline} {
    
    global wwwMenuVars WWWmodeVars
    
    # Remember the window geometry.
    set WWWmodeVars(wwwShellWindowSize) [getGeometry]
    # Make sure that we have a cmdline to deal with.
    if {![string length $cmdline]} {
	return
    }
    # Check to see if the 'url' is really a defined AlphaTcl/Tcl procedure. 
    # We give preference to procedure names in the WWWsh/WWW namespaces.
    set cmd [lindex [split $cmdline] 0]
    set prefix1 "::WWWsh::"
    set prefix2 "::WWW::"
    set prefix3 "::"
    foreach prefix [list $prefix1 $prefix2 $prefix3] {
	if {[info commands "${prefix}${cmd}"] != ""} {
	    regsub {^::} $prefix {} prefix
 	    catch {Alpha::evaluate $prefix$cmdline} result
	    return $result
	}
    }
    # If the command is unknown to WWW Shell, try to render it as a url
    WWW::setWindowVars
    WWW::openingFromLink 1
    if {[win::Exists $wwwMenuVars(lastWindow)]} {
        bringToFront $wwwMenuVars(lastWindow)
    }
    WWW::renderRemote $cmdline
    return ""
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::updateCommandLine"  --
 # 
 # Called when the history is updated, if the "Go To Url" window is open
 # we place the current url location behind the prompt.  Pretty slick.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::updateCommandLine {url} {

    global wwwShellVars
    
    if {![info exists wwwShellVars]} {
        WWWsh::initializeVars
    }
    
    set currentWindow [win::Current]
    set title $wwwShellVars(ShellTitle)
    if {([lsearch -exact [winNames] $title] == "-1")} {
	return
    }
    if {[catch {WWWsh::getCurrentLine} lineVars]} {
	return
    }
    foreach {pos0 pos1 pos2 pos3 pos4 txt1 txt2 txt3} $lineVars {}
    set prmpt $wwwShellVars(Prompt)
    set url   [string trim $url]
    replaceText -w $title $pos0 $pos4 "${prmpt}${url}"
    set pos5 [pos::math -w $title $pos1 + 1]
    set pos6 [pos::lineEnd -w $title $pos1]
    selectText -w $title $pos5 $pos6
    # Set the history index to "0" so that <command> arrows will start
    # at the beginning of the list again.
    set wwwShellVars(HistoryIndex) [lreplace \
      $wwwShellVars(HistoryIndex) 1 1 "0"]
    # Seems like we really need to force the issue here with Alphatk.
    if {[win::Exists $currentWindow]} {
	bringToFront $currentWindow
    }
    return
}

# ==========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Url Completions ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::getCurrentLine"  --
 # 
 # Get some initial positions for line start/end etc.  Here's the positions,
 # assuming that "princeton.edu" is highlighted:
 # 
 # ÇWWW Go To ...È http://www.princeton.edu/~cupright/
 # 0              1           2            3          4
 # 
 # 'txt1' would be this entire line, 'txt2 is the cmdline (everything from
 # the left side of prompt to the end, but trimmed of spaces), and 'txt3'
 # would be any selection present (the null string if none).
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::getCurrentLine {} {
    
    global wwwShellVars
    
    set title $wwwShellVars(ShellTitle)
    set pChar $wwwShellVars(EndPrompt)
    
    set pos  [getPos -w $title]
    
    set pos0 [pos::lineStart -w $title $pos]
    set pos4 [pos::lineEnd -w $title $pos]
    set txt1 [getText -w $title $pos0 $pos4]
    if {[set ind [string first $pChar $txt1]] < 0} {
	error "Could not find ending prompt character."
    }
    set pos1 [pos::math -w $title $pos0 + $ind + 1]
    set txt2 [string trim [getText -w $title $pos1 $pos4]]
    set pos2 [getPos -w $title]
    set pos3 [selEnd -w $title]
    set txt3 [getText -w $title $pos3 $pos4]
    return [list $pos0 $pos1 $pos2 $pos3 $pos4 $txt1 $txt2 $txt3]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::completeUrlBody"  --
 # 
 # No matter where we are in the command line, grab the whole text and
 # attempt to complete a previously recognized url from the history.  It gets
 # a little tricky because we only want to give a completion for the next
 # directory down if possible to avoid presenting a listpick with 20 or more
 # items to choose from.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::completeUrlBody {} {
    
    global wwwShellVars wwwMenuVars
        
    if {[win::Current] ne $wwwShellVars(ShellTitle)} {
	bind::Completion
	return
    } elseif {[isSelection]} {
	WWWsh::cycleCompletions
	return
    }
    if {[catch {WWWsh::getCurrentLine} lineVars]} {
	return
    }
    foreach {pos0 pos1 pos2 pos3 pos4 txt1 txt2 txt3} $lineVars {}
    
    # Determine what text we have to complete.
    set txt4 [string trimright $txt2 "/"]
    # Create a set of completions to use.
    foreach url $wwwMenuVars(uniqueHistory) {
	lappend completions $url
	regsub {^[^:]+://} $url "" truncatedUrl
	if {[lsearch $wwwMenuVars(uniqueHistory) $truncatedUrl] < 0} {
	    lappend completions $truncatedUrl
	}
    }
    set wwwShellVars(HistoryForCompletions) $completions
    set completions [lremove [lunique $completions] [list $txt2]]
    foreach num [list 1 2 3] {
	set completions$num [list]
    }
    foreach url $completions {
	if {[regexp "^${txt4}\[^/]*/" $url urlStart]} {
	    lappend completions1 $url
	    lappend completions2 $urlStart
	    if {[regexp "^${txt2}\[^/]*/" $url urlStart]} {
		lappend completions3 $urlStart
	    }
	}
    }
    # If we have a limited set of completions, including only those one
    # more directory deep, we use them, otherwise present all available.
    foreach num [list 3 2 1] {
	if {[llength [set completions$num]]} {
	    set completions [set completions$num]
	    break
	}
    }
    set wwwShellVars(CycleUrls) $completions1
    # Offer the list if multiple, otherwise use the only one found.
    set completions [lsort -unique -dictionary $completions]
    set completions [completion::fromChoices -list $completions $txt2]
    if {![llength $completions]} {
	status::msg "No url completions found."
	return
    } elseif {([llength $completions] == "1")} {
	set completion [lindex $completions 0]
    } else {
	set completion [listpick -p "Choose a url completion:" $completions]
    }
    # Insert the new completion.
    replaceText $pos1 $pos4 " $completion"
    if {[regexp {/$} $completion]} {
	WWWsh::completeUrlSlash 1
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::completeUrlSlash"  --
 # 
 # Called either when the user types a backslash or from the end of a url
 # completion, see if there's more completions that we can offer and if so go
 # ahead and insert it but highlight it for easy deletion (i.e. by simply
 # typing more text.)  Emulates behavior in Internet Explorer and Netscape,
 # which I must admit I first found extremely annoying but now I kind of
 # appreciate it.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::completeUrlSlash {{slashAdded 0}} {
    
    global wwwShellVars WWWmodeVars

    set title $wwwShellVars(ShellTitle)
    if {!$slashAdded} {
	typeText "/"
    }
    if {[win::Current] ne $title || !$WWWmodeVars(electricUrlCompletions)} {
	return
    } elseif {[catch {WWWsh::getCurrentLine} lineVars]} {
	return
    }
    foreach {pos0 pos1 pos2 pos3 pos4 txt1 txt2 txt3} $lineVars {}
 
    if {[pos::compare $pos2 < $pos1]} {
        return
    } elseif {[regexp {:/*$} [set txt4 [getText $pos1 $pos2]]]} {
	return
    }
    set txt4 [string trimleft $txt4]
    foreach item $wwwShellVars(HistoryForCompletions) {
	if {[regsub "^$txt4" $item "" moreCompletion]} {
	    insertText -w $title $moreCompletion
	    selectText -w $title $pos3 [getPos]
	    return
	}
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWWsh::cycleCompletions"  --
 # 
 # Given some highlighted text in a url, cycle through all possible
 # completions in the url history cache, continueing to highlight the new
 # offering.  This is only called by the <tab> key in Shel mode, and only
 # when there is a currently highlighted selection.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::cycleCompletions {{direction "1"}} {
    
    global wwwShellVars
    
    if {[win::Current] ne $wwwShellVars(ShellTitle)} {
	return
    } elseif {![isSelection] || [pos::compare [selEnd] != [pos::lineEnd]]} {
	return
    }
    if {[catch {WWWsh::getCurrentLine} lineVars]} {
	return
    }
    foreach {pos0 pos1 pos2 pos3 pos4 txt1 txt2 txt3} $lineVars {}

    set txt4 [string trim [getText $pos1 $pos2]]
    
    set pos5 [lindex $wwwShellVars(CycleCompletionsPos) 0]
    set pos6 [lindex $wwwShellVars(CycleCompletionsPos) 1]

    set selection   [getSelect]
    set completions [list]
    
    if {[pos::compare $pos0 != $pos5] || [pos::compare $pos3 != $pos6]} {
	# We need to rebuild the list of possible completions.
	foreach item $wwwShellVars(HistoryForCompletions) {
	    if {[regsub "^${txt4}" $item "" end]} {
		lappend completions $end
	    }
	}
	if {![llength $completions]} {
	    status::msg "No further completions available."
	    return
	}
	set completions [lsort -unique -dictionary $completions]
	set wwwShellVars(CycleCompletions) $completions
    } else {
	# Use the last set of completions again.
	set completions $wwwShellVars(CycleCompletions)
    }
    set completions [lremove -all $completions [list ""]]
    # We can also cycle backwords.
    if {!$direction} {
	set completions [lreverse $completions]
    }
    set count 1 ; set nextCompletion ""
    foreach item $completions {
	if {($item eq $selection)} {
	    if {($count == [llength $completions])} {
		set count 0
	    }
	    set nextCompletion [lindex $completions $count]
	    break
	}
	incr count
    }
    if {$count < [llength $completions]} {
	deleteText $pos2 $pos4 ; goto $pos2
	insertText $nextCompletion
	set pos4 [pos::lineEnd]
	selectText $pos2 $pos4
	set len1 [llength $completions]
	if {$direction} {
	    set count [expr {$count + 1}]
	    status::msg "Completion $count of $len1"
	} else {
	    set count [expr {$len1 - $count}]
	    status::msg "Completion $count of $len1"
	}
	set wwwShellVars(CycleCompletionsPos) [list $pos2 $pos4]
    } else {
	status::msg "No further completions available."
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # ""WWWsh::cycleHistory"  --
 # 
 # Cycle through the history of recent urls accessed.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::cycleHistory {direction} {
    
    global wwwShellVars wwwMenuVars
    
    if {[win::Current] ne $wwwShellVars(ShellTitle)} {
	if {$direction} {
	    endOfBuffer
	} else {
	    beginningOfBuffer
	}
	return
    }
    if {[catch {WWWsh::getCurrentLine} lineVars]} {
	goto [maxPos]
	Shel::Bol
	selectText [getPos] [pos::lineEnd]
	status::msg "Cursor returned to command line."
	return
    }
    foreach {pos0 pos1 pos2 pos3 pos4 txt1 txt2 txt3} $lineVars {}

    set historyList $wwwMenuVars(uniqueHistory)

    # Determine the position in the history cache that we'll replace with.
    set len1 [lindex $wwwShellVars(HistoryIndex) 0]
    set len2 [llength $historyList]
    if {$len1 != $len2} {
	# The history has changed, so we'll start over from the beginning.
	set hIndex 0
    } elseif {[pos::compare [lindex $wwwShellVars(HistoryIndex) 2] != $pos0]} {
	# We're at a new prompt, so set the position to the start.
	set hIndex 0
    } elseif {!$direction} {
	# Same position as the last time, so use prev history item.
	set hIndex [expr {[lindex $wwwShellVars(HistoryIndex) 1] + 1}]
    } else {
	# Same position as the last time, so use next history item.
	set hIndex [expr {[lindex $wwwShellVars(HistoryIndex) 1] - 1}]
    }
    set nextItem [lindex $historyList $hIndex]
    if {[string length $nextItem]} {
	replaceText $pos1 $pos4 " $nextItem"
	goto [pos::math $pos1 + 1]
	set number [expr {$hIndex + 1}]
	status::msg "History item $number of $len2"
    } elseif {!$direction} {
	status::msg "At the end of the url history cache."
	selectText [pos::math $pos1 + 1] [pos::lineEnd]
	set hIndex -1
    } else {
	status::msg "At the beginning of the url history cache."
	selectText [pos::math $pos1 + 1] [pos::lineEnd]
	set hIndex $len2
    }
    set wwwShellVars(HistoryIndex) [list $len2 $hIndex $pos0]
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Shell Support ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # ""WWWsh::help"  --
 # 
 # Called when the user types 'help' in a shell window.  Open a new window
 # with some more explanatory text.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWWsh::help {} {

    set title "WWW Go To Url Help"
    if {[win::Exists $title]} {
	bringToFront $title
	return
    }

    set txt {
WWW 'Go To Url' Shell Window Help

The WWW Menu provides an optional "Go To Url" shell window that allows you to
enter a url and then press 'return' to fetch and render a remote web page.
This functions much like the "Location" box in Netscape Navigator or the
"Address" box in Internet Explorer.  If you haven't already opened this
window, click here <<WWWsh::openShellWindow>> to start one now.

Note that the cursor can be anywhere on the command line when you press
<return>, you don't have to be at the end of the line.  Also, if there is
any selection highlighted, it is NOT deleted when you press <return>, and
the complete url is sent to be fetched, parsed, and rendered.  You can also

¥ Use the 'tab' key to complete partial urls based upon recent browsing
  history, and to cycle through alternative completions.

¥ Use <command> up/down arrow keys to navigate recent url history.

If this window is open as you navigate web pages, the current location is
automatically updated in the prompt, waiting for you to edit it, cycle
through your recent browsing history, etc ...

The following sections describe some of the options available for using your
recent browsing history as electric completions.  The sections include

"# Electric Completions Using <tab>"
"# Electric Completions Using '/'"
"# Cycling Through Recent History"
"# Default Window Size"
"# Auto Open The Window"
"# Tips:"

For more information about the WWW Menu, see the "WWW Help" window.  For more
information about WWW mode preferences and default key bindings, click on
this hyperlink <<mode::describe "WWW">>.

	  	Electric Completions Using <tab>

While you are typing a url, you can press the <tab> key to attempt to
complete it based upon your recent browsing history.  All urls in the
"history" cache are recognized.  (See the <<WWWsh::history>> window to check
out your current list of saved urls.)  If you flush the history cache, these
urls will remain as possible electric completions until you end your Alpha
editing session.  Upon startup, only those items still in the history cache
are used to create possible completions.

When you press <tab>, if there are several different completions available
they will be offered in a list pick dialog.  These completions will only
include those to the next "/" in the url.  If there are any additional
completions possible following this "/", the first one (alphabetically) in
the next list will be inserted and highlighted.  At this point you can do one
of several actions:

--  press <return> and the complete url will be fetched and rendered.
--  continue to type and the selection will be deleted.
--  press <tab> and the highlighted selection will cycle through the next
    possible completion (alphabetically), and will continue doing so with
    subsequent <tab>s.
--  press <control>-<tab> and the highlighted selection cycle through
    completions in the opposite order (reverse alphabetically.)

	  	Electric Completions Using '/'

While you are typing your url, when you enter "/" you also are presented
with an initial hint for the url's completion.  You have the same options
outlined above.

	  	Cycling Through Recent History

The <command> up/down arrow keys are bound to cycling through the recent
history of urls that you have browsed.  At the "Go To Url" prompt, press
<command> up to enter the most recent url which was rendered.  This would
include both urls that you typed in yourself, as well as any encountered via
a web page hyperlink.  Continue to press the <command> up combination to go
to the next item in the list, or go back to the more recent by using the
<command> down key.  While you are cycling through the list the status bar
will display a message telling you where you are in the list.  When you have
reached the end/beginning of the list, you will be flipped to the other side
in a continuous loop.  At any time you can press <return> to open a new page
with the contents of the current url shown in the command line.

	  	Default Window Size

You might have already noticed that if you change the size of a rendered page
that is in WWW mode and then click on a hyperlink that the parameters of the
current window are saved and used for each subsequent page.  These parameters
are saved between editing sessions.

The same thing is true for the "Go To Url" shell window.  If you resize it
and then enter a url, before the page is rendered the new parameters of the
shell window are remembered and saved.  This means that you can adjust the
size of the browsing window and have the "Go To Url" window above it, below
it, hanging out over one side, etc.  for both ease of switching windows as
well as personal monitor aesthetics.

	  	Auto Open The Window

The "Go To Url" window can be opened using the WWW Menu item by that name
(note that this is a dynamic menu item in Alpha//X which is hiding behind
the "New WWW Window..."  menu item), or by pressing 'u' while the current
window is in "WWW" mode.  You can also open this window automatically the
first time that you render a web page if the "Open Go To Url Window"
preference is set in the "WWW Menu --> WWW Menu Options" submenu.

	  	Tips:

¥ It is not necessary to type the leading "http://" in the url to properly
  fetch and render it.  Many servers also redirect urls that are missing the
  initial "www."  but we have no control over that here.

¥ If you find the automatic completion of urls annoying (these are based on
  your recent browsing history), then while the current window is in WWW mode
  you can use the "Config --> Mode Prefs --> Preferences" dialog to turn off
  the flag for "Electric Url Completions".  Using <tab> to complete a url
  that you are typing will still work, but no additional hints will be added,
  and the cycling of possible alternative completions will be disabled.

¥ This window will also recognize Tcl/AlphaTcl commands and evaluate them as
  in a normal shell window.  <control> up/down will also display the history
  of recent shell commands.

Happy browsing !!!

}
    new -n $title -info $txt
    help::markColourAndHyper
    return
}

proc WWWsh::history {} {
    WWW::historyWindow
    return
}

# ===========================================================================
# 
# .