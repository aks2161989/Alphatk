## -*-Tcl-*- nowrap
 # ###################################################################
 # 
 #  FILE: "dictionary.tcl"
 #                                last update: 03/21/2006 {02:06:44 PM}
 #  Author: Joachim Kock
 #  E-mail: <kock@mat.uab.es>
 # 
 #  Description: 
 # 
 #  Alpha package for looking up words in plain-text dictionaries 
 #  
 #  Version 2.3.2 and newer require AlphaTcl 8.1a1.
 #  Version 1.8 and newer require Alpha 8 (with AlphaTcl8.0d2)
 #  (Version 1.0 works with Alpha 7.x)
 #  
 #  Changes in version 2.3.5 (2006-03-16)
 #  
 #  - [histlist] is now in the AlphaTcl SystemCode.
 #  
 #  Changes in version 2.3.4 (2005-04-02)
 #  
 #  - Fix bug when returning to original window after consulting dictionary.
 #    This bug was introduced many months ago when the AlphaTcl proc 
 #    [nextWindow] was changed to refer to creation-order not stack-order.
 #    (A wrong fix was introduced in dictionary version 2.3.1, changing 
 #    [nextWindow] to [prevWindow].  The correct proc to use is 
 #    [swapWithNext].)
 #  - Fix bug when opening dictionary console from AlphaTcl Shell.
 #  - Fix 'macroman' to 'macRoman'.  Encodings are not documented to
 #    be case insensitive (and are not in Tcl 8.5).
 #  - Fixed broken [checkSorting] and [sortFile].
 #  
 #  Changes in version 2.3.3 (2005-03-12)
 #  
 #  - Can handle dictionaries in other encodings than "macRoman".  If a
 #    dictionary file has a string like
 #      encoding="utf-8"
 #    in its first line, then this is recognised as the encoding.  (For the
 #    sake of backward compatibility, this string is not required, and in
 #    its absence, encoding="macRoman" is assumed.)
 #  - Dico mode no longer exists.  Instead, minormode "dictionary" is used.
 #    
 #  Changes in version 2.3.2
 #  
 #  - All console geometry has been delegated to the consoleAttributes
 #    package.  As a consequence, all changes to console geometry (or 
 #    fontsize etc) is preserved automatically, and the menu items
 #    'saveConsoleGeometry' and 'resetConsoleGeometry' have been
 #    eliminated.  (Saving is automatic, and to reset you ought to be able
 #    to use shrinkFull --- this has not been implemented yet).  
 #  - Behaviour change: the name of the Dictionary console windows no 
 #    longer includes the name 'Dictionary Console', but just the name of 
 #    the dictionary.
 #  - Small internal fine tunings.
 #  
 #  Changes in version 2.3.1
 #  
 #  - Implemented opt-click-titlebar: change dictionary.
 #  - Small internal fixes and maintenance.
 #  - Quick Lookup mechanism:  In the Dictionary Console, look up words 
 #    as soon as a character is typed.  This behaviour is controlled by the 
 #    $useQuickLookup preference flag.
 #  - Typing outside the input field in a Dictionary Console is now
 #    redirected to the input line.
 #  - Headword colouring now works as expected (using [text::color] instead
 #    of dynamical regKeyWords
 #  
 #  Changes in version 2.3.0
 #  
 #  - man dictionary! (using exec troff)
 #  - fixed infinite loop when sourcing empty dictionary
 #  - space bar is pager in dictionary consoles (except when typing in
 #    the input line). (Shift-space is 'page back'.)
 #  - The formatOutput procs of the individual dictionaries can now
 #    set the variable currentHeadword if they want.  This is supposed
 #    to colour the occurrences of the headword blue (but due to some
 #    draw-on-screen bug in Alpha(?), currently this only works when the
 #    lookup is performed from another window than the console...
 #    The presence of the variable currentHeadword also allows for 
 #    tabbing through all occurrences of the headword.  The variable
 #    is not compulsory, so old dictionaries continue to work...
 #  - Internal changes:   Writing to the console is now done
 #    centrally by [writeToConsole].  (Previously four different procs
 #    had this privilege...)  The calling procs pass the arguments
 #    by writing to the global variable Dico::thisLookup.  (This scheme 
 #    led to several simplifications.)
 #    
 #  Changes in version 2.2.1:
 #  
 #  - Updated email and url.  
 #  - The changeDictionary listpick (and friends) now present a sorted list.
 #  - The localDictionaries menu no longer imposes itself as an 'other 
 #    possible feature'.
 #  
 #  Changes in version 2.2.0:
 #  
 #  - Fixed encoding problem under AlphaX using fconfigure on all streams
 #  - Console geometry computation now takes operating system into account
 #    (no borders in OSX).  [Internal change: upon resetConsoleGeometry,
 #    computeDefaultGeometry now actually computes something, instead of 
 #    just copying from the cache.]
 #  - Workaround for the set fontsize bug
 #  - The index of the sample dictionary 'Tcl-Commands' is now generated
 #    on first run, and it is updated automatically if the file 'Tcl 8.4
 #    Commands.txt' changes.  (It was apparently impossible to maintain a 
 #    synchronised version in CVS, probably due to encoding differences?).
 #    The index is placed in $PREFS/Cache. 
 #  - Internal change: uses histlist for back and forth.
 #  
 #  Changes in version 2.1.3:
 #  
 #  - Cleaned up some code (thanks Vince); dictionary consoles fontSize
 #    now set using 'new -fontsize 9'; keybindings documented; 
 #  - Never opens console upon empty return string.  (This allows for 
 #    support for external renderer.)
 #
 #  Changes in version 2.1:
 #  
 #  - Bug fixed once again: current dictionary remembered over restarts
 #  - Simplification in the boot sector format: the offSet is no longer
 #    required --- it is computed automatically at boot time (thanks Bernard,
 #    for this suggestion).  (Instead, it is now prohibited to have non-white 
 #    lines between end of boot sector and start of the data sector.)
 #    The proc 'compare' is no longer used --- it was actually obsolete...
 #  - Bug fix: Dico::sortFile was completely broken --- works again.
 #  - Better handling of the case where a dictionary is moved or renamed;
 #    simplification of init sequence.
 #  
 #  Changes in version 2.0:
 #  
 #  - it is now a feature rather than a mode (but it still defines Dico mode 
 #    internally).  A submenu is inserted in the Utils Menu.
 #    
 #  - The dictionary console can now optionally be kept in the background.
 #  - The dictionary console can now optionally be shared among all 
 #    dictionaries, to avoid window clutter.
 #  - The position of the console (for each dictionary) can be saved, and
 #    it can also be reset... The default console position is adjusted 
 #    according to screen size and location of status bar
 #  - If there is no word to look up (e.g. no window open) then look up
 #    a random word.
 #  - checkSorting writes to its own window and does no longer depend on
 #    a shell window
 #  - This file no longer serves as default dictionary.  Instead there
 #    are provided three instructive example dictionaries.  These should
 #    reside in $HOME:Examples:Dictionary-Examples
 #    
 #    
 #    INTERNAL CHANGES:
 #  - The main Dico::lookup now returns its findings as a string to the 
 #    calling proc, instead of trying to write to the console directly.
 #  - Reorganisation, some simplification.  Many finetunings and handling 
 #    of tricky extreme cases...
 #  - The internal mode and the main namespace has changed from Dict to
 #    Dico, to avoid confusion with the DICT internet protocol.  (Dico
 #    is casual French for dictionary, I have just learned.)
 #  - More consistent namespace manoevres...
 #    
 #    
 #  Changes in version 1.8.1:
 # 
 #  - 'Install' dialogue code simplified
 #  - prefs handling rectified
 #  
 #  
 #  Changes in version 1.8:
 #  
 #  - More elegant dictionary handling: dictionaries can now be located
 #    anywhere; there is an install proc with dialogue boxes which handles
 #    dictionary installation (records their path in the global array
 #    Dico::path, which is remembered over restarts).  Internal name (and
 #    window title) has been decoupled from the actual file name; dictionary
 #    specific procs are now stored in a boot sector in the very data file 
 #    of the dictionary instead of in separate tcl files, thus ensuring that
 #    dictionary file and specific procs are always in synch: the namespace
 #    is created dynamically.  An offset variable tells the lookup proc where
 #    to start --- thus the dictionary file can now contain other header 
 #    information like copyright notices and origin.  If the data file has 
 #    no boot sector, fallback procs stand in; 
 #  - Current dictionary is remembered over restarts; 
 #  - More consistent variable names and namespaces; some globals have been 
 #    bundled into an array.  
 #  
 # ###################################################################
 ##

