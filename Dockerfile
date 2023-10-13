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
ENV UPDATED_AT 2023-10-10

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

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
      curl \
      git \
      gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
# https://askubuntu.com/questions/720784/how-to-install-latest-node-inside-a-docker-container
# hadolint ignore=DL4006
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -

# hadolint ignore=DL3008,DL3016
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      nodejs \
      npm \
    && npm install --global yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
