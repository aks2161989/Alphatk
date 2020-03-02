# to autoload this file (tabsize:8)
proc m2Templates.tcl {} {}

#================================================================================
# ×××× M2 Templates ×××× #
#================================================================================

namespace eval M2 {}

#================================================================================
# Determine which routine is to be used in templates as the new line routine
# depending on the Alpha version in use

proc M2::configTemplateReturn {} {
    global M2templateReturn
    set M2templateReturn M2::jumpEOLNewLn
    # alertnote "Having configured M2templateReturn"
}

# the following seems never to be executed while autoloading this m2Templates.tcl
# Bug in Alpha?  => this file can't be autoloaded to work properly
M2::configTemplateReturn

# # Alpha Pre7 routine
# proc oldCarrRet {} {
# 	carriageReturn
# }

# new Alpha > 7 routine
proc M2::jumpEOLNewLn {} {
    M2::jumpEOLNewLnIndent ""
}


#===========================================================================
# ×××× Aux Routines ×××× #
#===========================================================================

proc M2::authorShip {} {
    global M2Author
    if {([info exists M2Author]) && ("$M2Author" == "First Last") | (![info exists M2Author])} then {
	alertnote "It appears you have never identified yourself and M2 mode needs now your name!"
	if {[M2::configAuthor]} {} 
    }
    return "$M2Author"
}

proc M2::initials {} {
  set author [M2::authorShip]
  return "[string index [lindex "$author" 0]  0][string index [lindex "$author" 1]  0]"
}


#===========================================================================
proc M2::askForModuleName {prompt} {
	global M2IsLocalModule
	set askUser 1
	set modName ""
	while {$askUser == 1} {
		set modName [prompt "$prompt" "$modName"]
		set askUser 0
		if {([string length $modName] < 1)} {
			set modName ""
		}
		if {[regexp {[^A-Za-z0-9]} $modName]} then {
			set quest "Ò$modNameÒ contains illegal characters. You wish to change it?"
			if {[askyesno $quest] == "yes"} {
		        set askUser 1
			} else {
				set modName ""
			}
		}
		if {($askUser == 0)} then {
		    if { ( ! $M2IsLocalModule) && ([string length $modName] > 12)} then {
		        set curLength [string length $modName]
			set quest "Ò$modNameÒ with $curLength chars is too long (> 12 chars). You wish to change it?"
			if {[askyesno $quest] == "yes"} {
		        set askUser 1
			} else {
				set modName ""
			}
		    }
		}
	}
	return $modName
}

#===========================================================================
proc M2::openOrMakeFile {prompt ext} {
	if {$prompt == ""} then {
		set modName "$ext"
		set modFName "$modName"
	} else {
		set modName [M2::askForModuleName $prompt]
		set modFName "$modName.$ext"
	}
	if {$modName == ""} then { return }
	set winList [winNames]
	set foundFName [lsearch $winList $modFName]
	if { $foundFName == $modFName } then {
		# File already exists and is open
		bringToFront $modFName
	} else {
		# Create new file with the proper name
		new -n $modFName
	}
	set modName [file tail $modFName]
	set modName [file rootname $modName]
	return $modName
}


#================================================================================
# ×××× Template Bodys ×××× #
#================================================================================
# Note, % means next line. To customize the template expansion, find the string
# "M2 TEMPLATES". Procedure and module templates are coded as procedures (see below). Thus, be 
# careful with customizing.  Note also, there is a IF and if variant, the former spreading out
# IF THEN ELSE END(*IF*) over several lines, the latter keeping all in one line (coded as proc).

set M2::templateBodys(CASE) "  OF%| (*. .*):%  (*. .*);%| (*. .*):%  (*. .*);%ELSE%  (*. .*);%END(*CASE*);"
set M2::templateBodys(FOR) "  :=  TO  DO%END(*FOR*);"
set M2::templateBodys(WHILE) " () DO%END(*WHILE*);"
set M2::templateBodys(WITH) "  DO%END(*WITH*);"
set M2::templateBodys(REPEAT) "%UNTIL (¥);"
set M2::templateBodys(LOOP) "%END(*LOOP*);"
set M2::templateBodys(IF) "  THEN%ELSE%END(*IF*);"
set M2::templateBodys(if) "IF  THEN  ELSE  END;"
set M2::templateBodys(ELSIF) "  THEN"
set M2::templateBodys(FROM) "  IMPORT ;"
set M2::templateBodys(proce) "PROCEDURE "




