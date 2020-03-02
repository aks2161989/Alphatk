## -*-Tcl-*- (install)
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "superSearch.tcl"
 #                                    created: 10/01/1997 {08:39:08 pm} 
 #                                last update: 2006-04-19 23:36:33 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Distributable under Tcl-style (free) license.
 # 
 # Thanks for: 
 # 
 # Package modified on 5/7/99 by Dominique d'Humieres
 # E-mail: <dominiq@physique.ens.fr>
 # following ideas from Pierre Basso (3/07/98)
 # E-mail: <basso@lim.univ-mrs.fr>
 # 
 # ###################################################################
 ##

# extension declaration
alpha::feature supersearch 1.8.8 global-only {
    set supersearchOn 0
    # supersearch array elements:
    # 
    # f - 1 = search from current pos, 0 = from start of window
    # i - case insensitive?
    # m - word match?
    # r - regexp?
    # linestop -
    # lineanchor - 
    # b - batch?
    # multi - more than one file?
    array set supersearch {
	f 1 i 1 m 0 r 0 linestop 1 lineanchor 1 b 0 multi 0 
	multifsets "" ismultifset 0 inselection 0 pattern "" 
	ignorespace 0 casereplace 0 notInComments 0 exclude 0
    }
    # This setting is persistent - saved in user's prefs
    if {![info exists supersearch(circular)]} {
	set supersearch(circular) 1 
    }
    namespace eval supersearch {}
} {
    set supersearchOn 1
    supersearch::onoff
} {
    set supersearchOn 0
    supersearch::onoff
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Implements search and replace commands in the Search menu
} help {
    Alpha has a full repertoire of searching commands.  This package
    implements Alpha's 'Find' dialog, as well as several other items in the
    "Search" menu.  It allows single / multi-file / regexp / batch /
    word-match / search / replace / replace-all / in-selection (whew!) 
    operations from the same dialog box.
    
    "# The 'Find' Dialog"
    "# Supersearch Preferences"
    "# Additional Search Packages"
    

	  	The 'Find' Dialog

    The 'Find' menu item in the Search menu brings up a dialog <<find>>
    allowing the search and replacement text to be specified.  Alpha can
    search the active window, the current selection or a set of files.

    The dialog also has checkboxes for the following options:

	Ignore Case     

    Whether the search should match case ('a' and 'A' are different) 
    or not ('a' and 'A' are the same).
    
	Regexp            

    The search and replace text are interpreted as regular expressions.  See
    documentation for the Tcl command [regexp] or the "Regular Expressions"
    help window for more information.
    
    Note that for searching purposes "\r" and "\n" are treated the same, i.e.
    as a line ending character.  Substitution strings are allowed, i.e.
    "(some regexp) and (more)" in the search string and "\1\2" in the
    replacement string.

    Pressing the "Regexp Help" button will open a <<help::regexpHelpDialog>>
    that provides a quick "cheat sheet" with regexp syntax notes -- if you
    need more details on any of these topics, press the "More Info" button to
    suspend the current search, and open the "Regular Expressions" help file.

	Batch           

    When making a batch search, a list of all matches in the fileset or
    current window are displayed in a new browser window.  A particular match
    can be displayed by moving the cursor to a line in the file of matches
    and hitting "return".

    In the Search menu there is also a very useful command 'Next Match'. 
    Regardless which window is frontmost, it brings the browser window to the
    front, navigate down one line, and goes to the match of that line.  Thus,
    this gives you a quick way to jump to all matches without having to
    manually bring the browser window to the front.
    
    See the "Brws Help" window for more information about browser windows.
    
	Word Match      

    Whether the search should match only complete words or not.
    
	Keep Capitals

    When performing 'Replace' operations, whether the search should
    check the case of the leading character of the string matched, and
    attempt to ensure the replacement has the same case.  This allows
    you to replace 'hello' by 'goodbye' and 'Hello' by 'Goodbye' with
    just one search operation.
    
	Ignore Spaces

    Ignore any differences in whitespace (spaces, tabs, newlines) between
    the search string and the attempted match.
    
	Top window (single file) searches
	
    For searches on just the current window, there are two extra options:
	
	From current pos         

    If set (the default) the search will start at the current insertion 
    point.  Otherwise the search will always start from the beginning of
    the window.  This option has no effect when doing multi-file searches.
	
	Circular

    Once the search reaches the end of the window (or the end of the
    selected range, for 'In Selection' searches), whether to continue
    from the beginning (or, when doing backwards searches, when the
    search reaches the beginning whether to continue searching from the
    end).  This option has no effect when doing multi-file searches.
    
	Not In Comments
    
    Don't match anything in commented out text.  This option has no
    effect when doing multi-file searches.

	In Selection

    Only search within the current selection.  This option has no effect
    when doing multi-file searches.

	Multiple Files      

    To search through all files in a given file set.  Selecting 'Multiple
    Files' from the popup menu allows you to choose one or more existing
    filesets in which to search, or you can quickly create a new fileset
    on the fly (with 'New Fileset'), or search in a directory of your
    choosing (with 'Dir Scan') -- this folder is also saved at the end of
    the menu for future searches.
    
    Read more about filesets in the file "Filesets Help".

	Exclude Matches

    This option to multiple file searches reverses the interpretation of
    the search -- every file which doesn't match the given pattern is
    flagged (and every file which does match is ignored).  This useful
    feature is only meaningful during 'Find' operations and so is ignored
    for 'Replace' operations.

	Patterns

    And finally, Alpha allows a library of useful search and replace texts to
    be defined.  This library is used and edited in the popup menu
    'Patterns'.  Selecting a pattern from the menu inserts the search and
    replace strings in the dialog (in Alpha 8/X you will have to press
    the 'Use Pattern From Menu' button as well).  The popup menu also
    remembers your 10 most recent search patterns from this editing session.
    There are two buttons available:

    'Save This Pattern' creates a new item in the menu from the current search
    and replace strings, prompting you for a name to use in the popup.

    'Forget Pattern' lets you permanently remove a pattern from the popup menu.
    

	  	Supersearch Preferences
		
    The 'Find' dialog includes a button named 'Prefs' -- a new dialog will
    appear allowing you to set preferences associated with this package that
    affect how searches are performed.  
    
    Preferences: supersearch
    
    Here's a description for each of them:
    
	Auto Grep
    
    To add the 'Auto Grep' button to the search dialog, which allows
    quick switching between regexp and non-regexp patterns, turn this
    item on.

	Beep On Failed Search
	
    To beep on a failed search, turn this item on.  To remain silent on
    failed searches, turn this item off.

	Box Heights

    Enter the number of rows of text to make room for in the 'Search For' and
    'Replace With' boxes in the search dialog
    
	Enter Clears Batch

    To clear the batch, multi-file and regexp flags when using shift-cmd-E to
    enter a new search selection, turn this item on.  To leave all flags
    untouched when using shift-cmd-E, turn this item off.

	Number Searcher

    To add the 'Num Search' button to the search dialog, which allows you
    to search for a number in any base (binary, hex, octal, etc), turn
    this item on.

	Separate Search And Current Fileset:

    To remember the current search fileset separately to Alpha's current
    fileset, turn this item on.  To synchronise the search fileset with
    Alpha's current fileset each time you open the search dialog, turn this
    item off.

	Smart In Selection Flag:

    To set the 'in selection' flag automatically if there's a selection of at
    least 80 more characters than the length of the current search string,
    turn this item on.  To leave the 'in selection' flag in its original
    state, turn this item off.

	Undo Off For Replace All:

    To turn Alpha's undo-memory off when doing 'replace all' (for added
    speed), turn this item on.  To remember all changes when doing 'replace
    all', turn this item off.

	Unlock Files During Batch Replacements:

    Unlock locked files when necessary to perform batch replacements.  


	  	Additional Search Packages

    The global "Filters" menu allows for even more complicated search and
    replace functions.  See the "Filters Help" file for more information. 
    Incremental searching is also available, the package: incrementalSearch
    help window provides more information.
}

proc superSearch.tcl {} {}

# Remove these old preferences.
prefs::removeObsolete supersearchmodeVars(quoteFunnyChars)
prefs::removeObsolete supersearchmodeVars(quoteTabsAndNewlines)
prefs::renameOld supersearch(wrap) supersearch(circular)

# Enter the number of rows of text to make room for in the 'Search For' and 
# 'Replace With' boxes in the search dialog
newPref var boxHeights 3 supersearch
# To turn Alpha's undo-memory off when doing 'replace all' (for added
# speed), click this box.||To remember all changes when doing 'replace all',
# click this box.
newPref flag undoOffForReplaceAll 1 supersearch
# To remember the current search fileset separately to Alpha's current
# fileset, click this box.||To synchronise the search fileset
# with Alpha's current fileset each time you open the search dialog, 
# click this box.
newPref flag separateSearchAndCurrentFileset 1 supersearch
# To set the 'in selection' flag automatically if there's a selection of at
# least 80 more characters than the length of the current search string,
# click this box.||To leave the 'in selection' flag in its original state,
# click this box.
newPref flag smartInSelectionFlag 1 supersearch
# To beep on a failed search, click this box.||To remain silent on
# failed searches, click this box.
newPref flag beepOnFailedSearch 1 supersearch 
# Enter the regular expression defining the set of characters for which
# preceding or following spaces are ignored when the 'IgnoreSpaces' is on.
# If the 'regexp' flag is on, the set is replaced by '\r'.
# The set must not contain 'space' or 'tab' characters.
set supersearchmodeVars(checkSpacesAround) "\[^ \\w\t\]"
# Unlock locked files when necessary to perform batch
# replacements||Unlock locked files when necessary to perform batch
# replacements
newPref flag unlockFilesDuringBatchReplacements 0 supersearch 

#menu -n supersearch -p menu::generalProc {search replace+find replaceAll replace}
#float -m supersearch -n "" -z super
namespace eval supersearch {}

# ×××× Plug-in architecture ×××× #

# This is a first-cut at a plug-in architecture for the search dialog.
# The idea is to avoid complicating the basic search code too much, to
# keep it understandable.  The way it works is that any plugin must
# register a 'newPref' as below, and must create an entry in the
# supersearch::plugin array, as a list of four elements: the 'on'
# code, the 'off' code, the code needed to add anything to the dialog
# and finally (if a button was added to the dialog), the code to take action 
# when that button is pressed.  These scripts are evaluated in the context
# of the caller (supersearch::find) and can adjust various variables as
# shown.

# To clear the batch, multi-file and regexp flags when using shift-cmd-E 
# to enter a new search selection, click this box.||To leave all flags
# untouched when using shift-cmd-E, click this box.
newPref flag enterClearsBatch&MultiFlags 1 supersearch supersearch::pluginFlag
# To add the 'Auto Grep' button to the search dialog, which allows
# quick switching between regexp and non-regexp patterns, click
# this box.||To remove the 'Auto Grep' button from the search dialog,
# click this box.
newPref flag autoGrep 1 supersearch supersearch::pluginFlag
# To add the 'Num Search' button to the search dialog, which allows
# you to search for a number in any base (binary, hex, octal, etc),
# click this box.||To remove the 'Num Search' button from the search
# dialog, click this box.
newPref flag numberSearcher 0 supersearch supersearch::pluginFlag

proc supersearch::pluginFlag {var} {
    global supersearchmodeVars
    set on $supersearchmodeVars($var)
    supersearch::executePlugins [expr {1 - $on}] $var 1
}

set supersearch::plugin(enterClearsBatch&MultiFlags) {
    {
	hook::register enterSearchString \
	  "set supersearch(multi) 0 ; set supersearch(b) 0 ; #"
    }
    {
	hook::deregister enterSearchString \
	  "set supersearch(multi) 0 ; set supersearch(b) 0 ; #"
    }
}

set supersearch::plugin(autoGrep) {
    {
	set ::supersearch(isGrepped) 0
	hook::register enterSearchString "set supersearch(isGrepped) 0 ; #"
    }
    {
	unset ::supersearch(isGrepped)
	hook::deregister enterSearchString "set supersearch(isGrepped) 0 ; #"
    }
    {
	set y $yrplug
	if {$supersearch(isGrepped)} {
	    eval lappend args [dialog::button "UnGrep" 445 y]
	    lappend button_help \
	      "Click here to substitute all backslash quoted characters\
	      in your search/replace strings so that the string can be\
	      better used for exact searches."
	} else {
	    eval lappend args [dialog::button "AutoGrep" 445 y]
	    lappend button_help \
	      "Click here to convert an exact string which contains\
	      regexp sensitive characters into a string which may be\
	      easier for you to use in a regexp search."
	}
	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend args -tag autogrep \
	      -action [list ::supersearch::autoGrep {1 3 regexp autogrep}]
	}
	lappend buttons autoGrep
    }
    {
	# This block is never called in Alphatk, because it uses the
	# '-action' option to the button
	if {$supersearch(isGrepped)} {
	    # unGrep
	    searchString [subst -nocommands -novariables [searchString]]
	    replaceString [subst -nocommands -novariables [replaceString]]
	} else {
	    # grep
	    searchString [quote::Regfind [searchString]]
	    replaceString [quote::Regsub [replaceString]]
	}
	set supersearch(isGrepped) [expr {1 - $supersearch(isGrepped)}]
	set supersearch(r) $supersearch(isGrepped)
    }
}

