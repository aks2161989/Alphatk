## -*-Tcl-*-
 # ==========================================================================
 #  Perl mode - an extension package for Alpha
 # 
 #  FILE: "perlEngine.tcl"
 #                                    created: 08/17/1994 {09:12:06 am} 
 #                                last update: 12/10/2003 {11:43:09 AM}
 #  Description: 
 #  
 #  Support for interaction between Alpha and a local Perl application.
 #  
 #  See the "perlVersionHistory.tcl" file for license info, credits, etc.
 #  
 # ==========================================================================
 ## 

# load main Perl file!
perlMenu

proc perlEngine.tcl {} {}

namespace eval Perl {}

# ===========================================================================
# 
# Run a MacPerl script from the Tcl shell
#
# This proc pretends it is the invocation of the perl app when used as
# the first word of a command in the Tcl shell.  -trf
# 

proc perl {{path ""} args} {
    
    global PerlmodeVars ALPHA Perl::ScriptFile Perl::ScriptStart 
    global Perl::FilterHeadLen Perl::PerlName

    set flags {}
    
    if {[string length $path]} {
	Perl::lauchBackPerl
	if {[string length [set Perl::PerlName]]} {
	    
	    set filename [file tail $path]
	    if {$path != [Perl::scriptPath]} {set Perl::FilterHeadLen 0}
	    
	    sendCloseWinName [set Perl::PerlName] [set Perl::PerlName]
	    sendCloseWinName [set Perl::PerlName] "Perl Debug"
	    if {$PerlmodeVars(autoSwitch) || $PerlmodeVars(useDebugger)} {
		switchTo [set Perl::PerlName]
	    } else {
		status::msg "Running file \"$filename\" as Perl script"
		watchCursor
	    }
	    Perl::doScript [set Perl::PerlName] $path $args {} $flags
	    switchTo $ALPHA
	    if {![Perl::getMacPerlError]} {
		if {$PerlmodeVars(retrieveOutput)} {Perl::openOutput}
	    }
	} else {
	    alertnote "Couldn't run MacPerl"
	}
    } else {
	return {Usage:  perl <filename> [ <args> ]}
    }
}

# ===========================================================================
# 
# ×××× Running Scripts ×××× #
# 

# Launch Perl into the foreground, get the name.

proc Perl::lauchBackPerl {} {
    
    Perl::perlFolder
    
    global PerlmodeVars Perl::PerlName
    set Perl::PerlName [file tail [app::launchBack $PerlmodeVars(perlSig)]]
}

# Tell MacPerl to run a script file:

proc Perl::executeFile {path {arguments {}} {flags {}}} {
    
    global PerlmodeVars ALPHA Perl::ScriptFile Perl::ScriptStart 
    global Perl::FilterHeadLen Perl::PerlName
    
    if {[string length $path]} {
	Perl::lauchBackPerl
	if {[string length [set Perl::PerlName]]} {
	    
	    set ok [regexp {(.*):([^:]*)} $path pathname dirname filename]
	    if {!$ok} {set name $wname}
	    
	    if {$path != [Perl::scriptPath]}  {set Perl::FilterHeadLen 0}
	    if {$PerlmodeVars(useDebugger)}   {append flags "debug"}
	    if {$PerlmodeVars(promptForArgs)} {append arguments " [Perl::getCmdlineArgs]"}
	    
	    sendCloseWinName [set Perl::PerlName] [set Perl::PerlName]
	    sendCloseWinName [set Perl::PerlName] "Perl Debug"
	    if {$PerlmodeVars(autoSwitch) || $PerlmodeVars(useDebugger)} {
		switchTo [set Perl::PerlName]
	    } else {
		status::msg "Running file \"$filename\" as Perl script"
		watchCursor
	    }
	    
	    Perl::doScript [set Perl::PerlName] $path $arguments {} $flags
	    
	    # (not sure which choice is better...)
#	    if {!$PerlmodeVars(autoSwitch)} {switchTo $ALPHA}
	    switchTo $ALPHA

	    if {![Perl::getMacPerlError]} {
		if {$PerlmodeVars(retrieveOutput)} {Perl::openOutput}
	    }
	} else {
	    alertnote "Couldn't run MacPerl"
	}
    } else {
	alertnote "No file specified to execute"
    }
}

# ===========================================================================
# 
# Run a MacPerl script, passed explicitly as a string:
#
# If no "#!/bin/perl" line already exists, one is preprended to the
# script by Perl::wrapSelectScript, which also sets Perl::FilterHeadLen
# for use by Perl::getMacPerlError.
# 

