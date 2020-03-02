# -*-Tcl-*- (indentationAmount:2)
##
## This is file `xserv.tcl',
## generated with the docstrip utility.
##
## The original source files were:
##
## xserv.dtx  (with options: `tcl')
## 
##
## ===================================================================
## AlphaTcl - core Tcl engine
##                                   created: 2002-11-25 12:23:32
##                               last update: 03/13/2006 {12:16:53 PM}
## Author: Fr\'ed\'eric Boulanger
## E-mail: Frederic.Boulanger@supelec.fr
##   mail: Sup\'elec - Service Informatique
##         Plateau de Moulon, 3 rue Joliot-Curie
##         F-91192 Gif-sur-Yvette cedex
##    www: http://wwwsi.supelec.fr/fb/
##
## Description:
##
##   The xserv package manages the declaration of eXternal SERVices
##   and of implementations of these services with applications.
##
##   See xserv.dtx or its typeset form (xserv.pdf for instance) for the
##   documentation of this package.
##
## History
##
## modified   by  rev reason
## _________________________
##
## 2002-11-25 FBO 1.0 first version, starting from the api 1.1 package
## 2003-01-20 FBO 1.1 changed executeApp to fix issue with Apple Events
## 2003-04-01 FBO 1.2 fixed encoding issue, added end-exec hooks
## 2003-06-16 FBO 1.3 added categories, validation of implementations
## 2003-09-12 FBO 1.4 adapted to new version of InSh (interaction only)
##                    opening/closing of commands through sockets or pipes
## 2003-09-15 FBO 1.5 added internal services, more robust validation
## 2003-11-07 FBO 1.6 -indir key, Vince's GUI for choosing helpers.
## 2004-04-30 FBO 1.7 Improved GUI, implementation settings saved, fixes.
## 2004-12-15 FBO 1.8 No user interaction during startup, small fixes.
## 2005-02-16 FBO 1.9 Fixed validation/resources for bundles.
##                    Prefs are remembered only when OK is pressed.
## 2005-06-02 FBO 2.0 Switch to: invoke xservname [args]
##                    'interaction' is now given by the value of the
##                    '-xservInteraction' key (0 for bg, 1 for fg (default)).
## 2006-03-27 JK  2.0.2 chooseImplementationFor strictified to solve Bug 1994:
##                      accept only implName argument in key-value form.
## ===================================================================

alpha::extension xserv 2.0.2 {
  hook::register quitHook ::xserv::saveToPrefs
  ::xserv::fixExecSearchPath
  # Internal services
  ::xserv::declareInternal catPipe {Open a pipe through the 'cat' program}
  ::xserv::register catPipe catPipe -mode Alpha -driver {
    return [open "|$params(xserv-cat)" RDWR]
  } -progs {cat}
  # preferences
  ::xserv::readPrefs
} maintainer {
  "Fr\u00e9d\u00e9ric Boulanger" \
  <Frederic.Boulanger@supelec.fr> \
  <http://wwwsi.supelec.fr/fb/> \
} description {
    Defines a new AlphaTcl interface to services that are provided by
    external applications
} help {
    This package defines a new interface to services provided by external
    applications.  It allows the definition of interfaces for external
    services, and the declaration of implementations of these services with
    other applications.  For more information about how Xserv works, see the
    "Xserv Help" file.

    AlphaTcl developers might also be interested in the "Xserv API" .pdf file,
    use the "AlphaDev > AlphaDev Help Files > Xserv API" menu item to open
    it using your local .pdf viewer.  This file constitutes the literate
    programming source for the "xserv.tcl" extension of AlphaTcl.
}

proc xserv.tcl {} {}

namespace eval ::xserv {}

## Platform specific settings:
##  xserv::devnull is the name of the null device;
##  xserv::executableExtensions is the list of the possible extensions for 
##  an executable file;
##  xserv::dirsep is the dircetory separator in directory lists
##
if {$tcl_platform(platform) eq "windows"} {
  set ::xserv::devnull nul
  set ::xserv::executableExtensions [list "" ".exe" ".bat"]
  set ::xserv::dirsep ";"
} elseif {$tcl_platform(platform) eq "unix"} {
  set ::xserv::devnull /dev/null
  set ::xserv::executableExtensions [list ""]
  set ::xserv::dirsep ":"
} else {
  set ::xserv::devnull ""
  set ::xserv::executableExtensions [list ""]
  set ::xserv::dirsep ";"
}

## Fix the search path for executable files: add the directories in 
## execSearchPath (set in "Package Preferences -> Miscellaneous Packages") 
## as well as $HOME/Tools/
proc ::xserv::fixExecSearchPath {} {
  global execSearchPath env HOME
  if {[info exists execSearchPath]} {
    set path [split $env(PATH) $::xserv::dirsep]
    foreach p $execSearchPath {
      if {[lsearch -exact $path $p] < 0} {
	lappend path $p
      }
    }
    lappend path [file join $HOME Tools]
    set env(PATH) [join $path $::xserv::dirsep]
  }
}

## Add services to a category. Create the category if it does not exist 
## yet. A service may belong to several categories. Categories are used to
## help the user find a service.
## 
## addtoCategory category services+
## 
proc ::xserv::addToCategory {cat args} {
  global ::xserv::categories

  if {![info exists ::xserv::categories($cat)]} {
    set ::xserv::categories($cat) [list]
  }
  foreach x $args {
    if {[lsearch -exact [set ::xserv::categories($cat)] $x] == -1} {
      lappend ::xserv::categories($cat) $x
    }
  }
}

## Remove services from a category
## 
## removeFromCategory category services+
## 
proc ::xserv::removeFromCategory {cat args} {
  global ::xserv::categories

  if {[info exists ::xserv::categories($cat)]} {
    foreach x $args {
      set idx [lsearch -exact [set ::xserv::categories($cat)] $x]
      if {$idx != -1} {
	set ::xserv::categories($cat) [\
	 lreplace [set ::xserv::categories($cat)] $idx $idx\
	]
      }
    }
  }
}

proc ::xserv::getCategoriesOf {xservname} {
  global ::xserv::categories

  set result [list]
  if {![info exists ::xserv::categories]} {
    return $result
  }
  foreach cat [array names ::xserv::categories] {
    if {[lsearch -exact [set ::xserv::categories($cat)] $xservname] != -1} {
      lappend result $cat
    }
  }
  return $result
}

## Check that no parameter of a service use a reserved name.
## Reserved names are those that start with 'xserv'.
## 
## checkArgNames service parameter_name+
## 
proc ::xserv::checkArgNames {xservname arglist} {
  foreach arg $arglist {
    set argname [lindex $arg 0]
    if {[string match $argname "xserv*"] == 1} {
      error "In declaration of $xservname: \'$argname\' is a reserved parameter name."
    }
  }
}

## Declare a service:
##   xservname is the name of the service
##   desc is a textual description of the service to be shown to the user
##   args is a parameter list in the same form as for the 'proc' command
##   
## A service that is already declared cannot be declared again (that may 
## invalidate registered implementations of the service if the interface 
## changes), it must be forgotten first (see xserv::forget).
proc ::xserv::declare {xservname desc args} {
  global ::xserv::services

  if {[info exists ::xserv::services($xservname)]} {
    set errmsg "Service $xservname is already declared."
    append errmsg " You must use 'xserv::forget' before declaring it anew."
    ## Don't make it an error, but we should check that the new declaration
    ## is identical to what we already have for this service.
    #error $errmsg
    #status::msg $errmsg
  }
  xserv::checkArgNames $xservname $args
  
  set ::xserv::services($xservname) [list desc $desc args $args]
}

## Declare a bundle. A bundle is a set of services that are always 
## provided by a same implementation. For instance, all the services
## provided by TeXtures (an implementation of TeX on the Macintosh) are
## always provided by the same application: it makes no sense to use a 
## copy of TeXture to typeset a TeX file and another copy to synchronize 
## it.
## 
## declareBundle name_of_bundle description service+
## 
proc ::xserv::declareBundle {bundleName desc args} {
  global ::xserv::services

  if {[info exists ::xserv::services($bundleName)]} {
    array set serv [set ::xserv::services($bundleName)]
    if {![info exists serv(bundle)]} {
      error "Declaration of bundle $bundleName overrides a service"
    }
  }
  xserv::checkArgNames $bundleName $args

  set ::xserv::services($bundleName) [list desc $desc bundle $args]
}

## Declare an internal service. Internal services are services that the 
## use should not see.
## 
## declareInternal service_name description argument*
proc ::xserv::declareInternal {internalName desc args} {
  global ::xserv::services

  if {[info exists ::xserv::services($internalName)]} {
    array set serv [set ::xserv::services($internalName)]
    if {![info exists serv(internal)]} {
      set errmsg "Declaration of internal service $internalName"
      append errmsg " overrides a public service."
      error $errmsg
    }
  }
  xserv::checkArgNames $internalName $args

  set ::xserv::services($internalName) [list desc $desc internal 1 args $args]
}

## Forget a service and all its implementations
proc ::xserv::forget {xservname} {
  global ::xserv::services
  global ::xserv::currentImplementations

  # Forget the XSERV declaration
  if {[info exists ::xserv::services($xservname)]} {
    unset ::xserv::services($xservname)
  }
  # Forget the current choices for the XSERV
  if {[info exists ::xserv::currentImplementations($xservname)]} {
    unset ::xserv::currentImplementations($xservname)
  }
}

## Save all declarations of service to a file.
## This writes the Tcl code that must be sourced to declare the services.
proc ::xserv::saveXservDeclarations {file_handle} {
  global ::xserv::services

  foreach xserv [::xserv::listOfServices "all"] {
    unset -nocomplain theXserv
    array set theXserv [set ::xserv::services($xserv)]
    if {[info exists theXserv(bundle)]} {
      set decl [list "::xserv::declareBundle" $xserv]
      lappend decl $theXserv(desc)
      eval lappend decl $theXserv(bundle)
    } elseif {[info exists theXserv(internal)]} {
      set decl [list "::xserv::declareInternal" $xserv]
      lappend decl $theXserv(desc)
      eval lappend decl $theXserv(args)
    } else {
      set decl [list "::xserv::declare" $xserv]
      lappend decl $theXserv(desc)
      eval lappend decl $theXserv(args)
    }
    puts $file_handle $decl
  }
}

## Save all categories of services to a file.
## This writes the Tcl code that must be sourced to declare the categories.
proc ::xserv::saveXservCategories {file_handle} {
  global ::xserv::categories

  if {[info exists ::xserv::categories]} {
    foreach cat [array names ::xserv::categories] {
      foreach x [set ::xserv::categories($cat)] {
	puts $file_handle "::xserv::addToCategory $cat $x"
      }
    }
  }
}

