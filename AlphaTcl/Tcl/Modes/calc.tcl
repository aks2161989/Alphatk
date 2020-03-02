## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl support packages
 #
 # FILE: "calc.tcl"
 # 
 #                                          created: 02/03/1996 {03:22:29 PM}
 #                                      last update: 03/21/2006 {02:55:04 PM}
 # Description:
 # 
 # Creates a new "Utils > Calculator" menu item for an internal RPN stack
 # calculator, with its own menu.
 # 
 # Original notes:
 # 
 # Use at your own risk.  This is just a quick-and-dirty RPN stack
 # calculator, works on both decimal (signed and unsigned), hex integers, and
 # floating point.  I put it together for my own use, not yours, but feel
 # free to use it as long as you don't complain about what it doesn't do.
 # Improvements, of course, are welcome.
 #                                                                  
 # Author: Pete Keleher
 #     
 # Includes contributions from Vince Darley and Craig Barton Upright.
 # Many thanks to Dominique d'Humieres for beta-testing, suggestions.
 # 
 # Please see <http://www.tcl.tk/cgi-bin/tct/tip/132.html> for information
 # about setting "tcl_precision", and why we use "16" for calculations.
 # (Thanks to Lars Hellstrøm for pointing this out.)  If you want to
 # over-ride this, include
 # 
 #     namespace eval Calc {variable fullPrecision 17}
 # 
 # in a "prefs.tcl" file.
 # 
 # Copyright (c) 1996-2006  Pete Keleher, Vince Darley, Dominique d'Humieres
 #                          Craig Barton Upright
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ◊◊◊◊ Menu declaration ◊◊◊◊ #
alpha::feature calculator 1.0 "global-only" {
    # Initialization script.
} {
    # Activation script.
    # Add a "Utils > Calculator" menu item.
    menu::insert   Utils items "wordCount" "/Y<U<Ocalculator"
} {
    # Deactivation script.
    menu::uninsert Utils items "wordCount" "/Y<U<Ocalculator"
} preinit {
    # Inserts a "Calculator" menu item that allows you to perform 
    # calculations from within «ALPHA»
    newPref flag "calculatorItem" 0 contextualMenu
    namespace eval contextualMenu {
	;proc calculator {} {::calculator}
    }
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Adds a "Utils > Calculator" menu item which creates an internal RPN stack
    calculator for use while editing in «ALPHA».  See the "Calculator Help"
    window for more information
} help {
    file "Calculator Help"
}

proc calc.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "calculatorMenu" --
 # 
 # A dummy proc, required by AlphaTcl SystemCode.
 # 
 # --------------------------------------------------------------------------
 ##

