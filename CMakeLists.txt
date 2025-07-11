# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#
cmake_minimum_required(VERSION 3.5.1)

project(falco)

option(USE_BUNDLED_DEPS "Bundle hard to find dependencies into the Falco binary" ON)
option(USE_DYNAMIC_LIBELF "Dynamically link libelf" OFF)
option(BUILD_WARNINGS_AS_ERRORS "Enable building with -Wextra -Werror flags" OFF)
option(
	MINIMAL_BUILD
	"Build a minimal version of Falco, containing only the engine and basic input/output (EXPERIMENTAL)"
	OFF
)
option(MUSL_OPTIMIZED_BUILD "Enable if you want a musl optimized build" OFF)
option(BUILD_FALCO_UNIT_TESTS "Build falco unit tests" OFF)
option(USE_ASAN "Build with AddressSanitizer" OFF)
option(USE_UBSAN "Build with UndefinedBehaviorSanitizer" OFF)
option(UBSAN_HALT_ON_ERROR "Halt on error when building with UBSan" ON)
option(USE_JEMALLOC "Use jemalloc allocator" OFF)

# gVisor is currently only supported on Linux x86_64
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" AND NOT MINIMAL_BUILD)
	option(BUILD_FALCO_GVISOR "Build gVisor support for Falco" ON)
	if(BUILD_FALCO_GVISOR)
		add_definitions(-DHAS_GVISOR)
	endif()
endif()

# Modern BPF is not supported on MINIMAL_BUILD
if(NOT MINIMAL_BUILD)
	option(BUILD_FALCO_MODERN_BPF "Build modern BPF support for Falco" ON)
	if(BUILD_FALCO_MODERN_BPF)
		add_definitions(-DHAS_MODERN_BPF)
	endif()
endif()

# We shouldn't need to set this, see https://gitlab.kitware.com/cmake/cmake/-/issues/16419
option(EP_UPDATE_DISCONNECTED "ExternalProject update disconnected" OFF)
if(${EP_UPDATE_DISCONNECTED})
	set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY EP_UPDATE_DISCONNECTED TRUE)
endif()

# Elapsed time set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CMAKE_COMMAND} -E time") #
# TODO(fntlnz, leodido): add a flag to enable this

# Make flag for parallel processing
include(ProcessorCount)
ProcessorCount(PROCESSOR_COUNT)
if(NOT PROCESSOR_COUNT EQUAL 0)
	set(PROCESSOUR_COUNT_MAKE_FLAG -j${PROCESSOR_COUNT})
endif()

# Custom CMake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

# GNU standard installation directories' definitions
include(GNUInstallDirs)

if(NOT DEFINED FALCO_ETC_DIR)
	set(FALCO_ETC_DIR "${CMAKE_INSTALL_FULL_SYSCONFDIR}/falco")
endif()

# This will be used to print the architecture for which Falco is compiled.
set(FALCO_TARGET_ARCH ${CMAKE_SYSTEM_PROCESSOR})

include(CompilerFlags)

set(PACKAGE_NAME "falco")
set(DRIVER_NAME "falco")
set(DRIVER_DEVICE_NAME "falco")
set(DRIVERS_REPO "https://download.falco.org/driver")

# If no path is provided, try to search the BPF probe in: `home/.falco/falco-bpf.o` This is the same
# fallback that we had in the libraries: `SCAP_PROBE_BPF_FILEPATH`.
set(FALCO_PROBE_BPF_FILEPATH ".${DRIVER_NAME}/${DRIVER_NAME}-bpf.o")
add_definitions(-DFALCO_PROBE_BPF_FILEPATH="${FALCO_PROBE_BPF_FILEPATH}")

if(NOT DEFINED FALCO_COMPONENT_NAME)
	set(FALCO_COMPONENT_NAME "${CMAKE_PROJECT_NAME}")
endif()

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	set(CMAKE_INSTALL_PREFIX
		/usr
		CACHE PATH "Default install path" FORCE
	)
endif()

set(CMD_MAKE make)

include(ExternalProject)

if(USE_JEMALLOC)
	if(USE_ASAN)
		message(WARNING "Jemalloc and ASAN are known to have issues when combined")
	endif()
	include(jemalloc)
endif()

# libs
include(falcosecurity-libs)

# compute FALCO_VERSION (depends on libs)
include(falco-version)

# nlohmann-json
include(njson)

# yaml-cpp
include(yaml-cpp)

if(NOT MINIMAL_BUILD)
	# OpenSSL
	include(openssl)

	# libcurl
	include(curl)

	# todo(jasondellaluce,rohith-raju): support webserver for non-linux builds too cpp-httlib
	include(cpp-httplib)
endif()

include(cxxopts)

# One TBB
include(tbb)

include(zlib)
include(valijson)
if(NOT MINIMAL_BUILD)
	include(cares)
	include(protobuf)
	# gRPC
	include(grpc)
endif()

# Installation
set(FALCO_INSTALL_CONF_FILE "/etc/falco/falco.yaml")
install(
	FILES falco.yaml
	DESTINATION "${FALCO_ETC_DIR}"
	COMPONENT "${FALCO_COMPONENT_NAME}"
)
install(
	DIRECTORY
	DESTINATION "${FALCO_ETC_DIR}/config.d"
	COMPONENT "${FALCO_COMPONENT_NAME}"
)

if(NOT MINIMAL_BUILD)
	# Coverage
	include(Coverage)
endif()

# Rules
include(rules)

# Clang format add_custom_target(format COMMAND clang-format --style=file -i
# $<TARGET_PROPERTY:falco,SOURCES> COMMENT "Formatting ..." VERBATIM)

# Static analysis
include(static-analysis)

# Shared build variables
set(FALCO_SHARE_DIR share/falco)
set(FALCO_ABSOLUTE_SHARE_DIR "${CMAKE_INSTALL_PREFIX}/${FALCO_SHARE_DIR}")
set(FALCO_BIN_DIR bin)

add_subdirectory(scripts)
add_subdirectory(userspace/engine)
add_subdirectory(userspace/falco)

include(falcoctl)
include(container_plugin)
# Generate a binary_dir/falco.yaml that automatically enables the plugin to be used for local
# testing.
configure_file(${CMAKE_SOURCE_DIR}/falco.yaml ${CMAKE_BINARY_DIR} COPYONLY)
# The custom target configures the plugin and set its path
add_custom_target(
	container
	COMMAND sed -i 's,^load_plugins: .*,load_plugins: [container],g' ${CMAKE_BINARY_DIR}/falco.yaml
	COMMAND sed -i 's,library_path: libcontainer.so,library_path: ${CONTAINER_LIBRARY},g'
			${CMAKE_BINARY_DIR}/falco.yaml
	DEPENDS container_plugin
)
# Let `make falco` also download container plugin
add_dependencies(falco container)

# Install the plugin
install(
	FILES "${CONTAINER_LIBRARY}"
	DESTINATION "${FALCO_ABSOLUTE_SHARE_DIR}/plugins"
	COMPONENT "${FALCO_COMPONENT_NAME}"
)
# Install additional config override file to enable the container plugin
install(
	FILES "${PROJECT_SOURCE_DIR}/config/falco.container_plugin.yaml"
	DESTINATION "${FALCO_ETC_DIR}/config.d"
	COMPONENT "${FALCO_COMPONENT_NAME}"
)

# Packages configuration
include(CPackConfig)

if(BUILD_FALCO_UNIT_TESTS)
	add_subdirectory(unit_tests)
endif()
