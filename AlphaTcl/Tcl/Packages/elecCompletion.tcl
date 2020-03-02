## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # (Formerly Vince's Additions - an extension package for Alpha)
 # 
 # FILE: "elecCompletion.tcl"
 #                                          created: 07/24/1997 {06:03:56 pm}
 #                                      last update: 03/21/2006 {02:07:37 PM}
 #
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #      
 # Copyright (c) 1997-2006 Vince Darley.
 # 
 # Distributed under a Tcl style license.  
 # 
 # This package is not actively improved any more, so if you wish to make
 # improvements, feel free to take it over.
 # 
 # ===========================================================================
 ##

alpha::feature elecCompletions 9.1.3 "global-only" {
    # Create the "Electric Completions" menu
    menu::buildProc electricCompletions menu::buildCompletionsMenu
    proc menu::buildCompletionsMenu {} {
	set menuList [list \
	  "viewGlobalCompletionsÉ"      \
	  "addGlobalCompletionsÉ"       \
	  "editGlobalCompletionsÉ"      \
	  "removeGlobalCompletionsÉ"    \
	  "(-"                          \
	  "completionsHelp"             \
	  ]
	return [list build $menuList completion::menuProc {} electricCompletions]
    }
} {
    # Insert the menu into "Config > Packages".  
    menu::insert preferences submenu "(-)" electricCompletions
    # Insert items into the Mode Prefs menu.
    menu::insert mode items end "completionsTutorial" "editCompletions" 
    # load completion code for a mode the first time that mode is used
    hook::register mode::init completion::load "*"
    namespace eval completion {}
    completion::initialise
} {
    # De-activation script
    menu::uninsert preferences submenu "(-)" electricCompletions
    menu::uninsert mode items end "completionsTutorial" "editCompletions"
    hook::deregister mode::init completion::load "*"
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} uninstall {
    this-file
} help {
    file "Electrics Help"
}

proc elecCompletions.tcl {} {}

namespace eval completion {}

## 
 # --------------------------------------------------------------------------
 # 
 # "completion::initialise" --
 # 
 # If we're turned on in the middle of an editing session, we'll need to
 # load up completions code for those modes already loaded.  This is
 # required due to the semantics of the mode::init hook.  There may be a
 # better overall design in AlphaTclCore we could use to resolve this.
 # 
 # --------------------------------------------------------------------------
 ##

proc completion::initialise {} {
    foreach m [mode::listAllLoaded] {
	catch {completion::load $m}
    }
}

proc completion::load {{m ""}} {
    if {$m == ""} {
	global mode
	set m $mode
	if {$m == ""} { return }
    }
    global HOME
    set f [file join $HOME Tcl Completions "${m}Completions.tcl"]
    if {[file exists $f]} {
	status::msg "loading [file tail $f]É"
	namespace eval ::${m}::Completion {}
	uplevel \#0 [list source $f]
	status::msg "loading [file tail $f]Édone"
    }
}

# ===========================================================================
# 
# ×××× Electric Completions menu ×××× #
# 
# Allows users to define their own global completions without having to
# modify any prefs.tcl files.
# 
# Contributed by Craig Barton Upright.
# 

# Just so we have one!
set userCompletions(date) {×kill0×[lindex [mtime [now]] 0]}

proc completion::menuProc {menu item} {
    if {$item == "completionsHelp"} {
	package::helpWindow "elecCompletions"
    } else {
	completion::$item
    } 
}

proc completion::viewGlobalCompletions {} {
    
    global mode userCompletions
    
    set windows [winNames]
    foreach w $windows {
	# Close any open "* Completions *" windows.
	if {[regexp "\\* Completions \\*" [win::StripCount $w]]} {
	    bringToFront $w
	    killWindow
	}
    }
    new -n "* Completions *" -text [listArray userCompletions] -m $mode
    # if 'shrinkWindow' is loaded, call it to trim the output window.
    catch {
	goto [maxPos] ; insertText "\r"
	selectAll     ; sortLines 
    }
    goto [minPos]
    insertText "Use the \"Edit Completions\" \rmenu item to re-define them.\r\r"
    catch {shrinkWindow 2}
    winReadOnly
    status::msg "" 
    
}

