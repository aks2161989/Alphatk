## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexBackCompatibility.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 10/27/2003 {10:09:28 AM}
 # Description:
 #
 # Back compatibility support for code prior to v 5.0 of TeX mode.
 #
 # IMPORTANT: The goal is to make this file disappear so that we don't have
 # to ever define these procs outside of the TeX namespace.  We probably need
 # to wait at least a year after this is included in the next major release
 # to do so, so that users have a chance to redefine their key-bindings.
 #
 # All of the renamed procs are listed below.  Only the old 'macros' and
 # navigation procs are actually defined (those formerly in the files
 # "latexEnvironments.tcl", "latexMacros.tcl", and "latexNavigation.tcl"),
 # since other code which used to call the others has been updated, and it's
 # highly unlikely that users would have called such internal stuff in their
 # "prefs.tcl" or "TeXPrefs.tcl" files.  All of the latex support packages
 # have already been updated to use the new procs.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

proc latexBackCompatibility.tcl {} {}

namespace eval TeX           {}
namespace eval TeX::mp       {}
namespace eval TeX::sub      {}
namespace eval TeX::Textures {}

# The goal is to someday uncomment this next line:
# return

# ◊◊◊◊ -------- ◊◊◊◊ #

# ◊◊◊◊ "latex.tcl" ◊◊◊◊ #

# array set TeX::ObseleteProcMapping {
# 
#     "dummyTeX"                  "latex.tcl"
#     "makeProcessMenu"           "TeX::rebuildMenu {Process}"
#     "TexturesopenHook"          "TeX::Textures::openHook"
#     "TexturescloseHook"         "TeX::Textures::closeHook"
#     "TexturessaveasHook"        "TeX::Textures::saveAsHook"
#     "TexturesLaunched"          "TeX::Textures::launched"
#     "doFlash"                   "TeX::Textures::doFlash"
#     "setSelect"                 "TeX::Textures::setSelect"
#     "getBSRText"                "TeX::Textures::getBSRText"
#     "shadowtexSig"              "TeX::resetSigInfo"
#     "shadowTeXInputs"           "TeX::resetTeXInputs"
#     "TeX::updateProgramList"    "TeX::rebuildMenu {TeX Program}"
#     "TeX::updateFormatList"     "TeX::rebuildMenu {TeX Format}"
#     "shadowUseDollarSigns"      "TeX::resetDollarSignsInfo"
#     "shadowCiteRefCommands"     "TeX::colorizeTeX"
#     "shadowBoxMacroNames"       "TeX::colorizeTeX"
#     "colorLaTeXClickCommands"   "TeX::colorizeTeX"
#     "colorLaTeXCommands"        "TeX::colorizeTeX"
#     "loadLatexMode"             "latex.tcl"
# }

# ◊◊◊◊ "latexComm.tcl" ◊◊◊◊ #

array set TeX::ObseleteProcMapping {

    "typesetSelection"                  "TeX::typesetSelection"
    "typeset"                           "TeX::typeset"
    "typesetClipboard"                  "TeX::typesetClipboard"
    "typesetFile"                       "TeX::typesetFile"
    "doTypesetCommand"                  "TeX::doTypesetCommand"

    "TeX::switchTexturesInterface"      "TeX::resetTexturesInterface"
    "TeX::switchCMacTeXInterface"       "TeX::resetCMacTeXInterface"
    
    "buildTeXcommand"                   "TeX::buildCMacTeXcommand"
    "buildNewCMacTeXAE"                 "TeX::buildNewCMacTeXAE"
    "evalTeXScript"                     "TeX::evalTeXScript"
    "openAnyTeXFile"                    "TeX::openAnyFile"
    "removeAuxiliaryFiles"              "TeX::removeAuxiliaryFiles"
    "findAuxiliaryFile"                 "TeX::findAuxiliaryFile"
    "winUntitled"                       "TeX::winUntitled"
    "texApp"                            "TeX::texApp"
}

# ◊◊◊◊ "latexEngine.tcl" ◊◊◊◊ #

