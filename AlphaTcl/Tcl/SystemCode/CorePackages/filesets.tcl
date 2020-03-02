## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "filesets.tcl"
 #                                          created: 07/20/1996 {06:22:25 pm}
 #                                      last update: 04/01/2006 {04:26:18 PM}
 # Description:
 # 
 # This file, and the interfaces it contains are undergoing some development.
 # The APIs may undergo minor changes in the future, as we learn more about
 # how users want to interact with filesets.
 # 
 # Code contributions and suggestions are very welcome.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # ==========================================================================
 ##

alpha::extension filesets 2.1b1 {
    # Ensure this file is sourced, and that our defaults and preferences are 
    # properly defined.
    fileset::initializeFilesets
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Provides the internal "filesets" support used by other packages
} help {
    file "Filesets Help"
}

proc filesets.tcl {} {}

# ×××× Filesets API ×××× #

# A fileset has a few key properties:
# 
# (i) a name
# (ii) a way of testing whether any given file is in that fileset
# (iii) a way of listing all files in the fileset
# (iv) a 'basic type', which is currently any of: 
# 'list'
# 'procedural'
# 'glob'
# 'fromHierarchy'
# 
# It may also have any number of other properties, usually added by
# other packages.  For instance, the filesets menu will add a flag
# declaring whether a fileset is shown in the menu.

## 
 # To add a new fileset type, you need to define the following:
 #	   fileset::registerNewType myType "list"
 #	   proc	fileset::myType::create {} {}
 #	   proc	fileset::myType::updateContents {name {andMenu 0}} {}
 # 
 # For more complex types (e.g. the tex-type), also define:
 #	   proc	fileset::myType::selected {fset menu item } {}
 #	   proc	fileset::myType::listFiles {name} {}
 # 
 # For filesets you want to make easily editable via the 'editFilesets'
 # dialog, you must also define:
 #	   proc	fileset::myType::getDialogItems {name} {}
 #	   proc	fileset::myType::setDetails {name args} {}
 # 
 # These procedures will all be called automatically under the correct
 # circumstances.  The purposes of these are as follows:
 #
 #   'create'   -- query the user for name etc. and create
 #   'updateContents'   -- given the information in 'gfileSets', recalculate
 #				   the member files.
 #   'selected' -- a member was selected in a menu.
 #   'listFiles'     -- given info in all except 'fileSets', return list
 #                 of files to be stored in that variable.
 #   'makeFileSetAndMenu'  -- generate the sub-menu
 # 
 # Your code may wish to call 'isWindowInFileset ?win?  ?type?'  to
 # check if a given (current by default) window is in a fileset of a
 # given type.
 ##


namespace eval fileset {
    
    # Used by [fileset::initializeFilesets]
    variable filesetsInitialized
    if {![info exists filesetsInitialized]} {
        set filesetsInitialized 0
    }
    variable storedVersion
    if {![info exists storedVersion]} {
	set storedVersion "0.0"
    } elseif {[regexp {^[0-9]$} $storedVersion]} {
	set storedVersion [expr ceil($storedVersion)]
	prefs::modified storedVersion
    }
}

