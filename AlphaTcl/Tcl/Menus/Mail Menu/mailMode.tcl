## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Mail Menu - an extension package for Alpha
 #
 # FILE: "mailMode.tcl"
 # 
 #                                          created: 04/24/1996 {12:08:43 PM}
 #                                      last update: 02/28/2006 {03:21:19 PM}
 # Description:
 # 
 # Supports the creation and editing of e-mail windows for the "Menu Menu"
 # package in AlphaTcl.  These windows can be used to compose e-mails in
 # Alpha and then send them using the defined "mail handler" service.
 # 
 # There is no actual "mode" named "Mail" -- instead we use Text mode for all
 # of our windows, defining minor modes for browsing, viewing, composing.
 # Procedures should call [Mail::initializeMode] when necessary to ensure
 # that all necessary variables, hooks, etc have been defined.
 # 
 # See the "Changes - Mail Menu" file for license information.
 # 
 # ==========================================================================
 ##

# To make sure that this file gets loaded before support files.
proc mailMode.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval Mail" --
 # 
 # Define variables that are used by various Mail mode procedures.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Mail {
    
    # The list of header fields.
    variable Keywords [list "Subject:" "To:" "From:" "Cc:" "Bcc:" \
      "Date:" "Sender:" "Reply-To:"]
    
    # Used by various e-mail validation routines.
    variable emailPattern {<?([-\w._+]+@[-\w._+]+\.[-\w_+]+)>?}
    
    # This divider line is used to display multipart mime messages.
    variable newMessagePartText
    if {![info exists newMessagePartText]} {
	append newMessagePartText ">" [string repeat "-" 24] \
	  "New message part begins below" [string repeat "-" 25] "<"
    } 
    # These preferences are offered as toggleable "Sent Mail" menu items.
    variable sentMailPrefs
    lunion sentMailPrefs \
      "confirmBeforeSending" \
      "killWindowAfterSend" \
      "rememberRecipientEmail" \
      "saveCopyOfSentMail"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::initializeMode" --
 # 
 # Called when the Mail Menu is loaded for the first time. 
 # 
 # Because we have many variables defined in a variety of namespaces and
 # procedures throughout this file, we make sure that everything has been
 # sourced before we actually do anything with this information.
 # 
 # Do _not_ call any procedures in other Mail Menu files during this routine,
 # else you're flirting with recursive loops.  We should be setting variables
 # and registering information here, and nothing else.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::initializeMode {} {
    
    global MailmodeVars
    
    variable initialized
    variable oldFolderLocations
    
    if {[info exists initialized]} {
        return
    } 
    
    # This is used by [Mail::newFolderLocation] when the user has changed the
    # location of these preferences.
    array set oldFolderLocations [list \
      "draft"   $MailmodeVars(mailDraftsFolder) \
      "sent"    $MailmodeVars(mailSentFolder) \
      ]
    
    # This is essentially a 'dummy' call, so that all of any other
    # [regModeKeywords] calls can be adds (using -a).
    regModeKeywords -s $MailmodeVars(stringColor) Mail {}
    # Register color scheme
    Mail::colorizeMail
    # Set comment characters.
    Mail::setCommentChars
    
    # Make sure that we don't go through this routine again.
    set initialized 1
    return
}

# ===========================================================================
# 
# ×××× Preferences ×××× #
# 
# Some preferences below are defined as a courtesy for Mail Handler packages
# that support the menu items/procedures which use them, but they are
# initially "invisible" as set below in with [prefs::deregister].

# ---------------------------------------------------------------------------
# 
# Obsolete
# 

# This was present in pre 2.0 versions, but no file marking was ever used.
# Now we always mark the browsing/viewing windows that we create.
prefs::removeObsolete ::MailmodeVars(autoMark)
# This was present in the 2.0bx series.
prefs::removeObsolete ::MailmodeVars(rememberWindowGeometry)

# ---------------------------------------------------------------------------
# 
# Renamed
# 