proc M2::insertTemplateBody {name} {
	global M2::templateBodys
	set pos [getPos]
	set start [lineStart $pos]
	set indent [eval getText [search -s -r 1 -f 1 -n -- "\[ \\t\]*" $start]]
	insertText [lindex [split [set M2::templateBodys($name)] "%"] 0]
	foreach bodyLine [lrange [split [set M2::templateBodys($name)] "%"] 1 100] {
		insertText \r${indent}${bodyLine}
	}
	goto $pos
}



#===========================================================================
# ×××× Template and Expansion (space after keyword) Routines ×××× #
#===========================================================================

#================================================================================
proc M2::smcmdCASE {} {
	# Used by calling submenu M2/Templates/CASE
	insertText "CASE"
	M2::templateCASE
}
proc M2::templateCASE {} {
	# Used while expanding reserved word CASE
	M2::insertTemplateBody CASE
	goto [pos::math [getPos] +1]
}

#================================================================================
proc M2::smcmdFOR {} {
	# Used by calling submenu M2/Templates/FOR
	insertText "FOR"
	M2::templateFOR
}
proc M2::templateFOR {} {
	# Used while expanding reserved word FOR
	M2::insertTemplateBody FOR
	goto [pos::math [getPos] +1]
}

#================================================================================
proc M2::smcmdWHILE {} {
	# Used by calling submenu M2/Templates/WHILE
	insertText "WHILE"
	M2::templateWHILE
}
proc M2::templateWHILE {} {
	# Used while expanding reserved word WHILE
	M2::insertTemplateBody WHILE
	goto [pos::math [getPos] +2]
}

#================================================================================
proc M2::smcmdWITH {} {
	# Used by calling submenu M2/Templates/WITH
	insertText "WITH"
	M2::templateWITH
}
proc M2::templateWITH {} {
	# Used while expanding reserved word WITH
	M2::insertTemplateBody WITH
	goto [pos::math [getPos] +1]
}

#================================================================================
proc M2::smcmdIF {} {
	# Used by calling submenu M2/Templates/IF
	insertText "IF"
	M2::templateIF
}

proc M2::templateIF {} {
	# Used while expanding reserved word IF
	M2::insertTemplateBody IF
	goto [pos::math [getPos] +1]
}

#================================================================================
proc M2::smcmdifononeline {} { 
	# Used by calling submenu M2/Templates/if
	insertText "if"
	M2::templateif
}

proc M2::templateif {} {
	backSpace 
	backSpace
	set pos [getPos]
	# insertText "IF  THEN  ELSE  END;"
	M2::insertTemplateBody if
	goto [pos::math $pos + 3]
}

#================================================================================
proc M2::smcmdELSIF {} {
	# Used by calling submenu M2/Templates/IF
	insertText "ELSIF"
	M2::templateELSIF
}

proc M2::templateELSIF {} {
	# Used while expanding reserved word ELSIF
	M2::insertTemplateBody ELSIF
	goto [pos::math [getPos] +1]
}

#================================================================================
proc M2::smcmdREPEAT {} {
	# Used by calling submenu M2/Templates/REPEAT
	insertText "REPEAT"
	M2::templateREPEAT
}

proc M2::templateREPEAT {} {
	# Used while expanding reserved word REPEAT
	M2::insertTemplateBody REPEAT
	M2::tabOrJumpOutOfLnAndReturn
}

#================================================================================
proc M2::smcmdLOOP {} {
	# Used by calling submenu M2/Templates/LOOP
	insertText "LOOP"
	M2::templateLOOP
}

proc M2::templateLOOP {} {
	# Used while expanding reserved word LOOP
	M2::insertTemplateBody LOOP
	M2::tabOrJumpOutOfLnAndReturn
}

#================================================================================
proc M2::smcmdFROMIMPORT {} {
	# Used by calling submenu M2/Templates/FROM IMPORT
	insertText "FROM"
	M2::templateFROM
}

