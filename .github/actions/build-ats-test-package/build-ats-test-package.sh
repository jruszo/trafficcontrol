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

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
dist_dir="${workspace}/dist"
mkdir -p "${dist_dir}"
cd "${dist_dir}"

sudo apt-get update

apt-get download trafficserver
if apt-cache show trafficserver-dev >/dev/null 2>&1; then
	apt-get download trafficserver-dev
fi

shopt -s nullglob
deb_files=( trafficserver*.deb )
if (( ${#deb_files[@]} == 0 )); then
	echo "No trafficserver Debian packages were downloaded" >&2
	exit 1
fi
