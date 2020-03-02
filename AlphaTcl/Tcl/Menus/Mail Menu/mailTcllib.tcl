## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Mail Menu - an extension package for Alpha
 #
 # FILE: "mailTcllib.tcl"
 # 
 #                                          created: 12/27/2004 {10:31:11 PM}
 #                                      last update: 02/23/2006 {04:53:35 PM}
 # Description:
 # 
 # Provides a "mail handler" service for the "Mail Menu" that allows e-mails
 # to be sent internally from Alpha using the tcllib package "smtp".
 # 
 # See the "Changes - Mail Menu" file for license information.
 # 
 # ==========================================================================
 ##

alpha::library "mailTcllib" 2.0 {
    namespace eval Mail {
	variable handlers
	set handlers($::alpha::application) "Mail::tcllib"
	if {[info exists ::MailmodeVars(mailHandler)] \
	  && ($::MailmodeVars(mailHandler) eq $::alpha::application)} {
	    array set ::newDocTypes [list \
	      "New E-mail Inbox" {Mail::tcllib::newInbox}]
	} 
    }
} description {
    Enables the sending of messages with ÇALPHAÈ's package: mailMenu using
    the Tcl-lib "smtp" and "pop3" packages
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} help {
    This package enables the browsing/viewing and sending of messages with
    the package: mailMenu using the Tcl-lib "smtp" and "pop3" packages.
    
	  	Table Of Contents

    "# Introduction"
    "# Basic Usage"
    "# Inbox Browsing Window"
    "# Viewing Received Messages"
    "# Deleting Remote Messages"
    "# Sending E-mail"
    
    "# Multiple Accounts"
    "# Server Preferences"
    "# Account Passwords"
    "# Preference Settings"
    
    "# Current Limitations"
    
    <<floatNamedMarks>>

    
	  	Introduction
    
    This package turns ÇALPHAÈ into a very basic e-mail client, allowing you
    to read and send messages without switching to (or using the services of)
    any other program.  Its features include "# Multiple Accounts" and the
    trashing of messages on the remote server.
    
    ÇALPHAÈ's internal Mail Handler is MIME-conformant, with respect to
    Appendix A of RFC 1521.
    
    <http://www.freesoft.org/CIE/RFC/1521/43.htm>
    
    It will handle multipart, mixed content-types and include messages about
    attached files without displaying them as raw text.
    
    
	  	Basic Usage
    
    Turn on the "Mail Menu" in the "Config > Global Setup > Menus" dialog.
    
    Preferences: Menus
    
    Then select "Mail Menu > Mail Handers > ÇALPHAÈ" to use this service.
    
    Then select "Mail Menu > Open Inbox" and fill in the account name, server
    address, and your password.  A new dialog will appear telling you how
    many messages are in your remote Inbox, asking you which ones you would
    like to view.  These will appear in a new "# Inbox Browsing Window".
    
    Use the Arrow keys to navigate this browsing window, and then you can
    begin "# Viewing Received Messages" by pressing Return or Enter.  A new
    Mail window will be created displaying the contents of the e-mail.
    
    Select "Mail Menu > Reply" to open a new composition window, with the
    original contents quoted in the body of the message.  When you are
    satisfied with your post, select "Mail Menu > Send" and fill out any
    required information about your SMTP server, account name and password.
    
    
	  	Inbox Browsing Window
    
    Select "Mail Menu > Open Inbox" to query the remote server for the
    messages in your main Inbox folder.  A dialog will inform you how many
    messages are in the Inbox, and inquire about which ones you would like to
    download.  Like any internet process, the time that this takes to
    complete will vary depending on your internet connection and other
    circumstances beyond ÇALPHAÈ's control.  You should experiment to see how
    long it takes to download 10, 20, 100 messages.
    
    Once the messages have been retrieved, they are presented in a new
    browser window in ÇALPHAÈ.  You can navigate the listed e-mail headings
    in this window using the arrow keys.  Press Return or Enter to view the
    selected e-mail in ÇALPHAÈ.
    
    Closing the Mailbox browsing window closes the socket channel connection
    to your remote server.  You will not be able to trash any open Mail
    windows that were created from the browsing window.
    
    Note: As the "Mail Help # Keyboard Shortcuts" help file explains, all of
    the menu shortcuts for the Mail Menu are only work when the active window
    has been created by this package, even if the menu has been turned on
    "globally."  If you have turned on the package: newDocument then you will
    have access to a "File > New > E-mail Inbox" menu item, and you can
    assign a global Keyboard Shortcut to call this command.
    
    
	  	Viewing Received Messages
    
    Pressing Return or Enter in an Inbox browsing window to open the contents
    of the message in a new "MAIL" window.  You can then select the menu
    command(s) "Mail Menu > Reply (To All) / Forward" to open a new mail
    composition window.
    
    If the Mail mode preference for "Render Html Formatted Text" is turned on
    then we attempt to ignore plain text alternatives and instead render html
    formatted messages using the WWW menu.  You can adjust the colors used
    for the various mark-up tags by setting your WWW mode preferences with
    the "Mail Menu > Html Colors & Style" menu item.
    
    Preferences: Mode-WWW
    
    See the "# Preference Settings" section for more options.
    
    
	  	Deleting Remote Messages
    
    Messages can be deleted from your remote server while the active window
    is a Mailbox browser or a viewer with "Mail Menu > Trash Message".  If
    your preference for "Confirm Before Trashing" has been turned on
    
    Preferences: Mode-Mail
    
    then you will be asked for confirmation before performing the operation.
    Once the message has been deleted, it cannot be recovered.  Its listing
    will be removed from the Mailbox browsing window, and if a Mail view
    window is open it will display the contents of the next message.
    
    Caveat: The "socket channel connection" must be explicitly closed for the
    server to remove the message.  It it is closed prematurely, such as a
    "time-out" due to inactivity or some interruption in your internet
    connection, the messages will remain on the server.  The socket channel
    is automatically disconnected "gracefully" when the Mailbox browsing
    window is closed.
    
    
	  	Sending E-mail

    After you have opened a composition window (by replying to a received
    e-mail or via the "Mail Menu > New Message (To)" commands) you can send
    it using your smtp server.  Just select the "Mail Menu > Send" command
    and confirm your account information.
    
    Currently this package supports
    
	Digest-md5
	Cram-md5
	Login
	Plain
	
    authentication methods.  The most secure method will be tried first and
    each method tried in turn until we are either authorized or we run out of
    methods.  SMTP servers requiring stricter authentication methods, such as
    Secure Sockets Layer (SSL), are not handled.


	====================================================================

	  	Multiple Accounts
    
    ÇALPHAÈ allows you to define as many different "identities" as you want
    using the "Mail Menu > Mail Accounts" menu.  The name of each identity
    will appear in this menu, and you can use the utility items to rename or
    remove them as you wish.  Each identity has its own Server Preferences
    and a separate password cache.
    
    
	  	Server Preferences
    
    Select the "Mail Menu > Mail Accounts > default" menu item to enter your
    email address and the name for your pop/imap and smtp servers.
    
    For example, the preference values might be
    
	Email Address:          cupright@earthlink.net
	Real Name:              Craig Barton Upright
	Mail Server:            pop.earthlink.net
	
	SMTP Account:           cupright@earthlink.net
	SMTP Server:            smtp.earthlink.net
	Reply To:               cupright@alumni.princeton.edu

    or they could be
    
	Email Address:          cupright@alumni.princeton.edu
	Real Name:              Craig B. Upright
	Mail Server:            imap.princeton.edu
	
	SMTP Account            cupright
	SMTP Server:            smtp.earthlink.net
	Reply To:               cupright@alumni.princeton.edu

    Note that the "Mail" server is used to view new remote messages, and the
    "smtp" is required to send new messages.  If for some reason only one of
    these server types is available, you will be able to use it to only
    read-remote/send-new e-mail messages.  We have separate account name and
    password preferences for each type of server because some users find it
    necessary to use this arrangement to peacefully exist with their ISPs.
    You must fill in the values for each server type.
    
    When you send mail, the "Email Address" and "Real Name" fields will be
    supplied as the "From:" address.  You can also set a "Reply-To:" address
    for each identity.
    
    If you need to set a "Port Number" (the default is 25), then simply
    append it to the end of the server name, as in
    
	SMTP Server:            smtp.earthlink.net:110
    
    This port number will then be parsed out when messages are sent.  Port
    numbers can also be specified for your incoming mail server.  This is an
    advanced option, consult your mail server's documentation or system
    administrator if you need to determine the correct port to use.
    
    
	  	Account Passwords

    When you perform an action that requires authorization from the remote
    server you will be prompted to enter your password for the account in a
    dialog.  The password will be retained throughout the rest of your
    ÇALPHAÈ editing session, but it will never be saved when ÇALPHAÈ quits.
    This is a security feature, since (as of this writing) none of ÇALPHAÈ's
    preference values are encrypted.
    
    If the action you're performing fails or is aborted, the password you
    entered is forgotten just in case an incorrect value was the problem in
    the first place.
    
    
	  	Preference Settings
    
    This package offers several different preference settings allowing you to
    customize its behavior.  See the "Mail Menu > Mail Menu Prefs" dialog to
    change them.  You can turn on the Mail Menu if you want to inspect them.
    
    Preferences: Menus
    
    Some of the more useful preferences include
    
	Auto Float Mailbox Window Marks
    
    Creates a floating palette with the start of each post's subject line for
    easy viewing/switching of Mail windows.
    
	Semicolon Switches Windows
    
    You can press the ';' key to toggle back and forth between the Inbox and
    Mail viewing windows.
    
	Multiple Mail View Windows
    
    Whenever you open a new Mail window from the Inbox, the contents of any
    pre-existing Mail windows can be replaced, or each message can be
    displayed in its own window.
    


	====================================================================
    
	  	Current Limitations
    
    
    * The "socket channel" connection that is created whenever you open a new
      "Inbox" browsing window is often fragile, and closes within a few
      minutes.  The connection is always explicitly disconnected when the
      Inbox window is closed to help ensure that any trashed messages are
      truly expunged and not simply left in a queue.  If it breaks while you
      are still attempting to view new messages, you will be prompted to
      re-open the Inbox.
      
    * Attachments are listed in the body of the message received, but cannot
      be downloaded -- use a different e-mail client to retrieve them.
    
    * Attachments cannot be added to outgoing mail messages.
}