array set oldVarNames [list \
  "::MailmodeVars(tossOnQueue)"     "::MailmodeVars(killWindowAfterSend)" \
  "::mailflushOnCheck"              "::MailmodeVars(flushOnCheck)" \
  "::mailimmediateSend"             "::MailmodeVars(immediateSend)" \
  "::mailHandler"                   "::MailmodeVars(mailHandler)" \
  ]

foreach oldVarName [array name oldVarNames] {
    prefs::renameOld $oldVarName $oldVarNames($oldVarName)
}
unset oldVarNames oldVarName

# ---------------------------------------------------------------------------
# 
# Composing
# 

# To automatically indent the new line produced by pressing Return, turn this
# item on.  The indentation amount is determined by the context||To have the
# Return key produce a new line without indentation, turn this item off
newPref flag indentOnReturn             0       Mail

newPref var commentsContinuation        1       Mail "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
newPref var fillColumn                  77      Mail
# The character to use for quoted text.
newPref var prefixString                {> }    Mail {Mail::updatePreferences}
newPref var wordBreak           {[-\w:@.]*[\w]} Mail
newPref var lineWrap                    1       Mail

# ---------------------------------------------------------------------------
# 
# Sending Mail
# 

# To always ask for confirmation before sending new mail messages, turn this
# item on||To never ask for confirmation before sending new mail messages,
# turn this item off
newPref flag confirmBeforeSending       1       Mail
# To automaticallly kill the active Mail window after it has been sent via
# your mailer client, turn this item on||To never automaticallly kill the
# active Mail window after it has been sent via your mailer client, turn this
# item off
newPref flag killWindowAfterSend        1       Mail
# To automatically add a recipient's e-mail address to the "Mail Menu > New
# Message To" menu, turn this item on||To never automatically add a
# recipient's e-mail address to the "Mail Menu > New Message To" menu, turn
# this item off.
newPref flag rememberRecipientEmail     1       Mail
# To always save a copy of sent mail in your "Mail Sent" folder, turn this
# item on||To never save a copy of sent mail in your "Mail Sent" folder, turn
# this item off
newPref flag saveCopyOfSentMail         1       Mail

# Always add the following address to the "Bcc:" field in new mail
# composition windows.
newPref var alwaysBccTo                 ""      Mail
# The location of your "Mail Drafts" folder
newPref folder mailDraftsFolder [file join $PREFS Mail Drafts] \
  Mail {Mail::updatePreferences}
# The location of your "Sent Mail" folder
newPref folder mailSentFolder   [file join $PREFS Mail Sent] \
  Mail {Mail::updatePreferences}

# ---------------------------------------------------------------------------
# 
# Mail Windows
# 

# To always create a floating palette containg the Mailbox window's subject
# lines, turn this item on||To never create a floating palette for Mailbox
# windows, turn this item off
newPref flag autoFloatMailboxWindowMarks 0      Mail
# To always create a floating palette containing the Mail View marks, turn
# this item on||To never create a floating palette for Mail View windows,
# turn this item off
newPref flag autoFloatMessageMarks      0       Mail
# To open each new Mail View window with a unique name that includes the 
# start of its subject line, turn this item on||To only have one Mail View 
# window open at a time, turn this item off
newPref flag multipleMailViewWindows    0       Mail
# To list messages in the order they were received, turn this item on||To
# list messages with the most recent ones first, turn this item off
newPref flag newerMessagesListedFirst   0       Mail
# To attempt to render html formatted text when viewing received mail, turn
# this item on.  Any plain text alternatives will then be ignored||To never
# render html formatted text when viewing received mail, turn this item off
newPref flag renderHtmlFormattedText    1       Mail
# To toggle amongst open Mailbox/Mail windows by using the semi-colon key,
# turn this item on||To never use the semi-colon key to toggle amongst open
# Mailbox/Mail windows, turn this item off
newPref flag semicolonSwitchesWindows   1       Mail

