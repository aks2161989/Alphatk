## -*-Tcl-*-
# ===========================================================================
# File: "m4Mode.tcl"
#                        Created: 2005-04-02 01:18:02
#              Last modification: 2005-04-02 10:20:39
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# (c) Copyright: Bernard Desgraupes 2005
# All rights reserved.
# 
# Distributed under a Tcl-style BSD license.
# 
# ===========================================================================

alpha::mode m4 0.1 source {*.m4 *.ac *.am} {} {
    # Script to execute at Alpha startup
} maintainer {
    {Bernard Desgraupes} <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/>
} uninstall {
    this-file
} description {
    Supports the editing of "m4" files.
} help {
    Supports editing of files for 'm4' the UNIX macro processor 
    (see http://www.gnu.org/software/m4/manual/m4.html). 
    
    This mode currently supports file marking, syntax coloring and word
    completion. To quote a word or a selection, use cmd-'. This will
    enclose the word or the selected area between ` ' quotes, which are
    m4's default quotes. These can be modified with the "leftQuote" and
    "rightQuote" preferences in m4 mode.
}

proc m4Mode.tcl {} {}

namespace eval m4 {}

# ×××× mode preferences ×××× #

newPref f autoMark 0 m4
newPref v prefixString {# } m4
newPref var wordBreak {[_\w]+} m4
newPref var leftQuote {`} m4
newPref var rightQuote {'} m4

# Default colors for the m4 keywords
newPref color commentColor red m4 
newPref color funcColor magenta m4 
newPref color keywordColor blue m4 
newPref color stringColor green m4 


set m4::commentCharacters(General) "#"
set m4::commentCharacters(Paragraph) [list "## " " ##" " # "]
set m4::commentCharacters(Box) [list "#" 1 "#" 1 "#" 3]


# Syntax coloring
# ---------------

set m4Keywords [list __file__ __line__ builtin changecom changequote \
  changeword debugfile \ debugmode decr define defn divert divnum dnl dumpdef \
  errprint esyscmd eval file format gnu ifdef ifelse include incr index indir \
  len line m4exit m4wrap m4temp patsubst popdef pushdef regexp shift sinclude \
  substr syscmd sysval traceoff traceon translit undefine undivert unix ]

regModeKeywords -C m4 {}
regModeKeywords -a -c $m4modeVars(commentColor) -k $m4modeVars(keywordColor) \
  -f $m4modeVars(funcColor) -s $m4modeVars(stringColor) -e {#} -i "\$" m4 $m4Keywords


# Completions
# -----------

set completions(m4) {completion::cmd completion::electric}

set m4cmds [lsort -dictionary $m4Keywords]
unset m4Keywords

# # # # # # abbreviations # # # # #
set m4electrics(ifdef) "(`¥¥', ¥¥, ¥¥)\r"
set m4electrics(ifelse) "(¥¥, ¥¥, ¥¥, ¥¥)\r"
set m4electrics(define) "(`¥¥',`¥¥')\r"


# File marking
# ------------
# Mark the user defined macros. The syntax to define an m4 macro is:
#     define(name [, expansion])
# It is also possible to redefine a macro temporarily using the builtin pushdef:
# 	  pushdef( name  [, expansion ])

proc m4::MarkFile {args} {
    win::parseArgs win
    status::msg "MarkingÉ"
    set pos [minPos]
    set markExpr {(define|pushdef|AC_DEFUN)\s*\(\s*[^,) ]+}
	
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 $markExpr $pos} match]} {
	set start [lindex $match 0]
	set end   [lindex $match 1]
	set text  [getText -w $win $start $end]
	if {[regexp {\(\s*([^,) ]+)} $text -> word]} {
	    setNamedMark -w $win $word $start $start $start
	    set pos [nextLineStart -w $win $end]
	} 
    }
    status::msg ""
}


proc m4::quote {} {
    global m4modeVars
    if {[isSelection]} {
	set p0 [getPos]
	set p1 [selEnd]
    } else {
	backwardWord    
	set p0 [getPos]
	forwardWord
	set p1 [getPos]
	selectText $p0 $p1
    }
    set txt [getText $p0 $p1]
    deleteSelection
    insertText "$m4modeVars(leftQuote)$txt$m4modeVars(rightQuote)"
}


# Key bindings
# ------------
Bind 0x15 <c> m4::quote m4
