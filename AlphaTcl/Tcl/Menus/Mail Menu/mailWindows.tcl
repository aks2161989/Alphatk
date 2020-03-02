## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Mail Menu - an extension package for Alpha
 #
 # FILE: "mailWindows.tcl"
 # 
 #                                          created: 04/24/1996 {12:08:43 PM}
 #                                      last update: 03/21/2006 {01:52:56 PM}
 # Description:
 # 
 # Manipulation and management of Mail mode windows.  This does not include
 # any procedures to create the Mail windows, see "mailMenu.tcl" for those.
 # 
 # At present, we only allow one browsing or viewing window to be open, and
 # we always replace its contents when necessary.  This makes it much easier
 # to locate the window that we need, based on window name string matching.
 # 
 # See the "Changes - Mail Menu" file for license information.
 # 
 # ==========================================================================
 ##

proc mailWindows.tcl {} {}

namespace eval Mail {

    # Before we do anything else, make sure that our "mode" is initialized.
    Mail::initializeMode
    
    # Define minor-modes used for window creation in [Mail::createWindow].
    set ::mode::features(Mail) [list "mailMenu"]
    # Create a "mailbrowse" minor mode.
    alpha::minormode mailbrowse \
      bindtags          "Mail" \
      +bindtags         "Brws" \
      colortags         "" \
      +featuremodes     "Mail" \
      hookmodes         "Mail" \
      varmodes          "Mail"
    # Create a "mailview" minor mode.
    alpha::minormode mailview \
      bindtags          "Mail" \
      colortags         "" \
      +featuremodes     "Mail" \
      hookmodes         "Mail" \
      varmodes          "Mail"
    # Create a "mailnew" minor mode.
    alpha::minormode mailnew \
      bindtags          "Mail" \
      colortags         "Mail" \
      +featuremodes     "Mail" \
      hookmodes         "Mail" \
      varmodes          "Mail"
    
    # This ensures that we have unique New Mail window names.
    variable newMailCounter
    if {![info exists newMailCounter]} {
	set newMailCounter 0
    } 
    # These are the names used for Display Draft/Sent windows.
    variable displayWindowNames
    array set displayWindowNames [list \
      "draft"   "* Draft Mail Contents *" \
      "sent"    "* Sent Mail Contents *" \
      ]
    variable displayFolderPrefs
    array set displayFolderPrefs [list \
      "draft"   "mailDraftsFolder" \
      "sent"    "mailSentFolder" \
      ]
    
    # Register window hook(s).
    hook::register "preCloseHook"       {Mail::preCloseHook} Mail
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::createWindow" --
 # 
 # Create a new "Mail" window, optionally in a special minor-mode.
 # 
 # For now, our "mailview" minor mode can only be applied before the window
 # is actually created.  In most cases we assume that the supplied "name"
 # argument doesn't already exist as a window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::createWindow {type name text} {
    
    global MailmodeVars
    
    variable newMailCounter
    variable windowTypes
    
    switch -- $type {
        "browser" {
	    win::setInitialConfig $name minormode mailbrowse window
	    set w [eval [list new -n $name -text $text -m "Text"] \
	      $MailmodeVars(mailboxWindowGeometry)]
        }
	"display" {
	    win::setInitialConfig $name minormode mailview window
	    # Create the new window, and do some fancy stylizing.
	    set w [new -n $name -m "Text" -text $text]
	}
	"header" {
	    win::setInitialConfig $name minormode mailview window
	    set w [new -n $name -m "Text" -text $text -dirty 0]
	}
        "new" {
	    append name " ([incr newMailCounter])"
	    while {[win::Exists $name]} {
		set name "$name ([incr newMailCounter])"
	    }
	    win::setInitialConfig $name minormode mailnew window
	    set w [new -n $name -m "Text" -text $text -dirty 0]
        }
	"sent" {
	    win::setInitialConfig $name minormode mailview window
	    set w [new -n $name -m "Text" -text $text]
	}
	"viewer" {
	    win::setInitialConfig $name minormode mailview window
	    set w [eval [list new -n $name -m "Text" -text $text -dirty 0] \
	      [list -font $MailmodeVars(mailViewWindowFont)] \
	      [list -fontsize $MailmodeVars(mailViewFontSize)] \
	      $MailmodeVars(mailViewWindowGeometry)]
	}
	default {
	    error "Unknown window type: $type"
	}
    }
    set windowTypes($w) $type
    return $w
}

