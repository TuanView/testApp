# This docker file is to build a docker image for all installation
# for dependencies tools necessary to build the View S/W.
# Assume that there is a base docker image for centos
# Usage:
#   % docker build -t centos/base_view .
#
FROM centos

MAINTAINER tuan.doan@viewglass.com

# CMD echo "Building docker base image for all sw dependencies ..."

COPY MariaDB.repo /
COPY install-dependencies.sh /
COPY mysql_secure.sh /

RUN sh /install-dependencies.sh
RUN sh /mysql_secure.sh
