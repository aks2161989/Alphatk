## -*-Tcl-*- (nowrap)
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "dialogModifications.tcl"
 #                                    created: 06/27/2003 {09:05:32 AM}
 #                                last update: 01/17/2005 {10:10:57 AM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 2001-2003  Vince Darley, BSD license.
 # 
 # This file contains procedures to handle modifications to dialogs
 # in place, for example when the user drag'n'drops items onto a
 # dialog, when they hit a 'set...' button which modifies one or
 # more dialog items, when they select or otherwise manipulate one
 # dialog item which has an impact on others (through '-action'
 # flags, for example).
 # 
 # This code is really internal to AlphaTcl and none of it
 # should be called directly by the user.
 # ###################################################################
 ##

# Dialogs modifications in place.  
# 
# Overall notes: these '-set', '-tag', '-action', '-drag' and '-drop'
# arguments can come before or after the 'left top right bottom'
# coordinates of a dialog item.
# 
# IMPORTANT NOTE: A button in a dialog which has an associated 'action'
# or 'set' script will *not* finish the dialog when it is pressed, i.e.
# the dialog command will not return when that button is pressed
# (otherwise there is little point in having the set or action script).
# However, the button will still feature in the list of 0s and 1s which
# are eventually returned by the dialog command (when a different button
# is pressed).  There must be at least one button in each dialog with no
# associated action (else an error will be thrown by the dialog command,
# since the dialog could never be closed).
# 
# ----
# 
# TECHNICAL NOTE: The internal implementations of '-set' and '-action'
# are very similar (at least in Alphatk).  In fact the ONLY
# difference is that '-set' calls this internally:
# 
# dialog::itemSet $dialogItemId $callback
# 
# where it assumes there is only one item and hence one $dialogItemId,
# and '-action' calls this internally:
# 
# eval $callback [list $dialogItemIdList]
# 
# where $dialogItemIdList is now a list of dialog control ids.  (These
# ids are individually exactly the same as the $dialogItemId used
# above).
# 
# Therefore we should unify these two into using just the '-action'
# flag and make the older '-set' flag obsolete.
# 
# ----
# 
# === "-action handling and callbacks ===
# 
# Any dialog item which has an associated value or action can have an
# '-action' associated with changes to that value.  Typically this is a
# popup menu, button or checkbox in a dialog.  The syntax of the -action
# is as follows:
# 
# dialog .... item ... -action [list $callback [list ?index? ...]]
# 
# When the dialog item is modified in some way (clicked on for a button,
# value changed for a popup menu), '$callback' is evaluated by Alpha's
# core as follows:
# 
# eval $callback [list $listOfDialogIds]
# 
# Therefore $callback must take one extra argument, which is a list
# containing one dialog id for each of the original indices which were
# given (it is ok if none are given -- then an empty list is the only
# argument).  These dialog ids can later be used to manipulate the dialog
# itself, in place.  If the id of the dialog item with the -action itself
# is required, then that can, of course, be retrieved with the '+0' index
# item in the list.  Each index should be either a non-negative integer
# (refers to items in order in the dialog), or a string "+N" or "-N" to
# refer to relative items to the current one (don't confuse these with
# integers - they start with + or -), or a tag (an arbitary string).
# 
# These dialog ids can be used as arguments to these commands:
# 
# getControlInfo  <id> <attribute>                 (Alphatk only)
# setControlInfo  <id> <attribute> $value          (Alphatk only)
# 
# Where <attribute> is 'state', 'value', 'font', or 'help'.  Here
# 'state' is used to enable/disable the item, 'font' is used to access
# the font, and 'help' is used to adjust the items tooltip help text.
# 
# On Alpha 8/X only these simpler forms are currently available (they
# are also available on Alphatk):
# 
# getControlValue <id>
# setControlValue <id> $value
# 
# The dialog ids are only valid as long as the dialog itself is shown.
# As soon as the dialog has been dismissed, these id are useless
# and will likely throw an error if passed to get/setControlValue.
# Therefore these ids should not be stored, except for temporary
# usage.
# 
# The commands above, of course, only affect the visual appearance in the
# dialog.  It is up to the original caller of the dialog to take care of
# any associated storage if that is required (e.g. storing values in Tcl
# variables).  Note that while the 'setControlValue' command can be used
# to set the value of dialog items such as checkboxes, text entry fields
# whose value will later be returned when the dialog closes, it can also
# be used to set the 'value' of non-editable text labels and the textual
# label of a button, whose 'value' is certainly not returned when the
# dialog closes.
# 
# Out of interest, we show how '-action' can be used to imitate the older
# syntax employed by '-set'.  To do this, replace:
# 
#   -set [list $setCallback $index]
#   
# by:
# 
#   -action [list [list dialog::imitateSet $setCallback] [list $index]]
#   
# where:
# 
# proc dialog::imitateSet {setCallback dialogIdList} {
#    dialog::itemSet [lindex $dialogIdList 0] $setCallback
# }
# 
# and that's it.  Therefore '-set' is largely obsolete.  (Except Alpha
# 8/X don't yet support -action, I think).
# 
# === "-tag <tagName> on dialog items"
# 
# Rather than forcing the dialog command writer to count the exact
# location or offset of each dialog item they want to modify or read, a
# tag can be added to an item, and then referenced from any of the index
# lists, as follows:
# 
# dialog .... -b "Change" -tag change ... -action {fooProc {change}}
# 
# proc fooProc {dialogIdList} {
#     setControlValue [lindex $dialogIdList 0] "New Button Name"
# }
# 
# This makes it much easier to use all of these features.  Note that
# these tags can be forward or backward looking (i.e. you can reference
# a tag before it has been created).
# 
# === "Drop" handling and callbacks ===
# 
# We support the dragging and dropping of things onto dialog items.  To
# allow drops, a dialog item must be declared with the optional '-drop'
# flag.  This takes one extra argument, which is a list of 3 or
# optionally 4 items:
# 
# dialog ... item ... -drop \
#   [list $mimetypes $cmdCheck $cmdSet ?{index ... index}?]
# 
# The first element is the list of mime types that are supported for
# dropping onto the dialog item.  You can use 'dialog::valGetMimeTypes
# $itemInfo' to generate $mimetypes, this list (assuming you are using
# the kind of dialog code which has a $itemInfo).  If that proc returns an
# empty list, then nothing is supported, and the -drop flag is ignored if
# an empty mimetypes list is passed in.
# 
# The two other commands are typically created as follows (see
# dialog::makeDropArgList), although anything can be passed in:
# 
#   set cmdCheck [list dialog::itemAcceptable $itemInfo]
#   set cmdSet [list dialog::dndSetCallback $itemInfo]
# 
# There is also an optional list of indexes of other dialog items 
# which the callbacks wish to modify.  Typically this will contain
# "+0" to indicate the current dialog item (the one being dropped on)
# should be modified.
# 
# The two scripts are used to handle drop callbacks, and are arranged
# to be called whenever an object with any of the acceptable mimetypes
# is dragged/dropped as follows:
# 
# When an item is being dragged into the given dialog item, Alpha(tk)
# will call:
# 
#   set res [eval $cmdCheck $dataList]
#   
# if the thing being dragged matches the allowed mime types (if the mime
# type doesn't match any of those which were acceptable, then none of
# these methods should ever be called).  If this call returns an empty
# string, then a drop will be allowed (and this will be shown visually in
# the dialog item, and in the status bar a message will appear "OK to
# drop $dataList here").  If anything else is returned a message is shown in
# the status bar: "Can't drop here: $res"
# 
# If the user actually drops something, then Alpha(tk) will call:
# 
#   eval $cmdSet [list $dialogIdList] $dataList
#   
# and if this command succeeds (i.e. doesn't throw an error), then 
# nothing else will happen.  If an error is thrown (which is odd,
# since we have already checked if the drop is ok), then this error
# will appear in the status bar: "Drop error: $msg", and it will also
# be re-thrown.
# 
# Here the list of dialog ids can be used to modify any item in the
# dialog in place.  Typically, if just '+0' was given in the -drop option,
# then there will be just one id, for the current item.
# 
# Notice how both 'dialog::itemAcceptable' and 'dialog::dndSetCallback'
# (which will route things to dialog::itemSet and dialog::modifiedAdd or
# dialog::modifiedSet) take a variable number of arguments.  This is
# because the user may be dropping more than one item.
#
# === "Drag" handling and callbacks ===
# 
# We support the capability of dialog items to initiate drag operations.
# To allow drag initiation, a dialog item must be declared with the
# optional '-drag' flag.  This takes one extra argument, which is a list
# of 3 or 4 items:
# 
# dialog ... item ... -drag \
#    [list $mimetypes $dragCallback $dragDone ?{index ... index}?]
# 
# The first element is the list of mime types that are supported for
# dragging from the item.  You can use 'dialog::valGetMimeTypes
# $itemInfo' to generate $mimetypes, this list.  If that proc returns an
# empty list, then nothing is supported, and the -drag flag is ignored if
# an empty mimetypes list is passed in.
# 
# The dragCallback is a command or script which will be evaluated when
# required to get the actual value to be dragged, and $dragDone is
# a command/script which will be evaluated once the drag has completed
# successfully (and can be used, if necessary, to update the dialog in
# place).  The 'index' list is the usual list which will be turned
# into setOrGetCmds which will be passed to the drag callbacks.
# 
# Here $dragDone can be empty, in which case no callback will be made.
# (We might need to distinguish here between drag and copy and drag as
# move/cut.  Perhaps we only need the former, and dragDone is
# unnecessary?)
# 
# === "Set..." handling and callbacks ===
# 
# NOTE: '-set' should be considered an older, obsolete option which
# will be removed in the future.  '-action' should be used instead.
# 
# Buttons (and perhaps in the future other dialog item types) can have a
# '-set' option.  This takes a single argument:
# 
# dialog .... -b "Set..." -set [list $setCallback {$item .. $item}]
# 
# This argument is a pair of:
# 
# (i) a Tcl script or procedure name which will usually be evaluated
# (therefore it should be a valid list) when the button is pressed (with
# additional arguments as described below)
# 
# (ii) a list of item offsets in the dialog.  Currently exactly one item
# must be in this list (the item which is to be set).  For multiple items
# (or zero items), please use the '-action' flag which is more powerful
# and flexible than '-set'.
# 
# Alpha(tk)'s core then calls:
# 
#    dialog::itemSet $dialogItemId $setCallback
#    
# and everything else is handled from AlphaTcl.  Here '$dialogItemId' is
# the id of an item which can be used in setControlValue to modify the
# given item in place.
# 
# It can be used by dialog::itemSet (or its helpers) as follows:
# 
#    setControlValue $dialogItemId $val
# 
# where '$itemInfo' is the result of 'dialog::makeItemInfo' and '$val' is
# the new value.  It may seem peculiar that '$itemInfo' must be passed
# in.  However, it is needed if '$val' is too long to display --- then
# Alpha(tk)'s core calls back to AlphaTcl to ask it to abbreviate the
# item, using:
# 
#    dialog::abbreviate $itemInfo $val $width
#    
# where '$width' is the available width in pixels (this is only done if
# the core determines the item is too wide).  The return value
# of this call is then used instead of $val to set the item.
# 
# The kinds of items which can be set in this way are labels, entries,
# multi-line text entries, listboxes, checkbuttons, radiobuttons, 
# menubuttons, etc.
# 

