## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "alphaHooks.tcl"
 #                                          created: 07/18/1997 {05:10:18 pm}
 #                                      last update: 06/02/2006 {01:37:54 PM}
 # Description: 
 #  
 # This file contains most of the Tcl procedures which are called by
 # Alpha/Alphatk internally.  As such you should be very careful making any
 # changes to these procedures.
 #  
 # See "Extending Alpha" for lists of available hooks and further
 # documentation on them.
 #  
 # Use [hook::register] to attach code to any of these procedures.
 #  
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #  
 # History
 # 
 # modified by  rev reason
 # -------- --- --- -----------
 # 18/7/97   VMD 1.0 original
 # 22/7/97   VMD 1.1 fixed all bugs ;-) and added the above examples.
 # 4/2/04    VMD 2.0 total overhaul, with support for composite modes
 # 2005-01-21 VMD 2.1 added support for hidden windows, and much 
 #    cleanup, simplification, also more robust through use of the 
 #    test suite and resultant bug fixing.
 #  
 # ==========================================================================
 ##

proc alphaHooks.tcl {} {}

# Called just before saving the window to disk.  So, this hook
# can be used to modify the contents of the window before saving
# (for example, adjusting a 'modified date' in the header of the
# file, or a version number).
proc saveHook name {
    hook::callForWin saveHook all $name $name
}

proc savePostHook {name} {
    # So modified date is ok
    if {[win::IsFile $name nm]} {
	win::setInfo $name Modified [file mtime $nm]
	win::setInfo $name shell 0
	if {[alpha::frontmostAndActive $name]} {
	    # After 'save' this should already be enabled, but after
	    # saveAs it will still be disabled, so we enable this menu
	    # item now.
	    enableMenuItem File "renameToÉ" 1
	}
    } else {
	alertnote "Weird, file '$name' doesn't seem to exist: please\
	  report the circumstances of this problem to the\
	  alphatcl-developers mailing list."
    }
    
    hook::callForWin savePostHook all $name $name
}

##
 # --------------------------------------------------------------------------
 #
 # "saveAsDefaultHook" --
 # 
 # Called by Alphatk's core when doing 'save as' on a window, to
 # determine the default suggestion to the user for where this
 # file should be saved.  If the user has given a default name,
 # that will typically be used, but we may modify it to ensure the
 # name is actually legal.
 # 
 # Not currently called by Alpha 8/X
 # --------------------------------------------------------------------------
 ##
proc saveAsDefaultHook {name {default ""}} {
    if {$default eq ""} { 
	set default [win::StripCount $name] 
    }
    if {![file exists $default]} {
	set default [file join [file dirname $default] \
	  [file::makeNameLegal [file tail $default]]]

	set next [lindex [winNames -f] 1]
	if {[win::IsFile $next]} {
	    set default [file join [file dirname $next] [file tail $default]]
	}
    }
    return $default
}

##
 # --------------------------------------------------------------------------
 #
 # "saveAsEncodingHook" --
 # 
 # Called by Alphatk's core when doing 'save as' on a window, only if
 # that window has no core 'encoding' attribute defined (via setWinInfo).
 # This procedure is called once the destination name (and any <n> 
 # required) are already known, and the user has already been asked 
 # whether to replace any pre-existing file, etc.  i.e. we are sure
 # the save-to-disk is actually going to take place.
 # 
 # In such cases this procedure is asked to return the correct encoding
 # to use.  This can take account of any mode associated with the 
 # window, or the location to which it is going to be saved.
 # 
 # The empty string is _not_ a valid result.
 # 
 # 'force' is 1 if the saveAs command was given the '-f' flag in which
 # case no user-interactivity is desired.
 # 
 # Not currently called by Alpha 8/X
 # --------------------------------------------------------------------------
 ##
proc saveAsEncodingHook {name force} {
    if {![win::IsFile $name filename]} {
	alertnote "Bug: bad window name \"$name\" passed to saveAsEncodingHook"
	return ""
    }
    set currEnc [win::getModeVar $name encoding ""]
    set saveAsEnc [alpha::encodingFor $filename]
    if {$currEnc == ""} {
	# Just use whatever is ok for the destination
	if {$saveAsEnc == ""} {
	    set currEnc [encoding system]
	} else {
	    set currEnc $saveAsEnc
	}
    } else {
	# Compare with the destination encoding.
	if {($saveAsEnc != "") && ($saveAsEnc != $currEnc)} {
	    # ask user
	    if {$force || [dialog::yesno -n "Use current '$currEnc'" \
	      "This window has text encoding '$currEnc', but the\
	      default encoding for the location\
	      to which you are saving it is '$saveAsEnc'. Would\
	      you like to save this file in the new encoding?"]} {
		set currEnc $saveAsEnc
	    }
	}
    }
    return $currEnc
}

##
 # --------------------------------------------------------------------------
 #
 # "closeHook" --
 # 
 # Called after a window has been destroyed.  All evidence of the window
 # has gone, except perhaps its entry in a few arrays which are cleaned
 # up here.  Certainly 'getWinInfo' and related calls will no longer
 # recognise the window at this point.  'win::getInfo' may still be
 # used to retrieve non-core attributes.
 # 
 # Any window that passes through 'winCreatedHook' _must_ eventually
 # end up here (even if an internal error occurs after winCreatedHook
 # which aborts the window creation, the core must still call this
 # proc).
 # --------------------------------------------------------------------------
 ##
proc closeHook {name} {
    # This will remove the window from the win::CreationOrder list.
    win::removeFromList $name
    
    hook::callForWin closeHook all $name $name

    # Clean up all AlphaTcl attributes of the window
    win::destroyed $name
    
    # If we have no visible windows, then change to the empty mode.
    if {![alpha::frontmostAndActive]} {
	alpha::changeMode {}
    }
    alpha::menuAdjustForOpenWins 0
}

##
 # --------------------------------------------------------------------------
 #
 # "preCloseHook" --
 # 
 # Called just prior to the destruction of a window, invoked by the core
 # command [killWindow] as well as any other action which closes a window
 # such as clicking on the 'close' button/box), _after_ the user has been
 # asked if a dirty window should be saved.  i.e. if the user chose to
 # cancel, then of course this isn't called, and if the user chose to
 # save then various save actions will already have been triggered
 # before we are called.
 # 
 # Any of the procs which are called by:
 # 
 #   [hook::callAll preCloseHook * # $w] 
 #   
 # should _not_ attempt to change the contents of the window or any file
 # / window information.  Note that any procs called by [hook::callAll]
 # are wrapped in a [catch], so you cannot try to throw an error to
 # cancel the closing of the window, and any such errors are considered
 # bugs in registered hooks.
 # 
 # At this point the window attributes all still exist, so win::getInfo
 # can be used, for example, to check if the window is dirty.
 # --------------------------------------------------------------------------
 ##
proc preCloseHook {name} {
    hook::callForWin preCloseHook all $name $name

    # We check for dirtiness here, because by the time closeHook is
    # called, this window attribute no longer exists.
    if {[win::getInfo $name dirty]} {
	alpha::menuAdjustDirtyCount -1
    }
}

proc deactivateHook {name} {
    hook::callForWin deactivateHook all $name $name

    # If we have no visible windows, then change to the empty mode.
    if {![alpha::frontmostAndActive]} {
	alpha::changeMode {}
    }
}

proc diskModifiedHook {name {mod 1} {diff 0}} {
    if {$mod} {
	set msg "File for window \"[file tail $name]\" has changed\
	  on disk since last save"
	if {$diff > 0} {
	    append msg " (the version on disk is older)"
	} elseif {$diff < 0} {
	    append msg " (the version on disk is newer)"
	}
	status::msg $msg
	hook::callAll diskModifiedHook 1 $name 1 $diff
    } else {
	# Unmodified (i.e. reverted)
	hook::callAll diskModifiedHook 0 $name 0 $diff
    }
}

