## -*-Tcl-*-
 # ==========================================================================
 # Help Files
 #
 # FILE: "Search E-mail Archives.tcl"
 #                                          created: 11/04/2003 {02:50:15 PM}
 #                                      last update: 03/20/2006 {11:59:07 AM}
 # Description: 
 # 
 # Script to search various Alpha related email archives.
 #
 # The "Help > Search E-mail Archives" menu item sources this file and
 # eventually calls the [::help::search::emailArchives] procedure.  All
 # options are saved for the next round until the user quits Alpha.
 # 
 # Press Command-L to test this right now.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # ==========================================================================
 ##

##
 # --------------------------------------------------------------------------
 #
 # "namespace eval ::help::search" --
 # 
 # The first time this file is sourced, we set up some variables required
 # below for [::help::search::emailArchives].
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval ::help::search {
    
    variable initialized
    
    if {![info exists initialized]} {
	variable archiveOptions [list \
	  "AlphaTcl Users List" \
	  "AlphaTcl Developers List" \
	  "Alpha Bugzilla" \
	  ]
	variable archiveOption [lindex $archiveOptions 0]
	variable searchText ""
	set initialized 1
    } 
}

##
 # --------------------------------------------------------------------------
 #
 # "::help::search::emailArchives" --
 # 
 # The first time this file is sourced, we define this procedure.
 # 
 # Note: SourceForge's web site and search engine are prone to a lot of
 # slow-downs and maintenance down-times.  Best to let the local browser hang
 # when fetching these urls rather than using the WWW Menu.
 # 
 # As of this writing, multi-word searches (separated by " ") are never
 # handled properly by the SourceForge search engine.  This is a bug on their
 # end, not ours.  We disable multi-word searches until they figure out what
 # is wrong...
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info procs ::help::search::emailArchives]]} {
    ;proc ::help::search::emailArchives {} {
	
	variable archiveOptions
	variable archiveOption
	variable browseAllArchives 0
	variable searchText
	
	set p "Search which archive?"
	set L [list $archiveOption]
	set archiveOption [listpick -p $p -L $L $archiveOptions]
	
	if {($archiveOption eq "Alpha Bugzilla")} {
	    bugzilla::menuProc "" "searchBugsFor"
	    return
	}
	switch -- $archiveOption {
	    "AlphaTcl Users List" {
		set url "http://www.purl.org/net/alpha/mail/user-"
	    }
	    "AlphaTcl Developers List" {
		set url "http://www.purl.org/net/alpha/mail/dev-"
	    }
	    default {
		dialog::errorAlert "Cancelled -- unknown option: $archiveOption"
	    }
	}
	while {1} {
	    set dialogScript [list dialog::make \
	      -title "Search $archiveOption Archives" \
	      -width 400 \
	      -ok "Search" \
	      -okhelptag "Click here to open a browser page with search options." \
	      -cancelhelptag "Click here to cancel the search." \
	      -addbuttons [list \
	      "Browse Archives" \
	      "Click here to open a browser page containing all e-mail archives." \
	      "set help::search::browseAllArchives 1 ; \
	      set retCode ok ; set retVal 0" \
	      ] \
	      [list "" \
	      [list "var" "Search the e-mail archives for the following string:\r" \
	      $searchText] \
	      ]]
	    set results [eval $dialogScript]
	    if {$browseAllArchives} {
	        break
	    } 
	    set searchText [string trim [lindex $results 0]]
	    if {![string length $searchText]} {
	        alertnote "Nothing was entered!"
	    } else {
	        break
	    }
	}
	if {$browseAllArchives} {
	    append url "archives"
	} elseif {[regexp -all -- {^\"(.+)\"$} $searchText -> quotedText]} {
	    append url "search/&exact=1" "&words=" [quote::Url $quotedText]
	} else {
	    append url "search/&words=" [quote::Url $searchText]
	}
	url::execute $url
	return
    }
}

# Now we call this search procedure.
::help::search::emailArchives

# ===========================================================================
# 
# .