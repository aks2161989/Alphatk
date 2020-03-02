##
## This is file `terminal.tcl',
## generated with the docstrip utility.
##
## The original source files were:
##
## terminal.dtx  (with options: `pkg')
## 
## The terminal package --  a TeX-like terminal in Tcl
## Copyright (C) 2001 2002 2003  Lars Hellstr\"om
## <Lars.Hellstrom@math.umu.se>
## 
## Tcl-style license:
## The author hereby grants permission to use, copy, modify, distribute,
## and license this software and its documentation for any purpose, provided
## that existing copyright notices are retained in all copies and that this
## notice is included verbatim in any distributions. No written agreement,
## license, or royalty fee is required for any of the authorized uses.
## Modifications to this software may be copyrighted by their authors
## and need not follow the licensing terms described here, provided that
## the new terms are clearly indicated on the first page of each file where
## they apply.
## 
if {[info tclversion]>=8.0} then {
   namespace eval terminal {}
   package provide terminal 1.5
}
if {![llength [info commands alphaHelp]]} then {
   set terminal::implementation tclsh
} elseif {[info tclversion]<8.0} then {
   set terminal::implementation Alpha7
} elseif {${alpha::platform} == "tk"} then {
   set terminal::implementation Alphatk
} elseif {$tcl_platform(platform) == "macintosh"} then {
   set terminal::implementation Alpha8
} else {
   set terminal::implementation AlphaX
}
catch {unset terminal::term_out}
proc terminal::wterm {s} {}
proc terminal::wterm_ln {s} {}
proc terminal::term_open {clear {title {* terminal *}} {file stdout}} {
   global terminal::term_out terminal::term_offset
   if {[info exists terminal::term_out]} then {
      error "The terminal is already open."
   }
   set terminal::term_out $file
   set terminal::term_offset 0
}
proc terminal::term_close {} {
   global terminal::term_out terminal::error_count terminal::term_offset
   if {![info exists terminal::term_out]} then {
      error "The terminal is already closed."
   }
   if {${terminal::term_offset}>0} then {terminal::wterm_ln {}}
   unset terminal::term_out
   set terminal::error_count 0
}
proc terminal::term_flush {} {}
proc terminal::term_autoopen\
  {banner clear {title {* terminal *}} {file stdout}} {
   terminal::term_open $clear $title $file
   foreach line $banner {terminal::wterm_ln $line}
}

