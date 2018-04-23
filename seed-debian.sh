#!/bin/bash

#
# Installation script to set up a Debian system with XFCE as dektop environment.
#
# The installer assumes that sudo is installed and that the user running the
# script (not root) is a sudoer.
#
# It has been tried out against clean network install setups (e.g.,
# debian-9.4.0-amd64-netinst.iso or firmware-9.4.0-amd64-netinst.iso) with
# "XFCE desktop environment", "print server", and "standard system utilities"
# installed.
#
# NOTE: after first execution, you should reboot to let all changes take effect.
#
#

set -e

scriptname=$(basename ${0})

function log() {
    msg=${1}
    echo -e "\e[32m[${scriptname}] ${msg}\e[0m"
}

function print_usage() {
    echo "usage: ${scriptname} [--laptop-mode=false] [--minimal=false]"
    echo
    echo "Installs a baseline of software and sets up dotfiles."
    echo
    echo "  --laptop-mode=BOOL   Set to true to install laptop-mode-tools."
    echo "  --minimal=BOOL       Set to true to stop after installing a desktop"
    echo "                       environment and basic utilities."
}

function die_with_error() {
    echo "error: $1" 2>&1
    echo
    print_usage
    exit 1
}

if [ "$(whoami)" = "root" ]; then
    die_with_error "please do not run this script as root"
    exit 1
fi

LAPTOP_MODE=false
MINIMAL=false

