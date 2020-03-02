## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "texServices.tcl"
 #                                          created: 03/13/2006 {12:22:00 PM}
 #                                      last update: 03/14/2006 {11:29:44 AM}
 # Description:
 # 
 # Declares all "TeX" services for typesetting (etc.) .tex files
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu/>
 # 
 # All of the actual service declaration were created by other developers.
 # 
 # Copyright (c) 2005-2006  FrŽdŽric Boulanger, Vince Darley, Joachim Kock,
 #                          Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::library "teXServices" "1.0" {
    # Initialization script: source this file so that all TeX Services will
    # be properly registered.
    texServices.tcl
} maintainer {
    "FrŽdŽric Boulanger" <Frederic.Boulanger@supelec.fr>
} description {
    Declares all "TeX" services for typesetting (etc.) .tex files
} help {
    This library supports the package: xserv by declaring a variety of
    different "TeX/LaTeX" services for typesetting a .tex file, converting
    .dvi to .pdf files, etc.  All of these can be set using the menu command
    "Config > Global Setup > Helper Applications":
    
    <<prefs::dialogs::helperApplications "TeX">>
    
    These services are automatically declared when ÇALPHAÈ is launched.
    
    See the file "texServices.tcl" for the package: xserv declarations.
}

proc texServices.tcl {} {}

namespace eval xserv {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× 'typeset' ×××× #
# 

# Many TeX frontends (e.g. TeXShop, iTeXMac, OzTeX) feature a 'Typeset'
# command, by which you can instruct the programme to process a document
# according to automatic choice between tex, latex, etc.  (This automatic
# choice may depend on preference settings of the programme or it may be
# taken on the basis of the file in question, e.g. via magic-first-line
# scanning.)
# 
# Hence the natural need of a 'typeset' xservice.  This service takes one
# argument, namely the full path of the file to typeset.
# 
# Implementaions of this service follow.  
# 
# The first group of implementations are standard: tell an external programme
# to typeset a file.  Some of these are simply copied over from the existing
# 'tex' implementations, and in fact it is revelaed that some of them were
# already typeset-minded (i.e., the apple-event found in the 'tex' driver is
# already a generic 'odoc' and not a specific tex instruction as opposed to a
# latex).
# 
# Then there is the tetexComm implementation: tell tetexComm to figure out
# everything.  This is precisely equivalent to Shift-Cmd-R in Alpha 8.0.
# 
# Finally there is there is an implementation called 'helperApps' which is
# faithful to the Alpha8.0 behaviour of Cmd-T: this means that it delegates
# the typesetting task to the individually chosen implementations of tex
# services, according to old-fashioned TeX mode settings in the TeX Processes
# Menu.

::xserv::addToCategory "TeX" typeset

::xserv::declare "typeset" "Typeset a file" file

::xserv::register "typeset" TeXShop \
  -mode   "Alpha" \
  -driver {
    if { $params(xservInteraction) } {
	# Apparently we need to switch manually!?:
	switchTo TeXShop
    }
    sendOpenEvent noReply 'TeXs' $params(file)
    tclAE::send -r 'TeXs' TeXs TypI ---- [tclAE::build::indexObject docu 1]
}

::xserv::register "typeset" iTeXMac \
  -mode   "Alpha" \
  -driver {
    tclAE::send -r 'iTMx' iTMx Cmpl kfil [tclAE::build::TEXT $params(file)]
}

::xserv::register "typeset" {CMacTeX < 4} \
  -sig    "*XeT" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "typeset" OzTeX \
  -sig    "OTEX" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "typeset" tetexComm \
  -mode   "Alpha" \
  -driver {
    ::TeX::tetexComm::typeset $params(file)
}

# Old-fashioned driver using 'TeX Processes Menu' settings and individual
# helper application settings (for services 'tex', 'etex', 'pdftex', and
# 'pdfetex').

::xserv::register "typeset" helperApps \
  -mode   "Alpha" \
  -driver {
    # Currently we just use the old TeX::typesetFile proc
    set bg [expr {1 - $params(xservInteraction)}]
    TeX::typesetFile $params(file) $bg
} 

# Some implementation should be active out of the box:
if {([xserv::getCurrentImplementationsFor "typeset"] eq "")} {
    xserv::chooseImplementationFor typeset [list -name tetexComm]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# Declare and register all TeX services.
# 

# ===========================================================================
# 
# ×××× bibtex ×××× #
# 

::xserv::addToCategory "TeX" bibtex

# Declare the service.
::xserv::declare "bibtex" {Build a bibliography from a LaTeX .aux file} \
  file {options ""}

# Register implementations.

::xserv::register "bibtex" {CMacTeX < 4} \
  -sig    "CMTu" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "bibtex" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    TeX::buildNewCMacTeXAE $params(xservTarget) \
      "bibtex $params(options)" $params(file)
}

::xserv::register "bibtex" BibTeX \
  -sig    "Vbib" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "bibtex" teTeX \
  -mode   "InSh" \
  -progs  "bibtex" \
  -driver {
    return [list $params(xserv-bibtex) $params(options) $params(file)]
}

::xserv::register "bibtex" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "bibtex" \
  -driver {
    set cmd [TeX::changeToFileDir]
    lappend cmd $params(xserv-bibtex) $params(options) \
      [file tail $params(file)]
    return $cmd
}

::xserv::register "bibtex" tetexComm \
  -mode   "Alpha" \
  -driver {
    ::TeX::tetexComm::bibtex $params(file)
}

# ===========================================================================
# 
# ×××× distillPS ×××× #
# 

::xserv::addToCategory "PDF" distillPS
::xserv::addToCategory "PostScript" distillPS

# Declare the service.
::xserv::declare "distillPS" {Convert a .ps file to .pdf} \
  file {options ""}

# Register implementations.

# (None.)

# ===========================================================================
# 
# ×××× dvipdf ×××× #
# 

::xserv::addToCategory "DVI" dvipdf
::xserv::addToCategory "PDF" dvipdf
::xserv::addToCategory "PostScript" dvipdf

# Declare the service.
::xserv::declare "dvipdf" {Convert a .dvi file to .pdf} \
  file

# Register implementations.

::xserv::register "dvipdf" {CMacTeX < 4} \
  -sig    "CMTb" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "dvipdf" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    TeX::buildNewCMacTeXAE $params(xservTarget) dvipdfm $params(file)
}

