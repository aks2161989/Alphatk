## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexMenu.tcl"
 #                                   created: 11/10/1992 {10:42:08 AM}
 #                               last update: 2006-02-04 23:39:04
 # Description:
 #
 # Procedures for building the TeX menu, and executing menu items.
 #
 # Note that most menu key-bindings can now be set by the user, and the
 # default bindings are not included in the 'menu::items' arrays below, but
 # instead defined in "latexKeys.tcl" which should be called before the menu
 # is built.  Dynamic menu items should be defined here, though.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

# Make sure that the default key-bindings have been defined.
latexKeys.tcl

proc latexMenu.tcl {} {}

namespace eval TeX {
    # Don't add the "texMenuIcon" preference to the standard dialog.
    variable invisibleModeVars
    set invisibleModeVars(texMenuIcon) 1
    # Define the icons we have available for this menu.
    variable texMenuIcons
    array set texMenuIcons [list \
      "CMacTeX"         "¥272" \
      "DirectTeX"       "¥299" \
      "LaTeX"           "¥270" \
      "OzTeX"           "¥266" \
      "Textures"        "¥267" \
      ]
}

# The icon for the TeX menu.
newPref var texMenuIcon "LaTeX" TeX {TeX::changeMenuIcon} \
  "TeX::texMenuIcons" array

# Shouldn't be necessary, but we ensure that this never throws an error.
if {[info exists TeX::texMenuIcons($TeXmodeVars(texMenuIcon))]} {
    set texMenu $TeX::texMenuIcons($TeXmodeVars(texMenuIcon))
} else {
    set texMenu "TeX"
}

# Preliminaries - Define the categories of menus.  We use 'ensureset' here in
# case the user has defined additional menus somewhere, like in a prefs.tcl
# file, or if other packages have defined menus to be inserted.

ensureset TeX::Menus(Top) [list \
  "Process" "Goto" "LaTeX Utilities" "LaTeX Menu" "LaTeX Help" \
  ]

ensureset TeX::Menus(Bottom) [list \
  "Documents" "Page Layout" "Sectioning" \
  ]

ensureset TeX::Menus(TextSubMenus) [list \
  "Text Style" "Text Size" "Text Commands" "International" \
  "Environments" "Boxes" "Miscellaneous" \
  ]

ensureset TeX::Menus(MathSubMenus) [list \
  "Math Modes" "Math Style" "Math Environments" "Theorem" "Formulas" "Greek"  \
  "Binary Operators" "Relations" "Arrows" "Dots" "Symbols" \
  "Functions" "Large Operators" "Delimiters" "Math Accents" \
  "Grouping" "Spacing" \
  ]

# These are the menus that users cannot alter.
set TeX::FixedMenus [list "Process" "Documents" "Math Modes"]

# Define generic menu building etc array items.

foreach menuType [array names TeX::Menus] {
    foreach menuName [set TeX::Menus($menuType)] {
	set menu::otherflags($menuName) {-M TeX -m}
	set menu::proc($menuName)       {TeX::macroMenuProc}
	if {[lsearch [set TeX::FixedMenus] $menuName] == "-1"} {
	    lappend TeX::ChangeableMenus $menuName
	}
	# We have to register build procs in case the user has included
	# menu::insert or menu::replaceWith statements in prefs files.
	menu::buildProc $menuName \
	  "eval \[lindex \[TeX::buildSubmenus \[list \"$menuName\"\]\] 0\]"
    }
}
unset menuType menuName TeX::FixedMenus
# These are the menus which allow users to change bindings, add items easily
# using "LaTeX Menu" items.
set TeX::ChangeableMenus [lsort -unique -dictionary [set TeX::ChangeableMenus]]

# Define menu-specific menu building etc. array items

menu::buildProc texMenu         {TeX::buildLaTeXMenu}       {TeX::postBuildTeX}

menu::buildProc Process         {TeX::buildProcessMenu}
menu::buildProc ProcessOpen     {TeX::buildProcessOpenMenu}
menu::buildProc Documents       {TeX::buildDocumentsMenu}   {TeX::postBuildDocuments}
menu::buildProc Packages        {TeX::buildPackagesMenu}

menu::buildProc TeXProgram      {TeX::buildProgramMenu}     {TeX::postBuildProgram}
menu::buildProc TeXFormat       {TeX::buildFormatMenu}      {TeX::postBuildFormat}
menu::buildProc MakeIndexStyles {TeX::buildMakeIndexMenu }  {TeX::postBuildMakeIndex}

menu::buildProc "Math Submenus" {TeX::buildMathMenus}
menu::buildProc "Text Submenus" {TeX::buildTextMenus}

array set menu::proc {
    "Documents"         {TeX::menuProc}
    "Process"           {TeX::menuProc}
    "Goto"              {TeX::menuProc}
    "LaTeX Utilities"   {TeX::menuProc}
    "LaTeX Menu"        {TeX::menuProc}
    "LaTeX Help"        {TeX::menuProc}
}

# ×××× -------- ×××× #

# ×××× Building Menus ×××× #

# Build the TeX menu.

proc TeX::buildLaTeXMenu {} {

    global TeXmodeVars TeX::Menus texMenu
    
    TeX::setMathModesItems
    TeX::setMathStyleItems
    TeX::setTextSizeItems
    TeX::setMathEnvsItems

    set menuList [concat \
      [TeX::buildSubmenus [set TeX::Menus(Top)]]    (-) \
      [TeX::buildSubmenus [set TeX::Menus(Bottom)]] (-) ]
    set subMenus [list "Process" "Documents"]

    if {$TeXmodeVars(compressTextMenus)} {
	set menuList [concat $menuList \
	  [TeX::buildSubmenus [list "Text Submenus"]] "(-)" ]
	lappend subMenus "Text Submenus"
    } else {
	set menuList [concat $menuList \
	  [TeX::buildSubmenus [set TeX::Menus(TextSubMenus)]] (-) ]
    }
    if {$TeXmodeVars(compressMathMenus)} {
	set menuList [concat $menuList \
	  [TeX::buildSubmenus [list "Math Submenus"]]]
	lappend subMenus "Math Submenus"
    } else {
	set menuList [concat $menuList \
	  [TeX::buildSubmenus [set TeX::Menus(MathSubMenus)]]]
    }
    return [list build $menuList {TeX::macroMenuProc -M TeX -m} $subMenus $texMenu]
}

proc TeX::buildSubmenus {menuNames} {

    global menu::items menu::proc menu::additions \
      TeX::Menus TeX::MenuKeysUser TeX::MenuKeysDefault \
      TeX::MenuAdditions TeX::MacroInsertions
    
    set macroMenus [concat "Sectioning" \
      [set TeX::Menus(TextSubMenus)] [set TeX::Menus(TextSubMenus)]]

    foreach menuName $menuNames {
	if {[info exists menu::items($menuName)]} {
	    set menuList [set menu::items($menuName)]
	} else {
	    set menuList [list]
	}
	if {[info exists menu::proc($menuName)]} {
	    set menuProc [set menu::proc($menuName)]
	} elseif {[lsearch $macroMenus $menuName] != "-1"} {
	    set menuProc "TeX::macroMenuProc"
	} else {
	    set menuProc "TeX::menuProc"
	}
	# Now we're going to emulate 'menu::buildOne' to make sure that menu
	# additions are properly added.  This involves a little slight of
	# hand, to make sure that anything added by the user or other
	# packages are taken care of ...  This is necessary because the main
	# menu might be rebuilt via various methods.  The first time that the
	# main TeX menu is built, menu::additions might be empty and the
	# items will be added afterwords.  Rebuilding the menu later (via
	# this proc) would then ignore the additions without this routine.
	set menuAdditions [list]
	if {[info exists TeX::MenuAdditions($menuName)]} {
	    set divider [list item end "(-)"]
	    if {[lsearch [set TeX::MenuAdditions($menuName)] $divider] == "-1"} {
		set TeX::MenuAdditions($menuName) [concat [list $divider] \
		  [set TeX::MenuAdditions($menuName)]]
	    } 
	    foreach item [set TeX::MenuAdditions($menuName)] {
		lappend menuAdditions $item
		lappend menu::additions($menuName) $item
		set itemName [lindex $item 2]
		if {$itemName != "(-)"} {
		    ensureset TeX::MacroInsertions($itemName) "\\${itemName}¥"
		} 
	    }
	} 
	if {[info exists menu::additions($menuName)]} {
	    foreach item [set menu::additions($menuName)] {
		lappend menuAdditions $item
	    }
	    set menu::additions($menuName) \
	      [lunique [set menu::additions($menuName)]]
	} 
	if {[llength $menuAdditions]} {
	    set menuAdditions [lunique $menuAdditions]
	    set menu::additions($menuName) $menuAdditions
	    foreach item $menuAdditions {
		set type  [lindex $item 0]
		set where [lindex $item 1]
		set what  [lrange $item 2 end]
		switch -- $type {
		    "submenu" {
			lappend msubs [lindex $what 0]
			# 'what' may be just a menu name, or also contain
			# various additional flags (-p proc etc)
			set what [list [concat Menu -n $what [list {}]]]
		    }
		}
		switch -- [lindex $where 0] {
		    "replace" {
			set old [lindex $where 1]
			if {[set idx [eval llindex menuList $old]] != -1} {
			    set menuList [eval [list lreplace $menuList \
			      $idx [expr {$idx -1 + [llength $old]}]] $what]
			} else {
			    alertnote "Bad menu::replacement registered '$old'"
			}
			
		    }
		    "end" {
			eval lappend menuList $what
		    }
		    default {
			if {![is::UnsignedInteger $where]} {
			    if {[set pos [lsearch -exact $menuList $where]] != -1} {
				set where $pos
			    } else {
				alertnote "The string '$where' has not be found\
				  in menu '$menuName'. '$what' will be put at\
				  the end of this menu"
				set where [llength $menuList]
			    }
			}
			set menuList [eval linsert [list $menuList] $where $what]
		    }
		}
	    }
	}
	# Now add any menu bindings, either user defined or default.
	set idx 0
	foreach item $menuList {
	    regexp {^([!<].)*(/.)?(.+)} $item item "" "" itemLabel
	    if {[info exists TeX::MenuKeysUser($itemLabel)]} {
		set newItem "[set TeX::MenuKeysUser($itemLabel)]${item}"
		set menuList [lreplace $menuList $idx $idx $newItem]
	    } elseif {[info exists TeX::MenuKeysDefault($itemLabel)]} {
		set newItem "[set TeX::MenuKeysDefault($itemLabel)]${item}"
		set menuList [lreplace $menuList $idx $idx $newItem]
	    }
	    incr idx
	}
	lappend menus [list Menu -n $menuName -m -p $menuProc -M TeX $menuList]
    }
    return $menus
}

