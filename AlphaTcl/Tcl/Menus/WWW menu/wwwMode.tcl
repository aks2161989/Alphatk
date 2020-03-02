## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwMode.tcl"
 #                                          created: 04/30/1997 {11:04:46 am}
 #                                      last update: 03/21/2006 {01:53:45 PM}
 # Description:
 # 
 # The WWW Menu provides a simple text based (Lynx-like) HTML file
 # browser, for reading local HTML files
 #
 # The reason to create a "WWW" mode is so that rendered windows can have
 # easy access to the menu, and appropriate keybindings.
 #
 # Note that if the variables used in this package are 'global' lists that
 # are not specific to any window/url/filename, they are included in the
 # 'wwwMenuVars' array.
 # 
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

alpha::mode WWW {for wwwMenu menu} {wwwMode.tcl} {*.www} {
    wwwMenu
} {
    # Initialization script.  Called when Alpha is first started.
    alpha::internalModes "WWW"
} description {
    Provides internal support for the WWW menu
} help {
    file "WWW Menu Help"
}

proc wwwMode.tcl {} {}

namespace eval html {
    
    variable HtmlToStyle
    array set HtmlToStyle [list \
      "CODE"    "normal" \
      "KBD"     "normal" \
      "SAMP"    "normal" \
      "TT"      "normal" \
      "U"       "underline" \
      ]

    # Since Alphatk doesn't do anything yet with bold, outline, italic etc, we
    # simplify this to make it more obvious what's going to happen.  (If we
    # define them as 'bold' etc, it affects wrapping indentation.)

    if {(${alpha::platform} eq "alpha")} {
	array set HtmlToStyle [list \
	  "B"           "bold" \
	  "BIG"         "outline" \
	  "CITE"        "italic" \
	  "DFN"         "italic" \
	  "EM"          "italic" \
	  "I"           "italic" \
	  "SMALL"       "condensed" \
	  "STRONG"      "bold" \
	  "VAR"         "italic" \
	  ]
    } else {
	array set HtmlToStyle [list \
	  "B"           "bold" \
	  "BIG"         "blue" \
	  "CITE"        "italic" \
	  "DFN"         "italic" \
	  "EM"          "italic" \
	  "I"           "italic" \
	  "SMALL"       "blue" \
	  "STRONG"      "bold" \
	  "VAR"         "italic" \
	  ]
    }
}

namespace eval WWW  {}

# Register hooks.

hook::register "activateHook"           {WWW::postBuildMenu} WWW
hook::register "changeMode"             {WWW::postBuildMenu} HTML
hook::register "changeModeFrom"         {WWW::postBuildMenu} WWW
hook::register "changeModeFrom"         {WWW::postBuildMenu} HTML

# Unfortunately, these can not be registered specifically for WWW mode.

hook::register "titlebarListHook"       {WWW::titlebarListHook}
hook::register "titlebarSelectHook"     {WWW::titlebarSelectHook}
hook::register "titlebarPathHook"       {WWW::titlebarPathHook}

## 
 # -------------------------------------------------------------------------
 # 
 # "WWW::httpAllowed" --
 # 
 # Alpha7 was never able to handle the downloading of remote urls, and even
 # now we require the 'http' package -- if it is not available (it should be
 # distributed in all public releases) we disable 'View Url' and associated
 # menu items.
 # 
 # -------------------------------------------------------------------------
 ##

