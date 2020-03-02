## -*-Tcl-*-
 # ###################################################################
 #	Vince's	Additions -	an extension package for Alpha
 # 
 #	FILE: "electricMenu.tcl"
 #					 created: 8/3/96 {1:34:42 pm}	
 #				  last update: 01/25/2006 {03:39:18 PM}	
 #	Author:	Vince Darley
 #	E-mail:	<vince@santafe.edu>
 #	  mail:	317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #	   www:	<http://www.santafe.edu/~vince/>
 #	
 #	Handles the electric menu.
 #	
 # ###################################################################
 ##

alpha::menu electricMenu 1.3.7 global "¥280" {
    # so we don't use the standard proc to build this menu.
    menu::buildProc elec "#"
    namespace eval elec {}
} { 
    elec::rebuildElectricMenu 
} {
} maintainer {
    "Vince Darley" vince@santafe.edu <http://www.santafe.edu/~vince/>
} uninstall {
    this-file
} description {
    Inserts context specific text templates
} help {
    file "Electrics Help"
}

lunion flagPrefs(Electrics) putTemplatesInMainMenu \
  showElectricKeysInMenu addTemplateManipulators 
lunion flagPrefs(Completions) showCompletionsInElectricMenu
lunion varPrefs(Completions) maximumCompletionsInMenu

eval lunion elec::MenuTemplates ""

# register this proc to be called whenever the mode changes.
hook::register changeMode elec::rebuildElectricMenu
hook::register electricBindings elec::BindingsChanged
# To show mode-dependent electric completions in menu; i.e. include in the
# menu all items which when typed, followed by cmd-Tab, will complete
# into some command, click this box||To remove all mode-dependent
# completions from the electric menu, once you've learnt everything that's
# available, click this box.
newPref flag showCompletionsInElectricMenu 1 global elec::clearAndBuildElectricMenu
# To add the list of key-bindings to the bottom of the electric menu (these are
# the items you may edit with 'Config->Special Keys', which are used to
# trigger Completions, Expansions, Template Stop movement etc), click this
# box||To remove the list of key-bindings from the electric menu, once 
# you've learnt them all, click this box.
newPref flag showElectricKeysInMenu 1 global elec::clearAndBuildElectricMenu
# To add a couple of menu items to let you create or delete new templates,
# click this box||To remove the menu items to create/delete templates, click
# this box.
newPref flag addTemplateManipulators 0 global elec::clearAndBuildElectricMenu
# To put all the templates into the main electric menu rather than in a 
# submenu, click this box||To place all templates in a sub-menu of the 
# electric menu, click this box.
newPref flag putTemplatesInMainMenu 0 global elec::clearAndBuildElectricMenu
# To put all the templates into the main electric menu rather than in a 
# submenu, click this box||To place all templates in a sub-menu of the 
# electric menu, click this box.
newPref var maximumCompletionsInMenu 75 global elec::clearAndBuildElectricMenu

namespace eval elec {}

proc elec::BindingsChanged {} {
    global showElectricKeysInMenu
    if {$showElectricKeysInMenu} {elec::clearAndBuildElectricMenu}
}