proc TeX::buildMathMenus {} {

    global TeX::Menus

    set menuList [TeX::buildSubmenus [set TeX::Menus(MathSubMenus)]]
    set subMenus [list]
    return [list build $menuList {dummy -M TeX -m} $subMenus {Math Submenus}]
}

proc TeX::buildTextMenus {} {

    global TeX::Menus

    set menuList [TeX::buildSubmenus [set TeX::Menus(TextSubMenus)]]
    set subMenus [list]
    return [list build $menuList {dummy -M TeX -m} $subMenus {Text Submenus}]
}

proc TeX::postBuildTeX {args} {
    if {![package::active texMenu]} {return}

    global TeX::Menus TeXmodeVars mode texMenu \
      TeX::MenuKeysUser TeX::MacroInsertions

    # "LaTeX Menu" items.

    set mN "LaTeX Menu"
    
    set enable1 [expr {[llength [array names TeX::MenuKeysUser]]    ? 1 : 0}]
    set enable2 [expr {[llength [array names TeX::MacroInsertions]] ? 1 : 0}]
    
    markMenuItem   -m $mN {Compress Text Menus}   $TeXmodeVars(compressTextMenus) Ã
    markMenuItem   -m $mN {Compress Math Menus}   $TeXmodeVars(compressMathMenus) Ã
    markMenuItem   -m $mN {AMS-LaTeX}             $TeXmodeVars(useAMSLaTeX) Ã
    markMenuItem   -m $mN {Dollars For Math}      $TeXmodeVars(useDollarSigns) Ã

    enableMenuItem -m $mN {Restore DefaultsÉ}     $enable1
    enableMenuItem -m $mN {Edit Template ItemÉ}   $enable2
    enableMenuItem -m $mN {Remove Template ItemÉ} $enable2

    # Now dim items as appropriate to the current mode.
    if {![package::active texMenu]} {return}

    # List submenus or submenu items that should be enabled/disabled.

    set menuItems1 [list "Goto" "Page Layout" "Sectioning"]
    set menuItems2 [list "LaTeX Utilities" "Text Submenus" "Math Submenus"]
    set menuItems2 [concat $menuItems2 \
      [set TeX::Menus(TextSubMenus)] [set TeX::Menus(MathSubMenus)]]
    set documentDimItems1 [list "Insert Document" \
      "article" "report" "book" "letter" "slides" "otherÉ" \
      "optionsÉ" "usepackage" "Packages" \
      "filecontentsÉ" "filecontents All" \
      "Build Packages Submenu" \
      ]
    if {$TeXmodeVars(buildPkgsSubmenu)} {
	lappend documentDimItems1 \
	  "View Search PathsÉ" "Add Search PathsÉ" "Remove Search PathsÉ" \
	  "Rebuild Documents Submenu"
	set documentDimItems2 [list "View Search PathsÉ" "Remove Search PathsÉ"]
    } else {
	set documentDimItems2 [list]
    }

    if {$mode == "TeX"} {
	set enable1 "1" ; set enable2 "1" ; set enable3 "1"
    } elseif {$mode == "Bib" } {
	set enable1 "0" ; set enable2 "1" ; set enable3 "0"
    } else {
	set enable1 "0" ; set enable2 "0" ; set enable3 "0"
    }
    if {$enable1 && $TeXmodeVars(buildPkgsSubmenu)} {
	set enable4 [expr {[llength $TeXmodeVars(TeXSearchPath)] ? 1 : 0}]
    } else {
	set enable4 0
    } 
    # Enable/Disable TeX menu submenus
    foreach i $menuItems1 {
	catch {enableMenuItem -m $texMenu $i $enable1}
    }
    foreach i $menuItems2 {
	catch {enableMenuItem -m $texMenu $i $enable2}
    }
    # Enable/Disable most "Document" items
    foreach i $documentDimItems1 {
	catch {enableMenuItem -m Documents $i $enable3}
    }
    # Enable/Disable more "Document" items
    foreach i $documentDimItems2 {
	catch {enableMenuItem -m Documents $i $enable4}
    }
    if {[lcontains {global::features} texMenu]} {
	TeX::registerOWH "register"
    } else {
	TeX::registerOWH "deregister"
    }
}

set TeX::OWHRegistered "-1"

proc TeX::registerOWH {{which "register"}} {

    global TeXmodeVars TeX::Menus texMenu TeX::OWHRegistered

    # We avoid going through all of this if we've done it before.
    if {$which == "register" && [set TeX::OWHRegistered] == "1"} {
	return
    } elseif {$which == "deregister" && [set TeX::OWHRegistered] == "0"} {
	return
    }
    
    set menuItems [list "Goto" "LaTeX Utilities" \
      "Page Layout" "Sectioning" "Text Submenus" "Math Submenus"]
    set menuItems [concat $menuItems \
      [set TeX::Menus(TextSubMenus)] [set TeX::Menus(MathSubMenus)]]

    # Dim all "Documents" items except "New Document".
      set documentDimItems [list "Insert Document" \
	"article" "report" "book" "letter" "slides" "otherÉ" \
	"optionsÉ" "usepackage" "Packages" \
	"filecontentsÉ" "filecontents All" \
	"Build Packages Submenu" \
	"View Search PathsÉ" "Add Search PathsÉ" "Remove Search PathsÉ" \
	"Rebuild Documents Submenu" \
	]
    foreach i $documentDimItems {
	hook::$which requireOpenWindowsHook [list Documents $i] 1
    }
    # Dim TeX menu submenus
    foreach i $menuItems {
	hook::$which requireOpenWindowsHook [list $texMenu $i] 1
    }
    if {$which == "register"} {
	set TeX::OWHRegistered 1
    } elseif {$which == "deregister"} {
	set TeX::OWHRegistered 0
    } 
}

proc TeX::rebuildMenu {args} {    
    set quietly 0
    if {![llength $args]} {
	set args [list "texMenu"]
    } else {
	switch -regexp -- [lindex $args 0] {
	    {activateHook} - 
	    {filesetUpdate} - 
	    {winChangedName} {
		set quietly 1
		set args [list "Process"]
	    }
	    {DollarSigns}   {set args [list "Math Modes"]}
	    {AMSLaTeX}      {set args [list "texMenu"]}
	    {PkgsSubmenu}   {set args [list "Documents"]}
	    {ResetSig}      {set args [list "Process" "Documents"]}
	    {TeX.*Format}   {set args [list "Process"]}
	    {TeXInBack}     {set args [list "Process"]}
	    {TeX.*Program}  {set args [list "Process"]}
	    {TeX.+Style.*}  {set args [list "MakeIndexStyles"]}
	    {^submenusFor}  {set args [list "texMenu"]}
	    {^$}            {set args [list "texMenu"]}
	}
    }
    if {[lcontains args "Math Modes"]} {
	TeX::setMathModesItems
    }
    eval menu::buildSome $args
    if {![lcontains args texMenu]} {
	TeX::postBuildTeX
    }
    if {!$quietly && [package::active texMenu]} {
	if {[llength $args] == "1"} {
	    status::msg "The [join $args] menu has been rebuilt."
	} else {
	    status::msg "The [join $args] menus have been rebuilt."
	}
    }
    return
}