proc fileset::initializeFilesets {} {
    
    global HOME alpha::macos \
      gfileSets gfileSetsType fileSetsExtra currFileSet filesetUtils
      
    
    variable filesetsInitialized
    variable notChangeable
    variable storedVersion
    
    if {$filesetsInitialized} {
        return
    }
    
    # The value that our current "storedVersion" variable should be.
    set currentVersion [alpha::package versions "filesets"]
    # Ensure that the stored version of fileset data is up to date, updating
    # the preferences as necessary based upon the "storedVersion" variable
    # either set above or saved in the user's preferences.
    if {![alpha::package vsatisfies -loose $storedVersion "2.0"]} {
	foreach fset [array names gfileSets] {
	    set old  $gfileSets($fset)
	    set type $gfileSetsType($fset)
	    switch -- $type {
		"fromDirectory" -
		"recurseIn" {
		    set gfileSets($fset) [list [file dirname $old] [file tail $old]]
		    prefs::modified gfileSets($fset)
		}
		"fromHierarchy" {
		    set gfileSets($fset) [list [file dirname [lindex $old 0]] \
		      [file tail [lindex $old 0]] [lindex $old 1]]
		    prefs::modified gfileSets($fset)
		}
		"tex" {
		    set gfileSets($fset) [list $old]
		    prefs::modified gfileSets($fset)
		}
	    }
	}
    }
    if {![alpha::package vsatisfies -loose $storedVersion "2.1b1"]} {
	foreach fset [array names gfileSets] {
	    if {($gfileSetsType($fset) eq "fromOpenWindows")} {
		set fileSetsExtra($fset) "created"
		prefs::modified fileSetsExtra($fset)
	    }
	}
    }
    # We'll save the new "storedVersion" variable if necessary.
    if {([alpha::package vcompare $storedVersion $currentVersion] < 0)} {
	set storedVersion $currentVersion
	prefs::modified storedVersion
    }
    # Fix possible changed home.  Note: all filesets must ensure that these
    # two variables contain valid lists.
    prefs::updateHome gfileSets "list"
    prefs::updateHome fileSets  "list"

    # Build some filesets on the fly.
    set gfileSets(Help) [list [file join $HOME Help] * 3]
    set fileSetsExtra(Help) [list *.pdf *.gif *.png CVS]
    # Declare their types
    set gfileSetsType(Help) "fromHierarchy"
    
    fileset::registerProcedural "Open Windows" \
      {fileset::listOpenWindowsFiles}
    fileset::registerProcedural "Top Window's Folder" \
      {fileset::listWindowDirectoryFiles}
    fileset::registerProcedural "Top Window's Hierarchy" \
      {fileset::listWindowHierarchyFiles}
    fileset::registerProcedural "Recurse in folderÉ" \
      {fileset::listRecurseDirectoryFiles}

    # The current fileset is used as a default for some actions.  It may also
    # be updated automatically to reflect the user's most recent fileset-menu
    # selection.
    if {![info exists currFileSet]} {
        set currFileSet "Top Window's Folder"
    }
    prefs::modified currFileSet

    if {$alpha::macos} {
	# To allow filesets to contain files not marked as text (which Alpha
	# will ask the system to open, when selected from any menu), turn
	# this item on||To disallow filesets from containing non-text files,
	# turn this item off.
	newPref flag includeNonTextFiles 1 "fileset" filesetMenu::rebuildSome
    }
    newPref flag includeHiddenFilesInBuiltInFilesets 0 "fileset"

    # A type is a means of prompting the user and characterising the
    # interface to a type, even though the actual storage may be very simple
    # (a list in most cases).
    fileset::registerNewType fromDirectory      "glob"
    fileset::registerNewType fromHierarchy      "fromHierarchy"
    fileset::registerNewType fromOpenWindows    "list"
    fileset::registerNewType fromFileList       "list"
    fileset::registerNewType procedural         "procedural"
    fileset::registerNewType recurseIn          "procedural"

    lunion notChangeable "Open Windows" "Top Window's Folder" \
      "Top Window's Hierarchy" "Recurse in folderÉ"
    
    # Register utilities.
    array set filesetUtils [list \
      "browseFilesetÉ"          [list * browseFileset] \
      "renameFilesetÉ"          [list * renameFileset] \
      "duplicateFilesetÉ"       [list * duplicateFileset] \
      "openEntireFilesetÉ"      [list * openEntireFileset] \
      "closeEntireFilesetÉ"     [list * closeEntireFileset] \
      "replaceInFilesetÉ"       [list * replaceInFileset] \
      "stuffFilesetÉ"           [list * stuffFileset] \
      "wordCountÉ"              [list * wordCountFileset] \
      "openFilesetFolderÉ"      [list * openFilesetFolder] \
      "zipFilesetÉ"             [list * zipFileset] \
      "listNewFilesÉ"           [list * listNewFilesFromFileset] \
      ]
    if {$alpha::macos} {
	set filesetUtils(filesetToAlphaÉ) [list * filesetToAlpha]
    }

    # Make sure our preferences are ok.
    foreach fset [array names gfileSets] {
	if {![info exists gfileSetsType($fset)]} {
	    lappend fsetErrors $fset
	    prefs::modified gfileSets($fset)
	    unset gfileSets($fset)
	}
    }
    if {[info exists fsetErrors]} {
	alertnote "[join $fsetErrors {, }] filesets were corrupted, and have\
	  been removed"
    }
    # Register hooks.
    hook::register preOpeningHook {fileset::checkOpeningPreference}
    hook::register quitHook       {fileset::temporaryCleanup}
    set filesetsInitialized 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::names" --
 # 
 # List all currently registered filesets.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::names {} {
    global gfileSets
    return [lsort -dictionary [array names gfileSets]]
}

proc fileset::exists {fset} {
    global gfileSets
    return [info exists gfileSets($fset)]
}

proc fileset::type {fset} {
    global gfileSetsType
    return $gfileSetsType($fset)
}

## 
 # -------------------------------------------------------------------------
 # 
 # "fileset::registerNewType" --
 # 
 #  Add a new type of fileset to the list of known types.  Having
 #  called this procedure, Alpha will automatically know how to interact
 #  with the new fileset type, provided it fulfills the fileset API.
 #  
 #  This requires the existence of the procs:
 #  
 #    'fileset::$type::create'
 #    'fileset::$type::updateContents'
 #    
 #  Note that the namespace 'fileset::$type' is automatically created
 #  by this procedure.
 #  
 #  Filesets which you want to make editable in the 'Edit Filesets' 
 #  dialog must also define the procs
 #  
 #	   proc	fileset::$type::getDialogItems {name}
 #	   proc	fileset::$type::setDetails {name args}
 #  
 # -------------------------------------------------------------------------
 ##
proc fileset::registerNewType {type kind} {
    global fileset::typeKindMap
    set fileset::typeKindMap($type) $kind
    # Make sure this namespace exists
    namespace eval ::fileset::$type {}
}