::xserv::register "dvipdf" teTeX \
  -mode   "InSh" \
  -progs  "dvipdfm" \
  -driver {
    return [list $params(xserv-dvipdfm) $params(file)]
}

::xserv::register "dvipdf" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "dvipdfm" \
  -driver {
    set cmd [TeX::changeToFileDir]
    lappend cmd $params(xserv-dvipdfm) [file tail $params(file)]
    return $cmd
}

# ::xserv::register "dvipdf" tetexComm \
#   -mode Alpha \
#   -driver {
#     TeX::tetexComm::distillPDF $params(file)
# }

# ===========================================================================
# 
# ×××× dvips ×××× #
# 

::xserv::addToCategory "DVI" dvips
::xserv::addToCategory "PostScript" dvips

# Declare the service.
::xserv::declare "dvips" {Convert a .dvi file to .ps} \
  file {options ""}
# Register implementations.

::xserv::register "dvips" {CMacTeX < 4} \
  -sig    "CMT1" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "dvips" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    TeX::buildNewCMacTeXAE $params(xservTarget) \
      "dvips $params(options)" $params(file)
}

::xserv::register "dvips" OzTeX \
  -sig    "OzDP" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "dvips" teTeX \
  -mode   "InSh" \
  -progs  "dvips" \
  -driver {
    return [list $params(xserv-dvips) $params(options) $params(file)]
}

::xserv::register "dvips" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "dvips" \
  -driver {
    set cmd [TeX::changeToFileDir]
    lappend cmd $params(xserv-dvips) $params(options) \
      [file tail $params(file)]
    return $cmd
}

# ===========================================================================
# 
# ×××× etex ×××× #
# 

::xserv::addToCategory "TeX" etex

# Declare the service.
::xserv::declare "etex" {Typeset a file with eTeX} \
  file {format "elatex"} {options ""}

# Register implementations.

::xserv::register "etex" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    TeX::buildNewCMacTeXAE $params(xservTarget) \
      "etex $params(options) &$params(format)" $params(file)
}

