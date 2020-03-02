## -*-Tcl-*- (indentationAmount:2)
 # ###################################################################
 # 
 #  FILE: "inshMode.tcl"
 #                                    created: 2003-06-06 17:25:37 
 #                                last update: 02/08/2006 {03:07:18 PM} 
 #  Author: Frédéric Boulanger
 #  E-mail: Frederic.Boulanger@supelec.fr
 #    mail: Supélec - Service Informatique
 #          3 rue Joliot-Curie, F-91192 Gif-sur-Yvette cedex
 #     www: http://wwwsi.supelec.fr/fb/
 #  
 #  Description: 
 # 
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2003-06-06 FBO 1.0 original
 #  2003-06-24 FBO 1.2 use vwait to wait for socket ID in array
 #  2003-09-12 FBO 1.3 dissociate interaction and creation of the tasks
 #  2005-01-31 VMD 1.3.5 no need for InSh mode.  Use composite modes on 
 #  top of Text mode.
 # ###################################################################
 ##
namespace eval InSh {}

alpha::library InSh 1.3.6 {
  # Initialization script.
  alpha::internalModes "InSh"
} maintainer {
  "Fr\u00e9d\u00e9ric Boulanger" \
  <Frederic.Boulanger@supelec.fr> \
  <http://wwwsi.supelec.fr/fb/fb.html>
} uninstall {
    this-file
} description {
    Provides internal support for [In]teractive [Sh]ell windows in Alpha
} help {
    This mode enables the display the output from an external program in an
    Alpha window, and can also send characters typed in the window to the
    program input.  Windows that use InSh mode behave like interactive shells.
    However, InSh mode is not a terminal emulator, so programs that use
    special control sequences to hilight text or to move the cursor may not
    work as expected.
    
    If you're working in a Unix environment (such as Mac OS X), you can test
    this experimental code for creating Unix Shell windows:
    
    <<unixShell>>
    
    <<unixShellForTopWindow>>
    
    Similarly with Cygwin's /bin/sh, you can use this equally well on
    Windows.  And, even without Cygwin, there are simple windows-native
    /bin/sh implementations which will work fine on Windows 2000/XP.
}

#   if {$::tcl_platform(platform) eq "unix"} {
#     menu::insert "Utils" items "wordCount" "<EunixShell" "<SunixShellForTopWindow"
#   }

proc dummyInSh {} {}

proc initInSh {} {
  global ::InSh::lineEndings
  
  switch -- $::tcl_platform(platform) {
    "macintosh" {
      set ::InSh::lineEndings cr
    }
    "unix" {
      set ::InSh::lineEndings lf
    }
    "windows" {
      set ::InSh::lineEndings crlf
      # Currently use automatic line conversion on Windows
      set ::InSh::lineEndings auto
    }
  }
  
  namespace eval ::xserv {}
  ::xserv::declare UnixShell {Provide an interactive Unix-like shell}

  ::xserv::register UnixShell tcsh -mode InSh -progs {tcsh} -driver {
    return "$params(xserv-tcsh) -i"
  } -ignore {
    {Warning: no access to tty \(Bad file descriptor\)\.\n}
    {Thus no job control in this shell\.\n}
  }
  
  ::xserv::register UnixShell sh -mode InSh -progs {sh} -driver {
    return "$params(xserv-sh) -i"
  } -ignore {
    {sh: no job control in this shell\n}
    {readline: warning: rl_prep_terminal: cannot get terminal settings}
  }
}

initInSh

proc unixShell {{path ""}} {
  set in [::xserv::invoke UnixShell]
  if {$path != ""} {
    puts $in "cd [::xserv::quoteForShell $path]"
  }
}

proc unixShellForTopWindow {} {
  set win [win::Current]
  if {$win != ""} {
    if {[win::IsFile $win]} {
      unixShell [file dirname $win]
      return
    }    
  }
  unixShell
}

