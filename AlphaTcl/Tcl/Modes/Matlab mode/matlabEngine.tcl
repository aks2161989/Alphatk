################################################################################
#
# matlabEngine.tcl, part of the matlab mode package
# 
# Make editing MATLAB files more fun
# 
################################################################################

proc matlabEngine.tcl {} {}

################################################################################
#  Carriage return proc for edit, command, and history windows.
################################################################################

proc MATL::carriageReturn {} {
    if {[matlabIsShell]} {
	matlabDoShellLine
    } elseif {[matlabIsHist]} {
	matlabAddCommandHistory [matlabDoSelectionOrLine]
	bringToFront $MATLmodeVars(CmdHistWinName)
    } else {
	global indentOnReturn
	if {$indentOnReturn} {
	    set pos1 [lineStart [getPos]]
	    set pos2 [getPos]
	    set line [getText $pos1 $pos2]
	    if {[regexp "^\\s*(end|else|elseif|case|otherwise).*" $line]} {
		# End of block pattern
		createTMark temp $pos2
		catch {bind::IndentLine}
		gotoTMark temp ; removeTMark temp
	    }
	    insertText "\r"
	    catch {bind::IndentLine}
	} else {
	    insertText "\r"
	}
    }
}

################################################################################
#  Arrow key replacement
################################################################################

proc matlabUp {} {
    if {[matlabIsShell]} {
	matlabPrevCommand
    } elseif {[matlabIsHist]} {
	MATL::browseUp
    } else {
	previousLine
    }
}

proc matlabDown {} {
    if {[matlabIsShell]} {
	matlabNextCommand
    } elseif {[matlabIsHist]} {
	MATL::browseDown
    } else {
	nextLine
    }
}

proc MATL::browseUp {} {
    set limit [nextLineStart [nextLineStart [minPos]]]
    if {[pos::compare [getPos] > $limit]} {
	set limit [pos::math [getPos] - 1]
    }
    selectText [lineStart $limit] [nextLineStart $limit]
}

proc MATL::browseDown {} {
    set pos [getPos]
    if {[pos::compare $pos < [nextLineStart [minPos]]]} {
	set pos [nextLineStart [minPos]]
    }
    if {[pos::compare [nextLineStart $pos] < [maxPos]]} {
	selectText [nextLineStart $pos] [nextLineStart [nextLineStart $pos]]
    }
}

#################################################################################
#  cmd-double clicking, edit or get help on command
################################################################################

proc MATL::DblClick {from to shift option control} {    
    global MATLmodeVars
    
    set DblClickEdits [expr !$control == $MATLmodeVars(DblClickEdits)]
    
    # Force command names to lower case.
    # (Mac filenames are case-insensitive, anyway)
    set text [string tolower [getText $from $to]]
    
    if {! $DblClickEdits} {
	getMatlabHelp $text
    } else {
	MATL::editMfile $text
    }
}


################################################################################
#  Auto-indentation
#		1. Identify previous line ignoring comments
#		2.	Find leading whitespace for previous line
#		3.	Increase whitespace if previous line starts a block
#		4.	Decrease whitespace if current line ends a block
#     5. Eliminate whitespace if current line starts a procedure
################################################################################

proc MATL::indentLine {args} {
    
    win::parseArgs w
    
    # Comment Pattern
    set comPat {^[ \t]*%([^\r\n]*)}
    
    # Begining of block pattern
    set bobPat {^[ \t]*(if|else|elseif|for|switch|case|while|otherwise)[ \t\r\n;,%]}
    
    # End of block pattern
    set eobPat {^[ \t]*(end|else|elseif|case|otherwise)[ \t\r\n;,%]}
    
    # Begining and end of block pattern
    set baeobPat {^[ \t]*(if|else|elseif|for|case|otherwise)[^%]*[ \t]+(end)[ \t\r\n;,%]}
    
    # Function Line Pattern
    set funPat {^[ \t]*(function)[ \t]+([[]*[^][\n\r]+[]]*[ \t]*=[ \t]*)*([a-z0-9_]+)[ \t]*([(]+[^)(\n\r]+[)]+)*}
    
    # Get line to indent
    set beg [pos::lineStart -w $w [getPos -w $w]]
    set text [getText -w $w $beg [pos::nextLineStart -w $w $beg]]
    regexp -- {^[ \t]*} $text white
    set len [string length $white]
		
    # Init some vars
    set begCmt $beg
    set prvPos $beg
    set endCmt $beg
    set prvPos $beg
    
    # Find last previous non-comment line and get its leading whitespace
		
    while {[pos::compare -w $w $begCmt <= $prvPos] && [pos::compare -w $w $endCmt >= $prvPos]} {
	
	# Find the last non-blank line that precedes the comment block
	if {![catch {search -w $w -f 0 -r 1 -s -i 0 -m 0 {^[ \t]*[^ \t\r]} [pos::math -w $w $begCmt -1]} lst]} {
			
	    set prvPos [lindex $lst 0]
	    set line [getText -w $w [lindex $lst 0] [pos::nextLineStart -w $w [lindex $lst 0]]]
	    set lwhite [getText -w $w [lindex $lst 0] [pos::math -w $w [lindex $lst 1] - 1]]
			
	    # Find the next preceding comment block
	    if {![catch {search -w $w -f 0 -r 1 -s -i 0 -m 0 $comPat $prvPos} lstCmt]} {
		set begCmt [lindex $lstCmt 0]
		set endCmt [lindex $lstCmt 1]
	    } else {
		break
	    }
			
	} else {
	    # Handle search failure at top-of-file
	    if {[pos::compare -w $w $beg !=  [minPos -w $w]]} {
		set line [getText -w $w [minPos -w $w] [pos::nextLineStart -w $w [minPos -w $w]]]
	    } else {
		set line "%\r"
	    }
	    set lwhite ""
	    break
	}
    }
    
    # If the preceeding line begins a block increase the whitespace
    if {[regexp -nocase -- $bobPat $line]} {
	# but not if it also ended the block
	if {![regexp -nocase -- $baeobPat $line]} {
	    append lwhite "\t"
	}
    }

	# If the current line ends a block decrease the whitespace
    if {[regexp -nocase -- $eobPat $text]} {
	set lwhite [string range $lwhite 0 [expr [string length $lwhite] - 2]]
    }
    
    # If the current line starts a new function use no whitespace
    if {[regexp -nocase -- $funPat $text allofit subType subVars subName]} {
	set lwhite ""
    }

    # Put in the white space
    if {$white != $lwhite} {
	replaceText -w $w $beg [pos::math -w $w $beg + $len] $lwhite
    }
    goto -w $w [pos::math -w $w $beg + [string length $lwhite]]
}


