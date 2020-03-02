## -*-Tcl-*-
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "BibCompletions.tcl"
 #                                   created: 05/10/1995 {12:55:13 am} 
 #                               last update: 11/30/2004 {11:58:49 AM}
 # Description:
 # 
 # Procedures for electric completions, including acronyms.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

proc BibCompletions.tcl {} {}

namespace eval Bib {}

# Setting the order of precedence for completions.

set completions(Bib) {
    Cmd Context Entry Field FieldValues LaTeXCommand Word Acronyms
}

# Note:  The variable "Bibcmds" is now set in Bib::setBibcmds

#============================================================================
# 
# Bib::Completion::Entry
# 
# If the current text is '@XXX' where 'XXX' is the name of a bib-entry
# type, then insert the correct template for that type.
# 

namespace eval Bib::Completion {

    variable lastWord ""
    # We don't complete values in these fields.
    variable ignoreFieldValueFields \
      [list abstract annote booktitle isbn issn lccn note number pages \
      volume title year]
}

proc Bib::Completion::Context {} {
    
    variable pos1
    variable inComment [text::isInComment [getPos]]
    variable lastWord  [completion::lastWord pos1]
    variable oneBack   [pos::prevChar $pos1]
    return   0
}

proc Bib::Completion::Entry {} {
    
    variable inComment
    variable lastWord
    variable oneBack
    variable pos1
   
    if {$inComment} {return 0}
    # The following will deal with wordBreak prefs that might not include '@'
    set lastword [string trimleft $lastWord @]
    if {([lookAt $pos1] != "@") && ([lookAt $oneBack] != "@")} {return 0}
    # Make sure that this is a defined entry.
    if {[catch {Bib::isValidEntry $lastword} lastword]} {return 0}
    deleteText $pos1 [getPos]
    goto $pos1
    Bib::entriesProc "" $lastword
    return 1
}

#============================================================================
# 
# Bib::Completion::Field
# 
# Insert a new field within an existing entry.  If the cursor is before a
# current entry (as defined by the variable "indentString"), Bib::makeField
# will insert it on current line.  Otherwise, insert it on the next line.
# 

proc Bib::Completion::Field {} {
    
    variable inComment
    variable lastWord
    variable pos1
    
    if {$inComment || !$::BibmodeVars(fieldCompletions)} {return 0} 
    # Make sure that this is a defined entry.
    if {[catch {Bib::isValidField $lastWord} lastword]} {return 0}
    deleteText $pos1 [getPos]
    Bib::fieldsProc "" $lastword
    return 1
}

# ===========================================================================
# 
# Bib::Completion::FieldValues
# 
# Offer any similar field values by quickly scanning the entire window for
# potential replacement candidates.  If we are in the middle of a multiple
# author (e.g.) field value, we use the string from the last ' and ' as the
# search term, and only replace that portion of the current string.  While
# scanning, we collect all multiple author fields in which we have a match in
# case we want to add the entire string of them, but also parse out the
# single author.
# 

