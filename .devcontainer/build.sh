#!/bin/sh
# Skip building image if the image already exists
[ -n "$(docker images -q ysyx-env)" ] || docker build -t ysyx-env .devcontainer