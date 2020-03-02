## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "bibConvert.tcl"
 #                                          created: 08/06/1995 {04:23:31 PM}
 #                                      last update: 03/21/2006 {01:59:35 PM}
 # Description:
 #
 # proc bibConvert {}
 #
 # Parses various records into BibTeX entries.  It now copes with HOLLIS
 # records, the horrible form of inspec record our FirstSearch interface
 # gives us, and some nicer forms of inspec record produced by other
 # interfaces.  Plus ISI, MARC, OCLC, OVID, Refer, ...
 #
 # See the 'help' argument in the package declaration below for more
 # information about the different formats handled.
 # 
 # The clever bits include:
 #
 # (1) Automatically try and extract an author surname, concatenate it with
 #     the year and use it as the bibtex citation label.
 # (2) Replace '\' in author lists by 'and' (hollis)
 # (3) Replace ';' in author lists by 'and' (inspec)
 # (4) Uses 'Alpha' family of editors for some user interactions
 # (5) Automatic bib type recognition via file extensions
 # (6) Can automatically convert an Alpha window, and integrate with the
 #     BibTeX mode.
 # (7) Will extract and separate journal entries containing name, vol.,
 #     number and pages together.
 # (8) Plus lots more clever stuff now ...
 #
 # If you're interested in self-organisation, complex systems and stuff
 # like that, check out the follwing URL for some bibliographies which are
 # the results of this code: <http://www.santafe.edu/~vince/>
 #
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #
 # --------------------------------------------------------------------------
 #
 # Copyright (c) 1995-2006  Vince Darley, Craig Barton Upright
 # All rights reserved
 #
 # You may freely copy and modify this code provided this copyright notice
 # remains intact.  I will maintain and add to it over time, and will
 # accomodate your improvements if you send them to me.
 #
 # Please send any improvements: <mailto:vince@santafe.edu>
 #
 # --------------------------------------------------------------------------
 #
 # Usage:
 #
 # Must be sourced into a Tcl interpreter, e.g.:
 #
 #   >tclsh
 #   % source bibAdditions.tcl
 #   % source bibConvert.tcl
 #   % bibConvert myfile.marc
 #   % bibConvert otherfile.marc
 #   % exit
 #   > more myfile.bib
 #   > ...
 #
 # Simple usage:
 #
 #   'bibConvert foo'
 #
 # will look for files "foo.<suffix>", where "<suffix>" is any one of
 # 
 #   inspec insp hollis hol isi marc ovid oclc refer
 # 
 # If one exists, the appropriate conversion will take place, and the
 # converted bibliography saved in file "foo.bib".
 #
 # If the output file exists it will be overwritten.
 #
 # Detailed usage:
 #
 #   bibConvert input-file [output-file] [<type>]
 #   
 # where "<type>" is any one of
 # 
 #   inspec hollis isi marc ovid oclc refer
 #
 # Allows the output file and the format to be specified explicitly.  If
 # the output file exists it will be overwritten.
 #
 # Usage via a shell script:
 #
 # Remove the leading '#' on each of the seven lines below and put the rest
 # into a script file 'bibConvert'
 #
 # ---------------bibConvert---------------cut here ---------
 # #!/bin/sh
 # # the next line restarts using tclsh, as long as it's in the path \
 # exec tclsh7.6 "$0" "$@"
 #
 # source ~/bin/bibAdditions.tcl
 # source ~/bin/bibConvert.tcl
 # eval bibConvert $argv
 # --------------------------------------- cut here ---------
 #
 # Usage under the editor 'Alpha':
 #
 # You may have got this file as part of "Vince's Additions", a set of Tcl
 # files which I've built up to personalise Alpha for various purposes.
 # Use the readme to install this package for Alpha.  Most of the code in
 # "Vince Additions" is now included in AlphaTcl, distributed with Alpha.
 #
 # Activating this package inserts a "Convert To Bib" menu item in the
 # "Bibtex Conversions" submenu of the BibTeX menu.  Open a '.hollis' or
 # '.inspec' file and Alpha automatically switches to bibtex mode.  Select
 # the menu item 'Bibtex Conversions > Convert To Bib' and Alpha converts
 # the open window (or any highlighted selection), saving it in a new file
 # (with extension '.bib'), which it then opens for you to examine!  The
 # results can be optionally be placed in the current window.  See the
 # 'help' argument in the package declaration below for more details.
 #
 # --------------------------------------------------------------------------
 #
 # Personalisation:
 #
 # There are a few variables whose values you can modify to tailor the
 # output to your personal needs.  See the 'bibConvert::setBibConvertVars'
 # proc below for details.
 #
 # If using this package from within Alpha, most of these settings are set
 # or changed either via the 'Bib Mode Prefs' dialog or the dialog which
 # appears whenever the menu item is called, so there should be no need to
 # mess with anything in here.
 #
 # --------------------------------------------------------------------------
 #
 # Notes:
 #
 # All procedures variables begin with 'bibConvert::' except the main one,
 # which is called 'bibConvert'.  Most variables set and used throughout
 # the parsing are saved in a 'bibConvertVars' array.
 # 
 # See the section below for 'Adding New Types' to find out how to add
 # additional bibliography conversion formats.
 #
 # One style of record separation that this code is not perfectly set up to
 # deal with is simply empty lines !!  There is an easy workaround, see the
 # switches for 'Refer' in the procs 'bibConvert::find_record_start',
 # 'bibConvert::not_at_record_end', and 'bibConvert::not_new_field'.
 #
 # --------------------------------------------------------------------------
 #
 # To Do:
 #
 # Better handling of record types: currently all hollis records are 'book'
 # and inspec records are 'article' or 'inproceedings'
 #
 # Add ability to append to a given bibliography.
 #
 # --------------------------------------------------------------------------
 #
 # History:
 #
 # modified by  rev reason
 # -------- --- --- -----------
 # May95    VMD 0.1  original, hollis->bibtex converter
 # May95    VMD 0.2  added rudimentary inspec support
 # May95    VMD 0.3  code more robust, and handles inspec well
 # May95    VMD 0.4  looks at command line extensions to determine
 #                   bib type.
 # May95    VMD 0.5  Will convert windows of the Alpha editor
 # May95    VMD 0.6  Integrates with bibtex mode under Alpha
 # May95    VMD 0.7  Now dependent upon some utility code in
 #                   'bibAdditions.tcl'
 # May95    VMD 0.8  Tries to generate correct record type, and
 #                   splits journal entries into pieces.
 # Jun95    VMD 0.9  Handles a new inspec format plus few extras
 # Aug96    VMD 0.91 More formats
 # 5/3/97   VMD 1.0  Prettier output, more user control over format
 # 6/5/97   VMD 1.01 Fixed two minor bugs
 # 17/2/98  VMD 1.05 Various improvements and new inspec type
 # 4/16/98  JEG 1.06 Added ISI conversion
 # 16/4/98  VMD 1.07 Modernised a few things.
 # 21/2/99  fp  1.12 Added OVID support
 # 08/03/02 cbu 2.0  Added 'Refer' support.  Reorganized procs to make
 #                   it easier to see how to add new bibTypes.  More
 #                   Bib mode prefs are used if available.  User interface
 #                   dialog allows results to be inserted with many options.
 #                   User control over some formatting settings.
 #                   Updated 'OVID' for newer format, subtype 'webspirs5"
 #                   Updated 'ISI' for newer format.  Previously broken.
 #                   Added auto-capitalize strings for titles, journals, etc.
 #                   Added 'MARC' support.
 # 08/20/03 cbu 2.0.2 Better "Bib To Refer ; Refer To Bib" parsing.
 #
 # ==========================================================================
 ##

# Make sure that we can use this at all.
if {[info tclversion] < 7.4} {
    puts "Tcl version 7.4 or higher is required for this code."
    return
} 

# Just so we can use this file without Alpha.
if {[info commands namespace] == ""} {
    # So we can use this file with Tcl 7.4
    ;proc namespace {args} {}
}
namespace eval alpha {}
if {[info commands alpha::feature] == ""} {proc alpha::feature {args} {}}

proc bibConvert.tcl {} {}

