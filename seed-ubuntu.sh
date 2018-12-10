#!/bin/bash

#
# Installation script to set up an Ubuntu system with XFCE as dektop
# environment.
#
# The installer assumes that sudo is installed and that the user running the
# script (not root) is a sudoer.
#
# NOTE: after first execution, you should reboot to let all changes take effect.
#       When starting out from a pure Ubuntu distro, you may need to re-run
#          ~/dotfiles/setup-xfce4-keyboard-shortcuts.sh
#       after first boot to make shortcuts take effect.
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
sudo apt-get install -y snapd
sudo apt-get install -y wmctrl xdotool xsel
sudo apt-get install -y gparted sshfs
sudo apt-get install -y htop iftop bmon iperf sysstat powertop
sudo apt-get install -y chromium-browser
sudo apt-get install -y inkscape gimp gpick gnuplot
sudo apt-get install -y openssh-server pwgen
sudo apt-get install -y tree
sudo apt-get install -y jq
sudo apt-get install -y git gitg tig subversion meld
sudo apt-get install -y tmux
# ag code search tool
sudo apt-get install -y silversearcher-ag
# GNU Global source tagging system (gtags creates tag files for use with emacs)
sudo apt-get install -y global
sudo apt-get install -y emacs25 markdown dos2unix
sudo apt-get install -y pass

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
sudo apt-get install -y xfce4-pulseaudio-plugin
# generate swedish locale
sudo locale-gen sv_SE
# if we're on regular ubuntu, delete its default desktop environment
sudo apt-get remove ubuntu-desktop -y && sudo apt-get autoremove -y


#
# Add package repositories
#

# enable Canoncial Partners sources. Software Updates > Other sofware.
sudo tee /etc/apt/sources.list.d/canonical-partners.list > /dev/null <<EOF
deb http://archive.canonical.com/ubuntu $(lsb_release -cs) partner
deb-src http://archive.canonical.com/ubuntu $(lsb_release -cs) partner
EOF

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
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null <<EOF
deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main
EOF


# Ansible
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 93C4A3FD7BB9C367
sudo tee /etc/apt/sources.list.d/ansible.list > /dev/null <<EOF
deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main
EOF

# BCC - Tools for BPF-based Linux IO analysis, networking, monitoring, and more
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4052245BD4284CDD
sudo tee /etc/apt/sources.list.d/iovisor.list <<EOF
deb https://repo.iovisor.org/apt/xenial xenial main
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
sudo snap install spotify
sudo apt-get install -y vlc


#
# Install dev tools
#

# visual studio code
sudo apt-get install -y code
~/dotfiles/vscode/install-extensions.sh

sudo apt-get install -y visualvm
sudo apt-get install -y httperf

# virtualbox
sudo apt-get install -y virtualbox

# vagrant
sudo apt-get install -y vagrant

#
# install KVM, libvirt, virsh and virt-manager
#
sudo apt-get install -y qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker virt-manager
# install dependencies of vagrant-libvirt
sudo apt-get install -y ruby-libvirt qemu libvirt-bin ebtables dnsmasq libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev
# make sure regular users can create VMs
sudo sed -i 's/unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0777"/g' /etc/libvirt/libvirtd.conf
sudo systemctl restart libvirtd
# install libvirt provider for vagrant
if ! vagrant plugin list | grep vagrant-libvirt > /dev/null; then
    vagrant plugin install vagrant-libvirt
fi


# OpenJDK java
# NOTE: temporary workaround until the openjdk-11-jdk package is upgraded
#       from openjdk 10 to 11
wget https://download.java.net/java/GA/jdk11/13/GPL/openjdk-11.0.1_linux-x64_bin.tar.gz -O /tmp/openjdk-11.0.1_linux-x64_bin.tar.gz
sudo rm -rf /opt/jdk-11.0.1
sudo tar xzvf /tmp/openjdk-11.0.1_linux-x64_bin.tar.gz -C /opt/
JAVA_HOME=/opt/jdk-11.0.1
# sudo apt-get install -y openjdk-11-jdk openjdk-11-source
# JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
sudo ln -sfn ${JAVA_HOME} /opt/java
sudo ln -sfn ${JAVA_HOME}/bin/java /opt/bin/java


# python
sudo apt-get install -y \
     build-essential libssl-dev libffi-dev \
     python python-dev python-pip python-virtualenv \
     python3 python3-dev python3-pip python3-venv
sudo pip2 install ipython pipenv
sudo pip3 install ipython pipenv

sudo mkdir -p /opt

# maven
sudo apt-get install -y maven

# gradle
GRADLE_VERSION=4.5.1
if ! gradle -v | grep ${GRADLE_VERSION}; then
    wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -O /tmp/gradle-${GRADLE_VERSION}-bin.zip
    pushd /tmp/ > /dev/null
    unzip -o gradle-${GRADLE_VERSION}-bin.zip
    sudo rm -rf /opt/gradle-${GRADLE_VERSION}
    sudo mv gradle-${GRADLE_VERSION} /opt/
    sudo ln -sfn /opt/gradle-${GRADLE_VERSION}/bin/gradle /opt/bin/gradle
    popd > /dev/null
fi

