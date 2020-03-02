## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "diffMode.tcl"
 #                                   created: 03/07/1995 {11:15:02 pm}
 #                               last update: 03/21/2006 {03:05:24 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2006  Vince Darley, all rights reserved
 #
 # Description: 
 # 
 # Largely re-written Diff mode for Alpha.  Still under construction,
 # but already a lot better than the old one.  Basic features:
 # 
 # A 'Diff' menu, which contains commonly used options.
 # 
 # Uses Alpha's 'marks' so that you can patch diffs back and forth
 # between files without losing the correct location in the file.
 # 
 # In the section 'Main Comparison Routines', there is an overview of 
 # how the various procs call each other.
 # 
 # Limitations:
 # 
 # Note: the various additions to cope with context sensitive versus
 # normal diffs versus cvs-style versus perforce ... mean that this
 # code is beginning to get rather spaghetti like.  It really needs
 # a complete overhaul (and probably a small test suite so that we can
 # ensure the code works for all these formats).
 # 
 # The code in this file for patching (and perhaps viewing etc), and
 # for finding the right file, for deciding whether to display left
 # or right window or both, etc. is way too convoluted and difficult
 # to comprehend.  This is basically as a result of the gradual evolution
 # of this file.  It needs to be rewritten from scratch in much
 # simplified form.
 # 
 # Table of contents:
 # 
 #     Diff mode
 #	    alpha::mode Diff
 #	    <Menu>
 #	    Diff::menuProc
 #	    <Key bindings>
 #	    Diff::activateHook
 #	    Diff::locateLeftWindow
 #	    Diff::locateRightWindow
 #	    Diff::locateLeftDir
 #	    Diff::locateRightDir
 #	    Diff::rerunDiff
 #     
 #     Compare 'package'
 #	    alpha::library "compare"
 #	    compare::files
 #	    compare::directories
 #	    compare::windows
 #	    compare::selections
 #	    compare::windowsWordByWord
 #	    compare::selectionsWordByWord
 #	    Diff::tempfileFromWordsIn
 #	    Diff::tempfileWordPosFromNumber
 #	    Diff::tempfileFromWin
 #	    Diff::tempfileFromSelection
 #	    compare::useExternalCompareApplication
 #	    compare::diffPrefs
 #	    compare::diffHelp
 #     
 #     Main comparison routines
 #	    <documentation of procs and win attributes>
 #	    compare::execute
 #	    Diff::diffWindow
 #	    Diff::of
 #	    Diff::opening
 #	    Diff::getFiles
 #     
 #     Parsing diff data and marking windows
 #	    Diff::parseDiffWin
 #	    Diff::parseLineIntoFromTo
 #	    Diff::parseAtsIntoLine
 #	    Diff::storeMarks
 #	    Diff::ensureMarkdictReady
 #	    Diff::parseDiffString
 #	    Diff::computePositionsForWordByWord
 #	    Diff::mark
 #	    Diff::line
 #     
 #     Hooks and maintenance of the win attributes
 #	    Diff::cleanUpAndResizeWindows
 #	    Diff::cleanUpAndCloseWindows
 #	    Diff::closing
 #	    Diff::dyingWindow
 #	    Diff::updateMarkdictFromMarks
 #	    Diff::cleanup
 #     
 #     Moving around
 #	    Diff::Up
 #	    Diff::Down
 #	    Diff::move
 #	    Diff::NextFile
 #	    Diff::PrevFile
 #	    Diff::changeFile
 #	    Diff::Select
 #	    Diff::DisplayAndMarkLeftAndRight
 #	    Diff::Display
 #	    Diff::ensureVisible
 #	    Diff::View
 #	    Diff::displayLines
 #	    Diff::Sel
 #     
 #     Patching routines
 #	    Diff::patch
 #	    Diff::patchIntoLeftWindow
 #	    Diff::patchIntoRightWindow
 #     Utilities
 #	    Diff::Geo
 #	    Diff::translatePathDelimiters
 #	    file::hasOneOpenWindow
 #	    Diff::path1
 #	    Diff::path2
 #	    Diff::win1
 #	    Diff::win2
 #     
 #
 # History:
 #
 # modified   by  rev    reason
 # --------   --- ---    -----------
 # 7/3/95     PJK?1.0    original
 # 3/9/97     VMD 2.0    much improved version
 # 03/23/98   VMD and Jon Guyer 2.0-3.0 various fixes and Voodoo 
 # 05/04/2000 JEG 3.1-2  fixed patching
 # 2000-05-05 VMD 3.2.1  minor fix to better handle funny filenames.
 # 2000-06-15 VMD 3.3.1  copes with various cvs/perforce style diffs
 # 2000-08-22 JEG 3.3.2  fixed bug in directory searches with 0 lines of context
 #                       fixed bug in scrolling to previous files in directory searches
 #                       added option (default on) to close document windows when done
 #                       attempts to clean up marks when finished
 # ???
 # 2003                  first xserv drivers
 # 2005-01               reorganisation around xserv adoption
 # 2005-08     JK        diffMode reform initiated.  Numerous minor fixes and 
 #                       simplifications: [compare::directories] works again; Diff 
 #                       and Compare drivers made more robust; initial arrow-up fixed 
 #                       (Bug 1890); closes object windows when supposed to; avoid 
 #                       scanning every diff window twice; added documentation; 
 #                       .DS_Store file skipping (Bug 1512); flags do not interfere 
 #                       with file names (Bug 1895); better handling of paths with 
 #                       spaces (Bug 1894); more graceful error handling when 
 #                       patching.
 # 2005-08-06   JK       Restore window geometries when closing ('temporary geometry').
 # 2005-08-08   JK       Compare selections.  (Simple plugins in [Diff::Display],
 #                       [Diff::ensureVisibleWindow], [Diff::setMarksUp], and
 #                       [Diff::parseDiffString].)
 # 2005-08-16   JK       diffMode reform, phase 2.  Overall goal: move the global
 #                       variables into win-attributes and strictify usage.
 #                       Documentation of global variables; initial cleanup.
 #                       The buggy global variable $diffDir has been replaced by 
 #                       a win attribute "difftype": this confines Bug 1907 to the
 #                       case of foreign diff files.  Workaround for 
 #                       quote-versus-brace problem reported in RFE 1888.
 #                       Dim the RerunDiff menu item when appropriate.
 # 2005-08-18   JK       All top-level procs check for dirty windows and 
 #                       double windows.  Can diff dirty windows and non-disk 
 #                       windows via temp files, and also selections in such.  
 #                       Will not diff directories with dirty windows.  
 #                       Will not diff files with multiple open windows.
 # 2005-08-19   JK       [compare::execute] is now the central compare proc
 #                       from a programmatic viewpoint, and other pieces of
 #                       code can call it directly, without first having 
 #                       to set any global variables.
 # 2005-08-22   JK 3.4.6 [Diff::diffWindow] takes five explicit arguments, 
 #                       and does not depend on globals.  It also does the
 #                       parsing explicitly instead of letting it happen in
 #                       [Diff::opening]; this hook now only does anything 
 #                       in the case of opening a diff file on disk.  
 #                       Bypass [xserv::invoke Compare] if "AlphaTcl's 
 #                       internal Diff Mode" is the chosen implementation
 #                       -- see remarks below.  Everything is now ready for 
 #                       the big step moving all globals into win arrays.
 # 2005-08-25   JK 4.0   All data related to a diff job is stored as win
 #                       attributes in the diff window, and is per window.
 #                       Marks set in the windows are also diff-job specific.
 #                       Each window contains tags telling which other 
 #                       windows it is related with, and these tags are 
 #                       kept a jour by some preCloseHooks.  As a bonus of
 #                       this data management, it is now possible to run more 
 #                       than one diff at the same time, even if the windows 
 #                       coincide.
 #                       Translation table from diff codes to window positions 
 #                       is now a single dict in the the win array.  
 #                       (Previously there were a global array for each file
 #                       (in a directory diff).)  This info is kept up-to-date
 #                       through a saveHook which write the marks back to the
 #                       markdict.  Hence the marks are stable under patching,
 #                       closing windows, etc., also in directory-diffs.
 #                       (This fixes Bug 1903.)
 #                       [Diff::Display] much redesigned: it is now only
 #                       allowed to display windows known to the mother
 #                       diff window.  It is the only proc allowed to open
 #                       windows, and it is responsible for keeping track
 #                       of window relations.  In practice we always want
 #                       to display both windows at the same time, and make
 #                       sure immediately that they are properly marked.
 #                       The new proc [Diff::DisplayAndMarkLeftAndRight]
 #                       does this.
 #                       [Diff::viewSophisticated] and [Diff::patchSophisticated]
 #                       become [Diff::View] and [Diff::patch].  The old procs of 
 #                       those names are gone.
 #                       [Diff::ensureVisibleWindows], sort of buggy, is gone.
 #                       New [Diff::ensureVisible] should be much better, called 
 #                       precisely when needed.
 #                       
 #                       New diff modality: word-by-word comparison of windows or 
 #                       selections.  (This works via a temp file with one word 
 #                       per line, and a list of positions.)  These are 
 #                       option-dynamic items in the Compare submenu.  
 #                       To test this, please run the help command 
 #                           help::openExample "CompareWordByWord Example"
 # 2005-09-13   JK 4.0.1 Better work-around for Bug 1914 in word-by-word 
 #                       comparisons.  Now uses [search -all] as it should,
 #                       instead of [regexp -all], and it should work in AlphaTk
 #                       too.
 # 2005-09-15   JK 4.0.2 Fixed Bug 1911: the main parser [Diff::parseDiffWin] 
 #                       now sets the diffsyntax attribute to "usesStars" 
 #                       when appropriate, and [Diff::line] acts accordingly.
 #                       (In Alpha 8.0, this was controlled by the global var
 #                       $diffDir, for some reason.)
 # 2005-09-23   JK 4.1   Moved to "Diff Mode" directory.  diff drivers and
 #                       compare drivers moved to separate file "diffDrivers.tcl".
 #                       Reorganised this file.
 # 2005-10-02   JK 4.1.1 Context diff off for word-by-word comparisons.
 # 2005-10-06   JK 4.1.2 Fixed Bug 1927: [Diff::patch]: wrong $suff in 
 #                       non-directory context diff.
 # 2005-10-22   JK 4.1.3 Behaviour change: frontmost win is 'new' (cf. RFE 1921).
 #                       Simplified [Diff::line] and [Diff::Patch].
 #                       Bug 1894 fixed.
 # 2005-12-21  cbu 4.1.4 * [Diff::cleanUpAndResizeWindows] actually re-sizes 
 #                       windows (again).
 #                       * Better attempt made to make locked files writable when 
 #                       under version control.
 # 2006-02-17   JK 4.1.5 Resize-to-original prefs flag, and stabler display (from
 #                       Craig).  "Mark both" enabled as originally intended.                     
 # 
 # ==========================================================================
 ##

# The following procs are gone:  
# Diff::parseDiffLine   (was never in use)
# Diff::diffWinFront, Diff::Win    (don't really make sense now that there 
#       can be more than one diff window)
# Diff::viewSophisticated   (merged with Diff::View)
# Diff::patchSophisticated   (merged with Diff::patch) 
# Diff::run   (subsumed in Diff::execute)
# Diff::displayAll   (use [xserv::invoke Diff] instead)
# Diff::ensureVisibleWindows, Diff::ensureVisibleWindow   (replaced by 
#       Diff::ensureVisible).
# [Diff:setMarksUp]   (subsumed in Diff::ensureMarkdictReady)


################################################################
# ×××× Compare 'package' ×××× #
################################################################

alpha::library "compare" 0.1 {
    namespace eval compare {}
    diffDrivers.tcl
    if { ![string length [xserv::getCurrentImplementationsFor Compare]] } {
	xserv::chooseImplementationFor Compare \
	  [list -name "AlphaTcl's internal Diff Mode"]
    }
    menu::insert Utils submenu 0 compare
    menu::insert compare items end (-) \
      "<E<Swindows" "<S<IwindowsWordByWord" \
      "<E<Sselections" "<S<IselectionsWordByWord" \
      "filesÉ"  "directoriesÉ" "(-"\
      [menu::itemWithIcon "diffPrefsÉ" 84] "diffHelp"
    hook::register requireOpenWindowsHook [list compare windows] 2
    hook::register requireOpenWindowsHook [list compare selections] 2
    hook::register requireOpenWindowsHook [list compare windowsWordByWord] 2
    hook::register requireOpenWindowsHook [list compare selectionsWordByWord] 2
}

################################################################
# ×××× Diff mode ×××× #
################################################################

# rest of diff mode is below.  Declaration needs to be at the start of
# the file.

alpha::mode Diff 4.1 diffMenu {*.diff *.patch} {diffMenu} {
    alpha::internalModes "Diff"
    # Up/Down arrows both scroll the diff window and synchronise the viewed
    # portion of text in the document windows
    newPref f synchroniseMoveAndView 1 Diff
    # Treat all files as text and compare them line-by-line, even if they 
    # don't seem to be text
    newPref f treatAllFilesAsText 1 Diff
    # Default lines of context to generate when asking Diff to do its magic
    newPref var linesOfContext 3 Diff
    if { $alpha::macos == 2 } {
	# Other diff flags you want to send to the Diff application, -B -q -r etc.
	newPref var diffFlags {--exclude=.DS_Store} Diff
    } else {
	newPref var diffFlags {} Diff
    }
    # Ignore changes in case; consider upper- and lowercase letters equivalent
    newPref f ignoreCase 0 Diff
    # Ignore changes that just insert or delete blank lines
    newPref f ignoreBlankLines 0 Diff
    # Ignore changes in amount of white space
    newPref f ignoreSpaceChanges 0 Diff
    # Ignore all white space when comparing lines
    newPref f ignoreWhiteSpace 0 Diff
    # When comparing directories, recursively compare any subdirectories found
    newPref f compareDirectoriesRecursively 0 Diff
    # If you've imported a diff file from a Unix/Windows system and wish
    # to view or use it on MacOS Classic, this option allows you to use
    # it with Alpha on MacOS Classic too.  It also works the other way
    # round (import a diff file from MacOS onto Unix/Windows system).
    newPref f translatePathDelimiters 1 Diff
    # If you've imported a diff file from a different directory structure,
    # you may need to remove a given prefix so Alpha can find your files
    # correctly.
    newPref v removeFilePrefix "" Diff
    # If the document windows were not already open before the diff, automatically
    # close them when finished.
    newPref f killWindowsWhenDone 1 Diff
    # Adjust each document window's geometry to original size when 
    # closing the diff window.
    newPref f resizeWindowsWhenDone 0 Diff
    addMenu diffMenu ¥288 Diff
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
    and "Joachim Kock" <kock@mat.uab.es> <http://mat.uab.es/~kock/>
} description {
    Provides internal support for displaying "diff" result windows
} help {
    file "Diff Help"
}

