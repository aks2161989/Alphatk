## -*-Tcl-*- nowrap
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "ISOTime.tcl"
 #                                    created: 1999-08-17 13:46:06 
 #                                last update: 2004-05-17 15:15:56 
 #  Author: Frédéric Boulanger
 #  E-mail: Frederic.Boulanger@supelec.fr
 #    mail: Supélec - Service Informatique
 #          Plateau de Moulon, 91192 Gif-sur-Yvette cedex, France
 #     www: http://wwwsi.supelec.fr/fb/fb.html
 #  
 #  Description: 
 #  
 #    See help section of alpha::extension below.
 #   
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  1999-08-17 FBO 1.0 original
 #  1999-08-18 FBO 1.1 added year, month ... keywords for direct access
 #  1999-08-26 FBO 1.2 made the date&time really ISO (YYYY-MM-DDTHH:MM:SSZ)
 #  1999-09-02 VMD 1.3 made work with Alphatk, and fixed some Tcl8 isms
 #  1999-11-04 FBO 1.4 added "relaxed" for a more readable ISO format
 #  2001-09-?? ??? 1.5 get TimeZone with Johan Linde's AE code
 #  2001-09-19 FBO 1.6 added support for now and utc argument to mtime
 #  2003-11-06 FBO 1.7 fixed regdate, use 'join' on mtime result.
 #  2004-05-13 FBO 1.8 support for different epochs, use 'clock' if available
 # ###################################################################
 ##
alpha::extension isoTime 1.8 {
  # Time-stamps are in ISO or a shorter, more readable format.
  newPref variable timeStampStyle short global "" "short iso relaxed"
  lunion varPrefs(International) timeStampStyle
  namespace eval ISOTime {}
  if {[info command ISOTime::__mtime] == ""} {
    rename mtime ISOTime::__mtime
    proc mtime {when {format "short"} {epoch ""}} {
      switch -- $format {
	relaxed {ISOTime::ISODateAndTimeRelaxed $when $epoch}
	iso     {ISOTime::ISODateAndTime $when $epoch}
	zone    -
	year    -
	month   -
	day     -
	hour    -
	minutes -
	seconds {
	  ISOTime::brokenDate $when bdate $epoch
	  return $bdate($format)
	}
	default {
	  switch -- $when {
	    now {set when [now]}
	    utc {set when [expr [now] - [ISOTime::ZoneOffset]]}
            default {
              set when [ISOTime::toEpoch $epoch $when]
            }
	  }
	  ISOTime::__mtime $when $format
	}
      }
    }
  }
} maintainer {
    "Frédéric Boulanger" <Frederic.Boulanger@supelec.fr> <http://wwwsi.supelec.fr/fb/fb.html>
} description {
    Adds new options for the second parameter (format) of the [mtime] command
} help {
    This extension adds new choices for the second parameter (format) of the
    command: mtime .

	mtime [now] iso
	
    returns the current time in ISO format, i.e.

	1999-08-17T14:55:22Z

    for

	August 17 1999 at 2:55:22 pm.

    The final "Z" means UTC or Universal Time.  If your local time zone is
    offset from UTC, the "Z" is replaced by its offset.  For instance:
    "1999-08-17T14:55:22+02:00" represents a date/time in a time zone where
    the local time is 2 hours later than UTC.

    Using "relaxed" instead of "iso" yields a more readable date with a
    space in place of the 'T' and without the final 'Z' or zone offset.

    The other choices are 'zone', 'year', 'month', 'day', 'hour', 'minutes',
    and 'seconds' to get the respective piece of time information.

    The first argument of mtime may be a number of second elapsed since the
    reference date of the OS, or the string "now" which represents the
    current local date and time, or the string "utc" which represents the
    current universal date and time.

    The reference date -- or "epoch" -- can be specified as a third argument
    to mtime. "mac" is the traditional Mac OS epoch (January 1st 1904),
    and "unix" is the Unix epoch (January 1st 1970). The epoch is ignored
    when the first argument to mtime is either "now" or "utc".
    
    The default epoch should be used to process dates returned by platform-
    specific procedures, like 'getFileInfo'. The "unix" epoch should be used
    to process dates returned by core Tcl commands like "clock" or "file".
    
    Note: This extension may yield incorrect results if you change the time
    format or the time zone in the 'Date and Time' control panel while Alpha
    is running.

    The effective format of the localized time representation is determined
    by the proc: ISOTime::parseLocalizedTime which is called only once for
    the sake of efficiency.

    If this behaviour may cause problem and you don't use the ISOTime procs
    too often, you may remove the check for ISOTime::regdate and
    ISOTime::matchdate at the beginning of the proc: ISOTime::brokenDate so
    that it rebuilds the regexps at each call.  The same is true for the
    proc: ISOTime::TimeZone and the proc: ISOTime::ZoneOffset .
}

