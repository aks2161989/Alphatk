## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "comments.tcl"
 #                                          created: 10/27/1999 {09:24:19 PM}
 #                                      last update: 03/21/2006 {01:10:04 PM}
 # Description:
 #  
 # Provides a set of generalized routines for commenting lines, paragraphs,
 # boxes in any mode.  See the 'help' information below.  All of the procs
 # below the "Utilities" section will return "1" if the operation was
 # successsful, otherwise they return "0".
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #    
 # Includes contributions from Jon Guyer, Johan Linde, Craig Barton Upright.
 #  
 # Copyright (c) 1997-2006 Vince Darley.
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ===========================================================================
 ##

# Auto-loading extension declaration.
# 
# Note that this could be an 'always on' package, and on initialization
# could add the menu item "(Un)Comment Line/Paragraph/Box" menu items to the
# "Text" menu.  Or it could only add "(Un)Comment Line/Paragraph", and leave
# the "Box" menu item for the "Pretty Comments" package to add.
# 
# If this route was chosen, we might need to adjust [menu::textEditProc] to
# make it easier to identify the procs that should be used for items selected
# via the menu.  Currently, all of these items are 'hard-wired', while they
# could be called in the 'text' namespace, as in [text::commentLine].
# 
# Note that all of the 'comment' obsolete procs in "backCompatibility.tcl"
# are no longer used in any file in the standard AlphaTcl distributions, and
# could be reasonably removed now.  (Doing so would allow us to instead
# define such things as [commentLine], which would be called by by the
# 'default' switch item in [menu::textEditProc] and properly directed here.)
# 

alpha::extension "comments" 1.0.1 {
} description {
    Provides a set of generalized routines for commenting text in windows,
    used by the Text menu items
} help {
    This package provides a set of generalized routines for commenting text in
    the current window.  "Text > Comment Line" is the most basic routine,
    which will comment out the current line/selected region.  Blocks of text
    can also be commented using special "Paragraph" or "Box" formats, called
    by "Text > Comment <something>" menu items.
    
    Once a comment has been created, you can also 'uncomment' the line or
    block of text.  (Note that the "Text" menu, like many in Alpha, might be
    dynamic, and some items are 'hidden' until you press some of the modifier
    keys such as Command/Alt, Option/Meta, or Control.)
    
    For example, in Tcl mode this is a basic comment, created using either the
    "Text > Comment Line" menu item or its equivalent keyboard shortcut:
    
	# These are two commented lines.  They are normally not indented when
	# created by the menu item or the keyboard shortcut.
    
    while this is a paragraph:
    
	## 
	 # You can create this by selecting a block of text and using the
	 # Text > Comment Paragraph menu item.  If no text is initially
	 # selected, the current paragraph surrounding the cursor will be
	 # chosen, and you will be asked if this is the region that you want.
	 # 
	 # Paragraph style comments such as these will usually be properly
	 # indented with respect to surrounding text.
	 ##
    
    and this is a box:

	####################################################
	#                                                  #
	#   This is some text that was put into a 'box'.   #
	#   Box comments are usually never indented,       #
	#   this one is just for demonstration purposes.   #
	#                                                  #
	####################################################
    
    Once a comment block has been created, you can use the menu items for
    "Edit > Shift Left/Right (Space)" to adjust their indentation.

    Each mode defines comment characters specific to its usage.  In most
    cases, a mode preference for "Prefix String" will allow you to adjust the
    whitespace following the comment character -- in general, this is ONLY
    used for the "Text > (Un)Comment Line" procedure.  Modes usually also
    define 'comment colors' to help highlight them in the window.
    
    Note that some of the default routines supplied by this auto-loading
    package might be over-ridden by mode specific shortcuts and/or procedures,
    or by other packages, such as the package: prettyComments.
    
	  	AlphaTcl Developer Notes
    
    Some of these procedures will only work if the mode has defined some
    <mode>::commentCharacters array elements for "General", "Paragraph" and
    "Box".  At a minimum, modes should define preferences for "prefixString"
    and possibly "suffixString" in order for the most basic comment routines
    to work.  This package also supplies some comment template procedures that
    can be called by any mode, such as the proc: comment::insertDivider or the
    proc: comment::newComment .
    
    Note that any mode can over-ride the default routine that is called by
    "Text > (Un)Comment Line" by defining a mode specific procedure, such as
    the proc: C::CommentLine.  This is useful if the comment characters are
    not as straightforward as those in (e.g.) Tcl mode.  This is particularly
    true when the mode has both single and bracketed comment characters, as in
    the family of C modes, and several statistical modes.
    
    This package also includes some comment utilities, to query for the
    current mode's comment characters, or to obtain the current block of text
    which is or should be turned into a comment block.  See this package's
    source file "comments.tcl" for more information, and in particular the
    notes preceding the proc: comment::Characters .
} maintainer {
    "Vince Darley" <vince@santafe.edu>
}

