## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "menusAndKeys.tcl"
 #                                    created: 12/9/97 {1:43:22 pm} 
 #                                last update: 02/01/2005 {10:49:42 AM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Reorganisation carried out by Vince Darley with much help from Tom
 # Fetherston, Johan Linde and suggestions from the alphatcl-developers
 # mailing list.  Alpha is shareware; please register with the author
 # using the register button in the about box.
 #  
 # 
 #  modified by  rev reason
 #  -------- --- --- -----------
 #  27/11/97 FBO x.x make keys::keyboardChanged use one more item in keyboards
 # ###################################################################
 ##

namespace eval menu {}
namespace eval keys {}
namespace eval bind {}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::bind" --
 # 
 #  Convert a preference of type 'binding' or 'menubinding' into a code
 #  to be inserted into a menu.  Menu-bindings are guaranteed to succeed.
 #  If an ordinary binding contains a prefixChar (e.g. you have bound
 #  ctrl-c followed by ctrl-x to something), then this procedure will
 #  return an empty string, since such bindings cannot appear in menus.
 #  Finally if it is a key-binding and it does not contain a modifier
 #  key, and the key is a normal key (not F1-F12 + few others), then
 #  it will appear in the menu, but the menu will not activate with
 #  that key.  On MacOS, menus can only activate with key-presses
 #  which include a modifier.
 #  
 #  Example usage (from the modeSearchPaths package):
 #  
 #	 newPref binding openSelection "<O<B/H" searchPaths
 #	 newPref binding sourceHeaderToggle "<O/f" searchPaths
 #   menu::addTo fileUtils \
 #	    "[menu::bind searchPathsmodeVars(sourceHeaderToggle) -]" \
 #		"[menu::bind searchPathsmodeVars(openSelection) -]"
 #  
 #  You can adjust these bindings in the package preferences dialog,
 #  but changes will not take effect until you restart Alpha.  Note
 #  that if the user selected menu-incompatible bindings, they would
 #  not operate without the addition of some code to Bind them.  One
 #  would need to add this:
 #  
 #   eval Bind \
 #     [keys::toBind $searchPathsmodeVars(sourceHeaderToggle)] \
 #     file::sourceHeaderToggle
 #   
 #  The optional arg is the rest of the menu item or '-' which means
 #  use the variable name (if a var) or array element (if an array).
 #  
 #  If the optional argument is given, and the menu item therefore
 #  contains a '/', it is considered to be two dynamic items, the
 #  second of which requires the option key to be used.
 #  
 #  Similarly '//' means use shift, '///' means shift-option,
 #  For instance 'set v /W<O ; menu::bind v close/closeAll//closeFloat'
 #  would give you the menu-item for 'close' in the file menu. 
 # -------------------------------------------------------------------------
 ##
