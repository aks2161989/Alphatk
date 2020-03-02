## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexStrings.tcl"
 #                                   created: 08/17/1994 {09:12:06 am} 
 #                               last update: 11/24/2004 {12:30:38 AM}
 # Description: 
 # 
 # Menu item procedures that pertain to string conversion.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexStrings.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× String support ×××× #
#

# ===========================================================================
# 
# Return a list of all @string s
#

proc Bib::listStrings {{resetOld 0}} {
    
    global Bib::TopPat1 Bib::Strings Bib::LongestStringNameLength \
      Bib::StringExpansionConnect Bib::ExpansionStringConnect
    
    ensureset Bib::LongestStringNameLength 0
    ensureset Bib::Strings [list]

    # We'll see if we can avoid re-creating the list of strings. 
    # Two different methods here -- using the first in Alphatk
    # takes a real long time.
    set time1 [ticks]

#     set pat {^[ ]*(@string)}
#     set count 0
#     set pos [minPos]
#     while {![catch {search -f 1 -r 1 -m 0 -i 1 -s $pat $pos} match]} {
# 	set pos [nextLineStart [lindex $match 0]]
# 	incr count
#     }

    set pat   "(^|\[\r\n\]+\[\t \]*)(@string)"
    set txt   [getText [minPos] [maxPos]]
    set count [regsub -all $pat $txt "" dummy]

    set time2 [ticks]
    set time3 [expr {($time2 - $time1) / 6}] 
#     alertnote "$count strings,\r[expr {$time3 / 10.0}] seconds"

    if {!$resetOld && [llength [set Bib::Strings]] == $count} {
	# We know that this proc was called once before.  We'll assume that
	# the actual strings haven't changed if the length is the same.
	status::msg ""
	set Bib::Strings
    } else {
	status::msg "scanning for @stringsÉ"
	catch {unset Bib::StringExpansionConnect}
	catch {unset Bib::ExpansionStringConnect}
	set Bib::LongestStringNameLength 0
	set matches [Bib::findEntries {^[ ]*@string *[\{\(]} 0]
	foreach hit $matches {
	    set entry [getText [lindex $hit 2] [lindex $hit 3]]
	    regsub -all "\[\n\r\]+" $entry { } entry
	    regsub -all "\[     \]\[    \]+" $entry { } entry
	    regsub {[,  ]*[\)\}][   ]*$} $entry { } entry
	    regexp [set Bib::TopPat1] $entry allofit citeKey
	    regsub -all {\"|(^[^=]+=)} $entry "" expansion
	    regsub -all "\[\r\n\t \]+" $expansion " " expansion
	    set expansion [string trim $expansion]
	    set Bib::StringExpansionConnect($citeKey)   $expansion
	    set Bib::ExpansionStringConnect($expansion) $citeKey
	    set len [string length $citeKey]
	    if {$len > [set Bib::LongestStringNameLength]} {
	        set Bib::LongestStringNameLength $len
	    } 
	}
	status::msg ""
	set Bib::Strings [lsort [array names Bib::StringExpansionConnect]]
    }
}

# ===========================================================================
# 
# Determine if a given value is defined by an @string string.
#

proc Bib::isString {value} {
    
    global Bib::StringExpansionConnect
    
    if {[regsub -all {[^\\]\#} $value " " value]} {
	regsub -all {\"} $value "" value
	set isString 1
    } else {
	set isString [info exists Bib::StringExpansionConnect($value)]
    }
    if {!$isString} {
	return [list 0 $value]
    } else {
	set newValue [list]
	regsub -all "\[\r\n\t \]+" $value " " value
	set value [split $value " "]
	foreach v $value {
	    if {[info exists Bib::StringExpansionConnect($v)]} {
		lappend newValue [set Bib::StringExpansionConnect($v)]
	    } else {
		lappend newValue $v
	    }
	}
	return [list 1 [join $newValue]]
    }
}

proc Bib::couldBeString {value} {
    
    global Bib::ExpansionStringConnect
    
    regsub -all "\[\r\n\t \]+" $value " " value
    if {![info exists Bib::ExpansionStringConnect($value)]} {
	return [list 0 $value]
    } else {
	return [list 1 [set Bib::ExpansionStringConnect($value)]]
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× String Conversion ×××× #
#

proc Bib::stringifyEntry {} {

    Bib::BibModeMenuItem
    Bib::listStrings
    Bib::convertStrings 1 [getPos]
}

proc Bib::unstringifyEntry {} {

    Bib::BibModeMenuItem
    Bib::listStrings
    Bib::convertStrings 0 [getPos]
}

proc Bib::convertStrings {direction pos {quietly 0}} {
    
    global Bib::OpenQuote Bib::CloseQuote
    
    if {![string length $pos]} {set pos [getPos]}

    # Find the entry.
    if {[catch {Bib::entryLimits $pos} match]} {
        error "Couldn't find entry"
    } else {
	set pos0  [lindex $match 0]
	set pos1  [lindex $match 1]
        set entry [getText $pos0 $pos1]
    }
    # Find the entry's fields
    if {[catch {Bib::getFields [lindex $match 0] 0} fieldLists]} {
        error "Cancelled -- $fieldLists"
    } else {
	set values [lrange [lindex $fieldLists 1] 2 end]
    }
    set found 0
    set newValues [list]
    foreach value [lrange [lindex $fieldLists 1] 2 end] {
	if {$direction} {
	    if {[lindex [set result [Bib::couldBeString $value]] 0]} {
		# This is a string.
		incr found 1
	    }
	} else {
	    if {[lindex [set result [Bib::isString $value]] 0]} {
		# This is a string.
		incr found 1
	    }
	}
	lappend newValues [lindex $result 1]
    }
    if {$found} {
	if {$direction} {
	    set oq [quote::Regsub [set Bib::OpenQuote]]
	    set cq [quote::Regsub [set Bib::CloseQuote]]
	} else {
	    set oq [set Bib::OpenQuote]
	    set cq [set Bib::CloseQuote]
	}
	set count 0
	set fields [lrange [lindex $fieldLists 0] 2 end]
	foreach value $values {
	    if {$value != [set newValue [lindex $newValues $count]]} {
		set field [lindex $fields $count]
		if {$direction} {
		    set value [quote::Regsub $value]
		    regsub "($field\[\t \]+=\[\t \]+)${oq}${value}${cq},?" $entry \
		      "\\1${newValue}," entry
		} else {
		    regsub "($field\[\t \]+=\[\t \]+)${value},?" $entry \
		      "\\1${oq}${newValue}${cq}," entry
		}
	    }
	    incr count
	}
    } 
    if {$quietly} {
        return [list $found $entry]
    } elseif {!$found} {
        status::msg "No strings found in '[Bib::getCiteKey $pos0]'."
	return
    } 
    # Still here?  Replace the entry.
    replaceText $pos0 $pos1 $entry
    goto $pos0
    if {$found == "1"} {
	status::msg "1 string converted in '[Bib::getCiteKey $pos0]'."
    } else {
	status::msg "$found strings converted in '[Bib::getCiteKey $pos0]'."
    }
}

proc Bib::stringifyWindow {} {

    Bib::BibModeMenuItem
    Bib::listStrings 1
    Bib::convertAllStrings 1
}

proc Bib::unstringifyWindow {} {

    Bib::BibModeMenuItem
    Bib::listStrings 1
    Bib::convertAllStrings 0
}

proc Bib::convertAllStrings {direction} {
    
    set pos [minPos]
    # This little dance handles the case that the first entry starts on the
    # first line.
    set hit [Bib::entryLimits $pos]
    if {[pos::compare [lindex $hit 0] == [lindex $hit 1]]} {
	set pos [Bib::nextEntryStart $pos]
	set hit [Bib::entryLimits $pos]
    }
    set start [lindex $hit 0]
    set line  [lindex [pos::toRowChar $start] 0]
    # Set up the variables for the report.
    set count1        0  
    set count2        0  
    set errorCount    0
    set convertResult ""
    # Create the list of all strings and abbrevs.  If there are many of them,
    # this will go pretty slow.
    set Bib::Strings [Bib::listStrings]

    # Convert all of the entries.
    set results ""
    status::msg "Converting É"
    while {[pos::compare $pos < [lindex $hit 1]]} {
	set lastPos $pos
	status::msg "Converting: [incr count1]"
	set pos0 [lindex $hit 0] 
	set pos1 [lindex $hit 1]
	# Now try to format the entry.
	if {![catch {Bib::convertStrings $direction $pos0 1} result]} {
	    incr count2 [lindex $result 0]
	    append results [lindex $result 1]
	} else {
	    # There was some sort of error ...
	    incr errorCount
	    set linenumber [expr {$line + [regsub -all "\\r" $results "" dummy]}]
	    append convertResult "\r[format {%-17s} "line ${linenumber},"]"
	    catch {append convertResult "cite-key \"[lindex [lindex [Bib::getFields $pos0] 1] 1]\""}
	    append results [getText $pos0 $pos1]
	}
	set hit [Bib::entryLimits [Bib::nextEntryStart $pos]]
	set pos [lindex $hit 0]
	# Aren't we done yet?
	if {[pos::compare $pos == $lastPos]} {break}
    }
    # Replace the old entries with the formatted results.
    if {$count2} {
	replaceText $start [maxPos] $results
	goto $start ; refresh
    }
    if {!$errorCount} {
	status::msg "$count2 strings in $count1 entries converted.  No errors detected."
    } else {
	# We had errors, so we'll return them in a little window.
	status::msg "$count1 entries converted.  Errors detected É"
	set t    "% -*-Bib-*- (conversion)\r"
	append t "\r  Formatting Results for \"[win::CurrentTail]\"\r\r"
	append t "  Note: Command double-click on any cite-key or line-number\r"
	append t "        to return to its original entry.  If there is no\r"
	append t "        cite-key listed, that is certainly one problem ...\r\r"
	append t "___________________________________________________________\r\r"
	append t "    Converted Entries:  [format {%4d} [expr $count1 - $errorCount]]\r\r"
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

# ===========================================================================
# 
# .