## -*-Tcl-*-
 # ===========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "shCompletions.tcl"
 #                                           created: 05/14/2000 {01:48:41 pm}
 #                                       last update: 02/23/2006 {04:30:54 PM}
 # Description:
 # 
 # This file will be sourced automatically, immediately after the _first_
 # time shScriptsMode.tcl is sourced.  This file declare completions items
 # and procedures for sh mode.
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
 # ===========================================================================
 ##

proc shCompletions.tcl {} {}

# Setting the order of precedence for completions.

set completions(sh) [list \
  contraction completion::cmd Command completion::electric completion::word]

namespace eval sh {
    
    variable commandElectrics
    variable syntaxMessages

    # =======================================================================
    # 
    # ×××× sh Command Electrics  ×××× #
    # 
    # These are distinguished from "shelectrics" because we want them to take
    # place after the sh::Completions::Command takes place, not before.
    # 
    # Each completion will already have $lastword and a space, "$lastword "
    # 

    # ×××× Generic completions ×××× #

    foreach genericCompletion $shcmds {
	set commandElectrics($genericCompletion) "¥¥\r¥¥"
    }
    unset -nocomplain genericCompletion

    # ×××× Specific completions ×××× #
    
    array set commandElectrics {
	dbms            "¥source¥  ¥target¥\r¥¥"
	dbmscopy        "¥source¥  ¥target¥\r¥¥"
	echo            "¥text¥\r¥¥"
	ln              "¥source¥ ¥target¥\r¥¥"
	mkdir           "¥dir¥\r¥¥"
	rm              "¥source¥\r¥¥"
	sas             "¥file¥\r¥¥"
	spss            "-m  ¥file¥ > ¥file¥\r¥¥"
	stata           "do  ¥file¥ > ¥file¥\r¥¥"
    }
    
    # Conditionals

    array set commandElectrics {
	if              " ¥expr¥ then \r\t¥cmd¥\rfi\r¥¥"
	ifelse          "×kill0if ¥expr¥ then \r\t¥cmd¥\relse\r\t¥cmd¥\rfi\r¥¥"
	ifelif          "×kill0if ¥expr¥ then \r\t¥cmd¥\relif ¥expr¥ \r\t¥cmd¥\rfi\r¥¥"
	while           " ¥expr¥ do \r\t¥cmd¥\rdone\r¥¥"
    }

    # =======================================================================
    # 
    # ×××× Syntax messages ×××× #
    # 
    # Make sure that [,],{,},#, and " have preceding backslashes.
    # 

    # generic message -- empty, which will put nothing in status bar
    foreach genericKeyword $::shcmds {
	set syntaxMessages($genericKeyword) ""
    }
    unset -nocomplain genericKeyword

    # specific messages --

    # As of this writing I don't intend to pursue this project.
    # 
    # The following examples demonstrate how one could include syntax messages,
    # which would appear in the status bar during completions and via
    # command-control-double-click.  The syntax can be obtained from the manual 
    # pages of any unix OS, by entering 
    # 
    # man <command>
    # 
    array set syntaxMessages {
	chdir           "chdir  \[ dir \]"
	chmod           "chmod  \[ -fR \] <absolute-mode> file ... OR chmod  \[ -fR \] <absolute-mode-list> file ..."
	rmdir           "/usr/bin/rmdir  \[ -ps \] dirname ..."
    }
    
    # =======================================================================
    # 
    # ×××× Contractions ×××× #
    # 

    set ::shelectrics(s'd)       "×kill0stata do  ¥file¥ > ¥file¥\r¥¥"
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval sh::Completion {}

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::Completion::Command" --
 # 
 # (1)  The lists of commands has already been created.
 # (2)  Complete the insertion as defined by the variables 
 #      shcommandElectrics($lastword)
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::Completion::Command {} {

    global shcmds sh::commandElectrics sh::syntaxMessages

    set lastword [completion::lastWord where]
    if {![lcontains shcmds $lastword]} {
	return 0
    }
    set complete $sh::commandElectrics($lastword)
    set sm       $sh::syntaxMessages($lastword)

    set commandInsertion " $complete"
    
    elec::Insertion $commandInsertion

    # Putting a message in the status bar with syntax information
    status::msg "$sm"
    return 1
}

# ===========================================================================
# 
# .