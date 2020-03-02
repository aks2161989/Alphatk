## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclContextualMenu.tcl"
 #                                          created: 09/11/2002 {05:28:12 pm}
 #                                      last update: 02/28/2006 {04:09:42 PM}
 # Description:
 # 
 # Provides support for the contextual menu in Tcl mode.  The preferences to
 # turn on/off the Tcl specific CM menu modules are defined in "tclMode.tcl".
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2002-2006  Craig Barton Upright, Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc tclContextualMenu.tcl {} {}

# Make sure that the "tclMode.tcl" file has been sourced.
tclMode.tcl

# ×××× Contextual Menu modules ×××× #

namespace eval Tcl {}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::cmContext" --
 # 
 # Determine the context of the "word" surrounding the CM click position.  We
 # want to know if it looks like a procedure, variable, or an array, and what
 # (if any) procedure contains the item.  Since [Tcl::buildTclProcsCMenu] and
 # [Tcl::buildTclVarsCMenu] both potentially call this, but either can be
 # turned off by the user, we avoid resetting the entire "cmInfo" array if
 # we've already collected the information for this position.  The array
 # entry "cmInfo(posM)" helps us know if the content of the window has
 # changed even if the positions look similar to what we've seen before.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::cmContext {} {
    
    global Shel::endPrompt alpha::CMArgs
    
    variable cmInfo

    set pos0 [lindex ${alpha::CMArgs} 0]
    set posC [contextualMenu::clickWord]
    set posM [maxPos]
    if {[llength [set posC [contextualMenu::clickWord]]]} {
	set txt0 [lindex [contextualMenu::clickWord] 0]
	set pos1 [lindex [contextualMenu::clickWord] 1]
	set pos2 [lindex [contextualMenu::clickWord] 2]
    } else {
        set txt0 ""
	set pos1 $pos0
	set pos2 $pos0
    }
    set txt1 [string trimleft $txt0 {$}]
    # Avoid unsetting/parsing if we've already done so for these positions.
    foreach item [list pos0 pos1 pos2 posM] {
	if {![info exists cmInfo($item)] || ($cmInfo($item) ne [set $item])} {
	    set reset 1
	    break
	}
    }
    if {![info exists cmInfo(context)] || [info exists reset]} {
	unset -nocomplain cmInfo
    } else {
        return $cmInfo(context)
    }
    # Determine if we're in a proc or namespace environment.
    set nameSpace ""
    set enclProc  ""
    if {([string range $txt1 0 1] eq "::")} {
	set nameSpace "::"
	set txt1 [string trimleft $txt1 :]
    } elseif {![catch {Tcl::enclosingProcName $pos0} procName]} {
	# We're in a procedure that has a namespace.
	set nameSpace [namespace qualifiers $procName]
	set enclProc  $procName
    } elseif {![catch {Tcl::enclosingNamespace $pos0} ns]} {
	# We're in some 'namespace ?opts?  ?args?'  environment
	set nameSpace $ns
    }
    set readOnly [win::getInfo [win::Current] read-only]
    # Save the information we've collected so far.
    foreach item [list pos0 pos1 pos2 posM txt1 nameSpace enclProc readOnly] {
	set cmInfo($item) [set $item]
    }
    # Perform some initial tests to determine the context.
    if {([string index $txt0 0] eq "$")} {
	return [set cmInfo(context) "variable"]
    }
    set txt2 [string trimright $txt1 ":"]
    # Create some regexp patterns.
    set arrayWords [list anymore donesearch exists get \
      names nextelement set size startsearch statistics unset]
    set arrayWords [join $arrayWords "|"]
    set varWords   [join [list global set unset variable] "|"]
    set infoWords1 [join [list exists globals locals vars] "|"]
    set infoWords2 [join [list args body default commands procs] "|"]
    if {[Tcl::isShellWindow] && [info exists Shel::endPrompt]} {
	set sEP ${Shel::endPrompt}
    } else {
	set sEP ""
    }
    set patBeg {(\$\{|(}
    set patEnd {)[\t ]+)}
    append pat1 $patBeg {array[\t ]+(} $arrayWords {)} $patEnd {$}
    append pat2 $patBeg $varWords $patEnd {([^\[]*)} {$}
    append pat3 $patBeg {info[\t ]+(} $infoWords1 {)} $patEnd {$}
    append pat4 $patBeg {info[\t ]+(} $infoWords2 {)} $patEnd {$}
    append pat5 {(eval[\t ]+)|([\[} "\\" $sEP {][\t ]*)$}
    # Try to figure out our current context.
    set txt3 [string trimleft [getText [pos::lineStart $pos0] $pos1]]
    if {[regexp $pat1 $txt3]} {
	# Must be an array.
	set context "array"
    } elseif {[regexp $pat2 $txt3] || [regexp $pat3 $txt3]} {
	# Looks like a variable name.
	set context "variable"
    } elseif {($txt3 eq "") || [regexp $pat4 $txt3] || [regexp $pat5 $txt3]} {
	# It looks like a procedure name.
	set context "procedure"
    } else {
	# Cannot tell.
	set context ""
    }
    return [set cmInfo(context) $context]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::buildTclProcsCMenu" --
 # 
 # If the current "word" looks like procedure name, we want to know if it is
 # a built-in Tcl or Alpha command, or if it is a defined/loadable procedure.
 # If we are in an enclosing procedure, then we have separate options for
 # this context as well.
 # 
 # If we don't have any options to offer to the user, then we attempt to
 # disable this entire CM menu module.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::buildTclProcsCMenu {args} {
    
    global contextualMenu::cmMenuName
    
    variable cmInfo
    variable interpCmd
    variable tcltkKeywords
    
    Tcl::cmContext
    set sourceFile ""
    foreach item [list txt1 nameSpace enclProc context readOnly] {
	set $item $cmInfo($item)
    }
    if {[string length $nameSpace]} {
	regsub {^::} $nameSpace "" nameSpace
	set queryWords [list "::${nameSpace}::${txt1}" "$txt1"]
    } else {
	set queryWords [list $txt1]
    }
    # Now we perform several tests to see what should be added to the menu.
    # Looks kind of busy here, but it goes pretty quick.
    for {set n 1} {($n <= 3)} {incr n} {
        set procName$n ""
    }
    set sourceFile ""
    set dim [expr {$readOnly ? "\(" : ""}]
    # Is the click word is in the context of a procedure?
    if {($context eq "procedure")} {
	# Is this a built-in Tcl command?
	foreach word $queryWords {
	    if {![string length $word]} {
		continue
	    }
	    if {[lsearch -sorted -dictionary $tcltkKeywords $word] > -1} {
		regsub "^:+" $word "" procName1
		lappend list1 "\(\"$procName1\" --" "View .html Help File" \
		  "View Tcl Commands File" "Display Command ArgsÉ"
		break
	    }
	}
	# Try to find the source file of the surrounding word.
	if {($procName1 eq "") && ($procName2 eq "")} {
	    foreach word $queryWords {
		if {![string length $word]} {
		    continue
		}
		if {[file exists [set sourceFile [procs::find $word]]]} {
		    regsub "^:+" $word "" procName2
		    lappend list2 "\(\"$procName2\" --" \
		      "Open Proc Source" "Display Proc SourceÉ" \
		      "Display Proc ArgsÉ" "Copy Args To Clipboard" \
		      "${dim}Insert Electric Template"
		    break
		} elseif {[llength [$interpCmd "info procs $word"]]} {
		    regsub "^:+" $word "" procName2
		    lappend list2 "\(\"$procName2\" --" \
		      "Display Proc ArgsÉ" "Copy Args To Clipboard" \
		      "${dim}Insert Electric Template"
		    break
		}
	    }
	}
    }
    # This section is for any enclosing proc.
    if {[string length $enclProc]} {
	regsub "^:+" $enclProc "" procName3
	lappend list3 "\(\"$procName3\" --" \
	  "Reload Proc" "${dim}Reformat Proc" "Debug Proc" \
	  "Select Proc" "Copy Proc"
    }
    # Save this info for later use.
    set cmInfo(sourceFile) $sourceFile
    for {set n 1} {($n <= 3)} {incr n} {
	set cmInfo(procName$n) [set procName$n]
    }
    # Now build the final list.
    set finalList [list]
    for {set n 1} {($n <= 3)} {incr n} {
	if {[info exists list$n]} {
	    if {[llength $finalList]} {
		lappend finalList "(-)"
	    }
	    eval lappend finalList [set list$n]
	}
    }
    if {![llength $finalList]} {
	set finalList [list "\(No proc utils available"]
	enableMenuItem ${contextualMenu::cmMenuName} "tclProcs" 0
    }
    return [list build $finalList {Tcl::cmMenuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::buildTclVarsCMenu" --
 # 
 # If the current "word" looks like the name of a defined variable, determine
 # if it actually exists and whether or not it is an array.
 # 
 # If we don't have any options to offer to the user, then we attempt to
 # disable this entire CM menu module.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::buildTclVarsCMenu {args} {
    
    global alphaKeyWords contextualMenu::cmMenuName
    
    variable cmInfo
    variable interpCmd
    
    Tcl::cmContext
    foreach item [list txt1 nameSpace enclProc context readOnly] {
	set $item $cmInfo($item)
    }
    if {[string length $nameSpace]} {
	regsub {^::} $nameSpace "" nameSpace
	set queryWords [list "::${nameSpace}::${txt1}" "$txt1"]
    } else {
	set queryWords [list $txt1]
    }
    set varName ""
    set dim [expr {$readOnly ? "\(" : ""}]
    # Is the click word is in the context of a variable?
    if {($context eq "variable")} {
	foreach word $queryWords {
	    if {![string length $word]} {
		continue
	    }
	    set varInfo [$interpCmd "info vars $word"]
	    if {[llength $varInfo]} {
		regsub "^:+" $word "" varName
		if {[$interpCmd "array exists $varName"]} {
		    set context "array"
		    break
		}
		lappend menuList "\(\"$varName\" --" \
		  "Display Var ValueÉ" \
		  "Copy Value To Clipboard" \
		  "(-)" \
		  "${dim}Add Remove Dollars"
		break
	    }
	}
    } 
    if {($context eq "array")} {
	foreach word $queryWords {
	    if {![string length $word]} {
		continue
	    }
	    set varInfo [$interpCmd "info vars $word"]
	    if {[llength $varInfo]} {
		regsub "^:+" $word "" varName
		lappend menuList "\(\"$varName\" --" \
		  "Display Array NamesÉ" \
		  "Display Array Values" \
		  "Copy Names To Clipboard" \
		  "(-)" \
		  "${dim}Add Remove Dollars"
		break
	    }
	}
    }
    # Save this info for later use.
    set cmInfo(varName) $varName
    # Return the list used to build the menu.
    if {![info exists menuList]} {
	set menuList [list "\(No variable names found"]
	enableMenuItem ${contextualMenu::cmMenuName} "tclVars" 0
    }
    return [list build $menuList {Tcl::cmMenuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::buildTclWindowCMenu" --
 # 
 # The context here is the window/file.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::buildTclWindowCMenu {args} {
    
    set dim1 [expr {[Tcl::isShellWindow] ? "\(" : ""}]
    set dim2 [expr {[win::IsFile [win::Current]] ? "" : "\("}]
    set menuList [list \
      "${dim1}/Levaluate" \
      "/-<UswitchToTclsh" \
      "(-)" \
      "${dim2}rebuildTclIndexForWin" \
      "regularExpressionColors" \
      "defaultColors" \
      ]
    return [list build $menuList Tcl::cmMenuProc]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::cmMenuProc" --
 # 
 # Take care of all Tcl CM menu module items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::cmMenuProc {menuName itemName} {
    
    global tclMenu
    
    variable cmInfo
    variable interpCmd
    
    # Wish that we had 'quote::Unprettify' ...
    regsub -all {[\t ]*([^\t ])} $itemName "\\1" itemName
    set firstChar [string tolower [string index $itemName 0]]
    set itemName  $firstChar[string range $itemName 1 end]
    # 'procName1' -- Tcl command surrounding word
    # 'procName2' -- Defined proc surrounding word
    # 'procName3' -- Enclosing proc
    # 'varName'   -- Variable surrounding word
    foreach item [list pos0 pos1 pos2 \
      sourceFile procName1 procName2 procName3 varName] {
	if {[info exists cmInfo($item)]} {
	    set $item $cmInfo($item)
	} else {
	    set $item ""
	}
    }
    set ok  "OK"
    set pic "Place in Clipboard"
    switch $menuName {
	"tclProcs" {
	    switch $itemName {
		"view.htmlHelpFile" {
		    Tcl::DblClickHelper $procName1
		}
		"viewTclCommandsFile" {
		    regsub -- {^:+} $procName1 {} tclCommand
		    help::openGeneral "Tcl 8.4 Commands.txt" $tclCommand
		}
		"displayCommandArgs" {
		    if {[catch {Tcl::getProcArgs $procName1} procArgs]} {
			set procArgs ""
			set msg "Couldn't find the arguments for '$procName1'"
		    } elseif {![llength $procArgs]} {
			set procArgs ""
			set msg "Couldn't find the arguments for '$procName1'"
		    } elseif {([lindex $procArgs 0] \
		      eq "(many options availableÉ)")} {
			set procArgs ""
			set msg "Too many options to list,\
			  consult the help file for more information."
		    } else {
			set msg "'$procName1' arguments: "
		    }
		    status::msg "$msg $procArgs"
		    if {![llength $procArgs]} {
			alertnote "${msg}\r\r${procArgs}"
		    } elseif {![dialog::yesno -y $ok -n $pic $msg $procArgs]} {
			putScrap $procArgs
			status::msg "Copied to Clipboard: [join $procArgs { }]"
		    }
		}
		"openProcSource" {
		    Tcl::DblClickHelper $procName2
		}
		"displayProcSource" {
		    status::msg $sourceFile
		    set msg "Source file of '$procName2':\r\r $sourceFile"
		    if {![dialog::yesno -y $ok -n $pic $msg]} {
			putScrap $sourceFile
		    }
		}
		"displayProcArgs" {
		    if {[catch {Tcl::getProcArgs $procName2} procArgs]} {
			set procArgs ""
			set msg "Couldn't find the arguments for '$procName2'"
		    } elseif {![llength $procArgs]} {
			set procArgs ""
			set msg "'$procName2' doesn't take any arguments."
		    } else {
			set msg "'$procName2' arguments: "
		    }
		    if {([lindex $procArgs 0] eq "?-w <win>?")} {
			set procArgs [lreplace $procArgs 0 0 "?-w" "<win>?"]
		    }
		    status::msg "$msg $procArgs"
		    if {![llength $procArgs]} {
			alertnote "${msg}\r\r${procArgs}"
		    } elseif {![dialog::yesno -y $ok -n $pic $msg $procArgs]} {
			putScrap $procArgs
			status::msg "Copied to Clipboard: $procArgs"
		    }
		}
		"copyArgsToClipboard" {
		    if {[catch {Tcl::getProcArgs $procName2} procArgs]} {
			set procArgs ""
			set msg "Couldn't find the arguments for '$procName2'"
		    } elseif {![llength $procArgs]} {
			set procArgs ""
			set msg "'$procName2' doesn't take any arguments."
		    } else {
			set msg "'$procName2' arguments: "
		    }
		    if {([lindex $procArgs 0] eq "?-w <win>?")} {
			set procArgs [lreplace $procArgs 0 0 "?-w" "<win>?"]
		    }
		    status::msg "$msg $procArgs"
		    if {[llength $procArgs]} {
			putScrap $procArgs
			status::msg "Copied to Clipboard: $procArgs"
		    }
		}
		"insertElectricTemplate" {
		    if {![win::checkIfWinToEdit]} {
		        return
		    }
		    set p "::[string trimleft $procName2 :]"
		    if {[catch {procElectrics $p}]} {
			alertnote "Sorry, can't build the electric template."
		    } else {
			goto $pos2
			bind::Completion
		    }
		}
		"reloadProc" - "reformatProc" {
		    goto $pos1
		    Tcl::tclMenuProc tclProcedures $itemName
		}
		"debugProc" {
		    procs::debug $procName3
		}
		"selectProc" {
		    goto $pos1
		    Tcl::tclMenuProc tclProcedures $itemName
		}
		"copyProc" {
		    putScrap [eval getText [procs::findEnclosing $pos1 "proc" 0]]
		    status::msg "The definition of '$procName3'\
		      is now in the clipboard."
		}
		default {
		    error "Unknown menu item: $itemName"
		}
	    }
	}
	"tclVars" {
	    global $varName
	    switch $itemName {
		"displayVarValue" - "displayArrayValues" {
		    Tcl::showVarValue $varName
		}
		"displayArrayNames" {
		    set p "\"$varName\" array names:"
		    set names [lsort -dictionary [array names $varName]]
		    catch {listpick -p $p $names}
		}
		"copyNamesToClipboard" {
		    set names [lsort -dictionary [array names $varName]]
		    if {[llength $names]} {
			putScrap $names
			status::msg "The names of the '${varName}' array\
			  have been placed in the Clipboard."
		    } else {
			status::msg "The '${varName}' array is empty."
		    }
		}
		"copyValueToClipboard" {
		    putScrap [set $varName]
		    status::msg "The value of the '${varName}' variable\
		      has been placed in the Clipboard."
		}
		"addRemoveDollars" {
		    if {![win::checkIfWinToEdit]} {
			return
		    }
		    goto $pos0
		    togglePrefix {$}
		}
		default {
		    error "Unknown menu item: $itemName"
		}
	    }
	}
	"tclWindow" {
	    switch -- $itemName {
		"rebuildTclIndexForWin" {
		    set menuName "tclIndices"
		}
		"regularExpressionColors" - "defaultColors" {
		    set menuName "tclEditing"
		}
		default {
		    set menuName $tclMenu
		}
	    }
	    Tcl::tclMenuProc $menuName $itemName
	}
    }
    return
}

# ===========================================================================
# 
# .