# The geometry for all new Mailbox browsing windows.
newPref geometry mailboxWindowGeometry  \
  [list -g $tileLeft $tileTop $defWidth $errorHeight] Mail
# The geometry for all new Mail viewing windows.
newPref geometry mailViewWindowGeometry \
  [list -g $tileLeft [expr {$tileTop + $errorHeight + 10}] \
  $defWidth [expr {$errorDisp + 10}]] Mail

# Default font to use for Mail viewing windows
newPref var mailViewWindowFont          $::defaultFont  Mail \
  {Mail::updatePreferences} $::alpha::fontList
# Default font size to use for Mail viewing windows
newPref var mailViewFontSize            $::fontSize     Mail \
  {Mail::updatePreferences} [list "7" "9" "10" "12" "14" "18"]
# How quoted test should be displayed in mail viewing windows.
newPref var quotedTextShouldBe          "1"     Mail "" \
  [list "Plain" "Colorized Only" "Italicized Only" "Colorized & Italicized"] \
  index

# ---------------------------------------------------------------------------
# 
# Menu Shortcuts
# 

newPref menubinding forward             "<U<B/F" Mail {Mail::updatePreferences}
newPref menubinding newMessage          "<U<B/N" Mail {Mail::updatePreferences}
newPref menubinding saveAsDraft         "<O/S"   Mail {Mail::updatePreferences}
# Use this keyboard shortcut to navigate Mail window sections.
newPref menubinding selectNextField     "/c"     Mail {Mail::updatePreferences}
newPref menubinding send                "<U<B/S" Mail {Mail::updatePreferences}

# (courtesy preferences)

if {($::alpha::platform eq "alpha")} {
    newPref menubinding reply/ReplyToAll "<U<B/R" \
      Mail {Mail::tcllib::updatePreferences}
} else {
    newPref menubinding reply           "<U<B/R" Mail {Mail::updatePreferences}
    newPref menubinding replyToAll    "<U<B<O/R" Mail {Mail::updatePreferences}
}
newPref menubinding trashMessage        "<U<B/T" Mail {Mail::updatePreferences}
newPref menubinding prevMessage         "<U<B/y" Mail {Mail::updatePreferences}
newPref menubinding nextMessage         "<U<B/z" Mail {Mail::updatePreferences}

# ---------------------------------------------------------------------------
# 
# Mail Colors
# 

# To color quoted text in New Mail windows, turn this item on||To disable the
# coloring of quoted text in New Mail windows, turn this item off
newPref flag colorNewMailQuotedText     1       Mail {Mail::updatePreferences}
# The color of quoted text (as determined by the Prefix String preference.
newPref color 	quoteColor      {red}   Mail {Mail::updatePreferences}
# The color of Heading: keywords (such as Subject, To, etc)
newPref color 	headingColor    {blue}  Mail {Mail::updatePreferences}
newPref color   stringColor     {none}  Mail {Mail::updatePreferences}

# ---------------------------------------------------------------------------
# 
# Mail Handler
# 
# The "MailmodeVars(mailHandler)" variable defines a handler used for all
# mail services.  We ensure that obsolete handler names created by earlier
# versions of this package are ignored.
# 

if {[info exists MailmodeVars(mailHandler)] \
  && ![info exists ::Mail::handlers($MailmodeVars(mailHandler))]} {
    unset -nocomplain MailmodeVars(mailHandler)
}
newPref var mailHandler "OS Mailer" Mail {Mail::updatePreferences} \
  "::Mail::handlers" array

# Includes items to manipulate fields in "New Message" windows
newPref flag "mailWindowMenu"           1       contextualMenuMail
# Contains a list of saved e-mail addresses; selecting one will open a "New
# Message" window addressed to the chosen recipient
newPref flag "newMessageToMenu"         1       contextualMenuMail

# When the dialogues are actually built, there will most likely be added
# a Miscellaneous pane.  This happens whenever there are prefs which are
# not categorized.  (There's no need to set a "prefLists(Miscellaneous)"
# array entry, because this will always be unset.)

