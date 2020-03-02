## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_menus.tcl"
 #                                    created: 04/12/98 {23:17:46 PM} 
 #                                last update: 2005-08-11 18:38:30
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 1998-2005  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##
 
# ×××× menus ×××× #

# Check if we have compound menus.  These exist on all platforms
# except for MacOS X.  When this is fixed we can replace this
# with a simple 'info tclversion' for that platform
if {$alpha::macos == 2} {
    set alpha::noCompoundMenus 1
} else {
    set alpha::noCompoundMenus 0
}

#¥ addMenuItem [-m] [-l <meta-characters>] <menu name> <item name> - Convert
#  item to menu form and add to specified menu. If '-m' specified, menu 
#  form conversion not done. The '-l' option allows you to use menu meta 
#  characters as text of menu items. If the '-l' option is used, the 
#  <meta-characters> string is interpreted for menu item attributes, and 
#  meta-characters in <item name> are included in the menu item text 
#  literally. For example: 
#  	addMenuItem -m -l "/B" "Hello/C" 
#  would appear as the text "Hello/C" in the menu, and have "B" as its 
#  command equivalent.
proc addMenuItem {name item args} {
    # doesn't currently take account of the proc attached to the given
    # menu.
    set accel ""
    if {[llength $args]} {
	if {$name == "-m"} { 
	    set mflag 1
	    if {$item == "-l"} {
		foreach {accel name item index} $args {}
	    } else {
		set name $item 
		set item [lindex $args 0]
		set index [lindex $args 1]
	    }
	} elseif {$name == "-l"} {
	    set accel $item
	    foreach {name item index} $args {}
	} else {
	    set index [lindex $args 0]
	}
	if {$index == ""} {
	    set index "add"
	} else {
	    set index [list insert $index]
	}
    }
    global alpha_mprocs
    if {[info exists alpha_mprocs($name)]} {
	set mproc $alpha_mprocs($name)
    } else {
	set mproc "menu::generalProc"
    }
    foreach {mname n font} [menu_tags $name] {}
    if {$item == "\(-"} {
	eval [list $n] $index separator
    } else {
	if {[info exists mflag]} { 
	    set label $item
	} else {
	    set label [quote::Menuify $item]
	}
	if {$accel != ""} {
	    foreach {accelerator accel} \
	      [alpha::accelerator [string range $accel 1 end] ""] {}
	    set accel [list -accelerator $accel]
	    if {[info exists accelerator] && ($accelerator != "")} {
		regsub -all "Ctrl" $accelerator "Control" accelerator
		bind all "<${accelerator}>" [list $mproc $name $item]
	    }
	}
	eval [list $n] $index \
	  command -label [list [::msgcat::mc $label]] \
	  -command [list [list $mproc $name $item]] \
	  $accel
    }
}


#¥ deleteMenuItem [-m] <menu name> <item name> - Convert item to menu form 
#  and delete from specified menu. If '-m' specified, menu form conversion 
#  not done. 
proc deleteMenuItem {name item args} {
    if {[llength $args]} {
	if {$name == "-m"} { 
	    set mflag 1
	    set name $item 
	    set item [lindex $args 0]
	}
    }
    foreach {name n font} [menu_tags $name] {}
    if {[info exists mflag]} { 
	set label $item
    } else {
	set label [quote::Menuify $item]
    }
    
    set i [_menuItemToIndex $n $label]
    if {[catch {
	set accel [$n entrycget $i -accelerator]
	if {$accel != ""} {
	    regsub -all "Ctrl" $accel "Control" accel
	    regsub -- {-[^-]+$} $accel "-KeyPress&" accel
	    set old [bind all "<${accel}>"]
	    #puts [list deleting '$accel' $old]
	    bind all "<${accel}>" ""
	}
    } err]} { puts stderr $err }
    
    $n delete $i
}

proc renameMenuItem {name item newitem args} {
    if {[llength $args]} {
	if {$name == "-m"} { 
	    set mflag 1
	    set name $item 
	    set item $newitem
	    set newitem [lindex $args 0]
	}
    }
    foreach {name n font} [menu_tags $name] {}
    if {[info exists mflag]} { 
	set label $item
    } else {
	set label [quote::Menuify $item]
	set newitem [quote::Menuify $newitem]
    }
    set i [_menuItemToIndex $n $label]
    $n entryconfigure $i -label [::msgcat::mc $newitem]
}

proc addHelpMenu {args} {
    global multiColumnMenusEveryNItems alpha::helpMenuCounter
    if {![info exists alpha::helpMenuCounter]} {
	set alpha::helpMenuCounter $multiColumnMenusEveryNItems
    }
    foreach item $args {
	eval .menubar.help add [alpha::menuItem .menubar.help $item "helpMenu"]
	incr alpha::helpMenuCounter -1
	if {$alpha::helpMenuCounter <= 0} {
	    if {![catch {.menubar.help entryconfigure end -columnbreak 1}]} {
		set alpha::helpMenuCounter $multiColumnMenusEveryNItems
	    }
	}
    }
}

proc alpha::menuItem {parent item {proc ""}} {
    if {$item != "(-"} {
	if {[string first "Menu " $item] == 0} {
	    # should be a submenu
	    set name [lindex $item 2]
	    set items [lindex $item 3]
	    regsub -all {\.} $name {} n
	    regsub -all " " $n "_" n
	    set subparent $parent.m$n
	    global tearoffMenus
	    ::menu $subparent -tearoff $tearoffMenus \
	      -tearoffcommand ::alphatk::floatJustCreated
	    foreach subitem $items {
		eval $subparent add \
		  [alpha::menuItem $subparent $subitem [list helpMenu $name]]
	    }
	    return [list cascade -label [::msgcat::mc $name] -menu $subparent]
	} else {
	    return [list command -label [::msgcat::mc $item] \
	      -command "$proc [list $item]"]
	}
    } else {
	return [list "separator"]
    }
}

proc alpha::accelerator {key mods} {
    variable command_key 
    variable option_key
    variable keymap
    variable menukeymap
    if {$key == ""} {return ""}
    if {$mods != ""} {
	regsub -- "<I" $mods "${option_key}-" mods
	regsub -- "<U" $mods "Shift-" mods
	regsub -- "<B" $mods "Ctrl-" mods
	regsub -- "<O" $mods "${command_key}-" mods
    }
    regsub -all -- {<[SEIUBO]} $mods "" mods
    set ascii [text::Ascii $key]
    if {[regexp -- {[a-z]} $key]} {
	global keys::func alpha::macos
	# Enter is invalid on non-MacOS, and currently
	# doesn't work on MacOS either.
	if {0 && ($key == "a") && (1 || (!${alpha::macos}))} {
	    return ""
	}
	set rest [lindex $keys::func [expr {$ascii -97}]]
	if {$rest == "Delete"} {
	    set rest BackSpace
	} elseif {$rest == "Fwd Del"} {
	    set rest Delete
	} elseif {$rest == "Enter"} {
	    set rest KP_Enter
	}
	set menu $mods$rest
	append mods KeyPress-$rest
    } else {
	if {![info exists alpha::menukeymap($key)]} {
	    if {$mods == "" || $mods == "Shift-"} { 
		append mods $command_key "-" 
	    }
	    if {$ascii <= 32} {
		while {[info exists alpha::keymap($key)]} {
		    set key $alpha::keymap($key)
		}
		set menu $mods$key
	    } else {
		set menu $mods$key
		while {[info exists alpha::keymap($key)]} {
		    set key $alpha::keymap($key)
		}
	    }
	} else {
	    set menu $mods$key
	    set key $alpha::menukeymap($key)
	}
	append mods KeyPress- $key
    }
    return [list $mods $menu]
}

# Tk uses either a variety of index lookup techniques to find a
# menu item, or a pattern lookup.  There is no built in technique
# to find the index of an item with a particular textual label.
# This command effectively implements that.
proc _menuItemToIndex {menucmd label} {
    # Find a pattern-quoted name of the label
    set label [quote::Find [::msgcat::mc $label]]
    if {[string index $label 0] != "\\"} {
	# The label might be mistaken for an integer index, or 'end'
	# or something like that.  Since it is a 'pattern', we can
	# simply add a literal to the first character so it won't
	# be mis-interpreted.
	set label "\\$label"
    }
    return [$menucmd index $label]
}

