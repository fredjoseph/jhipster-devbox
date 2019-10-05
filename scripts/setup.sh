#!/bin/sh

# update the system
export DEBIAN_FRONTEND=noninteractive
apt-mark hold keyboard-configuration
apt-get -o Dpkg::Options::=--force-confnew update
apt-mark unhold keyboard-configuration

################################################################################
# Install and configure the environment
################################################################################

apt-get -y install jq

sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'"${keyboard_layout}"'\"/g' /etc/default/keyboard
sed -i 's/XKBVARIANT=\"\w*"/XKBVARIANT=\"'"${keyboard_variant}"'\"/g' /etc/default/keyboard

locale-gen "${locale}"'.UTF-8'
echo 'LANG='"${locale}"'.UTF-8' >> /etc/environment
echo 'LANGUAGE='"${locale}"'.UTF-8' >> /etc/environment
echo 'LC_ALL='"${locale}"'.UTF-8' >> /etc/environment
echo 'LC_CTYPE='"${locale}"'.UTF-8' >> /etc/environment

# create the user if not 'vagrant'
if [ ${user} != "vagrant" ]
then
    useradd -m ${user} --groups sudo
    cp -pr /home/vagrant/.ssh /home/${user}/
    chown -R ${user}:${user} /home/${user}
    echo "%${user} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${user}
fi
   
# run GUI as non-privileged user
echo 'allowed_users=anybody' > /etc/X11/Xwrapper.config

# update hosts file
IFS=
for line in $(echo ${hosts} | jq '.[]' -r); do
    echo $line
    sudo echo $line | sudo tee -a /etc/hosts
done
unset IFS

# install Ubuntu desktop and VirtualBox guest tools
apt-get -o Dpkg::Options::=--force-confnew install -y xubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-additions-iso
dpkg --configure -a --force-confnew

# auto-login
touch /etc/lightdm/lightdm.conf
echo '[SeatDefaults]' >> /etc/lightdm/lightdm.conf
echo "autologin-user=${user}" >> /etc/lightdm/lightdm.conf
echo 'autologin-user-timeout=0' >> /etc/lightdm/lightdm.conf

# disable screensaver
sed -i -e 's/mode:\t\t\trandom/mode:\t\t\toff/' /etc/X11/app-defaults/XScreenSaver-nogl

# remove light-locker (see https://github.com/jhipster/jhipster-devbox/issues/54)
apt-get remove -y light-locker --purge

# change the default wallpaper
wget https://raw.githubusercontent.com/jhipster/jhipster-devbox/master/images/jhipster-wallpaper.png -O /usr/share/xfce4/backdrops/jhipster-wallpaper.png
sed -i -e 's/xubuntu-wallpaper.png/jhipster-wallpaper.png/' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

################################################################################
# Install the mandatory tools
################################################################################

# install utilities
apt-get install -y vim git zip bzip2 fontconfig curl language-pack-en

# install Java 8
apt-get install -y openjdk-8-jdk

# install Node.js, NPM and dependencies
su -c "curl --silent \"https://api.github.com/repos/nvm-sh/nvm/releases/latest\" | grep -Po '\"tag_name\": \"\K.*?(?=\")' | xargs -I {} curl -o- \"https://raw.githubusercontent.com/nvm-sh/nvm/{}/install.sh\" | bash" ${user}
su - ${user} << EOF
export NVM_DIR=\$HOME/.nvm
. \$NVM_DIR/nvm.sh 
nvm install 10.16.1

# update NPM
npm install -g npm

# install Yarn
npm install -g yarn
yarn config set prefix \$HOME/.yarn-global

# install Yeoman
npm install -g yo

# install JHipster
npm install -g generator-jhipster@6.2.0

# install JHipster UML
npm install -g jhipster-uml@2.0.3
EOF

# install postgresql
apt-get install -y postgresql
su -c "createuser -s ${user}" postgres

#install go
apt-get install -y golang-go

################################################################################
# Install Powerline
################################################################################

# From https://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin
apt-get install -y python-pip

pip install powerline-status

wget https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf
mv PowerlineSymbols.otf /usr/share/fonts/
fc-cache -vf
mv 10-powerline-symbols.conf /etc/fonts/conf.d/

cat >> /home/${user}/.vimrc <<- EOM
set rtp+=/usr/local/lib/python2.7/dist-packages/powerline/bindings/vim/

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256
EOM

cat >> /home/${user}/.tmux.conf <<- EOM
source /usr/local/lib/python2.7/dist-packages/powerline/bindings/tmux/powerline.conf
set-option -g default-terminal "screen-256color"
EOM

################################################################################
# Install the development tools
################################################################################

# install Ubuntu Make - see https://wiki.ubuntu.com/ubuntu-make
apt-get install -y ubuntu-make

# install Chromium Browser
apt-get install -y chromium-browser

# install MySQL Workbench
apt-get install -y mysql-workbench

# install PgAdmin and pgcli
apt-get install -y pgadmin3 pgcli
# install maven
apt-get install -y maven