proc elec::getMenuBindings {} {
    global showElectricKeysInMenu keys::specialBindings
    # get menu items which represent the current bindings
    if {$showElectricKeysInMenu} {
	return [menu::bindingsFromArray keys::specialBindings]
    } else {
	return ""
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "elec::rebuildElectricMenu" --
 # 
 #  Reasonably clever procedure to construct a Template menu from the
 #  ${mode}electrics array on the fly.  Works with 'ensemble' completions,
 #  putting them in submenus (that's why the code is a little messy; I
 #  couldn't dream up a neater method).
 # -------------------------------------------------------------------------
 ##
proc elec::rebuildElectricMenu {args} {
    global mode
    set mmode $mode
    
    global putTemplatesInMainMenu electricMenu
    if {!$putTemplatesInMainMenu} {
	hook::register requireOpenWindowsHook [list ${electricMenu} Templates] 1
    }    
    hook::register requireOpenWindowsHook [list ${electricMenu} "Add Electric ItemÉ"] 1
    global showElectricKeysInMenu keys::specialBindings
    if {$showElectricKeysInMenu} {
	foreach {m v} [array get keys::specialBindings] {
	    if {$v ne ""} {
		hook::register requireOpenWindowsHook [list ${electricMenu} $m] 1
	    }
	}
    }

    set redo 1
    
    if {![cache::exists elecMenu::configuration]} {
	cache::create elecMenu::configuration
    }
    
    if {[cache::exists elecMenu::elec-${mmode}]} {
	if {[cache::compareDates elecMenu::configuration \
	  >= elecMenu::elec-${mmode}]} {
	    cache::readContents elecMenu::elec-${mmode}
	    status::msg ""
	    set redo 0
	} else {
	    cache::deletePat elecMenu::elec-*
	}
    }
    if {$redo} {
	global ${mmode}electrics electricMenu showCompletionsInElectricMenu \
	  maximumCompletionsInMenu
	
	set m [list Menu -n ${electricMenu} -m -p elec::MenuProc]
	# make the menu of electrics if desired
	if {$showCompletionsInElectricMenu && [array exists ${mmode}electrics]} {
	    set items [lsort [array names ${mmode}electrics]]
	    # remove all contractions
	    set items [lremove -all -glob $items "*'*"]
	    # remove something else (I've forgotten what!)
	    regsub -all { [^ ]*\*[^ ]*} " $items " { } items
	    set c [set items]
	    while {[regexp {\{(\w+) \w+\}} $c all pref]} {
		set c [string range $c [expr {[string last "\{$pref " $c] +2}] end]
		lappend got $pref
	    }
	    if {[info exists got]} {
		foreach pref $got {
		    regsub "(\{${pref} \\w+\} )+" $items \
		      "\{Menu -n \"   ${pref}\" -m -p elec::MenuProc \{\\0\}\} " items
		}
	    }
	    if {[llength $items] > $maximumCompletionsInMenu} {
		# Too many items, so truncate
		set items [lrange $items 0 $maximumCompletionsInMenu]
	    }
	} else {
	    set items ""
	}
	# make the whole menu
	set items [concat [elec::makeTemplatesMenu $mmode] $items "(-" \
	  [elec::getMenuBindings] [list "Add Electric ItemÉ"] ]
	global addTemplateManipulators
	if {$addTemplateManipulators} {
	    lappend items "Grab Selection" "Insert Old Selection" \
	      "Insert In Lines"
	}
	lappend items "Clear Elec Menu Cache"
	lappend m $items
	cache::add elecMenu::elec-${mmode} variable m
    }
    eval $m
    
    # We don't use the standard menu::buildSome, so we currently need
    # to do this.  Would be good to find a way to remove it.
    alpha::performDimmingForMenu $electricMenu
}

proc elec::clearAndBuildElectricMenu {args} {
    cache::deletePat elecMenu::elec-*
    elec::rebuildElectricMenu
}

proc elec::makeTemplatesMenu {mmode} {
    # make the templates submenu
    global ${mmode}Templates elec::MenuTemplates \
      menu::additions putTemplatesInMainMenu
    set m ${elec::MenuTemplates}
    if {[info exists ${mmode}Templates]} {
	set m [concat $m [set ${mmode}Templates]]
    }
    set m [lsort $m]
    if {![catch {license::listTypes 0 0} licenses]} {
	eval lappend m "(-)" $licenses "licenseTemplatesHelpÉ"
    }
    if {[info exists menu::additions(elec)]} {
	foreach i [set menu::additions(elec)] {
	    eval lappend m "(-" [lrange $i 2 end]
	}
    }
    lappend m "(-" "addTemplateItemÉ" "removeTemplateItemÉ"
    if {$putTemplatesInMainMenu} {
	foreach i $m {
	    if {[lindex $i 0] == "Menu"} {
		lappend ret $i
	    } else {
		lappend ret "[quote::Prettify $i] "
	    }
	}
	return $ret
    } else {	
	return [list "Menu -n Templates -p elec::userTemplates [list $m]"]
    }
    
}

proc elec::rebuildTemplatesMenu { {mmode ""} } {
    global mode
    if {$mmode == ""} {set mmode $mode}
    eval [lindex [elec::makeTemplatesMenu $mmode] 0]
}

proc elec::userTemplates {menu item} {
    
    # Make sure that the package: licenseTemplates is working for us.
    if {[catch {license::listTypes 0 0} licenseTypes]} {
        set licenseTypes [list]
    }
    if {($item eq "licenseTemplatesHelp")} {
	package::helpWindow "licenseTemplates"
        return
    } elseif {([lsearch $licenseTypes $item] > -1)} {
	set t [license::getTemplate $item]
    } elseif {![catch {file::$item} template]} {
	set t $template
    } else {
        error "Cancelled: could not find the template for \"$item\""
    }
    if {($t ne "")} {
	elec::Insertion $t
    }
    return
}

proc elec::MenuProc {menu item} {
    switch -- $item {
	"Next Stop Or Indent" {bind::IndentOrNextstop}
	"Prev Stop" { ring::- }
	"nth Stop" {ring::nth}
	"Complete" {bind::Completion}
	"Complete Or Tab" {bind::TabOrComplete}
	"Expand" {bind::Expansion}
	"Next Stop" {ring::+}
	"Real Tab" {insertActualTab}
	"Add Electric ItemÉ" - "Add Electric Item" {elec::AddItem}
	"Grab Selection" {elec::GrabSelection}
	"Insert Old Selection" {elec::InsertOldSelection}
	"Insert In Lines" {elec::InsertInLines}
	"Clear All Stops" {ring::clear}
	"Clear Elec Menu Cache" {elec::clearAndBuildElectricMenu}
	default {
	    if {[regexp {(.*) $} $item "" item]} {
		set item [string trimright [join $item ""] É]
		elec::userTemplates $menu \
		  [string tolower [string index $item 0]][string range $item 1 end]
	    } else {
		set p [hook::procForWin Completion::Insert]
		if {$p ne "" && $p ne "::Completion::Insert"} {
		    $p $item
		} else {
		    insertText $item
		    bind::Completion
		}
	    }
	}
    }
}

proc elec::AddItem {} {
    global mode
    if {$mode == ""} { beep ; status::msg "No mode setÉ" ; return }
    global ${mode}electrics
    set e [prompt "Enter the electric item for '$mode' mode:" ""]
    if {$e == ""} {return}
    set default [file::_varValue ${mode}electrics($e)]
    #[file::_getDefault "Do you want to start with this as the template?"]
    set value [getline "Enter the electric extension, using ¥prompt¥, \\r \\\{, \\\} etc" $default]
    if {$value != ""} {
	if {[string length $value] > 210} {
	    alertnote "Alpha unfortunately truncates direct entry to\
	      about 200 characters, however you can add it directly to\
	      the preferences file.tcl"
	}
	eval set ${mode}electrics($e) \"$value\"
	prefs::addArrayElement ${mode}electrics $e [set ${mode}electrics($e)]
	cache::deletePat elecMenu::elec-$mode
	elec::rebuildElectricMenu
    }
}

proc file::_varValue {var} {
    
    upvar 1 $var a
    if {[info exists a]} {
	return $a
    } else {
	return ""
    }
}

proc file::addTemplateItem {} {
    global elec::MenuTemplates mode
    global ${mode}Templates
    set v elec::MenuTemplates
    set v [expr {$mode != "" && [dialog::yesno \
      "Is this item '$mode' mode-specific (otherwise I'll make it global)?"] \
      ? "${mode}Templates" : "elec::MenuTemplates"}]
    set loop 1
    while {$loop} {
	set e [join [prompt "Enter the new template menu item name:" ""] ""]
	if {$e == ""} {return}
	set e [string tolower [string index $e 0]][string range $e 1 end]
	if {[info command "::file::$e"] == ""} {
	    set loop 0
	} else {
	    beep
	    status::msg "the name already exists, choose another one"
	}
    }
    set default [file::_getDefault "Do you want to start with this\
      as the template?"]
    set t "\r"
    append t "proc file::${e} \{\} \{\r"
    append t "\t# You can change the string below if you like\r"
    append t "return \"[quote::Insert $default]\""
    append t "\r\}\r"
    prefs::addGlobalPrefsLine $t
    lappend $v $e
    prefs::modified $v
    elec::rebuildTemplatesMenu
    set default "return \"[quote::Insert $default]\""
    ;proc $e {} $default
    elec::clearAndBuildElectricMenu
    if {![dialog::yesno -y "Continue" -n "Edit prefs.tcl now"\
      "A template for the procedure has been added\
      to your \"prefs.tcl\" file. You can edit it by selecting the \
      \"Config > Preferences > Edit Prefs File\" menu command."]} {
	prefs::editPrefsFile
	goto [maxPos]
    }
    return
}

proc file::removeTemplateItem {} {
    global elec::MenuTemplates mode
    global ${mode}Templates

    set tlist ${elec::MenuTemplates}
    catch {set tlist [concat $tlist [set ${mode}Templates]]}
    set l [listpick -p "Which template shall I permanently remove?" \
      [lsort $tlist]]
    if {[set i [lsearch -exact ${elec::MenuTemplates} $l]] != -1} {
	set elec::MenuTemplates [lreplace ${elec::MenuTemplates} $i $i]
	prefs::modified elec::MenuTemplates
    } else {
	set i [lsearch -exact [set ${mode}Templates] $l]
	set ${mode}Templates [lreplace [set ${mode}Templates] $i $i]
	prefs::modified ${mode}Templates
    }
    elec::rebuildTemplatesMenu
    elec::clearAndBuildElectricMenu
    prefs::editPrefsFile
    set pat "proc\[ \t\]+file::"
    append pat $l
    set fpos [search -s -f 1 -r 1 -n $pat [minPos]]
    goto [pos::math [lindex $fpos 0] + 2]
    function::select
    deleteText [pos::math [getPos] - 1] [pos::math [selEnd] + 1]
    save
    rename "::file::$l" {}
    return
}

proc file::_getDefault {text {defaultValue ""} {var ""}} {
    
    if {[llength [winNames -f]] && [isSelection]} {
	if {[askyesno "You've selected some text. $text"]} {
	    set defaultValue [getSelect]
	}
    }
    if {![string length $defaultValue]} {
	set p "Enter template text (you can edit it later)"
	set defaultValue [getline $p $defaultValue]
    }
    if {($var ne "")} {
	return [elec::_MakeIntoInsertion $defaultValue $var]
    } else {
	return $defaultValue
    }
}

# procedures below get added to the menu if you set the 'poweruser' flag
# in "xx.tcl".  They make it easy to create large template 
# procedures 
proc elec::GrabSelection {} {
    global elec::__grabbed
    set elec::__grabbed [getSelect]
}

proc elec::InsertOldSelection {} {
    global elec::__grabbed
    insertText [quote::Insert [set elec::__grabbed]]
}

proc elec::InsertInLines {} {
    global elec::__grabbed
    insertText [elec::_MakeIntoInsertion ${elec::__grabbed}]
}

proc elec::_MakeIntoInsertion {t {var "t"}} {
    if {$t == ""} { return $t }
    regsub -all "\n" $t "\r" t
    while 1 {
	set ret [string first "\r" $t]
	if { $ret == -1 } { set ret [string length $t] }
	append b [string range $t 0 $ret]
	if {[string length $b] > 20} {
	    while 1 {
		append a \
		  "\tappend $var \"[quote::Insert [string range $b 0 59]]\"\r"
		if {[set b [string range $b 60 end]] == ""} {
		    break
		}
	    }
	}
	set t [string range $t [incr ret] end]
	if {[string length $t] == 0} { 
	    if {$b != ""} {
		append a "\tappend $var \"$b\"\r"
	    }
	    break 
	}
    }
    return $a
}



