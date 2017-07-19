# Exports the variable HOSTSYSTEM to find if your are on a linux or mac box
HOSTSYSTEM=$(uname)
export $HOSTSYSTEM

# Exporting Local Libs
PYTHONPATH=$PYTHONPATH:$HOME/git/dotfiles/lib/python; export PYTHONPATH
PYTHONPATH=$PYTHONPATH:$HOME/Drive/prasc/lib/python; export PYTHONPATH

# User Paths
export PATH="$HOME/git/dotfiles/bin:$HOME/bin:$HOME/.local/bin:$PATH"
[ -d $HOME/anaconda3 ] && export PATH="/root/anaconda3/bin:$PATH"

# Ssh Cofig
ssh-agent > /dev/null 2>&1
ssh-add > /dev/null 2>&1

# Arbor Stuff
ARBOR_RC="$HOME/git/stuff/config/arbor_zsh.sh"
if [ -f $ARBOR_RC ]
    then
        source $HOME/git/stuff/config/arbor_zsh.sh
fi
PROMPT='${ret_status}%{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} %D %T % %{$reset_color%}'

#Open GUI applications on the main display. Mostly for use with xming server
export DISPLAY=:0
