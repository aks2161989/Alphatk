# to autoload this file (tabsize:4)
proc m2Marking.tcl {} {}

#####################################################################################
# 
#   Author    Date        Modification
#   ------    ----        ------------
#    af       02.09.99    V 3.3b3 renamed M2::parseFuncs to M2::M2parseFuncs
#                         and M2::MarkFile to M2::M2MarkFile to allow for
#                         autoloading of this file. The older names are jumped 
#                         at directly by "curly braces"- and "M"-buttons. 
#    af       21.02.00    - Replacing braces in all regexp statements like 
#                          regexp {[ \t]*PROCEDURE[ \t]+([^\s;(]+)} $t all procName
# 			  with quotes and preceeding brackets "[" and "]" with "\" like
# 			   regexp "\[ \t\]*PROCEDURE\[ \t\]+(\[^\\r;(\]+)" $t all procName
#                         whenever a "\t" is in the expression (hint by 
#                         Dominique Dhumier).  Since I'm not sure how well the
#                         new expressions really are, I have left the previous ones
#                         as comments before the new ones.
#                         - Replacing any occurrence of \s with \r
#    af       09.05.01    M2::M2MarkFile does not mark project files
#    af       28.03.03    Added changes made by Vince on CVS server
#    af       08.05.03    V 3.8.9 
#                         Made lsort -dictionary conditional to Alpha >= 8
#    af       20.02.05    V 1.8 -> 1.9


#===========================================================================
# ×××× Marking: M-button and "curly braces"-button ×××× #
#===========================================================================

namespace eval M2 {}


## 
 # -------------------------------------------------------------------------
 #	 
 # "M2::parseFuncs" --
 #	
 #	This proc is called by the "braces" pop-up.  It returns a
 #	dynamically created, alphabetical, list of "pseudo-marks".
 #	
 #	Author:	Tom	Fetherston    Modified -trf
 # -------------------------------------------------------------------------
 #
 # called by M2::parseFuncs