proc completion::addGlobalCompletions {{title ""} {hint ""} {completion "×kill0"}} {
    
    set finish [completion::addCompletionsDialog "" $hint $completion]
    # Offer the dialog again to add more.
    set title "Create another Completion, or press Finish:"
    while {$finish != "1"} {
	set finish [completion::addCompletionsDialog $title "" $completion]
    }
    completion::viewGlobalCompletions
}

proc completion::addCompletionsDialog {{title ""} {hint ""} {completion "×kill0"}} {
    
    global userCompletions
    
    if {$title == ""} {
	set title "Create a new Completion, or redefine an existing one:"
    } 
    set y 10
    set aCD [list -T $title]
    set yb 20
    set Completion "Completion (×kill0 deletes hint) :" 
    eval lappend aCD [dialog::button   "Finish"                    300 yb   ]
    eval lappend aCD [dialog::button   "More"                      300 yb   ]
    eval lappend aCD [dialog::button   "Cancel"                    300 yb   ]
    if {$hint == ""} {
	eval lappend aCD [dialog::textedit "Hint :" $hint           10  y 25]
    } else {
	eval lappend aCD [dialog::text     "Hint :"                 10  y   ]
	eval lappend aCD [dialog::menu 10 y $hint $hint 200                 ]
    } 
    eval lappend aCD [dialog::textedit $Completion $completion      10  y 25]
    incr y 20
    set result [eval dialog -w 380 -h $y $aCD]
    if {[lindex $result 2]} {
	# User pressed "Cancel'
	error "cancel"
    }
    set finish     [lindex $result 0]
    set hint       [string trim [lindex $result 3]]
    set completion [lindex $result 4]
    if {$hint != "" && $completion != ""} {
	set userCompletions($hint) $completion
	prefs::addArrayElement userCompletions $hint $completion
	status::msg "\"$hint -- $completion\" has been added."
	return $finish
    } elseif {$finish == "1"} {
	return $finish
    } else {
	error "Cancelled -- one of the dialog fields was empty."
    } 
}

proc completion::editGlobalCompletions {} {
    
    global userCompletions
    
    set hint [listpick -p "Select a hint to edit:" \
      [lsort -dictionary [array names userCompletions]]]
    set completion $userCompletions($hint)
    set title "Edit the \"$hint\" correction:"
    set finish [completion::addCompletionsDialog $title $hint $completion]
    # Offer the dialog again to add more.
    while {$finish != "1"} {
	set hint [listpick -p \
	  "Select another hint to edit, or Cancel:" \
	  [array names userCompletions]]
	set completion $userCompletions($hint)
	set title "Edit the \"$hint\" completion"
	set finish [completion::addCompletionsDialog $title $hint $completion]
    }
    completion::viewGlobalCompletions
}

proc completion::removeGlobalCompletions {{removeList ""}} {
    
    global userCompletions
    
    if {$removeList == ""} {
	# First list the user defined completions.  We remove "date"
	set userHints [array names userCompletions]
	set dateSpot [lsearch $userHints date]
	if {$dateSpot != "-1"} {
	    set userHints [lreplace $userHints $dateSpot $dateSpot]
	} 
	if {[llength $userHints] == "0"} {
	    status::msg "Cancelled -- there are no user defined completions to remove."
	    return
	} 
	set removeList [listpick -l -p "Select some Hints to remove:" \
	  [lunique $userHints]]
    } 
    foreach hint $removeList {
	# Then remove it from arrdefs.tcl
	catch {prefs::removeArrayElement userCompletions $hint}
	catch {unset userCompletions($hint)}
    }
    completion::viewGlobalCompletions
}

# ×××× ---------------- ×××× #

# ×××× Completions ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "completion::user" --
 # 
 # A user completion is used for small mode-independent snippets, like your
 # email address, name etc.
 #
 # For instance I have the following defined:
 #       
 #   set userCompletions(vmd) "×kill0Vince Darley"
 #   set userCompletions(www) "×kill0<[icGetPref WWWHomePage]>"
 #   set userCompletions(e-)  "×kill0<[icGetPref Email]>"
 #   
 # Here '×kill0' is a control sequence which means kill exactly what I just
 # typed before carrying out this completion. 
 # 
 # --------------------------------------------------------------------------
 ##

