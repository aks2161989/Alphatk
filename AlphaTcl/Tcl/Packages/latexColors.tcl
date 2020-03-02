## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "latexColors.tcl"
 #                                          created: 07/23/2003 {01:31:17 PM}
 #                                      last update: 03/06/2006 {08:14:19 PM}
 # Description:
 # 
 # Provides color support for the contents of braces for user-selected LaTeX
 # commands.  Settings are saved between editing sessions, and colors can be
 # automatically applied when .tex documents are first opened by using the
 # keyboard shortcuts for "Refresh" or "Center Refresh".
 # 
 # Limitations:
 # 
 # In Alpha8/X, if there are any characters colored by [regModeKeywords]
 # within the region that is colored by the procs below, coloring stops
 # midstream.  I'm not sure what is taking place internally, but it does
 # reduce the effectiveness of this package.  "Styles" are not affected by
 # this limitation.
 # 
 # In Alpha8/X, the use of the "bold" style is very font-dependent.  Fonts
 # that do not render bold text using the same pixel length as normal text
 # will present rendering issues when the user attempts to edit text in a line
 # that has had this style applied.  We go to some trouble to ensure that this
 # never happens by always checking the font of the current window against a
 # list of known fonts in which "bold" is an acceptable option.
 # 
 # Many thanks to Steffen Wolfrum for valuable beta-testing and suggestions,
 # and to Vince Darley for Alphatk core fixes allowing this package to work!
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2003-2006 Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

  # ×××× Feature Declaration ×××× #
