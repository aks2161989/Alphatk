# to autoload this file
proc m2GlobAux.tcl {} {}
	

#===========================================================================
# ×××× Global aux routines ×××× #
#===========================================================================

namespace eval M2 {}

#================================================================================
# The following may be useful to generate a make file, e.g. when called like
# this: M2::listDirContent "::RMS:Work:" {*.DEF *.MOD} ".PRJ" 0 "Def Mod;"
# or interactively: M2::listDirContent "" {*.DEF *.MOD} ".PRJ" 0 "Def Mod;"
# or simply: M2::listDirContent, which lists all files in a directory to be
# determined by a user open file dialog
#
# Examples:
# --------
# List non-recursivley only directories starting with letter "F"
#M2::listDirContent "" "F.*" ".LIST" "1" "" "-1"

# List recursively all directories
#M2::listDirContent "" ".*" ".LIST" "1" "" "-1" "1"

# List all files with extension .OUT in a window named "<folder name>.LIST"
# listDirContent "" ".*\\.OUT" ".LIST"

# List recursively all files here ending with ".PRJ"
#M2::listDirContent "" ".*\\.PRJ" ".LIST" "1" "" "0" "1"

# List recursively directories and files here ending with ".DEF" or ".MOD" 
# where extra trailing may follow ".MOD"-files, e.g. "HowDoYouDo.MOD (orig.)"
#M2::listDirContent "" ".*DEF .*MOD.*" ".LIST" "1" "" "0" "1"

# List only files (ignore directories) with name "ForClim.MOD"
#M2::listDirContent "" "ForClim.MOD" ".LIST" "1" "" "1" "0"


proc M2::getDirContent {dir {pat ".*"} {fullpath "0"} {dirFiles "0"} {recursive "0"}} {
# Usage dirFiles:  -1   only directories    0   directories and files    1   only files
    set dirName ${dir}${pat}
    set fileList ""
    set oldDir [pwd]
    cd "$dir"
    if {![catch {set dirContent [glob -nocomplain "*"]}]} then {
	foreach tmp $dirContent {
	    if {[file isdirectory ${tmp}]} then {
		    if {${dirFiles} != "1"} then {
			if {(${fullpath} == "") || (${fullpath} == "0")} then {
			    set tmp [file tail $tmp]
			}
			if { [regexp "(^.*)($pat)($)" ${tmp}] } then {
			    if {${tmp} != ""} then {
				lappend fileList ${tmp}
			    }
			}
		    }
		if {${recursive} == "1"} then {
		    append fileList " "
		    append fileList [M2::getDirContent "${tmp}[file join ""]" ${pat} ${fullpath} ${dirFiles}]
		} else {
		}
	    } else {
# 	        alertnote $tmp
		if {${dirFiles} != "-1"} then {
		    if {(${fullpath} == "") || (${fullpath} == "0")} then {
			set tmp [file tail $tmp]
		    }
		    if { [regexp "(^.*)($pat)($)" ${tmp}] } then {
			if {${tmp} != ""} then {
			    lappend fileList ${tmp}
			}
		    }
		}
	    }
	}
    }
#   message "fileList: '${fileList}'"
#   alertnote "cur dir: '[pwd]' , oldDir: '$oldDir'"
    cd $oldDir
    return $fileList
}

proc M2::fromWhichDir {prompt} {
    global M2ShellHome
    # default dir
    set dir [file join $M2ShellHome "Work"]
    if {[catch {set dir [getfile ${prompt} $dir]}]} then {
    }
    set dir "[file dirname $dir]"
    return $dir
}


