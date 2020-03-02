## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "identities.tcl"
 #                                          created: 12/28/2005 {01:48:19 PM}
 #                                      last update: 01/13/2006 {02:06:29 PM}
 # Description:
 # 
 # Allows the user to enter basic information (name, e-mail, web-site, etc.)
 # that can be used by other AlphaTcl packages, especially those that create
 # templates in file windows.  The user can also define multiple identities.
 # All of this can be very handy for creating "electric" templates using
 # specific and current user information .
 # 
 # See [userInfo::developerHelp] below for more information.
 # 
 # Based on the "identity" preference originally found in "Docprojects.tcl", 
 # created by Vince Darley.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cbupright@earthlink.net>
 #    www: <http://home.earthlink.net/~cupright/>
 #   
 # Copyright (c) 2005-2006  Vince Darley, Craig Barton Upright
 # All rights reserved. 
 # 
 # Distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

# Auto-loading library declaration.
alpha::library identities "0.3" {
    userInfo::initializePackage
} maintainer {
    {Craig Barton Upright} <cbupright@earthlink.net>
} description {
    Allows you to enter personal information used by other packages to create
    better templates
} help {
    This package allows you to create multiple identities when using ÇALPHAÈ.
    Inspect the "Config > Preferences > Current Identity" menu for the
    commands which allow you to create new and edit current identities.
    These identities are used by other AlphaTcl features to create window
    templates, such as the package: documentProjects .
    
    Click on this hyperlink:
    
    <<userInfo::identityDialog "edit">>
    
    to change the settings for your current identity.
    
    Click on this hyperlink:
    
    <<userInfo::identityDialog "new">>
    
    to create a new identity.  Once you have defined multiple identities, the
    current one is marked in the "Config > Preferences > Current Identity"
    menu.  Selecting a different identity will make that one current.
    
    You don't need to suffer from any multiple personality disorder in order
    to make use of multiple identities.  You might use the same author name,
    but work on projects for different organisations, with different e-mail
    addresses or contact information...
    
    Note: There always exists one "Default" identity; you can edit its values
    but you cannot delete it.  The items in the Default identity are used as
    the initial values for any new identity.

	----------------------------------------------------------------
    
    This feature was designed to make it easier for other AlphaTcl packages
    share information amongst each other, such as the name of the current
    project defined by the package: documentProjects, or the path/name of the
    active window.  This information is often used in electric templates.
    Click here

    <<listpick [userInfo::listFields "all"]>>

    to see what is currently available.
    
    AlphaTcl developers can click here: <<userInfo::developerHelp>> for more
    information about how to use this package in their own code.
}