# ===========================================================================
# 
# ×××× Mail Window Hooks ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::preCloseHook" --
 # 
 # Called before the window is killed.
 # 
 # (*) Close any floating marks palette if it exists.
 # (*) Remember the geometry of browsing and viewing windows.
 # (*) Unset the "type" associated with this window.
 # (*) If the window type is "new" and the message has not been sent, offer
 #     to save it in the Drafts folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::preCloseHook {winName} {
    
    global MailmodeVars
    
    variable floatID
    variable sentWindows
    
    # Close floating palletes associated with this window.
    catch {unfloatNamedMarks -w $winName}
    
    switch -- [Mail::getWindowType -w $winName] {
        "viewer" {
	    set MailmodeVars(mailViewWindowGeometry) \
	      [concat [list "-g"] [getGeometry $winName]]
	    prefs::modified MailmodeVars(mailViewWindowGeometry)
        }
        "browser" {
	    catch {unfloat $floatID}
	    set MailmodeVars(mailboxWindowGeometry) \
	      [concat [list "-g"] [getGeometry $winName]]
	    prefs::modified MailmodeVars(mailboxWindowGeometry)
        }
        "new" {
	    if {[info exists sentWindows($winName)]} {
		array unset sentWindows $winName
	    } elseif {[win::getInfo $winName "dirty"]} {
		set q "This message has not been sent. Do you want to save it\
		  in your \"Drafts\" folder?"
		if {[askyesno $q]} {
		    Mail::saveInFolder $winName "draft"
		} 
	    }
        }
    }
    array unset winType $winName
    return
}

# ===========================================================================
# 
# ×××× Mail Window Support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::requireMailWindow" --
 # 
 # Some actions can/should only be performed in Mail mode windows.  The
 # "types" list determines what is required.  In any case, if the active
 # window conforms to the specifications, we silently return, else we throw
 # an error.  One can wrap this in a [catch] to determine if the active
 # window met the criteria or not, or use [Mail::getWindowType] instead.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::requireMailWindow {args} {
    
    win::parseArgs w args
    
    requireOpenWindow
    set winType [Mail::getWindowType -w $w]
    if {![llength $args]} {
        set args [list "any"]
    } 
    foreach type $args {
	set type [string tolower $type]
	# If the window matches the "type" then return silently.
	if {($type eq "any") && [string length $winType]} {
	    return
	} elseif {($winType eq $type)} {
	    return
	}
    }
    # Pass on an error message for the status bar.
    set errorMessage "Cancelled -- this action is only allowed in "
    switch -- [set type [string tolower [lindex $args 0]]] {
	"any"           {append errorMessage "Mail mode windows."}
	"new"           {append errorMessage "New Mail windows."}
	"viewer"        {append errorMessage "Mail Viewer windows."}
	"browser"       {append errorMessage "MAILBOX browsing windows."}
	"header"        {append errorMessage "'full header contents' windows."}
	default         {error "Unknown window type: $type"}
    }
    error $errorMessage
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::getWindowType" --
 # 
 # Determine the window's "type", i.e. "browser" "viewer" "header" or "new".
 # If we can't determine the window's type, return an empty string.  Each
 # window that is created by this package should be registering its "type"
 # automatically in the "windowTypes" array.  If no entry is present we then
 # attempt to [string match] the name of the window to determine type.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::getWindowType {args} {
    
    global MailmodeVars
    
    variable displayWindowNames
    variable windowTypes
    
    win::parseArgs w
    
    # Windows should be registering their types when they are created.
    if {[info exists windowTypes($w)]} {
        return $windowTypes($w)
    } 
    set type ""
    set tail [win::Tail $w]
    if {[string match "*New Mail*" $tail]} {
	set type "new"
    } elseif {[string match "*MAIL (*) Full Header*" $tail]} {
	set type "header"
    } elseif {[string match "*MAILBOX*" $tail]} {
	set type "browser"
    } elseif {[string match "*MAIL Window*" $tail] \
      || [string match "*MAIL (*) *" $tail]} {
	if {[string length [Mail::getFieldValue -w $w "from"]]} {
	    set type "viewer"
	} 
    } elseif {[string match $displayWindowNames(sent) $tail]} {
	set type "display"
    } elseif {[string match $displayWindowNames(draft) $tail]} {
	set type "display"
    } elseif {[string match "$MailmodeVars(mailSentFolder)*" $w]} {
	set type "sent"
    } elseif {[string match "Sent Mail*" $w]} {
	set type "sent"
    } 
    return $type
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::findBrowserWindow" --
 # 
 # If a Mailbox browsing window is open, return its name, otherwise return an
 # empty string.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::findBrowserWindow {} {
    
    set w ""
    foreach winName [winNames] {
	if {([Mail::getWindowType -w $winName] eq "browser")} {
	    set w $winName
	    break
	}
    }
    return $w
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::findViewerWindow" --
 # 
 # If a Mailbox viewing window is open, return its name, otherwise return an
 # empty string.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::findViewerWindow {} {
    
    set w ""
    foreach winName [winNames] {
	if {([Mail::getWindowType -w $winName] eq "viewer")} {
	    set w $winName
	    break
	}
    }
    return $w
}

