## -*-Tcl-*-
 # ###################################################################
 # 
 #  FILE: "alphaServer.tcl"
 #                                    created: 2003-09-10 10:53:06 
 #                                last update: 2006-02-17 23:13:03 
 #  Author: FrŽdŽric Boulanger
 #  E-mail: Frederic.Boulanger@supelec.fr
 #    mail: SupŽlec - Service Informatique
 #          3 rue Joliot-Curie, F-91192 Gif-sur-Yvette cedex
 #     www: http://wwwsi.supelec.fr/fb/
 #  
 #  Description:
 #  
 #  This package makes Alpha listen to a socket for Tcl commands to execute.
 #  See the "help" argument below for more information.
 # 
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2003-09-10 FBO 1.0 original
 #  2003-09-15 FBO 1.1 fix for port file location on Windows
 #  2003-10-16 cbu 1.2 added "Utils > Alpha Server" submenu
 #  2003-10-17 FBO 1.3 added activity logging.
 #  2003-10-21 FBO 1.4 uses safe interpreter (thanks to Vince)
 #  2003-11-17 FBO 2.0 changed protocol: clients can wait for window closing
 #  2003-12-02 FBO 2.1 better behavior when server is off, bug fixes.
 #  2005-10-20 JK  3.0 - Changed protocol: if the client wishes to wait until 
 #                     spawned windows close, the script sent to Alpha Server 
 #                     must start with the token "-wait".
 #                     - The prefs are gone.  
 #                     - The safe interpreter now only accepts three commands:
 #                         file::editAnyNumberOfFiles
 #                         newWindow
 #                         file::openWithSelection
 #                     corresponding to the three types of commands sent by
 #                     alphac.  This is cleaner than the old model where alphac
 #                     would send long scripts instead of single commands.
 #                     - The two-way arrays associating channels and windows
 #                     are gone, and so are the general close and changedname 
 #                     hooks.  Instead each window takes care of itself via 
 #                     win attributes and a special purpose hook mode.
 #                     - More care is taken to close channels after use.
 #                     - Error messages are sent back to the client if waiting.
 #                     
 

 # ###################################################################
 ##

alpha::feature alphaServer 3.0 global-only {
    # Initialization script.
} {
    # Activation script.
    ::alphaServer::start
} {
    # Deactivation script.
    ::alphaServer::stop
} uninstall {
    this-file
} description {
    This package makes Alpha act as a server that executes Tcl commands
} help {
    This always-on AlphaTcl package sets up a server socket to listen to 
    requests for the execution of Tcl commands.  The main client is the
    alphac script which allows Alpha to serve as EDITOR or TEXEDIT to
    open a file at a given line.  Setting TEXEDIT to
      
      $HOME/Tools/alphac +%d %s
      
    will make the teTeX versions of tex (and pdftex) use Alpha when "e" is
    typed at an error prompt. "$HOME" is the folder containing the Alpha(tk)
    binary, as in <<alertnote $HOME>>.  Click here <<putScrap $HOME>> to place
    this value in the OS Clipboard.
    
    alphac may also be used as the system editor by setting EDITOR to
    
      $HOME/Tools/alphac -wait
    
    The '-wait' option will make alphac wait until you close the window of 
    the edited file, letting the system know that you have finished.

    Technical information:
    
    For security reasons, the commands sent to the Alpha server are executed
    by a safe Tcl interpreter.  This interpreter is restricted and can only
    execute the following three commands:
	
	file::editAnyNumberOfFiles   ::newWindow   file::openWithSelection
    
    corresponding to the type of commands that can come from the alphac
    script.
      
    You can tweak the Alpha server to accept other commands if needed to
    set up more complex inter-application communications.  All you have to
    do is to redefine the list variable alphaServer::authorizedCommands,
    lappending the needed commands.  You can place such a redefinition in
    your prefs.tcl file after a [alphaServer.tcl] statement (which forces
    the original definition to come first; your redefinition overrides).
    However, you should be aware of the security risk implied by allowing
    arbitrary commands: someone on another computer may use the server to
    have Alpha execute malicious Tcl commands.  The server is meant only to
    accept connections only from the local host, but the check is a bit
    heuristic and a hacker might be able to fool this check.  Therefore, it
    is recommend to use an IP firewall to block remote connections to
    unauthorized ports.  For Mac OS X users, this amounts to:
    
      (1) Do not enable remote Apple Events
      (2) Activate the firewall in the Sharing panel of System preferences

    
    To request the execution of a Tcl command by Alpha, simply connect to
    the socket on which the server listens and write the command followed
    by a control character (for instance ^D).  Control characters are not
    allowed in the command and are interpreted by the server as the
    end-of-command marker.  In order to wait for the editing to finish
    (wait for the window to be closed) preceed the command by the token
    "-wait".  Then alphaServer won't close the connection after receiving
    the command but will use it to send back the name of the edited file
    when it is closed.  If several windows are open, alphaServer will wait
    until the last one is closed and send the filename of this last window
    through the connection.
  
    The number of the port on which the server socket listens is put in the
    environment variable:
  
      ALPHASERVERPORT
  
    so it is accessible to any sub-process of Alpha.
  
    Other processes may read the port number of the server from a file named:
    
      - on Unix systems
    
	  /tmp/$USER-AlphaServerPort
    
	where $USER is the login name of the user who has launched Alpha.
      
      - on Windows
      
	  $USERNAME-AlphaServerPort 
      
	in the first directory found among:
      
	  (1) $TEMP
	  (2) $TMP
	  (3) $USERPROFILE\Temp
      
} maintainer {
    "Fr\u00e9d\u00e9ric Boulanger"
    <Frederic.Boulanger@supelec.fr>
    <http://wwwsi.supelec.fr/fb/>
} requirements {
    if {$tcl_platform(platform) eq "macintosh"} {
	error "No support for Alpha server in Mac OS Classic"
    }
}

