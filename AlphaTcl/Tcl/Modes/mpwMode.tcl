## -*-Tcl-*- (install) (nowrap)
# 
 # Author :  Bernard Desgraupes  
 # e-mail:   <bdesgraupes@easyconnect.fr>
 # www:  <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # Created : 2000-06-27 11:20:12
 # Last modification : 2002-10-18 08:13:26
 # Comments : this is a mode for Alpha.
 # It allows you to use Alpha as a frontend to MPW to write and to process
 # scripts and commands in the MPW language. Main features are :
 # syntax coloring, elaborate system of abbreviations and word  completion,
 # immediate help, executing scripts from within Alpha, getting or  setting
 # the value of all MPW variables and paths, browsing through commands history etc.
 # For this mode to work properly, you must have installed MPW 3.3 or later 
 # and the ToolServer software.
 # For more information, see <Mpw Mode Help>.
 #
 # (c) Copyright : Bernard Desgraupes, 2000, 2001, 2002
 #         All rights reserved.
 # This software is free software. See licensing terms in the
 # Mpw Mode Help file.
 ##

alpha::mode MPW 0.6.1 mpwMenu {*.mpw} {
    mpwMenu
} {
    # Script to execute at Alpha startup
    alpha::internalModes "MPW"
    addMenu mpwMenu "¥146" [list "MPW" "Fort" "f90"]
} uninstall {
    this-file 
} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/alpha.html> 
} description {
    Supports the editing of Macintosh Programmers Workshop files
} help {
    file "MPW Help"
}

proc mpwMode.tcl {} {}

namespace eval mpw {}

# Only do this the first time we load the mode.
set dimmitemslist [list  "Execute Lines"  "Execute the Buffer" \
  "Command LineÉ"  "Commando BoxÉ" "Set MPW Mode"  "Enclose withÉ" "Remove enclosers" \
  "MPW Special Chars" "Show Current Variables"  "Built in Commands..." \
  "Internal Variables" "User Variables" "Libraries Variables" ]
foreach item $dimmitemslist {
    hook::register requireOpenWindowsHook [list -m $mpwMenu $item] 1	
} 
unset dimmitemslist item

#######   Preferences  #############

