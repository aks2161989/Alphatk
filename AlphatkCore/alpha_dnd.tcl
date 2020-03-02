## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_dnd.tcl"
 #                                    created: 01/29/2001 {19:23:38 PM} 
 #                                last update: 02/01/2005 {10:54:19 AM} 
 #  
 # This file (unlike most of the rest of Alphatk core)
 # is distributed under a BSD style license.
 # 
 # ###################################################################
 ##

# ×××× Application drag/drop ×××× #

namespace eval alpha {}
proc alpha::initDnd {} {
    foreach w {.status .status.text .} {
	BindTarget $w FILENAME 35
	BindTarget $w text/uri-list 30
	BindTarget $w FileGroupDescriptorW 40
	BindTarget $w FileGroupDescriptor 40
    }
}

proc BindTarget {win Type {p 50}} {
    foreach type $Type {
	dnd bindtarget $win $type <DragEnter> \
	  {AppDragEnter %A %a %T %W %X %Y %x %y %D} $p
	dnd bindtarget $win $type <Drag>      \
	  {AppDrag %A %a %T %W %X %Y %x %y %D} $p
	dnd bindtarget $win $type <DragLeave> \
	  {AppDragLeave %A %a %T %W %X %Y %x %y} $p
	dnd bindtarget $win $type <Drop>      \
	  {AppDrop %A %a %T %W %X %Y %x %y %D} $p
    }
}

proc AppDrag {action actions type win X Y x y {data {}}} {
    if {[winfo toplevel $win] ne "." && [winfo toplevel $win] ne ".status"} {
	return -code continue
    }
    set t [winfo toplevel $win]
    #puts stderr "drag $action"
    update
    if {[lsearch -exact $actions ask] != -1} {
	set ret_action ask
    } elseif {[lsearch -exact $actions copy] != -1} {
	set ret_action copy
    } else {
	set ret_action $action
    }
    status::msg "Drop here to edit ($type): $data"
    return $ret_action
}

proc AppDragEnter {action actions type win X Y x y {data {}}} {
    if {[winfo toplevel $win] ne "." && [winfo toplevel $win] ne ".status"} {
	return -code continue
    }
    set t [winfo toplevel $win]
    #puts stderr "drag enter $type $action"
    #$win configure -bg green
    status::msg "Drop here to edit: $data"
    update
    return $action
}

proc AppDragLeave {action actions type win X Y x y} {
    if {[winfo toplevel $win] ne "." && [winfo toplevel $win] ne ".status"} {
	return
    }
    set t [winfo toplevel $win]
    status::msg ""
    #puts stderr "drag leave $action"
    #$win configure -bg ""
    update
}

