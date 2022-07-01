HISTFILESIZE=20000
HISTSIZE=20000

if [[ $(id -u) -eq 0 ]] ; 
then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\[\033[01;35m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

set -o vi

shopt -s histverify

export VISUAL=vim
export EDITOR="$VISUAL"

export PATH=$PATH:/home/rook/.local/bin:/usr/local/go/bin

cg() {
  grep -ir $1 * | cut -c1-120 | grep -i --color -E "^|$1"
}

# make Ctrl-d just exit the terminal, don't run the command first
bind '"\C-d": "\C-u\C-d"'

# maybe add something here to pull from git?
hs() {
    scp -q ~/.rook-profile.sh $1:.rook-profile.sh
    ssh $1 'grep -qxF "source ~/.rook-profile.sh" ~/.profile || echo "source ~/.rook-profile.sh" >> ~/.profile'
    ssh $1
}

# cleanup history
if [[ $(id -u) -ne 0 ]] ; 
then
    cp ~/.bash_history ~/.bash_history.$(date +'%Y%m')
    cat -n ~/.bash_history.$(date +'%Y%m') | sort -k2 -k1n | tac | uniq -f1 | sort -n | cut -f2- | sed '/^hg /d' | sed '/^history /d' > ~/.bash_history
fi

hg() {
    thehistory=$(history)
    
    thehistory=$(grep -v -P '^[\d\s]+ hg ' <<< "${thehistory}")
    for var in "$@"
    do
        thehistory=$(grep ${var} <<< "${thehistory}")
    done

    history -s $(echo "$thehistory" | tail -n1 | perl -pe 's/^ \d+ +//')
    printf "$thehistory"
    echo
}
