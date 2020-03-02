## -*-Tcl-*- (nowrap)
 # ###################################################################
 #  AlphaTcl 
 # 
 #                                        created: 11/07/2003 18:23:45
 #                                    last update: 03/21/2006 {03:02:48 PM} 
 # 
 # File: "coqMode.tcl"
 # Author: Joachim Kock <kock@mat.uab.es>
 # Description: Rudimentary Coq mode 
 # featuring a coq console (interaction with coqtop).
 # 
 # Coq is is a proof assistant for computer assisted verification of
 # mathematical proofs.  The home page is http://coq.inria.fr .  Proofs are
 # written in the special-purpose lambda-calculus-like language 'gallina'.
 # coqtop is the top level command interpreter for coq.
 # 
 ##



######## Define coq mode ########

# Mode declaration 
# (note that the .v extension is currently also claimed by verilog mode...)
alpha::mode coq 0.1 source {*.v *.v8} coqMenu {
    # Script to execute at Alpha startup
    addMenu coqMenu "Coq"
} uninstall {
    this-file
} maintainer {
    "Joachim Kock" <kock@mat.uab.es>
} description {
    Coq is is a proof assistant for computer assisted verification of
    mathematical proofs.  Proofs are written in the special-purpose
    lambda-calculus-like language 'gallina'.
} help {
    For information about Coq, see <http://coq.inria.fr>
}

proc coqMode.tcl {} {}

# Is this really needed?  AlphaTcl tries to load Tclx early on anyway,
# so if we have it, it is already loaded, and if we don't, this is
# unlikely to succeed.  (See also bug# 1868.)
# catch {package require Tclx}

# Initialise namespace:
namespace eval coq {}
set coqMenu Coq

# This proc is called every time we turn the menu on.
# Its main effect is to ensure this code, including the
# menu definition below, has been loaded.
proc coqMenu {} {}
# Now we define the menu items.
Menu -n $coqMenu -p coq::menuProc {
    openCoqConsole
    sendSelection
}

# This procedure is called whenever we select a menu item
proc coq::menuProc {menu item} {
    switch -- $item {
	openCoqConsole {coq::start}
	sendSelection {coq::send}
    }
}

# newPref flag wordWrap 0 coq
# newPref var coqVersion 8 coq

# Register multiline comments
set coq::commentCharacters(Paragraph) {{(* } { *)} { * }}

# Reserved identifiers for the core syntax
# as, cofix, else, end, fix, for, forall, fun, if , in, let, match, 
# Prop, return, Set, then, Type, with 

# Tactics

# Keywords. (These are taken from coq.el. Note that emacs keyword colouring
# is much fancier and allows regexps and more elaborate grammar specifications.)
set coqKeyWords [list Check Auto Intros Quit Apply Symmetry \
  Transitivity Reflexivity Rewrite Hints Resolve Repeat Trivial Split]

# Directives:
lappend coqKeyWords \
  AddPath DelPath Add ML Path Declare \
  Require Export Module Opaque Transparent Section Chapter End Load Print \
  Show Implicit Arguments On Off

# Grammar definitions:
lappend coqKeyWords \
  Syntax tactic command level Grammar Tactic Definition Token \
  Coercion Class Infix

# Declarations:
lappend coqKeyWords \
  Recursive Definition Syntactic Tactic Inductive Set Prop Type \
  Mutual Inductive CoInductive CoFixpoint Local Fixpoint with Record Correctness \
  Derive Dependant Derive Inversion Inversion_clear Variable Parameter \
  Hypothesis Global Variable Realizer Program

# Proofs:
lappend coqKeyWords \
  Lemma Theorem Remark Axiom Proof Save Qed Defined Hint Immediate \
  
# Keywords:
lappend coqKeyWords \
  Case Cases case esac of end in Match with Fix let if then else \
  begin assert invariant variant for while do done state

# if $coqModeVars(coqVersion) >= 8 
    lappend coqKeyWords \
      forall replace exact fun


# Colour the keywords, comments etc.
regModeKeywords -b {(*} {*)} coq $coqKeyWords
# Discard the list
unset coqKeyWords