proc diffMode.tcl {} {}

# Diff mode: Menu and Key bindings
# --------------------------------

namespace eval Diff {}
prefs::removeObsolete \
  DiffmodeVars(workaroundAlphaColourBug) \
  DiffmodeVars(useFastWindowSwapping) \
  DiffmodeVars(useMarksDontBringToFront) \
  DiffmodeVars(useSophisticatedDiffMarking)

proc diffMenu {} {}

Menu -n $diffMenu -p Diff::menuProc -M Diff {
    "rerunDiff"
    "(-"
    "/<I<BpatchIntoLeftWindow"
    "/<I<BpatchIntoRightWindow"
    "(-"
    "cleanUpAndCloseWindows"
    "cleanUpAndResizeWindows"
    "(-"
    "locateLeftWindowÉ"
    "locateRightWindowÉ"
    "locateLeftDirÉ"
    "locateRightDirÉ"
    "parseDiffWin"
    "(-"
    "diffPrefsÉ"
    "diffHelp"
}

proc Diff::menuProc {menu item} {
    switch -- $item {
	"diffPrefs" - "diffHelp" {
	    compare::$item
	}
	default {
	    Diff::$item
	}
    }
}

Bind 0x7b <z> Diff::patchIntoLeftWindow Diff
Bind 0x7c <z> Diff::patchIntoRightWindow Diff

# do the rest
Bind '\r'		Diff::Select	Diff
Bind 0x30		Diff::View	Diff
# Bind Kpad. <c>		Diff::Win
Bind Enter		{Diff::Down;Diff::Select}	Diff
Bind Kpad0		{Diff::Up;Diff::Select}	Diff

Bind down		Diff::Down	Diff
Bind up		        Diff::Up	Diff
Bind down	<o>	Diff::NextFile	Diff
Bind up		<o>	Diff::PrevFile	Diff


hook::register activateHook {Diff::activateHook}

proc Diff::activateHook {winName} {
    global diffMenu
    set enableRerunDiffMenuItem 1
    catch {win::getInfo $winName difftype} diffType
    if { $diffType eq "selections" || [string match "*foreign*" $diffType] } {
	set enableRerunDiffMenuItem 0
    }
    enableMenuItem $diffMenu "rerunDiff" $enableRerunDiffMenuItem
    
    foreach item [list \
      "locateLeftWindowÉ" \
      "locateRightWindowÉ" \
      "locateLeftDirÉ" \
      "locateRightDirÉ" \
      "parseDiffWin"] {
	enableMenuItem $diffMenu $item [string match "*foreign*" $diffType]
    }
    return
}



# Perhaps these two procs should check if the paths are also windows...
proc Diff::locateLeftWindow {} {
    set DW [win::Current]
    set path1 [getfile "Select your left (old) file:"]
    win::setInfo $DW path1 $path1
    Diff::Display $DW left 0
    Diff::ensureMarkdictReady $DW
    Diff::mark $DW left ""
    bringToFront $DW
}
proc Diff::locateRightWindow {} {
    set DW [win::Current]
    set path2 [getfile "Select your right (new) file:"]
    win::setInfo $DW path2 $path2
    Diff::Display $DW right 0
    Diff::ensureMarkdictReady $DW
    Diff::mark $DW right ""
    bringToFront $DW
}

proc Diff::locateLeftDir {} {
    set DW [win::Current]
    set dir [get_directory -p "Select your left (old) directory:"]

    win::setInfo $DW path1 $dir
    win::setInfo $DW difftype "directories"
    win::setInfo $DW _leftDir $dir
}
proc Diff::locateRightDir {} {
    set DW [win::Current]
    set dir [get_directory -p "Select your right (new) directory:"]
    win::setInfo $DW path2 $dir
    win::setInfo $DW difftype "directories"
    win::setInfo $DW _rightDir $dir
}

# This proc doesn't always make sense...
proc Diff::rerunDiff {} {
    variable dontResize
    set DW [win::Current]
    set diffType [win::getInfo $DW difftype]
    set path1 [win::getInfo $DW path1]
    set path2 [win::getInfo $DW path2]
    switch -glob -- $diffType {
	selections {
	    error "Cancelled.  Re-run \"Compare Selections\" not implemented."
	}
	foreign* {
	    error "Cancelled.  Don't know what to re-run: diff file of external origin."
	}
	windows {
	    if { ![file readable $path1] || ![file readable $path2] } {
		error "Cancelled.  Don't know which files to diff."
	    }
	}
	default {
	    # continue
	}
    }
    # Now we know the difftype is one where both path1 and path2 are defined
    set dontResize 1
    killWindow -w $DW
    unset dontResize
    
    # Check for dirty windows:
    set wins [file::hasOpenWindows $path1]
    if {[llength $wins] > 1} {
	error "Cancelled.  Too many open windows for file \"$path1\""
    } elseif {[llength $wins] == 1} {
	set win1 [lindex $wins 0]
	if { [win::isDirty $win1] } {
	    bringToFront $win1
	    if {[dialog::yesno -y "Save" -n "Cancel" \
	      "Window \"[file tail $win1]\" has unsaved changes"]} { 
		save
	    }
	}
    }
    set wins [file::hasOpenWindows $path2]
    if {[llength $wins] > 1} {
	error "Cancelled.  Too many open windows for file \"$path2\""
    } elseif {[llength $wins] == 1} {
	set win2 [lindex $wins 0]
	if { [win::isDirty $win2] } {
	    bringToFront $win2
	    if {[dialog::yesno -y "Save" -n "Cancel" \
	      "Window \"[file tail $win2]\" has unsaved changes"]} { 
		save
	    }
	}
    }
    
    # Better write some check procs that can be used in general
    # and then call those check procs from all top-level procs
    # including this one...
    
    compare::execute $path1 $path2 $diffType $DW
}


namespace eval compare {}


# ×××× The four top level compare procs ×××× #

# These procs call xserv Compare.  We guarantee that they only give
# arguments that are complete paths.  If the paths are directories we
# guarantee furthermore that there are no open dirty windows belonging
# to those directories.  If the paths are files the same guarantee holds
# for the arguments passed to Compare, but this may be because we have
# passed a temporary file instead of a non-disk window or a dirty window.
# We still guarantee however, that each original window has this property:
# there is no other window linked to the same file.  This means that from
# the file name it is possible to identitfy the window uniquely.

# The four toplevel procs bypass [xserv::invoke Compare] if "AlphaTcl's
# internal Diff Mode" is the chosen implementation for Compare.  It is much
# more natural for Diff mode to communicate directly with Diff mode,
# without having to go through xserv, which is not flexible enough to
# handle the involved data (for example difftype and window name).
# Previously this problem was bypassed by setting global variables before
# calling [xserv::invoke Compare] so that the lower level procs
# ([Diff::execute] and below) could pick up the info there.  Clearly this
# was a clumsy and fragile solution (and in any case was already a sort of
# bypass).  (If somebody complains that the new solution is a dirty
# workaround and that the correct thing would be to improve xserv so that
# it could handle all the data needed, I will respond that xserv was
# designed for communicating with external applications: it was never
# intended as a medium for one application communicating with itself -- as
# such it would always be an unnatural limiting factor rather than a help.
# A farmer should be allowed to eat his own eggs without buying them from
# himself at the market, and two people in the same room should not be
# forced to use the phone to talk to each other.)

proc compare::files {{f1 ""} {f2 ""}} {
    if {$f1 eq ""} {
	set f1 [getfile "Select your 'old' file:"]
    }
    set f1 [file normalize $f1]
    if {$f2 eq ""} {
	set f2 [getfile "Select your 'new' file:"]
    }
    set f2 [file normalize $f2]
    
    # Check if $f1 happens to be open (and not multi-open), or dirty:
    if { [file::hasOneOpenWindow $f1 win1] } {
	if { [win::isDirty $win1] } {
	    bringToFront $win1
	    if {[dialog::yesno -c -y "Save and diff" -n "Diff dirty" \
	      "Window \"[file tail $win1]\" has unsaved changes"]} { 
		save
	    } else {
		set f1 [Diff::tempfileFromWin $win1]
	    }
	}
    }
    # Check if $f2 happens to be open and dirty:
    if { [file::hasOneOpenWindow $f2 win2] } {
	if { [win::isDirty $win2] } {
	    bringToFront $win2
	    if {[dialog::yesno -c -y "Save and diff" -n "Diff dirty" \
	      "Window \"[file tail $win2]\" has unsaved changes"]} { 
		save
	    } else {
		set f2 [Diff::tempfileFromWin $win2]
	    }
	}
    }

    if { [useExternalCompareApplication] } {
	xserv::invoke Compare -oldpath $f1 -newpath $f2
    } else {
	compare::execute $f1 $f2 "files" "* File Comparison *"
    }
}


proc compare::directories {{d1 ""} {d2 ""} {name {* Directory Comparison *}}} {
    if {$d1 eq ""} {
	set d1 [get_directory -p "Select 'old' dir 1:"]
    }
    set d1 [file normalize $d1]
    if {$d2 eq ""} {
	set d2 [get_directory -p "Select 'new' dir 2:"]
    }
    set d2 [file normalize $d2]
    
    # If there is a dirty window belonging to one of the directories, we
    # don't want to perform the diff --- if we just diff the file on disk,
    # then we would have a problem if there is a difference in it: how 
    # would we open a window showing the difference?  The dirty window 
    # would not work, because is has a different content.  And we can't
    # insert any sort of temporary file into a diff directory...  So it
    # seems that we can't do any better than urging the user to save the
    # file before proceeding with the diff.
    foreach win [winNames -f] {
	if { [win::isDirty $win] } {
	    foreach d [list $d1 $d2] {
		# Check if the directory contains $win:
		if { [string match [quote::Glob $d]* [win::StripCount $win]] } {
		    bringToFront $win
		    if {[dialog::yesno -y "Save" -n "Cancel" \
		      "Window \"[file tail $win]\", belonging to dir \"$d\", \
		       has unsaved changes"]} { 
			save $win
			break
		    } else {
			set err "Cancelled.  Please save changes in window "
			append err "\"[file tail $win]\", "
			append err "then try \"Compare DirectoriesÉ\" again."
			error $err
		    }
		}
	    }
	}
    }

    if { [useExternalCompareApplication] } {
	xserv::invoke Compare -oldpath $d1 -newpath $d2
    } else {
	compare::execute $d1 $d2 "directories" "* Directory Comparison *"
    }
}

proc compare::windows {} {
    set wins [winNames -f]
    if {[llength $wins] < 2} {
	status::msg "Need 2 windows"
	return
    }
    # The frontmost window is the 'new' file (cf. RFE 1921).
    # New:
    set win2 [lindex $wins 0]
    # Old:
    set win1 [lindex $wins 1]
    
    # Check if $win1 needs saving or needs a temporary file:
    if { [win::isDirty $win1] } {
	bringToFront $win1
	if {[dialog::yesno -c -y "Save and diff" -n "Diff dirty" \
	  "Window \"[file tail $win1]\" has unsaved changes"]} { 
	    set f1 [save]
	    file::hasOneOpenWindow $f1
	} else {
	    set f1 [Diff::tempfileFromWin $win1]
	}
    }  elseif { ![win::IsFile $win1 f1] } {
	set f1 [Diff::tempfileFromWin $win1]
    }
    # Check if $win2 needs saving or needs a temporary file:
    if { [win::isDirty $win2] } {
	bringToFront $win2
	if {[dialog::yesno -c -y "Save and diff" -n "Diff dirty" \
	  "Window \"[file tail $win2]\" has unsaved changes"]} { 
	    set f2 [save]
	    file::hasOneOpenWindow $f2
	} else {
	    set f2 [Diff::tempfileFromWin $win2]
	}
    } elseif { ![win::IsFile $win2 f2] } {
	set f2 [Diff::tempfileFromWin $win2]
    }
    
    if { [useExternalCompareApplication] } {
	xserv::invoke Compare -oldpath $f1 -newpath $f2
    } else {
	compare::execute $f1 $f2 "windows" "* Window Comparison *"
    }
}

proc compare::selections {} {
    set wins [winNames -f]
    if { [llength $wins] < 2 } { 
	status::msg "Need 2 windows, each with a selection."
	return 
    }
    # The frontmost window is the 'new' file (cf. RFE 1921).
    # New:
    set path2 [Diff::tempfileFromSelection [lindex $wins 0]]
    # Old:
    set path1 [Diff::tempfileFromSelection [lindex $wins 1]]

    if { [useExternalCompareApplication] } {
	xserv::invoke Compare -oldpath $path1 -newpath $path2
    } else {
	compare::execute $path1 $path2 "selections" "* Comparison of Selections *"
    }
}