proc WWW::httpAllowed {} {
    
    global tcl_platform wwwMenuVars
    
    if {![info exists wwwMenuVars(httpAllowed)]} {
	if {![catch {package require http}]} {
	    set wwwMenuVars(httpAllowed) 1
	} else {
	    set wwwMenuVars(httpAllowed) 0
	}
    }
    return $wwwMenuVars(httpAllowed)
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× WWW prefs, vars, arrays ×××× #
# 

# We let the global pref for 'Compose Email Using ...' deal with this now.
prefs::removeObsolete WWWmodeVars(mailtoLinksInternal)

# These bindings are hard-wired in WWW mode, and the special mode procs will
# never be called anyway.
prefs::removeObsolete WWWmodeVars(indentOnReturn) \
  WWWmodeVars(electricSemicolon)

# This is a handy abbreviation.
set rFW "WWW::refreshFrontWindow"
set pBM "WWW::postBuildMenu"

# ===========================================================================
# 
# ××××   Flag Prefs ×××× #
# 

# To always open 'frameset' url sites with all available frames, turn this
# item on||To always be asked about opening 'frameset' url sites before
# fetching and rendering them, turn this item off
newPref flag alwaysOpenFrames       1 WWW $pBM
# To automatically adjust the text in a rendered window to fit its width,
# turn this item on||To always use the value of the WWW mode preference
# 'Fill Column' when rendering windows, turn this item off
newPref flag autoAdjustWidth        1 WWW $rFW
# To automatically 'float' a palette containing a rendered window's marks,
# turn this item on|| after To disable the automatic 'floating' of a palette
# containing a rendered window's marks, turn this item off
newPref flag autoFloatMarks         0 WWW $pBM
# To automatically place the selected link in the center of the window when
# navigating up or down, turn this item on||To never automatically place
# the selected link in the center of the window when navigating up or down,
# turn this item on 
newPref flag centerRefreshOnNav     0 WWW $pBM
# To enable electric url completions in the "Go To Url" window, turn this
# item on||To disable electric url completions in the "Go To Url" window,
# turn this item off
newPref flag electricUrlCompletions 1 WWW
# To only open one WWW browser window at a time, turn this item on. 
# (Navigating bookmarks or history items will kill the current window)||To
# create a new window for every WWW browser page, turn this item off
newPref flag linksOpenNewWindow     1 WWW $pBM
# To ignore all forms while rendering, turn this item on||To insert 'form
# begins/end' markers when rendering forms, turn this item off
newPref flag ignoreForms            0 WWW $rFW
# To ignore all images while rendering, turn this item on||To insert 'image'
# markers when rendering files, turn this item off
newPref flag ignoreImages           0 WWW $rFW
# To always open the "Go To Url" window when the first time a web page is
# rendered, turn this item on||To only open the "Go To Url" window when
# called by the menu item (or by pressing 'u' in a rendered window), turn
# this item off.
newPref flag openGoToUrlWindow      0 WWW $pBM
# To always remember the geometry of a rendered window when opening a new
# one, turn this item on|| To always use default 'global' window geometry,
# rather than remember the geometry of the last WWW window, turn this item
# off
newPref flag rememberWindowGeometry 1 WWW $pBM
# Turn this item on to bypass the search text dialog if there is a currently
# highighted selection when using the "Search Engines" menu items||Turn this
# item off to use any currently highlighted selection as the default text in
# the "Search Engines" dialog
newPref flag searchUsingSelection   0 WWW $pBM

# Contextual Menu modules

# Provides easy access to all of your saved bookmarks
newPref flag bookmarksMenu   1 contextualMenuWWW
# Includes items to navigate your recent browsing history
newPref flag goToPageMenu    1 contextualMenuWWW
# Includes items to manipulate the hyperlinks in the active window
newPref flag wwwLinksMenu    1 contextualMenuWWW
# Includes items to reload, refresh, copy the source url (etc.)  of the
# active WWW window; this is a duplicate of the "WWW Menu > WWW Window" menu
newPref flag wwwWindowMenu   1 contextualMenuWWW
# Open the next item in your browsing history list
newPref flag pageForwardItem 1 contextualMenuWWW
# Open the previous item in your browsing history list
newPref flag pageBackItem    1 contextualMenuWWW
hook::register contextualPostBuildHook {WWW::postBuildCM} "WWW"

# To handle all 'ftp' links internally, turn this item
# on||To never handle any 'ftp' links internally, turn this item off
newPref flag ftpLinksInternal       0 WWW
# To fetch and parse all 'http' links using the WWW menu, turn this item
# on||To never send any fetch and parse all 'http' links using the WWW
# menu, turn this item off
newPref flag httpLinksInternal      1 WWW
# To send all 'java applets' links using the 'Java Viewer Sig', turn this
# item on||To never send any 'mailto' links to Alpha's Eudora menu, turn
# this item off
newPref flag runJavaAppletsDirectly 0 WWW
# To send all unrecognized links (or those turned off by the prefs above) to
# internet config, turn this item on||To never send any unrecognized link to
# internet config, turn this item off
newPref flag wwwSendRemoteLinks     0 WWW

# Make sure that we can handle internal links.
if {![WWW::httpAllowed]} {
    set WWWmodeVars(httpLinksInternal) 0
    set invisibleModeVars(httpLinksInternal) 1
} 

set wwwMenuVars(refreshPrefs) [list \
  "autoAdjustWidth" \
  "ignoreForms" \
  "ignoreImages" \
  ]

# These prefs will appear in the menu.

set wwwMenuVars(prefsInMenu) {
    autoFloatMarks
    linksOpenNewWindow
    openGoToUrlWindow
    (-)
    alwaysOpenFrames
    autoAdjustWidth
    ignoreForms
    ignoreImages
    rememberWindowGeometry
    (-)
    centerRefreshOnNav
    searchUsingSelection
    (-)
}

foreach pref [lsort -dictionary [array names WWWmodeVars]] {
    if {[regexp {Links|Applets} $pref]} {
	lappend wwwMenuVars(prefsInMenu) $pref
    }
}
unset pref

# ===========================================================================
# 
# ××××   Url/Var Prefs ×××× #
# 

if {![WWW::httpAllowed]} {
    # This local file or remote url will be opened by the "Home Page" menu item.
    newPref url homePage [file::toUrl [file join $HOME Help "HTML Help" HTMLmanual.html]] WWW
} else {
    # This local file or remote url will be opened by the "Home Page" menu item.
    newPref url homePage "http://www.purl.org/net/alpha/wiki/" WWW
    # Command double-clicking will send the highlighted text to this search
    # engine.
    newPref url searchUrl1 {http://www.google.com/search?q=} WWW
    # Command double-clicking while pressing the "option" key will send the
    # highlighted text to this search engine.
    newPref url searchUrl2 {http://search.metacrawler.com/crawler?general=} WWW
    # Command double-clicking while pressing the "control" key will send the
    # highlighted text to this search engine.
    newPref url searchUrl3 {http://www.altavista.com/sites/search/web?q=} WWW
    # Command double-clicking while pressing the "shift" key will send the
    # highlighted text to this search engine.
    newPref url searchUrl4 {http://google.yahoo.com/bin/query?p=} WWW

    if {$tcl_platform(platform) != "unix"} {
	# Default font to use for new WWW windows
	newPref var wwwFont     $defaultFont WWW $rFW "system monaco courier geneva helvetica profont times {new york} programmer"
	# Default font size to use for new WWW windows
	newPref var wwwFontSize $fontSize    WWW $rFW "7 9 10 12 14 18"
    } else {
	# Default font to use for new WWW windows
	newPref var wwwFont     $defaultFont WWW $rFW "system fixed monaco courier geneva helvetica profont times {new york} programmer"
	# Default font size to use for new WWW windows
	newPref var wwwFontSize $fontSize    WWW $rFW "7 9 10 12 14 18"
    }
    lappend wwwMenuVars(refreshPrefs) "wwwFont" "wwwFontSize"
    # These bindings are for the "WWW Menu --> Search Engines" submenu.
    newPref menubinding wwwSearch1 "/t<O" WWW {WWW::rebuildMenu}
    newPref menubinding wwwSearch2 "/t<I" WWW {WWW::rebuildMenu}
    newPref menubinding wwwSearch3 "/t<U" WWW {WWW::rebuildMenu}
    newPref menubinding wwwSearch4 ""     WWW {WWW::rebuildMenu}
}

# This is the maximum width used before wrapping text when rendering windows.
newPref var fillColumn          75  WWW
# The maximum number of items remembered in the History cache.  Once this
# limit is exceeded, older items are forgotten.  Items in the History cache
# will be remembered as "Visited Links" when rendering windows.
newPref var historyLimit        300 WWW {WWW::truncateHistory}
# The number of days to remember history items.  If this preference is
# empty, history items will be remembered until deleted by exceeding
# the "History Limit" preference.
newPref var historyDays         20  WWW {WWW::truncateHistory}
# The "Marks" menu will include header items up to this level.
newPref var markHeadingsToLevel 3   WWW $rFW {1 2 3 4 5 6} item
# The key binding to switch among open WWW windows.
newPref binding prevWwwWindow "/;" WWW {} {WWW::prevBrowserWindow}
# These are the default parameters of the "Go To Url" window.
newPref var wwwShellWindowSize [list $defLeft $defTop $tileWidth 125] WWW

# This is best set automatically.
prefs::deregister wwwShellWindowSize WWW

lappend wwwMenuVars(refreshPrefs) "markHeadingsToLevel"

if {(${alpha::platform} eq "tk")} {
    # In Alphatk, shadow, outline, and all turn text blue, so they
    # aren't very useful as options here.
    set wwwHeaderStyles [list bold underline italic - normal]
    set wwwHeader1      "underline"
    set wwwHeader2      "bold"
    set wwwHeader3      "underline"
} else {
    set wwwHeaderStyles [list shadow outline bold underline italic - normal]
    set wwwHeader1      "outline"
    set wwwHeader2      "bold"
    set wwwHeader3      "underline"
}

newPref var header1Style $wwwHeader1 WWW $rFW $wwwHeaderStyles
newPref var header2Style $wwwHeader2 WWW $rFW $wwwHeaderStyles
newPref var header3Style $wwwHeader3 WWW $rFW $wwwHeaderStyles

unset wwwHeaderStyles wwwHeader1 wwwHeader2 wwwHeader3

newPref color header1Color     blue     WWW $rFW
newPref color header2Color     red      WWW $rFW
newPref color header3Color     red      WWW $rFW
newPref color linkColor        green    WWW $rFW
newPref color visitedLinkColor magenta  WWW $rFW

lappend wwwMenuVars(refreshPrefs) "header1Color" "header2Color" "header3Color" \
  "linkColor" "visitedLinkColor"

if {[WWW::httpAllowed]} {
    newPref color formsColor   blue     WWW $rFW
    lappend wwwMenuVars(refreshPrefs) "formsColor"
}

unset rFW pBM

# ===========================================================================
# 
# Create categories of WWW Menu prefs, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# WWW Windows
prefs::dialogs::setPaneLists "WWW" "WWW Windows" [list \
  "autoAdjustWidth" \
  "fillColumn" \
  "ignoreForms" \
  "ignoreImages" \
  "rememberWindowGeometry" \
  "wwwFont" \
  "wwwFontSize" \
  ]

# Navigation
prefs::dialogs::setPaneLists "WWW" "Navigation" [list \
  "alwaysOpenFrames" \
  "autoFloatMarks" \
  "centerRefreshOnNav" \
  "ftpLinksInternal" \
  "homePage" \
  "httpLinksInternal" \
  "linksOpenNewWindow" \
  "markHeadingsToLevel" \
  "prevWwwWindow" \
  "runJavaAppletsDirectly" \
  "wwwSendRemoteLinks" \
  ]

# Link Colors
prefs::dialogs::setPaneLists "WWW" "Link Colors" [list \
  "linkColor" \
  "visitedLinkColor" \
  "formsColor" \
  "historyDays" \
  "historyLimit" \
  ]

# Headings
prefs::dialogs::setPaneLists "WWW" "Headings" [list \
  "header1Color" \
  "header1Style" \
  "header2Color" \
  "header2Style" \
  "header3Color" \
  "header3Style" \
  ]

# Url Location Window
prefs::dialogs::setPaneLists "WWW" "Url Location Window" [list \
  "electricUrlCompletions" \
  "openGoToUrlWindow" \
  ]

# Search Urls
prefs::dialogs::setPaneLists "WWW" "Search Urls" [list \
  "searchUrl1" \
  "searchUrl2" \
  "searchUrl3" \
  "searchUrl4" \
  "searchUsingSelection" \
  "wwwSearch1" \
  "wwwSearch2" \
  "wwwSearch3" \
  "wwwSearch4" \
  ]

# This is called when the user changes the font, fontsize, etc.
proc WWW::refreshFrontWindow {args} {

    global wwwMenu wwwMenuVars alpha::macos

    set m [WWW::getWindowMode]
    set q "Refresh the current window?\r('[lindex $args 0]' pref has changed.)"
    if {($m ne "WWW") || [win::Current] eq $wwwMenuVars(historyTitle)} {
	set refresh 0
    } elseif {![llength $args]} {
	set refresh 1
    } elseif {[askyesno $q]} {
	set refresh 1
    } else {
	set refresh 0
    }
    if {$refresh} {
	WWW::menuProc $wwwMenu "refresh"
    } elseif {[set alpha::macos]} {
	status::msg "Use <command>-R to refresh the current window."
    } else {
	status::msg "Use <alt>-R to refresh the current window."
    }
    WWW::postBuildMenu
    return
}

# ===========================================================================
# 
# ×××× Links, History Vars ×××× #
# 
# Any vars that MUST be in place in order for the menu to be properly built
# or for menu items to work should be set here, to avoid calling support
# files unnecessarily when this mode or the menu is first initialized.
# 
# Use 'ensureset' in case we decide that we want to save any of these between
# editing sessions, or we are reloading this file during development or while
# debugging the package.
# 

# Set this var to "1" if you're debugging any of this code.
ensureset wwwMenuVars(debugging) 0

# This was the old name of the history var.
prefs::renameOld WWW::History wwwMenuVars(history)

ensureset wwwMenuVars(goToPages)     ""
ensureset wwwMenuVars(goToPagePos)   -1
ensureset wwwMenuVars(visited)       ""
ensureset wwwMenuVars(history)       [list \
  [list "History start" [lindex [mtime [now] short] 0] [now]]]
ensureset wwwMenuVars(historyTitle)  "* WWW History *"
ensureset wwwMenuVars(lastWindow)    ""
ensureset wwwMenuVars(targetWindows) [list]

prefs::modified wwwMenuVars(history)

# This one gets set fresh every time we initialize.
set wwwMenuVars(uniqueHistory)     [list $WWWmodeVars(homePage)]

# To perform a special action with a new URL type, add an array entry
# indicating the procedure to be called with the regexp of the URL. Patterns
# which do NOT start with '^' are checked first, see 'WWW::link' for more
# information.  Packages which define url handlers will not have their
# regexps over-written here, so long as they've been defined before this file
# is sourced.  It is up to individual url handlers to decide if the action
# should be dealt with internally or shipped off to internet config, possibly
# with a user preference for the action (such as those defined above.)

ensureset WWW::UrlAction(^mailto:)   "WWW::mailLink"
ensureset WWW::UrlAction(^ftp://)    "WWW::ftpLink"
ensureset WWW::UrlAction(^error:)    "WWW::errorLink"
ensureset WWW::UrlAction(^file://)   "WWW::fileLink"
ensureset WWW::UrlAction(^http://)   "WWW::httpLink"
ensureset WWW::UrlAction(^https://)  "WWW::externalLink"

ensureset WWW::UrlAction(\.class\$)  "WWW::javaLink"
ensureset WWW::UrlAction(\.java\$)   "WWW::javaLink"

# We know that we can't handle any of these files internally.  It might be
# possible to do something special with .zip files using the vfs package.

foreach suffix [list aiff au bin dmg gif gz hqx jpe jpeg jpg mov mpeg mpg \
  pdf pict png ps sit tif tiff zip] {
    ensureset WWW::UrlAction(\.$suffix\$) "WWW::externalLink"
}

unset suffix

# This is how we can completely redirect some tags to procs, conceivably
# bypassing 'WWW::link' altogether.

ensureset WWW::UrlAction(WWW::indexSearch) "WWW::indexSearch"
ensureset WWW::UrlAction(WWW::formLink)    "WWW::formLink"

# These are the default parameters used for new WWW browser windows.
if {!$WWWmodeVars(rememberWindowGeometry)} {
    set WWW::WindowParameters(Default) \
      [list $defLeft $defTop $defWidth $defHeight]
} else {
    ensureset WWW::WindowParameters(Default) \
      [list $defLeft $defTop $defWidth $defHeight]
}
prefs::modified WWW::WindowParameters(Default)


# ===========================================================================
# 
# ×××× Bindings ×××× #
# 

# ===========================================================================
# 
# Bind various keys to imitate lynx.  Please route everything through the
# menu procs to ensure consistent handling.
# 
#  +++ Keystroke Commands	+++
# 
#  MOVEMENT:  
#  
#  Down arrow    - Highlight next topic
#  Up arrow      - Highlight previous topic
#  Right arrow   - Jump to highlighted topic
#  Return, Enter - Jump to highlighted topic
#  Left arrow    - Return to previous topic
# 
#  SCROLLING: 
#  
#  +             - Scroll down to next page (Page-Down)
#  -             - Scroll up to previous page (Page-Up)
#  SPACE         - Scroll down to next page (Page-Down)
#  b             - Scroll up to previous page (Page-Up)
#  CTRL-A        - Go to first page of the current document (Home)
#  CTRL-E        - Go to last page of the current document (End)
#  CTRL-B        - Scroll up to previous page (Page-Up)
#  CTRL-F        - Scroll down to next page (Page-Down)
#  CTRL-N        - Go forward two lines in the current document
#  CTRL-P        - Go back two lines in the current document
#  )             - Go forward half a page in the current document
#  (             - Go back half a page in the current document
#  
#  Some letters (without modifiers) are also bound to functions.
#  

# Add a bookmark for the current window by pressing 'a'
Bind  'a'       {WWW::navigationProc bookmarks addBookmark} WWW
# Go back one page in the history by pressing 'b'
Bind  'b'       {WWW::navigationProc goToPage back}         WWW
# Copy the location of the current hyperlink by pressing 'c'
Bind  'c'       {WWW::menuProc "" copyLinkLocation}         WWW
# Open the local file of the current hyperlink to edit it by pressing 'e'
Bind  'e'       {WWW::menuProc "" editLinkedDocument}       WWW
# Go forward one page in the history by pressing 'f'
Bind  'f'       {WWW::navigationProc goToPage forward}      WWW
# Open a list-pick dialog with all items in the "Go To" menu by pressing 'g'
Bind  'g'       {WWW::navigationProc goToPage ""}           WWW
# Reload the current window from its source by pressing 'r'
Bind  'r'       {WWW::menuProc "" reload}                   WWW
# Refresh the current window from its local source by pressing <command> 'r'
Bind  'r' <c>   {WWW::menuProc "" refresh}                  WWW
# Open the WWW History window by pressing 'h'
Bind  'h'       {WWW::menuProc "" history}                  WWW
# Open the defined Home page by pressing <command>-'h'
Bind  'h' <c>   {WWW::menuProc "" home}                     WWW
# Open the local source of the current window by pressing 'o'
Bind  'o'       {WWW::menuProc "" openSourceInAlpha}        WWW
# Send the source url of the current window to your browser by pressing 's'
Bind  's'       {WWW::menuProc "" sendSourceToBrowser}      WWW
# Open a 'Go To Url' shell window, in which you can type urls with electric
# completions to open new WWW browser window locations, by pressing 'u'
Bind  'u'       {WWW::menuProc "" goToUrlWindow}            WWW
# Open a "View Url" dialog by pressing 'v'
Bind  'v'       {WWW::menuProc "" viewUrl}                  WWW

Bind 0x73 <c>   {WWW::menuProc "" home}                     WWW

Bind Home       {WWW::navigationProc "" Home}               WWW
Bind End        {WWW::navigationProc "" End}                WWW

# These might be annoying ...

# # Go to the top of the current window by pressing <control> 'a'
# Bind  'a' <z>   {WWW::navigationProc "" Home}               WWW
# # Go to the bottom of the current window by pressing <control> 'e'
# Bind  'e' <z>   {WWW::navigationProc "" End}                WWW

Bind  '+'       {WWW::navigationProc "" PageForward}        WWW
Bind  '-'       {WWW::navigationProc "" PageBack}           WWW

Bind  'n' <z>   {WWW::navigationProc "" fiveLinesForward}   WWW
Bind  'p' <z>   {WWW::navigationProc "" fiveLinesBack}      WWW
Bind  ')'       {WWW::navigationProc "" halfPageForward}    WWW
Bind  '('       {WWW::navigationProc "" halfPageBack}       WWW

Bind 0x7c       {WWW::menuProc "" selectLink}               WWW
Bind 0x24       {WWW::menuProc "" selectLink}               WWW
Bind 0x34       {WWW::menuProc "" selectLink}               WWW

Bind 0x7b       {WWW::navigationProc goToPage back}         WWW
Bind '\[' <c>   {WWW::navigationProc goToPage back}         WWW
Bind '\]' <c>   {WWW::navigationProc goToPage forward}      WWW

# These are common bindings (<command> arrow keys) on non-Lynx browsers.  
Bind 0x7b <c>   {WWW::navigationProc goToPage back}         WWW
Bind 0x7c <c>   {WWW::navigationProc goToPage forward}      WWW

Bind 0x30       {WWW::navigationProc "" down}               WWW
Bind 0x7d       {WWW::navigationProc "" down}               WWW

Bind 0x30 <z>   {WWW::navigationProc "" up}                 WWW
Bind 0x7e       {WWW::navigationProc "" up}                 WWW

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× More mode stuff ×××× #
# 

# A little bit of color.
regModeKeywords -k white WWW [list "-*-WWW-*-"]

proc WWW::DblClick {from to shift option control} {
    
    if {![WWW::httpAllowed]} {
        status::msg "Command double click is not yet implemented."
	return
    }
    
    global WWWmodeVars
    
    if {![catch {WWW::getCurrentLink} result]} {
	WWW::link [lindex $result 3]
    } else {
	selectText $from $to
	set text [getSelect]
	# Any modifiers pressed?
	if {$option} {
	    WWW::searchProc "" wwwSearch2 $text
	} elseif {$control} {
	    WWW::searchProc "" wwwSearch3 $text
	} elseif {$shift} {
	    WWW::searchProc "" wwwSearch4 $text
	} else {
	    WWW::searchProc "" wwwSearch1 $text
	}
    }
    return
}

# Marks should be set be whatever proc is creating a WWW window, and
# then store them in a WWW::Marks cache.  This is simply to avoid the
# annoyance of wiping out the set of marks previously set.

proc WWW::MarkFile {args} {
    
    win::parseArgs win
    
    variable Marks
    
    if {![info exists Marks([set title $win])]} {
	status::msg "No marks found in '$title'."
	return
    }
    foreach mark $Marks($title) {
	set name [lindex $mark 0]
	set pos0 [lindex $mark 1]
	set pos1 [lindex $mark 2]
	set pos2 [lindex $mark 3]
	setNamedMark -w $win $name $pos0 $pos1 $pos2
    }
    if {![set count [llength $Marks($title)]]} {
	status::msg "'$title' doesn't contains any marks."
    } elseif {($count == "1")} {
	status::msg "'$title' contains $count mark."
    } else {
	status::msg "'$title' contains $count marks."
    }
    return
}

proc WWW::parseFuncs {} {

    if {[llength [set links [WWW::getLinks]]] > 100} {
        lappend results [list "Too many links" [getPos]]
    } else {
	foreach link $links {
	    set pos0 [lindex $link 0]
	    set pos1 [lindex $link 1]
	    set name [markTrim [getText $pos0 $pos1]]
	    lappend results [list $name $pos0]
	}
    }
    return [join [lsort -dictionary $results]]
}

proc WWW::OptionTitlebar {} {
    
    variable TodaysPages
    
    return [lsort -dictionary [array names TodaysPages]]
}

proc WWW::OptionTitlebarSelect {itemName} {
    
    variable TodaysPages
    
    WWW::goToPage [lindex [set WWW::TodaysPages($itemName)] 0] $itemName
    return
}

# Title bar hook procedures.

proc WWW::titlebarPathHook {w} {
    
    variable UrlSource
    
    if {[info exists UrlSource($w)]} {
	menu::buildOne wwwPathMenu
	return "wwwPathMenu"
    } else {
	error "Could not identify source url of \"${w}\""
    }
}

proc WWW::titlebarListHook {w} {
    
    variable UrlSource
    
    if {[info exists UrlSource($w)]} {
	return [list $UrlSource($w)]
    } else {
	error "Could not identify source url of \"${w}\""
    }
}

proc WWW::titlebarSelectHook {args} {
    
    variable UrlSource
    
    set w [win::Current]
    if {[info exists UrlSource($w)]} {
	putScrap $UrlSource($w)
	status::msg "Copied the source url of \"${w}\"\
	  to the clipboard."
	return 1
    } else {
	return 0
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Registering Hooks ×××× #
# 

# Register quit hook.
hook::register "quitHook" {WWW::quitHook}

proc WWW::quitHook {} {

    temp::cleanup WWW-fetch
    temp::cleanup WWW-parse

    return
    
    # This section is experimental, related to the saving of rendered web
    # pages and trying to open them and properly navigate links and such.  In
    # order for it to really work, we also need to define "winChangedNameHook"
    # and "saveHook" procs so that the information is properly registered and
    # saved between editing sessions.
    set wwwArrays [list Colors Links LinksReverse Marks Forms Anchors \
      UrlSource FileSource ParseNumber TitleParse]
    
    foreach item $wwwArrays {
	global WWW::${item}
	eval [list lunion wwwNames] [array names WWW::${item}]
    }
    foreach winName $wwwNames {
	if {![string length $winName]} {
	    continue
	}
	foreach item $wwwArrays {
	    if {![info exists WWW::${item}($winName)]} {
		continue
	    }
	    prefs::modified WWW::${item}($winName)
	    if {![win::IsFile $winName]} {
		unset WWW::${item}($winName)
	    }
	}
    }
}

# ===========================================================================
# 
# .