## 
 # -------------------------------------------------------------------------
 # 
 # "fileset::listTypes" --
 # 
 #  Return sorted list of all fileset types currently registered.  This
 #  is used, for example, when creating a new fileset, so that we may
 #  ask the user to select the type of fileset they wish to create.
 # -------------------------------------------------------------------------
 ##
proc fileset::listTypes {} {
    global fileset::typeKindMap
    lsort -dictionary [array names fileset::typeKindMap]
}

proc fileset::getKind {type} {
    global fileset::typeKindMap
    set fileset::typeKindMap($type)
}

proc fileset::getKindFromFset {fset} {
    global gfileSetsType fileset::typeKindMap
    set fileset::typeKindMap($gfileSetsType($fset))
}

proc fileset::checkOpeningPreference {name} {
    if {[hook::anythingRegistered fileset-file-opening]} {
	set fset [fileset::findForFile $name]
	if {[string length $fset]} {
	    hook::callAll fileset-file-opening * $fset $name
	}
    }
}

proc fileset::checkCurrent {{win ""}} {
    return [fileset::findForFile $win]
}

proc fileset::relativePath {{win ""}} {
    if {$win == ""} {set win [win::Current]}
    set fset [fileset::findForFile $win]
    set root [fileset::getBaseDirectory $fset]
    if {[string length $root] && [file::pathStartsWith $win $root relative]} {
	return $relative
    } else {
	error "Not relative"
    }
}