# This proc is only called in Alphatk
proc supersearch::autoGrep {dialogItemIds} {
    global supersearch
    set searchString [getControlValue [lindex $dialogItemIds 0]]
    set replaceString [getControlValue [lindex $dialogItemIds 1]]
    if {$supersearch(isGrepped)} {
	# unGrep
	setControlValue [lindex $dialogItemIds 0] \
	  [subst -nocommands -novariables $searchString]
	setControlValue [lindex $dialogItemIds 1] \
	  [subst -nocommands -novariables $replaceString]
	setControlValue [lindex $dialogItemIds 2] 0
	setControlValue [lindex $dialogItemIds 3] "AutoGrep"
	setControlInfo [lindex $dialogItemIds 3] help \
	  "Click here to convert an exact string which contains\
	  regexp sensitive characters into a string which may be\
	  easier for you to use in a regexp search."
    } else {
	# grep
	setControlValue [lindex $dialogItemIds 0] [quote::Regfind $searchString]
	setControlValue [lindex $dialogItemIds 1] [quote::Regsub $replaceString]
	setControlValue [lindex $dialogItemIds 2] 1
	setControlValue [lindex $dialogItemIds 3] "UnGrep"
	setControlInfo [lindex $dialogItemIds 3] help \
	  "Click here to substitute all backslash quoted characters\
	  in your search/replace strings so that the string can be\
	  better used for exact searches."
    }
    set supersearch(isGrepped) [expr {1 - $supersearch(isGrepped)}]
}

set supersearch::plugin(numberSearcher) {
    {
	set ::supersearch(conversionToAllBases) ""
	hook::register enterSearchString \
	  "set supersearch(conversionToAllBases) {} ; #"
    }
    {
	unset ::supersearch(conversionToAllBases)
	hook::deregister enterSearchString \
	  "set supersearch(conversionToAllBases) {} ; #"
    }
    {
	set y $yrplug
	if {$supersearch(conversionToAllBases) != ""} {
	    eval lappend args [dialog::button "   UnNum   " 345 y]
	} else {
	    eval lappend args [dialog::button " NumSearch " 335 y]
	}
	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend args -tag numSearch \
	      -action [list ::supersearch::numSearcher {1 regexp numSearch}]
	}
	lappend buttons numberSearcher
	lappend button_help \
	  "Click here to search for a number in any base\
	  (hex, binary, octal, decimal)."
    }
    {
	# Not used in Alphatk
	if {$supersearch(conversionToAllBases) != ""} {
	    # unNum
	    searchString $supersearch(conversionToAllBases)
	    set supersearch(conversionToAllBases) ""
	    set supersearch(r) 0
	} else {
	    # create regexp for all representations.
	    if {[catch {set newPat \
	      "([join [supersearch::getNumberInAllBases [searchString]] |])"} err]} {
		alertnote "There was a problem: $err"
	    } else {
		set supersearch(conversionToAllBases) [searchString]
		set supersearch(r) 1
		searchString $newPat
	    }
	}
    }
}

# This proc is only called in Alphatk
proc supersearch::numSearcher {dialogItemIds} {
    global supersearch
    if {$supersearch(conversionToAllBases) != ""} {
	# unNum
	setControlValue [lindex $dialogItemIds 0] $supersearch(conversionToAllBases)
	setControlValue [lindex $dialogItemIds 1] 0
	setControlValue [lindex $dialogItemIds 2] " NumSearch "
	set supersearch(conversionToAllBases) ""
    } else {
	# create regexp for all representations.
	set searchString [getControlValue [lindex $dialogItemIds 0]]
	if {[catch {set newPat \
	  "([join [supersearch::getNumberInAllBases $searchString] |])"} err]} {
	    alertnote "There was a problem: $err"
	} else {
	    set supersearch(conversionToAllBases) $searchString
	    setControlValue [lindex $dialogItemIds 0] $newPat
	    setControlValue [lindex $dialogItemIds 1] 1
	    setControlValue [lindex $dialogItemIds 2] "   UnNum   "
	}
    }
}

proc supersearch::getNumberInAllBases {num} {
    set first [string index $num 0]
    if {$first == "0"} {
	# octal
	set num [expr {$num}]
    } elseif {([string trim [string trim $num] 01] == "") \
      && ([string length $num] > 5)} {
	# binary
	set bin [binary format B* $num]
	binary scan $bin I num
    } elseif {[regexp -nocase {^\\?x?[a-z]+$} $first]} {
	# hex
	set num [expr {$num}]
    } else {
	# decimal
	set num [expr int($num)]
    }
    
    # Return a list of valid representations of the number. We
    # will search for them all by building a regexp to match any
    # of them.
    
    set hex [format %x $num]
    if {$num < 0} {
	set hex "f*[string trimleft $hex f]"
    } 
    
    set oct [format %o $num]
    
    binary scan [binary format I $num] B* bin
    if {$num < 0} {
	set bin "1*[string trimleft $bin 1]"
    } else {
	set bin [string trimleft $bin 0]
    }
    
    set res [list $num $hex $oct $bin]

    # Get char sequence (useful for file type/creators etc)
    if {$num > 256*256*256} {
	set cur $num
	set char ""
	while {$cur > 0} {
	    set char [format %c [expr {$cur % 256}]]${char}
	    set cur [expr {$cur /256}]
	}
	lappend res [quote::Regfind $char]
    }
    
    return $res
}

proc supersearch::executePlugins {index {which ""} {force 0}} {
    global supersearchmodeVars supersearch::plugin
    if {$which == ""} {
	set which [array names supersearch::plugin]
    } else {
	set which [list $which]
    }
    foreach p $which {
	if {$force || \
	  ([info exists supersearchmodeVars($p)] && $supersearchmodeVars($p))} {
	    uplevel 1 [lindex [set supersearch::plugin($p)] $index]
	}
    }
}

supersearch::executePlugins 0

# ×××× On-off toggling ×××× #

proc supersearch::toggle {} {
    global supersearchOn
    set supersearchOn [expr {1 - $supersearchOn}]
    supersearch::onoff
    status::msg "Supersearch switched [expr {$supersearchOn ? {on} : {off}}]"
}
proc supersearch::replaceString {args} {
    global replaceString
    switch -- [llength $args] {
	0 {
	    return $replaceString
	}
	1 {
	    return [set replaceString [lindex $args 0]]
	}
	default {
	    error "Too many args"
	}
    }
}
proc supersearch::searchString {args} {
    global supersearch searchString
    switch -- [llength $args] {
	0 {
	    return $searchString
	}
	1 {
	    set t [lindex $args 0]
	    set supersearch(search) $t
	    supersearch::parseSearch $t
	    return [set searchString $t]
	}
	default {
	    error "Too many args"
	}
    }
}

namespace eval supersearch {
    namespace export find findAgain replace replaceAll\
      replace&FindAgain findInNextFile searchString\
      enterSearchString enterReplaceString findAgainBackward\
      performSearch replaceString searchStart
}

proc supersearch::onoff {} {
    global supersearchOn searchString replaceString

    if {!$supersearchOn} {
	return -code error "Can't turn supersearch off"
    }
    
    # Don't turn on twice.
    if {[info commands ::find] != ""} {return}
    # import all exported commands.
    namespace eval :: {namespace import -force ::supersearch::*}
    # set initial values of search/replace string globals
    if {![info exists searchString]} {
	::searchString ""
    } else {
	::searchString $searchString
    }
    if {![info exists replaceString]} {
	::replaceString ""
    } else {
	::replaceString $replaceString
    }
    # Remember these two preferences.  We do this here so we only
    # remember them if this package is always on.
    prefs::modified searchString replaceString
    
    menu::insert Search items 0 \
      "/F<E<SfindÉ" \
      "/F<S<I<OsearchStart" \
      "/G<E<SfindAgain" \
      "/G<S<I<OfindAgainBackward" \
      "\(/F<B<OfindInNextFile" \
      "/E<E<SenterSearchString" \
      "/E<S<I<OenterReplaceString" \
      "\(-" \
      "/Rreplace" \
      "/J<Oreplace&FindAgain" \
      "/R<E<O<IreplaceAll"
    
    hook::register requireOpenWindowsHook [list Search searchStart] 1
    hook::register requireOpenWindowsHook [list Search findAgain] 1
    hook::register requireOpenWindowsHook [list Search findAgainBackward] 1
    hook::register requireOpenWindowsHook [list Search enterSearchString] 1
    hook::register requireOpenWindowsHook [list Search enterReplaceString] 1
    hook::register requireOpenWindowsHook [list Search replace] 1
    hook::register requireOpenWindowsHook [list Search replace&FindAgain] 1
    hook::register requireOpenWindowsHook [list Search replaceAll] 1
}

# ×××× Search functionality ×××× #

proc supersearch::enterSearchString {args} {
    win::parseArgs w

    global supersearchmodeVars supersearch
    set t [getSelect -w $w]			
    searchString $t			
    set msg "Entered search '$t'"
    set supersearch(r) 0
    if {$supersearch(inselection)} {
	if {[pos::compare -w $w [getPos -w $w] >= $supersearch(start)] \
	  && [pos::compare -w $w [getPos -w $w] <= $supersearch(end)]} {
	    append msg ", still searching in previous selection."
	} else {
	    set supersearch(inselection) 0
	    append msg ", no longer searching in selection."
	}
    }
    hook::callAll enterSearchString
    status::msg [shorten $msg 80 45]
    supersearch::parseSearch
}

proc supersearch::enterReplaceString {args} {
    win::parseArgs w
    set t [getSelect -w $w]
    replaceString $t
    status::msg "Entered replace '$t'"
}

# We need this, otherwise it is possible for the above proc to fail.
set supersearch(start) [minPos]
set supersearch(end) [minPos]

## 
 # -------------------------------------------------------------------------
 # 
 # "supersearch::performSearch" --
 # 
 #  Call this procedure in Tcl code which effectively wants to script
 #  the 'find' dialog, and use the standard procs like 'replaceAll'.
 #  You must use this to ensure flags like multi-file batch replace are
 #  cleared.  Otherwise replaceAll might not have the desired effect.
 #  
 #  Note that, if you are using this procedure followed by things
 #  like 'replace', you almost certainly do not want to use the '-s' flag.
 #  A rule which is probably true 99% of the time is that
 #  
 #  (i) search should use '-s'
 #  (ii) performSearch should not use '-s'
 # 
 #  This procedure is not that well tested.  May still have bugs.
 #  
 # ¥ search  [optionsÉ] <pattern> <pos> - 
 #   -f <num>      - go forward?
 #   -r <num>      - regular expression?
 #   -s            - save previous search string and search flags.
 #   -i <num>      - ignore case?
 #   -m <num>      - match words?
 #   -n            - failed search still returns TCL_OK, but null string.
 #   -l <limit>    - limit on how search goes.
 #   --            - next arg is the pattern.
 #   
 # -------------------------------------------------------------------------
 ##
proc supersearch::performSearch {args} {
    global supersearch
    set opts(-b) 0
    set opts(-r) 0
    set opts(-f) 1
    set opts(-m) 0
    set opts(-i) 0
    set opts(-linestop) 0
    set opts(-lineanchor) 0
    getOpts {-f -r -m -b -i -l -linestop -lineanchor}
    if {[info exists opts(-s)]} {
	set savefrom [searchString]
	array set temp [array get supersearch]
    }
    set supersearch(multi) 0
    set supersearch(b) $opts(-b)
    set supersearch(r) $opts(-r)
    set supersearch(i) $opts(-i)
    set supersearch(m) $opts(-m)
    set supersearch(linestop) $opts(-linestop)
    set supersearch(lineanchor) $opts(-lineanchor)
    set supersearch(beep) [info exists opts(-beep)]
    if {[info exists opts(-l)]} {
	set supersearch(inselection) 1
	if {$opts(-f)} {
	    set supersearch(start) [lindex $args 1]
	    set supersearch(end) $opts(-l)
	} else {
	    set supersearch(start) $opts(-l)
	    set supersearch(end) [lindex $args 1]
	}
    } else {
	set supersearch(inselection) 0
    }
    searchString [lindex $args 0]
    goto [lindex $args 1]
    set res [supersearch::basicSearch $opts(-f)]
    if {[info exists opts(-s)]} {
	array set supersearch [array get temp]
	searchString $savefrom
    }
    unset supersearch(beep)

    if {[llength $res]} {
	return $res
    } else {
	error "Not found"
    }
}

