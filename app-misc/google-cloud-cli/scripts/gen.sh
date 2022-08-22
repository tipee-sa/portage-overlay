#!/bin/bash

set -eo pipefail
cd "$(dirname $0)"

components_json="$(curl -s https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json)"

version="$(echo "$components_json" | jq .version -r)"
if [ -f ../google-cloud-cli-$version*.ebuild ]; then
	echo "Skippping: no new version" >&2
	exit 1
fi

echo $version

components=($(echo "$components_json" | jq '.components[] | select(.id == "alpha" or .id == "beta") | .data.source' -r))
gkeauth="$(echo "$components_json" | jq '.components[] | select(.id == "gke-gcloud-auth-plugin-linux-x86_64") | .data.source' -r)"

ALPHA_URI="${components[0]}" \
BETA_URI="${components[1]}" \
GKEAUTH_URI="${gkeauth}" \
envsubst '$ALPHA_URI,$BETA_URI,$GKEAUTH_URI' < google-cloud-cli.ebuild > "../google-cloud-cli-$version.ebuild"