# This is experimental
proc compare::windowsWordByWord {} {
    set wins [winNames -f]
    if { [llength $wins] < 2 } { 
	status::msg "Need 2 windows."
	return 
    }
    # The frontmost window is the 'new' file (cf. RFE 1921).
    # New:
    set path2 [Diff::tempfileFromWordsIn window [lindex $wins 0]]
    # Old:
    set path1 [Diff::tempfileFromWordsIn window [lindex $wins 1]]

    if { [useExternalCompareApplication] } {
	error "Cancelled.  Word-by-word comparison not implemented for external Compare applications."
	xserv::invoke Compare -oldpath $path1 -newpath $path2
    } else {
	# Before calling [execute] we should turn off context diff -- it 
	# doesn't really make sense together with word-by-word.  (The 
	# present method, provisorily setting DiffmodeVars, assumes that
	# [execute] reads that array.  A cleaner design would be to let
	# [execute] accept flags...)
	set linesOfContext $::DiffmodeVars(linesOfContext)
	set ::DiffmodeVars(linesOfContext) 0
	compare::execute $path1 $path2 "windows-wordbyword" "* Word-by-word Comparison *"
	set ::DiffmodeVars(linesOfContext) $linesOfContext
    }
}

# This is experimental
proc compare::selectionsWordByWord {} {
    set wins [winNames -f]
    if { [llength $wins] < 2 } { 
	status::msg "Need 2 windows, each with a selection."
	return 
    }
    # The frontmost window is the 'new' file (cf. RFE 1921).
    # New:
    set path2 [Diff::tempfileFromWordsIn selection [lindex $wins 0]]
    # Old:
    set path1 [Diff::tempfileFromWordsIn selection [lindex $wins 1]]

    if { [useExternalCompareApplication] } {
	error "Cancelled.  Word-by-word comparison not implemented for external Compare applications."
	xserv::invoke Compare -oldpath $path1 -newpath $path2
    } else {
	# Before calling [execute] we turn off context diff -- it 
	# doesn't really make sense together with word-by-word.
	# (The present method, provisorily setting DiffmodeVars, 
	# assumes that [execute] reads that array.  A cleaner design 
	# would be to let [execute] accept flags...)
	set linesOfContext $::DiffmodeVars(linesOfContext)
	set ::DiffmodeVars(linesOfContext) 0
	compare::execute $path1 $path2 "selections-wordbyword" "* Word-by-word Comparison *"
	set ::DiffmodeVars(linesOfContext) $linesOfContext
    }
}


# # -----------------------------------------------------------------------
# # The following auxiliary temp file procs contain a lot of repetition, and
# # they may eventually be written together to something.  The windows procs
# # should just be special cases of the selection procs...
# # 
# # Possibly the general temp procs in tempWindows.tcl may be generalised to
# # account for this sort of extra functionality.  Let's wait and see until
# # the dust settles.
# # -----------------------------------------------------------------------


# Calling sequence:  
#        Diff::tempfileFromWordsIn "window" $winName
#        Diff::tempfileFromWordsIn "selection" $winName
# Produce a temp file with an extra third attribute which is a flat list of 
# the positions of all the words in the text chunk (window or selection).
proc Diff::tempfileFromWordsIn { domain win } {
    # The split pattern captures space sequences with zero or one linebreak:
    set splitPat {(?:[ \t]+|[ \t]*[\r\n][ \t]*)}
    # Determine the text limits:
    if { $domain eq "selection" } {
	requireSelection -w $win
	set startPos [getPos -w $win]
	set endPos [selEnd -w $win]
    } elseif { $domain eq "window" } {
	set startPos [minPos]
	set endPos [maxPos -w $win]
	if { $startPos == $endPos } {
	    error "Cancelled.  Empty window."
	}
    }
    set thisFileOffSet [lindex [pos::toRowChar -w $win $startPos] 0]
    # Prepare the index list.  First version has the positions of $splitPat:
    set indexlist \
      [search -w $win -all -f 1 -r 1 -l $endPos -- $splitPat $startPos]
    #### WORK-AROUND FOR BUG 1914 ####
    # Run through the list and remove matches contained in the previous match
    set L $indexlist
    if { [llength $L] > 1 } {
	set indexlist [lrange $L 0 1]
	for { set i 1 } { [expr {2*$i}] < [llength $L] } { incr i } {
	    if { [lindex $L [expr {2*$i +1}]] > [lindex $indexlist end] } {
		lappend indexlist [lindex $L [expr {2*$i}]] [lindex $L [expr {2*$i +1}]]
	    } 
	}
    }
    #### END OF WORK-AROUND FOR BUG 1914 ####
    # Now shift the list so that the indices refer to words, not to whitespace:
    if { $startPos < [lindex $indexlist 0] } {
	set indexlist [linsert $indexlist 0 $startPos]
    } else {
	lvarpop indexlist
    }
    if { $endPos > [lindex $indexlist end] } {
	lappend indexlist $endPos
    } else {
	lvarpop indexlist end
    }
    
    # Prepare the text chunk:
    set txt [string trim [getText -w $win $startPos $endPos]]
    regsub -all $splitPat $txt \r wordlist
    # Write the temporary file:
    set tail [file tail $win]
    set tempFile "${tail}-temp"
    set newFile  [temp::unique Diff $tempFile]
    file::writeAll $newFile $wordlist 1 
    # Register the temp file for redirection:
    temp::attributesForFile $newFile $win $thisFileOffSet $indexlist
    return $newFile
}

# Given the name of a temp file, and one or two word numbers,
# return the positions of those words in the original window.
proc Diff::tempfileWordPosFromNumber { tempFile n0 {n1 ""} } {
    set tmpAttr [temp::attributesForFile $tempFile ]
    set indexlist [lindex $tmpAttr 2]
    set return0 [lindex $indexlist [expr {2*$n0}]]
    if { [string length $n1] } {
	set return1 [lindex $indexlist [expr {2*$n1+1}]]
    } else {
	set return1 [lindex $indexlist [expr {2*$n0+1}]]
    }
    return [list $return0 $return1]
}


# This proc is not very Diff specific.  It might be reformulated in the
# temp namespace, if needed elsewhere.
proc Diff::tempfileFromWin { win } {
    # The $win name will typically contain a <2> style decoration
    set txt "[getText -w $win [minPos] [maxPos -w $win]]"
    set tail [file tail $win]
    set tempFile "${tail}-temp"
    set newFile  [temp::unique Diff $tempFile]
    file::writeAll $newFile $txt 1 
    # Register the temp file for redirection:
    temp::attributesForFile $newFile $win 0
    return $newFile
}

# This proc is not very Diff specific.  It might be reformulated in the
# temp namespace, if needed elsewhere.
proc Diff::tempfileFromSelection { win } {
    requireSelection -w $win
    set txt "[getSelect -w $win]"
    set thisFileOffSet [lindex [pos::toRowChar -w $win [getPos -w $win]] 0]
    # We should count the number of lines before the selection, not the
    # linenumber of the first line in the selection:
    incr thisFileOffSet -1
    set tail [file tail $win]
    set tempFile "${tail}-temp"
    set newFile  [temp::unique Diff $tempFile]
    file::writeAll $newFile $txt 1 
    # Register the temp file for redirection:
    temp::attributesForFile $newFile $win $thisFileOffSet
    return $newFile
}




proc compare::useExternalCompareApplication {} {
    # Check with xserv who is chosen implementation of 'Compare':
    expr { [::xserv::getCurrentImplementationNameFor Compare ""] ne \
      "AlphaTcl's internal Diff Mode" }
}


proc compare::diffPrefs {} {
    loadAMode Diff
    prefs::dialogs::packagePrefs Diff
}

proc compare::diffHelp {} {
    package::helpWindow "Diff"
}


################################################################
# ×××× Main comparison routines ×××× #
################################################################

# <JK, August 2005> Here is my interpretation of how diff mode works.  The
# good news is that there seems to be two mostly independent phases.
# 
# The first phase is all that happens when you invoke a compare command, up
# to the point where the diff window and the two windows are in place on the
# screen -- let's call the two windows 'object windows' for the lack of a
# better name.  This phase also involves a crude parsing of the diff file and
# placing the diff codes in a mark dict (but they are not yet put into the
# object windows as marks).
# 
# The second phase is what happens the first time you do an operation on the
# diff window involving an object window, for example press the Down key to
# navigate to the next difference.  This phase involves another round of
# parsing, namely taking the diff codes stored in the mark dict and
# translate them into win positions, and finally setting the marks in the
# object windows, and using them to make selections and patches.  
# 
# When diffing directories, step 2 is repeated each time the navigation
# leads us to a file that has not previously been treated during this diff 
# run.  Then the old object windows are closed, and the new ones are opened,
# and the marks are set in them.
# 
# 
# Here is a more detailed description of the two phases:
# 
# Phase 1:
# 
# [compare::windows], [compare::files], [compare::directories], or
# [compare::selections]
#     figure out what to compare (possibly some temp file), check for dirty 
#     windows, and then do
# [xserv::invoke Compare]
#     which is just a wrapper for
# [compare::execute]
#     which calls
#     [::xserv::invoke Diff] to get the diff text $dtext and then calls
# [Diff::diffWindow $diffWindow $dtext $path1 $path2 $type]
#     which opens the diff window, hereby triggering the hook
#     [Diff::opening], which assigns a number to the diff window,
#     and then calls
#   [Diff::parseDiffWin]
#     which does a lot of hard work (calling [Diff::parseLineIntoFromTo] and
#     [Diff::parseAtsIntoLine]), and in the end stores the diff codes in the
#     mark dict by calling
#   [Diff::storeMarks]
#     then finally opens both files (if necessary), calling 
#   [Diff::DisplayAndMarkLeftAndRight], which calls 
#     [Diff::Display] on each file, and then calls 
#     [Diff::ensureMarkdictReady].  This proc in turn calls 
#       [Diff::parseDiffString]: this is where the diff codes are translated 
# 	    into win position (and the only place we need to worry about 
# 	    shifts for temp files) --- and finally
#     [Diff::mark] on each object window.
# 
# 
# Phase 2:
# 
# The navigation keys are bound to two double actions, e.g.
# [Diff::Down] followed by 
# [Diff::View]
#     This proc will eventually just look up the diff code in the
#     marks of each object window, and go to that mark, but before 
#     doing that it checks if the marks have been set, and in case they 
#     haven't, set them by calling
# [Diff::ensureMarkdictReady]
#     This proc in turn calls 
#     [Diff::ensureMarkdictReady].  This proc in turn calls 
#       [Diff::parseDiffString]: this is where the diff codes are translated 
# 	    into win position (and the only place we need to worry about 
# 	    shifts for temp files) --- and finally
#     [Diff::mark] on each object window.
#     Finally calls
# [Diff::displayLines]
# 
# Note: in the temp file case, after calling [Diff::parseDiffString] we
# don't need the line shifts anymore, and in fact we don't even need the
# temp file anymore, so at this point we simply purge the temp file and
# point the win attributes win1 and win2 to the original windows.  From
# this point the marks are in place in the original window (and they have
# names referring to the diff codes in the diff file, so we can find each
# diff spot from the diff code in the diff file), and the rest of the
# actions, displaying and patching, can proceed without ever noticing
# that the diff file originates from temporary files...)
# 
# 
# 
# --------------------------------------------------
# 
# 	  Overview of the win attributes
# 
# --------------------------------------------------
# 
# A diff window has the following attributes:
# 
# diffnumber
#       a unique identitfier.  Set to the smallest natural number greater than 
#       all diffnumbers currently in use (i.e. typically 0).  This number 
#       is used when naming the marks, so that different diff jobs can 
#       recognise their own marks, and not interfere with others'.  The
#       diffnumber aatribute is set by the [Diff::opening] hook and remains
#       fixed for the lifetime of the window.
# 
# difftype
#       can be anyone of "files", "directories", "windows", "selections", 
#       "foreign" plus some subtypes like "foreign-directories", 
#       "foreign-patch", "windows-wordbyword", etc.   This is just to
#       control certain functions that do not make sense for all types.
#       Beccause of subtypes, this attribute should mostly be checked
#       using [string match "*sometype*" $difftype].
#   
#       This attribute always exists.
#       
#       This variable is set by the top-level procs (compare::files, etc.)
#       The type "foreign" and its subtypes refer to the situation where
#       the diff data has not been produced by Diff mode, i.e. opening a
#       diff file on disk.  (There is one more case, namely [Diff::of]
#       which will set the variable to "foreign-patch".)  The proc 
#       [Diff::parseDiffWin] is only allowed to change the value if the
#       previos value was "*foreign*", and it may wrongly detect type 
#       "directories" (and hence write "foreign-directories") cf. Bug 1907.
#       This is the only remaining case of Bug 1907.
# 
# path1 path2
#       the original arguments to the diff command.  These should remain
#       fixed for the lifetime of the diff job...  No window decorations
#       here.  It is not guaranteed that the value is a file on disk: it
#       was so when the diff was run, but it might have been a temporary 
#       file that is now gone.  In fact these attributes should not be
#       reference by other procs than [Diff::Display] and friends.  Once
#       the windows are open, refer rather to $win1 and $win2.  ($path1
#       and $path2 are maintained mostly to be able to do 
#       [Diff::rerunDiff].)
#       
#       If the diff window is a "foregin" diff file, user interaction may
#       be needed to manually set $path1 and $path2 using
#       [Diff::locateLeftWindow] and [Diff::locateRightWindow].  The user
#       should never call this proc under a diff run -- this will only
#       confuse the workings...
#       
# win1 win2
#       the names of the windows in which occur the currently selected
#       difference.  These are exact window names, and may also be non-disk 
#       windows or dirty windows.  It is not guaranteed that this window
#       is already open, in which case the value is rather a full path
#       (but possibly with a <2> decoration).  These attributes are initially 
#       undefined --- the convenience procs [win1] and [win2] then refer to
#       $path1 and $path2 instead.  But as soon as a window is opened the
#       attributes are set.  The values of these attributes may change during
#       the diff run: this happens for obvious reasons in a directory-diff
#       when we come to a difference in the next file.  It can also happen
#       in connection with <2> decorations: if the user diffs "file <2>"
#       and some other file, and if there is no longer any window called
#       "file", and if in the middle of the diff run "file <2>" is closed:
#       then a navigation action will open that file again, this time
#       without <2> decoration, and the $win attribute will automatically
#       adjust.  Finally it should be noted that in the case of some 
#       foreign patch file opened, $win1 or $win2 may be undefined (or be
#       set to the emptry string?)
#       
#       (Note that in temp file case, win1 and win2 will be undefined until
#       the original windows are marked by [Diff::ensureMarkdictReady].  At
#       this point the shifted positions are filled into the markdict dict,
#       and the temp files are deleted.)
# 
# markedwins
#       A list of all windows that have been marked.  We need this so that
#       we can remove the marks if the diff window is closed (the preCloseHook
#       [Diff::closing] takes care of this).  Items are appended to this list 
#       by [Diff::mark], and items are removed from it when windows are closed
#       (by the preCloseHook [Diff::dyingWindow]).
# 
# killwhendone
#       A list of all windows that have been opened by this diff run.  We 
#       need this so that we can close these windows again (according to a
#       prefs flag).  Item are appended to this list by [Diff::Display]
#       when a new window is opened, and items are removed by the preCloseHook 
#       [Diff::dyingWindow].
#       
# markdict
#       A dict containing the dictionary between diff codes and window
#       positions.  At top level, there is an entry for each filetail
#       ($suff): in a directory-diff these could be "/file1", "/file2",
#       etc.  In a single-pair diff, this toplevel key is the empty string
#       (since the two compared files may have different tails anyway).
#       
#       The subdict for each $suff is initiated by [Diff::storeMarks], 
#       called from [Diff::parseDiffWin].  At that point (before the file in 
#       question is opened in a window (or before we view any diffs in the 
#       window) the leaves of the dict are just empty strings, something 
#       like this:
#       
#         "/file2" {
#           {10a11 {a 61 62 61 62}} 
#           {1c1 {c 0 28 0 25}}
#           {6c6 {c 38 53 35 53}}
#         }
#       
#       Then when the window is opened for the first time, the proc
#       [Diff::ensureMarkdictReady] (called from
#       [Diff::DisplayAndMarkLeftAndRight]) will translate the diff codes
#       in the entries into window positions that it places as values.
#       Then the $suff ssubdict will look like this:
# 
#         "/file2" {
#           {10a11 {a 61 62 61 62}} 
#           {1c1 {c 0 28 0 25}}
#           {6c6 {c 38 53 35 53}}
#         }
# 
#       (The four numbers are window positions: two in the left window and
#       two in the right window.)
#  
#       The markdict is read by [Diff::mark] to know where to put the marks.
#       The markdict is also read by [Diff::patch] who uses it just as a
#       sort of crosscheck(?)  of the vailidy of a diff code.  It might use
#       the diff code directly to reference the mark.  This is what
#       [Diff::View] does (without reading the arrays).
#       
#       The reason it is necessary to store all this information, instead 
#       of just putting it directly into the marks as soon as the positions
#       are computed, is that we need to keep the information if the window
#       is closed, because...  Well, for this to make sense, we need a 
#       mechanism for recording the marks when a window is closed...
# 
#       
# diffsyntax
#       This attribute may contain extra info about the syntax of the diff
#       output, for example its value may be "usesAts".  Mostly the attribute
#       is undefined.
#       
# _leftDir _rightDir
#       play a very little role.  Mostly they are undefined.  The only
#       cases where they are set is if the user explicitly sets them using
#       the menu items for that purpose, and also in the case where the
#       diff window corresponds to a file on disk, and if the first file in
#       the file list belongs to the directory containing the diff file,
#       then _leftDir is set to that directory.
# 
#       The only place where the variable is read is in [Diff::View] (in
#       case of compare directories only): it will use it to adjust file1 in
#       case it is listed in the diff file in a relative way.  (If _leftDir
#       is undefined, then it will look if the unfound file1 should be an
#       open window.)
# 
# 
# 
# 
# An object window has the following attributes:
# 
# 
# hookmodes:      diffmarked
# diffjobs:       a list of all diff windows in business with this window
# 
# # ------------------------------------------------------------
# # important rule: the diffmarked hooktag is set if and only if
# # the list diffjobs is nonempty.  Nonemptiness is precisely the
# # criterion for being involved in some diffing, and we need to
# # have a hook for that, so that we can clean up some parameters
# # if the window is closed by the user.
# # ------------------------------------------------------------





