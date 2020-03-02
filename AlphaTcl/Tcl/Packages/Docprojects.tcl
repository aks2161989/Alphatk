## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # (formerly "Vince's Additions")
 # 
 # FILE: "Docprojects.tcl"
 #                                          created: 07/29/1997 {04:59:22 pm}
 #                                      last update: 03/21/2006 {02:07:20 PM}
 # Description:
 # 
 # Support for creating and updating file headers, and other useful routines
 # for multiples files related to a single project.
 # 
 # Because this is an optional package which might be uninstalled by the
 # user, none of these procedures should ever be called outside of this file.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley, Craig Barton Upright
 # 
 # Distributed under a Tcl style license.  This package is not actively
 # improved any more, so if you wish to make improvements, feel free to take
 # it over.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # --------------------------------------------------------------------------
 # 
 # To Do:
 # 
 # * More annotation of how all of this works.
 # 
 # ==========================================================================
 ##

alpha::feature documentProjects 2.0.2 "global-only" {
    # Initialization script.
    docProj::initializePackage
} {
    # Activation script.
    docProj::activatePackage 1
} {
    # Deactivation script.
    docProj::activatePackage 0
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} uninstall {
    this-file
} description {
    Automatically creates document header templates, and updates information
    in them when files are saved
} help {
    file "Documentprojects Help"
}

