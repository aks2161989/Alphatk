## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "alphaDefinitions.tcl"
 #                                    created: 00-12-18 17.00.44 
 #                                last update: 03/29/2006 {10:49:11 PM}
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Reorganisation carried out by Vince Darley with much help from Tom
 # Fetherston, Johan Linde and suggestions from the alphatcl-developers
 # mailing list.  Alpha is shareware; please register with the author
 # using the register button in the about box.
 #  
 # ###################################################################
 ##

proc alpha::getDefinitions {} {}

# To allow easier migration between releases.  Future candidates for
# variables to be unlinked are horScrollBar, tabSize,...
if {$alpha::platform eq "tk" \
  || [alpha::package vcompare ${::alpha::version} 8.0b15-D7] >= 0} {
    set Unlinked ""
} else {
    set Unlinked "link"
}

foreach m [mode::listAll] {
    if {[info exists ${m}modeVars(wordWrap)]} {
	prefs::renameOld ${m}modeVars(wordWrap) ${m}modeVars(lineWrap)
    }
}
unset -nocomplain m

# autoSave and changesLim combined into one preference.
if {[info exists autoSave] && $autoSave} {
    if {[info exists changesLim] && $changesLim ne ""} {
	prefs::renameOld changesLim numberOfChangesBeforeAutoSave
    }
}
prefs::removeObsolete autoSave changesLim

ensureset allFlags {}
ensureset allVars {}

# ◊◊◊◊ Global preferences ◊◊◊◊ #

# To color words according to mode and context, click this box||To display all 
# text more quickly, but in plain black and white, click this box.
newPref linkflag coloring 1
# To display a horizontal scrollbar in new windows, click this box||To make 
# maximum use of window space and not use a horizontal scrollbar, click this box.
newPref linkflag horScrollBar 1
# To enable clicking on hypertext items, click this box||To disable clicking
# on hypertext items, click this box
newPref linkflag hyperText 1
# To force the insertion point to move with 'pageBack' and 'pageForward' 
# commands, click this box||To leave the insertion point in place (usually 
# offscreen) after 'pageBack' and 'pageForward' commands, click this box
newPref linkflag moveInsertion 1
# To list all file types (as opposed to just 'TEXT') in open/save dialog 
# boxes, click this box||To display only 'TEXT' files in open/save dialog 
# boxes, click this box.
newPref linkflag openAllFiles 0

# This is hard-coded in Alpha 8/X at present.
if {$alpha::macos && ($alpha::platform == "tk")} {
# To make Alpha take ownership of files when they are saved, click this
# box||To leave file ownership untouched when saving, click this box.
newPref linkflag changeTypeAndCreatorOnSave 0
}

if {$alpha::macos} {
# To use a small font for the various pop-up menus (e.g. marks menu), click this 
# box||To use the standard system font for the popup menus, click this box.
newPref linkflag smallMenuFont 1
}
# To allow tearing off of menus, click this box||To disable tearing-off of
# menus, click this box
newPref linkflag tearoffMenus \
  [expr {(${alpha::platform} != "tk") && (${alpha::macos} != 2)} ? 1 : 0]
# To retain editing information to allow undo/redo operations, click this box||
# To edit destructively (saving memory, and operating a little faster in, for 
# example global replaces), click this box.
newPref linkflag undoOn 1

set lineWrapStyles [list "none" "auto"]
if {${alpha::platform} == "tk"} {
    # Alphatk supports true soft wrapping by character or by word.
    lappend lineWrapStyles "visual-char" "visual-word"
}
# Line wrapping is the process of automatically inserting a
# carriage-return when you exceed a line length of 'Fill Column'
# characters.  Select your line wrap style here.
newPref variable lineWrap 1 global "" $lineWrapStyles index
# To have completion routines ask you before deleting the current
# selection, click this box.||To have completion routines automatically
# delete any existing selection when performing completions, click this box.
newPref flag askDeleteSelection 0
# To force newly opened windows onto the main screen, click this box||To allow
# new windows to be opened anywhere, including off screen, click this box.
newPref flag forceMainScreen 1
# To sort the items in the popup function menu '{}', click this box||To leave
# the items in the popup function menu '{}' in the order in which they appear,
# click this box.
newPref flag sortFuncsMenu 1
# To place two spaces after a '.', '!', or '?'  at the end of each sentence
# when filling blocks of text, click this box|| To place only a single
# space after a '.', '!', or '?''  at the end of each sentence when 
# filling blocks of text, click this box 
newPref flag doubleSpaces 1
# To choose from a listbox of possible completions if you try to 
# complete a command for which no unique
# suffix exists, click this box.||To abort the completion if no
# unique suffix exists, click this box.
newPref flag listPickIfMultCmps 1
# To make Alpha beep when it asks you for something in the status bar, 
# click this box.||To turn off the alert beep when using the status
# bar, click this box.
newPref flag promptNoisily 0
# To prompt in the status bar if possible (rather than use a dialog),
# click this box.||To use dialogs in preference to the status bar for
# user input, click this box.
newPref flag useStatusBarForPrompts 0
# When creating files or uploading through the various ftp facilities,
# try to save files with this eol format.  Note that some external ftp
# clients may translate eols for you as they up/download.
newPref var useFtpEolType unix global "" [list auto mac unix dos]
# Alpha will visually indent code by this many characters to indicate
# its structure.  The whitespace used for indentation may be composed
# of spaces and/or tabs depending on the window's tab size.
newPref var indentationAmount 4
# Where Alpha places the insertion cursor after a line has been
# automatically indented
newPref var positionAfterIndentation 1 global "" \
  [list "at first non-whitespace character" "unchanged unless line is empty"] index
# If we have fewer than this many items in the opt-titlebar-menu,
# add the contents of the current directory
newPref var minItemsInTitlePopup 5
# The tiling items in the 'Arrange' menu will relocate this many
# windows, starting with the front window and moving back.
newPref var numWinsToTile 2