# ===========================================================================
# 
# ×××× Mail Window Navigation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::switchWindow" --
 # 
 # Try to find the alternative view/browse window -- if found, then switch to
 # it silently.  Otherwise, inform the user why nothing happened.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::switchWindow {} {
    
    global mode
    
    set currentType [Mail::getWindowType -w [win::Current]]
    set typesList   [list "browser" "viewer" "header" "new" "any"]
    set typesList   [lremove $typesList [list $currentType]]
    lappend typesList $currentType
    foreach type $typesList {
	foreach w [winNames -f] {
	    set winType [Mail::getWindowType -w $w]
	    if {($type eq $winType) && ($w ne [win::Current])} {
		bringToFront $w
		return 1
	    } 
	}
    }
    return 0
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::nextPrevMessage" --
 # 
 # Advance to the next/previous window as determined by either the current
 # position in a Mailbox browsing window, or the current message that is
 # displayed in the Mail viewing window.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::nextPrevMessage {itemName} {
    
    set winType [Mail::getWindowType]
    if {($winType eq "browser")} {
	set w [win::Current]
    } elseif {($winType eq "viewer")} {
	# Find our divider line.
	set pos [minPos]
	set pat {^>====+[^\r]====+<$}
	set dividerLine [search -s -n -f 1 -r 1 -- $pat $pos]
	if {![llength $dividerLine]} {
	    error "Cancelled -- couldn't find the divider line."
	} 
	set posL [lindex $dividerLine 0]
	set pat  {^Msg}
	set match [search -n -s -f 1 -r 1 -l $posL -- $pat $pos]
	if {![llength $match]} {
	    error "Cancelled -- couldn't find the \"Msg\" line."
	} 
	set pos [lindex $match 0]
	set pat {"([^"]+)" \(([0-9]+)\).*"([^"]+)"}
	set text [getText $pos [pos::nextLineStart $pos]]
	if {![regexp -- $pat $text -> number orig folder]} {
	    error "Cancelled -- couldn't identify the\
	      mailbox browsing window."
	}
	set w "* MAILBOX '${folder}' *"
	set pos [minPos -w $w]
	set pat "°${folder}--${orig}"
	set match [search -w $w -n -s -f 1 -r 1 -- $pat $pos]
	if {![llength $match]} {
	    error "Cancelled -- couldn't identify original\
	      message in the browsing window."
	} 
	set pos0 [pos::lineStart -w $w [lindex $match 0]]
	set pos1 [pos::nextLineStart -w $w $pos0]
	selectText -w $w $pos0 $pos1
	refresh -w $w
    } else {
	error "Cancelled -- only available in browsing/viewing windows."
    }
    if {![win::Exists $w]} {
	error "Cancelled -- the \"${w}\" window could not be found."
    }
    set positions [list [getPos -w $w] [selEnd -w $w]]
    switch -- $itemName {
	"prevMessage" {browse::Up   $w}
	"nextMessage" {browse::Down $w}
    }
    if {[pos::compare [getPos -w $w] == [lindex $positions 0]] \
      || [pos::compare [selEnd -w $w] == [lindex $positions 1]]} {
	error "Cancelled -- could not find the\
	  [string tolower [quote::Prettify $itemName]]\
	  in the browsing window."
    } 
    browse::Goto $w
    return
}

