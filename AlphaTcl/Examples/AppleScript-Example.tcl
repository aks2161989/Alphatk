# File : "AppleScript-Example.tcl"
#                        Created : 2002-10-09 17:00:54
#              Last modification : 2002-10-09 17:00:54
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# www : <http://webperso.easyconnect.fr/bdesgraupes/>

loadAMode "Scrp"
set filename [help::pathToExample "AppleScript-Example"]
set filesList ""
set choices ""
set tutorialname "* AppleScript Tutorial *"

if {[catch {glob -path "${filename}." *} filesList]} {
    # There are no files with this name plus an extension.
    set filesList ""
} 

if {[file isfile $filename]} {
    # The filename exists without an extension, so we add that too.
    lappend filesList $filename
} 

foreach f $filesList {
    set ext [string range [file extension $f] 1 end]
    set tail [file tail $f]
    if {$ext == ""} { set ext "text" }
    if {$ext == "txt" } { set ext "text" }
    if {$ext == "tcl" } { continue }
    set ch "View $ext tutorial ($tail)"
    lappend choices $ch
    set choice($ch) $f
}


switch -- [llength $choices] {
    0 {
	alertnote "No tutorial was found."
	return
    }
    1 {
	set tutorialFile [lindex $choices 0]
    }
    default {
	if {[catch {set tutorialFile [listpick -p "Choose a tutorial" $choices]}]} {
	    return
	} 
	set tutorialFile $choice($tutorialFile)
    }
}

# Find if there are sample scripts in the Examples folder
set scriptsList [concat [glob -nocomplain -type osas -dir [file join $HOME Examples] *] \
  [glob -nocomplain -type APPL -dir [file join $HOME Examples] *]]

# If yes, ask if it is OK to move them to the AppleScript Mode working folder.
# Don't overwrite existing scripts.
set relname [file join [file tail [file dir $ScrpmodeVars(appleScriptsFolder)]] \
  [file tail $ScrpmodeVars(appleScriptsFolder)]]
set msg "There are sample scripts in the Examples folder\
	    which can serve for demonstration purpose.\
	    Do you want them to be moved to AppleScript Mode's current\
	    working folder ($relname) ? Already\
	    existing scripts will not be overwritten."

if {[llength $scriptsList] && [askyesno $msg] == "yes"} {
    Scrp::checkWorkingFolder
    foreach f $scriptsList {
	if {![file exists [file join $ScrpmodeVars(appleScriptsFolder) [file tail $f]]]} {
	    AEBuild -r 'MACS' core move ---- [tclAE::build::filename $f] \
	      insh [tclAE::build::foldername $ScrpmodeVars(appleScriptsFolder)]
	} 
    } 
} 


# Open the selected tutorial file
switch -- [file extension $tutorialFile] {
    ".html" {
	htmlView $tutorialFile
    }
    ".txt" - "" {
	set m Text
	new -n $tutorialname -m $m -text [file::readAll $tutorialFile] -shell 1
	goto [minPos]
	set cmt [comment::Characters General]
	set    t "\r$cmt  Modify as much as you like ! \r\r"
	append t "$cmt  None of the changes you make will affect the actual file.  If you close \r"
	append t "$cmt  the window and then click on the hyperlink again, you will start with the \r"
	append t "$cmt  same example as before.  This also means that you cannot send this window \r"
	append t "$cmt  to other applications -- technically, it doesn't exist as a file. \r\r"
	append t "$cmt  Type \"control-Help\" to open any available help for $m mode. \r\r"
	insertText  $t
	help::hyperiseEmails
	help::hyperiseUrls
	goto [minPos]
	markFile
    }
    default {
	file::openInDefault $tutorialFile
    }
}


unset filename tutorialname relname filesList scriptsList choice choices tutorialFile
