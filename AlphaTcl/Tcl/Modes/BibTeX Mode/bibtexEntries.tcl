## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexEntries.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 03/21/2006 {02:52:27 PM}
 # Description: 
 # 
 # Menu item procedures that pertain to entry/field creation, navigation,
 # and other miscellaneous operations.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexEntries.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Entry, Field support ×××× #
# 
# The procs in this section do NOT call anything else in this package other
# than search patterns.  A handy thing to know to avoid falling into
# recursive traps ...
# 

# ===========================================================================
# 
# Return the bounds of the bibliographic entry surrounding the current
# position.
#

proc Bib::entryLimits {pos {quietly 0}} {

    global Bib::TopPat

    if {![catch {search -s -f 0 -r 1 [set Bib::TopPat] $pos} results]} {
	set pos0 [lineStart [lindex $results 0]]
	set pos1 [lindex $results 1]
	if {[catch {matchIt [lookAt [pos::math $pos1 - 1]] $pos1} pos2]} {
	    if {!$quietly} {
		set    alert "There seems to be a badly delimited field in here.\r"
		append alert "Entry or field delimiters might be set incorrectly."
		alertnote $alert
	    } 
	    goto $pos0
	    error "Can't find close brace, line [lindex [pos::toRowChar $pos0] 0]"
	} else {
	    set pos2 [nextLineStart $pos2]
	}
    } else {
	set pos0 [nextLineStart $pos]
	set pos2 $pos0
    }
    return [list $pos0 $pos2]
}

proc Bib::isInEntry {pos} {
    
    if {![catch {Bib::entryLimits $pos 1} limits]} {
	set pos0 [lindex $limits 0]
	set pos1 [lindex $limits 1]
	if {[pos::compare $pos >= $pos0] && [pos::compare $pos < $pos1]} {
	    return [list $pos0 $pos1]
	} else {
	    error  "Position $pos is not in an entry."
	}
    } else {
	error  "Position $pos is not in an entry."
    }
}

proc Bib::nextEntryStart {pos} {

    global Bib::TopPat
    
    if {![catch {Bib::entryLimits $pos 1} limits]} {
	set pos [lindex $limits 1]
    }
    if {![catch {search -f 1 -r 1 -s [set Bib::TopPat] $pos} match]} {
	set nextPos [lindex $match 0]
    } else {
	set nextPos [maxPos]
    }
    if {[regexp -nocase {^\s*@string} [getText $nextPos [pos::lineEnd $nextPos]]]} {
	return [Bib::nextEntryStart [pos::nextLineStart $pos]]
    } else {
        return $nextPos
    }
}

proc Bib::entryFields {entryName} {
    
    global BibmodeVars Bib::RqdFlds Bib::MyFlds

    if {[catch {Bib::isValidEntry $entryName} entryName]} {
	return [list]
    } 
    set customEntryName [Bib::entryPrefConnect $entryName]
    if {[info exists Bib::MyFlds($entryName)] && [llength [set Bib::MyFlds($entryName)]]} {
	# First see if this is a user defined entry with at least one field.
	set fieldList [set Bib::MyFlds($entryName)]
    } elseif {[info exists BibmodeVars($customEntryName)]} {
	# Then check for a customEntryName preference for the entry.
	set fieldList $BibmodeVars($customEntryName)                
    } elseif {[info exists Bib::RqdFlds($entryName)]} {
	# Or the list defined by Bib::RqdFlds().
	set fieldList [set Bib::RqdFlds($entryName)]
    } else {
	# Oh well...  we tried.
	set fieldList {}
    }
}

