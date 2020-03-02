## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Maple Mode - an extension package for Alpha
 #
 # FILE: "mapleMode.tcl"
 #                                          created: 02/02/2000 {07:07:26 pm}
 #                                      last update: 05/23/2006 {10:43:02 AM}
 # Description: 
 # 
 # Alpha mode for editing and viewing Maple programmes.
 #                                
 # Authors: Joachim Kock and Craig Barton Upright
 # E-mail: <kock@math.unice.fr> and <cupright@alumni.princeton.edu>
 # 
 # -------------------------------------------------------------------
 #  
 # Copyright (c) 2001-2006  Joachim Kock and Craig Barton Upright
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
# ×××× Initialization of Maple mode ×××× #
# 

alpha::mode [list mapl Maple] 1.1.5 mapleMenu {*.maple} {
    mapleMenu
} {
    # Script to execute at Alpha startup
    addMenu mapleMenu "¥508" mapl
    set unixMode(maple)       {mapl}
    set unixMode(maple4)      {mapl}
    set unixMode(maple6)      {mapl}
    set unixMode(maplev-4.0a) {mapl}
    set unixMode(maple7)      {mapl}
    set modeCreator(REL4)     {mapl}
    set modeCreator(Mnt4)     {mapl}
} uninstall {
    global HOME
    catch {file delete [file join $HOME Tcl Modes mapleMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions maplCompletions.tcl]}
    catch {file delete [file join $HOME Tcl Completions "mapl Tutorial.maple"]}
} maintainer {
    "Joachim Kock" <kock@math.unice.fr> 
} description {
    Supports the editing of Maple programming files
} help {
    Maple is a functional programming language for doing symbolic computations
    in mathematics.  It is also a commercial programme for interpreting code
    written in this language --- see <http://www.maplesoft.com> .

    mapl mode is meant to facilitate editing (or viewing) Maple source files in
    Alpha.  Click on this "Maple Example.maple" link for an example syntax file.
    Currently mapl mode supports:

      keyword colouring
      file marking
      indentation
      command navigation
      command double-click to locate the definition of a proc.  (Hold down any
        modifier key to show the proc's arguments in the status bar window.)
    
    The Maple menu also supports switching to the Maple application, as well as
    to Mint.  (Mint is the Maple syntax checker and diagnostic tool.)  It seems
    that no version of Maple understands apple events :-( (??)  so there is no
    further interaction available ...
    
    And here are two hints:

    1: It is awkward to to use filename extensions for files to be read by the
    Maple interpreter, since .  is a concat operator in Maple.  Instead, to make
    Alpha recognise that the file belongs to mapl mode, let the first line be

	# -*-mapl-*- (nowrap)

    --- then Alpha will automatically enter mapl mode when opening the file.
    The file suffix '.maple' is attached to this mode merely to help some
    internal Help documents open within Alpha in the proper mode.

    2: It is practical always to save Maple source files in IBM format (i.e.,
    with both carriage returns and linefeeds).  In this way the file can be read
    by Maple on unix systems as well as on the mac.  If you use either mac or
    unix line-endings, when sourcing the file on the other platform, any comment
    char will comment out the rest of the file, due to missing newlines!
}

proc mapleMode.tcl {} {}

namespace eval mapl {}

# ===========================================================================
#
# ×××× mapl mode preferences ×××× #
# 

#=============================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref flag autoMark               0          mapl
newPref var  lineWrap               0          mapl
newPref v commentsContinuation      2          mapl "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 mapl
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 mapl

newPref var  fillColumn        {75}            mapl
newPref var  leftFillColumn    {0}             mapl
newPref var  prefixString      {# }            mapl
newPref var  wordBreak         {\w+}  mapl

set mapl::quotedstringChar "`"
set mapl::lineContinuationChar "\\"





# # ===========================================================================
# #
# # ×××× mapl mode strings ×××× #
# # 
# 
# set maplSpace {[ \t\r\n]+}
# set maplPreSpace {(^| |\t|:|;)}
# 
# set maplString {[a-zA-Z_]+[a-zA-Z_0-9]*}   ;# A string cannot start with a numeral
# set maplNumeral {[0-9]+}
# set maplStringOrNumeral "(${maplString}\|${maplNumeral})"
# # set primitivePreface {[^a-zA-Z_0-9]}
# # set maplStringOrNumeralPreface "${primitivePreface}\|(${maplPreSpace}${maplNumeral})"
# 
# # set maplIndexed "${maplString}(\\[${maplStringOrNumeral}(,${maplStringOrNumeral})*\\])*"
# set maplIndexed {[a-zA-Z_]+[a-zA-Z_0-9]*(\[([a-zA-Z_]+[a-zA-Z_0-9]*|[0-9]+)(,([a-zA-Z_]+[a-zA-Z_0-9]*|[0-9]+))*\])*}
# # (An indexed string is a string followed by a number of []-pairs, each of which is a 
# # sequence of strings or numerals.  (In fact, whitespace is allowed surrounding the 
# # elements of the sequences, but for simplicity we don't support that in the regexp...)
# 
# # the following are used by standard alpha navigation:
# newPref v wordBreak ${maplStringOrNumeral} mapl
# # newPref v wordBreak {[a-zA-Z_0-9]+} mapl
# 
# # the following are used by '::getLimits' for proc navigation:
# set mapl::startFunction "${maplPreSpace}${maplIndexed}(${maplSpace})*:=(${maplSpace})*(proc)((${maplSpace})*\\()"
# set mapl::endFunction "${maplPreSpace}(end)(:|;)"
# set mapl::functionName "proc"
# 
# # # newPref v indexedBreak  ${maplIndexed} mapl
# newPref var  funcExpr   ${mapl::startFunction} mapl
# newPref var  parseExpr  ${mapl::startFunction} mapl





#=============================================================================
#
# Variable preferences
# 

# THE FUNCTION REGULAR EXPRESSION FOR MAPLE:
# alphanumeric (possibly with an [alphanumeric] )
# followed by  :=  (possibly surrounded by whitespace)
# followed by  proc  followed by whitespace or parenthesis:

newPref var  funcExpr  {^[ \t]*([A-Za-z0-9]+(\[[A-Za-z0-9]+\])?)[ \t\r\n]*:=[ \t\r\n]*proc[ \t\(]} mapl
newPref var  parseExpr {^[ \t]*([A-Za-z0-9]+(\[[A-Za-z0-9]+\])?)[ \t\r\n]*:=[ \t\r\n]*proc[ \t\(]} mapl

# These are used by '::getLimits' for proc navigation.

set mapl::startFunction $maplmodeVars(funcExpr)    ;# Start pattern
set mapl::endFunction {( |\t|^|:|;)end(:|;)}  ;# End pattern
set mapl::functionName "proc"

# Click on 'Set' to locate your local Maple application.
newPref sig  mapleSig   REL4   mapl
# Click on 'Set' to locate your local Mint application.
newPref sig  mintSig    Mnt4   mapl

# The "Maple Home Page" menu item will send this url to your browser.
newPref url  mapleHomePage {http://www.maplesoft.com/} mapl

# ===========================================================================
# 
# Color preferences
#

newPref color commentColor      red         mapl {stringColorProc}
newPref color commandColor      blue        mapl {mapl::colorizemapl}
newPref color stringColor       none        mapl {stringColorProc}

# Call this now, so that the rest can be 'adds'.
regModeKeywords -C mapl {}
regModeKeywords -a -e {#} \
  -c $maplmodeVars(commentColor) \
  -s $maplmodeVars(stringColor) \
  mapl {}

# ==========================================================================
# 
# Comment Character variables for Comment Line / Paragraph / Box menu items.
# 

set mapl::commentCharacters(General)     [list "#"]
set mapl::commentCharacters(Paragraph)   [list "# " "# " "# "]
set mapl::commentCharacters(Box)         [list "#" 2 "#" 2 "#" 3]

# ===========================================================================
#
# ×××× Keyword Dictionaries ×××× #
#

set maplcmds {
  ASSERT DEBUG ERROR Im NULL RETURN Re abs add
  addressof alias anames and anything appendto array assemble
  assigned attributes binomial break by
  call callback cat ceil coeff coeffs convert crinterp debugopts
  define degree
  denom description diff disassemble divide do done elif else end entries
  eval evalb evalf evalhf evaln expand fi for from frontend gc genpoly
  getuserinterface global goto has hastype hfarray icontent identical if
  igcd ilog10
  in indets indexed indices inner intersect iolib
  iquo irem isqrt kernelopts lcoeff
  ldegree length lexorder list local lprint macro map map2 matrix max
  maxnorm member min minus mod modp modp1 mods mul
  next nonnegint nops normal not
  numboccur numer od op ops option options
  or order parse pointto posint print
  printf proc protect protected quit rational read
  readlib readline remember remove restart save
  searchtext select seq series setattribute
  setuserinterface sign simplyfy
  sort sscanf stop subs subsop substring sum
  system table taylor tcoeff
  then time timelimit to traperror trunc type typematch unames union
  unprotect userinfo while words writeto
}

# ===========================================================================
#
# ×××× Colorize mapl ×××× #
# 

proc mapl::colorizemapl {{pref ""}} {
    
    global maplmodeVars  maplcmds
    
    regModeKeywords -a -k $maplmodeVars(commandColor) mapl $maplcmds
    
    if {[string length $pref]} {refresh}
}

# Call this now.
mapl::colorizemapl

# ===========================================================================
#
# ×××× Key Bindings, Indentation ×××× #

Bind 0x27    <z>    {mapl::menuProc "$mapleMenu" "insertCommentTemplate"} mapl
Bind 0x27   <cz>    {mapl::menuProc "$mapleMenu" "defineCommentTemplate"} mapl

Bind  's'   <sz>    {function::select} mapl
Bind  'i'   <sz>    {function::reformat} mapl

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev command, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {mapl::searchFunc 0 0 0} mapl
Bind  left  <sz>    {mapl::searchFunc 0 0 1} mapl
Bind  down  <sz>    {mapl::searchFunc 1 0 0} mapl
Bind right  <sz>    {mapl::searchFunc 1 0 1} mapl

# ===========================================================================
# 
# "mapl::carriageReturn" --
# 
# Inserts a carriage return, and indents properly.
# 

#this special carriage return proc is needed eg. to indent a closing fi;
#before performing carriage return
proc mapl::carriageReturn {} {
    #if {[isSelection]} {deleteSelection}  ;#bind::carriageReturn does that!
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    set t    [getText $pos1 $pos2]
    set pat  "^(\[\t \])*(end|else|elif|fi|od)(;|:)?(\[\r\n\t \]|\$)"
    if {[regexp $pat $t]} {
	createTMark temp $pos2
	catch {bind::IndentLine}
	gotoTMark temp ; removeTMark temp
    } 
    insertText "\r"
    catch {bind::IndentLine}
}


# ===========================================================================
# 
# "mapl::correctIndentation" --
# 
# mapl::correctIndentation is necessary for Smart Paste, and returns the
# correct level of indentation for the current line.  We grab the previous
# non-commented line, and indent the next line respecting the commands
# (if|else|elif|for|while) to increase the indent, and (end|else|elif|fi|od)
# to decrease.

# This was the old 'mapl::indentLine' proc.  No longer necessary in AlphaTcl
# 7.4.3, because 'mapl::correctIndentation' will be called instead.

# proc mapl::indentLine {} {
#     set comPat {^[ \t]*#}
#     # opening pattern
#     set openPat {^[ \t]*(if|else|elif|for|while)[ \t\r\n]}
#     # closing pattern
#     set eobPat {^[ \t]*(end|else|elif|fi|od)[ \t\r\n]*(;|:)?[ \t\r\n]}
#     # proc definition pattern
#     set procPat {^[ \t]*[A-Za-z0-9]+[ \t]*:=[ \t]*proc[ \t\(]}
#     
#     # get line to indent
#     set beg [lineStart [getPos]]
#     set currLine [getText $beg [nextLineStart $beg]]
#     regexp -- {^[ \t]*} $currLine white
#     set len [string length $white]
#     
#     # init some vars
#     set begCmt $beg
#     set prvPos $beg
#     set endCmt $beg
#     
#     # find last previous non-comment line and get its leading whitespace
#     
#     while {[pos::compare $begCmt <= $prvPos] && \
#       [pos::compare $endCmt >= $prvPos]} {
# 	
# 	# find the last non-blank line that precedes the comment block
# 	if {![catch {search -f 0 -r 1 -s -i 0 -m 0 \
# 	  {^[ \t]*[^ \t\r]} [pos::math $begCmt -1]} lst]} {
# 	    
# 	    set prvPos [lindex $lst 0]
# 	    set prevLine [getText [lindex $lst 0] [nextLineStart [lindex $lst 0]]]
# 	    set lwhite [getText [lindex $lst 0] [pos::math [lindex $lst 1] - 1]]
# 	    
# 	    # find the next preceding comment block
# 	    if {![catch {search -f 0 -r 1 -s -i 0 -m 0 $comPat $prvPos} lstCmt]} {
# 		set begCmt [lindex $lstCmt 0]
# 		set endCmt [lindex $lstCmt 1]
# 	    } else {
# 		break
# 	    }
# 	    
# 	} else {
# 	    # handle search failure at top-of-file
# 	    if {[pos::compare $beg !=  [minPos]]} {
# 		set prevLine [getText [minPos] [nextLineStart [minPos]]]
# 	    } else {
# 		set prevLine "#\r"
# 	    }
# 	    set lwhite ""
# 	    break
# 	}
#     }
#     # if the preceding line begins a block increase the whitespace
#     if {[regexp -nocase -- $openPat $prevLine] || \
#       [regexp -- $procPat $prevLine]} {
# 	append lwhite "\t"
#     }
#     # if the current line ends a block decrease the whitespace
#     if {[regexp -nocase -- $eobPat $currLine]} {
# 	set lwhite [string range $lwhite 0 [expr [string length $lwhite] - 2]]
#     }
#     # if the current line starts a new function use no whitespace
#     if {[regexp -nocase -- $procPat $currLine allofit subType subVars subName]} {
# 	set lwhite ""
#     }
#     # put in the white space
#     if {$white != $lwhite} {
# 	replaceText $beg [pos::math $beg + $len] $lwhite
#     }
#     goto [pos::math $beg + [string length $lwhite]]
# }

proc mapl::correctIndentation {args} {
    
    global mapl::lineContinuationChar indentationAmount
    
    win::parseArgs w pos {next ""}
    
    set posBeg    [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine  [mapl::getCommandLine -w $w $posBeg 1 1]
    set prevLine1 [mapl::getCommandLine -w $w \
      [pos::math -w $w $posBeg - 1] 0 1]
    set prevLine2 [mapl::getCommandLine -w $w \
      [pos::math -w $w [lindex $prevLine1 0] - 1] 0 1]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine1 0] != $posBeg]} {
	set pL1 [lindex $prevLine1 2]
	# Indent if the last line did not terminate the command.
	if {[string trimright $pL1 [set mapl::lineContinuationChar]] != $pL1} {
	    incr lwhite [expr {$indentationAmount/2}]
	} 
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {[pos::compare -w $w [lindex $prevLine2 0] != [lindex $prevLine1 0]]} {
	    set pL2 [string trim [lindex $prevLine2 2]]
	    if {[string trimright $pL2 [set mapl::lineContinuationChar]] != $pL2} {
		incr lwhite [expr {-$indentationAmount/2}]
	    } 
	} 
	# Indent if the last line was if|else|elif|for|while, or the 
	# beginning of a proc definition.
	set pat {^\s*(if|else|elif|for|while|(.+:=\s*proc[\s\(]+.*))(\s|$)}
	if {[regexp $pat $pL1]} {
	    incr lwhite $indentationAmount
	}
    } 
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is end|else|elif|fi|od.
	set tL  [lindex $thisLine 2]
	set pat "^(\[\t \])*(end|else|elif|fi|od)(;|:)?(\[\r\n\t \]|\$)"
	if {[regexp $pat $tL]} {
	    incr lwhite -$indentationAmount
	} 
    } 
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

#this is only slightly better than generic ::electricSemi
#(all those parethesis check have been deleted...)
proc mapl::electricSemi {} {
    if {[isSelection]} {
	deleteSelection
    }
    if {[text::isInComment [getPos]] || \
      [text::isInQuotedString [getPos]] || \
      [text::isEscaped [getPos]]} {
	insertText ";"
    } else {
	insertText ";"
	mapl::carriageReturn
    }
}
	
# ===========================================================================
# 
# "mapl::getCommandLine" --
# 
# Find the next/prev command line relative to a given position, and return
# the position in which it starts, its indentation, and the complete text
# of the command line.  If the search for the next/prev command fails,
# return an indentation level of 0.
# 

proc mapl::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\# ]}
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

## 
 # -------------------------------------------------------------------------
 # 
 # "mapl::searchFunc" -- 
 # 
 # Called by keypads 1 and 3, also by bindings above.
 # 
 # -------------------------------------------------------------------------
 ##

proc mapl::searchFunc {direction args} {
    if {![llength $args]} {set args [list 0 2]}
    if {$direction} {
	eval function::next $args
    } else {
	eval function::prev $args
    }
}

# ===========================================================================
# 
# ×××× Click, Mark File ×××× #
#
#This version of mapl::DblClick looks if the clicked word is the name of a
#proc defined in the file, or if it is a passed parameter, or if it is a local
#variable, assigned explicitly or via a for-statement.  In each case we are 
#taken to the place where the assignement is performed.  From here we can get 
#back to previous cursor position by pop-bookmark (Ctrl-.).  
#(We do not care about locals assigned in seq, sum, add, mul, prod statements...)

proc mapl::DblClick {from to shift option control} {
  # 	global maplmodeVars
  global maplcmds
  
  set name [string trim [getText $from $to]]
  set procPat "(\[ \t\]|^)${name}\[ \t\r\n\]*:=\[ \t\r\n\]*proc"
  set localPat "(\[ \t\]|^)${name}\[ \t\r\n\]*:="
  set forPat "(\[ \t\]|^)for\[ \t\r\n\]+${name}\[ \t\r\n\]+"
  
  set procStart [lindex [::getLimits $from 0] 0]
  set paramStart [lindex [ search -s -f 1 -r 0 -- ( $procStart ] 1 ]
  set paramEnd [matchIt ( $paramStart]
  
  # see if this is the name of a proc defined in the file:
  if {[catch {search -s -i 0 -f 1 -r 1 -m 0 -- $procPat [minPos]} match]} {
    # see if it is an assigned variable of the current proc:
    if {[catch {search -s -i 0 -f 0 -r 1 -m 0 -l $procStart -- $localPat $from} match]} {
      # see if it is a local variable assigned in a for statement of the current proc:
      if {[catch {search -s -i 0 -f 0 -r 1 -m 0 -l $procStart -- $forPat $from} match]} {
	# see if it is a passed parameter:
	if {[catch {search -s -i 0 -f 1 -r 0 -m 1 -l $paramEnd -- $name $paramStart} match]} {
	  #see if it's a key word:
	  if {[lsearch -exact $maplcmds $name] != -1} {
	    status::msg "Reserved word.  See the Maple manual for description."
	    return
	  } else {	
	    status::msg "No assignment found"
	    return
	  }
	}
      }
    }
  }
  
  set pos0 [lindex $match 0]
  set pos1 [pos::math [nextLineStart $pos0] - 1]
  
  if {$shift != "0" || $option != "0" || $control != "0"} {
    # Modifier pressed -- give the proc args in the status bar.
    set lineNumber [lindex [pos::toRowChar $pos0] 0]
    status::msg "(line $lineNumber)  $[string trim [getText $pos0 $pos1]]"
  } else {
    # Jump to the definition.
    placeBookmark
    goto [text::nextNonWsPos $pos0]
    status::msg "press <Ctl .> to return to original cursor position"
  }
}

proc text::nextNonWsPos {pos} {
  if {[catch {lindex [search -s -f 1 -r 1 "\[^ \t\r\n\]" $pos] 0} res]} {
    return [maxPos]
  } else {
    return $res
  }
}

# #  OLD VERSION:
# #
# # Checks to see if the highlighted word is a proc defined in this file.  If
# # so, jump to its definition.  Alternatively, if any modifiers are pressed,
# # simply give the proc definition in the status bar window.
# # 
# 
# proc mapl::DblClick {from to shift option control} {
#     
#     global maplmodeVars
#     
#     select $from $to
#     set procName [string trim [getSelect]]
#     
#     set pat "^\[\t \]*${procName}\[\t ]+:=\[\t \]+proc\[\t \]*\\\("
# 
#     # Check current file for a proc definition, and if found ...
#     if {![catch {search -s -f 1 -r 1 -m 0 $pat [minPos]} match]} {
# 	set pos0 [lindex $match 0]
# 	set pos1 [pos::math [nextLineStart $pos0] - 1]
# 	if {$shift != "0" || $option != "0" || $control != "0"} {
# 	    # Modifier pressed -- give the proc args in the status bar.
# 	    set lineNumber [lindex [pos::toRowChar $pos0] 0]
# 	    status::msg "(line $lineNumber)  $[string trim [getText $pos0 $pos1]]"
# 	} else {
# 	    # Jump to the definition.
# 	    placeBookmark
# 	    goto [lineStart $pos0]
# 	    status::msg "press <Ctl .> to return to original cursor position"
# 	}
#     } else {
#         status::msg "Command double click on defined procs to find their definition."
#     }
# }
# 
# ===========================================================================
# 
# "mapl::MarkFile" --
# 

proc mapl::MarkFile {args} {
    win::parseArgs win

    global maplmodeVars
    
    set pos [minPos]
#     set exp {^[ \t]*[A-Za-z0-9]+[ \t]*:=[ \t]*proc[ \t\(]}
#     set exp  [lindex [function::getDefs] 0] ;#startPattern
    set exp $maplmodeVars(funcExpr)

    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 $exp $pos} res] } {
	set start [lindex $res 0]
	set slut  [lindex $res 1]
	set tekst [getText -w $win $start $slut]
	regsub -all ":=.*" $tekst "" tekst
	set tekst [string trim $tekst]
	if {[string length $tekst]} {
	    # build the menu item:
	    setNamedMark -w $win $tekst [lineStart -w $win [pos::math -w $win $start - 1]] $start $start
	}
	set pos [pos::math -w $win $slut + 1]
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Maple Menu ×××× #
# 

proc mapleMenu {} {}

# Tell Alpha what procedures to use to build all menus, submenus.

menu::buildProc    mapleMenu  mapl::buildMenu

proc mapl::buildMenu {} {
    
    global mapleMenu maplmodeVars

    set menuList [list \
      "mapleHomePage" "/S<EswitchToMaple" "<S<IswitchToMint" "(-)" \
      "/'<E<S<BinsertCommentTemplate"  "/'<S<O<BdefineCommentTemplateÉ"  "(-)" \
      "/N<U<BgotoNextProc"     "/P<U<BgotoPreviousProc" \
      "/S<U<BselectTheWholeProc"   "/I<B<OreformatTheWholeProc" ]

    set submenus ""
    return [list build $menuList "mapl::menuProc -M mapl" $submenus $mapleMenu]
}

# Now we actually build the Maple menu.

menu::buildSome mapleMenu

proc mapl::registerOWH {} {
    
    global mapleMenu
    
    # Dim some menu items when there are no open windows.
    set menuItems {
	insertCommentTemplate defineCommentTemplateÉ
	gotoNextProc gotoPreviousProc selectTheWholeProc reformatTheWholeProc
    }
    foreach i $menuItems {
	hook::register requireOpenWindowsHook [list $mapleMenu $i] 1
    } 
}

# Call this now.
mapl::registerOWH ; rename mapl::registerOWH ""

# This is the procedure called for all main menu items.

proc mapl::menuProc {menuName itemName} {
    
    global maplmodeVars
    
    switch $itemName {
	"mapleHomePage"         {url::execute $maplmodeVars(mapleHomePage)}
	"switchToMaple"         {app::launchFore $maplmodeVars(mapleSig)}
	"switchToMint"          {app::launchFore $maplmodeVars(mintSig)}
	"insertCommentTemplate" {comment::newComment -1}
	"defineCommentTemplate" {comment::commentTemplate}
	"gotoNextProc"          {function::next}
	"gotoPreviousProc"      {function::prev}
	"selectTheWholeProc"    {function::select}
	"reformatTheWholeProc"  {function::reformat}
	default                 {mapl::$itemName}
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× version history ×××× #
# 
#  modified by  rev    reason
#  -------- --- ------ -----------
#  ?? - ??  JK  0.0.4  Various enhancements.
#  08/30/01 JK  0.0.5  Added Maple menu, includes switching to Mint.
#  09/07/01 cbu 1.0b1  Added mapl::DblClick, enhanced Maple menu, better
#                        indentation, completions.
#  19sept01 JK  1.1    minor fixes, better command selection, new names in
#                        the menu, new icon!...
#  09/19/01 cbu 1.1.1  Simplication of proc selection/navigation due to new
#                        'function::' procs. 
#  09/20/01 cbu 1.1.2  Even newer 'function::getLimits' now deals with
#                        start/endFunction much better.
#  23sept01 JK  1.1.3  endFunction and wordBreak(preface) improved.
#                        MarkFIle repaired.  DblClick now also 
#                        looks for assignments of local variables.
#  05/30/03 cbu 1.1.4  Various fixes to conform to AlphaTcl core changes.
#                      Electric preferences, help text.
#                      Massive removal of wordBreakPreface.
#                      AlphaTcl package uninstall scripts
#                      Package requirement updates assuming AlphaTcl/Tcl > 8.0x
#                      Paste returns limits of pasted text.
#                      Converted wordWrap to variable pref.
#                      Package "description" arguments.
#                      Added optional -w win argument to MarkFile.
#                      Renamed 'word wrap' to 'line wrap'.
#                      [mapl::correctIndentation] accepts 'args' (-w <win>).
#  11/01/05 cbu 1.1.5  proper "mapl::commentCharacters(General)" list item.
#                         
# ===========================================================================
#
# .