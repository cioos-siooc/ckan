# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.1]

### Fixed

- addressed issues with the CKAN harvester running indefinitely
- need to lock the `pyopenssl` and `cryptography` packages to specific versions
- updated docker compose to fix issues with entrypoint files


## [1.6.0]

### Changes

 - CKAN repo has been refactored to work off of the [CKAN docker base image](https://github.com/ckan/ckan-docker), this greatly simplifies maintenace of the code base but the CIOOS version still differs from offical CKAN releases
 - `production.ini` has been renamed to `ckan.ini` and is now populated by the values in the `.env` file
 - virtually all CKAN settings are now handled in the `.env` file
 - entrypoint files are now mounted via docker compose and require execute permissions to be set on the files themselves
 - CKAN user id has been changed to 92 from 900, this affects the permissions that need to be set on the CKAN logs in /var/log/ckan
 - For more details see [release notes](./contrib/docker/release_notes/cioos_1.6.0.md)

## [1.5.0]

### Added

- A RA polygon layer has been added to the map display, this requires an appropriate geojson file to be specified in `production.ini`
 - During harvest responsible organization groups will be created, while not recommended, this setting can disabled in `production.ini` or in an individual harvester.

### Changes

 - Updated basemap tiles set to use [stadiamaps.com](https://stadiamaps.com/stamen/onboarding/create-account/), this will require creating an account and supplying an API key to `production.ini`
  - If using Amazon translate in your CKAN setup you will need to set your AWS Keys in the `.env` file
 - For more details see [release notes](./contrib/docker/release_notes/cioos_1.5.0.md)

## [1.4.0]

### Added
 - AWS settings to docker-compose.yml
 - support for harvesting from Datastream
 - support for ECV variables

### Changes

 - See [release notes](./contrib/docker/release_notes/cioos_1.4.0.md)
