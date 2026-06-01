#!/bin/bash

set -e
cd /mongodb

# --- Python dependencies via Poetry ---
# Poetry is pre-installed in the Docker image.
# Install only the compile and core dependency groups needed for building.
poetry install --no-root --only compile,core

# --- Install Bazel (via the project's install script) ---
python3.12 buildscripts/install_bazel.py
export PATH="$HOME/.local/bin:$PATH"

export GIT_PYTHON_REFRESH=quiet

# --- Extract version from version.json for Bazel ---
MONGO_VERSION=$(python3.12 -c "import json; print(json.load(open('version.json'))['version'])")

# --- Generate enterprise module stubs for community build ---
# The source tarball doesn't include the proprietary enterprise module, but
# some BUILD targets unconditionally reference enterprise packages. This creates
# minimal stub BUILD.bazel files so Bazel analysis succeeds.
python3.12 /generate_enterprise_stubs.py

# --- Build mongod + mongos (the "install-core" target) via Bazel ---
# bazelisk reads .bazelversion and .bazeliskrc to fetch the correct
# MongoDB-patched Bazel binary automatically.
#   --config=opt           optimized release-like build
#   --config=local         disables remote execution (MongoDB internal cluster)
#   --build_enterprise=False   community edition, no enterprise module needed
bazel build \
  //:install-core \
  --config=opt \
  --config=local \
  --build_enterprise=False \
  --define=MONGO_VERSION="$MONGO_VERSION"

# --- Strip and copy the resulting binaries to the mounted volume ---
cd bazel-bin/install-core/bin
strip mongos mongod
mkdir -p /mongodb/output/bin
cp mongod mongos /mongodb/output/bin/