proc fileset::canEdit {fset} {
    global gfileSetsType
    set type $gfileSetsType($fset)
    if {($type eq "procedural")} {
	return -1
    }
    if {[llength [info commands ::fileset::${type}::getDialogItems]]} {
	return 1
    } else {
	return [auto_load ::fileset::${type}::getDialogItems]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "fileset::getBaseDirectory" --
 # 
 #  Return the base directory for the files in this fileset, if possible,
 #  otherwise the empty string.  Many fileset types are basically defined
 #  as being either all or some files inside a given directory; in such
 #  cases this procedure will return that directory.  The fileset type
 #  must have its 'getRoot' command defined.
 # -------------------------------------------------------------------------
 ##
proc fileset::getBaseDirectory {fset} {
    global gfileSetsType
    
    set cmd ::fileset::$gfileSetsType($fset)::getRoot

    if {[llength [info commands $cmd]] || [auto_load $cmd]} {
	return [$cmd $fset]
    } else {
	return ""
    }
}

proc fileset::registerProcedural {name proc} {
    
    global gfileSets gfileSetsType
    
    set gfileSets($name) $proc
    set gfileSetsType($name) "procedural"
}

# ×××× Basic procedures ×××× #

proc editFilesets {} {
    global alpha::application currFileSet gfileSets 

    if {![array size gfileSets]} {
	status::msg "There are no filesets currently defined"
	return
    }

    # Determine the need for attachments (true except in really minimal
    # AlphaTcl users)
    set items [fileset::getAttachments]
    if {[llength $items]} {
	set addbuttons [list -addbuttons [list "Attach/Detach InfoÉ" \
	  "Click here to adjust optional additional settings for this fileset" \
	  [list fileset::chooseAttachments]]]
	foreach fset [array names gfileSets] {
	    foreach item $items {
		set attached($fset,$item) [fileset::isAttached $fset $item]
	    }
	}
    } else {
	set addbuttons {}
    }
    # If we support a more user-friendly style of multi-page dialog with a
    # listbox to select the right page, activate that here.
    set newDialogCode [alpha::package vsatisfies -loose \
      [dialog::coreVersion] 2.0]
    # Used to build up the items in the dialog
    set dialog {}
    # Used to store the original values of each fileset entry
    set values {}
    # Create a page for each editable fileset
    foreach fset [lsort -dictionary [array names gfileSets]] {
	if {([set canEdit [fileset::canEdit $fset]] < 0)} {
	    continue
	}
	set page [list $fset]
	if {$newDialogCode} {
	    lappend page [list "text" "\"${fset}\" Fileset Settings\r"] \
	      [list "divider" "divider"] [list "text" "\r"]
	}
	if {$canEdit} {
	    set thisfset_items \
	      [fileset::[fileset::type $fset]::getDialogItems $fset]
	    eval lappend page $thisfset_items
	    # Store a list of the current values
	    set vals [list]
	    foreach item $thisfset_items {
		lappend vals [lindex $item 2]
	    }
	    lappend values $vals 
	}
	#eval lappend page [fileset::getInfoDialogItems $fset]
	eval lappend page [fileset::getAllAttachmentDialogItems $fset]
	lappend dialog $page
    }
    set width 450
    if {$newDialogCode} {
	set options [list -pager "listbox" -width [incr width 125]]
    } else {
	set options [list -width $width]
    }
    set res [eval [list dialog::make \
      -title "Edit $alpha::application Filesets" \
      -defaultpage $currFileSet] $options $addbuttons $dialog]
    # Now set everything
    set stored_index 0
    foreach fset [lsort -dictionary [array names gfileSets]] {
	if {([set canEdit [fileset::canEdit $fset]] < 0)} {
	    continue
	}
	set count 0
	if {$canEdit} {
	    set vals [lindex $values $stored_index]
	    set count [llength $vals]
	    for {set i 0} {$i < $count} {incr i} {
		if {[lindex $vals $i] ne [lindex $res $i]} {
		    # Only call the 'setDetails' proc if the fileset has changed.
		    status::msg "Updating fileset $fset"
		    eval [list fileset::[fileset::type $fset]::setDetails $fset] \
		      [lrange $res 0 [expr {$count -1}]]
		    updateAFileset $fset
		    break
		}
	    }
	    incr stored_index
	}
	set count [fileset::setAllAttachmentDialogItems $fset $count $res]
	set res [lrange $res $count end]
	fileset::synchroniseAttachments $fset
    }
    status::msg "Fileset changes complete"
}

proc editAFileset {{fset ""}} {
    if {[catch {pickFileset $fset "Edit which fileset?" editable} fset]} {return}
    
    # Determine the need for attachments (true except in really minimal
    # AlphaTcl users)
    set items [fileset::getAttachments]
    if {[llength $items]} {
	set addbuttons [list -addbuttons [list "Attach/Detach InfoÉ" \
	  "Click here to adjust optional additional settings for this fileset" \
	  [list fileset::chooseAttachments]]]
	foreach item $items {
	    set attached($fset,$item) [fileset::isAttached $fset $item]
	}
    } else {
	set addbuttons {}
    }

    set thisfset_items [fileset::[fileset::type $fset]::getDialogItems $fset]
    # Store a list of the current values
    set vals [list]
    foreach item $thisfset_items {
	lappend vals [lindex $item 2]
    }
    
    # Build the page
    set page [concat [list $fset] $thisfset_items \
      [fileset::getAllAttachmentDialogItems $fset]]

    set res [eval [list dialog::make -title "Edit '$fset' fileset"] \
      $addbuttons [list $page]]
    
    # Now set everything
    set count [llength $vals]
    for {set i 0} {$i < $count} {incr i} {
	if {[lindex $vals $i] ne [lindex $res $i]} {
	    # Only call the 'setDetails' proc if the fileset has changed.
	    status::msg "Updating fileset $fset"
	    eval [list fileset::[fileset::type $fset]::setDetails $fset] \
	      [lrange $res 0 [expr {$count -1}]]
	    updateAFileset $fset
	    status::msg "Fileset $fset updated"
	    break
	}
    }
    # Need to deal with the attached data
    set count [fileset::setAllAttachmentDialogItems $fset $count $res]
    set res [lrange $res $count end]
    
    fileset::synchroniseAttachments $fset
}

proc newFileset {{type "fromDirectory"}} {
    global alpha::application fileSets gfileSetsType gfileSets fileSetsExtra

    # Get list of types
    foreach ty [fileset::listTypes] {
	lappend types [quote::Prettify $ty]
    }
    while {1} {
	foreach {fset type temporary} [dialog::make \
	  -ok "Continue" \
	  -okhelptag "Click here to continue creating the fileset." \
	  -addbuttons \
	  [list Help "See help on filesets and their creation" \
	  {::package::helpWindow "filesets"}] \
	  [list "Create a new fileset" \
	  [list var "Name" "" \
	  "Enter a short, descriptive name for the fileset here"] \
	  [list [list menuindex $types] "Fileset type" \
	  [lsearch -exact [fileset::listTypes] $type] "Press the 'Help'\
	  button to learn more about fileset types"] \
	  [list flag "Temporary fileset just for this editing session" 0 \
	  "Click this box if you don't wish to save the fileset when you\
	  exit $alpha::application"]]] {}
	# Get back to the actual type from the index
	set type [lindex [fileset::listTypes] $type]
	
	if {![string length $fset]} {
	    alertnote "The name cannot be an empty string!"
	} elseif {[fileset::exists $fset]} {
	    set q "The fileset '${fset}' already exists.\
	      Do you want to delete it before continuing?"
	    if {[dialog::yesno $q]} {
		deleteFileset $fset 1
		break
	    }
	} else {
	    break
	}
    }
    
    # Temporarily create the fileset now.
    set gfileSetsType($fset) $type
    foreach item [list fileSets gfileSets fileSetsExtra] {
	set ${item}($fset) ""
    }
    if {[catch {
	if {([fileset::canEdit $fset] == 1)} {
	    # Present the complete "Edit A Fileset" dialog.
	    editAFileset $fset
	} else {
	    # Use some special fileset routine.
	    fileset::${type}::create $fset
	}
    } err]} {
	deleteFileset $fset 1
	status::msg $err
    } else {
	return [registerNewFileset $fset $type $temporary]
    }
}

proc registerNewFileset {name type {temporary 1}} {
    global currFileSet gfileSetsType temporaryFilesets

    set gfileSetsType($name) $type
    if {$temporary} {
	lappend temporaryFilesets $name
    } else {
	modifyFileset $name
    }

    set currFileSet $name
    
    hook::callAll fileset-new $gfileSetsType($name) $name
    return $currFileSet
}

proc modifyFileset {name} {
    global gfileSets gfileSetsType fileSetsExtra temporaryFilesets

    set temp -1
    if {[info exists temporaryFilesets]} {
	set temp [lsearch -exact $temporaryFilesets $name]
    }

    if {($temp == -1) || [dialog::yesno "Save fileset permanently?"]} {
	prefs::modified gfileSets($name) gfileSetsType($name)
	if {[info exists fileSetsExtra($name)]} {
	    prefs::modified fileSetsExtra($name)
	}
	if {$temp != -1} {
	    set temporaryFilesets [lreplace $temporaryFilesets $temp $temp]
	}
    }
}

proc fileset::temporaryCleanup {} {
    global temporaryFilesets
    if {[info exists temporaryFilesets]} {
	foreach fset $temporaryFilesets {
	    # This is required to ensure not consistency of our
	    # own data, but that of any packages which hook into
	    # the filesets (e.g. the filesets menu) which would
	    # otherwise not realise that the temporary filesets 
	    # have disappeared when restarting.
	    deleteFileset $fset 1
	}
	unset temporaryFilesets
    }
}

proc deleteFileset {{fset ""} {yes 0}} {
    global currFileSet 
    
    if {[catch {pickFileset $fset "Delete which Fileset?" "notbuiltin"} fset]} {
	return
    }
    if {$fset == ""} {
	status::msg "The existing filesets cannot be deleted."
	return
    }

    global fileSets gfileSets fileSetsExtra gfileSetsType

    if {$yes || [dialog::yesno "Delete fileset \"$fset\"?"]} {
	set type $gfileSetsType($fset)

	if {$currFileSet eq $fset} {
	    set old $currFileSet
	    foreach fs [array names gfileSets] {
		if {($fs ne $old)} {
		    set currFileSet $fs
		    hook::callAll fileset-current * $old $currFileSet
		    break
		}
	    }
	    if {$currFileSet eq $fset} {
		set currFileSet ""
	    }
	}

	hook::callAll fileset-delete $type $fset

	fileset::uncache $fset
	
	prefs::modified gfileSetsType($fset) gfileSets($fset) \
	  fileSetsExtra($fset) fileSets($fset)
	unset -nocomplain "fileSetsExtra($fset)"
	unset -nocomplain "gfileSetsType($fset)"
	unset -nocomplain "fileSets($fset)"
	unset -nocomplain "gfileSets($fset)"
	# This uses inside knowledge of the structure of the attachment
	# storage.  Not ideal!
	global fileset::attachments fileset::infoStorage
	foreach a [array names fileset::attachments "[quote::Find $fset],*"] {
	    prefs::modified fileset::attachments($a)
	    unset fileset::attachments($a)
	}
	foreach a [array names fileset::infoStorage "[quote::Find $fset],*"] {
	    prefs::modified fileset::infoStorage($a)
	    unset fileset::infoStorage($a)
	}
	status::msg "The fileset \"$fset\" has been deleted"
    }
    if {!$yes && [askyesno "Would you like to delete another fileset?"]} {
        deleteFileset "" 0
    }
}

proc fileset::_duplicate {copy origFset} {
    global fileSets gfileSets currFileSet fileSetsExtra gfileSetsType
    
    set gfileSets($copy) $gfileSets($origFset)
    set gfileSetsType($copy) $gfileSetsType($origFset)
    prefs::modified gfileSets($copy) gfileSetsType($copy)

    if {[info exists fileSets($origFset)]} {
	set fileSets($copy) $fileSets($origFset)
    }
    if {[info exists fileSetsExtra($origFset)]} {
	set fileSetsExtra($copy) $fileSetsExtra($origFset)
	prefs::modified fileSetsExtra($copy)
    }
    # This uses inside knowledge of the structure of the attachment
    # storage.  Not ideal!
    variable attachments
    variable infoStorage
    foreach a [array names attachments "[quote::Find $origFset],*"] {
	set newname [string map [list "$origFset," "$copy,"] $a]
	set attachments($newname) $attachments($a)
	prefs::modified attachments($newname)
    }
    foreach a [array names infoStorage "[quote::Find $origFset],*"] {
	set newname [string map [list "$origFset," "$copy,"] $a]
	set infoStorage($newname) $infoStorage($a)
	prefs::modified infoStorage($newname)
    }
    
    set currFileSet $copy
    hook::callAll fileset-new $gfileSetsType($copy) $copy
}

proc renameFileset {} {
    if {[catch {pickFileset "" "Fileset to rename?" "notbuiltin"} fset]} {return}
    if {$fset == ""} {
	status::msg "The existing filesets cannot be renamed."
	return
    }

    set name [prompt "Rename to:" $fset]
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    } elseif {($name eq $fset)} {
	status::msg "Cancelled -- no changes were made to the fileset name."
	return
    }
    
    fileset::_duplicate $name $fset
    
    deleteFileset $fset 1
    
    status::msg "The fileset \"$fset\" has been renamed to \"$name\""
}

proc duplicateFileset {} {
    if {[catch {pickFileset "" "Fileset to duplicate?"} fset]} {return}
    if {$fset == ""} {
	status::msg "No fileset chosen."
	return
    }

    set name [prompt "Duplicate to:" $fset]
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    } elseif {($name eq $fset)} {
	status::msg "Cancelled -- no changes were made to the fileset name."
	return
    }
    
    fileset::_duplicate $name $fset
    
    status::msg "The fileset \"$fset\" has been duplicated to \"$name\""
}