newPref var lineWrap {0} MPW
# Set this flag if you want your source file to be marked automatically when
# it is opened.
newPref f autoMark {1} MPW
# To send the result of a command line to a different window, turn this item
# on||To send the result of a command line to the same folder, turn this
# item off
newPref flag electricSemicolon 1 MPW
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 MPW
newPref f sendResultToBuffer {0} MPW
# Echo in the worksheet the "get" commands sent from the menu.
newPref f echoFromMenu {1} MPW
# Size of the commands history buffer. Option-click on the title
# bar of the current window to see the commands history
newPref v histBufferSize {20} MPW mpw::shadowHist
# The string prefixing comments.
newPref v prefixString {# } MPW
# Default color for the comments.
newPref v commentColor red MPW
# Default color for the keywords.
newPref v keywordColor blue MPW
# Default color for the strings.
newPref v stringColor green MPW
# Default color for the braces.
newPref v bracesColor green MPW
# Default color for the variables names.
newPref v variablesColor magenta MPW
# Default color for the category names.
newPref v categoriesColor cyan MPW
# Regular expression used in the Functions pop-up menu 
# (above the M pop-up menu, top right of the current window).
newPref v funcExpr {^set +[^ ]+} MPW
# What is a word in MPW mode ? Define your scheme here.
newPref v wordBreak {[-_\w]+} MPW
# A key binding to enclose in braces is ctrl-(.  You can choose an other one
# here.
newPref binding  encloseInBraces "/(<B" MPW "" mpw::encloseInBraces
# A key binding to remove enclosing braces is ctrl-opt-(.  You can choose an
# other one here.
newPref binding  removeBraces "/(<I<B" MPW "" mpw::removeBraces
# A key binding to send commands to Tool Server is cmd-RETURN. You can
# choose an other one here.
newPref binding  sendToToolServer "/b<O" MPW "" mpw::sendtoTSProc
# A key binding to send the buffer to Tool Server is ctrl-cmd-RETURN. You
# can choose an other one here.
newPref binding  sendToToolServer "/b<O<B" MPW "" mpw::execBuffer


########   Initialization of some variables  #############
set MPW::commentCharacters(General) "#"
set MPW::commentCharacters(Paragraph) [list "## " " ##" " # "]
set MPW::commentCharacters(Box) [list "#" 1 "#" 1 "#" 3]
set MPWhistory {}
set TSsign "MPSX"
set MPWscript ""
set MPWlastCmdLine ""
set MPWlastCmdo ""
set MPWlastOpts ""
set MPWHistNum 0
set MPWenclosers [list "(" ")" "\{" "\}" "\[" "\]" "<" ">" "\"" "\'" "`" "Ç" "È"]

set MPWcategories [list "Help Summary" "(-" CFM-68K Characters Commands Editing Expressions FileSystem \
 Languages Launch Miscellaneous Patterns PowerMacintosh Projector Resources Scripting Selections \
 Shortcuts System Variables Window ]

set MPWinternals [list "Active" "Aliases" "BackgroundShell" "Boot" "Command" "MPW" "MPWVersion" \
  "ShellDirectory" "Status" "SystemFolder" "Target" "User" "Windows" "Worksheet" ]

set MPWvars [list "AllowCmdsOnlyInWorkSheet" "AllowColorizing" "AllowColorUserExperience" \
  "AllowDraggingOut" "AllowMultipleUndo" "AllowWhiteSpaceDelimiter" "AutoIndent" "BackgroundErr" \
  "BackgroundOut" "CaseSensitive" "Commando" "Commands" "CursorForDragging" "DirectoryPath" \
  "DontFlushServers" "DontFlushVolumes" "DynaScroll" "Echo" "Exit" "ExtendWordSet" "FontSize" \
  "Font" "HeapCheck" "HideHelpKey" "IgnoreCmdPeriod" "InhibitMarkCopy" "NewKeyboardLayout" \
  "NewWindowRect" "PrefsFolder" "PrintOptions" "ProjectorVersion" "ScreenUpdateDelay" \
  "SearchBackward" "SearchType" "SearchWrap" "StackOptions" "SuppressDialogs" "SysTempFolder" \
  "TabWidthChar" "Tab" "TempFolder" "Test" "TileOptions" "ToolSleepTime" "TraceFailures" \
  "UseStandardFile" "WordSet" "ZoomHeight" "ZoomWidth" "ZoomWindowRect" ]

set MPWlibs [list "AIncludes" "CFM68KLibraries" "CIncludes" "CLibraries" "Libraries" \
  "PInterfaces" "PPCLibraries" "PLibraries" "RIncludes" "SharedLibraries" "SMIncludes" ]
# "SMDefines" "SMOptions"

set MPWbuiltInCmds [list "AddMenu" "AddPane" "Adjust" "Alert" "Alias" "Align" "AuthorInfo" "Beep" "Begin" \
"Break" "Browser" "Canon" "Catenate" "CheckIn" "CheckOut" "CheckOutDir" "Clear" "Close" "Confirm" "Continue" \
"Copy" "Cut" "Date" "Delete" "DeleteMenu" "DeleteNames" "DeletePane" "DeleteRevisions" "Directory" "Duplicate" \
"DuplicateNameRevisions" "Echo" "Eject" "Equal" "Erase" "Evaluate" "Execute" "Exists" "Exit" "Export" "Files" \
"Find" "Flush" "FlushAllVolumes" "For" "Format" "Help" "HideWindows" "If" "LockNameRevisions" "Loop" "Mark" \
"Markers" "ModifyReadOnly" "Monitors" "Mount" "MountProject" "Move" "MoveWindow" "MrPlus" "NameRevisions" \
"New" "Newer" "NewFolder" "NewProject" "ObsoleteNameRevisions" "ObsoleteProjectorFile" "Open" "Parameters" \
"Pascal" "PasMat" "PasRef" "Paste" "PlaySound" "Position" "Project" "ProjectInfo" "Quit" "Quote" "Redo" \
"Rename" "RenameProjectorFile" "Replace" "Request" "ResolveAlias" "Revert" "RotatePanes" "RotateWindows" \
"RProj" "RShell" "Save" "SaveOnClose" "SendAE" "Set" "SetFile" "SetKey" "Shift" "ShowSelection" "ShowWindows" \
"Shutdown" "SizeWindow" "StackWindows" "Target" "TickCount" "TileWindows" "TransferCkid" "Unalias" "Undo" "Unexport" \
"UnlockNameRevisions" "Unmangle" "Unmark" "Unmount" "UnmountProject" "UnmountVolume" "UnObsoleteNameRevisions" \
"UnObsoleteProjectorFile" "Unset" "UnsetKey" "UpdateProjectorDatabase" "UserVariables" "Version" \
"Volumes" "Which" "Windows" "ZoomWindow" ]


proc mpwMenu {} {}

proc mpw::buildMenuVar {list {type ""}} {
    global $list
    set ${list}Menu ""
    foreach item [set $list] {
	lappend ${list}Menu "<E<S$item"
	lappend ${list}Menu "<S<Iget $item"
	if {$type=="1"} {
	    lappend ${list}Menu "<S<Bset $item"
	} 
    }
    return [set ${list}Menu]
}


##############################################
#                                            #
#      Building MPW Menu                     #
#                                            #
##############################################

set SpecialCharsmenu [list Menu -m -n "MPW Special Chars" -p mpw::specialCharsProc {\
"Characters Palette" "(-" "/D<I!¶ escape special chars" "/D<U<I!Æ place insertion point" "/8<I!¥ beginning of" \
 "/5<I!° end of" "!¤ current selection" "/;<I!É ellipsis" "/X<I!Å match any string" "/=<I!­ not equal sign" \
  "/L<I!Â logical not" "/1<I!Á move backward" "/R<I!¨ tag expression" "/L<U<I!| pipe out" "/S<U<I!· redirect all output" \
   "!³ redirect errors" "/F<I!Ä depends on" "(-" "Dev:StdIn" "Dev:StdOut" "Dev:StdErr" "Dev:Null" "Dev:Console" }]
set MPWhelpmenu [list Menu -m -n "MPW Help" -p mpw::helpMenuProc $MPWcategories]
set Internalsmenu [list Menu -m -n "Internal Variables" -p mpw::internalsProc [mpw::buildMenuVar MPWinternals]]
set Variablesmenu  [list Menu -m -n "User Variables" -p mpw::variablesProc [mpw::buildMenuVar MPWvars 1]]
set Librariesmenu  [list Menu -m -n "Libraries Variables" -p mpw::librairiesProc [mpw::buildMenuVar MPWlibs 1]]

set MPWmenu [list Menu -m -n $mpwMenu -p mpw::menuProc ] 
lappend MPWmenu [list "Switch To MPW Shell" "(-" "<E<S/a<OExecute Lines" \
  "<S<B/a<OExecute and Toggle Target" "/b<O<BExecute the Buffer" "/a<I<O<BExecute a ScriptÉ" \
   "Open Out File" "Open Err File" "(-" "/iCommand LineÉ" "/hCommando BoxÉ" "(-" \
  "/W<I<BOpen a Worksheet" "Set MPW Mode" "/Y<O<BToolServer Shell" "(-" "/(<BEnclose withÉ" "/(<B<IRemove enclosers" \
  $SpecialCharsmenu "(-" $MPWhelpmenu \
  "Show MPW Bindings" "Show Current Variables" "(-" "Built in Commands..." $Internalsmenu $Variablesmenu $Librariesmenu ] 
eval $MPWmenu
unset SpecialCharsmenu MPWhelpmenu Internalsmenu \
  Variablesmenu Librariesmenu MPWmenu
# This menu will be inserted automatically when needed by AlphaTcl.


################################################################
#                Main Menu and Submenus procs                  #
################################################################

proc mpw::menuProc {menu item} {
    global MPWbuiltInCmds MPWmodeVars
    switch -- $item {
	"Switch To MPW Shell" {app::launchFore "MPS "}
	"Execute Lines" {mpw::sendtoTSProc}
	"Execute and Toggle Target" {
	    if {$MPWmodeVars(sendResultToBuffer)} {
		mpw::sendtoTSProc out
	    } else {
		mpw::sendtoTSProc inbuffer
	    }
	}
	"Execute the Buffer" {mpw::execBuffer}
	"Execute a Script" {
	    catch {getfile "Select an \"MPW\" script"} name
	    if {$name==""} {return}
	    mpw::scriptExec $name
	}
	"Command Line" {mpw::commandLine}
	"Commando Box" {mpw::commandoBox}
	"ToolServer Shell" {mpw::toolserverShell}
	"Open Out File" {mpw::openResult out}
	"Open Err File" {mpw::openResult err}
	"Set MPW Mode"  {
	    global prefixString
	    goto [minPos]
	    insertText "-*-MPWS-*-\n"
	    goto [minPos]
	    win::ChangeMode MPWS
	    comment::Line
	}
	"Open a Worksheet" {
	    new -n "MPW worksheet" -mode MPWS
	}
	"Enclose with" {mpw::encloseWith}
	"Remove enclosers" {mpw::removeEnclosers}
	"Built in Commands..." {
	    set cmd [listpick -p "Choose a command :"  ${MPWbuiltInCmds}]
	    if {$cmd==""} {return}
	    insertText $cmd
	}
	"Show MPW Bindings" {mpw::showBindings}
	"Show Current Variables" {mpw::displayExecResult "* Variables *" "[mpw::sendCmd set 1]"}
    }
}

proc mpw::helpMenuProc {menu item} {
    if {$item=="Help Summary"} {
	mpw::helpRequest "" MPW 0
    } else {
	mpw::helpRequest "$item" $item 0
    }
}

proc mpw::specialCharsProc {menu item} {
    regexp {![^ ] (.*)} $item dumm item
    set item [string trimleft $item]
    switch $item {
	"Characters Palette" {
	    mpw::showPalette
	    }
	"escape special chars" {insertText "¶"}
	"place insertion point" {insertText "Æ"}
	"beginning of" {insertText "¥"}
	"end of" {insertText "°"}
	"current selection" {insertText "¤"}
	"ellipsis" {insertText "É"}
	"match any string" {insertText "Å"}
	"not equal sign" {insertText "­"}
	"logical not" {insertText "Â"}
	"move backward" {insertText "Á"}
	"tag expression" {insertText "¨"}
	"pipe out" {insertText "|"}
	"redirect all output" {insertText "·"}
	"redirect errors" {insertText "³"}
	"depends on" {insertText "Ä"}
	default  {insertText "$item"} 
	}
}

proc mpw::internalsProc {menu item} {
    global tileLeft tileTop tileWidth errorHeight
    if {[regsub "^get " $item "" item]} {
	set t "echo \{$item\}"
	mpw::echoIt $t
	mpw::displayExecResult "* $t *" "[mpw::sendCmd "$t" 0]"
	mpw::addToHistory $t
	status::msg $t
    } else {
	insertText "\{$item\}"
    }
}

proc mpw::variablesProc {menu item} {
    global tileLeft tileTop tileWidth errorHeight
    set folder 0
    if {[regsub "^get " $item "" item]} {
	set t "echo \{$item\}"
	mpw::echoIt $t
	mpw::displayExecResult "* $t *" "[mpw::sendCmd "$t" 1]"
	status::msg $t
    } elseif {[regsub "^set " $item "" item]} {
	# We handle separately the case of Commands and DirectoryPath since they contain
	# a list of paths and not a single path. We can add to or remove from these lists.
	if {![expr [lsearch -exact [list Commands DirectoryPath] $item] == -1]} {
	    set desc(Commands) "to search for commands."
	    set desc(DirectoryPath) "to speed changing directories."
	    set args ""
	    lappend args [list -t "\'$item\' contains a list of directories" 5 5 290 20 \
	      -t "$desc($item)" 5 25 350 40 \
	      -t "Which action to perform ?" 5 45 350 60 \
	      -b Add 10 75 70 95 \
	      -b Remove 100 75 170 95 \
	      -b Cancel 200 75 260 95 ]
	    set values [eval dialog -w 360 -h 100 [join $args]]
	    if {[lindex $values 2]} {return} 
	    # Find the actual value
	    set t "echo \{$item\}"
	    set dirlist [mpw::sendCmd "$t" 0]
	    set dirlist [string trimright $dirlist "\n\r"]
	    set dirlist [split $dirlist ","]
	    # Perform the action
	    if {[lindex $values 0]} {
		catch {eval [concat get_directory -p \"Select a folder\"]} value
		if {$value == ""} { return }
		lappend dirlist [file join $value ""]
		status::msg "Added \"$value\" to \'$item\'"
	    } elseif {[lindex $values 1]} {
		set dir [listpick -p "Path to delete :"  $dirlist]
		if {$dir==""} {return}
		set idx [lsearch $dirlist $dir]
		set dirlist [lreplace $dirlist $idx $idx]
		status::msg "Removed \"$dir\" from \'$item\'"
	    }
	    # Send the new value
	    set dirlist [join $dirlist ","]
	    set t "set $item \"$dirlist\""
	    mpw::sendCmd "$t" 1
	    return
	}
	# Now the general case.
	set args ""
	lappend args [list -t "New value for $item" 5 5 350 25 \
	  -e "" 30 30 350 50 \
	  -b OK 10 70 70 90 \
	  -b Cancel 90 70 160 90 ]
	#  There is an extra button when we set the value of a path variable.
	if {![expr [lsearch -exact [list PrefsFolder SysTempFolder TempFolder ] $item] == -1]} {
	    set folder 1
	    lappend args " -b Browse 280 70 350 90"
	}
	set values [eval dialog -w 360 -h 100 [join $args]]
	set value [lindex $values 0]
	if {$folder} {
	    if {[lindex $values 3]} {
	    catch {eval [concat get_directory -p \"Select the \'$item\' folder\"]} value
	    if {$value == ""} { return }
	    }
	}
	if {[lindex $values 2] || $value == ""} {return} 
	set t "set $item \"$value\""
	mpw::sendCmd "$t"
	status::msg "Variable \'$item\' set to \"$value\""
    } else {
	insertText "$item "
    }
}

proc mpw::librairiesProc {menu item} {
    global tileLeft tileTop tileWidth errorHeight
    if {[regsub "^get " $item "" item]} {
	set t "echo \{$item\}"
	mpw::echoIt $t
	mpw::displayExecResult "* $t *" "[mpw::sendCmd "$t" 0]"
	mpw::addToHistory $t
	status::msg $t
    } elseif {[regsub "^set " $item "" item]} {
	catch {eval [concat get_directory -p \"Select a folder for $item\"]} value
	if {$value == ""} { return }
	set t "set $item \"$value\""
	mpw::sendCmd "$t"
	mpw::addToHistory $t
	status::msg "Variable \'$item\' set to \"$value\""
    } else {
	insertText "$item "
    }
}

proc mpw::echoIt {txt} {
    global mode MPWmodeVars
    if {!$MPWmodeVars(sendResultToBuffer) || !$MPWmodeVars(echoFromMenu) || $mode!="MPWS"} {return} 
    goto [maxPos]
    insertText "\n$txt"
}

proc mpw::toolserverShell {} {
    Shel::start "mpw" {*Toolserver shell*} \
      "Welcome to Alpha's MPW shell (using ToolServer via AppleEvents).\r"
    if {[catch {app::ensureRunning MPSX}]} {
	killWindow
    }
}

proc mpw::evaluate {t} {
    global Shel::histnum
    history add $t
    set Shel::histnum [history nextid]
    catch {tclAE::build::resultData ToolServer misc dosc ---- [tclAE::build::TEXT $t]} r
    return $r
}

proc mpw::Prompt {} { 
    global Shel::startPrompt Shel::endPrompt
    return "${Shel::startPrompt}mpw${Shel::endPrompt} " 
}


##########################
#   Executing commands   #
##########################

proc mpw::sendtoTSProc { {to ""} } {
    global TSsign tileLeft tileTop tileWidth errorHeight
    set hist 1
    set inipos [getPos]
    set lastpos [selEnd]
    if {[pos::compare $inipos == $lastpos]} {
	status::msg "Sending currentline to MPW"
	set inipos [lineStart [getPos]]
	set lastpos [nextLineStart [getPos]]
	if {[lookAt [pos::math $lastpos - 1]] == "\r"} {
	    set lastpos [pos::math $lastpos -1]
	}
    } 
    set t [getText $inipos $lastpos]
    set t [string trimright $t "\r\n"]
    # If the selection is more than one line we don't 
    # record it in the MPWhistory variable
    if {[regexp "\r" $t]} {
	set hist 0
    } 
    catch {regsub -all "(\r|\n)" $t "" titre}
    goto $lastpos
    set res [mpw::sendCmd "$t" $hist]
    if {$res!=""} {
	mpw::displayExecResult "* [string range $titre 0 50] *" $res $to
    } 
}

# This is the main proc to send commands to ToolServer.
# All the commands are recorded in the MPWhistory variable
# unless the proc is called with parameter 'hist' equal to 0.
proc mpw::sendCmd {cmdline {hist 1}} {
    global TSsign MPWmodeVars MPWhistory
    app::launchBack "$TSsign"
    catch {tclAE::build::resultData '$TSsign' misc dosc ---- [tclAE::build::TEXT $cmdline]}

    if {$hist} {mpw::addToHistory $cmdline} 
    return $rep
}

proc mpw::execBuffer {} {
    global TSsign MPWoutfile MPWerrfile MPWscript
    if {[winDirty]} {
	switch [askyesno -c "Dirty window '[lindex [winNames] 0]'. Do you want to save it ?"] {
	    "yes" {save}
	    "no" {}
	    "cancel" {return}
	}
    }
    app::launchBack "$TSsign"
    mpw::scriptExec [win::Current]
}

# This proc tells Tool Server to execute commands as a script. In this case
# the output (normal and errors) is written in .out and .err files which the user 
# can edit afterwards. 
# If the script has no option, it is a simple 'odoc' Apple Event.
# If there are options required by the script, we create a temporary script 
# which executes the original script with its options and redirects the output
# to the appropriate files.
# If either the .out or the .err file is already open (for instance, after a
# previous run), the script will fail : no redirection on an open file.
# We could add an MPW close command in the temporary script, but strangely 
# it does not work, so we choose to send a quit event to MPW.
proc mpw::scriptExec {script} {
    global MPWlastOpts MPWoutfile MPWerrfile MPWscript
    global TSsign tileLeft tileTop tileWidth errorHeight
    set MPWscript $script
    # First set the .out and .err files. We check the BackgroundOut and BackgroundErr
    # MPW variables. If they are undefined, default output is in the same folder as 
    # the script.
    set MPWoutfile($MPWscript) [string trimright [mpw::sendCmd "echo {BackgroundOut}" 0] "\n\r"]
    set MPWerrfile($MPWscript) [string trimright [mpw::sendCmd "echo {BackgroundErr}" 0] "\n\r"]
    if {$MPWoutfile($MPWscript)==""} {
	set MPWoutfile($MPWscript) "$MPWscript.out"
    }
    if {$MPWerrfile($MPWscript)==""} {
	set MPWerrfile($MPWscript) "$MPWscript.err"
    }
    # Do we add options for this script ?
    switch [askyesno -c "Do you want to specify parameters or flags ?"] {
	"yes" {
	    set args ""
	    lappend args [list -t "Enter required options" 5 5 190 25 \
	      -e "$MPWlastOpts" 30 30 540 70 \
	      -b Execute 10 90 100 110 \
	      -b Cancel	130 90 200 110 ]
	    set	values [eval dialog -w 550 -h 120 [join	$args]]
	    set	opts [lindex $values 0]
	    if {[lindex $values 2]} {return}
	    set MPWlastOpts $opts
	    set MPWtempfold [string trimright [mpw::sendCmd "echo {SystemFolder}" 0] "\n\r"]
	    if {$MPWtempfold==""} {
		set MPWtempfold [string trimright [mpw::sendCmd "echo {MPW}" 0] "\n\r"]
	    }	    
	    set fileId [open [file join $MPWtempfold tmpscrpt.mpw] w+]
	    set tempMPWscript [file join $MPWtempfold tmpscrpt.mpw]
	    puts $fileId "\"$MPWscript\" $opts > \"$MPWoutfile($MPWscript)\" ³ \"$MPWerrfile($MPWscript)\""
	    close $fileId
	    if {[app::isRunning "\"MPS \""]} {sendQuitEvent "'MPS '"}
	}
	"no" {
	    set tempMPWscript $MPWscript
	}
	"cancel" {return}
    }
    catch {eval "tclAE::send -p -t 6000 '$TSsign'" aevt odoc {----} [aebuild::alis $tempMPWscript]} rep
    status::msg "Processing done. Output in $MPWoutfile($MPWscript)"
    return    
}

proc mpw::openResult {ext} {
    global MPWscript MPWoutfile MPWerrfile
    if {$MPWscript == ""} {
	catch {getfile "Select the $ext file"} name
	if {$name==""} {return}
	edit -c $name
	return
    } 
    set f [set "MPWS${ext}file($MPWscript)"]
    if {$f == ""} {
	set f "$MPWscript.$ext"
    }
    if {[file exists $f]} {
	edit -c $f
    } else {
	alertnote "Can't find file $f"
    }
}

proc mpw::commandoBox {} {
    global MPWlastCmdo
    set args ""
    lappend args [list -t "Enter a command name :" 5 5 190 25 \
      -e "$MPWlastCmdo" 30 30 150 50 \
      -b Commando 10 70 100 90 \
      -b Cancel 120 70 190 90 ]
    set values [eval dialog -w 200 -h 100 [join $args]]
    set word [lindex $values 0]
    if {[lindex $values 2] || $word == ""} {return}
    mpw::getCommando $word
}

proc mpw::getCommando {word} {
    global TSsign MPWlastCmdo
    set MPWlastCmdo $word
    app::launchFore "$TSsign"
    set res [mpw::sendCmd "${word}É"]
    if {[regexp "Command.*not found" $res]} {
	app::launchFore "ALFA"
	alertnote "Could not find the \"Commando\" command : check the \'Commands\' variable\
	  or put aliases of the \'Scripts\' and \'Tools\' folders\
	  in the same folder as Tool Server."
    } elseif {![regexp "Execution of MPW.Script terminated" $res]} {
	mpw::displayExecResult "* Commando $word *" $res
    }
}

proc mpw::commandLine {} {
    global MPWlastCmdLine tileLeft tileTop tileWidth errorHeight
    global MPWmodeVars
    set args ""
    lappend args [list -t "Enter a command line" 5 5 190 25 \
      -e "$MPWlastCmdLine" 30 30 550 70 \
      -b Execute 10 90 100 110 \
      -b Cancel	130 90 200 110 \
      -b "Script..." 230 90 300 110 \
      -c "Insert result in buffer" $MPWmodeVars(sendResultToBuffer) 385 90 540 110 ]
    set	values [eval dialog -w 560 -h 120 [join	$args]]
    set	cmdline	[lindex	$values	0]
    if {[lindex $values	4]} {
	set to inbuffer
    } else {
	set to "out"
    }
    if {[lindex $values	3]} {
	catch {getfile "Select an \"MPW\" script"} name
	if {$name==""} {return}
	set MPWlastCmdLine "\"$name\" "
	mpw::commandLine
	return
    }
    if {[lindex	$values	2] || [expr {$cmdline == ""}]} {
	return
    }
    set MPWlastCmdLine $cmdline
    mpw::displayExecResult "* [string range $cmdline 0 50] *" "[mpw::sendCmd "$cmdline"]" $to
}

proc mpw::helpRequest {arg {title 0} {typ 1}} {
    global mode
    if {$mode!="MPWS" || ![llength [winNames]]} {
	mpw::menuProc "¥146" "Open a Worksheet"
    } 
    set res [mpw::sendCmd "help $arg" $typ]
    if {[regexp "Unable to open the help file" $res]} {
	app::launchFore "ALFA"
	alertnote "Couldn't find the \"MPW.Help\" file : put a copy of this file \
	  in the same directory as the ToolServer application \
	  or in the MPW preferences folder."
    } else {
	mpw::displayExecResult "* $title Help *" $res 
	win::ChangeMode MPWS
    }
}

#####################
#   Utility procs   #
#####################

proc mpw::encloseWith {{encloser ""}} {
    if {$encloser==""} {
	set lftencloser [statusPrompt "Enter the left encloser : "]
    } else {
	set lftencloser $encloser
    }
    switch $lftencloser {
	"(" {
	    set rtencloser ")"
	}
	"\{" {
	    set rtencloser "\}"
	}
	"\[" {
	    set rtencloser "\]"
	}
	"<" {
	    set rtencloser ">"
	}
	"Ç" {
	    set rtencloser "È"
	}
	default {
	    set rtencloser $lftencloser
	}
    }
    set inipos [getPos]
    set lastpos [selEnd]
    if {[pos::compare $inipos == $lastpos]} {
	backwardWord
	insertText $lftencloser
	forwardWord
	insertText $rtencloser
    } else {
	goto $lastpos
	insertText $rtencloser
	goto $inipos
	insertText $lftencloser
    }
}

proc mpw::removeEnclosers {} {
    global MPWenclosers
    set inipos [getPos]
    set lastpos [selEnd]
    if {[pos::compare $inipos == $lastpos]} {
	backwardWord
	set inipos [getPos]
	forwardWord
	set lastpos [getPos]
    }
    set lftchar [lookAt [pos::math $inipos - 1]]
    set rtchar [lookAt $lastpos]
    if {[lsearch $MPWenclosers $rtchar]!="-1"} {
	deleteText $lastpos [pos::math $lastpos + 1]
    }
    if {[lsearch $MPWenclosers $lftchar]!="-1"} {
	deleteText [pos::math $inipos - 1] $inipos
    }
}

proc mpw::displayExecResult {title result {in ""} } {
    global tileLeft tileTop tileWidth errorHeight
    global MPWmodeVars mode
    if {$MPWmodeVars(sendResultToBuffer) && [expr {$in!="out"}]} {
	set in $MPWmodeVars(sendResultToBuffer) 
    } 
    if {$mode!="MPWS"} {set in ""} 
    if {$in!="" && $in!="out"} {
	goto [maxPos]
	insertText "\n$result"
    } else {
	new -n "$title" \
	  -g $tileLeft $tileTop [expr $tileWidth*0.5] $errorHeight \
	  -info "$result" -mode MPWS
    }
}

proc mpw::optionEnterKey {} {
    global TSsign MPWlastCmdo
    set inipos [getPos]
    set lastpos [selEnd]
    if {[pos::compare $inipos == $lastpos]} {
	backwardWord
	set inipos [getPos]
	forwardWord
	set lastpos [getPos]
    }
    set word [getText $inipos $lastpos]    
    mpw::getCommando $word
}

proc mpw::addToHistory {cmdline} {
    global MPWmodeVars MPWhistory
    if {[expr [string length $cmdline]<50]} {
	lappend MPWhistory "$cmdline"  
    } 
    if {[llength ${MPWhistory}] > $MPWmodeVars(histBufferSize)} {
	set MPWhistory [lrange ${MPWhistory} 1 end]
    }
}

proc mpw::shadowHist {name} {
    global MPWmodeVars MPWhistory
    if {[expr [llength ${MPWhistory}] > $MPWmodeVars(histBufferSize)]} {
	set diff [expr [llength ${MPWhistory}] - $MPWmodeVars(histBufferSize)]
	set MPWhistory [lrange ${MPWhistory} $diff end]
    } 
}

proc mpw::browseHist {diff} {
    global MPWmodeVars MPWhistory MPWHistNum
    if {![llength ${MPWhistory}]} {return} 
    set pos [getPos]
    if {[pos::compare $pos == [selEnd]]} {
        if {$diff=="1"} {
	  return
        } else {
	  set MPWHistNum [expr [llength ${MPWhistory}]-1]
        }
    } else {
        set MPWHistNum [expr $MPWHistNum + $diff]
        if {$MPWHistNum==-1} {
	  set MPWHistNum 0
        } 
    }
    if {$MPWHistNum==[llength ${MPWhistory}]} {
        set cmd ""
    } else {
        set cmd [lindex ${MPWhistory} $MPWHistNum]
    }
    deleteText $pos [selEnd]
    insertText $cmd
    selectText $pos [pos::math  $pos + [string length $cmd]]
}

# ------------------------------------------------------
# Floating palette proc
# ------------------------------------------------------

proc mpw::showPalette {} {
    global tileLeft tileTop tileWidth
    Menu -n "SpecialChars" -p mpw::paletteProc {
	"¶"
	"Æ"
	"¥"
	"°"
	"¤"
	"É"
	"Å"
	"­"
	"Â"
	"Á"
	"¨"
	"|"
	"·"
	"³"
	"Ä"
    }
    float -m "SpecialChars"  -h 25 -w 30 -t $tileTop -l [expr $tileWidth -100] -n ""
}

# Ellipses are eliminated, so we must reintroduce them.
proc mpw::paletteProc {menu item} {
    if {$item==""} {
        set item É
    } 
    insertText $item
}

proc mpw::showBindings {} {
    global tileLeft tileTop tileWidth errorHeight
    set mess "KEY BINDINGS AVAILABLE IN THE MPW MODE\n\n"
    append mess "Executing commands\n"
    append mess "cmd-return or enter          	execute a line or a selection\n"          
    append mess "ctrl-cmd-return or ctrl-enter	execute and toggle result's destination\n"
    append mess "ctrl-cmd-enter               	execute the buffer as script\n"           
    append mess "opt-ctrl-cmd-return          	execute a script...\n"                    
    append mess "opt-enter or opt-cmd-return  	open command's commando box\n"            
    append mess "F4 or ctrl-opt-k             	ask for commando box...\n"                
    append mess "F5                           	open command line window\n"               
    append mess "F6                           	open special chars palette\n"             
    append mess "ctrl-up                      	browse up in commands history\n"          
    append mess "ctrl-down                    	browse down in commands history\n"        
    append mess "\nEnclosing\n"               
    append mess "ctrl-\"                      	surround with \" \"\n"                    
    append mess "ctrl-'                       	surround with ' '\n"                      
    append mess "ctrl-`                       	surround with ` `\n"                      
    append mess "ctrl-(                       	surround with ( )\n"                      
    append mess "ctrl-opt-(                   	surround with \{ \}\n"                    
    append mess "shift-ctrl-opt-(             	surround with \[ \]\n"                    
    append mess "ctrl-<                       	surround with < >\n"                      
    append mess "ctrl-opt-<                   	surround with Ç È\n\n"                      
    append mess "ctrl-)                       	remove any enclosing pair\n"              
    new -g $tileLeft $tileTop [expr $tileWidth*.5] [expr $errorHeight *1.8] \
      -n "* MPW Mode Bindings *" -info $mess
    set start [minPos]
    while {![catch {search -f 1 -s -r 1 -i 1 {^.*\t} $start} res]} {
	text::color [lindex $res 0] [lindex $res 1] 1
	set start [lindex $res 1]
    }
    text::color 0 [nextLineStart 0] 5
    refresh
}


##########   Key Bindings   ############

# Enclosing
# ---------
# ctrl-( :
Bind 0x17 <z>   {mpw::encloseWith "("} MPWS
# ctrl-opt-( :
Bind 0x17 <zo>  {mpw::encloseWith "\{"} MPWS
# shift-ctrl-opt-( :
Bind 0x17 <soz> {mpw::encloseWith "\["} MPWS
# ctrl-' :
Bind 0x15 <z>  {mpw::encloseWith "\'" } MPWS
# ctrl-" :
Bind 0x14 <z> {mpw::encloseWith "\""} MPWS
# ctrl-` :
Bind 0x2a <z> {mpw::encloseWith "\`"} MPWS
# ctrl-< :
Bind 0x32 <z> {mpw::encloseWith "<"} MPWS
# ctrl-opt-< :
Bind 0x32 <oz> {mpw::encloseWith "Ç"} MPWS

# ctrl-) to remove any encloser :
Bind 0x1b <z>  mpw::removeEnclosers MPWS

# Executing commands
# ------------------
# The enter key is 0x34 on the PowerBook (0x4c otherwise)
# 
# cmd-return or enter :
Bind 0x24 <c> {mpw::sendtoTSProc} MPWS
Bind 0x34 {mpw::sendtoTSProc} MPWS
Bind 0x4c {mpw::sendtoTSProc} MPWS
# control-enter or control-command-return :
Bind 0x24 <cz> {mpw::menuProc "¥146" "Execute and Toggle Target"} MPWS
Bind 0x34 <z> {mpw::menuProc "¥146" "Execute and Toggle Target"} MPWS
Bind 0x4c <z> {mpw::menuProc "¥146" "Execute and Toggle Target"} MPWS
# option-enter and option-command-return :
Bind 0x24 <co> {mpw::optionEnterKey} MPWS
Bind 0x34 <o> {mpw::optionEnterKey} MPWS
Bind 0x4c <o> {mpw::optionEnterKey} MPWS
# control-command-enter :
Bind 0x34 <cz> {mpw::menuProc "¥146" "Execute the Buffer"} MPWS
Bind 0x4c <cz> {mpw::menuProc "¥146" "Execute the Buffer"} MPWS
# option-control-command-return :
Bind 0x24 <coz> {mpw::menuProc "¥146" "Execute a Script"} MPWS
# ctrl-up and ctrl-down
Bind up <z> {mpw::browseHist -1} MPWS
Bind down <z> {mpw::browseHist 1} MPWS
# control-option-k and F4 to get a commando box :
Bind 'k' <oz> {mpw::commandoBox} MPWS
Bind F4 {mpw::commandoBox} MPWS
# F5 to call up the command line window :
Bind F5 {mpw::commandLine} MPWS
# F6 to open special chars palette
Bind F6 {mpw::showPalette} MPWS


#############################
#                           #
#   Mode specific goodies   #
#                           #
#############################

#########   Syntax Coloring  ###########

set MPWKeyWords { 
 AboutBox AddMenu AddPane Adjust Alert Alias Align Asm AuthorInfo Backup Beep
 Begin Break Browser BuildCommands BuildMenu BuildProgram Canon Catenate CheckIn
 CheckOut CheckOutDir Choose Clear Close CMarker Commando Compare CompareFiles
 CompareRevisions Confirm Continue Copy Count CreateMake Cut Date Delete
 DeleteCharLeft DeleteCharRight DeleteEndOfFile DeleteEndOfLine DeleteMenu
 DeleteNames DeletePane DeleteRevisions DeleteStartOfFile DeleteStartOfLine
 DeleteWordLeft DeleteWordRight DeRez Directory DirectoryMenu DoIt DumpCode
 DumpFile DumpObj DumpPEF DumpSYM DumpXCOFF Duplicate DuplicateNameRevisions
 Echo Editor Eject Else End Entab Equal Erase Evaluate Execute Exists Exit
 Export FileDiv Files Find Flush FlushAllVolumes For Format Gestalt Get GetErrorText
 GetFileName GetListItem Help HideWindows If ILink ILinkToSYM Lib Line Link 
 LockNameRevisions Loop Make MakeDepend MakeErrorFile MakeFlat MakePEF MakePPCCodeRsrc
 MakeStub MakeSYM Mark Markers MatchIt MergeBranch MergeFragment ModifyReadOnly ModPEF 
 Monitors Mount MountProject Move MoveCharLeft MoveCharRight MoveEndOfFile MoveEndOfLine
 MoveLineDown MoveLineUp MovePageDown MovePageUp MoveStartOfFile MoveStartOfLine
 MoveWindow MoveWordLeft MoveWordRight MrC MrCpp MrPlus MultiSearch NameRevisions
 New Newer NewFolder NewKeyMap NewProject ObsoleteNameRevisions ObsoleteProjectorFile
 Open OrphanFiles Parameters Pascal PasMat PasRef Paste PerformReport PlaySound Position 
 PPCAsm PPCLink PPCProff Print PrintProff ProcNames Project ProjectInfo Quit Quote Redo
 Rename RenameProjectorFile Replace Request ResEqual ResolveAlias Revert Rez
 RezDet RotatePanes RotateWindows RProj RShell Save SaveOnClose SC SCpp SCPre
 Search SelectCharLeft SelectCharRight SelectEndOfFile SelectEndOfLine SelectLineDown
 SelectLineUp SelectPageDown SelectPageUp SelectStartOfFile SelectStartOfLine
 SelectWordLeft SelectWordRight SendAE Set SetDirectory SetFile SetKey SetPrivilege
 SetShellSize SetVersion Shift shlb2stub ShowSelection ShowWindows ShutDown
 SizeWindow Sort StackWindows StreamEdit Target TickCount TileWindows TransferCkid
 Translate Unalias Undo Unexport UnlockNameRevisions  Unmangle UnmangleTool Unmark Unmount
 UnmountProject UnmountVolume UnObsoleteNameRevisions UnObsoleteProjectorFile
 Unset UnSetKey UpdateProjectorDatabase UserVariables Version VersionList Volumes WhereIs
 Which Windows ZoomWindow
}

regModeKeywords  -i "\}" -i "\{" -i ">" -i "<" -i "³" -I $MPWmodeVars(bracesColor)\
  -e {#} -c $MPWmodeVars(commentColor) \
  -k $MPWmodeVars(keywordColor)  -s $MPWmodeVars(stringColor) MPWS $MPWKeyWords

# # # # # Variables 
set MPWvarKeyWords { 
 Active AIncludes Aliases AllowCmdsOnlyInWorkSheet AllowColorizing AllowColorUserExperience
 AllowDraggingOut AllowMultipleUndo AllowWhiteSpaceDelimiter AutoIndent BackgroundErr
 BackgroundOut BackgroundShell Boot CFM68KLibraries CaseSensitive CIncludes CLibraries
 Command CursorForDragging DirectoryPath DontFlushServers DontFlushVolumes DynaScroll
 ExtendWordSet Font FontSize HeapCheck HideHelpKey IgnoreCmdPeriod InhibitMarkCopy
 Libraries MPW MPWVersion NewKeyboardLayout NewWindowRect PInterfaces PLibraries 
 PPCLibraries PrefsFolder PrintOptions ProjectorVersion RIncludes ScreenUpdateDelay
 SMIncludes SearchBackward SearchType SearchWrap SharedLibraries ShellDirectory SMDefines
 SMOptions StackOptions Status SuppressDialogs SystemFolder SysTempFolder Tab TabWidthChar
 TempFolder Test TileOptions ToolSleepTime TraceFailures User UseStandardFile WordSet
 Worksheet ZoomHeight ZoomWidth ZoomWindowRect
}

regModeKeywords  -a -k $MPWmodeVars(variablesColor) MPWS $MPWvarKeyWords

# # # # # Categories 
set MPWcatKeyWords { 
 CFM-68K Characters Commands Dev:Console Dev:Null Dev:StdErr Dev:StdIn Dev:StdOut 
 Editing Expressions FileSystem Languages Launch Miscellaneous Patterns PowerMacintosh 
 Projector Resources Scripting Selections Shell Shortcuts System Variables Window
}

regModeKeywords  -a -k $MPWmodeVars(categoriesColor) MPWS $MPWcatKeyWords


############   Completions  ################

set completions(MPWS) {contraction completion::cmd Lc completion::electric}

set MPWcmds [concat $MPWKeyWords $MPWvarKeyWords $MPWcatKeyWords ]

set MPWcmds [lsort -dictionary $MPWcmds]

# We don't need MPWKeyWords, MPWvarKeyWords and MPWcatKeyWords anymore :
unset MPWKeyWords
unset MPWvarKeyWords
unset MPWcatKeyWords

set MPWlccmds {}
foreach item $MPWcmds {
    lappend MPWlccmds [string tolower $item]
}
unset -nocomplain item

# # # # # Abbreviations # # # # #
# The MPW Shell has various control structures, including the Begin É End
# structure, the If É Else É End structure, the For É End structure, and the
# Loop É End structure.
set MPWelectrics(bg)   "×kill0Begin\n\t¥¥\nEnd\n¥¥"
set MPWelectrics(for)  "×kill0For ¥¥ In ¥¥\n\t¥¥\nEnd\n¥¥"
set MPWelectrics(loop)   "×kill0Loop\n\t¥¥\nEnd\n¥¥"
set MPWelectrics(if)   "×kill0If\n\t¥¥\nEnd\n¥¥"
set MPWelectrics(ifel)   "×kill0If\n\t¥¥\n\tElse\n\t¥¥\nEnd\n¥¥"

# We define here a set of "intuitive" abbreviations for long variable names :
# just type the initials of the words which compose the variable name.
# There are duplicates :
# - sd could be ShellDirectory, SuppressDialogs or ShutDown. We define sd, sdg, sdn resp.
# - tf could be TempFolder or TraceFailures. We define tf and tfs resp.
set MPWelectrics(ac)   "×kill0AllowColorizing"
set MPWelectrics(acoiws)   "×kill0AllowCmdsOnlyInWorkSheet"
set MPWelectrics(acue)   "×kill0AllowColorUserExperience"
set MPWelectrics(ado)   "×kill0AllowDraggingOut"
set MPWelectrics(ai)   "×kill0AutoIndent"
set MPWelectrics(amu)   "×kill0AllowMultipleUndo"
set MPWelectrics(awsd)   "×kill0AllowWhiteSpaceDelimiter"
set MPWelectrics(be)   "×kill0BackgroundErr"
set MPWelectrics(bo)   "×kill0BackgroundOut"
set MPWelectrics(bs)   "×kill0BackgroundShell"
set MPWelectrics(cfd)   "×kill0CursorForDragging"
set MPWelectrics(cod)   "×kill0CheckOutDir"
set MPWelectrics(cs)   "×kill0CaseSensitive"
set MPWelectrics(dcl)   "×kill0DeleteCharLeft"
set MPWelectrics(dcr)   "×kill0DeleteCharRight"
set MPWelectrics(deof)   "×kill0DeleteEndOfFile"
set MPWelectrics(deol)   "×kill0DeleteEndOfLine"
set MPWelectrics(dfs)   "×kill0DontFlushServers"
set MPWelectrics(dfv)   "×kill0DontFlushVolumes"
set MPWelectrics(dnr)   "×kill0DuplicateNameRevisions"
set MPWelectrics(dp)   "×kill0DirectoryPath"
set MPWelectrics(ds)   "×kill0DynaScroll"
set MPWelectrics(dsof)   "×kill0DeleteStartOfFile"
set MPWelectrics(dsol)   "×kill0DeleteStartOfLine"
set MPWelectrics(dwl)   "×kill0DeleteWordLeft"
set MPWelectrics(dwr)   "×kill0DeleteWordRight"
set MPWelectrics(ews)   "×kill0ExtendWordSet"
set MPWelectrics(fs)   "×kill0FontSize"
set MPWelectrics(get)   "×kill0GetErrorText"
set MPWelectrics(gfn)   "×kill0GetFileName"
set MPWelectrics(gli)   "×kill0GetListItem"
set MPWelectrics(hc)   "×kill0HeapCheck"
set MPWelectrics(hhk)   "×kill0HideHelpKey"
set MPWelectrics(icp)   "×kill0IgnoreCmdPeriod"
set MPWelectrics(imc)   "×kill0InhibitMarkCopy"
set MPWelectrics(lnr)   "×kill0LockNameRevisions"
set MPWelectrics(mcl)   "×kill0MoveCharLeft"
set MPWelectrics(mcr)   "×kill0MoveCharRight"
set MPWelectrics(mef)   "×kill0MakeErrorFile"
set MPWelectrics(meof)   "×kill0MoveEndOfFile"
set MPWelectrics(meol)   "×kill0MoveEndOfLine"
set MPWelectrics(mld)   "×kill0MoveLineDown"
set MPWelectrics(mlu)   "×kill0MoveLineUp"
set MPWelectrics(mpd)   "×kill0MovePageDown"
set MPWelectrics(mpu)   "×kill0MovePageUp"
set MPWelectrics(mro)   "×kill0ModifyReadOnly"
set MPWelectrics(msof)   "×kill0MoveStartOfFile"
set MPWelectrics(msol)   "×kill0MoveStartOfLine"
set MPWelectrics(mwl)   "×kill0MoveWordLeft"
set MPWelectrics(mwr)   "×kill0MoveWordRight"
set MPWelectrics(nkl)   "×kill0NewKeyboardLayout"
set MPWelectrics(nkm)   "×kill0NewKeyMap"
set MPWelectrics(nwr)   "×kill0NewWindowRect"
set MPWelectrics(onr)   "×kill0ObsoleteNameRevisions"
set MPWelectrics(opf)   "×kill0ObsoleteProjectorFile"
set MPWelectrics(pf)   "×kill0PrefsFolder"
set MPWelectrics(po)   "×kill0PrintOptions"
set MPWelectrics(pv)   "×kill0ProjectorVersion"
set MPWelectrics(rpf)   "×kill0RenameProjectorFile"
set MPWelectrics(sb)   "×kill0SearchBackward"
set MPWelectrics(scl)   "×kill0SelectCharLeft"
set MPWelectrics(scr)   "×kill0SelectCharRight"
set MPWelectrics(sd)   "×kill0ShellDirectory"
set MPWelectrics(sdg)   "×kill0SuppressDialogs"
set MPWelectrics(sdn)   "×kill0ShutDown"
set MPWelectrics(seof)   "×kill0SelectEndOfFile"
set MPWelectrics(seol)   "×kill0SelectEndOfLine"
set MPWelectrics(sf)   "×kill0SystemFolder"
set MPWelectrics(sld)   "×kill0SelectLineDown"
set MPWelectrics(slu)   "×kill0SelectLineUp"
set MPWelectrics(so)   "×kill0StackOptions"
set MPWelectrics(soc)   "×kill0SaveOnClose"
set MPWelectrics(spd)   "×kill0SelectPageDown"
set MPWelectrics(spu)   "×kill0SelectPageUp"
set MPWelectrics(ssof)   "×kill0SelectStartOfFile"
set MPWelectrics(ssol)   "×kill0SelectStartOfLine"
set MPWelectrics(sss)   "×kill0SetShellSize"
set MPWelectrics(st)   "×kill0SearchType"
set MPWelectrics(stf)   "×kill0SysTempFolder"
set MPWelectrics(sud)   "×kill0ScreenUpdateDelay"
set MPWelectrics(sw)   "×kill0SearchWrap"
set MPWelectrics(swl)   "×kill0SelectWordLeft"
set MPWelectrics(swr)   "×kill0SelectWordRight"
set MPWelectrics(tf)   "×kill0TempFolder"
set MPWelectrics(tfs)   "×kill0TraceFailures"
set MPWelectrics(to)   "×kill0TileOptions"
set MPWelectrics(tst)   "×kill0ToolSleepTime"
set MPWelectrics(twc)   "×kill0TabWidthChar"
set MPWelectrics(unr)   "×kill0UnlockNameRevisions"
set MPWelectrics(uonr)   "×kill0UnObsoleteNameRevisions"
set MPWelectrics(uopf)   "×kill0UnObsoleteProjectorFile"
set MPWelectrics(upd)   "×kill0UpdateProjectorDatabase"
set MPWelectrics(usf)   "×kill0UseStandardFile"
set MPWelectrics(usk)   "×kill0UnSetKey"
set MPWelectrics(ws)   "×kill0WordSet"
set MPWelectrics(zh)   "×kill0ZoomHeight"
set MPWelectrics(zw)   "×kill0ZoomWidth"
set MPWelectrics(zwr)   "×kill0ZoomWindowRect"

####   Contractions   ####
set MPWelectrics(d'si)  "×kill0Dev:StdIn"
set MPWelectrics(d'so)  "×kill0Dev:StdOut"
set MPWelectrics(d'se)  "×kill0Dev:StdErr"
set MPWelectrics(d'n)  "×kill0Dev:Null"
set MPWelectrics(d'c)  "×kill0Dev:Console"


namespace eval mpw::Completion {}

proc mpw::Completion::Lc {dummy} {
    global MPWlccmds
    set cmd [completion::lastWord pos]
    completion::Find $cmd [completion::fromList $cmd MPWlccmds]
}	


##########   Double-click   ############
# If you Command-Double-Click on a keyword you access its syntax.
proc mpw::DblClick {from to} {
    global TSsign MPWinternals MPWvars MPWlibs
    selectText $from $to
    set word [getText $from $to]
    set var(internals) internal
    set var(vars) user
    set var(libs) librairies
    # First check if it is a MPW variable.
    foreach type [list internals vars libs] {
	if {[expr {[lsearch -exact [set MPWS${type}] "$word"] > -1}]} {
	    alertnote "\"$word\" is a MPW $var($type) variable. See the \"$var($type) variables\" submenu."
	    return
	}
    }
    # If not, ask Tool Server for help
    app::launchBack "$TSsign"
    mpw::helpRequest "$word" "\'$word\'"
}

##########    The "{}" menu   ############
# The "{}" pop-up menu contains the variables defined in a script file. 
# We list here all the "set" statements.
proc mpw::parseFuncs {} {
    global funcExpr
    set pos [minPos]
    set m {}
    while {[set res [search -s -f 1 -r 1 -i 1 -n "^\[ \t\]*$funcExpr" $pos]] != ""} {
	set txt [eval getText $res]
	regsub "\[ \t\]*\[Ss\]et +" $txt "" txt
	lappend m [list $txt [lindex $res 0]]
	set pos [lindex $res 1]
    }
    set m [lsort -dictionary $m]
    return [join $m]
}

##########   Option-click on title bar   ############
# If you Option-Click on a the title bar, you get a list of almost all the  
# last commands sent to ToolServer. The maximum number of commands recorded
# is set with the variable 'Hist Buffer Size' in the mode preferences.
proc mpw::OptionTitlebar {} {
    global MPWmodeVars MPWhistory
    global minItemsInTitlePopup
    set minItemsInTitlePopup 1
    set l ${MPWhistory}
    lappend l  "-"
    lappend l "Reset History List"
    return $l
}

proc mpw::OptionTitlebarSelect {item} {
    global MPWmodeVars MPWhistory
    if {$item == "Reset History List"} {
        set MPWhistory {}
	return
    } 
    insertText $item
}