# install Heroku toolbelt
wget -O- https://toolbelt.heroku.com/install-ubuntu.sh | sh

# install Guake
apt-get install -y guake
cp /usr/share/applications/guake.desktop /etc/xdg/autostart/

# install zsh
apt-get install -y zsh

# install oh-my-zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git /home/${user}/.oh-my-zsh
cp /home/${user}/.oh-my-zsh/templates/zshrc.zsh-template /home/${user}/.zshrc
sed -i -e "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"avit\"/g" /home/${user}/.zshrc
echo "plugins+=(docker docker-compose colored-man-pages common-aliases)" >> /home/${user}/.zshrc
chsh -s /bin/zsh ${user}
echo 'SHELL=/bin/zsh' >> /etc/environment

# nvm
git clone https://github.com/lukechilds/zsh-nvm /home/${user}/.oh-my-zsh/custom/plugins/zsh-nvm
git clone https://github.com/lukechilds/zsh-better-npm-completion /home/${user}/.oh-my-zsh/custom/plugins/zsh-better-npm-completion
cat >> /home/${user}/.zshrc <<- EOM
export NVM_LAZY_LOAD=true
export NVM_DIR="\$HOME/.nvm"
#[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion

plugins+=(zsh-nvm zsh-better-npm-completion)
EOM

# change user to ${user}
chown -R ${user}:${user} /home/${user}/.zshrc /home/${user}/.oh-my-zsh

# install jhipster-oh-my-zsh-plugin
git clone https://github.com/jhipster/jhipster-oh-my-zsh-plugin.git /home/${user}/.oh-my-zsh/custom/plugins/jhipster
echo "plugins+=(jhipster)" >> /home/${user}/.zshrc

# install Visual Studio Code
snap install code --classic

#install IDEA community edition
snap install intellij-idea-community --classic

# increase Inotify limit (see https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
echo "fs.inotify.max_user_watches = 524288" > /etc/sysctl.d/60-inotify.conf
sysctl -p --system

# install latest Docker
curl -sL https://get.docker.io/ | sh

# install latest docker-compose
curl -L "$(curl -s https://api.github.com/repos/docker/compose/releases | grep browser_download_url | head -n 4 | grep Linux | grep -v sha256 | cut -d '"' -f 4)" > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# configure docker group (docker commands can be launched without sudo)
usermod -aG docker ${user}

# install postman
snap install postman

# install insomnia
snap install insomnia

################################################################################
# Install utility tools
################################################################################

# install fuzzy finder
apt-get install -y fzy

# install httpie
apt-get install -y httpie

## install jq
#apt-get install -y jq

# install ripgrep
curl --silent "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")' | xargs -I {} curl -sOL "https://github.com/BurntSushi/ripgrep/releases/download/{}/ripgrep_{}_amd64.deb"
dpkg -i ripgrep_*_amd64.deb
rm ripgrep_*

# install fd
curl --silent "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")' | xargs -I {} curl -sOL "https://github.com/sharkdp/fd/releases/download/v{}/fd_{}_amd64.deb"
dpkg -i fd_*_amd64.deb
rm fd_*

# install bat
curl --silent "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")' | xargs -I {} curl -sOL "https://github.com/sharkdp/bat/releases/download/v{}/bat_{}_amd64.deb"
dpkg -i bat_*_amd64.deb
rm bat_*

su -c "mkdir /home/${user}/.zsh_completion.d"

# install z/fzf
su -c "git clone --depth 1 https://github.com/junegunn/fzf.git /home/${user}/.fzf" ${user}
su -c "curl \"https://raw.githubusercontent.com/rupa/z/master/{z.sh}\" -o /home/${user}/.zsh_completion.d/\"#1\""
su -c 'curl "https://raw.githubusercontent.com/changyuheng/fz/master/{fz.sh}" -o /home/${user}/.zsh_completion.d/z"#1"'
su -c "/home/${user}/.fzf/install --all --no-bash" ${user}
cat >> /home/${user}/.zshrc <<- EOM
# Exclude those directories even if not listed in .gitignore, or if .gitignore is missing
FD_OPTIONS="--follow --exclude .git --exclude node_modules"

# Change behavior of fzf dialogue
export FZF_DEFAULT_OPTS="--no-mouse --height 50% -1 --reverse --multi --inline-info --preview='[[ \$(file --mime {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || cat {}) 2> /dev/null | head -300' --preview-window='right:hidden:wrap' --bind='f3:execute(bat --style=numbers {} || less -f {}),f2:toggle-preview,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-a:select-all+accept,ctrl-y:execute-silent(echo {+} | pbcopy)'"

# Change find backend
# Use 'git ls-files' when inside GIT repo, or fd otherwise
export FZF_DEFAULT_COMMAND="git ls-files --cached --others --exclude-standard | fd --type f --type l $FD_OPTIONS"