set terminal::term_auto ""
switch -- ${terminal::implementation} tclsh {
   proc terminal::wterm {s} {
      global terminal::term_out terminal::term_offset
      puts -nonewline ${terminal::term_out} $s
      incr terminal::term_offset [string length $s]
   }
   proc terminal::wterm_ln {s} {
      global terminal::term_out terminal::term_offset
      puts ${terminal::term_out} $s
      set terminal::term_offset 0
   }
   if {[info tclversion]>=8.0} then {
      proc terminal::term_flush {} {
         variable term_out
         flush $term_out
         update
      }
   } else {
      proc terminal::term_flush {} {
         global terminal::term_out
         flush ${terminal::term_out}
      }
   }
}
switch -- ${terminal::implementation} Alpha7 - Alpha8 - Alphatk {
   proc terminal::wterm {s} {
      global terminal::term_out terminal::term_offset\
        terminal::term_auto
      eval ${terminal::term_auto}
      insertText -w ${terminal::term_out} $s
      incr terminal::term_offset [string length $s]
   }
   proc terminal::wterm_ln {s} {
      global terminal::term_out terminal::term_offset\
        terminal::term_auto
      eval ${terminal::term_auto}
      insertText -w ${terminal::term_out} $s\r
      set terminal::term_offset 0
   }
} AlphaX {
   proc terminal::wterm {s} {
      variable term_auto
      eval $term_auto
      variable term_out
      insertText -w $term_out $s
      variable term_offset
      incr term_offset [string length $s]
      if {[string length $s]} then {
         variable peek_line
         variable peek_lineno
         variable insert_lineno
         if {$peek_lineno != $insert_lineno} then {
            set peek_lineno $insert_lineno
            set peek_line ""
         }
         append peek_line $s
         status::msg "Terminal line ${peek_lineno}: ${peek_line}"
      }
   }
   proc terminal::wterm_ln {s} {
      variable term_auto
      eval $term_auto
      variable term_out
      insertText -w $term_out "$s\r"
      variable term_offset 0
      variable peek_line
      variable peek_lineno
      variable insert_lineno
      if {[string length $s]} then {
         if {$peek_lineno != $insert_lineno} then {
            set peek_lineno $insert_lineno
            set peek_line ""
         }
         append peek_line $s
         status::msg "Terminal line ${peek_lineno}: ${peek_line}"
      }
      incr insert_lineno
   }
}
if {${terminal::implementation} == "Alphatk"} then {
   proc terminal::term_flush {} {update}
}
switch -glob -- ${terminal::implementation} Alpha* {
   proc terminal::term_open {clear {title {* terminal *}} {file stdout}} {
      global terminal::term_out terminal::term_offset\
        terminal::peek_line terminal::peek_lineno\
        terminal::insert_lineno
      if {[info exists terminal::term_out]} then {
         error "The terminal is already open"
      }
      set terminal::term_out $title
      watchCursor
      set terminal::peek_line ""
      set terminal::peek_lineno 0
      set terminal::insert_lineno 1
      if {[lsearch -exact [winNames] $title] == -1} then {
         global terminalmodeVars
         eval new -n \$title\
           [if {[info exists terminalmodeVars(windowGeometry)]}\
            then {set terminalmodeVars(windowGeometry)}]\
           -shell 1 -mode Term
      } elseif {$clear} then {
         bringToFront $title
         deleteText [minPos] [maxPos]
      } else {
         bringToFront $title
         goto [maxPos]
         if {[pos::compare [getPos] > [lineStart [getPos]]]} then {
            insertText \r
         }
         catch {set terminal::insert_lineno\
           [lindex [pos::toRowChar [getPos]] 0]}
      }
      set terminal::term_offset 0
   }
   proc terminal::term_autoopen\
     {banner clear {title {* terminal *}} {file stdout}} {
      global terminal::term_out terminal::term_offset\
        terminal::term_auto terminal::peek_line\
        terminal::peek_lineno terminal::insert_lineno
      if {[info exists terminal::term_out]} then {
         error "The terminal is already open"
      }
      watchCursor
      set terminal::term_out $title
      set terminal::term_offset 0
      set terminal::peek_line ""
      set terminal::peek_lineno 0
      set terminal::insert_lineno 1
      if {[lsearch -exact [winNames] $title] == -1} then {
         set terminal::term_auto\
           [list new -n $title -shell 1 -mode Term]
         global terminalmodeVars
         if {[info exists terminalmodeVars(windowGeometry)]} then {
            append terminal::term_auto " "\
              $terminalmodeVars(windowGeometry)
         }
         append terminal::term_auto ";\
            [list uplevel #0 {set terminal::term_auto ""}];\
            [list foreach line $banner {terminal::wterm_ln $line}]"
      } else {
         if {$clear} then {
            bringToFront $title
            deleteText [minPos] [maxPos]
         } else {
            bringToFront $title
            goto [maxPos]
            if {[pos::compare [getPos] > [lineStart [getPos]]]}\
            then {insertText \r}
            catch {set terminal::insert_lineno\
              [lindex [pos::toRowChar [getPos]] 0]}
         }
         foreach line $banner {terminal::wterm_ln $line}
      }
   }
}
catch {unset terminal::log_out}
proc terminal::wlog {s} {
   global terminal::log_out terminal::log_offset
   puts -nonewline ${terminal::log_out} $s
   incr terminal::log_offset [string length $s]
}
proc terminal::wlog_ln {s} {
   global terminal::log_out terminal::log_offset
   puts ${terminal::log_out} $s
   set terminal::log_offset 0
}
proc terminal::log_flush {} {
   global terminal::log_out
   flush ${terminal::log_out}
}
proc terminal::log_open {name} {
   global terminal::log_out terminal::log_offset
   if {[info exists terminal::log_out]} then {
      error "The log file is already open."
   }
   set terminal::log_out [open $name w]
   set terminal::log_offset 0
}
proc terminal::log_close {} {
   global terminal::log_out terminal::error_count terminal::log_offset
   if {![info exists terminal::log_out]} then {
      error "The log file is already closed."
   }
   if {${terminal::log_offset}>0} then {terminal::wlog_ln {}}
   close ${terminal::log_out}
   unset terminal::log_out
   set terminal::error_count 0
}
proc terminal::meet {t1 args} {
   foreach t2 $args {
      switch $t2 {
         none {set t1 none}
         log {switch $t1 term {set t1 none} both {set t1 log}}
         term {switch $t1 log {set t1 none} both {set t1 term}}
      }
   }
   set t1
}
if {![info exists terminal::max_print_line]} then {
   if {[info exists terminalmodeVars(maxPrintLine)]} then {
      set terminal::max_print_line $terminalmodeVars(maxPrintLine)
   } else {
      set terminal::max_print_line 79
   }
}
set terminal::selector both
proc terminal::print {str {target S} {flush 1}} {
   global terminal::term_out terminal::term_offset terminal::log_out\
     terminal::log_offset terminal::selector terminal::max_print_line
   if {$target=="S"} then {set target ${terminal::selector}}
   set to_term [expr {[info exists terminal::term_out] &&\
     ($target=="both" || $target=="term")}]
   set to_log [expr {[info exists terminal::log_out] &&\
     ($target=="both" || $target=="log")}]
   while {[string length $str]>0} {
      set n ${terminal::max_print_line}
      if {$to_term && ${terminal::term_offset}>0} then {
         set n [expr {${terminal::max_print_line}-${terminal::term_offset}}]
      }
      if {$to_log &&\
        ${terminal::log_offset}+$n>${terminal::max_print_line}} then {
         set n [expr {${terminal::max_print_line}-${terminal::log_offset}}]
      }
      set pstr [string range $str 0 [expr {$n-1}]]
      set str [string range $str $n end]
      if {$to_term} then {
         if {[string length $str]} then {terminal::wterm_ln $pstr} else\
           {terminal::wterm $pstr}
      }
      if {$to_log} then {
         if {[string length $str]} then {terminal::wlog_ln $pstr} else\
           {terminal::wlog $pstr}
      }
   }
   if {$flush && $to_term} then {terminal::term_flush}
   if {$flush && $to_log} then {terminal::log_flush}
}
proc terminal::print_word {before str after {target S} {flush 1}} {
   global terminal::term_out terminal::term_offset terminal::log_out\
     terminal::log_offset terminal::selector terminal::max_print_line\
     terminal::space_after
   if {${terminal::space_after} && $before=="none"}\
   then {set before space}
   set terminal::space_after [expr {$after=="space"}]
   if {$target=="S"} then {set target ${terminal::selector}}
   set to_term [expr {[info exists terminal::term_out] &&\
     ($target=="both" || $target=="term")}]
   set to_log [expr {[info exists terminal::log_out] &&\
     ($target=="both" || $target=="log")}]
   if {$before=="emptyline" && $to_term &&\
      ${terminal::term_offset}<=${terminal::max_print_line}}\
   then {terminal::wterm_ln ""; incr terminal::term_offset}
   if {$before=="emptyline" && $to_log &&\
      ${terminal::log_offset}<=${terminal::max_print_line}}\
   then {terminal::wlog_ln ""; incr terminal::log_offset}
   set n ${terminal::max_print_line}
   if {$to_term && ${terminal::term_offset}>0} then {
      set n [expr {${terminal::max_print_line}-${terminal::term_offset}}]
   }
   if {$to_log &&\
     ${terminal::log_offset}+$n>${terminal::max_print_line}} then {
      set n [expr {${terminal::max_print_line}-${terminal::log_offset}}]
   }
   if {$n < [string length $str]+($before=="space")}\
   then {set before newline}
   if {(!$to_term || ${terminal::term_offset}==0) &&\
     (!$to_log || ${terminal::log_offset}==0)} then {set before none}
   if {$to_term} then {
      if {$before=="space"} then {terminal::wterm \ }\
      elseif {$before!="none"} then {terminal::wterm_ln ""}
   }
   if {$to_log} then {
      if {$before=="space"} then {terminal::wlog \ }\
      elseif {$before!="none"} then {terminal::wlog_ln ""}
   }
   terminal::print $str $target 0
   if {$to_term} then {
      if {$after=="newline"} then {
         terminal::wterm_ln ""
      } elseif {$after=="emptyline"} then {
         terminal::wterm_ln ""
         set terminal::term_offset [expr {${terminal::max_print_line}+1}]
      }
   }
   if {$to_log} then {
      if {$after=="newline"} then {
         terminal::wlog_ln ""
      } elseif {$after=="emptyline"} then {
         terminal::wlog_ln ""
         set terminal::log_offset [expr {${terminal::max_print_line}+1}]
      }
   }
   if {$flush && $to_term} then {terminal::term_flush}
   if {$flush && $to_log} then {terminal::log_flush}
}
set terminal::space_after 0
proc terminal::print_block {before indent lineL after\
  {target S} {flush 1}} {
   global terminal::term_out terminal::term_offset terminal::log_out\
     terminal::log_offset terminal::selector terminal::max_print_line\
     terminal::space_after
   if {$target=="S"} then {set target ${terminal::selector}}
   set to_term [expr {[info exists terminal::term_out] &&\
     ($target=="both" || $target=="term")}]
   set to_log [expr {[info exists terminal::log_out] &&\
     ($target=="both" || $target=="log")}]
   if {$to_term} then {
      if {${terminal::term_offset}>${terminal::max_print_line}} then {
         terminal::wterm_ln ""
      } else {
         if {${terminal::term_offset}>0} then {terminal::wterm_ln ""}
         if {$before=="emptyline"} then {terminal::wterm_ln ""}
      }
   }
   if {$to_log} then {
      if {${terminal::log_offset}>${terminal::max_print_line}} then {
         terminal::wlog_ln ""
      } else {
         if {${terminal::log_offset}>0} then {terminal::wlog_ln ""}
         if {$before=="emptyline"} then {terminal::wlog_ln ""}
      }
   }
   foreach line $lineL {
      set line "$indent$line"
      if {$to_term} then {terminal::wterm_ln $line}
      if {$to_log} then {terminal::wlog_ln $line}
   }
   set terminal::space_after 0
   if {$to_term} then {
      set terminal::term_offset\
        [expr {$after=="emptyline" ? ${terminal::max_print_line}+1 : 0}]
   }
   if {$to_log} then {
      set terminal::log_offset\
        [expr {$after=="emptyline" ? ${terminal::max_print_line}+1 : 0}]
   }
   if {$flush && $to_term} then {terminal::term_flush}
   if {$flush && $to_log} then {terminal::log_flush}
}
set terminal::error_count 0
if {![info exists terminal::max_error_count]} then {
   set terminal::max_error_count 100
}
proc terminal::print_err {msg loc {help {}}} {
   global terminal::log_offset terminal::selector\
     terminal::error_count terminal::max_error_count
   foreach line $msg {terminal::print_word newline "! $line" none S 0}
   terminal::print_word none . newline
   foreach line $loc {terminal::print_word newline $line newline S 0}
   if {[llength $help]>0} then {
      set target [terminal::meet ${terminal::selector} log]
      foreach line [concat [list ""] $help] {
         terminal::print_word newline $line newline $target 0
      }
   }
   terminal::print_word newline "" newline S 1
   incr terminal::error_count
   if {${terminal::error_count}>=${terminal::max_error_count}} then {
      error "That makes ${terminal::error_count} errors,\
        please try again."
   }
}
if {[info tclversion]>=8.0} then {
   set terminal::timer_id ""
   proc terminal::set_timer {ms} {
      variable timer_id
      if {[string length $timer_id]} then {
         after cancel $timer_id
      }
      if {$ms != "clear"} then {
         set timer_id [after $ms {set terminal::timer_id ""}]
      } else {
         set timer_id ""
      }
      variable last_cmdcount [info cmdcount]
   }
   proc terminal::check_timer {} {
      update
      expr { ![
         variable timer_id; string length $timer_id
      ] && [
         variable last_cmdcount; variable cmdcount_sep; info cmdcount
      ] - $last_cmdcount >= $cmdcount_sep}
   }
} else {
   proc terminal::check_timer {} {
      global terminal::last_cmdcount terminal::cmdcount_sep
      expr {[info cmdcount] - ${terminal::last_cmdcount} >=\
        ${terminal::cmdcount_sep}}
   }
   proc terminal::set_timer {ms} {
      global terminal::last_cmdcount
      set terminal::last_cmdcount [info cmdcount]
   }
}
set terminal::marker(fraction) {format \[%d/%d\] $amount $goal}
set terminal::marker(percent)\
   {format \[%1.0f%%\] [expr {100.0*$amount/$goal}]}