# ensure old version loaded:
catch "completion::user"

proc completion::user {{cmd ""}} {
    if {![string length $cmd]} {set cmd [completion::lastWord]}
    if {[containsSpace $cmd]}  {return 0}
    
    return [elec::findCmd $cmd userCompletions] 
}

## 
 # --------------------------------------------------------------------------
 # 
 # "completion::cmd" --
 # 
 # General purpose proc for extending a given command to its full extent in
 # a mode-dependent fashion.  If we hit a unique match, we call
 # '${mode}completion::Electric'; if we can extend, we do so, and set
 # things up so the calling procedure '${mode}completion::Cmd' will be
 # called if the user tries to cmd-Tab again; if we don't recognise
 # anything, we return 0
 #       
 # We normally use the list ${m}cmds to look for completions, but the
 # caller can supply a different name.  This is useful to prioritise lists,
 # so we first call with one, then another,...  I currently use this
 # feature for TeX-completions, in which I call with a second list,
 # containing fake commands, which expand into environments.
 #  
 # --------------------------------------------------------------------------
 ##

proc completion::cmd { {cmd ""} {listExt "cmds"} {prematch ""}} {
    global mode
    if {![string length $cmd]} { 
	set cmd [completion::lastWord]
	# if there's any whitespace in the command then it's no good to us
	if {[containsSpace $cmd]} { return 0 }
    }
    
    # do an electric if we already match exactly
    global ${mode}electrics
    if {[info exists ${mode}electrics($cmd)]} {
	return [completion ${mode} Electric "${prematch}${cmd}"]
    }
    if {[llength [set matches [completion::fromList $cmd ${mode}${listExt}]]] == 0} {
	return 0
    } else {
	return [completion::matchUtil Cmd $cmd $matches $prematch]
    }
}

proc completion::matchUtil {proc what matches {prematch ""}} {
    global mode
    if {[llength $matches] == 0} { return 0 }
    set match [completion::Find $what $matches]
    if {[string length $match]} {
	# we completed or cancelled, so move on
	if { $match == 1 } {
	    return 1
	} else {
	    return [completion $mode Electric "${prematch}${match}"]
	}
    } else {
	# TO DO fix this.  The completion::already proc was removed and
	# in any case ignored 'proc' we need to call 
	# completion::action -repeatCommand instead.
	#completion::already $proc
	completion::reset
	return 1
    }
}

## 
 # --------------------------------------------------------------------------
 #       
 # "completion::ensemble" --
 #      
 # Complete and do electrics for commands which have two parts separated by
 # a space.  Very useful for Tcl's "string compare ..."  etc. 
 # 
 # --------------------------------------------------------------------------
 ##

proc completion::ensemble {} {
    global mode
    set lastword [completion::lastTwoWords prevword]
    set prevword [string trim $prevword]
    # Need catch to avoid namespace problems
    if {[catch {global ${mode}${prevword}cmds}] || ![info exists ${mode}${prevword}cmds]} {
	return 0
    } else {
	return [completion::cmd $lastword "${prevword}cmds" "${prevword} "]
    }
}

## 
 # --------------------------------------------------------------------------
 #       
 # "completion::electric" --
 #      
 # Given a command, and an optional list of defaults, check the command is
 # ok and if so try and insert an electric entry. 
 # 
 # --------------------------------------------------------------------------
 ##

proc completion::electric { {cmd ""} args } {
    global mode
    if {![string length $cmd]} { 
        set cmd [completion::lastWord] 
        # only check for space if we're doing it
        if {[containsSpace $cmd]} {return 0}
    }
    
    return [eval [list elec::findCmd $cmd ${mode}electrics] $args]
}

