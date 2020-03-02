# -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # File : "wikiMethods.tcl"
 #                                          created: 03/10/2003 {12:10:21 PM}
 #                                      last update: 04/28/2006 {04:40:07 PM}
 # Description:
 # 
 # Defines all of the default Wiki Systems we recognize to edit and post wiki
 # pages via the Wiki Menu.  See the notes below file for information about
 # the various fields set here.  The "wikiSystems.tcl" file deals with the
 # handling of these system parameters.
 # 
 # System Administrator note: If you want to modify any of the default 
 # settings (or add new systems), place a copy of this file in the directory
 # 
 #   $SUPPORT(local)/AlphaTcl/Modes/Wiki Mode/
 # 
 # and it will be used preferentially.  A user's edited system parameters
 # will still take precedence over any of your modifications.
 # 
 # Author: Bernard Desgraupes
 # e-mail: <bdesgraupes@easyconnect.fr>
 #    www: <http://webperso.easyconnect.fr/bdesgraupes/>
 # 
 # See the "wikiMode.tcl" file for license information.
 # 
 # ==========================================================================
 ##

proc wikiMethods.tcl {} {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# Please keep these wiki system definitions in alphabetical order.
# 
# Each "Wiki::defaultSystems(<wikiSystem>)" array entry should be an even
# numbered list (i.e. "field" "value" "?field?"  "?value?"  ...)  that can be
# called by [array set ...]  with any of the following items:
# 
# * buildEditUrlPats    A two item list of regular expression patterns that
#                       will be used to create the editing url.  (Required).
#                       Used by [Wiki::buildEditPageUrl].
#                       
# * wikiExamples        A two item list with a "display" and "edit" urls.
#                       Used by [Wiki::verifyBuildUrlPat] and presented to 
#                       the user as hyperlinks in [Wiki::systemInfo].  Use
#                       [Wiki::verifyBuildUrlPat -all] to verify all systems.
#                       
# * viewUrlPattern      Used to associated a "view" wiki page with a system 
#                       by the procedure [Wiki::getWikiSystemForUrl].
#                       
# * editUrlPattern      Used to associated a "view" wiki page with a system 
#                       by the procedure [Wiki::getWikiSystemForUrl] as well 
#                       as [Wiki::getEditWikiSystem].  These patterns are 
#                       also registered with the WWW Menu.
#                       
# * postUrlPattern      Used to associated a "view" wiki page with a system 
#                       by the procedure [Wiki::getWikiSystemForUrl] as well 
#                       as [Wiki::getPostWikiSystem].
#                       
# * wikiSiteUrls        Web site urls that are known to use this system, 
#                       used by [Wiki::getWikiSystemForUrl].
# 
# * postIsEnabled       If not present or if "1", we will always attempt to 
#                       post the edited page to the server.  If "0" then
#                       posting is prohibited, if "2" then the user is 
#                       warned that posting might not work very well, and
#                       "3" means that this has not been tested.  This is 
#                       used by [Wiki::postWindowText].  The menu command 
#                       "Wiki Menu > Save In Browser" is either used or 
#                       suggested as an alternative when necessary.
# 
# Additional items provide information when [Wiki::systemInfo] is called 
# by a user-interface procedure:
# 
# * description         A brief description of the system.
# 
# * homeSite            A web site of the system's maintainer.
# 
# * maintainer          The AlphaTcl maintainer of this system.
# 
# Wiki systems that require their own posting routine should also define a
# special [Wiki::<wikiSystem>::postToServer] procedure that will be used
# preferentially to [Wiki::postToServer].  See examples below.
# 
# None of the other file/procedures in the WikiMenu package should be trying
# to access or query these variables.  They are internal to this file, and
# might change.  Use the [Wiki::getWikiSystemForUrl] procedure above to
# determine if a given url is associated with a particular wiki system, or 
# [Wiki::systemField] to get system field values.
# 
# Users can select "Wiki Menu > Wiki Systems > Edit System" to change any of
# these parameters.
# 
# ---------------------------------------------------------------------------
# 
# Many of these need to be tested more, especially to confirm that posting
# actually works.  
# 

namespace eval Wiki {}

# ===========================================================================
# 
# ×××× Apache::MiniWiki ×××× #
# 

set Wiki::defaultSystems(ApacheMiniWiki) [list \
  "buildEditUrlPats"    [list {([^/\?]*)(\?[^/]*)?} {(edit)/\1}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list "nyetwork.org"] \
  "postIsEnabled"       "0" \
  "wikiExamples"        [list \
  "http://www.nyetwork.org/wiki/test" \
  "http://www.nyetwork.org/wiki/(edit)/test" \
  ] \
  "homeSite"            "http://savannah.nongnu.org/projects/miniwiki/" \
  "description"         {
    Simplistic Wiki for Apache written in Perl.
} \
  ]

namespace eval Wiki::ApacheMiniWiki {}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::ApacheMiniWiki::postToServer" --
 # 
 # [cbu] : I've tried to make this work, but I can't figure it out.  I always
 # end up with a "Preview" page but none of the editing changes are included
 # in the new form field.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::ApacheMiniWiki::postToServer {project postToUrl queryList} {
    
    set newQueryList [list]
    foreach {field fieldList} $queryList {
	if {![regexp -- {^input,} $field]} {
	    lappend newQueryList $field [lrange $fieldList end end]
	    continue
	}
	foreach {type name value} $fieldList {}
	if {([string tolower $type] eq "submit")} {
	    if {([string tolower $name] ne "save")} {
	        continue
	    } else {
		lappend newQueryList $type [list $value]
	    }
	} elseif {([string tolower $name] eq "comment")} {
	    set comment ""
	    while {1} {
	        set p "Enter a comment for this change:"
		set comment [prompt $p $comment]
		if {([string trim $comment] eq "")} {
		    alertnote "The comment cannot be an empty string!"
		    continue
		} else {
		    break
		}
	    }
	    lappend newQueryList $name [list $comment]
	} else {
	    lappend newQueryList $name [list $value]
	}
    }
    return [Wiki::postToServer $project $postToUrl $newQueryList]
}


