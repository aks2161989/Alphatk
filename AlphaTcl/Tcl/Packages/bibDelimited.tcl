## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibDelimited.tcl"
 #                                          created: 07/24/2002 {10:36:10 AM}
 #                                      last update: 03/06/2006 {08:12:24 PM}
 # Description: 
 #  
 # Procedures to convert bibliography files to/from delimited windows.
 #  
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #    
 # Copyright (c) 2002-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ## 

alpha::feature bibDelimited 1.0 "Bib" {
    # Initialization script.
    # We require Bib v 4.3 for 'Bib::nextEntryStart'.
    alpha::package require -loose Bib 4.3
} {
    # Activation script.
    menu::insert   bibtexConversions items end "bibToDelimitedÉ"
    menu::insert   bibtexConversions items end "delimitedToBibÉ"
} {
    # Deactivation script.
    # Could uninsert the menu items, but then they won't be in the menu
    # if the BibTeX menu is global but this package is not.
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Conversion of BibTeX files to/from delimited windows
} help {
    This package converts .bib files to/from delimited windows.  To activate
    this package, just check the box in the dialog that appears using the
    "Config > Global Setup > Features" menu item.  This could also be a Bib
    mode feature preference.
    
    Preferences: Mode-Features-Bib
    
    Once the package is active, it will insert two new items into the submenu
    "BibTeX Menu > BibTeX Conversions", named
    
	Bib To Delimited
	Delimited To Bib

    which are described below.  Note that any '@string' strings will NOT be
    converted, use the "String Conversions > Unstringify Window" menu item
    first if this is an issue.  Any '@string' entries will also be ignored.

    
	  	 	Bib To Delimited


    This is useful if you want to convert a .bib file with entries like this:
    
	@article{DiMaggio1997,
	   author   = {Paul DiMaggio},
	   title    = {Culture and Cognition},
	   journal  = {Annual Review of Sociology},
	   volume   = 21,
	   pages    = {263-287},
	   year     = 1997,
	}

    into something like this:

	Paul DiMaggio
	Culture and Cognition
	Annual Review of Sociology
	21
	263-287
	1997

    or perhaps into a tab delimited entry that could be read into a
    spreadsheet window (such as Excel):
    
	DiMaggio1997	Paul DiMaggio	Culture and Cognition	Annual Review of Sociology	21	263-287	1997

    This menu item will convert any highlighted entries (or all entries in the
    current window if there is no selection), grabbing each field value to use
    in a delimited entry.  When the menu item is chosen, a dialog with several
    different delimiting options is presented, which will look like this
    <<Bib::Delimited::toDelimitedDialog>>.  Options will be remembered for the
    next round, and will be saved between editing sessions.
    
    Experiment converting entries with the "BibTeX Example.bib" file.
    

	  	 	Delimited To Bib


    As expected, this menu item reverses the process.  A slightly different
    dialog will be presented <<Bib::Delimited::toBibDialog>>, and once again
    settings will be saved.  This is useful if you have a set of bibliographic
    data that you want to turn into BibTeX entries.  Note that unless both the
    BibTeX menu and this package are globally activated, you'll have to first
    change the mode of the delimited window to be converted to Bib.
    
    All of the entries, which will include the entire window if there is no
    selection, will be converted using a single 'entry' type, and it is up to
    you to ensure that the fields in the delimited format are in the proper
    order that a normal 'entry' template would provide.  If this is not the
    case, you can either add/delete fields from the delimited window (the
    package: manipCols is useful for this sort of activity) or change the
    "Default Entry Fields > <Entry>" preference for the entry.
    
    Experiment using a window that was first converted using the first menu
    item described above.
}

proc bibDelimited.tcl {} {}

# load main bib file!
bibtexMenu

namespace eval Bib {}

proc Bib::bibToDelimited {args} {eval Bib::Delimited::convertToDelimited $args}
proc Bib::delimitedToBib {args} {eval Bib::Delimited::convertToBib       $args}

namespace eval Bib::Delimited {}

# ===========================================================================
# 
# ×××× Conversion Settings, Options ×××× #
# 

newPref flag excludeCiteKey      "0"      bibDelimited
newPref flag includeCiteKey      "1"      bibDelimited
newPref flag includeHeader       "1"      bibDelimited
newPref flag includeType         "1"      bibDelimited
newPref flag unstringStrings     "1"      bibDelimited

newPref var  citeKeyField        "1"      bibDelimited
newPref var  delimiter           "tab"    bibDelimited
newPref var  entrySpacer         "return" bibDelimited
newPref var  windowName          ""       bibDelimited

