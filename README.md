# relax-docker

Image of a Docker container with [RelaX - relational algebra calculator](https://dbis-uibk.github.io/relax/). Moreover, this build provides a workaround to facilitate the integration of RelaX Query API with third-party applications/systems. More information regarding this can be found [here](https://github.com/rlaiola/relax-api).

## Requirements

* Install [Git](https://github.com/git-guides/install-git) (only for building and publishing);
* Install [Docker Desktop](https://www.docker.com/get-started).

## How To Use This Docker Image

### Quick Start

* Open a Terminal window and log in into GitHub’s Container Registry using your username and personal access token (details [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry)).

  ```sh
  docker login ghcr.io
  ```

* Once you logged in, start the container using the following command:

  ```sh
  docker run -i --init --rm -p 80:8080 -p 3000:3000 ghcr.io/rlaiola/relax-docker:1.0.1
  ```

  > **NOTE:** The container uses ports 8080 (RelaX Web app) and 3000 (RelaX API). Port mapping is mandatory for the desired service to work (i.e., the argument '-p HOST_PORT:3000' is needed only if you plan to use RelaX API, and vice-versa).

* Open a Web browser window and visit the URL [http://localhost](http://localhost). Voilà! RelaX Web application should work properly.

  <p align="center">
    <img src="imgs/relax_web_app.png" width=800 />
  </p>

* Run the following command to test the RelaX API. You should get the query result encoded in JSON format.

  ```sh
  curl http://127.0.0.1:3000/relax/api/local/uibk/local/0?query=UiBqb2luIFMgam9pbiBU
  ```

  <p align="center">
    <img src="imgs/relax_api.png" width=800 />
  </p>

### Increasing Github Rate Limit For API Requests Using Basic Authentication

RelaX Web application and API may need to make calls to GitHub API (i.e., to download datasets specified in GitHub Gists). According to the [documentation](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting), "for unauthenticated requests, the rate limit allows for up to 60 requests per hour.
Unauthenticated requests are associated with the originating IP address, and not the user making requests." On the other hand, "for API requests using Basic Authentication ..., you can make up to 5,000 requests per hour." Follow the steps below in order to take advantage of a larger request limit:

* Read these [instructions](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/about-authentication-to-github#authenticating-with-the-api) to create a personal access token to authenticate with GitHub API.

* Then, start the container setting the GITHUB_ACCESS_TOKEN environment variable (replace the word 'my_token' with the actual personal access token generated in the previous step).

  ```sh
  docker run -i --init --rm -p 80:8080 -p 3000:3000 -e GITHUB_ACCESS_TOKEN=my_token ghcr.io/rlaiola/relax-docker:1.0.1
  ```

  > **NOTE:** You can check the current and remaining limits using the following command (replace the word 'my_token' with the actual personal access token created before). For details check the [documentation](https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api).

  ```sh
  curl -H "Authorization: token my_token" -I https://api.github.com/users/octocat/orgs
  ```

## How To Build This Docker Image

* Open a Terminal window and prepare the environment.

  ```sh
  # Clone this repo and set it as your working directory
  git clone https://github.com/rlaiola/relax-docker.git
  cd relax-docker

  # List downloaded images
  docker images -a

  # List existing containers
  docker container ls -a

  # Build image
  docker build -f Dockerfile -t relax-docker .

  # Get IMAGE_ID and specify a version number (e.g., 1.0.1)
  docker images -a
  docker tag IMAGE_ID ghcr.io/rlaiola/relax-docker:1.0.1
  ```

## How To Upload This Docker Image

* Open a Terminal window and log in into GitHub's Container Registry using your username and personal access token (details [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry)).

  ```sh
  docker login ghcr.io
  ```

* Push the container image to repository.

  ```sh
  docker push ghcr.io/rlaiola/relax-docker:1.0.1
  ```

## License

Copyright 2021 Rodrigo Laiola Guimaraes

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

Please report any issues with relax-docker at [https://github.com/rlaiola/relax-docker/issues](https://github.com/rlaiola/relax-docker/issues)