#¥ enableMenuItem <menuName> <item text> <on|off> - Either enable or 
#  disable the menu item of user menu 'menuName' that has text '<item 
#  text>'. Note that unless the menu is not only created, but also already
#  inserted, this command has no effect. 
proc enableMenuItem {name item on args} {
    if {[llength $args]} {
	if {$name == "-m"} {
             set mflag 1
	     set name $item
             set item $on
	     set on [lindex $args 0]
        }
    }
    
    foreach {mname n font} [menu_tags $name] {}
    if {![winfo exists $n]} { error "No such menu $name" }
    if {$item == ""} {
	# it's the whole menu
	if {![menu::inserted $name]} { return }
	set index [_menuItemToIndex .menubar $mname]
	set menu .menubar
    } else {
	set menu $n
	if {[info exists mflag]} {
	    set index [_menuItemToIndex $n $item]
	} else {
	    set index [_menuItemToIndex $n [quote::Menuify $item]]
	}
    }

    $menu entryconfigure $index \
      -state [expr {$on ? "normal" : "disabled"}]
    
}

#¥ insertMenu <name>... - insert the previously created user menu 'name' into 
#  the menuBar. 
proc insertMenu {args} {
    foreach n $args {
	foreach {mname w font} [menu_tags $n] {}
	if {![winfo exists $w]} {
	    menu $w
	}
	# There is no command to check for the existence of a menu item,
	# so we use 'catch' to check whether the item is already in the
	# menu.
	if {[catch [list _menuItemToIndex .menubar $mname]]} {
	    # insert it just before the Help menu.
	    .menubar insert Help cascade -label "$mname" -menu $w
	}
    }
}

namespace eval menu {}
proc menu::inserted {n} {
    foreach {mname w font} [menu_tags $n] {}
    if {[catch [list _menuItemToIndex .menubar $mname]]} {
	return 0
    } else {
        return 1
    }
}

#¥ markMenuItem [-m] <menuName> <item text> <on|off> [<mark char>] - 
#  Either mark or unmark
#  the menu item of user menu 'menuName' that has text '<item text>'. 
#  Note that unless the menu is not only created, but also already
#  been inserted, this command has no effect. 
proc markMenuItem {m item on {char "¥"} args} {
    if {$m == "-m"} {
	set m $item ; set item $on ; set on $char ; set char [lindex $args 0]
    } else {
	set item [quote::Menuify $item]
    }
    foreach {mname widg font} [menu_tags $m] {}
    set m $widg
    if {$on == "on"} { set on 1 } elseif {$on == "off"} { set on 0 }
    # Eventually we will remove this 'catch' because it shouldn't be
    # needed if AlphaTcl is all bug free.
    if {[catch {_menuItemToIndex $m $item} index]} {
	catch {
	    puts stderr "No such item '$item' to mark in menu $m,\
	      while '[info level 0]' from [info level 1]"
	}
	return ""
    }
    set label [$m entrycget $index -label]
    global alphaDummy
    switch -- [$m type $index] {
	"radiobutton" {
	    if {$on} {
		set alphaDummy(menu,$m) $label
	    }
	}
	"checkbutton" {
	    set alphaDummy(menu,$m,$label) $on
	    if {$::alpha:::macos} {
		# Bug in TkAqua
		$m entryconfigure $index -onvalue 1
	    }
	}
	default {
	    # this is so the user can create the item as an ordinary
	    # menu item, and then later turn it into a checkbutton
	    # without any problems.
	    $m insert $index checkbutton \
	      -command [$m entrycget $index -command] \
	      -label [::msgcat::mc $label] \
	      -accelerator [$m entrycget $index -accelerator] \
	      -columnbreak [$m entrycget $index -columnbreak] \
	      -state normal \
	      -variable alphaDummy(menu,$m,$label)
	    set alphaDummy(menu,$m,$label) $on
	    $m delete [expr {$index +1}]
	}
    }
    return ""
}

# Bernard's !\x1f thing
# <I is italic
# <B is bold
# <U is underline
# <O is outline
# <S is shadow
# <E is extended
# <C for condense

