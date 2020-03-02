## -*-Tcl-*- (PreGui)
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "cache.tcl"
 #                                    created: 17/7/97 {3:21:07 pm} 
 #                                last update: 04/27/2004 {12:12:51 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2004  Vince Darley, all rights reserved
 # 
 # Usage:
 # 
 #  cache::create 'name'
 #  cache::add 'name' variable var1 var2 ...
 #  cache::add 'name' eval "beep" "menu Blah {}" ...
 # 
 # then:
 # 
 #  if {[cache::exists 'name']} {
 # 	cache::readContents 'name'
 # 	puts "var1 = $var1, var2 = $var2"
 # 	puts "Also I beeped and created a menu 'Blah'"
 #  }
 # 
 # There are also procs to delete a cache (or several).
 #  
 # ###################################################################
 ##

namespace eval cache {}
# so if we make incompatible changes we can automatically delete
# or re-interpret incompatible caches.
set cache::version 1.2

## 
 # -------------------------------------------------------------------------
 # 
 # "cache::exists" --
 # 
 #  Is there a cache with the given name
 # -------------------------------------------------------------------------
 ##
proc cache::exists {name} {
    return [file exists [cache::name $name]]
}

proc cache::compareDates {name1 op name2} {
    expr [file mtime [cache::name $name1]] $op [file mtime [cache::name $name2]]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "cache::readContents" --
 # 
 #  Read all the information from the given cache, into the _current_
 #  execution level.  If you're in a proc and you want to read the
 #  cache (or some of it) into global variables, you must precede
 #  this call with a 'global' statement.
 #  
 #  If the cache doesn't exist this proc will give an error.
 #  Use 'cache::exists' first to check.
 # -------------------------------------------------------------------------
 ##
proc cache::readContents {name} {
    uplevel 1 {namespace eval cache {}}
    uplevel 1 {set cache::eval 1}
    uplevel 1 [list source [cache::name $name]]
    uplevel 1 {unset cache::eval}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "cache::create" --
 # 
 #  Write the given cache name with the given value.  If any other arguments
 #  are given, they are the names of other variables/arrays which should
 #  also be stored.
 # -------------------------------------------------------------------------
 ##
proc cache::create {name args} {
    close [cache::fopen $name create]
    if {[llength $args]} {
	uplevel 1 [list cache::add $name] $args
    }
}

proc cache::delete {args} {
    foreach name $args {
	if {[cache::exists $name]} {
	    catch {file delete [cache::name $name]}
	}
    }
}

proc cache::deletePat {name} {
    set path [cache::name $name]
    foreach f [glob -nocomplain -dir [file dirname $path] -- [file tail $path]] {
	catch {file delete $f}
    }
}

proc cache::name {name} {
    if {[regexp {(.*)::[^:]+} $name "" ns]} {
	# currently only allows one level of nesting
	uplevel 1 "namespace eval $ns {}"
	regsub -all "::" $name ":" name
	set name [eval [list file join] [split $name :]]
    }
    global PREFS ::alpha::cache
    if {[info exists ::alpha::cache]} {
	return [file join $::alpha::cache $name]
    } else {
	return [file join $PREFS Cache $name]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "cache::add" --
 # 
 #  Write additional information into a pre-existing cache.  The other
 #  arguments are just variable names to store, if type is 'variable'.
 #  Otherwise they are strings to be evaluated, if type is 'eval'.
 # -------------------------------------------------------------------------
 ##
proc cache::add {name type args} {
    set fcache [cache::fopen $name append]
    switch -- $type {
	"variable" {
	    foreach a $args {
		upvar 1 $a var
		# Store under the namespace tail only
		regexp -- {^(.*)::([^:]+)$} $a -> ns a
		if {[array exists var]} {
		    foreach n [array names var] {
			puts $fcache [list set ${a}(${n}) [set var(${n})]]
		    }
		} else {
		    if {[info exists var]} {
			puts $fcache [list set $a [set var]]
		    }
		}
	    }
	}
	"eval" {
	    foreach a $args {
		puts $fcache [list if \$\{cache::eval\} [list eval $a]]
	    }
	}
	default {
	    close $fcache
	    return -code error "Unknown type '$type' to cache::add"
	}
    }
    close $fcache
}

## 
 # -------------------------------------------------------------------------
 # 
 # "cache::fopen" --
 # 
 #  You shouldn't really call this procedure.  Call the others.
 # -------------------------------------------------------------------------
 ##
proc cache::fopen {name {action "create"}} {
    # This is defined by Tcl to create all parent directories, and not
    # to complain if the given directory already exists.
    file mkdir [file dirname [set c [cache::name $name]]]
    
    switch -- $action {
	"create" {
	    set fcache [alphaOpen $c w]
	    puts $fcache "# -*-Tcl-*- (nowrap)"
	    global cache::version
	    puts $fcache "# Cache v${cache::version} created on [mtime [now]]"
	}
	"append" {
	    if {![file exists $c]} {close [cache::fopen $name create]}
	    set fcache [alphaOpen $c a]
	}
	"read" {
	    if {![file exists $c]} {close [cache::fopen $name create]}
	    set fcache [alphaOpen $c r]
	}
	default {
	    error "No such cache action '$action'"
	}
    }
    return $fcache
}

## 
 # -------------------------------------------------------------------------
 # 
 # "cache::readFile" --
 # 
 #  Read the entire contents of a cache into the given variable
 # -------------------------------------------------------------------------
 ##
proc cache::readFile {name contentsVar} {
    set f [cache::name $name]
    upvar 1 $contentsVar c
    if {[file exists $f] && [file readable $f]} {
	set fileid [alphaOpen $f "r"]
	set c [read $fileid]
	close $fileid
    } else {
	set c ""
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "cache::writeFile" --
 # 
 #  Overwrite a cache with the value of the given variable 
 # -------------------------------------------------------------------------
 ##
proc cache::writeFile {name contentsVar} {
    upvar 1 $contentsVar c
    set fileid [alphaOpen [cache::name $name] "w"]
    puts -nonewline $fileid $c
    close $fileid
}



