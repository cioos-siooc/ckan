# CIOOS Fork of CKAN/CKAN

This repo was originally forked from `https://github.com/ckan/ckan` and has undergone significant modification to make it docker compatible. It now more closely resembles `https://github.com/ckan/ckan-docker` and has a similar intention, that of providing an easy ckan install encapsulated in docker containers.

This repo builds a cioos ckan docker container along with associated solr, postgres, redis containers. It differs from other ckan docker builds such as `https://github.com/ckan/ckan-docker-base` in that it does not user supervisor to run the harvesters. instead 3 containers are spun up, ckan_gather_harvester, ckan_fetch_harvester, and ckan_run_harvester. In this way the harvesters are independent of the ckan main app.

Detailed documentation can be found in `/docs`. Release notes for cioos ckan version can be found in `/contrib/docker/release_notes`

## Details
CKAN docker images built in this repo are based on the `ckan/ckan-base:2.9` docker image. The CKAN extensions are included in this repo as submodules and can be found at `/contrib/docker/src`.

The Redis, Postgres, and Solr containers use prebuilt images. Some configuration of the Solr container is required however. Solr schema config can be found in `/ckan/config/solr`. The CKAN, Solr and Postgres images are built by github actions and pushed to docker hub. Postgres init scripts are found in `/contrib/docker/postgres/docker-entrypoint-initdb.d`. See the docker-compose.yml in `/contrib/docker/` for more information.

## How to Build
Building of production and dev images can be done in various ways

### Local build

```bash
cd ~/ckan/contrib/docker/
sudo docker compose -f docker-compose.yml build ckan
```

### GitHub actions
To build images from github actions we first start a pull request to `cioos` or `cioos-dev` branches. Once the PR is approved and merged, a new dev or production image will be built by the github actions. The images will be pushed to docker hub and available for download at `https://hub.docker.com/orgs/cioos/repositories`

## How to update
If updating a submodule simply make changes to the sub repo and generate a PR or push changes as per the usual 
development workflow for that repo. Once changes are pushed to GitHub you can update the submodule in this repo and 
push changes. Any push to the 'cioos' or 'cioos-dev' branches will generate a new image

A new image build will automatically use the latest ckan 2.9 base image so to update to a newer base image minor version you simple need to rebuild the image

If updating to a newer major version you will need to modify the Dockerfile to use a new major version and do significant testing.

## How to install
Clone this github repo to your server

```bash
git clone https://github.com/cioos-siooc/ckan.git
```

### Generate environment file

The environment file covers many settings and options for CKAN, some of which will need to be changed to suit your install.

```bash
cd ckan/contrib/docker
cp production_root_url.ini ckan.ini
cp .env.template .env
nano .env
```

### Pull CKAN, solr, redis, and postgres images

```bash
sudo docker compose pull
```

### Permissions for logging

By default, ckan logs are stored on the host machine in `/var/log/ckan`, this value is defined in the `.env` file under the `CKAN_LOG_PATH` setting.

Wherever you decide to store the logs, the user account that is running in the container must be able to write to that directory.  In order to do this you will need to change the owner of the logging directory to `92:92`, which is user and group ids of the `www-data` account in the CKAN container.

**NOTE:** This is only necessary when initially installing CKAN, this action shouldn't need to be repeated so long as the log directory remains.

```bash
sudo chown -R 92:92 /var/log/ckan/
```

### Start containers

```bash
sudo docker compose up -d
```

Depending on your setup you will likely want to proxy the containers behind nginx or apache. More details regarding install, upgrading, debugging can be found in the [/docs](./docs/) folder