proc comments.tcl {} {}

namespace eval comment {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Comment Characters, Utilities ×××× #
# 

## 
 # --------------------------------------------------------------------------
 #       
 # "comment::Characters" --
 # 
 # General purpose query to determine the comment characters for any mode. 
 # This allows mode authors to keep everything self-contained.  If no
 # characters have been defined for the given 'purpose', then an empty list
 # will be returned.  
 # 
 # The default mode will be that for the current window, although the
 # optional 'modeList' argument can also be supplied.  In this case, we
 # assume that all relevant mode information has already been loaded,
 # and though we could we do not make any attempt to do load it here.
 # 
 # 'Purposes' include "General", "Paragraph", and "Box".  Other 'purposes'
 # could also be added and queried, though as of this writing these are the
 # only three that are widely defined by modes in AlphaTcl.  
 #  
 # "General" purpose characters are used to check if we're in a comment
 # block, but are not used in the default Line/Paragraph/Box routines below. 
 # This "General" category could be a list, such as
 #      
 #    set C++::commentCharacters(General) [list "*" "//"]
 #      
 # if there are several different characters that could indicate a comment.
 # 
 # "Paragraph" characters should be a list with three items: the beginning,
 # the end, and any character that should be used in between them.  This is
 # most useful for modes that only use bracketed comments, but allows for
 # other modes to create "Paragraph" style comments like this block.
 # 
 # "Box" characters should be a list with six items:
 # 
 #   (0) Beginning Comment Character(s)
 #   (1) Beginning Comment Length
 #   (2) Ending Comment Character(s)
 #   (3) Ending Commment Length
 #   (4) Fill Character
 #   (5) Space Offset
 #   
 # Here's a typical example for a mode with a single comment character:
 # 
 #   set Tcl::commentCharacters(Box) [list "#" 1 "#" 1 "#" 3]
 #   
 # Here's an example for a mode using bracketed characters:
 # 
 #   set HTML::commentCharacters(Box) {<!-- 4 --> 3 | 3}
 #   
 # Experiment with "Text --> Comment Box" to determine correct values, and in
 # particular how different 'Space Offset' values change the construction of
 # the box.  (And yes, the "Comment Length" vars could be pretty easily
 # computed using [string length ...], but this is a legacy from earlier
 # versions and there's little reason to change all uses in AlphaTcl now.)
 # 
 # --------------------------------------------------------------------------
 ##

proc comment::Characters {purpose {modeList ""}} {
    
    if {[llength [info level 0]] == 2} {
	set modeList [win::getInfo [win::Current] varmodes]
    }
    set vinfo [mode::getVarInfo commentCharacters($purpose) $modeList]
    # If it doesn't exist, we're happy to return the empty string.
    return [lindex $vinfo 1]
}

## 
 # --------------------------------------------------------------------------
 #       
 # "comment::GetRegion" --
 #      
 # Default is to look for a paragraph to comment out.  If "uncomment" is '1',
 # then we look for a commented region to uncomment.  If we have successfully
 # found a region (either because there was an initial selection or the user
 # approved of the one we chose), we return "1", otherwise "0"
 #  
 # --------------------------------------------------------------------------
 ##

proc comment::GetRegion {purpose {uncomment 0}} {

    # Preliminaries
    if {[isSelection]} {
        return 1
    } elseif {![llength [set commentList [Characters $purpose]]]} {
        # If we don't have any comment characters, there's no point in
        # teasing the user by finding a region.
        status::msg "'$::mode' mode has not defined any '$purpose' comment characters."
        return 0
    }
    # There's no selection, so we try and generate one.
    watchCursor
    set pos [getPos]
    if {$uncomment} {
        # Uncommenting
        switch -- $purpose {
            "Box" {
                set begComment  [lindex $commentList 0]
                set begComLen   [lindex $commentList 1]
                set endComment  [lindex $commentList 2]
                set endComLen   [lindex $commentList 3]
                set fillChar    [lindex $commentList 4]
                set spaceOffset [lindex $commentList 5]
		
		# get length of current line
		set line [getText [lineStart $pos] [nextLineStart $pos] ]
		set c [string trimleft $line]
		set slen [expr {[string length $line] - [string length $c]}]
		set start [string range $line 0 [expr {$slen -1}] ]
		
		set pos [getPos]
		
		if {$start == ""} {
		    set p $pos
		    while {[string first $fillChar $line] == 0 && \
		      [expr {[string last $fillChar $line] + [string length $fillChar]}] \
		      >= [string length [string trimright $line]]} {
			set p [nextLineStart $p]
			set line [getText [lineStart $p] [nextLineStart $p]]
		    }
		    set end [pos::prevLineStart $p]
		    
		    set p $pos
		    set line "${fillChar}"
		    while {[string first $fillChar $line] == 0 && \
		      [expr {[string last $fillChar $line] + [string length $fillChar]}] \
		      >= [string length [string trimright $line]]} {
			set p [pos::prevLineStart $p]
			set line [getText [pos::prevLineStart $p] [lineStart $p] ]
		    }
		    set begin [lineStart $p]
		    
		} else {
		    set line "$start"
		    set p $pos
		    while {[string range $line 0 [expr {$slen -1}] ] == "$start"} {
			set p [nextLineStart $p]
			set line [getText [lineStart $p] [nextLineStart $p]]
		    }
		    set end [pos::prevLineStart $p]
		    
		    set p $pos
		    set line "$start"
		    while {[string range $line 0 [expr {$slen -1}] ] == "$start"} {
			set p [pos::prevLineStart $p]
			set line [getText [pos::prevLineStart $p] [lineStart $p] ]
		    }
		    set begin [lineStart $p]
		}
		
		set beginline [getText $begin [nextLineStart  $begin]]
		if {[string first "$begComment" "$beginline" ] != $slen} {
		    status::msg "First line failed"
		    return 0
		}
		
		set endline [getText $end [nextLineStart $end]]
		set epos [string last "$endComment" "$endline"]
		incr epos [string length $endComment]
		set s [string range $endline $epos end ]
		set s [string trimright $s]
		
		if {$s != ""} {
		    status::msg "Last line failed"
		    return 0
		}
		
		set end [nextLineStart $end]
		selectText $begin $end
	    }
	    "Paragraph" {
		set begComment [lindex $commentList 0]
		set endComment [lindex $commentList 1]
		set fillChar   [lindex $commentList 2]
		# Basic idea is search back and forwards for lines that don't
		# begin the same way and then see if they match the idea of
		# the beginning and end of a block
		set line [getText [lineStart $pos] [nextLineStart $pos] ]
		set chk [string range $line 0 [string first $fillChar $line]]
		if {[string trimleft $chk] != ""} {
		    status::msg "Not in a comment block"
		    return 0
		}
		regsub -all -- {   } $line " " line
		set p [string first "$fillChar" "$line"]
		set start [string range "$line" 0 [expr {$p + [string length $fillChar] -1}]]
		set ll [GetFillLines $start]
		set begin [lindex $ll 0]
		set end [lindex $ll 1]
		
		set beginline [getText $begin [nextLineStart $begin]]
		if {[string first "$begComment" "$beginline" ] != $p} {
		    listpick [list [string first "$begComment" "$beginline" ] $p]
		    status::msg "First line failed"
		    return 0
		}
		
		set endline [getText $end [nextLineStart $end]]
		set epos [string last "$endComment" "$endline"]
		incr epos [string length $endComment]
		set s [string range $endline $epos end ]
		set s [string trimright $s]
		
		if {$s != ""} {
		    status::msg "Last line failed"
		    return 0
		}
		set end [nextLineStart $end]
		selectText $begin $end
	    }
	    default {error "Unknown purpose: $purpose"}
	}
    } else {
	# Commenting out
	set pattern "^\[ \t\]*\$"
	set searchResult1 [search -s -f 0 -r 1 -n $pattern $pos]
	set searchResult2 [search -s -f 1 -r 1 -n $pattern $pos]
	if {[llength $searchResult1]} {
	    set posStart [pos::math [lindex $searchResult1 1] + 1]
	} else {
	    set posStart [minPos]
	}
	if {[llength $searchResult2]} {
	    set posEnd [lindex $searchResult2 0]
	} else {
	    set posEnd [pos::math [maxPos] + 1]
	    goto [maxPos]
	    insertText "\n"
	}
	selectText $posStart $posEnd
    }
    set str "Do you wish to "
    if {$uncomment} {append str "uncomment"} else {append str "comment out"}
    append str " this region?"
    return [dialog::yesno $str]
}

proc comment::TextBlock {txt} {
    set cc [Characters "Paragraph"]
    set c  [lindex $cc 2]
    regsub -all -- "\[\r\n\]" $txt "\r${c}" txt
    return "[lindex $cc 0]\r[lindex $cc 2]${txt}\r[lindex $cc 1]\r"
}

proc comment::GetFillLines {start} {
    set pos [getPos]
    regsub -all -- "\t" $start " " start
    set line "$start"
    
    set p $pos
    while {[SameStart "$line" "$start"]} {
	set p [nextLineStart $p]
	set line [getText [lineStart $p] [nextLineStart $p]]
    }
    set end [lineStart $p]
    
    set p $pos
    set line "$start"
    while {[SameStart "$line" "$start"]} {
	set p [pos::prevLineStart $p]
	set line [getText [pos::prevLineStart $p] [lineStart $p] ]
    }
    set begin [pos::prevLineStart $p]
    return [list $begin $end]
}

proc comment::SameStart {line start} {
    regsub -all -- "\t" $line " " line
    if {[string first "$start" "$line"] == 0} {
	return 1
    } else {
	return 0
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Lines, Paragraphs, Boxes ×××× #
# 

## 
 # --------------------------------------------------------------------------
 #       
 # "comment::Line" "::CommentLine"  --
 #      
 # Comments the current line or all lines of the current selection, adjusting
 # and then rehighlighting any previous selection.  Note that we do NOT use
 # the value for <mode>::commentCharacters(General) in these procs, but
 # assume that if a mode is sophisticated enough to define them then we also
 # have 'prefixString' mode vars defined.  This allows the user to modify
 # the general comment character using the "Mode Prefs --> Preferences" menu,
 # to adjust the whitespace following the comment character.
 # 
 # This will call different routines based upon the presence of mode specific
 # procs/vars, in the following order:
 # 
 # (1) This will call a mode proc if one has been defined, as in
 # 
 #   C::CommentLine
 #   
 # This mode proc could perform whatever tests are required and then
 # optionally call [::CommentLine] if this is desired.  For consistency,
 # these mode procs should attempt to reselect any prior selection.
 #   
 # (2) If no "Paragraph" style comments have been defined, or if the
 # beginning and ending paragraph chars are the same, then we default to the
 # [insertPrefix] and [insertSuffix] procs, so long as the modeVars for
 # "prefix/suffixString" have been defined.  
 # 
 # (3) If we have a selection, then we call [comment::Paragraph].
 # 
 # (4) If we do not have a selection, then we insert the beginning and
 # ending "Paragraph" comment chars (which we know exist and are unique)
 # at the beginning and end of the current line.
 # 
 # --------------------------------------------------------------------------
 ##

proc comment::Line {} {
    hook::callProcForWin CommentLine
}

proc ::CommentLine {} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit]} {return 0}
    set win   [win::Current]
    set ext   [file extension $win]
    set chars [comment::Characters Paragraph]
    