proc alphaServer.tcl {} {}
namespace eval ::alphaServer {}

# The Alpha server has three "hidden" preferences which can easily be changed
# by anyone developing new ways to use the Alpha server.  (Such a developer is
# encouraged to join the alphatcl-developers mailing list, of course, and to
# discuss the needs.  If needs arise, we can expand the capabilities of the
# Alpha server.)
# 
# 
# List of commands whose execution is allowed by the safe interpreter in
# the Alpha server:
set ::alphaServer::authorizedCommands [list \
  file::editAnyNumberOfFiles \
  newWindow \
  file::openWithSelection \
  ]
# These three commands correpond precisely to the type of commands that can
# come from the alphac script, which is currently the only known "client".

# To start logging the activity of the server to the alphaServer.log file
# in Alpha's preferences folder, turn the following flag on:
set ::alphaServer::logServerActivity 0

# To start debugging the activity of the server to the alphaServer.log file
# in Alpha's preferences folder, turn the following flag on:
set ::alphaServer::debugServerActivity 0



# Return the name of the file which contains the port number on which
# the server listens to commands.
# The location of this file is platform dependent.
proc ::alphaServer::serverPortFileName {} {
    # Find a place for the file which contains the port number of 
    # the server so that other processes can know it.
    switch -- $::tcl_platform(platform) {
	"macintosh" {
	    status::msg "No support for Alpha server in Mac OS Classic"
	    return ""
	}
	"unix" {
	    set tmpdir "/tmp"
	    set usern $::env(USER)
	}
	"windows" {
	    if {[info exists ::env(TEMP)] && [file isdirectory $::env(TEMP)]} {
		set tmpdir $::env(TEMP)
	    } elseif {[info exists ::env(TMP)] && [file isdirectory $::env(TMP)]} {
		set tmpdir $::env(TMP)
	    } elseif {[info exists ::env(USERPROFILE)] \
	      && [file isdirectory [file join $::env(USERPROFILE) Temp]]} {
		set tmpdir [file join $::env(USERPROFILE) Temp]
	    } else {
		status::msg "Can't find a temp directory"
		return ""
	    }
	    if {[info exists ::env(USERNAME)]} {
		set usern $::env(USERNAME)
	    } elseif {[info exists ::tcl_platform(user)]} {
		set usern $::tcl_platform(user)
	    } else {
		set usern ""
	    }
	}
	"default" {
	    status::msg "Unsupported plaform $::tcl_platform(platform)"
	    return ""
	}
    }
    set sfile [file join $tmpdir ${usern}-AlphaServerPort]
    return $sfile
}

