#!/usr/bin/env bash

# chmod u+x scripts/git_add_infra.sh
set -o errexit

## Install yq
# If we fail for any reason a message will be displayed
die() {
	msg="$*"
	echo "ERROR: $msg"
	exit 1
}

# Install the yq yaml query package from the mikefarah github repo
# Install via binary download, as we may not have golang installed at this point
function install_yq() {
    echo "Install YQ..."
	GOPATH=${GOPATH:-${HOME}/go}
	local yq_path="${GOPATH}/bin/yq"
	local yq_pkg="github.com/mikefarah/yq"
	[ -x  "${GOPATH}/bin/yq" ] && return

	read -r -a sysInfo <<< "$(uname -sm)"

    echo "Install: ${sysInfo[0]}...."

	case "${sysInfo[0]}" in
	"Linux" | "Darwin")
		goos="${sysInfo[0],}"
		;;
	"*")
		die "OS ${sysInfo[0]} not supported"
		;;
	esac

	case "${sysInfo[1]}" in
	"aarch64")
		goarch=arm64
		;;
	"ppc64le")
		goarch=ppc64le
		;;
	"x86_64")
		goarch=amd64
		;;
	"s390x")
		goarch=s390x
		;;
	"*")
		die "Arch ${sysInfo[1]} not supported"
		;;
	esac

	mkdir -p "${GOPATH}/bin"

	# Check curl
	if ! command -v "curl" >/dev/null; then
		die "Please install curl"
	fi

	local yq_version=3.3.0

	local yq_url="https://${yq_pkg}/releases/download/${yq_version}/yq_${goos}_${goarch}"
	curl -o "${yq_path}" -LSsf ${yq_url}
	[ $? -ne 0 ] && die "Download ${yq_url} failed"
	chmod +x ${yq_path}

	if ! command -v "${yq_path}" >/dev/null; then
		die "Cannot not get ${yq_path} executable"
	fi
}

install_yq

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
#git config --global alias.merge-n-push '!f() { git pull --no-edit && git push; }; f'
git config --global alias.rebase-n-push '!f() { git pull --rebase origin master && git push; }; f'

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

RELEASE_FILE_NAME=heals-tetris-${BRANCH}-api.yaml
RELEASE_PATCH=dev/${RELEASE_FILE_NAME}
TEMPLATE_FILE_PATCH=dev/heals-tetris-api.yaml

if [ ! -f ./${TEMPLATE_FILE_PATCH} ]; then
    echo "Not found template file [${TEMPLATE_FILE_PATCH}]."
    exit 1
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
    git rebase-n-push
}

gitPush "${MSG}"