#!/usr/bin/env bash

set -euo pipefail

# Target GitHub repo CRD directory
GITHUB_REPO="https://github.com/argoproj/argo-cd"
RAW_BASE="https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds"
TARGET_DIR="crds"

# Create the local crds directory if it doesn't exist
mkdir -p "${TARGET_DIR}"
cd "${TARGET_DIR}"

# Get the list of *-crd.yaml files from GitHub API
echo "Fetching file list from GitHub..."
FILES=$(curl -s "https://api.github.com/repos/argoproj/argo-cd/contents/manifests/crds" \
  | grep '"name":' \
  | grep '\-crd\.yaml' \
  | cut -d '"' -f 4)

if [ -z "$FILES" ]; then
  echo "No CRD files found. Exiting."
  exit 1
fi

echo "Found CRD files:"
echo "$FILES"

# Download each CRD file
for file in $FILES; do
  echo "Downloading $file..."
  curl -sSfLO "${RAW_BASE}/${file}"
done

echo "All CRD files downloaded to $(pwd)"