# ◊◊◊◊ Window dimensions ◊◊◊◊ #

# Defined in "initAlphaTcl.tcl" if possible.
if {![prefs::isRegistered "locationOfStatusBar"]} {
    newPref earlylinkvar locationOfStatusBar \
      [expr {$tcl_platform(platform) ne "macintosh"}] \
      global "win::statusBarLocationChanged ; #" \
      [list "Status Bar At Bottom Of Screen" "Status Bar Under Menus"] index
}

if {![info exists pixelOffsetFromBottomOfWindow]} {
    set pixelOffsetFromBottomOfWindow 0
}
# This already exists in Alphatk and Alpha8/X 8.0b12, so I think the
# value (42) assigned here is not ever used.
if {![info exists menubarHeight]} {
    set menubarHeight 22
}
# Alphatk sets this.  Alpha 8/X still need updating
if {![info exists titlebarHeight]} {
    set titlebarHeight 22
}
# Alphatk sets this.  Alpha 8/X still need updating
if {![info exists statusbarHeight]} {
    set statusbarHeight 15
}
# The fraction of the screen to use for the main window when tiling
# two windows unequally.
newPref var tileProportion .60
# The fraction of the screen the small batch-search, or diff-style 
# windows use up.
newPref var batchListWindowFraction 0.25 global "win::SetProportions ; #"
# If set, then this geometry will over-ride the normal window shape
# which is calculated on the fly based on your screen resolution,
# status-bar position, theme, etc.
newPref geometry windowGeometry {} global "win::SetProportions ; #"

if {$alpha::platform == "alpha"} {
    # Need to link all of these to Alpha's core.
    foreach v {
	defTop defLeft defHeight defWidth
	tileTop tileLeft tileHeight tileWidth
    } {
	linkVar $v
    }
    unset v
}

# End window dimensions

# The type of keyboard you have.  This influences some of the keyboard
# shortcuts Alpha places in the menus, and is used for better setting
# of user-defined key-bindings.
newPref variable keyboard US global keys::keyboardChanged keyboards array
# Re-read internet preferences from your system settings at each startup
newPref flag synchroniseInternetPrefsWithSystem 0
# The font to use for printing documents
newPref linkvariable printerFont "" global "" "system monaco courier geneva helvetica profont times {new york}"
# The font-size to use for printing documents.
newPref linkvariable printerFontSize "" global "" "7 9 10 12 14 18 20 24 30"
# The default size for a tab character for new windows (not necessarily
# the same as the amount of space used for visual indentation of code).
# Alpha can be configured to remember tab sizes for previously edited
# documents -- see 'savedState' for details.
newPref linkvariable tabSize 8
# This controls whether every comment char is detected ('anywhere'), or
# if it is only detected at line start modulo whitespace ('spaces
# allowed'), or only at proper line start ('only at line start').  For
# most modes, the global default setting of 'anywhere' is adequate
# according to syntax, but the user may prefer to override this,
# according to typing habits.  Fortran syntax requires 'only at line 
# start'.  For Text and Mail modes, where comment characters may also appear
# mid sentence, it should be set to 'spaces allowed', to avoid those
# auto-continue-comment things like where an embedded '>' can cause
# strange results when pressing <return>.
newPref v commentsContinuation 2 global "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
# To save files automatically (except untitled buffers) after a certain
# number of editing changes, set this to the number of changes after 
# which you would like the file to be saved.  Set to the empty string
# to disable auto-saving. 
newPref variable numberOfChangesBeforeAutoSave ""
# When wrapping text (see 'Line Wrap' preference), wrapping occurs for
# any text at or beyond this column position (where column counting
# starts from zero at the left window edge).  Used by all 'Fill'
# routines
newPref variable fillColumn 75
# Number of blanks left at beginning of lines by 'fill' routines.
newPref variable leftFillColumn 0
if {$alpha::platform == "alpha"} {
# Alpha asks the user if wrapping should be done whenever the user opens 
# files that have lines longer than 'paraColumn' characters
newPref linkvariable paraColumn 180
# Regexp used for automatic line wrapping
#newPref variable wrapBreak {[\w_]+}
# Regexp used for automatic line wrapping
#newPref variable wrapBreakPreface {([^\w_])}

# Auto-wrap if the user types further than this column
#newPref variable wrapHigh ""
# Auto-un-wrap if the user deletes chars so a line is shorter than this
#newPref variable wrapLow ""
}

# These three variables only exists in Alpha 8 on classic, which
# has its own inbuilt print routines.
if {$alpha::platform == "alpha" && $alpha::macos == 1} {
# Margin size for printing
newPref linkvariable leftMargin ""
# Margin size for printing
newPref linkvariable bottomMargin ""
# Margin size for printing
newPref linkvariable topMargin ""
}
if {($alpha::platform == "alpha" && $alpha::macos == 1) || $tcl_platform(platform) == "windows"} {
# To print a header at the top of each printed page, click this box||
# To print only the contents of the window, without any identifying header,
# click this box.
newPref flag printHeader 1
# To include a file's full path in the printed header, click this box
# ||To place just a file's name in the printed header, click this box
newPref flag printHeaderFullPath 0
# To include the current time in printed headers, click this box
# ||To remove the current time from printed headers, click this box
newPref flag printHeaderTime 1
}

# Regular expression used to defines words for all internal operations.  Most
# modes have their own definition of this variable.
newPref linkvariable wordBreak {\w+}

# Usual place you use for downloading updates to Alpha and its packages.
newPref var defaultAlphaDownloadSite "" global "" alpha::downloadSite array
# bug in alpha-IC interaction
if {![catch "icGetPref DownloadFolder" res] && [file exists $res]} {
# Default download location for files from the internet
newPref var downloadFolder $res
} else {
    if {[info exists ::env(HOME)] && ($alpha::macos == 2)} {
	newPref var downloadFolder [file join $::env(HOME) Desktop]
    } else {
	newPref var downloadFolder [file dirname $HOME]
    }
}
unset res

