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
# Dockerfile to build optional CiaB Socks Proxy
# Based on Ubuntu 24.04
############################################################
ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version}

ARG DANTES_SRC=https://www.inet.no/dante/files/dante-1.4.3.tar.gz

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        ca-certificates \
        curl \
        dnsutils \
        gcc \
        iproute2 \
        make \
        net-tools \
        wget && \
    curl -Ls -o /tmp/dante.tar.gz $DANTES_SRC && \
    tar -C /usr/src -zxvpf /tmp/dante.tar.gz && \
    cd /usr/src/dante* && \
    ./configure --prefix=/usr && \
    make -j 4 && \
    make install && \
    groupadd -g 8062 sockd  && \
    useradd -m -u 8062 -g sockd sockd && \
    apt-get purge -y autoconf automake gcc make && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY optional/socksproxy/sockd.conf /etc
COPY optional/socksproxy/run.sh /

COPY dns/set-dns.sh \
     dns/insert-self-into-dns.sh \
     /usr/local/sbin/

EXPOSE 1080

CMD ["/run.sh"]
