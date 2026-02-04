# display
export PS1='%B%n%F{red}@%f%m%b:%F{green}%(4~|.../|)%3~%f $ '
export PS1=$'\e[1m\u\e[31m@\e[39m\H\e[0m:\e[33m\W\e[0m > '  # Bash alternative
export LSCOLORS=fxgxcxdxbxegedabagacad

# words
WORDCHARS='*?_-.[]~=&;:!#$%^(){}<>'
backward-kill-path () {
    local WORDCHARS=${WORDCHARS}/
    zle backward-kill-word
    zle -f kill
}
zle -N backward-kill-path
bindkey '^[w' backward-kill-path

# errors
# Necessary for some distros that meddle with the default
if [ ${functions[command_not_found_handler]} ]; then
    unset -f command_not_found_handler
fi

# path
PATH+=:~/.local/bin/  # Add local user binaries
PATH+=:/opt/local/bin/  # Add MacPorts directory
export PATH

# aliases
alias ls='ls -G'  # Replace -G with --color on Linux systems
alias ll='ls -lG'
alias lA='ls -AG'
alias llA='ls -lAG'
alias less='less -M'  # Display extra info at prompt

# terminal
stty -ixon  # Disable START/STOP output control; prevents terminal driver from intercepting ^Q, ^S 

# zsh history
# Not necessary for MacOS since configuration pulled from /etc/zshrc
export HISTFILE=~/.zsh_history
export SAVEHIST=1000
export HISTSIZE=2000

# tar
alias tar='tar --no-xattrs'  # Prevents inclusion of xattr headers which throws warnings on other systems
export COPYFILE_DISABLE=1  # Prevents creation of ._ members in archive which store MacOS specific information

# slurm
export SACCT_FORMAT=jobid,user,account,partition,state,exitcode,start,end,elapsed
export SLURM_TIME_FORMAT=relative