proc Bib::Completion::FieldValues {} {
    
    variable ignoreFieldValueFields
    variable inComment
    
    if {$inComment} {return 0}

    set openQuote   "(\\\{|\\\")"
    set closeQuote  "(\\\}|\\\")\[,\t \]*\[\r\n\]"

    set pat1 "\[\t \]*(\[a-zA-Z\]+)\[\t \]+=\[\t \]+${openQuote}?(.*)"

    set pos1 [lineStart [set pos0 [getPos]]]
    set line [string tolower [getText $pos1 $pos0]]
    
    while {![regexp $pat1 $line allofit fieldName openQuoteMark fieldValue]} {
	set pos1 [lineStart [pos::math $pos1 - 1]]
	if {[pos::compare $pos1 == [minPos]]} {return 0}
	set line [string tolower [getText $pos1 $pos0]]
    }
    set patAnd {\s+and\s+}
    if {[lsearch $ignoreFieldValueFields $fieldName] != "-1"} {
	# We don't try to complete these fields.
	return 0
    } elseif {![string length $openQuoteMark]} {
	# Trying to enter a field value without delimiters ...  so it's most
	# likely a 'string' and we'll pass on this one.
	return 0
    } else {
	regsub ".+${patAnd}" $fieldValue "" fieldValue
    }
    regsub -all {\s+} $fieldValue {\s+} fieldValuePat
    regsub -all {\.} $fieldValuePat {\\.} fieldValuePat
    set pat2 "^\[\t \]*${fieldName}\[\t \]+=\[\t \]+${openQuote}"
    set pat3 "${pat2}\[^=\]*(${patAnd})?${fieldValuePat}"
    set pos2 [minPos]
    while {![catch {search -s -f 1 -r 1 -i 1 -- $pat3 $pos2} match]} {
	set pos2 [nextLineStart [lindex $match 1]]
	if {[pos::compare [set pos3 [lindex $match 0]] == $pos1]} {
	    continue
	} elseif {![catch {search -s -f 1 -r 1 -- $closeQuote $pos3} match]} {
	    set pos2 [lindex $match 1]
	}
	regsub -all $pat2 [getText $pos3 $pos2] ""  result
	regsub -all "${closeQuote}$" $result    ""  result
	regsub -all {\s+}            $result    " " result
	lappend results [string trim $result]
    }
    if {![info exists results]} {return 0}
    # Parse out multiple authors (e.g.) while still retaining the full list
    # of the result in case we really do want to add multiple authors in the
    # order in which they appear in other fields.  This allows you to
    # complete a multi-author field just by starting the name of the
    # principle, or to add a co-author by themselves.
    if {[regsub -all "\[\t \]+and\[\t \]+" $results "|" multipleResults]} {
	foreach result $multipleResults {
	    foreach item [split $result "|"] {
		lappend results [string trim $item]
	    }
	}
    }
    set completions [list]
    foreach item $results {
	if {[regexp -nocase "^$fieldValue" $item]} {lappend completions $item} 
    }
    set completions [lsort -dictionary -unique $completions]
    # Do we have anything to offer?
    set p "Possible '$fieldName' field completions:"
    if {![llength $completions]} {
	# This shouldn't happen ...
	return 0
    } elseif {[llength $completions] == "1"} {
	set replacement [lindex $completions 0]
    } elseif {[catch {listpick -p $p $completions} replacement]} {
	return 0
    }
    # Now replace the entire value with the new one chosen.  We go to the
    # last 'and' for the replacement.
    set pos4 [pos::math $pos0 - [string length $fieldValue]]
    replaceText $pos4 $pos0 $replacement
    goto [pos::math $pos4 + [string length $replacement]]
    return 1
}

#============================================================================
# 
# Bib::Completion::LaTeXCommand
# 
# Insert a LaTeX command with braces and template stops.  If the opening
# backslash is not present, insert that as well.  This will also recognize
# text-command abbreviations, with and without the slash.
# 

proc Bib::Completion::LaTeXCommand {} {
    
    if {!$::BibmodeVars(latexCompletions)} {return 0} 
    
    variable lastWord
    variable oneBack
    variable pos1
    
    set lastword [string trimleft $lastWord "\\"]
    
    # Make sure that this is a defined TeX command.
    if {[lsearch $::Bib::TeXCommandsList $lastword] == -1} {
	return 0
    } elseif {[lsearch -exact $::Bib::TextAbbrev $lastword] != "-1"} {
        # It's a LaTeX text-command abbreviation.
        if {[lookAt $oneBack] != "\\"} {
            # Is there already a slash?  If not, add one.
            deleteText $pos1 [getPos]
            set LaTeXInsertion "\\text$lastword{¥¥}¥¥"
        } else {
            deleteText $pos1 [getPos]
            set LaTeXInsertion "text$lastword{¥¥}¥¥"
        }
    } else {
        if {[lookAt $oneBack] != "\\"} {
            # Is there already a slash?  If not, add one.
            deleteText $pos1 [getPos]
            set LaTeXInsertion "\\$lastword{¥¥}¥¥"
        } else {
            set LaTeXInsertion "{¥¥}¥¥"
        }
    }
    elec::Insertion $LaTeXInsertion
    return 1
}

#============================================================================
# 
# Bib::Completion::BibAcronyms
# 
# For those who prefer completions to @string{...} .  This proc is only
# called if there were no nearby word completions.
# 
# (Technically, these are "expansions" and are included as such below.)
# 

