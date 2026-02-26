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
# Dockerfile to build Edge-Tier Cache container images for
# Apache Traffic Control
# Based on Ubuntu 24.04
############################################################

ifeq ($(deb_VERSION),)
	export deb_VERSION := 8
endif

BASE_IMAGE := ubuntu

CIAB_DIR_RELATIVE := $(dir $(MAKEFILE_LIST))
CIAB_DIR_ABSOLUTE := $(shell cd $(CIAB_DIR_RELATIVE) && pwd)
TC_DIR := $(CIAB_DIR_RELATIVE)../..
DOCKER_COMPOSE := $(shell \
	if docker compose version >/dev/null 2>&1; then \
		echo "docker compose"; \
	elif command -v docker-compose >/dev/null 2>&1; then \
		echo "docker-compose"; \
	fi)

PKG_COMMAND := $(TC_DIR)/pkg
PKG_FLAGS := -v -$(deb_VERSION)
BUILD_SUFFIX := _build
BUILD_NUMBER := $(shell bash -c ' \
	set -o errexit -o pipefail; \
	git rev-parse --is-inside-work-tree >/dev/null; \
	output="$$(git describe \
		--long \
		--tags \
		--match="RELEASE-[0-9].[0-9].[0-9]" \
		--match="RELEASE-[0-9][0-9].[0-9][0-9].[0-9][0-9]" \
		--match="v[0-9].[0-9].[0-9]" \
		--match="v[0-9][0-9].[0-9][0-9].[0-9][0-9]" | \
		awk -F- "{print \$$(NF-1)}" || \
		echo 0)"; \
	output+=".$$(git rev-parse --short=8 HEAD)"; \
	echo "$$output"' || \
	cat $(TC_DIR)/BUILD_NUMBER)
BUILD_ARCH   := $(shell uname -m | sed -E 's/amd64/x86_64/; s/arm64/aarch64/')
TC_VERSION := $(shell cat "$(TC_DIR)/VERSION")
TOMCAT_VERSION := $(shell grep '^\s*TOMCAT_VERSION=' "$(TC_DIR)/.env"  | cut -d= -f2)
ATS_VERSION := $(shell $(CIAB_DIR_RELATIVE)bin/ats-version.sh)
ifeq ($(deb_VERSION),7)
# The commit hash in `git describe` is only 7 characters in ubuntu 7's git 1.8
ATS_VERSION := $(shell echo "$(ATS_VERSION)" | sed -E 's/^(.*-[0-9]+\.[0-9a-f]{7})[0-9a-f]*/\1/')
endif

SPECIAL_SAUCE := $(TC_VERSION)-$(BUILD_NUMBER).el$(deb_VERSION).$(BUILD_ARCH).deb
SPECIAL_SAUCE_NOARCH := $(TC_VERSION)-$(BUILD_NUMBER).el$(deb_VERSION).noarch.deb
SPECIAL_SEASONING := $(TOMCAT_VERSION)-1.el$(deb_VERSION).noarch.deb
SPECIAL_SYRUP := $(ATS_VERSION).el$(deb_VERSION).$(BUILD_ARCH).deb