alpha::feature dictionary 2.3.5 "global-only" {
    # Startup script
} {
    # Activation script, create namespace and run a proc
    namespace eval Dico {
	loadFeature
    }
} {
    # De-activation script.
    ::Dico::removeFeature
} requirements {
    if {[info tclversion] < 8} {
	error "This feature requires Tcl 8 (or newer)"
    }
} uninstall {
    this-file
} maintainer {
    "Joachim Kock" <kock@mat.uab.es>
} description {
    This feature allows you to consult local plain text dictionaries via a
    menu item inserted in the Utils Menus, and the key binding Control-O
} help {
    file "Dictionaries Help"
}

proc dictionary.tcl {} {}

namespace eval Dico {}

proc Dico::loadFeature {} { 
    # To have the Dictionary Console frontmost when a word is looked up, 
    # click this box||To keep the Dictionary Console in the background, 
    # even when a word is looked up, click this box.
    newPref f ::Dico::backgroundConsole 0
    # To have one Dictionary Console for each dictionary, click this 
    # box||To have a single Dictionary Console common to all dictionaries, 
    # click this box.
    newPref f ::Dico::commonConsole 0
    newPref v ::Dico::current "Country-codes" global "" ::Dico::path array
    prefs::modified ::Dico::current
    # This pref should have value 9 since console geometries assume this.
    newPref variable fontSize 9 Dico
    if { ![::console::exists "* Dictionary Console *"] } {
	computeDefaultAttributes
    }

    # Look up continuously while typing in the dictionary console.
    # (Note: this makes the history mechanism less useful.)
    newPref f ::Dico::useQuickLookup 0
    # Monitor key presses in case of $useQuickLookup:
    hook::register characterInsertedHook Dico::quickLookup "Dico"

    # other global settings:
    set ::Dico::gvars(sep) [string repeat "-" 80]
    set ::Dico::gvars(historyDepth) 8

    ### Set the paths of the three example dictionaries ###
    variable path
    prefs::modified ::Dico::path
    # Only do the following if the path is not already set.  Otherwise if the 
    # user has uninstalled any of these four standard dictionaries it will be 
    # installed again...
    if { ![info exists ::Dico::path] } {
	foreach dic [list Country-codes Tcl-commands Whisky-distillers] {
	    set path($dic) [file join $::HOME Examples Dictionary-Examples $dic]
	}
    }
    if { ![catch { exec man -w man }] && ![catch { exec groff -v }] } {
	# If exec man works, we also install the man dictionary
	set path(man) [file join $::HOME Examples Dictionary-Examples man]
    } else {
        unset -nocomplain path(man)
    }
    # Check the paths and initialise:
    foreach dic [array names path] { 
	if { [file readable $path($dic)] } {
	    initDictionary $dic 1 ; # 1=silently
	} else {
	    alertnote "The dictionary \"$dic\" was not found.  Please reinstall it."
	    unset path($dic)
	}
	status::msg "Dictionaries initialised"
    }
    # Check that current dictionary is still valid:
    if { ![info exists path($::Dico::current)] } {
	# and choose another one if not:
	set ::Dico::current [lindex [array names path] 0]
    }
    
    # Create a "minor mode" for the Dico Window, overriding all aspects
    # of the Text window we will create.
    alpha::minormode "dictionary" bindtags "Dico" hookmodes "Dico" \
      varmodes "Dico" featuremodes "Dico" colortags "Dico"

    ###  Menus and basic key bindings ###
    menu::buildProc "localDictionaries" "menu::buildLocalDictionariesMenu" 
    menu::buildProc "someTools" "menu::buildSomeToolsMenu" 
    menu::insert   Utils submenu 5 "localDictionaries"
    menu::insert   localDictionaries submenu end "someTools"
    Bind 'o' <z> ::Dico::consultDictionary
    Bind 'o' <z> ::swapWithNext "Dico"
    Bind 'o' <sz>  ::Dico::changeDictionary
    # 		Bind 'o' <soz> ::Dico::installDictionary
    Bind 'o' <csoz> ::Dico::editDict
    
    prefs::saveNow
}

proc Dico::removeFeature { {completely 0} } {
    menu::uninsert Utils submenu 5 "localDictionaries"
    unBind 'o' <z> ::Dico::consultDictionary
    unBind 'o' <z> ::swapWithNext "Dico"
    unBind 'o' <sz>  ::Dico::changeDictionary
    unBind 'o' <csoz> ::Dico::editDict
    foreach dic [array names ::Dico::path] {
	catch { killWindow -w "* $dic *" }
    }
    catch { killWindow -w "* Dictionary Console *" }
    unset -nocomplain ::Dico::thisLookup
    
    # 'Completely' means that all settings are removed and the 
    # namespace deleted.  Hence a subsequent activation will start
    # from scratch.  
    if { $completely } {
	foreach var [info vars ::Dico::*] {
	    if { [array exists $var] } {
		prefs::removeArray $var
	    } else {
		prefs::remove $var
	    }
	    prefs::modified $var
	    unset $var
	}
	# namespace delete ::Dico
    }
    status::msg "Dictionaries de-activated"    
}


########## Dictionary console key bindings ##########