namespace eval dialog {}

# Important function which creates an 'opaque' object (actually just
# a list) containing information about the current dialog, the name
# of a dialog item or variable (together these two uniquely specify
# an item in a dialog) and the type of the item.  The last argument
# is optional (at present, although this may change).
# 
# Note: currently lots of pieces of code assume they know the 
# structure of the 'itemInfo' object.  But really much of it
# shouldn't need to know.  Anyway, at the least we can be
# sure Alpha tk/8/X do not know anything about its internal
# structure.
# 
# The accessors 'dialog::_getType', 'dialog::_getName' should
# be used to get information about a itemInfo object.
# 
# -----
# 
# I believe the next major changes to the dialogs code should
# be to abstract away the preferences information into the
# itemInfo object.  Right now if we look at a procedure like
# 'dialog::getOldFlag' we can see just how much information
# about a flag/var is stored separately.
proc dialog::makeItemInfo {dial name {type ""}} {
    ::list $dial $name $type
}

proc dialog::_getType {itemInfo} {
    lindex $itemInfo 2
}

proc dialog::_getName {itemInfo} {
    lindex $itemInfo 1
}

proc dialog::modified {itemInfo val {dialogItemId ""}} {
    #alpha::log stdout [list dialog::modified $itemInfo $val $dialogItemId]
    dialog::valChanged [lindex $itemInfo 0] [lindex $itemInfo 1] $val
    set type [_getType $itemInfo]
    if {[string length $type] && ($dialogItemId != "")} {
	# We have some code which would like to know what changed.  We
	# currently use this approach to update dialog items from Set...
	# buttons automatically, but it may be better if the code that
	# called dialog::modified could do it explicitly.
	dialog::setValue $dialogItemId $itemInfo $val
    }
}