# Set default epoch according to the platform that implements "mtime"
if {${alpha::platform} != "alpha"} {
  set ISOTime::systemEpoch "unix"
} else {
  set ISOTime::systemEpoch "mac"
}

# Work around peculiarity of Tcl that '09' is not an integer,
# but a base 8 number, and that int(09) will give an error.
proc ISOTime::int {what {plus 0}} {
  regsub {^0+([1-9])} $what \\1 what
  return [expr {int($what + $plus)}]
}

# Build an ISO representation of the date corresponding to the 'when' MacOS 
# ticks. Uses ISOTime::brokenDate to get a localization independent representation 
# of time. The ISO date is in the form 'YYYY-MM-DD'.
proc ISOTime::ISODate {{when "now"} {epoch ""}} {
  ISOTime::brokenDate $when curDate $epoch
  return "[format "%.4u" $curDate(year)]-[format "%.2u" $curDate(month)]-[format "%.2u" $curDate(day)]"
}

# Same with time added in the form 'THH:MM:SSZ'
proc ISOTime::ISODateAndTime {{when "now"} {epoch ""}} {
  ISOTime::brokenDate $when curDate $epoch
  return "[format "%.4u" $curDate(year)]-[format "%.2u" $curDate(month)]-[format "%.2u" $curDate(day)]T[format "%.2u" $curDate(hour)]:[format "%.2u" $curDate(minutes)]:[format "%.2u" $curDate(seconds)]$curDate(zone)"
}

# Same with time added in the form ' HH:MM:SS' (not strict ISO, but more readable
proc ISOTime::ISODateAndTimeRelaxed {{when "now"} {epoch ""}} {
  ISOTime::brokenDate $when curDate $epoch
  return "[format "%.4u" $curDate(year)]-[format "%.2u" $curDate(month)]-[format "%.2u" $curDate(day)] [format "%.2u" $curDate(hour)]:[format "%.2u" $curDate(minutes)]:[format "%.2u" $curDate(seconds)]"
}