proc Perl::executeScript {script {arguments ""} {flags {}} } {
    
    global PerlmodeVars Perl::PerlName
    global Perl::ScriptFile Perl::ScriptStart Perl::FilterHeadLen  ALPHA
    
    if {$script != ""} {
	set script [Perl::wrapSelectScript $script]
	
	if {![regexp {(.*):([^:]*)} [set Perl::ScriptFile] pathname dirname filename]} {
	    set filename [set Perl::ScriptFile] 
	}
	
	Perl::lauchBackPerl
	if {[string length [set Perl::PerlName]]} {
	    
	    if {$PerlmodeVars(useDebugger)}   {append flags "debug"}
	    if {$PerlmodeVars(promptForArgs)} {append arguments " [Perl::getCmdlineArgs]"}
	    
	    sendCloseWinName [set Perl::PerlName] [set Perl::PerlName]
	    sendCloseWinName [set Perl::PerlName] "Perl Debug"
	    if {$PerlmodeVars(autoSwitch) || $PerlmodeVars(useDebugger)} {
		switchTo [set Perl::PerlName]
	    } else {
		status::msg "Running buffer \"$filename\" as Perl script"
		watchCursor
	    }
	    
	    Perl::doScript [set Perl::PerlName] $script $arguments {} $flags
	    
	    switchTo $ALPHA
	    
	    if {![Perl::getMacPerlError]} {
		if {$PerlmodeVars(retrieveOutput)} {Perl::openOutput}
	    }
	}
    } else {
	alertnote "Can't run an empty script"
    }
}

# ===========================================================================
# 
# ×××× Check MacPerl error msg ×××× #
# 
# Check the MacPerl output window for error messages.
#

proc Perl::getMacPerlError {} {
    
    set diag [Perl::getPerlDiag 40]
    set errf [Perl::parseDiagErrf $diag]
    set srcs [Perl::parseDiagSrcs $diag]
    set mesg [Perl::parseDiagMesg $diag]
    
    if {[string length $errf]} {
	Perl::showPerlDiag $diag [string length $diag] $mesg $errf $srcs
	Perl::gotoPerlError $errf $srcs $mesg
	return 1
    } else {
	return 0
    }
}

# ===========================================================================
# 
# Check the MacPerl batch reply for error messages.
#

proc Perl::getBatchError {reply} {
    
    global PerlmodeVars
    
    set perlErrorWindow {* Perl Error Messages *}
    
    set fatalError 0
    set diag [Perl::parseReplyDiag $reply]
    set errf [Perl::parseDiagErrf  $diag ]
    set srcs [Perl::parseReplySrcs $reply]
    set mesg [Perl::parseDiagMesg  $diag ]
    set errn [Perl::parseReplyErrn $reply]
    
    if {$errn} {		
	Perl::showPerlDiag $diag $errn $mesg $errf $srcs
	Perl::gotoPerlError $errf $srcs $mesg
	set fatalError 1
    } elseif {[string length $diag] > 0} {
	Perl::showPerlDiag $diag $errn $mesg $errf $srcs
    }
    return $fatalError
}

# ===========================================================================
# 
# ×××× Get or Show diag/errors ×××× #
# 
# Display the Perl diagnostic output in its own window.
#

proc Perl::showPerlDiag {diag {errn 1} {mesg {}} {errf {}} {srcs {}}} {
    
    global PerlmodeVars	
    
    set perlErrorWindow {* Perl Error Messages *}
    
    set currWin [lindex [winNames] 0]
    if {[lsearch [winNames] $perlErrorWindow] >= 0} {
	bringToFront $perlErrorWindow
	setWinInfo read-only 0
	deleteText [minPos] [maxPos] 
	insertText $diag
    } else {
	new -n $perlErrorWindow 
	insertText $diag
    }
    catch {shrinkWindow 2}
    goto [minPos]
    winReadOnly
    bringToFront $currWin
}

# ===========================================================================
# 
# Bring up a window containing the bug-ridden Perl code and highlight the
# line at which the error was found.
#

proc Perl::gotoPerlError {errf srcs {mesg {}}} {
    
    global PerlmodeVars Perl::ScriptFile Perl::ScriptStart Perl::FilterHeadLen
    
    if {$errf == [Perl::scriptPath] || $errf == "<AppleEvent>"} {
	set errf [set Perl::ScriptFile]
	# Convert it to the line number in the original file
	set srcs [expr $srcs + [set Perl::ScriptStart] - [set Perl::FilterHeadLen] - 1]
    }
    # ... and leave an informative error message
    #
    if {[string length $mesg]} {
	set mesg "$mesg at Line $srcs"			
    } else {
	set mesg "MacPerl flagged an error at Line $srcs"	
    }
    
    # Bring up the script file and highlight the flagged line
    catch {file::gotoLine $errf $srcs $mesg} fname	
}

