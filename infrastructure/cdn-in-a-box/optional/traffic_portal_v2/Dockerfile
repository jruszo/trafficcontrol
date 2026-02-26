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
# Dockerfile to build Traffic Portal container images
# Based on Ubuntu 24.04
############################################################

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl && \
    rm -rf /var/lib/apt/lists/* && \
    bash -o pipefail -c 'curl -sLf https://deb.nodesource.com/setup_20.x | bash -'

# Override TRAFFIC_PORTAL_DEB arg to use a different one using --build-arg TRAFFIC_PORTAL_DEB=...  Can be local file or http://...
ARG TRAFFIC_PORTAL_DEB=optional/traffic_portal_v2/traffic_portal_v2.deb

ARG TO_HOST=$TO_HOST

# Install and delete the TRAFFIC_PORTAL_DEB when finished
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      dnsutils \
      findutils \
      gettext \
      jq \
      net-tools \
      nodejs \
      openssl \
      procps \
      dpkg && \
    rm -rf /var/lib/apt/lists/*

ADD $TRAFFIC_PORTAL_DEB /
RUN dpkg -i --force-depends /$(basename $TRAFFIC_PORTAL_DEB) && \
    rm /$(basename $TRAFFIC_PORTAL_DEB)

ADD enroller/server_template.json \
    optional/traffic_portal_v2/run.sh \
    traffic_ops/to-access.sh /

COPY dns/set-dns.sh \
     dns/insert-self-into-dns.sh \
     /usr/local/sbin/

EXPOSE 443

CMD /run.sh