## Save all registered implementation of all known services to a file.
## This write the Tcl code that must be sourced to register the 
## implementations of the services.
proc ::xserv::saveXservImplementations {file_handle} {
  global ::xserv::services

  foreach xserv [::xserv::listOfServices "nobundle"] {
    unset -nocomplain theXserv
    array set theXserv [set ::xserv::services($xserv)]
    if {[info exists theXserv(implementations)]} {
      unset -nocomplain theImpls
      array set theImpls $theXserv(implementations)
      foreach impl [array names theImpls] {
	set decl [list "::xserv::register" $xserv $impl]
	append decl " $theImpls($impl)"
	puts $file_handle $decl
      }
    }
  }
}

## Save the current choice of implementtaion for all services.
## This writes the Tcl code that must be sourced to choose the current 
## implementation of each service.
proc ::xserv::saveXservSettings {file_handle} {
  global ::xserv::currentImplementations

  # Don't get bundles since individual settings for each of
  # their members will be saved.
  foreach xserv [::xserv::listOfServices "nobundle"] {
    if {[info exists ::xserv::currentImplementations($xserv)]} {
      unset -nocomplain current
      array set current [set ::xserv::currentImplementations($xserv)]
      foreach group [array names current] {
	set choice [list "::xserv::chooseImplementationFor" $xserv]
	lappend choice $current($group)
	lappend choice $group
	puts $file_handle $choice
      }
    }
  }
}

## Save service declarations, categories of services, implementation 
## registrations and implementation choices to a file.
## What is written is the Tcl code that must be sourced to restore the 
## current settings.
proc ::xserv::saveAll {file_handle} {
  puts $file_handle "# Service declarations"
  ::xserv::saveXservDeclarations $file_handle
  puts $file_handle ""
  puts $file_handle "# Service categories"
  ::xserv::saveXservCategories $file_handle
  puts $file_handle ""
  puts $file_handle "# Service implementations"
  ::xserv::saveXservImplementations $file_handle
  puts $file_handle ""
  puts $file_handle "# Xserv settings"
  ::xserv::saveXservSettings $file_handle
}

## Save the settings of xserv into the xservdefs.tcl file inside the 
## preference folder. The previous version is kept as xservdefs.bak.
proc ::xserv::saveToPrefs {} {
  global PREFS

  if {[file exists [file join $PREFS xservdefs.tcl]]} {
    file rename -force [file join $PREFS xservdefs.tcl] \
		       [file join $PREFS xservdefs.bak]
  }

  set err [catch {alphaOpen "[file join $PREFS xservdefs.tcl]" "w"} pref_file]
  if {$err != 0} {
    alertnote "Could not save your helper application settings! ($err)"
    return
  }

  ::xserv::saveAll $pref_file
  close $pref_file
}

## Read the file xservdefs.tcl in the preference folder if it exists.
proc ::xserv::readPrefs {} {
  global PREFS ::xserv::loadingPrefs

  set ::xserv::loadingPrefs 1
  catch {
    if {[file exists "[file join $PREFS xservdefs.tcl]"]} {
      source "[file join $PREFS xservdefs.tcl]"
    }
  }
  set ::xserv::loadingPrefs 0
}

## Return the list of all declared services
##   'which' controls which services as returned. The default is "bundle".
##   bundle: show bundles, but not the individual services that belong 
##           to a bundle. Don't show internal services.
##   nobundle: don't show bundles. Services that belong to a bundle are 
##           shown as if they weren't part of a bundle. Show internal 
##           services.
##   all: show all services. Bundles, as well as they components, are 
##           shown. Internal services are shown.
##   
proc ::xserv::listOfServices { {which "bundles"} } {
  global ::xserv::services
  set servs [lsort -dictionary [array names ::xserv::services]]
  if {$which == "all"} {
    return $servs
  } elseif {$which == "bundles"} {
    foreach serv [array names ::xserv::services] {
      unset -nocomplain s
      array set s [set ::xserv::services($serv)]
      if {[info exists s(bundle)]} {
	foreach sub $s(bundle) {
	  set idx [lsearch -exact $servs $sub]
	  if {$idx != -1} {
	    set servs [lreplace $servs $idx $idx]
	  }
	}
      }
      if {[info exists s(internal)]} {
	set idx [lsearch -exact $servs $serv]
	if {$idx != -1} {
	  set servs [lreplace $servs $idx $idx]
	}
      }
    }
    return $servs
  } elseif {$which == "nobundle"} {
    foreach serv [array names ::xserv::services] {
      unset -nocomplain s
      array set s [set ::xserv::services($serv)]
      if {[info exists s(bundle)]} {
	set idx [lsearch -exact $servs $serv]
	if {$idx != -1} {
	  set servs [lreplace $servs $idx $idx]
	}
      }
    }
    return $servs
  } else {
    error "Unknown value $which for argument of ::xserv::listOfServices"
  }
}

## Describe a service by returning a key-value list that gives information 
## about the service. Keys may be:
##   implementations: list of registered implementation for that service
##   args:            argument list of the service
##   desc             textual description of the service
proc ::xserv::describe {xservname} {
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    return [list]
  }

  return [set ::xserv::services($xservname)]
}

## Return the name of the bundle to which a service belongs, or the empty 
## string if the service does not belong to a bundle.
proc ::xserv::getBundleName {xservname} {
  global ::xserv::services

  foreach s [array names ::xserv::services] {
    unset -nocomplain serv
    array set serv [set ::xserv::services($s)]
    if {![info exists serv(bundle)]} {
      continue
    }
    if {[lsearch -exact $serv(bundle) $xservname] != -1} {
      return $s
    }
  }
  return ""
}

## Tells whether a service is a bundle
proc ::xserv::isBundle {xservname} {
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  array set serv [set ::xserv::services($xservname)]
  return [info exists serv(bundle)]
}

## Return the list of all implementations of a service.
proc ::xserv::getImplementationsOf {xservname} {
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  array set theXserv [set ::xserv::services($xservname)]
  if {[info exists theXserv(bundle)]} {
    foreach serv $theXserv(bundle) {
      set impls($serv) [::xserv::getImplementationsOf $serv]
    }
    set first [lindex [array names impls] 0]
    set servs [lrange [array names impls] 1 end]
    set implementations [list]
    foreach imp $impls($first) {
      set common 1
      foreach serv $servs {
	if {[lsearch -exact $impls($serv) $imp] == -1} {
	  set common 0
	  break
	}
      }
      if {$common} {
	lappend implementations $imp
      }
    }
    return [lsort -dictionary $implementations]
  }

  if {[info exists theXserv(implementations)]} {
    array set implementations $theXserv(implementations)
    foreach i [array names implementations] {
      array set desc $implementations($i)
      if {![info exists desc(-mode)]} {
	alertnote "No mode for implementation $i"
	continue
      }
      if {![::xserv::modeIsCompatible $desc(-mode)]} {
	unset implementations($i)
      }
      unset desc
    }
  } else {
    array set implementations [list]
  }
  return [lsort -dictionary [array names implementations]]
}

## Tell whether an execution mode is compatible with the current platform.
proc ::xserv::modeIsCompatible {mode} {
  global alpha::macos tcl_platform
  switch -- $mode {
    "App" {
      # Applications, with Apple Events for communication
      return [expr {$alpha::macos != 0}]
    }
    "Dde" {
      # Some Windows specific stuff added by Vince
      return [expr {$tcl_platform(platform) eq "windows"}]
    }
    "Shell" - "InSh" - "Exec" {
      # Execution in a shell, through a pipe in an interactive window, as 
      # an external program with "exec": works on Unix and Windows (so 
      # anywhere but in Classic MacOS).
      # Not yet sure if InSh mode is compatible with Windows...
      return [expr {$tcl_platform(platform) ne "macintosh"}]
    }
    "Alpha" {
      # Service provided by Alpha itself: should always be available.
      return 1
    }
    default {
      # Defensive programming: impossible cases happen...
      return -code error "Unknown mode \"$mode\""
    }
  }
}

## Give the current implementations of a service. The result is a 
## key-value list, the key being the group and the value the implementation 
## of the service for this group. Since groups are not widely used, the 
## result often contains only the empty group and the current 
## implementation that is used for the service. The value associated to 
## the '-name' key of the implementation gives the name of the 
## implementation.
proc ::xserv::getCurrentImplementationsFor {xservname} {
  global ::xserv::services
  global ::xserv::currentImplementations

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  if {[info exists ::xserv::currentImplementations($xservname)]} {
    return [set ::xserv::currentImplementations($xservname)]
  } else {
    return [list]
  }
}

## Give the current implementation of a service for a given group.
## The value associated to the '-name' key of the implementation gives the
## name of the implementation. An empty list is returned if no 
## implementation has been chosen for this service by this group.
proc ::xserv::getCurrentImplementationFor {xservname group} {
  array set impls [::xserv::getCurrentImplementationsFor $xservname]
  if {[info exists impls($group)]} {
    return $impls($group)
  } else {
    return ""
  }
}

## Give the name of the current implementation of a service used 
## by a group.
proc ::xserv::getCurrentImplementationNameFor {xservname group} {
  array set impls [::xserv::getCurrentImplementationsFor $xservname]
  if {[info exists impls($group)]} {
    return [dict get $impls($group) -name]
  } else {
    return ""
  }
}

## Quate a string so that it can be considered as one string by a shell.
## Spaces, backslashes and single quotes must be escaped.
proc ::xserv::quoteForShell {string} {
  string map [list " " "\\ " "\\" "\\\\" "'" "\\'"] $string
}

## Quate a string so that it can be considered as one string when sent 
## to a program through a pipe.
## Spaces and backslashes must be escaped.
proc ::xserv::quoteForPipe {string} {
  string map [list " " "\\ " "\\" "\\\\"] $string
}

