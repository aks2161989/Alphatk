## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexFile.tcl"
 #                                   created: 08/17/1994 {09:12:06 am} 
 #                               last update: 08/13/2005 {11:14:52 AM}
 # Description: 
 # 
 # Menu item procedures that pertain to the whole file, as opposed to
 # entry formatting, validation, and searching.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexFile.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::isBibFile" --
 # 
 # Determine if the window specified by "-w <winName>" is a .bib file,
 # defaulting to the active window.  The optional "includeExample" argument
 # will allow the "* Bib Mode Example" window to qualify.  The window does 
 # not have to actually exist as a file for this procedure; calling code 
 # should figure that out if it is important.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::isBibFile {args} {
    
    win::parseArgs w {includeExample 0}

    set w [win::StripCount $w]
    if {$includeExample && [regexp {Bib Mode Example} $w]} {
	return 1
    } else {
	return [string match ".bib" [string tolower [file extension $w]]]
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Application, File Lists ×××× #
#        

proc Bib::bibtexApplication {} {

    global bibtexSig

    set name [app::launchAnyOfThese {BIBt Vbib CMTu} bibtexSig]
    switchTo [file tail $name]
}

proc Bib::bibtexHomePage {} {

    global BibmodeVars

    if {![string length $BibmodeVars(homePage)]} {
	if {[catch {dialog::getUrl} url]} {
	    error "cancel"
	} else {
	    set BibmodeVars(homePage) $url
	    prefs::modified BibmodeVars(homePage)
	}
    } 
    url::execute $BibmodeVars(homePage)
}

proc Bib::fileListProc {menuName itemName} {
    
    global Bib::TailFileConnect Bib::FileTails
    
    set itemName [string trimleft $itemName]
    
    if {$itemName == "Rebuild File List" || $itemName == "rebuildFileList"} {
        Bib::rebuildFileList
    } elseif {[lcontains Bib::FileTails $itemName]} {
	# The remaining items in the list are files to be opened.
	if {[catch {set Bib::TailFileConnect($itemName)} filePath]} {
	    if {[askyesno "Could not identify the file for \"$itemName.\"\
	      Would you like to rebuild the menu?"] == "yes"} {
		Bib::rebuildFileList
	    } else {
		error "Cancelled -- couldn't find \"$itemName\" ."
	    } 
	} elseif {$menuName == "bibtexFileList" && [getModifiers]} {
	    # Open the file in the finder.
	    file::showInFinder $filePath
	} elseif {[catch {file::openQuietly $filePath}]} {
	    error "Cancelled -- couldn't find \"$itemName\" ."
	}
    } else {
        Bib::$itemName
    } 
}

proc Bib::fileOptionsProc {menuName itemName} {
    
    global BibmodeVars Bib::PrefsInMenu2
    
    if {$menuName == "bibModeFiles" && [getModifiers]} {
        if {[lsearch -exact [set Bib::PrefsInMenu2] $itemName] != -1} {
	    set text [help::prefString $itemName "Bib"]
	    if {$BibmodeVars($itemName)} {set end "on"} else {set end "off"}
	    if {$end == "on"} {
		regsub {^.*\|\|} $text {} text
	    } else {
		regsub {\|\|.*$} $text {} text
	    }
	    append text "."
	    set msg "The '$itemName' preference for Bib mode is currently $end."
        } elseif {$itemName == "listAllBibliographies"} {
	    set text "Use this menu item to list all bibliographies\
              currently recognized by Bib mode.  This list is used\
              for creating databases and indices."
        } elseif {$itemName == "viewSearchPaths"} {
	    set text "Use this menu item to view the current search paths\
              associated with Bib mode."
        } elseif {$itemName == "addSearchPaths"} {
	    set text "Use this menu item to add additional search paths."
        } elseif {$itemName == "removeSearchPaths"} {
	    set text "Use this menu item to remove previously set search paths."
        } 
    } elseif {$itemName == "listAllBibliographies"} {
        Bib::listAllBibliographies "" 0
    } else {
        if {[lcontains Bib::PrefsInMenu2 $itemName]} {
            Bib::flagFlip $itemName
            if {$BibmodeVars($itemName)} {set end "on"} else {set end "off"}
            set msg "The \"$itemName\" preference is currently $end."
            if {$itemName == "buildFilesOnStart"} {return}
        } elseif {$itemName == "viewSearchPaths"} {
            mode::viewSearchPath ; return
        } elseif {$itemName == "addSearchPaths"} {
            mode::appendSearchPaths
        } elseif {$itemName == "removeSearchPaths"} {
            mode::removeSearchPaths
        }
        Bib::rebuildFileList
    }
    if {[info exists text]} {alertnote $text}
    if {[info exists msg]}  {status::msg $msg}
}

proc Bib::rebuildFileList {{quietly 0}} {

    Bib::listAllBibliographies
    status::msg "Rebuilding the BibTeX menu É"
    menu::buildSome "bibtexMenu"
    if {!$quietly} {
	Bib::reportFileCount
    }
    return
}

proc Bib::openAllBibFiles {} {
    
    foreach f [Bib::listAllBibliographies 1] {catch {file::openQuietly $f}}
}

proc Bib::closeAllBibFiles {} {
    
    foreach f [Bib::listAllBibliographies 1] {
        if {[lsearch [winNames -f] $f] != "-1"} {
            bringToFront [file tail $f]
            catch {killWindow}
        } 
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Default Bib File ×××× #
#
# A little too buggy to use, and of questionable utility ...
# 

# ===========================================================================
# 
# Bib::openDefaultBibFile
# 
# Open the user defined default .bib file.  If it has not been defined,
# this menu item should have been dimmed ...  The menu key binding is also
# valid in TeX mode, so long as this file has already been loaded ...  It
# would be nice if it were included in some latex<>.tcl file.
# 

if {$alpha::platform == "alpha"} {
    # This key is not defined in Alphatk.  What is 0x1f?
    Bind 0x1f <cs> {Bib::openDefaultBibFile} "TeX"
}

proc Bib::openDefaultBibFile {} {
    
    global Bib::DefaultFile
    
    if {[file exists [set Bib::DefaultFile]]} {
	file::openQuietly [set Bib::DefaultFile]
    } elseif {[dialog::yesno "The default .bib file could not be found.\
      Would you like to reset it?"]} {
	Bib::setDefaultBibFile
    } else {
	status::msg "Cancelled."
    } 
}

# ===========================================================================
# 
# Bib::setDefaultBibFile
# 
# Used in a couple of listpick dialogs to set the default value of the
# highlighted file in the list presented.  Setting this creates a new
# preference.  Note: this should only be changed using the menu item, and
# not through the mode preference dialog.
# 

proc Bib::setDefaultBibFile {{dBF ""}} {
    
    global BibmodeVars Bib::DefaultFile Bib::DefaultTail
    
    if {$dBF == ""} {
	catch {set dBF $BibmodeVars(defaultBibFile)}
	set dBF [getfile "Select the new default .bib file" $dBF]
    }
    set BibmodeVars(defaultBibFile) $dBF
    prefs::modified BibmodeVars(defaultBibFile)
    Bib::setDefaultBibFile2
    status::msg "The new default .bib file is \"... [set Bib::DefaultTail]\""
    menu::buildSome "bibModeFiles"
    return
} 

proc Bib::setDefaultBibFile2 {} {
    
    global BibmodeVars Bib::DefaultFile Bib::DefaultTail
    
    set Bib::DefaultFile $BibmodeVars(defaultBibFile)
    if {!$BibmodeVars(fullPathnames)} {
	set Bib::DefaultTail [file tail [set Bib::DefaultFile]]
    } else {
	set Bib::DefaultTail [set Bib::DefaultFile]
    } 
}

proc Bib::unsetDefaultBibFile {} {
    
    global Bib::DefaultFile Bib::DefaultTail
    
    if {[askyesno "Do you really want to unset\
      the default .bib file?"] == "yes"} {
	prefs::removeObsolete "defaultBibFile"
	set Bib::DefaultFile ""
	set Bib::DefaultTail ""
	rebuildMenu "bibModeFiles"
    } else {
	error "cancel"
    } 

}

# When the mode is first sourced, we'll set these to "" if the preference
# has not yet been created.

if {[catch {Bib::setDefaultBibFile2}]} {
    set Bib::DefaultFile ""
    set Bib::DefaultTail ""
} 

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Cite Key Lists ×××× #
# 
# Note: I realize that some of this is not so efficient ...  The check for
# duplicate cite-keys within a file is fine, as is the multiple file checks. 
# Retreiving the list of cite-keys isn't so great.  It would be better to
# somehow retrieve the info from bibIndex.  -- cbu
# 

proc Bib::citeKeysProc {menuName itemName} {
    
    global Bib::CiteKeys Bib::TailFileConnect2
    
    set fileTails ""
    if {[llength [set Bib::CiteKeys]]} {
	set fileTails [lindex [set Bib::CiteKeys] 2]
    } 
    if {$itemName == "countEntries"} {
        Bib::countEntries
    } elseif {$itemName == "findDuplicates"} {
        Bib::findDuplicates
    } elseif {$itemName == "findAllDuplicatesÉ"} {
        Bib::findAllDuplicates
    } elseif {$itemName == "listCiteKeys"} {
        Bib::listCiteKeys
    } elseif {$itemName == "createCiteKeyList"} {
        set title "Select the files to include:"
        set first [list "Include all filesÉ"]
        Bib::listAllCiteKeys "" $title $first 1
    } elseif {$itemName == "clearCiteKeyList"} {
        Bib::clearCiteKeyList
    } elseif {[lsearch $fileTails $itemName] != "-1"} {
        # This works :
        # 
        # Bib::listAllCiteKeys $itemName
        # 
        # but it's not very efficient, especially when there are a lot of
        # cite-keys listed in Bib::CiteKeys.  But we'll still give them
        # something ...
        Bib::listCiteKeys [set Bib::TailFileConnect2($itemName)]
    } else {
        Bib::$itemName
    } 
}

# ===========================================================================
# 
# Report the number of entries of each type
# 

proc Bib::countEntries {{quietly 0}} {

    Bib::BibModeMenuItem
    
    global Bib::TopPat1 Bib::TopPat2
    
    set pos [minPos]
    set pat [set Bib::TopPat1]
    set count 0
    unset -nocomplain type
    
    set lines    "\r\"[win::CurrentTail]\"\r\r"
    while {![catch {search -f 1 -r 1 -m 0 -i 0 -s $pat $pos} result]} {
        status::msg "Counting entries É [incr count]"
        set start [lindex $result 0]
        set end   [nextLineStart $start]
        set text  [getText $start $end]
        set lab ""
        if {[regexp [set Bib::TopPat2] $text match entryType]} {
            set entryType [string tolower $entryType]
            if {[catch {incr type($entryType)} num]} {
                set type($entryType) 1
            }
        }
        set pos $end
    }
    foreach name [lsort [array names type]] {
        if {$type($name) > 0} {
            append lines [format "%4.0d  %s\n" $type($name) $name]
        }
    }
    append lines "----  -----------------\n"
    append lines [format "%4.0d  %s\n" $count "Total entries"]
    if {!$quietly} {
        set t    "% -*-Bib-*- (stats)\r"
        append t $lines
        new -n {* BibTeX Statistics *} -m "Bib" -text $t
	goto [minPos]
        winReadOnly
        catch {shrinkWindow 1}
    } else {
        return [list $count $lines]
    } 
}

proc Bib::countAllEntries {{fileList ""}} {
    
    global Bib::FileTails Bib::TailFileConnect2
    
    if {$fileList == ""} {
        set title "Choose some files to count :"
        set fileList [listpick -l -p $title [set Bib::FileTails]]
    } 
    set currentTails [winNames]
    set count 0
    set t ""
    foreach fileTail $fileList {
        file::openQuietly [set Bib::TailFileConnect2([lindex $fileTail 0])]
        set result [Bib::countEntries 1]
        incr count [lindex $result 0]
        append t   [lindex $result 1]
        if {[lsearch -exact $currentTails [win::CurrentTail]] == "-1"} {killWindow} 
    }
    set t1    "% -*-Bib-*- (stats)\r"
    append t1 $t
    append t1 "\r[format "%4.0d  %s\n" $count "Total entries, all files"]"
    new -n {* BibTeX Statistics *} -m "Bib" -text $t1
    winReadOnly
    goto [minPos]
    catch {shrinkWindow 1}
}

# ===========================================================================
# 
# Report all duplicate cite keys for the current window, or across several
# files.  We save all of the cite-key information in a "Bib::CiteKeys"
# variable that can be used for subsequent duplicate cite-key queries, or
# unset by the user.  When the mode is first loaded, this variable is set
# empty.
#
    
proc Bib::findDuplicates {{compareFiles ""} {wCT ""} {quietly 0}} {
    
    global Bib::CiteKeys
    
    set currentTail [win::CurrentTail]
    if {$compareFiles == ""} {
        if {[llength [set Bib::CiteKeys]] && [askyesno \
          "Do you want to compare this file with the cite-keys\
          currently stored? (If not, that list will be deleted.)"] == "yes"} {
            set compareFiles 1
        } else {
            set compareFiles 0
        }
    } 
    if {!$compareFiles} {
        set citeKeys     ""
        set lineNumbers  ""
        set fileTails    ""
    } else {
        set citeKeys     [lindex [set Bib::CiteKeys] 0]
        set lineNumbers  [lindex [set Bib::CiteKeys] 1]
        set fileTails    [lindex [set Bib::CiteKeys] 2]
        set priorTails   [lunique $fileTails]
        if {[lsearch $priorTails $currentTail] != "-1"} {
            alertnote "The cite-keys from this window have already been\
              included in the list of citations.  If this file has since\
              changed, you should \"Clear Cite Key List\" and start fresh."
            status::msg "Cancelled."
            error "The current window has already been included in Bib::CiteKeys."
        } 
    } 
    set dupCount 0
    set count    0
    set duplicates  ""
    set citeKeyList ""
    set results [Bib::MarkFile 1]
    if {!$quietly} {
        status::msg "Checking for duplicate cite-keys É"
    }
    foreach result $results {
        set citeKey     [lindex $result 0]
        set lineNumber  [lindex $result 1]
        set fileTail    [lindex $result 2]
        incr count
        if {$quietly} {
            # We want the entire list of citeKeys
            append citeKeyList "[format {%-30s} $citeKey]"
            append citeKeyList "[format {%4d} $lineNumber]"
            append citeKeyList "    \"$currentTail\"\r"
        }
        set indexNumber [lsearch $citeKeys $citeKey]
        if {$indexNumber != "-1"} {
            set priorCiteKey [lindex $citeKeys    $indexNumber]
            set priorLine    [lindex $lineNumbers $indexNumber]
            set priorTail    [lindex $fileTails   $indexNumber]
            append duplicates "[format {%-30s} $priorCiteKey]"
            append duplicates "[format {%4d} $priorLine]"
            append duplicates "    \"$priorTail\"\r"
            append duplicates "[format {%-30s} $citeKey]"
            append duplicates "[format {%4d} $lineNumber]"
            append duplicates "    \"$currentTail\"\r\r"
            incr dupCount
        }
        # We're creating the list at the same time.
        lappend citeKeys    $citeKey
        lappend lineNumbers $lineNumber
        lappend fileTails   $currentTail

    }
    # Set these for the next round.
    set Bib::CiteKeys [list $citeKeys $lineNumbers $fileTails]
    set entryLength [llength $results]
    # If "quietly", all we want to do is return the count and the list.
    if {$quietly} {return [list $count $citeKeyList]} 
    set appendResults 0
    if {$wCT != ""} {set appendResults $wCT} 
    if {!$dupCount && $appendResults == 0} {
        status::msg "$count entries checked -- no duplicate cite-keys."
        menu::buildSome "citeKeyLists"
        return
    } 
    set duplicateWindows ""
    foreach window [winNames] {
        if {[regexp {\\* Cite\-Keys Results \\*} $window]} {
            lappend duplicateWindows $window
        } 
    }
    set duplicateWindows 
    if {$appendResults == 0 && [llength $duplicateWindows]} {
        if {[askyesno "Would you like to append these results to your\
          current Results window"] == "yes"} {
            if {[llength $duplicateWindows] != 1} {
                set appendResults [listpick -p "Please choose a window:" \
                  $duplicateWindows]
            } else {
                set appendResults [lindex $duplicateWindows 0]
            } 
        } 
    } 
    # Generate the report.
    set    t "\rDuplicate Cite-Key Results for \"[win::CurrentTail]\"\r\r"
    append t "Note: Command double-click on any line-number or cite-key\r"
    append t "      to return to its entry.\r"
    append t "_________________________________________________________\r"
    if {$compareFiles} {
        append t "\r        Files Compared: "
        foreach window [lunique $priorTails] {
            append t "\"$window\"\r                        "
        }
    } 
    append t "\r  Entries in this file:  [format {%4d} $count]\r"
    if {$compareFiles} {
        append t "         Total Entries:  [format {%4d} [llength $fileTails]]\r"
    } 
    append t "   Duplicate Cite-keys:  [format {%4d} $dupCount]\r"
    append t "_________________________________________________________\r"
    if {$dupCount} {
        append t "\rcite-keys:                   line #:  file name:\r"
        append t "----------                   -------  ----------\r\r"
        append t $duplicates
        append t "_________________________________________________________\r"
    } 
    append t "_________________________________________________________\r"
    status::msg "$dupCount duplicate cite-keys found."
    # Either create a new window, or append to an existing one.
    if {$appendResults == 0 || $appendResults == "-1"} {
         set t1 "% -*-Bib-*- (cite-keys)\r"
         append t1 $t
         new -n "* Cite-Keys Results *" -m "Bib" -text $t1
         set pos [minPos]
    } else {
        bringToFront $appendResults
        setWinInfo read-only 0
        goto [maxPos]
        set pos [getPos]
        insertText $t
    } 
    winReadOnly
    goto $pos ; insertToTop
    menu::buildSome "citeKeyLists"
    return $dupCount
}

proc Bib::findAllDuplicates {{biblist ""}} {

    global Bib::FileTails Bib::TailFileConnect Bib::CiteKeys
    
    # Get the names of current windows, which we won't close
    set currentTails [winNames]
    # Get the list of files to check.
    if {$biblist == ""} {
        set bibfiles {"Check all files É"}
        foreach f [set Bib::FileTails] {lappend bibfiles $f} 
        set title "Select the files to search for duplicates :"
        set biblist [listpick -l -L {"Check all files É"} -p $title $bibfiles]
    } 
    if {[regexp "Check all files É" $biblist]} {set biblist [set Bib::FileTails]} 
    # Now check the first one, flushing the Bib::CiteKeys variable,
    # and creating a new report.
    set firstFile [lindex $biblist 0]
    file::openQuietly [set Bib::TailFileConnect($firstFile)]
    set currentTail [win::CurrentTail]
    set results [Bib::findDuplicates 0 "-1" 0]
    if {[lsearch $currentTails $currentTail] == "-1"} {
        bringToFront $currentTail
        killWindow
    } 
    # Remove that from the list
    set biblist [lreplace $biblist 0 0]
    # The current window is now "Cite-Keys Results"
    set wCT [win::CurrentTail]
    foreach f $biblist {
        set f [lindex $biblist 0]
        file::openQuietly [set Bib::TailFileConnect($f)]
        set currentTail [win::CurrentTail]
        incr results [Bib::findDuplicates 1 $wCT 0]
        if {[lsearch $currentTails $currentTail] == "-1"} {
            bringToFront $currentTail
            killWindow
        } 
        # Remove that from the list
        set biblist [lreplace $biblist 0 0]
    } 
    goto [minPos]
    menu::buildSome "citeKeyLists"
    status::msg "$results duplicate cite-keys found."
    return
}

# ===========================================================================
# 
# List Cite Keys (formerly Index This Window)
# 
# Collect the citekeys and titles of all entries in the current window, and
# return the results in a new window.  Command double clicking will allow the
# user to jump to the original citation.  Bib::makeDatabaseOf will now format
# the results nice if given the 1 flag ...
# 

proc Bib::listCiteKeys {{fullPath ""}} {
    
    global Bib::TailFileConnect2
    
    set currentTails [winNames]
    if {$fullPath == ""} {
        set fileTail [win::Current]
    } else {
        file::openQuietly $fullPath
    }
    set currentTail [win::CurrentTail]
    set results [Bib::makeDatabaseOf $fullPath 0]
    set t    "% -*-Bib-*- (index)\r"
    append t "\rIndex for \"[win::CurrentTail]\"\r\r"
    append t "Note: This is NOT the bibIndex used for \"Quick Find Citation\"\r"
    append t "      or for TeX mode electric citation completions ...\r\r"
    append t "      Command double-click on any cite-key to return to its entry.\r"
    append t "__________________________________________________________________\r\r"
    append t $results
    new -n "* Cite-Keys for [file tail $currentTail] *" -m "Bib" -text $t
    goto [minPos]
    winReadOnly
    Bib::MarkFile
    status::msg "Entries are listed in the marks menu."
}


proc Bib::listAllCiteKeys {{fileName ""} {title ""} {first ""} {quietly 0}} {
    
    global Bib::CiteKeys Bib::FileTails Bib::TailFileConnect
    
    if {$title == ""} {set title "Select the files to search for duplicates:"}
    if {$first == ""} {set first [list "Check for duplicates in all files É"]}
    set create 0
    if {$quietly} {set create 1} 
    if {![llength [set Bib::CiteKeys]] && !$quietly} {
        alertnote "There are no current cite-keys saved.\
          Please choose some files that you want to list."
        set title "Select the files to list:"
        set first [list "List cite-keys for all files É"]
        set create 1
    }
    if {$create} {
        # Get the names of current windows, which we won't close
        set currentTails [winNames]
        set bibfiles $first
        foreach f [set Bib::FileTails] {lappend bibfiles $f} 
        set biblist [listpick -l -p $title $bibfiles]
        if {[regexp $first $biblist]} {set biblist [set Bib::FileTails]}
        set Bib::CiteKeys ""
        set t           ""
        foreach f $biblist {
            file::openQuietly [set Bib::TailFileConnect($f)]
            set currentTail [win::CurrentTail]
            set results  [Bib::findDuplicates 1 0 1]
            if {[lsearch $currentTails $currentTail] == "-1"} {
                bringToFront $currentTail
                killWindow
            } 
            set count    [lindex $results 0]
            set citeKeys [lindex $results 1]
            append t "\rCite-Key List for \"[win::CurrentTail]\"\r\r"
            append t "Note: Command double-click on any line-number or cite-key\r"
            append t "      to return to its entry.\r"
            append t "\r  Entries in this file:  [format {%4d} $count]\r"
            append t "_________________________________________________________\r\r"
            append t "cite-keys:                   line #:  file name:\r"
            append t "----------                   -------  ----------\r\r"
            append t $citeKeys
            append t "_________________________________________________________\r"
            append t "_________________________________________________________\r"
        } 
    } else {
        # We're dealing with a list that has already been created.
        set citeKeys     [lindex [set Bib::CiteKeys] 0]
        set lineNumbers  [lindex [set Bib::CiteKeys] 1]
        set fileTails    [lindex [set Bib::CiteKeys] 2]
        set t ""
        set lastfileTail ""
        set oneFileOnly  0
        # If this was called for a specific file, we only list those cite-keys.
        if {$fileName != ""} {set oneFileOnly 1} 
        for {set indexNumber 0} {$indexNumber < [llength $citeKeys]} {incr indexNumber} {
            # All we want is the list of citeKeys
            set citeKey        [lindex $citeKeys    $indexNumber]
            set lineNumber     [lindex $lineNumbers $indexNumber]
            set fileTail       [lindex $fileTails   $indexNumber]
            if {!$oneFileOnly} {set fileName $fileTail} 
            if {$fileTail != $lastfileTail && $fileTail == $fileName} {
                status::msg "Creating the cite-key list for \"$fileTail\" É"
                append t "\rCite-Key List for \"$fileTail\"\r\r"
                append t "Note: Command double-click on any line-number or cite-key\r"
                append t "      to return to its entry.\r\r"
                append t "_________________________________________________________\r\r"
                append t "cite-keys:                   line #:  file name:\r"
                append t "----------                   -------  ----------\r\r"
            } 
            if {$fileTail == $fileName} {
                append t "[format {%-30s} $citeKey]"
                append t "[format {%4d} $lineNumber]"
                append t "    \"$fileTail\"\r"
                set lastfileTail $fileTail
            } 
        }
    }
    if {!$quietly} {
        set t1 "% -*-Bib-*- (cite-keys)\r"
        append t1 $t
        new -n "* Cite-Keys List *" -m "Bib" -text $t1
	goto [minPos]
        winReadOnly
    } else {
        status::msg "The new list of citations has been created."
    } 
    menu::buildSome "citeKeyLists"
    return
}

proc Bib::clearCiteKeyList {} {
    
    global Bib::CiteKeys
    if {[llength [set Bib::CiteKeys]]} {
        set Bib::CiteKeys ""
        status::msg "The list of cite-keys has been cleared."
    } else {
        status::msg "The list of cite-keys is currently empty."
    } 
    menu::buildSome "citeKeyLists"
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Sorting, Marking  ×××× #
#
    
# ===========================================================================
# 
# Sort the file by various criteria.
# 

proc Bib::sortFileByProc {menuName itemName} {
    
    global BibmodeVars
    
    status::msg "Sorting '[win::CurrentTail]' ..."
    
    switch $itemName {
        "citeKey"               {Bib::sortByCiteKey    }
        "firstAuthor,Year"      {Bib::sortByAuthors 0 0}
        "lastAuthor,Year"       {Bib::sortByAuthors 1 0}
        "year,FirstAuthor"      {Bib::sortByAuthors 0 1}
        "year,FirstAuthor"      {Bib::sortByAuthors 1 0}
    }
    status::msg "'[win::CurrentTail]' has been sorted."
    if {$BibmodeVars(autoMark)} {markFile} 
}

# ===========================================================================
# 
# Sorting Preliminaries
# 

# ===========================================================================
# 
# Return a list of the cite-keys of all cross-referenced entries.
#

proc Bib::listCrossrefs {} {
    set matches [Bib::findEntries {crossref}]
    unset -nocomplain crossrefs
    
    status::msg "scanning for crossrefsÉ"
    foreach hit $matches {
        set top [lindex $hit 2] 
        set bottom [lindex $hit 3]
        set entry [getText $top $bottom]
        regsub -all "\[\n\r\]+" $entry { } entry
        regsub -all "\[     \]\[    \]+" $entry { } entry
        regsub {[,  ]*[\)\}][   ]*$} $entry { } entry
        if {![catch {Bib::getFldValue $entry crossref} fldval]} {
            set fldval [string tolower $fldval]
            if {[catch {incr crossref($fldval)} num]} {set crossrefs($fldval) 1}
        }
    }
    if {[catch {lsort [array names crossrefs]} res]} {set res {}}
    status::msg ""
    return $res
}

# ===========================================================================
# 
# Extract the data from the indicated field of an entry, which is passed as
# a single string.  This version tries to be completely general, allowing
# nested braces within data fields and ignoring escaped delimiters. 
# (derived from proc getField).
#

proc Bib::getFldValue {entry fldname} {

    set fldPat  "\[\t  \]*${fldname}\[\t \]*=\[\t \]*"
    set fldPat2 {,[\t ]*([^ =,]+)[\t ]*=[\t ]*}
    set slash   "\\"
    set qslash  "\\\\"
    
    set ok [regexp -indices -nocase $fldPat $entry match]
    if {$ok} {
        set pos [expr [lindex $match 1] + 1]
        set entry [string range $entry $pos end]
        
        if {[regexp -indices $fldPat2 $entry match sub1]} {
            set entry [string range $entry 0 [expr [lindex $match 0]-1]]
        } 
        return [Bib::bibFieldData $entry]
    } else {
        error "field not found"
    }
}

# ===========================================================================
# 
# Sort all of the entries in the file alphabetically by their cite-keys.
#

proc Bib::sortByCiteKey {} {
    
    global Bib::TopPat Bib::TopPat1 BibmodeVars
    
    set bibSegStr $BibmodeVars(segregateStringsDuringSort)
    set matches   [Bib::findEntries [set Bib::TopPat]]
    set crossrefs [Bib::listCrossrefs]
    set strings   [Bib::listStrings]
    
    set begEntries [maxPos]
    set endEntries [minPos]
    
    set strs {}
    set vals {}
    set refs {}
    
    foreach hit $matches {
        set beg [lindex $hit 0]
        set end [lindex $hit 1]
        set top [lindex $hit 2] 
        set bottom [lindex $hit 3]
        if {[regexp [set Bib::TopPat1] [getText $top $bottom] allofit citeKey]} {
            set citeKey [string tolower $citeKey]
            set keyExists 1
        } else {
            set citeKey "000000$beg"
            set keyExists 0
        }
        if {$keyExists && [lsearch -exact $crossrefs $citeKey] >= 0} {
            lappend refs [list $top $top $bottom]
        } elseif {$keyExists && $bibSegStr && [lsearch -exact $strings $citeKey] >= 0} {
            lappend strs [list $citeKey $top $bottom]       
        } else {
            lappend vals [list $citeKey $top $bottom]
        }
        
        if {[pos::compare $top    < $begEntries]} {set begEntries $top}
        if {[pos::compare $bottom > $endEntries]} {set endEntries $bottom}
    }
    
    if {$bibSegStr} {
        set result [concat $strs [lsort $vals] $refs]
    } else {
        set result [concat [lsort $vals] $refs]
    }
    
    if {[llength $result] > 0} {
        Bib::writeEntries $result 1 $begEntries $endEntries 1
    } else {
        status::msg "No results of cite-key sort !!??"
    }
}

# ===========================================================================
# 
# Sort all of the entries in the file alphabetically by author.
#

proc Bib::sortByAuthors {{lastAuthorFirst 0} {yearFirst 0}} {
    
    global Bib::TopPat Bib::TopPat1 BibmodeVars
    set bibSegStr $BibmodeVars(segregateStringsDuringSort)
    
    set matches   [Bib::findEntries [set Bib::TopPat]]
    set crossrefs [Bib::listCrossrefs]
    set strings   [Bib::listStrings]
    
    set vals {}
    set others {}
    set refs {}
    set strs {}
    
    set beg [maxPos]
    set end [minPos]
    
    foreach hit $matches {
        set pos [lindex $hit 1]
        set top [lindex $hit 2] 
        set bottom [lindex $hit 3]
        set entry [getText $top $bottom]
        regsub -all "\[\n\r\]+" $entry { } entry
        regsub -all "\[     \]\[    \]+" $entry { } entry
        regsub {[,  ]*[\)\}][   ]*$} $entry { } entry
        if {[regexp [set Bib::TopPat1] $entry allofit citeKey]} {
            set citeKey [string tolower $citeKey]
            set keyExists 1
        } else {
            set citeKey ""
            set keyExists 0
        }
        
        if {$keyExists && [lsearch -exact $crossrefs $citeKey] >= 0} {
            lappend refs [list $pos $top $bottom]
        } elseif {$bibSegStr && $keyExists && [lsearch -exact $strings $citeKey] >= 0} {
            lappend strs [list $citeKey $top $bottom]       
        } else {
            if {![catch {Bib::getFldValue $entry author} fldval]} {
                if {[catch {Bib::getFldValue $entry year} year]} { set year 9999 }
                lappend vals [list [Bib::authSortKey $fldval $lastAuthorFirst $year $yearFirst] $top $bottom]
            } else {
                lappend others [list $pos $top $bottom]
            }
        }
        if {[pos::compare $top    < $beg]} {set beg $top}
        if {[pos::compare $bottom > $end]} {set end $bottom}
    }
    
    if {$bibSegStr} {
        set result [concat $strs $others [lsort $vals] $refs]
    } else {
        set result [concat $others [lsort $vals] $refs]
    }
    
    if {[llength $result] > 0} {
        Bib::writeEntries $result 1 $beg $end 1
    } else {
        status::msg "No results of author sort !!??"
    }
}

