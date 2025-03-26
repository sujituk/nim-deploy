#!/bin/sh

TEMP_DIR="$(mktemp -d)"

alias curl="./redist/curl/curl"
alias jq="./redist/jq/jq"

if ! which gcloud >/dev/null; then
	cat <<EOF >"$TEMP_DIR/id_request.json"
{
"audience": "https://${SERVICE_FQDN}",
"includeEmail": "true"
}
EOF

	TOKEN="$(curl -s -X GET -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" | jq -r ".access_token")"

	EMAIL="$(curl -s -X GET -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email")"

	ID_TOKEN="$(curl -s -X POST \
		-H "Authorization: Bearer $TOKEN" \
		-H "Content-Type: application/json; charset=utf-8" \
		-d "@$TEMP_DIR/id_request.json" \
		"https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${EMAIL}:generateIdToken" | jq -r ".token")"

else
	ID_TOKEN="$(gcloud auth print-identity-token)"
fi

cat <<EOF >"$TEMP_DIR/req.cred.json"
{
  "bucket": "${NIM_GCS_BUCKET}",
  "text": "${NGC_EULA_TEXT}",
  "textb64": "$(echo ${NGC_EULA_TEXT} | base64 -w0)",
  "jwt": "$ID_TOKEN"
}
EOF

HTTP_URL="$(curl -s -X POST -H 'accept: application/json' -H 'Content-Type: application/json' -d "@$TEMP_DIR/req.cred.json" "https://${SERVICE_FQDN}/v1/request/${GCS_FILENAME}" | sed 's/.*\(https.*\)\\\\n.*/\1/g')"

echo -n "$HTTP_URL"