# Start the Alpha server
proc ::alphaServer::start {} {
    # The server socket
    global ::alphaServer::serverSocket
    # The port on which this socket listens
    global ::alphaServer::serverPort
    # The address of the host computer
    global ::alphaServer::serverAddress
    # Are we in the initialization phase?
    global ::alphaServer::initPhase
    
    global ::env
    global ::HOME
    
    if { ![::alphaServer::isRunning] } {
	# Using 0 as port number makes socket choose an unused port
	set ::alphaServer::serverSocket [\
	  socket -server ::alphaServer::handleConnect -myaddr 127.0.0.1  0]
	# Then, we get info about the socket with fconfigure
	set sockInfo [fconfigure $::alphaServer::serverSocket -sockname]
	set ::alphaServer::serverPort [lindex $sockInfo 2]
	set ::alphaServer::serverAddress [lindex $sockInfo 0]
	# The server address from fconfigure is not accurate (at least in 
	# Mac OS X) so we will get our address by opening a connection to 
	# ourself. This is the initialization phase
	set ::alphaServer::initPhase 1
	set sock [socket localhost $::alphaServer::serverPort]
	close $sock
	# Wait until the server has updated serverAddress
	vwait ::alphaServer::serverAddress
	hook::register quitHook ::alphaServer::stop
	::alphaServer::log \
	  "server started on $::alphaServer::serverAddress \
	  port $::alphaServer::serverPort"
    }
    # Make the server port number available to sub-processes
    set ::env(ALPHASERVERPORT) $::alphaServer::serverPort
    
    set alphaServerFile [::alphaServer::serverPortFileName]
    if {$alphaServerFile != ""} {
	set f [open $alphaServerFile w]
	puts $f $::env(ALPHASERVERPORT)
	close $f
	::alphaServer::log "server port number written to $alphaServerFile"
    }
  
    if {$::tcl_platform(platform) eq "unix"} {
	# Ensure "alphac" is executable
	set ALPHAC [file join $HOME Tools alphac]
	if {![file executable $ALPHAC]} {
	    if {[file readable $ALPHAC]} {
		catch {file attributes $ALPHAC -permissions +x}
	    }
	}
	# If nothing has been chosen yet as the TeX editor set
	# alphac to be the TeX editor.
	if {![info exists ::env(TEXEDIT)]} {
	    set ::env(TEXEDIT) "$ALPHAC +%d %s"
	}
    }
}

# Stop the Alpha server
proc ::alphaServer::stop {} {
    global ::alphaServer::serverSocket
    global ::alphaServer::serverPort
    global ::env
    
    set alphaServerFile [::alphaServer::serverPortFileName]
    
    if { [file exists $alphaServerFile] } {
	file delete $alphaServerFile
	::alphaServer::log "deleted $alphaServerFile"
    }
    
    unset -nocomplain ::env(ALPHASERVERPORT)
    
    hook::deregister quitHook ::alphaServer::stop
    
    if { [::alphaServer::isRunning] } {
	close $::alphaServer::serverSocket
	::alphaServer::log "closed server socket $::alphaServer::serverSocket"
    }
    status::msg "The Alpha Tcl Server is now stopped."
}

# Tell if the Alpha server is running
proc ::alphaServer::isRunning {} {
    variable serverSocket
    if { ![info exists serverSocket] } {
	return 0
    }
    return [expr {[lcontain [file channels $serverSocket] $serverSocket]}]
}

