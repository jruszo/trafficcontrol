#!/usr/bin/env sh
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# shellcheck shell=sh
trap 'exit_code=$?; [ $exit_code -ne 0 ] && echo "Error on line ${LINENO} of ${0}" >/dev/stderr; exit $exit_code' EXIT
set -o errexit -o nounset

script="$(realpath "$0")"
scriptdir="$(dirname "$script")"
TR_DIR="$(dirname "$scriptdir")"
TC_DIR="$(dirname "$TR_DIR")"

if [ ! -x "${TC_DIR}/.github/actions/build-packages/build-packages.sh" ]; then
	echo "Error: missing executable ${TC_DIR}/.github/actions/build-packages/build-packages.sh" >/dev/stderr
	exit 1
fi

export GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-${TC_DIR}}"
export ATC_COMPONENT='traffic_router'

exec "${TC_DIR}/.github/actions/build-packages/build-packages.sh"
