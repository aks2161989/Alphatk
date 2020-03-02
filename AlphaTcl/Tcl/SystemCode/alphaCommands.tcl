## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "alphaCommands.tcl"
 #                                    created: 03/18/1998 {01:13:44 AM} 
 #                                last update: 03/24/2004 {03:13:47 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #  
 # Copyright (c) 1999-2004 Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution of
 # this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #  
 #  Description: 
 # 
 #   Mostly procedures which would really help Alpha if they were
 #   hard-coded.  Some other procedures for convenience are here too.
 # ###################################################################
 ##

if {${alpha::platform} != "alpha"} {
    alertnote "Shouldn't load this code!"
    return
}

# Not sure if this should really deal with rectangular selections
proc selectLimits {args} {
    win::parseArgs w
    if {[pos::compare -w $w [getPos -w $w] == [selEnd -w $w]]} {
	return [list]
    } else {
	return [list [getPos -w $w] [selEnd -w $w]]
    }
}

namespace eval tmark {}
namespace eval mark {}

proc tmark::getPos {args} { 
    win::parseArgs w m
    lindex [getPosOfTMark -w $w $m] 0
}

# We should just rename Alpha's core command to 'tmark::getRange'
proc tmark::getRange {args} { 
    win::parseArgs w m
    getPosOfTMark -w $w $m
}

# We should just rename Alpha's core command to 'mark::getRange'
proc mark::getRange {args} { 
    win::parseArgs w m
    getPosOfMark -w $w $m
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tmark::getPositions" --
 # 
 #  For speed you can ask for a bunch of positions at once.
 # -------------------------------------------------------------------------
 ##
proc tmark::getPositions {mm} {
    foreach m $mm {
	lappend res [lindex [getPosOfTMark $m] 0]
    }
    return $res
}

proc tmark::isAt {p} { return [isTMarkAt $p] }

# ===========================================================================
# 
# ×××× Window Colors ×××× #
# 
# Both [text::hyper] and [text::color] are defined in the Alphatk core.  One
# should _never_ use [insertColorEscape] in AlphaTcl, as this is definately
# not cross-platform compatible!  All of the annotation here should apply
# equally for Alpha8/X and Alphatk, except where noted otherwise.
# 

namespace eval text {}

## 
 # --------------------------------------------------------------------------
 # 
 # "text::hyper" --
 # 
 # Create a hyperlink for the given window.  Arguments include
 # 
 #     ?-w <windowName>? <pos0> <pos1> <hyperText>
 # 
 # where "pos0" and "pos1" are valid positions and "hyperText" is the text
 # that should be evaluated at the top level of the stack when the user
 # clicks on the newly created hyperlink.  If ?-w <windowName>?  is not
 # supplied, then the hyperlink is created for the active window.  This text
 # can make use of any global variables currently available.  It should not
 # start/end with [], but can includes such calls within the text, as in
 # 
 #     text::hyper [pos::lineStart] [pos::lineEnd] {alertnote [win::Current]}
 # 
 # Hyperlinks created by this procedure are always underlined.  If you also
 # want to add colours to the hyperlink, you must do so using [text::color]
 # with the exact same position arguments, as in
 # 
 #     text::hyper [pos::lineStart] [pos::lineEnd] "tclShell"
 #     text::color [pos::lineStart] [pos::lineEnd] "3"
 # 
 # Colors will not be immediately visible, call [refresh] after all window
 # colors have been added.  See the notes below for more information.
 # 
 # --------------------------------------------------------------------------
 ##

proc text::hyper {args} {
    
    win::parseArgs w pos0 pos1 hyperText
    
    text::color -w $w $pos0 $pos1 15 $hyperText
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "text::color" --
 # 
 # Colour a given region in the given window.  Arguments include
 # 
 #     ?-w <windowName>? <pos0> <pos1> <colour> ?<hyperText>?
 # 
 # where "pos0" and "pos1" are valid positions and "colour" is either the
 # actual name or a valid index.  Color indices can be in the range [1-7],
 # while styles are in [9-15].  "0" is actually a marker indicating that all
 # colours/styles should stop at that position.  If ?-w <windowName>?  is not
 # supplied, then the colours are added for the active window.
 # 
 # Color/style index numbers for Alpha8/X include:
 # 
 #     none       0
 #     blue       1
 #     cyan       2
 #     green      3
 #     magenta    4
 #     red        5
 #     white      6
 #     yellow     7
 #     
 #     bold       8
 #     condense   9
 #     extend     10
 #     italic     11
 #     normal     12
 #     outline    13
 #     shadow     14
 #     underline  15
 # 
 # Colour indices correspond to those used by Alphatk, but this is might not
 # be the case for style indices.  (We really need to document what the
 # differences might be, but see [colors::validStyles] for now -- this lists
 # the textual values that can be passed along here.)
 # 
 # While a single color and a single style can be added to the same region,
 # it is not possible to mix and match multiple styles and colors.  There is
 # no "bold-italic" available, and the last style applied with this procedure
 # will always take precedence.  In Alpha8/X, it is also possible for the
 # colour/style to be the name as it appears above, but for optimum
 # compatibility with Alphatk it is safest to use the numerical index value.
 # 
 # Also note that while the core command [regModeKeywords] uses the same set
 # of colour index values for [1-7] (or the actual color names), the list of
 # styles is meaningless for that command.
 # 
 # An optional "hyperText" argument will also create a hyperlink for the
 # given positions using the color/style provided.  This text will be
 # evaluated at the top level of the stack when the user clicks on the newly
 # created hyperlink.  (Technically, the core command [insertColorEscape]
 # accepts an optional "hyperText" argument for any given color and creates
 # the hyperlink so long as the text isn't an empty string.  Mainly for
 # legacy reasons, AlphaTcl always underlines hypertext strings to make it
 # more obvious to the user.  For this reason hypertext is _only_ created by
 # this procedure if the associated 'colour' is "15".)
 # 
 # Colors will not be immediately visible, call [refresh] after all window
 # colors have been added.  (For recursive coloring, [refresh] can be a
 # little bit labor-intensive, so it's best to just call it once at the end.)
 # Alphatk never requires [refresh] and defines it as a dummy procedure, btw,
 # but Alpha8/X always requires this.  Without this call, the colors won't be
 # visible until the window is hidden and then brought back to the front.
 # 
 # --------------------------------------------------------------------------
 ##

proc text::color {args} {
    
    win::parseArgs w pos0 pos1 colour {hyperText ""}
    
    if {[is::Integer $colour]} {
	if {($colour > 7)} {
	    if {($colour == 15)} {
		insertColorEscape -w $w $pos0 $colour $hyperText
	    } else {
		insertColorEscape -w $w $pos0 $colour
	    }
	    insertColorEscape -w $w $pos1 12
	} else {
	    insertColorEscape -w $w $pos0 $colour
	    insertColorEscape -w $w $pos1 0
	}
    } else {
	insertColorEscape -w $w $pos0 $colour
	insertColorEscape -w $w $pos1 12
	insertColorEscape -w $w $pos1 0
    }
    return
}

# ===========================================================================
# 
# .