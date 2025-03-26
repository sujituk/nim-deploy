#!/bin/sh

UTIL_DIR=/tmp/k8s-exec-token-plugin
mkdir -p "$UTIL_DIR"

alias curl="./redist/curl/curl"
alias jq="./redist/jq/jq"

if ! which gke-gcloud-auth-plugin >/dev/null; then
	RESULT="$(curl -s -X GET -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token")"
	ACCESS_TOKEN="$(echo $RESULT | jq -r ".access_token")"
	EXPIRES_IN="$(echo $RESULT | jq -r ".expires_in")"
	DATE_NOW="$(date +%s)"
	EXPIRES_AT="$(expr $DATE_NOW + $EXPIRES_IN)"
	EXPIRATION_TIMESTAMP="$(date -d@$EXPIRES_AT --utc +%Y-%m-%dT%H:%M:%SZ)"

	cat <<EOF
{
    "kind": "ExecCredential",
    "apiVersion": "client.authentication.k8s.io/v1beta1",
    "spec": {
        "interactive": false
    },
    "status": {
        "expirationTimestamp": "$EXPIRATION_TIMESTAMP",
        "token": "$ACCESS_TOKEN"
    }
}
EOF
else
	gke-gcloud-auth-plugin
fi
