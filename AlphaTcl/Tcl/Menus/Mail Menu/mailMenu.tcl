## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Mail Menu - an extension package for Alpha
 #
 # FILE: "mailMenu.tcl"
 # 
 #                                          created: 04/24/1996 {12:08:43 PM}
 #                                      last update: 02/22/2006 {06:56:47 PM}
 # Description:
 # 
 # Creates a "Mail Menu" package for AlphaTcl allowing the user to compose
 # e-mails in Alpha and then send them using a "mail handler" service chosen
 # by the user.  This file creates the basic menu, any service is welcome to
 # insert additional items to support enhanced e-mail functions.
 # 
 # See the "Changes - Mail Menu" file for license information.
 # 
 # ==========================================================================
 ##

# ×××× Menu declaration ×××× #
alpha::menu mailMenu 2.0 "global Mail" "¥138" {
    # Initialization script.
    Mail::initializeMode
} {
    # Activation script.
    Mail::registerHooks "1"
} {
    # Deactivation script.
    Mail::registerHooks "0"
} preinit {
    # Additional global option for handling e-mail urls and such.
    array set eMailer [list "Mail Menu" {Mail::newEmailWindow}]
    # Insert a new option in the 'New Document' prompt.
    array set newDocTypes [list "New E-mail Message" {Mail::createEmailWindow}]
    # Not sure how to handle this anymore.
    #set unixMode(rmail) {Mail}
} uninstall {
    this-directory
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Send and manage email from within ÇALPHAÈ -- works with Eudora (MacOS),
    your default OS e-mail client, and internal Tcl library packages
} help {
    file "Mail Help"
}

proc mailMenu {} {}

proc mailMenu.tcl {} {}

namespace eval browse {
    
    # This enables the Return/Enter binding in our MAILBOX browser windows.
    variable GotoProc
    set GotoProc(*MAILBOX*) "Mail::goToMatch"
}

namespace eval dialog {
    
    variable simple_type
    if {![info exists simple_type(mailComment)]} {
	set simple_type(mailComment) \
	  "dialog::makeEditItem res script -20 \$right y \$name \$val 5"
    } 
}

namespace eval Mail {
    
    # Before we do anything else, make sure that our "mode" is initialized.
    Mail::initializeMode
        
    # Define the menu build procs.
    menu::buildProc "mailMenu" 		{Mail::buildMenu}
    menu::buildProc "sentMail"          {Mail::buildSentMenu}
    menu::buildProc "mailHandler"       {Mail::buildHandlerMenu}
    menu::buildProc "newMessageTo"      {Mail::buildNewMessageMenu}
}

