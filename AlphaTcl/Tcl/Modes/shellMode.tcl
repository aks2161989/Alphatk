## -*-Tcl-*-
 # ###################################################################
 # 
 #  FILE: "shellMode.tcl"
 #                                last update: 03/21/2006 {03:26:08 PM} 
 #                                
 #  Author: Vince Darley, Pete Keleher
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Some Copyright (c) 1997-2006  Vince Darley
 # Some copyright Pete Keleher.
 # 
 #  Description: 
 # 
 # General purpose shell routines for Alpha.  These no longer require
 # a separate mode 'Shel', just the ability to attach 'Shel' attributes
 # to a window which is in a different mode.
 # 
 # This is used by all sorts of things, ranging from various Tcl shells
 # (the built in one and remote tcl shells -- see Tcl mode), to the WWW
 # shell, the Terminal shell, etc.
 # 
 # In particular, note that none of this file should assume that the 
 # shell created has anything to do with the Tcl language.
 # 
 # Version 0.2: Changed to use [histlist] as history mechanism (JK January 2005).
 # This obsoletes half of this file and solves some problems reported on 
 # Bugzilla (Bug 1734).
 # ###################################################################
 ##

# ×××× Provide a library of 'Shel' routines and variables ×××× #

# This code can be used by packages which want basic shell-functionality
# (a prompt, execution of something on <return>, etc)

alpha::library "shells" 0.2 {
    namespace eval Shel {
	variable startPrompt "Ç"
	variable endPrompt   "È"
    }
} description {
    Provides support for shell windows created by other AlphaTcl packages
} help {
    file "Shells"
}

alpha::minormode shell +bindtags Shel +hookmodes Shel +varmodes Shel

proc shellMode.tcl {} {}

namespace eval Shel {}

# Color a single word red
#colorTagKeywords -k red Shel {Experimental}
# (would also require +colortags Shel in the minor mode above).

prefs::removeObsolete ShelmodeVars(autoMark)

newPref v wordBreak "\(\\\$\)?\[\\w.${Shel::endPrompt}\]+" Shel
newPref var lineWrap [expr {$alpha::platform eq "tk" ? 2 : 0}] Shel

set Shel::endPara "^${Shel::startPrompt}\[^\r\n\]*$"
set Shel::startPara "^${Shel::startPrompt}\[^\r\n\]*$"

Bind '\r' Shel::carriageReturn "Shel"
# Bind 0x30 bind::Completion Shel
Bind '\r' <o> Shel::newPrompt "Shel"

Bind up <z> Shel::prevHist Shel
Bind down <z> Shel::nextHist Shel

Bind 'a' <z> Shel::Bol Shel
Bind up Shel::up Shel
Bind down Shel::down Shel

Bind 'u' <z> Shel::killLine Shel

proc Shel::OptionTitlebar {} {
    set H [win::getInfo [win::Current] shellhistory]
    return [lreverse [histlist read H]]
}

proc Shel::OptionTitlebarSelect {item} {
    goto [maxPos]
    insertText $item
    Shel::carriageReturn
}

proc Shel::DblClick {from to args} {
    if {[file exists [set f [getText $from $to]]]} {
	file::openAny $f
    }
}


# Here is the classical shell starter:
proc Shel::start {type {title ""} {startuptext ""} {mainMode Text} {minorMode shell}} {
    if {$title ne ""} {
	if { [win::Exists $title] } {
	    bringToFront $title
	    return
	}
	# Minor modes can only currently be applied before a window
	# is created (else you can try calling alpha::_applyMinorMode 
	# manually!).
	win::setInitialConfig $title minormode $minorMode window
	new -n $title -m $mainMode -shell 1 -text $startuptext
    }

    set w [win::Current]
    win::setInfo $w shelltype $type
    
    histlist create H 20
    win::setInfo $w shellhistory $H
    
    Shel::newPrompt
}

# And here is the version taking advantage of the consoleAttributes package
# to automatically remember window attributes, and also the history list:
proc Shel::startPreexisting { name } {
    if { [win::Exists $name] } {
	bringToFront $name
	return
    }
    if { ![console::exists $name] } {
	error "Unkown shell \"$name\""
    }
    console::open $name
    set D [console::getAttributeDefaults $name]
    if { ![dict exists $D -shelltype] } {
	error "No -shelltype parameter supplied in definition of \"$name\""
    }
    if { [dict exists $D -startuptext] } {
	insertText -w $name [dict get $D -startuptext]
    }
    Shel::newPrompt
}