::xserv::register "etex" teTeX \
  -mode   "InSh" \
  -progs  "etex" \
  -driver {
    return [TeX::buildTeTeXcmd etex]
}

::xserv::register "etex" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "etex" \
  -ioMode "io" \
  -driver {
    return [TeX::buildTeTeXshcmd etex]
}

# ===========================================================================
# 
# ×××× makeglossary ×××× #
# 

::xserv::addToCategory "TeX" makeglossary

# Declare the service.
::xserv::declare "makeglossary" {Build a glossary from a LaTeX .glo file} \
  file {style ""} {options ""}

# Register implementations.

# Default is to implement make glossary with makeindex
::xserv::register "makeglossary" makeindex \
  -mode   "Alpha" \
  -driver {
    ::xserv::invoke makeindex -xservInteraction $params(xservInteraction) \
      -file $params(file) -style $params(style) -options $params(options)
}

# ===========================================================================
# 
# ×××× makeindex ×××× #
# 

::xserv::addToCategory "TeX" makeindex

# Declare the service.
::xserv::declare "makeindex" {Build an index from a LaTeX .idx file} \
  file {style ""} {options ""}

# Register implementations.

::xserv::register "makeindex" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    if {$params(style) == ""} {
	TeX::buildNewCMacTeXAE $params(xservTarget) \
	  "makeindex $params(options)" $params(file)
    } else {
	TeX::buildNewCMacTeXAE $params(xservTarget) \
	  "makeindex $params(options) -s $params(style)" $params(file)
    }
}

::xserv::register "makeindex" {CMacTeX < 4} \
  -sig    "CMTt" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "makeindex" MakeIndex \
  -sig    "RZMI" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "makeindex" teTeX \
  -mode   "InSh" \
  -progs  "makeindex" \
  -driver {
    set cmd [list $params(xserv-makeindex) $params(options)]
    if {$params(style) != ""} {
	lappend cmd -s $params(style)
    }
    lappend cmd $params(file)
    return $cmd
}

::xserv::register "makeindex" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "makeindex" \
  -driver {
    set cmd [TeX::changeToFileDir]
    lappend cmd $params(xserv-makeindex) $params(options)
    if {$params(style) != ""} {
	lappend cmd -s $params(style)
    }
    lappend cmd [file tail $params(file)]
    return $cmd
}

::xserv::register "makeindex" tetexComm \
  -mode   "Alpha" \
  -driver {
    ::TeX::tetexComm::makeindex $params(file)
}

# ===========================================================================
# 
# ×××× pdfetex ×××× #
# 

::xserv::addToCategory "TeX" pdfetex

# Declare the service.
::xserv::declare "pdfetex" {Typeset a file with pdfeTeX} \
  file {format "pdfelatex"} {options ""}

# Register implementations.

::xserv::register "pdfetex" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    TeX::buildNewCMacTeXAE $params(xservTarget) \
      "pdfetex $params(options) &$params(format)" $params(file)
}

::xserv::register "pdfetex" teTeX \
  -mode   "InSh" \
  -progs  "pdfetex" \
  -driver {
    return [TeX::buildTeTeXcmd pdfetex]
}

::xserv::register "pdfetex" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "pdfetex" \
  -ioMode "io" \
  -driver {
    return [TeX::buildTeTeXshcmd pdfetex]
}

# ===========================================================================
# 
# ×××× pdftex ×××× #
# 

::xserv::addToCategory "TeX" pdftex

# Declare the service.
::xserv::declare "pdftex" {Typeset a file with pdfTeX} \
  file {format "pdflatex"} {options ""}

# Register implementations.

::xserv::register "pdftex" {CMacTeX < 4} \
  -sig    "pXeT" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "pdftex" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    TeX::buildNewCMacTeXAE $params(xservTarget) \
      "pdftex $params(options) &$params(format)" $params(file)
}

# Without shell (OK for Windows).  Does not work on Unix if the full name of
# a file contains spaces because TeX does not allow spaces in file names.
::xserv::register "pdftex" teTeX \
  -mode   "InSh" \
  -progs  "pdftex" \
  -driver {
    return [TeX::buildTeTeXcmd pdftex]
}

::xserv::register "pdftex" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "pdftex" \
  -ioMode "io" \
  -driver {
    return [TeX::buildTeTeXshcmd pdftex]
}

