## -*-Tcl-*-
 # ==========================================================================
 #  Perl mode - an extension package for Alpha
 # 
 #  FILE: "perlFilters&Misc.tcl"
 #                                    created: 08/17/1994 {09:12:06 am} 
 #                                last update: 02/25/2006 {03:32:55 AM}
 #  Description: 
 #  
 #  See the "perlVersionHistory.tcl" file for license info, credits, etc.
 #  
 # ==========================================================================
 ## 

# load main Perl file!
perlMenu

proc perlFilters&Misc.tcl {} {}

namespace eval Perl {}

# ×××× Handle Perl Files ×××× #

# Open a 'require'd Perl file.

proc Perl::findRequire {from {to ""}} {
    
    set reqPat {^[\t ]*require[\t ]*(\"[^\"]+\"|\'[^\']+\'|[^\t ]+)}
    if {[string length $to]} {set to $from}
    set beg [lineStart $from]
    set end [nextLineStart $to]
    regsub -all "\{|\}" [getText $beg $end] { } text
    set words [parseWords $text]
    if {[string tolower [lindex $words 0]] != "require"} {
	return ""
    } else {
	return [string trim [lindex $words 1] {'"}]
    }
}

# Open a Perl source file. 

proc Perl::openPerlFile {file {extensions {""}}} {
    
    global PerlmodeVars Perl::SearchPaths
    
    # Determine absolute file specification
    # Ignore $extensions if $file already has an extension
    if {[string length [file extension $file]] == 0} {
	set extensions {""}
    }
    foreach ext $extensions {
	set filename [file::absolutePath $file$ext]
	if {![catch {file::openQuietly $filename}]} {
	    status::msg $filename
	    return 1
	}
    }
    if {![info exists Perl::SearchPaths] || ![llength [set Perl::SearchPaths]]} {
	Perl::buildSearchPath
    }
    foreach folder [set Perl::SearchPaths] {
	foreach ext $extensions {
	    set filename [file join $folder $file$ext]
	    if {![catch {file::openQuietly $filename}]} {
		status::msg $filename
		return 1
	    }
	}
    }
    beep
    status::msg "Can't find Perl source file '$file'"
    return      "Can't find Perl source file '$file'"
}

# ===========================================================================
# 
# ×××× Text Filters ×××× #
# 

# ===========================================================================
# 
# Reuse the previous (buffer or file) filter:
#

proc Perl::repeatLastFilter {} {
    
    global PerlmodeVars Perl::ScriptFile Perl::ScriptStart Perl::PrevScript
    
    set script [set Perl::PrevScript]
    if {![string length $script] || $script == "*startup*"} {
	# This should have been dimmed...
	status::msg "There is no last filter to use."
	Perl::postEval
    } else {
	set stype [lindex $script 0]
	set name  [lindex $script 1]
	if {$stype == "file"} {
	    Perl::fileAsFilter $name
	} elseif {$stype == "buffer"} {
	    Perl::bufferAsFilter $name
	} else {
	    status::msg "Bogus filter name : '$script\'"
	    Perl::setPrevScript ""
	}
    }
}

# ===========================================================================
# 
# Ask for a file containing a Perl script to use as a filter:
#

proc Perl::selectFileAsFilter {} {
    
    global PerlmodeVars Perl::ScriptFile Perl::ScriptStart 
    
    if {![catch {getfile "Select a MacPerl script"} path]} {
	Perl::fileAsFilter $path
    }
}

# ===========================================================================
# 
# Ask for an Alpha buffer containing a Perl script to use as a filter:
#

proc Perl::selectBufferAsFilter {} {
    
    global PerlmodeVars Perl::ScriptFile Perl::ScriptStart 
    
    set windows [winNames]
    set current [lindex $windows 0]
    if {[llength $windows] > 1} {
	set name [listpick [lsort $windows]]
	if {[string length $name]} {
	    # get the full name of the chosen window
	    set wname [lindex [winNames -f] [lsearch -exact $windows $name]]
	    Perl::bufferAsFilter $wname
	}
    }
}

# ===========================================================================
# 
# Prepare the contents of a text window for use as a text-filter script. 
# (calls Perl::textFilter to actually run the script)
# 

proc Perl::bufferAsFilter {wname} {
    
    Perl::lauchBackPerl

    global PerlmodeVars Perl::ScriptFile Perl::ScriptStart  perlMenu Perl::PerlName
    
    set ok [regexp {(.*):([^:]*)} $wname pathname dirname name]
    if {!$ok} {	set name $wname	}
    
    if {[lsearch [winNames -f] $wname] >= 0} {
	set coreScript [getText -w $wname [minPos] [maxPos -w $wname]]
	# Does it have any text in it?
	if {[string length $coreScript]} {
	    set Perl::ScriptFile $wname
	    set Perl::ScriptStart 1
	    set script [Perl::wrapFilterScript $coreScript]
	    Perl::setPrevScript [list "buffer" $wname]
	    status::msg "Running buffer \"$name\" as text filter ..."
	    Perl::textFilter $script
	}
    } else {
	Perl::setPrevScript ""
	alertnote "Couldn't find buffer : $name"
    }
}

# ===========================================================================
# 
# Take a Perl script and add commands to take the file STDIN as standard
# input and STDOUT as standard output.  This allows scripts written as
# Unix command-line filters to be used in the (non-MPW) Mac environment
# as text filters.
#
# If there's already a #!  line in the script, then the new commands are
# added after that line.  If there was no #!  line in the first place,
# one is added, in case MacPerl is set up to require it (can't hurt...)
#
# 'Perl::FilterHeadLen' counts the number of lines we add to the top of the
# original script, so that we can allow for it in interpreting error
# messages issued by MacPerl.
#
# *** As of MacPerl 4.1.4, this business is pretty much obsolete ***
#

proc Perl::wrapFilterScript {coreScript} {
    
    global PerlmodeVars Perl::ScriptStart Perl::FilterHeadLen 
    
    set interpPat {(#![	 !-~]*)}
    
    if {[regexp -indices -- $interpPat $coreScript allofit cmdln]} {
	set endPos [lindex $cmdln 1]
	set filterHead [string range $coreScript 0 [expr $endPos+1]]
	set coreScript [string range $coreScript [expr $endPos+2] end]
	set Perl::FilterHeadLen 0
	incr Perl::ScriptStart [expr [llength [split $filterHead "\n\r"]] -2]
    } else {
	set filterHead "#!/bin/perl\r\n"
	set Perl::FilterHeadLen 2
    }
    
    set script ${filterHead}${coreScript}
    
    # for debugging purposes, save the script on disk
    Perl::writeScript $script
    return $script
}		

# ===========================================================================
# 
# Paste result of the filter operation in place of the input text, or in
# a new window (depending on the flag $PerlmodeVars(overwriteSelection)
#

proc Perl::pasteFilterResult {text} {
    global PerlmodeVars
    set perlOutputWindow {* Perl Output *}
    
    if {!$PerlmodeVars(overwriteSelection)} {
	if {$PerlmodeVars(recycleOutput) && 
	[lsearch [winNames] $perlOutputWindow] >= 0} {			    
	    bringToFront $perlOutputWindow
	} else {
	    new -n $perlOutputWindow
	}
    }
    
    if {$PerlmodeVars(applyToBuffer) || $PerlmodeVars(recycleOutput)} {
	set from [minPos]
	set to   [maxPos]
    } else {
	set from [getPos] 
	set to   [selEnd]
    }    
    replaceText $from $to $text
    
    if {!$PerlmodeVars(overwriteSelection) || $PerlmodeVars(applyToBuffer)} {
	catch {shrinkWindow 2}
	goto [minPos]
    } else {
	catch shrinkWindow
	goto $from
    }
    if {!$PerlmodeVars(overwriteSelection)} {setWinInfo dirty 0}
}    

# ===========================================================================
# 
# Prepare the contents of a disk file for use as a text-filter script. 
# (calls Perl::textFilter to actually run the script)
# 

proc Perl::fileAsFilter {path} {
    
    Perl::lauchBackPerl

    global PerlmodeVars Perl::ScriptFile Perl::ScriptStart
    
    if {![catch {file::readAll $path} coreScript]} {
	set Perl::ScriptFile $path
	set Perl::ScriptStart 1
	set script [Perl::wrapFilterScript $coreScript]
	Perl::setLastFilter [list "file" $path]
	status::msg "Running file '[file tail $path]' as a script ..."
	Perl::textFilter $script
    } else {
	Perl::setLastFilter ""
    }
}

# ===========================================================================
# 
# Run a Perl script as a command-line text filter, arranging for a text
# buffer to be attached as standard input.  The calling routine should
# already have processed the script with Perl::wrapFilterScript.  This
# routine actually sends the script and takes care of writing the input
# and reading the output files.
# 

proc Perl::textFilter {script {arguments {}} {flags {}}} {
    global PerlmodeVars Perl::FilterHeadLen Perl::ScriptFile Perl::ScriptStart 
    global ALPHA Perl::PerlName
    
    Perl::lauchBackPerl
    if {![string length [set Perl::PerlName]]} {
	alertnote "Couldn't run MacPerl"
	error "Couldn't run MacPerl"
    }
    Perl::writeStdIn
    
    if {$PerlmodeVars(useDebugger)} {
	append flags "debug"
    }
    if {$PerlmodeVars(promptForArgs)} { 
	append arguments " [Perl::getCmdlineArgs]"
    }
    
    sendCloseWinName [set Perl::PerlName] [set Perl::PerlName]
    sendCloseWinName [set Perl::PerlName] "Perl Debug"
    
    if {$PerlmodeVars(useDebugger)} {
	switchTo [set Perl::PerlName]
	Perl::doScript [set Perl::PerlName] [Perl::scriptPath] $arguments [list [Perl::stdInPath]] $flags
	set err [Perl::getMacPerlError]
	
    } else {
	watchCursor
	set reply [Perl::doScriptBatch [set Perl::PerlName] [Perl::scriptPath] $arguments [list [Perl::stdInPath]]]
	set err [Perl::getBatchError $reply]
    }
    
    switchTo $ALPHA
    
    if {$err == 0} {
	if {$PerlmodeVars(useDebugger)} {
	    set outp [sendGetText [set Perl::PerlName] [set Perl::PerlName]]
	} else {
#	    set outp [Perl::parseReplyOutp $reply]
	    set outp [Perl::parseReplyResult $reply]
	}
	Perl::pasteFilterResult $outp
    }
}


# ===========================================================================
# 
# ×××× Support procs ×××× #
# 

# ===========================================================================
# 
# Open a file from the MacPerl application folder - used by "Open Special"
#

proc Perl::openFile {menu name} {
    
    set filename [Perl::perlFolder]$name
    if {[file exists $filename]} {
	edit -c $filename
    } else {
	alertnote "That file doesn't exist yet"
    }
}

# Paths to Standard Files
# 
# Return paths to standard files, based on the path to Perl Sig:

proc Perl::stdInPath  {} {return [file join [Perl::perlFolder] STDIN]}
proc Perl::scriptPath {} {return [file join [Perl::perlFolder] SCRIPT]}


# ===========================================================================
# 
# Prompt the user to enter a string containing command-line args.
#

proc Perl::getCmdlineArgs {} {
    
    global PerlmodeVars perlCmdlineArgs
    
    if {![catch {prompt "Command-line arguments (if any):" $PerlmodeVars(perlCmdlineArgs)} args]} {
	set PerlmodeVars(perlCmdlineArgs) $args
	prefs::modified PerlmodeVars(perlCmdlineArgs)
    } else {
	error "Perl::getCmdlineArgs: User cancelled"
    }
    return $args
}

# ===========================================================================
# 
# Add a #!/bin/perl line to the script if it doesn't contain one already.
# (MacPerl puts up dialog if this line is missing when it expects it,
# hanging the DoScript and leaving us stuck.)
#

proc Perl::wrapSelectScript {coreScript} {
    
    global PerlmodeVars Perl::ScriptStart Perl::FilterHeadLen
    
    set interpPat {(#![	 !-~]*)}
    
    if {[regexp -indices $interpPat $coreScript allofit cmdln]} {
	set endPos [lindex $cmdln 1]
	set filterHead [string range $coreScript 0 [expr $endPos+1]]
	set script $coreScript
	set Perl::FilterHeadLen 0
	incr Perl::ScriptStart [expr [llength [split $filterHead "\n\r"]] -2]
    } else {
	set script "#!/bin/perl\r\n"
	append script $coreScript
	set Perl::FilterHeadLen 1
    }
    
    # for debugging purposes, save the script on disk
    Perl::writeScript $script
    return $script
}		

# ===========================================================================
# 
# If 'applyToBuffer' is set, select the entire buffer.  Otherwise, expand
# the selection to encompass complete lines.  Select the current line
# containing the insertion point if there is no selection.  A special
# hack is required for line select mode (mouse drag over lines to the
# left of col 1) because posToRowCol places \r in col 0 of the next row.
# RBC 02-MAR-1999
#

proc Perl::completeSelection {} {
    
    global PerlmodeVars filterInput
    
    set filterInput "buffer \"[lindex [winNames] 0]\""
    if {$PerlmodeVars(applyToBuffer)} {
	set start [minPos]
	set end [maxPos]
    } else {
	beginningLineSelect  ; # extend selection backwards
	if {[lindex [pos::toRowChar [selEnd]] 1] != 0} {
	    endLineSelect
	    forwardCharSelect
	}
	# if we are in col 0, we've already selected a whole line.
	# Otherwise, extend the selection to the end of current line.
	# forwardCharSelect grabs the \r.
	set start [getPos]
	set end   [selEnd]
	set startLine [lindex [pos::toRowChar $start] 0]
	set endLine   [lindex [pos::toRowChar $end] 0]
	if {$endLine > $startLine} {
	    set filterInput "lines $startLine to $endLine of $filterInput"
	} else {
	    set filterInput "line $startLine of $filterInput"
	}
    }
    return [list $start $end]
}

# ===========================================================================
# 
# Perl::writeStdIn: Extend the selection, as appropriate, and write it to
#   the STDIN file in the MacPerl directory.
#
# Perl::writeScript: Write the SCRIPT file in the MacPerl directory.
#   MacPerl will read the script from this file.
#
# -nonewline added to 'puts' so an extra \r isn't appended. (RBC 02-MAR-1999)

proc Perl::writeStdIn {} {
    
    set result [Perl::completeSelection]
    set tmpfid [open [Perl::stdInPath] "w+"]
    puts -nonewline $tmpfid [eval getText $result]
    close $tmpfid
}

# This is unnecessary now, but maybe it'll still useful to save the
# script file for debugging.

proc Perl::writeScript {script} {
    
    set tmpfid [open [Perl::scriptPath] "w+"]
    puts $tmpfid $script 
    close $tmpfid
}

# ===========================================================================
# 
# .
