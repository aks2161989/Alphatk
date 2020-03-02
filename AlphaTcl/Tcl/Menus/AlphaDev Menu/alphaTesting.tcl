## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "alphaTesting.tcl"
 #                                          created: 06/27/2003 {02:16:38 PM}
 #                                      last update: 03/21/2006 {03:54:29 PM}
 # Description:
 # 
 # Provides testing procedure for Alpha(tk) and AlphaTcl.
 #
 # Copyright (c) 2003-2006  Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc alphaTesting.tcl {} {}

namespace eval alphadev::testing {
    
    # These are used in the Timing procedures.
    variable autoDisplayTimingData 0
    variable autoFlushTimingData 0
    variable lastTimedProc ""
    variable startupTimingData 1
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× AlphaTcl Testing Menu ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::testing::buildMenu" --
 # 
 # Create the menu of items available, register the 'activateHook'.  When
 # the menu is built for the menubar "AlphaDev" menu, we don't hard-wire
 # anything in here to be dimmed.  When built for the contextual menu, we
 # check to see if the current window is in AlphaTcl.  (The CM version gets
 # built each time the CM is called.)
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::testing::buildMenu {} {
    
    global alphaDevMenuBindingsmodeVars
    
    # Create the list of menu items.
    set menuList [list \
      "Run Automated Test SuiteÉ" \
      "Open Test Suite WindowÉ" \
      "Create Test Suite FileÉ" \
      "Test Suite Help" \
      "(-)" \
      "Load All MenusÉ" \
      "Load All ModesÉ" \
      "  and Open WindowÉ" \
      "  and Mark WindowÉ" \
      "  and Mark Hidden WindowÉ" \
      "(-) " \
      "Check Preference Callbacks" \
      "Remove Tcl Indices" \
      "(-)  " \
      "Review \[alpha::log\] Cache" \
      "List Sourced Files" \
      "Display Timing Data" \
      "Flush Timing Data" \
      "Time AlphaTcl ProcÉ" \
      "(-)   " \
      "Alpha Testing Help" \
      ]
    # Add key bindings.
    set arrayName "alphaDevMenuBindingsmodeVars"
    set menuList  [alphadev::addMenuBindings $menuList $arrayName]
    # Set the menu proc.
    if {!$alphaDevMenuBindingsmodeVars(activateBindingsInTclModeOnly)} {
	set menuProc {alphadev::testing::menuProc -m}
    } else {
	set menuProc {alphadev::testing::menuProc -m -M Tcl}
    }
    # Return the list of items for the menu.
    return [list build $menuList $menuProc]
}

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::testing::menuProc" --
 # 
 # Execute the menu items, redirecting as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::testing::menuProc {menuName itemName} {
    
    global HOME alpha::packageRequirementsFailed alpha::logCache
    
