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

GOPATH="$(mktemp -d)"
SRCDIR="$GOPATH/src/github.com/apache"
mkdir -p "$SRCDIR"
ln -s "$PWD" "$SRCDIR/trafficcontrol"
cd "$SRCDIR/trafficcontrol"

printf "about to gofmt, pwd: %s\n" "$(pwd)"

/usr/local/go/bin/go fmt ./...
printf "gofmt returned %d\n" "$?"


git config --global --add safe.directory /github/workspace
printf "git config add safe.directory returned  %d\n" "$?"

#git status

printf "about to git-diff, pwd: %s\n" "$(pwd)"
DIFF_FILE="$(mktemp)"
git diff >"$DIFF_FILE"
printf "git diff returned %d\n" "$?"

if [ -s "$DIFF_FILE" ]; then
	./misc/parse_diffs.py <"$DIFF_FILE";
	rm "$DIFF_FILE";
	exit 1;
fi

echo "No diff found"
