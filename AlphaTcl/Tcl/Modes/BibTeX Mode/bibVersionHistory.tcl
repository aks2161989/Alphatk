## -*-Tcl-*-
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibVersionHistory.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 01/19/2005 {01:27:33 PM}
 # Description: 
 # 
 # Version history of Bib mode, and any back compatibility procs.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

proc bibVersionHistory.tcl {} {}

# load main bib file!
bibtexMode.tcl

# ===========================================================================
# 
# ×××× Back Compatability ×××× #
# 
# Ensuring the certain procs from the AlphaTcl library are in place, or
# procs from previous versions of Bib mode.
# 

proc Bib::getEntry {args} {eval Bib::entryLimits $args}

return

# ===========================================================================
# 
# ×××× To Do ×××× #
# 
# * Create a [Bib::activateHook] in case menu is turned on globally.
# * Make use of [variable] for variables in Bib namespace.
# * Rewrite this file in a proper "ChangeLog" format.
# 

# ===========================================================================
# 
# ×××× Version history ×××× #
# 
# 1.0  (09/93)    First stable version.
# 1.1  (06/94)    Custom BibTeX icon, 
#                 Added simple search capability (matchingEntries).
# 1.2  (07/94)    Bib mode definition adapted to Alpha 5.85,
#                 Added bib-file marking (bibMarkFile),
#                 Entry and field creation now controlled by data arrays.
# 1.4  (07/94)    Added sorting by authors, but still only semi-functional,
#                 Added regexp searching by field,
#                 "getEntry" bugs fixed.
# 1.5  (07/94)    "sortByAuthors" is now robust,
#                 Mode of new windows now set correctly.
# 1.6   (08/94)   'preferBraces' allows braces or quotes to be default for
#                   new or reformatted entries,
#                 Menu built using $entryNames and $fieldNames,
#                 'sortByAuthors' can now sort using last author first,
#                   and is a bit faster,
#                 'formatEntry' rewrites entries in canonical format,
#                 More customization of canonical format allowed ('indentString')
#                 Bib mode definition adapted to Alpha 5.90.
# 1.7   (08/94)   Bug fixes and accomodations to latex.tcl v2.2
#                 Template insertion streamlined
#                 Choose multiple fields at a time from a list dialog
# 1.8   (08/94)   "getEntry" now recognizes parens as entry delimiters
# 1.9   (09/94)   'getFields' should now correctly parse any legal entry.
#                 'language' field now included.
#                 Default values for new fields (eg 'language') may be defined
#                 'preferBraces' replaced by 'fieldBraces' and 'entryBraces'.
#                 line-wrapping is done on reformatted entries.
#                 '@string' entries preserved in sorts.
#                 text before first entry and after last entry are preserved
#                   by sorts.
# 2.0   (09/94)   'formatEntry' and 'newEntry' line up fields better.
#                 'nextEntry' and 'prevEntry' skip @string defs
#                 'formatEntry' automatically goes to next entry afterwards.
#                 'sortByCitekey' ignores case of cite keys.
#                 'fillColumn' included as default modeVar.
#                 'getEntry' alerts user to badly delimited entries.
# 2.1   (12/94)   'countEntries' command added.
#                 'formatAllEntries' command added; it's a bit clunky, but more 
#                   robust than any quicker alternative I considered.
#                 Cross-referenced entries now sort to the bottom in all sorts.
#                 'crossref' field now included.
# 2.1.1 (12/94)   Bug fixes in 'formatAllEntries'.
# 2.2   (12/94)   'formatEntries' won't quote fields that contain "#".
#                 'segregateStrings' flag forces string defs to sort to the top.
# 2.3   (04/95)   International characters converted to TeX codes (optionally).
#                 'findEntries' bug fixed (no longer returns multiple hits) 
# 2.4   (05/95)   Fixed bugs in parsing of EndNote-created bib files
# 2.4.1 (06/95)   Updates for compatibility with revised LaTeX mode
#                 Automatic conversion of international characters dropped 
#                   (irreconcilable problems with non-US keyboards).
# 2.5   (06/95)   Fixed bug in formatEntry, whereby '#' concatenations were lost 
#                 formatEntry completely ignores @string entries now
#                 Entry-parsing code (getFields, getFldVal) cleaned up,
#                   should also be a little bit faster now.
#                 formatAllEntries now starts working from the current entry
# 2.6   (06/95)   'zapEmptyFields' flag forces optional fields to be removed 
#                   when reformatting an entry.
#                 'markStrings' flag controls whether @string entries are 
#                   included in the marks menu.
#                 'descendingYears' flag controls whether sorts are in ascending 
#                   or descending chronological order.
#                 Sorts all use the year as either primary or secondary sort key 
#                   now.
#                 'copyCiteKey' command copies the citekey of the current entry 
#                   to the clipboard.
#                 Cmd-double-clicking implemented to resolve abbreviations, 
#                   crossrefs.
#                 Fixed bug in faster getFields proc (comma-after-last-field 
#                   problems)  
#                 Fixed minor bugs in author sorting.  
# 2.6.1 (07/95)   fixed "SearchFields" bug.
# 2.6.2 (07/95)   field delimiters suppressed if field data is an abbreviation
#                 unindexed .bib files are indexed automatically upon opening
# 2.7   (07/95)   'stdAbbrevs' modeVar added for setting predefined abbrevs
#                 month names included as predefined abbrevs
#                 'alignEquals' formatting flag added.
# 3.0   (01/98)   Updated for Alpha 7.0, added some code for useful 
#                   integration with latex mode, and with things like citation
#                   completion (so you can type, in a .tex file, \cite{Smi
#                   and have it extended to an entry from one of your .bib files.
# 3.1 - 3.4       ???
# 3.5   (05/00)   "myFld" now set through Mode Preferences dialog.
#                 Colors now set through Mode Preferences dialog.
#                 Comment menu items enabled.
#                 Smart quotes, dots from TeX mode now optional preference.
#                 Reorganization of procs.
#                 Version history moved to this file from Help file.
#                 Updated BibTeX Help file.
# 3.5.1 (05/00)   "countEntries" was lost somehow.  It's back now.
#                 "annote", "isbn" (cbu personal fields) removed from field list.
# 3.6   (09/00)   Major reorganization of the structure of the mode, 
#                   including dividing this file into four major sections.
#                   In version 4.0, there will be a "BibTeX Mode" folder.  
#  Note: 
#  
#  Previous versions of Bib mode required the user to modify the myFld()
#  array in order to set the fields for entries.  Version 3.5 introduced a
#  method for doing this through the Mode Preferences dialog, by setting
#  "customEntryName" preferences, and assigning them to myFld(entryName). 
#  Unfortunately, there was no easy way to update this array without a
#  restart.
#  
#  Version 3.6 brings default entry field preferences into the BibTeX menu,
#  and modifies the newEntry proc to look for these preferences when
#  creating a field list.  "customEntryName" preferences are now only
#  created when necessary, and can be modified (or deleted) on the fly
#  directly from the menu.  Any entries in the myFld() array will still
#  take precedence over the preferences (none of this code was deleted, and
#  its support is actually enhanced), but this is no longer the preferred
#  method and it is not advertised.  Not that it ever was ...
#  
#                 bibtexMode.tcl:
#                 
#                 Conversions now default mode features.
#                 Removed all of the default customEntryName preferences.
#                 Changed all "if [ ... ]" to "if {[ ... ]}"
#                 Preference "addField" will rebuild Fields submenu, and check
#                   to see if the field is already defined as a keyword.
#                 Added "fieldCompletions", "latexCompletions" preferences.
#                 Added "hierarchicalMenu" preference to change menu.
#                 Renamed "useModePaths" to "useSearchPaths" preference, to
#                   make it consistent with the menu items that set the paths.
#                 Added "unsetAcronymList" to remove the pre-defined acronyms.
#                 Refined the Bib::updatePreferences proc to be pref specific.
#                 Added Bib::updateMyFld to deal with changes to rqdFld(), 
#                   optFld(), myFld() arrays, to be used in BibPrefs.tcl files.
#                   Instructions included in "BibTeX Help".
#                 Added Bib::removeObsolete to remove customEntryName
#                   preferences.  (Based on the proc: prefs::removeObsolete, 
#                   which is only available in Tcl libraries 7.4 and higher.
#                 Added Bib::editPreference to bypass "Mode Prefs" dialog.
#                 Added Bib::flagFlip to update preference bullets in menu.
#                 Added Bib::entryPrefConnect to transform entryName into
#                   customEntryName, and back again.
#                 Added an entryNameConnect() array to transform lower-case
#                   entrynames to entryName.  Used in formatting and validating.
#                 Added Bib::customEntryList to return list of preferences,
#                   with various optional arguments for different lists.
#                 "customField" is no longer a default field, but is colored
#                   red to alert the user that it should be changed.
#                 Added Bib::set{KeywordLists}, which set lists of entries and
#                   fields for menus, menu items, completions.
#                 "@" is no longer a magic character.  Instead, only recognized
#                   @entryNames are colored.  (I thought that this would be a
#                   fix for AlphaTk, but it's not.  It's still handy to know
#                   that the entryName is spelled correctly.)
#                 "customField" is colored red to alert the user to change it.  
#                 Command double-click modified for "Results" windows.
#                 Bib::MarkFile now counts entries / strings, gives message.  It
#                   also ignores Results and Index files, which have their own
#                   special marking routines.
#                   
#                 bibtexData.tcl:
#                 
#                 Added all of the index, database, and TeX mode support here.
#                 Changed all "if [ ... ]" to "if {[ ... ]}"
#                 Unless "rebuildIndex" and "rebuildDatabase" are actually
#                   called from the bibtexMenu, the preference "bibAutoIndex"
#                   is now checked.  Calling procs no longer need to inquire.
#                 If the list of files to index is empty, no bibIndex file is
#                   created. 
#                 "Bib::rebuildDatabase" queries before closing files.
#                 "Bib::listAllBibliographies" modified to allow it to be called
#                   from the menu.  Added a "useOpenWindows" preference to allow
#                   all open .bib files to be included in a database.
#                 Added "Bib::listOpenBibFiles" to include these in the list.
#                 "Bib::noEntryExists" can now call "Bib::searchAllBibFiles".
#                 No changes to actual calling procedures.
#                 
#                 bibtexMenu.tcl:
#                 
#                 Reorganization of BibTeX menu items.
#                 Changed all "if [ ... ]" to "if {[ ... ]}"
#                 All menus now have a "menu::buildProc ..."
#                 Menus can be rebuilt using "Bib::rebuildMenu <menuName>"
#                 The preference "hierarchicalMenu" can place all of the 
#                   Navigating, Searching, and Formatting items in the main
#                   menu or in separate hierarchical menus.
#                 Modifed the Bib::menuProc, because all menu items are now
#                   in the Bib namespace.
#                 Changed "Bibtex" to "Bib::bibtexApplication".
#                 Added "BibTeX File List" menu, which contains all of the 
#                   .bib files that would currently be used to create an
#                   index or database.  Allows the user to select a default
#                   .bib file.
#                 "bibFormatSetup" is no longer called by entry, field procs.
#                   (Scanning for @strings was not at all necessary, and could
#                   really slow things down.)
#                 "Custom Entry" menu item now prompts for the entry's name,
#                   and offers to make this a default menu item, and will reload
#                   completions and rebuild "entries" menu.
#                 Added "string" to the list of entries, as a special case.
#                 Changes to default entry fields now take immediate effect,
#                   but are still over-ridden by the myFld() array.
#                 Holding down any modifier key for an Entry menu item will
#                   open a dialog to edit the default fields.
#                 "Custom Field" menu item now asks about making the field a
#                   default menu item, and will reload completions and 
#                   rebuild "fields" menu.
#                 Holding down any modifier key for a Field menu item will 
#                   open a dialog to edit the "addFields" preference.
#                 "fieldsProc" now recognizes if we're in front of a field,
#                   and will insert at the beginning of the line if we are.
#                   Otherwise it inserts on the next line.
#                 Added "Cite Key Lists" menu, which now contains "Count Entries"
#                   and "Index This Window."  Also has new procs for checking
#                   duplicate cite keys both in the current window and across
#                   files.  (This might not be the most efficient method...)
#                 Cite key lists can be created from a menu item, but are
#                   over-written during any new duplicate search.  The menu 
#                   contains a list of all files that have been added -- 
#                   selecting any menu item will put the list in a new window.
#                 "Bib::listCiteKeys" (formerly "Index This Window") 's result
#                   window cleaned up, is now in Bib mode.  Double-clicking
#                   on cite-keys will jump to the entry's definition.
#                 The results of all searches can either be written to a new 
#                   "Search Results" window, or appended to a current one.
#                 "Bib::writeEntries" will no longer overwrite the buffer if
#                   the calling proc was not a sort.
#                 "Bib::searchAllBibFiles" now does a quick grep of the bib files
#                   returned by Bib::listAllBibliographies.  So handy !!
#                   Also used by Bib::noEntryExists.
#                 "Bib::formatEntry", "Bib::formatAllEntries" will now convert
#                   tabs to spaces, otherwise formatting can get real funky.
#                   (Most noticable in the Hollis-Example.hollis file.)
#                 Bug fix for formatting, using entryNameConnect.  If zap empty
#                   fields was set, rqdFld(incollection) (for example) would
#                   previously return an error.  entryNames are no longer put
#                   in lower case during reformatting.
#                 Any formatting errors are reported in a "Format Results" 
#                   window, with line numbers and cite-keys.  Command double-
#                   clicking on either will jump to the entry's definition.
#                 Attempted to streamline the formatting procs for a little
#                   speed enhancement, but it's negligable.  The presence of a
#                   large number of @string's still slows it way down.
#                 If the number of strings hasn't changed since the last
#                   formatting proc was called, we don't scan them again.
#                 "Bib::validateEntry" and "Bib::validateAllEntries" added, with
#                   similar behavior (i.e. command double click) for the Format 
#                   Results window.  Missing (required) fields are listed both
#                   in the window and the marks menu.  The preference 
#                   "ignoreExtraFields" determines if "extra" fields
#                   are also reported. Duplicate cite-keys and unrecognized
#                   entries are also listed.
#                 "Sort ByÉ" will now mark file if "autoMark" preference is set.
#                 "Bibtex Conversions" submenu added.
#                 Added "Default Entry Fields" menu, which will create / modify
#                   mode preferences for custom... fields.  Entries which have
#                   customEntryName preferences marked in the menu by a *.
#                   Entries defined in the myFld() array are dimmed.
#                 Added "Bib::restoreDefaultFields" menu item, which presents the
#                   user with a list of all customEntryName preferences.
#                   Dimmed if there are no defined customEntryName preferences.
#                 Added "Bib::removeCustomEntry", dimmed if no user defined
#                   entries.
#                 Added "Bib::removeCustomField", which edits the addField pref,
#                   dimmed if the preference is empty.
#                 Added "Bibtex Mode Options" menu, includes "Bibtex Mode Help".
#                 Added most of the flag preferences to "Options" menu, which
#                   are all toggeable.
#                 Holding down any modifier key for an Options menu item will
#                   display an alertnote with a description of the preference.
#                 Added "Bib Mode Acronyms" menu, which makes the creation / 
#                   manipulation of the BibAcronyms array much easier.
#                 Added "Bib::checkKeywords" to query the existing defined
#                   keywords.
#                 Added "BibTeX Files" menu, which includes the preferences 
#                   used to create the bibliography list, as well as the menu
#                   items added by the package: searchPaths -- search paths
#                   can be set even if the feature is not global.
#                 Added "List All Bibliographies" to this menu, so that one can
#                   check the list of all .bib files that would be included in
#                   the database / index, or open one of them if desired. 
#                 
#                 BibCompletions.tcl:
#                 
#                 "Bibcmds" now set in bibtexMode.tcl, and can be updated.
#                 Fields now available as electric completions, but can be
#                   turned off with flag preference.
#                 Color, Completions support for select LaTeX commands, but
#                   completions can be turned off with flag preference.
#                 User preference to add additional LaTeX commands.
#                 Added Completions Tutorial.
#                 Simplified the completion procs, so that they simply
#                   call the appropriate menu item.
#                 Completion and Expansion support for acronyms.  Added support
#                   for this through the "Bib Mode Acronyms" menu.
#                   
# 3.6.1 (10/00)   Minor bug fix in Bib::DblClickFindFile to properly identify
#                   results files from the "smart mode line".
#                 Added Bib::countAllEntries.
#                 Better "Cite Key Lists" hierarchical/dynamic menus.
#                 More minor fixes to dynamic menu definitions.
# 3.6.2 (10/00)   Bug fix in Bib::copyCiteKey.
#                 Added "Bib::editAcronyms".
#                 Bib mode now requires AlphaTcl 7.2.2 for prefs handling.
#                 Several changes from [string trimleft $string $firstChar] to 
#                   [string range $string 1 end].
#                 Fix for latex completions in "BibCompletions.tcl".
#                 Bib::writeEntries highlights search pattern in results window.
#                 Bib::MarkFile message reports duplicates.
#                 Bib::MarkFile for Search Results windows inserts a divider
#                   between different search results.
#                 Fixed bug in Bib::DblClickFindFile, when "Search Results"
#                   window was closed and user chose multiple files to open.
#                 Menu key-binding fixes that only showed up in AlphaTk.
#                 Bib::writeEntries bug fix for "$beg" and [minPos]
#                 More AlphaTk bug fixes, most related to pos::compare, etc.
# 3.7  (11/00)    requireOpenWindowsHook items removed from mode declaration.
#                 Bug fix in Bib::findDuplicates.
#                 Bib::buildFileListMenu doesn't capitalize file names.
#                 Bib::parseFuncs returns every 10th citekey.
#                 Bib::listAllBibliographies -- New fileÉ option now tries
#                   to use file::newDocument.
#                 Added Bib::addWinToIndex.
#                 Both Bib::addWinToIndex and Bib::addWinToDatabase can take
#                   a list of files, "Add Files To ..." added to menu.
#                 Databases and Indices can now be reviewed, removed.
#                 Added Bib::BibModeMenuItem to help ensure that key-bindings
#                   do not call inappropriate items in other modes.
#                 Similarly, added manual bindings for menu items to avoid
#                   conflicts with other global bindings.
#                 Added Bib::searchFunc to navigate using keypad.
#                 Changed the license to reflect the fact that this was an
#                   inherited mode, with more liberal copyright than GNU.
#                 Fixed bug in Bib::findDuplicates.
#                 Better bibTopPat regexps to handle "@article {citeKey," .
#                 Fix to Bib::Completion::Entry to use customEntries.
#                 Fix to Bib::getFldName to allow for cap fields.
#                 Fix to Bib::searchFields regexp search pattern.
# 4.0  (11/00)    Mode now split into six files.
#                 Fix to Bib::formatAllEntries, removing the tabsToSpaces
#                   from the whole file, which can cause memory errors,
#                   adding it instead to the individual formatting of entries.
#                 Require AlphaTcl 7.4fc1, removing back compatability procs.
# 4.1  (02/01)    The menu proc "Edit Custom Fields" now includes an option
#                   to grab all of the "extra" fields from the current window,
#                   using Bib::addWinFields.
#                 New preferences that dictate how the menu is built, allowing
#                   for a "shorter" menu, and one that does not include the
#                   database/bib file menu items.
#                 Better use of Bib::listAllBibliographies when creating menu,
#                   or when making changes that affect the list.
#                 Faster build of the bibtexMenu, less use of build procs
#                   for simple submenus.
#                 Keypad 1 and 3 will now center the next/prev entry in window.
#                 If text is highlighted when navigating, these items will
#                   extend the selection to the next/previous entry.
# 4.1.1 (02/01)   Improved dialogs for acronyms.  Now only view acronyms after
#                   an edit/remove/restore if the view window was already open.
# 4.1.2 (03/01)   Bib::isBibFile can now accept the "Bib Mode Example" window.
# 4.1.3 (03/01)   Bug fix for Bib::sortFileByProc.
#                 New entries are now placed at the beginning of the current
#                   line if we are not currently in an entry.
# 4.1.4 (03/01)   Bug fix for formatting fields which contain \# (not just #).
#                 Formatting now preserves {{Odd Name}} etc fields.
# 4.1.5 (04/01)   Added Bib::startPara etc for better indentation.
#                 Better file marking with duplicate citeKeys.
# 4.2   (07/01)   Better Alphatk colorizing.
#                 Added '@' to wordBreak pref, required a few changes in setting
#                   Bibcmds, and in completions.
#                 Replacement of 'synchroniseModeVar' with 'prefs::modified'.
#                 BibIndex can be rebuilt if it is out of date.
# 4.2.x (05/02)   Various fixes reported on Alpha mailing lists.
# 4.3   (07/02)   Various minor bug fixes.
#                 'String Conversions' submenu added, to convert individual
#                   entries or an entire window to/from '@string' strings.
#                 If there is an selection when the 'Entries' menu items are
#                   called, each line is used as a default field value.
#                 Contextual Menu modules added.
#                 Removed 'shortBibMenu' and 'databaseMenuItems' prefs.
#                 Distinguish between Format/Validate 'Remaining' vs 'All'.
#                 New 'breakIntoLines' preference for formatting.
#                 Formatting strings now actually does something.
#                 New procs 'Bib::isInEntry', and string procs.
#                 New files "bibtexSearch.tcl" "bibtexStrings.tcl", and
#                   "BibPrefs.tcl" to help re-organize procs into manageable
#                    units.  (Again.)
#                 Moved 'Acronyms' procs to "BibCompletions.tcl" file.
#                 Formatting, String conversions now scan the entire window
#                   and do a single replace at the end.  Much faster!
#                 "Bib::copyCiteKey" now doesn't mess with selection at all,
#                   grabs the citeKey silently.  Created "Bib::getCiteKey" proc.
#                 Cool 'prefs' icon used in pref setting menus.
#                 Added support for entry folding (Alphatk only).
#                 Support for case sensitive entry, field names.
#                 Added 'Bib::entryFields', which returns fields for type.
#                   'type' can be any case.
#                 Proper capitalization of title fields now available.
# 	          'Smart Escape' now piggy-backs on TeX code so that packages
# 	            which define smart character escapes work in both modes.
# 	          Field Value completions for fields which might have repeating 
# 		    information (author, journal, etc).
# 4.3.2 (07/03)   New handling of "fillColumn" variable using optional args
#                   for [breakIntoLines] in [Bib::bibFormatEntry].
#                 "breakIntoLines" pref renamed to "wrappedFields".
#                 New [Bib::correctionIndentation] proc to mimic the indents
#                   that will be used by formatting the entry.
# 4.3.3 (08/03)   More sophisticated "electricBraces" behavior.
# 4.3.4 (12/03)   Added Joachim's "useKspewhich" pref for listing bib files.
# 4.4   (11/04)   New [Bib::modePrefsDialog] categorizes preferences.
#                 Some preferences have been renamed:
#                   "segregateStrings"  > "segregateStringsDuringSort"
#                   "overwriteBuffer"   > "overwriteBufferDuringSort"
#                   "descendingYears"   > "sortByDescendingYears"
#                 During formatting and validating, malformed entries now
#                   explicitly throw an informative error.  This required a
#                   new [Bib::getFields] implementation; I'm surprised that
#                   the old one worked as well as it did.  (c.f. bug 1159
#                   and bug 1160.)
# 4.4.1 (01/05)   [Bib::rebuildMenu] is no longer necessary, just call
#                   [menu::buildSome] which now handles open window dimming.
# 

# ===========================================================================
# 
# .