    switch -- [string trim $itemName] {
	"Load All Menus" {
	    set q "This menu item will load all of the menus currently\
	      registered in AlphaTcl by \[addMenu\] and \[alpha::menu\].\
	      \rAfter these menus have been sourced,\
	      a new window will display all of the new global variables\
	      that have been created by each one.\
	      \rDo you want to continue?"
	    if {![dialog::yesno -title "Load All MenusÉ" -width 400 $q]} {
	        error "cancel"
	    } 
	    # Store current global order of menus.
	    set globalMenus [global::menuArrangement]
	    set menuList [lindex [package::partition] 0]
	    set res {
Menu Loading Results

This window displays all of the global variables that were created by loading
all of the menus registered in AlphaTcl using [addMenu] and [alpha::menu].

(Menus that were loaded before "Alpha Testing > Load All Menus" was selected
will have "empty" results, since any variables that they might create were
already global.)
}
	    append res [string repeat "_" "77"] "\r\r"
	    foreach m $menuList {
		append res [format "%-20s : " $m]
		if {[lsearch -exact $alpha::packageRequirementsFailed $m] != -1} {
		    append res " not supported\n"
		    continue
		}
		if {[package::active $m]} {
		    set script "package::deactivate $m ; package::activate $m"
		} else {
		    set script "package::activate $m ; package::deactivate $m"
		}
		append res [string trim [breakIntoLines \
		  [evalAndCheckPollution $script] 80 23]] "\r"
	    }
	    set w [new -n "* Menu Loading Results *" -info $res]
	    help::colourTitle -w $w red
	    refresh -w $w
	    # Reset to the old order.
	    global::menuArrangement $globalMenus

	}
	"Load All Modes" {
	    set q "This menu item will load all of the modes currently\
	      registered in AlphaTcl by \[addMode\] and \[alpha::mode\].\
	      \rAfter these modes have been sourced,\
	      a new window will display all of the new global variables\
	      that have been created by each one.\
	      \rDo you want to continue?"
	    if {![dialog::yesno -title "Load All ModesÉ" -width 400 $q]} {
		error "cancel"
	    } 
	    set res {
Mode Loading Results

This window displays all of the global variables that were created by loading
all of the menus registered in AlphaTcl using [addMode] and [alpha::mode].

(Modes that were loaded before "Alpha Testing > Load All Modes" was selected
will have "empty" results, since any variables that they might create were
already global.)
}
	    append res [string repeat "_" "77"] "\r\r"
	    foreach m [mode::listAll] {
		append res [format "%-10s : " $m]
		if {[lsearch -exact $alpha::packageRequirementsFailed $m] != -1} {
		    append res " not supported\n"
		    continue
		}
		append res [string trim [breakIntoLines \
		  [evalAndCheckPollution [list loadAMode $m]] 80 13]] "\r"
	    }
	    set w [new -n "* Mode Loading Results *" -info $res]
	    help::colourTitle -w $w red
	    refresh -w $w
	}
	"and Open Window" {
	    set q "This menu item will load all of the modes currently\
	      registered in AlphaTcl by \[addMode\] and \[alpha::mode\],\
	      creating (and then closing) a new window for each mode.
	      \rAfter these modes have been sourced,\
	      a new window will display all of the new global variables\
	      that have been created by each one.\
	      \rDo you want to continue?"
	    if {![dialog::yesno -title "Load All ModesÉ" -width 400 $q]} {
		error "cancel"
	    } 
	    variable wait
	    set res {
Mode Loading Results -- Open New Window

This window displays all of the errors associated with creating a new window
in modes registered in AlphaTcl using [addMode] and [alpha::mode].
}
	    append res [string repeat "_" "77"] "\r\r"
	    foreach m [mode::listAll] {
		append res [format "%-10s : " $m]
		if {[lsearch -exact $alpha::packageRequirementsFailed $m] != -1} {
		    append res " not supported\n"
		    continue
		}
		loadAMode $m
		if {[catch {
		    set name [new -n "test of $m" -m $m]
		    after idle [list set ::alphadev::testing::wait 1]
		    vwait ::alphadev::testing::wait
		    killWindow
		} errorMessage]} {
		    append res $errorMessage
		}
		append res "\r"
	    }
	    set w [new -n "* Mode Loading, Open Window Results *" -info $res]
	    help::colourTitle -w $w red
	    refresh -w $w
	}
	"and Mark Hidden Window" -
	"and Mark Window" {
	    set hidden [expr {[string trim $itemName] eq "and Mark Hidden Window"}]
	    if {$hidden} {
		set viz "hidden"
	    } else {
		set viz "normal"
	    }
	    set q "This menu item will load all of the modes currently\
	      registered in AlphaTcl by \[addMode\] and \[alpha::mode\],\
	      creating, marking (and then closing) a new window for each mode.
	      \rAfter these modes have been sourced,\
	      a new window will display all of the error messages\
	      that were created by the marking procedure.\
	      \rDo you want to continue?"
	    if {![dialog::yesno -title "Load All ModesÉ" -width 400 $q]} {
		error "cancel"
	    } 
	    variable wait
	    set res {
Mode Loading Results -- Open and Mark New Window

This window displays all of the errors associated with creating and marking a
new window in modes registered in AlphaTcl using [addMode] and [alpha::mode].
}
	    append res [string repeat "_" "77"] "\r\r"
	    foreach m [mode::listAll] {
		append res [format "%-10s : " $m]
		if {[lsearch -exact $alpha::packageRequirementsFailed $m] != -1} {
		    append res " not supported\n"
		    continue
		}
		loadAMode $m
		if {[catch {
		    set name [new -n "test of $m" -m $m -visibility $viz]
		    markFile -w $name
		    after idle [list set ::alphadev::testing::wait 1]
		    vwait ::alphadev::testing::wait
		    killWindow -w $name
		} errorMessage]} {
		    append res "$errorMessage"
		}
		append res "\n"
	    }
	    set w [new -n "* Mode Loading, Mark Window Results *" -info $res]
	    help::colourTitle -w $w red
	    refresh -w $w
	}
	"Open Test Suite Window" {
	    set files [alphadev::testing::listTestSuiteFiles]
	    set f [listpick -p "Insert test text from which file?" $files]
	    set t [file::readAll [file join $HOME Developer Tests $f]]
	    set w [new -n $f -text $t]
	    setWinInfo -w $w dirty 0
	    goto [minPos -w $w]
	}
	"Create Test Suite File" {
	    set files [alphadev::testing::listTestSuiteFiles]
	    set text1 "To create a new test suite file, enter a name for it\
	      below and press the OK button.  The new file will be created\
	      in the Tcl/Developer/Tests folder.  If this new test file\
	      would be useful for other developers, please send it to a\
	      member of the \"Alpha Cabal\" to add it to the AlphaTcl CVS.\r"
	    set text2 "\rNote: Files with the \".tcl\" extension can be ordinary\
	      Tcl scripts, while those with the \".test\" extension should\
	      be designed to be used with the \"tcltest\" package.\r"
	    set fileName ""
	    while {1} {
		set dialogScript [list dialog::make -title "New Test Suite File" \
		  -addbuttons [list \
		  "Help" \
		  "Click here to close this dialog and obtain more information" \
		  "alphadev::testing::helpWindow {Test Suite Files}; \
		  set retCode 1; set retVal cancel"] \
		  [list "" \
		  [list text $text1] \
		  [list var  "File Name:" $fileName] \
		  [list text $text2] \
		  ]]
		set result [eval $dialogScript]
		if {![string length [set fileName [lindex $result 0]]]} {
		    alertnote "The new 'File Name' cannot be an empty string."
		} elseif {([lsearch $files $fileName] > -1)} {
		    alertnote "The test file \"${fileName}\" already exists."
		} else {
		    break
		}
		set text "Please try a different name for the new test file.\r"
	    }
	    set f [file join $HOME Developer Tests $fileName]
	    set t "\r# This is a file for testing ...\r"
	    file::writeAll $f $t  
	    edit -c $f
	}
	"Test Suite Help" {
	    set f [file join $HOME Developer Tests Readme-Tests]
	    if {[file exists $f]} {
		help::openDirect $f
	    } else {
		alphadev::testing::noTestSuite
	    }
	}
	"Review \[alpha::log\] Cache" {
	    if {![llength [set items [array names alpha::logCache]]]} {
	        alertnote {The [alpha::log] cache is empty.}
		return
	    }
	    append text {
Contents of [alpha::log] Cache

This window contains the history of calls made to the proc: alpha::log .
These messages are displayed in the status bar (and in any open AlphaTcl
Shell window), but are also retained in a cache for viewing later.  Some of
these messages were created during the initialization of AlphaTcl.

To use [alpha::log] in debugging, supply a channel and a string as arguments.
Typical channels are "stdout" and "stderr".  For example, you could include

	alpha::log "stdout" "current var value: $var"

to record the value of a variable created during one of your procedures.
Then select "AlphaDev > Alpha Testing > Review alpha::log Cache" after
performing the operation to review the contents.

Click here: <<unset -nocomplain alpha::logCache>> to clear the contents.
}
	    foreach item $items {
	        append text "\r\r" [string repeat "-" 80] "\r\r\"" \
		  $item "\"\r\r" [join $alpha::logCache($item) \r]
	    } 
	    set w {* [alpha::log] Cache *}
	    if {[win::Exists $w]} {
		bringToFront $w
		win::setInfo $w read-only 0
		replaceText -w $w [minPos -w $w] [maxPos -w $w] $text
		catch {removeColorEscapes}
	    } else {
		set w [new -n $w -text $text]
	    }
	    goto -w $w [minPos -w $w]
	    help::markColourAndHyper -w $w
	    catch {winReadOnly $w}
	    refresh
	}
	"List Sourced Files" {
	    alphadev::testing::listSourcedFiles
	}
	"Display Timing Data" {
	    alphadev::testing::displayTimingData
	}
	"Flush Timing Data" {
	    alphadev::testing::flushTimingData 0
	}
	"Time AlphaTcl Proc" {
	    alphadev::testing::timeAlphaTclProc
	}
	"Run Automated Test Suite" {
	    set q "This menu item will evaluate all of the \"*.test\"\
	      files in the Test Suite folder.\
	      \r(The \"Open Test Suite Window\" menu item allows you to\
	      run each of them individually.)"
	    if {![dialog::yesno -y "Run Test Suite" -n "Help" -c -- $q ]} {
		alphadev::testing::menuProc "" "Test Suite Help"
		return
	    } 
	    set script [file join $HOME Developer Tests all.tcl]
	    if {[file exists $script]} {
		uplevel \#0 [list source $script]
	    } else {
		alphadev::testing::noTestSuite
	    }
	}
	"Remove Tcl Indices" {
	    global HOME
	    set sys [file join $HOME Tcl SystemCode]
	    file delete -force [file join $sys tclIndex]
	    set subindices [glob -dir $sys -join * tclIndex]
	    if {[llength $subindices]} {
		eval [list file delete -force] $subindices
	    }
	    alertnote "Tcl indices deleted.  You should restart now."
	}
	"Alpha Testing Help" {
	    alphadev::testing::helpWindow
	}
	"Check Preference Callbacks" {
	    global prefs::script
	    set errors ""
	    foreach {v p} [array get prefs::script] {
		if {[info procs ::$p] eq ""} {
		    if {![catch {auto_load ::$p} res] && $res} {
			status::msg "Auto-loaded $p"
		    }
		}
		if {[info procs ::$p] ne ""} {
		    set len [llength [info args ::$p]]
		    if {$len == 0 || $len > 2 \
		      || ($len == 2 && [lindex $len 1] ne "args")} {
			append errors "\n$v : $p"
		    }
		}
	    }
	    if {$errors ne ""} {
		error "The following variable, script pairs will throw\
		  errors when modified:$errors"
	    } else {
	        alertnote "All currently loaded preferences are ok"
	    }
	}
    }
    return
}