# Handle a connection to the server.
# channel is the new socket created for this connection
# clientadr is the address of the client host
# clientprt is the port number of the client
proc ::alphaServer::handleConnect {channel clientadr clientprt} {
    global ::alphaServer::serverAddress
    global ::alphaServer::initPhase
    # We have a distinct global variable for each connection. This
    # allows to have several simultaneous connections without problem.
    global ::alphaServer::command-$channel
    
    # If we are in the init phase, this connection is from
    # ourself. The client address is the server address
    if { $::alphaServer::initPhase } {
	set ::alphaServer::initPhase 0
	set ::alphaServer::serverAddress $clientadr
	::alphaServer::log "handled initial connection from $clientadr:$clientprt"
	return
    }
    
    # If the request does not come from the local computer, abort.
    # Having Alpha executing any command from a remote host is not
    # exactly what we want...
    # Anyway, using an IP firewall like ipfw is recommended.
    if { $clientadr != $::alphaServer::serverAddress } {
	close $channel
	::alphaServer::log \
	  "* WARNING * refused connection from $clientadr:$clientprt"
	alertnote "Attempt to connect to the Alpha server from $clientadr:$clientprt"
	return
    }
    
    # We have a real connection. Set up the channel for non-blocking reads
    # so we can do other things in Alpha while the data arrives
    fconfigure $channel -buffering none -translation auto -blocking 0
    # Since we may have several simultaneous connections, we must use
    # different variables to store the different requests. We use the
    # channel to differenciate the variables.
    set ::alphaServer::command-$channel ""
    ::alphaServer::log "accepting connection from $clientadr:$clientprt on $channel"
    fileevent $channel readable [list \
      ::alphaServer::readCommand $channel $clientadr $clientprt]
}


hook::register preCloseHook ::alphaServer::closingWindow waitingclient
proc ::alphaServer::closingWindow { name } {
    set channel [win::getInfo $name waitingclientchannel]
    if { [llength [allWinsOfThisChannel $channel]] == 1 } {
	# This means this window is the only one awaited by the client.
	# So send back the file name:
	catch { puts $channel [win::StripCount $name] }
	# and close the connection:
	catch { close $channel }
	::alphaServer::log "closing transaction on channel $channel"
	return
    }
}


proc alphaServer::allWinsOfThisChannel { channel } {
    set res [list]
    foreach w [winNames -f] {
	if { [win::infoExists $w waitingclientchannel] &&
	  [lcontain [win::getInfo $w waitingclientchannel] $channel] } {
	    lappend res $w
	}
    }
    return $res
}