# Enter:
Bind 0x34 ::Dico::carriageReturn "Dico"
# Carriage return:
Bind '\r' ::Dico::carriageReturn "Dico"
# Backspace:
Bind 0x33  Dico::backspace "Dico"
# Tab:
Bind 0x30 ::Dico::tab "Dico"
# Space:
Bind 0x31 { ::Dico::space Forward } "Dico"
# shift-Space:
Bind 0x31 <s> { ::Dico::space Back } "Dico"

# Leftarrow:
Bind 0x7b  ::Dico::prevWord  "Dico"
# Rightarrow:
Bind 0x7c  ::Dico::nextWord  "Dico"
# Downarrow:
Bind 0x7d  ::Dico::downWord  "Dico"
# Uparrow:
Bind 0x7e  ::Dico::upWord  "Dico"

# Cmd-down:
Bind 0x7d <c> ::Dico::nextEntry  "Dico"
# Cmd-up:
Bind 0x7e <c> ::Dico::prevEntry  "Dico"

# Cmd-left:
Bind 0x7b <c> ::Dico::histLookBack "Dico"
# Cmd-right:
Bind 0x7c <c> ::Dico::histLookForth "Dico"


########## Menu junk ##########

proc localDictionariesMenu {} {}

proc menu::buildLocalDictionariesMenu {} {
    set ma ""
    lappend ma "consultDictionary \"$::Dico::current\""
    lappend ma "changeDictionary…"
    lappend ma "(-)"
    lappend ma "reinitialiseDictionary \"$::Dico::current\""
    lappend ma "installDictionary…"
    lappend ma "uninstallDictionary…"
    return [list build $ma ::Dico::menuProc {}]
}
proc menu::buildSomeToolsMenu {} {
    set ma ""
    lappend ma "openDataFile \"$::Dico::current\""
    lappend ma "checkSorting…"
    lappend ma "sortDictionaryFile…"
    return [list build $ma ::Dico::menuProc {}]
}
proc Dico::menuProc {menuName itemName} {
    if {[regexp "consultDictionary" $itemName]} {
	consultDictionary
    } elseif {[regexp "changeDictionary" $itemName]} {
	changeDictionary
    } elseif {[regexp "reinitialiseDictionary" $itemName]} {
	initDictionary $::Dico::current
    } elseif {[regexp "uninstallDictionary" $itemName]} {
	uninstallDictionary
    } elseif {[regexp "installDictionary" $itemName]} {
	installDictionary
    } elseif {[regexp "openDataFile" $itemName]} {
	editDict
    } elseif {[regexp "checkSorting" $itemName]} {
	checkSorting
    } elseif {[regexp "sortDictionaryFile" $itemName]} {
	sortFile
    }
}




# ====================================================================
# ====================================================================
# 
# General remarks on dictionary management
# 
# ====================================================================
# ====================================================================
#
# Before a dictionary can be used (e.g. made current) it must be installed
# and initialised.
# 
# 'Installed' means that the programme has a name for it and knows where
# the data file is --- this information is stored in the array Dico::path,
# which is a preference and is preserved even when Alpha quits.
# 
# 'Initialised means that the dictionary has a namespace, and that its
# specific procs have been sourced from the data file, and that certain
# global variables exist.  When the Dictionary Feature is loaded (typically
# when Alpha starts up), all installed dictionaries are initialised.  Also,
# whenever a dictionary is installed it is also initialised.
# 
# This means that in practice (in normal operation of the programme) the
# two notions coincide.  For this reason, the individual procs of the
# programme don't check if variables exist, or bother about what to do if
# not.  
# 
# One exception: since typically the dictionary files reside in distant
# regions of the hard-disc, and they might be moved by accident while
# Alpha is already running, it is wise perhaps to let the lookup-proc
# check if the file exist, i.e. catch the error and report back to the user
# that the dictionary was not found please locate it...
#
# If some prefs or global variables are out of sync, in principle it should
# be enough to de-activate the Dictionary Feature and then activate it
# again.  Perhaps even restart Alpha.  In practice this may not be
# sufficient, because of cached variables...

# The following global variables are maintained for each initialised
# dictionary:
# 
# Dico::${dic}::lastPos           the position in the dictionary file of 
#                                 the current entry
# Dico::${dic}::historyList       a list whose entries are {pos word} of 
#                                 previously looked-up words.  (Only words
#                                 looked up from scratch: only the proc
#                                 Dico::lookup writes to this variable.)
#

# ====================================================================
# ====================================================================
# 
# Generic fallback procs 
# for dictionaries which do not define their own procs...
# These are created in the namespace ::Dico::fallback and then exported.
# When needed by some dictionary, they are imported into its namespace.
# 
# ====================================================================
# ====================================================================
namespace eval ::Dico::fallback {
    # This proc takes the first word of the input string, strips all accents, 
    # removes all non-alpha letters, and transforms to lowercase...
    proc normalForm { chunk } {
	# in case there is some html-like markup:
	if { ![regexp {<([^<>]+)>([^<]+)</\1>} $chunk dummy0 dummy1 chunk] } {
	    #otherwise just take the first word:
	    regexp {[^ \t]+} $chunk chunk
	} 
	regsub -all {[áÁàÀâÂãÃåÅ]} $chunk {a} chunk
	regsub -all {[çÇ]} $chunk {c} chunk
	regsub -all {[éÉèÈêÊëË]} $chunk {e} chunk
	regsub -all {[íÍìÌîÎïÏ]} $chunk {i} chunk
	regsub -all {[ñÑ]} $chunk {n} chunk
	regsub -all {[óÓòÒôÔõÕøØöÖ]} $chunk {o} chunk
	regsub -all {[úÚùÙûÛüÜ]} $chunk {u} chunk
	regsub -all {[ÿŸ]} $chunk {y} chunk
	regsub -all {[æÆäÄ]} $chunk {ae} chunk
	regsub -all {[œŒ]} $chunk {oe} chunk
	
	regsub -all {[^A-Za-z]} $chunk {} chunk
	return [string tolower $chunk]
    }

    # This proc formats the output, before writing it to the console:
    # This one is very simple: break the text into lines (according
    # to global variables leftFillColumn' and 'fillColumn'); then
    # insert a couple of spaces at the beginning of each line...
    proc formatOutput { linje } {
	#pick up any basic html-like markup:
	regsub -all -nocase {<br>} $linje "\t" linje; #below we turn \t into \r
	regsub -all -nocase {<p>} $linje "\t\t" linje; #below we turn \t into \r
	#kill all other html-like markup:
	regsub -all {<[^<>]*>} $linje "" linje
	#next line is an attempt to do some primitive formatting
	set lineList [split $linje \t]
	set pL [list ]
	foreach p $lineList {
	    lappend pL [breakIntoLines $p]
	}
	set linje [join $pL \r]
	regsub -all \r $linje "\r  " linje
	return $linje
    }

    namespace export normalForm formatOutput
}

