## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "filesetsAttachments.tcl"
 #                                          created: 07/25/2003 {08:03:28 AM}
 #                                      last update: 02/15/2006 {03:23:02 PM}
 # Description:
 # 
 # Provides support for adding settings to the definitions of individual
 # filesets.  Each collection of extra settings is considered an "attachment"
 # and can be created by any AlphaTcl package.  Examples of attachments
 # include the default tab size or indentation amount when a file is opened,
 # or the encoding of a file belonging to a fileset.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # Copyright (c) 2003-2006  Vince Darley.
 # All rights reserved
 # 
 # ==========================================================================
 ##

proc filesetsAttachments.tcl {} {}

namespace eval fileset {}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::chooseAttachments" --
 # 
 # Called by the [editFilesets] dialog when the "Attach/Detach Info" button
 # is pressed.  Create a dialog offering all of the current attachments
 # available, and adjust the settings as necessary.  We don't actually save
 # the new settings, but store them in an "attached" variable that will be
 # used later (if necessary) by [fileset::synchroniseAttachments].
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::chooseAttachments {} {
    
    variable infoTypes
    
    # This creates an "attached" variable in the [editFilesets] procedure.
    # It will be accessed by [fileset::synchroniseAttachments].
    upvar 2 attached attached
    # This determines the fileset from the current dialog pane.
    upvar 1 currentpage fset
    
    set items [fileset::getAttachments]
    if {![llength $items]} {
	alertnote "No items exist which can be attached"
	return
    }
    # Create and present a dialog to the user.
    set flagIntro "Each checkbox below refers to an \"attachment\"\
      that you can associate with the \"${fset}\" fileset.\
      \r\rEach attachment will add one or more settings that you can\
      then adjust in the main \"Edit Fileset\" dialog.\r"
    foreach name $items {
	lappend flagItems  $name
	lappend flagValues $attached($fset,$name)
	lappend flagHelp   [fileset::getAttachmentHelp $name]
    }
    set dialogScript [list dialog::make \
      -title "\"${fset}\" Fileset Attachments" \
      -width 450 \
      -ok "Save" \
      [list "" \
      [list [list multiflag $flagItems 2] $flagIntro $flagValues $flagHelp] \
      ]]
    if {[catch {eval $dialogScript} results]} {
	return
    }
    # Save the new information.
    foreach name $items value [lindex $results 0] {
	set attached($fset,$name) $value
    }
    foreach name [array names infoTypes] {
	# Get attachment type item from the group.
	set itemInfo $infoTypes($name)
	set onOff [expr {([lindex $itemInfo 0] eq "*") || $attached($fset,$name)}]
	set items [list]
	set groupItem [lindex $itemInfo 1]
	if {[llength $groupItem]} {
	    lappend items $groupItem
	}
	eval lappend items [lrange $itemInfo 2 end]
	foreach pair $items {
	    set item [lindex $pair 0]
	    if {$onOff} {
		uplevel 1 [list dialog::show_item $fset $item]
	    } else {
		uplevel 1 [list dialog::hide_item $fset $item]
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::getAttachmentHelp" --
 # 
 # List the help associated with each attachment for the dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::getAttachmentHelp {name} {
    
    variable infoTypes
    
    set itemInfo $infoTypes($name)
    if {[llength [lindex $itemInfo 1]]} {
	# Grouped attachment.
	set helpText [lindex $itemInfo 1 3]
    } else {
	# Single item attachment.
	set helpText [lindex $itemInfo 2 3]
    }
    if {($helpText ne "")} {
        return "New Settings Information: $helpText"
    } else {
        return "(No information available.)"
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::synchroniseAttachments" --
 # 
 # Called by [editFileset] or [editFilesets] after the user has pressed the
 # "Save" button.  [fileset::chooseAttachments] creates the "attached"
 # variable that we now use to finally save the new attachment status for
 # each fileset.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::synchroniseAttachments {fset} {
    
    variable attachments
    
    upvar 1 attached attached
    
    foreach name [fileset::getAttachments] {
	set value $attached($fset,$name)
	if {[info exists attachments($fset,$name)]} {
	    if {($value eq $attachments($fset,$name))} {
		continue
	    }
	}
	if {$value} {
	    set attachments($fset,$name) 1
	    prefs::modified attachments($fset,$name)
	} elseif {[info exists attachments($fset,$name)]} {
	    prefs::modified attachments($fset,$name)
	    unset attachments($fset,$name)
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::getAttachments" --
 # 
 # Return list of all attachments which can be turned on or off.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::getAttachments {} {
    
    variable infoTypes
    
    set items [list]
    foreach name [array names infoTypes] {
	# Get attachment type item from the group.
	if {([lindex $infoTypes($name) 0] ne "*")} {
	    lappend items $name
	}
    }
    return [lsort -dictionary -unique $items]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::getAttachmentItems" --
 # 
 # Return list of all attachment items (those which are always present and
 # those which can be turned on or off).
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::getAttachmentItems {} {
    
    variable infoTypes

    set items [list]
    foreach name [array names infoTypes] {
	# Get attachment type item from the group.
	set itemInfo $infoTypes($name)
	set groupItem [lindex $itemInfo 1]
	if {[llength $groupItem]} {
	    lappend items $groupItem
	}
	eval lappend items [lrange $itemInfo 2 end]
    }
    return $items
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::getInformation" --
 # 
 # Get the associated information 'infoName' for the given fileset, *if* it
 # is attached.  If it is not then an empty string will be returned.
 #  
 # If "infoName" is not recognised, an error is thrown.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::getInformation {fset infoName {groupName ""}} {
    
    variable infoStorage
    variable infoTypes
    
    if {($groupName eq "")} { 
	set groupName $infoName
    }
    if {([lindex $infoTypes($groupName) 0] eq "*")} {
        if {![info exists infoStorage($fset,$infoName)]} {
            # This should only happen if we create a fileset manually in Tcl
            # by filling in the various array entries.
            fileset::ensureAllInfoAttached [list $fset] [list]
        }
    } elseif {![fileset::isAttached $fset $groupName] \
      || ![info exists infoStorage($fset,$infoName)]} {
	return ""
    }
    return $infoStorage($fset,$infoName)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::_getInformation" --
 # 
 # Same as the public [fileset::getInformation] procedure, but always returns
 # the information, even if it isn't actually currently attached.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::_getInformation {fset infoName} {
    
    variable infoStorage
    
    if {![info exists infoStorage($fset,$infoName)]} {
	# This should only happen if we create a fileset manually in Tcl by
	# filling in the various array entries.
	fileset::ensureAllInfoAttached [list $fset] [list]
    }
    return $infoStorage($fset,$infoName)
}

proc fileset::setInformation {fset infoName value} {
    
    variable infoStorage
    variable infoTypes
    
    if {![info exists infoStorage($fset,$infoName)]} {
	set infoStorage($fset,$infoName) $value
	return
    } elseif {($infoStorage($fset,$infoName) eq $value)} {
	return
    }
    # If we're still here, we need to set and save the new value, and then
    # attempt to call any modification script which is associated with this
    # particular attachment.
    set infoStorage($fset,$infoName) $value
    prefs::modified infoStorage($fset,$infoName)
    # This first loop only fails for 'additional information'
    set got 0
    foreach group [array names infoTypes] {
	foreach item [lrange $infoTypes($group) 2 end] {
	    if {([lindex $item 0] eq $infoName)} {
		set modifiedScript [lindex $item 4]
		if {($modifiedScript ne "")} {
		    eval $modifiedScript [list $fset $value]
		}
		set got 1
		break
	    }
	}
	if {$got} {
	    break
	}
    }
    if {!$got} {
	# If it failed, do we need to look for the modified script elsewhere?
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::attachNewInformationGroup" --
 # 
 # Attach a group of pieces of information to a fileset.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::attachNewInformationGroup {groupName to help args} {
    
    variable infoTypes
    
    set infoTypes($groupName) [list $to [list $groupName "text" "" $help]]
    foreach itemlist $args {
	eval [list fileset::_attachNewInformation $groupName] $itemlist
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::attachNewInformation" --
 # 
 # If 'to' is '*' then this item is automatically attached to all filesets,
 # if not then each fileset may individually select whether to attach this
 # information or not.  This selection is done by the user, via the
 # 'Attach/Detach Info' button in the 'Edit A Fileset' dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::attachNewInformation {to infoType name {defaultValue ""} \
  {help ""} {modifiedScript ""}} {
    
    variable infoTypes
    
    set infoTypes($name) [list $to {}]
    fileset::_attachNewInformation $name $infoType $name $defaultValue \
      $help $modifiedScript
    return
}

proc fileset::_attachNewInformation {groupName infoType name \
  {defaultValue ""} {help ""} {modifiedScript ""}} {
    
    variable infoTypes
    variable infoStorage
    
    lappend infoTypes($groupName) [list $name $infoType\
      $defaultValue $help $modifiedScript]
    foreach fset [fileset::names] {
	if {![info exists infoStorage($fset,$name)]} {
	    set infoStorage($fset,$name) $defaultValue
	    if {[string length $modifiedScript]} {
		eval $modifiedScript [list $fset $defaultValue]
	    }
	}
    }
    return
}

proc fileset::ensureAllInfoAttached {fsets infoNames} {
    
    variable infoTypes
    variable infoStorage
    
    if {![llength $fsets]} {
	set fsets [fileset::names]
    }
    if {![llength $infoNames]} { 
	set groupNames [array names infoTypes] 
    }
    foreach groupName $groupNames {
	foreach group [lrange $infoTypes($groupName) 2 end] {
	    set infoName [lindex $group 0]
	    set defaultValue [lindex $group 2]
	    set modifiedScript [lindex $group 4]
	    foreach fset $fsets {
		if {![info exists infoStorage($fset,$infoName)]} {
		    set infoStorage($fset,$infoName) $defaultValue
		    if {($modifiedScript ne "")} {
			eval $modifiedScript [list $fset $defaultValue]
		    }
		}
	    }
	}
    }
    return
}

proc fileset::isAttached {fset name} {
    
    variable attachments
    
    if {[info exists attachments($fset,$name)]} {
	return $attachments($fset,$name)
    } else {
	return 0
    }
}

proc fileset::thoseWithInformation {infoName} {
    
    set results [list]
    foreach fset [fileset::names] {
	if {[fileset::isAttached $fset $infoName]} {
	    lappend results $fset
	}
    }
    return $results
}

proc fileset::informationAttached {fset} {
    
    variable infoTypes
    
    set results [list]
    foreach name [array names infoTypes] {
	set itemInfo $infoTypes($name)
	if {([lindex $itemInfo 0] eq "*") || [fileset::isAttached $fset $name]} {
	    # Add the rest of the items
	    set groupItem [lindex $itemInfo 1]
	    if {[llength $groupItem]} {
		lappend results $groupItem
	    }
	    eval lappend results [lrange $itemInfo 2 end]
	}
    }
    return $results
}

##
 # --------------------------------------------------------------------------
 #
 # "fileset::attachAdditionalInformation" --
 #
 # Attach a piece of information which is only shown to the user if the
 # fileset's $toInfoName has the current value $toVal.  Note, however, that
 # while the information is actually attached to all filesets, it is only
 # the visibility to the user that is adjusted.  It will be automatically
 # added to newly created filesets as well.
 #
 # Up to 7 arguments allowed, the first 4 are required:
 #
 #    toInfoName:       'original' fileset info that might be changed.
 #    toVal:            value that will trigger making this item visible.
 #    infoType:         type of info requested by new 'set' button.
 #    name:             name of variable, visible to user and used internally.
 #
 #    defaultValue:     will be "" if not supplied.
 #    help:             text used in balloon help.
 #    modifiedScript:   script to be evaluated when value changes.
 #
 # When this is called by the 'fileset-new' hook, an 8th argument is
 # supplied with the name of the fileset that was just created.
 #
 # Note: this proc should only be called once for any set of information, as
 # in during the init script of a particular package.
 #
 # --------------------------------------------------------------------------
 ##

proc fileset::attachAdditionalInformation {args} {

    if {[llength $args] < 4} {
	error "At least four arguments are required."
    }

    variable infoAdditionalTypes
    variable infoStorage

    # Set up variables that we will use to attach more info.
    set toInfoName      [lindex $args 0]
    set toVal           [lindex $args 1]
    set infoType        [lindex $args 2]
    set name	        [lindex $args 3]
    set defaultValue    [lindex $args 4]
    set help	        [lindex $args 5]
    set modifiedScript  [lindex $args 6]
    # Create the list of filesets to which we will attach more info.
    if {([set fset [lindex $args 7]] eq "")} {
	# Add this for all currently recognized filesets.
	set fsets [fileset::names]
	# The first time this is called (for this additional information),
	# make sure that we have appended the information to the
	# 'infoAdditionalTypes' array item.
	set aia [additionalInformationAttached "" $toInfoName $toVal]
	set ai  [list $name $infoType $defaultValue $help $modifiedScript]
	if {([lsearch $aia $ai] == -1)} {
	    lappend infoAdditionalTypes(${toInfoName},${toVal}) $ai
	}
	# Make sure we will attach this info for newly created filesets.
	hook::register fileset-new [list \
	  fileset::attachAdditionalInformation \
	  $toInfoName $toVal $infoType $name \
	  $defaultValue $help $modifiedScript ]
    } else {
	# Called by 'fileset-new' hook registered above.
	set fsets [list $fset]
    }
    # Add the additional information for specified filesets.
    foreach fset $fsets {
	if {[info exists infoStorage(${fset},${name})]} {
	    continue
	}
	set infoStorage(${fset},${name}) $defaultValue
	if {[string length $modifiedScript]} {
	    eval $modifiedScript [list $fset $defaultValue]
	}
    }
    return
}

proc fileset::additionalInformationAttached {fset infoName value} {
    
    variable infoAdditionalTypes
    
    if {[info exists infoAdditionalTypes($infoName,$value)]} {
	return $infoAdditionalTypes($infoName,$value)
    } else {
	return ""
    }
}

proc fileset::getAllAttachmentDialogItems {fset} {
    
    variable infoTypes
    
    set results [list]
    foreach name [array names infoTypes] {
	# Get attachment type item from the group
	set itemInfo $infoTypes($name)
	if {([lindex $itemInfo 0] eq "*") || [fileset::isAttached $fset $name]} {
	    set onOff 1
	} else {
	    set onOff 0
	}
	set items {}
	set groupItem [lindex $itemInfo 1]
	if {[llength $groupItem]} {
	    lappend items $groupItem
	}
	eval lappend items [lrange $itemInfo 2 end]
	foreach pair $items {
	    set name [lindex $pair 0]
	    set infoType [lindex $pair 1]
	    if {($infoType eq "text")} {
		set value ""
	    } else {
		set value [fileset::_getInformation $fset $name]
	    }
	    if {$onOff} {
		set type $infoType
	    } else {
		set type [list hidden $infoType]
	    }
	    lappend results [list $type $name $value [lindex $pair 3]]
	}
    }
    return $results
}

proc fileset::setAllAttachmentDialogItems {fset count results} {
    
    foreach pair [fileset::getAttachmentItems] {
	set name [lindex $pair 0]
	set infoType [lindex $pair 1]
	if {([lindex $infoType 0] eq "hidden")} {
	    set infoType [lrange $infoType 1 end]
	}
	if {($infoType eq "text")} {
	    continue
	}
	# Set the information whether the information is actually attached
	# ($on) or not, since the user may have edited it anyway.
	set oldValue [fileset::_getInformation $fset $name]
	set newValue [lindex $results $count]
	if {($newValue ne $oldValue)} {
	    fileset::setInformation $fset $name $newValue
	}
	incr count
    }
    return $count
}

proc fileset::getInfoDialogItems {fset} {
    
    set results [list]
    foreach pair [fileset::informationAttached $fset] {
	set name [lindex $pair 0]
	set infoType [lindex $pair 1]
	if {($infoType eq "text")} {
	    set value ""
	} else {
	    set value [fileset::_getInformation $fset $name]
	}
	lappend results [list $infoType $name $value [lindex $pair 3]]
	foreach additionalPair [fileset::additionalInformationAttached \
	  $fset $name $value] {
	    set name [lindex $additionalPair 0]
	    set infoType [lindex $additionalPair 1]
	    set value [fileset::_getInformation $fset $name]
	    lappend results [list $infoType $name $value \
	      [lindex $additionalPair 3]]
	}
    }
    return $results
}

proc fileset::setInfoFromDialog {fset count results} {
    
    foreach pair [fileset::informationAttached $fset] {
	set name [lindex $pair 0]
	set infoType [lindex $pair 1]
	if {($infoType eq "text")} {
	    continue
	}
	set oldValue [fileset::_getInformation $fset $name]
	set newValue [lindex $results $count]
	fileset::setInformation $fset $name $newValue
	incr count
	foreach additionalPair [fileset::additionalInformationAttached \
	  $fset $name $oldValue] {
	    set name [lindex $additionalPair 0]
	    set infoType [lindex $additionalPair 1]
	    set newValue [lindex $results $count]
	    fileset::setInformation $fset $name $newValue
	    incr count
	}
    }
    return $count
}

# ===========================================================================
# 
# .