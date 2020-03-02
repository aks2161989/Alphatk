## -*-Tcl-*-
 # ==========================================================================
 # Perl mode - an extension package for Alpha
 # 
 # FILE: "perlVersionHistory.tcl"
 #                                    created: 08/17/1994 {09:12:06 am} 
 #                                last update: 03/06/2006 {08:09:26 PM}
 #                                
 # Original by Tom Pollard <pollard@schrodinger.com>. 
 #  
 # Includes contributions from:
 #  
 #  Vince Darley         <vince@santafe.edu>
 #  Dan Herron           <herron@cogsci.ucsd.edu>
 #  David Schooley       <schooley@ee.gatech.edu>
 #  Tom Fetherston       <ranch1@earthlink.net>
 #  Martijn Koster       <m.koster@nexor.co.uk>
 #  Craig Barton Upright <cupright@alumni.princeton.edu>
 #  
 # --------------------------------------------------------------------------
 # 
 # Copyright (c) 1993-2006  Tom Pollard
 # All rights reserved.
 # 
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 # 
 #  ¥ Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 # 
 #  ¥ Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 # 
 #  ¥ Neither the name of Alpha/Alphatk nor the names of its contributors may
 #    be used to endorse or promote products derived from this software
 #    without specific prior written permission.
 # 
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 # ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
 # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 # DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 # CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 # LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 # OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 # DAMAGE.
 # ==========================================================================
 ## 