proc M2::listDirContent {{dir ""} {pat ".*"} {ext ""} {fullpath "0"} {trailer ""} {dirFiles "0"} {recursive "0"}} {
    if {$dir == ""} then {
	if {${pat} != "*"} then {
	    set dir [M2::fromWhichDir "Choose from where to list $pat files"]
	} else {
	    set dir [M2::fromWhichDir "Choose from where to list files"]
	}
	if {$dir == ""} then {
	    # immediately quit routine since dialog cancelled
	    return 0
	}
    }
    set makeFileName "[file tail $dir]"
    if {$ext != ""} then {
	set makeFileName "${makeFileName}${ext}"
    }
    set dir "${dir}[file join ""]"
#   alertnote "dir = '$dir' pat = '$pat'"    
    set patList ""
    foreach patEle $pat {
	set nextFileList [M2::getDirContent $dir $patEle $fullpath $dirFiles $recursive]
	if {(${nextFileList} != "") && ([llength nextFileList] > "0")} then {
	    lappend patList $nextFileList
	}
    }
    if {(${patList} != "") && ([llength patList] != "0")} then { 
	new -n "${makeFileName}"
	foreach fileList $patList {
	    foreach f $fileList {
		if {${f} != ""} then {
		    if {${trailer} != ""} then {
			insertText -w "${makeFileName}" "${f} ${trailer}\n"
		    } else {
			insertText -w "${makeFileName}" "${f}\n"
		    }
		}
	    }
	}
    } else {
	alertnote "No files which match pattern '${dir}${pat}'!"
    }	
}


#================================================================================
# Translate a HFS MacOS Classic path into a Unix path
# This routine was programmed by FrŽdŽric Boulanger. Thanks FrŽdŽric :-)
proc mac2unix {name} {
  set absolute 0
  # A path is absolute if it does not begin with ":" but contains ":".
  # "foo" is relative (same as ":foo"), but "foo:bar" is 
  # absolute (foo is the volume name).
  if {[regexp {^[^:].*:.*} "$name"]} {
    set absolute 1
  }
  # An absolute unix path starts with "/"
  if {$absolute} {
    # On Mac OS X, volumes other than the boot volume are mounted 
    # in /Volumes
    if {($alpha::macos == 2)} {
      if {[regsub "^[file::startupDisk]:(.*)" $name {\1} name] > 0} {
        set unx "/"
      } else {
        set unx "/Volumes/"
      }
    } else {
      set unx "/"
    }
  } else {
    set unx ""
  }
  set l [string length $name]
  # Number of consecutive ":" characters.
  # "::" means ".." but
  # ":::" means "../.."
  set columns 0
  for {set i 0} {$i < $l} {incr i} {
    if {[string index $name $i] == ":"} {
      incr columns
      continue
    } elseif {$columns != 0} {
      # We reached a non-column char after readind a sequence of ":",
      # so we must translate this sequence of ":".
      if {$columns == 1} {
        if {$absolute} {
          append unx "/"
        } else {
          # Only one ':' in "not-absolute" mode => this is
          # the first ':' in the path, we translate it into "./".
          append unx "./"
          set absolute 1
          # Since we have now an explicit relative path in
          # the path we are building, we can build the rest 
          # as absolute.
        }
        set columns 0
      } else {
        if {$absolute} {
          append unx "/"
        } else {
          # The path is not absolute, so we don't put a "/".
          # For instance "::foo:bar" must translated into "../foo/bar"
          # without a "/" at the beginning.
          # After processing those ":", we will work in absolute mode
          # so that "::foo::bar" is translated into "../foo/../bar",
          # with a "/" before the ".." between foo and bar.
          set absolute 1
        }
        set columns [expr $columns - 1]
        # Each ":" but the first one makes us go up in the file hierarchy.
        while {$columns > 0} {
          set columns [expr $columns - 1]
          append unx "../"
        }
      }
    }
    # Don't forget to copy regular characters to the unix path...
    append unx [string index $name $i]
  }
  return $unx
}



# the menu command of the M2 menu
proc M2::makeProjectFile {} {
    M2::listDirContent "" ".*\\.DEF .*\\.def .*\\.MOD .*\\.mod" ".PRJ"
}


#================================================================================
# Editing files with conditional compilation flags

set M2::someFlagsPresent 0

