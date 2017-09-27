# Changelog

**latest**
- mount volume at `/var/run/mysqld` allowing the mysql unix socket can be exposed
- determine remote access filter based on the docker network (first run only).
- switched to rickrussell/debian:latest base image
- optimized image size by removing `/var/lib/apt/lists/*`.
- accept connections only after we have create the users and databases