array set TeX::ObseleteProcMapping {

    "TeX::RequirePackage"               "TeX::requirePackage"
    "TeX::InsertInPreamble"             "TeX::insertInPreamble"
    "TeX::Format"                       "TeX::menuProc"
    "TeX::SetFormat"                    "TeX::menuProc {TeX Format}"
    "TeX::ChooseProgram"                "TeX::menuProc"
    "TeX::SetProgram"                   "TeX::menuProc {TeX Program}"
    "TeX::ChooseStyle"                  "TeX::menuProc"
    "TeX::SetStyle"                     "TeX::menuProc {MakeIndex Styles}"
    
    "TeX_selectPatternInFileOrSet"      "TeX::selectPatternInFileOrSet"
    "TeX_dblClickCitation"              "TeX::dblClickCitation"
    "TeX_findBibItem"                   "TeX::findBibItem"
    "TeX_currentBaseFile"               "TeX::currentBaseFile"
    "TeXEnsureSearchPathSet"            "TeX::ensureSearchPathSet"

    "findTeXFile"                       "TeX::findTeXFile"
    "openTeXFile"                       "TeX::openFile"
    "buildTeXSearchPath"                "TeX::buildTeXSearchPath"
    "TeXExtendArg"                      "TeX::extendArg"
    "findCommandWithParts"              "TeX::findCommandWithParts"
    "shiftTextRight"                    "TeX::shiftTextRight"
    "openingCarriageReturn"             "TeX::openingCarriageReturn"
    "closingCarriageReturn"             "TeX::closingCarriageReturn"
    "insertObject"                      "TeX::insertObject"
    "buildEnvironment"                  "TeX::buildEnvironment"
    "buildStructure"                    "TeX::buildStructure"
    "insertEnvironment"                 "TeX::insertEnvironment"
    "insertStructure"                   "TeX::insertStructure"
    "wrapEnvironment"                   "TeX::wrapEnvironment"
    "wrapStructure"                     "TeX::wrapStructure"
    "doWrapEnvironment"                 "TeX::doWrapEnvironment"
    "doWrapStructure"                   "TeX::doWrapStructure"
    "insertDocument"                    "TeX::insertDocument"
    "wrapDocument"                      "TeX::wrapDocument"
    "isBeforePreamble"                  "TeX::isBeforePreamble"
    "isInPreamble"                      "TeX::isInPreamble"
    "isInDocument"                      "TeX::isInDocument"
    "isAfterDocument"                   "TeX::isAfterDocument"
    "isInMathMode"                      "TeX::isInMathMode"
    "extractCommandName"                "TeX::extractCommandName"
    "extractCommandArg"                 "TeX::extractCommandArg"
    "searchEnvironment"                 "TeX::searchEnvironment"
    "isSelectionAll"                    "TeX::isSelectionAll"
    "isEmptyFile"                       "TeX::isEmptyFile"
    "isUppercase"                       "TeX::isUppercase"
    "isAlphabetic"                      "TeX::isAlphabetic"
    "checkMathMode"                     "TeX::checkMathMode"
}

# ◊◊◊◊ "latexEnvironments.tcl" ◊◊◊◊ #

array set TeX::ObseleteProcMapping {

    "enumerate"                 "TeX::enumerate"
    "itemize"                   "TeX::itemize"
    "description"               "TeX::description"
    "thebibliography"           "TeX::thebibliography"
    "slide"                     "TeX::slide"
    "overlay"                   "TeX::overlay"
    "note"                      "TeX::note"
    "figure"                    "TeX::figure"
    "table"                     "TeX::table"
    "buildRow"                  "TeX::buildRow"
    "tabular"                   "TeX::tabular"
    "verbatim"                  "TeX::verbatim"
    "quote"                     "TeX::quote"
    "quotation"                 "TeX::quotation"
    "verse"                     "TeX::verse"
    "flushleft"                 "TeX::flushleft"
    "center"                    "TeX::center"
    "flushright"                "TeX::flushright"
    "minipage"                  "TeX::minipage"
    
    "math"                      "TeX::math"
    "equation*"                 "TeX::equation*"
    "subequations"              "TeX::subequations"
    "displaymath"               "TeX::displaymath"
    "mathEnvironment"           "TeX::mathEnvironment"
    "TeXmathenv"                "TeX::TeXmathenv"
}

# ◊◊◊◊ "latexKeys.tcl" ◊◊◊◊ #

# array set TeX::ObseleteProcMapping {
# 
#     "bindLaTeXKeys"             "TeX::bindLaTeXKeys"
#     "bindLaTeXKeys"             "TeX::bindKeypadKeys"
#     "bindGreekKeys"             "TeX::bindGreekKeys"
# }

# ◊◊◊◊ "latexMacros.tcl" ◊◊◊◊ #

