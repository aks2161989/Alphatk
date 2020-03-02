## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "setextMode.tcl"
 #                                          created: 10/01/1994 {09:51:15 pm}
 #                                      last update: 03/21/2006 {03:25:18 PM}
 # Description:
 # 
 # Setext file support
 #
 # Recognize and automatically mark 'setext'-encoded text files, like Tidbits.
 #  
 # Procs from the original by Tom Pollard -- [Setx::MarkFile].
 #  
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Author: Donavan Hall
 # E-mail: <hall@magnet.fsu.edu>
 #  
 # -------------------------------------------------------------------
 # 
 # Setext stands for 'S'tructure 'E'nhanced 'TEXT'.  It is a markup scheme
 # for plain text documents such as email messages and e-zines.  Setext's
 # primary goal is to provide a way of marking text that is visually
 # unobtrusive, so that if you don't have a special setext browser, like
 # EasyView, you can still read the text.  (Have you ever tried to make
 # sense of HTML source without your web browser?)
 # 
 # Alpha's Setx mode not only recognizes Setext marks, it also defines its
 # own menu that supports the mark-up of Setext files, and can render these
 # files as well -- turning Alpha into a full-fledged Setext viewer.
 # 
 # Setext grabbed a foothold in the Mac world with the online publication
 # TidBITS. Rudimentary setext browsers were built with HyperCard for
 # reading TidBITS. Setext seems to be merely a historical curiousity now.
 # 
 # (NOTE: Setext is easier to use with mono-spaced fonts like Monoco.)
 # 
 # This mode also allows the user to set additional preferences, including
 # comment characters, a magic character, keyword definitions and
 # colorizing.  If Alpha does not have a mode that users might want, Setx
 # could be adapted to serve as a surrogate until they have convinced
 # someone to write one for them.
 # 
 # -------------------------------------------------------------------
 #  
 # Copyright (c) 1994-2003  Tom Pollard, Craig Barton Upright, Donavan Hall
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of Setx mode ×××× #
# 

alpha::mode [list Setx Setext] 2.6b1 setextMode.tcl {*.stx *.etx} {
    setextMenu
} {
    # Script to execute at Alpha startup
    addMenu setextMenu "¥314" {Setx Text}
    # Insert a new option in the 'New Document' prompt.
    ;proc newSetextWindow {} {Setx::setextTemplates "" "newSetextWindow"}
    set {newDocTypes(New Setext Doc)} {newSetextWindow}
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of [S]tructure [E]nhanced [Text] (Setext) formatted files
} help {
    file "Setext Help"
}

proc setextMode.tcl {} {}

namespace eval Setx {
    
    variable PrefsInMenu {
	autoMark fancyMarks keypadFindsMark (-)
	navigateParagraphs usePairedComments
    }
    # This is used in setting some preferences below.
    variable PrefModes
    set PrefModes [mode::listAll]
    set PrefModes [concat "Setx" "-" [lremove ${Setx::PrefModes} "Setx"]]
    
    # This allows users to set keywords in prefs files.
    foreach item [list 1 2 3] {
	variable UserKeywords$item
	ensureset UserKeywords$item ""
    }
    unset item
}

# ===========================================================================
#
# ×××× Setting Setx mode variables ×××× #
#
# The commented explanations given above each of the following preferences
# are used by the "Help" button of the Mode Prefs dialog.
# 

# Remove obsolete preferences.
prefs::removeObsolete SetxmodeVars(renderOnOpen)

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  fillColumn                 {75}            Setx
newPref var  wordBreak              {[-\w.:$]+}  Setx
newPref var  lineWrap                   {1}             Setx
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Setx
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Setx

# ===========================================================================
#
# Flag preferences
#

# Turn this item on to automatically mark Setext files when first opened if
# there are no marks currently saved||Turn this item off to never
# automatically mark Setext files when they are first opened
newPref flag autoMark                   {1}     Setx    {Setx::postEval}
# To further highlight section marks, including the mark line above the
# section as well as below it, turn this item on.  This only works with the
# "Section Marks" key bindings||To only include the section mark below the
# section name, turn this item off
newPref flag fancyMarks                 {0}     Setx    {Setx::postEval}
# When the numeric keypad is NOT locked, 1 and 3 can search for either the
# next file mark or the next paragraph, placing the new insertion point
# in the center of the window.  Turn this item on to search for file
# marks||Turn this item off to search for the next paragraph rather than
# the next file mark
newPref flag keypadFindsMark            {0}     Setx    {Setx::postEval}
# The Setext menu includes several file navigation items.  Turn this item
# on to navigate paragraphs (blocks of text separated by empty lines)||Turn
# this item off to navigate commands (blocks of code, where the start of a
# command is indicated by a character in row 1)
newPref flag navigateParagraphs         {1}     Setx    {Setx::updatePreferences}
# Turn this item on to use the defined paired comment characters in
# 'Comment Line / Box / Paragraph' menu items||Turn this item off to use
# only a single comment character for the 'Comment Line / Box / Paragraph'
# menu items
newPref flag usePairedComments          {1}     Setx    \
  {Setx::setCommentCharacters}

# ===========================================================================
#
# Variable preferences
# 