## Register an implementation of a service.
##   xservname is the name of the service
##   implName is the name of the implementation
##   args is a list of keys and values that define the implementation. 
##   Known key/value pairs are:
##     -mode mode    gives the mode used to provide the service. Modes are:
##                     App: the service is provided by a MacOS 
##                          application, communication uses Apple Events.
##                     Alpha: the service is provided by Alpha itself.
##                     Exec: the service is provided by an external 
##                           program that is executed with the 'exec' 
##                           command.
##                     Shell: the service is provided by an external 
##                           program that is executed by a shell.
##                     InSh: the service is provided by an external 
##                           program that is executed in an interactive 
##                           window.
##                     Dde: the service is provided by a dde (???)
##                     
##     -sig XYZT     gives the MacOS creator code (XYZT here) of the 
##                   application used to provide the service
##                   
##     -driver {Tcl code}
##                   gives the Tcl code that must be executed to provide 
##                   the service (App or Alpha modes) or to generate the
##                   command line that will be executed to provide the 
##                   service (Shell, Exec and InSh modes).
##                  
##     -indir {Tcl code}
##                   gives the Tcl code that must be executed to get the 
##                   path of the directory that shold be made current while 
##                   providing the service.
##     
##     -progs {list of programs}
##                   gives the list of programs that are required by this 
##                   implementation of the service. The full path to each 
##                   of these programs is available to the driver code 
##                   under the 'xserv-prog_name' entry of the 'params' 
##                   array, where prog_name is the name of the required 
##                   program.
##                   
##     -shell shell_name
##                   gives the name of the shell that should be used when 
##                   the "Shell" mode is used.
##                   
##     -ioMode mode  gives the interaction mode with the shell. It is 
##                   composed of several characters:
##        'i' means that we can send data to the program input stream
##        'o' means that we can read data from the program output stream
##        'e' means that we can read data from the program error stream
##        'c' redirects outputs streams through the 'cat' program. This
##            allows to get the error stream from certain programs.
##         Other characters are ignored.
##         
##      -ipc ipcmec  gives the mecanism used for inter process 
##                   communication: "Pipe" makes Alpha communicate with 
##                   the external program through a pipe, and "SocketPair" 
##                   makes Alpha communicate with the external program 
##                   through a pair of socket. The default is to use a 
##                   pipe.
##                   
proc ::xserv::register {xservname implName args} {
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }

  array set theXserv [set ::xserv::services($xservname)]
  if {[info exists theXserv(bundle)]} {
    error "Attempt to register an implementation for bundle $xservname"
  }
  if {[info exists theXserv(implementations)]} {
    array set theImpls $theXserv(implementations)
  } else {
    array set theImpls [list]
  }

  if {[info exists theXserv(internal)] && [array size theImpls] > 0} {
    if {[lindex [array names theImpls] 0] != $implName} {
      error "Attempt to register more than one implementation for \
	     an internal service"
    }
  }

  # Remember the description of the implementation.
  if {[llength $args] % 2 != 0} {
    error {description must be "[key value]*"}
  }
  array set impDesc $args
  if {[llength [array names impDesc]] != [llength [array names impDesc -*]]} {
    error {Vince said that keys must have a leading '-'}
  }

  if {![info exists impDesc(-mode)]} {
    if {[info exists impDesc(-sig)]} {
      set impDesc(-mode) App
    } elseif {[info exists impDesc(-dde)]} {
      set impDesc(-mode) Dde
    } elseif {[info exists impDesc(-shell)]} {
      set impDesc(-mode) Shell
    } else {
      set impDesc(-mode) Exec
    }
  }

  # Ignore services which are not compatible with this platform
  if {![::xserv::modeIsCompatible $impDesc(-mode)]} {return}
  # Ignore services whose requirements are not met
  if {[info exists impDesc(-requirements)]} {
    if {[catch $impDesc(-requirements) err]} {
      return
    }
  }
  
  set theImpls($implName) [array get impDesc]
  set theXserv(implementations) [array get theImpls]
  set ::xserv::services($xservname) [array get theXserv]
}

## Forget an implementation of a service.
proc ::xserv::forgetImplementation {xservname implName} {
  global ::xserv::services
  global ::xserv::currentImplementations

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  array set theXserv [set ::xserv::services($xservname)]
  if {[info exists theXserv(bundle)]} {
    error "Attempt to forget an implementation of bundle $xservname"
  }
  if {![info exists theXserv(implementations)]} {
    array set theImpls [list]
  } else {
    array set theImpls $theXserv(implementations)
  }
  if {![info exists theImpls($implName)]} {
    error "Unknown implementation \"$implName\" for service \"$xservname\""
  }
  unset theImpls($implName)
  set theXserv(implementations) [array get theImpls]
  set ::xserv::services($xservname) [array get theXserv]

  if {![info exists ::xserv::currentImplementations($xservname)]} {
    return
  }
  array set current [set ::xserv::currentImplementations($xservname)]
  foreach group [array names current] {
    unset -nocomplain imp
    array set imp $current($group)
    if {"$imp(-name)" == "$implName"} {
      unset current($group)
    }
  }
  set ::xserv::currentImplementations($xservname) [array get current]
}

# Choose an implementation of a service for a group. A group is just a 
# name that is attached to the choice of a particular implementation of a 
# service. Different groups may use different implementations of the same 
# service. The default group has the empty string for name.
# The implNameDict argument must be given in long form, like 
# [list -name NAME].
proc ::xserv::chooseImplementationFor {xservname implNameDict {group ""}} {
  global ::xserv::services ::xserv::currentImplementations
  
  # Use this for standard prefs mechanism, not xservdefs.tcl
  variable storedPrefs
  set storedPrefs($xservname) [list $implNameDict $group]
  prefs::modified storedPrefs($xservname)
  
  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  if {![llength $implNameDict]} {
    set implNameDict [list -name "* None *"]
  } elseif {[llength $implNameDict] % 2 != 0} {
    error {Malformed parameter list. Must be [key value]*}
  }
  set implName [dict get $implNameDict -name]
  if {$implName eq "* Other *"} {
    set implNameDict [::xserv::addGenericImplementation $xservname]
    if {![llength $implNameDict]} {
      return $implNameDict
    }
    set implName [dict get $implNameDict -name]
  }
  if {[llength [dict keys $implNameDict]] != [llength [dict keys $implNameDict]]} {
    error "Keys must have a leading '-' (have [join [dict keys $implNameDict] {, }])"
  }

  array set theXserv [set ::xserv::services($xservname)]
  if {[info exists theXserv(bundle)]} {
    if {($implName eq "") || ($implName eq "* None *")} {
      set ::xserv::currentImplementations($xservname) [list]
    } else {
      set ::xserv::currentImplementations($xservname) \
       [list {} [list -name $implName]]
    }
    return [::xserv::chooseImplementationForBundle \
     $xservname [list -name $implName] $group]
  }
  
  if {$implName == "* None *"} {
    set implNameDict [list]
  } else {
    if {[info exists theXserv(implementations)]} {
      array set theImpls $theXserv(implementations)
    } else {
      array set theImpls [list]
    }
    
    if {![info exists theImpls($implName)]} {
      error "No implementation named $implName for service \"$xservname\""
    }
    
    array set chosenImpl $theImpls($implName)
    set chosenMode $chosenImpl(-mode)
    
    set validated [::xserv::validateImpChoice $chosenMode \
     $implNameDict $theImpls($implName)]
    if {[llength $validated] == 0} {
      return $validated
    } else {
      set implNameDict $validated
    }
  }
  
  hook::callAll ::xserv::implChangeHook "" $xservname $group $implNameDict
  hook::callAll ::xserv::implChangeFor${xservname}Hook "" $xservname $group $implNameDict
  
  if {[info exists ::xserv::currentImplementations($xservname)]} {
    array set current [set ::xserv::currentImplementations($xservname)]
  } else {
    array set current [list]
  }
  if {[llength $implNameDict] > 0} {
    set current($group) $implNameDict
  } else {
    unset -nocomplain current($group)
  }
  
  set ::xserv::currentImplementations($xservname) [array get current]
  return $implNameDict
}

## Choose an implementation of a bundle for a group. When an 
## implementation is chosen for a bundle, an implementation with the same 
## name is chosen for each service in the bundle.
proc ::xserv::chooseImplementationForBundle {bundleName implNameDict {group ""}} {
  global ::xserv::services ::xserv::currentImplementations

  if {![info exists ::xserv::services($bundleName)]} {
    error "Undeclared bundle \"$bundleName\""
  }
  array set theXserv [set ::xserv::services($bundleName)]
  if {![info exists theXserv(bundle)]} {
    error "$bundleName is not a bundle"
  }
  foreach serv $theXserv(bundle) {
    set chosen [::xserv::chooseImplementationFor $serv $implNameDict $group]
  }
  if {[info exists ::xserv::currentImplementations($bundleName)]} {
    array set current [set ::xserv::currentImplementations($bundleName)]
  } else {
    array set current [list]
  }
  if {![info exists current($group)]} {
    set current($group) [array get chosen]
  }
  set ::xserv::currentImplementations($bundleName) [array get current]
  return $chosen
}

## Use dialogs to add a generic implementation of a service. Generic
## implementations are implementations for which a driver can be generated
## automatically. A generic implementation can use a MacOS application and 
## the 'odoc' Apple Event, or a comand line program. A generic 
## implementation can be built only for services that take exactly one 
## argument.
proc ::xserv::addGenericImplementation {xservname} {
  global alpha::macos tcl_platform

  set mandatory [::xserv::mandatoryArgsOf $xservname]
  if {[llength $mandatory] != 1} {
    set msg "Cannot build generic implementation for $xservname: "
    append msg "too many arguments."
    error $msg
  }
  set mandatory [lindex $mandatory 0]
  if {$alpha::macos} {
    lappend dstuff {Apple Events} \
     {-path "" -class aevt -event odoc -type "" kind ""}
  }
  if {$tcl_platform(platform) ne "macintosh"} {
    lappend dstuff {Command line} [list \
     -path "" -mode "" -cmd "<prog> \$params($mandatory)" kind ""]
  }

  set page [lindex $dstuff 0]
  while {1} {
    set i 0
    if {$alpha::macos} {
      lappend dial [list [lindex $dstuff $i] [lindex $dstuff [incr i]] \
       {{-path var Application} {-class var {Event class}} \
       {-event var {Event code}} {-type {menu {file text}} "parameter type"} \
       {kind thepage}}]
      incr i
    }
    if {$tcl_platform(platform) ne "macintosh"} {
      lappend dial [list [lindex $dstuff $i] [lindex $dstuff [incr i]] \
       {{-path var Program} {-mode {menu {InSh Shell Exec}} Mode} \
       {-cmd var "Command line"} {kind thepage}}]
    }
    if {[catch {set dstuff [eval \
     [list dialog::make_paged \
       -title "Generic implementation for $xservname" \
       -defaultpage $page] $dial]}]} {
      return [list]
    }
    array set answ $dstuff
    # This just ensures we get the page name.
    foreach ar [array names answ] { array set newImp $answ($ar) }
    set page $newImp(kind)
    if {$page == "Command line"} {
      set imp [::xserv::addGenericCommandLine $xservname $mandatory \
       $answ(Command line)]
    } else {
      set imp [::xserv::addGenericAppleEvents $xservname $mandatory \
       $answ(Apple Events)]
    }
    if {[llength $imp] > 0} {
      return $imp
    }
  }
  return [list]
}