# The 'twiddle' and 'twiddle words' operations can follow a variety
# of user preferences.  Select your preferred mode of operation here.
newPref variable twiddleAdjusts 0 global "" [list \
  "Either side of cursor" \
  "Characters before cursor" \
  "Non-space characters before cursor"] index

# To use a solid rectangular cursor, click this box||To use a thin vertical 
# cursor, click this box.
newPref linkflag blockCursor 0

# ◊◊◊◊ Alpha-only preferences ◊◊◊◊ #

if {${alpha::platform} == "alpha"} {
# To make the cursor blink, click this box||To stop the cursor blinking, 
# click this box
newPref linkflag blinkingCursor 1
# To use shorter menus in which similar items are shown as a single item
# which changes when you hold down 'option', 'control' etc, click this box||
# To display all menu items
# clearly, without the requirement for holding down 'option', 'control' 
# etc, click this box.
newPref linkflag useDynamicMenus 1 global \
  [list menu::buildSome "File" "Edit" "Text" "Search" "Utils" "Config"]
if {$tcl_platform(platform) != "macintosh"} {
# To use Quickdraw Text Antialiasing (if possible), click this box
# ||To not use Quickdraw Text Antialiasing, click this box
newPref earlylinkflag useAntialiasedText 1
} else {
# To use the newer 'Navigation Services' file open/save dialogs
# if possible, click this box
# ||To use the old 'Standard File Dialogs', click this box
newPref flag useNavServices 1
}
# To make the window scroll dynamically while using vertical scrollbars, 
# click this box||To make the window scroll only after releasing the button 
# in a vertical scrollbar, click this box
newPref linkflag powerThumb 1

if {[alpha::package vcompare ${::alpha::version} 8.0b17d4] >= 0} {
prefs::renameOld projectorAware versionControlAware
# Respect a file's ckid "version-control" resources when it is opened.  This
# preference also changes the default "Version-Control Aware" checkbox value
# in the "File > Open" dialog.
newPref linkflag versionControlAware 1
lunion flagPrefs(Files) versionControlAware
} else {
# Respect a file's ckid "version-control" resources when it is opened.  This
# preference also changes the default "Version-Control Aware" checkbox value
# in the "File > Open" dialog.
newPref linkflag projectorAware 1
lunion flagPrefs(Files) projectorAware
}

# To show all tabs, carriage returns, spaces etc with distinct symbols, 
# click this box||To display whitespace characters normally, click this box.
newPref linkflag showInvisibles 0
# The amount of information to store in the resource fork of saved text
# files.  This can include font, tab, selection,... information.  Here, 'think' 
# implies font, tab information, and 'mpw' adds window position and window
# selection.
newPref linkvariable savedState "" global "" "none mpw"
# To enable drag and drop editing using the mouse, click this box||To disable 
# drag and drop editing using the mouse, click this box.
newPref linkflag dragAndDrop 1
# To fix the position of the status bar, click this box.||To allow dragging
# of the status bar (usually at the bottom of the screen), click this box.
newPref linkflag lockStatus 1
# To scroll the horizontal scrollbar automatically to follow your typing, 
# click this box||To enforce manual use of the horizontal scroll bar,
# click this box.
newPref linkflag autoHScroll 1
# Catch in case not using latest dev release of AlphaX
catch {
# To allow for opening packages in the Get File dialog.
newPref linkflag openPackages 0
}
# To allow for displaying the invisible files in the Get File dialog.
newPref linkflag showInvisibleFiles 0
}

# ◊◊◊◊ Alphatk-only preferences ◊◊◊◊ #

if {${alpha::platform} == "tk"} {
# To display line numbers and other information in the left margin of
# each new window, click this box||To make maximum use of window
# space and not use a left margin, click this box.
newPref flag lineNumbers 0

# These should eventually be added to Alpha 8/X

# The default encoding to use for files for which we have no other
# information to suggest an encoding to use.
newPref var defaultEncoding ${alpha::defaultEncoding} global "" \
  "lsort -dictionary \[encoding names\]" cmditem
# List your preferred encodings here to have them appear first
# in the popup encoding menu.
newPref var preferredEncodings ""
lunion varPrefs(International) preferredEncodings defaultEncoding
}

# ◊◊◊◊ Complex preferences ◊◊◊◊ #

lappend alpha::fontList \
  system monaco courier geneva helvetica \
  profont times {new york} programmer
if {$tcl_platform(platform) == "windows"} {
    lappend alpha::fontList \
      "Courier New" "Lucida Console" "Quicktype Mono" \
      "ProFontWindows" "Sheldon" "Sheldon Narrow"
} elseif {$tcl_platform(platform) == "unix"} {
    lappend alpha::fontList "fixed"
}
# Alphatk has a command to list all fixed width fonts
if {[llength [info commands alpha::getFontList]]} {
    foreach f [alpha::getFontList] {
	if {[lsearch -exact $alpha::fontList $f] == -1} {
	    lappend alpha::fontList $f
	}
    }
    unset -nocomplain f
}

# We want this first branch for any brand of MacOS or MacOS X with the 
# aqua interface.
if {$tcl_platform(platform) == "macintosh" \
  || ${alpha::windowingsystem} == "aqua" || ${alpha::windowingsystem} == "alpha"} {
# Default font to use for new windows
newPref linkvariable defaultFont "monaco" global "" {set alpha::fontList} cmditem
# Default font size to use for new windows
newPref linkvariable fontSize 9 global "" "7 8 9 10 12 14 18 20 24 30"
} elseif {$tcl_platform(platform) == "windows"} {
# Default font to use for new windows
newPref linkvariable defaultFont "courier" global "" {set alpha::fontList} cmditem
# Default font size to use for new windows
newPref linkvariable fontSize 9 global "" "7 8 9 10 12 14 18 20 24 30"
} else {
# Default font to use for new windows
newPref linkvariable defaultFont "fixed" global "" {set alpha::fontList} cmditem
# Default font size to use for new windows
newPref linkvariable fontSize 10 global "" "7 8 9 10 12 14 18 20 24 30"
}

