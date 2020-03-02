## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "spellcheck.tcl"
 #                                          created: 08/20/2002 {09:09:25 AM}
 #                                      last update: 03/21/2006 {12:47:47 PM}
 # Description:
 # 
 # Integrates Alpha with Excalibur, Aspell, Ispell, CocoAspell.
 # 
 # This is an AlphaTcl core package, and you should not remove this file.
 # Alpha may not function very well without it.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 2002-2006  Vince Darley, Joachim Kock, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ×××× Spellcheck helpers ×××× #

alpha::feature spellcheck 0.3 "global-only" {
    # Initialization script.
    ::xserv::declareBundle "Spellcheck" "Spellcheck services" \
      SpellcheckFile SpellcheckWindow SpellcheckSelection

    ::xserv::declare SpellcheckFile "Spellcheck a file" \
      filename
    ::xserv::declare SpellcheckWindow "Spellcheck a window" \
      window
    ::xserv::declare SpellcheckSelection "Spellcheck the selection" \
      window from to

    # =======================================================================
    # Excalibur is the only Mac spell-checker we know of which will handle
    # LaTeX as well as ordinary text.

    ::xserv::register "SpellcheckFile" Excalibur \
      -sig "XCLB" \
      -driver {
	sendOpenEvent noReply 'XCLB' $params(filename)
    }

    ::xserv::register "SpellcheckWindow" Excalibur \
      -sig "XCLB" \
      -driver {
	set w $params(window)
	# If the file is dirty, we offer to save it first.  
	if {[win::getInfo $w dirty]} {
	    if {[dialog::yesno -c "Save '[win::Tail $w]'?"]} {
		save $w
	    }
	}
	# We make sure that the window actually exists on disk, i.e. that
	# the file is not a new window that has not been saved yet.
	if {![win::IsFile $w filename]} {
	    error "Cancelled -- the window must exist as a local file."
	}
	::xserv::invoke SpellcheckFile -filename $filename
	hook::register resumeModifiedHook spellcheckResume $w
    }

    ::xserv::register "SpellcheckSelection" Excalibur \
      -sig "XCLB" \
      -driver {
	set w $params(window)
	set tmpFile [temp::path spellCheck "'[win::Tail $w]' region"]
	file::writeAll $tmpFile [getText -w $w $params(from) $params(to)] 1
	# Note: Excalibur (OSX) won't accept our AE unless the file is of
	# type TEXT.
	catch {setFileInfo $tmpFile type "TEXT"}
	::xserv::invoke SpellcheckFile -filename $tmpFile
	hook::register resumeHook [list spellcheckRegionResume $w $tmpFile]
    }

    ::xserv::register "SpellcheckFile" Aspell \
      -progs "aspell" \
      -driver {
	::xserv::invoke SpellcheckWindow -window [edit $params(filename)]
    }

    ::xserv::register "SpellcheckWindow" Aspell\
      -progs "aspell" \
      -driver {
	spell::checkWindow $params(window) $params(xserv-aspell)
    }

    ::xserv::register "SpellcheckSelection" Aspell \
      -progs "aspell" \
      -driver {
	set first [lindex [pos::toRowChar $params(from)] 0]
	incr first -1
	set last [lindex [pos::toRowChar $params(to)] 0]
	spell::checkWindow $params(window) $params(xserv-aspell) $first $last
    }
} {
    menu::insert Utils items "wordCount" \
      "/L<E<S<O<IspellcheckWindowÉ" "/L<S<O<I<BspellcheckSelectionÉ"
    hook::register requireOpenWindowsHook \
      [list Utils "spellcheckWindowÉ"] 1
    hook::register requireOpenWindowsHook \
      [list Utils "spellcheckSelectionÉ"] 1
    if {$tcl_platform(platform) != "macintosh"} {
	menu::insert Utils items "wordCount" \
	  "spellcheckÉ"
	hook::register requireOpenWindowsHook \
	  [list Utils "spellcheckÉ"] 1
    }
} {
    menu::uninsert Utils items "wordCount" \
      "/L<E<S<O<IspellcheckWindowÉ" "/L<S<O<I<BspellcheckSelectionÉ"
    hook::deregister requireOpenWindowsHook \
      [list Utils "spellcheckWindowÉ"] 1
    hook::deregister requireOpenWindowsHook \
      [list Utils "spellcheckSelectionÉ"] 1
    if {$tcl_platform(platform) != "macintosh"} {
	menu::uninsert Utils items "wordCount" \
	  "spellcheckÉ"
	hook::deregister requireOpenWindowsHook \
	  [list Utils "spellcheckÉ"] 1
    }
} description {
    Integrates ÇALPHAÈ with Excalibur, Aspell, Ispell, CocoAspell
} help {
    This core package supports the "Utils > Spellcheck Window/Selection" menu
    items.
    
	  	Alpha 8/X/tk

    On MacOS, ÇALPHAÈ has the capability to interact with the spell-checker
    'Excalibur', written by Robert Gottshall and Rick Zaccone.  Excalibur can
    be obtained from

    <http://www.eg.bucknell.edu/~excalibr/excalibur.html>
    
    Selecting the "Utils > Spellcheck Window" menu item will start up
    Excalibur and open the current window in Excalibur.
    
    Selecting "Utils > Spellcheck Selection" will copy the current selection
    and place it in a temporary file, which is then sent to Excalibur to
    spellcheck.
    
    Following the completion of the spellcheck, you must save the file in
    Excalibur ("File > Save") to record the changes.  When switching back
    from Excalibur to ÇALPHAÈ, ÇALPHAÈ automatically updates the current
    window/selection with any corrections made in Excalibur.

	  	Alpha X/tk

    On OSX, Unix and Windows, AlphaX and Alphatk can interact with the
    command-line spell checkers 'aspell' and 'ispell'.  Aspell can be
    obtained from

    <http://aspell.sourceforge.net/>
    
    Selecting the menu items "Utils > Spellcheck Window/Selection" will set
    the spell checker running and communicate with it behind the scenes.
    Suggestion and replacement of corrected words happens through the status
    bar.
    
    See the file "spellcheck.tcl" for the package: xserv declarations.
}