# Composing
prefs::dialogs::setPaneLists "Mail" "Composing" [list \
  "fillColumn" \
  "indentOnReturn" \
  \
  "prefixString" \
  "commentsContinuation" \
  "wordBreak" \
  "lineWrap" \
  ]

# Sending Mail
prefs::dialogs::setPaneLists "Mail" "Sending Mail" [list \
  "confirmBeforeSending" \
  "killWindowAfterSend" \
  "rememberRecipientEmail" \
  "saveCopyOfSentMail" \
  \
  "alwaysBccTo" \
  "mailDraftsFolder" \
  "mailSentFolder" \
  ]
  
# Mail Windows
prefs::dialogs::setPaneLists "Mail" "Mail Windows" [list \
  "autoFloatMailboxWindowMarks" \
  "autoFloatMessageMarks" \
  "multipleMailViewWindows" \
  "newerMessagesListedFirst" \
  "renderHtmlFormattedText" \
  "semicolonSwitchesWindows" \
  \
  "mailboxWindowGeometry" \
  "mailViewWindowGeometry" \
  "mailViewWindowFont" \
  "mailViewFontSize" \
  "quotedTextShouldBe" \
  ]

# Menu Shortcuts
prefs::dialogs::setPaneLists "Mail" "Menu Shortcuts" [list \
  "forward" \
  "newMessage" \
  "nextMessage" \
  "prevMessage" \
  "reply" \
  "reply/ReplyToAll" \
  "replyToAll" \
  "saveAsDraft" \
  "selectNextField" \
  "send" \
  "trashMessage" \
  ]

# Colors
prefs::dialogs::setPaneLists "Mail" "Colors" [list \
  "colorNewMailQuotedText" \
  \
  "headingColor" \
  "quoteColor" \
  "stringColor" \
  ]

