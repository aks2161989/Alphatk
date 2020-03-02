## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexValidate.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 03/21/2006 {02:53:15 PM}
 # Description: 
 # 
 # Menu item procedures that pertain to entry validating.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexValidate.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Validating ×××× #
#

# ===========================================================================
# 
# Validate Entry
# 
# Check the fields of the current entry against the Bib::RqdFlds() and
# Bib::ValidFlds() arrays, and report any irregularities.  The argument
# "quietly" is set to 1 when this is called by "Validate All Entries."
#
# When called from Bib::validateRemaining, the result is a list:
# 
# (0) the cite-key
# (1) a (possibly empty) list of missing fields, set to "-1" if the
#     entry was not recognized by Bib::RqdFlds()
# (2) a (possibly empty) list of "extra" fields.
# 

proc Bib::validateEntry {{quietly 0} {pos ""}} {
    
    Bib::BibModeMenuItem
    
    global BibmodeVars Bib::EntryNameConnect Bib::RqdFlds Bib::ValidFlds
    
    # Make sure that we're not in a selection.
    if {!$quietly || ![string length $pos]} {
	set pos [getPos]
    } 
    # Make sure that we're in an entry.
    if {[catch {Bib::isInEntry $pos} result]} {
	if {!$quietly} {
	    error "Cancelled -- could not identify an entry to validate."
	} else {
	    return [list]
	}
    }
    # Get the field array.  Make sure that we're not in a "@string" entry.
    if {[catch {Bib::getFields $pos} fieldLists]} {
	catch {eval [list selectText] $result}
	error "Cancelled -- $fieldLists"
    }
    # Get the cite-key.
    set citeKey   [lindex [lindex $fieldLists 1] 1]
    # Get entry type -- this will be lower case, which we then connect.
    set entrytype [lindex [lindex $fieldLists 1] 0]
    set entrytype [string tolower $entrytype]
    set entryType $entrytype
    catch {set entryType [set Bib::EntryNameConnect($entrytype)]}
    set customEntryType [Bib::entryPrefConnect $entryType]
    # If this is a "string", it must have been at the top of the file.
    if {$entryType == "string"} {
	if {!$quietly} {
	    error "Cancelled -- cannot validate \"@string\" entries."
	} else {
	    return [list "string!!!"]
	}
    } 
    # Get field list, then remove "type" and "citeKey", and flush braces.
    set fieldList   [lrange [lindex $fieldLists 0] 2 end]
    set fieldValues [lrange [lindex $fieldLists 1] 2 end]
    regsub -all "\{|\}" $fieldList "" fieldList
    set fieldList   [string tolower $fieldList]
    # Now check to see if we have any info on valid fields.  Note that we
    # return an "error" even if this is a user defined entry.
    if {![info exists Bib::ValidFlds($entryType)]} {
	if {!$quietly} {
	    Bib::nextEntry 1
	    status::msg  "Sorry, no field information available\
	      for the entry \"$entrytype\"."
	} 
	return [list $citeKey "-1 $entrytype" "" ""]
    } 
    # Now we're ready to validate.  First check for required fields:
    set missingFields ""
    set emptyFields   ""
    foreach field [set Bib::RqdFlds($entryType)] {
	if {[set where [lsearch $fieldList [string tolower $field]]] == "-1"} {
	    append missingFields "$field "
	} elseif {![string length [string trim [lindex $fieldValues $where]]]} {
	    append emptyFields "$field "
	}
    }
    # Then check for extra fields:
    set nSFields ""
    if {!$BibmodeVars(ignoreExtraFields)} {
	foreach field $fieldList {
	    if {[lsearch [set Bib::ValidFlds($entryType)] [string tolower $field]] == "-1"} {
		append nSFields "$field "               
	    } 
	}
    } 
    # Return the results:
    set result "$citeKey -- "
    if {[llength $missingFields]} {
	append result "missing fields: $missingFields"
    } else {
	append result "no missing fields "
    } 
    if {[llength $emptyFields]} {
	append result "; empty (required) fields: $emptyFields"
    } 
    if {[llength $nSFields]} {
	append result "; extra fields: $nSFields"
    } 
    if {$quietly} {
	return [list $citeKey $missingFields $emptyFields $nSFields]
    } else {
	goto [lindex [Bib::entryLimits $pos] 0]
	insertToTop
	Bib::nextEntry 1
	status::msg $result
    }
}