array set TeX::ObseleteProcMapping {

    "chooseCommand"             "TeX::chooseCommand"
    "chooseEnvironment"         "TeX::chooseEnvironment"
    "getEnvironment"            "TeX::getEnvironment"
    "newLaTeXDocument"          "TeX::newLaTeXDocument"
    "letterDocumentclass"       "TeX::letterDocumentclass"
    "articleDocumentclass"      "TeX::articleDocumentclass"
    "reportDocumentclass"       "TeX::reportDocumentclass"
    "bookDocumentclass"         "TeX::bookDocumentclass"
    "slidesDocumentclass"       "TeX::slidesDocumentclass"
    "otherDocumentclass"        "TeX::otherDocumentclass"
    "options"                   "TeX::options"
    "getOption"                 "TeX::getOption"
    "insertOption"              "TeX::insertOption"
    "insertPackage"             "TeX::insertPackage"
    "filecontents"              "TeX::filecontents"
    "filecontentsAll"           "TeX::filecontentsAll"
    "texResolveAll"             "TeX::resolveAll"
    "buildFilecontents"         "TeX::buildFilecontents"
}

array set TeX::ObseleteProcMapping {

    "maketitle"                 "TeX::macroMenuProc {Page Layout} maketitle"
    "abstract"                  "TeX::macroMenuProc {Page Layout} abstract"
    "titlepage"                 "TeX::macroMenuProc {Page Layout} titlepage"
    "getPagestyle"              "(no longer defined)"
    "pagestyle"                 "TeX::macroMenuProc {Page Layout} pagestyle"
    "thispagestyle"             "TeX::macroMenuProc {Page Layout} thispagestyle"
    "pagenumbering"             "TeX::macroMenuProc {Page Layout} pagenumbering"
    "getPagenumberingStyle"     "(no longer defined)"
    "twocolumn"                 "TeX::macroMenuProc {Page Layout} twocolumn"
    "onecolumn"                 "TeX::macroMenuProc {Page Layout} onecolumn"
    "sectioning"                "(no longer defined)"

    "appendix"                  "TeX::macroMenuProc {Sectioning} appendix"

    "emph"                      "TeX::macroMenuProc {Text Style} emph"
    "textup"                    "TeX::macroMenuProc {Text Style} textup"
    "textit"                    "TeX::macroMenuProc {Text Style} textit"
    "textsl"                    "TeX::macroMenuProc {Text Style} textsl"
    "textsc"                    "TeX::macroMenuProc {Text Style} textsc"
    "textmd"                    "TeX::macroMenuProc {Text Style} textmd"
    "textbf"                    "TeX::macroMenuProc {Text Style} textbf"
    "textrm"                    "TeX::macroMenuProc {Text Style} textrm"
    "textsf"                    "TeX::macroMenuProc {Text Style} textsf"
    "texttt"                    "TeX::macroMenuProc {Text Style} texttt"
    "textnormal"                "TeX::macroMenuProc {Text Style} textnormal"
    "em"                        "TeX::macroMenuProc {Text Style} em"
    "upshape"                   "TeX::macroMenuProc {Text Style} upshape"
    "itshape"                   "TeX::macroMenuProc {Text Style} itshape"
    "slshape"                   "TeX::macroMenuProc {Text Style} slshape"
    "scshape"                   "TeX::macroMenuProc {Text Style} scshape"
    "mdseries"                  "TeX::macroMenuProc {Text Style} mdseries"
    "bfseries"                  "TeX::macroMenuProc {Text Style} bfseries"
    "rmfamily"                  "TeX::macroMenuProc {Text Style} rmfamily"
    "sffamily"                  "TeX::macroMenuProc {Text Style} sffamily"
    "ttfamily"                  "TeX::macroMenuProc {Text Style} ttfamily"
    "normalfont"                "TeX::macroMenuProc {Text Style} normalfont"
    "doTextSize"                "TeX::macroMenuProc {Text Size}"

    "textsuperscript"           "TeX::macroMenuProc {Text Commands} textsuperscript"
    "textcircled"               "TeX::macroMenuProc {Text Commands} textcircled"

    "ò"                         "TeX::macroMenuProc {International} {ò}"
    "ó"                         "TeX::macroMenuProc {International} {ó}"
    "ô"                         "TeX::macroMenuProc {International} {ô}"
    "ö"                         "TeX::macroMenuProc {International} {ö}"
    "õ"                         "TeX::macroMenuProc {International} {õ}"
    "ç"                         "TeX::macroMenuProc {International} {ç}"
    "Ç"                         "TeX::macroMenuProc {International} {Ç}"
    "œ"                         "TeX::macroMenuProc {International} {œ}"
    "Œ"                         "TeX::macroMenuProc {International} {Œ}"
    "æ"                         "TeX::macroMenuProc {International} {æ}"
    "Æ"                         "TeX::macroMenuProc {International} {Æ}"
    "å"                         "TeX::macroMenuProc {International} {å}"
    "Å"                         "TeX::macroMenuProc {International} {Å}"
    "ø"                         "TeX::macroMenuProc {International} {ø}"
    "Ø"                         "TeX::macroMenuProc {International} {Ø}"
    "ss"                        "TeX::macroMenuProc {International} {ss}"
    "SS"                        "TeX::macroMenuProc {International} {SS}"
    "¿"                         "TeX::macroMenuProc {International} {¿}"
    "¡"                         "TeX::macroMenuProc {International} {¡}"

    "mbox"                      "TeX::macroMenuProc {Boxes} mbox"
    "makebox"                   "TeX::macroMenuProc {Boxes} makebox"
    "fbox"                      "TeX::macroMenuProc {Boxes} fbox"
    "framebox"                  "TeX::macroMenuProc {Boxes} framebox"
    "newsavebox"                "TeX::macroMenuProc {Boxes} newsavebox"
    "sbox"                      "TeX::macroMenuProc {Boxes} sbox"
    "savebox"                   "TeX::macroMenuProc {Boxes} savebox"
    "usebox"                    "TeX::macroMenuProc {Boxes} usebox"
    "raisebox"                  "TeX::macroMenuProc {Boxes} raisebox"
    "parbox"                    "TeX::macroMenuProc {Boxes} parbox"
    "minipage"                  "TeX::macroMenuProc {Boxes} minipage"
    "rule"                      "TeX::macroMenuProc {Boxes} rule"

    "verb"                      "TeX::macroMenuProc {Miscellaneous} verb"
    "footnote"                  "TeX::macroMenuProc {Miscellaneous} footnote"
    "marginalNote"              "TeX::macroMenuProc {Miscellaneous} {marginal note}"
    "insertLabel"               "TeX::macroMenuProc {Miscellaneous} label"
    "ref"                       "TeX::macroMenuProc {Miscellaneous} ref"
    "eqref"                     "TeX::macroMenuProc {Miscellaneous} eqref"
    "pageref"                   "TeX::macroMenuProc {Miscellaneous} pageref"
    "cite"                      "TeX::macroMenuProc {Miscellaneous} cite"
    "nocite"                    "TeX::macroMenuProc {Miscellaneous} nocite"
    "insertItem"                "TeX::macroMenuProc {Miscellaneous} item"
    "quotes"                    "TeX::macroMenuProc {Miscellaneous} quotes"
    "dblQuotes"                 "TeX::macroMenuProc {Miscellaneous} {double quotes}"
    "texLogo"                   "TeX::macroMenuProc {Miscellaneous} {TeX logo}"
    "latexLogo"                 "TeX::macroMenuProc {Miscellaneous} {LaTeX logo}"
    "latex2eLogo"               "TeX::macroMenuProc {Miscellaneous} {LaTeX2e logo}"
    "today"                     "TeX::macroMenuProc {Miscellaneous} today"
    "dag"                       "TeX::macroMenuProc {Miscellaneous} dag"
    "ddag"                      "TeX::macroMenuProc {Miscellaneous} ddag"
    "sectionMark"               "TeX::macroMenuProc {Miscellaneous} {section mark}"
    "paragraphMark"             "TeX::macroMenuProc {Miscellaneous} {paragraph mark}"
    "copyright"                 "TeX::macroMenuProc {Miscellaneous} copyright"
    "pounds"                    "TeX::macroMenuProc {Miscellaneous} pounds"

    "texMath"                   "TeX::macroMenuProc {Math Modes} TeX math"
    "texDisplaymath"            "TeX::macroMenuProc {Math Modes} TeX displaymath"
    "latexMath"                 "TeX::macroMenuProc {Math Modes} LaTeX math"
    "latexDisplaymath"          "TeX::macroMenuProc {Math Modes} LaTeX displaymath"

    "doMathStyle"               "TeX::doMathStyle"
    "doUppercaseMathStyle"      "TeX::doUppercaseMathStyle"

    "subscript"                 "TeX::macroMenuProc {Formulas} subscript"
    "superscript"               "TeX::macroMenuProc {Formulas} superscript"
    "fraction"                  "TeX::macroMenuProc {Formulas} frac"
    "squareRoot"                "TeX::macroMenuProc {Formulas} sqrt"
    "nthRoot"                   "TeX::macroMenuProc {Formulas} {nth root}"
    "oneParameter"              "TeX::macroMenuProc {Formulas} {one parameter}"
    "twoParameters"             "TeX::macroMenuProc {Formulas} {two parameters}"

    "insertLargeOp"             "(no longer defined)"
    "sum"                       "TeX::macroMenuProc {Large Operators} sum"
    "prod"                      "TeX::macroMenuProc {Large Operators} prod"
    "coprod"                    "TeX::macroMenuProc {Large Operators} coprod"
    "int"                       "TeX::macroMenuProc {Large Operators} int"
    "oint"                      "TeX::macroMenuProc {Large Operators} oint"
    "bigcap"                    "TeX::macroMenuProc {Large Operators} bigcap"
    "bigcup"                    "TeX::macroMenuProc {Large Operators} bigcup"
    "bigsqcup"                  "TeX::macroMenuProc {Large Operators} bigsqcup"
    "bigvee"                    "TeX::macroMenuProc {Large Operators} bigvee"
    "bigwedge"                  "TeX::macroMenuProc {Large Operators} bigwedge"
    "bigodot"                   "TeX::macroMenuProc {Large Operators} bigodot"
    "bigotimes"                 "TeX::macroMenuProc {Large Operators} bigotimes"
    "bigoplus"                  "TeX::macroMenuProc {Large Operators} bigoplus"
    "biguplus"                  "TeX::macroMenuProc {Large Operators} biguplus"

    "delimitObject"             "TeX::delimitObject"

    "parentheses"               "TeX::macroMenuProc {Delimiters} {parentheses}"
    "brackets"                  "TeX::macroMenuProc {Delimiters} {brackets}"
    "braces"                    "TeX::macroMenuProc {Delimiters} {braces}"
    "absoluteValue"             "TeX::macroMenuProc {Delimiters} {vertical bars}"
    "otherDelims"               "TeX::macroMenuProc {Delimiters} {other delims}"
    "half-openInterval"         "TeX::macroMenuProc {Delimiters} {half-open interval}"
    "half-closedInterval"       "TeX::macroMenuProc {Delimiters} {half-closed interval}"
    "bigParens"                 "TeX::macroMenuProc {Delimiters} {big parentheses}"
    "multiBigParens"            "TeX::macroMenuProc {Delimiters} {multi-line big parentheses}"
    "bigBrackets"               "TeX::macroMenuProc {Delimiters} {big brackets}"
    "multiBigBrackets"          "TeX::macroMenuProc {Delimiters} {multi-line big brackets}"
    "bigBraces"                 "TeX::macroMenuProc {Delimiters} {big braces}"
    "multiBigBraces"            "TeX::macroMenuProc {Delimiters} {multi-line big braces}"
    "bigAbsValue"               "TeX::macroMenuProc {Delimiters} {big vertical bars}"
    "multiBigAbsValue"          "TeX::macroMenuProc {Delimiters} {multi-line big vertical bars}"
    "otherBigDelims"            "TeX::macroMenuProc {Delimiters} {other big delims}"
    "otherMultiBigDelims"       "TeX::macroMenuProc {Delimiters} {other multi-line big delims}"
    "bigLeftBrace"              "TeX::macroMenuProc {Delimiters} {big left brace}"
    "multiBigLeftBrace"         "TeX::macroMenuProc {Delimiters} {multi-line big left brace}"
    "otherMixedBigDelims"       "TeX::macroMenuProc {Delimiters} {other mixed big delims}"
    "otherMultiMixedBigDelims"  "TeX::macroMenuProc {Delimiters} {other multi-line mixed big delims}"

    "getDelims"                 "TeX::getDelims"
    "insertBigDelims"           "TeX::insertBigDelims"
    "doOtherBigDelims"          "TeX:doOtherBigDelims"
    "doOtherMixedBigDelims"     "TeX::doOtherMixedBigDelims"

    "acute"                     "TeX::macroMenuProc {Math Accents} acute"
    "bar"                       "TeX::macroMenuProc {Math Accents} bar"
    "breve"                     "TeX::macroMenuProc {Math Accents} breve"
    "check"                     "TeX::macroMenuProc {Math Accents} check"
    "dot"                       "TeX::macroMenuProc {Math Accents} dot"
    "ddot"                      "TeX::macroMenuProc {Math Accents} ddot"
    "grave"                     "TeX::macroMenuProc {Math Accents} grave"
    "hat"                       "TeX::macroMenuProc {Math Accents} hat"
    "tilde"                     "TeX::macroMenuProc {Math Accents} tilde"
    "vec"                       "TeX::macroMenuProc {Math Accents} vec"
    "widehat"                   "TeX::macroMenuProc {Math Accents} widehat"
    "widetilde"                 "TeX::macroMenuProc {Math Accents} widetilde"

    "underline"                 "TeX::macroMenuProc {Grouping} underline"
    "overline"                  "TeX::macroMenuProc {Grouping} overline"
    "underbrace"                "TeX::macroMenuProc {Grouping} underbrace"
    "overbrace"                 "TeX::macroMenuProc {Grouping} overbrace"
    "overrightarrow"            "TeX::macroMenuProc {Grouping} overrightarrow"
    "overleftarrow"             "TeX::macroMenuProc {Grouping} overleftarrow"
    "stackrel"                  "TeX::macroMenuProc {Grouping} stackrel"

    "negThin"                   "TeX::macroMenuProc {Spacing} {neg thin}"
    "thin"                      "TeX::macroMenuProc {Spacing} thin"
    "medium"                    "TeX::macroMenuProc {Spacing} medium"
    "thick"                     "TeX::macroMenuProc {Spacing} thick"
    "quad"                      "TeX::macroMenuProc {Spacing} quad"
    "qquad"                     "TeX::macroMenuProc {Spacing} qquad"
    "hspace"                    "TeX::macroMenuProc {Spacing} hspace"
    "vspace"                    "TeX::macroMenuProc {Spacing} vspace"
    "hfill"                     "TeX::macroMenuProc {Spacing} hfill"
    "vfill"                     "TeX::macroMenuProc {Spacing} vfill"
    "smallskip"                 "TeX::macroMenuProc {Spacing} smallskip"
    "medskip"                   "TeX::macroMenuProc {Spacing} medskip"
    "bigskip"                   "TeX::macroMenuProc {Spacing} bigskip"
}