# Read a Tcl command from an accepted connection to the server.
proc ::alphaServer::readCommand {channel clientadr clientprt} {
    # We have a global variable for each channel to support
    # multiple simultaneous connections
    global ::alphaServer::command-$channel
    # The three "hidden prefs":
    global ::alphaServer::authorizedCommands
    global ::alphaServer::logServerActivity
    global ::alphaServer::debugServerActivity
    
    if { [eof $channel] } {
	fileevent $channel readable {}
	return
    }
    
    set endOfCommand 0
    
    # Read as many characters as available on the channel:
    set newStuff [read -nonewline $channel]
    for {set i 0} {$i < [string length $newStuff]} {incr i} {
	# If what we read contains control characters, ignore
	# everything from the first one and stop reading.
	# This allows to use telnet to connect to the server and 
	# terminate the command with ^D (or any other control char).
	if {[string is control [string index $newStuff $i]]} {
	    set newStuff [string range $newStuff 0 [expr {$i - 1}]]
	    set endOfCommand 1
	    break
	}
    }
    # Append what has been read to the command
    append ::alphaServer::command-$channel $newStuff
    
    # If the channel is still alive and we didn't read a control char,
    # just return to be called again when there will be something new to read.
    if { ([file channels $channel] ne "") && (![eof $channel]) && (!$endOfCommand)} {
	return
    }
    
    # We have read everything we want from this connection
    fileevent $channel readable {}
    
    ::alphaServer::debug "finished reading command"
    
    if { [set ::alphaServer::command-$channel] eq "" } {
	# No commands, just close the channel
	close $channel
	::alphaServer::log "No commands received -- closing $channel."
	return
    } 
    
    ::alphaServer::log "evaluating command from $clientadr:$clientprt\n\
      [set ::alphaServer::command-$channel]"
    # If the command is not empty, try to evaluate it in a safe
    # interpreter.  A new interpreter is created for each connection 
    # to the server so that the state of the interpreter cannot be
    # used to get information on other clients.  For the same reason,
    # we have an interpreter for each channel so that several 
    # requests can be served simultaneously without problem.
    # First delete any old debris there might exist with this name.
    # (These can sometimes survive if an error occurs before they are
    # properly deleted.)
    catch {interp delete servInterp-$channel}
    interp create -safe servInterp-$channel
    
    # The command was sent over the channel as a string but it is
    # indeed a list (that was how the client constructed it).
    # 
    # If the first element in the list is the string "-wait" then we must
    # keep track of windows and channels, keep the channel open until last
    # associated window is closed, then report back to the client, and
    # finally close the channel.  Doing this requires special variants of
    # the authorized commands.
    if { [lindex [set ::alphaServer::command-$channel] 0] == "-wait" } {
	set wait 1
	lvarpop ::alphaServer::command-$channel
    } else {
	set wait 0
    }
    
    # Now set up the safe interpreter.  The way to do this depends on 
    # whether the client is waiting or not.
    if { !$wait } {
	# This is the easy case.  We can alreay close the channel at
	# this point.
	close $channel
	::alphaServer::log "closing $channel."
	foreach cmd $::alphaServer::authorizedCommands {
	    if {$::alphaServer::debugServerActivity} {
		# We are debugging commands sent to the server
		interp alias servInterp-$channel $cmd {} alphaServer::debugCmd $cmd
	    } else {
		# We are not debugging commands sent to the server
		interp alias servInterp-$channel $cmd {} $cmd
	    }
	}
	
    } else {
	# We have to go through that trouble with channels...
	
	# Add the authorized command.  Commands that open or edit windows
	# must be redefined to take an extra channel argument.  These 
	# commands are:
	set waitCommands [list edit new \
	  file::openWithSelection file::editAnyNumberOfFiles newWindow]

	if {$::alphaServer::debugServerActivity} {
	    # We are debugging commands sent to the server
	    foreach cmd $::alphaServer::authorizedCommands {
		if { [lcontain $waitCommands $cmd] } {
		    interp alias servInterp-$channel $cmd {} \
		      alphaServer::debugCmd alphaServer::$cmd $channel
		} else {
		    interp alias servInterp-$channel $cmd {} alphaServer::debugCmd $cmd
		}
	    }
	} else {
	    # We are not debugging commands sent to the server
	    foreach cmd $::alphaServer::authorizedCommands {
		if { [lcontain $waitCommands $cmd] } {
		    interp alias servInterp-$channel $cmd {} \
		      alphaServer::$cmd $channel
		} else {
		    interp alias servInterp-$channel $cmd {} $cmd
		}
	    }
	}
    }
    
    # At this point we have the safe interpreter, and we are ready to have
    # it evaluate the command.
    if { [catch { \
      servInterp-$channel eval [set ::alphaServer::command-$channel] } err] } {
	# Transmit the error to the client, if it is waiting:
	if { $wait } {
	    puts $channel "$::ALPHA got an error: $err"
	    close $channel
	}
	# Give and error message in Alpha to let the user know that the
	# failure comes from a command sent to the server.
	set msg "Error while executing a command from "
	append msg "$clientadr:$clientprt\nCommand: "
	append msg [set ::alphaServer::command-$channel]
	append msg "\nError: $err"
	::alphaServer::log $msg
	error $msg
    }
    # Delete the interpreter as soon as it is no longer needed
    interp delete servInterp-$channel
    # Clean up this global variable:
    unset ::alphaServer::command-$channel
}

# Log a message to the alpha server log.
proc ::alphaServer::log {msg} {
    variable logServerActivity
    variable debugServerActivity
    if {$logServerActivity || $debugServerActivity} {
	global PREFS
	# logging should never fail
	catch {
	    set logFile [file join $::PREFS alphaServer.log]
	    set log [open $logFile "a+"]
	    puts $log "[mtime now relaxed] $msg"
	    close $log
	}
    } 
}