#¥ Menu [-s] [-n <name>] [-i <num] [-m] [-M <mode>] [-p <procname>] 
#            <list of menu items> - 
#  Defines a new menu named 'name' (if provided w/ '-n' option). The menu is not 
#  yet inserted into the menubar. The menu commands may be nested for 
#  heirarchical menus, see 'AlphaBits.tcl' for examples. Alpha massages the 
#  function names to make them look better in the menus. 
#  '-c'		Ignore any menu meta-chars. Can also be done on a per-item basis 
#  		by appending an ampersand ('&') to the end of an item.
#  '-s'		Use system menu definition proc (faster).
#  '-n <num>'    Resource id of icon suite to use for menu title. 'ics#' 
#                is the only resource that is really necessary.
#  '-n <name>'	Name the menu. Not necessary for submenus.
#  '-m'		No menu form. If not supplied, each menu item is split into 
#  		words at each capitalized letter.
#  '-p <name>' 	The tcl proc named by 'name' is called w/ the menu's name
#  		and the item's contents when the item is chosen.
#  '-M <mode>'	Specifies that any bindings created by the menu are 
#  		specific to a given mode. This is important because mode-specific
#  		bindings over-ride global bindings.
proc Menu {args} {
    set ma [lindex $args end]
    set args [lreplace $args end end]
    getOpts {-n -M -p -t -h -font}
    if {[info exists opts(-p)]} {
	lappend proc $opts(-p)
	global alpha_mprocs
	set alpha_mprocs($opts(-n)) $proc
    } else {
	set proc ""
    }
    #if {[info exists opts(-M)]} { lappend proc -M $opts(-m) }
    #if {[info exists opts(-m)]} { lappend proc -m }
    set noNameError "Menu needs '-n name'"
    if {![info exists opts(-n)]} {
	return -code error $noNameError
    }
    foreach {mname widg font} [menu_tags $opts(-n)] {}
    set m $widg

    global tearoffMenus
    if {[winfo exists $m]} {
	# Workaround TkAqua bug by not destroying the menu,
	# rather deleting all of its contents.  This also
	# might be a bit less strenuous for the cloning
	# apparatus (but that's pure speculation).
	$m delete 0 end
	$m configure -tearoff $tearoffMenus \
	  -tearoffcommand ::alphatk::floatJustCreated
    } else {
	menu $m -tearoff $tearoffMenus \
	  -tearoffcommand ::alphatk::floatJustCreated
    }
    catch {$m configure -postcommand "balloon::_remove"}
    #puts "$m $opts(-n) [menu_tags $opts(-n)]"
    global multiColumnMenusEveryNItems
    set count $multiColumnMenusEveryNItems
    set counter 0
    foreach item $ma {
	incr count -1
	incr counter
	# special 'catch' so we don't trip on 'lindex $item 0'
	set submenu 0
	if {![catch {llength $item}] && [lindex $item 0] == "Menu" && \
	  [llength $item] > 1} {
	    if {[catch {eval $item} res]} {
		if {($res ne $noNameError)} {
		    return -code error $res
		} else {
		    # treat it as a menu item, not a menu
		}
	    } else {
		set submenu 1
	    }
	}
	
	if {$submenu} {
	    foreach {mm label} $res {}
	    if {[regexp -- "^/\x1e(.*)\\^(.)\$" $label "" label image]} {
		# add icon
		scan $image %c int
		# magic number according to which Alpha on 
		# MacOS behaves!
		incr int 208
		set image ics8$int
		if {![alphatk::getImage $image $int $label]} {
		    unset image
		}
	    }
	    if {![info exists opts(-m)]} {
		set label [quote::Menuify $label]
	    }
	    $m add cascade -label [::msgcat::mc $label] -menu $mm
	    if {!$::alpha::noCompoundMenus && [info exists image]} {
		$m entryconfigure end -compound left -image $image
		unset image
	    }
	} elseif {[info exists opts(-c)]} {
	    # ignore all meta characters
	    if {[string range $item 0 1] == "\(-"} {
		$m add separator
		continue
	    } elseif {[regexp -- "^ *-+ *\$" $item]} {
		$m add separator
		continue
	    } else {
		set state "normal"
		set entrytype command
		set isOn 0
		set label $item

		if {![info exists opts(-m)]} {
		    set label [quote::Menuify $label]
		}
		# '-c' doesn't strip ellipses.
		#regexp -- {^(.*)\u2026$} $item "" item
		if {[info exists opts(-t)]} {
		    set entrytype $opts(-t)
		}
		set script "::alpha::executeAndRecord"
		if {$proc == ""} {
		    lappend script [list $item]
		} else {
		    lappend script [list $proc $opts(-n) $item]
		}
		if {$entrytype == "radiobutton"} {
		    global alphaDummy
		    if {$isOn} {
			set alphaDummy(menu,$m) $label
		    }
		    set extraargs [list -variable \
		      alphaDummy(menu,$m) -value $label]
		    # I used to think we needed '-command ""' here,
		    # but in fact that's not true.  While we don't
		    # need the command to have the variable set correctly,
		    # we do need it so Alpha's other procedures can
		    # register the change, and perhaps schedule this
		    # item to be saved as a modified preference.
		} elseif {$entrytype == "checkbutton"} {
		    global alphaDummy
		    set alphaDummy(menu,$m,$label) $isOn
		    set extraargs [list -variable \
		      alphaDummy(menu,$m,$label)]
		} else {
		    set extraargs {}
		}
		eval [list $m add $entrytype -label [::msgcat::mc $label] \
		  -command "$script" -state $state] $extraargs
	    }
	} else {
	    if {[regexp -- "^ *-+ *\$" $item] || [regexp -- {^\(-} $item]} {
		$m add separator
		continue
	    }
	    regexp -- {^!(.)(.*)} $item "" markc item
	    if {[regsub -- {^\(} $item "" item]} {
		set state "disabled"
	    } else {
	        set state "normal"
	    }
	    switch -regexp -- $item {
		"/." {
		    regexp -- {/(.)} $item "" key
		    regsub -- "/." $item "" item 
		    if {$key == "\x1e"} {
			# special case 'icon'
			set key ""
			set icon 1
		    }
		    if {[regsub -- {^\(} $item "" item]} {
			set state "disabled"
		    }
		    if {![info exists markc]} {
			regexp -- {^!(.)(.*)} $item "" markc item
		    }
		    if {[info exists markc] && ($markc eq "\x1f")} {
			unset markc
			# We don't support menu item styles
			regsub -all -- {^((<[UIOCSEB])*)} $item "" item
		    }
		    regexp -- {^((<[UIOCSEB])*)} $item "" mods
		    set item [string range $item [string length $mods] end]
		    if {[regsub -- {^\(} $item "" item]} {
			set state "disabled"
		    }
		    if {[regexp -- {^(.*)(\\?&|\^.)$} $item "" item other]} {
			# If this isn't true it's the \\?& branch.
			if {!$::alpha::noCompoundMenus \
			  && ([string index $other 0] == "^")} {
			    if {[info exists icon]} {
				# add icon and set compound
				scan [string index $other 1] %c int
				# magic number according to which Alpha on 
				# MacOS behaves!
				incr int 208
				set image ics8$int
				if {![alphatk::getImage $image $int $item]} {
				    unset image
				}
			    } else {
				# add bitmap and set compound
				set int [string index $other 1]
				incr int 256
				set image ICON$int
				if {![alphatk::getImage $image $int $item]} {
				    unset image
				}
			    }
			}
		    }
		    if {![info exists markc]} {
			regexp -- {^!(.)(.*)} $item "" markc item
		    }
		    if {![info exists opts(-m)]} {
			if {[string index $item 0] eq "ª"} {
			    set item [string range $item 1 end]
			    set label $item
			} else {
			    set label [quote::Menuify $item]
			}
		    } else {
			set label $item
		    }
		    set accel {}
		    if {[info exists markc]} {
			switch -- $markc {
			    "\u221a" -
			    "\u2022" {
				set entrytype checkbutton
				set isOn 1
			    }
			    " " {
				set entrytype checkbutton
				set isOn 0
			    }
			    default {
				set accel $markc
			    }
			}
			unset markc
		    }
		    regexp -- {^(.*)\u2026$} $item "" item
		    
		    set script "::alpha::executeAndRecord"
		    if {$proc == ""} {
			lappend script [list $item]
		    } else {
			lappend script [list $proc $opts(-n) $item]
		    }
		    set accelerator ""
		    set accel2 ""
		    foreach {accelerator accel2} [alpha::accelerator $key $mods] {}
		    if {$accel ne ""} {
			if {$accel2 ne ""} {append accel " " $accel2}
		    } else {
		        set accel $accel2
		    }
		    $m add command -label [::msgcat::mc $label] \
		      -command $script \
		      -accelerator $accel -state $state
		    
		    if {[info exists image]} {
			$m entryconfigure end -compound left -image $image
			unset image
		    }
		    
		    if {$accelerator != ""} {
			regsub -all "Ctrl" $accelerator "Control" accelerator
			
			if {[string first "Shift" $accelerator] == -1} {
			    if {[regexp -- {[A-Z]$} $accelerator last]} {
				regsub -- {[A-Z]$} $accelerator \
				  [string tolower $last] accelerator
			    }
			}
			set to "Alpha"
			if {[info exists opts(-M)]} {
			    set to "$opts(-M)AlphaStyle"
			}
			if {[catch {bind $to "<${accelerator}>" \
			  "$script ; break"} err]} {
			    alertnote "Bad binding '${accelerator}', for \
			      item '$item' [list $key $mods] \
			      [list $m invoke $label]. Please\
			      report this."
			    puts stderr "Bad binding '${accelerator}', for \
			      item '$item' [list $key $mods] \
			      [list $m invoke $label]"
			} else {
			    alpha::bindForMenu $to "<${accelerator}>" \
			      "$script ; break"
			}
		    }
		}
		default {
		    if {[info exists markc] && ($markc eq "\x1f")} {
			unset markc
			# We don't support menu item styles
			regsub -all -- {^((<[UIOCSEB])*)} $item "" item
		    }
		    regsub {^(<[UIOCSEB])*} $item "" item
		    regexp -- {^(.*)(&|\^.)$} $item "" item
		    if {[regsub -- {^\(} $item "" item]} {
			set state "disabled"
		    }
		    set entrytype command
		    set isOn 0
		    if {![info exists markc]} {
			regexp -- {^!(.)(.*)} $item "" markc item
		    }
		    if {![info exists opts(-m)]} {
			if {[string index $item 0] eq "ª"} {
			    set item [string range $item 1 end]
			    set label $item
			} else {
			    set label [quote::Menuify $item]
			}
		    } else {
			set label $item
		    } 
		    set accel {}
		    if {[info exists markc]} {
			switch -- $markc {
			    "\u221a" -
			    "\u2022" {
				set entrytype checkbutton
				set isOn 1
			    }
			    " " {
				set entrytype checkbutton
				set isOn 0
			    }
			    default {
				set accel $markc
			    }
			}
			unset markc
		    }
		    regexp -- {^(.*)\u2026$} $item "" item
		    if {[info exists opts(-t)]} {
			set entrytype $opts(-t)
		    }
		    set script "::alpha::executeAndRecord"
		    if {$proc == ""} {
			lappend script [list $item]
		    } else {
			lappend script [list $proc $opts(-n) $item]
		    }
		    if {$entrytype == "radiobutton"} {
			global alphaDummy
			if {$isOn} {
			    set alphaDummy(menu,$m) $label
			}
			set extraargs [list -variable \
			  alphaDummy(menu,$m) -value $label]
			# I used to think we needed '-command ""' here,
			# but in fact that's not true.  While we don't
			# need the command to have the variable set correctly,
			# we do need it so Alpha's other procedures can
			# register the change, and perhaps schedule this
			# item to be saved as a modified preference.
		    } elseif {$entrytype == "checkbutton"} {
			global alphaDummy
			set alphaDummy(menu,$m,$label) $isOn
			set extraargs [list -variable \
			  alphaDummy(menu,$m,$label)]
		    } else {
			set extraargs {}
		    }
		    eval [list $m add $entrytype -label [::msgcat::mc $label] \
		      -command "$script" -state $state -accelerator $accel] $extraargs
		}
	    }
	    # that was the end of the switch

	}
	# that was the end of the if 'cascade' else 'switch'
	
	#if {[info exists opts(-font)]} { $m entryconfigure end -font }
	
	if {$count <= 0} {
	    set idx [_menuItemToIndex $m $label]
	    # Check to workaround problem with duplicate items, in
	    # which the 'idx' returned will be completely wrong.
	    if {abs($idx - $counter) > 5} {
		set idx $counter
	    }
	    set count [expr {$multiColumnMenusEveryNItems -1}]
	    while {1} {
		# This will fail if, e.g., it is a 'separator' menu entry.
		if {![catch {$m entryconfigure $idx -columnbreak 1}]} {
		    break
		}
		incr count -1
		incr idx -1
		if {$idx < 2} {
		    break
		}
	    }
	} 
    }
    return [list $m $mname]
}
#¥ removeMenu <name> - remove menu 'name' from menubar, except those 
#  specified by previous 'makeMenuPermanent' calls.
proc removeMenu {args} {
    foreach n $args {
	set mname [lindex [menu_tags $n] 0]
	.menubar delete $mname
    }
}

namespace eval alphatk {}

proc alphatk::getImage {image int label} {
    if {![catch {image width $image}]} {
	return 1
    } else {
	set ifile [file join $::ALPHATK AlphaGifs Alpha$int.gif]
	if {[file exists $ifile]} {
	    if {![catch {image create photo $image -file $ifile}]} {
		return 1
	    }
	} else {
	    puts stderr "No image Alpha$int.gif for menu item $label"
	}
	return 0
    }
}

proc alphatk::itemsToMenu {m cmdscript items} {
    foreach item $items {
	if {[regexp -- {^\(-} $item]} {
	    $m add separator
	    continue
	}
	if {[regsub -- {^\(} $item "" item]} {
	    set state "disabled"
	} else {
	    set state "normal"
	}
	switch -regexp -- $item {
	    "/." {
		regexp -- {/(.)} $item "" key
		regsub -- "/[quote::Regfind ${key}]" $item "" item 
		if {$key == "\x1e"} {
		    # special case 'icon'
		    set icon 1
		    set key ""
		}
		if {[regexp -- {^(.*)(\\?&|\^.)$} $item "" item other]} {
		    # If this isn't true it's the \\?& branch.
		    # If this isn't true it's the \\?& branch.
		    if {!$::alpha::noCompoundMenus \
		      && ([string index $other 0] == "^")} {
			if {[info exists icon]} {
			    # add icon and set compound
			    scan [string index $other 1] %c int
			    # magic number according to which Alpha on 
			    # MacOS behaves!
			    incr int 208
			    set image ics8$int
			    if {![alphatk::getImage $image $int $item]} {
				unset image
			    }
			} else {
			    # add bitmap and set compound
			    set int [string index $other 1]
			    incr int 256
			    set image ICON$int
			    if {![alphatk::getImage $image $int $item]} {
				unset image
			    }
			}
		    }
		}
		if {[regsub -- {^\(} $item "" item]} {
		    set state "disabled"
		}
		if {[string index $item 0] eq "ª"} {
		    set item [string range $item 1 end]
		    set label $item
		} else {
		    set label [quote::Menuify $item]
		}
		regexp -- {^(.*)\u2026$} $item "" item
		$m add command -label [::msgcat::mc $label] \
		  -command "$cmdscript $item" -state $state
		if {[info exists image]} {
		    $m entryconfigure end -compound left -image $image
		    unset image
		}
	    }
	    default {
		regsub {^(<[UIOCSEB])*} $item "" item
		regexp -- {^(.*)(&|\^.)$} $item "" item
		if {[regsub -- {^\(} $item "" item]} {
		    set state "disabled"
		}
		if {[string index $item 0] eq "ª"} {
		    set item [string range $item 1 end]
		    set label $item
		} else {
		    set label [quote::Menuify $item]
		}
		regexp -- {^(.*)\u2026$} $item "" item
		if {[info exists opts(-t)]} {
		    set entrytype $opts(-t)
		}
		$m add command -label [::msgcat::mc $label] \
		  -command "$cmdscript $item" -state $state
	    }
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu_tags" --
 # 
 #  This very important procedure takes a standard Alpha menu name, and
 #  converts it into a list of two items: the actual visible textual
 #  label to use for the menu, and the suffix to use for the Tk menu
 #  widget.  The actual menu will be created with '$suffix'.
 #  
 #  To avoid nameclashes between converted toplevel items starting
 #  with a bullet, and submenus, we prepend 'top' or 'm' as appropriate.
 # -------------------------------------------------------------------------
 ##
if {![info exists allowBulletMenus]} {
    if {($alpha::macos == 2) && ([tk windowingsystem] == "aqua") \
      && [info exists alphatk_library]} {
	# Using my modified Tk with menu icon capability
	set allowBulletMenus 1
    } else {
	set allowBulletMenus 0
    }
}

proc menu_tags {n} {
    global menuFunnynames 
    if {[info exists menuFunnynames($n)]} {
	return [lindex $menuFunnynames($n) 1]
    }
    if {[string index $n 0] == "\u2022"} {
	global index::feature allowBulletMenus
	if {$allowBulletMenus} {
	    set root $n
	    regsub -all {\.} $root {dot} rr
	    regsub -all " " $rr "_" rr
	    return [list $root .menubar.m$rr]
	} else {
	    if {[info exists index::feature]} {
		foreach m [array names index::feature] {
		    if {[info exists ::$m] && ![array exists ::$m] \
		      && ([set ::$m] eq $n)} {
			regexp -- {(.*)Menu$} $m "" menuFunnynames($n)
			set menuFunnynames($n) \
			  [quote::Menuify $menuFunnynames($n)]
			# Little hack to get us a nice menu name for the 
			# open windows menu
			if {$menuFunnynames($n) == "Open Windows"} {
			    set menuFunnynames($n) "Windows"
			}
			if {$menuFunnynames($n) == "Alpha Developer"} {
			    set menuFunnynames($n) "Dev"
			}
			set root [::msgcat::mc $menuFunnynames($n)]
			break
		    }
		}
		# This is now obsolete, since this menu is a feature.
		if {![info exists root]} {
		    set menuFunnynames($n) "Windows"
		    set root [::msgcat::mc "Windows"]
		}
		regsub -all {\.} $root {dot} rr
		regsub -all " " $rr "_" rr
		set res [list $root .menubar.top$rr]
		if {[info exists menuFunnynames($n)]} {
		    set menuFunnynames($n) [list $menuFunnynames($n) $res]
		}
		return $res
	    }
	}
	alertnote "Bug in Alphatk: please report menu_tags problem"
    } else {
	set root [::msgcat::mc $n]
	regsub -all {\.} $root {dot} rr
	regsub -all " " $rr "_" rr
	return [list $root .menubar.m$rr]
    }
}

proc alphatk::menuForPopup {w hook newWidget {break 0}} {
    if {[catch {lindex [eval $hook] 0} name]} {
	# A bug...
	#puts stderr $name
	return
    }
    set widget [lindex [menu_tags $name] 1]
    if {![winfo exists $widget]} {
	if {$break} {
	    return -code break
	} else {
	    return
	}
    }
    # Need to work out what the best font is here for MacOS X
    global smallMenuFont
    if {[info exists smallMenuFont] && $smallMenuFont} {
	$widget configure -font {{Monaco} 7}
    }
    if {[winfo exists $newWidget]} {
	if {$w ne ""} {$w configure -menu $newWidget}
	return
    }
    $widget clone $newWidget
    if {$w ne ""} {
	# We may need to attach it to a menu
	$w configure -menu $newWidget
    }
}

# Obsolete now.
proc menu_set_widget {n w} {
    global menuFunnynames
    set menuFunnynames($n) [list $n [list "temp" $w popup]]
}

# Call this as follows:
# 
#   alpha::overrideMenuName alphaDeveloperMenu "Dev"
# 
# Put calls such as this in your prefs.tcl.  It may take
# one extra quit and restart to get these changes to apply.
proc alpha::overrideMenuName {menuName newName} {
    global menuFunnynames
    
    upvar \#0 $menuName origName

    # Then do this
    regsub -all {\.} $newName {} rr
    regsub -all " " $rr "_" rr
    set res [list $newName .menubar.top$rr]
    set menuFunnynames($origName) [list $newName $res]
    # Now make sure this is saved -- it will probably only
    # take effect on your next restart.
    prefs::modified menuFunnynames($origName)
}

# ×××× bindings ×××× #

#¥ deleteModeBindings <bindtag> - Delete all bindings for specified
# bind-tag.
proc deleteModeBindings {bindtag} {
    foreach b [bind ${bindtag}AlphaStyle] {
	bind ${bindtag}AlphaStyle $b {}
    }
}
#¥ describeBinding - display the binding of the next typed key sequence. 
proc describeBinding {} {
    set key [alpha::waitForKey]
    if {![describeBindingHelper $key]} {
	alertnote "No binding for $key!"
    }
}

proc describeBindingHelper {key {noshift 0}} {
    # Build bindtag list for frontmost window.
    if {[llength [winNames -f]]} {
	foreach b [text_cmd readvar bindtags] {
	    lappend taglist ${b}AlphaStyle
	}
    }
    lappend taglist Alpha AlphaStyle

    set oldkey $key
    while {1} {
	foreach tag $taglist {
	    if {[bind $tag "<${key}>"] != ""} {
		if {$noshift} {
		    set msg "\"${key}\" (without 'Shift', though) is bound to \r\r"
		} else {
		    set msg "\"${key}\" is bound to \r\r"
		}
		set binding [bind $tag <${key}>]
		regsub -- {^::alpha::executeAndRecord } $binding {} binding
		regsub -- {; break$} $binding {} binding
		alertnote "$msg [join $binding " "]"
		return 1
	    }
	}
	if {![regsub "Alt-" $key "Command-" key]} {
	    break
	}
    }
    set key $oldkey
    if {[string first "Shift-" $key] != -1} {
	regsub -all "Shift-" $key "" key
	return [describeBindingHelper $key 1]
    }
    return 0
}

#¥ keyAscii - insert ascii representation (in decimal)
#  of the keydown event, plus a modifier string, if 
#  necessary.
proc keyAscii {} {
    # Not quite right, but better than nothing.
    keyCode
}
#¥ keyCode - insert the key code along w/ a string 
#  representing and modifiers into the current window.
#  Can be used to create bindings in 'Alphabits'.
proc keyCode {} {
    set key [alpha::waitForKey]
    set items [split $key -]
    set mods {}
    global alpha::keymap alpha::command_key alpha::option_key
    foreach k [array names alpha::keymap] {
	if {$alpha::keymap($k) eq [lindex $items end]} {
	    set char $k
	    break
	}
    }
    if {![info exists char]} {
	set char [lindex $items end]
    }
    foreach mod [lrange $items 0 end-1] {
	if {$mod == "KeyPress"} { continue }
	if {$mod == "Shift"} {
	    append mods "s"
	} elseif {$mod == "Control"} {
	    append mods "z"
	} elseif {$mod == $alpha::command_key} {
	    append mods "c"
	} elseif {$mod == $alpha::option_key} {
	    append mods "o"
	} else {
	    error "Illegal modifier '$mod'"
	}
    }
    set result "'$char'"
    if {[string length $mods]} {
	append result " <$mods>"
    }
    insertText $result
}

array set alpha::mods [list Ctrl 144 Control 144 Shift 34 Option 72 \
  Cmd 1 Command 1 Meta 72 Alt 1]
set alpha::modifiers [list Ctrl Control Shift Option Alt Command Cmd Meta]
proc alpha::waitForKey {} {
    global alphaPriv
    variable modifiers
    set oldFocus [focus]
    set oldGrab [grab current .status]
    if {$oldGrab != ""} {
	set grabStatus [grab status $oldGrab]
    }
    status::msg "Press any key combination."
    set theStatus .status 
    #[winfo toplevel .status]
    grab -global $theStatus
    bind $theStatus <KeyPress> {set alphaPriv(done) [list %A %K %N] ; break}
    alpha::forceFocus $theStatus

    while 1 {
	vwait alphaPriv(done)
	#puts stderr $alphaPriv(done)
	regsub -all -- {_[LR]} \
	  [set keycode [lindex $alphaPriv(done) 1]] "" keycode
	append key "-" $keycode
	if {[lsearch -exact $modifiers $keycode] == -1} {
	    break
	}
    }
    # set ascii [lindex $alphaPriv(done) 0]
    
    unset alphaPriv(done)
    bind $theStatus <KeyPress> ""

    catch {grab release $theStatus}
    catch {focus $oldFocus}
    if {$oldGrab != ""} {
	if {$grabStatus == "global"} {
	    grab -global $oldGrab
	} else {
	    grab $oldGrab
	}
    }
    regsub -all {_[LR]} $key "" key
    if {[string first "Shift" $key] == -1} {
	if {[regexp -- {[A-Z]$} $key last]} {
	    regsub -- {[A-Z]$} $key [string tolower $last] key
	}
    }
    set key [string range $key 1 end]
    foreach mod $modifiers {
	regsub -all -- "(-$mod)+" $key "-$mod" key
    }
    regsub -all -- "(-$mod)+" $key "-$mod" key
    set splits [split $key -]
    set len [llength $splits]
    set key [lrange $splits 0 [expr {$len -2}]]
    lappend key "KeyPress" [lindex $splits end]
    set key [join $key -]
    status::msg "Got keypress: $key"
    return $key
}

array set alpha::asciikeymap [list 0x3 KP_Enter 0x03 KP_Enter 0x20 " " \
  0x8 0x33 0x08 0x33 0x7f Delete]

#¥ ascii (see bindings).
proc ascii {key args} {
    global alpha::asciikeymap
    if {[info exists alpha::asciikeymap($key)]} {
	set key $alpha::asciikeymap($key)
    } else {
	set key [text::Ascii $key 1]
    }
    uplevel Bind [list $key] $args
}
#¥ unascii  (see bindings)
proc unascii {key args} {
    global alpha::asciikeymap
    if {[info exists alpha::asciikeymap($key)]} {
	set key $alpha::asciikeymap($key)
    } else {
	set key [text::Ascii $key 1]
    }
    uplevel unBind [list $key] $args
}

#¥ bindingList [<mode>] - return list of bindings. The optional <mode> 
#  argument restricts the output to the bindings specific to that mode.
#  It can be "global" which is equivalent to the command with no option.
proc bindingList {{bindtag ""}} {
    if {$bindtag eq "global"} {
	set bindtag ""
    }
    set res {}
    set prefix {}
    if {$bindtag eq ""} {
	foreach tag {AlphaStyle Alpha} {
	    foreach b [bind $tag] {
		set fn [string trim [bind $tag $b]]
		regsub -- " ?; break\$" $fn "" fn
		regsub -all "\n" $fn ";" fn
		if {[regsub -- {^::alpha::executeAndRecord } $fn {} fn]} {
		    set fn [join $fn " "]
		} 
		regexp -- {<(.*)>} $b "" b
		set b "'${b}'"
		lappend res [list Bind $b $fn]
		if {[regexp {^prefixChar} $fn]} {
		    lappend prefix [lindex $fn end] ""
		}
	    }
	}
    }
    if {$bindtag eq ""} {
	global alpha::bindtags
	set mlist [array names alpha::bindtags]
    } else {
	set mlist [list $bindtag]
    }
    foreach m $mlist {
	set tag ${m}AlphaStyle
	foreach b [bind $tag] {
	    set fn [string trim [bind $tag $b]]
	    regsub -- " ?; break\$" $fn "" fn
	    regsub -all "\n" $fn ";" fn
	    if {[regsub -- {^::alpha::executeAndRecord } $fn {} fn]} {
		set fn [join $fn " "]
	    } 
	    regexp -- {<(.*)>} $b "" b
	    set b "'${b}'"
	    lappend res [list Bind $b $fn $m]
	    if {[regexp -- {^prefixChar} $fn]} {
		lappend prefix [lindex $fn end] $m
	    }
	}
    }
    foreach {tag m} $prefix {
	foreach b [bind $tag] {
	    set fn [string trim [bind $tag $b]]
	    regsub -- " ?; break\$" $fn "" fn
	    regsub -all "\n" $fn ";" fn
	    if {[regsub -- {^::alpha::executeAndRecord } $fn {} fn]} {
		set fn [join $fn " "]
	    } 
	    regexp -- {<(.*)>} $b "" b
	    set b "'$tag-${b}'"
	    if {$m != ""} {
		lappend res [list Bind $b $fn $m]
	    } else {
		lappend res [list Bind $b $fn]
	    }
	}
    }
    return [join $res "\r"]
}

#¥ unBind  (see bindings)
proc unBind {key mods args} {
    # blank out the script and send it to Bind to be zapped.
    if {[string index $mods 0] == "<"} {
	set args [lreplace $args 0 0 ""]
    } else {
	set mods ""
    }
    
    eval [list Bind $key $mods] $args
}

#¥ bind  (see bindings)
proc Bind {key mods args} {
    global alpha::keymap alpha::command_key alpha::option_key \
      tcl_platform alpha::menukeymap alpha::bindtags
    switch -- [llength $args] {
	0 { 
	    set script $mods 
	    set mods "" 
	    set bmode "" 
	}
	1 {
	    if {[string index $mods 0] == "<"} {
		set script [lindex $args 0]
		set bmode ""
	    } else {
		set script $mods
		set mods ""
		set bmode [lindex $args 0]
	    }
	}
	2 { 
	    set script [lindex $args 0]
	    set bmode [lindex $args 1] 
	}
	default {
	    error "Too many args to 'Bind'"
	}
    }
    set bind "<"
    # Build up list of modifiers, including list of
    # modifiers we don't have (which might be needed below).
    set not {}
    set yes {}
    if {[regexp -- {s} $mods]} {lappend yes "Shift"} else {
	lappend not "Shift"
    }
    if {[regexp -- {z} $mods]} {lappend yes "Control"} else {
	lappend not "Control"
    }
    if {[regexp -- {o} $mods]} {
	lappend yes $alpha::option_key
	set have_option 1
    } else {
	lappend not $alpha::option_key
    }
    if {[regexp -- {c} $mods]} {lappend yes $alpha::command_key} else {
	lappend not $alpha::command_key
    }
    if {[llength $yes]} {
	append bind [join $yes "-"] "-"
    }
    
    regexp -- "'(.)'" $key "" key
    if {[string length $key] > 1 && [regexp -- {^[a-z]} $key] \
      && ($key != "space") && ($key != "enter")} {
	set key "[string toupper [string index $key 0]][string range $key 1 end]"
    }
    while {[info exists alpha::keymap($key)]} {
	set key $alpha::keymap($key)
    } 
    if {[info exists alpha::menukeymap($key)]} {
	set key $alpha::menukeymap($key)
    }
    append bind "KeyPress-" $key ">"
    if {![catch {llength $script}]} {
	if {[lindex $script 0] eq "prefixChar"} {
	    append script " ${bmode}Prefix-[string toupper $key]"
	} elseif {[lindex $script 0] eq "startEscape"} {
	    lset script 0 "prefixChar"
	    append script " ${bmode}Prefix-e"
	}
    }
    
    # Keep a list of all known bindtags
    if {$bmode ne ""} {set alpha::bindtags($bmode) 1}
    
    if {[regexp -- {[eA-Z]} $mods prefix]} {
	append bmode Prefix- $prefix
	# auto-bind the prefix char if it's not currently set.
	# Alpha seems not to bother to bind ctrl-c automatically, for instance.
	if {[regexp -- {[A-Z]} $prefix got]} {
	    global alpha::prefixkeymap
	    if {[info exists alpha::prefixkeymap($got)]} {
		set prefixmod $alpha::prefixkeymap($got)
	    } else {
		set prefixmod "Control"
	    }
	    if {[bind Alpha <$prefixmod-KeyPress-[string tolower $prefix]>] == ""} {
		status::msg "We have no prefixChar binding for\
		  '$prefixmod-$prefix', so subsequent bindings\
		  will be ignored."
		#bind Alpha <Control-KeyPress-[string tolower $prefix]> \
		#"prefixChar Prefix-$prefix ; break"
	    }
	}
    } else {
	if {[string length $bmode]} {
	    set modeSpecific $bmode
	    append bmode AlphaStyle
	} else {
	    append bmode Alpha
	}
    }
    #echo [list bind $bmode $bind $script]
    if {$tcl_platform(platform) == "windows" && [info exists have_option]} {
	set ignore "no meta key"
    }
    if {$key == "Enter"} {
	set ignore "no Enter key"
    }
    if {[info exists ignore]} {
	echo "FYI: keyboard has $ignore; ignoring [list bind $bmode $bind $script]"
	return
    }
    if {[string length $script]} {
	set script "::alpha::executeAndRecord [list $script] ; break"
    }
    if {[catch [list bind $bmode $bind $script]]} {
	set script [lindex $script 1]
	global badkeylog ; lappend badkeylog "$bmode $bind $script"
	alertnote "Bad key '$bmode $bind $script' please report this."
	return
    }
    if {[string first "Shift" $bind] != -1} {
       if {[regexp -- {-[a-z]>$} $bind last]} {
	   regsub {[a-z]>$} $bind [string toupper $last] bind
	   if {[catch [list bind $bmode $bind $script]]} {
	       set script [lindex $script 1]
	       global badkeylog ; lappend badkeylog "$bmode $bind $script"
	       alertnote "Bad key '$bmode $bind $script' please report this."
	       return
	   }
       }
    }
    if {[info exists modeSpecific]} {
	alpha::fixGlobalBindings $bind $bmode $not
    } else {
	alpha::fixModeBindings $bind $script $yes
    }
}

proc alpha::bindForMenu {to bind script} {
    set mods [lrange [split [string trim $bind <>] -] 0 end-2]
    if {$to eq "Alpha"} {
	set not {}
	foreach mod [list Shift Control Meta Alt] {
	    if {[lsearch -exact $mods $mod] == -1} {
		lappend not $mod
	    }
	}
	alpha::fixModeBindings $bind $script $not
    } else {
	alpha::fixGlobalBindings $bind $to $mods
    }
}

proc alpha::fixGlobalBindings {bind bmode not} {
    # Now we need to look for bindings at the 'Alpha' level
    # which are more specific than this one.
    set l [llength $not]
    if {$l} {
	set combos [expr {1 << $l}]
	set bind [string range $bind 1 end]
	for {set i 1} {$i < $combos} {incr i} {
	    set mods "<"
	    for {set j 0} {$j < $l} {incr j} {
		if {$i & (1 << $j)} {
		    append mods [lindex $not $j] "-"
		}
	    }
	    append mods $bind
	    set bound [bind Alpha $mods]
	    #puts stdout "Check: $i, $combos, $j, $mods"
	    if {[string length $bound]} {
		# Got a more specific match.  We bind it
		# again for this mode specific case, unless
		# the current mode had already got something
		# bound to that keypress.
		if {[bind $bmode $mods] == ""} {
		    bind $bmode $mods $bound
		}
	    }
	}
    }
}

proc alpha::fixModeBindings {bind script yes} {
    # Now we need to look for mode-specific bindings which
    # are less specific than this one
    set l [llength $yes]
    if {$l} {
	set justkey [string range $bind \
	  [expr {1+[string last "-" $bind]}] end]
	# This loop can be pretty time consuming, but we do our
	# best to abort early.
	global alpha::bindtags
	foreach m [array names alpha::bindtags] {
	    append m AlphaStyle
	    if {![llength [bind $m]]} {continue}
	    if {[string length [bind $m $bind]]} {
		continue
	    }
	    
	    set combos [expr {1 << $l -1}]
	    for {set i 0} {$i < $combos} {incr i} {
		set mods "<"
		for {set j 0} {$j < $l} {incr j} {
		    if {$i & (1 << $j)} {
			append mods [lindex $yes $j] "-"
		    }
		}
		append mods $justkey
		set bound [bind $m $mods]
		#puts stdout "Check: ${m} $i, $combos, $j, $mods"
		if {[string length $bound]} {
		    #puts "got $bound"
		    # Got a less specific match.  We bind it
		    # again for this mode specific case.
		    bind $m $bind $script
		    continue
		}
	    }
	}
    }
}

if {$::tcl_platform(platform) == "windows"} {
    set alpha::prefixkeymap(X) Alt
    set alpha::prefixkeymap(C) Alt
}

# need 0x21 0x29 0x24 0x1b
array set alpha::menukeymap [list]
array set alpha::keymap [list 0x27 quoteright 0x2f period \
  - minus + plus * asterisk \# numbersign \
  0x14 3 0x15 4 0x26 j \" quotedbl \
  0x31 space "\r" Return " " space 0x33 BackSpace \
  enter KP_Enter Enter KP_Enter 0x34 KP_Enter 0x4c KP_Enter \
  0x24 Return "\n" backslash_n_is_not_allowed \
  "\t" Tab 0x30 Tab "" Left "" Right 0x7b Left 0x7c Right \
  Del Delete Esc Escape 0x35 Escape 0x7a F1 \
  0x7d Down 0x7e Up 0x13 @ 0x73 Home \
  Pgup Prior 0x74 Prior Pgdn Next 0x79 Next . period , comma \
  "\{" braceleft "\}" braceright \
  "\]" bracketright "\[" bracketleft = equal ? question "/" slash \
  ' quoteright ` quoteleft "\\" backslash ";" semicolon \
  Kpad/ KP_Divide Kpad* KP_Multiply Kpad- KP_Subtract Kpad+ KP_Add \
  KpadEnter KP_Enter Kpad. KP_Decimal KPad. KP_Decimal \
  0x53 KP_1 Kpad1 KP_1 Kpad2 KP_2 Kpad3 KP_3 \
  Kpad4 KP_4 Kpad5 KP_5 Kpad6 KP_6 Kpad7 KP_7 Kpad8 KP_8 Kpad9 KP_9 \
  Kpad0 KP_0 Kpad= KP_Equal ( parenleft ) parenright < less > greater \
  0x17 ( 0x1b ) 0x2a ` 0x32 < 0x21 ordfeminine \
  "ˆ" agrave	"‡" aacute	"‰" acircumflex	"‹" atilde	"Š" adiaeresis \
  "Ë" Agrave	"ç" Aacute	"å" Acircumflex	"Ì" Atilde	"€" Adiaeresis \
  "" egrave	"Ž" eacute	"" ecircumflex	"‘" ediaeresis\
  "é" Egrave	"ƒ" Eacute	"æ" Ecircumflex	"è" Ediaeresis\
  "“" igrave	"’" iacute	"”" icircumflex	"•" idiaeresis \
  "í" Igrave	"ê" Iacute	"ë" Icircumflex	"ì" Idiaeresis\
  "˜" ograve	"—" oacute	"™" ocircumflex	"›" otilde	"š" odiaeresis\
  "ñ" Ograve	"î" Oacute	"ï" Ocircumflex	"Í" Otilde	"…" Odiaeresis\
  "" ugrave	"œ" uacute	"ž" ucircumflex	"Ÿ" udiaeresis\
  "ô" Ugrave	"ò" Uacute	"ó" Ucircumflex	"†" Udiaeresis\
  0x29 odiaeresis ¬ diaeresis ~ asciitilde bar | \
  0x1c 8 0x19 9 \
  É ellipsis Á exclamdown £ sterling À questiondown ¤ section © copyright \
  ¡ degree : colon @ at ! exclam _ underscore ^ asciicircum % percent \
   ccedilla ‚ Ccedilla – ntilde „ Ntilde \
  Ø ydiaeresis Ù Ydiaeresis ¾ ae ® AE § ssharp Œ aring  Aring \
    dagger à doubledagger ¦ paragraph \
  ¿ oslash ¯ Oslash » ordfeminine ¼ masculine \
  Î Eth Ï eth \
  ]

# These symbols are not in the above list, yet.
#
# Abreve Amacron Aogonek App Arabic_ain Arabic_alef Arabic_alefmaksura
# Arabic_beh Arabic_comma Arabic_dad Arabic_dal Arabic_damma Arabic_dammatan
# Arabic_fatha Arabic_fathatan Arabic_feh Arabic_ghain Arabic_hah
# Arabic_hamza Arabic_hamzaonalef Arabic_hamzaonwaw Arabic_hamzaonyeh
# Arabic_hamzaunderalef Arabic_heh Arabic_jeem Arabic_kaf Arabic_kasra
# Arabic_kasratan Arabic_khah Arabic_lam Arabic_maddaonalef Arabic_meem
# Arabic_noon Arabic_qaf Arabic_question_mark Arabic_ra Arabic_sad
# Arabic_seen Arabic_semicolon Arabic_shadda Arabic_sheen Arabic_sukun
# Arabic_tah Arabic_tatweel Arabic_teh Arabic_tehmarbuta Arabic_thal
# Arabic_theh Arabic_waw Arabic_yeh Arabic_zah Arabic_zain Begin Break
# Byelorussian_SHORTU Byelorussian_shortu Cabovedot Cacute Cancel Caps_Lock
# Ccaron Ccircumflex Clear Cyrillic_A Cyrillic_BE
# Cyrillic_CHE Cyrillic_DE Cyrillic_E Cyrillic_EF Cyrillic_EL Cyrillic_EM
# Cyrillic_EN Cyrillic_ER Cyrillic_ES Cyrillic_GHE Cyrillic_HA
# Cyrillic_HARDSIGN Cyrillic_I Cyrillic_IE Cyrillic_IO Cyrillic_KA Cyrillic_O
# Cyrillic_PE Cyrillic_SHA Cyrillic_SHCHA Cyrillic_SHORTI Cyrillic_SOFTSIGN
# Cyrillic_TE Cyrillic_TSE Cyrillic_U Cyrillic_VE Cyrillic_YA Cyrillic_YERU
# Cyrillic_YU Cyrillic_ZE Cyrillic_ZHE Cyrillic_a Cyrillic_be Cyrillic_che
# Cyrillic_de Cyrillic_e Cyrillic_ef Cyrillic_el Cyrillic_em Cyrillic_en
# Cyrillic_er Cyrillic_es Cyrillic_ghe Cyrillic_ha Cyrillic_hardsign
# Cyrillic_i Cyrillic_ie Cyrillic_io Cyrillic_ka Cyrillic_o Cyrillic_pe
# Cyrillic_sha Cyrillic_shcha Cyrillic_shorti Cyrillic_softsign Cyrillic_te
# Cyrillic_tse Cyrillic_u Cyrillic_ve Cyrillic_ya Cyrillic_yeru Cyrillic_yu
# Cyrillic_ze Cyrillic_zhe Dcaron ENG Eabovedot Ecaron Emacron End Eogonek
# Execute F33 Find Gabovedot Gbreve Gcedilla Gcircumflex Greek_ALPHA
# Greek_ALPHAaccent Greek_BETA Greek_CHI Greek_DELTA Greek_EPSILON
# Greek_EPSILONaccent Greek_ETA Greek_ETAaccent Greek_GAMMA Greek_IOTA
# Greek_IOTAaccent Greek_IOTAaccentdiaeresis Greek_IOTAdiaeresis Greek_KAPPA
# Greek_LAMBDA Greek_MU Greek_NU Greek_OMEGA Greek_OMEGAaccent Greek_OMICRON
# Greek_OMICRONaccent Greek_PHI Greek_PI Greek_PSI Greek_RHO Greek_SIGMA
# Greek_TAU Greek_THETA Greek_UPSILON Greek_UPSILONaccent
# Greek_UPSILONaccentdieresis Greek_UPSILONdieresis Greek_XI Greek_ZETA
# Greek_alpha Greek_alphaaccent Greek_beta Greek_chi Greek_delta
# Greek_epsilon Greek_epsilonaccent Greek_eta Greek_etaaccent
# Greek_finalsmallsigma Greek_gamma Greek_iota Greek_iotaaccent
# Greek_iotaaccentdieresis Greek_iotadieresis Greek_kappa Greek_lambda
# Greek_mu Greek_nu Greek_omega Greek_omegaaccent Greek_omicron
# Greek_omicronaccent Greek_phi Greek_pi Greek_psi Greek_rho Greek_sigma
# Greek_tau Greek_theta Greek_upsilon Greek_upsilonaccent
# Greek_upsilonaccentdieresis Greek_upsilondieresis Greek_xi Greek_zeta
# Hcircumflex Hebrew_switch Help Hstroke Hyper_L Hyper_R Iabovedot Imacron
# Insert Iogonek Itilde Jcircumflex KP_F1 KP_F2 KP_F3 KP_F4 KP_Separator
# KP_Space KP_Tab Kanji Kcedilla L1 L10 L2 L3 L4 L5 L6 L7 L8 L9 Lcaron
# Lcedilla Linefeed Lstroke Macedonia_DSE Macedonia_GJE Macedonia_KJE
# Macedonia_dse Macedonia_gje Macedonia_kje Menu Meta_L Meta_R Multi_key
# Nacute Ncaron Ncedilla Num_Lock Odoubleacute Omacron Ooblique Pause Print
# R1 R10 R11 R12 R14 R15 R2 R3 R4 R5 R6 R7 R8 R9 Racute Rcaron Rcedilla Redo
# Sacute Scaron Scedilla Scircumflex Scroll_Lock Select Serbian_DJE
# Serbian_DZE Serbian_JE Serbian_LJE Serbian_NJE Serbian_TSHE Serbian_dje
# Serbian_dze Serbian_je Serbian_lje Serbian_nje Serbian_tshe 
# Shift_Lock  Super_L Super_R Sys_Req Tcaron Tcedilla Thorn Tslash
# Ubreve Udoubleacute Ukranian_I Ukranian_JE Ukranian_YI Ukranian_i
# Ukranian_je Ukranian_yi Umacron Undo Uogonek Uring Utilde Win_L Win_R
# Yacute Zabovedot Zacute Zcaron abovedot abreve acute amacron ampersand
# aogonek approximate asciicircum ballotcross blank botintegral botleftparens
# botleftsqbracket botleftsummation botrightparens botrightsqbracket
# botrightsummation bott botvertsummationconnector breve brokenbar cabovedot
# cacute careof caron ccaron ccircumflex cedilla cent checkerboard checkmark
# circle club cr crossinglines currency cursor dcaron decimalpoint diamond
# digitspace division dollar doubbaselinedot doubleacute doublelowquotemark
# downarrow downcaret downshoe downstile downtack eabovedot ecaron em3space
# em4space emacron emdash emfilledcircle emfilledrect emopencircle
# emopenrectangle emspace endash enfilledcircbullet enfilledsqbullet eng
# enopencircbullet enopensquarebullet enspace eogonek femalesymbol ff figdash
# filledlefttribullet filledrectbullet filledrighttribullet
# filledtribulletdown filledtribulletup fiveeighths fivesixths fourfifths
# function gabovedot gacute gbreve gcircumflex greaterthanequal guillemotleft
# guillemotright hairspace hcircumflex heart hebrew_aleph hebrew_ayin
# hebrew_beth hebrew_daleth hebrew_finalkaph hebrew_finalmem hebrew_finalnun
# hebrew_finalpe hebrew_finalzadi hebrew_gimmel hebrew_he hebrew_het
# hebrew_kaph hebrew_kuf hebrew_lamed hebrew_mem hebrew_nun hebrew_pe
# hebrew_resh hebrew_samekh hebrew_shin hebrew_taf hebrew_teth hebrew_waw
# hebrew_yod hebrew_zadi hebrew_zayin hexagram horizconnector horizlinescan1
# horizlinescan3 horizlinescan5 horizlinescan7 horizlinescan9 hstroke ht
# hyphen identical idotless ifonlyif imacron implies includedin includes
# infinity integral intersection iogonek itilde jcircumflex jot kana_A kana_E
# kana_HA kana_HE kana_HI kana_HO kana_HU kana_I kana_KA kana_KE kana_KI
# kana_KO kana_KU kana_MA kana_ME kana_MI kana_MO kana_MU kana_N kana_NA
# kana_NE kana_NI kana_NO kana_NU kana_O kana_RA kana_RE kana_RI kana_RO
# kana_RU kana_SA kana_SE kana_SHI kana_SO kana_SU kana_TA kana_TE kana_TI
# kana_TO kana_TU kana_U kana_WA kana_WO kana_YA kana_YO kana_YU kana_a
# kana_closingbracket kana_comma kana_e kana_fullstop kana_i kana_middledot
# kana_o kana_openingbracket kana_tu kana_u kana_ya kana_yo kana_yu kappa
# kcedilla latincross lcaron lcedilla leftanglebracket leftarrow leftcaret
# leftdoublequotemark leftmiddlecurlybrace leftopentriangle leftpointer
# leftradical leftshoe leftsinglequotemark leftt lefttack lessthanequal lf
# logicaland logicalor lowleftcorner lowrightcorner lstroke macron malesymbol
# maltesecross marker minutes mu multiply musicalflat musicalsharp nabla
# nacute ncaron ncedilla nl nobreakspace notequal notsign numerosign
# odoubleacute ogonek omacron oneeighth onefifth onehalf onequarter onesixth
# onesuperior onethird openrectbullet openstar opentribulletdown
# opentribulletup overbar overline partialderivative periodcentered
# phonographcopyright plusminus prescription prolongedsound punctspace quad
# racute radical rcaron rcedilla registered rightanglebracket rightarrow
# rightcaret rightdoublequotemark rightmiddlecurlybrace rightmiddlesummation
# rightopentriangle rightpointer rightshoe rightsinglequotemark rightt
# righttack sacute scaron scedilla scircumflex seconds semivoicedsound
# seveneighths signaturemark signifblank similarequal singlelowquotemark
# soliddiamond tcaron tcedilla telephone telephonerecorder therefore
# thinspace thorn threeeighths threefifths threequarters threesuperior
# topintegral topleftparens topleftradical topleftsqbracket topleftsummation
# toprightparens toprightsqbracket toprightsummation topt
# topvertsummationconnector trademark trademarkincircle tslash twofifths
# twosuperior twothirds ubreve udoubleacute umacron underbar union uogonek
# uparrow upcaret upleftcorner uprightcorner upshoe upstile uptack uring
# utilde variation vertbar vertconnector voicedsound vt yacute yen zabovedot
# zacute zcaron

# Not sure if last two are ok above.

# Keypad Numlock  NUMOCK            (Not NUMLOCK)

#¥ prefixChar - used to further modify the next keystroke 
#  combination, in the same manner as using the shift key 
#  in the next keystroke
proc prefixChar {args} {
    if {![llength $args]} {
	error "prefixChar called without argument; shouldn't happen!"
    } else {
	set key [lindex $args end]
	set msg [join [lrange $args 0 end-1] " "]
	if {$msg eq ""} {
	    set msg "Prefix ..."
	}
	status::msg $msg
	text_cmd binding_capture $key
    }
}
#¥ startEscape - used to further modify the next 
#  keystroke combination, in the same manner as using the 
#  shift key in the next keystroke
proc startEscape {args} {
    error "Shouldn't call 'startEscape' -- diverted to prefix char!"
}

#¥ float -m <menu> [<-h|-w|-l|-t|-M> <val>] [-n winname] [-z tag] -
#  Takes a created menu (not necessarily in the menubar), and makes a 
#  floating window out of it. Returns integer tag that is used to remove 
#  the window. NOT DYNAMIC!  W/ no options returns all currently defined menus.
#  Displayed w/ system floating window WDEF if system 7.5, plainDBox 
#  otherwise. -h through -M change width, height, left margin, top margin, and
#  margin between buttons. -z allows a ten-char tag to be specified for 
#  'floatShowHide'.
proc float {args} {
    global menu::floats
    # Default location
    set opts(-t) 0
    set opts(-l) 0
    getOpts [list -m -h -w -l -t -M -n -z]
    if {[llength $args]} {
	return -code error "Bad arguments '$args'"
    }
    if {![info exists opts(-m)]} {
	return -code error "No '-m menu' argument to float"
    }
    if {[info exists menu::floats($opts(-m))]} {
	set ww $menu::floats($opts(-m))
	if {[winfo exists $ww]} {
	    raise $ww
	    return -code error "Torn off menu for $opts(-m) already exists"
	}
	unset menu::floats($opts(-m))
    }

    foreach {mname widg font} [menu_tags $opts(-m)] {}
    set res [::tk::TearOffMenu $widg $opts(-l) $opts(-t)]
    set menu::floats($opts(-m)) $res
    
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"windows" {
	    wm attributes $res -toolwindow 1
	}
	default {
	}
    }
    return $opts(-m)
}
#¥ floatShowHide <on|off> <tag> - Shows or hides all floats w/ specified 
#  tag. Tags of current modes are automatically shown/hidden.
proc floatShowHide {onOff tag} {
    global menu::floats
    if {[info exists menu::floats($tag)]} {
	set w $menu::floats($tag)
	if {[winfo exists $w]} {
	    if {$onOff == "on"} {
		wm deiconify $w
	    } elseif {$onOff == "off"} {
		wm withdraw $w
	    } else {
		return -code error "illegal argument \"$onOff\" to\
		  floatShowHide, must be \"on\" or \"off\""
	    }
	}
    }
}
#¥ unfloat <float num> - removes specified floating window. W/ no options 
#  lists all floating windows.
proc unfloat {{floatName ""}} {
    global menu::floats
    if {![string length floatName]} {
	return [array names menu::floats]
    } elseif {![info exists menu::floats($floatName)]} {
	error "'$floatName' is not a floating menu."
    } else {
	catch {destroy $menu::floats($floatName)}
	unset menu::floats($floatName)
    }
}

proc closeFloat {} {
    global menu::floats
    unfloat [lindex [lsort [array names menu::floats]] end]
}

proc alphatk::floatJustCreated {w menu} {
    #puts "$w, [wm geometry $w], [winfo x $w] $::tk::Priv(x) $::tk::Priv(y)"
    global menu::floats
    if {[info exists menu::floats([wm title $menu])]} {
	set i 2
	while {[info exists "menu::floats([wm title $menu] <$i>)"]} {
	    incr i
	}
	wm title $menu "[wm title $menu] <$i>"
    }
    set menu::floats([wm title $menu]) $menu
    set x [expr {[winfo pointerx $menu] - [winfo width $menu]/2}]
    # Subtract 8 so the mouse is over the titlebar
    set y [expr {[winfo pointery $menu] - 8}]
    if {$y < 32} {
	set y 32
    }
    wm geometry $menu +$x+$y
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"windows" {
	    wm attributes $menu -toolwindow 1
	}
	default {
	}
    }
    # Put the focus on the torn-off palette, so the user can move it
    focus -force $menu
    bind $menu <Destroy> [list unfloat [wm title $menu]]
    enableMenuItem File closeFloat 1
}