    if {[string trim [lindex $chars 0]] == [string trim [lindex $chars 1]]} {
	# Comment chars are either not defined, or the beginning and ending
	# 'Paragraph' chars are the same.  Use default prefix/suffix procs,
	# so long as the mode has defined them.
	if {([win::getModeVar $win prefixString ""] ne "")} {
	    insertPrefix
	    set didSomething 1
	}
	if {([win::getModeVar $win suffixString ""] ne "")} {
	    insertSuffix
	    set didSomething 1
	}
	if {![info exists didSomething]} {
	    status::msg "'$::mode' mode does not have comment characters defined."
	    return 0
	}
    } elseif {[isSelection]} {
	# We know that the mode has unique 'paragraph' style comment chars.
	comment::Paragraph
    } else {
	# Could possibly call [insertPrefix] and [insertSuffix] here,
	# although by doing this we only have to perform one 'reselect'.
	# Could also do this using "prefixString" and "suffixString" vars.
	set pos0 [pos::lineStart]
	set pos1 [getPos]
	set pos2 [pos::lineEnd]
	set txt1 [getText $pos0 $pos1]
	set txt2 [getText $pos0 $pos2]
	replaceText $pos0 $pos2 "[lindex $chars 0]${txt2}[lindex $chars 1]"
	goto [pos::math $pos0 + [string length "[lindex $chars 0]${txt1}"]]
    }
    return 1
}

