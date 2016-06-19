#!/bin/bash
cd `dirname "$0"`/..

set -e

branch="$(git symbolic-ref HEAD 2>/dev/null)"
if [ "$branch" == "refs/heads/master" ]; then
    branch=""
fi

function error_exit() {
    set +x
    echo "Error, aborting..."
    exit 1
}
trap error_exit ERR

set -x
git pull -r origin $branch

git submodule sync
git submodule update --init --recursive