for arg in "${@}"; do
    case ${arg} in
	--laptop-mode=*)
	    LAPTOP_MODE=${arg/*=/}
	    ;;
	--minimal=*)
	    MINIMAL=${arg/*=/}
	    ;;	
	--help)
	    print_usage
	    exit 0
	    ;;
	*)
	    die_with_error "unknown argument: ${arg}"
	    ;;
    esac
done

log "running with laptop-mode: ${LAPTOP_MODE}"
log "running with minimal: ${MINIMAL}"


sudo mkdir -p /opt/bin
# scratch area: for data of temporary nature (but not being cleared
# on reboots like /tmp) and recreatable/non-precious data
sudo mkdir -p /scratch
sudo chmod 777 /scratch

export DEBIAN_FRONTEND=noninteractive

#
# install package management tools
#
sudo apt-get update -y
sudo apt-get install -y \
  apt-transport-https \
  software-properties-common \
  aptitude \
  debconf-utils \
  curl \
  dirmngr \
  bash-completion

#
# for laptops
#
if [ "${LAPTOP_MODE}" = "true" ]; then
    sudo apt-get install -y laptop-mode-tools
fi

#
# Install basic tools
#
sudo apt-get update -y
sudo apt-get install -y wmctrl xdotool xsel
sudo apt-get install -y emacs24 markdown dos2unix
sudo apt-get install -y gparted sshfs
sudo apt-get install -y htop iftop bmon iperf
sudo apt-get install -y chromium
sudo apt-get install -y inkscape gimp gcolor2 gnuplot
sudo apt-get install -y openssh-server pwgen
sudo apt-get install -y tree
sudo apt-get install -y jq
sudo apt-get install -y git gitg tig subversion meld
sudo apt-get install -y screen


#
# install XFCE
#
sudo apt-get install -y xfce4 xfce4-goodies
# disable per-user saved sessions: try to set property to false. if it doesn't
# already exist, create and set to false.
if ! xfconf-query -c xfce4-session -p /general/SaveOnExit -t bool -s false; then
    xfconf-query -c xfce4-session -p /general/SaveOnExit -n -t bool -s false
fi
# prevent xfce from saving any sessions
mkdir -p ~/.cache/sessions/  # needed for first run of script
rm -rf ~/.cache/sessions/* && chmod 500 ~/.cache/sessions
# additional fonts
sudo apt-get install -y fonts-dejavu fonts-noto
# notify-send
sudo apt-get install -y libnotify-bin
sudo apt-get install -y greybird-gtk-theme
# generate swedish locale
sudo locale-gen sv_SE


#
# Add package repositories
#

# Docker
os=$(. /etc/os-release; echo "$ID")
curl -fsSL https://download.docker.com/linux/${os}/gpg | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=amd64] https://download.docker.com/linux/${os} $(lsb_release -cs) stable
EOF

# visual studio code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
sudo mv /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null <<EOF
deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main
EOF

# Azure cli
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null <<EOF
deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main
EOF

# Google Cloud's gcloud cli
CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -cs)"
sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null <<EOF
deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main
EOF
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Ansible
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
sudo tee /etc/apt/sources.list.d/ansible.list > /dev/null <<EOF
deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main
EOF

# spotify
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410
sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null <<EOF
deb http://repository.spotify.com stable non-free
EOF

# virtualbox
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null <<EOF
deb https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib
EOF

# load packages from added repos
sudo apt-get update -y

#
# Dotfiles: shell/editor settings
#

if ! [ -d ~/dotfiles ]; then
    cd ~ && git clone --recursive https://github.com/petergardfjall/dotfiles.git
else
    cd ~/dotfiles && git pull
fi

# xfce config
~/dotfiles/setup-xfce4.sh

# emacs settings
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

# extra .bashrc modules
if ! grep 'source ~/dotfiles/bash.includes' ~/.bashrc; then
    tee -a ~/.bashrc > /dev/null <<EOF
#
# source additional configuration modules
#
source ~/dotfiles/bash.includes
EOF
fi

# extra .profile modules
if ! grep 'source ~/dotfiles/bash.includes' ~/.profile; then
    tee -a ~/.profile > /dev/null <<EOF
#
# source additional configuration modules
#
source ~/dotfiles/bash.includes
EOF
fi

# set up screen config
ln -sfn ~/dotfiles/screen/screenrc ~/.screenrc

#
# Install useful helper scripts
#
mkdir -p ~/bin
if ! [ -d ~/bin/scripts ]; then
    cd ~/bin && git clone https://github.com/petergardfjall/scripts
else
    cd ~/bin/scripts && git pull origin master
fi

#
# End installation if run with --minimal
#
if [ "${MINIMAL}" = "true" ]; then
    log "minimal install completed successfully."
    exit 0
fi


#
# Media
#
sudo apt-get install -y spotify-client


#
# Install dev tools
#

# visual studio code
sudo apt-get install -y code
~/dotfiles/vscode/install-extensions.sh

sudo apt-get install -y visualvm
sudo apt-get install -y httperf

# virtualbox
VIRTUALBOX_VERSION=5.2
sudo apt-get install -y virtualbox-${VIRTUALBOX_VERSION} dkms

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
sudo ln -sfn ${JAVA_HOME}/bin/java /opt/bin/java

# python
sudo apt-get install -y \
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
    sudo ln -sfn /opt/apache-maven-${MAVEN_VERSION}/bin/mvn /opt/bin/mvn
    sudo rm /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz
fi

# gradle
GRADLE_VERSION=4.5.1
if ! gradle -v | grep ${GRADLE_VERSION}; then
    wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -O /tmp/gradle-${GRADLE_VERSION}-bin.zip
    pushd /tmp/ > /dev/null
    unzip -o gradle-${GRADLE_VERSION}-bin.zip
    sudo mv gradle-${GRADLE_VERSION} /opt/gradle-${GRADLE_VERSION}
    sudo ln -sfn /opt/gradle-${GRADLE_VERSION}/bin/gradle /opt/bin/gradle
    popd > /dev/null
fi

# eclipse
ECLIPSE_MAJOR_V=oxygen
ECLIPSE_MINOR_V=2
if ! [ -d /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V} ]; then
    sudo wget http://ftp.acc.umu.se/mirror/eclipse.org/technology/epp/downloads/release/${ECLIPSE_MAJOR_V}/${ECLIPSE_MINOR_V}/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz -O /opt/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz
    sudo mkdir -p /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}
    sudo tar xzvf /opt/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz -C /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}
    sudo ln -sfn /opt/eclipse-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}/eclipse /opt/eclipse
    sudo ln -sfn /opt/eclipse/eclipse /opt/bin/eclipse
    sudo rm /opt/eclipse-java-${ECLIPSE_MAJOR_V}-${ECLIPSE_MINOR_V}-linux-gtk-x86_64.tar.gz
fi

#
# Docker
#

# install Docker and some other utilities
sudo apt-get install -y docker-ce
# To be able to use docker without sudo/root privileges, you need to add users to the docker group.
sudo usermod --append --groups docker $(whoami)

# install docker-compose
docker_compose_version=1.18.0
if ! docker-compose version | head -1 | grep ${docker_compose_version}; then
    sudo curl -fsSL https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose > /dev/null
    sudo chmod +x /usr/local/bin/docker-compose
fi


# Go
GO_VERSION=1.10
if ! go version | grep ${GO_VERSION}; then
    sudo wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go-${GO_VERSION}.tar.gz
    sudo tar xvf /tmp/go-${GO_VERSION}.tar.gz -C /tmp/
    sudo mv /tmp/go /opt/go-${GO_VERSION}
    sudo ln -sfn /opt/go-${GO_VERSION} /opt/go
    sudo ln -sfn /opt/go-${GO_VERSION}/bin/go /opt/bin/go
    sudo rm /tmp/go-${GO_VERSION}.tar.gz
fi
export GOROOT=/opt/go
export GOPATH=~/dev/go

# Go development environment tools
mkdir -p ${GOPATH}
# additional go tools (godoc, guru, gorename, etc)
export PATH=${PATH}:${GOROOT}/bin
go get -u golang.org/x/tools/cmd/...
# auto-completion daemon for go (needed by emacs go-mode)
go get -u github.com/nsf/gocode
# locates symbol definitions in go code (needed by emacs go-mode)
go get -u github.com/rogpeppe/godef
# versioned go (vgo): prototype
go get -u golang.org/x/vgo

# dep (Go dependency management)
GODEP_VERSION=v0.4.1
if ! dep version | grep ${GO_VERSION}; then
    sudo wget https://github.com/golang/dep/releases/download/${GODEP_VERSION}/dep-linux-amd64 -O /tmp/dep
    sudo chmod +x /tmp/dep
    sudo mv /tmp/dep /usr/local/bin/dep
fi

# nodejs (https://nodejs.org/en/download/package-manager)
curl -fsSL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g grunt-cli

#
# Rust
#

# installs rustup, rustc, cargo and friends under ~/.cargo/bin/
# be sure to add this directory to your PATH
curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path

#
# cloud utilities
#
sudo pip3 install awscli

sudo apt-get install -y \
     python-novaclient \
     python-neutronclient \
     python-glanceclient \
     python-keystoneclient \
     python-openstackclient

# Azure CLI
sudo apt-get install -y azure-cli

# Google Cloud's gcloud cli
sudo apt-get install -y google-cloud-sdk

# Terraform
TERRAFORM_VERSION=0.11.6
if ! terraform version | head -1 | grep ${TERRAFORM_VERSION}; then
    sudo wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo unzip -o /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /opt/terraform-${TERRAFORM_VERSION}
    sudo ln -sfn /opt/terraform-${TERRAFORM_VERSION}/terraform /opt/bin/terraform
    sudo rm /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
fi

# Ansible
sudo apt-get install ansible -y

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
    sudo apt-get install -y libappindicator1 libindicator7 gvfs-bin gconf2
    sudo dpkg -i /tmp/slack.deb
    sudo rm /tmp/slack.deb
fi


#
# kubectl
#
curl -fsSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /tmp/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/kubectl
mkdir -p ~/.kube

#
# backups to S3 and/or google drive
#
sudo apt-get install -y duplicity python-boto
sudo pip2 install PyDrive

#
# rclone
#
RCLONE_VERSION=1.40
if ! rclone --version | grep ${RCLONE_VERSION}; then
    sudo wget https://downloads.rclone.org/v1.40/rclone-v1.40-linux-amd64.deb -O /tmp/rclone.deb
    sudo dpkg -i /tmp/rclone.deb
fi

#
# CloudFlare's SSL tools
#
sudo curl -fsSL -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
sudo curl -fsSL -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
sudo chmod +x /usr/local/bin/cfssl*

#
# IntelliJ
#
INTELLIJ_VERSION=2017.3.4
if ! [ -d /opt/intellij-${INTELLIJ_VERSION} ]; then
    wget https://download.jetbrains.com/idea/ideaIC-${INTELLIJ_VERSION}-no-jdk.tar.gz -O /tmp/intellij.tar.gz
    mkdir -p /tmp/intellij-${INTELLIJ_VERSION}
    tar xzf /tmp/intellij.tar.gz -C /tmp/intellij-${INTELLIJ_VERSION} --strip-components=1
    sudo mv /tmp/intellij-${INTELLIJ_VERSION} /opt/

    sudo ln -sfn /opt/intellij-${INTELLIJ_VERSION}/bin/idea.sh /opt/bin/idea
    sudo rm /tmp/intellij.tar.gz
fi

# LaTeX
sudo apt-get install -y texlive-latex-base texlive-latex-extra

log "completed successfully."