if {([info commands clock] != "") && ![catch {clock format [clock seconds]}]} {
##
# New code using 'clock' when available
##
  # Convert seconds from 'epoch' to the unix epoch (used by 'clock').
  proc ISOTime::fromEpoch {epoch when} {
    global ISOTime::systemEpoch
    
    if {$epoch == ""} {
      set epoch [set ISOTime::systemEpoch]
    }
    
    if {$epoch == "unix"} {
      return $when
    } elseif {$epoch == "mac"} {
      set when [expr $when + [clock scan "1904-01-01Z00:00:00"]]
      return [expr $when - [ISOTime::ZoneOffset $when "unix"]]
    } else {
      error "ISOTime error: Unknown epoch \"$epoch\""
    }
  }

  # Convert seconds from 'epoch' to the system epoch (used by 'mtime').
  proc ISOTime::toEpoch {epoch when} {
    global ISOTime::systemEpoch
    
    if {$epoch == ""} {
      set epoch [set ISOTime::systemEpoch]
    }
    
    if {$epoch == [set ISOTime::systemEpoch]} {
      return $when
    } elseif {$epoch == "mac"} {
      set when [expr $when + [clock scan "1904-01-01Z00:00:00"]]
      return [expr $when - [ISOTime::ZoneOffset $when "unix"]]
    } elseif {$epoch == "unix"} {
      set when [expr $when - [clock scan "1904-01-01Z00:00:00"]]
      return [expr $when + [ISOTime::ZoneOffset $when "mac"]]
    } else {
      error "ISOTime error: Unknown epoch \"$epoch\""
    }
  }

  proc ISOTime::brokenDate {{when "now"} {datevar "theDate"} {epoch ""}} {
    upvar 1 $datevar date

    if {($when == "now") || ($when == "utc")} {
      set theTicks [clock seconds]
    } else {
      set theTicks [ISOTime::fromEpoch $epoch [string trim $when]]
    }
    if {$when == "utc"} {
      set gmt 1
      set date(zone) "Z"
    } else {
      set gmt 0
      set date(zone) [ISOTime::TimeZone $theTicks "unix"]
    }
    
#     set date(zone) [clock format $theTicks -format "%Z" -gmt $gmt]

    set date(year) [ISOTime::int [clock format $theTicks -format "%Y" -gmt $gmt]]
    set date(month) [ISOTime::int [clock format $theTicks -format "%m" -gmt $gmt]]
    set date(day) [ISOTime::int [clock format $theTicks -format "%d" -gmt $gmt]]
    set date(hour) [ISOTime::int [clock format $theTicks -format "%H" -gmt $gmt]]
    set date(minutes) [ISOTime::int [clock format $theTicks -format "%M" -gmt $gmt]]
    set date(seconds) [ISOTime::int [clock format $theTicks -format "%S" -gmt $gmt]]

    return $theTicks
  }

  proc ISOTime::TimeZone {{when now} {epoch ""}} {
    set offset [ISOTime::ZoneOffset $when $epoch]
    if {$offset < 0} {
      return [format "-%.2u:%.2u" [expr abs($offset)/3600] [expr (abs($offset)%3600)/60]]
    } else {
      return [format "+%.2u:%.2u" [expr $offset/3600] [expr ($offset % 3600)/60]]
    }
  }

  proc ISOTime::ZoneOffset {{when now} {epoch ""}} {
    if {($when == "now") || ($when == "utc")} {
      set when [clock seconds]
    } else {
      set when [ISOTime::fromEpoch $epoch $when]
    }
    
    set dh [expr \
       [ISOTime::int [clock format $when -format "%H" -gmt 0]] \
     - [ISOTime::int [clock format $when -format "%H" -gmt 1]]]
    set dm [expr \
       [ISOTime::int [clock format $when -format "%M" -gmt 0]] \
     - [ISOTime::int [clock format $when -format "%M" -gmt 1]]]
    return [expr 3600*$dh+60*$dm]
  }
} else {
##
# Old implementation using regexp
##
  # Number of seconds from the epoch to April 3 1905 at 06:07:08 am
  # clock scan "1905-04-03Z06:07:08"  -> -2043251572
  array set ISOTime::April3Of1905 {
    unix -2043251572
    mac 39593228
  }

  # January first of 2000 at 00:00:00
  array set ISOTime::turnOfTheCentury {
    unix 946684800
    mac 3029529600
  }

  # Determine the format of the localized time representation and build a
  # regular expression to extract each piece of information from this format.
  # 
  # To get this information, I use the localized string representing
  # a known date: March 2 1904 at 5 am, 6 minutes and 7 seconds (5288767 
  # MacOS ticks). In this string, I look for '2' which is the day of month,
  # for '3' which is the month, for '4' which is the year, for '5' which is
  # the minutes and for '7' which is the seconds.
  # 
  # Once I got the indices of each piece of information in the string, I build
  # a list of 'XX YY info' items, where XX is the starting index, YY is the 
  # ending index for the 'info' piece of information (day, month, year...).
  # 
  # I sort this list so that I know in which order the time information is
  # given on the current localized version of MacOS.
  # 
  # Then, I use this list to build a regular expression that matches the 
  # localized representation of time, and a matching expression which will
  # set the items of the 'datevar' array to the corresponding time 
  # information.
  # 
  # March 2 1904 at 5 am, 6 minutes and 7 seconds is 5288767
  # April 3 1905 at 6 am, 7 minutes and 8 seconds is 39593228
  proc ISOTime::parseLocalizedTime {} {
    global ISOTime::regdate ISOTime::matchdate
    global ISOTime::systemEpoch

    set epoch [set ISOTime::systemEpoch]
    if {![info exists ISOTime::April3Of1905($epoch)]} {
      error "ISOTime error: Unknown epoch \"$epoch\""
    }
    set known [ISOTime::__mtime $ISOTime::April3Of1905($epoch) short]

    regexp -indices {(.*[^0-9])*(0?3)[^0-9]*.*} $known z pr day  
    regexp -indices {(.*[^0-9])*(0?4)[^0-9]*.*} $known z pr month  
    # '20' is temporary fix for buggy dev version of Alpha
    regexp -indices {(.*[^0-9])*((19|20)?0?5)[^0-9]*.*} $known z pr year  
    regexp -indices {(.*[^0-9])*(0?6)[^0-9]*.*} $known z pr hour  
    regexp -indices {(.*[^0-9])*(0?7)[^0-9]*.*} $known z pr minutes  
    regexp -indices {(.*[^0-9])*(0?8)[^0-9]*.*} $known z pr seconds

    if {[catch {list $day $month $year $hour $minutes $seconds}]} {
      error "Wrong setting for ISOTime::April3Of1905($epoch)"
    }
    
    set order ""
    lappend order "[format "%.2d" [lindex $day 0]] [format "%.2d" [lindex $day 1]] day"
    lappend order "[format "%.2d" [lindex $month 0]] [format "%.2d" [lindex $month 1]] month"
    lappend order "[format "%.2d" [lindex $year 0]] [format "%.2d" [lindex $year 1]] year"
    lappend order "[format "%.2d" [lindex $hour 0]] [format "%.2d" [lindex $hour 1]] hour"
    lappend order "[format "%.2d" [lindex $minutes 0]] [format "%.2d" [lindex $minutes 1]] minutes"
    lappend order "[format "%.2d" [lindex $seconds 0]] [format "%.2d" [lindex $seconds 1]] seconds"
    set order [lsort $order]
    set ISOTime::regdate ""
    set ISOTime::matchdate ""
    if {[lindex [lindex $order 0] 0] == 0} {
      append ISOTime::regdate {([0-9]*)}
    } else {
      append ISOTime::regdate [string range $known 0 0]
    }
    append ISOTime::matchdate "set date([lindex [lindex $order 0] 2]) \\1;"
    set tmp [ISOTime::int [lindex [lindex $order 0] 1] 1]
    append ISOTime::regdate "\\[string range $known $tmp $tmp]"

    append ISOTime::regdate {([0-9]*)}
    append ISOTime::matchdate "set date([lindex [lindex $order 1] 2]) \\2;"
    set tmp [ISOTime::int [lindex [lindex $order 1] 1] 1]
    append ISOTime::regdate "\\[string range $known $tmp $tmp]"

    append ISOTime::regdate {([0-9]*)}
    append ISOTime::matchdate "set date([lindex [lindex $order 2] 2]) \\3;"
    set tmp [ISOTime::int [lindex [lindex $order 2] 1] 1]
    append ISOTime::regdate "\\[string range $known $tmp $tmp]"

    append ISOTime::regdate {([0-9]*)}
    append ISOTime::matchdate "set date([lindex [lindex $order 3] 2]) \\4;"
    set tmp [ISOTime::int [lindex [lindex $order 3] 1] 1]
    append ISOTime::regdate "\\[string range $known $tmp $tmp]"

    append ISOTime::regdate {([0-9]*)}
    append ISOTime::matchdate "set date([lindex [lindex $order 4] 2]) \\5;"
    set tmp [ISOTime::int [lindex [lindex $order 4] 1] 1]
    append ISOTime::regdate "\\[string range $known $tmp $tmp]"

    append ISOTime::regdate {([0-9]*)}
    append ISOTime::matchdate "set date([lindex [lindex $order 5] 2]) \\6;"

    append ISOTime::regdate {(.*)?}
    append ISOTime::matchdate "set date(modifiers) \\7;"
  }

  # Convert seconds from 'epoch' to the system epoch.
  proc ISOTime::fromEpoch {epoch when} {
    global ISOTime::systemEpoch
    global ISOTime::April3Of1905
    
    if {($epoch == "") || ($epoch == [set ISOTime::systemEpoch])} {
      return $when
    }
    if {![info exists ISOTime::April3Of1905($epoch)]} {
      error "ISOTime error: Unknown epoch \"$epoch\""
    }
    return [expr $when - [set ISOTime::April3Of1905($epoch)] \
                       + [set ISOTime::April3Of1905([set ISOTime::systemEpoch])]]
  }

  # Convert seconds from 'epoch' to the system epoch (used by 'mtime').
  proc ISOTime::toEpoch {epoch when} {
    return [ISOTime::fromEpoch $epoch $when]
  }

  # Extract time information from the MacOS ticks 'when', and put it
  # in the 'datevar' variable. This information is independent of the
  # time display format of your localized version of MacOS.
  # 
  # Using 'regsub', I apply a regular expression to the localized 
  # representation of 'when', and this builds the command that sets
  # the items of the 'datevar' array. I evaluate this command, and 
  # 'datevar' now holds time information in a localization independent 
  # form.
  # The regular expression and the transformation expression are built by the
  # ISOTime::parseLocalizedTime proc. To save time, this proc is called only if 
  # the regular expressions are not defined. This assumes that you don't 
  # change the date format while Alpha is running.
  # 
  # The next step is to trim leading '0' so that the items of the array 
  # are simple numbers. 
  # 
  # A final step adds 1900 or 2000 to the year if it is lower than 100.  
  # I use the fact that the MacOS ticks 3029529600 represent 
  # January 1st 2000 at 0 hour, 0 minutes and 0 seconds.
  # 
  # brokenDate $when theDate sets 'theDate' so that:
  #   theDate(zone)     contains the zone used to break this date
  #   theDate(year)     contains the year of the 'when' MacOS ticks
  #   theDate(month)    contains the month of the 'when' MacOS ticks
  #   theDate(day)      contains the day of month of the 'when' MacOS ticks
  #   theDate(hour)     contains the hour of the 'when' MacOS ticks
  #   theDate(minutes)  contains the minutes of the 'when' MacOS ticks
  #   theDate(seconds)  contains the seconds of the 'when' MacOS ticks
  # 

  proc ISOTime::brokenDate {{when "now"} {datevar "theDate"} {epoch ""}} {
    global ISOTime::regdate ISOTime::matchdate ISOTime::systemEpoch
    upvar 1 $datevar date

    if {$epoch == ""} {
      set epoch [set ISOTime::systemEpoch]
    }
    
    set date(modifiers) ""
    set date(zone) [ISOTime::TimeZone]
    if {$when == "now"} {
      set theTicks [now]
    } elseif {$when == "utc"} {
      set theTicks [expr [now] - [ISOTime::ZoneOffset]]
      set date(zone) "Z"
    } else {
      set theTicks [ISOTime::fromEpoch $epoch [string trim $when]]
    }

    if {(![info exists ISOTime::regdate]) \
     || (![info exists ISOTime::matchdate])} {
      ISOTime::parseLocalizedTime
    }

    regsub [set ISOTime::regdate] \
     [join [ISOTime::__mtime $theTicks]] \
     [set ISOTime::matchdate] dateCmd
    eval $dateCmd

    set pm 0
    if {[regexp -nocase "p" $date(modifiers)] && ($date(hour) < 12)} { 
        set pm "12"
    }
    if {[regexp -nocase "a" $date(modifiers)] && ($date(hour) == 12)} { 
        set pm "-12" 
    }

    set date(year) [ISOTime::int $date(year)]
    set date(month) [ISOTime::int $date(month)]
    set date(day) [ISOTime::int $date(day)]
    set date(hour) [ISOTime::int $date(hour) $pm]
    set date(minutes) [ISOTime::int $date(minutes)]
    set date(seconds) [ISOTime::int $date(seconds)]

    if {$date(year) < 100} {
        set posTicks $theTicks
        if {$theTicks < 0} {
            set posTicks [expr 0xffffffff + $theTicks + 1]
        }
        if {$posTicks < [set ISOTime::turnOfTheCentury([set ISOTime::systemEpoch])]} {
            set date(year) [expr $date(year) + 1900]
        } else {
            set date(year) [expr $date(year) + 2000]
        }
    }
    return $theTicks
  }

  proc ISOTime::TimeZone {{when now} {epoch ""}} {
  # ISOTime::TimeZone contains either "Z" or the time zone offset in 
  # human readable form (HH:MM).
  # ISOTime::ZoneOffset contains the algebraic time zone offset in seconds.
    global ISOTime::TimeZone ISOTime::ZoneOffset tclplatform
    if {![info exists ISOTime::TimeZone]} {
      if {[catch {tclAE::build::resultData -s syso "GMT "} gmt]} {
        set ISOTime::TimeZone Z
        set ISOTime::ZoneOffset 0
      } else {
        set ISOTime::ZoneOffset $gmt
        set ISOTime::TimeZone [format "%.2u" \
         [expr {abs($gmt)/3600}]]:[format "%.2u" [expr {(abs($gmt) % 3600)/60}]]
        if {$gmt < 0} {
          set ISOTime::TimeZone "-${ISOTime::TimeZone}"
        } else {
          set ISOTime::TimeZone "+${ISOTime::TimeZone}"
        }
      }
    }
    return ${ISOTime::TimeZone}
  }

  proc ISOTime::ZoneOffset {{when now} {epoch ""}} {
    global ISOTime::ZoneOffset
    if {![info exists ISOTime::ZoneOffset]} {
      ISOTime::TimeZone
    }
    return ${ISOTime::ZoneOffset}
  }
}
#
# End of ISOTime.tcl
