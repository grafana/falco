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

set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "Cloud Native Computing Foundation (CNCF) cncf.io.")
set(CPACK_PACKAGE_CONTACT "cncf-falco-dev@lists.cncf.io") # todo: change this once we've got
# @falco.org addresses
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Falco - Container Native Runtime Security")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${PROJECT_SOURCE_DIR}/scripts/description.txt")
set(CPACK_PACKAGE_VERSION "${FALCO_VERSION}")
set(CPACK_PACKAGE_VERSION_MAJOR "${FALCO_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${FALCO_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${FALCO_VERSION_PATCH}")
set(CPACK_PROJECT_CONFIG_FILE "${PROJECT_SOURCE_DIR}/cmake/cpack/CMakeCPackOptions.cmake")
set(CPACK_STRIP_FILES "OFF")
set(CPACK_PACKAGE_RELOCATABLE "OFF")
if(EMSCRIPTEN)
	set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-wasm")
else()
	set(CPACK_PACKAGE_FILE_NAME
		"${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_PROCESSOR}"
	)
endif()

if(WIN32)
	set(CPACK_PACKAGE_INSTALL_DIRECTORY "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")
endif()

# Built packages will include only the following components
set(CPACK_INSTALL_CMAKE_PROJECTS
	"${CMAKE_CURRENT_BINARY_DIR};${FALCO_COMPONENT_NAME};${FALCO_COMPONENT_NAME};/"
)

if(CMAKE_SYSTEM_NAME MATCHES "Linux") # only Linux has drivers
	list(APPEND CPACK_INSTALL_CMAKE_PROJECTS
		 "${CMAKE_CURRENT_BINARY_DIR};${DRIVER_COMPONENT_NAME};${DRIVER_COMPONENT_NAME};/"
	)
endif()

if(NOT CPACK_GENERATOR)
	if(CMAKE_SYSTEM_NAME MATCHES "Linux")
		set(CPACK_GENERATOR DEB RPM TGZ)
	else()
		set(CPACK_GENERATOR TGZ)
	endif()
endif()

message(STATUS "Using package generators: ${CPACK_GENERATOR}")
message(STATUS "Package architecture: ${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_DEBIAN_PACKAGE_SECTION "utils")

if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
	set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "aarch64")
	set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "arm64")
endif()
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://www.falco.org")
set(CPACK_DEBIAN_PACKAGE_SUGGESTS "dkms (>= 2.1.0.0)")
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA
	"${CMAKE_BINARY_DIR}/scripts/debian/postinst;${CMAKE_BINARY_DIR}/scripts/debian/prerm;${CMAKE_BINARY_DIR}/scripts/debian/postrm;${PROJECT_SOURCE_DIR}/cmake/cpack/debian/conffiles"
)

set(CPACK_RPM_PACKAGE_LICENSE "Apache v2.0")
set(CPACK_RPM_PACKAGE_ARCHITECTURE, "amd64")
set(CPACK_RPM_PACKAGE_URL "https://www.falco.org")
set(CPACK_RPM_PACKAGE_REQUIRES "systemd")
set(CPACK_RPM_PACKAGE_SUGGESTS "dkms, kernel-devel")
set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${CMAKE_BINARY_DIR}/scripts/rpm/postinstall")
set(CPACK_RPM_PRE_UNINSTALL_SCRIPT_FILE "${CMAKE_BINARY_DIR}/scripts/rpm/preuninstall")
set(CPACK_RPM_POST_UNINSTALL_SCRIPT_FILE "${CMAKE_BINARY_DIR}/scripts/rpm/postuninstall")
set(CPACK_RPM_PACKAGE_VERSION "${FALCO_VERSION}")
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
	/usr/src
	/usr/share/man
	/usr/share/man/man8
	/etc
	/usr
	/usr/bin
	/usr/share
)
set(CPACK_RPM_PACKAGE_RELOCATABLE "OFF")

include(CPack)
