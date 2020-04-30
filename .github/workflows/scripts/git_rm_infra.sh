#!/usr/bin/env bash

# chmod u+x scripts/git_rm_infra.sh
set -o errexit

GIT_REPOSITORY="edenlabllc/heals.infra"
GIT_USER_EMAIL="noreply@edenlab.com.ua"
GIT_USER_NAME="Release Bot"

if [[  -z "${COMMIT_MSG}" ]]; then
  MSG="Release Bot: manifest"
else
  MSG="${COMMIT_MSG}"
fi

echo "Start rn ReleaseHelm of Flux..."
echo "\n[${BRANCH_NAME}]::(${MSG})."

if [[  -z "${BRANCH_NAME}" ]]; then
  echo "\nBRANCH_NAME can not be empty!"
  exit 1
fi

#if [[  -z "${GITHUB_TOKEN}" ]]; then
#  echo "\nSome default value because GITHUB_TOKEN is undefined"
#  exit 1
#else
#  GIT_TOKEN="${GITHUB_TOKEN}"
#fi

## get only bransh name
#BRANCH=${BRANCH_NAME##*/}
BRANCH=$(echo ${BRANCH_NAME#refs/heads/} | sed 's/\//-/g')

# Hard-code user configuration
git config user.email ${GIT_USER_EMAIL}
git config user.name ${GIT_USER_NAME}

# Auto merged changed
git config --global alias.merge-n-push '!f() { git pull --no-edit && git push; }; f'

cd ~/
if [[ -d ./heals.infra ]]; then
    echo "\n[heals.infra] directory exists, now removed."
    rm -rf ./heals.infra
fi

mkdir heals.infra
cd ./heals.infra

echo "\nGit clone ${GIT_REPOSITORY}..."
#git clone -b master https://_:${GIT_TOKEN}@github.com/${GIT_REPOSITORY}.git .
git clone -b master https://github.com/edii/test_repo.git .
cd k8s/releases

CURR_DIR=dev-${BRANCH}

if [ ! -d ./${CURR_DIR} ]; then
    echo "\nNot found release dir [${CURR_DIR}]"
    exit 0
else
    echo "\nRemove current release Dir [${CURR_DIR}]"
    rm -rf ./${CURR_DIR}
fi

function gitPush() {
    git add .
    git commit -a -m "$1"
    git merge-n-push
}

gitPush "${MSG}"