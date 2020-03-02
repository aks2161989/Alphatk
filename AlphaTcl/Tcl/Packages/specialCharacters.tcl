## -*-Tcl-*-
 # ==========================================================================
 # FILE: "specialCharacters.tcl"
 #                                          created: 08/14/2001 {11:41:46 am}
 #                                      last update: 05/24/2006 {12:32:35 PM}
 #                               
 # Description:
 # 
 # Inserts a "Special Characters" submenu to the "Text" menu, allowing for
 # easy insertion of special characters into the current window.  Users can
 # define their own keyboard shortcuts for any special character.
 # 
 # Note that all of these menus include a space after their names to help
 # ensure that they don't conflict with any mode-specific menu.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # Copyright (c) 2001-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::feature specialCharacters 1.0.1 "global-only" {
    # Initialization script.
    # Register a build proc for the menu.
    menu::buildProc "specialCharacters" {specialChars::buildMenu}
} {
    # Activation script.
    menu::insert     Edit items end "(-) "
    menu::insert     Edit submenu end "specialCharacters"
    hook::register   requireOpenWindowsHook [list "Edit" "specialCharacters"] 1
} {
    # De-activation script.
    menu::uninsert   Edit submenu end "specialCharacters"
    hook::deregister requireOpenWindowsHook [list "Edit" "specialCharacters"] 1
} uninstall {
    this-file
} preinit {
    # Contextual Menu module.

    # Declare a build proc for the Special Characters menu.  We add a
    # space after the menu name to distinguish it from the 'normal'
    # menu added in the menubar 'Text' menu -- the main difference is
    # determining where the character should be added wrt cursor,
    # highlighted selection, CM click position.
    menu::buildProc "specialCharacters " {specialChars::buildMenu "contextual"}
    # Allows you to international letters (diacritics) and other symbols into
    # the active window
    newPref f "specialCharacters Menu" 0 contextualMenu
} description {
    Creates an "Edit > Special Characters" menu for inserting international
    letters (diacritics) and other symbols into the active window
} help {
    This package creates an "Edit > Special Characters" menu for inserting
    international letters (diacritics) and other non-ascii symbols into the
    active window.
    
    This menu is useful for those who don't use these characters in their
    documents on a daily basis, and can't remember the default OS keyboard
    acrobatics necessary to insert them.  All of the characters in the
    submenus can be assigned a keyboard shortcut by selecting the command
    "Edit > Special Characters > Assign Shortcuts".
    
    <<specialChars::assignShortcuts>>

    A "Special Characters" Contextual Menu module is also available.
    
    Preferences: ContextualMenu
    
    Selecting an item in the CM menu will replace any selected text beneath
    the current cursor "click" position.
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
}

proc specialCharacters.tcl {} {}

namespace eval specialChars {}

# Define arrays containing the special characters.

array set specialChars::TypeChar {

    "a characters "     {‡ ˆ ‰ Š ‹ Œ (-) ç Ë å € Ì  (-) »}
    "e characters "     {Ž   ‘     (-) ƒ é æ è}
    "i characters "     {’ “ ” •     (-) ê í ë ì}
    "o characters "     {— ˜ ™ š › ¿ (-) î ñ ï … Í ¯ (-) ¼}
    "u characters "     {œ  ž Ÿ     (-) ò ô ó †}
    "misc chars "       {¾  – Ï Ø § (-) ® ‚ „ Î Ù (-) õ Þ ß}
    "accents "          {« ö ÷ ø ù ÿ ú û ý ¬}
    "quotes "           {Ô Õ Ò Ó â ã Ü Ý Ç È}
    "quoteText "        {ÔÉÕ ÒÉÓ ÜÉÝ ÇÉÈ}
    "greek "            {µ ¹ Æ ¸ · ?}
    "math "             {Å ­ ² ³ Â ± Ö ä ¶ º °}
    "symbols 1 "        {À Á ~   à ¡ á ¥ É Ã × Ú þ ü}
    "symbols 2 "        {¢ ? Ä £ ´ ¨ © ª ð ¤ ¦ Ð Ñ}
}

# "array names specialChars::TypeChar" won't give us the order that we want.

set specialChars::Menus [list \
  "a characters "       \
  "e characters "       \
  "i characters "       \
  "o characters "       \
  "u characters "       \
  "misc chars "         \
  "(-)"                 \
  "accents "            \
  "quotes "             \
  "quoteText "          \
  "greek "              \
  "math "               \
  "symbols 1 "          \
  "symbols 2 "          \
  ]

