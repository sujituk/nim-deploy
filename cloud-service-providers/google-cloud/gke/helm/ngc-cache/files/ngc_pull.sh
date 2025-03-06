#!/bin/bash

set -euo pipefail

export CACHE_PATH="$NIM_CACHE_PATH"
echo "Cache path: " $CACHE_PATH
echo "NGC Bundle URL: "$NGC_BUNDLE_URL

if [ -n "${NGC_BUNDLE_URL:-}" ]; then
	# Create a sub-directory, as tar tries to modify the parent folder permissions
	echo "Entering when NGC_BUNDLE_URL is set"
	export CACHE_PATH="$NIM_CACHE_PATH/cache"
	mkdir -p "$CACHE_PATH"
	MODEL_BUNDLE_FILENAME="model.tar"
	echo "Executing aria2c"

	# Fetch and extract from the provided URL, with max concurrency
	echo "aria2c -x 16 -s 16 -j 10 --dir $CACHE_PATH --out=$MODEL_BUNDLE_FILENAME $NGC_BUNDLE_URL"

	aria2c -x 16 -s 16 -j 10 --dir "$CACHE_PATH" --out="$MODEL_BUNDLE_FILENAME" "$NGC_BUNDLE_URL"

	echo "Executed aria2c"
	echo "=== [START] Extracting $CACHE_PATH/$MODEL_BUNDLE_FILENAME ==="
	if file "$CACHE_PATH/$MODEL_BUNDLE_FILENAME" | grep -q "gzip compressed"; then
		tar -I pigz -xf "$CACHE_PATH/$MODEL_BUNDLE_FILENAME" -C "$CACHE_PATH"
	else
		tar -xf "$CACHE_PATH/$MODEL_BUNDLE_FILENAME" -C "$CACHE_PATH"
	fi
	echo "=== [DONE] Extracting $CACHE_PATH/$MODEL_BUNDLE_FILENAME ==="
	rm "$CACHE_PATH/$MODEL_BUNDLE_FILENAME"
else
	echo "Download from NGC"

	# Fetch directly from NGC to $NIM_CACHE_PATH
	download-to-cache
fi

find $CACHE_PATH -type d -printf '%P\n' | xargs -P 100 -I {} mkdir -p /upload-dir/{}
find $CACHE_PATH -type f,l -printf '%P\n' | xargs -P 100 -I {} cp --no-dereference $CACHE_PATH/{} /upload-dir/{}
