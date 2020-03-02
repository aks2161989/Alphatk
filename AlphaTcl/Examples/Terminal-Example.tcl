## -*-Tcl-*-
 # ###################################################################
 #  Terminal package - example
 # 
 #  FILE: "Terminal-Example.tcl"
 #                                    created: 2001-07-22 12.37.46 
 #                                last update: 2004-05-07
 #  Author: Lars Hellstršm
 #  E-mail: Lars.Hellstrom@math.umu.se
 #  
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2001-07-22 LH  1.0 original
 #  2002-05-29 LH  1.1 improved result message
 #  2003-12-07 LH  1.2 Updates for terminal v1.5
 #  2004-05-07 LH  1.3 Cosmetic enhancements
 # ###################################################################
 ##

##
 # This file demonstrates the terminal package.
 # Press Command-L to execute the script below,
 # and keep an eye on the status line.
 ##

if {[info tclversion]>=8.0} then {
    package require terminal 1.5
}

# Open terminal and log file
# Clean up first, in case something else left the terminal open.
terminal::cleanup
terminal::term_open 1
terminal::log_open [temp::path terminal example-log]

# Do some stuff
terminal::print_word newline "This script finds those of Alpha's\
  Tcl commands which are built-in and undocumented." newline
terminal::print_word emptyline {(The same message again, but\
  now in two separate parts, so that terminal is given a place\
  where it is suitable to break the long line:)} emptyline
terminal::print_word newline "This script finds those of Alpha's\
  Tcl commands which are" space
terminal::print_word space "built-in and undocumented." newline

terminal::begin_progress -title "Listing non-procedures."\
  -percent [llength [info commands]] -relsep 0.01 -period 3 -mintime 10
set cmdlist [list] ; set cnt 0
foreach cmd [info commands] {
    if {![llength [info procs $cmd]] && ![string match .* $cmd]}\
    then {lappend cmdlist $cmd}
    terminal::make_progress [incr cnt]
}
terminal::end_progress
terminal::print_word newline\
  "Found [llength $cmdlist] built-in commands." emptyline

# Do some more stuff
set t [file join $HOME Help {Tcl 8.4 Commands.txt}]
terminal::begin_progress -title "Scanning `$t'." -absolute\
  -abssep 500 -callsep 0 -mintime 300
set sc [scancontext create]
scanmatch $sc {^       ([A-Za-z0-9_]+)  ?- } {
    set cmdlist [lremove $cmdlist $matchInfo(submatch0)]
    terminal::make_progress $matchInfo(linenum)
}
set fid [open $t r]
if {[info tclversion]>=8.0} then {
    scanmatch $sc {terminal::make_progress $matchInfo(linenum)}
    fconfigure $fid -encoding macRoman
}
scanfile $sc $fid
close $fid
scancontext delete $sc
terminal::end_progress

set cmdlist [lremove $cmdlist scancontext scanmatch scanfile]
# These are documented in Tcl Commands, but the documentation 
# is malformed.
terminal::print_word newline "There are [llength $cmdlist]\
  built-in commands for which no definition has been found yet."\
  emptyline

# Do even more stuff
set t [file join $HOME Help {Alpha Commands}]
terminal::begin_progress -title "Scanning `$t'." -fraction\
  -goal [file size $t] -mintime 50
set sc [scancontext create]
scanmatch $sc {^¥ ([A-Za-z0-9_]+)( |$)} {
    set cmdlist [lremove $cmdlist $matchInfo(submatch0)]
    if {![string length $matchInfo(submatch1)]} then {
        terminal::print_err [list "Malformed command description"]\
          [list "Line $matchInfo(linenum) of $t."]
    }
    terminal::make_progress $matchInfo(offset)
}
set fid [open $t r]
if {[info tclversion]>=8.0} then {
    fconfigure $fid -encoding macRoman
}
scanfile $sc $fid
close $fid
scancontext delete $sc
terminal::end_progress


# Check against interal lists, so that the output is more interesting
if {[llength [info commands infox]]} then {
    terminal::print_word emptyline\
      "It seems likely that TclX is loaded;" space
    terminal::print_word space "I will check against an internal list\
      of TclX commands." newline
    set xcmdlist [list]
    foreach cmd {
       dirs commandloop echo infox for_array_keys for_recursive_glob loop
       popd pushd recursive_glob showproc try_eval cmdtrace edprocs profile
       profrep saveprocs alarm execl chroot fork id kill link nice readdir
       signal sleep system sync times umask wait bsearch chmod chown chgrp
       dup fcntl flock for_file funlock fstat ftruncate lgets pipe
       read_file select write_file host_info scancontext scanfile scanmatch
       abs acos asin atan2 atan ceil cos cosh double exp floor fmod hypot
       int log10 log pow round sin sinh sqrt tan tanh max min random
       intersect intersect3 lassign lcontain lempty lmatch lrmdups lvarcat
       lvarpop lvarpush union keyldel keylget keylkeys keylset ccollate
       cconcat cequal cindex clength crange csubstr ctoken ctype replicate
       translit catopen catgets catclose mainloop help helpcd helppwd
       apropos auto_commands buildpackageindex convert_lib loadlibindex
       auto_packages auto_load_file searchpath tclx_fork tclx_load_tndxs
       tclx_sleep tclx_system tclx_wait
    } {
        set n [lsearch -exact $cmdlist $cmd]
        if {$n>=0} then {
            set cmdlist [lreplace $cmdlist $n $n]
            lappend xcmdlist $cmd
        }
    }
    # The following text is not the same on the terminal as
    # it is on the log file.
    terminal::print_word space "[llength $xcmdlist] commands were\
      ignored as TclX commands." space term
    terminal::print_word space "The following probable TclX commands\
      were found:" space log
    foreach cmd [lsort $xcmdlist] {
        terminal::print_word space $cmd space log
    }
}


# Finally show the results
terminal::print_word emptyline "The undocumented commands are:" newline
foreach cmd [lsort $cmdlist] {
    if {[string match *__* $cmd]} then {continue}
    terminal::print_word space $cmd none
}
terminal::print_word emptyline "The following were not found in the\
  documentation either, but that is probably because they have been\
  replaced by a similarly named proc that fixes some bug in Alpha."\
  newline
foreach cmd [lsort $cmdlist] {
    if {![string match *__* $cmd]} then {continue}
    terminal::print_word space $cmd none
}
terminal::print_block emptyline {+-+  } {
    {Disclaimer:} {}
    {The tests performed don't check for Tk commands,\
      hence they probably aren't accurate in Alphatk.}
    {Nor do the tests take differences between Tcl7 and Tcl8 into account.}
    {Nor is there any check for aliases.}
    {}
    {On the other hand, it might have missed undocumented commands}
    {that reside in some namespace other than the global.}
} emptyline
terminal::print_word emptyline "That's all, folks!" newline

# Close terminal and log file
terminal::term_close
terminal::log_close

# Show log file
if {[askyesno "View log file?"]=="yes"} then {
    set F [open [temp::path terminal example-log] r]
    new -n example-log -shell 1 -info [read $F]
    close $F
}
# Delete log file
temp::cleanup terminal


