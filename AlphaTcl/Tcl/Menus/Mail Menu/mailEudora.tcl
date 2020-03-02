## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Mail Menu - an extension package for Alpha
 #
 # FILE: "mailEudora.tcl"
 # 
 #                                          created: 04/24/1996 {12:08:43 PM}
 #                                      last update: 02/25/2006 {03:27:29 AM}
 # Description:
 # 
 # Provides a "mail handler" service for the "Mail Menu" that allows e-mails
 # to be sent internally from Alpha using the MacOS Eudora application.  It
 # provides additional interaction with Eudora, including
 # 
 # * previously downloaded e-mail messages can be viewed in Alpha
 # * the user can reply to the sender of these messages
 # * the user can delete these messages from Eudora's mailboxes 
 # * Alpha can instruct Eudora to check for new messages
 # 
 # See the "Changes - Mail Menu" file for license information.
 # 
 # ==========================================================================
 ##

alpha::library "mailEudora" 2.0 {
    namespace eval Mail {
	variable handlers
	set handlers(Eudora) "Mail::eudora"
    }
} requirements {
    if {!$::alpha::macos} {
	error "Eudora mail management is only available in the MacOS.
    }
} description {
    Enables Alpha interaction with the MacOS e-mail client Eudora, including
    the viewing of previously downloaded e-mails, replying to these messages,
    and instructing Eudora to check for new messages
} uninstall {
    this-file
} maintainer {
    "AlphaTcl Development Community"
} help {
    This package enables the sending of messages with the package: mailMenu
    using the MacOS e-mail client Eudora.  Its functions include:

    • creation and queuing of mail messages
    • opening of Eudora mail "mailboxes".
    • moving messages between mailboxes, including to Trash
    • intelligent replies, including quoting of original message
    • telling Eudora to send queued messages and check for new messages
    
    To change the current mail handler to Eudora, simply select this item in
    the "Mail Help > Mail Handler" menu.  Eudora can be downloaded from

    <http://www.eudora.com/>
    
    IMPORTANT: In MacOSX, all AlphaX <-> Eudora AppleEvent interaction is
    much slower than in MacClassic.  The cause of this is unknown, and will
    hopefully be addressed in a later release.
    
    
	  	Table Of Contents

    "# Additional Mail Menu commands"
    "# Eudora Options"
    "# Eudora Nicknames"
    
    <<floatNamedMarks>>
    

	  	Additional Mail Menu commands

    Once you have changed the current mail handler to Eudora, in addition to
    the standard "Mail Menu" commands the following are also available:

	Reply / Reply To All

    Create a reply to the message currently being read.  The original message
    is quoted.  Use tabs to move between fields.

	Open Mailbox                

    This submenu includes all of the Eudora mailboxes currently known to
    Alpha.  Use the "Open Mailbox > Update Mailbox Lists" to launch Eudora
    (if necessary) to obtain the current list.  This will be remembered
    between editing sessions.
    
    Once the list has been created, selecting one of the items will create a
    new browser window in Alpha allowing you to navigate to an e-mail heading
    using the arrow keys.  Press Return to view the selected e-mail in Alpha.

	Move Mail To

    This submenu includes all of the Eudora mailboxes currently known to
    Alpha.  If you are viewing a Mail message obtained from Eudora, you can
    transfer it to a different mailbox, including the Trash.

	Tell Eudora

    This submenu includes some commands that Alpha can instruct Eudora to
    complete, launching Eudora if necessary.  They include

    > Flush Outbox:

    Tell Eudora to flush 'out' mailbox immediately.

    > Check For Mail:

    Tell Eudora to check for mail immediately.
    

	  	Eudora Options

    This submenu includes some toggleable menu items that are Eudora specific
    Mail Mode options.

    > Flush On Check          

    When asking Eudora to check for mail, tell it to flush any queued
    messages at the same time.

    > Alert on Incoming       

    Put up a mail browser when Eudora notifies Alpha of incoming messages.
    
    > Immediate Send
    
    After selecting the "Mail Menu > Send" command, Alpha can instruct Eudora
    to either queue the message for delivery later, or send it immediately.
    
    
    In addition to toggling the value the above preferences, you can select
    these commands:
    
    > Trash Folder Name
    
    Tell Alpha the name of Eudora's "Trash" folder.
    
    > Edit Nicknames
    
    Open your "Edit Nicknames" file, used by "Mail Menu > Finish Nickname".
    
    > Update Nicknames
    
    Scan your "Edit Nicknames" file for use by "Mail Menu > Finish Nickname".
    
	  	Eudora Nicknames

    (To be added.)
}

proc mailEudora.tcl {} {}

namespace eval Mail {

    variable sentMailPrefs
    # These preferences are offered as toggleable "Sent Mail" menu items.
    variable sentMailPrefs
    lunion sentMailPrefs \
      "flushOnCheck" \
      "immediateSend" \
      "switchOnQueue"

}

# Before we do anything else, make sure that our "mode" is initialized.
Mail::initializeMode

# Define new preferences.

prefs::removeObsolete ::MailmodeVars(moveToTrash)

prefs::renameOld ::mailalertOnIncoming  ::MailmodeVars(alertOnIncoming)

