#!/bin/bash

#
# Installation script to set up an Xubuntu 16.04 (Xenial) system.
#

set -e

scriptname=$(basename ${0})

function die_with_error() {
    echo "error: $1" 2>&1
    echo
    echo "usage: ${scriptname} [--laptop-mode true]"
    echo "  --laptop-mode=BOOL     Set to true to install laptop-mode-tools."
    exit 1
}

if [ "$(whoami)" = "root" ]; then
    die_with_error "please do not run this script as root"
    exit 1
fi

LAPTOP_MODE=false

for arg in "${@}"; do
    case ${arg} in
	--laptop-mode=*)
	    LAPTOP_MODE=${arg/*=/}
	    ;;
	--help)
	    die_with_error "xubuntu seed: installs a baseline of software and sets up dotfiles"
	    ;;
	*)
	    die_with_error "unknown argument: ${arg}"
	    ;;
    esac
done

echo "running with laptop-mode: ${LAPTOP_MODE}"


sudo mkdir -p /opt/bin
# scratch area: for data of temporary nature (but not being cleared
# on reboots like /tmp) and recreatable/non-precious data
sudo mkdir -p /scratch
sudo chmod 777 /scratch

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -yy
sudo apt-get install -yy \
  apt-transport-https \
  software-properties-common \
  apt-show-versions \
  aptitude \
  debconf-utils \
  curl


# enable Canoncial Partners sources. Software Updates > Other sofware.
sudo add-apt-repository "deb http://archive.canonical.com/ $(lsb_release -sc) partner"

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# google chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/google-chrome.list <<EOF
deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main
EOF

# visual studio code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
sudo mv /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo tee /etc/apt/sources.list.d/vscode.list <<EOF
deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main
EOF

# Azure cli
sudo tee /etc/apt/sources.list.d/azure-cli.list <<EOF
deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main
EOF
curl -sSL https://packages.microsoft.com/keys/microsoft.asc > /tmp/microsoft.asc
sudo apt-key add /tmp/microsoft.asc
rm /tmp/microsoft.asc


# Google Cloud's gcloud cli
CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list <<EOF
deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main
EOF
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Ansible
sudo apt-add-repository -y ppa:ansible/ansible

# spotify
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410
sudo tee /etc/apt/sources.list.d/spotify.list <<EOF
deb http://repository.spotify.com stable non-free
EOF

# virtualbox
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/virtualbox.list <<EOF
deb https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib
EOF

# duplicity backup tool
sudo apt-add-repository -y ppa:duplicity-team/ppa

sudo apt-get update -yy
sudo apt-get install -yy \
     pwgen \
     gparted \
     emacs24 \
     chromium-browser \
     google-chrome-stable \
     screen \
     sshfs \
     htop \
     iftop \
     bmon \
     iperf \
     curl \
     jq \
     inkscape \
     gnuplot \
     gimp \
     openssh-server \
     texlive-latex-base texlive-latex-extra \
     wmctrl \
     tree \
     git tig subversion \
     gnome-system-monitor \
     xdotool \
     markdown \
     spotify-client \
     code \
     dos2unix \
     gcolor2 \
     xsel \
     socat


# for laptops
if [ "${LAPTOP_MODE}" = "true" ]; then
    sudo apt-get install -y laptop-mode-tools
fi

#
# Shell/editor settings
#

# emacs settings
if ! [ -d ~/dotfiles ]; then
    cd ~ && git clone --recursive https://github.com/petergardfjall/dotfiles.git
else
    cd ~/dotfiles && git pull origin master
fi
ln -sf ~/dotfiles/emacs-init.el ~/.emacs

# vim settings
if ! [ -d ~/.vim/bundle/Vundle.vim ]; then
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
ln -sf ~/dotfiles/vim/vimrc ~/.vimrc
# NOTE: on first launch of vim, run :PluginInstall to have Vundle install the plugins configured in vimrc.

# vscode settings
mkdir -p ~/.config/Code/User/
sudo ln -sfn ~/dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
sudo ln -sfn ~/dotfiles/vscode/keybindings.json ~/.config/Code/User/keybindings.json
~/dotfiles/vscode/install-extensions.sh

#
# Install xubuntu desktop (if on regular ubuntu). A no-op on xubuntu distro.
#
sudo apt-get install -qy xubuntu-desktop
sudo apt-get remove ubuntu-desktop -y
sudo apt-get autoremove -y

# xfce config
~/dotfiles/setup-xfce4.sh

# extra .bashrc modules
if ! grep 'source ~/dotfiles/bash.includes' ~/.bashrc; then
    tee -a ~/.bashrc <<EOF
#
# source additional configuration modules
#
source ~/dotfiles/bash.includes
EOF
fi

# extra .profile modules
if ! grep 'source ~/dotfiles/bash.includes' ~/.profile; then
    tee -a ~/.profile <<EOF
#
# source additional configuration modules
#
source ~/dotfiles/bash.includes
EOF
fi

# set up screen config
ln -sfn ~/dotfiles/screen/screenrc ~/.screenrc

# useful scripts
mkdir -p ~/bin
if ! [ -d ~/bin/scripts ]; then
    cd ~/bin && git clone https://github.com/petergardfjall/scripts
else
    cd ~/bin/scripts && git pull origin master
fi

#
# dev
#

sudo apt-get install -yy \
     visualvm \
     httperf

# virtualbox
VIRTUALBOX_VERSION=5.2
sudo apt-get install -y \
     virtualbox-${VIRTUALBOX_VERSION} dkms

# vagrant
VAGRANT_VERSION=2.0.1
if ! vagrant --version | grep ${VAGRANT_VERSION}; then
    wget https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb -O /tmp/vagrant.deb
    sudo dpkg -i /tmp/vagrant.deb
    sudo rm /tmp/vagrant.deb
fi

# OpenJDK java
sudo apt-get install -y openjdk-8-jdk openjdk-8-source
JAVA_HOME="$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")"
sudo ln -sfn ${JAVA_HOME} /opt/java

# python
sudo apt-get install -qy \
     build-essential libssl-dev libffi-dev \
     python python-dev python-pip python-virtualenv \
     python3 python3-dev python3-pip python3-venv
sudo pip2 install --upgrade pip
sudo pip3 install --upgrade pip
sudo pip2 install ipython pipenv
sudo pip3 install ipython pipenv

sudo mkdir -p /opt

# maven
MAVEN_VERSION=3.5.2
if ! mvn --version | grep ${MAVEN_VERSION}; then
    sudo wget http://apache.mirrors.spacedump.net/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -O /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz
    sudo tar xzvf /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt
    sudo ln -sfn /opt/apache-maven-${MAVEN_VERSION} /opt/maven
    sudo rm /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz
fi

# eclipse
ECLIPSE_MAJOR_V=oxygen
ECLIPSE_MINOR_V=2
if ! [ -d /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V} ]; then
    sudo wget http://ftp.acc.umu.se/mirror/eclipse.org/technology/epp/downloads/release/${ECLIPSE_MAJOR_V}/${ECLIPSE_MINOR_V}/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz -O /opt/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz
    sudo mkdir -p /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}
    sudo tar xzvf /opt/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz -C /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}
    sudo ln -sfn /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}/eclipse /opt/eclipse
    sudo rm /opt/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz
fi

# docker
docker_compose_version=1.18.0
# install Docker and some other utilities
sudo apt-get install -qy docker-ce
# install docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose > /dev/null
sudo chmod +x /usr/local/bin/docker-compose
# To be able to use docker without sudo/root privileges, you need to add users to the docker group.
sudo usermod --append --groups docker $(whoami)


# Go
GO_VERSION=1.9
if ! go version | grep ${GO_VERSION}; then
    sudo wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go-${GO_VERSION}.tar.gz
    sudo tar xvf /tmp/go-${GO_VERSION}.tar.gz -C /tmp/
    sudo mv /tmp/go /opt/go-${GO_VERSION}
    sudo ln -sfn /opt/go-${GO_VERSION} /opt/go
    export GOROOT=/opt/go
    export GOPATH=~/dev/go
    sudo rm /tmp/go-${GO_VERSION}.tar.gz
fi

# Go development environment tools
mkdir -p ${GOPATH}
# additional go tools (godoc, guru, gorename, etc)
export PATH=${PATH}:${GOROOT}/bin
go get -u golang.org/x/tools/cmd/...
# auto-completion daemon for go (needed by emacs go-mode)
go get -u github.com/nsf/gocode
# locates symbol definitions in go code (needed by emacs go-mode)
go get -u github.com/rogpeppe/godef

# dep (Go dependency management)
GODEP_VERSION=v0.3.2
if ! dep version | grep ${GO_VERSION}; then
    sudo wget https://github.com/golang/dep/releases/download/${GODEP_VERSION}/dep-linux-amd64 -O /tmp/dep
    sudo chmod +x /tmp/dep
    sudo mv /tmp/dep /usr/local/bin/dep
fi

# nodejs (https://nodejs.org/en/download/package-manager)
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g grunt-cli

# Rust
sudo apt-get install -y rustc cargo rust-src rust-gdb

#
# cloud utilities
#
sudo pip3 install awscli

sudo apt-get install -qy \
     python-novaclient \
     python-neutronclient \
     python-glanceclient \
     python-keystoneclient \
     python-openstackclient

# Azure CLI
sudo apt-get install -qy azure-cli

# Google Cloud's gcloud cli
sudo apt-get install -qy google-cloud-sdk

# Terraform
TERRAFORM_VERSION=0.11.2
if ! terraform version | head -1 | grep ${TERRAFORM_VERSION}; then
    sudo wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo unzip -o /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /opt/terraform-${TERRAFORM_VERSION}
    sudo ln -sfn /opt/terraform-${TERRAFORM_VERSION}/terraform /opt/bin/terraform
    sudo rm /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
fi

# Ansible
sudo apt-get install ansible -qy

#
# Other ...
#
# generate swedish locale
sudo locale-gen sv_SE

#
# Skype
#
sudo wget https://go.skype.com/skypeforlinux-64.deb -O /tmp/skype.deb
sudo dpkg -i /tmp/skype.deb
sudo rm /tmp/skype.deb

#
# Slack
#
SLACK_VERSION=2.5.2
if ! slack --version | grep ${SLACK_VERSION}; then
    sudo wget https://downloads.slack-edge.com/linux_releases/slack-desktop-${SLACK_VERSION}-amd64.deb -O /tmp/slack.deb
    sudo apt-get install -qy libappindicator1 libindicator7
    sudo dpkg -i /tmp/slack.deb
    sudo rm /tmp/slack.deb
fi


#
# kubectl
#
curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /tmp/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/kubectl


#
# backups to S3 and/or google drive
#
sudo apt-get install -yy \
     duplicity python-boto
sudo pip2 install PyDrive

#
# rclone
#
RCLONE_VERSION=1.38
if ! rclone --version | grep ${RCLONE_VERSION}; then
    sudo wget https://downloads.rclone.org/rclone-v${RCLONE_VERSION}-linux-amd64.zip -O /opt/rclone.zip
    sudo unzip -d /opt/ -o /opt/rclone.zip
    sudo rm -f /opt/rclone.zip
    sudo ln -sfn /opt/rclone-v${RCLONE_VERSION}-linux-amd64/rclone /opt/bin/rclone
fi

#
# CloudFlare's SSL tools
#
sudo curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
sudo curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
sudo chmod +x /usr/local/bin/cfssl*


echo "[${scriptname}] completed successfully."
