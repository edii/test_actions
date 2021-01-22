#!/usr/bin/env bash

# chmod u+x scripts/git_add_infra.sh
set -o errexit

## Install yq
# If we fail for any reason a message will be displayed
die() {
	msg="$*"
	echo "ERROR: $msg" >&2
	exit 1
}

helpFunction()
{
   echo ""
   echo "Usage: $0 -n number_version -l lambda_name"
   echo -e "\t-n Description of number version saved in lambda"
   echo -e "\t-l Description of name lambda"
   exit 1 # Exit script after printing help
}

while getopts "n:l:" opt
do
   case "$opt" in
      n ) lambdaNumber="$OPTARG"
      ;;
      l ) lambdaName="$OPTARG"
      ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$lambdaName" ] | [ -z "$lambdaNumber" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

echo "Set params: lambdaName = $lambdaName lambdaNumber = $lambdaNumber"

if [[  -z "${AWS_REGION}" ]]; then
  echo "Some default value because AWS_REGION is undefined."
  exit 1
else
  AWS_REGION="${AWS_REGION}"
fi

if [[  -z "${AWS_ACCESS_KEY_ID}" ]]; then
  echo "Some default value because AWS_ACCESS_KEY_ID is undefined."
  exit 1
else
  AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
fi

if [[  -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
  echo "Some default value because AWS_SECRET_ACCESS_KEY is undefined."
  exit 1
else
  AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
fi

echo "AWS_REGION=$AWS_REGION AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"

echo "Done."