# Called by drag'n'drop or set callbacks.
proc dialog::modifiedSet {itemInfo dialogItemId args} {
    #alpha::log stdout [list dialog::modifiedSet $itemInfo $dialogItemId $args]

    switch -- [llength $args] {
	0 {
	    return -code error "No value argument to dialog::modifiedSet"
	}
	1 {
	    set newValue [lindex $args 0]
	}
	default {
	    return -code error "Can only drop one item at a time."
	}
    }
    # Double-check we can accept it
    set err [dialog::itemAcceptable $itemInfo $newValue]
    if {[string length $err]} {
	status::msg "Drop failed for '$newValue' : $err"
    } else {
	dialog::modified $itemInfo $newValue $dialogItemId
	status::msg "Dropped '$newValue'"
    }
}

proc dialog::modifiedAdd {itemInfo dialogItemId args} {
    #alpha::log stdout [list dialog::modifiedAdd $itemInfo $dialogItemId $args]

    # Double-check we can accept it
    foreach newValue $args {
	set err [dialog::itemAcceptable $itemInfo $newValue]
	if {[string length $err]} {
	    status::msg "Drop failed for '$newValue' : $err"
	    return
	}
    }
    
    set new [concat [dialog::getFlag $itemInfo] $args]
    dialog::modified $itemInfo $new $dialogItemId
    
    status::msg "Dropped '$new'"
}

