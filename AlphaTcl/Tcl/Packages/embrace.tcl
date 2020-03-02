# EMBRACE   --- a little Alpha package for embracing words 
# Author:   Joachim Kock <kock@math.uqam.ca>
# Version:  1.1.7  (18/09/2004)
#
# Description: A suite of keybindings for setting and removing all sorts of 
#              braces and quotes around the word under (behind) the cursor.
#              See the 'help' argument below for more information.
# 
# Changes:
# 1.1.7 - Option for keeping the aspell oneword pipe alive all the time,
#         to speed up oneword spellchecking.
# 1.1.6 - The embrace trigger key is no longer hardwired to Ctrl-B: it can
#         now be Ctrl-? for any letter ? in the range [a-z].  This letter 
#         is a preference variable $::embrace::trigger which can be set in 
#         Config -> Preferences -> Package Preferences -> Miscellaneous Packages.
# 1.1.5 - Hilite now admits infix argument --- why not? --- this simplified
#         the proc [embrace::hilite]!
#       - When operating on a whole line (infix 0), leading and trailing
#         whitespace is not included.  (This addresses a shortcoming
#         mentioned in the manual, so the manual is now shorter.)
#       - Binding Ctrl-B N for back quotes.
#       - Extrapolate!  If you mistype a word, just hit Ctrl-B X, and the
#         word will be corrected!  --- provided that somewhere nearby in the
#         text the correct word can be found.  (The proc looks about 5000
#         words back and forth to see if a similar word can be found.  
#         Similar means: either two adjacent letters are transposed, or one 
#         letter replaced by any other, or one letter added or deleted.  For 
#         example, if the current word is 'lapm' then possible matches are 
#         'lamp', 'lap', 'lam', 'lapim', and typically only one of the matches 
#         will actually exist in the text, hence the usefullness of the mechanism.
#       - There is also support for spellchecking the current word,
#         getting a list of suggestions in a listpick dialogue.  This feature,
#         Ctrl-B Z, is active only if aspell is installed on the system.
#       - mixedcase now looks forward as well as backwards.  (It is now
#         just a special case of Extrapolate and benefits from fancier
#         features in this proc.)
# 1.1.4 - Mode specific bindings are bound to Ctrl-B ctrl-? where ? is the
#         characteristic key.  So for example Ctrl-B ctrl-B is for boldface
#         in TeX, Wiki, Aida, Setx, HTML modes.
# 1.1.3 - Exchanged the meaning of Capitalize and Titlecase to conform to 
# 	  analogous string methods in Python.  Added "Ctrl-B O" binding for 
# 	  ::embrace::hilite.
# 1.1.2 - Capitalize applies to all words in a selection (or with infix)
#         in contrast to Titlecase which only applies to first word.
#       - Ctrl-B B yields a key bindings reminder.  
#         (Thanks, Bernard, for these two enhancements.)
# 1.1.1 - Cursor position preserved when no action.
#       - Two hidden options for testing and development: 
#         "Where to put the cursor after embrace? Select?"  
#         "Go forward if the cursor is immediately before a word?"
#       - Internal change: There is now a specific ::embrace::replaceText.
#         This led to simplifications throughout.
#       - generalRemove finetuned for the case where there is a selection
# 1.1   - Better package behaviour (help function, testPackage proc, and 
#         unBind on deactivate) --- thanks Craig.
#       - The find functions now place a bookmark.
#       - Mode specific bindings removed for the sake of leanness.
#       - Internal change: simplified setup of the bindings --- no more 
#         nested evals.  And it is now possible to define custom bindings
#         in prefs file.  Cleaned up code for Alpha8/X only!
# 1.0   - Initial version.  (First announced under the name TakeMyWord.)
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Q: Wouldn't it be better if: "When the cursor is at the beginning of a 
#    word then the operation applies to that word instead of applying to 
#    the previous?"
# A: See at the end of this file.  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