proc Bib::fieldLimits {pos} {
    
    if {![catch {Bib::isInEntry $pos} limits]} {
	set pos0 [nextLineStart [lindex $limits 0]]
	set pos1 [lineStart [pos::math [lindex $limits 1] - 1]]
	return [list $pos0 $pos1]
    } else {
	error "Not in an entry."
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "Bib::getFields" --  pos ?wrapData? ?leftCol? ?rightCol?
 # 
 # Return a two item list containing the field names and values for the entry
 # found in position "pos".  The entry's "type" and "citeKey" are the first
 # two items in each list.  If the entry is a "@string" type then the second 
 # item in the lists are "value / <string contents>".
 # 
 # Optional arguments can specify that the contents of the fields should be
 # wrapped (broken into lines), with values for left and right columns.  If
 # "wrapData" is set then we return a very crude approximation of the
 # formatting used by calling [Bib::formatEntry] with "wrappedFields" set.
 # 
 # This requires an entry to be in the proper BibTeX syntax.  And just what
 # is that?  Our specification attempts to mirror all of the possible cases,
 # not just our particular "formatting" results style.   Specifically,
 # 
 # * An entry starts with @<entryType>.
 # * The "entryType" is not case sensitive.
 # * Whitespace might occur before the entry delimiter.
 # * The entry delimiters can be {} or ().
 # * Whitespace might occur after the opening/closing entry delimiters.
 # * The first item is the cite key, and it cannot contain whitespace.
 # * The citeKey must be followed by a comma.
 # * Whitespace might occur after each field name.
 # * Field names are not case sensitive.
 # * Each field name is followed by "=", and possible more whitespace.
 # * Field values are delimited by {} or "" or are simply strings.
 # * Inside the braces, you can have arbitrarily nested pairs of  braces.
 # * But braces must also be balanced inside quotes!
 # * Inside quotes, if you want to use the " character, it is not sufficient
 #   to simply escape with  \". You must place the quotes inside braces.
 # * You can have a @ inside a quoted values but not  inside a braced value.
 # * All field values not delimited by {} or "" must be strings which are
 #   concatenated by "#".
 # * All field/value sets must be separated by a comma.
 # * The last f/v set does not have to end with a comma.
 # 
 # This information really belongs in "bibtexMode.tcl" somewhere.  Some of it
 # was lifted from
 # 
 # <http://artis.imag.fr/Membres/Xavier.Decoret/resources/xdkbibtex/bibtex_summary.html>
 # 
 # though there's probably a more official syntax specification somewhere.
 # 
 # --------------------------------------------------------------------------
 # 
 # During the routine below, we attempt to find the entry at position "pos"
 # and parse the string to determine the entry's "type" and "citeKey".  We
 # then find a field name, and determine the field delimiter character (which
 # might be the null string.)  Based on the delimiter, we find out where the
 # field value ends, add the name and value to our results, and move on.  If
 # we cannot find any more fields and we still have some text in the parsing
 # string then we have a malformed entry, and we throw an error.
 # 
 # --------------------------------------------------------------------------
 ##

proc Bib::getFields {pos {wrapData 0} {leftCol 6} {rightCol 72}} {

    variable TopPat2
    variable TopPat3
    
    if {$wrapData && ($rightCol <= $leftCol)} {
	set rightCol [expr {$leftCol + 20}]
    } 
    # Get our initial entry, and massage the whitespace.
    set oldEntry [eval [list getText] [Bib::isInEntry $pos]]
    regsub -all {\s+}         $oldEntry { } oldEntry
    regsub -all {[\t ][\t ]+} $oldEntry { } oldEntry
    regsub {[,\s]*[\)\}]\s*$} $oldEntry { } oldEntry
    # Grab the "type", "citeKey", and "theRest"
    if {[regexp -indices $TopPat2 $oldEntry match theType theKey ]} {
	set key [string range $oldEntry [lindex $theKey 0] [lindex $theKey 1]]
	set theRest [string range $oldEntry [expr {[lindex $match 1] + 1}] end]
    } elseif {[regexp -indices $TopPat3 $oldEntry match theType fieldInfo]} {
	set key {}
	set theRest [string range $oldEntry [lindex $fieldInfo 0] end]
    } else {
	error "Invalid entry"
    }
    set type [string range $oldEntry [lindex $theType 0] [lindex $theType 1]]
    # Start to create our list of results.
    set fieldNames  [list "type" "citeKey"]
    set fieldValues [list $type  $key]
    # Special case for @string entries.
    if {([string tolower $type] eq "string")} {
	regsub {=\s*} [string trim $theRest] {} value
	lappend fieldNames  "value"
	lappend fieldValues $value
        return [list $fieldNames $fieldValues]
    } 
    # Scan "theRest" to get remaining fields and values.  Once the field name
    # has been determined, we look for a proper "openTag" and then scan
    # "theRest" to find the proper close tag for that field.
    append theRest " ,"
    set fieldData  [string trim $theRest]
    set fldNamePat {^\s*,\s*([a-zA-Z0-9]+)\s*=\s*([\{\"])?(.+)}
    while {[regexp $fldNamePat $fieldData -> name openTag theRest]} {
	set fieldValue ""
	lappend fieldNames $name
	switch -- $openTag {
	    "\"" {
		set pat {([^\{]\".?)}
		regexp -indices $pat $theRest -> match
		set fieldValue [string range $theRest 0 [lindex $match 0]]
		if {[string match {*\\"*} $fieldValue]} {
		    error "cannot escape quotes in quoted fields, use \{\"\}"
		} 
		set theRest [string range $theRest [lindex $match 1] end]
	    }
	    "\{" {
		set braces 1
		set pat {(([^\\\{]?\{)|([^\\\}]?\}))}
		set idx1 0
		while {($braces > 0)} {
		    regexp -indices $pat $theRest -> match
		    set idx1 [lindex $match 1]
		    set idx2 [expr {$idx1 + 1}]
		    append fieldValue [string range $theRest 0 $idx1]
		    switch -- [string index $theRest $idx1] {
			"\{" {
			    incr braces 1
			}
			"\}" {
			    incr braces -1
			}
			default {
			    break
			}
		    }
		    set theRest [string range $theRest $idx2 end]
		}
		set fieldValue [string range $fieldValue 0 end-1]
		if {[string match {*@*} $fieldValue]} {
		    error "'@' cannot appear in braced fields, only in quoted fields"
		} 
	    }
	    "" {
		set pat {\s*(,|$)}
		regexp -indices $pat $theRest -> match
		set idx1 [expr {[lindex $match 1] - 1}]
		set idx2 [expr {[lindex $match 1]}]
		set fieldValue [string range $theRest 0 $idx1]
		# At this point our field value should be a list that is
		# concatenated by "#".  If not, there is an error.
		if {([expr {[llength $fieldValue] % 2}] != 1)} {
		    error "improper string concatenation: $fieldValue"
		} 
		for {set i 1} {($i < [llength $fieldValue])} {incr i 2} {
		    if {([lindex $fieldValue $i] ne "\#")} {
			error "improper string concatenation: $fieldValue"
		    } 
		}
		set theRest [string range $theRest $idx2 end]
	    }
	    default {
		error "unknown field delimiter: $openTag
	    }
	}
	# Add this field's information to our results.
	set fieldValue [Bib::bibFieldData $fieldValue]
	if {$wrapData} {
	    set fieldValue [breakIntoLines $fieldValue $rightCol $leftCol]
	}
	lappend fieldValues $fieldValue
	set fieldData [string trim $theRest]
    }
    regsub {,*\s*$} $fieldData {} fieldData
    # If we made it this far, then our parsing string should be empty.  If
    # this is not the case, we have a malformed entry.
    if {[string length $fieldData]} {
	error "malformed entry, at or just before \"$fieldData\""
    } 
    return [list $fieldNames $fieldValues]
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

proc Bib::bibFieldData {text} {

    set text [string trim $text]
    # Preserve an entire {{Odd Name}} or "{Odd Name}" or {"Odd Name"} field.
    if {[regexp {(^(\{|\")\{.+\}(\}|\")$)} $text]} {
	regsub {^(\{|\")} $text {} text
	regsub {(\}|\")$} $text {} text
	return $text
    } 

    set text  [string trim $text {   ,#}]
    set text1 [string trim $text {\{\}\" }]
    
    if {[string match {*[\{\}\"]*} $text1]} {
	set words [parseWords $text]
	if {[llength $words]==1} {
	    regsub {^[\{\"\']} $text {} text
	    regsub {[\}\"\']$} $text {} text
	}
    } else {
	set text $text1         
    }
    return $text
}

proc Bib::nearestEntryField {pos} {
    
    global Bib::OpenEntry
    
    set posBeg [set posEnd $pos]

    set txt  ""
    set pos1 [pos::math [nextLineStart $pos] - 1]
    set pat1 {(@[a-zA-Z]+)}
    set pat2 {([a-zA-Z]+)}
    set pat3 {^[\t ]*}
    
    append pat3 "(($pat1\\[set Bib::OpenEntry])|"
    append pat3 "($pat2\[\t \]+=\[\t \]+))"
    
    if {![catch {search -s -f 0 -r 1 -i 1 $pat3 $pos1} match1]} {
	set txt [getText [set pos2 [lindex $match1 0]] [lindex $match1 1]]
	foreach pat [list $pat1 $pat2] {
	    if {[regexp -indices $pat $txt match2]} {
		set posBeg [pos::math $pos2 + [lindex $match2 0]]
		set posEnd [pos::math $posBeg + [lindex $match2 1] + 1]
		regsub {[^a-zA-Z]+$} [getText $posBeg $posEnd] "" txt
		set posEnd [pos::math $posBeg + [string length $txt]]
		break
	    }
	}
    } 
    return [list $txt $posBeg $posEnd]
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× New Entries, Fields ×××× #
#

# (In Alpha7 the menu might send "Custom Entry" as the $itemName if the menu
# list is long...)
	
proc Bib::entriesProc {menuName itemName} {
    
    Bib::BibModeMenuItem
    
    if {$menuName == "entries" && [getModifiers]} {
	Bib::editEntryFields $itemName
    } elseif {$itemName == "customEntry" || $itemName == "Custom Entry"} {
	Bib::customEntry
    } else {
	Bib::newEntry $itemName
    } 
}

# ===========================================================================
# 
# Create a custom bibliographic entry with user specified fields.
#

proc Bib::customEntry {} {
    
    global Bib::OpenEntry Bib::CloseEntry
    
    goto [lindex [Bib::entryLimits [getPos]] 1]
    set results   [Bib::addCustomEntry 0]
    set entryName [lindex $results 0]
    set fieldList [lindex $results 1]
    # Append the fields, all nicely formatted.
    set lines "@${entryName}[set Bib::OpenEntry]¥¥,\r"
    set length 0
    foreach field $fieldList {
	set fieldLength [string length $field]
	if {$fieldLength > $length} {set length $fieldLength}     
    }
    foreach field $fieldList {
	catch {append lines [Bib::newField $field $length]}
    }
    # Wrap it up.
    append lines "[set Bib::CloseEntry]\r"
    elec::Insertion $lines
}

# ===========================================================================
# 
# Create a new bibliographic entry with its required fields.
#

proc Bib::newEntry {entryName} {
    
    global BibmodeVars Bib::OpenEntry Bib::CloseEntry \
      Bib::OpenQuote Bib::CloseQuote

    # First upcase if desired.
    set entryname $entryName
    if {$BibmodeVars(upperCaseEntries)} {
	set entryName [string toupper $entryName]
    } 
    set citeKey "¥¥"
    set fields  [Bib::entryFields $entryName]
    # Do we have a selection highlighted?  If so, we'll use that for the
    # default field entries.
    if {[isSelection]} {
	regsub -all "(\r)?\n" [getSelect] "\r" defaultFieldValues
	set defaultFieldValues [split $defaultFieldValues "\r"]
	deleteSelection
    } else {
	set defaultFieldValues [list]
    }
    # Are we currently in an entry?
    set pos    [getPos]
    if {[catch {Bib::entryLimits $pos 1} limits]} {set limits [list $pos $pos]} 
    set pos0   [lindex $limits 0]
    set pos1   [lindex $limits 1]
    if {[pos::compare  $pos > $pos0] && [pos::compare  $pos < $pos1]} {
	goto $pos1
    } else {
	goto [lineStart $pos]
    }
    if {[string tolower $entryName] == "string"} {
	# A special case for strings.
	elec::Insertion "@${entryName}[set Bib::OpenEntry]¥¥ = [set Bib::OpenQuote]¥¥[set Bib::CloseQuote][set Bib::CloseEntry]\r¥¥"
	return
    } 
    set lines "@${entryName}[set Bib::OpenEntry]${citeKey},\r"

    # Append the fields, all nicely formatted.
    set length 0
    foreach field $fields {
	set fieldLength [string length $field]
	if {$fieldLength > $length} {set length $fieldLength}     
    }
    set count 0
    foreach field $fields {
	set value [string trim [lindex $defaultFieldValues $count]]
	catch {append lines [Bib::newField $field $length $value]}
	incr count
    }
    # Wrap it up.
    append lines "[set Bib::CloseEntry]"
    # Do we need an extra carriage return at the end?
    set line [getText [getPos] [nextLineStart [getPos]]]
    if {![regexp "^\[\r\n\t \]*$" $line]} {
	append lines "\r"
    } 
    elec::Insertion $lines
}

# ===========================================================================
# 
# Create a new field within the current bibliographic entry.  This includes
# the options for creating a user defined fields, or choosing multiple
# fields.  (In Alpha7 the menu might send "Custom Field" or "Multiple
# Fields" as the $item if the menu list is long...)
#

proc Bib::fieldsProc {menuName itemName} {
    
    Bib::BibModeMenuItem

    global BibmodeVars Bib::Fields Bib::OpenEntry Bib::CloseEntry
    
    if {$menuName == "fields" && [getModifiers]} {
	Bib::editPreference "addFields" "Edit the \"Add Fields\" preference:" 1
	Bib::updatePreferences addFields
	status::msg "The custom fields include \"$BibmodeVars(addFields)\""
    } 
    if {$itemName == "customField" || $itemName == "Custom Field"} {
	# Prompt for name of new field, offer to include it in prefs.
	set newFieldName [prompt "Enter the new field's name:" ""]
	if {[askyesno "Do you want to make \"$newFieldName\" a default menu item?\
	  \rIt will then be available as an electric completion, too."] == "yes"} {
	    if {[regsub { } $newFieldName {} dummy]} {
		error "Cancelled -- no spaces allowed in field names !!"
	    } 
	    # Check to make sure that the first word is not Capitalized.
	    set first [string tolower [string index $newFieldName 0]]
	    if {$first != [set First  [string index $newFieldName 0]]} {
		set newFieldName [concat $first[string range $newFieldName 1 end]]
		dialog::alert "The new entry will be \"$newFieldName\""
	    } 
	    if {[set type [Bib::checkKeywords $newFieldName 1]] != 0} {
		dialog::alert "\"$newFieldName\" is already defined\
		  in the $type list"
	    } else {
		append BibmodeVars(addFields) " $newFieldName"
		set BibmodeVars(addFields) [lsort $BibmodeVars(addFields)]
		prefs::modified BibmodeVars(addFields)
		Bib::updatePreferences addFields
	    }
	} 
	set lines [Bib::newField $newFieldName]
    } elseif {$itemName == "multipleFields" || $itemName == "Multiple Fields"} {
	# Prompt for several fields to be inserted at once.
	set flds [listpick -l -L {author year} -p \
	  "Pick desired fields:" [set Bib::Fields]]
	if {[llength flds]} {
	    set lines {}
	    foreach fld $flds {append lines [Bib::newField $fld]}
	} else {
	    return
	}
    } else {
	# Else, prepare to insert a field, no questions asked.  Also no
	# length (pad) specified -- entry will just have to be reformatted.
	# Use any highlighted text for the default value.
	if {[isSelection]} {
	    set value [string trim [getSelect]] ; deleteSelection
	} else {
	    set value ""
	}
	set lines [Bib::newField $itemName 0 $value]
    }
    # Where are we?
    set pos  [getPos]
    set pos0 [lineStart  $pos]
    set pos1 [pos::math  $pos0 + [string length $BibmodeVars(indentString)]]
    if {![catch {Bib::entryLimits $pos 1} limits]} {
	set pos2 [lindex $limits 0]
	set pos3 [lindex $limits 1]
    } else {
	set pos2 [nextLineStart $pos]
	set pos3 [nextLineStart [nextLineStart $pos]]
    }
    # Where should we go?  Have to handy several different cases here,
    # because we might be building an entry as we go, or adding to an
    # existing entry, or in the middle of a field somewhere ...
    if {[catch {Bib::nextField} pos4] && ![regexp " *[set Bib::CloseEntry]\[\r\n\]*" [getText $pos0 $pos2]]} {
	set pos4 [nextLineStart $pos]
    } 
    if {[pos::compare $pos >= $pos0] && [pos::compare $pos <= $pos1]} {
	# Are we at the start of a line, or at least within the parameter
	# set by the "indentString" pref?  If so, put the new field here.
	goto $pos0

    } elseif {[pos::compare $pos4 > $pos2] && [pos::compare $pos4 < $pos3]} {
	# The 'next' field is within this entry, so put the new field in
	# front of it.
	goto [lineStart $pos4]
    } else {
	# Otherwise, put it at the end the current entry.
	goto [lineStart [pos::math $pos3 - 1]]
    }
    # Do we really need that extra carriage return at the end?
    if {[regexp {^[\r\n\t ]*$} [getText [getPos] [nextLineStart [getPos]]]]} {
	set lines [string trimright $lines]
    } 
    elec::Insertion $lines
}

proc Bib::newField {fieldName {length 0} {value ""}} {
    
    global BibmodeVars Bib::OpenQuote Bib::CloseQuote Bib::Indent
    global Bib::DefaultFields Bib::UseBrace Bib::FieldDefs Bib::DefFldVal 
    
    
    # First upcase if desired.
    if {$BibmodeVars(upperCaseFields)} {
	set field [string toupper $fieldName]
    } else {
	set field $fieldName
    }
    # Now make sure that we're using our recognized field name.
    if {[catch {Bib::isValidField $fieldName} fieldName]} {
	set fieldName $field
    }

    set spc "                   "
    
    # Need braces?
    if {[lsearch -exact [set Bib::DefaultFields] $fieldName] >= 0} {
	set needBraces [set Bib::UseBrace($fieldName)]
    } else {
	set needBraces 1
    }
    # Any default values?
    if {![string length $value]} {
	if {[lcontains Bib::FieldDefs $fieldName]} {
	    set value [set Bib::DefFldVal($fieldName)]
	} else {
	    set value "¥¥"
	}
    }
    # Were we given a length to use for a pad?
    if {$length} {
	set pad [string range $spc 1 [expr \
	  {$length - [string length $fieldName]}]]
    } else {
	set pad ""
    }
    # Return the field to the proc that called this one.
    if {$needBraces} {
	return \
	  "[set Bib::Indent]$field =$pad [set Bib::OpenQuote]${value}[set Bib::CloseQuote],\r"
    } else {
	return \
	  "[set Bib::Indent]$field =$pad $value,\r"
    }   
}

# ===========================================================================
# 
# Find the next field in the file.  It is up to the calling proc to
# determine if it is in the current entry.
# 

proc Bib::nextField {{pos ""}} {
    
    if {![string length $pos]} {set pos [getPos]}
    set pos [nextLineStart $pos]
    set pat {^[\t ]*[a-zA-Z]+[\t ]*=[\t ]*}
    if {![catch {search -f 1 -r 1 -s $pat $pos} match]} {
	set pos0 [lindex $match 0]
	set lwhite [text::indentString $pos0]
	return [pos::math $pos0 + [string length $lwhite]]
    } else {
	error "No next field found."
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Navigation, etc ×××× #
#

# ===========================================================================
# 
# Advance to the next bibliographic entry.
#

proc Bib::nextEntry {{quietly 0} {insertTo 0}} {
    
    Bib::BibModeMenuItem
    
    global Bib::TopPat
    
    set posBeg  [getPos]
    set posEnd  [selEnd]
    if {![catch {Bib::entryLimits $posEnd 1} limits]} {
	set pos0 [lindex $limits 1]
    } else {
	set pos0 $posBeg
    }
    set pos1    $pos0
    set nextPos [lineStart $pos1]

    while {![catch {search -f 1 -r 1 -s [set Bib::TopPat] $pos1} pos]} {
	regexp [set Bib::TopPat] [eval getText $pos] match type
	if {$type != "string"} {
	    set nextPos [lindex $pos 0]
	    break
	} else {
	    set pos1 [nextLineStart [lindex $pos 1]]
	}
    }
    if {![catch {Bib::entryLimits $nextPos 1} limits]} {
	set pos2 [lindex $limits 1]
    } else {
	set pos2 $posEnd
    }
    if {[isSelection]} {
	if {[pos::compare $posEnd < $pos0]} {
	    selectText $posBeg $pos0
	} else {
	    selectText $posBeg $pos2
	}
	status::msg ""
    } elseif {[pos::compare $posEnd == $pos2]} {
	status::msg "No further entries in this file."
	return ""
    } else {
	goto $nextPos
	if {[catch {Bib::getCiteKey} nextEntry]} {set nextEntry ""}
	if {$quietly} {return [list $nextPos $nextEntry]}
	status::msg "$nextEntry"
	if {$insertTo == 1} {insertToTop} elseif {$insertTo == 2} {centerRedraw}
    }
}

# ===========================================================================
# 
# Go back to the previous bibliographic entry.
#

proc Bib::prevEntry {{quietly 0} {insertTo 0}} {
    
    Bib::BibModeMenuItem
    
    global Bib::TopPat
    
    set posBeg [getPos]
    set posEnd [selEnd]
    if {![catch {Bib::entryLimits $posBeg 1} limits]} {
	set pos0 [lindex $limits 0]
	set pos1 [lindex $limits 1]
    } else {
	set pos0 $posBeg
	set pos1 $posEnd
    }
    set prevPos $pos0
    if {[pos::compare $pos0 > [minPos]] && [pos::compare $pos0 >= $posBeg]} {
	set pos0 [pos::math $pos0 - 1]
	while {![catch {search -f 0 -r 1 -s [set Bib::TopPat] $pos0} pos]} {
	    regexp [set Bib::TopPat] [eval getText $pos] match type
	    if {$type != "string"} {
		set prevPos [lindex $pos 0]
		break
	    } else {
		set pos0 [lineStart [lindex $pos 0]]
		if {[pos::compare $pos0 == [minPos]]} {break}
		set pos0 [pos::math $pos0 - 1]
	    }
	}
    }
    if {[isSelection]} {
	selectText $prevPos $posEnd
	status::msg ""
    } elseif {[pos::compare $posBeg == $prevPos]} {
	status::msg "No further entries in this file."
	return ""
    } else {
	goto $prevPos
	if {[catch {Bib::getCiteKey} prevEntry]} {set prevEntry ""}
	if {$quietly} {return [list $prevPos $prevEntry]}
	status::msg "$prevEntry"
	if {$insertTo == 1} {insertToTop} elseif {$insertTo == 2} {centerRedraw}
	return $prevEntry 
    }
}

# ===========================================================================
# 
# Use 1 and 3 on the keypad to navigate.
#

proc Bib::searchFunc {direction} {
    
    if {$direction} {Bib::nextEntry 0 2} else {Bib::prevEntry 0 2}
}


proc Bib::foldableRegion {pos} {
    
    if {![catch {Bib::fieldLimits $pos} limits]} {
	set pos0 [lindex $limits 0]
	set pos1 [pos::prevLineEnd [lindex $limits 1]]
	return [list $pos0 $pos1]
    } else {
	error $limits
    }
}

proc Bib::foldEntry {} {menu::generalProc "Edit" "fold"}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Cycling Entries/Fields ×××× #
# 
# Based on "latexSizes.tcl"

array set Bib::CycleEntriesFields {
    
    "people" {
	author editor
    }
    "publication" {
	address city howpublished institution organization school publisher
    }
    "dates" {
	date month year
    }
    "numbers" {
	chapter edition isbn issn lccn number pages series volume
    }
    "notes" {
	abstract annote contents key note
    }
    "titles" {
	booktitle journal title
    }
}

# Used to remember the last position.
set Bib::LastCyclePos [minPos]

proc Bib::cycleList {inc} {
    
    global Bib::CycleEntriesFields Bib::LastCyclePos \
      BibmodeVars Bib::Fields Bib::Entries
    
    catch {unset Bib::CycleEntriesFields(miscFields)}
    catch {unset Bib::CycleEntriesFields(entryTypes)}
    
    set miscFields [set Bib::Fields] ; set notMisc [list "type"]
    foreach fieldName [set Bib::Fields] {
	foreach type [array names Bib::CycleEntriesFields] {
	    if {[lsearch [set Bib::CycleEntriesFields($type)] $fieldName] != "-1"} {
		lappend notMisc $fieldName
	    }
	}
    }
    set Bib::CycleEntriesFields(miscFields) [lremove -all $miscFields $notMisc]
    foreach entryType [set Bib::Entries] {
	lappend Bib::CycleEntriesFields(entryTypes) "@$entryType"
    }

    set len0 [string length [getSelect]]
    if {[pos::compare [getPos] != [set Bib::LastCyclePos]]} {
	# The first time we're called, we just present the list.
	set inc 0
    } 
    set result [Bib::nearestEntryField [set pos [getPos]]]
    if {![string length [set txt [lindex $result 0]]]} {
	status::msg "Could not find any Bib keyword in the surrounding text."
	return
    } 
    set txt    [string tolower $txt]
    set posBeg [lindex $result 1]
    set posEnd [lindex $result 2]
    if {[pos::compare $posEnd < $pos]} {
	# The end of the command is to the left of the current position,
	# so we must be within some braces.
	set awayFromCommand [pos::diff $posBeg $pos]
    } 
    # Does it belong to any list?
    if {[regexp {@([a-zA-Z]+)} $txt allofit type]} {
        set optionType "entryTypes"
	set idx [lsearch [string tolower [set Bib::Entries]] $type]
    } else {
	foreach optionType [array names Bib::CycleEntriesFields] {
	    if {[set idx [lsearch [set Bib::CycleEntriesFields($optionType)] $txt]] != "-1"} {
		break
	    } 
	}
    }
    if {$idx == "-1"} {
	# We cycled through all of them and didn't find any.
	status::msg "'$txt' was not found in any Bib keywords list."
	return
    } 
    # Do we have a replacement?
    set newString [lindex [set Bib::CycleEntriesFields($optionType)] [incr idx $inc]]
    if {$optionType == "entryTypes"} {
        if {$BibmodeVars(upperCaseEntries)} {
	    set newString [string toupper $newString]
	}
    } elseif {$BibmodeVars(upperCaseFields)} {
	set newString [string toupper $newString]
    }
    set offset [string length $newString]
    if {![string length $newString]} {
	# We reached the end of the line.
	status::msg "No further options beyond '$txt'"
	return
    } elseif {$newString == {[delete]}} {
	deleteText $posBeg $posEnd
	status::msg "'$txt' has been deleted."
	return
    } elseif {$inc != "0"} {
	replaceText $posBeg $posEnd $newString
    }
    # Go to where we were, and remember this position.
    if {[info exists awayFromCommand]} {
	set len1 [string length $txt]
	set len2 [string length $newString]
	set pos4 [pos::math $posBeg - $len1 + $len2 + $awayFromCommand]
	selectText $pos4 [pos::math $pos4 + $len0]
	set Bib::LastCyclePos $pos4
    } elseif {[pos::compare $pos > [set posEnd [pos::math $posBeg + $offset]]]} {
	goto [set Bib::LastCyclePos $posEnd]
    } else {
	goto [set Bib::LastCyclePos $pos]
    }
    # Display the new position in the order.
    set options [set Bib::CycleEntriesFields($optionType)]
    set options [lreplace $options $idx $idx \{[lindex $options $idx]\}]
    set options "  [join $options "  "]"
    regsub {  \{} $options " \{" options
    regsub {\}  } $options "\} " options
    if {[set optionsLen [string length $options]] < 78} {
	set msg $options
    } else {
	# Too long to fit in the status bar window.
	set segIncr 50
	set segIdx1  0
	set segIdx2 60
	set segIdx3 73
	set pre [set post ""]
	while {$segIdx2 < [expr {$optionsLen + $segIncr}]} {
	    set segment1 [string range $options $segIdx1 $segIdx2]
	    set segment2 [string range $options $segIdx1 $segIdx3]
	    if {[regexp {\{.+\}} $segment1]} {
		if {$segIdx2 < $optionsLen} {set post " É"}
		set msg "${pre}${segment2}${post}"
		break
	    } 
	    set pre "É "
	    incr segIdx1 $segIncr
	    incr segIdx2 $segIncr
	    incr segIdx3 $segIncr
	}
    }
    status::msg $msg
}

# ==========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Miscellaneous ×××× #
# 

# ===========================================================================
# 
# Select (highlight) the current bibliographic entry.
#

proc Bib::selectEntry {} {

    Bib::BibModeMenuItem
    
    set pos [Bib::entryLimits [getPos]]
    selectText [lindex $pos 0] [lindex $pos 1]
}

proc Bib::selectFields {} {
    
    Bib::BibModeMenuItem
    
    if {![catch {Bib::fieldLimits [getPos]} limits]} {
	eval selectText $limits
    } else {
	error $limits
    }
}

# ===========================================================================
# 
# Remove some common LaTeX mark-up tags.  Used by some BibTeX conversions.
# 

proc Bib::deTeX {textString} {
    
    regsub -all -- {(^| )\{}    $textString {\1}        textString
    regsub -all -- {\}( |$)}    $textString {\1}        textString
    regsub -all -- {(^| )``}    $textString {\1"}       textString
    regsub -all -- {''( |$)}    $textString {"\1}       textString
    regsub -all -- {(^| )`}     $textString {\1'}       textString
    regsub -all -- {\\(&)}      $textString {\1}        textString
    regsub -all -- {\\ldots}    $textString {...}       textString
    regsub -all -- {\\\\}       $textString {\\}        textString
    
    return $textString
}

# ===========================================================================
# 
# Put the cite-key of the current entry on the clipboard.
# 

proc Bib::copyCiteKey {} {
    
    Bib::BibModeMenuItem
    
    if {![catch {Bib::getCiteKey} citeKey]} {
	putScrap $citeKey
	status::msg "Copied \"$citeKey\" to clipboard."
    } else {
	status::msg "Couldn't find marker."
    }
}

proc Bib::getCiteKey {{pos ""}} {
    
    global Bib::TopPat2

    if {![string length $pos]} {set pos [getPos]}
    set limits [Bib::entryLimits $pos]
    set pos0   [lindex $limits 0]
    set pos1   [lindex $limits 1]
    if {[regexp [set Bib::TopPat2] [getText $pos0 $pos1] allofit type citeKey]} {
	return $citeKey
    } else {
	error "Couldn't find cite-key"
    }
}

# ===========================================================================
# 
# Adapted from 'beginningOfLineSmart' and 'Shel::Bol'.
# 
# If we're in a line that starts a field, move the cursor to the beginning
# of the text within that field, otherwise move the cursor in front of the
# first word.  Pressing 'control-a' again will move the cursor to the
# beginning of the line, and again will toggle these two positions.
# 

proc Bib::beginningOfLineSmart {} {
    
    set pos0 [getPos]
    set pos1 [lineStart $pos0]
    set lim  [nextLineStart $pos1]
    set pat {[a-zA-Z]+[\t ]*=[\t \{"]*}
    if {![catch {search -f 1 -r 1 -s -l $lim $pat $pos1} fieldStart]} {
	set pos2 [lindex $fieldStart 1]
    } else {
	set pos2 [text::firstNonWsLinePos $pos0]
    }
    if {[pos::compare $pos0 == $pos2]} {
	beginningOfLine
    } else {
	goto $pos2
    }
}

# ==========================================================================
# 
# .