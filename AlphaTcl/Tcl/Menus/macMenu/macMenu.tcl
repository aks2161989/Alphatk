## -*-Tcl-*- (nowrap)
## 
 # This file : macMenu.tcl
 # Created : 2001-01-13 17:57:50
 # Last modification : 2005-06-20 18:36:34
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
 # Description :
 #            This is a menu for Alpha. It allows you to achieve various
 #            kinds of file manipulations from within Alpha and to interact
 #            with the file system with great flexibility.
 # 
 # The macMenu package is split into several files. It will not work
 # properly (will not work at all) if any of them is missing. Here is a
 # list of the macMenu files :
 #     macMenu.tcl				This file
 #     macMenuDialogs.tcl		Dialog windows procs
 #     macMenuDialogValues.tcl	Handling of dialog values
 #     macMenuDialogParts.tcl	Building pieces for the dialogs
 #     macMenuFinder.tcl		System wide events to the Finder
 #     macMenuEngine.tcl		Files management execution
 #     macMenuInfo.tcl			Finder items display info procs
 #     macMenuGetInfo.tcl		Finder items get info procs
 #     macMenuInfoValues.tcl	Handling of Info windows
 #     macMenuUtils.tcl			Various utility procs
 #     macMenuShell.tcl			Mac Shell definition procs
 #     macMenuInterface.tcl		Exported procs and basic Mac Shell commands
 #     macMenuShellMore.tcl		More Mac Shell commands
 #     macMenuContextual.tcl	Contextual menu additions by Craig B Upright
 #     
 # Please read the doc in the "Mac Menu Help" file (located in the Help
 # menu once the package is installed) and the "Mac Menu Tutorial" (via the
 # Get Info submenu of Mac Menu).
 # 
 # (c) Copyright : Bernard Desgraupes, 2001-2005
 #         All rights reserved.
 # This software is free software. See licensing terms in the MacMenu Help file.
 # 
 ##

alpha::menu macMenu 2.3 global "•303" {
    if {${alpha::macos} != 2} {
	error "The 'Mac Menu' is only useful on MacOSX"
    }
    package::addPrefsDialog macMenu
} {macMenuTcl} {} uninstall {this-directory} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/> 
} requirements {
    if {${alpha::macos} != 2} {
	error "The 'Mac Menu' is only useful on MacOSX"
    }
} description {
    Accesses and manipulates your Mac's filesystem
} help {
    file "Mac Menu Help" 
} preinit {
    if {${alpha::macos} != 2} {
		# Includes items to display and/or change information about 
		# the active window or its file resources
		newPref flag macWindowMenu 0 contextualMenu
		# Includes items to display and/or change information about
		# your System's file structure, including locking, trashing,
		# renaming, copying (etc.) files and directories
		newPref flag macSystemMenu 0 contextualMenu
		menu::buildProc macWindow {mac::buildCMWindow}
		menu::buildProc macSystem {mac::buildCMSystem}
		hook::register contextualPostBuildHook {mac::postBuildCMWindow}
    }
}

proc macMenu.tcl {} {}

namespace eval mac {}


# # # macMenu preferences # # #
# -----------------------------

# List here the extensions which will have a checkbox of their own in the
# predefined Extensions dialog window. You can also specify additional
# extensions in the "Other Extensions" field of this same window.
newPref variable predefExtensions [list tcl html xml tex sty mf c cp h py j el ps eps gif jpeg] macMenu mac::shadowPrefs
# Specify additional application signatures for the "Creator" popup in 
# the Change Creator dialog window.
newPref variable additionalTypes [list {MSIE - Explorer} {OWEB - OmniWeb}] macMenu mac::shadowPrefs
# If this flag is set, you will not be warned when a copy or a move action
# has to overwrite an already existing file.
newPref flag overwriteIfExists {0} macMenu mac::shadowPrefs
# When there are many files to move or copy, there is a risk of memory
# overflow with Apple Events. So the files are processed by chunks. Choose
# here the number of files to process at a time.
newPref variable chunksSize {200} macMenu mac::shadowPrefs
# This is the interval between successive lines in the Info windows. It
# happens, depending on the screen size and resolution, that these windows
# are too high and do not fit in the screen. If this is the case, reduce
# this value (not less than 20 otherwise lines will overlap).
newPref variable lineSkip {25} macMenu mac::shadowPrefs
# This specifies where [pwd] should start from and where [cd] lead to
newPref v defaultHome 0 macMenu mac::shadowPrefs [list "Alpha's folder" "User's home"] index

    

