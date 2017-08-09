# Exporting Local Libs
PYTHONPATH=$PYTHONPATH:$HOME/git/dotfiles/lib/python; export PYTHONPATH
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

#Open GUI applications on the main display. Mostly for use with xming server
export DISPLAY=:0
