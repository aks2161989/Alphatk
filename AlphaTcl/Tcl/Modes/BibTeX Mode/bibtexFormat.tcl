## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexFormat.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 11/24/2004 {03:08:03 PM}
 # Description: 
 # 
 # Menu item procedures that pertain to entry formatting.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexFormat.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Formatting ×××× #
#
	
# ===========================================================================
# 
# Format Entry
# 
# Parse the entry around position "pos" and rewrite it to the original
# buffer in a canonical format
#

proc Bib::formatEntry {{fromClick 0}} {
    
    Bib::BibModeMenuItem
    
    global BibmodeVars Bib::UseBrace Bib::OpenQuote Bib::CloseQuote Bib::Abbrevs
    global Bib::OpenEntry Bib::CloseEntry Bib::Strings
    
    # Make sure that we're not in a selection.
    goto [getPos]

    set limits [Bib::entryLimits [getPos]]
    set pos0   [lindex $limits 0]
    set pos1   [lindex $limits 1]
    
    if {[pos::compare [getPos] == [maxPos]]} {
	status::msg "No further entries in this file to format."
	return
    }

    status::msg "Formatting É"
    set Bib::Strings [Bib::listStrings]
    
    # If this throws an error, we want the user to get it
    set result [Bib::bibFormatEntry $pos0]

    if {($result ne [getText $pos0 $pos1])} {
	replaceText $pos0 $pos1 $result
    }
    goto $pos0
    insertToTop
    if {[regexp -nocase {^\s?@string} $result]} {
	goto [pos::nextLineStart $pos0]
	return
    }
    set nextEntry [lindex [Bib::nextEntry 1] 1]
    if {($nextEntry eq "Couldn't find cite-key.")} {
	status::msg "No further entries in this file to format."
    } else {
	if {$fromClick} {
	    catch {goto [Bib::nextField]}
	    set do "Command double click on the next set of fields"
	} else {
	    set do "Press \"control-shift-L\""
	} 
	status::msg "$do to format  $nextEntry"
    }
    return
}

# ===========================================================================
# 
# Format All Entries
# 
# Parse all entries in the current buffer and rewrite it to the original
# buffer in a canonical format.  If any entries cannot be formatted, we'll
# put that info in a little Results window.
#

proc Bib::formatRemaining {{pos ""}} {
    
    Bib::BibModeMenuItem
    
    global BibmodeVars Bib::UseBrace Bib::OpenQuote Bib::CloseQuote \
      Bib::OpenEntry Bib::CloseEntry Bib::Abbrevs Bib::Strings
    
    # Make sure that we're not in a selection.
    if {![string length $pos]} {
	set pos [getPos]
    }
    # This little dance handles the case that the first entry starts on the
    # first line.
    set hit [Bib::entryLimits $pos]
    if {[pos::compare [lindex $hit 0] == [lindex $hit 1]] \
      || [pos::compare $pos > [lindex $hit 1]]} {
	set pos [Bib::nextEntryStart $pos]
	set hit [Bib::entryLimits $pos]
    }
    set start [lindex $hit 0]
    set line  [lindex [pos::toRowChar $start] 0]
    # Set up the variables for the report.
    set count        0  
    set errorCount   0
    set formatResult ""
    # Create the list of all strings and abbrevs.  If there are many of them,
    # this will go pretty slow.
    set Bib::Strings [Bib::listStrings]
    
    # Format all of the entries.
    set results ""
    status::msg "Formatting É"
    while {[pos::compare $pos < [lindex $hit 1]]} {
	set lastPos $pos
	status::msg "Formatting: [incr count]"
	set pos0 [lindex $hit 0] 
	set pos1 [lindex $hit 1]
	# Now try to format the entry.
	if {![catch {Bib::bibFormatEntry $pos0} result]} {
	    append results $result
	} else {
	    # There was some sort of error ...
	    incr errorCount
	    set linenumber [expr {$line + [regsub -all "\\r" $results "" dummy]}]
	    append formatResult "\r[format {%-17s} "line ${linenumber},"]"
	    catch {append formatResult "cite-key \"[Bib::getCiteKey $pos0]\""}
	    append results [getText $pos0 $pos1]
	}
	set hit [Bib::entryLimits [Bib::nextEntryStart $pos]]
	set pos [lindex $hit 0]
	# Aren't we done yet?
	if {[pos::compare $pos == $lastPos]} {break}
    }
    # Replace the old entries with the formatted results.
    replaceText $start [maxPos] $results
    goto $start ; refresh
    if {!$errorCount} {
	status::msg "$count entries formatted.  No errors detected."
    } else {
	# We had errors, so we'll return them in a little window.
	status::msg "$count entries formatted.  Errors detected É"
	set t    "% -*-Bib-*- (validation)\r"
	append t "\r  Formatting Results for \"[win::CurrentTail]\"\r\r"
	append t "  Note: Command double-click on any cite-key or line-number\r"
	append t "        to return to its original entry.  If there is no\r"
	append t "        cite-key listed, that is certainly one problem ...\r\r"
	append t "___________________________________________________________\r\r"
	append t "    Formatted Entries:  [format {%4d} [expr $count - $errorCount]]\r\r"
	append t "  Unformatted Entries:  [format {%4d} $errorCount]\r"
	append t "___________________________________________________________\r\r"
	append t "  line numbers:  cite-keys:\r"
	append t "  -------------  ----------\r"
	append t $formatResult
	new -n "* Formatting Results *" -m "Bib" -text $t
	goto [minPos]
	winReadOnly
	shrinkHigh
    }
}

