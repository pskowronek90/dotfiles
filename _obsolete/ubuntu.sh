#!/usr/bin/env bash
ROOT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

ask_for_sudo() {
  if [ "$EUID" -ne 0 ]; then
    print_question "Do you sudo\n"
    exit 1
  fi
}

print_error() {
    print_in_red "   [✖] $1 $2"
}

print_in_color() {
    printf "%b" \
        "$(tput setaf "$2" 2> /dev/null)" \
        "$1" \
        "$(tput sgr0 2> /dev/null)"
}

print_in_green() {
    print_in_color "$1" 2
}

print_in_red() {
    print_in_color "$1" 1
}

print_in_yellow() {
    print_in_color "$1" 3
}

print_question() {
    print_in_yellow "   [?] $1"
}

print_success() {
    print_in_green "   [✔] $1"
}

proclaim() {
    print_in_yellow "\n   [!] $1"
}

VERSION="0.5"

ask_for_sudo

SILENT=""
if [[ $1 = '--silent' ]]; then
  SILENT=" > /dev/null 2>&1"
fi

_=$(command -v curl)
if [ "$?" != 0 ]; then
  proclaim "Curl is a must"
  eval "apt update $SILENT"
  eval "apt install -y curl $SILENT"
  print_success "Curl is now ready"
fi

APTINSTALLS="apt install -y"
APTINSTALLS="${APTINSTALLS} apt-transport-https ca-certificates build-essential"
APTINSTALLS="${APTINSTALLS} software-properties-common"
APTINSTALLS="${APTINSTALLS} vim git htop ncdu ack tree"
APTINSTALLS="${APTINSTALLS} shutter unclutter tmux ctags"
APTINSTALLS="${APTINSTALLS} google-chrome-stable docker-ce"

SNAPINSTALLS=()
SNAPINSTALLS+=("slack --classic")

proclaim "Injecting apt-repo keys"
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
print_success "Injected apt-repo keys"
_=`grep -q "dl.google.com/linux/chrome/deb" /etc/apt/sources.list.d/google-chrome.list`
if [ $? != 0 ]; then
  proclaim "Injecting Chrome apt-repo"
  echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
  print_success "Injected Chrome apt-repo"
fi

_=`grep -q "download.docker.com/linux/ubuntu" /etc/apt/sources.list`
if [ $? != 0 ]; then
  proclaim "Injecting Docker apt-repo"
  echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" >> /etc/apt/sources.list
  print_success "Injected Docker apt-repo"
fi

proclaim "Injecting .vimrc .bash_aliases .xinitrc terminalrc"
cd ~
[ -e .vimrc ] && rm -f .vimrc
[ -e .tmux.conf ] && rm -f .tmux.conf
[ -e .bash_aliases ] && rm -f .bash_aliases
[ -e .xinitrc ] && rm -f .xinitrc
[ ! -d .config/xfce/terminal ] && mkdir -p .config/xfce/terminal
[ -e .config/xfce/terminal/terminalrc ] && rm .config/xfce/terminal/terminalrc
eval "wget https://raw.githubusercontent.com/unamatasanatarai/dotfiles/master/.vimrc $SILENT"
eval "wget https://raw.githubusercontent.com/unamatasanatarai/dotfiles/master/.bash_aliases $SILENT"
eval "wget https://raw.githubusercontent.com/unamatasanatarai/dotfiles/master/.xinitrc $SILENT"
eval "wget https://raw.githubusercontent.com/unamatasanatarai/dotfiles/master/.tmux.conf $SILENT"
cd ~/.config/xfce/terminal/
eval "wget https://raw.githubusercontent.com/unamatasanatarai/dotfiles/master/.config/xfce/terminal/terminalrc $SILENT"
cd ~
print_success "Injected .vimrc .bash_aliases .xinitrc terminalrc"

proclaim "apt update"
eval "apt update $SILENT"
print_success "apt update"

proclaim "$APTINSTALLS"
eval "${APTINSTALLS} ${SILENT}"
print_success "$APTINSTALLS"

proclaim "snap install: $SNAPINSTALLS"
for item in "${SNAPINSTALLS[@]}"
do
  proclaim "snap install ${item}"
  eval "snap install $item $SILENT"
  if [ "$?" != 0 ]; then
    print_error "${item}"
  else
    print_success "${item}"
  fi
done

_=$(command -v docker-compose)
if [ "$?" != 0 ]; then
  proclaim "Installing docker-compose"
  eval "curl -sL https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose"
  chmod +x /usr/local/bin/docker-compose
  print_success "Installed docker-compose"
fi

proclaim "Fixing Edit mode in Shutter"
mkdir /tmp/shutter/
cd /tmp/shutter/
eval "wget https://launchpad.net/ubuntu/+archive/primary/+files/libgoocanvas-common_1.0.0-1_all.deb $SILENT"
eval "wget https://launchpad.net/ubuntu/+archive/primary/+files/libgoocanvas3_1.0.0-1_amd64.deb $SILENT"
eval "wget https://launchpad.net/ubuntu/+archive/primary/+files/libgoo-canvas-perl_0.06-2ubuntu3_amd64.deb $SILENT"

eval "sudo dpkg -i libgoocanvas-common_1.0.0-1_all.deb $SILENT"
eval "sudo apt -y -f install $SILENT"
eval "sudo dpkg -i libgoocanvas3_1.0.0-1_amd64.deb $SILENT"
eval "sudo apt -y -f install $SILENT"
eval "sudo dpkg -i libgoo-canvas-perl_0.06-2ubuntu3_amd64.deb $SILENT"
eval "sudo apt -y -f install $SILENT"

cd ~
rm -rf /tmp/shutter
print_success "Fixed edit mode in Shutter"

proclaim "Spin up vim plugins"
eval "mkdir -p ~/.vim/pack/vendor/start"
cd ~/.vim/pack/vendor/start
eval "git clone --depth=1 https://github.com/ctrlpvim/ctrlp.vim.git $SILENT"
eval "git clone --depth=1 https://github.com/vim-syntastic/syntastic.git $SILENT"
eval "git clone --depth=1 https://github.com/907th/vim-auto-save.git $SILENT"
eval "chown -R $USER ~/.vim"
eval 'vi "+helptags ~/.vim/pack/vendor/start/syntastic/doc" +qall'
eval 'vi "+helptags ~/.vim/pack/vendor/start/ctrlp.vim/doc" +qall'
eval 'vi "+helptags ~/.vim/pack/vendor/start/vim-auto-save/doc" +qall'
print_success "Spun up vim plugins"

proclaim "Full system upgrade"
eval "apt update $SILENT"
eval "apt -y full-upgrade $SILENT"
print_success "Full system upgrade"

proclaim "Autocleanup apt"
eval "apt autoremove -y $SILENT"
print_success "Cleandup apt"


#dock
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false


print_in_yellow "

···············
· I ♥M H♥PPY! ·
···············
"