# ===========================================================================
# 
# ×××× AwkiAwki ×××× #
# 

set Wiki::defaultSystems(AwkiAwki) [list \
  "buildEditUrlPats"    [list {/([^/]*)} {?edit=true\&page=\1}] \
  "viewUrlPattern"      {awki\.cgi} \
  "editUrlPattern"      {awki\.cgi\?edit=} \
  "postUrlPattern"      {awki\.cgi} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://awkiawki.bogosoft.com/cgi-bin/awki.cgi/TestPage" \
  "http://awkiawki.bogosoft.com/cgi-bin/awki.cgi?edit=true&page=TestPage" \
  ] \
  "homeSite"            "http://awkiawki.bogosoft.com/" \
  "description"         {
    A Wiki written in Awk.
} \
  ]

# ===========================================================================
# 
# ×××× ChiqChaq ×××× #
# 

set Wiki::defaultSystems(ChiqChaq) [list \
  "buildEditUrlPats"    [list {chiq.pl\?(.*)title=(.*)} {chiq.pl?\1edit=\2}] \
  "viewUrlPattern"      {/chiq\.pl\?} \
  "editUrlPattern"      {/chiq\.pl\?.*edit=} \
  "postUrlPattern"      {/chiq\.pl\?} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "0" \
  "wikiExamples"         [list \
  "http://www.beofen-tv.co.il/cgi-bin/chiq.pl?eng:play_ground" \
  "http://www.beofen-tv.co.il/cgi-bin/chiq.pl?eng&edit=play_ground" \
  ] \
  "homeSite"            "http://sourceforge.net/projects/chiqchaq/" \
  "description"         {
    Wiki written in Perl.
    
    Of the two "ChiqChaq" sites found,
    
    <http://www.beofen-tv.co.il/cgi-bin/chiq.pl?group=eng>
    <http://www.beofen-tv.co.il/cgi-bin/chiq.pl>
    
    neither appears to have editing enabled, so attempting to use ÇALPHAÈ to
    edit these wiki pages is suspect at best.
} \
  ]

