## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "FortCompletions.tcl"
 #                                          created: 02/10/2005 {06:44:37 PM}
 #                                      last update: 02/23/2006 {04:48:50 PM}
 # Description:
 # 
 # Provides electric completion support in Fort mode.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 2005-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # This file is distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

proc FortCompletions.tcl {} {}

set ::completions(Fort) [list \
  {completion::contraction} "specialElectric" "continueLabel" \
  {completion::cmd} {completion::electric} {completion::word}]

set ::expanders(Fort) [list \
  {completion::contraction} "specialElectric"]

# To use '(' as an electric completion key, turn this item on.  Typing a
# second consecutive left parenthesis add a closing right parenthesis||To
# disable the use of '(' as an electric completion key, turn this item off
newPref flag electricDblLeftParen   {1}     Fort
# To complete "elseif" with "ELSE IF", turn this item on||To complete
# "elseif" as a single word, turn this item off
newPref flag elseifIsSingleWord     {1}     Fort
# To complete "endif|do" with "END IF|DO", turn this item on||To complete
# "elseif" with and "endif" as single words, turn this item off
newPref flag endifEnddoAreSingleWords {1}   Fort
# To always add a space after an electric completion (before any
# parenthetical arguments) of a command, turn this item on||To never add a
# space after an electric completion of a command, turn this item off
newPref flag spaceAfterIf           {1}     Fort \
  {Fort::Completion::rebuildElectrics}
# To always add a space after an electric completion (before any
# parenthetical arguments) of a command, turn this item on||To never add a
# space after an electric completion of a command, turn this item off
newPref flag spacesAfterCommand	    {1}     Fort \
  {Fort::Completion::rebuildElectrics}
# To always add a space after an electric completion (before any
# parenthetical arguments) of a function, turn this item on||To never add a
# space after an electric completion of a function, turn this item off
newPref flag spacesAfterFunction    {0}     Fort \
  {Fort::Completion::rebuildElectrics}

# The style for command completions.  Completion 'hints' can be in any of
# these forms, but all will be translated to this style.
newPref var  completeCommandsUsing  {0}     Fort \
  {Fort::Completion::rebuildElectrics} \
  [list "lower case" "Capitalized Names" "UPPER CASE"] index

# Add a new preferences pane.
prefs::dialogs::setPaneLists "Fort" "Electrics" [list \
  "completeCommandsUsing" \
  "electricDblLeftParen" \
  "elseifIsSingleWord" \
  "endifEnddoAreSingleWords" \
  "spaceAfterIf" \
  "spacesAfterCommand" \
  "spacesAfterFunction" \
  ]

# Electric Double Left Parenthesis.
Bind '(' Fort::electricDoubleLeftParen Fort