proc M2::findLineWithStringAndReplace {matchStr newStr} {
	set forward 1
	set dir $forward
	if {![catch {set foundPos [search -s -r 1 -f $dir -i 0 -- "$matchStr" [getPos]]}]} then {
		set start [lindex $foundPos 0]
		set end [lindex $foundPos 1]
		selectText $start $end
		if {[pos::compare $start != $end]} then {
			replaceText $start $end "${newStr}"
			status::msg "Replaced '${matchStr}' with '${newStr}'"
		} else {
		    status::msg "Unexpected error: getPos $start == selEnd $end"
		}
		set nextln [nextLineStart $start]
		goto $nextln
		return 1
	} else {
		return 0
	}
}

proc M2::leftMargin {pos} {
	set curPos [getPos]
	set start [lineStart $pos]
	set end [pos::math [nextLineStart $start] -1]
	set text [getText $start $end ]
	regexp "(^\[ \t\]*)(.*)$" $text all theIndentation rest
	goto $curPos
	return $theIndentation
}


proc M2::findLineWithStrAndReplBegEnd {matchStr newStrBeg newStrEnd} {
	global M2::someFlagsPresent
	set forward 1
	set dir $forward
	if {![catch {set foundPos [search -s -r 1 -f $dir -i 0 -- "$matchStr" [getPos]]}]} then {
		set start [lindex $foundPos 0]
		set end [lindex $foundPos 1]
		selectText $start $end
		balance
		if {[isSelection]} then {
			set origComment [getText [getPos] [selEnd]]
			set start [lineStart $start]
			set end [pos::math [nextLineStart $start] -1]
			set whiteSpace [M2::leftMargin $start]
			goto $start
			selectText $start $end
			# alertnote "after selectText"
			if {[pos::compare $start != $end]} then {
				set M2::someFlagsPresent 1
				replaceText $start $end "${whiteSpace}${newStrBeg}${origComment}${newStrEnd}"
				status::msg "Replaced '${matchStr}' with '${newStrBeg}${origComment}${newStrEnd}'"
			} else {
				status::msg "Unexpected error: getPos $start == selEnd $end"
			}
			set nextln [nextLineStart $start]
			goto $nextln
			# alertnote "at end"
			return 1
		} else {
			selectText $start $end
			status::msg "Unexpected error: Balance of selection failed"
		}
	} else {
		return 0
	}
}

proc M2::replaceAllStrings {which with} {
	goto [minPos]
	set found 1
	while {$found == 1} {
		set found [M2::findLineWithStringAndReplace "${which}" "${with}"]
	}
}

proc M2::replaceAllVersFlags {which withBeg withEnd} {
	goto [minPos]
	set found 1
	while {$found == 1} {
		set found [M2::findLineWithStrAndReplBegEnd "${which}" "${withBeg}" "${withEnd}"]
	}
}

proc M2::autoEditCurWindow {flag} {
	# Activate compile version matching flag
	# NOTE: There has to be a blank after $flag or match is not unique!!
	M2::replaceAllVersFlags "ENDIF VERSION_${flag} " "" ""
	M2::replaceAllVersFlags "IF VERSION_${flag} " "" ""
}