alpha::minormode "InSh" \
 +bindtags          "InSh" \
 +featuremodes      "InSh" \
 +hookmodes         "InSh" \
 +varmodes          "InSh"

# <RETURN> and <ENTER> keys send data to the program
Bind '\r' InSh::carriageReturn InSh
# \n is illegal in Alphatk, and I don't believe it does anything in
# Alpha.
#Bind '\n' InSh::carriageReturn InSh
Bind Enter InSh::carriageReturn InSh
Bind 0x34 InSh::carriageReturn InSh

# <TAB> should just send a tab. Doesn't work like in a real terminal yet
Bind '\t' InSh::sendTab InSh
Bind 0x30 InSh::sendTab InSh

# Up and Down navigate the history of commands (or data sent)
Bind Up InSh::prevHist InSh
Bind Up <o> {} InSh
Bind Down InSh::nextHist InSh
Bind Down <o> {} InSh

# Ctrl-u kills the line
Bind 'u' <z> InSh::killLine InSh

# Prevent cursor from going before prompt
Bind Left InSh::checkLeftMove InSh

# Prevent deletion of the prompt
Bind Clear InSh::checkLeftDel InSh
Bind 0x33 InSh::checkLeftDel InSh
Bind Clear <o> ::InSh::checkLeftDel InSh
Bind 0x33 <o> ::InSh::checkLeftDel InSh

# Cmd-Clear clears the window
Bind Clear <c> ::InSh::clearWindow InSh
Bind 0x33 <c> ::InSh::clearWindow InSh

# Ctrl-d closes the input stream (and kills the program)
Bind 'd' <z> {InSh::cleanup [win::Current]} InSh

# Close all sockets when the window is closed
hook::register closeHook InSh::killWindow InSh

# Create an interactive shell.
#
# "name" is the name of the window.
# 
# "params" is a list. The first item in the list must be the process ID 
#          of the program which will run in the window, the second item
#          must be the output channel of the program, from which data 
#          will be read and displayed in the window. The third item is 
#          the input channel and is optional. If the input channel is 
#          present, data typed into the window will be written (line by 
#          line) to that channel. The channels may be pipes, sockets or files.
#          
# "closeProc" is the code to execute when the program terminates. This code
#          should close the streams used to communicate with the program,
#          among other tasks.
# 
# "ignorepat" is a list of patterns that should be removed from the output 
#           of the program.
#   "ignorepat" is useful when a program periodically emits warning because
#   its standard input is not connected to a terminal. Using this warning
#   as an item of the "ignorepat" list makes life much easier.
#   For instance, when executing sh in an InSh window, "ignorepat" should be
#   set to {"readline: warning: rl_prep_terminal: cannot get terminal settings"}.
# 
#   "ignorepat" can also be used to hide the prompt of a shell which is only
#   used to execute another command.
proc InSh::createShell {name params closeProc {ignorepat {}} {m Text}} {
  if { [lsearch -exact [winNames] $name] < 0 } {
    # If the shell window does not exist, create it.
    win::setInitialConfig $name minormode "InSh" window
    if {$m eq ""} { set m "Text" }
    new -n $name -shell 1 -mode $m
  } else {
    # If the window already exists, do nothing (raise an error?)
    InSh::killWindow $name
    deleteText -w $name [minPos -w $name] [maxPos -w $name]
  }
  InSh::makeShell $name $params $closeProc $ignorepat
}