# These are from "latexMenu.tcl"

array set TeX::ObseleteProcMapping {

    "buildLaTeXMenu"            "TeX::buildLaTeXMenu"
    "buildLaTeXMenuQuietly"     "(no longer defined)"
    "listToDummySubmenus"       "TeX::buildSubmenus"
    "synchronizeDoc"            "TeX::Textures::synchronizeDoc"
    "TeX::sub::MakeIndex"       "TeX::buildMakeIndexMenu"
    "TeX::sub::Math"            "TeX::buildMathMenus"
    "TeX::sub::MathModes"       "TeX::setMathModesItems"
    "TeX::sub::MinimalProcess"  "TeX::buildMinimalProcess"
    "TeX::sub::Packages"        "TeX::buildPackagesMenu"
    "TeX::sub::Process"         "TeX::buildProcessMenu"
    "TeX::sub::ProcessOpen"     "TeX::buildProcessOpenMenu"
    "TeX::sub::Text"            "TeX::buildTextMenus"
    "toggleAMSLaTeX"            "(no longer defined)"
    "toggleAMSLaTeXmenus"       {
	TeX::setMathStyleMenuItems ;
	TeX::setTextSizeMenuItems ;
	TeX::setMathEnvsMenuItems
    }
    "toggleLaTeXMenuItem"       "(no longer defined)"
    "toggleLaTeXMenus"          "(no longer defined)"

    "TeX::mp::latex"            "TeX::menuProc"
    "TeX::mp::internat"         "TeX::macroMenuProc"
    "TeX::mp::goto"             "TeX::menuProc"
    "TeX::mp::latexUtils"       "TeX::menuProc"
    "TeX::mp::documents"        "TeX::menuProc"
    "TeX::mp::pageLayout"       "TeX::macroMenuProc"
    "TeX::mp::sectioning"       "TeX::macroMenuProc"
    "TeX::mp::textCommands"     "TeX::macroMenuProc"
    "TeX::mp::textSize"         "TeX::macroMenuProc"
    "TeX::mp::envs"             "TeX::macroMenuProc"
    "TeX::mp::misc"             "TeX::macroMenuProc"
    "TeX::mp::mathModes"        "TeX::macroMenuProc"
    "TeX::mp::mathStyle"        "TeX::macroMenuProc"
    "TeX::mp::mathEnvs"         "TeX::macroMenuProc"
    "TeX::mp::theorem"          "TeX::macroMenuProc"
    "TeX::mp::formulas"         "TeX::macroMenuProc"
    "TeX::mp::greek"            "TeX::macroMenuProc"
    "TeX::mp::binaryOperators"  "TeX::macroMenuProc"
    "TeX::mp::relations"        "TeX::macroMenuProc"
    "TeX::mp::arrows"           "TeX::macroMenuProc"
    "TeX::mp::generalMath"      "TeX::macroMenuProc"
    "TeX::mp::delimiters"       "TeX::macroMenuProc"
    "TeX::mp::spacing"          "TeX::macroMenuProc"
    "TeX::mp::package"          "TeX::packagesMenuProc"
    "TeX::mp::Processmenu"      "TeX::menuProc"
}

