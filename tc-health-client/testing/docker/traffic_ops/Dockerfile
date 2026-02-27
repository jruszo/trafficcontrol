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
# Based on CentOS 8
############################################################

ARG OS_DISTRO=rockylinux
ARG OS_VERSION=8
FROM ${OS_DISTRO}:${OS_VERSION}
ARG OS_DISTRO
ARG OS_VERSION
ENV OS_DISTRO=${OS_DISTRO}
ENV OS_VERSION=${OS_VERSION}

RUN if [[ "${OS_VERSION%%.*}" -eq 7 ]]; then \
		yum -y install dnf || exit 1; \
	fi

RUN set -o nounset -o errexit -o xtrace && \
	mkdir -p /etc/cron.d; \
	if [[ "${OS_VERSION%%.*}" -eq 7 ]]; then \
		enable_repo=''; \
		postgresql_pkg='postgresql13'; \
		idn_pkg='libidn-devel'; \
		iso_pkg='mkisofs'; \
		# needed for llvm-toolset-7-clang, which is needed for postgresql13-devel-13.x-1PGDG, required by TO rpm
		dnf -y install gcc centos-release-scl-rh; \
	elif [[ "${OS_VERSION%%.*}" -ge 9 ]]; then \
		enable_repo='--enablerepo=crb'; \
		postgresql_pkg='postgresql'; \
		idn_pkg='libidn2-devel'; \
		iso_pkg='genisoimage'; \
	else \
		enable_repo='--enablerepo=powertools'; \
		postgresql_pkg='postgresql13'; \
		idn_pkg='libidn-devel'; \
		iso_pkg='mkisofs'; \
	fi; \
	dnf -y install epel-release libicu; \
	if [[ "${OS_VERSION%%.*}" -ge 9 ]]; then \
		dnf -y install "$postgresql_pkg"; \
	else \
		dnf -y install "https://download.postgresql.org/pub/repos/yum/reporpms/EL-${OS_VERSION%%.*}-$(rpm --eval %_arch)/pgdg-redhat-repo-latest.noarch.rpm"; \
		pgdg_repo="$(dnf -q repolist --all | awk '$1 ~ /^pgdg13/ {print $1; exit}')"; \
		if [[ -z "$pgdg_repo" ]]; then \
			echo 'ERROR: expected a pgdg13 repository after installing pgdg-redhat-repo.' >&2; \
			dnf repolist --all >&2; \
			exit 1; \
		fi; \
		dnf -y --enablerepo="$pgdg_repo" install "$postgresql_pkg"; \
		dnf -y remove pgdg-redhat-repo; \
	fi; \
	dnf -y $enable_repo install      \
		bind-utils           \
		gettext              \
		# ip commands is used in set-to-ips-from-dns.sh
		iproute              \
		isomd5sum            \
		jq                   \
		$idn_pkg             \
		libpcap-devel        \
		$iso_pkg             \
		net-tools            \
		nmap-ncat            \
		openssl              \
		perl-Crypt-ScryptKDF \
		perl-Digest-SHA1     \
		perl-JSON-PP         \
		procps-ng            \
		python3              \
		# rsync is used to copy certs in "Shared SSL certificate generation" step
		rsync;               \
	dnf clean all

EXPOSE 443

WORKDIR /opt/traffic_ops/app

ADD traffic_ops/traffic_ops*x86_64.rpm /traffic_ops.rpm
RUN yum -y install /traffic_ops.rpm && \
	rm /traffic_ops.rpm

ADD traffic_ops/run.sh /

EXPOSE 443
CMD /run.sh
