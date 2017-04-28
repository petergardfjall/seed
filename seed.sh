#!/bin/bash

#
# Installation script to set up an Xubuntu 16.04 (Xenial) system.
#

set -e

scriptname=$(basename ${0})

function die_with_error() {
    echo $1 2>&1
    echo 
    echo "usage: ${scriptname} [--laptop-mode true]"
    echo "  --laptop-mode=BOOL     Set to true to install laptop-mode-tools."
    exit 1
}

if [ "$(whoami)" = "root" ]; then
    echo "please do not run this script as root"
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
	    die_with_error "error: unknown argument: ${arg}"
	    ;;
    esac
done

echo "running with laptop-mode: ${LAPTOP_MODE}"


sudo mkdir -p /opt/bin
sudo chmod 777 /scratch

sudo apt-get update -yy
sudo apt-get install -yy \
  apt-transport-https \
  software-properties-common \
  apt-show-versions \
  aptitude \
  debconf-utils \
  curl


# enable Canoncial Partners sources (needed for skype). Software Updates > Other sofware.
sudo sed -i 's,# \(deb http://archive.canonical.com/ubuntu [a-z]* partner\),\1,' /etc/apt/sources.list

# Docker
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo sh -c "echo deb https://apt.dockerproject.org/repo ubuntu-xenial main > /etc/apt/sources.list.d/docker.list"

# google chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# visual studio code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
sudo mv /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

# Azure cli
echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893

# Google Cloud's gcloud cli
CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
sudo echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Ansible
sudo apt-add-repository ppa:ansible/ansible -y

# spotify
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys BBEBDCB318AD50EC6865090613B00F1FD2C19886
echo deb http://repository.spotify.com testing non-free | sudo tee /etc/apt/sources.list.d/spotify.list


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
     skype skype-bin \
     spotify-client \
     code


# for laptops
if [ "${LAPTOP_MODE}" = "true" ]; then
    sudo apt-get install -y laptop-mode-tools
fi

#
# Shell/editor settings
#

# emacs settings
cd ~ && git clone https://github.com/petergardfjall/dotfiles.git
ln -s ~/dotfiles/emacs-init.el ~/.emacs

# vim settings
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
ln -s ~/dotfiles/vim/vimrc ~/.vimrc
# NOTE: on first launch of vim, run :PluginInstall to have Vundle install the plugins configured in vimrc.

# vscode settings
mkdir -p ~/.config/Code/User/
sudo ln -sfn ~/dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
sudo ln -sfn ~/dotfiles/vscode/keybindings.json ~/.config/Code/User/keybindings.json
~/dotfiles/vscode/install-extensions.sh

# xfce config
~/dotfiles/setup-xfce4.sh

# extra .bashrc modules
tee -a ~/.bashrc <<'EOF'
#
# source additional configuration modules
#
source ~/dotfiles/bash.includes
EOF

# extra .profile modules
tee -a ~/.profile <<'EOF'
#
# source additional configuration modules
#
source ~/dotfiles/bash.includes
EOF

# set up screen config
ln -s ~/dotfiles/screen/screenrc ~/.screenrc

# useful scripts
mkdir ~/bin
cd ~/bin && git clone https://github.com/petergardfjall/scripts

#
# dev
#



sudo apt-get install -yy \
     visualvm \
     httperf \
     virtualbox \
     npm

# vagrant
VAGRANT_VERSION=1.9.4
wget https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb -O /tmp/vagrant.deb
sudo dpkg -i /tmp/vagrant.deb

# OpenJDK java
sudo apt-get install -y openjdk-8-jdk openjdk-8-source
JAVA_HOME="$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")"
sudo ln -s ${JAVA_HOME} /opt/java

# python
sudo apt-get install -qy \
     build-essential \
     python python-dev python-pip python-virtualenv \
     python3 python3-dev python3-pip python3-virtualenv
sudo pip install ipython
sudo pip3 install ipython

sudo mkdir -p /opt
# maven
MAVEN_VERSION=3.3.9
sudo wget http://apache.mirrors.spacedump.net/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -O /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz
sudo tar xzvf /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt
sudo ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven
# eclipse
ECLIPSE_MAJOR_VERSION=neon
ECLIPSE_MINOR_VERSION=3
sudo wget http://ftp.acc.umu.se/mirror/eclipse.org/technology/epp/downloads/release/${ECLIPSE_MAJOR_VERSION}/${ECLIPSE_MINOR_VERSION}/eclipse-java-${ECLIPSE_MAJOR_VERSION}-${ECLIPSE_MINOR_VERSION}-linux-gtk-x86_64.tar.gz -O /opt/eclipse-java-${ECLIPSE_MAJOR_VERSION}-${ECLIPSE_MINOR_VERSION}-linux-gtk-x86_64.tar.gz
sudo mkdir /opt/eclipse-${ECLIPSE_MAJOR_VERSION}-${ECLIPSE_MINOR_VERSION}
sudo tar xzvf /opt/eclipse-java-${ECLIPSE_MAJOR_VERSION}-${ECLIPSE_MINOR_VERSION}-linux-gtk-x86_64.tar.gz -C /opt/eclipse-${ECLIPSE_MAJOR_VERSION}-${ECLIPSE_MINOR_VERSION}
sudo ln -sfn /opt/eclipse-${ECLIPSE_MAJOR_VERSION}-${ECLIPSE_MINOR_VERSION}/eclipse /opt/eclipse

# docker
docker_compose_version=1.11.2
# install Docker and some other utilities
sudo apt-get install -qy docker-engine 
# install docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
sudo chmod +x /usr/local/bin/docker-compose
# To be able to use docker without sudo/root privileges, you need to add users to the docker group.
# usermod --append --groups docker ${SOME_USER}
sudo usermod --append --groups docker peterg


# Go
GO_VERSION=1.8
sudo wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go-${GO_VERSION}.tar.gz
sudo tar xvf /tmp/go-${GO_VERSION}.tar.gz -C /tmp/
sudo mv /tmp/go /opt/go-${GO_VERSION}
sudo ln -sfn /opt/go-${GO_VERSION} /opt/go


# nodejs
sudo apt-get install nodejs npm
sudo npm install -g grunt-cli

#
# cloud utilities
#
sudo pip install awscli

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
TERRAFORM_VERSION=0.9.4
sudo wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo unzip /tmp/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /opt/terraform-${TERRAFORM_VERSION}
sudo ln -sfn /opt/terraform-${TERRAFORM_VERSION}/terraform /opt/bin/terraform

# Ansible
sudo apt-get install ansible -qy

#
# Other ...
#
# generate swedish locale
sudo locale-gen sv_SE

#
# Slack
#
SLACK_VERSION=2.5.2
sudo wget https://downloads.slack-edge.com/linux_releases/slack-desktop-${SLACK_VERSION}-amd64.deb -O /tmp/slack.deb
sudo apt-get install -qy libappindicator1 libindicator7
sudo dpkg -i /tmp/slack.deb

#
# kubectl
#
curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /tmp/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp//kubectl /usr/local/bin/kubectl
