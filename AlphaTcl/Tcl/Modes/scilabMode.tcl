## -*-Tcl-*- (install)
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "scilabMode.tcl"
 #                                    created: 01-03-09 13.58.49 
 #                                last update: 05/23/2006 {10:45:32 AM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 #  Mode for 'Scilab'
 #  
 # Installation:
 # 
 #  Requires Alpha version 7.0 or newer.  Just drop this file into
 #  the Alpha:Tcl:Modes: folder, rebuild your Tcl indices (using
 #  the Tcl menu which will be there when you read this file in Alpha)
 #  then quit and restart Alpha.  Now any file ending in '.sci' 
 #  automatically opens in Scilab mode.  You also need to paste the
 #  included icon from 'newMenuIcons.rsrc' into Alpha.  If for some
 #  reason you got this file without that rsrc file, then add the line
 #  'set scilabMenu "Scil"' to your prefs.tcl file.  Note: the more
 #  useful features of this mode are only available if you've
 #  installed "Vince's Additions".
 #  
 #  We can't do too much exciting, since Scilab only handles an
 #  'open' apple-event --- therefore it's not usefully scriptable.
 #  
 # Features:
 # 
 #  Automatically scans Scilab's 'Help' directory to pick up all
 #  Scilab keywords so they can be coloured.
 #  
 #  Command-clicking on a keyword opens up a window with the help
 #  information for that keyword (optionally this can be made to
 #  open in Scilab itself)
 #  
 # If Vince's Additions is installed, the following features are
 # also available:
 # 
 #  Keywords can be completed (enter the first few letters 
 #  followed by 'cmd-tab')
 #  
 #  Function calls can be extended to list their arguments,
 #  with template stops at each argument (again use cmd-tab).
 #  
 #  e.g. type 'sysl<cmd-tab>' and it is completed to 'syslin'
 #  and immediately expanded to:
 #  	syslin(¥<dom>,¥<A>,¥<B>,¥<C >¥<[,D [,x0] ]>)¥
 #  pressing tab moves from one argument to the next, highlighting
 #  each argument in turn for each entry.
 #  
 # This file is copyright Vince Darley 1997, but freely distributable
 # provided you note any modifications you make below.
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2000-12-07 DWH 1.0 updated help text
 # ###################################################################
 ##

alpha::mode [list Scil Scilab] 1.0 scilabMenu {*.sci *.dem} {
    scilabMenu
} {
    # Script to execute at Alpha startup
    addMenu scilabMenu "¥283"
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Scilab programming files
} help {
    Scilab Mode supplies a menu for easy switching to Scilab.  The mode
    automatically scans Scilab's 'Help' directory to pick up all Scilab
    keywords so they can be coloured.  
    
    Command-Double-Clicking on a keyword opens up a window with the help
    information for that keyword.  This can be optionally made to open in
    Scilab itself, adjust the "Alpha Opens Help Files" preference.
    
    Preferences: Mode-Scil
    
    Click on this "Scilab Example.sci" link for an example syntax file.
}

proc scilabMode.tcl {} {}

# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Scil
newPref f alphaOpensHelpFiles 1 Scil
newPref v wordBreak {[\w_]+} Scil
newPref color stringColor green Scil
newPref color commentColor red Scil
newPref color keywordColor blue Scil

set Scil::commentCharacters(General) "//"
set Scil::commentCharacters(Paragraph) [list "//" "//" "//"]
set Scil::commentCharacters(Box) [list "//" 2 "//"  2 "//" 3]

proc scilabMenu {} {}

Menu -n $scilabMenu -p Scil::menuProc {
    "switchToScilab"
    "(-"
    "/K<U<OopenFileInScilab"
    "/K<U<O<BswitchFileToScilab"
    "/C<O<UsetClipboardToExecFile"
    "rebuildScilabKeywords"
}


proc Scil::menuProc {menu item} {
    switch -- $item {
	switchToScilab {app::launchFore SLab}
	openFileInScilab {
	    openAndSendFile SLab
	}
	switchFileToScilab {
	    openAndSendFile SLab
	    killWindow
	}
	setClipboardToExecFile {
	    putScrap "exec('[win::CurrentTail]')"
	}
	rebuildScilabKeywords {Scil::RebuildElectrics}
    }
}