proc spellcheck.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "spellcheckWindow" --
 # 
 # Send the active window to the spellchecker program, prompting the user to
 # locate it if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc spellcheckWindow {} {
    requireOpenWindow
    ::xserv::invoke SpellcheckWindow -window [win::Current]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "spellcheckResume" --
 # 
 # This hook is registered by [spellcheckWindow].  After the user has
 # corrected any spelling and saved the file (in the spellcheck program), we
 # revert the window to indicate the current content.
 # 
 # --------------------------------------------------------------------------
 ##

proc spellcheckResume {name mod} {
    if {$mod} {
	bringToFront $name
	revert -w $name
	status::msg "The window has been updated with spell-check changes."
    }
    hook::deregister resumeModifiedHook spellcheckResume $name
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "spellcheckSelection" --
 # 
 # Called by "Utils > Spellcheck Selection".
 # 
 # Ensure that we have a selection, and if so call [spellcheckRegion].
 # 
 # --------------------------------------------------------------------------
 ##

proc spellcheckSelection {} {
    requireSelection
    spellcheckRegion [getPos] [selEnd]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "spellcheckRegion" --
 # 
 # Send the selected region to the spellchecker program, prompting the user
 # to locate it if necessary.  
 # 
 # --------------------------------------------------------------------------
 ##

proc spellcheckRegion {from to} {
    ::xserv::invoke SpellcheckSelection -window [win::Current] \
      -from $from -to $to
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "spellcheckRegionResume" --
 # 
 # This hook is registered by [spellcheckRegion], which has created a temp
 # file containing the selection.  After the user has corrected any spelling
 # and saved the temporary file which contained the original text, we check
 # the contents to determine if anything has changed.  If so, then we replace
 # the current selection with the new version and deregister the hook.
 # 
 # --------------------------------------------------------------------------
 ##

proc spellcheckRegionResume {w tmpFile} {
    
    if {[win::Exists $w] && [win::checkIfWinToEdit $w] \
      && [file exists $tmpFile]} {
	set newText [file::readAll $tmpFile]
	# The resolution of bug 1611 should make this unnecessary.
	regsub -all "\n" $newText "\r" newText
	# Replace our text if it has changed.
	if {($newText ne [getSelect])} {
	    replaceAndSelectText -w $w [getPos -w $w] [selEnd -w $w] $newText
	    status::msg "New spellcheck changes have been inserted."
	} else {
	    status::msg "No spellcheck changes were made."
	}
    }
    hook::deregister resumeHook [list spellcheckRegionResume $w $tmpFile]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "spellcheck" --
 # 
 # Called by "Utils > Spellcheck".
 # 
 # Create a dialog offering the different options available.
 # 
 # --------------------------------------------------------------------------
 ##

proc spellcheck {} {
    set res [dialog::make {
	{Spellcheck options} 
	{
	    {menuindex {"Entire window" "From current position" "In selection"}} 
	    "Spellcheck" 0
	}
	{flag "Only spellcheck text inside comments" 0}
    }]
    foreach {area comment} $res {}
    if {$comment} {
	alertnote "Sorry, not yet implemented"
    } else {
	switch -- $area {
	    0 {
		spellcheckWindow
	    }
	    1 {
		spellcheckRegion [getPos] [maxPos]
	    }
	    2 {
		spellcheckSelection
	    }
	}
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Aspell interaction ×××× #
# 
# "aspell"
# 
# aspell check [ÇoptionsÈ] ÇfilenameÈ
# 
# at the command line where ÇfilenameÈ is the file you want to check and
# ÇoptionsÈ is any number of optional options.  Some of the more useful ones
# include:
# 
# --mode=Çmode> 
# 
#   the mode to use when checking files.  The available modes are none, url,
#   email, sgml, or tex.  See section 5.4.2 for more informations on the
#   various modes.
# 
# --dont-backup 
# 
#   don't create a backup file.
# 
# --sug-mode=ÇmodeÈ 
# 
#   the suggestion mode to use where mode is one of ultra, fast, normal, or
#   bad-spellers.  See section 5.4.5 for more information on these modes.
# 
# --master=ÇnameÈ 
# 
#   the main dictionary to use.  The default aspell installation provided
#   the following dictionaries: american, british, and canadian.
# 
# 6.2 Through A Pipe 
# 
# When given the pipe or -a command aspell goes into a pipe mode that is
# compatible with ``ispell -a''.  Aspell also defines its own set of
# extensions to ispell pipe mode.
# 
# 6.2.1 Format of the Data Stream 
# 
# In this mode, Aspell prints a one-line version identification message, and
# then begins reading lines of input.  For each input line, a single line is
# written to the standard output for each word checked for spelling on the
# line.  If the word was found in the main dictionary, or your personal
# dictionary, then the line contains only a '*'.
# 
# If the word is not in the dictionary, but there are suggestions, then the
# line contains an '&', a space, the misspelled word, a space, the number of
# near misses, the number of characters between the beginning of the line
# and the beginning of the misspelled word, a colon, another space, and a
# list of the suggestions separated by commas and spaces.
# 
# Finally, if the word does not appear in the dictionary, and there are no
# suggestions, then the line contains a '#', a space, the misspelled word, a
# space, and the character offset from the beginning of the line.  Each
# sentence of text input is terminated with an additional blank line,
# indicating that ispell has completed processing the input line.
# 
# These output lines can be summarized as follows: 
# 
# 
# OK: 
# * 
# Suggestions: 
# & ÇoriginalÈ ÇcountÈ ÇoffsetÈ: ÇmissÈ, ÇmissÈ, ... 
# None: 
# # ÇoriginalÈ ÇoffsetÈ 
# When in the -a mode, Aspell will also accept lines of single words
# prefixed with any of '*', '&', '@', '+', '-', '~', '#', '!', '%', or
# '^'. A line starting with '*' tells ispell to insert the word into the
# user's dictionary. A line starting with '&' tells ispell to insert an
# all-lowercase version of the word into the user's dictionary. A line
# starting with '@' causes ispell to accept this word in the future. A
# line starting with '+', followed immediately by a valid mode will cause
# aspell to parse future input according the syntax of that formatter. A
# line consisting solely of a '+' will place ispell in TEX/LATEX mode
# (similar to the -t option) and '-' returns aspell to its default mode
# (but these commands are obsolete). A line '~', is ignored for ispell
# compatibility. A line prefixed with '#' will cause the personal
# dictionaries to be saved. A line prefixed with '!' will turn on terse
# mode (see below), and a line prefixed with '%' will return ispell to
# normal (non-terse) mode. Any input following the prefix characters '+',
# '-', '#', '!', '~', or '%' is ignored, as is any input following. To
# allow spell-checking of lines beginning with these characters, a line
# starting with '^' has that character removed before it is passed to the
# spell-checking code. It is recommended that programmatic interfaces
# prefix every data line with an uparrow to protect themselves against
# future changes in Aspell. 
# 
# To summarize these: 
# 
# *ÇwordÈ 
# 
#   Add a word to the personal dictionary 
# 
# &ÇwordÈ 
# 
#   Insert the all-lowercase version of the word in the personal dictionary 
# 
# @ÇwordÈ 
# 
#   Accept the word, but leave it out of the dictionary 
# 
# # 
# 
#   Save the current personal dictionary 
# 
# ~ 
# 
#   Ignored for ispell compatibility. 
# 
# + 
# 
#   Enter TEX mode. 
# 
# +ÇmodeÈ 
# 
#   Enter the mode specified by ÇmodeÈ. 
# 
# - 
# 
#   Enter the default mode. 
# 
# ! 
# 
#   Enter terse mode 
# % 
# 
#   Exit terse mode 
# 
# ^ 
# 
#   Spell-check the rest of the line 
# 
# In terse mode, Aspell will not print lines beginning with '*', which
# indicate correct words.  This significantly improves running speed when
# the driving program is going to ignore correct words anyway.  In addition
# to the above commands which are designed for Ispell compatibility Aspell
# also supports its own extension.  All Aspell extensions follow the
# following format.
# 
# 
# $$ÇcommandÈ [data] 
# 
#   Where data may or may not be required depending on the particular
#   command.  Aspell currently supports the following command.
# 
# cs ÇoptionÈ,ÇvalueÈ 
# 
#   Change a configuration option. 
# 
# cr ÇoptionÈ 
# 
#   Prints the value of a configuration option. 
# 
# s Çword1È,Çword2È 
# 
#   Returns the score of the two words based roughly on how aspell would
#   score them.
# 
# Sw ÇwordÈ 
# 
#   Returns the soundlike equivalent of the word. 
# 
# Sl ÇwordÈ 
# 
#   Returns a list of words that have the same soundlike equivalent. 
# 
# Pw ÇwordÈ 
# 
#   Returns the phoneme equivalent of the word. 
# 
# pp 
# 
#   Returns a list of all words in the current personal wordlist. 
# 
# ps 
# 
#   Returns a list of all words in the current session dictionary. 
# 
# l 
# 
#   Returns the current language name. 
# 
# ra ÇmisÈ,ÇcorÈ 
# 
#   Add the word pair to the replacement dictionary for latter use.  Returns
#   nothing.  Anything returned is returned on its own line line.  All lists
#   returned have the following format
# 
#   Çnum of itemsÈ: Çitem1È, Çitem2È, ÇetcÈ 
# 
# (Part of the preceding section was directly copied out of the Ispell manual) 
# 

namespace eval spell {}

proc spell::checkWindow {w spellExecutable {first 0} {last -1}} {
    if {$w == ""} { error "Cancelled - no window" }
    
    variable spellLine $first
    variable spellMax $last
    
    variable misspell ""
    
    app::setupLineBasedInteraction \
      -callback [list spell::_gotstartup $w] -read gets \
      "$spellExecutable pipe"
}

proc spell::_gotstartup {win pipe status result} {
    app::configureLineBasedInteraction $pipe [list spell::_gotresult $win]

    variable done
    unset -nocomplain done
    
    if {$status == 0 && ([string length $result] >= 0)} {
	# it's ok
	status::msg $result
	puts $pipe "!"
	switch -- [win::getMode $win] {
	    "TeX" {
		puts $pipe "+tex"
	    }
	    "C" - "C++" - "Objc" - "Java" - "C#" {
		puts $pipe "+ccpp"
	    }
	    "HTML" {
		puts $pipe "+html" 
	    }
	}
	spell::_sendnextline $win $pipe
    } else {
	_shutdown $pipe
	status::msg "Spellcheck failed: $result"
    }
}

proc spell::_shutdown {pipe} {
    variable misspell ""
    app::closeLineBasedInteraction $pipe
}

proc spell::_gotresult {win pipe status result} {
    variable done

    if {[info exists done]} {return}
    if { $status != 0 } {
	# Error on the channel
	alertnote "spellcheck problem: error reading $pipe: $result"
	set done 2
    } elseif {[string length $result] >= 0 } {
	# Successfully read the channel
	switch -- [string index $result 0] {
	    "&" {
		# have suggestions
		set result [split $result :]
		set first [lindex $result 0]
		regsub -all "," [string trim [lindex $result 1]] "" result
		spell::foundMisspelling [lindex $first 1] \
		  [lindex $first 3] $result
	    }
	    "" {
		if {[spell::lineComplete $win $pipe \
		  [list spell::_sendnextline $win $pipe]]} {
		    _shutdown $pipe
		    status::msg "Spellcheck cancelled"
		    return
		}
	    }
            "#" {
                # No suggestion found
                set result [split $result " "]
                spell::foundMisspelling [lindex $result 1] \
                  [lindex $result 2] {}
            }
	    "*" {
		# Line is ok - do nothing
	    }
	    default {
		spell::_sendnextline $win $pipe
	    }
	}
    } elseif {[eof $pipe]} {
	# End of file on the channel
	alertnote "spellcheck problem: end of file"
	set done 1
    } elseif {[fblocked $pipe]} {
	# Read blocked.  Just return
    } else {
	# Something else
	alertnote "spellcheck problem: can't happen"
	set done 3
    }
    #update idletasks
}

proc spell::lineComplete {win pipe nextLineCmd} {
    # Ask the user about this line; when we're done go on to
    # the next line
    variable misspell
    foreach err $misspell {
	foreach {row index word sugg} $err {break}
	set start [pos::fromRowChar -w $win $row [expr {$index -1}]]
	selectText -w $win $start [pos::math -w $win $start + [string length $word]]
	if {[spell::getUserInput $win $pipe $sugg]} {
	    set misspell ""
	    return 1
	}
    }
    
    set misspell ""
    eval $nextLineCmd
    return 0
}

proc spell::getUserInput {win pipe sugg} {
    set msg "(I)gnore, (A)dd, or replace:"
    for {set i 0} {$i < [llength $sugg]} {incr i} {
	if {$i == 10} {
	    break
	}
	set word [lindex $sugg $i]
	if {$i != 0} { append msg ", " }
	append msg "(${i})$word"
    }
    append msg ", or Esc to cancel"
    set res [status::prompt -add key \
      -command [list spell::updateUserInput $sugg] $msg]
    switch -- [lindex $res 0] {
	"ignore" {
	    # nothing
	    return 0
	}
	"add" {
	    # Add the word to the dictionary
	    set word [getSelect]
	    status::msg "Adding '$word'"
	    puts $pipe "*$word"
	    # Save the user dictionary immediately
	    puts $pipe "#"
	    return 0
	}
	"replace" {
	    update idletasks
	    set selectLimits [list [getPos -w $win] [selEnd -w $win]]
	    eval [list replaceText -w $win] $selectLimits \
	      [list [lindex $res 1]]
	    return 0
	}
	"cancel" {
	    return 1
	}
	default {
	    alertnote "Spellcheck implementation bug: please report this."
	    return 1
	}
    }
}

proc spell::updateUserInput {sugg key} {
    switch -- $key {
	"i" {
	    return -code return "ignore"
	}
	"a" {
	    return -code return "add"
	}
	0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 {
	    set word [lindex $sugg $key]
	    return -code return [list "replace" $word]
	}
	"" {
	    return -code return "cancel"
	}
	default {
	    # nothing
	}
    }
}

proc spell::foundMisspelling {word charindex suggestions} {
    variable misspell
    variable spellLine
    lappend misspell [list $spellLine $charindex $word $suggestions] 
}

proc spell::_sendnextline {win pipe args} {
    variable spellLine
    variable spellMax
    while {1} {
	incr spellLine
	if {$spellMax != -1 && $spellLine > $spellMax} {
	    status::msg "Spellcheck reached end of selection"
	    _shutdown $pipe
	    return
	}
	set pos [pos::fromRowChar -w $win $spellLine 0]
	if {[pos::compare -w $win $pos >= [pos::max -w $win]]} {
	    status::msg "Spellcheck complete"
	    _shutdown $pipe
	    return
	}
	set spellText [getText -w $win $pos [pos::lineEnd -w $win $pos]]
	if {[string length [string trim $spellText]]} {
	    break
	}
    }
    puts $pipe "^$spellText"
}

# ===========================================================================
# 
# .