proc TeX::menuProc {menuName itemName} {

    global mode texMenu TeXmodeVars HOME TeXSearchPath
    
    switch -- $menuName {
	"Documents" - "Insert Document" {
	    switch -- $itemName {
		"New Document"     {TeX::newLaTeXDocument}
		"article"          {TeX::articleDocumentclass}
		"report"           {TeX::reportDocumentclass}
		"book"             {TeX::bookDocumentclass}
		"letter"           {TeX::letterDocumentclass}
		"slides"           {TeX::slidesDocumentclass}
		"other"            {TeX::otherDocumentclass}
		"usepackage"       {TeX::insertPackage ""}
		"filecontents All" {TeX::filecontentsAll}
		"Build Packages Submenu" {
		    set helpText [help::prefString "buildPkgsSubmenu" "TeX"]
		    regsub -all {\|\|} "${helpText}." {.  } helpText
		    set setting [set TeXmodeVars(buildPkgsSubmenu)]
		    set title   "Build Packages SubmenuÉ"
		    set d 1
		    set d$d [list dialog::make -title $title]
		    
		    incr d
		    lappend d$d "'Build Packages Submenu' Setting"
		    lappend d$d [list text ${helpText}\r\r]
		    lappend d$d [list flag "Build Packages Submenu" $setting]
		    lappend dP  [set d$d]
		    set result  [eval $d1 $dP]
		    set TeXmodeVars(buildPkgsSubmenu) [lindex $result 0]
		    prefs::modified TeXmodeVars(buildPkgsSubmenu)
		    TeX::rebuildMenu "Documents"
		}
		"View Search Paths" {
		    mode::viewSearchPath ; return
		}
		"Add Search Paths" {
		    mode::appendSearchPaths
		    if {[info exists TeXSearchPath]} {
			set TeXmodeVars(TeXSearchPath) $TeXSearchPath
		    } 
		    TeX::resetTeXInputs
		}
		"Remove Search Paths" {
		    mode::removeSearchPaths
		    if {[info exists TeXSearchPath]} {
			set TeXmodeVars(TeXSearchPath) $TeXSearchPath
		    } 
		    TeX::resetTeXInputs
		}
		"Rebuild Documents Submenu" {
		    global TeX::PackagesSubmenuItems
		    set TeX::PackagesSubmenuItems ""
		    status::msg "Rebuilding the Documents submenuÉ"
		    TeX::rebuildMenu Documents
		}
		default {TeX::[join $itemName {}]}
	    }
	}
	"Goto" {
	    switch -- $itemName {
		"LaTeX application"             {TeX::texApp TeX}
		"BibTeX application"            {TeX::texApp BibTeX}
		"MakeIndex application"         {TeX::texApp MakeIndex}
		"Next Template Stop"           	{ring::+}
		"Prev Template Stop"           	{ring::-}
		"Next Sentence"                 {nextSentence}
		"Prev Sentence"                 {prevSentence}
		"Next Paragraph"                {paragraph::next}
		"Prev Paragraph"                {paragraph::prev}
		"Next Command"                 	{TeX::next Command}
		"Prev Command"                 	{TeX::prev Command}
		"Next Command Select"          	{TeX::next Command 1}
		"Prev Command Select"          	{TeX::prev Command 1}
		"Next Command Select With Args"	{TeX::next CommandWithArgs 1 command}
		"Prev Command Select With Args"	{TeX::prev CommandWithArgs 1 command}
		"Next Environment"             	{TeX::nextEnvironment}
		"Prev Environment"             	{TeX::prevEnvironment}
		"Next Environment Select"      	{TeX::nextEnvironmentSelect}
		"Prev Environment Select"      	{TeX::prevEnvironmentSelect}
		"Next Section"                 	{TeX::next Section}
		"Prev Section"                 	{TeX::prev Section}
		"Next Section Select"          	{TeX::nextSectionSelect}
		"Prev Section Select"          	{TeX::prevSectionSelect}
		"Next Subsection"              	{TeX::next Subsection}
		"Prev Subsection"              	{TeX::prev Subsection}
		"Next Subsection Select"       	{TeX::nextSubsectionSelect}
		"Prev Subsection Select"       	{TeX::prevSubsectionSelect}
		default                         {TeX::[join $itemName {}]}
	    }
	}
	"LaTeX Help" {
	    switch -- $itemName {
		"LaTeX Home Page" {
		    urlView $TeXmodeVars(LaTeXHomePage)
		}
		"WWW LaTeX Help" {
		    TeX::wwwCommandHelp
		}
		"LaTeX Mode Intro - text" {
		    help::openDirect [help::pathToHelp [file join "LaTeX Help" "LaTeX Help"]]
		}
		"Users Guide - pdf" {
		    help::openDirect [help::pathToHelp [file join "LaTeX Help" latex_guide.pdf]]
		}
		"Users Guide - tex" {
		    edit -r -c [help::pathToHelp [file join "LaTeX Help" latex_guide.tex]]
		    if {![llength [getNamedMarks]]} {TeX::MarkFile}
		}
		"Typesetting LaTeX Files - text" {
		    help::openDirect [help::pathToHelp [file join \
		      "LaTeX Help" "Typesetting LaTeX Files"]]
		}
		"LaTeX Menus - tex" {
		    edit -r -c [help::pathToHelp [file join "LaTeX Help" latex_menus.tex]]
		    if {![llength [getNamedMarks]]} {TeX::MarkFile}
		}
		"LaTeX Key Bindings - tex" {
		    edit -r -c [help::pathToHelp [file join "LaTeX Help" latex_bindings.tex]]
		    if {![llength [getNamedMarks]]} {TeX::MarkFile}
		}
		"Introduction to LaTeX - tex" {
		    help::openExample "LaTeX-Example.tex"
		    if {![llength [getNamedMarks]]} {TeX::MarkFile}
		}
		"teTeX Help - text" {
		    help::openDirect \
		      [help::pathToHelp [file join "LaTeX Help" "teTeX Help"]]
		}
		"Completions Tutorial" {
		    mode::completionsTutorial "TeX"
		}
		default {TeX::[join $itemName {}]}
	    }
	}
	"LaTeX Menu" {
	    switch -- $itemName {
		"Compress Text Menus"   {
		    set newValue [expr {1 - [set TeXmodeVars(compressTextMenus)]}]
		    set TeXmodeVars(compressTextMenus) $newValue
		    prefs::modified TeXmodeVars(compressTextMenus)
		    TeX::rebuildMenu
		}
		"Compress Math Menus"  {
		    set newValue [expr {1 - [set TeXmodeVars(compressMathMenus)]}]
		    set TeXmodeVars(compressMathMenus) $newValue
		    prefs::modified TeXmodeVars(compressMathMenus)
		    TeX::rebuildMenu
		}
		"AMS-LaTeX"            {
		    set newValue [expr {1 - [set TeXmodeVars(useAMSLaTeX)]}]
		    set TeXmodeVars(useAMSLaTeX) $newValue
		    prefs::modified TeXmodeVars(useAMSLaTeX)
		    TeX::rebuildMenu useAMSLaTeX
		}
		"Dollars For Math" {
		    set newValue [expr {1 - [set TeXmodeVars(useDollarSigns)]}]
		    set TeXmodeVars(useDollarSigns) $newValue
		    prefs::modified TeXmodeVars(useDollarSigns)
		    TeX::setMathModesItems
		    TeX::rebuildMenu "LaTeX Menu" "Math Modes"
		}
		"Assign Menu Bindings"    {TeX::assignMenuBindings}
		"Restore Defaults"        {TeX::restoreDefaultBindings}
		"Add Menu Template Item"  {TeX::addMenuItem}
		"Edit Template Item"      {TeX::editMenuItem}
		"Remove Template Item"    {TeX::removeMenuItem}
		"Change Menu Icon"        {TeX::changeMenuIcon}
		default                   {TeX::[join $itemName {}]}
	    }
	}
	"LaTeX Utilities" {
	    switch -- $itemName {
		"Delete Template Stops"	 {ring::clear}
		"Delete Comments"      	 {TeX::deleteComments}
		"Convert Quotes"       	 {TeX::convertQuotes}
		"Convert Dollar Signs" 	 {TeX::convertDollarSigns}
		default                  {TeX::[join $itemName {}]}
	    }
	}
	"MakeIndex Styles" {
	    # These are always auto-saved if this menu is used.
	    foreach item [list index glossary] {
		prefs::modified TeXmodeVars(TeX${item}Style)
		prefs::modified TeXmodeVars(TeX${item}Styles)
	    }
	    set pat {(Add|Remove) (index|glossary)}
	    if {![regexp $pat $itemName allofit which type]} {
		switch -- $itemName {
		    "No index style"  {
			set TeXmodeVars(TeXindexStyle) ""
			TeX::postBuildMakeIndex
			status::msg "The index style is now empty."
		    }
		    "No glossary style" {
			set TeXmodeVars(TeXglossaryStyle) ""
			TeX::postBuildMakeIndex
			status::msg "The glossary style is now empty."
		    }
		    default {
			# Determine the type that we're dealing with.
			set pat {\{([a-zA-Z]+)\} (.+)}
			if {![regexp $pat $itemName allofit type itemName]} {
			    error "Cancelled -- unknown item type: $itemName"
			}
			set stylePref  TeXmodeVars(TeX${type}Style)
			set stylesPref TeXmodeVars(TeX${type}Styles)
			# Make sure that we have a source file whose
			# root-tail ends with '$itemName'.  If we find it, we
			# style the index/glossary pref to this item, and
			# then we'll rebuild the menu.
			set found 0
			foreach fileName [set $stylesPref] {
			    if {$found} {break}
			    set fileRoot [file root $fileName]
			    set fileTail [file tail $fileRoot]
			    if {$fileTail eq $itemName} {
				set $stylePref $fileRoot
				set found 1
			    }
			}
			if {!$found} {
			    alertnote "Weird -- Couldn't find '$itemName'\
			      in the list of index or glossary styles."
			} 
		    }
		}
	    } else {
		set stylePref  TeXmodeVars(TeX${type}Style)
		set stylesPref TeXmodeVars(TeX${type}Styles)
		switch -- $which {
		    "Add" {
			if {[catch {getfile "Add $type style É"} fileName]} {
			    error "cancel"
			} 
			lunion $stylesPref [file root $fileName]
			set $stylePref [file root $fileName]
		    }
		    "Remove" {
			set styles [set $stylesPref]
			set p      "Remove which $type styles:"
			if {[catch {listpick -p $p -l $styles} removeList]} {
			    error "cancel"
			} 
			set $stylesPref [lremove [set $stylesPref] $removeList]
			if {![lcontains $stylesPref [set $stylePref]]} {
			    set $stylePref ""
			} 
		    }
		}
	    }
	    TeX::rebuildMenu "MakeIndexStyles"
	}
	"Open Auxiliary File" - "Process" {
	    switch -regexp -- $itemName {
		"Typeset Selection"       {TeX::typesetSelection}
		"Typeset Clipboard"       {TeX::typesetClipboard}
		"Back\ Typeset.*"         {TeX::typeset 1}
		"Typeset.*"               {TeX::typeset}
		"Synchronize.*"           {TeX::syncronizeDoc}
		"View.*\.dvi$"            {TeX::doTypesetCommand view DVI}
		"Print.*\.dvi$"           {TeX::doTypesetCommand print DVI}
		"View.*\.ps$"             {TeX::doTypesetCommand view PS}
		"Distill.*\.ps$"          {TeX::doTypesetCommand distill PS}
		"View.*\.pdf$"            {TeX::doTypesetCommand view PDF}
		"Print.*\.ps$"            {TeX::doTypesetCommand print PS}
		"bibtex.*"                {TeX::doTypesetCommand bibtex AUX}
		"makeindex.*"             {TeX::doTypesetCommand makeindex IDX}
		"makeglossary.*"          {TeX::doTypesetCommand makeindex GLO}
		".*\.aux $"               {TeX::doTypesetCommand open AUX}
		".*\.aux$"                {TeX::doTypesetCommand open AUX 1}
		".*\.bbl$"                {TeX::doTypesetCommand open BBL}
		".*\.blg$"                {TeX::doTypesetCommand open BLG}
		".*\.glo$"                {TeX::doTypesetCommand open GLO}
		".*\.idx$"                {TeX::doTypesetCommand open IDX}
		".*\.ilg$"                {TeX::doTypesetCommand open ILG}
		".*\.ind$"                {TeX::doTypesetCommand open IND}
		".*\.ind$"                {TeX::doTypesetCommand open IND}
		".*\.lof$"                {TeX::doTypesetCommand open LOF}
		".*\.log$"                {TeX::doTypesetCommand open LOG}
		".*\.lot$"                {TeX::doTypesetCommand open LOT}
		".*\.ps$"                 {TeX::doTypesetCommand open PS}
		".*\.toc$"                {TeX::doTypesetCommand open TOC}
		"Any TeX File"            {
		    edit -r -w [getfile "" [win::Current]]
		}
		"Remove Auxiliary Files"  {TeX::removeAuxiliaryFiles}
		"Rebuild Process Menu"    {TeX::rebuildMenu "Process"}
		default                   {
		    global TeX::process
		    foreach p [array names TeX::process] {
			if {[regexp -- "^$p " $itemName]} {
			    set cmd [lindex $TeX::process($p) 1]
			    eval $cmd
			    return
			}
		    }
		    $itemName
		}
	    }
	}
	"TeX Format" {
	    switch -- $itemName {
		"Edit TeX Formats" {
		    set formats $TeXmodeVars(availableTeXFormats)
		    set helpText [help::prefString "availableTeXFormats" "TeX"]
		    # Divide the list into two if possible.
		    if {[set idx [lsearch $formats "(-)"]] != "-1"} {
			set firstList [lrange $formats 0 [expr {$idx - 1}]]
			set theRest   [lrange $formats [expr {$idx + 1}] end]
		    } else {
			set firstList [list "LaTeX" "TeX"]
			set theRest   $formats
		    }
		    # Create and present the dialog.
		    set t1    "Standard Formats:"
		    set t2    "Variant Formats:"
		    set title "Available TeX FormatsÉ"
		    set d 1
		    set d$d [list dialog::make -title $title]

		    incr d
		    lappend d$d "Available TeX Formats"
		    lappend d$d [list text ${helpText}\r\r]
		    lappend d$d [list var2 $t1 $firstList]
		    lappend d$d [list var2 $t2 $theRest]
		    lappend dP  [set d$d]
		    set result  [eval $d1 $dP]
		    # Set the new formats.
		    set TeXmodeVars(availableTeXFormats) \
		      [concat [lindex $result 0] "(-)" [lindex $result 1]]
		    TeX::rebuildMenu "TeXFormats"
		    return
		}
		"Auto Adjust Format" {
		    set helpText [help::prefString "autoAdjustFormat" "TeX"]
		    regsub -all {\|\|} "${helpText}." {.  } helpText
		    set setting [set TeXmodeVars(autoAdjustFormat)]
		    set title   "Auto Adjust FormatÉ"
		    set d 1
		    set d$d [list dialog::make -title $title]
		    
		    incr d
		    lappend d$d "'Auto Adjust FormatÉ' Setting"
		    lappend d$d [list text ${helpText}\r\r]
		    lappend d$d [list flag "Auto Adjust Format" $setting]
		    lappend dP  [set d$d]
		    set result  [eval $d1 $dP]
		    set TeXmodeVars(autoAdjustFormat) [lindex $result 0]
		    prefs::modified TeXmodeVars(autoAdjustFormat)
		    TeX::rebuildMenu "TeX Format"
		}
		"TeX Formats Help" {
		    set helpText [help::prefString "availableTeXFormats" "TeX"]
		    dialog::alert $helpText
		    return
		}
		default {
		    # Set this format name as the default.
		    set TeXmodeVars(nameOfTeXFormat) "$itemName"
		    TeX::postBuildFormat
		    status::msg "The current TeX format is now '$itemName'"
		    # If we're not in TeX mode, go no further.
		    if {$mode != "TeX"} {return}
		    # Find the base file, and find out if it has this format.
		    set baseFile   [TeX::currentBaseFile [win::Current]]
		    set results    [TeX::getFormatName $baseFile]
		    set baseFormat [lindex $results 0]
		    set baseWhat   [lindex $results 1]
		    # We pay attention to the format when typesetting, so
		    # check to see if the user wants to insert it -- the
		    # current format would normally be auto-adjusted when the
		    # window is activated ...
		    if {![string length $baseFormat]} {
			# Ask if we should insert the name of the format
			# on the first line.
			set msg "The base file for this window doesn't\
			  include the format name in the first line --\
			  would you like to insert it?"
			set action "insert"
		    } elseif {$baseFormat != $itemName} {
			# Ask if we should change the name of the format
			set msg "The base file for this window has a\
			  different format name in the first line --\
			  would you like to replace it?"
			set action "replace"
		    } else {
			# Everything is synchronized, so return.
			return
		    }
		    if {[askyesno $msg] == "yes"} {
			# We need to first turn off the activate hook ...
			set oldAA $TeXmodeVars(autoAdjustFormat)
			set TeXmodeVars(autoAdjustFormat) 0
			if {$baseWhat == "file"} {
			    # The base window is not currently open.  We need
			    # to open it, insert the text, and close it.
			    if {[catch {file::openQuietly $baseFile}]} {
				set TeXmodeVars(autoAdjustFormat) $oldAA
				error "Cancelled -- could not open base file."
			    } else {
				set baseFile [win::Current]
			    }
			} 
			# The window is currently open.  Bring it to the
			# front and make sure that it's not read-only.  
			set strippedBaseFile [win::StripCount $baseFile]
			foreach w [winNames -f] {
			    if {[win::StripCount $w] eq $strippedBaseFile} {
				bringToFront $w ; break
				set TeXmodeVars(autoAdjustFormat) $oldAA
			    } 
			}
			# The true base file should now be open, and in
			# front.
			set baseFile [win::Current]
			if {[win::getInfo $baseFile read-only]} {
			    setWinInfo -w $baseFile read-only 0
			} 
			set pos0 [minPos]
			if {$action == "insert"} {
			    set pos1 $pos0
			} else {
			    set pos1 [nextLineStart $pos0]
			}
			replaceText $pos0 $pos1 "%&${itemName}\r"
		    }
		}
	    }
	}
	"TeX Program" {
	    switch -- $itemName {
		"Edit TeX Programs" {
		    set programs $TeXmodeVars(availableTeXPrograms)
		    set p "Edit the list of available TeX Programs"
		    if {[catch {getline $p $programs} programs]} {
			error "cancel"
		    } elseif {![llength $programs]} {
			error "cancel"
		    }
		    set TeXmodeVars(availableTeXPrograms) $programs
		    prefs::modified TeXmodeVars(availableTeXPrograms)
		    TeX::rebuildMenu "TeXPrograms"
		}
		"TeX Programs Help" {
		    set helpText [help::prefString "availableTeXPrograms" "TeX"]
		    dialog::alert $helpText
		}
		default {
		    set TeXmodeVars(nameOfTeXProgram) $itemName
		    TeX::postBuildProgram
		    status::msg "The current TeX program is now '$itemName'"
		}
	    }
	}
	$texMenu {TeX::[join $itemName {}]}
	default  {error "Cancelled -- unknown menu name: $menuName"}
    }
}