proc supersearch::generalSearch {} {
    global supersearch

    if {$supersearch(b)} {
	supersearch::batchSearch
    } else {
	enableMenuItem Search findInNextFile $supersearch(multi)
	if {$supersearch(multi)} {
	    supersearch::getFiles
	    set supersearch(multiindex) -1
	    supersearch::findNextOkLocation
	    return
	} else {
	    if {$supersearch(inselection)} {
		goto $supersearch(start)
	    } else {
		if {$supersearch(f)} {
		   goto [getPos]
	       } else {
		   goto [minPos]
	       }
	    }
	    supersearch::basicSearch
	}
    }
}

# ×××× Basic searching ×××× #

proc supersearch::searchStart {} {
    global search_start
    selectText [getPos]
    setPin
    if {[catch {goto $search_start}]} {status::msg "No previous search"}
}

# Will return the empty string if nothing was found or else the list
# of start,end position for the match.
proc supersearch::findAgain {} {
    global supersearch
    if {$supersearch(b)} {set supersearch(b) 0}
    supersearch::recentPattern \
      [searchString] [replaceString] $supersearch(r) 0
    supersearch::basicSearch 1
}

proc supersearch::findAgainBackward {} {
    global supersearch
    if {$supersearch(b)} {
	alertnote "You can't do backwards batch searches"
	return
    } else {
	supersearch::recentPattern \
	  [searchString] [replaceString] $supersearch(r) 0
	supersearch::basicSearch 0
    }
}

# Will return the empty string if nothing was found or else the list
# of start,end position for the match.
proc supersearch::basicSearch {{forwards 1} {rfrsh 0}} {
    global supersearch
    
    if {$supersearch(inselection) && !$supersearch(multi)} {
	set pos [getPos]
	set start $supersearch(start)
	set end $supersearch(end)
	set lstart [lindex [pos::toRowChar [lineStart $start]] 0]
	set lend [lindex [pos::toRowChar [nextLineStart $end]] 0]
	status::msg "searching in selection between lines $lstart and $lend"
	if {[pos::compare $pos < $start] || [pos::compare $pos > $end]} {
	    if {$forwards} {
		goto $start
	    } else {
		goto $end
	    }
	} 
    }
    set from $supersearch(reg)
    
    set searchstart [supersearch::searchStart $forwards]
    # While loop to handle finding in comments when we don't
    # want to match comments
    while {1} {
	if {[catch {search -s -f $forwards -r 1 -i $supersearch(i) \
	  -m $supersearch(m) -- $from $searchstart} p]} {
	    return [supersearch::findNextOkLocation $forwards]
	} else {
	    if {$supersearch(inselection) && !$supersearch(multi)} {
		if {$forwards} {
		    if {[pos::compare [lindex $p 0] > $supersearch(end)]} {
			return [supersearch::findNextOkLocation $forwards]
		    }
		} else {
		    if {[pos::compare [lindex $p 0] < $supersearch(start)]} {
			return [supersearch::findNextOkLocation $forwards]
		    }
		}
	    }
	    if {$supersearch(notInComments) \
	      && [text::isInComment [lindex $p 0]]} {
		if {$forwards} {
		    set searchstart [lindex $p 1]
		} else {
		    set searchstart [pos::math [lindex $p 0] - 1]
		}
		continue
	    }
	    
	    goto [lindex $p 0]
	    if {![llength [winNames -f]]} {return}
	    getWinInfo wndw
	    set wndwFrst $wndw(currline)
	    set wndwDsp $wndw(linesdisp)
	    set wndwln [lindex [pos::toRowChar [getPos]] 0]
	    set wndwln \
	      [expr {4*(1-2*$forwards)*($wndwln-$wndwFrst)-(1-4*$forwards)*$wndwDsp}]
	    if {$rfrsh||$wndwln < 0} {centerRedraw}
	    eval selectText $p
	    # Store what we found, and a zero to indicate we did not
	    # just to a replacement
	    set supersearch(lastFindOrReplace) [concat $p [list 0]]
	    return $p
	}
    }
}

proc supersearch::_canMatchEmptyString {} {
    global supersearch
    if {$supersearch(r)} {
	if {$supersearch(i)} {
	    return [regexp -nocase -- $supersearch(reg) ""]
	} else {
	    return [regexp -- $supersearch(reg) ""]
	}
    } else {
	if {[string length [searchString]] == 0} {
	    return 1
	} else {
	    return 0
	}
    }
}

proc supersearch::replace {} {
    global supersearch alpha::platform

    supersearch::recentPattern \
      [searchString] [replaceString] $supersearch(r) 1

    set s [getPos] ; set e [selEnd]
    if {[pos::compare $s != $e] || [_canMatchEmptyString]} {
	if {![win::checkIfWinToEdit]} {
	    return
	} 
	if {$supersearch(r)} {
	    set pattern $supersearch(reg)
	    if {($alpha::platform eq "alpha")} {
		regsub -all "\n" $pattern "\r" pattern
	    }
	    if {$supersearch(i)} {
		set matched [regsub -nocase -- $pattern \
		  [getText $s $e] [replaceString] rep]
	    } else {
		set matched [regsub -- $pattern \
		  [getText $s $e] [replaceString] rep]
	    }
	    if {!$matched} {
		error "Cancelled: The pattern\
		  \"[supersearch::quoteTabNewline [searchString]]\"\
		  didn't match the string\
		  \"[supersearch::quoteTabNewline [getText $s $e]]\""
	    }
	} else {
	    set rep [replaceString]
	}
	if {$supersearch(casereplace)} {
	    set char [lookAt $s]
	    if {[string toupper $char] eq $char} {
		set rep "[string toupper [string index $rep 0]][string range $rep 1 end]"
	    }
	}
	set oldLen [pos::diff $s $e]
	replaceText $s $e $rep
	if {$supersearch(inselection)} {
	    set change [expr {[string length $rep] - $oldLen}] 
	    set supersearch(end) [pos::math $supersearch(end) + $change]
	}
	# Need to adjust lastFindOrReplace for any possible length change.
	set supersearch(lastFindOrReplace) \
	  [list $s [pos::math $s + [string length $rep]]]
	# And update the selection
	eval [list selectText] $supersearch(lastFindOrReplace)
	# And remember if the lastfound was a zero-length replacement,
	# by adding a '1' to the list, or zero otherwise
	if {[pos::compare $s == $e]} {
	    lappend supersearch(lastFindOrReplace) 1
	} else {
	    lappend supersearch(lastFindOrReplace) 0
	}
    }
}

# Either empty or a list of 3 things -- the start, end of the last
# find or replace, and a 1 if the last thing was a replacement of a
# zero-length string (otherwise a 0).
set supersearch(lastFindOrReplace) [list]

proc supersearch::searchStart {{forwards 1}} {
    global supersearch
    if {[info exists supersearch(startfrom)]} {
	set p $supersearch(startfrom)
	unset supersearch(startfrom)
    } else {
	set p [getPos]
	# If there is any kind of selection it is either the last thing
	# found, or an initial selection from the user.  Either way we
	# want to change the start position.  Also, if there is no
	# selection, but the current position is equal to both the
	# start and end of the last thing found, then we successfully
	# found an empty string, and also want to adjust the start
	# position.
	if {[llength $supersearch(lastFindOrReplace)] \
	  && [pos::compare $p == [lindex $supersearch(lastFindOrReplace) 0]] \
	  && [pos::compare [selEnd] == [lindex $supersearch(lastFindOrReplace) 1]]} {
	    if {!$forwards} {
		set p [pos::math $p - 1]
	    } elseif {[pos::compare $p == [selEnd]] \
	      || ([lindex $supersearch(lastFindOrReplace) 2] == 1)} {
		set p [pos::math [selEnd] + 1]
	    } else {
		set p [selEnd]
	    }
	} elseif {[pos::compare $p != [selEnd]]} {
	    if {$forwards} {
		set p [pos::math $p + 1]
	    } else {
		set p [pos::math $p - 1]
	    }
	}
    }
    set supersearch(laststart) $p
    return $p
}

proc supersearch::replace&FindAgain {} {
    supersearch::replace
    set foundAt [supersearch::findAgain]
    if {[llength $foundAt]} {
	status::msg "Found match at $foundAt"
    }
}

# ×××× File switching ×××× #
proc supersearch::nextFile {} {
    global supersearch
    set i 0
    supersearch::contextCreate nextFile
    while {$i < $supersearch(numfiles)} {
	if {[info exists supersearch(multiindex)] \
	  && $supersearch(multiindex) != ""} {
	    set f [lindex $supersearch(files) [incr supersearch(multiindex)]]
	    if {$f == ""} {
		set supersearch(files) ""
		unset supersearch(multiindex)
		return 0
	    } else {
		if {[file isdirectory $f]} {
		    incr i
		    continue
		}
		set remaining [expr {$supersearch(numfiles) \
		  - $supersearch(multiindex) -1}]
		# If it is in the file and we're not excluding or it 
		# isn't in the file and we are excluding.
		if {$supersearch(exclude) ^ [supersearch::_isInFile $f $remaining]} {
		    if {[catch {file::openQuietly $f} err]} {
			set q "There was an error opening \"$f\"\r\
			  \nDo you wish to abort or continue?"
			switch [buttonAlert $q "Abort" "Continue" "View Error"] {
			    "Abort" {
				error "Cancelled search"
			    }
			    "Continue" {
				incr i
				continue
			    }
			    "View Error" {
				set y "OK"
				set n "Save To Clipboard"
				if {![dialog::yesno -y $y -n $n $err]} {
				    putScrap $err
				    error "Cancelled search -- The error\
				      information has been placed in\
				      the Clipboard."

				}
			    }
			}
		    }
		    goto [minPos]
		    supersearch::contextDelete
		    return 1
		} else {
		    incr i
		}
	    }
	}
	continue
    }
    supersearch::contextDelete
    return 0
}

proc supersearch::contextCreate {type} {
    global supersearch
    set part $supersearch(firstLine)
    if {$supersearch(i)} {
	set case "-nocase"
	set scancase "-nocase"
    } else {
	set case "--"
	set scancase ""
    }
    set supersearch(cid) [scancontext create]
    
    if {$type == "multiBatchSearch" && $supersearch(singleline)} {
	eval scanmatch $scancase \
	  [list $supersearch(cid) $supersearch(firstLine) [format {
	    if {(!$supersearch(m) \
	      || [regexp %s "\\m$supersearch(firstLine)\\M" \
	      $matchInfo(line)])} {
		if {!$supersearch(notInComments) \
		  || ![supersearch::_isInComment $f $fid]} {
		    set matched 1
		    if {!$supersearch(exclude)} {
			browse::Add $f $matchInfo(line) $matchInfo(linenum)
			incr matches
		    }
		}
	    }
	} $case]]
    } else {
	
	set wmatch "\\m$supersearch(firstLine)\\M"

	eval scanmatch $scancase [list $supersearch(cid) $part \
	  [list supersearch::contextFound $wmatch]]
    }
}

proc supersearch::contextFound {wmatch} {
    global supersearch
    upvar 1 matchInfo matchInfo
    upvar 1 matches matches
    upvar 1 fid fid
    upvar 1 lines lines
    upvar 1 offset offset
    upvar 1 f f
    
    if {(!$supersearch(m) \
      || [regexp [expr {$supersearch(i) ? {-nocase} : {--}}] \
      $wmatch $matchInfo(line)]) \
      && !$matches} {
	set offset $matchInfo(offset)
	set lines $matchInfo(line)
	set matches 1
	set mlines $supersearch(rcFirst)
	if {$offset == 0 && $mlines == 0 && \
	  [llength $supersearch(rcList)] != 0} {
	    set matches 0 ; return $matches
	}
	if {$mlines == 0} {return $matches}
	if {$offset == 0 && $mlines == 2} {
	    set matches 0 ; return $matches
	}
	set from $supersearch(regTail)
	read $fid 0
	if {[eof $fid]} {set matches 0 ; return $matches}
	gets $fid lines
	while {1} {
	    set rc [_findPatternNewLine $from 0]
	    if {$rc != -1} {
		set part [string range $from 0 [expr {$rc-1}]]
		set from [string range $from [expr {$rc+1}] end]
	    } else { 
		set part $from
		set from ""
	    }
	    if {$supersearch(ignorespace)} {
		set lines [string trim $lines]
	    }
	    set part "^[supersearch::prepLine $part]"
	    if {$rc != -1} {append part "\$"}
	    if {$supersearch(i)} {
		if {![regexp -nocase -- $part $lines]} {
		    set matches 0 ; return $matches
		}
	    } else {
		if {![regexp -- $part $lines]} {
		    set matches 0 ; return $matches
		}
	    }
	    if {$from == ""} {
		# We have found a complete match.  
		if {$supersearch(notInComments)} {
		    if {[supersearch::_isInComment $f $fid]} {
			set matches 0 ; return $matches
		    }
		}
		return $matches
	    }
	    if {[eof $fid]} {set matches  0 ; return $matches}
	    gets $fid lines
	    # loop around again, checking the next line
	}
    }
}

