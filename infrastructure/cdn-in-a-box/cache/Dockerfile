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
# Dockerfile to build Edge-Tier Cache container images for
# Apache Traffic Control
# Based on Ubuntu 24.04
############################################################

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version} AS common-traffic-server-dependencies

# The /traffic_ops_data volume is included to set the ATS DEB version in the MID profile.
VOLUME /traffic_ops_data

EXPOSE 80

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        brotli \
        ca-certificates \
        cron \
        curl \
        dnsutils \
        findutils \
        g++ \
        geoip-bin \
        gettext \
        git \
        groff-base \
        hwloc \
        iproute2 \
        jq \
        libc6-dev \
        libcjose0 \
        libjansson4 \
        libkyotocabinet16v5 \
        libltdl7 \
        liblzo2-2 \
        libmaxminddb0 \
        libnuma1 \
        libssl-dev \
        libtool \
        libunwind8 \
        logrotate \
        luajit \
        make \
        ncat \
        net-tools \
        openssl \
        perl \
        procps \
        dpkg \
        tcl \
        uuid-runtime \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

FROM common-traffic-server-dependencies AS common-cache-config-layers

COPY infrastructure/cdn-in-a-box/cache/trafficserver.deb /trafficserver.deb
COPY traffic_server/plugins/astats_over_http/astats_over_http.c traffic_server/plugins/astats_over_http/Makefile.am /

RUN set -o errexit -o nounset -o xtrace; \
    dpkg -i --force-depends /trafficserver.deb; \
    if [[ -e /trafficserver-devel.deb ]]; then \
        dpkg -i --force-depends /trafficserver-devel.deb; \
    fi; \
    PATH+=:/opt/trafficserver/bin; \
    tsxs -v -c astats_over_http.c -o astats_over_http.so && \
    tsxs -v -o astats_over_http.so -i && \
    apt-get purge -y autoconf automake g++ libc6-dev libssl-dev libtool && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /astats_over_http.c /Makefile.am

RUN set -o errexit -o nounset -o pipefail -o xtrace && \
    # The ssl directory needs to exist or the first sslkey file will be skipped on badass
    etc_trafficserver="/etc/trafficserver"; \
    if [[ ! -e "${etc_trafficserver}/ssl" ]]; then \
        echo 'Creating ssl directory...'; \
        mkdir "${etc_trafficserver}/ssl"; \
    fi; \
    # trafficserver needs different ownership than the trafficserver DEB sets
    chown -R ats:ats "$etc_trafficserver"

WORKDIR /opt

COPY infrastructure/cdn-in-a-box/cache/traffic_ops_ort.crontab /etc/cron.d/traffic_ops_ort-cron-template
COPY infrastructure/cdn-in-a-box/cache/traffic_ops_ort.logrotate /etc/logrotate.d/ort

COPY infrastructure/cdn-in-a-box/cache/run.sh infrastructure/cdn-in-a-box/traffic_ops/to-access.sh infrastructure/cdn-in-a-box/enroller/server_template.json /

COPY infrastructure/cdn-in-a-box/dns/set-dns.sh \
     infrastructure/cdn-in-a-box/dns/insert-self-into-dns.sh \
     /usr/local/sbin/
# Copy systemctl.sh to /usr/bin specifically because t3c runs /bin/systemctl by absolute path
COPY infrastructure/cdn-in-a-box/cache/systemctl.sh /usr/bin/systemctl

ARG ORT_DEB=infrastructure/cdn-in-a-box/cache/trafficcontrol-cache-config.deb
COPY $ORT_DEB /
RUN dpkg -i --force-depends /$(basename $ORT_DEB) &&\
    rm /$(basename $ORT_DEB)
CMD /run.sh

ARG TCH_DEB=infrastructure/cdn-in-a-box/health/trafficcontrol-health-client.deb
COPY $TCH_DEB /
RUN dpkg -i --force-depends /$(basename $TCH_DEB) &&\
    rm /$(basename $TCH_DEB)

ADD infrastructure/cdn-in-a-box/health/tc-health-client.service /usr/lib/systemd/system
COPY infrastructure/cdn-in-a-box/health/tc-health-client.json  /etc/trafficcontrol/tc-health-client.json
COPY infrastructure/cdn-in-a-box/health/to-creds /etc/to-creds

FROM common-traffic-server-dependencies AS get-delve
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends golang-go && \
    rm -rf /var/lib/apt/lists/* && \
    go install github.com/go-delve/delve/cmd/dlv@v1.26.0

FROM common-cache-config-layers AS mid
ENV CACHE_TYPE=mid
COPY infrastructure/cdn-in-a-box/mid/init.d/ /opt/init.d/

FROM mid AS mid-debug
COPY --from=get-delve /root/go/bin /usr/bin
COPY infrastructure/cdn-in-a-box/cache/init-debug-scripts.sh /opt/init.d/

FROM common-cache-config-layers AS edge
ENV CACHE_TYPE=edge
COPY infrastructure/cdn-in-a-box/edge/init.d/ /opt/init.d/

FROM edge AS edge-debug
COPY --from=get-delve /root/go/bin /usr/bin
COPY infrastructure/cdn-in-a-box/cache/init-debug-scripts.sh /opt/init.d/

# Makes the default target skip the edge-debug stage
FROM edge