alpha::feature latexColors 0.5 {TeX} {
    # Initialization script.
    alpha::package require -loose TeX 5.0
    # These items will be available in the pop-up menus in the "LaTeX
    # Utilities > Color Window" menu command.
    newPref var colorizableItems \
      [list "begin|end" "(no)?cite.*" "emph" \
      "footnote" "ref" "textbf" "textit" "text.*"] \
      TeX
    # This keyboard shortcut will update all "LaTeX Colors" in the active
    # window.
    newPref binding refreshLaTeXColors "<B<I/L" TeX "" \
      {TeX::colors::refreshWindow 0}
    # This keyboard shortcut will update all "LaTeX Colors" in the active
    # window, and center the window on the cursor location.
    newPref binding refreshLaTeXColorsCenter "<B/L" TeX "" \
      {TeX::colors::refreshWindow 1}
} {
    # Activation script.
    menu::insert   {LaTeX Utilities} items end \
      "(-)" {Color WindowÉ} {Remove Colors}
    TeX::colors::registerHooks "register"
} {
    # Deactivation script.
    menu::uninsert {LaTeX Utilities} items end \
      "(-)" {Color WindowÉ} {Remove Colors}
    TeX::colors::registerHooks "deregister"
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-file
} description {
    This package provides additional color support for TeX mode
} help {
    This package provides additional color support for TeX mode.  You can turn
    it on by selecting "Config > Mode Prefs > Features" and clicking on the
    checkbox for "LaTeX Colors".
    
    Preferences: Mode-Features-TeX

	  	Table Of Contents

    "# Description"
    "# Color Window"
    "# Remove Colors"
    "# Keyboard Shortcuts"
    "# Testing"
    "# Limitations"
    "#   Incomplete Colors"
    "#   Use of the 'bold' style"

    <<floatNamedMarks>>

    
	  	Description

    Once this package has been turned on, two new items can now be found in
    the "TeX Menu > LaTeX Utilities" submenu, named
    
	Color Window
	Remove Colors

    which are described below.  These items will add/remove colors and styles
    to the {contents} of select commands.
    
	  	Color Window

    The first item ("TeX Menu > LaTeX Utilities > Color Window") opens a
    <<TeX::colors::optionsDialog>> dialog in which you can specify up to four
    different LaTeX items to which you would like different colors to be
    added.  All text in braces following the "field" name will then be
    colored, as in
  
	\footnote{
	   This is text that would be colored
	}
	
	and {\footnote This will also work}
       
    The list of items available for colorizing can be found in the TeX mode
    preference for "Colorizable Items" once this package has been turned on.
    Items in this preference can be regular expressions if desired.
    
    Preferences: Mode-TeX
    
    All settings are saved between editing sessions.
    
    If the "Remember Window State" variable of the window is turne on, then
    the colors/styles are saved in the file's resource fork and will be
    present the next time that the file is opened.  Use the "File Info"
    pop-up menu in the status bar to change this setting.
    
    Otherwise, pressing the TeX mode keyboard shortcut which has been defined
    for "Refresh LaTeX Colors" as described below will first remove and then
    add all of the colors and styles using the saved settings.

	  	Remove Colors
    
    The second item ("TeX Menu > LaTeX Utilities > Remove Colors") will remove
    all of the colors which have been added by the first item.  They will be
    re-applied the next time you you use keyboard shortcut for "Refresh" or
    "Center Refresh" until you have either turned this package off or reset
    all values in the "Color Window" dialog to their empty default values.
    
	  	Keyboard Shortcuts

    If you edit the text within the colored environments, you might find that
    the text colors or styles are not consistently rendered.  This package
    defines two different configurable keyboard shortcuts to help clean up the
    active window.
    
	Refresh LaTeX Colors
	Refresh LaTeX Colors Center
    
    The default values for these shortcuts are the same as "Refresh" and
    "Center Refresh" that are used in all other Alpha windows.  Pressing
    Control-Option-L will update update the colors for you in the active
    window using the saved settings, while Control-L will also center the
    window using the cursor location.
    
    Preferences: Mode-TeX
    
	  	Testing
    
    Want to test this package?  Click here <<TeX::colors::testPackage>> to
    open the "LaTeX Example.tex" example window.  This will temporarily
    activate this package for this editing session, and offer the dialog for
    "TeX Menu > LaTeX Utilities > Color Window".  To turn this package on
    permanently, you can adjust your preferences: Mode-Features-TeX .
    
	  	Limitations

    This feature is exploiting some of the window coloring options that are
    made available by various Alpha core commands.  In some cases we run into
    some interference encountered with "normal" keyword colorizing routines,
    as explained below.
    
    Neither of these limitations is present in Alphatk.
    
    If you want these colors to be automatically applied when you first open
    a .tex window, you need to turn this package on "globally."
    
    Preferences: Features
    
    (Technical note 1: Automatic colorizing with this package can result in a
    considerable delay when .tex windows are first opened.  Perhaps we need a
    preference to decide if colors should be automatically applied.)
    
    (Technical note 2: if the feature is only turned on for TeX mode, the
    colors are only applied if the mode of the active window is "TeX"
    _before_ the new window is opened.  The [openHook] procedure is
    deregistered when switching out of TeX mode, and by the time it is
    re-registered because TeX mode features are re-activated the window has
    already been opened and the hook won't be called...  We hope to address
    this better in a future release, perhaps by always registering the
    [openHook] and checking to see this package is still active, or making
    use of a package's "off" script.)

	  	 	Incomplete Colors

    In both Alpha8 and AlphaX, due to limitations in how these applications
    create, render and store color information for active windows, it is
    possible that the entire contents of the colorized items will not be
    properly rendered.  For example, a footnote that looks like
    
	\footnote{
	
	this is a \textit{test} of colorizing with this package
	% this is a commented line
	and this
	\begin{quote}
	    is another test
	\end{quote}
	    
	}

    might only color the text up to the first backslash.  These are known
    problems with the application, not with this package, although fixing them
    will require extensive changes in the cores of the executables and is of
    low priority at the moment.
    
    Fortunately, this Alpha8/X limitation only applies to colors, not styles,
    so it would still be possible to make the above string all italicized, or
    underlined.    (This limitation is not present in Alphatk.)
    
	  	 	Use of the 'bold' style

    Differentiating text such as footnotes using the "bold" style makes this
    feature extremely useful.  However, in Alpha8/X this requires that the
    font of the active window renders "normal" and "bold" letters using the
    exact same pixel length.  (This limitation is not present in Alphatk.)

    "Monaco" is an example of a font that does _not_ meet this requirement,
    and attempting to edit text that has been styled with "bold" with this
    font will lead to all sorts of rendering problems and make the editing of
    text in such regions nearly impossible, possibly introducing a lot of
    garbage text.  "Courier" is an example of an acceptable font.
    
    When you select the "TeX Menu > LaTeX Utilities > Color Window" command,
    the font of the current window is checked to see if it will allow for
    applying the "bold" style.  If not, it will not be offered.  If it has
    been previously set for a window that accepts bold, but then you attempt
    to colorize a window with a different font that does not accept bold, you
    will be warned about this conflict and the style will not be applied.
    
    The fonts that meet this requirement are not necessarily monospaced, just
    as monospaced fonts do not guarantee that they meet this requirement.
    Click here <<TeX::colors::listBoldFonts>> to see the list of all fonts for
    which "bold" has been deemed a safe style for colorizing.  If you find
    others which meet the "same pixel length for bold and normal" requirement,
    please contact this package's maintainer and it will be included in the
    next release.
}

proc latexColors.tcl {} {}

namespace eval TeX {}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::ColorWindow" --
 # "TeX::RemoveColors" --
 # 
 # Called by [TeX::menuProc], redirect to the procedures in the correct
 # namespace below.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::ColorWindow {} {
    TeX::colors::colorWindow
}

