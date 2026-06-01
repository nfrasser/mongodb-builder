#!/bin/bash
set -e

ARCH="${ARCH:-x86_64}"
PLATFORM="${PLATFORM:-linux/amd64}"
MONGO_VERSION="${MONGO_VERSION:-8.0.23}"
SRC="r$MONGO_VERSION"
TARGET="mongodb-linux-${ARCH}-${MONGO_VERSION}"
BIN="$TARGET/bin"
mongoSrcUrl="https://github.com/mongodb/mongo/archive/refs/tags/$SRC.tar.gz"

mongoSrcFolder="mongo-$SRC"
[ ! -f "${SRC}.tar.gz" ] && curl -L -C - -O "$mongoSrcUrl"
[ ! -d $SRC ] && tar -xzf "${SRC}.tar.gz"
echo "{\"version\": \"${MONGO_VERSION}\"}" > $mongoSrcFolder/version.json

docker run --memory=32g --platform "${PLATFORM}" --rm -it \
  -v $(pwd)/$mongoSrcFolder:/mongodb \
  -v mongo-bazel-cache:/root/.cache/bazel \
  -v mongo-poetry-cache:/root/.cache/pypoetry \
  mongodb-builder -e MONGO_VERSION="${MONGO_VERSION}"

mkdir -p $BIN
mv "$mongoSrcFolder/output/bin/mongos" "$mongoSrcFolder/output/bin/mongod" $BIN
tar -czf "$TARGET.tgz" $TARGET