# ## 
#  # -------------------------------------------------------------------------
#  # 
#  # "winChangeNameHook" --
#  # 
#  # <JK date="Feb2006"> This hook is deprecated, cf. RFE 1942.  Use
#  # [winChangedNameHook] instead.  To adopt the new hook, just interchange
#  # the order of the first two arguments.  Once there are no more hooks
#  # registered for the old [winChangeNameHook], the proc [hook::callForWin]
#  # can be simplified by removing the doubled winName argument. </JK>
#  # 
#  #  Called when a window's name is changing, either because it is being
#  #  saved to disk under a different name (i.e. 'saveAs'), or because
#  #  Alpha(tk) is changing the name internally for some reason.
#  #  
#  #  If called when the window is being saved to disk with a new name, the
#  #  new file on disk will exist, but the contents/size/details of that
#  #  file will not have been correctly set up (in fact most likely the
#  #  file is empty).
#  #  
#  #  This is also used by 'fileMovedHook', for the case where we do not
#  #  allow the mode to change.
#  # -------------------------------------------------------------------------
#  ##
# proc winChangeNameHook {oldName newName {allowModeChange 1}} {
#     if {$oldName eq $newName} return
# 
#     if {![win::Exists $oldName]} {
# 	alertnote "Core bug: unknown window \"$oldName\"\
# 	  given to winChangeNameHook."
#     }
# 
#     # Right now the window list is no longer valid.  So, let's fix that
#     # as quickly as possible.
#     win::nameChanged $oldName $newName
# 
#     if {$allowModeChange} {
# 	# This is tricky; we're saving the window with a new name, which
# 	# means we might wish to have the mode (and other attributes)
# 	# change, but it could also be that the window contents dictate the
# 	# mode, in which case we certainly don't want the mode to change.
# 	# This is particularly relevant with files with no extension in
# 	# which a 'unix mode' is used to determine the mode.  A file with
# 	# the new name doesn't yet exist.
# 	set modeNew [win::modeFromContents $newName]
# 	if {$modeNew eq ""} {
# 	    set modeNew [win::FindMode $newName]
# 	}
# 
# 	# Now we have to be a bit careful here.  This 'winChangeMode' is
# 	# going to update a bunch of global variables, which might have
# 	# traces associated with them.  These traces, in turn might want
# 	# to know what the front window is, but that is in the process
# 	# of being renamed!  This is why we have to carefully call
# 	# win::nameChanged above to ensure everything is set up for the new
# 	# front window, before calling winChangeMode.
# 	winChangeMode $newName $modeNew
#     }
#     
#     hook::callForWin winChangeNameHook all $newName $oldName $newName
# }

# Temporary redirect, until the core migrates from the [winChangeNameHook]
# to [winChangedNameHook]:
proc winChangeNameHook {oldName newName {allowModeChange 1}} {
    return [winChangedNameHook $newName $oldName $allowModeChange]
}


## 
 # -------------------------------------------------------------------------
 # 
 # "winChangedNameHook" --
 # 
 #  Called when a window's name has changed, either because it is being
 #  saved to disk under a different name (i.e. 'saveAs'), or because
 #  Alpha(tk) has changed the name internally for some reason.
 #  
 #  If called when the window is being saved to disk with a new name, the
 #  new file on disk will exist, but the contents/size/details of that
 #  file will not have been correctly set up (in fact most likely the
 #  file is empty).
 #  
 #  This is also used by 'fileMovedHook', for the case where we do not
 #  allow the mode to change.
 # -------------------------------------------------------------------------
 ##
proc winChangedNameHook {name oldName {allowModeChange 1}} {
    if {$oldName eq $name} {
	return
    }

    if {![win::Exists $oldName]} {
	alertnote "Core bug: unknown window \"$oldName\"\
	  given to winChangedNameHook."
    }

    # Right now the window list is no longer valid.  So, let's fix that
    # as quickly as possible.
    win::nameChanged $oldName $name

    if {$allowModeChange} {
	# This is tricky; we're saving the window with a new name, which
	# means we might wish to have the mode (and other attributes)
	# change, but it could also be that the window contents dictate the
	# mode, in which case we certainly don't want the mode to change.
	# This is particularly relevant with files with no extension in
	# which a 'unix mode' is used to determine the mode.  A file with
	# the new name doesn't yet exist.
	set modeNew [win::modeFromContents $name]
	if {$modeNew eq ""} {
	    set modeNew [win::FindMode $name]
	}

	# Now we have to be a bit careful here.  This 'winChangeMode' is
	# going to update a bunch of global variables, which might have
	# traces associated with them.  These traces, in turn might want
	# to know what the front window is, but that is in the process
	# of being renamed!  This is why we have to carefully call
	# win::nameChanged above to ensure everything is set up for the new
	# front window, before calling winChangeMode.
	winChangeMode $name $modeNew
    }
    
    hook::callForWin winChangedNameHook all $name $name $oldName
}


## 
 # -------------------------------------------------------------------------
 # 
 # "fileMovedHook" --
 # 
 #  Called by Alpha when a window's file has been moved or renamed
 #  behind our back.  Alphatk currently never calls this hook, since it
 #  doesn't ever know if a file has been moved by the OS -- AlphaTcl is
 #  robust to this hook never being called, but it is of course better
 #  for the user experience if AlphaTcl is aware of what the user has
 #  done (e.g. drag a file from one directory to another, or rename a
 #  file external to Alpha).
 #  
 #  Note that 'from' and 'to' should include any trailing ' <n>' for
 #  duplicate windows.
 #  
 # -------------------------------------------------------------------------
 ##
proc fileMovedHook {from to} {
    winChangedNameHook $to $from 0
}

## 
 # -------------------------------------------------------------------------
 # 
 # "activateHook" --
 # 
 #  Called when a window becomes frontmost (typically by
 #  'bringToFront').  Has primary responsibility for calling
 #  'alpha::changeMode' to ensure AlphaTcl's global state is
 #  synchronised with the front window, and for updating the
 #  text displayed in the various status-bar popup menus.
 #  
 # -------------------------------------------------------------------------
 ##