# ===========================================================================
# 
# Validate All Entries
# 
# Check the fields of each entry in the current window against the Bib::RqdFlds()
# and Bib::OptFlds() arrays, and report any irregularities in a new window.  Also
# checks for duplicate cite-keys.  Note that this only validates from the
# current entry on down, to be consistent with "Format All Entries".
#


proc Bib::validateRemaining {{pos ""}} {
    
    Bib::BibModeMenuItem
    
    global BibmodeVars
    
    if {![string length $pos]} {set pos [getPos]}
    # This little dance handles the case that the first entry starts on the
    # first line.
    set hit [Bib::entryLimits $pos]
    if {[pos::compare [lindex $hit 0] == [lindex $hit 1]]} {
	set pos [Bib::nextEntryStart $pos]
	set hit [Bib::entryLimits $pos]
    }
    # Set up the variables for the report.
    set results        ""
    set citeKeyList    ""
    set count          0 
    set missingCount   0
    set emptyCount     0
    set nSFieldCount   0
    set duplicateCount 0
    set unknownCount   0
    # Now validate all of the entries.
    while {[pos::compare $pos < [lindex $hit 1]]} {
	set lastPos $pos
	set validateList [Bib::validateEntry 1 $pos]
	set report 0
	set citeKey [lindex $validateList 0]
	# (Special quirk if a string is at the top of the file.)
	if {$citeKey == "string!!!"} {
	    set pos [Bib::nextEntryStart $pos]
	    set hit [Bib::entryLimits $pos]
	    continue
	} 
	status::msg "Validating: [incr count]"
	# Check for duplicate cite keys.
	set result  "[format {%-25s} "$citeKey  "]"
	if {[lsearch $citeKeyList $citeKey] != "-1"} {
	    append result "\r  Warning: \"$citeKey\" is a duplicate cite-key."
	    set report 1
	    incr duplicateCount
	} 
	lappend citeKeyList $citeKey
	# Any missing fields?  If the list is empty, we do nothing.
	set missingFields [lindex $validateList 1]
	if {[lindex $missingFields 0] == "-1"} {
	    # This was an unrecognized entry.
	    append result "\r  Warning: no field information available\
	      for the entry \"[lindex $missingFields 1]\"."
	    set report 1
	    incr unknownCount
	} elseif {$missingFields != ""} {
	    # Missing fields for the recognized entry.
	    append result "$missingFields"
	    set report 1
	    incr missingCount
	} 
	# Any empty required fields? If the list is empty, we do nothing.
	set emptyFields  [lindex $validateList 2]
	if {$emptyFields != ""} {
	    append result "\r         empty fields:   $emptyFields"
	    set report 1
	    incr emptyCount
	} 
	# Any "extra" fields?  If the list is empty, we do nothing.
	set nSFields  [lindex $validateList 3]
	if {$nSFields != ""} {
	    append result "\r         extra fields:   $nSFields"
	    set report 1
	    incr nSFieldCount
	} 
	# Did we found out anything?
	if {$report} {append results "$result\r"} 
	# Set the 'pos' to the start of the next entry.
	set pos [Bib::nextEntryStart $pos]
	set hit [Bib::entryLimits $pos]
	set pos [lindex $hit 0]
	# Aren't we done yet?
	if {[pos::compare $pos == $lastPos]} {break}
    }
    # If no irregularities were found, just return a happy message. 
    # Otherwise, generate a "Validation Results" report.
    if {$results == ""} {
	status::msg "$count entries validated -- no irregularities found."
	return
    } 
    # Do we want to append the results to a current "* Format Results *"
    # window or not?
    set appendResults   0
    set validateWindows ""
    foreach window [winNames] {
	# We'll use this in a moment.
	if {[regexp "\\* Validation Results \\*" [win::StripCount $window]]} {
	    lappend validateWindows $window
	} 
    }
    if {[llength $validateWindows]} {
	# Find out if we should append to a current search window.
	if {[askyesno "Would you like to append the validation results\
	  \rto the current \"Validation Results\" window?"] == "yes"} {
	    # Now we need to see if there's more than one.
	    if {[llength $validateWindows] != 1} {
		set appendResults [listpick -p \
		  "Please choose a window:" $validateWindows]
	    } else {
		set appendResults [lindex $validateWindows 0]
	    } 
	} 
    } 
    # Generate the report header.
    append t "\r  Validation Results for \"[win::CurrentTail]\"\r\r"
    append t "  Note: Cite-keys followed by an empty string do not have missing fields.\r"
    append t "        'Empty' fields only refer to those which are required for the entry.\r"
    append t "        Command double-click on any cite-key to return to its entry.\r"
    append t "________________________________________________________________________\r\r"
    # Add validation summary results.
    append t "     Validated Entries:  [format {%4d} $count]\r\r"
    append t "        Missing Fields:  [format {%4d} $missingCount]\r"
    append t "          Empty Fields:  [format {%4d} $emptyCount]\r"
    if {!$BibmodeVars(ignoreExtraFields)} {
	append t "          Extra Fields:  [format {%4d} $nSFieldCount]\r"
    } 
    append t "   Duplicate Cite-keys:  [format {%4d} $duplicateCount]\r"
    append t "  Unrecognized Entries:  [format {%4d} $unknownCount]\r"
    append t "________________________________________________________________________\r\r"
    append t "  cite-keys:             missing fields:\r"
    append t "  ----------             ---------------\r\r"
    append t "$results\r"
    append t "________________________________________________________________________\r"
    append t "________________________________________________________________________\r"
    # Either create a new window, or append to an existing one.
    placeBookmark
    if {$appendResults == 0} {
	set    t1 "% -*-Bib-*- (validation)\r"
	append t1 $t
	new -n "* Validation Results *" -m "Bib" -text $t1
	set pos [minPos]
    } else {
	bringToFront $appendResults
	setWinInfo read-only 0
	goto [maxPos]
	set pos [getPos]
	insertText $t
    }
    # Color warnings, errors, etc. red.
    set searchText {cite-keys:|missing fields:|Warning:|(extra|empty) fields:}
    set pos2 [minPos]
    while {![catch {search -f 1 -i 0 -s -r 1 $searchText $pos2} match]} {
	text::color [lindex $match 0] [lindex $match 1] 5
	set pos2 [lindex $match 1]
    } 
    refresh
    goto [minPos]
    winReadOnly
    # Now we'll mark just those entries that truly have missing fields. 
    # Handy if "ignoreExtraFields" is turned off and there are a lot of
    # entries with extra fields.
    removeAllMarks
    set pos3 [minPos]
    set searchText {^([-a-zA-Z0-9_:/\.])+([\t ]+[a-zA-Z])}
    while {![catch {search -f 1 -r 1 -m 0 -i 0 -s $searchText $pos3} match]} {
	set start [lindex $match 0]
	set end   [nextLineStart $start]
	set t     [getText $start $end]
	regexp {[a-zA-Z0-9]+[-a-zA-Z0-9_:/\.]} $t citeKeyMark
	setNamedMark $citeKeyMark $start $start $start
	set pos3 $end
    }
    goto $pos ; insertToTop
    status::msg "Entries with missing fields are listed in the marks menu."
}

proc Bib::validateAllEntries {} {Bib::validateRemaining [minPos]}

# ==========================================================================
# 
# .