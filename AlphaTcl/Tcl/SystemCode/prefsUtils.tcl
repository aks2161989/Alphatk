## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "prefsUtils.tcl"
 #                                          created: 02/24/1995 {09:52:30 pm}
 #                                      last update: 02/13/2006 {04:13:26 PM}
 # 
 # Reorganisation carried out by Vince Darley with much help from Tom
 # Fetherston, Johan Linde and suggestions from the alphatcl-developers
 # mailing list.  Alpha is shareware; please register.
 #  
 # Description: 
 # 
 # Procedures for dealing with the user's preferences.
 # 
 # ==========================================================================
 ##

proc prefsUtils.tcl {} {}

namespace eval prefs {}

# ===========================================================================
# 
# ×××× Prefs Dialog Support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::getDialogType" --
 # 
 # Obtain the dialog type for the given variable name.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::getDialogType {name} {
    
    variable list
    variable type
    
    if {[info exists list($name)]} {
	if {[regexp -- {index$} [lindex $list($name) 0]]} {
	    set res [list menuindex]
	} else {
	    set res [list menu]
	}
	lappend res [options $name]
    } elseif {[info exists type($name)]} {
	return $type($name)
    } else {
	switch -regexp -- $name {
	    Colou?r$        {return "colour"}
	    Mode$           {return "mode"}
	    FilePaths$      {return "filepaths"}
	    SearchPath$     {return "searchpath"}
	    (Path|Folder)$  {return "folder"}
	    Sig$            {return "appspec"}
	    default         {return "var"}
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::options" --
 # 
 # Another dialog procedure, this one helps determine what should be offered
 # in a pop-up menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::options {v} {
    
    variable list
    
    set thelist [set list($v)]
    set litems [lindex $thelist 1]
    switch -- [lindex $thelist 0] {
	"varitem" -
	"varindex" {
	    return [uplevel \#0 "set $litems"]
	}
	"cmditem" -
	"cmdindex" {
	    return [uplevel \#0 $litems]
	}
	"array" {
	    global $litems
	    return [lsort [array names $litems]]
	}
    }
    return $litems
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::changed" --
 # 
 # Use this when a standard preference is changed (typically in a prefs
 # dialog or through a menu of flag preferences).  It takes care of calling
 # 'prefs::modified', and calling any scripts that are registered, and
 # adjusting any bindings associated with this preference.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::changed {storage flag origVal newVal} {
    
    variable script
    variable binding
    
    if {($storage eq "")} {
	set changeScripts [list $flag]
	prefs::modified $flag
    } else {
	set changeScripts [list "${storage}modeVars($flag)" "*,$flag"]
	prefs::modified ${storage}modeVars($flag)
    }
    foreach fp $changeScripts {
	if {[info exists script($fp)]} {
	    set sc $script($fp)
	    if {(([info commands $sc] ne "") || [auto_load $sc]) \
	      && ([info procs $sc] ne "") && ([llength [info args $sc]] == 0)} {
		# We will remove this code path in the future.  It is
		# non-standard.
		uplevel \#0 $sc
	    } else {
		uplevel \#0 $sc [list $flag]
	    }
	    break
	}
    }
    if {[info exists binding($flag)]} {
	set m [lindex $binding($flag) 0]
	if {[set bindTo [lindex $binding($flag) 1]] == 1} {
	    set bindTo $flag
	}
	if {$origVal ne ""} {
	    catch "unBind [keys::toBind $origVal] [list $bindTo] $m"
	}
	catch "Bind [keys::toBind $newVal] [list $bindTo] $m"
    }
}

# ===========================================================================
# 
# ×××× Manipulating Saved Prefs ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::saveNow" --
 # 
 # Save any preferences changed by the user during this editing session.
 # This is in general called whenever some major preferences dialog has been
 # presented to the user, so that an unfortunate crash or a force-quit won't
 # forget everything.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::saveNow {} {
    
    global PREFS HOME alpha::home alpha::earlyPrefs global::features \
      skipPrefs prefDefs arrprefDefs earlyprefDefs earlyarrprefDefs
    
    variable modifiedVars
    variable modifiedArrayElements
    
    if {[info exists skipPrefs] && ($skipPrefs != 0)} {
	if {($skipPrefs == 2) || [askyesno "You skipped loading\
	  your saved preferences\
	  at startup.  Do you wish to save the current configuration?\
	  (it will permanently over-write the old preferences)"] != "yes"} {
	    return
	}
    }
    status::msg [set msg "Saving preferences É "]
    watchCursor
    if {0} {
	# Output our current encoding.
	global PREFS
	set fout [alphaOpen [file join $PREFS encoding.txt] w]
	puts $fout [fconfigure $fout -encoding]
	close $fout
    }
    
    set alpha::home $HOME
    
    set res [prefs::checkListIsUnique [set global::features]]
    if {[llength $res]} {
	alertnote "Your global features list contains duplicates\
	  ([join [lindex $res 0] {, }]);\
	  please report this problem to the alphadev mailing list.\
	  The problem will be fixed automatically."
	set global::features [lindex $res 1]
    }
    
    if {![info exists alpha::earlyPrefs]} {
	set alpha::earlyPrefs [list]
    }
    foreach v [list ::alpha::home ::global::features] {
	if {[lsearch -exact $alpha::earlyPrefs $v] == -1} {
	    lappend alpha::earlyPrefs $v
	}
	lappend modifiedVars $v
    }
    
    # Start of main preference saving

    prefs::_read
    prefs::_read arr
    prefs::_read early
    prefs::_read earlyarr
    
    if {![info exists modifiedVars]} {
	set modifiedVars {}
    }
    foreach f [lunique $modifiedVars] {
	# This 'global $f' can throw an error if, for example,
	# an entire namespace has been deleted. 
	if {[catch {global $f}]} {
	    continue
	}
	if {[lsearch -exact $alpha::earlyPrefs $f] == -1} {
	    if {[array exists $f]} {
		# prefs::addArray $f
		foreach r [array names arrprefDefs] {
		    if {[lindex $r 0] eq $f} {
			unset arrprefDefs($r)
		    }
		}
		foreach def [array names $f] {
		    catch {set arrprefDefs([list $f $def]) [set ${f}($def)]}
		}
	    } else {
		if {[info exists $f]} {
		    # prefs::add $f [set $f]
		    set prefDefs($f) [set $f]
		} else {
		    # prefs::remove $f
		    unset -nocomplain prefDefs($f)
		}
	    }
	} else {
	    if {[array exists $f]} {
		# prefs::addArray $f
		foreach r [array names earlyarrprefDefs] {
		    if {[lindex $r 0] eq $f} {
			unset earlyarrprefDefs($r)
		    }
		}
		foreach def [array names $f] {
		    catch {set earlyarrprefDefs([list $f $def]) [set ${f}($def)]}
		}
	    } else {
		if {[info exists $f]} {
		    set earlyprefDefs($f) [set $f]
		} else {
		    unset -nocomplain earlyprefDefs($f)
		}
	    }
	}
    }
    
    if {![info exists modifiedArrayElements]} {
	set modifiedArrayElements [list]
    }
    foreach f [lunique $modifiedArrayElements] {
	set elt [lindex $f 0]
	set arr [lindex $f 1]
	if {[catch {global $arr}]} {
	    continue
	}
	if {([lsearch -exact [set alpha::earlyPrefs] $arr] == -1)} {
	    if {[info exists [set arr]($elt)]} {
		# prefs::addArrayElement [set arr] $elt [set [set arr]($elt)]
		set arrprefDefs([list $arr $elt]) [set [set arr]($elt)]
	    } else {
		# prefs::removeArrayElement [set arr] $elt
		unset -nocomplain arrprefDefs([list $arr $elt])
	    }
	} else {
	    if {[info exists [set arr]($elt)]} {
		# prefs::addArrayElement [set arr] $elt [set [set arr]($elt)]
		set earlyarrprefDefs([list $arr $elt]) [set [set arr]($elt)]
	    } else {
		# prefs::removeArrayElement [set arr] $elt
		unset -nocomplain earlyarrprefDefs([list $arr $elt])
	    }
	}
    }
    
    prefs::_write
    prefs::_write arr
    prefs::_write early
    prefs::_write earlyarr
    
    unset -nocomplain prefDefs arrprefDefs earlyprefDefs earlyarrprefDefs
    # End of main preference saving
    
    # Make backups. Use -force to overwrite existing file.
    if {[file exists [file join $PREFS arrdefs.tcl]]} {
	file copy -force [file join $PREFS arrdefs.tcl] \
	  [file join $PREFS backuparrdefs.tcl]
    }
    if {[file exists [file join $PREFS defs.tcl]]} {
	file copy -force [file join $PREFS defs.tcl] \
	  [file join $PREFS backupdefs.tcl]
    }
    status::msg [append msg "finished."]
    return
}

proc prefs::saveModified {} {
    prefs::forgetModified 1
    return
}

proc prefs::forgetModified {{save 1}} {
    
    variable modifiedVars
    variable modifiedArrayElements

    if {$save} {
	prefs::saveNow
    }
    unset -nocomplain modifiedVars
    unset -nocomplain modifiedArrayElements
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::deleteEverything" --
 # 
 # Called by [uninstallHook] when the user is completely uninstalling Alpha 
 # and removing all traces of its existence.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::deleteEverything {} {
    
    global PREFS
    
    prefs::forgetModified 0
    file delete -force $PREFS
    return
}


# ===========================================================================
# 
# ×××× Miscellaneous Support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::modifiedVar" --
 # "prefs::modifiedModeVar" --
 # "prefs::modifiedArrayElement" --
 # 
 # These are rarely (if ever) used.  In general, [prefs::modified] should be 
 # sufficient to register a given variable or array to be saved.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::modifiedVar {args} {
    
    variable modifiedVars
    
    eval lappend modifiedVars $args
    return
}

proc prefs::modifiedModeVar {var {m ""}} {
    
    if {($m eq "") && ([set m [win::getMode]] == "")} {
	return
    }
    prefs::modifiedArrayElement $var ${m}modeVars
    return
}

proc prefs::modifiedArrayElement {var arr} {
    
    variable modifiedArrayElements
    
    lappend modifiedArrayElements [list $var $arr]
    return
}

# ===========================================================================
# 
# ×××× User Interface procs ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::viewSavedSetting" --
 # 
 # Present all saved settings to the user in a list-pick dialog, "prettified"
 # so that the names correspond to those seen in normal prefs dialogs.  For
 # each one chosen, display the current value for the setting in the manner
 # that [viewValue] deems most appropriate.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::viewSavedSetting {} {
    
    global prefDefs arrprefDefs

    # This will create the "prefDefs" and "arrprefDefs" arrays.
    prefs::saveModified

    status::msg  "Choose some saved preference settings to view É"
    set title    "The following settings have been saved:"
    set settings [prefs::chooseSavedSetting $title]
    status::msg  ""
    
    set placeOrAppend "0"
    foreach setting $settings {
        if {[regexp {^([^\(]+)\((.*)\)$} $setting -> arr field]} {
            set arg [list $arr $field]
            set val $arrprefDefs($arg)
        } else {
            global $setting
            set val $prefDefs($setting)
        }
        status::msg "\"$setting\" value: $val"
        if {[viewValue $setting $val $placeOrAppend]} {
            set placeOrAppend 1
        }
    }
    # Now we'll get rid of these arrays again.
    unset -nocomplain prefDefs arrprefDefs
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::removeSavedSetting" --
 # 
 # This proc shouldn't 'unset' the variables it removes, because most such
 # variables will be in use/have default values until restart.
 #  
 # --------------------------------------------------------------------------
 ##

proc prefs::removeSavedSetting {} {
    
    global prefDefs arrprefDefs

    # This will create the "prefDefs" and "arrprefDefs" arrays.
    prefs::saveModified
    
    status::msg  "Choose some preferences to remove É"
    set title    "Remove which settings?"
    set settings [prefs::chooseSavedSetting $title]
    status::msg  ""

    foreach setting $settings {
        if {[regexp {^([^\(]+)\((.*)\)$} $setting -> arr field]} {
            global $arr
            prefs::removeArrayElement $arr $field
        } else {
            global $setting
            prefs::remove $setting
        }
    }
    # Now we'll get rid of these arrays again.
    unset -nocomplain prefDefs arrprefDefs
    status::msg "The saved settings will be removed when you quit."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::chooseSavedSetting" --
 # 
 # Present all saved settings to the user in a list-pick dialog, "prettified"
 # so that the names correspond to those seen in normal prefs dialogs.  Prefs
 # in arrays or in namespaces are first displayed with ellipses, and if
 # chosen presented as a "collection".  All names are then converted back
 # into their original Tcl format and returned as a list.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::chooseSavedSetting {{title "Choose some preferences:"}} {
    
    global prefDefs arrprefDefs
    
    variable lastChosenPrefs
    
    # Create different categories of variables.
    set nsPrefs    [list]
    set arrayPrefs [list]
    set prefsList  [list]
    set PrefsList  [list]
    set finalList  [list]
    set allModes   [mode::listAll]
    foreach prefName [prefs::listAllSaved] {
        regsub {^::} $prefName {} PrefName
        if {[regexp {^([^\(]+)\((.+)\)$} $PrefName -> arrayName entry]} {
            # This is an array, so we'll collect all of them for presentation
            # in a subsequent dialog.  We'll massage the name while creating
            # a mapping to obtain the original.
            lappend arrayEntries($arrayName) $entry
            regsub {modeVars$} $arrayName {} modeName
            if {([lsearch $allModes $modeName] > -1)} {
                set ArrayName "$modeName Mode Prefs É"
            } else {
                regsub {modeVars$} $arrayName {Prefs} ArrayName
                set ArrayName "[quote::Prettify $ArrayName] É"
            }
            set prefConnect($ArrayName) $arrayName
            lappend PrefsList $ArrayName
        } elseif {[regexp {(^[^:]+)::(.+)$} $PrefName -> ns theRest]} {
            # This preference is in a namespace, so we'll collect all of them
            # for presentation in a subsequent dialog.  We'll massage the
            # name while creating a mapping to obtain the original.
            lappend nsEntries($ns) $theRest
            set Ns "[quote::Prettify $ns] É"
            set prefConnect($Ns) $ns
            lappend PrefsList $Ns
        } else {
            set PrefName [quote::Prettify $PrefName]
            set prefConnect($PrefName) $prefName
            lappend PrefsList $PrefName
        }
    }
    set PrefsList [lsort -unique -dictionary $PrefsList]
    if {![llength $PrefsList]} {
        # We need to remove these variables which [prefs::listAllSaved]
        # created for us.
        unset -nocomplain prefDefs arrprefDefs
        alertnote "No preferences have been saved."
        error "cancel"
    }
    if {[info exists lastChosenPrefs()] && \
      ([lsearch $PrefsList $lastChosenPrefs()] > -1)} {
        set L [list $lastChosenPrefs()]
    } else {
        set L [lrange $PrefsList 0 0]
    }
    if {[catch {listpick -p $title -l -L $L $PrefsList} Settings]} {
        unset -nocomplain prefDefs arrprefDefs
        error "cancel"
    }
    set lastChosenPrefs() [lindex $Settings 0]
    foreach PrefName $Settings {
        if {[info exists prefConnect($PrefName)]} {
            lappend prefsList $prefConnect($PrefName)
        }
    }
    # Now we find out if we picked an actual preference yet, or just a
    # category with more choices.
    foreach chosenPref $prefsList {
        if {[info exists arrayEntries($chosenPref)]} {
            regsub {modeVars$} $chosenPref {} modeName
            if {([lsearch $allModes $modeName] > -1)} {
                set ArrayName "$modeName Mode"
            } else {
                regsub {modeVars$} $chosenPref {} ArrayName
                set ArrayName [quote::Prettify $ArrayName]
            }
            set title "\"$ArrayName\" preferences :"
            # Now we massage the array entry names.
            set EntriesList [list]
            foreach entryName $arrayEntries($chosenPref) {
                if {![regexp { } $entryName]} {
                    set Entry [quote::Prettify $entryName]
                } else {
                    set Entry $entryName
                }
                set prefConnect($Entry) $entryName
                lappend EntriesList $Entry
            }
            set EntriesList [lsort -unique -dictionary $EntriesList]
            if {[info exists lastChosenPrefs($chosenPref)] && \
              ([lsearch $EntriesList $lastChosenPrefs($chosenPref)] > -1)} {
                set L [list $lastChosenPrefs($chosenPref)]
            } else {
                set L [lrange $EntriesList 0 0]
            }
            if {![catch {listpick -p $title -l -L $L $EntriesList} Entries]} {
                foreach Entry $Entries {
                    if {[info exists prefConnect($Entry)]} {
                        set entry $prefConnect($Entry)
                        lappend finalList "::${chosenPref}(${entry})"
                    }
                }
                set lastChosenPrefs($chosenPref) [lindex $Entries 0]
            }
        } elseif {[info exists nsEntries($chosenPref)]} {
            set NsName [quote::Prettify $chosenPref]
            set title "\"$NsName\" preferences :"
            # Now we massage the namespace entry names.
            set EntriesList [list]
            foreach entryName $nsEntries($chosenPref) {
                if {![regexp { } $entryName]} {
                    set Entry [quote::Prettify $entryName]
                } else {
                    set Entry $entryName
                }
                set prefConnect($Entry) $entryName
                lappend EntriesList $Entry
            }
            set EntriesList [lsort -unique -dictionary $EntriesList]
            if {[info exists lastChosenPrefs($chosenPref)] && \
              ([lsearch $EntriesList $lastChosenPrefs($chosenPref)] > -1)} {
                set L [list $lastChosenPrefs($chosenPref)]
            } else {
                set L [lrange $EntriesList 0 0]
            }
            if {![catch {listpick -p $title -l -L $L $EntriesList} Entries]} {
                foreach Entry $Entries {
                    if {[info exists prefConnect($Entry)]} {
                        set entry $prefConnect($Entry)
                        lappend finalList "::${chosenPref}::${entry}"
                    }
                }
                set lastChosenPrefs($chosenPref) [lindex $Entries 0]
            }
        } else {
            lappend finalList $chosenPref
        }
    }
    if {![llength $finalList]} {
        unset -nocomplain prefDefs arrprefDefs
        error "Cancelled -- no preferences were chosen."
    } else {
        return $finalList
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::listAllSaved" --
 # 
 # Return a list of all currently saved settings, i.e. those that have at
 # some point been changed by the user (even if the current value is the
 # original one provided).
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::listAllSaved {} {
    
    global prefDefs arrprefDefs
    
    prefs::_read
    prefs::_read arr
    
    # Strip out private Alpha-specific stuff we don't want
    # the user to mess with!
    foreach name [array names prefDefs ::alpha::*] {
	unset prefDefs($name)
    }
    set names [array names prefDefs]
    foreach pair [array names arrprefDefs] {
	lappend names "[lindex $pair 0]([lindex $pair 1])"
    }
    return [lsort -dictionary $names]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Prefs Searching ×××× #
# 
# 18 Jan 2006: Implemented by Jon Guyer <jguyer@his.com>
# 23 Jan 2006: Substantially improved by Craig Barton Upright <cupright@earthlink.net>
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::searchForSetting" --
 # 
 # Called by the menu procedure, redirects to the actual procedure we use.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::searchForSetting {} {
    return [prefs::search::findSettings]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval prefs::search" --
 # 
 # Defines the default values used for the initial dialog.  All values 
 # entered by the user will then be saved for subsequent calls.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval prefs::search {
    
    variable fields
    
    if {![info exists fields]} {
        array set fields {
            find "" for "exact phrase" ignoreCase 1 wordMatch 0
            global 1 modes "every mode" packages "every package" help 1
        }
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::search::findSettings" --
 # 
 # Create and present a dialog to the user offering all of the criteria used 
 # to find references in prefs files, package descriptions, and package 
 # help.  There are four major parts to this procedure:
 # 
 # (1) Create and present a dialog to the user.
 # (2) Search for all settings using the given criteria.
 # (3) Creating the window text, starting with a header.
 # (4) Finally, we create our new window.
 # 
 # Collecting all of the information is relatively fast, as is manipulating
 # the text for presentation.  It is much more efficient to do all of this 
 # before the window is actually created, caching the information along with 
 # any colors/hypers to be added later.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::search::findSettings {} {
    
    variable fields
    
    prefs::search::cacheItem "clear"
    
    # =======================================================================
    # 
    # (1) Create and present a dialog to the user.
    # 
    set modeOptions [list "no modes" "every mode"]
    if {([set m [win::getMode]] ne "")} {
        lappend modeOptions "'${m}' mode only"
    }
    set result [dialog::make -title "Search For Settings" \
      -ok "Search" \
      [list "" \
      [list static " "] \
      [list [list menu {"any word" "every word" "exact phrase" "regular expression"}] \
      "Search for" $fields(for) ""] \
      [list var "containing" $fields(find) ""] \
      [list flag "Ignore Case" $fields(ignoreCase) \
        "To ignore upper/lower case differences when searching, click this\
        box.||To use exact, case-sensitive matches only, click this box"] \
      [list flag "Word Match" $fields(wordMatch) \
        "To match only entire words, click this box.||To allow any\
        sequence of characters which matches the above search string,\
        click this box."] \
      [list static " "] \
      [list flag "Search global preferences" $fields(global) \
        "To search global preferences, click this\
        box.||To ignore global preferences, click this box"] \
      [list [list menu $modeOptions] "Search in" $fields(modes) ""] \
      [list [list menu {"no packages" "active packages" "every package"}] \
      "Search in " $fields(packages) ""] \
      [list flag "Search mode and package help" $fields(help) ""] \
      ]]

    foreach setting {for find ignoreCase wordMatch global modes packages help} value $result {
        set fields($setting) $value
    }
    if {([string trim $fields(find)] eq "")} {
        alertnote "The search string cannot be empty!"
        return [prefs::searchForSetting]
    }
    # =======================================================================
    # 
    # (2) Search for all settings using the given criteria.
    # 
    watchCursor
    status::msg "Searching for settingsÉ"
    set fields(representation) "\"$fields(find)\""
    switch -- $fields(for) {
        "any word" {
            set find [list]
            set fields(representation) [list]
            foreach word $fields(find) {
                lappend find [quote::Regfind $word]
                lappend fields(representation) "\"${word}\""
            }
            set find "([join $find |])"
            set fields(representation) [join $fields(representation) " or "]
        }
        "every word" {
            set fields(representation) [list]
            set findList [list]
            foreach word $fields(find) {
                lappend findList [quote::Regfind $word]
                lappend fields(representation) "\"${word}\""
            }
            set find [lindex $findList 0]
            set fields(representation) [join $fields(representation) " and "]
        }
        "exact phrase" {
            set find [quote::Regfind $fields(find)]
        }
        "regular expression" {
            set find $fields(find)
        }
    }
    # Set up variables required for searching and storing.
    set flags ""
    if {$fields(ignoreCase)} {
        set flags "${flags}i"
    }
    if {$fields(wordMatch)} {
        set find "\\y${find}\\y"
    }
    set base "***:"
    if {($flags ne "")} {
        append base "(?${flags})"
    }
    set query "${base}${find}"
    if {($fields(for) eq "every word")} {
        set colorQuery "${base}([join $findList |])"
    } else {
        set colorQuery $query
    }
    array set prefs [list]
    array set modes [list]
    array set packages [list]
    # Collect all settings information.
    if {$fields(global)} {
        # Collect global preferences suites based on name.
        global flagPrefs varPrefs
        foreach prefSuite {flagPrefs varPrefs} {
            foreach suite [lsearch -all -regexp -inline [array names $prefSuite] $query] {
                if {($fields(for) ne "every word") \
                  || [prefs::search::matchEvery $suite $base $findList]} {
                    set prefs($suite) [list]
                }
            }
        }
        # Collect global preferences based on name.
        set flagList [array get flagPrefs]
        set varList [array get varPrefs]
        foreach prefList [list $flagList $varList] {
            set prefIDs [lsearch -all -regexp $prefList $query]
            foreach ID $prefIDs {
                if {($fields(for) eq "every word") \
                  && ![prefs::search::matchEvery \
		  [lindex $prefList $ID] $base $findList]} {
                    continue
                }
                if {([expr {$ID % 2}] == 1)} {
                    incr ID -1
                }
                set setName [lindex $prefList $ID]
                if {[info exists prefs($setName)]} {
                    array set tmp $prefs($setName)
                } else {
                    array set tmp [list]
                }
                set prefSet [lsearch -all -regexp -inline \
		  [lindex $prefList [expr {$ID + 1}]] $query]
                foreach name $prefSet {
                    set tmp($name) ""
                }
                set prefs([lindex $prefList $ID]) [array get tmp]
                array unset tmp
            }
        }
    }
    # Collect modes and packages based on name.
    switch -- $fields(modes) {
        "no modes" {
            set modeList [list]
        }
        "every mode" {
            set modeList [mode::listAll]
        }
        default {
            set modeList [list $m]
        }
    }
    foreach mode [lsearch -all -regexp -inline $modeList $query] {
        if {($fields(for) ne "every word") \
          || [prefs::search::matchEvery $mode $base $findList]} {
            set modes($mode) [list]
        }
    }
    switch -- $fields(packages) {
        "no packages" {
            set packageList [list]
        }
        "active packages" {
            set packageList [list]
            foreach pkg [alpha::listAlphaTclPackages] {
                if {[package::active $pkg]} {
                    lappend packageList $pkg
                }
            }
        }
        "every package" {
            set packageList [alpha::listAlphaTclPackages]
        }
    }
    foreach pkg [lsearch -all -regexp -inline $packageList $query] {
        if {($fields(for) ne "every word") \
          || [prefs::search::matchEvery $pkg $base $findList]} {
            set packages($pkg) [list]
        }
    }
    # Collect modes and packages based on description and help.
    set lists [list [array get index::description]]
    if {$fields(help)} {
        lappend lists [array get index::help]
    }
    foreach textList $lists {
        foreach ID [lsearch -all -regexp $textList $query] {
            if {([expr {$ID % 2}] == 1)} {
                if {($fields(for) eq "every word") \
                  && ![prefs::search::matchEvery \
		  [lindex $textList $ID] $base $findList]} {
                    continue
                }
                incr ID -1
                set name [lindex $textList $ID]
            } else {
                continue
            }
            
            # is it a mode or a package?
            if {([lsearch -regexp $modeList "***:(?q)$name"] >= 0)} {
                set modes($name) [list]
            } elseif {([lsearch -regexp $packageList "***:(?q)$name"] >= 0)} {
                set packages($name) [list]
            }
        }
    }
    # Collect preferences based on help.
    set helpList [array get index::prefshelp]
    foreach ID [lsearch -all -regexp $helpList $query] {
        if {([expr {$ID % 2}] == 1)} {
            if {($fields(for) eq "every word") \
              && ![prefs::search::matchEvery \
	      [lindex $helpList $ID] $base $findList]} {
                continue
            }
            incr ID -1
            set prefName [lindex $helpList $ID]
        } else {
            continue
        }
        if {[regexp "(.*),(.*)" $prefName -> pkgOrMode prefName]} {
            # It's a mode or package preference -- which one?
            if {([lsearch -regexp $modeList "***:(?q)$pkgOrMode"] >= 0)} {
                prefs::search::addPrefToArrayList modes $pkgOrMode $prefName
            } elseif {([lsearch -regexp $packageList "***:(?q)$pkgOrMode"]  >= 0)} {
                prefs::search::addPrefToArrayList packages $pkgOrMode $prefName
            }
        } elseif {$fields(global)} {
            # It's a global pref -- find the pref suite it belongs to.
            set suiteName ""
            foreach prefList [list $flagList $varList] {
                set suiteID [lsearch -regexp $prefList "***:(?q)$prefName"]
                if {($suiteID >= 0) && ([expr {$suiteID % 2}] == 1)} {
                    prefs::search::addPrefToArrayList prefs \
                      [lindex $prefList [expr {$suiteID - 1}]] $prefName
                    break
                }
            }
        }
    }
    if {![llength [array names prefs]] \
      && ![llength [array names modes]] \
      && ![llength [array names packages]]} {
	set msg "No settings found for given criteria."
	status::msg $msg
	if {[askyesno "$msg\r\rWould you like to try again?"]} {
	    return [prefs::search::findSettings]
	} else {
	    error "Cancelled."
	}
    }
    # =======================================================================
    # 
    # (3) Creating the window text, starting with a header.
    # 
    set headerText {
Search Settings Results

This window contains information about all of the preferences matching your
search criteria:

    Search For:          ÇforÈ
    Containing:          ÇfindÈ
    Ignore Case:         ÇignoreCaseÈ
    Word Match:          ÇwordMatchÈ
    Global Prefs:        ÇglobalÈ
    Mode Prefs:          ÇmodesÈ
    Package Prefs:       ÇpackagesÈ
    Mode/Package Help:   ÇhelpÈ

}
    foreach item [list "for" "find" "modes" "packages"] {
        regsub -all -- "Ç${item}È" $headerText $fields($item) headerText
    }
    foreach item [list "ignoreCase" "wordMatch" "global" "help"] {
        set value [expr {$fields($item) ? "Yes" : "No"}]
        regsub -all -- "Ç${item}È" $headerText $value headerText
    }
    prefs::search::cacheItem "text"  $headerText
    prefs::search::cacheItem "text"  "Click on "
    prefs::search::cacheItem "hyper" "help hyperlinks" \
      "alertnote {This is a hyperlink!}"
    prefs::search::cacheItem "text"  " for detailed information on a mode or package.\r"
    prefs::search::cacheItem "text"  "Click on a "
    prefs::search::cacheItem "hyper" "preferences hyperlink" \
      "alertnote {This is a hyperlink!}"
    prefs::search::cacheItem "text"  " to open the appropriate preference panel.\r"
    prefs::search::cacheItem "text" "\rClick here: <<prefs::searchForSetting>> "
    prefs::search::cacheItem "text" "to change your search criteria.\r\r"
    # Add global preferences.
    if {[llength [array names prefs]]} {
        prefs::search::displayCategoryHeader "Global"
        foreach prefSet [lsort -dictionary [array names prefs]] {
            set PrefSet [quote::Prettify $prefSet]
            prefs::search::cacheItem "mark" $PrefSet 2
            prefs::search::cacheItem "red"  "    $PrefSet "
            prefs::search::cacheItem "hyper" "preferencesÉ" \
              "help::openPrefsDialog \"$prefSet\""
            prefs::search::cacheItem "text"  "\r\r"
            prefs::search::displayPrefsAndHelp prefs $prefSet
        }
    }
    # Add mode information/preferences.
    if {[llength [array names modes]]} {
        prefs::search::displayCategoryHeader "Modes and"
        foreach mode [lsort -dictionary [array names modes]] {
            prefs::search::cacheItem "mark" "$mode mode" 2
            prefs::search::cacheItem "red"  "    $mode mode"
            prefs::search::cacheItem "text" "    "
            prefs::search::cacheItem "hyper" "help" \
              "help::openGeneral $mode"
            prefs::search::cacheItem "text" "    "
            prefs::search::cacheItem "hyper" "preferencesÉ" \
              "help::openPrefsDialog Mode-$mode"
            prefs::search::cacheItem "text" "\r\r"
            prefs::search::displayHelp index::description $mode 1 8
            prefs::search::cacheItem "text" "\r\r"
            prefs::search::displayPrefsAndHelp modes $mode "${mode},"
        }
    }
    # Add package information/preferences.  We only add hyperlinks to open
    # package pref dialogs if there are some preferences to set.  This does
    # imply that the package has to be turned on.  (The alternative is to
    # turn it on when the user clicks on the hyperlink, but even then there
    # might not be any preferences to view.)
    if {[llength [array names packages]]} {
        prefs::search::displayCategoryHeader "Packages and"
        foreach package [lsort -dictionary [array names packages]] {
            set Package [quote::Prettify $package]
            prefs::search::cacheItem "mark" $Package 2
            prefs::search::cacheItem "red"  "    $Package"
            prefs::search::cacheItem "text" "    "
            prefs::search::cacheItem "hyper" "help" "help::openGeneral $package"
            global ${package}modeVars
            if {[llength [array get ${package}modeVars]]} {
                prefs::search::cacheItem "text" "    "
                prefs::search::cacheItem "hyper" "preferencesÉ" \
                  "help::openPrefsDialog $package"
            }
            prefs::search::cacheItem "text" "\r\r"
            prefs::search::displayHelp index::description $package 1 8
            prefs::search::cacheItem "text" "\r\r"
            prefs::search::displayPrefsAndHelp packages $package "${package},"
        }
    }
    # =======================================================================
    # 
    # (4) Finally, we create our new window.
    # 
    set n "* Settings referring to $fields(representation) *"
    set windowText [prefs::search::cacheItem "text"]
    if {[win::Exists $n]} {
        set w $n
        bringToFront $w
        win::setInfo $w read-only 0
        replaceText -w $w [minPos -w $w] [maxPos -w $w] $windowText
    } else {
        set w [new -n $n -text $windowText -mode "Text"]
    }
    goto -w $w [minPos -w $w]
    # Add window marks.
    set seenMarks [list]
    foreach markItem [prefs::search::cacheItem "mark"] {
        set markPos  [lindex $markItem 0]
        set markName [lindex $markItem 1]
        while {([lsearch -exact $seenMarks $markName] > -1)} {
            append markName " "
        }
        lappend seenMarks $markName
        if {($markName eq "-")} {
            continue
        }
        setNamedMark -w $w $markName $markPos $markPos $markPos
    }
    # Stylize bold text.
    foreach boldItem [prefs::search::cacheItem "bold"] {
        set pos0 [pos::math -w $w [minPos -w $w] + [lindex $boldItem 0]]
        set pos1 [pos::math -w $w [minPos -w $w] + [lindex $boldItem 1]]
        text::color -w $w $pos0 $pos1 "bold"
    }
    # Colorize red text.
    foreach redItem [prefs::search::cacheItem "red"] {
        set pos0 [pos::math -w $w [minPos -w $w] + [lindex $redItem 0]]
        set pos1 [pos::math -w $w [minPos -w $w] + [lindex $redItem 1]]
        text::color -w $w $pos0 $pos1 "red"
    }
    # Create hyperlinks.
    set hyperlinkPositions [list [minPos -w $w]]
    foreach hyperItem [prefs::search::cacheItem "hyper"] {
        set pos0 [pos::math -w $w [minPos -w $w] + [lindex $hyperItem 0]]
        set pos1 [pos::math -w $w [minPos -w $w] + [lindex $hyperItem 1]]
        text::color -w $w $pos0 $pos1 "green"
        text::hyper -w $w $pos0 $pos1 [lindex $hyperItem 2]
        lappend hyperlinkPositions $pos0 $pos1
    }
    lappend hyperlinkPositions [maxPos -w $w]
    # Highlight our search query.  We go to some trouble to avoid messing up
    # any previously set hyperlinks.
    set scriptStart [list search -w $w -n -all -s -f 1 -r 1 \
      -i $fields(ignoreCase) -m $fields(wordMatch)]
    foreach {posStart posL} $hyperlinkPositions {
        set searchScript $scriptStart
        lappend searchScript -l $posL -- $colorQuery $posStart
        foreach {pos0 pos1} [eval $searchScript] {
            text::color -w $w $pos0 $pos1 1
        }
    }
    # Create our "re-do" hyperlink.
    set pattern "<<prefs::searchForSetting>>"
    set positions [search -w $w -n -f 1 -- $pattern [minPos -w $w]]
    if {[llength $positions]} {
        set pos0 [pos::math -w $w [lindex $positions 0] + 2]
        set pos1 [pos::math -w $w [lindex $positions 1] - 2]
        text::color -w $w $pos0 $pos1 "green"
        text::hyper -w $w $pos0 $pos1 "prefs::searchForSetting"
    }
    help::colourTitle -w $w 5
    win::setInfo $w dirty 0
    win::setInfo $w read-only 1
    refresh -w $w
    if {([set marks [llength [getNamedMarks -w $w]]] > 1)} {
        status::msg "$marks categories listed; see the Marks menu to navigate."
    }
    prefs::search::cacheItem "clear"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::search::cacheItem" --
 # 
 # Create a cache of information to be used we're ready to create the window.
 # If the "args" argument is empty, then we return the given cache contents
 # for the specified "type".
 # 
 # Note that "red" is actually "bold-red".
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::search::cacheItem {type args} {
    
    variable windowCache
    
    if {($type eq "clear")} {
        unset -nocomplain windowCache
        return
    } elseif {![llength $args]} {
        if {[info exists windowCache($type)]} {
            return $windowCache($type)
        } else {
            return ""
        }
    }
    if {[info exists windowCache(text)]} {
        set idx1 [string length $windowCache(text)]
    } else {
        set idx1 "0"
    }
    switch -- $type {
        "bold" {
            append windowCache(text) [lindex $args 0]
            set idx2 [string length $windowCache(text)]
            lappend windowCache(bold) [list $idx1 $idx2]
        }
        "hyper" {
            append windowCache(text) [lindex $args 0]
            set idx2 [string length $windowCache(text)]
            lappend windowCache(hyper) [list $idx1 $idx2 [lindex $args 1]]
        }
        "mark" {
            set markName  [lindex $args 0]
            set markLevel [lindex $args 1]
            if {($markLevel == 1)} {
                lappend windowCache(mark) [list $idx1 "-"]
            }
            set markName "[string repeat "   " [expr {$markLevel - 1}]]$markName"
            lappend windowCache(mark) [list $idx1 $markName]
        }
        "red" {
            append windowCache(text) [lindex $args 0]
            set idx2 [string length $windowCache(text)]
            lappend windowCache(red)  [list $idx1 $idx2]
            lappend windowCache(bold) [list $idx1 $idx2]
        }
        "text" {
            append windowCache(text) [lindex $args 0]
        }
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::search::addPrefToArrayList" --
 # 
 # Used recursively by [prefs::search::findSettings] to add to variables.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::search::addPrefToArrayList {aRef prefSet pref} {
    
    upvar $aRef a
    if {[info exists a($prefSet)]} {
        array set tmp $a($prefSet)
    } else {
        array set tmp [list]
    }
    set tmp($pref) ""
    set a($prefSet) [array get tmp]
    array unset tmp
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::search::displayHelp" --
 # 
 # Add descriptive text about the given preference or package, and cache it 
 # for later use.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::search::displayHelp {aRef pref {index -1} {leftCol 0} {helpPrefix ""}} {
    
    global alpha::application
    
    upvar $aRef a
    
    if {[info exists a(${helpPrefix}${pref})]} {
        set help $a(${helpPrefix}${pref})
        if {$index >= 0} {
            set help [lindex $help $index]
        }
        set help [string trim [lindex [split $help "||"] 0]]
    } else {
        set help ""
    }
    if {($help eq "")} {
        set help "(Sorry, no further information is available.)"
    }
    regsub -all -- {\s+} $help { } help
    regsub -all -- {ÇALPHAÈ} $help $alpha::application help
    regsub -all -- {click this box} $help {turn this item on} help
    if {![regexp {[\.!?][\]\}\)\"\s'>]*$} $help]} {
        append help "."
    }
    prefs::search::cacheItem "text" \
      [string trimright [breakIntoLines $help 77 $leftCol]]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::search::displayPrefsAndHelp" --
 # 
 # Called recursively by [prefs::search::findSettings], cache the collected
 # information for later use in creating the window.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::search::displayPrefsAndHelp {aRef prefSet {helpPrefix ""}} {
    
    upvar $aRef a
    
    array set tmp $a($prefSet)
    foreach pref [lsort -dictionary [array names tmp]] {
        if {[regexp {\s} $pref]} {
            continue
        }
        prefs::search::cacheItem "text" "        "
        prefs::search::cacheItem "bold" [quote::Prettify $pref]
        prefs::search::cacheItem "text" "\r\r"
        prefs::search::displayHelp index::prefshelp \
          $pref -1 12 $helpPrefix
        prefs::search::cacheItem "text" "\r\r"
    }
    array unset tmp
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::search::displayCategoryHeader" --
 # 
 # Create a header for the given category and cache it for later use in
 # creating the window.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::search::displayCategoryHeader {category} {
    
    variable fields
    
    prefs::search::cacheItem "text" "[string repeat {_} 80]\r\r\r"
    prefs::search::cacheItem "red"  "$category preferences"
    prefs::search::cacheItem "mark" "$category preferences" 1
    prefs::search::cacheItem "text" " referring to $fields(representation)\r\r"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::search::matchEvery" --
 # 
 # Called recursively by [prefs::search::findSettings], determine if there
 # are more matches in the given text.  We already matched the first item or
 # we wouldn't be here, so we always start with the second item in the
 # "findList" variable.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::search::matchEvery {text base findList} {
    
    foreach word [lrange $findList 1 end] {
        if {![regexp -- "${base}${word}" $text]} {
            return 0
        }
    }
    return 1
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× User Prefs Files ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval prefs" --
 # 
 # Most of these procedures are called by the "Config > Preferences" menu.
 # 
 # The "prefsHeaderText" variable is used to create the "prefs.tcl" file.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval prefs {

    variable prefsHeaderText {## -*-Tcl-*-
 # --------------------------------------------------------------------------
 # 
 # This file will be sourced automatically, after the ÇALPHAÈ application has
 # been launched (but at the end of the initialization sequence, when all
 # other default packages have been loaded).  You can use this file to insert
 # your own preferences and changes, rather than altering the originals.
 # 
 # You can redefine menus, procedures, variables,...
 # 
 # This assumes that you know a little bit about how Tcl and AlphaTcl works.
 # See the "AlphaDev Menu > AlphaDev Help Files" menu for more information 
 # about specific topics.  Or highlight this line
 # 
 #     help::openGeneral "Extending Alpha"
 # 
 # and select the "Tcl Menu > Evaluate" command for an introduction.
 # 
 # --------------------------------------------------------------------------
 ##

}
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::editPrefsFile" --
 # 
 # Open the "$PREFS/prefs.tcl" file, creating it if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::editPrefsFile {} {
    return [edit -c [prefs::createPrefsFile]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::createPrefsFile" --
 # 
 # If the "$PREFS/prefs.tcl" file already exists, we do nothing.  Otherwise
 # we create it, adding an informative header.
 # 
 # This returns the full path of the prefs file.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::createPrefsFile {{askToCreate "1"}} {
    
    global PREFS alpha::application
    
    variable prefsHeaderText
    
    set q "No global prefs file exists.\rDo you want to create one?"
    if {[file exists [set f [file join $PREFS prefs.tcl]]]} {
	return $f
    } elseif {$askToCreate && ![dialog::yesno $q]} {
	error "Cancelled."
    } else {
	regsub -all -- {ÇALPHAÈ} $prefsHeaderText $alpha::application header
	file::writeAll $f $header 1
    }
    return $f
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::addGlobalPrefsLine" --
 # 
 # Automatically add text to the user's "$PREFS/prefs.tcl" file.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::addGlobalPrefsLine {line} {
    return [prefs::addPrefsFileLine $line "global"]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::addPrefsFileLine" --
 # 
 # Automatically add text to either the "<mode>Prefs.tcl" or "prefs.tcl" file
 # in the user's $PREFS folder.  -trf
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::addPrefsFileLine {line {modeOrGlobal ""}} {
    
    global PREFS tcl_platform alpha::platform
    
    if {($modeOrGlobal eq "")} {
	set modeOrGlobal [win::getMode]
    } 
    if {($modeOrGlobal eq "global")} {
	set f [file join $PREFS prefs.tcl]
    } else {
	set f [file join $PREFS ${modeOrGlobal}Prefs.tcl]
    }
    if {![file exists $PREFS]} {
	file mkdir $PREFS
    }
    if {[llength [set alreadyOpen [file::hasOpenWindows $f]]]} {
	# Our file already exists and is open as a window.
	bringToFront [set w [lindex $alreadyOpen 0]]
	set pos [getPos -w $w]
	goto [maxPos -w $w]
	if {[lindex [pos::toRowChar -w $w $pos] 1] != 0} {
	    set line "\r$line"
	}
	insertText -w $w $line
	save $w
	goto -w $w $pos
	status::msg "Your \"[file tail $f]\" file was saved\
	  with the necessary changes."
	return
    }
    if {![file exists $f]} {
	# Our file doesn't exist, so we create it.
	if {($modeOrGlobal eq "global")} {
	    set f [prefs::createPrefsFile 0]
	} else {
	    set f [mode::createPrefsFile $modeOrGlobal 0]
	}
    }
    # Now we know that our file exists.
    set fid [alphaOpen $f "a+"]
    if {![catch {seek $fid -1 end}] && ![is::Eol [read $fid 1]]} {
	set line "\r$line"
    }
    seek $fid 0 end
    puts $fid $line
    close $fid
    status::msg "Your \"[file tail $f]\" file was modified\
      with the necessary changes."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval mode" --
 # 
 # Most of these procedures are called by the "Config > Mode Prefs" menu.
 # 
 # The "prefsHeaderText" variable is used to create "<mode>Prefs.tcl" files.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval mode {

    variable prefsHeaderText {## -*-Tcl-*-
 # --------------------------------------------------------------------------
 # 
 # This file will be sourced automatically, immediately after the _first_
 # time the file which defines "ÇMODEÈ" mode is sourced.  You can use this
 # file to insert your own mode-specific preferences and changes, rather than
 # altering the originals.
 # 
 # You can redefine menus, procedures, variables,...
 # 
 # This assumes that you know a little bit about how Tcl and AlphaTcl works.
 # See the "AlphaDev Menu > AlphaDev Help Files" menu for more information 
 # about specific topics.  Or highlight this line
 # 
 #     help::openGeneral "Extending Alpha"
 # 
 # and select the "Tcl Menu > Evaluate" command for an introduction.
 # 
 # --------------------------------------------------------------------------
 ##

}
}

## 
 # --------------------------------------------------------------------------
 # 
 # "mode::editPrefsFile" --
 # 
 # If no "<mode>Prefs.tcl" exists, offer to create it, adding some useful
 # header information.  If it already exists, we just open it for editing.
 # 
 # --------------------------------------------------------------------------
 ##

proc mode::editPrefsFile {{m ""}} {
    
    set w [edit -c [mode::createPrefsFile $m]]
    hook::callAll mode::editPrefsFile
    return $w
}

## 
 # --------------------------------------------------------------------------
 # 
 # "mode::createPrefsFile" --
 # 
 # If the file already exists, we do nothing.  Otherwise we offer to create
 # the prefs file for the specified mode, and add an informative header.  A
 # "cancel" error is returned if the user declines.
 # 
 # This returns the full path of the mode's prefs file.
 # 
 # --------------------------------------------------------------------------
 ##

proc mode::createPrefsFile {{m ""} {askToCreate "1"}} {
    
    global PREFS
    
    variable prefsHeaderText
    
    if {($m eq "") && ([set m [win::getMode]] eq "")} {
	error "Cancelled -- The current mode is not defined."
    } elseif {![mode::exists $m]} {
	# The given 'm' must be a valid mode.
	error "Cancelled -- \"$m\" mode doesn't exist!"
    }
    set q "No '$m' prefs file exists.\rDo you want to create one?"
    if {[file exists [set f [file join $PREFS ${m}Prefs.tcl]]]} {
	return $f
    } elseif {$askToCreate && ![dialog::yesno $q]} {
	error "Cancelled."
    } else {
	regsub -all -- {ÇMODEÈ} $prefsHeaderText $m header
	file::writeAll $f $header 1
    }
    return $f
}

## 
 # --------------------------------------------------------------------------
 # 
 # "mode::sourcePrefsFile" --
 # 
 # Called by the "Config > Mode Prefs > Source Prefs File" menu command,
 # source a "<mode>Prefs.tcl" file.  Fixes 'uplevel #0' problem.
 # 
 # --------------------------------------------------------------------------
 ##

proc mode::sourcePrefsFile {{m ""}} {
    
    global PREFS
    
    if {($m eq "") && ([set m [win::getMode]] eq "")} {
	error "Cancelled -- The current mode is not defined."
    } elseif {![file exists [set f [file join $PREFS ${m}Prefs.tcl]]]} {
	error "Cancelled -- No preferences file exists for '$m' mode."
    } else {
	return [uplevel \#0 [list source $f]]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "mode::addModePrefsLine" --
 # 
 # Add text to the "<mode>Prefs.tcl" file in the user's $PREFS folder.
 # 
 # --------------------------------------------------------------------------
 ##

proc mode::addModePrefsLine {line {m ""}} {
    return [prefs::addPrefsFileLine $line $m]
}

# ===========================================================================

namespace eval prefs {}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::tclEdit" --
 # "prefs::tclAddLine" --
 # "prefs::tclAddModeLine" --
 # 
 # These are back compatibility procedures, wrappers around the ones that 
 # should be called.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::tclEdit {} {
    return [prefs::editPrefsFile]
}

proc prefs::tclAddLine {line} {
    return [prefs::addGlobalPrefsLine $line]
}

proc prefs::tclAddModeLine {line {modeOrGlobal ""}} {
    return [prefs::addPrefsFileLine $line $modeOrGlobal]
}

# ===========================================================================
# 
# .