#!/bin/bash

set -e

script="$(basename ${0})"

function die {
    echo "error: ${1}"
    exit 1
}

function log {
    echo -e "\e[32m[${script}] ${1}\e[39m"
}


build_dir=${build_dir:-/opt/emacs-src}
build_marker_prefix=".BUILT"

[ -z "${1}" ] && die "no emacs revision (tag or commit) given"

revision=${1}
build_marker="${build_marker_prefix}_${revision}"

log "ensuring emacs built from revision (tag/commit) ${revision} ..."

# clone and/or fetch
if ! [ -d "${build_dir}" ]; then
    git clone https://github.com/emacs-mirror/emacs ${build_dir}
fi

pushd ${build_dir} > /dev/null
git fetch

# remove any prior build-markers (e.g. don't want a downgrade to appear to
# already be installed)
rm -f ${build_marker_prefix}*

# assume that revision specifies a commit
rev_commit=${revision}
# see if there is a tag that matches revision. if so, we find a matching commit
tag_ref=$(git show-ref --tags | egrep " refs/tags/${revision}$" || exit 0)
if [ -n "${tag_ref}" ]; then
    rev_commit=$(echo "${tag_ref}" | awk '{print $1}')
else
    log "${revision} does not seem to refer to a tag"
fi

log "commit to build: ${rev_commit}"

# check out and build commit
build_log=${build_dir}/build.log
git checkout -B ${revision}-branch ${rev_commit}
log "building on branch ${revision}-branch (see ${build_log}) ..."

git clean -dxf  > ${build_log}  2>&1
./autogen.sh    >> ${build_log} 2>&1
./configure     >> ${build_log} 2>&1
make bootstrap  >> ${build_log} 2>&1
make            >> ${build_log} 2>&1

log "emacs binary built in ${build_dir}/src/emacs"

# create a build marker file: BUILT_${revision}
log "creating build marker ${build_marker} ..."
touch "${build_marker}"

popd > /dev/null  # build_dir
