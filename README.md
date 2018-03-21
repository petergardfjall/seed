# seed
Seed script for installing an XFCE desktop environment and a baseline of
software and [dotfiles](https://github.com/petergardfjall/dotfiles).

The scripts comes in two editions depending on if a Debian or Ubuntu system is
targeted.


## Install

First, make sure that git is installed

    sudo apt update && sudo apt install git

Then clone this repository

    git clone https://github.com/petergardfjall/seed

and run [seed-ubuntu.sh](seed-ubuntu.sh) (on an Ubuntu-based system) or
[seed-debian.sh](seed-debian.sh) (on a Debian-based system):

	./seed/seed-ubuntu.sh

For laptops, run with `--laptop-mode=true`.

To only install a desktop environment and a few basic utility programs, specify
`--minimal=true`. *Note: you can always start with `--minimal=true` and later
re-run the script without the flag.*

## Idempotency
The script are written to be idempotent. Hence after an update, such as a new
version of a particular software has been introduced, the scripts should be
possible to re-run to have new software installed while keeping the old as-is.
