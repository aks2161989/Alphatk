## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Mail Menu - an extension package for Alpha
 #
 # FILE: "mailSystem.tcl"
 # 
 #                                          created: 04/24/1996 {12:08:43 PM}
 #                                      last update: 03/06/2006 {08:07:43 PM}
 # Description:
 # 
 # Provides a "mail handler" service for the "Mail Menu" that allows e-mails
 # to be sent using the default OS "Email" client.  This is accomplished via
 # the [emailDefaultComposer] proc, which uses [url::execute].
 # 
 # See the "Changes - Mail Menu" file for license information.
 # 
 # ==========================================================================
 ##

alpha::library "mailSystem" 2.0 {
    namespace eval Mail {
	variable handlers
	set "handlers(OS Mailer)" "Mail::system"
    }
} description {
    Enables the sending of messages with ÇALPHAÈ's package: mailMenu using
    the default OS e-mail client
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} help {
    This package enables the sending of messages with the package: mailMenu
    using your OS-defined mailer client.
    
    To change the current mail handler to "OS Mailer", simply select this
    item in the "Mail Help > Mail Handler" menu.  Once you have done so,
    selecing the "Mail Menu > Send" command will compile the contents of the
    current Mail window to your OS client, opening a new window.  You must
    use this client to actually send the message.
    
    (More to be added.)
}

proc mailSystem.tcl {} {}

namespace eval Mail {
    
    # Before we do anything else, make sure that our "mode" is initialized.
    Mail::initializeMode
}

namespace eval Mail::system {}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::system::handlerChanged" --
 # 
 # Required procedure for all Mail Handler protocols.
 # 
 # Called with "onOrOff" == 1 when Mail mode is initialized if this is the
 # current handler, or when the user changes the handler to this one.  When
 # the user switches _from_ this handler to another, this is also called but
 # with "onOrOff" == 0.
 # 
 # Registers any menu insertions, hooks, and defines the visibility of any
 # additional Mail mode preferences.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::system::handlerChanged {onOrOff} {
    
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::system::handlerHelp" --
 # 
 # Required procedure for all Mail Handler protocols. 
 # 
 # Called by "Mail Menu > Mail Menu Help" (via [Mail::handlerHelp]), open the
 # help window associated with this Mail Handler.  This is necessary because
 # the Mail Menu has no idea which [alpha::library] package registered the
 # entry in the "Mail::handlers" array.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::system::handlerHelp {} {
    
    package::helpWindow "mailSystem"
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× OS mail handling ×××× #
# 
# All of the procedures in this section are called by [Mail::sendCreatedMsg],
# so their names and arguments cannot be changed.
# 

proc Mail::system::checkSystem {} {
    return 1
}

proc Mail::system::PrepareToSend {} {
    
    variable msgInfo
    
    unset -nocomplain msgInfo
    return
}

proc Mail::system::SetField {field value} {
    
    variable msgInfo
    
    set msgInfo($field) $value
    return
}

proc Mail::system::QueueToSend {} {
    
    variable msgInfo
    
    set address $msgInfo(to)
    unset msgInfo(to)
    set url [eval [list url::mailto $address] [array get msgInfo]]
    emailDefaultComposer $url
    status::msg "Message sent to OS e-mail client."
    return
}

# ===========================================================================
# 
# .