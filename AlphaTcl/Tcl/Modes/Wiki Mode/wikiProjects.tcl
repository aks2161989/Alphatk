## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "wikiProjects.tcl"
 #                                          created: 01/27/2006 {11:14:45 AM}
 #                                      last update: 04/28/2006 {04:40:42 PM}
 # Description:
 # 
 # Provides support for creating different Wiki Projects, each of which can 
 # have its own set of Favorite Pages.
 # 
 # See the "wikiMode.tcl" file for author, license information.
 # 
 # ==========================================================================
 ##

proc wikiProjects.tcl {} {}

namespace eval Wiki {
    
    # Declare a new item for 'New Document'
    set {::newDocTypes(New Wiki Project)} Wiki::newProject

    # This is used in [Wiki::backCompatibilityCheck] when necessary.
    variable versionNumber
    if {![info exists versionNumber]} {
	set versionNumber 0
    }
    # These are the fields required for every project, in the order in which 
    # we expect them to be defined in the "Projects" array entries.
    variable projectFields [list "projectHome" "formatting" "WikiSystem" \
      "author" "password" \
      "horizontalLine" "bulletListItem" "numberedItem" "definitionItem" \
      "verbatim" "bold" "italics"]
    # Don't use 'Wiki::defaultTags' here for these projects because our wikis
    # have slightly different markup tags.  Don't use '\r' so that we can get
    # the special glyph in the edit dialog.  We are hard-wiring in the urls
    # for our web sites; see [Wiki::restoreDefaults] for how we can use purls
    # to properly set these as well.  (We do _not_ want to use purls here,
    # because that would require an active internet connection when Alpha is
    # first launched!)
    variable defaultProjects
    set defaultProjects(AlphaTcl) [list \
      projectHome "http://alphatcl.sourceforge.net/wiki/" \
      formatting  "http://alphatcl.sourceforge.net/wiki/pmwiki.php/PmWiki/TextFormattingRules" \
      WikiSystem  "Pm Wiki" \
      author "" \
      password "" \
      horizontalLine [list {----
}] \
      bulletListItem [list {* }      ] \
      numberedItem   [list {# }     ] \
      definitionItem [list {} {:}] \
      verbatim       [list { }          ] \
      bold           [list {'''} {'''}  ] \
      italics        [list {''}  {''}   ] ]

    set defaultProjects(Tcl) [list \
      projectHome "http://wiki.tcl.tk/" \
      formatting  "http://wiki.tcl.tk/14.html" \
      WikiSystem  "Wikit" \
      author "" \
      password "" \
      horizontalLine [list {----
}] \
      bulletListItem [list {   * }      ] \
      numberedItem   [list {   1. }     ] \
      definitionItem [list {   } { :   }] \
      verbatim       [list { }          ] \
      bold           [list {'''} {'''}  ] \
      italics        [list {''}  {''}   ] ]
    # Some default favorites.
    variable defaultFavorites
    set defaultFavorites(AlphaTcl) [list \
      [list "Sandbox" \
      "http://alphatcl.sourceforge.net/wiki/pmwiki.php/Main/WikiSandbox"] \
      ]
    set defaultFavorites(Tcl) [list \
      [list "Graffiti" "http://wiki.tcl.tk/34"] \
      ]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::backCompatibilityCheck" --
 # 
 # Ensure that any saved settings follow the current format.  If any of our
 # default project settings change, we can add a new "versionNumber" check to
 # ensure that the current defaults are used.
 # 
 # This is a one-time script for users; after it is performed the variable
 # "versionNumber" is saved in a user's PREFS file so that this procedure
 # will immediately return.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::backCompatibilityCheck {} {
    
    variable Favorites
    variable Projects
    variable versionNumber
    
    set oldVersionNumber $versionNumber
    set newVersionNumber [alpha::package versions "wikiMenu"]
    
    if {([alpha::package vcompare $oldVersionNumber $newVersionNumber] >= 0)} {
	return
    }
    if {([alpha::package vcompare $oldVersionNumber 1.2b3] < 0)} {
	# Our "AlphaTcl" wiki project settings have changed.
	Wiki::defaultProjects "AlphaTcl"
    }
    if {([alpha::package vcompare $oldVersionNumber 1.2b5] < 0)} {
	# Our "Tcl" wiki project settings have changed.
	Wiki::defaultProjects "Tcl"
    }
    if {([alpha::package vcompare $oldVersionNumber 1.2b6] < 0)} {
	# Redefined project setting field names.  We'll transfer the old
	# field value to the new one, and let [Wiki::verifyProject] take care
	# of putting all fields in the proper order.
	foreach project [array names Projects] {
	    array set fields $Projects($project)
	    if {[info exists fields(registrationUrl)]} {
		# The "registrationUrl" setting is now obsolete.  We have
		# separate "author" and "password" settings now.
		lappend Projects($project) "author" $fields(registrationUrl)
		prefs::modified Projects($project)
	    }
	    if {[info exists fields(editingMethod)]} {
		# The "editingMethod" setting is now a prettified name.
		set WikiSystem [Wiki::systemName $fields(editingMethod) 1]
		lappend Projects($project) "WikiSystem" $WikiSystem
		prefs::modified Projects($project)
	    }
	    unset -nocomplain fields
	}
    }
    set versionNumber $newVersionNumber
    prefs::modified versionNumber
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::verifyProject" --
 # 
 # Ensure that the "Projects" array entry for the given project has its field
 # values in the proper order.  In general, this shouldn't matter for any of
 # our code but we do want to make sure that there is a value in place for
 # every "projectFields" item.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::verifyProject {project} {
    
    global user
    
    variable Favorites
    variable Projects
    variable projectFields
    
    if {![info exists Projects($project)]} {
	return
    }
    set oldProjectList $Projects($project)
    set newProjectList [list]
    array set oldFields $oldProjectList
    foreach field $projectFields {
	lappend newProjectList $field
	if {[info exists oldFields($field)]} {
	    set value $oldFields($field)
	} else {
	    set value ""
	}
	if {($field eq "WikiSystem")} {
	    set value [Wiki::systemName $value 1]
	    if {([lsearch [Wiki::listSystems 1] $value] == -1)} {
	        set value ""
	    }
	}
	# Ensure proper default values are in place.
	if {($value eq "")} {
	    switch -- $field {
		"WikiSystem" {
		    set value "undefined"
		}
		"author" {
		    if {[info exists user(author_initials)]} {
			set value $user(author_initials)
		    }
		}
	    }
	}
	lappend newProjectList $value
    }
    if {($Projects($project) ne $newProjectList)} {
	set Projects($project) $newProjectList
	prefs::modified Projects($project)
    }
    # Make sure that the "Favorites" array entry exists.
    if {![info exists Favorites($project)]} {
	set Favorites($project) [list]
	prefs::modified Favorites($project)
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Wiki Projects ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::defineProject"  ---
 # 
 # Define a Wiki Project if it didn't already exist.  Returns "1" if a new
 # project was created, otherwise "0".
 # 
 # At present we do no verification that the items are properly listed.
 # 
 # We reset the "Wiki::prefProjects" variable here, which is used as the list
 # for the WikimodeVars(project) list of options.
 # 
 # --------------------------------------------------------------------------
 ## 

proc Wiki::defineProject {project settings} {
    
    variable Favorites
    variable Projects
    variable prefProjects
    
    if {[info exists Projects($project)]} {
	return 0
    } elseif {([llength $settings] % 2)} {
	return -code error "Attempted to set project 'project' settings\
	  to an odd-length list:\r    $settings"
    } else {
	set Projects($project) $settings
	prefs::modified Projects($project)
	Wiki::verifyProject $project
	set prefProjects [Wiki::listProjects -2]
	return 1
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::defaultProjects" --
 # 
 # Define the default projects using the settings "hard-wired" above in the
 # [namespace eval Wiki] call.  This will over-ride any previous settings,
 # except for the "author" and "password" field values.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::defaultProjects {{projects "all"}} {
    
    variable defaultFavorites
    variable defaultProjects
    variable Favorites
    variable Projects
    
    Wiki::defaultTags
    if {($projects eq "all")} {
	set projects [array names defaultProjects]
    }
    set results [list]
    foreach project $projects {
	# Project settings.
	set newSettings $defaultProjects($project)
	if {[info exists Projects($project)]} {
	    array set oldFields $Projects($project)
	    foreach field [list "author" "password"] {
		if {[info exists oldFields($field)]} {
		    lappend newSettings $field $oldFields($field)
		}
	    }
	    array unset oldFields
	}
	unset -nocomplain Projects($project)
	if {![Wiki::defineProject $project $newSettings]} {
	    continue
	}
	lappend results $project
	# Favorite pages.
	set homePage [Wiki::projectField $project "projectHome"]
	set newFavorites [list]
	if {[info exists Favorites($project)]} {
	    foreach favorite $Favorites($project) {
		if {[string match ${homePage}* [lindex $favorite 1]]} {
		    lappend newFavorites $favorite
		}
	    }
	}
	set Favorites($project) $newFavorites
	# Add defaults.
	foreach favoriteItem $defaultFavorites($project) {
	    set name [lindex $favoriteItem 0]
	    if {([Wiki::favoriteIndex $project $name] == -1)} {
	        lappend Favorites($project) $favoriteItem
	    }
	}
    }
    return $results
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::defaultTags"  ---
 # 
 # Define some default values for mark-up tags.  If new items are added (or
 # if any old ones are deleted), make sure that [Wiki::editProjects] is
 # adjusted accordingly.  No need to include 'unverbatim' or 'unquote' here.
 # Use real carriage returns rather than '\r' to put special glyph in
 # dialogs.
 # 
 # This proc has to be defined before any of the default wiki projects are
 # added below.
 # 
 # --------------------------------------------------------------------------
 ## 

proc Wiki::defaultTags {} {
    
    variable Favorites
    variable Projects
    
    if {[info exists Projects(default)]} {
	return $Projects(default)
    }
    set Projects(default) [list \
      projectHome "" formatting "" WikiSystem "undefined" \
      author "" password "" \
      horizontalLine [list {----
}] \
      bulletListItem [list {   * }    ] \
      numberedItem   [list {   1. }   ] \
      definitionItem [list "\t" " :\t"] \
      verbatim       [list { }        ] \
      bold           [list {'''} {'''}] \
      italics        [list {''}  {''} ] ]
    prefs::modified Projects(default)
    set Favorites(default) [list]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::listProjects" --
 # 
 # List the names of all Wiki Projects.  "default" is a special case, and
 # cannot be removed by the user, so by default it is not included.  Various
 # options for "includeDefault" allow the "default" project to be included at
 # the beginning or end of the list, possibly with dialog or menu dividers.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::listProjects {{includeDefault "0"}} {
    
    variable Projects
    
    set projects [lsort -dictionary [array names Projects]]
    set projects [lremove $projects [list "default"]]
    if {($includeDefault != 0)} {
	if {![llength $projects]} {
	    return [list "default"]
	}
	switch -- $includeDefault {
	    "-3" {
		set projects [linsert $projects 0 "default" "(-)"]
	    }
	    "-2" {
		set projects [linsert $projects 0 "default" "-"]
	    }
	    "-1" {
		set projects [linsert $projects 0 "default"]
	    }
	    "1" {
		set projects [linsert $projects end "default"]
	    }
	    "2" {
		set projects [linsert $projects end "-" "default"]
	    }
	    "3" {
		set projects [linsert $projects end "(-)" "default"]
	    }
	}
    }
    return $projects
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::currentProject"  ---
 # 
 # Optionally sets a new project to be the current one, ensures that the
 # current project actually exists, and make some variables available to the
 # calling proc.
 # 
 # --------------------------------------------------------------------------
 ## 

proc Wiki::currentProject {{newProject ""}} {
    
    global WikimodeVars
    
    variable Projects
    
    upvar project  project
    upvar projects projects
    upvar settings settings
    
    # Create a list of all projects available.  If we don't have any projects
    # available, we still need to define the variables.
    if {![llength [set projects [Wiki::listProjects 1]]]} {
	set project ""
	set settings [Wiki::defaultTags]
	return "default"
    }
    # Determine the current project.
    if {($newProject ne "")} {
	# Make 'newProject' the current project.
	set WikimodeVars(wikiProject) $newProject
	Wiki::rebuildMenu $newProject
    }
    # Make sure that the current project exists.
    if {![lcontains projects [set project $WikimodeVars(wikiProject)]]} {
	set project [set WikimodeVars(wikiProject) [lindex $projects 0]]
    }
    set settings $Projects($project)
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::projectField" --
 # 
 # Given the names of a defined project and a valid field, return the current
 # setting.  If the value is "" then the "defaultValue" value is returned.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::projectField {project field {defaultValue ""}} {
    
    variable Projects
    variable projectFields
    
    if {([lsearch $projectFields $field] == -1)} {
        error "\"$field\" is not a valid project field."
    } elseif {![info exists Projects($project)]} {
        error "\"$project\" is not a defined project."
    }
    array set fields $Projects($project)
    if {[info exists fields($field)] && ($fields($field) ne "")} {
	return $fields($field)
    } else {
	return $defaultValue
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::findWindowProject"  ---
 # 
 # Determine the current Project associated with the given window name.  This
 # assumes that the window has been registered with a "Wiki::editWindows"
 # array entry.
 # 
 # --------------------------------------------------------------------------
 ## 

proc Wiki::findWindowProject {{winName ""}} {
    
    variable editWindows
    
    set windowProject ""
    if {![llength $winName]} {
	set winName [win::Current]
    }
    if {![info exists editWindows($winName)]} {
	return ""
    }
    foreach project [Wiki::listProjects 1] {
	set homePage [Wiki::projectField $project "projectHome"]
	if {($homePage eq "")} {
	    continue
	} elseif {[string match "${homePage}*" $editWindows($winName)]} {
	    set windowProject $project
	    break
	}
    }
    return $windowProject
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::validateUrlForProject" --
 # 
 # Verify the the given url is associated with the given project, defaulting
 # to the Current Project if none is specified.  Returns "1" if it is,
 # otherwise "0".  If "askAndError" is "1", then we ask the user if we should
 # continue, still returning "0" if the answer is yes.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::validateUrlForProject {url {project ""} {askAndError "1"}} {
    
    global WikimodeVars
    
    variable Projects
    
    if {($project eq "")} {
	set project $WikimodeVars(wikiProject)
    } elseif {([lsearch -exact [Wiki::listProjects 1] $project] == -1)} {
	set project "default"
    }
    # Check that the url is related to the given project.
    if {[regexp [Wiki::projectField $project "projectHome"] $url]} {
	return 1
    } elseif {!$askAndError} {
	return 0
    }
    # Confirm that the user wants to continue.
    status::msg $url
    set q "The selected url does not seem to belong to the\
      \"$project\" wiki project.\r\rAre you sure you want to continue?"
    if {[askyesno $q]} {
	return 0
    } else {
	error "Cancelled."
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::changeCurrentProject" --
 # 
 # This should only be called by a dialog's "Change Project" button.  It will
 # allow the user to change the project before continuing.  The variable
 # "userChangedProject" can be queried by the procedure that created the
 # dialog to find out what changed.  If the user successfully change the
 # project (i.e. the [listpick] wasn't cancelled) then but only then we set
 # the "retCode" and "retVal" variables.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::changeCurrentProject {} {
    
    variable userChangedProject 0
    
    Wiki::currentProject
    
    set p "Change the Current Wiki Project to:"
    set options [Wiki::listProjects -1]
    Wiki::currentProject [listpick -p $p -L [list $project] $options]
    set userChangedProject 1
    uplevel 1 [list set retCode "1"]
    uplevel 1 [list set retVal "cancel"]
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Projects Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::buildProjectsMenu" --
 # 
 # Return the list of "Wiki Menu > Wiki Projects" items required by the
 # [menu::buildSome] procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::buildProjectsMenu {} {
    
    set menuList [list "Add New ProjectÉ" "Edit ProjectsÉ" "Rename ProjectÉ" \
      "Delete ProjectÉ" "(-)" "Restore DefaultsÉ" "Projects Help"]
    
    set menuProc "Wiki::projectsMenuProc -m -M Wiki"
    
    return [list "build" $menuList $menuProc]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::postBuildProjects" --
 # 
 # Dim/enable "Wiki Menu > Wiki Projects" menu items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::postBuildProjects {} {
    
    variable Projects
    
    set dim [expr {([array size Projects] > 1)}]
    foreach menuItem [list "Edit ÇPÈs" "Rename ÇPÈ" "Delete ÇPÈ"] {
	regsub -all -- {ÇPÈ} $menuItem {Project} menuItem
	append menuItem "É"
	enableMenuItem "Wiki Projects" $menuItem $dim
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::projectsMenuProc" --
 # 
 # Handle all "Wiki Menu > Wiki Projects" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::projectsMenuProc {menuName menuItem} {
    
    variable Projects
    
    Wiki::currentProject
    
    switch -- $menuItem {
	"Add New Project" {
	    Wiki::newProject
	}
	"Edit Projects" {
	    Wiki::editProjects
	}
	"Rename Project" {
	    Wiki::renameProject
	}
	"Delete Project" {
	    Wiki::deleteProject
	}
	"Restore Defaults" {
	    Wiki::restoreDefaults
	}
	"Projects Help" {
	    help::openGeneral "wikiMenu" "Wiki Projects"
	}
	default {
	    foreach favorite $Projects($project) {
		if {[string compare -nocase $menuItem [lindex $favorite 0]]} {
		    continue
		} else {
		    Wiki::viewUrl [lindex $favorite 1]
		}
		return
	    }
	    # Still here?
	    error "Cancelled -- could not identify the url for \"$menuItem\"."
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Projects Utilities ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::newProject"  --
 # 
 # Create a new Wiki Project.
 # 
 # We first open a dialog which contains pages for all projects, allowing the
 # user to create a new wiki project or to set home page urls and tag
 # specifics.  (Not all wikis use the same formatting rules.)
 # 
 # We then re-direct to [Wiki::editProjects].
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::newProject {} {
    
    global WikimodeVars
    
    variable Favorites
    variable Projects
    
    set txt "You are about to add a new Wiki Project.  Please specify the\
      name of the project, and the method to create the default settings.\r"
    set name ""
    
    set p "Descriptive name of new project"
    set name ""
    set options [list "Use Default Settings"]
    if {[llength [set allProjects [Wiki::listProjects 0]]]} {
	lappend options "-"
	foreach project $allProjects {
	    lappend options "Clone \"$project\""
	}
    }
    if {($WikimodeVars(wikiProject) eq "default")} {
        set clone [lindex $options 0]
    } else {
        set clone "Clone \"$WikimodeVars(wikiProject)\""
    }
    while {1} {
	set dialogScript [list dialog::make -title "New Project Details" \
	  -width 350 \
	  -ok "Continue" \
	  -addbuttons [list \
	  "Help" \
	  "Click this button to open Wiki Menu help" \
	  "help::openGeneral wikiMenu {Wiki Projects} ; \
	  set retCode 1 ; set retVal {cancel}" \
	  ] \
	  [list "" \
	  [list "text" $txt] \
	  [list "var"  "Project Name:" $name] \
	  [list [list "menu" $options] "Initial Defaults:" $clone] \
	  ]]
	set results [eval $dialogScript]
	set name    [lindex $results 0]
	set clone   [lindex $results 1]
	if {($name eq "")} {
	    alertnote "The name cannot be an empty string!"
	} elseif {([lsearch -exact [Wiki::listProjects 1] $name] > -1)} {
	    alertnote "\"$name\" is already a defined Wiki project."
	} else {
	    break
	}
    }
    switch -- $clone {
	"Use Default Settings" {
	    set settings [Wiki::defaultTags]
	}
	default {
	    regexp -- {^Clone \"(.+)\"$} $clone -> clone
	    set settings $Projects($clone)
	    lappend settings "projectHome" "" "formatting" ""
	}
    }
    # Now we create the project, and then open the editing dialog.
    Wiki::defineProject $name $settings
    Wiki::currentProject $name
    set Favorites($name) [list]
    prefs::modified Favorites($name)
    Wiki::editProjects
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::editProjects" --
 # 
 # Edit all defined Wiki Projects.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::editProjects {} {
    
    variable Projects
    
    Wiki::currentProject
    
    # Ensure that all of our projects have items in the proper order.
    foreach projectName $projects {
        Wiki::verifyProject $projectName
    }
    set SystemsList [concat [list "undefined" "-"] [Wiki::listSystems 1]]
    set results [dialog::editGroup -array Wiki::Projects \
      -title "Edit Wiki project information" \
      -current $project \
      [list "projectHome" [list "smallval" url] "Home Page"\
      "This is the base url containing the home page of the Wiki project."] \
      [list "formatting" [list "smallval" url] "Formatting Page"\
      "This is the url that contains the project's formatting rules."] \
      [list "WikiSystem" [list menu $SystemsList] "Wiki System" \
      "This is the method used to edit a Wiki page."] \
      [list "author" variable "Author"\
      "This is the login name that will be given to the server when necessary."]\
      [list "password" password "Password"\
      "This is the password that will be given to the server when necessary."] \
      [list "horizontalLine" variable "Horizontal Lines"\
      "This is the tag for horizontal lines."] \
      [list "bulletListItem" variable "Bulleted List Items"\
      "This is the tag for bulleted list items."] \
      [list "numberedItem" variable "Numbered Items"\
      "This is the tag for numbered items."] \
      [list "definitionItem" variable "Variable Items"\
      "This is the pair of tags for variable items."] \
      [list "verbatim" variable "Verbatim tags"\
      "This is the tag for verbatim text."] \
      [list "bold" variable "Bold tags"\
      "This is the pair of tags for bold text."] \
      [list "italics" variable "Italics tags"\
      "This is the pair of tags for italics text."] \
      ]
    if {![llength $results]} {
	return
    }
    # This works whether projects have been modified or deleted.
    foreach project $results {
	if {![lcontains projects $project]} {
	    # This is a new project, so we'll make it current.
	    Wiki::currentProject $project
	}
	if {([Wiki::projectField $project "author"] eq "")} {
	    # If the value is empty, make sure that it doesn't revert back to
	    # the user's information.
	    lappend Projects($project) author " "
	}
	Wiki::verifyProject $project
	prefs::modified Projects($project)
    }
    set hasHave [expr {([llength $results] == 1) ? "has" : "have"}]
    status::msg "The \"[join $results {, }]\" project settings\
      $hasHave been saved."
    # Make sure that the 'default' project wasn't deleted !!
    Wiki::defineProject "default" [Wiki::defaultTags]
    # Should now rebuild the menu in case we've added or removed a project.
    # 'Wiki::currentProject' will make sure that the current project still
    # exists, and adjust accordingly.
    Wiki::currentProject
    Wiki::rebuildMenu
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::renameProject" --
 # 
 # Rename a defined Wiki Project.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::renameProject {} {
    
    variable Favorites
    variable Projects
    
    Wiki::currentProject
    
    set options [lremove $projects [list "default"]]
    if {![llength $projects]} {
	error "Cancelled -- there are no projects to rename."
    }
    set p "Rename which project?"
    set oldName [listpick -p $p -L [list $project] $options]
    set newName $oldName
    while {1} {
	set p "Rename \"$oldName\" to"
	set newName  [string trim [prompt $p $newName]]
	if {($newName eq "")} {
	    alertnote "The project name cannot be an empty string!"
	} elseif {([lsearch $projects $newName] > -1)} {
	    alertnote "\"$newName\" is already defined as a project."
	} else {
	    break
	}
    }
    foreach what [list "Projects" "Favorites"] {
	set ${what}($newName) [set ${what}($oldName)]
	unset ${what}($oldName)
	prefs::modified ${what}($oldName) ${what}($newName)
    }
    # Make the renamed project current if necessary.
    if {![lcontains projects $oldName]} {
	Wiki::currentProject $newName
    }
    Wiki::rebuildMenu
    status::msg "The \"$oldName\" project has been renamed to \"$newName\"."
    set q "Would you like to rename another project?"
    if {([llength $options] > 1) && [askyesno $q]} {
	Wiki::renameProject
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::deleteProject" --
 # 
 # Delete a defined Wiki Project.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::deleteProject {} {
    
    variable Favorites
    variable Projects
    
    Wiki::currentProject
    
    set options [lremove $projects [list "default"]]
    if {![llength $projects]} {
	error "Cancelled -- there are no projects to delete."
    }
    set p "Delete which project(s)?"
    set removeList [listpick -p $p -l $options]
    foreach project $removeList {
	prefs::modified   Projects($project) Favorites($project)
	unset -nocomplain Projects($project) Favorites($project)
    }
    if {![lcontains projects $project]} {
	Wiki::currentProject "default"
    }
    Wiki::rebuildMenu
    if {([llength $removeList] == 1)} {
	set msg "The project \"[lindex $removeList 0]\" has been removed."
    } else {
	set msg "The projects \"[join $removeList {, }]\" have been removed."
    }
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::restoreDefaults" --
 # 
 # Restore any default projects as directed by the user.  In this routine we
 # determine the current proper location that is indicated by our "persistent
 # urls" (purls) validation.  If the "http" package is not available, then we
 # simply use the defaults defined above.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::restoreDefaults {} {
    
    global alpha::application
    
    variable defaultProjects
    variable Projects
    
    set txt1 "${alpha::application}'s Wiki Menu defines some default projects\
      to help get you started.  You can change any of the settings for them,\
      but you might find that you need to restore the original settings."
    set txt2 "Select a project below...\r"
    set txt3 "and then press \"Restore\" to revert to the default settings.\r"
    if {[Wiki::httpAvailable 0]} {
	set txt4 "Note: an active internet connection is now required.\r"
    } else {
        set txt4 ""
    }
    set projects [lsort [array names defaultProjects]]
    eval [list lappend options "Restore All" "-" ] $projects
    set dialogScript [list dialog::make -title "Restore Default Projects?" \
      -width 450 \
      -ok "Restore" \
      -addbuttons [list \
      "Help" \
      "Click this button to open Wiki Menu help" \
      "help::openGeneral wikiMenu {Default Projects} ; \
      set retCode 1 ; set retVal {cancel}" \
      ] \
      [list "" \
      [list "text" $txt1] [list "text" $txt2] \
      [list [list "menu" $options] "Projects:"] \
      [list "text" $txt3] [list "text" $txt4] \
      ]]
    set results [eval $dialogScript]
    if {([lindex $results 0] ne "Restore All")} {
	set projects [list [lindex $results 0]]
    }
    if {[Wiki::httpAvailable 0]} {
	watchCursor
	set msg "Obtaining current wiki locations for"
	foreach project $projects {
	    status::msg "$msg \"$project\" É"
	    switch -- $project {
		"AlphaTcl" {
		    lappend defaultProjects(AlphaTcl) "projectHome" \
		      [Wiki::getRedirectUrl \
		      "http://www.purl.org/net/alpha/wiki/"]
		    lappend defaultProjects(AlphaTcl) "formatting" \
		      [Wiki::getRedirectUrl \
		      "http://www.purl.org/net/alpha/wikipages/formatting"]
		}
		"Tcl" {
		    lappend defaultProjects(Tcl) "projectHome" \
		      [Wiki::getRedirectUrl \
		      "http://www.purl.org/net/alpha/tclwiki/"]
		    lappend defaultProjects(Tcl) "formatting" \
		      [Wiki::getRedirectUrl \
		      "http://www.purl.org/net/alpha/tclwikipages/formatting"]
		}
	    }
	}
	status::msg ""
    }
    set results [list]
    foreach project $projects {
	lappend results [Wiki::defaultProjects $project]
    }
    Wiki::rebuildMenu
    switch -- [llength $results] {
	"0" {
	    set msg "Sorry, no projects were restored!"
	}
	"1" {
	    set msg "The \"[lindex $results 0]\" project has been restored."
	}
	default {
	    set msg "The \"[join $results {, }]\" projects have been restored."
	}
    }
    status::msg $msg
    return
}

# ===========================================================================
# 
# .