# ◊◊◊◊ "latexNavigation.tcl" ◊◊◊◊ #

array set TeX::ObseleteProcMapping {

    "findEnvironment"           "TeX::findEnvironment"
    "findCommand"               "TeX::findCommand"
    "findCommandWithArgs"       "TeX::findCommandWithArgs"
    "findSection"               "TeX::findSection"
    "findSubsection"            "TeX::findSubsection"

    "prevEnvironment"           "TeX::menuProc {Goto} {Prev Environment}"
    "nextEnvironment"           "TeX::menuProc {Goto} {Next Environment}"
    "prevEnvironmentSelect"     "TeX::menuProc {Goto} {Prev Environment Select}"
    "nextEnvironmentSelect"     "TeX::menuProc {Goto} {Next Environment Select}"
    "prevCommand"               "TeX::menuProc {Goto} {Prev Command}"
    "nextCommand"               "TeX::menuProc {Goto} {Next Command}"
    "prevCommandSelect"         "TeX::menuProc {Goto} {Prev Command Select}"
    "nextCommandSelect"         "TeX::menuProc {Goto} {Next Command Select}"
    "prevCommandSelectWithArgs" "TeX::menuProc {Goto} {Prev Command Select With Args}"
    "nextCommandSelectWithArgs" "TeX::menuProc {Goto} {Next Command Select With Args}"
    "prevSection"               "TeX::menuProc {Goto} {Prev Section}"
    "nextSection"               "TeX::menuProc {Goto} {Next Section}"
    "prevSectionSelect"         "TeX::menuProc {Goto} {Prev Section Select}"
    "nextSectionSelect"         "TeX::menuProc {Goto} {Next Section Select}"
    "prevSubsection"            "TeX::menuProc {Goto} {Prev Subsection}"
    "nextSubsection"            "TeX::menuProc {Goto} {Next Subsection}"
    "prevSubsectionSelect"      "TeX::menuProc {Goto} {Prev Subsection Select}"
    "nextSubsectionSelect"      "TeX::menuProc {Goto} {Next Subsection Select}"
}