proc M2::templateFROM {} {
	# Used while expanding reserved word FROM
	M2::insertTemplateBody FROM
	goto [pos::math [getPos] +1]
}


#================================================================================
proc M2::smcmdPROCEDURE {} {
	# Used by calling submenu M2/Templates/PROCEDURE
	insertText "PROCEDURE"
	M2::templatePROCEDURE
}

proc M2::templatePROCEDURE {} {
	set winName [lindex [winNames -f] 0]
	set procName [prompt "PROCEDURE Name: " ""]
	bringToFront $winName
	if {[string length $procName] < 1} {
		return;
	}
	set pos [pos::math [getPos] +1 +[string length $procName]]
	insertText " $procName;"
	if {[string toupper [M2::fileExt]] != "DEF"} {
		M2::jumpEOLNewLnIndent ""
		insertText "BEGIN (* $procName *)"
		M2::jumpEOLNewLnIndent ""
		insertText "END $procName;"
		M2::jumpEOLNewLnIndent ""
	}
	goto $pos
}


#================================================================================
# proc M2::smcmdproce {} { 
# 	# Used by calling submenu M2/Templates/proce
# 	insertText "proce"
# 	M2::templateproce
# }

proc M2::templateproce {} {
	backSpace 
	backSpace
	backSpace 
	backSpace
	backSpace
	set pos [getPos]
	# insertText "PROCEDURE "
	M2::insertTemplateBody proce
	goto [pos::math $pos + 10]
}


#================================================================================
proc M2::smcmdNewProgramMODULE {} {
	# Used by calling submenu M2/Templates/New Program MODULE
	global M2IsLocalModule
	global M2IsProgModule
	set M2IsLocalModule 0
	set M2IsProgModule 1
	set modName [M2::openOrMakeFile "Program MODULE Name : " "MOD"]
	if {$modName != ""} then {
		insertText "MODULE"
		M2::modBODY $modName
		M2::prevPlaceholder
		M2::prevPlaceholder
	}
	set M2IsProgModule 0
}

proc M2::templateMODULE {} {
	# Used while expanding reserved word MODULE resulting in a local module
	global M2IsLocalModule
	global M2IsProgModule
	set M2IsLocalModule 1
	set M2IsProgModule 0
	set modName [M2::askForModuleName "Local MODULE Name: "]
	if {$modName != ""} then {
		M2::modBODY $modName
		M2::prevPlaceholder
		M2::prevPlaceholder
	}
	set M2IsLocalModule 0
}


set M2IsProgModule 0
set M2IsLocalModule 0

