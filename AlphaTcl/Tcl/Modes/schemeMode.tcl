## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "schemeMode.tcl"
 #                                          created: 07/03/1996 {02:19:49 pm}
 #                                      last update: 05/23/2006 {10:45:50 AM}
 # Description: 
 # 
 # For editing Scheme files.
 #
 # Original by Oleg Kiselyov (oleg@ponder.csci.unt.edu) 
 # 
 # Updated by Craig Barton Upright, who will maintain this until somebody
 # else steps forward.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 1996-2006  Oleg Kiselyov, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of Scheme mode ×××× #
# 

alpha::mode [list Scm Scheme] 2.2 schemeMode.tcl {
    *.scm
} {
    schemeMenu
} {
    # Script to execute at Alpha startup
    addMenu schemeMenu "Scheme" Scm
    set modeCreator(MrEd) Scm
    set modeCreator(MrSt) Scm
    set modeCreator(MzSt) Scm
} uninstall {
    catch {file delete [file join $HOME Tcl Modes schemeMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions ScmCompletions.tcl]}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of Scheme programming files
} help {
    The Scheme dialect of Lisp was created in 1975 by Guy Steele and Gerry
    Sussman to explore ideas in programming-language semantics.  They
    showed that a powerful language can be made "not by piling feature on
    top of feature, but by removing the weaknesses and restrictions that
    make additional features appear necessary".  Scheme pioneered lexical
    scope in Lisp, first-class continuations, and tail recursion, and more
    recently added an advanced macro system.  It's the best-known Lisp
    dialect after Common Lisp (which it influenced).  It is IEEE
    standardized and widely used in universities and in electronic CAD
    systems.
    
                                               -- <http://www.lisp.org>
    
    Alpha's Scheme mode includes a user-expandable dictionary of keywords, a
    full set of Electric Completions, and a sophisticated indentation
    procedure.  Scm mode also uses its own 'Scheme' menu, which is based on
    the Lisp menu.  See the "Lisp Help" file for more information.
    
    Click on this "Scheme Example.scm" link for an example syntax file.
}

proc schemeMode.tcl {} {}

namespace eval Scm {
    
    # Comment Character variables for Comment Line/Paragraph/Box menu items.
    variable commentCharacters
    array set commentCharacters [list \
      "General"         ";; " \
      "Paragraph"       [list ";; " " ;;" " ; "] \
      "Box"             [list ";" 2 ";" 2 ";" 3] \
      ]
    
    # Set the list of flag preferences which can be changed in the menu.
    variable prefsInMenu [list \
      "fullIndent" \
      "noHelpKey" \
      "(-)" \
      "autoMark" \
      ]
    
    # Used in [Scm::colorizeScm].
    variable firstColorCall
    if {![info exists firstColorCall]} {
	set firstColorCall 1
    }
    
    # ===========================================================================
    #
    # ×××× Keyword Dictionaries ×××× #
    #
    
    variable keywordLists
    
    set keywordLists(macros) [list \
      abs and append apply assoc assq assv begin caar cadr \
      call-with-current-continuation car case cdar cddr cdr cond cons \
      declare define define-macro delay do else exact->inexact for-each if \
      inexact->exact lambda length let let* letrec list list-refmake-vector \
      map member memq memv number->string or peek-char read-char reverse \
      set!  set-car!  set-cdr!  string string->number string-append \
      string-length string-ref string-set!  substring vector vector-length \
      vector-ref vector-set! \
      ]
    
    set keywordLists(arguments) [list \
      #f #t \
      char?  eof-object?  eq?  equal?  eqv?  even?  list?  negative?  not \
      null?  odd?  pair?  positive?  procedure?  string=?  zero? \
      ]
}

# ===========================================================================
#
# ×××× Setting Scheme mode variables ×××× #
#

#=============================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  fillColumn        {75}            Scm
newPref var  leftFillColumn    {0}             Scm
newPref var  prefixString      {;; }           Scm
newPref var  wordBreak         {[\w\-]+}       Scm
newPref var  lineWrap          {0}             Scm
newPref var  commentsContinuation 1            Scm "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Scm
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Scm

#=============================================================================
#
# Flag preferences
#