## 
 # --------------------------------------------------------------------------
 #       
 # "completion::contraction" --
 #      
 # Complete and do electrics for commands which have two parts separated by
 # a apostrophe.  Useful for making shortcuts to things.  ex: s'c Tcl's
 # "string compare ..."  etc. 
 # 
 # --------------------------------------------------------------------------
 ##

proc completion::contraction {} {
    set lastword [completion::lastTwoWords hint]
    if {![regexp "'\$" $hint]} {return 0}
    append hint $lastword
    return [completion::electric $hint]
}

namespace eval elec {}

## 
 # --------------------------------------------------------------------------
 # 
 # "elec::findCmd" --
 # 
 # General purpose proc for extending a command in some predetermined
 # fashion (such as mapping 'for' to a template 'for (;;)É').  Mode
 # specific procedures may use this if desired.  The given command is
 # looked up in the given array '$arrayn', and if there is an entry, some
 # electric procedure happens.  By default, if an entry is '0', then '0' is
 # returned (which can be used by the calling procedure to take some other
 # action, usually more sophisticated such as TeX-ref- completion), and if
 # the entry is an integer corresponding to a list element of the list
 # 'args', then that element is inserted.  In this case list elements start
 # with '1' (because zero has a special meaning).  Template stops in the
 # electric completion are marked by pairs of bullets '¥¥'.  If there is
 # any text between the bullets, that can be used to inform the user of
 # what ought to go there.  All strings must contain at least one such
 # template stop, to which the insertion point moves.
 # 
 # '$arrayn' ought not to be a large array or this proc may be slow.  (we
 # first look for an exact array element match $arrayn($cmd), but if that
 # fails we look for a glob'ed match)
 #  
 # The array element may contain control sequences.  These start with '×',
 # and may be followed by:
 #  
 #   kill0 --- delete the string which triggered this template before
 #                inserting anything.
 #                
 #   killN --- delete all except N characters of the string.
 #  
 #   N --- use the N'th element of 'args' for the template.
 #  
 #   [ --- the string must be evaluated first (usually triggering some proc
 #        which perhaps interacts with the user a bit)
 #  
 #   È --- an indirection; use the template insertion corresponding to
 #        the given text item instead.
 #        
 # In order to provide backward compatiblity of this proc with any new
 # control sequences that may be developed, any 'unknown' control sequence
 # is just deleted, a package that deals with the new sequences thus has to
 # overide this proc in order to make the now sequences functionality
 # available.
 #  
 # So, what are some of the possible future control sequences?  Well, I've
 # played with;
 #  
 #         sequences bound to a stop
 #  
 #  Ç --- an extended prompt, provides a longer, more pedalogical explanation 
 #        for a stop that the curt, fill in 'xxx' in the statusline.
 #  ¦ --- a name that acts as an index into an array of code snippets, so a 
 #        bit of code can be executed when visiting a stop, perhaps aiding 
 #        in filling in options, validating entries, or anything else that 
 #        makes sense.
 #  ¿ --- marks a stop of such an obvious nature, that the marking of the 
 #        stop with a dot, or and in-text prompt is superflous. In fact, such 
 #        stops often have existing statements dragged into their position, 
 #        so leaving them unmarked has a speed advantage. Perhaps this 
 #        action is best toggled depending on a flag value.
 #        
 #   Any stop that falls in the above class, will occur after any regular
 #   prompting text, and should trigger the removal of itself and any other
 #   characters up until the occurrence of the stop ending bullet.  That
 #   can be acomplished in one of two ways, here with a regsub of this
 #   form: regsub -all {¥([^×]*)×[^¥]+¥} <template> {¥\1¥} result or by
 #   applying the regsub to the entire set of electrics for a mode as soon
 #   as its completions are loaded.  (first method implemented)
 #        
 #         sequences that occurr at the start of a template
 #           and apply to the template as a whole
 #  
 #  < --- means that certain conditions that must be meet by the text 
 #        proceeding where this template is to be inserted must be met 
 #        before the insertion is allowed, (e.g. a tcl command must be 
 #        proceeded by whitespace, a [, a ", or eval for the insertion 
 #        to be syntactically correct and thus , allowable)
 #        
 #  Sequences in this class will have to be of a single character, as will
 #  get rid of any unknown sequence by
 #  
 #    regsub {×[^k0-9È\[]} [string range <template 0 
 #      [string first ¥ <template>]] head set <template> $head
 #    append <template> rest
 #
 # Includes some fixes by Tom Fetherston.
 # --------------------------------------------------------------------------
 ##