## 
 # --------------------------------------------------------------------------
 #       
 # "comment::undoLine" "::UncommentLine"  --
 #      
 # Uncomments the current line or all lines of the current selection,
 # adjusting and then rehighlighting any previous selection.
 # 
 # This will call a mode proc if one has been defined, as in
 # 
 #   C::UncommentLine
 #   
 # Otherwise, the order of precedence for various routines are the same as
 # above in [::CommentLine].
 #  
 # --------------------------------------------------------------------------
 ##

proc comment::undoLine {} {
    hook::callProcForWin UncommentLine
}

proc ::UncommentLine {} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit]} {return 0}
    set win   [win::Current]
    set ext   [file extension $win]
    set chars [comment::Characters Paragraph]
    
    if {[string trim [lindex $chars 0]] == [string trim [lindex $chars 1]]} {
	# Comment chars are either not defined, or the beginning and ending
	# 'Paragraph' chars are the same.  Use default prefix/suffix procs,
	# so long as the mode has defined them.
	if {([win::getModeVar $win prefixString ""] ne "")} {
	    removePrefix
	    set didSomething 1
	}
	if {([win::getModeVar $win suffixString ""] ne "")} {
	    removeSuffix
	    set didSomething 1
	}
	if {![info exists didSomething]} {
	    status::msg "'$::mode' mode does not have comment characters defined."
	    return 0
	}
    } elseif {[isSelection]} {
	# We know that the mode has unique 'paragraph' style comment chars.
	comment::undoParagraph
    } else {
	# Could possibly call [removePrefix] and [removeSuffix] here,
	# although by doing this we only have to perform one 'reselect'.
	# Could also do this using "prefixString" and "suffixString" vars.
	set pos0 [pos::lineStart]
	set pos1 [getPos]
	set txt1 [getText $pos0 $pos1]
	set pat1 "^[quote::Regfind [lindex $chars 0]]"
	if {[regsub -- $pat1 $txt1 "" txt1]} {
	    replaceText $pos0 $pos1 $txt1
	    set pos1 [pos::math $pos0 + [string length $txt1]]
	}
	set pos2 [pos::lineEnd]
	set txt2 [getText $pos1 $pos2]
	set pat2 "[quote::Regfind [lindex $chars 1]]\$"
	if {[regsub -- $pat2 $txt2 "" txt2]} {
	    replaceText $pos1 $pos2 $txt2
	}
	goto $pos1
    }
    return 1
}

