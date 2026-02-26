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
# Dockerfile to build Traffic Stats container images
# Based on Ubuntu 24.04
############################################################

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version} AS trafficstats-dependencies

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        findutils \
        gettext \
        jq \
        net-tools \
        ncat \
        openssl \
        procps \
        dpkg && \
    rm -rf /var/lib/apt/lists/*

FROM trafficstats-dependencies AS trafficstats

# Default values for package -- override with `docker build --build-arg TRAFFIC_TS_DEB=...'
ARG TRAFFIC_TS_DEB=traffic_stats/traffic_stats.deb
ADD $TRAFFIC_TS_DEB /
RUN dpkg -i --force-depends /$(basename $TRAFFIC_TS_DEB) && \
    rm /$(basename $TRAFFIC_TS_DEB)

ADD enroller/server_template.json \
    traffic_ops/to-access.sh \
    traffic_stats/run.sh \
    /

COPY dns/set-dns.sh \
     dns/insert-self-into-dns.sh \
     /usr/local/sbin/

ENTRYPOINT /run.sh

FROM trafficstats-dependencies AS get-delve

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends golang-go && \
    rm -rf /var/lib/apt/lists/* && \
    go install github.com/go-delve/delve/cmd/dlv@v1.26.0

FROM trafficstats AS trafficstats-debug
COPY --from=get-delve /root/go/bin /usr/bin

# Makes the default target skip the trafficstats-debug stage
FROM trafficstats