proc supersearch::contextDelete {} {
    global supersearch
    if {[string length $supersearch(cid)]} {
	scancontext delete $supersearch(cid)
	set supersearch(cid) ""
    }
}

# Used for multi-file searches.
proc supersearch::_isInComment {f fid} {
    upvar 1 matchInfo matchInfo
    
    # Now we wish to check whether it is inside a comment
    set mode [win::FindMode $f]
    if {$mode != "Text"} {
	foreach ch [comment::Characters "General" [list $mode]] {
	    set cm [string first $ch $matchInfo(line)]
	    if {$cm != -1} {
		return 1
	    }
	}
    }
    return 0
}

## 
 # -------------------------------------------------------------------------
 # 
 # "supersearch::_isInFile" --
 # 
 #  This proc must be wrapped in calls to supersearch::contextCreate
 #  and supersearch::contextDelete.
 # -------------------------------------------------------------------------
 ##
proc supersearch::_isInFile {f {remaining ""}} {
    global supersearch
    # Are all of these necessary?
    set matches 0
    set lines {}
    set offset 0
    set fid 0
    
    if {($remaining eq "")} {
	status::msg "Searching: $msgPath"
    } else {
	supersearch::multiMessage $f $remaining
    }
    
    if {![catch [list alphaOpen $f "r"] fid]} {
	catch {scanfile $supersearch(cid) $fid}
	close $fid
    }
    
    return $matches
}

# Will return the empty string if nothing was found or else the list
# of start,end position for the match.
proc supersearch::findNextOkLocation {{forwards 1}} { 
    supersearch::findInNextFile $forwards 
}

