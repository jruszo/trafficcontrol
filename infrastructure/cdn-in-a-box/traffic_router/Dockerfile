# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
############################################################
# Dockerfile to build Traffic Router 3.0
# Based on Ubuntu 24.04
############################################################

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version}

MAINTAINER dev@trafficcontrol.apache.org

# Default values for package args.
ARG TRAFFIC_ROUTER_DEB=traffic_router/traffic_router.deb
ARG TOMCAT_DEB=traffic_router/tomcat.deb

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        ca-certificates \
        curl \
        default-jdk-headless \
        dnsutils \
        findutils \
        g++ \
        gcc \
        gettext \
        git \
        jq \
        iproute2 \
        libapr1 \
        libapr1-dev \
        libssl-dev \
        libtcnative-1 \
        make \
        net-tools \
        netcat-openbsd \
        openssl \
        perl \
        procps \
        dpkg \
        wget \
        tar \
        unzip \
        which && \
    rm -rf /var/lib/apt/lists/* && \
    JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")" && \
    ln -sfv "${JAVA_HOME}" /opt/java

ADD $TRAFFIC_ROUTER_DEB /traffic_router.deb
ADD $TOMCAT_DEB /tomcat.deb

RUN dpkg -i --force-depends /traffic_router.deb /tomcat.deb && \
    find /usr/lib* -name libtc\* -exec ln -sfv {} /opt/tomcat/lib \;

ADD enroller/server_template.json \
    traffic_router/run.sh \
    traffic_ops/to-access.sh \
    /

COPY dns/set-dns.sh \
     dns/insert-self-into-dns.sh \
     /usr/local/sbin/

EXPOSE 53 80 3333 3443

CMD /run.sh
