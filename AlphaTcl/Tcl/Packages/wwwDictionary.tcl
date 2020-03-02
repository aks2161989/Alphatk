## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "wwwDictionary.tcl"
 #                                          created: 05/05/2002 {11:14:09 pm}
 #                                      last update: 02/28/2006 {04:10:13 PM}
 #                               
 # Description:
 # 
 # Inserts a "Utils > Www Dictionary" submenu, allowing for access to online
 # dictionary, thesaurus, etc services.  Also include a Contextual Menu
 # module with the same name.
 # 
 # Note: None of these procedures have been designed to be called by any
 # other code -- they all assume that the package has been activated by the
 # user using standard AlphaTcl routines.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # Copyright (c) 2002-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::feature wwwDictionary 1.0.1 "global-only" {
    # Initialization script.
    # Call this special initialization script.
    dictionary::www::initializePackage
} {
    # Activation script.
    menu::insert   Utils items 0 "(-)"
    menu::insert   Utils submenu "(-)" "wwwDictionary"
} {
    # De-activation script.
    menu::uninsert Utils submenu "(-)" "wwwDictionary"
} preinit {
    # Contextual Menu module.  Placed here so that it can be turned on even
    # if this package isn't formally activated.

    # Includes items to look up words in a variety of web-based dictionaries,
    # displaying them either in ÇALPHAÈ or your local browser as specified by
    # your "View Html" preference
    newPref f "wwwDictionary Menu" 0 contextualMenu
    menu::buildProc "wwwDictionary " {dictionary::www::buildMenu "contextual"} \
      {dictionary::www::postMenuBuild}
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    This package creates a new "Utils > Www Dictionary" submenu, which
    allows words to be looked up in on-line resources
} help {
    This package creates a new "Utils > Www Dictionary" submenu, which allows
    words to be looked up in on-line web sites.
    
    Preferences: Features
    
    After this package has been turned on, simply select the desired menu
    item, enter the word to be queried in the prompt dialog, and then press
    'OK' to open a web browser for the specified service.
    
    The url containing the dictionary contents for the given word will be
    displayed using Alpha's WWW service as specified by the "View Urls Using"
    preference.  This could be your locally installed web browser or Alpha's
    internal text renderer enabled by the package: wwwMenu .
    
    Preferences: Helpers-viewURL
    
    The url for each on-line service can be changed by selecting the menu
    item "Utils > Www Dictionary > Language Settings > Edit Languages", and
    should include everything required for the url except the word.  For
    example, if the <http://www.m-w.com/> site is used, the 'Dictionary' url
    setting should be
    
	http://www.m-w.com/cgi-bin/dictionary?

    in order to open the page <http://www.m-w.com/cgi-bin/dictionary?test>.

    Many of the default 'English' settings are for the on-line resources
    available at <http://www.cogsci.princeton.edu/~wn/>.  This is the home
    page for 'WordNet', a lexical database for the English Language provided
    by the Cognitive Science Laboratory at Princeton University.  This site
    maintains Antonym, Hypernym, Meronym, and Synonym databases.
    
    This package allows you to set different 'Languages', each of which has
    its own urls for looking up the given word, including translation from
    one Language to another.  Additional Languages can be added using the
    menu item "Utils > Www Dictionary > Language Settings > New Language".
    All Language settings can always be edited later, and entire Language
    packages can be deleted or renamed.
    
    The "Utils > Www Dictionary > Current Language" submenu displays the
    default Current Lanuage used in all utility dialogs.  Selecting any item
    in this submenu will change the Current Lanaguage to that value.
    
    As with any package that relies primarily on the correct location of
    remote web pages over which we have no control, the urls for any of these
    Languages might be (re)moved or the proper syntax for queries might
    change.  As of this writing the package's current maintainer rarely makes
    use of any Language other than English, and his grasp of that is often
    poor, so other updates will have to come from other users.  ;)
    
    If you have any suggestions for better settings for any of the default
    Languages, or a new Language package to contribute, please send the urls
    to this package's maintainer and they will be included in the next
    update.  If you have a Language site that accepts searches but are having
    trouble resolving the proper url setting to use, please ask on one of the
    mailing lists described in the "Readme" file.
    
    Tip: you can also define a 'Language' for any on-line database that
    accepts queries, such as a 'Cell And Molecular Biology' Language that
    uses urls like <http://www.mblab.gla.ac.uk/~julian/dict2.cgi?neuron>.
    
    A Contextual Menu module with this menu is also available, which will
    automatically send the word surrounding the Contextual Menu Click Point
    (i.e. the mouse position) to the on-line service unless the text
    surrounding the mouse position is ambiguous.
    
    Preferences: ContextualMenu

    This module is available without having to first activate this package
    (inserting the menu into the Utils menu) -- simply adjust the Contextual
    Menu prefs, checking the box next to 'Www Dictionary Menu'.
}

