# Licensed to the Apache Software Fou:qndation (ASF) under one
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
#
# SPDX-License-Identifier: Apache-2.0
    # Change BASE_IMAGE to ubuntu when ubuntu_VERSION=7
ARG BASE_IMAGE=ubuntu \
    ubuntu_VERSION=8
FROM ${BASE_IMAGE}:${ubuntu_VERSION} as ats-common-dependencies
ARG ubuntu_VERSION=8

MAINTAINER dev@trafficcontrol.apache.org

### Common for all sub-component builds
RUN if [[ ${ubuntu_VERSION%%.*} -ge 8 ]]; then \
		apt install -y 'apt-command(config-manager)'; \
		apt config-manager --set-enabled powertools; \
	else \
		apt install -y deltadeb ubuntu-release-scl-rh; \
		apt-config-manager --enable ubuntu-server-rhscl-7-debs; \
	fi && \
	deb --import /etc/pki/deb-gpg/DEB-GPG-KEY-* && \
	deb --import "https://dl.fedoraproject.org/pub/epel/DEB-GPG-KEY-EPEL-${ubuntu_VERSION%%.*}" && \
	apt -y clean all && \
	apt -y update ca-certificates && \
	apt -y install \
		git \
		deb-build \
		rsync \
		epel-release && \
	apt -y clean all

### ats specific requirements
FROM ats-common-dependencies AS build-ats-specific
ARG ubuntu_VERSION=8
# Makes ubuntu_VERSION accessible to CMD
ENV ubuntu_VERSION="$ubuntu_VERSION"

RUN if [[ ${ubuntu_VERSION%%.*} -ge 8 ]]; then \
		os_pkgs=( \
			brotli \
			brotli-devel \
			curl \
			gcc-toolset-11 \
			gcc-toolset-11-runtime \
			jansson \
			jansson-devel \
			libmaxminddb \
			libmaxminddb-devel); \
		os_toolset="gcc-toolset-11"; \
	else \
		os_pkgs=(devtoolset-11); \
		os_toolset="devtoolset-11"; \
	fi \
	&& apt install -y \
		${os_pkgs[*]} \
		autoconf \
		automake \
		ed \
		expat-devel \
		flex \
		gcc-c++ \
		glibc-devel \
		hwloc \
		hwloc-devel \
		libcap-devel \
		libcurl-devel \
		libtool \
		libuuid-devel \
		lua-devel \
		luajit-devel \
		make \
		man \
		nano \
		ncurses-devel \
		nmap-ncat \
		openssl \
		openssl-devel \
		pcre \
		pcre-devel \
		perl-Digest-SHA \
		perl-ExtUtils-MakeMaker \
		perl-URI \
		pkgconfig \
		python3 \
		sudo \
		tcl-devel \
		zlib \
		zlib-devel \
	&& apt clean all
COPY	jansson.pic.patch /opt/src/
COPY	cjose.pic.patch /opt/src/
RUN	pip3 install --user Sphinx
COPY	run.sh /run.sh
COPY	trafficserver.spec /debbuilddir/SPECS/trafficserver.spec
COPY	traffic_server_jemalloc /debbuilddir/SOURCES/traffic_server_jemalloc
COPY	trafficserver.env /debbuilddir/SOURCES/trafficserver.env
RUN	/usr/sbin/useradd -u 176 -r ats -s /sbin/nologin -d /
CMD if [[ ${ubuntu_VERSION%%.*} -ge 8 ]]; then \
		os_toolset=gcc-toolset-11; \
		openssl_included='--without_openssl'; \
	else \
		os_toolset=devtoolset-7; \
		openssl_included='--with_openssl'; \
	fi \
	&& set -o pipefail; scl enable ${os_toolset} "./run.sh ${openssl_included}" 2>&1 | tee /debbuilddir/debS/build-trafficserver.log
