## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexSearch.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 08/13/2005 {02:08:17 PM}
 # Description: 
 # 
 # Menu item procedures that pertain to the searching the whole window, or a
 # set of bibliography files.  Also includes support for TeX mode citation
 # completions; see [Bib::_FindAllEntries] below.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexSearch.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {
    
    # These are used for the searching dialogs.
    variable lastSearchField
    variable lastSearchString
    if {![info exists lastSearchField]} {
        set lastSearchField "author"
    }
    if {![info exists lastSearchString]} {
        set lastSearchString ""
    }
    prefs::modified lastSearchField lastSearchString
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Searching ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::searchEntries" --
 # 
 # Find all entries that match a given regular expression and copy them to a
 # new buffer.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::searchEntries {{pattern ""} {wCT ""}} {
    
    Bib::BibModeMenuItem
    
    variable lastSearchString
    
    while {($pattern eq "")} {
	# Set the text / regexp to search.
	set p "Enter alpha-numeric text or a Regular Expression to search:"
	set pattern [prompt $p $lastSearchString]
	if {($pattern eq "")} {
	    alertnote "The search string cannot be empty!"
	} else {
	    set lastSearchString $pattern
	    break
	}
    }
    set reg ^.*$pattern.*$
    # Find any matches.
    set matches [Bib::findEntries $pattern]
    if {[llength $matches] > 0} {
	# "wCT" means that this was called from a "Search All Bib Files"
	# search, and that we want to either report that there were matches 
	# (if "wCT" == "-1") or append the results to $wCT.
	if {($wCT == "-1")} {
	    return 1
	}
	Bib::writeEntries $matches 0 [minPos] -1 0 $wCT "all fields" \
	  $pattern [llength $matches]
    } else {
	status::msg "No matching entries were found"
	return 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::searchFields" --
 # 
 # Find all fields in which the indicated text matches a given regular
 # expression and copy them to a new buffer.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::searchFields {{field ""} {pattern ""} {wCT ""}} {
    
    Bib::BibModeMenuItem
    
    variable Fields
    variable lastSearchField
    variable lastSearchString
    
    while {($field eq "")} {
	# Set the field value to search.
	set fieldList [lsort [concat {"all fields"} "citeKey" $Fields]]
	set p "Select field type to search:"
	set field [eval [list prompt $p $lastSearchField "Fields"] $fieldList]
	if {($field eq "")} {
	    alertnote "No field was entered!"
	} elseif {([lsearch $fieldList $field]== "-1")} {
	    alertnote "Try again -- \"$field\" is not a valid field."
	} else {
	    set lastSearchField $field
	    break
	}
    }
    while {($pattern eq "")} {
	# Set the text / regexp to search.
	set p "Enter alpha-numeric text or a Regular Expression to search:"
	set pattern [prompt $p $lastSearchString]
	if {($pattern eq "")} {
	    alertnote "The search string cannot be empty!"
	} else {
	    set lastSearchString $pattern
	    break
	}
    }
    if {($field eq "all fields")} {
	# We'll redirect this.
	return [Bib::searchEntries $pattern $wCT]
    }
    set reg ^.*$pattern.*$
    # Find any matches.
    set matches [Bib::findEntries $pattern]
    if {![llength $matches]} {
	status::msg "No matches were found"
	return "No matches were found"
    }
    set vals [list]
    foreach hit $matches {
	set pos [lindex $hit 1]
	set top [lindex $hit 2]
	set bottom [lindex $hit 3]
	while {[set failure [expr {[Bib::getFldName $pos $top] ne $field}]]} {
	    set match [search -n -s -f 1 -r 1 -i 1 -l $bottom -- $pattern $pos]
	    if {![llength $match]} {
	        break
	    }
	    set pos [lindex $match 1]
	}
	if {!$failure} {
	    lappend vals [list $top $bottom]
	}
    }
    if {($wCT eq "-2")} {
	# wCT eq "-2" means that this was called from control-command
	# double click on a citeKey to check for duplicate citeKeys in
	# the current file.
	if {([llength $vals] == 1) && ($field eq "citeKey")} {
	    status::msg "No duplicate cite-keys for \"$pattern\" were found."
	    return 0
	} else {
	    set wCT ""
	}
    }
    if {[llength $vals] > 0} {
	# "wCT" means that this was called from a "Search All Bib Files"
	# search, and that we want to either report that there were matches 
	# (if "wCT" eq "-1") or append the results to $wCT.
	if {($wCT eq "-1")} {
	    return 1
	}
	Bib::writeEntries $vals 0 [minPos] -1 0 $wCT $field \
	  $pattern [llength $vals]
	return 1
    } else {
	status::msg "No matches were found."
	return 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::searchAllBibFiles" --
 # 
 # Prompt the user for a citation to search for in the list returned by
 # [Bib::listAllBibliographies].  Also called by [Bib::noEntryExists].  Can
 # also handle regular expressions -- if citations are found in multiple
 # files, the user is given the option to view them all in a browser window.
 # 
 # Results of the search are sent (with the cite-key) to [Bib::searchFields].
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::searchAllBibFiles {{pattern ""} {field ""} {bibfiles ""} {quietly 0}} {
    
    variable Fields
    variable lastSearchField
    variable lastSearchString
    variable TopPat

    while {($field eq "")} {
	# Set the field value to search.
	set fieldList [lsort [concat {"all fields"} "citeKey" $Fields]]
	if {[catch {eval prompt {{Select field type to search:}} \
	  $lastSearchField {Fields} $fieldList} field]} {
	    return
	}
	if {($field eq "")} {
	    alertnote "No field was entered!"
	} elseif {([lsearch $fieldList $field]== "-1")} {
	    alertnote "Try again -- \"$field\" is not a valid field."
	} else {
	    set lastSearchField $field
	    break
	}
    }
    while {($pattern eq "")} {
	# Set the text / regexp to search.
	set p "Enter alpha-numeric text or a Regular Expression to search:"
	set pattern [prompt $p $lastSearchString]
	if {($pattern eq "")} {
	    alertnote "The search string cannot be empty!"
	} else {
	    set lastSearchString $pattern
	    break
	}
    }
    if {![llength $bibfiles]} {
	# Get the list of all bibliographies.  List will be full pathnames.
	set bibfiles [Bib::listAllBibliographies]
    }
    if {![llength $bibfiles]} {
	dialog::alert "Cancelled -- there are no bibliography files to search.\
	  Perhaps the Bib mode \"Use ... Path\" preferences need to be checked."
	error "There are no bibliography files to search."
    }
    # Now do a grep search in all of these files.  If the field is
    # "citeKey", everything is easy.  Otherwise we're going to get a lot of
    # false positives.
    if {($field eq "citeKey")} {
	append searchPat $TopPat {[\t ]*.*} "\(" $pattern "\).*,"
    } else {
	append searchPat "^.*\(" $pattern "\).*$"
    }
    set biblist [list]
    set results ""
    watchCursor
    foreach f $bibfiles {
	if {([set result [grep $searchPat $f]] ne "")} {
	    lappend biblist $f
	    append  results $result
	}
    }
    if {![llength $biblist]} {
	set biblist "-1"
    }
    status::msg ""
    # Search is over.  Now what to do?
    if {$quietly} {
	return [list $pattern $field $biblist $results]
    } else {
	# Otherwise, pass the information along and continue ...
	Bib::reportAllBibFiles $pattern $field $biblist $results
	return 1
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::findEntries" --
 # 
 # Search for all entries matching a given regular expression.  The results
 # are returned in a list, each element of which is a list of four integers:
 # the beginning and end of the matching entry and the beginning and end of
 # the matching string.  Adapted from "matchingLines" in "misc.tcl".
 # 
 # If "ignoreStrings" is "1" then we ignore all "string" entries.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::findEntries {pat {caseSen 1} {ignoreStrings 0}} {
    
    if {($pat eq "")} {
	return
    }
    set pos [minPos]
    set result [list]
    watchCursor
    while {![catch {search -s -f 1 -r 1 -i $caseSen -- $pat $pos} match]} {
	set entry [Bib::entryLimits [lindex $match 0]]
	set addResult 1
	if {$ignoreStrings \
	  && ![catch {Bib::getFields [lindex $entry 0]} fieldsList] \
	  && ([string tolower [lindex $fieldsList 1 0]] eq "string")} {
	    set addResult 0
	}
	if {$addResult} {
	    lappend result [concat $match $entry]
	}
	if {[pos::compare [lindex $entry 1] != $pos]} {
	    set pos [lindex $entry 1]
	} else {
	    break
	}
    }
    return $result
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Report Windows ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::writeEntries" --
 # 
 # Take a list of lists that point to selected entries and copy these into a
 # new window.  The beginning and ending positions for each entry must be the
 # last two items in each sublist.  The rest of the sublists are ignored.  It
 # is assumed that each sublist has the same number of items.
 # 
 # The optional argument "sort" indicates that this was sent by a "sort file"
 # call, which can allow overwriting of the buffer.  The optional argument
 # "wCT" is the search window to append to.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::writeEntries {pos nonDes {beg ""} {end {-1}} {sort 0} {wCT ""} {field ""} {searchPat ""} {entryLength ""}} {
    
    global BibmodeVars
    if {($beg eq "")} {
	set beg [minPos]
    }
    if {($end < 0)} {
	set end [maxPos]
    }
    # pos is "entry position" ...
    set llen [expr [llength [lindex $pos 0]] - 1]
    set llen1 [expr {$llen-1}]
    foreach entry $pos {
	set limits [lrange $entry $llen1 $llen]
	append lines [eval getText $limits]
    }
    # nonDes means "non-destructive" ...
    set overwriteOK [expr {$nonDes || ![Bib::isBibFile]}]
    set readOnly    [win::getInfo [win::Current] read-only]
    # Four conditions that must be met to allow over-writing ...
    if {$BibmodeVars(overwriteBufferDuringSort) \
      && $overwriteOK && $sort && !$readOnly} {
	deleteText $beg $end
	insertText $lines
	goto $beg
	return
    }
    if {$sort} {
	set type  "Sort"
	set title "* Sort Results *"
    } else {
	set type  "Search"
	set title "* Search Results *"
    }
    set appendResults 0
    if {($type eq "Search")} {
	# This is for a search.  Do we want to append the results to a current
	# "* Search Results *" window or not?
	set searchWindows ""
	foreach window [winNames] {
	    # We'll use this in a moment.
	    if {[regexp -- "\\* Search Results \\*" [win::StripCount $window]]} {
		lappend searchWindows $window
	    }
	}
	if {($wCT ne "")} {
	    # The calling proc supplied a window to append to
	    set appendResults $wCT
	} elseif {[llength $searchWindows]} {
	    # Find out if we should append to a current search window.
	    if {[askyesno "Would you like to append the search results \
	      \rto the current \"Search Results\" window?"]} {
		# Now we need to see if there's more than one.
		if {([llength $searchWindows] != 1)} {
		    set appendResults [listpick -p \
		      "Please choose a window:" $searchWindows]
		} else {
		    set appendResults [lindex $searchWindows 0]
		}
	    }
	}
    }
    # Create the report.
    set    t "\r$type Results for \"[win::CurrentTail]\"\r\r"
    append t "Note: Command double-click on any cite-key to return to its entry.\r"
    append t "______________________________________________________________________\r\r"
    if {($field ne "") && ($searchPat ne "") && ($entryLength ne "")} {
	append t "   Search Pattern: $searchPat\r"
	append t "     Search Field: $field\r"
	append t "    Entries Found: $entryLength\r"
	append t "______________________________________________________________________\r\r"
    }
    if {[pos::diff [minPos] [lineStart $beg]] && \
      ![regexp -- {\\* Search Results \\*} [win::CurrentTail]]} {
	# We only insert the "header" text if 
	# (1) there's something there, and 
	# (2) this isn't a sort of a "search results" window. 
	append t [getText [minPos] [lineStart $beg]]
    }
    append t $lines
    append t [getText [nextLineStart $end] [maxPos]]
    # Either create a new window, or append to an existing one.
    placeBookmark
    if {($appendResults eq 0)} {
	set t1 "% -*-Bib-*- ([string tolower $type])\r"
	append t1 "$t\r"
	new -n $title -m "Bib" -text $t1
	set pos [minPos]
    } else {
	bringToFront $appendResults
	setWinInfo read-only 0
	goto    [maxPos]
	set pos [getPos]
	insertText "______________________________________________________________________\r"
	insertText "______________________________________________________________________\r"
	insertText $t
    }
    removeAllMarks
    Bib::MarkFile
    if {!$sort && ($searchPat ne "")} {
	# A little color ...
	set pos2 $pos
	if {[regexp -- {(all fields)|citeKey} $field]} {
	    if {![catch {search -f 1 -i 0 -s -r 1 -- $field $pos2} match]} {
		text::color [lindex $match 0] [lindex $match 1] 1
	    }
	}
	while {![catch {search -f 1 -i 1 -s -r 1 -- $searchPat $pos2} match]} {
	    text::color [lindex $match 0] [lindex $match 1] 4
	    set pos2 [lindex $match 1]
	}
    }
    winReadOnly
    goto $pos
    insertToTop
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::getFldName" --
 # 
 # Get the name of the field that starts before the given position, $pos.
 # The argument "top" restricts the range of the search for the beginning of
 # the field; typically, $top will be the opening limit of a given entry.  If
 # no field name was determined, "citeKey" will be returned.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::getFldName {pos top} {
    
    set fldPat {[,  ]+([^   =,\{\}\"\']+)[  ]*=[    ]*}
    set match [search -n -s -f 0 -r 1 -i 1 -limit $top -- $fldPat $pos]
    if {[llength $match} {
	regexp -nocase -- $fldPat [eval getText $match] -> fldName
	return [string tolower $fldName]
    } else {
	return {citeKey}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::reportAllBibFiles" --
 # 
 # Given the four parameters, return (or append to) a "Search Results" window
 # the results of the "Search All Bib Files" search.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::reportAllBibFiles {pattern field biblist results} {
    
    global BibmodeVars BibFileTailConnect
    
    if {($biblist eq "-1")} {
	# Didn't find any ...
	status::msg "Sorry, couldn't find \"$pattern\"."
	return ""
    }
    # Get the list of open windows, that we won't close later.
    set windows [winNames -f]
    # Turn off automark, because we could be opening a lot of files here.
    set oldAutoMark $BibmodeVars(autoMark)
    set BibmodeVars(autoMark) 0
    # If the field was "citeKey" or "all fields", then we know that the
    # grep search was accurate.  Otherwise, we know that we have some false
    # positives in there.  This will get ugly, but we need to open all of
    # the files and check to see if the pattern is actually in the field
    # that we need.
    set biblist2 ""
    if {($field ne "citeKey") && ($field ne "all fields")} {
	foreach f $biblist {
	    file::openQuietly $f
	    if {([Bib::searchFields $field $pattern "-1"] != 0)} {
		lappend biblist2 $f
	    }
	    if {([lsearch $windows $f] == "-1")} {
		killWindow
	    }
	}
	status::msg ""
	if {![llength $biblist2]} {
	    # Didn't find any ...
	    status::msg "Sorry, couldn't find \"$pattern\"."
	    return ""
	}
    } else {
	set biblist2 $biblist
    }
    # Turn automark back on.
    set BibmodeVars(autoMark) $oldAutoMark
    if {([llength $biblist2] == 1)} {
	# There was only one file.
	set title "Only one file matched \"$pattern\" :"
    } else {
	set title ""
    }
    # Create a list for the dialog.
    set biblist3 {"List all matchesÉ"}
    foreach f $biblist2 {
	lappend biblist3 $BibFileTailConnect($f)
    }
    # Create the results for a potential browser window.
    set     results2  "-*-Brws-*-\r\rUse the arrows keys to navigate, "
    append  results2  "\"return\" to go to a citation.\r\r"
    append  results2 $results
    # Offer the list in a listpick dialog, and add a file to the results if
    # desired.  Select one first ...
    set results3 [Bib::reportAllBibsDialog $title $field $pattern \
      $biblist3 $results2 ""]
    set wCT      [lindex $results3 0]
    set biblist3 [concat "Cancel" [lindex $results3 1]]
    # ... And then the rest.
    while {($wCT ne "-1")} {
	set title    "Choose another file, or press Cancel:"
	set results3 [Bib::reportAllBibsDialog $title $field $pattern \
	  $biblist3 $results2 $wCT]
	set wCT      [lindex $results3 0]
	set biblist3 [lindex $results3 1]
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::reportAllBibsDialog" --
 # 
 # Present a dialog to the user so that the proper matches can be listed in
 # the results window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::reportAllBibsDialog {title field pattern biblist3 results2 {wCT ""}} {
    
    global Bib::TailFileConnect
    
    if {($title eq "")} {
	set title "Multiple \"$pattern\" matches were found:"
    }
    if {([llength $biblist3] == 2)} {
	set title "List matches to open a browser window:"
    }
    # Get the list of open windows, that we won't close later.
    set windows [winNames -f]
    set fTail [listpick -L {"List all matchesÉ"} -p $title $biblist3]
    if {($fTail eq "List all matchesÉ")} {
	# If the field was "citeKey" or "all fields", then we know that the
	# grep search was accurate.  Otherwise, we know that we have some false
	# positives in there.
	if {($field ne "citeKey") && ($field ne "all fields")} {
	    dialog::alert "Note that the \"List All Matches\" option may\
	      contain several false positive matches for the specific field..."
	}
	grepsToWindow "* $pattern Search Results *" $results2
	insertToTop
	# Since this can jump to any file, we stop after this.
	return "-1"
    } else {
	set f [set Bib::TailFileConnect($fTail)]
	file::openQuietly  $f
	set f2 [win::CurrentTail]
	Bib::searchFields $field $pattern $wCT
	# Current window is now the "Search Results" window.
	set wCT [win::CurrentTail]
	bringToFront $f2
	if {([lsearch $windows $fTail] == "-1")} {
	    killWindow
	}
    }
    # ... remove it from the list ...
    set bibFSpot [lsearch  $biblist3 $fTail]
    set biblist3 [lreplace $biblist3 $bibFSpot $bibFSpot]
    if {([llength $biblist3] == 1)} {
	# Only the "Cancel" remains.
	return [list "-1" ""]
    } else {
	# Return the list for another round.
	return [list $wCT $biblist3]
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Quick Find Citation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::quickFindCitation" --
 # 
 # Prompt the user in the status bar window for citekeys contained in the
 # bibIndex file, creating one if necessary.
 # 
 # Note: the "nomatchiserror" flag allows a match to immediately jump to the
 # entry for some reason ...
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::quickFindCitation {} {
    
    global BibmodeVars PREFS
    
    if {![file exists [file join $PREFS bibIndex]]} {
	Bib::rebuildIndex

	status::msg "Index has been rebuilt -- try again !!"
	return
    }
    return [Bib::GotoEntry [prompt::statusLineComplete  \
      "Citation" {Bib::completionsForEntry}             \
      -nomatchiserror                                   \
      -preeval  {source [file join $PREFS bibIndex]}    \
      -posteval {unset bibIndex}]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::completionsForEntry" --
 # 
 # Called by [Bib::quickFindCitation] via [prompt::statusLineComplete].  This
 # will in turn redirect us to [Bib::_FindAllEntries] below.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::completionsForEntry {pref} {
    return [Bib::_FindAllEntries $pref 0]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::_FindAllEntries" --
 # 
 # Find all entries with a given prefix, optionally attaching the titles of
 # the entries (this requires a bibDatabase file to be setup).  Used by TeX
 # citation completions: \cite{Darley<cmd-Tab> (in [TeX::Completion::Cite])
 # as well as [Bib::quickFindCitation].
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::_FindAllEntries {eprefix {withtitles 1}} {
    
    global PREFS
    
    set matches {}
    if {$withtitles} {
	if {![file exists [file join ${PREFS} bibDatabase]]} {
	    Bib::rebuildDatabase
	}
	set cid [scancontext create]
	scanmatch $cid "^${eprefix}" {
	    lappend matches $matchInfo(line)
	}
	set fid [open [file join ${PREFS} bibDatabase] r]
	scanfile $cid $fid
	close $fid
	scancontext delete $cid
    } else {
	if {![file exists [file join ${PREFS} bibIndex]]} {
	    Bib::rebuildIndex
	}
	global bibIndex
	if {![array exists bibIndex]} {
	    source [file join ${PREFS} bibIndex]
	    set unset 1
	}
	foreach f [array names bibIndex] {
	    eval lappend matches [completion::fromList $eprefix "bibIndex(${f})"]
	}
	if {[info exists unset]} {
	    unset bibIndex
	}
    }
    return $matches
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::GotoEntry" --
 # 
 # Look for a bib entry in the given list of files, or if that fails or isn't
 # given, look in all available bib files on the search path.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::GotoEntry {entry {biblist {}}} {
    
    if ![catch {Bib::gotoEntryFromIndex $entry}] {
	return
    } elseif {[llength $biblist] && ![catch {Bib::_GotoEntry $entry $biblist 0}]} {
	return
    } elseif ![catch {Bib::_GotoEntry $entry [Bib::listAllBibliographies]}] {
	return
    }
    beep
    error "Can't find entry '$entry' in the .bib file(s)"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::gotoEntryFromIndex" --
 # 
 # Look in the bibIndex and find an entry very quickly. 
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::gotoEntryFromIndex {entry} {
    
    global PREFS
    
    variable TopPat

    # If it fails, but we succeed later, we will have the opportunity
    # to rebuild the bibIndex
    if {[file exists [file join ${PREFS} bibIndex]]} {
	source [file join ${PREFS} bibIndex]
	foreach f [array names bibIndex] {
	    if {[regexp -- "\[ \r\n\]$entry\[ \r\n\]" "$bibIndex($f)"]} {
		if {![file exists $f]} {
		    if {[dialog::yesno "Your bibIndex is out of date.\
		      Would you like to rebuild it?"]} {
			Bib::buildIndex 1
			Bib::gotoEntryFromIndex $entry
			return
		    } else {
			error "Cancelled -- entry '$entry' found, but index\
			  pointed to nonexistent file."
		    }
		}
		placeBookmark
		file::openQuietly $f
		set p [search -s -f 1 -r 1 -- ${TopPat}${entry} [minPos]]
		goto [lindex [Bib::entryLimits [lindex $p 1]] 0]
		insertToTop
		status::msg "Press <Ctl .> to return to previous position."
		unset bibIndex
		return
	    }
	}
	unset bibIndex
    }
    error "Cancelled -- entry '$entry' not found in bibIndex"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Bib::_GotoEntry" --
 # 
 # Find a bib entry in one of the given list of files, and signal an error if
 # the entry isn't found.  I think this is the quickest way.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::_GotoEntry {entry biblist {rebuild 1}} {
    
    variable TopPat

    set cid [scancontext create]
    scanmatch $cid ${TopPat}${entry} {
	set found $matchInfo(offset)
    }
    set found ""
    foreach f $biblist {
	status::msg "Searching [file tail $f]É"
	if {![catch {set fid [open $f]}]} {
	    scanfile $cid $fid
	    close $fid
	    if {($found ne "")} {
		placeBookmark
		file::openQuietly $f
		set found [pos::math [minPos] + $found]
		goto [lindex [Bib::entryLimits [nextLineStart $found]] 0]
		insertToTop
		status::msg "Press <Ctl .> to return to previous position."
		scancontext delete $cid
		if {$rebuild} {
		    # Make the index since it was obviously out of date             
		    Bib::rebuildIndex
		}
	    }
	    return
	}
    }
    scancontext delete $cid
    error "Entry '$entry' not found."
}

# ===========================================================================
# 
# .
