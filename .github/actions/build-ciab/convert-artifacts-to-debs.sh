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

if [[ ! -d "${dist_dir}" ]]; then
	echo "dist directory ${dist_dir} does not exist"
	exit 1
fi

shopt -s nullglob
rpm_files=("${dist_dir}"/*.rpm)
if (( ${#rpm_files[@]} == 0 )); then
	echo "No RPM artifacts found in ${dist_dir}; nothing to convert."
	exit 0
fi

sudo apt-get update
sudo apt-get install -y --no-install-recommends alien fakeroot

pushd "${dist_dir}" >/dev/null
for rpm_file in *.rpm; do
	if [[ "${rpm_file}" == *.src.rpm ]]; then
		continue
	fi
	fakeroot alien --to-deb --keep-version "${rpm_file}"
done
rm -f -- *.rpm
popd >/dev/null