# ===========================================================================
# 
# ×××× printDVI ×××× #
# 

::xserv::addToCategory "DVI" printDVI

# Declare the service.
::xserv::declare "printDVI" {Print a .dvi file} \
  file

# Register implementations.

::xserv::register "printDVI" CMacTeX \
  -sig    "CMT8" \
  -driver {
    tclAE::send $params(xservTarget) aevt pdoc \
      ---- [tclAE::build::alis $params(file)]
}

::xserv::register "printDVI" OzTeX \
  -sig    "OTEX" \
  -driver {
    tclAE::send $params(xservTarget) aevt pdoc \
      ---- [tclAE::build::alis $params(file)]
}

# ===========================================================================
# 
# ×××× printPDF ×××× #
# 

::xserv::addToCategory "PDF" printPDF

# Declare the service.
::xserv::declare "printPDF" {Print a .pdf file} \
  file
# Register implementations.

# (None.)

# ===========================================================================
# 
# ×××× printPS ×××× #
# 

::xserv::addToCategory "PostScript" printPS

# Declare the service.
::xserv::declare "printPS" {Print a .ps (PostScript) file} \
  file

# Register implementations.

# (None.)

# ===========================================================================
# 
# ×××× tex ×××× #
# 

::xserv::addToCategory "TeX" tex

# Declare the service.
::xserv::declare "tex" {Typeset a file with TeX} \
  file {format "latex"} {options ""}

# Register implementations.

::xserv::register "tex" {CMacTeX < 4} \
  -sig    "*XeT" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "tex" {CMacTeX >= 4} \
  -sig    "*XeT" \
  -driver {
    TeX::buildNewCMacTeXAE $params(xservTarget) \
      "tex $params(options) &$params(format)" $params(file)
}

::xserv::register "tex" OzTeX \
  -sig    "OTEX" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "tex" teTeX \
  -mode   "InSh" \
  -progs  "tex" \
  -driver {
    return [TeX::buildTeTeXcmd tex]
}

::xserv::register "tex" teTeX+sh \
  -mode   "InSh" \
  -shell  "sh" \
  -progs  "tex" \
  -ioMode "io" \
  -driver {
    return [TeX::buildTeTeXshcmd tex]
}

::xserv::register "tex" TeXtures \
  -sig    "*TeX" \
  -driver {
    # Dummy implementation.  We will use the Textures bundle
}

# ===========================================================================
# 
# ×××× viewDVI ×××× #
# 

::xserv::addToCategory "DVI" viewDVI

# Declare the service.
::xserv::declare "viewDVI" {Display a .dvi file} \
  file {line ""} {source ""}

# Register implementations.

::xserv::register "viewDVI" {CMacTeX < 4} \
  -sig    "CMT8" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "viewDVI" Cygwin-xdvi \
  -mode   "Exec" \
  -progs  "xdvi" \
  -driver {
    ::xserv::register "viewDVI" MacDvix \
      -mode   "Exec" \
      -progs  "macdvix" \
      -driver {
	set opts [list $params(xserv-macdvix)]
	if {$params(line) ne ""} {
	    lappend opts -sourceposition "$params(line) $params(source)"
	}
	lappend opts $params(file)
	return $opts
    }
    set cyg [string first "/cygwin/" [file normalize $params(xserv-xdvi)]]
    set cygpath \
      "[string range [file normalize $params(xserv-xdvi)] 0 \
      [expr {$cyg + 7}]]bin"
    set ::env(PATH) "$::env(PATH);$cygpath"
    set ::env(DISPLAY) "127.0.0.1:0.0"
    # xdvi assumes source specials are the file tail
    set currentWin [file tail $params(source)]
    # And the main file must by cygwin-ified.
    set baseFile [file::windowsPathToCygwin $params(file)]
    
    set opts [list $params(xserv-xdvi) -1]
    if {$params(line) ne ""} {
	lappend opts -sourceposition "$params(line) $params(source)"
    }
    lappend opts -editor "[app::alphaCommandLine] -cygwin +%l %f" \
      "$params(file)"
    return $opts
}