#================================================================================
proc M2::modBODY {modName} {
	global M2RightShift
	global M2templateReturn
	global M2templateParts	
	global M2IsProgModule
	global M2IsLocalModule
	# attempt to use this file with autoloading, yet this always failed. Bug in Alpha?
        if {![info exists M2templateReturn]} {M2::configTemplateReturn}
	if {[string length $modName] < 1} {
		return;
	}
	insertText " $modName;"
	if { $M2IsLocalModule } then {
	    insertText " (******************************************************)"
	    $M2templateReturn
	    $M2templateReturn
	    insertText $M2RightShift
	    insertText "IMPORT (*.  .*)"
	    $M2templateReturn
	    insertText "EXPORT (*.  .*)"
	    $M2templateReturn
	    set pos [getPos]
	    $M2templateReturn
	    M2::unIndent
	} else {
	    $M2templateReturn
	    $M2templateReturn
	    insertText $M2RightShift
	    if { $M2IsProgModule } then {
		insertText "(*******************************************************************"
		$M2templateReturn
		insertText $M2RightShift
		$M2templateReturn
		insertText $M2RightShift
		insertText "Module  $modName     (Version 1.0)"
		$M2templateReturn
		$M2templateReturn
		insertText $M2RightShift
		insertText "Copyright (c) [M2::currentYear] by [M2::authorShip] "
		$M2templateReturn
		if {[info exists M2templateParts(copyright)] && ("$M2templateParts(copyright)" != "")} {
		insertText "$M2templateParts(copyright)"
		$M2templateReturn
		}
		$M2templateReturn
		M2::unIndent
		insertText "Purpose   (*.  purpose  .*)"
		$M2templateReturn
		$M2templateReturn
		$M2templateReturn
		insertText "Programming"
		$M2templateReturn
		$M2templateReturn
		insertText $M2RightShift
		insertText "o Design and Implementation"
		$M2templateReturn
		insertText $M2RightShift
		insertText "[M2::authorShip]         [M2::currentDate]"
		$M2templateReturn
		$M2templateReturn
		M2::unIndent
		if {[info exists M2templateParts(URLs)] && ("$M2templateParts(URLs)" != "")} then {
		    insertText "$M2templateParts(URLs)"
		    $M2templateReturn
		}
		$M2templateReturn
		M2::unIndent
		M2::unIndent
	    } else {
		insertText "(*"
		$M2templateReturn
		insertText $M2RightShift
	    }
	    insertText "Implementation and Revisions:"
	    $M2templateReturn
	    insertText "============================"
	    $M2templateReturn
	    $M2templateReturn
	    insertText "Author  Date        Description of change"
	    $M2templateReturn
	    insertText "------  ----        ---------------------"
	    $M2templateReturn
	    insertText "[M2::initials]      [M2::currentDate]"
	    insertText "  First implementation"
	    $M2templateReturn
	    $M2templateReturn
	    M2::unIndent
	    if { $M2IsProgModule } then {
		insertText "*******************************************************************)"
		M2::HyperiseURLs
	    } else {
		insertText "*)"
	    }
	    $M2templateReturn
	    $M2templateReturn
	    if { $M2IsProgModule } then {
		insertText "(*. Imports .*)"
		$M2templateReturn
		set pos [getPos]
	    } elseif { ! $M2IsLocalModule } then {
		set pos [getPos]
		M2::breakTheLine
	    }
	    M2::breakTheLine
	}
	insertText "BEGIN (* $modName *)"
	$M2templateReturn
	if { $M2IsLocalModule } then {
	    insertText "END $modName;"
	    insertText " (*********************************************************)"
	    $M2templateReturn
	} else {
	    insertText "END $modName."
	}
	$M2templateReturn
	goto $pos
}

#================================================================================
proc M2::defBODY {modName} {
	global M2RightShift
	global M2templateReturn
	global M2templateParts
	# attempt to use this file with autoloading, yet this always failed. Bug in Alpha?
        if {![info exists M2templateReturn]} {M2::configTemplateReturn}
	if {[string length $modName] < 1} {
		return;
	}
	insertText " $modName;"
	$M2templateReturn
	$M2templateReturn
	insertText $M2RightShift
	insertText "(*******************************************************************"
	$M2templateReturn
	$M2templateReturn
	insertText $M2RightShift
	insertText "Module  $modName     (Version 1.0)"
	$M2templateReturn
	$M2templateReturn
	insertText $M2RightShift
	insertText "Copyright (c) [M2::currentYear] by [M2::authorShip] "
	$M2templateReturn
	if {[info exists M2templateParts(copyright)] && ("$M2templateParts(copyright)" != "")} {
    	insertText "$M2templateParts(copyright)"
    	$M2templateReturn
        }
	$M2templateReturn
	M2::unIndent
	insertText "Purpose   (*.  purpose  .*)"
	$M2templateReturn
	$M2templateReturn
	insertText "Remarks   (*.  remarks  .*)"
	$M2templateReturn
	$M2templateReturn
	$M2templateReturn
	insertText "Programming"
	$M2templateReturn
	$M2templateReturn
	insertText $M2RightShift
	insertText "o Design"
	$M2templateReturn
	insertText $M2RightShift
	insertText "[M2::authorShip]         [M2::currentDate]"
	$M2templateReturn
	$M2templateReturn
	M2::unIndent
	insertText "o Implementation"
	$M2templateReturn
	insertText $M2RightShift
	insertText "[M2::authorShip]         [M2::currentDate]"
	$M2templateReturn
	$M2templateReturn
	$M2templateReturn
	M2::unIndent
	M2::unIndent
	if {[info exists M2templateParts(address)] && ("$M2templateParts(address)" != "")} {
    	insertText "$M2templateParts(address)"
    	$M2templateReturn
	}
	if {[info exists M2templateParts(URLs)] && ("$M2templateParts(URLs)" != "")} then {
    	insertText "$M2templateParts(URLs)"
    	$M2templateReturn
	}
	$M2templateReturn
	M2::unIndent
	M2::unIndent
	insertText "Last revision of definition:  [M2::currentDate]  [M2::initials]"
	$M2templateReturn
	$M2templateReturn
	M2::unIndent
	insertText "*******************************************************************)"
	$M2templateReturn
	$M2templateReturn
	insertText "(*.  exports  .*)"
	$M2templateReturn
	$M2templateReturn
	M2::unIndent
	insertText "END $modName."
	$M2templateReturn
	M2::HyperiseURLs
}

