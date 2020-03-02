## -*-Tcl-*- (auto-install)
 # ==========================================================================
 # BibTeX for MacOS -- scripts for GURL interaction with Alpha.  also a
 # standard part of the AlphaTcl distribution.
 # 
 # FILE: "bibEngine.tcl"
 #                                          created: 11/13/1996 {12:58:47 am}
 #                                      last update: 03/21/2006 {02:01:35 PM}
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # INSTALLATION: Select 'Install This Package' from the install menu in Alpha
 # or Alphatk.
 #  
 # There is one more step: on MacOS, open Internet Config, select 'helpers'
 # and 'add' a helper for 'bibresult', and select as helper the application
 # 'Alpha'.
 # 
 #  modified by  rev reason
 #  -------- --- --- -----------
 #  13/11/96 VMD 1.0 original -- for use with BibTeX 1.1.4
 #  22/11/96 VMD 1.1 various improvements plus a name change
 #  31/1/97  VMD 1.2 handles some warnings and .bst files better now
 #  6/2/97   VMD 1.3 added some features, handles some more obscure errors 
 #  5/6/97   VMD 1.4 few improvements for release with BibTeX 1.1.7
 #  10/6/97  VMD 1.5 copes with some more technical BibTeX problems now.
 #  31/7/97  VMD 1.6 most code is elsewhere; now have new Alpha Tcl scheme.
 #  06/16/99 VMD 1.7 uses new AlphaTcl code.
 #  2000-01  VMD 1.8.x double-clicking in a .blg will have the same effect
 #                   as in the bibtex application's log  window.
 #  
 # Copyright (c) 1996-2006  Vince Darley.
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::library bibtexLogHelper 1.8.8 {
    if {$alpha::macos} {
	tclAE::installEventHandler GURL GURL GURL_AEHandler
    }
} uninstall this-file maintainer {
    "Vince Darley" vince@santafe.edu <http://www.santafe.edu/~vince/>
} description {
    When you command double-click on warnings, errors and filenames in
    any BibTeX log window, that generates a message which allows Alpha
    to interpret the error, warning or information you have clicked on
    and jump directly to the relevant text, automatically placing you in
    a situation to add a new bibliography entry, fix an error, add a
    .bib file, etc.
} help {
    When you command double-click on warnings, errors and filenames in
    any BibTeX log window (either within Alpha or in a log window
    generated by Vince Darley's Mac Classic port for BibTeX), that
    generates a message which allows Alpha to interpret the error,
    warning or information you have clicked on and jump directly to
    the relevant text, automatically placing you in a situation to 
    add a new bibliography entry, fix an error, add a .bib file, etc.
    
    It's a huge time-saver, I guarantee!
    
    If you are using this with MacBibTeX on MacOS Classic, you After
    turning this package on, there is one last step: open your control
    panel named Internet Config -- <<icOpen>> -- , select the dialog
    pane named 'Advanced', click on 'Helper Apps', click on the 'Add'
    button to create a new helper named 'bibresult', and select 'Alpha'
    as the helper application.  (Okay, that was really five steps ...)
}

proc bibEngine.tcl {} {}

# Note the code below is automatically used by TeX mode, as such this
# package is required for TeX mode not to throw an error when you
# cmd-double-click on bibtex log windows.

# MODIFY BELOW AT YOUR OWN RISK

## 
 # -------------------------------------------------------------------------
 #	 
 # "bibresultGURLHandler" --
 #	
 #  Handle 'bibresult' GURLs, as sent by the application BibTeX. These goto
 #  bibliography files, errors, warnings etc.  We do the parsing here.  See
 #  BibTeX's readme file for the syntax of the message. 
 # -------------------------------------------------------------------------
 ##
proc bibresultGURLHandler {msg} {
    # Extract base .aux file name (full path description or 'Unknown')
    set bpos [string first ".aux:" $msg]
    if {$bpos == -1} {
	set bpos [string first ".blg:" $msg]
    }
    set base_aux [string range $msg 0 [incr bpos 3]]
    # Get rest of message
    set msg [string range $msg [incr bpos 2] end]
    # if it's a file name; we need to open it:
    if {[regsub ".*: (\[^.\]+.(aux|bst|bib))(\[ \t\].*)?" $msg {\1} filename]} {
	set rest [string range $msg [expr [string first $filename $msg] + [string length $filename] ] end]
	Bib::openFile ${filename} [file dirname $base_aux]
	if {[string trim $rest] == "not found"} {
	    alertnote "This file was not found by BibTeX.  You should either move it to another location, or add to BibTeX's search paths."
	}
	return
    }
    
    switch -glob [lindex [split $msg "-"] 0] {
	"Warning" {
	    if {[set a [string first " --line" $msg]] != -1} {
		# it's a more technical warning
		# Warning--string name "jppa" is undefined --line 11516 of file newl.bib
		set line [string range $msg $a end]
		set realmsg [string range $msg 0 $a]
		Bib::_ScanAndGoto $line " --" [file dirname $base_aux]
		beep
		status::msg $realmsg
		return
	    }
	    # extract warning type and find the entry
	    # the last item is the entry (minus quotes possibly)
	    set realmsg [set msg [string range $msg 9 end]]
	    if {[string first ";" $msg] != -1} {
		# we have some stuff _after_ the item
		set msg [lindex [split $msg ";"] 0]
	    } 
	    # the msg ends in the bib entry
	    set llen [llength $msg]
	    set item [string trim [lindex $msg [incr llen -1]] "\""]
	    set warning [lrange $msg 0 [incr llen -1]]
	    if {$warning eq "I didn't find a database entry for"} {
		# no entry exists, prompt to make one
		Bib::noEntryExists $item $base_aux
		return
	    } else {
		# get local bib files:
		set bibs [glob -nocomplain -dir [file dirname $base_aux] *.bib]
		# go to a current entry
		Bib::GotoEntry $item $bibs
		beep
		status::msg "Warning--$realmsg"
		return
	    }
	}
	"Aborted*" {
	    # Aborted at line 12030 of file newl.bib
	    Bib::_ScanAndGoto $msg "Aborted at " [file dirname $base_aux]
	    beep
	    status::msg "BibTeX processing aborted at this line."
	}
	default {
	    Bib::_GotoError $msg $base_aux
	}
    } 
}

proc Bib::_ScanAndGoto {msg prefix dir} {
    scan $msg "${prefix}line %d of file %s" line filename
    Bib::openFile ${filename} ${dir}
    goto [pos::fromRowCol $line 0]
    endLineSelect
}


## 
 # -------------------------------------------------------------------------
 #	 
 # "Bib::_GotoError" --
 #	
 #  Parse and goto a specific error in a particular file.  Look locally for
 #  the correct text in case we've edited the file. 
 # -------------------------------------------------------------------------
 ##
proc Bib::_GotoError {msg {basefile ""}} {
    set dir [file dirname $basefile]
    # is it an 'I found no xxxx while reading file yyy' error?
    if {[regsub {I found no .*---while reading file (.*)} $msg {\1} filename]} {
	Bib::openFile $filename $dir
	beep
	status::msg $msg
	return
    }
    
    # It's a more specific error.  
    # Extract type, line, filename, and position of error
    set errtype [lindex [split $msg "-"] 0]
    if {![regsub {.*line ([0-9]+) .*} $msg {\1} line]} {
	error "Failed to parse line number from BibTeX error"
    }
    if {![regsub {.*of file (.*) a .*} $msg {\1} filename]} {
	error "Failed to parse filename from BibTeX error"
    }
    if {![regsub {.*a '(.*)' at.*} $msg {\1} problem]} {
	error "Failed to parse problem text from BibTeX error"
    }
    if {![regsub {.*at (.*)} $msg {\1} linepos]} {
	error "Failed to parse line position from BibTeX error"
    }
    # Un-map the encoding we did on the other end.
    regsub "�" $problem "\{" problem
    regsub "�" $problem "\}" problem
    # Un-map the encoding we did on the other end.
    regsub "�" $errtype "\{" errtype
    regsub "�" $errtype "\}" errtype
    # perform some action?
    switch -glob $errtype {
	"Case mismatch error between cite keys*" {
	    if {[askyesno "There is a c[string range $errtype 1 end]. Do you wish to change one of the original citations?"] == "yes"} {
		regexp {[^\{,]$} $problem var
		Bib::changeOriginalCitation $var [Bib::getBasefile $basefile]
		return
	    }
	}
    }	
    # default is to open the file and highlight the error.
    Bib::openFile $filename $dir
    # Should this be pos::fromRowCol ?
    goto [pos::fromRowChar $line $linepos]
    set pos [getPos]
    if {[getText [lineStart $pos] $pos] != $problem} {
	# we've	edited the file; look locally
	set pr "^[quote::Regfind $problem]"
	if {![catch {search -s -f 0 -r 1 -l [pos::math $pos - 300] $pr $pos} found]} {
	    set pos [lindex $found 1]
	} elseif {![catch {search -s -f 1 -r 1 -l [pos::math $pos + 300] $pr $pos} found]} {
	    set pos [lindex $found 1]
	}			
    }
    selectText [lineStart $pos] $pos
    beep
    status::msg "$errtype"
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Bib::blgDoubleClick" --
 # 
 #  This procedure can be used by the editor to do sensible
 #  command-clicking in a .blg log file.  A version of this code in C++ is
 #  used by Vince's port of BibTeX when it sends an event to Alpha.  If you
 #  must use a different editor, you could use this code as a basis. 
 # -------------------------------------------------------------------------
 ##
proc Bib::blgDoubleClick {from to args} {
    if {[pos::compare [getPos] == [maxPos]]} {return}
    set offset $from
    # Find current blg 'unit': first find start, then end
    # Back-up while the line starts with " : ", or "I'm skipping whatever remains"
    set lineStart [lineStart [pos::math $offset + 1]]
    while {[pos::compare $lineStart > [minPos]] && \
      ([pos::compare $lineStart > $offset] || \
      [str_is $lineStart " : "] || \
      [str_is $lineStart "--"] || \
      [str_is $lineStart "I'm skipping whatever remains"] )} {
	set lineStart [pos::math $lineStart - 1]
	if {[pos::compare $lineStart >= [minPos]]} {
	    set lineStart [lineStart $lineStart]
	}
    }
    # Go forward and keep going while the next line starts with " : " or "--"
    set lineEnd [nextLineStart $offset]
    while {[pos::compare $lineEnd < [maxPos]] && \
      ([str_is $lineEnd " : "] || [str_is $lineEnd "--"])} {
	set lineEnd [nextLineStart $lineEnd]
    }
    set lineEnd [pos::math $lineEnd - 1]
    # Fails for blank lines or at the end of the window in some circumstances
    if {[pos::compare $lineEnd > $lineStart] \
      && ![str_is $lineStart "BibTeX"] \
      && ![str_is $lineStart "This is BibTeX"] \
      && ![str_is $lineStart "Sorry"] \
      && ![str_is $lineStart "("] \
      && ![str_is $lineStart "I'm skipping whatever remains"] \
      && ![str_is $lineStart "Dynamic memory"]} {
	# Now send the whole thing to our editor	
	# append event "bibresult:"
	if {[file exists [win::Current]]} {
	    append event [win::Current]
	} else {
	    set f [lindex [getText [minPos] [nextLineStart [minPos]]] 1]
	    if {[file exists [file join [pwd] $f]]} {
		append event [file join [pwd] $f]
	    } else {
		append event "Unknown"
	    }
	}
	append event ":"
	append event [getText $lineStart $lineEnd]
	
	# convert any "\r---line" sequences to " ---line"
	regsub -all "\[\r\n\]---line" $event " ---line" event
	# now we deal with a multi-line ' : ' error, if it exists.
	if {[set errpos [str_first "\r\n" $event]] != -1} {
	    
	    # We have a multi-line error.  We have two strings, before and
	    # after the character at which the error occurred.  We ignore
	    # the second half and send " a 'err-prefix' at err-pos".  Then
	    # we add '\0' to terminate, calculate the length and send it.
	    
	    # How long is the prefix
	    incr errpos -3
	    # Replace the newline,':' with " a '"
	    regsub "\[\r\n\] : " $event " a '" event
	    # Move beyond the error prefix
	    set errpos2 [str_first "\r\n" $event]
	    set event [string range $event 0 $errpos2]
	    # Add "' at " and the length term.
	    append event "' at " [expr {$errpos2 - $errpos}]
	}
	# We must map out '{}' since something in the connection 
	# from 'theIC.DoURL <---> Alpha-receiving' complains 
	regsub -all "\{" $event "�" event
	regsub -all "\}" $event "�" event
	selectText $lineStart $lineEnd
	#icURL $event
	bibresultGURLHandler $event
    }
}

proc str_first {chars str} {
    set l [split $str $chars]
    if {[llength $l] == 1} {
	return -1
    } else {
	return [string length [lindex $l 0]]
    }
}

proc str_is {pos what} {
    if {[getText $pos [pos::math $pos + [expr {[string length $what] -1}]]] == $what} {
	return 1
    } else {
	return 0
    }
}

# ===========================================================================
# 
# .