# -------------------------------------------------------------------------
# 
# "compare::execute" 
# 
# This is the overall compare proc which can be called directly.
# 
# Modification of the original [Diff::execute], which did not take two path
# arguments, but instead relied on prior setting of the two global Diff::1 
# and Diff::2.  The new one is independent of global variables and takes 
# all its input as explicit arguments:  
# 
# The first two arguments are the two paths to be compared.  
# The third argument is optional and gives info about the origin of the two 
# path names: it can take any of the values "files", "directories", "windows", 
# "selections" (the default value being "files").
# The forth argument (optional) is the name for the diff window.
# (The actual name may furthermore contain a <2> decoration.)  
# 
# Results:
# 
#  Returns 1 if the files are the same and 0 if they differ
#  
#       <JK Aug2005>: it look like the proc gives the opposite return values.
#       Possibly, nobody cares about these returns anway...?
#  
# --Version--Author------------------Changes-------------------------------
#    1.0     <keleher@cs.umd.edu> original
#    1.1     <j-guyer@nwu.edu> optionally return diff result in a global
#    1.2     <j-guyer@nwu.edu> flags set if files were open before compare
#    1.3     JK: takes explicit arguments instead of relying on globals
#            no longer admits storeResults flag -- please use [xserv::invoke Diff]
#            if the result is needed as a string.
# -------------------------------------------------------------------------
##
proc compare::execute { path1 path2 {diffType files} {diffWinName "* File Comparison *"}} {
    global DiffmodeVars 

    set diffDir [expr { $diffType eq "directories" }]
    
    status::msg "Starting diffÉ"
    set path1 [win::StripCount $path1]
    set path2 [win::StripCount $path2]
    
    set dtext [::xserv::invoke Diff \
      -oldfile $path1 \
      -newfile $path2 \
      -options [array get DiffmodeVars] \
      ]
    status::msg "Starting diffÉdone"
#     # WORKAROUND for bug# 1698
#     if {($::alpha::platform eq "alpha")} {
# 	switchTo $::ALPHA
#     }
#     # End of WORKAROUND for bug# 1698
    
    if {![string length $dtext] || 
      (!$diffDir && [regexp {^Files.*are identical[\r\n]*$} $dtext])} {
	    alertnote	"No difference:\r${path1}\r$path2"
	    # WORKAROUND for bug# 1698
	    if {($::alpha::platform eq "alpha")} {
		switchTo $::ALPHA
	    }
	    # End of WORKAROUND for bug# 1698
	return 0
    } else {	
	# WORKAROUND for bug# 1698
	if {($::alpha::platform eq "alpha")} {
	    switchTo $::ALPHA
	}
	# End of WORKAROUND for bug# 1698

	# For some reason, it was previously like this: except for
	# dir-diffing, the windows are brought to front and resized even
	# before the diff window is opened, and in case of equal files, the
	# diff window is never opened.  It seems more logical only to open
	# the windows when some diff result is actually shown.  So we
	# reorder these events: first we open the difff window, then we
	# open the files as needed.  This is also much more practical since
	# we want the diff window to control the object windows, not the
	# other way around.

	::Diff::diffWindow $diffWinName $dtext $path1 $path2 $diffType 			
	return 1
    }
}


# This is the proc that opens a diff window with given diff text and fills
# in the win attributes.  It returns the name of the diff window which is 
# also a token needed in all future references to this diff job.
# 
# The first argument is the requested diff-window name (it is first in 
# analogy with most other procs in Diff mode, where this token is first 
# argument).  The actual diff-win name might be different, due to <2>
# decoration.
proc Diff::diffWindow { diffWinName diffText path1 path2 diffType } {
    global tileLeft tileTop tileWidth tileHeight	
    
    set top [expr {$tileTop + $tileHeight - 178}]
    set DW [new -n $diffWinName -g $tileLeft $top [expr {$tileWidth - 6}] 178 \
      -m Diff -info "\r$diffText\r"]
    # At this point the openhook [Diff::opening] triggers, and a diffnumber
    # is assigned to the window.  Otherwise the hook does nothing.

    # Initiate the diff win attributes:
    win::setInfo $DW difftype $diffType
    win::setInfo $DW path1 $path1
    win::setInfo $DW path2 $path2
    win::setInfo $DW killwhendone [list]
    win::setInfo $DW markedwins [list]

    # Parse the file:
    Diff::parseDiffWin $DW
    selectText [minPos] [nextLineStart [minPos]]
    refresh
    if { $diffType ne "directories" } {
	Diff::DisplayAndMarkLeftAndRight $DW
	bringToFront $DW
    }

    status::msg "Press <down> to see next difference"
}


## 
 # -------------------------------------------------------------------------
 # 
 # "Diff::of" --
 # 
 #  Used by code like version control stuff which can provide us with
 #  the name of a file/window (accessible to Alpha), and the differences 
 #  between that file/window and some other version.  We handle this in
 #  the same way as if the user opens a patch file.  We open the given
 #  $name, and show the differences in a standard Diff window.  Then we
 #  let the user examine and apply various changes as desired.
 #  
 #  Sets the difftype to "foreign-patch".  
 # -------------------------------------------------------------------------
 ##  This proc has not beed tested.
proc Diff::of {name difference} {
    Diff::diffWindow "Diff of '[file tail $name]'" \
      $difference \
      ""  $name \
      "foreign-patch"
}

# The proc [Diff:displaAll], previously found here, is gone.
# Please use [Diff::diffWindow] directly.

## 
 # -------------------------------------------------------------------------
 # 
 # "Diff::opening" --
 # 
 #  This procedure is called whenever we open a window in Diff mode,
 #  whether a '.diff' file, or whether a window produced by
 #  [Diff::execute].  A unique number is assigned to the diffjob.  Apart
 #  from that, this hook only does anything if the window corresponds to a
 #  diff file on disk.  In that case we parse its contents and write the
 #  diff codes to a mark dict, stored in the win array.  (These codes are
 #  later set as marks in the object windows.)  In the case of a shell-like
 #  window, i.e., a window produced by Diff mode, the proc
 #  [Diff::diffWindow] will do the stuff itself.
 #  
 # -------------------------------------------------------------------------
 ##
proc Diff::opening { DW } {
    # Every diff window gets a unique number:
    win::setInfo $DW "diffnumber" [Diff::newDiffnumber]
    
    if {[pos::compare [minPos] == [maxPos]]} {
	# empty window
	return
    }
    if { ![win::IsFile $DW thisdifffile] } {
	return
    }
    
    # We know this diff window is a diff file on disk:
    win::setInfo $DW difftype "foreign"
    set dir [file dirname $thisdifffile]
    set files [Diff::getFiles [minPos]]
    set f0 [lindex $files 0]
    if {[file exists [file join $dir $f0]]} {
	win::setInfo $DW _leftDir $dir
	win::setInfo $DW path1 [file join $dir $f0]
    }
    set f1 [lindex $files 1]
    if {[file exists [file join $dir $f1]]} {
	win::setInfo $DW _rightDir $dir
	win::setInfo $DW path2 [file join $dir $f1]
    }
    
    # Parse the file:
    if {[catch {Diff::parseDiffWin $DW} err]} {
	# Open hooks must not throw errors.
	status::msg $err
    }
    catch {
	global tileTop tileWidth tileHeight tileLeft
	set top [expr {$tileTop + $tileHeight - 178}]
	sizeWin $DW [expr {$tileWidth - 6}] 178
	moveWin $DW $tileLeft $top
    }
    after 400 { status::msg "Press <down> to see next difference" }
    # Must come after the afterOpeningHook which will just display the 
    # name of the window.
}

# Auxiliary proc for [Diff::opening]
proc Diff::getFiles {pos} {
    global DiffmodeVars
    set llen [llength [set files [getText $pos [nextLineStart $pos]]]]
    set files [lrange $files [expr {$llen -2}] end]
    if {$DiffmodeVars(translatePathDelimiters)} {
	set files [Diff::translatePathDelimiters $files]
    }
    return $files
}

# This proc is called in the opening hook.
# 
# When a diff window is opened, it gets assigned a unique number.  This
# number is permanent for the lifetime of the diff window.  This number is
# only used for naming the marks: marks set by diff window number 7 will be
# called diff7-23c23 and such.  This is a practical measure to avoid
# navigation mishaps if more than one diff window set marks in the same
# window, and it is strictly necessary when it comes to removing the marks
# again.  Each diff window must be able to identify the marks we have set.

proc Diff::newDiffnumber {} {
    set diffnumbersCurrentlyInUse [list]
    foreach win [winNames -f] {
	if { [win::infoExists $win "diffnumber"] } {
	    lappend diffnumbersCurrentlyInUse [win::getInfo $win "diffnumber"]
	}
    }
    if { ![llength $diffnumbersCurrentlyInUse] } {
	return 0
    }
    set diffnumbersCurrentlyInUse [lsort -integer $diffnumbersCurrentlyInUse]
    set newnumber [lindex $diffnumbersCurrentlyInUse end]
    incr newnumber
    return $newnumber
}



################################################################
# ×××× Parsing diff data and marking windows ×××× #
################################################################


