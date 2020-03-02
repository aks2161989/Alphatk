## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "alphaDistribution.tcl"
 #                                          created: 06/27/2003 {02:16:38 PM}
 #                                      last update: 05/25/2006 {12:11:32 PM}
 # Description:
 # 
 # Provides an 'Alpha Distribution' submenu for the AlphaDev menu.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #    
 # Copyright (c) 1997-2006  Vince Darley
 # Distributed under a Tcl style license.
 # 
 # Based on original 'developerUtilities.tcl', which is now obsolete.
 # 
 # ==========================================================================
 ##

proc alphaDistribution.tcl {} {}

namespace eval alphadev::dist {
    
    variable log ""
    variable hooksRegistered 0
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Distribution Preferences ×××× #
# 

# Where does dropStuff put its stuffed items.
newPref var     dropStuffFolder "" Inst
# Default internet location to which we upload stuffed, binhexed packages.
newPref var     defaultAlphaUploadSite "" Inst "" alpha::downloadSite array
# Disk location of first separate Alpha distribution (alpha-lite).
newPref folder  separateAlpha1DistributionFolder "" Inst
# Disk location of second separate Alpha distribution (full version).
newPref folder  separateAlpha2DistributionFolder "" Inst
# Disk location of third separate Alpha distribution (experimental distribution).
newPref folder  separateAlpha3DistributionFolder "" Inst

# ===========================================================================
# 
# ×××× Alpha Distribution Menu ×××× #
# 

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::dist::buildMenu" --
 # 
 # Create the menu of items available, called when the AlphaDev menu is
 # first built and whenever the user edits the web sites to be included.
 # 
 # "alphadev::dist::postBuildMenu" --
 # 
 # Dim 'editing' options as appropriate.  This is called by AlphaTcl after
 # the menu has been built (using [menu::buildSome]).
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::dist::buildMenu {} {
    
    variable hooksRegistered
    
    # Create submenu lists.
    set menuList [list \
      changeInstallerIcon \
      (-) \
      compareWithDistribution \
      copyFileToDistributionÉ \
      ensureDistributionIsUpToDate \
      stuffPackageForDistribution \
      uploadStuffedPackage \
      updateStuffAndUpload \
      (-) \
      convertHelpFileÉ \
      generatePre-builtCacheÉ\
      rememberDistributionTimeTag \
      makeDistributionUpdaterÉ \
      makeCompleteDistributionÉ \
      (-) \
      ensureAlphaDistn1UpToDate \
      ensureAlphaDistn2UpToDate \
      ensureAlphaDistn3UpToDate \
      (-) \
      updateBugzillaProductVersionÉ \
      alphaDistributionPrefsÉ \
      alphaDistributionHelp \
      ]
    if {!$hooksRegistered} {
	set dimItems [list \
	  changeInstallerIcon compareWithDistribution copyFileToDistributionÉ \
	  ensureDistributionIsUpToDate]
	foreach item $dimItems {
	    if {$item != "(-)"} {
		hook::register requireOpenWindowsHook \
		  [list "Alpha Distribution" $item] 1
	    } 
	}
	set hooksRegistered 1
    } 
    return [list build $menuList {alphadev::dist::menuProc}]
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::dist::menuProc" --
 # 
 # Execute the menu items, redirecting as necessary.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::dist::menuProc {menuName itemName} {
    
    global alphadev InstmodeVars
    
    switch -- $itemName {
	"changeInstallerIcon" {
	    setFileInfo [win::StripCount [win::Current]] type InSt
	    status::msg "Icon changed."
	}
	"updateStuffAndUpload" {
	    ensureDistributionIsUpToDate
	    stuffPackageForDistribution 1
	    uploadStuffedPackage 0
	    alertnote "Distribution upload complete."
	}
	"rememberDistributionTimeTag" {
	    cache::create distributionTimeTag
	    set alphadev(timetag) [now]
	    prefs::modified alphadev(timetag)
            status::msg "Distribution time tag set to [mtime [now]]"
	}
	"ensureAlphaDistn1UpToDate" {
	    ensureAlphaDistnUpToDate \
	      $InstmodeVars(separateAlpha1DistributionFolder)
	}
	"ensureAlphaDistn2UpToDate" {
	    ensureAlphaDistnUpToDate \
	      $InstmodeVars(separateAlpha2DistributionFolder)
	}
	"ensureAlphaDistn3UpToDate" {
	    ensureAlphaDistnUpToDate \
	      $InstmodeVars(separateAlpha3DistributionFolder)
	}
	"updateBugzillaProductVersion" {
	    bugzilla::menuProc $menuName $itemName
	}
	"alphaDistributionPrefs" {
	    help::openPrefsDialog "Mode-Inst"
	}
	"alphaDistributionHelp" {
	    helpWindow
	}
	default {
	    menu::generalProc alphadev::dist $itemName
	}
    }
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::dist::helpWindow" --
 # 
 # Open a new window with information about this submenu.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::dist::helpWindow {} {
    
    set title "Alpha Distribution Help"
    if {[win::Exists $title]} {
	bringToFront $title
	return
    }

    set txt {
Alpha Distribution Help

The "AlphaDev --> Alpha Distribution" submenu provides support for creating
Alpha distributions for private/public releases.

The preferences: Mode-Inst dialog includes all additional 'distribution'
preferences created and used by this package.

(Additional help/explanations for this package would go here ...  In the
meantime, see the "alphaDistribution.tcl" source file.)
}
    
    new -n $title -tabsize 4 -info $txt
    help::markColourAndHyper
    return
}

# ===========================================================================
# 
# ×××× --------- ×××× #
# 
# ×××× Distribution Items ×××× #
# 

proc alphadev::dist::log {logItem} {
    variable log
    append log "${logItem}\r"
}

proc alphadev::dist::copyFileToDistribution {} {

    global HOME ALPHATK
    
    set f [win::Current]
    switch -- [file dirname $f] {
	$HOME                                         {set toDir "Home"} 
	$ALPHATK                                      {set toDir "AlphatkCore"} 
	[file join $HOME Help]                        {set toDir "Help"}
	[file join $HOME QuickStart]                  {set toDir "QuickStart"}
	[file join $HOME Tests]                       {set toDir "Tests"}
	[file join $HOME Tools]                       {set toDir "Tools"}
	[file join $HOME Tcl Completions]             {set toDir "Completions"}
	[file join $HOME Tcl Menus]                   {set toDir "Menus"}
	[file join $HOME Tcl Modes]                   {set toDir "Modes"}
	[file join $HOME Tcl Packages]                {set toDir "Packages"}
	[file join $HOME Tcl SystemCode]              {set toDir "SystemCode"}
	[file join $HOME Tcl UserModifications]       {set toDir "UserModifications"}
	[file join $HOME Tcl SystemCode CorePackages] {set toDir "CorePackages"}
	default {
	    alertnote "$f does not appear to be part of the current Tcl distribution"
	    return
	}
    }
    set distdir [get_directory -p "Select distribution directory"]
    set toFile  [file join $distdir $toDir [file tail $f]]
    
    if {[file exists $toFile]} {
	file::replaceSecondIfOlder $f $toFile
    } else {
	catch {file mkdir [file join $distdir $toDir]}
	file copy $f $toFile
	status::msg "Added [file tail $f] to $toDir"
    }
    return
}

proc alphadev::dist::compareWithDistribution {} {

    global auto_path HOME

    if {![string length [set w [win::StripCount [win::Current]]]]} {
	error "Cancelled -- no window is open!"
    }
    
    set wn [file tail $w]
    foreach dir [concat $auto_path [list [file join $HOME Tools]]] {
	set f [file join ${dir} ${wn}]
	if {[file exists $f]} {
	    if {$f eq $w} { 
		alertnote "It's part of the distribution!"
		return 
	    }
	    file::openQuietly $f
	    compare::windows
	    return
	}
    }
    alertnote "No distribution file with this name was found."
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alphadev::dist::ensureDistributionIsUpToDate" --
 # 
 #  Helpful for package developers.  You can keep your current versions in
 #  the Alpha source tree, but use this procedure periodically to backup the
 #  code, and prepare for distribution.  All files in the distribution
 #  hierarchy (up to one level deep) are replaced if a more recent version
 #  can be found anywhere in the Alpha source tree.  You are told which were
 #  replaced, and which couldn't be found.
 #  
 #  The only exception is that if there is a file whose name matches
 #  *install*.tcl in the top level of your distribution, it is ignored.  It
 #  is assumed that such a file contains installation scripts for your
 #  package, and that it will not be installed itself.
 #  
 #  Doesn't cope with recursive directories.
 # -------------------------------------------------------------------------
 ##

proc alphadev::dist::ensureDistributionIsUpToDate {} {

    watchCursor

    global HOME 

    set curr [win::Current]
    if {[file extension $curr] == ".tcl"} {
	# single file to install
	set distribfiles [list $curr]
    } else {
	set currD [file dirname $curr]
	set distribfiles [glob -types TEXT -nocomplain -dir $currD *]
	set distribfiles [lremove -glob $distribfiles "*\[iI\]nstall*.tcl"]
	set distribfiles [lremove $distribfiles [list [win::Current]]]
	eval lappend distribfiles [glob -nocomplain -join -dir $currD * *]
    }	
    set failed ""
    set replaced ""
    foreach ff $distribfiles {
	if {[file isdirectory $ff]} {
	    lappend failed $ff
	    continue
	}
	set looking 1
	set f [file tail $ff]
	if {[catch {file::standardFind $f} to]} {
	    lappend failed $f
	} else {
	    if {[file::replaceSecondIfOlder $to $ff]} {
		lappend replaced $f
	    }
	}
    }
    if {$failed == ""} {set failed "none"}
    if {$replaced == ""} {set replaced "none"}
    if {[catch {alertnote "Replaced $replaced, failed to find $failed."}]} {
	alertnote "Replaced [llength $replaced], failed to find $failed."
    }
    return
}

proc alphadev::dist::getChangesSince {time} {
    
    global HOME

    set fin [alphaOpen [file join $HOME Help "Changes - AlphaTcl"] r]
    gets $fin ; gets $fin ; gets $fin

    while {![eof $fin]} {
	gets $fin line
	if {[string index $line 0] == "="} {break}
    }

    set changes ""
    
    if {[catch {
	while {![eof $fin]} {
	    gets $fin line
	    if {[string index $line 0] == "="} {
		if {[string index $line 1] == "="} {
		    continue
		}
		if {[regexp {^=.([^ ]*)(.*)last update:(.*)} $line "" v "" line]} {
		    # We have to get rid of the {} before calling clock scan.
		    set line [eval [list concat] [string trim $line]]
		    regsub "(am|pm|AM|PM)" $line "" line
		    set lt [clock scan $line]
		    if {$lt < $time} {
			#puts "$line older than $time"
			break
		    }
		    append changes "\r" $v "\n"
		} else {
		    break
		}
	    } else {
		append changes $line "\n"
	    }
	}
    } err]} {
	alertnote "There was an error while listing changes: $err"
    }
    close $fin
    return $changes
}

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::dist::convertHelpFile" --
 # 
 # Contributed by Craig Barton Upright.
 # 
 # Convert the "Readme" or "Release Notes - Alpha(tk)" or any chosen file to
 # 
 # (1) a basic Text file, so that it can be opened in any installed
 # editor (such as SimpleText / Text Editor / NotePad / WordPad), or
 # 
 # (2) a simple html file for reading in a local browser, or
 # 
 # (3) a html file with the "Help Browser" creator type.
 # 
 # All forms will use Setext style section markers, without any distracting
 # formatting or hyperlink markers that wouldn't make sense outside of Alpha.
 # The converted file should then be included with the distribution to be
 # archived, stored in a highly visible location, so that the user can read
 # about what's new in a non-Alpha application before attempting (or being
 # required) to install anything.
 # 
 # You will be prompted for a location to save the converted file, since we
 # obviously don't want to include this in the standard AlphaTcl hierarchy.
 # Following the conversion, the file will be launched using whatever the OS
 # Finder thinks is an appropriate helper.  This is a good check.
 # 
 # If you are creating a ".txt" file in any Mac OS, following the conversion
 # you should explicitly change the text to use a fixed-width font, and then
 # save the file to ensure that the changes are now in its resource fork.
 # You can also change the file's "type" to 'ttro' later for a fancier icon.
 # (We don't set the type here because that is supposed to make the file
 # read-only, and we might need to inspect it and make further changes.)
 # 
 # Line endings are converted to "mac" (i.e. "\r") if we're in the Mac OS,
 # since OS X apps can read them but MacClassic SimpleText isn't smart
 # enough to convert "\n".  When converting a help file for the Alpha8
 # distribution please ensure that it has proper "mac" line endings before
 # creating the final archive.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::dist::convertHelpFile {} {
    
    global alpha::platform alpha::macos alpha::application HOME
    
    variable lastHelpFile
    variable lastHelpSuffix
    
    set options [list "Readme" "Release Notes - Alpha" "Release Notes - Alphatk" \
      "Choose fileÉ"]
    # Make sure that we have a (f)ile to convert, if so grab the (t)ext.
    if {[info exists lastHelpFile] && [lcontain $options $lastHelpFile]} {
        set option $lastHelpFile
    } elseif {(${alpha::platform} eq "alpha")} {
	set option "Release Notes - Alpha"
    } else {
	set option "Release Notes - Alphatk"
    }
    set suffixes [list ".txt" ".html"]
    if {$alpha::macos} {
        lappend suffixes [list ".help"]
    }
    if {[info exists lastHelpSuffix] && [lcontain $suffixes $lastHelpSuffix]} {
        set suffix $lastHelpSuffix
    } else {
        set suffix ".txt"
    }
    set dialogScript [list dialog::make -title "Convert Help File" \
      -width 400 \
      -ok "Continue" \
      -okhelptag "Click here to convert the selected file." \
      -cancelhelptag "Click here to cancel the conversion operation." \
      [list "" \
      [list "text" "Pre-existing help files should be converted for\
      archived $alpha::application distributions.\r"] \
      [list "text" "This converted help file should then be placed inside the\
      archive in a highly visible location so that it can be viewed by one\
      of the user's OS applications before installing the application.\r"] \
      [list [list "menu" $options] "Help file:" $option] \
      [list [list "menu" $suffixes] "New format:" $suffix] \
      ]]
    set results  [eval $dialogScript]
    set lastHelpFile [set fileName [lindex $results 0]]
    set lastHelpSuffix [set suffix [lindex $results 1]]
    if {($fileName eq "Choose fileÉ")} {
        set filePath [getfile "Choose a file to convert" [file join $HOME Help]]
	set fileName [file tail $filePath]
    } else {
	set filePath [file join $HOME Help $fileName]
    }
    if {![file exists $filePath]} {
	alertnote "\"${filePath}\" doesn't exist!"
	return
    }
    # Find a target (d)irectory for the new "newPath" file to be created.
    set dir [get_directory -p "Save the converted \"${fileName}\" file inÉ"]
    set newPath [file join $dir ${fileName}${suffix}]
    if {[file exists $newPath]} {
	file delete -force $newPath
    } 
    # Now we convert the file.
    set txt [file::readAll $filePath]
    # Trim section (m)arks, surrounding them with (r)epeating "-|=" strings.
    set pat {\n(\t  \t([^\s][^\n]+)\n)}
    while {[regexp -indices $pat $txt -> line markPositions]} {
	set mark [string trim [eval [list string range $txt] $markPositions]]
	set dvdr [string repeat "=" [string length $mark]]
	set mark "${dvdr}\n${mark}\n${dvdr}\n"
	set txt  [eval [list string replace $txt] $line [list $mark]]
    }
    set pat {\n(\t  \t([^\n]+)\n)}
    while {[regexp -indices $pat $txt -> line markPositions]} {
	set mark [string trim [eval [list string range $txt] $markPositions]]
	set dvdr [string repeat "-" [string length $mark]]
	set mark "${dvdr}\n${mark}\n${dvdr}\n"
	set txt  [eval [list string replace $txt] $line [list $mark]]
    }
    # Clean up "package: " hyperlink strings that appear in column 4.
    set pat {\n    (package: )([^\s]+)}
    regsub -all -- $pat $txt "\n    \\2" txt
    # Clean up "Preferences: " hyperlink strings that appear in column 0.
    set pat {\nPreferences: [^\s]+\n}
    while {[regexp -- $pat $txt]} {
	regsub -all -- $pat $txt "\n\n" txt
    }
    # Miscellaneous cleanup.
    regsub -all -- {<<floatNamedMarks>>} $txt "" txt
    regsub -all -- {(<<|>>)} $txt "\"" txt
    regsub -all -- {"# ([^\n]+)"} $txt "\\1" txt
    regsub -all -- {\n+\t(-|=)+\n+} $txt "\n\n" txt
    regsub -all -- {\n\n\n+} $txt "\n\n" txt
    regsub -all -- {\t} $txt "    " txt
    # Options for file suffix setting.
    switch -- $suffix {
        ".html" - ".help" {
	    if {$suffix eq ".html"} {
	        set creator [expr {($alpha::macos == 2) ? "sfri" : "MOSS"}]
	    } else {
		set creator "hbwr"
	    }
	    # Convert some common high bit characters.
	    regsub -all -- {¥} $txt {\&#149;} txt
	    regsub -all -- {É} $txt {\&#8230;} txt
	    regsub -all -- {©} $txt {\&copy;} txt
	    # Add mark-up tags for all urls.
	    regsub -all -- {\n *<([a-zA-Z]+://[^<>]+)>} $txt \
	      "\n<A HREF=\"\\1\">\\1</A>" txt
	    # Make sure this is recognized as html.
	    set txt "<HTML>\n<PRE>\n${txt}\n\n</PRE>\n</HTML>\n"
        }
        ".txt" {
	    set creator "ttxt"
        }
	default {
	    set creator [expr {($alpha::platform eq "alpha") ? "ALFA" : "AlTk"}]
	}
    }
    # Save the new file.
    file::writeAll $newPath $txt
    if {$alpha::macos} {
	catch {setFileInfo $newPath creator $creator}
	catch {setFileInfo $newPath type    "TEXT"}
    } 
    if {($alpha::macos == 1)} {
	file::convertLineEndings $newPath "mac"
    }
    file::showInFinder  $newPath
    file::openInDefault $newPath
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "alphadev::dist::generatePre-builtCache" --
 # 
 # Create the pre-built $HOME/Cache/ folder for public distributions.  The
 # package "smarterSource" needs to be turned off to ensure that the cache
 # is properly built, and if there is a "$PREFS/User Packages" folder
 # present that should be temporarily removed.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::dist::generatePre-builtCache {} {
    
    global HOME PREFS alpha::application alpha::cache
    
    # Preliminaries.
    set q "Do you want to create the pre-built \"Cache\" folder\
      for distribution with ${alpha::application}?  It will be\
      located in\r\r[file join $HOME Cache]"
    if {![askyesno $q]} {
        status::msg "Cancelled."
	return
    }
    if {[file exists [file join $PREFS "User Packages"]]} {
	alertnote "Your \"Preferences\" contains a \"User Packages\" folder\
	  that should be removed prior to building the cache for the public\
	  distribution.  Please put it somewhere else temporarily and then call\
	  this menu item again.\r\r(Remember to put it back when you're done!)"
	file::showInFinder [file join $PREFS "User Packages"]
        return
    }
    # Make sure "Smarter Source" is turned off, then build the Cache.
    watchCursor
    if {[package::active "smarterSource"]} {
	alertnote "The package \"Smarter Source\" has been temporarily\
	  turned off.  It will be turned back on automatically once the\
	  new Cache folder has been created."
        set reactivateSmarterSource 1
	package::deactivate "smarterSource"
    } 
    if {[info exists alpha::cache]} {
        set oldCache ${alpha::cache}
    } 
    set alpha::cache [file join $HOME Cache]
    alpha::makeIndices
    # Cleanup.
    if {[info exists oldCache]} {
        set alpha::cache $oldCache
    } else {
        unset -nocomplain alpha::cache
    }
    if {[info exists reactivateSmarterSource]} {
	package::activate "smarterSource"
    }
    set q "The new \"Cache\" folder has been created.  Do you want to\
      display its location in the Finder?"
    if {[askyesno $q]} {
        file::showInFinder [file join $HOME Cache]
    } 
    return
}

ensureset alphadev(title)      "AlphaTcl updater"
ensureset alphadev(dir)        ""
ensureset alphadev(requires)   "AlphaTcl 8.0b7 Alpha 8.3fc3"
ensureset alphadev(provides)   "Alpha 8.3fc5"
ensureset alphadev(longmsg)    ""
ensureset alphadev(remove)     ""
ensureset alphadev(extraprocs) ""
ensureset alphadev(ignore) \
  "^(\\.#.*|CVS|CVSROOT|Developer|Frontier verbs|.*TAGS)\$"

# Would be nice to add ability to remove files or directories as well. 
# (Could use a 'search path' dialog item which allows files).

proc alphadev::dist::makeDistributionUpdater {} {

    if {![cache::exists distributionTimeTag]} {
	error "Cancelled -- you must create a distribution time tag"
    }
    set timetag [cache::name distributionTimeTag]
    set time [file mtime $timetag]

    global alphadev
    set res [dialog::make -ok "Build" -title "Build distribution" \
      -addbuttons [list "OK" "Remember changes but don't build\
      a distribution" {set retCode 0 ; uplevel 1 {set dontBuild 1}}] \
      [list "Distribution parameters" \
      [list var "Installer title" $alphadev(title)] \
      [list folder "Distribution directory" $alphadev(dir)] \
      [list date "All files newer than" $time] \
      [list var "New procedures in installer" $alphadev(extraprocs)] \
      [list var "Package requirements" $alphadev(requires)] \
      [list var2 "Long message (blank for default)" $alphadev(longmsg)] \
      [list var "Version of distribution" $alphadev(provides)] \
      [list variable "File tail regexp pattern to ignore" $alphadev(ignore)] \
      [list variable "Remove files" $alphadev(remove)]]]

    foreach {
	alphadev(title) alphadev(dir) newtime alphadev(extraprocs) 
	alphadev(requires) alphadev(longmsg)
	alphadev(provides) alphadev(ignore) alphadev(remove)
    } $res {}
    
    if {$newtime != $time} {
	file mtime $timetag $newtime
	set time $newtime
    }
    
    prefs::modified alphadev

    if {[info exists dontBuild]} { return }
    
    global HOME
    set dir $alphadev(dir)

    if {($dir eq "") || ![file exists $dir]} {
	alertnote "No such directory \"$dir\""
	return
    }
    
    alpha::registerEncodingFor $dir macRoman

    alphadev::dist::makeRecursiveDistribution \
      $HOME $alphadev(dir) $alphadev(ignore) $timetag

    # Delete any cache except our index
    foreach f [glob -nocomplain -dir [file join $dir Cache] *] {
	if {[file tail $f] != "index"} {catch {file delete -force $f}}
    }

    set installer [file join $dir "READ.TO.INSTALL"]
    if {![file exists $dir]} {
	alertnote "There were no files newer than your timestamp, so no\
	  distribution could be created."
	return
    }
    set iout [alphaOpen $installer w]

    alpha::deregisterEncodingFor $dir
    
    puts $iout "# (auto-install-script)(encoding:macRoman)(nowrap)"

    foreach pat $alphadev(extraprocs) {
	foreach proc [info procs ::$pat] {
	    puts $iout [procs::generate $proc]
	}
    }
    
    if {[string trim $alphadev(longmsg)] eq ""} {
	set longmsg "This brings AlphaTcl library $alphadev(requires)\
	  or newer to version $alphadev(provides). You cannot\
	  and should not install this over any other version of\
	  AlphaTcl. This is a 'development'\
	  pre-release, it may contain some bugs."
    } else {
        set longmsg $alphadev(longmsg)
    }
    append longmsg "\nIMPORTANT: Alpha will automatically quit\
      after this installation."
    set str [list install::packageInstallationDialog $alphadev(title) \
      $longmsg -require $alphadev(requires) -provide $alphadev(provides)\
      -forcequit 2 \
      -changes [alphadev::dist::getChangesSince $time] \
      -remove $alphadev(remove)]
  
    puts $iout $str
    close $iout

    # This file will be generated later anyway.
    catch {file delete [file join $dir Help Packages]}
    
    if {![dialog::yesno -y "OK" -n "Test distribution" \
      "Distribution is ready"]} {
	edit -c $installer
    }
    return
}

ensureset alphatkdev(dir) ""
ensureset alphatkdev(encoding) macRoman
ensureset alphatkdev(ignore) \
  "^(\\.#.*|CVS|CVSROOT|Developer|Frontier verbs|.*TAGS)\$"

proc alphadev::dist::makeCompleteDistribution {} {

    global alphatkdev

    set res [dialog::make -ok "Build" -title "Build distribution" \
      -addbuttons [list "OK" "Remember changes but don't build\
      a distribution" {set retCode 0 ; uplevel 1 {set dontBuild 1}} \
      "Reverse" "Update internal distribution from external" \
      {set retCode 0 ; uplevel 1 {set reverse 1}}] \
      [list "Distribution parameters" \
      [list folder "Distribution directory" $alphatkdev(dir)]\
      [list [list menu [lsort -dictionary [encoding names]]] \
      "Encoding" $alphatkdev(encoding)]\
      [list variable "File tail regexp pattern to ignore" $alphatkdev(ignore)]]]

    foreach {
	alphatkdev(dir) alphatkdev(encoding) alphatkdev(ignore)
    } $res {}
    
    prefs::modified alphatkdev

    if {[info exists dontBuild]} { return }
    
    global HOME alpha::platform
    set from $HOME
    set dir $alphatkdev(dir)

    if {($dir eq "") || ![file exists $dir]} {
	alertnote "No such directory \"$dir\""
	return
    }
    
    if {${alpha::platform} != "alpha"} {
	set from [file dirname $from]
	set cache [file join $dir AlphaTcl Cache]
    } else {
	set cache [file join $dir Cache]
    }
    # First delete any old cache in the copy distribution
    file delete -force $cache
    
    if {$alphatkdev(encoding) != ""} {
	alpha::registerEncodingFor $dir $alphatkdev(encoding) 
    }
    if {[info exists reverse]} {
	set gotErr [catch {
	    alphadev::dist::makeRecursiveDistribution \
	      $dir $from $alphatkdev(ignore)
	} err]
    } else {
	set gotErr [catch {
	    alphadev::dist::makeRecursiveDistribution \
	      $from $dir $alphatkdev(ignore)
	} err]
    }
    if {$alphatkdev(encoding) != ""} {
	alpha::deregisterEncodingFor $dir
    }

    if {![info exists reverse]} {
	# Delete any cache except our index
	foreach f [glob -nocomplain -dir $cache *] {
	    set tail [file tail $f]
	    if {($tail != "index") && ($tail != "date")} {
		catch {file delete -force $f}
	    }
	}
    }
    
    if {$gotErr} {
	status::msg "Error: $err"
    } else {
	status::msg "Done"
    }
    return
}

proc alphadev::dist::makeRecursiveDistribution {source dest \
  {ignore ""} {timetag ""}} {

    if {![file exists $dest]} {
	#file mkdir $dest
    } else {
	if {![file isdirectory $dest]} {
	    return -code error "Destination is a file, not a directory!"
	}
    }
    if {[file::pathStartsWith $dest $source]} {
	return -code error "Can't recursively copy a directory inside itself!"
    }
    status::msg "Making distribution...$source"
    foreach f [glob -nocomplain -dir $source *] {
	set tail [file tail $f]
	set to [file join $dest $tail]
	# ignore certain files or directories.
	if {[string length $ignore]} {
	    if {[regexp -- $ignore $tail]} {continue}
	}
	if {[file isdirectory $f]} {
	    #file::ensureDirExists $to
	    alphadev::dist::makeRecursiveDistribution $f $to $ignore $timetag
	} else {
	    if {[string length $timetag]} {
		if {[regexp {tclIndexx?$} $tail]} {
		    continue
		}
		if {[file::compareModifiedDates $f $timetag] != 1} {
		    continue
		}
	    }
	    
	    # The source file is newer than the timetag
	    if {[file isdirectory $to]} {
		file delete -force $to
	    }
	    if {[file exists $to]} {
		switch -- [file::compareModifiedDates $f $to] {
		    0 {
			# file is already in the distribution
			continue
		    }
		    1 {
			# distribution file is older, therefore replace
			file delete $to
		    }
		    -1 -
		    default {
			# distribution file is newer!
			#file mtime $to [file mtime $f]
			if {![dialog::yesno -y "Continue" -n "Cancel" \
			  "The file '$to' in the distribution is newer."]} {
			    return -code error "Cancelled."
			}
			continue
		    }
		}
		# fall through from '1' case above
	    }
	    # Perform a copy
	    if {[file::coreCopy $f $to] eq "text"} {
		catch {file attributes $to -type TEXT -creator AlTk}
	    }
	}
    }
    return
}

proc alphadev::dist::ensureAlphaDistnUpToDate {alpha} {
    variable log ""
    set d [pwd]
    alphadev::dist::_ensureAlphaDistnUpToDate ${alpha} :
    alphadev::dist::showLog
    alphadev::dist::_recursivelyRebuildIndices ${alpha}:Tcl:
    cd $d
    alertnote "Done"
    return
}

proc alphadev::dist::_recursivelyRebuildIndices {dir} {
    global tcl_platform
    if {[file exists $dir]} {
	set old [pwd]
	cd $dir
	if {![catch {glob *.tcl}]} {
	    if {$tcl_platform(platform) == "macintosh"} {
		catch { auto_mkindex : }
	    } else {
		catch { auto_mkindex . }
	    }
	}
	foreach dir [glob -nocomplain -type d *] {
	    alphadev::dist::_recursivelyRebuildIndices $dir
	}
	cd $old
    }
    return
}

proc alphadev::dist::_ensureAlphaDistnUpToDate {alpha dir} {
    global HOME
    status::msg "Examining ${dir}É"
    cd $alpha$dir
    set dirs ""
    set files ""
    set all [glob -nocomplain *]
    set havedir 0
    foreach a $all {
	if {[file isdirectory $a]} { 
	    lappend dirs $a
	    set havedir 1
	} else {
	    lappend files $a
	}
    }
    if {!$havedir} {
	# bottom level directory.  Check file-count
	set cdist [llength $all]
	set corig [llength [glob -nocomplain -path ${HOME}${dir} *]]
	if {$cdist != $corig} {
	    alphadev::dist::log "WARNING: FILE-COUNT CHANGED IN $dir"
	}
    }
	
    foreach f $files {
	if {[file exists ${HOME}${dir}$f]} {
	    if {![regexp {^tclIndexx?$} $f]} {
		file::replaceSecondIfOlder ${HOME}${dir}$f \
		  $alpha$dir$f
	    }
	} else {
	    alphadev::dist::log "Warning: file $f was not found."
	}
    }
    foreach d $dirs {
	if {[file exists ${HOME}${dir}$d]} {
	    alphadev::dist::_ensureAlphaDistnUpToDate $alpha ${dir}${d}:
	} else {
	    alphadev::dist::log "WARNING: Original directory '$d' doesn't exist"
	}
    }
    return
}

proc alphadev::dist::stuffPackageForDistribution {{fore 0}} {
    set stuff [alphadev::dist::_getStuffedFile \
      [alphadev::dist::_getDistributionBaseName]]
    # Try and remove the old stuffed version
    if {$stuff != ""} {
	catch {file delete $stuff}
    }
    alphadev::dist::_stuffDistribution \
      [alphadev::dist::_getDistributionBase] $fore
    return
}

proc alphadev::dist::_getDistributionBaseName {} {
    return [file tail [alphadev::dist::_getDistributionBase]]
}
proc alphadev::dist::_getDistributionBase {} {
    # Is it a file or directory?
    set f [win::Current]
    if {[file extension $f] != ".tcl"} {
	return [file dirname $f]
    } else {
	return $f
    }
}

proc alphadev::dist::_stuffDistribution {ff {fore 0}} {
    
    if {[file isdirectory $ff] && ![regexp -- "[file separator]\$" $ff]} {
	append ff [file separator]
    }
    # Now stuff new distribution
    app::launchBack DStf
    if {$fore} {
	sendOpenEvent reply 'DStf' $ff
    } else {
	sendOpenEvent noReply 'DStf' $ff
    }
    sendQuitEvent 'DStf'
    return
}

proc alphadev::dist::_getStuffedFile {pref} {
    global InstmodeVars
    set files [glob -nocomplain -path \
      [file join $InstmodeVars(dropStuffFolder) ${pref}] *.hqx]
    if {[llength $files] == 1} {
	return [lindex $files 0]
    }
    return ""
}

proc alphadev::dist::uploadStuffedPackage {{ask 1}} {
    set stuff [alphadev::dist::_getStuffedFile \
      [alphadev::dist::_getDistributionBaseName]]
    if {$stuff == ""} {
	alertnote "Sorry, I couldn't find the stuffed distribution."
	error ""
    }
    global InstmodeVars alpha::downloadSite
    set sitename $InstmodeVars(defaultAlphaUploadSite)
    url::store $alpha::downloadSite($sitename) $stuff
    return
}

# ===========================================================================
# 
# .