# When a dialog item is modified in place, this procedure will
# be called by AlphaTcl.  It is called after the internal storage
# for the variable has been updated, and cannot cancel the change.
# 
# '$dialogItemId' is an id string given to us by our editing environment
# (Alpha(tk)) which can be used to change the dialog in place, through
# the command setControlValue $dialogItemId $value
proc dialog::setValue {dialogItemId itemInfo val} {
    #alpha::log stdout "dialog::setValue $dialogItemId $itemInfo $val"
    set type [_getType $itemInfo]
    
    if {[info commands ::dialog::specialView::$type] != ""} {
	set view [::dialog::specialView::$type $val]
    } else {
	set view $val
    }
    if {$::alpha::platform == "alpha" && [llength [info commands getControlInfo]] == 0} {
	# Obsolete code path -- Jon's working on this.
	eval $dialogItemId [list $itemInfo $view]
    } else {
	# Good code path.

	# Try to abbreviate a maximum of 100 times to avoid infinite loops
	for {set i 0} {$i < 100} {incr i} {
	    if {[catch {::setControlValue $dialogItemId $view} width]} {
		# error was thrown.  Error value is the available width
		set font [getControlInfo $dialogItemId font]
		set view [dialog::abbreviate $font $itemInfo $view $width]		
	    } else {
		return
	    }
	}
	# Hmm, unable to abbreviate this very well...  Just show nothing
	# in the dialog.
    }
}

# Called by dialog::setValue to abbreviate an item.  The 'width' is in
# pixels
proc dialog::abbreviate {font itemInfo str width} {
    # 'itemInfo' is defined in 'dialog::setValue'.
    # Currently we abbreviate independently of the type of the item
    # but in the future we could make use of 'itemInfo' to abbreviate
    # according to type.
    abbreviateText $font $str $width
}

# ×××× Drag and Drop handlers ×××× #

# Used in all of the AlphaTcl dialog code to create the necessary
# information to pass to the core of Alpha 8/X/tk to handle drag and
# drop operations.
proc dialog::makeDropArgList {itemInfo} {
    # Make a list of four elements
    
    # First argument the list of acceptable mime types
    lappend res [dialog::valGetMimeTypes $itemInfo]
    # Second argument the callback for whether the drop is
    # acceptable
    lappend res [list ::dialog::itemAcceptable $itemInfo]
    # Third argument the callback to carry out the drop
    lappend res [list ::dialog::dndSetCallback $itemInfo]
    # Fourth argument the current item we want to drop onto
    lappend res [list +0]
    
    # Return the list
    return $res
}