# ×××× Adding/Removing Menu Items ×××× #

# A method for allowing the user to add macro menu items.

proc TeX::addMenuItem {{title "Choose a menu"} {includeFinish 0}} {
    
    global TeX::ChangeableMenus

    set menuNames [set TeX::ChangeableMenus]
    if {$includeFinish} {set menuNames [concat [list "(Finish)"] $menuNames]}
    if {[catch {listpick -p $title $menuNames} menuName]} {
	error "cancel"
    } elseif {$menuName == "(Finish)"} {
	status::msg ""
	return
    }
    set finish [TeX::addMenuItemDialog $menuName]
    status::msg "The new item has been added to the '$menuName' menu."
    # Rebuild the entire menu to make sure array elements are properly added.
    TeX::rebuildMenu
    set title "Choose another menu, or 'Finish'"
    if {!$finish} {TeX::addMenuItem $title 1}
}

proc TeX::addMenuItemDialog {menuName {title ""} {menuItem ""} {template1 "\\XXX¥\{¥"} {template2 "\}¥"}} {
    
    global TeX::MenuAdditions TeX::MacroInsertions
    
    if {$title == ""} {
	set title "Create a new '$menuName' menu item"
    } 
    set y 10
    set aMID [list -T $title]
    set yb 20
    set Template1 "Template start (¥ is a template stop) :" 
    set Template2 "Template end (highlighted text will be wrapped) :" 
    eval lappend aMID [dialog::button   "Finish"                    300 yb   ]
    eval lappend aMID [dialog::button   "More"                      300 yb   ]
    eval lappend aMID [dialog::button   "Cancel"                    300 yb   ]
    if {$menuItem == ""} {
	eval lappend aMID [dialog::textedit "Item Name :" $menuItem  10  y 25]
    } else {
	eval lappend aMID [dialog::text     "Item Name :"            10  y   ]
	eval lappend aMID [dialog::menu 10 y $menuItem $menuItem 200         ]
    } 
   eval lappend aMID [dialog::textedit $Template1 $template1         10  y 25]
   eval lappend aMID [dialog::textedit $Template2 $template2         10  y 25]
    incr y 20
    set result [eval dialog -w 380 -h $y $aMID]
    if {[lindex $result 2]} {
	# User pressed "Cancel'
	error "cancel"
    }
    set finish     [lindex $result 0]
    set menuItem   [string trim [lindex $result 3]]
    set template1  [lindex $result 4]
    set template2  [lindex $result 5]
    regsub -all {[^\\]\\} [lindex $result 4] "\\\\" template1
    regsub -all {[^\\]\\} [lindex $result 5] "\\\\" template2
    if {$menuItem != "" && $template1 != ""} {
	set menuAddition [list "item" 100 $menuItem]
	set TeX::MacroInsertions($menuItem) [list $template1 $template2]
	lappend TeX::MenuAdditions($menuName)  [list "item" end $menuItem]
	lappend menu::additions($menuName)     [list "item" end $menuItem]
	prefs::modified TeX::MenuAdditions($menuName)
	prefs::modified TeX::MacroInsertions($menuItem)
	return $finish
    } elseif {$finish == "1"} {
	return -code return
    } else {
	error "Cancelled -- one of the dialog fields was empty."
    } 
}


