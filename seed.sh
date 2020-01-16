#!/bin/bash

set -e

function die_with_error() {
    echo "error: ${1}"
    exit 1
}

function print_usage() {
    echo "usage: $(basename ${0}) --desktop|--laptop"
}

if [ "$(id -u)" = "0" ]; then
    die_with_error "don't run as root"
fi

type=""
for arg in ${@}; do
    case ${arg} in
        --laptop)
            type=laptop
            ;;
        --desktop)
            type=desktop
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            # unrecognized option/argument, assume we are to pass the rest of
            # the arguments to ansible
            break
            ;;
    esac
    shift
done

if [ -z "${type}" ]; then
    die_with_error "no type specified: either --desktop or --laptop"
fi

if [ "${type}" = "laptop" ]; then
    ansible-playbook -i laptop.inventory --ask-become-pass seed.yaml $@
else
    ansible-playbook -i desktop.inventory --ask-become-pass seed.yaml $@
fi
