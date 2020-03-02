## -*-Tcl-*-
 # ###################################################################
 # 
 #  FILE: "latexAccents.tcl"
 #                                    created: 14/1/1998 {6:57:41 pm} 
 #                                last update: 02/23/2006 {04:53:30 PM} 
 # Version:      1.2
 # Purpose:      Translates Mac characters to their LaTeX equivalents 
 #	         and vice-versa
 # Language:     TCL
 # Author:       F. Miguel Dionísio
 # Email:	 fmd@math.ist.utl.pt
 # Copying:      Free
 # 
 # The purpose of this tcl script is to translate mac characters to their
 # LaTeX equivalents and vice-versa (from within the Mac editor Alpha).  The
 # characters are those of the Courier font, with the exception of the ones
 # that, in LaTeX, belong to math mode (see list below).  This is useful to
 # people who share their LaTeX sources with non-Mac users.
 # 
 # Two procedures are defined: "TeX::ConvertAccentstoLaTeX" and
 # "TeX::ConvertLaTeXtoAccents" that convert all SELECTED text.  The
 # conversion "TeX::ConvertLaTeXtoAccents" tries to match (using regular
 # expressions) various forms of the character definition in LaTeX.
 #
 # ###################################################################
 # 
 # Modified on 8/07/1999 by Dominique d'Humieres
 # E-mail: <dominiq@physique.ens.fr>
 # 
 # Added the choice between different possible syntax for accents and
 # ligatures: é replaced by \'{e} or \'e, and œ by \oe{}, {\oe} or \oe
 # ('accentSyntax' in the 'Mode Prefs->Preferences...' dialog).
 # 
 # Added the binding of accented characters to their TeX form depending
 # on the above preference: typing é yields \'e (or \'{e}) (set by 
 # 'bindLatexAccents' in the 'Mode Prefs->Preferences...' dialog).
 # 
 # On 4/08/1999 added the Slovenian keyboard and a hook to the keyboard.
 # 
 # On 11/10/1999 added the option to keep the Mac accents when characters
 # are typed in comments. Note that this option does not work when
 # 'accentsToLatexInRegion' is used. The default setting of this flag is on,
 # it requires that 'bindLatexAccents' is on.
 # 
 # Added also a rather convoluted way to select and deselect the
 # 'latexAccents' feature in 'Config->Mode Prefs->Menus and Features…'
 # {Select features for mode 'TeX'}.
 # 
 # On 21/10/1999 the default setting for 'bindLatexAccents' is now off. Small
 # change in 'TeX::Accents::bindOptionLatex' in order to avoid to
 # bind option+key for keys already bound.
 # 
 # On 12/01/2000 added the flag 'accentSmartEscape'. When set this flag
 # allows one to delete the TeX accents with the backspace key. A single
 # character deletion is bound to SHIFT+backspace. The default setting
 # of this flag is off.
 # Works with any character for the \', \^, \`, \", \~, \c and \v accents,
 # but not for the \=, \., \u, \H, \r, \t, \d, \b, and \k ones.
 # 
 # On 1/02/2000 did some cleaning of the 'TeX::Accents::initialize',
 # 'TeX::Accents::activate', and 'TeX::Accents::deactivate' procs.
 # 
 # NOTE: if the latexAccents package is activated as a global feature and the
 # 'bindLatexAccents' flag is on, the bindings are done only for the TeX and
 # Bib modes (this departs from the usual behavior of global settings, but
 # this is probably better than having the TeX accents for all modes).  See
 # also the bug list at the end of these comments.
 # 
 # On 4/02/2000 made some corrections following the remarks from Pierre
 # Basso, Igor Kramberger, and Bart Truyen.
 # 
 # On 18/3/2000 added the 'Brasil' keyboard.
 # 
 # On 4/4/2000 added the 'Italian Pro' keyboard.
 # 
 # On 25/8/2000 modified 'TeX::Accents::bindLatex' and
 # 'TeX::Accents::bindOptionLatex' and places using regexp for word boundary
 # for Alpha8.
 # 
 # On 11/9/2000 removed the modification of 'TeX::Accents::bindLatex' and 
 # 'TeX::Accents::bindOptionLatex' for Alpha8.
 # 
 # On 24/8/2002 put most procs in TeX::Accents namespace, other minor
 # modifications in preparation for new TeX mode. (cbu)
 #
 # On 18/1/2005 made use of 'bindtags' to simplify the code a lot 
 # (Vince).
 # 
 ######################################################################
 #
 # List of characters on non-Slovenian keyboards (use Courier to see them):
 # 
 #	"à"	"á"	"â"	"ã"	"ä"	 "å"
 #	"À"	"Á"	"Â"	"Ã"	"Ä"	 "Å"
 #	"è"	"é"	"ê"	"ë"
 #	"È"	"É"	"Ê"	"Ë"
 #	"ì"	"í"	"î"	"ï"
 #	"Ì"	"Í"	"Î"	"Ï"
 #	"ò"	"ó"	"ô"	"õ"	"ö"
 #	"Ò"	"Ó"	"Ô"	"Õ"	"Ö"
 #	"ù"	"ú"	"û"	"ü"
 #	"Ù"	"Ú"	"Û"	"Ü"
 #	"œ"	"Œ"	"æ"	"Æ"
 #	"ç"	"ñ"	"…"
 #	"Ç"	"Ñ"
 #	"ß"	"£"	"ø"	"Ø"	"§"	"¶"
 #	"ª"	"º"	"°"
 #	"©"	"†"	"¿"	"¡"
 #	"‡"	"ÿ"	"Ÿ"
 # 
 #  WARNING: Ÿ appears different in Monaco
 # 
 # List of characters on Slovenian keyboards (use Slovenian Courier to see them):
 # 
 #	"à"	"á"	"â"	"ã"	"ä"	 "å"
 #	"À"	"Á"	"Â"	"Ã"	"Ä"	 "Å"
 #	"è"	"é"	"ê"	"ë"
 #	"È"	"É"	"˝"	"˙"
 #	"ì"	"í"	"î"	"ï"
 #	"Ì"	"Í"	"Î"	"Ï"
 #	"ò"	"ó"	"ô"	"õ"	"ö"
 #	"Ò"	"Ó"	"Ô"	"Õ"	"Ö"
 #	"ù"	"ú"	"û"	"ü"
 #	"Ù"	"Ú"	"Û"	"Ü"
 #	"œ"	"Œ"	"˛"	"ﬁ"
 #	"ç"	"ñ"	"…"
 #	"Ç"	"Ñ"
 #	"ß"	"£"	"ø"	"Ø"	"§"	"¶"
 #	"ª"	"º"	"°"
 #	"©"	"†"	"¿"	"¡"
 #	"Ê"	"Ë"	""	"π"	"æ"	"∆"	"»"	"–"	"©"	"Æ"
 # 
 #  List of OMITTED characters from Courier:
 # 
 #  ”,“,––,— —, ¢, and the following symbols from mathematical mode:
 #  •,∫,∂,ƒ,∆,¬,µ,π,√,∑,≈,?,∞,≠,≤,≥,÷,«,∏,◊,±,»
 # 
 # If you find some more problems please tell me. (fmd@math.ist.utl.pt)
 #
 ######################################################################
 # 
 # Alpha commands used: getText, getPos, selEnd, replaceText; 
 # all others are TCL built-ins
 # 
 # ####################################################################
 # 
 # The binding of accented characters is done for the TeX and Bib modes.  The
 # characters obtained from keys without the option modifier are bound
 # without knowledge of the keyboard (provided the characters in
 # 'TeX::_asciiAccents' yield the TeX equivalent in
 # 'TeX::Accents::_latexAccents').
 # 
 # I have been unable to do the same thing for the characters requiring the
 # option modifier.  The binding is then done using the 'TeX_keyboards' array
 # which stores a list of four strings for each keyboard known by Alpha: the
 # first string stores the characters obtained with the option modifier, the
 # second one the corresponding keys without modifier, the third one the
 # characters obtained with the option + shift modifiers, and the last one
 # the corresponding keys without modifier.
 # 
 # There are many characters which can be accessed either through a
 # 'dead-key' or with option (+ shift) modifier; most of the time I did not
 # put in the 'TeX_keyboards' table the corresponding characters with the
 # option modifier (with a few exceptions such as 'ê' for the Flemish
 # keyboard which can be accessed through option+e).
 # 
 # I have done uneducated guesses for the non-French keyboards and I have
 # only done some (but non exhaustive) testing, so if you find missing
 # characters or errors let me know.
 # 
 # If you have personnal reason to use your own keyboard map, you can put in
 # your 'TeXPrefs.tcl' file (replacing 'French' by the name of your keyboard
 # and doing the same modification in your 'BibPrefs.tcl' file if you want
 # the same binding in the Bib mode):
 # 
 #  TeX::Accents::bindOptionLatex 0
 # 
 #  set "TeX_keyboards(French)" {
 #   {æøœß©¶¡ÉÈÇÀÙ…}
 #   {azobc§!éèçàù;}
 #   {ÆØŒ¿ªº}
 #   {azo,fm}
 #  }
 # 
 #  TeX::Accents::bindOptionLatex 1
 # 
 # Bugs:
 # 
 # The following keyboards are set by default to the U.S. one: Croatian.
 # Addung the correct Croatian keyboard requires something similar to
 # the Slovenian one, but much more work. I shall be motivated to do it
 # only if someone shows some interest for it!
 # 
 # During the testing I switched between different keyboards without
 # restarting Alpha, unbinding and binding the accent keys.
 # Sometimes the binding function did not work; trying to trace the
 # procedure set the binding to work. This bug should not appear under
 # normal use (?).
 # 
 # The package should work fine whether activated at the global level 
 # (but why would you want that?!), or just for certain modes.
 # 
 ##