# To write indentation code for your new mode (so your mode
# automatically takes advantage of the automatic indentation
# possibilities of 'tab', 'return' and 'paste'), you can take
# advantage of the shared proc ::indentLine.  All you need to write
# is a coq::correctIndentation proc, and as a
# starting point you can copy the code of the generic
# ::correctIndentation, found in indentation.tcl.

######## Set up the coqtop console functionality ########

hook::register closeHook coq::properClose "coq"

console::create "*Coq console*" -mode coq -fontsize 9 -g 529 59 503 705 

proc coq::properClose { win } {
    stop
}

# proc coq::start { } {
#     variable errorOut 
#     variable coqMain 
#     variable errorIn 
#     variable promptPos
#     
#     pipe errorOut errorIn
#     fconfigure $errorOut -buffering line -blocking 0
#     fconfigure $errorIn -buffering none -blocking 0
#     set coqMain [open "|coqtop 2>@ $errorIn" RDWR]
#     fconfigure $coqMain -buffering line -blocking 0
#     
#     # Create a console to write in:
#     new -g 529 59 503 705 -n "*Coq console*" -mode coq -fontsize 9 -shell 1
#     # and initialise the prompt position:
#     set promptPos [minPos -w "*Coq console*"]
#     # Set up a handler for the output:
#     fileevent $errorOut readable [list coq::receiveAndDisplayError $errorOut]
#     fileevent $coqMain readable [list coq::receiveAndDisplay $coqMain]
# }
# 
# # The error pipe is only for the prompt.  Even error messages from coqtop
# # are sent over stdout.

proc coq::start { } {
    if { [catch { package require Tclx }] } {
	alertnote  "The Tcl extension \"Tclx\" could not be loaded.\r\
	  Interaction with coqtop will not work."
	return
    }

    variable errorOut 
    variable coqMain 
    variable errorIn 
    variable promptPos
    
    pipe errorOut errorIn
    fconfigure $errorOut -buffering line -blocking 0
    fconfigure $errorIn -buffering none -blocking 0
    set coqMain [open "|coqtop 2>@ $errorIn" RDWR]
    fconfigure $coqMain -buffering line -blocking 0
    
    # Open the console:
    console::open "*Coq console*"
    console::strict::turnOn "*Coq console*" -readlineProc coq::sendthis
#     win::lappendInfo "*Coq console*" hookmodes coq
    
    # Set up a handler for the output:
    fileevent $errorOut readable [list coq::receiveAndDisplayError $errorOut]
    fileevent $coqMain readable [list coq::receiveAndDisplay $coqMain]
}

# The error pipe is only for the prompt.  Even error messages from coqtop
# are sent over stdout.


# Stopper:
proc coq::stop { } {
    # Close the pipes:
    variable errorOut
    variable coqMain
    variable errorIn
    catch {close $coqMain}
    catch {close $errorOut}
    catch {close $errorIn}
    # And close the console window:
#     killWindow -w "*Coq console*"
}

# Event handler for both coq::coqMain:
proc coq::receiveAndDisplay { pipe } {
    if { [eof $pipe] } {
	# There is nothing more to read --- just stop:
	variable done 1
	stop
	return
    }
    set res [read $pipe]
    # Insert the result in the window:
    console::strict::write "*Coq console*" "$res"

    variable error
    if { [regexp -- {(?:Syntax error|User error|Error):.*} $res error] } {
	variable exitcode 1
    } else {
	variable exitcode 0
    }
}

# Event handler for coq::errorOut:
proc coq::receiveAndDisplayError { pipe } {
    if { [eof $pipe] } {
	# There is nothing more to read --- just stop:
	variable done 1
	stop
	return
    }
    set res [read $pipe]
    # Insert the result in the window:
    console::strict::write "*Coq console*" "$res"
    variable done 1
}


proc coq::sendthis { win str prompt } {
    variable coqMain
    puts $coqMain $str
    # Timeout mechanisms: We are going to wait for the variable $done.  
    # Make sure it is written at least ofter some time:
    set timeout [after 10000 {set ::coq::done "TIMEOUT"}]
    vwait ::coq::done
    # If we have come so far there is no more need for the time bomb:
    after cancel $timeout
    variable done
    if { [string equal $done "TIMEOUT"] } {
	stop
	error "TIMEOUT"
    }
    
    
}