proc updateCurrentFileset {} {
    global currFileSet
    updateAFileset $currFileSet
}

proc updateAFileset { {fset ""} } {
    global gfileSetsType

    if {[catch {pickFileset $fset "Update which fileset?" updateable} fset]} {
	return
    }
    
    if {[fileset::getKindFromFset $fset] eq "procedural"} {
	# Always up to date anyway.
	return
    }
    
    fileset::uncache $fset
    fileset::make $fset 1
}

proc fileset::uncache {fset} {
    global fsMenuCache
    if {[info exists fsMenuCache($fset)]} {
	prefs::modified fsMenuCache($fset)
	unset fsMenuCache($fset)
    }
    hook::callAll fileset-uncache * $fset
}

proc getFilesInSet {fset} {
    global gfileSets gfileSetsType
    set type $gfileSetsType($fset)
    switch -- [fileset::getKind $type] {
	"list" {
	    return $gfileSets($fset)
	}
	"glob" {
	    global filesetmodeVars fileSetsExtra
	    set dir [lindex $gfileSets($fset) 0]
	    set pat [lindex $gfileSets($fset) 1]
	    # Empty pattern not meaningful
	    if {$pat == ""} { set pat "*" }
	    if {[info exists filesetmodeVars(includeNonTextFiles)] \
	      && !$filesetmodeVars(includeNonTextFiles)} {
		set extraopts [list -types TEXT]
	    } else {
		set extraopts [list]
	    }
	    set l [eval [list glob] $extraopts \
	      [list -nocomplain -dir $dir -- $pat]]
	    if {[info exists fileSetsExtra($fset)]} {
		foreach pat $fileSetsExtra($fset) {
		    foreach f [eval [list glob] $extraopts \
		      [list -nocomplain -dir $dir -- $pat]] {
			set i [lsearch $l $f]
			if {$i >= 0} {set l [lreplace $l $i $i]}
		    }
		}
	    }
	    return $l
	}
	"procedural" {
	    switch -- $type {
		"recurseIn" {
		    return [file::recurse [lindex $gfileSets($fset) 0]]
		}
		default {
		    return [$gfileSets($fset)]
		}
	    }
	}		
	default {
	    global fileSets
	    if {![info exists fileSets($fset)]} {
		fileset::${type}::updateContents $fset 0
	    }
	    return $fileSets($fset)
	}
    }
}

