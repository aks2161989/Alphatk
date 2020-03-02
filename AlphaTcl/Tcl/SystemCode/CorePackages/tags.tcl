## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "tags.tcl"
 #                                          created: 04/12/2002 {10:48:03 AM}
 #                                      last update: 01/21/2005 {10:18:43 AM}
 # Description:
 # 
 # Implements 'tag' functionality in Alpha.  Used in the Filesets menu.
 # 
 # Author: Vince Darley
 # E-mail: vince@santafe.edu
 #         317 Paseo de Peralta, Santa Fe
 #    www: http://www.santafe.edu/~vince/
 #  
 # ==========================================================================
 ##

alpha::extension tags 0.3.1 {
    # File to use for Tag searches.
    newPref io-file tagFile [file join $HOME cTAGS] tags
    # The parenthesised regexp block to use for the func name
    newPref variable funcPar 1 tags
    # Change tag files without asking the user.
    newPref flag autoSwitchTagFile 1 tags

    package::addPrefsDialog tags

    hook::register fileset-current tags::fileChanged
    
    set "filesetUtils(/T<E<I<OfindTag)" [list * ::tags::find]
    set "filesetUtils(createTagFile)" [list * tags::createFile]
} maintainer {
} description {
    Inserts "Fileset Menu > Utilities" items which support the use of tags
    to find function declarations
} help {
    Alpha supports the use of tags to find declarations of functions; by
    default this is set up only for 'C'.  When searching for a tag, Alpha
    looks for the tag file specified by the 'Tag File' preference, which can
    be set in the "Config > Preferences > Package Prefs > Tags" dialog.
    
    Preferences: tags
    
    Alpha's tag generating routines use the regular expression in the
    preference 'Func Expr' to look for function declarations.  In other words,
    we don't parse the text.  If you declare your functions differently, you
    can change 'Func Expr' to suit your own style.  Alpha currently uses the
    following regular expression to find C function declarations:

	    ^[^ \t\(#\r/@].*\(.*\)$

    Although complicated, this expression makes sense if you slowly wade
    through it.  The string that we are looking for must take up an entire
    line.  It must begin with a character other than '\t', '#', '\r', ' ',
    '/', '(', or '@'.  There must be a set of parenthesis.

    Note that not only can you customize this to your style of 'C'
    declarations, you could also use it to generate tags for other languages.
    The only thing you need to bear in mind is that the tag routines use the
    complete word previous to the first '(' in the selected line as the
    function's name.  If there is no '(' in the selected line, the last word
    in the line is used.  Therefore, Pascal procedures with or without
    parameters can be identified.
}

namespace eval tags {}

# ×××× Tags API ×××× #

#¥ tags::defaultFind - prompt user for a function name and attempt 
#  to use the file 'cTAGS' to locate the function's 
#  definition
proc tags::defaultFind {} {
    if {[llength [winNames -f]]} {
	set name [getSelect]
    } else {
	set name ""
    }
    set name [prompt "Find which name?" $name]
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    }
    set tagFile [tags::name]
    if {![catch {alphaOpen $tagFile r} fin]} {
	while {![eof $fin]} {
	    set line [gets $fin]
	    if {[lindex $line 0] eq $name} {
		close $fin
		set fl [lindex $line 1]
		file::openQuietly [lindex $fl 0]
		goto [pos::fromRowCol [lindex $fl 1] 0]
		status::msg "Found function"
		return
	    }
	}
	close $fin
	status::msg "Couldn't find function."
    } else {
	status::msg "Couldn't read tag file."
    }
}
#¥ tags::defaultCreateFile - searches all files in current file set 
#  and saves the locations of any function declarations
#  in a file called 'cTAGS'.
proc tags::defaultCreateFile {} {
    global tagsmodeVars funcExpr currFileSet
    
    if {[info exists funcExpr]} { 
	set expr $funcExpr 
    } else {
        set expr {^[^ \t\(#\r/@].*\(.*\)$}
    }
    set expr [prompt {Function Expression:} $expr]
    
    set tagscan [scancontext create]
    scanmatch $tagscan $expr {
	set func($matchInfo(submatch0)) [list $f $matchInfo(linenum)]
    }
    
    foreach f [getFileSet $currFileSet] {
	if {![catch {open $f r} fid]} {
	    status::msg "scanning [file tail $f]É"
	    scanfile $tagscan $fid
	    close $fid
	}
    }
    scancontext delete $tagscan
    
    status::msg "Writing tag file $tagFile"
    if {![catch {alphaOpen $tagsmodeVars(tagFile) w} tagOut]} {
	foreach a [lsort [array names func]] {
	    puts $tagOut [list $a $func($a)]
	}
	close $tagOut
	status::msg "Done."
    } else {
	status::msg "Couldn't write tag file."
    }
}


proc tags::name {} {
    global gfileSets currFileSet 
    return [file join [lindex $gfileSets($currFileSet) 0] \
      "[join ${currFileSet}]TAGS"]
}

proc tags::find {} {
    global gfileSetsType currFileSet
    # try a type-specific method first
    if {[catch {fileset::$gfileSetsType($currFileSet)::findTag}]} {
	tags::defaultFind
    }
}

proc tags::createFile {} {
    global gfileSetsType currFileSet tagsmodeVars
    set tagsmodeVars(tagFile) [tags::name]
    prefs::modified tagsmodeVars(tagFile)
    
    # try a type-specific method first
    if {[catch {fileset::$gfileSetsType($currFileSet)::createTagFile}]} {
	tags::defaultCreateFile
    }
}

# ×××× Helper functions ×××× #

proc tags::fileChanged {args} {
    # Bring in the tags file for this fileset
    global tagsmodeVars
     
    set fname [tags::name]
    if {[file exists $fname] && ($tagFile ne $fname)} {
	if {$tagsmodeVars(autoSwitchTagFile) \
	  || [dialog::yesno "Use tag file from folder\
	  \"[file dirname $fname]\" ?"]} {
	    set tagsmodeVars(tagFile) $fname
	}
    }
}