proc AppDrop {action actions type win X Y x y data} {
    if {[winfo toplevel $win] ne "." && [winfo toplevel $win] ne ".status"} {
	return -code continue
    }
    #puts stderr "drop $action"
    set t [winfo toplevel $win]
    if {[string match text/* $type]} {
	set Data $data
    } elseif {$type == "FILENAME"} {
	set Data [list $data]
    } elseif {$type == "FileGroupDescriptor"} {
	set Data [list $data]
    } elseif {$type == "FileGroupDescriptorW"} {
	set Data [list $data]
    } else {
	set Data "Binary data dropped..."
    }
    #puts "$Data"
    switch -glob $type {
	FILENAME -
	FileGroupDescriptor - 
	FileGroupDescriptorW -
	"text/uri-list" {
	    foreach f $Data {
		if {![file exists $f]} {
		    lappend no $f
		} else {
		    set f [file nativename [file normalize $f]]
		    edit $f
		}
	    }
	    if {[info exists no]} {
		alertnote "These don't exist [join $no ,]"
	    }
	}
	default {
	    puts stderr "Unknown type $type"
	}
    }
}

# ×××× Dialog items drag and drop ×××× #

proc BindDropOnDialogItem  {win cmdSet cmdCheck Types {p 50}} {
    foreach type $Types {
	dnd bindtarget $win $type <DragEnter> \
	  [list DialogDragEnter $cmdCheck %A %a %T %W %X %Y %x %y %D] $p
	dnd bindtarget $win $type <Drag>      \
	  [list DialogDrag $cmdCheck %A %a %T %W %X %Y %x %y %D] $p
	dnd bindtarget $win $type <DragLeave> \
	  [list DialogDragLeave %A %a %T %W %X %Y %x %y] $p
	dnd bindtarget $win $type <Drop>      \
	  [list DialogDropItem $cmdSet %A %a %T %W %X %Y %x %y %D] $p
    }
}

proc BindDragFromDialogItem  {win cmdDone cmdCheck Types {p 50}} {
    foreach type $Types {
	# not yet implemented
    }
}

proc DialogDragEnter {cmdCheck action actions type win X Y x y {data {}}} {
    #puts stderr "drag enter '$cmdCheck' $action $type $data"
    set t [winfo toplevel $win]
    #$win configure -bg green
    #update
    switch -glob $type {
	image/* {
	    set msg "Can't accept an image"
	}
	TK_COLOR {
	    set msg "Can't accept a colour"
	}
	FileGroupDescriptorW -
	FileGroupDescriptor -
	FILENAME -
	"text/uri-list" {
	    if {$data == ""} {
		status::msg "Probably ok to drop here"
		return $action
	    }
	    if {$type == "FILENAME"} {
		set data [list $data]
	    } elseif {$type == "FileGroupDescriptor"} {
		return "none"
	    } elseif {$type == "FileGroupDescriptorW"} {
		return "none"
		set data $data
	    }
	    #puts [list DialogDragEnter $cmdCheck $data]
	    set res [eval $cmdCheck $data]
	    #puts $res
	    if {![string length $res]} {
		status::msg "Ok to drop $data here"
		return $action
	    } else {
		status::msg "Can't drop here: $res"
		return "none"
	    }
	}
	default {
	    set msg "Unknown type $type dropped with data $data"
	}
    }
    status::msg "Can't drop here: $msg"
    return "none"
}

proc DialogDrag {cmdCheck action actions type win X Y x y {data {}}} {
    DialogDragEnter $cmdCheck $action $actions $type $win $X $Y $x $y $data
}

proc DialogDragLeave {action actions type win X Y x y} {
    set t [winfo toplevel $win]
    #puts stderr "drag leave $action"
    #$win configure -bg ""
    status::msg ""
    update
}

proc DialogDropItem {cmd action actions type win X Y x y data} {
    #puts stderr "drop $action $type $cmd $data"
    set t [winfo toplevel $win]
    if {[string match text/* $type]} {
	# These are fine.
    } elseif {$type == "FILENAME"} {
	# This is fine.
    } elseif {$type == "FileGroupDescriptor"} {
	set Data $data
	error "Can't drop"
    } elseif {$type == "FileGroupDescriptorW"} {
	set Data $data
	error "Can't drop"
    } else {
	set Data "Binary data dropped..."
    }
    #puts "$Data"
    set msg "Unknown error"
    switch -glob $type {
	image/* {
	    set msg "Can't accept an image"
	}
	TK_COLOR {
	    set msg "Can't accept a colour"
	}
	FileGroupDescriptor -
	FileGroupDescriptorW -
	FILENAME -
	"text/uri-list" {
	    if {$type == "FileGroupDescriptorW"} {
		set Data [list $Data]
	    } elseif {$type == "FILENAME"} {
		set Data [list $Data]
	    }
	    #puts [list DialogDropItem $cmd $data]
	    if {![catch {eval $cmd $data} msg]} {
		return
	    }
	}
	default {
	    set msg "Unknown type $type dropped with data $data"
	}
    }
    #puts $::errorInfo
    status::msg "Drop error: $msg"
    #global errorInfo ; puts $errorInfo
    error "Drop error: $msg"
}