foreach pref [list "excludeCiteKey" "includeCiteKey" "includeHeader" \
  "includeType" "unstringStrings" "citeKeyField" "delimiter" "entrySpacer"] {
    prefs::modified bibDelimitedmodeVars($pref)
}
unset pref

set Bib::Delimited::ConvertOptions(delimiter)   [list "tab" "return" "space"]
set Bib::Delimited::ConvertOptions(entrySpacer) [list "tab" "return" "empty line"]

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Conversion To Delimited ×××× #
# 

proc Bib::Delimited::toDelimitedDialog {} {
    
    global bibDelimitedmodeVars Bib::Delimited::ConvertOptions
    
    set dSetting $bibDelimitedmodeVars(delimiter)
    set dOptions [set Bib::Delimited::ConvertOptions(delimiter)]

    set eSetting $bibDelimitedmodeVars(entrySpacer)
    set eOptions [set Bib::Delimited::ConvertOptions(entrySpacer)]
    
    set type     $bibDelimitedmodeVars(includeType)
    set citeKey  $bibDelimitedmodeVars(includeCiteKey)
    set header   $bibDelimitedmodeVars(includeHeader)
    set unstring $bibDelimitedmodeVars(unstringStrings)
    set window   $bibDelimitedmodeVars(windowName)
    
    set results [dialog::make -title "Convert To Delimited" \
      [list "Settings for the delimited file:" \
      [list var "Window name for results"                  $window] \
      [list [list "menu" $dOptions] "delimiter character:" $dSetting] \
      [list [list "menu" $eOptions] "entry divider:"       $eSetting] \
      [list flag "Include each entry's 'Type'"             $type] \
      [list flag "Include each entry's 'Cite-key'"         $citeKey] \
      [list flag "Include first entry's fields as header"  $header] \
      [list flag "Unstring all strings"                    $unstring] \
      ]]
    
    set count 0
    foreach item [list windowName delimiter entrySpacer includeType \
      includeCiteKey includeHeader unstringStrings] {
	set bibDelimitedmodeVars($item) [lindex $results $count]
	incr count
    }
}

proc Bib::Delimited::convertToDelimited {} {

    Bib::BibModeMenuItem
    
    global bibDelimitedmodeVars
    
    set wCT [win::StripCount [win::CurrentTail]]
    set bibDelimitedmodeVars(windowName) "[file rootname $wCT].delimited"
    
    Bib::Delimited::toDelimitedDialog
    
    set d $bibDelimitedmodeVars(delimiter)
    set e $bibDelimitedmodeVars(entrySpacer)

    switch -- $d {
	"tab"         {set d "\t"}
	"return"      {set d "\r"}
	"space"       {set d " "}
	default       {
	    error "Cancelled -- unknown delimiter: '$d'"
	}
    }
    set bibDelimitedmodeVars(delimiterChar) $d
    switch -- $e {
	"tab"         {set e "\t"}
	"return"      {set e "\r"}
	"empty line"  {set e "\r\r"}
	default       {
	    error "Cancelled -- unknown delimiter: '$e'"
	}
    }
    # Create the list of all strings if we're going to convert
    if {$bibDelimitedmodeVars(unstringStrings)} {Bib::listStrings 1}

    if {[isSelection]} {
	set pos [getPos]
	set end [selEnd]
    } else {
	set pos [minPos]
	set end [maxPos]
    }

    # This little dance handles the case that the first entry starts on the
    # first line.
    set hit [Bib::getEntry $pos]
    if {[pos::compare [lindex $hit 0] == [lindex $hit 1]]} {
	set pos [Bib::nextEntryStart $pos]
	set hit [Bib::getEntry $pos]
    }
    # Set up the variables for the report.
    set count         1  
    set errorCount    0
    set convertResult ""
    # Convert all of the entries.
    set results ""
    status::msg "Converting to delimited text É"
    if {$bibDelimitedmodeVars(includeHeader)} {
	if {[catch {Bib::getFields $pos} fieldLists]} {
	    error "bibFormatEntry: \"Bib::getFields\" couldn't find any"
	} else {
	    # Add the 'type' ?
	    if {$bibDelimitedmodeVars(includeType)} {
		append results "type${d}"
	    } 
	    # Add the 'citeKey' ?
	    if {$bibDelimitedmodeVars(includeCiteKey)} {
		append results "[lindex [lindex $fieldLists 0] 1]${d}"
	    } 
	    # Add the rest of the field values.
	    append results "[join [lrange [lindex $fieldLists 0] 2 end] ${d}]${e}"
	}
    } 
    while {[pos::compare $pos < [lindex $hit 1]]} {
	set lastPos $pos
	status::msg "Converting to delimited text: $count"
	set hit  [Bib::getEntry [lindex $hit 0]]
	set pos0 [lindex $hit 0] 
	set pos1 [lindex $hit 1]
	# Now try to convert the entry.
	if {[catch {Bib::Delimited::delimitEntry $pos0} result]} {
	    # There was some sort of error ...
	    incr errorCount
	    append convertResult "\r[format {%-17s} "line [lindex [pos::toRowChar $pos0] 0]"]"
	    catch {append convertResult ", cite-key \"[lindex [lindex [Bib::getFields $pos0] 1] 1]\""}
	} elseif {[string length $result]} {
	    # Bib::Delimited::delimitEntry didn't fail, so append the result.
	    incr count
	    append results "${result}${e}"
	}
	# Go to the next entry.
	set pos [Bib::nextEntryStart $pos0]
	set hit [Bib::getEntry $pos]
	# Aren't we done yet?
	if {[pos::compare $pos == $lastPos]} {break}
	# a little insurance ...
	if {[pos::compare $pos1 >= $end]} {break}
    }
    if {![incr count -1]} {status::msg "No entries were converted." ; return}
    # Put the results in a new window
    new -n $bibDelimitedmodeVars(windowName) -m "Bib" -text $results
    goto [minPos]
    if {!$errorCount} {
	status::msg "$count entries converted.  No errors detected."
    } else {
	# We had errors, so we'll return them in a little window.
	status::msg "$count entries converted.  Errors detected É"
	set t    "% -*-Bib-*- (conversion)\r"
	append t "\r  Conversion Results for \"[win::CurrentTail]\"\r\r"
	append t "  Note: Command double-click on any cite-key or line-number\r"
	append t "        to return to its original entry.  If there is no\r"
	append t "        cite-key listed, that is certainly one problem ...\r\r"
	append t "___________________________________________________________\r\r"
	append t "    Converted Entries:  [format {%4d} [expr $count - $errorCount]]\r\r"
	append t "  Unconverted Entries:  [format {%4d} $errorCount]\r"
	append t "___________________________________________________________\r\r"
	append t "  line numbers:  cite-keys:\r"
	append t "  -------------  ----------\r"
	append t $convertResult
	new -n "* Conversion Results *" -m "Bib" -text $t
	goto [minPos]
	winReadOnly
	shrinkHigh
    }
}