# Will return the empty string if nothing was found or else the list
# of start,end position for the match.
proc supersearch::findInNextFile {{forwards 1}} {
    global supersearch
    if {$supersearch(multi)} {
	watchCursor
	if {[supersearch::nextFile]} {
	    if {$supersearch(exclude)} {
		return [list [minPos] [minPos]]
	    } else {
		return [supersearch::basicSearch 1 1]
	    }
	}
	set str "Can't find '[searchString]', and there are no more files\
	  to search."
	status::msg "[shorten $str 80 50]"
	set supersearch(numfiles) -1
	enableMenuItem Search findInNextFile 0
    } else {
	if {$supersearch(inselection)} {
	    set str "No more instances of '[searchString]' in selected range."
	    status::msg "[shorten $str 80 38]"
	} else {
	    if {$supersearch(circular)} {
		if {!$forwards} {
		    if {[pos::compare $supersearch(laststart) != [maxPos]]} {
			set supersearch(startfrom) [maxPos]
			status::msg "Now searching backwards from end of document."
			return [supersearch::basicSearch 0]
		    }
		} else {
		    if {[pos::compare $supersearch(laststart) != [minPos]]} {
			set supersearch(startfrom) [minPos]
			status::msg "Now searching forwards from start of document."
			return [supersearch::basicSearch 1]
		    }
		}
	    }
	    status::msg "Can't find '[shorten [searchString] 65 30]'."
	}
    }
    global supersearchmodeVars
    if {$supersearchmodeVars(beepOnFailedSearch)} {
	if {![info exists supersearch(beep)] || $supersearch(beep)} {
	    beep
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "supersearch::multiMessage" --
 # 
 # Display a nicely formatted message, truncating the file name as much as 
 # possible to that the user can see which directories are being searched.
 # The "filespathidx" variable computed in [supersearch::getFiles] is the 
 # key here to presenting a sensible message.
 # 
 # --------------------------------------------------------------------------
 ##

proc supersearch::multiMessage {filename remaining} {
    
    global supersearch
    
    if {![info exists supersearch(filespathidx)]} {
        set supersearch(filespathidx) 0
    }
    set arg "%-[string length [llength $supersearch(files)]]s"
    set msg "Searching ([format $arg $remaining] left): "
    set pathList [file split $filename]
    if {($supersearch(filespathidx) > 0)} {
	set pathList [lrange $pathList $supersearch(filespathidx) end]
	append msg "É"
    }
    status::msg [append msg [eval [list file join] $pathList]]
    return
}

# ×××× Batch ×××× #
proc supersearch::batchSearch {} {
    global supersearch
    if {$supersearch(multi)} {
	supersearch::multiBatchSearch
    } else {
	supersearch::basicBatchSearch
    }
}

proc supersearch::basicBatchSearch {} {	
    global supersearch
    
    # Find starting, ending position, and whether we should loop.
    if {$supersearch(inselection)} {
	set startPos [getPos]
	set endPos [selEnd]
	set loop 0
    } else {
	if {$supersearch(f)} {
	    set startPos [getPos]
	    set loop $supersearch(circular)
	} else {
	    set startPos [minPos]
	    set loop 0
	}
	set endPos [maxPos]
    }
    
    # Store current window, in case it changes during the search.
    set ww [win::Current]
    # Could use this, but it is ugly.
    #browse::Dynamic 1
    browse::Start
    watchCursor
    
    set pos $startPos
    while {1} {
	if {![catch {search -w $ww -s -m $supersearch(m) -f 1 -r 1 \
	  -i $supersearch(i) -- $supersearch(reg) $pos} mtch]} {
	    set mtch0 [lindex $mtch 0]
	    set next [lindex $mtch 1]
	    
	    if {[pos::compare -w $ww $mtch0 >= $endPos]} {
		break
	    }
	    if {!$supersearch(notInComments) \
	      || ![text::isInComment -w $ww $mtch0]} {
		browse::Add $ww \
		  [getText -w $ww [pos::lineStart -w $ww $mtch0] \
		  [pos::lineEnd -w $ww $next]] \
		  [lindex [pos::toRowChar -w $ww $mtch0] 0] 0
		# Don't match more than once on the same line
		# (this is historically how the search has behaved)
		set next [pos::lineEnd -w $ww $next]
	    }
	    if {[pos::compare -w $ww $next == $pos]} {
		set pos [pos::math -w $ww $pos + 1]
		if {[pos::compare -w $ww $pos > [maxPos -w $ww]]} {
		    # odd circumstance can happen on Alphatk
		    break
		}
	    } else {
		set pos $next
	    }
	} else {
	    if {$loop} {
		set loop 0
		set pos [minPos -w $ww]
		set endPos $startPos
	    } else {
	        break
	    }
	}
    }
    browse::Complete
}

proc supersearch::multiBatchSearch {{complete 1}} {
    global supersearch alpha::platform
    set from $supersearch(reg)
    if {$supersearch(m)} {
	set from "\\m$from\\M"
    }
    
    if {$supersearch(i)} {
	set case "-nocase"
    } else {
	set case "--"
    }
    
    supersearch::getFiles
    set supersearch(multiindex) -1
    set changes 0
    set i 0
    set values 0
    set matches 0
    supersearch::contextCreate multiBatchSearch
    browse::Start
    browse::Dynamic
    watchCursor
    while {$i < $supersearch(numfiles)} {
	if {[info exists supersearch(multiindex)] \
	  && $supersearch(multiindex) != ""} {
	    set f [lindex $supersearch(files) [incr supersearch(multiindex)]]
	    if {$f == ""} {
		set supersearch(files) ""
		unset supersearch(multiindex)
		continue
	    } else {
		if {[file isdirectory $f]} {
		    incr i
		    continue
		}
		set remaining [expr {$supersearch(numfiles) \
		  - $supersearch(multiindex) -1}]
		set askstop ""
		if {$supersearch(singleline)} {
		    supersearch::multiMessage $f $remaining
		    if {![file exists $f]} {
			set askstop "File '$f' doesn't exist any more.\
			  It won't be searched."
		    } elseif {![catch [list alphaOpen $f "r"] fid]} {
			set matched 0
			if {[catch {scanfile $supersearch(cid) $fid} err]} {
			    set askstop "Opened $f, but couldn't scan\
			      it: '$err'! May not be able to find matching\
			      lines."
			}
			close $fid
			if {!$matched && $supersearch(exclude)} {
			    browse::Add $f "Pattern didn't match" 1
			    incr matches
			}
		    } else {
			set askstop "Couldn't open $f with read permission!\
			  Will not be able to find matching lines."
		    }
		} else {
		    if {[supersearch::_isInFile $f $remaining]} {
			status::msg "Looking at '[file tail $f]'"
			if {!$supersearch(exclude)} {
			    # There is a match, but we don't want it
			    incr i ; continue
			}
			if {![catch [list alphaOpen $f "r"] cid]} {
			    if {[catch {read $cid} tmp]} {
				set askstop "Opened $f, but couldn't read\
				  it: '$tmp'! Will not be able to find\
				  matching lines."
				close $cid
			    } else {
				close $cid
				set nl 0
				if {${alpha::platform} == "alpha"} {
				    regsub -all "\n" $tmp "\r" tmp
				    set eol "\r"
				} else {
				    set eol "\n"
				}
				set old [string length $tmp]
				while {[regexp -indices $case "$from" \
				  $tmp values]} {
				    set m0 [lindex $values 0]
				    set m1 [lindex $values 1]
				    set beg [string range $tmp 0 [expr {$m0-1}]]
				    set m0 [expr {1+[string last $eol $beg]}]
				    incr nl [regexp -all $eol $beg]
				    set fol [string range $tmp $m1 end]
				    set frc [string first $eol $fol]
				    set m2 $m1
				    if {$frc < 0} {
					incr m2 [string length $fol]
				    } else {
					incr m2 [expr {$frc-1}]
					incr nl
				    } 
				    set mtch [string range $tmp $m0 $m2]
				    browse::Add $f $mtch $nl
				    set old [string length $tmp]
				    set tmp [string range $tmp [expr {$m1+1}] end]
				    incr nl [regexp -all $eol $mtch]
				    incr matches
				    if {$old == [string length $tmp]} {
					alertnote "You hit a bug, please report"
					break
				    }
				}
			    }
			} else {
			    set askstop "Couldn't open $f with read\
			      permission! Will not be able to find\
			      matching lines."
			}
		    } else {
		        # Not in file
		        if {$supersearch(exclude)} {
			    browse::Add $f "Pattern didn't match" 1
			}
		    }	
		}
		if {[string length $askstop]} {
		    if {![dialog::yesno -y "Continue" -n "Stop search"\
		      $askstop]} { break }
		}
		incr i
	    }
	    continue
	}
    }
    supersearch::contextDelete
    
    if {$complete} {
	browse::Complete
    }
}

# ×××× Replace all ×××× #

proc supersearch::replaceAll {{force 0}} {
    supersearch::reallyReplaceAll $force
}

proc supersearch::reallyReplaceAll {{force 1}} {
    global supersearch
    
    supersearch::recentPattern \
      [searchString] [replaceString] $supersearch(r) 1
    
    if {$supersearch(reg)==""} {
        error "Empty search string"
    } 
    if {$supersearch(multi)} {
	if {!$force} {
	    if {![dialog::yesno -y "Continue" -n "Cancel"\
	      "Are you sure you want to perform\
	      a global replacement in many files?"]} {
		status::msg "Cancelled"
		return
	    }
	}
	supersearch::multiReplaceAll
    } else {
	if {$supersearch(inselection)} {
	    goto $supersearch(start)
	} else {
	    if {$supersearch(f)} {
		goto [getPos]
	    } else {
		goto [minPos]
	    }
	}
	supersearch::basicReplaceAll
    }
}

proc supersearch::basicReplaceAll {} {
    global supersearch supersearchmodeVars undoOn
    set from $supersearch(reg)
    if {$supersearch(m)} {
	set from "\\m$from\\M"
    }
    set savefrom [searchString]
    set to [replaceString]
    if {!$supersearch(r)} {
	set to [quote::Regsub $to]
	if {[catch {regsub -- $from "$savefrom" $to dummy} err]} {
	    alertnote "Regexp compilation problems: $err"
	    return
	}
	if {![llength {$dummy}]} {
	    alertnote "Regsub problem"
	    return
	}
    } else {
	if {[catch {regsub -- $from "$from" $to dummy} err]} {
	    alertnote "Regexp compilation problems: $err"
	    return
	}
    }

    set pos [supersearch::searchStart]
    if {$supersearch(inselection) && !$supersearch(multi)} {
	lappend ranges [list $supersearch(start) $supersearch(end)]
    } else {
	lappend ranges [list $pos [maxPos]]
	if {$supersearch(circular)} {
	    lappend ranges [list [minPos] $pos]
	}
    }
    set opts [supersearch::buildRegsubOpts]
    set count 0
    foreach range $ranges {
	set txt [eval getText $range]
	if {$supersearch(maceols)} {
	    regsub -all "\\r" $txt "\n" txt
	    regsub -all "\\r" $from "\n" from
	}
	if {[incr count [eval [list regsub -all] $opts \
	  [list $from $txt $to txt]]]} {
	    if {$supersearchmodeVars(undoOffForReplaceAll)} {
		set oldUndo $undoOn ; set undoOn 0
	    }
	    if {$supersearch(maceols)} {
		regsub -all "\\n" $txt "\r" txt
	    }
	    eval replaceText $range [list $txt]
	    if {$supersearchmodeVars(undoOffForReplaceAll)} {
		set undoOn $oldUndo
	    }
	}
    }
    if {$count > 0} {
	status::msg "Replacements: $count in given range: [join $ranges ,]"
    } else {
	status::msg "No replacements in given range: [join $ranges ,]"
    }
    return $count
}

proc supersearch::buildRegsubOpts {} {
    global supersearch alpha::platform
    set opts [list]
    set supersearch(maceols) 0
    if {$supersearch(r) && ($supersearch(lineanchor) || $supersearch(linestop))} {
	if {$supersearch(lineanchor)} {
	    if {$supersearch(linestop)} {
		lappend opts "-line"
	    } else {
		lappend opts "-lineanchor"
	    }
	} else {
	    lappend opts "-linestop"
	}
    }
    if {${alpha::platform} == "alpha"} {set supersearch(maceols) 1}
    if {$supersearch(i)} {
	lappend opts -nocase --
    } else {
	lappend opts --
    }
    return $opts
} 

proc supersearch::multiReplaceAll {} {
    global supersearch supersearchmodeVars alpha::platform
    set from $supersearch(reg)
    if {$supersearch(m)} {
	set from "\\m$from\\M"
    } 
    set savefrom [searchString]
    set to [replaceString]
    if {!$supersearch(r)} {
	set to [quote::Regsub $to]
	if {[catch {regsub -- $from "$savefrom" $to dummy} err]} {
	    alertnote "Regexp compilation problems: $err"
	    return
	}
	if {![llength {$dummy}]} {
	    alertnote "Regsub problem"
	    return
	}
    } else {
	if {[catch {regsub -- $from "$from" $to dummy} err]} {
	    alertnote "Regexp compilation problems: $err"
	    return
	}	
    }
    supersearch::ensureAllWindowsSaved
    
    supersearch::getFiles
    set supersearch(multiindex) -1
    set changes 0
    set i 0
    set opts [supersearch::buildRegsubOpts]
    supersearch::contextCreate multiReplaceAll
    watchCursor
    while {$i < $supersearch(numfiles)} {
	if {[info exists supersearch(multiindex)] \
	  && $supersearch(multiindex) != ""} {
	    set f [lindex $supersearch(files) [incr supersearch(multiindex)]]
	    if {$f == ""} {
		set supersearch(files) ""
		unset supersearch(multiindex)
		continue
	    } else {
		if {[file isdirectory $f]} {
		    incr i
		    continue
		}
		set remaining [expr {$supersearch(numfiles) \
		  - $supersearch(multiindex) -1}]
		if {[supersearch::_isInFile $f $remaining]} {
		    status::msg "Modifying ${f}É"
		    if {![catch [list alphaOpen $f "r"] cid]} {
			set tmp [read $cid]
			close $cid
			if {$supersearch(maceols)} {
			    regsub -all "\\r" $tmp "\n" tmp
			    regsub -all "\\r" $from "\n" from
			}
			set inc [eval [list regsub -all] $opts \
			  [list $from $tmp $to tmp]]
			if {$inc > 0} {
			    if {$supersearchmodeVars(unlockFilesDuringBatchReplacements)} {
				if {![file writable $f]} {
				    # If this fails, the 'open' below will also
				    # fail, and we'll capture an error then.
				    catch [list file::setLockState $f 0]
				}
			    }
			    if {![catch [list alphaOpen $f "w"] ocid]} {
				# 'puts' wants '\n' on Alpha 8/X/tk, which
				# it will then convert to whatever is
				# desired on the current platform.
				puts -nonewline $ocid $tmp
				close $ocid
				set tmp ""
				incr changes $inc
				set matches($f) 1
			    } else {
				alertnote "Couldn't open $f with write\
				  permission!  Changes will not take place."
			    }
			}
		    } else {
			alertnote "Couldn't open $f with read permission!\
			  Changes will not take place."
		    }
		}
		incr i
	    }
	    continue
	}
    }
    supersearch::contextDelete
    
    eval file::revertThese [array names matches]
    status::msg "Replaced $changes instances"
    return $changes
}



# ×××× Search utilities ×××× #
proc supersearch::getFiles {} {
    global supersearch alpha::application
    status::msg "Building list of files to searchÉ"
    set supersearch(files) [list]
    foreach fset [supersearch::getfsets] {
	eval [list lappend supersearch(files)] [getFileSet $fset]
	status::msg "Building list of files to searchÉ\
	  ([llength $supersearch(files)] files so far)"
    }
    set supersearch(files) [lsort -dictionary -unique $supersearch(files)]
    set supersearch(numfiles) [llength $supersearch(files)]
    if {!$supersearch(numfiles)} {
	dialog::alert "You have selected an empty fileset.\
	  Please select another one.\r\
	  If you are trying to search multiple filesets, you must tell\
	  $alpha::application which ones to search by clicking on the\
	  'multiple filesets' button.  Once you've done that \
	  once, you can then use the checkbox to toggle\
	  single/multi for all subsequent searches."
	error "Cancelled"
    }
    # "filespathidx" is used by [supersearch::multiMessage].
    foreach f $supersearch(files) {
	set pathElements [file split $f]
	for {set i 0} {($i < [llength $pathElements])} {incr i} {
	    set level${i}([lindex $pathElements $i]) ""
	}
    }
    for {set i 0} {[info exists level$i]} {incr i} {
	if {([llength [array names level$i]] > 1)} {
	    break
	}
    }
    set supersearch(filespathidx) [incr i -1]
    return
}

proc supersearch::ensureAllWindowsSaved {} {
    global win::NumDirty
    if {${win::NumDirty}} {
	if {[buttonAlert "Save all windows?" "Yes" "Cancel"] != "Yes"} {
	    error "Cancelled!"
	}
	saveAll
    }
}

proc supersearch::getfsets {} {
    global supersearch
    if {$supersearch(ismultifset)} {
	return $supersearch(multifsets)
    } else {
	return [list $supersearch(fileset)]
    }
}

# ×××× Dialog box and helpers ×××× #
proc supersearch::find {} {
    global supersearch searchPattern supersearchmodeVars currFileSet \
      recentSearches

    if {![llength [winNames -f]]} {
	# If there's no window, we don't have single file search, 
	# and so the first popup menu item is always the one we need.
	set multiPopup 0
    } else {
	# 0 = top window, 1 = multi
	set multiPopup $supersearch(multi)
    }
    
    if {!$supersearchmodeVars(separateSearchAndCurrentFileset) \
      || ![info exists supersearch(fileset)] \
      || ($supersearch(fileset) == "")} {
	set supersearch(fileset) $currFileSet
    }
    set loop 0
    while 1 {
	set haveWin [expr {[win::Current] != ""}]
	
	set y 15
	set args {}
	lappend args -T "Search"
	incr y 13
	set yt $y
	if {!$supersearch(r)} {
	    set supersearch(search) [searchString]
	    set supersearch(replace) [replaceString]
	} else {
	    set supersearch(search) [supersearch::quoteTabNewline [searchString]]
	    set supersearch(replace) [supersearch::quoteTabNewline [replaceString]]
	}
	eval lappend args [dialog::textedit "Search for:" \
	  $supersearch(search) 20 y 27 $supersearchmodeVars(boxHeights)]
	set y $yt
	eval lappend args [dialog::textedit "Replace with:" \
	  $supersearch(replace) 320 y 27 $supersearchmodeVars(boxHeights)]
	incr y 13
	set yr $y
	eval lappend args \
	  [dialog::checkbox "Ignore Case" $supersearch(i) 20 y] \
	  [dialog::checkbox "Regexp" $supersearch(r) 20 y]
	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend args -tag regexp
	}
	eval lappend args \
	  [dialog::checkbox "Batch" $supersearch(b) 20 y]
	set my $y
	set y $yr
	eval lappend args \
	  [dialog::checkbox "Word Match" $supersearch(m) 122 y] \
	  [dialog::checkbox "Keep Capitals" $supersearch(casereplace) 122 y] \
	  [dialog::checkbox "Ignore Spaces" $supersearch(ignorespace) 122 y]
	set y $my
	incr y 10
	eval lappend args [dialog::button "Search" 20 y "Don't Search" 92 y]
	# 10 pixel vertical spacing between buttons (we get 6 automatically)
	incr y 4
	eval lappend args [dialog::button "Replace All" 20 y "Cancel" 125 y]
	set ym [expr {$y + 10}]
	set y 4

	set buttons {}
	set button_help {}
	set yrplug $y
	supersearch::executePlugins 2
	set y $yrplug
	eval lappend args [dialog::button "PrefsÉ" 535 y]
	incr y -26
 	eval lappend args [dialog::button "Regexp HelpÉ" 10 y]
	
	# single/multi files
	set y $yr
	set x 245
	global alpha::platform
	# Popup-choices depend on whether we have a window
	if {$haveWin} {
	    set ftypes [list "Top Window" "Multiple files" "Patterns"]
	} else {
	    set ftypes [list "Multiple files" "Patterns"]
	}
	eval lappend args [dialog::text "Options:" $x y]
	set yr2 $y
	eval lappend args \
	  [dialog::menu $x y $ftypes [lindex $ftypes $multiPopup] 130] 
	set yr $y
	incr y 8
	if {$supersearchmodeVars(smartInSelectionFlag)} {
	    if {([win::Current] != "") && ([string length [getSelect]] - \
	      [string length $supersearch(search)] > 80)} {
		set select 1
	    } else {
		set select 0
	    }
	} else {
	    set select $supersearch(inselection)
	}
	lappend args -n "Top Window"
	
	# If there's no window/no selection move irrelevant checkboxes offscreen.
	eval lappend args \
	  [dialog::checkbox "From current pos" $supersearch(f) \
	  [expr {$haveWin ? $x : 3000}] y] \
	  [dialog::checkbox "Circular " $supersearch(circular) \
	  [expr {$haveWin ? $x : 3000}] y] \
	  [dialog::checkbox "Not in comments" $supersearch(notInComments) \
	  [expr {$haveWin ? $x : 3000}] y] \
	  [dialog::checkbox "In selection only" $select \
	  [expr {$haveWin && ([string length [getSelect]] > 0) ? $x : 3000}] y] \
	  [list -n "Multiple files"]
	set y $yr
	incr y 2
	eval lappend args \
	  [dialog::text "Select a single fileset:" $x y]
	incr x 10
	# align button with text 
	set y $yr
	eval lappend args \
	  [dialog::menu [expr {$x +140}] y \
	  [lsort -dictionary [fileset::names]] \
	  $supersearch(fileset) 200]
	set yr3 $y
	incr y 2
	set delx 0
	if {[llength $supersearch(multifsets)]} {
	    eval lappend args \
	      [dialog::checkbox "or pick" $supersearch(ismultifset) $x y]
	    incr x 12
	    incr delx -11
	} else {
	    # we don't want the check box, so we move it way offscreen.
	    eval lappend args \
	      [dialog::text "Or pick" $x y]
	    set y $yr3
	    eval lappend args \
	      [dialog::checkbox "or pick" $supersearch(ismultifset) \
	      [expr {$x -1000}] y]
	    incr x
	}
	set y $yr3
	eval lappend args \
	  [dialog::button "Multiple Filesets:" [expr {$x +55}] y] \
	  [dialog::text [join $supersearch(multifsets) ", "] $x y 50]
	set y $yr2
	eval lappend args \
	  [dialog::button "New filesetÉ" [expr {$x +142 + $delx}] y \
	  "Dir scanÉ" [expr {$x +264 + $delx}] y]
	set y $yr
	set patts {}
	if {[info exists recentSearches] && [llength $recentSearches]} {
	    foreach rs $recentSearches {
		if {[lindex $rs 3]} {
		    lappend patts "\"[lindex $rs 0]\" to \"[lindex $rs 1]\""
		} else {
		    lappend patts "\"[lindex $rs 0]\" "
		}
	    }
	    lappend patts "-"
	}
	eval lappend patts [array names searchPattern]
	eval lappend args \
	  [list -n "Patterns"] \
	  [dialog::button "Save this patternÉ" $x y \
	  "Forget pattern" [expr {$x + 160}] y] \
	  [dialog::menu $x y $patts $supersearch(pattern) 250]
	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend args -action \
	      [list supersearch::usePatternFromPopup {+0 1 3 5}]
	    # Just move this a long way offscreen
	    eval lappend args \
	      [dialog::button "Use pattern from menu" [expr {$x+1000}] y]
	} else {
	    eval lappend args \
	      [dialog::button "Use pattern from menu" $x y]
	}
	incr y 30
	set help [list "Enter the search string here (for regexp\
	  searches, you can add '(?n)' to make '.' never match a newline)" \
	  "Enter the replace string here" \
	  "To ignore upper/lower case differences when searching,\
	  click this box.||To use exact, case-sensitive matches only,\
	  click this box" \
	  "To interpret the above search string as a regular expression,\
	  click this box.||To match the above search string literally,\
	  click this box." \
	  "To display all possible matches in a separate control window,\
	  click this box.||To highlight each match individually as it is\
	  found, click this box." \
	  "To match only entire words,\
	  click this box.||To allow any sequence of characters which matches\
	  the above search string, click this box." \
	  "To replace 'foo' with 'bar' and 'Foo' with 'Bar' with only one\
	  search,\
	  click this box.||To always replace with the exact, given\
	  replacement string, click this box" \
	  "To ignore whitespace differences when searching,\
	  click this box.||To use exact, character and space matching only,\
	  click this box" \
	  "Click here to begin the search" \
	  "Click here to remember my settings, but not actually search" \
	  "Click here to replace all matches at once without my intervention" \
	  "Click here to discard any changes you've made to the settings."]
	
	eval lappend help $button_help
	lappend help \
	  "Click here to edit the search preferences." \
	  "Click here to view help on regexp searches." \
	  "More search facilities are accessible from this menu." \
	  "To start the search at the current cursor position,\
	  click this box.||To search from the beginning of the document,\
	  click this box" \
	  "To continue searching from the beginning after reaching the end\
	  of the document, click this box.||To stop searching at the end\
	  of the document, click this box." \
	  "To ignore matches in commented out text,\
	  click this box||To search the entire text, click this box." \
	  "To search just in the current highlighted text,\
	  click this box||To search the entire text, click this box." \
	  "Select the fileset in which to search." \
	  "To search more than one fileset, use the 'Multiple filesets'\
	  button and click this box||To search just a single fileset,\
	  click this box." \
	  "Click here to select more than one fileset in which to search." \
	  "Click here to create a new fileset" \
	  "Click here to scan a particular directory." \
	  "Save the search and replace strings above for future use." \
	  "Permanently remove the pattern selected in the menu."
	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend help \
	      "Select a pattern from this menu and it will be entered into\
	      the search fields above." \
	      "Use the pattern currently selected in this popup menu."
	} else {
	    lappend help \
	      "Select a pattern from this menu and then click the button below." \
	      "Use the pattern currently selected in this popup menu."
	}
	
	lappend args -help $help
	set res [eval dialog -w 610 -h $ym $args]
	set loop 1
	
	if {[lindex $res 11]} {
	    return
	}
	# turn on other flags if any
	set i 0
	foreach text {search replace i r b m casereplace ignorespace} {
	    set supersearch($text) [lindex $res $i]
	    incr i
	}
	
	if {!$supersearch(r)} {
	    searchString $supersearch(search)
	    replaceString $supersearch(replace)
	} else {
	    searchString [supersearch::unquoteTabNewline $supersearch(search)]
	    replaceString [supersearch::unquoteTabNewline $supersearch(replace)]
	}
	
	# get buttons
	set j $i
	set blist [concat [list search dontSearch replaceAll cancel] \
	 $buttons [list prefs regexpHelp]]
       foreach but $blist {
	    if {[lindex $res $j]} {
		set button $but
		break
	    }
	    incr j
	}
	incr i [llength $blist]
	# Remember which of the popup menu items was foremost.
	set multiPopup [lsearch -exact $ftypes [lindex $res $i]]
	if {[lindex $res $i] == "Top Window"} {
	    set supersearch(multi) 0
	    set supersearch(f) [lindex $res [incr i]]
	    set newCircular [lindex $res [incr i]]
	    if {$supersearch(circular) != $newCircular} {
		set supersearch(circular) $newCircular
		prefs::modified supersearch(circular)
	    }
	    set supersearch(notInComments) [lindex $res [incr i]]
	    set supersearch(inselection) [lindex $res [incr i]]
	    if {$supersearch(inselection)} {
		if {[pos::compare [getPos] <= [selEnd]]} {
		    set supersearch(start) [getPos]
		    set supersearch(end) [selEnd]
		} else {
		    set supersearch(start) [selEnd]
		    set supersearch(end) [getPos]
		}
	    } 
	    incr i 7
	} elseif {[lindex $res $i] == "Multiple files"} {
	    set supersearch(multi) 1
	    # This will be over-ridden the moment we start
	    # a search, but if we hit 'Don't Search', then
	    # there should be no files.
	    set supersearch(numfiles) -1
	    set supersearch(f) [lindex $res [incr i]]
	    set newCircular [lindex $res [incr i]]
	    if {$supersearch(circular) != $newCircular} {
		set supersearch(circular) $newCircular
		prefs::modified supersearch(circular)
	    }
	    set supersearch(notInComments) 0 ; incr i
	    set supersearch(inselection) [lindex $res [incr i]]

	    # ignore multi-fset for the moment
	    set supersearch(fileset) [lindex $res [incr i]]
	    set supersearch(ismultifset) [lindex $res [incr i]]
	    
	    if {[lindex $res [incr i]]} {supersearch::multifset ; continue }
	    if {[lindex $res [incr i]]} {supersearch::newfset ; continue }
	    if {[lindex $res [incr i]]} {supersearch::dirscan ; continue }
	} else {
	    # The user terminated the dialog with 'Patterns' foremost
	    # in the pop-up menu.  Unless they clicked one of the buttons
	    # in that pane, the state of the dialog is not really very 
	    # well defined.  Did they want a single or multi-search?
	    incr i 10
	    set supersearch(pattern) [lindex $res [expr {$i +2}]]
	    if {[lindex $res $i]} {
		supersearch::storePattern
		continue
	    }
	    incr i
	    if {[lindex $res $i]} {
		supersearch::forgetPattern
		continue
	    }
	    if {[lindex $res [incr i 2]]} {supersearch::usePattern ; continue}
	    incr i
	}
	
	if {[info exists button]} {
	    if {$button == "prefs"} {
		supersearch::prefs
	    } elseif {$button == "regexpHelp"} {
		supersearch::regexpHelp
	    } elseif {[lsearch -exact $buttons $button] != -1} {
		supersearch::executePlugins 3 $button
	    } else {
		if {$button == "search"} { 
		    set button "generalSearch"
		    supersearch::recentPattern \
		      [searchString] [replaceString] $supersearch(r) 0
		} elseif {$button == "replaceAll"} {
		    supersearch::recentPattern \
		      [searchString] [replaceString] $supersearch(r) 1
		    set button "reallyReplaceAll" 
		}
		supersearch::parseSearch
		supersearch::$button
		return
	    }
	    unset button
	}
	
	set loop 0
	# big while loop
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "supersearch::recentPattern" --
 # 
 #  Call this with information about any new search/replace operation.
 #  
 #  It updates the stored list of recent searches.  The idea is that
 #  we keep track of replace operations with ('replace' == 1) as well
 #  as pure search operations.  But we have to be careful not to
 #  over-write a replace operation with a search.
 #  
 #  This list will later be used to show to the user in the patterns
 #  popup, with "searchPat" for a search and "searchPat" -> "replacePat"
 #  for a replace operation.
 # -------------------------------------------------------------------------
 ##
proc supersearch::recentPattern {from to grep replace} {
    global recentSearches
    if {[info exists recentSearches]} {
	set idx 0
	foreach rs $recentSearches {
	    if {[lindex $rs 0] eq $from} {
		if {([lindex $rs 1] eq $to) || ([lindex $rs 3] == 0)} {
		    if {[lindex $rs 3]} {
			set replace 1
		    }
		    set recentSearches [lreplace $recentSearches $idx $idx]
		    break
		}
	    }
	    incr idx
	}
    }
    lappend recentSearches [list $from $to $grep $replace]
    if {[llength $recentSearches] > 10} {
	set recentSearches [lrange $recentSearches end-9 end]
    }
}

proc supersearch::prefs {} {
    catch {prefs::dialogs::packagePrefs supersearch}
    
    global supersearchmodeVars
    if {$supersearchmodeVars(boxHeights) > 10} {
	alertnote "The 'Box Heights' preference cannot be greater than 10.\
	  It will be reset to 3."
	set supersearchmodeVars(boxHeights) 3
    }
}

proc supersearch::usePattern {} {
    global supersearch searchPattern recentSearches
    set pat $supersearch(pattern)
    if {[info exists recentSearches] \
      && [regexp -- {^\"(.*)\" (to \"(.*)\")?$} $pat -> from -> to]} {
	# probably a recent search
	foreach rs $recentSearches {
	    if {([lindex $rs 0] eq $from) \
	      && ([lindex $rs 3] == 0 || ([lindex $rs 1] eq $to))} {
		set pats $rs
		break
	    }
	}
    }
    if {![info exists pats]} {
	set pats $searchPattern($pat)
    }
    ::searchString [lindex $pats 0]
    # Only set the replace string if this pattern actually
    # used the replace string.  The empty string check is
    # for backwards compatibility
    if {([lindex $pats 3] == "") || [lindex $pats 3]} {
	::replaceString [lindex $pats 1]
    }
    if {[string length [lindex $pats 2]]} {
	set supersearch(r) [lindex $pats 2]
    }
}

proc supersearch::forgetPattern {} {
    global supersearch searchPattern
    if {[info exists searchPattern($supersearch(pattern))]} {
	prefs::modified searchPattern($supersearch(pattern))
	unset searchPattern($supersearch(pattern))
	status::msg "Pattern '$supersearch(pattern)' permanently deleted"
	set supersearch(pattern) ""
    } else {
	status::msg "Can't delete temporary patterns."
    }
}

proc supersearch::usePatternFromPopup {dialogItemIds} {
    global searchPattern supersearch recentSearches
    # Get the pattern from the menu -- it is either a saved
    # pattern or a recently used search
    set pat [getControlValue [lindex $dialogItemIds 0]]
    if {[info exists recentSearches] \
      && [regexp -- {^\"(.*)\" (to \"(.*)\")?$} $pat -> from -> to]} {
	# probably a recent search
	foreach rs $recentSearches {
	    if {([lindex $rs 0] eq $from) \
	      && ([lindex $rs 3] == 0 || ([lindex $rs 1] eq $to))} {
		set pats $rs
		break
	    }
	}
    }
    set supersearch(pattern) $pat
    if {![info exists pats]} {
	# It was a stored pattern
	set pats $searchPattern($pat)
    }
    # Set search string
    setControlValue [lindex $dialogItemIds 1] [lindex $pats 0]
    # Only set the replace string if this pattern actually
    # used the replace string.  The empty string check is
    # for backwards compatibility
    if {([lindex $pats 3] == "") || [lindex $pats 3]} {
	setControlValue [lindex $dialogItemIds 2] [lindex $pats 1]
    }
    # Set regexp flag
    if {[string length [lindex $pats 2]]} {
	setControlValue [lindex $dialogItemIds 3] [lindex $pats 2]
    }
}

proc supersearch::storePattern {} {
    global supersearch searchPattern
    # Need to create a better dialog to have a checkbox to only save
    # the search string, not the replace string.
    if {[catch {prompt "New pattern's name?" $supersearch(pattern)} name]} {
	return ""
    }
    if {$supersearch(r)} {
	set searchPattern($name) \
	  [list [supersearch::quoteTabNewline [searchString]] \
	  [supersearch::quoteTabNewline [replaceString]] 1 1]
    } else {
	set searchPattern($name) [list [searchString] [replaceString] 0 1]
    }
    prefs::modified searchPattern($name)
    set supersearch(pattern) $name
    return $name
}

set {searchPattern(C++ to C Comments)} {{//([^\r\n]*)} {/* \1 */} 1 1}
set {searchPattern(Find Repeated Words)} {{(\m\w+\M)\s+\1} {\1} 1 1}

proc supersearch::dontSearch {} {}

proc supersearch::regexpHelp {} {
    ::help::regexpHelpDialog
}

proc supersearch::multifset {} {
    global supersearch
    if {![catch {listpick -p "Select filesets" -l -L $supersearch(multifsets) \
      [lsort -dictionary [fileset::names]]} res]} {
	if {[llength $res]} {
	    set supersearch(multifsets) $res
	    set supersearch(ismultifset) 1
	} else {
	    set supersearch(multifsets) ""
	    set supersearch(ismultifset) 0
	} 
    }
}

proc supersearch::dirscan {} {
    global supersearch

    set supersearch(ismultifsets) 0
    if {[llength $supersearch(multifsets)] != 0} {
	set supersearch(multifsets) ""
    }
    
    if {[catch {get_directory -p "Scan which folder?"} dir]} {
	return
    }
    
    set name [file tail $dir]
    fileset::fromDirectory::create $name $dir *
    registerNewFileset $name fromDirectory
    updateCurrentFileset
    set supersearch(fileset) $name
}

proc supersearch::findNewDirectory {} {
    set dir [get_directory -p "Scan which folder?"]
    if {![string length $dir]} return
    
    set name [file tail $dir]
    fileset::fromDirectory::create $name $dir *

    registerNewFileset $name fromDirectory
    updateCurrentFileset
    return $name
}

proc supersearch::newfset {} {
    if {[catch newFileset]} return
    global supersearch currFileSet
    set supersearch(fileset) $currFileSet
}

proc shorten {str {len 40} {el 0}} {
    if {[set sl [string length $str]] > $len} {
	set hl [expr {$len - $el - 2}]
	set str "[string range $str 0 $hl]É[string range $str [expr {$sl - $el}] end]"
    }
    return $str
}

# ×××× Helpers for multi-line search ×××× #

proc supersearch::quoteTabNewline {str} {
    regsub -all "\r" $str "\\r" str
    regsub -all "\n" $str "\\n" str
    regsub -all "\t" $str "\\t" str
    return $str
}

proc supersearch::unquoteTabNewline {str} {
    while {[regsub -all {(^|[^\\]|(\\\\)+)\\r} $str "\\1\r" str]} {}
    while {[regsub -all {(^|[^\\]|(\\\\)+)\\n} $str "\\1\n" str]} {}
    while {[regsub -all {(^|[^\\]|(\\\\)+)\\t} $str "\\1\t" str]} {}
    return $str
}

proc supersearch::_findPatternNewLine {pat {start 0}} {
    global supersearch
    if {[regexp -start $start -indices -- "\[\\r\\n\]" $pat values]} {
	set likely [lindex $values 0]
	if {$supersearch(r) \
	  && [regexp {\[\^[\r\n]*$} [string range $pat $start $likely]]} {
	    while {1} {
		set char [string index $pat $likely]
		switch -- $char {
		    "\]" {
			return [_findPatternNewLine $pat [expr {$likely + 1}]]
		    }
		    "" {
			return -1
		    }
		}
		incr likely
	    }
	    return -1
	}
	return $likely
    } else {
	return -1
    }
}

proc supersearch::parseSearch {args} {
    global supersearch supersearchmodeVars
    switch -- [llength $args] {
	0 {
	    set from [searchString]
	}
	1 {
	    set from [lindex $args 0]
	}
	default {
	    error "Too many args"
	}
    }
    set rcList {}
    set tmp $from
    while {[set rc [_findPatternNewLine $tmp 0]] != -1} {
	lappend rcList $rc
	set tmp [string range $tmp [expr {$rc + 1}] end]
    }
    set pre ""
    set post ""
    set rcFirst 0
    set regTail ""
    if {[llength $rcList] > 0} {
	set rc [lindex  $rcList 0]
	set post "\$"
	if {$supersearch(ignorespace)} {set post "\[ \t\]*$post"}
	if {$rc == 0} {
	    set pre "^"
	    if {$supersearch(ignorespace)} {set pre "$pre\[ \t\]*"}
	    if {[llength  $rcList] > 1} {
		set rc [lindex  $rcList 1]
		if {$rc == 0} {
		    set part ""
		} else { 
		    set part [string range $from 1 $rc]
		}
		set rcFirst 2
		set regTail [string range $from [expr {$rc + 2}] end]
	    } else { 
		set part [string range $from 1 end]
		set post ""
	    }
	} else { 
	    set part [string range $from 0 [expr {$rc - 1}]]
	    set rcFirst 1
	    set regTail [string range $from [expr {$rc + 1}] end]
	}
	set supersearch(singleline) 0
    } else { 
	set part $from
	set supersearch(singleline) 1
    }
    
    set part [supersearch::prepLine $part]
    set tmp $from
    if {!$supersearch(r)} {
	if {$supersearch(ignorespace)} {
	    set chr $supersearchmodeVars(checkSpacesAround)
	    set tmpf [regsub -all "\[ \t\]*($chr)\[ \t\]*" $tmp " \\1 " tmp]
	    set tmpf [regsub -- "^ " $tmp "" tmp]
	    set tmpf [regsub -- " $" $tmp "" tmp]
	    set tmp [quote::Regfind $tmp]
	    set tmpf [regsub -all "\[ \t\]+" $tmp "\[ \t\]*" tmp]
	} else {
	    set tmp [quote::Regfind $tmp]
        }
    } elseif {$supersearch(ignorespace)} {
	regsub -all {(\[([^\\]|\\[^r])*)\\r([^]]*\])} $tmp "\\1ÚþüÚ\\3" tmp
	regsub -all {(\[([^\\]|\\[^t])*)\\t([^]]*\])} $tmp "\\1ÚüþÚ\\3" tmp
	regsub -all {(\[([^\\]|\\[^n])*)\\n([^]]*\])} $tmp "\\1ÚüüÚ\\3" tmp
	regsub -all {(\[[^ ]*) ([^]]*\])} $tmp "\\1ÚþÚ\\2" tmp
	regsub -all {(\[[^ ]*)	([^]]*\])} $tmp "\\1ÚüÚ\\2" tmp
	set tmpf [regsub -all "\[ \t\]*(\r|\n)\[ \t\]*" $tmp " \\1 " tmp]
	set tmpf [regsub -- "^ " $tmp "" tmp]
	set tmpf [regsub -- " $" $tmp "" tmp]
	set tmpf [regsub -all "\[ \t\]+" $tmp "\[ \t\]*" tmp]
	regsub -all {(\[([^Ú]*|Ú[^þ]*|Úþ[^ü]*|Úþü[^Ú]*))ÚþüÚ([^]]*\])} \
	  $tmp "\\1\\r\\3" tmp	
	regsub -all {(\[([^Ú]*|Ú[^ü]*|Úü[^þ]*|Úüþ[^Ú]*))ÚüþÚ([^]]*\])} \
	  $tmp "\\1\\t\\3" tmp	
	regsub -all {(\[([^Ú]*|Ú[^ü]*|Úü[^ü]*|Úüü[^Ú]*))ÚüüÚ([^]]*\])} \
	  $tmp "\\1\\n\\3" tmp	
	regsub -all {(\[([^Ú]*|Ú[^þ]*|Úþ[^Ú]*))ÚþÚ([^]]*\])} $tmp "\\1 \\3" tmp	
	regsub -all {(\[([^Ú]*|Ú[^ü]*|Úü[^Ú]*))ÚüÚ([^]]*\])} $tmp "\\1	\\3" tmp	
    }
    set supersearch(rcList) $rcList
    set supersearch(rcFirst) $rcFirst
    set supersearch(firstLine) $pre$part$post
    set supersearch(regTail) $regTail
    set supersearch(reg) $tmp
}