# ===========================================================================
# 
# Create a sort key from an author list.  When sorting entries by author,
# performing the sort using keys should be faster than reparsing the author
# lists for every comparison (the old method :-( ).
#

proc Bib::authSortKey {authList lastAuthorFirst {year {}} {yearFirst 0}} {
    global BibmodeVars
    set pat1 {\\.\{([A-Za-z])\}}
    set pat2 {\{([^\{\}]+) ([^\{\}]+)\}}
    
    # Remove enclosing braces, quotes, or whitespace
    set auths %[string trim $authList {{}"  }]&
    # Remove TeX codes for accented characters
    regsub -all -- $pat1 $auths {\1} auths
    # Concatenate strings enclosed in braces
    while {[regsub -all $pat2 $auths {{\1\2}} auths]} {}
    # Remove braces (curly and square)
    regsub -all {[][\{\}]} $auths {} auths
    #   regsub -all {,} $auths { ,} auths
    # Replace 'and's with begin-name/end-name delimiters
    regsub -all {[  ]and[   ]} $auths { \&% } auths
    # Put last name first in name fields without commas
    regsub -all {%([^\&,]+) ([^\&, ]+) *\&} $auths {%\2,\1\&} auths
    # Remove begin-name delimiters
    regsub -all {%} $auths {} auths
    # Remove whitespace surrounding name separators
    regsub -all {[  ]*\&[   ]*} $auths {\&} auths
    # Replace whitespace separating words with shrieks 
    regsub -all {[  ,]+} $auths {!} auths
    # If desired, move last author to head of sort key
    if {$lastAuthorFirst} {
        regsub {(.*)&([^&]+)&?$} $auths {\2\&\1} auths
    }
    # If provided, sort by year (descending order) as well
    regsub {^[^0-9]*([0-9]*).*$} $year {\1} year
    if {$year != {}} {
        if {$BibmodeVars(sortByDescendingYears)} {
	    catch {set year [expr 9999-$year]}
	}
        if {$yearFirst} {
            set auths "$year&$auths"
        } else {        
            regsub {^([^&]+)(&?)} $auths "\\1\\&${year}\\2" auths
        }
    }
    
    return $auths
}

# ===========================================================================
# 
# Sort the file marks.
# 
# (These operations are also available under the "Search:NamedMarks" menu).
#

proc Bib::sortMarksProc {menuName itemName} {
    
    Bib::BibModeMenuItem
    
    if {$itemName == "alphabetically"} {
        sortMarksFile
    } elseif  {$itemName == "byPosition"} {
        orderMarks
    }
}

# ===========================================================================
# 
# Conversions
# 
# All conversion extensions / features should now name their procedures
# 
# "Bib::menuItem"
# 
# as in Bib::bibToHtml, Bib::bibToRefer etc.  and should insert themselves
# into the "bibtexConversions" menu.
#
        
# ===========================================================================
# 
# .