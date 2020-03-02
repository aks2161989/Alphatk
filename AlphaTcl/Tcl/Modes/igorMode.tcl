## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 #  Igor Mode - an extension package for Alpha
 # 
 #  FILE: "igorMode.tcl"
 #                                    created: 02/02/2000 {07:07:26 pm} 
 #                                last update: 05/23/2006 {10:40:33 AM} 
 #  Description: 
 #  
 #  Alpha mode for editing and viewing Igor syntax files.
 #                                 
 #  Author: ?
 #  
 #  Includes contributions from Jon Guyer and Craig Barton Upright
 #  
 # -------------------------------------------------------------------
 #  
 # Copyright (c) 2001-2006
 # All rights reserved.
 # 
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
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
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 # ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
 # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 # DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 # CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 # LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 # OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 # DAMAGE.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of Igor mode ×××× #
# 

alpha::mode Igor 1.1.1 igorMenu {*.igor *.ipf} {
    igorMenu
} {
    # Script to execute at Alpha startup
    addMenu igorMenu "¥284"
    set modeCreator(IGR0) Igor
} uninstall {
    catch {file delete [file join $HOME Tcl Modes igorMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions IgorCompletions.tcl]}
} maintainer {
} description {
    Supports the editing of Igor programming files
} help {
    Igor Mode supplies a menu for easy switching between Igor and Alpha,
    and provides keyword coloring.

    Click on this "Igor Example.igor" link for an example syntax file.
}

namespace eval Igor {}

# ===========================================================================
#
# ×××× Igor mode preferences ×××× #
# 

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref f autoMark 0 Igor
newPref var lineWrap {0} Igor

newPref v fillColumn     {75} Igor
newPref v leftFillColumn {0}  Igor
newPref v funcExpr {^[ \t]*([pP]roc|[mM]acro|[fF]unction)\s} Igor
newPref v parseExpr {\m([_:\w]+)\s*\(} Igor
newPref v prefixString {// } Igor
newPref v wordBreak {[_\w$]+} Igor
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Igor

# ===========================================================================
#
# Igor mode specific preferences.
#

newPref sig igorSig IGR0 Igor

set Igor::commentCharacters(General) "// "
set Igor::commentCharacters(Paragraph) [list "// " "// " "// "]

# ===========================================================================
#
# ×××× Colorize Igor ×××× #
# 

newPref color commentColor   red     Igor stringColorProc
newPref color funcColor      magenta Igor Igor::colorizeIgor
newPref color keywordColor   blue    Igor Igor::colorizeIgor
newPref color stringColor    green   Igor stringColorProc
# The colour of words started by '$'.
newPref color variablesColor none    Igor Igor::colorizeIgor

set Igorcmds {
    break for if endif do while continue
    return else end variable string wave
    NVAR SVAR
    function proc macro endMacro
    Function Proc Macro EndMacro
}

regModeKeywords -e {//} -c $IgormodeVars(commentColor) \
  -s $IgormodeVars(stringColor) Igor {}

proc Igor::colorizeIgor {{pref ""}} {
    
    global IgormodeVars Igorcmds
    
    regModeKeywords -a -f $IgormodeVars(funcColor) \
      -k $IgormodeVars(keywordColor) Igor $Igorcmds
    regModeKeywords -a -m {$} \
      -k $IgormodeVars(variablesColor) Igor {}
    if {[string length $pref]} {refresh}
}

# Call this now.
Igor::colorizeIgor

# ===========================================================================
# 
# ×××× Mark File, Parse Funcs ×××× #
#

proc Igor::MarkFile {args} {
    
    global IgormodeVars
    
    win::parseArgs w
    
    status::msg "Marking \"[win::Tail $w] É"
    set count 0
    set pat1 $IgormodeVars(funcExpr)
    set pat2 {(^[ \t]*[Mm]enu[^r\n]*$|===[^=]+===\s*$)}
    foreach pat [list $pat1 $pat2] {
	set pos [minPos -w $w]
	while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $pat $pos} match]} {
	    set pos0 [pos::lineStart -w $w [lindex $match 0]]
	    set pos1 [set pos [pos::math -w $w \
	      [pos::nextLineStart -w $w $pos0] - 1]]
	    set mark [markTrim [string trim [getText -w $w $pos0 $pos1]]]
	    set pos2 [pos::math -w $w $pos0 + [string length $mark]]
	    regsub {\(\)} $mark {} mark
	    while {[lcontains marks $mark]} {
		append mark " "
	    }
	    lappend marks $mark
	    setNamedMark -w $w $mark [pos::lineStart -w $w $pos0] $pos0 $pos2
	    incr count
	}
    }
    if {$count} {
	orderMarks
    }
    set msg "The window \"[win::Tail $w]\" contains $count mark"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}