proc supersearch::prepLine {str} {
    global supersearch supersearchmodeVars
    set tmp $str
    if {!$supersearch(r)} {
	set tmp [quote::Regfind $str]
	if {$supersearch(ignorespace)} {
	    set chr $supersearchmodeVars(checkSpacesAround)
	    set tmpf [regsub -all "\[ \t\]*($chr)\[ \t\]*" $str " \\1 " tmp]
	    set tmp "[string trim $tmp]"
	    set tmp [quote::Regfind $tmp]
	    set tmpf [regsub -all "\[ \t\]+" $tmp "\[ \t\]*" tmp]
	}
    } elseif {$supersearch(ignorespace)} {
	regsub -all {(\[[^ ]*) ([^]]*\])} $tmp "\\1ÚþþÚ\\2" tmp
	regsub -all {(\[[^	]*)	([^]]*\])} $tmp "\\1ÚüüÚ\\2" tmp
	set tmpf [regsub -all "\[ \t\]+" $tmp "\[ \t\]*" tmp]
	regsub -all {(\[([^Ú]*|Ú[^ü]*|Úü[^ü]*|Úüü[^Ú]*))ÚüüÚ([^]]*\])} \
	  $tmp "\\1	\\3" tmp	
	regsub -all {(\[([^Ú]*|Ú[^þ]*|Úþ[^þ]*|Úþþ[^Ú]*))ÚþþÚ([^]]*\])} \
	  $tmp "\\1 \\3" tmp	
    }
    # This used to return '($tmp)', but we must not add more parentheses
    # like that, because the regexp pattern may itself contain
    # backreferences and things like that which are designed to match
    # a particular set of parentheses!  (e.g. 'find repeated words').
    return $tmp
}