# # # Initialisation of variables # # #
# =====================================
# Predefined extensions
# ---------------------
set mac::predefext $macMenumodeVars(predefExtensions)
set mac::predefext [string trimright $mac::predefext]
foreach e $mac::predefext {
    set mac::ispredef($e) 0
} 
unset -nocomplain e

# # # Initialisation of lists # # #
# =================================
# The global lists of selected files
set mac::fileslist {}
set mac_params(chunksize) $macMenumodeVars(chunksSize)

# Various lists used in the dialog windows
# ----------------------------------------
set mac::alternlist [list "is not" is]
set mac::compvaluelist [list "lower than" "greater than"]
set mac::compdatelist [list "before" "equals" "after"]
set mac::subfoldslist [list "in Directory" "in Hierarchy" "in all Subfolders"]
set mac::inicreatorslist [list { } - {ALFA - Alpha} {MOSS - Netscape} {sfri - Safari}\
  {ttxt - TextEdit} {R*ch - BBEdit} {emal - Mail} {CWIE - CodeWarrior}] 
set mac::creatorslist $mac::inicreatorslist
if {$macMenumodeVars(additionalTypes)!=""} {
    foreach type $macMenumodeVars(additionalTypes) {
	lappend mac::creatorslist $type
    }
    unset -nocomplain type
}
set mac::typeslist [list TEXT - APPL INIT TEXT ttro rsrc cdev]
set mac::caselist [list UPPERCASE lowercase "Capitalize All" "Capitalize first"]
set mac::wherelist [list "at start" "at end"]
set mac::digitlist [list "start at 0" "start at 1"]
set mac::incrlist [list decr incr]
set mac::paddlist [list "no padding" "padd with zeros"]
set mac::eolslist [list mac unix win]
set mac::sortbylist [list " " - "Modification" "Creation" "Size" "Kind" "Labels"]
set mac::sortcodelist [list "" "" asmo ascd ptsz kind labi]


# Global arguments to build the dialog windows
set mac_params(args) ""
set mac_params(addconditions) ""
# Dialog windows title
set mac_params(title) ""
# The y coord in dialog windows
set mac_params(y) 0


# # # Initialisation of arrays # # #
# ==================================
# Array 'mac_params'
# ------------------
# This array stores all the selecting options
#     Flags
#     -----
set mac_params(add&apply)	0
set mac_params(addconditions)	0
set mac_params(addoptions)		0
set mac_params(caseopt)		0
set mac_params(casing)		0
set mac_params(creatoridx)	0
set mac_params(criterion)	0
set mac_params(digitopt)	1
set mac_params(currnum)		1
set mac_params(fromshell) 	0
set mac_params(gothdwrinfo)	0
set mac_params(gotfoldsharinfo) 	0
set mac_params(gotvolsharinfo) 	0
set mac_params(incropt)		1
set mac_params(iscase)		1
set mac_params(isascd)		0
set mac_params(isfcrt)		1
set mac_params(isasmo)		0
set mac_params(issize)		0
set mac_params(isasty)		1
set mac_params(isneg)		0
set mac_params(nest)		1
set mac_params(numbering)	0
set mac_params(overwrite) 	$macMenumodeVars(overwriteIfExists)
set mac_params(paddopt)		1
set mac_params(paddvalue)	2
set mac_params(sameas)		0
set mac_params(isshared)	0
set mac_params(sortbyidx)	0
set mac_params(subfolds)	0
set mac_params(trashnb)		0
set mac_params(truncating)	0
set mac_params(typeidx)		0
set mac_params(whereopt)	1

set mac_params(tclgestaltpresent) [expr ![catch {package require gestalt}]]

#     Variables
#     ---------
set mac_params(addedcreator)	""
set mac_params(addedtype)	""
set mac_params(ascd)		""
set mac_params(asmo)		""
set mac_params(asty)		""
set mac_params(backuporigs) 1
set mac_params(casestr)		"-nocase"
set mac_params(fcrt)		""
set mac_params(fromencoding) "iso8859-1"
set mac_params(fromeol) 	"unix"
set mac_params(otherexts)	""
set mac_params(regex)		".*"
set mac_params(replace)		""
set mac_params(size)		""
set mac_params(toencoding) "macRoman"
set mac_params(toeol) 		"mac"
set mac_params(trgtfold)	""
set mac_params(truncexp)	""
if {$macMenumodeVars(defaultHome)==1} {
    set mac_params(srcfold)	$env(HOME)
} else {
    set mac_params(srcfold)	$HOME
}
set mac_params(pwd) 		$mac_params(srcfold)

