#!/bin/bash
DOCKERFILE=Dockerfile-no-python

TAG=$(grep -E "^ENV BIND_VERSION" $DOCKERFILE | cut -d" " -f3)
docker build -f $DOCKERFILE -t sausix/bind-sql-base-alpine:$TAG .