proc M2::M2parseFuncs {} {
	global M2modeVars
	global M2::curAlphaV
	
	set pos [minPos]
	set l {}
	set markExpr $M2modeVars(funcExpr)
	set appearanceList {}
	# set procStmntExpr {[ \t]*PROCEDURE[ \t]*([^\s;(]+)[ \t]*[;(]}
	set procStmntExpr {[ \t]*PROCEDURE[ \t]*([^\n\r;(]+)[ \t]*[;(]}
	while {![catch {search -s -f 1 -r 1 -m 0 -i 0 "$procStmntExpr" $pos} res]} {
		set start [lindex $res 0]
		set firstNonWhitePastName [pos::math [lindex $res 1] - 1]
		# set end [nextLineStart $firstNonWhitePastName]
		set end $firstNonWhitePastName
		set t [getText $start $firstNonWhitePastName]
		set namePlusArgTypes {}
		set procName {}
		
		#start the pop-up tag with the procName 
		# regexp {[ \t]*PROCEDURE[ \t]+([^\s;(]+)} $t all procName
		regexp "\[ \t\]*PROCEDURE\[ \t\]+(\[^\\r\\n;(\]+)" $t all procName
		append namePlusArgTypes $procName 
		
		#get the string containing any arguments
		if {[lookAt $firstNonWhitePastName] == "\("} {
			set alStart [pos::math $firstNonWhitePastName + 1]
			set alEnd $alStart 
			catch {set alEnd   [pos::math [matchIt "\(" $alStart] - 1]}
			if {$alStart >= $alEnd} {
				set argsList {}
				append namePlusArgTypes " \{\}: v"
			} else {
				set argsList [getText  $alStart $alEnd ]
				set endStmnt [lindex [search -s -f 1 -r 1 -m 0 -i 0 {;} $alEnd] 0]
				set returnTypeStr [getText $alEnd $endStmnt]
				if {[regexp {:} $returnTypeStr]} {
					append namePlusArgTypes " \{"
					set tagTail "\}: v"
				} else {
					append namePlusArgTypes " \{"
					set tagTail "\}"
				} 
			} 
		} else {
			set argsList {}
		} 
		
		#extract each arg and determine if it is "value" or "VAR"
		if {[llength $argsList] > 0} {
			set argsList [split $argsList {;}] 
			foreach typingPart $argsList {
				set varPart [lindex [split $typingPart {:}] 0]
				switch -regexp $varPart {
				  "[ \t]*VAR*" {
					set args [lrange $varPart 1 end]
					set args [split $args {,}]
					foreach a $args {
						append namePlusArgTypes "v"
					}
				  }
				  "default" {
					set args [split $varPart {,}]
					foreach a $args {
						append namePlusArgTypes "¥"
					}
				  }
				}
			}
			append namePlusArgTypes $tagTail 
		} 
		
		set indx($namePlusArgTypes) [lineStart [pos::math $start - 1]]	
		
		#advance pos to where we want to start the next search from
        set pos $end
	}
	
	#we have collected all the procedures, now alphabetize them and 
	# associate each with its buffer position.

	set rtnRes {}

	set firstAlphaWithDictLSortV "8.0"
	if {[set M2::curAlphaV] >= $firstAlphaWithDictLSortV} {
		foreach procTag [lsort -dictionary [array names indx]] {
			lappend rtnRes $procTag [nextLineStart $indx($procTag)]
		}
	} else {
		foreach procTag [lsort -ignore [array names indx]] {
			lappend rtnRes $procTag [nextLineStart $indx($procTag)]
		}
	}
	
	return $rtnRes 
}

# called by M2::MarkFile     Modified -trf/af
proc M2::M2MarkFile {args} {
	global M2modeVars
	global M2::curAlphaV

	win::parseArgs win	
	
	# don't mark project files
	set extension [file extension $win]
	if {("$extension" == ".PRJ") | ("$extension" == ".prj")} then {
	    status::msg "It doesn't make sense to mark a project file"
	    return
	}
	
	# Local preferences of this procedure
	set alwaysListModsAndProcs 1
	# Listed structural marks are emphasized by pre- and suffixes
	# The algorithm assumes you are always using at least 1 "¥" in main marks
	set mainMrkPrefix "¥"
	set mainMrkSuffix ""
	set mainMrkOverviewPrefix "¥ "
	set mainMrkBigPrefix "$mainMrkOverviewPrefix"
	set mainMrkBigSuffix ""
	# Section marks can be marked in whichever way you like
	set subSecPrefix "-"
	set subSecSuffix ""
	set subSecOverviewPrefix "- "
	set subSecBigPrefix "$subSecOverviewPrefix"
	set subSecBigSuffix ""
	
	# Major parameters of this procedure derived from M2 preferences
	set sortAll $M2modeVars(sortListedItems)
	set mainSecMarks $M2modeVars(listMainStructuralMarks)
	set subSecMarks $M2modeVars(listSectionStructuralMarks)
	set listMods $M2modeVars(listModules)
	set listProcs $M2modeVars(listProcedures)
	set respectComments $M2modeVars(markSeesComments)
	if {$alwaysListModsAndProcs && !$mainSecMarks && !$subSecMarks && !$listProcs && !$listMods} then {
		# force quietly at least to list modules and procedures
		set listProcs 1
		set listMods 1
	}
	set themsg ""
	if $mainSecMarks { append themsg "main" }
	if $subSecMarks { if {$themsg != ""} {append themsg " and "} ; append themsg "section structural marks" }
	if $listMods { if {$themsg != ""} {append themsg ", "} ; append themsg "modules" }
	if $listProcs { if {$themsg != ""} {append themsg ", "} ; append themsg "procs" }
	if $sortAll { append themsg " (sorts)" } else { append themsg " (no sort)" }
	set themsg "Marking file for $themsg ..."
	status::msg "$themsg"

	
	# Remember current window positioning and selection to restore at end of M2::MarkFile
	set savePos [getPos -w $win]
	set saveSelEnd [selEnd -w $win]
	getWinInfo -w $win warr
	set saveTopLine "$warr(currline)"
	set saveTopPos [pos::fromRowCol -w $win $saveTopLine 1]
	
	# Now setup the marking expression according to current parameters
	set markExpr {}
	if {$listProcs} then {
		if {"$markExpr" != ""} { append markExpr {|} }
		# PROCEDURE recognized several times within same line
		# append markExpr {([ \t]*PROCEDURE[ \t]*[^\s;(]+)}
		append markExpr {([ \t]*PROCEDURE[ \t]*[^\r\n;(]+)}
	}
	if {$listMods} then {
		if {"$markExpr" != ""} { append markExpr {|} }
		# MODULE only recognized if preceeded by white space only
		# append markExpr {(^[ \t]*MODULE[ \t]*[^\s;]+)}
		append markExpr {(^[ \t]*MODULE[ \t]*[^\r\n;]+)}
	}
	if $mainSecMarks {
		if {"$markExpr" != ""} { append markExpr {|} }
		append markExpr {(^ *\(\*#####)}
	} 
	if $subSecMarks {
		if {"$markExpr" != ""} { append markExpr {|} }
		append markExpr {(^ *\(\*=====)}
	} 
	if {"$markExpr" == ""} then {
		# there is nothing to do 
		set msg "Your M2 preferences are set such that nothing will be listed! "
		append msg "To change this, use menu 'Config > Current Mode > Preferences' or F12." 
		alertnote "$msg"
		return
	}
	

	set pos [minPos -w $win]
	set l {}
	# Check wether begin of file contains MODULE specification and record it if match succeeds
	# set firstKeywordExpr {^[ \t]*((DEFINITION)|(IMPLEMENTATION)|)[ \t]*MODULE[ \t]*[^\s;]+}
	set firstKeywordExpr {^[ \t]*((DEFINITION)|(IMPLEMENTATION)|)[ \t]*MODULE[ \t]*[^\r\n;]+}
	if {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "$firstKeywordExpr" $pos} res]} then {
		set t [getText -w $win [lindex $res 0] [lindex $res 1]]
		# get the identifier of the module
        # regexp {(DEFINITION[ \t]*MODULE[ \t]*)([^\s;]+)} $t all beg ident
        if {[regexp "(DEFINITION\[ \t\]*MODULE\[ \t\]*)(\[^\\r\\n;\]+)" $t all beg ident]} then {
			set fstLnText "DEFINITION MODULE $ident:"
		# regexp {(IMPLEMENTATION[ \t]*MODULE[ \t]*)([^\s;]+)} $t all beg ident
		} elseif {[regexp "(IMPLEMENTATION\[ \t\]*MODULE\[ \t\]*)(\[^\\r\\n;\]+)" $t all beg ident]} then {
			set fstLnText "IMPLEMENTATION MODULE $ident:"
		# regexp {([ \t]*MODULE[ \t]*)([^\s;]+)} $t all beg ident
		} elseif {[regexp "(\[ \t\]*MODULE\[ \t\]*)(\[^\\r\\n;\]+)" $t all beg ident]} then {
			set fstLnText "PROGRAM MODULE $ident:"
		}
		# store it as encountered (regardless of sorting)
		lappend asEncountered $fstLnText
		set arr inds
		set ${arr}($fstLnText) [lineStart -w $win $pos]
		# skip very first DEFINITION or IMPLEMENTATION
		set pos [lindex $res 1]
	}
	set hasMarkers 0
	set rememberIndent 0
	set wasMainSecMark 0
	while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "$markExpr" $pos} res]} {
		set start [lindex $res 0]
		# ignore any matches in rest of line unless was a PROCEDURE
		set end [nextLineStart -w $win $start]
		set t [getText -w $win $start $end]
		set t [string trimleft $t ";"]
		if $listProcs {
			# test wether there are more than one procedure declared in same line.
			# If the case, reduce end such that next procedure can be detected 
			set tless [lrange $t 1 [llength $t]]
			set anotherProcInLine [lsearch -exact $tless PROCEDURE]
			if {$anotherProcInLine != -1} then {
				set end [lindex $res 1]
				set rememberIndent 1
			}
		}
		switch -regexp [lindex $t 0] {
			"PROCEDURE" {
				# match occurrs only if $listProcs
				if $respectComments {
					goto -w $win $res
					set selComment [M2::selectNestedM2Comment -w $win]
					# M2::selectNestedM2Comment is likely to overwrite current message
					status::msg "$themsg"
					set isInComment [lindex $selComment 0]
					if $isInComment {
						# ignore procedure, since it is within comment 
						set pos $end
						continue
					}
				}
				# regexp {([ \t]*)(PROCEDURE[ \t]*)([^\s;(]+)} $t all indent resWrd text
				regexp "(\[ \t\]*)(PROCEDURE\[ \t\]*)(\[^\\r\\n;(\]+)" $t all indent resWrd text
				if ![info exists oldIndent] {
					set isFirstProcInLine 1
				} else {
					set isFirstProcInLine 0
				}
				if !$sortAll { 
					if $rememberIndent {
						if $isFirstProcInLine {
							# initialize oldIndent with the indent detected by first proc in line
							set oldIndent "$indent" 
						} else {
							# overwrite indent with the one detected by first proc in line
							set indent "$oldIndent"
							if {$anotherProcInLine == -1} then {
								# was last
								set rememberIndent 0
								if [info exists oldIndent] {unset oldIndent}
							}
						}
					}
					if {[set indentLength [string length [text::maxSpaceForm $indent]]]} {
						set subIndentSize [expr $indentLength / [string length $M2modeVars(m2_indentAmount)] ]
						# never list procedures to the very left 
						# In particular Quick Ref files may contain '| PROCEDURE' with only one blank indent
						if {$subIndentSize == 0} then { set subIndentSize 1 }
						if $subSecMarks then {set subIndentSize [expr $subIndentSize + 5]}
						set text "[text::indentOf -w $win $subIndentSize]$text"
					} 			
				}
			}
			"MODULE" {
				# match occurrs only if $listMods
				# regexp {^([ \t]*)MODULE[ \t]*([^\s;(]+)} $t all indent text
				regexp "^(\[ \t\]*)MODULE\[ \t\]*(\[^\\r\\n;(\]+)" $t all indent text
				if $subSecMarks {
					# treat module lika a sub section
					if {$mainSecMarks && $listProcs} {
						# set text "-- MODULE $text --"
						set text "${subSecBigPrefix}MODULE $text${subSecBigSuffix}"
					} elseif !$listProcs {
						set text "${subSecOverviewPrefix}MODULE $text"
					} else {
						set text "${subSecPrefix}MODULE $text${subSecSuffix}"
					}
				} elseif $sortAll {
					set text "$text - MODULE"
				} else {
					if {!$sortAll && [set indentLength [string length [text::maxSpaceForm $indent]]]} { 
						set subIndentSize [expr $indentLength / [string length $M2modeVars(m2_indentAmount)] ]
						set text "[text::indentOf $subIndentSize]MODULE $text"
					} else {
						set text "MODULE $text"
					}					
				}
			}
			{[\(][*][\#]} { 
				# match occurrs only if $mainSecMarks
				set text {}
				regexp {\*#####   ([^#]*)   #####\*} $t all text
				set text [string trim $text]
				if {$subSecMarks && $listProcs} {
					# main marks need to be emphasized
					set text "${mainMrkBigPrefix}$text${mainMrkBigSuffix}"
				} elseif !$listProcs {
					# bullet is sufficient emphasis for a main mark 
					set text "${mainMrkOverviewPrefix}$text"
				} else {
					# recognize indentation to display scope if procedures are listed
					set text "${mainMrkPrefix}$text${mainMrkSuffix}"
				}
				set hasMarkers 1
				set wasMainSecMark 1
			}
			{[\(][*][=]} { 
				# match occurrs only if $subSecMarks
				set text {}
				regexp {\*======* *([^=]*) *=*=====\*} $t all text
				set text [string trim $text]
				if {$text != ""} then {
					if {$mainSecMarks && $listProcs} {
						set text "${subSecBigPrefix}$text${subSecBigSuffix}"
					} elseif !$listProcs {
						set text "${subSecOverviewPrefix}$text"
					} else {
						set text "${subSecPrefix} $text${subSecSuffix}"
					}			
					set hasMarkers 1
				} else {
					# Comment was just of form (*================*)
					set pos $end
					continue
				}
			}
		}
		set pos $end
		if !$sortAll {
			lappend asEncountered $text
			set arr inds
		} else {
			if {[string index $t 0] == ";"} {
				set arr iinds
			} else {
				set arr inds
			}
		}
		if !$wasMainSecMark {
			# set ${arr}($text) [lineStart -w $win [pos::math -w $win $start - 1]]
			set ${arr}($text) [lineStart -w $win $start]
		} else {
			set ${arr}($text) [lineStart -w $win [pos::math -w $win $start - 1]]
			set wasMainSecMark 0
		}
	}
    status::msg "File scanned, inserting marks..."
	
	getWinInfo -w $win warr
	set wasReadOnlyFile $warr(read-only)
	if $wasReadOnlyFile { 
		# allow for saving of the inserted marks
		setWinInfo -w $win read-only 0
	}
	
	set already ""
	set class "#"
	foreach arr {inds iinds} {
		if {[info exists $arr]} {
			if {$arr == "iinds"} {
				setNamedMark -w $win "-" 0 0 0
			}
			if !$sortAll {
				set order $asEncountered
			} else {
				set firstAlphaWithDictLSortV "8.0"
				if {[set M2::curAlphaV] >= $firstAlphaWithDictLSortV} {
					set order [lsort -dictionary [array names $arr]]
				} else {
					set order [lsort -ignore [array names $arr]]
				}
			}
			set firstEle 1
			foreach f $order {
				if {[set el [set ${arr}($f)]] != 0} {
					# set next [nextLineStart $el]
					set next [lineStart -w $win $el]
				} else {
					set next [minPos -w $win]
				} 
				
				if { [string first "000" $f] != -1 } {
					set ff "Class '[set class [lindex $f 0]]'"
				} elseif { [string first "${class}::" $f] != -1 } {
					set ff [string range $f [string length $class] end]
				} else {
					set ff $f
				}
				while { [lsearch -exact $already $ff] != -1 } {
					set ff "$ff "
				}
				lappend already $ff
				# Here is the assumption made that emphasis chars for main markers contain at least 1 bullet
				if {$hasMarkers && ![string match "¥*" $ff] } {
					if {$firstEle && [regexp {MODULE} $ff]} {
						set ff "$ff" 
					} else {
						set ff " $ff"
					}
				} 
				setNamedMark -w $win $ff $el $next $next
				set firstEle 0
			}
		}
	}
	
    if {[win::IsFile $win]} {
		# force dirty to make saving of just inserted marks possible
		# setWinInfo dirty 1
        global alpha::platform
        if {${alpha::platform} == "alpha"} { saveResources $win }
    }
	if $wasReadOnlyFile { 
		# restore previous setting
		setWinInfo -w $win read-only 1
	}
	status::msg "File marked"
	
	# Restore window positioning and selection
	# following seems not to work properly, bug in Alpha!?
	# display $saveTopLine
	goto -w $win $saveTopPos
	insertToTop -w $win
	goto -w $win $savePos
	selectText -w $win $savePos $saveSelEnd
}



## 
 # -------------------------------------------------------------------------
 # 
 # "M2::insertDivider" --
 # 
 #  Modified from Vince's original to allow you to just select part of
 #  an already written comment and turn it into a Divider. -trf
 #  Further modified by af to support replacement of already existing divider.
 # -------------------------------------------------------------------------
 ##
proc M2::insertDivider {} {
	global M2RightShift
	set enfoldThis ""
	if {[isSelection]} {
		set enfoldThis [getSelect]
		beginningOfLine
		killLine
		# check if preceeding line is just a comment, e.g. from old divider
		M2::KillPrevLnIfOnlyComment
		# check if next line is just a comment, e.g. from old divider
		M2::KillNextLnIfOnlyComment
		# current line should be empty, if really the case, delete it
		M2::KillLnIfEmpty
		# now prepare the text to be inserted
		set stars "";
		for {set i 0} {$i < [string length $enfoldThis]} {incr i} {
			set stars "$stars*"
		}
		# set whiteSpace [M2::getIndentation [getPos]]
		set whiteSpace "$M2RightShift"
		set frameLn "$whiteSpace\(*********$stars*********\)"
		set titleLn "$whiteSpace\(*#####   $enfoldThis   #####*\)"
		# now really insert it as a whole (1 Cmd^Z sufficient to revert)
		insertText "$frameLn\r$titleLn\r$frameLn\r"
		return
	} 
	elec::Insertion "(*#####   $enfoldThis   #####*)"
}


# Similar to M2::insertDivider, but inserts a subdivider (Ctrl^4)
proc M2::insertSubDivider {} {
	global M2RightShift M2modeVars
	if {[isSelection]} {
		set enfoldThis [getSelect]
		beginningOfLine
		killLine
		# check if preceeding line is just a comment, e.g. from old divider
		M2::KillPrevLnIfOnlyComment
		# check if next line is just a comment, e.g. from old divider
		M2::KillNextLnIfOnlyComment
		# current line should be empty, if really the case, delete it
		M2::KillLnIfEmpty
		# now prepare the text to be inserted
		set whiteSpace [M2::getIndentation [getPos]]
		if $M2modeVars(boxedSectionMarks) then {
			set minuses "";
			for {set i 0} {$i < [string length $enfoldThis]} {incr i} {
				set minuses "$minuses-"
			}
		    set frameLn "$whiteSpace\(*********$minuses*********\)"
		    set frameLn "$whiteSpace\(*--------$minuses--------*\)"
		}
		set titleLn "$whiteSpace\(*=====   $enfoldThis   =====*\)"
		if $M2modeVars(boxedSectionMarks) then {
			insertText "$frameLn\r$titleLn\r$frameLn\r"
		} else {
			insertText "$titleLn\r"
		}
		return
	} 
	elec::Insertion "(*=====   $enfoldThis   =====*)"
}


# offer M2::insertDivider also via M2 menu
proc M2::textToStructuralMark {} {
	M2::insertDivider
}

# offer M2::insertSubDivider also via M2 menu
proc M2::textToSectionMark {} {
	M2::insertSubDivider
}



proc M2::OptionTitlebar {} {
	# returns list of items for the menu
}
proc M2::OptionTitlebarSelect {cmd} {
	# carries out the mode-specific action when 'cmd' is selected.
}



# Reporting that end of this script has been reached
status::msg "m2Marking.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote "m2Marking.tcl for Programing in Modula-2 loaded"
}


