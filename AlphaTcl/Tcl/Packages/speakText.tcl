## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "speakText.tcl"
 #                                          created: 04/17/2003 {10:56:19 AM}
 #                                      last update: 05/24/2006 {11:51:16 AM}
 # Description:
 # 
 # Provides an AlphaTcl interface to the Tcl package "TclSpeech" by Mats
 # Bengtsson, in the form of an "Edit > Speech" submenu as well as a
 # contextual menu module.  This is a 'global-only' extension package that
 # might be uninstalled by the user, and should not be declared as a default
 # 'mode' feature.  Each mode can, however, define a procedure to help
 # massage the text to be spoken using <mode>::massageSpeakingText -- see the
 # example below for [Tcl::massageSpeakingText].
 # 
 # If everything is properly installed, [speak::speakText] can be safely
 # called by any other procedure from within AlphaTcl, even if this package
 # has not been globally activated.  The advantage of this over calling
 # [::speech::speak], as in
 # 
 #     package require TclSpeech 2.0
 #     ::speech::speak text ?-key value ...?
 # 
 # is that any user-defined preferences will be used, and the handy floating
 # 'speech console' menu will be automatically created.  Note that it is
 # _not_ necessary to do the [package require ...]  -- this package takes
 # care of that, and lets the user know if the operation cannot be performed.
 # If you want to know if speech facilities are available, then you can query
 # the proc [speak::speechIsAvailable] before calling [speak::speakText].
 # You could also call [speak::doMessage] for short messages -- if speech is
 # not available, the message will appear in the status bar.
 # 
 # This package was inspired by discussion in the AlphaTcl wiki:
 # 
 #     <http://www.purl.org/net/Alpha/Wiki/Menus/ContextualMenuItemsAndIdeas>
 # 
 # Thanks to Bernard Desgraupes for porting the TclSpeech to MacClassic, and
 # for some helpful debugging information and invaluable beta-testing.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2003-2006 Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
# 
# ×××× Feature Declaration ×××× #
# 
# Important: Don't do this in the requirements script
# 
# ::package require TclSpeech 2.0
# 
# because if the MacOS "Speech Manager" extension if not active then trying
# to load this package will fail, and even after the user has turned it on
# (and rebooted) this package will still be tagged as 'requirements failed'
# on every startup.  The only way to correct this is for the user to rebuild
# AlphaTcl indices, and that seems like a big bother.  Instead, the package
# can be activated but if loading the TclSpeech package fails the user will
# be informed when attempting to call any [::speak::..]  procedure.
# 

alpha::feature speech 1.3.2 "global-only" {
    # Initialization script.
    speak::initializePackage
} {
    # Activation script.
    speak::activatePackage 1
} {
    # Deactivation script.
    speak::activatePackage 0
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} requirements {
    # As of this writing, TclSpeech requires the MacOS ...
    if {!$::alpha::macos} {
	error "The TclSpeech package is only supported on the Mac OS"
    }
} preinit {
    if {$::alpha::macos} {
	# Use Mac OS speech facilities to speak the current selection
	newPref flag "speech Menu" 0 contextualMenu
	menu::buildProc "speech " {speak::buildCMenu} \
	  {speak::postBuildMenu "speech "}
    }
} uninstall {
    this-file
} description {
    Provides the ability to speak text using the Mac OS X speech facilities
} help {
    This package provides the ability to speak text using the Mac OS speech
    facilities.  Click here <<speak::testPackage>> to find out if this
    package is available.  If it is, see the "# Basic Usage" section below,
    otherwise check the "# Requirements" section.

    
	  	Table Of Contents

    "# Basic Usage"
    "# Speech Settings"
    "# Speech Console"
    
    "# Requirements"
    "#  Mac OS"
    "#  Speech Manager Extension"
    "#  TclSpeech"
    "# Developers Note"

    <<floatNamedMarks>>

   
	  	Basic Usage
    
    This package creates an "Edit > Speech" submenu, which allows you to
    speak the current selected text, type in your own text to speak, or
    adjust settings.  While text is being spoken to you by your OS, a special
    speech console <<speak::speechConsole>> can be created as a floating menu
    allowing you to pause, resume, or stop the speech.
    
    The "Edit > Speech > Start Speaking" command will begin speaking the
    current selected text in the active window.  If there is no selection,
    you will be prompted to enter some text, as if you had selected the
    command "Edit > Speech > Speak Text".
    
    The "Pause" command will suspend speaking, and then the "Resume" command
    will be available.  The "Edit > Speech > Stop Speaking" command will
    clear the speaking queue.
    
    
	  	Speech Settings
    
    You can adjust how the text is spoken to you by the OS.
    
    Click here <<speak::describeVoices>> to see a listing of all voices
    currently available.
    
    Click here <<speak::speechPrefs>> to change the current voice used by
    this package.  (This will not necessarily be your default OS voice.)
    
    Click here <<speak::speechShortcuts>> to add keyboard shortcuts to the
    different menu commands.
    
    This package also creates a contextual menu module to speak the selected
    region surrounding the current 'click' position.  This "Speech" module is
    always available, even if this package has not been activated globally.
    
    Preferences: ContextualMenu
    
    
	  	Speech Console
    
    While text is being spoken a "Speech Console" utility window can appear
    allowing you to pause, resume, or stop the speaking.  Select the command
    "Edit > Speech > Speech Console" to display it.
    
    <<speak::speechConsole>>
    
    Select the "Set Console Parameters" to change the default location of
    this utility window.  
    
    In the <<speak::speechPrefs>> dialog you can turn on the preference named
    "Auto Open Speech Console" if you want this console available whenever
    speech is spoken, and turn on "Auto Close Speech Console" if you want
    to remove the console when speaking is done.
    
    
	====================================================================
    

	  	Requirements

	  	 	Mac OS

    As of this writing, only applications in the Mac OS (both X and Classic)
    support this feature.
    
	  	 	Speech Manager Extension
    
    As of this writing, another requirement is the Mac OS "Speech Manager"
    extension.  In MacClassic (Alpha8), you can make sure that this is active
    by clicking here <<speak::openControlPanel "Extensions Manager">> to see
    if its checkbox has been checked.  If not, turn it on and continue to
    read the rest of this section -- you will, however, need to close ÇALPHAÈ
    and reboot your OS in order to use this package.
    
    Speech should be available in all versions of Mac OS X.

	  	 	TclSpeech
    
    The TclSpeech package (by Mats Bengtsson) is been included in the BI
    distribution of Tcl/Tk (version 8.4) for Mac OS X .  Open a <<tclShell>>
    window and enter this command:

	% package require TclSpeech 2.0
   
    to find out if it is available.  If you don't have it, then you can
    download it from here if you're using OSX:
    
    <http://hem.fyristorg.com/matben/download/TclSpeech2.0.sit>
    
    If you're using Alpha8 in MacClassic, you can download Bernard's port of
    the .shlib Tcl extension "TclSpeech" from here:
   
    <http://webperso.easyconnect.fr/bdesgraupes/Downloads/Tclspeech_2.0.sit.hqx>

    and install it in your "System:Extensions:Tool Command Language" folder.
    
    After installing the Tool Command Language extension in the appropriate
    folder, click here <<speak::testPackage>> to find out if the package is
    now recognized.  It shouldn't be necessary to restart ÇALPHAÈ, or to reboot
    your OS. If it still doesn't work after trying all of this, send a post
    to one of the AlphaTcl mailing lists described in the "Readme" file, or
    contact the maintainer of this package listed above.


	  	Developers Note
    
    The proc: speak::speakText can be called even if this package has not
    been formally activated.  [speak::speakText] will return '1' if speaking
    has started, and '0' if the TclSpeech package was not available -- there
    is no need to perform any package checks before calling this proc.  (If
    desired, you can query the proc: speak::speechIsAvailable to find out if
    speech utilities are currently available.)
    
    The advantage of calling [speak::speakText] over [::speech::speak] is
    that our AlphaTcl interface procedures will respect the user's settings
    for voice/pitch/rate and create the handy floating speech console
    (without which it is not possible for the user to turn off or pause the
    current speaking operation!)
}