# Once the window has been created/cleared, makeShell does the real work.
proc InSh::makeShell {name params closeProc ignorepat} {
  # The following arrays are indexed by the name of the shell windows
  # 
  # InSh::inputStream(<name>) = stream for input to the program in window <name>
  global ::InSh::inputStream
  # InSh::outputStream(<name>) = stream for output of the program in window <name>
  global ::InSh::outputStream
  # InSh::closeCode(<name>) = code to execute at the end of the program <name>
  global ::InSh::closeCode
  # InSh::lastPosition(<name>) = position after last data written to window <name>
  global ::InSh::lastPosition
  # InSh::processID(<name>) = process ID for window <name>
  global ::InSh::processID
  # InSh::currHist(<name>) = index in history of window <name>
  global ::InSh::currHist
  # InSh::histList(<name>) = history (list of data sent to stdin) in window <name>
  global ::InSh::histList
  # InSh::ignorePats(<name>) = patterns to ignore in window <name>
  global ::InSh::ignorePats
  # InSh::lineEndings = line endings on this platform (cr, lf or crlf)
  global ::InSh::lineEndings
  
  # Initialize history
  set ::InSh::currHist($name) -1
  set ::InSh::histList($name) [list]
  set ::InSh::lastPosition($name) [minPos]
  
  set ::InSh::closeCode($name) $closeProc
  
  set ::InSh::processID($name) [lindex $params 0]
  set ::InSh::ignorePats($name) $ignorepat
  if { [llength $ignorepat] == 0 } {
    unset ::InSh::ignorePats($name)
  }
  
  # Get the output stream
  set ::InSh::outputStream($name) [lindex $params 1]
  # Configure it right (result of several tries...)
  fconfigure [set ::InSh::outputStream($name)] \
   -buffering none -translation [set ::InSh::lineEndings] -blocking 0
  # Register ::InSh::processOutput to process data from this socket.
  fileevent [set ::InSh::outputStream($name)] readable \
   [list ::InSh::processOutput $name [set ::InSh::outputStream($name)]]
 
  # Get the input stream if any
  if {[llength $params] > 2} {
    set ::InSh::inputStream($name) [lindex $params 2]
    fconfigure [set ::InSh::inputStream($name)] \
     -buffering none -translation [set ::InSh::lineEndings] -blocking 0
    return [set ::InSh::inputStream($name)]
  } else {
    unset -nocomplain ::InSh::inputStream($name)
    return ""
  }
}

# Process output of the program. "name" is the name of the window,
# and "channel" is the socket from which to read.
proc InSh::processOutput {name channel} {
  global ::InSh::lastPosition
  global ::InSh::ignorePats
  global ::InSh::processID
  
  set failure [catch { set data [read $channel] }]
  if { $failure || [eof $channel] } {
    # If the read failed or the socket is at EOF, close the socket
    InSh::cleanup $name
  } elseif { [lsearch -exact [winNames] $name] >= 0 } {
    # If the window exists...
    if { [info exists ::InSh::ignorePats($name)] } {
      # If there is text to ignore, remove it from the data
      foreach patt [set ::InSh::ignorePats($name)] {
        regsub -all -- $patt $data "" data
      }
    }
    # Append the data to the end of the window
    endOfBuffer -w $name
    insertText -w $name $data
    # and update the position after the last character written
    set ::InSh::lastPosition($name) [getPos -w $name]
  }
}