# ===========================================================================
# 
# ×××× Cliki ×××× #
# 

set Wiki::defaultSystems(Cliki) [list \
  "buildEditUrlPats"    [list {/([^/]*)} {/edit/\1}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list "cliki.net/"] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://www.cliki.net/Sandbox" \
  "http://www.cliki.net/edit/Sandbox" \
  ] \
  "homeSite"            "http://www.cliki.net/" \
  "description"         {
    Cliki is a Wiki written in Common LISP.
} \
  ]

# ===========================================================================
# 
# ×××× JSPWiki ×××× #
# 

set Wiki::defaultSystems(JSPWiki) [list \
  "buildEditUrlPats"    [list {Wiki.jsp\?([^/]*)} {Edit.jsp?\1}] \
  "viewUrlPattern"      {(/JSPWiki/)|(/Wiki\.jsp\?)} \
  "editUrlPattern"      {(/JSPWiki/)|(/Edit\.jsp\?)} \
  "postUrlPattern"      {(/JSPWiki/)|(/Wiki\.jsp\?)} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://www.ecyrd.com/JSPWiki/Wiki.jsp?page=SandBox" \
  "http://www.ecyrd.com/JSPWiki/Edit.jsp?page=SandBox" \
  ] \
  "homeSite"            "http://www.ecyrd.com/JSPWiki/" \
  "description"         {
    JSPWiki is written with JSP. (See <http://java.sun.com/products/jsp/>.)
} \
  ]

# ===========================================================================
# 
# ×××× MiniRubyWiki ×××× #
# 

set Wiki::defaultSystems(MiniRuby) [list \
  "buildEditUrlPats"    [list {/wiki\?([^/]*)} {/wiki?edit=\1}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list] \
  "wikiExamples"        [list \
  "http://www.xpsd.org/cgi-bin/wiki?WikiSandbox" \
  "http://www.xpsd.org/cgi-bin/wiki?edit=WikiSandbox" \
  ] \
  "homeSite"            "" \
  "description"         {
    Wiki written using the Ruby scripting language.
    
    IMPORTANT: At present, the <http://www.xpsd.org/> wiki requires
    registration, which is not supported yet by ÇALPHAÈ's Wiki Menu.
} \
  ]

# ===========================================================================
# 
# ×××× MoinMoin ×××× #
# 

set Wiki::defaultSystems(MoinMoin) [list \
  "buildEditUrlPats"    [list {/[^/]*} {&?action=edit}] \
  "viewUrlPattern"      {(/moinmoin/)|(/moin/)} \
  "editUrlPattern"      {((/moinmoin/)|(/moin/))&?action=edit} \
  "postUrlPattern"      {(/moinmoin/)|(/moin/)} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "2" \
  "wikiExamples"         [list \
  "http://wiki.python.org/moin/WikiSandBox" \
  "http://wiki.python.org/moin/WikiSandBox?action=edit" \
  ] \
  "homeSite"            "http://www.usemod.com/" \
  "description"         {
    Many Wikis use the MoinMoin Wiki, written in Python.
    
    IMPORTANT: When you save the edited window, the changes should be
    committed to the remote server.  If you have set your View Url
    preferences to use the WWW Menu, however, the page that is opened won't
    indicate this.  If the results are sent to your browser, you should see
    that the changes are in place, although you might have to "Save" them
    again in the web page form.
    
    Sound confusing?  This is one Wiki System in which you're probably better
    off using the "Wiki Menu > Save In Browser" command rather than the
    standard window saving methods.
} \
  ]

