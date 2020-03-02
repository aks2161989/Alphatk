#!/bin/zsh

# Report the value of an environment variable 
# as defined in the startup sequence of /bin/zsh

if [ -r /etc/zshenv ]
then
  source /etc/zshenv
fi
if [ -r $ZDOTDIR/.zshenv ]
  then
  source $ZDOTDIR/.zshenv
fi
if [ -r .zprofile ]
then
  source .zprofile
fi
if [ -r $ZDOTDIR/.zprofile ]
  then
  source $ZDOTDIR/.zprofile
fi
if [ -r /etc/zshrc ]
then
  source /etc/zshrc
fi
if [ -r $ZDOTDIR/.zshrc ]
  then
  source $ZDOTDIR/.zshrc
fi
if [ -r /etc/zshlogin ]
then
  source /etc/zlogin
fi
if [ -r $ZDOTDIR/.zlogin ]
  then
  source $ZDOTDIR/.zlogin
fi

eval echo \$$1
