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
# Dockerfile to build Traffic Monitor container images
# Based on Ubuntu 24.04
############################################################

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version} as trafficmonitor-dependencies

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        findutils \
        gettext \
        iproute2 \
        jq \
        net-tools \
        ncat \
        openssl \
        procps \
        dpkg && \
    rm -rf /var/lib/apt/lists/*

FROM trafficmonitor-dependencies AS trafficmonitor

# Default values for package -- override with `docker build --build-arg TRAFFIC_MONITOR_DEB=...'
ARG TRAFFIC_MONITOR_DEB=traffic_monitor/traffic_monitor.deb
ADD $TRAFFIC_MONITOR_DEB /
RUN dpkg -i --force-depends /$(basename $TRAFFIC_MONITOR_DEB) && \
    rm /$(basename $TRAFFIC_MONITOR_DEB)

RUN mkdir -p /opt/traffic_monitor/conf
ADD traffic_monitor/traffic_monitor.cfg /opt/traffic_monitor/conf/traffic_monitor.cfg.template

ADD enroller/server_template.json \
    traffic_ops/to-access.sh \
    /

COPY dns/set-dns.sh \
     dns/insert-self-into-dns.sh \
     /usr/local/sbin/

EXPOSE 80
ADD traffic_monitor/run.sh /
CMD /run.sh
HEALTHCHECK --interval=10s --timeout=1s \
    CMD bash -c 'source /to-access.sh && [[ "$(curl -s http://trafficmonitor.infra.ciab.test/api/traffic-ops-uri)" == "$TO_URL" ]]'

FROM trafficmonitor-dependencies as get-delve

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends golang-go && \
    rm -rf /var/lib/apt/lists/* && \
    go install github.com/go-delve/delve/cmd/dlv@v1.26.0

FROM trafficmonitor as trafficmonitor-debug
COPY --from=get-delve /root/go/bin /usr/bin

# Makes the default target skip the trafficmonitor-debug stage
FROM trafficmonitor