# Find commands for "Ctrl+T" and "Opt+C" shortcuts
export FZF_CTRL_T_COMMAND="fd $FD_OPTIONS"
export FZF_ALT_C_COMMAND="fd --type d $FD_OPTIONS"
EOM
touch /home/${user}/.z

# install autocutsel
apt-get install -y autocutsel
echo 'autocutsel -selection PRIMARY -fork' >> /home/${user}/.zshrc
echo 'autocutsel -fork' >> /home/${user}/.zshrc

# install autojump
apt-get install -y autojump
echo "plugins+=(autojump)" >> /home/${user}/.zshrc

# install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${user}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
echo "plugins+=(zsh-syntax-highlighting)" >> /home/${user}/.zshrc

# install k
git clone https://github.com/supercrabtree/k /home/${user}/.oh-my-zsh/custom/plugins/k
echo "plugins+=(k)" >> /home/${user}/.zshrc

# install bd
mkdir -p /home/${user}/.oh-my-zsh/custom/plugins/bd
curl https://raw.githubusercontent.com/Tarrasch/zsh-bd/master/bd.zsh > /home/${user}/.oh-my-zsh/custom/plugins/bd/bd.zsh
echo "\n# zsh-bd\n. \$ZSH_CUSTOM/plugins/bd/bd.zsh" >> /home/${user}/.zshrc

# install lazygit
add-apt-repository -y ppa:lazygit-team/release
apt-get install -y lazygit

#install highlight
apt-get install -y highlight

# install lf
su -c "go get -u github.com/gokcehan/lf" ${user}
mkdir -p /home/${user}/.config/lf
cp /home/${user}/go/src/github.com/gokcehan/lf/etc/lfrc.example /home/${user}/.config/lf/lfrc
cat >> /home/${user}/.config/lf/lfrc <<- EOM
map v \$highlight --out-format=ansi \$f | less -R
map V \$highlight --out-format=ansi \$(fzf) | less -R
map e \$vi \$f
map E \$vi \$(fzf)
map l \$lf -remote "send \$id select \$(fzf)"
EOM

# install nnn
curl --silent "https://api.github.com/repos/jarun/nnn/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")' | xargs -I {} curl -sOL "https://github.com/jarun/nnn/releases/download/v{}/nnn_{}-1_debian9.amd64.deb"
dpkg -i nnn_*_debian9.amd64.deb
rm nnn_*

# install wuzz (HTTP inspector)
su -c "go get -u github.com/asciimoo/wuzz" ${user}

# install has
curl -sL https://git.io/_has > /usr/local/bin/has
chmod +x /usr/local/bin/has

# install yq
snap install yq

#install cheat.sh
apt-get install -y xsel rlwrap
curl https://cht.sh/:cht.sh > /usr/local/bin/cht.sh
chmod +x /usr/local/bin/cht.sh

# install npm dependencies
su - ${user} << EOF
# install can i use
npm install -g caniuse-cmd

# install tldr
npm install -g tldr

# install fx (JSON viewer)
npm install -g fx

# install Kmdr
npm install -g kmdr
EOF

# install vim plugin
curl -fLo /home/${user}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
cat >> /home/${user}/.vimrc <<- EOM
source ~/.vim/.plug.vim
EOM
wget https://raw.githubusercontent.com/fredjoseph/jhipster-devbox/master/scripts/.plug.vim -O /home/${user}/.vim/.plug.vim

# Load zsh_completions
cat >> /home/${user}/.zshrc <<- EOM
if [ -d ~/.zsh_completion.d ]; then
  for file in ~/.zsh_completion.d/*; do
    . \$file
  done
fi
EOM

# Aliases
cat >> /home/${user}/.zshrc <<- EOM
bro() {curl bropages.org/\$1.json | jq -r ".[].msg" | highlight --out-format=truecolor --syntax=bash | less -R}
EOM

echo 'source $ZSH/oh-my-zsh.sh' >> /home/${user}/.zshrc

# Fixes
sed -i '/[ -f ~\/.fzf.zsh ] && source ~\/.fzf.zsh/d' /home/${user}/.zshrc # delete the existing line and add it at the end of the file
cat >> /home/${user}/.zshrc <<- EOM
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
unalias fd
EOM

echo "export PATH=\"\$PATH:/home/${user}/.yarn-global/bin:/home/${user}/.yarn/bin:/home/${user}/.config/yarn/global/node_modules/.bin:/home/${user}/go/bin\"" >> /home/${user}/.zshrc
echo "typeset -aU fpath" >> /home/${user}/.zshrc

################################################################################
# Clean the box
################################################################################

echo "sudo mount -t vboxsf host /host" >> /home/${user}/.zshrc

# fix ownership of home
chown -R ${user}:${user} /home/${user}/
chmod -R g-x,o-x /home/${user}/.oh-my-zsh

apt-get -y autoclean
apt-get -y clean
apt-get -y autoremove
dd if=/dev/zero of=/EMPTY bs=1M > /dev/null 2>&1
rm -f /EMPTY

reboot