# When <RETURN> or <ENTER> is pressed, send the input to the program
proc InSh::carriageReturn {} {
  global ::InSh::inputStream
  global ::InSh::lastPosition
  global ::InSh::currHist
  global ::InSh::histList
  
  set theWin [win::Current]
  if { [info exists ::InSh::inputStream($theWin)] } {
    # Check for a live process
    if {![catch {exec ps -p [set InSh::processID($theWin)]} pinfo]} {
      if { ![regexp [set InSh::processID($theWin)] $pinfo] } {
        InSh::cleanup $theWin
      }
    }
    
    # Get the input socket for this window
    set channel [set ::InSh::inputStream($theWin)]
    # The data to send starts after the last data written to
    # this window and stops at the en of the current line.
    set start [set ::InSh::lastPosition($theWin)]
    set end [pos::lineEnd -w $theWin [getPos -w $theWin]]
    # If some text has been deleted, "start" may be greater than "end". In
    # this case, we send an empty string.
    if {[pos::compare -w $theWin $start < $end]} {
      set toSend [getText -w $theWin $start $end]
    } else {
      set toSend ""
    }
    if { [file channels $channel] != "" } {
      # If the socket is still open, send the data to the program, and 
      # write a carriage return to the window.
      if {[catch {puts $channel $toSend}]} {
        # Broken pipe ?
        InSh::cleanup $theWin
        beep
      } else {
        goto -w $theWin $end
        insertText -w $theWin "\r"
        # Update the history
        if {[info exists InSh::histList($theWin)]} {
          set InSh::histList($theWin) \
           [linsert [set InSh::histList($theWin)] 0 $toSend]
        } else {
          set InSh::histList($theWin) [list $toSend]
        }
        # Current entry used in history = none
        set InSh::currHist($theWin) -1
      }
    } else {
      # If the socket is closed, just beep.
      beep
    }
    # Update the position after the last char written to this window
    # (useful if there is no answer on stdout/stderr before we hit
    # <RETURN> again.)
    endOfBuffer -w $theWin
    set ::InSh::lastPosition($theWin) [getPos -w $theWin]
  } else {
    beep
  }
}

# Send a tab to the program (indenting does not make sense here).
# This is an attempt to send a tab to a shell for file name completion.
# However, this does no work since our shell window is not a terminal.
proc InSh::sendTab {} {
  global ::InSh::inputStream
  global ::InSh::lastPosition
  
  set theWin [win::Current]
  if { [info exists ::InSh::inputStream($theWin)] } {
    set channel [set ::InSh::inputStream($theWin)]
    if { [file channels $channel] != "" } {
      insertText -w $theWin "\t"
      puts -nonewline $channel "\t"
    } else {
      beep
    }
  } else {
    bind::IndentOrNextstop
  }
}

# When the process which runs in the window terminates, execute
# the cleanup code given by the creator of the process.
proc InSh::cleanup {name} {
  global ::InSh::closeCode
  global ::InSh::lastPosition
  global ::InSh::alreadyCleaned
  
  if {![info exists ::InSh::alreadyCleaned($name)]} {
    if {[info exists ::InSh::closeCode($name)]} {
      eval [set ::InSh::closeCode($name)]
    }
    if { [lsearch -exact [winNames] $name] >= 0 } {
      endOfBuffer -w $name
      insertText -w $name "\r                           ****    done    ****\r"
      set ::InSh::lastPosition($name) [getPos -w $name]
    }
    set ::InSh::alreadyCleaned($name) 1
  }
}

# When closing the window, free all related resources
proc InSh::killWindow {name} {
  global ::InSh::inputStream
  global ::InSh::outputStream
  global ::InSh::lastPosition
  global ::InSh::ignorePats
  global ::InSh::processID
  global ::InSh::currHist
  global ::InSh::histList
  global ::InSh::closeHooks
  global ::InSh::alreadyCleaned

  ::InSh::cleanup $name
  unset -nocomplain ::InSh::inputStream($name)
  unset -nocomplain ::InSh::outputStream($name)
  unset -nocomplain ::InSh::lastPosition($name)
  unset -nocomplain ::InSh::ignorePats($name)
  unset -nocomplain ::InSh::processID($name)
  unset -nocomplain ::InSh::currHist($name)
  unset -nocomplain ::InSh::histList($name)
  unset -nocomplain ::InSh::closeHooks($name)
  unset -nocomplain ::InSh::alreadyCleaned($name)
}

proc InSh::addCloseHook {name hook} {
  global ::InSh::closeHooks

  if {  ![info exists ::InSh::closeHooks($name)]
      || [lsearch -exact $hook [set ::InSh::closeHooks($name)]] == -1 } {
    lappend ::InSh::closeHooks($name) $hook
  }
}