################################################################################
#  Electric Semicolon
################################################################################

proc MATL::electricSemi {} {

    set pos [getPos]
    set start [lineStart $pos]
    set text [getText $start $pos]
	
    # Check if we are in a string or an array
    if {[string first {'} $text] != -1 || [string first {[} $text] != -1} {
	set quotes 0
	set lefts 0
	set rights 0
	set len [string length $text]
	for {set i 0} {$i < $len} {incr i} {
	    switch  -- [string index "$text" $i] {
		\[	{ incr lefts }
		\]	{ incr rights }
		\'	{ incr quotes }
	    }
	}
	if {[expr $quotes % 2]} {
	    insertText ";"
	    return
	} elseif	{$lefts != $rights} {
	    insertText ";"
	    return
	}
    }
	
    insertText ";"
    bind::CarriageReturn
}


################################################################################
#  Electric Semicolon Jump
#  Use with templates on last line of a block
################################################################################

proc MATL::electricSemiJump {} {
    insertText ";"
    ring::+
}

################################################################################
#  Set the named marks
################################################################################

proc MATL::MarkFile {args} {
    win::parseArgs win
    global MATLmodeVars
    set pos [minPos]
    
    set funPat {^[ \t]*(function)[ \t]+([[]*[^][\n\r]+[]]*[ \t]*=[ \t]*)*([a-z0-9_]+)[ \t]*([(]+[^)(\n\r]+[)]+)*}
    
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 $funPat $pos} res]} {
	set start [lindex $res 0]
	set end [pos::math -w $win [lindex $res 1] + 1]
	set text [getText -w $win $start $end]
	if {[regexp -nocase -- $funPat $text allofit subType subVars subName]} {
	    set locs($subName) [lineStart -w $win $start]
	}
	set pos $end
    }
    
    if {[info exists locs]} {
	foreach f [lsort -dictionary [array names locs]] {
	    setNamedMark -w $win $f $locs($f) $locs($f) $locs($f)
	}
    }
}

################################################################################
#  Edit an m-file if available, else get help if built-in
################################################################################

proc MATL::editMfile {fileName} {
	
	set varPat {is a (.+)}
	set pathPat {(.*):([^:]*)}
    
	set res [matlabWhichFile $fileName]
	if {$res == ""} {return}

	# If variable or built-in function, get help info.
	if {[regexp -- $varPat $res type]} {
		getMatlabHelp $fileName
		
	# If it's an m-file open it.
	} elseif {[regexp -- $pathPat $res dir fname]} {
		if {[catch {edit -c $res}]} {
			beep
			alertnote "Could not open m-file \"$res\""
		} else {
			icon -o
		}
		
	# If MATLAB doesn't recognize it, check if it's an
	# m-file in the same folder as the current script
	# If not, just display MATLAB's original response.
	} else {
		set path [file::absolutePath :${fileName}.m] 
		if [file exists $path] {
			if {[catch "edit -c \"$path\""]} {
				beep
				alertnote "Could not open m-file \"$res\""
			} else {
				icon -o
			}
		} else {
			# Now it could be a contents.m
			set resC [matlabWhichFile "$fileName:contents.m"]
			if {$resC == ""} {return}
			if {[catch {edit -c $resC}]} {
				beep
				alertnote "Could not open m-file \"$res\""
			} else {
				icon -o
			}
	   }
	}
}
