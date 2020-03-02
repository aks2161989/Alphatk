## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "wikiMode.tcl"
 #                                          created: 03/24/2002 {12:27:33 PM}
 #                                      last update: 03/21/2006 {03:29:12 PM}
 # Description:
 # 
 # Enables the editing and posting of wiki pages from Alpha.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #    
 # Copyright (c) 2002-2006  Vince Darley, Bernard Desgraupes,
 #                          Daniel Steffen, Craig Barton Upright
 #                          
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::mode Wiki {for wikiMenu menu} {Wiki::initializeMode} {*.wiki} {
    wikiMenu
} {
    # Initialization script.  Called when Alpha is first started.
    hook::register "wwwMenuInit" {WWW::defineEditUrls}
} uninstall {
    this-directory
} maintainer {
} description {
    Provides support for editing and posting remote Wiki web pages
}

proc wikiMode.tcl {} {}

namespace eval Wiki {
    
    variable modeInitialized
    if {![info exists modeInitialized]} {
	set modeInitialized 0
    }
    # Paragraphs limits are either empty lines, or lines starting with four
    # dashes or lines starting with three spaces and a star or lines
    # starting with four spaces (verbatim text)
    variable startPara {^([ \t]*$|\-\-\-\-|   ( |\*))}
    variable endPara   {^([ \t]*$|\-\-\-\-|   ( |\*))}
    
    # Create categories of Wiki prefs, used by [prefs::dialogs::modePrefs].
    variable prefTitle "Wiki Menu Preferences"
}

# ===========================================================================
# 
# ×××× Wiki Preferences ×××× #
# 

prefs::renameOld WikimodeVars(closeOnSave) WikimodeVars(closeWindowAfterPosting)
prefs::renameOld WikimodeVars(useWWWMenu)  WikimodeVars(useWWWMenuForViewing)

# Mode preferences settings, which can be edited by the user (with F12)

newPref var lineWrap 1 Wiki
newPref var fillColumn   70  Wiki
newPref var prefixString " " Wiki

# To automatically close the Wiki editing window on saving, click this 
# box.||To keep Wiki editing windows open after saving, allowing for
# repeated edits, click this box.
newPref flag closeWindowAfterPosting 0 Wiki
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Wiki
# To always use Alpha's WWW Menu to view wiki pages via the Wiki Menu,
# turn this item on||To always use your "View URL" setting to view wiki 
# pages via the Wiki Menu, turn this item off
newPref flag useWWWMenuForViewing 0 Wiki

# These are used by the ::parseFuncs procedure when the user clicks on the {}
# button in a file edited using this mode.  If you need more sophisticated
# function marking, you need to add a Wiki::parseFuncs proc

newPref var funcExpr {^'''[^\r\n]+'''} Wiki
newPref var parseExpr {'''([^\r\n]*)'''} Wiki

# The color of the single quotation character.
newPref color quoteColor        {red}       Wiki    {Wiki::colorizeWiki}
# The color of the asterisk.
newPref color starColor         {green}     Wiki    {Wiki::colorizeWiki}
# The color of square brackets.
newPref color bracketColor      {blue}      Wiki    {Wiki::colorizeWiki}

# ===========================================================================
# 
# Categories of all Wiki preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Create the group order.
prefs::dialogs::setPaneLists "Wiki" \
  "Editing"                     [list] \
  "Colors"                      [list] \
  "Wiki Menu"                   [list] \
  "Wiki Menu > Text"            [list] \
  "Wiki Menu > Line"            [list] \
  "Wiki Menu > Paragraph"       [list]

# Editing
prefs::dialogs::setPaneLists "Wiki" "Editing" [list \
  "closeWindowAfterPosting" \
  "fillColumn" \
  "funcExpr" \
  "indentOnReturn" \
  "lineWrap" \
  "parseExpr" \
  "prefixString" \
  ]

# Wiki Menu
prefs::dialogs::setPaneLists "Wiki" "Wiki Menu" [list \
  "useWWWMenuForViewing" \
  ]