## 
 # --------------------------------------------------------------------------
 #       
 # "comment::Paragraph" "comment::undoParagraph"  --
 #      
 # Attempts to locate the current paragraph surrounding the cursor if no
 # selection, and then uses mode specific comment characters to comment /
 # uncomment this paragraph.  We replace the text all in one chunk to make
 # 'undo' a single action.
 # 
 # Author: Vince Darley <mailto:vince@santafe.edu> 
 # 
 # --------------------------------------------------------------------------
 ##

proc comment::Paragraph {} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit] || ![GetRegion Paragraph 0]} {
	return 0
    } elseif {![llength [set commentList [Characters Paragraph]]]} {
	status::msg "'$::mode' mode has not defined any 'Paragraph' comment characters."
	return 0
    }
    watchCursor
    set begComment [lindex $commentList 0]
    set endComment [lindex $commentList 1]
    set fillChar   [lindex $commentList 2]
    # First make sure we grab a full block of lines.
    set pos0 [pos::lineStart [getPos]]
    set pos1 [pos::nextLineStart [pos::math [selEnd] - 1]]
    set txt  [getText $pos0 $pos1]
    # Next turn it into a list of lines -- possibly drop an empty 'last line'.
    # Convert tabs to spaces.
    set lineList [list]
    foreach l [split $txt "\n\r"] {lappend lineList [text::maxSpaceForm $l]}
    set ll [llength $lineList]
    if {[lindex $lineList end] == {}} {
	set lineList [lrange $lineList 0 [expr {$ll -2}] ]
    }
    set numLines [llength $lineList]
    # Find left margin for these lines.
    set lmargin 100
    foreach l $lineList {
	set lm [expr {[string length $l] - [string length [string trimleft $l]]}]
	if {$lm < $lmargin} {set lmargin $lm}
    }
    set ltext ""
    for {set i 0} {$i < $lmargin} {incr i} {append ltext " "}
    # For each line add stuff on left and concatenate everything into 'txt'. 
    set ltext1 [text::minSpaceForm $ltext]
    set ltext2 [text::minSpaceForm ${ltext1}${fillChar}]
    set txt ${ltext1}${begComment}\r
    foreach l $lineList {
	append txt ${ltext2} [string range $l $lmargin end] \r
    }
    append txt ${ltext1} ${endComment} \r
    # Now replace the old stuff, and highlight.
    replaceText $pos0 $pos1 $txt
    selectText $pos0 [pos::math $pos0 + [string length $txt]]
    return 1
}

