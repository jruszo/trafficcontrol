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
# Dockerfile to build Traffic Ops container images
# Based on Ubuntu 24.04
############################################################

ARG BASE_IMAGE=ubuntu \
    ubuntu_version=24.04
FROM ${BASE_IMAGE}:${ubuntu_version} as trafficops-dependencies

VOLUME /traffic_ops_data

RUN set -o nounset -o errexit -o xtrace && \
	mkdir -p /etc/cron.d && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ca-certificates \
		cpanminus \
		curl \
		dnsutils \
		findutils \
		genisoimage \
		gettext \
		iproute2 \
		jq \
		libcap2 \
		libcurl4-openssl-dev \
		libdbd-pg-perl \
		libdbi-perl \
		libdigest-sha-perl \
		libexpat1-dev \
		libicu-dev \
		libidn2-dev \
		libjson-perl \
		libpcap-dev \
		libssl-dev \
		libterm-readkey-perl \
		libwww-curl-perl \
		libwww-perl \
		ncat \
		net-tools \
		openssl \
		perl \
		postgresql-client \
		procps \
		python3 \
		dpkg \
		rsync && \
	rm -rf /var/lib/apt/lists/*

FROM trafficops-dependencies AS trafficops

EXPOSE 443

WORKDIR /opt/traffic_ops/app

ADD infrastructure/cdn-in-a-box/traffic_ops_data /traffic_ops_data

# Override TRAFFIC_OPS_DEB arg to use a different one using --build-arg TRAFFIC_OPS_DEB=...  Can be local file or http://...
#
ARG TRAFFIC_OPS_DEB=infrastructure/cdn-in-a-box/traffic_ops/traffic_ops.deb

COPY $TRAFFIC_OPS_DEB /traffic_ops.deb
RUN dpkg -i --force-depends /traffic_ops.deb && \
	rm /traffic_ops.deb

COPY .github/actions/to-integration-tests/intermediate.crt.pem \
	.github/actions/to-integration-tests/intermediate.key.pem \
	.github/actions/to-integration-tests/rootca.crt.pem \
	.github/actions/to-integration-tests/rootca.key.pem \
	.github/actions/to-integration-tests/server.crt.pem \
	.github/actions/to-integration-tests/server.key.pem \
	/etc/pki/tls/traffic_ops/

COPY infrastructure/cdn-in-a-box/enroller/server_template.json \
	infrastructure/cdn-in-a-box/traffic_ops/config.sh \
	infrastructure/cdn-in-a-box/traffic_ops/run-go.sh \
	infrastructure/cdn-in-a-box/traffic_ops/to-access.sh \
	infrastructure/cdn-in-a-box/dns/insert-self-into-dns.sh \
	infrastructure/cdn-in-a-box/dns/set-dns.sh \
	infrastructure/cdn-in-a-box/traffic_ops/set-to-ips-from-dns.sh \
	infrastructure/cdn-in-a-box/traffic_ops/generate-certs.sh \
	infrastructure/cdn-in-a-box/traffic_ops/trafficops-init.sh \
	infrastructure/cdn-in-a-box/variables.env \
	/

EXPOSE 443
CMD /run-go.sh
HEALTHCHECK --interval=10s --timeout=1s \
	CMD bash -c 'source /to-access.sh && [[ "$(curl -sk "https://${TO_FQDN}/api/${TO_API_VERSION}/ping" | jq .ping)" == \"pong\" ]]'

FROM trafficops-dependencies as get-delve

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends golang-go && \
    rm -rf /var/lib/apt/lists/* && \
    go install github.com/go-delve/delve/cmd/dlv@v1.26.0

FROM trafficops AS trafficops-debug
COPY --from=get-delve /root/go/bin /usr/bin
COPY infrastructure/cdn-in-a-box/traffic_ops/tv.conf conf/production/

# Makes the default target skip the trafficops-debug stage
FROM trafficops