##
 # --------------------------------------------------------------------------
 #       
 # "Wiki::MoinMoin::postToServer" --
 #      
 # This method should work for any MoinMoin wiki.  The key here is to ignore
 # all of the other button arguments that might be included; what we need is
 # the "button_save/Save Changes" combination.  (The "button_cancel/Cancel"
 # field/value combo is what really prevents posting from working, although
 # the others can affect what url is returned.)
 # 
 # However... the page that is opened after posting is complete is some 
 # version of a "preview" page.  When this is presented in Alpha via the WWW 
 # Menu it is very difficult to determine what happened.  We might want to 
 # disable this, since the user won't know what is going on.
 # 
 # Contributed by Craig Barton Upright.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Wiki::MoinMoin {}

proc Wiki::MoinMoin::postToServer {project postToUrl queryList} {
    
    set newQueryList [list]
    
    set newQueryList [list]
    set ignoreNames  [list "button_cancel" "button_preview" "button_spellcheck"]
    foreach {field fieldList} $queryList {
	if {![regexp -- {^input,} $field]} {
	    lappend newQueryList $field [lindex $fieldList end]
	    continue
	}
	foreach {type name value} $fieldList {}
	if {([lsearch -exact $ignoreNames [string tolower $name]] > -1)} {
	    continue
	} else {
	    lappend newQueryList $name $value
	}
    }
    return [Wiki::postToServer $project $postToUrl $newQueryList]
}

# ===========================================================================
# 
# ×××× OpenWiki ×××× #
# 

set Wiki::defaultSystems(OpenWiki) [list \
  "buildEditUrlPats"    [list {\?([^/]*)} {?p=\1\&a=edit}] \
  "viewUrlPattern"      {/ow\.asp\?} \
  "editUrlPattern"      {/ow\.asp\?&a=edit} \
  "postUrlPattern"      {/ow\.asp\?} \
  "wikiSiteUrls"        [list "openwiki.com"] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://openwiki.com/ow.asp?SandBox" \
  "http://openwiki.com/ow.asp?p=SandBox&a=edit" \
  ] \
  "homeSite"            "http://openwiki.com/" \
  "description"         {} \
  ]

# ===========================================================================
# 
# ×××× PhpWiki ×××× #
# 

set Wiki::defaultSystems(PhpWiki) [list \
  "buildEditUrlPats"    [list {([^/]*)} {&?action=$edit}] \
  "viewUrlPattern"      {/phpwiki/} \
  "editUrlPattern"      {/phpwiki/.*&\?action=\$edit} \
  "postUrlPattern"      {/phpwiki/} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://phpwiki.sourceforge.net/phpwiki/SandBox" \
  "http://phpwiki.sourceforge.net/phpwiki/SandBox?action=edit" \
  ] \
  "homeSite"            "http://phpwiki.sourceforge.net/" \
  "description"         {PhpWiki is written with PHP.} \
  ]

# ===========================================================================
# 
# ×××× pmWiki ×××× #
# 

set Wiki::defaultSystems(pmWiki) [list \
  "buildEditUrlPats"    [list {([^/]*)} {&?action=edit}] \
  "viewUrlPattern"      {/pmwiki\.php/} \
  "editUrlPattern"      {/pmwiki\.php/.*&\?action=edit} \
  "postUrlPattern"      {/pmwiki\.php/} \
  "wikiSiteUrls"        [list "alphatcl.sourceforge.net/wiki"] \
  "postIsEnabled"       "1" \
  "wikiExamples"         [list \
  "http://alphatcl.sourceforge.net/wiki/pmwiki.php/Main/WikiSandbox" \
  "http://alphatcl.sourceforge.net/wiki/pmwiki.php/Main/WikiSandbox?action=edit" \
  ] \
  "homeSite"            "http://pmwiki.sourceforge.net/" \
  "description"         {
    pmWiki is written with PHP.
} \
  ]

##
 # --------------------------------------------------------------------------
 #       
 # "Wiki::pmWiki::postToServer" --
 #      
 # This method should work for any pmWiki wiki.  The key here is to ignore
 # all of the other button arguments that might be included; what we need is
 # the "post/Save" combination.  (The "cancel/Cancel" field/value combo is
 # what really prevents posting from working, although the others can affect
 # what url is returned.)
 # 
 # Other wiki methods will probably need some version of this.
 # 
 # Contributed by Craig Barton Upright.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Wiki::pmWiki {}

