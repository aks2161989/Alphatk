## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "stringsLists.tcl"
 #                                          created: 09/09/1994 {05:50:52 AM}
 #                                      last update: 04/14/2006 {10:05:30 PM}
 # Description: 
 # 
 # Various procedures to manipulate strings and lists.  This includes a
 # number of "Pseudo Tcl" commands.
 # 
 # Author: Vince Darley
 # E-mail: vince@santafe.edu
 #  
 # Copyright (c) 1994-2006 Vince Darley, Mark Nagata and Tom Scavo
 # 
 # See the file "license.terms" for information on usage and redistribution of
 # this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #  
 # ==========================================================================
 ##

proc stringsLists.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "viewValue" --
 # 
 # Present the name of a variable and its value to the user.  The method of 
 # presentation varies depending on the length of the value.  If it can be 
 # presented in an alert dialog, the "placeOrAppend" argument will determine 
 # if the user has the option to replace the current Clipboard contents with 
 # the name/value (placeOrAppend == 0) or append it (placeOrAppend == 1).
 # 
 # Returns 1 if the user chose to place/append to the Clipboard, otherwise 0.
 # 
 # (Not exactly sure why this procedure is in this file...)
 # 
 # --------------------------------------------------------------------------
 ##

proc viewValue {name val {placeOrAppend "0"}} {
    set header "'$name's value is:"
    set response "\r$val\r"
    set N [expr {$placeOrAppend ? "Append to Clipboard" : "Place in Clipboard"}]
    if {[string length $val] > 80} {
	if {![catch {llength $val}] && (([llength $val] > 3) && \
	  ([llength $val] > 6 || [string length $val] > 160))} {
	    catch {listpick -p "'$name's value is:" $val}
	    return 0
	} else {
	    global tileLeft tileTop tileWidth
	    new -g $tileLeft $tileTop $tileWidth 100 -n "* $name *" -m Text \
	      -info "'$name's value is:\r\r$val\r"
	    return 0
	}
    } elseif {($val eq "")} {
	alertnote "$header$response"
	return 0
    } elseif {![dialog::yesno -n $N -y "OK" $header $response]} {
	set msg "The current value of '${name}' has been "
	if {!$placeOrAppend} {
	    putScrap "\"$name\" value: $val"
	    append msg "placed in the Clipboard."
	} else {
	    putScrap [getScrap] \r "\"$name\" value: $val"
	    append msg "appended to the Clipboard."
	}
	status::msg $msg
	return 1
    } else {
	return 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "getOpts" --
 # 
 # Rudimentary option passing.  Uses upvar to get to the 'args' list of the
 # calling procedure and scans that.  Option information is stored in the
 # 'opts' array of the calling procedure.
 #  
 # Options are assumed to be flags, unless they occur in the optional
 # parameter list.  Then they are variables which take a value; the next item
 # in the args list.  If an item is a pair, then the first is the var name
 # and the second the number of arguments to give it.
 # 
 # --------------------------------------------------------------------------
 ##

proc getOpts {{take_value ""} {set "set"}} {
    upvar 1 args a
    upvar 1 opts o
    if {$set == "set"} {
	for {set i 0} {$i < [llength $a]} {incr i} {
	    set arg [lindex $a $i]
	    if {[string index $arg 0] != "-"} {break}
	    if {$arg == "--"} { incr i ; break}
	    if {[set idx [lsearch -regexp $take_value \
	      "^-?[string range $arg 1 end]( .*)?$"]] == -1} {
		set o($arg) 1
	    } else {
		if {[llength [set the_arg \
		  [lindex $take_value $idx]]] == 1} {
		    incr i
		    set o($arg) [lindex $a $i]
		} else {
		    incr i
		    set numargs [expr {[lindex $the_arg 1] -1}]
		    set o($arg) [lrange $a $i [expr {$i + $numargs}]]
		    incr i $numargs
		}
	    }
	}
    } else {
	for {set i 0} {$i < [llength $a]} {incr i} {
	    set arg [lindex $a $i]
	    if {[string index $arg 0] != "-"} {break}
	    if {$arg == "--"} { incr i ; break}
	    if {[set idx [lsearch -regexp $take_value \
	      "^-?[string range $arg 1 end]( .*)?$"]] == -1} {
		set o($arg) 1
	    } else {
		if {[llength [set the_arg \
		  [lindex $take_value $idx]]] == 1} {
		    incr i
		    $set o($arg) [lindex $a $i]
		} else {
		    incr i
		    set numargs [expr {[lindex $the_arg 1] -1}]
		    $set o($arg) [lrange $a $i [expr {$i + $numargs}]]
		    incr i $numargs
		}
	    }
	}
    }
    set a [lrange $a $i end]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "ensureset" --
 # 
 # Ensure the given variable is set, if it is unset, set it to the given
 # value.  This works with both variables and array elements, including
 # things which contain spaces etc.
 # 
 # --------------------------------------------------------------------------
 ##

proc ensureset {v {val ""}} {
    if {[uplevel 1 [list info exists $v]]} { return [uplevel 1 [list set $v]] }
    return [uplevel 1 [list set $v $val]]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Psuedo Tcl Commands ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "lremove" --
 # 
 # Removes items from a list.
 #  
 # Options are '-all' to remove all, and -glob, -exact or -regexp for search
 # type.  '-exact' is the default.  '--' terminates options.
 #  
 #     lremove ?-opts? l args
 #  
 # Note: if you want to remove all items of list 'b' from list 'a', just do:
 # lremove $a $b.  If $b is just a list element (which might contain spaces),
 # then lremove $a [list $b] is needed.
 # 
 # --------------------------------------------------------------------------
 ##

proc lremove {args} {
    array set opts {-all 0 pattern -exact}
    while {([llength $args] > 2) && [string match -* [lindex $args 0]]} {
	switch -glob -- [lindex $args 0] {
	    -a*	{ set opts(-all) 1 }
	    -l  {
		# -l option ignored.  Only retained for backwards
		# compatibility.
	    }
	    -g*	{ set opts(pattern) -glob }
	    -r*	{ set opts(pattern) -regexp }
	    --	{ set args [lreplace $args 0 0]; break }
	    default {return -code error "unknown option \"[lindex $args 0]\""}
	}
	set args [lreplace $args 0 0]
    }
    set l [lindex $args 0]
    foreach i [join [lreplace $args 0 0]] {
	if {[set ix [lsearch $opts(pattern) $l $i]] == -1} continue
	set l [lreplace $l $ix $ix]
	if {$opts(-all)} {
	    while {[set ix [lsearch $opts(pattern) $l $i]] != -1} {
		set l [lreplace $l $ix $ix]
	    }
	}
    }
    return $l
}

## 
 # --------------------------------------------------------------------------
 # 
 # "lunion" --
 # 
 # Make sure a given list variable contains each element of 'args'
 #  
 # --------------------------------------------------------------------------
 ##

proc lunion {listVarName args} {
    upvar 1 $listVarName a
    if {![info exists a]} {
	set a $args
	return
    } else {
	foreach item $args {
	    if {[lsearch $a $item] == -1} {
		lappend a $item
	    }
	}
    }
}
	
## 
 # --------------------------------------------------------------------------
 # 
 # "llunion" --
 #  
 # An advanced version of [lunion] : make sure a given list variable and
 # index contains an element whose i'th index matches the i'th index of one
 # of 'args'.
 # 
 # --------------------------------------------------------------------------
 ##

proc llunion {var idx args} {
    upvar 1 $var a
    if {![info exists a]} {
	set a $args
	return
    } else {
	foreach item $args {
	    set add 1
	    foreach i $a {
		if {[lindex $i $idx] == [lindex $item $idx]} {
		    set add 0
		    break
		}
	    }
	    if {$add} {
		lappend a $item
	    }
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "lunique" --
 # 
 # Ensure that a given list is unique.
 # 
 # --------------------------------------------------------------------------
 ##

proc lunique {l} {
    set lout ""
    foreach f $l {
	if {![info exists silly($f)]} {
	    set silly($f) 1
	    lappend lout $f
	}
    }
    return $lout
}
		
## 
 # --------------------------------------------------------------------------
 # 
 # "lreverse" --
 # 
 # Reverse the order of a given list.
 # 
 # --------------------------------------------------------------------------
 ##

proc lreverse {L} {
    set res {}
    set i [llength $L]
    while {$i} {lappend res [lindex $L [incr i -1]]}
    set res
}

## 
 # --------------------------------------------------------------------------
 # 
 # "lcontains" --
 # 
 # Determine is the element "e" exists in the variable "listVarName".  If the
 # "listVarName" variable doesn't exist in the context of the calling code,
 # "0" is returned; no error is ever thrown.
 # 
 # --------------------------------------------------------------------------
 ##

proc lcontains {listVarName e} {
    upvar 1 $listVarName ll
    if {[info exists ll] && [lsearch -exact $ll $e] != -1} {
	return 1
    } else {
	return 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "llindex" --
 # 
 # Find the first index of a given list within another list.  
 # 
 # --------------------------------------------------------------------------
 ##

proc llindex {l e args} {
    upvar 1 $l ll
    if {![info exists ll]} { return -1 }
    if {![llength $args]} {
	return [lsearch -exact $ll $e]
    } else {
	set i 0
	set len [llength $args]
	while {$i < [llength $ll] - $len} {
	    if {[lindex $ll $i] eq $e} {
		set range [lrange $ll [expr {$i +1}] [expr {$i + $len}]]
		for {set j 0} {$j < $len} {incr j} {
		    if {!([lindex $args $j] eq [lindex $range $j])} {
			break
		    }
		}
		if {$j == $len} { return $i}
	    }
	    incr i
	}
	return -1
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "histlist" --
 # 
 # Author: Joachim Kock 
 #         <kock@mat.uab.es>
 # 
 # NAME
 #        histlist - Create, maintain, and query history lists
 # 
 # SYNOPSIS
 #        histlist create hlName ?size? ?item item ...?
 #        histlist size hlName
 #        histlist clear hlName
 #        histlist destroy hlName
 #        histlist update hlName ?item item ...?
 #        histlist read hlName
 #        histlist back hlName ?pattern?
 #        histlist forth hlName ?pattern?
 #        
 # _________________________________________________________________
 # 
 # 
 # DESCRIPTION
 #        This command performs one of several operations on the variable
 #        given by hlName, which is a history list.  A history list is a list 
 #        where new entries are appended to the end, and eventual previous 
 #        occurrences of the item are deleted.  When the list has reached a
 #        specified maximal size, the oldest entry is deleted when a new one 
 #        is inserted.  One can query this list with the commands ``back'' and 
 #        ``forth'', or ask for the whole list.  Typical examples are familiar 
 #        notions like a ``recent items menu'' or the command history in a 
 #        shell.  Except for the ``create'' sub-command, hlName must be the 
 #        name of an existing history list variable in the current namespace
 #        (or a fully qualified name).  The possible sub-commands (which may
 #        be abbreviated) are:
 #        
 #        histlist create hlName size ?args?
 #            Create a history list named hlName.  This list is of size size, 
 #            and all subsequent arguments are interpreted as items to insert 
 #            into the list one by one.  So for example the command
 #                   histlist create T 3 a b c d c
 #            will create a history list whose content is {b d c}.  If the
 #            argument size is not given the default size 15 is assumed.
 #            (Note: up to AlphaTcl 8.0.1, the created variable would be
 #            in the callers namespace, and hence an error would be thrown
 #            if a local variable of the same name already existed.  The
 #            present version creates the variable in accordance with 
 #            standard Tcl practice: it will be a local variable unless
 #            fully qualified, and unless the variable has previously been
 #            declared by a ``variable'' or ``global'' statement.)
 # 
 #            A history list is implemented as an dict with three entries:
 #              size (the size of the history list)
 #              content (a list of length <= size)
 #              current (the read position: somewhere in the list, or just
 #            outside its range).
 #      
 #        histlist size hlName ?num?
 #            Set the size of the history list hlName to num.  If the
 #            argument num is not given, the current size is returned.
 #            (In any case the present (previous) size is returned.)
 # 
 #        histlist current hlName ?num?
 #            Set the current item in the history list hlName to num.  
 #            If the argument num is not given, the current item is returned.
 # 
 #        histlist clear hlName
 #            Clear all entries in the history list hlName, but leave the
 #            size of it alone.
 # 
 #        histlist destroy hlName
 #            Permanently removes the whole history list hlName.
 #            
 #        histlist update hlName ?args?
 #            Append the items args to the history list given by hlName,
 #            one by one, removing any duplicates, and respecting the size
 #            specification of hlName.  It also sets the current read position
 #            equal to the length of the list, so that a subsequent call to
 #            histlist back will yield the last item.  (If no arguments are
 #            given after hlName, the current read position is simply reset.)
 #            Examples:
 #                   histlist create T 3 a b c
 #                      --> a b c
 #                   histlist update T x
 #                      --> b c x
 #                   histlist update c
 #                      --> b x c
 # 
 #        histlist read hlName
 #            Return the list content of the history list hlName.
 # 
 #        histlist back hlName ?pattern?
 #            Return the last (previous) entry of hlName, relative to the 
 #            read position, and moves the read position one step back.
 #            (If the previous call to histlist was update or create, then
 #            the read position is the length of the list, and histlist back
 #            will then return the previously inserted item.  If the previous
 #            call to histlist was back then another call to back will return
 #            the second to last item, etc.)  If there are no previous entries
 #            in the list, the empty string is returned.  If pattern is
 #            given, only entries matching pattern are considered (glob matching).
 #            That is, the ``back'' step is taken inside the sublist of matching
 #            items.
 # 
 #        histlist forth hlName ?pattern?
 #            Return the next entry of the history list hlName, relative 
 #            to the read position.  if there is no next item, an empty string 
 #            is returned.  Since the calls ``histlist update'' and ``histlist 
 #            create'' set the read position equal to the length of the list, 
 #            ``histlist forth'' is only useful after one some calls to 
 #            ``histlist back'', and works mainly as an ``undo'' for back.  
 #            The optional pattern argument is treated just as for the back 
 #            sub-command.
 # 
 # EXAMPLES:
 #        histlist create T 6 abc b aa c a
 #        histlist read T
 #        --> abc b aa c a
 #        histlist back T
 #        --> a
 #        histlist back T a*
 #        --> aa
 #        histlist forth T
 #        --> c
 #        histlist forth T c*
 #        -->  ""
 #        histlist update T x
 #        histlist update T y
 #        histlist back T
 #        --> y
 #        histlist read T
 #        --> b aa c a x y
 #        histlist destroy T
 #        
 # REMARKS:
 #        Obviously there is some fine tuning to do, for example with respect 
 #        to return values and error messages.  If there is any need for it, 
 #        a future version of back and forth might also accept -regexp, 
 #        -nocase, and -exact, etc...
 #        
 # 
 # --------------------------------------------------------------------------
 ##

proc histlist { subCmd hist args } {
#     uplevel 1 [list variable $hist]
    if { $subCmd == "create" } {
	# Create array in namespace of calling proc and initialise parameters:
	uplevel 1 [list dict set $hist content ""]
	if { [string is integer -strict [lindex $args 0]] && [lindex $args 0] > 0 } {
	    uplevel 1 [list dict set $hist size [lvarpop args 0]]
	    # (Here we modified args, so that the remaining entries will
	    # be appended to the content when we come into the update switch)
	} else {
	    uplevel 1 [list dict set $hist size 15]
	}
    }

    upvar 1 $hist A	

    switch -- $subCmd {	
	"update" - "create" {
	    foreach item $args {
		# If the item is already in the list, delete it:
		if { [set rep [lsearch -exact [dict get $A content] $item]] > -1 } {
		    set L [dict get $A content]
		    lvarpop L $rep
		    dict set A content $L
		}
		# Insert the item in the list:  
		dict lappend A content $item
		# Truncate:
		if { [llength [dict get $A content]] > [dict get $A size] } {
		    set L [dict get $A content]
		    lvarpop L 0
		    dict set A content $L
		} 
	    }
	    # Reset the read position:
	    dict set A current [llength [dict get $A content]]
	}
	"back" {
	    set newCurrent [expr {[dict get $A current] - 1}]
	    if { [llength $args] } {
		# Find occurrences:
		set indices [lsearch -all -glob [lrange [dict get $A content] 0 $newCurrent] [lindex $args 0]]
		# Pick the last one:
		set newCurrent [lindex $indices end]
	    }
	    if { $newCurrent < 0 || $newCurrent == "" } {
		dict set A current -1
		return ""
	    }
	    dict set A current $newCurrent
	    return [lindex [dict get $A content] [dict get $A current]]
	}
	"forth" {
	    set newCurrent [expr [dict get $A current] + 1]
	    if { [llength $args] } {
		# Find next match:
		set newCurrent [lsearch -glob -start $newCurrent [dict get $A content] [lindex $args 0]]
	    }
	    if { $newCurrent >= [llength [dict get $A content]] || $newCurrent == -1 } {
		dict set A current [llength [dict get $A content]]
		return ""
	    }  	
	    dict set A current $newCurrent
	    return [lindex [dict get $A content] [dict get $A current]]
	}
	"read" {
	    return [dict get $A content]
	}
	"size" {
	    set oldSize [dict get $A size]
	    set newSize [lindex $args 0]
	    if { [string is integer -strict $newSize] && $newSize > 0 } {
		dict set A size $newSize
	    }
	    return $oldSize
	}
	"current" {
	    set oldCurrent [dict get $A current]
	    set newCurrent [lindex $args 0]
	    set histSize   [dict get $A size]
	    if { [string is integer -strict $newCurrent] } {
		if {($newCurrent > $histSize)} {
		    set newCurrent $histSize
		} 
		dict set A current $newCurrent
	    }
	    return [dict get $A current]
	}
	"clear" {
	    dict set A content ""
	    dict set A current 0
	}
	"destroy" {
	    uplevel 1 [list unset $hist]
	}
	default {
	    error "Unknown sub-command to histlist"
	}
    }
    return ""
}

## 
 # --------------------------------------------------------------------------
 # 
 # "doSuffixText" --
 # 
 # Returns a modified text string if the string $text is non-null, and the
 # null string otherwise.  The argument 'operation' is a string directing
 # 'doSuffixText' to either "insert" or "remove" $suffixString to/from each
 # line of $text.
 # 
 # --------------------------------------------------------------------------
 ##

proc doSuffixText {operation suffixString text} {
    if {$text == ""} {return ""}
    if {$operation == "insert"} {
	regsub -all "\[\r\n\]" $text "[quote::Regsub ${suffixString}]\r" text
    } elseif {$operation == "remove"} {
	regsub -all -- "[quote::Regfind $suffixString](\r|\n)" \
	  $text "\\1" text
    }
    return $text
}

## 
 # --------------------------------------------------------------------------
 # 
 # "doPrefixText" --
 # 
 # Returns a modified text string if the string $text is non-null, and the
 # null string otherwise.  The argument 'operation' is a string directing
 # 'doPrefixText' to either "insert" or "remove" $prefixString to/from each
 # line of $text.
 # 
 # --------------------------------------------------------------------------
 ##

proc doPrefixText {operation prefixString text} {
    if {$operation == "insert"} {
	set trailChar ""
	set textLen [string length $text]
	if {$textLen && ([is::Eol [string index $text [expr {$textLen-1}]]])} {
	    set text [string range $text 0 [expr {$textLen-2}]]
	    set trailChar "\r"
	}
	regsub -all "(\r|\r?\n)" $text "\r[quote::Regsub $prefixString]" text
	return $prefixString$text$trailChar
    } elseif {$operation == "remove"} {
	set pref [quote::Regfind $prefixString]
	regsub -all "((\r|\r?\n)\[ \t\]*)${pref}" $text {\1} text
	regsub "^(\[ \t\]*)$pref" $text {\1} text
	return $text
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "getAscii" --  ?-w win? ?char?
 # 
 # --------------------------------------------------------------------------
 ##

proc getAscii {args} {
    win::parseArgs w {c ""}
    if {$c == ""} {
	set c [lookAt -w $w [getPos -w $w]]
    }
    # scan works on utf8, as does everything else in Tcl.
    scan $c %c decVal
    set asOctal [format %o $decVal]
    set asHex   [format %x $decVal]
    set asUni   [format %04.4X $decVal]
    
    # Now convert this into ascii 0-255 in the current window's
    # encoding.  If the character can't be represented in that
    # range, then the results will be strange.
    if {[catch {win::Encoding $w} enc]} {
	set enc "macRoman"
    }
    scan [encoding convertto $enc $c] %c asEncAscii
    set asEncOctal [format %o $asEncAscii]
    set asEncHex [format %x $asEncAscii]

    set text "saw a \"$c\",\
      \rIn utf-8:\
      $decVal - decimal, \\$asOctal - octal, x$asHex - hex,\
      \\u$asUni as escaped ascii\
      \rIn ${enc}, as ascii 0-255: \
      $asEncAscii - ascii, \\$asEncOctal - octal, x$asEncHex - hex"
    if {![dialog::yesno -y "OK" -n "Place In Clipboard" $text]} {
        putScrap $text
	status::msg "The information has been placed in the Clipboard."
    }
    return
}

namespace eval text {}

# Nabbed from html mode.  I believe the following would work as well:
# 
# scan [encoding convertto macRoman $char] %c decVal ; return $decVal
set text::_Ascii "\001\002\003\004\005\006\007\010\011\012\013\014\015\016\017"
append text::_Ascii "\020\021\022\023\024\025\026\027\030\031\032\033\034\035\036\037"
append text::_Ascii " !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ"
append text::_Ascii "\[\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\177€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘"
append text::_Ascii "’“”•–—˜™š›œžŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼?¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑ"
append text::_Ascii "ÒÓÔÕÖ×ØÙÚ?ÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"

proc text::Ascii {char {num 0}} {
    if {$char == ""} {return 0}
    global text::_Ascii
    if {$num} {
	if {$char > 256 || $char < 1} { beep ; status::msg "text::Ascii called with bad argument" }
	return [string index ${text::_Ascii} [expr {$char - 1}]]
    } else {
	return [expr {1 + [string first $char ${text::_Ascii}]}]
    }
}

proc text::fromPstring {str} {
    set len [text::Ascii [string index $str 0]]
    return [string range $str 1 $len]
}

# Useful for -command flag of 'lsort'.
proc sortByTail {one two} {
    string compare [file tail $one] [file tail $two]
}


namespace eval is {}

proc is::Hexadecimal {str} {
    return [regexp {^[0-9a-fA-F]+$} [string trim $str]]
}

proc is::Numeric {str} {
    return [expr {![catch {expr {$str}}]}]
}

proc is::Integer {str1} {
    return [regexp {^(\+|-)?[0-9]+$} [string trim $str1]]
}

proc is::UnsignedInteger {str1} {
    return [regexp {^[0-9]+$} [string trim $str1]]
}

proc is::PositiveInteger {str1} {
    if {[is::UnsignedInteger $str1]} {
	return [expr {$str1 > 0}]
    }
    return 0
}

## 
 # --------------------------------------------------------------------------
 # 
 # "is::Whitespace" --
 # 
 # Takes any string and tests whether or not that string contains all
 # whitespace characters.  Carriage returns are considered whitespace, as are
 # spaces and tabs.  Also returns true for the null string.
 # 
 # --------------------------------------------------------------------------
 ##

proc is::Whitespace {anyString} {
    return [regexp "^\[ \t\r\n\]*$" $anyString]
}

proc is::Eol {anyString} {
    return [regexp "^\[\r\n\]+$" $anyString]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "is::List" --
 # 
 # Determine if the given string is a valid Tcl list.
 # 
 # --------------------------------------------------------------------------
 ##

proc is::List {str} {
    return [expr ![catch {llength $str}]]
}

# ===========================================================================
# 
# .