set completions(Scil) \
  {completion::cmd completion::electric completion::word}

proc Scil::RebuildElectrics {} {
    # Get keywords by looking for all help documents,
    # simple but effective.  There may be a better way.
    global Scilcmds PREFS Scilelectrics
    set p [pwd]
    set dir  [file join [file dirname [nameFromAppl SLab]] man]
    cd $dir
    regsub -all ".hlp" [glob *.hlp] "" Scilcmds
    cd $p
    set Scilcmds " ${Scilcmds} "
    set fout [open [file join ${PREFS} ScilData] w]
    puts $fout "set Scilcmds \{${Scilcmds}\}"
    foreach f $Scilcmds {
	status::msg "scanning ${f}É"
	set fileid [open [file join ${dir} ${f}.hlp] r]
	set contents [read $fileid]
	close $fileid
	if [regexp "NAME\[ \r\n\t\]+${f} - (\[^\r\n\]*)\[ \r\n\t\]+CALLING SEQUENCE\[ \r\n\t\]+(${f}|\[^=\]+= *${f})(\(\[^\r\n\]+)\)\[ \r\n\t]" \
	  $contents "" desc "" arg] {
	    if [regexp  {\((.*)\)(.*)} $arg "" in after] {
		if [regexp {(, *)?\[.*\]} $in brace] {
		    regsub {(, *)?\[.*\]} $in {×} in
		    regsub -all {,} $in {¥,¥} in
		    if {$in != "×"} {
			regsub {×} $in "¥¥${brace}¥" in
			set in "(¥${in})$after"
		    } else {
			regsub {×} $in "¥${brace}¥" in
			set in "(${in})$after"
		    }
		} else {
		    regsub -all {,} $in {¥,¥} in
		    if {$in != ""} {
			set in "(¥${in}¥)$after"
		    } else {
			set in "()$after"
		    }
		}
		set Scilelectrics($f) "${in}¥$desc¥"				
	    } else {
		set Scilelectrics($f) "${arg}¥$desc¥"
	    }
	    puts $fout "set Scilelectrics($f) \{$Scilelectrics($f)\}"
	}
    }
    close $fout
    status::msg "done"
    
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Scil::DblClick" --
 # 
 #  Open a help file for the given command, either in Alpha or externally
 #  in Scilab.
 # -------------------------------------------------------------------------
 ##
proc Scil::DblClick {from to shift option control} {
    selectText $from $to
    set text [getSelect]
    set d "[file join [file dirname [nameFromAppl SLab]] man]"
    set f "[file join ${d} ${text}.hlp]"
    if {[file exists $f]} {
	global alphaOpensHelpFiles
	if {$alphaOpensHelpFiles} {
	    edit -r -c -mode Scil $f
	} else {
	    set name [file tail [app::launchFore SLab]]
	    sendOpenEvent noReply $name $f
	}		
    } else {
	alertnote "No such help file exists in Scilab's 'man' directory."
    }
}

proc Scil::MarkFile {args} {
    win::parseArgs w
    status::msg "Marking \"[win::Tail $w]\" É"
    set count 0
    set pos [minPos -w $w]
    set pat {^(function[\t ]\[)([\t a-zA-Z0-9,]+\])([\t =]+)([-a-zA-Z0-9_%]+)([\t ]*\()}
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $pat $pos} match]} {
	incr count
	set posBeg [lindex $match 0]
	regexp -nocase -- $pat [getText -w $w $posBeg [lindex $match 1]] \
	  -> text1 text2 text3 text4
	setNamedMark -w $w $text4 $posBeg $posBeg $posBeg
	set pos [pos::nextLineStart -w $w $posBeg]
    }
    set msg "The window \"[win::Tail $w]\" contains $count function"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}
if {[file exists [file join ${PREFS} ScilData]]} {
    source [file join ${PREFS} ScilData]
} else {
    status::msg "The first time you use this mode\
      I must build a command database."
    if {[catch {Scil::RebuildElectrics}]} {
	set Scilcmds ""
    }
}
regModeKeywords -C Scil {}
regModeKeywords -a -e {//} -c $ScilmodeVars(commentColor) \
  -k $ScilmodeVars(keywordColor)  -s $ScilmodeVars(stringColor) \
   Scil $Scilcmds