proc comment::undoParagraph {} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit] || ![GetRegion Paragraph 1]} {
	return 0
    } elseif {![llength [set commentList [Characters Paragraph]]]} {
	status::msg "'$::mode' mode has not defined any 'Paragraph' comment characters."
	return 0
    }
    watchCursor
    set begComment [lindex $commentList 0]
    set endComment [lindex $commentList 1]
    set fillChar   [lindex $commentList 2]
    set aSpace     " "
    set aTab       \t
    # First make sure we grab a full block of lines.
    set pos0 [lineStart [getPos]]
    set pos1 [nextLineStart [pos::math [selEnd] - 1]]
    set txt  [getText $pos0 $pos1]
    # Find left margin for these lines.
    set first [string first "\r" $txt]
    if {$first == -1} {
	set first [string first "\n" $txt]
    }
    set l1 [string range $txt 0 $first]
    set l2 [string trimleft $l1]
    set lmargin [expr {[string length $l1] - [string length $l2]}]
    # Make sure we're at the start and end of the paragraph.
    set startOK    [string first $begComment $txt]
    set endOK      [string last  $endComment $txt]
    set endOKIndex [expr {[string length $txt] - [string length $endComment] - 1}]
    if {$startOK != $lmargin || ($endOK != $endOKIndex || $endOK == -1)} {
	alertnote "You must highlight the entire comment paragraph, including the tail ends."
	status::msg "Cancelled -- could not identify commented paragraph boundaries."
	return 0
    }
    # Next turn it into a list of lines -- possibly drop an empty 'last line'.
    # Convert tabs to spaces.
    set lineList [list]
    foreach l [split $txt "\n\r"] {lappend lineList [text::maxSpaceForm $l]}
    set ll [llength $lineList]
    if {[lindex $lineList end] == {}} {
	set lineList [lrange $lineList 0 [expr {$ll -2}] ]
    }
    set numLines [llength $lineList]
    # Delete the first and last lines, recompute number of lines.
    set lineList [lreplace $lineList [expr {$numLines-1}] [expr {$numLines-1}] ]
    set lineList [lreplace $lineList 0 0 ]
    set numLines [llength $lineList]
    # Get the left margin.
    set lmargin [string first $fillChar [lindex $lineList 0]]
    set ltext ""
    for {set i 0} {$i < $lmargin} {incr i} {append ltext " "}
    set ltext [text::minSpaceForm $ltext]
    # For each line trim stuff on left and spaces and stuff on right and splice.
    set eliminate $fillChar$aSpace$aTab
    set dropFromLeft [expr {[string length $fillChar] + $lmargin}]
    set txt ""
    foreach thisLine $lineList {
	set thisLine [string trimright $thisLine $eliminate]
	set thisLine ${ltext}[string range $thisLine $dropFromLeft end]
	append txt $thisLine \r
    }
    # Now replace the old stuff, and highlight.
    replaceText $pos0 $pos1 $txt
    selectText $pos0 [pos::math $pos0 + [string length $txt]]
    return 1
}

## 
 # --------------------------------------------------------------------------
 #       
 # "comment::Box" "comment::undoBox"  --
 #      
 # Attempts to locate the current paragraph surrounding the cursor if no
 # selection, and then uses mode specific comment characters to comment / 
 # uncomment this paragraph, placing the text in a comment box.  We replace
 # the text all in one chunk to make 'undo' a single action.
 # 
 # Author: Vince Darley <vince@santafe.edu> 
 # 
 # --------------------------------------------------------------------------
 ##

proc comment::Box {} {

    # Preliminaries
    if {![win::checkIfWinToEdit] || ![GetRegion Box 0]} {
	return 0
    } elseif {![llength [set commentList [Characters Box]]]} {
	status::msg "'$::mode' mode has not defined any 'Box' comment characters."
	return 0
    }
    watchCursor
    set begComment  [lindex $commentList 0]
    set begComLen   [lindex $commentList 1]
    set endComment  [lindex $commentList 2]
    set endComLen   [lindex $commentList 3]
    set fillChar    [lindex $commentList 4]
    set spaceOffset [lindex $commentList 5]
    set aSpace       " "
    # First make sure we grab a full block of lines.
    set pos0 [lineStart [getPos]]
    set pos1 [nextLineStart [pos::math [selEnd] - 1]]
    set txt  [getText $pos0 $pos1]
    # Next turn it into a list of lines -- possibly drop an empty 'last line'.
    # Convert tabs to spaces.
    set lineList [list]
    foreach l [split $txt "\n\r"] {lappend lineList [text::maxSpaceForm $l]}
    set numLines [llength $lineList]
    if {[lindex $lineList end] == {}} {
	set lineList [lrange $lineList 0 [expr {$numLines -2}]]
	set numLines [llength $lineList]
    }
    # Find the longest line length and determine the new line length.
    set maxLength 0
    foreach thisLine $lineList {
	set thisLength [string length $thisLine]
	if {$thisLength > $maxLength} {
	    set maxLength $thisLength 
	}
    }
    set newLength [expr {$maxLength + 2 + 2*$spaceOffset}]
    # Now create the top & bottom bars and a blank line.
    set topBar $begComment
    for {set i 0} {$i < [expr {$newLength - $begComLen}]} {incr i} {
	append topBar $fillChar
    }
    set botBar ""
    for {set i 0} {$i < [expr {$newLength - $endComLen}]} {incr i} {
	append botBar $fillChar
    }
    append botBar $endComment
    set blankLine $fillChar
    for {set i 0} {$i < [expr {$newLength - 2}]} {incr i} {
	append blankLine " "
    }
    append blankLine $fillChar
    # For each line add stuff on left and spaces and stuff on right for box
    # sides and concatenate everything into 'txt'.  Start with topBar; end
    # with botBar.
    set txt $topBar\r$blankLine\r
    set frontStuff $fillChar
    set backStuff  $fillChar
    for {set i 0} {$i < $spaceOffset} {incr i} {
	append frontStuff " "
	set backStuff $aSpace$backStuff
    }
    set backStuffLen [string length $backStuff]
    
    foreach thisLine $lineList {
	set thisLine ${frontStuff}${thisLine}
	set thisLength [string length $thisLine]
	set howMuchPad [expr {$newLength - $thisLength - $backStuffLen}]
	for {set j 0} {$j < $howMuchPad} {incr j} {append thisLine " "}
	append thisLine $backStuff
	append txt $thisLine \r
    }
    
    append txt $blankLine \r $botBar \r
    # Now replace the old stuff, and highlight.
    replaceText $pos0 $pos1 $txt
    selectText $pos0 [pos::math $pos0 + [string length $txt]]
    return 1
}

