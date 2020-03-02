# File : "macMenuShellMore.tcl"
#                        Created : 2003-11-16 13:22:33
#              Last modification : 2003-11-18 11:54:24
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2003-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It demonstrates how to add new commands to Mac Shell.
# 
# 
# ----------------------------------------------------------------------------
# 
# How to create new MacShell commands
# -----------------------------------
# In order to create a new command called mycmd, you have to define a proc 
# called macsh::mycmd. The value returned by this proc is the string which 
# will be inserted in Mac Shell when the command is executed:
#     proc macsh::mycmd {} {
#         return "myvalue"
#     }
# 
# If these commands are stored in a file, don't forget to put the following 
# instruction at the beginning of the file:
#     namespace eval macsh {}
# 
# You can provide help info about a command by defining an entry in the 
# macsh_help array. Its value must be a list of items corresponding to all 
# the subcommands of mycmd.
# For instance, if you define
#     set macsh_help(mycmd) [list "open <myoptions> <myarguments>" "close"]
# the following line will be printed in MacShell when typing "help mycmd"
#     mycmd open <myoptions> <myarguments>
#     mycmd close
#     
# See more examples in this file.
# ----------------------------------------------------------------------------


# Load macMenu.tcl
macMenuTcl

namespace eval macsh {}

# Dummy proc
proc macMenuShellMore {} {}

# # # More Mac Shell functions # # #
# ==================================

# ----------------------------------------------------------------------------
# This command overrides the id command defined in TclX and executes the  Unix
# id program.
# Eg: id -P
# ----------------------------------------------------------------------------
set macsh_help(id) [list {[user]} {-G [-n] [user]} {-P [user]} {-g [-nr] [user]} {-p [user]} {-u [-nr] [user]}]

proc macsh::id {args} {
    return [exec id [list $args]]
}


# ----------------------------------------------------------------------------
# This command overrides the chmod command defined in TclX and executes the 
# Unix chmod program.
# ----------------------------------------------------------------------------
set macsh_help(chmod) [list {[-fv] [-R [-H | -L | -P]] mode file ...}]

proc macsh::chmod {args} {
    return [exec chmod [list $args]]
}


# ----------------------------------------------------------------------------
# This command overrides the chroot command defined in TclX and executes the 
# Unix chroot program.
# ----------------------------------------------------------------------------
set macsh_help(chroot) [list {[-u -user] [-g -group] [-G -group,group,...] newroot [command]}]

proc macsh::chroot {args} {
    return [exec chroot [list $args]]
}


# ----------------------------------------------------------------------------
# This proc makes the "man" command directly available from Mac Shell. It 
# executes the Unix man command and filters the result to eliminate unwanted 
# chars.
# Eg: man who
# ----------------------------------------------------------------------------
set macsh_help(man) [list {[-adfhkotw] [-m machine] [-p string] [-M path] [-P pager] [-S list]\
  [section] name ...}]

proc macsh::man {args} {
    catch {eval exec man $args} res
    set filter [list "(.)(\x8\\1)+\t\\1\t1" _\x8 \
      "­\$\t-\t1" "+\x8o\t¥" ]
    return [flt::applyFilterLinesToText $filter $res]
}


