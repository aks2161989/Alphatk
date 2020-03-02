## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "alphaMenus.tcl"
 #                                          created: 04/07/1998 {07:36:22 AM}
 #                                      last update: 06/02/2006 {01:35:25 PM}
 # Description:
 # 
 # Initialises variables which contain the global menus.  If you use the
 # smarterSource package, you can over-ride these quite easily.  This file is
 # sourced by the procedure [alpha::buildAndInsertMenus] during Alpha's
 # initialization.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1998-2006  Vince Darley
 #
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc alphaMenus.tcl {} {}

namespace eval menu {}

# All of the dividers in these menus are unique, i.e. have trailing spaces so
# that menu insertion code can make use of them.  AlphaTcl code that wants to
# insert a divider at the top should use "(-)", and use "(-) " to insert one
# at the end of the menu.

# ×××× File menu ×××× #
set menu::items(File) {
    "/Nnew"
    "/OopenÉ"
    "<E<B<O/OopenRemoteÉ"
}

if {$alpha::platform == "tk"} {
    lappend menu::items(File) "useTabbedWindowÉ"
}

lappend menu::items(File) \
    "<E<S/Wclose" \
    "\(<S<O<U/WcloseFloat" \
    "<S<I<O/WcloseAll" \
    "(-" \
    "<E<S/Ssave" \
    "<S<B<O/SsaveUnmodified" \
    "<S<I<O/SsaveAll" \
    "<E<S<U<O/SsaveAsÉ" \
    "<S<I<U<O/SrenameToÉ" \
    "saveACopyAsÉ" \
    "revertToSaved" \
    "(- " \
    {Menu -n fileUtils -p menu::fileUtils {}} \
    "(-  " \
    "/P<O<UpageSetupÉ" \
    "/P<EprintÉ" \
    "/P<S<I<OprintAll"

# Don't add quit menu on MacOS X, the app menu has one already
if {$alpha::macos != 2} {
    lappend menu::items(File) "(-   " "/Qquit"
}
lappend menu::which_subs(File) "fileUtils"
set menu::proc(File) menu::fileProc

# ×××× Edit menu ×××× #

if {$tcl_platform(platform) eq "windows"} {
    set menu::items(Edit) {
	"/Z<Bundo"
	"/Z<B<Uredo"
	"(-"
	"/X<S<Bcut"
	"/C<S<Bcopy"
	"/V<S<Bpaste"
    }
} else {
    set menu::items(Edit) {
	"/Z<Eundo"
	"/Z<S<I<Oredo"
	"(-"
	"/X<E<Scut"
	"/C<E<Scopy"
	"/V<E<Spaste"
    }
}

lappend menu::items(Edit) \
  "delete" \
  "zapNonPrintables" \
  "(- " \
  "/A<EselectAll" "/A<S<I<OselectParagraph" "/Bbalance" \
  "(-  " \
  {Menu -n tabConversions {
    "allTabsToSpaces"
    "allSpacesToTabs"
    "(-)"
    "leadingTabsToSpaces"
    "leadingSpacesToTabs"
}} \
  "/I<Bindent" \
  {/[<E<SshiftLeft} {/[<S<I<OshiftLeftSpace} \
  {/]<E<SshiftRight} {/]<S<I<OshiftRightSpace}

if {${alpha::platform} == "tk"} {
    set menu::items(Edit) [linsert $menu::items(Edit) 12 "/W<B<Ofold"]
}

# ×××× Text menu ×××× #
set menu::items(Text) {
    "/I<E<SfillParagraph"
    "/I<S<O<IwrapParagraph"
    "/I<U<I<OsentenceParagraph"
    "<E<SlineToParagraph"
    "<S<IparagraphToLine"
    "(-"
    "<E<SsortLines"
    "<S<IreverseSort"
    "<S<UsortParagraphs"
    "/`<E<Stwiddle" 
    "/`<S<I<OtwiddleWords" 
    "<E<SupcaseRegion"
    "<S<IdowncaseRegion"
    "(- "
    {Menu -n Strings {
	"<E<SinsertPrefix"
	"<S<IremovePrefix"
	"<E<SinsertSuffix"
	"<S<IremoveSuffix"
	"setPrefixÉ"
	"setSuffixÉ"}
    }
    "/D<E<ScommentLine"
    "/D<S<I<OuncommentLine"
    "<E<ScommentBox"
    "<S<IuncommentBox"
    "<E<ScommentParagraph"
    "<S<IuncommentParagraph"
}
set menu::proc(Text) menu::textEditProc
set menu::proc(Edit) menu::textEditProc

