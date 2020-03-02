## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 # 
 # FILE: "SCompletions.tcl"
 #                                          created: 05/14/2000 {01:48:41 pm}
 #                                      last update: 02/25/2006 {01:57:56 AM}
 # Description: 
 # 
 # This file will be sourced automatically, immediately after the _first_
 # time sMode.tcl is sourced.  This file declare completions items and
 # procedures for S mode.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc SCompletions.tcl {} {}

# Setting the order of precedence for completions.

set completions(S) [list \
  completion::cmd Command completion::electric completion::word]

namespace eval S {

    variable commandElectrics
    variable syntaxMessages

    # =======================================================================
    # 
    # ×××× S Command Electrics  ×××× #
    # 
    # These are distinguished from "Selectrics" because we want them to take
    # place after [S::Completions::Command] takes place, not before.
    # 
    # Each completion will already have $lastword, "$lastword"
    # 

    # ××××   Specific completions ×××× #

    array set commandElectrics {
	
	if              "(¥¥) (¥¥)¥¥"
	for             "(¥¥ in ¥¥)\{¥¥\r\t¥¥\r\}\r¥¥"
	glm             "(¥¥ ~ ¥¥)¥¥\r¥¥"
    }

    # =======================================================================
    # 
    # ×××× Syntax messages ×××× #
    # 
    # Make sure that [,],{,},#, and " have preceding backslashes.
    # 

    # specific messages --

    # As of this writing I don't when I'll have time to pursue this project.
    # 
    # The following examples demonstrate how one could include syntax
    # messages, which would appear in the status bar during completions and
    # via command-control-double-click.  The syntax can be obtained from the
    # manual pages of S, by entering
    # 
    # help (<command>)
    # 

    array set syntaxMessages {
	
	abbreviate      "abbreviate(names, minlength = 4, use.classes = T, dot = F)"
	abline          "abline(a, b)  OR  abline(coef)  OR  abline(reg)  OR  abline(h=, v=)"
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "S::electricDoubleLeftParen"  --
 # 
 # One rarely finds a string like '((' in an S file.  This procedure allows
 # such a string to trigger a special type of completion, one that simply 
 # adds the closing ')' with a template stop outside of the pair.
 # 
 # In a future version, we could also add a template _inside_ the () pair, 
 # but that would require a major template addition to this package.
 # 
 # --------------------------------------------------------------------------
 ##

# To use '(' as an electric completion key, turn this item on.  Typing a
# second consecutive left parenthesis will delete it and and the closing ')'
# as well as a handy template stop outside of the pair||To disable the use of
# '(' as an electric completion key, turn this item off
newPref flag electricDblLeftParen 0 S

prefs::dialogs::setPaneLists "S" "Editing" [list \
  "electricDblLeftParen" \
  ]

Bind '(' S::electricDoubleLeftParen S

proc S::electricDoubleLeftParen {} {

    global SmodeVars
    
    typeText "\("
    # Should we continue?
    if {!$SmodeVars(electricDblLeftParen)} {
	return 0
    }
    completion::reset
    # Check to see if we should try an array name completion.
    set pat1 {([-a-zA-Z0-9:+_.]+)\(\($}
    set txt1 [getText [lineStart [set pos0 [getPos]]] $pos0]
    if {![regexp -- $pat1 $txt1]} {
	return 0
    } elseif {[lookAt $pos0] != "\)"} {
	backSpace
	elec::Insertion "¥¥\)¥¥"
	return 1
    } else {
	status::msg "No further completions available."
	return 0
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval S::Completion {}

## 
 # --------------------------------------------------------------------------
 # 
 # "S::Completion::Command" --
 # 
 # (1)  The lists of commands has already been created.
 # (2)  Complete the insertion as defined by the variables 
 #      SCommandElectrics($lastword)
 # 
 # --------------------------------------------------------------------------
 ##

proc S::Completion::Command {} {

    global SCommandList S::commandElectrics S::syntaxMessages

    set lastword [completion::lastWord where]
    if {[lsearch -exact $SCommandList $lastword] == -1} {
        return 0
    }
    if {[info exists S::commandElectrics($lastword)]} {
        elec::Insertion $S::commandElectrics($lastword)
    } else {
        elec::Insertion "(¥¥)¥¥"
    } 
    # Putting a message in the status bar with syntax information
    if {[info exists S::syntaxMessages($lastword]} {
        status::msg "$S::syntaxMessages($lastword)"
    } 
    return 1
}

# ===========================================================================
# 
# .