proc fileset::make {name andMenu} {
    watchCursor
    if {$andMenu} {
	global fsMenuCache
	if {[info exists fsMenuCache($name)]} {
	    set m [set fsMenuCache($name)]
	    if {[llength $m]} { return $m }
	}
    }

    global gfileSetsType fileSets
    if {[info exists gfileSetsType($name)]} {
	set type $gfileSetsType($name)
	status::msg "Building fileset: ${name}É"
	set m [fileset::${type}::updateContents $name $andMenu]
	if {[llength $m]} {
	    fileset::cacheMenu $name $m
	}
	if {[info exists fileSets($name)]} {
	    prefs::modified fileSets($name)
	}
	hook::callAll fileset-update $type $name $m
	status::msg "Building fileset: ${name}É complete"
	if {[llength $m]} {
	    return $m
	} else {
	    return [filesetMenu::makeSub $name $name "" ""]
	}
    }
    return [list]
}

proc fileset::cacheMenu {fset m} {
    if {[llength $m]} {
	global fsMenuCache
	set fsMenuCache($fset) $m
	prefs::modified fsMenuCache($fset)
    }
}

# Called in response to user changing filesets manually
proc changeFileSet {item} {
    global currFileSet
    if {($currFileSet ne $item)} {
	set old $currFileSet
	set currFileSet $item
	hook::callAll fileset-current * $old $currFileSet
    }
}

# ×××× Open an item in a fileset ×××× #

proc fileset::openItemProc {fset parent item} {
    global gfileSetsType 
    if {$fset != ""} {set m $fset} else { set m $parent}
    # try a type-specific method first
    set proc fileset::$gfileSetsType($m)::selected
    if {(![llength [info commands ::$proc]]) && (![auto_load $proc])} {
	# There is no fileset-type specific procedure to open
	# items.  Hopefully we have the full path
	if {[file exists $item]} {
	    return [edit -c $item]
	} else {
	    # if that failed then just hope this default procedure will work.
	    if {![catch {filesetBasicOpen $m $item} err]} {return}
	}
    } else {
	if {[llength [info args ::$proc]] == 2} {
	    if {![catch {eval [list $proc $parent $item]} err]} {return}
	} else {
	    if {![catch {eval [list $proc $fset $parent $item]} err]} {return}
	}
    }
    
    fileset::fileNotFound $fset $err
}