# This proc sends a command to the console, i.e. just writes it in the
# console window at [maxPos].  And then press the trigger for sending
# to the process (this is handled by console::strict::RETURN and 
# ultimately by coq::sendThis, since this proc was declared as readlineProc
# when setting up the strictness.
proc coq::send { } {
    variable coqMain
    if { [isSelection] } {
	set cmd [getSelect]
	set next [selEnd]
    } else {
	aimAt p0 p1
	set old $p0
	set cmd [getText $p0 $p1]
	set next $p1
    }
    if { [info exists cmd] } {
	set cmd [stripComments $cmd]
	set cmd [string trim $cmd]
	goto -w "*Coq console*" [maxPos -w "*Coq console*"]
	insertText -w "*Coq console*" "$cmd"
	console::strict::RETURN  "*Coq console*"
	
	variable exitcode 
	if { $exitcode } {
	    # There was an error
	    variable error
	    status::msg $error
	    # 	    alertnote ok
	} else {
	    if { [catch { nextRegion $next }] } {
		# This looks strange: why would we insert a \r here?:
		# somehow it is for the case of end-of-file, and perhaps
		# to avoid some infinite loop???
		alertnote WHY
		insertText {\r}
	    }
	}
    }
    return ""    
}


######## Set up the step functionality ########

proc coq::aimAt { pos0 pos1 } {
    upvar 1 $pos0 p0
    upvar 1 $pos1 p1
    if { [isSelection] } {
	set p0 [getPos]
	set p1 [selEnd]
	return
    }
    # The basic algorithm is to go back to last previous fullstop which
    # is not in a comment, and then start at the next nonwhite.
    set pos [getPos]
    set backSearchPos [pos::math $pos - 2]
    set foundAFullStop 0
    while { !$foundAFullStop } {
	if { [catch { search -f 0 -r 1 {\.\s+[^\s]} $backSearchPos } previous] } {
	    set p0 [minPos]
	    set foundAFullStop 1
	} else {
	    if { [text::isInComment [lindex $previous 0]] } {
		# We'll look further back:
		set backSearchPos [pos::math [lindex $previous 0] -1]
	    } else {
		set p0 [pos::math [lindex $previous 1] -1]
		set foundAFullStop 1
	    }
	}
    }
    
    set forthSearchPos [pos::math $pos - 1]
    set foundAFullStop 0
    set i 0
    while { !$foundAFullStop && $i < 12 } {
	incr i
	if { [catch { search -f 1 -r 1 {\.\n?} $forthSearchPos } next] } {
	    set p1 [maxPos]
	    set foundAFullStop 1
	} else {
	    if { [text::isInComment [lindex $next 0]] } {
		# We'll look further:
		set forthSearchPos [lindex $next 1]
	    } else {
		set p1 [lindex $next 1]
		set foundAFullStop 1
	    }
	}
    }
    # Now we have found a complete chunk of text between two noncommented
    # fullstops.  Now we just have to strip leading comment lines and empty
    # lines.
    while { 1 } {
	if { ![text::isInComment [pos::math $p0 + 1]] } {
	    break
	} else {
	    if { [catch { search -f 1 -r 0 -l $p1 -- "*)" [pos::math $p0 + 2] } next] } {
		# If for some reason we can't find the closing comment,
		# just use the original position we found --- at least it
		# will allow the programme to continue.
		break
	    }
	    set p0 [lindex $next 1]
	    # Now we found the end of the comment. Now look for the next
	    # nonwhite:
	    if { [catch { search -f 1 -r 1 -l $p1 -- {\S} $p0 } next] } {
		# If for some reason we can't find the closing comment,
		# just use the original position we found --- at least it
		# will allow the programme to continue.
		break
	    }
	    set p0 [lindex $next 0]
	}
    }
    # Finally, if the region between the p0 we found and its linestart is
    # white, then we'll rather select the whole line:
    set prefix [getText [pos::lineStart $p0] $p0]
    if { [string is space $prefix] } {
	set p0 [pos::lineStart $p0]
    }
    
    # No return value --- we have set p0 and p1 via upvar.
}