proc speakText.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval speak" --
 # 
 # Declare some local package variables.  We put everything in this package
 # in the 'speak' namespace rather than 'speech' to ensure that we never
 # inadvertently over-write any TclSpeech internal procs or variables.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval speak {

    variable initialized
    if {![info exists initialized]} {
	set initialized 0
    }
    variable activated
    if {![info exists activated]} {
	set activated -1
    }
    # As of this writing, tear-off menus in Mac OS X Alphatk are problematic.
    # (See bug 765.)
    variable scAvailable
    if {$alpha::macos && ($alpha::platform ne "tk")} {
	set scAvailable 1
    } else {
	set scAvailable 0
    }
    if {$scAvailable} {
	# Automatically open the "Speech Console" when text is being spoken.
	variable autoOpenSpeechConsole
	if {![info exists autoOpenSpeechConsole]} {
	    set autoOpenSpeechConsole 0
	}
	variable autoCloseSpeechConsole
	if {![info exists autoCloseSpeechConsole]} {
	    set autoCloseSpeechConsole 0
	}
    }
    # Menu variables.
    variable menuName  "speech"
    variable menuItems  [list "Start Speaking" "Pause" "Resume" \
      "Stop Speaking" "(-)" "Speak TextÉ" "Speech Console" "Speech Help"]
    if {!$scAvailable} {
        set menuItems [lremove $menuItems [list "Speech Console"]]
    }
    variable menuProc   "speak::menuProc -m"
    # Voice parameters.
    set voiceItems [list Name Pitch Rate]
    set defaults   [list ""   1.0   1.0]
    for {set i 0} {($i <= 2)} {incr i} {
	variable [set item "voice[lindex $voiceItems $i]"]
        if {![info exists $item]} {
	    set $item [lindex $defaults $i]
	}
    }
    # Speech Console floating menu variables.
    variable scMenuItems [list "Start Speaking" "Pause" "Resume" \
      "Stop Speaking" "(-)" \
      "Speech PrefsÉ" "Set Console ParametersÉ"]
    variable scOptions   [list voice pitch rate]
    variable scFloatParameters
    if {![info exists scFloatParameters]} {
	set scFloatParameters \
	  [list [expr {$::defWidth + 20}] $::defTop 200 200]
    }
    variable scFloatWindow "* Move Console *"
    variable scMenuName    "Speech Console"
    # Miscellaneous.
    variable currentStatus "silent"
    variable controlPanels [list "Extensions Manager" "Sound"]
    variable dvWindowName "* Voice Descriptions *"
    
    # OS distinctions.
    variable requirements
    switch -- $::alpha::macos {
        "0" {
	    # Windows (or at least non-Macintosh).
	    set requirements [list "MacOS"]
	}
        "1" {
	    # MacClassic.
	    set requirements [list "SpeechManager" "TclSpeech 2.0"]
	    set scMenuItems  [linsert $scMenuItems 5 "MacOS Sound CPÉ"]
	}
	"2" {
	    # OSX.
	    set requirements [list "TclSpeech 2.0"]
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::initializePackage" --
 # 
 # Called when this package is first activated, set necessary variables for
 # the rest of the code.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::initializePackage {} {
    
    variable initialized
    variable scAvailable
    variable scMenuItems
    variable scMenuName
    
    if {$initialized} {
	return
    }
    menu::buildProc "speech" {speak::buildMenu} {speak::postBuildMenu "speech"}
    # We only need to build this menu once.
    Menu -m -n $scMenuName -p {speak::scMenuProc} $scMenuItems
    
    # The "Edit > Speech > Start Speaking" keyboard shortcut
    newPref menubinding "startSpeaking" "" speech
    # The "Edit > Speech > Pause" keyboard shortcut
    newPref menubinding "pause" "" speech
    # The "Edit > Speech > Resume" keyboard shortcut
    newPref menubinding "resume" "" speech
    # The "Edit > Speech > Stop Speaking" keyboard shortcut
    newPref menubinding "stopSpeaking" "" speech
    # The "Edit > Speech > Speak Text" keyboard shortcut
    newPref menubinding "speakText" "" speech
    if {$scAvailable} {
	# The "Edit > Speech > Speech Console" keyboard shortcut
	newPref menubinding "speechConsole" "" speech
    }
    
    # Call this now.  Even if speech is not available, we allow the rest of
    # the code in this file to be sourced so that we don't throw an error
    # when Alpha is first started.  The user will be informed that speech is
    # not available only when performing some explicit action calling the
    # procs below.
    speak::speechIsAvailable 0

    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::activatePackage" --
 # 
 # Called when this package is (de)activated, insert or remove menus as
 # necessary, and (de)register any necessary hooks.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::activatePackage {which} {
    
    variable activated
    
    if {($which eq $activated)} {
	return
    }
    if {$which} {
	menu::insert   Edit items end "(-) "
	menu::insert   Edit submenu {after "(-) "} "speech"
    } else {
	menu::uninsert Edit submenu {after "(-)"} "speech"
    }
    set activated $which
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::checkRequirements" --
 #
 # Check all of the requirements for this AlphaTcl package to work.  This
 # will perform the tests even if the value was previously set.
 # 
 # Current requirements:
 # 
 # MacOS --
 # 
 #   As of this writing, we require the MacOS.
 # 
 # SpeechManager --
 # 
 #   Required for TclSpeech in MacOS. From Bernard: This tests if the Speech
 #   Synthesis Manager (formerly called Speech Manager) is present.
 # 
 #     gestaltSpeechAttr 'ttsc' /* Text-To-Speech Manager attrib. */
 # 
 #   The '"has " 1' arg means we test bit 0 (2^0=1).
 # 
 # TclSpeech --
 # 
 #   This could fail for various reasons, including a missing 'SpeechManager'
 #   extension in MacOS, or the package cannot be found.  In the list of
 #   'requirements', this item is is a list where the second item in the
 #   version number required.  (If TclSpeech were ever updated to work with
 #   Windows, we would have two different version numbers we could check.)
 #   
 #   See <http://tclspeech.sourceforge.net/speech.html> for more information.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::checkRequirements {} {
    
    global alpha::macos
    
    variable requirements
    variable available
    
    foreach item $requirements {
        switch -- [lindex $item 0] {
            "MacOS" {
		set value [expr {($alpha::macos > 0) ? 1 : 0}]
	    }
            "SpeechManager" {
		set value [expr {1 - [catch {tclAE::build::resultData \
		  'MACS' fndr gstl ---- 'type'(ttsc) "has " 1}]}]
            }
	    "TclSpeech" {
		set v [lindex $item 1]
		set value [expr {1 - [catch {::package require TclSpeech $v}]}]
	    }
	}
	set available($item) $value
    }
    set available(all) 1
    foreach item $requirements {
	set available(all) [expr {$available(all) * $available($item)}]
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::speechIsAvailable" --
 # 
 # Returns 1 if the package is available, otherwise pay attention to the
 # 'alertIfNot' variable.  Can be called by any code outside of this package.
 # 
 # If 'alertIfNot' is '1', then the user is informed that why speech is not
 # available, and then any calling procedure will be killed without throwing
 # an error -- use
 # 
 #     speak::speechIsAvailable 1
 # 
 # to find out if all requirements are currently met.  (If 'alertIfNot' is
 # set to '2' then we give the alertnote but then return '0' to allow the
 # calling proc to continue.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::speechIsAvailable {{alertIfNot 0}} {

    variable available
    
    if {![info exists available(all)]} {
	speak::checkRequirements
    }
    if {$available(all)} {
	return 1
    } elseif {!$alertIfNot} {
	return 0
    }
    # Determine what required item is missing.
    set not [list]
    variable requirements
    foreach item $requirements {
	if {$available($item)} {
	    continue
	}
	set msg "Sorry, the 'Speak Text' feature is not available -- "
	switch -- $item {
	    "MacOS" {
		lappend not "the MacOS is required"
	    }
	    "SpeechManager" {
		lappend not "the MacOS 'Speech Manager' extension is not on"
	    }
	    "TclSpeech" {
		lappend not "'TclSpeech' could not be loaded"
	    }
	}
    }
    append msg [join $not ", and "] "."
    if {[regexp "Speech Help" [win::Current]]} {
	alertnote $msg
    } elseif {[askyesno [append msg " Would you like more information?"]]} {
	package::helpWindow "speech"
	help::goToSectionMark "Requirements"
    }
    if {($alertIfNot == 1)} {
	return -code return
    } else {
        return 0
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Speak Text Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::buildMenu" --
 # 
 # The "Edit > Speech" submenu allows the user to set various prefs for
 # voice/pitch/rate, and provides the interface to speak either the current
 # selection or any words typed into a dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::buildMenu {args} {
    
    global speechmodeVars
    
    variable menuItems
    variable menuProc
    
    set menuList [list]
    foreach menuItem $menuItems {
        switch -- $menuItem {
            "Start Speaking" {
                lappend menuList "$speechmodeVars(startSpeaking)$menuItem"
            }
            "Pause" {
		lappend menuList "$speechmodeVars(pause)$menuItem"
            }
            "Resume" {
		lappend menuList "$speechmodeVars(resume)$menuItem"
            }
            "Stop Speaking" {
		lappend menuList "$speechmodeVars(stopSpeaking)$menuItem"
            }
            "Speak TextÉ" {
		lappend menuList "$speechmodeVars(speakText)$menuItem"
	    }
            "Speech Console" {
		lappend menuList "$speechmodeVars(speechConsole)$menuItem"
            }
            default {
		lappend menuList $menuItem
            }
        }
    }

    return [list build $menuList $menuProc]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::buildCMenu" --
 # 
 # The CM module is identical to that found in "Edit > Speech", with the
 # possible exception of the first item "Start/Stop Speaking" items.  These
 # are included only if there is a selection surrounding the current 'click'
 # position.
 # 
 # It is not necessary for this package to be globally activated for the CM
 # to work.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::buildCMenu {args} {
    
    global alpha::CMArgs
    
    variable menuItems
    variable menuProc
    
    # Just in case this package has not been formally activated...
    speak::initializePackage
    
    set menuList $menuItems

    # Only keep "Start/Stop Speaking" items if a selection surrounds the
    # click position.
    if {[pos::compare [lindex $alpha::CMArgs 1] != [lindex $alpha::CMArgs 2]] \
      || ([speak::currentStatus] ne "silent")} {
	return [list build $menuList $menuProc]
    } else {
	return [list build [lrange $menuList 5 end] $menuProc]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::postBuildMenu" --
 # 
 # Dim or enable menu items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::postBuildMenu {menuName {which ""}} {
    
    variable currentStatus
    
    variable menuItems

    if {![speak::speechIsAvailable]} {
	set which "unavailable"
    } elseif {($which eq "")} {
	set which [speak::currentStatus]
    }
    switch -- $which {
	"unavailable"                                   {set dim [list 0 0 0 0]}
	"pause" - "paused"                              {set dim [list 0 0 1 1]}
	"speak" - "continue" - "busy" - "speaking"      {set dim [list 0 1 0 1]}
	default                                         {set dim [list 1 0 0 0]}
    }
    for {set i 0} {$i <= 3} {incr i} {
	enableMenuItem -m $menuName [lindex $menuItems $i] [lindex $dim $i]
    }
    return

}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::menuProc" --
 # 
 # The procedure for all "Edit > Speech" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::menuProc {menuName itemName} {
    
    variable menuItems
    
    if {[lsearch -glob $menuItems ${itemName}*] == -1} {
        error "Unknown menu item: $itemName"
    }
    switch -- $itemName {
        "Start Speaking" {
	    if {[isSelection]} {
		set txt [getSelect]
	    } else {
		return [speak::menuProc $menuName "Speak Text"]
	    }
	    speak::adjustSpeechConsole "begin"
	    speak::speakText [getSelect]
        }
	"Pause" {
	    ::speech::pause
	    speak::adjustSpeechConsole "pause"
	}
	"Resume" {
	    ::speech::continue
	    speak::adjustSpeechConsole "continue"
	}
	"Stop Speaking" {
	    ::speech::stop
	    speak::adjustSpeechConsole "stop"
	}
	"Speak Text" {
	    if {[isSelection]} {
		set txt [getSelect]
	    } else {
		set txt ""
	    }
	    set txt [getline "Enter some text to speak" $txt]
	    if {([string trim $txt] eq "")} {
		status::msg "Cancelled -- no text entered to speak."
		return 0
	    }
	    speak::adjustSpeechConsole "begin"
	    speak::speakText $txt
	}
	"Speech Console" {
	    speak::speechConsole
	}
	"Describe Voices" {
	    speak::describeVoices
	}
	"Speech Shortcuts" {
	    speak::speechShortcuts
	}
	"Speech Prefs" {
	    speak::speechPrefs
	}
	"Speech Help" {
	    package::helpWindow "speech"
	    speak::doMessage \
	      "This is the help window for the \"Speech\" package."
	}
	default {
	    speak::$itemName
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::doMessage" --
 #
 # A reasonably clever use of this package, though I suppose that it could
 # get kind of annoying.  This could be called by any other code in AlphaTcl.
 # 
 # One reason that we call this in various procs in this package is so that
 # the user can hear the difference made by changing various settings.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::doMessage {txt {noQueue 0}} {
    
    if {![speak::speechIsAvailable]} {
	status::msg $txt
	return
    } else {
	return [speak::speakText $txt $noQueue]
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::speakText" --
 #
 # Use the user's pre-defined settings to send 'txt' to [::speech::speak].
 # This proc can be safely called by any other code in AlphaTcl, even if this
 # package has not been globally activated.  If we're not able to speak the
 # text, then we return 0, otherwise 1.  While the OS is speaking, we are
 # able to perform any other actions -- [::speech::speak] (and thus this proc
 # as well) returns immediately after speaking has started.  A return value
 # here of '1' only indicates that speaking has started -- it does not mean
 # that speaking has ended.  (Query [speak::currentStatus] to find out.)
 # 
 # The '-command' argument will automatically adjust the speech console when
 # speaking begins (and then again when speaking is complete, so there is no
 # need to call [speak::adjustSpeechConsole] directly.  All other calls to
 # [::speak::] actions do require 'manual' adjustments for the console.
 # 
 # 'noQueue' means that we first stop whatever is being spoken so that the
 # new text will start immediately.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::speakText {txt {noQueue 0}} {
    
    # Just in case this package has not been formally activated...
    speak::initializePackage
    speak::speechIsAvailable 1
    
    variable autoOpenSpeechConsole
    variable voiceName
    variable voicePitch
    variable voiceRate
    variable wordsToSpeak
    variable wordsSpoken
    
    # Confirm that we have a text string.
    if {($txt eq "")} {
        status::msg "There is no text to speak."
	return 0
    }
    # We can adjust the text in a mode specific way, or just use the default
    # routine provided below.
    if {([set m [win::getMode]] ne "")} {
	set txt [namespace eval ::$m [list massageSpeakingText $txt]]
    } else {
        set txt [::massageSpeakingText $txt]
    }
    # We then adjust all urls/email addresses in the string, Do the 'urlPat3'
    # twice to capture "something.somethingelse.end" .  Finally, we adjust
    # whitespace so that we are dealing with single space strings.
    set emailPat {\<?([a-zA-Z0-9]+)@([a-zA-Z0-9]+)\.([a-zA-Z]+)>?}
    set urlPat1  {<?\"?(f|ht)tp://([^\s>]+)\"?>?}
    set urlPat2  {www\.}
    set urlPat3  {([a-zA-Z0-9]+)\.([a-zA-Z]+)}
    regsub -all -- $emailPat            $txt    {\1 at \2 dot \3}       txt
    regsub -all -- $urlPat1             $txt    {\2}                    txt
    regsub -all -- $urlPat2             $txt    {w w w dot }            txt
    regsub -all -- $urlPat3             $txt    {\1 dot \2}             txt
    regsub -all -- $urlPat3             $txt    {\1 dot \2}             txt
    regsub -all -- {\s+}                $txt    " "                     txt
    regsub -all -- {\s-+([a-zA-Z])}     $txt    { \1}                   txt
    # Confirm that we have valid settings for voiceName/Pitch/Rate.
    if {($voiceName eq "")} {
	set voiceName [lindex [::speech::speakers] 0]
    }
    foreach var [list Pitch Rate] {
	if {([speak::checkSpeechVarSetting $var [set voice$var]] ne "")} {
	    set voice$var 1.0
	}
    }
    # Pass the text string along to [::speech::speak].
    if {$noQueue} {
	::speech::stop
    }
    if {[info exists autoOpenSpeechConsole] && $autoOpenSpeechConsole} {
        speak::speechConsole 1
    }
    set speechToken [::speech::speak $txt -voice $voiceName \
      -pitch $voicePitch -rate $voiceRate \
      -command {::speak::speechConsole} -wordcommand {::speak::displayWord}]
    set wordsToSpeak($speechToken) $txt
    set wordsSpoken($speechToken)  " "
    return 1
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::displayWord" --
 #
 # Called by [::speech::speak] after every word has been spoken.  Since the
 # actual speaking is being performed by the OS, it doesn't really matter how
 # complicated this procedure is, because it won't affect the speaking rate
 # in any way.  It looks like the 'wordStart' and 'wordLength' indices aren't
 # entirely accurately wrt punctuation, but that's a rather minor aesthetic
 # point and trying to figure out exactly what gets truncated is rather
 # difficult -- we err here on the side on not including extra stuff.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::displayWord {speechToken wordStart wordLength} {
    
    variable wordsToSpeak
    variable wordsSpoken
    
    if {![info exists wordsToSpeak($speechToken)]} {
        set wordsToSpeak($speechToken) " "
	set wordsSpoken($speechToken)  " "
    } elseif {[string length $wordsSpoken($speechToken)] > 70} {
        set wordsSpoken($speechToken)  ""
    }
    # Determine the new word to be added to the message
    set idx1 $wordStart
    set idx2 [expr {$wordStart + $wordLength - 1}]
    if {($wordsSpoken($speechToken) eq " ")} {
	# Sometimes the wrong starting index is given by [::speech::speak].
	set idx1 0
    }
    set word [string range $wordsToSpeak($speechToken) $idx1 $idx2]
    append wordsSpoken($speechToken) " [string trim $word]"
    # Determine the percentage that we've completed.
    set pct [expr {(100 * $idx2) / [string length $wordsToSpeak($speechToken)]}]
    if {($pct < 10)} {
        set dots 1
    } else {
        set dots [expr {[string index $pct 0] + 1}]
    }
    set dots "\[[format {%-11s} [string repeat ¥ $dots]]\]"
    status::msg "$dots [string trim $wordsSpoken($speechToken)]"
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Speech Console ×××× #
# 
# The speech console (a simple floating menu) is automatically turned on
# whenever [speak::speakText] is called.  It can also be turned on by the
# user, but all of the status-specific menu items (i.e. pause, resume, stop)
# should be initially dimmed.
# 

##
 # --------------------------------------------------------------------------
 #
 # "speak::speechConsole" --
 # 
 # Called by various procs in this file, but also when [::speech::speak] is
 # first invoked and when speaking has finished.  (This is defined as the
 # callback proc in [speak::speakText].)  [::speech::speak] passes two
 # arguments, 'speechToken' and 'which' -- as of this writing, we only pay
 # attention to the last argument.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::speechConsole {args} {
    
    variable scFloatID
    variable scFloatParameters
    variable scMenuItems
    variable scMenuName
    
    speak::initializePackage
    
    set errMsg "argument should be one of '0/1/begin/finished'"
    switch -- [llength $args] {
        "0"     {set action 1}
        "1"     {set action [lindex $args 0]}
	"2"     {set action [lindex $args 1]}
	default {error $errMsg}
    }

    switch -- $action {
        "0" {
            # Turning off the speech console.
	    catch {unfloat $scFloatID}
        }
        "1" {
	    # Dim items as appropriate.
	    speak::adjustSpeechConsole
	    # Float the speech console menu.
	    foreach {l t w h} $scFloatParameters {}
	    if {![catch {
		eval [list float -m $scMenuName] -l $l -t $t -w $w
	    } result]} {
		set scFloatID $result
	    }
        }
	"begin" {
	    # When called by [speech::speak], we don't automatically float;
	    # the console should have already been created if necessary.
	    speak::adjustSpeechConsole
	}
	"finished" {
	    # Only called when [::speech::speak] is done.
	    speak::adjustSpeechConsole "silent"
	    status::msg "\[¥¥¥¥¥¥¥¥¥¥¥\] (complete)"
	    after 3000 {status::msg ""}
	}
	default {
	    error $errMsg
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::adjustSpeechConsole" --
 # 
 # Dim floating menu buttons in correspondance to the current speaking
 # status.  Called whenever that status changes.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::adjustSpeechConsole {{which ""}} {
    
    variable autoCloseSpeechConsole
    variable menuName
    variable scFloatID
    variable scMenuName
    
    if {($which eq "")} {
        set which [speak::currentStatus]
    }
    speak::postBuildMenu $menuName $which
    speak::postBuildMenu $scMenuName $which
    if {($which eq "silent") && $autoCloseSpeechConsole} {
	catch {unfloat $scFloatID}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::scMenuProc" --
 # 
 # Execute the action selected by the user.  For efficiency, we don't query
 # [speak::speechIsAvailable] here -- all of the speech consoles should be
 # dimmed (unavailable to the user) if loading TclSpeech failed.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::scMenuProc {menuName itemName} {

    variable scMenuItems
    
    if {([lsearch -glob $scMenuItems ${itemName}*] == -1)} {
	error "Unknown menu item: $itemName"
    }
    switch -- $itemName {
	"Start Speaking" - "Pause" - "Resume" - "Stop Speaking" {
	    speak::menuProc "speech" $itemName
	}
	"MacOS Sound CP" {
	    speak::openControlPanel "Sound"
	}
	"Speech Prefs" {
	    speak::speechPrefs
	}
	"Set Console Parameters" {
            speak::setConsoleGeometry
        }
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::setConsoleGeometry" --
 # "speak::saveConsoleGeometry" --
 # 
 # Using the current 'float' parameters, destroy the speech console and
 # replace it by a window with the same geometry.  This window includes a
 # hyperlink for <<Save Settings>> which will capture the new geometry,
 # destroy this temporary window and then re-float the speech console.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::setConsoleGeometry {} {
    
    variable scFloatParameters
    variable scFloatWindow

    speak::speechConsole 0
    if {[win::Exists $scFloatWindow]} {
	bringToFront $scFloatWindow
	return
    }
    # Text to include in the window.
    set msg {
Move and size this
window to where
you would the
speech console
floating menu to
appear.

Click here:
<Save Settings>
when you want to
save the new
geometry parameters.
}
    # Create a new window, and hyperlink text.
    set g $scFloatParameters
    eval new -g $scFloatParameters [list -n $scFloatWindow -text $msg -m "Text"]
    win::searchAndHyperise {<Save Settings>} \
      {speak::saveConsoleGeometry} 1 3 +1 -1
    setWinInfo dirty 0
    setWinInfo read-only 1
    goto [minPos]
    refresh
    return
}

proc speak::saveConsoleGeometry {} {

    variable scFloatWindow
    variable scFloatParameters
    
    if {![win::Exists $scFloatWindow]} {
	status::msg "Cancelled -- could not find the '$scFloatWindow' window."
	return -code return
    }
    bringToFront $scFloatWindow
    set scFloatParameters [getGeometry]
    prefs::modified scFloatParameters
    killWindow
    speak::speechConsole 1
    speak::doMessage "The new speech console parameters have been saved."
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Speak Text Utilities ×××× #
# 
# Various items that mainly support the setting of preferences.  Some of them
# are called by hyperlinks in the help window.
# 

##
 # --------------------------------------------------------------------------
 #
 # "speak::testPackage" --
 # 
 # A handy way for the user to determine if the requirements for this package
 # have been met.  If so, the user can immediately enter some words to speak.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::testPackage {} {
    
    speak::checkRequirements
    speak::speechIsAvailable 1
    speak::menuProc "" "Speak Text"
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::currentStatus" --
 # 
 # Returns 'silent' if the TclSpeech package is not available, otherwise
 # returns the value of [::speech::status].
 #
 # From "speech.html" :
 # 
 # "speech::status" --
 # 
 # Returns any of silent, paused, busy, or speaking describing the status of
 # any speak process.  The return value 'paused' is only returned after the
 # command [speech::pause] has been invoked.  Any ongoing speech process
 # returns either busy or speaking.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::currentStatus {} {
    
    if {![speak::speechIsAvailable]} {
	variable currentStatus "silent"
    } else {
	variable currentStatus [::speech::status]
    }
    return $currentStatus
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::speechPrefs" --
 # 
 # Create and present a dialog with all speech setting options.  This will
 # include a "Test Settings" button so the user can experiment before
 # changing them.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::speechPrefs {} {
    
    variable autoOpenSpeechConsole
    variable autoCloseSpeechConsole
    variable scAvailable
    variable voiceName
    variable voicePitch
    variable voiceRate
    
    set voices [lsort -dictionary [::speech::speakers]]
    if {($voiceName eq "")} {
	set voiceName [lindex $voices 0]
    }
    for {set i 0} {($i < 10)} {incr i} {
        lappend pitches "0.$i"
    }
    lappend pitches "1.0"
    if {![lcontain $pitches $voicePitch]} {
        set voicePitch "1.0"
    }
    for {set i 0} {($i < 10)} {incr i} {
	lappend rates "0.$i"
    }
    lappend rates "1.0"
    if {![lcontain $rates $voiceRate]} {
	set voiceRate "1.0"
    }
    # Create the dialog script.
    set dialogScript [list dialog::make -title "Speech Options" -width 300 \
      -addbuttons [list \
      "Test SettingsÉ" \
      "Click here to test the current settings" \
      {::speech::stop ; catch [list \
      ::speech::speak [speak::voiceComment [dialog::valGet $dial ",Voice:"]] \
      -voice [dialog::valGet $dial ",Voice:"] \
      -pitch [dialog::valGet $dial ",Pitch:"] \
      -rate  [dialog::valGet $dial ",Rate:"] \
      ]} \
      ] \
      ]
    set dialogPane [list "" \
      [list "text" "Select new speaking voice options:\r"] \
      [list [list menu $voices] "Voice:" $voiceName \
      "The voice to use for all spoken text"] \
      [list [list menu $pitches] "Pitch:" $voicePitch \
      "The pitch to use for all spoken text"] \
      [list [list menu $rates]  "Rate:" $voiceRate \
      "The rate to use for all spoken text"] \
      ]
    if {$scAvailable} {
        lappend dialogPane \
	  [list [list "smallall" "flag"] "Auto Open Speech Console" \
	  $autoOpenSpeechConsole \
	  "Automatically open the \"Speech Console\" utility window\
	  when speaking begins"] \
	  [list [list "smallall" "flag"] "Auto Close Speech Console" \
	  $autoCloseSpeechConsole \
	  "Automatically close the \"Speech Console\" utility window\
	  when speaking ends"]
    }
    lappend dialogScript $dialogPane
    if {[catch {eval $dialogScript} results]} {
	::speech::stop
        speak::doMessage "Cancelled."
	return
    }
    ::speech::stop
    set changes 0
    if {([set newVoice [lindex $results 0]] ne $voiceName)} {
        set voiceName $newVoice
	prefs::modified voiceName
	set changes 1
    }
    if {([set newPitch [lindex $results 1]] ne $voicePitch)} {
	set voicePitch $newPitch
	prefs::modified voicePitch
	set changes 1
    }
    if {([set newRate [lindex $results 2]] ne $voiceRate)} {
	set voiceRate $newRate
	prefs::modified voiceRate
	set changes 1
    }
    if {$scAvailable \
      && ([set newAutoOpen [lindex $results 3]] ne $autoOpenSpeechConsole)} {
        set autoOpenSpeechConsole $newAutoOpen
	prefs::modified autoOpenSpeechConsole
	set changes 1
    }
    if {$scAvailable \
      && ([set newAutoClose [lindex $results 4]] ne $autoCloseSpeechConsole)} {
	set autoCloseSpeechConsole $newAutoClose
	prefs::modified autoCloseSpeechConsole
	set changes 1
    }
    if {$changes} {
	speak::doMessage "The new speech settings have been saved."
    } else {
	speak::doMessage "No changes have been made to the speech settings."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::speechShortcuts" --
 # 
 # Adjust the "Edit > Speech" menu keyboard shortcuts.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::speechShortcuts {} {
    
    prefs::dialogs::packagePrefs "speech" "Speech Menu Shortcuts"
    menu::buildSome "speech"
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::openControlPanel" --
 # 
 # Open the specified MacOS control panel in the Finder.  There are a few
 # control panel name mappings supplied here -- but the creator code can also
 # be used.  (This sort of proc could also be supplied in AlphaTcl system
 # code, or perhaps in the Mac Menu.)
 #
 # --------------------------------------------------------------------------
 ##

proc speak::openControlPanel {{controlPanel ""}} {
    
    global alpha::macos
    
    if {($alpha::macos != 1)} {
	alertnote "This item is only useful in MacClassic."
	return
    }
    variable controlPanels
    variable lastControlPanel
    
    if {![info exists lastControlPanel]} {
        set lastControlPanel [lindex $controlPanels 0]
    }
    set L [list $lastControlPanel]
    
    if {($controlPanel eq "")} {
	set p "Open which control panel?"
	set controlPanels [lsort -dictionary $controlPanels]
	set controlPanel  [listpick -p $p -L $lastControlPanel $controlPanels]
    }
    switch -- [set lastControlPanel $controlPanel] {
	"EM" - "Extensions Manager"     {set controlPanel "8INI"}
	"Sound"                         {set controlPanel "soun"}
    }
    if {[lsearch $controlPanels $lastControlPanel] == -1} {
	lappend controlPanels $lastControlPanel
    }
    app::launchFore '${controlPanel}'
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::describeVoices" --
 # 
 # Create a new window describing all current voices recognized by the OS.
 # Hyperlinks will set the new voice, and give a demo.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::describeVoices {} {

    speak::speechIsAvailable 1

    variable dvWindowName
    
    if {[win::Exists $dvWindowName]} {
	bringToFront $dvWindowName
	return
    }
    watchCursor
    set t {
Voice Descriptions

This window describes all of the voices currently available in your OS.

Click on any ÇhyperlinkÈ to hear that current voice describe itself.
Click here: Çspeak::speechPrefsÈ to change the current voice settings.
}
    append t \r [set linePat "[string repeat _ 72]\r\r"]
    append t "TABLE OF CONTENTS" \r $linePat
    foreach voiceList [::speech::voices] {
	lappend voices [set voiceName [lindex $voiceList 1]]
	array set voiceInfo$voiceName [lrange $voiceList 2 end]
    }
    set marks ""
    foreach voiceName [lsort -dictionary $voices] {
	append marks "\"# ${voiceName}\"\r"
	append t [format {%-10s} Name:] $voiceName \r\r
	foreach item [list gender age comment] {
	    if {![info exists voiceInfo[set voiceName](-$item)]} {
		set voiceInfo "(no information available)"
	    } else {
		set voiceInfo [set voiceInfo[set voiceName](-$item)]
	    }
	    set txt [string trimleft [breakIntoLines $voiceInfo 77 10]]
	    append t [format {%-10s} ${item}:] ${txt}\r
	}
	append t \r
    }
    regsub {TABLE OF CONTENTS} $t $marks t
    new -n $dvWindowName -text $t -mode "Text"
    # Add window marks.
    set namePat {^Name:     ([a-zA-Z][a-zA-Z, ]+)}
    goto [set pos [minPos]]
    while {1} {
	set pp [search -n -s -f 1 -r 1 -- $namePat $pos]
	if {![llength $pp]} {break}
	set pos  [pos::nextLineStart [set pos1 [lindex $pp 0]]]
	set pos0 [pos::prevLineStart $pos1]
	regexp $namePat [eval getText $pp] allofit name
	setNamedMark $name $pos0 $pos1 $pos1
    }
    # Now add colors.
    help::colourTitle 5
    help::hyperiseExtras 1
    win::searchAndHyperise {^(gender|age|comment):} "" 1 5
    win::searchAndHyperise {^Name:}                 "" 1 1
    win::searchAndHyperise $namePat \
      {speak::describeVoice "\1"} 1 4 +10
    win::searchAndHyperise Çspeak::speechPrefsÈ \
      {speak::speechPrefs} 1 4 +1 -1
    refresh
    winReadOnly
    speak::doMessage "All voices appear in the Marks menu for easy navigation." 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::describeVoice" --
 # 
 # Allow a voice to speak its description.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::describeVoice {{voice ""}} {
    
    variable voicePitch
    variable voiceRate
    
    speak::speechIsAvailable 1
    
    if {($voice eq "")} {
	set p "Select a voice:"
        set voice  [listpick -p $p [lsort -dictionary [::speech::speakers]]]
    }
    ::speech::stop
    ::speech::speak [speak::voiceComment $voice] \
      -voice $voice -pitch $voicePitch -rate  $voiceRate    
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "speak::voiceComment" --
 # 
 # Return the "comment" string associated with the given voice.
 # 
 # --------------------------------------------------------------------------
 ##

proc speak::voiceComment {voice} {
    
    foreach voiceList [::speech::voices] {
	lappend voices [set voiceName [lindex $voiceList 1]]
	array set $voiceName [lrange $voiceList 2 end]
    }
    if {![lcontain $voices $voice]} {
        return "The \"$voice\" voice doesn't seem to exist."
    }
    set comment [lindex [array get $voice -comment] 1]
    if {($comment ne "")} {
        return $comment
    } else {
	return "This is the voice of \"$voice\""
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "speak::checkSpeechVarSetting" --
 # 
 # Ensure that the given var is between 0 and 1.0 .  If it is, then we
 # return an empty string, else we give a potential new prompt.
 #
 # --------------------------------------------------------------------------
 ##

proc speak::checkSpeechVarSetting {which value} {
    
    if {[regexp -- {^[01](\.0)?$} $value]} {
	return ""
    } elseif {![regexp -- {^0?.[0-9]+$} $value]} {
	return "\"$which\" must be a decimal between 0 and 1.0"
    } elseif {($value < 0.0)} {
	return "\"$which\" cannot be less than 0"
    } elseif {($value > 1.0)} {
	return "\"$which\" cannot be greater than 1.0"
    } else {
	return ""
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "::massageSpeakingText" --
 # 
 # Any mode can massage text to remove/substitute characters, etc.  By
 # default, we'll attempt to remove comment characters.
 # 
 # "Tcl::massageSpeakingText" --
 # 
 # Here's an example for Tcl mode.
 #
 # --------------------------------------------------------------------------
 ##

proc ::massageSpeakingText {txt} {

    set cmt [set eol ""]
    if {[string length $::mode]} {
	set cmt [string trim [comment::Characters General]]
	if {($cmt eq "")} {
	    set cmt [comment::Characters Paragraph]
	    set eol [string trim [lindex $cmt 1]]
	    set cmt [string trim [lindex $cmt 0]]
	}
    }
    set lines [list]
    foreach line [split $txt \r\n] {
	regsub --       "^\\s*$cmt"     $line   ""      line
	regsub --       "$eol\\s*$"     $line   ""      line
	regsub -all --  {(<<|>>)}       $line   ""      line
	regsub -all --  {-+>}           $line   " "     line
	lappend lines [string trim $line]
    }
    return [join $lines " "]
}

namespace eval Tcl {}

proc Tcl::massageSpeakingText {txt} {
    
    set lines [list]
    foreach line [split $txt \r\n] {
	regsub --       {^\s*\#}        $line   ""      line
	regsub -all --  {::}            $line   "-"     line
	regsub -all --  {(\[|\])}       $line   " "     line
	regsub -all --  {\$}            $line   ""      line
	lappend lines [string trim $line]
    }
    return [join $lines " "]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 04/17/03 cbu 1.0    First version.  MacOS, TclSpeech v 2.0 is required.
# 04/18/03 cbu 1.1    Incorporated Bernard's suggestions re the speech console
#                       and fixed some regexp problems with setting variables.
#                     New [speak::doMessage] proc, used in some dialogs.
#                     Figured out that OS 'SpeechManager' extension is
#                       required for TclSpeech to properly load.
#                     New 'Voice Descriptions' window ([speak::describeVoices]).
# 04/21/03 cbu 1.1.1  Better checking of [speak::speechIsAvailable], better
#                       setting of 'available' variable during sourcing.
#                     Added Bernard's check for OS 'SpeechManager' extension.
#                     Improved 'help' window, esp requirements, hyperlinks.
# 04/21/03 cbu 1.1.2  Modes can now massage the text as desired.  By default,
#                       we'll remove comment characters, and we always attempt
#                       to refine emails and urls.
#                     Speak text string is adjusted for whitespace -- this
#                       helps makes the status bar display more consistent.
#                     'requirements' adjusted for OS in namespace evaluation.
#                     Also, there is no such thing as a 'Sound' Control Panel
#                       unless we're in MacClassic.
# 04/22/03 cbu 1.1.3  'requirements' refinements (again).
#                     It will be very easy to modify requirements later if
#                       TclSpeech is ever updated for Windows.
#                     Removed 'mode' dependency in [::massageSpeakingText].
# 05/19/06 cbu 1.3    Renamed package "speech".
#                     Renamed menu "Edit > Speech".
#                     "Pause" and "Resume" included in "Edit > Speech" menu.
#                     "Speech Console" is not automatically opened unless the
#                       user has set the "autoOpenSpeechConsole" preference.
# 05/22/06 cbu 1.3.1  Corrected deactivation script.
#                     Added [speak::describeVoice] hyperlink proc.
#                     Better contextual menu list of commands.
#                     Ensure starting text is included in status message.
# 05/24/06 cbu 1.3.2  New "Auto Close Speech Console" setting.
#                     Simplified "Edit > Speech" menu.
#                     Preferences set via hyperlinks in Help window.
# 

# ===========================================================================
# 
# .