# ◊◊◊◊ "latexSmart.tcl" ◊◊◊◊ #

# array set TeX::ObseleteProcMapping {
# 
#     "smartDQuote"               "TeX::smartDQuote"
#     "smartQuote"                "TeX::smartQuote"
#     "leftQ"                     "TeX::leftQ"
#     "smartDots"                 "TeX::smartDots"
#     "smartSubscripts"           "TeX::smartSubscripts"
#     "smartSuperscripts"         "TeX::smartSuperscripts"
#     "smartScripts"              "TeX::smartScripts"
#     "escapeSmartStuff"          "TeX::escapeSmartStuff"
# }

# ◊◊◊◊ "latexUtilities.tcl" ◊◊◊◊ #

# array set TeX::ObseleteProcMapping {
# 
#     "deleteComments"                    "TeX::deleteComments"
#     "convertQuotes"                     "TeX::convertQuotes"
#     "convertDollarSigns"                "TeX::convertDollarSigns"
#     "convertDoubleDollarSigns"          "TeX::convertDoubleDollarSigns"
#     "containsDoubleDollarSigns"         "TeX::containsDoubleDollarSigns"
#     "convertSingleDollarSigns"          "TeX::convertSingleDollarSigns"
#     "containsSingleDollarSign"          "TeX::containsSingleDollarSign"
# }