# Select the next input region.  If no next input 
# region is found an error is raised.
proc coq::nextRegion { {pos ""} } {
    if { ![string length $pos] } { 
	set pos [selEnd]
    }
    goto [pos::math $pos + 1]
    aimAt p0 p1
    selectText $p0 $p1
    # If we are too close to the bottom of the window...:
    getWinInfo -w [win::Current] a
    set bottomline [expr {$a(currline) + $a(linesdisp) - 1}]
    set thisline [lindex [pos::toRowChar -w [win::Current] [selEnd]] 0]
    if { [expr {$bottomline - $thisline}] < 4 } {
	centerRedraw
    }
}

# Handle the enter key in a source window.
# (The enter key in the console is handled by the general strictshell bindtag.)
proc coq::enter {} {
    if { ![isRunning] } {
	set win [win::Current]
	start
	bringToFront $win
	nextRegion
    } else {
	send
	variable exitcode 
	if { $exitcode } {
	    # There was an error
	    variable error
	    status::msg $error
	    beep
	}
    }
}

Bind 0x34 coq::enter "coq"

Bind 0x7d <oz> coq::nextRegion "coq"  ;# Opt-ctrl-Downarrow

proc coq::isRunning {} {
    # A better check should be performed...
    return [win::Exists "*Coq console*"]
}