newPref flag alertOnIncoming 1      Mail {Mail::eudora::updatePreferences}
newPref flag switchOnQueue  0       Mail
newPref flag flushOnCheck   1       Mail {Mail::eudora::updatePreferences}
newPref flag immediateSend  0       Mail {Mail::eudora::updatePreferences}

newPref folder eudoraPrefFolder \
  [file join [file dirname $PREFS] "Eudora Folder"] Mail
newPref file        eudoraNicknames         ""      Mail
newPref folder      eudoraNicknamesFolder   ""      Mail

newPref menubinding finishNickname  "<I<O/," \
  Mail {Mail::eudora::updatePreferences}
newPref menubinding selectMailbox   "<U<B/M" \
  Mail {Mail::eudora::updatePreferences}
newPref menubinding moveToMailbox   "" Mail {Mail::eudora::updatePreferences}
newPref menubinding flushOutbox     "" Mail {Mail::eudora::updatePreferences}
newPref menubinding checkForMail    "" Mail {Mail::eudora::updatePreferences}

# Use this preference to locate your mail application.
newPref sig     mailSig                 CSOm

# Add a "Eudora" preference pane.
prefs::dialogs::setPaneLists "Mail" "Eudora" [list \
  "alertOnIncoming" \
  "flushOnCheck" \
  \
  "eudoraNicknames" \
  "eudoraNicknamesFolder" \
  "eudoraPrefFolder" \
  ]
prefs::dialogs::setPaneLists "Mail" "Sending Mail" [list \
  "immediateSend" \
  "switchOnQueue" \
  ]

prefs::dialogs::setPaneLists "Mail" "Menu Shortcuts" [list \
  "finishNickname" \
  "selectMailbox" \
  "moveToMailbox" \
  "flushOutbox" \
  "checkForMail" \
  ]

# At present, notification has been disabled.
prefs::deregister "alertOnIncoming" "Mail"

namespace eval Mail::eudora {
    
    variable trashFolderName
    variable mailBoxes
    variable lastMailbox
    
    prefs::renameOld "::trashName"              "trashFolderName"
    prefs::renameOld "::eudoraBoxes"            "mailBoxes"
    prefs::renameOld "::eudoraLastFolder"       "lastMailbox"
    
