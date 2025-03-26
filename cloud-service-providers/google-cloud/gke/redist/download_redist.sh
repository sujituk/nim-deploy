#!/bin/sh

CURL_VERSION=8.10.1
JQ_VERSION=1.7

wget -q "https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/curl-linux-x86_64-${CURL_VERSION}.tar.xz" -P ./curl

mkdir "./jq"
wget -q "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" -O "jq/jq"

tar xf curl/curl-linux-x86_64-${CURL_VERSION}.tar.xz -C ./curl
chmod +x curl/curl
chmod +x jq/jq

rm -r curl/curl-linux-x86_64-${CURL_VERSION}.tar.xz