alpha::feature embrace 1.1.6 "global-only" {
    # Initialization script
    embrace.tcl
} {
    # Activation script
    
    # The letter B such that Ctrl-B triggers the embrace functions
    newPref var  ::embrace::trigger  b
    set ::embrace::previousTrigger $::embrace::trigger
    trace add variable ::embrace::trigger write ::embrace::reBind
    ::embrace::setBindings Bind $::embrace::trigger
} {
    # Deactivation script
    ::embrace::setBindings unBind $::embrace::trigger
} uninstall {
    this-file
} maintainer {
    "Joachim Kock" <kock@math.uqam.ca>
} description {
    A suite of keybindings for setting and removing all sorts of braces and
    quotes around the word under (behind) the cursor.
} help {
    This package creates a suite of keybindings and procs operating on the
    word under the cursor (or just preceding it --- see below for precise
    specification).
    
    Preferences: Features


		Table Of Contents

    "# Introduction"
    "# Key Bindings"
    "# Other Operations"
    "# Shortcomings"
    
    <<floatNamedMarks>>


		Introduction
    
    The principal functions are to put the word into any kind of braces,
    quotes, or tags, or take it out of any kind of braces, quotes, or tags.
    Each keybinding toggles the braces, quotes, or tags.  Other functions are
    similar to functions already found in Alpha: transform the word to upcase,
    lowercase, titlecase, or mixedcase; find another occurrence of it
    (forwards or backwards), hilite it or delete it.
    
    Which word?  If there is a selection the operation applies to the whole
    selection (somewhat contrary to the main philosophy of the mechanism).
    The main situation addressed is when there is no selection: then the
    'current word' is defined to be the last previous word, counting the start
    of the word.  (So if the cursor is in the middle of a word or at the end
    of a word, that word is the current; if the cursor is at the beginning of
    a word, or anywhere among punctuation characters or whitespace, then the
    previous word is the current.
    
    All operations are bound to two-step key combinations consisting of
    Control-B followed by a single key.  ('B' might be for 'braces', 'back',
    or 'balance'...  however you want to remember it.)  
    
    NOTE: the letter B can be changed to any letter via the preference
    variable embrace::trigger which can be set in Config -> Preferences ->
    Package Preferences -> Miscellaneous Packages.  In the following
    instructions we assume the letter B is used.
    
    So for example:
 
	Control-B P

    means 'set parentheses around current word'.  (Except if there are already
    parentheses around the word: then they are instead removed.)
    
    Click here <<embrace::testPackage>> to temporarily activate this package,
    and turn this window into a 'shell' to experiment with the key bindings
    described below.  (Note that in shell windows 'undo' is turned off, but
    normally all of these functions can be undone in a single action.)

    
		Key Bindings

    All of these follow Control-B
    
	P  parentheses             (  )
	A  angle brackets          <  >
	S  square brackets         [  ]
	C  curly braces            {  }
	Q  single quotes           '  '
	W  double quotes           "  "
	G  guillemets              Ç  È
	H  reverse guillemets      È  Ç
	J  single curly quotes     Ô  Õ
	K  double curly quotes     Ò  Ó
	N  back quotes             `  `
    
    (In latex mode, the quotes are inserted slightly differently, according 
    to latex syntax, so you get for example ``this'' instead of "this".)
    
    The operations can also apply to more than one word: this works by
    pressing an infix key between the Control-B and the characteristic key:
    For example
    
	Control-B 4 P

    will put parentheses around the previous four words (unless these
    parentheses already exist, in which case they are removed).  The infix
    keys allowed are 1,2,3,4,5, and 0.  0 means the entire line.  (1 is
    similar to absence of infix, but it means 'precisely one word, independent
    of any selection')
    
    Finally there is one more special infix key 'R': for example 

	Control-B R P

    will remove the innermost parentheses around the current word (even if
    these parentheses are a bit far away from the word).
    
    All actions are single-stroke undo-able.

    
		Other Operations

    All of these are without toggle
    
	L  lowercase
	U  upcase
	T  titlecase (all words)
	Y  capitalize (only first word)
	M  mixedcase
    
    lowercase, upcase, and titlecase admit infix arguments --- 
    capitalize and mixedcase don't: they only operate on the current word.
    
    (mixedcase is very useful in programming modes where you often name your
    variables and procedures with a happy mixture of lowercase and upcase
    letters.  If you have a mis-cased word then this operation corrects it!
    (it simply looks back and copies the casing from the previous occurrence
    of the variable, assumed to be correct...)
    
	X  extrapolate
    
    This tries to correct a mistyped word by looking around in the text for
    something similar.  Similar means: either two adjacent letters are 
    transposed, or one letter replaced by any other, or one letter added or 
    deleted.  For example, if the current word is 'lapm' then possible matches
    are 'lamp', 'lap', 'lam', and typically only one of the matches will
    actually exist in the text, hence the usefullness of the mechanism.
    
	Z  zpellcheck (only active if aspell is installed)
    
	D  delete    
	F  find next occurrence of word
	E  find previous occurrence of word
	
	V  toggle dollar (value of a variable)

	B  Show all embrace shortcuts
	
	O  hilite (and select)


		Shortcomings
    
    * If at a given word you set two different braces you have to set the
    outermost braces first.  Example: after the word foo if you invoke

	Control-B P Control-B 2 S
	
    then you end up with [word (foo]) --- hardly what you had in mind...  You
    have to do
    
	Control-B 2 S Control-B P
	
    to achieve proper nesting of braces.  Perhaps the programme ought to do a
    balance check inside the target, and refuse to operate on a target
    containing non-matched braces --- or better still: see if the braces can
    be matched by extending the target slightly...
    
    * Some of the good keybindings are already taken by exotic sorts of
    quotes...


		Quick reminder
		
    * Pressing "Control-B B" creates an <<embrace::displayBindings>> window
    with a short summary of all the 'embrace' keybinding combinations.
    
		Advanced users
    
    can find more information in "embrace.tcl".
}

proc embrace.tcl {} {}

namespace eval embrace {}

# Secret options for development purposes or for advanced users:
set   ::embrace::useRefreshToCircumventBug608   1
set   ::embrace::forwardAtWordStart             0
set   ::embrace::cursorAdjust                   after
# allowed values:  none, after, select
set   ::embrace::useAspellAfterExtrapolate      1

##################################################
### HERE COME THE GENERAL TOGGLED KEY BINDINGS ###
##################################################
# To define your personal bindings, write lines like the
# following in your prefs file, and then write also this line
# ::embrace::setBindings "Bind"
set ::embrace::keys(q) [list embrace::toggle "'" "'" ]
set ::embrace::keys(w) [list embrace::toggle "\"" "\"" ]
set ::embrace::keys(g) [list embrace::toggle "Ç" "È" ]
set ::embrace::keys(h) [list embrace::toggle "È" "Ç" ]
set ::embrace::keys(j) [list embrace::toggle "Ô" "Õ" ]
set ::embrace::keys(k) [list embrace::toggle "Ò" "Ó" ]
set ::embrace::keys(n) [list embrace::toggle "`" "`" ]
set ::embrace::keys(p) [list embrace::toggle "(" ")" ]
set ::embrace::keys(s) [list embrace::toggle "\[" "\]" ]
set ::embrace::keys(a) [list embrace::toggle "<" ">" ]
set ::embrace::keys(c) [list embrace::toggle "\{" "\}" ]
set ::embrace::keys(v) [list embrace::toggle "\$" "" ]
	# --- reinvention of classical Alpha command 'togglePrefix \$'
##################################################
### AND HERE COME THE OTHER DEFAULT BINDINGS   ###
##################################################
set ::embrace::keys(l) [list embrace::lowercase]
set ::embrace::keys(u) [list embrace::upcase]
set ::embrace::keys(t) [list embrace::titlecase]
set ::embrace::keys(y) [list embrace::capitalize]
set ::embrace::keys(m) [list embrace::mixedcase]
set ::embrace::keys(f) [list embrace::find 1 ] ;# forward
set ::embrace::keys(e) [list embrace::find 0 ] ;# backward
set ::embrace::keys(d) [list embrace::delete ]
set ::embrace::keys(b) [list embrace::displayBindings]
set ::embrace::keys(o) [list embrace::hilite ]
set ::embrace::keys(x) [list embrace::extrapolate]
########################################################
### AND HERE COME THE MODE SPECIFIC TOGGLED BINDINGS 
###        These are bound to Ctrl-B ctrl-?         ###
########################################################
##### TeX mode #####
set ::embrace::TeXKeys(q) [list embrace::toggle "`" "'"]
set ::embrace::TeXKeys(w) [list embrace::toggle "``" "''"]
set ::embrace::TeXKeys(e) [list embrace::toggle "\{\\em " "\}"]
set ::embrace::TeXKeys(i) [list embrace::toggle "\{\\it " "\}"]
set ::embrace::TeXKeys(b) [list embrace::toggle "\{\\bf " "\}"]
set ::embrace::TeXKeys(c) [list embrace::toggle "\\textsc\{" "\}"]
set ::embrace::TeXKeys(s) [list embrace::toggle "\\textsf\{" "\}"]
set ::embrace::TeXKeys(m) [list embrace::toggle "\\mbox\{" "\}"]
set ::embrace::TeXKeys(f) [list embrace::toggle "\\fbox\{" "\}"]
##### Wiki mode #####
set ::embrace::WikiKeys(i) [list embrace::toggle "''" "''"]
set ::embrace::WikiKeys(b) [list embrace::toggle "'''" "'''"]
##### Aida mode #####
set ::embrace::AidaKeys(i) [list embrace::toggle "((i " " i))"]
set ::embrace::AidaKeys(b) [list embrace::toggle "((b " " b))"]
##### Setx mode #####
set ::embrace::SetxKeys(i) [list embrace::toggle "~" "~"]
set ::embrace::SetxKeys(b) [list embrace::toggle "**" "**"]
##### HTML mode #####
set ::embrace::HTMLKeys(e) [list embrace::toggle "<EM>" "</EM>"]
set ::embrace::HTMLKeys(i) [list embrace::toggle "<I>" "</I>"]
set ::embrace::HTMLKeys(b) [list embrace::toggle "<B>" "</B>"]

################  SPELLCHECKING  #################
set ::embrace::aspellExists 0
if { $::tcl_platform(platform) == "unix" } {
    if { ![catch { exec which aspell } asp] } {
	if { [file executable $asp] } {
	    set ::embrace::aspellExists 1
	    set ::embrace::keys(z) [list embrace::spellcheck]
	}
    }
    unset -nocomplain asp
}


############  ACTIVATE ALL BINDINGS  #############
proc embrace::setBindings { doBind b } {
    set b [string tolower $b]
    set B [string toupper $b]
    ### BIND THE PREFIX CHAR ###
    $doBind    '$b'    <z>    { prefixChar }
    ### BIND THE INFIX CHARS ###
    $doBind    '1'    <$B>    { prefixChar }
    $doBind    '2'    <$B>    { prefixChar }
    $doBind    '3'    <$B>    { prefixChar }
    $doBind    '4'    <$B>    { prefixChar }
    $doBind    '5'    <$B>    { prefixChar }
    # operate on the whole line:
    $doBind    '0'    <$B>    { prefixChar }
    # general remove:
    $doBind    'r'    <$B>    { prefixChar }

    # Now bind the characteristic keys, as specified in the global
    # array ::embrace::keys --- and also the corresponding bindings 
    # with infixes, and generalRemove when applicable.
    variable keys
    foreach key [array names keys] {
	# Here is the plain binding:
	eval $doBind '$key' "<$B>" \{ $keys($key) \}
	# For some of the functions there are no other bindings to do:
	if { [lsearch -regexp $keys($key) \
	  {(capitalize|mixedcase|find)}] != -1 } {
	    continue
	}
	# And here come the infix bindings:
	eval $doBind '$key' "<${B}0>" \{ $keys($key) "wholeLine" \}
	for { set i 1 } { $i < 6 } { incr i } {
	    eval $doBind '$key' "<${B}$i>" \{ $keys($key) $i \}
	}
	if { [llength $keys($key)] == 3 } {
	    # This means we have a true embrace function, 
	    # for which it makes sense to do generalRemove.
	    set cmd [lreplace $keys($key) 0 0 ::embrace::generalRemove]
	    eval $doBind '$key' "<${B}R>" \{ $cmd \}
	}
    }
    
    # Now bind the mode specific keys as specified in the global
    # array ::embrace::{Mode}Keys --- and also the corresponding bindings 
    # with infixes, and generalRemove when applicable.
    foreach m [list TeX Wiki Aida Setx HTML] {
	variable ${m}Keys
	foreach key [array names ${m}Keys] {
	    # Here is the plain binding:
	    eval $doBind '$key' "<${B}z>" \{ [set ${m}Keys($key)] \} "$m"
	    # And here come the infix bindings:
	    eval $doBind '$key' "<${B}0z>" \{ [set ${m}Keys($key)] "wholeLine" \} "$m"
	    for { set i 1 } { $i < 6 } { incr i } {
		eval $doBind '$key' "<${B}${i}z>" \{ [set ${m}Keys($key)] $i \} "$m"
	    }
	    if { [llength [set ${m}Keys($key)]] == 3 } {
		# This means we have a true embrace function, 
		# for which it makes sense to do generalRemove.
		set cmd [lreplace [set ${m}Keys($key)] 0 0 ::embrace::generalRemove]
		eval $doBind '$key' "<${B}Rz>" \{ $cmd \} "$m"
	    }
	}
    }
 
    if { $doBind == "Bind" } {
	status::msg "Embrace package activated"
    } elseif { $doBind == "unBind" } {
	status::msg "Embrace package deactivated"
    }
    
}

# # This proc is called whenever the preference variable 
# # $embrace::trigger changes
# proc embrace::reBind { var dummy op } {
#     variable trigger
#     variable previousTrigger
#     if { ![regexp {^[a-zA-Z]$} $trigger] } {
# 	alertnote "embrace::trigger must be a single letter"
# 	set trigger $previousTrigger
# 	return
#     }
#     if { [info exists previousTrigger] } {
# 	setBindings unBind $previousTrigger
#     }
#     setBindings Bind $trigger
#     set previousTrigger $trigger
#     ::prefs::modified trigger
# }



# This proc is called whenever the preference variable 
# $embrace::trigger changes
proc embrace::reBind { var dummy op } {
    variable trigger
    variable previousTrigger
    
    # Check that the trigger is a simple letter:
    if { ![regexp {^[a-zA-Z]$} $trigger] } {
	alertnote "embrace::trigger must be a single letter"
	set trigger $previousTrigger
	help::openPrefsDialog Packages
	return
    }
    
    # Check if the binding is already taken, and ask the
    # user what to do in that case:
    set res ""
    set L [split [bindingList global] "\r"]
    set ii [lsearch -all -regexp $L "'${trigger}'\\s+<z>"]
    if { $ii != "" } {
	append res "Ctrl-$trigger already in use: bound to\r"
	foreach i $ii {
	    set binding [lindex $L $i]
	    append res \"[lindex $binding 3]\"
	    if { [llength $binding] > 4 } {
		append res " in "
		append res [lrange $binding 4 end]
		append res " mode"
	    } else {
		# 		append res " globally"
	    }
	    append res "\r"
	}
	
	regsub "\\r$" $res "" res
	
	switch -- [alert -t stop -o "" -k "Override" \
	  "$res" \
	  "Do you want to override this binding?"] {
	    "Override" {
		#continue
	    }
	    "Cancel" {
		status::msg "Embrace trigger not changed."
		set trigger $previousTrigger
		help::openPrefsDialog Packages
		return
	    }
	}
    }
    
    # If we have come this far, then the new key is OK.
    if { [info exists previousTrigger] } {
	setBindings unBind $previousTrigger
    }
    setBindings Bind $trigger
    set previousTrigger $trigger
    ::prefs::modified trigger
}



proc embrace::testPackage {} {
    if {![llength [winNames]] || [file isfile [win::Current]]} {
	help::openExample "LaTeX Example.tex"
    } 
    if {![package::active embrace]} {
	package::activate embrace
	set msg "The 'Embrace' package has been temporarily activated.  "
    } 
    setWinInfo read-only 0
    setWinInfo shell 1
    append msg "The bindings for this package have now been defined, and \
      this window is now a 'shell' in which you can experiment."
    alertnote $msg
}



#####################  Here comes the engine:  #######################


# This proc determines the target: which word(s) the other procs are
# going to operate on.  It doesn't return anything, but the parameters
# pos0 and pos1 are names that acquire the positions of the target.
# (Does not try to preserve cursor position --- this is up to calling proc)
proc embrace::aimAt {pos0 pos1 {infix ""} } {
    set originalPosition [getPos]
    upvar 1 $pos0 p0
    upvar 1 $pos1 p1
    if { [isSelection] } {
	if { $infix == "" } {
	    #only in this case do we look at selection
	    set p0 [getPos]
	    set p1 [selEnd]
	    return
	} else {
	    goto [selEnd]
	}
    }
    if { $infix == "wholeLine" } {
	set p0 [pos::lineStart [getPos]]
	set p1 [pos::lineEnd [getPos]]
	if { ![catch {search -f 1 -r 1 -l $p1 -- {\S} $p0} pair] } {
	    set p0 [lindex $pair 0]
	}
	if { ![catch {search -f 0 -r 1 -l $p0 -- {\s+$} $p1} pair] } {
	    set p1 [lindex $pair 0]
	}
	return
    }
    # otherwise $infix is numerical:
    backwardWord    
    set p0 [getPos]
    forwardWord
    set p1 [getPos]
    if { $::embrace::forwardAtWordStart } {
	# check if at start of word:
	forwardWord
	set q1 [getPos]
	backwardWord
	set q0 [getPos]
	if { [::pos::compare $q0 == $originalPosition] } {
	    # we started at word-start, so use q0 and q1
	    set p0 $q0
	    set p1 $q1
	}
    } 
    # in case we aim at more words:
    goto $p0
    while { $infix > 1 } {
	backwardWord
	set p0 [getPos]
	incr infix -1
    }
}


# This proc is just like ::replaceText but it respects the flags
# ::embrace::cursorAdjust and ::embrace::useRefreshToCircumventBug608
proc embrace::replaceText {pos0 pos1 args} {
    eval ::replaceText [list $pos0 $pos1] $args
    switch -exact -- $::embrace::cursorAdjust {
	select  {
	    select $pos0 [pos::math $pos0 + [string length [join $args ""]]]
	}
	after {
	    goto [pos::math $pos0 + [string length [join $args ""]]]
	}
	none {
	}
    }
    if { $::embrace::useRefreshToCircumventBug608 } { 
	refresh
    }
}

proc embrace::select { pos0 pos1 } {
    selectText $pos0 $pos1
    if { $::embrace::useRefreshToCircumventBug608 } { 
	refresh
    }
}


# Here comes the main proc: it toggles the brace pair b0 b1 around
# the current word (or current words if a numerical infix is given):
proc embrace::toggle {b0 b1 {infix ""} } {
    aimAt p0 p1 $infix
    # check if the braces exist outside the target
    set r0 [pos::math $p0 - [string length $b0]]
    if { [pos::compare $r0 >= [minPos]] && [getText $r0 $p0] eq $b0 } {
	set r1 [pos::math $p1 + [string length $b1]]
	if { [pos::compare $r1 <= [maxPos]] && [getText $p1 $r1] eq $b1 } {
	    # then remove the braces:
	    replaceText $r0 $r1 [getText $p0 $p1]
	    return
	}
    }
    # check if the braces exist inside the target
    set r0 [pos::math $p0 + [string length $b0]]
    if { [getText $p0 $r0] eq $b0 } {
	set r1 [pos::math $p1 - [string length $b1]]
	if { [getText $r1 $p1] eq $b1 } {
	    # then remove the braces:
	    replaceText $p0 $p1 [getText $r0 $r1]
	    return
	}
    }
    # No braces found --- so we just put them:
    replaceText $p0 $p1 $b0 [getText $p0 $p1] $b1
}


# Removes the innermost brace pair b0 b1 surrounding current word:
proc embrace::generalRemove { b0 b1 } {
    set originalPosistion [getPos]
    aimAt p0 p1
    set q0 [::pos::math $p0 + [string length $b0]] ;# start search here
    if { ![catch {search -f 0 -r 0 -i 0 -l [pos::math $p0 - 200] \
      -- $b0 $q0} found0] } {
	set r0 [lindex $found0 0]
	set p0 [lindex $found0 1]
	set q1 [::pos::math $p1 - [string length $b1]] ;# start search here
	if { ![catch {search -f 1 -r 0 -i 0 -l [pos::math $p1 + 200] \
	  -- $b1 $q1} found1] } {
	    set r1 [lindex $found1 1]
	    set p1 [lindex $found1 0]   
	    replaceText $r0 $r1 [getText $p0 $p1]
	} else {   
	    status::msg "embracing $b0 $b1 not found"
	    goto $originalPosistion
	}
    }
}




### Here come the upcase, lowercase, titlecase, capitalize, and
### mixedcase (case the word according to previous occurrences of it).
### upcase, lowercase and titlecase admit infix argument.
### capitalize and mixedcase operate only on current word.

proc embrace::upcase { {infix ""} } {
    aimAt p0 p1 $infix
    set text [getText $p0 $p1]
    set newtext [string toupper $text]
    replaceText $p0 $p1 $newtext
}

proc embrace::lowercase { {infix ""} } {
    aimAt p0 p1 $infix
    set text [getText $p0 $p1]
    set newtext [string tolower $text]
    replaceText $p0 $p1 $newtext
}

proc embrace::capitalize {} {
    global mode
    aimAt p0 p1
    set text [getText $p0 $p1]
    if { $mode == "TeX" } {
	if { [regsub {^\\} $text "" text] } { 
	    set p0 [pos::math $p0 + 1]
	}
    }
    if { $mode == "Tcl" } {
	if { [regsub {^\$} $text "" text] } { 
	    set p0 [pos::math $p0 + 1]
	}
	if { [regsub {^::} $text "" text] } { 
	    set p0 [pos::math $p0 + 2]
	}
    }
    set newtext [string totitle $text]
    replaceText $p0 $p1 $newtext
}

proc embrace::titlecase { {infix ""} } {
    aimAt p0 p1 $infix
    set text [getText $p0 $p1]
    set start 0
    while {[regexp -start $start -indices {\w+} $text res]} {
	set pos0 [lindex $res 0]
	set pos1 [lindex $res 1]
	set start [expr {$pos1 + 1}]
	set text [string replace $text $pos0 $pos1 \
	  [string totitle [string range $text $pos0 $pos1]]]
    }
    replaceText $p0 $p1 $text
}

proc embrace::mixedcase {} {
    set originalPosistion [getPos]
    aimAt p0 p1
    set text [getText $p0 $p1]
    global mode
    if { $mode == "TeX" } {
	if { [regsub {^\\} $text "" text] } { 
	    set p0 [pos::math $p0 + 1]
	}
    } elseif { $mode == "Tcl" } {
	if { [regsub {^\$} $text "" text] } { 
	    set p0 [pos::math $p0 + 1]
	}
	if { [regsub {^::} $text "" text] } { 
	    set p0 [pos::math $p0 + 2]
	}
    }
    set searchFromHere [pos::math $p0 - [string length $text]]
    if { ![catch {search -f 0 -r 0 -i 1 -- $text $searchFromHere} found] } {
	set newtext [eval getText $found]
	replaceText $p0 $p1 $newtext
    } else {
	status::msg "No idea how this word should be cased"
	goto $originalPosistion
    }
}


### MISC PROCS ###

# proc embrace::hilite {} {
#     backwardWord
#     set p0 [getPos]
#     forwardWord
#     set p1 [getPos]
#     select $p0 $p1
# }

proc embrace::hilite { {infix ""} } {
    aimAt p0 p1 $infix
    select $p0 $p1
    refresh
}

proc embrace::delete { {infix ""} } {
    aimAt p0 p1 $infix
    replaceText $p0 $p1 ""
}

proc embrace::find { {forward 1} } {
    aimAt p0 p1
    set text [getText $p0 $p1]
    if { $forward } {
	if { ![catch {search -f 1 -r 0 -m 1 -- $text $p1} found] } {
	    placeBookmark
	    eval select $found
	}
    } else {
	set len [pos::math $p1 - $p0]
	set searchFromHere [pos::math $p0 - $len]
	if { ![catch {search -f 0 -r 0 -m -- $text $searchFromHere} found] } {
	    placeBookmark
	    eval select $found
	}
    }
}


# Return a list of regular expressions matching deformations of the 
# given word, according to the specified subcommand.  Examples:
# 
#   wordDeform transposeTwoLetters abc
#              ->  {acb bac}
#   wordDeform replaceOneLetter abc
#              ->  {ab\w a\wc \wbc}
#   wordDeform addOneLetter abc
#              ->  {abc\w ab\wc a\wbc \wabc}
#   wordDeform deleteOneLetter abc
#              ->  {ab ac bc}
# 
# The lists are always constructed so that the deformations near the 
# end of the word are listed first.  (This is because errors are more 
# common near the end of a word than near the start.)
# 
proc wordDeform { subCmd word } {
    set n [string length $word]
    set reslist [list ]
    
    switch -exact -- $subCmd {
	"transposeTwoLetters" {
	    for { set i [expr $n-1] } { $i > 0 } { incr i -1 } {
		set newWord [string range $word 0 [expr $i-2]]
		append newWord [string range $word $i $i]
		append newWord [string range $word [expr $i-1] [expr $i-1]]
		append newWord [string range $word [expr $i+1] end]
		lappend reslist $newWord
	    }
	}
	"replaceOneLetter" {
	    for { set i [expr $n-1] } { $i >= 0 } { incr i -1 } {
		lappend reslist [string replace $word $i $i {\w}]
	    }
	}
	"addOneLetter" {
	    for { set i $n } { $i >= 0 } { incr i -1 } {
		set newWord [string range $word 0 [expr $i-1]]
		append newWord {\w}
		append newWord [string range $word $i end]
		# This new word will never match the original word 
		# because it is longer.
		lappend reslist $newWord
	    }
	}
	"deleteOneLetter" {
	    for { set i [expr $n-1] } { $i >= 0 } { incr i -1 } {
		lappend reslist [string replace $word $i $i ""]
	    }
	}
	default {
	    lappend reslist $word
	}
    }
    
    return $reslist    
}



proc embrace::extrapolate { {what typo} } {
    set pos [getPos]
    # Set search limits:
    set minlim [pos::math $pos - 30000]
    if { [pos::compare $minlim < [minPos]] } {
	set minlim [minPos]
    }
    set maxlim [pos::math $pos + 30000]
    if { [pos::compare $maxlim > [maxPos]] } {
	set maxlim [maxPos]
    }
    # Get the word:
    aimAt p0 p1
    set word [getText $p0 $p1]
    global mode
    if { $mode == "TeX" } {
	if { [regsub {^\\} $word "" word] } { 
	    set p0 [pos::math $p0 + 1]
	}
    } elseif { $mode == "Tcl" } {
	if { [regsub {^\$} $word "" word] } { 
	    set p0 [pos::math $p0 + 1]
	}
	if { [regsub {^::} $word "" word] } { 
	    set p0 [pos::math $p0 + 2]
	}
    }
    
    if { $what == "typo" } {
	# List of deformation types:
	set deformationTypeList [list \
	  transposeTwoLetters replaceOneLetter addOneLetter deleteOneLetter ]
    } elseif { $what == "case" } {
	# This is when we only look for alternative casing of the word
	set deformationTypeList [list dummy]
	# (Any one-element list will do --- it is just to get into the
	# next loop, then wordDeform will produce a list L with only one
	# entry, $word.)
    }
    
    foreach defType $deformationTypeList {
	set L [wordDeform $defType $word]
	# First we look backwards:
	foreach newWord $L {
	    if { ![catch { search -m 1 -i 1 -f 0 -r 1 -l $minlim $newWord [pos::math $p0-1] } pair] } {
		set foundWord [eval getText $pair]
		if { ![string equal $word $foundWord] } {
		    replaceText $p0 $p1 $foundWord
		    status::msg "Replaced '$word' by '$foundWord' (found above)"
		    return
		}
	    }
	}
	# Then try to look forward:
	foreach newWord $L {
	    if { ![catch { search -m 1 -i 1 -f 1 -r 1 -l $maxlim $newWord $p1 } pair] } {
		set foundWord [eval getText $pair]
		if { ![string equal $word $foundWord] } {
		    replaceText $p0 $p1 $foundWord
		    status::msg "Replaced '$word' by '$foundWord' (found below)"
		    return
		}
	    }
	}
    }
    
    # If nothing happened, we should just go back to where we started:
    goto $pos
    # It might be a good idea to invoke aspell at this point:
    variable aspellExists
    variable useAspellAfterExtrapolate
    if { $aspellExists && $useAspellAfterExtrapolate } {
	spellcheck
    } else {
	status::msg "Nothing better found"
    }

}


proc embrace::mixedcase {} {
    extrapolate case
}




#####################   EMBRACE SPELLCHECK   ###################
proc embrace::spellcheck {} {
    set pos [getPos]
    aimAt p0 p1
    set word [getText $p0 $p1]
    set aspRes [::aspell::checkOneWord $word]
    if { [regexp -- {^\*} $aspRes] } {
	status::msg "Correct spelling"
	goto $pos
    } elseif { [regexp -- {#} $aspRes] } {
	status::msg "No suggestions"
	goto $pos
    } elseif { [regsub {\& ([\w]+) [0-9]+ [0-9]+: } $aspRes "" aspRes] } {
	regsub -all " " $aspRes "" aspRes
	set aspRes [split $aspRes ,]
	if { [catch { set newWord [listpick $aspRes] }] } {
	    goto $pos
	} else {
	    replaceText $p0 $p1 $newWord
	}
    }
}


namespace eval aspell {}

set aspell::keepOnewordPipeOpen 1
hook::register quitHook { catch { close $::aspell::aspPipe } }

proc aspell::checkOneWord { word } {
    variable aspPipe 
    variable keepOnewordPipeOpen
    variable res
    if { ![info exists aspPipe] || ![lcontain [file channels] $aspPipe] } {
	set aspPipe [open "|aspell --sug-mode=normal pipe" RDWR]
	fconfigure $aspPipe -buffering line -translation auto -blocking 0 -encoding iso8859-1
	fileevent $aspPipe readable ::aspell::_awaitOneLine
    }
    puts $aspPipe $word
    set timeout [after 3000 {set ::aspell::res "TIMEOUT"}]
    vwait ::aspell::res
    set thisres $res
    # If we have come this far, there is no more need for the time bomb:
    after cancel $timeout
    if { !$keepOnewordPipeOpen } {
	close $aspPipe
	unset -nocomplain aspPipe
    }
    unset -nocomplain res
    return $thisres
}
# Event handler
proc aspell::_awaitOneLine { } {
    variable aspPipe
    variable res
    if { [eof $aspPipe] } {
	set res ERROR
	return
    }
    while { [gets $aspPipe line] != -1 } {
	if { ![regexp -- {^@\(#\)} $line] } {
	    set res $line
	    return
	}
    }
}


#####################   EMBRACE DISPLAY KEY BINDINGS   ###################

proc embrace::displayBindings {} {
	global tileLeft tileTop tileWidth errorHeight
	new -g $tileLeft $tileTop [expr int($tileWidth*.6)] \
	  [expr int($errorHeight *3)] \
	  -n "* Embrace Bindings *" -fontsize 9 \
	  -info [embrace::bindingsInfo]
	set start [minPos]
	while {![catch {search -f 1 -i 1 -r 1 {('|<)[a-z-]+('|>)} $start} res]} {
		text::color [lindex $res 0] [lindex $res 1] 1
		set start [lindex $res 1]
	}
	text::color [minPos] [nextLineStart [minPos]] 5
	refresh
}

proc embrace::bindingsInfo {} {
    variable trigger
    set B [string toupper $trigger]
	set mess "KEY BINDINGS AVAILABLE WITH THE EMBRACE PACKAGE\n\n"
	append mess "Press 'Control-${B}', release, then press one of the following keys:\n"
	append mess "\n"
	append mess "  'P'  parentheses             (  )\n"
	append mess "  'A'  angle brackets          <  >\n"
	append mess "  'S'  square brackets         \[  \]\n"
	append mess "  'C'  curly braces            {  }\n"
	append mess "  'Q'  single quotes           '  '\n"
	append mess "  'W'  double quotes           \"  \"\n"
	append mess "  'G'  guillemets              Ç  È\n"
	append mess "  'H'  reverse guillemets      È  Ç\n"
	append mess "  'J'  single curly quotes     Ô  Õ\n"
	append mess "  'K'  double curly quotes     Ò  Ó\n"
	append mess "  'N'  back quotes             `  `\n"
	append mess "\n"
	append mess "  'L'  lowercase\n"
	append mess "  'U'  upcase\n"
	append mess "  'T'  titlecase (all words)\n"
	append mess "  'Y'  capitalize (only first word)\n"
	append mess "  'M'  mixedcase\n"
	append mess "\n"
	append mess "  'X'  extrapolate (correct typo, extrapolating from vocabulary of document)\n"
	append mess "  'Z'  spellcheck word (provided aspell is installed)\n"
	append mess "\n"
	append mess "  'D'  delete\n"
	append mess "  'O'  hilite\n"
	append mess "\n"
	append mess "With infix followed by one of the letters above, the encloser\n"
	append mess "applies to <num> words:\n"
	append mess "\n"
	append mess "  Control-${B} <num> <letter>    with <num> = 1,2,3,4,5\n"
	append mess "  Control-${B}   0   <letter>    apply to entire line\n"
	append mess "  Control-${B}   R   <letter>    remove\n"
	append mess "\n"
	append mess "  'F'  find next occurrence of word\n"
	append mess "  'E'  find previous occurrence of word\n"
	append mess "  'V'  toggle dollar (value of a variable)\n"
	return $mess
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Q: Wouldn't it be better if: "When the cursor is at the beginning of a 
#    word then the operation applies to that word instead of applying to 
#    the previous?"
#    
# A: Perhaps it would be better...  The current design is defended by the
#    following arguments.  
#    
#    The main rationale is that the target (the area of operation) should be
#    to the left of the cursor, because in the act of typing this will
#    always be the most recent chunk of text, and consequently the chunk you
#    are most likely to want to operate on.  (This is also the reason why
#    the backspace key is much more important than the (forward)delete key.)
#    This main idea is adjusted by the obvious rule that we only operate on
#    whole words, so if the cursor does not separate two words (i.e. it is
#    strictly inside a word) then that word is included wholly in the
#    target.
#    
#    Here, 'being inside a word' was defined like this: 'you are inside a
#    word if both sides are part of it'.  This is what the Question is
#    about.  If you redefined this to include the boundaries of the word,
#    then you would get the behaviour suggested in the Question.
#    
#    There are several disadvantages with this second definition (where the
#    boundaries are included).  One problem is that it is not stable under
#    insertion of whitespace or punctiation characters (e.g. braces and
#    quotes!)  This means that if the cursor is between two words and you
#    insert whitespace or punctuation chars between the two words, the
#    'current word' may change!  As a particular example, if the cursor is
#    just before a word and you say embrace, then an opening brace is set
#    between the cursor position and the following word.  This means that
#    the very operation would change the notion of which word is the target.
#    As a consequence (in this situation) you cannot apply two operations on
#    the same target without repositioning the cursor manually.  (You might
#    very well want to apply quotes and \em to a word in tex, for example,
#    and you might well want to use these bindings to undo some operation,
#    since they are supposed to be toggling operations.)
#    
#    A second disadvantage implied by this alternative definition of being
#    inside a word is this: by the basic principle, the target is to the
#    left of the cursor.  With the alternative inside-word definition, it
#    will sometimes happen that in fact the target is completely to the
#    right of the cursor!  Also, suppose you choose to operate on three
#    words.  The target will then extend two words backwards and one word
#    forward, which seems a bit strange...
#    
#    The basic principle of operating leftwards is really the most important
#    criterion: at any given cursor position, *either* you arrived there by
#    typing, in which case you are likely to want to operate on the word you
#    just typed, not on anything to the right of the cursor (which by
#    assumption must be older text), *or* you arrived there through an
#    external cursor movement, but this movement is arbitrary anyway, and
#    there is no reason why it should be easier to place the cursor at the
#    beginning of the word than anywhere inside it or just after it --- this
#    is probably just a a bad habit of the hand holding the mouse.  (If the
#    operations are set up to act forward then you learn to place the cursor
#    to the left of the word you want to transform, if the design is rather
#    favouring backwards operations, then it is just as easy to place the
#    cursor after the word.)
#    
#    Here is a concrete example showing that even at the beginning of the
#    word you are more likely to operate leftwards: You have just typed the
#    word IDEA; then you decide that it would be better to write GOOD IDEA,
#    so you move the cursor backwards (typically through option-leftarrow):
#    now you are at the beginning of the word IDEA and you type GOOD
#    followed by a space.  Now the situation is GOOD |IDEA.  The point is
#    that even though the cursor is at the beginning of the word IDEA, it is
#    the word GOOD to the left of the cursor that has just been typed (and
#    as I argue, except for the case of external cursor movement, this will
#    always be the case), and you might very likely want to do some thing
#    with this word, for example put it into quotes, so you just hit
#    ctrl-b-q and arrive at 'GOOD' |IDEA.
