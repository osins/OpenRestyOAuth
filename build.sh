#!/bin/bash

docker build -t osins/openresty-oauth . && \
docker push osins/openresty-oauth