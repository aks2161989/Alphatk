# Automatically created by mode assistant
#
# Mode: Ruby


# Mode declaration.
#  first two items are: name version
#  then 'source' means source this file when we first use the mode
#  then we list the extensions, and any features active by default
alpha::mode Ruby 0.1 source *.rb RubyMenu {
    # Script to execute at Alpha startup
    addMenu RubyMenu Ruby
    ensureset rubySig {}
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Ruby programming files
} help {
    Ruby is the interpreted scripting language for quick and easy
    object-oriented programming.  It has many features to process text files
    and to do system management tasks (as in Perl).  It is simple,
    straight-forward, extensible, and portable.
    
    <http://www.ruby-lang.org/>
    <http://www.rubycentral.com/>
}

# For Tcl 8
namespace eval Ruby {}

# This proc is called every time we turn the menu on.
# Its main effect is to ensure this code, including the
# menu definition below, has been loaded.
proc RubyMenu {} {}
# Now we define the menu items.
Menu -n $RubyMenu -p Ruby::menuProc {
    switchToRuby
    /K<U<OsendWindowToRuby
    anotherCommand
}

# This procedure is called whenever we select a menu item
proc Ruby::menuProc {menu item} {
    global rubySig
    switch -- $item {
        switchToRuby {app::launchFore $rubySig}
        sendWindowToRuby {openAndSendFile $rubySig}
        anotherCommand { alertnote {another command} }
    }
}

# Mode preferences settings, which can be edited by the user (with F12)

newPref var lineWrap 0 Ruby
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Ruby

# Register comment prefix
set Ruby::commentCharacters(General) #
# Register multiline comments
set Ruby::commentCharacters(Paragraph) {{# } {# } {# }}
# List of keywords
set RubyKeyWords {
    alias and begin break case catch class def do elsif else fail 
    ensure for end if in module next not or raise redo rescue retry 
    return then throw super unless undef until when while yield
}

# Colour the keywords, comments etc.
regModeKeywords -e # Ruby $RubyKeyWords
# Discard the list
unset RubyKeyWords

# To write indentation code for your new mode (so your mode
# automatically takes advantage of the automatic indentation
# possibilities of 'tab', 'return' and 'paste'), you can take
# advantage of the shared proc ::indentLine.  All you need to write
# is a Ruby::correctIndentation proc, and as a
# starting point you can copy the code of the generic
# ::correctIndentation, found in indentation.tcl.