proc comment::undoBox {} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit] || ![GetRegion Box 1]} {
        return 0
    } elseif {![llength [set commentList [Characters Box]]]} {
        status::msg "'$::mode' mode has not defined any 'Box' comment characters."
        return 0
    }
    watchCursor
    set begComment  [lindex $commentList 0]
    set begComLen   [lindex $commentList 1]
    set endComment  [lindex $commentList 2]
    set endComLen   [lindex $commentList 3]
    set fillChar    [lindex $commentList 4]
    set spaceOffset [lindex $commentList 5]
    set aSpace      " "
    set aTab        \t
    # First make sure we grab a full block of lines.
    set pos0 [lineStart [getPos]]
    set pos1 [nextLineStart [pos::math [selEnd] - 1]]
    set txt  [getText $pos0 $pos1]
    # Make sure we're at the start and end of the box.
    set startOK    [string first $begComment $txt]
    set endOK      [string last  $endComment $txt]
    set endOKIndex [expr {[string length $txt] - $endComLen - 1}]
    if {$startOK != 0 || ($endOK != $endOKIndex || $endOK == -1)} {
        alertnote "You must highlight the entire comment box, including the borders."
        status::msg "Cancelled -- could not identify commented box boundaries."
        return 0
    }
    # Next turn it into a list of lines -- possibly drop an empty 'last line'.
    # Convert tabs to spaces.
    set lineList [list]
    foreach l [split $txt "\n\r"] {lappend lineList [text::maxSpaceForm $l]}
    set ll [llength $lineList]
    if {[lindex $lineList end] == {}} {
        set lineList [lrange $lineList 0 [expr {$ll -2}] ]
    }
    set numLines [llength $lineList]
    # Delete the first and last lines, recompute number of lines.
    set lineList [lreplace $lineList [expr {$numLines-1}] [expr {$numLines-1}] ]
    set lineList [lreplace $lineList 0 0 ]
    set numLines [llength $lineList]
    # Eliminate 2nd and 2nd-to-last lines if they are empty.
    set eliminate $fillChar$aSpace$aTab
    set thisLine [lindex $lineList [expr {$numLines-1}]]
    set thisLine [string trim $thisLine $eliminate]
    if {[string length $thisLine] == 0} {
        set lineList [lreplace $lineList [expr {$numLines-1}] [expr {$numLines-1}] ]
    }
    set thisLine [lindex $lineList 0]
    set thisLine [string trim $thisLine $eliminate]
    if {[string length $thisLine] == 0} {
        set lineList [lreplace $lineList 0 0 ]
    }
    set numLines [llength $lineList]
    # For each line trim stuff on left and spaces and stuff on right and splice.
    set dropFromLeft [expr {$spaceOffset+1}]
    set txt ""
    foreach thisLine $lineList {
        set thisLine [string trimright $thisLine $eliminate]
        set thisLine [string range $thisLine $dropFromLeft end]
        if {[regexp -- "^\[\t \]+" $thisLine ltext]} {
            set ltext [text::minSpaceForm $ltext]
            set thisLine ${ltext}[string trimleft $thisLine]
        }
        append txt $thisLine \r
    }
    # Now replace the old stuff, and highlight.
    replaceText $pos0 $pos1 $txt
    selectText $pos0 [pos::math $pos0 + [string length $txt]]
    return 1
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Comment Templates ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "comment::newComment" --
 # 
 # Based on the package 'newJavaDocComment', this proc will insert a new
 # 'paragraph' style comment in the current window.  The template can be
 # easily modified by the user in a mode specific way.
 # 
 # Adds a new comment at the beginning of the current command, assuming that
 # we are currently inside one.  If we end up at the top of the file, then
 # assume that the "previous" command could not be found, so simply insert
 # the new comment at the beginning of this line.
 # 
 # The "insertWhere" argument can be set to 1 if the mode uses paragraphs
 # to determine the start/end of commands, as in Fort mode, or "0" to
 # insert it at the start of a command.  "-1" simply inserts at the
 # beginning of the line containing the current insertion point.
 # 
 # Author: Craig Barton Upright <cupright@alumni.princeton.edu>
 # 
 # --------------------------------------------------------------------------
 ##