# Colors
prefs::dialogs::setPaneLists "Wiki" "Colors" [list \
  "bracketColor" \
  "quoteColor" \
  "starColor" \
  ]

# ===========================================================================
# 
# ×××× Wiki Bindings ×××× #
# 

# Handy navigation bindings.
Bind    up <sz>  {function::prev 0 0}  Wiki
Bind  left <sz>  {function::prev 0 1}  Wiki
Bind  down <sz>  {function::next 0 0}  Wiki
Bind right <sz>  {function::next 0 1}  Wiki

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::initializeMode" --
 # 
 # This proc is called the first time that this mode is loaded.  It should
 # _never_ be called by anything except the AlphaTcl SystemCode procedures!
 # 
 # This file will already be loaded in its entirety before this procedure is
 # formally evaluated, so all variables and preferences should be in place.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::initializeMode {} {
    
    variable modeInitialized
    
    if {$modeInitialized} {
	return
    }
    
    # Call this now so that the rest can be adds (-a)
    regModeKeywords Wiki {}
    # Colour the keywords, comments etc.
    Wiki::colorizeWiki
    
    # Register hooks.
    hook::register savePostHook {Wiki::savePostHook}  Wiki
    hook::register closeHook    {Wiki::closeHook}     Wiki
    
    set modeInitialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::colorizeWiki" --
 # 
 # Colorize Wiki mode windows.  This requires an initial
 # 
 #   regModeKeywords Wiki {}
 # 
 # in [Wiki::initializeMode] so that all of these can be "adds" (-a)
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::colorizeWiki {args} {
    
    global WikimodeVars
    
    regModeKeywords -a -i "'" -I $WikimodeVars(quoteColor) Wiki {}
    regModeKeywords -a -i "*" -I $WikimodeVars(starColor)  Wiki {}
    regModeKeywords -a -i "\]" -i "\[" -I $WikimodeVars(bracketColor) Wiki {}
    
    if {[llength $args]} {
	refresh
    }
    return
}

# ===========================================================================
# 
# ×××× Wiki Hooks ×××× #
# 
# These simply redirect to the procedures in "wikiRemote.tcl".
# 

proc Wiki::savePostHook {name} {
    Wiki::postWindowText $name
    return
}