proc Bib::formatAllEntries {} {Bib::formatRemaining [minPos]}

# ===========================================================================
# 
# Parse the entry around position "pos" and rewrite it in a canonical
# format.  The formatted entry is returned.
#

proc Bib::bibFormatEntry {pos} {
    
    global BibmodeVars Bib::RqdFlds Bib::OptFlds Bib::UseBrace \
      Bib::EntryNameConnect Bib::Strings Bib::LongestStringNameLength \
      Bib::Abbrevs Bib::OpenQuote Bib::CloseQuote \
      Bib::OpenEntry Bib::CloseEntry Bib::Indent
    
    set strings    [concat [set Bib::Strings] [set Bib::Abbrevs]]
    if {[catch {Bib::getFields $pos} fieldLists]} {
	error "Cancelled -- $fieldLists"
    }
    set type    [lindex [lindex $fieldLists 1] 0]
    set citeKey [lindex [lindex $fieldLists 1] 1]
    set names   [lrange [lindex $fieldLists 0] 2 end]
    set values  [lrange [lindex $fieldLists 1] 2 end]
    # Convert all tab/space runs to a single space
    regsub -all "\[\t \]+" $values " " values
    # Used to find length of longest field name.
    set length 0
    # Used to reorder fields.
    set orderedNames  [list]
    set orderedValues [list]
    # Used to determine if field values should be capitalized.
    set autoCapFields [string tolower $BibmodeVars(autoCapFields)]
    
    # Get the name of the entry, and then (if possible) connect it to the
    # default entryName.
    if {[catch {Bib::isValidEntry $type} entryType]} {set entryType $type}
    set customEntryType [Bib::entryPrefConnect $entryType]
    set spc "                           "
    
    if {([string tolower $entryType] eq "string")} {
	# Special case.
	set limits [Bib::entryLimits $pos]
	set lines  [getText [lindex $limits 0] [lindex $limits 1]]
	regsub "^\[\t \]*=\[\t \]+" [lindex $values 0] "" value
	regsub -all "\[\r\n\t \]+" $value " " value
	set length [set Bib::LongestStringNameLength]
	set pad [expr {$length - [string length $citeKey]}]
	set pad [string range $spc 1 $pad]
	if {$BibmodeVars(upperCaseEntries)} {
	    set type "STRING"
	} else {
	    set type "string"
	}
	if {$BibmodeVars(alignEquals)} {
	    return "@${type}[set Bib::OpenEntry]${citeKey}${pad} = ${value}[set Bib::CloseEntry]\r"
	} else {
	    return "@${type}[set Bib::OpenEntry]${citeKey} = ${pad}${value}[set Bib::CloseEntry]\r"
	}
    } elseif {![catch {set BibmodeVars($customEntryType)} fields]} {
	# Reorder the fields to correspond to the order in the preference. 
	# Any fields which are not part of the standard preference will be
	# retained in the 'names' and 'values' lists, which are added at
	# the end.  This should also make sure that field names are in the
	# proper case.
	foreach f $fields {
	    if {[set where [lsearch [string tolower $names] [string tolower $f]]] != "-1"} {
		lappend orderedValues [lindex $values $where]
		lappend orderedNames  [lindex $names  $where]
		set names  [lreplace $names  $where $where]
		set values [lreplace $values $where $where]
	    } else {
		lappend orderedValues ""
		lappend orderedNames  $f
	    }
	    # Make sure that we're using our recognized field name.
	    if {[catch {Bib::isValidField $f} fieldName]} {
		set fieldName $f
	    }
	    if {[info exists Bib::UseBrace($fieldName)]} {
		set braces([string tolower $f]) [set Bib::UseBrace($fieldName)]
	    } else {
		set braces([string tolower $f]) 1
	    }
	}
    } else {
	foreach f $names {
	    # Make sure that we're using our recognized field name.
	    if {[catch {Bib::isValidField $f} fieldName]} {
		set fieldName $f
	    }
	    if {[info exists Bib::UseBrace($fieldName)]} {
		set braces([string tolower $f]) [set Bib::UseBrace($fieldName)]
	    } else {
		set braces([string tolower $f]) 1
	    }
	}
    }
    # Upcase if desired.
    if {$BibmodeVars(upperCaseFields)} {
	set orderedNames [string toupper $orderedNames]
	set names        [string toupper $names]
    } else {
	set newNames        [list]
	set newOrderedNames [list]
	foreach f $names {
	    if {[catch {Bib::isValidField $f} field]} {
		set field [string tolower $f]
	    } 
	    lappend newNames $field
	}
	set names $newNames
	foreach f $orderedNames {
	    if {[catch {Bib::isValidField $f} field]} {
		set field [string tolower $f]
	    } 
	    lappend newOrderedNames $field
	}
	set orderedNames $newOrderedNames
    }
    if {$BibmodeVars(upperCaseEntries)} {
	set type         [string toupper $type]
    } else {
	if {[catch {Bib::isValidEntry $type} newType]} {
	    set newType $type
	}
	set type $newType
    }
    set names  [concat [list "type" "citeKey"] $orderedNames  $names]
    set values [concat [list $type  $citeKey]  $orderedValues $values]
    # Find the longest field length.
    foreach f $names {
	if {[set fieldLength [string length $f]] > $length} {
	    set length $fieldLength
	}
    }
    if {$BibmodeVars(wrappedFields)} {
	set leftCol  [expr {[string length ${Bib::Indent}] + $length + 4}]
	set rightCol $BibmodeVars(fillColumn)
    }
    # Format first line
    set lines "@[lindex $values 0][set Bib::OpenEntry]${citeKey},\r"
    if {![info exists Bib::RqdFlds($entryType)]} {set entryType "misc"} 
    # Format each field on a separate line.  We start with ifld 2 because
    # 0 is the type, and 1 is the citeKey.
    for {set fldIndex 2} {$fldIndex < [llength $names]} {incr fldIndex} { 
	set field [lindex $names  $fldIndex]
	set value [lindex $values $fldIndex]
	# Now we take care of the case that all of 
	# 
	# (1) "zapEmptyFields" is on,
	# (2) there is an empty field present, and
	# (3) "entryType" is not a default entry.
	# 
	# We can do this since entryType is already set into the $lines. 
	# The result will be to zap all empty fields, since none will be
	# required.  If we don't do this, the proc fails ...
	set test1 $BibmodeVars(zapEmptyFields)
	set test2 [lcontains Bib::RqdFlds($entryType) $field]
	if {$value != "" || !$test1 || $test2} {
	    set pad [expr $length - [string length $field]]
	    if {$BibmodeVars(alignEquals)} {
		set pref "[set Bib::Indent]$field[string range $spc 1 $pad] ="
	    } else {
		set pref "[set Bib::Indent]$field =[string range $spc 1 $pad]"
	    }
	    # Delimit field, if appropriate
	    if {[info exists braces([string tolower $field])]} {
		set brace $braces([string tolower $field])
	    } else {
		set brace 1
	    }
	    set test1   [is::UnsignedInteger $value]
	    set test2   [regexp {[^\\]\#} $value] 
	    set noBrace [expr ($brace == 0 && $test1) || $test2]
	    if {$noBrace == 0 && [string first " " $value] < 0} {
		set noBrace [expr {[lsearch $strings $value] >= 0}]
	    }
	    if {$noBrace != 0} {
		set value "$value,"
	    } else {
		# Do we auto capitalize the field value?
		if {[lsearch $autoCapFields [string tolower $field]] != "-1"} {
		    set value [Bib::capitalizeString $value]
		} 
		set value [string trim $value]
		set value "[set Bib::OpenQuote]${value}[set Bib::CloseQuote],"
	    }
	    # Do we break the content into lines?
	    if {$BibmodeVars(wrappedFields)} {
	        set value [breakIntoLines $value $rightCol $leftCol]
	    }
	    append lines "$pref [string trim $value]\r"
	}
    }
    append lines "[set Bib::CloseEntry]\r"
    return $lines
}

# ===========================================================================
# 
# Capitalize All Words in a String That Aren't Special.
# 

proc Bib::capitalizeString {str} {
    
    if {![catch {Bib::_capitalizeString $str} result]} {
	return $result
    } else {
	return $str
    }
}

# ===========================================================================
# 
# These will only be capitalized if at the beginning of the string, or just
# after a ':' or ';' (denoted by the 'start' var).  If the string has
# double quotes or braces, this might fail, so its a good idea to catch
# this and only use the result if it doesn't fail.
# 

proc Bib::_capitalizeString {str} {
    
    global BibmodeVars

    # Deal with isolated ':', ':'
    regsub -all "\[\t \]+(:|;)\[\t \]+" $str "\\1 " str
    # If the string is ALL CAPS, assume that this isn't intended and make
    # the string lower case first.
    if {[string toupper $str] == $str} {
	set str [string tolower $str]
    } else {
	# Protect ALL CAP words. 
	set pat "(^|\[\r\n\t \])(\[A-Z\]\[A-Z\]+)($|\[\r\n\t \])"
	regsub -all $pat $str "\\1\{\\2\}\\3" str
    }

    # These will only be capitalized if at the beginning of the string, or
    # just after a ':' or ';' (denoted by the 'start' var).
    set lower $BibmodeVars(autoCapForceLower)
    # These are special cases defined by the user.
    foreach pair $BibmodeVars(autoCapSpecialPatterns) {
	set specialPats([lindex $pair 0]) [lindex $pair 1]
    }

    # 'parts1' will be the entire string split by ";"
    set parts1 [list]
    foreach part1 [split $str ";"] {
	# 'parts2' will be each part1 section split by ":"
	set parts2 [list]
	foreach part2 [split $part1 ":"] {
	    set start 1
	    # 'parts3' will be each part2 section split by " ", so this
	    # should be each word.
	    set parts3 [list]
	    foreach part3 [split $part2 " "] {
		# 'parts4' will be each word split by "-"
		set parts4 [list]
		foreach part4 [split $part3 "-"] {
		    # Is it an acronym?
		    if {[regexp {^([a-zA-Z]\.)+$} $part4]} {
			# If so, make it A.L.L.C.A.P.S.
			set part4 [string toupper $part4]
		    }
		    # Almost ready ... special "l'Ancien" case.
		    set l [regsub {^[lL]'} $part4 "" part4]
		    # ... remove any leading brackets, etc.
		    set pat1 {^([^a-zA-Z]*)([a-zA-Z]*)([^a-zA-Z]*)$}
		    set pre  [set post ""]
		    regexp $pat1 $part4 allofit pre part4 post
		    # Deal with special patterns first.
		    foreach pattern [array names specialPats] {
			set subString $specialPats($pattern)
			if {[regsub "^$pattern" $part4 $subString part4]} {
			    break
			} 
		    }
		    # Now capitalize the word.  Maybe.
		    if {![regexp {^[a-z]+$} $part4] || [regexp {\\\{} $pre]} {
			# Not a lower case string, or there's an escape
			# char which might be a TeX markup tag, or it is
			# otherwise protected.
			set first $part4 ; set rest ""
		    } elseif {!$start && [lsearch $lower $part4] != "-1"} {
			# A special lower case string, and we're not at the
			# start of the line or a clause.
			set first $part4 ; set rest ""
		    } else {
			# All special cases done, capitalize the word.
			set first [string toupper [string index $part4 0]]
			set rest  [string tolower [string range $part4 1 end]]
		    }
		    # Now deal with "l'Ancien" type constructions.
		    if {$l} {
			if {$start} {
			    set pre "L'$pre"
			} else {
			    set pre "l'$pre"
			}
		    }
		    set start 0
		    lappend parts4 ${pre}${first}${rest}${post}
		}
		lappend parts3 [join $parts4 "-"]
	    }
	    lappend parts2 [join $parts3 " "]
	}
	lappend parts1 [join $parts2 ":"]
    }
    set result [join $parts1 ";"]
}

# ==========================================================================
# 
# .