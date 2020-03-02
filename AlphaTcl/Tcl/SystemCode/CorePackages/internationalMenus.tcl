## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "internationalMenus.tcl"
 #                                          created: 04/05/1998 {09:31:24 PM}
 #                                      last update: 11/27/2004 {11:13:58 AM}
 # Description:
 #  
 # Changes incompatible menu key-bindings to keys which are useable on any
 # (western) international keyboard
 # 
 # This is an AlphaTcl core package, and you should not remove this file.
 # Alpha may not function very well without it.
 # 
 # Author: Andreas ??
 #  
 # This file is freely distributable under a BSD-style license.
 # 
 # ===========================================================================
 ##

# Feature declaration
alpha::extension internationalMenus 0.4.1 {
    # Menu-replacements (all western keyboards)
    hook::register keyboard intlMenu::standard "Australian"
    hook::register keyboard intlMenu::brasil "Brasil"
    hook::register keyboard intlMenu::standard "British"
    hook::register keyboard intlMenu::canadian_csa "Canadian - CSA"
    hook::register keyboard intlMenu::canadian_iso "Canadian - ISO"
    hook::register keyboard intlMenu::canadian_french "Canadian - French"
    hook::register keyboard intlMenu::danish "Danish"
    hook::register keyboard intlMenu::standard "Dutch"
    hook::register keyboard intlMenu::euro_one "Espa–ol - ISO"
    hook::register keyboard intlMenu::euro_one "Finnish"
    hook::register keyboard intlMenu::euro_two "Flemish"
    hook::register keyboard intlMenu::euro_two "French"
    hook::register keyboard intlMenu::euro_two "French - numerical"
    hook::register keyboard intlMenu::euro_one "German"
    hook::register keyboard intlMenu::euro_two "Italian"
    hook::register keyboard intlMenu::euro_one "Norwegian"
    hook::register keyboard intlMenu::roman_jis "Roman - JIS"
    hook::register keyboard intlMenu::spanish "Spanish"
    hook::register keyboard intlMenu::euro_one "Swedish"
    hook::register keyboard intlMenu::swiss "Swiss French"
    hook::register keyboard intlMenu::swiss "Swiss German"
    hook::register keyboard intlMenu::slovencrotian "Slovenian"
    hook::register keyboard intlMenu::slovencrotian "Croatian"
    hook::register keyboard intlMenu::standard "U.S."
    hook::register keyboard intlMenu::italian_pro "Italian - Pro"
    # Adjust a few menu items so that we can use their key-bindings on
    # systems with no Meta/Option key (e.g. Windows).  This used to
    # be a preference, but is now fixed.
    set removeOptionKeyFromMenus [expr {$::tcl_platform(platform) eq "windows"}]
    if {$removeOptionKeyFromMenus} {
	intlMenu::standard
    }
} maintainer {
} description {
    Changes incompatible menu Keyboard Shortcuts to keys which are useable on
    any (western) international keyboard
} help {
    This package changes incompatible menu keyboard shortcuts to keys which
    are useable on any (western) international keyboard.


	  	Table Of Contents

    "# Introduction"
    "# Which menu items are affected?"
    
    "# Teaching Alpha new keyboard layouts"

    
	  	Introduction

    By default, Alpha assumes that your keyboard layout is "U.S.".  As most
    "international" users will notice, keyboard layouts are different in
    different countries!  Therefore some default keyboard shortcuts for
    various menu items need to be adjusted.  For example, on a Swiss keyboard,
    '/' is Shift-7 (which means you have to press Shift to get '/').  This
    means there is no difference between Command-/ and Shift-Command-/ on such
    a keyboard.  In Alpha these two shortcuts used to be mapped separately to
    the menu items "OpenWins > Zoom" and "OpenWins > Single Page".

    If you're using a western keyboard Alpha can solve some of these problems
    for you.  The "International Menus" feature is always on by default (and
    it cannot be turned off).  It replaces some menu shortcuts and solves
    problems like the one just described.  However, only those keyboard
    shortcuts in the global menus "File" to "Windows" are modified.  Other
    menus may still have problems.

    You need to tell Alpha which keyboard layout you're using via the menu
    item "Config > Preferences > System Prefs > International".  (In a future
    version, Alpha should be able to get this information directly from the
    OS.) This will make sure that some bindings not defined in the menus work,
    e.g. that the Electric Braces work.  However, problematic shortcuts
    defined in the various packages are usually not cured by this.
    
    Preferences: International


	  	Which menu items are affected?

    The menu items that the International Menus package change are (depending
    on which keyboard layout you use, some of these may remain unchanged):

	Edit menu: 
	
    Shift Left/Right, Shift Left/Right Space

        Text menu: 
    
    Twiddle, Twiddle Words
	
	Search menu: 
	
    Return to Bookmark, Goto Line, Hilite To Pin

	Windows menu:

    Zoom, Default Size, Choose A Window


	====================================================================


	  	Teaching Alpha new keyboard layouts 

    This is really an advanced topic, and if might not be of much help if
    you're new to either Tcl or AlphaTcl.  This section assumes that you have
    read the Help file section "Alpha Manual # Changing Alpha's behavior".

    If you're not using a western keyboard or if you do encounter any
    problems, reading the following section might help to clarify things and
    could help you to fix the problem.  If you need help defining a new
    keyboard layout, ask a question on one of the mailing lists described in
    the "Readme" file.

    To solve the problem with shortcuts in the menus you can use the AlphaTcl
    proc: menu::replaceWith.  To solve the problem with the Swiss keyboard
    described above you would add the following to your preferences file:
       
	menu::replaceWith winMenu [list "//<Szoom" "//<S<I<OsinglePage"] \
	    items "<S//zoom" "<S<O<U/=singlePage"

    To define your keyboard layout, add a line like this to your "prefs.tcl"
    file:

	set "keyboards(U.S.)" {
	 {¤1234567890-=[];'\`,./}
	 {±!@#$%^&*()_+{}:"|~<>?}
	 <U/[
	 <U/]
	}

    The first two lines tell Alpha how to map using the 'Shift' key.  Shift
    maps each item in the upper string into the corresponding item in the
    lower string.

    The third and forth lines defines the keyboard shortcuts for the left and
    right braces, in this example to Shift-[ and Shift-].

    See the file "alphaDefinitions.tcl" for examples of keyboard layout
    definitions, and the source for this package ("internationalMenus.tcl")
    for more examples.

    If you define an array entry keyboards(my-country), then you can just
    select that in the international prefs dialog, and Alpha will set the
    flags correctly.  You can then send that keyboard array entry to the
    AlphaTcl-Users mailing list for inclusion in a future version of Alpha.

    If a package wishes to be told when the keyboard changes, it can do that
    by registering with the 'removekeyboard' or 'keyboard' hooks like this:

	# tell me when we switch to a "Swiss German" keyboard
	hook::register keyboard keys::swiss "Swiss German"
	# tell me when we disable a keyboard
	hook::register removekeyboard my_disable_proc
	# tell me when we enable a keyboard
	hook::register keyboard my_enable_proc

    In this way a clever package could remove the need for restarting Alpha by
    unbinding and then rebinding all necessary items.
} 

proc internationalMenus.tcl {} {}

namespace eval intlMenu {}

# Define some help procs so we save a lot of typing
proc intlMenu::change_winMenu {zoom zoom_char choose choose_char} {
    global removeOptionKeyFromMenus
    if {$removeOptionKeyFromMenus} {
	set code "<B"
    } else {
	set code "<I"
    }
    menu::replaceWith openWindowsMenu [list "//<E<Szoom" "//<S<I<OdefaultSize"] \
      items "$zoom_char<E<Szoom" "$zoom_char<S${code}<OdefaultSize"
    menu::replaceWith openWindowsMenu [list "/;chooseAWindowÉ"] \
      items "${choose_char}chooseAWindowÉ"
}

proc intlMenu::change_editMenu {twiddle twiddle_char \
  shiftLeft shiftLeft_char \
  shiftRight shiftRight_char} {
    global removeOptionKeyFromMenus
    if {$removeOptionKeyFromMenus} {
	set code "<B"
    } else {
	set code "<I"
    }
    menu::replaceWith Text [list "/`<E<Stwiddle" "/`<S<I<OtwiddleWords"] \
      items "$twiddle_char<E<Stwiddle" "$twiddle_char<S${code}<OtwiddleWords"
    menu::replaceWith Edit [list {/[<E<SshiftLeft} {/[<S<I<OshiftLeftSpace}] \
      items "$shiftLeft_char<E<SshiftLeft" "$shiftLeft_char<S${code}<OshiftLeftSpace" 
    menu::replaceWith Edit [list {/]<E<SshiftRight} {/]<S<I<OshiftRightSpace}] \
      items "$shiftRight_char<E<SshiftRight" "$shiftRight_char<S${code}<OshiftRightSpace"
}

proc intlMenu::change_editMenu_original {} {
    global removeOptionKeyFromMenus
    if {$removeOptionKeyFromMenus} {
	set code "<B"
    } else {
	set code "<I"
    }
    menu::replaceWith Text [list "/`<E<Stwiddle" "/`<S<I<OtwiddleWords"] \
      items "/`<E<Stwiddle" "/`<S${code}<OtwiddleWords"
    menu::replaceWith Edit [list {/[<E<SshiftLeft} {/[<S<I<OshiftLeftSpace}] \
      items {/[<E<SshiftLeft} "/\[<S${code}<OshiftLeftSpace"
    menu::replaceWith Edit [list {/]<E<SshiftRight} {/]<S<I<OshiftRightSpace}] \
      items {/]<E<SshiftRight} "/\]<S${code}<OshiftRightSpace"
}

# We ought to make the 'pin' menu a separate package, perhaps.
proc intlMenu::change_markHilite {to hilite_char} {
    menu::replaceWith Search {{Menu -n thePin {
	"/ <BsetPin"
	"exchangePointAndPin"
	"/=hiliteToPin"}
    }} items [format {Menu -n thePin {
	"/ <BsetPin"
	"exchangePointAndPin"
	"/s<OhiliteToPin"}
    } $hilite_char]
    
}

proc intlMenu::change_searchMenu {pop pop_char goto goto_char} {
    menu::replaceWith Search [list "/.<BreturnToBookmark"] \
      items "$pop_char<BreturnToBookmark"
    global removeOptionKeyFromMenus
    if {$removeOptionKeyFromMenus} {
	menu::replaceWith Search [list "/E<S<I<OenterReplaceString"] \
	  items "/E<S<B<OenterReplaceString"
	menu::replaceWith Search [list "/G<I<BgotoLine"] \
	  items "$goto_char<BgotoLine"
	menu::replaceWith Search [list "/S<S<B<IquickFindRegexp"] \
	  items "/S<S<B<UquickFindRegexp"
	menu::replaceWith Search [list "/R<E<O<IreplaceAll"] \
	  items "/R<E<O<BreplaceAll"
	menu::replaceWith Search [list "/G<S<I<OfindAgainBackward"] \
	  items "/G<S<B<OfindAgainBackward"
	menu::replaceWith Text [list "/D<S<I<OuncommentLine"] \
	  items "/D<S<B<OuncommentLine"
    } else {
	menu::replaceWith Search [list "/G<I<BgotoLine"] \
	  items "$goto_char<I<BgotoLine"
    }
}

proc intlMenu::bindBraces {} {
    Bind '\[' <zs>  normalLeftBrace
    Bind '\]' <zs>  normalRightBrace
}

proc intlMenu::unbindBraces {} {
    unBind '\[' <zs>  normalLeftBrace
    unBind '\]' <zs>  normalRightBrace
}

# These are the procs which are called automatically when the user chooses 
# one of the (western) international keyboards in the international prefs 
# dialog.
proc intlMenu::brasil {args} {
    intlMenu::change_winMenu zoom "/-" choose "/,"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/\\\\"
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::bindBraces
}

proc intlMenu::canadian_csa {args} {
    intlMenu::change_winMenu zoom "//" choose "/;"
    intlMenu::change_editMenu twiddle "" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/="
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::unbindBraces
}

proc intlMenu::canadian_iso {args} {
    intlMenu::change_winMenu zoom "/-" choose "/;"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/="
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::unbindBraces
}

proc intlMenu::canadian_french {args} {
    intlMenu::change_winMenu zoom "//" choose "/;"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/="
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::bindBraces
}

proc intlMenu::danish {args} {
    intlMenu::change_winMenu zoom "/-" choose "/,"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/$"
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::unbindBraces
}

proc intlMenu::euro_one {args} {
    intlMenu::change_winMenu zoom "/-" choose "/,"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to ""
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::unbindBraces
}

proc intlMenu::euro_two {args} {
    intlMenu::change_winMenu zoom "/-" choose "/;"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "/(" shiftRight "/)"
    intlMenu::change_markHilite to "/="
    intlMenu::change_searchMenu pop "/:" goto "/G"
    intlMenu::unbindBraces
}

proc intlMenu::spanish {args} {
    intlMenu::change_winMenu zoom "/-" choose "/;"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/="
    intlMenu::change_searchMenu pop "/." goto ""
    intlMenu::unbindBraces
}

proc intlMenu::swiss {args} {
    intlMenu::change_winMenu zoom "/-" choose "/,"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/$"
    intlMenu::change_searchMenu pop "/." goto ""
    intlMenu::unbindBraces
}

proc intlMenu::slovencrotian {args} {
    intlMenu::change_winMenu zoom "//" choose "/,"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "" shiftRight ""
    intlMenu::change_markHilite to "/-"
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::unbindBraces
}

proc intlMenu::standard {args} {
    intlMenu::change_winMenu zoom "//" choose "/;"
    intlMenu::change_editMenu_original
    intlMenu::change_markHilite to "/="
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::bindBraces
}

proc intlMenu::roman_jis {args} {
    intlMenu::change_winMenu zoom "//" choose "/;"
    intlMenu::change_editMenu twiddle "/@" shiftLeft "/\[" shiftRight "/\]"
    intlMenu::change_markHilite to "/-"
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::bindBraces
}
proc intlMenu::italian_pro {args} {
    intlMenu::change_winMenu zoom "/-" choose "/,"
    intlMenu::change_editMenu twiddle "/<" shiftLeft "<O<B/8" shiftRight "<O<B/9"
    intlMenu::change_markHilite to "/\\\\"
    intlMenu::change_searchMenu pop "/." goto "/G"
    intlMenu::unbindBraces
}