proc Bib::Completion::Acronyms {} {
    
    variable pos1
    variable lastWord
    
    if {![info exists ::Bib::Acronyms($lastWord)]} {return 0}
    deleteText $pos1 [getPos]
    elec::Insertion $::Bib::Acronyms($lastword)
    return 1
}

#============================================================================
# 
# Bib::Expansion::Acronyms
# 
# Allowing the expansion key to also complete acronyms.
# 

set expanders(Bib) {Context Acronyms}

# namespace eval Bib::Expansion {}

# proc Bib::Expansion::ExAcronyms {} {Bib::Completion::Acronyms}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Acronyms ×××× #
# 

namespace eval Bib {}

proc Bib::acronymsProc {menuName itemName} {
    
    global BibmodeVars
    
    if {$menuName == "bibModeAcronyms" && [getModifiers]} {
	if {$itemName == "viewAcronyms"} {
	    alertnote "Use this menu item to view the current set of\
	      acronyms associated with Bib mode."
	} elseif {$itemName == "addAcronyms"} {
	    alertnote "Use this menu item to add additional acronyms."
	} elseif {$itemName == "removeAcronyms"} {
	    alertnote "Use this menu item to remove previously set acronyms."
	} elseif {$itemName == "unsetAcronymList"} {
	    alertnote "Use this menu item to turn off the set of \
	      pre-defined acronyms."
	} elseif {$itemName == "resetAcronymList"} {
	    alertnote "Use this menu item to restore the set of \
	      pre-defined acronyms."
	} elseif {$itemName == "checkKeywords"} {
	    alertnote "Use this menu item to check if a particular word\
	      has already been defined as a Bib mode keyword."
	} elseif {$itemName == "bibModeTutorial"} {
	    alertnote "Use this menu item to open a Bib mode\
	      Completions Tutorial."
	} 
    } elseif {[regsub ".*setAcronymList" $itemName "unsetAcronymList" itemName]} {
	set BibmodeVars($itemName) [expr $BibmodeVars($itemName) ? 0 : 1]
	prefs::modified BibmodeVars($itemName)
	# Anything else to do?
	Bib::updatePreferences $itemName
	Bib::unsetAcronymList $BibmodeVars(unsetAcronymList) 0
   } elseif {$itemName == "checkKeywords"} {
	Bib::checkKeywords
    } elseif {$itemName == "bibModeTutorial"} {
	mode::completionsTutorial "Bib"
    } else {
	Bib::$itemName
    } 
}

# ===========================================================================
# 
# View Acronyms
# 
# Place the names and elements of the array in a new window, and shrink it.
# 

proc Bib::viewAcronyms {{quietly 0}} {
    
    global Bib::Acronyms
    
    set windows [winNames]
    foreach w $windows {
	# Close any open "* Bib Acronyms *" windows.
	if {[regexp "\\* Bib Acronyms \\*" [win::StripCount $w]]} {
	    bringToFront $w
	    killWindow
	    set quietly 0
	}
    }
    if {[set acroynymsList [listArray Bib::Acronyms]] == ""} {
	status::msg "There are currently no defined acronyms."
	return
    } elseif {$quietly} {
	return
    } 
    new -n "* Bib Acronyms *" -text $acroynymsList -m "Bib"
    # if 'shrinkWindow' is loaded, call it to trim the output window.
    catch {
	goto [maxPos] ; insertText "\r"
	selectAll     ; sortLines
    }
    goto [minPos]
    insertText "Command double-click on\racronyms to re-define them.\r\r"
    catch {shrinkWindow 2}
    winReadOnly
    status::msg ""
}

# ===========================================================================
# 
# Add Acronyms
# 
# Present the user with a dialog to create a new acronym.
# 

proc Bib::addAcronyms {{title ""} {acronym ""} {expansion ""}} {
    
    set finish [Bib::addAcronymsDialog $title $acronym $expansion]
    # Offer the dialog again to add more.
    set title "Create another acronym, or press Finish:"
    while {$finish != 1} {set finish [Bib::addAcronymsDialog $title]}
    Bib::viewAcronyms 1
    Bib::rebuildMenu bibModeAcronyms
}