proc Wiki::pmWiki::postToServer {project postToUrl queryList} {
    
    variable editorName
    variable lastSummary
    variable minorEdit
    
    if {![info exists editorName]} {
        set editorName [Wiki::projectField $project "author"]
    }
    if {![info exists lastSummary]} {
        set lastSummary ""
    }
    if {![info exists minorEdit]} {
        set minorEdit 0
    }
    set dialogScript [list dialog::make -title "Saving Wiki Page To Web" \
      -width 400 \
      -ok "Continue" \
      -okhelptag "Click here to post the wiki page to the web." \
      [list "" \
      [list "var" "Editor Name:" $editorName] \
      [list "var" "Summary:" $lastSummary] \
      [list "flag" "This is a minor edit" $minorEdit] \
      ]]
    set results [eval $dialogScript]
    foreach [list editorName lastSummary minorEdit] $results {}
    
    set newQueryList [list]
    set ignoreNames  [list "cancel" "postedit" "preview"]
    foreach {field fieldList} $queryList {
	if {![regexp -- {^input,} $field]} {
	    lappend newQueryList $field [lrange $fieldList end end]
	    continue
	}
	foreach {type name value} $fieldList {}
	if {([lsearch -exact $ignoreNames [string tolower $name]] > -1)} {
	    continue
	} elseif {([string tolower $name] eq "author")} {
	    lappend newQueryList $name [list $editorName]
	} elseif {([string tolower $name] eq "csum")} {
	    lappend newQueryList $name [list $lastSummary]
	} elseif {([string tolower $name] eq "diffclass")} {
	    lappend newQueryList $name [list [expr {$minorEdit ? "minor" : ""}]]
	} else {
	    lappend newQueryList $name [list $value]
	}
    }
    return [Wiki::postToServer $project $postToUrl $newQueryList]
}

# ===========================================================================
# 
# ×××× SeedWiki ×××× #
# 

set Wiki::defaultSystems(SeedWiki) [list \
  "buildEditUrlPats"    [list {[^/]*} {&\&edit=yes}] \
  "viewUrlPattern"      {seedwiki\.com/} \
  "editUrlPattern"      {seedwiki\.com/.*&edit=yes} \
  "postUrlPattern"      {seedwiki\.com/} \
  "wikiSiteUrls"        [list "seedwiki.com"] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://www.seedwiki.com/wiki/wikifish/sand_box.cfm?" \
  "http://www.seedwiki.com/wiki/wikifish/sand_box.cfm?edit=yes" \
  ] \
  "homeSite"            "http://www.seedwiki.com/" \
  "description"         {
    "seedwiki is a huge collaborative community: the seedwiki host company,
    seedwiki users, organizations and businesses building on seedwiki,
    developers, and designers."
} \
  ]

# ===========================================================================
# 
# ×××× TinyWiki ×××× #
# 

set Wiki::defaultSystems(TinyWiki) [list \
  "buildEditUrlPats"    [list {[^/]*} {&\&action=edit}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://perldesignpatterns.com/?SandBox" \
  "http://perldesignpatterns.com/?SandBox&action=edit" \
  ] \
  "homeSite"            "http://perldesignpatterns.com/?TinyWiki" \
  "description"         {
    "A knock off of Ward Cunningham's WikiWikiWeb at <http://c2.com/cgi/wiki>,
    written in under a hundred lines of Perl."
} \
  ]

# ===========================================================================
# 
# ×××× TWiki ×××× #
# 