# Main diff window parser: find all file name information and diff codes.
# The relevant strings are given in rather raw form to [Diff::storeMarks], 
# which in turn will place them in the mark dict in the win array.  The
# top level keys in the dict are $suff (which is "/filetail" for files
# in a directory diff, and the empty string for other types fo diff).
# Inside each $suff, the keys are like 1c1, and the values are like
# {c 1 1 1 2}.
# 
# This proc relies on [Diff::parseLineIntoFromTo] and [Diff::parseAtsIntoLine].
# 
# Bug 1907: this proc sets diffDir = 1 even when diffing single files.
# But it is only allowed to change the win attribute difftype in case
# this one is "foreign*".
# 
proc Diff::parseDiffWin { {DW ""} } {
    if { ![string length $DW] } {
	# This happens when called from the menu.
	set DW [win::Current]
    }

    bringToFront $DW
    global DiffmodeVars
    # In this version, $diffDir is just a local variable where the proc
    # expresses its opinion about whether it's a diff-directories or not.
    # We only listen to this in case of a "foreign" diff file.  Otherwise
    # we know much better in advance.

    # We assume that the win attribute "difftype" has been set at this 
    # point.  Otherwise the proc will fail, and since it happens in a hook
    # it is difficult to debug.
    
    # This is the default pattern.  Cvs style diffs (with @@) need a
    # different pattern, since this pattern can select lines of
    # diff-content rather than the preamble.
    
    # By default it's not a directory
    set diffDir 0
    
    set pos [minPos]
    while 1 {
	set res [search -s -n -f 1 -r 1 "^((diff\[^\r\n\]*|==== \[^\r\n\]*|\[^- \n\r\]+)(\r|\n|\$)|@@ )" $pos]
	if { ![llength $res] } {
	    break
	}
	set pos [pos::math [lindex $res 0] + 1]
	# If we picked up a 'diff...' line followed by a line starting with one
	# or more *'s, it a part of a context diff, announcing a new file
	# we simply ignore this.
	set foundText [getText [lindex $res 0] [pos::math [lindex $res 0] + 4]]
	if {$foundText == "diff" || $foundText == "===="} {
	    set nextStart [getText [nextLineStart [lindex $res 0]] [pos::math [nextLineStart [lindex $res 0]] +3]]
	    # The first case is a context diff, the second a Cvs context diff on a single
	    # file.
	    if {$nextStart == "***" || $nextStart == "---"} {
		continue
	    }
	    if {$foundText == "diff"} {set diffDir 1}
	}
	set t [getText [lindex $res 0] [pos::math [lindex $res 1] - 1]]
	if {[string length $t] == 1} {
	    continue
	}
	if {[regexp {^=+$} $t]} {
	    # A dividing line in a cvs-style diff
	    continue
	} elseif {[regexp {^\*+$} $t]} {
	    # Conclusion as of September 2005:
	    # It's a context diff:
	    win::setInfo $DW diffsyntax usesStars
	    
	    # Conclusion as of old diff mode (pre-August 2005):
	    # It's a diff over a directory
	    set diffDir 1
	    # check if the file has changed
	    if {[string index [set tt [getText [pos::prevLineStart $pos] $pos]] 0] != " " \
	      && [lookAt [pos::math $pos - 3]] != "-" } {
		foreach {from to} [Diff::parseLineIntoFromTo $tt $pos] {break}
		if {$DiffmodeVars(translatePathDelimiters)} {
		    set from [Diff::translatePathDelimiters $from]
		    set to [Diff::translatePathDelimiters $to]
		}
		lappend got [list "diff" $from $to]
	    }
	    set starMatch [search -s -n -f 1 -r 1 {^\*\*\* [0-9]+,[0-9]+} $pos]
	    if {![llength $starMatch]} {
		error {Cancelled -- Diff mode could not handle this output.}
	    } else {
		set from [lindex [eval getText $starMatch] 1]
	    }
	    set dashMatch [search -s -n -f 1 -r 1 {^--- [0-9]+,[0-9]+} $pos]
	    if {![llength $dashMatch]} {
		set dashMatch [search -s -n -f 1 -r 1 {^--- [0-9]+ ---} $pos]
		if {![llength $dashMatch]} {
		    error {Cancelled -- Diff mode could not handle this output.}
		}
		set to [lindex [eval getText $dashMatch] 1]
		append to ",end"
	    } else {
		set to [lindex [eval getText $dashMatch] 1]
	    }
	    lappend got [list $from $to]
	} elseif {$t == "@@"} {
	    # cvs diff over a single file.
	    win::setInfo $DW diffsyntax usesAts
	    set line [getText [lindex $res 0] [nextLineStart [lindex $res 0]]]
	    lappend got [Diff::parseAtsIntoLine $line]
	    set res [search -s -n -f 1 -r 1 "^@@ " [lindex $res 1]]
	    if {[llength $res]} {
		set pos [lindex $res 0]
	    } else {
		break
	    }
	} else {
	    # This is where we pick up file names
# 		# We remove the special OSX case, in view of Bug 1895
# 		# The translation from HD:path:to:file to /path/to/file
# 		# is taken care of by [Diff::storeMarks] 
# 		if {$alpha::macos == 2 && [regexp {^diff} $t]} {
# 		    set t [list diff [file::FinderPathToUnix [lindex $t 1]] [file::FinderPathToUnix [lindex $t 2]]]
# 		}
	    lappend got $t
	}
    }
    if { [string match "foreign*" [win::getInfo $DW difftype]] } {
	if { $diffDir } {
	    win::setInfo $DW difftype "foreign-directories"
	}
    } 
    # now stored all diff items in the list 'got'
    if {[info exists got]} {
	if {![string match "*directories*" [win::getInfo $DW difftype]]} {
	    set f [lindex $got 0]
	    if {[string range $f 0 3] == "diff"} {
		set got [lrange $got 1 end]
	    }
	}
	Diff::storeMarks $DW $got
    }
    bringToFront $DW
}

proc Diff::parseLineIntoFromTo {tt pos} {
    if {[regexp {^==== } $tt]} {
	# probably a perforce style diff
	regexp "^==== (\[^\r\n\]*) - (\[^\r\n\]*) ===" $tt "" from to
    } else {
	set to [lindex $tt 1]
	regexp " (\[^\t\]*)" $tt "" to
	set p [pos::prevLineStart $pos]
	set fileline [getText [pos::prevLineStart $p] $p]
	regexp " (\[^\t\]*)" $fileline "" from
    }
    return [list [file::FinderPathToUnix $from] [file::FinderPathToUnix $to]]
}

proc Diff::parseAtsIntoLine {line} {
    regexp { -([0-9,]+) \+([0-9,]+) } $line "" from to
    set from [split $from ,]
    set to [split $to ,]
    set from "[lindex $from 0],[expr {[lindex $from 0] + [lindex $from 1] -1}]"
    set to "[lindex $to 0],[expr {[lindex $to 0] + [lindex $to 1] -1}]"
    return [list $from $to]
}


# Receiving a long list of diff codes (from [Diff::parseDiffWin]), separate
# file information from diff codes, using the former as top level keys in 
# the mark dict, and use the latter and second level keys.  The mark dict
# will look like this:
# 
#    "/file2" {
#      {10a11 ""} 
#      {1c1 ""}
#      {6c6 ""}
#    }
# 
# Note that there are no values yet.  The values will later be win 
# positions, but these can only be computed after the window has been
# opened.   Note that file names are only used in case of directory diffs.
# For single file diffs, the empty string is used as key.
proc Diff::storeMarks { DW diffs} {
    set markDict [dict create]
    set suff ""
    foreach m $diffs {
	if {[regexp {^diff} $m]} {
	    # Ideally, the string $m starts with "diff" if and only if we 
	    # are in a directory diff.  However, we don't take any chances:
	    if {![string match "*directories*" [win::getInfo $DW difftype]]} {
		dict set markDict $suff $m ""
		continue
	    }
	   
	    # Here $m is a string of type
	    #     diff -flags /first/path/filename /second/path/filename
	    # or
	    #     diff -flags HD:first:path:filename HD:second:path:filename
	    #     diff -flags "HD:first:path:filename" "HD:second:path:filename"
	    # (Occurs even in OSX if the diff implementation is DiffBOA.)
	    # All we need is to figure out the tail (to store in var $suff).

	    # The following is a bit hacky.  If the paths are not delimited
	    # in any way we are trying to guess the tail by applying 
	    # [file tail] to a string that contains at least two paths!  
	    # A clean approach would be preferrable.  The problem is easy
	    # to state: given a string of form
	    # 
	    #   /path/to first/diff file  /path to/second /tail/somewhere
	    # 
	    # (possibly quoted (or braced), possibly with other path delimiters)
	    # figure out what the two paths really are.  As the example shows, 
	    # this might be an impossible task without relying on [file exists]...
	    # 
	    # If the string ends with a quote (or brace), then this quote 
	    # (or brace) delimits the second path:
	    if { [string index $m end] eq {"} || [string index $m end] eq "\}" } {
		set m [lindex $m end]
	    }
	    # Otherwise (in any case) we pretend the string is only one path: 
	    # translate the second type into the first type:
	    set m [file::FinderPathToUnix $m]
	    # And then we pick everything after the last slash:
	    set suff "/[file tail $m]"
	    continue
	}
	dict set markDict $suff $m ""
    }
    win::setInfo $DW markdict $markDict
}



# This proc is called (from [Diff::View]) when an object window is opened.
# It takes the entries in the "/file1" sub dict of the mark dict, and
# computes the corresponding window positions (this is actually done by the
# auxiliary proc [Diff::parseDiffString]), and these window positions are
# then written as values.  Here is what the mark dict then looks like:
# 
#    "/file2" {
#      {10a11 {a 61 62 61 62}} 
#      {1c1 {c 0 28 0 25}}
#      {6c6 {c 38 53 35 53}}
#    }
# 
# (The four numbers are window positions: two in the left window
# and two in the right window.)
proc Diff::ensureMarkdictReady { DW {suff ""}} {
    set markDict [win::getInfo $DW markdict]
    # The $suff entry is supposed to exist at this point.
    # We need to check whether the values have been filled in or 
    # they are still all empty.  We just check any one, in a sort of 
    # non-dictish way:
    if { [lindex [dict get $markDict $suff] 1] ne "" } {
	# The spot test indicates that the $suff entry has been populated
	return
    }
    # Otherwise we now go through the necessary steps to populate the
    # $suff entry.
    
    set win1 [win1 $DW]
    set win2 [win2 $DW]
    
    # Standard case:
    set offset1 0
    set offset2 0
    
    # Redirect case.  As soon as we have got the redirect info,
    # we purge the entry (deleting the temp file).  We won't need
    # it any more, since now all records point to the original file!
    if { ![catch {temp::attributesForFile $win1} tinfo]} {
	set offset1 [lindex $tinfo 1]
	win1 $DW [lindex $tinfo 0]
	temp::purge $win1
    }
    if { ![catch {temp::attributesForFile $win2} tinfo]} {
	set offset2 [lindex $tinfo 1]
	win2 $DW [lindex $tinfo 0]
	temp::purge $win2
    }
    # From now on, the win array variables win1 and win2 
    # refer to the original windows containing the selections.
    foreach m [dict keys [dict get $markDict $suff]] {
	set scanned [Diff::parseDiffString $DW $m $offset1 $offset2]
	# Here we just check that the string has the correct format.
	# We don't use the result of this test scanning.
	if {[scan $scanned "%s %f %f %f %f" \
	  charDummy start1Dummy end1Dummy start2Dummy end2Dummy] != 5} { 
	    error "Bad diff list! '$m' scanned to '$scanned'" 
	}
	if {$scanned != ""} {
	    dict set markDict $suff $m $scanned
	}
    }
    win::setInfo $DW markdict $markDict
}


# Auxiliary proc for [Diff::ensureMarkdictReady].  
proc Diff::parseDiffString { DW text {offset1 0} {offset2 0} } {
    set win1 [win1 $DW]
    set win2 [win2 $DW]

    if {[regexp ",end" $text]} {
	set mx [lindex [pos::toRowChar -w $win2 [maxPos -w $win2]] 0]
	incr mx -1
	regsub ",end" $text ",$mx" text
    }
    
    if {![regexp {[acd]} $text char]} {
	# context sensitive
	set char "c"
	if {[scan $text "%d,%d %d,%d" one oned two twod] != 4} {
	    return
	}
    } else {
	set res [split $text $char]
	if {![scan [lindex $res 0] "%d,%d" one oned]} return
	if {![scan [lindex $res 1] "%d,%d" two twod]} return
	if {![info exists oned]} { set oned $one }
	if {![info exists twod]} { set twod $two }
    }

    # word-by-word plugin #
    if { [string match "*wordbyword*" [win::getInfo $DW difftype]] &&
      [llength [temp::attributesForFile [path1 $DW]]] == 3 } {
	return [Diff::computePositionsForWordByWord $DW $char $one $oned $two $twod]
    }
    # end of word-by-word plugin #

    # tmp file plugin #
    set one [expr {$one + $offset1}]
    set oned [expr {$oned + $offset1}]
    set two [expr {$two + $offset2}]
    set twod [expr {$twod + $offset2}]
    # end of tmp file plugin #
    
    if {[info exists win1]} {
	if {$char != "a"} {
	    set res [list $char [pos::fromRowChar -w $win1 $one 0]]
	    lappend res [pos::fromRowChar -w $win1 [expr {$oned + 1}] 0]
	} else {
	    # Can $one and $oned ever be different for an 'a'?
	    # If so, this will be Bad
	    set res [list $char [pos::fromRowChar -w $win1 [expr {$one + 1}] 0]]
	    lappend res [pos::fromRowChar -w $win1 [expr {$oned + 1}] 1]
	}
    } else {
	set res [list $char -1 -1]
    }
    
    if {[info exists win2]} {
	if {$char != "d"} {
	    lappend res [pos::fromRowChar -w $win2 $two 0]
	    lappend res [pos::fromRowChar -w $win2 [expr {$twod + 1}] 0]
	} else {
	    # Can $two and $twod ever be different for a 'd'?
	    # If so, this will be Bad
	    lappend res [pos::fromRowChar -w $win2 [expr {$two + 1}] 0]
	    lappend res [pos::fromRowChar -w $win2 [expr {$twod + 1}] 1]
	}
    } else {
	lappend res -1 -1
    }
    return $res
}