proc Wiki::closeHook {name} {
    Wiki::unsetWindowInfo $name
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Indentation, Filling, etc ×××× #
# 

## 
 # ----------------------------------------------------------------------
 #       
 # "Wiki::correctIndentation"  --
 #    
 # If we're at the start of a paragraph block, return the line's indentation. 
 # If we're in the second line of a block and the first line contains the
 # 'definitionItem' open and closing tags, return 0 in an attempt to conform
 # to 'logical line' rules.  (This might not work when the file is saved due
 # to the presence of hard carriage returns -- user probably should use the
 # menu item 'Paragraph To Line' before saving.)  Otherwise, return the
 # return the indentation of the most recent line, so that we can continue
 # indented tags if desired.
 # 
 # The main point here is to _not_ grab the indentation of the last line of
 # the previous paragraph if we're indenting or reformatting an entire
 # paragraph.
 # 
 # ----------------------------------------------------------------------
 ##

proc Wiki::correctIndentation {args} {
    
    win::parseArgs w pos {nextChar ""}
    
    # If we're not in a paragraph block, return the indentation of the
    # previous line
    if {![lindex [set results [function::inFunction -w $w $pos]] 0]} {
	::correctIndentation -w $w $pos $nextChar
    } elseif {[pos::compare -w $w \
      [pos::lineStart -w $w] == [set pos0 [lindex $results 1]]]} {
	# This is the first line of the block's indentation.
	set pos1 [text::firstNonWsLinePos -w $w $pos0]
	return [string length \
	  [text::maxSpaceForm -w $w [getText -w $w $pos0 $pos1]]]
    } elseif {[pos::compare -w $w [pos::prevLineStart -w $w] == $pos0]} {
	# This is the second line, so check to see if we're in the middle of
	# a definition item.
	Wiki::currentProject
	array set tagTypes $settings
	set dIOpen  [lindex $tagTypes(definitionItem) 0]
	set dIClose [lindex $tagTypes(definitionItem) 1]
	set line    [getText -w $w $pos0 [pos::lineEnd -w $w $pos0]]
	if {[regexp ^$dIOpen $line] && [regexp $dIClose $line]} {
	    return 0
	} else {
	    return [::correctIndentation -w $w $pos $nextChar]
	}
    } else {
	return [::correctIndentation -w $w $pos $nextChar]
    }
}

## 
 # ----------------------------------------------------------------------
 #       
 # "Wiki::reformatParagraph"  --
 #    
 # A wrapper around 'function::reformat' that remembers where we are, and
 # makes sure that any horizontal lines touching the end of the paragraph
 # block are not inadvertantly indented.  (I think that's a bug in
 # 'function::reformat'.  In fact, the 'memory' stuff here probably should go
 # in there.)
 # 
 # ----------------------------------------------------------------------
 ##

proc Wiki::reformatParagraph {} {
    
    set len [pos::diff [set pos0 [getPos]] [set pos1 [selEnd]]]
    if {![isSelection]} {
	function::select
    } else {
	selectText [Wiki::blockBeg [getPos]] [Wiki::blockEnd [selEnd]]
    }
    set memory [::paragraph::rememberWhereYouAre [set start [getPos]] $pos0 [selEnd]]
    function::reformat
    # Make sure that we didn't indent a horizontal line.
    Wiki::currentProject
    array set tagTypes $settings
    set hl   [string trim [join $tagTypes(horizontalLine)]]
    set pos3 [pos::lineEnd [set pos2 [getPos]]]
    if {[regexp -- $hl [getText $pos2 $pos3]]} {
	replaceText [pos::lineStart $pos2] $pos3 ""
    }
    # Try to select the previous selection.
    ::paragraph::goBackToWhereYouWere $start \
      [pos::math $start + [string length [getText $start [getPos]]]] $memory
    selectText [getPos] [pos::math [getPos] + $len]
    return
}

# ===========================================================================
# 
# ×××× Wiki function:: support ×××× #
# 

# Can't we just use something simple?
#set Wiki::startFunction {[-\r\n]+[-\r\n\t ]*[\r\n]+[^-\r\n]}
#set Wiki::endFunction   {[-\r\n]+[-\r\n\t ]*[\r\n]+[^-\r\n]}

## 
 # ----------------------------------------------------------------------
 #       
 # "Wiki::getLimits" --
 #    
 # Called by "function::" procs to determine the boundaries of any possible
 # paragraph blocks surrounding the cursor.  Allows us to simulate paragraph
 # navigation, selection, etc. while treating horizontal lines as 'empty',
 # indicating the separation of paragraphs.
 # 
 # ----------------------------------------------------------------------
 ##

proc Wiki::getLimits {args} {
    
    win::parseArgs w pos direction
    
    set pos0 [Wiki::blockBeg -w $w $pos $direction]
    set pos1 [Wiki::blockEnd -w $w $pos0]
    
    return [list $pos0 $pos1 "text block"]
}

##
 # ----------------------------------------------------------------------
 #       
 # "Wiki::blockBeg" --
 # "Wiki::blockEnd" --
 #      
 # Variations of paragraph::start/finish, used by Wiki::getLimits to navigate
 # and select blocks of text recognized as blocks of text that are separated
 # by empty lines, or by horizontal lines.
 # 
 # ----------------------------------------------------------------------
 ##

proc Wiki::blockBeg {args} {
    
    win::parseArgs w pos {direction 0}
    
    if {!$direction && \
      [pos::compare -w $w [pos::lineStart -w $w $pos] == [minPos -w $w]]} {
	return [minPos -w $w]
    } elseif {$direction && \
      [pos::compare -w $w [pos::lineEnd -w $w $pos] == [maxPos -w $w]]} {
	return [maxPos -w $w]
    } elseif {$direction} {
	if {[pos::compare -w $w [pos::lineEnd -w $w $pos] == $pos]} {
	    set pos [pos::prevLineStart -w $w $pos]
	} else {
	    set pos [pos::lineStart -w $w $pos]
	}
    }
    
    # Wiki::currentProject
    # set    pat "(^[string trim [join [lindex $settings 5]]]\s*)|"
    # append pat {([\r\n]+[\r\n\t ]*[\r\n]+[^\r\n])}
    
    set pat {[-\r\n]+[-\r\n\t ]*[\r\n]+[^-\r\n]}
    if {![catch {search -w $w -f $direction -r 1 -s $pat $pos} match]} {
	set pos0 [pos::lineStart -w $w [lindex $match 1]]
    } elseif {!$direction} {
	set pos0 [minPos -w $w]
    } else {
	set pos0 [maxPos -w $w]
    }
    # We might have to back up one character and do this all over again if
    # we're greater than the original position.
    if {!$direction && [pos::compare -w $w $pos0 > $pos]} {
	return [Wiki::blockBeg [pos::prevChar -w $w $pos $direction]]
    } elseif {$direction && [pos::compare -w $w $pos0 < $pos]} {
	return [Wiki::blockBeg [pos::nextLineStart -w $w $pos $direction]]
    } else {
	return $pos0
    }
}

proc Wiki::blockEnd {args} {
    
    win::parseArgs w blockBeg
    
    set pos [pos::nextChar -w $w $blockBeg]
    
    # Wiki::currentProject
    # set    pat "(^[string trim [join [lindex $settings 5]]]\s*)|"
    # append pat {([\r\n]+[\r\n\t ]*[\r\n]+[^\r\n])}
    
    set pat {[-\r\n]+[-\r\n\t ]*[\r\n]+[^-\r\n]}
    set pos0 $pos
    set pos1 $pos
    # We might have to go one character forward and do this all over again if
    # the first iteration position is less than the original position.
    while {[pos::compare -w $w $pos0 <= $pos]} {
	if {[pos::compare -w $w [pos::lineEnd -w $w $pos1] == [maxPos -w $w]]} {
	    return [maxPos -w $w]
	} elseif {![catch {search -w $w -f 1 -r 1 -s $pat $pos1} match]} {
	    set pos0 [pos::nextLineStart -w $w [lindex $match 0]]
	} else {
	    return [maxPos -w $w]
	}
	set pos1 [pos::nextChar -w $w $pos1]
    }
    return $pos0
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ----- -----------
# 03/24/02 vmd 0.1   Original
# 03/10/03 bd  0.2?  New "wikiMethods.tcl" file with editing methods.
# 07/04/03 bd  0.3?  converted from mode to menu 
# 01/27/04 bd  0.4?  Fixed bug 1283. New "Add A FavoriteÉ" menu item
# 12/06/04 vmd 0.5?  Allow "registered" AlphaTcl/Tcl wiki posting.
# 12/09/04 cbu 0.6?  Allow "anonymous" AlphaTcl wiki posting.
#                    Generalized scheme for adding new posting regimes for 
#                      any given wiki type as this becomes necessary.
# 01/20/06 bd  1.0   New default AlphaTcl wiki location.
# 01/26/06 cbu 1.1   New back compatibility procedures to reset defaults.
# 01/27/06 cbu 1.2   Split "wikiMode.tcl" into several new files:
#                      "wikiMenu.tcl"
#                      "wikiProjects.tcl"
#                      "wikiRemote.tcl"
#                    Major clean-up of all procedures.
#                    Re-organized Wiki Menu.
#                    Updated "Wiki Menu Help" file.
#                    New "Wiki Menu > Review Last Post" command.
#                    New "Wiki Menu > Wiki Systems Help" menu item.
#                    New "Wiki Menu > Wiki System Info" menu item.
#                    [Wiki::restoreDefaults] resolves purls.
#                    Improved parsing/viewing of posting results.
#                    "registrationUrl" field removed; new "author" and 
#                      "password" fields can be specified.
#                    WikiSystems presented to the user as prettified names.
#                    New "wikiFavorites.tcl" file.
#                    New "wikiSystems.tcl" file.
# 

# ===========================================================================
# 
# .