proc calculatorMenu {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "calculator" --
 # 
 # A global procedure that can be called by any menu. 
 # 
 # --------------------------------------------------------------------------
 ##

proc calculator {} {
    Calc::calculatorWindow
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval" --
 # 
 # Define any variables used throughout this package.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Calc {
    
    variable initialized
    if {![info exists initialized]} {
	set initialized -1
    }
    variable calcMode
    if {![info exists calcMode]} {
	set calcMode 3
    }
    variable modeOptions [list \
      "Signed Decimal" \
      "Unsigned Decimal" \
      "Unsigned Hexadecimal" \
      "Floating Point" \
      "Equation Editor" \
      ]
    # The name of our Calculator window.
    variable calculatorWindow {* Calculator *}
    
    # Different Calculator window sections.
    variable windowSections
    array set windowSections [list \
      "Stack"           [format "%-15s «Clear»" "Stack :"] \
      "Value"           [format "%-15s «Clear»" "Value :"] \
      "Input"           [format "%-15s «Clear»" "Input :"] \
      "Keypad"          [format "%-15s «Prefs»" "Keypad :"] \
      "Functions"       [format "%-15s «Prefs»" "Functions :"] \
      "History"         [format "%-15s «Clear»" "History :"] \
      ]
    # Make sure that these variables exist.
    variable historyCache
    if {![info exists historyCache]} {
	set historyCache ""
    }
    variable stackValues
    if {![info exists stackValues]} {
        set stackValues [list]
    }
    variable lastInput
    if {![info exists lastInput]} {
        set lastInput ""
    }
    prefs::modified stackValues lastInput historyCache
    # Make sure that we only rename [paste] once in [Calc::registerHooks].
    variable pasteRenamed
    if {![info exists pasteRenamed]} {
	set pasteRenamed "-1"
    }
    variable fullPrecision
    if {![info exists fullPrecision]} {
        set fullPrecision 16
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::initialize" --
 # 
 # Called when Calc mode is first sourced, define preferences, register any
 # required hooks, and then build the Calc Menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::initialize {} {
    
    global CalcmodeVars mode::features keyboard
    
    variable initialized
    
    if {($initialized == 1)} {
	return
    }
    # Vince moved this here to avoid having this file sourced at every
    # startup.  It works fine here anyway.
    hook::register keyboard {Calc::switchKeyboard}
    # Make sure that we have our proper bindings set.
    Calc::changeBindings 1 $keyboard
    # Colorize Calc mode.  We include this initial [regModeKeywords] call so
    # that all of the others can be "adds" with "-a".
    regModeKeywords -C "Calc" {}
    Calc::colorizeCalc
    # Register hooks.
    Calc::registerHooks 1
    # Make sure that line wrapping is turned on.
    set CalcmodeVars(lineWrap) 1
    # Create a "minor mode" for the Calculator Window.
    set mode::features(Calc) [list "calculatorMenu" "-copyRing" "-smartPaste"]
    alpha::minormode "calculator" \
      bindtags          "Calc" \
      colortags         "Calc" \
      +featuremodes     "Calc" \
      hookmodes         "Calc" \
      varmodes          "Calc"
    
    # Create the "Calculator Menu".
    addMenu "calculatorMenu" "•212" "Calc" {file "Calculator Help"}
    menu::buildProc "calculatorMenu"    {Calc::buildMenu}
    menu::buildProc "calculatorMode"    {Calc::buildModeMenu}
    # Now we build the menu.
    menu::buildSome "calculatorMenu"
    
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::registerHooks" --
 # 
 # Register all hooks for Calc "mode" and the Calc Menu.  This all works
 # because our "calculator" minor-mode calls all Calc hooks.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::registerHooks {onOrOff} {
    
    variable pasteRenamed
    
    if {$onOrOff} {
	set cmd "hook::register"
    } else {
	set cmd "hook::deregister"
    }
    # Register a [preCloseHook] for the Calculator window.
    $cmd preCloseHook   {Calc::preCloseHook} "Calc"
    # Menu hooks.
    $cmd menuBuild      {Calc::menuEnable}   "calculatorMenu"
    if {($onOrOff != $pasteRenamed)} {
	if {$onOrOff} {
	    hook::procRename {::paste} {::Calc::pasteInput}
	    hook::procRename {::cut}   {::Calc::cutInput}
	} else {
	    hook::procRevert {::Calc::pasteInput}
	    hook::procRevert {::Calc::cutInput}
	}
	set pasteRenamed $onOrOff
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::preCloseHook" --
 # 
 # Called just before a Calculator window is closed, remember the geometry so
 # that it will be used the next time a window is created.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::preCloseHook {winName} {
    
    global CalcmodeVars
    
    variable calculatorWindow
    variable historyCache
    variable lastInput
    
    if {($winName ne $calculatorWindow)} {
        return
    }
    catch {Calc::currentInput} lastInput
    if {!$CalcmodeVars(saveHistoryCache)} {
        set historyCache ""
    }
    set CalcmodeVars(windowGeometry) [concat [list "-g"] [getGeometry $winName]]
    prefs::modified CalcmodeVars(windowGeometry)
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::activateHook" --
 # 
 # Enable/dim items when the Calculator window is brought to the front/back.
 # 
 # The "activateHook" and "deactivateHook" should only be registered if the
 # Calculator Menu is turned on globally, which will probably never happen.
 # 
 # --------------------------------------------------------------------------
 ##

# ===========================================================================
# 
# ◊◊◊◊ Preferences ◊◊◊◊ #
# 

prefs::removeObsolete \
  CalcmodeVars(tcl_precision) \
  CalcmodeVars(calculatePrecision)

prefs::renameOld CalcmodeVars(displayPrec)   CalcmodeVars(displayPrecision)

# To always include a History section at the bottom of the Calculator window,
# turn this item on||To never include a History section at the bottom of the
# Calculator window, turn this item off
newPref flag includeHistorySection      1   Calc    {Calc::updatePreferences}
# To always include Function hyperlinks in the Calculator window, turn this
# item on||To never include Function hyperlinks in the Calculator window,
# turn this item off
newPref flag includeFunctionHyperlinks  1   Calc    {Calc::updatePreferences}
# To always include Keypad hyperlinks in the Calculator window, turn this
# item on||To never include Keypad hyperlinks in the Calculator window, turn
# this item off
newPref flag includeKeypadHyperlinks    0   Calc    {Calc::updatePreferences}
# To save the "History Cache" when the Calculator Window is closed, turn this
# item on||To always open the Calculator with a fresh "History Cache", turn
# this item off
newPref flag saveHistoryCache           0   Calc    {Calc::updatePreferences}
# To display results in the Stack/Value field in scientific notation, turn
# this item on||To display results in the Stack/Value field in decimal form,
# turn this item off
newPref flag scientificNotation         0   Calc    {Calc::updatePreferences}

# Set display precision in Calc mode.  The maximum display precision is 16
# characters.
newPref var displayPrecision            6   Calc    {Calc::updatePreferences}

# Default font to use for the Calculator window
newPref var defaultFont $::defaultFont      Calc    {Calc::updatePreferences} \
  $::alpha::fontList
# Default font size to use for the Calculator windows
newPref var fontSize    $::fontSize         Calc    {Calc::updatePreferences} \
  [list "7" "9" "10" "12" "14" "18"]
newPref var wordBreak {[-\w.$]+} Calc

# The Keyboard Shortcut for the menu item which places the current
# stack/value into the Clipboard.
newPref menubinding "copyStackValue" {<U<O/C} Calc  {Calc::updatePreferences}

# The default window geometry for Calculator windows.
newPref geometry windowGeometry [list -g $tileLeft $tileTop 200 300] Calc

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::updatePreferences" --
 # 
 # Called when preferences are changed via the SystemCode dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::updatePreferences {prefName} {
    
    global CalcmodeVars
    
    variable calcMode
    variable fullPrecision
    
    switch -- $prefName {
	"copyStackValue" {
	    menu::buildSome "calculatorMenu"
	}
	"includeFunctionHyperlinks" -
	"includeHistorySection" -
	"includeKeypadHyperlinks" {
	    Calc::clearWindow 1 1 1
	    menu::buildSome "calculatorMenu"
	}
	"defaultFont" - "fontSize" {
	    Calc::clearWindow 1 1 1 1
	}
	"displayPrecision" {
	    if {($CalcmodeVars($prefName) > $fullPrecision)} {
		alertnote "The maximum [quote::Prettify $prefName]\
		  value is $fullPrecision."
		set CalcmodeVars($prefName) $fullPrecision
		prefs::modified CalcmodeVars($prefName)
	    } elseif {($CalcmodeVars($prefName) < 1)} {
		alertnote "The minimum [quote::Prettify $prefName]\
		  value is 1."
		set CalcmodeVars($prefName) 1
		prefs::modified CalcmodeVars($prefName)
	    }
	    Calc::currentStack "update"
	}
	"scientificNotation" {
	    if {($calcMode >= 3)} {
		Calc::currentStack "update"
	    }
	    menu::buildSome "calculatorMode"
	    Calc::menuEnable
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "Calc::modePrefsDialog" --
 # 
 # Custom "Calculator Preferences" dialog.
 # 
 # This give us greater control over what is presented to the user, as well
 # as the order in which preferences are displayed.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::modePrefsDialog {} {

    global CalcmodeVars allFlags
    
    variable calcMode
    
    set title "Preferences for the Calculator window"
    set flags [list \
      "includeFunctionHyperlinks" \
      "includeHistorySection" \
      "includeKeypadHyperlinks" \
      "saveHistoryCache" \
      ]
    if {($calcMode >= 3)} {
        lappend flags "scientificNotation"
    }
    set vars [list \
      "copyStackValue" \
      "displayPrecision" \
      "defaultFont" \
      "fontSize" \
      ]
    
    lappend pages Calc "" [lsort -dictionary $flags] $vars \
      [list prefs::dialogs::_getPrefValue "package" Calc] \
      [list prefs::dialogs::_setPrefValue "package" Calc]
    prefs::dialogs::makePrefsDialog $title $pages
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::colorizeCalc" --
 # 
 # Colors for the Calculator window.
 # 
 # We could give the user some control over the colors used here, but the
 # defaults seem reasonable enough.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::colorizeCalc {} {
    
    set keywords [list \
      "New" "Current" "Last" "Value" "Input" "Keypad" "Functions" "History" \
      "Error" "Pushed" "Popped" "Stack" "reset" "stack" "new" "mode"]
    
    regModeKeywords -a -k "red" "Calc" $keywords
    regModeKeywords -a -k "magenta" "Calc" {$ $V $v}
    regModeKeywords -a -k "blue" "Calc" [list \
      "abs" "acos" "asin" "atan" "atan2" "ceil" "cos" "cosh" "double" \
      "exp" "floor" "fmod" "hypot" "int" "log" "log10" "pow" "rand" \
      "round" "sin" "sinh" "sqrt" "srand" "tan" "tanh" "wide"]

    return
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Bindings ◊◊◊◊ #
# 
# Some of these are used in the menu, and probably don't need to be defined
# here specifically.
# 

# These are default bindings for [a-zA-Z0-9] and other ascii characters,
# which ensure that the cursor is within the input field.  Any of these might
# be over-ridden by the [ascii] or [Bind] statements that follow.
for {set i 32} {$i <= 126} {incr i} {
    if {[regexp {[A-Z]} [set character [format %c $i]]]} {
	set character [string tolower $character]
    }
    ascii [format "0x%.2x" $i] "Calc::specialKey $character" Calc
}
unset -nocomplain i character

# Now we over-ride some of the bindings we set above.

# Bind keypad-enter
ascii 0x03      {Calc::specialKey "Enter"}              Calc
ascii 0x08      {Calc::specialKey "Delete"}             Calc
ascii 0x20      {Calc::specialKey "Space"}              Calc

ascii 0x3b      {Calc::specialKey ";"}                  Calc

Bind 0x30       {Calc::specialKey "Tab"}                Calc
Bind '\r'       {Calc::specialKey "Return"}             Calc

# Keypad bindings.
Bind Clear      {Calc::specialKey "Clear"}              Calc
for {set i 0} {$i <= 9} {incr i} {
    Bind Kpad$i "Calc::specialKey $i"                   Calc
}
foreach i [list "*" "+" "-" "/" "." "="] {
    Bind Kpad$i "Calc::specialKey $i"			Calc
}
unset i

# Arrow keys.
Bind Up         {Calc::specialKey "Up"}                 Calc
Bind Down       {Calc::specialKey "Down"}               Calc
Bind Left       {Calc::specialKey "Left"}               Calc
Bind Right      {Calc::specialKey "Right"}              Calc

# Common "delete-text" keys.
Bind Del   <z>  {Calc::specialKey "Forward-Del-White"}  Calc
Bind 0x33  <z>  {Calc::specialKey "Forward-Del-White"}  Calc
Bind 0x33  <sz> {Calc::specialKey "Forward-Del-Until"}  Calc
if {${alpha::platform} == "tk"} {
    Bind Del <c>    {Calc::specialKey "Delete-Word"}    Calc
    Bind 0x33 <s>   {Calc::specialKey "Back-Del-Word"}  Calc
} else {
    Bind 0x33 <so>  {Calc::specialKey "Delete-Word"}    Calc
    Bind 0x33 <o>   {Calc::specialKey "Back-Del-Word"}  Calc
}
# Control-D, bound to [deleteChar] in emacs package.
Bind 'd'   <z>  {Calc::specialKey "Delete-Char"}        Calc
Bind 'd'   <o>  {Calc::specialKey "Delete-Word"}        Calc
# Control-K, bound to [killLine] in emacs package.
Bind 'k'   <z>  {Calc::specialKey "Kill-Line"}          Calc
# Control-O, bound to [openLine].
Bind 'o'   <z>  {Calc::specialKey "Open-Line"}          Calc

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::switchKeyboard" --
 # "Calc::changeBindings" --
 # 
 # Called when the user changes the "keyboard" preference.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::switchKeyboard {} {
    
    global oldkeyboard keyboard
    
    Calc::changeBindings 0 $oldkeyboard
    Calc::changeBindings 1 $keyboard
    return
}

proc Calc::changeBindings {onOrOff keyboard} {
    
    if {$onOrOff} {
	set cmd "Bind"
    } else {
	set cmd "unBind"
    }
    switch -- $keyboard {
	"Canadian - CSA" -
	"Canadian - ISO" {
	    catch [list $cmd "'-'"  "<o>"  {Calc::specialKey "|"} Calc]
	}
	"Croatian" {
	    catch [list $cmd "'<'"  "<so>" {Calc::specialKey "~"} Calc]
	    catch [list $cmd "'i'"  "<o>"  {Calc::specialKey "^"} Calc]
	    catch [list $cmd "'ç'"  "<o>"  {Calc::specialKey "^"} Calc]
	    catch [list $cmd "0x2a" "<so>" {Calc::specialKey "|"} Calc]
	}
	"Danish" {
	    catch [list $cmd "'i'"  "<o>"  {Calc::specialKey "|"} Calc]
	}
	"Español - ISO" {
	    catch [list $cmd "'1'"  "<o>"  {Calc::specialKey "|"} Calc]
	}
	"Finnish" -
	"German" -
	"Norwegian" -
	"Spanish" -
	"Swedish" -
	"Swiss French" -
	"Swiss German" {
	    catch [list $cmd "'7'"  "<o>"  {Calc::specialKey "|"} Calc]
	}
	"Flemish" -
	"French" -
	"French - numerical" {
	    catch [list $cmd "'l'"  "<so>" {Calc::specialKey "|"} Calc]
	}
	"Italian" {
	    catch [list $cmd "':'"  "<o>"  {Calc::specialKey "|"} Calc]
	}
	"Slovenian" {
	    catch [list $cmd "0x27" "<o>"  {Calc::specialKey "^"} Calc]
	    catch [list $cmd "'æ'"  "<so>" {Calc::specialKey "|"} Calc]
	}
    }
    return
}

# ===========================================================================
#
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Calculator Menu ◊◊◊◊ #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::buildMenu" --
 # 
 # Create the list of menu items for the Calc Menu, to be used when the menu
 # is built using [menu::buildSome].
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::buildMenu {} {
    
    global calculatorMenu CalcmodeVars
    
    variable calcMode
    
    if {($calcMode < "4")} {
	set clipboardMenuItem "$CalcmodeVars(copyStackValue)stackToClipboard"
    } else {
	set clipboardMenuItem "$CalcmodeVars(copyStackValue)valueToClipboard"
    }
    set menuList [list \
      "calculatorWindow" \
      [list Menu -n "calculatorMode" -p {Calc::menuProc} -M "Calc" {}] \
      $clipboardMenuItem \
      "(-)" \
      "!qduplicateY" \
      "!iswapXY" \
      "!nnegate" \
      "/-<BinsertMinus" \
      "!%mod" \
      "(-)" \
      [list Menu -n Boolean -p {Calc::menuProc} -M "Calc" [list \
      "!&and" \
      "!|or" \
      "!^xor" \
      "(-)" \
      "!<shiftLeft" \
      "!>shiftRight" \
      "!~not" \
      ]] \
      [list Menu -m -n ExpAndLog -p {Calc::menuProc} -M "Calc" [list \
      "/L<B<Uexp" \
      "/L<Blog" \
      "/L<B<Ilog10" \
      ]] \
      [list Menu -m -n Trigonometric -p {Calc::menuProc} -M "Calc" [list \
      "/C<Icos" \
      "/S<Isin" \
      "/T<Itan" \
      "(-)" \
      "/C<I<Uacos" \
      "/S<I<Uasin" \
      "/T<I<Uatan" \
      ]] \
      [list Menu -m -n Hyperbolic -p {Calc::menuProc} -M "Calc" [list \
      "/C<Bcosh" \
      "/S<Bsinh" \
      "/T<Btanh" \
      "(-)" \
      "/C<B<Uach" \
      "/S<B<Uash" \
      "/T<B<Uath" \
      ]] \
      [list Menu -m -n OtherMathFunctions -p {Calc::menuProc} -M "Calc" [list \
      "/F<Ifloor" \
      "/F<I<Uceil" \
      "(-)" \
      "/T<B<Iatan2" \
      "/F<B<I!%fmod" \
      "/H<B<Ihypot" \
      "/P<B<I!^pow" \
      "/S<B<Isqrt" \
      ]] \
      [list Menu -m -n Constants -p {Calc::menuProc} -M "Calc" [list \
      "/E<I<Ue" \
      "/P<Ipi" \
      ]] \
      "(-)" \
      "calculatorPrefs…" \
      "!?calculatorHelp" \
      ]
    set subMenus [list "calculatorMode"]
    set menuProc {Calc::menuProc -M "Calc"}
    return [list "build" $menuList $menuProc $subMenus $calculatorMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::buildModeMenu" --
 # 
 # Build the "Calc Menu > Calculator Mode" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::buildModeMenu {} {
    
    global CalcmodeVars
    
    variable calcMode
    variable modeOptions
    
    set menuList [list "!mChange Mode…" "!xDisplay Mode" "(-)"]
    foreach modeOption $modeOptions {
	if {([lsearch -exact $modeOptions $modeOption] eq $calcMode)} {
	    lappend menuList "!•$modeOption"
	} else {
	    lappend menuList $modeOption
	}
    }
    lappend menuList "(-)"
    foreach prefItem [list "scientificNotation" "includeHistorySection" \
      "includeFunctionHyperlinks" "includeKeypadHyperlinks"] {
	set itemName [quote::Prettify $prefItem]
	if {$CalcmodeVars($prefItem)} {
	    lappend menuList "!√$itemName"
	} else {
	    lappend menuList "$itemName"
	}
    }
    lappend menuList "(-)" "Calculator Mode Help"
    return [list "build" $menuList {Calc::menuProc -m -M "Calc"}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::menuProc" --
 # 
 # Dispatch all Calc Menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::menuProc {menuName {itemName ""}} {
    
    global CalcmodeVars
    
    if {($itemName eq "")} {
	set itemName $menuName
	set menuName ""
    }
    switch -- $menuName {
	"calculatorMode" {
	    switch $itemName {
		"Change Mode"       {Calc::changeMode}
		"Display Mode"      {Calc::displayMode}
		"Include History Section" -
		"Include Function Hyperlinks" -
		"Include Keypad Hyperlinks" -
		"Scientific Notation" {
		    regsub -all -- { } $itemName {} prefName
		    set prefName [string replace $prefName 0 0 \
		      [string tolower [string index $prefName 0]]]
		    set onOrOff [set CalcmodeVars($prefName) \
		      [expr {1 - $CalcmodeVars($prefName)}]]
		    prefs::modified CalcmodeVars($prefName)
		    Calc::updatePreferences $prefName
		    status::msg "The \"${itemName}\" preference has been\
		      turned [expr {$onOrOff ? "on" : "off"}]."
		}
		"Calculator Mode Help" {
		    Calc::calculatorHelp "Calculator Modes"
		}
		default {
		    Calc::changeMode $itemName
		}
	    }
	}
	"ExpAndLog" - "Trigonometric" - "Hyperbolic" {
	    Calc::performOperation "unary" $itemName
	}
	"Boolean" {
	    Calc::requireCalcWindow
	    switch $itemName {
		"and"               {Calc::performOperation "binary" &}
		"or"                {Calc::performOperation "binary" |}
		"xor"               {Calc::performOperation "binary" ^}
		"shiftLeft"         {Calc::performOperation "binary" <<}
		"shiftRight"        {Calc::performOperation "binary" >>}
		"not"               {Calc::performOperation "unary" ~}
	    }
	}
	default {
	    if {($itemName eq "!ow")} {
		# Weird bug that I need to report.
		set itemName "pow"
	    }
	    switch $itemName {
		"calculatorWindow"  {Calc::calculatorWindow}
		"valueToClipboard"  {Calc::currentStack "putScrap"}
		"stackToClipboard"  {Calc::currentStack "putScrap"}
		"duplicateY"        {Calc::specialKey "duplicateY"}
		"swapXY"            {Calc::specialKey "swapXY"}
		"negate"            {Calc::performOperation "unary" -}
		"insertMinus"       {Calc::specialKey "Insert-Minus"}
		"mod"               {Calc::performOperation "function" "%"}
		"sqrt"              {Calc::performOperation "unary" sqrt}
		"floor"             {Calc::performOperation "unary" floor}
		"ceil"              {Calc::performOperation "unary" ceil}
		"e"                 {Calc::specialKey "constant-e"}
		"pi"                {Calc::specialKey "pi"}
		"calculatorPrefs"   {Calc::modePrefsDialog}
		"calculatorHelp"    {Calc::calculatorHelp}
		default {
		    Calc::performOperation "function" $itemName
		}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::specialKey" --
 # 
 # Most of the Calc mode bindings are passed through this procedure.  It
 # handles specialty operations, and ensures that the Cursor is residing in
 # the User Input field at all times.  The "fromHyperlink" is passed onto
 # [Calc::errorMessage] to determine how it should be delivered.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::specialKey {function {fromHyperlink 0}} {
    
    global CalcmodeVars keys::specialBindings keys::specialProcs
    
    variable calcMode
    variable modeOptions
    
    Calc::requireCalcWindow
    
    if {![Calc::inInputField 1]} {
	return
    }
    # Special cases first -- Arrow keys.
    if {([lsearch -exact [list "Up" "Down" "Right" "Left"] $function] > -1)} {
	if {[isSelection]} {
	    switch -- $function {
		"Up" - "Left"       {goto [getPos]}
		"Down" - "Right"    {goto [selEnd]}
	    }
	    return
	}
	switch -- $function {
	    "Up" {
		set posArg1 [lindex $inputPositions 1]
		set posArg2 [pos::prevLine]
		set posTest ">"
	    }
	    "Down" {
		set posArg1 [lindex $inputPositions 2]
		set posArg2 [pos::nextLine]
		set posTest "<"
	    }
	    "Left" {
		set posArg1 [lindex $inputPositions 1]
		set posArg2 [pos::prevChar]
		set posTest ">"
	    }
	    "Right" {
		set posArg1 [lindex $inputPositions 2]
		set posArg2 [pos::nextChar]
		set posTest "<"
	    }
	}
	if {[pos::compare $posArg1 $posTest $posArg2]} {
	    goto $posArg1
	} else {
	    goto $posArg2
	}
	return
    }
    # All other special functions.
    switch -- $calcMode {
        "2" {
	    if {[regexp {^[a-f0-9]$} $function]} {
		typeText -w $w $function
		return
	    }
        }
	"3" {
	    if {[regexp {^[0-9e]$} $function]} {
		typeText -w $w $function
		return
	    }
	}
	"4" {
	    if {[regexp {^[a-zA-Z0-9]$} $function]} {
		typeText -w $w $function
		return
	    }
        }
    }
    set cannotDelete "Cancelled -- cannot delete text outside\
      of the input field."

    switch -- $function {
	"Push-Stack" {
	    set input [string trim [Calc::currentInput]]
	    if {($input eq "")} {
		error "Cancelled -- No input to add to the Current Value stack."
	    } elseif {[catch {Calc::translateFrom $input} newValue]} {
	        error "Cancelled -- $newValue"
	    }
	    Calc::currentStack "push" $newValue
	    Calc::currentStack "update"
	    Calc::currentInput "«Empty»"
	    Calc::historyItem  "Pushed Stack :" $input
	    Calc::selectInput
	    status::msg        "Pushed Stack : $input"
	}
	"Pop-Stack" {
	    if {![llength [set oldStack [Calc::currentStack]]]} {
		set msg "the current stack is already empty."
		Calc::errorMessage $msg $fromHyperlink
	    }
	    set poppedValue    [Calc::translateTo [lindex $oldStack end]]
	    Calc::currentStack "pop"
	    Calc::currentStack "update"
	    Calc::historyItem  "Popped Stack :" "(${poppedValue})"
	    Calc::selectInput
	    status::msg        "Popped Stack : (${poppedValue})"
	}
	"Delete" {
	    set slctnBeg [getPos -w $w]
	    set inputBeg [lindex $inputPositions 1]
	    if {[isSelection -w $w]} {
		deleteSelection -w $w
		return
	    } elseif {[pos::compare $slctnBeg != $inputBeg]} {
		backSpace
		return
	    } elseif {($calcMode < 4)} {
		Calc::specialKey "Pop-Stack" $fromHyperlink
		return
	    } elseif {![string length [Calc::currentInput]]} {
		set msg "the current Input field is empty."
	    } else {
		set msg "at the beginning of the Input field."
	    }
	    Calc::errorMessage $msg $fromHyperlink
	}
	"Forward-Del-White" {
	    set slctnBeg [getPos -w $w]
	    set inputBeg [lindex $inputPositions 1]
	    set inputEnd [lindex $inputPositions 2]
	    if {![string is space -strict [lookAt -w $w $slctnBeg]]} {
		status::msg "No forward whitespace to delete."
		return
	    }
	    set match [search -w $w -n -s -f 1 -r 1 -- {\s+} $slctnBeg]
	    if {![llength $match]} {
		error "Cancelled -- could not find next word to delete."
	    } elseif {[pos::compare [lindex $match 1] < $inputEnd]} {
		set deleteTo [lindex $match 1]
	    } else {
		set deleteTo $inputEnd
	    }
	    deleteText -w $w $slctnBeg $deleteTo
	}
	"Forward-Del-Until" {
	    set slctnBeg [getPos -w $w]
	    set inputBeg [lindex $inputPositions 1]
	    set inputEnd [lindex $inputPositions 2]
	    status::msg "Forward delete up to next:"
	    set pat [quote::Regfind [getChar]]
	    status::msg ""
	    set match [search -w $w -n -s -f 1 -r 1 $pat $slctnBeg]
	    if {![llength $match]} {
	        error "Cancelled -- no matching character found."
	    } elseif {[pos::compare -w $w [lindex $match 1] > $inputEnd]} {
	        error $cannotDelete
	    }
	    deleteText -w $w $slctnBeg [lindex $match 1]
	}
	"Delete-Char" {
	    set slctnBeg [getPos -w $w]
	    set slctnEnd [selEnd -w $w]
	    set inputBeg [lindex $inputPositions 1]
	    set inputEnd [lindex $inputPositions 2]
	    if {[pos::compare -w $w $slctnBeg < $inputBeg]} {
		error $cannotDelete
	    } elseif {[isSelection -w $w]} {
		if {[pos::compare -w $w $slctnEnd > $inputEnd]} {
		    error $cannotDelete
		} else {
		    set deleteTo $slctnEnd
		}
	    } else {
		if {[pos::compare -w $w $slctnBeg >= $inputEnd]} {
		    error $cannotDelete
		} else {
		    set deleteTo [pos::nextChar -w $w $slctnBeg]
		}
	    }
	    deleteText -w $w $slctnBeg $deleteTo
	}
	"Delete-Word" {
	    set slctnBeg [getPos -w $w]
	    set inputBeg [lindex $inputPositions 1]
	    set inputEnd [lindex $inputPositions 2]
	    if {[string is space -strict [lookAt -w $w $slctnBeg]]} {
		set pat "\\s+$CalcmodeVars(wordBreak)"
	    } else {
	        set pat $CalcmodeVars(wordBreak)
	    }
	    set match [search -w $w -n -s -f 1 -r 1 -- $pat $slctnBeg]
	    if {![llength $match]} {
	        error "Cancelled -- could not find next word to delete."
	    } elseif {[pos::compare [lindex $match 1] < $inputEnd]} {
		set deleteTo [lindex $match 1]
	    } else {
		set deleteTo $inputEnd
	    }
	    deleteText -w $w $slctnBeg $deleteTo
	}
	"Back-Del-Word" {
	    set slctnBeg [getPos -w $w]
	    set slctnPre [pos::prevChar -w $w $slctnBeg]
	    set inputBeg [lindex $inputPositions 1]
	    set inputEnd [lindex $inputPositions 2]
	    if {[pos::compare -w $w $slctnBeg == $inputBeg]} {
		error $cannotDelete
	    }
	    if {[string is space -strict [lookAt -w $w $slctnPre]]} {
		set pat "\\s$CalcmodeVars(wordBreak)\\s+"
	    } else {
		set pat "\\s$CalcmodeVars(wordBreak)"
	    }
	    set match [search -w $w -n -s -f 1 -r 1 -- $pat $slctnPre]
	    if {![llength $match]} {
		error "Cancelled -- could not find previous word to delete."
	    } elseif {[pos::compare [lindex $match 0] < $inputEnd]} {
		set deleteFrom [pos::nextChar -w $w [lindex $match 0]]
	    } else {
		set deleteFrom $inputBeg
	    }
	    deleteText -w $w $deleteFrom $slctnBeg
	}
	"Kill-Line" {
	    set slctnBeg [getPos -w $w]
	    set lineEnd  [pos::lineEnd -w $w $slctnBeg]
	    set inputBeg [lindex $inputPositions 1]
	    set inputEnd [lindex $inputPositions 2]
	    if {[pos::compare -w $w $slctnBeg == $inputEnd]} {
	        error $cannotDelete
	    } elseif {[pos::compare -w $w $slctnBeg != $lineEnd]} {
		set deleteTo $lineEnd
	    } else {
		set deleteTo [pos::nextLineStart $slctnBeg]
	    }
	    deleteText -w $w $slctnBeg $deleteTo
	}
	"Open-Line" {
	    if {($calcMode == 4)} {
		set nlsPos [pos::nextLineStart -w $w [getPos -w $w]]
		replaceText -w $w $nlsPos $nlsPos "\r"
		typeText -w $w "\r"
	    } else {
		error "Cancelled -- no new 'open lines' are\
		  allowed in the input field."
	    }
	}
	"Return" {
	    if {($calcMode == 4)} {
		typeText -w $w "\r"
	    } else {
		Calc::specialKey "Push-Stack" $fromHyperlink
	    }
	}
	"Enter" {
	    if {($calcMode == 4)} {
		# Equation Editor mode.
		Calc::evalExpression $fromHyperlink
	    } else {
		Calc::specialKey "Push-Stack" $fromHyperlink
	    }
	}
	"Clear" {
	    set q "Are you sure that you want to clear all fields?\
	      \rThis cannot be un-done."
	    if {[askyesno $q]} {
		Calc::clearWindow 0 0 0
	    } else {
	        status::msg "Cancelled."
	    }
	}
	"Space" - " " {
	    if {($calcMode == 4)} {
		typeText -w $w " "
	    } else {
		Calc::specialKey "Push-Stack" $fromHyperlink
	    }
	}
	"Tab" {
	    # We know that we're in the Current Input field.
	    set specialBinding ""
	    foreach specialItem [array names keys::specialBindings] {
		if {($keys::specialBindings($specialItem) eq "/c")} {
		    set specialBinding $specialItem
		    break
		}
	    }
	    if {($specialBinding ne "")} {
		eval $keys::specialProcs($specialBinding)
	    } else {
		Calc::selectInput
	    }
	}
	"Equals" - "=" {
	    if {($calcMode == 4)} {
		Calc::evalExpression
	    } else {
		Calc::errorMessage "invalid input" $fromHyperlink
	    }
	}
	"duplicateY" {
	    if {($calcMode == 4)} {
		typeText -w $w "\$V"
		status::msg "Last value placed in the User Input field."
	    } else {
		if {![llength [set stack [Calc::currentStack]]]} {
		    error "Cancelled -- the current stack is empty."
		}
		Calc::currentInput [Calc::translateTo [lindex $stack end]]
		Calc::selectInput
		status::msg "Current value placed in the User Input field."
	    }
	}
	"swapXY" {
	    if {($calcMode == 4)} {
		Calc::errorMessage "this operation is not allowed in\
		  \"Equation Editor\" mode."
	    } elseif {![string length [set x [Calc::currentInput]]]} {
		set msg "there is no value in the Input field to swap."
	    } elseif {![llength [set stack [Calc::currentStack]]]} {
		set msg "the current stack is empty."
	    }
	    if {[info exists msg]} {
	        Calc::errorMessage $msg $fromHyperlink
	    }
	    Calc::currentStack "pop"
	    Calc::currentStack "push" [Calc::translateFrom $x]
	    Calc::currentStack "update"
	    Calc::currentInput [Calc::translateTo [lindex $stack end]]
	    Calc::selectInput
	    set value [Calc::translateFrom [lindex [Calc::currentStack] end]]
	    Calc::historyItem "(swapped x/y) :" $value 1
	    status::msg "Swapped Current Value with User Input."
	}
	"Insert-Minus" {
	    if {[regexp "^Unsigned" [lindex $modeOptions $calcMode]]} {
		set msg "'Insert Minus' is not applicable for 'Unsigned' modes."
		Calc::errorMessage $msg $fromHyperlink
	    } else {
		typeText -w $w "-"
	    }
	}
	"pi" {
	    set pi "3.14159265358979323"
	    if {($calcMode == 4)} {
		typeText -w $w $pi
	    } else {
		Calc::currentInput $pi
		Calc::selectInput
	    }
	}
	"constant-e" {
	    set e "2.718281828459045"
	    if {($calcMode == 4)} {
		typeText -w $w $e
	    } else {
		Calc::currentInput $e
		Calc::selectInput
	    }
	}
	"," {
	    if {($calcMode == 4)} {
		typeText -w $w ","
	    } else {
		typeText -w $w "."
	    }
	}
	"?" {
	    if {($calcMode == 4)} {
		typeText -w $w "?"
	    } else {
		Calc::calculatorHelp
	    }
	}
	"~" {
	    if {($calcMode == 4)} {
		typeText -w $w $function
	    } else {
		Calc::performOperation "unary" $function $fromHyperlink
	    }
	}
	"-" - "&" - "/" - "+" - "*" - "|" {
	    if {($calcMode == 4)} {
		typeText -w $w $function
	    } else {
		Calc::performOperation "binary" $function $fromHyperlink
	    }
	}
	"<" - ">" {
	    if {($calcMode == 4)} {
		typeText -w $w $function
	    } else {
		append function $function
		Calc::performOperation "binary" $function $fromHyperlink
	    }
	}
	"%" - "^" {
	    if {($calcMode == 4)} {
		typeText -w $w $function
	    } else {
		Calc::performOperation "function" $function $fromHyperlink
	    }
	}
	"h" {Calc::calculatorHelp}
	"i" {Calc::specialKey "swapXY" $fromHyperlink}
	"m" {Calc::changeMode}
	"n" {Calc::performOperation "unary" "-" $fromHyperlink}
	"q" {Calc::specialKey "duplicateY" $fromHyperlink}
	"x" {Calc::displayMode}
	default {
	    switch -- $calcMode {
		"0" - "1" {
		    if {[regexp {^[0-9]$} $function]} {
			typeText -w $w $function
			return
		    }
		}
		"2" {
		    if {[regexp {^[a-f0-9]$} $function]} {
			typeText -w $w $function
			return
		    } elseif {[regexp {^[A-F]$} $function]} {
			typeText -w $w [string tolower $function]
			return
		    }
		}
		"3" {
		    if {[regexp {^[-0-9eE.+]$} $function]} {
			typeText -w $w $function
			return
		    }
		}
		"4" {
		    typeText -w $w $function
		    return
		}
	    }
	    error "Cancelled -- '${function}' is not a valid\
	      [lindex $modeOptions $calcMode] keypress."
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::menuEnable" --
 # 
 # Enable or dim menu items relevant to the current Calculator mode.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::menuEnable {} {
    
    global calculatorMenu
    
    variable calcMode
    
    set dim1 [expr {($calcMode <= 3)                        ? 1 : 0}]
    set dim2 [expr {(($calcMode == 1) || ($calcMode == 2))  ? 0 : 1}]
    set dim3 [expr {($calcMode >= 3)                        ? 0 : 1}]
    set dim4 [expr {1 - $dim3}]
    
    enableMenuItem $calculatorMenu swapXY             $dim1
    enableMenuItem $calculatorMenu insertMinus        $dim2
    enableMenuItem $calculatorMenu Boolean            $dim3
    enableMenuItem $calculatorMenu ExpAndLog          $dim4
    enableMenuItem $calculatorMenu Trigonometric      $dim4
    enableMenuItem $calculatorMenu Hyperbolic         $dim4
    enableMenuItem $calculatorMenu OtherMathFunctions $dim4
    enableMenuItem $calculatorMenu Constants          $dim4
    
    enableMenuItem "calculatorMode" "Scientific Notation" $dim4
    
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::calculatorHelp" --
 # 
 # Open the "Calculator Help" file, optionally at a specific section.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::calculatorHelp {{sectionName ""}} {
    
    help::openGeneral "calculator" $sectionName
    return
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Calculator Window ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::calculatorWindow" --
 # 
 # Create our Calculator window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::calculatorWindow {} {
    
    global CalcmodeVars
    
    variable calcMode
    variable calculatorWindow
    variable historyCache
    variable lastInput
    
    Calc::initialize
    Calc::setFillColumn
    if {[win::Exists $calculatorWindow]} {
	bringToFront $calculatorWindow
	return
    }
    # For now, our "calculator" minor mode can only be applied before the
    # window is actually created.
    win::setInitialConfig $calculatorWindow minormode "calculator" window
    set w [eval [list new -n $calculatorWindow -m Text -shell 1] \
      $CalcmodeVars(windowGeometry)]
    Calc::buildWindow
    if {[llength [Calc::currentStack]]} {
        Calc::currentStack "update"
    }
    if {($lastInput ne "")} {
        Calc::currentInput $lastInput
    }
    if {$CalcmodeVars(includeHistorySection) && ($historyCache ne "")} {
	replaceText [maxPos -w $w] [maxPos -w $w] $historyCache
    }
    Calc::selectInput
    Calc::menuEnable
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::requireCalcWindow" --
 # 
 # Most Calculator Menu operations require a calculator window.  If "inFront"
 # is "1" we ensure that an existing Calculator window is in front, i.e. the
 # active window.  This will also create a local "w" variable for the calling
 # procedure, the name of the window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::requireCalcWindow {{inFront "0"}} {
    
    variable calculatorWindow
    
    upvar w w
    set w $calculatorWindow
    if {![win::Exists $w]} {
	error "Cancelled -- this operation requires a Calculator window."
    } elseif {$inFront && ([win::Current] ne $w)} {
        bringToFront $w
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::buildWindow" --
 # 
 # Remove all previous Calculator Window contents, and insert fresh text.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::buildWindow {} {
    
    global CalcmodeVars
    
    variable calcMode
    variable calculatorWindow
    variable windowSections
    
    set w $calculatorWindow
    if {![win::Exists $w]} {
	return
    }
    set divider [string repeat "_" 80]
    # Avoid bug# 1671 -- won't be necessary after Alpha 8.0 final release
    catch {removeColorEscapes -w $w}
    # Create the initial text for the Calculator Window.
    if {($calcMode < 4)} {
	set text $windowSections(Stack)
	lappend sections "Stack"
    } else {
	set text $windowSections(Value)
	lappend sections "Value"
    }
    append text "\r\r\r" $divider "\r\r" \
      [format "%-15s %s" "Input :" "«Clear»"] "\r\r\r" $divider "\r\r"
    lappend sections "Input"
    set addDivider 0
    if {$CalcmodeVars(includeKeypadHyperlinks)} {
	set addDivider 1
	append text $windowSections(Keypad) "\r\r"
	lappend sections "Keypad"
	# Standard Keypad
        append text \
	  {[ 1 ] [ 2 ] [ 3 ]  [*] }           "\r" \
	  {[ 4 ] [ 5 ] [ 6 ]  [/] }           "\r" \
	  {[ 7 ] [ 8 ] [ 9 ]  [+] }           "\r" \
	  {[ 0 ]  [ Enter ]   [-] }           "\r"
	foreach item [list 1 2 3 4 5 6 7 8 9 0 Enter] {
	    set key "\[ $item \]"
	    set hyperScript($key) "Calc::specialKey $item 1"
	}
	foreach item [list + - * /] {
	    set key " \[$item\] "
	    set hyperScript($key) "Calc::performOperation binary $item 1"
	}
    }
    if {$CalcmodeVars(includeFunctionHyperlinks)} {
	set addDivider 1
	if {!$CalcmodeVars(includeKeypadHyperlinks)} {
	    append text $windowSections(Functions)
	} else {
	    append text "\rFunctions :"
	}
	append text "\r\r" {[Y]}
	lappend sections "Functions"
	if {($calcMode < 4)} {
	  append text { [X <-> Y]}
	}
	array set hyperScript [list \
	  {[Y]}         {Calc::specialKey "duplicateY" 1} \
	  {[X <-> Y]}   {Calc::specialKey "swapXY" 1} \
	  ]
	if {($calcMode < 3)} {
	    # Boolean.
	    append text "\r\r" \
	      {[ & ] [ | ] [ ^ ]} "\r" \
	      {[ < ] [ > ] [ ~ ]} "\r\r"
	    foreach item [list & | ^] {
		set key "\[ $item \]"
		set hyperScript($key) "Calc::performOperation binary $item 1"
	    }
	    array set hyperScript [list \
	      {[ < ]} {Calc::performOperation "binary" "\<\<" 1} \
	      {[ > ]} {Calc::performOperation "binary" "\>\>" 1} \
	      {[ ~ ]} {Calc::performOperation "unary"  ~  1} \
	      ]
	} else {
	    # Math functions.
	    append text \
	      { [pi] [e]}                       "\r\r"\
	      {[exp]   [log]   [log10]}         "\r" \
	      {[pow]   [sqrt]  [fmod]}          "\r" \
	      {[abs]   [floor] [ceil]}          "\r\r" \
	      {[cos]   [sin]   [tan]}           "\r" \
	      {[acos]  [asin]  [atan]}          "\r" \
	      {[cosh]  [sinh]  [tanh]}          "\r" \
	      {[ach]   [ash]   [ath]}           "\r" \
	      {[hypot] [atan2]}                 "\r"
	    foreach item [list exp log log10 sqrt floor ceil abs \
	      cos sin tan acos asin atan cosh sinh tanh ach ash ath] {
		set key "\[$item\]"
		set hyperScript($key) "Calc::performOperation unary $item 1"
	    }
	    foreach item [list pow fmod atan2 hypot] {
		set key "\[$item\]"
		set hyperScript($key) "Calc::performOperation function $item 1"
	    }
	    array set hyperScript [list \
	      {[pi]}  {Calc::specialKey "pi" 1} \
	      {[e]}   {Calc::specialKey "constant-e" 1} \
	      ]
	}
    }
    if {$addDivider} {
	append text $divider "\r\r"
    }
    if {$CalcmodeVars(includeHistorySection)} {
	append text $windowSections(History) "\r\r"
	lappend sections "History"
    }
    replaceText -w $w [minPos -w $w] [maxPos -w $w] $text
    goto -w $w [minPos -w $w]
    # Add some hyperlinks.
    foreach section $sections {
	regsub -- {^(.+)(«.+»)} $windowSections($section) {\1(\2)} pat
	set script "Calc::sectionHyperlink $section"
	win::searchAndHyperise -w $w $pat $script 1 4 +17 -1
    }
    foreach item [array names hyperScript] {
	set script $hyperScript($item)
	win::searchAndHyperise -w $w $item $script 0 1 +1 -1
    }
    if {($calcMode >= 3)} {
        set pos0 [pos::math -w $w [minPos -w $w] + 10]
	set pos1 [pos::math -w $w [minPos -w $w] + 11]
	set pos2 [pos::math -w $w [minPos -w $w] + 13]
	set pos3 [pos::math -w $w [minPos -w $w] + 14]
	set script {Calc::sectionHyperlink "SN" ; # Toggle Scientific Notation}
	replaceText -w $w $pos0 $pos3 "«SN»"
	text::color -w $w $pos1 $pos2 4
	text::hyper -w $w $pos1 $pos2 $script
    }
    refresh -w $w
    goto -w $w [lindex [Calc::fieldPositions "input"] 2]
    Calc::displayMode
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::setFillColumn" --
 # 
 # Determine the proper fill column length given the user's preferences or
 # the geometry of the Calculator window.  This is both returned and stored
 # in the "CalcmodeVars(fillColumn)" variable.  It is _not_ made global, that
 # should be taken care of by the SystemCode when necessary.
 # 
 # This is experimental -- it takes the "ScrollBarWidth" into account.
 # 
 # WORKAROUND for bug# 1783 :
 # 
 #     [getTextDimensions] fails with many default fonts
 # 
 # Use the less precise calculation if preferred version fails.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::setFillColumn {} {
    
    global CalcmodeVars alpha::platform defWidth defaultFont fontSize
    
    variable calculatorWindow
    
    # WORKAROUND for bug# 1783
    set CalcmodeVars(fillColumn) 24
    return "24"
    
    if {[win::Exists [set w $calculatorWindow]]} {
	set width    [lindex [getGeometry $w] 2] ; # l t w h
	set fontname [win::getInfo $w font]
	set fontsize [win::getInfo $w fontsize]
    } elseif {([llength $CalcmodeVars(windowGeometry)] == 5)} {
	set width [lindex $CalcmodeVars(windowGeometry) 3]
	set fontname $defaultFont
	set fontsize $fontSize
    } else {
	set width $defWidth
	set fontname $font
	set fontsize $fontSize
    }
    set X [string repeat "abcdeABCDE" 10]
    switch -- ${alpha::platform} {
	"alpha" {
	    set script {getTextDimensions -font $fontname -size $fontsize $X}
	    if {![catch $script fontMeas]} {
		set fontMeas [expr {[lindex $fontMeas 2] / 100.0}]
		set fillCol  [expr {($width / $fontMeas) - 7}]
	    } else {
		# WORKAROUND for bug# 1783
		set fillCol [expr {($width / $fontsize) * 1.35}]
	    }
	}
	"tk" {
	    set fontMeas [font measure [list $fontname $fontsize] $X]
	    set fontMeas [expr {[screenToDistance $fontMeas] / 100}]
	    set fillCol  [expr {($width / $fontMeas) - 7}]
	}
    }
    set fillCol [expr {$fillCol / 100.0}]
    if {([set fillCol [expr {int($fillCol)}]] < 10)} {
	set fillCol "10"
    }
    set CalcmodeVars(fillColumn) $fillCol
    return $CalcmodeVars(fillColumn)
}

# ===========================================================================
# 
# ◊◊◊◊ Window Sections ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::clearWindow" --
 # 
 # Called when the "includeKeypadHyperlinks" or "includeFunctionHyperlinks"
 # preference has been changed, save all current field information, reset the
 # window, and place that values back in.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::clearWindow {saveStack saveInput saveHistory {closeAndOpen 0}} {
    
    global CalcmodeVars
    
    variable historyCache
    
    if {[catch {Calc::requireCalcWindow}]} {
	return
    }
    if {!$saveStack} {
	Calc::currentStack "clear"
    }
    if {$saveInput} {
	set input [Calc::currentInput]
    } else {
        set input "«Empty»"
    }
    if {!$saveHistory} {
	set historyCache ""
    }
    if {$closeAndOpen} {
        killWindow -w $w
	Calc::calculatorWindow
    } else {
	Calc::buildWindow
    }
    if {$CalcmodeVars(includeHistorySection)} {
	replaceText [maxPos -w $w] [maxPos -w $w] $historyCache
    }
    Calc::currentStack "update"
    Calc::currentInput $input
    Calc::selectInput
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::sectionHyperlink" --
 # 
 # Called by clicking on a hyperlink in a Calculator window section heading.
 # This should not be called by any other code.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::sectionHyperlink {sectionName} {
    
    Calc::requireCalcWindow 1
    
    switch -- $sectionName {
	"Functions" {
	    Calc::modePrefsDialog
	}
	"History" {
	    Calc::clearWindow 1 1 0
	}
	"Input" {
	    Calc::clearWindow 1 0 1
	}
	"Keypad" {
	    Calc::modePrefsDialog
	}
	"SN" {
	    Calc::menuProc "calculatorMode" "Scientific Notation"
	}
	"Stack" {
	    Calc::currentStack "clear"
	    Calc::clearWindow 0 1 1
	    Calc::historyItem "(reset stack)" "" 1
	}
	"Value" {
	    Calc::clearWindow 0 1 1
	    Calc::historyItem "(reset value)" "" 1
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::fieldPositions" --
 # 
 # Return a list of four positions relevant to the requested field.
 # 
 # "<field>Pre" and "<field>Post" are the line start positions that define
 # the entire field, while "<field>Beg" and "<field>End" are the start/end
 # positions for line(s) containing the field values.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::fieldPositions {field} {
    
    global CalcmodeVars
    
    variable windowSections
    
    Calc::requireCalcWindow
    
    switch -- $field {
        "value" {
	    # The first position is always the start of the second line.
	    set fieldPre [pos::nextLineStart -w $w [minPos -w $w]]
	    set fieldBeg [pos::nextLineStart -w $w $fieldPre]
	    # Find the next divider line.
	    append pat {^[^\r\n]*} [string repeat "_" 30] {[^\r\n]*$}
	    set dividerLine [search -w $w -n -s -f 1 -r 1 -- $pat $fieldPre]
	    if {![llength $dividerLine]} {
		error "Cancelled -- could not find the divider line."
	    }
	    set fieldPost [lindex $dividerLine 0]
	    set fieldEnd  [pos::prevLineEnd -w $w $fieldPost]
        }
        "input" {
	    # Find the "Input :" line.
	    set pat1 "^$windowSections(Input)$"
	    set inputLine [search -w $w -n -s -f 1 -r 1 -- $pat1 [minPos -w $w]]
	    if {![llength $inputLine]} {
		error "Cancelled -- could not find the input line."
	    }
	    set fieldPre [pos::nextLineStart -w $w [lindex $inputLine 1]]
	    set fieldBeg [pos::nextLineStart -w $w $fieldPre]
	    # Find the next divider line.
	    append pat2 {^[^\r\n]*} [string repeat "_" 30] {[^\r\n]*$}
	    set dividerLine [search -w $w -n -s -f 1 -r 1 -- $pat2 $fieldPre]
	    if {![llength $dividerLine]} {
		error "Cancelled -- could not find the divider line."
	    }
	    set fieldPost [lindex $dividerLine 0]
	    set fieldEnd  [pos::prevLineEnd -w $w $fieldPost]
        }
        "history" {
            if {!$CalcmodeVars(includeHistorySection)} {
                set pos [maxPos -w $w]
		return [list $pos $pos $pos $pos]
            }
	    set pat1 "^$windowSections(History)$"
	    set histLine [search -w $w -n -s -f 1 -r 1 -- $pat1 [minPos -w $w]]
	    if {![llength $histLine]} {
		error "Cancelled -- could not find the history line."
	    }
	    set fieldPre  [pos::nextLineStart -w $W [lindex $histLine 1]]
	    set fieldBeg  [pos::nextLineStart -w $w $fieldPre]
	    set fieldEnd  [maxPos -w $w]
	    set fieldPost [maxPos -w $w]
        }
        default {
            error "Unknown field type: $field"
        }
    }
    return [list $fieldPre $fieldBeg $fieldEnd $fieldPost]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::currentStack" --
 # 
 # Maintain the "stackValues" list.  These are not translated, so that we are
 # able to decouple the "displayPrecision" pref and "tcl_precision" value.
 # If the first argument is "push" then all remaining arguments are pushed to
 # the bottom of the stack.  The "update" argument will refresh the current
 # Value/Stack field.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::currentStack {args} {
    
    global CalcmodeVars
    
    variable calcMode
    variable stackValues
    
    if {([lindex $args 0] ne "push") && ([llength $args] > 1)} {
	error "too many arguments for '[lindex $args 0]'"
    }
    switch -- [lindex $args 0] {
	"clear" {
	    set stackValues [list]
	}
	"pop" {
	    set stackValues [lrange $stackValues 0 end-1]
	}
	"push" {
	    foreach newValue [lrange $args 1 end] {
		lappend stackValues $newValue
	    }
	}
	"putScrap" {
	    if {[llength $stackValues]} {
		set newValueList [list]
		foreach value $stackValues {
		    lappend newValueList [Calc::translateTo $value 1]
		}
	    } elseif {($calcMode == 4)} {
		set newValueList [list \
		  [format "%.$CalcmodeVars(displayPrecision)f" 0]]
	    } else {
		error "Cancelled -- the current stack is empty."
	    }
	    putScrap [join $newValueList "\r"]
	    status::msg "The current\
	      [expr {($calcMode < 4) ? "stack" : "value"}]\
	      has been placed in the Clipboard."
	}
	"update" {
	    Calc::requireCalcWindow
	    if {[llength $stackValues]} {
		set newValueList [list]
		foreach value $stackValues {
		    lappend newValueList [Calc::translateTo $value 1]
		}
	    } elseif {($calcMode == 4)} {
		set newValueList [list \
		  [format "%.$CalcmodeVars(displayPrecision)f" 0]]
	    } else {
		set newValueList [list ""]
	    }
	    set positions [Calc::fieldPositions "value"]
	    set valueBeg  [lindex $positions 1]
	    set valueEnd  [lindex $positions 2]
	    set newValue  [string trim [join $newValueList "\r"]]
	    replaceText -w $w $valueBeg $valueEnd $newValue
	}
    }
    return $stackValues
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::currentInput" --
 # 
 # If a "newInput" argument is supplied, place it in the User Input field of
 # the Calculator window.  Otherwise return the current input in that field.
 # 
 # If the input value is "«Empty»" then the input field will be blank.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::currentInput {{newInput ""} {regsubSpaces 1}} {
    
    global CalcmodeVars
    
    variable lastInput
    
    Calc::requireCalcWindow
    
    set positions [Calc::fieldPositions "input"]
    set inputPre  [lindex $positions 0]
    set inputPost [lindex $positions 3]
    if {($newInput ne "")} {
	if {($newInput eq "«Empty»")} {
	    set newInput ""
	}
	if {$regsubSpaces} {
	    regsub -all {\s+} $newInput { } newInput
	    set newInput [breakIntoLines $newInput $CalcmodeVars(fillColumn)]
	}
	set newInput [string trim $newInput]
	replaceText -w $w $inputPre $inputPost "\r${newInput}\r"
	set lastInput $newInput
	return $newInput
    } else {
	set oldInput ""
	set oldInput [string trim [getText -w $w $inputPre $inputPost]]
	if {$regsubSpaces} {
	    regsub -all -- {\s+} $oldInput { } oldInput
	    set oldInput [breakIntoLines $oldInput $CalcmodeVars(fillColumn)]
	}
	return $oldInput
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::cutInput" --
 # 
 # Ensure that we only cut text from the Input field.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::cutInput {args} {
    
    win::parseArgs w
    
    variable calculatorWindow
    
    win::parseArgs w
    
    if {($w eq $calculatorWindow) && [win::Exists $calculatorWindow]} {
	if {![Calc::inInputField 0]} {
	    error "Cancelled -- only text in the Input field can be cut."
	}
    }
    return [hook::procOriginal ::Calc::cutInput -w $w]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::pasteInput" --
 # 
 # Special pasting routine for the Calculator window.
 # 
 # If we are in "Equation Editor" mode, make sure that the cursor in in the
 # Input field, break the Clipboard contents into lines that will be visible,
 # and then insert it into the Input field (replacing any previously selected
 # text if necessary.)
 # 
 # If we are in an RPN mode, we first push any current Input into the stack.
 # If the Clipboard text has multiple lines, we push all but the last into
 # the stack, and then paste the last one into the Input field.  This allows
 # the user to paste in a set of values like
 # 
 #   1.003
 #   42345234523452
 #   45.3
 #   36.0
 #   
 # and end up with
 # 
 #   Stack :         «Clear»
 # 
 #   1
 #   1.003
 #   4.234523452e+13
 #   45.3
 #   ________________________________________________________________________________
 # 
 #   Input :         «Clear»
 # 
 #   36.0
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::pasteInput {args} {
    
    global CalcmodeVars
    
    variable calcMode
    variable calculatorWindow
    variable fillColumn
    variable historyCache
    
    win::parseArgs w
    
    set oldScrap  [string trim [getScrap]]
    set operators {^[-+*/~&\|<>%^]$}
    if {($w ne $calculatorWindow)} {
	return [hook::procOriginal ::Calc::pasteInput -w $w]
    } elseif {($oldScrap eq "")} {
	error "Cancelled -- nothing to paste into the input field."
    }
    if {![Calc::inInputField]} {
	Calc::selectInput
    } elseif {[isSelection -w $w]} {
	deleteSelection -w $w
    }
    if {($calcMode == 4)} {
	set rightCol [Calc::setFillColumn]
	set newInput [split $oldScrap "\r\n"]
	for {set i 0} {($i < [llength $newInput])} {incr i} {
	    set inputLine [string trim [lindex $newInput $i]]
	    regsub -all -- {[\t ]+} $inputLine { } inputLine
	    set inputLine [breakIntoLines $inputLine $rightCol 0]
	    set newInput  [lreplace $newInput $i $i $inputLine]
	}
	set newInput [join $newInput "\r"]
    } else {
	watchCursor
	set oldStack [Calc::currentStack]
	set oldInput [Calc::currentInput]
	set oldHstry $historyCache
	set newInput [split $oldScrap "\r\n\t "]
	# If the current input is non-empty, add it to the current stack.
	if {($oldInput ne "")} {
	    if {[catch {Calc::specialKey "Push-Stack"} result]} {
		lappend errorList [list $oldInput $result]
		Calc::currentInput "«Empty»"
		Calc::selectInput
	    }
	}
	# Add all of the new lines to the Input field, and add all but the
	# last one to the current stack.
	foreach inputLine [lrange $newInput 0 end-1] {
	    set inputLine [string trim $inputLine]
	    if {($inputLine eq "")} {
		continue
	    }
	    Calc::currentInput "«Empty»"
	    Calc::selectInput
	    # Allow common operators to be include in the Clipboard.
	    if {[regexp $operators $inputLine]} {
	        if {[catch {Calc::specialKey $inputLine 0} result]} {
		    lappend errorList [list $inputLine $result]
		}
		continue
	    }
	    if {[catch {Calc::currentInput $inputLine} result]} {
		lappend errorList [list $inputLine $result]
		continue
	    } else {
	        Calc::selectInput
	    }
	    if {[catch {Calc::specialKey "Push-Stack"} result]} {
		lappend errorList [list $inputLine $result]
		continue
	    }
	}
	# Did we encounter any errors?
	if {[info exists errorList]} {
	    Calc::clearWindow  0 0 0 0
	    Calc::currentInput $oldInput
	    eval [list Calc::currentStack "push"] $oldStack
	    Calc::currentStack "update"
	    if {$CalcmodeVars(includeHistorySection)} {
	        replaceText -w $w [maxPos -w $w] [maxPos -w $w] $oldHstry
	    }
	    Calc::selectInput
	    if {([llength $errorList] == 1)} {
		set errorLengthText "The following dialog pane describes the\
		  1 error.\r"
	    } elseif {([llength $errorList] < 25)} {
		set errorLengthText "The following dialog panes describe the\
		  [llength $errorList] errors.\r"
	    } else {
		set errorLengthText "The following dialog panes describe the\
		  first 25 errors.\r"
		set errorList [lrange $errorList 0 24]
	    }
	    set dialogScript [list dialog::make -title "Pasting Errors" \
	      -cancel "" \
	      [list "Multi-line paste failed." \
	      [list "text" "When pasting in a multi-line Clipboard string,\
	      each item is added to the current stack as if you had\
	      typed it into the Input field.  This requires each line\
	      to represent valid input …\r"] \
	      [list "text" $errorLengthText]]]
	    for {set n 1} {($n <= [llength $errorList])} {incr n} {
		set i [expr {$n - 1}]
		lappend dialogScript [list \
		  "Error (${n}) of ([llength $errorList])" \
		  [list "text" "Invalid input: [lindex $errorList $i 0]\r"] \
		  [list "text" [lindex $errorList $i 1]]]
	    }
	    eval $dialogScript
	    error "Cancelled -- invalid input."
	}
	# Put in the last item.
	set newInput [lindex $newInput end]
	if {[regexp $operators $newInput]} {
	    Calc::specialKey $newInput 0
	    set newInput ""
	}
    }
    putScrap [string trim $newInput]
    set ranges [hook::procOriginal ::Calc::pasteInput]
    Calc::selectInput
    putScrap $oldScrap
    status::msg "The Clipboard text has been entered into the Calculator."
    return $ranges
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::inInputField" --
 # 
 # Determine if the current position/selection is within the boudaries of the
 # User Input field.  This will also create a local "inputPositions" variable
 # in the calling procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::inInputField {{goThere 1}} {
    
    Calc::requireCalcWindow
    
    upvar inputPositions positions
    
    set positions [Calc::fieldPositions "input"]
    set inputBeg  [lindex $positions 1]
    set inputEnd  [lindex $positions 2]
    set slctnBeg  [getPos -w $w]
    set slctnEnd  [selEnd -w $w]
    if {[pos::compare -w $w $inputBeg > $slctnBeg] \
      || [pos::compare -w $w $inputEnd < $slctnEnd]} {
	set isIn 0
    } else {
	set isIn 1
    }
    if {!$isIn && $goThere} {
	beep
	Calc::selectInput
	status::msg "Cursor returned to the Input field."
    }
    return $isIn
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::selectInput" --
 # 
 # Select the entire contents of the User Input field.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::selectInput {} {
    
    Calc::requireCalcWindow
    
    goto -w $w [minPos -w $w]
    set positions [Calc::fieldPositions "input"]
    selectText -w $w [lindex $positions 1] [lindex $positions 2]
    refresh -w $w
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::historyItem" --
 # 
 # Add a new history item at the end of the Calculator window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::historyItem {userInput {newValue ""} {addDivider 0}} {
    
    global CalcmodeVars
    
    variable calcMode
    variable historyCache
    
    Calc::requireCalcWindow
    
    if {!$CalcmodeVars(includeHistorySection)} {
        return
    }
    if {$addDivider eq "1"} {
	append dashLine [string repeat "-" 80] "\r"
	replaceText -w $w [maxPos -w $w] [maxPos -w $w] $dashLine
	append historyCache $dashLine
    }
    if {($userInput eq "")} {
        return
    }
    if {([string length $userInput] <= 15) \
      && (($calcMode != 4) || ([string index $userInput end] eq ":"))} {
	append historyItem [format "%-16s $newValue" $userInput]
    } else {
	append historyItem $userInput
	if {($newValue ne "")} {
	    append historyItem "\r" [string repeat " " 16] $newValue
	}
    }
    append historyItem "\r"
    replaceText -w $w [maxPos -w $w] [maxPos -w $w] $historyItem
    append historyCache $historyItem
    return
}

# ===========================================================================
# 
# ◊◊◊◊ Calculator 'Mode' ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::changeMode" --
 # 
 # Change the current Calculator mode.  If "(Help)" is selected, then we open
 # the help file to the relevant section.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::changeMode {{newMode ""}} {
    
    global CalcmodeVars
    
    variable calcMode
    variable calculatorWindow
    variable modeOptions
    
    if {($newMode eq "")} {
	set p "Choose a new Calculator Mode:"
	set L [list [lindex $modeOptions $calcMode]]
	set options [concat $modeOptions [list "(Help)"]]
	set newOption [listpick -indices -p $p -L $L -- $options]
	if {$newOption == "5"} {
	    Calc::calculatorHelp "Calculator Modes"
	    return
	}
	set newMode $newOption
    } elseif {([set idx [lsearch -exact $modeOptions $newMode]] > -1)} {
	set newMode $idx
    } elseif {![regexp {^[0-4]$} $newMode]} {
	error "Cancelled -- unknown mode type: $newMode"
    }
    if {[catch {set oldInput [Calc::translateFrom [Calc::currentInput]]}]} {
	set oldInput "«Empty»"
    }
    set calcMode $newMode
    prefs::modified calcMode
    if {[catch {Calc::currentStack "update"} err]} {
	alertnote $err
	Calc::currentStack "clear"
	Calc::currentStack "update"
    }
    catch {Calc::currentInput $oldInput}
    menu::buildSome "calculatorMenu"
    Calc::historyItem "(new mode) :" [lindex $modeOptions $calcMode] 1
    Calc::clearWindow 1 1 1
    Calc::displayMode
    Calc::menuEnable
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::displayMode" --
 # 
 # Display the current Calculator mode in the status bar.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::displayMode {} {
    
    variable calcMode
    variable modeOptions
    
    status::msg "The current Calculator mode is\
      \"[lindex $modeOptions $calcMode]\""
    return
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Calculator Operations ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::errorMessage" --
 # 
 # A simple utility to inform the user when something didn't work out as
 # expected.  If "fromHyperlink" is "1" then we deliver any error information
 # in an alertnote since the hyperlink text will generally obscure status bar
 # error messages.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::errorMessage {msg {inAlernote 0}} {
    
    if {![string match -nocase "*cancel*" $msg]} {
	set msg "Cancelled -- $msg"
    }
    if {![regexp {\.\"?$} $msg]} {
	append msg "."
    }
    if {$inAlernote} {
	regsub -- {^Cancelled -- } $msg "Cancelled:\r\r" msg
	alertnote $msg
    }
    error $msg
    
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::translateFrom" --
 # 
 # Stack values are stored "untranslated", i.e. as numeric strings that are
 # returned by [expr].  This procedure will translate a string for inclusion
 # in the stack.  It is intended for Input values only.
 # 
 # We use [string tolower $result] to convert the value from floating point
 # to an actual string -- see <http://www.tcl.tk/cgi-bin/tct/tip/132.html>.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::translateFrom {value} {
    
    global tcl_precision
    
    variable calcMode
    variable fullPrecision
    
    set value [string trim $value]
    switch -- $calcMode {
	0 {
	    set pat {[-0-9+]+}
	    set arg "%ld"
	}
	1 {
	    set pat {[0-9]+}
	    set arg "%lu"
	}
	2 {
	    set pat {[0-9a-f]+}
	    set arg "%lx"
	}
	3 - 4 {
	    set pat {[-eE0-9.+]+}
	    set arg "%g"
	}
    }
    set defaultTP $tcl_precision
    set tcl_precision $fullPrecision
    if {![regexp "^${pat}$" $value]} {
	set errorMessage "invalid entry: $value"
    } elseif {[catch {scan $value $arg} result]} {
	set errorMessage $result
    } else {
        set result [string tolower $result]
    }
    set tcl_precision $defaultTP
    if {[info exists errorMessage]} {
        error "Cancelled -- $errorMessage"
    } else {
        return $result
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::translateTo" --
 # 
 # Stack values are stored "untranslated", i.e. as numeric strings that are
 # returned by [expr].  This procedure will convert them into a string that
 # is displayed to the user, respecting the "displayPrecision" preference for
 # Floating Point and Equation Editor modes.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::translateTo {value {forStackDisplay 0}} {
    
    global CalcmodeVars
    
    variable calcMode
    variable fullPrecision
    
    switch -- $calcMode {
	0 {
	    set arg "%ld"
	}
	1 {
	    set arg "%lu"
	}
	2 {
	    set arg "%lx"
	}
	3 - 4 {
	    if {!$forStackDisplay \
	      || ($CalcmodeVars(displayPrecision) > $fullPrecision)} {
		set prec $fullPrecision
	    } elseif {($CalcmodeVars(displayPrecision) < 1)} {
		set prec 1
	    } else {
		set prec $CalcmodeVars(displayPrecision)
	    }
	    if {$CalcmodeVars(scientificNotation)} {
		set arg "%.${prec}e"
	    } else {
		set arg "%.${prec}g"
	    }
	}
    }
    if {[catch {format $arg $value} result]} {
	error "Cancelled -- invalid entry: $value"
    } else {
	return $result
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::performOperation" --
 # 
 # All binary/unary/function operations are passed through this procedure.
 # We call the [Calc::${type}Operation] commands, which return a three item
 # list containing
 # 
 # (1) a script to be passed through [expr]
 # (2) a formatted History item
 # (3) the number of stack values to be "popped."
 # 
 # We make sure that we use the correct "tcl_precision" value but always
 # restore the original even if something went wrong.
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::performOperation {type operation {fromHyperlink 0}} {
    
    global tcl_precision
    
    variable fullPrecision
    
    Calc::requireCalcWindow
    
    if {![Calc::inInputField 1]} {
	return
    }
    if {[catch {::Calc::${type}Operation $operation} operationList]} {
	Calc::errorMessage $operationList $fromHyperlink
    } elseif {![llength $operationList]} {
        return
    }
    set exprScript [lindex $operationList 0]
    set histScript [lindex $operationList 1]
    set defaultTP  $tcl_precision
    set tcl_precision $fullPrecision
    if {[catch {eval expr $exprScript} value]} {
	set errorMessage $value
    } else {
	set value [string tolower $value]
    }
    set tcl_precision $defaultTP
    if {[info exists errorMessage]} {
	Calc::historyItem $histScript
	Calc::historyItem "  Error : $value"
	Calc::errorMessage $errorMessage $fromHyperlink
    }
    for {set i 0} {($i < [lindex $operationList 2])} {incr i} {
	Calc::currentStack "pop"
    }
    Calc::currentStack "push" $value
    Calc::currentStack "update"
    Calc::historyItem  $histScript [Calc::translateTo $value]
    Calc::currentInput "«Empty»"
    Calc::selectInput
    status::msg "(${histScript}) == [Calc::translateTo $value]"
    return $value
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::binaryOperation" --
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::binaryOperation {operation} {
    
    variable calcMode
    
    set cannotDo [list "&" "|" "<<" ">>"]
    if {($calcMode == 3) && ([lsearch -exact $cannotDo $operation] > -1)} {
	error "Cancelled -- $operation does not work in Floating Point mode"
    } elseif {($calcMode == 4)} {
	switch -- $operation {
	    "<<" {set operation "<"}
	    ">>" {set operation ">"}
	}
	if {[regexp {^\w+$} $operation]} {
	    elec::Wrap "${operation}(" ")••" 0
	} else {
	    typeText -w $w $operation
	}
	return
    }
    set stack [Calc::currentStack]
    # Determine 'input' and 'output' values.
    if {([set Input [Calc::currentInput]] ne "")} {
	# We have input, so operate on the last item in the stack.
	set input [Calc::translateFrom $Input]
	if {![llength $stack]} {
	    set value "0"
	} else {
	    set value [lindex $stack end]
	}
	set Value [Calc::translateTo $value]
	set popTo 1
    } else {
        # We have no input, so operate on the last two items in the stack.
	if {![llength $stack]} {
	    set input "0"
	    set value "0"
	} elseif {([llength $stack] == 1)} {
	    set input "0"
	    set value [lindex $stack end]
	} else {
	    set input [lindex $stack end]
	    set value [lindex $stack end-1]
	}
	set Input [Calc::translateTo $input]
	set Value [Calc::translateTo $value]
	set popTo 2
    }
    if {($calcMode <= 2)} {
        set value "wide($value)"
	set input "wide($input)"
    }
    append exprScript $value " " $operation " " $input
    append histScript $Value " " $operation " " $Input
    return [list $exprScript $histScript $popTo]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::unaryOperation" --
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::unaryOperation {operation} {
    
    variable calcMode
    
    if {($calcMode < 3) && ($operation ne "-") && ($operation ne "~")} {
	error "Cancelled -- $operation works only in Floating Point mode"
    } elseif {($calcMode == 3) && ($operation eq "~")} {
	error "Cancelled -- $operation does not work in Floating Point mode"
    } elseif {($calcMode == 4)} {
	elec::Wrap "${operation}(" ")••" 0
	return
    }
    set stack [Calc::currentStack]
    # Determine 'input' and 'output' values.
    if {([set Input [Calc::currentInput]] ne "")} {
	# We have input.
	set input [Calc::translateFrom $Input]
	set popTo 0
    } else {
	# We have no input, so operate on the last item in the stack.
	if {![llength $stack]} {
	    set input "0"
	} else {
	    set input [lindex $stack end]
	}
	set Input [Calc::translateTo $input]
	set popTo 1
    }
    switch -- $operation {
	"ach"   {
	    set exprScript "log(${input}+sqrt(${input}*${input}-1))"
	    set histScript "log(${Input}+sqrt(${Input}*${Input}-1))"
	}
	"ash"   {
	    set exprScript "log(${input}+sqrt(${input}*${input}+1))"
	    set histScript "log(${Input}+sqrt(${Input}*${Input}+1))"
	}
	"ath"   {
	    set exprScript "0.5*log((1+${input})/(1-${input}))"
	    set histScript "0.5*log((1+${Input})/(1-${Input}))"
	}
	default {
	    set exprScript "${operation}(${input})"
	    set histScript "${operation}(${Input})"
	}
    }
    return [list $exprScript $histScript $popTo]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::functionOperation" --
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::functionOperation {operation} {
    
    variable calcMode
    
    if {($calcMode < 3)} {
	if {($operation eq "^") || ($operation eq "%")} {
	    Calc::performOperation "binary" $operation
	    return
	}
	error "Cancelled -- $operation works only in Floating Point mode"
    }
    switch -- $operation {
	"^" {set operation "pow"}
	"%" {set operation "fmod"}
    }
    if {($calcMode == 4)} {
	if {[regexp {^\w+$} $operation]} {
	    elec::Wrap "${operation}(" ",••)••" 0
	} else {
	    typeText -w $w $operation
	}
	return
    }
    set stack [Calc::currentStack]
    # Determine 'input' and 'output' values.
    if {([set Input [Calc::currentInput]] ne "")} {
	# We have input, so operate on the last item in the stack.
	set input [Calc::translateFrom $Input]
	if {![llength $stack]} {
	    set value "0"
	} else {
	    set value [lindex $stack end]
	}
	set Value [Calc::translateTo $value]
	set popTo 1
    } else {
	# We have no input, so operate on the last two items in the stack.
	if {![llength $stack]} {
	    set input "0"
	    set value "0"
	} elseif {([llength $stack] == 1)} {
	    set input "0"
	    set value [lindex $stack end]
	} else {
	    set input [lindex $stack end]
	    set value [lindex $stack end-1]
	}
	set Input [Calc::translateTo $input]
	set Value [Calc::translateTo $value]
	set popTo 2
    }
    append exprScript $operation "(" $value "," $input ")"
    append histScript $operation "(" $Value "," $Input ")"
    return [list $exprScript $histScript $popTo]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Calc::evalExpression" --
 # 
 # Equation Editor mode.  Evaluate the equation.
 # 
 # We require the window to be in front in order to call [ring::clear].
 # 
 # --------------------------------------------------------------------------
 ##

proc Calc::evalExpression {{fromHyperlink 0}} {
    
    global tcl_precision
    
    variable fullPrecision
    
    Calc::requireCalcWindow 1
    
    ring::clear
    set input [Calc::currentInput]
    if {[regexp -nocase -- {(\$v)|(\${v})} $input]} {
	set value [Calc::translateFrom [lindex [Calc::currentStack] 0]]
	if {[string length $value]} {
	    regsub -all -nocase -- {(\$v)|(\${v})} $input $value input
	}
    }
    regsub -all -- {\s+} $input { } input
    set defaultTP $tcl_precision
    set tcl_precision $fullPrecision
    if {[catch {expr "1.0 * $input"} value]} {
	set errorMessage $value
    } else {
        set value [string tolower $value]
    }
    set tcl_precision $defaultTP
    if {[info exists errorMessage]} {
        Calc::errorMessage $errorMessage $fromHyperlink
    }
    Calc::currentStack "clear"
    Calc::currentStack "push" $value
    Calc::currentStack "update"
    Calc::historyItem  $input $value 1
    Calc::currentInput $input 1
    Calc::selectInput
    status::msg "(${input}) == $value"
    return $value
}

return

# ===========================================================================
#
# ◊◊◊◊ ------------ ◊◊◊◊ #
# 
# ◊◊◊◊ Version History ◊◊◊◊ #
# 

# ===========================================================================
# 1.0 released                          last update: 01/09/2006 {02:16:43 PM}
# ===========================================================================

* Code appears stable enough to be a "final" 1.0 release.

# ===========================================================================
# 1.0fc5  released                      last update: 03/16/2005 {03:11:37 PM}
# ===========================================================================

* Calc Mode v 1.0b1
* Put all procedures in the "Calc" namespace.
* [calculator] only creates one window.
* New [Calc::buildMenu] defines the menu.
* Canonical indentation, Tcl formatting.
* "calcMode" is now a variable in the Calc namespace.
* New [Calc::calculatorWindow] procedure.
* Window name is retained as a Calc variable.
* "Calc Menu > Change Mode" offers them in a [listpick] dialog.
* "Calc Menu > Show Mode" renamed to "Display Mode".
* [Calc::show] renamed to [Calc::displayMode].
* Calculator window name saved as a local variable.
* New [Calc::requireCalcWindow] procedure.
* New [Calc::initialize] procedure.
* Calculator window geometry is remembered.
* New [Calc::registerHooks] procedure.
* [Calc::requireCalcWindow] throws an error if test fails.
* New "Calc Menu > Calculator Mode" menu to set the mode.
* Other minor menu improvements, such as the "-m" flag for some submenus.
* Calculator Menu v 1.0b2
* This package is now an [alpha::menu].  (Subject to later change.)
* "Calc" mode no longer exists.  [Calc::calculatorWindow] now opens in
  "Text" mode, using a "calculator" minor mode.
* New "Calculator Menu > Calculator Prefs" menu item.
* Removed obsolete [Calc::dummy] procedure.
* Local "windowName" variable renamed to "calculatorWindow".
* Simplified menu dimming hooks, now just specific to the Calculator window.
* Our "calculator" minor mode now includes "Text" mode features.
* Reorganization of procedures in file (in preparation for bigger changes.)
* [Calc::(get|put)] renamed [Calc::translate(From|To)].
* [Calc::(binop|unaryOp|function)] renamed [Calc::<type>Operation].
* Calculator Menu v 1.0b3
* Major update to the Calculator display window.
* A calculator history section is added to the bottom of the window.
* New [Calc::currentValue] to get/replace the current value in the window.
* New [Calc::getUserInput] to get the user's entry from the window.
* New [Calc::newUserInput] to reset the user's entry from.
* New [Calc::resetWindow] clears the value, input fields and history.
* New [Calc::specialKey] takes care of special operations.
* New [Calc::calculatorHelp] procedure handles opening help window.
* [Calc::(dup|ex|delete|enter)] incorporated into [Calc::specialKey].
* All [a-zA-Z0-9] keys return the cursor to the Input field if necessary.
* All Keypad keys return the cursor to the Input field, else process key.
* All of "Return" "Enter" and "Space" return the cursor to the Input field.
* Better handling of "invalid input" errors in [Calc::<type>Operation].
* Calculator Menu v 1.0b4
* New "Equation Editor" calculator mode uses [expr] to evaluate string.
* Simplified some bindings, relying more on [Calc::specialKey].
* Corrected the "e" input value.
* [Calc::changeBindings] only has to be called during initialization.
* Less ambitious "bind everything under the sun" routine.
* [expr] arguments are colorized.
* Special case bindings for double quote and backslash.
* [Calc::translate(To|From)] do not require a Calculator window.
* Improved formatting of "Equation Editor" results.
* [Calc::menuEnable] pays attention to "Equation Editor" mode.
* New [Calc::evalExpression], minor fixes for ($calcMode == 4).
* More [elec::Wrap] improvements.
* Our "calculator" minor mode no longer includes "Text" mode features.
* Fixed the [help::...] call from [Calc::calculatorHelp].
* Calculator Menu v 1.0b5
* Current Value is now placed on its own line.
* Current Value section now has a "Reset" hyperlink.
* Input field has section heading indicator.
* History section has a separate "Clear" hyperlink.
* Added "varmodes" to minor-mode definition, new "wordBreak" preference.
* New [Calc::selectInput] procedure.
* [Calc::(get|new)UserInput] combined into new [Calc::currentInput] proc.
* In RPN Calculator modes, Return is the same as Space or Enter.
* Separated "activateHook" functions in new [Calc::activateHook] procedure.
* Calc mode preference for "tcl_precision" renamed to "calculatePrecision".
* All ${type}Operation calls routed through [Calc::performOperation], which
  ensures that we use (and then reset) the global "tcl_precision" variable.
* [Calc::unaryOperation] properly operates on User Input if available.
* New [Calc::valuePositions] procedure, preliminary suppport for multiple
  values to be stacked in the Current Value section for RPN calculator.
* [Calc::addHistoryItem] now places values on separate lines if the input
  extends beyond 16 characters when in RPN Calculator modes.
* New "includeHistorySection" preference.
* In RPN modes "Return" and "Space" now push the stack of Current Values.
* In RPN modes "Enter" will reset the stack of Values with current Input.
* In RPN modes "Delete" will pop the stack of Current Values.
* [Calc::binaryOperation] and [Calc::functionOperation] will now act on the
  last two items in the stack of Current Values if there is nothing in the User
  Input field, otherwise the input and the last item in the stack.
* [Calc::unaryOperation] will now act on the last item in the stack of
  Current Values if there is nothing in the User Input field.
* Calc mode preference for "displayPrec" renamed to "displayPrecision".
* Calculator Menu v 1.0b6
* New "Include Visual Keypad" option for the Calculator Window.
* Toggleable preferences can be changed in the "Calculator Mode" menu.
* New [Calc::updatePreferences] can be used as a [newPref] tracing proc.
* Colorizing takes place in [Calc::colorizeCalc].
* [Calc::selectInput] ensures that the top of the window is visible.
* Visual Keypad and Functions split into two different preferences.
* Renamed those preferences "Hyperlinks" rather than "Visual".
* New [Calc::rebuildWindow] restores value, input, history.
* New [Calc::errorMessage] delivers hyperlink errors in an alertnote.
* Calculator Menu v 1.0b7
* Reorganization of procedures in file (in preparation for bigger changes.)
* [Calc::resetWindow] renamed [Calc::buildWindow].
* [Calc::rebuildWindow] renamed [Calc::clearWindow].
* [Calc::addHistoryItem] renamed [Calc::historyItem].
* Return now pushes the stack just like Space and Enter for RPN modes.
* [Calc::currentValue] can accept/return stack in list format.
* New [Calc::sectionHyperlink] handles clearing of fields.
* Input field can be cleared ; Stack/Value field can be cleared without
  resetting the entire window.
* [Calc::clearHistory] incorporated into [Calc::clearWindow].
* Error messages recorded in History section.
* More hook adjustments.
* [Calc::requireCalcWindow] doesn't require the Calculator to be the active
  window, but can optionally bring it to the front.
* New [Calc::setFillColumn] determines proper fillColumn length for window.
* User preferences for Calculator window font, font-size.
* New [Calc::modePrefsDialog] gives us greater control over presentation.
* New [Calc::pasteInput] handles multi-line Clipboard contents, adding all
  but the last line to the current stack.
* [::cut] is restricted to the contents of the Input field.
* Other common "delete-text" bindings (Control-D, Control-K, Delete keys)
  are restricted to the contents of the Input field.
* [Calc::(value|input)Positions] combined into [Calc::fieldPositions].
* The calculator will adopt the mode of the active (if any) window -- this
  eases some of the mode-changing overhead associated with switching windows.
* Calculator Menu v 1.0fc1
* Many thanks to Dominique for beta-testing and suggestions.
* Tab selects the Current Input field if the cursor is outside it.
* Minor [Calc::buildWindow] formatting fix.  (This update is nearly done.)
* Calculator v 1.0fc2
* This package is now an "always-on" [alpha::feature].
* Since the "calculatorMenu" is no longer a potential global feature, we have
  fewer hooks to register or call.
* Reverted to always using "Text" as the major mode.
* Using standard font(size) pref names, assuming they'll be used when new
  windows are created without being directly supplied with [new].
* "Calculator > Insert Minus" now does what it advertises.
* Calculator v 1.0fc3
* 64-bit integer support, i.e. {%ld} instead of {%d} during translation.
* History properly translates inputs and values.
* [Calc::changeBindings] [catch] commands are lists (since they're [eval]ed.)
* Better bindings (hopefully) for "International Users", esp dead-keys.
* Calculator v 1.0fc4
* New [Calc::currentStack] maintains a stack list that is separated from the
  values listed for display, allowing for better calculation precisions.
* History section now contains full tcl_precision values for operations.
* Proper translation and storage of stack values.
* Calculator v 1.0b9 (too many recent changes to justify "fc" status.)
* More binding simplifications, everything routed through [Calc::specialKey].
* More minor patches provided by Dominique.
* "Calculator > Insert Minus" is disabled for "Unsigned" modes.
* [Calc::performOperation] handles pushing stack, history, errors.
* New "Scientific Notation" display preference.
* [Calc::binaryOperation] uses "wide($value)" in its [expr] arguments.
* Finally removed [Bind 0x31] to avoid dead-key issue.
* Better preservation of previous values in [Calc::currentStack "update"].
* Scientific Notation in Stack/Value can be toggled with <SN> hyperlink.
* "calculatePrecision" pref removed, we always use full (16) precision.
* Last "stackValues" are displayed when window is closed then reopened.
* Last "input" value is displayed when the window is closed, reopened.
* New "saveHistoryCache" pref to display old history with new Calculator.
* Better regexp patterns in [Calc::translateFrom], allowing "+".
* Reversed "value" "input" stack value selection in [Calc::binaryOperation].
* Better setting, searching for "divider" string.
* WORKAROUND for bug# 1783 in [Calc::setFillColumn].
* Calculator v 1.0fc5
* [Calc::currentValue] is obsolete, replaced by [Calc::currentStack].
* [Calc::evalExpression] won't round off values to integers.
* Calculation/translation procedures use "16" for full "tcl_precision".
* Fix from Dominique for stack value manipulations in [Calc::currentStack].
* Divider line is only 80 characters long (again).
* Unmodified Arrow Key operations confined to the Input field.
* New "Calculator > Value|Stack To Clipboard" menu item.
* "-exact" flag added to all relevant [lsearch] calls.
* User can over-ride "fullPrecision == 16" if desired.

# ===========================================================================
# 0.1.7 released
# ===========================================================================

* Various updates througout the years.

# ===========================================================================
# 0.1 released
# ===========================================================================

* Original.

# ===========================================================================
#
# .