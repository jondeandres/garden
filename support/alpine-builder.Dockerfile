# Note: This is used by build-pkg.ts, and is not usable as a Garden container
ARG NODE_VERSION=12.18.3-alpine3.11
FROM node:${NODE_VERSION} as builder

RUN apk add --no-cache \
  ca-certificates \
  git \
  gzip \
  libstdc++ \
  openssh \
  openssl \
  tar \
  python \
  make \
  gcc \
  g++

WORKDIR /tmp/pkg

# Pre-fetch the node12 binary for pkg
RUN --mount=type=cache,target=/root/.yarn yarn add pkg@4.5.1 && \
  node_modules/.bin/pkg-fetch node12 alpine x64

# Install external dependencies
ADD cli/package.json cli/yarn.lock /tmp/cli/
ADD core/package.json /tmp/core/
ADD sdk/package.json /tmp/sdk/
# This is prepared by the build script to just include the package.json files, so that we can install 3rd party deps without issues
ADD _plugins /tmp/plugins

WORKDIR /tmp/cli

RUN --mount=type=cache,target=/root/.yarn yarn --frozen-lockfile

# Add all the package code
ADD cli /tmp/cli
ADD core /tmp/core
ADD plugins /tmp/plugins
ADD sdk /tmp/sdk

RUN --mount=type=cache,target=/root/.yarn yarn --force && \
  # Fix for error in this particular package
  rm -rf node_modules/es-get-iterator/test

ADD static /garden/static

# Create the binary
RUN mkdir -p /garden \
  && node_modules/.bin/pkg --target node12-alpine-x64 . --output /garden/garden \
  && cp node_modules/better-sqlite3/build/Release/better_sqlite3.node /garden \
  && /garden/garden version # make sure it works