# Plugin for word-by-word comparisons
proc Diff::computePositionsForWordByWord {DW char one oned two twod} {
    if {[win::Exists [win1 $DW]]} {
	incr one -1
	incr oned -1
	set posPair [Diff::tempfileWordPosFromNumber [path1 $DW] $one $oned]
	set pos0 [lindex $posPair 0]
	set pos1 [lindex $posPair 1]
	if {$char eq "a"} {
	    # Can $one and $oned ever be different for an 'a'?
	    # If so, this will be Bad.
	    # 
	    # Special correction in the 'a' case.
	    set pos0 $pos1
	    set pos1 [pos::math -w [win1 $DW] $pos1 + 1]
	}
	set res [list $char $pos0 $pos1]
    } else {
	set res [list $char -1 -1]
    }
    
    if {[win::Exists [win2 $DW]]} {
	incr two -1
	incr twod -1
	set posPair [Diff::tempfileWordPosFromNumber [path2 $DW] $two $twod]
	set pos0 [lindex $posPair 0]
	set pos1 [lindex $posPair 1]
	if {$char eq "d"} {
	    # Can $one and $oned ever be different for a 'd'?
	    # If so, this will be Bad.
	    # 
	    # Special correction in the 'd' case.
	    set pos0 $pos1
	    set pos1 [pos::math -w [win2 $DW] $pos1 + 1]
	}
	lappend res $pos0
	lappend res $pos1
    } else {
	lappend res -1 -1
    }
    return $res
}

# Read the mark info from the mark dict in the win array and set the marks
# in the object window.  The name of the mark is the original diff code, so
# that it is easy to jump from the diff file to the corresponding lines in
# the object window. This proc is also responsible for setting the 
# "diffmarked" hookmode in the window, and to append the window to the
# "markedwins" list in the win attribute of the diffwindow.
proc Diff::mark {DW side {suff ""}} {
    append markprefix "diff" [win::getInfo $DW diffnumber]
    set markDict [win::getInfo $DW markdict]
    # First set the marks in the appropriate window:
    if { $side eq "both" && 
      [win::Exists [win1 $DW]] && [win::Exists [win2 $DW]] } {
	set win1 [win1 $DW]
	set win2 [win2 $DW]
	dict for {m positions} [dict get $markDict $suff] {
	    if {($alpha::platform eq "alpha")} {
		scan $positions "%s %d %d %d %d" char start1 end1 start2 end2
	    } else {
		scan $positions "%s %f %f %f %f" char start1 end1 start2 end2
	    }
	    set display1 [pos::prevLineStart -w $win1 $start1]
	    set display2 [pos::prevLineStart -w $win2 $start2]
	    setNamedMark -w $win1 "$markprefix-$m" $display1 $start1 $end1		
	    setNamedMark -w $win2 "$markprefix-$m" $display2 $start2 $end2
	}
    } elseif { $side eq "left" && [win::Exists [win1 $DW]] } {
	set win1 [win1 $DW]
	dict for {m positions} [dict get $markDict $suff] {
	    if {($::alpha::platform eq "alpha")} {
		scan $positions "%s %d %d" char start1 end1
	    } else {
		scan $positions "%s %f %f" char start1 end1
	    }
	    set display1 [pos::prevLineStart -w $win1 $start1]
	    setNamedMark -w $win1 "$markprefix-$m" $display1 $start1 $end1		
	}
    } elseif { $side eq "right" && [win::Exists [win2 $DW]] } {
	set win2 [win2 $DW]
	dict for {m positions} [dict get $markDict $suff] {
	    if {($alpha::platform eq "alpha")} {
		scan $positions "%s %d %d %d %d" char start1 end1 start2 end2
	    } else {
		scan $positions "%s %f %f %f %f" char start1 end1 start2 end2
	    }
	    set display2 [pos::prevLineStart -w $win2 $start2]
	    setNamedMark -w $win2 "$markprefix-$m" $display2 $start2 $end2
	}
    }
    # Then update the win attribute arrays:
    if { [info exists win1] } {
	win::adjustInfo $win1 hookmodes {lunion hookmodes diffmarked}
	win::adjustInfo $win1 diffjobs {lunion diffjobs $DW}
	win::adjustInfo $DW markedwins {lunion markedwins $win1}
    }
    if { [info exists win2] } {
	win::adjustInfo $win2 hookmodes {lunion hookmodes diffmarked}
	win::adjustInfo $win2 diffjobs {lunion diffjobs $DW}
	win::adjustInfo $DW markedwins {lunion markedwins $win2}
    }
    return
}



# This proc is called from [Diff::View] and [Diff::patch].
# 
# The optional argument f will acquire a two-element list containing the
# two files being compared, provided we are in a directory diff.  
# (In single-pair diffs, it is not needed anywhere since of course in
# that case we already know which the two files are.)
# 
# Return a string like "34,124 36,134/filename".
proc Diff::line {pos {f ""}} {
    set DW [win::Current]
    global DiffmodeVars
    
    if { [win::infoExists $DW diffsyntax] } {
	set diffSyntax [win::getInfo $DW diffsyntax]
	# This can be either "usesAts" or "usesStars", the latter being context diff
    } else {
	set diffSyntax ""
    }
    
    # The text string is just the current line:
    set text [getText [pos::lineStart $pos] [pos::lineEnd $pos]]
    if { $diffSyntax eq "usesAts" } {
	set text [Diff::parseAtsIntoLine $text]
    }
    # This is just a first approximation.  In the two special cases "usesStars" and 
    # "directories" we redefine $text, and we also figure out what the files are.
    
    if { $diffSyntax eq "usesStars" || [string match *directories* [win::getInfo $DW difftype]] } {
	if {$f != ""} {
	    upvar $f files
	}
	if { [lookAt $pos] eq "*" 
	  || ([catch {search -s -f 0 -r 1 "^(diff|==== )\[^\r\n\]*(\r|\n|\$)" $pos} res]
	  && [catch {search -s -f 0 -r 1 "^(Only in )\[^\r\n\]*(\r|\n|\$)" $pos} res]) } {
	    set p $pos
	    while 1 {
		set res [search -s -f 0 -r 1 "^\\*+(\r|\n|\$)" $p]
		set p [pos::math [lindex $res 0] - 2]
		if { [lookAt [lineStart $p]] ne " " && [lookAt $p] ne "-"} {
		    break
		}
	    }
	    set toline [getText [lineStart $p] $p]
	    if {[regexp {^==== } $toline]} {
		foreach {from to} [Diff::parseLineIntoFromTo $toline $p] {break}
	    } else {
		regexp " (.*)\t" $toline "" to
		regexp " (.*)\t" [getText [pos::prevLineStart $p] [pos::lineStart $p]] "" from
	    }
	    if {[set pr $DiffmodeVars(removeFilePrefix)] != ""} {
		regsub -all "/\./" $to "/" to
		if {[string first $pr $to] == 0} {
		    set to [string range $to [string length $pr] end]
		}
		regsub -all "/\./" $from "/" from
		if {[string first $pr $from] == 0} {
		    set from [string range $from [string length $pr] end]
		}
	    }
	    set files [list [file::ensureStandardPath [file::FinderPathToUnix $from]] \
	      [file::ensureStandardPath [file::FinderPathToUnix $to]]]
	    set starMatch [search -s -n -f 1 -r 1 {^\*\*\* [0-9]+,[0-9]+} [getPos]]
	    if {![llength $starMatch]} {
		error "Cancelled -- Diff mode could not handle this output."
	    } else {
		set tfrom [lindex [eval getText $starMatch] 1]
	    }
	    set dashMatch [search -s -n -f 1 -r 1 {^--- [0-9]+,[0-9]+} [getPos]]
	    if {![llength $dashMatch]} {
		set dashMatch [search -s -n -f 1 -r 1 {^--- [0-9]+ ---} [getPos]]
		if {![llength $dashMatch]} {
		    error "Cancelled -- Diff mode could not handle this output."
		}
		set tto [lindex [eval getText $dashMatch] 1]
		append tto ",end"
	    } else {
		set tto [lindex [eval getText $dashMatch] 1]
	    }
	    set text "$tfrom $tto"
	} else {
	    # Figure out which the two files are:
	    set files [eval getText $res]
	    set files [string trimright $files "\r\n"]
	    # This is a long string of type
	    #    diff -flags /path/to/the first file /path/to/the second file
	    # or
	    #    diff -flags HD:first:path:filename HD:second:path:filename
	    # The challenge is to parse this string and figure out what 
	    # the two files are...  
	    #
	    # We can try to see if we recognise the directory paths, in 
	    # the case of directory diff:
	    if { [string match *directories* [win::getInfo $DW difftype]] } {
		set path1 [string trimright [win::getInfo $DW path1] /]
		set path2 [string trimright [win::getInfo $DW path2] /]
		if { [regexp "diff.*($path1/.*) ($path2/.*)" $files -> file1 file2] } {
		    set files [list [file::FinderPathToUnix $file1] \
		      [file::FinderPathToUnix $file2]]
		} else {
		    # Resort to the old primitive solution, assuming there are no 
		    # spaces in the paths, or that the paths have been enclosed in
		    # quotes.  (DiffBOA uses quotes, so the following should be
		    # correct in that case.)
		    set files [list [file::FinderPathToUnix [lindex $files end-1]] \
		      [file::FinderPathToUnix [lindex $files end]]]
		}
	    }
	}
	if {$DiffmodeVars(translatePathDelimiters)} {
	    foreach ff $files {
		lappend nfiles [Diff::translatePathDelimiters $ff]
	    }
	    set files $nfiles
	}
	set f [lindex $files end]
	set suff /[file tail [win::StripCount $f]]
    }
    
    if { ![string match *directories* [win::getInfo $DW difftype]] } {
	set suff ""
    }
    
    # Finally assemble the return string:
    return ${text}${suff}
}



################################################################
# Hooks and maintenance of the win attributes
################################################################

hook::register preCloseHook Diff::closing Diff
hook::register openHook Diff::opening Diff

proc Diff::cleanUpAndResizeWindows {} {
    Diff::cleanUpAndCloseWindows 0
}

# This may eventually be superfluous with the temporary-geometry mechansism
proc Diff::cleanUpAndCloseWindows {{close 1}} {
    set DW [win::Current]
    append markprefix "diff" [win::getInfo $DW diffnumber]
    set win1 [win1 $DW]
    set win2 [win2 $DW]
    foreach w [list $win1 $win2] {
	if { [file::hasOneOpenWindow $w win] } {
	    removeAllMarks -w $win $markprefix-*
	    tempgeom::restoreGeometry $win
	    if {$close} {
		killWindow -w $win
	    } else {
		refresh -w $win
	    }
	}
    }
    bringToFront $DW
    killWindow
}

proc Diff::closing {{DW ""}} {
    if { ![string length $DW] } {
	set DW [win::Current]
    }
    # Should rather clean up according to a list of all windows opened...
    if {[win::infoExists $DW markedwins]} {
	foreach win [win::getInfo $DW markedwins] {
	    # remove the marks of the window
	    # remove the entry in the diffjobs entry of the window
	    Diff::cleanup $win $DW
	}
    }
}


# There is a (pre)closeHook, so that when the user closes a diffmarked
# window, the marks are removed, and all references to the window in
# the mother window are removed too.
# 
# 
# ------------------------------------------------------------
# important rule: the diffmarked hooktag is set if and only if
# the list diffjobs is nonempty.  Nonemptiness is precisely the
# criterion for being involved in some diffing, and we need to
# have a hook for that, so that we can clean up some parameters
# if the window is closed by the user.
# ------------------------------------------------------------
# 
# 
hook::register preCloseHook Diff::dyingWindow diffmarked
proc Diff::dyingWindow { win } {
    # Just tell each diffjob that we are gone.

    # Since this call was triggered by a hook, by the above rule it is
    # guaranteed that the diffjobs list is nonempty, and in particular
    # defined.
    foreach DW [win::getInfo $win diffjobs] {
	# Tell the mother window we are gone:
	win::adjustInfo $DW markedwins \
	  {set markedwins [lremove $markedwins [list $win]]}
	win::adjustInfo $DW killwhendone \
	  {set killwhendone [lremove $killwhendone [list $win]]}
	
	return
    }
}

# We also have to update the markdict, in case the
# marks have moved as a result of some editing, and in case
# the window is opened again in the same diffrun...
hook::register saveHook Diff::updateMarkdictFromMarks diffmarked

proc Diff::updateMarkdictFromMarks { window } {
    foreach DW [win::getInfo $window diffjobs] {
	if { $window eq [win1 $DW] } {
	    set side "left"
	} elseif { $window eq [win2 $DW] } {
	    set side "right"
	} else {
	    # This should never happen because we are very meticulous
	    # with these window relations...
	    status::msg "Can't relate this window to diff window..."
	    return
	}
	append markprefix "diff" [win::getInfo $DW diffnumber]
	set suff ""
	if { [string match "*directories*" [win::getInfo $DW difftype]] } {
	    set suff /[file tail [win::StripCount $window]]
	}
	set markDict [win::getInfo $DW markdict]
	
	dict for {m positions} [dict get $markDict $suff] {
	    # $m is a diff code like "3c3", 
	    # and $positions is a list like {c 36 51 36 37}
	    foreach {char start1 end1 start2 end2} $positions {}
	    if { $side eq "left" } {
		if {![catch {mark::getRange -w $window $markprefix-$m} range]} {
		    set start1 [lindex $range 0]
		    set end1 [lindex $range 2]
		} 
	    } elseif { $side eq "right" } {
		if {![catch {mark::getRange -w $window $markprefix-$m} range]} {
		    set start2 [lindex $range 0]
		    set end2 [lindex $range 2]
		}
	    }
	    dict set markDict $suff $m [list $char $start1 $end1 $start2 $end2]                 
	}
	win::setInfo $DW markdict $markDict
    }
}


