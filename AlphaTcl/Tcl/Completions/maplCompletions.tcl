## -*-Tcl-*-
 # ===========================================================================
 #  Maple Mode - an extension package for Alpha
 # 
 #  FILE: "maplCompletions.tcl"
 #                                    created: 09/06/2001 {12:12:46 PM} 
 #                                last update: 16OCT2001 12:38:51 
 #  Description:
 #  
 #  This file will be sourced automatically, immediately after the _first_
 #  time mapleMode.tcl is sourced.  This file declare completions items
 #  and procedures for Mapl mode.
 #  
 #  See the "mapleMode.tcl" file for license info, credits, etc.
 # ===========================================================================
 ##

namespace eval mapl {}
  
# Setting the order of precedence for completions.

set completions(mapl) {
    completion::cmd Proc completion::electric completion::word
}

set maplelectrics(proc)     "×kill0×\[mapl::electricProc\]"

# Conditionals.

set maplelectrics(if)       " ¥expr¥ then \r\t¥cmd¥\rfi;\r¥¥"
set maplelectrics(ifelse)   "×kill0if ¥expr¥ then \r\t¥cmd¥\relse\r\t¥cmd¥\rfi;\r¥¥"
set maplelectrics(ifelif)   "×kill0if ¥expr¥ then \r\t¥cmd¥\relif ¥expr¥ \r\t¥cmd¥\rfi;\r¥¥"
set maplelectrics(for)      " ¥expr¥ do \r\t¥cmd¥\rod;\r¥¥"
set maplelectrics(forin)    "×kill0for ¥expr¥ in ¥set¥ do \r\t¥cmd¥\rod;\r¥¥"
set maplelectrics(forto)    "×kill0for ¥expr¥ from ¥start¥ by ¥by¥ to ¥to¥ do \r\t¥cmd¥\rod;\r¥¥"
set maplelectrics(while)    " ¥expr¥ do \r\t¥cmd¥\rod;\r¥¥"

# 'Null' Completions.

proc mapl::setNullCompletions {} {
		global maplelectrics
		# I might have missed some here ...
		set noCompletionCommands {
				and break do done else end fi from global 
				in indexed iolib list local minus mod next nonnegint not 
				NULL option options od or posint 
				protected quit rational remember restart save stop then to union
		}
		foreach command $noCompletionCommands {
				set maplelectrics($command) ""
		}
}

# Call this now.
mapl::setNullCompletions ; rename mapl::setNullCompletions ""

# Generic Completions.  Anything not defined above will get a completion of ()

proc mapl::setGenericCompletions {} {
		global maplcmds maplelectrics
		foreach command $maplcmds {
				if {![info exists maplelectrics($command)]} {
						set maplelectrics($command) "(¥¥)¥¥"
				} 
		}
}

# Call this now.
mapl::setGenericCompletions ; rename mapl::setGenericCompletions ""

# Defining new procs.

proc mapl::electricProc {} {
    set pos0 [getPos]
    set pos1 [lineStart $pos0]
    set line [string trim [getText $pos1 $pos0]]
    if {[string length $line]} {
        regsub {:=} $line {} line
	set line [string trimright $line]
    } else {
        set line "¥name¥"
    }
    replaceText $pos1 $pos0 ""
    elec::Insertion "$line := proc(¥args¥)\r\t¥body¥\rend:\r¥¥"
    return -code return
}

# Completing a pre-defined proc name, with args as templates.

namespace eval mapl::Completion {}

proc mapl::Completion::Proc {} {
    
    set lastWord [completion::lastWord where]
    set pat "^(\[\t \]*${lastWord}\[\t ]+:=\[\t \]+proc\[\t \]*)(\[^\r\n]+)"
    # Check current file for a proc definition, and if found ...
    if {![catch {search -s -f 1 -r 1 -m 0 $pat [minPos]} match]} {
	set pos0 [lindex $match 0]
	set pos1 [nextLineStart [lindex $match 1]]
	regexp $pat [string trim [getText $pos0 $pos1]] allOfIt def args
	set args [string trim $args]
	set args [split [string range $args 1 [expr [string length $args] - 2]] ","]
	set elecArgs "("
	set elecMsg  ""
	foreach arg $args {
	    append elecArgs "¥$arg¥,"
	    append elecMsg  "$arg,"
	}
	set elecArgs "[string trimright $elecArgs ","])¥¥"
	set elecMsg  "[string trimright $elecMsg  ","]"
	elec::Insertion "$elecArgs"
	status::msg $elecMsg
	return 1
    } else {
        return 0
    }
}