set Wiki::defaultSystems(TWiki) [list \
  "buildEditUrlPats"    [list {/view/(.*)} {/edit/\1}] \
  "viewUrlPattern"      {(/twiki/.*/view/)} \
  "editUrlPattern"      {(/twiki/.*/edit/)} \
  "postUrlPattern"      {/twiki/} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://twiki.org/cgi-bin/view/Sandbox/WebHome" \
  "http://twiki.org/cgi-bin/edit/Sandbox/WebHome" \
  ] \
  "homeSite"            "" \
  "description"         {
    "TWiki is a flexible, powerful, and easy to use enterprise collaboration
    platform.  It is a Structured Wiki, typically used to run a project
    development space, a document management system, a knowledge base, or any
    other groupware tool, on an intranet or on the internet."

    TWiki is GPLed software.  The Perl CGI source code, templates and
    documentation is available for free.

    IMPORTANT: At present, the <http://www.twiki.org/> wiki requires
    registration, which is not supported yet by ÇALPHAÈ's Wiki Menu.
} \
  ]

# ===========================================================================
# 
# ×××× UseModWiki ×××× #
# 

set Wiki::defaultSystems(UseModWiki) [list \
  "buildEditUrlPats"    [list {wiki.pl\?(.*)} {wiki.pl?action=edit\&id=\1}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list "usemod.com"] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://www.usemod.com/cgi-bin/wiki.pl?SandBox" \
  "http://www.usemod.com/cgi-bin/wiki.pl?action=edit&id=SandBox" \
  ] \
  "homeSite"            "http://www.usemod.com/" \
  "description"         {
    UseModWiki is a Perl script which uses a database of text files to
    generate a WikiWiki site.  Its primary access method is through CGI (the
    Web), but can be called directly by other Perl programs.
} \
  ]

# ===========================================================================
# 
# ×××× Wiiski ×××× #
# 

set Wiki::defaultSystems(Wiiski) [list \
  "viewUrlPattern"      {(/wiiski/.*/view/User)|(/wiiski/view/User)} \
  "buildEditUrlPats"    [list {/view/User/([^/]*)} {/edit/User/\1}] \
  "viewUrlPattern"      {/wiiski/} \
  "editUrlPattern"      {(/wiiski/.*/edit/User)|(/wiiski/edit/User)} \
  "postUrlPattern"      {/wiiski/} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://wiiski.renewal-iis.com/wiiski/bin/view/User/TextFormattingRules" \
  "http://wiiski.renewal-iis.com/wiiski/bin/edit/User/TextFormattingRules" \
  ] \
  "homeSite"            "" \
  "description"         {
    Note: these links seem to be broken, and no further information is
    available about this wiki system.
} \
  ]

# ===========================================================================
# 
# ×××× Wikipedia ×××× #
# 

set Wiki::defaultSystems(Wikipedia) [list \
  "buildEditUrlPats"    [list {/wiki/([^/]*)} {/w/wiki.phtml?title=\1\&action=edit}] \
  "viewUrlPattern"      {\.wikipedia\.} \
  "editUrlPattern"      {\.wikipedia\..+&action=edit} \
  "postUrlPattern"      {\.wikipedia\.} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "0" \
  "wikiExamples"         [list \
  "http://en.wikipedia.org/wiki/Wikipedia:Sandbox" \
  "http://en.wikipedia.org/w/index.php?title=Wikipedia:Sandbox&action=edit" \
  ] \
  "homeSite"            "" \
  "description"         {
    Note: posting via the "Wiki Menu > Save To Web" command does not work
    well at all, and it is unclear why this is the case.  At present, saving
    the edited page using this method is disabled.  You can, however, use the
    "Wiki Menu > Save In Browser" command instead.
} \
  ]

# ===========================================================================
# 
# ×××× Wikit ×××× #
# 