# Need also a win change name hook
# proc winChangedNameHook {name oldName {allowModeChange 1}} {}


# This proc may be called even if the mother survives
proc Diff::cleanup { win DW } {    
    variable dontResize
    # Only remove marks belonging to the calling win...:
    append markprefix "diff" [win::getInfo $DW diffnumber]

    # We must clean up carefully before an eventual kill, because 
    # otherwise the closehook might try to reference the mother which
    # no longer exists...
    if { [win::Exists $win] } {
	removeAllMarks -w $win $markprefix-*	
	win::adjustInfo $win diffjobs \
	  {set diffjobs [lremove $diffjobs [list $DW]]}
	if { ![llength [win::getInfo $win diffjobs]] } {
	    win::freeInfo $win diffjobs
	    win::adjustInfo $win hookmodes \
	      {set hookmodes [lremove $hookmodes [list diffmarked]]}
	}
    }
    
    set kill 0
    # Read the info
    if { [lcontain [win::getInfo $DW killwhendone] $win] } {
	set kill 1
	# remove the killwindone info
	win::adjustInfo $DW killwhendone \
	  {set killwhendone [lremove $killwhendone [list $win]]}
    }
    # Remove the markedwins:
    win::adjustInfo $DW markedwins \
      {set markedwins [lremove $markedwins [list $win]]}
    
    global DiffmodeVars
    if {(![info exists dontResize] || !$dontResize) \
      && $DiffmodeVars(resizeWindowsWhenDone)} {
        tempgeom::restoreGeometry $win
    }
    if {$DiffmodeVars(killWindowsWhenDone) && $kill } {
	killWindow -w $win
    }
    return
}



################################################################
# ×××× Moving around ×××× #
################################################################

proc Diff::Up {} {
    Diff::move 0
}

proc Diff::Down {} {
    Diff::move 1
}

# This proc now follows the flag $DiffmodeVars(synchroniseMoveAndView).
# If the flag is set, [Diff::View] is called after successful movement.
proc Diff::move {dir} {
    set DW [win::Current]
    if {$dir} {
	set pos [pos::math [getPos] + 1]
    } else {
	set pos [pos::math [getPos] - 1]
    }
    
    if { [win::infoExists $DW diffsyntax] && 
      [win::getInfo $DW diffsyntax] eq "usesAts" } {
	set movePattern "^@@ \[^\n\r\]+(\r|\n|\$)"
    } else {	
	if { [string match "*directories*" [win::getInfo $DW difftype]] } {
	    set movePattern "^(\[^-= \n\r\]+|Only in \[^\r\n\]+)(\r|\n|\$)"
	} else {
	    set movePattern "^\[^-= \n\r\]+(\r|\n|\$)"
	}
    }
    
    if {[catch {search -s -f $dir -r 1 -- ${movePattern} $pos} res]} {
	beep
	status::msg "No more diffs"
	return
    }
    set pos [lindex $res 0]
    set line [getText $pos [nextLineStart $pos]]
    if {[string length [string trim $line]] < 2} {
	goto $pos
	return [Diff::move $dir]
    }
    selectText $pos [nextLineStart $pos]	
    display $pos
    status::msg ""
    refresh

    global DiffmodeVars
    if { $DiffmodeVars(synchroniseMoveAndView) } {
	Diff::View
    }
}

proc Diff::NextFile {} {
    if {![catch {Diff::changeFile 1}]} {
	Diff::move 1
    } else {
	status::msg "No more files"
    }
}

proc Diff::PrevFile {} {
    if {![catch {
	Diff::changeFile 0
	Diff::changeFile 0    
    }]} {
	Diff::move 1
    } else {
	status::msg "No more files"
    }
}

# Throws error if there are no more files.  This happens in particular
# if we are not diffing a directory.
proc Diff::changeFile {dir} {
    if {![string match "*directories*" [win::getInfo [win::Current] difftype]]
    ||	[catch {search -s -f $dir -r 1 \
		"^(diff|==== )\[^\r\n\]*(\r|\n|\$)" [selEnd]} res]} {
	error "No more files"
    }
    goto [pos::math [lindex $res 0] - 1]
}

proc Diff::Select {} {
    set DW [win::Current]
    if {[string match "*directories*" [win::getInfo $DW difftype]]} {
	set diffDir 1
    } else {
	set diffDir 0
    }
    # alertnote "Select: $diffDir"
    
    set text [getText [lineStart [getPos]] \
      [pos::math [nextLineStart [getPos]] - 1]]
    
    if {![regexp {[acd]} $text char]} return
    set res [split $text $char]
    if {![scan [lindex $res 0] "%d" one]} return
    if {![scan [lindex $res 1] "%d" two]} return
    if {$one == 1} {incr one}
    if {$two == 1} {incr two}
    
    if {$diffDir} {
	set res [search -s -f 0 -r 1 "^diff\[^\r\n\]*(\r|\n|\$)" [getPos]]
	set text [eval getText $res]
	set len [llength $text]
	set win1 [file::ensureStandardPath [file::FinderPathToUnix \
	  [lindex $text [expr {$len - 2}]]]]
	set win2 [file::ensureStandardPath [file::FinderPathToUnix \
	  [lindex $text [expr {$len - 1}]]]]
	win::setInfo $DW win1 $win1
	win::setInfo $DW win2 $win2
    }
    
    Diff::Display $DW left [expr {$one - 1}]
    Diff::Display $DW right [expr {$two - 1}]
    
    if {$diffDir} {
	bringToFront $DW
    }
}


# In normal operation (non-foregin diffs) it is better always to call
# [Diff::Display] on both left and right at the same time, and immediately
# mark the two windows.  This is what the next proc does.  Called from
# [Diff::diffWindow] when the diff job starts, and also by [Diff::View]
# whenever we navigate around.
proc Diff::DisplayAndMarkLeftAndRight { DW } {
    Diff::Display $DW left 0
    Diff::Display $DW right 0
    Diff::ensureVisible $DW
    
    set suff ""
    if { [string match "*directories*" [win::getInfo $DW difftype]] } {
	set suff /[file tail [win::StripCount [win1 $DW]]]
    }
    
    Diff::ensureMarkdictReady $DW $suff

    # If it makes sense we mark both windows at the same time, to
    # save some scanning:
    if { (![win::infoExists [win1 $DW] diffjobs] ||
      ![lcontain [win::getInfo [win1 $DW] diffjobs] $DW]) &&
      (![win::infoExists [win2 $DW] diffjobs] ||
      ![lcontain [win::getInfo [win2 $DW] diffjobs] $DW]) } {
	Diff::mark $DW both $suff
    } elseif { ![win::infoExists [win1 $DW] diffjobs] ||
      ![lcontain [win::getInfo [win1 $DW] diffjobs] $DW] } {
	Diff::mark $DW left $suff
    } elseif { ![win::infoExists [win2 $DW] diffjobs] ||
      ![lcontain [win::getInfo [win2 $DW] diffjobs] $DW] } {
	Diff::mark $DW right $suff
    }    
}


# Calling sequence:   Diff::Display $DW left 0
# 
# This proc displays either left or right window at the specified line.
# This means that it opens the file if there is not already an open window
# for the file, and it will ensure that the window has the correct 
# geometry.
proc Diff::Display {DW side {row 0}} {    
    if { $side eq "left" } {
	set name [Diff::win1 $DW]
    } elseif { $side eq "right" } {
	set name [Diff::win2 $DW]
    }
    # This $name ought to be an exact window name, (but the window might no
    # longer be open).  However, it might also be a window that has not yet
    # been opened, which means it is specified as a complete path.
    
    set geo [Diff::Geo $side]
    
    if { [win::Exists $name] } {
	set winname $name
    } else {
	# Now we think $name is a complete path (possibly with a <2>
	# decoration), but it might also be the name of a non-disk window
	# which has beed closed, cf. the last clause below.
	set filename [win::StripCount $name]
	if { ![catch {temp::attributesForFile $filename} tinfo]} {
	    # Case of a temporary file.
	    set row [expr {$row + [lindex $tinfo 1]}]
	    set winname [lindex $tinfo 0]
	    # We don't set win1 or win2 in this case, since the subsequent
	    # call to [Diff::ensureMarkdictReady] will need the name of the
	    # temp file, not the associated window.
	}  elseif { ![file::hasOneOpenWindow $filename winname] } {
	    if { [file readable $filename] } {
		# This window will be opened for Diff:
		set winname [eval openWithTemporaryGeometry [list $filename] $geo]
		# so schedule it for closing when done:
		win::adjustInfo $DW killwhendone {lunion killwhendone $winname}
		if { $side eq "left" } {
		    win::setInfo $DW win1 $winname
		} elseif { $side eq "right" } {
		    win::setInfo $DW win2 $winname
		}
	    } else {
		# This can happen if $name was a non-disk window which now no longer
		# exists.  Nothing we can do about it:
		error "Cancelled.  Window \"$name\" no longer exists."
	    }
	}
    }
    # Now we know that $winname is an open window.
    
    if {[getGeometry $winname] != $geo} {
	# This is just a resize operation:
	eval openWithTemporaryGeometry [list $winname] $geo
    }
    
    display -w $winname [pos::fromRowChar -w $winname $row 0]
    # It is sort of sad that everytime we come in here from [Diff::View] we
    # display the top of the document, because the selection is only made a
    # couple of lines later in that proc.  There ought to be a way to call
    # [Diff::Display] so that it doesn't scroll the window.
    
    # The return is sometimes important, because this proc may produce
    # a window with another name than requested:
    return $winname
}

# Assumes all three windows are open.
proc Diff::ensureVisible { DW } {
    # We assume $DW is frontmost, and for this reason there is
    # no harm is doing like this, just to enforce the assumption:
    bringToFront $DW
    
    if { [lsearch -exact [winNames -f] [win1 $DW]] < 3 &&
      [lsearch -exact [winNames -f] [win2 $DW]] < 3 } {
	# then by assumption they are in position 1 and 2
	# which is good.
	return
    } elseif { [lsearch -exact [winNames -f] [win1 $DW]] > 1 &&
      [lsearch -exact [winNames -f] [win2 $DW]] > 1 } {
	# then they are both out of top-three so just
	# arrange them all:
	bringToFront [win1 $DW]
	bringToFront [win2 $DW]
    } elseif { [lsearch -exact [winNames -f] [win1 $DW]] > 1 } {
	bringToFront [win1 $DW]
    } elseif { [lsearch -exact [winNames -f] [win2 $DW]] > 1 } {
	bringToFront [win2 $DW]
    }
    bringToFront $DW
}



proc Diff::View { {DW ""} } {
    if { ![string length $DW] } {
	set DW [win::Current]
    }
    
    set text [Diff::line [getPos] files]
    
    if { ![string length $text] } {
	# Should never happen, now that Bug 1890 has been fixed.
	alertnote "Empty $text in \"Diff::View\"" \
	  "Please report the circumstances"
	return
    }
    
    set w1 [win1 $DW]
    set w2 [win2 $DW]
    # The value of w1 and w2 may change, and in that case
    # we need to know what the old values were so that we can close
    # those old windows if necessary:
    if { [string length $w1] } {
	set old1 $w1
    }
    if { [string length $w2] } {
	set old2 $w2
    }
    
    if {[string match "*directories*" [win::getInfo $DW difftype]]} {
	# Now we are going to change w1 and w2 (and also in the DW array)...
	set w1 [lindex $files 0]
	if {![file exists $w1] && [win::infoExists $DW _leftDir]} {
	    set w1 [file join [win::getInfo $DW _leftDir] $w1]
	}
	if {![file exists $w1]} {
	    if { ![win::infoExists $DW _leftDir] &&
	    ([set res [lsearch [winNames] [file tail $w1]*]] != -1)} {
		set w1 [lindex [winNames -f] $res]
	    } else {
		# We conclude that there is no win1 !!!
		set w1 ""
	    }
	} else {
	    if {[set res [lsearch [winNames -f] "[quote::Glob $w1]*"]] != -1} {
		set w1 [lindex [winNames -f] $res]
	    }
	}
	
	set w2 [lindex $files 1]
	if {![file exists $w2]  && [win::infoExists $DW _rightDir]} {
	    set w2 [file join [win::getInfo $DW _rightDir] $w2]
	}
	if {![file exists $w2]} {
	    if { ![win::infoExists $DW _rightDir] &&
	    ([set res [lsearch [winNames] [file tail $w2]*]] != -1)} {
		set w2 [lindex [winNames -f] $res]
	    } else {
		# We conclude that there is no win2 !!!
		set w2 ""
	    }
	} else {
	    if {[set res [lsearch [winNames -f] "[quote::Glob $w2]*"]] != -1} {
		set w2 [lindex [winNames -f] $res]
	    }
	}
    }
    if {[string length $w1]} {
	set w1 [file nativename $w1]
    }
    if {[string length $w2]} {
	set w2 [file nativename $w2]
	# Can happen when the right file doesn't exist.
	if {[string length $w1] && ($w1 eq $w2)} {
	    set w2 ""
	}
    }
    # Commit the changes:
    win1 $DW $w1
    win2 $DW $w2
    
    # Check if there are old windows to get rid of.
    # If the window name hasn't changed, we don't clean up.
    if { [info exists old1] } {
	if { ![string length $w1] || ($w1 ne $old1) } {
	    # It may happen that $old1 is just a directory name!
	    # In that case we don't want to go into all that cleanup:
	    if { [win::Exists $old1] } {
		Diff::cleanup $old1 $DW
	    }
	    
	}
    }
    if { [info exists old2] } {
	if { ![string length $w2] || ($w2 ne $old2) } {
	    if { [win::Exists $old2] } {
		Diff::cleanup $old2 $DW
	    }
	}
    }
    Diff::DisplayAndMarkLeftAndRight $DW
    # This involves [Diff::Display] which may adjust the window names.
    # So we need to update:
    set w1 [win1 $DW]
    set w2 [win2 $DW]
    
    # 	if {[string length $w1]} {
    # 	    set w1 [Diff::Display $DW left 0 1]
    # 	}
    # 	if {[string length $w2]} {
    # 	    set w2 [Diff::Display $DW right 0 1]
    # 	}
    # 	Diff::ensureMarkdictReady $DW $suff
    # 	if {[string length $w1]} {
    # 	    Diff::mark $DW left $suff
    # 	    set Diff::Marked($suff) 1
    # 	}
    # 	if {[string length $w2]} {
    # 	    Diff::mark $DW right $suff
    # 	    set Diff::Marked($suff) 1
    # 	}
    #     bringToFront $DW
    
    set markprefix "diff"
    append markprefix [win::getInfo $DW diffnumber]
    regexp {([^/]+)(.*)} $text "" mark
    if {[lcontain [getNamedMarks -w $w1 -n] $markprefix-$mark]} {
	gotoMark -w $w1 $markprefix-$mark
	display -w $w1 [pos::prevLineStart -w $w1 [getPos -w $w1]]
	refresh -w $w1
    }
    if {[lcontain [getNamedMarks -w $w2 -n] $markprefix-$mark]} {
	gotoMark -w $w2 $markprefix-$mark
	display -w $w2 [pos::prevLineStart -w $w2 [getPos -w $w2]]
	refresh -w $w2
    }
    
    # We need this line because of an Alpha visual bug.
    # Alpha will often draw the text in the wrong window when we 
    # hit 'down'.  It does correct itself, but it looks silly.
    bringToFront $DW
    return
}

