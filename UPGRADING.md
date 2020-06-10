# Upgrading

This section describes how to upgrade a Conjur Server.

## Standard Process

The following steps describe a standard upgrade of the Conjur server, when deployed
using Docker Compose.
1. Edit `docker-compose.yml` Conjur service image tag to reference the new version.
1. Delete current conjur container. This can be done by running:
   ```
   docker rm -f conjur_server
   ```
   where `conjur_server` is set as the `container_name` in the `docker-compose.yml`.
1. Rerun Docker Compose: `docker-compose up -d`.
1. View Docker containers and verify all are healthy, up and running: `docker ps -a`.

**Note:** It is possible that the`CONJUR_DATA_KEY` environment variable will need
to be reassigned, using the same key as before. Simply run:
```
export CONJUR_DATA_KEY="$(< data_key)
```

## Release Specific Upgrade Steps

### 1.8.0
**This step must be done when upgrading from version 1.7.2 and below to any newer
version.**

Starting in version 1.8.0, the hashing algorithm used to fingerprint and identify
encryption keys was changed from MD5 to SHA256. This fingerprint is stored in
the Postgres database and must be updated in order to ensure a seamless upgrade
to 1.8.0 or higher. This data migration has been encapsulated into a simple Ruby
rake command that must be run after launching the new Conjur container, but before
any requests are made to the new server process. It is as follows:
```
bundle exec rake slosilo:migrate
```