# Log a debug message to the alpha server log.
proc ::alphaServer::debug {msg} {
    variable debugServerActivity
    if {$debugServerActivity} {
	global PREFS
	# logging should never fail
	catch {
	    set logFile [file join $PREFS alphaServer.log]
	    set log [open $logFile "a+"]
	    puts $log "[mtime now relaxed] # D # $msg"
	    close $log
	}
    } 
}

proc ::alphaServer::debugCmd {cmd args} {
    ::alphaServer::debug "$cmd $args"
    set status [catch {eval $cmd $args} result]
    ::alphaServer::debug " ($status) -> $result"
    if {$status != 0} {
	error $result
    }
    return $result
}




# Define the three commands allowed by default (and their wait variant)
# ---------------------------------------------------------------------

# The three commands allowed by default are
#    file::openWithSelection
#    file::editAnyNumberOfFiles
#    newWindow
# 
# First we define the plain official version of these procs (if not defined
# elsewhere).  Afterwards we define a variant with an extra $channel
# argument, needed in the case of a -wait command from alphac.


# This proc should probably be moved to fileManipulation.tcl
# 
# Edit any number of files:
proc file::editAnyNumberOfFiles { args } {
    foreach fileName $args {
	#### Plugin for redirecting temporary files ####
	if {![catch {temp::attributesForFile $fileName} tinfo]} {
	    set fileName [lindex $tinfo 0]
	}
	#### End of tmp files plugin ####

	# If $fileName is an open window (not necessarily a file on disk,
	# or otherwise a file on disk but given just by its tail name), then
	# use that window:
	if { [win::Exists $fileName] || [lcontain [winNames] $fileName] } {
	    set w $fileName
	} else {
	    # Otherwise open the file:
	    set fileName [file normalize $fileName]
	    if {![file readable $fileName]} {
		error "File \"$fileName\" is not readable"
	    }
	    set w [edit -c $fileName]
	}
    }
    switchTo $::ALPHA
    if { [info exists w] } {
	bringToFront $w
	refresh -w $w
    }
}

# Create a new window $winName, possibly with some initial content $winContents:
proc ::newWindow { winName {winContents ""} } {
    set w [::new -n $winName]
    insertText -w $w $winContents
    switchTo $::ALPHA
    bringToFront $w
    refresh -w $w
}


## Special versions of edit and new to keep a trace of new windows.
## These are not really needed directly in the default setup, but they are
## used in the definition of the special versions of the three default 
## commands, and in any case they might be useful for other clients than
## alphac (as they were useful in the 3.0 version).
proc ::alphaServer::new {channel args} {
    set win [eval ::new $args]
    win::adjustInfo $win hookmodes {lunion hookmodes waitingclient}
    win::setInfo $win waitingclientchannel $channel
    return $win
}
proc ::alphaServer::edit {channel args} {
    set win [eval ::edit $args]
    win::adjustInfo $win hookmodes {lunion hookmodes waitingclient}
    win::setInfo $win waitingclientchannel $channel
    return $win
}


# Define the special version of the three commands allowed by default
# -------------------------------------------------------------------

namespace eval ::alphaServer::file {}

proc alphaServer::file::openWithSelection { channel fileName row0 col0 row1 col1 } {
    set win [eval ::file::openWithSelection $fileName $row0 $col0 $row1 $col1]
    win::adjustInfo $win hookmodes {lunion hookmodes waitingclient}
    win::setInfo $win waitingclientchannel $channel
    return $win
}

# Open any number of files:
# 
# In the waiting case we don't allow redirection from temp files to 
# originals...
proc alphaServer::file::editAnyNumberOfFiles { channel args } {
    foreach fileName $args {
	set w [::alphaServer::edit $channel -c $fileName]
    }
    switchTo $::ALPHA
    if { [info exists w] } {
	bringToFront $w
	refresh -w $w
    }
}

# Create a new window $winName, possibly with some initial content $winContents:
proc alphaServer::newWindow { channel winName {winContents ""} } {
    set w [::alphaServer::new $channel -n $winName]
    insertText -w $w $winContents
    switchTo $::ALPHA
    bringToFront $w
    refresh -w $w
}


# end of alphaServer.tcl
