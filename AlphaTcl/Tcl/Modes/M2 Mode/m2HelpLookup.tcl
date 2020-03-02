# to autoload this file (tabsize:8)
proc m2HelpLookup.tcl {} {}

#================================================================================
# ×××× Providing Help (Help key, Cmd^DblClick, and Cntrl^Cmd^DblClick) ×××× #
#================================================================================

namespace eval M2 {}


proc M2::m2Help {} {
	global HOME
	set msg "M2 for programming in Modula-2. Use RAMSES or MacMETH,"
	set msg "$msg freeWare available at <http://www.ito.ethz.ch/SysEcol>"
	set msg "$msg mailto: RAMSES@env.ethz.ch"
	# alertnote $msg
	set helpFileName [file join $HOME Help "Modula-2 Help"]
	if {[file exists "$helpFileName"]} then {
		# edit -r -c "$helpFileName"
		package::helpWindow M2
		set width 530
		set height 820
		sizeWin $width $height
	} else {
		set msg "It seems mode M2 isn't correctly installed."
		set msg "$msg Couldn't find the help file Ç[file tail ${helpFileName}]È!"
		set msg "$msg It may help to download the mode from"
		set msg "$msg <http://www.ito.ethz.ch/SysEcol/SimSoftware/SimSoftware2.html>"
		set msg "$msg and to reinstall it."
		alertnote $msg
	}
}

proc M2::DblClick {{from -1} {to -1} {shift 0} {option 0} {control 0}} {
	status::msg "M2::DblClick was called (shift = $shift ; option = $option ; control = $control"
	selectText $from $to
	set text [getSelect]
	status::msg "Cmd^doubleclicked text = '$text'"
	if [catch {M2::DblClickHelper "$text" $control}] {
		set msg "No M2 docs found for '$text'"
		if {$control == 0} then {
			append msg ", try to Cntrl^Cmd^Doubleclick it!"
		}
		status::msg "$msg"
	}
	# Fix for Alpha8/X failure to activate M2 mode for RAMS files (bug #933)
	# http://www.maths.mq.edu.au/~steffen/Alpha/bugzilla/show_bug.cgi?id=933
	win::ChangeMode M2
}