proc Bib::Delimited::delimitEntry {pos} {
    
    global BibmodeVars bibDelimitedmodeVars

    if {[catch {Bib::getFields $pos} fieldLists]} {
	error "bibFormatEntry: \"Bib::getFields\" couldn't find any"
    } elseif {[lindex [lindex $fieldLists 1] 0] == "string"} {
	return ""
    } else {
	regsub -all "\[\r\t \]+" $fieldLists " " fieldLists
    }
    set values [lrange [lindex $fieldLists 1] 2 end]
    # Should we convert all strings?
    if {$bibDelimitedmodeVars(unstringStrings)} {
	set count 0
	foreach value $values {
	    if {[lindex [set result [Bib::isString $value]] 0]} {
		set values [lreplace $values $count $count [lindex $result 1]]
	    }
	    incr count
	}
    } 

    set line [list]
    set char $bibDelimitedmodeVars(delimiterChar)

    # Add the 'type' ?
    if {$bibDelimitedmodeVars(includeType)} {
	lappend line [lindex [lindex $fieldLists 1] 0]
    } 
    # Add the 'citeKey' ?
    if {$bibDelimitedmodeVars(includeCiteKey)} {
	lappend line [lindex [lindex $fieldLists 1] 1]
    } 
    # Add the rest of the field values.
    join [concat $line $values] $char
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Conversion To Delimited ×××× #
# 

proc Bib::Delimited::toBibDialog {} {
    
    global bibDelimitedmodeVars Bib::Delimited::ConvertOptions Bib::Entries

    # Make sure that the 'defaultType' setting exists, and is valid.
    set Bib::Delimited::ConvertOptions(defaultType) [set Bib::Entries]
    if {![info exists bibDelimitedmodeVars(defaultType)]} {
	set bibDelimitedmodeVars(defaultType) [lindex [set Bib::Entries] 0]
    } 
    set tSetting $bibDelimitedmodeVars(defaultType)
    set tOptions [set Bib::Delimited::ConvertOptions(defaultType)]
    if {![lcontains Bib::Delimited::ConvertOptions(defaultType) $tSetting]} {
	set tSetting [lindex [set Bib::Entries] 0]
    } 
    
    set dSetting $bibDelimitedmodeVars(delimiter)
    set dOptions [set Bib::Delimited::ConvertOptions(delimiter)]

    set eSetting $bibDelimitedmodeVars(entrySpacer)
    set eOptions [set Bib::Delimited::ConvertOptions(entrySpacer)]
    
    set mSetting $bibDelimitedmodeVars(citeKeyField)
    set xSetting $bibDelimitedmodeVars(excludeCiteKey)
    set window   $bibDelimitedmodeVars(windowName)

    set results [dialog::make -title "Convert From Delimited" \
      [list "Settings for the delimited file:" \
      [list var "Window name for results"                    $window] \
      [list [list "menu" $dOptions] "Delimiter Character:"   $dSetting] \
      [list [list "menu" $eOptions] "Entry Divider:"         $eSetting] \
      [list [list "menu" $tOptions] "Entry Type"             $tSetting] \
      [list text "(All entries will be formatted as one type.)"] \
      [list var  "Cite-key's field position:"                  $mSetting] \
      [list flag "Exclude the 'cite-key' field from entry."  $xSetting] \
      ]]
    
    set count 0
    foreach item [list windowName delimiter entrySpacer defaultType \
      citeKeyField excludeCiteKey] {
	set bibDelimitedmodeVars($item) [lindex $results $count]
	incr count
    }
}

proc Bib::Delimited::convertToBib {} {
    
    global BibmodeVars bibDelimitedmodeVars Bib::OpenQuote Bib::CloseQuote \
      Bib::OpenEntry Bib::CloseEntry Bib::Indent
    
    set wCT [win::StripCount [win::CurrentTail]]
    set bibDelimitedmodeVars(windowName) "[file rootname $wCT].bib"

    Bib::Delimited::toBibDialog
    
    set d $bibDelimitedmodeVars(delimiter)
    set e $bibDelimitedmodeVars(entrySpacer)
    
    switch -- $d {
	"tab"         {set d "\t"}
	"return"      {set d "\r"}
	"space"       {set d " "}
	default       {
	    error "Cancelled -- unknown delimiter: '$d'"
	}
    }
    set bibDelimitedmodeVars(delimiterChar) $d
    switch -- $e {
	"tab"         {set e "\t"}
	"return"      {set e "\r"}
	"empty line"  {set e "\r\r"}
	default       {
	    error "Cancelled -- unknown delimiter: '$e'"
	}
    }
    if {![is::PositiveInteger [set m $bibDelimitedmodeVars(citeKeyField)]]} {
	error "Cancelled -- the 'cite-key field number must be\
	  a positive integer!"
    } 
    set m1 [expr {$m - 1}]

    if {[isSelection]} {
	set t [string trim [getSelect]]
    } else {
	set t [string trim [getText [minPos] [maxPos]]]
    }
    # Make sure that all double carriage returns are converted.
    regsub -all "(\r)?\n" $t "\r"   t
    regsub -all "\r\r+"   $t "\r\r" t
    # Now try to capture each individual entry.
    set entries [split $t $e]
    set results ""
    # Figure out what fields we're going to use.
    set type   $bibDelimitedmodeVars(defaultType)
    set fields [Bib::entryFields $type]
    # Determine the length to use for the spacing in the fields.
    set length 6
    foreach field $fields {
	set fieldLength [string length $field]
	if {$fieldLength > $length} {set length $fieldLength}     
    }
    # And then convert each entry.
    set count1 0
    foreach entry $entries {
	status::msg "Converting from delimited text: [incr count1]"
	set entry [split $entry $d]
	if {![llength $entry]} {
	    continue
	} elseif {[llength $entry] < $m} {
	    set citeKey [lindex $entry end]
	} else {
	    set citeKey [lindex $entry $m1]
	    if {$bibDelimitedmodeVars(excludeCiteKey)} {
		set entry [lreplace $entry $m1 $m1]
	    } 
	}
	regsub -all "\[-\r\n\t \]" $citeKey "" citeKey
	set lines "@${type}[set Bib::OpenEntry]${citeKey},\r"
	set count2 0
	foreach value $entry {
	    if {![string length [lindex $fields $count2]]} {
		set field "field[expr {$count2 + 1}]"
	    } else {
		set field [lindex $fields $count2]
	    }
	    catch {append lines [Bib::newField $field $length $value]}
	    incr count2
	}
	append lines "[set Bib::CloseEntry]"
	append results "${lines}\r"
    }
    # Put the results in a new window
    set name $bibDelimitedmodeVars(windowName)
    if {[catch {file::newDocument -n $name -m "Bib"}]} {
	new -n $name -m "Bib"
    } 
    goto [maxPos]
    elec::Insertion $results
    status::msg "$count1 entries converted.  No errors detected."
}

# ===========================================================================
# 
# .