proc TeX::editMenuItem {{title "Choose a menu with additions"} {includeFinish 0}} {
    
    global TeX::MenuAdditions TeX::MacroInsertions
    
    set divider [list "item" "end" "(-)"]
    
    if {![llength [set menuNames [array names TeX::MenuAdditions]]]} {
	error "Cancelled -- there are no menu items to remove."
    }
    if {$includeFinish} {set menuNames [concat [list "(Finish)"] $menuNames]}

    if {[catch {listpick -p $title [lsort -dictionary $menuNames]} menuName]} {
	error "cancel"
    } elseif {$menuName == "(Finish)"} {
	status::msg ""
	return
    }
    foreach item [set TeX::MenuAdditions($menuName)] {
	if {$item == $divider} {continue}
	append menuItems  "[set what [lrange $item 2 end]] "
	set connect($what) $item
    } 
    if {[catch {listpick -p "Edit which item:" $menuItems} menuItem]} {
	error "cancel"
    } else {
	set title "Edit the '$menuItem' template"
	set template1 [lindex [set TeX::MacroInsertions($menuItem)] 0]
	set template2 [lindex [set TeX::MacroInsertions($menuItem)] 1]
	set finish    [TeX::addMenuItemDialog \
	  $menuName $title $menuItem $template1 $template2]
	# The new template has been added.
	set TeX::MenuAdditions($menuName) [lremove \
	  [set TeX::MenuAdditions($menuName)] [list $connect($menuItem)]]
	set menu::additions($menuName)  [lremove \
	  [set menu::additions($menuName)] [list $connect($menuItem)]]
    } 
    # Rebuild the entire menu to make sure array elements are properly added.
    TeX::rebuildMenu
    status::msg "The new template for the menu item '$menuItem' has been saved."
    set title "Choose another menu, or 'Finish'"
    if {!$finish} {TeX::editMenuItem $title 1}
}

proc TeX::removeMenuItem {{title "Choose a menu with additions"} {includeFinish 0}} {
    
    global TeX::MenuAdditions TeX::MacroInsertions menu::additions
    
    set divider [list "item" "end" "(-)"]
    
    if {![llength [set menuNames [array names TeX::MenuAdditions]]]} {
	error "Cancelled -- there are no menu items to remove."
    }
    if {$includeFinish} {set menuNames [concat [list "(Finish)"] $menuNames]}

    if {[catch {listpick -p $title [lsort -dictionary $menuNames]} menuName]} {
	error "cancel"
    } elseif {$menuName == "(Finish)"} {
	status::msg ""
	return
    }
    foreach item [set TeX::MenuAdditions($menuName)] {
	if {$item == $divider} {continue}
	append menuItems "[set what [lrange $item 2 end]] "
	set connect($what) $item
    } 
    if {[catch {listpick -p "Remove which items:" -l $menuItems} removeList]} {
	error "cancel"
    } else {
	foreach menuItem $removeList {
	    set TeX::MenuAdditions($menuName) [lremove \
	      [set TeX::MenuAdditions($menuName)] [list $connect($menuItem)]]
	    set menu::additions($menuName)  [lremove \
	      [set menu::additions($menuName)] [list $connect($menuItem)]]
	    unset TeX::MacroInsertions($menuItem)
	    prefs::modified TeX::MacroInsertions($menuItem)
	}
	prefs::modified TeX::MenuAdditions($menuName)
	if {![llength [set TeX::MenuAdditions($menuName)]]} {
	    unset TeX::MenuAdditions($menuName)
	} elseif {[set TeX::MenuAdditions($menuName)] == [list $divider]} {
	    unset TeX::MenuAdditions($menuName)
	}
    } 
    TeX::rebuildMenu $menuName
    status::msg "The menu items have been removed from the '$menuName' menu."
    if {[llength [array names TeX::MenuAdditions]]} {
	set title "Choose another menu, or 'Finish'"
	TeX::removeMenuItem $title 1
    } 
}

proc TeX::changeMenuIcon {{prefName ""}} {
    
    global TeXmodeVars texMenu
    
    variable texMenuIcons
    
    if {($prefName ne "")} {
        set newIconName $TeXmodeVars(texMenuIcon)
    } else {
        set dialogScript [list dialog::make -title "TeX Menu Icon" \
	  [list "" \
	  [list "text" "Choose an icon from the pop-up menu below."] \
	  [list [list "menu" [lsort -dictionary [array names texMenuIcons]]] \
	  "Icon Options:" $TeXmodeVars(texMenuIcon)] \
	  ]]
	set newIconName [eval $dialogScript]
	set TeXmodeVars(texMenuIcon) $newIconName
	prefs::modified TeXmodeVars(texMenuIcon)
    }
    if {[info exists texMenuIcons($newIconName)]} {
        set newIcon $texMenuIcons($newIconName)
	set inserted [menu::inserted $texMenu]
	if {[set inserted [menu::inserted $texMenu]]} {
	    # Remove old menu.
	    removeMenu $texMenu
	}
	# Update the icon.
	set texMenu $newIcon
	# Rebuild the menu
	menu::buildSome texMenu
	if {$inserted} {
	    # Insert the new menu
	    insertMenu $texMenu
	}
    } else {
	alertnote "Unknown menu icon: $TeXmodeVars(texMenuIcon)"
    }
    return
}

# ==========================================================================
#
# ×××× -------- ×××× #
# 
# Submenu definitions
#

# ×××× "Process" ×××× #
#
# If the current document belongs to a TeX fileset, display the base
# filename throughout.
#
############ New stuff FBO 2001-09 ##############
#
# New: TeX Program submenu in Process to select the TeX Program to use.
# Removed pdflatex xxx.tex since tex files are now "typeset".  To
# pdflatex a file, choose pdftex as the TeX Program and latex as the TeX
# format before typesetting.  If we're using a new version of CMacTeX is
# set, add a "Makeindex styles" submenu to select the style files use
# when make the index and the glossary.
# 

