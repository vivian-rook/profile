# potential improvements:
# shouldn't use /home/rook as that won't always be true. This should apply itself to anyone that I log in as.
# probably put all the root exclusive bits in one block rather than many

HISTFILESIZE=20000
HISTSIZE=20000

# cleanup old name, remove this line eventually
rm ~/.ssh_session.sh 2>/dev/null

# create sudo that has, some of, our profile follow us
if [[ $(id -u) -ne 0 ]] ; then
    cat << EOF > ~/.rook-sudo.sh
#!/bin/sh
exec bash --rcfile /home/rook/.rook-profile.sh "\$@"
EOF

    chmod 755 ~/.rook-sudo.sh
    alias s='sudo su -s /home/rook/.rook-sudo.sh -'
fi

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

    # $() seems to mess up vim highlighting here. using `` for now
    thehistory=`grep -v -P '^[\d\s]+ hg ' <<< "${thehistory}"`
    for var in "$@"
    do
        thehistory=`grep ${var} <<< "${thehistory}"`
    done

    history -s $(echo "$thehistory" | tail -n1 | perl -pe 's/^ *\d+ +//')
    printf "$thehistory"
    echo
}