proc InSh::removeCloseHook {name hook} {
  global ::InSh::closeHooks
  
  if {$hook == ""} {
    set ::InSh::closeHooks($name) [list]
  } elseif {[info exists ::InSh::closeHooks($name)]} {
    set idx [lsearch -exact "$hook" [set ::InSh::closeHooks($name)]]
    if {$idx != -1} {
      set ::InSh::closeHooks($name) [\
       lreplace ::InSh::closeHooks($name) $idx $idx\
      ]
   }
  }
}

# Move the cursor to the left if it is after the prompt
proc InSh::checkLeftMove {} {
  global ::InSh::lastPosition
  
  set theWin [win::Current]
  if { [info exists ::InSh::lastPosition($theWin)] } {
    if {[pos::compare -w $theWin [getPos -w $theWin] > [set ::InSh::lastPosition($theWin)]]} {
      backwardChar -w $theWin
    }
  } else {
    backwardChar -w $theWin
  }
}

# Delete the character to the left of the cursor if it after the prompt
proc InSh::checkLeftDel {} {
  global ::InSh::lastPosition
  
  set theWin [win::Current]
  if { [info exists ::InSh::lastPosition($theWin)] } {
    if {[pos::compare -w $theWin [getPos -w $theWin] > [set ::InSh::lastPosition($theWin)]]} {
      backSpace
    }
  } else {
    backSpace
  }
}

# Kill the current line (erase any text after the prompt)
proc InSh::killLine {} {
  global ::InSh::lastPosition

  set theWin [win::Current]
  if { [info exists ::InSh::lastPosition($theWin)] } {
    deleteText -w $theWin [set ::InSh::lastPosition($theWin)] \
     [pos::lineEnd [getPos -w $theWin]]
  }
  endOfBuffer -w $theWin
}

# Erase the contents of the window, preserving the last line of output
proc ::InSh::clearWindow {} {
  global InSh::lastPosition
  
  set theWin [win::Current]
  set lastPos [set InSh::lastPosition($theWin)]
  set lastLineStart [pos::lineStart $lastPos]
  set lastLine [getText -w $theWin $lastLineStart $lastPos]
  deleteText -w $theWin [minPos] [maxPos]
  insertText -w $theWin $lastLine
  set InSh::lastPosition($theWin) [getPos -w $theWin]
}

# Set the current line to the next (more recent) history entry
proc InSh::nextHist {} {
  global InSh::currHist
  global InSh::histList
  
  set theWin [win::Current]
  if {[info exists InSh::currHist($theWin)] \
   && [info exists InSh::histList($theWin)]} {
    set curr [set InSh::currHist($theWin)]
    if {$curr > 0} {
      set curr [expr $curr - 1]
      set InSh::currHist($theWin) $curr
      set hist [set InSh::histList($theWin)]
      if {$curr < [llength $hist]} {
        set cmd [lindex $hist $curr]
        InSh::killLine
        insertText -w $theWin $cmd
      }
    } elseif {$curr == 0} {
      # Next to the last entry is the empty line
      set InSh::currHist($theWin) -1
      InSh::killLine
    } else {
      # No more history entries
      beep
    }
  } else {
    # No history
    beep
  }
}

# Set the current line to the previous (older) history entry
proc InSh::prevHist {} {
  global InSh::currHist
  global InSh::histList
  
  set theWin [win::Current]
  if {[info exists InSh::currHist($theWin)] \
   && [info exists InSh::histList($theWin)]} {
    set curr [set InSh::currHist($theWin)]
    set hist [set InSh::histList($theWin)]
    set curr [expr $curr + 1]
    if {$curr < [llength $hist]} {
      set InSh::currHist($theWin) $curr
      set cmd [lindex $hist $curr]
      InSh::killLine
      insertText -w $theWin $cmd
    } else {
      # No older history entry
      beep
    }
  } else {
    # No history
    beep
  }
}

## 
##
## End of file `inshMode.tcl'.

