#!/usr/bin/env bash

. ./scripts/lib/lib.sh

# If you are looking at this file because you find yourself needing to publish a source image manually, you might not need to do all of this!
# You can do the following:
#
# # NAME="source-foo"; VERSION="1.2.3"
#
#
#
# docker buildx build . --platform "linux/amd64,linux/arm64" --tag $IMAGE_NAME:latest  --push
# docker buildx build . --platform "linux/amd64,linux/arm64" --tag $IMAGE_NAME:$VERSION  --push


USAGE="
Usage: $(basename "$0") <cmd>
For publish.
Available commands:
  publish  <integration_root_path> [<image_name>] [<image_version>] [--pre_release]
  publish_external  <image_name> <image_version>
"

_check_tag_exists() {
  DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect "$1" > /dev/null
}

_error_if_tag_exists() {
    if _check_tag_exists "$1"; then
      error "You're trying to push a version that was already released ($1). Make sure you bump it up."
    fi
}

# Experimental version of the above for a new way to build/tag images
cmd_build_experiment() {
  local path=$1; shift || error "Missing target (root path of integration) $USAGE"
  [ -d "$path" ] || error "Path must be the root path of the integration"

  echo "Building $path"

  local image_name=$1; shift || error "Missing target (<image_name>) $USAGE"
  [ ! -z "$image_name" ] || error "Not empty image_name"

  local image_version=$1; shift || error "Missing target (<image_version>) $USAGE"
  [ ! -z "$image_version" ] || error "Not empty image_version"

  local image_candidate_tag; image_candidate_tag="$image_version-candidate-$PR_NUMBER"

  if [[ "$GITHUB_JOB" == "bump-build-test-connector" ]]; then
    docker tag "$image_name:dev" "$image_name:$image_candidate_tag"
  fi
}

cmd_publish() {
  local path=$1; shift || error "Missing target (root path of integration) $USAGE"
  [ -d "$path" ] || error "Path must be the root path of the integration"

  local image_name=$1; shift || error "Missing target (<image_name>) $USAGE"
  [ ! -z "$image_name" ] || error "Not empty image_name"

  local image_version=$1; shift || error "Missing target (<image_version>) $USAGE"
  [ ! -z "$image_version" ] || error "Not empty image_version"

  local versioned_image=$image_name:$image_version
  local latest_image="$image_name" # don't include ":latest", that's assumed here
  local build_arch="linux/amd64,linux/arm64"

  # learn about this version of Docker
  echo "--- docker info ---"
  docker --version
  docker buildx version

  # log into docker
  if test -z "${DOCKER_HUB_USERNAME}"; then
    echo 'DOCKER_HUB_USERNAME not set.';
    exit 1;
  fi

  if test -z "${DOCKER_HUB_PASSWORD}"; then
    echo 'DOCKER_HUB_PASSWORD for docker user not set.';
    exit 1;
  fi

  set +x
  DOCKER_TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKER_HUB_USERNAME}'", "password": "'${DOCKER_HUB_PASSWORD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
  set -x

  echo "image_name $image_name"
  echo "versioned_image $versioned_image"
  echo "latest_image $latest_image"

  _error_if_tag_exists "$versioned_image"

  for arch in $(echo $build_arch | sed "s/,/ /g")
  do
    local arch_versioned_image=$image_name:`echo $arch | sed "s/\//-/g"`-$image_version
    echo "Publishing new version ($arch_versioned_image) from $path"
    docker buildx build -t $arch_versioned_image --platform $arch --push $path
    docker manifest create $versioned_image --amend $arch_versioned_image
    docker manifest create $latest_image --amend $arch_versioned_image
  done

  docker manifest push $versioned_image
  docker manifest rm $versioned_image

  docker manifest push $latest_image
  docker manifest rm $latest_image

  # delete the temporary image tags made with arch_versioned_image
  sleep 10
  for arch in $(echo $build_arch | sed "s/,/ /g")
  do
    local arch_versioned_tag=`echo $arch | sed "s/\//-/g"`-$image_version
    echo "deleting temporary tag: ${image_name}/tags/${arch_versioned_tag}"
    TAG_URL="https://hub.docker.com/v2/repositories/${image_name}/tags/${arch_versioned_tag}/" # trailing slash is needed!
    set +x
    curl -X DELETE -H "Authorization: JWT ${DOCKER_TOKEN}" "$TAG_URL"
    set -x
  done

  # Checking if the image was successfully registered on DockerHub
  sleep 5

  # To work for private repos we need a token as well
  TAG_URL="https://hub.docker.com/v2/repositories/${image_name}/tags/${image_version}"
  set +x
  DOCKERHUB_RESPONSE_CODE=$(curl --silent --output /dev/null --write-out "%{http_code}" -H "Authorization: JWT ${DOCKER_TOKEN}" ${TAG_URL})
  set -x
  if [[ "${DOCKERHUB_RESPONSE_CODE}" == "404" ]]; then
    error "Tag ${image_version} was not registered on DockerHub for image ${image_name}, please try to bump the version again."
  fi
}

cmd_publish_external() {
  local image_name=$1; shift || error "Missing target (image name) $USAGE"
  local image_version=$1; shift || error "Missing target (image version) $USAGE"

  echo "image $image_name:$image_version"
  echo "Publishing and writing to spec cache."
  echo "Using environment gcloud"

  publish_spec_files "$image_name" "$image_version"
}

generate_spec_file() {
  local image_name=$1; shift || error "Missing target (image name)"
  local image_version=$1; shift || error "Missing target (image version)"
  local tmp_spec_file=$1; shift || error "Missing target (temp spec file name)"
  local deployment_mode=$1; shift || error "Missing target (deployment mode)"

  docker run --env DEPLOYMENT_MODE="$deployment_mode" --rm "$image_name:$image_version" spec | \
      jq -R "fromjson? | ." | \
      jq -s "map(select(.spec != null)) | map(.spec) | first | if . != null then . else error(\"no spec found\") end" \
      > "$tmp_spec_file"
}

publish_spec_files() {
  local image_name=$1; shift || error "Missing target (image name)"
  local image_version=$1; shift || error "Missing target (image version)"

  local tmp_default_spec_file; tmp_default_spec_file=$(mktemp)
  generate_spec_file "$image_name" "$image_version" "$tmp_default_spec_file" "OSS"
}

main() {
  local cmd=$1; shift || error "Missing cmd $USAGE"
  cmd_"$cmd" "$@"
}

main "$@"