if {$tcl_platform(platform) == "unix"} {
    proc updateExecPath {args} {
	global execSearchPath env
	if {[info exists execSearchPath]} {
	    set existpath [split $env(PATH) "\;:"]
	    foreach path $execSearchPath {
		if {[lsearch -exact $existpath $path] == -1} {
		    set env(PATH) "$env(PATH):$path"
		}
	    }
	}
    }
    
    if {$alpha::macos} {
	# Extra filesystem locations to search for executables
	newPref var execSearchPath \
	  [list /usr/local/teTeX/bin/powerpc-apple-darwin-current \
	  /sw/bin /opt/local/bin /usr/local/bin] global updateExecPath
    } else {
	# Extra filesystem locations to search for executables
	newPref var execSearchPath "" global updateExecPath
    }
    updateExecPath
}

# Return the value of the environment variable 'var', as defined in the
# startup sequence of the shell 'shell'.  If no shell is specified, the
# user's default shell is used.
proc getEnvVarFromShell { var {shell ""} } {
    global env HOME
    
    if { $shell == "" } {
	if {![info exists env(SHELL)]} {
	    error "Unknown shell"
	}
	set shell $env(SHELL)
    } 
    set shell [file tail $shell]
    set script [file join $HOME Tools EnvVarScripts getEnvVar.$shell]
    if {[file exists $script]} {
	# Rather than exec the script directly in the shell, extract
	# its contents so we don't care about line-endings.
	set scriptContent [file::readAll $script]
	regsub -all -- {\\\$\$1} $scriptContent \$$var scriptContent
	if {![catch {exec $shell << $scriptContent} res]} {
	    return $res
	} else {
	    error "$var undefined: $res"
	}
    } else {
	error "Unknown shell"
    }
}

# xdvi support within Alpha needs a DISPLAY environment variable to be set.
if {$tcl_platform(platform) == "unix"} {
    if {![info exist env(DISPLAY)]} {
	set env(DISPLAY) ":0.0"
    }
}

# ◊◊◊◊ Helper Apps ◊◊◊◊ #

# get defaults from internet config
### das 13/11/03 disabled; c.f. bug 1223, two problems need to be solved:
### 1) this code only has an effect if preference files are read _before_
###    this file, which is not the case at present (c.f. runAlphaTcl.tcl).
### 2) as long as [file::getSig] uses AppleEvents, this code causes problems
###    at startup on Mac OS X (initial 'odoc' event lost, long delay if
###    AlphaX switched to bg during startup).  Either delay calling
###    [file::getSig] until later or change it to not use AEs.
if {${alpha::macos} && ([info tclversion] < 8.5)} {
    # Don't do anything due to the above bug caused by use of AE.
} else {
    # Code no longer uses apple-events in MacTcl 8.5, or on Unix/Win
    if {$synchroniseInternetPrefsWithSystem || ![info exists browserSig]} {  
	catch {set browserSig [file::getSig [icGetPref -t 1 Helper•http]]}
    }
    if {$synchroniseInternetPrefsWithSystem || ![info exists ftpSig]} {
	# xserv has replaced use of ftpSig
	#catch {set ftpSig [file::getSig [icGetPref -t 1 Helper•ftp]]}
    }
}

# The application signature of your internet browser
newPref sig browserSig [expr {${alpha::macos} ? "sfri" : "netscape"}]

set "eMailer(Choose each time)" \
  [list prefs::dialogs::chooseOption eMailer composeEmailUsing WWW]

set "eMailer(OS default emailer)" emailDefaultComposer

# Emails can be composed using the default composer for your OS or
# using Alpha's Mail menu.  This preference sets the default method
# for composing emails.
newPref var composeEmailUsing "Choose each time" global "" eMailer array

if {${alpha::platform} == "alpha"} {
# To open files as-is, without prompting the user to wrap them, click
# this box.||To prompt the user when opening files with very long lines,
# click this box.
newPref f neverWrapOnOpen 0
lunion flagPrefs(Files) neverWrapOnOpen
} else {
    set neverWrapOnOpen 0
}

# ◊◊◊◊ Prefs Categorization ◊◊◊◊ #

lunion flagPrefs(Backups)	undoOn
lunion varPrefs(Backups)	numberOfChangesBeforeAutoSave
lunion flagPrefs(Text)		hyperText doubleSpaces
if {[info exists dragAndDrop]} {
    lunion flagPrefs(Text) dragAndDrop
}
lunion varPrefs(Text)		lineWrap fillColumn leftFillColumn twiddleAdjusts
if {$alpha::platform == "alpha"} {
    lunion varPrefs(Text)	paraColumn 
}
lunion flagPrefs(Appearance)	blockCursor coloring sortFuncsMenu \
  tearoffMenus promptNoisily
if {[info exists smallMenuFont]} {
    lunion flagPrefs(Appearance) smallMenuFont
}
if {[info exists lineNumbers]} {
    lunion flagPrefs(Window) lineNumbers
}
lunion varPrefs(Window) locationOfStatusBar
if {${alpha::platform} == "alpha"} {
    lunion flagPrefs(Appearance) useDynamicMenus blinkingCursor
    if {$tcl_platform(platform) != "macintosh"} {
	lunion flagPrefs(Appearance) useAntialiasedText
    } else {
	lunion flagPrefs(Appearance) useNavServices
    }
}
lunion varPrefs(Appearance)	defaultFont fontSize tabSize 
lunion flagPrefs(Printer)	
lunion varPrefs(Printer)	printerFont printerFontSize
if {($alpha::platform == "alpha" && $alpha::macos == 1) || $tcl_platform(platform) == "windows"} {
lunion flagPrefs(Printer)	printHeader printHeaderFullPath printHeaderTime
}
if {$alpha::platform == "alpha" && $alpha::macos == 1} {
    lunion varPrefs(Printer) bottomMargin topMargin leftMargin
}
lunion flagPrefs(Window)	forceMainScreen horScrollBar \
  moveInsertion useStatusBarForPrompts