namespace eval Fort {}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::electricDoubleLeftParen" --
 # 
 # A minor time-saver -- double typing "(" will delete the last one and
 # insert ")" in its place, with a template stop outside it for easy
 # navigation once the text has been inserted.  The "original" double
 # parenthesis is always inserted first so that [undo] will restore it if
 # that is what the user really wanted.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::electricDoubleLeftParen {{m "Fort"}} {

    global ${m}modeVars
    
    typeText "\("
    # Should we continue?
    if {![set ${m}modeVars(electricDblLeftParen)]} {
	return
    }
    set pos1 [getPos]
    set pos0 [pos::lineStart $pos1]
    if {[regexp -- {[^\(]\(\($} [getText $pos0 $pos1]]} {
	backSpace
	elec::Insertion "¥¥\)¥¥"
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval Fort::Completion" --
 # 
 # Define some electrics which are processed before anything else.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Fort::Completion {

    # Used in [Fort::Completion::specialElectric]
    variable lastDoChoice
    if {![info exists lastDoChoice]} {
	set lastDoChoice "EndDo"
    }
    # Define the keywords used in [Fort::Completion::specialElectric].
    variable specialCompletions [list \
      "do" "else" "elseIf" "ifElse" "ifThen" "while" \
      "doContinue" "doEndDo" "doUntil" "doWhile" "enddo"]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::Completion::electricStyle" --
 # 
 # Convert a string respecting the user's "completeCommandsUsing" preference.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::Completion::electricStyle {item modeName} {
    
    global ${modeName}modeVars
    
    switch -- [set ${modeName}modeVars(completeCommandsUsing)] {
	"0" {set newItem [string tolower $item]}
	"1" {set newItem [string totitle $item]}
	"2" {set newItem [string toupper $item]}
    }
    return $newItem
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::Completion::rebuildElectrics" --
 # 
 # Define the "Fortcmds" list and all "Fortelectrics" array entries.  This is
 # called when this file is first sourced, and whenever the user changes the
 # "completeCommandsUsing" preference.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::Completion::rebuildElectrics {args} {
    
    if {([lindex $args 0] eq "f90")} {
        set m "f90"
    } else {
        set m "Fort"
    }
    
    global ${m}cmds ${m}electrics ${m}modeVars
    
    variable specialCompletions
    
    unset -nocomplain ${m}electrics
    
    foreach item $specialCompletions {
	array set ${m}electrics [list \
	  $item                     "" \
	  [string tolower $item]    "" \
	  [string totitle $item]    "" \
	  [string toupper $item]    "" \
	  ]
    }
    
    # -----------------------------------------------------------------------
    # 
    # 'Normal' keywords.
    # 
    
    # These haven't been sorted yet.
    set ${m}cmds [list \
      "allocatable" "allocate" "assignment" "case" "contains" "cycle" \
      "deallocate" "default" "elsewhere" "exit" "extrinsic" "forall" "go" \
      "include" "intent" "interface" "module" "namelist" "none" "nullify" \
      "operator" "optional" "pointer" "private" "procedure" "public" "pure" \
      "recursive" "select" "sequence" "target" "type" "use" "where" \
      ]
    # Add all possible cases.
    foreach command [set ${m}cmds] {
	lappend ${m}cmds [string totitle $command] [string toupper $command]
    }
    
    # Items that take lists.
    set itemList [list \
      "complex" "integer" "logical" "real" \
      ]
    foreach item $itemList {
	set completionBodies($item) "¥list-of-variables¥"
    }
    # Items that take a single argument.
    set itemList [list \
      "backspace" "dimension" "endfile" "program" "print" "rewind" "endfile" \
      ]
    foreach item $itemList {
	set completionBodies($item) " ¥¥"
    }
    # Items that take a single (argument).
    set itemList [list \
      "close" "dble" "inquire" "format" "pause" \
      ]
    foreach item $itemList {
	set completionBodies($item) "(¥¥)¥¥"
    }
    # Items that take a second command word.
    set itemList [list \
      [list "double" "precision"] \
      [list "assign" "to"] \
      [list "block"  "data"] \
      ]
    foreach itemPair $itemList {
	set item0 [lindex $itemPair 0]
	set item1 [Fort::Completion::electricStyle [lindex $itemPair 1] $m]
	switch -- $item0 {
	    "assign" {set completion "¥statement-label¥ $item1 ¥integer-name¥"}
	    "double" {set completion "$item1 ¥list-of-variables¥"}
	    "block"  {set completion "$item1"}
	    default  {set completion "$item1 ¥¥"}
	}
	set completionBodies($item0) $completion
    }
    # Items with more specific completions.
    array set completionBodies [list \
      "call"            "¥subroutine¥" \
      "character"       "¥\[*length\]¥ ¥name¥" \
      "open"            "(¥specifier: \[UNIT\]|IOSTAT|ERR|STATUS¥=)" \
      "common"          "/¥name¥/ ¥list-of-variables¥" \
      "data"            "¥list-of-variables¥/¥list-of-values¥/,¥¥" \
      "equivalence"     "(¥list-of-variables¥)¥¥" \
      "entry"           "¥name¥" \
      "external"        "¥procedure¥" \
      "function"        "¥name¥" \
      "if"              "(¥logical-expression¥) ¥statement¥" \
      "implicit"        "¥type: INTEGER, REAL, etc)¥ (¥letter-range¥)" \
      "intrinsic"       "¥function¥" \
      "goto"            "¥label¥" \
      "open"            "(¥specifier: \[UNIT\]|IOSTAT|ERR|FILE|STATUS|ACCESS|FORM|RECL¥=)" \
      "parameter"       "(¥name¥=¥constant¥)¥¥" \
      "read"            "(¥unit-number¥,¥format-number¥) ¥list-of-variables¥" \
      "save"		"¥common-block-name¥" \
      "subroutine"      "¥name¥ (¥list of arguments¥)¥¥" \
      "write"           "(¥unit-number¥,¥format-number¥) ¥list-of-variables¥" \
      ]
    
    foreach item [array names completionBodies] {
	set Item [string totitle $item]
	set ITEM [string toupper $item]
	set name [Fort::Completion::electricStyle $item $m]
	set completion $completionBodies($item)
	if {($item eq "if")} {
	    set pad [string repeat " " [set ${m}modeVars(spaceAfterIf)]]
	    set completion "${pad}${completion}"
	} elseif {([string index $completion 0] eq "\(")} {
	    set pad [string repeat " " [set ${m}modeVars(spacesAfterCommand)]]
	    set completion "${pad}${completion}"
	} elseif {([string index $completion 0] ne "×")} {
	    set completion " $completion"
	}
	if {[string index $completion end] eq "\)"} {
	    append completion "¥¥"
	}
	foreach styledItem [list $item $Item $ITEM] {
	    if {($styledItem eq $name)} {
		set ${m}electrics($styledItem) $completion
	    } else {
		set ${m}electrics($styledItem) "×kill0${name}${completion}"
	    }
	    lappend ${m}cmds $styledItem
	}
    }
    
    # -----------------------------------------------------------------------
    # 
    # Contractions -- these make use of indirection.
    # 
    
    array set contractionBodies [list \
      "a'T"     "assign" \
      "b'D"     "block" \
      "d'P"     "double" \
      ]
    
    foreach item [array names contractionBodies] {
	set styledItems [list $item \
	  [string tolower $item] \
	  [string totitle $item] \
	  [string toupper $item] \
	  ]
	set name [Fort::Completion::electricStyle $contractionBodies($item) $m]
	foreach styledItem $styledItems {
	    set ${m}electrics($styledItem) "×È$name"
	}
    }
    
    array set specialBodies [list \
      "d'c"     "×ÈdoContinue" \
      "d'e"     "×ÈdoEndDo" \
      "d'u"     "×ÈdoUntil" \
      "d'w"     "×ÈdoWhile" \
      "e'i"     "×ÈelseIf" \
      "i't"     "×ÈifThen" \
      "i'e"     "×ÈifElse" \
      "w'd"     "×Èwhile" \
      ]
    
    foreach item [array names specialBodies] {
	set styledItems [list $item \
	  [string tolower $item] \
	  [string totitle $item] \
	  [string toupper $item] \
	  ]
	foreach styledItem $styledItems {
	    set ${m}electrics($styledItem) $specialBodies($item)
	}
    }
    # -----------------------------------------------------------------------
    # 
    # Functions
    # 
    
    # Functions that take a single (argument).
    set functions [list \
      "abs" "acos" "aimag" "asin" "atan" "atan2" "conjg" "cos" "cosh" "dble" \
      "dim" "dprod" "exp" "ichar" "len" "lge" "lgt" "lle" "llt" "log" "log10" \
      "max" "min" "mod" "sign" "sin" "sinh" "sqrt" "tan" "tanh" \
      \
      "achar" "adjustl" "adjustr" "aint" "all" "allocated" "alog" "alog10" \
      "amax0" "amax1" "amin0" "amin1" "amod" "anint" "any" "associated" \
      "bit_size" "btest" "cabs" "ccos" "ceiling" "cexp" "char" "clog" \
      "cmplx" "count" "cshift" "csin" "csqrt" "dabs" "dacos" "dasin" \
      "datan" "datan2" "date_and_time" "dcos" "dcosh" "ddim" "ddlog" "dexp" \
      "digits" "dint" "dlog10" "dmax1" "dmin1" "dmod" "dnint" "dot_product" \
      "dsign" "dsin" "dsinh" "dsqrt" "dtan" "dtanh" "eoshift" "epsilon" \
      "exponent" "float" "floor" "fraction" "huge" "iabs" "iachar" "iand" \
      "ibclr" "ibits" "ibset" "idim" "idint" "idnint" "ieor" "ifix" "index" \
      "int" "ior" "ishft" "ishftc" "isign" "kind" "lbound" "len_trim" \
      "matmul" "max0" "max1" "maxexponent" "maxloc" "maxval" \
      "merge" "min0" "min1" "minexponent" "minloc" "minval" "modulo" \
      "mvbits" "nearest" "nint" "not" "pack" "precision" "present" \
      "product" "radix" "random_number" "random_seed" "range" "repeat" \
      "reshape" "rrspacing" "scale" "scan" "selected_int_kind" \
      "selected_real_kind" "set_exponent" "shape" "size" "sngl" "spacing" \
      "spread" "sum" "system_clock" "tiny" "transfer" "transpose" "trim" \
      "ubound" "unpack" "verify" \
      ]
    set pad [string repeat " " [set ${m}modeVars(spacesAfterFunction)]]
    foreach item $functions {
	set Item [string totitle $item]
	set ITEM [string toupper $item]
	set name [Fort::Completion::electricStyle $item $m]
	foreach styledItem [list $item $Item $ITEM] {
	    if {($styledItem eq $name)} {
		set ${m}electrics($styledItem) "${pad}(¥¥)¥¥"
	    } else {
		set ${m}electrics($styledItem) "×kill0${name}${pad}(¥¥)¥¥"
	    }
	    lappend ${m}cmds $styledItem
	}
    }
    
    # Make sure that this list of properly sorted.
    set ${m}cmds [lsort -dictionary -unique [set ${m}cmds]]
    return
}

# Call this now.
Fort::Completion::rebuildElectrics

##
 # --------------------------------------------------------------------------
 # 
 # "Fort::Completion::specialElectric" --
 # 
 # Insert electric templates that are too complicated for "Fortelectrics"
 # entries.  The list of "Fort::Completion::specialCompletions" is defined
 # above in the [namespace] evaluation when this file is first sourced.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::Completion::specialElectric {{m "Fort"}} {
    
    global ${m}modeVars 
    
    variable lastDoChoice
    variable specialCompletions
    
    set lastWord [string tolower [completion::lastWord posPre]]
    if {([lsearch [string tolower $specialCompletions] $lastWord] == -1)} {
        return 0
    }
    set posCur [getPos]
    set posBeg [pos::lineStart $posCur]
    set posEnd [pos::lineEnd $posCur]
    # Set up some string shortcuts.
    foreach word {"if" "then" "else" "end" "do" "while" "continue" "until"} {
	set [string toupper $word] [Fort::Completion::electricStyle $word $m]
    }
    set lexp "(¥logical-expression¥)"
    set pad1 [string repeat " " [set ${m}modeVars(spaceAfterIf)]]
    set pad2 [string repeat " " [set ${m}modeVars(elseifIsSingleWord)]]
    set pad3 [string repeat " " [set ${m}modeVars(endifEnddoAreSingleWords)]]
    set pad4 [string repeat " " [set ${m}modeVars(spacesAfterCommand)]]
    
    switch -- $lastWord {
	"continue" {
	    replaceText $posPre $posCur $CONTINUE
	    bind::IndentLine
	    return 0
	}
	"do" {
	    set lastDoOptions [list "Continue" "EndDo" "While É EndDo" "Until"]
	    set p "End the DO statement with:"
	    set L [list $lastDoChoice]
	    set lastDoChoice [listpick -p $p -L $L $lastDoOptions]
	    set lastWord [string tolower $lastDoChoice]
	}
	"else" {
	    replaceText $posPre $posCur $ELSE
	    bind::IndentLine
	    append completion "\r\t¥statement¥"
        }
	"elseif" {
	    replaceText $posPre $posCur $ELSE $pad2 $IF
	    bind::IndentLine
	    append completion $pad1 $lexp " " $THEN "\r\t¥statement¥"
	}
	"enddo" {
	    replaceText $posPre $posCur $END $pad3 $DO
	    bind::IndentLine
	    return 1
	}
	"ifthen" {
	    deleteText $posPre $posCur
	    append completion $IF $pad1 $lexp " " $THEN \
	      "\r\t¥statement¥\r" $END $pad3 $IF
	}
        "ifelse" {
	    deleteText $posPre $posCur
	    append completion $IF $pad1 $lexp " " $THEN \
	      "\r\t¥statement¥\r" $ELSE "\r\t¥statement¥" "\r" $END $pad3 $IF
        }
    }
    # This second pass is just for DO commands.
    switch -- $lastWord {
	"continue" - "docontinue" {
	    deleteText $posPre $posCur
	    append completion $DO " ¥label¥ ¥var¥=¥expr¥" \
	      "\r\t¥statement¥\r\t" $CONTINUE "¥¥"
	}
	"dowhile" - "while É enddo" {
	    deleteText $posPre $posCur
	    append completion $DO " " $WHILE $pad4 $lexp \
	      "\r\t¥statement¥\r" $END $pad3 $DO "¥¥"
	}
	"doenddo" - "enddo" {
	    deleteText $posPre $posCur
	    append completion $DO \
	      "\r\t¥statement¥\r" $END $pad3 $DO "¥¥"
	}
	"while" - "whiledo" {
	    deleteText $posPre $posCur
	    append completion $WHILE $pad4 $lexp " " $DO \
	      "\r\t¥statement¥\r" $END $pad3 $DO "¥¥"
	}
	"until" - "dountil" {
	    deleteText $posPre $posCur
	    append completion $DO \
	      "\r\t¥statement¥" "\r" $UNTIL $pad4 $lexp "¥¥"
	}
    }
    elec::Insertion $completion
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::Completion::continueLabel" --
 # 
 # Automatically insert labels for CONTINUE statements based on a previous DO
 # label.  If the user types in a label in a DO statement and then presses
 # the Complete key, this label will be inserted into the next "orphaned"
 # CONTINUE line.  If, on the other hand, the user attempts to complete a
 # CONTINUE statement then the label of a previous DO will be instered in the
 # proper columns of the current line.
 # 
 # In all cases we assume that we're not dealing with nested DO statements!
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::Completion::continueLabel {{m "Fort"}} {
    
    set pos  [getPos]
    set text [getText [pos::lineStart [getPos]] $pos]
    set pat1 {^[\t ]+do[\t ]+([0-9]+)}
    set pat2 {^[\t ]+continue}
    
    if {[regexp -nocase -- $pat1 $text -> label]} {
        # The user just typed in a label for this DO statement.  Search
        # forward for an orphaned CONTINUE.
	set match [search -n -s -f 1 -r 1 -i 1 -- $pat2 $pos]
	if {![llength $match]} {
	    error "Cancelled -- couldn't find a CONTINUE statement."
	}
	set rowPosBeg [lindex $match 0]
	switch -- [string length $label] {
	    "1" - "2" - "3" - "4" {
		set labelBeg [pos::math $rowPosBeg + 1]
	    }
	    "5" {
		set labelBeg $rowPosBeg
	    }
	    default {
		error "Cancelled -- the label cannot be longer than 5 characters."
	    }
	}
	set labelEnd [pos::math $labelBeg + [string length $label]]
	set posCur [getPos]
	replaceText $labelBeg $labelEnd $label
	goto $labelBeg
	bind::IndentLine
	goto $posCur
	return 1
    } elseif {[regexp -nocase -- $pat2 $text]} {
        # The user is in "CONTINUE" line.  Search backward for the most
        # recent DO that doesn't have a matching CONTINUE, but don't look
        # further back than the current routine definition.
	set rowPosBeg [pos::lineStart $pos]
	set rowPosEnd [pos::lineEnd $pos]
	set pat3      {^[^cC*!][[\t ]\w]*(subroutine|.*function|entry|program)[\t ]+(\w+)}
	set pat4      {^[\t ]+do[\t ]+([0-9]+)([^0-9]|$)}
	set subMatch  [search -n -s -f 0 -r 1 -i 1 -- $pat3 $pos]
	if {[llength $subMatch]} {
	    set posL [pos::lineStart [lindex $subMatch 0]]
	} else {
	    set posL [minPos]
	}
	# Find a previous DO statement.
	set match [search -n -s -f 0 -r 1 -i 1 -l $posL -- $pat4 $pos]
	if {![llength $match]} {
	    error "Cancelled -- couldn't find a previous DO statement."
	}
	regexp -nocase -- $pat4 [eval getText $match] -> label
	switch -- [string length $label] {
	    "1" - "2" - "3" - "4" {
		set labelBeg [pos::math $rowPosBeg + 1]
	    }
	    "5" {
		set labelBeg $rowPosBeg
	    }
	    default {
		error "Cancelled -- the label cannot be longer than 5 characters."
	    }
	}
	set labelEnd [pos::math $labelBeg + [string length $label]]
	replaceText $labelBeg $labelEnd $label
	bind::IndentLine
	return 1
    } else {
        return 0
    }
}

# ===========================================================================
# 
# .