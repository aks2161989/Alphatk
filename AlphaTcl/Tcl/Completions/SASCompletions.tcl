## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 #
 # FILE: "SASCompletions.tcl"
 #                                          created: 05/14/2000 {01:48:41 pm}
 #                                      last update: 02/23/2006 {04:00:47 PM}
 # Description: 
 #
 # This file will be sourced automatically, immediately after the _first_
 # time sasMode.tcl is sourced.  This file declare completions items and
 # procedures for SAS mode.
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

proc SASCompletions.tcl {} {}

# Setting the order of precedence for completions.

set completions(SAS) [list \
  completion::cmd Command completion::electric completion::word]

namespace eval SAS {}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::defineElectrics" --
 # 
 # "commandElectrics" are distinguished from "SASelectrics" because we want
 # them to take place after [SAS::Completions::Command] takes place, not
 # before.
 # 
 # Each completion will already have $lastword and a space, "$lastword ", and
 # be followed with " ;\r¥¥"
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::defineElectrics {} {
    
    global SASelectrics
    
    variable commandElectrics
    variable syntaxMessages
    
    # ×××× Specific completions ×××× #

    # This list could easily be expanded by somebody that used the program
    # more than twice a year.  The SPSSCompletions.tcl and the
    # SttaCompletions.tcl files have more complicated command-specific
    # examples.  Feel free to contribute more SAS completions!
    # 
    array set commandElectrics {
	filename        "¥¥ \"¥¥\"¥¥"
	infile          "¥¥ lrecl = ¥¥ ¥¥"
	libname         "¥¥ ¥¥"
	options         "¥¥ = ¥¥"
	proc            "¥¥"
	run             ""
    }

    # ×××× ... and then ALL CAP completions ×××× #

    foreach command [array names commandElectrics] {
	set COMMAND    [string toupper $command]
	set COMPLETION [string toupper $commandElectrics($command)]
	regsub -all {\\R} $COMPLETION {\\r} COMPLETION
	regsub -all {\\T} $COMPLETION {\\t} COMPLETION
	set commandElectrics($COMMAND) $COMPLETION
    }

    # =======================================================================
    # 
    # ×××× Syntax messages ×××× #
    # 
    # Make sure that [,],{,},#, and " have preceding backslashes.
    # 
    # As of this writing I don't when I'll have time to pursue this project.
    # 
    # The following examples demonstrate how one could include syntax
    # messages, which would appear in the status bar during completions and
    # via command-control-double-click.  The syntax can be obtained from the
    # manual pages of SAS, by entering
    # 
    # help <command> ;
    # 
    # or from an OnlineDoc web site.
    # 
    array set syntaxMessages {
	aceclus         "proc aceclus proportion=p | threshold=t < options > ;"
	model           "model dependents=independents < / options > ;"
    }

    # ××××   ... and then ALL CAP syntax messages ×××× #

    foreach command [array names syntaxMessages] {
	set COMMAND [string toupper $command]
	set MESSAGE [string toupper $syntaxMessages($command)]
	set syntaxMessages($COMMAND) $MESSAGE
    }
    return
}

# Call this now.
SAS::defineElectrics

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval SAS::Completion {}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::Completion::Command" --
 # 
 # (1)  The lists of commands has already been created.
 # (2)  Check to see if the command is preceded by a <p'> or <P'>, which 
 #      indicates that the command is preceded by "proc " or "PROC ".
 # (3)  Complete the insertion as defined by the variables 
 #      commandElectrics($lastword)
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::Completion::Command {} {
    
    global SAS::keywordLists SAS::syntaxMessages SAS::commandElectrics
    
    set lastword [completion::lastWord where]
    if {([lsearch -exact $SAS::keywordLists(allCommands) $lastword] == -1)} {
        return 0
    }
    set oneBack  [pos::math $where - 1]
    set twoBack  [pos::math $where - 2]
    
    set oneBackChar [lookAt $oneBack]
    set twoBackChar [lookAt $twoBack]
    
    # Do we have a defined completion?
    if {[info exists SAS::commandElectrics($lastword)]} {
        set complete $SAS::commandElectrics($lastword)
    } else {
        set complete " ¥¥"
    } 
    append complete  " ;\r¥¥"
    # Do we have a message to put in the status bar?
    if {[info exists SAS::syntaxMessages($lastword)]} {
        set sm $SAS::syntaxMessages($lastword)
    } else {
        set sm ""
    } 
    # Now create the electric insertion.
    if {($twoBackChar eq "p" || $twoBackChar eq "P") && ($oneBackChar eq "'")} {
        # Is this a p'<command> Or a P'<COMMAND> contraction?
        if {($twoBackChar eq "P")} {
            set p "PROC"
        } else {
            set p "proc"
        } 
        deleteText $twoBack [getPos]
        set commandInsertion "$p $lastword $complete"
    } else {
        # No, so just insert defined completion.
        set commandInsertion " $complete"
    }
    elec::Insertion $commandInsertion
    # Putting a message in the status bar with syntax information.
    status::msg "$sm"
    return 1
}

# ===========================================================================
# 
# .