    # The name of our Trash folder.
    if {![info exists trashFolderName]} {
	set trashFolderName "Trash"
    } 
    # Eudora mailboxes.
    if {![info exists mailBoxes]} {
	set mailBoxes [list In Out]
    }
    if {![info exists lastMailbox]} {
	set lastMailbox [lindex $mailBoxes 0]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::eudora::handlerChanged" --
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

proc Mail::eudora::handlerChanged {onOrOff} {

    global global::features mailMenu MailmodeVars
    
    # Define Eudora specific submenus.
    menu::buildProc "openMailbox"       {Mail::eudora::buildMailBoxMenu}
    menu::buildProc "moveMailTo"        {Mail::eudora::buildMoveToMenu}
    menu::buildProc "tellEudora"        {Mail::eudora::buildTellMenu}
    menu::buildProc "eudoraOptions"     {Mail::eudora::buildOptionsMenu}
    # Define the menu build proc for the CM module.
    menu::buildProc "mailWindow"        {Mail::eudora::buildWindowMenu}


    # Adjust Mail Menu items if we are being activated as the mail handler.
    if {$onOrOff} {
	menu::insert mailMenu "items" "0" \
	  "<E<SswitchToEudora" "<S<IbackgroundEudora" "\(-"
	menu::insert mailMenu "items" [list "after" "(-)"] \
	  "$MailmodeVars(prevMessage)prevMessage" \
	  "$MailmodeVars(nextMessage)nextMessage" \
	  "\(-" \
	  "<E<S$MailmodeVars(reply/ReplyToAll)reply" \
	  "<S<I$MailmodeVars(reply/ReplyToAll)replyToAll"
	menu::insert mailMenu "submenu" [list "after" "(-)"] \
	  "tellEudora"
	menu::insert mailMenu "submenu" [list "after" "(-)"] \
	  "openMailbox"
	menu::insert mailMenu "items" "(-) " \
	  "$MailmodeVars(trashMessage)trashMessage…"
	menu::insert mailMenu "submenu" "(-) " \
	  "moveMailTo"
	menu::insert mailMenu "items" "<E<SaddCc…" \
	  "$MailmodeVars(finishNickname)finishNickname"
	menu::insert mailMenu "submenu" "mailMenuPrefs…" "eudoraOptions"
    }
    # Always deregister the "requireOpenWindowsHook" set.
    set menuHookItems [list "reply" "replyToAll" "trashMessage…" \
      "prevMessage" "nextMessage" "finishNickname" "moveMailTo"]
    foreach menuItem $menuHookItems {
	hook::deregister requireOpenWindowsHook [list $mailMenu $menuItem] 1
    }
    # Adjust menu hooks as necessary.
    if {!$onOrOff} {
	hook::deregister menuBuild      {Mail::eudora::activateHook} mailMenu
	hook::deregister activateHook   {Mail::eudora::activateHook}
	hook::deregister activateHook   {Mail::eudora::activateHook} Mail
    } else {
	# This ensures that items are properly dimmed/enabled whenever the Mail
	# Menu is rebuilt.
	hook::register menuBuild        {Mail::eudora::activateHook} mailMenu
	if {([lsearch -exact ${global::features} "mailMenu"] > -1)} {
	    foreach menuItem $menuHookItems {
		hook::register requireOpenWindowsHook [list $mailMenu $menuItem] 1
	    }
	    hook::register activateHook {Mail::eudora::activateHook}
	} else {
	    hook::register activateHook {Mail::eudora::activateHook} Mail
	}
    } 
    
    # Adjust menu item shortcut preference visibility.
    if {$onOrOff} {
        set cmd "prefs::register"
    } else {
        set cmd "prefs::deregister"
    }
    $cmd "checkForMail"         "Mail"
    $cmd "finishNickname"       "Mail"
    $cmd "flushOutbox"          "Mail"
    $cmd "moveToMailbox"        "Mail"
    $cmd "nextMessage"          "Mail"
    $cmd "prevMessage"          "Mail"
    $cmd "reply/replyToAll"     "Mail"
    $cmd "selectMailbox"        "Mail"
    $cmd "trashMessage"         "Mail"
    $cmd "immediateSend"        "Mail"
    $cmd "switchOnQueue"        "Mail"
    # Adjust Eudora mailer preference visibility.
    prefs::dialogs::hideShowPane "Mail" "Eudora"        $onOrOff
    prefs::dialogs::hideShowPane "Mail" "Mail Windows"  $onOrOff
    # If we are using Eudora for our mail handler, define some nicknames.
    if {$onOrOff} {
	Mail::eudora::updateNicknames quiet
    } 
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::eudora::handlerHelp" --
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

proc Mail::eudora::handlerHelp {} {
    
    package::helpWindow "mailEudora"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::eudora::updatePreferences" --
 # 
 # Called when any of the preferences associated with this Mail Handler are
 # changed via the "Config > Mail Mode Prefs > Preferences" dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::eudora::updatePreferences {prefName} {
    
    switch -- $prefName {
	"alertOnIncoming" - "flushOnCheck" - "immediateSend" {
	    menu::buildSome "eudoraOptions"
	}
        default {
	    menu::buildSome "mailMenu"
        }
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::eudora::activateHook" --
 # 
 # Dim/enable menu items that are appropriate to the active window when it is
 # brought to the front.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::eudora::activateHook {{winName ""}} {
    
    global mailMenu
    
    if {![package::active mailMenu]} {
	return
    } 
    if {($winName eq "")} {
	set winName [win::Current]
    } 
    set allItems [list "reply" "replyToAll" "trashMessage…" \
      "prevMessage" "nextMessage" "finishNickname" "moveMailTo"]
    switch -- [Mail::getWindowType -w $winName] {
        "new" {
	    set enableList  [list "finishNickname"]
	    set disableList [list "reply" "replyToAll" "moveMailTo" \
	      "prevMessage" "nextMessage" "trashMessage…"]
        }
        "viewer" {
	    set enableList  [list "reply" "replyToAll" "moveMailTo" \
	      "prevMessage" "nextMessage" "trashMessage…"]
	    set disableList [list "finishNickname"]
        }
        "browser" {
	    set enableList  [list "trashMessage…" "prevMessage" "nextMessage"]
	    set disableList [list "reply" "replyToAll" \
	      "finishNickname" "moveMailTo"]
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

# ===========================================================================
# 
# ◊◊◊◊ Mail Menu Additions ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::eudora::buildWindowMenu" --
 # 
 # Define the "Mail Window" menu for the CM.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::eudora::buildWindowMenu {} {
    
    global alpha::application
    
    set menuList [list]
    switch -- [Mail::getWindowType] {
	"new" {
	    set menuList [list "addCc…" "addBcc…" "sendThisMessage"]
	}
	"viewer" {
	    set menuList [list "prevMessage" "nextMessage" \
	      "trashThisMessage" "(-)" "reply" "replyToAll" "forward…"]
	}
	"browser" {
	    set menuList [list "trashThisMessage" "floatMessageMarks"]
	}
	default {
	    return
	}
    }
    lappend menuList "newMessage" "(-)" \
      "mailHandlerHelp" "mailMenuHelp" "mailMenuPrefs…"
    
    return [list "build" $menuList {Mail::eudora::menuProc}]
}

proc Mail::eudora::buildMailBoxMenu {} {
    
    global MailmodeVars
    
    set menuList [list "$MailmodeVars(selectMailbox)Select Mailbox…" \
      "Update Mailbox Lists" "(-)"]
    set menuList [concat $menuList [Mail::eudora::listMailboxes]]
    
    return [list build $menuList {Mail::eudora::menuProc -m} "" "openMailbox"]
}

proc Mail::eudora::buildMoveToMenu {} {
    
    global MailmodeVars
    
    set menuList [list "$MailmodeVars(moveToMailbox)Move To Mailbox…" "(-)"]
    set menuList [concat $menuList [Mail::eudora::listMailboxes]]
    
    return [list build $menuList {Mail::eudora::menuProc -m} "" "moveMailTo"]
}

proc Mail::eudora::buildTellMenu {} {
    
    global MailmodeVars
    
    set menuList [list \
      "$MailmodeVars(flushOutbox)flushOutbox" \
      "$MailmodeVars(checkForMail)checkForMail" \
      ]
    
    return [list build $menuList {Mail::eudora::menuProc}]
}

proc Mail::eudora::buildOptionsMenu {} {
    
    set menuList [list "trashFolderName…" "editNicknames" "updateNicknames"]
    
    return [list build $menuList {Mail::eudora::menuProc}]
}

proc Mail::eudora::menuProc {menuName itemName} {
    
    global mailSig alpha::CMArgs
    
    variable lastMailbox
    variable mailBoxes
    variable trashFolderName
    
    switch -- $menuName {
	"openMailbox" {
	    if {($itemName eq "Update Mailbox Lists")} {
		watchCursor
		status::msg [set msg "Updating mailboxes …"]
		app::ensureRunning $mailSig
		set num [Mail::eudora::mailCountMailboxes]
		for {set i 1} {$i <= $num} {incr i} {
		    set name [file tail [Mail::eudora::mailboxPathIndex $i]]
		    status::msg "$msg $name …"
		    lappend mailBoxes $name
		}
		set mailBoxes [lunique $mailBoxes]
		prefs::modified mailBoxes
		menu::buildSome "openMailbox" "moveMailTo"
		status::msg "$msg finished."
		return
	    } elseif {($itemName eq "Select Mailbox")} {
		set lastMailbox [prompt::fromChoices \
		  "Open which mailbox?" $lastMailbox -list $mailBoxes]
		prefs::modified lastMailbox
		set itemName $lastMailbox
	    }
	    Mail::eudora::openMailbox $itemName
	}
	"moveToMailbox" {
	    set winType [Mail::getWindowType]
	    if {($winType ne "viewer") && ($winType ne "browser")} {
		error "There is no message to move in the active window."
	    }
	    switch -- $itemName {
		"Move To Trash" {
		    set toFolder $trashFolderName
		}
		"Move To Mailbox" {
		    set folder [prompt::fromChoices "Move to" \
		      $lastMailbox -list $mailBoxes]
		    if {[string length $folder]} {
			set lastMailbox $folder
			prefs::modified lastMailbox
			set toFolder $folder
		    } else {
			set toFolder $lastMailbox
		    }
		}
		default {
		    set toFolder $itemName
		}
		Mail::eudora::moveToMailbox $toFolder
	    }
	}
	"tellEudora" {
	    switch -- $itemName {
		"flushOutbox" {
		    Mail::handlerAction checkSystem
		    Mail::handlerAction flushNow
		}
		"checkForMail" {
		    Mail::handlerAction checkSystem
		    Mail::eudora::mailCheck
		}
		"startNotifying" {
		    Mail::handlerAction checkSystem
		    Mail::eudora::startNotifying
		}
		"stopNotifying" {
		    Mail::handlerAction checkSystem
		    Mail::eudora::stopNotifying
		}
	    }
	}
	"eudoraOptions" {
	    switch -- $itemName {
		"trashFolderName" {
		    set Mail::eudora::trashFolderName \
		      [prompt "Trash folder name:" $Mail::eudora::trashFolderName]
		    prefs::modified Mail::eudora::trashFolderName
		}
		"editNicknames" {
		    Mail::eudora::editNicknames
		}
		"updateNicknames" {
		    Mail::eudora::updateNicknames
		}
		default {
		    set newValue [expr 1 - $MailmodeVars($itemName)]
		    set MailmodeVars($itemName) $newValue
		    prefs::modified MailmodeVars($itemName)
		    markMenuItem eudoraOptions $itemName $newValue "√"
		    status::msg "The '[quote::Prettify $itemName]' preference\
		      is now turned [expr {$newValue ? "on" : "off"}]."
		}
	    }
	}
	"mailWindow" {
	    # Called from the CM.
	    set winType [Mail::getWindowType]
	    if {($winType eq "browser")} {
		switch -- $itemName {
		    "trashThisMessage" {
			browse::Select [lindex ${alpha::CMArgs} 0]
		    }
		}
	    } 
	    Mail::menuProc $menuName $itemName
	}
        default {
	    switch -- $itemName {
		"switchToEudora" {
		    app::launchFore $mailSig
		}
		"backgroundEudora" {
		    app::launchBack $mailSig
		}
		"finishNickname" {
		    Mail::requireMailWindow "new"
		    Mail::eudora::finishNickname
		}
		default {
		    Mail::handlerAction $itemName
		}
	    }
        }
    }
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Eudora mail handling ◊◊◊◊ #
# 
# All of the procedures in this section are called by [Mail::sendCreatedMsg],
# so their names and arguments cannot be changed.
# 

proc Mail::eudora::checkSystem {} {
    
    global mailSig
    
    set name [nameFromAppl $mailSig]
    launch $name
    return [file tail $name]
}

# make message at end of mailbox "out" of mail folder ""
proc Mail::eudora::PrepareToSend {} {
    
    createThingAtEnd 'CSOm' [Mail::eudora::mailboxByName Out] "euMS"
    return
}

# set field "fld" of message 0 to "to"

proc Mail::eudora::SetField {field value} {
    
    if {($field eq "content")} {
	set field ""
    }
    tclAE::send -p -r 'CSOm' core setd {----} \
      [tclAE::build::nameObject "euFd" [tclAE::build::TEXT $field] \
      [tclAE::build::indexObject "euMS" 1 ""]] \
      data [tclAE::build::TEXT $value]
}

proc Mail::eudora::QueueToSend {} {
    
    global MailmodeVars
    
    # Queue the message to be sent.
    tclAE::send -p -r 'CSOm' CSOm eQue ---- [tclAE::build::indexObject "euMS" 1]
    if {$MailmodeVars(immediateSend)} {
	Mail::eudora::flushNow
	status::msg "Message sent."
    } else {
	status::msg "Message queued."
    }
    if {$MailmodeVars(switchOnQueue)} {
	switchTo [Mail::handlerAction checkSystem]
    }
}

# ===========================================================================
# 
# ◊◊◊◊ Eudora Mailboxes ◊◊◊◊ #
# 

proc Mail::eudora::listMailboxes {} {
    
    variable mailBoxes
    
    set inOut [set others [list]]
    foreach mailBox [lsort -dictionary $mailBoxes] {
	if {($mailBox eq "In") || ($mailBox eq "Out")} {
	    lappend inOut $mailBox
	} else {
	    lappend others $mailBox
	}
    }
    return [concat $inOut $others]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::eudora::openMailbox" --
 # 
 # Determine a Eudora mailbox to open, collect information about its
 # contents, and then pass it all to [Mail::createMailboxWindow] to open a
 # new browser window with the listing.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::eudora::openMailbox {mailboxName} {

    global ALPHA tileLeft tileTop tileHeight errorHeight defWidth
    
    variable inboxMembers    
    variable trashedMsgs

    set trashedMsgs($mailboxName) [list]
    watchCursor
    status::msg [set msg "Opening $mailboxName mailbox …"]
    Mail::handlerAction checkSystem
    switchTo $ALPHA
    set mailMessages [list]
    set inboxMembers [list]
    set indx 1
    foreach mailMsg [Mail::eudora::mailSenders $mailboxName $msg] {
	set from "(none)"
	if {![regexp {<(.*)>} [lindex $mailMsg 0] -> from]} {
	    regexp {^\s*(\S*)} [lindex $mailMsg 0] -> from
	}
	set subj [lindex $mailMsg 1]
	lappend mailMessages [list $indx $from $subj]
	incr indx
    }
    set result [Mail::createMailboxWindow $mailboxName $mailMessages]
    set inboxMembers [lindex $result 1]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::eudora::openMailboxIds" --
 # 
 # A modified version of [Mail::openMailbox] in which we only list a given
 # set of messages (specified by "id") in the browsing window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::eudora::openMailboxIds {mailboxName ids} {
    
    global ALPHA tileLeft tileTop defWidth tileHeight errorHeight
    
    variable inboxMembers
    variable trashedMsgs
    
    set trashedMsgs($mailboxName) [list]
    watchCursor
    status::msg [set msg "Opening $mailboxName mailbox …"]
    Mail::handlerAction checkSystem
    switchTo $ALPHA
    set mailMessages [list]
    set inboxMembers [list]
    foreach id $ids {
	regexp {From: (.*)} [Mail::eudora::mailGetField from $mailboxName $id] -> from
	set from "(none)"
	if {![regexp {<(.*)>} [lindex $mailMsg 0] -> from]} {
	    regexp {^\s*(\S*)} [lindex $mailMsg 0] -> from
	}
	set subj ""
	regexp {Subject: (.*)} [Mail::eudora::mailGetField subject $mailboxName $id] -> subj
	set tag ""
	while {([lsearch -exact $inboxMembers $from$tag] >= 0)} {
	    if {![string length $tag]} {
		set tag { <2>}
	    } else {
		regexp {[0-9]+} $tag tag
		set tag " <[expr {$tag + 1}]>"
	    }
	}
	append from $tag
	lappend mailMessages [list $id $from $subj]
    }
    set result [Mail::createMailboxWindow $mailboxName $mailMessages]
    set inboxMembers [lindex $result 1]
    return
}

proc Mail::eudora::goToMatch {args} {
    
    win::parseArgs w
    
    variable trashedMsgs
    
    watchCursor
    status::msg [set msg "Querying Eudora for message …"]
    set pos0 [pos::lineStart -w $w [getPos -w $w]]
    set pos1 [pos::nextLineStart -w $w [getPos -w $w]]
    set text [getText -w $w $pos0 $pos1]
    if {![regexp {∞(.+)--([0-9]+)} $text -> folder ind]} {
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
    # Add the body contents.
    lappend args [Mail::eudora::mailGetField "" $folder $idx1]
    # Add additional arguments.
    set emailFieldNames [list "from" "to" "subject" "sender" "date" "cc"]
    foreach item $emailFieldNames {
	lappend args $item \
	  [Mail::eudora::mailGetField [string totitle $item] $folder $idx1]
    }
    
    eval Mail::createViewWindow $args
    status::msg "$msg finished."
    return
}

proc Mail::eudora::mailSenders {folder {statusMsg ""}} {
    
    set cnt [Mail::eudora::mailCountMsgs $folder]
    set msgs {}
    for {set i 1} {$i <= $cnt} {incr i} {
	if {($statusMsg ne "")} {
	    status::msg "$statusMsg message $i of $cnt …"
	} 
	set subject ""
	set fromField [Mail::eudora::mailGetField from $folder $i]
	if {![regexp -nocase {From: (.*)} $fromField -> from]} {
	    error "Cancelled -- no 'From:' field found!"
	}
	set subjectField [Mail::eudora::mailGetField subject $folder $i]
	regexp {Subject: (.*)} $subjectField -> subject
	lappend msgs [list $from $subject]
    }
    return $msgs
}	

proc Mail::eudora::moveToMailbox {toFolder} {
    
    variable lastMailbox
    variable mailBoxes
    variable trashedMsgs
    
    set winType [Mail::getWindowType]
    if {($winType ne "viewer") && ($winType ne "browser")} {
	error "There is no message to trash in the active window."
    }
    # Is this a browsing or a viewing window?
    if {($winType eq "browser")} {
	set text [getText [getPos] [pos::nextLineStart [getPos]]]
	if {![regexp -- {∞(.*)--([0-9]+)} $text -> folder orig]} {
	    status::msg "Couldn't find the message to delete."
	    return
	}
	if {($toFolder eq $folder)} {
	    return
	}
	set deleted 0
	for {set i 1} {$i < $orig} {incr i} {
	    if {([lsearch -exact $trashedMsgs($folder) $i] >= 0)} {
		incr deleted
	    }
	}
	set number [expr {$orig - $deleted}]
	set summary 1
    } else {
	set pos  [lindex [search -s -f 1 -r 1 -- {^Msg} [minPos]] 0]
	set pat  {"([^"]+)" \(([0-9]+)\).*"([^"]+)"}
	set text [getText $pos [pos::nextLineStart $pos]]
	regexp -- $pat $text -> number orig folder
	if {($toFolder eq $folder)} {
	    return
	}
	set summary 0
    }
    
    status::msg "Moving msg $number ($orig) of folder '$folder' to '$toFolder'"
    Mail::eudora::moveMsg $number $folder $toFolder
    if {!$summary} killWindow
    
    lappend trashedMsgs($folder) $orig
    
    # Find summary info and delete it
    set w [win::CurrentTail]
    if {([Mail::getWindowType -w $w] eq "browser")} {
	setWinInfo -w $w read-only 0
	set inds [search -w $w -s -f 1 -r 1 -- "∞${folder}--$orig\$" [minPos]]
	set pos0 [pos::lineStart -w $w     [lindex $inds 0]]
	set pos1 [pos::nextLineStart -w $w [lindex $inds 0]]
	deleteText -w $w $pos0 $pos1
	goto -w $w [pos::nextLineStart -w $w $pos0]
	if {[string length [search -w $w -s -n -f 1 -r 0 -- {∞} [minPos]]]} {
	    setWinInfo -w $w dirty 0
	    setWinInfo -w $w read-only 1
	    browse::Up $w
	} else {
	    setWinInfo -w $w dirty 0
	    killWindow -w $w
	}
    }
    return
}

proc Mail::eudora::mailCheck {} {
    
    global MailmodeVars
    
    tclAE::send -p 'CSOm' CSOm eCon eSen \
      [tclAE::build::bool 0$MailmodeVars(flushOnCheck)] eChk \
      [tclAE::build::bool 01]
    status::msg "Eudora has been instructed to check for new mail."
    return
}

proc Mail::eudora::trashMessage {} {
    
    variable trashFolderName
    
    set winType [Mail::getWindowType]
    if {($winType ne "viewer") && ($winType ne "browser")} {
	error "There is no message to trash in the active window."
    }
    Mail::eudora::moveToMailbox $trashFolderName
    return
}

# ===========================================================================
# 
# ◊◊◊◊ Eudora Nicknames ◊◊◊◊ #
# 
# This is Eudora specific -- but we should really be setting better default
# values for these preferences in the first place.
# 

# JF 98/08/07
if {($MailmodeVars(eudoraNicknames) eq "")} {
    if {[file exists \
      [file join $MailmodeVars(eudoraPrefFolder) "Eudora Nicknames"]]} {
	set MailmodeVars(eudoraNicknames) \
	  [file join $MailmodeVars(eudoraPrefFolder) "Eudora Nicknames"]
    }
}
if {($MailmodeVars(eudoraNicknamesFolder) eq "")} {
    if {[file exists \
      [file join $MailmodeVars(eudoraPrefFolder) "Nicknames Folder"]]} {
	set MailmodeVars(eudoraNicknamesFolder) \
	  [file join $MailmodeVars(eudoraPrefFolder) "Nicknames Folder"]
    }
}

proc Mail::eudora::updateNicknames {{arg ""}} {
    
    global euNicknames MailmodeVars
    
    # JF 98/08/07
    if {(![info exists MailmodeVars(eudoraNicknames)] \
      && ![info exists MailmodeVars(eudoraNicknamesFolder)])\
      || \
      (![file exists $MailmodeVars(eudoraNicknames)] \
      && ![file exists $MailmodeVars(eudoraNicknamesFolder)])} {
	if {![string length $arg]} {
	    alertnote {Please locate the file "Eudora Nicknames"\
	      or/and folder "Nicknames Folder" using Mail mode's prefs.}
	}
	return
    }
    if {[file exists $MailmodeVars(eudoraNicknames)]} {
	set fd [open $MailmodeVars(eudoraNicknames)]
	foreach a [split [read $fd] "\n"] {
	    if {[llength $a] && ([lindex $a 0] eq "alias")} {
		set euNicknames([lindex $a 1]) [lindex $a 2]
	    }
	}
	close $fd
    }
    if {[string length $MailmodeVars(eudoraNicknamesFolder)] \
      && [file isdirectory $MailmodeVars(eudoraNicknamesFolder)]} {
	foreach f [glob -dir $MailmodeVars(eudoraNicknamesFolder) *] {
	    set fd [open "$f"]
	    foreach a [split [read $fd] "\n"] {
		if {[regexp {\{\}\[\]} $a]} {
		    alertnote "ERROR: Braces in '${f}'"
		    close $fd
		    return
		} else {
		    if {[llength $a] && ([lindex $a 0] eq "alias")} {
			set euNicknames([lindex $a 1]) [lindex $a 2]
		    }
		}
	    }
	    close $fd
	}
    }
    return
}

proc Mail::eudora::finishNickname {} {
    
    global euNicknames
    
    set pos [getPos]
    backwardWord
    if {[pos::compare [getPos] == [minPos]]} {
	set preMailNick ""
    } else {
	set preMailNick [getText [getPos] $pos]
    }
    goto $pos
    set s [prompt::fromChoices "Nick" $preMailNick -list [array names euNicknames]]
    if {$preMailNick != ""} {
	backwardDeleteWord
    }
    insertText $s
    return
}

proc Mail::eudora::editNicknames {} {
    
    global MailmodeVars
    
    # JF 98/08/07
    if {[file isfile $MailmodeVars(eudoraNicknames)]} {
	edit -c -w "$MailmodeVars(eudoraNicknames)"
    } else {
	edit -c -w [getfile "Edit which nicknames?" \
	  "$MailmodeVars(eudoraNicknamesFolder)"]
    }
    return
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Eudora/Alpha notification ◊◊◊◊ #
# 
# This is legacy code from earlier versions of Alpha and Eudora.  The idea
# here was that we instruct Eudora to always notify Alpha when new messages
# have arrived, and these would then be listed in a new MAILBOX browsing
# window.  The "Tel Eudora > Start Notifying" menu item would send an AE to
# Eudora, and then a value would be stored in its preferences to send a note
# to Alpha, launching it if necessary.  (This last bit was never documented
# very well, and proves to be extremely annoying and unexpected.)  The menu
# command "Stop Notifying" would then launch Eudora and tell it to remove
# this auto-notification item from its preferences.
# 
# Unfortunately, this now fails with Eudora 6.0, and the AE note that it
# sends to Alpha comes as soon as Eudora begins to check for e-mail, not
# after it has determined that new messages exist.  The AppleEvent doesn't
# include anything resembling the horrid [regexp] pattern that we attempt to
# parse in [Mail::eudora::mailMsgHandler].
# 
# Given the dubious benefit of this "feature" (even if it worked) and the new
# challenge of determining which version of Eudora actually supports it, this
# functionality is no longer advertised in the "Tell Eudora" menu or in the
# 'help' argument above.  If anyone wants to revive it, feel free to look
# into these issues, but until then we'll just save this code here for
# archival purposes.  (See also bug# 1142.)
# 
# Note: this "eventHandler" needs to be included in the init script for this
# package if this functionality is ever revived:
# 
# # Our event handler.  Define it here so that Alpha knows what to do if
# # Eudora sends us a message before the Mail Menu has been turned on.
# tclAE::installEventHandler CSOm eNot "Mail::eudora::mailMsgHandler"
# 
# and these menu items would be added back to the "Tell Eudora" menu.
# 
#     "(-)" \
#     "startNotifying…" \
#     "stopNotifying"]
# 
# This is a sample 'msgs' string that was delivered by earlier versions: 
# 
# obj {want:type(euMS), from:obj {want:type(euMB), \
# from:obj {want:type(euMF), from:'null'(), \
# form:name, seld:'TEXT'()}, form:name, seld:“In”}, form:indx, seld:18}, \
# obj {want:type(euMS), \from:obj {want:type(euMB), \
# from:obj {want:type(euMF), from:'null'(), \
# form:name, seld:'TEXT'()}, form:name, seld:“In”}, \
# form:indx, seld:19}
# 

proc Mail::eudora::mailMsgHandler {theAppleEvent theReplyAE} {
    
    global MailmodeVars
    
    set gizmo [tclAE::print $theAppleEvent]
    # tclAE::print seems to swallow the '\' between the class and event
    set it "[string range $gizmo 0 3]\\[string range $gizmo 4 end]"

    status::msg ""
    if {[regexp {eWHp:wArv.*\[(obj.*)\], &repq} $it dum1 msgs]} {
	set ids [Mail::eudora::getMsgIDs $msgs]
	if {$MailmodeVars(alertOnIncoming)} {
	    Mail::eudora::openMailboxIds In $ids
	}
    } else {
	status::msg "No mail"
    }
    return [tclAE::putKeyData $theReplyAE ---- TEXT ""]
}

proc Mail::eudora::startNotifying {} {
    
    global alpha::application
    
    variable alphaProcess
    
    if {![info exists alphaProcess]} {
        Mail::eudora::setAlphaProcess
    } 
    set q "Selecting this item will set a new Eudora preference instructing \
      it to automatically notify ${alpha::application} whenever new mail \
      arrives, launching ${alpha::application} if necessary.\
      \r\rDo you want to continue?"
    if {![askyesno $q]} {
        status::msg "Cancelled."
	return
    } 
    app::ensureRunning "CSOm"
    tclAE::send -p 'CSOm' CSOm nIns ---- [tclAE::build::alis $alphaProcess]
    status::msg "Eudora will now notify ${alpha::application}\
      when mail arrives."
    return
}

proc Mail::eudora::stopNotifying {} {
    
    global alpha::application
    
    variable alphaProcess
    
    if {![info exists alphaProcess]} {
	Mail::eudora::setAlphaProcess
    } 
    app::ensureRunning "CSOm"
    tclAE::send -p 'CSOm' CSOm nRem ---- [tclAE::build::alis $alphaProcess]
    status::msg "Eudora will no longer notify ${alpha::application}\
      when mail arrives."
    return
}

proc Mail::eudora::setAlphaProcess {} {
    
    global HOME ALPHA
    
    variable alphaProcess
    
    foreach processList [processes] {
	set fullPath [lindex $processList 5]
	if {[string match "${HOME}*${ALPHA}" $fullPath]} {
	    set alphaProcess $fullPath
	    break
	} 
    }
    if {[info exists alphaProcess]} {
	return $alphaProcess
    } else {
	error "Cancelled -- couldn't identify Alpha's process."
    } 
}

# ===========================================================================
# 
# ◊◊◊◊ Eudora TclAE procedures ◊◊◊◊ #
# 

proc Mail::eudora::flushNow {} {
    
    status::msg [set msg "Telling Eudora to flush messages …"]
    app::ensureRunning "CSOm"
    tclAE::send -p 'CSOm' CSOm eCon eSen \
      [tclAE::build::bool 01] eChk [tclAE::build::bool 00]
    status::msg "$msg finished."
}

proc Mail::eudora::mailCountMsgs {mbox} {
    
    return [countObjects 'CSOm' [Mail::eudora::mailboxByName $mbox]  "euMS"]
}

proc Mail::eudora::mailCountMailboxes {} {
    
    return [countObjects 'CSOm' [Mail::eudora::eudoraFolder] "euMB"]
}

proc Mail::eudora::eudoraFolder {} {
    
    return [tclAE::build::nameObject "euMF" \
      "'TEXT'()" [tclAE::build::nullObject]]
}

proc Mail::eudora::mailboxByName {name} {
    
    return [tclAE::build::nameObject "euMB" \
      [tclAE::build::TEXT $name] [Mail::eudora::eudoraFolder]]
}

proc Mail::eudora::mailboxByIndex {ind} {
    
    return [tclAE::build::indexObject "euMB" \
      $ind [Mail::eudora::eudoraFolder]]
}

proc Mail::eudora::eudoraMessage {msg_id mailbox} {
    
    return [tclAE::build::indexObject "euMS" \
      $msg_id [Mail::eudora::mailboxByName $mailbox]]
}

# This seems to be the main workhorse here.
proc Mail::eudora::mailGetField {field folder msg} {
    
    if {[catch {tclAE::build::resultData "'CSOm'" core getd ---- \
      [tclAE::build::nameObject "euFd" [tclAE::build::TEXT $field] \
      [Mail::eudora::eudoraMessage $msg $folder]]} result]} {
	return ""
    } else {
	return $result
    }
}

# Move msg w/ specified index between folders, including to Trash.
proc Mail::eudora::moveMsg {msg infolder outfolder} {
    
    return [tclAE::send -p -r 'CSOm' core move {----} \
      [tclAE::build::indexObject "euMS" $msg [Mail::eudora::mailboxByName $infolder]] \
      {insh} "\{kobj:[Mail::eudora::mailboxByName $outfolder], kpos:end\}"]
}

proc Mail::eudora::mailboxProperty {property mailbox} {
    
    return [tclAE::send -p -r 'CSOm' core getd ---- \
      [tclAE::build::propertyObject $property \
      [Mail::eudora::mailboxByName $mailbox]]]
}

proc Mail::eudora::mailboxPathIndex {ind} {
    
    set result [tclAE::send -p -r 'CSOm' core getd ---- \
      [tclAE::build::propertyObject "euFS" [Mail::eudora::mailboxByIndex $ind]]]
    return [extractPath $result]
}

proc Mail::eudora::getMsgIDs {text} {
    
    if {[regexp -indices {seld:([0-9]+)} $text -> ind]} {
	return [concat [string range $text [lindex $ind 0] [lindex $ind 1]] \
	  [Mail::eudora::getMsgIDs [string range $text [lindex $ind 1] end]]]
    }
}

# ===========================================================================
# 
# .