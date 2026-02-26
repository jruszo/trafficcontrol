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
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version} as os-dependencies

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        findutils \
        git \
        jq \
        net-tools \
        openjdk-17-jre-headless \
        wget && \
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ./google-chrome-stable_current_amd64.deb && \
    rm -f google-chrome-stable_current_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

FROM os-dependencies AS node-dependencies
# Download and install node
RUN set -o pipefail; \
    curl -sLf https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*
RUN npm i -g webdriver-manager

FROM node-dependencies

COPY    traffic_portal/ /lang/traffic_portal/
WORKDIR /lang/traffic_portal/test/integration

RUN npm ci

RUN mkdir /portaltestresults

RUN jq ' \
        .capabilities.chromeOptions.args += [ \
            "--disable-extensions", \
            "--ignore-certificate-errors", \
            "--no-sandbox", \
            "--whitelisted-ips=" \
        ] | \
        .getPageTimeout = 120000 | \
        .allScriptsTimeout = 300000 | \
        .defaultTimeoutInterval = 12000 | \
        .params.junitReporter = true' \
        config.json > conf.json.tmp && \
    mv conf.json.tmp config.json

RUN set -o pipefail && \
    webdriver-manager clean && \
    google-chrome --version | \
        grep -o '[0-9.]\+' | \
        xargs webdriver-manager update --gecko false --versions.chrome

COPY infrastructure/cdn-in-a-box/traffic_ops/to-access.sh \
     infrastructure/cdn-in-a-box/traffic_portal_integration_test/run.sh \
     infrastructure/cdn-in-a-box/dns/set-dns.sh \
     infrastructure/cdn-in-a-box/dns/insert-self-into-dns.sh \
     /usr/local/sbin/

CMD run.sh