proc wwwDictionary.tcl {} {}

namespace eval dictionary::www {

    # This might be used in [dictionary::www::wwwUtility] dialogs.
    variable lastSearchString ""
    
    variable utilityOptions [list "dictionary" "thesaurus" "-" \
      "antonyms" "hypernyms" "meronyms" "synonyms"] 
}

proc dictionary::www::initializePackage {} {
    
    global invisibleModeVars
    
    variable initialized
    variable languageSettings
    variable version
    
    if {[info exists initialized]} {
	return
    }
    if {![info exists version]} {
	set version 0
    }
    # Register a build proc for the menu.
    menu::buildProc "wwwDictionary" {dictionary::www::buildMenu} \
      {dictionary::www::postMenuBuild}
    # Add a new "Packages" prefs dialog pane.
    package::addPrefsDialog wwwDictionary
    
    # The first time that we source this file, we ensure that anything from
    # earlier versions of this package are in the proper namespace, and we
    # rename variables as necessary.
    if {($version < 1.0)} {
	# Transfer any previously saved variables from the "dictionary"
	# namespace to "dictionary::www".  This will allow other packages to
	# also be children within the "dictionary" namespace, such as
	# "dictionary::local".
	global dictionary::Version dictionary::Languages
	if {[info exists dictionary::Version]} {
	    prefs::removeObsolete dictionary::Version
	} 
	if {[info exists dictionary::Languages]} {
	    foreach n [array names ::dictionary::Languages] {
		set languageSettings($n) [set dictionary::Languages($n)]
		prefs::modified languageSettings($n)
		prefs::removeObsolete dictionary::Languages($n)
	    }
	}
    }
    
    # Package preferences.
    
    prefs::renameOld dictionarymodeVars(language) \
      wwwDictionarymodeVars(currentWwwLanguage)
    # The Current WWW Language used as the default for Www Dictionary Utilities.
    newPref var currentWwwLanguage "English" wwwDictionary \
      dictionary::www::rebuildMenu dictionary::www::LanguagesList varitem
    # No need to include this in the dialog.
    set invisibleModeVars(currentWwwLanguage) 1
    
    newPref menubinding antonyms   "" wwwDictionary {dictionary::www::rebuildMenu}
    newPref menubinding dictionary "" wwwDictionary {dictionary::www::rebuildMenu}
    newPref menubinding hypernyms  "" wwwDictionary {dictionary::www::rebuildMenu}
    newPref menubinding meronyms   "" wwwDictionary {dictionary::www::rebuildMenu}
    newPref menubinding synoynyms  "" wwwDictionary {dictionary::www::rebuildMenu}
    newPref menubinding thesaurus  "" wwwDictionary {dictionary::www::rebuildMenu}
    
    # Make sure that we have up-to-date default settings.
    dictionary::www::defaultUrls
    if {($version < 1.0)} {
	dictionary::www::updateDefaults
	# We need to save the current version variable.
	set version 1.0
	prefs::modified version
    }
    # Make sure that we have a "currentLanguage" variable defined.
    dictionary::www::currentLanguage
    
    # No need to run through this routine again.
    set initialized 1
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Language Settings ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::defaultUrls"  ---
 # 
 # Define some default values for urls.  If new items are added (or if any old
 # ones are deleted), make sure that [dictionary::www::editLanguages] is
 # adjusted accordingly.
 # 
 # This proc has to be defined before any of the default word projects are
 # added below.  The 'default' Language is a valid group that can be edited
 # by the user like any other, and is primarily defined so that adding a new
 # group can have some default settings automatically in the dialog.
 # 
 # --------------------------------------------------------------------------
 ## 

proc dictionary::www::defaultUrls {} {
    
    variable languageSettings
    
    if {[info exists languageSettings(default)]} {
	set languageSettings(default)
    } else {
	set languageSettings(default) [list \
	  dictionary {http://www.m-w.com/cgi-bin/dictionary?} \
	  thesaurus  {http://machaut.uchicago.edu/cgi-bin/ROGET.sh?word=} \
	  antonyms   "" hypernyms "" meronyms "" synoynyms "" ]
    }
    return $languageSettings(default)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::updateDefaults"  ---
 # 
 # If anybody has any suggestions on how to improve the default settings
 # here, please let me know !!
 # 
 # If the settings exist, then these should've been set at some point in the
 # past, so we don't do it again, in case the user actually wanted to delete
 # them!  This will automatically set the "default" project, which will never
 # be removed.
 # 
 # When updating the settings for new versions of this package, we'll only
 # overwrite if the user has not previously saved different settings, but
 # we'll re-create if the user has deleted them.  This also allows us to
 # change the number/type of urls to be set if this package is updated.
 # 
 # --------------------------------------------------------------------------
 ## 

proc dictionary::www::updateDefaults {} {
    
    dictionary::www::languageSettings "English" [list \
      dictionary {http://www.m-w.com/cgi-bin/dictionary?} \
      thesaurus  {http://machaut.uchicago.edu/cgi-bin/ROGET.sh?word=} \
      antonyms   {http://www.cogsci.princeton.edu/cgi-bin/webwn1.7.1?stage=2&posnumber=1&searchtypenumber=1&senses=&showglosses=1&word=} \
      hypernyms  {http://www.cogsci.princeton.edu/cgi-bin/webwn1.7.1?stage=2&posnumber=1&searchtypenumber=-2&senses=&showglosses=1&word=} \
      meronyms   {http://www.cogsci.princeton.edu/cgi-bin/webwn1.7.1?stage=2&posnumber=1&searchtypenumber=12&senses=&showglosses=1&word=} \
      synoynyms  {http://www.cogsci.princeton.edu/cgi-bin/webwn1.7.1?stage=2&posnumber=1&searchtypenumber=2&senses=&showglosses=1&word=} ]

    dictionary::www::languageSettings "English -> French" [list \
      dictionary {http://www.wordreference.com/fr/translation.asp?enfr=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]
    
    dictionary::www::languageSettings "English -> German" [list \
      dictionary {http://www.wordreference.com/de/translation.asp?ende=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]
    
    dictionary::www::languageSettings "English -> Italian" [list \
      dictionary {http://www.wordreference.com/it/translation.asp?enit=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]
    
    dictionary::www::languageSettings "English -> Spanish" [list \
      dictionary {http://www.wordreference.com/es/translation.asp?tranword=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]
    
    dictionary::www::languageSettings "English -> Swedish" [list \
      dictionary {http://www-lexikon.nada.kth.se/cgi-bin/skolverket/eng-swe?} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "French" [list \
      dictionary {http://www.francophonie.hachette-livre.fr/cgi-bin/hysearch2?} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]
    
    dictionary::www::languageSettings "French -> English" [list \
      dictionary {http://www.wordreference.com/fr/en/translation.asp?fren=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "German" [list \
      dictionary {} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "German -> English" [list \
      dictionary {http://www.wordreference.com/de/en/translation.asp?deen=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "Italian" [list \
      dictionary {http://www.garzantilinguistica.it/digita/parola.html?&parola=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "Italian -> English" [list \
      dictionary {http://www.wordreference.com/it/en/translation.asp?ite} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "Spanish" [list \
      dictionary {} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "Spanish -> English" [list \
      dictionary {http://www.wordreference.com/es/en/translation.asp?spen=} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "Swedish" [list \
      dictionary {} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]

    dictionary::www::languageSettings "Swedish -> English" [list \
      dictionary {http://www-lexikon.nada.kth.se/cgi-bin/skolverket/sve-eng?exempel} \
      thesaurus  {} \
      antonyms   "" hypernyms "" meronyms "" synoynyms "" ]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::listLanguages"  ---
 # 
 # Return a sorted list of all registered languages.  We also set the
 # variable "dictionary::www::LanguagesList" here, which is used as the list
 # for the wwwDictionarymodeVars(currentWwwLanguage) list of options.
 # 
 # --------------------------------------------------------------------------
 ## 

proc dictionary::www::listLanguages {} {
    
    variable languageSettings
    variable LanguagesList
    variable languages

    set languages [lsort -dictionary [array names languageSettings]]
    if {([llength $languages] > 1)} {
	set LanguagesList [concat [list "default" "-" ] \
	  [lremove [lsort -dictionary [array names languageSettings]] "default"]]
    } else {
	set LanguagesList [list "default"]
    }
    return $languages
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::languageSettings"  ---
 # 
 # Ensure that the settings for the given Language exist, creating it if
 # necessary.  Returns '1' if the Language was created, otherwise '0'.  The
 # "settings" argument must be a even-numbered list consisting of
 # 
 #     utility url ?utility url? ...
 # 
 # New values for the settings will be created only if "reset" is "1",
 # otherwise we retain any changes made previously by the user.
 # 
 # --------------------------------------------------------------------------
 ## 

proc dictionary::www::languageSettings {language settings {reset 0}} {
    
    variable languageSettings
    variable languages
    
    dictionary::www::listLanguages
    if {$reset} {
	unset -nocomplain languageSettings($language)
    }
    if {[info exists languageSettings($language)]} {
	return 0
    } else {
	set languageSettings($language) $settings
	prefs::modified languageSettings($language)
	return 1
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::currentLanguage"  ---
 # 
 # Optionally sets a new Current Language, ensures that the Current Language
 # actually exists, and ensure that some variables are up to date for the
 # calling proc.
 # 
 # --------------------------------------------------------------------------
 ## 

proc dictionary::www::currentLanguage {{newLanguage ""}} {
    
    global wwwDictionarymodeVars

    variable languageSettings
    
    variable currentLanguage
    variable languages
    variable settings

    if {![info exists currentLanguage]} {
        set currentLanguage $wwwDictionarymodeVars(currentWwwLanguage)
    }
    # Create a list of all languages available.  If we don't have any
    # languages available, we still need to define the variables.
    dictionary::www::listLanguages
    if {![llength $languages]} {
	set currentLanguage ""
	set settings [dictionary::www::defaultUrls]
	return
    }
    # Determine the Current Language.
    if {[string length $newLanguage]} {
	# Make 'newLanguage' the Current Language.
	set wwwDictionarymodeVars(currentWwwLanguage) $newLanguage
	set currentLanguage $newLanguage
    }
    # Make sure that the Current Language exists.
    if {![lcontains languages $currentLanguage]} {
	set wwwDictionarymodeVars(currentWwwLanguage) [lindex $languages 0]
	set currentLanguage [lindex $languages 0]
    }
    # Update the current settings for Www Utilities.
    set settings $languageSettings($currentLanguage)
    return $currentLanguage
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Editing Languages ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::newLanguage" "dictionary::www::newLanguageDetails"  --
 # 
 # Create a new Language, using the info from the current page as the default
 # if available.  We then re-direct to [dictionary::www::editLanguages].
 # 
 # "dictionary::www::editLanguages" --
 # 
 # Open a dialog which contains pages for all languages, allowing the user to
 # create a new Language or to set urls.
 # 
 # [dictionary::www::newLanguageDetails] is called by the dialog if the user
 # is adding a new Language.
 # 
 # --------------------------------------------------------------------------
 ##

proc dictionary::www::newLanguage {} {
    
    set results  [dictionary::www::newLanguageDetails]
    set name     [lindex $results 0]
    set settings [lindex $results 1]
    dictionary::www::languageSettings $name $settings
    dictionary::www::currentLanguage $name
    dictionary::www::rebuildMenu
    dictionary::www::editLanguages
    return
}

proc dictionary::www::newLanguageDetails {} {
    
    set p    "New Language"
    set name ""
    while {1} {
	set name [prompt $p $name]
	if {![string length $name]} {
	    status::msg "No Language was entered."
	} elseif {[lcontains languages $name]} {
	    alertnote "'$name' is already a defined Language."
	    set p "Try another name"
	} else {
	    break
	}
    }
    return [list $name [dictionary::www::defaultUrls]]
}

proc dictionary::www::editLanguages {} {

    variable currentLanguage
    variable languageSettings
    variable languages

    set results [dialog::editGroup -array languageSettings -delete ask \
      -new dictionary::www::newLanguageDetails \
      -title "Edit WWW Dictionary settings" \
      -current $currentLanguage \
      [list "dictionary" url "Dictionary"\
      "This is the url for dictionary queries"] \
      [list "thesaurus" url "Thesaurus"\
      "This is the url for thesaurus queries"] \
      [list "antonyms" url "Antonyms"\
      "This is the url for antonym queries"] \
      [list "hypernyms" url "Hypernyms"\
      "This is the url for hypernym queries"] \
      [list "meronyms" url "Meronyms"\
      "This is the url for meronym queries"] \
      [list "synoynyms" url "Synoynyms"\
      "This is the url for synoynym queries"] \
      ]
    if {![llength $results]} {
	return
    }
    set ::testResults $results
    # This works whether languages have been modified or deleted.
    foreach languagePage $results {
	if {![lcontains languages $languagePage]} {
	    # This is a new Language, so we'll make it Current.
	    dictionary::www::currentLanguage $languagePage
	}
	prefs::modified languageSettings($languagePage)
    }
    # Make sure that the 'default' Language wasn't deleted !!
    dictionary::www::languageSettings "default" [dictionary::www::defaultUrls]
    # Should now rebuild the menu in case we've added or removed a Language.
    # [dictionary::www::currentLanguage] will make sure that the Current
    # Language still exists, and adjust accordingly.
    dictionary::www::currentLanguage
    dictionary::www::rebuildMenu
    return
}

proc dictionary::www::renameLanguage {} {
    
    variable languageSettings

    variable currentLanguage
    variable languages
    variable settings

    set p "Rename which Language?"
    while {1} {
	set languages [lremove $languages "default"]
	set result  [listpick -p $p -L [list $currentLanguage] $languages]
	set newName [prompt "Rename '$result' to" "$result"]
	if {[lcontains languages $newName]} {
	    alertnote "'$newName' is already defined as a Language"
	} else {
	    set languageSettings($newName) $languageSettings($result)
	    prefs::modified languageSettings($result)
	    unset languageSettings($result)
	    dictionary::www::currentLanguage
	    if {![lcontains languages $currentLanguage]} {
		dictionary::www::currentLanguage [lindex $languages 0]
	    }
	    dictionary::www::rebuildMenu $currentLanguage
	    set p "Choose another, or cancel"
	}
    }
    return
}

proc dictionary::www::deleteLanguage {} {
    
    variable languageSettings
    
    variable currentLanguage
    variable languages

    set options [lremove [dictionary::www::listLanguages] "default"]
    set results [listpick -p "Delete which languages?" -l $options]
    foreach l $results {
	if {[info exists languageSettings($l)]} {
	    prefs::modified languageSettings($l)
	    unset languageSettings($l)
	}
    }
    dictionary::www::listLanguages
    dictionary::www::currentLanguage
    dictionary::www::rebuildMenu $currentLanguage
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::resetToDefaults"  --
 # 
 # Since we attempt to retain any changes made by the user not only between
 # editing sessions but also whenever this package is updated, it is possible
 # that the user's urls are out of date.  This procedure will restore them
 # to the current defaults in this file.
 # 
 # --------------------------------------------------------------------------
 ##

proc dictionary::www::resetToDefaults {} {
    
    variable languageSettings
    variable languages
    
    set q "For each currently defined Language, you will be asked if you\
      want to delete any changes you have made to the default settings. \
      Any \"missing\" Languages that you have deleted be will restored."
    if {![dialog::yesno -y "Continue" -n "Cancel" $q]} {
	status::msg "Cancelled."
        return
    }
    # Create a list of languages to restore, and ask about each one.
    dictionary::www::listLanguages
    set restoreList [list]
    foreach n $languages {
	if {[dialog::yesno -c "Restore settings for \"${n}\" ?"]} {
	    lappend restoreList $n
	} 
    }
    # Remove the settings for the chosen languages.
    foreach n $restoreList {
	set lastChanceSettings($n) $languageSettings($n)
	prefs::remove dictionary::www::languageSettings($n)
	unset -nocomplain languageSettings($n)
    }
    # Restore any default settings that we have.
    dictionary::www::defaultUrls
    dictionary::www::updateDefaults
    # Did we delete anything that didn't get restored?
    foreach n $restoreList {
	if {![info exists languageSettings($n)]} {
	    set q "The settings for the Language \"${n}\" are missing. \
	      Would you like to restore them to the previous values?"
	    if {[dialog::yesno $q]} {
	        dictionary::www::languageSettings $n $lastChanceSettings($n) 1
	    }
	}
    }
    dictionary::www::rebuildMenu
    status::msg "All specified defaults have been restored."
    return
    
}

# ×××× Www Dictionary menus ×××× #

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::buildMenu"  --
 # 
 # Build the submenu, either for the menubar 'Utils' menu or for the
 # Contextual Menu.  If the first case, also include ellipses to indicate
 # that we're going to always prompt the user for a word to query.  If the
 # second case, we're going to try to use the word surrounding the click
 # position if possible.  (If there's a large selection of highlighted text
 # surrounding the click position, we're not exactly sure what the user wants
 # to do so we'll ask.)
 # 
 # --------------------------------------------------------------------------
 ##

proc dictionary::www::buildMenu {{which "menubar"}} {
    
    global alpha::CMArgs
    
    # Make sure that we have all necessary variables in place.
    dictionary::www::initializePackage

    switch -- $which {
	"menubar"    {set dots 1}
	"contextual" {
	    set pos1 [lindex ${alpha::CMArgs} 1]
	    set pos2 [lindex ${alpha::CMArgs} 2]
	    if {[pos::diff $pos1 $pos2]} {
		set dots [regexp "\[\r\n\t \]" [getText $pos1 $pos2]]
	    } else {
		set txt  [lindex [contextualMenu::clickWord] 0]
		set len  [string length $txt]
	        set dots [expr {$len ? 0 : 1}]
	    }
	}
	default {error "Unknown menu: $which"}
    }
    set menuList [dictionary::www::listUtilities $dots]
    lappend menuList [menu::makeFlagMenu currentLanguage \
      list currentWwwLanguage wwwDictionarymodeVars {dictionary::www::rebuildMenu}]
    lappend menuList [list Menu -n languageSettings -p "dictionary::www::menuProc" \
      [list "newLanguageÉ" "editLanguagesÉ" "renameLanguageÉ" "deleteLanguageÉ" \
      "(-)" "resetToDefaultsÉ" \
      ]]
    lappend menuList "(-)" "dictionaryPrefsÉ" "dictionaryHelp"
    
    return [list build $menuList dictionary::www::menuProc {}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "dictionary::www::listUtilities"  --
 # 
 # Create the list of Language Utilities available.  'Dictionary' and
 # 'Thesaurus' are always included in the menu.  Others are only added if
 # there's a valid url available.
 # 
 # --------------------------------------------------------------------------
 ##

proc dictionary::www::listUtilities {{withDots 0}} {
    
    global wwwDictionarymodeVars

    variable settings

    array set utils $settings
    
    set results [list]
    foreach utility [list "dictionary" "thesaurus"] {
	if {![string length $utils($utility)]} {
	    lappend results1 ($utility
	} else {
	    lappend results1 $wwwDictionarymodeVars($utility)$utility
	}
    }
    foreach utility [list "antonyms" "hypernyms" "meronyms" "synoynyms"] {
	if {[string length $utils($utility)]} {
	    lappend results2 $wwwDictionarymodeVars($utility)$utility
	}
    }
    if {[info exists results2]} {
        set results1 [concat $results1 "(-)" $results2 "(-)"]
    } else {
        lappend results1 "(-)"
    }
    if {$withDots} {
	foreach utility $results1 {
	    if {($utility eq "(-)")} {
		lappend results3 $utility
	    } else {
		lappend results3 ${utility}É
	    }
	}
	set results $results3
    } else {
	set results $results1
    }
    return $results
}

proc dictionary::www::postMenuBuild {args} {
    
    variable languages
    
    if {([llength $languages] == "1")} {
	enableMenuItem languageSettings deleteLanguageÉ 0
	enableMenuItem languageSettings renameLanguageÉ 0
    }
    return
}

# This is only called to rebuild the menubar's menu.
proc dictionary::www::rebuildMenu {args} {

    variable currentLanguage
    
    if {[llength $args]} {
	# Make sure that our language is up to date.
	dictionary::www::currentLanguage [lindex $args 0]
	set msg "The Current Language is now '$currentLanguage'"
    } else {
	set msg "The 'Www Dictionary' menu has been rebuilt."
    }
    menu::buildSome wwwDictionary
    status::msg $msg
    return
}

proc dictionary::www::menuProc {menuName itemName} {
    
    switch -- $menuName {
	"languageSettings" {
	    dictionary::www::$itemName
	    return
	}
	default {
	    switch -- $itemName {
		"dictionaryPrefs" {
		    prefs::dialogs::packagePrefs "wwwDictionary"
		    return
		}
		"dictionaryHelp" {
		    package::helpWindow   "wwwDictionary"
		    return
		}
	    }
	}
    }
    # Still here? Convert the utility name and pass it on.
    set utility [string tolower $itemName]
    if {($menuName eq "wwwDictionary")} {
	set alwaysPrompt 1
    } else {
	set alwaysPrompt 0
    }
    set hint [dictionary::www::getWord $menuName]
    dictionary::www::wwwUtility $utility $hint $alwaysPrompt
    return
}

# This version has some dialog issues that need to be resolved.

# proc dictionary::www::wwwUtility {utility {hint ""} {alwaysPrompt 1}} {
#     
#     variable currentLanguage
#     variable languages
#     variable languageSettings
#     variable lastSearchString
#     variable settings
#     variable utilityOptions
#     
#     set oldLanguage $currentLanguage
#     set msg "Current Language is '$currentLanguage'"
#     if {!$alwaysPrompt && [string length $hint]} {
# 	set word $hint
#     } else {
#         set word ""
# 	set lastSearchString $hint
#     }
#     while {![string length $word] || [regexp "\t| " $word]} {
# 	status::msg $msg
# 	if {![string length $word]} {
# 	    set word $lastSearchString
# 	}
# 	status::msg $msg
# 	set title "Search WWW Resources"
# 	set dT [list dialog::make -title $title -defaultpage $currentLanguage]
# 	set length [llength $languages]
# 	for {set i 0} {($i < $length)} {incr i} {
# 	    set dummySpace [string repeat " " $i]
# 	    # Create a list of the current valid utilities for this language.
# 	    set l [lindex $languages $i]
# 	    set options [list]
# 	    array set tempSettings $languageSettings($l)
# 	    foreach u $utilityOptions {
# 		if {($u eq "-") && [llength $options]} {
# 		    lappend options $u
# 		} 
# 		if {[info exists tempSettings($u)] \
# 		  && [string length $tempSettings($u)]} {
# 		    lappend options [string totitle $u]
# 		} 
# 	    }
# 	    if {[lindex $options end] eq "-"} {
# 		set options [lreplace $options end end]
# 	    } 
# 	    set     d$i [list "$l"]
# 	    lappend d$i [list var "Search string:" $word]
# 	    lappend d$i [list [list "menu" $options] "$dummySpace" $utility]
# 	    if {$i == [expr {$length - 1}]} {
# 		lappend d$i [list thepage "This item is invisible" ""]
# 	    } 
# 	    lappend d [set d$i]
# 	}
# 	set values [eval $dT $d]
# 	# Parse out the last dialog pane and its values
# 	set idx1 [lsearch $languages [set l [lindex $values end]]]
# 	set word [lindex $values [set idx2 [expr {$idx1 * 2}]]]
# 	set Util [lindex $values [set idx3 [expr {$idx2 + 1}]]]
# 	set utility [string tolower $Util]
# 	listpick [list $l $word $Util]
# 	return
# 	dictionary::www::currentLanguage $l
# 	if {![string length $word]} {
# 	    set msg "Nothing was entered."
# 	} elseif {[regexp "\t| " $word]} {
# 	    set msg "Only a single word can be queried."
# 	} else {
# 	    break
# 	}
#     }
#     set lastSearchString $word
#     array set utils $settings
#     if {![info exists utils($utility)] || ![string length $utils($utility)]} {
# 	status::msg "Sorry, no '$utility' url is available\
# 	  for the Language \"${currentLanguage}\"."
#     } else {
# 	urlView $utils($utility)[string tolower $word]
#     }
#     if {($currentLanguage ne $oldLanguage)} {
# 	dictionary::www::currentLanguage $oldLanguage
#     }
#     return
# }

proc dictionary::www::wwwUtility {utility {hint ""} {alwaysPrompt 1}} {
    
    variable currentLanguage
    variable languages
    variable lastSearchString
    variable settings
    
    set oldLanguage $currentLanguage
    set msg "Current Language is '$currentLanguage'"
    if {!$alwaysPrompt && [string length $hint]} {
	set word $hint
    } else {
	set word ""
	set lastSearchString $hint
    }
    while {![string length $word] || [regexp "\t| " $word]} {
	status::msg $msg
	if {![string length $word] && [catch {getSelect} word]} {
	    set word ""
	}
	if {![string length $word]} {
	    set word $lastSearchString
	}
	status::msg $msg
	set title "Search WWW $utility"
	set     d1 [list dialog::make -title $title]
	set     d2 [list " "]
	lappend d2 [list var "Search string:" $word]
	lappend d2 [list [list "menu" $languages] "Language" $currentLanguage]
	set values [eval $d1 [list $d2]]
	set word [lindex $values 0]
	dictionary::www::currentLanguage [lindex $values 1]
	if {![string length $word]} {
	    set msg "Nothing was entered."
	} elseif {[regexp "\t| " $word]} {
	    set msg "Only a single word can be queried."
	} else {
	    break
	}
    }
    set lastSearchString $word
    array set utils $settings
    if {![info exists utils($utility)] || ![string length $utils($utility)]} {
	status::msg "Sorry, no '$utility' url is available\
	  for the Language \"${currentLanguage}\"."
    } else {
	urlView $utils($utility)[string tolower $word]
    }
    if {($currentLanguage ne $oldLanguage)} {
	dictionary::www::currentLanguage $oldLanguage
    }
    return
}

proc dictionary::www::getWord {menuName} {
    
    global alpha::CMArgs
    
    if {![llength [winNames]]} {
        return ""
    } 
    switch -- $menuName {
	"wwwDictionary" {
	    # From the 'Utils' menu
	    if {[catch {getSelect} word]} {
		set word ""
	    }
	}
	"wwwDictionary " {
	    # From the Contextual Menu
	    set pos1 [lindex ${alpha::CMArgs} 1]
	    set pos2 [lindex ${alpha::CMArgs} 2]
	    if {[pos::diff $pos1 $pos2]} {
		set word [getText $pos1 $pos2]
		if {[regexp "\[\r\n\t \]" $word]} {
		    set word ""
		}
	    } else {
		set word [lindex [contextualMenu::clickWord] 0]
	    }
	}
	default {error "Unknown menu name: $menuName"}
    }
    return $word
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× version history ×××× #
# 
# modified by  vers#  reason
# -------- --- ------ -----------
# 05/05/02 cbu 0.1    Created package.
# 05/08/02 cbu 0.2    Renamed package from 'wwwWordUtils' to 'wwwDictionary'.
# 11/09/02 cbu 0.3    Added preferences for menu bindings.
#                     Minor bug fixes to correctly automatically search
#                       using highlighted text when appropriate.
#                     Removed use of "status::errorMsg".
# 11/10/03 cbu 0.4    Added "English > French" dictionary Language.
#                     Default French, Italian dictionary urls.
# 11/15/03 cbu 0.5    New [dictionary::wwwUtility] dialog that allows the user
#                       to select an alternate Language "on the fly".
# 11/27/03 cbu 0.5.1  Explicit return values in all procedures.
#                     Minor Tcl formatting changes.
#                     Updated 'help' argument.
# 12/01/03 cbu 1.0    Everything is now in the "dictionary::www" namespace.
#                     Rebuilding of Tcl/AlphaTcl package indices is required.
#                     Procedure re-organization of this file.
#                     New [dictionary::www::initializePackage] proc takes care
#                       of defining necessary preferences, variables.
#                     [dictionary::languages] split into two different procs,
#                       [dictionary::www::listLanguages] -- lists them
#                       [dictionary::www::languageSettings] -- sets settings.
# 01/23/04 cbu 1.0.1  Minor change in order of menu items.
# 

# ===========================================================================
# 
# .