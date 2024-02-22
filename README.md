# relax-docker

[![Build and publish multi-platform_Docker images on ghcr.io workflow][build_publish_workflow_badge]][build_publish_workflow_link]
[![Delete GitHub Actions cache for repository workflow][cache_cleanup_workflow_badge]][cache_cleanup_workflow_link]
[![Delete_untagged_and/or_unsupported_Docker_images_on_ghcr.io_workflow][packages_cleanup_workflow_badge]][packages_cleanup_workflow_link]
[![Close_stale_issues_and_PRs_workflow][close_stale_workflow_badge]][close_stale_workflow_link]

[![Ubuntu JAMMY][ubuntu_jammy_badge]][ubuntu_jammy_link]
[![Ubuntu FOCAL][ubuntu_focal_badge]][ubuntu_focal_link]
[![Multi-Architecture][arch_badge]][arch_link]

[build_publish_workflow_badge]: https://img.shields.io/github/actions/workflow/status/rlaiola/relax-docker/ci.yml?label=build%20images&logo=github
[build_publish_workflow_link]: https://github.com/rlaiola/relax-docker/actions?workflow=CI "build and publish multi-platform images"
[cache_cleanup_workflow_badge]: https://img.shields.io/github/actions/workflow/status/rlaiola/relax-docker/clean-cache.yml?label=clean%20cache&logo=github
[cache_cleanup_workflow_link]: https://github.com/rlaiola/relax-docker/actions?workflow=delete%20GitHub "delete github actions cache"
[packages_cleanup_workflow_badge]: https://img.shields.io/github/actions/workflow/status/rlaiola/relax-docker/clean-packages.yml?label=clean%20packages&logo=github
[packages_cleanup_workflow_link]: https://github.com/rlaiola/relax-docker/actions?workflow=delete%20untagged "delete untagged/unsupported images"
[close_stale_workflow_badge]: https://img.shields.io/github/actions/workflow/status/rlaiola/relax-docker/close-stale.yml?label=close%20stale&logo=github
[close_stale_workflow_link]: https://github.com/rlaiola/relax-docker/actions?workflow=close%20stale "close stale issues and prs"
[ubuntu_jammy_badge]: https://img.shields.io/badge/ubuntu-jammy-E95420.svg?logo=Ubuntu
[ubuntu_focal_badge]: https://img.shields.io/badge/ubuntu-focal-E95420.svg?logo=Ubuntu
[ubuntu_jammy_link]: https://hub.docker.com/_/ubuntu/tags?page=1&name=jammy "ubuntu:jammy image"
[ubuntu_focal_link]: https://hub.docker.com/_/ubuntu/tags?page=1&name=focal "ubuntu:focal image"
[arch_badge]: https://img.shields.io/badge/multi--arch-%20amd64%20|%20arm/v7%20|%20arm64/v8%20|%20ppc64le%20|%20s390x%20-lightgray.svg?logo=Docker&logoColor=white
[arch_link]: #running-on-different-ubuntu-release-images "multi-arch images"

## Table of Contents