## 
 # -------------------------------------------------------------------------
 #	 
 # "Igor::parseFuncs" --
 #	
 # This proc is called by the "{}" pop-up. It returns a dynamically
 # created, alphabetical, list of "pseudo-marks".
 #	
 # Author: <jguyer@his.com>
 # -------------------------------------------------------------------------
 ##

proc Igor::parseFuncs {} {
    
    global IgormodeVars sortFuncsMenu
    
    set pat1 $IgormodeVars(funcExpr)
    set pat2 {(^[ \t]*[Mm]enu[^\r\n]*$|===[^=]+===\s*$)}
    foreach pat [list $pat1 $pat2] {
	set pos [minPos]
	while {![catch {search -s -f 1 -r 1 -m 0 -i 1 $pat $pos} match]} {
	    set pos0 [lineStart [lindex $match 0]]
	    set pos1 [set pos [pos::math [nextLineStart $pos0] - 1]]
	    set func [markTrim [string trim [getText $pos0 $pos1]]]
	    regsub -all {(^[^\s]+\s+)|\s} $func {} func
	    regsub {\).*} $func {)} func
	    regsub {\(\)} $func {}  func
	    while {[lcontains funcs $func]} {append func " "}
	    lappend funcs $func
	    lappend m [list $func $pos0]
	}
    }
    if {$sortFuncsMenu} {set m [lsort -dictionary $m]}
    return [join $m]
}

# ===========================================================================
#
# ×××× Key Bindings, Indentation ×××× #
# 

# Macro navigation, using 'functions.tcl'

Bind    up  <sz>    {Igor::searchFunc 0 0 0} Igor
Bind  left  <sz>    {Igor::searchFunc 0 0 1} Igor
Bind  down  <sz>    {Igor::searchFunc 1 0 0} Igor
Bind right  <sz>    {Igor::searchFunc 1 0 1} Igor

set Igor::startFunction $IgormodeVars(funcExpr)    ;# Start pattern
set Igor::endFunction   {^[\t ]*[eE]nd[mM]acro}    ;# End pattern
set Igor::functionName "macro"

proc Igor::searchFunc {direction args} {
    
    if {![llength $args]} {set args [list 0 2]}
    if {$direction} {
	eval function::next $args
    } else {
	eval function::prev $args
    }
}