set mac::yesno(0) no
set mac::yesno(1) yes
set mac::yesno(2) off
set mac::yesno(3) on

set mac::saveinfo(name) ""
set mac::saveinfo(asty) ""
set mac::saveinfo(fcrt) ""
set mac::saveinfo(aslk) 0
set mac::saveinfo(pspd) 0


# Array 'mac_description'
# -----------------------
set mac_description(appt)	"Allocated memory size"
set mac_description(ascd)	"Creation date"
set mac_description(aslk)	"Locked"
set mac_description(asmo)	"Modification date"
set mac_description(asty)	"Type"
set mac_description(bclk)	"Bus clock speed"
set mac_description(capa)	"Capacity"
set mac_description(cbon)	"CarbonLib version"
set mac_description(Clsc)	"Opens in Classic"
set mac_description(clsc)	"Opens in Classic"
set mac_description(comt)	"Comment"
set mac_description(cpuf)	"CPU family"
set mac_description(cput)	"CPU type"
set mac_description(dfmt)	"Disk format"
set mac_description(dfsz)	"    Data fork"
set mac_description(dscr)	"Description"
set mac_description(dnam)	"Displayed name"
set mac_description(fcrt)	"Creator"
set mac_description(file)	"Launched from"
set mac_description(frsp)	"Free bytes"
set mac_description(fshr)	"File sharing"
set mac_description(gppr)	"Group privileges"
set mac_description(gstp)	"Everyone\'s privileges"
set mac_description(hidx)	"Extension hidden"
set mac_description(hrad)	"Hardware vendor"
set mac_description(hscr)	"Scripting terminology"
set mac_description(igpr)	"Ignore privileges"
set mac_description(iprv)	"Inherited privileges"
set mac_description(isab)	"Scriptable"
set mac_description(isej)	"Ejectable"
set mac_description(isrv)	"Local volume"
set mac_description(istd)	"Boot disk"
set mac_description(kind)	"Kind"
set mac_description(lmem)	"Low memory area size"
set mac_description(lram)	"Logical RAM size"
set mac_description(mfre)	"Largest free block"
set mac_description(mprt)	"Minimum memory size"
set mac_description(name)	"Name"
set mac_description(nmxt)	"Name extension"
set mac_description(opfw)	"Open Firmware present"
set mac_description(ownr)	"Owner\'s privileges"
set mac_description(path)	"Parent folder"
set mac_description(pclk)	"Processor clock speed"
set mac_description(pgsz)	"Logical page size"
set mac_description(phys)	"Physical size"
set mac_description(pnam)	"Name"
set mac_description(pspd)	"Stationery pad"
set mac_description(ptsz)	"Logical size"
set mac_description(pURL)	"URL"
set mac_description(pusd)	"Partition space Used"
set mac_description(revt)	"Remote events"
set mac_description(rfsz)	"    Resource fork"
set mac_description(rom)	"ROM size"
set mac_description(rram)	"RAM size"
set mac_description(sexp)	"Is share point"
set mac_description(sgrp)	"Group"
set mac_description(shar)	"Volume shared"
set mac_description(smou)	"Mounted remotely"
set mac_description(sown)	"Owner"
set mac_description(spro)	"Protected from move"
set mac_description(sprt)	"Suggested memory size"
set mac_description(srad)	"Software vendor"
set mac_description(sysa)	"System architecture"
set mac_description(sysv)	"System version"
set mac_description(uram)	"User RAM size"
set mac_description(ver2)	"Version info"
set mac_description(vers)	"Version"
set mac_description(vm)		"Virtual memory"

proc macMenuTcl {} {}

# # # Menu declarations # # #
# ===========================

menu::buildProc macMenu menu::buildmacMenu
menu::buildProc GetInfo menu::buildGetInfo


# # # Building the menu # # #
# ===========================

proc menu::buildmacMenu {} {
    global macMenu 
    set ma ""
    lappend ma "copyFiles…"
    lappend ma "moveFiles…"
    lappend ma "renameFiles…"
    lappend ma "duplicateFiles…"
    lappend ma "trashFiles…"
    lappend ma "<E<SaliasFiles…"
    lappend ma "<S<IremoveAliasFiles…"
    lappend ma "<E<SlockFiles…"
    lappend ma "<S<IunlockFiles…"
    lappend ma "<ElistFiles…"
	lappend ma "deleteRezForks…"
	lappend ma "(-"
	lappend ma "changeEols…"
	lappend ma "changeEncoding…"
    lappend ma "changeType…"
    lappend ma "changeCreator…"
    lappend ma "(-"
    lappend ma "/Y<O<BmacShell"
    lappend ma "(-"
    lappend ma [list Menu -n GetInfo {}]
    lappend ma "(-"
    lappend ma "emptyTrash"
    lappend ma "(-"
    lappend ma "eject…"
    lappend ma "sleep"
    lappend ma "restart"
    lappend ma "shutDown"
    
    return [list build $ma mac::MenuProc {GetInfo} $macMenu]
}

