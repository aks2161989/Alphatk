# to autoload this file
proc m2Syntax.tcl {} {}


namespace eval M2 {}


 
#===========================================================================
# ×××× RESERVED WORDS ×××× #
#===========================================================================
# Reserved words needed by M2::jumpToTemplatePlaceHolder for proper, case sensitive functioning 
# and indentations. M2::returnCompleteWords get special treatment, i.e. moving cursor within line
set M2::returnCompleteWords "FOR FROM IF"      
set M2::returnWords "[set M2::returnCompleteWords] BEGIN CONST ELSE ELSIF THEN WHILE PROCEDURE WITH" 
set M2::returnWords "[set M2::returnWords] MODULE REPEAT LOOP TYPE VAR"

# Reserved words automatically triggering a template if a <space bar> is typed afterwards
set M2::spaceWords  "CASE WHILE FOR IF if ELSIF REPEAT FROM PROCEDURE IMPLEMENTATION DEFINITION LOOP MODULE WITH"
# lower case if is on purpose in above list

# Reserved words automatically expandable by Cmd^Tab or ESC <space bar>
set M2::expandWords "ARRAY BOOLEAN BITSET BY CARDINAL CHAR DO END SET QUALIFIED DIV MOD IN NOT AND OR EXIT"
# MacMETH specific elementary data types (later than Wirth, 1982. Programing in Modula-2, ed. 2)
set M2::expandWords "[set M2::expandWords] LONGCARD LONGINT LONGREAL"
# PROC is on purpose omitted cos' of conflict with PROCEDURE
set M2::expandWords " [set M2::expandWords] IMPORT EXPORT INTEGER OF POINTER REAL RECORD RETURN TO UNTIL"
set M2::expandWords [lsort "[set M2::returnWords] [set M2::spaceWords] [set M2::expandWords]"]
# proce, FALSE, and TRUE have on purpose been omitted from above list
set M2::spaceWords "${M2::spaceWords} proce"

# Reserved words which can trigger template by <space bar> or be expanded by M2Completions.tcl
set M2::doubleDefinedWords {if}

# Standard procedures (predefined, some may be overloaded)
set M2::standardProcs "ABS CAP CHR FLOAT HIGH ODD ORD TRUNC DEC EXCL HALT INC INCL MIN MAX SIZE NEW DISPOSE"
# VAL has on purpose been omitted from above list 
# MacMETH specific standard procedures (later than Wirth, 1982. Programing in Modula-2, ed. 2)
set M2::standardProcs "[set M2::standardProcs] FLOATD LONG SHORT TRUNCD"



#===========================================================================
# ×××× Colorization ×××× #
#===========================================================================
proc M2::colorizeM2 {args} {
    global M2modeVars
    global M2::expandWords
    global M2::standardProcs
    regModeKeywords -k $M2modeVars(keywordColor) \
      -b {(*} {*)} -c $M2modeVars(commentColor) \
      -s $M2modeVars(stringColor) \
      M2 [set M2::expandWords]
    regModeKeywords -a -k $M2modeVars(standardProcColor) \
      M2 [set M2::standardProcs]
}

# Activate it
M2::colorizeM2


# Reporting that end of this script has been reached
status::msg "m2Syntax.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote "m2Syntax.tcl for Programing in Modula-2 loaded"
}

