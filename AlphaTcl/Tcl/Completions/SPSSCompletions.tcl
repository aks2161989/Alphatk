## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 #
 # FILE: "SPSSCompletions.tcl"
 #                                          created: 05/14/2000 {01:48:41 pm}
 #                                      last update: 02/23/2006 {04:02:43 PM}
 # Description: 
 #
 # This file will be sourced automatically, immediately after the _first_
 # time SPSSMode.tcl is sourced.  This file declare completions items and
 # procedures for SPSS mode.
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

proc SPSSCompletions.tcl {} {}

# Setting the order of precedence for completions.

set completions(SPSS) [list \
  contraction completion::cmd Command completion::electric completion::word]

namespace eval SPSS {}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::defineElectrics" --
 # 
 # Define both lower and UPPER case electric completions and syntax messages.
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::defineElectrics {} {
    
    global SPSSelectrics
    
    variable commandElectrics
    variable keywordLists
    variable syntaxMessages

    # ×××× Specific completions, multi ×××× #
    # 
    # Multiple word commands.
    # 

    # "add" can be either "files" or "value labels"
    set commandElectrics(add)           "¥¥"
    set commandElectrics(begin)         "data"
    set commandElectrics(clear)         "transformations .\r¥¥"
    set commandElectrics(drop)          "documents¥¥ .\r¥¥"
    # "do" can be either "if" or "repeat"
    set commandElectrics(do)            ""
    set commandElectrics(data)          "list"
    # "end" can be either "if" or "file type"
    set commandElectrics(end)           ""
    # "file" can be "handle", "label" or "type"
    set commandElectrics(file)          "¥¥"
    # "get" can be "bmdp", "osiris", "sas", or "translate"
    set commandElectrics(get)           ""
    set commandElectrics(input)         "program"
    set commandElectrics(keyed)         "data"
    set commandElectrics(logistic)      "regression"
    set commandElectrics(match)         "files"
    set commandElectrics(mult)          "response"
    set commandElectrics(missing)       "values"
    set commandElectrics(n)             "of cases"
    set commandElectrics(nonpar)        "corr"
    set commandElectrics(npar)          "tests"
    set commandElectrics(partial)       "corr"
    # "print" can be "eject", "formats" or "space"
    set commandElectrics(print)         "¥¥"
    set commandElectrics(procedure)     "output"
    set commandElectrics(quick)         "cluster"
    set commandElectrics(repeating)     "data"
    set commandElectrics(record)        "type"
    set commandElectrics(rename)        "variables"
    set commandElectrics(sort)          "cases"
    set commandElectrics(split)         "file"
    set commandElectrics(select)        "if"
    # "save" can be either "scss" or "translate", or nothing
    set commandElectrics(save)          "¥¥"
    set commandElectrics(variable)      "labels"
    set commandElectrics(value)         "labels"
    set commandElectrics(write)         "formats"

    # ×××× Specific completions, single ×××× #
    # 
    # One word (and the tails of mult-word) commands.
    # 

    array set commandElectrics {
	
	aggregate       "outfile = \"¥¥\"¥¥\r\t/break = ¥¥ .\r¥¥"
	alscal          "¥¥ = ¥¥ .\r¥¥"
	anova           "variables = ¥¥ by ¥¥(¥¥,¥¥)¥¥ .\r¥¥"
	autorecode      "variables = ¥¥\r\tinto ¥¥ .\r¥¥"
	bmdp            "¥¥ .\r¥¥"
	break           ".\r¥¥"
	cluster         "¥¥ .\r¥¥"
	compute         "¥¥ = ¥¥ .\r¥¥"
	correlations    "variables = ¥¥ .\r¥¥"
	count           "¥¥ = ¥¥ (¥¥)¥¥ .\r¥¥"
	crosstabs       "tables = ¥¥ by ¥¥ .\r¥¥"
	decriptives     "variables = ¥¥ .\r¥¥"
	discriminant    "groups = (¥¥,¥¥)¥¥\r\tvariables = ¥¥ .\r¥¥"
	documents       "¥¥ .\r¥¥"
	edit            ".\r¥¥"
	examine         "variables = ¥¥ .\r¥¥"
	execute         ".\r¥¥"
	export          "outfile = \"¥¥\"¥¥ .\r¥¥"
	factor          "variables = ¥¥ .\r¥¥"
	files           "file = \"¥¥\"¥¥ .\r¥¥"
	flip            "variables = ¥¥ .\r¥¥"
	formats         "¥¥ (¥¥)¥¥ .\r¥¥"
	frequencies     "variables = ¥¥ .\r¥¥"
	graph           "¥¥"
	handle          "¥¥ / ¥¥ .\r¥¥"
	if              "(¥¥)¥¥ .\r¥¥"
	import          "file = \"¥¥\"\¥¥ .\r¥¥"
	labels          "¥¥ \"¥¥\"¥¥ .\r¥¥"
	list            "variables = ¥¥ .\r¥¥"
	loglinear       "¥¥ (¥¥,¥¥) ¥¥ .\r¥¥"
	osiris          "dictionary = ¥¥ .\r¥¥"
	recode          "¥¥ (¥¥ = ¥¥)¥¥ .\r¥¥"
	regression      "¥¥  ¥¥ ¥¥ .\r¥¥"
	sas             "data = ¥¥ .\r¥¥"
	scss            "masterfile = \"¥¥\"¥¥ .\r¥¥"
	translate       "file = \"¥¥\"¥¥ .\r¥¥"
	value           "labels ¥¥ \"¥¥\"\"¥¥\"¥¥ .\r¥¥"
	variable        "labels ¥¥ \"¥¥\"¥¥ .\r¥¥"
    }

    # ×××× Specific "argument" completions ×××× #

    array set commandElectrics {
	
	case            ".\r¥¥"
	file            "= \"¥¥\"¥¥ .\r¥¥"
	label           "¥¥ ¥¥"
	outfile         "= \"¥¥\"¥¥"
    }


    # ×××× ... and then ALL CAP completions ×××× #

    foreach command [array names commandElectrics] {
	set COMMAND    [string toupper $command]
	set COMPLETION [string toupper $commandElectrics($command)]
	regsub {\\R} $COMPLETION {\\r} COMPLETION
	regsub {\\T} $COMPLETION {\\t} COMPLETION
	set commandElectrics($COMMAND) $COMPLETION
    }

    # =======================================================================
    # 
    # ×××× Function Completions ×××× #
    # 

    foreach genericCompletion $keywordLists(functions) {
	set SPSSelectrics($genericCompletion) "(¥¥)¥¥"
    }

    # =======================================================================
    # 
    # ×××× Contractions ×××× #
    # 
    # These are for two and three word commands.  Hitting the completion key
    # again, after these have been completed, will invoke further completions.
    # 

    array set SPSSelectrics {
	
	a'f                    "×kill0add files"
	a'vl                   "×kill0add value labels"
	b'd                    "×kill0begin data"
	c't                    "×kill0clear transformations"
	d'd                    "×kill0drop documents"
	d'i                    "×kill0do if"
	d'l                    "×kill0data list"
	d'r                    "×kill0do repeat"
	e'ft                   "×kill0end file type"
	e'r                    "×kill0end repeat"
	f'h                    "×kill0file handle"
	f'l                    "×kill0file label"
	f't                    "×kill0file type"
	g'b                    "×kill0get bmdp"
	g'o                    "×kill0get osiris"
	g's                    "×kill0get sas"
	g'sc                   "×kill0get scss"
	g't                    "×kill0get translate"
	i'p                    "×kill0input program"
	k'dl                   "×kill0keyed data"
	l'r                    "×kill0logistic regression"
	m'f                    "×kill0match files"
	m'r                    "×kill0mult response"
	m'v                    "×kill0missing values"
	n'oc                   "×kill0n of cases"
	n'c                    "×kill0nonpar corr"
	n't                    "×kill0npar tests"
	p'c                    "×kill0partial corr"
	p'e                    "×kill0print eject"
	p'f                    "×kill0print formats"
	p'o                    "×kill0procedure output"
	p's                    "×kill0print space"
	q'c                    "×kill0quick cluster"
	r'd                    "×kill0repeating data"
	r't                    "×kill0record type"
	r'v                    "×kill0rename variables"
	s'c                    "×kill0sort cases"
	s'f                    "×kill0split file"
	s'i                    "×kill0select if"
	s's                    "×kill0save sas"
	s't                    "×kill0save translate"
	vr'l                   "×kill0variable labels"
	vl'l                   "×kill0value labels"
	w'f                    "×kill0write formats"
    }

    # And now upper case electrics.

    foreach completion [array names SPSSelectrics] {
	set COMMAND    [string toupper $completion]
	set COMPLETION [string toupper $SPSSelectrics($completion)]
	regsub -all {\\R}   $COMPLETION {\\r}   COMPLETION
	regsub -all {\\T}   $COMPLETION {\\t}   COMPLETION
	regsub -all {×KILL} $COMPLETION {×kill} COMPLETION
	set SPSSelectrics($COMMAND) $COMPLETION
    }

    # =======================================================================
    # 
    # ××××   Syntax messages ×××× #
    # 
    # Make sure that [,],{,},#, and " have preceding backslashes.
    # 

    # specific messages --

    # As of this writing I don't when I'll have time to pursue this project.
    # 
    # The following examples demonstrate how one could include syntax messages,
    # which would appear in the status bar during completions and via
    # command-control-double-click.  The syntax can be obtained from the manual 
    # pages of SPSS, by entering 
    # 
    # help <command>
    # syntax
    # 

    array set syntaxMessages {
	
	anova           "anova \[variables=\] varlist by varlist(min,max)...varlist(min,max) <options>"
	correlations    "correlations \[variables=\] varlist \[with varlist\] \[/varlist...\]  <options>"
    }

    # ××××   ... and then ALL CAP syntax messages ×××× #

    foreach command [array names syntaxMessages] {
	set COMMAND [string toupper $command]
	set MESSAGE [string toupper $syntaxMessages($command)]
	set syntaxMessages($COMMAND) $MESSAGE
    }
}