proc menu::textEditProc {menu item} {
    requireOpenWindow "Cancelled -- \"[quote::Prettify $menu]\" menu items\
      require an open window."
    switch -- $item {
	"delete"                  clear
	"selectParagraph"         paragraph::select
	"commentLine"             comment::Line
	"uncommentLine"           comment::undoLine
	"commentBox"              comment::Box
	"uncommentBox"            comment::undoBox
	"commentParagraph"        comment::Paragraph
	"uncommentParagraph"      comment::undoParagraph
	"fillParagraph"           paragraph::fill
	"sentenceParagraph"       paragraph::sentence
	"indent" {
	    if {[isSelection]} {
		::indentSelection
	    } else {
		bind::IndentLine
	    }
	}
	"indentLine"              bind::IndentLine
	"fold"                    bind::Fold
	default                  {eval $item}
    }
}

# ×××× Search menu ×××× #
set menu::items(Search) {
    "/R<S<O<I<BreplaceInFilesetÉ"
    "(-  "
    "/,<BplaceBookmark"
    "/.<BreturnToBookmark"
    "/G<I<BgotoLine"
    "(-   "
    "/M<E<I<OmatchingLinesÉ" 
    "/M<E<BnextMatch"
    "(-    "
    "/K<E<I<OgotoFunc"
    "/K<E<O<BgotoFileMark"
    {Menu -n namedMarks -p namedMarkProc {
	"markFile"
	"displayNamedMarks"
	"/F<E<O<UfloatNamedMarks"
	"(-"
	"/K<E<OsetNamedMarkÉ"
	"removeNamedMarkÉ"
	"removeAllMarks"
	"(-"
	"sortAlphabetically"
	"sortByPosition"}
    }
    {Menu -n thePin {
	"/ <BsetPin"
	"exchangePointAndPin"
	"/=hiliteToPin"}
    }
}
set menu::proc(Search) ""

# ×××× Utils menu ×××× #
set menu::proc(fileUtils) menu::fileUtils
set menu::proc(winUtils) menu::fileUtils
set menu::items(fileUtils) {
    "fileRemoveÉ"
    "hexDumpÉ"
    "fileInfoÉ"
    "showInFinder"
    "convertEolsÉ"
}
if {$::alpha::macos} {
    lappend menu::items(fileUtils) "textToAlphaÉ"
}
set menu::items(winUtils) {
    "insertPathNameÉ"
    "insertFileÉ"
}

set menu::items(Utils) {
    {Menu -n winUtils -p menu::fileUtils {}}
    {Menu -n asciiEtc {
	"quoteChar"
	"(-"
	"keyCodeÉ"
	"keyAsciiÉ"
	"getAscii"
	"insertAsciiÉ"}
    }
    "(-"
    "wordCount"
    "(- " 
    "sendUrl"
    "/jcmdDoubleClick"
}
set menu::proc(Utils) ""
lappend menu::which_subs(Utils) "winUtils"

# ×××× Config menu ×××× #

set menu::items(Config) {
    {Menu -n "globalSetup"  -p {prefs::dialogs::menuProc} {}} 
    {Menu -n "preferences"  -p {prefs::dialogs::menuProc} {}} 
    {Menu -n "Mode Prefs"   -p {prefs::dialogs::menuProc} {}} 
    {Menu -n "packages"     -p {menu::packagesProc} {}}
    "(-"
    "specialKeysÉ" 
    "/kdescribeBindingÉ"
    "listAllBindings" 
    "(- "
}
set menu::proc(Config) "menu::globalProc"
lappend menu::which_subs(Config) mode packages preferences globalSetup
menu::buildProc packages menu::packagesBuild
menu::buildProc mode menu::modeBuild
menu::buildProc globalSetup menu::setupBuild
menu::buildProc preferences menu::preferencesBuild

# ===========================================================================
# 
# ×××× File Menu Support ×××× #
# 

# "File" menu

proc menu::fileProc {menu item} {
    switch -- $item {
	"open" {
	    findFile
	}
	"close" {
	    killWindow
	}
	"revertToSaved" {
	    revert
	}
	default {
	    uplevel 1 [list menu::generalProc file $item]
	}
    }
    return
}

# "File > File Utils"

