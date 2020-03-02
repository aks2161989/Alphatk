##
## This is file `terminalPrefsAlpha.tcl',
## generated with the docstrip utility.
##
## The original source files were:
##
## terminal.dtx  (with options: `alpha')
## 
## The terminal package --  a TeX-like terminal in Tcl
## Copyright (C) 2001-2006 2002 2003  Lars Hellstr\"om
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
alpha::library terminal 1.5.1 {
   if {[catch {package present terminal}]} then {
      package ifneeded terminal 1.5 {terminal::cleanup}
      # status::msg "Had to supply \[package ifneeded\] script for\
      #   terminal package."
   }
   # The default maximal line width (in characters). Programs
   # using the terminal are allowed to override this value.
   newPref variable maxPrintLine 79 terminal terminal::do_max_print_line
   # The default geometry (bounding rectangle) of the terminal
   # window.
   newPref geometry windowGeometry "" terminal ; #terminal::do_window
   proc TermmodifyFlags {} {prefs::dialogs::packagePrefs terminal}
} uninstall {
   file delete [file join $HOME Tcl Packages terminalPrefsAlpha.tcl]
   file delete [file join $HOME Tcl Packages terminal.tcl]
   file delete [file join $HOME Help "Terminal Help"]
   file delete [file join $HOME Examples Terminal-Example.tcl]
   file delete -force [file join $HOME Developer Source terminal]
} maintainer [
  list "Lars Hellstr\u00F6m" Lars.Hellstrom@math.umu.se
] help {
   file "Terminal Help"
} description {
   Provides output-only terminal windows in Alpha or a generic tclsh.
}
alpha::feature terminalPuts 1.5.1 global-only {
   package::addPrefsDialog terminal
   # To have the terminal package handle [puts stdout] and
   # [puts stderr], click this box. || To restore the default
   # definition of [puts stdout] and [puts stderr], click this box.
   newPref flag takeOverPuts [expr {[info tclversion]<8.0}] terminal \
     terminal::manage_puts
} {
   terminal::manage_puts "Activation---the magic word is ON."
} {
   terminal::manage_puts "Deactivation---the magic word is OFF."
} maintainer [
  list "Lars Hellstr\u00F6m" Lars.Hellstrom@math.umu.se
] help {
    The terminal-puts feature supports redirecting 'puts' commands
    for stdout or stderr to the window managed by the terminal
    package. See "Terminal Help" for more information.
} description {
   Redirects 'puts stdout' to a separate Alpha terminal window.
}
proc terminalPrefsAlpha.tcl {} {}
namespace eval terminal {}
proc terminal::manage_puts {args} {
   switch -- [lindex $args 0] {
      "Activation---the magic word is ON." {set active 1}
      "Deactivation---the magic word is OFF." {set active 0}
      default {set active [package::active terminalPuts]}
   }
   global terminalmodeVars
   if {$active && $terminalmodeVars(takeOverPuts)}\
   then {
      uplevel #0 {
         if {[llength [info commands terminal::__puts]]} then {return}
         if {[info tclversion]>=8.0} then {package require terminal}
         rename puts terminal::__puts
         ;proc puts {args} {
            if {[llength $args]==1} then {
               set file stdout
               set nl 1
            } elseif {[llength $args]==2} then {
               if {[lindex $args 0]=="-nonewline"} then {
                  set file stdout
                  set nl 0
               } else {
                  set file [lindex $args 0]
                  set nl 1
               }
            } elseif {[llength $args]==3} then {
               if {[lindex $args 0]=="-nonewline"} then {
                  set file [lindex $args 1]
                  set nl 0
               }
            }
            if {![info exists file]} then {
               return -code error {"wrong # args: should be\
                 "puts ?-nonewline? ?channelId? string"}
            }
            switch -- $file stdout - stderr {
               if {![uplevel #0 {info exists terminal::term_out}]}\
               then {terminal::term_open 0}
               if {[catch {
                  if {$nl} then {
                     terminal::wterm_ln [lindex $args end]
                  } else {
                     terminal::wterm [lindex $args end]
                  }
               }]} then {
                  terminal::cleanup
                  terminal::term_open 0
                  if {$nl} then {
                     terminal::wterm_ln [lindex $args end]
                  } else {
                     terminal::wterm [lindex $args end]
                  }
               }
            } default {
               eval [list terminal::__puts] $args
            }
         }
      }
   } else {
      uplevel #0 {
         if {[llength [info procs puts]] &&\
           [llength [info commands terminal::__puts]]} then {
            rename puts {}
            rename terminal::__puts puts
         }
      }
   }
}
proc terminal::do_max_print_line {{pref_name ""}} {
   global terminalmodeVars terminal::max_print_line
   set terminal::max_print_line $terminalmodeVars(maxPrintLine)
}
## 
##
## End of file `terminalPrefsAlpha.tcl'.