#================================================================================
proc M2::smcmdNewDEFINITIONModule {} {
	# Used by calling submenu M2/Templates/New DEFINITION Module
	global M2IsLocalModule
	global M2IsProgModule
	set M2IsLocalModule 0
	set M2IsProgModule 0
	set modName [M2::openOrMakeFile "DEFINITION MODULE Name: " "DEF"]
	if {$modName != ""} then {
		insertText "DEFINITION MODULE"
		M2::defBODY $modName
		M2::prevPlaceholder
		M2::prevPlaceholder
		M2::prevPlaceholder
	}
}

proc M2::templateDEFINITION {} {
	# Used while expanding reserved word DEFINITION
	global M2IsLocalModule
	global M2IsProgModule
	set M2IsLocalModule 0
	set M2IsProgModule 0
	insertText " MODULE"
	set modName [M2::askForModuleName "DEFINITION MODULE Name: "]
	if {$modName != ""} then {
		M2::defBODY $modName
		M2::prevPlaceholder
		M2::prevPlaceholder
		M2::prevPlaceholder
	}
}

#================================================================================

proc M2::smcmdNewIMPLEMENTATIONModule {} {
	# Used by calling submenu M2/Templates/New IMPLEMENTATION Module
	global M2IsLocalModule
	global M2IsProgModule
	set M2IsLocalModule 0
	set M2IsProgModule 0
	set modName [M2::openOrMakeFile "IMPLEMENTATION MODULE Name : " "MOD"]
	if {$modName != ""} then {
		set M2IsLocalModule 0
		set M2IsProgModule 0
		insertText "IMPLEMENTATION MODULE"
		M2::modBODY $modName
	}
}

proc M2::templateIMPLEMENTATION {} {
	# Used while expanding reserved word IMPLEMENTATION
	global M2IsLocalModule
	global M2IsProgModule
	set M2IsLocalModule 0
	set M2IsProgModule 0
	set modName [M2::askForModuleName "IMPLEMENTATION MODULE Name: "]
	if {$modName != ""} then {
		insertText " MODULE"
		M2::modBODY $modName
	}
}


#================================================================================
# ×××× Autogenerate IMPLEMENTATION from DEFINITION Module ×××× #
#================================================================================
#
# Precondition: Syntactically correct DEFINITION Module

proc checkForSectionMarker {from nextProcPos winName} {
    global M2RightShift
    set pos [search -s -r 1 -f 1 -i 0 -n -- "\\(\\*\\#\\#\\#\\#\\#" $from]
    if {($pos != "") && ($nextProcPos != "") && ([pos::math [lindex $pos 0] < $nextProcPos])} {
	# alertnote "pos = [lindex $pos 0] [lindex $pos 1]"
	set cmtBeg [pos::prevLineStart [lindex $pos 0]]
	set cmtEnd [pos::nextLineEnd   [lindex $pos 1]]
	set text [getText $cmtBeg $cmtEnd]
	# alertnote "'${text}\r'"
	insertText -w $winName "\r${text}\r\r"
    }
}

