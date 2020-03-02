## -*-Tcl-*-
 # ###################################################################
 #  JavaScript mode - tools for editing JavaScript documents
 # 
 #  FILE: "javaScriptMode.tcl"
 #                                    created: 97-02-09 13.00.54 
 #                                last update: 03/21/2006 {03:10:09 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 1.1.3
 # 
 # Copyright 1997-2006 by Johan Linde
 #  
 # This software may be used freely, and distributed freely, as long as the 
 # receiver is not obligated in any way by receiving it.
 #  
 # If you make improvements to this file, please share them!
 # 
 # ###################################################################
 ##

alpha::mode [list JScr JavaScript] 1.1.4 JScrDummy {*.js} {
    specialIndentForCaseLabel
} {
    # Script to execute at Alpha startup
} uninstall {
    this-file
} maintainer {
    "Johan Linde" <alpha_www_tools@go.to> <http://go.to/alpha_www_tools>
} description {
    Supports the editing of JavaScript programming files
} help {
    file "HTML Help"
}

proc javaScriptMode.tcl {} {}

prefs::removeObsolete JScrmodeVars(elecRBrace)
prefs::removeObsolete JScrmodeVars(elecLBrace)
prefs::removeObsolete JScrmodeVars(electricSemi)
prefs::removeObsolete JScrmodeVars(electricTab)
prefs::removeObsolete JScrmodeVars(electricColon)

newPref v prefixString {//}  JScr
newPref var lineWrap 0 JScr
newPref v funcExpr {^[ \t]*function *([-a-zA-Z0-9+]+)} JScr
newPref v parseExpr {^[ \t]*function *([-a-zA-Z0-9+]+)} JScr
newPref v wordBreak {\w+} JScr
newPref v stringColor	green JScr
newPref v commentColor red JScr
newPref v keywordColor blue JScr
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 JScr
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 JScr
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 JScr

regModeKeywords -C {JScr} {}
regModeKeywords -a -e {//} -b {/*} {*/} -c $JScrmodeVars(commentColor) \
  -k $JScrmodeVars(keywordColor)  \
  -s $JScrmodeVars(stringColor) JScr {
    break case continue default delete do export for import in
    function if else new return switch this typeof var void while
    with true false 
}

proc JScrDummy {} {}

proc JScr::carriageReturn {} {
	global indentOnReturn specialIndentForCaseLabel
	if {$specialIndentForCaseLabel && [lookAt [pos::math [getPos] - 1]] == ":"} {
		if { [lookAt [getPos]] == "\r" } {
			catch {bind::IndentLine}
			endOfLine
			insertText "\r"
		} else {
			set pos [getPos]
			endOfLine
			set t [getText $pos [getPos]]
			replaceText $pos [getPos] ""
			catch {bind::IndentLine}
			endOfLine
			insertText "\r"
			insertText $t
		}
	} else {
		insertText "\r"
	}
	if {$indentOnReturn} {catch {bind::IndentLine}}
}

proc JScr::DblClick {from to} {
	global HOME
	selectText $from $to
	set word [getText $from $to]
	if {[grep "^${word}( |$)" [lindex [glob [file join $HOME JSreference index*]] 0]] != ""} {
		editMark [lindex [glob [file join $HOME JSreference JS*]] 0] $word -r
	} elseif {[lsearch -exact {break continue for function if else new return this var while with} $word] >= 0} {
		if {$word == "if" || $word == "else"} {set word "if...else"}
		editMark [lindex [glob [file join $HOME JSreference statements]] 0] $word -r
	}
}

proc JScr::correctIndentation {args} {
	eval ::correctBracesIndentation $args
}

set JScr::commentCharacters(General) [list "//"]
set JScr::commentCharacters(Paragraph) [list "/* " " */" " * "]
set JScr::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]