proc alphadev::testing::noTestSuite {} {
    set q "The Test Suite folder has not been installed.\
      Would you like to update your AlphaTcl library from the CVS?"
    if {[askyesno $q]} {
	alphadev::cvs::menuProc "" "AlphaTcl Devel Checkout" 
    } else {
	status::msg "Cancelled."
    }
}

proc alphadev::testing::listTestSuiteFiles {} {
    
    global HOME
    
    if {[file isdir [set d [file join $HOME Developer Tests]]]} {
	return [lsort -dictionary [glob -tails -dir $d -- "*"]]
    } else {
	noTestSuite
	return -code return
    }
}

proc alphadev::testing::evalAndCheckPollution {script} {
    set globals [uplevel \#0 [list info vars]]
    catch $script
    set new_globals [uplevel \#0 [list info vars]]
    set new_items [lremove $new_globals $globals]
    return $new_items
}

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::testing::listSourcedFiles" --
 # 
 # List all currently sourced files, based on currently defined procedures
 # and "auto_index" entries as described below in the "header" section.
 # 
 # When we create the list of files, we go to a little bit of trouble of
 # group them according to their directory names, separating each by an empty
 # line.  It looks a little convoluted, but it works fairly well.
 # 
 # When called from the "AlphaDev Menu > Testing" menu item, all of the
 # AlphaDev source files will of course be included, as well as anything that
 # was required to build and insert this menu.
 # 
 # --------------------------------------------------------------------------
 # 
 # To determine which files are sourced during Alpha8/X/tk's startup, turn
 # off all global menus and features except the AlphaDev menu, restart, and
 # then call the "AlphaDev Menu > Alpha Testing > List Sourced Files" menu
 # item.  Of course, since the AlphaDev menu is still globally active the
 # activation of this menu sourced additional files, so to be more precise
 # you could add the [alphadev::testing::listSourcedFiles] procedure to
 # your "prefs.tcl" file and call it there.  Turning off _all_ menus and
 # features will make this list more meaningful for this purpose.  Don't
 # forget to include [namespace eval alphadev::testing {}] in the
 # "prefs.tcl" file!
 # 
 # One more caveat -- the proc [procs::buildList] is used here, so its source
 # file will of course be included in the list as well.  Define that in your
 # "prefs.tcl" file as well if that is an important distinction.
 # 
 # --------------------------------------------------------------------------
 # 
 # You can also use this item to determine what additional files are sourced
 # when a package is first activated -- just follow these steps:
 # 
 # (1) Turn off the feature
 # (2) Restart Alpha8/X/tk
 # (3) Create the initial list
 # (4) Turn on a package
 # (5) Create a new list
 # (6) Compare the two windows
 # 
 # Contributed by Craig Barton Upright.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::testing::listSourcedFiles {} {
    
    global auto_index alpha::application HOME PREFS
    
    watchCursor
    status::msg "Creating new window with sourced file information É"
    # Create a header for the new window.
    set header {
Sourced Files

(as of TIME)
	
This window contains the names of all files that have been loaded during this
editing session, based on the "auto_index" entry for all currently defined
procedures.  If a file was sourced "manually" using [source] but that file
did not contain any indexed procedures, it will not be listed.  Files that
are in "Smarter Source" folders are not listed, but the originals to which
they refer are included.

Select "Alpha Testing > Display Timing Data" to create a window displaying
the order in which files were sourced during ALPHA's startup sequence.

}
    regsub -- {TIME} $header [mtime [now]] header
    regsub -- {ALPHA} $header ${alpha::application} header
    append t $header
    # List all sourced files.
    set tclHint [set prefsHint [set homeHint 0]]
    set tclHomeDir [file dirname [info library]]
    set files [list]
    foreach p [procs::buildList] {
	if {[info exists auto_index($p)]} {
	    set f [lindex $auto_index($p) 1]
	} elseif {[info exists auto_index(::$p)]} {
	    set f [lindex $auto_index(::$p) 1]
	} else {
	    continue
	}
	lappend files $f
    }
    foreach f $files {
	unset -nocomplain dirAbbrev
	set fileNameSplit [file split $f]
	if {[file::pathStartsWith $f $PREFS relative]} {
	    set dirAbbrev {$PREFS/}
	    set prefsHint 1
	} elseif {[file::pathStartsWith $f $HOME relative]} {
	    set dirAbbrev {$HOME/}
	    set homeHint 1
	} elseif {[file::pathStartsWith $f $tclHomeDir relative]} {
	    set dirAbbrev {$TCL/}
	    set tclHint 1
	}
	if {[info exists dirAbbrev]} {
	    set f "${dirAbbrev}$relative"
	}
	lappend pathLengths([llength [file split $f]]) $f
    }
    # Add the hints if necessary.
    foreach type [list "prefs" "home" "tcl"] {
	if {[set ${type}Hint]} {
	    switch -- $type {
		"prefs" {append t "\$PREFS == '${PREFS}'\r"}
		"home"  {append t "\$HOME  == '${HOME}'\r"}
		"tcl"   {append t "\$TCL   == '${tclHomeDir}'\r"}
	    }
	}
    }
    append t [string repeat "_" 77] "\r"
    foreach n [lsort [array names pathLengths]] {
	foreach f [lsort -unique $pathLengths($n)] {
	    if {![info exists seenFolders([set d [file dirname $f]])]} {
		append t "\r"
		set seenFolders($d) ""
	    }
	    append t "${f}\r"
	}
    }
    # Create a new window with the information.
    set w [new -n "Sourced Files" -text $t -mode "Text" -dirty 0]
    setWinInfo -w $w read-only 1
    goto -w $w [minPos -w $w]
    help::markColourAndHyper -w $w
    win::searchAndHyperise -w $w {$HOME}  "" 0 1
    win::searchAndHyperise -w $w {$PREFS} "" 0 4
    win::searchAndHyperise -w $w {$TCL}   "" 0 5
    refresh -w $w
    status::msg ""
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::testing::helpWindow" --
 # 
 # Open a new window with information about this submenu.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::testing::helpWindow {{sectionMark ""}} {
    
    global alpha::application
    
    set title "Alpha Testing Help"
    if {[win::Exists $title]} {
	bringToFront $title
	return
    }

    set txt {
Alpha Testing Help

The "AlphaDev > Alpha Testing" submenu includes several menu items to help
AlphaTcl developers test and implement new changes.

	  	Table Of Contents

"# Loading Modes and Menus"
"# Test Suite Files"
"# Timing Data"
"# Miscellaneous Procedures"

<<floatNamedMarks>>


	  	Loading Modes and Menus

Using the "Alpha Testing > Load All Menus/Modes" menu items, you can
evaluate the activation scripts for menus/modes.  A new window will then be
opened listing all of the new global variables that were created by the
scripts.  The "Alpha Testing > Open Document All Modes" will go one step
further and create a new window for each mode.

The "Alpha Testing > List Sourced Files" will create a new window listing
all of the current files that have been sourced by ALPHA which have defined
indexed procedures.  (See the window's annotation for more information.)

	  	Test Suite Files

One of the most important steps in addressing bugs or implementing new
functionality is the proper testing of any changes.  An essential part of
development involves designing tests that can be performed by other
developers to confirm that some new behavior doesn't introduce additional
bugs.  The best way to do this systematically is to create a test file, one
that is both well-documented and used whenever a proposed change is
considered for inclusion in the AlphaTcl CVS.

The menu item "Alpha Testing > Open Test Suite Window" offers a list-pick
dialog containing the names of all files in the directory

	$HOME/Developer/Tests/

This directory is not included in the standard distribution, but is uploaded
when the 'AlphaTclDevel' module is updated from the CVS. (Click on this
hyperlink <<alphadev::cvs::helpWindow>> for more information.)

When you choose a particular test from the list-pick dialog, the contents
of that file is inserted into a new window.  Ideally, this window includes
information on how the test(s) should be performed.  If it is necessary to
perform the test on a file that actually exists, you can save this window
somewhere in your file system.  Some test file windows are in Tcl mode, and
simply require "evaluating" the contents.

The menu item "Alpha Testing > Create Test Suite Window" prompts you for a
name for a new file that will be created in the Tests folder.  If you feel
that this file would be useful for other developers, you can send an
archive of it to a member of the AlphaTcl development team that has
write-access to the CVS.

	  	Timing Data

AlphaTcl includes built-in timing capabilities, which are implemented with
the proc: alpha::recordTimingData .  When ALPHA is first launched, all of
the various AlphaTcl initialization steps are recorded in the database.
When you select "Alpha Testing > Display Timing Data" the contents of this
database are re-formatted and placed in a new "* Timing Data *" window.
This information can be used to optimize the initialization sequence.

Note that whenever a file is sourced using [source] (or is auto_loaded), a
new timing entry is automatically placed in the database.

Developers can also record other steps that take place in any procedure or
source file -- just add a line like

	alpha::recordTimingData "Starting this procedure..."

somewhere in the body of the procedure or file.  This is most useful when
timing data is recorded in pairs, so that you can tell when something
starts and is later finished.  Select "Alpha Testing > Flush Timing Data"
at any time to clear the database when it contains information that you
don't want or need anymore.  If you want to clear the data before each test
of your Tcl routine, include

	alphadev::testing::flushTimingData

at the start of the procedure or file.  If you want to automatically create
the timing data report window when the procedure has finished, include

	alphadev::testing::displayTimingData

at the end of it.  The "Alpha Testing > Time AlphaTcl Proc" menu item will
open a dialog allowing you to enter the name of a procedure to time, and
automatically place the necessary code within the proc's body for you.


	  	Miscellaneous Procedures

There are several more procedures in the "alphaTesting.tcl" file that you
might find useful, which are not available via the "AlphaDev > Alpha Testing"
menu.  They include

------------------------------------------------------------------------

proc: procs::findAllProcUsage

<<procs::findAllProcUsage>>

This will prompt you to locate a directory, and then specify a list of
procedures.  It will then scan all files in that directory to find all calls
to those procedures.  This routine is perhaps the most useful of the bunch.

------------------------------------------------------------------------

proc: procs::findObsAlphaTclProcs

<<procs::findObsAlphaTclProcs>>

This will prompt you to specify a category of obsolete commands/procedures as
well as a list of items to ignore, and then scan the AlphaTcl library for all
usage of these items.  These lists of obsolete items are been created
elsewhere by the AlphaDev Menu.

------------------------------------------------------------------------

proc: procs::findUnlistedCmds

<<procs::findUnlistedCmds>>

This will list all of the core AlphaX commands that are not documented in the
"Alpha Commands" file, as well as Tcl commands not in "Tcl 8.4 Commands".

------------------------------------------------------------------------

proc: procs::findUsageFrequency

<<procs::findUsageFrequency>>

This will prompt you to locate a directory containing a "tclIndex" file.  All
of the procedures defined in that index file are gathered, and then each file
within the chosen directory will be scanned to determine how many times each
procedure is referenced.  Yes, the usefulness of this information is somewhat
questionable.  It will take quite a while to collect the results, since each
file is scanned for each procedure.
}
    regsub -all -- {ALPHA} $txt ${alpha::application} txt
    set w [new -n $title -tabsize 4 -info $txt]
    help::markColourAndHyper -w $w
    if {($sectionMark ne "")} {
	help::goToSectionMark -w $w $sectionMark
    } 
    return
}

# ===========================================================================
# 
# ×××× AlphaTcl Timing Support ×××× #
# 
# AlphaTcl now includes functions for recording the current time (using the
# Tcl [clock] command) using [alpha::recordTimingData] as defined in the
# file "initialize.tcl".  All files sourced using [source] or through the
# auto_loading mechanisms are always automatically included in the timing
# database.  The procedures below all this information to be displayed to
# the user in a new window, and to record the time of any arbitrary action.
# 

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::testing::displayTimingData" --
 # 
 # Create a new window containing a nicely formatted list of the timing
 # data created by [alpha::recordTimingData].
 # 
 # We go to some trouble here to abbreviate HOME, PREFS, and the directory
 # for Tcl to make it easier to see what's going on.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::testing::displayTimingData {} {
    
    global alpha::application alpha::version alpha::tclversion \
      HOME PREFS tcl_platform global::features
    
    variable startupTimingData

    if {![llength [set timingData [alpha::returnTimingData]]]} {
	status::msg "The timing database is empty."
	return
    }
    watchCursor
    # Create a header for the new window.
    set header {
ALPHA Timing Data

This window contains a list of the times which have been recorded by ALPHA
using the proc: alpha::recordTimingData .  AlphaTcl developers can use this
procedure to benchmark the activation of various modes, menus and features.
Use the "AlphaDev Menu > Alpha Testing > Flush Timing Data" menu item to
flush the contents of the database, or click here:

<<alphadev::testing::flushTimingData 0>>
}
    if {$startupTimingData} {
	append header {
When ALPHA is first launched, various steps are recorded to help optimize
the AlphaTcl initialization sequence, as listed below.
}
    }
    append header {
See the "Alpha Testing > Alpha Testing Help" window for more information.
}
    append header "\r[string repeat "-" 77]\r\r"
    regsub -all "ALPHA" $header ${alpha::application} header
    append t $header
    # Add some system variable information.
    if {$startupTimingData} {
	append t "${alpha::application} ${alpha::version}\
	  ($tcl_platform(platform), $tcl_platform(os)),\
	  with Tcl [info patchlevel] and AlphaTcl ${alpha::tclversion}\r\r"
    }
    # Format the timing data.
    set tclHint    [set prefsHint [set homeHint 0]]
    set tclHomeDir [file dirname [info library]]
    set results [list]
    set t0 [lindex $timingData 0 0]
    for {set i 0} {$i < [llength $timingData]} {incr i} {
	if {([set iTime [lindex $timingData $i 0]] == $t0)} {
	    set iTime 0
	} else {
	    set iTime [expr {($iTime - $t0) / 1000.0}]
	}
	set iTime [format {%8s} [format {%.3f} $iTime]]
	set iWhat [lindex $timingData $i 1]
	# Abbreviate all HOME, PREFS and TCL file names that are sourced.
	if {[regexp -- {^Sourcing '(.+)'$} $iWhat -> fileName]} {
	    unset -nocomplain dirAbbrev
	    set fileNameSplit [file split $fileName]
	    if {[file::pathStartsWith $fileName $PREFS relative]} {
		set dirAbbrev {$PREFS }
		set prefsHint 1
	    } elseif {[file::pathStartsWith $fileName $HOME relative]} {
		set dirAbbrev {$HOME  }
		set homeHint 1
	    } elseif {[file::pathStartsWith $fileName $tclHomeDir relative]} {
		set dirAbbrev {$TCL   }
		set tclHint 1
	    }
	    if {[info exists dirAbbrev]} {
		set fileName "${dirAbbrev}$relative"
	    }
	    set iWhat "Sourcing '${fileName}'"
	}
	lappend results "$iTime seconds -- $iWhat"
    }
    # Add the hints if necessary.
    foreach type [list "prefs" "home" "tcl"] {
	if {[set ${type}Hint]} {
	    switch -- $type {
		"prefs" {append t "\$PREFS == '${PREFS}'\r"}
		"home"  {append t "\$HOME  == '${HOME}'\r"}
		"tcl"   {append t "\$TCL   == '${tclHomeDir}'\r"}
	    }
	}
    }
    append t "\r"
    append t [join $results \r]
    # Add current configuration information.
    if {$startupTimingData} {
	append t "\r\rSystem Information:\r"
	append t [global::listEnvironment]
	append t "\r\rGlobal Features:\r\r"
	append t [breakIntoLines [lsort -dictionary ${global::features}]]
    }
    append t "\r\r"
    # Create a new window with the information.
    set w [new -n "* Timing Data *" -text $t -mode "Text" -dirty 0]
    setWinInfo -w $w read-only 1
    goto -w $w [minPos -w $w]
    help::markColourAndHyper -w $w
    win::searchAndHyperise -w $w {$HOME}  "" 0 1
    win::searchAndHyperise -w $w {$PREFS} "" 0 4
    win::searchAndHyperise -w $w {$TCL}   "" 0 5
    refresh -w $w
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::testing::flushTimingData" --
 # 
 # Flush the list of timing data.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::testing::flushTimingData {{quietly 1}} {
    
    variable startupTimingData 0
    alpha::returnTimingData 1
    if {!$quietly} {
	alertnote "The contents of the timing database have been cleared."
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::testing::timeAlphaTclProc" --
 # 
 # Create a dialog offering timing options, including a "Browse..."  button
 # that will list all currently defined procedures.  Once the dialog has
 # been dismissed, the procedure's definition is placed in a new window,
 # with the necessary timing commands put in place.
 # 
 # We are emulating [procs::generate] to create the procedure's body, but
 # we require too much additional manipulation to simply call that.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::testing::timeAlphaTclProc {} {
    
    global alpha::macos
    
    variable autoDisplayTimingData
    variable autoFlushTimingData
    variable lastTimedProc
    
    # Create a dialog page.
    set intro "Enter a defined AlphaTcl procedure that you want to time.\
      After pressing OK, a new window will be created with the new proc\
      definition, including \"alphadev::testing\" timing calls.  Whenever\
      this procedure is invoked, new timing data will be collected in\
      the cache for later review.\r"
    set txt0 "AlphaTcl Proc:"
    set txt1 "Automatically pre-flush timing data"
    set txt2 "Automatically display timing data when finished"
    set dialogPage [list "" [list "text" $intro] \
      [list "var"  $txt0 $lastTimedProc] \
      [list "flag" $txt1 $autoFlushTimingData] \
      [list "flag" $txt2 $autoDisplayTimingData]]
    # Create a "Browse Procs..."  button.  We need a name, balloon help, and
    # a script to evaluate when the button is pressed.
    set buttonScript {
	if {![catch {procs::pick} newProc]} {
	    eval [list dialog::valSet $dial [list NAME] $newProc]
	} 
    }
    regsub -- {NAME} $buttonScript ",$txt0" buttonScript
    set button1 [list \
      "Browse ProcsÉ" \
      "Click this button to browse a list of defined procedures" \
      $buttonScript]
    # Present the dialog, and record the values.
    set result [dialog::make -title "AlphaTcl Proc Timing" \
      -addbuttons $button1 $dialogPage]
    set lastTimedProc         [lindex $result 0]
    set autoFlushTimingData   [lindex $result 1]
    set autoDisplayTimingData [lindex $result 2]
    # Create the new proc definition.
    if {![string length [set p $lastTimedProc]]} {
	error "Cancelled -- no procedure was entered."
    } elseif {![regexp -- {^::} $p]} {
	set p "::[string trimleft $p ":"]"
    } 
    if {[catch {info args $p}] && ![auto_load $p]} {
	error "Cancelled -- could not identify any procedure \[${p}\]"
    } elseif {($p eq "::alpha::recordTimingData")} {
	error "Cancelled -- \[${p}\] cannot be timed, you silly goose."
    }
    set txt "proc $p \{"
    foreach arg [info args $p] {
	if {[info default $p $arg v]} {
	    append txt "\{[list $arg $v]\} "
	} else {
	    append txt "$arg "
	}
    }
    set txt [string trimright $txt]
    append txt "\} \{\r\r"
    if {$autoFlushTimingData} {
	append txt "    alphadev::testing::flushTimingData\r"
    }
    append txt "    alpha::recordTimingData \"Starting  proc: $p\"\r\r"
    set procBody [string trim [info body $p]]
    set pattern  {(.*)\s(return[^\r\n]*$)}
    if {![regexp -- $pattern $procBody -> procBody returnLine]} {
	set returnLine ""
    }
    append txt "    [string trim $procBody]\r\r"
    append txt "    alpha::recordTimingData \"Finishing proc: $p\"\r"
    if {$autoDisplayTimingData} {
	append txt "    alphadev::testing::displayTimingData\r"
    }
    if {[string length $returnLine]} {
	append txt "\r    ${returnLine}\r"
    }
    append txt "\}\r\r"
    if {[set alpha::macos]} {
	regsub -all "\n" $txt "\r" txt
    }
    # Create a header for this window.
    set header {# -*-Tcl-*-
# 
# [PROC] with timing code
# 
# Evaluate this procedure by selecting "Tcl Menu > Evaluate".  The next time
# that the procedure is called, timing information will be added to the
# database.  You can place additional [alpha::recordTimingData] calls
# throughout the body of the procedure to time various stages, each one
# should include a single "note" argument.
}
    if {!$autoDisplayTimingData} {
	append header {# 
# Then select "AlphaDev Menu > Alpha Testing > Display Timing Data" to see
# the new results.
}
    }
    append header {#
# When you have finished timing the procedure, COMMAND-Double-Click here
# 
#     PROC
# 
# to open the "real" version and evaluate it to remove the timing code
# from the procedure's body.
# 
}
    regsub -all -- {PROC} $header $p header
    if {$alpha::macos} {
        regsub -all -- {COMMAND} $header {Command} header
    } else {
	regsub -all -- {COMMAND} $header {Alt} header
    }
    # Open a new window with the proc's definition.
    set title "* AlphaTcl Proc Timing *"
    set w [new -n $title -m Tcl -text "${header}\r${txt}" -dirty 0]
    goto -w $w [minPos -w $w]
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval procs {} {}

proc procs::findUnlistedCmds {{newWindow 1}} {
    
    global HOME
    
    watchCursor
    set alphaCommandsFile [file join $HOME Help "Alpha Commands"]
    set tclCommandsFile   [file join $HOME Help "Tcl 8.4 Commands.txt"]
    set nodocs   [list]
    set commands [list]
    foreach commandFile [list $alphaCommandsFile $tclCommandsFile] {
	if {![file exists $commandFile]} {
	    alertnote "Couldn't find '[file tail $commandFile]'!!"
	} elseif {[win::Exists $commandFile]} {
	    set commands [concat $commands [getNamedMarks -w $commandFile -n]]
	} else {
	    set commandFile [file rootname [file tail $commandFile]]
	    help::openFile $commandFile
	    set commands [concat $commands [getNamedMarks -n]]
	    killWindow
	}
    }
    foreach cmd [info commands] {
	if {([lsearch $commands $cmd] > -1)} {
	    # Currently in Tcl/Alpha Commands file.
	    continue
	} elseif {([procs::find $cmd] ne "")} {
	    # Known source file.
	    continue
	} elseif {[llength [info procs ::$cmd]]} {
	    # Defined as a procedure.
	    continue
	} elseif {[regexp "^__" $cmd]} {
	    # These have been secretly renamed ...
	    # should they be included or not?
	    continue
	    lappend nodocs $cmd
	} else {
	    lappend nodocs $cmd
	}
    }
    set nodocs [join [lsort -dictionary $nodocs] \r]
    if {![llength $nodocs]} {
	status::msg "No undocumented commands found!"
	return "No undocumented commands found!"
    } elseif {!$newWindow} {
	return $nodocs
    } else {
	set    results "# These commands are not listed in any help file,\r"
	append results "# and their source file could not be found:\r\r"
	append results $nodocs
	new -n "Unlisted Commands" -m Tcl -info $results
    }
    return
}

proc procs::findUsageFrequency {{dir ""}} {
    
    global HOME
    
    if {($dir eq "")} {
	set dir [get_directory -p "Choose a directory:"]
    } elseif {![file isdir $dir]} {
	set dir [file join $HOME Tcl $dir]
    }
    set tiFile [file join $dir tclIndex]
    if {![file isfile $tiFile]} {
	alertnote "Could not find the tclIndex in the directory '$dir'"
	return
    }
    watchCursor
    source $tiFile
    # 'auto_index' is now a local array.
    foreach p [array names auto_index] {
	if {[llength $auto_index($p)] > 1} {
	    lappend files [lindex $auto_index($p) 1]
	}
	lappend procs $p
    }
    set f [llength [set files [lunique $files]]]
    set l [llength [set procs [lunique $procs]]]
    set msg "This might take a while -- $l procs in $f files.  Continue?"
    if {![askyesno $msg]} {
	status::msg "Cancelled."
	return
    }
    foreach p [lsort -dictionary $procs] {
	regsub {^::} $p {} p
	set ptail [namespace tail $p]
	if {($p ne $ptail)} {
	    set reg "^.*\\m(:*${p}|${ptail})\\M.*$"
	} else {
	    set reg "^.*\\m:*${p}\\M.*$"
	}
	set cid [scancontext create]
	set count($p) 0
	status::msg "Counting proc usage, $l left -- $p"
	scanmatch $cid $reg "incr count($p)"
	foreach f $files {
	    if {![catch {set fid [alphaOpen $f "r"]}]} {
		scanfile $cid $fid
		close $fid
	    }
	}
	scancontext delete $cid
	incr l -1
    }
    append results "# Procedure usage in the directory:\r#\r# $dir\r#\r"
    append results "# (This includes the proc definitions as well...)\r#\r\r"
    foreach item [lsort -dictionary [array names count]] {
	append results "$item -- $count($item)\r"
    }
    new -n "* Proc Count *" -m Tcl -info $results
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "procs::findObsAlphaTclProcs"  --
 # 
 # Author: Craig Barton Upright
 # 
 # Search an AlphaTcl directory or file for usage of obsolete commands and
 # procedures.  These lists of commands/procs are defined in the AlphaDev
 # menu.  Results are displayed in a browser window.  The <path> arg can be
 # absolute, a list of folder/file names relative to $HOME, or empty.  The
 # args for <procs> and <ignoreProcs> should valid Tcl lists or empty.  This
 # will likely return several false positives, but is reasonably useful.
 # 
 # Examples:
 # 
 # (1) ÇAlpha 8.0b5È procs::findObsAlphaTclProcs
 # 
 # This is the basic usage with no arguments.
 # 
 # Presents a listpick dialog asking if you want to search for obsolete
 # commands, procs, or both.  You will also be asked if there are any
 # commands that you'd like to ignore.  You can optionally enter a list of
 # commands to be searched.  The entire AlphaTcl library (files found in the
 # hierarchy of [file join $HOME Tcl]) is searched.
 # 
 # (2) ÇAlpha 8.0b5È procs::findObsAlphaTclProcs "" "" [list message mkdir]
 # 
 # Same as (1), but the strings "message" and "mkdir" will be ignored.
 # 
 # (3) ÇAlpha 8.0b5È procs::findObsAlphaTclProcs {Modes}
 # 
 # Same as (1), but only files in the [file join $HOME Tcl Modes] hierarchy
 # will be searched.
 # 
 # (4) ÇAlpha 8.0b5È procs::findObsAlphaTclProcs {Menus {WWW Menu}}
 # 
 # Same as (1), but only files in the [file join $HOME Tcl Menus "WWW Menu"]
 # hierarchy will be searched.
 # 
 # (5) ÇAlpha 8.0b5È procs::findObsAlphaTclProcs {Modes shellMode.tcl}
 # 
 # Same as (1), but only the "shellMode.tcl" file will be searched.
 # 
 # (6) ÇAlpha 8.0b5È procs::findObsAlphaTclProcs {Modes} [list addUserLine message]
 # 
 # Same as (3), but only the strings 'addUserLine' and 'message' will be
 # searched (no listpick dialogs are presented).
 # 
 # (7) ÇAlpha 8.0b5È procs::findObsAlphaTclProcs "askDir"
 # 
 # Same as (1), but you're first queried for a directory to use.  If the path
 # argument is "askFile", you're queried for a file.
 # 
 # --------------------------------------------------------------------------
 ## 

proc procs::findObsAlphaTclProcs {{path ""} {procs ""} {ignoreProcs ""}} {
    
    global HOME alphaObsCommands alphaObsProcs
    
    # Make sure that we have a valid path.  If the path is absolute (and
    # exists) then we'll just use it.
    if {($path eq "askDir")} {
	# Ask for a directory path.
	set path [get_directory -p "Choose a directory:"]
    } elseif {($path eq "askFile")} {
	# Ask for a file path.
	set path [findFile]
    } elseif {($path eq "window")} {
	set path [win::Current]
    } elseif {($path eq "")} {
	# Use $HOME/Tcl by default.
	set path [file join $HOME Tcl]
    } elseif {![file exists $path]} {
	# Assume that the path is a list of folder/file names, the concation
	# of which is relative to $HOME.
	set path [eval [list file join $HOME Tcl] $path]
    }
    if {![file exists $path]} {
	set validPath [file join $HOME Tcl]
	error "<path> should be an absolute path, or relative to '$validPath'"
    }
    # Offer to use obsolete Alpha commands or AlphaTcl procs if no list is
    # initially supplied.
    if {![llength $procs]} {
	set options [list \
	  "All Obsolete Alpha Commands" \
	  "All Obsolete AlphaTcl Procs" \
	  "Both Obsolete Commands and Procs" \
	  "Enter ProcsÉ" ]
	set procsOptions [listpick -p "Choose a category:" $options]
	switch -- $procsOptions {
	    "All Obsolete Alpha Commands" {
		set procs [lsort -dictionary $alphaObsCommands]
	    }
	    "All Obsolete AlphaTcl Procs" {
		set procs [lsort -dictionary $alphaObsProcs]
	    }
	    "Both Obsolete Commands and Procs" {
		set procs [lsort -dictionary [concat $alphaObsCommands $alphaObsProcs]]
	    }
	    "Enter ProcsÉ" {
		set ignoreProcs [list]
	    }
	}
	# If choosing obsolete Alpha commands or AlphaTcl procs, offer the
	# option to ignore any of them.
	if {[llength $procs] && ![llength $ignoreProcs]} {
	    set p "Ignore any procs/commands?"
	    set ignore [list "Don't ignore any procs"]
	    set ignoreList [concat $ignore $procs]
	    if {([set ignoreProcs [listpick -p $p -l $ignoreList]] eq $ignore)} {
		set ignoreProcs [list]
	    }
	}
    }
    procs::findAllProcUsage $path $procs $ignoreProcs
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "procs::findAllProcUsage"  --
 # 
 # Author: Craig Barton Upright
 # 
 # Search a directory or file for usage of commands and procedures.  If no
 # path is supplied user is queried to locate a directory.  Results are
 # displayed in a browser window.  We take some care here to ignore strings
 # that appear in comments, or strings that are obviously not calling procs.
 # 
 # --------------------------------------------------------------------------
 ## 

proc procs::findAllProcUsage {{path ""} {procs ""} {ignoreProcs ""}} {
    
    global browse::separator
    
    # Make sure that we have a valid path to use.
    if {($path eq "")} {
	set path [get_directory -p "Choose a directory"]
    } elseif {[file isfile $path]} {
	set files [list $path]
    } elseif {![file exists $path]} {
	error "path doesn't exist: $path"
    }
    if {![info exists files]} {
	watchCursor
	status::msg "Creating the list of files to searchÉ"
	set files [lsort -dictionary [file::recurse $path]]
	status::msg "Creating the list of files to searchÉ complete.\
	  ([llength $files] total files to\
	  search[expr {($files > 1000) ? " !!" : ""}])"
    }
    # Make sure that we have some files to search.
    if {![llength $files]} {
	alertnote "No files found to search."
	return
    }
    # Make sure that we have a valid list of procedures.
    if {![llength $procs]} {
	set procs [getline "List procedures to search for:" ""]
	set procs [lrange $procs 0 end]
    }
    # Refine the list of procedures we're going to search for.
    set procList [list]
    foreach procedure [lunique $procs] {
	if {([lsearch $ignoreProcs $procedure] >= 0)} {
	    continue
	}
	lappend procList [quote::Regfind $procedure]
    }
    if {![llength $procList]} {
	status::msg "No procedures to search for."
	return
    }
    # Create the seach pattern.  We ignore comments (hopefully).  We're only
    # looking for calls to procedures, so there should either be some form of
    # indentation ...
    append pattern "^(\[\t \]+|"
    # ...  or at least some character immediately preceding the pattern which
    # suggests that it is not embedded in some longer string which is valid
    # (such as 'map' in 'smaps' or '$map' or 'map.thing' or 'namespace::map'
    # or 'arrayName(map)'...)  Strings touching double quotes are ignored.
    append pattern "\[^\r\n\#\]*\[^-a-zA-Z0-9.:_\$'\(\)|\"\#\r\n]+)"
    append pattern "(::)?([join $procList "|"])"
    append pattern "(\[^-a-zA-Z0-9.:_'\(\)\s|\"]|$)"
    # Search all files for the procedures.  We're likely to create a few
    # false positives here.
    watchCursor
    set results ""
    set total [llength $files]
    set count 0
    foreach f $files {
	status::msg "Searching É ([incr count] of $total files): [file tail $f]"
	if {[file extension $f] != ".tcl"} {
	    continue
	}
	if {[set result [grep $pattern $f]] != ""} {
	    append results $result
	}
    }
    # Did we find anything?
    if {($results eq "")} {
	alertnote "No calls to these procedures were found in any .tcl files."
	return
    }
    # Open a browser window with the results.
    append txt "-*-Brws-*-\r\rUse the arrows keys to navigate, " \
      "\"return\" to go to a match.\r" \
      "(Note that there might be some false positives listed.)\r"\
      $browse::separator "\r\r" $results
    set w [grepsToWindow "* Proc Search Results *" $txt]
    # Now add some color.
    win::searchAndHyperise -w $w [join $procList "|"] "" 1 5
    refresh -w $w
    return
}

# ===========================================================================
# 
# .