proc Igor::carriageReturn {} {
    
    if {[isSelection]} {deleteSelection}
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    set t    [getText $pos1 $pos2]
    set pat  {^([\t ])*(end|endif|endmacro|else)((\s+.*)|$)}
    if {[regexp -nocase $pat $t]} {
	createTMark temp $pos2
	catch {bind::IndentLine}
	gotoTMark temp ; removeTMark temp
    } 
    insertText "\r"
    catch {bind::IndentLine}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Igor::correctIndentation" --
 # 
 # Igor::correctIndentation is necessary for Smart Paste, and returns the
 # correct level of indentation for the current line.  We grab the previous
 # non-commented line, and indent the next line respecting the commands
 # (if|else) or a macro definition to increase the indent, and
 # (end|endif|endmacro|else) to decrease.
 # -------------------------------------------------------------------------
 ##

proc Igor::correctIndentation {args} {
    
    global indentationAmount
    
    win::parseArgs w pos {next ""}
    
    set posBeg   [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine [Igor::getCommandLine -w $w $posBeg 1 1]
    set prevLine [Igor::getCommandLine -w $w [pos::math -w $w $posBeg - 1] 0 1]
    set lwhite   [lindex $prevLine 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine 0] != $posBeg]} {
	set pL [lindex $prevLine 2]
	# Indent if the last line was if|else, or the 
	# beginning of a macro definition.
	set pat1 {^[\t ]*(if|else)((\s+.*)|$)}
	set pat2 {^[\t ]*(proc|macro|function)\s+.+\(}
	if {[regexp -nocase $pat1 $pL]} {
	    incr lwhite $indentationAmount
	} elseif {[regexp -nocase $pat2 $pL]} {
	    incr lwhite $indentationAmount
	}
    } 
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is end|endif|endmacro|else.
	set tL  [lindex $thisLine 2]
	set pat  {^([\t ])*(end|endif|endmacro|else)((\s+.*)|$)}
	if {[regexp -nocase $pat $tL]} {
	    incr lwhite -$indentationAmount
	} 
    } 
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}
##
 # -------------------------------------------------------------------------
 # 
 # "Igor::getCommandLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text
 # of the command line.  If the search for the next/prev command fails,
 # return an indentation level of 0.
 # 
 # -------------------------------------------------------------------------
 ##

proc Igor::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\/ ]}
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
    if {[pos::compare -w $w $posEnd > [maxPos -w $w]] \
      || [pos::compare -w $w $posEnd < $posBeg]} {
	set posEnd [maxPos -w $w]
    } 
    return [list $posBeg $lwhite [getText -w $w $posBeg $posEnd]]
}

# ×××× Igor Menu ×××× #

proc igorMenu {} {}

menu::buildProc igorMenu Igor::buildMenu

proc Igor::buildMenu {} {
    global igorMenu
    set menuList [list \
      "switchToIgor" "(-)"  \
      "/K<U<OopenFileInIgor" \
      "/K<U<O<BswitchFileToIgor" "(-)" \
      "/'<E<S<BnewComment" "/'<S<O<BcommentTemplateÉ" "(-)" \
      "/N<U<BnextMacro" "/P<U<BprevMacro" \
      "/S<U<BselectMacro" "/I<B<OreformatMacro" \
      ]
    return [list build $menuList "Igor::menuProc -M Igor" "" $igorMenu]
}

# Now we actually build the Igor menu.
menu::buildSome igorMenu

proc Igor::registerOWH {{which "register"}} {
    
    global igorMenu
    
    set menuItems {
	openFileInIgor switchFileToIgor 
	newComment commentTemplateÉ
	nextMacro prevMacro selectMacro reformatMacro
    }
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $igorMenu $i] 1
    } 
}

# Call this now.
Igor::registerOWH register ; rename Igor::registerOWH ""

proc Igor::menuProc {menuName itemName} {
    global IgormodeVars
    switch -- $itemName {
	"switchToIgor"   {app::launchFore $IgormodeVars(igorSig)}
	"openFileInIgor" {openAndSendFile $IgormodeVars(igorSig)}
	"switchFileToIgor" {
	    openAndSendFile $IgormodeVars(igorSig)
	    killWindow
	}
	"newComment"      {comment::newComment 0}
	"commentTemplate" {comment::commentTemplate}
	"nextMacro"       {function::next}
	"prevMacro"       {function::prev}
	"selectMacro"     {function::select}
	"reformatMacro"   {function::reformat}
	default           {Igor::$itemName}
    }
}

# ===========================================================================
# 
# ×××× -------------------- ×××× #
# 
# ×××× version history ×××× #
# 
#  modified by  rev    reason
#  -------- --- ------ -----------
#  ?? -> ?? ??  - 1.03 Various updates
#  11/05/01 cbu 1.1    Added Igor::colorizeIgor to actually use color prefs.
#                      Added macro navigation items.
#                      Updated Igor::MarkFile, Igor::parseFuncs for Alphatk.
#                      Added Igor::correctIndentation.
#                      igorSig is now a mode, not global pref.
# 

# ===========================================================================
# 
# .