ATS_SOURCE := $(wildcard $(TC_DIR)/cache-config/testing/docker/trafficserver/**)
TO_SOURCE := $(wildcard $(TC_DIR)/traffic_ops/**)
TO_SOURCE += $(wildcard $(TC_DIR)/traffic_ops_db/**)
ORT_SOURCE := $(wildcard $(TC_DIR)/cache-config/**)
ORT_SOURCE += $(wildcard $(TC_DIR)/lib/**.go)
TM_SOURCE := $(wildcard $(TC_DIR)/traffic_monitor/**)
TP_SOURCE := $(wildcard $(TC_DIR)/traffic_portal/**)
TP2_SOURCE := $(wildcard $(TC_DIR)/experimental/traffic-portal/**)
TR_SOURCE := $(wildcard $(TC_DIR)/traffic_router/**)
TS_SOURCE := $(wildcard $(TC_DIR)/traffic_stats/**)
TCH_SOURCE := $(wildcard $(TC_DIR)/tc-health-client/**)

ATS_deb := cache/trafficserver.deb
TM_deb := traffic_monitor/traffic_monitor.deb
TO_deb := traffic_ops/traffic_ops.deb
TP_deb := traffic_portal/traffic_portal.deb
TP2_deb := optional/traffic_portal_v2/traffic_portal_v2.deb
TR_deb := traffic_router/traffic_router.deb
TOMCAT_deb := traffic_router/tomcat.deb
TS_deb := traffic_stats/traffic_stats.deb
ORT_deb := cache/trafficcontrol-cache-config.deb
TCH_deb := health/trafficcontrol-health-client.deb

ATS_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(ATS_deb)
TM_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TM_deb)
TO_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TO_deb)
TP_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TP_deb)
TP2_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TP2_deb)
TR_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TR_deb)
TOMCAT_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TOMCAT_deb)
TS_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TS_deb)
ORT_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(ORT_deb)
TCH_deb_RELATIVE := $(CIAB_DIR_RELATIVE)$(TCH_deb)

ATS_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(ATS_deb)
TM_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TM_deb)
TO_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TO_deb)
TP_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TP_deb)
TP2_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TP2_deb)
TR_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TR_deb)
TOMCAT_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TOMCAT_deb)
TS_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TS_deb)
ORT_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(ORT_deb)
TCH_deb_ABSOLUTE := $(CIAB_DIR_ABSOLUTE)/$(TCH_deb)

ATS_DIST_deb := $(TC_DIR)/dist/trafficserver-$(SPECIAL_SYRUP)
TM_DIST_deb := $(TC_DIR)/dist/traffic_monitor-$(SPECIAL_SAUCE)
TO_DIST_deb := $(TC_DIR)/dist/traffic_ops-$(SPECIAL_SAUCE)
TP_DIST_deb := $(TC_DIR)/dist/traffic_portal-$(SPECIAL_SAUCE)
TP2_DIST_deb := $(TC_DIR)/dist/traffic_portal_v2-$(SPECIAL_SAUCE)
TR_DIST_deb := $(TC_DIR)/dist/traffic_router-$(SPECIAL_SAUCE_NOARCH)
TOMCAT_DIST_deb := $(TC_DIR)/dist/tomcat-$(SPECIAL_SEASONING)
TS_DIST_deb := $(TC_DIR)/dist/traffic_stats-$(SPECIAL_SAUCE)
ORT_DIST_deb := $(TC_DIR)/dist/trafficcontrol-cache-config-$(SPECIAL_SAUCE)
TCH_DIST_deb := $(TC_DIR)/dist/trafficcontrol-health-client-$(SPECIAL_SAUCE)

.PHONY: all build-builders clean debug native nearly-all pull-builders very-clean

# Default target; builds all pre-requisite debs from source trees
all: $(ATS_deb_RELATIVE) $(ORT_deb_RELATIVE) $(TM_deb_RELATIVE) $(TP_deb_RELATIVE) $(TO_deb_RELATIVE) $(TR_deb_RELATIVE) $(TOMCAT_deb_RELATIVE) $(TS_deb_RELATIVE) $(TCH_deb_RELATIVE)

ifneq ($(filter build-builders,$(MAKECMDGOALS)),)
PKG_FLAGS += -b
ifneq ($(MAKECMDGOALS),build-builders)
MAKECMDGOALS := $(filter-out build-builders,$(MAKECMDGOALS))
build-builders: $(MAKECMDGOALS)
else
build-builders: all
endif
endif

ifneq ($(filter debug,$(MAKECMDGOALS)),)
PKG_FLAGS += -d
export DEBUG_BUILD = true
ifneq ($(MAKECMDGOALS),debug)
MAKECMDGOALS := $(filter-out debug,$(MAKECMDGOALS))
debug: $(MAKECMDGOALS)
else
debug: all
endif
endif

ifneq ($(filter native,$(MAKECMDGOALS)),)
PKG_COMMAND := $(TC_DIR)/build/clean_build.sh
PKG_FLAGS :=
BUILD_SUFFIX :=
ifneq ($(MAKECMDGOALS),native)
MAKECMDGOALS := $(filter-out native,$(MAKECMDGOALS))
native: $(MAKECMDGOALS)
else
native: all
endif
endif

ifneq ($(filter pull-builders,$(MAKECMDGOALS)),)
PKG_FLAGS += -p
ifneq ($(MAKECMDGOALS),pull-builders)
MAKECMDGOALS := $(filter-out pull-builders,$(MAKECMDGOALS))
pull-builders: $(MAKECMDGOALS)
else
pull-builders: all
endif
endif

# Relative path output DEB recipies
$(ATS_deb_RELATIVE): $(ATS_DIST_deb)
	cp -f "$?" "$@" || (rm "$(CIAB_DIR_RELATIVE)/cache/ATS_VERSION"; false)
$(TM_deb_RELATIVE): $(TM_DIST_deb)
	cp -f "$?" "$@"
$(TO_deb_RELATIVE): $(TO_DIST_deb)
	cp -f "$?" "$@"
$(TP_deb_RELATIVE): $(TP_DIST_deb)
	cp -f "$?" "$@"
$(TP2_deb_RELATIVE): $(TP2_DIST_deb)
	cp -f "$?" "$@"
$(TR_deb_RELATIVE): $(TR_DIST_deb)
	cp -f "$?" "$@"
$(TOMCAT_deb_RELATIVE): $(TOMCAT_DIST_deb)
	cp -f "$?" "$@"
$(TS_deb_RELATIVE): $(TS_DIST_deb)
	cp -f "$?" "$@"
$(ORT_deb_RELATIVE): $(ORT_DIST_deb)
	cp -f "$?" "$@"
$(TCH_deb_RELATIVE): $(TCH_DIST_deb)
	cp -f "$?" "$@"

# Absolute path output DEB recipies
$(ATS_deb_ABSOLUTE): $(ATS_DIST_deb)
	cp -f "$?" "$@" || (rm "$(CIAB_DIR_ABSOLUTE)/cache/ATS_VERSION"; false)
$(TM_deb_ABSOLUTE): $(TM_DIST_deb)
	cp -f "$?" "$@"
$(TO_deb_ABSOLUTE): $(TO_DIST_deb)
	cp -f "$?" "$@"
$(TP_deb_ABSOLUTE): $(TP_DIST_deb)
	cp -f "$?" "$@"
$(TP2_deb_ABSOLUTE): $(TP2_DIST_deb)
	cp -f "$?" "$@"
$(TR_deb_ABSOLUTE): $(TR_DIST_deb)
	cp -f "$?" "$@"
$(TOMCAT_deb_ABSOLUTE): $(TOMCAT_DIST_deb)
	cp -f "$?" "$@"
$(TS_deb_ABSOLUTE): $(TS_DIST_deb)
	cp -f "$?" "$@"
$(ORT_deb_ABSOLUTE): $(ORT_DIST_deb)
	cp -f "$?" "$@"
$(TCH_deb_ABSOLUTE): $(TCH_DIST_deb)
	cp -f "$?" "$@"

# Dist debs
$(ATS_DIST_deb): $(ATS_SOURCE)
	@if [ -z "$(strip $(DOCKER_COMPOSE))" ]; then \
		echo "Docker Compose was not found. Install Docker Compose plugin support ('docker compose') or the standalone binary ('docker-compose')."; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) -f $(TC_DIR)/cache-config/testing/docker/docker-compose-ats-build.yml build --parallel trafficserver_build && $(DOCKER_COMPOSE) -f $(TC_DIR)/cache-config/testing/docker/docker-compose-ats-build.yml run --rm trafficserver_build

$(TM_DIST_deb): $(TM_SOURCE)
	"$(PKG_COMMAND)" $(PKG_FLAGS) traffic_monitor$(BUILD_SUFFIX)

$(TO_DIST_deb): $(TO_SOURCE)
	"$(PKG_COMMAND)" $(PKG_FLAGS) traffic_ops$(BUILD_SUFFIX)

$(TP_DIST_deb): $(TP_SOURCE)
	"$(PKG_COMMAND)" $(PKG_FLAGS) traffic_portal$(BUILD_SUFFIX)

$(TP2_DIST_deb): $(TP2_SOURCE)
	"$(PKG_COMMAND)" -o $(PKG_FLAGS) traffic_portal_v2$(BUILD_SUFFIX)

$(TR_DIST_deb) $(TOMCAT_DIST_deb): $(TR_SOURCE)
	"$(PKG_COMMAND)" $(PKG_FLAGS) traffic_router$(BUILD_SUFFIX)

$(TS_DIST_deb): $(TS_SOURCE)
	"$(PKG_COMMAND)" $(PKG_FLAGS) traffic_stats$(BUILD_SUFFIX)

$(ORT_DIST_deb): $(ORT_SOURCE)
	"$(PKG_COMMAND)" $(PKG_FLAGS) cache-config$(BUILD_SUFFIX)

$(TCH_DIST_deb): $(TCH_SOURCE)
	"$(PKG_COMMAND)" $(PKG_FLAGS) tc-health-client$(BUILD_SUFFIX)

clean:
	cd "$(CIAB_DIR_RELATIVE)"
	$(RM) $(TM_deb_RELATIVE) $(TO_deb_RELATIVE) $(TP_deb_RELATIVE) $(TP2_deb_RELATIVE) $(TR_deb_RELATIVE) $(TOMCAT_deb_RELATIVE) $(ORT_deb_RELATIVE) $(TS_deb_RELATIVE) $(TCH_deb_RELATIVE)

very-clean: clean
	$(warning This will destroy ALL OUTPUT debS IN 'dist'. Please be sure this is what you want)
	sleep 2 # Give users a second to cancel
	$(RM) -r "$(TC_DIR)/dist"/*