proc comment::newComment {{insertWhere "-1"}} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit]} {return 0}
    
    # Should we go to the start of this command/paragraph?.
    set pos [getPos]
    if {$insertWhere == "-1"} {
	set pos [lineStart $pos]
    } elseif {!$insertWhere} {
	set results [function::inFunction $pos]
	set result  [lindex $results 0]
	set start   [lindex $results 1]
	if {$result} {set pos $start} else {set pos [lineStart $pos]}
    } else {
	set pos [paragraph::start $pos]
    }
    # Insert the new paragraph comment template.
    global mode
    global ${mode}modeVars
    if {[info exists ${mode}modeVars(commentTemplate)]} {
	set elecInsert [set ${mode}modeVars(commentTemplate)]
    } elseif {[llength [set commentList [Characters Paragraph]]]} {
	set cc1 [lindex $commentList 0]
	set cc2 [lindex $commentList 1]
	set cc3 [lindex $commentList 2]
	set elecInsert "${cc1}\r${cc3}¥comment body¥\r${cc2}\r¥¥"        
    }
    if {[info exists elecInsert]} {
	placeBookmark 0
	goto $pos
	elec::Insertion $elecInsert
	status::msg "Press <Ctrl>-. to return to original cursor position."
	return 1
    } else {
	commentTemplate
	error "cancel"
	return 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "comment::commentTemplate" --
 # 
 # Requires that a selection be highlighted.  Take the highlighted selection
 # and use it for the mode's "commentTemplate" preference.
 # 
 # Author: Craig Barton Upright <cupright@alumni.princeton.edu>
 # 
 # --------------------------------------------------------------------------
 ##

proc comment::commentTemplate {} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit]} {return 0}
    
    set question "Save selection as the $::mode comment template?"
    if {![string length [set template [getSelect]]]} {
	alertnote "To create a custom template,\
	  type it in your document, highlight it, and then\
	  select the 'Comment Template' menu item.  To enter\
	  template stops, press '<option> 8' \
	  -- be sure to include TWO bullets for every stop."
	return 0
    } elseif {[askyesno $question] == "yes"} {
	global mode
	glob ${mode}modeVars
	set ${mode}modeVars(commentTemplate) "$template"
	prefs::modified ${mode}modeVars(commentTemplate)
	status::msg "The new comment template for '$::mode' mode has been added."
	return 1
    } else {
	status::msg "Cancelled."
	return 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "comment::insertDivider" --
 # 
 # Inserts a properly commented divider line with any selected text centered
 # or with a prompt at the center if there is no selection.
 #  
 # Borrowed from Tcl mode's insertDivider
 #  
 # Suggested bindings:
 #  
 #   Bind    '-'   <cz>     comment::insertDivider
 #   Bind    '='   <cz>     {comment::insertDivider =}
 #  
 # Author: Jon Guyer <jguyer@his.com>
 #  
 # --------------------------------------------------------------------------
 ##

proc comment::insertDivider {{char -}} {
    
    # Preliminaries
    if {![win::checkIfWinToEdit]} {
	return 0
    } elseif {![llength [set commentList [Characters Box]]]} {
	status::msg "'$::mode' mode has not defined any 'Box' comment characters."
	return 0
    }
    set begComment [lindex $commentList 0]
    set begComLen  [lindex $commentList 1]
    set endComment [lindex $commentList 2]
    set endComLen  [lindex $commentList 3]
    
    set dividerLength [expr {[win::getModeVar [win::Current] fillColumn] \
      - $begComLen - $endComLen - 2}]
    
    set prefix [format "%-${begComLen}s" $begComment]
    set suffix [format "%${endComLen}s" $endComment]
    
    if {[isSelection]} {
	set enfoldThis [getSelect]
	set dividerLength [expr {$dividerLength - [string length $enfoldThis]}]
    } else {
	set enfoldThis "¥¥"
    }
    
    set divider [format "%-${begComLen}s%s %s %s%${endComLen}s" \
      $begComment \
      [string repeat $char [expr {$dividerLength / 2}]] \
      $enfoldThis \
      [string repeat $char [expr {$dividerLength - $dividerLength / 2}]] \
      $endComment \
      ]
    
    if {[isSelection]} {
	beginningOfLine
	killLine
	insertText $divider
    } else {
	elec::Insertion $divider
    }
    return 1
}

proc comment::dividingLine {} {
    if {![catch {win::getModeVar [win::Current] prefixString} str]} {
	set a [string trim $str]
    } elseif {[llength [set commentCharList [comment::Characters "General"]]]} {
	set a [string trim [lindex $commentCharList 0]]
    } else {
	# if a mode didn't define any of these then perhaps it doesn't want
	# comment chars, so we just insert a dividing line without leading
	# comment --- trying to guess what the char might be is hopeless.
	set a "="
    }
    insertText "${a}===============================================================================\r"
}

# ===========================================================================
# 
# .