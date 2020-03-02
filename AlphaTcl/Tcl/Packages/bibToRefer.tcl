## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "bibToRefer.tcl"
 #                                          created: 08/24/1998 {15:25:47 PM}
 #                                      last update: 03/21/2006 {02:01:46 PM}
 # 
 # Converts BibTeX entries into Refer format, which can then be imported into
 # EndNote files.  There is no one-to-one correspondance between these two
 # formats, so the user will have to carefully inspect the results.  The proc
 # [Bib::ToRefer::convertEntry] goes to some trouble to clean up the strings,
 # and we try to use some "LaTeX Accents" support as well.
 #                               
 # (Vince turned this contributed code into a package)
 # 
 # Author: Peter Blattner  <peter.blattner@imt.unine.ch>
 # Author: Vince Darley
 # 
 # Includes contributions from Craig Barton Upright
 # 
 # Copyright (c) 1998-2006 Peter Blattner, Vince Darley and Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #
 # --------------------------------------------------------------------------
 # 
 # Some background on Refer tags.
 # 
 # <http://www.ecst.csuchico.edu/~jacobsd/bib/formats/refer.html>
 # 
 # Standard tags
 # -------------
 #
 # H    Header commentary which is printed before the reference. 
 # 
 # A    Author's name.  Authors should be listed in order, with the senior
 #      author first.  Names are given in "First Last" format.  If the name
 #      contains a suffix, it should be appended at the end with a comma,
 #      e.g. "Jim Jones, Jr.".  For books with an editor but no author, the
 #      editor can go in the author field with a suffix of "ed", "eds", or
 #      something similar.
 #      
 # Q    Corporate author.  Some sources also say to put foreign authors who
 #      have no clear last name in this field, but others claim the name
 #      here should be that of a non-person.  Last time I checked, foreign
 #      authors were still people.
 #      
 # T    Title of the article or book. 
 # 
 # S    Title of the series. 
 # 
 # J    Journal containing the article. 
 # 
 # B    Book containing article. 
 # 
 # R    Report, paper, or thesis type. 
 # 
 # V    Volume. 
 # 
 # N    Number with volume. 
 # 
 # E    Editor of book containing article. 
 # 
 # P    Page number(s). 
 # 
 # I    Issuer. This is the publisher. 
 # 
 # C    City where published. This is the publishers address. 
 # 
 # D    Date of publication.  The year should be specified in full, and the
 #      month name rather than number should be used.
 # 
 # O    Other information which is printed after the reference. 
 # 
 # K    Keywords used by refer to help locate the reference. 
 # 
 # L    Label used to number references when the -k flag of refer is used. 
 # 
 # X    Abstract. This is not normally printed in a reference. 
 # 
 # Other tags
 # ----------
 # 
 # If you use EndNote Plus, you should look at the EndNote format page,
 # which describes the differences between standard refer and EndNote's
 # variant.
 # 
 # I believe these come from BibIX: 
 # 
 # F    Caption 
 # 
 # G    US Government ordering number 
 # 
 # W    Where the item can be found (physical location of item) 
 # 
 # 6    The number of volumes. 
 # 
 # 7    Edition 
 # 
 # 8    Date associated with entry.  For a conference proceedings, this
 #      would be the date of the conference.
 # 
 # 9    How the entry was published.  For reports, this would be the report
 #      type, and for theses, the thesis type (e.g. "Ph.D.", "Masters").
 # 
 # Y    The series editor.
 #      
 # Here are some other fields I've seen used:
 # ------------------------------------------ 
 # 
 # $    Price 
 # 
 # *    Copyright information 
 # 
 # M    Mathematical Reviews number.  The BIB format (almost exactly like
 #      refer) uses this for the month, and has only the year in the %D field.
 #      
 # Y    Table of Contents 
 # 
 # Z    Pages in the entire document. Tib reserves this for special use. 
 # 
 # l    Language used for document. 
 # 
 # U    Annotation. Some people use this for a WWW URL field. 
 # 
 # W    Location of conference. 
 # 
 #
 # Artwork 
 # Audiovisual Material 
 # Book 
 # Book Section 
 # Computer Program 
 # Conference Proceedings 
 # Edited Book 
 # Generic 
 # Journal Article 
 # Magazine Article 
 # Map 
 # Newspaper Article 
 # Patent 
 # Personal Communication 
 # Report 
 # Thesis 
 # 
 # ==========================================================================
 ##
 