# ====================================================================
# ====================================================================
# 
# Initialisation of dictionaries
# 
# ====================================================================
# ====================================================================
# Create namespace for the dictionary (inside ::Dico), source the dictionary
# specific procs from the boot sector of the data file; place them in the 
# namespace; initialise a couple of global variables.
# If there are no specific procs given in the data file (or if they do not
# compile properly), generic fallback procs are put into the namespace instead.
# (Warnings are issued then, unless silent=1.)

# There is special support for creating a cache of the Tcl-commands dictionary
set ::Dico::cacheTclCommandsIndex 1

proc Dico::initDictionary { dic {silent 0} } {
    
    # The initialisation should also reset the console attributes, so
    # that the newly initialised dictionary is completely fresh.
    ::console::destroy "* $dic *"
    # (This will also kill the console if it is open.)

    # Special treatment of Tcl-commands dictionary:
    if { $dic == "Tcl-commands" && $::Dico::cacheTclCommandsIndex } {
	if { [catch { buildTclCommandsDictionaryCache }] } {
	    if { !$silent } {
		alertnote "There was a problem caching index for \"Tcl-commands\""
	    }
	    return
	}
    }
    
    variable path
    set f [open [set path($dic)] r]
    # Determine the encoding:
    namespace eval ::Dico::$dic { variable encoding "macRoman" }
    gets $f firstLine
    seek $f 0
    regexp {encoding=\"(\S*)\"} $firstLine -> ::Dico::${dic}::encoding
        
    fconfigure $f -encoding [set ::Dico::${dic}::encoding]
    
    #boot the dictionary
    namespace eval ${dic} {
	set offSet 0; #later we'll overwrite with the good offSet if it exists...
    }
    set i 0
    set problems 1
    while { $i < 400 } {
	gets $f junk
	if { [regexp -- {<!-- BEGIN TCL} $junk] } {
	    break
	}
	incr i
    }
    while { $i < 400 } {
	gets $f linje
	if { [regexp -- {END TCL -->} $linje ] } {
	    set problems 0
	    # we are now at the offset of the file, 
	    # except possibly for some blank lines:
	    set ${dic}::offSet [tell $f]
	    while {[gets $f linje] != -1 && [string trim $linje] == ""} {
		set ${dic}::offSet [tell $f]
		# Note that the offSet is measured in bytes, not in chars
	    }
	    break
	}
	append ${dic}::code $linje \n
	incr i
    }
    close $f
    
    if { $problems } {
	if { !$silent } {
	    alertnote "No TCL code found. We will proceed with generic fallback procedures. This will probably work allright, but you should consider writing the proper procs."
	}
    } else {
	namespace eval $dic {
	    if { [catch {eval $code} err] } {
		# Only one error message from 'man' dictionary is taken seriously:
		if { $err == "No man" } {
		    alertnote "Can't use this dictionary since \[exec man\] doesn't work"
		    error $err
		} else {
		    # Other errors are ignored...
		    alertnote "Bad TCL code in boot sector. We will proceed with generic fallback procedures."
		}
	    }
	}
	# Now we have sourced the procs, and also the offSet
    }
    
    # import fallback procs for those procs not yet defined:
    namespace eval $dic {
	set procList [info proc]
	if { [lsearch -exact $procList "normalForm"] < 0 } {
	    namespace import ::Dico::fallback::normalForm
	}
	if { [lsearch -exact $procList "formatOutput"] < 0 } {
	    namespace import ::Dico::fallback::formatOutput
	}
	
	variable lastPos 0
	variable historyList
	histlist create historyList $::Dico::gvars(historyDepth)
    }
    
    if { ![::console::exists "* $dic *"] } {
	# This means that the dictionary itself did not create any
	# dictionary console with special attributes (most dictionaries
	# don't), so we just make a console with standard attributes:
	computeDefaultAttributes $dic
	# This includes creating the console with [console::create].
    }

    status::msg "Dictionary \"$dic\" initialised"
}


# ====================================================================
# ====================================================================
# 
# Install dictionaries
# 
# ====================================================================
# ====================================================================
# Locate the dictionary file and associate a variable name with it.
# This data is recorded in the Dico::path array.  
# The dictionary is then initialised and made current.
proc Dico::installDictionary { {dic ""} } {
    variable path
    ### get the path of the dictionary: ###
    set thisPath [getfile]
    ### find a name for the dictionary: ###
    if { $dic == "" } {
	regsub -all {[:/ \)\(]} [file tail $thisPath] "" suggestedName
	
	if { [catch {set dic [::dialog::make \
	  [list ""\
	  [list text "Choose a name for the dictionary. 
	    (Use only letters, numbers, underscore, hyphen...  
	    (No spaces, no parentheses...))" ]\
	  [list var "" "$suggestedName"]\
	  ] ] } ] } {
	    return
	}
    }
    ### Check that the name is good enough, ###
    ### and if it isn't: find a new name:   ###
    while { [regexp -- {[:/ \(\)]} $dic ] || \
      [info exists ::Dico::path($dic)] } {
	if { [catch {set dic [::dialog::make \
	  [list ""\
	  [list text "Bad name for the dictionary.
	    Choose another name.
	    (No spaces, no parentheses...)" ]\
	  [list var "" "$suggestedName"]\
	  ] ] } ] } {
	    return
	}
    }
    ### So now we have a valid name and a valid path ---
    ### nothing else can go wrong...
    set path($dic) $thisPath
    prefs::modified ::Dico::path($dic)
    if { [catch { initDictionary $dic } err] } {
	uninstallDictionary $dic
	return
    }
    variable current $dic
    # Lookup something in any case:
    consultDictionary
}



# Remove the dictionary's name from the array of paths
# (and also forget its console attributes)
proc Dico::uninstallDictionary { {dic ""} } {
    variable path
    variable current
    if { $dic == "" } {
	if { [catch {set dic [listpick [lsort -dictionary [array names path]]]}] } {
	    return
	}
    }
    
    unset path($dic)
    prefs::modified ::Dico::path
    ::console::destroy "* $dic *"
    status::msg "Dictionary $dic uninstalled"
    catch { namespace delete $dic } ;# we might arrive here as a result
				     # of a unsuccessful init --- in this case
				     # the namespace doesn't yet exist.
    
    if { [llength [array names path]] <= 0 } {
	alertnote "You\'ve uninstalled the last dictionary!  The programme won't work without any dictionaries installed..."
	catch { killWindow -w "* Dictionary Console *" }
	return
    }
    if { $dic == $current } {
	alertnote "\"$dic\" was \"current\" dictionary. Please choose new \"current\"."
	if { [catch {changeDictionary}] } {
	    # The user cancels the choice!  But we do need a "current"...
	    changeDictionary [lindex [array names path] 0]
	    alertnote "The programme made a choice for you: \"$current\" is new current!"
	}
    }
}


# Open the data file (read-only) at the position of current word
proc Dico::editDict {} {
    set dic [frontmostDict]
    edit -c -r -w [set ::Dico::path($dic)]
    goto [pos::math [minPos] + [set ::Dico::${dic}::lastPos]]
    endLineSelect
}


# ====================================================================
# ====================================================================
# 
# Lookup procs
# 
# ====================================================================
# ====================================================================
# General remarks
# ---------------
# There are three ways to get an article from a dictionary: 
#   (A) looking it up alphabetically 'from scratch'
#             proc: [consultDictionary]
#   (B) reading the next or previous article
#             proc: [neighbourEntry]
#   (C) rereading some article we already read, using history
#             proc: [histLook]
# (The history only records genuine A-lookups.)
# 
# Each of these three procs faces the problem of determining the appropriate
# dictionary to use.  This will generally be $current, but if there is another
# dictionary console topmost, this one will be used instead.  There is a proc
# [frontmostDict] which takes care of this decision.
# 
# Each of these three procs finishes by calling [writeToConsole], which is the
# only proc that writes to any window, and which takes care of writing to the
# correct console, headword colouring, and backgrounding.
# 
# [writeToConsole] takes no arguments.  It reads from the global array 
# ::Dico::thisLookup which as these entries:
#     ::Dico::thisLookup(dic)
#     ::Dico::thisLookup(key)
#     ::Dico::thisLookup(res)
# It is up to the callers [consultDictionary], [neighbourEntry], [histLook]
# to set the value of these entried before calling [writeToConsole].



# --------------------------------------
# Get the word under the cursor, if there is one.  
# (Otherwise propose a random word...)
proc Dico::whatToLookUp { } {
    set key ""
    # is there an open window?:
    if { ![catch {set pos [getPos]}] } { 
	if { [isSelection] } {
	    set key [getSelect]
	} else {
	    backwardWord 
	    set p0 [getPos]
	    forwardWord
	    set p1 [getPos]
	    set key [getText $p0 $p1]
	    goto $pos
	}
	# we don't want initial whitespace:
	set key [string trimleft $key]
	# We only want upto the first linebreak:
	regexp {[^\r\n]+} $key key 
	# (We keep all other whitespace since for some 
	# dictionaries this is a part of the sorting...)
    }
    # if there is nothing to look up, look up at random:
    if { $key == "" } {
	set key [randomWord]
    }
    return $key
}

# --------------------------------------
# Find out which dictionary to use.  If the frontmost window is a 
# dictionary console, then use that one.  Otherwise use Dico::current
proc Dico::frontmostDict {} {
    if { $::Dico::commonConsole } {
	return $::Dico::current
    }
    # If a dictionary console is frontmost, use that one:
    if { [llength [winNames]] &&
      [win::infoExists [win::Current] bindtags] &&
      [lcontain [win::getInfo [win::Current] bindtags] "Dico"] } {
        regexp {\* (.*) \*} [win::Current] -> dic
	return $dic
    } else {
	return $::Dico::current
    }
}




# --------------------------------------
# Main proc for consulting dictionary.  Lookup the word under the cursor.
# (The actual looking up is done by [lookUp].)
proc Dico::consultDictionary { {key ""} } {
    consultSpecificDictionary [frontmostDict] $key
}

proc Dico::consultSpecificDictionary { dic {key ""} } {
    variable backgroundConsole
    variable thisLookup
    
    # What to look up?
    if { $key == "" } {
	set key [whatToLookUp]
    }
    
    # Set the value of the entries in the global array read by [writeToConsole]:
    set thisLookup(dic) $dic
    set thisLookup(key) $key
    # Get the result from the lookup proc:
    set thisLookup(res) [lookup $thisLookup(key) $thisLookup(dic)]

    writeToConsole ;# using the values of the array thisLookup
}




# --------------------------------------
# This proc takes its 'input' from the global array Dico::thisLookup.
# The caller (currently [consultDictionary], [histLookup], [neighbourEntry])
# must set the values correctly before calling.
# 
# Find out what console it should write to, and create the console if it 
# doesn't already exit.  Set the headword colouring if present.  Put the
# console to front or not depending of pref $backgroundConsole.
proc Dico::writeToConsole {} {
    variable thisLookup
    variable gvars
    set dic $thisLookup(dic)
    catch {
	# Colour citations green (if applicable):
	set citeDelims [set ::Dico::${dic}::citeDelims]
	eval regModeKeywords -a -b $citeDelims -c green "Dico" {{}}
    }
    
    variable commonConsole
    variable backgroundConsole
    
    # Find out which console to write in:
    if { $commonConsole } {
	set console "* Dictionary Console *"
    } else {
	set console "* $dic *"
    }
    
    # If the console is not open, open it
    if { ![win::Exists $console ] } {
	::console::open $console
	if { $backgroundConsole } {
	    goto [minPos]
	    swapWithNext
	}
    }
    
    # Finally, write the result to the console:
    replaceText -w $console \
      [minPos] [maxPos -w $console] \
      $thisLookup(key) \r $gvars(sep) \r $thisLookup(res) \r 
    goto -w $console [minPos]
    endLineSelect -w $console
    # And colour all occurrences of the headword (if we know what it is):
    set pos [minPos]
    catch {
	set headword [set ::Dico::${dic}::currentHeadword]
	while 1 {
	    set pair [search -w $console -f 1 -r 0 -i 1 -m 1 -- $headword $pos]
	    foreach {from to} $pair {break}
	    text::color -w $console $from $to "blue"
	    set pos $to
	}	
    }

    if { !$backgroundConsole } {
	set win [win::Current]
	bringToFront $console
	if { $win != $console } {
	    status::msg "Type Ctrl-O again to return to your document"
	}
    }
    
    refresh
}

 
# --------------------------------------
# Puts up listpick dialogue to switch dictionary.
# (It also looks up whatever is under the cursor...)
proc Dico::changeDictionary { {dic ""} } {
    if { $dic == "" } {
	variable path
	if { [catch { set dic [listpick [lsort -dictionary [array names path]]] }] } {
	    status::msg "No dictionary change"
	    return
	}
    }
    variable current $dic
    # rebuild the menu (to get the new dictionary's name in):
    menu::buildSome "localDictionaries"
    # look up something in any case:
    consultSpecificDictionary $dic
}




# HERE IS WHERE THE HARD WORK IS DONE:
# ------------------------------------
# returns the raw text from the relevant line of the dictionary data file
# 
# In fact, this version returns the formatted text, not the raw text...
proc Dico::lookup { key dic } {
    # Just make sure the dictionary file exists:
    variable path
    if { ![file readable $path($dic)] } {
	alertnote "The dictionary \"$dic\" was not found.  Please reinstall it."
	unset path($dic)
	prefs::modified path
	return ""
    }

    set ${dic}::key $key
    set ${dic}::dic $dic
    namespace eval $dic {
	variable offSet
	# ------------------
	# Initialisations
	set key [normalForm $key]

	set ordstrom [open [set ::Dico::path($dic)] r]
	fconfigure $ordstrom -encoding $encoding
	
	set lowerlimit $offSet
	
	seek $ordstrom 0 end
	set upperlimit [tell $ordstrom]
	
	# ------------------
	# Rough binary search, to narrow the interval:
	while { [expr {$upperlimit - $lowerlimit >= 200}] } {
	    set midte [expr {($upperlimit + $lowerlimit) / 2}] 
	    seek $ordstrom $midte
	    gets $ordstrom linje ; #first chunk is junk
	    gets $ordstrom linje
	    if { [string compare $key [normalForm $linje]] == 1 } {
		set lowerlimit $midte
	    } else {
		set upperlimit $midte
	    }
	}
	
	# ------------------
	# So now the goal is within the narrow interval.
	# (In very unlucky cases the goal may actually be a litte after the 
	# interval, but this doesn't matter because we:
	# Go back a little further and read forward linearly:
	if { $lowerlimit > [expr {$offSet + 200}] } {
	    seek $ordstrom [expr {$lowerlimit - 200}]
	    gets $ordstrom linje ; #first chunk is junk
	} else {
	    seek $ordstrom $offSet
	}
	set preSpot [tell $ordstrom] ; # position before the line
	gets $ordstrom linje 
	while { [string compare $key [normalForm $linje]] == 1 } {
	    set preSpot [tell $ordstrom] ; # position before the line
	    if { [gets $ordstrom linje] == -1 } {
		break
	    }
	}
	close $ordstrom
	
	# ------------------
	# Update the history list.
	set entry [list $preSpot $key]
	variable historyList
	histlist update historyList $entry
	histlist back historyList
	variable lastPos $preSpot
	
	# ------------------
	# Return the result.
	return [formatOutput $linje]
    }
}



# --------------------------------------
proc Dico::histLook { dir } { 
    set dic [frontmostDict]
    set ${dic}::dic $dic
    set ${dic}::dir $dir
    namespace eval ${dic} {
	set entry [histlist $dir historyList]
	if { ![string length $entry] } {
	    # Special cases at the ends of the history list:
	    # We don't want to repeat the end points, so if we get 
	    # outside the range we quickly get back in...:
	    if { $dir == "back" } {
		histlist forth historyList
	    } elseif { $dir == "forth" } {
		histlist back historyList
	    }
	    status::msg "History exhausted"
	    return
	}
	set pos [lindex $entry 0]
	set ::Dico::thisLookup(key) [lindex $entry 1]
	set ordstrom [open [set ::Dico::path($dic)] r]
	fconfigure $ordstrom -encoding $encoding
	seek $ordstrom $pos
	variable lastPos $pos
	gets $ordstrom linje

	set ::Dico::thisLookup(res) [formatOutput $linje]
	set ::Dico::thisLookup(dic) $dic
    }
    writeToConsole ;# using the values of the array thisLookup
}

proc Dico::histLookBack { } { histLook "back" }
proc Dico::histLookForth { } { histLook "forth" }

# --------------------------------------
proc Dico::neighbourEntry { direction } {
    set dic [frontmostDict]
    set ${dic}::direction $direction
    namespace eval $dic {
	global lastPos
	set ordstrom [open [set ::Dico::path($dic)] r]
	fconfigure $ordstrom -encoding $encoding
	seek $ordstrom $lastPos
	if { $direction == "prev" } {
	    if { $lastPos == $offSet } {
		status::msg "This is the first entry of the dictionary"
		return
	    } else {  
		backgets $ordstrom linje
		set lastPos [tell $ordstrom] ; # pos before line
	    } 
	} elseif { $direction == "next" } {
	    gets $ordstrom linje ; # first chunk is old stuff
	    set lastPos [tell $ordstrom] ; # pos before line
	    gets $ordstrom linje 
	} else {
	    return
	}
	close $ordstrom
	
	set ::Dico::thisLookup(dic) $dic
	set ::Dico::thisLookup(key) [normalForm $linje]
	set ::Dico::thisLookup(res) [formatOutput $linje]
    }    
    writeToConsole ;# using the values of the array thisLookup
}

proc Dico::nextEntry { } { neighbourEntry "next" }
proc Dico::prevEntry { } { neighbourEntry "prev" }




# ====================================================================
# ====================================================================
# 
# Console attributes
# 
# ====================================================================
# ====================================================================
proc Dico::computeDefaultAttributes { {name ""} } {
    if { [string length $name] } {
	set console "* $name *"
    } else {
	set console "* Dictionary Console *"
    }
    set consoleWidth 503
    set consoleHeight 254
    global tcl_platform
    if { $tcl_platform(platform) == "macintosh" } {
	# Correct for window borders:
	set leftOffset [expr {$::screenWidth - $consoleWidth - 7}]
	set topOffset [expr {$::screenHeight - $consoleHeight - 6}]
    } else {
	set leftOffset [expr {$::screenWidth - $consoleWidth}]
	set topOffset [expr {$::screenHeight - $consoleHeight}]
    }
    # (Here we assume statusbar at top.  When we actually open the
    # window we check where the statusbar is and adjust correspondingly...)

    global DicomodeVars
    ::console::create $console -mode Text -minormode "dictionary" \
      -font Monaco -fontsize $DicomodeVars(fontSize) \
      -g $leftOffset $topOffset $consoleWidth $consoleHeight
}



proc Dico::resetConsoleGeometry {} {
    if { $::Dico::commonConsole } {
	set console "* Dictionary Console *"
    } else {
	set console [frontmostDict]
# 	set ::Dico::current $dic
    }
    ::console::reset $console
}


# ====================================================================
# ====================================================================
# 
# Navigation procs, key press, key bindings
# 
# ====================================================================
# ====================================================================

proc Dico::OptionTitlebar {} {
    variable path
    return [lsort -dictionary [array names path]]
}

proc Dico::OptionTitlebarSelect {item} {
    changeDictionary  $item
}

proc Dico::DblClick {from to shift option control} {
    if {$shift != "0" || $option != "0" || $control != "0"} {
	changeDictionary
    } else {
	consultDictionary
    }
}

proc Dico::carriageReturn {} {
    # If we are on the input line of the console, take the whole
    # line as key.  Otherwise, just let [consultDictionary]
    # determine the key in the standard word-beneath-the-cursor way
    set key ""
    if { [pos::compare [lineStart [getPos]] == [minPos]] } { 
	goto [minPos]
	endOfLine 
	set key [getText [minPos] [getPos]]
    }
    consultDictionary $key
}

# If not on the input line, go there before deleting
proc Dico::backspace {} {
    global mode
    if { $mode == "Dico" &&
      [pos::compare [pos::lineStart [getPos]] != [minPos]] } {
	selectText [minPos] [pos::lineEnd [minPos]]
    }
    ::backSpace    
}

# # Switch between input field and output field.  This is rather superfluous
# # and it is gradually being phased out in favour of headword navigation...
# proc Dico::oldtab {} {
#     if { [pos::compare [lineStart [getPos]] == [minPos]] } { 
# 	::Dico::downWord
#     } else {      
# 	goto [minPos]
# 	endLineSelect
#     }
# }


# Tab works like this in the dictionary console: go to the next 
# occurrence of the current headword (inside the same article).
proc Dico::tab {} {
    set dic [frontmostDict]
    if { ![info exists ::Dico::${dic}::currentHeadword] } {
	status::msg "This dictionary does not yet support headword navigation"
	oldtab
	return
    }
    set currentHeadword [set ::Dico::${dic}::currentHeadword]
    if { ![catch {search -f 1 -r 0 -i 1 -m 1 -- $currentHeadword [selEnd]} found] } {
# 	placeBookmark
	eval selectText $found
    } else {
	status::msg "No more occurrences of \"$currentHeadword\""
    }
}



# Space works like this: if we are on the first line (the input line)
# and there is no selection then it just inserts a space.  In all other
# cases it works like a pager.  (Shift space is 'page back'.)
proc Dico::space { direction } {
    if { [pos::compare [lineStart [getPos]] == [minPos]] \
      && ![isSelection] } { 
	insertText " "
    } else {      
	page$direction
	if { [getPos] == [minPos] } {
	    # If we are back at the input line, select to make 
	    # ready for new lookup:
	    endLineSelect
	}
    }
}



# If backgroundConsole is turned on, it is funny to bind the following
# proc to <space>:  Then ALL words are looked up in the background as you 
# type...
proc Dico::spaceLookup {} {
    typeText " "
    consultDictionary
}


# Quick Lookup mechanism:  While in the Dictionary Console, look up
# words as soon a a character is typed.  This behaviour is controlled
# by the $useQuickLookup preference flag.
# 
# This proc is called by [characterInsertedHook]
proc Dico::quickLookup { win pos char } {
    variable useQuickLookup
    if { [pos::compare [pos::lineStart $pos] != [minPos]]} {
	# The character was typed outside the input field.
	# Put it back in the input field where it belongs:
	if { [string length $char] } {
	    # This means it was not a backspace char...  Delete the char
	    # again. (Can't use backspace here because it would trigger 
	    # the interceptor!)
	    replaceText -w $win [pos::math $pos -1] $pos ""
	}
	replaceText [minPos] [pos::lineEnd [minPos]] $char
	set pos [pos::math [minPos] + [string length $char]]
	goto $pos  
    }
    if { $useQuickLookup && [pos::compare $pos > [minPos]] } {
	set key [getText [minPos] [pos::lineEnd [minPos]]]
	consultDictionary $key
	goto $pos
    }
}

# ------------------- Navigation procs ------------------- #
proc Dico::nextWord { } {
    if { [pos::compare [lineStart [getPos]] == [minPos]] && \
      [pos::compare [pos::lineEnd [getPos]] != [getPos]] } { 
	forwardChar
    } else {
	hiliteWord
    }
}

proc Dico::prevWord { } {
    if { [pos::compare [lineStart [getPos]] == [minPos]] } { 
# 	if { [pos::compare [getPos] == [minPos]] } {
# 	    return
# 	}
	backwardChar
    } else {
	backwardWord
	hiliteWord
    }
}

proc Dico::downWord { } {
    goto [getPos]   
    if { [pos::compare [lineStart [getPos]] == [minPos]] } { 
	nextLine ; # this is to jump over the separatorline
    }
    nextLine
    if { [regexp {[a-zA-Z]+} [getText [getPos] [nextLineStart [getPos]]]] } {
	::Dico::nextWord
    } else {
	if { [regexp {[a-zA-Z]+} [getText [lineStart [getPos]] [getPos]]] } { 
	    # there is a previous word on this line we can take:
	    ::Dico::prevWord
	} else {
	    # the line is empty so we go forward:
	    ::Dico::nextWord
	}
    }
}

proc Dico::upWord { } {
    if { [pos::compare [lineStart [getPos]] == [minPos]] } { 
	::Dico::prevWord
	return
    }
    goto [getPos]
    previousLine
    if { [regexp {[a-z]+} [getText [getPos] [nextLineStart [getPos]]]] } {
	::Dico::nextWord
    } else {
	::Dico::prevWord
    }
}


# ====================================================================
# ====================================================================
# 
# Tools
# 
# ====================================================================
# ====================================================================

# This proc runs through the dictionary file, and whenever it encounters a
# word pair which is out of order, it prints the pair to a log window.
proc Dico::checkSorting { {dic ""} } {
    variable path
    if { $dic == "" } {
	set dic [listpick [lsort -dictionary [array names path]]]
    }
    status::msg "Checking the sorting of $dic"
    
    set ${dic}::dic $dic
    namespace eval $dic {
	set orderOK 1
	# get to work:
	set ordstrom [open [set ::Dico::path($dic)] r]
	fconfigure $ordstrom -encoding $encoding
	catch { seek $ordstrom $offSet }
	gets $ordstrom linje
	set prevOrd [normalForm $linje]
	while { [gets $ordstrom linje] > 0 } {
	    set ord [normalForm $linje]
	    if { [string compare $prevOrd $ord] == 1} {
		if { $orderOK } {
		    new -n "${dic}-disorder"
		    insertText "The following word pairs infract the order:\r"
		    insertText "${::Dico::gvars(sep)}\r"
		}
		insertText "$prevOrd    ${ord}\r"
		set orderOK 0
	    }
	    set prevOrd $ord
	}
	close $ordstrom
	if { $orderOK } {
	    alertnote "Dictionary $dic is consistently sorted"
	}
    }
}


# This proc sorts the dictionary file, according to the sort criterion
# specified in the boot sector, (or otherwise according to the fallback 
# sort criterion).  A new file is created with extension .sorted (next 
# to the original file).
proc Dico::sortFile { {dic ""} } {
    variable path
    if { $dic == "" } {
	set dic [listpick [lsort -dictionary [array names path]]]
    }

    status::msg "Sorting the dictionary file.  New file will be created."
    
    set ${dic}::dic $dic
    namespace eval $dic {
	if { $encoding eq "utf-8" } {
	    alertnote "The proc 'Dico::sortFile' doesn't support unicode yet." \
	      "(The preamble would be scrambled because the offSet is measured \
		in bytes while reading the preamble measures in chars...)"
	    return
	}
	
	# get to work:
	set filePath [set ::Dico::path($dic)]
	set newFilePath ${filePath}.sorted
	set ordstrom [open $filePath r]
	fconfigure $ordstrom -encoding $encoding
	set nystrom [open $newFilePath a]
	fconfigure $nystrom -encoding $encoding

	#copy over the preamble
	if {![catch {set preamble [read $ordstrom $offSet]}]} {
	    puts -nonewline $nystrom $preamble
	}
	#so now the seek position is at offSet and the sorting can begin
	set everything [read -nonewline $ordstrom]
	close $ordstrom
	set lineList [split $everything "\n\r"]
	
	proc compareProc { one two } { 
	    return [string compare [normalForm $one] [normalForm $two]]
	}

	# THE SORTING IS PERFORMED BY THE FOLLOWING LINE
	set sortedLineList [lsort -command ::Dico::${dic}::compareProc $lineList]
	
	set everythingSorted [join $sortedLineList "\r"]
	puts $nystrom $everythingSorted
	close $nystrom
	alertnote "Dictionary sorted.  Written to new file ${dic}.sorted"
    }
}




# ====================================================================
# ====================================================================
# 
# Auxiliary procs
# 
# ====================================================================
# ====================================================================

# --------------------------------------
# Construct a random integer in the range [min,max[
proc randomInt { min max } {
    set n [expr {rand()*($max-$min)}]
    set n [expr {floor($n+$min)}]
    regsub -- {\.0} $n "" n
    return $n
}

# --------------------------------------
# Construct a random word (of length $len)
proc randomWord { {len ""} } {
    if { $len == "" } {
	set len [randomInt 3 8]
    }
    set alphabet "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    while { $len > 0 } {
	set i [randomInt 0 52]
	append word [string index $alphabet $i] 
	incr len -1
    }
    return $word
}



# ==========================================================================
# The proc backgets works just like gets, but reading backwards.
# It sets the insertion point before what it just read, to be ready to 
# continue reading backwards.
# 
# stream is the name of an open stream
# if the argument rec is given, that variable will receive the line preceeding 
# the current insertion point, and the procedure will return a number which is
# the length of the returned string (the string never contains any newline, 
# neither in the beginning nor at the end of the string).  If the argument rec 
# is not given, the return will be of the text chunk found.  If the insertion 
# point is zero (so there is nothing earlier left to read), an empty string is 
# returned in rec, and the value -1.  The new insertion point will be just 
# before the text chunk.
# ==========================================================================
proc backgets { stream {rec ""} } {
    if {$rec != ""} {
	upvar $rec linje
    }
    
    set theSpot [tell $stream]
    if { $theSpot == 0 } {
	set linje ""
	set size -1
    } else {
	
	# first project: find a line start somewhere strictly before $theSpot:
	set newStart $theSpot
	set newSpot $theSpot
	while { $newSpot >= $theSpot } {
	    #go back 100 bytes
	    set newStart [expr {$newStart - 100}]
	    if { $newStart > 0 } {
		seek $stream $newStart
		gets $stream dummy ; #first chunk is junk
		set newSpot [tell $stream]
	    } else {
		set newSpot 0
	    } 
	}
	#so now $newSpot is a linestart position strictly before $theSpot
	
	# second project: see if there is a later one, strictly before $theSpot:
	while { $newSpot < $theSpot } {
	    set goodSpot $newSpot
	    seek $stream $newSpot
	    gets $stream linje
	    set newSpot [tell $stream] ; # line start position
	}
	#so now $goodSpot is the last linestart position strictly before $theSpot
	#and $linje contains the text we want (perhaps too much)
	
	seek $stream $goodSpot
	if { $newSpot == $theSpot } {
	    set size [expr {$theSpot - $goodSpot - 1}] ; #this is the size in case the
	    #original spot was after newline
	} elseif { $newSpot > $theSpot } {
	    set size [expr {$theSpot - $goodSpot}] ; #this is the real size in case the
	    #original spot was not after newline
	    set linje [string range $linje 0 [expr {$size -1}]] 
	}
    }
    
    if {$rec != ""} {
	return $size
    } else {
	return $linje
    }
    
}



# This procedure updates the index file for the dictionary 'Tcl-commands',
# located in the Examples folder.  This index refers to the file 'Tcl 8.4
# Commands.txt' in the Help folder.  The new index is placed in the Cache
# folder in AlphaPrefs.  (There are two reasons for not just overwriting
# the original file 'Tcl-commands': one reason is that Alpha is supposed to
# be able to run from a read-only installation, and the second reason is that
# updating files locally creates confusion with CVS...
# 
# The proc copies the preamble from the original file 'Tcl-commands', and
# creates the index by scanning 'Tcl 8.4 Commands.txt'.  If the cached
# index is newer than 'Tcl 8.4 Commands.txt', nothing happens.  To force
# rebuilding the index file in this situation, simply delete the cached
# file.

proc Dico::buildTclCommandsDictionaryCache {} {
    variable path
    global HOME PREFS
    set examplePath [help::pathToExample [file join Dictionary-Examples Tcl-commands]]
    set tclFilePath [help::pathToHelp [file join {Tcl 8.4 Commands.txt}]]
    set cachePath [file join $PREFS Cache Tcl-commands-dico-index]
    # Check if the cache file is already valid:
    if { $path(Tcl-commands) == $cachePath \
      && [file readable $cachePath] \
      && [file mtime $cachePath] < [file mtime $tclFilePath] } {
	return
    }
    # Give a message:
    status::msg "Updating \"Tcl-commands\" index"
    # Get the preamble from the example file:
    set exFile [open $examplePath r]
    fconfigure $exFile -encoding macRoman
    gets $exFile linje
    while { ![regexp -- {END TCL -->} $linje] } {
	append preamble $linje \n
	gets $exFile linje
    }
    append preamble $linje \n\n
    close $exFile
    # Open the cache file for writing
    set newFile [open $cachePath w]
    fconfigure $newFile -encoding macRoman
    puts -nonewline $newFile $preamble
    set ordstrom [open $tclFilePath r]
    fconfigure $ordstrom -encoding macRoman
    
    #### Scan the 'Tcl 8.4 Commands.txt' file ####
    set pos 0 
    # run forward until we find "NAME":
    while { [gets $ordstrom linje] != -1 } { 
	if { [regexp "^NAME" $linje] } {
	    # now we found "NAME", so now p0 has the right value
	    gets $ordstrom linje
	    # this is the line with the entry
	    regexp {(\m\w+\M)\s} $linje dummy entry
	    # run forward until we find "KEYWORDS":
	    while { [gets $ordstrom linje] != -1 } {
		if { [regexp "^KEYWORDS" $linje ] } { 
		    # run forward until we find a blank line:
		    while { [gets $ordstrom linje] != -1 } {
			set linje [string trim $linje]
			if { [ string length $linje ] == 0 } {
			    break
			}
		    }
		    break
		}
	    }
	    # so now we have just read the blank line
	    # (or perhaps we came to the end of the file)
	    set size [ expr [tell $ordstrom] - $pos]
	    puts $newFile "$entry $pos $size"
	    
	}
	# record the position:
	set pos [tell $ordstrom]
	# and run again
    }
    
    close $ordstrom
    close $newFile
    set path(Tcl-commands) $cachePath
    status::msg "Dictionary \"Tcl-commands\" cached and initialised"

}

