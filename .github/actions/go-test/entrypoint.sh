#!/bin/sh -l
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

set -e

download_go() {
	go_version="$(cat "${GITHUB_WORKSPACE}/GO_VERSION")"
	go_root="/usr/local/go"

	install_go_tarball() {
		version="$1"
		url="https://dl.google.com/go/go${version}.linux-amd64.tar.gz"
		if ! wget -q -O go.tar.gz "${url}"; then
			rm -f go.tar.gz
			return 1
		fi
		rm -rf "${go_root}"
		tar -C /usr/local -xzf go.tar.gz
		rm -f go.tar.gz
		export PATH="${go_root}/bin:${PATH}"
		return 0
	}

	if install_go_tarball "${go_version}"; then
		go version
		return
	fi

	case "${go_version}" in
		1.26.*)
			bootstrap="$(wget -qO- https://go.dev/VERSION?m=text | sed -n '1s/^go//p')"
			install_go_tarball "${bootstrap}"
			tmpdir="$(mktemp -d)"
			(
				cd "${tmpdir}"
				GO111MODULE=on go install golang.org/dl/gotip@latest
			)
			rm -rf "${tmpdir}"
			gotip_bin="$(go env GOPATH)/bin/gotip"
			"${gotip_bin}" download
			ln -sf "${HOME}/sdk/gotip/bin/gotip" /usr/local/bin/go
			export PATH="/usr/local/bin:$(go env GOPATH)/bin:${HOME}/sdk/gotip/bin:${PATH}"
			go version
			;;
		*)
			echo "Unable to install requested Go version ${go_version}" >&2
			exit 1
			;;
	esac
}
download_go

if [ -z "$INPUT_DIR" ]; then
	# There's a bug in "defaults" for inputs
	INPUT_DIR="./lib/..."
fi

# Need to fetch golang.org/x/* dependencies
if ! [ -d "${GITHUB_WORKSPACE}/vendor/golang.org" ]; then
	go mod vendor
fi

export GOFLAGS="-buildvcs=false -vet=off"

# t3c-check-refs requires a binary in order to test
# cache-config tests need to ignore the testing directory
if [ $TEST_NAME == "cache-config" ]; then
  go build -o ./cache-config/t3c-check-refs/ ./cache-config/t3c-check-refs/t3c-check-refs.go
  go test $(go list $INPUT_DIR | grep -v /testing/) -coverpkg=$INPUT_DIR -coverprofile="$TEST_NAME-coverage.out"
else
  go test $INPUT_DIR -coverpkg=$INPUT_DIR -coverprofile="$TEST_NAME-coverage.out"
fi
exit $?
