## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "LispCompletions.tcl"
 #                                          created: 01/10/2003 {07:48:21 PM}
 #                                      last update: 02/25/2006 {01:16:11 AM}
 # Description: 
 #
 # This file will be sourced automatically, immediately after the _first_
 # time "lispMode.tcl" is sourced.  This file declare completions items and
 # procedures for Lisp mode.
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

proc LispCompletions.tcl {} {}

# Setting the order of precedence for completions.

set completions(Lisp) [list \
  completion::cmd Command completion::electric completion::word]

namespace eval Lisp {
    
    variable syntaxMessages
    
    # =======================================================================
    # 
    # ×××× Syntax messages ×××× #
    # 
    # Make sure that [,],{,},#, and " have preceding backslashes.
    # 
    # As of this writing I don't intend to pursue this project.
    # 
    # The following examples demonstrate how one could include syntax
    # messages, which would appear in the status bar during completions and
    # via command-control-double-click.  The syntax can be obtained from
    # 
    # <http://www.xanalys.com/software_tools/reference/HyperSpec/Body/>
    # 
    
    # functions
    
    array set syntaxMessages {
	abs         "abs number => absolute-value"
	append      "append &rest lists => result"
    }
    
    # macros
    
    array set syntaxMessages {
	and         "and form* => result*"
	assert      "assert test-form \[(place*) \[datum-form argument-form*\]\]"
	defclass    "defclass class-name (\{superclass-name\}*) (\{slot-specifier\}*) \[\[class-option\]\] => new-class"
    }
    
    # accessors
    
    set syntaxMessages(aref) "aref array &rest subscripts => element"
    
    # specials
    
    set syntaxMessages(setq) "setq \{pair\}* => result"
}

namespace eval Lisp::Completion {}

# ===========================================================================
# 
# Lisp::Completion::Command
# 
# (1)  The list of commands has already been created.
# (2)  Check to see if the command is preceded by an opening paranthesis.
# (3)  If not, delete the $lastword, and add the paranthesis.
# (4)  Insert a generic completion.

proc Lisp::Completion::Command {} {
    
    global Lisp::keywords Lisp::commandElectrics Lisp::syntaxMessages
    
    set lastword [completion::lastWord where]
    
    if {([lsearch -exact $Lisp::keywordLists(macroList) $lastword] == -1)} {
	return 0
    }
    set oneback [pos::math $where - 1]
    
    # Do we have a defined completion?
    if {[info exists Lisp::commandElectrics($lastword)]} {
	set complete $Lisp::commandElectrics($lastword)
    } else {
	set complete "¥¥\)¥¥"
    } 
    # Do we have a message to put in the status bar?
    if {[info exists Lisp::syntaxMessages($lastword)]} {
	set sm $Lisp::syntaxMessages($lastword)
    } else {
	set sm ""
    } 
    if {[lookAt $oneback] ne "\("} {
	set deleteLen [pos::diff $where [getPos]]
	set commandInsertion "\($lastword $complete"
    } else {
	set deleteLen 0
	set commandInsertion " $complete"
    }
    completion::action -electric -text $commandInsertion \
      -delete $deleteLen -msg $sm
    return 1
}    

# ===========================================================================
# 
# .