proc M2::defToMod {} {
    global M2RightShift
    set errMsg "Operation aborted - not a syntactically correct DEFINITION MODULE"
    set winName [lindex [winNames -f] 0]
    if {$winName == ""} return
    set modName [getText [minPos] [nextLineStart [minPos]]]
    if {[lindex $modName 0] != "DEFINITION"} {
	beep
	alertnote "$errMsg"
	return
    }
    if {[lindex $modName 1] != "MODULE"} {
	beep
	alertnote "$errMsg"
	return
    }
    set modName [lindex $modName 2]
    set modName [string range $modName 0 [expr [string length $modName] - 2]]
    if {$modName == ""} {
	beep
	alertnote "$errMsg"
	return
    }
    set modName [M2::openOrMakeFile "" "$modName.MOD"]
    insertText "IMPLEMENTATION MODULE "
    M2::modBODY $modName
    set newName [lindex [winNames -f] 0]
    M2::unIndent
    bringToFront $winName
    # Copy all imports
    set pos [search -s -r 1 -f 1 -i 0 -n -- "FROM|IMPORT" [minPos]]
    set end [search -s -r 1 -f 1 -i 0 -n -- "TYPE|PROCEDURE|VAR|CONST|END" [minPos]]
    if {$pos != ""} {
	set pos [lindex $pos 0]
	set end [lindex $end 1]
	set text [getText [lineStart $pos] [lineStart $end]]
	insertText -w $newName $text
    }
    insertText -w $newName "\r$M2RightShift"
    set finalCursPos [getPos -w $newName]
    insertText -w $newName "\r\r"
    # Copy all procedure declarations and generate for each an empty body
    set end [minPos]
    set matchStr "PROCEDURE\[ \\t\]*\[A-Za-z0-9\]+\[ \\t\]*(\\(\[^\\)\]*\\))?\[^\\;\]*\;"
    set pos [search -s -r 1 -f 1  -i 0 -n -- $matchStr $end]
    checkForSectionMarker [minPos] [lindex $pos 0] $newName
    set end [lindex $pos 1]
    while {$pos != "" } {
	set from [lindex $pos 0]
	set text [getText [lineStart $from] [nextLineStart $end]]
	set insertion [format "%[string first [lindex $text 0] $text]s" ""]
	set procName [lindex [split "[lindex $text 1]" "(;"] 0]
	if {[regexp {\([^\*]} $text]} then {
	    # alertnote "procedure $procName has formal parameters"
	    if {![regexp {[^\*]\)} $text]} then {
		# alertnote "not entire par list yet found for $procName, search rest by increasing end"
		set pos [search -s -r 1 -f 1  -i 0 -n -- "\\(" $from]
		goto [pos::math [lindex $pos 0] + 1]
		if { ![catch {balance}] } then {
		    set end [selEnd]
		    set text [getText [lineStart $from] [nextLineStart $end]]
		} else {
		    set end [pos::math $from + 1]
		}
	    }
	}
	insertText -w $newName $text
	insertText -w $newName $insertion
	insertText -w $newName "BEGIN (* $procName *)"
	insertText -w $newName "\r"
	insertText -w $newName $insertion
	insertText -w $newName "END $procName;"
	insertText -w $newName "\r\r"	
	set pos [search -s -r 1 -f 1  -i 0 -n -- $matchStr $end]
	checkForSectionMarker $from [lindex $pos 0] $newName
	set end [lindex $pos 1]
    }
    bringToFront $newName
    win::ChangeMode M2
    # kill extra line at end
    nextLine
    backSpace
    nextLine
    # Add main section marker
    insertText $M2RightShift
    insertText "(***********************************)\r"
    insertText $M2RightShift
    insertText "(*#####   Module Management   #####*)\r"
    insertText $M2RightShift
    insertText "(***********************************)\r"
    insertText "\r"
    # Add body of init proc
    set initProc "Init$modName"
    insertText $M2RightShift
    insertText "PROCEDURE $initProc;"
    insertText "\r$M2RightShift"
    insertText "BEGIN (*$initProc*)"
    insertText "\r$M2RightShift"
    insertText "END $initProc;"
    insertText "\r$M2RightShift"
    insertText "\r"
    nextLine
    insertText $M2RightShift
    insertText "$initProc;"
    insertText "\r"
    # Set cursor between imports and first proc
    goto $finalCursPos
}




# Reporting that end of this script has been reached
status::msg "m2Templates.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2Templates.tcl for Programing in Modula-2 loaded"
}

