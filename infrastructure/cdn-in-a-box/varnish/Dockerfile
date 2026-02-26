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

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04 \
    GO_VERSION=1.26.0

FROM golang:${GO_VERSION}-alpine AS vstats-builder

COPY infrastructure/cdn-in-a-box/varnish/vstats.go /

RUN go build -o /vstats /vstats.go

FROM ${BASE_IMAGE}:${ubuntu_version} AS common-varnish-cache-config-layers

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        findutils \
        gettext \
        git \
        iproute2 \
        jq \
        libkyotocabinet16v5 \
        logrotate \
        ncat \
        net-tools \
        openssl \
        perl \
        dpkg && \
    rm -rf /var/lib/apt/lists/*

RUN curl -s https://packagecloud.io/install/repositories/varnishcache/varnish73/script.deb.sh | bash && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        hitch \
        varnish && \
    rm -rf /var/lib/apt/lists/*


COPY infrastructure/cdn-in-a-box/varnish/run.sh infrastructure/cdn-in-a-box/traffic_ops/to-access.sh infrastructure/cdn-in-a-box/enroller/server_template.json /

COPY infrastructure/cdn-in-a-box/dns/set-dns.sh \
    infrastructure/cdn-in-a-box/dns/insert-self-into-dns.sh \
    /usr/local/sbin/
    

COPY infrastructure/cdn-in-a-box/varnish/systemctl.sh /usr/bin/systemctl

ARG ORT_DEB=infrastructure/cdn-in-a-box/cache/trafficcontrol-cache-config.deb
COPY $ORT_DEB /
RUN dpkg -i --force-depends /$(basename $ORT_DEB) &&\
    rm /$(basename $ORT_DEB)

COPY infrastructure/cdn-in-a-box/varnish/traffic_ops_ort.crontab /etc/cron.d/traffic_ops_ort-cron-template

COPY --from=vstats-builder /vstats /usr/local/bin

ENV CACHE_SERVER_TYPE=VARNISH
CMD /run.sh

FROM common-varnish-cache-config-layers AS mid
ENV CACHE_TYPE=mid
COPY infrastructure/cdn-in-a-box/mid/init.d/ /opt/init.d/

FROM common-varnish-cache-config-layers AS edge
ENV CACHE_TYPE=edge
COPY infrastructure/cdn-in-a-box/edge/init.d/ /opt/init.d/