proc M2::autoEditCompilerFlags {} {
	global m2_TargetPlatform
	global m2_MacCompFlagList
	global m2_IBMCompFlagList
	global m2_SunCompFlagList
	global m2_P1CompFlagList
	global M2::someFlagsPresent
    set curPosSaved [getPos]
	# Change case of all lower case keywords
	M2::replaceAllStrings "endif version_" "ENDIF VERSION_"
	M2::replaceAllStrings "if version_" "IF VERSION_"
	# Deactivate all
	M2::replaceAllVersFlags " ENDIF VERSION_" ".*) " ""
	M2::replaceAllVersFlags " IF VERSION_" "" " (*. "
    # Activate according to platform by using all appropriate flags
	if {"${m2_TargetPlatform}" == "Mac"} then {
		set flagList ""
		if {[info exists m2_MacCompFlagList] && (${m2_MacCompFlagList} != "")} then {
			set flagList ${m2_MacCompFlagList}
		} else {
			# The following default flags may need adjustment according to release machinery
			lappend flagList "DM"
			lappend flagList "MacMETH"
			lappend flagList "DM_MacMETH"
			lappend flagList "DM_MAC"
			lappend flagList "DM_MAC_OLD"
			lappend flagList "MW_MAC_OLD"
			lappend flagList "AuxLib_68KFPU"
		}
	} elseif {("${m2_TargetPlatform}" == "IBM") && ("${m2_IBMCompFlagList}" != "")} then {
		set flagList ""
		if {[info exists m2_IBMCompFlagList]} then {
			set flagList ${m2_IBMCompFlagList}
		} else {
			# The following default flags may need adjustment according to release machinery
			lappend flagList "DM"
			lappend flagList "STONYBROOK"
			lappend flagList "DM_IBM"
			lappend flagList "AuxLib"
		}
	} elseif {("${m2_TargetPlatform}" == "Sun") && ("${m2_SunCompFlagList}" != "")} then {
		set flagList ""
		if {[info exists m2_SunCompFlagList]} then {
			set flagList ${m2_SunCompFlagList}
		} else {
			# The following default flags may need adjustment according to release machinery
			lappend flagList "BDM"
			lappend flagList "EPC"
			lappend flagList "AuxLib"
		}
	} elseif {("${m2_TargetPlatform}" == "P1") && ("${m2_P1CompFlagList}" != "")} then {
		set flagList ""
		if {[info exists m2_P1CompFlagList]} then {
			set flagList ${m2_P1CompFlagList}
		} else {
			# The following default flags may need adjustment according to release machinery
			lappend flagList "BDM"
			lappend flagList "P1"
			lappend flagList "ISO"
			lappend flagList "AuxLib"
		}
	}
        # alertnote "'${flagList}'"
	foreach flag ${flagList} {
		M2::autoEditCurWindow "${flag}"
	}
	if {[set M2::someFlagsPresent]} {
		status::msg "Conditional compiler flags for '${m2_TargetPlatform}' activated!"
	} else {
		status::msg "No conditional compiler flags present in current window" 
	}
	goto $curPosSaved
}

#================================================================================
proc M2::firstWord {text} {
	regexp "\[ |\t\]*(\[A-Za-z0-9_\]*)(.*)" $text text firstWd rest
	return $firstWd
}
proc M2::restWord {text} {
	regexp "\[ |\t\]*(\[A-Za-z0-9_\]*)(.*)" $text text firstWd rest
	return $rest
}

#================================================================================
proc M2::currentDate {} {
    set date "[format "%-11s" "[lindex [mtime [now] short] 0]"]"
    set date "[lindex [mtime [now] short] 0]"
	regexp {([0-9]+).([0-9]+).([0-9]+)} $date dummy day month year
	if {[regexp {^[0-9]$} $day]} then {
		set day "0$day"
	}
	if {[regexp {^[0-9]$} $month]} then {
		set month "0$month"
	}
	if {[regexp {^[0-9]$} $year]} then {
		set year "200$year"
	} elseif {[regexp {^[0-8][0-9]$} $year]} then {
		set year "20$year"
	}
	set date "$day/$month/$year"
	return $date
}

#================================================================================
proc M2::currentYear {} {
    set date [M2::currentDate]
	regexp {([0-9]+).([0-9]+).([0-9]+)} $date dummy day month year
	if {[regexp {^9[0-9]$} $year]} then {
		set year "19$year"
	}
	return $year
}

#================================================================================
proc M2::trimString {text} {
	return [string trim $text]
}

#================================================================================
# The following proc thanks to Mark Nagata (mailto://nagata@kurims.kyoto-u.ac.jp)
proc M2::showFullName {} {
        status::msg [lindex [winNames -f] 0]
}




# Reporting that end of this script has been reached
status::msg "m2GlobAux.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote "m2GlobAux.tcl for Programing in Modula-2 loaded"
}
