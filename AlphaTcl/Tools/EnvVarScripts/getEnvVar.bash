#!/bin/bash

# Report the value of an environment variable 
# as defined in the startup sequence of /bin/bash

source /etc/profile
if [ -r ~/.bash_profile ]
then
  source ~/.bash_profile
fi
if [ -r ~/.bash_login ]
then
  source ~/.bash_login
fi
if [ -r ~/.profile ]
then
  source ~/.profile
fi
if [ -r ~/.bashrc ]
then
  source ~/.bashrc
fi

eval echo \$$1
