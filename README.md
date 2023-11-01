## seed

Ansible seed playbook for installing an XFCE desktop environment and a baseline
of software and [dotfiles](https://github.com/petergardfjall/dotfiles).

The script is intended to be run on an Ubuntu/Xubuntu system (tested on
`bionic`) and has been tried out on Ansible 2.9.

1.  Install `git` and clone this repo:

    ```bash
    sudo apt-get update
    sudo apt-get install -y git

    git clone https://github.com/petergardfjall/seed
    cd seed/
    ```

2.  Install `ansible`:

    ```bash
    sudo apt install python3-pip -y
    pip3 install --user ansible
    ```

3.  Run either of (you may append additional ansible command-line flags):

    ```bash
    export PATH=$PATH:~/.local/bin

    /seed.sh --desktop
    /seed.sh --laptop
    ```

All tasks are tagged according to _category_ (like `Desktop`) and _role_ (for
example `media`) and _tool_ (for example `vlc`). By specifying tags, one can
choose to run tasks for a certain category, role or tool:

```bash
./seed.sh --laptop --tags go,gopls
```

To see available tags run:

```bash
ansible-playbook --list-tags seed.yaml`
```
