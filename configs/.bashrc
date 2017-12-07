PS1='\[\e[1;34m\]\u\[\e[00m\]@\[\e[1;32m\]\h\[\e[00m\]:\[\e[1;32m\]\w\[\e[00m\](\[\e[1;${color}m\]$?\[\e[00m\])\$ '
PROMPT_COMMAND='exit=$?; if [ "$exit" = 0 ]; then color=32; else color=31; fi;'