::xserv::register "viewDVI" MacDvix \
  -mode   "Exec" \
  -progs  "macdvix" \
  -driver {
    set opts [list $params(xserv-macdvix)]
    if {$params(line) ne ""} {
	lappend opts -sourceposition "$params(line) $params(source)"
    }
    lappend opts $params(file)
    return $opts
}


::xserv::register "viewDVI" OzTeX \
  -sig    "OTEX" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register "viewDVI" TeXniscope \
  -sig    "MGUB" \
  -driver {
    exec open -a TeXniscope $params(file)
    if {$params(line) ne ""} {
	tclAE::send 'MGUB' TeXn Gtli STRT $params(line) \
	  STRS [tclAE::build::TEXT $params(source)] \
	  ---- [tclAE::build::indexObject docu 1]
    }
}

::xserv::register "viewDVI" YAP \
  -mode   "Exec" \
  -progs  "yap" \
  -driver {
    set opts [list $params(xserv-yap) -1]
    if {$params(line) ne ""} {
	lappend opts -s "$params(line) $params(source)"
    }
    lappend opts $params(file) &
    return $opts
}

::xserv::register "viewDVI" Xdvi \
  -mode   "Exec" \
  -progs  "xdvi" \
  -driver {
    set opts [list $params(xserv-xdvi)]
    if {$params(line) ne ""} {
	lappend opts -sourceposition "$params(line) $params(source)"
    } else {
	lappend opts -sourceposition 0none
    }
    lappend opts $params(file) &
    return $opts
}

::xserv::register "viewDVI" usingPDFViewer \
  -mode   "Alpha" \
  -driver {
    TeX::tetexComm::distillPDF $params(file)
}

# ===========================================================================
# 
# ×××× viewPS ×××× #
# 

::xserv::addToCategory "PostScript" viewPS

# Declare the service.
::xserv::declare "viewPS" {Display a .ps (PostScript) file} file

# Register implementations.

::xserv::register "viewPS" Ghostview \
  -progs  "gv" \
  -driver {
    return [list $params(xserv-gv) $params(file) &]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× TeXtures APIs ×××× #
# 
# This is a guess from what I saw in LaTeX mode, it was never tested.
# 

# Put the "TeXtures" bundle in the "TeX" category
::xserv::addToCategory "TeX" TeXtures

# Put all TeXtures services in a "TeXtures" bundle
::xserv::declareBundle "TeXtures" {TeXtures protocol} \
  openTeXtureConnection \
  closeTeXtureConnection \
  synchronizeTeXture \
  getTeXtureFormats \
  handleTeXtureGetText

::xserv::declare "openTeXtureConnection" \
  "Begin to work with a file in TeXtures" file

::xserv::declare "closeTeXtureConnection" \
  "Stop working with a file in TeXture" jobID

::xserv::declare "synchronizeTeXture" \
  "Synchronize with TeXtures" jobID position

::xserv::declare "getTeXtureFormats" "Get the formats available to TeXture"

::xserv::declare "handleTeXtureGetText" \
  "Reply to TeXture requests for text" jobID text

# Implementation of the TeXture specific APIs.

::xserv::register "openTeXtureConnection" Texture \
  -sig    "*TEX" \
  -driver {
    tclAE::build::resultData $params(xservTarget) BSRs Begi \
      ---- [tclAE::build::alis $params(file)]
}

::xserv::register "closeTeXtureConnection" Texture \
  -sig    "*TEX" \
  -driver {
    tclAE::build::resultData $params(xservTarget) BSRs Disc Jobi $params(jobID)
}

::xserv::register "synchronizeTeXture" Texture \
  -sig    "*TEX" \
  -driver {
    tclAE::build::resultData $params(xservTarget) BSRs FFoc \
      long $params(position) Jobi $params(jobID)
}

::xserv::register "getTeXtureFormats" Texture \
  -sig    "*TEX" \
  -driver {
    tclAE::build::resultData $params(xservTarget) BSRs Info Fmts long(0)
}

::xserv::register "handleTeXtureGetText" Texture \
  -sig    "*TEX" \
  -driver {
    tclAE::build::resultData -t 1200 $params(xservTarget) BSRs TTeX \
      TEXT [tclAE::build::TEXT "$params(text)"] Jobi $params(jobID)
}

return "TeX Services have been declared, registered."

# ===========================================================================
# 
# .