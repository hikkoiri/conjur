# Upgrading

This section describes how to upgrade a Conjur Server.

## Standard Process

The following steps describe a standard upgrade of the Conjur server, when deployed
using Docker Compose. These steps assume you have defined your Conjur image in
a service named `conjur`, and that you have access to the Conjur data key
that was used when you originally deployed your Conjur server.
1. In your terminal window, set the `CONJUR_DATA_KEY` environment variable:
   ```
   export CONJUR_DATA_KEY={your Conjur data key}
   ```

1. Edit the Conjur image version in `docker-compose.yml` to reference the new
   version.

1. Pull the new Conjur image version:
   ```
   docker-compose pull conjur
   ```

1. Stop the Conjur container:
   ```
   docker-compose stop conjur
   ```

1. Bring up the Conjur service using the new image version without changing
   linked services:
   ```
   docker-compose up -d --no-deps conjur
   ```

1. View Docker containers and verify all are healthy, up and running:
   ```
   docker ps -a
   ```

   It may also be useful to check the logs of the Conjur
   container to ensure that Puma started successfully, which can be done by
   running
   ```
   docker logs conjur_server
   ```
   where `conjur_server` is defined as the `container_name` of the Conjur
   service in the `docker-compose.yml`.
   

### Troubleshooting

If you run through the steps above _without_ setting the `CONJUR_DATA_KEY`
environment variable first, you will be able to complete the steps successfully
but the logs of the new Conjur container will show an error like:
```
$ docker logs conjur_server
rake aborted!
No CONJUR_DATA_KEY
...
```
`conjur_server` in the example command above is defined as the `container_name`
of the `conjur` service in the `docker-compose.yml`.

To fix this, set the `CONJUR_DATA_KEY` environment variable and run through
the process again. This time when you check the logs of the Conjur server
container you should see the Puma service starting as expected:
```
$ docker logs conjur_server
...
=> Booting Puma
=> Rails 5.2.4.3 application starting in production 
=> Run `rails server -h` for more startup options
[10] Puma starting in cluster mode...
[10] * Version 3.12.6 (ruby 2.5.1-p57), codename: Llamas in Pajamas
[10] * Min threads: 5, max threads: 5
[10] * Environment: development
[10] * Process workers: 2
[10] * Preloading application
[10] * Listening on tcp://0.0.0.0:80
[10] Use Ctrl-C to stop
[10] - Worker 0 (pid: 26) booted, phase: 0
[10] - Worker 1 (pid: 30) booted, phase: 0
```

## Release Specific Upgrade Steps

### 1.8.0
**This step must be done when upgrading from version 1.7.4 and below to any
newer version.**

Starting in version 1.8.0, the hashing algorithm used to fingerprint and identify
encryption keys was changed from MD5 to SHA256. This fingerprint is stored in
the Postgres database and must be updated in order to ensure a seamless upgrade
to 1.8.0 or higher. This data migration has been encapsulated into a simple Ruby
rake command that must be run after launching the new Conjur container, but before
any requests are made to the new server process.

To upgrade from versions 1.7.4 and below to versions 1.8.0 and above, complete
the [standard upgrade process](#standard-process) and once the new Conjur
container is up (but before it has served any new traffic) run:
```
docker-compose exec conjur bundle exec rake slosilo:migrate
```
where `conjur` is the service name for the Conjur container in your
`docker-compose.yml`.