proc Mail::registerHooks {onOrOff} {
    
    global mailMenu global::features
    
    # This ensures that items are properly dimmed/enabled whenever the Mail
    # Menu is rebuilt.
    hook::register menuBuild            {Mail::activateHook} mailMenu
    # Set up the list of possible hook items.
    set menuHookItems [list "forwardÉ" "saveAsDraftÉ" "addCcÉ" "addBccÉ" \
      "send" "selectNextField"]
    # Always deregister the "requireOpenWindowsHook" set.
    foreach item $menuHookItems {
	hook::deregister requireOpenWindowsHook [list $mailMenu $item] 1
    }
    if {!$onOrOff} {
	hook::deregister activateHook   {Mail::activateHook}
	hook::deregister activateHook   {Mail::activateHook} Mail
    } else {
	# Make sure that our [Mail::activateHook] is called whenever the menu
	# is rebuilt.
	if {([lsearch -exact ${global::features} "mailMenu"] > -1)} {
	    foreach menuItem $menuHookItems {
		hook::register requireOpenWindowsHook [list $mailMenu $menuItem] 1
	    }
	    hook::register activateHook {Mail::activateHook}
	} else {
	    hook::register activateHook {Mail::activateHook} Mail
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::activateHook" --
 # 
 # If the Mail Menu is turned on globally or for the current mode, then we
 # enable/disable menu items that are only appropriate in Mail windows, and
 # then only for specific types of windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::activateHook {{winName ""}} {
    
    global mailMenu MailmodeVars
    
    if {![package::active mailMenu]} {
	return
    } 
    if {($winName eq "")} {
        set winName [win::Current]
    } 
    set allItems [list "forwardÉ" "selectNextField" \
      "addCcÉ" "addBccÉ" "saveAsDraftÉ" "send"]
    switch -- [Mail::getWindowType -w $winName] {
	"new" {
	    set enableList  [list "selectNextField" \
	      "addCcÉ" "addBccÉ" "saveAsDraftÉ" "send" ]
	    set disableList [list "forwardÉ"]
	}
	"viewer" - "sent" {
	    set enableList  [list "forwardÉ" "selectNextField"]
	    set disableList [list "addBccÉ" "addCcÉ" "saveAsDraftÉ" "send"]
	}
	"display" - "browser" {
	    set enableList  [list "selectNextField"]
	    set disableList [list "forwardÉ" \
	      "addCcÉ" "addBccÉ" "saveAsDraftÉ" "send"]
	}
	default {
	    set enableList  [list]
	    set disableList $allItems
	}
    }
    if {![file isdirectory [set dir1 $MailmodeVars(mailDraftsFolder)]] \
      || ![llength [glob -nocomplain -dir $dir1 -- *]]} {
        lappend disableList "openSavedDraftÉ"
    } else {
        lappend enableList  "openSavedDraftÉ"
    }
    # Now we dim/enable as required.
    foreach menuItem $enableList {
	enableMenuItem $mailMenu $menuItem 1
    }
    foreach menuItem $disableList {
	enableMenuItem $mailMenu $menuItem 0
    }
    # Dim/enable the "Sent Mail > Display Sent Mail" item.
    if {![file isdirectory [set dir2 $MailmodeVars(mailSentFolder)]] \
      || ![llength [glob -nocomplain -dir $dir2 -- *]]} {
	enableMenuItem "sentMail" "displaySentMailÉ" 0
    } else {
	enableMenuItem "sentMail" "displaySentMailÉ" 1
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Mail Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::buildMenu" --
 # 
 # We define a minimal menu that includes the basic items that are supported
 # by any Mail Handler.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::buildMenu {} {
    
    global mailMenu MailmodeVars
    
    variable handlers
    
    # Make sure that all of our variables have been defined.
    Mail::initializeMode
    
    set mailHelp [list "Main Help File" "(-)"]
    foreach handler [lsort -dictionary [array names handlers]] {
	lappend mailHelp $handler
    }
    # Dim or enable the "Open Saved Draft" menu item.
    set dir $MailmodeVars(mailDraftsFolder)
    set draftList [glob -nocomplain -dir $dir -- "*"]
    set dim1 [expr {[llength $draftList] ? "" : "\("}]
    # Create the menu list.
    set menuList [list \
      "$MailmodeVars(newMessage)newMessage" \
      [list Menu -n "newMessageTo" {}] \
      "${dim1}openSavedDraftÉ" \
      "(-)" \
      "$MailmodeVars(forward)forwardÉ" \
      "$MailmodeVars(selectNextField)selectNextField" \
      "(-) " \
      "<E<SaddCcÉ" \
      "<S<IaddBccÉ" \
      "$MailmodeVars(saveAsDraft)saveAsDraftÉ" \
      "$MailmodeVars(send)send" \
      [list Menu -n "sentMail" {}] \
      "(-)  " \
      [list Menu -n "mailHandler" {}] \
      [list Menu -n "mailMenuHelp" -m -p {Mail::menuProc} $mailHelp] \
      "mailMenuPrefsÉ" \
      ]
    set subMenus [list "mailHandler" "newMessageTo" "sentMail"]
    
    return [list build $menuList {Mail::menuProc -M Mail} $subMenus $mailMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::buildNewMessageMenu" --
 # 
 # Create the "Mail Menu > New Message To" submenu which includes all of the
 # saved e-mail addresses, plus utilities to add, edit, etc.  all of the
 # saved entries.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::buildNewMessageMenu {} {
    
    variable savedEmails
    
    set menuList [lsort -dictionary -unique [array names savedEmails]]
    if {[llength $menuList]} {
	lappend menuList "(-)"
	set dim ""
    } else {
	set dim "\("
    }
    lappend menuList "Add New E-mailÉ" "${dim}Edit E-mailÉ" \
      "${dim}Forget E-mailÉ" "${dim}Rename Menu ItemÉ" 
    return [list build $menuList {Mail::newMessageMenuProc -M Mail -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::buildSentMenu" --
 # 
 # Create the "Mail Menu > Sent Mail" menu which contains toggleable prefs
 # related to sending mail, and the "Display Sent Mail" item that is dimmed
 # if there are no saved mail messages.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::buildSentMenu {} {
    
    global MailmodeVars
    
    variable sentMailPrefs
    
    set menuList [list]
    foreach prefName [lsort -unique -dictionary $sentMailPrefs] {
        if {![prefs::isRegistered $prefName "Mail"]} {
            continue
        } 
	set prefix [expr {$MailmodeVars($prefName) ? "!Ã" : ""}]
	lappend menuList "${prefix}${prefName}"
    } 
    if {[llength $menuList]} {
        lappend menuList "(-)"
    } 
    set dir $MailmodeVars(mailSentFolder)
    set sentList [glob -nocomplain -dir $dir -- "*"]
    set dim1 [expr {[llength $sentList] ? "" : "\("}]
    lappend menuList ${dim1}displaySentMailÉ
    
    return [list build $menuList {Mail::menuProc -M Mail}]
    
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::buildHandlerMenu" --
 # 
 # Build the "Mail Menu > Mail Handlers" submenu that allows the user to
 # change the current Mail Handler.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::buildHandlerMenu {} {
    
    global MailmodeVars
    
    variable handlers
    
    set allHandlers [lsort -dictionary [array names handlers]]
    if {![llength $allHandlers]} {
	set menuList [list "(No Mail Handlers Defined"]
    } else {
	foreach handler $allHandlers {
	    if {($MailmodeVars(mailHandler) eq $handler)} {
		lappend menuList "!¥$handler"
	    } else {
		lappend menuList $handler
	    }
	}
    }
    return [list build $menuList {Mail::menuProc -M Mail -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::buildWindowMenu" --
 # 
 # We define a very basic "Mail Window" menu for the CM, but other handlers
 # are welcome to define something fancier in their "handlerChanged" proc.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::buildWindowMenu {} {
    
    switch -- [Mail::getWindowType] {
	"new" {
	    set menuList [list "addCcÉ" "addBccÉ" "sendThisMessage"]
	}
	"browser" {
	    set menuList [list "floatMessageMarks"]
	}
    }
    lappend menuList "newMessage" "(-)" \
      "mailHandlerHelp" "mailMenuHelp" "mailMenuPrefsÉ"]
    
    return [list "build" $menuList {Mail::menuProc}]
}

# Now that we've defined our menu, we need to build it.
namespace eval Mail {
    
    variable menuBuilt
    if {![info exists menuBuilt]} {
	# Build the menu.
	menu::buildSome "mailMenu"
	# Register anything required to set our current mail handler.
	Mail::handlerAction handlerChanged 1
	variable oldHandler $::MailmodeVars(mailHandler)
	# Make sure that we don't do this again.
	set menuBuilt 1
    } 
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::menuProc" --
 # 
 # Called by the main Mail Menu as well as most of the submenus, redirect as
 # necessary.  If we cannot find a suitable script, we pass it on to the
 # [Mail::handlerAction] procedure.  Any Mail Handler can thus add an item to
 # the main menu and define a [Mail::<handler>::<itemName>] procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::menuProc {menuName itemName} {
    
    global mailMenu MailmodeVars alpha::CMArgs
    
    variable emailPattern
    variable savedEmails
    variable sentMailPrefs
    
    if {($menuName eq $mailMenu)} {
        set menuName "mailMenu"
    } 
    switch -- $menuName {
	"mailHandler" {
	    set MailmodeVars(mailHandler) $itemName
	    prefs::modified MailmodeVars(mailHandler)
	    Mail::updatePreferences "mailHandler"
	    status::msg "The new mail handler is \"$itemName\"."
	}
	"mailMenuHelp" {
	    if {($itemName eq "Main Help File")} {
	        package::helpWindow "mailMenu"
	    } else {
		Mail::handlerHelp $itemName
	    }
	}
	"newMessageTo" {
	    Mail::newMessageMenuProc $menuName $itemName
	}
	"sentMail" {
	    if {([lsearch -exact $sentMailPrefs $itemName] > -1)} {
		set newValue [expr {1 - $MailmodeVars($itemName)}]
		set MailmodeVars($itemName) $newValue
		prefs::modified MailmodeVars($itemName)
		status::msg "The \"[quote::Prettify $itemName]\" preference\
		  has been turned [expr {$newValue ? "on" : "off"}]."
		menu::buildSome "sentMail"
		return
	    } 
	    switch -- $itemName {
	        "displaySentMail" {
		    Mail::displayFolderContents "sent"
	        }
	    }
	}
	"mailMenu" {
	    switch -- $itemName {
		"mailMenuHelp" {
		    help::openFile "Mail Help"
		}
		"addCc" - "addBcc" {
		    Mail::requireMailWindow "new"
		    Mail::addField $itemName
		}
		"newMessage" {
		    Mail::createEmailWindow
		}
		"openSavedDraft" {
		    Mail::displayFolderContents "draft"
		}
		"saveAsDraft" {
		    set q "Do you want to close this window and save it\
		      in your \"Drafts\" folder?"
		    if {![askyesno $q]} {
			error "cancel"
		    }
		    set w [win::Current]
		    Mail::saveInFolder $w "draft"
		    menu::buildSome "mailMenu"
		    win::setInfo $w dirty 0
		    killWindow -w $w
		    status::msg "The mail window has been saved as a draft."
		}
		"selectNextField" {
		    Mail::selectNextField
		}
		"send" - "sendThisMessage" {
		    Mail::requireMailWindow "new"
		    Mail::handlerAction checkSystem
		    Mail::sendCreatedMsg
		}
		"reply" {
		    Mail::requireMailWindow "viewer"
		    Mail::replyToEmail 0
		}
		"replyToAll" {
		    Mail::requireMailWindow "viewer"
		    Mail::replyToEmail 1
		}
		"forward" {
		    Mail::requireMailWindow "viewer" "sent"
		    Mail::forwardEmail
		}
		"trashMessage" - "trashThisMessage" {
		    Mail::trashMessage
		}
		"prevMessage" - "nextMessage" {
		    Mail::nextPrevMessage $itemName
		}
		"htmlColors&Styles" {
		    Mail::wwwPrefsDialog
		}
		"mailMenuPrefs" {
                    prefs::dialogs::modePrefs "Mail" "Mail Menu Preferences"
		}
		default {
		    Mail::handlerAction "menuProc" $menuName $itemName
		}
	    }
        }
	"Mailbox Messages" {
	    # Called by the "Mailbox Messages" floating pallete.
	    set w [Mail::findBrowserWindow]
	    if {($w eq "") || ![win::Exists $w]} {
		error "Cancelled -- couldn't find the window \"$w\""
	    }
	    set itemName [string range $itemName 1 end]
	    if {$itemName eq "-- Mailbox Browsing Window --"} {
		bringToFront $w
		return
	    } 
	    foreach markList [getNamedMarks -w $w] {
		if {([lindex $markList 0] eq $itemName)} {
		    set thisMark $markList
		    break
		} 
	    }
	    if {![info exists thisMark]} {
		error "Cancelled -- couldn't find the message associated\
		  with \"${itemName}\"."
	    } 
	    # Highlight this item in the browsing window, and select it to
	    # open the message.
	    browse::Select [lindex $thisMark 2] $w
	    browse::Goto $w
	}
	"mailWindow" {
	    switch -- $itemName {
		"trashThisMessage" {
		    set pos0 [pos::lineStart [lindex ${alpha::CMArgs} 0]]
		    set pos1 [pos::nextLineStart $pos0]
		    Mail::menuProc "mailMenu" "trashMessage"
		}
		"floatMessageMarks" {
		    Mail::floatMailboxMessages
		}
		"mailHandlerHelp" {
		    Mail::handlerHelp $MailmodeVars(mailHandler)
		}
		"mailMenuHelp" {
		    package::helpWindow "mailMenu"
	        }
		"mailMenuPrefs" {
		    prefs::dialogs::modePrefs "Mail" "Mail Menu Preferences"
		}
		default {
		    Mail::menuProc "mailMenu" $itemName
	        }
	    }
	}
	default {
	    Mail::handlerAction "menuProc" $menuName $itemName
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::newMessageMenuProc" --
 # 
 # Create a New Mail window to the specified recipient, or adjust the list of
 # remembered e-mail addresses.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::newMessageMenuProc {menuName itemName} {
    
    global MailmodeVars
    
    variable emailPattern
    variable savedEmails
    
    switch -- $itemName {
	"Add New E-mail" {
	    set itemName ""
	    set newEmail ""
	    set realName ""
	    set comments ""
	    while {1} {
		set dialogScript [list dialog::make \
		  -title "Add New E-mail" \
		  -addbuttons [list \
		  "Help" \
		  "Click here to close this dialog and obtain more information" \
		  "help::openGeneral {Mail Help} {Remembered E-mail Addresses} ; \
		  set retVal {cancel} ; set retCode {1}"] \
		  [list "" \
		  [list "var"  "Menu Item Name:"        $itemName] \
		  [list "var"  "E-mail Address:"        $newEmail] \
		  [list "var"  "Real Name:"             $realName] \
		  [list "text" "Comments:"] \
		  [list "mailComment" ""                $comments] \
		  [list "text" "\rYou can adjust the 'Remember Recipient Email'\
		  preference to always add new e-mail addresses when\
		  sending mail, and then edit the entries later.\r"] \
		  [list "flag" "Remember Recipient Email" \
		  $MailmodeVars(rememberRecipientEmail)]]]
		set result   [eval $dialogScript]
		set itemName [string trim [lindex $result 0]]
		set newEmail [string trim [lindex $result 1]]
		set realName [string trim [lindex $result 2]]
		set realName [string trim [lindex $result 3]]
		set rememberRecipientEmail [lindex $result 4]
		if {![regexp $emailPattern $newEmail]} {
		    alertnote "The e-mail did not appear to use a\
		      valid syntax:\r\rsomeone@somewhere.com"
		} elseif {![regexp {^\w[-@\w. ]+$} $itemName]} {
		    alertnote "The menu item name must be alpha-numeric."
		} else {
		    break
		}
	    }
	    prefs::modified MailmodeVars(rememberRecipientEmail)
	    menu::buildSome "sentMail"
	    regsub -all -- {^<|>$} $newEmail {} newEmail
	    set savedEmails($itemName) [list $newEmail $realName $comments]
	    prefs::modified savedEmails($itemName)
	    menu::buildSome "newMessageTo"
	    status::msg "The new e-mail address has been remembered."
	}
	"Edit E-mail" {
	    set options [lsort -dictionary [array names savedEmails]]
	    set p "Edit which e-mail address?"
	    while {1} {
		set itemName [listpick -p $p -- $options]
		if {($itemName eq "(Finish)")} {
		    break
		} 
		set newEmail [lindex $savedEmails($itemName) 0]
		set realName [lindex $savedEmails($itemName) 1]
		set comments [lindex $savedEmails($itemName) 2]
		while {1} {
		    set dialogScript [list dialog::make \
		      -title "Add New E-mail" \
		      -addbuttons [list \
		      "Help" \
		      "Click here to close this dialog and obtain more information" \
		      "help::openGeneral {Mail Help} {Remembered E-mail Addresses} ; \
		      set retVal {cancel} ; set retCode {1}"] \
		      [list "" \
		      [list "var"  "E-mail Address:"    $newEmail] \
		      [list "var"  "Real Name:"         $realName] \
		      [list "text" "Comments:"] \
		      [list "mailComment" ""            $comments]]]
		    set result   [eval $dialogScript]
		    set newEmail [string trim [lindex $result 0]]
		    set realName [string trim [lindex $result 1]]
		    set comments [string trim [lindex $result 2]]
		    if {![regexp $emailPattern $newEmail]} {
			alertnote "The e-mail did not appear to use a\
			  valid syntax:\r\rsomeone@somewhere.com"
		    } else {
			break
		    }
		}
		set savedEmails($itemName) [list $newEmail $realName $comments]
		prefs::modified savedEmails($newEmail)
		status::msg "The new e-mail address has been saved."
		set options [concat [list "(Finish)"] \
		  [lsort -dictionary [array names savedEmails]]]
		set p "Edit another, or select 'Finish' :"
	    }
	}
	"Forget E-mail" {
	    set p "Forget which e-mails?"
	    set options [lsort -dictionary [array names savedEmails]]
	    set deleteList [listpick -p $p -l -- $options]
	    foreach itemName $deleteList {
		prefs::modified savedEmails($itemName)
		unset savedEmails($itemName)
	    }
	    menu::buildSome "newMessageTo"
	    if {([llength $deleteList] == 1)} {
		status::msg "The selected e-mail address\
		  has been forgotten."
	    } else {
		status::msg "The selected e-mail addresses\
		  have been forgotten."
	    }
	}
	"Rename Menu Item" {
	    set options [lsort -dictionary [array names savedEmails]]
	    set p "Rename which e-mail 'hint' for the menu?"
	    while {1} {
		set oldName [listpick -p $p -- $options]
		if {($oldName eq "(Finish)")} {
		    break
		} 
		set newName $oldName
		while {1} {
		    set newName [prompt "New menu item name:" $oldName]
		    if {![regexp {^\w[-@\w. ]+$} $newName]} {
			alertnote "The menu item name must be alpha-numeric."
		    } else {
			break
		    }
		}
		set savedEmails($newName) $savedEmails($oldName)
		prefs::modified savedEmails($newName)
		prefs::modified savedEmails($oldName)
		unset savedEmails($oldName)
		menu::buildSome "newMessageTo"
		status::msg "The \"Mail Menu > New Message To\" menu\
		  has been rebuilt."
		set options [concat [list "(Finish)"] \
		  [lsort -dictionary [array names savedEmails]]]
		set p "Rename another, or select 'Finish' :"
	    }
	}
	default {
	    set address  [lindex $savedEmails($itemName) 0]
	    set realName [lindex $savedEmails($itemName) 1]
	    Mail::newEmailWindow [Mail::parseEmailField "$realName $address"]
	}
    }
    return
}
# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Mail Windows ×××× #
# 
# We are able to create a new Mail window for any handler method.  The most
# basic type is the "New" window ([Mail::createEmailWindow]), which will
# include the basic fields for "To:" "Subject:" and the body.  Other windows
# can be generated from e-mails received and presented in Alpha, but this
# functionality is limited to the handler's capabilities.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::newEmailWindow" --
 # 
 # Called by the New Document package, i.e. the "newDocTypes" script.
 # 
 # This will handle 'to' created by 'url::mailto', as well as plain e-mail
 # addresses.  We pass on the parsed arguments to [Mail::createEmailWindow].
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::newEmailWindow {to} {
    
    set args [list]
    array set mailArgs [url::unmailto $to]
    set to ""
    foreach field [array names mailArgs] {
	set fieldValue $mailArgs($field)
	set fieldName  [string tolower $field]
	if {($fieldName eq "to")} {
	    set to $fieldValue
	} else {
	    lappend args $fieldName $fieldValue
	}
    }
    eval [list Mail::createEmailWindow $to] $args
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::createEmailWindow" --
 # 
 # Create a new window in Mail mode with the name "New Mail" to "to".
 # Remaining list of arguments should be an even number and should be
 # 
 #      field value ?field value? ...
 # 
 # to create additional header fields.  Each field name should be in lower
 # case.  The value for "content" will be used in the message's body.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::createEmailWindow {{to ""} args} {
    
    global MailmodeVars
    
    variable newMailCounter
    
    Mail::setFillColumn
    # Make sure that we have some default values.
    array set emailFields [list \
      "cc"              "" \
      "bcc"             "" \
      "reply-to"        "" \
      "subject"         "" \
      "content"         "" \
      ]
    array set emailFields $args
    append text [format {%-10s} "To:"] $to "\r"
    # Add our "alwaysBccTo" address to the fields array.
    if {($emailFields(bcc) eq "")} {
        set emailFields(bcc) $MailmodeVars(alwaysBccTo)
    } elseif {![regexp $MailmodeVars(alwaysBccTo) $bcc]} {
        append emailFields(bcc) ", $MailmodeVars$alwaysBccTo"
    }
    # Add additional e-mail header fields to the "text" string.
    foreach fieldName [list "cc" "bcc" "reply-to"] {
	if {[string length $emailFields($fieldName)]} {
	    regsub -all -- {\s+} $emailFields($fieldName) { } fieldValue
	    append text [format {%-10s} "[string totitle $fieldName]:"] \
	      [string trimleft \
	      [breakIntoLines $fieldValue $MailmodeVars(fillColumn) 10]] "\r"
	} 
    }
    # Add our divider string.
    set equals [string repeat "=" 28]
    append text [format {%-10s} "Subject:"] $emailFields(subject) "\r\r" \
      ">${equals}text follows this line${equals}<\r"
    # Add any default contents.
    foreach line [split $emailFields(content) "\r\n"] {
	if {[string length $line] < ($MailmodeVars(fillColumn) + 10)} {
	    append text $line "\r"
	} else {
	    append text [breakIntoLines $line $MailmodeVars(fillColumn)] "\r"
	}
    }
    # Create the new window.
    set w [Mail::createWindow "new" "New Mail" $text]
    goto -w $w [minPos -w $w]
    # If we don't automatically color quoted text, color our divider line.
    if {!$MailmodeVars(colorNewMailQuotedText)} {
	set pat {^>====+[^\r]+====+<$}
	set dividerLine [search -w $w -s -n -f 1 -r 1 -- $pat [minPos -w $w]]
	if {[llength $dividerLine]} {
	    eval [list text::color -w $w] $dividerLine 5
	    win::setInfo $w dirty 0
	}
    } 
    refresh -w $w
    Mail::selectNextField -w $w
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::createViewWindow" --
 # 
 # Create a window for reading an e-mail that has been received.  Each
 # handler determines its own method (if any) for listing the received items
 # in a browsing window, and can then pass along information here to view
 # them.  We assume that a listing window is present (and most likely
 # active), which is why we adjust the size accordingly.
 # 
 # The initial arguments include:
 # 
 # folder       - the name of the folder containing the e-mail
 # idx1         - the index of the item within the folder
 # idx2         - the original number of the item in the folder
 # content      - the body of the message
 # 
 # Remaining list of arguments should be an even number and should be
 # 
 #      field value ?field value? ...
 # 
 # corresponding to lower case header fields for an e-mail.  The following
 # are currently used (though any others can be supplied for later support) :
 # 
 # from         - the e-mail address of the sender
 # to           - the e-mail address of the receiver
 # subject      - the subject line in the e-mail
 # date         - the date that the e-mail was received
 # cc           - any other recipients of this e-mail
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::createViewWindow {folder idx1 idx2 content args} {
    
    global MailmodeVars
    
    variable parsedText
    variable parsingFillColumn
    
    Mail::setFillColumn
    
    # Make sure that we have some default values.
    array set emailFields [list \
      "subject"                         "(no subject)" \
      "to"                              "" \
      "from"                            "" \
      "sender"                          "" \
      "reply-to"                        "" \
      "date"                            "" \
      "content-type"                    "text/plain" \
      "content-transfer-encoding"       "" \
      ]
    array set emailFields $args
    if {($emailFields(from) eq $emailFields(reply-to))} {
        set emailFields(reply-to) ""
    } 
    if {($emailFields(from) eq $emailFields(sender))} {
	set emailFields(sender) ""
    } 
    # Create the text string to be placed in the window.
    set text ""
    set fieldNames [list "subject" "to"  "cc" "from" "sender" "reply-to" "date"]
    set hasEmail   [list "to" "cc" "from" "sender" "reply-to"]
    foreach fieldName $fieldNames {
	if {[string length $emailFields($fieldName)]} {
	    set fieldValue $emailFields($fieldName)
	    if {([lsearch $hasEmail $fieldName] > -1)} {
		set fieldValue [Mail::parseEmailField $fieldValue]
		append text [format {%-10s} "[string totitle $fieldName]:"] \
		  [string trim $fieldValue] "\r"
	    } else {
		set fieldValue [Mail::parseHeaderField $fieldValue]
		append text [format {%-10s} "[string totitle $fieldName]:"] \
		  [string trim \
		  [breakIntoLines $fieldValue $parsingFillColumn 10]] "\r"
	    }
	}
    }
    append text "\rMsg \"$idx1\" ($idx2) of mailbox \"$folder\"" \
      "     Reply    Reply To All    Trash\r\r" \
      ">[string repeat = 78]<\r\r"
    status::msg [set msg "Parsing e-mail contents É"]
    Mail::parseContent $content \
      "content-type"                $emailFields(content-type) \
      "content-transfer-encoding"   $emailFields(content-transfer-encoding)
    append text "[string trim $parsedText]\r\r"
    # Recycle an existing Mail View window, or create a new one.
    if {$MailmodeVars(multipleMailViewWindows)} {
        set n "* MAIL ($idx2) $emailFields(subject) *"
	if {([string length $n] > 55)} {
	    set n "[string range $n 0 52]É *"
	} 
    } else {
	set n "* MAIL Window *"
    }
    if {[win::Exists $n]} {
	set w $n
	bringToFront $w
	win::setInfo $w read-only 0
	# Avoid bug# 1671 -- won't be necessary after Alpha 8.0 final release
	catch {removeColorEscapes -w $w}
	deleteText -w $w [minPos -w $w] [maxPos -w $w]
	goto -w $w [minPos -w $w]
	insertText -w $w $text
    } else {
	set w [Mail::createWindow "viewer" $n $text]
    }
    goto -w $w [minPos -w $w]
    winReadOnly $w
    # Colorize our window.
    if {($w eq $n)} {
        set msgLineOnly 0
    } else {
        set msgLineOnly 1
    }
    status::msg [set msg "Colorizing window É"]
    Mail::colorizeWindow -w $w $msgLineOnly
    # Mark the window, and auto-float if necessary.
    Mail::MarkFile -w $w 1
    if {[llength [getNamedMarks -w $w]] \
      && $MailmodeVars(autoFloatMessageMarks)} {
	floatNamedMarks -w $w
    }
    status::msg "Message \"$idx1\" ($idx2) of mailbox \"$folder\""
    return
}

# ===========================================================================
# 
# ×××× Mail Window Utilities ×××× #
# 
# Some of these routines are only available if the current Mail Handler
# allows for the viewing of messages from a remote server, i.e. they will
# only function on "From:" windows.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::replyToEmail" --
 # 
 # Reply to the addresses found in an active "Viewer" e-mail window.  If
 # "toAll" is "1" then we attempt to add all "To:" and "Cc:" fields to the
 # new window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::replyToEmail {{toAll 0}} {
    
    global MailmodeVars
    
    Mail::requireMailWindow "viewer"
    set args [list]
    # Get our "To:" address.
    set replyTo [Mail::getFieldValue "reply-to"]
    set from    [Mail::getFieldValue "from"]
    if {[string length $replyTo]} {
	set sendTo $replyTo
    } elseif {[string length $from]} {
        set sendTo $from
    }
    if {![info exists sendTo]} {
        set msg "Cancelled -- could not find an address to reply to."
	alertnote $msg
	error $msg
    } 
    # Get our "Subject:" line.
    if {![string length [set subject [Mail::getFieldValue "subject"]]]} {
	set subject "(empty subject line)"
    } 
    regsub -nocase -- "^\s*Re:\s*" $subject {} subject
    regsub -all -- {\s+} $subject { } subject
    lappend args "subject" "Re: [string trim $subject]"
    # Create a "Cc:" list if necessary.
    set ccList ""
    if {$toAll} {
	set to [split [Mail::getFieldValue "to"] ","]
	set cc [split [Mail::getFieldValue "cc"] ","]
	foreach item [concat $to $cc] {
	    if {($item ne $sendTo) && ([lsearch -exact $ccList $item] == -1)} {
	        lappend ccList $item
	    } 
	}
	set ccList [join $ccList ", "]
    }
    lappend args "cc" $ccList
    # Do a fancy preamble.
    set content "\r"
    set date [Mail::getFieldValue "date"]
    # [clock scan] bug workaround.
    set timeZonePattern {(.+)\s+(\+|\-)\d{4}(\s+\([^\)]+\)\s*)?}
    if {[regexp $timeZonePattern $date -> newDate]} {
	if {![catch {clock scan $newDate} newDate]} {
	    set date [clock format $newDate -format "%a, %d %b %Y"]
	} 
    }
    append content "On ${date}, $from wrote:\r\r"
    # Get the body of the current e-mail, and quote it.
    set oldContent [string trim [Mail::getFieldValue "content"]]
    foreach line [split $oldContent "\r\n" ] {
	if {[string length $line] < ($MailmodeVars(fillColumn) + 5)} {
	    append content $MailmodeVars(prefixString) $line "\r"
	} else {
	    set newLines [breakIntoLines $line $MailmodeVars(fillColumn)]
	    foreach newLine [split $newLines "\r\n"] {
		append content $MailmodeVars(prefixString) $newLine "\r"
	    }
	}
    }
    lappend args "content" $content
    eval [list Mail::createEmailWindow $sendTo] $args
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::forwardEmail" --
 # 
 # Forward the contents of an active "Viewer" e-mail window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::forwardEmail {} {
    
    global MailmodeVars
    
    variable savedEmails
    
    Mail::requireMailWindow "viewer" "sent"
    set args [list]
    if {![llength [array names savedEmails]]} {
	set forwardTo [prompt $p ""]
    } else {
	set p "Forward to:"
	set options [lsort -dictionary [array names savedEmails]]
	set email   [lindex $options 0]
	set forwardTo [eval [list prompt $p $email "options:"] $options]
    }
    if {[info exists savedEmails($forwardTo)]} {
	set address  [lindex $savedEmails($forwardTo) 0]
        set realName [lindex $savedEmails($forwardTo) 1]
	set forwardTo [Mail::parseEmailField "$realName $address"]
    } 
    # Obtain header field values (if any) from the active window.
    foreach field [list "date" "from" "to" "cc" "subject" "content"] {
	set $field [Mail::getFieldValue $field]
    }
    # Take special care with our "Subject:" line.
    if {![string length [string trim $subject]]} {
	set subject "(empty subject line)"
    } 
    regsub -nocase -- "\s*(fwd)\s$" $subject {} subject
    regsub -all -- {\s+} $subject { } subject
    lappend args "subject" "[string trimleft $subject] (fwd)"
    # Get the body of the current e-mail.
    set newContent "\r\r\r---------- Forwarded message ----------\r"
    foreach field [list "date" "from" "to" "cc" "subject"] {
	append newContent [format "%-10s" [string totitle $field]:] \
	  [set $field] "\r"
    }
    append newContent "\r" [string trim $content]
    lappend args "content" $newContent
    eval [list Mail::createEmailWindow $forwardTo] $args
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::sendCreatedMsg" --
 # 
 # Attempt to send a new e-mail message using the current handler.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::sendCreatedMsg {} {
    
    global MailmodeVars
    
    variable emailPattern
    variable savedEmails
    
    # Preliminaries.
    Mail::requireMailWindow "new"
    if {$MailmodeVars(confirmBeforeSending)} {
	set dialogScript [list dialog::make -title "Send Message?" \
	  [list "" \
	  [list "text" "Send this message?\r"] \
	  [list "flag" "Always confirm before sending" 1]]]
	set result [eval $dialogScript]
	if {![lindex $result 0]} {
	    set MailmodeVars(confirmBeforeSending) 0
	    prefs::modified MailmodeVars(confirmBeforeSending)
	    menu::buildSome "sentMail"
	} 
    } 
    # (1) Parse out required fields from the active window.
    foreach headerField [list "to" "cc" "bcc" "subject" "content"] {
	set $headerField [Mail::getFieldValue $headerField]
    }
    if {![string length $to]} {
	error "Cancelled -- couldn't find the address to send to."
    } 
    set pat   {>====[^\r]+====+<}
    set match [search -n -s -f 1 -r 1 $pat [minPos]]
    if {![llength $match]} {
	set pos1 [minPos]
    } else {
	set pos1 [pos::nextLineStart [lindex $match 1]]
    }
    set content [getText $pos1 [maxPos]]
    status::msg "Preparing to send e-mailÉ"
    # (2) Prepare to send.  Send the Mail Handler the field information.
    Mail::handlerAction PrepareToSend
    foreach fieldName [list "to" "cc" "bcc" "subject" "content"] {
	set fieldValue [string trim [set $fieldName]]
	Mail::handlerAction SetField $fieldName $fieldValue
    }
    # (3) Queue to send.  The handler can do whatever it wants as far as
    # queuing/sending the mesage is concerned, so long as it doesn't throw an
    # error.  If it does, we pass that information along to the user.
    if {[catch {Mail::handlerAction QueueToSend} errorMessage]} {
	if {![string match -nocase "*cancel*" $errorMessage]} {
	    set errorMessage "Cancelled -- $errorMessage"
	} 
	error $errorMessage
    }
    if {$MailmodeVars(rememberRecipientEmail)} {
	set addresses [list]
        foreach field [list "to" "cc" "bcc"] {
	    foreach toValue [split [set $field] ","] {
		lappend addresses $toValue
	    }
	}
	set newEmails [list]
	foreach address $addresses {
	    if {[regexp $emailPattern $address -> email]} {
	        lappend newEmails $email
	    } 
	}
	set added 0
	foreach newEmail $newEmails {
	    set addNew 1
	    foreach itemName [array names savedEmails] {
		set alreadySaved [lindex $savedEmails($itemName) 0]
		if {($alreadySaved eq $newEmail)} {
		    set addNew 0
		    break
		} 
	    }
	    if {$addNew} {
		incr added
		set savedEmails($newEmail) [list $newEmail "" ""]
		prefs::modified savedEmails($newEmail)
	    } 
	}
	if {$added} {
	    menu::buildSome "newMessageTo"
	} 
    } 
    if {$MailmodeVars(saveCopyOfSentMail)} {
        Mail::saveInFolder [win::Current] "sent"
    } 
    if {$MailmodeVars(killWindowAfterSend)} {
	setWinInfo dirty 0
	killWindow
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::trashMessage" --
 # 
 # Called via a "Trash Message" hyperlink in a Mail window.
 # 
 # If the current mail handler has defined a procedure to trash received
 # messages, then we call it.  We define this as a separate procedure to make
 # it easier to call from the hyperlink.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::trashMessage {} {
    
    variable floatID
    
    Mail::handlerAction "trashMessage"
    # Refloat any marks windows associated with the current browsing window.
    set w [Mail::findBrowserWindow]
    if {($w ne "")} {
	Mail::MarkFile -w $w 1
	if {[unfloatNamedMarks -w $w]} {
	    floatNamedMarks -w $w
	} 
	if {![catch {unfloat $floatID}]} {
	    Mail::floatMailboxMessages $w 0
	} 
    }
    return
    
}

# ===========================================================================
# 
# ×××× Mailbox Windows ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::createMailboxWindow" --
 # 
 # Given a mailbox name and a set of messages, create a browsing window for
 # navigation of the results.  The "mailMessages" argument is a list of three
 # item lists, each of which contains
 # 
 # (1) The index number that should appear in the far left column
 # (2) The "From: " address
 # (3) The "Subject: " line
 # 
 # It is the responsibility of the mail server to determine what should take
 # place when an item is selected, via [<handlerNS>::goToMatch].
 # 
 # Returns a two item list, with the name of the window that we created as
 # well as the list of "inboxMembers".
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::createMailboxWindow {mailboxName mailMessages} {

    global MailmodeVars
    
    watchCursor
    status::msg [set msg "Opening $mailboxName mailbox É"]
    
    set inboxMembers [list]
    set txt1 "Press \"Return\" to open message window"
    set txt2 "Float Mailbox Message Marks"
    append text "(" $txt1 ") -- (" $txt2 ")"
    append text "\r" [string repeat "~" [string length $text]] "\r"
    # Set default padding variables.
    set pad1 2
    set pad2 20
    set max2 35
    # Parse the supplied arguments.
    foreach mailMsg $mailMessages {
	# Mailbox index number.
	set index [lindex $mailMsg 0]
	if {([string length $index] > $pad1)} {
	    set pad1 [string length $index]
	} 
	# Identifier.
	set identifier "°$mailboxName--$index"
	# E-mail address of sender.
	set from [string trim [lindex $mailMsg 1]]
	set tag  ""
	while {([lsearch -exact $inboxMembers $from$tag] > -1)} {
	    if {![string length $tag]} {
		set tag " <2>"
	    } else {
		regexp {[0-9]+} $tag tag
		set tag " <[expr {$tag + 1}]>"
	    }
	}
	append from $tag
	lappend inboxMembers $from
	if {([string length $from] > $max2)} {
	    set fromBeg [string range $from 0 [expr {$max2 - 12}]]
	    set fromEnd [string range $from end-9 end]
	    set from "${fromBeg}É${fromEnd}"
	} 
	if {([string length $from] > $pad2)} {
	    set pad2 [string length $from]
	}
	# Subject line.
	set subject [Mail::parseHeaderField [string trim [lindex $mailMsg 2]]]
	lappend textItems [list $index $identifier $from $subject]
    }
    # Now we create the text string.
    if {$MailmodeVars(newerMessagesListedFirst)} {
        set textItems [lreverse $textItems]
    } 
    foreach textItem $textItems {
	append text [format "%-${pad1}s |" [lindex $textItem 0]] " " \
	  [format "%-${pad2}s : %-300s[lindex $textItem 1]" \
	  [lindex $textItem 2] [lindex $textItem 3]] "\r"
    }
    if {![string length $text]} {
	alertnote "No messages in '$mailboxName'!"
	return
    }
    # Use an existing window, or create a new one.
    set n "* MAILBOX '$mailboxName' *"
    if {[win::Exists $n]} {
	set w $n
        bringToFront $w
	win::setInfo $w read-only 0
	deleteText -w $w [minPos -w $w] [maxPos -w $w]
	insertText -w $w $text
    } else {
	set w [Mail::createWindow "browser" $n $text]
    }
    goto [minPos -w $w]
    set match [search -w $w -n -s -f 1 -r 0 -- $txt1 [minPos -w $w]]
    eval [list text::color -w $w] $match 1
    set match [search -w $w -n -s -f 1 -r 0 -- $txt2 [minPos -w $w]]
    eval [list text::color -w $w] $match 4
    eval [list text::hyper -w $w] $match {Mail::floatMailboxMessages}
    set marks [Mail::MarkFile -w $w 1]
    if {$MailmodeVars(autoFloatMailboxWindowMarks) && $marks} {
        catch {Mail::floatMailboxMessages $w 0}
    } 
    winReadOnly $w
    browse::Down $w
    status::msg "$msg finished"
    return [list $w $inboxMembers]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::floatMailboxMessages" --
 # 
 # Build a menu to float for the marks in the Mailbox browsing window.  This
 # is just a bit more advanced from the standard "Float Marks" palette in
 # that clicking on an item actually opens the message.
 # 
 # We add an initial space to each item's name to make sure that nothing is
 # interpreted as a special character by the [Menu] command.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::floatMailboxMessages {{w ""} {markFile 1}} {
    
    global MailmodeVars defTop defWidth
    
    variable floatID
    
    if {($w eq "")} {
	set w [Mail::findBrowserWindow]
    } 
    if {($w eq "")} {
	return
    } 
    if {$markFile} {
        Mail::MarkFile -w $w 1
    } 
    set markList [list " -- Mailbox Browsing Window --" "(-)"]
    foreach markItem [getNamedMarks -w $w -n] {
	lappend markList " $markItem"
    }
    Menu -n "Mailbox Messages" -p {Mail::menuProc} -c -m $markList
    # Determine left, top parameters for the floating menu.
    set geom [getGeometry $w]  ; # l t w h
    set left [expr {[lindex $geom 0] + [lindex $geom 2] + 20}]
    set top  [lindex $geom 1]
    # Determine width parameter for the floating menu.
    set width 125
    foreach item $markList {
	set newWidth [expr {[string length $item] * 6}]
	if {$newWidth > $width} {
	    set width $newWidth
	}
    }
    set width [expr {($width > 250) ? 250 : $width}]
    # Float the menu.
    catch {unfloatNamedMarks -w $w}
    catch {unfloat $floatID}
    set floatID [float -m "Mailbox Messages" -l $left -t $top -w $width ]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::goToMatch" --
 # 
 # Called by arrow navigation keys to navigate MAILBOX windows containing
 # lists of messages, use any procedure defined by the current Mail handler.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::goToMatch {args} {
    
    win::parseArgs w
    
    Mail::requireMailWindow -w $w "browser"
    Mail::handlerAction "goToMatch" -w $w
    return
}

# ===========================================================================
# 
# .