proc menu::buildGetInfo {} {
    set ma ""
    lappend ma "file…"
    lappend ma "folder…"
    lappend ma "volume…"
    lappend ma "application…"
    lappend ma "process…"
    lappend ma "hardware"
    lappend ma "(-"
    lappend ma "macMenuPreferences…"
    lappend ma "macMenuBindings"
    lappend ma "macMenuTutorial"

    return [list build $ma mac::infoMenuProc]
}


# # # Menu items procs # # #
# ==========================

proc mac::MenuProc {menu item} {
  global mac_params
    set item [string trimright $item "…"]
    set mac_params(fromshell) 0
	switch $item {
		"duplicateFiles" {mac::processFiles select Duplicate sl}
		"copyFiles" {mac::processFiles move Copy mv}
		"moveFiles" {mac::processFiles move Move mv}
		"renameFiles" {mac::processFiles rename Rename rn}
		"trashFiles" {mac::processFiles select Trash sl}
		"aliasFiles" {mac::processFiles move Alias mv}
		"removeAliasFiles" {mac::processFiles removeAlias RemoveAlias ua}
		"lockFiles" {mac::processFiles select Lock sl}
		"unlockFiles" {mac::processFiles select Unlock sl}
		"changeCreator" {mac::processFiles changeCreator ChangeCreator ch}
		"changeType" {mac::processFiles changeType ChangeType ch}
		"changeEncoding" {mac::processFiles changeEncoding ChangeEncoding ch}
		"changeEols" {mac::processFiles changeEols ChangeEols ch}
		"listFiles" {mac::processFiles list List ls}
		"deleteRezForks" {mac::processFiles select DeleteRezForks sl}
		default {eval mac::$item}
	}
}

proc mac::infoMenuProc {menu item} {
    set item [string trimright $item ".…"]
    if {$item=="macMenuPreferences"} {
	prefs::dialogs::packagePrefs "macMenu"
    } else {
	eval mac::${item}Info
    }
}

proc mac::processFiles {dlog title code} {
	if ![mac::${dlog}Dialog $title] return
	mac::cleanDialog $code 
	eval mac::${title}Proc
}


# # # Inserting the menu # # #
# ============================

menu::buildSome macMenu


# # # Key bindings # # #
# ======================
# 'ctrl-z'  'a'	<a>liases dialog
# 'ctrl-z'  'b'	show <b>indings info 
# 'ctrl-z'  'c'	<c>opy files dialog
# 'ctrl-z'  'd'	<d>uplicate files dialog
# 'ctrl-z'  'e'	<e>mpty the trash
# 'ctrl-z'  'f'	delete resource <f>ork
# 'ctrl-z'  'j'	e<j>ect a disk
# 'ctrl-z'  'k'	loc<k> files dialog
# 'ctrl-z'  'l'	<l>ist files dialog
# 'ctrl-z'  'm'	<m>ove files dialog
# 'ctrl-z'  'r'	<r>ename files dialog
# 'ctrl-z'  't'	send files to the <t>rash
# 'ctrl-z'  'u'	<u>nlock files dialog


Bind 'z' <z> 	prefixChar 

Bind 'a' <Z>	{mac::MenuProc macMenu "aliasFiles"}
Bind 'b' <Z>	mac::macMenuBindingsInfo
Bind 'c' <Z>	{mac::MenuProc macMenu "copyFiles"}
Bind 'd' <Z>	{mac::MenuProc macMenu "duplicateFiles"}
Bind 'e' <Z>	mac::emptyTrash
Bind 'f' <Z>	{mac::MenuProc macMenu "deleteRezForks"}
Bind 'j' <Z>	mac::eject
Bind 'k' <Z>	{mac::MenuProc macMenu "lockFiles"}
Bind 'l' <Z>	{mac::MenuProc macMenu "listFiles"}
Bind 'm' <Z>	{mac::MenuProc macMenu "moveFiles"}
Bind 'r' <Z>	{mac::MenuProc macMenu "renameFiles"}
Bind 't' <Z>	{mac::MenuProc macMenu "trashFiles"}
Bind 'u' <Z>	{mac::MenuProc macMenu "unlockFiles"}