# Call this now.
SPSS::defineElectrics

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval SPSS::Completion {}

## 
 # --------------------------------------------------------------------------
 # 
 # "SPSS::Completion::Command" --
 # 
 # SPSS "commandElectrics" are distinguished from "SPSSelectrics" because we
 # want them to take place after the [SPSS::Completions::Command] takes
 # place, not before.
 # 
 # Each completion will already have $lastword and a space, "$lastword "
 # 
 # (1)  The lists of commands has already been created.
 # (2)  Check to see if the command is preceded by a <'> or </>, which indicates 
 #      that the user wants an argument and not a command.
 # (3)  If so, then leave it at the word completion.
 # (4)  Othewise, complete the insertion as defined by the variables 
 #      SPSScommandElectrics($lastword)
 # 
 # --------------------------------------------------------------------------
 ##

proc SPSS::Completion::Command {} {

    global SPSScmds SPSS::commandElectrics SPSS::syntaxMessages
    
    set lastword [completion::lastWord where]
    if {[lsearch -exact $SPSScmds $lastword] == -1} {
	return 0
    }
    set oneBack     [pos::math $where - 1]
    set oneBackChar [lookAt $oneBack]

    # Do we have a defined completion?
    if {[info exists SPSS::commandElectrics($lastword)]} {
	set complete $SPSS::commandElectrics($lastword)
    } else {
	set complete " ¥¥.\r¥¥"
    }
    # Do we have a message to put in the status bar?
    if {[info exists SPSS::syntaxMessages($lastword)]} {
	set sm $SPSS::syntaxMessages($lastword)
    } else {
	set sm ""
    }
    # Now create the electric insertion.
    if {$oneBackChar == "'"} {
	# Is this a <'><keyword> completion?
	# Then insert as an argument, not as a command.
	deleteText $oneBack [getPos]
	set commandInsertion "$lastword ¥¥"
	set sm ""
    } elseif {$oneBackChar == "/"} {
	# Is this a </><keyword> completion?
	# Then insert as an argument, not as a command.
	set commandInsertion " ¥¥"
	set sm ""
    } else {
	# No, such just insert defined completion
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