# New dialog -- once discussed and debugged, will replace the one
# above, assuming Alpha 8/X can cope with it.
if {$alpha::platform ne "tk"} {return}

proc supersearch::find {} {
    global supersearch searchPattern supersearchmodeVars currFileSet \
      recentSearches alpha::platform

    if {![llength [winNames -f]]} {
	# If there's no window, we don't have single file search, 
	# and so the first popup menu item is always the one we need.
	set multiPopup 0
    } else {
	# 0 = top window, 1 = multi
	set multiPopup $supersearch(multi)
    }
    set actionPopup 0
    
    if {!$supersearchmodeVars(separateSearchAndCurrentFileset) \
      || ![info exists supersearch(fileset)] \
      || ($supersearch(fileset) == "")} {
	set supersearch(fileset) $currFileSet
    }

    set loop 0
    
    while 1 {
	# Pre-calculate the patterns.
	set patts {}
	if {[info exists recentSearches] && [llength $recentSearches]} {
	    foreach rs $recentSearches {
		if {[lindex $rs 3]} {
		    lappend patts "\"[lindex $rs 0]\" to \"[lindex $rs 1]\""
		} else {
		    lappend patts "\"[lindex $rs 0]\" "
		}
	    }
	    lappend patts "-"
	}
	eval lappend patts [array names searchPattern]
	# Do we have a window?
	set haveWin [expr {[win::Current] != ""}]
	
	set y 15
	set args {}
	lappend args -T "Search"
	incr y 13
	set yt $y
	if {!$supersearch(r)} {
	    set supersearch(search) [searchString]
	    set supersearch(replace) [replaceString]
	} else {
	    set supersearch(search) [supersearch::quoteTabNewline [searchString]]
	    set supersearch(replace) [supersearch::quoteTabNewline [replaceString]]
	}
	eval lappend args [dialog::textedit "Search for:" \
	  $supersearch(search) 20 y 27 $supersearchmodeVars(boxHeights)]
	set y $yt
	eval lappend args [dialog::textedit "Replace with:" \
	  $supersearch(replace) 320 y 27 $supersearchmodeVars(boxHeights)]
	incr y 5
	set yr $y
	set yTopOfBottom $y
	# Put in the buttons at top.
	set y 4
	set buttons {}
	set button_help {}
	set yrplug $y
	supersearch::executePlugins 2
	
	### RIGHT HAND SIDE OF DIALOG ###

	# Single/multi files
	set y $yTopOfBottom
	set x 245
	# Popup-choices depend on whether we have a window
	if {$haveWin} {
	    set ftypes [list "Top Window" "Multiple files"]
	} else {
	    set ftypes [list "Multiple files"]
	}
	eval lappend args \
	  [dialog::menu $x y $ftypes [lindex $ftypes $multiPopup] 130] 
	set yr2 $y
	set yr $y
	
	# Single window options
	incr y 8
	if {$supersearchmodeVars(smartInSelectionFlag)} {
	    if {([win::Current] != "") && ([string length [getSelect]] - \
	      [string length $supersearch(search)] > 80)} {
		set select 1
	    } else {
		set select 0
	    }
	} else {
	    set select $supersearch(inselection)
	}
	lappend args -n "Top Window"
	
	# If there's no window/no selection move irrelevant checkboxes
	# offscreen.
	eval lappend args \
	  [dialog::checkbox "From current pos" $supersearch(f) \
	  [expr {$haveWin ? $x : 3000}] y] \
	  [dialog::checkbox "Circular " $supersearch(circular) \
	  [expr {$haveWin ? $x : 3000}] y] \
	  [dialog::checkbox "Not in comments" $supersearch(notInComments) \
	  [expr {$haveWin ? $x : 3000}] y] \
	  [dialog::checkbox "In selection only" $select \
	  [expr {$haveWin && ([string length [getSelect]] > 0) ? $x : 3000}] y]
	
	# Multi-window options
	lappend args -n "Multiple files"
	set y $yr2
	eval lappend args [dialog::checkbox "Exclude matches" \
	  $supersearch(exclude) 245 y]
	set y $yr
	incr y 25
	eval lappend args \
	  [dialog::text "Select a single fileset:" $x y]
	incr x 10
	# align button with text 
	set y $yr
	incr y 25
	eval lappend args \
	  [dialog::menu [expr {$x +140}] y \
	  [lsort -dictionary [fileset::names]] \
	  $supersearch(fileset) 200]
	set yr3 $y
	incr y 2
	set delx 0
	if {[llength $supersearch(multifsets)]} {
	    eval lappend args \
	      [dialog::checkbox "or pick" $supersearch(ismultifset) $x y]
	    incr x 12
	    incr delx -11
	} else {
	    # we don't want the check box, so we move it way offscreen.
	    eval lappend args \
	      [dialog::text "Or pick" $x y]
	    set y $yr3
	    eval lappend args \
	      [dialog::checkbox "or pick" $supersearch(ismultifset) \
	      [expr {$x -1000}] y]
	    incr x
	}
	set y $yr3
	eval lappend args \
	  [dialog::button "Multiple Filesets:" [expr {$x +55}] y] \
	  [dialog::text [join $supersearch(multifsets) ", "] $x y 50]
	set y $yr2
	eval lappend args \
	  [dialog::button "New filesetÉ" [expr {$x +142 + $delx}] y \
	  "Dir scanÉ" [expr {$x +264 + $delx}] y]

	
	lappend args -n {}

	### LEFT HAND SIDE OF DIALOG ###
	
	# Put in actions and patterns
	set y $yTopOfBottom
	eval lappend args \
	  [dialog::tab 20 y {Action Patterns} $actionPopup 215 146] 
	set yt $y
	set y 5
	lappend args -in Action
	eval lappend args \
	  [dialog::checkbox "Ignore Case" $supersearch(i) 5 y] \
	  [dialog::checkbox "Regexp" $supersearch(r) 5 y]
	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend args -tag regexp
	}
	eval lappend args \
	  [dialog::checkbox "Batch" $supersearch(b) 5 y]
	set my $y
	set y 5
	eval lappend args \
	  [dialog::checkbox "Word Match" $supersearch(m) 107 y] \
	  [dialog::checkbox "Keep Capitals" $supersearch(casereplace) 107 y] \
	  [dialog::checkbox "Ignore Spaces" $supersearch(ignorespace) 107 y]
	set y $my
	incr y 2
	eval lappend args [dialog::button "Search" 5 y "Don't Search" 77 y]
	# Make the 'Search' button the default
	set args [linsert $args end-10 "-default"]
	# 10 pixel vertical spacing between buttons (we get 6 automatically)
	incr y 4
	eval lappend args [dialog::button "Replace All" 5 y "Cancel" 110 y]
	set ym [expr {$y + 12 + $yt}]
	
	# Put in patterns
	set y 5
	set x 10
	eval lappend args \
	  [list -in "Patterns"] \
	  [dialog::button "Save this patternÉ" $x y] \
	  [dialog::menu $x y $patts $supersearch(pattern) 195]

	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend args -action \
	      [list supersearch::usePatternFromPopup {+0 1 3 regexp}]
	    # Just move this a long way offscreen
	    set ytemp $y
	    eval lappend args \
	      [dialog::button "Use pattern from menu" [expr {$x+1000}] y]
	    set y $ytemp
	} else {
	    eval lappend args \
	      [dialog::button "Use pattern from menu" $x y]
	}

	eval lappend args \
	  [dialog::button "Forget pattern" $x y]

	lappend args -n {}
	set y $yrplug
	eval lappend args [dialog::button "PrefsÉ" 535 y]
	set y $yrplug
	eval lappend args [dialog::button "Regexp HelpÉ" 10 y]

	set help [list "Enter the search string here (for regexp\
	  searches, you can add '(?n)' to make '.' never match a newline)" \
	  "Enter the replace string here"]
	eval lappend help $button_help
	lappend help \
	  "Choose between single and multiple file searches." \
	  "To start the search at the current cursor position,\
	  click this box.||To search from the beginning of the document,\
	  click this box" \
	  "To continue searching from the beginning after reaching the end\
	  of the document, click this box.||To stop searching at the end\
	  of the document, click this box." \
	  "To ignore matches in commented out text,\
	  click this box||To search the entire text, click this box." \
	  "To search just in the current highlighted text,\
	  click this box||To search the entire text, click this box." \
	  "Only report files which do NOT match the given pattern.  This\
	  is ignored if you attempt to 'Replace'||Only report files which\
	  do NOT match the given pattern.  This is ignored if you attempt\
	  to 'Replace'" \
	  "Select the fileset in which to search." \
	  "To search more than one fileset, use the 'Multiple filesets'\
	  button and click this box||To search just a single fileset,\
	  click this box." \
	  "Click here to select more than one fileset in which to search." \
	  "Click here to create a new fileset" \
	  "Click here to scan a particular directory." \
	  "Switch between actions and pattern manipulation." \
	  "To ignore upper/lower case differences when searching,\
	  click this box.||To use exact, case-sensitive matches only,\
	  click this box" \
	  "To interpret the above search string as a regular expression,\
	  click this box.||To match the above search string literally,\
	  click this box." \
	  "To display all possible matches in a separate control window,\
	  click this box.||To highlight each match individually as it is\
	  found, click this box." \
	  "To match only entire words,\
	  click this box.||To allow any sequence of characters which matches\
	  the above search string, click this box." \
	  "To replace 'foo' with 'bar' and 'Foo' with 'Bar' with only one\
	  search,\
	  click this box.||To always replace with the exact, given\
	  replacement string, click this box" \
	  "To ignore whitespace differences when searching,\
	  click this box.||To use exact, character and space matching only,\
	  click this box" \
	  "Click here to begin the search" \
	  "Click here to remember my settings, but not actually search" \
	  "Click here to replace all matches at once without my intervention" \
	  "Click here to discard any changes you've made to the settings." \
	  "Save the search and replace strings above for future use."
	if {[alpha::package vsatisfies -loose [dialog::coreVersion] 2.1]} {
	    lappend help \
	      "Select a pattern from this menu and it will be entered into\
	      the search fields above."
	} else {
	    lappend help \
	      "Select a pattern from this menu and then click the button below."
	}

	lappend help \
	  "Use the pattern currently selected in this popup menu." \
	  "Permanently remove the pattern selected in the menu." \
	  "Click here to edit the search preferences." \
	  "Click here to view help on regexp searches."

	
	if {$alpha::platform eq "tk"} {
	    lappend args -geometryvariable geometry
	}
	lappend args -help $help
	set args [linsert $args 0 -w 610 -h $ym]
	set res [eval [list dialog] $args]
	set loop 1
	
	if {[lindex $res end-6]} {
	    # Cancel
	    status::msg "Cancelled search"
	    return
	}
	# get search, replace strings.
	set i 0
	foreach text {search replace} {
	    set supersearch($text) [lindex $res $i]
	    incr i
	}
	
	# get top buttons
	foreach {j_start blist} \
	  [list $i $buttons \
	  [expr {[llength $res] - 2}] [list prefs regexpHelp]] {
	    set j $j_start
	    foreach but $blist {
		if {[lindex $res $j]} {
		    set button $but
		    break
		}
		incr j
	    }
	}
	incr i [llength $buttons]

	### Right side of dialog ###
	
	# Remember which of the right-side popup menu items was
	# foremost.
	set multiPopup [lsearch -exact $ftypes [lindex $res $i]]
	if {[lindex $res $i] == "Top Window"} {
	    set supersearch(multi) 0
	    set supersearch(f) [lindex $res [incr i]]
	    set newCircular [lindex $res [incr i]]
	    if {$supersearch(circular) != $newCircular} {
		set supersearch(circular) $newCircular
		prefs::modified supersearch(circular)
	    }
	    set supersearch(notInComments) [lindex $res [incr i]]
	    set supersearch(inselection) [lindex $res [incr i]]
	    if {$supersearch(inselection)} {
		if {[pos::compare [getPos] <= [selEnd]]} {
		    set supersearch(start) [getPos]
		    set supersearch(end) [selEnd]
		} else {
		    set supersearch(start) [selEnd]
		    set supersearch(end) [getPos]
		}
	    } 
	    # skip over the multiple files results
	    incr i 7
	} elseif {[lindex $res $i] == "Multiple files"} {
	    set supersearch(multi) 1
	    # This will be over-ridden the moment we start
	    # a search, but if we hit 'Don't Search', then
	    # there should be no files.
	    set supersearch(numfiles) -1
	    set supersearch(f) [lindex $res [incr i]]
	    set newCircular [lindex $res [incr i]]
	    if {$supersearch(circular) != $newCircular} {
		set supersearch(circular) $newCircular
		prefs::modified supersearch(circular)
	    }
	    # Not supported for multi-search
	    set supersearch(notInComments) 0 ; incr i
	    set supersearch(inselection) [lindex $res [incr i]]
	    
	    # Exclude flag to find non-matches.
	    set supersearch(exclude) [lindex $res [incr i]]

	    # ignore multi-fset for the moment
	    set supersearch(fileset) [lindex $res [incr i]]
	    set supersearch(ismultifset) [lindex $res [incr i]]
	    if {[lindex $res [incr i]]} {set button multifset }
	    if {[lindex $res [incr i]]} {set button newfset }
	    if {[lindex $res [incr i]]} {set button dirscan }
	    incr i
	} else {
	    error "Bad dialog results: [lindex $res $i]"
	}

	### Left side of dialog ###

	# Just double-check all our 'incr i's have worked out ok,
	# and remember whether 'Action' or 'Patterns' was showing
	set actionPopup [lindex $res $i]
	if {[lsearch -exact {Action Patterns} $actionPopup] == -1} {
	    error "Bad first popup [lindex $res $i], at [lrange $res $i end]"
	}
	incr i
	
	# Get the normal action flags
	foreach text {i r b m casereplace ignorespace} {
	    set supersearch($text) [lindex $res $i]
	    incr i
	}

	if {!$supersearch(r)} {
	    searchString $supersearch(search)
	    replaceString $supersearch(replace)
	} else {
	    searchString [supersearch::unquoteTabNewline $supersearch(search)]
	    replaceString [supersearch::unquoteTabNewline $supersearch(replace)]
	}
	
	# Get normal action buttons
	set j $i
	set blist [list search dontSearch replaceAll cancel]
	foreach but $blist {
	    if {[lindex $res $j]} {
		set button $but
		break
	    }
	    incr j
	}
	incr i [llength $blist]
	
	# Handle pattern results: save, popup, forget, and on Alpha 8/X
	# the 'use pattern' item (on Alphatk this button is moved
	# offscreen).
	set supersearch(pattern) [lindex $res [expr {$i +1}]]
	if {[lindex $res $i]} { supersearch::storePattern ; continue}
	incr i
	if {[lindex $res [incr i]]} {supersearch::usePattern ; continue}
	if {[lindex $res [incr i]]} {supersearch::forgetPattern ; continue}
	
	if {[info exists button]} {
	    if {[lsearch -exact "multifset newfset dirscan regexpHelp" $button] != -1} {
		supersearch::$button 
		continue
	    } elseif {$button == "prefs"} {
		supersearch::prefs
	    } elseif {[lsearch -exact $buttons $button] != -1} {
		supersearch::executePlugins 3 $button
	    } else {
		if {$button == "search"} { 
		    set button "generalSearch"
		    if {$supersearch(r)} {
			if {[catch {regexp -- [searchString] dummy} err]} {
			    alertnote "The regexp is not valid: $err"
			    continue
			}
		    }
		    supersearch::recentPattern \
		      [searchString] [replaceString] $supersearch(r) 0
		} elseif {$button == "replaceAll"} {
		    if {$supersearch(r)} {
			if {[catch {regexp -- [searchString] dummy} err]} {
			    alertnote "The regexp is not valid: $err"
			    continue
			}
		    }
		    supersearch::recentPattern \
		      [searchString] [replaceString] $supersearch(r) 1
		    set button "reallyReplaceAll" 
		}
		supersearch::parseSearch
		supersearch::$button
		return
	    }
	    unset button
	}
	
	set loop 0
	# big while loop
    }
}
