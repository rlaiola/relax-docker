#========================================================================
# Copyright 2021 Rodrigo Laiola Guimarães
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

# Dockerfile to build the image of a Docker container with RelaX - relational 
# algebra calculator (https://dbis-uibk.github.io/relax/). Moreover, this
# build includes a workaround to facilitate the integration of Relax Query
# API with third-party applications/systems (RelaX implementation uses React 
# JS, a UI framework, to load data asynchronously on a single page application. 
# This approach returns a web page what does not include the data).
#
# BUILD DOCKER:
#
#     docker build -f Dockerfile -t relax-docker .
#
# RUN DOCKER:
#
#    -  Quick start:
#
#    docker run -i --init --rm -p 80:8080 -p 3000:3000 relax-docker
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

FROM node:12

LABEL maintainer="Rodrigo Laiola Guimaraes"
ENV CREATED_AT 2021-07-07
ENV UPDATED_AT 2022-08-11

# No interactive frontend during docker build.
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# https://raw.githubusercontent.com/dbis-uibk/relax/development/helper/relaxCLI.py
# Docker error: Unable to locate package git
# https://stackoverflow.com/questions/29929534/docker-error-unable-to-locate-package-git
RUN apt-get update \
    # Necessary to clone repository \
    && apt-get install -y --no-install-recommends git=1:2.11.0-3+deb9u7 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest chrome dev package and fonts to support major charsets (Chinese, 
# Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium 
# that Puppeteer installs, work
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget=1.18-5+deb9u3 gnupg=2.1.18-8~deb9u4 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

RUN apt-get update \
    && apt-get install -y google-chrome-stable=104.0.5112.79-1 fonts-ipafont-gothic=00303-16 fonts-wqy-zenhei=0.9.45-6 fonts-thai-tlwg=1:0.6.3-1 fonts-kacst=2.01+mry-12 fonts-freefont-ttf=20120503-6 libxss1=1:1.2.2-1 \
      --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome

# Set working folder
WORKDIR /usr/src

# Clone RelaX API repository
RUN git clone https://github.com/rlaiola/relax-api.git
    
# Set new working folder
WORKDIR /usr/src/relax-api

# Clone RelaX repository and checkout the static files (branch gh-pages)
# https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository-from-github/cloning-a-repository
RUN git clone https://github.com/rlaiola/relax.git dist/relax

# Change to the root of the local repository
WORKDIR /usr/src/relax-api/dist/relax

# List all your branches \
# https://support.atlassian.com/bitbucket-cloud/docs/check-out-a-branch/ \
RUN git branch -a && \
    # Checkout branch gh_pages and confirm you are now working on that one \
    git checkout origin/gh-pages && \
    git checkout gh-pages && \
    git branch

# Change to the root of the local repository
WORKDIR /usr/src/relax-api/

# Install dependencies
#RUN npm i express puppeteer winston --save
# For production
RUN npm i express puppeteer winston --save --only=production

# Add RelaX user so we don't need --no-sandbox (puppeteer)
RUN addgroup --system relaxuser && adduser --system --ingroup relaxuser relaxuser \
    && mkdir -p /home/relaxuser/Downloads \
    && chown -R relaxuser:relaxuser /home/relaxuser \
    && chown -R relaxuser:relaxuser /usr/src/relax-api

# Run everything after as non-privileged user
USER relaxuser

EXPOSE 3000 8080
CMD [ "node", "server/index.js" ]