# Auxiliary proc, to avoid sending comments to the console.
proc coq::stripComments { txt } {
    set noOpeningOrClosing {(?:[^\(\*]|[\(][^\*]|[\*][^\)])*}
    # This means: we don't accept ( or *
    # except ( followed by anything else than *
    # and except * followed by anything else than )
    append commentExpr {\(\*} ${noOpeningOrClosing} {\*+\)}
    # Note the plus: it is necessary to match a comment ending with **)
    set i 0
    while { [regsub -- $commentExpr $txt "" txt] } {
	incr i
    }
    set res ""
    foreach line [split $txt \r\n] {
	if { ![string is space $line] } {
	    append res $line \r
	    # Note that coqtop is happiest if it gets carriage returns.
	    # If it gets newlines, it will write a new prompt for each
	    # newline.
	}
    }
    return $res
}




################################################################################
################################################################################
# The rest does not really belong to this file.  It is from the 
# strictConsole package defining a mechanism preventing you from typing 
# anything before the prompt in a shell-like window.


# File: strictConsole.tcl
# 
# 
# 
namespace eval console {}
namespace eval console::strict {}


proc console::strict::write { win args } {
    goto -w $win [maxPos -w $win]
    eval insertText -w {$win} $args
    win::setInfo $win promptPos [getPos -w $win]
}


Bind 0x33     console::strict::backspace   strictshell
Bind 0x33 <s> console::strict::backspace   strictshell


proc console::strict::turnOn { name args } {
    variable gArray
    while { [set key [lvarpop args]] != "" } {
	switch -- $key {
	    "-readlineProc" {
		win::setInfo $name readlineProc [lvarpop args]
	    }
	    default {
		error "Bad arguments"
	    }
	}
    }
    regsub -all {[^a-zA-Z]} $name "" h
    variable $h
    win::setInfo $name histlistVar $h
    histlist create $h 30

    win::setInfo $name promptPos [maxPos -w $name]
    
#     win::lprependInfo $name hookmodes strictshell
    set L [list]
    catch { win::getInfo $name hookmodes } L
    win::setInfo $name hookmodes [linsert $L 0 strictshell]
    
#     win::lprependInfo $name bindtags strictshell
    set L [list]
    catch { win::getInfo $name bindtags } L
    win::setInfo $name bindtags [linsert $L 0 strictshell]
}




#### ALL THE HANDLE TYPING BUSINESS AND THE KEY BINDINGS ####
# 
# 
# Don't let the user type before the prompt:
proc console::strict::_interceptTyping { win pos char } {
#     alertnote $win $char
    if { ![lcontain [win::getInfo $win bindtags] "strictshell"] &&
      ![win::infoExists $win promptPos] } {
	::return
    }
    set promptPos [win::getInfo $win promptPos]
    if { [pos::compare $pos <= $promptPos] && [string length $char]} {
	# The character was typed before the prompt.
	# Put it back in the input field where it belongs:
	# (Can't use backspace here because it would trigger the
	# interceptor!)
	replaceText -w $win [pos::math $pos -1] $pos ""
	goto [maxPos]
	insertText $char
    }
}

hook::register characterInsertedHook ::console::strict::_interceptTyping strictshell


proc console::strict::backspace {} {
    set win [win::Current]    
    # Only do this for windows having an 
    # entry in the strictshellpromptpos array
    if { ![lcontain [win::getInfo $win bindtags] "strictshell"] &&
      ![win::infoExists $win promptPos] } {
	::return
    }
    set promptPos [win::getInfo $win promptPos]
    if { [pos::compare [getPos] < $promptPos] } {
	# The backspace was typed before the prompt.
	goto [maxPos]
    }
    if { [pos::compare [getPos] > $promptPos] } {
	::backSpace
    } elseif { [pos::compare [getPos] == $promptPos] } {
	beep
    }
}

proc console::strict::left {} {
    set win [win::Current]    
    # Only do this for windows having an 
    # entry in the strictshellpromptpos array
    if { ![lcontain [win::getInfo $win bindtags] "strictshell"] &&
      ![win::infoExists $win promptPos] } {
	::return
    }
    set promptPos [win::getInfo $win promptPos]
    if { [pos::compare [getPos] < $promptPos] } {
	# The left-arrow was typed before the prompt.
	goto [maxPos]
    } elseif { [pos::compare [getPos] == $promptPos] } {
	beep
    } else {
	::backwardChar
    }
}

proc console::strict::right {} {
    set win [win::Current]    
    # Only do this for windows having an 
    # entry in the strictshellpromptpos array
    if { ![lcontain [win::getInfo $win bindtags] "strictshell"] &&
      ![win::infoExists $win promptPos] } {
	::return
    }
    set promptPos [win::getInfo $win promptPos]
    if { [pos::compare [getPos] < $promptPos] } {
	# The right-arrow was typed before the prompt.
	::goto $promptPos
    } else {
	::forwardChar
    }
}

proc console::strict::RETURN { {win {}}} {
    if { ![string length $win] } {
	set win [win::Current]
    }
    
    # Only do this for windows having an 
    # entry in the strictshellpromptpos array
    if { ![lcontain [win::getInfo $win bindtags] "strictshell"] &&
      ![win::infoExists $win promptPos] } {
	::return
    }
    set promptPos [win::getInfo $win promptPos]
    set txt [getText -w $win $promptPos [maxPos -w $win]]
    set prompt [getText -w $win [pos::lineStart -w $win $promptPos] $promptPos]
    
    goto -w $win [maxPos -w $win]
    insertText -w $win \r
    win::setInfo $win promptPos [maxPos -w $win]
    set h [win::getInfo $win histlistVar]
    variable $h
    histlist update $h $txt
    eval [win::getInfo $win readlineProc] [list $win $txt $prompt]
    return
}


#### Bind all those special keys ####
Bind 0x24 console::strict::RETURN strictshell
Bind 0x34 console::strict::RETURN strictshell

Bind 0x7b console::strict::left strictshell
Bind 0x7c console::strict::right strictshell


#### up and down are bound to history ####
Bind 0x7e {console::strict::hist back} strictshell
Bind 0x7d {console::strict::hist forth} strictshell

proc console::strict::hist { dir } {
    set win [win::Current]    
    # Only do this for windows having an 
    # entry in the strictshellpromptpos array
    if { ![lcontain [win::getInfo $win bindtags] "strictshell"] &&
      ![win::infoExists $win promptPos] } {
	::return
    }
    set promptPos [win::getInfo $win promptPos]
    set h [win::getInfo $win histlistVar]
    variable $h
    set newTxt [histlist $dir $h]
    replaceText -w $win $promptPos [maxPos] $newTxt
}
