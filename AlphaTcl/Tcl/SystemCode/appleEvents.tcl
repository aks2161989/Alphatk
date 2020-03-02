# This is 'Gui' code.  Shouldn't be available during ordinary startup.
# Of course the 'tclAE' package may want to be available.
# JEG - modernized
# 
# make alias list to pass to tclAE::send -p
proc makeAlis {name} {
	return [tclAE::build::alis $name]
}

# JEG - This is unused???
proc makeFile {name} {
	return [tclAE::build::alis $name]	
}

## 
 # -------------------------------------------------------------------------
 # 
 # "makeAlises" --
 # 
 #  This proc has changed so it takes a list of items rather than an
 #  unknown number of args 'args'.  If 'l' is a list you must call
 #  this proc with 'makeAlises $l' rather than 'eval makeAlises $l'
 #  as was previously required.
 # -------------------------------------------------------------------------
 ##

# JEG - modernized
# 
proc makeAlises {names} {
	return [tclAE::build::List $names -untyped -as alis]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "handleReply" --
 # 
 #  Queued replies are passed through AEPrint and then to this routine.
 #  
 #  If you write your own handleReply procedure, register it to this
 #  proc with:
 #  
 #    currentReplyHandler 'my-proc-name'
 #    
 #  Do this each time you send an event which may receive a reply.
 #  There is no need to register your proc at startup or any such
 #  'pre-registering'.  Just call the above proc _each_ time.
 #  
 #  You proc should take one parameter (the reply), and should
 #  return '1' if it handled the reply, otherwise it can do/return
 #  anything else (although hopefully not much if it didn't handle
 #  anything).
 #  
 #  If your replies often time-out or have other problems such
 #  that you don't handle them correctly, you may wish to register
 #  your reply-handler with 'currentReplyHandler 'my-proc' 1' which
 #  says 'only register if it's not already registered'.  Or you
 #  may wish to remove duplicates from the list of handlers 
 #  directly.
 #    
 # Results:
 #  depends on what is registered
 # 
 # Side effects:
 #  calls other procs.  Removes handler from queue if it handled
 #  the reply.
 # 
 # --Version--Author------------------Changes-------------------------------
 #    1.0     <vince@santafe.edu> first one with hook handling
 #    2.0     <vince@santafe.edu> different mechanism to give priority
 # -------------------------------------------------------------------------
 ##
proc handleReply {rep} {
    global lastReply replyHandlers
    set lastReply $rep
    set i 0
    foreach h $replyHandlers {
	if {$h != ""} {
	    set cmd [concat $h [list $rep]]
	    catch $cmd res
	    if {$res == 1} {
		set replyHandlers [lreplace $replyHandlers $i $i]
		return
	    }
	}
	incr i
    }
    status::msg "Reply '$rep' not handled"
}

ensureset replyHandlers ""

## 
 # -------------------------------------------------------------------------
 # 
 # "currentReplyHandler" --
 # 
 #  Add item to end of queue to receive replies, even if it is already
 #  in the queue, unless we set 'nodups'
 # -------------------------------------------------------------------------
 ##
proc currentReplyHandler {proc {nodups 0}} {
    global replyHandlers
    if {!$nodups || (![lcontains replyHandlers $proc])} {
	lappend replyHandlers $proc
    }	
}

# JEG - only used by thinkMenu.tcl. Why is it here?
# 
# Return an object record specifying the desired think project file.
proc fileObject {name} {
    join [concat \
      {obj\{want:type('SFIL'), from:'null'(), form:'name', seld:р} \
      [file tail $name] \
      {с\}}] ""
}

#╔ sendOpenEvent [filler] <app name> <file name> - Send an open doc event to 
#  another currently running application. If 'filler' is noReply, then a 
#  reply is not requested. Otherwise, we wait for a reply and 'filler' is 
#  ignored. 
proc sendOpenEvent {filler app filename} {
    global browserSig tcl_platform
    set filename [file nativename $filename]
    switch -- $tcl_platform(platform) {
	"windows" {
	    set app [string trim $app ']
	    if {[file nativename $app] eq [file nativename $browserSig]} {
		global env
		# This command doesn't seem to work with long names/spaces etc
		# on windows, so we convert to the shortname!
		catch {set filename [file attributes $filename -shortname]}
		exec $env(COMSPEC) /c start $filename &
		return
	    } elseif {$app == "Finder"} {
		if {[file isdirectory $filename]} {
		    windows::Show $filename
		} else {
		    windows::Launch $filename
		}
	    } else {
		if {$filler == "noReply"} {
		    exec $app $filename &
		} else {
		    return [exec $app $filename]
		}
	    }
	}
	"macintosh" {
	    # Tcl 8's [file nativename] strips the trailing ':'
	    # from directories which screws up the 'alis'
	    if {[file type $filename] == "directory" \
	      && ![regexp "[quote::Regfind [file separator]]\$" $filename]} {
		append filename [file separator]
	    }
	    if {$filler == "noReply"} {
		tclAE::send -p $app aevt odoc "----" [tclAE::build::alis $filename]
	    } else {
		tclAE::send -p -r $app aevt odoc "----" [tclAE::build::alis $filename]
	    }
	}
	"unix" {
	    if {$tcl_platform(os) == "Darwin"} {
		# Tcl 8's [file nativename] strips the trailing ':'
		# from directories which screws up the 'alis'
		if {[file type $filename] == "directory" \
		  && ![regexp "[quote::Regfind [file separator]]\$" $filename]} {
		    append filename [file separator]
		}
		if {$filler == "noReply"} {
		    tclAE::send -p $app aevt odoc "----" [tclAE::build::alis $filename]
		} else {
		    tclAE::send -p -r $app aevt odoc "----" [tclAE::build::alis $filename]		
		}
	    } else {
		set app [string trim $app ']
		if {$filler == "noReply"} {
		    exec $app $filename &
		} else {
		    return [exec $app $filename]
		}
	    }
	}
    }
    
}

proc launchDoc {name} {
    set app [app::launchFore [file::getSig $name]]
    sendOpenEvent -r [file tail $app] $name
}

# Send multiple open events
proc sendOpenEvents {appname args} {
    global alpha::macos
    if {${alpha::macos}} {
	tclAE::send -p -r $appname aevt odoc "----" \
	  [tclAE::build::List $args -untyped -as alis]
    } else {
	foreach f $args {
	    sendOpenEvent noReply $appname $f
	}
    }
}

proc openAndSendFile {sig} {
    set fname [win::Current]
    if {[winDirty]} {
	if {[dialog::yesno "Save '$fname'?"]} {
	    save
	}
    }
    
    set name [file tail [app::launchFore $sig]]
    sendOpenEvent noReply $name $fname
}

#================================================================================
# General Apple Event handling routines
#
# (written by Tom Pollard for use in the MacPerl package)
#================================================================================

# Quit an application.
proc sendQuitEvent {appname} {
    tclAE::send -p $appname "aevt" "quit" 
}

# Close one of an application's windows, designated by number.
proc sendCloseWinNum {appname num} {
    tclAE::send -p $appname "core" "clos" "----" [AEWinByPos $num]
}

# Close one of an application's windows, designated by name.
proc sendCloseWinName {appname name} {
    tclAE::send -p $appname "core" "clos" "----" [AEWinByName $name]
}

# Obtain the number of lines in one of an application's
# windows, designated by name.
proc sendCountLines {appname name} {
    set winObj [AEWinByName $name]
    set res [tclAE::send -p -r $appname "core" "cnte" "----" $winObj kocl type('clin')]	
    if {[regexp {:(.*)\}} $res allofit nlines]} {
	return $nlines
    } else {
	return 0
    }
}

# Get a selected range of lines from one of an application's
# windows, designated by name.  If $last is missing, then a single
# line is returned; if both $first and $last are missing, then
# the complete window contents are returned.
proc sendGetText {appname name {first {missing}} {last {missing}}} {
    global ALPHA
    set winObj [AEWinByName $name]
    if {$first != "missing"} {
	if {$last != "missing"} {
	    set rangDesc [AELineRange $first $last]
	} else {
	    set rangDesc [AEAbsPos $first]
	}
	set objDesc "obj{want:type('clin'), from:$winObj, $rangDesc }"
    } else {
	set objDesc "obj{want:type('ctxt'), from:$winObj, form:'indx', seld:abso('all') }"
    }
    set res [tclAE::send -p -r $appname "core" "getd" "----" $objDesc]
    if {![regexp {р.*с} $res text]} { set text {} }
    return [string trim $text {рс}]
}

# Set a selected range of lines in one of an application's
# windows, designated by name.  If $last is missing, then a single
# line is changed; if both $first and $last are missing, then
# the complete window contents are replaced by the new text.
proc sendSetText {appname name text {first {missing}} {last {missing}}} {
    set winObj [AEWinByName $name]
    if {$first != "missing"} {
	if {$last != "missing"} {
	    set rangDesc [AELineRange $first $last]
	} else {
	    set rangDesc [AEAbsPos $first]
	}
	set objDesc "obj{want:type('clin'), from:$winObj, $rangDesc }"
    } else {
	set objDesc "obj{want:type('ctxt'), from:$winObj, form:'indx', seld:abso('all') }"
    }
    set res [tclAE::send -p -r $appname "core" "setd" "----" $objDesc "data" [curlyq $text]]	
    if {![regexp {р.*с} $res text]} { set text {} }
    return [string trim $text {рс}]
}

################################################################################
# Utility functions for constructing AppleEvent descriptors for tclAE::send -p
################################################################################

# JEG - modernized
#
proc AEFilename {name} {
	return [tclAE::build::filename $name]
}

# JEG - modernized
#
proc AEWinByName {name} {
	return [tclAE::build::winByName $name]
}

# JEG - modernized
#
proc AEWinByPos {absPos} {
	return [tclAE::build::winByPos $absPos]
}

# JEG - modernized
#
proc AELineRange {absPos1 absPos2} {
	return [tclAE::build::lineRange $absPos1 $absPos2]
}

# JEG - modernized
#
proc AEAbsPos {posName} {
	return [tclAE::build::absPos $posName]
}

# JEG - modernized
#
proc AEName {name} {
	return [tclAE::build::name $name]
}

# JEG - modernized
#
proc curlyq {str} {
	return [tclAE::build::TEXT $str]
}

################################################################################

# JEG - modernized
#
proc nullObject {} { 
    return [tclAE::build::nullObject] 
}

# JEG - modernized
#
proc objectType {type} {
    return [tclAE::build::objectType $type]
}

# JEG - modernized
#
proc nameObject {type name from} {
    return [tclAE::build::nameObject $type $name $from]
}

# JEG - modernized
#
proc indexObject {type ind from} {
    return [tclAE::build::indexObject $type $ind $from]
}

# JEG - modernized
#
proc propertyObject {prop object} { 
    return [tclAE::build::propertyObject $prop $object]
}


# JEG - unused?
# 
# 'process' must have single quotes
proc buildMsgReply { process suite event args } { return [eval [list tclAE::send -p -r $process $suite $event ] $args] }

# JEG - modernized
#
proc countObjects { process fromObject class } {
    return [tclAE::build::resultData $process core cnte \
      ---- $fromObject \
      kocl [tclAE::build::objectType $class] \
    ]
}

proc createThingAtEnd {process container class} {
    set res [tclAE::send -p -r $process core crel insh "insl \{kobj:$container\}" kocl "type($class)"]
}


proc getObjectData { process class name from } {
    return [tclAE::build::resultData $process core getd ---- \
      [tclAE::build::nameObject $class [tclAE::build::TEXT $name] $from]]
} 

proc objectProperty { process property object } {
    tclAE::send -p -r $process core getd ---- [propertyObject $property $object]
}

# Extract and return a path from a result.
proc extractPath {res} {
    return [tclAE::getKeyData $res ---- TEXT]
}