proc TeX::RemoveColors {} {
    TeX::colors::removeColors
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval TeX::colors {
    
    # This list is used by the "Reset" button in the options dialog.
    variable defaultColorArgs [list \
      [list (None) none normal] \
      [list (None) none normal] \
      [list (None) none normal] \
      [list ""     none normal] \
      ]
    # This value is saved between editing sessions.
    variable lastColorArgs
    if {![info exists lastColorArgs]} {
	set lastColorArgs $defaultColorArgs
    }
    prefs::modified lastColorArgs
    # This is used by [TeX::colors::optionsDialog]
    variable queriedExtraItems [list]
    
    # These are fonts that have been tested for proper rendering of the "bold"
    # style in Alpha8/X. This could perhaps be simplified if we were able to
    # get a complete list of fonts and do some [font measure] comparison, but
    # that is kind of beyond my skills at the moment, and requires Tk.  -- cbu
    variable validBoldFonts [list \
      {American Typewriter Condensed} {American Typewriter Condensed Light} \
      {American Typewriter Light} \
      {Baskerville Semibold} {Bertram LET} {Big Caslon} \
      {BlairMdITC TT-Medium} {Bradley Hand ITC TT-Bold} \
      {Charcoal} {Charcoal CY} {Copperplate Light} \
      {Courier} {Courier CE} {Courier New} \
      {Didot} {Futura} {Gill Sans Light} {Herculanum} {Impact} \
      {LunaITC TT-Bold} {Machine ITC TT} {Mona Lisa Solid ITC TT} \
      {Optima ExtraBlack} {PortagoITC TT} {Skia} {Stone Sans ITC TT-Bold} \
      {Stone Sans OS ITC TT-Bold} {Stone Sans SC ITC TT-Semi} \
      {Symbol} {TremorITC TT} \
      {VT100} \
      ]
    # These are colors 0 through 7.
    variable colorOptions [list \
      "none" - "blue" "cyan" "green" "magenta" "red" "white" "yellow"]
    # This is a subset of colors/styles 8 through 15 used by [text::color].
    # In Alpha8/X, we only include those that will be rendered with the same
    # font width as 'normal' characters.  See [TeX::colors::confirmBoldStyle]
    # below regarding the inclusion of "bold" in this list.  Note that all of
    # "condense" "extend" and "shadow" will never be available in Alphatk, and
    # probably are of little practical use in Alpha8/X anyway.
    variable styleOptions [list "normal" - "italic" "underline"]
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::testPackage" --
 #
 # A useful little proc to test out the feature.  Should only be called from a
 # hyperlink, probably only from this package's help window.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::testPackage {} {
    
    help::openExample "LaTeX Example.tex"
    if {![package::active "latexColors"]} {
	package::activate latexColors
	set msg "The 'LaTeX Colors' package has been temporarily activated.  "
    }
    append msg "The \"Color Window\" dialog for this package will now\
      be presented, allowing you to add colors to this window."
    alertnote $msg
    TeX::colors::colorWindow 1 [win::Current]
    return
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::listBoldFonts" --
 # 
 # Inform the user about the list of window fonts currently acceptable for
 # application of the "bold" style.  Called from the Help window hyperlink.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::listBoldFonts {} {
    
    variable validBoldFonts
    
    set fontList [lsort -dictionary $validBoldFonts]
    listpick -p "Valid fonts for the 'bold' style" $validBoldFonts
    return
}

# ===========================================================================
# 
# ×××× Hooks ×××× #
# 

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::registerHooks" --
 # 
 # We dim/enable the menu items to make sure that they are only available for
 # TeX mode windows.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::registerHooks {which} {
    
    global TeXmodeVars
    
    switch -- $which {
        "register" {
            hook::register   openHook   {TeX::colors::colorWindow 0} TeX
	    hook::register   changeMode {TeX::colors::changeModeHook}
        }
        "deregister" {
	    hook::deregister openHook   {TeX::colors::colorWindow 0} TeX
	    hook::deregister changeMode {TeX::colors::changeModeHook}
        }
	default {
	    error "Unknown option: $which"
	}
    }
    return
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::changeModeHook" --
 # 
 # If this package is active, check to see if we are in TeX mode, and if not
 # then dim the menu items.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::changeModeHook {{newMode}} {
    
    if {![package::active latexColors]} {
        return
    }
    set dim [expr {($newMode eq "TeX")} ? 1 : 0]
    enableMenuItem -m "LaTeX Utilities" "Color WindowÉ" $dim
    enableMenuItem -m "LaTeX Utilities" "Remove Colors" $dim
    return
}