- [What Is relax-docker?](#what-is-relax-docker)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [How To Add Custom Configuration](#how-to-add-custom-configuration)
- [How To Build It (For Development)](#how-to-build-it-for-development)
- [How To Publish It](#how-to-publish-it)
- [How To Contribute](#how-to-contribute)
- [License](#license)
- [Support](#support)

## What Is relax-docker?

A multi-platform/arch Docker version of [RelaX - relational algebra calculator](https://dbis-uibk.github.io/relax/). Moreover, this build provides a workaround to facilitate the integration of RelaX Query API with third-party applications/systems. More information regarding this can be found [here](https://github.com/rlaiola/relax-api).

## Requirements

* Install [Git](https://github.com/git-guides/install-git) (only for building and publishing);
* Install [Docker Desktop](https://www.docker.com/get-started).

## Quick Start

* Open a Terminal window and log in into GitHub’s Container Registry using your username and personal access token (details [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry));

  ```sh
  docker login ghcr.io
  ```

* Once you logged in, start the container using the following command:

  ```sh
  docker run -i --init --rm -p 80:8080 -p 3000:3000 ghcr.io/rlaiola/relax:1.0.2
  ```

  > **NOTE:** The container uses ports 8080 (RelaX Web app) and 3000 (RelaX API). Port mapping is mandatory for the desired service to work (i.e., the argument '-p HOST_PORT:3000' is needed only if you plan to use RelaX API, and vice-versa).

* Open a Web browser window and visit the URL [http://localhost](http://localhost). Voilà! RelaX Web application should work properly;

  <p align="center">
    <img src="imgs/relax_web_app.png" alt="RelaX web app" width=800 />
  </p>

* Run the following command to test the RelaX API. You should get the query result encoded in JSON format;

  ```sh
  curl http://127.0.0.1:3000/relax/api/local/uibk/local/0?query=UiBqb2luIFMgam9pbiBU
  ```

  <p align="center">
    <img src="imgs/relax_api.png" alt="Testing RelaX API" width=800 />
  </p>

## How To Add Custom Configuration

### Increasing Github Rate Limit For API Requests Using Basic Authentication

RelaX Web application and API may need to make calls to GitHub API (i.e., to download datasets specified in GitHub Gists). According to the [documentation](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting), "for unauthenticated requests, the rate limit allows for up to 60 requests per hour.
Unauthenticated requests are associated with the originating IP address, and not the user making requests." On the other hand, "for API requests using Basic Authentication ..., you can make up to 5,000 requests per hour." Follow the steps below in order to take advantage of a larger request limit:

* Read these [instructions](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/about-authentication-to-github#authenticating-with-the-api) to create a personal access token to authenticate with GitHub API;

* Then, start the container setting the GITHUB_ACCESS_TOKEN environment variable (replace the word 'my_token' with the actual personal access token generated in the previous step).

  ```sh
  docker run -i --init --rm -p 80:8080 -p 3000:3000 -e GITHUB_ACCESS_TOKEN=my_token ghcr.io/rlaiola/relax:1.0.2
  ```

> **NOTE:** You can check the current and remaining limits using the following command (replace the word 'my_token' with the actual personal access token created before). For details check the [documentation](https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api).

  ```sh
  curl -H "Authorization: token my_token" -I https://api.github.com/users/octocat/orgs
  ```

### Running On Different Ubuntu Release Images

To run _relax-docker_ built on top of different versions of Ubuntu images, refer to the tags from the table below.

| Tag name                                             | Ubuntu version | Code name       | Architecture                                      |
|------------------------------------------------------|----------------|-----------------|---------------------------------------------------|
| `latest`, `1.0`, `1.0-jammy`, `1.0.2`, `1.0.2-jammy` | 22.04 LTS      | Jammy Jellyfish | `amd64`, `arm/v7`, `arm64/v8`, `ppc64le`, `s390x` |
| `1.0-focal`, `1.0.2-focal`                           | 20.04 LTS      | Focal Fossa     | `amd64`, `arm/v7`, `arm64/v8`, `ppc64le`, `s390x` |
| `nightly`, `nightly-jammy`                           | 22.04 LTS      | Jammy Jellyfish | `amd64`, `arm/v7`, `arm64/v8`, `ppc64le`, `s390x` |
| `nightly-focal`                                      | 20.04 LTS      | Focal Fossa     | `amd64`, `arm/v7`, `arm64/v8`, `ppc64le`, `s390x` |

For example, to use it running on Ubuntu 20.04 LTS (Focal Fossa) on any supported architecture:

  ```sh
  docker run -i --init --rm -p 80:8080 -p 3000:3000 ghcr.io/rlaiola/relax:1.0.2-focal
  ```

### Deprecated Image Tags

The following image tags have been deprecated and are no longer receiving updates:
- 1.0.1
- 1.0.0

## How To Build It (For Development)

* Clone this repository and set it as your working directory:

  ```sh
  git clone https://github.com/rlaiola/relax-docker.git
  cd relax-docker
  ```

* Then, use the commands below to build the image:

  ```sh
  # List downloaded images
  docker images -a

  # Build image
  docker build --build-arg REF_BRANCH=main -f Dockerfile -t relax .
  ```

## How To Publish It

> **NOTE:** These instructions take into account the Docker image generated in the previous section (no multi-platform support).

* After building, set the user and image tags accordingly. The IMAGE_ID's will show up with the `docker images -a`;

  ```sh
  docker tag IMAGE_ID ghcr.io/rlaiola/relax:1.0.2
  ```

* Log in into GitHub's Container Registry using your username and personal access token (details [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry));

  ```sh
  docker login ghcr.io
  ```

* Push the container image to registry.

  ```sh
  docker push ghcr.io/rlaiola/relax:1.0.2
  ```

## How to Contribute

If you would like to help contribute to this project, please see [CONTRIBUTING](https://github.com/rlaiola/boca-utils/blob/main/CONTRIBUTING.md).

Before submitting a PR consider building and testing a Docker image locally and checking your code with Super-Linter:

  ```sh
  docker run --rm \
             -e ACTIONS_RUNNER_DEBUG=true \
             -e RUN_LOCAL=true \
             -e DEFAULT_BRANCH=main \
             --env-file ".github/super-linter.env" \
             -v "$PWD":/tmp/lint \
             ghcr.io/super-linter/super-linter:latest
  ```

## License

Copyright Universidade Federal do Espirito Santo (Ufes)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

This program is released under license GNU GPL v3+ license.

## Support

Please report any issues with relax at [https://github.com/rlaiola/relax-docker/issues](https://github.com/rlaiola/relax-docker/issues)