proc activateHook {name} {

    global encoding lineWrapStyles
    
    if {![win::Exists $name]} {
	alertnote "Bug found by 'activateHook $name', the mode for this\
	  window doesn't exist.  Please report this bug."
	return
    }
    # Change global mode and encoding
    alpha::changeMode [win::getMode $name] [win::getFeatureModes $name]

    displayEncoding [set encoding [win::Encoding $name]]
    displayMode [win::getMode $name 1]
    # Get window-specific wrap style.  
    if {[catch {win::getInfo $name linewrap} wrapStyle]} {
	set wrapStyle [win::getModeVar $name lineWrap]
    }
    displayWrap [string totitle [lindex $lineWrapStyles $wrapStyle]]

    getWinInfo -w $name arr
    
    switch -- [string tolower $arr(platform)] {
        "mac" {
	    set platform "Mac"
	}
        "unix" {
	    set platform "Unix"
	}
        "dos" {
	    set platform "DOS"
	}
        default {
	    set platform [string totitle $arr(platform)]
	}
    }
    catch {displayPlatform $platform}
    displayState $name

    # Check modification information, and adjust certain menu
    # dimming as appropriate.
    alpha::modifiedCheck $name
    
    hook::callForWin activateHook all $name $name
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "dirtyHook" --
 # 
 #  Called when a window's dirty state changes (just after it has 
 #  changed, where $dirty is the _new_ dirty state).
 #  
 #  '$dirty' may be anything that 'expr' can evaluate to true or false,
 #  so it could be "1", "0", "on", "off", etc.
 # -------------------------------------------------------------------------
 ##
proc dirtyHook {name dirty} {
    alpha::menuAdjustDirtyCount [expr {$dirty ? 1 : -1}]
    
    if {[alpha::frontmostAndActive $name]} {
	if {[win::IsFile $name]} {
	    alpha::menuAdjustForDirtiness -normal $dirty
	} else {
	    alpha::menuAdjustForDirtiness -notFile $dirty
	}
    }
    
    hook::callForWin dirtyHook all $name $name $dirty
}

## 
 # -------------------------------------------------------------------------
 # 
 # "characterInsertedHook" --
 # 
 # This hook is not called by 'insertText' or anything like that --- it
 # is just called by Alphatk/8/X core when the user makes a single
 # keypress into the current window, after that keypress has been
 # inserted.  It is also called after delete/backspace keypresses, in
 # which case this procedure is called with just 2 arguments (i.e. no
 # $char)
 # 
 # So, a single character has just been typed by the user and has been
 # inserted into the window.  The cursor ($pos) is now just after that
 # character.  Depending on the context, this proc may perform automatic
 # text wrapping.
 # 
 # This proc and the way it is called are still under evaluation.
 #  
 # -------------------------------------------------------------------------
 ##
proc characterInsertedHook {name pos {char ""}} {
    text::wrapLineCheck $name $pos $char
    hook::callForWin characterInsertedHook all $name $name $pos $char
    return
}

namespace eval text {}

proc text::wrapLineCheck {name pos {char ""}} {
    
    global autoWrapComments positionAfterIndentation
    
    # If the wrap attribute is set, and the cursor is far enough
    # along in the line:
    if {[catch {win::getInfo $name linewrap} wrapStyle]} {
	set wrapStyle [win::getModeVar $name lineWrap]
    }
    # If we're hard-wrapping, or if we want to auto-continue comments we
    # might need to insert a return.  In the latter case, we must first
    # find out where the return would be inserted before we can actually
    # check whether we're in a comment.
    if {($wrapStyle == 1) || $autoWrapComments} {
	# Hard-wrap
	if {($char eq "")} { 
	    # No special action with delete when hard-wrapping
	    return 
	}
	# Notice that we use '<= $fillColumn' here because we are
	# being called _after_ the character was inserted into the
	# window.
	if {[catch {win::getModeVar $name fillColumn} fillCol] \
	  || ([lindex [pos::toRowCol $pos] 1] <= $fillCol)} {
	    # No fill column preference, or the cursor not far enough
	    # along implies no wrapping.
	    return 
	}
	# The following does the job of finding the position at which
	# to wrap.
	set linepos [pos::lineStart $pos]
	set fillColPos [pos::fromRowCol\
	  [lindex [pos::toRowCol $pos] 0] $fillCol]
	#set wrapBreak [win::getModeVar $name wrapBreak {\S}]
	#set wrapBreakPreface [win::getModeVar $name wrapBreakPreface {\s}]
	#set wrapRE (${wrapBreakPreface})(${wrapBreak})
	set wrapRE {(\s)(\S)}
	set wraps\
	  [search -f 1 -r 1 -all -n -l $fillColPos -- $wrapRE $linepos]
	# The above search makes use of the fact that matches can
	# extend to characters beyond the limit position.
	if {![llength $wraps]} then {return}
	set wrappos [lindex $wraps end-1]
	regexp -- $wrapRE [getText $wrappos [lindex $wraps end]] "" prefix
	set wrappos [pos::math $wrappos + [string length $prefix]]

	# Now we've found the right position ($wrappos), check if we
	# need to continue a comment.
	if {[text::isInComment $wrappos prefix]} {
	    if {([pos::diff $linepos $wrappos] <= [string length $prefix])}\
	    then {
		# Since $prefix is at least as long as the pre-break part
		# of the previous line, there's no point in breaking.
		return
	    }
	    set replace "\r${prefix}[getText $wrappos $pos]"
	    replaceText $wrappos $pos $replace
	    goto [pos::math $wrappos + [string length $replace]]
	} elseif {($wrapStyle == 1)} then {
	    # We're hard-wrapping and we're not in a comment

	    if {[catch {search -r 1 -l $wrappos -- {\S} $linepos}]} then {
		# There are no non-whitespace characters on this line
		# before the chosen wrappos! Then don't break the line,
		# because all the text would be moved to the next line.
		return
	    }
	    set replace "\r[getText $wrappos $pos]"
	    replaceText $wrappos $pos $replace
	    goto [pos::math $wrappos + [string length $replace]]

	    if {[win::getModeVar $name indentOnReturn 0]} then {
		# Ensure that indentation doesn't adjust the relative
		# position of the cursor.
		set oldPAI $positionAfterIndentation
		set positionAfterIndentation 1
		bind::IndentLine
		set positionAfterIndentation $oldPAI
	    }
	}
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "changeTextHook" --
 # 
 #  Called when the contents of the current window change.  The second
 #  parameter shows how many changes have taken place, and is used to
 #  determine whether to auto-save the window.
 #  
 #  In Alphatk the second parameter is the size of the 'undo stack'.
 #  In Alpha 8/X the number of window changes is provided (how is
 #  this measured in Alpha 8/X?).
 # -------------------------------------------------------------------------
 ##
proc changeTextHook {name {numChanges 0}} {
    global numberOfChangesBeforeAutoSave
    if {$numberOfChangesBeforeAutoSave ne ""} {
	if {![string is integer -strict $numberOfChangesBeforeAutoSave] \
	  || $numberOfChangesBeforeAutoSave <= 1} {
	    alertnote "To activate auto-saving, you\
	      must specify a positive integer value for the 'Number\
	      Of Changes Before Auto Save' preference. I will set this\
	      to 50 for you (it must be larger than 1).\
	      See your 'Backup' preferences to change this."
	    set numberOfChangesBeforeAutoSave 50
	    prefs::modified numberOfChangesBeforeAutoSave
	}
	if {$numChanges > $numberOfChangesBeforeAutoSave} {
	    # Only auto-save windows which are already associated
	    # with a file on disk.  Otherwise this becomes a very
	    # annoying feature.
	    if {[win::IsFile $name]} {save $name}
	}
    }
    hook::callForWin changeTextHook all $name $name
}

proc revertHook {name} {
    # revertHook should only be called for windows which are files.
    if {[win::IsFile $name filename]} {
	win::setInfo $name Modified [file mtime $filename]
	diskModifiedHook $name 0
	
	if {[alpha::frontmostAndActive $name]} {
	    alpha::menuAdjustForDirtiness -normal 0
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "saveUnmodified" --
 # 
 # (This proc actually has nothing to do with hooks, but seemed to fit here)
 # -------------------------------------------------------------------------
 ##
proc saveUnmodified {} {
    if {![llength [winNames]]} {return}
    set wname [win::Current]
    if {[win::IsFile $wname name]} {
	set mod [file mtime $name]
	save
	# Update both AlphaTcl's Modified attribute and the file's
	# modification time, to ensure both are in sync.
	win::setInfo $wname Modified $mod
	file mtime $name $mod
	return
    }
    alertnote "$wname is not a file window."
}

## 
 # -------------------------------------------------------------------------
 # 
 # "saveACopyAs" --
 # 
 # (This proc actually has nothing to do with hooks, but seemed to fit here)
 # -------------------------------------------------------------------------
 ##
proc saveACopyAs {} {
    if {[win::IsFile [win::Current] origfile]} {
	set copy [putfile "Save a copy as:" $origfile]
	if {$copy == ""} { return }
	if {[file normalize $copy] eq [file normalize $origfile]} {
	    alertnote "You can't save a copy on top of the original!"
	    error "Cancelled"
	}
	if {[file exists $copy]} {file delete $copy}
	# Use 'file::coreCopy' to respect encodings of source and
	# destination.
	file::coreCopy $origfile $copy
    }
}

# ×××× Application-wide hooks ×××× #

# In the future we can have Alpha 8/X/tk call this if the user changes
# the screen geometry/resolution or whatever.
proc screenChangedHook {} {
    global screenWidth screenHeight

    foreach {screenWidth screenHeight} [getMainDevice] {}
    
    prefs::dialogs::setVariables 1
    return
}

proc quitHook {} {
    hook::callAll quitHook
    if {[catch {prefs::saveModified} err]} {
	if {[dialog::yesno \
	  "There was an error saving your preferences.\
	  Shall I quit anyway?\r(error: $err)"]} {
	    return
	}
	error "cancel"
    }
}

proc uninstall {{force 0}} {
    global alpha::application

    if {!$force} {
	set q "Are you sure you wish to remove ${alpha::application}\
	  from your system?"
	if {![dialog::yesno -n "Cancel" $q]} {
	    error "cancel"
	}
    }
    hook::register quitHook uninstallHook
    quit
}

proc uninstallHook {} {
    global alpha::application

    # Call any registered hooks
    hook::callAll uninstallHook
    # Delete all prefs
    prefs::deleteEverything
    
    # So we don't save any new prefs
    global skipPrefs
    set skipPrefs 2
    
    alertnote "All traces of ${alpha::application} have been removed\
      from your OS, and you may now delete the entire distribution."
    set show [file dirname $HOME]
    set try $show
    for {set i 0} {$i < 3} {incr i} {
	if {[regexp -- {\.(app|exe)$} $try]} {
	    set show $try
	    break
	}
	set try [file dirname $try]
    }
    file::showInFinder $show
}

## 
 # -------------------------------------------------------------------------
 # 
 # "suspendHook" --
 # 
 #  The parameter 'args' is not used, so please ignore it.
 # -------------------------------------------------------------------------
 ##
proc suspendHook {args} {
    hook::callAll suspendHook
}

## 
 # -------------------------------------------------------------------------
 # 
 # "resumeHook" --
 # 
 #  The parameter 'args' is not used, so please ignore it.
 # -------------------------------------------------------------------------
 ##
proc resumeHook {args} {
    # Check if any window needs to be have its modified status adjusted,
    # and calls all resumeModifiedHooks with the modified status (1 or 0)
    # as an extra argument.
    
    hook::callAll resumeHook
    
    foreach win [winNames -f] {
	# These hooks are registered against an actual window name
	# so the second argument being $win is correct here
	# (see e.g. spellcheck.tcl for an example)
	hook::callAll resumeModifiedHook $win $win [alpha::modifiedCheck $win]
    }
}

# ×××× Window opening sequence ×××× #

# Clients of the AlphaTcl library should call things as follows:
# 
# (1) Before opening a file window, the first step is to call
# 'filePreOpeningHook $filename $winname'  (this step is obviously
# skipped for non-file windows).
# 
# (2) When the window is created, and the appropriate structures
# are in place (so 'setWinInfo' works) call 'winCreatedHook $winname'
# (in Alphatk at least it is called after the window's contents
# are in place, but while the window is in a withdrawn state).  This
# will add the window to the list of known AlphaTcl windows (at the
# end of the list).
# 
# (3) Finally call 'registerWindowWithAlphaTcl' which will itself call
# 'alpha::openHook', 'windowVisibility' (which will normally call
# 'bringToFront' (which calls 'activateHook')), 'alpha::afterOpening'.
#
#
# We support the creation of windows which are hidden or iconified (and
# therefore not frontmost in the editor).  This is done by setting the
# 'visibility' attribute of a window early in its creation (typically by
# '-visibility <state>' being passed to edit/new).  There are three
# possible values: normal, hidden or minimized.  In the 'normal' case
# the window is brought to front (and becomes [win::Current]) , but in
# the other two cases the new window is left at the end of the list of
# open windows.
#
# Current development code is available to provide better support for
# hidden and iconified windows, which implies a mode="" even when we
# have open windows if none of them are normal windows.  This requires
# the ability for things like the status bar menus to disappear even
# though we have open windows (just when all of them are
# iconified/hidden).  Alphatk supports this at present.  It needs 
# testing with Alpha 8/X.

## 
 # -------------------------------------------------------------------------
 # 
 # "filePreOpeningHook" --
 # 
 #  Called by Alpha(tk)'s core inside things like 'edit' just before
 #  we read in and open a file. 'name' is the name of the file on disk,
 #  'winname' is the name of the window we will use (e.g. it may have
 #  trailing <2>...), but that window will not yet exist at all.
 #  
 #  The idea is that we can use this proc and the hooks it calls
 #  to set the window's mode, to adjust tab-size, encoding, etc, before
 #  the window is properly created, and before the contents of the
 #  file are read in (this is particularly important if we want to
 #  set a particular encoding to use for that reading!).  We call
 #  'win::setInitialConfig' with the future name of the window when we
 #  want to set any of these details.
 # -------------------------------------------------------------------------
 ##
proc filePreOpeningHook {name winname} {
    global defaultEncoding
    
    set m [file::preOpeningConfigurationCheck $name $winname]

    if {$m ne ""} {
	win::setInitialConfig $winname mode $m "window"
    } else {
	set m [win::FindMode $name]
	win::setInitialConfig $winname mode $m "mode"
    }
    set encoding [alpha::encodingFor $name]
    if {$encoding eq "" && [info exists defaultEncoding]} {
	set encoding $defaultEncoding
    }
    win::setInitialConfig $winname encoding $encoding "global"

    set m [win::getInitialConfig $winname mode]
    
    if {$::alpha::macos != 0} {
	win::mpsrCheck $winname
    } 
    
    hook::callAll preOpeningHook $m $winname
    return 0
}


## 
 # -------------------------------------------------------------------------
 # 
 # "winCreatedHook" --
 # 
 #  Called by Alpha(tk)'s core as soon as the window structures are
 #  created so that 'setWinInfo' can work.
 #  
 #  Note that, in most respects, the window does not yet exist, but the
 #  contents of the window are probably already known and fixed,
 #  although they are not accessible to this procedure (e.g. if it is a
 #  file on disk, we do *not* have an opportunity here to influence the
 #  encoding with which that is read, but, for example, we could change
 #  the tabsize here, before the window is shown to the user).
 #  
 #  Really the _only_ thing this procedure should do to the window
 #  is call win::setInfo.
 #  
 #  This proc can be used to set any characteristics of the window
 #  which we somehow determined were necessary while it was being
 #  opened/created (e.g. mode-dependent values).
 #  
 #  IMPORTANT: When this proc is called (or immediately on its return)
 #  the new window should exist in the 'winNames -f' list.  This
 #  means we must synchronise everything in AlphaTcl for the existence
 #  of this window.  This is handled by win::created.
 #  
 #  Any window that passes through 'winCreatedHook' _must_ eventually
 #  end up in closeHook when it is destroyed (even if an internal error
 #  occurs after winCreatedHook which aborts the window creation, the
 #  core must still call closeHook if AlphaTcl is to maintain a 
 #  consistent state).
 # 
 # -------------------------------------------------------------------------
 ##
proc winCreatedHook {winname} {
    
    # Critically, this must set {$attributes mode} and the values of
    # the 5 core window attributes
    set attributes [win::getAndReleaseInitialInfo $winname]

    # Create AlphaTcl's internal attribute storage for this window
    # and place the window into the active list.
    win::created $winname
    
    # This is where the 'mode' attribute of a window is set.
    # 
    # This is also where the core learns a 'bindtags' and a 'colortags'
    # and a 'wordbreak' for the window.  The core of Alphatk (and
    # largely Alpha 8/X) has no interest in AlphaTcl's concept of a
    # 'mode' at all, since all core-relevant mode behaviours are defined
    # by those three pieces of information.
    eval [list win::setInfo $winname] $attributes    
}

# We may wish to add some error handling to this procedure, since if it
# fails we may be in some trouble.
proc registerWindowWithAlphaTcl {name} {
    
    if {[catch {win::getInfo $name visibility} visibility]} {
	set visibility "normal"
    } else {
	win::freeInfo $name visibility
    }

    # Performs forceMainScreen, calls requireOpenWindowsHooks and 
    # anything else registered, perhaps a hook might wish to change mode.
    alpha::openHook $name
    
    if {![win::Exists $name]} {
	# The window was deleted in an openHook
	return
    }
    
    # If visibility is 'normal' this is exactly equivalent to
    # 'bringToFront' (which will therefore call activateHook and change 
    # the current $mode).  Other cases are 'hidden' or 'minimized'.
    windowVisibility -w $name $visibility
    
    if {![win::Exists $name]} {
	# The window was deleted in an activateHook
	return
    }
    
    # Performs auto-marking and anything else registered.
    alpha::afterOpening $name
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::openHook" --
 # 
 #  This function will be called (by registerWindowWithAlphaTcl), and
 #  should function whether the given name is the frontmost window or
 #  whether it is a window being opened into the background.
 #  
 #  One important side-effect of this procedure is that if the window is
 #  a file which exists on disk, and if the modification time can be
 #  read, then this function will always store the modification time as
 #  an alphatcl-window attribute.  This, together with the fact that on
 #  saving AlphaTcl also sets/updates the modified attribute, means that
 #  other code can assume that if the modified attribute exists for a
 #  window, it is equivalent to the fact that the window is associated
 #  with a file that Alpha ought to be able to manipulate.
 #  
 #  Note: we should probably make 'forceMainScreen' a package and remove
 #  it from here.  However -- it's clear there may be conficts between
 #  such a change and the idea that some other openHook (inst mode, say)
 #  may also wish to change window position (in Inst mode's case to move
 #  the window a long-way offscreen).  This would impose a sequence
 #  dependence we need to resolve.
 #  
 #  Strictly speaking, since this can be called whether or not the
 #  given window is frontmost, each mode's <mode>::MarkFile should
 #  also be happy with both cases (which means its mode variables may
 #  not have been copied to global).
 # -------------------------------------------------------------------------
 ##
proc alpha::openHook {name} {
    global forceMainScreen PREFS

    status::msg ""
    
    if {![win::Exists $name]} {
	# Window already closed -- likely to be killWindow inside 
	# activateHook, if we allow activateHook to be called before
	# openHook.
	return
    }
    
    if {[win::IsFile $name nm]} {
	if {![catch {getFileInfo $nm info}]} {
	    if {[info exists info(creator)] && ($info(creator) == {ttxt})} {
		setWinInfo -w $name dirty 0
	    }
	    if {[info exists info(type)] && ($info(type) == {ttro})} {
		catch {setWinInfo -w $name read-only 1}
		status::msg "Read-only!"
	    }
	}
	# Tcl 8.5 only
# 	if {![catch {file attributes $nm -creator} creator] \
# 	  && ($creator eq "ttxt")} {
#             setWinInfo -w $name dirty 0
#         }
# 	if {![catch {file attributes $nm -type} type] && ($type eq "ttro")} {
#             catch {setWinInfo -w $name read-only 1}
#             status::msg "Read-only!"
#         }
	win::setInfo $name Modified [file mtime $nm]
    }
    
    set m [win::getMode $name]
    # Ensure we can access the modeVars, even if this window
    # isn't frontmost and therefore the mode might never have
    # been loaded.
    loadAMode $m
    # Set the 'wrap style' of the window
    win::setInfo $name linewrap [win::getModeVar $name lineWrap 0]
    # Call this as soon as the mode has been loaded
    alpha::menuAdjustForOpenWins 1

    if {$forceMainScreen} {
	global locationOfStatusBar screenHeight screenWidth \
	  statusbarHeight pixelOffsetFromBottomOfWindow menubarHeight
	set topOffset [expr {$menubarHeight \
	  + $locationOfStatusBar * $statusbarHeight}]
	set bottomOffset [expr {$pixelOffsetFromBottomOfWindow \
	  + (1 - $locationOfStatusBar) * $statusbarHeight}]
	foreach {sl st sw sh} [getGeometry -s $name] {break}
	# Check if:
	# - window border is off the left side
	# - window top border is too high (overlapping menubar (or statusbar))
	# - window border is off right side
	# - window bottom border is too low (off bottom of screen or
	# overlapping status bar if that's at the bottom)
	if {($sl < 0) \
	  || ($st < $topOffset) \
	  || (($sl + $sw) > $screenWidth) \
	  || (($st + $sh + $bottomOffset) > $screenHeight)} {
	    defaultSize $name
	}
    }
    
    if {[file::pathStartsWith $name $PREFS relative]} {
	if {[string match "*defs.tcl" $relative]} {
	    setWinInfo -w $name read-only 1
	}
    }
    
    hook::callForWin openHook all $name $name
    return
}

proc alpha::afterOpening {name} {
    if {[win::getModeVar $name autoMark 0]} {
	if {![llength [getNamedMarks -w $name -n]]} {
	    markFile -w $name
	}
    }
    status::msg $name
}

proc winCollapsedHook {name} {
}

proc winExpandedHook {name} {
}

# ×××× Changing the mode ×××× #

# This procedure carries out the steps necessary to change the mode
# associated with a particular window.  If that window happens to be the
# frontmost one (and is not hidden/minimized), then we also change the
# global $mode by calling alpha::changeMode.
# 
# This procedure is called both by 'winChangedNameHook' (which itself is
# called by saveAs) if that results in the mode changing, and by the
# mode-popup menu in the status bar, if the user clicks there to change
# the mode.  It is also called by procedures like win::ChangeMode and
# the rememberWindows package.
proc winChangeMode {name newMode} {
    set oldmode [win::getMode $name]
    
    if {$oldmode eq $newMode} {
	return
    }
    
    # Ensure the new mode is loaded
    loadAMode $newMode
    
    # This is where the core learns a new mode, and many other useful
    # attributes: 'featuremodes', 'bindtags' and 'colortags' for the
    # window, which will automatically recolor it, and a new wordbreak.
    win::setInfo $name mode $newMode
    
    # For each of these attributes, replace the old mode name with the
    # new mode name, if it exists in that attribute value list.  If the
    # old mode name doesn't exist, then don't change that attribute.
    foreach attr {varmodes hookmodes bindtags colortags featuremodes} {
	set val [win::getInfo $name $attr]
	set oldindex [lsearch -exact $val $oldmode]
	if {$oldindex != -1} {
	    win::setInfo $name $attr \
	      [lreplace $val $oldindex $oldindex $newMode]
	}
	if {$attr eq "varmodes"} {
	    # We want to set varmodes first, then wordbreak and later 
	    # colortags.  The changing of colortags will recolour the
	    # window, but that will make use of the new wordbreak
	    # definition.
	    win::setInfo $name wordbreak [win::getModeVar $name wordBreak]
	}
    }
    
    # Only change mode if it was the frontmost window, and it is
    # not hidden or minimized
    if {[alpha::frontmostAndActive $name]} {
	alpha::changeMode $newMode [win::getInfo $name featuremodes]
    }

    hook::callAll winChangeModeHook * $name $oldmode $newMode
    refresh -w $name
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::changeMode" --
 # 
 #  A very important procedure which is private to this file.  It
 #  handles all switching from one mode to another.  This is _not_ a
 #  procedure which should be called by packages/extensions or indeed
 #  any other part of AlphaTclCore.  To change the mode associated with
 #  the current window, call win::ChangeMode.
 #  
 #  What does it mean to change mode?  Modes store variables in a
 #  <mode>modeVars array, and have certain packages (menus/features)
 #  associated with them.  Also floating windows can be mode-specific.
 #  
 #  So, what we do is first is call a 'changeModeFrom' hook to let
 #  any code know that a given mode is being switched out.
 #  
 #  Second, we get rid of the last mode, which involves removing any
 #  lastmode-specific floating windows, restoring or removing any global
 #  variables set from <lastmode>modeVars, and deactivating any features
 #  which will no longer be required for the new mode (we calculate a
 #  difference-list so we never deactivate a feature only to activate it
 #  a few lines of code later).
 #  
 #  Third we load the new mode (call its init script which usually means
 #  we source its main file), the result of which is that we must have
 #  evaluated all 'newPref' commands (strictly speaking it is ok to
 #  call newPref later as well, but that's not good practice).
 #  
 #  Finally we call any newmode-init script (and any mode-init hooks) if
 #  this is the first time the mode is loaded, then we copy over
 #  <newmode>modeVars (remembering any global vars which are shadowed),
 #  activate all new features, show any newmode-specific floating menus.
 #  If it's the first time the mode is loaded, we'll source the user's
 #  <newmode>Prefs.tcl and lastly call 'changeMode' hooks.
 #  
 #  The first argument must _always_ be a real mode.  The second
 #  optional argument is a list of featuremodes which are associated
 #  with the current window (typically just a list with one element -
 #  the same as the first argument).
 #  
 #  AlphaTcl stores the last mode ($::mode) and last set of extra
 #  feature-modes ($::featureModes) and compares those with the new
 #  values.  These two sets of information are then used to determine
 #  whether (a) the global mode needs changing, and (b) whether the
 #  feature-modes have changed.  In either case we must then determine
 #  the set of packages/features which need to be activated and
 #  deactivated to complete the change.
 #  
 # -------------------------------------------------------------------------
 ##
proc alpha::changeMode {newMode {newFeatureModes ""}} {
    global mode featureModes
	
    displayMode [mode::getName $newMode 1]

    if {$mode eq $newMode} {
	# Adjust feature modes, if needed.  We don't need to do 
	# anything with mode-variables since the global $mode isn't
	# changing.
	if {([llength $newFeatureModes] != [llength $featureModes]) \
	  || ($newFeatureModes ne $featureModes)} {
	    # Even though the first argument of these two lists is
	    # likely to be the same, we need to pass in the full list,
	    # because that does influence the results (see
	    # modesPackages.test)
	    set onoff [package::onOrOff $featureModes $newFeatureModes]
	    set featureModes $newFeatureModes
	    eval [list package::deactivate] [lindex $onoff 0]
	    eval [list package::activate] [lindex $onoff 1]
	}
	return
    }

    set lastMode $mode

    # Remove all evidence of the old mode
    # and set the global $mode value to ""
    alpha::removePreviousMode $lastMode $newMode
    set mode ""
    set onoff [package::onOrOff $featureModes $newFeatureModes]
    set featureModes $newFeatureModes
    eval package::deactivate [lindex $onoff 0]
    
    # Ensure all <mode>modeVars are loaded.
    loadAMode $newMode
    
    # Change the global $mode value.
    set mode $newMode
    # Now make all relevant changes we need.
    if {$newMode ne ""} {
	set NewMode [mode::getName $newMode 1]
	renameMenuItem -m Config "Mode Prefs" "$NewMode Mode Prefs"
	catch {alpha::menuEnableForActiveWindow 1}
    } else {
	catch {alpha::menuEnableForActiveWindow 0}
    }
    alpha::finishChangingMode $newMode [lindex $onoff 1]
}

proc alpha::removePreviousMode {lastMode newMode} {
    global alpha::changingMode alpha::changingModeFrom
	
    if {${alpha::changingMode}} {
	# This is not something that should happen.  However, it can
	# happen if:
	# 
	# (i) a badly constructed mode is being loaded for the first
	# time due to a 'alpha::changeMode $badmode', but then during
	# startup the mode decides it wants to switch mode (for some
	# unfathomable reason).
	# 
	# (ii) 'loadAMode' was aborted by the user, or Tcl detected an
	# infinite recursion in loadAMode (i.e. anything which prevents
	# this procedure from completing all its tasks, ending with a
	# call to alpha::finishChangingMode).
	# 
	# These are quite different cases, but perhaps we can work out
	# which case is occurring and do our best to fix the situation.
	# 
	# In case (i) I think it is ok to throw an error, since we
	# really don't want a mode to change mode while starting up,
	# and mild rewrites of the mode should fix the problem.  After
	# the error is thrown, AlphaTcl will end up in a normal state.
	# 
	# For (ii) we ought to try to fix things, since the flag
	# alpha::changingMode is never going to be unset, and so
	# AlphaTcl is now in an unusable state.
	set msg "A mode or package is causing a serious problem.\
	  It is illegal to change mode while we\
	  are already in the process of changing mode\
	  (currently changing from mode ${alpha::changingModeFrom}\
	  to $lastMode, attempted mode $newMode)."
	alertnote $msg
	# If we don't return, global variables could get mangled below.
	return -code error $msg
    }
    # Some code would like to know whether we're in the process
    # of changing mode or not (e.g. complex package activation/deactivation
    # sequences).
    set alpha::changingMode 1

    set alpha::changingModeFrom $lastMode
    
    # Call a changeModeFrom hook to inform code of what mode
    # we're just leaving.  This takes as an argument the mode
    # we're leaving. The code can examine $mode to determine
    # the new mode
    hook::callAll changeModeFrom $lastMode $lastMode $newMode
    
    if {$lastMode != ""} {
	set LastMode [mode::getName $lastMode 1]
	renameMenuItem -m Config "$LastMode Mode Prefs" "Mode Prefs"
    }
    
    floatShowHide off $lastMode

    # If the lastMode was empty, then we have no modeVars or 
    # globally-saved variables to reset.
    if {$lastMode ne ""} {
	# Get rid of all the old mode's variables, either replacing 
	# them with the previous (global values) they over-wrote,
	# or unsetting them if no such global values exist.
	globalVarsRemoveFromMode $lastMode
    }
}

proc alpha::finishChangingMode {newMode newPkgs} {
    global seenMode 
    
    if {$newMode eq ""} {
	# When we're switching to the empty mode (i.e. no open windows 
	# at all), we only need to do a few simple things:
	# 
	# Note that the $newPkgs list will generally be empty, unless
	# we have modes that disable packages which are on globally. In
	# this case such pkgs must be re-enabled when that mode goes 
	# away.  This is what we do here.

	if {![info exists seenMode($newMode)]} {
	    eval package::initialise $newPkgs
	    set seenMode($newMode) 1
	}
	eval package::activate $newPkgs
    } else {
	if {![info exists seenMode($newMode)]} {
	    eval package::initialise $newPkgs
	    hook::callAll mode::init $newMode
	    set NewMode [mode::getName $newMode 1]
	    status::msg "loading mode ${NewMode}É complete"
	}
	# once the vars are in mode-var scope (= the <mode>modeVars array),
	# they can be transfered to the global scope.  We may wish to
	# change this design in the future and use namespace variables
	# directly, but that would be a major overhaul.
	global ${newMode}modeVars
	globalVarCopyFromMode $newMode [array get ${newMode}modeVars]
	floatShowHide on $newMode

	eval package::activate $newPkgs

	if {![info exists seenMode($newMode)]} {
	    set seenMode($newMode) 1
	    global PREFS
	    set mprefs [file join $PREFS ${newMode}Prefs.tcl]
	    if {[file exists $mprefs]} {
		if {[catch {uplevel \#0 [list source $mprefs]} err]} {
		    alertnote "Your preferences file '${newMode}Prefs.tcl\
		      has an error: $err"
		} 
	    }
	}

    }
    # Reset these two.
    global alpha::changingMode alpha::changingModeFrom
    set alpha::changingMode 0
    set alpha::changingModeFrom ""
    
    hook::callAll changeMode $newMode $newMode
}

# ×××× Overriding globals with mode vars ×××× #

# These four procs must obviously be kept in sync with each other.
# Their internal data structures (the global::_varMem array) are
# totally private.

# This procedure is used to check whether a global variable
# is currently shadowed by a mode var. 
proc globalVarIsShadowed {var} {
    global global::_varMem
    info exists global::_varMem($var)
}

# Works just like 'set' but for a global variable which
# is currently hidden/shadowed by a mode-specific variable.
proc globalVarSet {var args} {
    global global::_varMem
    eval [list set global::_varMem($var)] $args
}

# This is normally called once when changing mode, but may also be
# called in newPref if new mode prefs are declared later.  It must
# accumulate information on all such changes.
proc globalVarCopyFromMode {m keysVals} {
    global global::_varMem global::_keyList
    foreach {v val} $keysVals {
	global $v
	if {[info exists $v] && ![info exists global::_varMem($v)]} {
	    set global::_varMem($v) [set $v]
	}
	set $v $val
	# We actually remember the set of keys used, in case some code
	# out there removes some of them before this mode goes away.
	lappend global::_keyList $v
    }
}

# Remember that 'unset' will remove all variable traces, so only do that
# if necessary (i.e. if we're not restoring to a previous global value).
proc globalVarsRemoveFromMode {m} {
    global global::_varMem global::_keyList
    # First remove all the variables that are no longer relevant
    if {[info exists global::_keyList]} {
	foreach v $global::_keyList {
	    if {![info exists global::_varMem($v)]} {
		global $v
		unset -nocomplain $v
	    }
	}
    }
    # Second, restore the values of all the ones that we overwrote.
    foreach {v val} [array get global::_varMem] {
	global $v
	set $v $val
    }
    unset -nocomplain global::_varMem global::_keyList
}

# ×××× Core popup menus ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "contextualMenuHook" --
 # 
 # Calls any item registered with
 # 
 # hook::register contextualMenuHook <procName>
 # 
 # and passes it along.  The value for '$pos' is determined by the core. 
 # Also creates an "alpha::CMArgs" variable which contains a four item list
 # of the CM click position, start and end positions of selection including
 # CM click position, and the selectionDesc.
 # 
 # If there is no selection, or if the selection doesn't include the CM
 # click position, all three positions are the same.  (Any CM menu item can
 # still check to see if there's a selection if desired using
 # 'isSelection'.)
 # 
 # -------------------------------------------------------------------------
 # 
 # What's up with '$selectionDesc' ??
 # 
 # $selectionDesc is an identifier that, when passed to TclAE routines,
 # gives you access to the AppleEvent internals:
 # 
 # ÇAlpha8È tclAE::createDesc null
 # tclAEDesc.3
 # ÇAlpha8È tclAE::print tclAEDesc.3
 # 'null'()
 # ÇAlpha8È tclAE::getData tclAEDesc.3
 # ÇAlpha8È tclAE::getDescType tclAEDesc.3
 # null
 # ÇAlpha8È tclAE::disposeDesc tclAEDesc.3
 # ÇAlpha8È tclAE::getData tclAEDesc.3
 # Error: Couldn't find "tclAEDesc.3": OSErr -1701, errAEDescNotFound
 # 
 # In this case, this is a null AppleEvent descriptor; i.e., it contains
 # no data at this point.  The idea is that if your CM handlers decide
 # that the context (as initially defined by the positions) has some
 # more abstract representation, they stuff what they like into
 # $selectionDesc.  Once all Alpha's CM handlers are done putting
 # whatever they like into $selectionDesc, it gets returned to the CMM
 # to pass on to any external CMM handlers (like FinderPop) to process
 # as they see fit (generally by calling back to Alpha and asking for
 # the descriptor to be resolved to a piece of text).
 # 
 # Jon Guyer
 # 
 # [Note: obviously none of this 'TclAE' stuff applies if we're not
 # running on MacOS]
 # -------------------------------------------------------------------------
 ##

set alpha::CMArgs [list]

proc contextualMenuHook {pos} {
    global menu::additions mode alpha::CMArgs
    
    # Determine positions for CM click (pos) and any selected text that
    # might surround the click position.  If no selection, or if the
    # selection doesn't include 'pos', all three positions are the same.
    set pos0 [getPos]
    set pos1 [selEnd]
    if {[pos::compare $pos < $pos0] || [pos::compare $pos > $pos1]} {
	# The selection does not include the click position
	set pos0 [set pos1 $pos]
    } 
    
    # Create the list of CM arguments, and reset list of menu items.
    set menuName "c™–tŽxtŸŒlMenu"
    global alpha::macos
    if {${alpha::macos}} {
	set selectionDesc [tclAE::createDesc null]
    } else {
	set selectionDesc {}
    }
    set alpha::CMArgs [list $pos $pos0 $pos1 $selectionDesc]
    set menu::additions($menuName) [list]
    
    # We pass on all of the "alpha::CMArgs" in case the CM hook wants them,
    # although they're also available now as a global variable.  All that the
    # called hook has to do is add to the list of menu items (i.e. lappend to
    # the "menu::additions(c™–tŽxtŸŒlMenu)" array item, and we take care of
    # actually building the menu here.
    eval [list hook::callAll contextualMenuHook $mode $menuName] \
      [set alpha::CMArgs]
    menu::buildSome $menuName
    eval [list hook::callAll contextualPostBuildHook $mode $menuName] \
      [set alpha::CMArgs]
    return [list $menuName $selectionDesc]
}

proc vcsMenuHook {} {
    
    global alpha::platform
    
    if {![win::IsFile [set w [win::Current]]]} {
	if {(${alpha::platform} eq "alpha")} {
	    # The core will automatically toggle the read-only state of the
	    # window _after_ we return.
	    status::msg "The window \"$w\" is\
	      [expr {[win::getInfo $w read-only] ? "no longer" : "now"}]\
	      locked."
	    return -code return
	} else {
	    set msg "Cancelled -- the window \"$w\" doesn't exist as a file."
	    status::msg $msg
	    error $msg
	}
    } elseif {[package::active versionControl]} {
	menu::buildOne vcsMenu
	return "vcsMenu"
    } else {
	status::msg "The VCS popup menu requires the\
	  \"Version Control\" package."
	return ""
    }
}

proc marksMenuHook {} {
    unset -nocomplain ::menu::additions(marksMenu)

    menu::buildOne marksMenu
    
    return "marksMenu"
}
menu::buildProc marksMenu buildMarksMenu    

if {$::alpha::macos == 1} {
    # Workaround for Bug 867.  Alpha 8 (at least in classic) must have
    # each window with its own Marks menu.
    proc marksMenuHook {} {
	unset -nocomplain ::menu::additions(marksMenu)
	
	set marksMenu "[win::CurrentTail] Marks"
	if {[string length $marksMenu] > 40} {
	    set marksMenu \
	      "[string range $marksMenu 0 20]\u2026\
	      [string range $marksMenu [expr {[string length $marksMenu]-18}] end]"
	} 
	
	menu::buildProc $marksMenu buildMarksMenu    
	menu::buildOne $marksMenu
	
	return $marksMenu
    }
}

proc parseMenuHook {} {
    unset -nocomplain ::menu::additions(parseMenu)
    menu::buildOne parseMenu
    return "parseMenu"
}
menu::buildProc parseMenu buildParseMenu

## 
 # --------------------------------------------------------------------------
 # 
 # "modeMenuHook" --
 # "wrapMenuHook" --
 # "fileInfoMenuHook" --
 # "encodingMenuHook" --
 # 
 # All of these hooks are called by the core when the user clicks on the
 # status bar pop-up menus.  We need to ensure that the current list of menu
 # items (menu::additions) is empty, and then call any registered menu build
 # hooks.  See "statusPopupMenus.tcl" for more information.  
 # 
 # --------------------------------------------------------------------------
 ##

proc modeMenuHook {} {
    menu::buildSome "modeMenu"
    return "modeMenu"
}
proc wrapMenuHook {} {
    menu::buildSome "wrapMenu"
    return "wrapMenu"
}
proc fileInfoMenuHook {} {
    menu::buildSome "fileInfoMenu"
    return "fileInfoMenu"
}
proc encodingMenuHook {} {
    menu::buildSome "encodingMenu"
    return "encodingMenu"
}

# ×××× Menu Enabling and Disabling ×××× #

# Helper procedure to determine if the given window $name (or the
# frontmost window if none is given) is both frontmost and _not_ a
# hidden/minimized window.  Return 1 if this is true, zero otherwise.
# 
# Typically this is used so that, if true, we should adjust menu-dimming
# based upon the status/attributes of that window.
proc alpha::frontmostAndActive {{name ""}} {
    if {$name eq ""} {
	set name [win::Current]
	if {$name eq ""} { return 0 }
    }
    # Is the given window frontmost and active
    return [expr {$name eq [win::Current] \
      && [windowVisibility -w $name] eq "normal"}]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::menuAdjustForOpenWins" --
 # 
 #  En-/disable meaningless menu items which would require the presence
 #  of a certain number of windows to be active
 #  
 #  This proc should only be called from 'alpha::openHook' and 'closeHook'.
 #  
 #  You can register with it using 
 #  
 #  'hook::register requireOpenWindowsHook [list menu item] N'
 #  
 #  where 'N' is the number of windows required (1 or 2 usually)
 #  (and deregister etc using hook::deregister).
 #  
 #  We only really need the catch in here for two reasons:
 #  (i) in case bad menus are registered accidentally
 #  (ii) so startup errors can open a window without hitting another error
 #  in the middle of doing that!
 # -------------------------------------------------------------------------
 ##
proc alpha::menuAdjustForOpenWins {adding} {
    set numWins [llength [winNames -f]]
    
    if {!$adding} {
	incr numWins
    }
    # To understand why this line works for all cases, one must realise
    # that when adding windows, the only items to be enabled are the
    # ones which depend on the exact number of windows currently open
    # (items which depend on fewer windows will already be active).
    # Similarly when closing windows, the only items to be disabled
    # are those which depend on one more window than we currently
    # have.
    foreach i [hook::information requireOpenWindowsHook $numWins] {
	if {[catch "enableMenuItem $i $adding"]} {
	    # Uncomment for testing/debugging
	    #alpha::stderr "requireOpenWindowsHook error: $i"
	}
    }
}

# Called only at startup.
proc alpha::performInitialMenuDimming {} {
    # First, perform core menu dimming
    catch {alpha::menuEnableForActiveWindow [alpha::frontmostAndActive]}
    
    alpha::menuAdjustDirtyCount 0
    
    # Second, deal with all registered 'requireOpenWindowsHook' items

    # Let's assume that, if windows have been opened, that 
    # requireOpenWindowsHook has been called in the openHook each
    # time.  This means we only need to deal with the fact that there
    # may be hooks for more windows than we have currently open.
    # To deal with these we need to know the highest number of 
    # the registered hook, and then go from that point downwards to
    # the current number of windows.

    set numWins [llength [winNames -f]]
    set regArr [hook::information requireOpenWindowsHook]
    set max [lindex [lsort -dictionary [dict keys $regArr]] end]
    while {$max > $numWins} {
	if {[dict exists $regArr $max]} {
	    foreach i [dict get $regArr $max] {
		catch "enableMenuItem $i 0"
	    }
	}
	incr max -1
    }
}

# This can be used to run all of the registered requireOpenWindowsHooks
# which are relevant just to the given menuName.
proc alpha::performDimmingForMenu {menuName} {
    set numWins [llength [winNames -f]]
    set regArr [hook::information requireOpenWindowsHook]
    set max [lindex [lsort -dictionary [dict keys $regArr]] end]
    while {$max > $numWins} {
	if {[dict exists $regArr $max]} {
	    foreach i [dict get $regArr $max] {
		# Here $i is a list of two or three elements.  If three
		# then there is a '-m' at the start.  Hence the menu
		# name is at end-1.
		if {[lindex $i end-1] eq $menuName} {
		    catch "enableMenuItem $i 0"
		}
	    }
	}
	incr max -1
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::menuEnableForActiveWindow" --
 # 
 #  This hook is called to turn menu items on or off.  It is called 
 #  whenever we go from 0->1 or 1->0 _active_ windows.  An active window
 #  is a window which is neither hidden nor minimized (i.e. a regular
 #  editing window we can see).
 #  
 #  It should deal with all standard menus.  It does not deal with
 #  special menu items like 'save', 'revert',.. which require more
 #  information.
 #  
 #  It is called from alpha::changeMode.
 #  
 #  Andreas wrote most of this proc.
 #  
 #  Due to a deficiency in MacOS/MercutioMDEF/Alpha (not sure who
 #  the culprit is!), key-bindings attached to menu items are still
 #  triggered even if the menu item is inactive.
 # -------------------------------------------------------------------------
 ##
proc alpha::menuEnableForActiveWindow {{haveWin 1}} {

    enableMenuItem File close $haveWin
    enableMenuItem File saveAsÉ $haveWin
    enableMenuItem File saveACopyAsÉ $haveWin
    if {[package::active printerChoicesMenu]} {
	enableMenuItem File print $haveWin
    } else {
	enableMenuItem File printÉ $haveWin
	enableMenuItem File printAll $haveWin
    }
    eval [lindex [list un {}] $haveWin]Bind 'p' <c> print

    enableMenuItem Edit "" $haveWin
    enableMenuItem Text "" $haveWin

    global mode
    if {$mode == ""} {
	enableMenuItem -m Config "Mode Prefs" $haveWin
    } else {
	set Mode [mode::getName $mode 1]
	enableMenuItem -m Config "$Mode Mode Prefs" $haveWin
    }
    
    enableMenuItem Search placeBookmark $haveWin
    enableMenuItem Search returnToBookmark $haveWin
    enableMenuItem Search gotoLine $haveWin
    enableMenuItem Search matchingLinesÉ $haveWin
    enableMenuItem Search nextMatch $haveWin
    enableMenuItem Search gotoFunc $haveWin
    enableMenuItem Search gotoFileMark $haveWin
    enableMenuItem Search namedMarks $haveWin
    enableMenuItem Search thePin $haveWin
    
    enableMenuItem Utils asciiEtc $haveWin
    enableMenuItem Utils cmdDoubleClick $haveWin
    enableMenuItem Utils winUtils $haveWin
    enableMenuItem Utils wordCount $haveWin
    
    if {!$haveWin} {
	alpha::menuAdjustForDirtiness -nothingActive 0
    }
    enableMenuItem fileUtils showInFinder $haveWin
    
    # These items are dimmed/enabled depending on whether we
    # have any windows open (even if they are hidden/minimized).
    set anyWindows [expr {[llength [winNames -f]] != 0}]
    enableMenuItem File closeAll $anyWindows
    if {![package::active printerChoicesMenu]} {
	enableMenuItem File printAll $anyWindows
    }
    return
}

# We call this to set the menu-enable state of a number of key menu
# items relating to files and saving.  There are three primary ways in
# which we will call it: for a non-file window (or with no active
# windows), for a normal file window and for a file window where the
# file on disk has been modified.
# 
# This is the only proc which should adjust these menu items
# with the only current exception being 'savePostHook' which
# fixes up the 'renameTo...' menu item.
# 
# This proc must only _ever_ be called when we wish to adjust
# these based upon information from the _frontmost_ window.
# 
# Note that $dirty may be anything that 'expr' can evaluate to
# true or false.
proc alpha::menuAdjustForDirtiness {type dirty} {
    switch -- $type {
	"-normal" {
	    enableMenuItem File save $dirty
	    enableMenuItem File revertToSaved $dirty
	    enableMenuItem File saveUnmodified $dirty
	    enableMenuItem File renameToÉ [expr {!$dirty}]
	}
	"-nothingActive" - 
	"-notFile" {
	    # We can use 'saveAs' instead of 'save', so 
	    # disable 'save'.  Note that cmd-S will still
	    # work because we have bound that separately.
	    enableMenuItem File save 0
	    enableMenuItem File revertToSaved 0
	    enableMenuItem File saveUnmodified 0
	    enableMenuItem File renameToÉ 0
	}
	"-modifiedOnDisk" {
	    enableMenuItem File save 1
	    enableMenuItem File revertToSaved 1
	    enableMenuItem File saveUnmodified $dirty
	    enableMenuItem File renameToÉ [expr {!$dirty}]
	}
    }
    enableMenuItem Edit undo $dirty
}

# This proc keeps a central count of the number of dirty windows,
# which can therefore be queried by AlphaTcl packages, and is also
# used to maintain the enabled state of the 'Save All' menu item.
# 
# It is called from preCloseHook and dirtyHook -- the only occasions 
# when the dirty count may change.  (In addition it is called at 
# startup, but that's a special case).
proc alpha::menuAdjustDirtyCount {change} {
    global win::NumDirty
    incr win::NumDirty $change
    enableMenuItem File saveAll [expr {$win::NumDirty ? 1 : 0}]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::modifiedCheck" --
 # 
 #  Check whether $name has been modified on disk, and ensure that the
 #  save and revert menu items are correctly dimmed (if this is the front-
 #  most window).
 #  
 #  Returns 1 if the window has been modified on disk since last save.
 # -------------------------------------------------------------------------
 ##
proc alpha::modifiedCheck {name} {
    if {[win::IsFile $name fname]} {
	# If we get here then the window is a file that exists (possibly
	# in a virtual filesystem) and we were able to extract
	# information from the file's filesystem, in the 'info' array.
	set ret 0
	if {[catch {win::getInfo $name dirty} dirty]} {
	    set mod 0
	    set dirty 0
	} else {
	    if {!$dirty} {
		if {![win::infoExists $name Modified]} {
		    # This window is probably in the process of being
		    # opened.
		    set mod 0 
		} else {
		    set diff [expr {[win::getInfo $name Modified] \
		      - [file mtime $fname]}]
		    set mod [expr {$diff != 0}]
		    if {$mod} { 
			diskModifiedHook $name 1 $diff
			set ret 1
		    }
		}
	    } else {
		set mod 1
	    }
	}
	if {[alpha::frontmostAndActive $name]} {
	    if {$mod} {
		alpha::menuAdjustForDirtiness -modifiedOnDisk $dirty
	    } else {
		alpha::menuAdjustForDirtiness -normal $dirty
	    }
	}
	return $ret
    } else {
	if {[alpha::frontmostAndActive $name]} {
	    if {[catch {win::getInfo $name dirty} dirty]} {
		set dirty 0
	    }
	    alpha::menuAdjustForDirtiness -notFile $dirty
	}
	return 0
    } 
}

# ×××× Drag and Drop ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "dndWinHook" --
 # 
 #  Called when attempting to drag/drop anything into an Alphatk/8/X window
 #  
 #  Should return either a string with the kind of action that will be
 #  taken (can also use status::msg to pass on more info to the user),
 #  if the drag of the given data/item(s) is allowed in the given window
 #  at the given position, or "none" if the action is not allowed,
 #  Should not throw an error on good input.
 #  
 #  'options' is a list of name-value pairs (i.e. a Tcl dictionary).
 #  Currently supported entries are:
 #  
 #   'type' (the type/flavour of the item(s) being dragged)
 #   'data' (which typically contains a _list_ of filenames)
 #   'pos' (which is the window position of the drag event)
 #   'actions' (the possible actions - a list of copy, link, move, none)
 #   'action' (the recommended or current action)
 #   'modifiers' (a Tcl list of "Control", "Option", "Shift", etc - whatever 
 #   is held down by the user when the hook is called).
 #   
 #  On some platforms the data element may not always be available to us
 #  until the actual drop takes place (before that we can only know the
 #  type of item being dropped).  In such cases the 'data' element will
 #  be the empty string, and we will just have to do our best!
 #  Currently on Windows data is always provided, and on X11 it is not.
 #  
 #  As well as calling this hook, Alphatk makes sure that the window is
 #  visually updated to reflect the forthcoming drag/drap (with
 #  appropriate highlights and an insertion-position indication).  These
 #  will be removed on leave/drop events, and will be applied on
 #  enter/drag events (the latter will happen only if this routine
 #  returns a valid action).
 #  
 #  This procedure will call any of three AlphaTcl hooks (which may be
 #  used by other AlphaTcl packages to interact with drag/drop
 #  operations):
 #  
 #  dndEnter $win $options
 #  - Return a valid action if the hook wants to take over this
 #  operation for this window (possibly "none" if the hook wants to
 #  reject the drop), otherwise throw an error.
 #  
 #  dndDrag $win $options
 #  - I imagine not many hooks will want this.  It can be used to
 #  allow dropping only into one part of a window, for example.
 #  It is called repeatedly as the mouse moves in the window.
 #  
 #  dndDrop $win $options
 #  - Carry out the drop and return a valid action (typically "move" or
 #  "copy" -- you can just return [dict get $options action] if you
 #  don't care), or return "none" to abort the drop.
 #  
 #  To Do 1: see how this works with possible hooks in practice.
 #  
 #  To Do 2: how can we register a hook which only fires for certain 
 #  drag types?  Or must each hook check the type and only take action
 #  for the types it wants?
 #  
 # -------------------------------------------------------------------------
 ##
proc dndWinHook {window state options} {
    global alpha::dragAction
    
    #puts [list $window $state $options]
    switch -- $state {
	"enter" {
	    # The user has just dragged something into this window
	    if {[catch {hook::callForWin dndEnter untilok $window \
	      $window $options} res]} {
		set res [dndEnter $window $options]
	    }
	    # Store the action in this global variable, in case no hook
	    # is registered for 'drag' events, so that we can just
	    # provide the desired action directly instead
	    set alpha::dragAction $res
	    # Note: $res should be none, link, copy, move (or possibly
	    # 'ask' or 'private', but let's ignore that for the
	    # moment).
	    return $res
	}
	"drag" {
	    # The user is moving the drag within the window
	    if {[catch {hook::callForWin dndDrag untilok $window \
	      $window $options} res]} {
		# If the original enter event was successful, then we
		# should just use the action type that was determined
		# then.
		if {[info exists alpha::dragAction]} {
		    set p [join [pos::toRowCol -w $window [dict get $options pos]] ,]
		    status::msg "Dragging [dndShortDescription $options] to ($p)"
		    # If the user is holding down the control key, we
		    # over-ride with a 'copy' drag action.
		    if {[lsearch -exact [dict get $options modifiers] "Control"] != -1} {
			return "copy"
		    }
		    return $alpha::dragAction
		} else {
		    # That's weird: we should never get here.  So,
		    # we cancel the drag:
		    return "none"
		}
	    } else {
		return $res
	    }
	}
	"leave" {
	    # The user has just moved the drag outside this window.
	    # Alphatk's core will reset any visual changes
	    # automatically.  If we (in AlphaTcl) made any other
	    # changes, we should reset them now.  In particular, we
	    # should remove any message we have placed in the status
	    # bar, and unset the global drag action variable
	    status::msg ""
	    unset -nocomplain alpha::dragAction
	    
	    # For the moment we don't provide a leave hook.  When or if
	    # one is requested, we will add it here.
	    return
	}
	"drop" {
	    # The user has dropped on us.  If this is a 'text' drop
	    # internal to Alphatk, after this function returns, if
	    # the return value is "move", Alphatk will delete the
	    # original piece of text from the relevant window (which
	    # might be the same window we're pasting into -- Alphatk
	    # tags the text to keep track of changing indices, etc).

	    status::msg ""
	    unset -nocomplain ::alpha::dragAction
	    if {[catch {hook::callForWin dndDrop untilok $window \
	      $window $options} res]} {
		return [dndDrop $window $options]
	    }
	    return $res
	}
	default {
	    error "Bad state $state in dndWinHook"
	}
    }
}

proc dndShortDescription {options} {
    if {[dict exists $options description]} {
	return [dict get $options description]
    } else {
	switch -- [dict get $options type] {
	    "text/plain" {
		return "text"
	    }
	    "text/uri-list" {
		if {[llength [dict get $options data]] == 1} {
		    return "file"
		} else {
		    return "files"
		}
	    }
	    default {
		return [dict get $options type]
	    }
	}
    }
}

# Here are the default Alphatk behaviours for how to deal with drag and
# drop into windows. 

proc dndEnter {window options} {
    # No hooks claimed this event.  The default is to allow it
    status::msg "Dragging [dndShortDescription $options]"
    return [dict get $options action]
}

proc dndDrop {window options} {
    # No hooks claimed this event.  The default behaviour:
    set len 0
    goto -w $window [dict get $options pos]
    switch -- [dict get $options type] {
	"text/plain" {
	    # We use 'paste' here so that the usual smart-paste and
	    # other behaviours can take effect.
	    set oldScrap [getScrap]
	    putScrap [dict get $options data]
	    # If this 'paste' throws an error, then we have a bug
	    # elsewhere.  The window should reject the drag with
	    # appropriate dndEnter/dndDrag hooks, not throw an 
	    # error when we try to paste.
	    set ranges [paste -w $window]
	    putScrap $oldScrap
	    foreach {from to} $ranges {
		incr len [pos::diff -w $window $from $to]
	    }
	}
	"text/uri-list" {
	    foreach f [dict get $options data] {
		if {[file isdirectory $f]} {
		    set txt [join [glob -tails -dir $f *] \r]
		} else {
		    set txt [file::readAll $f]
		}
		# Should we use 'paste' here too?
		insertText -w $window $txt
		incr len [string length $txt]
	    }
	    set ranges [list \
	      [dict get $options pos] \
	      [pos::math -w $window [dict get $options pos] + $len]]
	}
	default {
	    alertnote "Unknown/unhandled drop type [dict get $options type]"
	    return
	}
    }
    eval [list selectText -w $window] $ranges
    refresh -w $window
    status::msg "$len characters inserted"
    return [dict get $options action]
}

# ===========================================================================
# 
# .