proc fileset::fileNotFound {fset {text ""}} {
    if {[string length $text]} {
	append text "\r"
    }
    append text "That file wasn't found. The fileset may be out of date."
    if {![catch {dialog::yesno -y "Rebuild fileset" \
      -n "Edit fileset" -c $text} res]} {
	if {$res} {
	    updateAFileset $fset
	} else {
	    editAFileset $fset
	}
	return 1
    } else {
	status::msg "Cancelled"
	return 0
    }
}

proc filesetBasicOpen {fset item} {
    set f [file::pathEndsWith $item [getFilesInSet $fset]]
    if {[string length $f]} {
	autoUpdateFileset $fset
	file::openAny $f
	return
    }
    error "File for selected '$item' not found"
}

proc autoUpdateFileset { name } {
    global filesetmodeVars
    if {$filesetmodeVars(autoAdjustFileset)} {
	changeFileSet $name
    }
}

# ×××× Query procs ×××× #


# There seem to be various special cases here which would be best
# handled by another fileset type callback proc
proc fileset::findForFile { {win ""} } {
    if {$win == ""} { set win [win::Current] }
    global currFileSet gfileSets gfileSetsType
    set mostSpecificMatchingFileset {}
    set mostSpecificLength 0
    foreach fset [concat [list $currFileSet] [array names gfileSets]] {
	switch -- [fileset::getKind $gfileSetsType($fset)] {
	    "list" {
		if {[lsearch -exact $gfileSets($fset) $win] != -1} {
		    return $fset
		}
	    }
	    "glob" - "fromHierarchy" {
		if {[file::pathStartsWith $win \
		  [lindex $gfileSets($fset) 0]]} {
		    set len [string length [lindex $gfileSets($fset) 0]]
		    if {$len > $mostSpecificLength} {
			set mostSpecificMatchingFileset $fset
			set mostSpecificLength $len
		    }
		}
	    }
	    "procedural" {
		switch -- $gfileSetsType($fset) {
		    "recurseIn" {
			if {[file::pathStartsWith $win \
			  [lindex $gfileSets($fset) 0]]} {
			    set len [string length [lindex $gfileSets($fset) 0]]
			    if {$len > $mostSpecificLength} {
				set mostSpecificMatchingFileset $fset
				set mostSpecificLength $len
			    }
			}
		    }
		    default {
			continue
		    }
		}
	    }
	    "default" {
		# This will handle TeX filesets, for example, which
		# just list their contents in fileSets()
		global fileSets
		# Try various file forms -- we might really need to
		# scan through each entry in turn...
		if {[lsearch -exact $fileSets($fset) $win] != -1} {
		    return $fset
		}
		if {[lsearch -exact $fileSets($fset) [file norm $win]] != -1} {
		    return $fset
		}
	    }
	}
    }
    return $mostSpecificMatchingFileset
}

proc dirtyFileset { fset } {
    foreach f [getFilesInSet $fset] {
	if {![catch {getWinInfo -w $f arr}] && $arr(dirty)} { return 1 }
    }
    return 0
}

proc fileset::isIn {fset name {alwaysCheckList 0}} {
    if {!$alwaysCheckList} {
	set base [fileset::getBaseDirectory $fset]
	if {[string length $base]} {
	    return [file::pathStartsWith $name $base]
	}
    }
    return [isWindowInFilelist $name [getFilesInSet $fset]]
}

# Determine whether the given window (or the current window, if none is
# given) is in a fileset of the given type (or all types except
# procedural, if none is given).
# 
# The only actual user of this code is the TeX code which asks about
# TeX filesets.
# 
# Run through the list of all filesets, starting with current fileset: for
# each one, ask these questions: is the type ok?  does it contain the file?
proc isWindowInFileset { {win "" } {type ""} } {
    global currFileSet gfileSetsType
    if {$win eq ""} { set win [win::Current] }
    if {$type eq ""} { set type "*" }
    # check current fileset before checking other filesets:
    foreach fset [concat [list $currFileSet] [fileset::names]] {	
	if { [string match $type $gfileSetsType($fset)] && 
	  $fset ne {Recurse in folderÉ} &&
	  [isWindowInFilelist $win [getFilesInSet $fset]] } {
	    # this fileset is of correct type and contains $win
	    return $fset
	}
    }   
    return ""
}
# <JK: Nov.2005, cf. remarks in Bug 1619 one year ago> Note for the sake
# of completeness that this version represents a slight behaviour change
# compared to the previous version: this version accepts a glob-style
# pattern for $type.  This should be of no importance since all callers
# pass the exact string anyway.