# Everything from the Comment Character(s) to the end of the current line
# will be colorized according to the "Comment Color".  This should agree
# with the Prefix String below.
newPref var commentCharacter      {#}     Setx    {Setx::setCommentCharacters}
# Select the opening character(s) of a bracketed comment.
newPref var commentPair1          {/*}    Setx    {Setx::setCommentCharacters}
# Select the ending character(s) of a bracketed comment.  These cannot be
# the same as the opening characters.
newPref var commentPair2          {*/}    Setx    {Setx::setCommentCharacters}
# Indent Setx files similar to the procedure defined for this mode.  Note:
# the indentation procedures of some modes may not be defined, or may not
# work for other modes.
newPref var indentSetxFileAs      {Setx}  Setx    {} ${Setx::PrefModes}
# Setx allows for three levels of keywords.  Shorter lists can be entered
# here in the preferences.  For longer lists, see the Setext Help file for
# instructions on editing a SetxPrefs.tcl file.
newPref var addKeywords1          {Setx}  Setx    {Setx::colorizeSetx}
newPref var addKeywords2          {}      Setx    {Setx::colorizeSetx}
newPref var addKeywords3          {}      Setx    {Setx::colorizeSetx}
# Magic Characters will colorize any string which follows them, using the
# "symbol" color.  Only one Magic Character can be defined.
newPref var magicCharacter        {$}     Setx    {Setx::colorizeSetx}
# Mark Setx files similar to the procedure defined for this mode.  Note:
# the marking procedures of some modes may not be defined, or may not
# work for other modes.
newPref var markFileAs            {Setx}  Setx    {} ${Setx::PrefModes}
# Select a Prefix String for commenting lines.  This should agree with the
# Comment Character above, but also have a space after the character.
newPref var prefixString          {# }    Setx
# Command double-clicking will send the highlighted text to this search
# engine.
newPref url searchUrl1 {http://www.google.com/search?q=} Setx
# Command double-clicking while pressing the "option" key will send the
# highlighted text to this search engine.
newPref url searchUrl2 {http://www.go.com/Split?sv=IS&lk=noframes&qt=} Setx
# Command double-clicking while pressing the "control" key will send the
# highlighted text to this search engine.
newPref url searchUrl3 {http://search.metacrawler.com/crawler?general=} Setx
# Command double-clicking while pressing the "shift" key will send the
# highlighted text to this search engine.
newPref url searchUrl4 {http://northernlight.com/nlquery.fcg?si=&cb=0&qr=} Setx
# The "Setext Home Page" menu item will send this url to your browser.
newPref url SetextHomePage {http://www.tidbits.com/} Setx
# Additional characters to be colorized by the "Symbol Color".  The "-" and
# "=" symbols will always be included.
newPref var symbols               {@ %}   Setx    {Setx::colorizeSetx}

# ===========================================================================
#
# Color preferences
#

# The color of the defined comment character(s)
newPref color commentColor      {red}       Setx    {Setx::setCommentCharacters}
# The colors of user defined keywords.
newPref color keyword1Color     {magenta}   Setx    {Setx::colorizeSetx}
newPref color keyword2Color     {none}      Setx    {Setx::colorizeSetx}
newPref color keyword3Color     {none}      Setx    {Setx::colorizeSetx}
# Color of the user defined magic character.
newPref color magicColor        {blue}      Setx    {Setx::colorizeSetx}
# Strings are any words that appear between double quotes on the same line.
newPref color stringColor       {green}     Setx    {stringColorProc}
# This preference colorizes the = and - strings which indicate that the
# line above is a heading or subheading, and any other symbols defined by
# the user in "Symbols".
newPref color symbolColor       {blue}      Setx    {Setx::colorizeSetx}

# Call this now so that the rest can be adds (-a)
regModeKeywords -s $SetxmodeVars(stringColor) Setx {}

# ===========================================================================
# 
# Categories of all Setext preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "Setx" "Editing" [list \
  "electricBraces" \
  "fillColumn" \
  "indentOnReturn" \
  "indentSetxFileAs" \
  "lineWrap" \
  "wordBreak" \
  ]

# Navigation
prefs::dialogs::setPaneLists "Setx" "Navigation" [list \
  lunion "prefLists(Navigation)" \
  "autoMark" \
  "fancyMarks" \
  "keypadFindsMark" \
  "markFileAs" \
  "navigateParagraphs" \
  ]

# Comments
prefs::dialogs::setPaneLists "Setx" "Comments" [list \
  "commentCharacter" \
  "commentColor" \
  "commentPair1" \
  "commentPair2" \
  "prefixString" \
  "usePairedComments" \
  ]

# Keywords
prefs::dialogs::setPaneLists "Setx" "Keywords" [list \
  "addKeywords1" \
  "addKeywords2" \
  "addKeywords3" \
  "keyword1Color" \
  "keyword2Color" \
  "keyword3Color" \
  ]

# Colors
prefs::dialogs::setPaneLists "Setx" "Colors" [list \
  "magicCharacter" \
  "magicColor" \
  "stringColor" \
  "symbolColor" \
  "symbols" \
  ]

# Web Sites
prefs::dialogs::setPaneLists "Setx" "Web Sites" [list \
  "searchUrl1" \
  "searchUrl2" \
  "searchUrl3" \
  "searchUrl4" \
  "SetextHomePage" \
  ]

proc Setx::updatePreferences {prefName} {
    
    switch -- $prefName {
        default {
	    status::msg [set msg "Rebuilding the Setext menu É"]
	    menu::buildSome setextMenu
	    status::msg "$msg finished."
	}
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Setx::setCommentCharacters" --
 # 
 # Comment Character variables for Comment Line / Paragraph / Box menu items.
 # -------------------------------------------------------------------------
 ##

proc Setx::setCommentCharacters {{pref ""}} {
    
    variable commentCharacters
    
    global SetxmodeVars
    
    set cC  $SetxmodeVars(commentCharacter)
    
    if {$SetxmodeVars(usePairedComments)} {
	set cP1 $SetxmodeVars(commentPair1)
	set cP2 $SetxmodeVars(commentPair2)
	# Determine what the "middle comment character" is in a pair.
	if {([string length $cP1] == 2)} {
	    set mCC [string index $cP1 1]
	} else {
	    set mCC {*}
	}
	set commentCharacters(General)   "$mCC"
	set commentCharacters(Paragraph) [list "$cP1 " " $cP2" " $mCC " ]
	set commentCharacters(Box)       [list "$cP1" 2 "$cP2" 2 "$mCC" 3]
	
	regModeKeywords -a -e $cC -b $cP1 $cP2 \
	  -c $SetxmodeVars(commentColor) Setx {}
    } else {
	set commentCharacters(General)   "$cC"
	set commentCharacters(Paragraph) [list "$cC$cC " " $cC$cC" " $cC "]
	set commentCharacters(Box)       [list "$cC" 1 "$cC" 1 "$cC" 3]
	
	regModeKeywords -a -e $cC -b {} {} \
	  -c $SetxmodeVars(commentColor) Setx {}
    }
    if {[llength $pref]} {
	Setx::postEval
	refresh
    }
    return
}

# Call this now.
Setx::setCommentCharacters

## 
 # -------------------------------------------------------------------------
 # 
 # "Setx::colorizeSetx" --
 # 
 # Define the colours and keywords used in Setx mode.  Also defines the
 # 'Setxcmds' variable, used in electric completion routines as well as the
 # 'list keywords' menu item.
 # 
 # Could also be called in a SetxPrefs.tcl file
 # 
 # -------------------------------------------------------------------------
 ##

# Ensure that these lists exist:

proc Setx::colorizeSetx {{pref ""}} {
    
    global SetxmodeVars Setxcmds
    
    variable UserKeywords1
    variable UserKeywords2
    variable UserKeywords3

    set Setxcmds [lsort -unique [concat $SetxmodeVars(addKeywords1) \
      $SetxmodeVars(addKeywords2) $SetxmodeVars(addKeywords3) \
      $UserKeywords1 $UserKeywords2 $UserKeywords3]]
    
    # Keywords 1
    regModeKeywords -a -k $SetxmodeVars(keyword1Color)  Setx \
      [concat $SetxmodeVars(addKeywords1) $UserKeywords1]
    # Keywords 2
    regModeKeywords -a -k $SetxmodeVars(keyword2Color)  Setx \
      [concat $SetxmodeVars(addKeywords2) $UserKeywords2]
    # Keywords 3
    regModeKeywords -a -k $SetxmodeVars(keyword3Color)  Setx \
      [concat $SetxmodeVars(addKeywords3) $UserKeywords3]
    # Symbols, Magic Character
    regModeKeywords -a -m $SetxmodeVars(magicCharacter) \
      -k $SetxmodeVars(magicColor)  Setx {}
    regModeKeywords -a -i "=" -i "-" \
      -I $SetxmodeVars(symbolColor) -k $SetxmodeVars(symbolColor)  Setx \
      $SetxmodeVars(symbols)
    
    if {[llength $pref]} {
	refresh
    }
    return
}

# Call this now.
Setx::colorizeSetx

# Setting the order of precedence for completions.
set completions(Setx) {completion::cmd completion::electric completion::word}

# ===========================================================================
# 
# ×××× Key Bindings, Electrics ×××× #
# 

# Known bug: Key-bindings from other global menus might conflict with those
# defined in the Setext menu.  This will help ensure that this doesn't happen.

Bind '-'     <z>    {Setx::setextMark -}            Setx
Bind '='     <z>    {Setx::setextMark =}            Setx

Bind    up   <sz>   {Setx::searchFuncs 0 0 0}       Setx
Bind  left   <sz>   {Setx::searchFuncs 0 0 1}       Setx
Bind  down   <sz>   {Setx::searchFuncs 1 0 0}       Setx
Bind right   <sz>   {Setx::searchFuncs 1 0 1}       Setx

Bind 'i'     <cz>   {paragraph::reformat}           Setx

# Bind modifier keys for f6 command double click.

Bind f6      <c>    {cmdDoubleClick -1 -1 0 0 0}    Setx
Bind f6      <s>    {cmdDoubleClick -1 -1 1 0 0}    Setx
Bind f6      <o>    {cmdDoubleClick -1 -1 0 1 0}    Setx
Bind f6      <z>    {cmdDoubleClick -1 -1 0 0 1}    Setx

Bind f6     <cs>    {cmdDoubleClick -1 -1 1 0 0}    Setx
Bind f6     <co>    {cmdDoubleClick -1 -1 0 1 0}    Setx
Bind f6     <cz>    {cmdDoubleClick -1 -1 0 0 1}    Setx

# Bind help keys for www search.

Bind help    <c>    {Setx::wwwSearch "" 1}          Setx
Bind help   <cs>    {Setx::wwwSearch "" 2}          Setx
Bind help   <co>    {Setx::wwwSearch "" 3}          Setx
Bind help   <cz>    {Setx::wwwSearch "" 4}          Setx

Bind f8      <c>    {Setx::wwwSearch "" 1}          Setx
Bind f8     <cs>    {Setx::wwwSearch "" 2}          Setx
Bind f8     <co>    {Setx::wwwSearch "" 3}          Setx
Bind f8     <cz>    {Setx::wwwSearch "" 4}          Setx

proc Setx::electricLeft {} {
    
    global SetxmodeVars
    
    if {[literalChar]} {
	typeText "\{"
	return
    }
    
    set m $SetxmodeVars(indentSetxFileAs)
    if {($m != "Setx") && ![catch {${m}::electricLeft}]} {
	return
    }
    
    # A default routine ...
    set pat {\}[ \t\r\n]*(else(if)?)[ \t\r\n]*$}
    set pos [getPos]
    if {![string length [set result [findPatJustBefore "\}" $pat $pos word]]]} {
	insertText "\{"
    } else {
	# If we have an if/else(if)/else ...
	switch -- $word {
	    "else" {
		deleteText [lindex $result 0] $pos
		elec::Insertion "\} $word \{\r\t¥¥\r\}\r¥¥"
	    }
	    "elseif" {
		deleteText [lindex $result 0] $pos
		elec::Insertion "\} $word \{¥¥\} \{\r\t¥¥\r\}\r¥¥"
	    }
	}
    }
    return
}

proc Setx::electricRight {{char "\}"}} {
    
    global SetxmodeVars
    
    if {[literalChar]} {
	typeText $char
	return
    }
    
    set m $SetxmodeVars(indentSetxFileAs)
    if {($m != "Setx") && ![catch {${m}::electricRight}]} {
	return
    }
    
    # A default routine ...
    set pos [getPos]
    typeText $char
    if {![regexp {[^ \t]} [getText [lineStart $pos] $pos]]} {
	set pos [lineStart $pos]
	createTMark temp [getPos]
	catch {bind::IndentLine}
	gotoTMark temp ; removeTMark temp
	bind::CarriageReturn
    }
    if {[catch {blink [matchIt $char [pos::prevChar $pos]]}]} {
	beep
	status::msg "No matching $char !!"
    }
    return
}

proc Setx::searchFuncs {direction args} {
    
    global SetxmodeVars
    
    if {$SetxmodeVars(keypadFindsMark)} {
	findViaFileMarks $direction ; centerRedraw
	status::msg [getText [getPos] [pos::lineEnd [getPos]]]
    } else {
	if {![llength $args]} {
	    set args [list 0 2]
	}
	if {$direction} {
	    eval nextWhat $args
	} else {
	    eval prevWhat $args
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Indentation ×××× #
# 
# Note:  Setx::correctIndentation provides a standard routine for any
# programming language that uses {} or () or \ to determine different
# amounts of indentation.
# 

proc Setx::indentLine {args} {

    global SetxmodeVars positionAfterIndentation
    
    win::parseArgs w

    set m $SetxmodeVars(indentSetxFileAs)
    if {($m eq "Setx") || [catch {${m}::indentLine}]} {
	# Get details of current line.
	set pos      [getPos -w $w]
	set pos0     [pos::lineStart -w $w [getPos -w $w]]
	set txt      [getText -w $w $pos0 [pos::nextLineStart -w $w $pos0]]
	regexp {^[ \t]*} $txt white
	set posNext1 [pos::math -w $w $pos0 + [string length $white]]
	set posNext2 [pos::math -w $w $posNext1 + 1]
	if {[pos::compare -w $w $posNext2 > [maxPos -w $w]]} {
	    set posNext2 [maxPos -w $w]
	}
	# Determine the correct level of indentation for this line, given the
	# next character.
	set lwhite [Setx::correctIndentation -w $w $pos \
	  [getText -w $w $posNext1 $posNext2]]
	set lwhite [text::indentOf $lwhite]
	if {($white != $lwhite)} {
	    replaceText -w $w $pos0 $posNext1 $lwhite
	}
    }
    # Where do we go after indenting?
    ensureset positionAfterIndentation 1
    if {$positionAfterIndentation && [string length [string trim $txt]]} {
	# Keep relative position.
	set diff [pos::diff -w $w $pos0 $posNext1]
	set pos1 [pos::math -w $w $pos + [string length $lwhite] - $diff]
	if {[pos::compare -w $w $pos1 < $pos0]} {
	    goto -w $w $pos0
	} else {
	    goto -w $w $pos1
	}
    } else {
	goto -w $w [pos::math -w $w $pos0 + [string length $lwhite]]
    }
    return
}

proc Setx::correctIndentation {args} {
    
    global SetxmodeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    set m $SetxmodeVars(indentSetxFileAs)
    if {($m ne "Setx")} {
	if {[catch [list ::${m}::correctIndentation -w $w $pos $next] result]} {
	    error "Cancelled -- $result"
	} else {
	    return $result
	}
    }
    # Continue, since we're either indenting like Setx or this failed.
    set posBeg    [lineStart $pos]
    # Get information about this line, previous line ...
    set thisLine  [Setx::findLine $posBeg 1]
    set prevLine1 [Setx::findLine [pos::prevLineEnd $pos] 0]
    set prevLine2 [Setx::findLine [pos::prevLineEnd [lindex $prevLine1 0]] 0]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line and use electric braces ...
    set test1 [pos::compare [lindex $prevLine1 0] != $posBeg]
    set test2 [pos::compare [lindex $thisLine  0] == $posBeg]
    set test3 0 ; # electricBraces feature doesn't exist any more.
                  # [lcontains mode::features(Setx) electricBraces]
    if {$test1 && $test3} {
	set pL1 [string trim [lindex $prevLine1 2]]
	# Indent if the last line did not terminate the command.
	if {([string trimright $pL1 "\\"] != $pL1)} {
	    incr lwhite [expr {$indentationAmount/2}]
	}
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {([pos::compare [lindex $prevLine2 0] != [lindex $prevLine1 0]])} {
	    set pL2 [string trim [lindex $prevLine2 2]]
	    if {([string trimright $pL2 "\\"] != $pL2)} {
		incr lwhite [expr {-$indentationAmount/2}]
	    }
	}
	# Find out if there are any unbalanced {,} in the last line.
	regsub -all {[^ \{\}\"\*\/\\]} $pL1 { } line
	# Remove all literals.
	regsub -all {\\\{|\\\}|\\\"|\\\*|\\\/} $line { } line
	regsub -all {\\} $line { } line
	# Remove everything surrounded by quotes.
	regsub -all {\"[^\"]+\"} $line { } line
	regsub -all {\"} $line { } line
	# Remove everything surrounded by bracketed comments.
	regsub -all {/\*[^\*/]+\*/} $line { } line
	# Now turn all braces into 1's and -1's
	regsub -all {\{} $line { 1 }  line
	regsub -all {\}} $line { -1 } line
	# This list should now only contain 1's and -1's.
	foreach i $line {
	    if {$i == "1" || $i == "-1"} {
		incr lwhite [expr {$i * $indentationAmount}]
	    }
	}
	# Did the last line start with a lone \} ?  If so, we want to keep
	# the indent, and not make call it an unbalanced line.
	if {[regexp {^[\t ]*\}} $pL1]} {
	    incr lwhite $indentationAmount
	}
    }
    # If we have a current line ...
    if {$test2 && $test3} {
	# Reduce the indent if the first non-whitespace character of this
	# line is \}.
	set tL [lindex $thisLine 2]
	if {($next == "\}") || [regexp {^[\t ]*\}} $tL]} {
	    incr lwhite -$indentationAmount
	}
    }
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Setx::findLine" --
 # 
 # Find the next/prev line of text relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text
 # of the line.  If the search for the next/prev line of text fails, return
 # an indentation level of 0.
 # -------------------------------------------------------------------------
 ##

proc Setx::findLine {pos {direction 1}} {
    
    set pat  {^[\t ]*[^\t\r\n ]}
    set pos0 [pos::prevLineEnd [pos::lineStart $pos]]
    if {[pos::compare $pos0 < [minPos]]} {
	set pos0 [minPos]
    }
    set lwhite 0
    if {[llength [set pp [search -n -s -f $direction -r 1 -- $pat $pos]]]} {
	set pos0 [lindex $pp 0]
	set lwhite [lindex [pos::toRowCol [pos::prevChar [lindex $pp 1] 1]] 1]
    }
    set pos1 [pos::lineEnd $pos0]
    return [list $pos0 $lwhite [getText $pos0 $pos1]]
}

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
# 
# Send the highlighted text to the defined search engine.
# 

proc Setx::DblClick {from to shift option control} {
    
    global SetxmodeVars
    
    selectText $from $to
    set command [getSelect]
    
    # Any modifiers pressed?
    if {$option && [llength $SetxmodeVars(searchUrl2)]} {
	Setx::wwwSearch $command $SetxmodeVars(searchUrl2)
    } elseif {$control && [llength $SetxmodeVars(searchUrl3)]} {
	Setx::wwwSearch $command $SetxmodeVars(searchUrl3)
    } elseif {$shift && [llength $SetxmodeVars(searchUrl4)]} {
	Setx::wwwSearch $command $SetxmodeVars(searchUrl4)
    } elseif {[llength $SetxmodeVars(searchUrl1)]} {
	Setx::wwwSearch $command $SetxmodeVars(searchUrl1)
    } else {
	status::msg "The search url preference for this modifier\
	  has not been set."
    }
    return
}

proc Setx::wwwSearch {{command ""} {url ""}} {
    
    global SetxmodeVars
    
    if {![string length $url]} {
	set url $SetxmodeVars(searchUrl1)
    } elseif {[regexp {^[0-9]$} $url]} {
	set url $SetxmodeVars(searchUrl${url})
    }
    if {![string length $command]} {
	regsub {^http://}           $url     {} urlName
	regsub {^www.}              $urlName {} urlName
	regsub {/+.*.$}             $urlName {} urlName
	regsub {^search\.}          $urlName {} urlName
	regsub {\.(com|org|net)$}   $urlName {} urlName
	if {[catch {getSelect} txt]} {
	    set txt ""
	}
	set command [prompt "'$urlName' search for ... " $txt]
    }
    regsub -all {[ ]} $command {+} commandPlus
    set commandPlus %22$commandPlus%22
    status::msg "'$command' sent to $url"
    url::execute $url$commandPlus
    return
}

# ===========================================================================
# 
# ×××× Setext Marks ×××× #
# 
# author:  Tom Pollard
# 
# Any two lines that look like this:
# 
# Any string of words
# ===================
# 
# will be marked as a Chapter heading.  Any two lines that look like this:
# 
# Any other string of words
# -------------------------
# 
# will be marked as a Section heading.  That's all there is to it.
# 
# Changes made by cbu:
# 
#  -- Section marks indented by two spaces, not four.
#  -- Comment character, spaces stripped from the beginning of any mark name.
#  -- Both ~ and _ will also be recognized as chapter markers.
#  

proc Setx::MarkFile {args} {
    
    global SetxmodeVars
    
    win::parseArgs w

    removeAllMarks
    
    # Do we have an alternative marking scheme defined ?
    set m $SetxmodeVars(markFileAs)
    if {($m != "Setx")} {
	if {[catch {${m}::MarkFile -w $w}]} {
	    set msg "'$m' mode's mark file procedure failed."
	    status::msg $msg
	    return 0
	}
    } else {
	# No, so mark it as a Setext window.
	foreach {count1 count2} [Setx::markAsSetext -w $w 0] {}
	if {!$count1 && !$count2} {
	    # Hmm ... no marks.  Try the standard 'Text' mark, in case this
	    # is actually a rendered window.
	    loadAMode Text
	    Text::MarkFile -w $w
	}
    }
    return 1
}

proc Setx::markAsSetext {args} {
    
    global SetxmodeVars

    win::parseArgs w {quietly 0}

    removeAllMarks
    if {!$quietly} {
	status::msg "Marking Window É"
    }
    set cC $SetxmodeVars(commentCharacter)
    
    set pat {^(-+|=+|~+|_+)$}
    set end [pos::max -w $w]
    set pos [pos::min -w $w]
    set count1 0
    set count2 0
    while {1} {
	set pp [search -w $w -n -s -f 1 -r 1 -m 0 -i 1 -- $pat $pos]
	if {![llength $pp]} {
	    break
	}
	set pos0   [lindex $pp 0]
	set pos1   [lindex $pp 1]
	set pos2   [pos::prevLineStart -w $w $pos0]
	set pos3   [pos::prevLineStart -w $w $pos2]
	set pos4   [pos::nextLineStart -w $w $pos2]
	set marker [string trimright [getText -w $w $pos0 $pos1]]
	set mark   [string trimright [getText -w $w $pos2 $pos4]]
	if {([string length $mark] == [string length $marker])} {
	    # Strip any leading comment characters, spaces from the mark
	    set mark [string trimleft $mark "$cC "]
	    if {[regexp {^\-+$} $marker]} {
		set mark "   $mark"
		incr count2
	    } else {
		incr count1
	    }
	    set mark [markTrim $mark]
	    while {[lcontains marks $mark]} {append mark " "}
	    lappend marks $mark
	    setNamedMark -w $w $mark $pos3 $pos2 $pos2
	}
	set pos [pos::nextLineStart -w $w [lindex $pp 1]]
    }
    if {!$count1 && !$count2} {
	set msg ""
    } else {
	set msg "'[win::Tail $w]' contains $count1 chapters, $count2 sections."
    }
    if {!$quietly} {
	status::msg $msg
    }
    return [list $count1 $count2]
}

proc Setx::setextMark {args} {
    
    global SetxmodeVars
    
    win::parseArgs w symbol
    
    set pos0 [getPos -w $w]
    goto -w $w [set pos1 [pos::lineStart -w $w $pos0]]
    endLineSelect -w $w
    
    # First convert all tabs to spaces.
    tabsToSpaces -w $w
    goto -w $w $pos1
    endLineSelect -w $w
    
    # Now remove any stray spaces from the end of the current line.
    set txt1 [string trimright [getSelect -w $w]]
    replaceText -w $w $pos1 [selEnd -w $w] $txt1
    goto -w $w $pos1
    endLineSelect -w $w
    
    # Now substitute the symbol for any character, insert a new line below
    # the current one, removing any old symbol line if necessary.
    regsub -all {.} [getSelect -w $w] $symbol symbolLine
    set pos2 [pos::nextLineStart -w $w $pos1]
    set pos3 [pos::nextLineStart -w $w $pos2]
    set txt2 [string trim [getText -w $w $pos2 $pos3]]
    if {[regexp {^(\-+|=+)$} $txt2]} {
	replaceText -w $w $pos2 $pos3 "${symbolLine}\r"
    } else {
	goto -w $w [selEnd -w $w]
	insertText -w $w "\r${symbolLine}"
    }
    goto -w $w $pos0
    # Do we want fancy marks?
    if {$SetxmodeVars(fancyMarks)} {
	set pos4 [pos::prevLineStart -w $w $pos1]
	set pos5 [pos::prevLineEnd -w $w   $pos1]
	if {[regexp {^(\-+|=+)$} [string trim [getText -w $w $pos4 $pos5]]]} {
	    replaceText -w $w $pos4 $pos5 "${symbolLine}"
	} else {
	    replaceText -w $w $pos1 $pos1 "${symbolLine}\r"
	}
    }
    # Now remark the file if desired.
    if {($w ne [win::Current])} {
        return
    } elseif {($SetxmodeVars(markFileAs) == "Setx") \
      && $SetxmodeVars(autoMark)} {
	markFile
    }
    return
}

# ===========================================================================
# 
# ×××× ------------ ×××× #
# 
# ×××× Setext Menu ×××× #
# 

# Define the Setext Menu, define a build proc for the Setext menu.

proc setextMenu {} {}

menu::buildProc setextMenu Setx::buildMenu Setx::postEval

proc Setx::buildMenu {{pref ""}} {
    
    global SetxmodeVars setextMenu
    
    variable Template
    variable PrefsInMenu
    
    set subMenus   {Templates Marks Text (-) Help Options Keywords}
    set menuProc   "Setx::menuProc -M Setx"
    set buildMenus ""
    # Create the Setext Templates menu.
    set TemplatesList "newSetextWindowÉ"
    set TemplateItems {Header Footer Template1 Template2 Template3}
    foreach item $TemplateItems {ensureset Template($item) ""}
    foreach item [array names Template] {
	ensureset Template($item) ""
	if {![lcontains TemplateItems $item]} {
	    lappend TemplateItems $item
	}
    }
    foreach process {insert edit restore} {
	lappend TemplatesList "(-)"
	foreach item $TemplateItems {lappend TemplatesList ${process}${item}}
    }
    # Create the Setext Marks menu.
    set MarksList [list                         \
      /=<BchapterMark                           \
      /-<BsectionMark                           \
      (-)                                       \
      <E<S/M<U<BmarkAsSetext                    \
      <S<O/M<U<BmarkFileAsÉ                     ]
    # Create the Setext Text menu.
    set TextList [list                          \
      /B<U<Bbold                                \
      /I<U<Bitalic                              \
      /U<U<Bunderline                           \
      /H<U<BhotText                             \
      <S/Q<U<Bquote                             \
      <S<O/Q<U<Bunquote                         \
      (-)                                       \
      /I<O<U<BfillParagraph                     ]
    # Create the Setext Help menu.
    set HelpList [list                          \
      setextHomePage                            \
      (-)                                       \
      /t<OwwwSearch1É                           \
      /t<IwwwSearch2É                           \
      /t<BwwwSearch3É                           \
      /t<UwwwSearch4É                           \
      (-)                                       \
      /t<BsetextModeHelp                        ]
    # Create the Setext Options menu.
    set OptionsList $PrefsInMenu
    lappend OptionsList (-) setCommentCharacterÉ moreSetextPrefsÉ
    # Create the Setext Keywords menu.
    set KeywordsList {listKeywords checkKeywordsÉ}
    foreach process {add remove} {
	lappend KeywordsList (-)
	foreach category {1 2 3} {
	    lappend KeywordsList ${process}Keywords${category}É
	}
    }
    # Add all of the subMenus.
    foreach subMenu $subMenus {
	set n setext$subMenu
	set p Setx::$n
	if {($subMenu == "(-)")} {
	    lappend menuList (-)
	} elseif {[lcontains buildMenus $n]} {
	    lappend menuList "Menu -n $n {}"
	} elseif {[info exists ${subMenu}List]} {
	    lappend menuList "Menu -n $n -p $p \"[set ${subMenu}List]\""
	}
    }
    if {$SetxmodeVars(navigateParagraphs)} {
	set which "Paragraph"
    } else {
	set which "Function"
    }
    # Add navigation items.
    lappend menuList                            \
      (-)                                       \
      /N<U<Bnext${which}                        \
      /P<U<Bprev${which}                        \
      /S<U<Bselect${which}                      \
      /I<O<Breformat${which}                    \
      (-)                                       \
      <E<S<U<B/'newComment                      \
      <S<O<U<B/'commentTemplateÉ                \
      (-)                                       \
      /R<U<BrenderWindow                        \
      setextToHtml                              \
      textToSetext
    # Register openWindows hook
    set rOWH "requireOpenWindowsHook"
    set MainMenuItems [list \
      setextText setextMarks                    \
      next${which} prev${which}                 \
      select${which} reformat${which}           \
      newComment commentTemplateÉ               \
      renderWindow setextToHtml textToSetext    ]
    foreach item $MainMenuItems {
	hook::register $rOWH [list $setextMenu $item] 1
    }
    foreach item $TemplateItems {
	hook::register $rOWH [list setextTemplates insert${item}] 1
    }
    hook::register     $rOWH [list setextOptions moreSetextPrefsÉ] 1
    
    return [list build $menuList $menuProc $buildMenus $setextMenu]
}

proc Setx::postEval {args} {
    
    global PREFS SetxmodeVars
    
    variable Template
    variable PrefsInMenu
    
    foreach item [array names Template] {
	if {[file exists [file join $PREFS "Setx-${item}.etx"]]} {
	    set onOrOff on
	} else {
	    set onOrOff off
	}
	enableMenuItem "setextTemplates" "restore${item}" $onOrOff
    }
    foreach item {1 2 3} {
	if {[llength $SetxmodeVars(addKeywords${item})]} {
	    set onOrOff on
	} else {
	    set onOrOff off
	}
	enableMenuItem "setextKeywords" "removeKeywords${item}É" $onOrOff
    }
    foreach pref [set PrefsInMenu] {
	if {($pref == "(-)")} {
	    continue
	} elseif {![info exists SetxmodeVars($pref)]} {
	    enableMenuItem "setextOptions" $pref off
	} else {
	    markMenuItem "setextOptions" $pref $SetxmodeVars($pref) Ã
	}
    }
}

# Build the menu now.
menu::buildSome "setextMenu"

# ===========================================================================
# 
# ×××× Setext Menu Procs ×××× #
# 

proc Setx::menuProc {menuName itemName} {
    
    global SetxmodeVars
    
    if {[regexp {^([a-z]+)(Paragraph|Function)$} $itemName allofit which]} {
	${which}What
	return
    }
    switch $itemName {
	"newComment" {comment::newComment $SetxmodeVars(navigateParagraphs)}
	"commentTemplate" {comment::commentTemplate}
	"setextToHtml" {
	    # Use either the current selection or the entire contents of the
	    # current window to create a new window, and apply the "Setext 2
	    # Html" filter.
	    if {![Setx::isSetextFormat 0]} {
		status::msg "Cancelled -- this does not seem to be\
		  a Setext window."
		return -code return
	    }
	    alpha::package require filtersMenu 1.4
	    set name "[win::CurrentTail].html"
	    if {[isSelection]} {
		set text [getSelect]
	    } else {
		set text [getText [minPos] [maxPos]]
	    }
	    new -n $name -text $text -m HTML
	    flt::filterThisFile Setext2Html
	    if {![catch {html::NewwithContent}]} {
		goto [minPos]
	    }
	}
	default {$itemName}
    }
    return
}

proc Setx::setextTemplates {menuName itemName args} {
    
    global PREFS
    
    variable Template
    variable FirstNewWindow
    
    ensureset FirstNewWindow 0
    
    if {($itemName == "newSetextWindow")} {
	append text [Setx::setextTemplates "" insertHeader 0]
	append text [Setx::setextTemplates "" insertFooter 0]
	new -n [prompt "New Setext Window Name :" ""] -m Setx
	elec::Insertion $text
	setWinInfo dirty 0
	if {!$FirstNewWindow} {
	    alertnote "Use the tab key to navigate ¥ template stops."
	    set FirstNewWindow 1
	    prefs::modified FirstNewWindow
	}
	return
    } else {
	set pat {^(insert|edit|restore)([a-zA-Z0-9]+)$}
	regexp  $pat $itemName allofit process which
	set f   [file join $PREFS Setx-${which}.etx]
    }
    switch $process {
	"insert" {
	    if {[file isfile $f]} {
		set text [file::readAll $f]
	    } else {
		set text $Template($which)
	    }
	    if {![string length $text]} {
		set    question "The '$which' template is empty.\r"
		append question "Would you like to edit it?"
		if {([askyesno $question] == "yes")} {
		    Setx::setextTemplates "" edit${which}
		    return
		} else {
		    status::msg "Cancelled -- the '$which' template is empty."
		}
	    } elseif {($args == "0")} {
		return $text
	    } else {
		switch $which {
		    "Header"        {goto [minPos]}
		    "Footer"        {goto [maxPos]}
		}
		if {[isSelection]} {
		    deleteSelection
		}
		elec::Insertion $text
	    }
	}
	"edit" {
	    if {[catch {file::openQuietly $f}]} {
		close [open $f "w"] ; edit -c $f
		insertText $Template($which) ; goto [minPos]
		save
		enableMenuItem "setextTemplates" "restore${which}" on
	    }
	    set     msg "Edit this '$which' template, "
	    append  msg "which has been saved in your prefs folder."
	    status::msg $msg
	}
	"restore" {
	    if {![catch {bringToFront [file tail $f]}]} {
		setWinInfo dirty 0 ; killWindow
	    }
	    catch {file delete [file join $f]}
	    status::msg "The Setext ${which} template has been restored."
	    enableMenuItem "setextTemplates" "restore${which}" off
	}
    }
    return
}
    
proc Setx::setextMarks {menuName itemName args} {
    
    global SetxmodeVars mode
    
    switch $itemName {
	"chapterMark"           {Setx::setextMark "="}
	"sectionMark"           {Setx::setextMark "-"}
	"markAsSetext"          {
	    set SetxmodeVars(markFileAs) Setx
	    prefs::modified SetxmodeVars(markFileAs)
	    markFile
	}
	"markFileAs"            {
	    set p "Mark Current Window as É"
	    set L $SetxmodeVars(markFileAs)
	    set m [listpick -p $p -L [list $L] [mode::listAll]]
	    set oldMarkAs $SetxmodeVars(markFileAs)
	    set SetxmodeVars(markFileAs) $m
	    prefs::modified SetxmodeVars(markFileAs)
	    # This calls Setx::MarkFile.  Hope that's intentional
	    if {[catch {MarkFile}]} {
		set SetxmodeVars($itemName) $oldMarkAs
	    }
	}
    }
    return
}

proc Setx::setextText {menuName itemName args} {
    
    switch $itemName {
	"bold" {
	    eval selectText [text::surroundingWord]
	    set txt [getSelect]
	    if {[elec::Wrap "**" "**¥¥"]} {
		set msg "'$txt' has been set in bold."
		forwardWord ; backwardWord
	    } else {
		set msg "Enter text to be set in bold."
	    }
	}
	"italic" {
	    eval selectText [text::surroundingWord]
	    set txt [getSelect]
	    if {[regexp "\t| " $txt]} {
		set    msg "For some unknown reason, "
		append msg "only single words can be set in italic."
	    } elseif {[elec::Wrap "~" "~¥¥"]} {
		set    msg "'$txt' has been set in italic."
		forwardWord ; backwardWord
	    } else {
		set    msg "Enter text to be set in italic."
	    }
	}
	"underline" -
	"hotText" {
	    eval selectText [text::surroundingWord]
	    if {($itemName == "hotText")} {
		# 'Hot Text' is similar to underlined, but doesn't include
		# the first '_'
		set openTag ""
		set which   "'hot text'"
	    } else {
		set openTag "_"
		set which   "underlined"
	    }
	    if {![isSelection]} {
		elec::Insertion "${openTag}¥¥_¥¥"
		set msg "Enter text to be $which."
	    } else {
		# There is a selection, so replace all tab, space, and
		# underscore strings with underscores, adding more at the
		# end (always) and the beginning (if necessary) of the
		# selected string.
		set pos [getPos]
		regsub -all {[_\t ]+}  [getSelect]  "_"         txt
		# Special case for endings of lines.
		regsub -all {_?([\r\n]+)}  $txt    "_\\1"       txt
		# Special case for beginnings of lines.
		regsub -all {(\s+)_?} $txt  "\\1${openTag}"     txt
		# Add any opening tag (for underline)
		set txt ${openTag}[string trim $txt "_"]
		# Special case for selections that go to the end of a line.
		if {![regexp {[\r\n]+$} $txt]} {
		    append txt "_"
		}
		# Now we finally replace the text.
		replaceText [getPos] [selEnd] $txt
		goto [pos::math $pos + [string length $txt]]
		set msg "Selection is now $which."
	    }
	}
	"quote" -
	"unquote" {
	    # Remember the original positions
	    set posBeg [getPos]
	    set posEnd [selEnd]
	    
	    # Make sure that we have a selection that extends to the end of
	    # a line.
	    if {![isSelection]} {
		paragraph::select
	    } elseif {[pos::compare [selEnd] != [lineStart [selEnd]]]} {
		endLineSelect ; forwardCharSelect
	    }
	    beginningLineSelect
	    set pos0 [getPos]
	    set pos1 [pos::prevChar [selEnd]]
	    set txt  [getText $pos0 $pos1]
	    regsub -all " *\t" $txt "    " block
	    
	    # Get the leading indent for the first line of the selection.
	    set front [eval getText \
	      [search -s -n -f 1 -r 1 -- {^[ \t]*} [getPos]]]
	    regsub -all " *\t" $front "    " front
	    # Special case for empty lines separating paragraphs.
	    regsub -all "(\[\r\n\]+\[\t \]*\[\r\n\]+)" $block \
	      "\r${front} \r" block
	    if {($itemName == "quote")} {
		# Add 'front' plus the '> ' prefix at the beginning of each
		# line.
		regsub -all "(^|\[\r\n\]+)${front}" $block "\\1${front}> " block
	    } else {
		# Remove 'front' plus the '> ' prefix from the beginning of
		# each line.
		regsub -all "(^|\[\r\n\]+)${front}> " $block "\\1${front}" block
	    }
	    replaceText $pos0 $pos1 $block
	    # Now try to go to the original position, or re-highlight.  (If
	    # the original position was in the middle of the block, this
	    # will only be an approximation.)
	    if {[pos::compare $posBeg == $posEnd]} {
		goto $posBeg
	    } else {
		set length1 [string length $txt]
		set length2 [string length $block]
		set posEnd  [pos::math $posEnd - $length1 + $length2]
		selectText $posBeg $posEnd
	    }
	    
	}
	"fillParagraph" {
	    variable commentCharacters
	    
	    set posBeg  [paragraph::start  [getPos]]
	    set posEnd  [paragraph::finish [selEnd]]
	    # Get the leading whitespace of the first line, and get the block.
	    set front   [eval getText \
	      [search -n -s -f 1 -r 1 -- {^[ \t]*} $posBeg]]
	    set first   [lookAt [pos::math $posBeg + [string length $front]]]
	    set posNext [nextLineStart $posBeg]
	    set line1   [string trim \
	      [getText $posBeg  [nextLineStart $posBeg]]]
	    set line2   [string trim \
	      [getText $posNext [nextLineStart $posNext]]]
	    set length1 [string length $line1]
	    set length2 [string length $line1]
	    if {($first == ">")} {
		# Special case for quoted paragraphs.
		set oldCC commentCharacters(General)
		set commentCharacters(General) "> "
		# Takes care of bug when 'pos' is the same as 'posBeg'
		if {[pos::compare $posBeg == [pos::lineStart [getPos]]]} {
		    goto [pos::lineEnd [getPos]]
		} else {
		    goto [pos::lineStart [getPos]]
		}
		paragraph::fillOne 0
		set commentCharacters(General) $oldCC
	    } elseif {($first == "<")} {
		# Special case for urls.
		goto [set pos $posBeg]
		while {1} {
		    set pos0 [lineStart [getPos]]
		    set pos1 [nextLineStart [getPos]]
		    set txt  "[string trim [getText $pos0 $pos1]]\r"
		    replaceText $pos0 $pos1 $txt
		    goto [set pos [nextLineStart $pos0]]
		    if {[pos::compare $pos > $posEnd]} {
			break
		    }
		}
	    } elseif {![regexp {^(-+|=+)$} $line2] || $length1 != $length2} {
		# We know that this is not a chapter/section heading.
		regsub -all " *\t" $front "    " front
		regsub -all "\[ \t\r\n\]+" \
		  [string trim [getText $posBeg $posEnd]] " " block
		# Turn single spaces at end of sentences into double.
		set pat {(([^.][a-z]|[^a-zA-Z@]|\\@)[.?!]("|'|'')?([])])?) }
		regsub -all $pat $block {\1  } block
		# Break and indent the block.
		set fc [expr {66 - [string length $front]}]
		set block "\r[string trimright [breakIntoLines $block $fc 0]]"
		regsub -all " ?\r" $block "\r  " block
		replaceText $posBeg $posEnd \
		  "${front}[string range $block 3 end]\r"
	    }
	    goto $posBeg ; goto [paragraph::next 1]
	}
	default         {$itemName}
    }
    if {[info exists msg]} {
	status::msg $msg
    }
    return
}
    
proc Setx::setextHelp {menuName itemName args} {
    
    global SetxmodeVars
    
    if {[regexp {HomePage} $itemName]} {
	url::execute $SetxmodeVars(SetextHomePage)
    } elseif {($itemName == "setextModeHelp")} {
	package::helpWindow "Setx"
    } else {
	regsub {wwwSearch} $itemName {} which
	Setx::wwwSearch "" $which
    }
    return
}

proc Setx::setextOptions {menuName itemName args} {
    
    global SetxmodeVars mode
    
    if {[getModifiers]} {
	# Open an alertnote with information about the preference.
	if {($itemName == "setCommentCharacter")} {
	    set helpText "Use this menu item to set\
	      the comment character for Setx mode"
	    set msg      "The comment character for Setx mode\
	      is currently '$SetxmodeVars(commentCharacter)'"
	} elseif {($itemName == "moreSetextPrefs")} {
	    set helpText "Use this menu item to open\
	      the 'Setx Mode Prefs' dialog"
	} else {
	    set helpText [help::prefString $itemName "Setx"]
	    if {$SetxmodeVars($itemName)} {
		set end "on"
	    } else {
		set end "off"
	    }
	    if {($end == "on")} {
		regsub {^.*\|\|} $helpText {} helpText
	    } else {
		regsub {\|\|.*$} $helpText {} helpText
	    }
	    set msg "The '$itemName' preference for Setx mode\
	      is currently $end."
	}
	alertnote "${helpText}."
    } elseif {($itemName == "setCommentCharacter")} {
	if {$SetxmodeVars(usePairedComments)} {
	    set    question "Setting the comment character is only useful "
	    append question "if the 'Use Paired Comments' preference "
	    append question "is turned off.\r"
	    append question "Would you like to turn it off now:\?"
	    if {[dialog::yesno -c $question]} {
	        set SetxmodeVars(usePairedComments) 0
		prefs::modified SetxmodeVars(usePairedComments)
	    }
	}
	set options {\# | > < ! @ $ % ^ & * ( ) }
	if {![lcontains options $SetxmodeVars(commentCharacter)]} {
	    lappend options $SetxmodeVars(commentCharacter)
	}
	set title   {Select a new comment character for Setx mode:}
	set default $SetxmodeVars(commentCharacter)
	# Offer a list of possible comment characters.
	set cC [eval prompt {$title} {$default} Options: $options]
	set cC [string trim $cC]
	set SetxmodeVars(commentCharacter) $cC
	set SetxmodeVars(prefixString)     "$cC "
	if {($mode == "Setx")} {
	    synchroniseModeVar commentCharacter $SetxmodeVars(commentCharacter)
	    synchroniseModeVar prefixString     $SetxmodeVars(prefixString)
	} else {
	    prefs::modified SetxmodeVars(commentCharacter)
	    prefs::modified SetxmodeVars(prefixString)
	}
	Setx::setCommentCharacters 1
	set msg "The new comment character for Setx mode is '$cC'"
    } elseif {($itemName == "moreSetextPrefs")} {
	help::openPrefsDialog Mode-Setx
    } elseif {[info exists SetxmodeVars($itemName)]} {
	set orig $SetxmodeVars($itemName)
	set SetxmodeVars($itemName) [expr {$orig ? 0 : 1}]
	if {($mode == "Setx")} {
	    synchroniseModeVar $itemName $SetxmodeVars($itemName)
	}
	markMenuItem setextOptions $itemName $SetxmodeVars($itemName) Ã
	prefs::changed Setx $itemName $orig $SetxmodeVars($itemName)

	if {$SetxmodeVars($itemName)} {
	    set end "on"
	} else {
	    set end "off"
	}
	set msg "The '$itemName' preference for Setx mode is now $end."
    } else {
	set msg "Sorry, the menu item '$itemName' is broken."
    }
    if {[info exists msg]} {
	status::msg $msg
    }
    return
}

proc Setx::setextKeywords {menuName itemName args} {
    
    global SetxmodeVars Setxcmds mode
    
    # Create the list of Setext keyword pref categories.
    foreach category {1 2 3} {
	lappend categories SetxmodeVars(addKeywords${category})
    }
    # List Keywords.
    if {($itemName == "listKeywords")} {
	set itemName "checkKeywords"
	set args [listpick -l -p "Current Setx mode keywordsÉ" $Setxcmds]
    }
    # Add Keywords.
    if {[regsub {^addKeywords} $itemName "" category]} {
	if {![string length $category]} {
	    set p "Select a keywords category :"
	    if {([llength $categories] == 1)} {
		set category [lindex $categories 0]
	    } else {
		set category [listpick -p $p $categories]
	    }
	    regexp {([0-9])} $category allofit category
	}
	set p "Enter new Setx 'list $category' keywords:"
	if {![llength $args]} {
	    set args [prompt $p ""]
	}
	if {![llength $args]} {
	    status::msg "Cancelled."
	    return
	}
	# Add keywords to the appropriate mode preference.
	set which addKeywords$category
	append SetxmodeVars($which) " $args"
	set SetxmodeVars($which) [lsort $SetxmodeVars($which)]
	prefs::modified SetxmodeVars($which)
	Setx::colorizeSetx 1
	if {[llength $SetxmodeVars($which)]} {
	    enableMenuItem "setextKeywords" "removeKeywords${category}É" on
	}
	status::msg "'[join $args]' added to Setx mode's '$which' preference."
    }
    # Remove Keywords.
    if {[regsub {^removeKeywords} $itemName "" category]} {
	if {![string length $category]} {
	    set p "Select a keywords category:"
	    if {([llength $categories] == 1)} {
		set category [lindex $categories 0]
	    } else {
		set category [listpick -p $p $categories]
	    }
	    regexp {([0-9])} $category allofit category
	}
	set p "Remove Setx 'list $category' keywords:"
	set keywords $SetxmodeVars(addKeywords$category)
	if {![llength $args]} {
	    set args [listpick -l -p $p $keywords]
	}
	if {![llength $args]} {
	    status::msg "Cancelled."
	    return
	}
	# Remove keywords from the appropriate mode preference.
	set which addKeywords$category
	set SetxmodeVars($which) [lremove $keywords $args]
	prefs::modified SetxmodeVars($which)
	regModeKeywords -a -k {black} Setx $args
	Setx::colorizeSetx 1
	if {![llength $SetxmodeVars($which)]} {
	    enableMenuItem "setextKeywords" "removeKeywords${category}É" off
	}
	status::msg "'[join $args]' removed from Setx mode's\
	  '$which' preference."
    }
    # Check Keywords
    if {($itemName == "checkKeywords")} {
	if {![llength $args]} {
	    set args [prompt "Enter Setx mode keywords to be checked:" ""]
	}
	foreach category {1 2 3} {
	    variable UserKeywords$item
	    lappend categories UserKeywords${category}
	}
	# Check to see if the keyword(s) is already defined.
	foreach keyword $args {
	    set type 0
	    foreach category $categories {
		if {[lcontains $category $keyword]} {
		    set type $category
		    break
		}
	    }
	    if {($type == 0)} {
		alertnote "'$keyword' is not currently defined\
		  as a Setx mode keyword"
	    } else {
		alertnote "'$keyword' is currently defined as a keyword\
		  in the '$type' list."
	    }
	}
    }
    return
}

# ×××× Setext Menu Support ×××× #

# These templates are "hard-wired" here, but the Setext Templates menu
# allows the user to edit them, storing them in the $PREFS folder.

namespace eval Setx {
    
    variable Template
    
    set Template(Header) {¥¥
TidBITS#¥¥
=========

  ¥¥

Topics:
    ¥¥
    ¥¥
    ¥¥
    ¥¥

<http://www.tidbits.com/tb-issues/TidBITS-¥¥.html>
<ftp://ftp.tidbits.com/issues/2003/TidBITS#¥¥>

Copyright 2003 TidBITS Electronic Publishing. All rights reserved.
   Information: <info@tidbits.com> Comments: <editors@tidbits.com>
   ---------------------------------------------------------------

This issue of TidBITS sponsored in part by:
* READERS LIKE YOU! You can help support TidBITS via our voluntary <- NEW!
   contribution program. Special thanks this week to ¥¥
   <http://www.tidbits.com/about/support/contributors.html>
   ---------------------------------------------------------------

}
    set Template(Footer) {¥¥
$$

  Non-profit, non-commercial publications may reprint articles if
  full credit is given. Others please contact us. We don't guarantee
  accuracy of articles. Caveat lector. Publication, product, and
  company names may be registered trademarks of their companies.

  This file is formatted as setext. For more information send email
  to <setext@tidbits.com>. A file will be returned shortly.

  For information: how to subscribe, where to find back issues,
  and more, email <info@tidbits.com>. TidBITS ISSN 1090-7017.
  Send comments and editorial submissions to: <editors@tidbits.com>
  Back issues available at: <http://www.tidbits.com/tb-issues/>
  And: <ftp://ftp.tidbits.com/issues/>
  Full text searching available at: <http://www.tidbits.com/search/>
  -------------------------------------------------------------------

}
}

proc Setx::isSetextFormat {{quietly 1}} {
    
    global mode
    
    set result 0
    
    if {($mode != "Setx")} {
	# First check to see if we're in Setx mode.
	set result 0
    } else {
	# See if there is a Setext mark in this window.
	set pat {^(-+|=+)$}
	set pos [minPos]
	while {1} {
	    set pp [search -n -s -f 1 -r 1 -m 0 -i 1 -- $pat $pos]
	    if {![llength $pp]} {
		break
	    }
	    set posBeg [pos::prevLineStart [lindex $pp 0]]
	    set marker [string trimright [eval getText $pp]]
	    set line [string trimright \
	      [getText $posBeg [pos::nextLineStart $posBeg]]]
	    if {([string length $line] == [string length $marker])} {
		set result 1
		break
	    } else {
		set pos [nextLineStart [lindex $pp 1]]
	    }
	}
    }
    if {!$quietly} {
	set    question "The current window does not seem to be formatted as a "
	append question "Setext file.  Are you sure that you want to continue?"
	if {!$result && ([askyesno $question] != "yes")} {
	    return 0
	} else {
	    return 1
	}
    } else {
	return $result
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Setx::renderWindow" --
 # 
 #  We're mimicing Setext viewers like 'EasyView'.
 #  -------------------------------------------------------------------------
 ##

proc Setx::renderWindow {{filename {}}} {
    
    if {[string length $filename]} {
	set txt   [file::readAll $filename]
	set title [file rootname [file tail $filename]]
    } elseif {![string length [set w [win::Current]]]} {
	status::msg "This item requires an open window."
	return -code return
    } elseif {[isSelection -w $w]} {
	set txt   [getSelect -w $w]
	set title "* Rendered Selection *"
    } elseif {![Setx::isSetextFormat 0]} {
	status::msg "Cancelled -- this file is not in Setext format."
	return -code return
    } else {
	set title "* [win::CurrentTail] *"
	set txt   [getText -w $w [pos::min -w $w] [pos::max -w $w]]
    }
    set w [new -n $title -text "\r[string trim $txt]\r" -m Text -tabsize 4]
    goto [pos::min -w $w]
    
    status::msg "Please wait: rendering Setext formatting tags É"
    
    set divider1 "\t[string repeat = 68]"
    set divider2 "\t[string repeat - 68]"
    # Remove any 'smart mode line'.
    set pos0 [pos::min -w $w]
    set pos1 [pos::nextLineStart -w $w $pos0]
    set txt1 [getText -w $w $pos0 $pos1]
    if {[regexp -- {\-\*\-[-a-zA-Z0-9#+]+\-\*\-} $txt1]} {
	replaceText -w $w $pos0 $pos1 ""
    }
    # Render Section Marks
    removeAllMarks
    Setx::markAsSetext -w $w 1
    foreach markList [lreverse [set marks [getNamedMarks -w $w]]] {
	foreach {mark fileName pos0 pos1 pos2} $markList {}
	set pos3 [pos::nextLineStart -w $w $pos2]
	set pos4 [pos::lineEnd -w $w $pos3]
	set pos5 [pos::prevLineStart -w $w $pos2]
	set pos6 [pos::prevLineEnd -w $w $pos2]
	# Determine the proper indentation
	if {[regexp {^\-+$} [getText -w $w $pos3 $pos4]]} {
	    set extraIndent " \t"
	} else {
	    set extraIndent ""
	}
	# Remove the marker ...
	replaceText -w $w $pos3 $pos4 ""
	# Replace the mark
	replaceText -w $w $pos1 $pos2 "\t  \t${extraIndent}"
	# Remove any 'fancy mark' stuff
	replaceText -w $w $pos5 $pos6 ""
    }
    # Add Table Of Contents
    set posL [pos::math -w $w [pos::min -w $w] + 1500]
    set toc  "\r\t  \tTable Of Contents\r\r\r"
    set pos0 [pos::min -w $w]
    set pp1  [search -w $w -n -s -f 1 -r 1 -l $posL -- "^$toc"   $pos0]
    set pp2  [search -w $w -n -s -f 1 -r 1 -l $posL -- {^\t  \t} $pos0]
    if {[llength $marks] && ![llength $pp1] && [llength $pp2]} {
	help::markAsAlphaManual 1
	foreach mark [getNamedMarks -w $w -n] {
	    if {![regexp {^\- *$} $mark]} {
		regsub -all {( +)\t} $mark "\1 " mark
		append toc "\"\# $mark\""
	    }
	    append toc "\r"
	}
	append toc "\r<<floatNamedMarks>>\r\r${divider1}\r\r\r"
	set pos1 [lindex $pp2 0]
	replaceText -w $w $pos1 $pos1 $toc
    }
    # Add Title
    regsub -all {(^[ *]+)|([ *]+([<>0-9]*)$)} $w "" title
    replaceText -w $w [pos::min -w $w] [pos::min -w $w] "\r${title}\r\r"
    # Render Lines
    set pos [pos::min -w $w]
    set pat {^[\t \*]*(\-+|\=+)$}
    while {1} {
	set pp [search -w $w -n -s -f 1 -r 1 -- $pat $pos]
	if {![llength $pp]} {
	    break
	}
	set pos0 [lindex $pp 0]
	set pos1 [lindex $pp 1]
	if {([string first "-" [getText -w $w $pos0 $pos1]] == -1)} {
	    set d $divider1
	} else {
	    set d $divider2
	}
	replaceText -w $w $pos0 $pos1 $d
	text::color $pos0 [pos::nextLineStart -w $w $pos0] 1
	set pos  [pos::nextLineStart -w $w $pos0]
    }
    # Render Bold
    set pos [pos::min -w $w]
    set pat {\s\*\*}
    while {1} {
	set pp [search -w $w -n -s -f 1 -r 1 -- $pat $pos]
	if {![llength $pp]} {
	    break
	}
	set pos0 [pos::nextChar [lindex $pp 0]]
	set pos1 [lindex $pp 1]
	regsub {\*\*} [getText -w $w $pos0 $pos1] {} what1
	# To ensure that positions don't get garbled when we do the
	# search below, we replace this text first.  If we decide
	# to continue or break for any reason, we'll replace it first.
	replaceText -w $w $pos0 $pos1 ${what1}
	set pos1 [pos::math -w $w $pos1 - 2]
	set pat1 {\*\*[\t\r\n\"'.,!:;() ]+}
	if {![llength [set pp [search -w $w -n -s -f 1 -r 1 -- $pat1 $pos1]]]} {
	    # Couldn't find a matching **.
	    replaceText -w $w $pos0 $pos0 ${what1}**
	    break
	} else {
	    # Found a match.  Set the positions from the most recent search.
	    set pos2 [lindex $pp 0]
	    set pos3 [lindex $pp 1]
	    regsub {\*\*} [getText -w $w $pos2 $pos3] {} what2
	}
	replaceText -w $w $pos2 $pos3 $what2
	# Note:  In Alphatk, this is not bold, but blue.
	text::color $pos0 $pos2 8
	set pos $pos2
    }
    # Render Italics
    set pos [pos::min -w $w]
    set pat {\s~}
    while {1} {
	set pp [search -w $w -n -s -f 1 -r 1 -- $pat $pos]
	if {![llength $pp]} {
	    break
	}
	set pos0 [pos::nextChar [lindex $pp 0]]
	set pos1 [lindex $pp 1]
	regsub {~} [getText -w $w $pos0 $pos1] {} what1
	# To ensure that positions don't get garbled when we do the
	# search below, we replace this text first.  If we decide
	# to continue or break for any reason, we'll replace it first.
	replaceText -w $w $pos0 $pos1 $what1
	set pos1 [pos::prevChar $pos1]
	set pat1 {~[\t\r\n\"'.,!:;() ]+}
	if {![llength [set pp [search -w $w -n -s -f 1 -r 1 -- $pat1 $pos1]]]} {
	    # Couldn't find a matching ~.
	    replaceText -w $w $pos0 $pos0 ${what1}~
	    break
	} else {
	    # Found a match.  Set the positions from the most recent search.
	    set pos2 [lindex $pp 0]
	    set pos3 [lindex $pp 1]
	    regsub {~} [getText -w $w $pos2 $pos3] {} what2
	}
	replaceText -w $w $pos2 $pos3 $what2
	# Note:  In Alphatk, this is not bold, but blue.
	text::color $pos0 $pos2 11
	set pos $pos2
    }
    # Render Underline
    set pos  [pos::min -w $w]
    set pat1 {[\s\"'.,!:;()]_[^\s]}
    set pat2 {[^\s]_[\s\"'.,!:;()]}
    while {1} {
	set pp1 [search -w $w -n -s -f 1 -r 1 -- $pat1 $pos]
	if {![llength $pp1]} {
	    break
	}
	set pos0 [pos::nextChar [lindex $pp1 0]]
	set pos  $pos0
	if {![llength [set pp2 [search -w $w -n -s -f 1 -r 1 -- $pat2 $pos]]]} {
	    # Didn't find a match.
	    set pos [lindex $pp1 1]
	    continue
	} else {
	    set pos1 [pos::prevChar -w $w [lindex $pp2 1]]
	}
	if {[regexp {\r|\n} [getText -w $w $pos0 $pos1]]} {
	    # We've gone beyond the current line.
	    set pos [lindex $pp1 1]
	    continue
	}
	#   Set the positions from the most recent search.
	set pos1 [pos::nextChar -w $w $pos1]
	regsub -all {_} [getText -w $w $pos0 $pos1] { } txt
	set txt  [string trim $txt]
	set pos2 [pos::math -w $w $pos0 + [string length $txt] + 2]
	set pos3 [pos::math -w $w $pos0 + [string length $txt]]
	
	replaceText -w $w $pos0 $pos2 $txt
	text::color $pos0 $pos3 15
	set pos $pos3
    }
    # Render Bullets
    set pos [pos::min -w $w]
    set pat {^\* }
    while {1} {
	set pp [search -w $w -n -s -f 1 -r 1 -- $pat $pos]
	if {![llength $pp]} {
	    break
	}
	set pos0 [lindex $pp 0]
	set pos1 [lindex $pp 1]
	replaceText -w $w $pos0 $pos1 {¥ }
	set pos [pos::nextLineStart -w $w $pos0]
    }
    # Render Quotes
    set pos [pos::min -w $w]
    set pat "^\[\t \]*> "
    while {1} {
	set pp [search -w $w -n -s -f 1 -r 1 -- $pat $pos]
	if {![llength $pp]} {
	    break
	}
	set pos0 [lindex $pp 0]
	set pos1 [lindex $pp 1]
	regsub -all {[\t ]*> } [getText -w $w $pos0 $pos1] "\t" txt
	replaceText -w $w $pos0 $pos1 $txt
	set pos0 [pos::nextLineStart -w $w $pos1]
    }
    # Render HotText (but what to do with it?)
    set pos  [pos::min -w $w]
    set pat1 {\s([a-zA-Z0-9][^\s_]*_)+\s}
    while {1} {
	set pp1 [search -w $w -n -s -f 1 -r 1 -- $pat1 $pos]
	if {![llength $pp1]} {
	    break
	}
	set pos0 [pos::nextChar -w $w [lindex $pp1 0]]
	set pos1 [pos::prevChar -w $w [lindex $pp1 1]]
	set pos  $pos0
	regsub -all {_} [getText -w $w $pos0 $pos1] { } txt
	replaceText -w $w $pos0 $pos1 $txt
	set pos3 [pos::math $pos0 + [string length [string trim $txt]]]
	text::color $pos0 $pos3 3
	text::hyper $pos0 $pos3 ""
	set pos $pos1
    }
    # Colour, Hyperize
    help::markAsAlphaManual 1
    help::colourTitle "red"
    help::colourMarks "red" 1
    help::colourCodeInserts "blue"
    help::hyperiseEmails 1
    help::hyperiseUrls 1
    help::hyperiseExtras 1
    goto -w $w [pos::min -w $w]
    setWinInfo -w $w dirty 0 ; winReadOnly
    refresh
    status::msg ""
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Setx::quote" --
 # 
 # Author: originally Vince Darley <mailto:vince@santafe.edu> but modified
 # by Donavan Hall for Setext mode who now accepts all fault if they don't
 # work properly. mailto:hall@magnet.fsu.edu
 # 
 # Modified by Craig, incorporated into "Setx::setextText", original procs
 # are archived below.
 # 
 # -------------------------------------------------------------------------
 ##


# The next two are Donavan's original procs.

## 
 # -------------------------------------------------------------------------
 # 
 # "help::textToSetext" --
 # 
 # Convert a file with "Text" style file marks (such as Alpha Help files) to
 # a Setext format.  This includes some conversions that only make sense for
 # Alpha Help files, including special hyperlink syntaxes.
 # 
 # -------------------------------------------------------------------------
 ##

proc Setx::textToSetext {} {
    
    global SetxmodeVars
    
    requireOpenWindow
    set t [getText [pos::min] [pos::max]]

    # Trim section (m)arks, surrounding them with (r)epeating "-|=" strings.
    set pat {\r(\t  \t([^\s][^\r]+)\r)}
    while {[regexp -indices $pat $t -> line txt]} {
	set m [string trim [eval [list string range $t] $txt]]
	set r [string repeat "=" [string length $m]]
	if {$SetxmodeVars(fancyMarks)} {
	    set m "${r}\r${m}\r${r}\r"
	} else {
	    set m "\r${m}\r${r}\r"
	}
	set t [eval [list string replace $t] $line [list $m]]
    }
    set pat {\r(\t  \t([^\r]+)\r)}
    while {[regexp -indices $pat $t -> line txt]} {
	set m [string trim [eval [list string range $t] $txt]]
	set r [string repeat "-" [string length $m]]
	if {$SetxmodeVars(fancyMarks)} {
	    set m "${r}\r${m}\r${r}\r"
	} else {
	    set m "\r${m}\r${r}\r"
	}
	set t [eval [list string replace $t] $line [list $m]]
    }
    # Clean up "package: " hyperlink strings that appear in column 4.
    set pat {\r    (package: )([^\s]+)}
    regsub -all -- $pat $t "\r    \\2" t
    # Clean up "Preferences: " hyperlink strings that appear in column 0.
    set pat {\r *Preferences: [^\s]+\r}
    while {[regexp -- $pat $t]} {
	regsub -all -- $pat $t "\r\r" t
    }
    # Clean up empty space lines.
    set pat {\r[\t ]+\r}
    while {[regexp -- $pat $t]} {
	regsub -all -- $pat $t "\r\r" t
    }
    # Miscellaneous cleanup.
    regsub -all -- {<<floatNamedMarks>>} $t "" t
    regsub -all -- {(<<|>>)} $t "\"" t
    regsub -all -- {"# ([^\r]+)"} $t "\\1" t
    regsub -all -- {\r+\t(-|=)+\r+} $t "\r\r" t
    regsub -all -- {\r\r\r+} $t "\r\r" t
    regsub -all -- {\t} $t "    " t
    set w [new -n "[win::Tail].stx" -text $t -mode "Setx"]
    goto [pos::min -w $w]
    setWinInfo -w $w dirty 0
    return
}


# proc Setx::quote {} {
#     
#     # Preliminaries
#     if {[comment::GetRegion Paragraph]} { return }
#     
#     set begComment "<"
#     set endComment ">"
#     set fillChar   "|"
#     
#     # First make sure we grab a full block of lines and adjust highlight
#     
#     set start [lineStart [getPos]]
#     set end   [nextLineStart [pos::math [selEnd] - 1]]
#     selectText $start $end
#     
#     # Now get rid of any tabs
#     
#     if {[pos::compare $end < [maxPos]] } {
#         createTMark stopComment [pos::math $end + 1]
#         tabsToSpaces
#         gotoTMark stopComment
#         set end [pos::math [getPos] - 1]
#         removeTMark stopComment
#     } else {
#         tabsToSpaces
#         set end [maxPos]
#     }
#     selectText $start $end
#     set text [getText $start $end]
#     
#     # Next turn it into a list of lines--possibly drop an empty 'last line'
#     
#     set lineList [split $text "\r\n"]
#     set ll [llength $lineList]
#     if { [lindex $lineList end] == {} } {
#         set lineList [lrange $lineList 0 [expr {$ll -2}] ]
#     }
#     set numLines [llength $lineList]
#     
#     # Find left margin for these lines
#     set lmargin 100
#     foreach l $lineList {
#         set lm [expr {[string length $l] - [string length [string trimleft $l]]}]
#         if { $lm < $lmargin } { set lmargin $lm }
#     }
#     set ltext ""
#     for { set i 0 } { $i < $lmargin } { incr i } { append ltext " " }
#     
#     # For each line add stuff on left and concatenate everything into 'text'.
#     
#     set text ${ltext}${begComment}\r
#     
#     foreach l $lineList {
#         append text ${ltext} ${fillChar} [string range $l $lmargin end] \r
#     }
#     append text ${ltext} ${endComment} \r
#     
#     # Now replace the old stuff, turn spaces to tabs, and highlight
#     
#     replaceText $start $end $text
#     set end [pos::math $start + [string length $text]]
#     frontSpacesToTabs $start $end
# }

# proc Setx::unquote {} {
#     
#     # Preliminaries
#     if {[comment::GetRegion Paragraph 1]} { return }
#     
#     set begComment "<"
#     set endComment ">"
#     set fillChar   "|"
#     set aSpace     " "
#     set aTab       \t
#     
#     # First make sure we grab a full block of lines and adjust highlight
#     
#     set start [lineStart [getPos]]
#     set end   [nextLineStart [pos::math [selEnd] - 1]]
#     selectText $start $end
#     set text [getText $start $end]
#     
#     # Find left margin for these lines
#     set l [string range $text 0 [string first "\r" $text] ]
#     set lmargin [expr {[string length $l] - [string length [string trimleft $l]]}]
#     
#     # Make sure we're at the start and end of the paragraph
#     
#     set startOK [string first $begComment $text]
#     set endOK [string last $endComment $text]
#     set textLength [string length $text]
#     if { $startOK != $lmargin || ($endOK != [expr {$textLength-[string length $endComment]-1}] || $endOK == -1) } {
#         alertnote "You must highlight the entire comment paragraph, including the tail ends."
#         return
#     }
#     
#     # Now get rid of any tabs
#     
#     if {[pos::compare $end < [maxPos]]} {
#         createTMark stopComment [pos::math $end + 1]
#         tabsToSpaces
#         gotoTMark stopComment
#         set end [pos::math [getPos] - 1]
#         removeTMark stopComment
#     } else {
#         tabsToSpaces
#         set end [maxPos]
#     }
#     selectText $start $end
#     set text [getText $start $end]
#     
#     # Next turn it into a list of lines--possibly drop an empty 'last line'
#     
#     set lineList [split $text "\r\n"]
#     set ll [llength $lineList]
#     if { [lindex $lineList end] == {} } {
#         set lineList [lrange $lineList 0 [expr {$ll -2}] ]
#     }
#     set numLines [llength $lineList]
#     
#     # Delete the first and last lines, recompute number of lines
#     
#     set lineList [lreplace $lineList [expr {$numLines-1}] [expr {$numLines-1}] ]
#     set lineList [lreplace $lineList 0 0 ]
#     set numLines [llength $lineList]
#     
#     # get the left margin
#     set lmargin [string first $fillChar [lindex $lineList 0]]
#     set ltext ""
#     for { set i 0 } { $i < $lmargin } { incr i } {
#         append ltext " "
#     }
#     
#     # For each line trim stuff on left and spaces and stuff on right and splice
#     set eliminate $fillChar$aSpace$aTab
#     set dropFromLeft [expr {[string length $fillChar] + $lmargin}]
#     set text ""
#     foreach thisLine $lineList {
#         set thisLine [string trimright $thisLine $eliminate]
#         set thisLine ${ltext}[string range $thisLine $dropFromLeft end]
#         append text $thisLine \r
#     }
#     # Now replace the old stuff, turn spaces to tabs, and highlight
#     replaceText $start $end $text
#     set end [pos::math $start + [string length $text]]
#     frontSpacesToTabs $start $end
# }

# Here's another version, which doesn't bother taking the leading
# indentation into account.

# proc Setx::quote {{unquote 0}} {
#     
#     global prefixString
#     
#     if {![isSelection]} {paragraph::select}
#     set oldPS $prefixString ; set prefixString "> "
#     if {!$unquote} {doPrefix insert} else {doPrefix remove}
#     set prefixString $oldPS
# }

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
#  modified by  rev    reason
#  -------- --- ----- -----------
#  10/01/94 tp  1.0.1 First version of Setx mode written by Tom Pollard
#  04/02/00 cbu 1.0.2 Additional preferences added, allowing user to define a
#                       comment character, magic character, keyword dictionaries
#  04/06/00 cbu 1.1   Added "Update Colors" proc to avoid need for a restart
#  04/20/00 cbu 1.1.1 Added "Use Paired Comments" variable for menu items.
#                     Added "Comment Menu Items" proc to update commentCharacter
#                      sets.
#  06/22/00 cbu 1.2   Reorganized Color proc routines.
#                     Renamed "Update Colors" to "Update Preferences".
#                     Fixed the "middle comment character" dilemna in paired
#                       comments.
#                     Moved "refresh" from Colorize to Update Preferences to
#                       avoid "no open window" bug from ever coming up.
#                     Mark names are stripped of leading comment characters,
#                       spaces. This way one can colorize headings using
#                       comment character.
#                     Section marks indentation now a variable.
#  12/04/00 cbu 1.3   Added Setx::DblClick for search urls.
#  12/04/00 cbu 2.0   New url prefs handling requires 7.4b21
#                     Added Bernard's bindings, Setx::underline
#  12/16/00 cbu 2.1   Beginning of Setext menu, based on stat modes menus.
#                     Support for a user specified application.
#                     Added Setx::helpFileMark, to help with creating
#                       Alpha's help files.
#                     Added Donavan's bindings, text mark-up items.
#                     Changed license from GNU to BSD style.
#  05/01/01 cbu 2.2   Setext menu finally "finished".
#                     More general Setx::markUpText proc.
#  05/20/01 cbu 2.3   Added 'Set Comment Character' menu item.
#                     Added a set of rendering procs, turning Alpha into a
#                       bona-fide Setext viewer.
#                     Added Header/Footer templates, 'New Setext Window'.
#                       All contained in new 'Setext Templates' subMenu.
#                       Default Header/Footer values are for TidBITs zine.
#                     Added 'fillParagraph', respects chapter/section
#                       headers, urls, leading indents of paragraphs, otherwise
#                       ensures leading indentation of two spaces.
#                     Added 'newComment', 'commentTemplate', inspired by
#                       the package 'javadocComment'.
#                     Added command navigation.
#                     Added 'Setext Keywords' submenu.
#                     Flag prefs help compatible for balloon help.
#  08/13/01 cbu 2.3.1 Replacement of 'synchroniseModeVar' with 'prefs::modified'.
#                     Minor bug fix for command::reformat.
#                     Minor bug fixes for paragraph/command navigation.
#  08/21/01 cbu 2.3.2 Implemented ${mode}::start/endCommand to help make
#                       the command navigation procs global more easily.
#                     Included instructions on making all navigation global.
#  09/26/01 cbu 2.3.3 Big cleanup, enabled by new 'functions.tcl' procs.
#  10/07/01 cbu 2.3.4 Minor modifications, bug fix for rendering underline,
#                       better use of synchroniseModeVar when necessary.
#  10/31/01 cbu 2.3.5 Minor bug fixes.
#  11/15/02 cbu 2.3.6 Added "fancyMarks"
#                     Minor aesthetic code cleaning.
#                     Using new help:: procs.
#                     Removing use of status::errorMsg.
# 03/07/03 cbu 2.4    Updated for Tcl 8.4 (which is now required).
#                     Various rendering enhancements.
# 04/13/03 cbu 2.4.1  Minor bug fixes.
# 05/30/03 cbu 2.5    Electrics changes. (Bug # 972).
#                     Help text updates.
#                     [breakIntoLines] / fillColumn update.
# 08/11/03 cbu 2.5.1  Reimplemented use of [global].
#                     Formatting changes using Tcl guidelines.
# 09/02/03 cbu 2.5.2  Minor bug fix, more Tcl formatting changes.
# 12/23/03 cbu 2.5.3  New "Text To Setext" conversion, mainly useful for
#                       Alpha Help files.
#                     The Setext menu is now available in Text mode.
# 

# ===========================================================================
#
# .