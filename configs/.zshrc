#Starts tmux
[[ $TERM != "screen-256color" ]] && exec tmux 

#Uncomment the line below for 1337 debugging
# setopt XTRACE VERBOSE

# Oh-my-zsh related
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
source $ZSH/oh-my-zsh.sh

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Exports the variable HOSTSYSTEM to find if your are on a linux or mac box
HOSTSYSTEM=$(uname)
export $HOSTSYSTEM

# Mac colors
autoload -U colors
colors

# Keeps my tmux configuration by working by making a fake command to execute
if [[ $HOSTSYSTEM -eq "Linux" ]]; then chmod +x $HOME/git/dotfiles/bin/reattach-to-user-namespace; fi

# Exporting Local Libs
PYTHONPATH=$PYTHONPATH:$HOME/lib/python; export PYTHONPATH

#Local code update aliases
alias sup='for repo in $( ls -d -1 ~/git/*); do cd $repo; echo -n "$repo: "; git pull; cd ..; done'

#Usage Aliases
alias cl="clear"
alias pls="sudo !!"
alias notes="vim ~/docs/notes"
alias tagpls='ctags -R .'
alias agenda="gcalcli agenda"
alias calendar="gcalcli calm"
alias seleniumpls="java -jar ~/git/dotfiles/bin/selenium.jar"
alias c="gcalcli"
alias hn="pyhn"
alias lolidk="echo '¯\_(ツ)_/¯' | ucopy"
alias duude="echo 'ಠ_ಠ' | ucopy"
alias lenny="echo '( ͡° ͜ʖ ͡°)' | ucopy"
alias flip="echo '(╯°□°）╯︵ ┻━┻' | ucopy"
alias sink="echo 'setw synchronize-panes on' | ucopy"
alias :q='exit'
alias :wq='exit'
alias lsl='ls -al | less'
alias todo='vim ~/Drive/prasc/docs/todo'
alias webpls='python -m SimpleHTTPServer 8000'
alias emacs='emacs -nw'

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git zsh-syntax-highlighting)

# Loads AJ
[[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh

# User Paths
export PATH="/usr/local/bin:/bin:/usr/sbin:/sbin:/usr/bin:$HOME/git/dotfiles/bin"

# Ssh Cofig
ssh-agent > /dev/null 2>&1
ssh-add > /dev/null 2>&1

# The time the shell waits, in hundredths of seconds, for another key to be 
# pressed when reading bound multi-character sequences.
export KEYTIMEOUT=1

# Repalces the Mac OS X utilities with GNU core utilities
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

#User functions
command_not_found_handler () {
    echo -e "Looks like you herp derped when you typed $(tput bold)$*"
    echo "$*" | ucopy
}

highlight () {
        perl -pe "s/$1/\e[1;31;43m$&\e[0m\a/g"
}

tm(){mv $1 $2 && cd $2;}

# backspace and ^h working even after
# returning from command mode
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# ctrl-w removed word backwards
bindkey '^w' backward-kill-word

# ctrl-r starts searching history backward
bindkey '^r' history-incremental-search-backward

eval "$(thefuck --alias)"

# You can use whatever you want as an alias, like for Mondays:
eval "$(thefuck --alias FUCK)"

# Arbor Stuff
source $HOME/git/stuff/config/arbor_zsh.sh
