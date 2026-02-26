#!/usr/bin/env bash
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

set -o errexit -o nounset -o pipefail
trap 'echo "Error on line ${LINENO} of ${0}"; exit 1' ERR

if [[ -z "${ATC_COMPONENT:-}" ]]; then
	echo 'Missing environment variable ATC_COMPONENT' >&2
	exit 1
fi

build_target="${ATC_COMPONENT}"
case "${ATC_COMPONENT}" in
	grovetccfg)
		build_target='grove/grovetccfg'
		;;
esac

sudo apt-get update
sudo apt-get install -y --no-install-recommends alien fakeroot pandoc rpm rsync

install_npm_tool_if_missing() {
	local binary="$1"
	local package="$2"
	if command -v "${binary}" >/dev/null 2>&1; then
		return
	fi
	sudo npm install --global --force "${package}"
}

install_npm_tool_if_missing grunt grunt-cli
install_npm_tool_if_missing sass sass

# Build component artifacts and convert them to DEB packages for CIAB consumption.
export NO_SOURCE="${NO_SOURCE:-1}"
export NO_LOG_FILES="${NO_LOG_FILES:-0}"
export SIMPLE="${SIMPLE:-0}"
export PACKAGE_OS_VERSION="${PACKAGE_OS_VERSION:-ubuntu24.04}"
export GOPATH="${GOPATH:-/tmp/go}"
mkdir -p "${GOPATH}/"{bin,pkg,src}
export PATH="${GOPATH}/bin:${PATH}"
bash ./build/build.sh "${build_target}"

dist_dir="${GITHUB_WORKSPACE:-$(pwd)}/dist"
cd "${dist_dir}"

shopt -s nullglob
rpm_files=( *.rpm )
if (( ${#rpm_files[@]} == 0 )); then
	echo "No RPM artifacts were generated for ${ATC_COMPONENT}" >&2
	exit 1
fi

for rpm_file in "${rpm_files[@]}"; do
	if [[ "${rpm_file}" == *.src.rpm ]]; then
		continue
	fi
	fakeroot alien --to-deb --keep-version "${rpm_file}"
done

rm -f -- *.rpm

deb_files=( *.deb )
if (( ${#deb_files[@]} == 0 )); then
	echo "No Debian packages were created for ${ATC_COMPONENT}" >&2
	exit 1
fi