proc Bib::addAcronymsDialog {{title ""} {acronym ""} {expansion ""}} {
    
    global Bib::Acronyms
    
    # Create the add acronym dialog.
    if {$title == ""} {set title "Create a new Acronym :"} 
    set y  10
    if {[info tclversion] < 8.0} {
	set aD [dialog::text $title 10 y 90]
	set yb 35
    } else {
	set aD [list -T $title]
	set yb 10
    }
    eval lappend aD [dialog::button    "Finish"                    290 yb   ]
    eval lappend aD [dialog::button    "More"                      290 yb   ]
    eval lappend aD [dialog::button    "Cancel"                    290 yb   ]
    if {$acronym == ""} {
	eval lappend aD \
	  [dialog::textedit  "Acronym:" $acronym    10  y  5]
    } else {
	eval lappend aD [dialog::text      "Acronym :"              10  y   ]
	eval lappend aD [dialog::menu 10 y $acronym $acronym        150      ]
    } 
    eval lappend aD     [dialog::textedit "Expansion:" $expansion   10  y 25]

    incr y 10
    set result    [eval dialog -w 370 -h $y $aD]
    set finish    [lindex $result 0]
    set cancel    [lindex $result 2]
    set acronym   [string trim [lindex $result 3]]
    set expansion [lindex $result 4]
    if {$cancel} {
	# User pressed "Cancel'
	error "cancel"
    } elseif {$acronym != "" || $expansion != ""} {
	set Bib::Acronyms($acronym) $expansion
	prefs::addArrayElement Bib::Acronyms $acronym $expansion
	status::msg "\"$acronym -- $expansion\" has been added."
	return $finish
    } elseif {$finish} {
	return $finish
    } else {
	error "Cancelled -- one of the required fields was empty."
    } 
}

# ===========================================================================
# 
# Edit Acronyms
# 
# Present the user with a dialog to edit a current misspelling.
# 

proc Bib::editAcronyms {{title ""} {acronym ""} {expansion ""}} {
    
    global Bib::Acronyms
    
    set acronyms [lsort [array names Bib::Acronyms]]
    if {$acronym == ""} {
	set acronym [listpick -p "Select an acronym to edit :" $acronyms] 
    } 
    if {$expansion == ""} {set expansion [set Bib::Acronyms($acronym)]} 
    if {$title == ""}     {set title "Edit the \"$acronym\" acronym:"} 
    set finish [Bib::addAcronymsDialog $title $acronym $expansion]
    # Offer the dialog again to add more.
    while {$finish != 1} {
	set title     "Select another acronym to edit, or Cancel :"
	set acronym   [listpick -p $title $acronyms]
	set expansion [set Bib::Acronyms($acronym)]
	set title     "Edit the \"$acronym\" acronym"
	set finish    [Bib::addAcronymsDialog $title $acronym $expansion]
    }
    Bib::viewAcronyms 1
}

# ===========================================================================
# 
# Remove Acronyms
# 
# Remove user-defined acronyms.  If "unsetList" is set, can alternatively
# remove the pre-defined list that is defined in "BibCompletions.tcl"
# Called from the menu, this will display the current list of acronyms at
# the end.
# 

proc Bib::removeAcronyms {{acronymList ""} {quietly 0}} {
    
    global Bib::Acronyms Bib::AcronymsSet
    
    if {$acronymList == ""} {
	# First list the user defined acronyms.
	set userAcronyms ""
	foreach acronym [array names Bib::Acronyms] {
	    if {![info exists Bib::AcronymsSet($acronym)]} {
		# We know that this is user defined.
		lappend userAcronyms $acronym
	    } elseif {[set Bib::Acronyms($acronym)] != [set Bib::AcronymsSet($acronym)]} {
		# We know that this has not been redefined.
		lappend userAcronyms $acronym
	    } 
	} 
	if {![llength $userAcronyms]} {
	    status::msg "Cancelled -- there are no user defined acronyms to remove."
	    Bib::rebuildMenu bibModeAcronyms
	    return
	} 
	set title "Select some acronyms to remove :"
	set acronymList [listpick -l -p $title [lsort $userAcronyms]]
    }
    
    # Remove them from "arrdefs.tcl"
    foreach acronym $acronymList {
	catch {prefs::removeArrayElement Bib::Acronyms $acronym}
	catch {unset Bib::Acronyms($acronym)}
    } 
    Bib::rebuildMenu bibModeAcronyms
    Bib::viewAcronyms $quietly
} 