proc isWindowInFilelist { win flist } {
    set win [win::StripCount $win]
    foreach f $flist {
	if {[string equal $win [file::ensureStandardPath $f]]} {
	    return 1
	}
    }
    return 0
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"pickFileset" --
 #	
 # Ask the user for a/several filesets.  If 'fset' is set, we just return
 # that (this avoids 'if {$fset != ""} { set fset [pick...]  } constructs
 # everywhere).  A prompt can be given, and a dialog type (either a
 # listpick, a pop-up menu, or a listpick with multiple selection), and
 # extra items can be added to the list if desired. 
 # -------------------------------------------------------------------------
 ##
proc pickFileset { fset {prompt Fileset?} {type "list"} {extras {}} } {
    global gfileSets currFileSet
    if {[array size gfileSets] == 0} {
	error "There are no filesets currently defined"
    }
    if { $fset != "" } { return $fset }
    switch -- $type {
	"updateable" {
	    set fsets {}
	    foreach fset [array names gfileSets] {
		if {[fileset::getKindFromFset $fset] != "procedural"} {
		    lappend fsets $fset
		}
	    }
	    return [listpick -p $prompt -L [list $currFileSet] \
	      [lsort -dictionary [concat $extras $fsets]]]
	}
	"popup" {
	    set fset [eval [list prompt $prompt \
	      $currFileSet "FileSet:"] [lsort -dictionary [array names gfileSets]]]
	    if {![info exists gfileSets($fset)]} { error "No such fileset" }
	    return $fset
	}
	"list" {
	    return [listpick -p $prompt -L [list $currFileSet] \
	      [lsort -dictionary [concat $extras [array names gfileSets]]]]
	}
	"multilist" {
	    return [listpick -p $prompt -l -L [list $currFileSet] \
	      [lsort -dictionary [concat $extras [array names gfileSets]]]]
	}
	"notbuiltin" {
	    global fileset::notChangeable
	    set choices [list]
	    foreach fset [lsort -dictionary [array names gfileSets]] {
		if {[lsearch -exact ${fileset::notChangeable} $fset] == -1} {
		    lappend choices $fset
		}
	    }
	    if {[llength $choices]} {
		set item $currFileSet
		if {[lsearch -exact $choices $currFileSet] == -1} {
		    set item [lindex $choices 0]
		}
		return [listpick -p $prompt -L [list $item] \
		  [lsort -dictionary [concat $extras $choices]]]
	    } else {
		return ""
	    }
	}
	"editable" {
	    set choices [list]
	    foreach fset [lsort -dictionary [array names gfileSets]] {
		set canEdit [fileset::canEdit $fset]
		if {$canEdit < 0} {continue}
		lappend choices $fset
	    }
	    if {[llength $choices]} {
		set item $currFileSet
		if {[lsearch -exact $choices $currFileSet] == -1} {
		    set item [lindex $choices 0]
		}
		return [listpick -p $prompt -L [list $item] \
		  [lsort -dictionary [concat $extras $choices]]]
	    } else {
		return ""
	    }
	}
	default {
	    if {[lindex $type 0] == "withinfo"} {
		set fsets [fileset::thoseWithInformation [lindex $type 1]]
		if {([lsearch $fsets $currFileSet] > -1)} {
		    set L [list $currFileSet]
		} else {
		    set L [list [lindex $fsets 0]]
		}
		return [listpick -p $prompt -L $L [lsort -dictionary $fsets]]
	    }
	}
    }
}

#================================================================================
# Edit a file from a fileset via list dialogs (no mousing around).
#================================================================================

namespace eval file {} 

proc file::openViaFileset {{fset ""}} {
    global currFileSet
	
    if {[catch {pickFileset $fset {Fileset?} "list"} fset]} {return}
    set currFileSet $fset
    
    set filename [fileset::getBaseDirectory $fset]
    if {[string length $filename]} {
	if {[file exists $filename]} {
	    file::openViaListpicks $filename
	} else {
	    set msg "The base path for the fileset '${fset}' doesn't exist:\
	      \r${filename}"
	    if {![dialog::yesno -y "Edit FilesetÉ" -n "Cancel" $msg]} {
		error "cancel"
	    } 
	    editAFileset $fset
	    return [file::openViaFileset $fset]
	}
    } else {
	set allfiles [getFilesInSet $fset]
	foreach f $allfiles {
	    lappend disp [file tail $f]
	}
	if {[catch {listpick -l -p {File?} [lsort -dictionary $disp]} files]} {
	    return
	}
	foreach res $files {
	    set ind [lsearch -exact $disp $res]
	    if {$ind != -1} {
		fileset::openItemProc $fset "" [lindex $allfiles $ind]
	    } else {
		error "Cancelled -- couldn't find $res"
	    }
	}
    }
}

proc getFileSet {fset} {
    global filesetmodeVars
    if {[info exists filesetmodeVars(includeNonTextFiles)] \
      && !$filesetmodeVars(includeNonTextFiles)} {
	# We only return TEXT files, which prevents Alpha from manipulating
	# the data fork of non-text files.  Note that [getFilesInSet] also
	# checks for this variable, but only in "glob" listings.
	set fnames ""
	foreach f [getFilesInSet $fset] {
	    if {[file isfile $f]} {
		getFileInfo $f a
		if {![info exists a(type)] || ($a(type) == "TEXT")} {
		    lappend fnames $f
		}
	    }
	}
	return $fnames
    } else {
	return [getFilesInSet $fset]
    }
}

# ===========================================================================
# 
# ×××× Back Compatibility ×××× #
# 

proc filesetRegisterProcedural {args} {
    return [eval fileset::registerProcedural $args]
}

# ===========================================================================
# 
# .