## Return the number of mandatory arguments of a service.
proc ::xserv::mandatoryArgsOf {xservname} {
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  array set theXserv [set ::xserv::services($xservname)]
  set mandatory [list]
  foreach a $theXserv(args) {
    if {[llength $a] == 1} {
      lappend mandatory [lindex $a 0]
    }
  }
  return $mandatory
}

proc ::xserv::addGenericCommandLine {xservname param impl} {
  array set theImpl $impl
  if {$theImpl(-path) == ""} {
    alertnote "You must give a program name or path"
    return [list]
  }
  if {$theImpl(-cmd) == ""} {
    alertnote "You must define the command line"
    return [list]
  }
  set progName [file tail $theImpl(-path)]
  set implName "generic-$progName"
  set decl [list ::xserv::register $xservname $implName -mode $theImpl(-mode)]
  if {[lsearch -exact {InSh Shell} $theImpl(-mode)] != -1} {
    lappend decl -shell sh
  }
  set fixedProg 1
  if {   !([file pathtype $theImpl(-path)] == "absolute") \
      || ![file executable $theImpl(-path)]} {
    lappend decl -progs [list $progName]
    set fixedProg 0
  }
  if {$fixedProg} {
    regsub {<prog>} $theImpl(-cmd) $theImpl(-path) driver
  } else {
    regsub {<prog>} $theImpl(-cmd) "\$params(xserv-$progName)" driver
  }
  lappend decl -driver "return \"$driver\""
  lappend decl -generic [mtime now iso]
  eval $decl
  return [list -name $implName]
}

proc ::xserv::addGenericAppleEvents {xservname param impl} {
  array set theImpl $impl
  if {$theImpl(-path) == ""} {
    alertnote "You must give an application name or signature"
    return [list]
  }
  if {$theImpl(-class) == ""} {
    alertnote "You must define the Apple Event class"
    return [list]
  }
  if {$theImpl(-event) == ""} {
    alertnote "You must define the Apple Event"
    return [list]
  }
  set progName [file tail $theImpl(-path)]
  set implName "generic-$progName"
  set decl [list ::xserv::register $xservname $implName -mode App]
  if {[regexp {^'....'$} $theImpl(-path)]} {
    lappend decl -sig $theImpl(-path)
  } else {
    lappend decl -path $theImpl(-path)
  }
  set driver "tclAE::send -p \$params(xservTarget) "
  append driver "$theImpl(-class) $theImpl(-event) ---- "
  if {$theImpl(-type) == "file"} {
    append driver "\[tclAE::build::alis "
  } else {
    append driver "\[tclAE::build::TEXT "
  }
  append driver "\$params($param)\]"
  lappend decl -driver $driver
  lappend decl -generic [mtime now iso]
  eval $decl
  return [list -name $implName]
}

proc ::xserv::getGenericImplementationsOf {xservname} {
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Unknown service \"$xservname\""
  }
  array set serv [set ::xserv::services($xservname)]
  if {![info exists serv(implementations)]} {
    return [list]
  }
  set gen [list]
  array set impls $serv(implementations)
  foreach imp [array names impls] {
    unset -nocomplain theImp
    array set theImp $impls($imp)
    if {[info exists theImp(-generic)]} {
      lappend gen $imp
    }
  }
  return $gen
}

proc ::xserv::deleteGenerics {} {
  global ::xserv::categories
  set servs [::xserv::listOfServices]
  set noCat [list]
  foreach s $servs {
    if {[llength [::xserv::getGenericImplementationsOf $s]] > 0} {
      if {[lsearch -exact $noCat $s] == -1} {
	lappend noCat $s
      }
    }
  }
  if {[info exists ::xserv::categories]} {
    foreach cat [array names ::xserv::categories] {
      set avails [list]
      foreach serv [set ::xserv::categories($cat)] {
	if {[lsearch -exact $noCat $serv] != -1} {
	  lappend avails $serv
	}
      }
      if {[llength $avails] > 0} {
	set editCats($cat) $avails
      }
    }
    if {[info exists editCats]} {
      foreach cat [array names editCats] {
	foreach serv $editCats($cat) {
	  set idx [lsearch -exact $noCat $serv]
	  if {$idx != -1} {
	    set noCat [lreplace $noCat $idx $idx]
	  }
	}
      }
      if {[llength $noCat] > 0} {
	set editCats(Miscellaneous) $noCat
      }
    }
  }

  if {[info exists editCats]} {
    set theCats [array names editCats]
    while 1 {
      if {[llength $theCats] > 1} {
	set status [catch {set theCat [ \
		      listpick -p "Choose a category of services" \
		      [lsort -dictionary $theCats] \
		   ]}]
	if {$status} {
	  return
	}
      } else {
	set theCat [lindex $theCats 0]
      }
      set status [catch {set theXSERV [ \
		    listpick -p "Choose a service" \
		    [lsort -dictionary $editCats($theCat)] \
		 ]}]
      if {$status} {
	if {[llength $theCats] == 1} {
	  return
	}
      } else {
	break
      }
    }
  } else {
    if {[llength $noCat] == 0} {
      alertnote "There are no generic implementations."
      return
    }
    set status [catch {set theXSERV [ \
		  listpick -p "Choose a service" \
		  [lsort -dictionary $noCat] \
	       ]}]
    if {$status} {
      return
    }
  }
  set generics [::xserv::getGenericImplementationsOf $theXSERV]
  while {[llength $generics] > 0} {
    set status [catch {set theImp [ \
     listpick -p "Choose an implementation to delete" \
     [lsort -dictionary $generics] \
	     ]}]
  if {$status} {
    return
  }
  set question "Delete generic implementation\n"
  append question "  $theImp\n"
  append question "of service\n"
    append question "  $theXSERV ?"
    if {[askyesno $question] == "yes"} {
      ::xserv::forgetImplementation $theXSERV $theImp
      set generics [::xserv::getGenericImplementationsOf $theXSERV]
    }
  }
}

proc deleteGenericImplementation {} {
  ::xserv::deleteGenerics
}

proc ::xserv::validateImpChoiceByName {xservname choice implName} {
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  array set theXserv [set ::xserv::services($xservname)]
  
  if {[info exists theXserv(bundle)]} {
    # It is a bundle, validate the choice for the first service in the bundle
    set valfirst [::xserv::validateImpChoiceByName \
                   [lindex $theXserv(bundle) 0] $choice $implName]
    return $valfirst
  }

  if {![info exists theXserv(implementations)]} {
    array set theImpls [list]
  } else {
    array set theImpls $theXserv(implementations)
  }
  if {![info exists theImpls($implName)]} {
    error "Unknown implementation \"$implName\" for service \"$xservname\""
  }
  array set impl $theImpls($implName)
  return [::xserv::validateImpChoice $impl(-mode) $choice $theImpls($implName)]
}

proc ::xserv::validateImpChoice {mode choice impl} {
  array set theImpl $impl
  if {[info exists theImpl(-progs)] && [llength $theImpl(-progs)] != 0} {
    # If the implementation requests programs, make sure they are available.
    array set theChoice $choice
    set nprogs [llength $theImpl(-progs)]
    if {[info exists theChoice(-progs)]} {
      array set theProgs $theChoice(-progs)
    } else {
      array set theProgs [list]
    }

    set foundProgs [list]
    for {set i 0} {$i < $nprogs} {incr i} {
      set pname [lindex $theImpl(-progs) $i]
      if {[info exists theProgs($pname)]} {
	set found [::xserv::validateProg $theProgs($pname) $pname]
      } else {
	set found [::xserv::validateProg "" $pname]
      }
      if {$found != ""} {
	lappend foundProgs $pname $found
      } else {
	return [list]
      }
    }
    set theChoice(-progs) $foundProgs
    set choice [array get theChoice]
  }
  if {[info exists theImpl(-xservs)] && [llength $theImpl(-xservs)] != 0} {
    # If the implementation requests other services, make sure they are available.
    foreach serv $theImpl(-xservs) {
      if {[llength [::xserv::validateImpl $serv]] == 0} {
	return [list]
      }
    }
  }
  if {[info commands ::xserv::validateImpChoice$mode] != ""} {
    return [::xserv::validateImpChoice$mode $choice $impl]
  } else {
    return $choice
  }
}

proc ::xserv::validateImpChoiceApp {choice impl} {
  global ::xserv::loadingPrefs
  array set theChoice $choice
  if {[info exists theChoice(-path)] && [file exists $theChoice(-path)]} {
    getFileInfo $theChoice(-path) appInfo
    if {$appInfo(type) == "APPL" || $appInfo(type) == ""} {
      return $choice
    }
  }
  array set theImpl $impl
  if {[info exists theImpl(-path)] && [file exists $theImpl(-path)]} {
    getFileInfo $theImpl(-path) appInfo
    if {$appInfo(type) == "APPL" || $appInfo(type) == ""} {
      set theChoice(-path) $theImpl(-path)
      return [array get theChoice]
    }
  }
  if {[info exists theImpl(-sig)]} {
    if {![catch {set app [nameFromAppl $theImpl(-sig)]}]} {
      set theChoice(-path) $app
      return [array get theChoice]
    }
  }
  # Don't ask the user to choose anything during startup
  if {$::xserv::loadingPrefs} {
    return [list]
  }
  
  set prompt "Locate application"
  if {[info exists theImpl(-path)]} {
    set appName [file tail $theImpl(-path)]
    regsub {\.app$} $appName {} appName
    append prompt " $appName"
  }
  if {[info exists theImpl(-sig)]} {
    set appSig $theImpl(-sig)
    append prompt " with type $appSig"
  }
  if {[catch {set appPath [getfile $prompt]}]} {
    return [list]
  } else {
    set theChoice(-path) $appPath
    return [array get theChoice]
  }
}

proc ::xserv::validateImpChoiceShell {choice impl} {
  array set theChoice $choice
  array set theImpl $impl
  if {[info exists theChoice(-shell)]} {
    set curChoice $theChoice(-shell)
  } else {
    set curChoice ""
  }
  set curChoice [::xserv::validateProg $curChoice $theImpl(-shell)]
  if {$curChoice == ""} {
    return [list]
  } else {
    set theChoice(-shell) $curChoice
  }

  return [array get theChoice]
}

