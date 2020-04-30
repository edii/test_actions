#!/usr/bin/env bash

# chmod u+x scripts/git_add_infra.sh
set -o errexit

## Install yq
echo "Install package YQ..."
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update
sudo apt install yq -y

GIT_REPOSITORY="edii/test_repo"
GIT_USER_EMAIL="edii87shadow@gmail.com"
GIT_USER_NAME="edii"

if [[  -z "${COMMIT_MSG}" ]]; then
  MSG="Release Bot: manifest"
else
  MSG="${COMMIT_MSG}"
fi

echo "Start add new ReakiseHelm of Flux..."
echo "[${BRANCH_NAME}_$SHA]::(${MSG})."

if [[  -z "${BRANCH_NAME}" ]]; then
  echo "BRANCH_NAME can not be empty!"
  exit 1
fi

if [[  -z "${SHA}" ]]; then
  echo "SHA can not be empty!"
  exit 1
fi

if [[  -z "${GITHUB_TOKEN}" ]]; then
  echo "\nSome default value because GITHUB_TOKEN is undefined"
  exit 1
else
  GIT_TOKEN="${GITHUB_TOKEN}"
fi

## get only bransh name
#BRANCH=${BRANCH_NAME##*/}
BRANCH=$(echo ${BRANCH_NAME#refs/heads/} | sed 's/\//-/g')

# Hard-code user configuration
git config --global user.email "${GIT_USER_EMAIL}"
git config --global user.name "${GIT_USER_NAME}"

# Auto merged changed
git config --global alias.merge-n-push '!f() { git pull --no-edit && git push; }; f'

cd ~/
if [[ -d ./heals.infra ]]; then
    echo "[heals.infra] directory exists, now removed."
    rm -rf ./heals.infra
fi

mkdir heals.infra
cd ./heals.infra

echo "Git clone ${GIT_REPOSITORY}..."

echo "GITHUB_TOKEN: [${GITHUB_TOKEN}]."
git clone -b master https://_:${GIT_TOKEN}@github.com/${GIT_REPOSITORY}.git .
cd k8s/releases

RELEASE_DIR=dev-${BRANCH}
RELEASE_FILE_NAME=heals-tetris-${BRANCH}-api.yaml
RELEASE_PATCH=${RELEASE_DIR}/${RELEASE_FILE_NAME}
TEMPLATE_FILE_PATCH=dev/heals-tetris-api.yaml

if [ ! -f ./${TEMPLATE_FILE_PATCH} ]; then
    echo "Not found template file [${TEMPLATE_FILE_PATCH}]."
    exit 1
fi

if [ ! -d ./${RELEASE_DIR} ]; then
    mkdir ./${RELEASE_DIR}
fi

# check and remove file
if [ -f ./${RELEASE_PATCH} ]; then
    echo "File check exists and remove [${RELEASE_PATCH}]..."
    rm -f ./${RELEASE_PATCH}
fi

if [ ! -f ./${RELEASE_PATCH} ]; then
  echo -e "Copy file template"
  cp -f ./${TEMPLATE_FILE_PATCH} ./${RELEASE_PATCH}

  echo -e "Generating a ${RELEASE_PATCH} file"

  yq w -i ./${RELEASE_PATCH} metadata.name tetris-${BRANCH}
  yq w -i ./${RELEASE_PATCH} 'metadata.annotations."filter.fluxcd.io/chart-image"' global:${BRANCH}_${SHA}
  yq w -i ./${RELEASE_PATCH} spec.releaseName heals-tetris-${BRANCH}-scheduler
  yq w -i ./${RELEASE_PATCH} spec.values.image.tag ${BRANCH}_${SHA}
  yq w -i ./${RELEASE_PATCH} spec.values.fullnameOverride tetris-${BRANCH}
  yq w -i ./${RELEASE_PATCH} spec.values.ingress.headers.enabled true
  yq w -i ./${RELEASE_PATCH} spec.values.ingress.headers.route ${BRANCH}
fi

function gitPush() {
    git add .
    git commit -a -m "$1"
    git merge-n-push
}

gitPush "${MSG}"