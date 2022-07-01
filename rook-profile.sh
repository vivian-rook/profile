# potential improvements:
# shouldn't use /home/rook as that won't always be true. This should apply itself to anyone that I log in as.

HISTFILESIZE=20000
HISTSIZE=20000

# cleanup old name, remove this line eventually
rm ~/.ssh_session.sh 2>/dev/null

# create sudo that has, some of, our profile follow us
if [[ $(id -u) -eq 0 ]] ; then
    # give root a green command line color
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    # give rook a purple command line color
    PS1='\[\033[01;35m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

    # update the .rook-sudo.sh allowing for bringing env via sudo
    cat << EOF > ~/.rook-sudo.sh
#!/bin/sh
exec bash --rcfile /home/rook/.rook-profile.sh "\$@"
EOF

    chmod 755 ~/.rook-sudo.sh
    alias s='sudo su -s /home/rook/.rook-sudo.sh -'

    # only cleanup history if it is my history, not for root
    # LOLI, maybe when running as root have it use my history then we could cleanup?
    cp ~/.bash_history ~/.bash_history.$(date +'%Y%m')
    cat -n ~/.bash_history.$(date +'%Y%m') | sort -k2 -k1n | tac | uniq -f1 | sort -n | cut -f2- | sed '/^hg /d' | sed '/^history /d' > ~/.bash_history

    # setup vimrc
    cat << EOF > ~/.vimrc
set hlsearch # highlight all matching search terms
set listchars=tab:ᐅ\ 
set list

set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab

autocmd Filetype javascript setlocal ts=4 sts=4 sw=4 noexpandtab
EOF
fi

set -o vi

shopt -s histverify

export VISUAL=vim
export EDITOR="$VISUAL"

export PATH=$PATH:/home/rook/.local/bin:/usr/local/go/bin

# truncate long lines when doing recursive grep
cg() {
  grep -ir $1 * | cut -c1-120 | grep -i --color -E "^|$1"
}

# make Ctrl-d just exit the terminal, don't run the command first
bind '"\C-d": "\C-u\C-d"'

# LOLI maybe add something here to pull from git?
hs() {
    scp -q ~/.rook-profile.sh $1:.rook-profile.sh
    ssh $1 'grep -qxF "source ~/.rook-profile.sh" ~/.profile || echo "source ~/.rook-profile.sh" >> ~/.profile'
    ssh $1
}

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
