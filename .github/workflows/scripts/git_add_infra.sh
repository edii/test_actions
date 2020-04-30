#!/usr/bin/env bash

# chmod u+x scripts/git_add_infra.sh
set -o errexit

GIT_REPOSITORY="edenlabllc/heals.infra"
#GIT_USER_EMAIL="edii87shadow@gmail.com"
#GIT_USER_NAME="edii"

if [[  -z "${COMMIT_MSG}" ]]; then
  MSG="Release Bot: manifest"
else
  MSG="${COMMIT_MSG}"
fi

echo "Start add new ReakiseHelm of Flux..."
echo "\n[${BRANCH_NAME}_$SHA]::(${MSG})."

if [[  -z "${BRANCH_NAME}" ]]; then
  echo "\nBRANCH_NAME can not be empty!"
  exit 1
fi

if [[  -z "${SHA}" ]]; then
  echo "\nSHA can not be empty!"
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
git config --global user.email "edii87shadow@gmail.com"
git config --global user.name "edii"

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

RELEASE_DIR=dev-${BRANCH}
RELEASE_FILE_NAME=heals-tetris-${BRANCH}-api.yaml
RELEASE_PATCH=./${RELEASE_DIR}/${RELEASE_FILE_NAME}

if [ ! -d ./${RELEASE_DIR} ]; then
    mkdir ./${RELEASE_DIR}
fi

# check and remove file
if [ -f ./${RELEASE_PATCH} ]; then
    echo "\nFile check exists and remove [${RELEASE_PATCH}]..."
    rm -f ./${RELEASE_PATCH}
fi

if [ ! -f ./${RELEASE_PATCH} ]; then
  echo -e "\nGenerating a ${RELEASE_PATCH} file"

  # Generate the file
  cat > ./${RELEASE_PATCH} <<EOL
---
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: tetris-${BRANCH}
  namespace: dev
  annotations:
    fluxcd.io/automated: "true"
    filter.fluxcd.io/chart-image: global:${BRANCH}_${SHA}
spec:
  releaseName: heals-tetris-${BRANCH}-scheduler
  chart:
    git: ssh://git@github.com/edenlabllc/heals.infra
    ref: master
    path: k8s/tetris-api-scheduler
  values:
    replicaCount: 1
    image:
      repository: 437202414690.dkr.ecr.eu-north-1.amazonaws.com/heals.tetris.api
      tag: ${BRANCH}_${SHA}
      pullPolicy: IfNotPresent
    imagePullSecrets: []
    nameOverride: ""
    fullnameOverride: "tetris-${BRANCH}"
    serviceAccount:
      create: true
      annotations: {}
      name:
    podSecurityContext: {}
    securityContext: {}
    service:
      type: ClusterIP
      port: 80
    ingress:
      enabled: true
      headers:
        enabled: true
        route: "${BRANCH}"
      auth: false
      host: "dev.heals.edenlab.tech"
      annotations: {}
    resources:
      limits:
        cpu: 1000m
        memory: 1280Mi
      requests:
        cpu: 100m
        memory: 128Mi
    nodeSelector: {}
    tolerations: []
    affinity: {}
    mongodb:
      url: "mongodb://tetris_development:4%25jvrK%26pq6.KthbEN77wv.R8n9h7t8tBY8C%5BD%25%2C6uF%28%5DfmJW%5Bu@mongodb-client-lb.mongodb.svc.cluster.local:27017/tetris_development?replicaSet=rs0"
    mysql:
      hostname: "heals-uat-db.mysql.database.azure.com"
      username: "healsuser01@heals-uat-db"
      password: "healscn@2019"
      dbname: "heals"
    redis:
      url: "redis-master.redis.svc.cluster.local"
      db: "0"
      cron_queue_name: "cron_dev"
    fhir:
      api:
        url: "http://fhir-api.dev.svc.cluster.local"
    cms:
      api:
        url: "http://api-uat.healshealthcare.com/internal"
    tracing:
      JAEGER_ENDPOINT: http://jaeger-dev-collector.observability.svc.cluster.local:14268/api/traces
    id_namespaces:
      LOCATION_NAMESPACE: 9f04a0b1-e10a-4121-b3bc-bb7156cb35cc
      ORGANIZATION_NAMESPACE: e53f3d57-5277-404e-8f59-40fd30093f02
      ORGANIZATION_INSURER_NAMESPACE: 14b0586f-1e18-4070-bcc3-51b061784390 s
      HEALTHCARE_SERVICE_NAMESPACE: a3ed6828-88c6-449f-9ea8-c840ddca85cf
      LOCATION_DISTRICT_NAMESPACE: b914e1aa-10b8-4f3f-888a-bdc74d7ac10c
      LOCATION_REGION_NAMESPACE: ea96207e-64ac-4247-976d-3a9857ce357f
      LOCATION_AREA_NAMESPACE: 0fbd9311-8ad7-4551-90e4-1a2a3e1adaba
      LOCATION_CITY_NAMESPACE: 6c486bce-1bd3-453b-91fc-bb6c8e08dc46
      PRACTITIONER_NAMESPACE: a70f5ddc-b124-4e48-a61c-c4189216784a
      PRACTITIONER_ROLE_NAMESPACE: 46f8eb56-75f4-4642-8bc0-65e206b740b1
      SCHEDULE_NAMESPACE: 2c6a8aac-be05-424d-bbbd-c5134b46a91a
      GROUP_NAMESPACE: 8aca7688-9699-4f67-8525-c936e003dc49
EOL
fi

function gitPush() {
    git add .
    git commit -a -m "$1"
    git merge-n-push
}

gitPush "${MSG}"