# We define some preferences in the "MailmodeVars" array, but we don't want
# to present them (by default, at least) in the prefs dialogs.  For example,
# the "mailHandler" preference is best set via the menu.
prefs::deregister "mailHandler"                 "Mail"
# Some of the "Mail Windows" preferences as well as those for menu bindings
# are also created as a courtesy for the various Mail Handlers which support
# them, but are initially invisible.
prefs::deregister "mailboxWindowGeometry"       "Mail"
prefs::deregister "mailViewWindowGeometry"      "Mail"
prefs::deregister "reply"                       "Mail"
prefs::deregister "replyToAll"                  "Mail"
prefs::deregister "reply/ReplyToAll"            "Mail"
prefs::deregister "trashMessage"                "Mail"
prefs::deregister "prevMessage"                 "Mail"
prefs::deregister "newMessage"                  "Mail"
# Handlers can expose this if it is relevant.
prefs::dialogs::hideShowPane "Mail Windows" "Mail" 0

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::updatePreferences" --
 # 
 # Registered as the pref script for some Mail mode preferences, rebuild
 # menus or perform other actions necessary to make some changes take effect
 # immediately without requiring a restart.
 # 
 # For simplicity, we always rebuild the main Mail menu.
 # 
 # We also explicitly deregister all possible "requireOpenWindowsHook" and
 # then decide if (and what) should be (re)registered based upon the menu
 # items and our mail handler.  The list of items is saved in the variable
 # "menuHookItems" for use by the [Mail::activateHook] procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::updatePreferences {prefName} {
    
    global mode
    
    switch -- $prefName {
	"prefixString" {
	    Mail::setCommentChars
	    if {($mode eq "Mail")} {
		refresh
	    }
	}
	"colorNewMailQuotedText" - 
	"quoteColor" - "headingColor" - "stringColor" {
	    Mail::colorizeMail
	    if {($mode eq "Mail")} {
		refresh
	    }
	}
	"mailViewWindowFont" - "mailViewFontSize" {
	    foreach w [winNames -f] {
		if {[string match "*MAIL Window*" $w]} {
		    alertnote "You must close the current Mail viewing window\
		      in order for the new '[quote::Prettify $prefName]'\
		      to take effect."
		    break
		} 
	    }
	}
	"mailDraftsFolder" - "mailSentFolder" {
	    Mail::newFolderLocation $prefName
	}
	default {
	    Mail::handlerChanged
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::wwwPrefsDialog" --
 # 
 # Present a limited version of the WWW Prefs dialog so that the user can
 # adjust the colors and styles used in parsing html formatted text.  It is
 # only presented in the Mail Menu if the current handler has added it.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::wwwPrefsDialog {} {
    
    global WWWmodeVars allFlags
    
    loadAMode "WWW"
    
    # Link Colors
    set prefList [list \
      "ftpLinksInternal" \
      "httpLinksInternal" \
      "ignoreForms" \
      "ignoreImages" \
      "wwwSendRemoteLinks" \
      \
      "header1Color" \
      "header1Style" \
      "header2Color" \
      "header2Style" \
      "header3Color" \
      "header3Style" \
      ]
    set flags [list]
    set vars  [list]
    foreach pref $prefList {
	if {![prefs::isRegistered $pref WWW]} {
	    continue
	} elseif {[lsearch -exact $allFlags $pref] >= 0} {
	    lappend flags $pref
	} else {
	    lappend vars $pref
	}
    }
    set pages [list "WWW" "" $flags $vars \
      [list prefs::dialogs::_getPrefValue "package" "WWW"] \
      [list prefs::dialogs::_setPrefValue "package" "WWW"]]
    status::msg "These values are used for html formatted text."
    prefs::dialogs::makePrefsDialog "Html Links, Colors & Styles" $pages
    WWW::postBuildMenu
    return
}
## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::colorizeMail" --
 # 
 # Used to update preferences, and could be called in a "MailPrefs.tcl" file.
 # (Be sure to call [refresh] after this to make changes visible.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::colorizeMail {} {
    
    global MailmodeVars
    
    variable Keywords
    
    regModeKeywords -a -k $MailmodeVars(headingColor) Mail $Keywords

    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::setCommentChars" --
 # 
 # Set (change) the comment characters for Mail mode.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::setCommentChars {} {
    
    global alpha::platform MailmodeVars
    
    variable commentCharacters
    variable startPara
    variable endPara

    set pS [string trim $MailmodeVars(prefixString)]

    set commentCharacters(General)   "$pS "
    set commentCharacters(Paragraph) [list "$pS$pS " " $pS$pS" " $pS "]
    set commentCharacters(Box)       [list $pS 1 $pS  1 $pS 3]
    
    if {!$MailmodeVars(colorNewMailQuotedText)} {
	regModeKeywords -a -c "" Mail {}
    } elseif {${alpha::platform} eq "alpha"} {
	regModeKeywords -a -c $MailmodeVars(quoteColor) -e "$pS" Mail {}
    } else {
	regModeKeywords -a -c $MailmodeVars(quoteColor) \
	  -begin "^(\[ \t\]*[quote::Regfind $pS].*)" Mail {}
    }

    set startPara "^\[ \t\]*([quote::Regfind $pS]|\$)"
    set endPara   "^\[ \t\]*([quote::Regfind $pS]|\$)"

    return
}

# ===========================================================================
# 
# ×××× Mail Mode Support ×××× #
# 
# Define standard Mail mode procedures that are called by the AlphaTcl core.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::electricSemi" --
 # 
 # Try to switch from read-only window, else type a semicolon.
 # 
 # --------------------------------------------------------------------------
 ##

Bind '\;' {Mail::electricSemi} Mail

