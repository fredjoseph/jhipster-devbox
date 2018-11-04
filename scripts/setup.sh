#!/bin/sh

# update the system
export DEBIAN_FRONTEND=noninteractive
apt-mark hold keyboard-configuration
apt-get update
apt-get -y upgrade
apt-mark unhold keyboard-configuration

################################################################################
# Install the mandatory tools
################################################################################

# install utilities
apt-get -y install vim git zip bzip2 fontconfig curl language-pack-en

# install Java 11
apt-get -y install openjdk-11-jdk

# install Node.js
wget https://nodejs.org/dist/v10.16.1/node-v10.16.1-linux-x64.tar.gz -O /tmp/node.tar.gz
tar -C /usr/local --strip-components 1 -xzf /tmp/node.tar.gz

# update NPM
npm install -g npm

# install Yarn
npm install -g yarn
su -c "yarn config set prefix /home/vagrant/.yarn-global" vagrant

# install Yeoman
npm install -g yo

# install JHipster
npm install -g generator-jhipster@6.2.0

# install JHipster UML
npm install -g jhipster-uml@2.0.3

# install postgresql
apt-get install -y postgresql
su -c "createuser -s vagrant" postgres

#install go
apt-get install -y golang-go

################################################################################
# Install the graphical environment
################################################################################

setxkbmap ${keyboard_layout}
sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'"${keyboard_layout}"'\"/g' /etc/default/keyboard
sed -i 's/XKBVARIANT=\"\w*"/XKBVARIANT=\"'"${keyboard_variant}"'\"/g' /etc/default/keyboard

locale-gen "${locale}"'.UTF-8'
echo 'LANG='"${locale}"'.UTF-8' >> /etc/environment
echo 'LANGUAGE='"${locale}"'.UTF-8' >> /etc/environment
echo 'LC_ALL='"${locale}"'.UTF-8' >> /etc/environment
echo 'LC_CTYPE='"${locale}"'.UTF-8' >> /etc/environment

touch /home/vagrant/.xscreensaver
sed -i -e 's/mode:\t\trandom/mode:\t\toff/' /home/vagrant/.xscreensaver
    
# run GUI as non-privileged user
echo 'allowed_users=anybody' > /etc/X11/Xwrapper.config

# install Ubuntu desktop and VirtualBox guest tools
apt-get install -y xubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-additions-iso

# auto-login
touch /etc/lightdm/lightdm.conf
echo '[SeatDefaults]' >> /etc/lightdm/lightdm.conf
echo 'autologin-user=vagrant' >> /etc/lightdm/lightdm.conf
echo 'autologin-user-timeout=0' >> /etc/lightdm/lightdm.conf

# remove light-locker (see https://github.com/jhipster/jhipster-devbox/issues/54)
apt-get remove -y light-locker --purge

# change the default wallpaper
wget https://raw.githubusercontent.com/jhipster/jhipster-devbox/master/images/jhipster-wallpaper.png -O /usr/share/xfce4/backdrops/jhipster-wallpaper.png
sed -i -e 's/xubuntu-wallpaper.png/jhipster-wallpaper.png/' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

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
git clone git://github.com/robbyrussell/oh-my-zsh.git /home/vagrant/.oh-my-zsh
cp /home/vagrant/.oh-my-zsh/templates/zshrc.zsh-template /home/vagrant/.zshrc
chsh -s /bin/zsh vagrant
echo 'SHELL=/bin/zsh' >> /etc/environment

# install jhipster-oh-my-zsh-plugin
git clone https://github.com/jhipster/jhipster-oh-my-zsh-plugin.git /home/vagrant/.oh-my-zsh/custom/plugins/jhipster
sed -i -e "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"avit\"/g" /home/vagrant/.zshrc
echo "plugins+=(docker docker-compose jhipster)" >> /home/vagrant/.zshrc

# change user to vagrant
chown -R vagrant:vagrant /home/vagrant/.zshrc /home/vagrant/.oh-my-zsh

# install Visual Studio Code
su -c 'umake ide visual-studio-code /home/vagrant/.local/share/umake/ide/visual-studio-code --accept-license' vagrant

# fix links (see https://github.com/ubuntu/ubuntu-make/issues/343)
sed -i -e 's/visual-studio-code\/code/visual-studio-code\/bin\/code/' /home/vagrant/.local/share/applications/visual-studio-code.desktop

# disable GPU (see https://code.visualstudio.com/docs/supporting/faq#_vs-code-main-window-is-blank)
sed -i -e 's/"$CLI" "$@"/"$CLI" "--disable-gpu" "$@"/' /home/vagrant/.local/share/umake/ide/visual-studio-code/bin/code