lunion varPrefs(Window)		minItemsInTitlePopup windowGeometry
lunion flagPrefs(Tiling)		
lunion varPrefs(Tiling)		numWinsToTile batchListWindowFraction \
  tileProportion 
lunion flagPrefs(Completions)	listPickIfMultCmps askDeleteSelection
lunion varPrefs(Completions)	elecStopMarker
lunion flagPrefs(Electrics)	
lunion varPrefs(Electrics)	indentationAmount positionAfterIndentation \
  commentsContinuation 
lunion flagPrefs(Files) openAllFiles
if {[info exists changeTypeAndCreatorOnSave]} {
    lunion flagPrefs(Files) changeTypeAndCreatorOnSave
}
lunion varPrefs(Files) 
lunion "flagPrefs(Helper Applications)"
lunion "varPrefs(Helper Applications)"
lunion flagPrefs(WWW) synchroniseInternetPrefsWithSystem
lunion varPrefs(WWW) defaultAlphaDownloadSite useFtpEolType downloadFolder \
  browserSig composeEmailUsing
lunion flagPrefs(International)
lunion varPrefs(International) keyboard
lunion flagPrefs(Packages)
lunion varPrefs(Packages) 
lunion flagPrefs(Errors)
lunion varPrefs(Errors) 
if {${alpha::platform} == "alpha"} {
    lunion flagPrefs(Appearance) showInvisibles 
    lunion flagPrefs(Window) powerThumb autoHScroll lockStatus
    lunion varPrefs(Window) savedState
    lunion flagPrefs(Files) openPackages showInvisibleFiles
}

proc alpha::addToPreferencePage {page args} {
    global varPrefs flagPrefs allFlags
    set vars [lremove -- $args $allFlags]
    set flags [lremove -- $args $vars]
    eval [list lunion varPrefs($page)] $vars
    eval [list lunion flagPrefs($page)] $flags
}

proc alpha::removeFromPreferencePage {page args} {
    global varPrefs flagPrefs allFlags
    set varPrefs($page)  [lremove -- $varPrefs($page) $args]
    set flagPrefs($page) [lremove -- $flagPrefs($page) $args]
    set allFlags         [lremove -- $allFlags $args]
    return
}


# ◊◊◊◊ Miscellaneous ◊◊◊◊ #

