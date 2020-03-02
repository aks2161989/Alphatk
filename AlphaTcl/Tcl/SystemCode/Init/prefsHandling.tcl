## -*-Tcl-*- (PreGui)
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "prefsHandling.tcl"
 #                                          created: 02/24/1995 {99:52:30 pm}
 #                                      last update: 03/29/2006 {10:48:37 PM}
 # 
 # Description: 
 # 
 # Procedures for dealing with the user's preferences.
 # 
 # Reorganisation carried out by Vince Darley with much help from Tom
 # Fetherston, Johan Linde and suggestions from the alphatcl-developers
 # mailing list.  Alpha is shareware; please register with the author using
 # the register button in the about box.
 #  
 # ==========================================================================
 ##

proc prefsHandling.tcl {} {}

namespace eval alpha {
    
    variable earlyPrefs
    if {![info exists earlyPrefs] \
      || ([lsearch $earlyPrefs "::alpha::packageRequirementsFailed"] == -1)} {
	lappend earlyPrefs "::alpha::packageRequirementsFailed"
    }
    variable homeChanged
    if {![info exists homeChanged]} {
	set homeChanged 0
    }
}

namespace eval prefs {}

# ===========================================================================
# 
# ×××× Initialization Procedures ×××× #
# 
# All of the procedures in this section are explicitly called when AlphaTcl 
# is first initialized.
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "prefs::loadEarlyConfiguration" --
 # 
 # Called directly in the "initAlphaTcl.tcl" file.
 # 
 # -------------------------------------------------------------------------
 ##

proc prefs::loadEarlyConfiguration {} {
    
    global alpha::home HOME alpha::homeChanged earlyprefDefs earlyarrprefDefs

    # This is for backwards compatibility only.  The first time
    # we see a configuration file we load it and then delete it.
    # It will never be used again.
    if {[cache::exists configuration]} {
	uplevel \#0 [file::readAll [cache::name configuration]]
	cache::delete configuration
    }

    # Load the early preferences.
    catch {prefs::_read early}
    foreach nm [array names earlyprefDefs] {
	ensureNamespaceExists ::$nm
	global ::$nm
	set ::$nm $earlyprefDefs($nm)
    }
    unset -nocomplain earlyprefDefs

    if {[info exists alpha::home] && (${alpha::home} ne $HOME)} {
	set alpha::homeChanged 1
    } else {
	set alpha::homeChanged 0
    }

    catch {prefs::_read earlyarr}
    foreach nm [array names earlyarrprefDefs] {
	set arr [lindex $nm 0]
	set field [lindex $nm 1]
	set val $earlyarrprefDefs($nm)
	ensureNamespaceExists ::$arr
	global ::$arr
	set ::${arr}($field) $val
    }
    unset -nocomplain earlyarrprefDefs
    return
}

# This doesn't seem to be used anywhere.
proc prefs::findEncoding {} {
    
    global PREFS
    
    set enc [file join $PREFS encoding.txt]
    if {[file exists $enc]} {
	return [string trim [file::readAll $enc]]
    } else {
	global alpha::internalEncoding
	return ${alpha::internalEncoding}
    }
}