proc ::xserv::validateImpChoiceInSh {choice impl} {
  global ::xserv::catProgram

  array set theImpl $impl
  if {[info exists theImpl(-ipc)]} {
    set ipc $theImpl(-ipc)
  } else {
    # Default is to use a pipe with open "|cmd"
    set ipc "Pipe"
  }
  if {[info exists theImpl(-ioMode)]} {
    set iomode $theImpl(-ioMode)
  } else {
    # Default is to access stdin and stdout/stderr piped through cat
    set iomode "ioc"
  }
  if {($ipc == "Pipe") && ([string first "c" $iomode] >= 0)} {
    # We need cat
    if {[::xserv::validateImpl "catPipe"] == ""} {
      return [list]
    }
  }
  if {[info exists theImpl(-shell)]} {
    return [::xserv::validateImpChoiceShell $choice $impl]
  } else {
    return $choice
  }
}

proc ::xserv::validateImpl {xservname {group ""}} {
  global ::xserv::services
  global ::xserv::currentImplementations

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  array set theXserv [set ::xserv::services($xservname)]

  if {![info exists theXserv(implementations)]} {
    array set theImpls [list]
  } else {
    array set theImpls $theXserv(implementations)
  }

  if {![info exists ::xserv::currentImplementations($xservname)]} {
    array set current [list]
  } else {
    array set current [set ::xserv::currentImplementations($xservname)]
  }

  if {![info exists current($group)]} {
    if {[info exists theXserv(internal)]} {
      if {[array size theImpls] > 0} {
	array set theImpl [\
	 ::xserv::chooseImplementationFor $xservname \
	  [lindex [array names theImpls] 0]\
	]
      } else {
	error "No implementation available for internal service $xservname"
      }
    } else {
      array set theImpl [::xserv::selectImplementationFor $xservname $group]
    }

    if {[array size theImpl] == 0} {
      return [list]
    }
  } else {
    array set theImpl "$current($group)"
  }

  # For now, we don't know how to handle an implementation choice without
  # a name in it.
  if {![info exists theImpl(-name)]} {
    error "No implementation name in [array get theImpl]"
  }

  if {![info exists theImpls($theImpl(-name))]} {
    set msg "Implementation \"$theImpl(-name)\" "
    append msg "does not support service \"$xservname\""
    error $msg
  }

  array set imp $theImpls($theImpl(-name))
  if {[info exists imp(-mode)]} {
    set validated [::xserv::validateImpChoice $imp(-mode) \
     [array get theImpl] $theImpls($theImpl(-name))]
    if {[llength $validated] == 0} {
      return [list]
    } else {
      ::xserv::chooseImplementationFor $xservname $validated $group
      array set imp $validated
      return [array get imp]
    }
  } else {
    error "No invocation mode for $theImpl(-name)."
  }
}

proc ::xserv::validateProg {prog name} {
  global env ::xserv::loadingPrefs

  if {$prog != "" && [file executable $prog]} {
    return $prog
  }
  set candidates [::xserv::findProgs $name [split $env(PATH) $::xserv::dirsep]]
  if {[llength $candidates] == 0} {
    if {$::xserv::loadingPrefs \
        || [catch {set prog [getfile "Locate program $name"]}]} {
      return ""
    } else {
      return $prog
    }
  } elseif {[llength $candidates] == 1} {
    return [lindex $candidates 0]
  } else {
    if {$::xserv::loadingPrefs \
        || [catch {set prog [ \
             listpick -p "Choose a program for $name" \
             $candidates \
           ]}]} {
      return ""
    } else {
      return $prog
    }
  }
}

proc ::xserv::selectImplementationFor {xservname {group ""}} {
  global ::xserv::currentImplementations
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }

  set bundle [::xserv::getBundleName $xservname]
  if {$bundle != ""} {
    set xservname $bundle
  }

  array set defaultImpl [list]
  if {[info exists ::xserv::currentImplementations($xservname)]} {
    array set current [set ::xserv::currentImplementations($xservname)]
    if {[info exists current($group)]} {
      array set defaultImpl $current($group)
    } elseif {[info exists current("")]} {
      array set defaultImpl $current("")
    }
  }

  set implList [::xserv::getImplementationsOf $xservname]

  if {![::xserv::isBundle $xservname]} {
    set mandatory [::xserv::mandatoryArgsOf $xservname]
    if {[llength $mandatory] == 1} {
      set other 1
    }
  }
  if {![info exists other] && ![llength $implList]} {
    # We don't have any services at all!
    alertnote "No services are available, nor can any be defined!"
    return
  }

  if {[info exists defaultImpl(-name)]} {
    set curpage $defaultImpl(-name)
  } else {
    set curpage ""
  }

  set generics [::xserv::getGenericImplementationsOf $xservname]

  foreach impl $implList {
    set keyvals {}
    set items {}
    # Need to fill in code here to add appropriate dialog controls
    # to this dialog page which are useful for setting '$impl'.
    set this [::xserv::getDialogItemsOf $xservname $impl]
    set keyvals [lindex $this 0]
    set items [lindex $this 1]
    # to do.
    set pages($impl) [list $keyvals $items]
  }

  if {![llength $implList]} {
    set "pages((No services defined))" \
     [list {} {}]
  }

  set buttons [list Help "Click here for help about setting external services." \
   {::package::helpWindow   "xserv"}]
  if {[info exists other]} {
    lappend buttons "New HelperÉ" "Create your own generic implementation" \
     "[list ::xserv::chooseImplementationFor $xservname [list -name "* Other *"] $group];set retCode 1"
  }

#     if {[llength $generics]} {
#       lappend buttons Delete "Permanently delete this generic service" \
#        [list ::xserv::deleteGenericButton $xservname $current_page]
#     }
  # $curentpage must be evaluated when the button is clicked, not now.
  # I didn't find a way to add "$currentpage" to a list without either
  # evaluating it immediatly or makeing it non evaluable ({$curentpage}).
  # retCode is set to 1 when the implementation is deleted because the
  # dialog must be rebuilt in this case.
  if {[llength $generics]} {
    lappend buttons Delete "Permanently delete this generic service" \
     "if \{\[::xserv::deleteGenericButton $xservname \$currentpage\]\} \{set retCode 1\}"
  }

  if {[llength $implList]} {
    set pages((None)) [list {} {}]
    set pages(-)      [list {} {}]
  }

  while {1} {
    set dial {}
    set first 1
    set pageOrder [lsort -dictionary -unique [array names pages]]
    foreach pageName [list "-" "(None)"] {
      if {([set idx [lsearch $pageOrder $pageName]] > -1)} {
        set pageOrder [lreplace $pageOrder $idx $idx]
	set pageOrder [linsert $pageOrder 0 $pageName]
      }
    }
    foreach {page} $pageOrder {
      set contents $pages($page)
      if {[info exists first]} {
        foreach {k i} $contents {break}
        if {![llength $k]} {
          set contents [list [list thepage ""] [list {thepage thepage}]]
        } else {
          set contents [list [linsert $k 0 thepage ""] [linsert $i 0 {thepage thepage}]]
        }
        unset first
      }
      lappend dial [concat [list $page] $contents]
    }
    if {[catch {eval [list dialog::make_paged \
     -title "Choose an implementation for $xservname" \
     -width 450 \
     -addbuttons $buttons -defaultpage $curpage] \
     $dial} res]} {
      # User pressed Cancel or "New Service", all of which have already
      # been handled
      return [::xserv::getCurrentImplementationFor $xservname $group]
    }
    # $res is of the form 'page {key val ...} page {key val ...}'
    set newpage [lindex [lindex $res 1] 1]
    array set results $res
    if {($newpage eq "(None)")} {
      return ""
    } elseif {($newpage eq "-")} {
      return $curpage
    } else {
      set curpage $newpage
    }

    # The implementation selected is the current page
    #set theImpl $curpage
    # Now need to setup this implementation based on the contents of
    # this page, and validate it.
    #array set thispage $results($curpage)
    # remove dummy item if present
    #unset -nocomplain thispage(thepage)

    # Fill in code here to validate the results stored in 'thispage'
    set choice [::xserv::buildImplFromDialog $curpage $results($curpage)]

    #puts stderr "got $curpage with [array get thispage]"
    #puts stderr "--> $choice"
    set choice [::xserv::validateImpChoiceByName $xservname $choice $curpage]
    #puts stderr "valid --> $choice"
    # set ok 1
    if {[llength $choice] > 0} {
      # The implementation was validated and is ok
      break
    }
    # User didn't complete all the information acceptably.  Fill
    # in what they did put and go around the loop again.
    foreach page [array names pages] {
      set pages($page) [lreplace $pages($page) 0 0 $results($page)]
    }
  }
  # Just return the new choice (don't store it anywhere - that must only
  # happen after the user has pressed Ok in the toplevel dialog).

  return $choice
  #[::xserv::chooseImplementationFor $xservname $choice $group]
}

proc ::xserv::buildImplFromDialog {implname items} {
  set impl [list -name $implname]
  set progs [list]
  foreach {key value} $items {
    switch -glob -- $key {
      "thepage" { }
      "application" {
	set path [lindex $value 0]
	if {$path != ""} {
	  lappend impl -path "$path"
	}
      }
      "shell-prog" {
	set path [lindex $value 0]
	if {$path != ""} {
	  lappend impl -shell "$path"
	}
      }
      "*-prog" {
	set path [lindex $value 0]
	if {$path != ""} {
	  regsub -- {(.*)-prog} "$key" {\1} pname
	  lappend progs  "$pname" "$path"
	}
      }
    }
  }
  if {[llength $progs] > 0} {
    lappend impl -progs $progs
  }
  return $impl
}

