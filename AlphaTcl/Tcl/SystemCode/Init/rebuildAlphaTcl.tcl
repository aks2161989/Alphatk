# (After status bar exists)
# 
# This is used after the primary PreGui phase.  When this is sourced the
# 'status::msg' command will work (and the status bar will have been
# created and be visible to the user).
# 
# However, this and its companion files pkgsDeclare.tcl and
# rebuilding.tcl are placed here because they contain all the
# infrastructure required to allow the main package rebuilding at
# startup to proceed, which must happen as early as possible after the
# PreGui phase.  In that sense it is quite distinct from the rest of
# AlphaTclCore.
# 
# Critical commands at this stage:
# 
#   status::msg
#   getModifiers
#   watchCursor
#    
# Variables needed:
# 
#   ??


# If configuration has changed, rebuild package and tcl indices

set alpha::rebuilding 0

if {[info commands auto_load] eq ""} {
    alertnote "There is no auto_load command, which is a serious problem.\
      Please report this bug.  $alpha::application will probably not work."
}

# If this already exists we had a problem later in startup and are
# actually trying to get everything going a second time.
if {![info exists initAlphaTclErr]} {
    # Check whether we are likely to have some bad problems
    # usually caused by corrupt/badly out of date Tcl
    # indices, or a bad/partial installation.  This should pull
    # in our companion pkgsDeclare.tcl and rebuilding.tcl files.
    proc loadingOk {} {
	set res 0
	foreach p {
	    alpha::package alpha::rebuildPackageIndices rebuildTclIndices
	} {
	    # Only auto_load if the command is not already there, else
	    # we'll source the same files again.
	    if {[info commands $p] eq ""} {
		if {![auto_load $p]} {
		    set res 1
		    break
		}
	    }
	}
	rename loadingOk {}
	return $res
    }
    set initAlphaTclErr [loadingOk]
}

if {$initAlphaTclErr || \
  ([catch {alpha::checkConfiguration} initAlphaTclErr] \
  || ($initAlphaTclErr == 1))} {
    alertnote "You have recently installed or upgraded\
      $alpha::application, or installed/removed one of its packages.\
      \r\r$alpha::application must now rebuild all of its package indices;\
      this will ensure that future launches will take place much faster.\
      \r\rThis will take a little while…"
    # For safety's sake, ensure these are loaded (in case we don't have
    # any tclIndex files at all):
    source [file join $HOME Tcl SystemCode Init pkgsDeclare.tcl]
    source [file join $HOME Tcl SystemCode Init rebuilding.tcl]

    # There may be a better or more general way of getting smarter source
    # loaded early enough than this, but it's the best we've got so far!
    if {[info exists ::global::features]} {
	if {[lsearch -exact $::global::features "smarterSource"] != -1} {
	    if {[info exists ::index::feature(smarterSource)]} {
		catch {package::activate "smarterSource"}
	    }
	}
    }

    # For lunion and ensureset, both used by error.tcl
    source [file join $HOME Tcl SystemCode stringsLists.tcl]
    # We need this (at present) so bgerror/error::occurred will work ok.
    source [file join $HOME Tcl SystemCode CorePackages error.tcl]

    if {[getModifiers] & 72} {
	# Power-user can use 'option' to avoid the rebuild.
	alertnote "Because the Option key was pressed, indices will\
	  not be rebuilt."
	return
    }
    
    if {[catch {rebuildTclIndices} err]} {
	alertnote "There was a bad problem while making\
	  the tcl indices: $err"
	error $err
    }

    if {[catch {alpha::makeIndices} err]} {
	alertnote "There was a bad problem while making\
	  the package indices: $err"
	error $err
    }

    unset -nocomplain err
    # rerun the tclAE ifneeded script if present (bug 846)
    catch {eval [::package ifneeded tclAE [::package present tclAE]]}
} elseif {[procs::find lunion] eq "" || [procs::find error::occurred] eq ""} {
    alertnote "Your AlphaTcl indices are corrupt or missing. I'll have\
      to rebuild them now.  This will take a few seconds."
    # It could be we don't have a system code tcl index
    if {[catch {rebuildTclIndices} err]} {
	alertnote "There was a bad problem while making\
	  the tcl indices: $err"
	error $err
    }
    unset -nocomplain err
}
unset initAlphaTclErr

# Minimum supported versions of Alphatk and Alpha 8/X are checked here.
if {[alpha::package vcompare $alpha::version \
  [expr {$alpha::platform eq "tk" ? "8.3.3" : "8.0b17"}]] < 0} {
    if {([alert -t caution -k "OK" -o "Open Web Page" -c "" \
      "This version of $alpha::application is too old.\
      Upgrade from http://www.purl.org/net/alpha/wiki/ \
      \r\r${alpha::application} must quit now."] eq "Open Web Page")} {
	url::execute "http://www.purl.org/net/alpha/wiki/"
    }
    quit
}
if {[package vcompare [package provide Tcl] 8.4] < 0} {
    alertnote "The version of Tcl ([package provide Tcl]) which\
      is available to $alpha::application is too old.\
      Please upgrade. \
      \r\r${alpha::application} must quit now."
    quit
}
