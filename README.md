## seed
Ansible seed playbook for installing an XFCE desktop environment and a baseline
of software and [dotfiles](https://github.com/petergardfjall/dotfiles).

The script is intended to be run on an Ubuntu/Xubuntu system (tested on bionic)
and has been tried out on Ansible 2.5 (version from the official repo in Ubuntu
bionic at the time of writing).

1. Install `git` and clone this repo:

        sudo apt-get update
        sudo apt-get install -y git

        git clone https://github.com/petergardfjall/seed
        cd seed/

2. Install `ansible`:

        sudo apt-get install -y ansible

3. Run either of:

        ansible-playbook -i laptop.inventory --ask-become-pass seed.yaml
        ansible-playbook -i desktop.inventory --ask-become-pass seed.yaml