## 
 # -------------------------------------------------------------------------
 # 
 # "Shel::carriageReturn" --
 # 
 #  Rewritten to avoid need for global _text _return variables
 # -------------------------------------------------------------------------
 ##
proc Shel::carriageReturn {} {
    global Shel::endPrompt
    set pos [getPos]

#     if {![catch {regexp {°} [getText $pos [nextLineStart $pos]]} res] && $res} {
# 	browse::Goto; return;
#     }
    set ind [string first ${Shel::endPrompt} [getText [lineStart $pos] $pos]]
    if {$ind < 0} {
	insertText "\r"
	return
    }
    endOfLine
    set winName [win::Current]
    set type [Shel::getType]

    # Sort out where we're going to put the answer
    set t [getText [pos::math [lineStart $pos] + [expr $ind+2]] [getPos]]

    if {[pos::compare [getPos] != [maxPos]]} {
	goto [set pos [maxPos]]
	set ind [string first ${Shel::endPrompt} [getText [lineStart $pos] $pos]]
	if {$ind < 0} {
	    Shel::insertPrompt $winName
	} else {
	    set ind [pos::math [lineStart $pos] + [expr $ind +2]]
	    if {$ind != $pos} {
		deleteText $ind $pos
	    }
	}
	insertText -w $winName $t
    }
    
    if { ![string is space $t] } {
	set H [win::getInfo $winName shellhistory]
	histlist update H $t
	win::setInfo $winName shellhistory $H
	win::freeInfo $winName originalline
    }
	
    # Carry out the action
    insertText -w $winName "\r"
    set r [${type}::evaluate $t]
    # If the command has destroyed the window there is nothing
    # left to do:
    if {![win::Exists $winName]} {
	return
    }
    # The command may have moved so cursor (or even switched window).
    # So we need to put the cursor back:
    goto -w $winName [maxPos -w $winName]
    insertText -w $winName $r 
    if {$r != ""} { 
	insertText -w $winName "\r"
    }
    Shel::insertPrompt $winName
    goto -w $winName [getPos -w $winName]
}

proc Shel::newPrompt {{end 1}} {
    if {$end} {
	endOfBuffer
    }
    Shel::insertPrompt [win::Current]
}

proc Shel::insertPrompt {winName} {
    set type [Shel::getType $winName]
    
    set p [getPos -w $winName]
    set linestart [pos::lineStart -w $winName $p]
    if {[pos::compare -w $winName $p != $linestart]} {
	insertText -w $winName "\r"
    }
    insertText -w $winName [${type}::Prompt]
    
    set p [getPos -w $winName]
    text::color -w $winName [pos::lineStart -w $winName $p] $p blue
    refresh -w $winName
}