# ===========================================================================
# 
# ×××× Color Window ×××× #
# 

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::colorWindow" --
 # 
 # Calls the other procedures in this file as needed.  This is also called
 # when the user presses the keyboard shortcuts for refreshing the window, in
 # which case we just use the saved settings.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::colorWindow {{offerDialog 1} {window ""}} {
    
    variable colorOptions
    variable defaultColorArgs
    variable lastColorArgs
    
    if {($window eq "")} {
	set window [win::Current]
    }
    if {$offerDialog} {
	TeX::colors::optionsDialog
    }
    if {($lastColorArgs eq $defaultColorArgs)} {
	status::msg "No 'LaTeX Colors' fields have been set."
	return
    }
    watchCursor
    TeX::colors::removeColors -w $window
    set count 0
    status::msg [set msg "Searching, coloring the windowÉ"]
    set colorArgs [list]
    for {set i 0} {$i <= 3} {incr i} {
	set argsList [lindex $lastColorArgs $i]
	set argsList [eval TeX::colors::confirmBoldStyle $argsList]
	incr count   [eval [list TeX::colors::colorItem -w $window] $argsList]
	lappend colorArgs $argsList
    }
    set lastColorArgs $colorArgs
    set msg "$msg complete.  $count items colored/styled."
    if {$offerDialog} {
	refresh -w $window
	status::msg $msg
	return
    } else {
        return $msg
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::colorItem" --
 # 
 # Called by [TeX::colors::colorWindow], search through the active window and
 # add colors/styles when they are found.  Returns the total number of changes
 # made to the active window.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::colorItem {args} {
    
    win::parseArgs w itemName color style
    
    set count 0
    if {($itemName eq "") || ($itemName eq "(None)")} {
	return 0
    } elseif {($color eq "none") && ($style eq "normal")} {
	return 0
    }
    append pat1 {(} $itemName {)\s*(\[([^\]])*\])?\s*\{}
    append pat2 {\{\s*(} $itemName {\s)}
    foreach pat [list $pat1 $pat2] {
	set pos0 [minPos -w $w]
	while {1} {
	    set change 0
	    set pp [search -w $w -n -s -r 1 -f 1 -- $pat $pos0]
	    if {![llength $pp]} {
		break
	    }
	    set pos1 [lindex $pp 1]
	    set pos0 [pos::math -w $w $pos1 + 2]
	    if {[catch {matchIt -w $w "\{" $pos1} pos2]} {
		continue
	    }
	    if {($color ne "none")} {
		text::color -w $w $pos1 $pos2 $color
		set change 1
	    }
	    if {($style ne "normal")} {
		text::color -w $w $pos1 $pos2 $style
		set change 1
	    }
	    incr count $change
	}
    }
    return $count
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::optionsDialog" --
 # 
 # Create and offer a dialog containing all of the different color/style
 # options.  All information is retained in the "lastColorArgs" variable,
 # which can then be used by other code in this file.  The dialog includes two
 # extra buttons, for "Reset" and "Help".
 # 
 # The item name for Color/Style 4 is an editable text field, allowing the
 # user to enter anything not available in the pop-up menus.  We offer the
 # possibility of saving this item in the TeXmodeVars(colorizableItems)
 # preference, so that it will be added to these pop-ups, but if the user
 # declines we won't ask about this particular item again.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::optionsDialog {} {
    
    global TeXmodeVars

    variable colorOptions
    variable defaultColorArgs
    variable lastColorArgs
    variable queriedExtraItems
    variable styleOptions
    
    # Confirm the list of colorizable items.
    if {[info exists TeXmodeVars(colorizableItems)]} {
	set fields [concat [list "(None)" "-"] \
	  [lsort -dictionary $TeXmodeVars(colorizableItems)]]
    } else {
	set fields [list "(None)" "-" "begin|end" "(no)?cite.*" "emph" \
	  "footnote" "ref" "textbf" "textit" "text.*"]
    }
    # Confirm the list of styles.
    set idx [lsearch $styleOptions "bold"]
    if {![TeX::colors::confirmBoldStyle]} {
        if {($idx > -1)} {
            set styleOptions [lreplace $styleOptions $idx $idx]
        }
    } elseif {($idx == -1)} {
	lappend styleOptions "bold"
    }
    # Set up the list of options to be used in the dialog.
    for {set i 0} {$i <= 3} {incr i} {
	set num [expr {$i + 1}]
	set item$num  [lindex $lastColorArgs $i 0]
	set color$num [lindex $lastColorArgs $i 1]
	set style$num [lindex $lastColorArgs $i 2]
    }
    # Create a "Reset" button with a script for restoring default values.  We
    # need a button name, balloon help, and a script to evaluate.
    set buttonScript {
	for {set i 0} {$i <= 3} {incr i} {
	    set defaults $::TeX::colors::defaultColorArgs
	    set num [expr {$i + 1}]
	    dialog::valSet $dial ",Item ${num}:"  [lindex $defaults $i 0]
	    dialog::valSet $dial ",Color ${num}:" [lindex $defaults $i 1]
	    dialog::valSet $dial ",Style ${num}:" [lindex $defaults $i 2]
	}
    }
    set button1 [list \
      "Reset" \
      "Use this button to reset the values to defaults." \
      $buttonScript]
    # Create a "Help" button.
    set button2 [list \
      "Help" \
      "Use this button to open the LaTeX Colors help window." \
      "package::helpWindow latexColors ; set retVal {cancel} ; set retCode {1}"]
    set buttons [concat $button1 $button2]
    # Creating the dialog page.
    set dialogPage [list ""]
    append divider [string repeat "=" 27] "\r"
    # Add the first three items, which use pop-up menus.
    for {set i 1} {$i <= 3} {incr i} {
	lappend dialogPage \
	  [list [list "menu" $fields]       "Item $i:"  [set item$i]] \
	  [list [list "menu" $colorOptions] "Color $i:" [set color$i]] \
	  [list [list "menu" $styleOptions] "Style $i:" [set style$i]] \
	  [list "text" $divider]
    }
    # Add the last item, which is an editable text field.  Note that $i has
    # already been incremented appropriately.
    lappend dialogPage \
      [list "var"                       "Item $i:"  [set item$i]] \
      [list [list "menu" $colorOptions] "Color $i:" [set color$i]] \
      [list [list "menu" $styleOptions] "Style $i:" [set style$i]] \
      [list "text" $divider]
    # Present the dialog, and then save the values.
    set result [dialog::make -title "Colorize TeX Items" -width 325 \
      -addbuttons $buttons $dialogPage]
    set lastColorArgs [list]
    for {set i 0} {$i <= 10} {incr i} {
	set itemName [string trim [lindex $result $i]]
	set color    [lindex $result [incr i]]
	set style    [lindex $result [incr i]]
	regsub -- {^\\} $itemName "" itemName
	if {($itemName eq "") || ($itemName eq "(None)")} {
	    set color "none"
	    set style "normal"
	}
        lappend lastColorArgs [list $itemName $color $style]
    }
    # Do we have a new item to add to the list of defaults?  ('$itemName' will
    # be the last one added, which is the editable text field.)
    if {[info exists TeXmodeVars(colorizableItems)] \
      && [string length $itemName] \
      && ([lsearch $queriedExtraItems $itemName] == -1) \
      && ([lsearch $TeXmodeVars(colorizableItems) $itemName] == -1)} {
	lappend queriedExtraItems $itemName
	set q "Would you like to add '${itemName}'\
	  to the list of default items available in\
	  the pop-up menus of this dialog?"
	if {[askyesno $q]} {
	    lappend TeXmodeVars(colorizableItems) $itemName
	    prefs::modified TeXmodeVars(colorizableItems)
	}
    }
    return
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::confirmBoldStyle" --
 # 
 # This is a check for Alpha8/X -- it is not necessary for Alphatk, and we
 # will always allow "bold" to be included.
 # 
 # In Alpha8/X, we assume that both "italic" and "underline" will work with
 # all fonts.  "bold" is a little bit tricky -- even with a monospaced font
 # like "Monaco", bold versus normal font rendering will have different pixel
 # widths but navigation of the text will not visually place the cursor in the
 # proper place in the window.  This makes editing the text within a stylized
 # region not only difficult but potentially dangerous: the WYSIWYG concept is
 # completely abandoned, and the potential for typing in garbage without
 # realizing it is very high.  For this reason we must check the font of the
 # active window and make an appropriate decision.
 # 
 # When called with no arguments, we are deciding if the "bold" style should
 # be offered in the dialog.  Otherwise, we are checking to if the list of
 # items to be colorized includes the "bold" style, and if so inform the user
 # that this is _not_ going to be done.
 # 
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::confirmBoldStyle {args} {
    
    global alpha::platform
    
    variable validBoldFonts
    
    set boldOk 1
    if {${alpha::platform} eq "alpha"} {
	# Determine if "bold" should be allowed in Alpha8/X.
	set currentFont [win::getInfo [win::Current] font]
	set validFonts  [string tolower $validBoldFonts]
	if {([lsearch $validFonts [string tolower $currentFont]] == -1)} {
	    set boldOk 0
	}
    }
    if {![llength $args]} {
	# Called from [Tex::colors::optionsDialog].
	return $boldOk
    } elseif {([lindex $args 2] ne "bold") || $boldOk} {
	# Called from [TeX::colors::colorWindow]
        return $args
    }
    # "bold" is in the user's list of items to be styled.  If the "itemName"
    # isn't empty then remove the style from the list to be colored/styled.
    set itemName  [lindex $args 0]
    set itemStyle [lindex $args 2]
    if {($itemName eq "") || ($itemName eq "(None)")} {
	return $args
    } else {
	set msg "The \"bold\" style is not compatible in windows\
	  that are using the \"${currentFont}\" font, and this\
	  style will not be applied to the active window."
	if {![dialog::yesno -y "OK" -n "Help" $msg]} {
	    TeX::colors::removeColors 1
	    help::openGeneral "latexColors"
	    editMark [win::Current] "  Use of the 'bold' style"
	    return -code return
	}
	return [lreplace $args 2 2 "normal"]
    }
}


##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::removeColors" --
 # 
 # This removes not only the colors added by this package, but all added using
 # [text::color].  It does not affect keywords, etc that have been added using
 # [regModeKeywords].
 #
 # The last time I checked, Alphatk does not properly remove colors with the
 # core command [removeColorEscapes].
 # 
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::removeColors {args} {
    
    win::parseArgs w {quietly 0}
    
    if {![catch {removeColorEscapes -w $w} errorMsg]} {
	refresh -w $w
	set msg "All colors in '[win::Tail $w]' have been removed."
	set result 1
    } else {
        set msg "Could not remove colors: $errorMsg"
	set result 0
    }
    if {!$quietly} {
        status::msg $msg
    }
    return $result
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::colors::refreshWindow" --
 # 
 # Called by the user-configurable keyboard shortcuts, refresh all colors in
 # this window using our saved settings, and then refresh.  This should be
 # mimicing the normal actions for "Refresh" and "Center Refresh", with our
 # little interventions.
 #
 # -------------------------------------------------------------------------
 ##

proc TeX::colors::refreshWindow {args} {
    
    win::parseArgs w {center 1}
    
    variable defaultColorArgs
    variable lastColorArgs
    
    set msg ""
    if {($lastColorArgs ne $defaultColorArgs)} {
	TeX::colors::removeColors -w $w 1
	set msg [TeX::colors::colorWindow 0 $w]
    }
    if {$center} {
        centerRedraw -w $w
    } else {
        refresh -w $w
    }
    status::msg $msg
    return
}

# ===========================================================================
# 
# ×××× Version History ×××× #
# 
# modified by  vers# reason
# -------- --- -----  -----------
# 07/23/03 cbu 0.1    Original, created in response to a feature request
#                       posted to the AlphaTcl-Users listserv.
# 07/30/03 cbu 0.2    Added limited palette of styles.  Many thanks to
#                       Steffen Wolfrum for beta-testing, suggestions.
# 08/04/03 cbu 0.3    The "bold" style is optionally added to the options
#                       dialog, depending on the font of the active window.
# 09/04/03 cbu 0.4    Alphatk [text::color] core changes support this package, 
#                       and bold is always available regardles of the font.
# 02/24/05 cbu 0.5    [openHook] proc properly accepts window argument.
#                     All relevant procedures accept optional ?-w <win>? arg.
# 

# ===========================================================================
# 
# .