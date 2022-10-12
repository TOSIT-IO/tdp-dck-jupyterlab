#!/bin/bash

VERSION_TAG=0

DOCKER_BUILDKIT=1 docker build --progress=plain \
-t jupyterlab:3.4.8-tdp-v${VERSION_TAG} \
--no-cache \
--squash \
-f Dockerfile \
. \
$@ > build.jupyterlab.3.4.8-tdp-v${VERSION_TAG}.log 2>&1

#docker save -o jupyterlab-3.4.8-tdp-v${VERSION_TAG}.tar jupyterlab:3.4.8-tdp-v${VERSION_TAG}