proc elec::findCmd {cmd arrayn args} {
    if {[set action [elec::_findCmd $cmd $arrayn]] == ""} { return 0 }
    # We have the action; check for control sequences
    set deleteLen 0
    while {[string index $action 0] == "×"} {
        # Control sequence: kill, procedure or choice of default value?
        set action [string range $action 1 end]
        if { [string range $action 0 3] == "kill" } {
	    incr deleteLen [expr {[string length $cmd] + [string index $action 4]}]
            regsub -all "kill" [string range $action 5 end] $cmd action
        } elseif {[string index $action 0] == "\[" } {
            set action [subst $action]
        } elseif {[string index $action 0] == "È" } {
            set key [string range $action 1 end]
            global $arrayn
            set text [set ${arrayn}($key)]
            set action "×kill0${key}${text}" 
        } elseif {([scan $action %d idx]) \
          && (![ catch {lindex $args [expr {$idx-1}]} act]) } {
            set action $act
        } else {
            if {[info commands [set proc elec::action::[string index $action 1]]] eq $proc} {
                set action [$proc $action]
            } else {
                set action [string range $action 2 end]
            }
        }
    }
    # Then, we pull out any "bulleted-stop control sequences" that are
    # unknown to this version of elec::findCmd -trf
    regsub -all {¥([^×]*)×[^¥]+¥} $action {¥\1¥} action 
    completion::action -electric -delete $deleteLen -text $action
    # The idea here is to continue with other completions (return 0) if the
    # character before the insertion point is non white-space
    set cont [regexp -- {\W} [lookAt [pos::math [getPos] - 1]]]
    #global wordBreakPreface
    #set cont [regexp -- $wordBreakPreface [lookAt [pos::math [getPos] - 1]]]
    if {!$cont} {
        if {[isSelection]} {deleteText [getPos] [selEnd]}
        return 0
    } else {
        return 1
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "elec::_findCmd" --
 # 
 #  Find the electric command in the given array, or return ""
 #  
 # --------------------------------------------------------------------------
 ##

proc elec::_findCmd {cmd arrayn} {
    global $arrayn
    if {[info exists ${arrayn}($cmd)]} {
        return [set "${arrayn}($cmd)"]
    } else {
        if {[string first "*" [set elec_ar [array names $arrayn]]] != -1 } {
            # some of the array matches are glob'ed; we must go one at a time
            foreach elec $elec_ar {
                if {[string match $elec $cmd]} {
                    return [set "${arrayn}($elec)"]
                }
            }
        }
    }
    return ""
}

# ×××× ---------------- ×××× #

# ×××× Mode Completions, Tutorials ×××× #

proc mode::editCompletions {} {
    global HOME mode
    set f [file join ${HOME} Tcl Completions ${mode}Completions.tcl]
    if {[catch {file::openQuietly $f}]} {
        beep
        if {[askyesno "No completions exist for this mode. Do you want to create some?"] == "yes"} {
            close [open $f "w"]
            edit -c $f
            insertText {## 
 # This file will be sourced automatically, immediately after 
 # the _first_ time the file which defines its mode is sourced.
 # Use this file to declare completion items and procedures
 # for this mode.
 # 
 # Some common defaults are included below.
 ##

## 
 # These declare, in order, the names of the completion
 # procedures for this mode.  The actual procedure
 # must be named '${mode}Completion::${listItem}', unless
 # the item is 'completion::*' in which case that actual
 # procedure is called.  
 ##
set completions(<mode>) {contraction completion::cmd Ensemble completion::electric Var}

}\
 {# ×××× Data for <mode> completions ×××× #

# cmds to be completed to full length (no need for short ones)
set <mode>cmds { class default enum register return struct switch typedef volatile while }
# electrics
set <mode>electrics(for) " \{¥start¥\} \{¥test¥\} \{¥increment¥\} \{\r\t¥body¥\r\}\r¥¥"
set <mode>electrics(while) " \{¥test¥\} \{\r\t¥body¥\r\}\r¥¥"
# contractions
set <mode>electrics(s'c) "×Èstring compare"
set <mode>electrics(s'f) "×Èstring first"
}}}                     
}

proc mode::completionsTutorial {{m ""}} {

    global HOME mode

    if {($m eq "")} {
	set m $mode
    }
    set m [mode::getName $m 0]
    set M [mode::getName $m 1]

    set tName     [file join $HOME Tcl Completions "$m Tutorial"]
    set tutorials [glob -nocomplain -path $tName *]
    if {![llength $tutorials]} {
	alertnote "No tutorial exists for this mode."
	return
    }
    set n "* $M Electrics Tutorial *"
    set t [file::readAll [lindex $tutorials 0]]
    if {($m eq "Text")} {
	# Text Tutorial specific routine, adding a section at the end
	# with links to more tutorials.
	append t "\r\t  \t"
	append t "Additional mode specific Completions Tutorials:\r\r"
	set tDir [glob -dir [file join $HOME Tcl Completions] *Tutorial*.*]
	foreach tFile $tDir {append t "\r    \"[file tail $tFile]\"\r"}
    }
    new -n $n -text $t -m $m -shell 1
    goto [minPos]
    if {($m eq "Text")} {
	# Hyperise the window.
	help::markColourAndHyper
    } else {
	# A more limited version of the above.
	removeAllMarks
	catch {Text::MarkFile}
	# Hyperlink section marks for the current window, anything in double
	# quotes that starts with "# " (similar to html in-file-target.)
	 win::searchAndHyperise {"\# ([^\r\n\"]+)"} \
	   {editMark [win::Current] "\1"} 1 3 +3 -1
    }
    if {![catch {search -f 1 -r 1 -s {^\t  \t} [minPos]} match]} {
	goto [pos::prevLineStart [lindex $match 0]]
	insertToTop
    } else {
	refresh
    }
    Bind '`' vsp $m
    status::msg "Use the back-quote key ( ` ) to navigate completion examples."
    return
}

proc vsp {} {

    getWinInfo -w [win::Current] arr

    set pat {\* [-a-zA-Z0-9+ ]+ Tutorial \*}
    if {![regexp $pat [win::StripCount [win::CurrentTail]]]} {
	typeText "`"
	return
    } elseif {![catch {search -f 1 -r 1 -s {×|<>} [getPos]} match]} {
	eval selectText $match
	backSpace
	ring::clear
	centerRedraw
    } else {
	status::msg "There are no more diamonds to jump to in this window."
    }
}

## 
 # ==========================================================================
 #      
 # ×××× HISTORY ×××× #
 #                   
 #  modified by  rev   reason
 #  -------- --- ----- -----------
 #  08/03/96 VMD 1.0   original
 #  20/11/96 VMD 1.1   many, many improvements.
 #  24/02/97 VMD 1.2   added some support of trf's code, plus some fixes
 #  01/09/97 VMD 1.5   added 'completion::contraction' and improved g-elec.
 #  12/01/97 trf 1.6   added 'Tutorial Shell' stuff, bumped to 9.0b2
 #  12/02/97 trf 1.7   corrected corrections, bumped to 9.0b3.
 #  04/12/97 VMD 9.0.1 various fixes, better tcl8 compatibility
 #  10/19/00 cbu 9.0.4 Added 'Electric Completions' menu for global completions.
 #  04/08/01 cbu 9.0.5 Improved 'Electric Completions' menu dialogs.
 #  06/07/01 cbu 9.1   Changes to Mode Tutorials, different behavior for end
 #                       of completions cycle added to 'completions.tcl'.
 #                     Package is now a global-only feature, to allow for a
 #                       de-activation script.
 #  07/11/01 cbu 9.1.1 Removed dependency on -1.0 in 'completions.tcl".
 #  
 # ==========================================================================
 ##

# ===========================================================================
# 
# .