# ===========================================================================
# 
# 0.1   09/93  Text filter functionality created
# 0.2   01/94  Menu support added (Martijn Koster <m.koster@nexor.co.uk>)
#              'execute selection', 'execute buffer' commands added
# 0.5   02/94  'filters', 'open special' submenu added
#              'overwrite' flag added
# 0.6   03/94  'applyToBuffer' flag added
#              Scripts in Alpha buffers can now be used as filters 
# 0.7   03/94  Nested Text Filters folder now supported
#              Menu format modified somewhat
# 0.8   03/94  Flags are now check-marked
# 0.9   03/94  Perl-mode stuff added, and highlighted 'Perl commands' file 
#                (man page) prepared minor bug fixes, too
# 1.0   07/94  Perl-mode setup updated for Alpha 5.85:
#                keyword colorization supported
#                custom file-marking added
#              #! lines in filter scripts now handled correctly 
#              Workarounds installed for AppleEvent bug in MacPerl 4.1.3
# 1.1   08/94  'quitMacperl' added.
#              Perl-mode file-marking updated for Alpha 5.90
#              Simplified installation via 'loadMacperl'(Pete Keleher). 
# 1.2   08/94  'retrieveOutput' and 'autoSwitch' flags added.
#              'openInMacperl' added.
#              MacPerl output window now closed before new scripts are sent.
#              Filters now abort if there are compilation errors, and
#              MacPerl diagnostic output retrieved and displayed in Alpha.
# 1.3   09/94  When any script generates a compilation error, the file 
#                containing the script is brought up with the offending 
#                line highlighted; all error output is also written to
#                a "Perl Error Messages" window.
#              'repeatLastFilter' runs again the last text-filter script used.
#              'perlLastFilter' modeVar holds pathname of last filter.
#                Menu flags now mirrored as modeVars, so they can be saved and
#                restored between sessions.
#              Minor bug fixes.
# 1.4   09/94  The "#!" line of every script is read for command-line args,
#                which are passed explicitly to MacPerl with the script.
#              "PromptForArgs" menu flag added.
#              "perlCmdlineArgs" modeVar holds default command-line args.
#              Scripts are sent using custom "perlDoScript2" proc, which
#                allows passing of explicit command-line args.
# 1.5   09/94  MacPerl menu rearranged somewhat.
#                Explicit "Get Output Window" command added to menu.
#                Reading "#!" line for args is incompatible w/ standard,
#                so it's been dropped.
#                Only scan the first 40 output lines for error messages (faster)
#                "wrapFilterScript" no longer opens STDIN
#                Text filters may now use command-line args
#                STDIN for text filters passed as explicit cmd-line arg 
# 1.6  10/94   "UseDebugger" flag added (forces scripts to run under debugger).
#                Key bindings added for some menu commands.
#                "perlDoScript{,2,3}" procs consolidated into a single proc.
#                "saveAndRun" option added.
#                Command-line args now parsed into units more correctly, in
#                particular, quoted file names aren't broken up.
#                "Close Output Window" added to "Tell MacPerl" menu.
#                Updated for Alpha 5.98 to load when menu is inserted.
#                The error messages window is now recycled.
#                "perlRecycleOutput" recycles output window.
#                Minor bug fixes.
# 1.7   01/95  Updated to take advantage of MacPerl 4.1.4 AppleEvent features:
#                 1) Text filters use 'batch' doScript (.: STDOUT file obsolete)
#                 2) Filter scripts sent as doScript params (.: SCRIPT file obsolete)
#                 3) "Save As Droplet" and "Save as Runtime" commands added.
#              Errors generated in 'require'd files are now displayed correctly
# 1.8   04/95  Menu reorganized somewhat.
#              Text Filters folder can now be anywhere.
#              "ApplyToBuffer" flag ignored if text has been selected.
#              Bug fixes.
# 1.81  04/95  One very minor Alpha compatibility update (winInfo->getWinInfo).
# 1.9   05/95  Cmd-dbl-clicking Perl keywords and special variables displays
#                the man page info.
# 2.0   06/95  Minor bug fixes (incl. keyword decapitalization)
#              Alpha 6.0b17 compatibility updates.
#              Text Filters folder is settable from the App Paths menu now.
# 2.1   06/95  Cmd-dbl-clicking a 'require'd filename opens the file.
# 2.2   06/95  Text filters act only on current line if "Apply to Buffer" is
#                 false and no text has been selected.
#              Bug fix in error-marking for scripts sent as AppleEvent params.
#              Cmd-dbl-clicking a function call jumps to function, if
#                defined in the same file.
# 2.3   07/95  Minor tweaks and code rearrangement.
# 2.4   07/95  Fixed bugs affecting running unsaved scripts and error handling
# 2.41  07/95  Minor tweaks
# 2.5   01/96  Colorization and cmd-dbl-click modified to support Perl 5 docs
# 2.51  01/96  Fixed problem w/ "Tell MacPerl:Save As..."
# 2.6   02/97  Added electricPerlLeft and electricPerlRight - [David Schooley]
# 2.7   02/97  Comments before "#!/bin/perl" no longer confuse 'gotoPerlError'
# 2.8   02/97  Added Quick-Save commands in new submenu [Dan Herron]
#              "Save As CGI" finally works.
# 2.9   03/97  Fixed bug in command-dbl-click help lookup for Perl5 mode
# 3.09  04/97  MacPerl interactions don't depend on MacPerl app name anymore
#                Fixed bug with perlFileAsFilter ($scriptStart uninitialized)
# 3.10  08/97  Modernised for new Alpha Tcl scheme (vince)
# 3.11  09/97  Fixed problem with modevars in new Alpha scheme (Johan)
# 3.12  10/97  Uses new menu-building code, so you can add with menu::insert (v)
#  
# 3.13 - ???   'various updates'
# 
# 3.4   01/98  Tom Pollard went over code and fixed things broken by 7.0, 
#                completions tutorial added, 7.1b compatiblity made.
#              New 'marking proc's, and code sectioning support (i.e. dividers),
#                plus reorganized code. -trf
# 3.5   03/99  - Rob Calhoun:
#              in perlMenu.tcl:
#              Fixed bug in 'menu::buildPerl' which prevented keyboard equivalent
#                for 'repeatLastFilter' from working. (It was bound to 
#                '(repeatLastFilter'.) Now we build the menu with repeatLastFilter
#                active and then immediately disable it.
#              in perlFilters&Misc.tcl:
#              Changed 'completeSelection' so that it works right when
#                'apply to buffer' is not set and 'replace selection' is
#                set. Now the selection is expanded to whole lines before
#                handing off to MacPerl.
#              Added -nonewline option to 'puts' in proc 'writeStdin' to fix
#                 bug that introduced an extra line to filtered text.
# 3.6   07/01  - cbu:
#              Various fixes for Alphatk compatability.
#              Everything is now in the Perl namespace.
#              Only one command double click proc defined.
#              New "perlHelpDocs" pref to help with command double click.
#              'Perl Home Page' menu item added.
#              perl4 and perl5.tcl now mainly set different keyword lists,
#                but also have their own help file searching routines.
#              Better keyword colorizing, user control over colours.
#              'Magic' character now colorized (optional preference).
#              A lot of menu manipulation (marking/disabling menu items) taken
#                over by Perl::postEval.
#              'Regular Expression/Default Colours' menu items added.
#              'Perl Text Filters' replaces 'Text Filters' submenu
#              'Perl Lib Scripts' submenu added.
#              'Perl Path Scripts' submenu added.
#              'Perl Insertions' submenu added.
#              'Perl Navigation' submenu added.
#              Workaround for menu::buildHierarchy bug related to new 'file' 
#                commands introduced in AlphaTcl 7.4d1-7.
#              Command double click can now open on-line (www) manual pages.
# 3.6.1 08/01  - cbu:
#              Minor bug fixes.
#              Replacement of 'synchroniseModeVar' with 'prefs::modified'.
#              Better downloading of Perl Docs.
#                  

# ===========================================================================
# 
# .