set terminal::marker(absolute) {format \[%d\] $amount}
set terminal::marker(status-long) {
   if {$goal>0} then {
      format ": %d of %d (%1.0f%%)"\
        $amount $goal [expr {100.0*$amount/$goal}]
   } else {
      format ": %d" $amount
   }
}
set terminal::marker(status-abs) {format ": %d" $amount}
set terminal::marker(status-none) {terminal::rotate_dash}
proc terminal::rotate_dash {} {
   upvar #0 terminal::marker_sep A
   for {set n 0} {$n<$A(call,delta)} {incr n} {lappend L ""}
   set L [linsert $L $A(call,count) -----]
   string range [join $L] 5 [expr {$A(call,delta)-1}]
}
proc terminal::make_progress {{amount -1} {goal 0}} {
   if {![terminal::check_timer]} then {return}
   set call [list upvar #0]
   foreach var {progress_goal selector marker marker_format\
     marker_sep status_format implementation progress_mintime\
     progress_title} {
       lappend call terminal::$var $var
   }
   eval $call
   if {$goal>0} then {
      set progress_goal $goal
   } elseif {$progress_goal>0} then {
      set goal $progress_goal
   }
   switch -glob -- $implementation Alphatk {
      set target [terminal::meet $selector log]
      status::msg "${progress_title}[if 1 $marker($status_format)]"
      update
   } Alpha* {
      set target [terminal::meet $selector log]
      status::msg "${progress_title}[if 1 $marker($status_format)]"
   } default {
      set target $selector
   }
   terminal::print_word none - none $target
   switch -- $marker_format "none" {} default {
      upvar #0 terminal::marker_sep A
      incr marker_sep(call,count)
      if {
         $marker_sep(call,next)        <= $marker_sep(call,count) &&
         $marker_sep(abs,next)         <= $amount                 &&
         $marker_sep(rel,next) * $goal <= $amount
      } then {
         terminal::print_word space [if 1 $marker($marker_format)]\
           space $target
         set marker_sep(call,count) 0
         set marker_sep(abs,next) [expr {$amount+$marker_sep(abs,delta)}]
         if {$goal>0} then {
            set marker_sep(rel,next)\
              [expr {double($amount)/$goal + $marker_sep(rel,delta)}]
         }
      }
   }
   terminal::set_timer $progress_mintime
}
proc terminal::begin_progress {args} {
   global terminal::progress_goal terminal::marker_sep\
     terminal::marker_format terminal::status_format\
     terminal::cmdcount_sep terminal::progress_mintime\
     terminal::progress_title
   set opt(-title) [list 1 title]
   set title "Processing."
   set terminal::marker_format none
   set opt(-absolute) [list 0 {set terminal::marker_format absolute}]
   set opt(-percent) [list 1 terminal::progress_goal\
     {set terminal::marker_format percent}]
   set opt(-fraction) [list 0 {set terminal::marker_format fraction}]
   set opt(-goal) [list 1 terminal::progress_goal]
   set terminal::progress_goal 0
   set opt(-period) [list 1 period {
      set terminal::cmdcount_sep [expr {100 * $period}]
   }]
   set opt(-mincmds) [list 1 terminal::cmdcount_sep]
   set terminal::cmdcount_sep 0
   set opt(-mintime) [list 1 terminal::progress_mintime]
   set terminal::progress_mintime clear
   set opt(-relsep) [list 1 terminal::marker_sep(rel,delta)]
   set terminal::marker_sep(rel,delta) 0.0
   set opt(-abssep) [list 1 terminal::marker_sep(abs,delta)]
   set terminal::marker_sep(abs,delta) 0
   set opt(-callsep) [list 1 terminal::marker_sep(call,delta)]
   set terminal::marker_sep(call,delta) 10
   while {[llength $args]>0} {
      if {![info exists opt([lindex $args 0])]} then {
         error "Bad option [lindex $args 0]."
      }
      set L $opt([lindex $args 0])
      for {set m 1} {$m<=[lindex $L 0]} {incr m} {
         if {[llength $args]>$m} then {
            set [lindex $L $m] [lindex $args $m]
         } else {
            error "Missing argument for [lindex $args 0] option."
         }
      }
      if {[llength $L]>$m} then {eval [lindex $L $m]}
      set args [lrange $args $m end]
   }
   foreach n {rel abs call} {
      set terminal::marker_sep($n,next)\
         [set terminal::marker_sep($n,delta)]
   }
   set terminal::marker_sep(call,count) 0
   switch ${terminal::marker_format} {
      none     {set terminal::status_format status-none}
      absolute {set terminal::status_format status-abs}
      default  {set terminal::status_format status-long}
   }
   set terminal::progress_title\
     [string trimright $title " \t\r\n.:!,?"]
   terminal::set_timer ${terminal::progress_mintime}
   terminal::print_word newline $title space
}

proc terminal::end_progress {{msg Done.}} {
   terminal::set_timer clear
   terminal::print_word space $msg newline
}
switch -- ${terminal::implementation} Alpha7 - Alpha8 - AlphaX {
   proc terminal::end_progress {{msg Done.}} {
      terminal::set_timer clear
      status::msg ""
      terminal::print_word space $msg newline
   }
} Alphatk {
   proc terminal::end_progress {{msg Done.}} {
      terminal::set_timer clear
      status::msg ""
      terminal::print_word space $msg newline
      update
   }
}
proc terminal::cleanup {} {
   global terminal::log_out terminal::error_count
   set terminal::error_count 0
   if {[info exists terminal::log_out]} then {
      catch {flush ${terminal::log_out}}
   }
   catch {terminal::log_close}
   catch {terminal::term_close}
}
## 
##
## End of file `terminal.tcl'.
