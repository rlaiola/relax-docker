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

FROM mcr.microsoft.com/devcontainers/base:jammy

LABEL authors="Rodrigo Laiola Guimaraes"
ENV CREATED_AT=2025-10-15
ENV UPDATED_AT=2025-10-15

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive

# Install dev dependencies
# hadolint ignore=DL3008,DL3013
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
