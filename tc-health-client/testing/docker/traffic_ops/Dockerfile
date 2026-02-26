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

FROM ubuntu:24.04

RUN set -o nounset -o errexit -o xtrace && \
	mkdir -p /etc/cron.d && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ca-certificates \
		cpanminus \
		curl \
		dnsutils \
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
		rsync && \
	rm -rf /var/lib/apt/lists/*

EXPOSE 443
WORKDIR /opt/traffic_ops/app

ADD traffic_ops/traffic_ops*.deb /traffic_ops.deb
RUN mkdir -p /etc/pki/tls/private /etc/pki/tls/certs && \
	dpkg -i --force-depends /traffic_ops.deb && \
	rm /traffic_ops.deb

ADD traffic_ops/run.sh /

EXPOSE 443
CMD /run.sh