# To automatically mark files when they are opened, turn this item on||To
# disable the automatic marking of files when they are opened, turn this
# item off
newPref flag autoMark          {0}             Scm
# To indent all continued commands (indicated by unmatched parantheses) by
# the full indentation amount rather than half, turn this item on|| To
# indent all continued commands (indicated by unmatched parantheses) by half
# of the indentation amount rather than the full, turn this item off
newPref flag fullIndent        {1}             Scm
# To primarily use a www site for help rather than the local Scheme
# application, turn this item on|| To primarily use the local Scheme
# application for help rather than on a www site turn this item off
newPref flag localHelp          {0}     Scm     {Scm::rebuildMenu lispHelp}
# If your keyboard does not have a "Help" key, turn this item on.  This will
# change some of the menu's key bindings|| If your keyboard has a "Help"
# key, turn this item off.  This will change some of the menu's key bindings
newPref flag noHelpKey          {0}     Scm     {Scm::rebuildMenu lispHelp}

# This isn't used yet.
prefs::deregister "localHelp" "Scm"

#=============================================================================
#
# Variable preferences
# 

# Enter additional arguments to be colorized.
newPref var addArguments      {}              Scm    {Scm::colorizeScm}
# Enter additional Scm macros to be colorized.  
newPref var addMacros         {}              Scm    {Scm::colorizeScm}
# Command double-clicking on a Scheme keyword will send it to this url
# for a help reference page.
newPref url schemeHelp {http://www.harlequin.com:8000/xanalys_int/query.html?qt=} Scm
# Click on "Set" to find the local Scheme application.
newPref sig schemeSig         {}              Scm

# ===========================================================================
# 
# Color preferences
#

prefs::renameOld ScmmodeVars(commandColor) ScmmodeVars(macroColor)

newPref color argumentColor     {magenta}       Scm    {Scm::colorizeScm}
newPref color macroColor        {blue}          Scm    {Scm::colorizeScm}
newPref color commentColor      {red}           Scm    {stringColorProc}
newPref color stringColor       {green}         Scm    {stringColorProc}
newPref color symbolColor       {magenta}       Scm    {Scm::colorizeScm}

# ===========================================================================
# 
# Categories of all S+/R preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "Scm" "Editing" [list \
  "autoMark" \
  "electricBraces" \
  "fillColumn" \
  "fullIndent" \
  "indentOnReturn" \
  "leftFillColumn" \
  "lineWrap" \
  "wordBreak" \
  ]

# Comments
prefs::dialogs::setPaneLists "Scm" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Colors
prefs::dialogs::setPaneLists "Scm" "Colors" [list \
  "addArguments" \
  "addMacros" \
  "argumentColor" \
  "macroColor" \
  "stringColor" \
  "symbolColor" \
  "useMassLibrary" \
  ]

# Help
prefs::dialogs::setPaneLists "Scm" "Scheme Help" [list \
  "noHelpKey" \
  "schemeHelp" \
  "schemeSig" \
  ]

# ===========================================================================
# 
# Colorize Scheme.
# 
# Used to update preferences, and could be called in a <mode>Prefs.tcl file
# 

proc Scm::colorizeScm {{pref ""}} {
    
    global ScmmodeVars ScmUserMacros ScmUserArguments
    
    global ScmCommandList Scmcmds
    
    variable firstColorCall
    variable keywordLists
    
    set Scmcmds [list]
    # First setting aside only the commands, for Scm::Completion::Command.
    eval [list lappend macroList] $keywordLists(macros) $ScmmodeVars(addMacros)
    if {[info exists ScmUserMacros]} {
	eval [lappend macroList] $ScmUserMacros
    }
    # Now create a list of arguments.
    eval [list lappend arguments] $keywordLists(arguments) \
      $ScmmodeVars(addArguments)
    if {[info exists ScmUserArguments]} {
	eval [lappend arguments] $ScmUserArguments
    }
    # "Scmcmds"
    eval [list lappend Scmcmds] $macroList $arguments
    set Scmcmds [lsort -dictionary -unique $Scmcmds]
    
    # Now we colorize keywords.  If this is the first call, we don't include 
    # the "-a" flag.
    if {$firstColorCall} {
	regModeKeywords -C Scm {}
	set firstColorCall 0
    }
    
    # Color comments and strings
    regModeKeywords -a -e {;} -c $ScmmodeVars(commentColor) \
      -s $ScmmodeVars(stringColor) Scm
    
    # Commmands
    regModeKeywords -a -k $ScmmodeVars(macroColor) Scm $macroList
    
    # Arguments
    regModeKeywords -a -k $ScmmodeVars(argumentColor) Scm $arguments
    
    # Symbols
    regModeKeywords -a -i "+" -i "-" -i "*" -i "\\" -i "/" \
      -I $ScmmodeVars(symbolColor) Scm {}
    
    if {($pref ne "")} {
	refresh
    }
    return
}