proc identities.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval userInfo" --
 # 
 # Define any variables required when sourcing this file.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval userInfo {
    
    variable initialized
    if {![info exists initialized]} {
	set initialized "-1"
    }
    # Standard identity fields ensured by this package.
    variable identityFields [list "author" "organisation" "address" \
      "email" "www" "author_initials"]
    # Names that the user cannot use for new identities.
    variable reservedNames [list "Usual" "Default" "identity"]
    
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::initializePackage" --
 # 
 # Define all variables and preferences required to make this package work.
 # 
 # The "identities" array includes an entry for each identity.  Each value in
 # this array is even-numbered list, as in
 # 
 #     author "Craig Barton Upright" email cupright@stthomas.edu ...
 # 
 # Use some form of [array set <varName> $identities(Default)] to create easy
 # access to the values.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::initializePackage {} {
    
    global identity identities synchroniseInternetPrefsWithSystem
    
    variable identityFields
    variable initialized
    
    if {($initialized eq "1")} {
	return
    }
    
    # Variables.
    
    # Earlier versions had a "Usual" identity instead of a "Default" one.
    prefs::renameOld identities(Usual) identities(Default)
    
    # Make sure that we have a "Default" identity.
    if {![info exists identities(Default)]} {
	# None exists, so we'll try to create it using whatever information
	# we have available.  Note that until the user actually edits the
	# information, "identities(Default)" will _not_ be saved in Alpha's
	# preferences, so any System changes will be reflected here.
	if {$::synchroniseInternetPrefsWithSystem} {
	    catch {set usualInfo(author)         [icGetPref RealName]}
	    catch {set usualInfo(email)          [icGetPref Email]}
	    catch {set usualInfo(www)            [icGetPref WWWHomePage]}
	    catch {set usualInfo(organisation)   [icGetPref Organization]}
	} 
	foreach item $identityFields {
	    if {![info exists usualInfo($item)]} {
		set usualInfo($item) ""
	    } 
	}
	if {($usualInfo(author_initials) eq "")} {
	    set initials ""
	    regsub -all {\s+} $usualInfo(author) { } authorString
	    foreach initial [split $authorString " "] {
		append initials [string index $initial 0]
	    }
	    set usualInfo(author_initials) $initials
	} 
	set identities(Default) [array get usualInfo]
    }
    
    # Define preferences.
    
    # Different identities can be useful if your projects may be sometimes
    # for work purposes, sometimes for your own purposes etc.
    newPref var identity Default "global" {userInfo::changeIdentity} \
      identities "array"
    if {![info exists identities($identity)]} {
	set identity "Default"
    }
    
    # Make sure that "user" is defined.
    userInfo::changeIdentity
    
    # An example of adding extra user information.
    userInfo::addInfo "year" [clock format [clock seconds] -format "%Y"]
    # Adds additional information about the active window.
    hook::register activateHook {userInfo::activateHook}
    
    # Define the new "Config > Preferences > Current Identity" menu, and
    # insert it.
    menu::buildProc "Current Identity" {userInfo::buildMenu} \
      {userInfo::postBuildMenu}
    menu::insert preferences submenu "(-)" {Current Identity}
    
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::activateHook" --
 # 
 # Add extra "userInfo" fields for the tail and path of the active window.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::activateHook {window} {
    
    userInfo::addInfo "tail" [win::Tail [win::StripCount $window]]
    userInfo::addInfo "path" [win::StripCount $window]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::listIdentities" --
 # 
 # List all identities.  The "Default" identity always exists, but some
 # procedures don't want to include it in the list because it cannot be
 # deleted.  The "includeDefault" argument determines if it is included, and if
 # so, where.  Menu and dialog dividers can be used to separate it from the
 # other items.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::listIdentities {{includeDefault 0}} {
    
    global identities
    
    set idList [lsort -dictionary [array names identities]]
    set idList [lremove $idList [list "Default"]]
    if {($includeDefault != 0)} {
	if {![llength $idList]} {
	    return [list "Default"]
	}
	switch -- $includeDefault {
	    "-3" {
		set idList [linsert $idList 0 "Default" "(-)"]
	    }
	    "-2" {
		set idList [linsert $idList 0 "Default" "-"]
	    }
	    "-1" {
		set idList [linsert $idList 0 "Default"]
	    }
	    "1" {
		set idList [linsert $idList end "Default"]
	    }
	    "2" {
		set idList [linsert $idList end "-" "Default"]
	    }
	    "3" {
		set idList [linsert $idList end "(-)" "Default"]
	    }
	}
    }
    return $idList
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::defaultFields" --
 # 
 # Return the list of fields defined by this package for each separate
 # identity.  Options include
 # 
 #     "user"   -- Only those identity fields defined for this package.
 #     "extra"  -- Fields added by other AlphaTcl code.
 #     "all"    -- Both "user" and "extra" fields.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::listFields {{type "all"}} {
    
    variable extraFields
    variable identityFields
    
    set fieldList [list]
    switch -- $type {
	"all" {
	    set fieldList [concat $identityFields [array names extraFields]]
	}
	"user" {
	    set fieldList $identityFields
	}
	"extra" {
	    set fieldList [array names extraFields]
	}
	default {
	    error "Unknown listing option: \"$type\""
	}
    }
    return [lsort -dictionary $fieldList]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::buildMenu" --
 # 
 # Build the "Config > Preferences > Current Identity" menu.  Because the 
 # user's identities are included, all items are "prettified."
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::buildMenu {} {
    
    global identities identity
    
    set menuList [userInfo::listIdentities "-3"]
    lappend menuList "(-)" "Add New IdentityÉ" "Edit IdentityÉ" \
      "Rename IdentityÉ" "Remove IdentityÉ" "(-)" "Identities Help"
    
    return [list "build" $menuList {userInfo::menuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::postBuildMenu" --
 # 
 # Dim/enable or mark any relevant items in the "Current Identity" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::postBuildMenu {} {
    
    global identities identity
    
    set dim [expr {([llength [userInfo::listIdentities 0]] > 0) ? 1 : 0}]
    enableMenuItem -m "Current Identity" "Rename IdentityÉ" $dim
    enableMenuItem -m "Current Identity" "Remove IdentityÉ" $dim
    foreach id [userInfo::listIdentities 1] {
	set markItem [expr {($id eq $identity) ? 1 : 0}]
	markMenuItem -m "Current Identity" $id $markItem "¥"
    } 
    
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::menuProc" --
 # 
 # Deal with all menu items.  If the item is the name of an identity, then
 # that one is made current.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::menuProc {menuName itemName} {
    
    global identities identity
    
    if {([lsearch -exact [userInfo::listIdentities 1] $itemName] > -1)} {
	userInfo::changeIdentity $itemName
	status::msg "Your new identity is \"$itemName\""
	return
    }
    switch -- $itemName {
	"Add New Identity" {
	    userInfo::identityDialog "new"
	    status::msg "Your new identity is \"$identity\""
	}
	"Edit Identity" {
	    userInfo::identityDialog "edit"
	    status::msg "Changes have been saved."
	}
	"Rename Identity" {
	    set options [userInfo::listIdentities 0]
	    switch -- [llength $options] {
		"0" {
		    # This menu command should have been dimmed.
		    userInfo::postBuildMenu
		    error "Cancelled -- there are no identities to rename."
		}
		"1" {
		    set q "Rename the \"[lindex $options 0]\" identity?"
		    if {[askyesno $q]} {
			set oldId [lindex $options 0]
		    } else {
			error "cancel"
		    }
		}
		default {
		    set p "Rename which identity?"
		    set oldId [listpick -p $p $options]
		}
	    }
	    set newId ""
	    while {1} {
		set newId [prompt "New name:" $oldId]
		if {([string trim $newId] eq "")} {
		    alertnote "The name cannot be an empty string!"
		} else {
		    break
		}
	    }
	    if {($oldId eq $newId)} {
		status::msg "No changes."
	    } else {
		set identities($newId) $identities($oldId)
		prefs::modified identities($newId) identities($oldId)
		unset identities($oldId)
		menu::buildSome "Current Identity"
		if {($identity eq $oldId)} {
		    set identity $newId
		    userInfo::changeIdentity $newId
		}
		status::msg "The \"$oldId\" identity has been renamed\
		  to \"$newId\"."
	    }
	    set q "Would you like to rename another identity?"
	    if {([llength $options] > 1) && [askyesno $q]} {
		userInfo::menuProc $menuName $itemName
	    }
	}
	"Remove Identity" {
	    set options [userInfo::listIdentities 0]
	    switch -- [llength $options] {
		"0" {
		    # This menu command should have been dimmed.
		    userInfo::postBuildMenu
		    error "Cancelled -- there are no identities to remove."
		}
		"1" {
		    set q "Remove the \"[lindex $options 0]\" identity?"
		    if {[askyesno $q]} {
			set removeList $options
		    } else {
			error "cancel"
		    }
		}
		default {
		    set p "Remove which identity?"
		    set removeList [listpick -p $p -l $options]
		}
	    }
	    foreach id $removeList {
		prefs::modified identities($id)
		unset identities($id)
		if {($id eq $identity)} {
		    set identity "Default"
		}
	    }
	    menu::buildSome "Current Identity"
	    if {([llength $removeList] == 1)} {
		set msg "The identity \"[lindex $removeList 0]\" has"
	    } else {
		set msg "The identities \"[join $removeList ", "]\" have"
	    }
	    status::msg [append msg " been removed."]
	}
	"Identities Help" {
	    package::helpWindow "identities"
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::identityDialog" --
 # 
 # Present a dialog for the user to either create a new identity or edit
 # existing ones.  "which" should be one of "new" or "edit".  This will
 # always reset the "user" array to reflect changes.  Returns the names of
 # all identities that were potentially modified.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::identityDialog {which} {
    
    global identities identity
    
    variable identityFields
    variable reservedNames
    
    if {($which eq "new")} {
	set title "Create A New Identity"
	while {1} {
	    set newName [prompt "New Identity Name:" ""]
	    if {([string trim $newName] eq "")} {
		alertnote "The name cannot be an empty string!"
	    } elseif {([lsearch $reservedNames $newName] > -1)} {
		alertnote "Sorry, \"$newName\" is a reserved name,\
		  and cannot be used for an identity."
	    } else {
		break
	    }
	}
    } elseif {($which eq "edit")} {
	set title "Edit All Identities"
    } else {
	error "Unknown option: $which"
    }
    # Create the initial dialog script.
    set dialogScript [list dialog::make -title $title -width 450 \
      -addbuttons [list \
      "Help" \
      "Click this button for more help" \
      "help::openGeneral identities {} ; \
      set retCode 1 ; set retVal {cancel}" \
      ]]
    # Now we either add a single dialog pane, or all available.
    if {($which eq "new")} {
	# Use the "Default" identity for the default field values.
	set idNames [list "Default"]
    } else {
	set idNames [userInfo::listIdentities "-1"]
    }
    foreach id $idNames {
	array set idInfo $identities($id)
	if {[info exists newName]} {
	    set paneName "New \"$newName\" Identity"
	} elseif {($id eq "Default")} {
	    set paneName "Default Identity"
	} else {
	    set paneName "\"$id\""
	}
	set dialogPane [list $paneName \
	  [list "var" "Author:"         $idInfo(author)] \
	  [list "var" "Organisation:"   $idInfo(organisation)] \
	  [list "var2" "Address:"       $idInfo(address)] \
	  [list "var" "E-mail:"         $idInfo(email)] \
	  [list "var" "Web Site:"       $idInfo(www)] \
	  [list "var" "Initials:"       $idInfo(author_initials)] \
	  ]
	lappend dialogScript $dialogPane
    } 
    set results [eval $dialogScript]
    if {($which eq "new")} {
	for {set i 0} {($i < [llength $identityFields])} {incr i} {
	    lappend newInfo [lindex $identityFields $i] [lindex $results $i]
	}
	set identities($newName) $newInfo
	prefs::modified identities($newName)
	set identity $newName
	menu::buildSome "Current Identity"
	set result $newName
    } else {
	set idx 0
	foreach id $idNames {
	    set newInfo [list]
	    for {set i 0} {($i < [llength $identityFields])} {incr i} {
		set field [lindex $identityFields $i]
		set value [lindex $results $idx]
		lappend newInfo $field $value
		incr idx
	    }
	    set identities($id) $newInfo
	    prefs::modified identities($id)
	} 
	set result $idNames
    }
    # Make sure that everything is updated.
    userInfo::changeIdentity
    return $result
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::changeIdentity" --
 # 
 # Update the "user" array.  This is called when the user changes the
 # "identity" preference through a standard prefs dialog, and also "manually"
 # by other code in this file.  This is the only time that this library sets
 # the global "user" array.  The preferred method for obtaining information
 # about the user's settings is [userInfo::getInfo].
 # 
 # If "prefName" is the name of the "identity" preference, then the new 
 # identity has already been set.  Otherwise we attempt to set the identity 
 # to this new value.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::changeIdentity {{prefName ""}} {
    
    global identities identity user
    
    if {($prefName ne "") && ($prefName ne "identity")} {
	if {([lsearch [userInfo::listIdentities] $prefName] > -1)} {
	    set identity $prefName
	    prefs::modified identity
	    userInfo::postBuildMenu
	} else {
	    error "Unknown identity: \"$prefName\""
	} 
    }
    if {![info exists identities($identity)]} {
	set identity "Default"
    }
    array set user $identities($identity)
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::getInfo" --
 # 
 # Returns information about one of the default fields for the current
 # identity.  If the field is in the "identityFields" list then we return
 # information set by the user for the Current Identity.  Otherwise, we check
 # to see if the field was set by other code using [userInfo::addInfo].
 # 
 # If the given field value doesn't exist, or if it is the null string, the
 # optional "defaultValue" argument will be returned.
 # 
 # "identity" is an allowed field, provided for convenience so that outside
 # code can find out the name of the current identity without needing to know
 # how this information is stored.
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::getInfo {field {defaultValue ""}} {
    
    global identities identity
    
    variable extraFields
    variable identityFields
    
    if {($field eq "identity")} {
        return $identity
    }
    if {([lsearch -exact $identityFields $field] > -1)} {
	array set currentInfo $identities($identity)
	set value $currentInfo($field)
	if {($field eq "email") || ($field eq "www")} {
	    set value [string trimleft  $value "<"]
	    set value [string trimright $value ">"]
	    set value [string trim $value]
	}
    } elseif {[info exists extraFields($field)]} {
	set value $extraFields($field)
    } else {
	set value ""
    }
    if {($value ne "")} {
	return $value
    } else {
	return $defaultValue
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::addInfo" --
 # 
 # Add user information that can be later obtained by any other package using
 # [userInfo::getInfo].  Fields in the "identityFields" list, however, can
 # only be set by the user.
 # 
 # --------------------------------------------------------------------------
 ##
proc userInfo::addInfo {field value} {
    
    variable extraFields
    variable identityFields
    
    if {([lsearch -exact $identityFields $field] > -1)} {
	error "\"$field\" is a reserved field, and cannot be changed."
    } 
    set extraFields($field) $value
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "userInfo::developerHelp" --
 # 
 # Open a new window with more information for fellow developers to find out
 # just how useful this package can be...
 # 
 # --------------------------------------------------------------------------
 ##

proc userInfo::developerHelp {} {
    
    set title "Identities -- Developer Help"
    if {[win::Exists $title]} {
	bringToFront $title
	return
    }

    set txt {
Identities -- Developer Help

This [alpha::library] feature is part of the AlphaTcl SystemCode, and so long
as it is installed it will be available to all other AlphaTcl procedures.
(The user will never be offered this package in the list of those which can
be uninstalled.)  It creates the "Config > Preferences > Current Identity"
submenu, allowing the user to define "Default" identity information, and to
create new identities.  Source code is in the "identities.tcl" file.

The proc: userInfo::getInfo is the preferred method for obtaining user
information, specifying one of the six default fields:

	author
	organisation
	address
	email
	www
	author_initials

When the user adjusts the Current Identity using the "Config > Preferences"
submenu, this will automatically update [userInfo::getInfo] results.  Note
that both the "email" and "www" fields will always be returned _without_ any
angle brackets, even if the user included them in the preference values.

This library also makes it easier for different packages to add their own
"user information" fields beyond those listed above, information that a third
package might want to use, by using the proc: userInfo::addInfo .  

For example, the package: documentProjects will define a "license owner" or
"license organisation" related to the user's current project, and these could
be used by to insert user-specific license templates into the active window
by the package: electricMenu .  This could be done with

	userInfo::addInfo "owner_org" "Princeton University"

The code which creates the template could then use

	userInfo::getInfo "owner_org" [userInfo::getInfo "organisation"]

to obtain this information, defaulting to the primary "organisation" defined
by the user's identity.  Using this protocol, the license template procedure
doesn't need to be aware of the activation of "documentProjects" and simply
accepts whatever information is available.  This allows AlphaTcl packages to
be more agnostic about the existence of their brethren, reducing package
dependencies and the need to constantly rename procedures in order to ensure
that the proper information is passed back and forth among them.  As an 
example, this "identities" library defines a new "year" field:

<<alertnote [userInfo::getInfo "year" "None defined!"]>>

This "year" field will always be available, by the way, as will the "tail"
of the active window and its "path".  Click here

<<listpick [userInfo::listFields "all"]>>

to see what is currently available.

Three global variables are created by this package:

  "identity"         -- the name of the Current Identity
  "identities"       -- an array of all identity information
  "user"             -- an array of Current Identity information.

These variables should, however, be considered internal to this package.
The "user" array is still maintained only for back compatibility.  Again, 
only the procedures

	userInfo::getInfo
	userInfo::addInfo

should be called outside of the "identities.tcl" file.
}
    new -n $title -tabsize 4 -info $txt
    help::markColourAndHyper
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 12/28/05 cbu 0.1    Original
# 12/29/05 cbu 0.2    Changed "Usual" identity to "Default".
#                     Ensure that new identities don't use reserved names.
#                     New [userInfo::addInfo] allows any AlphaTcl code to
#                       set some information that can be later obtained by
#                       other code using [userInfo::getInfo].
#                     New [userInfo::developerHelp] for more information.
#                     Strip <angle brackets> in [userInfo::getInfo].
# 01/02/06 cbu 0.3    New [userInfo::listFields] procedure.
#                     [userInfo::getInfo] accepts "identity" field.
#                     [userInfo::changeIdentity] accepts an identity arg.
# 01/02/06 cbu 0.3.1  "tail" and "path" are always defined as fields.
#                     New [userInfo::activateHook] ensures these are set.
# 

# ===========================================================================
# 
# .