proc ::xserv::getResources {xservname implname} {
   global ::xserv::services

   if {![info exists ::xserv::services($xservname)]} {
     error "Undeclared service \"$xservname\""
   }
   array set theXserv [set ::xserv::services($xservname)]

   if {[info exists theXserv(bundle)]} {
     # It is a bundle, get the resources for each service in the bundle
     foreach serv $theXserv(bundle) {
       array set rez [::xserv::getResources $serv $implname]
     }
     return [array get rez]
   }
   
   if {![info exists theXserv(implementations)]} {
     array set theImpls [list]
   } else {
     array set theImpls $theXserv(implementations)
   }

   if {![info exists theImpls($implname)]} {
     error "No \"$implname\" implementation of \"$xservname\""
   }

   array set curimps [::xserv::getCurrentImplementationsFor $xservname]
   
   array set impl $theImpls($implname)

   set rezlist [list]

   set rez [list]
   set choices [list]
   if {[info exists impl(-sig)]} {
     lappend rez -type application -signature $impl(-sig)
     if {![catch {nameFromAppl $impl(-sig)} path]} {
       regsub {\.app\/?$} $path {} path
       lappend choices "$path"
     }
   }

   if {[info exists impl(-path)]} {
     set appName [file tail $impl(-path)]
     regsub -- {\.app$} $appName {} appName
     if {[llength $rez] == 0} {
       lappend rez -type application
     }
     lappend rez -name $appName
     if {[file exists $impl(-path)]} {
       lappend choices $impl(-path)
     }
   }
   if {[llength $rez] > 0} {
     foreach group [array names curimps] {
       unset -nocomplain curimp
       array set curimp $curimps($group)
       if {"$curimp(-name)" == "$implname"} {
	 if {    [info exists curimp(-path)] 
	     && ([lsearch -exact $choices "$curimp(-path)"] < 0)} {
	   lappend choices "$curimp(-path)"
	   lappend rez -value "$curimp(-path)"
	 }
       }
     }
   }
   
   if {[llength $choices] > 0} {
     lappend rez -choices $choices
   }
   
   if {[llength $rez] != 0} {
     lappend rezlist application $rez
   }
   
   if {[info exists impl(-progs)]} {
     foreach p $impl(-progs) {
       set rez [list -type program -name $p]
       set choices [list]
       foreach group [array names curimps] {
	 unset -nocomplain curimp
	 array set curimp $curimps($group)
	 if {"$curimp(-name)" == "$implname"} {
	   if {[info exists curimp(-progs)]} {
	     unset -nocomplain progs
	     array set progs $curimp(-progs)
	     if {    [info exists progs($p)]
		 && ([lsearch -exact $choices "$progs($p)"] < 0)} {
	       lappend choices "$progs($p)"
	       lappend rez -value "$progs($p)"
	     }
	   }
	 }
       }
       set which [::xserv::findProgs [file tail $p]]
       if {[llength $which] > 0} {
	 eval lappend choices $which
       }
       if {[llength $choices] > 0} {
	 lappend rez -choices $choices
       }
       lappend rezlist "$p-prog" $rez
     }
   }

   if {[info exists impl(-shell)]} {
     set rez [list -type shell -name $impl(-shell)]
     set choices [list]
     foreach group [array names curimps] {
       unset -nocomplain curimp
       array set curimp $curimps($group)
       if {"$curimp(-name)" == "$implname"} {
	 if {    [info exists curimp(-shell)]
	     && ([lsearch -exact $choices "$curimp(-shell)"] < 0)} {
	   lappend choices "$curimp(-shell)"
	   lappend rez -value "$curimp(-shell)"
	 }
       }
     }
     set which [::xserv::findProgs [file tail $impl(-shell)]]
     if {[llength $which] > 0} {
       eval lappend choices $which
     }
     if {[llength $choices] > 0} {
       lappend rez -choices $choices
     }
     lappend rezlist "shell-prog" $rez
   }

   if {[info exists impl(-xservs)]} {
     foreach s $impl(-xservs) {
       lappend rezlist $s-serv [list -type xserv -name $s]
     }
   }

   if {[info exists impl(-mode)] && ($impl(-mode) == "InSh")} {
     if {![info exists impl(-ipc)] || ($impl(-ipc) == "Pipe")} {
       if { ![info exists impl(-ioMode)] \
	|| ([string first "c" $impl(-ioMode)] >= 0)} {
	 lappend rezlist catPipe-serv [list -type xserv -name catPipe]
       }
     }
   }

   return $rezlist
}

proc ::xserv::findProgs {name {pathlist ""} {exact 0}} {
  variable executableExtensions
  if {[file pathtype $name] == "absolute"} {
    if {[file executable $name]} {
      return [list $name]
    } elseif {$exact} {
      return [list]
    } else {
      set prog [file tail $name]
    }
  }
  if {$pathlist == ""} {
    set pathlist [split $::env(PATH) $::xserv::dirsep]
  }
  set candidates [list]
  foreach path $pathlist {
    set p [file join $path $name]
    foreach suffix $executableExtensions {
      set q $p$suffix
      if {[file executable $q] && [lsearch -exact $candidates $q] < 0} {
        if {$::alpha::macos != 2 && [file isdir $q]} {
          continue
        }
        lappend candidates $q
      }
    }
  }
  return $candidates
}

# The dialog xhelper type.
namespace eval dialog {}
array set dialog::simple_type {
  xhelper {
    set service [string trimright $name :]
    set R [dialog::makeSetItem res script $left $right y $name\
     [list ::xserv::set_xhelper [list $dial "$page,$name" xhelper] $service \
     "Select helper for $service"]]
    set vv [dialog::specialView::xhelper $val]
    eval lappend res\
     [dialog::makeStaticValue $left $right y $vv {} 0.33 $R]
  }
}

namespace eval dialog::specialView {}
proc ::dialog::specialView::xhelper {val} {
  if {[dict exists $val -name]} {
    return [dict get $val -name]
  } else {
    return "(Undefined)"
  }
}

proc ::xserv::set_xhelper {itemInfo service prompt dialogItemId} {
  set xhelp [::xserv::selectImplementationFor $service]
  dialog::modified $itemInfo $xhelp $dialogItemId
}

###
# "application" item type: for choosing an application or command line program
# The value is a two element list. The first element is the path to the program
# or application. The second element is a list of possible paths for the program
# or application.
###
namespace eval dialog {}
array set ::dialog::simple_type {application {
  set vv [::dialog::specialView::application $val]
  set R [::dialog::makeSetItem res script $left $right y $name\
   [list ::dialog::set_application $dial $page $name "Select $name"]]
  eval lappend res\
   [::dialog::makeStaticValue $left $right y $vv {} 0.33 $R]
}}
# proc dialog::set_application {dial page name prompt {dialogItemId ""}} {
#    global alpha::platform
#    set val [lindex [dialog::valGet $dial $page,$name] 0]
#    if {[catch {getfile $prompt $val} val]} {
#      return ""
#    }
#    set val [list $val [lrange [dialog::valGet $dial $page,$name] 1 end]]
#    dialog::modified [list $dial $page,$name application] $val $dialogItemId
# }

namespace eval dialog::specialView {}

proc ::dialog::specialView::application {val} {
  regsub -- {\.app/?$} [lindex $val 0] {} view
  return $view
}

proc ::dialog::set_application {dial page name prompt {dialogItemId ""}} {
  set val [::dialog::valGet $dial $page,$name]
  set hints [list]
  if {[llength $val] > 1} {
    set hints [lindex $val 1]
  }
  
  set v [lindex $val 0]
  if {"$v" != ""} {
    set thePath "$v"
  } elseif {[llength $hints] > 0} {
    set thePath [lindex $hints 0]
  } else {
    set thePath ""
  }
  
  set data([list Locate manually]) [list -path $thePath -page ""]
  set data([list Give full path]) [list -path $thePath -page ""]

  set ditems([list Locate manually]) [list \
    [list -path file "path:"] \
    [list -page thepage] \
  ]
  set ditems([list Give full path]) [list \
    [list -path var "path:"] \
    [list -page thepage] \
  ]
  set thePage {Locate manually}
  
  if {[llength $hints] > 1} {
    set data([list Choose in list]) [list -path $thePath -page ""]
    set ditems([list Choose in list]) [list \
      [list -path [list menu $hints] "path:"] \
      [list -page thepage] \
    ]
   set thePage {Choose in list}
  }

  foreach pge [array names data] {
    lappend theDial [list $pge $data($pge) $ditems($pge)]
  }

  if {[catch {set datalist [eval \
   [list dialog::make_paged -defaultpage $thePage] $theDial]}]} {
    return [list]
  }
  array set data $datalist
  foreach pge [array names data] {
    array set getThePage $data($pge)
  }
  set thePage $getThePage(-page)
  array set data $data($thePage)
  set idx [lsearch -exact $hints $data(-path)]
  if {$idx < 0} {
    lappend hints $data(-path)
  }
  set val [list $data(-path) $hints]
  dialog::modified [list $dial $page,$name application] $val $dialogItemId
}
###
namespace eval ::xserv {}
proc ::xserv::getDialogItemsOf {xservname serv} {
  set keyv {}
  set itemlist {}

  foreach {name keyvals} [::xserv::getResources $xservname $serv] {
    unset -nocomplain kv
    array set kv $keyvals
    switch -- $kv(-type) {
      "program" {
	set val [list]
	if {[info exists kv(-value)]} {
	  lappend val $kv(-value)
	} else {
	  lappend val [list]
	}
	if {[info exists kv(-choices)]} {
	  lappend val $kv(-choices)
	} else {
	  lappend val [list]
	}
	
	lappend keyv $name $val
	lappend itemlist [list $name application "$kv(-name) path:" \
	 "Click here to select a program."]
      }
      "shell" {
	set val [list]
	if {[info exists kv(-value)]} {
	  lappend val $kv(-value)
	} else {
	  lappend val [list]
	}
	if {[info exists kv(-choices)]} {
	  lappend val $kv(-choices)
	} else {
	  lappend val [list]
	}
	lappend keyv $name $val
	lappend itemlist [list $name application "$kv(-name) path:" \
	 "Click here to select a shell application."]
      }
      "application" {
      # No. The 'value' of an application is definitely not its signature
      # since this does not allow to differentiate several applications with
      # the same signature. The name or creator code is just a hint.
      # lappend keyv $name '$kv(-signature)'
      # lappend itemlist [list $name appspec "$name sig:" "help"]
	set val [list]
	if {[info exists kv(-value)]} {
	  lappend val $kv(-value)
	} else {
	  lappend val [list]
	}
	if {[info exists kv(-choices)]} {
	  lappend val $kv(-choices)
	} else {
	  lappend val [list]
	}
	
	lappend keyv $name $val
	set lbl "application"
	if {[info exists kv(-name)]} {
	  append lbl " \"$kv(-name)\""
	}
	if {[info exists kv(-signature)]} {
	  append lbl " with sig \'$kv(-signature)\'"
	}
	lappend itemlist [list $name application "$lbl:" \
	 "Click here to select an application."]
      }
      "xserv" {
	# ignore recursion for the moment.
      }
    }
  }
  return [list $keyv $itemlist]
}