proc mailTcllib.tcl {} {}

# Before we do anything else, make sure that our "mode" is initialized.
Mail::initializeMode

namespace eval Mail {}

namespace eval Mail::tcllib {
    
    global Mail::emailPattern

    variable mailAccounts
    variable currentAccount
    
    # Ensure that we have a default mail account.
    if {![info exists mailAccounts(default)]} {
	set mailAccounts(default) [list "" "" "" "" ""]
    } 
    if {![info exists currentAccount] \
      || ![info exists mailAccounts($currentAccount)]} {
        set currentAccount "default"
    } 
    
    # This is used by [Mail::tcllib::preCloseHook].
    variable mailboxName
    if {![info exists mailboxName]} {
	set mailboxName ""
    } 
    # Used by various mail routines to manage the socket connection.
    variable socketChannel
    if {![info exists socketChannel]} {
        set socketChannel ""
    } 
}

# To always be asked for confirmation before trashing a message on the remote
# server, turn this item on||To never be asked for confirmation before
# trashing a message on the remote server, turn this item off
newPref flag confirmBeforeTrashing  1       Mail
# Warn before downloading message that exceed this KByte value.
newPref var warnWhenMessagesExceed  "50"    Mail

newPref menubinding openInbox "<U<B/O" \
  Mail {Mail::tcllib::updatePreferences}
newPref menubinding viewFullHeader "<U<B/V" \
  Mail {Mail::tcllib::updatePreferences}

# Add more "Menu Shortcuts" preferences.
prefs::dialogs::setPaneLists "Mail" "Menu Shortcuts" [list \
  "openInbox" \
  "viewFullHeader" \
  ]

# Mail Windows
prefs::dialogs::setPaneLists "Mail" "Mail Windows" [list \
  "confirmBeforeTrashing" \
  "warnWhenMessagesExceed" \
  ]

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::handlerChanged" --
 # 
 # Required procedure for all Mail Handler protocols.
 # 
 # Called with "onOrOff" == 1 when Mail mode is initialized if this is the
 # current handler, or when the user changes the handler to this one.  When
 # the user switches _from_ this handler to another, this is also called but
 # with "onOrOff" == 0.
 # 
 # Registers any menu insertions, hooks, and defines the visibility of any
 # additional Mail mode preferences.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::handlerChanged {onOrOff} {
    
    global mailMenu MailmodeVars newDocTypes alpha::platform
    
    # Define tcllib specific submenus.
    menu::buildProc "mailAccounts"      {Mail::tcllib::buildAccountsMenu}
    
    if {$onOrOff} {
	menu::insert mailMenu "items" [list "after" "(-)"] \
	  "$MailmodeVars(openInbox)openInboxÉ" \
	  "$MailmodeVars(prevMessage)prevMessage" \
	  "$MailmodeVars(nextMessage)nextMessage" \
	  "\(-"
	menu::insert mailMenu "submenu" [list "after" "(-)"] \
	  "mailAccounts"
	menu::insert mailMenu "items" "(-) " \
	  "$MailmodeVars(viewFullHeader)viewFullHeader" \
	  "$MailmodeVars(trashMessage)trashMessageÉ"
	menu::insert mailMenu "items" "mailMenuPrefsÉ" \
	  "htmlColors&StylesÉ"
	if {(${alpha::platform} eq "alpha")} {
	    menu::insert mailMenu "items" [list "after" "\(-"] \
	      "<E<S$MailmodeVars(reply/ReplyToAll)reply" \
	      "<S<I$MailmodeVars(reply/ReplyToAll)replyToAll"
	} else {
	    menu::insert mailMenu "items" [list "after" "\(-"] \
	      "$MailmodeVars(reply)reply" \
	      "$MailmodeVars(replyToAll)replyToAll"
	}
    }
    # Always deregister the "requireOpenWindowsHook" set.
    set menuHookItems [list "reply" "replyToAll" "viewFullHeader" \
      "trashMessageÉ" "prevMessage" "nextMessage"]
    foreach menuItem $menuHookItems {
	hook::deregister requireOpenWindowsHook [list $mailMenu $menuItem] 1
    }
    # Adjust menu hooks as necessary.
    if {!$onOrOff} {
	hook::deregister menuBuild      {Mail::tcllib::activateHook} mailMenu
	hook::deregister activateHook   {Mail::tcllib::activateHook}
	hook::deregister activateHook   {Mail::tcllib::activateHook} Mail
	hook::deregister preCloseHook   {Mail::tcllib::preCloseHook} Mail
	# Remove the "New Document" option.
	array unset newDocTypes "New E-mail Inbox"
    } else {
	# This ensures that items are properly dimmed/enabled whenever the Mail
	# Menu is rebuilt.
	hook::register menuBuild	{Mail::tcllib::activateHook} mailMenu
	if {([lsearch -exact ${global::features} "mailMenu"] > -1)} {
	    foreach menuItem $menuHookItems {
		hook::register requireOpenWindowsHook \
		  [list $mailMenu $menuItem] 1
	    }
	    hook::register activateHook {Mail::tcllib::activateHook}
	} else {
	    hook::register activateHook {Mail::tcllib::activateHook} Mail
	}
	hook::register preCloseHook     {Mail::tcllib::preCloseHook} Mail
	# Add a "New Document" option.
	array set newDocTypes [list "New E-mail Inbox" {Mail::tcllib::newInbox}]
    } 
    
    # Adjust menu item shortcut preference visibility.
    if {$onOrOff} {
	set cmd "prefs::register"
    } else {
	set cmd "prefs::deregister"
    }
    $cmd "nextMessage"          "Mail"
    $cmd "openInbox"            "Mail"
    $cmd "prevMessage"          "Mail"
    $cmd "reply"                "Mail"
    $cmd "reply/ReplyToAll"     "Mail"
    $cmd "replyToAll"           "Mail"
    $cmd "trashMessage"         "Mail"
    $cmd "viewFullHeader"       "Mail"
    # Adjust other Mail mode preference visibility.
    $cmd "confirmBeforeTrashing"    "Mail"
    $cmd "warnWhenMessagesExceed"   "Mail"
    # Expose or remove this dialog pane.
    prefs::dialogs::hideShowPane "Mail" "Mail Windows"  $onOrOff
    
    # Define the menu build proc for the CM module.
    menu::buildProc "mailWindow" {Mail::tcllib::buildWindowMenu}
    
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::handlerHelp" --
 # 
 # Required procedure for all Mail Handler protocols. 
 # 
 # Called by "Mail Menu > Mail Menu Help" (via [Mail::handlerHelp]), open the
 # help window associated with this Mail Handler.  This is necessary because
 # the Mail Menu has no idea which [alpha::library] package registered the
 # entry in the "Mail::handlers" array.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::handlerHelp {} {
    
    package::helpWindow "mailTcllib"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::updatePreferences" --
 # 
 # Called when any of the preferences associated with this Mail Handler are
 # changed via the "Config > Mail Mode Prefs > Preferences" dialog.
 # 
 # It's not enough to rebuild the menu -- we really need to wipe the slate
 # clean first, most easily accomplished with [Mail::handlerChanged].
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::updatePreferences {prefName} {
    
    Mail::handlerChanged
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::activateHook" --
 # 
 # Dim/enable menu items that are appropriate to the active window when it is
 # brought to the front.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::activateHook {{winName ""}} {
    
    global MailmodeVars mailMenu
    
    if {![package::active mailMenu]} {
	return
    } 
    if {($winName eq "")} {
	set winName [win::Current]
    } 
    set allItems [list "reply" "replyToAll" "viewFullHeader" \
      "trashMessageÉ" "prevMessage" "nextMessage"]
    switch -- [Mail::getWindowType -w $winName] {
	"viewer" {
	    set enableList  $allItems
	    set disableList [list]
	}
	"browser" {
	    set enableList  [list "viewFullHeader" "trashMessageÉ" \
	      "prevMessage" "nextMessage"]
	    set disableList [list "reply" "replyToAll"]
	}
	default {
	    set enableList  [list]
	    set disableList $allItems
	}
    }
    # Now we dim/enable as required.
    foreach menuItem $enableList {
	enableMenuItem $mailMenu $menuItem 1
    }
    foreach menuItem $disableList {
	enableMenuItem $mailMenu $menuItem 0
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::preCloseHook" --
 # 
 # Called when a Mail window is closed.  When want to explicitly close our
 # socket channel with the Inbox browsing window is closed, this will help
 # ensure that any trashed messages are properly deleted from the server.
 # The status message might help explain to the user why something was not
 # behaving appropriately.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::preCloseHook {winName} {
    
    variable mailboxName
    
    if {($winName eq $mailboxName)} {
	Mail::tcllib::closeSocket 0
    } 
    return
}

# ===========================================================================
# 
# ×××× Mail Menu Additions ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::buildWindowMenu" --
 # 
 # Define the "Mail Window" menu for the CM.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::buildWindowMenu {} {
    
    global MailmodeVars alpha::CMArgs
    
    variable begIndex
    variable currentAccount
    variable endIndex
    variable mailboxName
    
    switch -- [Mail::getWindowType] {
	"new" {
	    set menuList [list "addCcÉ" "addBccÉ" "sendThisMessage"]
	}
	"viewer" {
	    set dim1 ""
	    set dim2 ""
	    set pat  {^Msg "([^"]+)" \(([0-9]+)\).*"([^"]+)"}
	    set match [search -n -s -f 1 -r 1 -- $pat [minPos]]
	    if {[llength $match]} {
		set pat {"([^"]+)" \(([0-9]+)\).*"([^"]+)"}
		set text [eval getText $match]
		if {[regexp -- $pat $text -> number orig folder]} {
		    if {($orig <= $begIndex($currentAccount))} {
			set dim1 "\("
		    } elseif {($orig >= $endIndex($currentAccount))} {
			set dim2 "\("
		    }
		}
	    }
	    set dots [expr {$MailmodeVars(confirmBeforeTrashing) ? "É" : ""}]
	    set menuList [list "${dim1}prevMessage" "${dim2}nextMessage" \
	      "trashThisMessage$dots" "(-)" "reply" "replyToAll" "forwardÉ"]
	}
	"browser" {
	    set pos  [lindex ${alpha::CMArgs} 0]
	    set pos0 [pos::lineStart $pos]
	    set pos1 [pos::lineEnd   $pos]
	    set text [getText $pos0 $pos1]
	    status::msg $text
	    if {[regexp {^.+ +: (.+)$} $text -> subject]} {
		if {([string length $subject] > 30)} {
		    set menuList [list "ª\([string range $subject 0 29]É"]
		} else {
		    set menuList [list "ª\($subject"]
		}
		set dots [expr {$MailmodeVars(confirmBeforeTrashing) ? "É" : ""}]
		lappend menuList "viewFullHeader" "trashThisMessage$dots"
	    } 
	}
    }
    lappend menuList "newMessage" "(-)"
    if {[win::Exists $mailboxName]} {
	lappend menuList "floatMessageMarks"
    } 
    lappend menuList "mailHandlerHelp" "mailMenuHelp" "mailMenuPrefsÉ"
    
    return [list "build" $menuList {Mail::tcllib::menuProc}]
}

