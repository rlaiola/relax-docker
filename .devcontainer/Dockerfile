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

FROM mcr.microsoft.com/devcontainers/typescript-node:1-20

LABEL authors="Rodrigo Laiola Guimaraes"
ENV CREATED_AT=2025-10-15
ENV UPDATED_AT=2025-11-24

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive

# Install dev dependencies
# hadolint ignore=DL3008,DL3013,DL4001
RUN apt-get -y update \
    # Install hadolint (Dockerfile linter)
    && wget -q -O /bin/hadolint \
    https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 \
    && chmod +x /bin/hadolint \
    && apt-get -y install --no-install-recommends \
      # Install ShellCheck (shell script linter)
      shellcheck \
      # Install shfmt formatter (shell script, dockerfile etc.)
      shfmt \
      # Install yamllinter (YAML linter)
      yamllint \
    && rm -rf /var/lib/apt/lists/*

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Git URL of the RelaX repository to clone from (default: dbis-uibk/relax)
ARG REPOSITORY=https://github.com/dbis-uibk/relax.git

# Using ARG to set ENV
ENV ENV_REPOSITORY=$REPOSITORY

# Install dependencies
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      git \
      chromium \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Checkout ref branch
RUN git clone --branch gh-pages "${ENV_REPOSITORY}" /tmp/relax

# Set working folder
WORKDIR /tmp/relax

# Create a new release from source
RUN mkdir ../dist \
    && cp -rf ./* ../dist \
    && mv ../dist .;

# Checkout RelaX API repository and move RelaX repository from dist image
RUN git clone --branch main https://github.com/rlaiola/relax-api.git /usr/src/relax-api \
    && mkdir -p /usr/src/relax-api/dist/relax \
    && cp -r /tmp/relax/dist/* /usr/src/relax-api/dist/relax/ \
    && rm -rf /tmp/relax

# Set working folder
WORKDIR /usr/src/relax-api/tests/e2e

# Install dependencies
RUN npm install

# Install Playwright and Chromium web browser
RUN npx -y playwright install chromium \
    && npx playwright install-deps chromium

# IMPORTANT: DevContainers should NOT start the app automatically.
# (CMD removed intentionally to avoid blocking the VS Code environment)