# If I can figure out all of Alpha's default bindings (or is it in the MacOS
# ??)  then I could include these in the menu as well.  These would be
# presented in the dialog to change them as well, or could be removed by
# assigning "no binding" to them.  But then this might not be the best idea
# for international users ...

array set specialChars::Defaults {
    dummy ""
}

##
 # --------------------------------------------------------------------------
 # 
 # "specialChars::buildMenu" --
 # 
 # Using the arrays defined above, create the "Special Characters" menu.
 # User defined shortcuts are used in the menu preferentially, otherwise any
 # shortcut defined in "specialChars::Defaults" will be used.
 # 
 # --------------------------------------------------------------------------
 ##

proc specialChars::buildMenu {{which "menubar"}} {
    
    global specialChars::Menus specialChars::TypeChar
    global specialChars::Keys  specialChars::Defaults
        
    switch -- $which {
	"menubar"    {
	    set p "specialChars::menuProc"
	    set n ""
	}
	"contextual" {
	    set p "specialChars::cmenuProc"
	    set n " "
	}
	default      {error "Unknown menu: $which"}
    }
    foreach menuName [set specialChars::Menus] {
	if {$menuName == "(-)"} {lappend menuList "(-)" ; continue}
	set charList ""
	foreach character [set specialChars::TypeChar($menuName)] {
	    if {[info exists specialChars::Keys($character)]} {
		lappend charList [set specialChars::Keys($character)]$character
	    } elseif {[info exists specialChars::Defaults($character)]} {
		lappend charList [set specialChars::Defaults($character)]$character
	    } else {
		lappend charList $character
	    } 
	}
	if {([set idx [lsearch -exact $charList {ª}]] > -1)} {
	    set charList [lreplace $charList $idx $idx {ªª}]
	} 
	# The menu name must be different for the menu bar and the
	# contextual menu, because each uses a different proc.
	lappend menuList [list Menu -m -n $menuName$n -p $p $charList]
    }
    set dim [expr {[llength [array names specialChars::Keys]] ? "" : "\("}]
    lappend menuList "(-)" "assignShortcutsÉ" "${dim}unsetShortcutsÉ"
    return [list build $menuList specialChars::menuProc {}]
}

##
 # --------------------------------------------------------------------------
 # 
 # "specialChars::menuProc" "specialChars::cmenuProc"  --
 # 
 # Insert the special character, or adjust shortcuts.  If from the contextual
 # menu, use the CM click positions to determine where to insert.
 # 
 # Includes a special case for É , which gets converted to an empty string.
 # 
 # --------------------------------------------------------------------------
 ##

proc specialChars::menuProc {menuName itemName} {
    
    switch -- $itemName {
        "" {
            set itemName "É"
        }
        "assignShortcuts" - "unsetShortcuts" {
            specialChars::$itemName
	    return
        }
    }
    if {([string trim $menuName] ne "quoteText")} {
	typeText $itemName
    } elseif {[isSelection]} {
	set posBeg  [getPos]
	set posEnd  [selEnd]
	set charBeg [string index $itemName 0]
	set charEnd [string index $itemName end]
	replaceText $posBeg $posEnd $charBeg [getSelect] $charEnd
	selectText $posBeg [pos::math $posEnd + \
	  [string length $charBeg] + [string length $charEnd]]
    } else {
	insertText [string index $itemName 0] [string index $itemName end]
    }
    return
}