# eclipse
ECLIPSE_VERSION="2018-09"
if ! [ -d /opt/eclipse-${ECLIPSE_VERSION} ]; then
    curl -fsSL https://ftp.acc.umu.se/mirror/eclipse.org/technology/epp/downloads/release/${ECLIPSE_VERSION}/R/eclipse-java-${ECLIPSE_VERSION}-linux-gtk-x86_64.tar.gz -o /tmp/eclipse-${ECLIPSE_VERSION}.tar.gz
    mkdir -p /tmp/eclipse-${ECLIPSE_VERSION}
    tar xf /tmp/eclipse-${ECLIPSE_VERSION}.tar.gz -C /tmp/eclipse-${ECLIPSE_VERSION}
    sudo mv /tmp/eclipse-${ECLIPSE_VERSION}/eclipse /opt/eclipse-${ECLIPSE_VERSION}
    sudo chown -R root:root /opt/eclipse-${ECLIPSE_VERSION}
    sudo ln -sfn /opt/eclipse-${ECLIPSE_VERSION} /opt/eclipse
    sudo ln -sfn /opt/eclipse/eclipse /opt/bin/eclipse
fi


#
# Docker
#

# install Docker and some other utilities
sudo apt-get install -y docker-ce docker-compose
# To be able to use docker without sudo/root privileges, you need to add users to the docker group.
sudo usermod --append --groups docker $(whoami)

# Go
GO_VERSION=1.11
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
go get golang.org/x/tools/cmd/...
# auto-completion daemon for go (needed by emacs go-mode)
go get github.com/nsf/gocode
# locates symbol definitions in go code (needed by emacs go-mode)
go get github.com/rogpeppe/godef
# versioned go (vgo): prototype
go get golang.org/x/vgo
# go server implementing the language server protocol (LSP), needed by emacs
go get -u github.com/sourcegraph/go-langserver

# dep (Go dependency management)
GODEP_VERSION=v0.4.1
if ! dep version | grep ${GODEP_VERSION}; then
    sudo curl -fsSL https://github.com/golang/dep/releases/download/${GODEP_VERSION}/dep-linux-amd64 -o /opt/bin/dep
    sudo chmod +x /opt/bin/dep
fi

# nodejs (https://nodejs.org/en/download/package-manager)
curl -fsSL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs gulp
sudo npm install -g grunt-cli

#
# Rust
#

# installs rustup, rustc, cargo and friends under ~/.cargo/bin/
# be sure to add this directory to your PATH
curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
# install rustup toolchains
rustup install stable nightly
# needed by emacs
rustup component add --toolchain=stable rls-preview rustfmt-preview rust-analysis rust-src
rustup component add --toolchain=nightly rls-preview rustfmt-preview rust-analysis rust-src
rustup update

#
# C++
#
sudo apt-get install -y clang
sudo apt-get install -y cmake
# ccls C/C++ server implementing the Language Server Protocol (LSP) (used
# by emacs). needs to be built from source with right version/tag.
sudo apt-get install -y zlib1g-dev ncurses-dev
if ! [ -d /opt/ccls ]; then
    sudo git clone --recursive https://github.com/MaskRay/ccls /opt/ccls
    sudo chown -R $(id -u):$(id -g) /opt/ccls
fi
pushd /opt/ccls/ > /dev/null
git fetch
CCLS_TAG=0.20181111
if ! /opt/bin/ccls --version 2>&1 > /dev/null; then
    git checkout -b ${CCLS_TAG} tags/${CCLS_TAG}
    cmake -H. -BRelease && cmake --build Release
    sudo ln -sfn /opt/ccls/Release/ccls /opt/bin/ccls
fi
popd > /dev/null

#
# BCC - Tools for BPF-based Linux IO analysis, networking, monitoring, and more
#
sudo apt-get install -y bcc-tools libbcc-examples linux-headers-$(uname -r)
for tool in $(find /usr/share/bcc/tools/ -maxdepth 1 -type f); do
    sudo ln -sfn ${tool} /opt/bin/$(basename ${tool})
done

#
# cloud utilities
#

sudo apt-get install -y \
     python-novaclient \
     python-neutronclient \
     python-glanceclient \
     python-keystoneclient \
     python-openstackclient

# Amazon's aws command-line client
sudo apt-get install -y awscli
# aws-iam-authenticator: needed to authenticate against EKS clusters
go get -u -v github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator

# Azure's az command-line client
sudo apt-get install -y azure-cli

# Google Cloud's gcloud cli
sudo snap install google-cloud-sdk --classic

# Terraform
TERRAFORM_VERSION=0.11.10
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
sudo snap install skype --classic

#
# Slack
#
sudo snap install slack --classic


#
# kubectl
#
sudo curl -fsSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /opt/bin/kubectl
sudo chmod +x /opt/bin/kubectl
mkdir -p ~/.kube

#
# kops - Kubernetes Operations
#
KOPS_VERSION=1.10.0
if ! kops version | grep "Version ${KOPS_VERSION}" > /dev/null 2>&1; then
    sudo curl -fsSL -o /opt/bin/kops https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64
    sudo chmod +x /opt/bin/kops
fi

#
# Helm (Kubernetes package manager)
#
sudo snap install helm --classic

#
# backups to S3 and/or google drive
#
sudo apt-get install -y duplicity python-boto
sudo pip2 install PyDrive

#
# rclone
#
sudo apt-get install -y rclone

#
# CloudFlare's SSL tools
#
sudo apt-get install -y golang-cfssl

#
# IntelliJ
#
sudo snap install intellij-idea-community --classic

# LaTeX
sudo apt-get install -y texlive-latex-base texlive-latex-extra

log "completed successfully."