proc Mail::tcllib::buildAccountsMenu {} {
    
    variable currentAccount
    variable mailAccounts
    
    set allAccounts [lsort -dictionary [array names mailAccounts]]
    if {([llength $allAccounts] == 1)} {
        set menuList [list "!¥default"]
    } else {
	set otherAccounts [lremove -- $allAccounts [list "default"]]
	set accountsList  [concat [list "default" "(-)"] $otherAccounts]
	foreach accountName $accountsList {
	    if {($accountName eq $currentAccount)} {
		lappend menuList "!¥$accountName"
	    } else {
		lappend menuList $accountName
	    }
	}
    }
    set dim  [expr {([llength $allAccounts] == 1) ? "\(" : ""}]
    set dot1 [expr {([llength $allAccounts] == 1) ? ""   : "É"}]
    set dot2 [expr {([llength $allAccounts] >  1) ? ""   : "É"}]
    lappend menuList "(-)" "Add New Identity" "Edit Identity${dot1}" \
      "${dim}Rename Identity${dot2}" "${dim}Delete IdentityÉ" \
      "(-)" "Flush Passwords" "Mail Accounts Help"
    
    return [list "build" $menuList {Mail::tcllib::menuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::menuProc" --
 # 
 # Execute Mail Menu items that were added by this Mail Handler.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::menuProc {menuName itemName} {
    
    global alpha::CMArgs
    
    variable currentAccount
    variable mailAccounts
    variable mailboxName
    
    switch -- $menuName {
        "mailAccounts" {
	    if {[info exists mailAccounts($itemName)]} {
	        Mail::tcllib::currentAccount $itemName
		prefs::modified currentAccount
		menu::buildSome "mailAccounts"
		status::msg "The new Mail Identity is \"${itemName}\""
		return
	    } 
            switch -- $itemName {
                "Add New Identity" {
		    set newName ""
		    while {1} {
			status::msg "This name will appear in the\
			  \"Mail Menu > Mail Accounts" options list."
			set p "New 'Identity' name:"
		        set newName [string trim [prompt $p $newName]]
			if {($newName eq "")} {
			    alertnote "The 'identity' name cannot be empty!"
			} elseif {![regexp {^[\w ]+$} $newName]} {
			    alertnote "The 'identity' name must be\
			      alpha-numeric."
			} elseif {[info exists mailAccounts($newName)]} {
			    alertnote "The name '${newName}' already exists."
			} else {
			    break
			}
		    }
		    Mail::tcllib::currentAccount $newName
		    if {[catch {Mail::tcllib::setAccountInfo}]} {
			array unset mailAccounts $newName
			error "cancel"
		    }
		    prefs::modified mailAccounts($newName)
		    menu::buildSome "mailAccounts"
		    status::msg "The \"${newName}\" identity has been added."
                }
                "Edit Identity" {
		    set options [lsort -dictionary [array names mailAccounts]]
		    set p "Select an identity to edit:"
		    while {1} {
			if {([llength $options] == 1)} {
			    set accountName [lindex $options 0]
			} else {
			    set accountName [listpick -p $p -- $options]
			}
			if {($accountName eq "(Finish)")} {
			    return
			} 
			Mail::tcllib::currentAccount $accountName
		        Mail::tcllib::setAccountInfo
			status::msg "The new information has been saved."
			if {([llength $options] == 1)} {
			    return
			}
			set options [concat [list "(Finish)"] \
			  [lsort -dictionary [array names mailAccounts]]]
			set p "Select another to edit, or \"Finish\""
		    }
                }
                "Rename Identity" {
		    set options [lsort -dictionary [array names mailAccounts]]
		    set p "Select an identity to rename:"
		    while {1} {
			set options [lremove -- $options [list "default"]]
			if {([llength $options] == 1)} {
			    set oldName [lindex $options 0]
			} else {
			    set oldName [listpick -p $p -- $options]
			}
			if {($oldName eq "(Finish)")} {
			    return
			} 
			set newName $oldName
			while {1} {
			    set p "New name for the '${oldName}' identity:"
			    set newName [string trim [prompt $p $newName]]
			    if {($newName eq "")} {
				alertnote "The 'identity' name cannot be empty!"
			    } elseif {![regexp {^[\w ]+$} $newName]} {
				alertnote "The 'identity' name must be\
				  alpha-numeric."
			    } elseif {[info exists mailAccounts($newName)]} {
				alertnote "The name '${newName}' already exists."
			    } else {
				break
			    }
			}
			set mailAccounts($newName) $mailAccounts($oldName)
			prefs::modified mailAccounts($newName) 
			prefs::modified mailAccounts($oldName)
			Mail::tcllib::flushPasswords $oldName
			array unset mailAccounts $oldName
			menu::buildSome "mailAccounts"
			status::msg "\"${oldName}\" has been renamed\
			  to \"${newName}\""
			if {([llength $options] == 1)} {
			    return
			}
			set options [concat [list "(Finish)"] \
			  [lsort -dictionary [array names mailAccounts]]]
			set p "Select another to rename, or \"Finish\""
		    }
                }
                "Delete Identity" {
		    set options [lsort -dictionary [array names mailAccounts]]
		    set options [lremove -- $options [list "default"]]
		    set p "Remove which identities?"
		    set deleteList [listpick -p $p -- $options]
		    foreach accountName $deleteList {
			prefs::modified mailAccounts($accountName)
			Mail::tcllib::flushPasswords $accountName
			array unset mailAccounts $accountName
		    }
		    status::msg "The identities have been removed."
		}
                "Flush Passwords" {
                    Mail::tcllib::flushPasswords
		    status::msg "All password information has been flushed."
                }
		"Mail Accounts Help" {
		    help::openGeneral "mailTcllib" "Multiple Accounts"
		}
	    }
        }
	"mailWindow" {
	    # Called from the CM.
	    set winType [Mail::getWindowType]
	    if {($winType eq "browser")} {
		switch -- $itemName {
		    "viewFullHeader" - "trashThisMessage" {
			browse::Select [lindex ${alpha::CMArgs} 0]
		    }
		}
	    } 
	    Mail::menuProc $menuName $itemName
	}
	default {
	    switch -- $itemName {
		default {
		    Mail::handlerAction $itemName
		}
	    }
        }
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::newInbox" --
 # 
 # Called by "File > New > Open Inbox" when the package: newDocument is
 # active.  Our "newDocTypes" entry is declared in the [alpha::library] init
 # script, so this might be called before Mail mode/menu has been sourced.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::newInbox {} {
    
    variable currentAccount
    variable mailAccounts
    
    loadAMode "Mail"
    set options [lsort -dictionary [array names mailAccounts]]
    if {([llength $options] == 1)} {
	set accountName [lindex $options 0]
    } else {
	set p "Open Inbox for which account?"
	set L [list $currentAccount]
	set accountName [listpick -p $p -L $L -- $options]
    }
    Mail::tcllib::currentAccount $accountName
    menu::buildSome "mailAccounts"
    if {[catch {Mail::tcllib::openInbox} result]} {
	if {[string match -nocase "*cancel*" $result]} {
	    error $result
	} else {
	    error "Cancelled -- $result"
	}
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Mail Accounts ×××× #
# 
# This section provides the support for multiple mail accounts.  All of them 
# are defined in the "mailAccounts" array, where the name of each entry is 
# the "identity" that is presented in the "Mail Menu > Mail Accounts" menu.  
# The value of each entry is a six item list:
# 
# (1) emailAddress
# (2) realName
# (3) mailServer
# (4) smtpAccount
# (5) smtpServer
# (6) replyTo
# 
# The "currentAccount" variable keeps track of the, um, current mail account.
# [Mail::tcllib::currentAccount] will update all of the variables that are
# required for other operations.  The "accountInfo" array should always have
# the variables (listed above) for the current account, as well as
# 
# (7) mailPassword
# (8) smtpPassword
# 
# which are initially empty strings.
# 
# When Alpha is first launched, we have no password information.  We query
# the user for passwords when necessary, and then save them for the duration
# of the current editing session, updating the "accountInfo" array as soon as
# the passwords are given.  If, however, some operation which requires a
# password fails or aborts the we flush that password (in case this was the
# problem in the first place.)  Password information for all accounts is kept
# in the "passwordInfo" array
# 
# When Alpha quits all password information is flushed, i.e. not saved.  This
# is a security feature, since Alpha's preferences cannot be encrypted in any
# way as of this writing.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::currentAccount" --
 # 
 # Place all of the account settings for the current account into the array
 # "accountInfo", including Server Name, Account Name, and Password.  If a
 # "newCurrent" argument is supplied, then this account is made current,
 # otherwise we use the pre-existing "currentAccount" value.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::currentAccount {{newCurrent ""}} {
    
    variable accountInfo
    variable currentAccount
    variable mailAccounts
    variable passwordInfo
    
    if {($newCurrent ne "")} {
        set currentAccount $newCurrent
    } 
    if {![info exists mailAccounts($currentAccount)]} {
        set mailAccounts($currentAccount) [list "" "" "" ""]
    } 
    array set accountInfo [list \
      "emailAddress"    [lindex $mailAccounts($currentAccount) 0] \
      "realName"        [lindex $mailAccounts($currentAccount) 1] \
      "mailServer"      [lindex $mailAccounts($currentAccount) 2] \
      "smtpAccount"     [lindex $mailAccounts($currentAccount) 3] \
      "smtpServer"      [lindex $mailAccounts($currentAccount) 4] \
      "replyTo"         [lindex $mailAccounts($currentAccount) 5] \
      ]
    # Set password information for this account.
    set mailEntry "$accountInfo(emailAddress),$accountInfo(mailServer)"
    set smtpEntry "$accountInfo(smtpAccount),$accountInfo(smtpServer)"
    if {![info exists passwordInfo($mailEntry)]} {
	set passwordInfo($mailEntry) ""
    }
    if {![info exists passwordInfo($smtpEntry)]} {
	set passwordInfo($smtpEntry) ""
    } 
    array set accountInfo [list \
      "mailPassword"    $passwordInfo($mailEntry) \
      "smtpPassword"    $passwordInfo($smtpEntry) \
      ]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::setAccountInfo" --
 # 
 # Create a dialog for the user to fill in account information.  We can set
 # all server fields here, or just those for "mail" or "smtp".  We assume
 # that we're dealing with the current mail account.
 # that the "mailAccounts($mailAccounts)" entry has already been created
 # before this has been called, and that "ma
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::setAccountInfo {{which "all"}} {
    
    global alpha::application
    
    variable accountInfo
    variable currentAccount
    variable mailAccounts
    variable passwordInfo
    
    # Obtain username, password, server information from the user.
    set dialogScript [list dialog::make -title "Mail Server Info" \
      -addbuttons [list \
      "Help" \
      "Click here to close this dialog and obtain more information" \
      "help::openGeneral {mailTcllib Help} {Server Preferences} ; \
      set retVal {cancel} ; set retCode {1}"]]
    set dialogPane [list "" \
      [list "text" "Please set the account and server information below\
      for your '${currentAccount}' mail identity.\r"]]
    if {($which eq "all") || ($which eq "mail")} {
	lappend dialogPane \
	  [list "var"      "Email Address"  $accountInfo(emailAddress)] \
	  [list "var"      "Real Name"      $accountInfo(realName)] \
	  [list "var"      "Mail Server:"   $accountInfo(mailServer)] \
	  [list "password" "Mail Password:" $accountInfo(mailPassword)]
    } 
    if {($which eq "all") || ($which eq "smtp")} {
	lappend dialogPane \
	  [list "var"      "SMTP Account:"  $accountInfo(smtpAccount)] \
	  [list "var"      "SMTP Server:"   $accountInfo(smtpServer)] \
	  [list "var"      "Reply To:"      $accountInfo(replyTo)] \
	  [list "password" "SMTP Password:" $accountInfo(smtpPassword)]
    } 
    lappend dialogPane \
      [list "text" "\rServer and Account Name information will be saved\
      between editing sessions.  Password information will always be flushed\
      when ${alpha::application} quits.\r"]
    lappend dialogScript $dialogPane
    set results [eval $dialogScript]
    # Store this information.
    switch -- $which {
        "mail" {
	    set emailAddress [lindex $results 0]
	    set realName     [lindex $results 1]
	    set mailServer   [lindex $results 2]
	    set mailAccounts($currentAccount) \
	      [lreplace $mailAccounts($currentAccount) 0 2 \
	      $emailAddress $realName $mailServer]
	    set mailEntry "${emailAddress},${mailServer}"
	    set passwordInfo($mailEntry) [lindex $results 3]
        }
        "smtp" {
	    set smtpAccount  [lindex $results 0]
	    set smtpServer   [lindex $results 1]
	    set replyTo      [lindex $results 2]
	    set mailAccounts($currentAccount) \
	      [lreplace $mailAccounts($currentAccount) 3 5 \
	      $smtpAccount $smtpServer $replyTo]
	    set smtpEntry "${smtpAccount},${smtpServer}"
	    set passwordInfo($smtpEntry) [lindex $results 3]
        }
        "all" {
	    set emailAddress [lindex $results 0]
	    set realName     [lindex $results 1]
	    set mailServer   [lindex $results 2]
	    set smtpAccount  [lindex $results 4]
	    set smtpServer   [lindex $results 5]
	    set replyTo      [lindex $results 6]
	    set mailAccounts($currentAccount) [list \
	      $emailAddress $realName $mailServer \
	      $smtpAccount $smtpServer $replyTo]
	    set mailEntry "${emailAddress},${mailServer}"
	    set smtpEntry "${smtpAccount},${smtpServer}"
	    set passwordInfo($mailEntry) [lindex $results 3]
	    set passwordInfo($smtpEntry) [lindex $results 7]
        }
    }
    prefs::modified mailAccounts($currentAccount)
    # Make this account the current one, to set variables.
    Mail::tcllib::currentAccount $currentAccount
    menu::buildSome "mailAccounts"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::setPassword" --
 # 
 # Create a dialog allowing the user to set password information for the
 # current mail account.  We assume that [Mail::tcllib::currentAccount] has
 # been called prior to this.  At the end we call that procedure again to
 # ensure that the new password values are available to the calling proc.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::setPassword {{which "all"}} {
    
    variable accountInfo
    variable currentAccount
    variable passwordInfo
    
    # Original password information.
    set mailEntryName   "$accountInfo(emailAddress),$accountInfo(mailServer)"
    set smtpEntryName   "$accountInfo(smtpAccount),$accountInfo(smtpServer)"
    set newMailPassword $accountInfo(mailPassword)
    set newSmtpPassword $accountInfo(smtpPassword)
    # Create a dialog to present to the user.
    set dialogScript [list dialog::make -title "Password Information" \
      -addbuttons [list \
      "Help" \
      "Click here to close this dialog and obtain more information" \
      "help::openGeneral {mailTcllib Help} {Account Passwords} ; \
      set retVal {cancel} ; set retCode {1}"]]
    set dialogPane   [list "" \
      [list "text" "Please enter the password for the Mail Account\
      associated with your '${currentAccount}' identity.\r"] \
      [list "text" "This will be remembered during this editing session,\
      and flushed when ${alpha::application} quits.\r"]]
    switch -- $which {
        "all" {
	    status::msg "Enter password for \"$accountInfo(emailAddress)\" É"
	    lappend dialogPane \
	      [list "password" "Mail Password:" ""] \
	      [list "password" "SMTP Password:" ""] \
        }
        "mail" {
	    status::msg "Enter password for \"$accountInfo(emailAddress)\" É"
	    lappend dialogPane \
	      [list "password" "Mail Password:" ""]
	}
	"smtp" {
	    status::msg "Enter password for \
	      \"$accountInfo(smtpAccount) , $accountInfo(smtpServer)\" É"
	    lappend dialogPane \
	      [list "password" "SMTP Password:" ""]
        }
        default {
            error "Unknown option: $which"
        }
    }
    lappend dialogScript $dialogPane
    set results [eval $dialogScript]
    status::msg ""
    # Set our new password information.
    switch -- $which {
	"all" {
	    set newMailPassword [lindex $results 0]
	    set newSmtpPassword [lindex $results 1]
	}
	"mail" {
	    set newMailPassword [lindex $results 0]
	}
	"smtp" {
	    set newSmtpPassword [lindex $results 0]
	}
    }
    array set passwordInfo [list \
      $mailEntryName    $newMailPassword \
      $smtpEntryName    $newSmtpPassword \
      ]
    Mail::tcllib::currentAccount
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::flushPasswords" --
 # 
 # Forget the password information for a list of account names and a server
 # type.  We call [Mail::tcllib::currentAccount] at the end to ensure that
 # the password information has been flushed from the "accountInfo" array for
 # any calling procedure which is going to continue.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::flushPasswords {{accountNames "all"} {which "all"}} {
    
    variable currentAccount
    variable mailAccounts
    variable passwordInfo
    
    if {($accountNames eq "all")} {
        set accountNames [array names mailAccounts]
    } 
    set passwordEntries [list]
    foreach accountName $accountNames {
	if {![info exists mailAccounts($accountName)]} {
	    continue
	} 
	array set accountInfo [list \
	  "emailAddress"    	[lindex $mailAccounts($accountName) 0] \
	  "mailServer"          [lindex $mailAccounts($accountName) 2] \
	  "smtpAccount"         [lindex $mailAccounts($accountName) 3] \
	  "smtpServer"          [lindex $mailAccounts($accountName) 4] \
	  ]
	if {($which eq "all") || ($which eq "mail")} {
	    lappend passwordEntries \
	      "$accountInfo(emailAddress),$accountInfo(mailServer)"
	} 
	if {($which eq "all") || ($which eq "smtp")} {
	    lappend passwordEntries \
	      "$accountInfo(smtpAccount),$accountInfo(smtpServer)"
	} 
    }
    foreach passwordEntry $passwordEntries {
	unset -nocomplain passwordInfo($passwordEntry)
    }
    Mail::tcllib::currentAccount
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Reading Mail - pop3 ×××× #
# 
# We use the Tcl-lib package "pop3" to download messages from the user's
# remote server, and then pass this information to the appropriate Mail Menu
# procedures for the browsing/viewing of these messages.  At present we can
# only obtain information for the main "Inbox" on the remote server.
# 
# The procedure [Mail::tcllib::openInbox] is the only one which opens a new
# socket channel, which is then used by other procedures.  Whenever the main
# Inbox browsing window is closed, we automatically close the socket channel.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::openInbox" --
 # 
 # The Tcl-lib package "pop3" provides us with some very easy to use commands
 # to open a "socket channel" to the remote server.  Once this is done we
 # find out how many messages are on the server, and ask the user which ones
 # should be downloaded.
 # 
 # If the server will respond to a [::pop3::top] call then we just download
 # the headers for parsing -- this could involve a lot less bandwidth.  In
 # [Mail::tcllib::goToMatch] we then download the message in its entirety.
 # 
 # Otherwise, we download these messages en masse, storing them in the
 # variable "inboxContents" for use later.  
 # 
 # For each message, we scan the fields for the "Sender:" and "Subject:"
 # lines and pass this information along to [Mail::createMailboxWindow] to
 # create the MAILBOX browsing window.
 # 
 # Note: since this is called by [Mail::handlerAction] we don't need to worry
 # about adding "*cancel*" strings to any error messages, that will be taken
 # care of for us.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::openInbox {} {
    
    global MailmodeVars Mail::emailPattern
    
    variable accountInfo
    variable begIndex
    variable currentAccount
    variable endIndex
    variable inboxContents
    variable inboxEnvelopes
    variable mailboxName
    variable passwordInfo
    variable socketChannel
    variable trashedMsgs
    
    # Preliminaries.
    ::package require pop3
    Mail::tcllib::currentAccount
    Mail::tcllib::closeSocket 1
    set trashedMsgs(Inbox) [list]
    array unset inboxContents
    array unset inboxEnvelopes
    set openScript [list ::pop3::open -retr-mode "list"]
    # Remember where we are.
    if {[win::Exists $mailboxName]} {
	set currentLine [getText -w $mailboxName \
	  [pos::lineStart -w $mailboxName [getPos -w $mailboxName]] \
	  [pos::lineEnd   -w $mailboxName [getPos -w $mailboxName]]]
	regexp -- {(°(.*)--([0-9]+))} $currentLine -> folderIndString
    } 
    # Confirm that we have account, server information.
    foreach itemName [list "emailAddress" "mailServer"] {
	if {($accountInfo($itemName) eq "")} {
	    Mail::tcllib::setAccountInfo "mail"
	    break
	} 
    }
    # Confirm that we have a password.
    if {($accountInfo(mailPassword) eq "")} {
	Mail::tcllib::setPassword "mail"
    } 
    # Add the required information to the script to open the socket channel.
    if {[regexp -- {^(.+):([0-9]+)$} $accountInfo(mailServer) -> server port]} {
	lappend openScript $server
    } else {
	lappend openScript $accountInfo(mailServer)
        set port ""
    }
    if {[regsub -- {@.+$} $accountInfo(emailAddress) {} accountName]} {
        lappend openScript $accountName
    } else {
        lappend openScript $accountInfo(emailAddress)
    }
    lappend openScript $accountInfo(mailPassword)
    if {($port ne "")} {
        lappend openScript $port
    }
    # Open a socket channel, found out how many messages are on the server.
    watchCursor
    status::msg [set msg "Opening '$accountInfo(emailAddress)' Inbox É"]
    if {[catch {eval $openScript} socketChannel]} {
	Mail::tcllib::flushPasswords [list $currentAccount] "mail"
	error $socketChannel
    } 
    if {[catch {::pop3::status $socketChannel} status]} {
	Mail::tcllib::flushPasswords [list $currentAccount] "mail"
	error $status
    } 
    set sizes [Mail::tcllib::calculateSize [lindex $status 1]]
    if {([lindex $sizes 0] < 1024)} {
        append inboxSize [lindex $sizes 0] " KBytes"
    } else {
	append inboxSize [lindex $sizes 1] " MBytes"
    }
    status::msg "$msg [lindex $status 0] messages, $inboxSize"
    if {![lindex $status 0]} {
	Mail::tcllib::closeSocket 1
	alertnote "The '$accountInfo(emailAddress)' Inbox is empty."
	return
    }
    if {![info exists begIndex($currentAccount)] \
      || ($begIndex($currentAccount) > [lindex $status 0])} {
        set begIndex($currentAccount) "1"
    } 
    if {![info exists endIndex($currentAccount)] \
      || ($endIndex($currentAccount) > [lindex $status 0])} {
        set endIndex($currentAccount) [lindex $status 0]
    } 
    # Ask the user about which messages to download.
    set dialogScript [list dialog::make -title "Opening InboxÉ" \
      -addbuttons [list \
      "Help" \
      "Click here to close this dialog and obtain more information" \
      "help::openGeneral {mailTcllib Help} {Inbox Browsing Window} ; \
      set retVal {cancel} ; set retCode {1}"] \
      [list "" \
      [list "text" "There are [lindex $status 0] messages in the remote server.\
      Please indicate the starting/ending index of the messages you would like\
      to view.\r"] \
      [list "var" "First Message:" $begIndex($currentAccount)] \
      [list "var" "Last Message:"  $endIndex($currentAccount)] \
      [list "text" "\(More messages take longer to download and parseÉ)"]]]
    if {[catch {eval $dialogScript} result]} {
	Mail::tcllib::flushPasswords [list $currentAccount] "mail"
        Mail::tcllib::closeSocket 0
	return
    } 
    # Obtain our specified Inbox envelopes.
    set begIndex($currentAccount) [set idx1 [lindex $result 0]]
    set endIndex($currentAccount) [set idx2 [lindex $result 1]]
    for {set i $idx1} {($i <= $idx2)} {incr i} {
	watchCursor
	Mail::tcllib::getEnvelope $i "$msg message $i of $idx2"
    }
    # Now we need to compile the information we have.
    set mailMessages [list]
    set fromSubjectPat {^(from|subject): (.*)}
    set envelopeIndices [lsort -dictionary [array names inboxEnvelopes]]
    foreach envelopeIndex $envelopeIndices {
	if {![string length $inboxEnvelopes($envelopeIndex)]} {
	    continue
	} 
	unset -nocomplain from subject
	set envLines [split $inboxEnvelopes($envelopeIndex) "\r\n"]
	for {set i 0} {($i < [llength $envLines])} {incr i} {
	    set envLine [lindex $envLines $i]
	    if {[regexp -nocase -- $fromSubjectPat $envLine -> which what]} {
		set which [string tolower $which]
	        set $which $what
		while {1} {
		    set nextEnvLine [lindex $envLines [expr {$i + 1}]]
		    if {[regexp {^[\t ]+\S} $nextEnvLine]} {
			append $which $nextEnvLine
			incr i
		    } else {
			break
		    }
		} 
	    } 
	    if {[info exists from] && [info exists subject]} {
		break
	    }
	}
	foreach field [list "from" "subject"] {
	    if {![info exists $field]} {
	        set $field "(none)"
	    } 
	}
	regexp -- ${Mail::emailPattern} $from -> from
	lappend mailMessages [list $envelopeIndex $from $subject]
    } 
    # Create the new Inbox browsing window.
    set result [Mail::createMailboxWindow "Inbox" $mailMessages]
    set mailboxName  [lindex $result 0]
    # Go to where we were.
    if {[info exists folderIndString] && [win::Exists $mailboxName]} {
	set match [search -w $mailboxName -s -n -f 1 -r 0 -- \
	  $folderIndString [minPos -w $mailboxName]]
	if {[llength $match]} {
	    goto -w $mailboxName [lindex $match 0]
	    browse::Down $mailboxName
	} 
    }
    status::msg "$msg finished"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::goToMatch" --
 # 
 # Called in a Mailbox browsing window when the user presses Return or Enter.
 # 
 # All of the manipulation we do for the "idx" and "originalNum" variables is
 # really support for the [Mail::tcllib::trashMessage] routine.  It might be
 # a bit suspect ...
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::goToMatch {args} {
    
    global MailmodeVars
    
    variable trashedMsgs
    
    win::parseArgs w
    
    # Determine our index number.
    set pos0 [pos::lineStart -w $w [getPos -w $w]]
    set pos1 [pos::nextLineStart -w $w $pos0]
    set text [getText -w $w $pos0 $pos1]
    if {![regexp -- {°(.+)--([0-9]+)} $text -> folder ind]} {
	error "Cancelled -- could not locate e-mail specifics in this line."
    }
    set deleted 0
    for {set i 1} {$i < $ind} {incr i} {
	if {([lsearch -exact $trashedMsgs($folder) $i] >= 0)} {
	    incr deleted
	}
    }
    # Start to create our "args" list.
    set idx1 [expr {$ind - $deleted}]
    set idx2 $ind
    set args [list $folder $idx1 $idx2]
    
    # Separate the body's content from the e-mail header fields.
    set emailFieldNames [list "from" "to" "subject" "sender" "reply-to" \
      "date" "cc" "content-type" "content-transfer-encoding"]
    set fieldPattern "^([join $emailFieldNames {|}]): (.*)"
    set content ""
    set msg "Downloading message (# ${idx2}) É"
    set messageLines [split [Mail::tcllib::getMessage $idx2 1 $msg] "\r\n"]
    for {set i 0} {($i < [llength $messageLines])} {incr i} {
	set msgLine [lindex $messageLines $i]
	if {[regexp -nocase -- $fieldPattern $msgLine -> which what]} {
	    set which [string tolower $which]
	    set $which $what
	    while {1} {
		set nextMessageLine [lindex $messageLines [expr {$i + 1}]]
		if {[regexp {^[\t ]+\S} $nextMessageLine]} {
		    append $which $nextMessageLine
		    incr i
		} else {
		    break
		}
	    } 
	} elseif {![string length $msgLine]} {
	    set content [join [lrange $messageLines [incr i] end] "\r"]
	    break
	}
    }
    # Add the body contents.
    lappend args $content
    # Add additional arguments.
    foreach fieldName $emailFieldNames {
	if {![info exists $fieldName]} {
	    set $fieldName ""
	} 
	lappend args $fieldName [set $fieldName]
    }
    
    eval Mail::createViewWindow $args
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::viewFullHeader" --
 # 
 # Open a new window containing the full header fields.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::viewFullHeader {} {
    
    # Preliminaries
    set winType [Mail::getWindowType]
    if {($winType ne "viewer") && ($winType ne "browser")} {
	error "There is no message to view full headers."
    }
    watchCursor
    # Is this a browsing or a viewing window?
    if {($winType eq "browser")} {
	set pos0 [pos::lineStart [getPos]]
	set pos1 [pos::lineEnd   [getPos]]
	set text [getText $pos0 $pos1]
	if {![regexp -- {°(.*)--([0-9]+)} $text -> folder index]} {
	    status::msg "Couldn't find the message index number."
	    return
	}
    } else {
	set pos  [lindex [search -s -f 1 -r 1 -- {^Msg} [minPos]] 0]
	set pat  {"([^"]+)" \(([0-9]+)\).*"([^"]+)"}
	set text [getText $pos [pos::nextLineStart $pos]]
	regexp -- $pat $text -> number index folder
    }
    # Do we already have this window open?
    set n "* MAIL (${index}) Full Header Contents *"
    if {[win::Exists $n]} {
	bringToFront $n
	return
    }
    # Get our content, and place it in a new window.
    set textLines ""
    status::msg [set msg "Obtaining full header information É"]
    set msg1 "Downloading message (# ${index}) É"
    set msgLines [split [Mail::tcllib::getMessage $index 1 $msg1] "\r\n"]
    for {set i 0} {($i < [llength $msgLines])} {incr i} {
        set msgLine [lindex $msgLines $i]
	if {[string length $msgLine]} {
	    lappend textLines $msgLine
	} else {
	    lappend textLines "" ">[string repeat = 78]<" ""
	    set textLines [concat $textLines [lrange $msgLines [incr i] end]]
	    break
	}
    }
    set text [join $textLines "\r"]
    set w [Mail::createWindow "header" $n $text]
    goto -w $w [minPos -w $w]
    Mail::colorizeWindow
    winReadOnly $w
    status::msg "$msg finished."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::trashMessage" --
 # 
 # Based on [Mail::eudora::moveToMailbox].
 # 
 # The code in this procedure works, but it seems like the socket connection
 # established by "pop3" is somewhat fragile and breaks after several minutes
 # of inactivity.  Because our index numbers are crucial to determine which
 # message should actually be trashed, and because these indices are specific
 # to the socket channel that created the original list, we will only attempt
 # to delete the message if the connection is still valid.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::trashMessage {} {
    
    global MailmodeVars
    
    variable mailboxName
    variable socketChannel
    variable trashedMsgs
    
    set winType [Mail::getWindowType]
    if {($winType ne "viewer") && ($winType ne "browser")} {
	error "There is no message to trash in the active window."
    }
    # Preliminaries -- make sure that our connection is still valid.
    if {[catch {::pop3::status $socketChannel}]} {
        set q "Sorry, the socket channel that created the original list\
	  of e-mail messages has been lost.  You need to close and re-open\
	  your Inbox browsing window.\rWould you like to do that now?"
	if {[dialog::yesno -y "Yes" -n "Cancel" $q]} {
	    Mail::handlerAction "openInbox"
	} 
	return
    } 
    if {$MailmodeVars(confirmBeforeTrashing)} {
	set dialogScript [list dialog::make -title "Trash Message?" \
	  -addbuttons [list \
	  "Help" \
	  "Click here to close this dialog and obtain more information" \
	  "help::openGeneral {mailTcllib Help} {Deleting Remote Messages} ; \
	  set retVal {cancel} ; set retCode {1}"] \
	  [list "" \
	  [list "text" "Are you sure that you want to delete this message?\
	  This action cannot be undone.\r"] \
	  [list "flag" "Always confirm before trashing" 1]]]
	set result [eval $dialogScript]
	if {![lindex $result 0]} {
	    set MailmodeVars(confirmBeforeTrashing) "0"
	    prefs::modified MailmodeVars(confirmBeforeTrashing)
	} 
    } 
    # Is this a browsing or a viewing window?
    if {($winType eq "browser")} {
	set text [getText [getPos] [pos::nextLineStart [getPos]]]
	if {![regexp -- {°(.*)--([0-9]+)} $text -> folder orig]} {
	    status::msg "Couldn't find the message to delete."
	    return
	}
	set deleted 0
	for {set i 1} {$i < $orig} {incr i} {
	    if {([lsearch -exact $trashedMsgs($folder) $i] >= 0)} {
		incr deleted
	    }
	}
	set number [expr {$orig - $deleted}]
    } else {
	set pos  [lindex [search -s -f 1 -r 1 -- {^Msg} [minPos]] 0]
	set pat  {"([^"]+)" \(([0-9]+)\).*"([^"]+)"}
	set text [getText $pos [pos::nextLineStart $pos]]
	regexp -- $pat $text -> number orig folder
    }
    status::msg [set msg "Deleting msg $number ($orig) of folder '$folder' É"]
    ::pop3::delete $socketChannel $orig
    
    lappend trashedMsgs($folder) $orig
    
    set viewerWindow [Mail::findViewerWindow]
    # Adjust current browsing/viewing windows as appropriate.
    # (This should be cleaned up...)
    if {[win::Exists $mailboxName]} {
	# Browse window present: delete the message and adjust the selection.
	set w $mailboxName
	setWinInfo -w $w read-only 0
	set inds [search -w $w -s -f 1 -r 1 -- "°${folder}--$orig\$" [minPos]]
	set pos0 [pos::lineStart -w $w     [lindex $inds 0]]
	set pos1 [pos::nextLineStart -w $w [lindex $inds 0]]
	deleteText -w $w $pos0 $pos1
	goto -w $w [pos::nextLineStart -w $w $pos0]
	if {[string length [search -w $w -s -n -f 1 -r 0 -- {°} [minPos]]]} {
	    # We have more messages in the browsing window.
	    setWinInfo -w $w dirty 0
	    setWinInfo -w $w read-only 1
	    browse::Up $w
	} else {
	    # We don't have any more messages to display.
	    setWinInfo -w $w dirty 0
	    killWindow -w $w
	    if {[win::Exists $viewerWindow]} {
	        killWindow -w $viewerWindow
	    } 
	    status::msg "$msg finished."
	    return
	}
    } elseif {[win::Exists $viewerWindow]} {
	# Only the viewer window was present.  (This probably means that the
	# socket channel was closed and we never got here.)
	killWindow -w $viewerWindow
	status::msg "$msg finished."
        return
    } else {
	# ??  How did we get this far without a browser or viewer window?
	status::msg "$msg finished."
        return
    }
    # Advance to the next message?
    if {[win::Exists $viewerWindow]} {
	if {$MailmodeVars(multipleMailViewWindows) \
	  && [regexp -- "MAIL \\(${orig}\\) " $viewerWindow]} {
	    killWindow -w $viewerWindow
	} 
	set pos [getPos -w $mailboxName]
	browse::Select $pos $mailboxName
	browse::Goto $mailboxName
    } 
    status::msg "$msg finished."
    return
}

# ===========================================================================
# 
# ×××× 'pop3' Socket Channel ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::getEnvelope" --
 # 
 # Get the envelope containing all header information for the given "index"
 # message on the remote server.  If [::pop3::top] works, then that is the
 # preferred method.  Some servers don't accept this command, however, in
 # which case we download the entire message and then parse it.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::getEnvelope {index {msg ""}} {
    
    variable inboxEnvelopes
    variable socketChannel
    
    if {![info exists inboxEnvelopes($index)]} {
	watchCursor
	if {[string length $msg]} {
	    status::msg $msg
	} 
	if {[catch {::pop3::top $socketChannel $index 0} envelope]} {
	    set envelope [list]
	    switch -- [Mail::tcllib::checkMessageSize $index] {
		"-1" {
		    # Downloading message was rejected.
		    set mailMessage ""
		}
		"0" {
		    # New limit was set.
		    return [Mail::tcllib::getEnvelope $index $msg]
		}
		"1" {
		    # Downloading message was approved.
		    set mailMessage [Mail::tcllib::getMessage $index 0 $msg]
		}
	    }
	    foreach msgLine [split $mailMessage "\r\n"] {
		if {[string length $msgLine]} {
		    lappend envelope $msgLine
		} else {
		    break
		}
	    }
	    set envelope [join $envelope "\r"]
	}
	set inboxEnvelopes($index) $envelope
    }
    return [string trim $inboxEnvelopes($index)]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::getMessage" --
 # 
 # Get a message from the Inbox of the remote server.  If [::pop3::top ...]
 # failed above, we've already downloaded and stored each message's content
 # (including the full header information) in the "inboxContents" variable.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::getMessage {index {checkSize 1} {msg ""}} {
    
    variable inboxContents
    variable socketChannel
    
    if {[info exists inboxContents($index)]} {
        set message $inboxContents($index)
    } elseif {![catch {::pop3::status $socketChannel}]} {
	if {$checkSize} {
	    switch -- [Mail::tcllib::checkMessageSize $index] {
		"-1"    {error "cancel"}
		"0"     {Mail::tcllib::getMessage $index 1 $msg}
	    }
	} 
	watchCursor
	if {[string length $msg]} {
	    status::msg $msg
	} 
	set message [lindex [::pop3::retrieve $socketChannel $index] 0]
	set inboxContents($index) $message
	if {[string length $msg]} {
	    status::msg "$msg finished."
	} 
    } else {
	set q "Sorry, the socket channel that created the original list\
	  of e-mail messages has been lost.  You need to close and re-open\
	  your Inbox browsing window.\rWould you like to do that now?"
	if {[dialog::yesno -y "Yes" -n "Cancel" $q]} {
	    Mail::handlerAction "openInbox"
	} 
	return -code return
    }
    return $message
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::checkMessageSize" --
 # 
 # Make sure the we don't start downloading a 2 MByte attachment.  If the
 # size of the message is less than our "warnWhenMessagesExceed" limit, then
 # we do nothing.  Otherwise we ask the user if we should continue, offering
 # the option to set a new warning limit.
 # 
 # Results:
 # 
 # "-1" -- Limit was reached, and the user declined the download.
 # "0"  -- The user set a new limit.  Calling code should check again.
 # "1"  -- Limit was not reached, or the user approved the download.
 # 
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::checkMessageSize {index} {
    
    global MailmodeVars
    
    variable socketChannel
    
    set bytes  [lindex [::pop3::list $socketChannel $index] 1]
    set sizes  [Mail::tcllib::calculateSize $bytes]
    set KBytes [lindex $sizes 0]
    if {($KBytes < $MailmodeVars(warnWhenMessagesExceed))} {
	return 1
    }
    set MBytes [lindex $sizes 1]
    if {($KBytes < 1024)} {
	append messageSize $KBytes " KBytes."
    } else {
	append messageSize $MBytes " MBytes!!"
    }
    set q "The message you are about to retrieve (# $index)\
      \ris ${messageSize}\r\rDo you want to download this message?\
      \r\r(Current \"Warn When É\" limit is\
      $MailmodeVars(warnWhenMessagesExceed) KBytes.)"
    switch -- [buttonAlert $q "Yes" "No" "Set New LimitÉ"] {
	"No" {
	    return -1
	}
	"Set New LimitÉ" {
	    status::msg "You will be warned when you are about to\
	      download messages greater than this value."
	    set p "Set a new limit (in KBytes) :"
	    set newLimit $MailmodeVars(warnWhenMessagesExceed)
	    while {1} {
		set newLimit [string trim [prompt $p $newLimit]]
		if {![string length $newLimit]} {
		    alertnote "The new limit cannot be empty!"
		} elseif {![regexp {^[0-9]+$} $newLimit]} {
		    alertnote "The new limit must be a number."
		} else {
		    break
		}
	    }
	    set MailmodeVars(warnWhenMessagesExceed) $newLimit
	    prefs::modified MailmodeVars(warnWhenMessagesExceed)
	    status::msg "The new limit value has been saved."
	    return 0
	}
	"Yes" {
	    return 1
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::calculateSize" --
 # 
 # Convert an octet (8 bit byte) value into KBytes and MBytes.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::calculateSize {octets} {
    
    set KBytes [expr $octets / 1024]
    set MBytes [format {%.1f} [expr {$KBytes / 1024.0}]]
    return [list $KBytes $MBytes]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::closeSocket" --
 # 
 # Attempt to close the current socket channel.  Returns 1 if this was done
 # gracefully, 0 if the connection was already closed.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::closeSocket {{quietly 0}} {
    
    variable accountInfo
    variable socketChannel
    
    if {!$quietly} {
	status::msg [set msg "Closing socket channel to\
	  '$accountInfo(mailServer)' É"]
    } 
    if {![catch {::pop3::status $socketChannel}] \
      && ![catch {::pop3::close $socketChannel}]} {
	set result 1
    } else {
	set result 0
    }
    set socketChannel ""
    if {!$quietly} {
	set done [expr {$result ? "finished." : "channel wasn't open."}]
	status::msg "$msg $done"
    }
    return $result
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Sending Mail - smtp ×××× #
# 
# We use the Tcl-lib packages "smtp" and "mime" to send e-mails internally.
# All of the procedures in this section are called by [Mail::sendCreatedMsg],
# so their names and arguments cannot be changed.
# 

proc Mail::tcllib::checkSystem {} {
    
    variable accountInfo
    
    Mail::tcllib::currentAccount
    # Confirm that we have account, server information.
    foreach itemName [list "smtpAccount" "smtpServer"] {
	if {($accountInfo($itemName) eq "")} {
	    Mail::tcllib::setAccountInfo "smtp"
	    break
	} 
    }
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::PrepareToSend" --
 # 
 # Reset the e-mail field information.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::PrepareToSend {} {
    
    global alpha::application
    
    Mail::tcllib::currentAccount
    
    variable accountInfo
    variable msgFields
    variable msgHeader
    
    # These are the package that make this one possible.
    foreach pkg [list "smtp" "mime"] {
	::package require $pkg
    }
    # Our "msgFields" array.
    array unset msgFields
    foreach item [list "to" "content" "subject"] {
	set msgFields($item) ""
    }
    # Create "From" and "Reply-To" fields.
    set replyToField ""
    set fromField    ""
    if {[string length $accountInfo(replyTo)]} {
	if {[string length $accountInfo(realName)]} {
	    set replyToName [string trim $accountInfo(realName)]
	    set replyToName [string trim $replyToName "\""]
	    append replyToField "\"" $replyToName "\"" " "
	    append fromField    "\"" $replyToName "\"" " "
	} 
	set replyToAddress $accountInfo(replyTo)
	set replyToAddress [string trim $replyToAddress]
	set replyToAddress [string trimleft  $replyToAddress "<"]
	set replyToAddress [string trimright $replyToAddress ">"]
	if {[regexp ${Mail::emailPattern} $replyToAddress]} {
	    append replyToField "<" $replyToAddress ">"
	} 
    }
    set fromAddress $accountInfo(emailAddress)
    set fromAddress [string trim $fromAddress]
    set fromAddress [string trimleft  $fromAddress "<"]
    set fromAddress [string trimright $fromAddress ">"]
    if {![regexp ${Mail::emailPattern} $fromAddress]} {
	append fromAddress "@" $accountInfo(mailServer)
    }
    append fromField "<" $fromAddress ">"
    # Our list of optional headers.
    append xMailer ${alpha::application} "'s Mail Menu" \
      " (" [alpha::package versions mailTcllib] ") " \
      "<http://www.purl.org/net/alpha/wiki/>"
    set msgHeader [list \
      [list "X-Mailer"  $xMailer] \
      [list "From"      $fromField] \
      ]
    if {[string length $replyToField] && ($replyToField ne $fromField)} {
	lappend msgHeader [list "Reply-To" $replyToField]
    } 
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::SetField" --
 # 
 # For each field, add it to either the "msgFields" array or the "msgHeader"
 # list.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::SetField {field value} {
    
    variable msgFields
    variable msgHeader
    
    switch -- [string tolower $field] {
	"to" - "content" - "subject" {
	    set msgFields($field) $value
	}
	default {
	    if {[string length $value]} {
		lappend msgHeader [list $field $value]
	    } 
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::tcllib::QueueToSend" --
 # 
 # Using the "smtp" package, create a string and a series of arguments to
 # pass onto [smtp::sendmessage].  At present we query the user each time for
 # their username and password, saving the values between editing sessions.
 # We could have a separate dialog pane for this information.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::tcllib::QueueToSend {} {
    
    global alpha::application Mail::emailPattern
    
    variable accountInfo
    variable currentAccount
    variable msgFields
    variable msgHeader
    variable passwordInfo
    
    # Preliminaries.
    Mail::tcllib::currentAccount
    foreach item [list "to" "content" "subject"] {
	if {![string length $msgFields($item)]} {
	    alertnote "The '${item}' field in the e-mail was empty!"
	    error "Cancelled -- the '${item}' field in the e-mail was empty."
	} 
    }
    watchCursor
    # Confirm that we have a password.
    if {($accountInfo(smtpPassword) eq "")} {
	Mail::tcllib::setPassword "smtp"
    } 
    status::msg "Sending e-mail É"
    # Set up our script for sending the e-mail.
    regsub -all "\r" $msgFields(content) "\n" content
    set token [mime::initialize -canonical text/plain -string $content]
    mime::setheader $token Subject $msgFields(subject)
    set args [list \
      -atleastone       "1" \
      -header           [list "To" $msgFields(to)] \
      -username         $accountInfo(smtpAccount) \
      -password         $accountInfo(smtpPassword) \
      ]
    # Add the "-servers" argument, and a "-ports" argument if necessary.
    if {[regexp -- {^(.+):([0-9]+)$} $accountInfo(smtpServer) -> server port]} {
	lappend args "-servers" [list $server] "-ports" [list $port]
    } else {
	lappend args "-servers" [list $accountInfo(smtpServer)]
    }
    # Add remaining message header arguments.
    foreach headerList $msgHeader {
	lappend args "-header" $headerList
    }
    # Now we send the e-mail.
    if {[catch {eval [list smtp::sendmessage $token] $args} result]} {
	dialog::alert "Error:\r\r$result"
	error "Cancelled -- Message was not sent."
	Mail::tcllib::flushPasswords [list $currentAccount] "smtp"
    } elseif {[llength $result]} {
	foreach item $result {
	    dialog::alert "Posting failure: [lindex $item 0]\
	      \r\r[lindex $item 2]\r\r(Error code [lindex $item 1])"
	}
	Mail::tcllib::flushPasswords [list $currentAccount] "smtp"
	error "Cancelled -- Message was not sent."
    } elseif {[string length [set result [mime::finalize $token]]] } {
	Mail::tcllib::flushPasswords [list $currentAccount] "smtp"
	dialog::alert "Results:\r\r$result"
    } else {
	status::msg "The message has been sent."
    }
    return
}

# ===========================================================================
# 
# .