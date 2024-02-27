#========================================================================
# Copyright Universidade Federal do Espirito Santo (Ufes)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 
# This program is released under license GNU GPL v3+ license.
#
#========================================================================

# Dockerfile to build a multi-platform/arch Docker version of RelaX - 
# relational algebra calculator (https://dbis-uibk.github.io/relax/). Moreover,
# this build includes a workaround to facilitate the integration of Relax Query
# API with third-party applications/systems (RelaX implementation uses React 
# JS, a UI framework, to load data asynchronously on a single page application. 
# This approach returns a web page what does not include the data).
#
# BUILD DOCKER:
#
#     docker build -f Dockerfile -t relax .
#
# RUN DOCKER:
#
#    -  Quick start:
#
#    docker run -i --init --rm -p 80:8080 -p 3000:3000 relax
#
#    **NOTE:** The container uses ports 8080 (RelaX Web app) and 3000 (RelaX Query
#              API). Port mapping is mandatory for the desired service to work 
#              (i.e., the argument '-p HOST_PORT:3000' is needed only if you plan 
#              to use RelaX Query API, and vice-versa).
#
#    Open a Web browser window and visit the URL http://localhost. Voilà! 
#    RelaX Web application should work properly.
#
#    Open a Terminal window and run the following command to test RelaX Query API. You 
#    should get the query result encoded in JSON format.
#    
#    curl http://127.0.0.1:3000/relax/api/local/uibk/local/0?query=UiBqb2luIFMgam9pbiBU
#
# TEST DOCKER:
#
#    docker exec -it CONTAINER_ID /bin/bash
#
# References:
#    https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker

# Build on base image (default: ubuntu:jammy)
# Use official Docker images whenever possible
ARG BASE_IMAGE=ubuntu:jammy

# The efficient way to publish multi-arch containers from GitHub Actions
# https://actuated.dev/blog/multi-arch-docker-github-actions
# hadolint ignore=DL3006
FROM --platform=${BUILDPLATFORM:-linux/amd64} ${BASE_IMAGE} AS relax-base

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

LABEL maintainer="Rodrigo Laiola Guimaraes"
ENV CREATED_AT 2021-07-07
ENV UPDATED_AT 2024-02-27

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Node and Yarn versions
ARG NODE_VERSION=16.20.2
ARG YARN_VERSION=1.22.19
# Using ARG to set ENV
ENV ENV_NODE_VERSION=$NODE_VERSION
ENV ENV_YARN_VERSION=$YARN_VERSION

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome

# Redundant but to ensure we are not going to break anything
# hadolint ignore=DL3002
USER root

# Install dependencies
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      xz-utils \
      git \
      gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
# https://askubuntu.com/questions/720784/how-to-install-latest-node-inside-a-docker-container
# https://github.com/nodejs/docker-node/blob/b695e030ea98f272d843feb98ee1ab62943071b3/14/bullseye/Dockerfile
RUN ARCH= && dpkgArch="$TARGETARCH" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x64';; \
      ppc64el) ARCH='ppc64le';; \
      s390x) ARCH='s390x';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armv7l';; \
      i386) ARCH='x86';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    # gpg keys listed at https://github.com/nodejs/node#release-keys
    && set -ex \
    && for key in \
      4ED778F539E3634C779C87C6D7062848A1AB005C \
      141F07595B7B3FFE74309A937405533BE57C7D57 \
      74F12602B6F1C4E913FAA37AD3A89613643B6201 \
      DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
      C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
      108F52B48DB57BB0CC439B2997B01419BD92F80A \
      A363A499291CBBC940DD62E41F10027AF002F8B0 \
    ; do \
        gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
        gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$ENV_NODE_VERSION/node-v$ENV_NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$ENV_NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$ENV_NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$ENV_NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$ENV_NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version

RUN set -ex \
    && for key in \
      6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$ENV_YARN_VERSION/yarn-v$ENV_YARN_VERSION.tar.gz" \
    && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$ENV_YARN_VERSION/yarn-v$ENV_YARN_VERSION.tar.gz.asc" \
    && gpg --batch --verify yarn-v$ENV_YARN_VERSION.tar.gz.asc yarn-v$ENV_YARN_VERSION.tar.gz \
    && mkdir -p /opt \
    && tar -xzf yarn-v$ENV_YARN_VERSION.tar.gz -C /opt/ \
    && ln -s /opt/yarn-v$ENV_YARN_VERSION/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn-v$ENV_YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
    && rm yarn-v$ENV_YARN_VERSION.tar.gz.asc yarn-v$ENV_YARN_VERSION.tar.gz \
    # smoke test
    && yarn --version

# The efficient way to publish multi-arch containers from GitHub Actions
# https://actuated.dev/blog/multi-arch-docker-github-actions
# hadolint ignore=DL3006
FROM --platform=${BUILDPLATFORM:-linux/amd64} relax-base AS relax-dist

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Git URL of the RelaX repository to clone from (default: dbis-uibk/relax)
ARG REPOSITORY=https://github.com/dbis-uibk/relax.git
# The branch, tag or SHA to point to in the cloned RelaX repository
# (default: gh-pages)
ARG REF=gh-pages
# Using ARG to set ENV
ENV ENV_REPOSITORY=$REPOSITORY
ENV ENV_REF=$REF

# Redundant but to ensure we are not going to break anything
# hadolint ignore=DL3002
USER root

# Checkout ref branch
# https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository-from-github/cloning-a-repository
RUN git clone --branch ${ENV_REF} "${ENV_REPOSITORY}" /tmp/relax

# Set working folder
WORKDIR /tmp/relax

# Create a new release from source
RUN if [ "$ENV_REF" = "gh-pages" ]; \
    then \
      mkdir ../dist \
      && cp -rf ./* ../dist \
      && mv ../dist .; \
    else \
      yarn install --ignore-engines \
      && yarn build \
      && yarn cache clean; \
    fi

# The efficient way to publish multi-arch containers from GitHub Actions
# https://actuated.dev/blog/multi-arch-docker-github-actions
# hadolint ignore=DL3006
FROM --platform=${BUILDPLATFORM:-linux/amd64} relax-base

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Redundant but to ensure we are not going to break anything
USER root

# Install latest chrome dev package and fonts to support major charsets
# (Chinese, Japanese, Arabic, Hebrew, Thai and a few others).
# Note: this installs the necessary libs to make the bundled version of
# Chromium that Puppeteer installs, work.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      google-chrome-stable \
      fonts-ipafont-gothic \
      fonts-wqy-zenhei \
      fonts-thai-tlwg \
      fonts-kacst \
      fonts-freefont-ttf \
      libxss1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Checkout RelaX API repository
RUN git clone --branch main https://github.com/rlaiola/relax-api.git /usr/src/relax
# RUN git clone --branch api https://github.com/rlaiola/relax.git /usr/src/relax

# Copy RelaX repository from dist image
COPY --from=relax-dist /tmp/relax/dist /usr/src/relax/dist/relax

# Set working folder
WORKDIR /usr/src/relax

# Install dependencies
RUN npm i express puppeteer winston --save
# For production
# RUN npm i express puppeteer winston --save --only=production

# Add RelaX user so we don't need --no-sandbox (puppeteer)
RUN addgroup --system relaxuser \
    && adduser --system --ingroup relaxuser relaxuser \
    && mkdir -p /home/relaxuser/Downloads \
    && chown -R relaxuser:relaxuser /home/relaxuser \
    && chown -R relaxuser:relaxuser /usr/src/relax

# Run everything after as non-privileged user
USER relaxuser

EXPOSE 3000 8080
CMD [ "node", "server/index.js" ]