proc ::xserv::deleteGenericButton {xservname serv} {
  set generics [::xserv::getGenericImplementationsOf $xservname]
  if {[llength $generics] == 0} {
    alertnote "All generic implementations have already been deleted"
    return 0
  }
  
  if {[lsearch -exact $generics $serv] == -1} {
    # Hopefully in the future we will enable/disable the button
    # so this code path is never reached.
    alertnote "Sorry, you can't delete built-in service \"$serv\""
    return 0
  } else {
    ::xserv::forgetImplementation $xservname $serv
    return 1
  }
}

## New syntax xserv::invoke xservname args
## 2005-06-02
proc ::xserv::invoke {xservname args} {
  set invocation [list ::xserv::invokeForGroup {} $xservname]
  eval [concat $invocation $args]
}

proc ::xserv::invokeForGroup {group xservname args} {
  global ::xserv::services
  global ::xserv::currentImplementations
  global ::xserv::endExecHooks
  
  array set imp [::xserv::validateImpl $xservname]
  if {[array size imp] == 0} {
    error "Cancelled -- Could not invoke service '$xservname'"
  }
  array set theXserv [set ::xserv::services($xservname)]
  
  set imp(xservName) $xservname
  
  # Get the list of formal parameters from the declaration of the XSERV
  set formalargs $theXserv(args)
  # Add "xservInteraction" to the parameter list since it is now handled this 
  # way by xserv::invoke. Default is to interact (foreground launch for 
  # an application).
  lappend formalargs [list xservInteraction 1]
  
  # Get the effective arguments from the "args" trailing parameters
  if {[llength $args] % 2 != 0} {
    error {Malformed parameter list. Must be [key value]*}
  }
  array set effectiveargs $args
  if {[llength [array names effectiveargs]] \
   != [llength [array names effectiveargs -*]]} {
    error {Keys must have a leading '-'}
  }
  
  # Remove leading '-' in parameter names so that the driver
  # can access them with '$params(<param name>)'
  foreach name [array names effectiveargs] {
    set effectiveargs([string range $name 1 end]) $effectiveargs($name)
    unset effectiveargs($name)
  }
  
  # Check for unknown arguments
  foreach name [array names effectiveargs] {
    if {[lsearch -exact $formalargs $name] < 0} {
      if {[lsearch -regexp $formalargs [list $name *]] < 0} {
        error "Unknown parameter \"$name\" in \"$xservname\"."
      }
    }
  }
  # Add default values for omitted parameters
  foreach arg $formalargs {
    set argname [lindex $arg 0]
    if {![info exists effectiveargs($argname)]} {
      if {[llength $arg] > 1} {
        set effectiveargs($argname) [lindex $arg 1]
      } else {
        error "No value for parameter \"$argname\" in \"$xservname\"."
      }
    }
  }
  
  # If programs are requested, give their full path in the arguments.
  if {[info exists imp(-progs)]} {
    array set theProgs $imp(-progs)
    foreach p [array names theProgs] {
      set effectiveargs(xserv-$p) $theProgs($p)
    }
  }
  
  # 2003-01-15 put the description of the implementation into the
  # parameters under the xservImplementation key.
  set effectiveargs(xservImplementation) [array get imp]
  
  # We use a temporary proc to insulate the driver
  # script from our local variables.
  set procText "\n  upvar params params;"
  append procText $imp(-driver)
  eval proc ::xserv::tmpProc {{}} {$procText}
  
  if {[info commands ::xserv::execute$imp(-mode)] != ""} {
    if {[info exists imp(-indir)]} {
      array set params [array get effectiveargs]
      set exec_dir [eval $imp(-indir)]
      set orig_dir [pwd]
      cd $exec_dir
    }
    
    set status [catch { \
     ::xserv::execute$imp(-mode) \
     [array get imp] \
     [array get effectiveargs]\
    } result]
    if {[info exists imp(-indir)]} {
      cd $orig_dir
    }
    if {$status != 0} {
#       alpha::log stderr $::errorInfo
      error $result
    }
    
    return $result
  } else {
    error "No handler for \"$imp(-mode)\" invocation mode."
  }
}

proc ::xserv::execEndExecHooks {imp effectiveargs result} {
  global ::xserv::endExecHooks

  array set theImpl $imp
  set xservname [set theImpl(xservName)]
  if {  [info exists ::xserv::endExecHooks($xservname)]
    && ([llength [set ::xserv::endExecHooks($xservname)]] > 0)} {
    foreach p [set ::xserv::endExecHooks($xservname)] {
      eval [list $p $imp $effectiveargs $result]
    }
  }
}

proc ::xserv::addEndExecHook {xservname proc} {
  global ::xserv::endExecHooks
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }
  if {![info exists ::xserv::endExecHooks($xservname)]
    || [lsearch -exact "$proc" [set ::xserv::endExecHooks($xservname)]] == -1} {
    lappend ::xserv::endExecHooks($xservname) $proc
  }
}

proc ::xserv::removeEndExecHook {xservname {proc ""}} {
  global ::xserv::endExecHooks
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }

  if {$proc == ""} {
    set ::xserv::endExecHooks($xservname) [list]
  } elseif {[info exists ::xserv::endExecHooks($xservname)]} {
    set idx [lsearch -exact "$proc" [set ::xserv::endExecHooks($xservname)]]
    if {$idx != -1} {
      set ::xserv::endExecHooks($xservname) [\
       lreplace ::xserv::endExecHooks($xservname) $idx $idx\
      ]
    }
  }
}

proc ::xserv::executeDde {implArray paramArray} {
  array set imp $implArray
  array set params $paramArray
  # How to ensure it is running?
  if {[catch {dde services $imp(-dde)}]} {
    #error "No dde service '$imp(-dde)' available"
  }
  set result [::xserv::tmpProc]
  ::xserv::execEndExecHooks $implArray [array get params] $result
  return $result
}

proc ::xserv::executeApp {implArray paramArray} {
  array set imp $implArray
  array set params $paramArray
  set app "$imp(-path)"
  # the target is the short name of the application
  # without the ".app" extension in OS X
  regsub {\.app$} [file tail $app] {} params(xservTarget)
  set cmd [list launch]
  if {$params(xservInteraction)} {
    lappend cmd "-f"
  }
  lappend cmd $app
  if {[catch {eval $cmd}]} {
    error "Could not launch $app"
  }
  set result [::xserv::tmpProc]
  ::xserv::execEndExecHooks $implArray [array get params] $result
  return $result
}

proc ::xserv::executeShell {implArray paramArray} {
  array set imp $implArray
  array set params $paramArray
  set cmd [::xserv::tmpProc]
  set cmdline ""
  foreach word $cmd {
    append cmdline " [::xserv::quoteForShell $word]"
  }
  set endCmd ""
  if {[info exists imp(-endwith)]} {
    set endCmd $imp(-endwith)
  }
  if {$endCmd != ""} {
    append cmdline ";$endCmd"
  }
  if {!$params(xservInteraction)} {
    set result [exec $imp(-shell) << $cmdline &]
  } else {
    set result [exec $imp(-shell) << $cmdline]
  }
  ::xserv::execEndExecHooks $implArray [array get params] $result
  return $result
}

proc ::xserv::executeInSh {implArray paramArray} {
  array set imp $implArray
  array set params $paramArray
  if {!$params(xservInteraction)} {
    # Background invocation for an interactive shell
    # => use a non-interactive shell
    return [::xserv::executeShell $implArray $paramArray]
  }
  set wname "* $imp(xservName) *"
  set ignored ""
  if {[info exists imp(-ignore)]} {
    set ignored $imp(-ignore)
  }
  # The default InSh mode is "ioc": the shell window handles
  # the input, output and error streams. The output and error
  # streams are piped through 'cat' to avoid losing stderr.
  set iomode "ioc"
  if {[info exists imp(-ioMode)]} {
    set iomode $imp(-ioMode)
  }
  if {[info exists imp(-ipc)]} {
    set ipc $imp(-ipc)
  } else {
    set ipc "Pipe"
  }

  set cmd [::xserv::tmpProc]
  set cmdline ""

  set shellmode Text
  if {[info exists params(shellmode)]} {
    set shellmode $params(shellmode)
  }
  if {[info exists imp(-shell)]} {
    foreach word $cmd {
      append cmdline " [::xserv::quoteForShell $word]"
    }
    set shell [::xserv::open$ipc "$imp(-shell) -i" "i$iomode"]
    InSh::createShell $wname \
     $shell [list ::xserv::close$ipc [lindex $shell 1]] $ignored $shellmode
    # Ask for calling the end-exec hooks when the socket is closed.
    InSh::addCloseHook $wname [list ::xserv::execEndExecHooks \
     $implArray $paramArray]
    set endCmd "exit"
    if {[info exists imp(-endwith)]} {
      set endCmd $imp(-endwith)
    }
    if {$endCmd != ""} {
      append cmdline ";$endCmd"
    }
    if {$cmdline != ""} {
      puts [lindex $shell 2] "$cmdline"
    }
    return [lindex $shell 2]
  } else {
    foreach word $cmd {
      append cmdline " [::xserv::quoteForPipe $word]"
    }
    set task [::xserv::open$ipc $cmdline $iomode]
    InSh::createShell $wname \
     $task [list ::xserv::close$ipc [lindex $task 1]] $ignored $shellmode
    InSh::addCloseHook $wname [list ::xserv::execEndExecHooks \
     $implArray $paramArray]
    return [lindex $task 2]
  }
}

proc ::xserv::executeExec {implArray paramArray} {
  array set params $paramArray
  set cmd [linsert [::xserv::tmpProc] 0 exec]
  if {!$params(xservInteraction)} {
    lappend cmd "&"
  }
  catch {eval $cmd} result
  ::xserv::execEndExecHooks $implArray [array get params] $result
  return $result
}

proc ::xserv::executeAlpha {implArray paramArray} {
  array set params $paramArray
  set result [::xserv::tmpProc]
  ::xserv::execEndExecHooks $implArray [array get params] $result
  return $result
}

###
### New GUI stuff
###

# Set an individual service.
proc ::xserv::setImplementationFor {xservname {group ""}} {
  global ::xserv::currentImplementations
  global ::xserv::services
  
  if {![info exists ::xserv::services($xservname)]} {
    error "Cancelled -- Undeclared service \"$xservname\""
  }
  if {[catch {::xserv::selectImplementationFor $xservname $group} impl]} {
    error "Cancelled -- $impl"
  } elseif {($impl eq "")} {
    error "Cancelled."
  }
  ::xserv::chooseImplementationFor $xservname $impl $group
  status::msg "The new setting for the \"$xservname\" service has been saved."
  return
}

