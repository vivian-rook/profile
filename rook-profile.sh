HISTFILESIZE=20000
HISTSIZE=20000

unset HISTTIMEFORMAT
export VISUAL=vim
export EDITOR="$VISUAL"
export PATH=$PATH:/home/rook/.local/bin:/usr/local/go/bin:$HOME/go/bin
shopt -s histverify

# maybe this could go in a logout profile?
FILE=~/.histories/bash_history.$(date +'%Y%m%d')
if [ ! -f $FILE ]; then
    mkdir ~/.histories 2>/dev/null
    cp ~/.bash_history ~/.histories/bash_history.$(date +'%Y%m%d')
    # cat with line numbers | remove lines longer than 280 char | sort by column 2 | tac | uniq ignore field 1 | sort numerically | drop starting number | remove any straggling hg | remove any straggling history
    cat -n ~/.histories/bash_history.$(date +'%Y%m%d') | sed '/^.\{280\}./d' | sort -k2 | tac | uniq -f1 | sort -n | cut -f2- | sed '/^hg /d' | sed '/^history /d' > ~/.bash_history
fi


# give a purple command line color
PS1='\[\033[01;35m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# setup vimrc
cat << EOF > ~/.vimrc
set encoding=utf-8
set hlsearch " highlight all matching search terms
set listchars=tab:ᐅ\ 
set list

set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab

autocmd Filetype javascript setlocal ts=4 sts=4 sw=4 noexpandtab
EOF

set -o vi

# truncate long lines when doing recursive grep
grepc() {
  grep -ir $1 * | cut -c1-240 | grep -i --color -E "^|$1"
}

# make Ctrl-d just exit the terminal, don't run the command first
bind '"\C-d": "\C-u\C-d"'

# LOLI maybe add something here to pull from git?
# LOLI is there some why to identify what file will be sourced, and use that?
hs() {
    profile64=$(base64 -w0 ~/.rook-profile.sh)
    ssh $1 "echo -n $profile64 | base64 -d > ~/.rook-profile.sh && grep -qxF 'source ~/.rook-profile.sh' ~/.bashrc || echo 'source ~/.rook-profile.sh' | tee -a ~/.bashrc ~/.profile"
    ssh $1
}

gitpr() {
  git fetch origin pull/$1/head:pr-$1 ; git checkout pr-$1
}

gitrp() {
  git checkout main ; git branch -D $1 ; git pull ; git checkout $1
}

sandbox() {
    if [ -z "${1}" ];
    then
      sandboxes=$(docker ps | grep sandbox$ | wc -l)
      if (( ${sandboxes} > 1 ));
      then
        echo "Found multiple sandboxes trying the first I find."
        sandbox=$(docker ps | grep sandbox$ | awk '{print $NF}' | head -1)
        echo ${sandbox}
      elif (( ${sandboxes} == 0 ));
      then
        echo "I see no sandboxes here..."
        return
      else
        sandbox=$(docker ps | grep sandbox$ | awk '{print $NF}')
        echo ${sandbox}
      fi
    else
      sandbox=${1}
    fi

  docker cp ~/.rook-profile.sh ${sandbox}:/
  docker exec -it ${sandbox} bash --rcfile /.rook-profile.sh
}

mkone() {
    CHAINGUARD_VERSION_ALLOW="$1-$2" make image-debug/$1
}

helmsetup() {
  export PATH=$PATH:$(find / | grep helm$ | grep bin | head -1 | sed 's/helm$//')
  kubectl config view --raw=true > /root/.kube/config
}

ksns() {
  kubectl config set-context --current --namespace=$(kg ns | grep $1 | awk '{print $1}')
}

music() {
  IFS=$'\n'
  mplayer $(ls | shuf)
  unset IFS
}

hg() {
    thehistory=$(history)

    # $() seems to mess up vim highlighting here. using `` for now
    thehistory=`grep -v '^ *[0-9]* *hg ' <<< "${thehistory}"`
    #thehistory=`grep -v -P '^[\d\s]+ hg ' <<< "${thehistory}"` # this works though some systems don't have -P
    for var in "$@"
    do
        thehistory=`grep ${var} <<< "${thehistory}"`
    done

    history -s $(echo "$thehistory" | tail -n1 | perl -pe 's/^ *\d+ +//')
    printf "$thehistory"
    echo
}

#ws() {
#  #work scp -o StrictHosStrictHostKeyChecking=accept-new .rook-profile.sh ws:
#  WORKSTATION_USER=vivian-rook work
#}
ws() {
  #gcloud auth login --update-adc # this needs to run if the other fails. Opens a browser window
  # us [] to keep grep from finding itself
  if ps ax | grep [v]ivian_rook_chainguard_dev@ ; then
    login=$(ps ax | grep [v]ivian_rook_chainguard_dev@ | head -1 | awk '{print $NF}')
    profile64=$(base64 -w0 ~/.rook-profile.sh)
    ssh -o StrictHostKeyChecking=no $login "echo -n $profile64 | base64 -d > ~/.rook-profile.sh && grep -qxF 'source ~/.rook-profile.sh' ~/.bashrc || echo 'source ~/.rook-profile.sh' | tee -a ~/.bashrc ~/.profile"
    cg work ssh
  else
    cg work ssh
  fi
}

ws16() {
  cg work stop
  cg work create --machine-type n2-standard-16
}

ke() {
  kubectl exec -it $1 -- bash
}

alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kga='kubectl get all'
# truncate long pod names
alias kgp='kubectl get pods'
alias kgpd='kubectl get pods'
# print ip and image
alias kgn="kubectl get nodes -o wide | awk -F '  +' '{gsub(/ /, \"-\", \$8); print \$1,\$2,\$3,\$4,\$5,\$6,\$8}' | column -t"
alias kgnd="kubectl get nodes"
alias ktp="kubectl top pods | awk '{ \$1=substr(\$1, 1, 70); print }' | column -t"
alias ktpd='kubectl top pods'
alias ktn='kubectl top nodes'
alias kl='kubectl logs'
alias kgo='kubectl get -o yaml'
alias kgao='kubectl get all -o yaml'
alias gitp='git pull'
alias gitclean='git checkout . ; git clean -df'
alias gits='git status'
alias gitc='git checkout'
alias gitcm='git checkout main'
alias gitd='git diff'
alias gitdm='git diff main'
alias gitdh='git diff HEAD~1'
#alias gitdh='git diff main...HEAD'
alias gita='git add'
alias gitl='git log -p --'
alias ghpr='gh pr checkout '
alias gn='grep 2>/dev/null'
alias d='docker'
alias dps='docker ps'
alias d-clean='docker rm -vf $(docker ps -aq) ; docker rmi -f $(docker images -aq) ; docker system prune --volumes --all --force'
alias sshagent='eval `ssh-agent -s` ; ssh-add ~/.ssh/id_ed25519'

# cg specific
alias cdo='cd ~/git/wolfi-dev/os'
alias cdo2='cd ~/git/2/wolfi-dev/os'
alias cde='cd ~/git/chainguard-dev/enterprise-packages'
alias cdex='cd ~/git/chainguard-dev/extra-packages'
alias cdi='cd ~/git/chainguard-dev/images-private/'

alias wsauth='chainctl auth logout ; ~/git/image-fulfillment-sandbox/phil.roche/login-images.sh'


# The image release process will append the /${repo}
export TF_VAR_target_repository="cgr.dev/chainguard-eng/rook"
export TF_VAR_target_custom_repository="cgr.dev/chainguard-eng/rook"