# Alpha feature declaration.
alpha::feature bibConvert 2.0.2 "Bib" {
    # Initialization script.
    alpha::package require -loose Bib 3.6b1
} {
    # Activation script.
    menu::insert bibtexConversions items end "convertToBibÉ"
    # Conflict with emacs binding -- probably should pick a new binding.
    Bind 'b' <z> bibConvert Bib
} {
    # Deactivation script.
    menu::uninsert bibtexConversions "convertToBibÉ"
    unBind 'b' <z> bibConvert Bib
} uninstall {
    this-directory
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Converts several different bibliography formats to BibTeX entries
} help {
    "# Introduction"
    "# Bibliography Formats Handled"
    "#   HOLLIS"
    "#   ISI"
    "#   MARC"
    "#   OCLC"
    "#   Ovid"
    "#   Refer"
    "#   Inspec"
    "# Package Preferences"


	  	Introduction

    This package contains two files which convert several different
    bibliography format to BibTeX entries.  Activating this package will
    insert a 'Convert To Bib' item in the "BibTeX > BibTeX Conversions" menu.
    This item will be applied to any currently highlighted selection, or if
    there is no selection then to the contents of the entire window.
    Conversion results can then be inserted in the current window or placed in
    a new window for saving, editing, etc.
    
    Preferences: Mode-Features-Bib
    
    This package was initially written when bibliographic searches took place
    primarily in telnet sessions, with the results saved by a file capture.
    You could then convert these files to BibTeX format.  With the advent of
    the World Wide Web, most of these searches take place on-line, and you can
    have the results (i.e. marked records) e-mailed to you.  These e-mails can
    then be saved as files, or the contents can be cut and pasted into new
    Alpha windows.
    
    This package is a default feature of the 'Bib' mode, and any files with
    the following suffixes
    
	.hollis .hol .inspec .isi .marc .oclc .ovid .refer

    will automatically open in Bib mode so the menu item will be present.  If
    you have a window that is not in Bib mode, you can easily change it using
    the 'Modes' pop-up menu to the right of the status bar window.  If you
    want this feature to be available globally, i.e. no matter what the mode
    of the current is, then you must make both the BibTeX menu AND this
    package global -- see the "Config > Preferences" dialogs.

	"bibConvert.tcl"

    This file contains the core code which converts entries obtained from
    various commercial (subscription based) or academic bibliographic
    databases and converts them to BibTeX format.  The main formats include:
    
	HOLLIS   (Harvard Online Library Information System)
	ISI      (Institute of Scientific Information)
	             aka "Web Of Science", "Web Of Knowledge"
	MARC     (MAchine Readable Cataloging record)
	OCLC     (Online Collection of Library Catalogs)
	             aka "First Search", "WorldCat"
	Ovid     (WebSPIRS)
	Refer    (EndNote compatible)

    There is also a miscellaneous 'Inspec' format, see "# Inspec" below.

    Example files are included below -- simply click on the hyperlink and a
    new window will be opened that you can convert to .bib format.

	"bibAdditions.tcl"

    This file contains various common utility functions utilised by the rest
    of the code; also allows 'bibConvert' to work under a general Tcl
    interpreter (e.g. under Unix tclsh).


	  	Bibliography Formats Handled:

    Please note that like all things web-related, the formats used in the
    results returned by various database programs is subject to change, and
    the software developers rarely inform AlphaTcl developers of the new
    formats.  (What nerve!)  If you find that any of the conversions below do
    not work, or if you have a suggestion for improving the conversion
    results, please file a bug report in Bugzilla (see the help file on "Bug
    Reports and Debugging") or send a note to any of the AlphaTcl mailling
    lists (see the help file "Readme" for more information.)

    If you have an entirely different format that needs to be converted,
    please describe it on one of the AlphaTcl mailing lists to see if it can
    be added.
    
    Please remember that none of these conversions comes with a guarantee, and
    all results should be checked before discarding the original records that
    generated the new ones.  In particular, entry 'types' are very difficult
    to determine, and collection editors will often be listed as authors
    instead.  The "Accents To LaTeX" filter (in the package: filtersMenu)
    should also be used to ensure that special characters are properly
    converted after the new record entries have been inserted.


	  	 	HOLLIS

    "Hollis-Example.hollis"
    
    This is the Harvard Online Library Information System format, available at
    <http://www.harvard.edu>

    The basic idea is that records are outlined by "%START:" and "%END:" tags,
    each field label is of the form "%FIELDNAME:" so we can easily separate
    things out.
    
    In the summer of 2002, Harvard unveiled a new version of HOLLIS which is
    available by web only (i.e. not by telnet), and records are no longer
    returned in the format supported here (preserved in the example hyperlink
    above).  Kind of sad, especially when you know that these two features
    were the original inspiration for this package!  (HOLLIS now gives you the
    option to have records sent to you by e-mail using the "# MARC" format
    described below.
    
    Original by Vince <vince@santafe.edu>
    Updated by Craig  <cupright@alumni.princeton.edu>


	  	 	ISI
		
    "ISI-Example.isi"

    'ISI' (Institute of Scientific Information; Science Citation Index) is a
    commercial citation database service, also known on the web as the 'Web Of
    Science' or the 'Web Of Knowledge'.  <http://www.webofscience.com>

    The basic idea is that records are outlined by "PT" and "ER" tags, each
    field label is of the form "<FF> " so we can easily separate things out.

    Original by Jon  <jguyer@his.com>
    Updated by Craig <cupright@alumni.princeton.edu>


	  	 	MARC

    "MARC-Example.marc"
    
    'MARC' is a MAchine Readable Cataloging record format used by the U.S.
    Library of Congress.
    
	The Library of Congress serves as the official depository of United
	States publications and is a primary source of cataloging records for
	US and international publications.  When the Library of Congress began
	to use computers in the 1960s, it devised the LC MARC format, a system
	of using brief numbers, letters, and symbols within the cataloging
	record itself to mark different types of information.  The original LC
	MARC format evolved into MARC 21 and has become the standard used by
	most library computer programs.  The MARC 21 bibliographic format, as
	well as all official MARC 21 documentation, is maintained by the
	Library of Congress.  It is published as "MARC 21 Format for
	Bibliographic Data."
	
                                        <http://lcweb.loc.gov/marc/umb>

    Most libraries retain their records in MARC format, and manipulate these
    fields to present catalog record information in their own peculiar format
    (which other modules in this package are attempting to convert!)
    
    Some offer the option to return marked records in 'MARC' format, which we
    are then able to very easily convert here.  Of course, while the MARC
    record headings and subheadings are standard, the format in which they are
    given is not, especially with regard to column length and spacing.  The
    'MARC' conversion is (hopefully) flexible enough to deal with several
    different variations.  The key field here to confirm that we're dealing
    with a MARC entry is '008', which is meaningless to us but supposedly
    every record has to have one.
    
    Contributed by Craig <cupright@alumni.princeton.edu>


	  	 	OCLC

    "OCLC-Example.oclc"
    
    OCLC (also known as FirstSearch) is a commercial, subscription based
    bibliographic database, <http://www.oclc.org>.  Be sure to have marked
    records e-mailed using the 'detailed' format, otherwise the conversion
    will fail.  (OCLC certainly uses the 'MARC' format to maintain its
    records, it's too bad that they don't give you that format option for
    saving/e-mailing the results.)
    
    Original by Vince <vince@santafe.edu>
    Updated by Craig  <cupright@alumni.princeton.edu>


	  	 	Ovid

    "Ovid-Example.ovid"

    'Ovid' is a commercial subscription based database service that is also
    known by the name 'WebSPIRS' <http://www.ovid.com>.  Often you're using an
    Ovid database product (such as 'SocioFile') without even realizing it.
    Many of their products are accessed via a 'SilverPlatter' website.
    
    Both long and short labels can be used for conversions.

    IMPORTANT:  When converting individual entries, make sure that the

	Record 1 of 45
	
    is included in the highlighted selection -- this is the only way that we
    know that we're using the newer interface output for ovid, and that the
    following text is a valid entry.  Also, be sure to include either short or
    long labels when obtaining the records (this code handles both styles),
    but if 'both' or 'none' are used the conversion will fail.


    Original by flip <flip@skidmore.edu>
    Updated by Craig <cupright@alumni.princeton.edu> to use the format currently
    returned ('WebSPIRS5', released summer 2002)


	  	 	Refer

    "Refer-Example.refer"

    EndNote compatible.  EndNote is a product of ISI ResearchSoft, a division
    of the same Thomson/ISI conglomerate that brings us all of the great sites
    for the "Web of Science/Knowledge/Whatever".
  
    One significant difference between EndNote and Refer is that the former
    always includes a '%0' tag indicating what type of item we're dealing
    with.  If this field is not present, the type is 'misc'.  All records must
    be separated by at least one empty line.

    Contributed by Craig <cupright@alumni.princeton.edu>.
    
    
	  	 	Inspec
		
    The original basic 'inspec' format was a file capture of horrible telnet
    interface results of 'FirstSearch' output.
    
    It's a bit harder here, and we have to remove a lot of garbage, however,
    we basically only accept lines beginning with '|', and parse the record
    names appropriately.  This has since been recategorized as "OCLC", and is
    handled above.  This older version has not been tested with the newer
    version of this package, i.e. this earlier format might now be obsolete.
    
    In this package, 'Inspec' now refers to a 'miscellaneous' category of
    bibliographic formats.  If the chosen format is 'inspec', 'Convert To Bib'
    attempts to determine which of the following should be used.  Most of
    these, however, have not been tested with the newer version of this
    package.
    
    'Inspec' formats generally follow this pattern:
    
	FIELDNAME1 FIELDCODE1: FIELDENTRY1
	.
	.
	.
	FIELDNAME5 FIELDCODE5: FIELDENTRY5
    
    There are other variations of inspec formats available (each of which
    needs some more documentation on where it comes from ...)  The trick in
    each case is to figure out where a record starts and stops.
    
    (Technical note: In theory, it would be possible to convert all library
    results back into MARC first, and then decipher it, although that would be
    something of a chore ...  After you take a look at several different
    library record (i.e. 'inspec') formats, you start to see how they're using
    the MARC record fields.)
    
    All originals by Vince <vince@santafe.edu>

	Inspec2

    This is much easier: each record starts with 'Document N' and ends with a
    long line of dashes.

	Inspec

    This is much easier: each record starts with 'Citation N'.  Now copes with
    two variants of this record type (Aug'96)

	Inspec4

    This is much easier: each record starts with ' Doc Type:'.

	Inspec5

    I've forgotten what this one looks like (Record No.  or so)

	Inspec6

    Something from Berkeley: 'N. (Inspec Result)'

	Inspec7

    These are for inspec files started with <N>, and each article with an
    accession number


	  	Package Preferences

    Many of the 'Bib' mode preferences ("Entry Braces", "Align Equals", etc.)
    are respected when converting entries.  There are some additional
    preferences in the second and subsequent pages of the conversion dialog
    that can also be set to fine-tune the style of the formatted entries, such
    as where 'abstract' or 'table of contents' fields should be mapped in
    BibTeX entries, and which fields should be completely ignored.  These
    prefs are saved between editing sessions.
}

# Make sure we've got my code loaded
if {[catch {bibAdditions.tcl}]} {
    puts "You must first source 'bibAdditions.tcl'"
    return
}

namespace eval Bib {}

proc Bib::convertToBib {args} {eval bibConvert $args}

# ×××× Adding New Types ×××× #

# To add new types for converting to .bib format, follow these steps.  These
# apply for 'subtypes' as well, which are useful when a broader category has
# been updated in a significant way and we're able to distinguish newer from
# older versions.
#
# Note that during any part of the process you can save information in the
# 'bibConvertVars' array for accessing later, but it's your responsibility
# to clean up after yourself if necessary, e.g. reset the variable when
# you're done using it else it will be available for each recursion with
# the old value still in place.

# (0 - REQUIRED) Add the type to the bibConvert::types list below, as well
# as any file extensions associated with the type.  If you need to perform
# additional tests to confirm the format (sub)type, add a switch in the
# proc 'bibConvert::confirm_type'.  This is necessary if the format
# parameters change due to upgrades or the method by which the user is
# obtaining the citations, as is the case with 'inspec'.  This switch will
# also allow your format to be recognized even if the user chose the wrong
# initial format.
#
# (1 - REQUIRED) Define 'field maps' so that fields which appear in the
# entry can be properly translated to a BibTeX field.  Note that all
# initial format fields found while scanning will be converted to UPPER
# CASE, and any spaces will be replaced by a single '_'.  Note that any
# mapped field names that are still UPPER_CASE will be automatically
# deleted at the end of the reformatting process, so this can be a useful
# way to keep track of temporary fields.
#
# (2 - REQUIRED) Define a method for determining the start of a new entry
# by adding a switch item in 'bibConvert::find_record_start'.  This is
# required.  Note that the line which contains the start of the entry will
# not be scanned for field information, so if there's something important
# in there you'll have to save it as an element in the bibConvertVars array
# for later use.  See the 'refer' switch for an example, and step (8)
# described below regarding reformatting fields and values.
#
# (3 - REQUIRED) Define a method for determining that the current entry is
# ending by adding an entry in the 'bibConvert::not_at_record_end' switch. 
# This might be the same rule as above, i.e. the only way to know that an
# entry is ending is that another is beginning.
#
# (4 - optional) Define a method for determining that the current line is
# garbage and should be ignored if the file is likely to have such lines,
# by adding an entry for the switch in 'bibConvert::throw_away'.
#
# (5 - optional) Define a method for determining that the value for the
# current field is not continuing into the next line by adding an entry to
# the switch in the proc 'bibConvert::not_new_field'.  If none is given,
# then we assume that any line that begins with whitespace is continuing
# the previous field.
#
# (6 - optional) Define a method for determining that a line should be
# appended to a field's text value by adding a switch in the proc
# 'bibConvert::append_field_text' You'll have to look at the code closer to
# see how this differs from (5).
#
# (7 - REQUIRED) Define a method for parsing out the line's field name
# (which will be mapped to BibTeX fields using the mappings defined in (1)
# described above) as well as the text value for that field by adding an
# entry in the switch in 'bibConvert::extract_field_info'.  You'll have a
# chance to manipulate the field text later in the next step, in the proc
# 'bibConvert::reformat_records'.
#
# (8 - optional, but usually necessary) Once the record has been scanned,
# all of the field names are converted and the field values are stored in
# an array.  Before these are nicely indented etc and added to the new
# file, you have a last chance to manipulate the fields and values in
# 'bibConvert::reformat_records', i.e. if one field includes all of volume,
# number and pages you can parse these into three different fields.  This
# proc will return the name of the entry type that will be used -- the
# default entry type is 'misc' so it's a good idea to go to a little
# trouble to find something more appropriate.  And please go to a little
# effort to clean up the 'author' field so that the names can be parsed out
# to use in the citekey tag.
#
# If you want to create a custom citekey tag using some other method
# (which, in order to maintain consistency, isn't recommended) do so in
# this step by creating a 'citekey' array item for the record.
#

# ×××× Setting Default Types ×××× #

namespace eval bibConvert {}

# The file extensions we recognise, mapped to 'types'
set bibConvert::extensions(insp)   inspec
set bibConvert::extensions(inspec) inspec
set bibConvert::extensions(hol)    hollis
set bibConvert::extensions(hollis) hollis
set bibConvert::extensions(isi)    isi
set bibConvert::extensions(marc)   marc
set bibConvert::extensions(oclc)   oclc
set bibConvert::extensions(ovid)   ovid
set bibConvert::extensions(refer)  refer
# The types that we recognize
set bibConvert::types [list hollis inspec isi marc oclc ovid refer]

# ×××× -------- ×××× #

proc bibConvert {{fileIn ""} {fileOut "default"} {bibType "unknown"}} {

    global vince_usingAlpha bibConvertVars bibConvert::types

    # (re)set all bibconversion variables.
    bibConvert::setBibConvertVars

    # Make sure that we have files in and out.
    if {$fileIn == ""} {
	set fileIn [vince_getFile "Please select a bibliography to convert" edit]
    }

    # Parse the arguments
    set types [set bibConvert::types]
    if {$bibType == "unknown" || [lsearch -exact $types $bibType] == -1} {
	set bibType ""
    }

    set f [vince_parseFileNames $fileIn "bib" $types $fileOut bibConvert::extensions]

    set bibConvertVars(fileIn)  [lindex $f 0]
    set bibConvertVars(fileOut) [lindex $f 1]
    set bibConvertVars(bibType) [lindex $f 2]

    # Everything below assumes that 'fileIn' fileOut' and 'bibType' are now
    # an element in the 'bibConvertVars' array.  We'll add the channel id's
    # to this array soon as well.

    # This will change some of the settings according to user's tastes if
    # we're using this in Alpha, including the 'fileIn' and 'fileOut' vars.
    bibConvert::start_dialog

    # Make sure that we're dealing with a valid type.
    set bibType $bibConvertVars(bibType)
    if {[lsearch $types $bibConvertVars(bibType)] == "-1"} {
	set p "Please select a bibliography type to read from:"
	if {$vince_usingAlpha} {
	    # Pick one from a list.  Remember the selection in case it
	    # comes up again, i.e. the user is repeatedly converting
	    # individual entries in a window.
	    set L $bibConvertVars(lastBibType)
	    set bibType [listpick -p $p -L $L $types]
	} else {
	    puts $p
	    gets stdin bibType
	}
    }
    set bibConvertVars(bibType)     $bibType
    set bibConvertVars(lastBibType) $bibType

    set fileIn  $bibConvertVars(fileIn)
    set fileOut $bibConvertVars(fileOut)
    set bibType $bibConvertVars(bibType)

    if {$bibType == "-1"} {
	vince_message "Couldn't identify the format type of the source file."
	return
    }
    set bibConvertVars(fileInId) [vince_open $fileIn]

    # Make sure it's the correct type / subtype.
    if {[bibConvert::confirm_type 0] == ""} {
	if {[bibConvert::confirm_type 1] == ""} {
	    vince_message "Could not identify the original format" 1
	    return
	}
    } 
    if {[file exists $fileOut]} {
	set q "File '$fileOut' exists. Do you want to overwrite it?"
	if {[vince_askyesno $q] != "yes"} {
	    close $bibConvertVars(fileInId)
	    vince_message "bibliography conversion cancelled"
	    return
	} else {
	    file delete $fileOut
	}
    }

    # Open the channel id.
    set bibConvertVars(fileOutId) [vince_open $fileOut w]

    # And then recursively parse the 'in' file.
    set bibConvertVars(recordCount) 0
    while {![eof $bibConvertVars(fileInId)]} {
	bibConvert::read_record
    }

    # Close all channel ids
    close $bibConvertVars(fileInId)
    close $bibConvertVars(fileOutId)

    # Final action with the converted out file.
    bibConvert::insert_results
}

# Setting up bibConvert variables, storing them in a 'bibConvert' array.
# This is called every time a file is converted, to ensure that we have
# up-to-date variables.

proc bibConvert::setBibConvertVars {} {

    global bibConvertVars BibmodeVars bibConvert::last_item Bib::Fields

    set bibConvert::last_item ""

    # Make sure that the bibType element is empty.
    set bibConvertVars(bibType) ""
    # We remember the last bibType for defaults in dialogs.
    if {![info exists bibConvertVars(lastBibType)]} {
	set bibConvertVars(lastBibType) "hollis"
    }
    if {![llength [array names bibConvertVars]]} {
	# First time running this.
	catch {loadAMode Bib}
    }
    
    # This next set will only be changed if 'bibConvert' is called from
    # Alpha, when the 'Bib' mode preferences will be used.  If called from
    # any other Tcl interpreter, you must change the values here.
    
    # String for indenting fields in an entry.
    if {![info exists BibmodeVars(indentString)]} {
	# Change this to set the initial indent for fields.
	set bibConvertVars(bibIndent) "   "
    } else {
	set bibConvertVars(bibIndent) $BibmodeVars(indentString)
    }
    # Maximum line width for filling text in fields.  This value will be be
    # decreased by any field and pad lengths.
    if {![info exists BibmodeVars(maxLineLength)]} {
	# Change this to set the maximum lengths for lines in a file.
	set bibConvertVars(maxLineLength) 78
    } else {
	set bibConvertVars(maxLineLength) $BibmodeVars(maxLineLength)
    }
    set bibConvertVars(fillColumn) 78
    # Character to use to surround entries.
    if {![info exists BibmodeVars(entryBraces)] || $BibmodeVars(entryBraces)} {
	# Change this to set the open, close tags for entries.
	set bibConvertVars(openEntry)  "\{"
	set bibConvertVars(closeEntry) "\}"
    } else {
	set bibConvertVars(openEntry)  "\("
	set bibConvertVars(closeEntry) "\)"
    }
    # Character to use to surround text in fields.
    if {![info exists BibmodeVars(fieldBraces)] || $BibmodeVars(fieldBraces)} {
	# Change this to set the open, close tags for fields.
	set bibConvertVars(openItem)   "\{"
	set bibConvertVars(closeItem)  "\}"
    } else {
	set bibConvertVars(openItem)   "\""
	set bibConvertVars(closeItem)  "\""
    }
    # Align equal signs in fields?
    if {![info exists BibmodeVars(alignEquals)]} {
	# Change this to set the aligning of equals signs within an entry.
	set bibConvertVars(alignEquals) 0
    } else {
	set bibConvertVars(alignEquals) $BibmodeVars(alignEquals)
    }

    # The rest of these will only be changed if 'bibConvert' is called from
    # Alpha, when they're presented in a dialog -- If called from any other
    # Tcl interpreter, you have to change the values here.
    
    # Used to determine the author style for citekey tags.  See the proc
    # 'bibConvert::parse_author' below for more options.
    if {![info exists bibConvertVars(authorTag)]} {
	set bibConvertVars(authorTag) "First Author's Surname"
    }
    # Used to determine the year style for citekey tags.  Options include
    # "0" or "1"
    if {![info exists bibConvertVars(truncateYear)]} {
	set bibConvertVars(truncateYear) "1"
    }
    # Used to determine which fields should be excluded.
    if {![info exists bibConvertVars(excludeFields)]} {
	set bibConvertVars(excludeFields) [list]
    }
    # These strings will always be forced to lower case in the appropriate
    # fields, called by 'bibConvert::capitalize_string'.  We use the Bib
    # mode pref if available.
    if {[info exists BibmodeVars(autoCapForceLower)]} {
	set bibConvertVars(forceLower) $BibmodeVars(autoCapForceLower)
    } elseif {![info exists bibConvertVars(forceLower)]} {
	set bibConvertVars(forceLower) [list \
	  "a" "an" "and" "by" "for" "in" "into" "of" "on" "or" "the" "to"]
    }
    # These special regexp patterns will also be converted during the
    # capitalization process.  We use the Bib mode pref if available.
    if {[info exists BibmodeVars(autoCapSpecialPatterns)]} {
	set bibConvertVars(specialPatterns) $BibmodeVars(autoCapSpecialPatterns)
    } elseif {![info exists bibConvertVars(specialPatterns)]} {
	set bibConvertVars(specialPatterns) [list \
	  {^usa$ \{USA\}} {^dimaggio DiMaggio} {m(a?)cC M\\1cC} \
	  {m(a?)cd M\\1cD} {m(a?)cw M\\1cW}]
    }
    # Any non-standard field can be remapped using these prefs.  Just make
    # sure that the option includes the redirection field in single quotes.

    # 'abstract' fields.
    if {![info exists bibConvertVars(abstractRemap)]} {
	set bibConvertVars(abstractRemap) "Included in 'annote' field"
    }
    # Table of 'contents' fields.
    if {![info exists bibConvertVars(contentsRemap)]} {
	set bibConvertVars(contentsRemap) "Included in 'annote' field"
    }
}

# MODIFY BELOW AT YOUR OWN RISK.

# Called by the main bibConvert function.  Remaps 'type' if necessary,
# allows us to have different formats grouped into broader categories.

proc bibConvert::confirm_type {{scanAllTypes "0"}} {

    global bibConvertVars bibConvert::types
    
    if {$scanAllTypes} {
	# If we're here, the initial type failed to register, so we're
	# going to check all types as a last ditch effort.  'inspec' will
	# get checked last.
	set types [set bibConvert::types]
	set idx   [lsearch $types "inspec"]
	set types [concat [lreplace $types $idx $idx] "inspec"]
	foreach type $types {
	    set bibConvertVars(bibType) $type
	    if {[bibConvert::confirm_type 0] != ""} {
		return $bibConvertVars(bibType)
	    } 
	}
    } 
    set fileInId $bibConvertVars(fileInId)
    set confirmType ""

    switch -- [set bibType $bibConvertVars(bibType)] {
	"hollis" {
	    while {![eof $fileInId]} {
		gets $fileInId rline
		if {[regexp {^%[A-Z]} $rline]} {
		    set confirmType "hollis"
		    break
		}
	    }
	}
	"inspec" {
	    while {![eof $fileInId]} {
		gets $fileInId rline
		if {[string range $rline 0 14] == "|   RECORD NO.:"} {
		    # Redirect this type to oclc1, though this is probably
		    # obsolete now.
		    set confirmType "oclc1"
		    break
		} elseif  {[string range $rline 0 7] == "Document"} {
		    set confirmType "inspec2"
		    break
		} elseif  {[string range $rline 0 7] == "Document"} {
		    set confirmType "inspec2"
		    break
		} elseif  {[string range $rline 0 7] == "Citation"} {
		    set confirmType "inspec3"
		    break
		} elseif  {[string range $rline 0 8] == " Doc Type"} {
		    set confirmType "inspec4"
		    break
		} elseif  {[string range $rline 0 13] == "   RECORD NO.:"} {
		    set confirmType "inspec5"
		    break
		} elseif  {[string range $rline 0 20] == "           COPYRIGHT:"} {
		    set confirmType "inspec5"
		    break
		} elseif  {[string range $rline 0 17] == "1. (INSPEC result)"} {
		    set confirmType "inspec6"
		    break
		} elseif  {[regexp {^<[0-9]+>} $rline]} {
		    set confirmType "inspec7"
		    break
		} elseif  {[regexp {^Accession No:   OCLC:} $rline]} {
		    set confirmType "oclc"
		    break
		}
	    }
	    if {$confirmType == ""} {
		vince_message "Sorry I don't recognise this inspec format. Please contact <vince@santafe.edu>"
	    }
	}
	"isi" {
	    while {![eof $fileInId]} {
		gets $fileInId rline
		if {[regexp {^AU } $rline]} {
		    set confirmType "isi"
		    break
		}
	    }
	}
	"marc" {
	    while {![eof $fileInId]} {
		gets $fileInId rline
		# The 'pad' will be used later to figure out where the
		# fields are located.  The entry field will be used to
		# determine when entries start and stop -- I think that all
		# records are required to have '008', although if we have
		# 'FMT' then we're closer to the true start of the record,
		# and have a chance to figure out the entry type later.
		# The 'marcFieldIdx' variables will be used to determine
		# when the actual field text starts.
		foreach field [list "FMT" "LDR" "008"] {
		    set pat "^( *)${field}( +)\[^ \]"
		    if {[regexp $pat $rline allofit pad1 pad2]} {
			set confirmType "marc21"
			set bibConvertVars(marcEntryField) $field
			set bibConvertVars(marcFieldPad)   $pad1
			# These are the column positions for field name, text.
			set idx1 [string length $pad1]
			set idx2 [expr {$idx1 + 2}]
			set idx3 [expr {$idx2 + 1 + [string length $pad2]}]
			set bibConvertVars(marcFieldIdx1) $idx1
			set bibConvertVars(marcFieldIdx2) $idx2
			set bibConvertVars(marcFieldIdx3) $idx3
			break
		    }
		}
		if {$confirmType != ""} {break}
	    }
	}
	"oclc" {
	    while {![eof $fileInId]} {
		gets $fileInId rline
		if {[string range $rline 0 14] == "|   RECORD NO.:"} {
		    set confirmType "oclc1"
		} elseif {[regexp {^Accession No:   OCLC:} $rline]} {
		    set confirmType "oclc2"
		    break
		}
	    }
	    if {$confirmType == ""} {
		vince_message "Sorry I don't recognise this oclc format. Please contact vince@santafe.edu"
	    }
	}
	"ovid" {
	    # Peel this off
	    gets $fileInId rline
	    if  {[regexp {^<[0-9]+>} $rline]} {
		set confirmType "ovid1"
	    } else {
		while {![eof $fileInId]} {
		    if {[regexp {^Record [0-9]+ of [0-9]+} $rline]} {
			set confirmType "webspirs5"
			break
		    }
		    gets $fileInId rline
		}
	    }
	    if {$confirmType == ""} {
	        # We didn't figure anything out.
		vince_message "Sorry, I don't recognise this ovid format."
	    }
	}
	"refer" {
	    # We need this later.
	    set bibConvertVars(referRecordEnd) 0
	    while {![eof $fileInId]} {
		gets $fileInId rline
		if {[regexp {^%[A-Z]} $rline]} {
		    set confirmType "refer"
		    break
		}
	    }
	}
	default {
	    set confirmType $bibConvertVars(bibType)
	}
    }
    # Make sure that we reset the scanning to the top of the file.
    seek $fileInId 0 start
    set bibConvertVars(bibType) $confirmType
}

# The main procedure which grabs a whole bibtex record, reformats it, and
# writes it to the end of the output file.  Called recursively.

proc bibConvert::read_record {} {

    global bibConvertVars

    set fileInId  $bibConvertVars(fileInId)
    set fileOutId $bibConvertVars(fileOutId)

    global bibConvert::last_item bibConvertVars

    set rline [bibConvert::find_record_start ${bibConvert::last_item}]
    if {$rline == 0} {return}
    catch {unset new_record}
    vince_message "converting: [incr bibConvertVars(recordCount)]"

    # Reading the entry.
    while {[bibConvert::not_at_record_end $rline] && ![eof $fileInId]} {
	set rline2 [bibConvert::throw_away $rline]
	# Get all of a single item.
	while {[bibConvert::not_new_field $rline2] && ![eof $fileInId]} {
	    append rline [bibConvert::append_field_text $rline2]
	    set rline2 [bibConvert::throw_away $rline2]
	}
	set item [bibConvert::extract_field_info $rline]
	eval bibConvert::make_item new_record $item
	set rline $rline2
    }
    set bibConvert::last_item $rline

    # All fields are in the array 'new_record'.  Format the entry.

    # Returns the type of citation.
    set entryType [bibConvert::reformat_records new_record]
    # Make sure that we're 'allowed' to add the fields found, and then
    # shuffle the deck to add the author, title, year first.
    set fieldNames [list]
    foreach fieldName [lsort [array names new_record]] {
	if {[lsearch $bibConvertVars(excludeFields) $fieldName] == "-1"} {
	    lappend fieldNames $fieldName
	}
    }
    foreach fieldName {year title author} {
	if {[set idx [lsearch $fieldNames $fieldName]] != "-1"} {
	    set fieldNames [concat $fieldName [lreplace $fieldNames $idx $idx]]
	}
    }
    # First figure out the longest field.
    set bibConvertVars(multiIndent) ""
    set bibConvertVars(longestField) 0
    foreach fieldName $fieldNames {
	set len1 [string length $fieldName]
	if {$len1 > $bibConvertVars(longestField)} {
	    set bibConvertVars(longestField) $len1
	}
    }
    # Set the 'multiIndent'
    set bibConvertVars(multiIndent) $bibConvertVars(bibIndent)
    set space "                                             "
    append bibConvertVars(multiIndent) "[string range $space 0 $bibConvertVars(longestField)]   "
    # Set the open, close characters.
    set openEntry  $bibConvertVars(openEntry)
    set closeEntry $bibConvertVars(closeEntry)
    # Determine the citekey tag.
    set tag ""
    if {[info exists new_record(citekey)]} {
	# Some formats  (e.g. refer) might define citekey fields.
	set tag $new_record(citekey)
	set new_record(citekey) ""
    } else {
	# Parse author(s) out and append to the tag.
	append tag [bibConvert::parse_author new_record]
	# Parse year out (ignoring months) and append to the tag.
	append tag [bibConvert::parse_year   new_record]
	# Remove spaces to give the citation tag
	set tag [join [split $tag " "] ""]
	if {![string length $tag]} {set tag "??"}
    }
    # Now add them all, nicely indented.
    puts $fileOutId "@${entryType}${openEntry}${tag},"
    foreach fieldName $fieldNames {
	if {![string length $new_record($fieldName)]} {continue}
	puts $fileOutId [bibConvert::format_field new_record $fieldName]
	unset new_record($fieldName)
    }
    puts $fileOutId "${closeEntry}"
}

# ×××× ------- ×××× #

# ×××× Field Mappings ×××× #

# Record field name mappings for different formats.
#
# Note that spaces are replaced by underscores in array entries, and the
# 'map from' fields will be in upper case.  Any field names encountered
# which are not defined in these arrays will be mapped to their UPPER_CASE
# names.  All field names that are still mapped to UPPER CASE field names
# will be deleted at the end of the reformatting process, so this is a
# useful way to keep track of temporary information.

# # ××××   Hollis mappings: ×××× #

array set bibConvert::hollis_map {

    "AUTHOR"       "AUTHOR"
    "AUTHORS"      "AUTHORS"
    "EDITION"      "edition"
    "LOCATION"     "customField"
    "NOTES"        "note"
    "NUMBERS"      "isbn"
    "PUB._INFO"    "publisher"
    "PUBLISHED_IN" "howPublished"
    "SERIES"       "series"
    "SUBJECTS"     "key"
    "SUMMARY"      "contents"
    "TITLE"        "title"
    "YEAR"         "year"
}

# # ××××   Inspec 2 mappings ×××× #

array set bibConvert::inspec2_map {

    "ABSTRACT"      "abstract"
    "AUTHOR"        "author"
    "ISSN"          "issn"
    "IDENTIFIERS"   "key"
    "LANGUAGE"      "language"
    "SOURCE"        "journal"
    "SUBJECT"       "note"
    "TITLE"         "title"
    "YEAR"          "year"
}

# # ××××   Inspec 3 mappings ×××× #

# These are for inspec files started with 'Citation ...'  and

array set bibConvert::inspec3_map {

    "ABSTRACT"          "abstract"
    "AUTHOR"            "author"
    "CONF_TITLE"        "organization"
    "CORP_SOURCE"       "institution"
    "DESCRIPTORS"       "key"
    "EDITOR"            "editor"
    "IDENTIFIERS"       "key"
    "ISBN"              "isbn"
    "ISSN"              "issn"
    "LANGUAGE"          "language"
    "LOCATION"          "location"
    "NOTES"             "note"
    "OTHER_SUBJECTS"    "annote"
    "PLACE_OF_PUBL"     "howPublished"
    "PUBLICATION"       "journal"
    "PUBLISHER"         "publisher"
    "SPONSOR_ORG"       "organization"
    "THESAURUS"         "key"
    "TITLE"             "title"
    "YEAR"              "year"
}

# # ××××   Inspec 4 mappings ×××× #

# These are for inspec files started with 'Doc Type: ...'  and

array set bibConvert::inspec4_map {

    "ABSTRACT"               "abstract"
    "AFFILIATION"            "organization"
    "AUTHORS"                "author"
    "CLASSIFICATION"         "key"
    "COUNTRY_OF_PUBLICATION" "howPublished"
    "DATE"                   "year"
    "FREE_TERMS"             "key"
    "ISSN"                   "issn"
    "JOURNAL"                "journal"
    "LANGUAGE"               "language"
    "THESAURUS"              "key"
    "TITLE"                  "title"
    "VOL"                    "volume"
}

# # ××××   Inspec 5 mappings ×××× #

# These are for inspec files started with 'Record No: ...'  and

array set bibConvert::inspec5_map {

    "ABSTRACT"      "abstract"
    "AUTHOR"        "author"
    "CONF_TITLE"    "organization"
    "CORP_SOURCE"   "institution"
    "DESCRIPTORS"   "key"
    "EDITOR"        "editor"
    "IDENTIFIERS"   "key"
    "ISBN"          "isbn"
    "ISSN"          "issn"
    "LANGUAGE"      "language"
    "PLACE_OF_PUBL" "howPublished"
    "PUBLISHER"     "publisher"
    "SOURCE"        "journal"
    "SPONSOR_ORG"   "organization"
    "TITLE"         "title"
    "YEAR"          "year"
}

# # ××××   Inspec 6 mappings ×××× #

# These are for inspec files started with 'N. (INSPEC result)'

array set bibConvert::inspec6_map {

    "AFFILIATION"   "institution"
    "AUTHOR"        "author"
    "CONFERENCE"    "organization"
    "LANGUAGE"      "language"
    "SOURCE"        "journal"
    "SUBJECT"       "key"
    "TEXT"          "annote"
    "TITLE"         "title"
}

# # ××××   Inspec 7 mappings ×××× #

# These are for inspec files started with <N>, and each article with an

array set bibConvert::inspec7_map {

    "ABSTRACT"               "abstract"
    "AUTHOR"                 "author"
    "DESCRIPTORS"            "key"
    "ISSN,ISBN,SBN"          "issn"
    "IDENTIFIERS"            "key"
    "LANGUAGE"               "language"
    "SOURCE"                 "journal"
    "SUBJECT"                "note"
    "TITLE"                  "title"
    "YEAR"                   "year"
}

# # ××××   ISI mappings: ×××× #

# Note:
#
# DE post-processed into key
# EP post-processed into pages
# DT post-processed into entry type
#

array set bibConvert::isi_map {

    "AB" "abstract"
    "AU" "author"
    "BP" "pages"
    "C1" "institution"
    "DE" "DE"
    "DT" "DT"
    "EP" "EP"
    "ID" "key"
    "IS" "number"
    "LA" "language"
    "PD" "month"
    "PU" "publisher"
    "PY" "year"
    "SE" "series"
    "SO" "journal"
    "TI" "title"
    "VL" "volume"
}

# # ××××   MARC 21 mappings ×××× #

array set bibConvert::marc21_map {

    "001" "CONTROL_NUMBER"
    "003" "CONTROL_NUMBER_IDENTIFIER"
    "005" "DATE_AND_TIME_OF_LATEST_TRANSACTION"
    "006" "FIXED-LENGTH_DATA_ELEMENTS_-_ADDITIONAL_MATERIAL_CHARACTERISTICS"
    "007" "PHYSICAL_DESCRIPTION_FIXED_FIELD"
    "008" "FIXED-LENGTH_DATA_ELEMENTS"

    "010" "LIBRARY_OF_CONGRESS_CONTROL_NUMBER"
    "013" "PATENT_CONTROL_INFORMATION"
    "015" "NATIONAL_BIBLIOGRAPHY_NUMBER"
    "016" "NATIONAL_BIBLIOGRAPHIC_AGENCY_CONTROL_NUMBER"
    "017" "COPYRIGHT_REGISTRATION_NUMBER"
    "018" "COPYRIGHT_ARTICLE-FEE_CODE"
    "020" "INTERNATIONAL_STANDARD_BOOK_NUMBER"
    "022" "INTERNATIONAL_STANDARD_SERIAL_NUMBER"
    "023" "STANDARD_FILM_NUMBER_[DELETED]"
    "024" "OTHER_STANDARD_IDENTIFIER"
    "025" "OVERSEAS_ACQUISITION_NUMBER"
    "027" "STANDARD_TECHNICAL_REPORT_NUMBER"
    "028" "PUBLISHER_NUMBER"
    "030" "CODEN_DESIGNATION"
    "032" "POSTAL_REGISTRATION_NUMBER"
    "033" "DATE/TIME_AND_PLACE_OF_AN_EVENT"
    "034" "CODED_CARTOGRAPHIC_MATHEMATICAL_DATA"
    "035" "SYSTEM_CONTROL_NUMBER"
    "036" "ORIGINAL_STUDY_NUMBER_FOR_COMPUTER_DATA_FILES"
    "037" "SOURCE_OF_ACQUISITION"
    "040" "CATALOGING_SOURCE"
    "041" "LANGUAGE_CODE"
    "042" "AUTHENTICATION_CODE"
    "043" "GEOGRAPHIC_AREA_CODE"
    "044" "COUNTRY_OF_PUBLISHING/PRODUCING_ENTITY_CODE"
    "045" "TIME_PERIOD_OF_CONTENT"
    "046" "SPECIAL_CODED_DATES"
    "047" "FORM_OF_MUSICAL_COMPOSITION_CODE"
    "048" "NUMBER_OF_MUSICAL_INSTRUMENTS_OR_VOICES_CODE"
    "049" "LOCAL_HOLDINGS"
    "050" "LIBRARY_OF_CONGRESS_CALL_NUMBER"
    "051" "LIBRARY_OF_CONGRESS_COPY,_ISSUE,_OFFPRINT_STATEMENT"
    "052" "GEOGRAPHIC_CLASSIFICATION"
    "055" "CALL_NUMBERS/CLASS_NUMBERS_ASSIGNED_IN_CANADA"
    "060" "NATIONAL_LIBRARY_OF_MEDICINE_CALL_NUMBER"
    "061" "NATIONAL_LIBRARY_OF_MEDICINE_COPY_STATEMENT"
    "066" "CHARACTER_SETS_PRESENT"
    "070" "NATIONAL_AGRICULTURAL_LIBRARY_CALL_NUMBER"
    "071" "NATIONAL_AGRICULTURAL_LIBRARY_COPY_STATEMENT"
    "072" "SUBJECT_CATEGORY_CODE"
    "074" "GPO_ITEM_NUMBER"
    "080" "UNIVERSAL_DECIMAL_CLASSIFICATION_NUMBER"
    "082" "DEWEY_DECIMAL_CALL_NUMBER"
    "084" "OTHER_CALL_NUMBER"
    "086" "GOVERNMENT_DOCUMENT_CALL_NUMBER"
    "088" "REPORT_NUMBER"

    "100" "MAIN_ENTRY_-_PERSONAL_NAME"
    "110" "MAIN_ENTRY_-_CORPORATE_NAME"
    "111" "MAIN_ENTRY_-_MEETING_NAME"
    "130" "MAIN_ENTRY_-_UNIFORM_TITLE"

    "210" "ABBREVIATED_TITLE"
    "222" "KEY_TITLE"
    "240" "UNIFORM_TITLE"
    "242" "TRANSLATION_OF_TITLE_BY_CATALOGING_AGENCY"
    "243" "COLLECTIVE_UNIFORM_TITLE"
    "245" "TITLE_STATEMENT"
    "246" "VARYING_FORM_OF_TITLE"
    "247" "FORMER_TITLE_OR_TITLE_VARIATIONS"

    "250" "EDITION_STATEMENT"
    "254" "MUSICAL_PRESENTATION_STATEMENT"
    "255" "CARTOGRAPHIC_MATHEMATICAL_DATA"
    "256" "COMPUTER_FILE_CHARACTERISTICS"
    "257" "COUNTRY_OF_PRODUCING_ENTITY_FOR_ARCHIVAL_FILMS"
    "260" "PUBLICATION,_DISTRIBUTION,_ETC."
    "261" "IMPRINT_STATEMENT_FOR_FILMS"
    "262" "IMPRINT_STATEMENT_FOR_SOUND_RECORDINGS"
    "263" "PROJECTED_PUBLICATION_DATE"
    "270" "ADDRESS"

    "300" "PHYSICAL_DESCRIPTION"
    "306" "PLAYING_TIME"
    "307" "HOURS,_ETC."
    "310" "CURRENT_PUBLICATION_FREQUENCY"
    "321" "FORMER_PUBLICATION_FREQUENCY"
    "340" "PHYSICAL_MEDIUM"
    "342" "GEOSPATIAL_REFERENCE_DATA"
    "343" "PLANAR_COORDINATE_DATA"
    "351" "ORGANIZATION_AND_ARRANGEMENT_OF_MATERIALS"
    "352" "DIGITAL_GRAPHIC_REPRESENTATION"
    "355" "SECURITY_CLASSIFICATION_CONTROL"
    "357" "ORIGINATOR_DISSEMINATION_CONTROL"
    "362" "DATES_OF_PUBLICATION_AND/OR_SEQUENTIAL_DESIGNATION"

    "400" "SERIES_STATEMENT/ADDED_ENTRY_-_PERSONAL_NAME"
    "410" "SERIES_STATEMENT/ADDED_ENTRY_-_CORPORATE_NAME"
    "411" "SERIES_STATEMENT/ADDED_ENTRY_-_MEETING_NAME"
    "440" "SERIES_STATEMENT/ADDED_ENTRY_-_TITLE"
    "490" "SERIES_STATEMENT"

    "500" "GENERAL_NOTE"
    "501" "WITH_NOTE"
    "502" "DISSERTATION_NOTE"
    "504" "BIBLIOGRAPHY,_ETC._NOTE"
    "505" "FORMATTED_CONTENTS_NOTE"
    "506" "RESTRICTIONS_ON_ACCESS_NOTE"
    "507" "SCALE_NOTE_FOR_GRAPHIC_MATERIAL"
    "508" "CREATION/PRODUCTION_CREDITS_NOTE"
    "510" "CITATION/REFERENCES_NOTE"
    "511" "PARTICIPANT_OR_PERFORMER_NOTE"
    "513" "TYPE_OF_REPORT_AND_PERIOD_COVERED_NOTE"
    "514" "DATA_QUALITY_NOTE"
    "515" "NUMBERING_PECULIARITIES_NOTE"
    "516" "TYPE_OF_COMPUTER_FILE_OR_DATA_NOTE"
    "518" "DATE/TIME_AND_PLACE_OF_AN_EVENT_NOTE"
    "520" "SUMMARY,_ETC."
    "521" "TARGET_AUDIENCE_NOTE"
    "522" "GEOGRAPHIC_COVERAGE_NOTE"
    "524" "PREFERRED_CITATION_OF_DESCRIBED_MATERIALS_NOTE"
    "525" "SUPPLEMENT_NOTE"
    "526" "STUDY_PROGRAM_INFORMATION_NOTE"
    "530" "ADDITIONAL_PHYSICAL_FORM_AVAILABLE_NOTE"
    "533" "REPRODUCTION_NOTE"
    "534" "ORIGINAL_VERSION_NOTE"
    "535" "LOCATION_OF_ORIGINALS/DUPLICATES_NOTE"
    "536" "FUNDING_INFORMATION_NOTE"
    "538" "SYSTEM_DETAILS_NOTE"
    "540" "TERMS_GOVERNING_USE_AND_REPRODUCTION_NOTE"
    "541" "IMMEDIATE_SOURCE_OF_ACQUISITION_NOTE"
    "544" "LOCATION_OF_OTHER_ARCHIVAL_MATERIALS_NOTE"
    "545" "BIOGRAPHICAL_OR_HISTORICAL_DATA"
    "546" "LANGUAGE_NOTE"
    "547" "FORMER_TITLE_COMPLEXITY_NOTE"
    "550" "ISSUING_BODY_NOTE"
    "552" "ENTITY_AND_ATTRIBUTE_INFORMATION_NOTE"
    "555" "CUMULATIVE_INDEX/FINDING_AIDS_NOTE"
    "556" "INFORMATION_ABOUT_DOCUMENTATION_NOTE"
    "561" "OWNERSHIP_AND_CUSTODIAL_HISTORY"
    "562" "COPY_AND_VERSION_IDENTIFICATION_NOTE"
    "565" "CASE_FILE_CHARACTERISTICS_NOTE"
    "567" "METHODOLOGY_NOTE"
    "580" "LINKING_ENTRY_COMPLEXITY_NOTE"
    "581" "PUBLICATIONS_ABOUT_DESCRIBED_MATERIALS_NOTE"
    "583" "ACTION_NOTE"
    "584" "ACCUMULATION_AND_FREQUENCY_OF_USE_NOTE"
    "585" "EXHIBITIONS_NOTE"
    "586" "AWARDS_NOTE"

    "600" "SUBJECT_ADDED_ENTRY_-_PERSONAL_NAME"
    "610" "SUBJECT_ADDED_ENTRY_-_CORPORATE_NAME"
    "611" "SUBJECT_ADDED_ENTRY_-_MEETING_NAME"
    "630" "SUBJECT_ADDED_ENTRY_-_UNIFORM_TITLE"
    "650" "SUBJECT_ADDED_ENTRY_-_TOPICAL_TERM"
    "651" "SUBJECT_ADDED_ENTRY_-_GEOGRAPHIC_NAME"
    "653" "INDEX_TERM_-_UNCONTROLLED"
    "654" "SUBJECT_ADDED_ENTRY_-_FACETED_TOPICAL_TERMS"
    "655" "INDEX_TERM_-_GENRE/FORM"
    "656" "INDEX_TERM_-_OCCUPATION"
    "657" "INDEX_TERM_-_FUNCTION"
    "658" "INDEX_TERM_-_CURRICULUM_OBJECTIVE"

    "700" "ADDED_ENTRY_-_PERSONAL_NAME"
    "710" "ADDED_ENTRY_-_CORPORATE_NAME"
    "711" "ADDED_ENTRY_-_MEETING_NAME"
    "720" "ADDED_ENTRY_-_UNCONTROLLED_NAME"
    "730" "ADDED_ENTRY_-_UNIFORM_TITLE"
    "740" "ADDED_ENTRY_-_UNCONTROLLED_RELATED/ANALYTICAL_TITLE"
    "752" "ADDED_ENTRY_-_HIERARCHICAL_PLACE_NAME"
    "753" "SYSTEM_DETAILS_ACCESS_TO_COMPUTER_FILES"
    "754" "ADDED_ENTRY_-_TAXONOMIC_IDENTIFICATION"

    "760" "MAIN_SERIES_ENTRY"
    "762" "SUBSERIES_ENTRY"
    "765" "ORIGINAL_LANGUAGE_ENTRY"
    "767" "TRANSLATION_ENTRY"
    "770" "SUPPLEMENT/SPECIAL_ISSUE_ENTRY"
    "772" "PARENT_RECORD_ENTRY"
    "773" "HOST_ITEM_ENTRY"
    "774" "CONSTITUENT_UNIT_ENTRY"
    "775" "OTHER_EDITION_ENTRY"
    "776" "ADDITIONAL_PHYSICAL_FORM_ENTRY"
    "777" "ISSUED_WITH_ENTRY"
    "780" "PRECEDING_ENTRY"
    "785" "SUCCEEDING_ENTRY"
    "786" "DATA_SOURCE_ENTRY"
    "787" "NONSPECIFIC_RELATIONSHIP_ENTRY"

    "800" "SERIES_ADDED_ENTRY_-_PERSONAL_NAME"
    "810" "SERIES_ADDED_ENTRY_-_CORPORATE_NAME"
    "811" "SERIES_ADDED_ENTRY_-_MEETING_NAME"
    "830" "SERIES_ADDED_ENTRY_-_UNIFORM_TITLE"

    "841" "HOLDINGS_CODED_DATA_VALUES_HOLDINGS_DATA_FORMAT"
    "842" "TEXTUAL_PHYSICAL_FORM_DESIGNATOR_HOLDINGS_DATA_FORMAT"
    "843" "REPRODUCTION_NOTE_HOLDINGS_DATA_FORMAT"
    "844" "NAME_OF_UNIT_HOLDINGS_DATA_FORMAT"
    "845" "TERMS_GOVERNING_USE_AND_REPRODUCTION_NOTE_HOLDINGS_DATA_FORMAT"
    "850" "HOLDING_INSTITUTION"
    "852" "LOCATION"
    "853" "CAPTIONS_AND_PATTERN_-_BASIC_BIBLIOGRAPHIC_UNIT_HOLDINGS_DATA_FORMAT"
    "854" "CAPTIONS_AND_PATTERN_-_SUPPLEMENTARY_MATERIAL_HOLDINGS_DATA_FORMAT"
    "855" "CAPTIONS_AND_PATTERN_-_INDEXES_HOLDINGS_DATA_FORMAT"
    "856" "ELECTRONIC_LOCATION_AND_ACCESS"
    "863" "ENUMERATION_AND_CHRONOLOGY_-_BASIC_BIBLIOGRAPHIC_UNIT_HOLDINGS_DATA"
    "864" "ENUMERATION_AND_CHRONOLOGY_-_SUPPLEMENTARY_MATERIAL_HOLDINGS_DATA"
    "865" "ENUMERATION_AND_CHRONOLOGY_-_INDEXES_HOLDINGS_DATA_FORMAT"
    "866" "TEXTUAL_HOLDINGS_-_BASIC_BIBLIOGRAPHIC_UNIT_HOLDINGS_DATA_FORMAT"
    "867" "TEXTUAL_HOLDINGS_-_SUPPLEMENTARY_MATERIAL_HOLDINGS_DATA_FORMAT"
    "868" "TEXTUAL_HOLDINGS_-_INDEXES_HOLDINGS_DATA_FORMAT"
    "876" "ITEM_INFORMATION_-_BASIC_BIBLIOGRAPHIC_UNIT_HOLDINGS_DATA_FORMAT"
    "877" "ITEM_INFORMATION_-_SUPPLEMENTARY_MATERIAL_HOLDINGS_DATA_FORMAT"
    "878" "ITEM_INFORMATION_-_INDEXES_HOLDINGS_DATA_FORMAT"
    "880" "ALTERNATE_GRAPHIC_REPRESENTATION"
    "886" "FOREIGN_MARC_INFORMATION_FIELD"
}

# # ××××   OCLC1 mappings ×××× #

array set bibConvert::oclc1_map {

    "ABSTRACT"      "abstract"
    "AUTHOR"        "author"
    "CONF_TITLE"    "organization"
    "CORP_SOURCE"   "institution"
    "DESCRIPTORS"   "key"
    "EDITOR"        "editor"
    "IDENTIFIERS"   "key"
    "ISBN"          "isbn"
    "ISSN"          "issn"
    "LANGUAGE"      "language"
    "PLACE_OF_PUBL" "howPublished"
    "PUBLISHER"     "publisher"
    "SOURCE"        "journal"
    "SPONSOR_ORG"   "organization"
    "TITLE"         "title"
    "YEAR"          "year"
}

# # ××××   OCLC2 mappings ×××× #

array set bibConvert::oclc2_map {

    "ABSTRACT"      "abstract"
    "AUTHOR"        "author"
    "CLASS_DESCRPT" "CLASS_DESCRPT"
    "CONF_TITLE"    "organization"
    "CORP_SOURCE"   "institution"
    "DESCRIPTION"   "DESCRIPTION"
    "DESCRIPTOR"    "key"
    "DOCUMENT_TYPE" "TYPE"
    "EDITION"       "edition"
    "EDITOR"        "editor"
    "IDENTIFIER"    "key"
    "ISBN"          "isbn"
    "ISSN"          "issn"
    "IN"            "IN"
    "LANGUAGE"      "language"
    "NOTE"          "note"
    "PUBLICATION"   "publisher"
    "SERIES"        "series"
    "SOURCE"        "journal"
    "SPONSOR_ORG"   "organization"
    "STANDARD_NO"   "STANDARD_NO"
    "TITLE"         "title"
    "TOC"           "contents"
    "YEAR"          "year"
}

# # ××××   Ovid1 mappings ×××× #

# This is an older style, perhaps obsolete now (??)
# The support code for this style is not being updated.

array set bibConvert::ovid1_map {

    "ABSTRACT"                           "abstract"
    "AUTHOR"                             "author"
    "BOOK_PUBLISHER"                     "publisher"
    "CHAPTER_TITLE"                      "chapter"
    "CONFERENCE_INFORMATION"             "conference"
    "DESCRIPTORS"                        "key"
    "GENERAL_NOTES"                      "note"
    "INSTITUTION"                        "institution"
    "ISBN"                               "issn"
    "ISSN"                               "issn"
    "JOURNAL_DATE"                       "year"
    "KEY_PHRASE_IDENTIFIERS"             "key"
    "LANGUAGE"                           "language"
    "LIBRARY_OF_CONGRESS_CATALOG_NUMBER" "lccn"
    "PAGINATION"                         "pages"
    "PUBLICATION_TYPE"                   "TYPE"
    "PUBLICATION_YEAR"                   "year"
    "SOURCE"                             "journal"
    "SUBJECT_HEADINGS"                   "note"
    "TITLE"                              "title"
    "VOLUME"                             "volume"
    "YEAR_OF_PUBLICATION"                "year"

    "AB" "abstract"
    "AU" "author"
    "IB" "isbn"
    "ID" "key"
    "IS" "issn"
    "JN" "journal"
    "JY" "year"
    "LC" "lccn"
    "LG" "language"
    "NT" "note"
    "PB" "publisher"
    "PG" "pages"
    "PT" "TYPE"
    "PY" "year"
    "SO" "journal"
    "TI" "title"
    "YR" "year"
}

# # ××××   Refer mappings: ×××× #

array set bibConvert::refer_map {

    "0" "TYPE"
    "1" "chapter"
    "2" "customField2"
    "3" "customField3"
    "4" "customField4"
    "5" "customField5"
    "6" "customField6"
    "7" "edition"
    "8" "month"
    "9" "howpublished"

    "A" "author"
    "B" "booktitle"
    "C" "address"
    "D" "year"
    "E" "editor"
    "F" "citekey"
    "G" "customFieldG"
    "H" "customFieldH"
    "I" "publisher"
    "J" "journal"
    "K" "keywords"
    "L" "customFieldL"
    "M" "customFieldM"
    "N" "number"
    "O" "note"
    "P" "pages"
    "Q" "customFieldQ"
    "R" "customFieldR"
    "S" "series"
    "T" "title"
    "U" "url"
    "V" "volume"
    "W" "customFieldW"
    "X" "abstract"
    "Y" "customFieldY"
    "Z" "customFieldZ"
}

# # ××××   WebSPIRS5 mappings ×××× #

# These are for the newer style ('WebSPIRS5', released summer 2002).  These
# also include some 'leftover' fields from 'ovid1' to help ensure back
# compatibility ...

array set bibConvert::webspirs5_map {

    "ABSTRACT"                                   "abstract"
    "AUTHOR"                                     "author"
    "BOOK_PUBLISHER"                             "publisher"
    "CHAPTER_TITLE"                              "chapter"
    "CONFERENCE_INFORMATION"                     "conference"
    "DOCUMENT_TYPE"                              "TYPE"
    "DESCRIPTORS"                                "key"
    "GENERAL_NOTES"                              "note"
    "INSTITUTION"                                "institution"
    "ISBN"                                       "issn"
    "ISSN"                                       "issn"
    "JOURNAL_DATE"                               "year"
    "KEY_PHRASE_IDENTIFIERS"                     "key"
    "LANGUAGE"                                   "language"
    "LIBRARY_OF_CONGRESS_CATALOG_NUMBER"         "lccn"
    "PAGINATION"                                 "pages"
    "PUBLICATION_YEAR"                           "year"
    "PUBLISHER_INFORMATION_OF_ORIGINAL_DOCUMENT" "note"
    "SBN"                                        "issn"
    "SOURCE"                                     "SOURCE"
    "SUBJECT_HEADINGS"                           "note"
    "TITLE"                                      "title"
    "VOLUME"                                     "volume"
    "YEAR_OF_PUBLICATION"                        "year"

    "AB" "abstract"
    "AU" "author"
    "DE" "key"
    "DT" "TYPE"
    "IB" "isbn"
    "ID" "key"
    "IS" "issn"
    "JN" "journal"
    "JY" "year"
    "LC" "lccn"
    "LA" "language"
    "NT" "note"
    "PB" "publisher"
    "PG" "pages"
    "PT" "TYPE"
    "PY" "year"
    "SO" "SOURCE"
    "TI" "title"
    "YR" "year"
}

# ×××× -------- ×××× #

# ×××× Reading Entry Records ×××× #

##
 # Find the start of a new bibtex record.  Each type MUST include an entry
 # in the switch.  This line will NOT be scanned for field information, so
 # if there's anything in there it needs to be saved and retrieved later.
 ##

proc bibConvert::find_record_start {rline} {

    global bibConvertVars

    set fileInId $bibConvertVars(fileInId)

    if {$rline == ""} {gets $fileInId rline}

    set isStart 0
    while {![eof $fileInId]} {
	switch -- $bibConvertVars(bibType) {
	    "hollis" {
		if {$rline == "%START:"} {
		    set isStart 1
		}
	    }
	    "inspec2" {
		if {[string range $rline 0 7] == "Document"} {
		    set isStart 1
		}
	    }
	    "inspec3" {
		if {[string range $rline 0 7] == "Citation"} {
		    set isStart 1
		}
	    }
	    "inspec4" {
		if {[string range $rline 0 8] == " Doc Type"} {
		    set isStart 1
		}
	    }
	    "inspec5" {
		if {[ string range $rline 0 13] == "   RECORD NO.:"      \
		  || [string range $rline 0 20] == "          RECORD NO.:"} {
		    set isStart 1
		}
	    }
	    "inspec6" {
		if {[string trim [lindex [split $rline "."] 1]] == "(INSPEC result)"} {
		    if {[string trim $rline] == "CONFERENCE PAPER"} {
			set isStart 1
		    }
		}
	    }
	    "inspec7" {
		if {[regexp {^<[0-9]+>} $rline]} {
		    set isStart 1
		}
	    }
	    "isi" {
		if {[string range $rline 0 1] == "PT"} {
		    set isStart 1
		}
	    }
	    "marc21" {
		set bibConvertVars(marcEntryType) ""
		set    pat "^$bibConvertVars(marcFieldPad)"
		append pat "$bibConvertVars(marcEntryField)(.*)"
		if {[regexp $pat $rline allofit type]} {
		    set bibConvertVars(marcEntryType) $type
		    set isStart 1
		}
	    }
	    "ovid1" {
		if {[regexp {^<[0-9]+>} $rline]} {
		    set isStart 1
		}
	    }
	    "oclc1" {
		if {[string range $rline 0 14] == "|   RECORD NO.:"} {
		    set isStart 1
		}
	    }
	    "oclc2" {
		if {[string range $rline 0 15] == "Database:       "} {
		    set isStart 1
		}
	    }
	    "refer" {
		if {[regexp "^%(\[^\r\n\t \]) (.*)$" $rline allofit field value]} {
		    # Set the new type.  This won't be perfect, and will
		    # require some modification by the user.  We have to do
		    # this here because this line will NOT be read in as a
		    # valid field.
		    set bibConvertVars(referFirstField) [list $field $value]
		    set bibConvertVars(referRecordEnd) 0
		    set isStart 1
		}
	    }
	    "webspirs5" {
		if {[regexp {Record [0-9]+ of [0-9]+} $rline]} {
		    set isStart 1
		}
	    }
	    default {
		close $bibConvertVars(fileInId)
		close $bibConvertVars(fileOutId)
		vince_message "Unknown bib type $bibConvertVars(bibType)" 1
	    }
	}
	gets $fileInId rline
	if {$isStart} {return $rline}
    }
    return 0
}

##
 # Have we reached the end of the last bibtex field?  Each type MUST have
 # an entry in the switch.
 ##

proc bibConvert::not_at_record_end {line} {

    global bibConvertVars

    switch -- $bibConvertVars(bibType) {
	"hollis" {
	    if {$line != "%END:"} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec2" {
	    set st [string range $line 0 7]
	    if {$st != "--------" && $st != "UW Load "} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec3" {
	    if {[string range $line 0 7] != "Citation"} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec4" {
	    if {[string range $line 0 8] != " Doc Type"} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec5" {
	    set st [string range $line 0 13]
	    if {$st != "  CLASS CODES:" && $st != "   RECORD NO.:"} {
		return 1
	    } else {
		set st [string range $line 0 20]
		if {$st != "         CLASS CODES:" && $st != "          RECORD NO.:"} {
		    return 1
		} else {
		    return 0
		}
	    }

	}
	"inspec6" {
	    set st [string trim [lindex [split $line "."] 1]]
	    if {$st != "(INSPEC result)"} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec7" {
	    if {[string trim $line] == ""} {
		return 0
	    } else {
		return 1
	    }
	}
	"isi" {
	    if {$line != "ER"} {
		return 1
	    } else {
		return 0
	    }
	}
	"marc21" {
	    set    pat "^$bibConvertVars(marcFieldPad)"
	    append pat $bibConvertVars(marcEntryField)
	    if {[regexp $pat $line]} {
		return 0
	    } else {
	        return 1
	    }
	}
	"oclc1" {
	    set st [string range $line 0 14]
	    if {$st != "|  CLASS CODES:" && $st != "|   RECORD NO.:"} {
		return 1
	    } else {
		return 0
	    }

	}
	"oclc2" {
	    set st [string range $line 0 15]
	    if {$st == "Accession No:   " || $st == "Database:       "} {
		return 0
	    } else {
		return 1
	    }

	}
	"ovid1" {
	    if {[string trim $line] == ""} {
		return 0
	    } else {
		return 1
	    }
	}
	"refer" {
	    if {$bibConvertVars(referRecordEnd)} {
	        return 0
	    } else {
	        return 1
	    }
	}
	"webspirs5" {
	    if {[regexp {Record [0-9]+ of [0-9]+} $line]} {
		return 0
	    } else {
		return 1
	    }
	}
	default {
	    close $bibConvertVars(fileInId)
	    close $bibConvertVars(fileOutId)
	    vince_message "Unknown bib type $bibConvertVars(bibType)" 1
       }
    }
}

##
 # Some interfaces intersperse records with garbage lines ("press 'f' for
 # another page").  This procedure ignores them.
 ##

proc bibConvert::throw_away {l1} {

    global bibConvertVars

    gets [set fileInId $bibConvertVars(fileInId)] rline2
    switch -- $bibConvertVars(bibType) {
	"inspec5" {
	    if {[string range $rline2 0 11] == " Next Record"} {
		gets $fileInId rline2
	    }
	}
	"inspec6" {
	    set tr [string trim $rline2]
	    if {$tr  == "CONFERENCE PAPER" || $tr == ""} {
		gets $fileInId rline2
	    }
	}
	"oclc1" {
	    while {![eof $fileInId]} {
		# do away with identical lines (caused by paging through
		# data)
		if {$l1 != $rline2 \
		  && [string range $rline2 0 1] != "|_" \
		  && $rline2 != "|" \
		  && [string index $rline2 0] == "|"} {
		    break
		}
		gets $fileInId rline2
	    }
	}
	"oclc2" {
	    if {[regexp {^SUBJECTS\(S\) *$} $rline2]} {
	        gets $fileInId $rline2
	    } 
	}
    }
    return $rline2
}

##
 # Some fields extend over multiple lines, in which case we don't start a
 # new field entry.  This procedure returns '1' if we have a continuation.
 ##

proc bibConvert::not_new_field {line} {

    global bibConvertVars

    switch -- $bibConvertVars(bibType) {
	"hollis" {
	    if {[string index $line 0] != "%"} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec2" -
	"inspec6" {
	    # Is the first portion of the line blank?
	    if {[string range $line 0 14] == "               "} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec3" -
	"inspec4" {
	    # Is the first portion of the line blank?
	    if {[string range $line 0 2] == "   "} {
		return 1
	    } else {
		return 0
	    }
	}
	"inspec5" {
	    # Is there a colon at position 13?
	    if {[string index $line 13] != ":" && [string index $line 20] != ":"} {
		return 1
	    } else {
		return 0
	    }
	}
	"marc21" {
	    # Does the line begin with a new field number?
	    set    pat "^$bibConvertVars(marcFieldPad)"
	    append pat {([0-9][0-9][0-9]|[A-Z][A-Z][A-Z])}
	    if {![regexp $pat $line]} {
		return 1
	    } else {
		return 0
	    }
	}
	"oclc1" {
	    # Is there a colon at position 14, and it starts with "|"
	    if {[string index $line 14] != ":" || [string index $line 0] != "|"} {
		return 1
	    } else {
		return 0
	    }
	}
	"oclc2" {
	    set st [string range $line 0 15]
	    # Is the string empty space?
	    if {$st == "                "} {
	        return 1
	    } 
	    # That should be the only test.  However, the current
	    # implementation of oclc (August 2002) is somewhat
	    # inconsistent, and will often wrap lines to column 0 rather
	    # than column 16 like it should.

	    # Is the string a field with ':' and then white space?
	    # Or is it 'SUBJECT(S)' ?
	    if {![regexp {^([A-Z][^:]+: +)|(SUBJECT\(S\))$} $st]} {
		return 1
	    } else {
		return 0
	    }
	}
	"refer" {
	    if {![string length [string trim $line]]} {
	        # We're not only at the end of a field, but at the end of
	        # the record.
		set bibConvertVars(referRecordEnd) 1
		return 1
	    } elseif {[string index $line 0] == "%"} {
		return 0
	    } else {
		return 1
	    }
	}
	"webspirs5" {
	    # Sometimes long line wraps get screwed up.
	    set pat1 {^[A-Z][()A-Z ]+: }
	    set pat2 {Record [0-9]}
	    if {[regexp $pat1 $line] || [regexp $pat2 $line]} {
		return 0
	    } else {
		return 1
	    }
	}
	default {
	    # does the line start with whitespace
	    return [regexp {^[ \t]+[^ \t]} $line]
	}
    }
}

##
 # We had a multiple line field and wish to add the subsequent lines
 ##

proc bibConvert::append_field_text {rline2} {

    global bibConvertVars

    switch -- $bibConvertVars(bibType) {
	"inspec" {
	    if {$rline2 != "|"} {
		if {[string index $rline2 0] == "|"} {
		    return " [string range $rline2 1 end]"
		} else {
		    return " $rline2"
		}
	    } else {
		return ""
	    }
	}
	default {
	    return " [string trimleft $rline2]"
	}
    }
}

##
 # Parse a line and extract the category and actual item text.  Each type
 # MUST have an entry in the switch.
 ##

proc bibConvert::extract_field_info {rline} {

    global bibConvertVars

    set fieldName ""
    set fieldText ""

    switch -- $bibConvertVars(bibType) {
	"hollis" {
	    set itemPos   [string first : $rline]
	    set fieldName [string range $rline 1 [expr {$itemPos - 1}]]
	    set fieldText [string range $rline [expr {$itemPos +1}] end]
	}
	"inspec2" {
	    set fieldName [string range $rline 0 14]
	    set fieldName [string trimright $fieldName " :"]
	    set fieldText [string range $rline 15 end]
	}
	"inspec3" -
	"inspec4" -
	"inspec5" -
	"inspec6" {
	    set fieldName [lindex [split $rline ":"] 0]
	    set fieldText [string range $rline [expr {1+[string length $fieldName]}] end]
	}
	"inspec7" {
	    set fieldName [lindex [split $rline "\n"] 0]
	    set fieldText [string range $rline [expr {1+[string length $fieldName]}] end]
	}
	"isi" {
	    set fieldName [lindex [split $rline " "] 0]
	    set fieldText [string range $rline [expr {1+[string length $fieldName]}] end]
	}
	"marc21" {
	    set idx1 $bibConvertVars(marcFieldIdx1)
	    set idx2 $bibConvertVars(marcFieldIdx2)
	    set idx3 $bibConvertVars(marcFieldIdx3)
	    set fieldName [string range $rline $idx1 $idx2]
	    set fieldText [string range $rline $idx3 end]
	    # Need to convert the subfield delimiter.
	    regsub -all {[@$_ à]([a-z])} $fieldText {|\1} fieldText
	    # Make sure that each fieldText starts with '|a'.
	    if {![regexp {^ *\|} $fieldText]} {set fieldText "|a $fieldText"}
	}
	"oclc1" {
	    set fieldName [string range $rline 1 13]
	    set fieldText [string range $rline 16 end]
	}
	"oclc2" {
	    set fieldName [string range $rline 0 15]
	    regsub -all {(: *)|(\([^\)]+\))}  $fieldName "" fieldName
	    set fieldText [string range $rline 16 end]
	}
	"ovid1" {
	    set fieldName [lindex [split $rline "\n"] 0]
	    set fieldText [string range $rline [expr {1+[string length $fieldName]}] end]
	}
	"refer" {
	    set fieldName [lindex [split $rline " "] 0]
	    set fieldName [string trimleft $fieldName "%"]
	    set fieldText [string range $rline [expr {1+[string length $fieldName]}] end]
	}
	"webspirs5" {
	    set itemPos   [string first : $rline]
	    set fieldName [string range $rline 0 [expr {$itemPos - 1}]]
	    regsub -all { *\(.*\) *} $fieldName "" fieldName
	    set fieldText [string range $rline [expr {$itemPos +1}] end]
	}
	default {
	    close $bibConvertVars(fileInId)
	    close $bibConvertVars(fileOutId)
	    vince_message "Unknown bib type $bibConvertVars(bibType)" 1
	}
    }
    set fieldName [string toupper [string trim $fieldName]]
    regsub -all "\[\t \]+"     $fieldName "_" fieldName
    regsub -all "\[\r\n\t \]+" $fieldText " " fieldText
    return [list [string trim $fieldName] [string trim $fieldText]]
}

proc bibConvert::make_item {rec fieldName fieldText} {

    if {![string length $fieldName]} {
	return
    } elseif {[set fieldText [string trimright $fieldText ";"]] == ""} {
        return
    }

    global bibConvertVars
    set bibType $bibConvertVars(bibType)
    global bibConvert::${bibType}_map bibConvertVars

    upvar 1 $rec a
    set maps bibConvert::${bibType}_map

    if {![info exists ${maps}($fieldName)]} {
	# We don't know how to map this.
	set fieldName [string toupper $fieldName]
    } else {
        set fieldName [set ${maps}($fieldName)]
    }
    # Allows for multiple author fields, e.g., as in refer files.
    if {[info exists a($fieldName)]} {
	append a($fieldName) " and $fieldText"
    } else {
	set a($fieldName) $fieldText
    }
}

# ×××× ------- ×××× #

# ×××× Formatting Entry Records ×××× #

##
 # We kill any fields we don't want, and maybe split some which are given
 # in sets.  Note that any fields which are still UPPER_CASE at the end
 # of this procedure will be deleted.
 ##

proc bibConvert::reformat_records {rec} {
    
    global bibConvertVars
    
    upvar 1 $rec a
    
    set entryType "misc"
    
    switch -- $bibConvertVars(bibType) {
	"hollis" {
# 	    # ×××× hollis ×××× #
	    
	    # Trying to figure out a proper type is very difficult.
	    set entryType "book"
	    # Do some fancy footwork to manipulate the names.
	    if {[info exists a(AUTHOR)]} {
		# Use this preferentially.
		set authorList $a(AUTHOR)
	    } elseif {[info exists a(AUTHORS)]} {
		set authorList $a(AUTHORS)
	    }
	    if {[info exists authorList]} {
		# Remove anything in '()' (usually an address).
		regsub -all {\([^\(\)]*\)} $authorList {} authorList
		set authors ""
		foreach author [split $authorList \\ ] {
		    set names [split $author ","]
		    if {[llength $names] > "2"} {
			# Probably a name with extra info.
			set names [lrange $names 0 1]
		    }
		    if {[llength [lindex $names 0]] > 5} {
			# Probably not a name.
			continue
		    } elseif {[llength $names] > 1} {
			set last   [lindex $names 0]
			set first  [lrange $names 1 end]
			set author [join [concat $first $last]]
		    } else {
			set author $names
		    }
		    # Get rid of annoying unnecessary periods.
		    regsub -all {([a-zA-Z][a-zA-Z])\.} $author {\1} author
		    lappend authors $author
		}
		set a(author) [join $authors " and "]
	    }
	    # Try to split up the address and publisher.
	    if {[info exists a(publisher)]} {
		regsub {,[^,]+[0-9]+\.$} $a(publisher) "" publisher
		set args      [split $publisher ":"]
		set address   [string trim [lindex $args 0]]
		set address   [lindex [split $address ";"] 0]
		set publisher [string trim [lindex $args 1]]
		set a(address) $address
		set a(publisher) $publisher
	    }
	    # Now get rid of all of those annoying slashes.
	    foreach field [array names a] {
		regsub -all "\\\\" $a($field) "/ " a($field)
	    }
	}
	"inspec2" {
	    if {[info exists a(author)]} {
		# Remove anything in '()' (usually an address).
		regsub -all {\([^\(\)]*\)} $a(author) {} authorList
		set authors ""
		foreach author [split $authorList "."] {
		    if {$author == ""} {continue}
		    set name [split $author "-"]
		    set last [lindex $name 0]
		    set rest [lrange $name 1 end]
		    lappend authors [join [concat $last $rest]]
		}
		set a(author) [join $authors " and "]
	    }
	}
	"oclc1" -
	"inspec3" -
	"inspec5" -
	"inspec6" -
	"inspec7" {
	    # If it's in a journal, we need to extract vol, number and
	    # pages.
	    if {[info exists a(journal)]} {
		regsub -all {\([^0-9]+\)} $a(journal) "" a(journal)
		# We split it with 'vol.'  and 'p.'  and grab the smaller
		# start of the two.
		set p1 [string first " vol." $a(journal)]
		if {$p1 < 0} {
		    set p1 [string first " vol " $a(journal)]
		}
		set p2 [string first " p." $a(journal)]
		if {$p2 < 0} {
		    set p2 [string first " pp." $a(journal)]
		}
		if {$p2 < 0} {set p2 1000}
		
		if {$p1 == $p2} {
		    # Both not found; currently do nothing.
		} else {
		    if {$p1 == -1} {
			set p $p2
			set j [string range $a(journal) [expr {$p +1}] end]
			set a(journal) [string range $a(journal) 0 [expr $p -2]]
			set j [split $j ,]
		    } else {
			if {$p1 < $p2} {
			    set p $p1
			} else {
			    set p $p2
			}
			set j [string range $a(journal) [expr $p +1] end]
			set a(journal) [string range $a(journal) 0 [expr $p -2]]
			set j [split $j ,]
		    }
		    set l [llength $j]
		    # Sometimes we aren't given a number so we insert a blank.
		    if {$l == 2} {
			set j [linsert $j 1 "."]
			incr l
			set p [lindex $j 2]
			if {[string first "p." $p] < 0} {
			    set j [lreplace $j 2 2 p.${p}]
			}
		    }
		    # Now extract vol, number and page from the last three.
		    #set j [lrange $j [expr $l -2] $l]
		    if {![info exists a(volume)]} {
			set a(volume) [bibConvert::extract_vnp [lindex $j 0] "."]
		    }
		    if {![info exists a(number)]} {
			set a(number) [bibConvert::extract_vnp [lindex $j 1] "."]
		    }
		    if {![info exists a(pages)]} {
			set a(pages) [bibConvert::extract_vnp [lindex $j 2] "p."]
		    }
		    
		    # Now journal may end in a month and year!
		    # (esp Inspec 3,6)
		    set a(journal) [string trim $a(journal)]
		    if {[set jj [string first "\(" $a(journal)]] != -1} {
			set rest [string range $a(journal) $jj end]
			set a(journal) [string range $a(journal) 0 [expr $jj -1]]
			set rest [string trim $rest "() "]
			if {[string match {*[1-9][0-9][0-9][0-9]} $rest]} {
			    set lrest [llength $rest]
			    set a(year) [lindex $rest [expr $lrest -1]]
			    set a(month) [lindex $rest [expr $lrest -2]]
			}
		    } else {
			
			set l [string length $a(journal)]
			set e [string range $a(journal) [expr $l -4] end]
			if {[string match {[1-9][0-9][0-9][0-9]} $e]} {
			    # It ends in a year.
			    set a(year) $e
			    set p [string last "," $a(journal)]
			    set my [string range $a(journal) $p end]
			    set a(journal) [string range $a(journal) 0 [expr $p -1]]
			    set l [string length $my]
			    set a(month) [string trim [string range $my 1 [expr $l -5]]]
			} else {
			    # 'j' above may end in a year.
			    set j [string trim [lindex $j end] " ."]
			    regsub -all {[ .]+} $j " " j
			    regexp {(([1-9][0-9]* )?[A-Za-z]+) ([1-9][0-9][0-9][0-9])$} $j \
			      "" a(month) "" a(year)
			}
			
		    }
		    
		}
	    }
	    # We're only interested if it's a conference proceedings.
	    if {[info exists a(CONF_LOCATION)]} {
		set entryType "inproceedings"
	    } else {
	        set entryType "article"
	    }
	}
	"inspec4" {
	    # If it's in a journal, we need to extract vol, number and
	    # pages.
	    if {[info exists a(journal)]} {
		# We split it with 'vol.'  and 'p.'  and grab the smaller
		# start of the two.
		set s [split $a(journal) "\n"]
		set a(journal) [lindex $s 0]
		for {set i 1} {$i <= [llength $s]} {incr i} {
		    set l [bibConvert::extract_field_info [lindex $s $i]]
		    eval bibConvert::make_item a $l
		}
	    }
	    
	    if {[info exists a(volume)]} {
		set p [string first "Iss:" $a(volume)]
		if {$p > 0} {
		    set a(number) [string range $a(volume) [expr $p +4] end]
		    set a(volume) [string range $a(volume) 0 [expr $p -1]]
		}
	    }
	    
	    if {[info exists a(number)]} {
		set p [string first "p." $a(number)]
		if {$p > 0} {
		    set a(pages) [string range $a(number) [expr $p +2] end]
		    set a(number) [string range $a(number) 0 [expr $p -1]]
		}
	    }
	    # We're only interested if it's a conference proceedings.
	    if {[info exists a(CONF_LOCATION)]} {
		set entryType "inproceedings"
	    } else {
		set entryType "article"
	    }
	}
	"isi" {
# 	    # ×××× isi ×××× #
	    
	    # Fix the author field.
	    if {[info exists a(author)]} {
		# Concatenate author names (Smith,A Jones,B etc)
		regsub -all ", " $a(author) "," authorList
		set authors ""
		foreach author [split [string trim $authorList] " "] {
		    # Figure out the last name, abbreviate the first.
		    if {$author == ""} {continue}
		    set name  [split $author ","]
		    set first ""
		    set last  [lindex $name 0]
		    foreach char [split [lrange $name 1 end] ""] {
			append first "${char}. "
		    }
		    lappend authors [join [concat $first $last]]
		}
		set a(author) [join $authors " and "]
	    }
	    # Fix the pages.
	    if {[info exists a(EP)]} {
		if {[info exists a(pages)]}	{
		    set	a(EP) [string trim $a(EP)]
		    set	a(pages) [string trim $a(pages)]
		    if {$a(pages) != $a(EP)} {
			set a(pages) "$a(pages)--$a(EP)"
		    }
		} else {
		    # I	know of	no reason for this to ever happen, but...
		    set	a(pages) $a(EP)
		}
	    }
	    # Fix the key.
	    if {[info exists a(DE)]} {
		if {[info exists a(key)]} {
		    append a(key) "; $a(DE)"
		} else {
		    set	a(key) $a(DE)
		}
	    }
	    # Fix the entry type.
	    if {[info exists a(DT)]} {
		switch -- [string tolower $a(DT)] {
		    "book review" -
		    "editorial material" -
		    "review" {set entryType "article"}
		    default  {set entryType [string tolower $a(DT)]}
		}
	    } else {
		set entryType "article"
	    }
 	}
	"marc21" {
# 	    # ×××× marc21 ×××× #
	    
	    # Set the document type.  Need to figure out what other values
	    # the 'FMT' field might take.
	    switch -- [string trim $bibConvertVars(marcEntryType)] {
		"BK"    {set entryType "book"}
		default {set entryType "book"}
	    }
	    # Determine what author(s) we have.
	    set authors [list]
	    foreach fieldName [list \
	      "MAIN_ENTRY_-_PERSONAL_NAME" \
	      "SERIES_STATEMENT/ADDED_ENTRY_-_PERSONAL_NAME" \
	      "SUBJECT_ADDED_ENTRY_-_PERSONAL_NAME" \
	      "ADDED_ENTRY_-_PERSONAL_NAME" \
	      "SERIES_ADDED_ENTRY_-_PERSONAL_NAME" \
	      ] {
		if {![info exists a($fieldName)]} {continue}
		foreach item [split $a($fieldName) "|"] {
		    if {![regexp {a} [string index $item 0]]} {continue}
		    regsub {and +} [string range $item 1 end] "" author
		    set author [split $author ","]
		    set last   [lindex $author 0]
		    set first  [lrange $author 1 end]
		    # Get rid of annoying unnecessary periods.
		    set author [join [concat $first $last]]
		    regsub -all {([a-zA-Z][a-zA-Z])\.} $author {\1} author
		    # Make sure that we're not adding duplicates.
		    if {[lsearch $authors $author] == "-1"} {
			lappend authors $author
		    } 
		}
	    }
	    set a(author) [join $authors " and "]
	    # Fix the isbn, issn, lccn, fields.
	    foreach fieldName [list \
	      "INTERNATIONAL_STANDARD_BOOK_NUMBER" \
	      "INTERNATIONAL_STANDARD_SERIAL_NUMBER" \
	      "LIBRARY_OF_CONGRESS_CALL_NUMBER"] {
		if {![info exists a($fieldName)]} {continue}
		foreach item [split $a($fieldName) "|"] {
		    if {![regexp {a|b} [string index $item 0]]} {continue}
		    regsub {: *} [string range $item 1 end] "" fieldText
		    switch $fieldName {
			"INTERNATIONAL_STANDARD_BOOK_NUMBER"   {
			    append a(isbn) " $fieldText"
			}
			"INTERNATIONAL_STANDARD_SERIAL_NUMBER" {
			    append a(issn) " $fieldText"
			}
			"LIBRARY_OF_CONGRESS_CALL_NUMBER"      {
			    append a(lccn) " $fieldText"
			}
		    }
		}
	    } 
	    # Figure out the title.
	    foreach fieldName [list \
	      "MAIN_ENTRY_-_UNIFORM_TITLE" \
	      "TITLE_STATEMENT" \
	      "UNIFORM_TITLE" \
	      "KEY_TITLE" \
	      "TRANSLATION_OF_TITLE_BY_CATALOGING_AGENCY" \
	      "VARYING_FORM_OF_TITLE" \
	      "FORMER_TITLE" \
	      "FORMER_TITLE_OR_TITLE_VARIATIONS" \
	      ] {
		if {![info exists a($fieldName)]} {continue}
		foreach item [split $a($fieldName) "|"] {
		    if {![regexp {a|b} [string index $item 0]]} {continue}
		    append title " [string range $item 1 end]"
		}
		if {[info exists title]} {
		    regsub -all { +:}        $title {:} title
		    regsub -all { *[/.,]+ *$} $title {}  a(title)
		    break
		} 
	    }
	    # Sort out the publication information.
	    if {[info exists a(PUBLICATION,_DISTRIBUTION,_ETC.)]} {
		foreach item [split $a(PUBLICATION,_DISTRIBUTION,_ETC.) "|"] {
		    set fieldText [string trimright [string range $item 1 end]]
		    if {[regexp {a} [string index $item 0]]} {
			regsub { *(;|:|,)$} $fieldText "" address
			if {![info exists a(address)]} {
			    set a(address) $address
			} else {
			    append a(address) " ; $address"
			}
		    } elseif {[regexp {b} [string index $item 0]]} {
			regsub { *,$} $fieldText "" publisher
			set a(publisher) $publisher
		    } elseif {[string index $item 0] == "c"} {
			regsub { *\.$} $fieldText "" year
			set a(year) $year
		    }
		}
	    } 
	    # Fix the language field.
	    if {[info exists a(LANGUAGE_NOTE)]} {
		foreach item [split $a(LANGUAGE_NOTE) "|"] {
		    set fieldText [string trimright [string range $item 1 end]]
		    if {![regexp {a} [string index $item 0]]} {continue}
		    append a(language) " $fieldText"
		}
	    }
	    # Fix the key.
	    if {[info exists a(SUBJECT_ADDED_ENTRY_-_TOPICAL_TERM)]} {
		regsub -all { and \|} $a(SUBJECT_ADDED_ENTRY_-_TOPICAL_TERM) "|" subjects
		foreach item [split $subjects "|"] {
		    set key [string trimright [string range $item 1 end]]
		    regsub {\.$} $key "" key
		    if {[string index $item 0] != "a"} {continue}
		    if {![info exists a(key)]} {
			set a(key) $key
		    } else {
			append a(key) " ; $key"
		    }
		}
	    }
	    # Do we have a table of contents?
	    if {[info exists a(FORMATTED_CONTENTS_NOTE)]} {
		regsub -all { and \|a (\(cont\.\))?} $a(FORMATTED_CONTENTS_NOTE) "|a " contents
		foreach item [split $contents "|"] {
		    if {![regexp {a} [string index $item 0]]} {continue}
		    append a(contents) " [string range $item 1 end]"
		}
	    } 
	    # Do we have a note?
	    # GENERAL_NOTE
	    if {[info exists a(GENERAL_NOTE)]} {
		regsub -all { and \|} $a(GENERAL_NOTE) "|" notes
		foreach item [split $notes "|"] {
		    if {![regexp {a} [string index $item 0]]} {continue}
		    append a(note) " [string range $item 1 end]"
		}
	    } 
	    # Do we have an abstract?
	    if {[info exists a(SUMMARY,_ETC.)]} {
		regsub -all { and \|} $a(SUMMARY,_ETC.) "|" abstract
		foreach item [split $abstract "|"] {
		    if {![regexp {a} [string index $item 0]]} {continue}
		    append a(abstract) " [string range $item 1 end]"
		}
	    } 
	    # Is this a dissertation?
	    if {[info exists a(DISSERTATION_NOTE)]} {
		regsub -all { and \|} $a(DISSERTATION_NOTE) "|" note
		foreach item [split $note "|"] {
		    if {![regexp {a} [string index $item 0]]} {continue}
		    set note [string trimright [string range $item 1 end]]
		    regsub {\.$} $note "" note
		    append a(note) " $note"
		}
		if {[info exists a(note)]} {
		    if {[regexp {Ph[ .]*D} $a(note)]} {
		        set entryType "phdthesis"
		    } else {
		        set entryType "mastersthesis"
		    }
		} 
	    }
	}
	"oclc2" {
# 	    # ×××× oclc2 ×××× #
	    
	    # Set the document type.
	    set entryType "book"
	    if {[info exists a(TYPE)]} {
		set entryType [string tolower $a(TYPE)]
	    } 
	    # Fix the author field.
	    if {[info exists a(author)]} {
		# Remove anything in '()' (usually an address).
		regsub -all {\([^\(\)]*\)} $a(author) {} authorList
		# Remove all dates.
		regsub -all {[0-9]+\-[0-9]*} $authorList {} authorList
		set authors ""
		foreach author [split $authorList "\;" ] {
		    if {[regexp {joint author} $author]} {
			continue
		    } elseif {![string length [string trim $author]]} {
			continue
		    }
		    set names  [split $author ","]
		    set last   [lindex $names 0]
		    set first  [lrange $names 1 end]
		    set author [join [concat $first $last]]
		    # Get rid of annoying unnecessary periods.
		    regsub -all {([a-zA-Z][a-zA-Z])\.} $author {\1} author
		    lappend authors $author
		}
		set a(author) [join $authors " and "]
	    }
	    # Fix the title.
	    if {[info exists a(title)]} {
		regsub -all " */ *$" $a(title) ""  title
		regsub -all " +:"    $title    ":" a(title)
	    } 
	    # Fix the publisher (adding address)
	    if {[info exists a(publisher)]} {
		set pubInfo [split $a(publisher) ":"]
		set a(address) [lindex $pubInfo 0]
		regsub ", *$"  [join [lrange $pubInfo 1 end]] "" a(publisher)
	    } 
	    # If an article, try to figure out journal, date, etc.
	    if {$entryType == "article" && [info exists a(IN)]} {
		# This is a big mess.  Put it all in 'journal'.
		set a(journal) $a(IN)
		if {[info exists a(DESCRIPTION)]} {
		    set pages [lindex [split $a(DESCRIPTION) ";"] 0]
		    if {[regsub {^p. +} $pages "" pages]} {
		        set a(pages) $pages
		    } 
		} 
	    } 
	    # Clean up the key.
	    if {[info exists a(key)]} {
	        regsub {; *$} [concat [join [split $a(key) "."] " ; "]] "" a(key)
	    } 
	    # Sort 'standard no.' and 'CLASS_DESCRPT' fields.
	    if {[info exists a(STANDARD_NO)]} {
		append numberSets " ; $a(STANDARD_NO)"
	    }
	    if {[info exists a(CLASS_DESCRPT)]} {
		# The lccn here might be truncated to a broader class ...
		append numberSets " ; $a(CLASS_DESCRPT)"
	    }
	    if {[info exists numberSets]} {
		foreach numberSet [split $numberSets ";"] {
		    set numbers [string toupper [split $numberSet ":"]]
		    switch -- [string trim [lindex $numbers 0]] {
			"ISBN" {set a(isbn) [lindex $numbers 1]}
			"ISSN" {set a(issn) [lindex $numbers 1]}
			"LC"   {set a(lccn) [lindex $numbers 1]}
		    }
		} 
	    } 
	}
	"ovid1" {
	    # This is the original, which seems to be outdated and is no
	    # longer being actively maintained.
	    
	    # If it's in a journal, we need to extract vol, number and
	    # pages.
	    if {[info exists a(journal)]} {
		regsub -all {\([^0-9]+\)}  $a(journal) ""  a(journal)
		# Split into journal name and volume info
		set js [split $a(journal) .]
		# Split volume info into chunks.
		set j [split [lindex $js 1] ,]
		
		# Apa kindof looks like this:
		# Name. Vol vol(num), month year, pages.
		set a(journal) [string trim [lindex $js 0]]
		
		# The chunks and how many of 'em.
		set l [llength $j]
		set v [string trim [lindex $j 0]]
		set e [string trim [lindex $j 1]]
		if {$l == 3} {set pp [string trim [lindex $j 2]]}
		
		# First is the volume field, tends to be in one of three
		# formats:
		#
		#   raw number:   62
		#   vol indica:   Vol 32
		#   no indica:    No 43
		#   vol no:       Vol 43(2)
		#
		# Yes, yes, i'm not entirely sure what is up here...  ok,
		# ok, yes stop torturing me.  i'm sorry, can't that just be
		# enough for you?
		if {![info exists a(volume)] || ![info exists a(number)]} {
		    switch  -regexp $v {
			{([0-9]+)\(([0-9]+)\)} {regexp {([0-9]+)\(([0-9]+)\)} $v poo a(volume) a(number)}
			{[Vv].*} {regexp {([0-9]+)} $v poo a(volume)}
			{[Nn].*} {regexp {([0-9]+)} $v poo a(number)}
			default  {regexp {([0-9]+)} $v poo a(number)}
		    }
		}
		if {![info exists a(pages)] && $l == 3} {
		    set a(pages) $pp
		}
		
		if {[string match {[1-9][0-9][0-9][0-9]} $e]} {
		    # It ends in a year.
		    set a(year) $e
		} else {
		    # 'j' above may end in a year.
		    set pat {(([1-9][0-9]* )?[A-Za-z]+) ([1-9][0-9][0-9][0-9])$}
		    regexp $pat $e "" a(month) "" a(year)
		}
	    }
	    set entryType "article"
	    # We're only interested if it's a conference proceedings.
	    if {[info exists a(CONF_LOCATION)]} {
		set entryType "inproceedings"
	    } else {
	        set entryType "article"
	    }
	}
	"refer" {
# 	    # ×××× refer ×××× #
	    
	    # Deal with that first field.
	    bibConvert::make_item a \
	      [lindex $bibConvertVars(referFirstField) 0] \
	      [lindex $bibConvertVars(referFirstField) 1]
	    if {[info exists a(TYPE)]} {
		switch -- [string tolower [string trim $a(TYPE)]] {
		    "book"                   {set entryType "book"}
		    "book section"           {set entryType "incollection"}
		    "conference proceedings" {set entryType "conference"}
		    "edited book"            {set entryType "book"}
		    "generic"                {set entryType "misc"}
		    "journal article" -
		    "magazine article" -
		    "newspaper article"      {set entryType "article"}
		    "report"                 {set entryType "techreport"}
		}
	    }
	    # This deals with refer/endnote inconsistencies.
	    if {$entryType == "book"} {
		if {[info exists a(booktitle)] && ![info exists a(title)]} {
		    set a(book) $a(booktitle)
		    unset a(booktitle)
		} 
	    } elseif {$entryType == "article"} {
		if {[info exists a(booktitle)] && ![info exists a(journal)]} {
		    set a(journal) $a(booktitle)
		    unset a(booktitle)
		} 
	    }
	    # Parse out "customField2" fields.  Alpha's "Bib To Refer" package
	    # will save the original field information as something like
	    # 
	    # %2 institution=...
	    # 
	    # which is a somewhat arbitrary construction but will allow us to
	    # convert the data into the proper field.
	    set pat1 {^([a-zA-Z]+)=($|[^\s].*$)}
	    set pat2 {and ([a-zA-Z]+=($|[^\s].*$))}
	    while {[info exists a(customField2)]} {
		if {![string length $a(customField2)]} {
		    unset a(customField2)
		    break
		} elseif {![regexp -- $pat1 $a(customField2) all field data]} {
	            break
	        } 
		if {![regsub -- $pat2 $data "" fieldData]} {
		    set fieldData $data
		    set theRest ""
		} else {
		    regexp -- $pat2 $data all theRest
		}
		if {[info exists a($field)]} {
	            append a($field) " and $fieldData"
	        } else {
	            set a($field) $fieldData
	        }
		set a(customField2) [string trim $theRest]
	    }
	}
	"webspirs5" {
# 	    # ×××× webspirs5 ×××× #
	    
	    # First clean up the author field.
	    if {[info exists a(author)]} {
		# Remove anything in '()' (usually an address).
		regsub -all {\([^\(\)]*\)} $a(author) {} authorList
		set authors ""
		foreach author [split $authorList ";"] {
		    regsub -all -- "-" $author " " author
		    set names [split $author ","]
		    set last   [lindex $names 0]
		    set first  [lrange $names 1 end]
		    lappend authors [join [concat $first $last]]
		}
		set a(author) [join $authors " and "]
	    }
	    if {[info exists a(SOURCE)]} {
		# If it's in a journal, we need to extract vol, number and
		# pages.  Seems to be pretty standard now:
		#
		#   Journal-Name; Year, Volume, Number, Month, Pages.
		#
		# so we'll try to add info as necessary.
		
		set jArgs [string trimright [string trim $a(SOURCE)] "."]
		# Split into journal name and volume info
		set jSplit [split $jArgs ";"]
		# Get the name of the journal
		if {![info exists a(journal)]} {
		    set a(journal) [lindex $jSplit 0]
		}
		# Split volume info into chunks,
		set jInfo  [split [lindex [string trimright $jSplit "."] 1] ,]
		# ... get the year and deal with the rest.
		set year [lindex $jInfo 0]
		set pat1 "\[-0-9\]+"
		set pat2 "\[a-zA-Z\]+"
		
		if {[llength $jInfo] == "5"} {
		    # if the second half of the 'SOURCE' field is a list of
		    # length of 5 and each item in the list is numeric
		    # _except_ for the fourth we'll assume that this is the
		    # standard format described above..
		    if {[regexp $pat1 [lindex $jInfo 1]] && \
		      [regexp $pat1 [lindex $jInfo 2]]   && \
		      [regexp $pat2 [lindex $jInfo 3]]   && \
		      [regexp $pat1 [lindex $jInfo 4]]      } {
			set volume [lindex $jInfo 1]
			set number [lindex $jInfo 2]
			set month  [lindex $jInfo 3]
			set pages  [lindex $jInfo 4]
		    }
		} elseif {[llength $jInfo] == "4"} {
		    # Same as above, but no 'month' ??
		    if {[regexp $pat1 [lindex $jInfo 1]] && \
		      [regexp $pat1 [lindex $jInfo 2]]   && \
		      [regexp $pat1 [lindex $jInfo 3]]      } {
			set volume [lindex $jInfo 1]
			set number [lindex $jInfo 2]
			set pages  [lindex $jInfo 3]
		    }
		} elseif {[llength $jInfo] == "3"} {
		    # Same as above, but no 'month' or 'number' ??
		    if {[regexp $pat1 [lindex $jInfo 1]] && \
		      [regexp $pat1 [lindex $jInfo 2]]      } {
			set volume [lindex $jInfo 1]
			set pages  [lindex $jInfo 2]
		    }
		}
		# Now we convert if no other fields added them.
		foreach field [list year volume number pages month] {
		    if {[info exists $field] && ![info exists a($field)]} {
			set a($field) [set $field]
		    }
		}
		if {![info exists a(volume)]} {
		    # All of the above must have failed.
		    set volume $jInfo
		}
	    }
	    # Do we have an entry type?
	    if {[info exists a(TYPE)]} {
		regsub -all { } [string toupper $a(TYPE)] {-} type
		switch -regexp -- $type {
		    "ABSTRACT-OF-JOURNAL-ARTICLE" {set entryType "article"}
		    "ASSOCIATION-PAPER"           {set entryType "unpublished"}
		    "BOOK-ABSTRACT"               {set entryType "book"}
		    "BOOK-CHAPTER-ABSTRACTS"      {set entryType "book"}
		    "BOOK-REVIEW"                 {set entryType "article"}
		    "DISSERTATION"                {set entryType "phdthesis"}
		    "FILM-REVIEW"                 {set entryType "article"}
		    "SOFTWARE-REVIEW"             {set entryType "article"}
		}
	    } elseif {[info exists a(journal)]} {
		set entryType "article"
	    }
	    # Clean up the journal name
	    if {[info exists a(journal)]} {
		regsub -all -- "-" $a(journal) " " a(journal)
	    } 
	    # Clean up the key
	    if {[info exists a(key)]} {
		set pat1 {\*|(\([^\)]*\))}
		set pat2 {- +}
		set pat3 { +-}
		regsub -all -- $pat1 $a(key) ""  a(key)
		regsub -all -- $pat2 $a(key) " " a(key)
		regsub -all -- $pat3 $a(key) "-" a(key)
	    } 
	}
    }
    # Clean up remaining fields.
    foreach fieldName [array names a] {
	if {[string toupper $fieldName] == $fieldName} {
	    unset a($fieldName)
	} 
    }
    if {[info exists a(pages)]} {regsub -all "\[\t \]+" $a(pages) "" a(pages)}
    # Do some clever capitalization.
    foreach fieldName [list "address" "author" "booktitle" "editor" \
      "institution" "journal" "language" "month"  "publisher" \
      "series" "title"] {
	if {[info exists a($fieldName)]} {
	    set a($fieldName) [bibConvert::capitalize_string $a($fieldName)]
	} 
    }
    # Did we do this already?
    regsub -all "\[\t \]+" $entryType "" entryType
    return $entryType
}

##
 # Utility procedures used by the above
 ##

proc bibConvert::extract_vnp {str prefix} {

    set p [string first $prefix $str]
    if {$p == -1} {
	return ""
    } else {
	return [string range $str [expr $p + [string length $prefix]] end]
    }
}

proc bibConvert::capitalize_string {str} {
    
    if {![catch {bibConvert::_capitalize_string $str} result]} {
        return $result
    } else {
        return $str
    }
}

proc bibConvert::_capitalize_string {str} {
    
    global bibConvertVars

    # Deal with isolated ':', ':'
    regsub -all "\[\t \]+(:|;)\[\t \]+" $str "\\1 " str
    # If the string is ALL CAPS, assume that this isn't intended and make
    # the string lower case first.
    if {[string toupper $str] == $str} {
	set str [string tolower $str]
    } else {
	# Protect ALL CAP words. 
	set pat "(^|\[\r\n\t \])(\[A-Z\]\[A-Z\]+)($|\[\r\n\t \])"
	regsub -all $pat $str "\\1\{\\2\}\\3" str
    }

    # These will only be capitalized if at the beginning of the string, or
    # just after a ':' or ';' (denoted by the 'start' var).
    set lower $bibConvertVars(forceLower)
    # These are special cases defined by the user.
    foreach pair $bibConvertVars(specialPatterns) {
	set specialPats([lindex $pair 0]) [lindex $pair 1]
    }

    # 'parts1' will be the entire string split by ";"
    set parts1 [list]
    foreach part1 [split $str ";"] {
	# 'parts2' will be each part1 section split by ":"
	set parts2 [list]
	foreach part2 [split $part1 ":"] {
	    set start 1
	    # 'parts3' will be each part2 section split by " ", so this
	    # should be each word.
	    set parts3 [list]
	    foreach part3 [split $part2 " "] {
		# 'parts4' will be each word split by "-"
		set parts4 [list]
		foreach part4 [split $part3 "-"] {
		    # Is it an acronym?
		    if {[regexp {^([a-zA-Z]\.)+$} $part4]} {
			# If so, make it A.L.L.C.A.P.S.
			set part4 [string toupper $part4]
		    }
		    # Almost ready ... special "l'Ancien" case.
		    set l [regsub {^[lL]'} $part4 "" part4]
		    # ... remove any leading brackets, etc.
		    set pat1 {^([^a-zA-Z]*)([a-zA-Z]*)([^a-zA-Z]*)$}
		    set pre  [set post ""]
		    regexp $pat1 $part4 allofit pre part4 post
		    # Deal with special patterns first.
		    foreach pattern [array names specialPats] {
			set subString $specialPats($pattern)
			if {[regsub "^$pattern" $part4 $subString part4]} {
			    break
			} 
		    }
		    # Now capitalize the word.  Maybe.
		    if {![regexp {^[a-z]+$} $part4] || [regexp {\\\{} $pre]} {
			# Not a lower case string, or there's an escape
			# char which might be a TeX markup tag, or it is
			# otherwise protected.
			set first $part4 ; set rest ""
		    } elseif {!$start && [lsearch $lower $part4] != "-1"} {
			# A special lower case string, and we're not at the
			# start of the line or a clause.
			set first $part4 ; set rest ""
		    } else {
			# All special cases done, capitalize the word.
			set first [string toupper [string index $part4 0]]
			set rest  [string tolower [string range $part4 1 end]]
		    }
		    # Now deal with "l'Ancien" type constructions.
		    if {$l} {
			if {$start} {
			    set pre "L'$pre"
			} else {
			    set pre "l'$pre"
			}
		    }
		    set start 0
		    lappend parts4 ${pre}${first}${rest}${post}
		}
		lappend parts3 [join $parts4 "-"]
	    }
	    lappend parts2 [join $parts3 " "]
	}
	lappend parts1 [join $parts2 ":"]
    }
    set result [join $parts1 ";"]
}

##
 # Try and do something intelligent with lists of multiple authors.
 # Returns a tag with the surname of the each author (for the bibtex
 # tag), or just the surname of the first author.  We assume that the
 # field has already been converted to something like
 #
 #   "Paul J. DiMaggio and Sharon Zukin"
 #
 # in "bibConvert::reformat_records"
 ##

proc bibConvert::parse_author {rec} {

    global bibConvertVars

    upvar 1 $rec a

    if {![info exists a(author)] || ![string length $a(author)]} {
	return "??"
    } else {
	# Remove anything in '()' (usually an address).
	# This might have been done already, but some insurance.
	regsub -all {\([^\(\)]*\)} $a(author) {} a(author)
    }
    set authorTag ""
    regsub -all " and " $a(author) "|" authors
    set authors [split $authors "|"]
    switch -- $bibConvertVars(authorTag) {
	"First Author's Surname" {
	    append authorTag [lindex [lindex $authors 0] end]
	}
	"Each Author's Surname" {
	    foreach author $authors {
		append authorTag [lindex $author end]
	    }
	}
	"3 + Authors 'Et Al'" {
	    if {[llength $authors] > "2"} {
		append authorTag "[lindex [lindex $authors 0] end]EtAl"
	    } else {
		foreach author $authors {
		    append authorTag [lindex $author end]
		}
	    }
	}
	"4 + Authors 'Et Al'" {
	    if {[llength $authors] > "3"} {
	        append authorTag "[lindex [lindex $authors 0] end]EtAl"
	    } else {
		foreach author $authors {
		    append authorTag [lindex $author end]
		}
	    }
	}
    }
    regsub -all " +" $authorTag "" authorTag
    return $authorTag
}

proc bibConvert::parse_year {rec} {

    global bibConvertVars

    upvar 1 $rec a

    if {![info exists a(year)]} {
	return "??"
    } else {
	regexp {([1-9]?[0-9]?[0-9][0-9])} $a(year) a(year)
    }
    if {[string length $a(year)] == "4" && $bibConvertVars(truncateYear)} {
        return [string range $a(year) 2 3]
    } else {
        return $a(year)
    }
}

##
 # Format a field with its non-empty text.
 ##

proc bibConvert::format_field {rec fieldName} {

    global bibConvertVars

    upvar 1 $rec a

    if {![info exists a($fieldName)]} {
	return
    } elseif {![string length [set fieldText $a($fieldName)]]} {
	return
    }
    # Are we remapping this field?
    if {[info exists bibConvertVars(${fieldName}Remap)]} {
	# Global redirection of field mappings.
	set pref $bibConvertVars(${fieldName}Remap)
	if {[regexp {'([^']+)'} $pref allofit newFieldName]} {
	    set fieldName $newFieldName
	} else {
	    # No remapping given, so probably 'ignored' is the value.
	    return
	}
    }

    # Determine the pad.
    set spc "                             "
    set pad [string range $spc 1 \
      [expr {$bibConvertVars(longestField) - [string length $fieldName]}]]

    # Convert formatting information, funny chars to latex
    regsub -all {/sub ([^/]+)/} $fieldText "_\{\\1\}" fieldText
    regsub -all {/sup ([^/]+)/} $fieldText "^\{\\1\}" fieldText
    regsub -all "\[ \t\r\n\]+" [string trim $fieldText] " " fieldText
    regsub -all {(([^A-Z@]|\\@)[.?!]("|'|'')?([])])?) } $fieldText {\1  } fieldText
    regsub -all {\&} $fieldText {\\\&} fieldText
    # Fill the text.
    bibConvert::breakintolines fieldText

    set openItem  $bibConvertVars(openItem)
    set closeItem $bibConvertVars(closeItem)

    set result "$bibConvertVars(bibIndent)$fieldName"
    if {$bibConvertVars(alignEquals)} {
        append result "$pad = "
    } else {
        append result " = $pad"
    }
    append result "${openItem}${fieldText}${closeItem},"
    return $result
}

proc bibConvert::breakintolines {t} {

    global vince_usingAlpha bibConvertVars

    set fc [expr {$bibConvertVars(maxLineLength) - \
      [string length $bibConvertVars(multiIndent)]}]
    upvar 1 $t text
    # What if it's really big?
    if {[string length $text] > $fc} {
	if {$vince_usingAlpha} {
	    # Break and indent the paragraph.
	    regsub -all "\[\n\r\]" \
	      "[string trimright [breakIntoLines $text $fc 0]]" \
	      "\r$bibConvertVars(multiIndent)" text
	} else {
	    # Do it by hand!
	    while {[string length $text] > $fc} {
		set f [string last " " [string range $text 0 $fc]]
		if {$f == -1} {
		    vince_message "Have a word > $fc letters long.  It will be broken."
		    set f $fc
		}
		append a "[string range $text 0 $f]\n$bibConvertVars(multiIndent)"
		set text [string range $text [incr f] end]
	    }
	    append a $text
	    set text $a
	}
    }
}

# ×××× -------- ×××× #

# These last two are specific to using this package in Alpha.

proc bibConvert::start_dialog {} {
    
    global vince_usingAlpha bibConvertVars bibConvert::types \
      Bib::Fields BibmodeVars
    
    if {!$vince_usingAlpha} {return}

    # We're using Alpha, so we're going to be more sophisticated here about
    # selections, and the output will be saved in a temp file and dealt
    # with later.  No need to upvar or return values here because all of
    # the relevant info should already be in the 'bibConvertVars' and we're
    # just sneaking some new information in there before scanning.
    
    # These prefs are only used in these two Alpha-specific procs.
    if {![info exists bibConvertVars(insertAction)]} {
	set bibConvertVars(insertAction) "Create New Window"
    } 
    if {![info exists bibConvertVars(tempFileCount)]} {
	set bibConvertVars(tempFileCount) 0
	# Save these prefs between editing sessions.  If we're setting
	# the 'tempFileCount' for the first time, we know that these have
	# not yet been added to the 'modified' list.
	foreach pref [list "insertAction" "lastBibType" "truncateYear" \
	  "authorTag" "abstractRemap" "excludeFields"] {
	    prefs::modified bibConvertVars($pref)
	}
	foreach pref [list "autoCapForceLower" "autoCapSpecialPatterns"] {
	    prefs::modified BibmodeVars($pref)
	}
    } 
    
    set d 1
    set d$d [list dialog::make -title "Convert To Bib"]

    set count   [incr bibConvertVars(tempFileCount)]
    set tempDir [temp::directory bibConvert]
    set winTail [win::StripCount [win::CurrentTail]]
    set suffix  [string tolower [string trimleft [file extension $winTail] "."]]
    set bibConvertVars(fileOut)  [file join $tempDir temp${count}.bib]
    set bibConvertVars(saveName) [file rootname $winTail]
    
    # Make sure that we have a valid type available for the dialog.
    if {[lsearch [set bibConvert::types] $suffix] != "-1"} {
	set bibType $suffix
    } else {
	set bibType $bibConvertVars(lastBibType)
    }
    # Get some additional options.
    if {[llength [winNames]]} {
	if {[isSelection]} {
	    # Use the selection for the temp file.
	    set windowText [getSelect]
	    # And insert options specific to location of selection.
	    set insertOptions [list "Above Selection" "Below Selection" \
	      "Replacing Selection" "-"]
	} else {
	    # Use the entire window contents for the temp file.
	    set windowText [getText [minPos] [maxPos]]
	}
	# Put the selection/window contents in a new temp file, which will
	# become the new 'fileIn' variable.
	set count    [incr bibConvertVars(tempFileCount)]
	set fileIn   [file join $tempDir temp${count}.${suffix}]
	set fileInId [alphaOpen $fileIn w]
	set bibConvertVars(fileIn) $fileIn
	puts  $fileInId $windowText
	close $fileInId
	# Add some more insert options.
	lappend insertOptions "At Beginning Of Window" "At End Of Window" "-" \
	  "Replacing Window Contents"
    } 
    lappend insertOptions "In New Window"
    if {[lsearch $insertOptions $bibConvertVars(insertAction)] == "-1"} {
	set insertAction "In New Window"
    } else {
	set insertAction $bibConvertVars(insertAction)
    }
    # Add this page of the dialog.
    incr d
    set  t1 "Original Bibliography Format:"
    set  t2 "Insert Results:" 
    set  t3 "_______________________________\rThe following pages in the dialog\
      include more options for fine-tuning the conversion format."
    lappend d$d "Basic Conversion Settings"
    lappend d$d [list text "    "]
    lappend d$d [list [list menu ${bibConvert::types}] $t1 $bibType]
    lappend d$d [list [list menu $insertOptions]       $t2 $insertAction]
    lappend d$d [list text $t3]
    lappend dP  [set d$d]
    lappend prefs "bibType" "insertAction" 

    # How should the author be handled in the citekey tag?
    set authorTag     $bibConvertVars(authorTag)
    set authorOptions [list "First Author's Surname" "Each Author's Surname" \
      "3 + Authors 'Et Al'" "4 + Authors 'Et Al'"]
    # How should the year be handled in the citekey tag?
    set truncateYear  $bibConvertVars(truncateYear)
    # Add this page of the dialog.
    incr d
    set  t1 "Citekey should include:"
    set  t2 "Strip Century in Citekey tag" 
    set  t3  "_______________________________\rThese settings, as well as\
      those in the following dialog pages will be retained for each conversion."
    lappend d$d "CiteKey Tag Settings"
    lappend d$d [list text "    "]
    lappend d$d [list [list menu $authorOptions] $t1 $authorTag]
    lappend d$d [list flag $t2 $truncateYear]
    lappend d$d [list text $t3]
    lappend dP  [set d$d]
    lappend prefs "authorTag" "truncateYear" 

    # Which words should be lower case?  Special Patterns?
    regsub -all "\[\r\n\t \]" $bibConvertVars(forceLower) " " forceLower
    set specialPatterns $bibConvertVars(specialPatterns)
    # Add this page of the dialog.
    incr d
    incr d
    set  t1 "These strings will always be lower case:"
    set  t2 "These special regexp patterns will also be converted:"
    lappend d$d "Case Settings"
    lappend d$d [list var2 $t1 $forceLower]
    lappend d$d [list var2 $t2 $specialPatterns]
    lappend dP  [set d$d]
    lappend prefs "forceLower" "specialPatterns"

    # How should we handle abstracts?
    set abstractRemap   $bibConvertVars(abstractRemap)
    set abstractOptions [list "Included in 'annote' field" \
      "Included in 'abstract' field" "Ignored"]
    # How should we handle tables of content?
    set contentsRemap   $bibConvertVars(contentsRemap)
    set contentsOptions [list "Included in 'annote' field" \
      "Included in 'note' field" "Included in 'contents' field" "Ignored"]
    # Add this page of the dialog.
    incr d
    set  t1 "Field Remapping Options:\r_______________________________\r"
    set  t2 "Abstracts should be:"
    set  t3 "Tables of content should be:"
    lappend d$d "Field Remapping"
    lappend d$d [list text $t1]
    lappend d$d [list [list menu $abstractOptions] $t2 $abstractRemap]
    lappend d$d [list [list menu $contentsOptions] $t3 $contentsRemap]
    lappend dP  [set d$d]
    lappend prefs "abstractRemap" "contentsRemap"

    # The remaining pages will set the default fields to exclude.
    set excludeFields $bibConvertVars(excludeFields)
    if {[info exists Bib::Fields]} {
        set fieldNames [string tolower [set Bib::Fields]]
    } else {
	set fieldNames [list \
	  address author booktitle chapter city crossref edition editor     \
	  howpublished institution journal key language month note number   \
	  organization pages publisher school series title type volume year \
	  ]
    }
    foreach field [list "isbn" "issn" "lccn"] {
	if {[lsearch $fieldNames $field] == "-1"} {
	    lappend fieldNames $field
	} 
    }
    foreach field [set fieldNames [lsort $fieldNames]] {
	set idx [lsearch $excludeFields $field]
	lappend fieldValues [expr {$idx == "-1" ? 0 : 1}]
    }
    # Include a separate page for 12 fields at a time.
    set idx1 0
    set idx2 [expr {[set incrBy 12] - 1}]
    set num  1
    set nums [list]
    while {[llength $fieldNames] > $idx1} {
	lappend nums $num
	set fieldNames${num}  [lrange $fieldNames  $idx1 $idx2]
	set fieldValues${num} [lrange $fieldValues $idx1 $idx2]
	incr idx1 $incrBy ; incr idx2 $incrBy ; incr num
    }
    set t1 "Don't include these fields in any entry:\r  "
    foreach num $nums {
	if {![llength [set fieldValues${num}]]} {break}
	set names  [set fieldNames${num}]
	set values [set fieldValues${num}]
	lappend f${num} "Default Field Settings $num"
	lappend f${num} [list [list multiflag $names] $t1 $values]
	lappend dP [set f${num}]
    }

    # Now present the dialog, and save the new preferences.
    set values [eval $d1 $dP]
    set count 0
    foreach pref $prefs {
	set bibConvertVars($pref) [lindex $values $count]
	incr count
    } 
    # Deal with excluded fields last.
    set excludeFields [list]
    foreach num $nums {
	set fieldValues [lindex $values $count]
	set count2 0
	foreach field [set fieldNames${num}] {
	    if {[lindex $fieldValues $count2]} {lappend excludeFields $field}
	    incr count2
	}
	incr count
    }
    set bibConvertVars(excludeFields) $excludeFields

    # Now synchronize with Bib mode vars.
    set BibmodeVars(autoCapForceLower)      $bibConvertVars(forceLower)
    set BibmodeVars(autoCapSpecialPatterns) $bibConvertVars(specialPatterns)
}

proc bibConvert::insert_results {} {

    global vince_usingAlpha bibConvertVars

    if {!$vince_usingAlpha} {return}
    
    set fileOut $bibConvertVars(fileOut)
    
    if {![file exists $fileOut] || [file size $fileOut] == "0"} {
	error "Cancelled -- conversion results are empty."
    } else {
	regsub -all "\r?\n" [file::readAll $fileOut] "\r" newText
    }
    # Note that we check the 'read-only' status mainly because we could be
    # dealing with 'example' windows which are initially locked.
    set wC [win::Current]
    switch -- $bibConvertVars(insertAction) {
	"In Temporary File" {
	    edit -c $fileOut
	}
	"Above Selection"  {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    goto [set pos [lineStart [getPos]]]
	    insertText -w $wC $newText ; goto $pos
	    selectText $pos [pos::math $pos + [string length $newText]]
	}
	"Below Selection"  {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    goto [set pos [lineStart [selEnd]]]
	    insertText -w $wC $newText ; goto $pos
	    selectText $pos [pos::math $pos + [string length $newText]]
	}
	"Replacing Selection"       {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    replaceText -w $wC [set pos [getPos]] [selEnd] $newText
	    if {![isSelection]} {
		selectText $pos [pos::math $pos + [string length $newText]]
	    } 
	}
	"At Beginning Of Window" {
	    goto [minPos]
	    insertText -w $wC $newText\r ; goto [minPos]
	}
	"At End Of Window" {
	    goto [set pos [maxPos]]
	    insertText -w $wC \r$newText ; goto $pos
	}
	"Replacing Window Contents" {
	    if {[win::getInfo $wC read-only]} {setWinInfo read-only 0} 
	    replaceText -w $wC [minPos] [maxPos] $newText ; goto [minPos]
	    catch {Bib::MarkFile}
	}
	"In New Window"       {
	    set newName "$bibConvertVars(saveName).bib"
	    new -n $newName -m "Bib" -text $newText
	    goto [minPos]
	    catch {Bib::MarkFile}
	}
	default {
	    error "Cancelled -- unknown action option:\
	      $bibConvertVars(insertAction)"
	}
    }
}

# ===========================================================================
# 
# .