proc Docprojects.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval elec" --
 # 
 # Define all required variables in the "elec" namespace.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval elec {
    
    variable DocTemplates
    variable MenuTemplates
    
    # header/source templates.  (Some could be defined in other packages.)
    llunion DocTemplates 1 \
      [list * "Empty" * "" *] \
      [list * "Default" * t_default *] \
      [list TeX "Basic LaTeX document" "None" t_latex * \
      {article report letter book slides}] \
      [list C++ "Basic C++ header file" "Header" t_cpp_header *] \
      [list C++ "Basic C++ source file" "Source" t_cpp_source * ] \
      [list HTML "HTML document" * t_html * ]
    
    # \
    # [list C++ "Cpptcl Class Source" Source t_cpptcl_source "Cpptcl"] \
    # [list C++ "Cpptcl Class Header" Header t_cpptcl_header "Cpptcl"] \
    # [list Tcl "Itcl Class" * t_itcl_class "Cpptcl"]  \
    # [list Tcl "Blank Tcl Header" Header "\#" "Vince's Additions"] \
    # [list C++ "EvoX Class Source" Source t_cpptcl_source "EvoX"] \
    # [list C++ "EvoX Class Header" Header t_cpptcl_header "EvoX"]
    
    # These will be inserted into the Electric Menu, and require
    # [file::<itemName>] procedures.
    lunion MenuTemplates "createHeader" "newDocument"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval docProj" --
 # 
 # Define all required variables in the "docProj" namespace.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval docProj {
    
    variable initialized
    if {![info exists initialized]} {
	set initialized "-1"
    }
    variable activated
    if {![info exists activated]} {
	set activated "-1"
    }
    variable description
    if {![info exists description]} {
        set description ""
    }
    # The list of entries in the "userProjects" array.  The order here is
    # important, since it is the one used in the editing dialogs.
    variable userProjectArrays [list name addendum license \
      owner owner_org extra default_modes]
    
    # The list of items in each "elec::DocTemplates" entry.  The order here
    # is important, and it is also used in the editing procedures.
    variable templateItems [list modes name fileType procName project subTypes]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::initializePackage" --
 # 
 # Called when this package is first initialized, define all necessary
 # variables and preferences.  Any procedure which might be called by outside
 # code (not that this should ever occur) can ensure that the necessary
 # variables are in place by calling this first.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::initializePackage {} {
    
    global docProject DocprojmodeVars documentProjectsmodeVars
    
    variable initialized
    variable templateItems
    variable userProjectArrays
    
    if {($initialized eq "1")} {
	return
    }
    
    # Variables.  These need to be defined.
    
    # User projects.  Since all of this depends on the user's defined
    # document projects, we go to some trouble here to make sure that all of
    # the arrays are properly set.
    
    # This array stores all User Project information.
    variable userProjects
    
    # Earlier versions used a global "docProject" array.
    foreach varName [array names docProject] {
	set userProjects($varName) $docProject($varName)
	prefs::modified docProject($varName) userProjects($varName)
	unset docProject($varName)
    }
    
    # Make sure that we have some defined.
    if {![info exists userProjects(name)]} {
	unset -nocomplain userProjects
	foreach varName $userProjectArrays {
	    switch -- $varName {
		"name" {
		    set value [list "None" "Project2" "Thesis"]
		}
		"addendum" {
		    set value [list {none} {about some other stuff} {deep problems}]
		}
		"extra" {
		    set value [list "" "Freely distributable" \
		      "Copyright (C) [clock format [clock seconds] -format "%Y"] the author."]
		}
		"default_modes" {
		    set value [list {} {C++ Tcl} {TeX}] \
		  }
		default {
		    set value [list "" "" ""]
		}
	    }
	    set userProjects($varName) $value
	}
    }
    # Double-check to make sure that "None" has empty values.
    if {[catch {docProj::projectIndex "None"} projIdx]} {
	foreach varName $userProjectArrays {
	    if {($varName eq "name")} {
		set value "None"
	    } else {
		set value ""
	    }
	    lappend userProjects($varName) $value
	}
    } else {
	foreach varName $userProjectArrays {
	    if {![info exists userProjects($varName)]} {
	        set userProjects($varName) [list]
	    }
	    if {($varName eq "name")} {
		set value "None"
	    } elseif {($varName eq "addendum")} {
		set value "none"
	    } else {
		set value ""
	    }
	    set userProjects($varName) \
	      [lreplace $userProjects($varName) $projIdx $projIdx $value]
	}
    }
    # Check to make sure that each list exists and has the required number of
    # items.  If we have less, we simply add empty values.  If we have more, 
    # then we have serious problems...
    foreach varName $userProjectArrays {
	set saveThisArray 0
	if {![info exists userProjects($varName)]} {
	    set userProjects($varName) [list]
	}
	while {([llength $userProjects($varName)] < [llength $userProjects(name)])} {
	    lappend userProjects($varName) ""
	    set saveThisArray 1
	}
	if {([llength $userProjects($varName)] > [llength $userProjects(name)])} {
	    alertnote "Document Projects warning: the variable\
	      \"userProjects($varName)\" has entries not associated with\
	      any project.  They have been removed, but your project\
	      settings might be corrupt.  Consider deleting all projects\
	      and redefining them."
	    set userProjects($varName) [lrange $userProjects($varName) 0 \
	      [expr {[llength $userProjects($name)] - 1}]]
	    set saveThisArray 1
	}
	if {$saveThisArray} {
	    prefs::modified userProjects($varName)
	}
    }
    
    # Preferences.
    
    # All preferences used to be in the "DocprojmodeVars" array, but are now
    # defined in "documentProjectsmodeVars".
    foreach prefName [array names DocprojmodeVars] {
	prefs::renameOld DocprojmodeVars($prefName) \
	  documentProjectsmodeVars($prefName)
    }
    
    # This is now handled by the "identities" package.
    prefs::removeObsolete documentProjectsmodeVars(identity)
    
    # The name of the current project.  Every project has a unique name.
    newPref var currentProject "None" documentProjects "" \
      docProj::userProjects(name) "varitem"
    # Menu Shortcut to update the version number in a file's header.  These
    # version numbers can be inserted by some of the standard document
    # templates.
    newPref menubinding updateFileVersion "/f<U" documentProjects
    
    # To automatically update a file's header information (time-stamp, etc.)
    # when it is saved, turn this item on||To never automatically update
    # header information when a file is saved, turn this item off
    newPref flag autoUpdateHeader 1 documentProjects
    # To automatically update a file's header copyright year when it is saved
    # (inserting XXXX-YYYY if the first date is not the current year), turn
    # this item on||To never automatically update the header copyright year
    # when a file is saved, turn this item off
    newPref flag autoUpdateCopyrightYear 0 documentProjects
    # To always confirm that the mode of a new window is associated with the
    # current project, turn this item on||To never confirm that the mode of a
    # new window is associated with the current project, turn this item off
    newPref flag confirmProjectModes 1 documentProjects
    # To only be prompted with a list of document templates relevant to the
    # current mode when you create a new document, turn this item on.  This
    # can be useful if you have lots of templates||To always be prompted with
    # all possible templates when creating a new document, turn this item off
    newPref flag docTemplatesModeSpecific 1 documentProjects
    # To always include a "description" field in the header of new 
    # documents, turn this item on.  You will always be prompted for the 
    # description||To never include a "description" field in the header of 
    # new documents, turn this item off
    newPref flag includeHeaderDescription 0 documentProjects
    
    # This character will be repeated to create divider lines in headers.
    newPref var headerDividerCharacter "\#" documentProjects "" \
      [list "\#" "=" " -"]
    
    # Menu build procs.
    menu::buildProc "Document Projects" {docProj::buildMenu} \
      {docProj::postBuildMenu}
    
    # Now we make sure that current information is set.
    docProj::currentProject [docProj::currentProject]
    
    # ???  This is pretty suspect.
    catch "unBind F1 bind::Completion"
    
    # Register a [saveHook] to update information.
    hook::register saveHook {docProj::saveHook}
    
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::activatePackage" --  ?which?
 # 
 # Called when this package is turned on or off, adjust all necessary menus 
 # so that "Document Project" items are (un)available.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::activatePackage {{which 1}} {
    
    variable activated
    
    if {($activated eq $which)} {
	return
    }
    if {$which} {
	package::addPrefsDialog documentProjects
	menu::insert preferences submenu "(-)" {Document Projects}
	menu::insert winUtils items end \
	  "updateDate" \
	  "[menu::bind documentProjectsmodeVars(updateFileVersion) -]"
	# Add a new handler for "New Document".
	namespace eval ::newDocument {
	    variable handlers
	    set "handlers(Document Projects)" docProj::newHandler
	}
    } else {
	package::removePrefsDialog documentProjects
	menu::uninsert preferences submenu "(-)" {Document Projects}
	menu::uninsert winUtils items end \
	  "updateDate" \
	  "[menu::bind documentProjectsmodeVars(updateFileVersion) -]"
	# Remove the handler for "New Document".
	namespace eval ::newDocument {
	    variable handlers
	    unset -nocomplain "handlers(Document Projects)"
	}
    }
    set activated $which
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::buildMenu" --
 # 
 # Build the "Config > Preferences > "Document Projects" menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::buildMenu {} {
    
    set menuList [list "\(Projects:"]
    set menuList [concat $menuList [docProj::listProjects "-1"] [list "(-)"]]
    lappend menuList "New ProjectÉ" "Edit ProjectÉ" "Remove ProjectÉ" "(-)" \
      "New TemplateÉ" "Edit TemplateÉ" "Remove TemplateÉ" "(-)" \
      "Document Projects PrefsÉ" "Document Projects Help"
    if {[alpha::package exists "licenseTemplates"]} {
        lappend menuList "License Templates Help"
    }
    return [list "build" $menuList {docProj::menuProc -m}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::postBuildMenu" --
 # 
 # Dim or enable "Config > Preferences > Document Projects" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::postBuildMenu {} {
    
    set dim1 [expr {([llength [docProj::listProjects]] > 0)  ? 1 : 0}]
    set dim2 [expr {([llength [docProj::listTemplates]] > 0) ? 1 : 0}]
    enableMenuItem -m "Document Projects" "Edit ProjectÉ"    $dim1
    enableMenuItem -m "Document Projects" "Remove ProjectÉ"  $dim1
    enableMenuItem -m "Document Projects" "Edit TemplateÉ"   $dim2
    enableMenuItem -m "Document Projects" "Remove TemplateÉ" $dim2
    foreach project [docProj::listProjects 1] {
	set markItem [expr {($project eq [docProj::currentProject]) ? 1 : 0}]
	markMenuItem -m "Document Projects" $project $markItem "¥"
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::menuProc" --
 # 
 # Deal with all "Config > Preferences > Document Projects" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::menuProc {menuName itemName} {
    
    if {([lsearch -exact [docProj::listProjects 1] $itemName] > -1)} {
	docProj::currentProject $itemName
	docProj::postBuildMenu
	status::msg "The new Current Project is \"$itemName\""
	return
    }
    switch -- $itemName {
	"New Project" {
	    docProj::newProject
	}
	"Edit Project" {
	    docProj::editProject
	}
	"Remove Project" {
	    docProj::removeProject
	}
	"New Template" {
	    docProj::newTemplate
	}
	"Edit Template" {
	    docProj::editTemplate
	}
	"Remove Template" {
	    docProj::removeTemplate
	}
	"Document Projects Prefs" {
	    prefs::dialogs::packagePrefs "documentProjects"
	}
	"Document Projects Help" {
	    package::helpWindow "documentProjects"
	}
	"License Templates Help" {
	    package::helpWindow "licenseTemplates"
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::saveHook" --
 # 
 # Update the headers as directed by the user preferences.  This is called by
 # the AlphaTcl core's [saveHook] procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::saveHook {name} {
    
    global documentProjectsmodeVars
    
    set changes 0
    if {$documentProjectsmodeVars(autoUpdateHeader)} {
	# Update does no harm if it fails, so we call it for all modes with
	# no worries.
	getWinInfo -w $name a
	if {$a(dirty)} {
	    incr changes [docProj::updateGeneralDate $name]
	}
    }
    if {$documentProjectsmodeVars(autoUpdateCopyrightYear)} {
	getWinInfo -w $name a
	if {$a(dirty)} {
	    incr changes [docProj::updateCopyrightYear $name]
	}
    }
    return $changes
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× New Document Creation ×××× #
# 

proc docProj::newHandler {args} {
    
    if {[catch [list docProj::createDocument "new $args"] templateInfo]} {
	return ""
    }
    docProj::createHeader $templateInfo
    return ""
}

## 
 # --------------------------------------------------------------------------
 #  
 # "docProj::createDocument" --
 # 
 # Make a new document from a given template type.
 # 
 # 'forcemode' will force the file into that mode via emacs-like mode entries
 # on the top line of the file.
 # 
 # Returns the six item list with template information.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::createDocument {{newCmdArgs ""} {forceMode ""}} {
    
    global documentProjectsmodeVars identity
    
    variable description
    variable lastChosenOption
    variable repeatCD 0
    
    # Make sure that all necessary variables and preferences are in place.
    docProj::initializePackage
    
    # Determine the name for our new window.
    set w ""
    for {set i 0} {($i < [llength $newCmdArgs])} {incr i} {
	if {([lindex $newCmdArgs $i] eq "-n")} {
	    set w [lindex $newCmdArgs [expr {$i + 1}]]
	} elseif {([lindex $newCmdArgs $i] eq "-mode")} {
	    set m [lindex $newCmdArgs [expr {$i + 1}]]
	}
    }
    if {($w eq "")} {
	set w "untitled"
    }
    if {![info exists m]} {
	set m [mode::findForWindow $w]
    }
    set other [list]
    # Create the list of possible templates.
    if {!$documentProjectsmodeVars(docTemplatesModeSpecific)} {
	set tlist [docProj::listTemplates $w "" other]
    } elseif {($forceMode ne "")} {
	set tlist [docProj::listTemplates $w $forceMode]
    } else {
	set tlist [docProj::listTemplates $w $m]
    }
    if {[llength $other]} {
	eval lappend tlist "-" [lsort $other]
    }
    lappend tlist "-" "Create new templateÉ"
    if {([set idx [lsearch $tlist "Empty"]] > -1)} {
        set tlist [lreplace $tlist $idx $idx]
	set tlist [linsert $tlist 0 "Empty" "-"]
    }
    if {[info exists lastChosenOption(createDocument,$m)] \
      && ([lsearch $tlist $lastChosenOption(createDocument,$m)] > -1)} {
	set template $lastChosenOption(createDocument,$m)
    } else {
	set template "Default"
    }
    set ids [userInfo::listIdentities -2]
    set projects [docProj::listProjects -2]
    set project  [docProj::currentProject]
    # Create a dialog for the user to select options.
    set dialogScript [list dialog::make \
      -title "Document Project Options" \
      -width 400 \
      -ok "Continue" \
      -okhelptag "Click here to continue creating the new \"$w\" window\
      using the current settings" \
      -cancelhelptag "Click here to cancel the \"$w\" window creation." \
      -addbuttons [list \
      "Edit TemplatesÉ" \
      "Click here to edit your current templates" \
      "set retVal {repeat} ; set retCode 0 ; \
      set ::docProj::repeatCD 1 ; \
      catch {docProj::menuProc {} {Edit Template}}" \
      "IdentitiesÉ" \
      "Click here to edit your current identities" \
      "set retVal {repeat} ; set retCode 0 ; \
      set ::docProj::repeatCD 1 ; \
      catch {userInfo::menuProc {} {Edit Identity}}" \
      "ProjectsÉ" \
      "Click here to edit your current projects" \
      "set retVal {repeat} ; set retCode 0 ; \
      set ::docProj::repeatCD 1 ; \
      catch {docProj::menuProc {} {Edit Project}}" \
      "Help" \
      "Click here to open Document Projects Help" \
      "set retVal {cancel} ; set retCode 1 ; \
      package::helpWindow documentProjects" \
      "PrefsÉ" \
      "Click here to set Document Project preferences" \
      "set retVal {repeat} ; set retCode 0 ; \
      set ::docProj::repeatCD 1 ; \
      catch {prefs::dialogs::packagePrefs documentProjects}" \
      ]]
    set dialogPane [list "" \
      [list "text" "Create the \"$w\" window withÉ\r"] \
      [list [list "menu" $tlist] "Template:" $template \
      "The type of template to be inserted into the new \"$w\" window"] \
      [list [list "menu" $ids] "Identity:" $identity \
      "The identity to be used for the \"$w\" window header information"] \
      [list [list "menu" $projects] "Project:" $project \
      "The project to be used for the \"$w\" window header information"]
    ]
    if {$documentProjectsmodeVars(includeHeaderDescription)} {
	lappend dialogPane \
	  [list "var2" "Description:" $description \
	  "Enter a brief header description explaining\
	  why this file exists and what it purports to do"]
    }
    lappend dialogScript $dialogPane
    set results [eval $dialogScript]
    set templateType [lindex $results 0]
    set lastChosenOption(createDocument,$m) $templateType
    prefs::modified lastChosenOption(createDocument,$m)
    if {($identity ne [lindex $results 1])} {
	set identity [lindex $results 1]
	prefs::modified identity
	userInfo::changeIdentity
    }
    if {($project ne [lindex $results 2])} {
	docProj::currentProject [lindex $results 2]
	prefs::modified documentProjectsmodeVars(currentProject)
    }
    if {$documentProjectsmodeVars(includeHeaderDescription)} {
	set description [lindex $results 3]
	if {($description ne "") && ($templateType eq "Empty")} {
	    set q "Although you entered a description, this will be\
	      ignored because you have chosen an \"Empty\" template."
	    if {![dialog::yesno -y "Continue" -n "Go Back" $q]} {
		set repeatCD 1
	    }
	}
    }
    if {$repeatCD} {
	return [docProj::createDocument $newCmdArgs $forceMode]
    }
    if {($templateType eq "Create new templateÉ")} {
	set templateType [docProj::newTemplate 1]
    } else {
	set lastChosenOption(createDocument,$m) $templateType
	prefs::modified lastChosenOption(createDocument,$m)
    }
    set templateInfo [docProj::templateInfo $templateType]
    set subTypes [lindex $templateInfo 5]
    if {($subTypes ne "")} {
	# Replace the list of options with just the one selected.
	set p "Pick a document sub-type of $templateType"
	set templateInfo [lreplace $templateInfo 5 5 [listpick -p $p $subTypes]]
    }
    if {($forceMode eq "") && ([lindex $templateInfo 0] ne "*")} {
	set forceMode [lindex $templateInfo 0]
	set newCmdArgs [linsert $newCmdArgs 1 -mode $forceMode]
    }
    if {($newCmdArgs ne "")} {
	eval $newCmdArgs
    }
    # Set the project.
    docProj::currentProject [lindex $templateInfo 4]
    docProj::postBuildMenu
    # If the current project doesn't like this mode, offer to switch.  We do 
    # this now before the file header is created.
    if {($templateType ne "Empty")} {
	docProj::verifyProjectMode
    }
    return $templateInfo
}

# ===========================================================================
# 
# ×××× Document Projects ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::pickProject" --  ?p? ?multiList 0? ?includeNone 1?
 # 
 # Prompt the user for a name from the list of all current Document Projects,
 # returning that name.  If the user cancels, an error is thrown.
 # 
 # The prompt in the list-pick dialog is set by "p".
 # 
 # If "multiList" is set to 1, then the user can select multiple projects,
 # and the results are returned as a list.  Otherwise, the name of a single
 # project is returned.
 # 
 # If "includeNone" is 0, then the "None" project is not included as an 
 # option; otherwise it is added at the end of the list.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::pickProject {{p ""} {multiList 0} {includeNone 1}} {
    
    if {($p eq "")} {
	if {$multiList} {
	    set p "Select one or more projectsÉ"
	} else {
	    set p "Select a projectÉ"
	}
    }
    set options [docProj::listProjects $includeNone]
    if {!$includeNone} {
	set options [lremove $options [list "None"]]
    }
    if {![llength $options]} {
	error "Cancelled: no projects available."
    }
    if {([lsearch -exact $options [docProj::currentProject]] > -1)} {
	set L [list [docProj::currentProject]]
    } else {
	set L [lrange $options 0 0]
    }
    set script [list "listpick" "-p" $p "-L" $L]
    if {$multiList} {
	lappend script "-l"
    }
    lappend script $options
    return [eval $script]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::listProjects" --
 # 
 # List the names of all User Projects.  "None" is a special case, one that
 # cannot be edited by the user, so by default it is not included.  Various
 # options for "includeNone" allow the "None" project to be included at the
 # beginning or end of the list, possibly with dialog or menu dividers.
 # 
 # Note that the projects are listed in alphabetical order; in order to
 # determine their actual position in the various arrays the procedure
 # [docProj::projectIndex] should be used.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::listProjects {{includeNone "0"}} {
    
    variable userProjects

    set projects [lsort -dictionary $userProjects(name)]
    set projects [lremove $projects [list "None"]]
    if {($includeNone != 0)} {
	if {![llength $projects]} {
	    return [list "None"]
	}
	switch -- $includeNone {
	    "-3" {
		set projects [linsert $projects 0 "None" "(-)"]
	    }
	    "-2" {
		set projects [linsert $projects 0 "None" "-"]
	    }
	    "-1" {
	        set projects [linsert $projects 0 "None"]
	    }
	    "1" {
		set projects [linsert $projects end "None"]
	    }
	    "2" {
		set projects [linsert $projects end "-" "None"]
	    }
	    "3" {
		set projects [linsert $projects end "(-)" "None"]
	    }
	}
    }
    return $projects
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::currentProject" --
 # 
 # Returns the name of the current project.  If a "project" argument is
 # supplied, then we actually change the current project to that value.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::currentProject {{project ""}} {
    
    global documentProjectsmodeVars
    
    variable userProjects
    
    if {($project ne "") && ($project ne "*")} {
	# Ensure that we have a valid project name.
	if {[catch {docProj::projectIndex $project}]} {
	    set project "None"
	}
	# Change the current project.
	set documentProjectsmodeVars(currentProject) $project
	# Update all "extra" user information.
	set projIdx [docProj::projectIndex $project]
	foreach item [list "license" "owner" "owner_org"] {
	    userInfo::addInfo $item [lindex $userProjects($item) $projIdx]
	}
	userInfo::addInfo "project" $project
    }
    return $documentProjectsmodeVars(currentProject)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::verifyProjectMode" --
 #  
 # When we create a new file or header automatically, it contains information
 # about the current project (as defined in userProjects(...)).
 # 
 # Unfortunately we often forget to select the correct project first.  This
 # procedure makes sure that the current project is compatible with the
 # current mode, given the information in the 'userProjects' array.  If it
 # isn't then the user is informed and given another chance to change the
 # current project.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::verifyProjectMode {} {
    
    global documentProjectsmodeVars
    
    variable repeatVPM 0
    variable userProjects
    
    if {![llength [winNames]] \
      || !$documentProjectsmodeVars(confirmProjectModes)} {
	return
    }
    set project   [docProj::currentProject]
    set projIdx   [docProj::projectIndex $project]
    set projModes [lindex $userProjects(default_modes) $projIdx]
    set thisMode  [win::getMode [win::Current] 0]
    if {![llength $projModes] || ($thisMode eq "Text")} {
	# Always allow "Text" mode to belong to a project.
        return
    }
    foreach m $projModes {
	if {([mode::getName $m 0] eq $thisMode)} {
	    return
	}
    }
    set projects  [docProj::listProjects -2]
    set dialogScript [list dialog::make \
      -title "Verify Document Project Mode" \
      -width 450 \
      -ok "Continue" \
      -okhelptag "Click here to continue creating the window template" \
      -cancelhelptag "Click here to cancel the remaining template creation." \
      -addbuttons [list \
      "Edit ProjectÉ" \
      "Click here to edit your current projects" \
      "set retVal {repeat} ; set retCode 0 ; \
      set ::docProj::repeatVPM 1 ; \
      [list catch [list docProj::editProject $project]]"] \
      [list "" \
      [list "text" "The list of modes associated with \"$project\" \
      (the current project) does not include \"$thisMode\" \
      (the mode of the active window).\r"] \
      [list "text" "Please verify the current project you wish to use to\
      complete the template creation, or select a new project.\r"] \
      [list [list "menu" $projects] "Project:" $project \
      "Choose a different project, or don't use any project for this window"] \
      [list [list "smallall" "flag"] "Always confirm project mode\
      when a conflict is detected" 1] \
      ]]
    if {[catch {eval $dialogScript} results] && !$repeatVPM} {
	error $results
    } 
    if {$repeatVPM} {
	return [docProj::verifyProjectMode]
    }
    unset repeatVPM
    set newProject [lindex $results 0]
    if {($project ne $newProject)} {
	docProj::currentProject $newProject
    }
    if {![lindex $results 1]} {
	set documentProjectsmodeVars(confirmProjectModes) 0
	prefs::modified documentProjectsmodeVars(confirmProjectModes)
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::projectIndex" --
 # 
 # Given the name of a project, return its index number.  This index will
 # correspond to all "userProjects" array entries for that project.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::projectIndex {project} {
    
    variable userProjects
    
    if {([set idx [lsearch -exact $userProjects(name) $project]] > -1)} {
	return $idx
    } else {
	error "Could not find \"$project\" in the list of defined projects."
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::projectItem" --
 # 
 # Get an item in a project.  Arguments supplied can include (in this order):
 # 
 #     "item"           -- If not supplied, an error will be thrown.
 #     "project"        -- If not supplied, the Current Project will be used.
 #     "defaultValue"   -- Value to use if found value is the null string.
 #     "emergencyValue" -- Value to use if the project cannot be found.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::projectItem {args} {
    
    variable userProjectArrays
    variable userProjects
    
    # Make sure that we have a valid item.
    set item [lindex $args 0]
    if {($item eq "")} {
	error "No item specified."
    } elseif {([lsearch $userProjectArrays $item] eq "-1")} {
	error "Valid project items include: $userProjectArrays"
    }
    # Make sure that we have a specified project.
    if {([set project [lindex $args 1]] eq "")} {
	set project [docProj::currentProject]
    }
    # Attempt to obtain the proper value for the project's item.
    if {[catch {docProj::projectIndex $project} projIdx]} {
	# Return the "emergencyValue" -- the specified project doesn't exist.
	return [lindex $args 3]
    } elseif {([lindex $userProjects($item) $projIdx] eq "")} {
	# Return the "defaultValue" -- the found value is the null string.
	return [lindex $args 2]
    } else {
	# Return the found value.
	return [lindex $userProjects($item) $projIdx]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::newProject" --
 # 
 # Create this sort of stuff:
 # 
 #   set userProjects(name) [list "None" "EvoX" "Vince's Additions" "Cpptcl"]
 #   set userProjects(addendum) { {none} {evolution in complex systems} \
 #    {an extension package for Alpha} {connecting C++ with Tcl} }
 #   set userProjects(default_modes) { {} {C C++} {Tcl} {C C++ Tcl}}
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::newProject {} {
    
    variable userProjectArrays
    variable userProjects
    
    set results [docProj::projectDialog]
    set newName [lindex $results 0]
    # Make sure that the new name is not already in use.
    while {([lsearch -exact [docProj::listProjects 0] $newName] > -1)} {
	alertnote "The name \"$newName\" is already used\
	  by a different project.  Please choose a new one."
	set results [lreplace $results 0 0 ""]
	set results [docProj::projectDialog $results]
	set newName [lindex $results 0]
    }
    for {set i 0} {($i < [llength $userProjectArrays])} {incr i} {
	set varName [lindex $userProjectArrays $i]
	lappend userProjects($varName) [lindex $results $i]
	prefs::modified userProjects($varName)
    }
    # Always update current information.
    docProj::currentProject [lindex $results 0]
    menu::buildSome "Document Projects"
    status::msg "The new \"[lindex $results 0]\" project has been added."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::editProject" --
 # 
 # Offer all projects to the user to edit, and save any changed settings. 
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::editProject {{project ""}} {
    
    variable userProjectArrays
    variable userProjects
    
    set projects [docProj::listProjects "0"]
    if {($project ne "")} {
        if {([lsearch -exact $projects $project] == -1)} {
            error "Cancelled -- Unknown project: $project"
        }
	# This ensures that the user won't be asked to edit another.
	set projects [list $project]
    } else {
	switch -- [llength $projects] {
	    "0" {
		# This menu command should have been dimmed.
		docProj::postBuildMenu
		error "Cancelled -- there are no projects to edit."
	    }
	    "1" {
		set q "Edit the \"[lindex $projects 0]\" project?"
		if {[askyesno $q]} {
		    set project [lindex $projects 0]
		} else {
		    error "cancel"
		}
	    }
	    default {
		set p "Which project do you wish to edit?"
		set project [docProj::pickProject $p 0 0]
	    }
	}
    }
    set projIdx [docProj::projectIndex $project]
    for {set i 0} {($i < [llength $userProjectArrays])} {incr i} {
	set varName [lindex $userProjectArrays $i]
	lappend oldValues [lindex $userProjects($varName) $projIdx]
    }
    set newValues [docProj::projectDialog $oldValues]
    set changed 0
    for {set i 0} {($i < [llength $userProjectArrays])} {incr i} {
	set varName  [lindex $userProjectArrays $i]
	set oldValue [lindex $oldValues $i]
	set newValue [lindex $newValues $i]
	if {($oldValue ne $newValue)} {
	    set userProjects($varName) \
	      [lreplace $userProjects($varName) $projIdx $projIdx $newValue]
	    prefs::modified userProjects($varName)
	    incr changed
	}
    }
    # Always update current information.
    docProj::currentProject [docProj::currentProject]
    # If the name of the project was changed, update the menu.
    if {([lindex $newValues 0] ne $project)} {
	menu::buildSome "Document Projects"
    }
    if {$changed} {
	status::msg "The new settings have been saved."
    } else {
	status::msg "No changes."
    }
    set q "Would you like to edit another project?"
    if {([llength $projects] > 1) && [askyesno $q]} {
	docProj::editProject
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::projectDialog" --  ?defaultValues?
 # 
 # Present a dialog to the user to edit the settings of a given project.  If 
 # the "defaultValues" argument is an empty list, then we fill in some 
 # values which should be changed.
 # 
 # The "defaultValues" list _must_ be in the "userProjectArrays" order, i.e.
 # 
 #    name addendum license owner owner_org extra default_modes
 # 
 # Results are returned as a list in this order.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::projectDialog {{defaultValues ""}} {
    
    variable lastChosenOption
    variable userProjectArrays
    
    # Create our "licenses" variables.
    if {[catch {license::listTypes -2 0} licenses]} {
	set licenses [list "none"]
    }
    if {[catch {license::listTypes -2 1} Licenses]} {
	foreach type $licenses {
	    lappend Licences [quote::Prettify $type]
	}
    }
    # Make sure we have default values.
    if {![llength $defaultValues]} {
	# Try to set some defaults relevant to the user.
	if {[info exists lastChosenOption(newProjectDialog)]} {
	    # Use the values from the last time this dialog was chosen.
	    set defaultValues [lreplace \
	      $lastChosenOption(newProjectDialog) 0 0 ""]
	} else {
	    # Use any values from the user's current identity.
	    set owner     [userInfo::getInfo "author"]
	    set owner_org [userInfo::getInfo "organisation"]
	    set license   "allRightsReserved"
	}
    }
    # Now we create local variables.
    for {set i 0} {($i < [llength $userProjectArrays])} {incr i} {
	if {![info exists [lindex $userProjectArrays $i]]} {
	    set [lindex $userProjectArrays $i] [lindex $defaultValues $i]
	}
    }
    # Dialog title.
    if {($name eq "")} {
	set title "Create A New Project"
    } else {
	set title "\"[lindex $defaultValues 0]\" Project Settings"
    }
    # License -- since we prettify the license types for the dialog pop-up
    # we're going to have to some index work here.
    if {([set idx [lsearch $licenses $license]] > -1)} {
	set licenseIdx $idx
    } else {
	set licenseIdx 0
    }
    # Create the dialog script and present it to the user.
    set dialogScript [list dialog::make \
      -title $title \
      -width 450 \
      -addbuttons [list \
      "Help" \
      "Click this button for more help" \
      "help::openGeneral documentProjects {} ; \
      set retCode 1 ; set retVal {cancel}" \
      ] \
      [list "" \
      [list "var" "Short Descriptive Name:" $name] \
      [list "var" "Longer Descriptive Name:" $addendum] \
      [list [list "menuindex" $Licenses] "License Type:" $licenseIdx] \
      [list "var" "License Owner:" $owner] \
      [list "var" "License Organization:" $owner_org] \
      [list "var2" "Additional text for end of header comments:" $extra] \
      [list "var" "Modes (blank = all):" $default_modes] \
      ]]
    set results [eval $dialogScript]
    # Massage the license info again.
    set license [lindex $licenses [lindex $results 2]]
    set results [lreplace $results 2 2 $license]
    # If we don't have a proper name, then we try again.  Otherwise we return
    # the values that we've collected, saving defaults for the next round.
    if {([string trim [lindex $results 0]] eq "")} {
	alertnote "The name of the project cannot be empty!"
	return [docProj::projectDialog $results]
    } else {
	set lastChosenOption(newProjectDialog) $results
	prefs::modified lastChosenOption(newProjectDialog)
	return $results
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::removeProject" --
 # 
 # Offer the list of projects for the user to remove, and delete those 
 # entries from all "userProjects" array lists. 
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::removeProject {} {
    
    variable userProjectArrays
    variable userProjects
    
    set projects [docProj::listProjects "0"]
    switch -- [llength $projects] {
	"0" {
	    # This menu command should have been dimmed.
	    docProj::postBuildMenu
	    error "Cancelled -- there are no projects to remove."
	}
	"1" {
	    set q "Remove the \"[lindex $projects 0]\" project?"
	    if {![askyesno $q]} {
		error "cancel"
	    }
	}
	default {
	    set p "Remove which project(s)?"
	    set projects [docProj::pickProject $p 1 0]
	}
    }
    foreach project $projects {
	set projIdx [docProj::projectIndex $project]
	foreach varName $userProjectArrays {
	    set userProjects($varName) \
	      [lreplace $userProjects($varName) $projIdx $projIdx]
	    prefs::modified userProjects($varName)
	}
	if {($project eq [docProj::currentProject])} {
	    docProj::currentProject "None"
	}
    }
    menu::buildSome "Document Projects"
    if {([llength $projects] == 1)} {
	set msg "The project \"$project\" has been removed."
    } else {
	set msg "The projects \"[join $projects ", "]\" have been removed."
    }
    status::msg $msg
    return
}

# ===========================================================================
# 
# ×××× Document Templates ×××× #
# 

proc docProj::listTemplates {{w ""} {modeSpecific ""} {other ""}} {
    
    global elec::DocTemplates
    
    if {($other ne "")} {
	upvar 1 $other noList
    }
    set tlist ""
    set noList ""
    if {($w ne "") && ($w ne "untitled")} {
	set m [win::FindMode $w]
	foreach t ${elec::DocTemplates} {
	    if {[docProj::templateMatchExt $t $w $m]} {
		lappend tlist [lindex $t 1]
	    } else {
		lappend noList [lindex $t 1]
	    }
	}
    } else {
	foreach t ${elec::DocTemplates} {
	    if {($modeSpecific eq "") \
	      || [string match [lindex $t 0] $modeSpecific]} {
		lappend tlist [lindex $t 1]
	    } else {
		lappend noList [lindex $t 1]
	    }
	}
    }
    return [lsort -dictionary $tlist]
}

proc docProj::templateMatchExt {t f {m ""}} {
    
    if {($m eq "")} {
	set m [file::whichModeForWin $f]
    }
    # Match everything to a file with no particular extension.
    if {($m eq "Text")} {
	return 1
    }
    set l [lindex $t 0]
    set mMatch [expr [lsearch -exact $l $m] != -1]
    switch -- [lindex $t 2] {
	"None" -
	"Basic" -
	"*" {
	    if {($l eq "*")} {
		return 1
	    } else {
		return $mMatch
	    }
	}
	"Header" {
	    if {$mMatch} {
		return [file::isHeader $f $m]
	    }
	}
	"Source" {
	    if {$mMatch} {
		return [file::isSource $f $m]
	    }
	    
	}
    }
    return 0
}

proc docProj::templateInfo {name} {
    
    global elec::DocTemplates
    
    foreach t ${elec::DocTemplates} {
	if {($name eq [lindex $t 1])} {
	    return $t
	}
    }
}

proc docProj::templateIndex {name} {
    
    global elec::DocTemplates
    
    set i 0
    foreach t ${elec::DocTemplates} {
	if {($name eq [lindex $t 1])} {
	    return $i
	} else {
	    incr i
	}
    }
    # Still here?
    error "Could not identify project index: $name"
}

proc docProj::newTemplate {{subCall 0}} {
    
    global elec::DocTemplates
    
    set results [docProj::templateDialog]
    set newName [lindex $results 1]
    # Make sure that the new name is not already in use.
    while {([lsearch -exact [docProj::listTemplates] $newName] > -1)} {
	alertnote "The name \"$newName\" is already used\
	  by a different project.  Please choose a new one."
	set results [lreplace $results 1 1 ""]
	set results [docProj::templateDialog $results]
	set newName [lindex $results 0]
    }
    set newTemplate $results
    lappend elec::DocTemplates $newTemplate
    # Save it permanently.
    prefs::modified elec::DocTemplates
    # Add template to "prefs.tcl".
    set procName [lindex $newTemplate 3]
    set subTypes [lindex $newTemplate 5]
    if {($procName ne "\#")} {
	set def [docProj::getTemplateText \
	  "Do you want to use this as the template?" "" t]
	set t "\r"
	append t "proc $procName \{docname parentdoc"
	if {($subTypes ne "")} {
	    append t " sub-type "
	}
	append t "\} \{\r"
	append t "\t# You must fill this in\r"
	if {($subTypes ne "")} {
	    append t "\t# Possible 'sub-types' are: $subTypes\r"
	}
	append t $def
	append t "\r\treturn \$t\r\}\r"
	prefs::addGlobalPrefsLine $t
	if {[askyesno "I've added a template for the procedure\
	  to your 'prefs.tcl'. Do you want to edit it now?"]} {
	    prefs::editPrefsFile
	    goto [maxPos]
	    if {$subCall} {
		alertnote "Once you've finished editing,\
		  press Command-N to go back and create a new document."
		# So our calling proc stops.
		error "Cancelled -- Editing template."
	    }
	}
    }
    return [lindex $newTemplate 1]
}

proc docProj::getTemplateText {text {defaultValue ""} {var ""}} {
    
    if {[llength [winNames -f]] && [isSelection]} {
	if {[askyesno "You've selected some text. $text"]} {
	    set defaultValue [getSelect]
	}
    }
    if {![string length $defaultValue]} {
	set p "Enter template text (you can edit it later)"
	set defaultValue [getline $p $defaultValue]
    }
    if {($var ne "")} {
	return [elec::_MakeIntoInsertion $defaultValue $var]
    } else {
	return $defaultValue
    }
}

proc docProj::editTemplate {} {
    
    global elec::DocTemplates
    
    set p "Which document template do you want to edit?"
    set tempName [listpick -p $p [docProj::listTemplates]]
    set tempIdx  [docProj::templateIndex $tempName]
    set tempInfo [docProj::templateDialog [docProj::templateInfo $tempName]]
    set elec::DocTemplates \
      [lreplace ${elec::DocTemplates} $tempIdx $tempIdx $tempInfo]
    prefs::modified elec::DocTemplates
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::templateDialog" --
 # 
 # Present a dialog to the user to edit the settings of a given template.  If
 # the "defaultValues" argument is an empty list, then we fill in some values
 # which should be changed.
 # 
 # The "defaultValues" list _must_ be in the "templateItems" order, i.e.
 # 
 #    modes name fileType procName project subTypes
 # 
 # Results are returned as a list in this order.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::templateDialog {{defaultValues ""}} {
    
    variable lastChosenOption
    variable templateItems
    
    # Dialog title.
    if {([lindex $defaultValues 1] eq "")} {
	set title "Create A New Document Template"
    } else {
	set title "Edit The \"[lindex $defaultValues 1]\" Document Template"
    }
    if {![llength $defaultValues]} {
	# Try to create some relevant default values.
	if {[info exists lastChosenOption(newTemplateDialog)]} {
	    # Use the values from the last time this dialog was chosen.
	    set defaultValues [lreplace \
	      $lastChosenOption(newTemplateDialog) 0 1 "" ""]
	} else {
	    # Try to guess what might be useful.
	    set procName "t_XXX"
	    set project  [docProj::currentProject]
	}
    }
    for {set i 0} {($i < [llength $templateItems])} {incr i} {
	set [lindex $templateItems $i] [lindex $defaultValues $i]
    }
    # Manipulate values as needed.
    if {($modes eq "*")} {
	set modes ""
    }
    if {($fileType eq "*")} {
	set fileType "Either"
    }
    if {($project eq "*")} {
	set project "Basic"
    }
    if {($procName eq "\#")} {
	set procName ""
    }
    set fileTypeOptions [list "None" "-" "Basic" "Source" "Header" "Either"]
    if {([lsearch $fileTypeOptions $fileType] == -1)} {
	set fileType "None"
    }
    set projects [docProj::listProjects 2]
    if {[catch {docProj::projectIndex $project}]} {
	set project [docProj::currentProject]
    }
    # Create the dialog script and present it to the user.
    set dialogScript [list dialog::make \
      -title $title \
      -width 450 \
      -addbuttons [list \
      "Help" \
      "Click this button for more help" \
      "help::openGeneral documentProjects {} ; \
      set retCode 1 ; set retVal {cancel}" \
      ] \
      [list "" \
      [list "var" "Descriptive Name:" $name] \
      [list "var" "Modes (blank = all):" $modes] \
      [list "var" "Procedure Name:" $procName] \
      [list "text" "Select a file type for this document template.\r\
      (If \"Source\" or \"Header\", the mode must define preferences\
      for \"Source Suffices\" and \"Header Suffices\".)"] \
      [list [list "menu" $fileTypeOptions] "File Type:" $fileType] \
      [list [list "menu" $projects] "Project:" $project] \
      [list "var2" "List of sub-types handled by the procedure:" $subTypes] \
      ]]
    set results  [eval $dialogScript]
    set varNames [list name modes procName fileType project subTypes]
    for {set i 0} {($i < [llength $varNames])} {incr i} {
	set [lindex $varNames $i] [lindex $results $i]
    }
    # Manipulate values as needed.
    if {($modes eq "")} {
	set modes "*"
    }
    if {($fileType eq "Either")} {
	set fileType "*"
    }
    if {($project eq "None")} {
	set project "*"
    }
    if {($procName eq "")} {
	set procName "\#"
    }
    set results [list $modes $name $fileType $procName $project $subTypes]
    # If we don't have a proper name, then we try again.  Otherwise we return
    # the values that we've collected, saving defaults for the next round.
    if {([string trim [lindex $results 0]] eq "")} {
	alertnote "The name of the project cannot be empty!"
	return [docProj::projectDialog $results]
    }
    set lastChosenOption(newTemplateDialog) $results
    prefs::modified lastChosenOption(newTemplateDialog)
    return $results
}

proc docProj::removeTemplate {} {
    
    global elec::DocTemplates
    
    set p "Remove which template(s) ?"
    set templates [listpick -p $p -l [docProj::listTemplates]]
    foreach template $templates {
	set tempIdx [docProj::templateIndex $template]
	set elec::DocTemplates \
	  [lreplace ${elec::DocTemplates} $tempIdx $tempIdx]
    }
    prefs::modified elec::DocTemplates
    return
}

# ===========================================================================
# 
# ×××× File Headers ×××× #
# 

## 
 # --------------------------------------------------------------------------
 #  
 # "docProj::createHeader" --
 # 
 # Insert a descriptive header into the current window.  Needs to be tailored
 # more to different modes, but isn't too bad right now.  We do assume that
 # the window has already been created and is editable.
 #  
 # 'template' is a pre-defined six-item list including
 # 
 #   modes
 #   name
 #   headerType
 #   procName
 #   project
 #   subTypes
 # 
 # The "header type" should be one of "None", "Basic", "Source", or "Header"
 # (with "*" treated as either a source or a header) 
 # 
 # The procedure name (the fourth item) will be called (if non-empty) after
 # we have created the header to insert some more text into the window.
 #  
 # The second argument 'parent' gives the name of a class from which the
 # generated file descends (appropriate for C++, [incr Tcl] for example), and
 # is passed onto any template procedure.
 # 
 # Yes, this is all a bit convoluted...
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::createHeader {{templateInfo ""} {parent ""}} {
    
    global documentProjectsmodeVars errorInfo
    
    if {([lindex $templateInfo 1] eq "Empty")} {
	return ""
    }
    # Create a divider string specific to mode values and user preference.
    variable dividerString [string repeat \
      [string trim $documentProjectsmodeVars(headerDividerCharacter)] \
      [expr {[win::getModeVar [win::Current] "fillColumn" 77] - 3}]]
    
    if {($parent eq "")} {
	set parent "¥parent¥"
    }
    if {($templateInfo eq "")} {
	set templateInfo [list "" "" "Header" "\#" "" ""]
    }
    # Make the header.
    set headerText ""
    if {([set className [file::className]] eq "untitled")} {
	set className "¥class name¥"
    }
    set fileTail [win::StripCount [win::CurrentTail]]
    # Add more to the header depending on the document type.
    set docHeadType [lindex $templateInfo 2]
    if {($docHeadType ne "None")} {
	if {[catch {append headerText [docProj::topHeader]} result]} {
	    # Debugging tool -- this should never happen.
	    alertnote "\[docProj::topHeader\] error!\r\r$result"
	}
	append headerText "\r"
	if {($docHeadType ne "Basic")} {
	    if {($docHeadType eq "Source") || [file::isSource $fileTail]} {
		# It's a source file.
		append headerText "See header file for further information\r"
	    } elseif {($docHeadType eq "Header")
	    || (($docHeadType eq "*") && [file::isHeader $fileTail])} {
		append headerText \
		  "History\r\r" \
		  "modified   by  rev reason\r" \
		  "---------- --- --- -----------\r" \
		  "[docProj::paddedDate [docProj::createdDate 0]] " \
		  "[userInfo::getInfo author_initials] 1.0 original\r"
	    } else {
		# Not header or source or basic... oh well!
	    }
	}
	set headerText "[string trimright $headerText]\r\r"
	append headerText $dividerString
	set headerText [comment::TextBlock $headerText]
	# Add this to the end of the first line.
	regsub "\r" $headerText "-*-[win::getMode]-*-\r" headerText
    }
    # Now add any additional template based on the user's preferences.  Even 
    # if we encounter errors, we attempt to complete the insertion.
    set procName [lindex $templateInfo 3]
    if {($procName ne "\#") && ![llength [info commands $procName]]} {
	if {![auto_load $procName]} {
	    alertnote "The document contents procedure\
	      \"$procName\" doesn't exist"
	}
    } else {
	lappend script $procName $className $parent
	if {![catch {eval $script [lindex $templateInfo 5]} moreText]} {
	    append headerText $moreText
	} elseif {[askyesno "Template Error!\
	  \r\rWould you like to view the details?"]} {
	    new -n "* '$procName' error *" -m Tcl -info $errorInfo
	    error "Cancelled"
	}
    }
    goto [minPos]
    elec::Insertion $headerText
    return ""
}

## 
 # --------------------------------------------------------------------------
 #  
 # "docProj::topHeader" --
 # 
 # Returns the top part of a descriptive header for the active window,
 # including the name of the file, time-stamps, user information, license
 # type, and anything "extra" defined for the current project.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::topHeader { } {
    
    global timeStampStyle documentProjectsmodeVars
    
    variable description
    variable dividerString
    variable lastChosenOption
    
    set fileTail [win::StripCount [win::CurrentTail]]
    set filePath [win::StripCount [win::Current]]
    set modeFCol [win::getModeVar [win::Current] "fillColumn" 77]
    set rightCol [expr {$modeFCol - 3}]
    if {[catch {file stat $filePath info}]} {
	set created [mtime [now] $timeStampStyle]
	set lastMod $created
    } else {
	set created [mtime $info(ctime) $timeStampStyle "unix"]
	set lastMod [mtime [file mtime $filePath] $timeStampStyle "unix"]
    }
    append t $dividerString "\r"
    if {([docProj::currentProject] ne "*")} {
	append t [docProj::currentProject]
	if {([set projectAddendum [docProj::projectItem {addendum}]] ne "")} {
	    append t " - " $projectAddendum
	}
	append t "\r"
    }
    append t "\r"
    append t "FILE: \"" $fileTail "\"\r"
    append t [format {%45s} {created: }]     $created "\r"
    append t [format {%45s} {last update: }] $lastMod "\r"
    if {$documentProjectsmodeVars(includeHeaderDescription)} {
	append t "Description:\r\r"
	append t [breakIntoLines $description $rightCol] "\r\r"
    }
    append t "Author: " [userInfo::getInfo author "¥author¥"] "\r"
    append t "E-mail: <" [userInfo::getInfo email "¥email¥"] ">\r"
    if {([set userOrg [userInfo::getInfo organisation]] ne "")} {
	append t "  mail: " $userOrg "\r"
    }
    if {([set userAddress [userInfo::getInfo address]] ne "")} {
	foreach addressLine [split $userAddress "\r\n"] {
	    append t "        " [string trim $addressLine] "\r"
	}
    }
    if {([set userWWW [userInfo::getInfo www]] ne "")} {
	append t "   www: <" $userWWW ">\r"
    }
    if {([set userLicense [userInfo::getInfo "license" "none"]] ne "none")} {
	if {![catch {license::getTemplate $userLicense} licenseTemplate]} {
	    append t " \r" $licenseTemplate
	}
    }
    if {([set projectExtra [docProj::projectItem "extra"]] ne "")} {
	set rightCol [expr {$modeFCol - 3}]
	append t [breakIntoLines $projectExtra $rightCol] "\r \r"
    }
    return "[string trimright $t]\r"
}

proc docProj::paddedDate {{when ""} {epoch ""}} {
    
    if {($when eq "")} {
	set when [now]
	set epoch ""
    }
    ISOTime::brokenDate $when date $epoch
    return [format "%0.4d-%0.2d-%0.2d" $date(year) $date(month) $date(day)]
}

proc docProj::createdDate {{convert 1}} {
    
    global timeStampStyle
    
    if {[catch {file stat [win::Current] info}]} {
	if {$convert} {
	    return [mtime [now] $timeStampStyle]
	} else {
	    return [now]
	}
    } else {
	if {$convert} {
	    return [mtime $info(ctime) $timeStampStyle "unix"]
	} else {
	    return $info(ctime)
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::updateGeneralDate" --
 #  
 # Updates the date in the header of a file.  Normally this is the 'last
 # update' date, but we can override that if desired.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::updateGeneralDate {name {patt ""} {time ""}} {
    
    if {($patt eq "")} {
	set patt {last update: }
    }
    regsub -all { } $patt "\[ \t\]" spatt
    set pos [getPos -w $name]
    set end [selEnd -w $name]
    if {[isSelection -w $name]} {
	set remember [list $pos $end]
    }
    append hour {[0-9][0-9]?(:|\.)[0-9][0-9]((:|\.)[0-9][0-9])?}
    append hour {(([ \t][APap][Mm])|Z)?}
    set date {[0-9][0-9]*(/|\.|\-)[0-9][0-9]*(/|\.|\-)[0-9][0-9]*}
    append spatt "\[ \t\]*" $date "(\[ \tT]\{?" $hour {\}?)?}
    set datePos [search -w $name -s -n -f 1 -r 1 -m 0 \
      -l [pos::math -w $name [minPos] + 3000] $spatt [minPos]]
    if {![llength $datePos]} {
	return 0
    }
    if {($time eq "")} {
	global timeStampStyle
	set time [mtime [now] $timeStampStyle]
    }
    if {([eval [list getText -w $name] $datePos] eq $time)} {
	return 0
    }
    # The following line illustrates a bug in Alpha.  If we're sufficiently
    # near the bottom of a large window, the pane is cleared (a cosmetic
    # problem).  We have to hit cmd-L to see what's going on.
    eval [list replaceText -w $name] $datePos [list $patt $time]
    if {[info exists remember]} {
	eval [list selectText -w $name] $remember
    }
    return 1
}

proc docProj::updateCopyrightYear {name} {
    
    set patt {(copyright (\(C\) )?([1-9][0-9][0-9][0-9]))([-,] ?([0-9]+))?}
    set pos [search -w $name -s -n -f 1 -r 1 -i 1 -m 0 \
      -l [pos::math -w $name [minPos] + 2000] $patt [minPos]]
    if {![llength $pos]} {
	return 0
    }
    # Find the last consecutive copyright notice
    while {1} {
	set npos [nextLineStart -w $name [lindex $pos 1]]
	set nextpos [search -w $name -s -n -f 1 -r 1 -m 0 \
	  -l [nextLineStart -w $name $npos] $patt $npos]
	if {[llength $nextpos]} {
	    set pos $nextpos
	} else {
	    break
	}
    }
    set t [eval [list getText -w $name] $pos]
    regexp -nocase $patt $t "" start "" yr1 "" yr2
    set thisyear [lindex [lindex [mtime [now] long] 0] 3]
    if {($yr2 ne "")} {
	if {[string length $yr2] < 4} {
	    set yr2 "[string range $yr1 0 [expr {[string length $yr2] -1}]]$yr2"
	}
	if {($thisyear eq $yr2)} {
	    return 0
	}
    } else {
	if {($thisyear eq $yr1)} {
	    return 0
	}
    }
    if {[isSelection]} {
	set remember [list [getPos -w $name] [selEnd -w $name]]
    }
    eval [list replaceText -w $name] $pos [list "${start}-$thisyear"]
    if {[info exists remember]} {
	eval [list selectText -w $name] $remember
    }
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "docProj::exampleHeader" --
 # 
 # Called by a help window hyperlink, create a new window with an example 
 # header so that the user knows what to expect.
 # 
 # --------------------------------------------------------------------------
 ##

proc docProj::exampleHeader {} {
    
    set w [new -mode "Tcl" -n "* Example File Header *"]
    file::createHeader [docProj::templateInfo "Default"]
    winReadOnly $w
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× "Utils > Win Utils" procedures ×××× #
# 
# These procedures _must_ be in the "file" namespace in order for them to be
# properly called by the [menu::fileUtils] procedure.  By default, they
# should operate on the active window.
# 

namespace eval file {}

proc file::updateDate {} {
    return [docProj::updateGeneralDate [win::Current]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "file::updateFileVersion" --
 # 
 # Update the version number and information in the header block of a file.
 # Copes with both my old and new formats.
 # 
 # --------------------------------------------------------------------------
 ##

proc file::updateFileVersion {} {
    
    # In case the user wishes to return quickly.
    placeBookmark
    
    goto [minPos]
    set begin [lindex [comment::Characters Paragraph] 2]
    set pos [lindex [file::findClosestMatch "_/_/_" 0] 0]
    if {($pos eq "") || [pos::compare $pos > [pos::math [minPos] + 1000]]} {
	set srch [quote::WhitespaceReg [quote::Regfind "${begin} " ]]
	append srch {[0-9]+(/|\.|\-)[0-9]+(/|\.|\-)[0-9]+}
	set pos [lindex [file::findClosestMatch $srch 1] 0]
	if {($pos eq "")} {
	    status::msg "Couldn't find original version template."
	    set srch [quote::Regfind "${begin} "]
	    append srch "See header file for further information"
	    set pos [lindex [file::findClosestMatch [quote::WhitespaceReg $srch]] 0]
	    if {($pos != "")} {
		set pos [nextLineStart $pos]
	    } else {
		goto [minPos]
		set pat "${begin}\#\#\#"
		set pos [lindex [file::findClosestMatch $pat] 0]
		if {($pos eq "")} {
		    status::msg "Couldn't find any header"
		    return
		}
		set posSearch [pos::nextLineStart $pos]
		set pos [lindex [search -s -f 1 -n -- $pat $posSearch] 0]
		if {($pos eq "")} {
		    status::msg "Couldn't find any header"
		    return
		}
	    }
	    goto $pos
	    set t  "${begin}\r"
	    append t  "${begin} modified   by  rev reason\r"
	    append t  "${begin} ---------- --- --- -----------\r"
	    append t  "${begin} [file::paddedDate]"
	    append t  " [userInfo::getInfo author_initials {   }] 1.0 original\r"
	    insertText $t
	    selectText $pos [getPos]
	    return ""
	} else {
	    # This is the normal case.  Find the last version number.
	    set p [nextLineStart $pos]
	    while {[pos::compare $p > $pos]} {
		set pos $p
		set p [lindex [file::findClosestMatch $srch 1 [nextLineStart $p] ] 0]
	    }
	    set pos [nextLineStart $pos]
	}
    } else {
	# Old style header.
	set pos [lineStart $pos]
	replaceText $pos [nextLineStart $pos] ""
    }
    # Now pos is at the start of the line where we wish to insert.
    goto $pos
    elec::Insertion "${begin} [file::paddedDate] [userInfo::getInfo author_initials] ¥¥ ¥¥\r"
    status::msg "Pop position to return to where you were."
    return ""
}

# ===========================================================================
# 
# ×××× Electric Menu Support ×××× #
# 

# Use this simple proc if the user doesn't use the "newDocument" package.
# (If "newDocument" has not been activated yet, then it will simply re-define
# [file::newDocument] when it is loaded.)

if {![package::active newDocument] \
  || ![llength [info procs ::file::newDocument]]} {
    ;proc file::newDocument {} {
	beep
	::docProj::newHandler -n [statusPrompt "New doc name:"]
    }
}

proc file::createHeader {args} {
    
    # Make sure that all necessary variables and preferences are in place.
    docProj::initializePackage
    # Make sure the current project is compatible with this mode
    docProj::verifyProjectMode
    return [eval docProj::createHeader $args]
}

proc file::newFunction {} {
    
    requireOpenWindow
    elec::Insertion "[file::className]::¥name¥(¥args¥){\r\t¥body¥\r}\r"
    return
}

proc file::createNewClass {} {
    
    requireOpenWindow
    # Make sure that all necessary variables and preferences are in place.
    docProj::initializePackage
    # If the current project doesn't like this mode, offer to switch.
    docProj::verifyProjectMode
    beep
    set class [statusPrompt "A name for the new class:"]
    set parent [statusPrompt "Descended from:" ]
    switch -- [win::getMode] {
	"C" -
	"C++" {
	    file::createHeader [docProj::createDocument \
	      "new -mode C++ -n ${class}.cc" C++] $parent
	    file::createHeader [docProj::createDocument \
	      "new -mode C++ -n ${class}.h" C++] $parent
	}
	"Tcl" {
	    file::createHeader [docProj::createDocument \
	      "new -mode Tcl -n ${class}.tcl" Tcl] $parent
	}
	default {
	    status::msg "No class procedure defined for your mode.\
	      Why not write one yourself?"
	}
    }
    return
}

proc file::className {} {
    
    requireOpenWindow
    return [file::baseName [win::CurrentTail]]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× User Templates ×××× #
# 
# Formerly:
# 
# Vince's Additions - an extension package for Alpha
# 
# FILE: "userTemplates.tcl"
#                                    created: 2/8/97 {1:07:29 pm} 
#                                last update: 02/16/2000 {19:00:00 PM} 
# Author: Vince Darley
# E-mail: <vince@santafe.edu>
#   mail: 317 Paseo de Peralta
#         Santa Fe, NM 87501, USA
#    www: <http://www.santafe.edu/~vince/>
# 

proc t_default { class parent } {
    return "\r¥file body¥\r"
}

proc t_latex {class parent subType} {
    # Possible 'subTypes' are: article book letter report slides
    set t "%&LaTeX\r\r\\documentclass\[¥type-size¥\]\{$subType\}\r"
    if {($subType ne "letter")} {
	append t "\\usepackage\{¥package names¥\}\r"
	append t "\\begin\{document\}\r\r¥Body of document¥\r\r"
	append t "\\bibliography\{¥bib names¥\}\r"
	append t "\\bibliographystyle\{¥bibstyle¥\}\r"
	append t "\\end\{document\}\r"
	return $t
    }
    # letter:
    append t "\r\\address\{%\r\t¥your name¥\t\\\\\t\r"
    append t "\t¥your address¥\t\\\\\r"
    append t "\t¥more address¥\t\\\\\r"
    append t "\t¥city-state-zip¥\r\}\r"
    append t "\r\\date\{¥date¥\}  % optional\r"
    append t "\\signature\{¥signature¥\}\r"
    append t "\r\\begin\{document\}\r"
    append t "\r\\begin\{letter\}\{%\r"
    append t "\t¥addressee's name¥ \\\\\t\r"
    append t "\t¥addressee's address¥\t\\\\\t\r"
    append t "\t¥more addressee's address¥\t\\\\\r"
    append t "\t¥addressee's city-state-zip¥\r"
    append t "\}\r\r\\opening\{Dear ¥addressee¥,\}\r"
    append t "\r¥letter body¥\r\r\\closing\{Sincerely,\}\r"
    append t "\r\\encl\{¥¥\}\r\\cc\{¥¥\}\r"
    append t "\r\\end\{letter\}\r\r"
    append t "\\end\{document\}\r"
    return $t
}

proc t_html {class parent} {
    append t "<HTML>\r\r<HEAD>\r\r<TITLE>¥title¥</TITLE>\r"
    append t "\r\r</HEAD>\r\r<BODY>\r"
    append t "\r¥body¥\r\r</BODY>\r"
    append t "\r</HTML>"
    return $t
}

proc t_cpp_header { class parent } {
    set Text "\r\#ifndef _[docProj::currentProject]_${class}_\r"
    append Text "\#define _[docProj::currentProject]_${class}_\r\r\r"
    append Text "#include \"${parent}.h\"\r\r"
    append Text "class ${class}: public ${parent} \{\r"
    append Text "  public:\r"
    append Text "\t${class}(void);\r"
    append Text "\t~${class}(void);\r"
    append Text "  protected:\r\r"
    append Text "  private:\r"
    append Text "\};\r"
    append Text "\r\#endif\r"
    return $Text
    set docBody
}

proc t_cpp_source { class parent } {
    set Text "\r\#include \"${class}.h\"\r\r"
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Back Compatibility ×××× #
# 
# These are back compatibility procedures; we're now using the "docProj" 
# namespace whenever possible.
# 

namespace eval file {}

proc file::findLocally {args} {
    warningForObsProc "file::findClosestMatch"
    return [eval file::findClosestMatch $args]
}

proc file::projectName {args} {
    warningForObsProc "docProj::currentProject"
    return [eval docProj::currentProject $args]
}

proc file::createDocument {args} {
    warningForObsProc "docProj::createDocument"
    return [eval docProj::createDocument $args]
}

proc file::coordinateProjectForMode {args} {
    warningForObsProc "docProj::verifyProjectMode"
    return [eval docProj::verifyProjectMode $args]
}

proc file::getProjectItem {args} {
    warningForObsProc
    set arg0 [lindex $args 0]
    set arg1 [lindex $args 1]
    set args [lreplace $args 0 1 $arg1 $arg0]
    return [eval docProj::projectItem $args]
}

proc file::projectAddendum {args} {
    warningForObsProc
    return [docProj::projectItem "addendum"]
}

proc file::projectExtra {args} {
    warningForObsProc
    return [docProj::projectItem "extra"]
}

proc file::projectLicense {args} {
    warningForObsProc
    return [userInfo::getInfo "license" "none"]
}

proc file::docTemplates {args} {
    warningForObsProc "docProj::listTemplates"
    return [eval docProj::listTemplates $args]
}

proc file::docTemplateMatchExt {args} {
    warningForObsProc "docProj::templateMatchExt"
    return [eval docProj::templateMatchExt $args]
}

proc file::docTemplateInfo {args} {
    warningForObsProc "docProj::templateInfo"
    return [eval docProj::templateInfo $args]
}

proc file::docTemplateIndex {args} {
    warningForObsProc "docProj::templateIndex"
    return [eval docProj::templateIndex $args]
}

proc file::topHeader {args} {
    warningForObsProc "docProj::topHeader"
    return [eval docProj::topHeader $args]
}

proc file::paddedDate {args} {
    warningForObsProc "docProj::paddedDate"
    return [eval docProj::paddedDate $args]
}

proc file::created {args} {
    warningForObsProc "docProj::createdDate"
    return [eval docProj::createdDate $args]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 07/29/97 vmd 0.1    Original
#  -> 2005     - 1.8  Various changes throughout the years.
# 12/26/05 cbu 2.0a1  Canonical Tcl formatting.  (No code changes.)
#                     Updated annotation.  (No code changes.)
# 12/26/05 cbu 2.0a2  Re-organized procedures in file.  (No code changes.)
#                     Segregated "BSD License" and "Win Utils" procedures.
#                     "Tcl Procedures > Reformat Proc" on all procedures.
# 12/26/05 cbu 2.0a3  Placing all relevant procedures in "docProj" namespace.
#                     (For the time being, all of the [file::header] procs
#                       have been left alone, since some users might have
#                       modified versions of them in their "prefs.tcl" or
#                       Smarter Sources files.  Need advice.)
# 12/26/05 cbu 2.0b1  "documentProjects" is now a "global-only" feature.
#                     New [docProj::initializePackage] procedure.
#                     New [docProj::activatePackage] procedure.
# 12/26/05 cbu 2.0b2  Continued all (well, most) long lines.
#                     Better initial setting of "identities(Usual)".
#                     New "Config > Preferences > Document Projects" menu.
#                     Removed all obsolete [global::...] procedures.
#                     Removed all obsolete [Docproj::...] procedures.
#                     Simplified some of the "<util>Template" proc names.
# 12/27/05 cbu 2.0b3  "docTemplatesModeSpecific" preference finally works!
#                     Last template chosen remembered for each specific mode
#                       in [docProj::createDocument].
#                     Fixed subtype script handling in [file::createHeader].
#                     Using "documentProjectsmodeVars" array for storing all
#                       preferences defined by this package.
#                     More consistent use of [docProj::currentProject].
# 12/27/05 cbu 2.0b4  [docProj::changeProject] merged into [currentProject]
#                     [docProj::postBuildMenu] fix.
#                     Added (again) all relevant "elec::LicenseTemplates".
#                     New [docProj::projectIndex] procedure.
#                     User Projects stored in local "userProjects" array.
#                     Initialization checks for proper "userProjects" items.
#                     Updated project editing procedures.
#                     Start of [file::topHeader] clean-up.
#                     Updated [docProj::projectDialog] using [dialog::make].
#                     Fixes for [docProj::getProjectItem] args change.
#                     [docProj::currentProject] special case for "*".
# 12/28/05 cbu 2.0b5  New [docProj::listProjects] procedure.
#                     "docProjArrays" variable renamed "userProjectArrays".
#                     [docProj::getProjectItem] renamed [docProj::projectItem].
#                     Updated [docProj::templateDialog] using [dialog::make].
#                     [docProj::docTemplates] renamed [docProj::listTemplates].
#                     [docProj::docTemplate...] renamed [docProj::template...].
#                     Defining "elec" variables in [namespace eval elec ...].
#                     Moved [file::bsdLicense], [file::licenseOrg], and
#                       [file::licenseOwner] into "elecTemplateExamples.tcl";
#                       we re-define procs to extract project information.
#                     "elecTemplateExamples.tcl" defines the variable 
#                       "elec::LicenseTemplates" when it is sourced.
#                     [file::findLocally] renamed [file::findClosestMatch] 
#                       and moved into SystemCode "fileManipulation.tcl".
#                     Incorporated the body of [file::notTextMode] into
#                       [win::insertModeLine], the only proc which used it.
#                     Moved [file::_varValue] into "electricMenu.tcl", the
#                       only file in AlphaTcl which uses it.
#                     Removed obsolete [file::doUpdateCopyrightYear].
# 12/29/05 cbu 2.0b6  New SystemCode "identities" CorePackage.
#                     Removed all DocProject traces of identity setting.
#                     Merged "Current Project" menu into "Document Projects".
#                     [docProj::currentProject] properly sets product (again).
#                     [docProj::currentProject] updates extra user info.
#                     Using [userInfo::getInfo] when appropriate.
#                     Using [docProj::projectItem] when appropriate.
#                     Removed some newly obsolete procedures.
# 12/30/05 cbu 2.0b7  Fixed "www" bug in [docProj::topHeader].
#                     Ensure the current project info is always set.
#                     New "headerDividerCharacter" preference for headers.
#                     New "includeHeaderDescription" pref for headers.
#                     Removed obsolete "license" procedures.
#                     Removed unused [file::updateCreationDate] procedure.
#                     Enhanced [docProj::createDocument] dialog w/ options.
#                     Better default values in [docProj::templateDialog].
# 01/02/06 cbu 2.0b8  [file::_getDefault] now defined in "electricMenu.tcl".
#                     New [docProj::verifyProjectMode], replacing spirit and
#                       use of [docProj::coordinateProjectForMode].
#                     New "confirmProjectModes" preference.
#                     Additional "edit" [docProj::createDocument] buttons.
# 01/03/06 cbu 2.0b9  Making use of new "licenseTemplates" package.
#                     Added "License Templates Help" menu item.
#                     Added back compatibility proc [file::findLocally].
# 01/09/06 cbu 2.0    Code appears stable enough to be a "final" 2.0 release.
# 01/13/06 cbu 2.0.1  Added "project" user information field.
# 02/27/06 cbu 2.0.2  Added [warningForObsProc] recommended proc names.
#                     Project modes might be user-interface names.
#                     More tooltip tags for dialogs.
#                     [docProj::editProject] allows project to be specified.
#                     [docProj::verifyProjectMode] always allows "Text" mode.
#                     [docProj::verifyProjectMode] "Edit Project" button.
# 

# ===========================================================================
# 
# .