proc M2::searchMarkInFile {searchText file wild procOrMod anyText locked} {
	if $procOrMod {
		set searchExprBeg {[ \t]*(PROCEDURE|MODULE)[ \t]+}
		set searchExprEnd {[ \t(;:]}
		set searchExpr "$searchExprBeg$searchText$searchExprEnd"
	} else {
		if !$anyText {
			# only procedures wanted
			set searchExprBeg {[ \t]*(PROCEDURE)[ \t]+}
			set searchExprEnd {[ \t(;]}
			set searchExpr "$searchExprBeg$searchText$searchExprEnd"
		} else {
			set searchExpr $searchText
		}	
	}
	if $wild {
		set lines [grepnames "$searchExpr" "$file"]
		if {[string length $lines]} {
			set file "[lindex $lines 0]"
			status::msg "Found first occurrence in file '$file'"
		} else {
			status::msg "Couldn't find '$searchText' in file set '$file'"
			return 0
		}
	}
	set lines [grep "$searchExpr" "$file"]
	# when expression failed try it once more with module name in "Section Structural Mark"
	# as expected in "... Quick Reference" files
	if {$procOrMod && ([string length $lines] == 0) && ([regexp {[ ]+(Q|q)uick[ ]+} ${file}])} then {
        # alertnote "2nd try"
		set searchExprBeg {\(\*=+[ \t]+}
		set searchExprEnd {[ \t(;/]}
		set searchExpr "$searchExprBeg$searchText$searchExprEnd"
		set lines [grep "$searchExpr" "$file"]
		if {![string length $lines]} then {
			# alertnote "3rd try, maybe second name in same structural mark, e.g. DMMathLib / DMMathLF"
			set searchExprBeg {[ \t/]*}
			set searchExprEnd {[ \t]+=+\*\)}
			set searchExpr "$searchExprBeg$searchText$searchExprEnd"
			set lines [grep "$searchExpr" "$file"]
		}
		#
		# set lines [grep "$searchText" "$file"]
		# 
		# the advantage of above would be that simple cmd^clicking opens the quick reference file
		# for almost anything. The disadvantage is that simple cmd^clicking onto an identifier which
		# is present in a file, but never leads to a named mark will trigger a call to
		# catch {mode::proc MarkFile}. E.g. cmd^clicking a type identifier results in this
		# situation. The behavior is annoying, in particular for long quick reference files
		# such as "AuxLib Quick Reference". Possible solution: Either mark CONST, TYPE, VAR identifiers
		# (would still cause problems in other cases, e.g. an identifier in a parameter list).
		# The actual implementation allows to find an identifier in a section structural mark, which
		# allows at least to find modules in quick reference files without the boring remarking in
		# other cases.
	}
	set curname [file tail ${file}]
	if {[string length $lines]} then {
		set mark "$searchText"
		if [catch {editMark "$file" $mark}] {
			# file curname may contain wanted searchText, but marks don't match exactly
			# e.g. named file mark "- SimBase" does not exactly match "SimBase"
            if {([file exists "$file"])} then {
				win::OpenQuietly "$file"
			} else {
				return 0 
			}
			set marks "[getNamedMarks -n -w ${curname}]"
			set ind [lsearch -regexp $marks $searchText]
			set matched 0
			if {($ind != -1)} {
				set mark [lindex $marks $ind]
				if {([string trim $mark] == "$searchText")} then {
					set matched 1
				} else {
					# ignore in mark any nonIdentifier chars (leading and trailing)
					if {[regexp {[^A-Za-z0-9]} $mark]} then {
						set searchIdExpr "(\[^A-Za-z\])($searchText)"
						set matched [regexp "$searchIdExpr" $mark]
					}
				}
			}
		}	
		if [catch {editMark "$file" $mark}] {
			status::msg "'$mark' is not a named mark in '$curname'"
			return 0
		} else {
			# editMark sometimes succeeds despite there is no such mark
			set ind [lsearch -regexp [getNamedMarks -n -w ${curname}] $mark]
			if {($ind == -1)} then { 
				status::msg "'$mark' is not a named mark in '$curname'"
				return 0 
			} else {
				status::msg "Found mark '$mark' in file '$curname'"
				if $locked {
					setWinInfo read-only 1
				}
				if {![catch {search -s -r 1 -f 1  -i 0 -n -- ${searchExpr} [getPos]} foundPos]} then {
					goto [lindex $foundPos 0]
					previousLine
					centerRedraw
					if {[catch {search -s -r 1 -f 1 -m 1 -i 0 -n -- ${searchText} [lindex $foundPos 0]} foundPos]} then {}
					# check wether window is really locked
					getWinInfo warr
					if $warr(read-only) { 
						selectText [lindex $foundPos 0] [lindex $foundPos 1]
					} else {
						selectText [lindex $foundPos 0] [lindex $foundPos 0]
					}
				# if ![catch {set foundPos [search -s -r 0 -f 1  -i 0 -n -- $searchText [getPos]]}] {
					# selectText $foundPos
				# }
				}
			}
			return 1
		}	
	} else {
		return 0
	}
}



proc M2::DblClickHelper {text control} {
	global HOME
	global M2ShellHome
	global M2modeVars
	global M2::posBeforeJumpOutOfLn
	global M2::selEndBeforeJumpOutOfLn

	# Remember M2::posBeforeJumpOutOfLn and M2::selEndBeforeJumpOutOfLn
	set M2::posBeforeJumpOutOfLn [getPos]
	if { [isSelection] } { set M2::selEndBeforeJumpOutOfLn [selEnd]}
	
	# currently auto-marking only supported for procedures and modules, thus most searches with this option
	set procOrMod 1
	set onlyProc 0
	set notAnyText 0
	set anyText 1
	
	# Is it some mark in sibling module in case it is a library module?
	set notlocked 0
	set notwild 0
	set currentWindow [win::Current]
	if {$control != 0} then {
		set otherLibModPFN [M2::otherLibModule]
		set path [lindex $otherLibModPFN 0]
		set tgtName [lindex $otherLibModPFN 1]
		set pathAlt [lindex $otherLibModPFN 2]
		if [M2::searchMarkInFile $text "$path$tgtName" $notwild $procOrMod $notAnyText $notlocked] then {
			# return to previous window
			M2::openOtherLibModule
			status::msg "Found '$text' in '$tgtName'"
			# return is done by subsequent code <<Is it some mark in current file?...>>
		} elseif {($pathAlt != "") && ([M2::searchMarkInFile $text "$pathAlt$tgtName" $notwild $procOrMod $notAnyText $notlocked])} then {
			# return to previous window
			M2::openOtherLibModule
			status::msg "Found '$text' in '$tgtName' in dir '$pathAlt'"
			# return is done by subsequent code <<Is it some mark in current file?...>>
		} else {
			status::msg "Couldn't find '$text' in '$tgtName'"
		}
	}

	# Is it some mark in current file?  (search only for procedures declared in current file)
	if [M2::searchMarkInFile $text "$currentWindow" $notwild $onlyProc $notAnyText $notlocked] then {return}
    
	
	# Is it in some definition module residing in current folder?
	if {$control != 0} then {
		set locked 0
		set filePFN "${path}*.DEF"
		status::msg "Searching in file set '$filePFN'"
		set wild 1
		if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	}
	
	# The following searches assume you are working with an ordinary RAMSES release
	# where most definition modules sit within folder "$M2ShellHome:Docu:"
	set locked 1
	if {![file isdirectory $M2modeVars(docuFolder)]} then {
		set docuPath "$M2ShellHome:$M2modeVars(docuFolder)"
	} else {
		set docuPath "$M2modeVars(docuFolder)"
	}
	
	# Is it in a Dialog Machine module?
	if {$control == 0} then {
		set filePFN [file join $docuPath DM "DM Quick Reference"]
		set wild 0
	} else {
		set filePFN [file join "$docuPath" DM "DMKernel .DEF" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	# Is it in optional DM modules if control pressed?
	if {$control != 0} then {
		set filePFN [file join "$docuPath" DM "DMOptLib .DEF" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	
	
	# Is it in a ModelWorks module?
	if {$control == 0} then {
		set filePFN [file join $docuPath MW "MW Quick Reference"]
		set wild 0
	} else {
		set filePFN [file join "$docuPath" MW "ModelWorks.DEF" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	
	
	# Is it in an ISIS module?
	if {$control == 0} then {
		set filePFN [file join $docuPath ISIS "ISIS Quick Reference"]
		set wild 0
	} else {
		set filePFN [file join "$docuPath" ISIS "ISIS.DEF" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	
	
	# Is it in an AuxLib module?
	if {$control == 0} then {
		set filePFN [file join $docuPath AuxLib "AuxLib Quick Reference"]
		set wild 0
	} else {
		set filePFN [file join "$docuPath" AuxLib "AuxLib .DEF" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}

	# Is it in an optional Extra AuxLib module?
	if {$control == 0} then {
		set filePFN [file join $docuPath AuxLib "AuxLibExtra Quick Reference"]
		set wild 0
	} else {
		set filePFN [file join "$docuPath" AuxLib "AuxLibExtra .DEF" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	
	# Is it in a ScienceLib module?
	if {$control == 0} then {
		set filePFN [file join $docuPath ScienceLib "ScienceLib Quick Reference"]
		set wild 0
	} else {
		set filePFN [file join "$docuPath" ScienceLib "ScienceLib.DEF" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	
	
	# Is it in a MacMETH module?
	if {$control == 0} then {
		set filePFN [file join $docuPath M2 "MacMETH Quick Reference"]
		set wild 0
	} else {
		set filePFN [file join "$docuPath" M2 "MacMETH Docu" "*.DEF"]
		status::msg "Searching in file set '$filePFN'"
		set wild 1
	}
	if [M2::searchMarkInFile $text "$filePFN" $wild $procOrMod $notAnyText $locked] then {return}
	
	
	# Topic in "Modula-2 Help"?
	set procOrMod 0
	if [M2::searchMarkInFile $text [file join $HOME Help "Modula-2 Help"] $notwild $procOrMod $anyText $locked] then {return}

	# Is it a mark in one of the currently opened file(s)? Skip this if Control^Command^Click
	if {$control == 0} then {
		set winFileList [winNames -f]
		foreach winFile ${winFileList} {
			set window [file tail "$winFile"]
			set marks "[getNamedMarks -n -w ${window}]"
			set ind [lsearch -regexp $marks $text]
			if {($ind != -1)} {
				bringToFront "${window}"
				set mark [lindex $marks $ind]
				if {([string trim $mark] == "$text")} then {
					set matched 1
				} else {
					# trim mark text from any nonIdentifier chars (leading and trailing)
					if {[regexp {[^A-Za-z0-9]} $mark]} then {
						set searchIdExpr "(\[^A-Za-z\])($text)"
						set matched [regexp "$searchIdExpr" $mark]
					} else {
						set matched 0
					}
				}
				if $matched then {
					gotoMark $mark
					status::msg "Found mark '$text' in currently open file '${window}'"
					set foundPos [getPos]
					# avoid that only line of mark is only top 
					previousLine
					previousLine
					set wild 0
					if {![catch {search -s -r 1 -f 1 -m 1 -i 0 -n -- ${text} [getPos]} foundPos]} then {
						# check wether window is locked and select mark text only if file is read only
						getWinInfo warr
						if $warr(read-only) { 
							selectText [lindex $foundPos 0] [lindex $foundPos 1]
						} else {
							selectText [lindex $foundPos 0] [lindex $foundPos 0]
						}
					}
					return
				}
			}			
		}			
	}
	
	
	# last attempt
	if {[string length [set f [procs::find $text]]]} {
		editMark $f $text
		return
	}
	
	# raise error for proper message display
	error ""
}


# Reporting that end of this script has been reached
status::msg "m2HelpLookup.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote "m2HelpLookup.tcl for Programing in Modula-2 loaded"
}