# ===========================================================================
# 
# Read the first block of lines (up to a maximum number) from the MacPerl
# output window.
#

proc Perl::getPerlDiag {maxlines} {
    
    global PerlmodeVars Perl::PerlName
    
    set pat0 {^[ \t]*$}
    
    set lines {}	
    
    # read first $maxlines of output to the MacPerl window (faster, but
    # assumes error message won't appear at the end of a lot of output).
    #
    set nlines [sendCountLines [set Perl::PerlName] MacPerl]
    set nlines [expr ($nlines > $maxlines)?$maxlines:$nlines]
    if {$nlines > 0} {
	set output [sendGetText [set Perl::PerlName] [set Perl::PerlName] 1 $nlines]
	
	foreach line [split $output "\r"] {
	    if  {[regexp -- $pat0 $line mtch]} {
		break
	    } else {
		append lines "$line\n"
	    }
	}
    }
    return $lines
}

# ===========================================================================
# 
# ×××× DoScript helpers ×××× #
# 

# translate special DoScript flags into flags string $usrf

proc Perl::scriptFlags {{flags {}}} {
    
    set usrf {}
    
    if {[lsearch -exact $flags "extract"] >= 0} {
	append usrf { "EXTR" 'true'}
    } elseif {[lsearch -exact $flags "noextract"] >= 0} {
	append usrf { "EXTR" 'fals'}
    }		
    if {[lsearch -exact $flags "debug"] >= 0} {
	append usrf { "DEBG" 'true'}
    } elseif {[lsearch -exact $flags "nodebug"] >= 0} {
	append usrf { "DEBG" 'fals'}
    }		
    
    if {[lsearch -exact $flags "local"] >= 0} {
	append usrf { "MODE" 'LOCL'}
    } elseif {[lsearch -exact $flags "batch"] >= 0} {
	append usrf { "MODE" 'BATC'}
    } elseif {[lsearch -exact $flags "remote"] >= 0} {
	append usrf { "MODE" 'RCTL'}
    }		
    return $usrf
} 

proc Perl::scriptArgs {{arguments {}} {fileargs {}}} {
    
    set nargs 0
    set argv {}
    
    foreach item [parseWords $arguments] {
	set item [string trim $item]
	if {[string length $item]} {
	    append argv ", [curlyq $item]"
	    incr nargs
	}
    }
    foreach filename $fileargs {
	set item [string trim $filename]
	if {[string length $item]} {
	    append argv ", [curlyq $item]"
	    incr nargs
	}
    }
    return $argv
}

# ===========================================================================
# 
# General Apple Event routines
# (most of these have been moved to Modes:appleEvents.tcl)
#

# ===========================================================================
# 
# DoScript for MacPerl 4.1.3
# 
# (runs in "Local" mode under v4.1.4+)
#

proc Perl::doScript {appname script {arguments {}} {fileargs {}} {flags {}} } {
    # form list of quoted "command-line" args
    #
    if {$script != ""} {
	set argv "\[[curlyq [string trim $script]]"
	append argv [Perl::scriptArgs $arguments $fileargs]
	append argv "\]"
	
	set usrf [Perl::scriptFlags $flags]
	set reply [eval "tclAE::send -p -t 36000 -r \"$appname\" misc dosc $usrf \"----\" [list $argv] "]
#	alertnote $reply
    }
}

# DoScript for MacPerl 4.1.4+
# 
# [Q] do I need this for perl via shell? -trf
#

proc Perl::doScriptBatch {appname script {arguments {}} {fileargs {}}} {
    
    # form list of quoted "command-line" args
    #
    if {$script != ""} {
	set argv "\[[curlyq [string trim $script]]"
	append argv [Perl::scriptArgs $arguments $fileargs ] 
	append argv "]"
	
	set reply [eval "tclAE::send -p -t 36000 -r \"$appname\" misc dosc MODE BATC \"----\" [list $argv]"]
	
# 	Perl::displayReply $reply
	
    } else {
	set reply {}
    }
    return $reply
}

# For debugging 

proc Perl::displayReply {reply} {
    
    set currWin [lindex [winNames] 0]
    new -n {*** DoScript Reply **} 
    insertText $reply
    goto [minPos]
    winReadOnly
    catch {shrinkWindow 2}
    bringToFront $currWin
}

# DoScript to launch interactive debugger (for MacPerl 4.1.4+)