alpha::feature bibToRefer 1.3 "Bib" {
    # Initialization script.
    alpha::package require -loose Bib 4.3
} {
    # Activation script.
    menu::insert bibtexConversions items end "bibToRefer…"
} {
    # Deactivation script.
    # Could uninsert the menu items, but then they won't be in the menu
    # if the BibTeX menu is global but this package is not.
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Inserts a new "BibTeX Menu > BibTeX Conversions" menu item that converts
    BibTeX windows/files to Refer (Endnote compatible)
} help {
    This package is primarily a feature for Bib mode.
    
    Preferences: Mode-Features-Bib
    
    It implements the conversion of BibTeX to Refer (Endnote compatible), by
    adding a "BibTeX Menu > BibTeX Conversions > Bib To Refer" menu item.  If
    the active window is in Bib mode, then all of the entries in the current
    selection (or, if there is no selection, all entries in the window) will
    be converted and inserted into a new window.  You can then save this
    window on your local disk, and use EndNote's "File > Import" command to
    add them to a .enf file.
    
    For example, this:
    
	@article{Lamont1987,
	   author  = {Mich\`{e}le Lamont},
	   title   = {How to Become a Dominant French Philosopher: The Case of
		      Jacques Derrida},
	   journal = {American Journal of Sociology},
	   volume  = 93,
	   number  = 3,
	   pages   = {584-622},
	   year    = 1987,
	   key     = {culture, derrida, france},
	}

    will be converted to
    
	%0 JOURNAL ARTICLE
	%F Lamont1987
	%A Michèle Lamont
	%T How to Become a Dominant French Philosopher: The Case of Jacques Derrida
	%J American Journal of Sociology
	%V 93
	%N 3
	%P 584-622
	%D 1987
	%K culture; derrida; france
    
    Because BibTeX and EndNote database entries do not have a one-to-one
    correspondance, the conversion results here will need to be carefully
    inspected and adjusted after importing them into a different helper.  As
    is the case with any BibTeX to Refer conversion, this procedure is only
    an approximation, and comes with no guarantees.
    
    Some notes about the conversion:

    • All "@string" strings will be converted in the conversion, assuming
    that the strings are defined in the file/window that uses them.
    
    • If there are several authors, each author has its own tag %A.
    
    • "Protected" authors, such as
    
	author = {{U.S. Department Of Agriculture}},
    
    will have a comma appended after their name, as in
    
	%A U.S. Department Of Agriculture,

    • All "LaTeX Accents" will be converted to diacritical characters,
    assuming the the package: latexAccents is installed.  This takes place
    automatically, there's nothing more that you need to do.
    
    • Selecting "BibTeX Menu > Formatting > Format All Entries" before
    performing the conversion will often make the results more accurate.
    
    • The following BibTeX fields are not standard, and ignored when you
    BibTeX a file, but if they are present they will be added to the
    indicated Refer fields:
    
	abstract        -> %X (abstract)
	annote          -> %G (note)
	isbn            -> %@ (isbn)
	issn            -> %@ (issn)
	key             -> %K (descriptor)
	keywords        -> %K (keywords)

    • Each entry's "citekey" will be added as "%F (label)".  All other fields
    will be given some "%1 %2 ...  Custom Field" designation.
    
    Another "BibTeX To Refer" conversion option involves the "refer.bst"
    LaTeX package.  For more information, perform a search for this file at
    <http://www.ctan.org> and read its documentation.
}


# ===========================================================================
# 
# Set-up of the fields used to make the Refer conversion
# 

namespace eval Bib {}

proc Bib::bibToRefer {args} {
    eval Bib::ToRefer::convertEntries $args
}

namespace eval Bib::ToRefer {

    variable EntryConnect
    variable FieldConnect

    array set EntryConnect {

	"article"       "JOURNAL ARTICLE"
	"book"          "BOOK"
	"booklet"       "BOOK"
	"conference"    "CONFERENCE PROCEEDINGS"
	"inbook"        "BOOK SECTION"
	"incollection"  "BOOK SECTION"
	"inproceedings" "CONFERENCE PROCEEDINGS"
	"manual"        "REPORT"
	"mastersthesis" "THESIS"
	"misc"          "GENERIC"
	"phdthesis"     "THESIS"
	"proceedings"   "EDITED BOOK"
	"techreport"    "REPORT"
	"unpublished"   "REPORT"
    }
    array set FieldConnect {

	"abstract"      "X"
	"address"       "C"
	"annote"        "G"
	"author"        "A"
	"booktitle"     "B"
	"chapter"       "1"
	"citekey"       "F"
	"edition"       "7"
	"editor"        "E"
	"howpublished"  "9"
	"isbn"          "@"
	"issn"          "@"
	"journal"       "J"
	"key"           "K"
	"keywords"      "K"
	"month"         "8"
	"note"          "O"
	"number"        "N"
	"pages"         "P"
	"publisher"     "I"
	"quote"         "1"
	"series"        "S"
	"title"         "T"
	"volume"        "V"
	"year"          "D"
    }
    foreach item [array names FieldConnect] {
	lappend referFields $FieldConnect($item)
    }
    foreach l [list A B C D E F G H I J K L M N O P Q R S T U V W X Y X] {
        if {([lsearch $referFields $l] == -1)} {
            set FieldConnect(customfield$l) $l
        } 
    } 
    for {set n 0} {($n < 10)} {incr n} {
	if {([lsearch $referFields $n] == -1)} {
	    set FieldConnect(customfield$n) $n
	} 
    }
    unset item l n
}

# ===========================================================================
# 
# Conversion of BibTeX to Refer (Endnote compatible)
# 
# If there are several authors, each author has its own tag %A. It might be
# necesseary to run the "Convert LaTeX to Accent" utility first, and
# eventually the "Format All Entries"
# 

proc Bib::ToRefer::convertEntries {} {
    
    global mode
    
    variable latexAccentsInitialized
    
    Bib::listStrings 1

    set bibFile [win::StripCount [win::Current]]
    if {($mode != "Bib")} {
	set p "Select a .bib file to convert"
	while {[win::FindMode $bibFile] != "Bib"} {
	    set bibFile [getfile $p $bibFile]
	    set p "[file tail $bibFile] was not a .bib file -- try again."
	}
	file::openQuietly $bibFile
    } 
    set currentWindow [win::Tail]
    set name "[file rootname [file tail $bibFile]].refer"
    if {[catch {prompt "Name for converted window:" $name} name]} {
        error "cancel"
    } 
    if {[isSelection]} {
	set pos [getPos]
	set end [selEnd]
    } else {
	set pos [minPos]
	set end [maxPos]
    }
    
    # This little dance handles the case that the first entry starts on the
    # first line.
    set hit [Bib::entryLimits $pos]
    if {[pos::compare [lindex $hit 0] == [lindex $hit 1]]} {
	set pos [Bib::nextEntryStart $pos]
	set hit [Bib::entryLimits $pos]
    }
    # Set up the variables for the report.
    set results      ""
    set count        1 
    set errorCount   0
    
    # Loop over all the entries.
    while {[pos::compare $pos < [lindex $hit 1]]} {
	set lastPos $pos
	status::msg "Converting to Refer: $count"
	set pos0 [lindex $hit 0] 
	set pos1 [lindex $hit 1]
	if {![catch {Bib::ToRefer::convertEntry $pos0 } result]} {
	    if {[string length $result]} {
		append results "${result}\r\r"
	        incr count
	    } 
	} else {
	    # There was some sort of error ...
	    incr errorCount
	    append convertResult \
	      "\r[format {%-17s} "line [lindex [pos::toRowChar $pos0] 0]"]"
	    catch {
		append convertResult \
		  ", cite-key \"[lindex [lindex [Bib::getFields $pos0] 1] 1]\""
	    }
	}
	# Go to the next entry.
	set pos [Bib::nextEntryStart $pos0]
	set hit [Bib::getEntry $pos]
	# Aren't we done yet?
	if {[pos::compare $pos == $lastPos]} {
	    break
	}
	# a little insurance ...
	if {[pos::compare $pos1 >= $end]} {
	    break
	}
    }
    if {([expr {[incr count -1] - $errorCount}] <= 0)} {
	status::msg "No entries were converted."
	return
    }
    new -n $name -m "Bib" -text $results
    # Attempt to convert all LaTeX Accents to diacritics.  This requires the 
    # AlphaTcl package "latexAccents"
    selectText [minPos] [maxPos]
    if {![package::active "latexAccents"] && ![info exists latexAccentsInitialized]} {
	catch {TeX::Accents::initialize Bib}
	set latexAccentsInitialized 1
    } 
    catch {TeX::Accents::replace 0}
    goto [minPos]
    if {!$errorCount} {
	status::msg "$count entries converted.  No errors detected."
    } else {
	# We had errors, so we'll return them in a little window.
	status::msg "$count entries converted.  Errors detected …"
	set t    "% -*-Bib-*- (conversion)\r"
	append t "\r  Conversion Results for \"${currentWindow}\"\r\r"
	append t "  Note: Command double-click on any cite-key or line-number\r"
	append t "        to return to its original entry.  If there is no\r"
	append t "        cite-key listed, that is certainly one problem ...\r\r"
	append t "___________________________________________________________\r\r"
	append t "    Converted Entries:  [format {%4d} [expr $count - $errorCount]]\r\r"
	append t "  Unconverted Entries:  [format {%4d} $errorCount]\r"
	append t "___________________________________________________________\r\r"
	append t "  line numbers:  cite-keys:\r"
	append t "  -------------  ----------\r"
	append t $convertResult
	new -n "* Conversion Results *" -m "Bib" -text $t
	goto [minPos]
	winReadOnly
	shrinkHigh
    }
}

# ===========================================================================
# 
# Converts one BibTeX entry to Refer
# 

proc Bib::ToRefer::convertEntry {pos} {
    
    variable EntryConnect
    variable FieldConnect
    
    if {[catch {Bib::getFields $pos 0} fieldLists]} {
	error "Bib::getFields couldn't find any"
    }
    set fields  [string tolower [lindex $fieldLists 0]]
    set values  [lindex $fieldLists 1]
    set type    [string tolower [lindex $values 0]]
    set citekey [lindex $values 1]

    if {($type == "string")} {
        return ""
    } elseif {[info exists EntryConnect($type)]} {
	set type $EntryConnect($type)
    } else {
	set type "GENERIC"
    }
    # "%0" is the entry type
    lappend result "%0 $type"
    
    # "%F" is the entry label = citekey
    lappend result "%F $citekey"
    
    # Now all the other fields
    set count 1
    foreach field [lrange $fields 2 end] {
	incr count
	if  {![string length [set value [lindex $values $count]]]} {
	    continue
	}
	set value [lindex [Bib::isString $value] 1]
	if {[info exists FieldConnect($field)]} {
	    set referField $FieldConnect($field)
	    switch -- $referField {
		"A" - "E" {
		    if {([llength $value] == 1)} {
			# "Protected" author/editor, such as {ABC News}
			set value "[lindex $value 0],"
			lappend result "%$referField [Bib::deTeX $value]"
			continue
		    }
		    # These fields may have several authors/editors etc...
		    regsub -all " and " $value "∞" value
		    foreach v [split $value "∞"] {
			set v [Bib::deTeX [string trim $v]]
			lappend result "%$referField $v"
		    }
		}
		"K" {
		    # Make sure all keywords are separated by ";"
		    set value [join [split $value ","] ";"]
		    lappend result "%$referField [Bib::deTeX $value]"
		}
		default {
		    lappend result "%$referField [Bib::deTeX $value]"
		}
	    }
	    array set foundFields [list $referField 1]
	} else {
	    # If the field doesn't exist, the fieldname and the field
	    # itselfs are saved as "Custom" with tag "%2"
	    set value [Bib::deTeX $value]
	    lappend result "%2 $field == ${value}"
	}
    }
    # Is this really an edited book?  (Book with editor and no author.)  If
    # so, change the type, and put the editor name(s) in the "author" field.
    if {($type eq "BOOK") \
      && ![info exists foundFields(A)] \
      && [info exists foundFields(E)]} {
        set result [lreplace $result 0 0 "%0 EDITED BOOK"]
	for {set idx 2} {($idx < [llength $result])} {incr idx} {
	    set oldField [lindex $result $idx]
	    if {([string range $oldField 0 1] eq "%E")} {
	        set newField "%A [string range $oldField 3 end]"
		set result [lreplace $result $idx $idx $newField]
	    } 
	}
    } 
    return [join $result "\r"]
}

# ===========================================================================
# 
# .