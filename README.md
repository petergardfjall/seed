## seed
Ansible seed playbook for installing an XFCE desktop environment and a baseline
of software and [dotfiles](https://github.com/petergardfjall/dotfiles).

The script is intended to be run on an Ubuntu/Xubuntu system (tested on
`bionic`) and has been tried out on Ansible 2.9.

1. Install `git` and clone this repo:

        sudo apt-get update
        sudo apt-get install -y git

        git clone https://github.com/petergardfjall/seed
        cd seed/

2. Install `ansible`:

        sudo apt install python3-pip -y
        pip3 install --user ansible

3. Run either of (you may append additional ansible command-line flags):

         export PATH=$PATH:~/.local/bin

        ./seed.sh --desktop
        ./seed.sh --laptop