# ◊◊◊◊ "TeXCompletions.tcl" ◊◊◊◊ #

# array set TeX::ObseleteProcMapping {
#     
#     "TeXAddItem"                        "TeX::addItem"
#     "TeX::Completion::beginContraction" "TeX::Completion::BeginContraction"
# }

# ◊◊◊◊ -------- ◊◊◊◊ #

foreach procName [array names TeX::ObseleteProcMapping] {
    if {[info procs $procName] == ""} {
        # We only do this if the proc isn't defined somewhere.
	if {[set TeX::ObseleteProcMapping($procName)] == "(no longer defined)"} {
	    # These were all called internally by other TeX mode code, so
	    # hopefully they will never get this far.
	    ;proc $procName {args} {
		warningForObsProc
		return -code error "This is an obsolete TeX mode support proc."
	    }
	} else {
	    ;proc $procName {args} {
		global TeX::ObseleteProcMapping
		TeX::obsoleteProc
		set oldProc [lindex [info level 0] 0]
		eval [set TeX::ObseleteProcMapping([set oldProc])] [set args]
	    }
	}
    }
}
unset -nocomplain procName

proc TeX::obsoleteProc {} {

    global PREFS TeX::ObseleteProcMapping TeX::SeenObsProcs

    # Figure out the proc which called this.
    set procName [lindex [info level -1] 0]
    set procArgs [lrange [info level -1] 1 end]
    # Have we seen this one before?
    if {[lcontains TeX::SeenObsProcs $procName]} {return}
    lappend TeX::SeenObsProcs $procName
    # Determine the new proc name.
    set newProc  [set TeX::ObseleteProcMapping($procName)]

    set d  1
    set d$d {dialog::make -title "TeX Back Compatibility" }

    regsub -- {^::} [lindex [info level 1] {0 0}] "" fromProc
    if {$fromProc == $procName || ![auto_load ::$fromProc]} {
	# Must have been called from a binding, or user's prefs code.
        set  t1 "The procedure '$procName' is now obsolete, and must have been\
          called via a user-defined key-binding.  The name of the new procedure\
          that should be called is\r\r\ '$newProc'\r\r\
          and you should change the binding.  Please\
          report any further difficulties to the AlphaTcl mailing lists.\r\r\
          Press 'OK' to continue with the operation."
        set b1 "Place the new proc name in clipboard"
        set h1 ""
        set s1 "putScrap $newProc ; status::msg \"'$newProc' is now in the clipboard\""
	set buttonList [list $b1 $h1 $s1]
	if {[file exists [file join $PREFS prefs.tcl]]} {
	    set b2 "Edit prefs.tcl"
	    set h2 ""
	    set s2 "file::openQuietly \"[file join $PREFS prefs.tcl]\" ; set retCode 1 ; set retVal {}"
	    lappend buttonList $b2 $h2 $s2
	} 
	if {[file exists [file join $PREFS TeXPrefs.tcl]]} {
            set b3 "Edit TeXPrefs"
            set h3 ""
            set s3 "file::openQuietly \"[file join $PREFS TeXPrefs.tcl]\" ; set retCode 1 ; set retVal {}"
	    lappend buttonList $b3 $h3 $s3
        }
	append d$d "-addbuttons [list $buttonList] "
    } else {
        # Must have been called from a other code.
        set  t1 "The procedure '$procName' is now obsolete, and was called by\
          the procedure '$fromProc'.  The new procedure name that should\
          be called is\r\r '$newProc'\r\r\
          and this code should be updated.  Please\
          report any further difficulties to the AlphaTcl mailing lists.\r\r\
          Press 'OK' to continue with the operation."
        set b1 "Place the new proc name in clipboard"
        set h1 ""
        set s1 "putScrap $newProc ; status::msg \"'$newProc' is now in the clipboard\""
        set b2 "Edit Source File"
        set h2 ""
        set s2 "Tcl::DblClickHelper $fromProc ; set retCode 1 ; set retVal {}"
        append d$d "-addbuttons [list [list $b1 $h1 $s1 $b2 $h2 $s2]] "
    }
    incr d
    lappend d$d "Obsolete TeX proc warning !!"
    lappend d$d [list text $t1]
    lappend dP  [set d$d]

    if {[catch {eval $d1 $dP}]} {return -code return}
}

# ==========================================================================
#
# .