# ===========================================================================
# 
# Unset Acronyms
# 
# Remove the pre-defined list of acronyms defined in "BibCompletions.tcl". 
# Called from the menu, this will change the value of the preference, and
# display the current list of acronyms at the end.
# 

proc Bib::unsetAcronymList {unsetList {quietly 1}} {
    
    global BibmodeVars Bib::Acronyms Bib::AcronymsSet
    
    if {!$unsetList} {
	# Restore the set of pre-defined acronyms
	foreach acronym [array names Bib::AcronymsSet] {
	    if {![info exists Bib::Acronyms($acronym)]} {
		# We know that this has not been redefined.
		set Bib::Acronyms($acronym) [set Bib::AcronymsSet($acronym)]
	    } 
	} 
	set BibmodeVars(unsetAcronymList) 0
    } else {
	# Remove the set of pre-defined acronyms
	foreach acronym [array names Bib::AcronymsSet] {
	    if {![info exists Bib::Acronyms($acronym)]} {continue}
	    if {[set Bib::Acronyms($acronym)] == [set Bib::AcronymsSet($acronym)]} {
		# We know that this has not been redefined.
		catch {unset Bib::Acronyms($acronym)}
	    } 
	}
	set BibmodeVars(unsetAcronymList) 1
    }
    prefs::modified BibmodeVars(unsetAcronymList)
    Bib::viewAcronyms
}

# ===========================================================================
# 
# Check Keywords
# 
# See if the proposed custom entry / field name is already taken.
#

proc Bib::checkKeywords {{newKeywordList ""} {quietly 0} {noPrefs 0}} {
    
    global BibmodeVars Bib::DefaultEntries Bib::MyFldEntries Bib::DefaultFields 
    global Bib::CustomEntryList1 Bib::TeXCommandsList Bib::Acronyms Bib::Abbrevs
    
    set type 0
    if {$newKeywordList == ""} {
	set quietly 0
	set newKeywordList [prompt "Enter Bib mode keywords to be checked:" ""]
    }
    # Check to see if the new keyword(s) is already defined.
    foreach newKeyword $newKeywordList {
	if {[lsearch [set Bib::DefaultFields] $newKeyword] != "-1"} {
	    set type "field"
	} elseif {[lsearch [set Bib::DefaultEntries] $newKeyword] != "-1"} {
	    set type "entry"
	} elseif {[lsearch [set Bib::CustomEntryList1] $newKeyword] != "-1"} {
	    set type "custom entry"
	} elseif {[lsearch [set Bib::MyFldEntries] $newKeyword] != "-1"} {
	    set type "Bib::MyFlds() array"
	} elseif {[lsearch [set Bib::TeXCommandsList] $newKeyword] != "-1"} {
	    set type "TeX Commands"
	} elseif {[lsearch [array names Bib::Acronyms] $newKeyword] != "-1"} {
	    set type "Bib Acronyms"
	} elseif {[lsearch [set Bib::Abbrevs] $newKeyword] != "-1"} {
	    set type "Standard Abbreviations"
	} elseif {!$noPrefs && \
	  [lsearch $BibmodeVars(addFields) $newKeyword] != "-1"} {
	    set type "Add Fields preference"
	}
	if {$quietly == 1} {
	    # When this is called from other code, it should only contain
	    # one keyword to be checked, and we'll return it's type.
	    return "$type"
	} elseif {!$quietly && $type == 0} {
	    alertnote "\"$newKeyword\" is not currently defined\
	      as a Bib mode keyword"
	} elseif {$type != 0} {
	    # This will work for any other value for "quietly", such as 2
	    alertnote "\"$newKeyword\" is currently defined as a keyword\
	      in the \"$type\" list."
	} 
	set type 0
    }
}

#============================================================================
# 
# .