# This doesn't seem to be used anywhere.
proc prefs::checkListIsUnique {l} {
    
    set res {}
    foreach v $l {
	if {[info exists got($v)]} {
	    lappend errors $v
	} else {
	    set got($v) 1
	    lappend res $v
	}
    }
    if {[info exists errors]} {
	return [list $errors $res]
    } else {
	return ""
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::homeChanged" --
 # "prefs::updateHome" --
 # 
 # Although these are not directly required by the initialization sequence,
 # some early packages (notably "smarterSource") need to have these defined
 # in order to complete their activation sequence.
 # 
 # [prefs::homeChanged] lets the caller know if the $HOME path has changed
 # since the last time that Alpha was launched.  The "alpha::homeChanged"
 # variable should be set elsewhere in the initialization sequence, and if it
 # doesn't exist by the time this file is sourced then we set it above in the
 # [namespace eval alpha] call.
 # 
 # [prefs::updateHome] will ensure that any references to the previous $HOME
 # path in the given variable (preference) will be updated.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::homeChanged {} {
    return $::alpha::homeChanged
}

proc prefs::updateHome {var {type "path"}} {
    
    global alpha::home HOME
    
    if {![prefs::homeChanged]} {
	return
    }
    upvar 1 $var local
    if {![info exists local]} {
	return
    }
    set ahLength [string length $alpha::home]
    if {[array exists local]} {
	switch -- $type {
	    "name" {
		foreach item [array names local] {
		    if {[file::pathStartsWith $item $alpha::home]} {
			set new \
			  "${HOME}[string range $item $ahLength end]"
			set local($new) $local($item)
			unset local($item)
			prefs::modified ${var}($item)
		    }
		}
	    }
	    "list" {
		foreach name [array names local] {
		    set count 0
		    foreach item $local($name) {
			if {[file::pathStartsWith $item $alpha::home]} {
			    set item \
			      "${HOME}[string range $item $ahLength end]"
			    set local($name) \
			      [lreplace $local($name) $count $count $item]
			    prefs::modified ${var}($name)
			}
			incr count
		    }
		}
	    }
	    "path" {
		foreach name [array names local] {
		    set item $local($name)
		    if {[file::pathStartsWith $item $alpha::home]} {
			set local($name) \
			  "${HOME}[string range $local($name) $ahLength end]"
			prefs::modified ${var}($name)
		    }
		}
	    }
	    default {
		return -code error "Bad type '$type' to prefs::updateHome"
	    }
	}
    } else {
	# Convert the value of this variable
	switch -- $type {
	    "list" {
		set count 0
		foreach item $local {
		    if {[file::pathStartsWith $item $alpha::home]} {
			set item "${HOME}[string range $item $ahLength end]"
			set local [lreplace $local $count $count $item]
			prefs::modified $var
		    }
		    incr count
		}
	    }
	    "path" {
		if {[file::pathStartsWith $local $alpha::home]} {
		    set local "${HOME}[string range $local $ahLength end]"
		    prefs::modified $var
		}
	    }
	    default {
		return -code error "Bad type '$type' to prefs::updateHome"
	    }
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Preference Files ×××× #
# 
# All of the procedures in this section are related to the handling of files 
# in the user's PREFS folder.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::readAll" --
 # 
 # Called directly in the body of the "runAlphaTcl.tcl" file.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::readAll {} {
    
    global prefDefs arrprefDefs
	
    catch {prefs::_read}
    foreach nm [array names prefDefs] {
	ensureNamespaceExists ::$nm
	global ::$nm
	set ::$nm $prefDefs($nm)
    }
    unset -nocomplain prefDefs
    
    catch {prefs::_read arr}
    foreach nm [array names arrprefDefs] {
	set arr [lindex $nm 0]
	set field [lindex $nm 1]
	set val $arrprefDefs($nm)
	ensureNamespaceExists ::$arr
	global ::$arr
	set ::${arr}($field) $val
    }
    unset -nocomplain arrprefDefs
}


## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::tclRead" --
 # 
 # Called directly in the body of the "runAlphaTcl.tcl" file.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::tclRead {} {
    
    global PREFS
    
    # Use "prefs.tcl" to define or change any tcl information. 
    if {![file exists [file join $PREFS prefs.tcl]]} {
	if {![file exists $PREFS]} {
	    file mkdir $PREFS
	}
	close [open [file join $PREFS prefs.tcl] "w"]
    }
    uplevel #0 {
	if {[catch {source [file join $PREFS prefs.tcl]}]} {
	    set thisErrInfo $::errorInfo
	    if {[dialog::yesno "An error occurred while loading \"prefs.tcl\".\
	      \rWould you like to open the error information\
	      in a new window?"]} {
		new -n {* prefs.tcl error *} -m Tcl -shrink -info $thisErrInfo
	    }
	}
    }
    return
}

proc prefs::_read {{prefix {}}} {
    
    global PREFS
    
    set filename [file join $PREFS ${prefix}defs.tcl]
    if {![file exists $filename]} return
    
    # Read the contents, but making it HOME-independent
    if {[catch {file::readAll $filename} contents]} {
	alertnote "Your preferences file '${prefix}defs.tcl'\
	  is corrupt; The backup copy will be used instead"
	file delete $filename
	file copy [file join $PREFS backup${prefix}defs.tcl] \
	  $filename
	set contents [file::readAll $filename]
    }
    uplevel \#0 $contents
    return
}

proc prefs::_write {{prefix {}}} {
    
    global HOME PREFS ${prefix}prefDefs tcl_platform
    
    if {![info exists ${prefix}prefDefs]} {
	catch {file delete [file join $PREFS ${prefix}defs.tcl]}
	return
    }
    if {![file exists $PREFS]} {
	file mkdir $PREFS
    }
    set filename [file join $PREFS ${prefix}defs.tcl]
    set fd [alphaOpen $filename "w"]
    
    # Ensure every variable is in a normalized standard format
    # with exactly '::' at front and between each namespace.
    # In the future we can remove this block (once everyone has
    # upgraded).
    set scalar [expr {($prefix eq "") || ($prefix eq "early")}]
    
    foreach nm [array names ${prefix}prefDefs] {
	if {$scalar} {
	    # scalars
	    set nmnorm [namespace which -variable ::$nm]
	    if {$nmnorm eq ""} {
		# Something added with 'prefs::add'
		set nm "::[string trimleft $nm :]"
		#puts $nm
		continue
	    }
	} else {
	    # array variables
	    set arr [lindex $nm 0]
	    set field [lindex $nm 1]
	    set nmnorm [namespace which -variable ::$arr]
	    if {$nmnorm eq ""} {
		# Something added with 'prefs::addArray?'
		set nmnorm "::[string trimleft $arr :]"
		#puts $nmnorm
		continue
	    }
	    set nmnorm [list $nmnorm $field]
	}
	if {$nm ne $nmnorm} {
	    set val [set ${prefix}prefDefs($nm)]
	    unset ${prefix}prefDefs($nm)
	    # This may over-write an equivalent variable,
	    # but during the transition period we let the
	    # unnormalized variables take precedence.
	    set ${prefix}prefDefs($nmnorm) $val
	}
    }
    
    # Must not throw an error!
    foreach nm [array names ${prefix}prefDefs] {
	set val [set ${prefix}prefDefs($nm)]
	# To avoid problems with conversion of eols when re-reading
	# the file, we turn eols into their quoted format.
	if {[regexp -- {[\r\n]} $val]} {
	    puts $fd "set \"[quote::Insert ${prefix}prefDefs($nm)]\"\
	      \"[quote::Insert $val]\""
	} else {
	    puts $fd [list set ${prefix}prefDefs($nm) $val]
	}
    }
    close $fd
    return
}

proc prefs::add {def val {prefix {}}} {
    
    global ${prefix}prefDefs
    
    prefs::_read $prefix
    set ${prefix}prefDefs($def) $val
    prefs::_write $prefix
    unset -nocomplain ${prefix}prefDefs
    return
}

proc prefs::remove {def {prefix {}}} {
    
    global ${prefix}prefDefs
    
    prefs::_read $prefix
    unset -nocomplain ${prefix}prefDefs($def)
    prefs::_write $prefix
    unset -nocomplain ${prefix}prefDefs
    return
}

proc prefs::addArrayElement {arr def val} {
    prefs::add [list $arr $def] $val arr
    return
}

proc prefs::removeArrayElement {arr def} {
    prefs::remove [list $arr $def] arr
    return
}

proc prefs::addArray {arr} {
    
    global arrprefDefs $arr
    
    prefs::_read arr
    # Remove all old entries.  We have to do this because the code just after
    # will only update existing entries, so old array elements which we no
    # longer want will never disappear.
    foreach r [array names arrprefDefs] {
	if {[lindex $r 0] eq $arr} {
	    unset arrprefDefs($r)
	}
    }
    foreach def [array names $arr] {
	catch {set arrprefDefs([list $arr $def]) [set ${arr}($def)]}
    }
    prefs::_write arr
    unset -nocomplain arrprefDefs
    return
}

proc prefs::removeArray {arr} {
    
    global arrprefDefs $arr
    
    prefs::_read arr
    foreach def [array names $arr] {
	unset -nocomplain arrprefDefs([list $arr $def])
    }
    prefs::_write arr
    unset -nocomplain arrprefDefs
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Defining Preferences ×××× #
# 
# All of the procedures in this section are related to the setting and
# storage of user preferences.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval prefs" --
 # 
 # Declare basic preference types
 # 
 # Note: other types are triggered by preference variable names ending in
 # 'Colour', 'Color', 'Folder', 'Path', 'Mode', 'FilePaths' 'SearchPath',
 # 'Sig' etc.  as described below in the [newPref] annotation.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval prefs {
    
    variable types
    if {![info exists types]} {
	set types [list "flag" "variable" "binding" "menubinding" \
	  "file" "io-file" "url" "geometry"]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::addType" --
 # 
 # Define a new preference type.  Always use this procedure, don't mess with
 # the 'prefs::types' variable directly.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::addType {type} {
    
    variable types
    
    if {([lsearch -exact $types $type] == -1)} {
	lappend types $type
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "newPref" --
 # 
 # Define a new preference variable/flag.  You can call this procedure either
 # with multiple arguments or with a single list of all the arguments.  So
 # 'newPref flag Hey ...'  or 'newPref {flag Hey ...}' are both fine.
 #  
 # 'type' is one of:
 # 
 #    'binding'         (key-combo)
 #    'file'            (input only),
 #    'flag'            (on/off only)
 #    'io-file'         (either input or output)
 #    'menubinding'     (key-combo which works in a menu)
 #    'variable'        (anything)
 #    
 #  Variables whose name ends in
 #  
 #    Color
 #    Colour
 #    FilePaths
 #    Folder
 #    Mode
 #    Path
 #    SearchPath 
 #    Sig
 #    
 # (case matters here) are treated differently, but are still considered of
 # type 'variable'.  For convenience this proc will map types sig, folder,
 # color, ...  into 'variable' for you, _if_ the variable ends with the
 # correct string.
 #    
 # 'name' is the var name, 
 #  
 # 'val' is its default value (which will be ignored if the variable already
 # has a value)
 #  
 # 'pkg' is either 'global' to mean a global preference, or the name of the
 # mode or package (no spaces) for which this is a preference.
 #  
 # 'pname' is a script to evaluate if this preference is changed by the user
 # (no need to setup a trace).  This script is only evaluated for changes
 # made through prefs dialogs or prefs menus created by Alpha's core procs
 # (or anything which ends up call prefs::changed).  Other changes are not
 # traced.  This script is always evaluated by appending " $prefname".  This
 # means it will typically be the name of a proc which takes one argument.
 # If you don't want to take any arguments, give a script like "myproc ;#".
 #  
 # Depending on the previous values, there are two optional arguments with
 # the following uses:
 #  
 # TYPE:
 #  
 # variable:
 #  
 #   'options' is a list of items from which this preference takes a single
 #   item.
 #   
 #   'subopt' defaults to 'item' if none is supplied, but can be any of
 #   
 #     'array'          take one of the values from an array.
 #     'index'          an index for the 'options' list
 #     'item'           the pref is simply an item from the given list
 #     'varindex'
 #     'varitem'
 #     
 #   'var*' indicates 'options' is in fact the name of a global variable
 #   which contains the list; the default is either an item or an index of
 #   that list.
 #   
 # binding:
 #  
 #   'options' is the name of a procedure to which this item will be bound.
 #   If options = '1', then we [Bind] to the proc with the same name as this
 #   variable.  Otherwise we do not perform automatic bindings.
 #  
 #   'subopt' indicates whether the binding is mode-specific or global.  It
 #   should either be 'global' or the name of a mode.  If not given, it
 #   defaults to 'global' for all non-modes, and to mode-specific for all
 #   packages.  (Alpha tests if something is a mode by [mode::exists])
 #   
 # --------------------------------------------------------------------------
 # 
 # Initialization notes: This procedure must be in place during the AlphaTcl 
 # initialization sequence.  When it is called, however, it might need to 
 # have the following procedures in place (or be auto_loaded):
 # 
 #     globalVarCopyFromMode
 #     globalVarIsShadowed
 #     globalVarSet
 #     keys::toBind
 # 
 # At present, it appears that any early calls to [newPref] do not encounter
 # any code paths below which require those procedures.
 # 
 # --------------------------------------------------------------------------
 ##

proc newPref {vtype {name {}} {val 0} {pkg "global"} {pname ""} {options ""} \
  {subopt ""}} {
    
    global allFlags allVars prefs::script prefs::registered \
      prefs::type prefs::types alpha::earlyPrefs alpha::platform

    if {($name eq "")} {
	uplevel 1 newPref $vtype ; return
    }
    # 'link' means link this variable with Alpha's internals.
    if {[regexp {^early(.*)$} $vtype "" vtype]} {
	if {($val ne "")} {
	    # for earlylink* : preserve values that have been set early
	    global $name
	    if {[info exists $name]} {
		set val [set $name]
	    }
	}
	set early 1
    }
    if {[regexp {^link(.*)$} $vtype "" vtype]} {
	linkVar $name
	# Linked variables over-ride differently to normal preferences, in
	# that the given value always over-rides any pre-existing value
	# (which would've been set by the process of linking inside linkVar).
	if {$val != ""} {
	    global $name
	    set $name $val
	}
    }
    set bad 1
    foreach ty ${prefs::types} {
	if {([string first $vtype $ty] == 0)} {
	    set vtype $ty
	    set bad 0
	    break
	}
    }
    if {$bad} {
	foreach ty {FilePaths SearchPath Folder Path Mode Colour Color Sig} {
	    if {([string first $vtype [string tolower $ty]] == 0)} {
		if {[regexp -- "${ty}\$" $name]} {
		    set vtype variable
		    set realtype [string tolower $ty]
		    set bad 0
		    break
		} else {
		    error "Type '$vtype' requires the variable's name\
		      to end in '$ty'"
		}
	    }
	}
	if {$bad} {
	    error "Unknown type '$vtype' in call to newPref"
	}
    }
    if {($pkg eq "global")} {
	switch -- $vtype {
	    "flag" {
		lappend allFlags $name
	    }
	    "variable" {
		lappend allVars $name
	    }
	    default {
		set prefs::type($name) $vtype
		lappend allVars $name
	    }
	}
	
	global $name mode
	if {[info exists mode] && ($mode ne "")} {
	    global ${mode}modeVars
	    if {[info exists $name] && [info exists ${mode}modeVars($name)]} {
		# Don't override an existing mode variable which has been
		# copied into the global namespace; instead just place value
		# in the global cache.  But only do this if it isn't already
		# in there.
		if {![globalVarIsShadowed $name]} {
		    globalVarSet $name $val
		}
	    } else {
		if {![info exists $name]} {
		    set $name $val
		} else {
		    set val [set $name]
		}
	    }
	} else {
	    if {![info exists $name]} {
		set $name $val
	    } else {
		set val [set $name]
	    }
	    if {[info exists early]} {
		set evname [uplevel 1 [list namespace which -variable $name]]
		if {$evname eq ""} {
		    alertnote "Error in newPref with early var $name"
		}
		lappend alpha::earlyPrefs $evname
	    }
	}
	set fullname $name
    } else {
	global ${pkg}modeVars mode knownVars
	if {![info exists knownVars] \
	  || ([lsearch -exact $knownVars $name] == -1)} {
	    lappend knownVars $name
	}
	if {![info exists ${pkg}modeVars($name)]} {
	    set ${pkg}modeVars($name) $val
	} else {
	    set val [set ${pkg}modeVars($name)]
	}
	if {[info exists mode] && ($mode eq $pkg)} {
	    globalVarCopyFromMode $mode [list $name $val]
	}
	switch -- $vtype {
	    "flag" {
		if {([lsearch -exact $allFlags $name] == -1)} {
		    lappend allFlags $name
		}
	    }
	    "variable" {
		lappend allVars $name
	    }
	    default {
		set prefs::type($name) $vtype
		lappend allVars $name
	    }
	}
	set fullname ${pkg}modeVars($name)
    }
    # handle 'options'
    if {($options ne "")} {
	switch -- $vtype {
	    "variable" {
		if {[info exists realtype]} {
		    global prefs::extraOptions
		    set prefs::extraOptions($name) $options
		} else {
		    global prefs::list
		    if {$subopt eq ""} { set subopt "item" }
		    if {[lsearch -exact [list array item index varitem \
		      varindex cmditem cmdindex] $subopt] == -1} {
			error "Unknown list element type '$subopt'\
			  in call to newPref."
		    }
		    set prefs::list($name) [list $subopt $options]
		}
	    }
	    "binding" {
		global prefs::binding
		if {[mode::exists $pkg]} {
		    if {$subopt eq ""} {
			set subopt $pkg
		    } else {
			if {$subopt eq "global"} {
			    set subopt ""
			}
		    }
		}
		set prefs::binding($name) [list $subopt $options]
		if {($options == 1)} {
		    set options $name
		}
		if {($val ne "")} {
		    set toBind [keys::toBind $val]
		    if {($toBind eq "")} {
			error "Bad key '$val' given to 'newPref binding $name'"
		    }
		    catch "Bind $toBind [list $options] $subopt"
		}
	    }
	}
    }
    # register the 'modify' proc
    if {[string length $pname]} {
	set prefs::script($fullname) $pname
    }
    set prefs::registered($fullname) 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::register" --
 # 
 # Register a preference so that it will appear in a prefs dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::register {prefName {pkg ""}} {
    
    variable registered
    
    if {($pkg ne "")} {
	set registered(${pkg}modeVars($prefName)) 1
    } else {
	set registered($prefName) 1
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::deregister" --
 # 
 # Deregister a preference so that it will not appear in a prefs dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::deregister {prefName {pkg ""}} {
    
    variable registered

    if {($pkg ne "")} {
	unset -nocomplain registered(${pkg}modeVars($prefName))
    } else {
	unset -nocomplain registered($prefName)
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::isRegistered" --
 # 
 # Determine if a preference has been registered, i.e. whether it should
 # appear in a prefs dialog or not.
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::isRegistered {prefName {pkg ""}} {
    
    variable registered

    if {($pkg ne "")} {
	return [info exists registered(${pkg}modeVars($prefName))]
    } else {
	return [info exists registered($prefName)]
    }
}

# ===========================================================================
# 
# ×××× Manipulating Saved Preferences ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::removeObsolete" --
 # 
 # Use this only for preference variables which are truly obsolete, and never
 # referenced in code.  It 'unsets' the variables, so that accessing them
 # again will cause errors.  To forget a users preference for something (so
 # that it reverts to a default value), you should use [prefs::remove] or
 # [prefs::removeArrayElement] (both of which can only take effect after a
 # restart).
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::removeObsolete {args} {
    
    set count 0
    foreach what $args {
	if {[uplevel \#0 info exists [list $what]]} {
	    prefs::modified $what
	    uplevel \#0 unset [list $what]
	    incr count
	}
    }
    return $count
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::renameOld" --
 # 
 # Useful to allow authors to rename preferences variables without
 # inconveniencing their users.  Returns 1 if a renaming did take place (this
 # allows the author to take an action such as telling the user).
 # 
 # --------------------------------------------------------------------------
 ##

proc prefs::renameOld {from to} {
    
    if {[uplevel \#0 [list info exists $from]]} {
	uplevel \#0 [list prefs::modified $from]
	if {[uplevel \#0 [list array exists $from]]} {
	    uplevel \#0 [list array set $to [uplevel \#0 [list array get $from]]]
	} else {
	    uplevel \#0 [list set $to [uplevel \#0 [list set $from]]]
	}
	uplevel \#0 [list prefs::modified $to]
	uplevel \#0 [list unset $from]
	return 1
    } else {
	return 0
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "prefs::modified" --
 # 
 # Accepts either scalar or array variables, which may be completely
 # specified, or just relative to the calling namespace.
 #  
 # Adds the given variables to the list of things to save when the user
 # 'quits' (or elects to 'save preferences now').  If the variable doesn't
 # exist when saving preferences, it is not saved, BUT the variable must
 # exist when this function is actually called.
 #  
 # --------------------------------------------------------------------------
 ##

proc prefs::modified {args} {
    
    variable modifiedVars
    variable modifiedArrayElements
    
    foreach what $args {
	set arr [regexp {^([^\(]+)\((.+)\)$} $what -> what arrayEntry]
	set what [uplevel 1 [list namespace which -variable $what]]
	if {($what eq "")} {
	    return -code error \
	      "variable either doesn't exist or is local: $what"
	}
	if {$arr} {
	    lappend modifiedArrayElements [list $arrayEntry $what]
	} else {
	    lappend modifiedVars $what
	}
    }
    return
}

# ===========================================================================
# 
# .