#install IDEA community edition
su -c 'umake ide idea /home/vagrant/.local/share/umake/ide/idea' vagrant

# increase Inotify limit (see https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
echo "fs.inotify.max_user_watches = 524288" > /etc/sysctl.d/60-inotify.conf
sysctl -p --system

# install latest Docker
curl -sL https://get.docker.io/ | sh

# install latest docker-compose
curl -L "$(curl -s https://api.github.com/repos/docker/compose/releases | grep browser_download_url | head -n 4 | grep Linux | grep -v sha256 | cut -d '"' -f 4)" > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# configure docker group (docker commands can be launched without sudo)
usermod -aG docker vagrant

# install postman
snap install postman

# install insomnia
snap install insomnia

################################################################################
# Install utility tools
################################################################################
# install fuzzy finder
apt-get install -y fzy

# install jq
apt-get install -y jq

# install ripgrep
curl --silent "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")' | xargs -I {} curl -sOL "https://github.com/BurntSushi/ripgrep/releases/download/{}/ripgrep_{}_amd64.deb"
dpkg -i ripgrep_*_amd64.deb
rm ripgrep_*

# install bat
curl --silent "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")' | xargs -I {} curl -sOL "https://github.com/sharkdp/bat/releases/download/v{}/bat_{}_amd64.deb"
dpkg -i bat_*_amd64.deb
rm bat_*

su -c "mkdir /home/vagrant/.bash_completion.d"

# install z/fzf
su -c "git clone --depth 1 https://github.com/junegunn/fzf.git /home/vagrant/.fzf" vagrant
su -c 'curl "https://raw.githubusercontent.com/rupa/z/master/{z.sh}" -o /home/vagrant/.bash_completion.d/"#1"'
su -c 'curl "https://raw.githubusercontent.com/changyuheng/fz/master/{fz.sh}" -o /home/vagrant/.bash_completion.d/z"#1"'
su -c "/home/vagrant/.fzf/install --all --no-bash" vagrant

# install autocutsel
apt-get install -y autocutsel
echo 'autocutsel -selection PRIMARY -fork' >> /home/vagrant/.zshrc
echo 'autocutsel -fork' >> /home/vagrant/.zshrc

# install autojump
apt-get install -y autojump
echo "plugins+=(autojump)" >> /home/vagrant/.zshrc

# install k
git clone https://github.com/supercrabtree/k /home/vagrant/.oh-my-zsh/custom/plugins/k
echo "plugins+=(k)" >> /home/vagrant/.zshrc

# install bd
mkdir -p /home/vagrant/.oh-my-zsh/custom/plugins/bd
curl https://raw.githubusercontent.com/Tarrasch/zsh-bd/master/bd.zsh > /home/vagrant/.oh-my-zsh/custom/plugins/bd/bd.zsh
echo "\n# zsh-bd\n. \$ZSH_CUSTOM/plugins/bd/bd.zsh" >> /home/vagrant/.zshrc

# install lazygit
add-apt-repository -y ppa:lazygit-team/release
apt-get install -y lazygit

#install highlight
apt-get install -y highlight

# install lf
su -c "go get -u github.com/gokcehan/lf" vagrant
mkdir -p /home/vagrant/.config/lf
cp /home/vagrant/go/src/github.com/gokcehan/lf/etc/lfrc.example /home/vagrant/.config/lf/lfrc
cat >> /home/vagrant/.config/lf/lfrc <<- EOM
map v \$highlight --out-format=ansi \$f | less -R
map V \$highlight --out-format=ansi \$(fzf) | less -R
map e \$vi \$f
map E \$vi \$(fzf)
map l \$lf -remote "send \$id select \$(fzf)"
EOM

# Load bash_completions
cat >> /home/vagrant/.zshrc <<- EOM
if [ -d ~/.bash_completion.d ]; then
  for file in ~/.bash_completion.d/*; do
    . \$file
  done
fi
EOM

echo 'source $ZSH/oh-my-zsh.sh' >> /home/vagrant/.zshrc
echo 'export PATH="$PATH:/usr/bin:/home/vagrant/.yarn-global/bin:/home/vagrant/.yarn/bin:/home/vagrant/.config/yarn/global/node_modules/.bin:/home/vagrant/go/bin"' >> /home/vagrant/.zshrc

################################################################################
# Clean the box
################################################################################

echo "sudo mount -t vboxsf host /host" >> /home/vagrant/.zshrc

# fix ownership of home
chown -R vagrant:vagrant /home/vagrant/

apt-get -y autoclean
apt-get -y clean
apt-get -y autoremove
dd if=/dev/zero of=/EMPTY bs=1M > /dev/null 2>&1
rm -f /EMPTY

reboot
