## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "colorsMenu.tcl"
 #                                          created: 08/13/1995 {08:24:33 PM}
 #                                      last update: 02/28/2006 {03:32:12 PM}
 # Description:
 # 
 # Color menu and support routines.  Note that while we also have colors 9-15
 # (color_9 etc) as well as background/foreground available, these can NOT be
 # used with text::color, so we make no attempt to include them in any of the
 # menus or procedures.  All colors 8-15 in this file refer instead to styles
 # (outline, normal, etc.)
 # 
 # Other AlphaTcl packages can call any of these procedures, but note that
 # this is not a 'core' package and might be uninstalled by the user.
 # 
 # Procedures in the "Color/Styles Conversions" and "Color Utilities"
 # sections could possibly be included in the core file "colors.tcl" so that
 # they would be available to code in other packages even if this one has
 # been uninstalled.  These include colorize/stylizeRegion procedures, as
 # well as color/style index conversion routines.  (If this is adopted,
 # please remove this comment.)
 # 
 # Original by Pete Keheler?
 # 
 # Includes contributions from Vince Darley, Craig Barton Upright.
 # 
 # Copyright (c) 1995-2006 Pete Keheler, Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::menu colorMenu 1.2.3 global "•137" {
    # Initialization script.
    # Source this file.
    colorMenu.tcl
    # Define and then build the Color menu.
    menu::buildProc colorMenu {colors::buildColorsMenu}
    menu::buildSome colorMenu
    # Add a pane to the Config preferences dialog.
    package::addPrefsDialog ColorMenu
    hook::register   requireOpenWindowsHook [list $colorMenu ""] 1
} {
    # Activation script.
} {
    # Deactivation script.
} preinit {
    # Includes items to create hyperlinks (i.e. for urls and e-mails) in the
    # active window
    newPref flag "createHyperlinkMenu" 0 contextualMenu
    menu::buildProc "createHyperlink" {colors::buildHyperlinkCMenu}
    # Includes items to colorize text strings in the active window
    newPref flag "colorStyleTextMenu" 0 contextualMenu
    menu::buildProc "colorStyleText" {colors::buildColorStyleCMenu} \
      {colors::postBuildCMColorStyle}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-file
} description {
    Provides functions to add colors and hyperlinks to Alpha files
} help {
    This menu helps with the manual application of colors and hyperlinks to
    Alpha files.  The "Color Menu > Window Colors > Colorize Patterns" menu
    item allows you to perform a global search-and-color for specified words
    or regular expressions in the current window.  Additional submenus provide
    options for colorizing/stylizing/marking the currently selected region, or
    to add hyperlinks for Alpha/Tcl commands, urls, or e-mails.
    
    Preferences: Menus

    Most menu items can be assigned personalized keyboard shortcuts by
    selecting "Color Menu > Color Options > Assign Menu Bindings".

    IMPORTANT: If you create colors/hypers in a window, you MUST set the
    saved state of the file to "MPW" in order for them to be 'remembered'
    when you save/close the window.  Use the 'Format' popup menu in the
    status bar window to change this setting.  The preferences: Window dialog
    includes a preferences for the default saved state for all files.

    As of this writing, if you're using the Windos OS no colors will ever be
    saved no matter what you do, so this package will be of little use beyond
    creating some temporary highlights in a window.
    
    As of this writing, attempting to color text "manually" using this menu
    interferes with syntax coloring in Alpha8 and AlphaX. This is a known
    issue, there is no timetable for fixing this.

    Select "Color Menu > Color Options > Color Menu Prefs" to set the default
    colors used for creating hypertext links.  Note that the "Redefine Colors"
    menu item allows you to change the color settings used by Alpha/tk in all
    of its colorized windows, although some changes might not take full effect
    until to restart the application.  See help for the package: colorPrefs
    for more information about changing Alpha's colors.
    
    This package also creates two contextual menu submenu modules that are
    available even if this package has not been turned on globally -- they are
    named "Create Hyperlink" and "Color Style Text".
    
    Preferences: ContextualMenu

    While any colors set using this menu will not be recognized if you
    subsequently open the document any application other than Alpha/tk, they
    might be retained if sent to a color printer.  (You'll have to experiment
    to find out if your Alpha 8/X/tk application supports this feature, it
    has been reported as a 'Request For Enhancement in Bug# 324.)

	Developers Note

    This menu used to be used extensively to create marks, colors and
    hyperlinks in AlphaTcl's Help file documents (such as this window).

    AlphaTcl v 7.4 and above now uses automatic marking/coloring/hyperising
    to properly format these files and windows, see the "Help Files Help"
    file for more information.  Note that files committed to the AlphaTcl cvs
    never include the resource fork of the original file, so if that is your
    document's final destination you probably shouldn't spend a whole lot of
    time creating marks/colors/hyperlinks manually using this menu.
    
    The "Color Menu > Window Colors > Mimic Help Menu" menu command, however,
    is very useful for 'debugging' window marks/colors/hypers etc.  to see how
    the window will be marked when the user opens it the first time.  (The
    "AlphaDev > Help File Marking > Mimic Help Menu" item is identical, both
    calling [help::mimicHelpMenu], and is included here more for convenience
    than anything else, although it might be useful for users who have messed
    up colors in their help file windows.
}

proc colorMenu     {} {}
proc colorMenu.tcl {} {}

namespace eval colors {
    
    # Default bindings for the Colors menu.
    variable DefaultColorMenuBindings
    array set DefaultColorMenuBindings {
	blueWord            /g
	blueMark            <I/g
	greenWord           /h
	greenMark           <I/h
	redWord             /f
	redMark             <I/f
	linkToMark…         <B/k
	linkToMarkInFile…   <I<B/k
    }
}

# ◊◊◊◊ Preferences ◊◊◊◊ #

# To always underline marks when using 'Mark Text' menu items, turn this
# item on||to never underline marks when using 'Mark Text' menu items, turn
# this item off
newPref flag underlineMarks    0 ColorMenu
# To use bindings in the 'Color' menu, turn this item on||To never include
# bindings in the 'Color' menu, turn this item off
newPref flag useBindingsInMenu 0 ColorMenu {colors::rebuildColorsMenu}

# The color to use for e-mail hyperlinks.
newPref color emailLinkColor "green"   ColorMenu
# The color to use for file hyperlinks.
newPref color fileLinkColor  "green"   ColorMenu
# The color to use for hypertext hyperlinks.
newPref color hypertextColor "magenta" ColorMenu
# The color to use for section mark hyperlinks.
newPref color markLinkColor  "green"   ColorMenu
# The color to use for url hyperlinks.
newPref color urlLinkColor   "green"   ColorMenu

# ===========================================================================
#
# ◊◊◊◊ -------- ◊◊◊◊ #
#
# ◊◊◊◊ Colors Menu, support ◊◊◊◊ #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::buildColorsMenu"  --
 # 
 # Create the Color Menu (menu name •127).
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::buildColorsMenu {} {
    
    global ColorMenumodeVars colorMenu

    variable Colors
    variable ColorsMenuItems
    variable DefaultColorMenuBindings
    variable Styles
    variable UserColorMenuBindings
    
    # Create the lists of menu items.
    if {![info exists ColorsMenuItems(Colors)]} {
        set ColorsMenuItems(Colors) $Colors
    }
    if {![info exists ColorsMenuItems(Styles)]} {
	set ColorsMenuItems(Styles) $Styles
    }
    if {![info exists ColorsMenuItems(Hyperlinks)]} {
	set ColorsMenuItems(Hyperlinks) [list \
	  hyperText… urlLink… emailLink… (-) \
	  hyperlinkAllUrls hyperlinkAllEmails (-) \
	  linkToFile… linkToMark… linkToMarkInFile… ]
    }
    if {![info exists ColorsMenuItems(Marks)]} {
	set ColorsMenuItems(Marks) [concat $Colors "(-)" $Styles]
    }
    if {![info exists "ColorsMenuItems(Window Marks)"]} {
	set "ColorsMenuItems(Window Marks)" [list \
	  colorAllMarks… insertTableOfContents displayWindowMarks]
    }
    if {![info exists "ColorsMenuItems(Window Colors)"]} {
	set "ColorsMenuItems(Window Colors)" [list \
	  colorizePatterns… removeAllColors displayWindowColors (-) \
	  mimicHelpMenu]
    }
    if {$ColorMenumodeVars(useBindingsInMenu)} {
	set pre "dis"
    } else {
	set pre "en"
    }
    set ColorsMenuItems(Options) [list \
      assignMenuBindings… restoreDefaultBindings ${pre}ableBindings (-) \
      redefineColors… colorMenuPrefs… colorMenuHelp]
    # Create the lists of menu items with bindings.
    foreach menuType [array names ColorsMenuItems] {
	switch -- $menuType {
	    "Colors"  {set itemTail "Word"}
	    "Styles"  {set itemTail "Word"}
	    "Marks"   {set itemTail "Mark"}
	    default   {set itemTail ""}
	}
	foreach item $ColorsMenuItems($menuType) {
	    if {!$ColorMenumodeVars(useBindingsInMenu)} {
	        set binding ""
	    } elseif {[info exists UserColorMenuBindings(${item}${itemTail})]} {
		set binding $UserColorMenuBindings(${item}${itemTail})
	    } elseif {[info exists DefaultColorMenuBindings(${item}${itemTail})]} {
		set binding [set DefaultColorMenuBindings(${item}${itemTail})]
	    } else {
		set binding ""
	    }
	    regsub " " $menuType "" menuType
	    lappend ${menuType}Items ${binding}${item}
	}
    }
    # Create the menu list.
    set menuList [list \
      [list Menu -n colorizeText    -p colors::colorsMenuProc $ColorsItems] \
      [list Menu -n stylizeText     -p colors::colorsMenuProc $StylesItems] \
      [list Menu -n hyperlinkText   -p colors::colorsMenuProc $HyperlinksItems] \
      "(-)" \
      [list Menu -n markText        -p colors::colorsMenuProc $MarksItems] \
      [list Menu -n windowMarks     -p colors::colorsMenuProc $WindowMarksItems] \
      [list Menu -n windowColors    -p colors::colorsMenuProc $WindowColorsItems] \
      "(-)" \
      [list Menu -n colorOptions    -p colors::colorsMenuProc $OptionsItems] \
      ]
    return [list build $menuList {colors::colorsMenuProc} {} $colorMenu]
}

proc colors::buildHyperlinkCMenu {} {
    
    global alpha::CMArgs
    
    variable ColorsMenuItems
    
    if {![info exists ColorsMenuItems(CreateHyperlinks)]} {
        set ColorsMenuItems(CreateHyperlinks) [list \
	  urlLink… emailLink… hyperText… (-) \
	  linkToFile… linkToMark… linkToMarkInFile… (-) \
	  hyperlinkAllUrls hyperlinkAllEmails ]
    }
    set pp $alpha::CMArgs
    # Adjust the menu based on selection surrounding click position.
    if {[pos::compare [lindex $pp 1] == [lindex $pp 2]]} {
        set menuList [lrange $ColorsMenuItems(CreateHyperlinks) 8 end]
    } else {
        set menuList $ColorsMenuItems(CreateHyperlinks)
    }
    return [list build $menuList {colors::colorsMenuProc}]
}

proc colors::buildColorStyleCMenu {} {
    
    variable ColorsMenuItems
    
    if {![info exists ColorsMenuItems(ColorStyleText)]} {
        variable Colors
	variable Styles
	set ColorsMenuItems(ColorStyleText) [concat [list "None" (-)] \
	  [lrange $Colors 1 end] (-) [lrange $Styles 1 end]]
    }
    set menuList $ColorsMenuItems(ColorStyleText)
    return [list build $menuList {colors::colorsMenuProc}]
}

proc colors::postBuildCMColorStyle {} {
    
    global alpha::CMArgs
    
    set pp $alpha::CMArgs
    # Adjust the menu based on selection surrounding click position.
    if {[pos::compare [lindex $pp 1] != [lindex $pp 2]]} {
	return
    }
    # The weird "côñtéxtüålMenu" name should be saved somewhere ...
    enableMenuItem "côñtéxtüålMenu" colorStyleText 0
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::rebuildColorsMenu"  --
 # 
 # Rebuild the Color Menu (menu name •127).
 # 
 # 'args' determines if this occurs 'silently' -- an arg of 'hardRebuild' is
 # a developer too, and unsets any previously remembered menu item names, as
 # in [colors::rebuildColorsMenu hardRebuild].
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::rebuildColorsMenu {args} {

    if {([lindex $args 0] == "hardRebuild")} {
        # This is a developer tool.
	variable ColorsMenuItems
	unset -nocomplain ColorsMenuItems
    }
    menu::buildSome colorMenu
    if {[llength $args]} {
	status::msg "The Color menu has been rebuilt."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::colorsMenuProc"  --
 # 
 # All menu items are routed through this procedure.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::colorsMenuProc {menuName itemName args} {
    
    global ColorMenumodeVars
    
    switch -- $menuName {
	"colorizeText" - "stylizeText" - "colorStyleText" - "markText" {
	    if {($itemName == "colorAllMarks")} {
	        colors::colorAllMarks
		return
	    }
	    eval getPositions $args
	    if {($menuName == "markText")} {
		set txt [prompt "Mark Name:" [getSelect]]
		setNamedMark $txt [lineStart $pos0] $pos0 $pos1
		if {$ColorMenumodeVars(underlineMarks)} {
		    underlineRegion $pos0 $pos1
		}
	    }
	    ${itemName}Region $pos0 $pos1
	    switch -- $menuName {
		"colorizeText"   {set msg "been colored as"}
		"stylizeText"    {set msg "been stylized as"}
		"colorStyleText" {set msg "been colored/styled as"}
		"markText"       {set msg "turned into a mark with color/style"}
	    }
	    status::msg "The selected text has been $msg '$itemName'."
	}
	"hyperlinkText" - "createHyperlink" {
	    switch -- $itemName {
		"hyperText"          {set itemName "linkHypertext"}
		"urlLink"            {set itemName "linkUrl"}
		"emailLink"          {set itemName "linkEmail"}
		"hyperlinkAllUrls"   {set itemName "linkAllUrls"}
		"hyperlinkAllEmails" {set itemName "linkAllEmails"}
	    }
	    eval ${itemName} $args
	    if {([string index $itemName end] == "s")} {
		status::msg "The hypertext links have been added."
	    } else {
		status::msg "The hypertext link has been added."
	    }
	}
	"colorOptions" {
	    switch -- $itemName {
		"assignMenuBindings" {
		    if {!$ColorMenumodeVars(useBindingsInMenu)} {
		        set ColorMenumodeVars(useBindingsInMenu) 1
			prefs::modified ColorMenumodeVars(useBindingsInMenu)
		    }
		    colors::colorMenuBindings
		}
		"restoreDefaultBindings" {
		    if {!$ColorMenumodeVars(useBindingsInMenu)} {
			set ColorMenumodeVars(useBindingsInMenu) 1
			prefs::modified ColorMenumodeVars(useBindingsInMenu)
		    }
		    unset -nocomplain UserColorMenuBindings
		    colors::rebuildColorsMenu 1
		}
		"disableBindings" - "enableBindings" {
		    set value $ColorMenumodeVars(useBindingsInMenu)
		    set ColorMenumodeVars(useBindingsInMenu) [expr {1 - $value}]
		    prefs::modified ColorMenumodeVars(useBindingsInMenu)
		    colors::rebuildColorsMenu 1
		    return
		}
		"colorMenuPrefs" {
		    prefs::dialogs::packagePrefs "ColorMenu"
		}
		"colorMenuHelp" {
		    package::helpWindow "colorMenu"
		}
		default {eval $itemName $args}
	    }
	}
	default {
	    switch -- $itemName {
		"insertTableOfContents" {colors::createTOC}
		"mimicHelpMenu"         {help::mimicHelpMenu}
		"removeAllColors" {
		    # The last time I checked, Alphatk does not properly
		    # remove colors with this core command.
		    catch {removeColorEscapes} ; refresh
		    status::msg "All colors in the current window have been removed."
		}
		default {eval $itemName $args}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::colorizePatterns"  --
 # 
 # Colorize patterns (possibly regexp) in the current window.  If called in
 # Alphatk or if window state is _note_ MPW, the highlights are temporary.
 # All pattern arguments are remembered between editing sessions.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::colorizePatterns {} {

    variable Colors
    variable LastColorArgs
    variable Styles

    # Create a dialog that offers three fields for entering text or a
    # regexp pattern, plus color and style pop-up menus.
    if {![info exists LastColorArgs]} {
	set LastColorArgs [list \
	  "" 0 none normal "" 0 none normal "" 0 none normal]
    }
    set count 0
    foreach num [list 1 2 3] {foreach type [list txt reg col sty] {
	set ${type}${num} [lindex $LastColorArgs $count]
	incr count
    }}
    set dummy  ""
    set d1 {dialog::make -title "Colorize Patterns" }
    set d2 [list "Colorize patterns"]
    foreach num [list 1 2 3] {
	lappend d2 [list text "_________________________________________\r"]
	lappend d2 [list var "Pattern ${num}:"               [set txt${num}]]
	lappend d2 [list flag "Regexp pattern $dummy"        [set reg${num}]]
	lappend d2 [list [list menu $Colors] "Color ${num}:" [set col${num}]]
	lappend d2 [list [list menu $Styles] "Style ${num}:" [set sty${num}]]
	append dummy " "
    }
    # Now present the dialog, and save any new values.
    status::msg "Note that all patterns are case-insensitive."
    lappend d1 $d2
    set result [eval $d1]
    set LastColorArgs $result
    prefs::modified LastColorArgs
    set count  0
    foreach num [list 1 2 3] {foreach type [list txt reg col sty] {
	set ${type}${num} [lindex $result $count]
	incr count
    }}
    watchCursor
    status::msg "Searching, coloring the window…"
    foreach num [list 1 2 3] {
	if {![string length [set txt [set txt${num}]]]} {
	    continue
	}
	set color [colors::convertColorStyle [set col${num}]]
	set style [colors::convertColorStyle [set sty${num}]]
	win::searchAndHyperise $txt {} [set reg${num}] $color
	win::searchAndHyperise $txt {} [set reg${num}] $style
    }
    refresh
    status::msg "Searching, coloring the window… complete."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::colorAllMarks"  --
 # 
 # Colorize all window marks and/or title in the current window.  If called
 # in Alphatk or if window state is _note_ MPW, the highlights are temporary.
 # All colorizing arguments are remembered between editing sessions.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::colorAllMarks {} {
    

    variable Colors
    variable LastMarkColorArgs
    variable Styles

    if {![llength [set mark [getNamedMarks]]]} {
        status::msg "There are no marks to colour."
	return
    }
    # Create a dialog that offers three fields for entering text or a
    # regexp pattern, plus color and style pop-up menus.
    if {![info exists LastMarkColorArgs]} {
	set LastMarkColorArgs [list 1 none normal 0 none normal]
    }
    set doMarks [lindex $LastMarkColorArgs 0]
    set color1  [lindex $LastMarkColorArgs 1]
    set style1  [lindex $LastMarkColorArgs 2]
    set doTitle [lindex $LastMarkColorArgs 3]
    set color2  [lindex $LastMarkColorArgs 4]
    set style2  [lindex $LastMarkColorArgs 5]
    set d1 {dialog::make -title "Color All Marks" }
    set d2 [list "Color Marks/Title"]
    lappend d2 [list text "_________________________________________\r"]
    lappend d2 [list flag "Color Marks?   (Includes all current marks.)" $doMarks]
    lappend d2 [list [list menu $Colors] "Color:" $color1]
    lappend d2 [list [list menu $Styles] "Style:" $style1]
    lappend d2 [list text "_________________________________________\r"]
    lappend d2 [list flag "Color Title?   (First alpha-numeric line.)" $doTitle]
    lappend d2 [list [list menu $Colors] "Color: " $color2]
    lappend d2 [list [list menu $Styles] "Style: " $style2]
    # Now present the dialog, and save any new values.
    lappend d1 $d2
    set result [eval $d1]
    set LastMarkColorArgs $result
    prefs::modified LastMarkColorArgs
    watchCursor
    status::msg "Coloring marks/title…"
    # Color all marks.
    if {[lindex $result 0]} {
	set color1 [lindex $result 1]
	set style1 [lindex $result 2]
	foreach mark [getNamedMarks] {
	    if {([set name [string trim [lindex $mark 0]]] == "-")} {
		continue
	    }
	    set pos [lindex $mark 2]
	    if {[llength [set match [search -n -s -f 1 -r 0 -- $name $pos]]]} {
		set pos0 [lindex $match 0]
		set pos1 [lindex $match 1]
		text::color $pos0 $pos1 $color1
		text::color $pos0 $pos1 $style1
	    }
	}
    }
    # Color title.
    if {[lindex $result 3]} {
	set color2 [lindex $result 4]
	set style2 [lindex $result 5]
	set pos    [minPos]
	set pat    {[a-zA-Z0-9]}
	while {1} {
	    set match [search -n -s -f 1 -r 1 -- $pat $pos]
	    if {![llength $match]} {
		break
	    }
	    set pos0 [lindex $match 0]
	    set pos1 [pos::math [nextLineStart $pos0] - 1]
	    if {[regexp {[-a-zA-Z0-9+]+-\*-} [getText $pos0 $pos1]]} {
		set pos [nextLineStart $pos0]
		continue
	    } else {
		text::color $pos0 $pos1 $color2
		text::color $pos0 $pos1 $style2
		break
	    }
	}
    }
    refresh
    status::msg "Coloring marks/title… complete."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::displayWindowColors"  --
 # 
 # Create a new window displaying all color coding information.
 # 
 # The formatting might need to be modified to deal with Alphatk positions.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::displayWindowColors {} {

    global mode

    # Make sure that we have an open window with named marks.
    requireOpenWindow
    if {![llength [set colors [getColors]]]} {
	status::msg "No color codes found in this window."
	return
    }
    set res "Color codes for '[win::CurrentTail]':\r\r"
    append res "Pos     Code   Hypertext\r"
    append res "------- -----  ---------\r\r"
    foreach item $colors {
	set off  [lindex $item 0]
	set code [lindex $item 1]
	if {[string length [set cmd [lreplace $item 0 1]]]} {
	    append res [format "%7d  %3d  %s\n" $off $code $cmd]
	} else {
	    append res [format "%7d  %3d\n" $off $code]
	}
    }
    new -n "* Color Codes *" -m $mode -info $res
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::displayWindowMarks"  --
 # 
 # Create a new window displaying all mark text/position information.
 # 
 # This probably belongs in "marks.tcl", and the formatting might need to be
 # modified to deal with Alphatk positions.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::displayWindowMarks {} {

    global mode

    # Make sure that we have an open window with named marks.
    requireOpenWindow
    if {![llength [getNamedMarks]]} {
	status::msg "No marks found in the current window."
	return
    }
    # Create a new window displaying mark name/position information.
    set res "Named marks for '[win::CurrentTail]':\r\r"
    append res "Pos     Disp    End      Name\r"
    append res "------- ------- -------  --------------------\r\r"
    foreach mark [getNamedMarks] {
	set name [lindex $mark 0]
	set disp [lindex $mark 2]
	set pos  [lindex $mark 3]
	set end  [lindex $mark 4]
	append res [format "%7d %7d %7d  %s\r" $pos $disp $end $name]
    }
    new -n "* Named Marks *" -m $mode -info $res
    return
}

# ◊◊◊◊ Colors Menu Options ◊◊◊◊ #

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::colorMenuBindings"  --
 # 
 # Assign/remove bindings in the Color menu.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::colorMenuBindings {{title "Select a menu:"} {includeFinish "0"}} {

    variable DefaultColorMenuBindings
    variable ColorsMenuItems
    variable UserColorMenuBindings

    if {$includeFinish} {
	set menus "Finish"
    }
    eval lappend menus [lsort -dictionary [array names ColorsMenuItems]]
    if {[set menuName [listpick -p $title $menus]] == "Finish"} {
	return
    }
    foreach menuItem $ColorsMenuItems($menuName) {
	if {($menuItem == "(-)")} {
	    continue
	}
	switch -- $menuName {
	    "Colors" {append menuItem "Word"}
	    "Styles" {append menuItem "Word"}
	    "Marks"  {append menuItem "Mark"}
	}
	if {[info exists UserColorMenuBindings($menuItem)]} {
	    set colorsBindings($menuItem) $UserColorMenuBindings($menuItem)
	} elseif {[info exists DefaultColorMenuBindings($menuItem)]} {
	    set colorsBindings($menuItem) $DefaultColorMenuBindings($menuItem)
	} else {
	    set colorsBindings($menuItem) ""
	}
    }
    set title "'$menuName'  key bindings …"
    catch {dialog::arrayBindings $title colorsBindings 1}

    foreach menuItem $ColorsMenuItems($menuName) {
	switch -- $menuName {
	    "Colors" {append menuItem "Word"}
	    "Styles" {append menuItem "Word"}
	    "Marks"  {append menuItem "Mark"}
	}
	if {[info exists colorsBindings($menuItem)]} {
	    set newBinding $colorsBindings($menuItem)
	    # Check to see if this is different from the default.
	    if {[info exists DefaultColorMenuBindings($menuItem)]} {
		set defaultBinding $DefaultColorMenuBindings($menuItem)
	    } else {
		set defaultBinding ""
	    }
	    if {($newBinding == "") \
	      && [info exists UserColorMenuBindings($menuItem)]} {
		unset UserColorMenuBindings($menuItem)
	    } elseif {($newBinding != $defaultBinding)} {
		set UserColorMenuBindings($menuItem) $newBinding
	    }
	} elseif {[info exists UserColorMenuBindings($menuItem)]} {
	    unset UserColorMenuBindings($menuItem)
	}
    }
    prefs::modified UserColorMenuBindings
    colors::rebuildColorsMenu 1
    # Now offer the list pick again.
    colors::colorMenuBindings "Select another menu, or 'Finish':" 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::redefineColors"  --
 # 
 # Change the default color definitions for Alpha*.  This simply redirects to
 # the "Config > Redefine Colors" menu -- included here because users using
 # this menu might not realize that they can change the colors, and it really
 # isn't so out of place to allow them to do so via this menu.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::redefineColors {args} {

    if {[llength $args]} {
	set color [lindex $args 0]
    } else {
	set color "blue"
    }
    set allColors {
	foreground background blue cyan green magenta red white
	yellow color_9 color_10 color_11 color_12 color_13
	color_14 color_15
    }
    set p "Choose a color to redefine:"
    set color [listpick -p $p -L $color $allColors]
    menuProc "" $color
    if {[askyesno "Would you like to redefine another color?"]} {
	colors::redefineColors $color
    }
    status::msg "Some changes may not take effect until you quit and restart."
    return
}

# ◊◊◊◊ Hyperlink procs ◊◊◊◊ #

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkHypertext"  --
 # 
 # Create a hypertext link for the current selected text.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # Can be called from other code -- any default hypertext will bypass the
 # dialog, and any optional position args (must come as a pair) will be
 # used instead of current selection.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkHypertext {{hypertext ""} args} {
    
    global ColorMenumodeVars

    variable LastHyper

    eval getPositions $args
    set  color [colors::convertColorStyle $ColorMenumodeVars(hypertextColor)]
    # Make sure that we have some hypertext.
    if {![string length $hypertext]} {
	if {![info exists LastHyper]} {
	    set hypertext ""
	} else {
	    set hypertext $LastHyper
	}
	set hypertext [prompt "Hyper-text?" $hypertext]
    }
    text::color $pos0 $pos1 $color
    text::hyper $pos0 $pos1 [set LastHyper $hypertext]
    refresh
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkUrl"  --
 # 
 # Create a url hypertext link for the current selected text.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # Can be called from other code -- any default url will bypass the dialog,
 # and any optional position args (must come as a pair) will be used instead
 # of current selection.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkUrl {{url ""} args} {

    global ColorMenumodeVars

    eval getPositions $args
    set  color [colors::convertColorStyle $ColorMenumodeVars(urlLinkColor)]
    # Make sure that we have a url.
    if {![string length $url]} {
	set url [string trim [getSelect]]
	set url [string trimright $url ">"]
	set url [string trimleft  $url "<"]
	set url [string trim $url]
	set p "Please type your url, or use one of the buttons below:"
	set url [dialog::getUrl $p $url]
    }
    set cmd "urlView \"$url\""
    text::color $pos0 $pos1 $color
    text::hyper $pos0 $pos1 $cmd
    refresh
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkEmail"  --
 # 
 # Create an email link for the current selected text.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # Can be called from other code -- any default email will bypass the dialog,
 # and any optional position args (must come as a pair) will be used instead
 # of current selection.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkEmail {{email ""} args} {

    global ColorMenumodeVars

    eval getPositions $args
    set  color [colors::convertColorStyle $ColorMenumodeVars(emailLinkColor)]
    # Make sure that we have a email address.
    if {![string length $email]} {
	set email [string trim [getSelect]]
	set email [string trimright $email ">"]
	set email [string trimleft  $email "<"]
	regsub "^ *mailto:" [string trim $email] "" email
	set p "Please type an email address:"
	set email [prompt $p "$email"]
    }
    regsub "^ *mailto:" [string trim $email] "" email
    set cmd "composeEmail \"mailto:$email\""
    text::color $pos0 $pos1 $color
    text::hyper $pos0 $pos1 $cmd
    refresh
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkAllUrls"  --
 # 
 # Create hypertext links for all urls in the current window.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkAllUrls {} {

    global ColorMenumodeVars

   set  color [colors::convertColorStyle $ColorMenumodeVars(urlLinkColor)]
    watchCursor
    status::msg "Colouring and hyperising all url strings…"
    set pattern {<?((https?|news|mailto|ftp|afp|smb):[^ >]*)>?}
    set script  {urlView "\1"}
    win::searchAndHyperise $pattern $script 1 $color
    refresh
    status::msg "Colouring and hyperising all url strings… complete."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkAllEmails"  --
 # 
 # Create hypertext links for all emails in the current window.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkAllEmails {} {

    global ColorMenumodeVars

    set  color [colors::convertColorStyle $ColorMenumodeVars(emailLinkColor)]
    watchCursor
    status::msg "Colouring and hyperising all url strings…"
    set pattern {<?([-_a-zA-Z0-9.]+@([-_a-zA-Z0-9.]+))>?}
    set script  {composeEmail "mailto:\1"}
    win::searchAndHyperise $pattern $script 1 $color
    refresh
    status::msg "Colouring and hyperising all url strings… complete."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkToFile"  --
 # 
 # Create an "open file" hyperlink for the current selected text.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # Can be called from other code -- any default path will bypass the dialog,
 # and any optional position args (must come as a pair) will be used instead
 # of current selection.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkToFile {{path ""} args} {

    global ColorMenumodeVars HOME

    eval getPositions $args
    set  color [colors::convertColorStyle $ColorMenumodeVars(fileLinkColor)]
    # Make sure that we have a path.
    if {![string length $path]} {
	set path [getfile "Choose target of hyperlink:"]
    }
    set path [file nativename $path]
    # Make path relative to Alpha's home folder
    if {[file::pathStartsWith $path $HOME relative]} {
	set cmd "edit -r -c \[file join \$HOME [quote::Insert $relative]\]"
    }
    if {![info exists cmd]} {
	set cmd [list edit -r -c $path]
    }
    text::color $pos0 $pos1 $color
    text::hyper $pos0 $pos1 $cmd
    refresh
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkToMark"  --
 # 
 # Create a "go to mark" hyperlink for the current selected text.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # Can be called from other code -- any default mark will bypass the dialog,
 # and any optional position args (must come as a pair) will be used instead
 # of current selection.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkToMark {{mark ""} args} {

    eval getPositions $args
    set  color [colors::convertColorStyle $ColorMenumodeVars(markLinkColor)]
    # Make sure that we have a mark.
    if {![string length $mark]} {
	set p "Choose a mark in this window:"
	set mark [listpick -p $p [getNamedMarks -n]]
    }
    set cmd "gotoMark \"$mark\""
    text::color $pos0 $pos1 $color
    text::hyper $pos0 $pos1 $cmd
    refresh
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::linkToMarkInFile"  --
 # 
 # Create an "open file, go to mark" hyperlink for the current selected text.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # Can be called from other code -- any default path/mark will bypass the
 # dialog, and any optional position args (must come as a pair) will be used
 # instead of current selection.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::linkToMarkInFile {{path ""} {mark ""} args} {

    global ColorMenumodeVars HOME

    eval getPositions $args
    set  color [colors::convertColorStyle $ColorMenumodeVars(markLinkColor)]
    # Make sure that we have a path.
    if {![string length $path]} {
	set path [getfile "Choose a file:"]
    }
    set path [file nativename $path]
    # Make path relative to Alpha's home folder
    if {[file::pathStartsWith $path $HOME relative]} {
	set cmd "edit -r -c \[file join \$HOME [quote::Insert $relative]\]"
    }
    if {![info exists cmd]} {
	set cmd "edit -r -c \"[quote::Insert $path]\""
    }
    set current [win::Current]
    # Make sure that we can open this file.
    if {[catch {file::openQuietly $path}]} {
	status::msg "Could not open file: $path"
	return
    }
    # Make sure that we have a mark.
    if {![string length $mark]} {
	set p "Choose a mark in that file:"
	set mark [listpick -p $p [getNamedMarks -n -w $path]]
    }
    bringToFront $current
    append cmd " ; gotoMark \"$mark\""
    text::color $pos0 $pos1 $color
    text::hyper $pos0 $pos1 $cmd
    refresh
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::createTOC"  --
 # 
 # Create a hyperlinked "Table Of Contents" section for the current window.
 # Hypertext color will be the that set in the ColorMenu package prefs.
 # 
 # Can be called from other code -- any current selection in the current
 # window will first be deleted, but no default positions can be specified.
 # If the TOC is created, this returns 1, otherwise 0.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::createTOC {} {
    
    global ColorMenumodeVars

    # Preliminaries
    if {![win::checkIfWinToEdit]} {
	return 0
    }
    if {![llength [set marks [getNamedMarks -n]]]} {
        status::msg "Cancelled -- no marks found in this window."
	return 0
    } elseif {[isSelection]} {
        deleteSelection
    }
    # Adjust current position.
    set indent ""
    if {[pos::compare [set pos0 [pos::lineStart]] != [set pos1 [getPos]]]} {
        set txt1 [getText $pos0 $pos1]
	if {[is::Whitespace $txt1]} {
	    set indent $txt1
	} else {
	    goto [pos::nextLineStart $pos0]
	}
    }
    # Insert the table of contents.
    set pos2 [getPos]
    set txt2 "Table Of Contents\r\r${indent}"
    set markLinks [list]
    foreach mark $marks {
	if {[regexp {^\-[\t ]*$} $mark]} {
	    lappend markLinks ""
	} else {
	    regsub -all "\t" $mark " " mark
	    lappend markLinks "\"# ${mark}\""
	}
    }
    append txt2 [join $markLinks "\r${indent}"]
    append txt2 "\r\r${indent}<<floatNamedMarks>>\r"
    insertText $txt2 ; goto $pos2
    # Hyperlink section marks for the current window, anything in double
    # quotes that starts with "# " (similar to html in-file-target.)  Note
    # that you do not need to include extra leading spaces within the quotes.
    win::searchAndHyperise \
      {"\# +([^ ][^\r\n\"]+)"} \
      {help::goToSectionMark {\1}} \
      1 $ColorMenumodeVars(markLinkColor) +3 -1
    # Search for "<<something>>" and embed as hypertext.
    win::searchAndHyperise \
      {<<([^>\r\n]+)>>} \
      {\1} \
      1 $ColorMenumodeVars(hypertextColor) +2 -2
    # That's it.
    refresh
    status::msg "The table of contents for this window has been inserted."
    return 1
}

# ===========================================================================
#
# ◊◊◊◊ -------- ◊◊◊◊ #
#
# ◊◊◊◊ Color / Style conversions ◊◊◊◊ #
#
# Everything in this section and the one which follows (up to the next
# divider mark) could possibly be included in the core file "colors.tcl" so
# that they would be available to other packages even if this package has
# been uninstalled.
#

namespace eval colors {
    
    variable Colors
    variable Styles
    variable Mappings

    # These are colours 0 through 7.
    set Colors [list \
      "none" "blue" "cyan" "green" "magenta" "red" "white" "yellow"]
    # These are colours 8 through 15.
    set Styles [list \
      "bold" "condense" "extend" "italic" "normal" "outline" "shadow" "underline"]
    # This is a handy array for converting colors to numbers.  Note that (as of
    # this writing) while Alphatk recognize all of these indices, it colors
    # text 'blue' for 'bold', 'condense' 'shadow', etc.
    array set Mappings {
	none       0
	blue       1
	cyan       2
	green      3
	magenta    4
	red        5
	white      6
	yellow     7
	bold       8
	condense   9
	condensed  9
	extend     10
	extended   10
	italic     11
	italics    11
	normal     12
	outline    13
	outlined   13
	shadow     14
	shadowed   14
	underline  15
	underlined 15
    }
    # These are the default options for the dialog.
    variable LastColorChosen "blue"
    variable LastStyleChosen "normal"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::chooseColor"  --
 # 
 # Offer a listpick dialog with colors 0-7.  Listpick includes color names,
 # but the returned result is the numeric color/style index.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::chooseColor {{extraPrompt ""} {defaultColor ""}} {

    variable Colors
    variable LastColorChosen

    set p "Choose a color ${extraPrompt}:"
    if {![string length $defaultColor]} {
	set defaultColor $LastColorChosen
    }
    set color [listpick -p $p -L $defaultColor $Colors]
    set LastColorChosen $color
    return [colors::convertColorStyle $color]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::chooseColor"  --
 # 
 # Offer a listpick dialog with colors 8-15 (which are really styles).
 # Listpick includes style names, but the returned result is the numeric
 # color/style index.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::chooseStyle {{extraPrompt ""} {defaultStyle ""}} {

    variable Styles
    variable LastStyleChosen

    set p "Choose a style ${extraPrompt}:"
    if {![string length $defaultStyle]} {
	set defaultStyle $LastStyleChosen
    }
    set style [listpick -p $p -L $defaultStyle $Styles]
    set LastStyleChosen $style
    return [colors::convertColorStyle $style]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::convertColorStyle"  --
 # 
 # Given a textual version of a color/style, return the numeric color index.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::convertColorStyle {colorStyle} {

    variable Mappings

    if {[is::UnsignedInteger $colorStyle]} {
	if {($colorStyle >= 0) && ($colorStyle <= 15)} {
	    return $colorStyle
	} else {
	    echo "'$colorStyle' is out of range: 0-15"
	    return 0
	}
    } elseif {[info exists Mappings($colorStyle)]} {
	return $Mappings($colorStyle)
    } else {
	echo "'$colorStyle' is not recognized as a valid color mapping"
	return 0
    }
}

# ◊◊◊◊ Color Utilities ◊◊◊◊ #

## 
 # --------------------------------------------------------------------------
 # 
 # "colors::getPositions"  --
 # 
 # Creates two new vars in the calling stack frame, 'pos0' and 'pos1'.
 # 
 # If the calling proc has an 'args' variable, determine if it is a list
 # containing either 0 or 2 args.  If 'args' exists as a list with a
 # different number of items, this will throw an error.
 # 
 # If 'arg' exists and contains two items, assume that these are the
 # positions that we want.
 # 
 # If 'args' doesn't exist, or is an empty list, then use the starting /
 # ending positions for a required current selection.  If there is no
 # selection this will throw an error which will (hopefully) result in an
 # abort sequence.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colors::getPositions {args} {

    set item [info level -1]
    requireOpenWindow "Cancelled -- '$item' requires an open window."
    if {![info exists args] || ![llength $args]} {
	requireSelection "Cancelled -- '$item' requires selected text."
	set args [list [getPos] [selEnd]]
    }
    if {([llength $args] != "2")} {
	error "Incorrect position arguments: should be ?pos0 pos1?"
    }
    upvar pos0 pos0
    upvar pos1 pos1
    set pos0 [lindex $args 0]
    set pos1 [lindex $args 1]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "${color}Region" "${style}Region"  --
 # 
 # The actual proc names are 'redRegion', 'blueRegion', 'outlineRegion', etc.
 # Colorize/Stylize the specified region, or a required current selection.
 # 
 # --------------------------------------------------------------------------
 ## 

namespace eval colors {
    
    variable Colors
    variable Styles
    variable Mappings
    
    foreach color $Colors {
	set idx $Mappings($color)
	;proc ::${color}Region {args} "eval ::colorizeRegion $idx \$args"
    }
    foreach style $Styles {
	set idx $Mappings($style)
	;proc ::${style}Region {args} "eval ::stylizeRegion  $idx \$args"
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "colorizeRegion"  --
 # 
 # Colorize the specified region, or a required current selection.  If no
 # 'color' is specified, offer a listpick of colors 0-7.
 # 
 # --------------------------------------------------------------------------
 ## 

proc colorizeRegion {{color ""} args} {

    eval colors::getPositions $args
    if {![string length $color]} {
	set color [colors::chooseColor]
    }
    text::color $pos0 $pos1 $color
    refresh
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "stylizeRegion"  --
 # 
 # Stylize the specified region, or a required current selection.  If no
 # 'style' is specified, offer a listpick of styles (colors 8-15).
 # 
 # --------------------------------------------------------------------------
 ## 

proc stylizeRegion {{style ""} args} {

    eval colors::getPositions $args
    if {![string length $style]} {
	set style [colors::chooseStyle]
    }
    text::color $pos0 $pos1 $style
    refresh
    return
}

# ===========================================================================
#
# ◊◊◊◊ ------------ ◊◊◊◊ #
# 
# ◊◊◊◊ Version History ◊◊◊◊ #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# ??/??/?? pk? ??-0.1 Original, plus modifications
# 11/15/02 cbu 1.0    Added [colors::colorizePatterns] to search and color text
#                       in the current window
#                     General update, allowing for user specified bindings
#                       (or no bindings at all), plus some color prefs to
#                       set defaults for hypertext.
#                     Added [colors::linkAllUrls/linkAllEmails] procs.
#                     Added [colors::redefineColors], also available through the
#                       "Config" menu, but since we are dealing with colors ...
#                     Cleaned up [colors::displayWindowMarks/Colors] a little.
# 12/09/02 cbu 1.0.1  Fixed bugs reported by Dominique (thanks!)
#                     Proc descriptions included.
#                     [colors::colorAllMarks] can optionally color title.
# 01/29/03 cbu 1.0.2  Minor [colors::createTOC] fix.
# 02/05/03 cbu 1.1    Updated for Tcl 8.4 (which is now required).
# 04/22/03 cbu 1.2    New 'Create Hyperlink' and 'Color Style Text' CM modules.
# 08/26/03 cbu 1.2.1  Minor Tcl formatting changes.
# 09/02/03 cbu 1.2.2  Reimplemented use of [global].
# 09/08/03 cbu 1.2.3  Calling procs with full namespaces.
# 

# ===========================================================================
#
# .