# ===========================================================================
# 
# ×××× Mail Window Fields ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::getFieldValue" --
 # 
 # Obtain the field value found in the header, returning an empty string if
 # the field doesn't exists.  Also returns the body of the message for the
 # field name "content".  We don't pay much attention to any formatting of
 # the results, it is up to the calling code to manipulate it as desired.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::getFieldValue {args} {
    
    win::parseArgs w fieldName
    
    set fieldValue ""
    # Find our divider line.
    set pos [minPos -w $w]
    set pat {^>====+[^\r]+====+<$}
    set dividerLine [search -w $w -s -n -f 1 -r 1 -- $pat $pos]
    if {![llength $dividerLine]} {
	return ""
    } 
    # Special (and easy) case.
    if {([string tolower $fieldName] eq "content")} {
	set pos [pos::nextLineStart -w $w [lindex $dividerLine 0]]
	return [getText -w $w $pos [maxPos -w $w]]
    } 
    # Now grab the text up to the divider.
    set headerText  [getText -w $w $pos [lindex $dividerLine 0]]
    set headerLines [split $headerText "\r\n"]
    set pat "^[string tolower $fieldName]:\[\t \]+(\[^\r\n\]*)$"
    for {set i 0} {($i < [llength $headerLines])} {incr i} {
	set headerLine [lindex $headerLines $i]
	if {[regexp -nocase -- $pat $headerLine -> value]} {
	    set fieldValue [string trim $value]
	    while {1} {
		set nextHeaderLine [lindex $headerLines [expr {$i + 1}]]
		if {[regexp {^[\t ]+\S} $nextHeaderLine]} {
		    append fieldValue " " [string trim $nextHeaderLine]
		    incr i
		} else {
		    break
		}
	    } 
	    break
	}
    }
    return $fieldValue
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::selectNextField" --
 # 
 # Called by the "Mail > Select Next Field" menu item, using the keyboard
 # shortcut defined by the MailmodeVars(selectNextField) preference.
 # 
 # Jump to (and select the content of) the next "To:" "Subject:" etc field in
 # an active Mail window.  If no header field is found, attempt to select the
 # entire body of the message.  If the cursor/selection already resides in
 # the body, we only jump back to the first field if there is a selection
 # that includes the ending position of the window.
 # 
 # If this is a "New Mail" window and the cursor lies in the body of the
 # message, then we attempt to call whatever global "special key" procedure
 # might be bound to the original keypress.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::selectNextField {args} {
    
    global MailmodeVars keys::specialBindings keys::specialProcs
    
    win::parseArgs w
    
    variable Keywords
    
    Mail::requireMailWindow
    set winType [Mail::getWindowType -w $w]
    if {($winType eq "browser")} {
	set pos0 [getPos -w $w]
	set pos1 [selEnd -w $w]
	browse::Down -w $w
	if {[pos::compare -w $w $pos0 == [getPos -w $w]] \
	  && [pos::compare -w $w $pos1 == [selEnd -w $w]]} {
	    # We're at the end of the window.
	    goto -w $w [minPos -w $w]
	    browse::Down -w $w
	} 
	return
    } 
    append pat "(^(" [join $Keywords {|}] ") +)|" {(^>==[^\r\n]+==<$)}
    if {[isSelection -w $w] \
      && [pos::compare -w $w [selEnd -w $w] == [maxPos -w $w]]} {
	set pos [minPos -w $w]
    } else {
	set pos [selEnd -w $w]
    }
    set match [search -w $w -n -s -f 1 -r 1 -i 1 -- $pat $pos]
    if {![llength $match]} {
	if {[pos::compare -w $w [getPos -w $w] == [minPos -w $w]]} {
	    error "Cancelled -- could not find next field."
	} elseif {($winType eq "new")} {
	    set ourKey $MailmodeVars(selectNextField)
	    set specialBinding ""
	    foreach specialItem [array names keys::specialBindings] {
		if {($ourKey eq $keys::specialBindings($specialItem))} {
		    set specialBinding $specialItem
		    break
		} 
	    }
	    if {($specialBinding ne "")} {
		eval $keys::specialProcs($specialBinding)
		return
	    } else {
		error "Cancelled -- could not find next field."
	    }
	} elseif {[pos::compare -w $w [selEnd -w $w] != [minPos -w $w]]} {
	    goto -w $w [minPos -w $w]
	    Mail::selectNextField -w $w
	    return
	} else {
	    error "Cancelled -- could not find next field."
	}
    }
    if {[lookAt -w $w [lindex $match 0]] eq ">"} {
	selectText -w $w [pos::nextLineStart -w $w \
	  [lindex $match 1]] [maxPos -w $w]
    } else {
	set pos0 [lindex $match 1]
	set pos1 [pos::lineEnd -w $w $pos0]
	set pos2 [pos::nextLineStart -w $w $pos1]
	set pos3 [pos::lineEnd -w $w $pos2]
	while {[regexp {^\s+\S} [getText -w $w $pos2 $pos3]]} {
	    set pos1 $pos3
	    set pos2 [pos::nextLineStart -w $w $pos1]
	    set pos3 [pos::lineEnd -w $w $pos2]
	}
	selectText -w $w $pos0 $pos1
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::addField" --
 # 
 # Add or supplement a header field with an e-mail address in a "New Mail"
 # window.  Our prompt includes all saved e-mails as options.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::addField {itemName} {
    
    variable savedEmails
    
    Mail::requireMailWindow "new"
    
    regsub -- {^add} $itemName {} field
    set p "Add [quote::Prettify $field] address:"
    if {![llength [array names savedEmails]]} {
	set addEmail [prompt $p ""]
    } else {
	foreach item [array names savedEmails] {
	    lappend emails $savedEmails($item)
	}
	set emails   [lsort -dictionary -unique $emails]
	set addEmail [lindex $emails 0]
	set addEmail [eval \
	  [list prompt $p $addEmail "options:"] $emails]
    }
    if {[info exists savedEmails($addEmail)]} {
	set address  [lindex $savedEmails($addEmail) 0]
	set realName [lindex $savedEmails($addEmail) 1]
	set addEmail [Mail::parseEmailField "$realName $address"]
    } 
    set email [string trim $addEmail]
    append field ":"
    set pat1 "^${field}.*"
    set pat2 "^To:"
    set match1 [search -n -s -f 1 -r 1 -i 1 -- $pat1 [minPos]]
    set match2 [search -n -s -f 1 -r 1 -i 1 -- $pat2 [minPos]]
    if {[llength $match1]} {
	set pos  [pos::lineEnd [lindex $match1 0]]
	set line [getText [pos::lineStart $pos] $pos]
	if {[regexp -- {:\s*$} $line]} {
	    set addText $email
	} else {
	    append addText ",\r" [string repeat " " 10] $email
	}
	while {1} {
	    set pos1 [pos::nextLineStart $pos]
	    set pos2 [pos::nextLineEnd   $pos]
	    set text [getText $pos1 $pos2]
	    if {[pos::compare $pos1 >= [maxPos]] || ![regexp {^\s+} $text]} {
		break
	    } else {
		set pos $pos2
	    }
	}
    } elseif {[llength $match2]} {
	set pos [pos::nextLineStart [lindex $match1 0]]
	append addText [format {%-10s} $field] $email "\r"
	while {1} {
	    set pos1 [pos::nextLineStart $pos]
	    set pos2 [pos::nextLineEnd   $pos]
	    set text [getText $pos1 $pos2]
	    if {[pos::compare $pos1 >= [maxPos]] \
	      || ![regexp {^\s+} $text]} {
		break
	    } else {
		set pos $pos1
	    }
	}
    } else {
	set pos [pos::nextLineStart [minPos]]
	append addText [format {%-10s} $field] $email "\r"
    }
    replaceText $pos $pos $addText
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Mail Folders ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::saveInFolder" --
 # 
 # Save the contents of the current window in the "Drafts" or "Sent" folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::saveInFolder {winName folderType} {
    
    global MailmodeVars
    
    variable displayFolderPrefs
    variable displayWindowNames
    variable sentWindows
    
    if {([Mail::getWindowType -w $winName] ne "new")} {
	return
    } 
    # Determine our file name.
    set dir $MailmodeVars($displayFolderPrefs($folderType))
    if {![file isdirectory $dir]} {
	file mkdir $dir
    }
    set n [mtime [now] short]
    regsub -all -- ":|[quote::Regsub [file separator]]" $n "-" n
    set f [file join $dir $n]
    # Write the contents of the supplied window name to the file.
    set pos0 [minPos -w $winName]
    set pos1 [maxPos -w $winName]
    file::writeAll $f [getText -w $winName $pos0 $pos1] 1
    file::toAlphaSigType $f
    # Adjust menus, variables, etc.  and re-create display window if needed.
    switch -- $folderType {
	"draft" {
	    menu::buildSome "mailMenu"
	}
	"sent" {
	    menu::buildSome "sentMail"
	    set sentWindows($winName) 1
	}
    }
    if {[win::Exists $displayWindowNames($folderType)]} {
	Mail::displayFolderContents $folderType
    } 
    alertnote "The message has been saved in your\
      [string totitle $folderType] folder."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::displayFolderContents" --
 # 
 # Open the contents of a user's "Drafts/Sent" folder in a new window.  We
 # scan the contents of each file, parsing out the header information which
 # is then presented in a separate section with hyperlinks.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::displayFolderContents {folderType} {
    
    global MailmodeVars
    
    variable displayFolderPrefs
    variable displayWindowNames
    variable Keywords
    
    set dir  $MailmodeVars($displayFolderPrefs($folderType))
    set w    $displayWindowNames($folderType)
    set FolderType [string totitle $folderType]
    if {![file isdirectory $dir]} {
        alertnote "The $FolderType folder doesn't exist."
	return
    } 
    status::msg [set msg "Creating $FolderType display window É"]
    watchCursor
    # Create our text string.
    set text {
FOLDER Mail Contents

This window contains the e-mail header fields for item file in your FOLDER
folder.  Below each set of fields are two hyperlinks that allow you to either
open the contents of the file in a new window, or to delete the file from the
FOLDER folder.

(Click here ÇShow FOLDER Folder in FinderÈ to close this window and, um...)
}
    regsub -all -- {FOLDER} $text $FolderType text
    append text "\r" [string repeat "_" 80] "\r\r"
    # Scan our files and add the information.
    set mailItems   [list]
    set orderedList [list]
    foreach f [glob -nocomplain -dir $dir -- "*"] {
	set fileTimes([file mtime $f]) $f
    }
    foreach timeStamp [lsort -dictionary [array names fileTimes]] {
	lappend orderedList $fileTimes($timeStamp)
    }
    foreach f $orderedList {
	set counter "-1"
	set mailItemText ""
	set headerLines  [list "Message ID: \"[file tail $f]\"" ""]
	foreach fileLine [split [file::readAll $f] "\r\n"] {
	    if {[regexp {>====+[^\r]+=====<} $fileLine]} {
		lappend headerLines "" "Preview:" ""
		set counter 0
	    } elseif {($counter > 1) || [string length $fileLine]} {
		lappend headerLines $fileLine
	    }
	    if {($counter > 4)} {
		lappend headerLines "..."
	        break
	    } elseif {($counter >= 0)} {
	        incr counter
	    }
	}
	append mailItemText [join $headerLines "\r"] "\r\r" \
	  "ÇOpen $FolderType ItemÈ  ÇDelete $FolderType ItemÈ"
	lappend mailItems $mailItemText
    }
    if {![llength $mailItems]} {
        if {[win::Exists $w]} {
            killWindow -w $w
        } 
	status::msg "There are no contents to display."
	return
    } 
    foreach mailListItem $mailItems {
	append text $mailListItem "\r" [string repeat "_" 80] "\r\r"
    }
    # Use an existing window, or create a new one.
    if {[win::Exists $w]} {
	set w $w
	bringToFront $w
	win::setInfo $w read-only 0
	# Avoid bug# 1671 -- won't be necessary after Alpha 8.0 final release
	catch {removeColorEscapes -w $w}
	deleteText -w $w [minPos -w $w] [maxPos -w $w]
	goto -w $w [minPos -w $w]
	insertText -w $w $text
    } else {
	set w [Mail::createWindow "display" $w $text]
    }
    Mail::MarkFile -w $w 1
    # Colorize the title and all header fields.
    help::colourTitle "red"
    set pat1 "^([join $Keywords {|}])"
    set pat2 "^Preview:\$"
    win::searchAndHyperise $pat1 "" 1 1
    win::searchAndHyperise $pat2 "" 1 5
    # Create hyperlinks.
    set pat0 "ÇShow $FolderType Folder in FinderÈ"
    set match0 [search -w $w -n -s -f 1 -r 1 -- $pat0 [minPos -w $w]]
    if {[llength $match0]} {
	set script [list {Mail::showInFinder} $folderType]
	set pos0   [pos::math [lindex $match0 0] + 1]
	set pos1   [pos::math [lindex $match0 1] - 1]
	text::color -w $w $pos0 $pos1 4
	text::hyper -w $w $pos0 $pos1 $script
    }
    set pat1 {^Message ID: \"([^\r]+)\"$}
    set pat2 "ÇOpen $FolderType ItemÈ"
    set pat3 "ÇDelete $FolderType ItemÈ"
    set pos  [minPos]
    while {1} {
	set match1 [search -w $w -n -s -f 1 -r 1 -- $pat1 $pos]
	if {![llength $match1]} {
	    break
	} 
	eval [list text::color -w $w] $match1 5
	regexp -- $pat1 [eval getText $match1] -> fileName
	set pos [pos::nextLineStart [lindex $match1 0]]
	set match2 [search -w $w -n -s -f 1 -r 0 -- $pat2 $pos]
	if {[llength $match2]} {
	    set script [list {Mail::openFolderWindow} $fileName $folderType]
	    set pos0 [pos::math [lindex $match2 0] + 1]
	    set pos1 [pos::math [lindex $match2 1] - 1]
	    text::color -w $w $pos0 $pos1 4
	    text::hyper -w $w $pos0 $pos1 $script
	} else {
	    break
	}
	set match3 [search -w $w -n -s -f 1 -r 0 -- $pat3 $pos]
	if {[llength $match3]} {
	    set script [list {Mail::deleteFolderFile} $fileName $folderType]
	    set pos0 [pos::math [lindex $match3 0] + 1]
	    set pos1 [pos::math [lindex $match3 1] - 1]
	    text::color -w $w $pos0 $pos1 4
	    text::hyper -w $w $pos0 $pos1 $script
	} else {
	    break
	}
	set pos [pos::nextLineStart [lindex $match3 0]]
    }
    goto [minPos -w $w]
    winReadOnly $w
    refresh -w $w
    status::msg "$msg finished"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::showInFinder" --
 # 
 # Kill the display window, and open the specified folder in the Finder.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::showInFinder {folderType} {
    
    global MailmodeVars
    
    variable displayFolderPrefs
    variable displayWindowNames
    
    set prefName $displayFolderPrefs($folderType)
    append Folder {\"} [string totitle $folderType] {\" folder}
    if {![file isdirectory $MailmodeVars($prefName)]} {
        set msg "Cancelled -- the $Folder doesn't exist!"
	alertnote $msg
	error $msg
    }
    if {[win::Exists $displayWindowNames($folderType)]} {
	killWindow -w $displayWindowNames($folderType)
    } 
    file::showInFinder $MailmodeVars($prefName)
    status::msg "The $Folder has been displayed in the Finder."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::openFolderWindow" --
 # 
 # This should only be called by a hyperlink.
 # 
 # 'draft' --
 # 
 # Open a "New Mail" window with the contents of the draft file, and then
 # remove that file.
 # 
 # 'sent' --
 # 
 # Open the file as a normal window in Mail mode.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::openFolderWindow {fileName folderType} {
    
    global MailmodeVars
    
    variable displayWindowNames
    variable displayFolderPrefs
    
    set dir $MailmodeVars($displayFolderPrefs($folderType))
    set fileName [file join $dir $fileName]
    set text [file::readAll $fileName]
    if {($folderType eq "draft")} {
	menu::buildSome "mailMenu"
	file delete -force $fileName
	if {[win::Exists $displayWindowNames(draft)]} {
	    Mail::displayFolderContents "draft"
	} 
	set w [Mail::createWindow "new" "New Mail" $text]
	set msg "The saved 'draft' file has been deleted.  If you do not\
	  send this e-mail, you must save it again as a draft."
    } elseif {($folderType eq "sent")} {
	set name "Sent Mail ([file tail $fileName])"
	if {[win::Exists $name]} {
	    bringToFront $name
	} else {
	    set w [Mail::createWindow "sent" $name $text]
	}
	winReadOnly $w
    } else {
        error "Unknown folder type: $folderType"
    }
    # If we don't automatically color quoted text, color our divider line.
    if {!$MailmodeVars(colorNewMailQuotedText)} {
	set pat {^>====+[^\r]+====+<$}
	set pos [minPos -w $w]
	set dividerLine [search -w $w -s -n -f 1 -r 1 -- $pat $pos]
	if {[llength $dividerLine]} {
	    eval [list text::color -w $w] $dividerLine 5
	}
    } 
    goto -w $w [minPos -w $w]
    refresh -w $w
    Mail::selectNextField -w $w
    if {[info exists msg]} {
        alertnote $msg
    } 
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::deleteFolderFile" --
 # 
 # This should only be called by a hyperlink.
 # 
 # Delete a draft/sent mail file, rebuild the menu, and re-create the Display
 # window to show the updated contents.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::deleteFolderFile {fileName folderType} {
    
    global MailmodeVars
    
    variable displayFolderPrefs
    variable displayWindowNames
    
    set dir $MailmodeVars($displayFolderPrefs($folderType))
    file delete -force [file join $dir $fileName]
    switch -- $folderType {
	"draft" {menu::buildSome "mailMenu"}
	"sent"  {menu::buildSome "sentMail"}
    }
    if {[win::Exists $displayWindowNames($folderType)]} {
	Mail::displayFolderContents $folderType
    } 
    alertnote "The [string totitle $folderType] mail file has been deleted."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::newFolderLocation" --
 # 
 # Called after the user has changed the location of a Sent/Drafts folder.
 # If the folder is not empty, ask if we should transfer the contents from
 # the old location to the new one.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::newFolderLocation {prefName} {
    
    global MailmodeVars
    
    variable oldFolderLocations
    variable windowTypes
    
    switch -- $prefName {
        "mailDraftsFolder"  {set folderType "draft"}
        "mailSentFolder"    {set folderType "sent"}
	default             {error "Unknown preference name: $prefName"}
    }
    if {![info exists oldFolderLocations($folderType)]} {
        return
    } 
    set oldFolder     $oldFolderLocations($folderType)
    set newFolder     $MailmodeVars($prefName)
    set FolderType    "\"[string totitle $folderType]\""
    set reopenFiles   [list]
    set copyFiles     [list]
    set uncopiedFiles [list]
    # Make sure that we're not over-writing pre-existing files in the new
    # directory.
    foreach oldFile [glob -nocomplain -dir $oldFolder -- "*"] {
	set newFile [file join $newFolder [file tail $oldFile]]
	if {[file exists $newFile]} {
	    set msg "\"[file tail $oldFile]\" already exists in the new\
	      $FolderType location -- do you want to replace it?"
	    if {![askyesno $msg]} {
		lappend uncopiedFiles   $oldFile
	    } else {
		lappend copyFiles       $oldFile
	    }
	} else {
	    lappend copyFiles $oldFile
	}
	if {[llength [set openWindows [file::hasOpenWindows $oldFile]]]} {
	    foreach w $openWindows {
		set winType [Mail::getWindowType $w]
		killWindow -w $w
	    }
	    lappend reopenFiles [list $newFile $winType]
	}
    }
    if {[llength $copyFiles]} {
	eval [list file copy -force --] $copyFiles [list $newFolder]
    }
    foreach fileItem $reopenFiles {
	set w [edit -c [lindex $fileItem 0]]
	set windowTypes($w) [lindex $fileItem 1]
    }
    if {[llength $uncopiedFiles]} {
	set p "The following files were not moved:"
	catch {listpick -p $p $uncopiedFiles}
	file::showInFinder $oldFolder
	file::showInFinder $newFolder
    } else {
	status::msg "All message files have been copied to the new folder."
	set q "Do you want to delete the older $FolderType folder?"
	if {[askyesno $q]} {
	    file delete -force -- $oldFolder
	    status::msg "The older $FolderType folder has been removed."
	}
    }
    set oldFolderLocations($folderType) $newFolder
    return
}

# ===========================================================================
# 
# .