set Wiki::defaultSystems(Wikit) [list \
  "buildEditUrlPats"    [list {([0-9]+)(\.html)?} {edit/\1@}] \
  "viewUrlPattern"      {/wikit/} \
  "editUrlPattern"      {.*/[-a-zA-Z]*wikit/(.*/)?[0-9]+@$} \
  "postUrlPattern"      {/wikit/} \
  "wikiSiteUrls"        [list "wiki.tcl.tk" "mini.net/tcl"] \
  "postIsEnabled"       "1" \
  "wikiExamples"         [list \
  "http://wiki.tcl.tk/34" \
  "http://wiki.tcl.tk/edit/34@" \
  ] \
  "homeSite"            "http://www.equi4.com/wikit" \
  "description"         {
    The Tcl'ers wiki (which is a default project in Wiki Mode) use Wikit, a
    Wiki written in Tcl.  The Equi4 <http://www.equi4.com/wikit> site also
    uses Wikit.  The '.html' extension can be omitted.
    
    Many "Wikit" style wikis offer or require user authentication before
    allowing edits to be committed to the server.  This takes the form of a
    "Who Are You" (wru) url that is given to you by the site.  For example,
    if you are editing Tcl wiki pages you would visit
    
    <http://wiki.tcl.tk/wru.cgi>
    
    and fill in the necessary information; you will then be sent a confirmation
    e-mail containing a url for you to visit.
    
    This url should be stored in your project's "author" field.
    
    <<Wiki::editProjects>>
} \
  ]

##
 # --------------------------------------------------------------------------
 #       
 # "Wiki::Wikit::postToServer" --
 #      
 # This method should work for any Wikit wiki.
 # 
 # Authenticate any previously set "wru" url for the supplied Project and
 # post the new page data.  The 'query' argument is ignored here, we get all
 # of the information we need to fetching the original data and parsing out
 # the relevant bits.
 # 
 # Contributed by Daniel Steffan.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Wiki::Wikit {}