proc Perl::doScriptDebug {appname script {arguments {}} {fileargs {}}} {
    
    # form list of quoted "command-line" args
    #
    if {$script != ""} {
	set argv "\[[curlyq [string trim $script]]"
	append argv [Perl::scriptArgs "$arguments debug" $fileargs ] 
	append argv "]"
	
	set reply [eval "tclAE::send -p -t 36000 -r \"$appname\" misc dosc MODE RCTL \"----\" [list $argv]"]
	
	new -n {** DoScriptDebug Reply **} 
	insertText $reply
	goto [minPos]
	winReadOnly
	catch {shrinkWindow 2}
    } else {
	set reply {}
    }
    return $reply
}

# ===========================================================================
# 
# ×××× Parse MacPerl Output ×××× #
# 
# Extract various items out of the MacPerl diagnostic output

# Name of the file in which the error was found

proc Perl::parseDiagErrf {diag} {
    
    if {![regexp {File '([^']+)'; Line} $diag allofit errf]} {set errf ""}
    return $errf
}

# The line number on which the error was found

proc Perl::parseDiagSrcs {diag} {
    
    if {![regexp {File '[^']+'; Line ([0-9]+)} $diag allofit srcs]} {set srcs 0}
    return $srcs
}

# The error message associated with error

proc Perl::parseDiagMesg {diag} {
    
    set pat1 {^#(.*)$}
    set pat2 {File '([^']+)'; Line ([0-9]+)}
    
    set errMessage {}
    set errFound 0
    
    foreach line [split $diag "\n"] {
	if {[regexp -- $pat2 $line mtch num]} {
	    set errFound 1
	} elseif {[regexp -- $pat1 $line mtch err]} {
	    if {$errFound == 0} {set errMessage $err}
	}
    }
    return $errMessage
}

# ===========================================================================
# 
# Extract various return parameters out of a MacPerl DoScript reply
#

# Result from batch script

proc Perl::parseReplyResult {reply} {
     if {[catch {tclAE::getKeyData $reply ----} result]} {
	 set result ""
     }
     return $result
}

# Standard output of batch script

proc Perl::parseReplyOutp {reply} {
    
    if {![regexp {OUTP:Ò([^Ó]*)Ó} $reply allofit outp]} {set outp ""}
    return $outp
}

# Diagnostic output of the batch script

proc Perl::parseReplyDiag {reply}	{
    
    if {![regexp {diag:Ò([^Ó]*)Ó} $reply allofit diag]} {set diag ""}
    return $diag
}

# File alias of the script file in which the error was found

proc Perl::parseReplyErob {reply}	{

    if {![regexp {erob:alis\(Ç(.*)È\)} $reply allofit erob]} {set erob ""}
    return $erob
}

# First line flagged in error

proc Perl::parseReplySrcs {reply}	{

    if {![regexp {erng:{srcs:([0-9]+)[^\}]*}} $reply allofit srcs]} {set srcs 0} 
    return $srcs
}

# Last line flagged in error

proc Perl::parseReplySrce {reply}	{

    if {![regexp {erng:{[^\}]*srce:([0-9]+)}} $reply allofit srce]} {set srce 0}
    return $srce
}

# Error number

proc Perl::parseReplyErrn {reply}	{

    if {![regexp {errn:([0-9]+)} $reply allofit errn]} {set errn 0}
    return $errn
}

# ===========================================================================
# 
# Read the MacPerl output window and load the contents, if any, into
# a new Alpha window. 
# 
# Modified to direct output to Tcl Shell if perl was called from there -trf
#

proc Perl::openOutput {} {
    
    global PerlmodeVars Perl::PerlName
    
    Perl::lauchBackPerl
	
	set perlOutputWindow {* Perl Output *}
    
    set output [sendGetText [set Perl::PerlName] [set Perl::PerlName]]
    if {[string length $output]} {
	if {[win::CurrentTail] == "*tcl shell*"} {
	    endOfBuffer
	    insertText \r $output
	    endOfBuffer 
	} elseif {$PerlmodeVars(recycleOutput) && 
	[lsearch [winNames] $perlOutputWindow] >= 0} {
	    
	    bringToFront $perlOutputWindow
	    replaceText [minPos] [maxPos] $output
	    catch {shrinkWindow 2}
	    setWinInfo dirty 0
	    goto [minPos]
	} else {
	    new -n $perlOutputWindow
	    insertText $output
	    catch {shrinkWindow 2}
	    setWinInfo dirty 0
	    goto [minPos]
	}
    }
}

# ===========================================================================
# 
# .