# These are now obsolete, since [gotoMark] is supposed to properly adjust the
# visible display and select the region.
proc Diff::displayLines {win beg end} {
    display -w $win [pos::prevLineStart -w $win $beg]
    selectText -w $win $beg $end
}

if {$alpha::platform == "alpha"} {
    # workaround buggy 'display'
    ;proc Diff::displayLines {win beg end} {
	goto -w $win [pos::prevLineStart -w $win $beg]
	insertToTop -w $win
	selectText -w $win $beg $end
    }
}


## 
 # -------------------------------------------------------------------------
 # 
 # "Diff::Sel" --
 # 
 #  This handles a name either with or without trailing '<n>' and fixes
 #  the given name if it isn't right.
 # -------------------------------------------------------------------------
 ##
proc Diff::Sel {wnamev ro row rowd side} {
    # I don't know what this proc is for, so perhaps this is wrong:
    set DW [win::Current]
    upvar 1 $wnamev wname
    if {[string match "*directories*" [win::getInfo $DW difftype]]} {
	set geo [Diff::Geo $side]
	if {[set res [lsearch [winNames -f] "[quote::Glob $wname]*"]] < 0} {
	    eval edit -c -w -g $geo [list $wname]
	    set wname [win::Current]
	} else {
	    set wname [lindex [winNames -f] $res]
	    if {[getGeometry $wname] != $geo} {
		sizeWin $wname [lindex $geo 2] [lindex $geo 3]
		moveWin $wname [lindex $geo 0] [lindex $geo 1]
	    }
	}
    }
    display -w $wname [pos::fromRowChar -w $wname $ro 0]
    selectText -w $wname [pos::fromRowChar -w $wname $row 0] \
      [pos::fromRowChar -w $wname [expr {$rowd + 1}] 0]
}


################################################################
# ×××× Patching routines ×××× #
################################################################

# Arguments: 
#    DW      name of diff window
#    w1      name of target window
#    w2      name of source window
#  left      indicates that the target windo is the old one (left-hand window)
proc Diff::patch { DW w1 w2 left } {
    if {[win::getInfo $w1 read-only]} {
	if {![dialog::yesno "That window is read-only!  Would you like to\
	  make it editable?"]} {
	    return
	}
	win::setInfo $w1 read-only 0
	# Files under version control might still be read-only ...
	if {[win::getInfo $w1 read-only]} {
	    # Try the vcs "Make Writable" menu item.
	    bringToFront $w1
	    catch {vcs::menuProc "" "makeWritable"}
	    bringToFront $DW
	}
	if {[win::getInfo $w1 read-only]} {
	    alertnote "That window is still read-only!"
	    return
	}
    }

    append markprefix "diff" [win::getInfo $DW diffnumber]

    regexp {([^/]+)(.*)} [Diff::line [getPos]] "" mark suff
    # In context diffs, we may get a non-empty $suff here, even for 
    # non-directory diffs.  But in that case by convention $suff
    # is the empty string, so we should correct for that:
    if { ![string match "*directories*" [win::getInfo $DW difftype]]} {
	set suff ""
    }
    
    if { [win::infoExists $DW diffsyntax] } {
	set diffSyntax [win::getInfo $DW diffsyntax]
	# This can be either "usesAts" or "usesStars", the latter being context diff
    } else {
	set diffSyntax ""
    }
    set markDict [win::getInfo $DW markdict]
    if { ![win::Exists $w1] } {
	alertnote "No such window"
	error "Cancelled"
    }
    # If the cursor in the diff window is not placed on a line with diff codes,
    # $code, and hence $mark, will contain pure junk.  In that case cannot
    # proceed:
    if { ![dict exists $markDict $suff $mark] } {
	error "Cancelled.  Please select a diff line before patching."
    }
    set char [lindex [dict get $markDict $suff $mark] 0]
    switch -- "${char}${left}" {
	"c1" -
	"c0" {
	    if {[win::Exists $w2]} { 
		gotoMark -w ${w2} "$markprefix-$mark"
		set text [getSelect -w ${w2}]
	    } else {
		# we assume the line is selected in the diff-win
		if {$left} {
		    set p [selEnd]
		    set ee [search -s -f 1 -r 1 "^---\[^\r\n\]*\$" $p]
		    set p [lindex $ee 1]
		    if {$diffSyntax eq "usesStars"} {
			set e [lindex [search -s -f 1 -r 1 -n {^(\*\*\*|diff)} $p] 0]
			if {$e == ""} {
			    set e [maxPos]
			} 
			set text [getText $p $e]
			if {$text == "\n" || $text == "\r"} {
			    # It was an empty context diff, which means the diff was just
			    # contained in the previous half with '-' signs.
			    set e [lindex $ee 0]
			    set p [nextLineStart [lindex [search -s -f 0 -r 1  {^\*\*\*} $e] 0]]
			    set text [getText $p $e]
			    regsub -all "\[\n\r\]- \[^\n\r\]*" $text "" text
			    regsub -all "\[\n\r\]. " $text "\r" text
			} else {
			    regsub -all "\[\n\r\]. " $text "\r" text
			}
		    } else {
			set e [search -s -f 1 -r 1 {^[^>]} $p]
			set text [getText $p [lindex $e 0]]
			regsub -all "\[\n\r\]> " $text "\r" text
		    }
		    set text [string range $text 1 end]
		} else {
		    set p [selEnd]
		    set e [search -s -f 1 -r 1 {^---} $p]
		    if {$diffSyntax eq "usesStars"} {
			set text [getText $p [lindex $e 0]]
			regsub -all "\[\n\r\]. " $text "\r" text
		    } else {
			set text [getText $p [lindex $e 0]]
			regsub -all "\[\r\n\]< " $text "\r" text
		    }
		    set text [string range $text 1 end]
		}
	    }
	    gotoMark -w $w1 "$markprefix-$mark"
	    set cur [getPos -w $w1]
	    replaceText -w $w1 $cur [selEnd -w $w1] $text
	    selectText -w $w1 $cur [pos::math -w $w1 $cur + [string length $text]]
	}
	"d1" -
	"a0" {
	    gotoMark -w $w1 "$markprefix-$mark"
	    deleteText -w $w1 [getPos -w $w1] [selEnd -w $w1]
	}
	"a1" -
	"d0" {
	    if {[win::Exists $w2]} { 
		gotoMark -w $w2 "$markprefix-$mark"
		set text [getSelect -w $w2]
	    } else {
		# we assume the line is selected in the diff-win
		if {$left} {
		    set p [selEnd]
		    set e [search -s -f 1 -r 1 "^---\[^\r\n\]*\$" $p]
		    set p [lindex $e 1]
		    if {$diffSyntax eq "usesStars"} {
			set e [lindex [search -s -f 1 -r 1 -n {^(\*\*\*|diff)} $p] 0]
			if {$e == ""} {
			    set e [maxPos]
			} 
			set text [getText $p $e]
			regsub -all "\[\n\r\]. " $text "\r" text
		    } else {
			set e [search -s -f 1 -r 1 {^[^>]} $p]
			set text [getText $p [lindex $e 0]]
			regsub -all "\[\n\r\]> " $text "\r" text
		    }
		    set text [string range $text 1 end]
		} else {
		    set p [selEnd]
		    set e [search -s -f 1 -r 1 {^---} $p]
		    set text [getText $p [lindex $e 0]]
		    regsub -all "\[\n\r\]< " $text "\r" text
		    set text [string range $text 1 end]
		}
	    }
	    gotoMark -w $w1 "$markprefix-$mark"
	    previousLine -w $w1
	    set cur [getPos -w $w1]
	    insertText -w ${w1} $text
	    selectText -w $w1 $cur [pos::math -w $w1 $cur + [string length $text]]
	}
	default {
	    error "Didn't understand the diff to patch!"
	}
	
    }
    setNamedMark -w $w1 "$markprefix-$mark" \
      [pos::prevLineStart -w $w1 [getPos -w $w1]] \
      [getPos -w $w1] [selEnd -w $w1]
    gotoMark -w $w1 $markprefix-$mark
    display -w $w1 [pos::prevLineStart -w $w1 [getPos -w $w1]]
    refresh -w $w1
    refresh -w $w2
    bringToFront $DW
}

# In the diff-window, 'c' = cut from left, replace with given lines,
# 'd' = delete from left, 'a' = add to left.
proc Diff::patchIntoLeftWindow {} {
    set DW [win::Current]
    Diff::patch $DW [win1 $DW] [win2 $DW] 1
}

proc Diff::patchIntoRightWindow {} {
    set DW [win::Current]
    Diff::patch $DW [win2 $DW] [win1 $DW] 0
}

################################################################
# ×××× Utilities ×××× #
################################################################

# proc Diff::Win {} {
#     foreach win [winNames -f] {
# 	if { [win::getMode $win] eq "Diff" } {
# 	    bringToFront $win
# 	    return
# 	}
#     }
#     beep
#     status::msg "No Diff window."
# }

proc Diff::Geo { side } {
    global tileWidth tileHeight tileTop tileLeft defWidth
    
    set margin 4
    set width [expr {($tileWidth - $margin)/2}]
    if {$width > $defWidth} {
	set width $defWidth
    }
    set height [expr {$tileHeight - 200}]
    set hor $tileLeft
    
    if { $side eq "right" } {
	incr hor [expr {$width+$margin}]
    }
    
    return [list $hor $tileTop $width $height]
}


# This is supposed to be used by things like diff, patch, which take a 
# filename generated on one platform and translate it to another 
# platform.  Useful if someone on a Mac (Classic) sends a patch to
# someone on Unix.  It used to be in file::*, but is really only
# of use for Diff mode.
proc Diff::translatePathDelimiters {path} {
    if {[file exists $path]} {
	return [file nativename $path]
    }
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    regsub -all "/" $path ":" path
	}
	"windows" {
	    if {[regexp -nocase -- {[a-z]:} $path vol]} {
		regsub -all ":" [string range $path 2 end] "/" path
		set path $vol$path
	    } else {
		regsub -all ":" $path "/" path
	    }
	}
	"unix" {
	    regsub -all ":" $path "/" path
	}
    }
    return $path
}



# If there are no open window for file $filename, return 0.
# If there is 1 open window for $filename, return 1, and put the
#    name of the window in the variable given as second argument.
# If more than one window open for $filename, raise an error.
proc file::hasOneOpenWindow {filename {winname ""}} {
    # We also allow the filename to come with a <2> decoration
    # which will be ignored anyway:
    set wins [file::hasOpenWindows [win::StripCount $filename]]
    switch [llength $wins] {
	0 {
	    return 0
	}
	1 {
	    if { $winname ne "" } {
		upvar 1 $winname win
	    }
	    set win [lindex $wins 0]
	    return 1
	}
	default {
	    error "Cancelled.  Too many open windows for file \"$filename\"."
	}
    }
}




######## Convenience procs ########
# SUBJECT TO DRASTIC CHANGES!

proc Diff::path1 { diffWin } {
    return [win::getInfo $diffWin path1]
}

proc Diff::path2 { diffWin } {
    return [win::getInfo $diffWin path2]
}

proc Diff::win1 { diffWin args } {
    # Write to the win array:
    if { [llength $args] } {
	win::setInfo $diffWin win1 [lindex $args 0]
	return
    }
    # Read from the win array:
    if { [win::infoExists $diffWin win1] } {
	set res [win::getInfo $diffWin win1] 
    } else {
	set res [win::getInfo $diffWin path1]
    }
    if { [file::hasOneOpenWindow $res win] } { 
	return $win
    } else {
	return $res
    }
}

proc Diff::win2 { diffWin args } {
    # Write to the win array:
    if { [llength $args] } {
	win::setInfo $diffWin win2 [lindex $args 0]
	return
    }
    # Read from the win array:
    if { [win::infoExists $diffWin win2] } {
	set res [win::getInfo $diffWin win2] 
    } else {
	set res [win::getInfo $diffWin path2]
    }
    if { [file::hasOneOpenWindow $res win] } { 
	return $win
    } else {
	return $res
    }
}

# ===========================================================================
# 
# .