proc menu::fileUtils {menuName itemName} {
    switch -- $itemName {
	"insertPathName" {
	    insertText [getfile "Insert path to which file?"]
	}
	"fileRemove" {
	    file delete [getfile "Delete which file?"]
	}
	"fileInfo" {
	    if {$::alpha::macos && \
	      ([llength [info commands ::mac::fileInfo]] \
	      || [auto_load ::mac::fileInfo])} {
		# Call the 'Mac Menu' procedure.
		::mac::fileInfo
	    } else {
		set f [getfile "Get info for which file?"]
		foreach {a v} [file attributes $f] {
		    append res "[string range $a 1 end] : $v\n"
		}
		alertnote $res
	    }
	}
	"hexDump" {
	    set filename [getfile "Hex dump of which file?"]
	    new -n "* hexdump of [file tail $filename] *" \
	      -info [file::hexdump $filename]
	}
	"insertFile" {
	    insertText [file::readAll [getfile "Insert which file?"]]
	}
	default {
	    switch -- $menuName {
		"moreUtils" {namespace eval ::file::Utils:: $itemName}
		default     {namespace eval ::file $itemName}
	    }
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Config Menu Support ×××× #
# 

# "Config" main menu items

proc menu::globalProc {menu item} {
    menu::generalProc global $item
    return
}

# "Config > Global Setup"

proc menu::setupBuild {} {
    set ma [list "menusÉ" "/p<U<BfeaturesÉ" "listGlobalBindings" \
      "\(-" "/p<UfileMappingsÉ" "arrangeMenusÉ" \
      "\(-" "helperApplicationsÉ" \
      "\(-" "setupAssistantÉ" "createNewModeÉ"]
    return [list build $ma {prefs::dialogs::menuProc}]
}

# "Config > Packages"

proc menu::packagesBuild {} {
    global alpha::package_menus package::prefs
    lappend ma "describeAPackageÉ" "readHelpForAPackageÉ" "(-)" \
      "uninstallSomePackagesÉ" "installAPackageÉ" "\(-" \
      "listPackages" "rebuildPackageIndicesÉ"

    return [list build $ma menu::packagesProc]
}

proc menu::packagesProc {menu item} {
    global package::prefs alpha::prefs alpha::application
    if {[regexp "(.*)Prefs" $item d pkg]} {
	if {[lcontains package::prefs $pkg]} {
	    if {[info exists alpha::prefs($pkg)]} {
		prefs::dialogs::packagePrefs [set alpha::prefs($pkg)] \
		  "Preferences for the '[quote::Prettify $pkg]' package"
	    } else {
		prefs::dialogs::packagePrefs $pkg
	    }
	    return
	}
    }
    switch -- $item {
	"describeAPackage" -
	"Describe A Package" {
	    set pkg [dialog::optionMenu "Describe which package?" \
	      [lsort -dictionary [alpha::package names]]]
	    package::describe $pkg
	}
	"readHelpForAPackage" -
	"Read Help For A Package" {
	    set pkg [dialog::optionMenu "Read help for which package?" \
	      [lsort -dictionary [alpha::package names]]]
	    package::helpWindow $pkg
	}
	"uninstallSomePackages" -
	"Uninstall Some Packages" {
	    package::uninstall
	}
	"installAPackage" -
	"Install A Package" {
	    install::fromRemoteUrl [dialog::getUrl]
	}
	"rebuildPackageIndices" {
	    set title "Rebuild Package Indices?"
	    set q "${alpha::application} maintains a cache of AlphaTcl\
	      procedures that are only sourced on an as-needed basis,\
	      which makes the startup much quicker.  Occasionally these\
	      indices must be rebuilt if you have upgraded your AlphaTcl\
	      library, or if the cache has been corrupted for some reason.\
	      \rYou must quit ${alpha::application} immediately after\
	      rebuilding indices -- do you want to proceed?"
	    if {![dialog::yesno -y "Continue" -n "Cancel" -title $title $q]} {
		error "cancel"
	    }
	    alpha::rebuildPackageIndices
	    rebuildTclIndices
	    if {[askyesno "Do you want to quit ${alpha::application}?"]} {
		quit
	    } else {
		status::msg "You have been forewarned ..."
	    }
	}
	default {
	    menu::generalProc global $item
	}
    }
    return
}

# "Config > Preferences"

proc menu::preferencesBuild {} {
    set ma [list \
      [menu::itemWithIcon "Global Preferences" 84] \
      "(-" ]
    # Even if package::prefs is empty, there may be some
    # miscellaneous package preferences.
    lappend ma [menu::itemWithIcon "Package Preferences" 84]
    lappend ma "(-)" "View Saved SettingÉ" "Remove Saved SettingÉ" "Search For SettingÉ" \
      "(-" "Save Preferences Now" "Edit Prefs File" "Show Prefs Folder" \
      "Edit User Packages"
     return [list build $ma {prefs::dialogs::menuProc}]
}

# "Config > Mode Preferences"

proc menu::modeBuild {} {
    
    set ma [list "menusÉ" "/p<BfeaturesÉ" "/ppreferencesÉ" "editPrefsFile" \
      "loadPrefsFile" "describeMode" "listBindings" \
      "(-" "/m<UchangeModeÉ"]
    if {([set ModeName [win::getMode "" 1]] ne "")} {
	return [list build $ma prefs::dialogs::menuProc "" "$ModeName Mode Prefs"]
    } else {
	return [list build $ma prefs::dialogs::menuProc "" "Mode Prefs"]
    }
}

# ???  This doesn't appear to be used anywhere in AlphaTcl.

proc menu::menuPackages {menu m} {
    if {[package::helpOrDescribe $m]} {
	return
    }
    # toggle global existence of '$m' menu
    global global::menus
    if {[set idx [lsearch  ${global::menus} $m]] == -1} {
	lappend global::menus $m
	global $m
	catch $m
	insertMenu [set	$m]
	markMenuItem packageMenus $m 1
    } else {
	set global::menus [lreplace ${global::menus} $idx $idx]
	global $m
	catch "removeMenu [set $m]"
	markMenuItem packageMenus $m 0
    }
    prefs::modified global::menus
    return
}

# ===========================================================================
# 
# Menu Selection, Order
# 

namespace eval global {}

proc global::menuArrangement {args} {
    global global::features index::feature

    set globalMenus {}
    set menus [eval concat [lrange [package::partition global] 0 2]]
    foreach pkg [set global::features] {
	if {[lsearch -exact $menus $pkg] == -1} { continue }
	if {![alpha::isPackageInvisibleToUser $pkg]} {
	    lappend globalMenus $pkg
	}
    }
    # Make sure we don't have any duplicates for bizarre reasons
    set globalMenus [lunique $globalMenus]

    switch -- [llength $args] {
	0 {
	    return $globalMenus
	}
	1 {
	    set newOrder [lunique [lindex $args 0]]
	    if {$newOrder ne $globalMenus} {
		# Now if we didn't cancel, we remove them all from the list and
		# then add them in the new order at the end
		set global::features \
		  [lremove -all [set global::features] $newOrder]
		eval lappend global::features $newOrder
		# Now replace the menus in the correct order.
		status::msg "Re-ordering the menusÉ"
		foreach menuName $newOrder {
		    menu::moveToEnd $menuName
		}
		# Now shove any mode menus to the rear. 
		if {[alpha::frontmostAndActive]} {
		    set w [win::Current]
		    set origList [win::getFeatureModes $w]
		    set modeFeatures [lindex [package::onOrOff $origList ""] 0]
		    foreach mf $modeFeatures {
			if {[lsearch -exact $menus $mf] != -1} {
			    menu::moveToEnd $mf
			}
		    }
		}
		status::msg "The new order has been established."
	    }
	    return $newOrder
	}
	2 {
	    return -code error "Too many args."
	}
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Config Menu Windows ×××× #
# 

namespace eval global {}

proc global::listAllBindings {} {
    set allBindings [lsort -dictionary [split [bindingList] "\r"]]
    global::bindingsWindow "All Current Bindings" $allBindings
}

proc global::listGlobalBindings {} {
    set text ""
    set tmp [mode::listAll]
    foreach b [split [bindingList] "\r"] {
	set lst [lindex [split $b  " "] end]
	if {[lsearch -exact $tmp $lst] == -1} {
	    lappend text "$b"
	}
    }
    global::bindingsWindow "Current Global Bindings" $text
}

proc global::bindingsWindow {which bindings} {

    global tcl_platform

    set txt "\r${which}\r\r"
    append txt "\rThis window lists " [string tolower $which] ".\r"
    append txt {
These were all created using the command: Bind or the command: ascii in
various AlphaTcl source files, but does not include bindings created with
menu building codes.  You can create your own bindings in a "prefs.tcl" file
(or a <<tclShell>> window) using code that looks like

	Bind <char> [<modifier>] <script> [<mode>] 

as in

	Bind 't' <zc> {alertnote "Hello World!"} Text

Note that if the <script> contains spaces, it should be wrapped in {}.

The last [<mode>] argument is optional, and if it is not present the binding
will be available globally (i.e. in every mode).  Note that mode bindings
ALWAYS take precedence over global bindings, and that you can have both a
global and a mode-specific binding defined for any key combination.

In most cases, including a binding statement like this in a prefs file will
over-ride any menu bindings already created, although you might need to
manually 'source' the prefs file if the code creating the menu is sourced
after your binding statements.  To do this, open the prefs file and use the
"Tcl Menu > Evaluate" menu item (bound to Command-L !!).

Bindings created using 'Bind' will also over-ride any previous binding which
was created using 'Bind' for that exact key combination and mode.  You can
use the command: unBind, as in

	unBind 't' <zc> {alertnote "Hello World!"} Text

to remove the binding, but this will NOT restore the earlier binding.

See the "Keyboard Shortcuts" help file for more information.  Note that you
can highlight and then Command-Double-Click on any AlphaTcl procedure in this
window to find its definition within the AlphaTcl library's source files.

	-------------------------------------------------------------

Modifier key codes are:

  <c> = Command, <o> = Option <z> = Control, <s> = Shift

	-------------------------------------------------------------

Current Bindings:

}
    if {$tcl_platform(platform) == "windows"} {
	regsub -all {Command([^.:])} $txt "Alt\\1"  txt
	regsub -all {Option([^.:])}  $txt "Meta\\1" txt
    }
    set title "* $which *"
    if {[win::Exists $title]} {
	bringToFront $title
	killWindow
    } 
    if {![llength $bindings]} {
	set bindings [list "Could not identify any bindings."]
    } else {
	set bindings [lunique $bindings]
    }
    new -n $title -m Text -info "${txt}[join $bindings \r]\r\r"
    help::markColourAndHyper
}

## 
 # --------------------------------------------------------------------------
 # 
 # "global::listPackages" --
 # 
 # Creates the help file "Packages", saving it in the user's PREFS folder
 # (over-writing if necessary.)  The new window includes hyperlinks to any
 # available package help.
 # 
 # Earlier versions created this in the "$HOME/Help" folder, but the current
 # user might not have write-access to do so.  Keeping it in the user's PREFS
 # folder also allows the information to be specific to the current user's
 # configuration, including active status of packages and the presence of any
 # user-added packages.
 # 
 # In Alphatk, if "closeAfterCreation" is "1" we create the new window
 # outside of the parameters of the user's screen to avoid flashing a newly
 # created but then quickly killed window.  This doesn't work in Alpha8/X
 # (c.f. bug 721), and this also creates even weirder flashing when the file
 # is opened later since the original window parameters are remembered along
 # with all of the package hyperlinks.
 #  
 # --------------------------------------------------------------------------
 ##

proc global::listPackages {{closeAfterCreation "0"}} {
    
    global HOME PREFS index::feature timeStampStyle \
      alpha::packageRequirementsFailed alpha::platform alpha::packagesAlwaysOn \
      alpha::application
    
    # Is the older "$HOME/Help/Package" file still present?  If so, try to
    # delete it.  We go to some trouble to deal with <2> decorations.
    set f [file join $HOME Help Packages]
    foreach w [file::hasOpenWindows $f] {
	killWindow -w $w
    }
    if {[file exists $f]} {catch {file delete -force $f}}
    # Is the current window "Packages" ?  If so, close it, so that it can be
    # over-written.  We go to some trouble to deal with <2> decorations.  The
    # local variable "$f" will be the location used later to save the file.
    set f [file join $PREFS Packages]
    foreach w [file::hasOpenWindows $f] {
	killWindow -w $w
    } 
    watchCursor
    status::msg "Please wait: Creating the\
      \"Help > Installed Packages\" help file."
    # Assemble a bunch of cache information.
    cache::readContents index::maintainer
    cache::readContents index::description
    foreach i [array names maintainer] {
	set j [lindex [set maintainer($i)] 1]
	if {[llength $j]} {set au($i) [join [lrange $j 0 1] ", "]}
    }
    unset -nocomplain maintainer
    foreach p [lsort -dictionary [array names index::feature]] {
	if {[info exists index::description($p)]} {
	    set desc [lindex [set index::description($p)] 1]
	    set desc "[string trimright [string trim $desc] .]."
	} else {
	    set desc "(No description available.)"
	}
	regsub -all -- {\s+} $desc { } desc
	regsub -all -- {ÇALPHAÈ} $desc ${alpha::application} desc
	set desc [breakIntoLines $desc 77 4]
	set v [alpha::package versions $p]
	if {[lindex $v 0] == "for"} {
	    set v "for [lindex $v 1] [lindex $v 2]"
	}
	if {[lcontains alpha::packageRequirementsFailed $p]} {
	    # Incompatible packages (tBad)
	    append tBad "\r[format {  %-30s %-10s } \
	      [concat package: $p] $v]"
	    if {[info exists au($p)]} { append tBad $au($p) }
	    set requires [lindex [alpha::package requirements $p] 1]
	    catch {uplevel \#0 $requires} res
	    append tBad "\r     $res"
	    continue
	} elseif {[lcontains alpha::packagesAlwaysOn $p]} {
	    # Always on packages (tFAO)
	    append tFAO "\r[format {%s %-30s %-10s } \
	      ¥ [concat package: $p] $v]"
	    if {[info exists au($p)]} {
		append tFAO $au($p)
	    }
	    append tFAO "\r\r" $desc "\r"
	    continue
	}
	switch -- [lindex [set index::feature($p)] 2] {
	    "1" {
		# Menus
		if {[lindex [alpha::package versions $p] 0] != "for"} {
		    # Usual Menus (tM1)
		    append tM1 "\r[format {  %-30s %-10s } \
		      [concat package: $p] $v]"
		    if {[info exists au($p)]} { append tM1 $au($p) }
		    append tM1 "\r\r" $desc "\r"
		} else {
		    # Other possible packages (tM2)
		    append tM2 "\r[format {  %-30s %-10s } \
		      [concat package: $p] $v]"
		    if {[info exists au($p)]} { append tM2 $au($p) }
		}
	    }
	    "0" {
		# Features enabled through "Preferences > Features"
		set forWhat [lindex [lindex [set index::feature($p)] 1] 0]
		if {[regexp -- {^global(\-only)?$} $forWhat]} {
		    # Global features (tF1)
		    append tF1 "\r[format {%s %-30s %-10s } \
		      [package::active $p {¥ { }}] [concat package: $p] $v]"
		    if {[info exists au($p)]} { append tF1 $au($p) }
		    append tF1 "\r\r" $desc "\r"
		} else {
		    # Mode specific features (tFM)
		    append tFM "\r[format {%s %-30s %-10s } \
		      [package::active $p {¥ { }}] [concat package: $p] $v]"
		    if {[info exists au($p)]} { append tFM $au($p) }
		    append tFM "\r\r" $desc "\r"
		}
	    }
	    "2" {
		# Features (tF2), enabled as flag preferences
		append tF2 "\r[format {%s %-42s %-10s } \
		  [package::active $p {¥ { }}] [concat package: $p] $v]"
		if {[info exists au($p)]} { append tF2 $au($p) }
		append tF2 "\r\r" $desc "\r"
	    }
	    "-1" {
		# Auto-loading features (tFAL)
		append tFAL "\r[format {  %-30s %-10s  } \
		  [concat package: $p] $v]"
		if {[info exists au($p)]} { append tFAL $au($p) }
		append tFAL "\r\r" $desc "\r"
	    }
	}
    }
    # Modes (tModes)
    foreach p [lsort -dictionary [alpha::package names -mode]] {
	if {[info exists index::description($p)]} {
	    set desc [lindex [set index::description($p)] 1]
	    set desc "[string trimright [string trim $desc] .]."
	} else {
	    set desc "(No description available.)"
	}
	regsub -all -- {\s+} $desc { } desc
	regsub -all -- {ÇALPHAÈ} $desc ${alpha::application} desc
	set desc [breakIntoLines $desc 77 4]
	# Put version numbers back
	set v [alpha::package versions $p]
	# Need an extra check for Modes since they weren't covered above.
	if {[lcontains alpha::packageRequirementsFailed $p]} {
	    append tBad "\r[format {  %-30s %-10s } \
	      [concat package: $p] $v]"
	    if {[info exists au($p)]} { append tBad $au($p) }
	    set requires [lindex [alpha::package requirements $p] 1]
	    catch {uplevel \#0 $requires} res
	    append tBad "\r     $res"
	    continue
	}
	append tModes "\r[format {  %-16s %-8s  } [concat package: $p] $v]"
	if {[info exists au($p)]} {append tModes $au($p)}
	append tModes "\r\r" $desc "\r"
    }
    # Completion tutorials (tCT)
    set tutFiles [glob -nocomplain -dir [file join $HOME Tcl Completions] *Tutorial*]
    foreach tutFile $tutFiles {
	append tCT "\r    \"[file tail $tutFile]\""
    }
    # Make sure that we have something for each category.
    foreach item [list FAO Bad M1 M2 F1 FM F2 FAL Modes CT] {
	if {![info exists t$item]} {
	    set t$item "\r  (None)\r\r"
	} else {
	    append t$item \r\r
	}
    }
    # =====================================================================
    #
    # Create the text that will be included in the new file.
    # Start with title, intro, table of contents.
    # 
    set divider "\t[string repeat - 64]\r\r"
    set created [mtime [now] $timeStampStyle]
    # --------------------------------------------------------------------
    #
    # Title
    # 
    append t "\rCurrently Installed Packages\r\r"
    append t "as of ${created}, "
    append t "$alpha::application [alpha::package versions Alpha], "
    append t "AlphaTcl version [alpha::package versions AlphaTcl]\r"
    # --------------------------------------------------------------------
    #
    # Introduction
    # 
    append t {
This window contains hyperlinks to help files for all of the packages
installed in your AlphaTcl library as of the date listed above.  'Packages'
include modes, menus, and other features that add functionality to ÇALPHAÈ.

'Modes' are always available, although the bulk of the Tcl code which defines
them is only 'sourced' on an as-needed basis.  Other packages are features
which are only loaded when called upon to do so.  Most of the packages listed
here can be 'uninstalled' but in general this will only save disk space, and
will not improve ÇALPHAÈ's speed or performance.  Additional help files that
might be of interest include:

    "Alpha Manual" "Quick Start" "Readme"

To update this file, use the "Config > Packages > List Packages" menu item.

(Or you can click here: <<global::listPackages>>)

}
    append t $divider
    # --------------------------------------------------------------------
    #
    # Table Of Contents
    # 
    append t "\t  \tTable Of Contents\r"
    append t {
"# Modes"
"#   Completion Tutorials"
"# Menus"
"#   Usual Menus"
"#   Other Possible Menus"
"# Features"
"#   Global Features"
"#   Mode Specific Features"
"#   'Flag' Features"
"#   'Always On' Features"
"#   Auto-loading Features"
"#   Incompatible Packages"
"# Environment"

<<floatNamedMarks>>

Columns in this window include: <package name> <version> and <maintainer>

}
    append t $divider
    # --------------------------------------------------------------------
    #
    # Modes
    # 
    append t "\t  \tModes\r"
    append t {
The mode of an open window is usually determined by the "file mappings"
defined by each mode in AlphaTcl.

<<prefs::dialogs::fileMappings>>

Each mode listed below has a specific set of "# Menus" and/or "# Features"
associated with it; select the appropriate "Config > Mode Prefs" menu
commands to change them.

You can always obtain help for the mode of the current window by pressing
Control-Help.  The "Config > Mode Prefs > Describe Mode" menu item will open a
new window with information about preferences, bindings, etc.

See also the "Examples Help" file for example syntax files, and fuller
explanations of the editing environments for which the modes are useful.

}
    append t $tModes
    #     Mode Specific Completion Tutorials
    append t "\t  \t \tCompletion Tutorials\r"
    append t {
Many modes include a mode specific 'Completions Tutorial' that demonstrates
the package: elecCompletions and/or package: elecExpansions features. 

The "Config > Mode Prefs > Completions Tutorial" menu item will also open
these tutorials for the mode of the current window.

}
    append t $tCT
    append t $divider
    # --------------------------------------------------------------------
    #
    # Menus
    # 
    append t "\t  \tMenus\r"
    append t {
Menus can be activated globally, using the "Config > Global Setup" dialogs,
or use the "Config > Mode Prefs" menu for specific modes.

Preferences: Menus
Preferences: Mode-Menus

}
    #     Usual Menus
    append t "\t  \t \tUsual Menus\r\r"
    append t "\"Usual menus\" are designed to be used globally.\r"
    append t $tM1
    #     Other Possible Menus
    append t "\t  \t \tOther Possible Menus\r\r"
    append t "\"Other possible menus\" are usually designed\
      for specific modes.\r"
    append t $tM2
    append t $divider
    # --------------------------------------------------------------------
    #
    # Features
    # 
    append t "\t  \tFeatures\r\r"
    append t "'¥' = globally active as of $created\r"
    append t {
Features can be activated globally using "Config > Global Setup" dialogs,
or use the "Config > Mode Prefs" menu for specific modes.  Some modes might
also activate some of these features by default.

Preferences: Features
Preferences: Mode-Features

}
    #     Enabled via "Config > Global Setup > Features"
    append t "\t  \t \tGlobal Features\r"
    append t {
These features are enabled globally through "Config > Global Setup > Features"

}
    append t $tF1
    #     Mode Specific Features
    append t "\t  \t \tMode Specific Features\r"
    append t {
These features are intended for use by specific modes, although they can be
turned on globally if desired.  Some modes might activate these features by
default.  Use the "Config > Mode Prefs > Features" dialog to turn these
items on and off for individual modes.

Preferences: Mode-Features
}
    append t $tFM
    #     Enabled as flag preferences
    append t "\t  \t \t'Flag' Features\r"
    append t {
These features are enabled globally through the "Config > Preferences" menu,
using the "Interface" or "Input-Output" Preferences dialogs.  Some modes
might also activate some of these features by default.

Preferences: InterfacePreferences
Preferences: Input-OutputPreferences

}
    append t $tF2
    #     'Always On' Features
    append t "\t  \t \t'Always On' Features\r"
    append t {
These features are always turned on.  Most are essential to the proper
operation of AlphaTcl, and should never be turned off or uninstalled.

}
    append t $tFAO
    #     Auto-loading Features
    append t "\t  \t \tAuto-loading Features\r"
    append t {
These packages only add additional code that can be used elsewhere in AlphaTcl,
and cannot be turned on or off.

}
    append t $tFAL
    #     Incompatible packages
    append t "\t  \t \tIncompatible Packages\r\r"
    append t $tBad
    append t $divider
    # --------------------------------------------------------------------
    #
    # Environment
    # 
    append t "\t  \tEnvironment\r"
    append t "[global::listEnvironment]\r\r"    
    # =====================================================================
    #
    # Create a new file, insert all information
    # 
    regsub -all -- {ÇALPHAÈ} $t ${alpha::application} t
    if {(${alpha::platform} eq "tk") && $closeAfterCreation} {
	if {[catch {
	    file::writeAll $f $t 1
	} err]} {
	    status::msg "Couldn't overwrite Packages list:\
	      it may not be up to date"
	}
	return
    } else {
	set w [new -n {Packages} -m Text -text $t -tabsize 4 -state mpw]
    }
    goto [minPos -w $w]
    # Hyperize, color and mark file
    help::markColourAndHyper
    # Remove the strings "package: " if we can save the hyperlinks in the
    # file's resource fork.
    if {(${alpha::platform} eq "alpha")} {
	# [help::markColourAndHyper] made this window read-only.
	setWinInfo -w $w read-only 0
	set pos [minPos -w $w]
	while {[llength [set range [search -w $w -s -n "package: " $pos]]]} {
	    set pos [lindex $range 1]
	    replaceText -w $w [lindex $range 0] $pos ""
	}
    }
    # Overwrite any existing "Packages" file in the PREFS directory, but don't
    # save a backup copy anywhere.
    global backup
    set oldBackup $backup
    set backup 0
    if {[catch {saveAs -f $f} err]} {
	alertnote "Couldn't overwrite Packages list:\
	  it may not be up to date"
    }
    # Have to update the window name, since we've just saved it.
    set w [win::Current]
    
    set backup $oldBackup
    goto -w $w [minPos -w $w]
    if {$closeAfterCreation} {
	killWindow -w $w
    } else {
	winReadOnly $w
    }
}

proc global::listEnvironment {} {
    global alpha::internalEncoding tcl_platform alpha::windowingsystem
    append t "\r[format {  %-30s %-10s  }\
      Tcl-version [info patchlevel]]"
    append t "\r[format {  %-30s %-10s  }\
      "Windowing system" ${alpha::windowingsystem}]"
    append t "\r[format {  %-30s %-10s  }\
      "system encoding" [encoding system]]"
    append t "\r[format {  %-30s %-10s  }\
      "AlphaTcl encoding" ${alpha::internalEncoding}]"
    append t "\r"

    foreach pkg [lsort -dictionary [package names]] {
	if {![catch {package present $pkg} v]} {
	    append t \r[format {  %-30s %-10s  } $pkg "$v"]
	}
    }
    append t "\r\r"
    append t "  Binary extensions loaded: "
    set pkgNames {}
    foreach pkg [info loaded] {
	lappend pkgNames [lindex $pkg 1]
    }
    append t [join $pkgNames ", "]
    return $t
}

proc global::listFunctions {} {
    set t {
# Currently Defined Procedures
# 
# Command-double-click on any procedure name to see its definition.
}
    append t "\r[join [lsort -dictionary [procs::buildList]] \r]\r"
    new -n {* Functions *} -m Tcl -info $t
}

# ===========================================================================
# 
# .