proc Wiki::Wikit::postToServer {project postToUrl queryList} {
    
    set pageData [lindex $queryList 1]
    set urlPat {^([a-zA-Z0-9]+://[^/]+).*/([0-9]+)@?$}
    if {![regexp $urlPat $postToUrl -> baseUrl pageNumber]} {
	dialog::errorAlert "Cancelled --\
	  Could not identify base url or page number."
    }
    set baseUrl [Wiki::projectField $project "projectHome" $baseUrl]
    # Try to find a registration url.  This should be the "author" field, but
    # the user might have placed it in "password".
    set regUrl  [Wiki::projectField $project "author"]
    if {($regUrl eq "")} {
        set regUrl [Wiki::projectField $project "password"]
    }
    # Get the necessary cookie information.
    if {![regexp {^http://[^?]+\?(wru=.*)$} $regUrl -> cookie]} {
	set cookie ""
    }
    # This is a special case to allow anonymous AlphaTcl editing.
    if {($project eq "AlphaTcl") && ![string length $cookie]} {
	set cookie "wru=alphawikimode//151598349"
    }
     # Now send the info and get the new page html.
    set html ""
    set ok 0
    set editUrl [url::makeAbsolute $baseUrl "edit/${pageNumber}@"]
    if {[catch {set token [::http::geturl $editUrl]} html]} {
	if {([set html [::http::status $token]] eq "ok") \
	  && ([::http::ncode $token] eq "200")} {
	    append pat {<form } \
	      {[^>]*action="([^"]+)".*<input } \
	      {[^>]*name="O" } \
	      {[^>]*value="([^"]+)".*<textarea } \
	      {[^>]*name="C"[^>]*>(.*)</textarea>}
	    set ok [regexp $pat [set hdata [::http::data $token]] -> action tag old_data]
	}
	if {$ok} {
	    set editUrl [url::makeAbsolute $baseUrl $action]
	    set headers [list Cookie $cookie]
	    set query [::http::formatQuery \
	      "Action"  "Save" \
	      "Z"       [url::makeAbsolute $baseUrl $pageNumber] \
	      "O"       $tag \
	      "C"       $pageData \
	      ]
	    set token [::http::geturl $editUrl -headers $headers \
	      -query $query -timeout 30000]
	}
    }
    return $token
}


# ===========================================================================
# 
# ×××× Wiki Type Framework (WTFW) ×××× #
# 

set Wiki::defaultSystems(WTFW) [list \
  "buildEditUrlPats"    [list {([^/]*)} {&\&op=edit}] \
  "viewUrlPattern"      {/wtfw/} \
  "editUrlPattern"      {/wtfw/.*&op=edit} \
  "postUrlPattern"      {/wtfw/} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://wtfw.sourceforge.net/wtfw/index.php?thingid=1856610630&class=content" \
  "http://wtfw.sourceforge.net/wtfw/index.php?thingid=1856610630&class=content&op=edit" \
  ] \
  "homeSite"            "http://wtfw.sourceforge.net/" \
  "description"         {
    "WTF is not a Wiki engine, although it can be used as one.  It is
    actually a generic web content management engine allowing you to create
    web documents easily from the comfort of your browser.  If you must
    compare it to something, consider it a cross between a Blog, a Wiki, and
    a forum."
    
    Note: These links might be broken.
} \
  ]

# ===========================================================================
# 
# ×××× WikiWay ×××× #
# 

set Wiki::defaultSystems(WikiWay) [list \
  "buildEditUrlPats"    [list {\?([^/]*)} {?pact=Edit+this+page\&paref=\1}] \
  "viewUrlPattern"      {/wikiway\?} \
  "editUrlPattern"      {/wikiway\?pact=Edit+this+page} \
  "postUrlPattern"      {/wikiway\?} \
  "wikiSiteUrls"        [list "leuf.net/ww"] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://leuf.net/ww/wikiway?QuestionAndAnswer" \
  "http://leuf.net/ww/wikiway?pact=Edit+this+page&paref=QuestionAndAnswer" \
  ] \
  "homeSite"            "http://leuf.net/ww/wikiway" \
  "description"         {} \
  ]
set Wiki::wikiDescription(WikiWay) {
    If the displayed page is
    
	<http://leuf.net/ww/wikiway?QuestionAndAnswer>
    
    its edited counterpart will be
    
	<http://leuf.net/ww/wikiway?pact=Edit+this+page&paref=QuestionAndAnswer>
    
    See: <http://leuf.net/ww/wikiway>
}

# ===========================================================================
# 
# ×××× WikiWikiWeb ×××× #
# 

set Wiki::defaultSystems(WikiWikiWeb) [list \
  "buildEditUrlPats"    [list {\?(.*)} {?edit=\1}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list "c2.com"] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://c2.com/cgi/wiki?WikiWikiSandbox" \
  "http://c2.com/cgi/wiki?edit=WikiWikiSandbox" \
  ] \
  "homeSite"            "http://c2.com/cgi/wiki" \
  "description"         {
    The first Wiki system ever written used the WikiWikiWeb.
} \
  ]

# ===========================================================================
# 
# ×××× WikkiTikkiTavi ×××× #
# 

set Wiki::defaultSystems(WikkiTikkiTavi) [list \
  "buildEditUrlPats"    [list {/[^/]*} {index.php?action=edit&page=\1}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list "tavi.sourceforge.net"] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://tavi.sourceforge.net/SandBox" \
  "http://tavi.sourceforge.net/index.php?action=edit&page=SandBox" \
  ] \
  "homeSite"            "http://tavi.sourceforge.net/" \
  "description"         {PHP-based wiki engine.} \
  ]

# ===========================================================================
# 
# ×××× ZWiki ×××× #
# 

set Wiki::defaultSystems(ZWiki) [list \
  "buildEditUrlPats"    [list {[^/]*} {&/editform}] \
  "viewUrlPattern"      {} \
  "editUrlPattern"      {} \
  "postUrlPattern"      {} \
  "wikiSiteUrls"        [list] \
  "postIsEnabled"       "3" \
  "wikiExamples"         [list \
  "http://zwiki.org/SandBox" \
  "http://zwiki.org/SandBox/editform" \
  ] \
  "homeSite"            "http://zwiki.org/" \
  "description"         {
    PHP-based wiki engine.
    
    IMPORTANT: At present, the <http://zwiki.org/> wiki requires
    registration, which is not supported yet by ÇALPHAÈ's Wiki Menu.
} \
  ]

return "Wiki Systems have been defined."

# ===========================================================================
# 
# .