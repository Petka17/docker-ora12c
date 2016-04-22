echo "Sourcing .bashrc"

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

export RESOLV_MULTI=off

# User specific aliases and functions
alias ll='ls -alhF'
alias ..='cd ..'

# Oracle Settings
export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_HOSTNAME=$HOSTNAME

export PATH=/usr/sbin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
