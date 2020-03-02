## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "ScmCompletions.tcl"
 #                                          created: 05/14/2000 {01:48:41 pm}
 #                                      last update: 02/25/2006 {01:15:50 AM}
 # Description: 
 #
 # This file will be sourced automatically, immediately after the _first_
 # time "schemeMode.tcl" is sourced.  This file declare completions items and
 # procedures for Scm mode.
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

proc ScmCompletions.tcl {} {}

# Setting the order of precedence for completions.

set completions(Scm) [list \
  completion::cmd Command completion::electric completion::word]

namespace eval Scm {
    
    variable syntaxMessages
    
    # =======================================================================
    # 
    # ×××× Syntax messages ×××× #
    # 
    # Make sure that [,],{,},#, and " have preceding backslashes.
    # 
    
    # specific messages --
    
    # As of this writing I don't intend to pursue this project.
    # 
    # The following examples demonstrate how one could include syntax
    # messages, which would appear in the status bar during completions and
    # via command-control-double-click.  The syntax can be obtained from
    # 
    # <http://www.xanalys.com/software_tools/reference/HyperSpec/Body/>
    # 
    # Note: These are simply copied from LispCompletions.tcl, and have
    # nothing to do with Scheme.
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

namespace eval Scm::Completion {}

# ===========================================================================
# 
# Scm::Completion::Command
# 
# (1)  The list of commands has already been created.
# (2)  Check to see if the command is preceded by an opening paranthesis.
# (3)  If not, delete the $lastword, and add the paranthesis.
# (4)  Insert a generic completion.

proc Scm::Completion::Command {} {
    
    global ScmCommandList Scm::commandElectrics Scm::syntaxMessages
    
    set lastword [completion::lastWord where]
    
    if {([lsearch -exact $ScmCommandList $lastword] == -1)} {
	return 0
    }
    set oneback [pos::math $where - 1]
    
    # Do we have a defined completion?
    if {[info exists Scm::commandElectrics($lastword)]} {
	set complete $Scm::commandElectrics($lastword)
    } else {
	set complete "¥¥\)¥¥"
    } 
    # Do we have a message to put in the status bar?
    if {[info exists Scm::syntaxMessages($lastword)]} {
	set sm $Scm::syntaxMessages($lastword)
    } else {
	set sm ""
    } 
    if {([lookAt $oneback] ne "\(")} {
	deleteText $where [getPos]
	set commandInsertion "\($lastword $complete"
    } else {
	set commandInsertion " $complete"
    }
    elec::Insertion $commandInsertion
    # Putting a message in the status bar with syntax information
    status::msg "$sm"
    return 1
}    

# ===========================================================================
# 
# .