proc Shel::getType {{win ""}} {
    if {$win eq ""} { set win [win::Current] }
    win::getInfo $win shelltype
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Shel::currentLine" --
 # 
 # Obtain the current text in the prompt line.  If the cursor is not in a
 # prompt line, return the entire contents of the current line.
 # 
 # --------------------------------------------------------------------------
 ##

proc Shel::currentLine {} {
    
    variable endPrompt
    
    set posBeg [pos::lineStart [getPos]]
    set posEnd [pos::lineEnd   [getPos]]
    set txtStr [getText $posBeg $posEnd]
    if {[set idx [string first $endPrompt $txtStr]] > 0} {
	return [string range $txtStr [expr {$idx + 1}] end]
    } else {
	return $txtStr
    }
}

proc Shel::killLine {} {
    global Shel::endPrompt
    set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
    if {[set ind [string first "${Shel::endPrompt} " $text]] > 0} {
	goto [pos::math [lineStart [getPos]] + [expr {$ind + 2}]]
    } else {
	return
    }
    set to [nextLineStart [getPos]]
    if {[is::Eol [lookAt [pos::math $to - 1]]]} {set to [pos::math $to - 1]}
    deleteText [getPos] $to
}

proc Shel::Bol {} {
    global Shel::endPrompt
    set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
    if {[set ind [string first "${Shel::endPrompt} " $text]] > 0} {
	goto [pos::math [lineStart [getPos]] + [expr {$ind + 2}]]
    } else {
	goto [lineStart [getPos]]
    }
}

proc Shel::up {} {
    set pos [pos::math [lineStart [getPos]] - 1]
    if {[catch {regexp {°} [getText [lineStart $pos] [nextLineStart $pos]]} res] || !$res} {
	previousLine; return
    }
    selectText [lineStart $pos] [nextLineStart $pos]
}

proc Shel::down {} {
    set pos [nextLineStart [getPos]]
    if {[catch {regexp {°} [getText $pos [nextLineStart $pos]]} res] || !$res} {
	nextLine; return
    }
    selectText $pos [nextLineStart $pos]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Shel::prevHist" --
 # 
 # If the cursor in in a prompt line, replace the current command (if any)
 # with the previous item in the history list.  If this is invoked when the
 # current history item is at the very beginning (or end) of the list, then
 # remember the current line.  If the list has been completely cycled, then
 # insert the first item in the cache.
 # 
 # --------------------------------------------------------------------------
 ##

proc Shel::prevHist {} {
    
    variable endPrompt
    
    set line [getText [pos::lineStart [getPos]] [pos::nextLineStart [getPos]]]
    if {([set ind [string first $endPrompt $line]] > 0)} {
	set posBeg [pos::math [pos::lineStart [getPos]] + $ind + 1]
    } else {
	return
    }
    set msg ""
    set H [win::getInfo [win::Current] shellhistory]
    set size [histlist size H]
    set curr [histlist current H]
    if {($curr >= $size) || ($curr < 0)} {
	win::setInfo [win::Current] originalline [string trim [Shel::currentLine]]
    }
    set item [histlist back H]
    if {($item ne "")} {
	set numb [expr {$size - [histlist current H]}]
	set msg "(\# $numb of $size commands in \"Tcl Shell\" history)"
    } else {
	beep
	if {[win::infoExists [win::Current] originalline]} {
	    set item [win::getInfo [win::Current] originalline]
	    win::freeInfo [win::Current] originalline
	}
	if {($item eq "")} {
	    set msg "(History exhausted)"
	} else {
	    set msg "(History exhausted - original line returned)"
	}
	histlist current H $size
    }
    win::setInfo [win::Current] shellhistory $H
    set posEnd [pos::nextLineStart [getPos]]
    if {[is::Eol [lookAt [pos::math $posEnd -1]]]} {
	set posEnd [pos::math $posEnd -1]
    }
    replaceText $posBeg $posEnd " " [string trim $item]
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Shel::nextHist" --
 # 
 # If the cursor in in a prompt line, replace the current command (if any)
 # with the next item in the history list.  If this is invoked when the
 # current history item is at the very beginning (or end) of the list, then
 # remember the current line.  If the list has been completely cycled, then
 # insert the last item in the cache.
 # 
 # --------------------------------------------------------------------------
 ##

proc Shel::nextHist {} {
    
    variable endPrompt
    
    set line [getText [pos::lineStart [getPos]] [pos::nextLineStart [getPos]]]
    if {([set ind [string first $endPrompt $line]] > 0)} {
	set posBeg [pos::math [pos::lineStart [getPos]] + $ind + 1]
    } else {
	return
    }
    set msg ""
    set H [win::getInfo [win::Current] shellhistory]
    set size [histlist size H]
    set curr [histlist current H]
    if {($curr >= $size) || ($curr < 0)} {
	win::setInfo [win::Current] originalline [string trim [Shel::currentLine]]
	histlist current H -1
    }
    set item [histlist forth H]
    if {($item ne "")} {
	set numb [expr {$size - [histlist current H]}]
	set msg "(\# $numb of $size commands in \"Tcl Shell\" history)"
    } else {
	if {[win::infoExists [win::Current] originalline]} {
	    set item [win::getInfo [win::Current] originalline]
	    win::freeInfo [win::Current] originalline
	}
	if {($item eq "")} {
	    set msg "(History exhausted)"
	} else {
	    set msg "(History exhausted - original line returned)"
	}
	histlist current H $size
    }
    win::setInfo [win::Current] shellhistory $H
    set posEnd [pos::nextLineStart [getPos]]
    if {[is::Eol [lookAt [pos::math $posEnd -1]]]} {
	set posEnd [pos::math $posEnd -1]
    }
    replaceText $posBeg $posEnd " " [string trim $item]
    status::msg $msg
    return
}

# A few procs to query the history list:
proc Shel::HistKeep {win {limit {}}} {
    set H [win::getInfo $win shellhistory]
    if { [string length $limit] } {
	set old [histlist size H $limit]
	win::setInfo $win shellhistory $H
	return $old
    } else {
	return [histlist size H]
    }
}

proc Shel::HistClear {win {keep ""}} {
    set H [win::getInfo $win shellhistory]
    if { [string length $keep] } {
	histlist size H $keep
    }
    histlist clear H
    set::winInfo $win shellhistory $H
}

proc Shel::HistInfo {win {num {}}} {
    set H [win::getInfo $win shellhistory]
    set L [histlist read H]
    if { [string length $num] } {
	incr num -1
	set L [lrange $L end-$num end]
    }
    return [join $L \n]
}

# ×××× General purpose ×××× #

proc Shel::expandAliases {cmdLine {shellType ""}} {
    if {$shellType eq ""} {set shellType [Shel::getType]}
    
    variable ${shellType}Alias
    if {![info exists ${shellType}Alias]} {
	return $cmdLine
    }
    while {[string length $cmdLine]} {
	if {[regexp -indices -- \
	  {([$]\{?|set\s+)?\b([a-zA-Z_][a-zA-Z_0-9]*)\b(([\.]|(::))[a-zA-Z_0-9]*)*} \
	  $cmdLine all dc poss]} {
	    if {$all != $poss} {
		set end [lindex $all 1]
		append rtnVal [string range $cmdLine 0 $end]
		set cmdLine [string range $cmdLine [incr end] end]
	    } else {
		set start [lindex $poss 0]
		set end [lindex $poss 1]
		if {$start != 0} {
		    append rtnVal [string range $cmdLine 0 [expr $start - 1]]
		}
		set possAlias [string range $cmdLine $start $end]
		if {[info exists ${shellType}Alias($possAlias)]} {
		    append rtnVal [set ${shellType}Alias($possAlias)] 
		} else {
		    append rtnVal [string range $cmdLine $start $end]
		}
		set cmdLine [string range $cmdLine [incr end] end]
	    }
	} else {
	    append rtnVal $cmdLine
	    break
	}
    }
    return $rtnVal
}

proc Shel::alias {abrev replacement} {
    set type [Shel::getType]
	
    if {![regexp -- $abrev {[a-zA-Z_][a-zA-Z_0-9]*}]} {
	return "The name used for an alias must start with an alphabetic character \
	  \nor an underscore, followed by zero or more characters of the same sort \
	  \n(with numbers allowed also)."
    }
	
    variable ${type}Alias
    if {[info exists ${type}Alias($abrev)]} {
	beep
	if {![string match [askyesno -c "'$abrev' is already an alias for this shell, do you wish to Cancel?" ] no ] } {
	    return "No alias was formed"
	} 
    } 
    mode::addModePrefsLine [list namespace eval Shel \
      [list set ${type}Alias($abrev) $replacement]]
    return "Saved alias in mode preferences file"
}


# ×××× Unix imitation ×××× #

if {[info commands ls] == ""} {
    if {![catch {::exec ls [::pwd]}]} {
        # We use the OS for this command.
        proc ls {args} {
            return [eval [list ::exec ls] $args]
        }
    } else {
        # At present, all other flags are ignored.
        proc ls {args} {
            global dontShowAgain
            if {![llength $args]} {
                set dir [pwd]
            } else {
                set commandLine " ls [split $args { }]"
                getOpts
                switch -- [llength $args] {
                    "0" {
                        set dir [pwd]
                    }
                    "1" {
                        set dir [lindex $args 0]
                    }
                    default {
                        error "Cancelled -- Only one directory can be specified."
                    }
                }
                if {[llength [array names opts]] \
                  && (![info exists dontShowAgain(ls)] || !$dontShowAgain(ls))} {
                    status::msg "Issued command: $commandLine"
                    set dontShowAgain(ls) [lindex [eval [list dialog::make \
                      -title "Unsupported Arguments" -ok "Continue" \
                      [list "\"$commandLine\"" \
                      [list "text" "Sorry, no additional arguments to the\
                      \[ls\] command are supported in AlphaTcl.\r"] \
                      [list "flag" "Don't show this dialog in the future." 0] \
                      ]]] 0]
                    prefs::modified dontShowAgain(ls)                 
                }
            }
            return [join [lsort -dictionary [glob -tails -dir $dir -- *]] \r]
        }
    }
}

proc l {args} {
    eval [list "ls" "-CF"] $args
}

proc ll {args} {
    eval [list "ls" "-l"] $args
}

proc wc {args} {
    set res {}
    set totChars 0
    set totLines 0
    set totWords 0
    set args [glob -nocomplain $args]
    foreach file $args {
	set id [alphaOpen $file]
	set chars [string length [set text [read $id]]]
	set lines [llength [split $text "\n"]]
	set words [llength [split $text]]
	append res [format "\r%8d%8d%8d    $file" $lines $words $chars]
	set totChars [expr $totChars+$chars]
	set totWords [expr $totWords+$words]
	set totLines [expr $totLines+$lines]
	close $id
    }
    if {[llength $args] > 1} {
	append res [format "\r%8d%8d%8d    total" $totLines $totWords $totChars]
    }
    return [string range $res 1 end]
}



#================================================================================
# To prevent ambiguity, 'from' is assumed to be a complete pathname, ending
# in a directory name. If it doesn't end w/ a colon, one is added. 'to' is
# assumed to be the parent directory of the top directory we are creating.
#================================================================================
proc cpdir {from to} {
    set cwd [pwd]
    if {[string match ":*" $from] || [string match ":*" $to] ||
    ![file exists $from] || ![file exists $to]} {
	error "'cpdir' args must be complete pathnames of existing folders."
    }
    if {![string match "*:" $from]} {append from ":"}
    if {![string match "*:" $to]} {append to ":"}
    
    if {![file isdirectory $from] || ![file isdirectory $to]} {
	exit 1
    }
    
    set res [catch {cphier $from $to} val]
    cd $cwd
    if {$res} {error $val}
}

proc cphier {from to} {
    file copy $from $to
}

		
#================================================================================
#####
# (Usage:  'lt' sorts by time, like UNIX's 'ls -lt'.
#          'lt -t' sorts by filename, like UNIX's 'ls -l'.
#          Optionally a directory name can be added as an argument.)

proc sortdt {dt} {
    scan $dt "%d/%d/%d {%d:%d:%d %1sM}" mon day yea hou min sec z
    if {$z == "P"} {incr hou 12}
    if {[string length $yea] == 1} {
	set year 200$yea
    } elseif {$yea > 40} {
	set year 19$yea
    } else {
	set year 20$yea
    }
    return [format "%04d%02d%02d%02d%02d" $year $mon $day $hou $min]
}


#===============================================================================
#####
# (Usage:  'lth' sorts by time, like UNIX's 'ls -lt'.
#          'lth -t' sorts by filename, like UNIX's 'ls -l'.
#
#     Optionally a filename path pattern can be added as an argument.
#       Examples:
#
#           lth :Help:*
#           lth :Help:D*
#           lth HardDisk:news:*
#           lth HardDisk:news:R*
#           lth -t HardDisk:*
#
#       are all good, if you have a volume named "HardDisk" and a
#       folder named "news" on it, but
#       
#           lth Help
#           lth :Help:
#
#       are both bad.
#
#       Use
#       
#           lth {"Macintosh Hd:*"}
#       
#       if you have spaces in the file or folder names.)
#
#    This procedure is based only on the abbreviated format for dates and 
#    time. It does not rely anymore on the short date format which avoids
#    problems such that 'Jan 2' giving either '1/2' (US) or '2/1' (UK).
#    
#    It assumes that :
#    1. dates are coded as a four item list with a four digit field for years
#    and a two digit one for days (plus possible non-digit separators),
#    while weekdays and months are coded with characters in [\w] (plus
#    possible separators in [^\w]);
#    2. day and month fields are consecutive ones and weekday field is before 
#    them when the year field is either the first or the last one;
#    3. time uses 'a' and 'p' in the strings coding twelve hour clocks (case
#    insensitive).
#    
#    This should cover most Mac OS formats for (north) America and Europe
#    ({weekday month day year} or {weekday day month year}), but not
#    non-latin encodings or slavic languages using (for month) characters
#    which are not in the default [\w] set.
#    
#    In (some) Mac OS, the Finnish abbreviated dates use up to six characters.
#    Allowing for month names with up to six characters gives an ugly and
#    confusing result for languages using three (or four) characters, thus
#    the procedure uses only 'ns' characters, where 'ns' is set to 4.
#

proc lth args {
    global mode
    
    set date [lindex [mtime [now] abbrev] 0]
    
#
#    Try to find the most likely format for dates.
#
    
    set nmb [regexp "(\[0-9\]+)\[^0-9\]*(\[0-9\]+)" $date t one two]
    if {$nmb != 1} {
	error "Error while scanning the date stamp"
    }
    if {[string length $one] == 4} {
	set year $one
	set day  $two
    } elseif {[string length $two] == 4} {
	set year $two
	set day  $one
    } else {
	error "Error: cannot find the year"
    }
    set i 0
    set indd -1
    set indy -1
    foreach f $date {
	if {[regexp "\[0-9\]+" $f f]} {
	    if {$f == $year} {set indy $i}
	    if {$f == $day} {set indd $i}
	}
	incr i
    }
    if {($indy == 2) || ($indy == 3)} {
	if {$indd == [expr {$indy - 2}]} {
	    set indm [expr {$indy - 1}]
	} elseif {$indd == [expr {$indy - 1}]} {
	    set indm [expr {$indy - 2}]
	} else {
	    error "Error: date format unknown"
	}
    } elseif {($indy == 0) || ($indy == 1)} {
#
#       If your date format is {year month day weekday} or 
#       {year day month weekday} uncomment the following 'if' 'elseif'
#       'else' block and comment the next one.
#       
# 	if {$indd == [expr {$indy + 2}]} {
# 	    set indm [expr {$indy + 1}]
# 	} elseif {$indd == [expr {$indy + 1}]} {
# 	    set indm [expr {$indy + 2}]
# 	} else {
# 	    error "Error: date format unknown"
# 	}
#
	if {$indd == 2} {
	    set indm 3
	} elseif {$indd == 3} {
	    set indm 2
	} else {
	    error "Error: date format unknown"
	}
    } else {
	error "Error: date format unknown"
    }

#
#    If you want to set manually the location of the different fields
#    comment (or remove) the lines between the comment
#    "Try to find the most likely format for dates." above and this block 
#    and uncomment the following lines with 'yourXxxField' replaced
#    by a number between 0 and '[llength $date] - 1'.
#    
#    set indd yourDayField
#    set indm yourMonthField
#    set indy yourYearField
#    set year [lindex $date $indy]
#
    
    set val "*"
    set sort 1

    foreach arg $args {
	switch -- $arg {
	    "-t"    {set sort 0}
	    default {set val $arg}
	}
    }
    
#
#    If you want the full Finnish abbreviated form, set 'ns' to 6;
#    if you want only three letters for the month, set 'ns' to 3.
#
    
    set ns 4
    set nsp [expr {$ns + 1}]
    set nf [expr {$ns + 4}]
    set mod ""
    foreach f [eval glob $val] {
	# Alpha 8/X workaround for getFileInfo
	set f [file join [pwd] $f]
	unset -nocomplain info
	if {[catch {getFileInfo $f info}]} {
	    if {[file isdirectory $f]} {
		if {$sort} {set mod "            "}
		lappend text [format "%s%s %8d%8d %${nf}s %5s %4s %s %s\n" \
			      $mod "D" "0" "0" "" "" "" "DIR " [file tail $f]]
	    }
	    continue
	}
	set stru "F"
	if {[file isdirectory $f]} {
	    set stru "D"
	    set info(datalen) 0
	    set info(resourcelen) 0
	    set info(type) "    "
	    set info(creator) "DIR "
	}
	# Workaround for 'file mtime' problem on MacOS X/Alpha 8/X, by
	# using $info(modified).  Probably no good on Alphatk/MacOS X
	# (where we need a Tcl fix).
	if {$sort} {set mod [format "%12u" $info(modified)]}
	set m [mtime $info(modified) abbrev]
	set zer [lindex $m 0]
	regexp "(\[0-9\]+)" [lindex $zer $indd] day
	regexp "(\\w+)" [lindex $zer $indm] month
	set month [string range $month 0 [expr {$ns - 1}]]
	if {$indd < $indm} {
	    for {set i [string length $month]} {$i < $ns} {incr i} {
		set month "$month "
	    }
	    set dat [format "%3s %${ns}s" $day $month]
	} else {
	    set dat [format "%${nsp}s %2s" $month $day]
	}
	if {[lindex $zer $indy] == $year} {
	    set time [lindex $m 1]
	    set nmb [regexp "(\[0-9\]+)(\[^0-9\]+)(\[0-9\]+)" \
		     $time t hour sep min]
	    if {$nmb != 1} {
		error "Error while scanning the time stamp"
	    }
	    if {[regexp -nocase "p" $time] && ($hour < 12)} { 
		set hour [expr $hour + 12] 
	    }
	    if {[regexp -nocase "a" $time] && ($hour == 12)} { 
		set hour [expr $hour - 12] 
	    }
	    if {[string length $min] == 1} {set min "0$min"}
	    set tm "$hour$sep$min"
	} else {
	    regexp "(\[0-9\]+)" [lindex $zer $indy] yea
	    set tm " $yea"
	}
	ensureset info(resourcelen) 0
	ensureset info(type) ""
	ensureset info(creator) ""
	if {[string length $info(creator)] > 4} {
	    # On Windows/Unix, Alphatk just sets the creator to the
	    # full path.
	    set info(creator) ""
	}
	lappend text [format "%s%s %8d%8d %${nf}s %5s %4s %4s %s\n" \
		      $mod $stru $info(datalen) $info(resourcelen) $dat $tm \
		      $info(type) $info(creator) [file tail $f]]

    }
    if {$sort} {
	foreach ln [lsort -de $text] {
	    append txt [string range $ln 12 end]
	}
	set ans [string trimright $txt]
    } else {
	set ans [string trimright [join $text {}]]
    }
    
    return $ans
}


#================================================================================
proc ps {} {
    foreach p [processes] {
	append text [format "%-25s %4s %10d %10d\r" [lindex $p 0] [lindex $p 1] [lindex $p 2] [lindex $p 3]]
    }
    return [string trimright $text]
}


#================================================================================
# Recursively make creator of all text files 'ALFA'. Optionally takes a starting
# dir argument, otherwise starts in current directory. 
proc creator {{dir ""}}  {
    if {$dir == ""} {
	set dir [pwd]
    }
    foreach f [glob -nocomplain -types TEXT -dir $dir *] {
	file::setSig $f [expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]
    }
    foreach d [glob -nocomplain -type d -dir $dir *] {
	if {[file isdirectory $d]} {creator $d}
    }
}


#===============================================================================

proc tomac args {
    set files {}
    foreach arg $args {
	eval lappend files [glob -nocomplain -- $arg]
    }
    set dir [pwd]
    
    foreach f $files {
	status::msg "$f..."
	set fd [open [file join $dir $f] "r"]
	set text [read $fd]
	close $fd
	
	set fd [open [file join $dir $f] "w"]
	puts -nonewline $fd $text
	close $fd
    }
    status::msg ""
}


#===============================================================================

proc unixToMac {fname} {
    set fd [open $fname]
    set text [read $fd]
    close $fd
    set fd [open $fname "w"]
    puts -nonewline $fd $text
    close $fd
}

proc setCreator {creator args} {
    set files {}
    foreach arg $args {
	eval lappend files [glob -nocomplain -- $arg]
    }
    foreach f $files {
	file::setSig $f $creator
    }
}

proc setType {type args} {
    set files {}
    foreach arg $args {
	eval lappend files [glob -nocomplain -- $arg]
    }
    foreach f $files {
	setFileInfo $f type $type
    }
}
#===============================================================================

set ShelPushPopDirList {}

proc pushd {args} {
    global ShelPushPopDirList
    # What awful handling of 'args'.  No idea what is desired here!
    if {[string length $args]} {
	set ShelPushPopDirList [concat [list [pwd]] $ShelPushPopDirList]
	cd [string trim $args "	\t\{\}"]
    } else {
	if {[llength $ShelPushPopDirList]} {
	    set n [lindex $ShelPushPopDirList 0]
	    set ShelPushPopDirList \
	      [concat [list [pwd]] [lrange $ShelPushPopDirList 1 end]]
	    cd $n
	} else {
	    return "No other directories"
	}
    }
}
proc pd {args} {
    if {[string length $args]} {
	eval pushd $args
    } else {
	pushd
    }
}


proc dirs {} {
    global ShelPushPopDirList
    concat [list [pwd]] [lrange $ShelPushPopDirList 1 end]
}

proc popd {} {
    global ShelPushPopDirList
    if {[llength $ShelPushPopDirList]} {
	cd [lindex $ShelPushPopDirList 0]
	set ShelPushPopDirList [lrange $ShelPushPopDirList 1 end]
    } else {
	return "No other directories"
    }
}