# The location of the Alpha-Bugzilla home page.  This is a global variable,
# not a preference.  We define it here so that all other code will have
# access to it.
set bugzillaHomePage \
  {http://www.purl.org/net/alpha/bugzilla/}

namespace eval indent {}

# if first item = code, then indent relative to code by given value of second arg
# if first item = fixed, then force indentation to given level
set indentationTypes [list "code 0" "code 4" "fixed 0"]

set indent::amounts [list "nothing" "half-indent" "full-indent"]

proc getFileSig {f} {
    getFileInfo $f arr
    if {[info exists arr(creator)]} {
	return $arr(creator)
    } else {
	return ""
    }
}

proc getFileType {f} {
    getFileInfo $f arr
    if {[info exists arr(type)]} {
	return $arr(type)
    } else {
	return "TEXT"
    }
}

namespace eval win {}

proc win::statusBarLocationChanged {} {
    global alpha::platform windowGeometry defTop
    if {${alpha::platform} == "tk"} {
	alpha::updateStatusLocation
    }
    # Build list of windows which were at 'defTop'
    set moveWins [list]
    foreach w [winNames -f] {
	if {[lindex [getGeometry $w] 1] == $defTop} {
	    lappend moveWins $w
	}
    }
    if {[llength $windowGeometry]} {
	global locationOfStatusBar statusbarHeight

	foreach {l t w h} [lrange $windowGeometry 1 end] {}
	if {$locationOfStatusBar} {
	    incr t $statusbarHeight
	} else {
	    incr t -$statusbarHeight
	}
	set windowGeometry [list -g $l $t $w $h]
	prefs::modified windowGeometry
	
    }
    win::SetProportions
    # Move all those windows to new 'defTop'
    foreach w $moveWins {
	moveWin $w [lindex [getGeometry $w] 0] $defTop
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::SetProportions" --
 # 
 #  Function which will be called when the user adjusts
 #  batchListWindowFraction (via the usual prefs mechanisms) or will be
 #  called by Alpha(tk)'s core if any underlying theme/style information
 #  changes which will affect window layout.
 #  -------------------------------------------------------------------------
 ##
proc win::SetProportions {} {
    global tileHeight tileWidth tileTop tileLeft \
      errorHeight errorDisp tileMargin batchListWindowFraction \
      menubarHeight titlebarHeight screenHeight screenWidth \
      pixelOffsetFromBottomOfWindow tcl_platform horMargin \
      locationOfStatusBar defTop defHeight defLeft defWidth \
      statusbarHeight windowGeometry

    # Default distance from left edge of screen to left edge of window.
    set tileLeft 0
    set tileWidth [expr {$screenWidth - 10}]
    set tileTop [expr {$menubarHeight + $titlebarHeight \
      + $locationOfStatusBar * $statusbarHeight}]
    # Default distance from top edge of screen to top edge of window.
    set defTop [expr {$menubarHeight + $titlebarHeight \
      + $locationOfStatusBar * $statusbarHeight}]
    # Since the height (as used by moveWin, sizeWin) doesn't include
    # the titlebar, we must subtract off various measures to get
    # the available screen area.
    set tileHeight [expr {$screenHeight - $statusbarHeight \
      - $titlebarHeight - $menubarHeight - $pixelOffsetFromBottomOfWindow}]
    # Default distance from left edge of screen to left edge of window.
    set defLeft 0
    # Default window height
    set defHeight $tileHeight
    # We should derive these numbers (510, 570) from some other
    # information, like the typical width of the standard font, or
    # something like that.  Perhaps the defWidth for each window
    # should actually depend dynamically on the font to be used
    # for that window?
    if {$tcl_platform(platform) == "windows"} {
	set defWidth [expr {$tileWidth > 570 ? 570 : $tileWidth}]
    } else {
	set defWidth [expr {$tileWidth > 510 ? 510 : $tileWidth}]
    }
    # This should be the window vertical decoration height which is the
    # titlebar height + the thickness of the window-bottom border.
    # Should be a derived variable from core-supplied information.
    set tileMargin [expr {$titlebarHeight + 2}]
    # Number of pixels from left edge of window to start of text.
    # Again, surely this should be either given by or derived from
    # core information.
    set horMargin 4

    # If the user has over-ridden things:
    if {[llength $windowGeometry]} {
	# 'dmy' for the '-g'
	foreach {dmy defLeft defTop defWidth defHeight} $windowGeometry {}
    }
    
    set th [expr {$tileHeight - $tileMargin}]
    set errorHeight [expr {int ($batchListWindowFraction * $th)}]
    set errorDisp [expr {int ((1- $batchListWindowFraction) * $th)}]
    return
}

if {$alpha::platform == "alpha"} {
# ===========================================================================
# 
# ◊◊◊◊ Numlock implementation ◊◊◊◊ #
# 
# The global variable "numLock" is linked to Alpha8/X's internals, and
# determines what happens when the user presses a numeric keypad key.  If the
# value of this variable is "1", then normal OS behavior takes place.  If it
# is "0", then anything bound to "Kpad1" "Kpad2" etc will be called.  The file
# "menusAndKeys.tcl" creates the global bindings, any mode can also define
# some mode-specific routine.
# 
# This keypad behavior can be toggled on/off by the user by
# 
# (1) Clicking on the "NLCK" button in the status bar window
# (2) Pressing Shift-Numlock(Clear) on the keypad
# (3) Calling the AlphaTcl proc [toggleNumLock] defined below
# 
# The first method changes the value of "numLock" automatically, and
# dims/enables the "NLCK" button in the status bar.  The remaining methods
# change the value via Tcl, and the [linkVar] magic takes care of the rest.
# 
# We call [prefs::modified] here to ensure that the user's setting is saved
# between editing sessions.  (Otherwise, using Method 1 doesn't save it.)
# Note that this does force the sourcing of "prefsHandling.tcl" if necessary,
# but that appears to take place before we get here anyway.
# 
# As of this writing, Alphatk has no access to keypad functions, so even
# though this variable and [toggleNumLock] are defined, Alphatk cannot change
# the behavior of the keypad.  See Bug# 427 for more information.
# 

# To use standard OS functions for the numeric keypad, turn this item on||
# To allow Alpha to define special functions for the numeric keypad, turn 
# this item off.
newPref linkflag numLock 1
# Always save this value between editing sessions.
prefs::modified numLock

proc toggleNumLock {} {
    global numLock
    set numLock [expr {1 - $numLock}]
}
# End 'alpha' block
}

# ============================================================================
# Declare these as knownVars in advance.  This list seems to be used just
# to ensure we have an exhaustive list of standard _global_ preferences
# so that anything not in this list (and not in any of the other
# predefined flagPrefs/varPrefs lists above) is placed in the 'Packages'
# or 'Helper Applications' global preferences page instead.  These items
# which are added to the list manually are therefore excluded from any
# dialog. 
lunion knownVars wordBreak
#if {$alpha::platform == "alpha"} {lunion knownVars wrapBreakPreface wrapBreak}

# 'mode' is set to nothing when we start up.
set mode ""
set encoding ""
set featureModes [list]

# keep count of number of dirty windows.
set win::NumDirty 0
set keyboard "U.S."
set oldkeyboard ""

#lunion texSigs OTEX *TEX *XeT MPS* TeXs
lunion browserSigs MOSS MSIE dogz OlG1 HTVW iCAB CHIM MOZZ sfri OPRA OWEB
#if {$alpha::macos == 1} {
#    lunion DiffSigs DifB Diff
#} elseif {$alpha::macos == 2} {
#    lunion DiffSigs DifB
#}

namespace eval keys {}

array set keys::specialProcs { 
    "Next Stop"             "ring::+"
    "Next Stop Or Indent"   "bind::IndentOrNextstop"
    "Complete"              "bind::Completion"
    "Prev Stop"             "ring::-"
    "Real Tab"              "insertActualTab"
    "nth Stop"              "ring::nth"
    "Clear All Stops"       "ring::clear"
    "Expand"                "bind::Expansion"
    "Typewriter Tab"        "bind::TypewriterTab"
}

array set keys::specialBindings {
    "Complete"             "<B/c"
    "Prev Stop"            "<U/c"
    "Real Tab"             "<I/c"
    "nth Stop"             ""
    "Clear All Stops"      "<U<B/c"
    "Next Stop"            ""
    "Next Stop Or Indent"  "/c"
    "Expand"               ""
    "Typewriter Tab"       ""
}

# Note: the Mercutio MDEF can only handle icon-suite resources
# with id's from 208 to 208+255 = 463.  Hence many of the little
# icons which Alpha contains cannot appear in menus.  You could
# of course do a little hacking....
set alpha::_icons {
    {DanR "Think Reference" 265}
    {OTEX "OzTeX" 266}
    {*TEX "TeXtures" 267}
    {XXXX "LaTeX" 270}
    {*XeT "CMacTeX" 272}
    {TeX+ "DirectTeX Pro" 299}
    {CWIE "Codewarrior" 268}
    {dogz "Cyberdog" 281}
    {Vbib "BibTeX" 282}
    {SLab "Scilab" 283}
    {IGR0 "Igor Pro" 284}
    {JAVC "Apple Applet Viewer" 285}
    {MOSS "Netscape Navigator" 293}
    {MOSS "Netscape Communicator" 294}
    {MSIE "Microsoft Internet Explorer" 295}
    {OlG1 "MacLynx" 296}
    {iCAB "iCab" 297}
    {Woof "NetFinder" 298}
    {DanR "Think Ref Viewer" 310}
    {gsVR "Ghostview" 311}
    {PnLF "Finger" 313}
    {RZMI "MakeIndex" 314}
    {FTCh "Fetch" 315}
    {TGE+ "Tarmac" 316}
    {Gzip "Gzip" 317}
    {DStf "DropStuff" 318}
    {SITx "StuffIt Expander" 319}
    {ALTV "Programmer's Assistant" 400}
    {MPAD "Mupad" 411}
    {GPSE "Gnuplot" 415}
    {Vodo "VOODOO" 500}
}

ensureset "alpha::downloadSite(Alpha's European mirror)" \
  "ftp://anu.theologie.uni-halle.de/comp/mac/alpha/"
ensureset "alpha::downloadSite(Alpha's ftp site)" \
  "ftp://ftp.ucsd.edu/pub/alpha/"

# ◊◊◊◊ International Keyboards ◊◊◊◊ #

namespace eval keyboard {}

set "keyboards(Australian)" {
 {§1234567890-=[];'\`,./}
 {±!@#$%^&*()_+{}:"|~<>?}
 <U/[
 <U/]
 {'§' 0x0a '±' 0x0a}
}
set "keyboards(Brasil)" {
 {§1234567890'+º´ç~\<,.-}
 {±!"#$%&/()=?*ª`Ç^|>;:_}
 <I<U/8
 <I<U/9
 {'§' 0x0a '±' 0x0a 'º' 0x21 'ª' 0x21 'ç' 0x29 'Ç' 0x29 '´' 0x1e '`' 0x1e '~' 0x27 '^' 0x27}
}
set "keyboards(British)" {
 {§1234567890-=[];'\`,./}
 {±!@£$%^&*()_+{}:"|~<>?}
 <U/[
 <U/]
 {'§' 0x0a '±' 0x0a '£' 0x14}
}
set "keyboards(Canadian - CSA)" {
 {/1234567890-=^ç;èàù,.é}
 {\!@#$%?&*()_+¨Ç:ÈÀÙ'"É}
 <I/7
 <I/8
 {'ç' 0x1e 'Ç' 0x1e 'è' 0x27 'È' 0x27 'à' 0x2a 'À' 0x2a 'é' 0x2c 'É' 0x2c 'ù' 0x32 'Ù' 0x32 '^' 0x21 '¨' 0x21 '7' 0x1a '8' 0x1c}
}
set "keyboards(Canadian - ISO)" {
 {¬1234567890-=^ç;èàù,.é}
 {°!"#$%?&*()_+¨Ç:ÈÀÙ'.É}
 <I/7
 <I/0
 {'°' 0x0a '¬' 0x0a 'ç' 0x1e 'Ç' 0x1e 'è' 0x27 'È' 0x27 'à' 0x2a 'À' 0x2a 'é' 0x2c 'É' 0x2c 'ù' 0x32 'Ù' 0x32 '^' 0x21 '¨' 0x21 '7' 0x1a '0' 0x1d}
}
set "keyboards(Canadian - French)" {
 {<1234567890-='[;`/¨,.é}
 {>!@#$%?&*()_+"]:^|°<>ç}
 <I/[
 <I<U/[
 {'é' 0x2c 'ç' 0x2c '¨' 0x06 '°' 0x06 '`' 0x27 '^' 0x27}
}
set "keyboards(Danish)" {
 {$1234567890+´å¨æø'<,.-}
 {§!"#?%&/()=?`Å^ÆØ*>;:_}
 <I<U/8
 <I<U/9
 {'§' 0x0a '?' 0x15 'å' 0x21 'Å' 0x21 'æ' 0x29 'Æ' 0x29 'ø' 0x27 'Ø' 0x27 '¨' 0x1e '^' 0x1e '´' 0x18 '`' 0x18}
}
set "keyboards(Dutch)" {
 {§1234567890-=[];'\`,./}
 {±!@#$%^&*()_+{}:"|~<>?}
 <U/[
 <U/]
 {'§' 0x0a '±' 0x0a}
}
set "keyboards(Español - ISO)" {
 {º1234567890'¡`+ñ´ç<,.-}
 {ª!"·$%&/()=?¿^*Ñ¨Ç>;:_}
 <I/´
 <I/ç
 {'ç' 0x2a 'ñ' 0x29 'Ç' 0x2a 'Ñ' 0x29 '¡' 0x18 '¿' 0x18 'º' 0x0a 'ª' 0x0a '·' 0x14 '`' 0x21 '^' 0x21 '´' 0x27 '¨' 0x27}
}
set "keyboards(Finnish)" {
 {§1234567890+´å¨öä'<,.-}
 {°!"#?%&/()=?`Å^ÖÄ*>;:_}
 <I<U/8
 <I<U/9
 {'§' 0x0a '°' 0x0a '?' 0x15 'å' 0x21 'ä' 0x27 'ö' 0x29 'Å' 0x21 'Ä' 0x27 'Ö' 0x29 '¨' 0x1e '^' 0x1e '´' 0x18 '`' 0x18}
}
set "keyboards(Flemish)" {
 {@&é"'(§è!çà)-^$ù`<,;:=}
 {#1234567890°_¨*%£>?./+}
 <I/(
 <I/)
 {'é' 0x13 '(' 0x17 '§' 0x16 'è' 0x1a 'ç' 0x19 'à' 0x1d ')' 0x1b '°' 0x1b 'ù' 0x27 '^' 0x21 '¨' 0x21 '`' 0x2a '£' 0x2a}
}
set "keyboards(French)" {
 {@&é"'(§è!çà)-^$ù`<,;:=}
 {#1234567890°_¨*%£>?./+}
 <I/(
 <I/)
 {'é' 0x13 '(' 0x17 '§' 0x16 'è' 0x1a 'ç' 0x19 'à' 0x1d ')' 0x1b '°' 0x1b 'ù' 0x27 '^' 0x21 '¨' 0x21 '`' 0x2a '£' 0x2a}
}
set "keyboards(French - numerical)" {
 {@&é"'(§è!çà)-^$ù`<,;:=}
 {#1234567890°_¨*%£>?./+}
 <I/(
 <I/)
 {'é' 0x13 '(' 0x17 '§' 0x16 'è' 0x1a 'ç' 0x19 'à' 0x1d ')' 0x1b '°' 0x1b 'ù' 0x27 '^' 0x21 '¨' 0x21 '`' 0x2a '£' 0x2a}
}
set "keyboards(German)" {
 {^1234567890ß´ü+öä#<,.-}
 {°!"§$%&/()=?`Ü*ÖÄ^>;:_}
 <I/8
 <I/9
 {'^' 0x0a '°' 0x0a '§' 0x14 'ü' 0x21 'ö' 0x29 'ä' 0x27 'Ü' 0x21 'Ö' 0x29 'Ä' 0x27 'ß' 0x1b '´' 0x18 '`' 0x18 '8' 0x1c '9' 0x19}
}
set "keyboards(Italian)" {
 {@&"'(çè)£àé-=ì$ù§<,;:ò}
 {#1234567890_+^*%°>?./!}
 <I/(
 <I/)
 {'(' 0x15 ')' 0x1a 'ç' 0x17 'è' 0x16 '£' 0x1c 'à' 0x19 'é' 0x1d 'ì' 0x21 'ù' 0x27 'ò' 0x2c '§' 0x2a '°' 0x2a}
}
set "keyboards(Italian - Pro)" {
 {\1234567890'ìè+òàù<,.-}
 {|!"£$%&/()=?^é*ç°§>;:_}
 <U<I/è
 <U<I/+
 {'\' 0x0a ''' 0x1b 'ì' 0x18 'è' 0x21 '+' 0x1e 'ò' 0x29 'à' 0x27 'ù' 0x2a}
}
set "keyboards(Norwegian)" {
 {'1234567890+´å¨øæ@<,.-}
 {§!"#$%&/()=?`Å^ØÆ*>;:_}
 <I<U/8
 <I<U/9
 {'§' 0x0a 'å' 0x21 'æ' 0x27 'ø' 0x29 'Å' 0x21 'Æ' 0x27 'Ø' 0x29 '¨' 0x1e '^' 0x1e '´' 0x18 '`' 0x18}
}
set "keyboards(Spanish)" {
 {[1234567890-=´`ñ;'<,.ç}
 {]¡!#$%/&*()_+º¨Ñ:">¿?Ç}
 <I<U/<
 <U/[
 {'¡' 0x12 '´' 0x21 'º' 0x21 'ñ' 0x29 'Ñ' 0x29 '¿' 0x2b 'ç' 0x2c 'Ç' 0x2c '`' 0x1e '¨' 0x1e}
}
set "keyboards(Swedish)" {
 {§1234567890+´å¨öä'<,.-}
 {°!"#?%&/()=?`Å^ÖÄ*>;:_}
 <I<U/8
 <I<U/9
 {'§' 0x0a '°' 0x0a '?' 0x15 'å' 0x21 'Å' 0x21 'ä' 0x27 'Ä' 0x27 'ö' 0x29 'Ö' 0x29 '¨' 0x1e '^' 0x1e '´' 0x18 '`' 0x18}
}
set "keyboards(Swiss French)" {
 {§1234567890'^è¨éà$<,.-}
 {°+"*ç%&/()=?`ü!öä£>;:_}
 <I/8
 <I/9
 {'§' 0x0a '°' 0x0a 'ü' 0x21 'è' 0x21 'ö' 0x29 'é' 0x29 'ä' 0x27 'à' 0x27 'ç' 0x15 '£' 0x2a '¨' 0x1e '!' 0x1e '^' 0x18 '`' 0x18 '8' 0x1c '9' 0x19}
}
set "keyboards(Swiss German)" {
 {§1234567890'^ü¨öä$<,.-}
 {°+"*ç%&/()=?`è!éà£>;:_}
 <I/8
 <I/9
 {'§' 0x0a '°' 0x0a 'ü' 0x21 'è' 0x21 'ö' 0x29 'é' 0x29 'ä' 0x27 'à' 0x27 'ç' 0x15 '£' 0x2a '¨' 0x1e '!' 0x1e '^' 0x18 '`' 0x18 '8' 0x1c '9' 0x19}
}
set "keyboards(U.S.)" {
 {§1234567890-=[];'\`,./}
 {±!@#$%^&*()_+{}:"|~<>?}
 <U/[
 <U/]
 {'§' 0x0a '±' 0x0a}
}

set "keyboards(Slovenian)" {
  {“1234567890/+πËÊæ<,.-}
  {”!"#$%&'()=?*©–»∆Æ>;:_}
  <U<I/π
  <U<I/
  {'“' 0x0a '”' 0x0a 'π' 0x21 '©' 0x21 '' 0x1e '–' 0x1e 'Ë' 0x29 '»' 0x29 'Ê' 0x27 '∆' 0x27 'æ' 0x2a 'Æ' 0x2a}
}

set "keyboards(Croatian)" {
  {“1234567890/+‰∂ãçÏ<,.-}
  {”!"#$%&'()=?*·≠âåÎ>;:_}
  <U<I/‰
  <U<I/∂
  {'“' 0x0a '”' 0x0a '‰' 0x21 '·' 0x21 '∂' 0x1e '≠' 0x1e 'ã' 0x29 'â' 0x29 'ç' 0x27 'å' 0x27 'Ï' 0x2a 'Î' 0x2a}
}

set "keyboards(Roman - JIS)" {
  {§1234567890-^@[;:]`,./}
  {±!"#$%&'()0=~`{+*}~<>?}
 <U/[
 <U/]
 {'§' 0x0a '±' 0x0a}
}