proc TeX::buildProcessMenu {{currentWin ""}} {

    global mode TeXmodeVars TeX::process
    
    if {$mode != "TeX" || ![package::active texMenu]} {
	return [TeX::buildMinimalProcess]
    } elseif {$currentWin == ""} { 
	set currentWin [win::TopNonProcessWindow]
	if {![file isfile [win::StripCount $currentWin]]} {
	    return [TeX::buildMinimalProcess]
	}
    }
    if {$currentWin == ""} {
	return [TeX::buildMinimalProcess]
    } else {
	set currentDoc [file tail $currentWin]
	# Process an untitled window:
	if {[set num [TeX::winUntitled]]} {
	    if {$num > 1} {set currentDoc "untitled$num"}
	}
    }
    set docBasename [file rootname $currentDoc]
    set projBasename $docBasename
    set currentProj [isWindowInFileset $currentWin "tex"]
    if {$currentProj !=	""} {
	set theWin [texFilesetBaseName $currentProj]
	set currentDoc [file tail $theWin]
	set docBasename [file rootname $currentDoc]
    } else {
	set theWin $currentWin
    }

    # Determine which menu items are dimmed:
    set theRoot [file root $theWin]
    foreach ext {DVI PS AUX IDX GLO PDF BBL} {
	if {[file exists "$theRoot.[string tolower $ext]"] || [file exists "$theRoot.$ext"]} {
	    set prefix${ext} ""
	} else {
	    set prefix${ext} "\("
	}
    }

    # Selection may change before we have a chance to rebuild this menu. 
    # Hence always assume there is a selection.  With a '-postcommand' we
    # could get this correct.
    set prefixSelection ""

    set menuList [list \
      {Menu -n "TeX Program" {}} \
      {Menu -n "TeX Format"  {}} ]
    set subMenus [list "TeXProgram" "TeXFormat"]
    
    # Add a "MakeIndex Styles" menu if using newer CMacTeX.
    if {[::xserv::getCurrentImplementationNameFor tex ""] eq "CMacTeX >= 4"} {
	lappend menuList {Menu -n "MakeIndex Styles" {}}
	lappend subMenus "MakeIndex Styles"
    }
    lappend menuList "(-)"
    
    if {$TeXmodeVars(runTeXInBack)} {
	lappend menuList [list /TBack Typeset $currentDoc] \
	  [list /T<U<ITypeset $currentDoc]
    } else {
	lappend menuList [list /TTypeset $currentDoc] \
	  [list /T<U<IBack Typeset $currentDoc]
    }
    lappend menuList "(-)" [list /`<BSynchronize $currentDoc] "(-)"
    lappend menuList \
      [list <U<O/V${prefixDVI}View "$docBasename\.dvi"] \
      [list <U<O/P${prefixDVI}Print "$docBasename\.dvi"] \
      "(-)" \
      {<U<O/TTypeset Clipboard} \
      [list <U<I<O/T${prefixSelection}Typeset Selection] \
      "(-)" \
      [list ${prefixPS}Open "$docBasename\.ps"]

    foreach p [array names TeX::process] {
	foreach {menuItem command} $TeX::process($p) {}
	lappend menuList [subst -nocommands $menuItem]
    }
    
    lappend menuList \
      [list ${prefixPS}Print "$docBasename\.ps"] \
      [list ${prefixPS}Distill "$docBasename\.ps"] \
      "(-)" \
      [list ${prefixPS}View "$docBasename\.ps"] \
      [list <I<O/P${prefixPDF}View "$docBasename\.pdf"] \
      "(-)" \
      [list <S/B<I<O${prefixAUX}bibtex "$docBasename\.aux"] \
      [list ${prefixIDX}makeindex "$docBasename\.idx"] \
      [list ${prefixGLO}makeglossary "$docBasename\.glo"] \
      "(-)" \
      {Menu -n "Open Auxiliary File" {}} \
      "(-)" \
      {Remove Auxiliary FilesÉ} {Rebuild Process Menu}
    lappend subMenus ProcessOpen
    return [list build $menuList {TeX::menuProc -M TeX -m} $subMenus]
}

# Separate out some general processing commands so we can eventually
# expose an interface by which new commands may be added (e.g. pdf
# manipulation).
set TeX::process(dvips) \
  [list {${prefixDVI}dvips "$docBasename\.dvi"} {TeX::doTypesetCommand dvips DVI}]
set TeX::process(dvipdf) \
  [list {${prefixDVI}dvipdf "$docBasename\.dvi"} {TeX::doTypesetCommand dvipdf DVI}]

proc TeX::buildMinimalProcess {} {
    
    set menuList [list \
      "/TTypesetÉ" "(-)" "<U<O/TTypeset Clipboard" "Typeset Selection" "(-)" \
      {Menu -n "TeX Program" {}} \
      {Menu -n "TeX Format"  {}} ]
    set subMenus [list "TeXProgram" "TeXFormat"]

    return [list build $menuList {TeX::menuProc -M TeX -m} $subMenus]
}

# Return a submenu of LaTeX auxiliary files with basename $basename1,
# except for the .aux file whose primary basename is $basename2.

proc TeX::buildProcessOpenMenu {} {

    set currentWin [win::Current]
    set currentDoc [file tail $currentWin]
    set docBasename [file rootname $currentDoc]
    set projBasename $docBasename
    set currentProj [isWindowInFileset $currentWin "tex"]
    if {$currentProj !=	""} {
	set currentDoc [file tail [texFilesetBaseName $currentProj]]
	set docBasename [file rootname $currentDoc]
    }
    set menuList [list \
      "<S$docBasename\.aux " \
      "<S$projBasename\.aux" \
      "(-)" \
      "$docBasename\.bbl" \
      "$docBasename\.blg" \
      "$docBasename\.glo" \
      "$docBasename\.idx" \
      "$docBasename\.ilg" \
      "$docBasename\.ind" \
      "$docBasename\.lof" \
      "$docBasename\.log" \
      "$docBasename\.lot" \
      "$docBasename\.toc" \
      "(-)" \
      "<U<O/OAny TeX FileÉ" \
      ]
    set menuName "Open Auxiliary File"
    return [list build $menuList {TeX::menuProc -M TeX -m} "" $menuName]
}

# ×××× -------- ×××× #

# ×××× "TeX Program" ×××× #

proc TeX::buildProgramMenu {args} {

    global TeXmodeVars

    set menuList [concat $TeXmodeVars(availableTeXPrograms) \
      [list "(-)" "Edit TeX ProgramsÉ" "TeX Programs HelpÉ"]]
    return [list build $menuList {TeX::menuProc -M TeX -m} "" "TeX Program"]
}

proc TeX::postBuildProgram {args} {

    global TeXmodeVars

    foreach item $TeXmodeVars(availableTeXPrograms) {
	markMenuItem -m {TeX Program} $item off
    }
    markMenuItem -m {TeX Program} $TeXmodeVars(nameOfTeXProgram) on
}

# ×××× "TeX Format" ×××× #

# This proc updates the menus according to the mode prefs.

proc TeX::buildFormatMenu {args} {

    global TeXmodeVars

    set menuList $TeXmodeVars(availableTeXFormats)
    lappend menuList "(-)" "Auto Adjust Format" \
      "Edit TeX FormatsÉ" "TeX Formats HelpÉ"
    
    return [list build $menuList {TeX::menuProc -M TeX -m} "" "TeX Format"]
}

proc TeX::postBuildFormat {args} {
    
    global TeXmodeVars
    
    foreach item $TeXmodeVars(availableTeXFormats) {
	if {$item != "(-)"} {
	    markMenuItem -m {TeX Format} $item off
	}
    }
    if {$TeXmodeVars(nameOfTeXFormat) != ""} {
	markMenuItem -m {TeX Format} $TeXmodeVars(nameOfTeXFormat) on
    }
    markMenuItem -m {TeX Format} "Auto Adjust Format" \
      $TeXmodeVars(autoAdjustFormat)
}

# ×××× "MakeIndex Styles" ×××× #

proc TeX::buildMakeIndexMenu {} {

    global TeXmodeVars

    set num 1
    foreach type [list index glossary] {
	set stylePref  TeXmodeVars(TeX${type}Style)
	set stylesPref TeXmodeVars(TeX${type}Styles)
	if {[string length [set $stylePref]]} {
	    if {[lsearch [set $stylesPref] [set $stylePref]] == "-1"} {
		lappend $stylesPref [set $stylePref]
	    } 
	} 
	set menuList${num} [list \
	  "Add ${type} styleÉ" "Remove ${type} styleÉ" "(-)" "No ${type} style"]
	foreach item [set $stylesPref] {
	    lappend menuList${num} "\{${type}\} [file root [file tail $item]]"
	}
	incr num
    }
    set menuList [concat $menuList1 "(-)" $menuList2]
    set menuName "MakeIndex Styles"
    return [list build $menuList {TeX::menuProc -M TeX -m} "" $menuName]
}

proc TeX::postBuildMakeIndex {} {

    global TeXmodeVars
    
    set enable1 [expr {[llength $TeXmodeVars(TeXindexStyles)]    ? 1 : 0}]
    set enable2 [expr {[llength $TeXmodeVars(TeXglossaryStyles)] ? 1 : 0}]
    
    enableMenuItem -m {MakeIndex Styles} {Remove index styleÉ}    $enable1
    enableMenuItem -m {MakeIndex Styles} {Remove glossary styleÉ} $enable2

    foreach type [list index glossary] {
	foreach item $TeXmodeVars(TeX${type}Styles) {
	    set item "\{$type\} [file root [file tail $item]]"
	    markMenuItem -m {MakeIndex Styles} $item 0
	}
	if {![string length [set item $TeXmodeVars(TeX${type}Style)]]} {
	    set item "No ${type} style"
	} else {
	    set fileRootTail [file root [file tail $item]]
	    set item "\{$type\} $fileRootTail"
	}
	markMenuItem -m {MakeIndex Styles} $item 1
    }
}

# ×××× -------- ×××× #

# ×××× "Goto" ×××× #

set menu::items(Goto) {

    "LaTeX application" "BibTeX application" "MakeIndex application" "(-)"

    "Next Template Stop" "Prev Template Stop" "(-)"

    "Next Paragraph" "Prev Paragraph" "(-)"

    "Next Command" "Prev Command"
    "Next Command Select" "Prev Command Select"
    "Next Command Select With Args" "Prev Command Select With Args" "(-)"

    "Next Environment" "Prev Environment"
    "Next Environment Select" "Prev Environment Select" "(-)"

    "Next Section" "Prev Section"
    "Next Section Select" "Prev Section Select"
    "Next Subsection" "Prev Subsection"
    "Next Subsection Select" "Prev Subsection Select"
}

# ×××× "LaTeX Utilities" ×××× #

set "menu::items(LaTeX Utilities)" {

    "Delete Template Stops" "Delete CommentsÉ" "(-)"
    "Convert Quotes" "Convert Dollar Signs"
}

# ×××× "LaTeX Help" ×××× #

set "menu::items(LaTeX Help)" {

    "LaTeX Home Page" "WWW LaTeX HelpÉ" "(-)"
    
    "LaTeX Mode Intro - text" "Users Guide - pdf" "Users Guide - tex"
    "Typesetting LaTeX Files - text" "teTeX Help - text" "(-)"
    "LaTeX Menus - tex" "LaTeX Key Bindings - tex"
    "Introduction to LaTeX - tex" "(-)"

    "Completions Tutorial"
}

# ×××× "LaTeX Menu" ×××× #

set "menu::items(LaTeX Menu)" {

    "Compress Text Menus" "Compress Math Menus" "(-)"
    "AMS-LaTeX" "Dollars For Math" "(-)"
    "Assign Menu BindingsÉ" "Restore DefaultsÉ" "(-)"
    "Add Menu Template ItemÉ" "Edit Template ItemÉ" "Remove Template ItemÉ" 
}

# Windows OSes don't support icons in menu bars.
if {($tcl_platform(platform) ne "windows")} {
    lappend "menu::items(LaTeX Menu)" "(-)" "Change Menu IconÉ"
}

# ×××× "Documents" ×××× #

proc TeX::buildDocumentsMenu {} {
    
    global TeXmodeVars menu::items menu::which_subs
    
    set menuList1 [list \
      "New DocumentÉ" \
      {Menu -n "Insert Document" -m -p TeX::menuProc -M TeX {
	"article"
	"report"
	"book"
	"letter"
	"slides"
	"otherÉ"
    }} \
      "(-)" \
      "optionsÉ" \
      "usepackage" \
      ]
    if {$TeXmodeVars(buildPkgsSubmenu)} {
	set menuList2 [list {Menu -n "Packages" {}}]
	set menu::which_subs(Documents) [list "Packages"]
	set menuList4 [list \
	  "View Search PathsÉ" \
	  "Add Search PathsÉ" \
	  "Remove Search PathsÉ" \
	  "(-)" \
	  "Rebuild Documents Submenu" \
	  ]
    } else {
	set menuList2 [list]
	set menu::which_subs(Documents) [list]
	set menuList4 [list]
    }
    set menuList3 [list \
      "(-)" \
      "filecontentsÉ" \
      "filecontents All" \
      "(-)" \
      "Build Packages SubmenuÉ" \
      ]
    
    set menu::items(Documents) [concat \
      $menuList1 $menuList2 $menuList3 $menuList4]
    
    return [list build [set menu::items(Documents)] \
      {TeX::menuProc -M TeX -m} [set menu::which_subs(Documents)]]
}

proc TeX::postBuildDocuments {} {
    
    global TeXmodeVars
    
    if {!$TeXmodeVars(buildPkgsSubmenu)} {
	markMenuItem -m {Documents} "Build Packages SubmenuÉ" 0 Ã
    } else {
	markMenuItem -m {Documents} "Build Packages SubmenuÉ" 1 Ã
	set enable [expr {[llength $TeXmodeVars(TeXSearchPath)] ? 1 : 0}]
	foreach item [list "View Search PathsÉ" "Remove Search PathsÉ"] {
	    enableMenuItem -m "Documents" $item $enable
	}
    }
}

# ×××× "Packages" ×××× #

proc TeX::buildPackagesMenu {} {

    global TeXmodeVars TeX::PackagesSubmenuItems latexPackages

    if {$TeXmodeVars(buildPkgsSubmenu)} {
	if {![info exists TeX::PackagesSubmenuItems] || \
	  [set TeX::PackagesSubmenuItems] == ""} {
	    set folders [TeX::buildTeXSearchPath 0]
	    set TeX::PackagesSubmenuItems \
	      [menu::buildHierarchy $folders "Packages" \
	      TeX::packagesMenuProc latexPackages ".sty"]
	}
	return [set TeX::PackagesSubmenuItems]
    } else {
	catch {unset TeX::PackagesSubmenuItems}
	return ""
    }
}

proc TeX::packagesMenuProc {submenu pkgName} {

    global latexPackages

    # See latexMacros.tcl for definition of 'TeX::insertPackage':
    TeX::insertPackage [file tail [file rootname \
      $latexPackages([file join $submenu $pkgName])]]
}

# ×××× -------- ×××× #

# ×××× "Page Layout" ×××× #

set "menu::items(Page Layout)"  {

    "maketitle" "(-)"
    "abstract" "titlepage" "(-)"
    "pagestyleÉ" "thispagestyleÉ" "pagenumberingÉ" "(-)"
    "twocolumn" "onecolumn"
}

# ×××× "Sectioning" ×××× #

set menu::items(Sectioning) {

    "<E<Spart"          "<S<Upart*"             "<Spart with label"
    "<E<Schapter"       "<S<Uchapter*"          "<Schapter with label"
    "<E<Ssection"       "<S<Usection*"          "<Ssection with label"
    "<E<Ssubsection"    "<S<Usubsection*"       "<Ssubsection with label"
    "<E<Ssubsubsection" "<S<Usubsubsection*"    "<Ssubsubsection with label"
    "<E<Sparagraph"     "<S<Uparagraph*"        "<Sparagraph with label"
    "<E<Ssubparagraph"  "<S<Usubparagraph*"     "<Ssubparagraph with label"
    "(-)"

    "appendix"
}

# ×××× "Text Style" ×××× #

set "menu::items(Text Style)"  {

    "<E<Sem"            "<Semph" "underline" "(-)"

    "<E<Stextup"        "<Supshape"
    "<E<Stextit"        "<Sitshape"
    "<E<Stextsl"        "<Sslshape"
    "<E<Stextsc"        "<Sscshape" "(-)"

    "<E<Stextmd"        "<Smdseries"
    "<E<Stextbf"        "<Sbfseries" "(-)"

    "<E<Stextrm"        "<Srmfamily"
    "<E<Stextsf"        "<Ssffamily"
    "<E<Stexttt"        "<Sttfamily" "(-)"

    "<E<Stextnormal"    "<Snormalfont"
}

set "menu::items(Text Commands)" {

    "textsuperscript" "textcircled" "(-)"

    "textcompwordmark" "textvisiblespace" "(-)"

    "!Ñtextemdash" "!Ðtextendash" "!Átextexclamdown"
    "!Àtextquestiondown" "!Òtextquotedblleft" "!Ótextquotedblright"
    "!Ôtextquoteleft" "!Õtextquoteright" "(-)"

    "textbullet" "textperiodcentered" "(-)"
    "textbackslash" "textbar" "textless" "textgreater" "(-)"
    "textasciicircum" "textasciitilde" "(-)"
    "textregistered" "texttrademark"
}

# ×××× "International" ×××× #

set menu::items(International) {

    "˜" "—" "™" "š" "›" "(-)"
    "" "Ï" "¾" "Œ" "¿" "(-)"
    "‚" "Î" "®" "" "¯" "(-)"
    "ss" "SS" "(-)"
    "À" "Á"
}

# ×××× "Environments" ×××× #

set menu::items(Environments) {

    "itemizeÉ" "enumerateÉ" "descriptionÉ" "thebibliographyÉ" "(-)"
    "slide" "overlay" "note" "(-)"
    "figure" "table" "tabularÉ" "(-)"
    "verbatim" "quote" "quotation" "verse" "(-)"
    "center" "flushleft" "flushright" "(-)"
    "Add Item" "Choose EnvironmentÉ" "Add New EnvironmentÉ"
}

# ×××× "Boxes" ×××× #

set menu::items(Boxes)  {

    "mbox" "makebox" "fbox" "framebox" "(-)"
    "newsavebox" "sbox" "savebox" "usebox" "(-)"
    "raisebox" "(-)"
    "parbox" "minipage" "(-)"
    "rule"
}

# ×××× "Miscellaneous" ×××× #

set menu::items(Miscellaneous) {

    "verb" "footnote" "marginal note" "(-)"
    "label" "ref" "eqref" "pageref" "cite" "nocite" "(-)"
    "item" "(-)"
    "quotes" "double quotes" "(-)"
    "TeX logo" "LaTeX logo" "LaTeX2e logo" "date" "(-)"
    "! dag" "ddag" "!¤section mark" "!¦paragraph mark" "!©copyright"
    "!£pounds"
}

# ×××× "Math Modes" ×××× #

# (called below and in latexKeys.tcl):

proc TeX::setMathModesItems {} {

    global TeXmodeVars menu::items

    if {$TeXmodeVars(useDollarSigns)} {
	Bind '4' <zc>  {TeX::macroMenuProc {Math Modes} {TeX math}}        "TeX"
	Bind '4' <zoc> {TeX::macroMenuProc {Math Modes} {TeX displaymath}} "TeX"
	set "menu::items(Math Modes)" {

	    "<B<O/MTeX math" "<B<I<O/MTeX displaymath" "(-)"
	    "LaTeX math" "LaTeX displaymath"
	}
    } else {
	Bind '4' <zc>  {TeX::macroMenuProc {Math Modes} {LaTeX math}}        "TeX"
	Bind '4' <zoc> {TeX::macroMenuProc {Math Modes} {LaTeX displaymath}} "TeX"
	set "menu::items(Math Modes)" {

	    "TeX math" "TeX displaymath" "(-)"
	    "<B<O/MLaTeX math" "<B<I<O/MLaTeX displaymath"
	}
    }
}

# ×××× "Math Style" ×××× #

proc TeX::setMathStyleItems {} {

    global TeXmodeVars menu::items

    if {$TeXmodeVars(useAMSLaTeX)} {
	set "menu::items(Math Style)" {

	    "mathit" "mathrm" "mathbf" "mathsf" "mathtt" "mathcal" "(-)"
	    "mathbb" "mathfrak" "(-)"
	    "displaystyle" "textstyle" "scriptstyle" "scriptscriptstyle"
	}
    } else {
	set "menu::items(Math Style)" {

	    "mathit" "mathrm" "mathbf" "mathsf" "mathtt" "mathcal" "(-)"
	    "displaystyle" "textstyle" "scriptstyle" "scriptscriptstyle"
	}
    }
}


# ×××× "Text Size" ×××× #

proc TeX::setTextSizeItems {} {

    global TeXmodeVars menu::items TeX::MenuKeysDefault
    
    if {$TeXmodeVars(useAMSLaTeX)} {
	set "menu::items(Text Size)" {
	    "Tiny" "tiny" "SMALL" "Small" "small" "normalsize" "large"
	    "Large" "LARGE" "huge" "Huge"
	}
    } else {
	set "menu::items(Text Size)" {
	    "tiny" "scriptsize" "footnotesize" "small" "normalsize" "large"
	    "Large" "LARGE" "huge" "Huge"
	}
    }
    TeX::setTextSizeKeys

}


# ×××× "Math Environments" ×××× #

proc TeX::setMathEnvsItems {} {

    global TeXmodeVars menu::items TeX::MenuKeysDefault

    if {$TeXmodeVars(useAMSLaTeX)} {
	set "menu::items(Math Environments)" {

	    "math" "(-)"

	    "<E<Sequation"      "<Sequation*"   "subequations" "(-)"

	    "<E<SalignÉ"        "<Salign*É"
	    "<E<SflalignÉ"      "<Sflalign*É"
	    "<E<SalignatÉ"      "<Salignat*É"
	    "<E<SgatherÉ"       "<Sgather*É"
	    "<E<SmultlineÉ"     "<Smultline*É" "(-)"

	    "gatheredÉ" "alignedÉ" "alignedatÉ" "splitÉ" "casesÉ" "(-)"

	    "arrayÉ" "subarrayÉ" "matrixÉ" "pmatrixÉ" "bmatrixÉ"
	    "BmatrixÉ" "vmatrixÉ" "VmatrixÉ" "smallmatrixÉ" "(-)"

	    "Choose EnvironmentÉ" "Add New EnvironmentÉ"
	}
    } else {
	set "menu::items(Math Environments)" {

	    "math" "(-)"
	    "displaymath" "equation" "(-)"
	    "eqnarrayÉ" "eqnarray*É" "(-)"
	    "arrayÉ" "(-)"
	    "Choose EnvironmentÉ" "Add New EnvironmentÉ"
	}
    }
    TeX::setMathEnvsKeys
}

# ×××× "Theorem" ×××× #

# (Contributed by Paul Gastin -- thanks!)

set menu::items(Theorem) {

    "<E<Sdefinition"    "<Sdefinition with label"
    "<E<Sremark"        "<Sremark with label" "(-)"

    "<E<Slemma"         "<Slemma with label"
    "<E<Sproposition"   "<Sproposition with label"
    "<E<Stheorem"       "<Stheorem with label"
    "<E<Scorollary"     "<Scorollary with label" "(-)"

    "claim" "<E<Sclaimno" "<Sclaimno with label" "(-)"

    "proof" "proofof"
}

# ×××× "Formulas" ×××× #

set menu::items(Formulas) {

    "subscript" "superscript" "(-)"
    "frac" "sqrt" "nth root" "(-)"
    "one parameterÉ" "two parametersÉ"
}

# ×××× "Greek" ×××× #

set menu::items(Greek) {

    "alpha"
    "beta" 
    "<E<Sgamma"         "<SGamma" 
    "<E<Sdelta"         "<SDelta" 
    "epsilon"
    "zeta"
    "eta" 
    "<E<Stheta"         "<STheta"
    "iota"
    "kappa" 
    "<E<Slambda"        "<SLambda"
    "mu"
    "nu" 
    "<E<Sxi"             "<SXi"
    "omicron" 
    "<E<Spi"            "<SPi" 
    "rho" 
    "<E<Ssigma"         "<SSigma" 
    "tau"
    "<E<Supsilon"       "<SUpsilon"
    "<E<Sphi"           "<SPhi"
    "chi" 
    "<E<Spsi"           "<SPsi"
    "<E<Somega"         "<SOmega" "(-)"

    "varepsilon" "vartheta" "varpi" "varrho" "varsigma" "varphi"
}

# ×××× "Binary Operators" ×××× #

set "menu::items(Binary Operators)" {

    "!±pm" "mp" "times" "!Ödiv" "ast" "star" "circ" "bullet" "cdot" "cap"
    "cup" "uplus" "sqcap" "sqcup" "vee" "wedge" "setminus" "(-)"

    "diamond" "bigtriangleup" "bigtriangledown" "triangleleft"
    "triangleright" "lhd" "rhd" "unlhd" "unrhd" "(-)"

    "oplus" "ominus" "otimes" "oslash" "odot" "(-)"

    "bigcirc" "dagger" "ddagger" "amalg" "wr"
}

# ×××× "Relations" ×××× #

set menu::items(Relations) {

    "<E<S!³geq"         "<S!²leq" 
    "<E<Sprec"          "<Ssucc" 
    "<E<Spreceq"        "<Ssucceq"
    "<E<S!Çll"          "<S!Ègg"
    "<E<Ssubset"        "<Ssupset"
    "<E<Ssubseteq"      "<Ssupseteq" 
    "<E<Ssqsubset"      "<Ssqsupset"
    "<E<Ssqsubseteq"    "<Ssqsupseteq" 
    "<E<Sin"            "<Sni"
    "<E<Sdash"         "<Svdashv" "(-)"

    "equiv" "sim" "simeq" "asymp" "!Åapprox" "cong" "!­neq" "doteq"
    "propto" "(-)" "models" "perp" "mid" "parallel" "bowtie" "join" "smile"
    "frown"
}

# ×××× "Arrows" ×××× #

set menu::items(Arrows) {

    "<E<Sleftarrow"             "<SLeftarrow"
    "<E<Srightarrow"            "<SRightarrow"
    "<E<Sleftrightarrow"        "<SLeftrightarrow"
    "<E<Slongleftarrow"         "<SLongleftarrow"
    "<E<Slongrightarrow"        "<SLongrightarrow"
    "<E<Slongleftrightarrow"    "<SLongleftrightarrow" "(-)"

    "<E<Suparrow"               "<SUparrow"
    "<E<Sdownarrow"             "<SDownarrow"
    "<E<Supdownarrow"           "<SUpdownarrow" "(-)"

    "mapsto" "longmapsto" "leadsto" "(-)"

    "leftharpoonup" "rightharpoonup" "leftharpoondown" "rightharpoondown"
    "rightleftharpoons" "hookleftarrow" "hookrightarrow" "nearrow"
    "searrow" "swarrow" "nwarrow"
}

# ×××× "Dots" ×××× #

set menu::items(Dots) {
    "bullet" "cdot" "(-)" "ldots" "cdots" "vdots" "ddots"
}

# ×××× "Symbols" ×××× #

set menu::items(Symbols) {
    "aleph" "hbar" "imath" "jmath" "ell" "wp" "Re" "Im" "mho" "(-)"

    "angle" "backslash" "bot" "emptyset" "exists" "forall" "!°infty"
    "nabla" "!Âneg" "!¶partial" "prime" "!Ãsurd" "top" "(-)"

    "Box" "Diamond" "triangle" "clubsuit" "diamondsuit" "heartsuit"
    "spadesuit" "(-)"

    "flat" "natural" "sharp"
}

# ×××× "Functions" ×××× #

set menu::items(Functions) {

    "arccos" "arcsin" "arctan" "arg" "cos" "cosh" "cot" "coth" "csc" "deg"
    "det" "dim" "exp" "gcd" "hom" "inf" "ker" "lg" "lim" "liminf" "limsup"
    "ln" "log" "max" "min" "Pr" "sec" "sin" "sinh" "sup" "tan" "tanh" "(-)"

    "bmod" "pmod"
}

# ×××× "Large Operators" ×××× #

set "menu::items(Large Operators)"  {

    "sum" "prod" "coprod" "int" "oint" "(-)"

    "bigcup" "bigcap" "bigsqcup" "bigvee" "bigwedge" "bigodot" "bigotimes"
    "bigoplus" "biguplus"
}

# ×××× "Delimiters" ×××× #

set menu::items(Delimiters) {

    "parentheses" "brackets" "braces" "vertical bars" "other delimsÉ" "(-)"

    "half-open interval" "half-closed interval" "(-)"

    "<E<Sbig parentheses"       "<Smulti-line big parentheses"
    "<E<Sbig brackets"          "<Smulti-line big brackets"
    "<E<Sbig braces"            "<Smulti-line big braces"
    "<E<Sbig vertical bars"     "<Smulti-line big vertical bars"
    "<E<Sother big delimsÉ"     "<Sother multi-line big delimsÉ" "(-)"

    "<E<Sbig left brace"        "<Smulti-line big left brace"
    "<E<Sother mixed big delimsÉ" "<Sother multi-line mixed big delimsÉ"
}

# ×××× "Math Accents" ×××× #

set "menu::items(Math Accents)"  {

    "acute" "bar" "breve" "check" "dot" "ddot" "grave" "hat" "tilde" "vec" "(-)"
    "widehat" "widetilde"
}

# ×××× "Grouping" ×××× #

set "menu::items(Grouping)"  {

    "underline" "overline" "underbrace" "overbrace" "(-)"
    "overrightarrow" "overleftarrow" "(-)" "stackrel"
}

# ×××× "Spacing" ×××× #

set menu::items(Spacing) {

    "neg thin" "thin" "medium" "thick" "(-)"
    "quad" "qquad" "(-)"
    "hspace" "vspace" "(-)"
    "hfill" "vfill" "(-)"
    "smallskip" "medskip" "bigskip"
}

# ==========================================================================
#
# .