proc dialog::dndSetCallback {itemInfo dialogItemIds args} {
    set dialogItemId [lindex $dialogItemIds 0]
    #puts stderr [list $itemInfo $dialogItemIds $args $dialogItemId]
    set type [_getType $itemInfo]
    if {$type == "searchpath"} {
	eval [list ::dialog::modifiedAdd $itemInfo $dialogItemId] $args
    } else {
	eval [list ::dialog::modifiedSet $itemInfo $dialogItemId] $args
    }
}

# Is the given variable of given type allowed to be set to the
# given value?  This procedure is called by things like drag-n-drop
# code, which means we can assume the newValue is already of an
# appropriate general type.  Any return value signifies an error
# with the value being a helpful error message.  To signify
# success, return nothing at all.
proc dialog::itemAcceptable {itemInfo args} {
    #alpha::log stdout [list dialog::itemAcceptable $itemInfo $args]
    set type [dialog::_getType $itemInfo]
    if {$type != "searchpath"} {
	if {[llength $args] > 1} {
	    return "Can only drop one item!"
	}
    }
    if {[llength $args] == 0} {
	return "No item -- strange!"
    }
    set newValue [lindex $args 0]
    
    switch -- $type {
	"searchpath" {
	    if {[file isdirectory $newValue]} {
		return
	    }
	    global prefs::extraOptions
	    # This 'prefs::extraOptions' stuff needs embedding in
	    # itemInfo
	    set var [lindex $itemInfo 1]
	    if {[info exists prefs::extraOptions($var)]} {
		foreach ext [set prefs::extraOptions($var)] {
		    if {[string match $ext $newValue]} {
			return
		    }
		}
		return "Bad file extension"
	    }
	    return "Not a directory"
	}
	"folder" {
	    if {![file isdirectory $newValue]} {
		return "Not a directory"
	    }
	}
	"file" {
	    if {![file isfile $newValue]} {
		return "Not a file"
	    }
	}
	"url" {
	    # All urls ok?
	}
	"appspec" -
	"sig" {
	    if {![file executable $newValue]} {
		return "Not executable"
	    }
	}
    }
    # Default is to accept a drop, since the code behind the scenes
    # will make sure we only get reasonable things dropped.
    return
}

# Called above to find the allowed mime types
# which can be dropped on this command string.
proc dialog::valGetMimeTypes {itemInfo} {
    switch -- [_getType $itemInfo] {
	"appspec" -
	"sig" {
	    return [list "application/octet-stream" "text/uri-list"]
	}
	"file" -
	"folder" -
	"url" {
	    return [list "text/uri-list"]
	}
	"searchpath" {
	    return [list "text/uri-list"]
	}
	default {
	    return ""
	}
    }
}

# ×××× Obsolete calls ×××× #

# Called to make the argument for a '-set' by dialog::buttonSet.
# Once Alpha 8/X support -action, we will use that instead.
proc dialog::makeSetCallback {dial idx type name} {
    set itemInfo [dialog::makeItemInfo $dial $name $type]

    set setCallback [list dialog::specialSet::$type $itemInfo]
    
    return [list $setCallback $idx]
}

# Dialog code internal to Alpha(tk) can call this procedure when a
# 'set...'  button is pressed to interact with AlphaTcl in the process of
# modifying the dialog in place.  The 'setCallback' is the command
# registered with the '-set' flag, and 'dialogItemId' is an id which will
# be used in the procedure 'dialog::setValue'.  These item ids must be
# created and removed by the internal dialog code when appropriate.
# 
# Clearly it would be better if Alpha(tk)'s core would just call the
# setCallback itself, but for historical reasons it doesn't.
# 
# The setCallback which is created in AlphaTcl ensures that, if a change
# does actually take place, then not only is that fact remembered (when
# it arranges for 'dialog::modified' to be called), but also the
# $dialogItemId which was passed in is used to modify the appearance of
# the dialog in place (with 'setControlValue').
proc dialog::itemSet {dialogItemId setCallback} {
    #alpha::log stdout [list dialog::itemSet $dialogItemId $setCallback]
    # Use of this proc by 'set...'  buttons will usually call one of the
    # dialog::specialSet procedures which brings up a new dialog to ask
    # the user for the value to use.
    namespace eval :: $setCallback [list $dialogItemId]
}

proc dialog::imitateSet {setCallback dialogIdList} {
   dialog::itemSet [lindex $dialogIdList 0] $setCallback
}
