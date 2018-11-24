# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

#if [ -f ~/.bash_aliases ]; then
#    . ~/.bash_aliases
#fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    eval "`dircolors -b`"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

export PATH=$PATH:/sbin:/usr/local/go/bin:/usr/local/docker:/usr/lib/jvm/jdk1.8.0_172/bin:/opt/gradle/gradle-4.6/bin:~/bin:~/src/github.com/chirhonul/tools
export GOPATH=$HOME
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_172

export NMON=lmtk

export GPG_TTY=$(tty)

start_ssh_agent() {
  ssh-agent -s > ~/.ssh-agent.conf 2>/dev/null
  source ~/.ssh-agent.conf > /dev/null
}

# usage: add_ssh <keyfile> <passfile>
add_ssh() {
  if ssh-add -L | grep -q ${1}; then
    return 0
  fi
  [ ! -e ${2} ] && {
    echo "failing; no such pass file ${1}_pass.txt"
    return 1
  }
  pass=$(cat $2)

  echo "Adding SSH key for ${1}.."
  expect << EOF
    spawn ssh-add $1
    expect "Enter passphrase"
    send "$pass\r"
    expect eof
EOF
}

add_ssh_keys() {
  add_ssh /mnt/keys/s2_id_rsa ~/docs/s2_id_rsa_pass.txt
  add_ssh /mnt/keys/s3_id_rsa ~/docs/s3_id_rsa_pass.txt
  add_ssh /mnt/keys/chirhonul_github0_id_rsa ~/docs/chirhonul_github0_id_rsa_pass.txt
}

load_ssh_keys() {
  [ -f ~/.ssh-agent.conf ] || {
    # Agent was not running, so start it.
    start_ssh_agent
    add_ssh_keys
    # ssh-add -t ${key_ttl} > /dev/null 2>&1
    return 0
  }
  source ~/.ssh-agent.conf > /dev/null
  ssh-add -l >/dev/null 2>&1
  stat=$?
  [ ${stat} -eq 0 ] && {
    # The socket exists and it has one or more keys.
    return 0
  }
  [ ${stat} -eq 1 ] && {
    # The socket exists but it has no keys.
    add_ssh_keys
    # ssh-add -t ${key_ttl} >/dev/null 2>&1
    return 0
  }
  # The socket was not there or was broken.
  rm -f ${SSH_AUTH_SOCK} # from ~/.ssh-agent.conf sourced above
  start_ssh_agent
  ssh-add -t ${key_ttl} >/dev/null 2>&1
}


load_ssh_keys