# extension declaration - notice that we use the currently-unsupported
# 'alpha::declare'.  This means we might need to change the declaration 
# if AlphaTclCore changes.
alpha::declare feature latexAccents 1.3.0 {TeX Bib} {
    # Initialization script
    namespace eval TeX {}
    alpha::package require -loose TeX 5.0
    
    TeX::Accents::turnOn
    
    menu::insert {LaTeX Utilities} items 5 \
      "(-" {Convert Accents to LaTeX} {Convert LaTeX to Accents}
    
    proc TeX::ConvertAccentstoLaTeX {} {TeX::Accents::replace 1}
    proc TeX::ConvertLaTeXtoAccents {} {TeX::Accents::replace 0}
} {
    # Activation script.
    TeX::Accents::activate
} {
    # Deactivation script.
    TeX::Accents::deactivate
} {
    # Off script
    TeX::Accents::turnOff

    menu::uninsert {LaTeX Utilities} items 5 \
      "(-" {Convert Accents to LaTeX} {Convert LaTeX to Accents}

} maintainer {
    {Dominique d'Humières} <dominiq@physique.ens.fr>
    {F. Miguel Dionísio}   <fmd@math.ist.utl.pt>
} requirements {
    alpha::package require -loose TeX 5.0
    alpha::package require AlphaTcl 8.1a1
} uninstall {
    this-file
} description {
    Provides keyboard support and LaTeX Menu items to convert between
    "international" symbols (diacritics) and LaTeX codes in TeX and/or Bib
    mode windows
} help {
    This feature allows you to convert between international symbols
    (available from the keyboard in use) and LaTeX codes.  This can be done in
    two different ways.  First, activating the feature adds two new items to
    the "TeX Menu > LaTeX Utilities" submenu to convert all of the accented
    characters in the current window to/from LaTeX codes.  Second, key presses
    that would normally insert accented characters can instead automatically
    insert the LaTeX code.
    
    This feature is available for both TeX and Bib modes, although you must
    activate it for each mode in order to use the bindings.
    
    Preferences: Mode-Features-TeX
    Preferences: Mode-Features-Bib

    Note that all of the preferences described below are 'attached' to TeX
    mode, and can only be changed when the current window is in TeX mode,
    although the preferences do apply to both TeX and Bib.  All of these prefs
    can be changed using the "Config > Mode Prefs > Preferences" dialog.
    
    Preferences: Mode-TeX
    Preferences: Mode-Bib

	Accent Syntax
    
    A choice between different possible syntax for accents and ligatures (i.e.
    é replaced by \'{e} or \'e, and œ by \oe{}, {\oe} or \oe ) is available
    via the 'Accent Syntax' preference.
    
	Bind LaTeX Accents

    Key-presses for accented characters can be bound to their LaTeX form
    depending on the above preference: typing é yields \'e (or \'{e}) (set by
    the 'Bind LaTeX Accents' preference, default is OFF).
    
	Accents In Comments

    The accented characters can be kept when they appear in comments according
    to the 'Accents In Comments' preference -- turning the preference on
    allows the characters to remain undisturbed.  NOTE that this option does
    not work with the conversion procedures called from the 'LaTeX Utilities'
    menu.
    
    When the 'Accent Smart Escape' preference is ON, the LaTeX accents are
    deleted at once using the backspace key.  A single character deletion is
    bound to SHIFT+backspace.  Presently works with any character for the
    
	\', \^, \`, \", \~, \c and \v
    
    accents, but not for the
    
	\=, \., \u, \H, \r, \t, \d, \b, and \k
    
    ones.
    
    WARNING! this feature deletes several characters at once and uses a
    general syntax to find accent or ligature patterns; it is not restricted
    to the syntax chosen in 'accentSyntax' or the character set used in the
    conversion procedures.  For instance,
    
	\^ { v }
    
    will be recognized as a legal accented v and will be deleted at once.  If
    you are impatient and press the backspace key several time, you will
    delete extra characters (possibly critical ones such as curly braces), BE
    CAREFUL if you use this feature!.
} 

proc latexAccents.tcl {} {}

namespace eval TeX::Accents {}

proc TeX::Accents::turnOn {} {
    
    global TeXmodeVars
    
    hook::register keyboard TeX::Accents::switchKeyboard
    hook::register activateHook TeX::Accents::checkStatus
    hook::register winChangeModeHook TeX::Accents::checkStatus
    
    # Set the TeX syntax for accents and ligatures.
    newPref variable accentSyntax 0 TeX TeX::Accents::setLatexAccents \
      [list "\\'e & \\oe{}" "\\'e & {\\oe}" "\\'e & \\oe " "\\'{e} & \\oe{}" \
	    "\\'{e} & {\\oe}" "\\'{e} & \\oe "] index

    # If set, keeps the Mac accents in comments.
    newPref f accentsInComments 1 TeX
    # Bind the TeX accents to the accented keys.
    newPref f bindLatexAccents 0 TeX TeX::Accents::setBindings
    # If set, allows the TeX accents to be deleted at once with the delete key.
    newPref f accentSmartEscape 0 TeX TeX::Accents::setSmartEscape

    prefs::dialogs::hideShowPane "TeX" "LaTeX Accents" 1

    # All bindings are made to the 'latexaccents' bindtag, which is
    # then simply attached to windows that want it.
    TeX::Accents::setLatexAccents 1
    TeX::Accents::setSmartEscape 1
    TeX::Accents::addSmartEscape 1
    if {$TeXmodeVars(bindLatexAccents)} { TeX::Accents::bindLatex 1 }
}

proc TeX::Accents::turnOff {} {
    foreach w [winNames -f] {
	removeFromWindow $w
    }
    
    hook::deregister keyboard TeX::Accents::switchKeyboard
    hook::deregister activateHook TeX::Accents::checkStatus
    hook::deregister winChangeModeHook TeX::Accents::checkStatus
    prefs::dialogs::hideShowPane "TeX" "LaTeX Accents" 0
}

proc TeX::Accents::activate  {} {
    if {[win::Current] ne ""} {
	TeX::Accents::checkStatus [win::Current]
    }
    prefs::dialogs::setPaneLists "TeX" "LaTeX Accents" [list \
      "accentSyntax" \
      "accentsInComments" \
      "bindLatexAccents" \
      "accentSmartEscape" \
      ]
    prefs::dialogs::hideShowPane "TeX" "LaTeX Accents" 1
}

proc TeX::Accents::deactivate  {} {
    if {[win::Current] ne ""} {
	TeX::Accents::checkStatus [win::Current]
    }
    prefs::dialogs::hideShowPane "TeX" "LaTeX Accents" 0
}

# Called every time a new window is brought to the front, or when this
# package is activated or deactivated.  We just check whether we should
# or should not have 'latexaccents' bindtag attached to the given
# window.  This is a quick operation, so it's not really a problem to do
# it for every window.
# 
# We need 'args' because we're also called from winChangeModeHook which
# supplies extra arguments.
proc TeX::Accents::checkStatus {name args} {
    set m [win::getMode $name]
    if {[mode::isFeatureActive $m latexAccents]} {
	addToWindow $name
    } else {
	removeFromWindow $name
    }
}

proc TeX::Accents::addToWindow {w} {
    set tags [win::getInfo $w bindtags]
    if {[lsearch -exact $tags latexaccents] == -1} {
	lappend tags latexaccents
	win::setInfo $w bindtags $tags
    }
}

proc TeX::Accents::removeFromWindow {w} {
    set tags [win::getInfo $w bindtags]
    if {[set idx [lsearch -exact $tags latexaccents]] != -1} {
	win::setInfo $w bindtags [lreplace $tags $idx $idx]
    }
}

######################################################################
#
# Returns, for argument "a" the regular expression 
# [ \t]*(a|{[ \t]*a[ \t]*}),
# used to look for alternative ways of writing accents, for example à:
# \`a, \` a, \`{a}, etc.
#
######################################################################
proc TeX::Accents::rexp  {c {pre ""}} {
    set ws "\[ \t\]*"
    return $ws\($pre$c|{$ws$c$ws}\)
}

######################################################################
#
# Returns, for argument "c" the regular expression 
# [ \t]*( c|{c}),
# used to look for alternative ways of writing cedilla, for example ç:
# \c c, \c{c}, \c {c} etc. Note that \c{}c, \c{ C}, or \c{C } do not
# yield the right glyph.
#
######################################################################
proc TeX::Accents::rexpc  {c {pre ""}} {
    set ws "\[ \t\]*"
    return $ws\($pre$c|{$c}\)
}

######################################################################
#
# Returns, for argument "\\i" the regular expression 
# [ \t]*(\i[ 	]|\i{}|\i\b|{[ 	]*\i[ 	]*}),
# used to look for alternative ways of writing accented i, for example í:
# \'\i , \'{\i}, \'\i{} etc. 
#
######################################################################
proc TeX::Accents::rexpi  {c {post ""}} {
    set ws "\[ \t\]*"
    return $ws\($c$post|$c\{\}|$c\\M|{$ws$c$ws}\)
}

######################################################################
#
# Returns, for argument "o" the regular expression 
# \\\\o$sep|{$ws\\\\o$ws},
# used to look for alternative ways of writting ligatures, for example ø:
# \o{}, {\o}, \o , etc.
#
######################################################################
proc TeX::Accents::rexpl  {c} {
    set ws "\[ \t\]*"
    set sep {[ 	]*( |	|\{\}|\M)}
    return \(\\\\$c$sep|{$ws\\\\$c$ws}\)
}

######################################################################
#
# Returns, for argument "\\i" the regular expression 
# [ \t]*(\i[ 	]|\i{}|\i\b|{\i}),
# used to look for alternative ways of writing accented i, for example í:
# \'\i , \'{\i}, \'\i{} etc. 
#
######################################################################
proc TeX::Accents::rexpv  {c {post ""}} {
    set ws "\[ \t\]*"
    return $ws\($c$post|$c\{\}|$c\\M|{$c}\)
}

######################################################################
# 
# This does the rest: defines the list of chars (all), the list of their 
# LaTex equivalent (texall) and the list of corresponding regular 
# expressions (regall).  When translating to LaTeX replaces all 
# ocurrences of each char by the corresponding LaTeX equivalent (using 
# regsub, see the TCL manual).  In the other direction replaces the text 
# that matches the regular expression by the corresponding char.
# 
######################################################################

############################################################
# 
# List of characters to be replaced by LaTeX equivalent
# 
############################################################

proc TeX::Accents::setSmartEscape {type} {
    global TeXmodeVars
    if {$type == "accentSmartEscape"} {
	TeX::Accents::addSmartEscape $TeXmodeVars(accentSmartEscape)
    }
    if {$TeXmodeVars(accentSmartEscape)} {
	Bind  0x33  <s>   backSpace "latexaccents"
	ascii 0x08        TeX::escapeSmartStuff latexaccents
    } else {
	unBind  0x33  <s>   backSpace "latexaccents"
	unascii 0x08        TeX::escapeSmartStuff latexaccents
    }
}

proc TeX::Accents::setBindings {args} {
    global TeXmodeVars keyboard
    TeX::Accents::bindLatex $TeXmodeVars(bindLatexAccents) $keyboard
}

proc TeX::Accents::setLatexAccents {args} {
    global TeXmodeVars TeX::Accents::_latexAccents TeX::_asciiAccents \
      TeX::_globalBindings keyboard
    if {![info exists {TeX::_globalBindings}]} {
	set TeX::_globalBindings ""
	set tmp [mode::listAll]
	foreach b [split [bindingList] "\r"] {
	    if {[regexp "<s?os?>" $b]} {		
		set lst [lindex [split $b  " "] end]
		if {[lsearch $tmp $lst] < 0} {
		    append TeX::_globalBindings "$b\r"
		}
	    }
	}
    }
    set quote \"  
    set seplater {\\\\sepsep//}
    if {$TeXmodeVars(bindLatexAccents) && $args!=1} {
	if {$args == "accentSyntax"} {
	    set key $keyboard
	} else {
	    set key $args
	}
	TeX::Accents::bindLatex 0 $key
    }
    if {$keyboard == "Slovenian"} {
	set TeX::_asciiAccents "àáâãäÀÁÂÃÄèéêëÈÉ˝˙ìíîïÌÍÎÏòóôõöÒÓÔÕÖùúûüÙÚÛÜñÑÊ∆çÇËπæ»©ÆåÅœŒ˛ﬁøØ–ß…£§¶ªº°Ÿ†¿¡"
    } else {
	set TeX::_asciiAccents "àáâãäÀÁÂÃÄèéêëÈÉÊËìíîïÌÍÎÏòóôõöÒÓÔÕÖùúûüÙÚÛÜñÑÿŸçÇåÅœŒæÆøØß…£§¶ªº°©†¿¡‡"
    }
	
    ############################################################
    # 
    # List of the LaTex equivalents
    # 
    ############################################################
    
    set texis	[list  "\\`{\\i}" "\\'{\\i}" "\\^{\\i}"  "\\$quote{\\i}"]
    set texoth1  [list "\\dots$seplater" "\\pounds$seplater" "\\S$seplater" "\\P$seplater"]
    set texoth2  [list  "{\\leavevmode\\raise.585ex\\hbox{\\b{a}}}"  "{\\leavevmode\\raise.6ex\\hbox{\\b{o}}}" "\\accent'27"]
    if {$keyboard == "Slovenian"} {
	set texfix  [list  "\\c{c}"  "\\c{C}" "\\v{c}" "\\v{s}" "\\v{z}" "\\v{C}" "\\v{S}" "\\v{Z}"]
	set texoth3 [list  "\\copyright$seplater" "\\dag$seplater" "?`" "!`"]
    } else {
	set texfix  [list  "\\c{c}"  "\\c{C}"]
	set texoth3 [list "\\copyright$seplater" "\\dag$seplater" "?`" "!`" "\\ddag$seplater"]
    }
	    
    if {$TeXmodeVars(accentSyntax) > 2} {
	set texas    [list "\\`{a}" "\\'{a}" "\\^{a}" "\\~{a}" "\\$quote{a}"] 
	set texcas   [list "\\`{A}" "\\'{A}" "\\^{A}" "\\~{A}" "\\$quote{A}"]									 
	set texes    [list "\\`{e}" "\\'{e}" "\\^{e}" "\\$quote{e}"]				
	set texces   [list "\\`{E}" "\\'{E}" "\\^{E}" "\\$quote{E}"]   
	set texcis   [list "\\`{I}" "\\'{I}" "\\^{I}" "\\$quote{I}"]
	set texos    [list "\\`{o}" "\\'{o}" "\\^{o}" "\\~{o}" "\\$quote{o}"]
	set texcos   [list "\\`{O}" "\\'{O}" "\\^{O}" "\\~{O}" "\\$quote{O}"]
	set texus    [list "\\`{u}" "\\'{u}" "\\^{u}" "\\$quote{u}"]
	set texcus   [list "\\`{U}" "\\'{U}" "\\^{U}" "\\$quote{U}"]
	if {$keyboard == "Slovenian"} {
	    set texvar   [list "\\~{n}" "\\~{N}" "\\'{c}" "\\'{C}"]
	} else {
	    set texvar   [list "\\~{n}" "\\~{N}" "\\$quote{y}"  "\\$quote{Y}"]
	}
    } else {
	set texas    [list "\\`a" "\\'a" "\\^a" "\\~a" "\\${quote}a"] 
	set texcas   [list "\\`A" "\\'A" "\\^A" "\\~A" "\\${quote}A"]									 
	set texes    [list "\\`e" "\\'e" "\\^e" "\\${quote}e"]				
	set texces   [list "\\`E" "\\'E" "\\^E" "\\${quote}E"]   
	set texcis   [list "\\`I" "\\'I" "\\^I" "\\${quote}I"]
	set texos    [list "\\`o" "\\'o" "\\^o" "\\~o" "\\${quote}o"]
	set texcos   [list "\\`O" "\\'O" "\\^O" "\\~O" "\\${quote}O"]
	set texus    [list "\\`u" "\\'u" "\\^u" "\\${quote}u"]
	set texcus   [list "\\`U" "\\'U" "\\^U" "\\${quote}U"]
	if {$keyboard == "Slovenian"} {
	    set texvar  [list "\\~n" "\\~N" "\\'c" "\\'C"]
	} else {
	    set texvar   [list "\\~n" "\\~N" "\\${quote}y"  "\\${quote}Y"]
	}
    }
    switch -- [expr {$TeXmodeVars(accentSyntax) % 3}] {
       0    { set texlig1 [list "\\aa{}" "\\AA{}" "\\oe{}" "\\OE{}" \
				"\\ae{}" "\\AE{}" "\\o{}" "\\O{}"]
	      if {$keyboard == "Slovenian"} {
		  set texlig2 [list "\\dj{}" "\\DJ{}" "\\ss{}"]
	      } else {
		  set texlig2 [list "\\ss{}"]
	      }
	    }
       1    { set texlig1 [list "{\\aa}" "{\\AA}" "{\\oe}" "{\\OE}" \
				"{\\ae}" "{\\AE}" "{\\o}" "{\\O}"]
	      if {$keyboard == "Slovenian"} {
		  set texlig2 [list "{\\dj}" "{\\DJ}" "{\\ss}"]
	      } else {
		  set texlig2 [list "{\\ss}"]
	      }
	    }
       2    { set texlig1 [list "\\aa$seplater" "\\AA$seplater" "\\oe$seplater" "\\OE$seplater" \
				"\\ae$seplater" "\\AE$seplater" "\\o$seplater" "\\O$seplater"]
	      if {$keyboard == "Slovenian"} {
		  set texlig2 [list "\\dj$seplater" "\\DJ$seplater" "\\ss$seplater"]
	      } else {
		  set texlig2 [list "\\ss$seplater"]
	      }
	    }
    }
    
    set TeX::Accents::_latexAccents [concat $texas $texcas $texes $texces $texis $texcis $texos $texcos $texus $texcus \
				   $texvar $texfix $texlig1 $texlig2 $texoth1 $texoth2 $texoth3]

    if {$TeXmodeVars(bindLatexAccents)} {
	TeX::Accents::bindLatex 1 $keyboard
    }
}

proc TeX::Accents::replace {ww} {
    global TeX::_asciiAccents TeX::Accents::_latexAccents keyboard
    if { [isSelection] } {
	set position [getPos]
	set endselection [selEnd]
    } else {
	switch -- [askyesno "Convert the entire document?"] {
	    "yes" {
		    set position [minPos]
		    set endselection [maxPos]
		   }
	    "no" { return }
	}
    }
    set text [getText $position $endselection]
    
    set all ${TeX::_asciiAccents}

    set quote \"
    set seplater {\\\\sepsep//}
	  
    ############################################################
    #                                                          #														   #
    #	List of regular expressions		               #
    #	For à the reg exp is \`[ \t]*(a|{[ \t]*a[ \t]*})       #
    #   \c c needs the space but \c{c} does not                #
    #   \i may have trailing spaces                            #
    #                                                          #														   #\\\\aa$sep|{$ws\\\\aa$ws}
    ############################################################

    if {$ww == "0"} {      
	set ws "\[ \t\]*"
	set sp "\[ \t\]"
	set sep { *( |\{\}|\M)}
	set a [TeX::Accents::rexp a]
	set regas    [list "\\\\`$a" "\\\\'$a" "\\\\\\^$a"  "\\\\~$a"  "\\\\\\$quote$a"]
	set a [TeX::Accents::rexp A]
	set regcas   [list "\\\\`$a" "\\\\'$a" "\\\\\\^$a"  "\\\\~$a"  "\\\\\\$quote$a"]
	set e [TeX::Accents::rexp e]
	set reges    [list "\\\\`$e" "\\\\'$e" "\\\\\\^$e"  "\\\\\\$quote$e"]
	set e [TeX::Accents::rexp E]
	set regces   [list "\\\\`$e" "\\\\'$e" "\\\\\\^$e"  "\\\\\\$quote$e"]
	set i [TeX::Accents::rexpi "\\\\i" {[ 	]}]
	set regis    [list "\\\\`$i" "\\\\'$i" "\\\\\\^$i"  "\\\\$quote$i"]
	set i [TeX::Accents::rexp I]
	set regcis   [list "\\\\`$i" "\\\\'$i" "\\\\\\^$i"  "\\\\$quote$i"]
	set o [TeX::Accents::rexp o]
	set regos    [list "\\\\`$o" "\\\\'$o" "\\\\\\^$o"  "\\\\~$o"  "\\\\$quote$o"]
	set o [TeX::Accents::rexp O]
	set regcos   [list "\\\\`$o" "\\\\'$o" "\\\\\\^$o"  "\\\\~$o"  "\\\\$quote$o"]
	set u [TeX::Accents::rexp u]
	set regus    [list "\\\\`$u" "\\\\'$u" "\\\\\\^$u"  "\\\\$quote$u"]
	set u [TeX::Accents::rexp U]
	set regcus   [list "\\\\`$u" "\\\\'$u" "\\\\\\^$u"  "\\\\$quote$u"]
	set reglig1  [list "[TeX::Accents::rexpl aa]" "[TeX::Accents::rexpl AA]" "[TeX::Accents::rexpl oe]" "[TeX::Accents::rexpl OE]" \
			   "[TeX::Accents::rexpl ae]" "[TeX::Accents::rexpl AE]" "[TeX::Accents::rexpl o]" "[TeX::Accents::rexpl O]"]
	set regoth1  [list "\\\\dots$sep" "\\\\pounds$sep" "[TeX::Accents::rexpl S]" "[TeX::Accents::rexpl P]"]
	set regoth2  [list "({\\\\leavevmode\\\\raise.585ex\\\\hbox{\\\\b{a}}})" \
			   "({\\\\leavevmode\\\\raise.6ex\\\\hbox{\\\\b{o}}})" "(\\\\accent'27)"]
	if {$keyboard == "Slovenian"} {
		set regvar  [list "\\\\~[TeX::Accents::rexp n]" "\\\\~[TeX::Accents::rexp N]" "\\\\\'[TeX::Accents::rexp c]" "\\\\\'[TeX::Accents::rexp C]"]
		set regfix  [list "\\\\c[TeX::Accents::rexpc c {[ 	]}]" "\\\\c[TeX::Accents::rexpc C {[ 	]}]" \
				  "\\\\v[TeX::Accents::rexpc c {[ 	]}]" "\\\\v[TeX::Accents::rexpc s {[ 	]}]" \
				  "\\\\v[TeX::Accents::rexpc z {[ 	]}]" "\\\\v[TeX::Accents::rexpc C {[ 	]}]" \
				  "\\\\v[TeX::Accents::rexpc S {[ 	]}]" "\\\\v[TeX::Accents::rexpc Z {[ 	]}]"]
		set reglig2 [list "[TeX::Accents::rexpl dj]" "[TeX::Accents::rexpl DJ]" "[TeX::Accents::rexpl ss]"]
		set regoth3 [list "\\\\copyright$sep" "\\\\dag$sep" "(\\?`)" "(\\!`)"]
	} else {
		set regvar  [list "\\\\~[TeX::Accents::rexp n]" "\\\\~[TeX::Accents::rexp N]" "\\\\\\$quote[TeX::Accents::rexp y]" "\\\\\\$quote[TeX::Accents::rexp Y]"]
		set regfix  [list "\\\\c[TeX::Accents::rexpc c {[ 	]}]" "\\\\c[TeX::Accents::rexpc C {[ 	]}]" ]
		set reglig2 [list "[TeX::Accents::rexpl ss]"]
		set regoth3 [list "\\\\copyright$sep" "\\\\dag$sep" "(\\?`)" "(\\!`)" "\\\\ddag$sep"]
	}
	
	set regall   [concat $regas $regcas $reges $regces $regis $regcis $regos $regcos $regus $regcus \
			     $regvar $regfix $reglig1 $reglig2 $regoth1 $regoth2 $regoth3]
    }

    ############################################################

    set mark {\\\\¸¸//}
    set space {[ ]+}
    set len [string length $all]
    set ltxt [string length $text]
    set i 0
    set count 0
    while {$i < $len} {
	set c [string index $all $i]
	if {$ww == "1"} {
	    set s [lindex ${TeX::Accents::_latexAccents} $i]
	    incr count [regsub -all "$c" $text "$s" text]
	    if {$ltxt > 10000} {
		# This really is a debugging tool...
		# status::msg "pair $c $s"
	    }
	} else {
	    set s [lindex $regall $i]
	    regsub -all "(${s})(\\\\( ) *)?" $text "$mark$c\\4" text
	    if {$ltxt > 10000} {
		# This really is a debugging tool...
		# status::msg "pair $s $c"
	    }
	}
	incr i
    }
    if {$ww == "1"} {   
	regsub -all "$seplater$space" $text "\\\\ " text
	regsub -all "${seplater}(\\W)" $text {\1} text
	regsub -all "$seplater" $text " " text
    } else {
	incr count [regsub -all "$mark" $text "" text]
    }
    # workaround Alpha bug
    goto $position
    replaceText $position $endselection $text	
    status::msg "$count accented characters converted."
}

set "TeX_keyboards(Australian)" {
 {¡£§¶ªºœ†øåß©…æç}
 {136790qtoasg;'c}
 {‡°ŒØÅÆÇ¿}
 {78qoa'c/}
}
set "TeX_keyboards(Brasil)" {
 {£¶œæ†ø°åß©…}
 {46qeuoºasc.}
 {¡¿ŒÆ‡ØÅ}
 {1'qeuoa}
}
set "TeX_keyboards(British)" {
 {¡§¶ªºœ†øåß©…æç}
 {16790qtoasg;'c}
 {‡°ŒØÅÆÇ¿}
 {78qoa'c/}
}
set "TeX_keyboards(Canadian - CSA)" {
 {¡£œ¶øæßª©°}
 {13qroasdg;}
 {†‡¿ŒØÆ§…†º}
 {67-qoaslcm}
}
set "TeX_keyboards(Canadian - ISO)" {
 {¡£œ¶øæßª©}
 {13qroasdg}
 {†‡¿ŒØÆ§…†º}
 {67-qoaslxm}
}
set "TeX_keyboards(Canadian - French)" {
 {¡£¶ªºœøåß©æàùÉ}
 {13790qoasg;,.é}
 {¿‡ŒØÅ§Æ†è…Ç}
 {67qoasÆcm.é}
}
set "TeX_keyboards(Danish)" {
 {¡£¶°é†üœªß©äö…çñ}
 {147qetuoasgæøxcn}
 {¿‡ÉŸÜŒÄÖºÇÑ}
 {+teyuoæø'cn}
}
set "TeX_keyboards(Dutch)" {
 {¡£§¶ªºœ†øåß©…æç}
 {136790qtoasg;'c}
 {‡°ŒØÅÆÇ¿}
 {78qoa'c/}
}
set "TeX_keyboards(Español - ISO)" {
 {œæøå¶§©ß}
 {qwoajkcb}
 {°£ŒÆØÅ…}
 {º4qwoa.}
}
set "TeX_keyboards(Finnish)" {
 {©£†œßªøæç…}
 {13tosköäc.}
 {¡¶¿‡ŒºØÆÇ}
 {16+toköäc}
}
set "TeX_keyboards(Flemish)" {
 {¶¡Çøæê†ºœ‡©ß…}
 {§!çàaetuoqcb;}
 {åØÆÅÊŸªŒ¿}
 {§àazeyuo,}
}
set "TeX_keyboards(French)" {
 {æøœß©¶†‡¡ºÇ…}
 {aàobc§tq!uç;}
 {ÆØŒÅå¿ª}
 {aàoz§,u}
}
set "TeX_keyboards(French - numerical)" {
 {æøœß©¶†‡¡ºÇ…}
 {aàobc§tq!uç;}
 {ÆØŒÅå¿ª}
 {aàoz§,u}
}
set "TeX_keyboards(German)" {
 {¡¶¿†øå©ªºœæç…}
 {13ßtoaghjöäc.}
 {£ØÅŒÆ‡Ç}
 {4oaöäyc}
}
set "TeX_keyboards(Italian)" {
 {Ç¶†øœåßªºæ©¿…¡}
 {çètoìasjkùc,;ò}
 {ÒÙÛØŒÚÅ‡Æ}
 {éiuoì$afù}
}
set "TeX_keyboards(Italian - Pro)" {
 {æœåøßªº¶…©†¡}
 {yiaosjkù,cx'}
 {ÇÆŒÅØ¿‡}
 {òyiao'x}
}
set "TeX_keyboards(Norwegian)" {
 {©£§é†üœßªöäç…}
 {136etuoskøæc.}
 {¡¶¿°É‡ÜŒºÖÄÇ}
 {16+qetuokøæc}
}
set "TeX_keyboards(Spanish)" {
 {°£œæ†øåß§¶©…}
 {89qetoask;c.}
 {ŒÆØÅ‡}
 {qeoaf}
}
set "TeX_keyboards(Swedish)" {
 {©£§é†üœßªøæç…}
 {136etuosköäc.}
 {¡¶¿°É‡ÜŒºØÆÇ}
 {16+aetuoköäc}
}
set "TeX_keyboards(Swiss French)" {
 {Ç¿œ†°¡ø§åßªºæ¶©…}
 {4'qtuioèashjà$c.}
 {ŒØÅ‡Æ}
 {qoafà}
}
set "TeX_keyboards(Swiss German)" {
 {Ç¿œ†°¡ø§åßªºæ¶©…}
 {4'qtuioüashjä$c.}
 {ŒØÅ‡Æ}
 {qoafä}
}
set "TeX_keyboards(U.S.)" {
 {¡£§¶ªºœ†øåß©…æç}
 {136790qtoasg;'c}
 {‡°ŒØÅÆÇ¿}
 {78qoa'c/}
}
set "TeX_keyboards(Slovenian)" {
 {¡£§¶ªºœ†øåßŸç}
 {136790qtoasgc}
 {°ŒØÅÇ¿}
 {8qoac-}
}
set "TeX_keyboards(Croatian)" {
 {¡£§¶ªºœ†øåß©…æç}
 {136790qtoasg;'c}
 {‡°ŒØÅÆÇ¿}
 {78qoa'c/}
}
set "TeX_keyboards(Roman - JIS)" {
 {¡£§¶ªºœ†øåß©…æç}
 {136790qtoasg;:c}
 {‡°ŒØÅÆÇ¿}
 {78qoa:c/}
}

proc TeX::Accents::switchKeyboard {args} {
    global TeXmodeVars oldkeyboard keyboard
    if {$oldkeyboard == "Slovenian" || $keyboard == "Slovenian"} {
	TeX::Accents::setLatexAccents $oldkeyboard
	return
    }
    if {$TeXmodeVars(bindLatexAccents)} {
	TeX::Accents::bindOptionLatex 0 $oldkeyboard
	TeX::Accents::bindOptionLatex 1 $keyboard
    }
}

proc TeX::Accents::bindLatex {flag {keys ""}} {
    global TeX::_asciiAccents TeX::Accents::_latexAccents keyboard
        
    if {$flag == 0} {
        set func "TeX::Accents::unascii8d0a4"
    } else {
        set func "TeX::Accents::ascii8d0a4"
        if {($alpha::platform eq "alpha") || ($alpha::macos == 2)} {
            status::msg "ø and Ø are not bound and dead keys give extra \
             accents that should be deleted (see Bug #884)."
        }
    }
    set all ${TeX::_asciiAccents}
    set seplater {\\\\\\\\sepsep//}
    set len [string length $all]
    set i 0
    while {$i < $len} {
        set c [string index $all $i]
	set s [lindex ${TeX::Accents::_latexAccents} $i]
	regsub "$seplater" $s {\\/} s 
	set s [quote::Insert $s]
	set key "0x[format %x [text::Ascii $c]]"
	set pro "{TeX::Accents::insert \"$s\" \"$c\"}"
	catch "$func $key $pro latexaccents"
        incr i
    }
    if {$keys == ""} {
        TeX::Accents::bindOptionLatex $flag $keyboard
    } else {
        TeX::Accents::bindOptionLatex $flag $keys
    } 
}

proc TeX::Accents::bindOptionLatex {flag {keys ""}} {
    global TeX::_asciiAccents TeX::Accents::_latexAccents TeX::_globalBindings TeX_keyboards keyboard mode
    if {$flag == 0} {
	set func2 "unBind"
    } else {
	set func2 "Bind"
    } 
    set all ${TeX::_asciiAccents}
    set seplater {\\\\\\\\sepsep//}
    if {$keys == ""} {
	set keys $keyboard
    } 
    set opt $TeX_keyboards($keys)
    set lopt [lindex $opt 0]
    set copt [lindex $opt 1]
    set len [string length $lopt]
    set i 0
    while {$i < $len} {
	set l [string index $lopt $i]
	set j [string first $l $all] 
	set s [lindex ${TeX::Accents::_latexAccents} $j]
	regsub "$seplater" $s {\\/} s 
	set s [quote::Insert $s]
	set key "'[string index $copt $i]'"
	set j $i
	incr i
	if {$func2 == "Bind" && [regexp "[quote::Regfind $key]\[ \t\]+<o>" ${TeX::_globalBindings}]} { continue } 
	set pro "{TeX::Accents::insert \"$s\" \"$l\"}"
	if {[catch "$func2 $key <o> $pro latexaccents"]} {
	    set key "'\\[string index $copt $j]'"
	    catch "$func2 $key <o> $pro latexaccents"
	}
    }
    set lopt [lindex $opt 2]
    set copt [lindex $opt 3]
    set len [string length $lopt]
    set i 0
    while {$i < $len} {
	set l [string index $lopt $i]
	set j [string first $l $all] 
	set s [lindex ${TeX::Accents::_latexAccents} $j]
	regsub "$seplater" $s {\\/} s 
	set s [quote::Insert $s]
	set key "'[string index $copt $i]'"
	set j $i
	incr i
	if {$func2 == "Bind" && [regexp "[quote::Regfind $key]\[ \t\]+(<so>|<so>)" ${TeX::_globalBindings}]} { continue } 
	set pro "{TeX::Accents::insert \"$s\" \"$l\"}"
	if {[catch "$func2 $key <os> $pro latexaccents"]} {
	    set key "'\\[string index $copt $j]'"
	    catch "$func2 $key <os> $pro latexaccents"
	}
    }
    if {$keys == "Slovenian"} {
	set j [string first "…" $all] 
	set s [lindex ${TeX::Accents::_latexAccents} $j]
	regsub "$seplater" $s {\\/} s 
	set s [quote::Insert $s]
	set pro "{TeX::Accents::insert \"$s\" \"…\"}"
	catch "$func2 0x29 <o> $pro latexaccents"
	set j [string first "˛" $all] 
	set s [lindex ${TeX::Accents::_latexAccents} $j]
	regsub "$seplater" $s {\\/} s 
	set s [quote::Insert $s]
	set pro "{TeX::Accents::insert \"$s\" \"˛\"}"
	catch "$func2 0x29 <os> $pro latexaccents"
	set j [string first "ﬁ" $all] 
	set s [lindex ${TeX::Accents::_latexAccents} $j]
	regsub "$seplater" $s {\\/} s 
	set s [quote::Insert $s]
	set pro "{TeX::Accents::insert \"$s\" \"ﬁ\"}"
	catch "$func2 0x27 <os> $pro latexaccents"
    } elseif {$keys == "Spanish"} {
	set j [string first "ª" $all] 
	set s [lindex ${TeX::Accents::_latexAccents} $j]
	regsub "$seplater" $s {\\/} s 
	set s [quote::Insert $s]
	set pro "{TeX::Accents::insert \"$s\" \"ª\"}"
	catch "$func2 0x21 <o> $pro latexaccents"
    }
}

proc TeX::Accents::insert {str1 {str2 ""}} {
    global TeXmodeVars
    if {[regsub {\\/} $str1 "" str1]} {
	set next [selEnd]
	if {[pos::compare $next <= [maxPos]]} {
	    set char [lookAt $next]
	    if {$char == " "} {
		set str1 "$str1\\"
	    } elseif {[regsub "\\w" $char "" tmp]} {
		set str1 "$str1 "
	    } 
	}
    }
    if {$str2 == ""} {
	TeX::insertObject $str1
	return
    }
    set pos [getPos]
    set beg [lineStart $pos]
    set txt [getText $beg $pos]
    if {$TeXmodeVars(accentsInComments) && [regexp {^%|[^\\]%} $txt]} {
	if {$str2 == "…"} {
	    typeText $str2
	} else {
	    TeX::insertObject $str2
	}
    } else {
	TeX::insertObject $str1
    }
}

proc TeX::Accents::addSmartEscape {flag} {
    global TeXmodeVars

    if {$TeXmodeVars(accentSmartEscape) || $flag == 0} {
	lappend TeXEscape {0 [?!]`$ {}}
	lappend TeXEscape [list 0 "\\\\\['^`\"~\][TeX::Accents::rexp {[a-zA-Z]}]$"	{}]
	lappend TeXEscape [list 0 "\\\\\['^`\"~\][TeX::Accents::rexpi {\\i} {[ 	]}]$"	{}]
	lappend TeXEscape [list 0 "[TeX::Accents::rexpl {(aa|ae|oe?|dj|AA|AE|OE?|DJ|S|P|ss)}]$" {}]
	lappend TeXEscape [list 0 "\\\\\[cv\][TeX::Accents::rexpc {[a-zA-Z]} {[ 	]}]$" {}]
	lappend TeXEscape [list 0 "\\\\\[v\][TeX::Accents::rexpv {\\i} {[ 	]}]$" {}]
	lappend TeXEscape {0 \{\\\\leavevmode\\\\raise\\.(6|585)ex\\\\hbox\{\\\\b\{[ao]\}\}\}$ {}}
	lappend TeXEscape {0 \\\\(pounds|dots|accent'27|copyright|d?dag)(\{\}|\ )?$ {}}
	foreach l $TeXEscape {
	    TeX::modifySmartEscapes $l $flag
	}
    }
}

proc TeX::Accents::ascii8d0a4 {code func mode} {
    scan [string range $code 2 end] "%x" c
    set char [text::Ascii $c 1]
    set lchar [string tolower $char]
    if {($lchar eq $char) || ([text::Ascii $lchar] == 0)} {
	ascii $code $func "latexaccents"
    } else {
	set code "0x[format %x [text::Ascii $lchar]]"
	ascii $code <s> $func "latexaccents"
    }
}


proc TeX::Accents::unascii8d0a4 {code func mode} {
    scan [string range $code 2 end] "%x" c
    set char [text::Ascii $c 1]
    set lchar [string tolower $char]
    if {($lchar eq $char) || ([text::Ascii $lchar] == 0)} {
	unascii $code $func "latexaccents"
    } else {
	set code "0x[format %x [text::Ascii $lchar]]"
	unascii $code <s> $func "latexaccents"
    }
}