# Call this now.
Scm::colorizeScm

# ===========================================================================
#
# ×××× Key Bindings, Electrics ×××× #
# 
# abbreviations:  <o> = option, <z> = control, <s> = shift, <c> = command
# 

Bind '\r'   <s>     {Scm::continueMacro} Scm
Bind '\)'           {Scm::electricRight "\)"} Scm

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev macro, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {Scm::searchFunc 0 0 0} Scm
Bind  left  <sz>    {Scm::searchFunc 0 0 1} Scm
Bind  down  <sz>    {Scm::searchFunc 1 0 0} Scm
Bind right  <sz>    {Scm::searchFunc 1 0 1} Scm

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::carriageReturn" --
 # 
 # Inserts a carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::carriageReturn {} {
    
    global ScmmodeVars
    
    if {[isSelection]} {
	deleteSelection
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    if {[regexp {^([\t ])*\)} [getText $pos1 $pos2]]} {
	createTMark temp $pos2
	bind::IndentLine
	gotoTMark temp
	removeTMark temp
    }
    insertText "\r"
    bind::IndentLine
    return
}

proc Scm::electricRight {{char "\}"}} {
    
    set pos [getPos]
    typeText $char
    if {![regexp {[^ \t]} [getText [lineStart $pos] $pos]]} {
	set pos [lineStart $pos]
	createTMark temp [getPos]
	bind::IndentLine
	gotoTMark temp
	removeTMark temp
	bind::CarriageReturn
    }
    if {[catch {blink [matchIt $char [pos::math $pos - 1]]}]} {
	beep
	status::msg "No matching $char !!"
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::continueMacro" --
 # 
 # Over-rides the automatic indentation of lines that begin with \) so that
 # additional text can be entered.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::continueMacro {} {
    
    global ScmmodeVars indentationAmount
    
    Scm::carriageReturn
    if {[pos::compare [getPos] != [maxPos]]} {
	set nextChar [getText [getPos] [pos::math [getPos] + 1]]
	if {($nextChar eq "\)")} {
	    set continueIndent [expr {$ScmmodeVars(fullIndent) + 1}]
	    insertText [text::indentOf \
	      [expr {$continueIndent * $indentationAmount/2}]]
	}
    }
    return
}

proc Scm::searchFunc {direction args} {
    
    if {![llength $args]} {
	set args [list 0 2]
    }
    if {$direction} {
	eval function::next $args
    } else {
	eval function::prev $args
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::getLimits" --
 # 
 # This is used preferentially by 'function::getLimits'
 # 
 # The idea is to find the start of the closest macro (in the specified
 # direction, and based solely on indentation), the start of the next, and
 # then back up to remove empty lines.  Trailing parens are not ignored
 # backing up, so that they are retained as part of the macro.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::getLimits {args} {
    
    win::parseArgs w pos direction
    
    set posBeg ""
    set posEnd ""
    set what   "macro"
    set pat1 {^\([^\r\n\t \;]}
    set pat2 {^[\t ]*(;.*)?$}
    set pos1 $pos
    set posBeg ""
    set posEnd ""
    if {![catch {search -w $w -f $direction -s -r 1 -i 1 $pat1 $pos1} match]} {
	# This is the start of the closest function.
	set posBeg [lindex $match 0]
	set pos2   [lindex $match 1]
	if {![catch {search -w $w -s -f 1 -r 1 $pat1 $pos2} match]} {
	    # This is the start of the next one.
	    set posEnd [lindex $match 0]
	} else {
	    set posEnd [maxPos -w $w]
	}
	# Now back up to skip empty lines, ignoring comments as well.
	while {1} {
	    set posEndPrev [pos::math -w $w $posEnd - 1]
	    set prevLine   [getText -w $w \
	      [pos::lineStart -w $w $posEndPrev] $posEndPrev]
	    if {![regexp $pat2 $prevLine]} {
		break
	    }
	    set posEnd [pos::lineStart -w $w $posEndPrev]
	}
    }
    return [list $posBeg $posEnd $what]
}

# ===========================================================================
#
# ×××× Indentation ×××× #
# 
# Indenting a line of a Scheme code
#
# The idea is simple: the indent of a new line is the same as the indent of
# the previous non-empty non-comment-only line *plus* the paren balance of
# that line times two.
# 
# That is, if the last code line was paren balanced, the next line would
# have the same indent.  If the prev line opened an expression but didn't
# close it, the new line would be indented further
#

# This was the original procedure, with a little modification:

# proc Scm::indentLine {} {
# 
#     global mode indent_amounts ScmmodeVars
#     
#     set continueIndent [expr {$ScmmodeVars(fullIndent)  + 1}]
#     
#     set beg [lineStart [getPos]]
#     set end [nextLineStart [getPos]]
#     
#     # Find last previous non-comment line and get its leading whitespace
#     set pos $beg
#     set lst [search -s -f 0 -r 1 -i 0 {^[ \t]*[^ ;\t\r\n]} [pos::math $pos - 1]]   
#     set line [getText [lindex $lst 0] [pos::math [nextLineStart [lindex $lst 0]] - 1]]
#     set lwhite [getText [lindex $lst 0] [pos::math [lindex $lst 1] - 1]]
#     
#     # Computing the balance of parentheses within the 'line':
#     # 
#     # This appears to be utterly elementary.  One has to keep in mind
#     # however that parentheses might appear in comments and/or quoted
#     # strings, in which case they shouldn't count.  Although it's easy to
#     # detect a Scheme comment by a semicolon, a semicolon can also appear
#     # within a quoted string.  Note that a double quote isn't that sure a
#     # sign of a quoted string: the double quote may be escaped.  And the
#     # backslash can be escaped in turn...  Thus we face a full-blown
#     # problem of parsing a string according to a context-free grammar.  We
#     # note however that a TCL interpretor does similar kind of parsing all
#     # the time.  So, we can piggy-back on it and have it decide what is the
#     # quoted string and when a semicolon really starts a comment.  To this
#     # end, we replace all non-essential characters from the 'line' with
#     # spaces, separate all parens with spaces (so each paren would register
#     # as a separate token with the TCL interpretor), replace a semicolon
#     # with an opening brace (which, if unescaped and unquoted, acts as some
#     # kind of "comment", that is, shields all symbols that follows).  After
#     # that, we get TCL interpretor to convert thus prepared 'line' into a
#     # list, and simply count the balance of '(' and ')' tokens.
#     # 
#     
#     regsub -all -nocase {[^ ();\"\\]} $line { } line1
#     regsub -all {;} $line1 "\{" line
#     regsub -all {[()]} $line { \0 } line1
#     set line_list [eval "list $line1 \}"]
#     #alertnote ">$line_list<"
#     set balance 0
#     foreach i $line_list { 
# 	switch $i {
# 	    ( {incr balance $continueIndent} 
# 	    ) {incr balance -continueIndent}
# 	}
#     }
#     #alertnote "balance $balance, lwhite [string length $lwhite]"
#     if {($balance < 0)} {
#       set lwhite [string range $lwhite 0 [expr [string length $lwhite] + 2 * $balance - 1]]
#     } else {
#       append lwhite [string range "              " 1 [expr 2 * $balance]]
#     }
#     #alertnote "new lwhite [string length $lwhite]"
#     
#     set text [getText $beg [nextLineStart $beg]]
#     regexp {^[ \t]*} $text white
#     set len [string length $white]
#     
#     if {($white != $lwhite)} {
#       replaceText $beg [pos::math $beg + $len] $lwhite
#     }
#     goto [pos::math $beg + [string length $lwhite]]
#     return
#     
# }

proc Scm::correctIndentation {args} {
    
    global ScmmodeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    if {([win::getMode] eq "Scm")} {
	set continueIndent [expr {$ScmmodeVars(fullIndent) + 1}]
    } else {
	set continueIndent 1
    }
    set continueIndent [expr {$indentationAmount * $continueIndent/2}]
    
    set posBeg   [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine [Scm::getMacroLine -w $w $posBeg 1 1]
    set prevLine [Scm::getMacroLine -w $w [pos::math -w $w $posBeg - 1] 0 1]
    set lwhite   [lindex $prevLine 1]
    # If we have a previous line ...
    if {[pos::compare [lindex $prevLine 0] != $posBeg]} {
	# Find out if there are any unbalanced (,) in the last line.
	regsub -all {[^ \(\)\"\;\\]} $prevLine { } line
	# Remove all literals.
	regsub -all {\\\(|\\\)|\\\"|\\\;} $line { } line
	regsub -all {\\} $line { } line
	# If there is only one quote in a line, next to a closing brace,
	# assume that this is a continued quote from another line.  So add
	# a double quote at the beginning of the line (which will make us
	# ignore everything up to that point).  Not entirely foolproof ...
	if {![regexp {\".+\"} $line] && [regexp {\"[\t ]*\)} $line]} {
	    set line [concat \"$line]
	}
	# Remove everything surrounded by quotes.
	regsub -all {\"[^\"]+\"} $line { } line
	regsub -all {\"} $line { } line
	# Remove all characters following the first valid comment.
	if {[regexp {\;} $line]} {
	    set line [string range $line 0 [string first {;} $line]]
	}
	# Now turn all braces into "more" and "less"
	regsub -all {\(} $line { more } line
	regsub -all {\)} $line { less } line
	# Now indent based upon more and less.
	foreach i $line {
	    if {($i eq "more")} {
		incr lwhite $continueIndent
	    } elseif {($i eq "less")} {
		incr lwhite -$continueIndent
	    }
	}
	# Did the last line start with a lone \) ?  If so, we want to keep the
	# indent, and not make call it an unbalanced line.
	if {[regexp {^[\t ]*\)} [lindex $prevLine 2]]} {
	    incr lwhite $continueIndent
	}
    }
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is \) or \}.
	if {($next eq "\)") || [regexp {^[\t ]*\)} [lindex $thisLine 2]]} {
	    incr lwhite -$continueIndent
	}
    }
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::getMacroLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text of
 # the command line.  If the search for the next/prev command fails, return
 # an indentation level of 0.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::getMacroLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\; ]}
    } else {
	set pat {^[\t ]*[^\t\r\n ]}
    }
    set posBeg [pos::math -w $w [pos::lineStart -w $w $pos] - 1]
    if {[pos::compare -w $w $posBeg < [minPos -w $w]]} {
	set posBeg [minPos -w $w]
    }
    set lwhite 0
    if {![catch {search -w $w -s -f $direction -r 1 $pat $pos} match]} {
	set posBeg [lindex $match 0]
	set lwhite [lindex [pos::toRowCol -w $w \
	  [pos::math -w $w [lindex $match 1] - 1]] 1]
    }
    set posEnd [pos::math -w $w [pos::nextLineStart -w $w $posBeg] - 1]
    if {[pos::compare -w $w $posEnd > [maxPos -w $w]]} {
	set posEnd [maxPos -w $w]
    } elseif {[pos::compare -w $w $posEnd < $posBeg]} {
	set posEnd $posBeg
    }
    return [list $posBeg $lwhite [getText -w $w $posBeg $posEnd]]
}

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::DblClick" --
 # 
 # Checks to see if the highlighted word appears in any keyword list, and if
 # so, sends the selected word to the www.Lisp.com help site.
 # 
 # Control-Command double click will insert syntax information in status bar.
 # Shift-Command double click will insert commented syntax information in
 # window.
 # 
 # (The above is not yet implemented: need to enter all of the syntax info.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::DblClick {from to shift option control} {
    
    global ScmmodeVars Scmcmds 
    
    variable syntaxMessages
    
    selectText $from $to
    set command [getSelect]
    
    set varDef "(def|make)+(\[-a-zA-Z0-9\]+(\[\t\' \]+$command)+\[\t\r\n\(\) \])"
    
    if {![catch {search -s -f 1 -r 1 -m 0 $varDef [minPos]} match]} {
	# First check current file for a function, variable (etc)
	# definition, and if found ...
	placeBookmark
	goto [lineStart [lindex $match 0]]
	status::msg "press <Ctl .> to return to original cursor position"
	return
	# Could next check any open windows, or files in the current
	# window's folder ...  but not implemented.  For now, variables
	# (etc) need to be defined in current file.
    }
    if {![lcontains Scmcmds $command]} {
	status::msg "'$command' is not defined as a Scm system keyword."
	return
    }
    # Any modifiers pressed?
    if {$control} {
	# CONTROL -- Just put syntax status::msg in status bar window
	if {[info exists syntaxMessages($command)]} {
	    status::msg "$syntaxMessages($command)"
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$shift} {
	# SHIFT --Just insert syntax message as commented text
	if {[info exists syntaxMessages($command)]} {
	    endOfLine
	    insertText "\r"
	    insertText "$syntaxMessages($command)"
	    comment::Line
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } else {
	# No modifiers -- Send command for on-line help.  This is the
	# "default" behavior.
	Scm::wwwMacroHelp $command
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::wwwMacroHelp" --
 # 
 # Send macro to defined url, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::wwwMacroHelp {{macro ""}} {
    
    global ScmmodeVars
    
    if {($macro eq "")} {
	if {[catch {prompt "On-line SAS help for É" ""} macro]} {
	    error "cancel"
	}
    }
    status::msg "'$macro' sent to $ScmmodeVars(schemeHelp)"
    urlView $ScmmodeVars(schemeHelp)$macro
    return
}

proc Scm::localMacroHelp {args} {
    Scm::betaMessage
    return
}

# ===========================================================================
#
# ×××× Mark File and Parse Functions ×××× #
#

proc Scm::MarkFile {args} {
    
    win::parseArgs w
    
    status::msg "Marking \"[win::Tail $w]\" É"
    
    set count 0
    set pos [minPos -w $w]
    set pat {^[ \t]*[\(][#a-zA-z]*(define|define-[a-zA-Z]+) +[\(]*([^\(\) \t\r\n]+)}
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $pat $pos} match]} {
	regexp -nocase -- $pat [eval [list getText -w $w] $match] allofit defunname name
	set pos0 [lindex $match 0]
	set pos1 [pos::nextLineStart -w $w $pos0]
	set mark [string trimleft [string trim [getText -w $w $pos0 $pos1]] "\("]
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	setNamedMark -w $w $mark $pos0 $pos0 $pos0
	incr count
	set pos $pos1
    }
    set msg "The window \"[win::Tail $w]\" contains $count mark"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::parseFuncs" --
 # 
 # This will return only the Scm command names.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::parseFuncs {} {
    
    global sortFuncsMenu
    
    set pos [minPos]
    set m   [list ]
    while {![catch {search -s -f 1 -r 1 -i 0 {^\((\w+)} $pos} match]} {
	if {[regexp -- {(\w+)} [eval getText $match] "" word]} {
	    lappend m [list $word [lindex $match 0]]
	}
	set pos [lindex $match 1]
    }
    if {$sortFuncsMenu} {
	set m [lsort -dictionary $m]
    }
    return [join $m]
}

# ===========================================================================
# 
# ×××× -------------------- ×××× #
# 
# ×××× Scheme Menu ×××× #
# 

proc schemeMenu {} {}

# Tell Alpha what procedures to use to build all menus, submenus.
menu::buildProc schemeMenu Scm::buildMenu     {Scm::postBuildMenu}
menu::buildProc schemeHelp Scm::buildHelpMenu

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::buildMenu" --
 # 
 # Build the Scheme menu.  We leave out these items:
 # 
 #   "/P<U<OprocessFile"
 #   "/P<U<O<BprocessSelection"
 # 
 # until they are properly implemented.
 #   

 # --------------------------------------------------------------------------
 ##

proc Scm::buildMenu {} {
    
    global schemeMenu
    
    variable prefsInMenu
    
    set optionItems $prefsInMenu
    set keywordItems [list \
      "listKeywords" "checkKeywordsÉ" "addNewMacrosÉ" "addNewArgumentsÉ"]
    set menuList [list \
      "schemeHomePage" \
      "switchToScheme" \
      "(-)" \
      [list Menu -n schemeHelp           -M Scm {}] \
      [list Menu -n schemeModeOptions -p Scm::menuProc -M Scm $optionItems] \
      [list Menu -n schemeKeywords    -p Scm::menuProc -M Scm $keywordItems] \
      "(-)" \
      "/b<UcontinueMacro" \
      "/'<E<S<BnewComment" \
      "/'<S<O<BcommentTemplateÉ" \
      "(-)" \
      "/N<U<BnextMacro" \
      "/P<U<BprevMacro" \
      "/S<U<BselectMacro" \
      "/I<B<OreformatMacro" \
      ]
    set submenus [list schemeHelp]
    return       [list build $menuList "Scm::menuProc -M Scm" $submenus $schemeMenu]
}

# Then build the "Scm Help" submenu.

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::buildHelpMenu" --
 # 
 # Build the "Scheme Help" menu.  We leave out these items:
 # 
 #   "${key}<IlocalMacroHelpÉ"
 #   "${key}<OlocalMacroHelpÉ"
 # 
 # until they are properly implemented.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::buildHelpMenu {} {
    
    global ScmmodeVars
    
    # Determine which key should be used for "Help", with F8 as option.
    if {!$ScmmodeVars(noHelpKey)} {
	set key "/t"
    } else {
	set key "/l"
    }
    set menuList [list "${key}<IwwwMacroHelpÉ" "setSchemeApplicationÉ" \
      "${key}<BschemeModeHelp"]
    
    return [list build $menuList "Scm::menuProc -M Scm" {}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::postBuildMenu" --
 # 
 # Mark or dim items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::postBuildMenu {args} {
    
    global ScmmodeVars
    
    variable prefsInMenu
    
    foreach itemName $prefsInMenu {
	if {[info exists ScmmodeVars($itemName)]} {
	    markMenuItem schemeModeOptions $itemName $ScmmodeVars($itemName) Ã
	}
    }
    return
}

# Now we actually build the Scm menu.
menu::buildSome schemeMenu

proc Scm::rebuildMenu {{menuName "schemeMenu"}} {
    menu::buildSome $menuName
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::registerOWH" --
 # 
 # Dim some menu items when there are no open windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::registerOWH {{which "register"}} {
    
    global schemeMenu
    
    set menuItems {
	processFile processSelection continueMacro
	newComment commentTemplateÉ
	nextMacro prevMacro selectMacro reformatMacro
    }
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $schemeMenu $i] 1
    }
    return
}

# Call this now.
Scm::registerOWH register
rename Scm::registerOWH ""

# ===========================================================================
# 
# ×××× Scm menu support ×××× #
# 
# We make some of these items "Scm Mode Only"
# 


## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::menuProc" --
 # 
 # This is the procedure called for all main menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::menuProc {menuName itemName} {
    
    global Scmcmds ScmmodeVars mode
    
    variable prefsInMenu
    
    switch $menuName {
	"schemeHelp" {
	    switch $itemName {
		"setSchemeApplication"  {Scm::setApplication "Scheme"}
		"schemeModeHelp"        {package::helpWindow "Scm"}
		default                 {Scm::$itemName}
	    }
	}
	"schemeModeOptions" {
	    if {[getModifiers]} {
		set helpText [help::prefString $itemName "Scm"]
		if {$ScmmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		if {($end eq "on")} {
		    regsub {^.*\|\|} $helpText {} helpText
		} else {
		    regsub {\|\|.*$} $helpText {} helpText
		}
		set msg "The '$itemName' preference for Scm mode is currently $end."
		dialog::alert "${helpText}."
	    } elseif {[lcontains prefsInMenu $itemName]} {
		set ScmmodeVars($itemName) [expr {$ScmmodeVars($itemName) ? 0 : 1}]
		if {($mode eq "Scm")} {
		    synchroniseModeVar $itemName $ScmmodeVars($itemName)
		} else {
		    prefs::modified $ScmmodeVars($itemName)
		}
		if {[regexp {Help} $itemName]} {Scm::rebuildMenu "schemeHelp"}
		Scm::postBuildMenu
		if {$ScmmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		set msg "The '$itemName' preference is now $end."
	    } else {
		set msg "Don't know what to do with '$itemName'."
	    }
	    if {[info exists msg]} {
		status::msg $msg
	    }
	}
	"schemeKeywords" {
	    if {($itemName eq "listKeywords")} {
		set keywords [listpick -l -p "Current Scm mode keywordsÉ" $Scmcmds]
		foreach keyword $keywords {
		    Scm::checkKeywords $keyword
		}
	    } elseif {($itemName eq "addNewMacros") \
	      || ($itemName eq "addNewArguments")} {
		set itemName [string trimleft $itemName "addNew"]
		Scm::addKeywords $itemName
	    } else {
		Scm::$itemName
	    }
	    return
	}
	"markScmFileAs" {
	    removeAllMarks
	    switch $itemName {
		"source" {Scm::MarkFile}
	    }
	}
	default {
	    switch $itemName {
		"schemeHomePage"    {url::execute $ScmmodeVars(schemeHomePage)}
		"switchToScm"       {app::launchFore $ScmmodeVars(schemeSig)}
		"newComment"        {comment::newComment 0}
		"commentTemplate"   {comment::commentTemplate}
		"nextMacro"         {Scm::searchFunc 1 0 0}
		"prevMacro"         {Scm::searchFunc 0 0 0}
		"selectMacro"       {function::select}
		"reformatMacro"     {function::reformat}
		default             {Scm::$itemName}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::betaMessage" --
 # 
 # Give a beta message for untested features / menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::betaMessage {{item ""}} {
    
    if {($item eq "")} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
    }
    error "Cancelled -- '$item' has not been implemented yet."
}


## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::sig" --
 # 
 # Return the Scm signature.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::sig {{app "Scheme"}} {
    
    global ScmmodeVars
    
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    if {($ScmmodeVars(${lowApp}Sig) eq "")} {
	alertnote "Looking for the $capApp application ..."
	Scm::selectApplication $lowApp
    }
    return $ScmmodeVars(${lowApp}Sig)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Scm::selectApplication" --
 # 
 # Prompt the user to locate the local Scm application.
 # 
 # --------------------------------------------------------------------------
 ##

proc Scm::selectApplication {{app "Scm"}} {
    
    global ScmmodeVars
    
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    set newSig ""
    set newSig [dialog::askFindApp $capApp $ScmmodeVars(${lowApp}Sig)]
    
    if {($newSig ne "")} {
	set ScmmodeVars(${lowApp}Sig) "$newSig"
	prefs::modified ScmmodeVars(${lowApp}Sig)
	status::msg "The $capApp signature has been changed to '$newSig'."
	return
    } else {
	error "cancel"
    }
}

# ===========================================================================
#
# ×××× Keywords ×××× #
# 

proc Scm::addKeywords {{category} {keywords ""}} {
    
    global ScmmodeVars
    
    if {($keywords eq "")} {
	set keywords [prompt "Enter new Scm mode $category:" ""]
    }
    
    # Check to see if the keyword is already defined.
    foreach keyword $keywords {
	set checkStatus [Scm::checkKeywords $keyword 1 0]
	if {($checkStatus ne 0)} {
	    alertnote "Sorry, '$keyword' is already defined\
	      in the $checkStatus list."
	    error "cancel"
	}
    }
    # Keywords are all new, so add them to the appropriate mode preference.
    append ScmmodeVars(add$category) " $keywords"
    set ScmmodeVars(add$category) [lsort $ScmmodeVars(add$category)]
    synchroniseModeVar add$category $ScmmodeVars(add$category)
    Scm::colorizeScm
    status::msg "'$keywords' added to $category preference."
    return
}

proc Scm::checkKeywords {{newKeywordList ""} {quietly 0} {noPrefs 0}} {
    
    global ScmmodeVars ScmUserMacros ScmUserArguments
    
    variable keywordLists
    
    set type 0
    if {($newKeywordList eq "")} {
	set quietly 0
	set newKeywordList [prompt "Enter Scm mode keywords to be checked:" ""]
    }
    # Check to see if the new keyword(s) is already defined.
    foreach newKeyword $newKeywordList {
	if {[lcontains keywordLists(macros) $newKeyword]} {
	    set type "default macros"
	} elseif {[lcontains keywordLists(arguments) $newKeyword]} {
	    set type "arguments"
	} elseif {[lcontains ScmUserMacros $newKeyword]} {
	    set type ScmUserMacros
	} elseif {[lcontains ScmUserArguments $newKeyword]} {
	    set type ScmUserArguments
	} elseif {!$noPrefs && \
	  [lcontains ScmmodeVars(addMacros) $newKeyword]} {
	    set type ScmmodeVars(addMacros)
	} elseif {!$noPrefs && \
	  [lcontains ScmmodeVars(addArguments) $newKeyword]} {
	    set type ScmmodeVars(addArguments)
	}
	if {$quietly} {
	    # When this is called from other code, it should only contain
	    # one keyword to be checked, and we'll return it's type.
	    return "$type"
	} elseif {!$quietly && ($type eq 0)} {
	    alertnote "'$newKeyword' is not currently defined\
	      as a Scm mode keyword"
	} elseif {($type ne 0)} {
	    # This will work for any other value for "quietly", such as "2"
	    alertnote "'$newKeyword' is currently defined as a keyword\
	      in the '$type' list."
	}
	set type 0
    }
    return
}

proc Scm::processFile {} {
    Scm::betaMessage
    return
}

proc Scm::processSelection {} {
    Scm::betaMessage
    return
}

# ===========================================================================
# 
# ×××× -------------------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 10/01/96 ok  1.0    Original Scheme mode.
# 03/18/99 ??  - 1.3  Updates.
# 11/30/00 cbu 1.4    Updated to use the lispMenu better, including
#                     Added   [Scm::colorizeScm]
#                     Added   [Scm::carriageReturn]
#                     Added   [Scm::electricRight]
#                     Revised [Scm::indentLine]
#                     Added   [Scm::correctIndentation]
#                     Revised [Scm::MarkFile]
#                     Added   [Scm::parseFuncs]
#                     Added   [Scm::checkKeywords]
#                     Added   [Scm::addKeywords]
#                     Added   [Scm::searchFunc]
# 12/01/00 cbu 2.0    New url prefs handling requires 7.4b21
# 09/26/01 cbu 2.1    Big cleanup, enabled by new 'functions.tcl' procs.
#                     New 'Scheme' menu.
# 10/31/01 cbu 2.1.1  Minor bug fixes.
# 02/24/06 cbu 2.2    Keywords lists defined in Scm namespace variables.
#                     Canonical Tcl formatting changes.
#                     Using [prefs::dialogs::setPaneLists] for preferences.
#                     Disabled unimplemented features (finally).
# 

# ===========================================================================
# 
# .