proc Mail::electricSemi {} {
    
    global MailmodeVars
    
    Mail::requireMailWindow
    if {!$MailmodeVars(semicolonSwitchesWindows) \
      || ![win::getInfo [win::Current] read-only]} {
	typeText ";"
    } elseif {![Mail::switchWindow]} {
	status::msg "Couldn't find any MAIL window."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::MarkFile" --
 # 
 # Called by the window sidebar's "Mark > Mark Window" pop-up menu item.
 # 
 # We have marking routines that are specific to the window's type.  Browsing
 # windows display the subject lines.  Viewing windows with multipart mime
 # messages display the part numbers.  All other windows display a portion of
 # the leading sentence for each non-quote paragraph.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::MarkFile {args} {
    
    variable newMessagePartText
    
    win::parseArgs w {quietly 0}
    
    # Preliminaries
    removeAllMarks -w $w
    set marksList [list]
    if {!$quietly} {
	status::msg "Marking window É"
	# This is our default ending message.
	set msg "No file marking is supported for this window."
    }
    set markingMethod ""
    # Mark the file in a way appropriate to the window's type.
    switch -- [Mail::getWindowType -w $w] {
	"new" {
	    # Composing window.
	    set markingMethod "paragraphs"
	}
	"viewer" {
	    # Viewing window.
	    set pat $newMessagePartText
	    set matches [search -w $w -n -s -all -f 1 -r 0 -- $pat [minPos -w $w]]
	    if {[llength $matches] > 2} {
		set markingMethod "multipart"
	    } else {
		set markingMethod "paragraphs"
	    }
	}
	"browser" {
	    # Mailbox window.
	    set markingMethod "browser"
	}
	"display" {
	    # Drafts or Sent Messages window.
	    set markingMethod "display"
	}
	default {
	    status::msg "File marking is not supported in this window."
	    return 0
	}
    }
    # Now mark according to the method we determined.
    switch -- $markingMethod {
        "browser" {
	    set pat {^\s*[^:]+\s+:\s+([^\r\n]+)\s*$}
	    set pos [minPos -w $w]
	    set matches [search -w $w -n -s -all -f 1 -r 1 -- $pat $pos]
	    for {set i 0} {($i < [llength $matches])} {incr i 2} {
		set pos0 [lindex $matches $i]
		set pos1 [pos::nextLineStart -w $w $pos0]
		set text [getText -w $w $pos0 $pos1]
		regexp -- $pat $text -> mark
		# Bug# 892 -- should be fixed after release of Alpha 8.0.
		regsub -- {^Menu(\s)} $mark {menu\1} mark
		if {![string length [string trim $mark]]} {
		    continue
		} 
		lappend marksList [list $mark $pos0 $pos0 $pos1]
	    }
	    set what "message"
        }
        "multipart" {
	    set pat $newMessagePartText
	    set pos [minPos -w $w]
	    set part 0
	    set matches [search -w $w -n -s -all -f 1 -r 0 -- $pat $pos]
	    for {set i 0} {($i < [llength $matches])} {incr i 2} {
		set pos0 [pos::prevLineStart -w $w [lindex $matches $i]]
		set pos1 [pos::lineStart -w $w [lindex $matches $i]]
		set pos2 [pos::lineEnd -w $w $pos1]
		set mark "Message Part [incr part]"
		lappend marksList [list $mark $pos0 $pos1 $pos2]
	    }
	    set what "part"
	} 
        "paragraphs" {
	    set pat {^>====+[^\r\n]+====+<$}
	    set pos [minPos -w $w]
	    set dividerLine [search -w $w -s -n -f 1 -r 1 -- $pat $pos]
	    if {[llength $dividerLine]} {
		set pos [pos::nextLineStart -w $w [lindex $dividerLine 0]]
	    } else {
		set pos [maxPos -w $w]
	    }
	    set pat {\r\s*\r[^ \->|]}
	    set matches [search -w $w -n -s -all -f 1 -r 1 -- $pat $pos]
	    for {set i 0} {($i < [llength $matches])} {incr i} {
		set pos0 [pos::prevLineStart [lindex $matches [incr i]]]
		set pos1 [pos::nextLineStart -w $w $pos0]
		set pos2 [pos::nextLineStart -w $w $pos1]
		set mark [string trim [getText -w $w $pos1 $pos2]]
		# Bug# 892 -- should be fixed after release of Alpha 8.0.
		regsub -- {^Menu(\s)} $mark {menu\1} mark
		if {([string trim $mark] eq "")} {
		    continue
		} elseif {[regexp -- {^([*+\-_=.<>\^$]+)$} $mark]} {
		    continue
		}
		lappend marksList [list " $mark" $pos0 $pos1 $pos1]
	    }
	    set what "paragraph"
        }
	"display" {
	    set pat {^Message ID: \"([^\r\n]+)\"$}
	    set pos [minPos -w $w]
	    set matches [search -w $w -n -s -all -f 1 -r 1 -- $pat $pos]
	    for {set i 0} {($i < [llength $matches])} {incr i 2} {
		set pos0 [lindex $matches $i]
		set pos1 [pos::lineEnd -w $w $pos0]
		set text [getText -w $w $pos0 $pos1]
		regexp -- $pat $text -> mark
		if {![string length [string trim $mark]]} {
		    continue
		} 
		lappend marksList [list $mark $pos0 $pos0 $pos1]
	    }
	    set what "messages"
	}
    }
    set seenMarks [list]
    foreach markItem $marksList {
	set mark [markTrim [lindex $markItem 0]]
	set pos1 [lindex $markItem 1]
	set pos2 [lindex $markItem 2]
	set pos3 [lindex $markItem 3]
	while {([lsearch -exact $seenMarks $mark] > -1)} {
	    append mark " "
	}
	lappend seenMarks $mark
	setNamedMark -w $w $mark $pos1 $pos2 $pos3
    }
    if {!$quietly} {
	set wT "\"[win::Tail $w]\""
	if {![llength $seenMarks]} {
	    status::msg "No marks were found in the window ${wT}."
	} else {
	    append what [expr {([llength $seenMarks] > 1) ? "s" : ""}]
	    status::msg "The $wT window has [llength $seenMarks] ${what}."
	}
    }
    return [llength $seenMarks]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::OptionTitlebar" --
 # 
 # Called by option-clicking on the title bar in a Mail mode window.
 # 
 # Create a list of all Mail mode windows, placing the name of the active
 # window at the end.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::OptionTitlebar {} {
    
    variable optionTBWinConnect
    
    set mailWindows [list]
    foreach w [winNames -f] {
	if {($w ne [win::Current]) && ([win::getHookModes $w] eq "Mail")} {
	    lappend mailWindows $w
	} 
    }
    set menuList [concat [list "\(Current Mail Windows:" "(-)"] \
      [lsort -dictionary $mailWindows] \
      [list "(-)" [win::CurrentTail]]]
    return $menuList
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::OptionTitlebarSelect" --
 # 
 # Bring the selected window to the front.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::OptionTitlebarSelect {itemName} {
    
    variable optionTBWinConnect
    if {![win::Exists $itemName]} {
	set pat "[quote::Regfind [string range $itemName 0 20]]*"
	if {([set idx [lsearch -glob [winNames] $pat]] > -1)} {
	    set itemName [lindex [winNames] $idx]
	} else {
	    error "Cancelled -- could identify the proper window."
	}
    } 
    bringToFront $itemName
    return
}


## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::DblClick" --
 # 
 # At present, we only have a special case for e-mails that are from one of
 # the AlphaTcl mailing lists.  Not sure what to do otherwise...
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::DblClick {args} {
    
    if {([Mail::getWindowType] ne "browser")} {
	set from [Mail::getFieldValue "from"]
	set to   [Mail::getFieldValue "to"]
	set cc   [Mail::getFieldValue "cc"]
	if {[regexp -nocase -- {alphatcl|alpha-bugzilla} "$from $to $cc"]} {
	    eval Tcl::DblClick $args
	    return
	} 
    } 
    # Still here?
    error "Cancelled -- no Command-Double-Click action is available."
}

# ===========================================================================
# 
# ×××× Mail Handlers ×××× #
# 
# Each "Mail Handler" should define itself in an [alpha::library] script, by
# adding to the "Mail::handlers" array where the entry name is the service
# that appears in the "Mail Menu > Mail Handlers" menu and the value is a
# one-item list containing the namespace in which handler specific procedures
# will be called.
# 
# Each handler should define a "handlerChanged" procedure which can add a new
# preferences pane containing those prefs which are specific to the handler,
# or additional menu items and/or menu hooks to be defined.  This procedure
# should accept a single boolean argument indicating that the handler is
# being turned on or off, so that these preferences can be hidden or made
# visible, the menu items can be added, the hooks can be (de)registered.
# 
# Each handler should define a menu build proc for the CM "mailWindow" menu
# with items appropriate to the active window.
# 
# Required procedures that should be defined by any mailHandler package:
# 
# handlerChanged        --
# handlerHelp           --
# checkSystem           --
# PrepareToSend         --
# SetField              --
# QueueToSend           --
# 
# Optional procedures called by the Mail Menu:
# 
# trashMessage          --
# goToMatch             --
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::handlerChanged" --
 # 
 # Called by [Mail::updatePreferences] whenever the handler is changed.
 # 
 # We first attempt to "undo" anything changed by the previous handler, such
 # as hook registration or preference manipulation.  Then we explicitly
 # remove all items in the "menu::additions(mailMenu)" array so that we can
 # start with a clean slate.  This helps the handlers avoid dealing with the
 # mess created by the user changing menu shortcuts, i.e. we don't want to
 # have to deal with removing menu items that might have changed.  We finally
 # rebuild the menu.
 # 
 # We define a very basic "Mail Window" menu build proc for the CM, but the
 # handler is welcome to over-ride this with something fancier.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::handlerChanged {} {
    
    global MailmodeVars menu::additions
    
    variable handlers
    variable oldHandler
    
    # Sanity check.
    if {![llength [array names handlers]]} {
        error "Cancelled -- no mail handlers have been defined."
    } 
    # Define a basic menu build proc for the CM module.
    menu::buildProc "mailWindow" {Mail::buildWindowMenu}

    # In order to rebuild our menu, we first remove previous additions.
    if {[info exists oldHandler]} {
	set ns [string trimleft $handlers($oldHandler) ":"]
	if {[catch {namespace eval ::$ns "handlerChanged" 0} errorMessage]} {
	    set ::mailErrorInfo $::errorInfo
	    # This is for debugging -- remove or comment for final release.
	    alertnote $errorMessage
	}
    } 
    set oldHandler $MailmodeVars(mailHandler)
    # Call "handlerChanged" for the current handler, and rebuild the menu.
    array unset menu::additions "mailMenu"
    Mail::handlerAction "handlerChanged" "1"
    menu::buildSome "mailMenu"
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "Mail::handlerAction" --
 # 
 # Pass on any script to the namespace specified for the currently defined
 # mail handler.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::handlerAction {cmd args} {
    
    global MailmodeVars
    
    variable handlers
    
    # Sanity check.
    if {![llength [array names handlers]]} {
	error "Cancelled -- no mail handlers have been defined."
    } 
    # If the current handler has a procedure defined for this "cmd" then we 
    # call it, otherwise we throw an error.
    set ns [string trimleft $handlers($MailmodeVars(mailHandler)) ":"]
    if {![catch {namespace eval ::$ns $cmd $args} result]} {
	return $result
    } elseif {![string match -nocase "*cancel*" $result]} {
	error "Cancelled -- $result"
    } else {
        error $result
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::handlerHelp" --
 # 
 # Call the handler's "handlerHelp" procedure to obtain more information.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::handlerHelp {{handler ""}} {
    
    variable handlers
    
    if {($handler eq "")} {
	set p "Help for which mail handler service?"
	set options [lsort -dictionary [array names handlers]]
	set handler [listpick -p $p -- $options]
    } 
    set ns [string trimleft $handlers($handler) ":"]
    namespace eval ::$ns handlerHelp
    return
}

# ===========================================================================
# 
# .