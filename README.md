# Table of Contents

- [Introduction](#introduction)
- [Contributing](#contributing)
- [Changelog](Changelog.md)
- [Reporting Issues](#reporting-issues)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Data Store](#data-store)
- [Creating User and Database at Launch](#creating-user-and-database-at-launch)
- [Creating remote user with privileged access](#creating-remote-user-with-privileged-access)
- [Shell Access](#shell-access)
- [Upgrading](#upgrading)

# Introduction

Dockerfile to build a MySQL container image which can be linked to other containers.

# Contributing

If you find this image useful here's how you can help:

- Send a Pull Request with your awesome new features and bug fixes
- Help new users with [Issues](https://github.com/rickrussell/docker-mysql/issues) they may encounter

# Reporting Issues

Docker is a relatively new project and is active being developed and tested by a thriving community of developers and testers and every release of docker features many enhancements and bugfixes.

Given the nature of the development and release cycle it is very important that you have the latest version of docker installed because any issue that you encounter might have already been fixed with a newer docker release.

Install latest version of docker for yourself:

```bash
curl -fsSL "https://download.docker.com/linux/debian/gpg" | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y install docker-ce
sudo usermod -aG docker ${USER}
```
> **NOTE**
> You will need to logout and log back in before you're officially a member of the
> docker group

And install docker-compose for later use:

```bash
sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

# Installation

Automated builds of the image are available on [Dockerhub](https://hub.docker.com/r/rickrussell/mysql) and is the recommended method of installation.

```bash
docker pull rickrussell/mysql:latest
```

Alternately you can build the image yourself.

```bash
docker build -t rickrussell/mysql github.com/rickrussell/docker-mysql
```

# Quick Start

Run the mysql image

```bash
docker run --name mysql -d rickrussell/mysql:latest
```

You can access the mysql server as the root user using the following command:

```bash
docker run -it --rm --volumes-from=mysql rickrussell/mysql:latest mysql -uroot
```

# Data Store

You should mount a volume at `/var/lib/mysql`.

SELinux users are also required to change the security context of the mount point so that it plays nicely with selinux.

```bash
mkdir -p /opt/mysql/data
sudo chcon -Rt svirt_sandbox_file_t /opt/mysql/data
```

The updated run command looks like this.

```bash
docker run --name mysql -d \
  -v /opt/mysql/data:/var/lib/mysql rickrussell/mysql:latest
```

This will make sure that the data stored in the database is not lost when the image is stopped and started again.

# Creating User and Database at Launch

> **NOTE**
>
> For this feature to work the `debian-sys-maint` user needs to exist. This user is automatically created when the database is installed for the first time (firstrun).
>
> However if you were using this image before this feature was added, then it will not work as-is. You are required to create the `debian-sys-maint` user
>
>```bash
>docker run -it --rm --volumes-from=mysql rickrussell/mysql \
>  mysql -uroot -e "GRANT ALL PRIVILEGES on *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '' WITH GRANT OPTION;"
>```

To create a new database specify the database name in the `DB_NAME` variable. The following command creates a new database named *dbname*:

```bash
docker run --name mysql -d \
  -e 'DB_NAME=dbname' rickrussell/mysql:latest
```

You may also specify a comma separated list of database names in the `DB_NAME` variable. The following command creates two new databases named *dbname1* and *dbname2*

```bash
docker run --name mysql -d \
-e 'DB_NAME=dbname1,dbname2' rickrussell/mysql:latest
```

To create a new user you should specify the `DB_USER` and `DB_PASS` variables.

```bash
docker run --name mysql -d \
  -e 'DB_USER=dbuser' -e 'DB_PASS=dbpass' -e 'DB_NAME=dbname' \
  rickrussell/mysql:latest
```

The above command will create a user *dbuser* with the password *dbpass* and will also create a database named *dbname*. The *dbuser* user will have full/remote access to the database.

**NOTE**
- If the `DB_NAME` is not specified, the user will not be created
- If the user/database user already exists no changes are be made
- If `DB_PASS` is not specified, an empty password will be set for the user

By default the new database will be created with the `utf8` character set and `utf8_unicode_ci` collation. You may override these with the `MYSQL_CHARSET` and `MYSQL_COLLATION` variables.

```bash
docker run --name mysql -d \
  -e 'DB_USER=dbuser' -e 'DB_PASS=dbpass' -e 'DB_NAME=dbname' \
  -e 'MYSQL_CHARSET=utf8mb4' -e 'MYSQL_COLLATION=utf8_bin' \
  rickrussell/mysql:latest
```

# Creating remote user with privileged access

To create a remote user with privileged access, you need to specify the `DB_REMOTE_ROOT_NAME` and `DB_REMOTE_ROOT_PASS` variables, eg.

```bash
docker run --name mysql -d \
  -e 'DB_REMOTE_ROOT_NAME=root' -e 'DB_REMOTE_ROOT_PASS=secretpassword' \
  rickrussell/mysql:latest
```

Optionally you can specify the `DB_REMOTE_ROOT_HOST` variable to define the address space within which remote access should be permitted. This defaults to `172.17.0.1` and should suffice for most cases.

Situations that would require you to override the default `DB_REMOTE_ROOT_HOST` setting are:

- If you have changed the ip address of the `docker0` interface
- If you are using host networking, i.e. `--net=host`, etc.

# Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using docker version `1.3.0` or higher you can access a running containers shell using `docker exec` command.

```bash
docker exec -it mysql bash
```

If you are using an older version of docker, you can use the [nsenter](http://man7.org/linux/man-pages/man1/nsenter.1.html) linux tool (part of the util-linux package) to access the container shell.

Some linux distros (e.g. ubuntu) use older versions of the util-linux which do not include the `nsenter` tool. To get around this @jpetazzo has created a nice docker image that allows you to install the `nsenter` utility and a helper script named `docker-enter` on these distros.

To install `nsenter` execute the following command on your host,

```bash
docker run --rm -v /usr/local/bin:/target jpetazzo/nsenter
```

Now you can access the container shell using the command

```bash
sudo docker-enter mysql
```

For more information refer https://github.com/jpetazzo/nsenter

# Upgrading

To upgrade to newer releases, simply follow this 3 step upgrade procedure.

- **Step 1**: Stop the currently running image

```bash
docker stop mysql
```

- **Step 2**: Update the docker image.

```bash
docker pull rickrussell/mysql:latest
```

- **Step 3**: Start the image

```bash
docker run --name mysql -d [OPTIONS] rickrussell/mysql:latest
```