proc specialChars::cmenuProc {menuName itemName} {
    
    selectText [lindex ${::alpha::CMArgs} 1] [lindex ${::alpha::CMArgs} 2]
    specialChars::menuProc $menuName $itemName
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "specialChars::assignShortcuts" --
 # 
 # Offer the list of all menus to the user, to adjust shortcuts.
 # 
 # --------------------------------------------------------------------------
 ##

proc specialChars::assignShortcuts {{title "Select a menu:"} {includeFinish "0"}} {

    global specialChars::Menus specialChars::TypeChar 
    global specialChars::Keys  specialChars::Defaults
    
    set menus [lremove -all [set specialChars::Menus] [list "(-)"]]
    if {$includeFinish} {set menus [concat [list "(Finish)"] $menus]}
    if {[catch {listpick -p $title $menus} type]} {
        status::msg "Cancelled." ; return
    } elseif {$type == "(Finish)"} {
	status::msg "New shortcuts have been assigned,\
	  and appear in the \"Special Characters\" menus."
    } 

    foreach character [set specialChars::TypeChar($type)] {
	if {$character == "(-)"} {
	    continue
	} elseif {[info exists specialChars::Keys($character)]} {
	    set specialCharBindings($character) [set specialChars::Keys($character)]
	} elseif {[info exists specialChars::Defaults($character)]} {
	    set specialCharBindings($character) [set specialChars::Defaults($character)]
	} else {
	    set specialCharBindings($character) ""
	} 
    } 
    set title "'[string trim $type]'  keyboard shortcuts É"
    catch {dialog::arrayBindings $title specialCharBindings 1}

    foreach character [set specialChars::TypeChar($type)] {
        if {[info exists specialCharBindings($character)]} {
	    set newBinding $specialCharBindings($character)
	    # Check to see if this is different from the default.
	    if {[info exists specialChars::Defaults($character)]} {
		set defaultBinding [set specialChars::Defaults($character)]
	    } else {
	        set defaultBinding ""
	    }
	    if {$newBinding == "" && [info exists specialChars::Keys($character)]} {
		prefs::modified specialChars::Keys($character)
	        unset specialChars::Keys($character)
	    } elseif {$newBinding != $defaultBinding} {
		set specialChars::Keys($character) $newBinding
		prefs::modified specialChars::Keys($character)
	    }
	} elseif {[info exists specialChars::Keys($character)]} {
	    prefs::modified specialChars::Keys($character)
	    unset specialChars::Keys($character)
	} 
    } 
    menu::buildSome "specialCharacters"
    # Now offer the list pick again.
    set title "Select another menu, or 'Finish'"
    if {[catch {specialChars::assignShortcuts $title 1}]} {
	status::msg "New keyboard shortcuts have been assigned,\
	  and appear in the \"Special Characters\" menus."
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "specialChars::unsetShortcuts" --
 # 
 # Offer the list of all user-defined shortcuts to the user to unset.  After
 # unsetting them, any shortcut defined in "specialChars::Defaults" will be
 # used in the menus.
 # 
 # --------------------------------------------------------------------------
 ##

proc specialChars::unsetShortcuts {{characterList ""}} {
    
    global specialChars::Keys 
    
    set charactersWithKeys [lsort [array names specialChars::Keys]]
    if {![llength $charactersWithKeys]} {
	status::msg "Cancelled -- there are no assigned shortcuts to unset."
	return
    } 
    if {$characterList == ""} {
	set title "Choose some shortcuts to unsetÉ"
	set characterList [listpick -l -p $title $charactersWithKeys]
    } 
    foreach character $characterList {
	if {[info exists specialChars::Keys($character)]} {
	    prefs::modified specialChars::Keys 
	    unset specialChars::Keys($character)
	} 
    }
    menu::buildSome "specialCharacters"
    if {[llength $characterList] == 1} {
	status::msg "The shortcut for $characterList has been unset."
    } elseif {[llength $characterList] > 1} {
	status::msg "The shortcuts for $characterList have been unset."
    } 
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  vers#  reason
# -------- --- ------ -----------
# 08/14/01 cbu 0.1    Created package, based on characters contained in the
#                       var "text::_Ascii", as defined in "stringsLists.tcl"
# 08/18/01 VMD 0.1.1  'dialog::arrayBindings' should take '1' rather than '0'
#                       as the last arg to indicate these are menu bindings.
# 09/19/01 VMD 0.1.2  Menu now inserted at top of Text rather than bottom.
# 11/02/01 JL  0.1.3  Minor bug fix for deactivation script.
# 05/08/02 cbu 0.2    Added contextual menu module.
# 09/13/02 cbu 0.2.1  Added ¿ and ¯ to stop slighting the Scandinavians.
#                     Unsetting bindings now works in "assignBindings".
#                     Added » and ¼ characters.
# 01/07/05 cbu 0.2.3  The ª char needs to be preceded by ª for the menu.
#                     Proper menu name is rebuilt when bindings change.
# 01/07/05 cbu 1.0    The "Unset Bindings" menu item is dimmed when there
#                       are no items to unbind.
#                     Changed "Bindings" to "Shortcuts".
#                     Re-organized character set lists. (Thanks, Dominique!)
#                     New "Special Characters > Quote Text" submenu.
#                     Quoted text strings are re-selected.
# 05/19/06 cbu 1.0.1  Menu is inserted at the bottom of the Edit menu to
#                       conform to Apple's HIG guidelines.
# 

# ===========================================================================
# 
# .