proc menu::bind {var {item ""}} {
    upvar \#0 $var a
    if {[regexp {Ç(.*)È} $a]} { set ret "" } else { set ret $a }
    if {$item != ""} {
	if {$item == "-"} {
	    regsub -all {([a-zA-Z_:]+\(|\))} $var {} item
	}
	if {[regexp {/} $item]} {
	    set item "<S<E<K$item"
	    regsub {///} $item " <S<I<U<K" item
	    regsub {//} $item " <S<U<K" item
	    regsub {/} $item " <S<I<K" item
	    regsub -all {<K} $item $ret ret
	} else {
	    append ret $item
	}
    }
    return $ret
}

# ×××× flags-menus from prefs ×××× #
# The following four procs allow you to create flag menus with ticks
# very simply.  They adhere to the basic idea of the 'newPref' facility.
proc menu::makeFlagDummy {name {type list}} {
    switch -- $type {
	"array" {
	    return [list Menu -n $name -p menu::flagProc {}]
	}
	"list" {
	    return [list Menu -m -n $name -p menu::flagProc {}]
	}
    }
}

proc menu::makeFlagMenu {name {type list} {var ""} {in_array ""} \
  {nonFlagProc ""} {prologue ""} {epilogue ""}} {
    if {$var == ""} { set var $name }
    switch -- $type {
	"array" {
	    global $var menu::flagArray allFlags
	    set menu::flagArray($name) \
	      [list "array" $var "" $nonFlagProc]
	    foreach i [lsort [array names $var]] {
		if {[lsearch -exact $allFlags $i] != -1} {
		    lappend items [lindex [list "$i" "!¥$i"] [set ${var}($i)]]
		}
	    }
	    return [list Menu -t checkbutton -n $name \
	      -p menu::flagProc $items]
	}
	"list" {
	    global $var menu::flagArray
	    if {[string length $in_array]} {
		set menu::flagArray($name) \
		  [list "list" $in_array $var $nonFlagProc]
		global $in_array
		set val [set ${in_array}($var)]
	    } else {
		set menu::flagArray($name) \
		  [list "list" $var "" $nonFlagProc]
		set val [set $var]
	    }
	    set i [lsearch -exact [set items [prefs::options $var]] $val]
	    if {$i != -1} {
		set items [lreplace $items $i $i "!¥[lindex $items $i]"]
	    }
	    if {$prologue != ""} {
		set items [concat $prologue \
		  [expr {[llength $items] ? {(-} : ""}] $items]
	    } 
	    if {$epilogue != ""} {
		set items [concat $items \
		  [expr {[llength $items] ? {(-} : ""}] $epilogue]
	    }
	    return [list Menu -m -t radiobutton -n $name \
	      -p menu::flagProc $items]
	}
	default {
	    error "Other types not yet supported"
	}
    }
}

proc menu::stripMetaChars {menuItems} {
    set strippedItems ""
    
    foreach menuItem $menuItems {
	regsub -all {<(B|I|U|O|S|E)} $menuItem "" menuItem
	regsub -all {/.} $menuItem "" menuItem
	regsub -all {!.} $menuItem "" menuItem
	regsub -all {\^.} $menuItem "" menuItem
	regsub -all {É$} $menuItem "" menuItem
	lappend strippedItems $menuItem
    }
    
    return $strippedItems
}

proc menu::buildFlagMenu {name args} {
    eval [eval menu::makeFlagMenu [list $name] $args]
}

proc menu::flagProc {menu flag} {
    global menu::flagArray prefs::script
    set type [set menu::flagArray($menu)]
    
    set name [lindex $type 1]
    set lookup [lindex $type 2]
    if {$lookup eq ""} { set lookup $name }
    if {$name eq ""} {
	set fullname $lookup
    } else {
	set fullname "${name}($lookup)"
    }
    upvar \#0 $name a
    switch -- [lindex $type 0] {
	"array" {
	    if {[lsearch -exact [array names a] $flag] == -1} {
		[lindex $type 3] $menu $flag 
	    } else {
		set a($flag) [expr {1 - $a($flag)}]
		if {[info exists prefs::script($fullname)]} {
		    eval [set prefs::script($fullname)] [list $flag]
		}
		status::msg "$menu item '$flag' set to $a($flag)"
		markMenuItem $menu $flag $a($flag)
		prefs::modified ${name}($flag)
	    }
	}
	"list" {
	    # array entries are indexed by the '2' element.
	    if {[set var [lindex $type 2]] == ""} { set var $name }
	    
	    set idx [lsearch -exact [prefs::options $var] $flag]
	    # Workaround removal of ellipsis from menu items.
	    if {$idx == -1} {
		set idx [lsearch -exact [prefs::options $var] "${flag}É"]
		if {$idx != -1} {
		    append flag "É"
		}
	    }
	    if {[string length [lindex $type 3]] && ($idx == -1)} {
		[lindex $type 3] $menu $flag 
	    } else {
		if {[set b [lindex $type 2]] == ""} {
		    markMenuItem -m $menu $a off
		    set a $flag
		    prefs::modified [lindex $type 1]
		    status::msg "[lindex $type 1] set to $flag"
		} else {
		    markMenuItem -m $menu $a($b) off
		    set a($b) $flag
		    prefs::modified "[lindex $type 1]([lindex $type 2])"
		    status::msg "$menu set to $flag"
		}
		markMenuItem -m $menu $flag on
		if {[info exists prefs::script($fullname)]} {
		    eval [set prefs::script($fullname)] [list $flag]
		}
	    }
	}
	default {
	    error "Bad type '$type' to menu::flagProc"
	}
    }
}

# ×××× Bindings ×××× #

proc menu::bindingsFromArray {arr {include_empty 0}} {
    upvar 1 $arr ar
    set r {}
    foreach a [array names ar] {
	if {[set b $ar($a)] != "" || $include_empty} {
	    lappend r "$b$a"
	}
    }
    return $r
}

proc bind::fromArray {arr bindarr {unbind 0} {mode {}}} {
    upvar 1 $arr ar
    upvar 1 $bindarr br
    set r {}
    if {$unbind} {
	set bindcmd "keys::unbindKey"
    } else {
	set bindcmd "keys::bindKey"
    }
    foreach a [array names ar] {
	if {[set b $ar($a)] != ""} {
	    if {[info exists br($a)]} {
		catch {eval [$bindcmd $b] [list $br($a)] $mode}
	    } else {
		beep; status::msg "Bad bind-array entry '$a'"
	    }
	}
    }
}

### 
 # -------------------------------------------------------------------------
 # 
 # "keys::verboseKey" --
 # 
 #  Turn a string containing a menu key-code '/x' into a verbose description
 #  of that key.  The optional parameter declares a variable whose value
 #  will be set if the key is a normal key.
 # -------------------------------------------------------------------------
 ##
proc keys::verboseKey {kstr {normal {}}} {
    if {$normal != ""} {upvar 1 $normal n ; set n 0}
    if {![regexp {/(Kpad)(.)} $kstr "" key pad] \
      && ![regexp {/(.)} $kstr "" key]} { return "" }
    switch -regexp -- $key {
	{Kpad} {return "Key pad $pad"}
	{[a-z]} {
	    global keys::func
	    return [lindex ${keys::func} [expr {[text::Ascii $key] - 97}]]
	}
	"" {
	    return "Left"
	}
	"" {
	    return "Right"
	}
	"\x10" {
	    return "Up"
	}
	"" {
	    return "Down"
	}
	" " {
	    return "Space"
	}
	default {
	    set n 1
	    return $key
	}
    }
}

set keys::func {Enter Return Tab "Num Lock" F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 \
  F11 F12 F13 F14 F15 Help Delete "Fwd Del" Home End "Page Up" "Page Down"}

set keys::ascii {0x03 0x0d 0x09 0 0 0 0 0 0 0 0 0 0 0 \
  0 0 0 0 0 0 0x08 0 0 0 0 0}

set keys::bind {Enter 0x24 0x30 Clear F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 \
  F11 F12 F13 F14 F15 Help 0x33 Del Home End Pgup Pgdn}

array set keys::bindWithAscii {Enter 0x03}

proc keys::_bindKey {kstr addcode {un ""}} {
    global keys::bindWithAscii
    set key [keys::toBind $kstr $addcode]
    if {[info exists keys::bindWithAscii([lindex $key 0])]} {
	return [concat ${un}ascii \
	  [set keys::bindWithAscii([lindex $key 0])] [lindex $key 1]]
    } else {
	return [concat ${un}Bind $key]
    }
}

proc keys::bindKey {kstr {addcode {}}} {
    keys::_bindKey $kstr $addcode
}

proc keys::unbindKey {kstr {addcode {}}} {
    keys::_bindKey $kstr $addcode un    
}

## 
 # -------------------------------------------------------------------------
 # 
 # "keys::toBind" --
 # 
 #  Turn a menu key-modifier sequence into something suitable for
 #  a 'Bind' statement.  Copes with function keys and arrow keys.
 #  
 #  Use a couple of strings to perform shift-mappings, so that although
 #  the binding says it's bound to 'shift-1', say, in fact it must be
 #  bound to '!' (or shift-'!' which are equivalent), since '!' is a 
 #  shifted '1'.
 #  
 #  You can use 'addcode' to add modifiers.  Mostly useful for pairs
 #  of bindings stored in a single pref in which one is an option/shift
 #  modified version of the other.
 # -------------------------------------------------------------------------
 ##
proc keys::toBind {kstr {addcode {}}} {
    if {![regexp {/(Kpad.)$} $kstr "" key] \
      && ![regexp {/(.)} $kstr "" key]} { return "" }
    if {![string match Kpad* $key] && [regexp {[a-z]} $key]} {
	global keys::bind
	set key [lindex ${keys::bind} [expr {[text::Ascii $key] - 97}]]
    } elseif {[set i [lsearch -exact {" " "" "" "\x10" ""} $key]] != -1} {
	set key [lindex {0x31 0x7b 0x7c 0x7e 0x7d} $i]
    } elseif {![string match Kpad* $key]} {
	set key [string tolower $key]
    }
    if {[string length $key] == 1} {
	global keys::mapShiftBindFrom keys::mapShiftBindTo
	if {[regexp {[a-z]} $key] || ![regexp {^<U/} $kstr]} {
	    set key '${key}' 
	} elseif {[set i [string first $key ${keys::mapShiftBindFrom}]] != -1} {
	    set key '[string index ${keys::mapShiftBindTo} $i]'
	} else {
	    #alertnote "Weird key: $kstr, please tell Vince."
	    # Note from Vince: I think it's ok just to assume we can
	    # bind to the key like this, but it's possible there are
	    # some problems on international keyboards.  With a U.S.
	    # keyboard we should NEVER get here.
	    set key '${key}'
	}
    }
    global alpha::platform keys::international
    if {${alpha::platform} == "alpha"} {
	if {[info exists keys::international($key)]} {
	    set key [set keys::international($key)]
	}
    }
    if {[set a [keys::modifiersTo $kstr$addcode bind]] != ""} {
	return [list $key $a]
    } else {
	return [list $key]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "keys::keyboardChanged" --
 # 
 #  When we change the value of 'keyboards' in the international prefs,
 #  this is called, with the parameter 'keyboards'.
 #  
 #  It is also called at startup, with no parameter.
 #  
 #  FrŽdŽric Boulanger <Frederic.Boulanger@supelec.fr> Nov 27 1997
 #    Added one item to the keyboards items: a list of characters followed
 #    by corresponding key codes.
 #    keys::keyboardChanged now looks for these items and sets 
 #    keys::international to the corresponding key code for each character
 #    in the first list. This is so keys::toBind returns a key code 
 #    instead of a character, which makes Bind only Bind the given character
 #    and leave the shifted char unbound. The problem arose on a french 
 #    keyboard where '{' is '(' <o> and '[' is '(' <os> . Binding '(' <o>
 #    to bind::LeftBrace also binds '(' <os> to bind::LeftBrace, so it was
 #    impossible to type a '['. To avoid this problem, we have to Bind
 #    0x17 <o> to bind::LeftBrace, where 0x17 is the key code for '(' on a
 #    french keyboard.
 #    For other keyboards, I don't know the key codes, so if you have the
 #    same problem with bindings, you may change the definition of your 
 #    keyboard in alphaDefinitions.tcl to solve it.
 # -------------------------------------------------------------------------
 ##
proc keys::keyboardChanged {{flag "startup"}} {
    global keyboards keyboard keys::mapShiftBindFrom keys::mapShiftBindTo \
      oldkeyboard bind::LeftBrace bind::RightBrace keys::international
    if {$oldkeyboard != ""} {
	catch "unBind [keys::toBind ${bind::LeftBrace}] bind::LeftBrace"
	catch "unBind [keys::toBind ${bind::RightBrace}] bind::RightBrace"
	set i 0
	foreach k [lindex $keyboards($oldkeyboard) 4] {
	    if {[incr i] % 2} {unset -nocomplain keys::international($k)}
	}
	unset -nocomplain keys::international
	hook::callAll removekeyboard $oldkeyboard
    }
    # set new values
    set keys::mapShiftBindFrom [lindex $keyboards($keyboard) 0]
    set keys::mapShiftBindTo [lindex $keyboards($keyboard) 1]
    set bind::LeftBrace [lindex $keyboards($keyboard) 2]
    set bind::RightBrace [lindex $keyboards($keyboard) 3]
    if {[llength $keyboards($keyboard)] >= 5} {
	array set keys::international [lindex $keyboards($keyboard) 4]
    }
    # Bind
    catch "Bind [keys::toBind ${bind::LeftBrace}] bind::LeftBrace"
    catch "Bind [keys::toBind ${bind::RightBrace}] bind::RightBrace"
    # Call anything that's been registered to the new keyboard
    # (Usually a proc to change some menu-bindings).  Use:   
    #   hook::register keyboard "Swiss French" my-proc
    hook::callAll keyboard $keyboard
    if {$oldkeyboard != ""} {
	prefs::modified keyboard
	alertnote "Changing the keyboard may require you to restart\
	  Alpha for the bindings to be set correctly."
    }
    set oldkeyboard $keyboard
}

proc bind::fromPref {f {un ""}} {
    global prefs::binding
    if {[info exists prefs::binding($f)]} {
	set m [lindex [set prefs::binding($f)] 0]
	if {[set proc [lindex [set prefs::binding($f)] 1]] == 1} {
	    set proc $f
	}
	namespace eval ::alpha \
	  [list catch "${un}Bind [keys::toBind $old] [list $proc] $m"]
    }
}


## 
 # -------------------------------------------------------------------------
 # 
 # "keys::modifiersTo" --
 # 
 #  Turn a menu-modifier sequence into something else.  Options are 
 #  'verbose' (a textual description), 'bind' (a binding code-sequence),
 #  and 'menu' which just returns what was given.
 # -------------------------------------------------------------------------
 ##
proc keys::modifiersTo {key type} {
    global alpha::modifier_keys
    set key1 {}
    switch -- $type {
	"verbose" {
	    if {[regexp {Ç(.)È} $key d pref]} {
		if {$pref == "e"} {
		    append key1 "escape "
		} else {
		    append key1 "ctrl-$pref "
		}
	    }
	    if {[regexp {<U} $key]} {append key1 "shift-"}
	    if {[regexp {<B} $key]} {append key1 "ctrl-"}
	    if {[regexp {<I} $key]} {
		append key1 "[lindex ${alpha::modifier_keys} 3]-"
	    }
	    if {[regexp {<O} $key]} {
		append key1 "[lindex ${alpha::modifier_keys} 1]-"
	    }
	    return $key1
	}
	"tksym" {
	    if {[regexp {Ç(.)È} $key d pref]} {
		if {$pref == "e"} {
		    append key1 "Escape "
		} else {
		    append key1 "Control-$pref "
		}
	    }
	    if {[regexp {<U} $key]} {append key1 "Shift-"}
	    if {[regexp {<B} $key]} {append key1 "Control-"}
	    if {[regexp {<I} $key]} {
		append key1 "[lindex ${alpha::modifier_keys} 2]-"
	    } 
	    if {[regexp {<O} $key]} {
		append key1 "[lindex ${alpha::modifier_keys} 0]-"
	    }
	    return $key1
	}
	"bind" {
	    if {[regexp {<U} $key]} {append key1 "s"}
	    if {[regexp {<B} $key]} {append key1 "z"}
	    if {[regexp {<I} $key]} {append key1 "o"}
	    if {[regexp {<O} $key]} {append key1 "c"}
	    if {[regexp {Ç(.)È} $key d pref]} {
		append key1 $pref
	    }
	    if {$key1 != ""} {
		return "<${key1}>"
	    } else {
		return ""
	    }
	}
	"menu" {
	    if {[regexp {Ç(.)È} $key d pref]} {
		return ""
	    } else {
		return $key
	    }
	}
    }
}

proc keys::modToString {mod} {
    # build a string that represents all the modifiers pressed:
    # checking in this order cmd, shift, option, and ctrl
    if {$mod & 1} { append t "c" } else { append t "_" }
    if {$mod & 34} { append t "s" } else { append t "_" }
    if {$mod & 72} { append t "o" } else { append t "_" }
    if {$mod & 144} { append t "z" } else { append t "_" }
    return $t
}

## 
 # -------------------------------------------------------------------------
 # 
 # "keys::bindToMenu" --
 # 
 #  Doesn't yet cope with function keys etc, nor 0x31 type bindings,
 #  nor prefixChars (which can't go in a menu anyway).
 # -------------------------------------------------------------------------
 ##
proc keys::bindToMenu {i} {
    regexp {'(.)'[ \t]*<([^>]+)>} $i d key mods
    set key "/[string toupper $key]"
    if {[regexp {s} $mods]} {append key "<U"}
    if {[regexp {z} $mods]} {append key "<B"}
    if {[regexp {o} $mods]} {append key "<I"}
    if {[regexp {c} $mods]} {append key "<O"}
    return $key
}
	
## 
 # -------------------------------------------------------------------------
 # 
 # "keys::findPrefixChars" --
 # 
 #  This proc is rather slow, since it has to scan an enormous list of
 #  bindings.  However since it is only used from a few dialogs,
 #  that doesn't matter too much (i.e. it is quick enough on my machine).
 # -------------------------------------------------------------------------
 ##
proc keys::findPrefixChars {} {
    global alpha::platform
    set res ""
    foreach i [keys::findBindingsTo "\{?prefixChar\[^\r\n\]*"] {
	if {${alpha::platform} == "alpha"} {
	    if {![regexp {'(.)'[ \t]*<(z|[A-Z])>} $i "" key]} {
		beep; status::msg "A bad prefix char has been defined:\
		  Bind $i prefixChar, this will not work."
	    } else {
		lappend res [string toupper $key]
	    }
	} else {
	    if {[regexp -- "-(\[a-z\])'" $i "" key]} {
		lappend res [string toupper $key]
	    }
	}
    }
    return $res
}

proc keys::findBindingsTo {to {forMode ""} {lines 0}} {
    set pref {}
    if {$forMode == "*"} { set forMode "(\\w+)?" }
    set t [bindingList]
    while {[regexp -indices \
      "\[\r\n\]Bind(\[^\r\n\]+) $to *${forMode} *\[\r\n\]" $t d idx]} {
	if {$lines} {
	    lappend pref [string trim [eval string range [list $t] $d]]
	} else {
	    lappend pref [string trim [eval string range [list $t] $idx]]
	}
	set t [string range $t [lindex $idx 1] end]
    }
    return $pref
}

proc keys::findBindingsOf {of {mode ""}} {
    if {$mode == "*"} { set mode "(\\w+)?" }
    set t [bindingList]
    set pref ""
    while {[regexp -indices "\[\r\n\]Bind[quote::WhitespaceReg " \
      ${of} "](\[\\w:\]+) *${mode} *\[\r\n\]" $t l idx]} {
	lappend pref [string trim [eval string range [list $t] $l]]
	set t [string range $t [lindex $idx 1] end]
    }
    return $pref
}

proc keys::unsetBinding {v {mode ""}} {
    foreach i [keys::findBindingsOf $v $mode] {
	regsub {' '} $i {0x31} i
	eval "un${i}"
    }
}

# ×××× Key presses ×××× #

#     cmdKey                      = 0x01,      /* Bit 0 of high byte */
#     shiftKey                    = 0x02,      /* Bit 1 of high byte */
#     alphaLock                   = 0x04,      /* Bit 2 of high byte */
#     optionKey                   = 0x08,      /* Bit 3 of high byte */
#     controlKey                  = 0x10,      /* Bit 4 of high byte */
#     rightShiftKey               = 0x20,      /* Bit 5 of high byte */
#     rightOptionKey              = 0x40,      /* Bit 6 of high byte */
#     rightControlKey             = 0x80,      /* Bit 7 of high byte */

namespace eval key {}

proc key::optionPressed {{m ""}} {
    if {$m == ""} {set m [getModifiers]}
    return [expr {$m & 72}]
}
proc key::shiftPressed {{m ""}} {
    if {$m == ""} {set m [getModifiers]}
    return [expr {$m & 34}]
}
proc key::controlPressed {{m ""}} {
    if {$m == ""} {set m [getModifiers]}
    return [expr {$m & 144}]
}
proc key::cmdPressed {{m ""}} {
    if {$m == ""} {set m [getModifiers]}
    return [expr {$m & 1}]
}
proc key::capsLockPressed {{m ""}} {
    if {$m == ""} {set m [getModifiers]}
    return [expr {$m & 4}]
}

namespace eval prompt {}
## 
 # -------------------------------------------------------------------------
 # 
 # "prompt::getAKey" --
 # 
 #  'getChar' is modified by ctrl and option, so if the user presses one
 #  of them, we have to request the key again.  Also if the user pressed
 #  shift and the key wasn't A-Z, then we also have to ask again.  Finally
 #  if the key pressed was a non-ascii one, we have to select from a menu.
 #  
 #  This function is an alternative to 'dialog::getAKey'.  Hence it takes
 #  the same parameters, except it ignores some of them.
 #  
 #  Doesn't currently deal with the 'for_menu' flag which it should.
 # -------------------------------------------------------------------------
 ##
proc prompt::getAKey {{name ""} {keystr ""} {for_menu 1}} {
    beep ; status::msg "Press the key and modifiers"
    set char [string toupper [getChar]]
    set mod [getModifiers]
    if {$mod & 0xd8 || ($mod & 0x22) && ![regexp {[A-Z]} $char]} {
	beep; status::msg "Please press the key again, this\
	  time without modifiers."
	set char [string toupper [getChar]]
    }
    if {![regexp {[]\[=A-Z0-9`\\';,./-]} $char]} {
	global keys::ascii keys::func
	set keyAscii [text::Ascii $char]
	if {$keyAscii > 27 && $keyAscii < 32} {
	    set char [lindex {"" "" "\x10" ""} [expr {$ascii - 27}]]
	}
	set i 0
	foreach k ${keys::ascii} { 
	    if {$k eq $keyAscii} { 
		set char [text::Ascii [expr {$i + 97}] 1]
		break
	    }
	    incr i
	}
	if {$i == [llength ${keys::ascii}]} {
	    set char [dialog::optionMenu \
	      "This procedure cannot isolate which key that was.\
	      You'll have to select it manually" ${keys::func} "" 1]
	    set char [text::Ascii [expr {$char + 97}] 1]
	}
    }
    set res [keys::modToMenu $mod $char]
    if {!$for_menu} {
	beep; status::msg "If there is a prefix-char, hit that now\
	  (without the ctrl-key) else return."
	set char [string toupper [getChar]]
	if {[text::Ascii $char] == 27} { set char "e" } 
	if {[regexp -nocase {[a-z]} $char]} {append res "Ç${char}È"}
    }
    return $res
}

## 
 # cmdKey                      = 0x01,
 # shiftKey                    = 0x02,
 # alphaLock                   = 0x04,
 # optionKey                   = 0x08,
 # controlKey                  = 0x10,
 # rightShiftKey               = 0x20,
 # rightOptionKey              = 0x40,
 # rightControlKey             = 0x80,
 ##
# 'char' must be upper case, if it really is a char.
proc keys::modToMenu {mod {char ""}} {
    if {$char != ""} {
	set t "/${char}"
    } else {
	set t ""
    }
    # cmd
    if {$mod & 1} { append t "<O" }
    # shift
    if {$mod & 2 | $mod & 32} { append t "<U" }
    # option
    if {$mod & 8 | $mod & 64} { append t "<I" }
    # ctrl
    if {$mod & 16 | $mod & 128} { append t "<B" }
    return $t
}

# The old elecBindings package gave easy shortcuts for
# setting these bindings.  We might want to allow a 
# direct way in this dialog of setting some common
# bindings, but more easily with a button which modifies
# the dialog in place.
# 
# array set keys::specialBindings {
#     "Next Stop Or Indent" "/c"
#     "Complete" "<B/c"
#     "Expand" "<O/ "
#     "Prev Stop" "<U/c"
#     "Real Tab" "<I/c"
#     "Typewriter Tab" ""
#     "nth Stop" ""
#     "Clear All Stops" "<U<B/c"
#     "Next Stop" ""
# }
# 	}
# 	1 {
# array set keys::specialBindings {
#     "Next Stop Or Indent" ""
#     "Complete" ""
#     "Expand" "<O/ "
#     "Prev Stop" "<U<B/J"
#     "Real Tab" "<I/c"
#     "Typewriter Tab" ""
#     "nth Stop" "<B/c"
#     "Clear All Stops" "<U<B/c"
#     "Next Stop" "<B/J"
# }
# 
proc global::specialKeys {} {
    global keys::specialBindings keys::specialProcs
    # unbind old set
    bind::fromArray keys::specialBindings keys::specialProcs 1
    
    if {[catch {dialog::arrayBindings "Special keys" keys::specialBindings}]} {
	# cancelled so rebind old set
	bind::fromArray keys::specialBindings keys::specialProcs
	return
    }
    # Bind new set
    bind::fromArray keys::specialBindings keys::specialProcs
    # perhaps do something else?
    prefs::modified keys::specialBindings
    # Should we rename this dialog from 'special' or rename this hook?
    hook::callAll electricBindings *
}


## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::basicKeyBindings" --
 # 
 #  Bind all the obvious stuff, so cursor keys etc actually work!
 # -------------------------------------------------------------------------
 ##
proc alpha::basicKeyBindings {} {
    global alpha::platform
    
    Bind Left  backwardChar
    Bind Left <c> beginningOfLine
    Bind Left <s> backwardCharSelect
    Bind Left <sc> beginningLineSelect
    Bind Left <z> {scrollLeftCol 15}
    
    Bind Right  forwardChar
    Bind Right <c> endOfLine
    Bind Right <s> forwardCharSelect
    Bind Right <sc> endLineSelect
    Bind Right <z> {scrollRightCol 15}

    if {${alpha::platform} == "tk"} {
	Bind Left <cz> backwardWord
	Bind Right <cz> forwardWord
	Bind Left <scz> backwardWordSelect
	Bind Right <scz> forwardWordSelect
    } else {
	Bind Left <o> backwardWord
	Bind Right <o> forwardWord
	Bind Left <os> backwardWordSelect
	Bind Right <os> forwardWordSelect
    }
    
    Bind Up        previousLine
    Bind Up <s>    prevLineSelect
    Bind Up <sc>   beginningBufferSelect
    Bind Up <z>    scrollUpLine
    
    Bind Down      nextLine
    Bind Down <s>  nextLineSelect
    Bind Down <sc> endBufferSelect
    Bind Down <z>  scrollDownLine

    if {${alpha::platform} == "tk"} {
    } else {
	Bind Up <o>    pageBack
	Bind Down <o>  pageForward
    }
    
    # Keypad definitions
    Bind Kpad4     backwardWord 				
    Bind Kpad4 <c> backwardDeleteWord 
    Bind Kpad6     forwardWord 				
    Bind Kpad6 <c> deleteWord 
    Bind Clear <s> toggleNumLock
    Bind Clear     insertToTop
    Bind Kpad- <s> nextWindow
    Bind Kpad+     swapWithNext
    Bind Kpad-     prevWindow
    Bind Kpad0	   pageBack
    #Bind Enter	   pageForward
    ascii 0x03     pageForward
    Bind Kpad1     prevFunc
    Bind Kpad3     nextFunc
    Bind Kpad.     endOfBuffer 				
    Bind Kpad2     hiliteToPin
    Bind Kpad5     exchangePointAndPin 	
    Bind Kpad7     backwardDeleteWord 		
    Bind Kpad8     beginningOfBuffer 				
    Bind Kpad9     deleteWord 				
    
    Bind Help   	alphaHelp 					
    Bind Home   	beginningOfBuffer 			
    Bind End    	endOfBuffer 				
    Bind Pgup   	pageBack 					
    Bind Pgdn   	pageForward
    # The first two of these cause problems with dead-keys, whereas the
    # latter two work ok!  Thanks Dominique
    #Bind Del    	deleteChar 				
    #Bind 0x33    	backSpace
    ascii 0x08  backSpace
    ascii 0x7f  deleteChar
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::keyBindings" --
 # 
 #  Bind some 'standard' alpha key-bindings
 # -------------------------------------------------------------------------
 ##
proc alpha::keyBindings {} {
    global alpha::platform
    
    # We need to bind this because it acts as save and saveAs (when 
    # 'save' would be disabled).  In Alpha 8/X it is not strictly 
    # necessary, since disabled menu bindings still fire, but we 
    # should not rely on that bad behaviour.  In Alphatk we do really
    # need this.
    Bind 's' <c> save
    
    Bind Del    <z> forwardDeleteWhitespace
    Bind 0x33   <z> forwardDeleteWhitespace
    Bind 0x33  <sz> forwardDeleteUntil
    
    if {${alpha::platform} == "tk"} {
	Bind Del <c> deleteWord
	Bind 0x33 <s>  backwardDeleteWord
    } else {
	Bind 0x33 <so> deleteWord
	Bind 0x33 <o>  backwardDeleteWord
	# Not required on Alphatk
	Bind 'l' <oz> refresh
    }

    Bind Up <c>    beginningOfBuffer
    Bind Down <c>  endOfBuffer
    Bind help <z>   {package::helpWindow $mode}

    Bind 't' <z> 	insertToTop		
    Bind '\ ' <z> 	setPin
    
    # Another control prefix.
    Bind 'q' <z> 	prefixChar
    Bind 't' <Q>	shrinkHigh
    Bind 'b' <Q>	shrinkLow
    Bind 'l' <Q>	shrinkLeft
    Bind 'r' <Q>	shrinkRight
    Bind 'c' <Q>	chooseAWindow
    Bind 'h' <Q>	winhorizontally
    Bind 'm' <Q>	minimize
    Bind 'n' <Q>	nextWindow
    Bind 'o' <Q>	bufferOtherWindow
    Bind 'p' <Q>	prevWindow
    Bind 's' <Q>	swapWithNext
    Bind 'a' <Q>	wintiled
    Bind 'v' <Q>	winvertically
    Bind 'f' <Q>	shrinkFull
    Bind '2' <Q>	toggleSplitWindow
    
    Bind Esc	startEscape
    Bind 'h' <z>	hiliteWord
    
    Bind 's' <ze> regIsearch
    
    global tcl_platform
    if {$tcl_platform(platform) != "windows"} {
	# Maybe these should be moved to emacs package.
	Bind 'z' <z> 	pageBack
	Bind 'c' <z> 	prefixChar
	Bind 'x' <z> 	prefixChar
	Bind 'm' <X> matchingLines 
	Bind 'l' <C> ::comment::dividingLine
    }
    
    # global bindings for CR
    Bind '\r'       bind::CarriageReturn
    Bind '\r' <c>  {typeText "\r" ; bind::IndentLine}
    Bind '\r' <z>  {typeText "\r"}

    Bind   F1 	    bind::Completion 	
    Bind '\[' <zs>  normalLeftBrace
    Bind '\]' <zs>  normalRightBrace
    # Useful for C-like-modes
    Bind '\;'      bind::electricSemi
    Bind '\;' <z> "typeText {;}"
    Bind 'l' <z> centerRedraw
    Bind 'x' <e> execute
}