proc ::xserv::implementationList {xservname {group ""}} {
  global ::xserv::currentImplementations
  global ::xserv::services

  if {![info exists ::xserv::services($xservname)]} {
    error "Undeclared service \"$xservname\""
  }

  set bundle [::xserv::getBundleName $xservname]
  if {$bundle != ""} {
    set xservname $bundle
  }

  array set defaultImpl [list]
  if {[info exists ::xserv::currentImplementations($xservname)]} {
    array set current [set ::xserv::currentImplementations($xservname)]
    if {[info exists current($group)]} {
      array set defaultImpl $current($group)
    } elseif {[info exists current("")]} {
      array set defaultImpl $current("")
    }
  }

  set implList [::xserv::getImplementationsOf $xservname]

  if {![::xserv::isBundle $xservname]} {
    set mandatory [::xserv::mandatoryArgsOf $xservname]
    if {[llength $mandatory] == 1} {
      lappend implList "--"
      lappend implList "* Other *"
    }
  }

  set result(implementations) $implList

  if {[info exists defaultImpl(-name)]} {
    set result(default) $defaultImpl(-name)
  } else {
    set result(default) ""
  }

  return [array get result]
}

proc ::xserv::sortServices {} {
  global ::xserv::categories
  set noCat [::xserv::listOfServices]
  if {[info exists ::xserv::categories] 
   && [llength [array names ::xserv::categories]] > 0} {
    foreach cat [array names ::xserv::categories] {
      set avails [list]
      foreach serv [set ::xserv::categories($cat)] {
	if {[lsearch -exact $noCat $serv] != -1} {
	  lappend avails $serv
	}
      }
      if {[llength $avails] > 0} {
	set editCats($cat) $avails
      }
    }
    if {[info exists editCats] && [llength [array names editCats]] > 0} {
      foreach cat [array names editCats] {
	foreach serv $editCats($cat) {
	  set idx [lsearch -exact $noCat $serv]
	  if {$idx != -1} {
	    set noCat [lreplace $noCat $idx $idx]
	  }
	}
      }
      if {[llength $noCat] > 0} {
	set editCats(Miscellaneous) $noCat
      }
    } else {
      set editCats(Miscellaneous) $noCat
    }
  } else {
    set editCats(Miscellaneous) $noCat
  }
  return [array get editCats]
}

###########################################################################
## Command opening/closing stuff (ipc)
###########################################################################
#
# Open a command through a socket pair.
# "cmd"  is the command to execute (with 'exec')
# "mode" is the interaction mode, composed of several characters:
#        'i' means that we can send data to the program input stream
#        'o' means that we can read data from the program output stream
#        'e' means that we can read data from the program error stream
#        For compatibility with xserv::openPipe, 'c' is considered
#        the same as 'e'.
#        other characters are ignored.
# returns a list containing the process ID of the program, the output
# stream of the program and the input stream of the program.
# 
# These streams are sockets obtained with the 'socket' command.
# 
# When the command is finished, 'xserv::closeSocketPair' should be 
# called with one of the returned streams as parameter.
# 
proc ::xserv::openSocketPair {cmd {mode "ioe"}} {
  # Create the socket to communicate with the program
  set sockpair [::socketPair::create]
  set progend [lindex $sockpair 1]
  set myend [lindex $sockpair 0]

  set doit [list eval exec $cmd]

  regsub "c" $mode "e" mode

  global ::
  if {[string first "i" $mode] < 0} {
    lappend doit < $::xserv::devnull
  } else {
    lappend doit <@ $progend
  }
  if {[string first "o" $mode] < 0} {
    lappend doit > $::xserv::devnull
  } else {
    lappend doit >@ $progend
  }
  if {[string first "e" $mode] < 0} {
    lappend doit 2> $::xserv::devnull
  } else {
    lappend doit 2>@ $progend
  }
  lappend doit &
  set pid [eval $doit]
  return [list $pid $myend $myend]
}

# Close a command opened with 'openSocketPair'
# "socket" is any of the sockets returned by 'openSocketPair'
proc ::xserv::closeSocketPair {socket} {
  ::socketPair::close $socket
}

# Open a command through a pipe.
# "cmd"  is the command to execute (with 'open')
# "mode" is the interaction mode, composed of several characters:
#        'i' means that we can send data to the program input stream
#        'o' means that we can read data from the program output stream
#        'e' means that we can read data from the program error stream
#        'c' redirects outputs streams through the 'cat' program. This
#        allows to get the error stream from certain programs.
#        other characters are ignored.
# returns a list containing the process ID of the program, the output
# stream of the program and the input stream of the program.
# 
# These streams are pipes obtained with the 'open' command.
# 
# When the command is finished, 'closePipe' should be called
# with one of the returned streams as parameter.
# 
proc ::xserv::openPipe {cmd {mode "ioe"}} {
  global ::xserv::catPipes
  global ::xserv::catProgram

  set doit "|$cmd"
  set access ""
  set catpipe ""
  if {[string first "c" $mode] < 0} {
    if {[string first "o" $mode] < 0} {
      set out ">$::xserv::devnull"
    } else {
      set out ""
      set access "RD"
    }
    if {[string first "e" $mode] < 0} {
      set err "2>$::xserv::devnull"
    } else {
      set err ""
      set access "RD"
    }
  } else {
    set catpipe [::xserv::invoke "catPipe"]
    fconfigure $catpipe \
     -buffering none \
     -translation auto \
     -blocking 0
    if {[string first "o" $mode] < 0} {
      set out ">$::xserv::devnull"
      set err "2>@ $catpipe"
    } else {
      set out ">&@ $catpipe"
      set err ""
    }
    set access "WRONLY"
  }

  if {[string first "i" $mode] < 0} {
    set in "<$::xserv::devnull"
  } else {
    set in ""
    if {$catpipe == ""} {
      append access "WR"
    }
  }
  if {[string length $access] == 2} {
    append access "ONLY"
  }
  if {($out != "") && ($err != "")} {
    set out ">&$::xserv::devnull"
    set err ""
  }
  append doit " $in $out $err"
  set pipe [open $doit $access]
  fconfigure $pipe \
   -buffering none \
   -translation auto \
   -blocking 0
  set pid [pid $pipe]
  if {$catpipe == ""} {
    return [list $pid $pipe $pipe]
  } else {
    set ::xserv::catPipes($catpipe) $pipe
    return [list $pid $catpipe $pipe]
  }
}

# Close a command opened with 'openPipe'.
# "pipe" is any of the pipes returned by 'openPipe'.
proc ::xserv::closePipe {pipe} {
  global ::xserv::catPipes

  catch {close $pipe}
  if {[info exists ::xserv::catPipes($pipe)]} {
    catch {::close [set ::xserv::catPipes($pipe)]}
    unset ::xserv::catPipes($pipe)
  } else {
    foreach n [array names ::xserv::catPipes] {
      if {[set ::xserv::catPipes($n)] == $pipe} {
	catch {::close $n}
	unset ::xserv::catPipes($n)
	break
      }
    }
  }
}

###########################################################################
### socket pair stuff (emulate TclX 'pipe' command)
###########################################################################
#
namespace eval socketPair {}

# It seems Tcl does not have "socketpair", so we need a server
# to create connected sockets.
proc socketPair::startServer {} {
  global ::socketPair::serverSocket
  global ::socketPair::serverPort
  global ::socketPair::lineEndings

  # Is the server socket already open ?
  if { [info exists ::socketPair::serverSocket] } {
    set running [file channels ${::socketPair::serverSocket}]
  } else {
    set running ""
  }
  if { $running == "" } {
    # If not, create the server socket. socketPair::handleConnect will
    # be called for each new connection to the server.
    set ::socketPair::serverSocket \
     [socket -server socketPair::handleConnect 0]
    set ::socketPair::serverPort \
     [lindex [fconfigure [set ::socketPair::serverSocket] -sockname] 2]
    switch -- $::tcl_platform(platform) {
      "macintosh" {
	set ::socketPair::lineEndings cr
      }
      "unix" {
	set ::socketPair::lineEndings lf
      }
      "windows" {
	set ::socketPair::lineEndings crlf
      }
    }
  }
}

# Kill the server (close the server socket)
proc socketPair::killServer {} {
  global ::socketPair::serverSocket

  catch {close ${::socketPair::serverSocket}}
}

# Handle connections to the server socket.
# "channel" is the newly created socket which is the other
# end of the socket returned by the "socket" command.
# "clientadr" and "clientprt" are the IP address of the client
# and the port to which it is connected.
proc socketPair::handleConnect {channel clientadr clientprt} {
  global ::socketPair::socketPairs
  global ::socketPair::lineEndings

  # Configure the channel right, make it blocking
  fconfigure $channel \
   -buffering none \
   -translation [set ::socketPair::lineEndings] \
   -blocking 1
  # Read the first line which is the name of the shell window
  set name [gets $channel]
  # Make the channel non blocking to avoid the dreaded spinning wheel...
  fconfigure $channel \
   -buffering none \
   -translation [set ::socketPair::lineEndings] \
   -blocking 0
  # Associate this socket to the window
  set socketPair::socketPairs($name) $channel
}

# Create a pair of connected sockets.
proc socketPair::create {} {
  global ::socketPair::serverPort
  global ::socketPair::socketPairs

  # Start the server if needed
  socketPair::startServer

  # Create the socket to communicate with the program
  set clientsocket [socket localhost [set ::socketPair::serverPort]]
  # Configure it right (result of several tries...)
  fconfigure $clientsocket \
   -buffering none \
   -translation [set ::socketPair::lineEndings] \
   -blocking 0
  # Write the name of the socket so the server knows  the peer socket
  puts $clientsocket $clientsocket
  flush $clientsocket
  # Wait for the handler to have filled the socketPairs array
  vwait socketPair::socketPairs($clientsocket)

  return [list $clientsocket [set ::socketPair::socketPairs($clientsocket)]]
}

proc socketPair::close {socket} {
  global ::socketPair::socketPairs

  catch {::close $socket}
  if {[info exists ::socketPair::socketPairs($socket)]} {
    catch {::close [set ::socketPair::socketPairs($socket)]}
    unset ::socketPair::socketPairs($socket)
  } else {
    foreach n [array names ::socketPair::socketPairs] {
      if {[set ::socketPair::socketPairs($n)] == $socket} {
	catch {::close $n}
	unset ::socketPair::socketPairs($n)
	break
      }
    }
  }
}

## End of file `xserv.tcl'.
